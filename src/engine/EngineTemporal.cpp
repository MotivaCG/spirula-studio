#include "engine/EngineTemporal.h"

#include "backend/api/BackendRuntime.h"
#include "data/DataManager.h"
#include "engine/EngineInternal.h"
#include "engine/EngineState.h"

#include <cmath>
#include <memory>
#include <stdexcept>

namespace {

struct Field {
    void* live;
    size_t bytes;
};

struct Temporal {
    int frames = 0;
    int active = -1;
    int64_t splats = 0;
    // One device block per frame: every per-frame field, back to back.
    std::vector<void*> slots;
    size_t slot_bytes = 0;
    std::vector<std::unique_ptr<DataManager>> sources;
};

std::unique_ptr<Temporal> g_temporal;

// Parameters with their Adam moments, so each frame resumes its own optimizer
// state. Order is the slot layout.
std::vector<Field> per_frame_fields(int64_t n) {
    EngineState& s = engine();
    auto& w = s.world;
    auto& o = s.optim;
    if (o.non_sh_quantize_enabled())
        throw std::runtime_error("chunk training needs quantization_level 0");
    const size_t f3 = sizeof(float3) * n, f4 = sizeof(float4) * n, f1 = sizeof(float) * n;
    std::vector<Field> fields = {
        {w.means.data_ptr(), f3},       {w.quats.data_ptr(), f4},
        {w.opacities.data_ptr(), f1},   {w.features_dc.data_ptr(), f3},
        {o.g1_means.data_ptr(), f3},    {o.g2_means.data_ptr(), f3},
        {o.g1_quats.data_ptr(), f4},    {o.g2_quats.data_ptr(), f4},
        {o.g1_opacities.data_ptr(), f1}, {o.g2_opacities.data_ptr(), f1},
        {o.g1_features_dc.data_ptr(), f3}, {o.g2_features_dc.data_ptr(), f3},
    };
    if (o.bias_correction_steps.data_ptr())
        fields.push_back({o.bias_correction_steps.data_ptr(), sizeof(int32_t) * n});
    for (const Field& f : fields)
        if (!f.live) throw std::runtime_error("chunk training: optimizer state not allocated");
    return fields;
}

void copy_slot(int frame, bool to_live) {
    Temporal& t = *g_temporal;
    char* slot = static_cast<char*>(t.slots[frame]);
    for (const Field& f : per_frame_fields(t.splats)) {
        if (to_live)
            backend::memcpy_async(f.live, slot, f.bytes, backend::MemcpyKind::DeviceToDevice);
        else
            backend::memcpy_async(slot, f.live, f.bytes, backend::MemcpyKind::DeviceToDevice);
        slot += f.bytes;
    }
}

// The first four fields are the parameters themselves; see per_frame_fields.
struct HostParams {
    std::vector<float> means, quats, opacities, dc;
};

HostParams download(int frame) {
    Temporal& t = *g_temporal;
    const size_t n = (size_t)t.splats;
    HostParams h;
    h.means.resize(3 * n);
    h.quats.resize(4 * n);
    h.opacities.resize(n);
    h.dc.resize(3 * n);
    const char* slot = static_cast<const char*>(t.slots[frame]);
    for (std::vector<float>* v : {&h.means, &h.quats, &h.opacities, &h.dc}) {
        backend::memcpy_sync(v->data(), slot, v->size() * sizeof(float),
                             backend::MemcpyKind::DeviceToHost);
        slot += v->size() * sizeof(float);
    }
    return h;
}

void upload(int frame, const HostParams& h) {
    char* slot = static_cast<char*>(g_temporal->slots[frame]);
    for (const std::vector<float>* v : {&h.means, &h.quats, &h.opacities, &h.dc}) {
        backend::memcpy_sync(slot, v->data(), v->size() * sizeof(float),
                             backend::MemcpyKind::HostToDevice);
        slot += v->size() * sizeof(float);
    }
}

// A gradient step on sum_t |D x_t|^2, D the order-th time difference: order 2
// leaves constant-velocity motion alone, order 1 pulls towards a constant.
// w = 1 is a step of 1 / the operator's top eigenvalue (4 or 16).
void smooth(std::vector<std::vector<float>*>& x, size_t width, float w, int order) {
    const int64_t T = (int64_t)x.size();
    if (w <= 0.0f || T < order + 1) return;
    const float eta = w / (order == 1 ? 4.0f : 16.0f);
    const size_t count = x[0]->size();
    std::vector<float> v((size_t)T * width), step((size_t)T * width), sign((size_t)T);
    for (size_t i = 0; i < count; i += width) {
        for (int64_t t = 0; t < T; t++) {
            const float* c = x[t]->data() + i;
            // A quaternion and its negation are one rotation: align each frame
            // with the previous one so the differences measure the rotation.
            sign[t] = 1.0f;
            if (width == 4 && t > 0) {
                float dot = 0.0f;
                for (size_t k = 0; k < 4; k++) dot += c[k] * v[(t - 1) * 4 + k];
                if (dot < 0.0f) sign[t] = -1.0f;
            }
            for (size_t k = 0; k < width; k++) v[t * width + k] = sign[t] * c[k];
        }
        std::fill(step.begin(), step.end(), 0.0f);
        for (int64_t t = 0; t + order < T; t++)
            for (size_t k = 0; k < width; k++) {
                auto at = [&](int64_t s) { return v[s * width + k]; };
                if (order == 1) {
                    const float d = at(t + 1) - at(t);
                    step[t * width + k] -= d;
                    step[(t + 1) * width + k] += d;
                } else {
                    const float a = at(t) - 2.0f * at(t + 1) + at(t + 2);
                    step[t * width + k] += a;
                    step[(t + 1) * width + k] -= 2.0f * a;
                    step[(t + 2) * width + k] += a;
                }
            }
        for (int64_t t = 0; t < T; t++) {
            float* c = x[t]->data() + i;
            float n0 = 0.0f, n1 = 0.0f;
            for (size_t k = 0; k < width; k++) {
                const float y = v[t * width + k] - eta * step[t * width + k];
                n0 += c[k] * c[k];
                n1 += y * y;
                c[k] = sign[t] * y;
            }
            if (width == 4 && n1 > 0.0f) {
                const float r = std::sqrt(n0 / n1);
                for (size_t k = 0; k < 4; k++) c[k] *= r;
            }
        }
    }
}

}  // namespace

void engine_temporal_begin(int frames, bool fused, bool per_splat_bias) {
    if (frames < 1) throw std::runtime_error("chunk training needs at least one frame");
    engine_temporal_end();
    // Adam state is otherwise allocated by the first step; the slots copy it now.
    engine().optim.use_fused_proj_bwd_optim = fused;
    engine().optim.use_per_splat_bias_correction = per_splat_bias;
    engine_ensure_optim_state(32, 32, 32, per_splat_bias);
    auto t = std::make_unique<Temporal>();
    t->frames = frames;
    t->splats = engine().cur_num_splats;
    for (const Field& f : per_frame_fields(t->splats)) t->slot_bytes += f.bytes;
    t->sources.resize(frames);
    g_temporal = std::move(t);
    for (int k = 0; k < frames; k++) {
        g_temporal->slots.push_back(
            backend::device_malloc_checked(g_temporal->slot_bytes, "chunk training frames"));
        copy_slot(k, false);
    }
    backend::device_synchronize();
}

void engine_temporal_end() {
    if (!g_temporal) return;
    backend::device_synchronize();
    for (void* p : g_temporal->slots) backend::device_free(p);
    g_temporal.reset();
}

bool engine_temporal_active() { return g_temporal != nullptr; }
int engine_temporal_frames() { return g_temporal ? g_temporal->frames : 0; }
int engine_temporal_current() { return g_temporal ? g_temporal->active : -1; }

void engine_temporal_stash_data_manager(int frame) {
    if (!g_temporal || frame < 0 || frame >= g_temporal->frames)
        throw std::runtime_error("chunk training: bad frame for a data source");
    if (!engine().dm) throw std::runtime_error("chunk training: no DataManager to stash");
    g_temporal->sources[frame] = std::move(engine().dm);
}

void engine_temporal_select(int frame) {
    Temporal& t = *g_temporal;
    if (frame == t.active) return;
    if (engine().cur_num_splats != t.splats)
        throw std::runtime_error("chunk training: the splat population changed");
    if (!t.sources[frame]) throw std::runtime_error("chunk training: frame has no images");
    if (t.active >= 0) {
        copy_slot(t.active, false);
        t.sources[t.active] = std::move(engine().dm);
    }
    copy_slot(frame, true);
    engine().dm = std::move(t.sources[frame]);
    t.active = frame;
}

void engine_temporal_smooth(const TemporalSmoothing& w, bool hold_first) {
    Temporal& t = *g_temporal;
    if (t.frames < 2) return;
    if (t.active >= 0) copy_slot(t.active, false);
    backend::device_synchronize();
    std::vector<HostParams> h;
    for (int k = 0; k < t.frames; k++) h.push_back(download(k));
    auto column = [&](std::vector<float> HostParams::* m) {
        std::vector<std::vector<float>*> c;
        for (auto& p : h) c.push_back(&(p.*m));
        return c;
    };
    auto means = column(&HostParams::means), quats = column(&HostParams::quats);
    auto opac = column(&HostParams::opacities), dc = column(&HostParams::dc);
    smooth(means, 3, w.position, 2);
    smooth(quats, 4, w.rotation, 2);
    smooth(opac, 1, w.opacity, 1);
    smooth(dc, 3, w.color, 1);
    for (int k = hold_first ? 1 : 0; k < t.frames; k++) upload(k, h[k]);
    if (t.active >= 0) copy_slot(t.active, true);
    backend::device_synchronize();
}

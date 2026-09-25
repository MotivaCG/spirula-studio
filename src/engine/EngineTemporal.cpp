#include "engine/EngineTemporal.h"

#include "backend/api/BackendRuntime.h"
#include "data/DataManager.h"
#include "engine/EngineInternal.h"
#include "engine/EngineState.h"

#include <algorithm>
#include <cmath>
#include <memory>
#include <unordered_map>
#include <stdexcept>

namespace {

struct Field {
    void* live;
    size_t bytes;
};

struct Slot {
    void* mem = nullptr;  // every per-frame field, back to back
    std::unique_ptr<DataManager> dm;
    bool held = false;
};

struct Temporal {
    int active = -1;
    int64_t splats = 0;
    size_t slot_bytes = 0;
    std::vector<Slot> slots;
};

std::unique_ptr<Temporal> g_temporal;

// The slot layout: the per-frame parameters, then their Adam moments and
// bias-correction steps, so each frame resumes its own optimizer state.
std::vector<Field> per_frame_fields(int64_t n) {
    EngineState& s = engine();
    auto& w = s.world;
    auto& o = s.optim;
    if (o.non_sh_quantize_enabled())
        throw std::runtime_error("chunk training needs quantization_level 0");
    const size_t f3 = sizeof(float3) * n, f4 = sizeof(float4) * n, f1 = sizeof(float) * n;
    std::vector<Field> fields = {
        {w.means.data_ptr(), f3}, {w.quats.data_ptr(), f4},
        {w.opacities.data_ptr(), f1}, {w.features_dc.data_ptr(), f3},
    };
    fields.insert(fields.end(), {
        {o.g1_means.data_ptr(), f3},    {o.g2_means.data_ptr(), f3},
        {o.g1_quats.data_ptr(), f4},    {o.g2_quats.data_ptr(), f4},
        {o.g1_opacities.data_ptr(), f1}, {o.g2_opacities.data_ptr(), f1},
        {o.g1_features_dc.data_ptr(), f3}, {o.g2_features_dc.data_ptr(), f3},
    });
    if (o.bias_correction_steps.data_ptr())
        fields.push_back({o.bias_correction_steps.data_ptr(), sizeof(int32_t) * n});
    for (const Field& f : fields)
        if (!f.live) throw std::runtime_error("chunk training: optimizer state not allocated");
    return fields;
}

void copy_slot(int frame, bool to_live) {
    Temporal& t = *g_temporal;
    char* slot = static_cast<char*>(t.slots[frame].mem);
    for (const Field& f : per_frame_fields(t.splats)) {
        if (to_live)
            backend::memcpy_async(f.live, slot, f.bytes, backend::MemcpyKind::DeviceToDevice);
        else
            backend::memcpy_async(slot, f.live, f.bytes, backend::MemcpyKind::DeviceToDevice);
        slot += f.bytes;
    }
}

// The parameter fields at the head of a slot.
struct HostParams {
    std::vector<float> means, quats, opacities, dc;
    std::vector<std::vector<float>*> all() { return {&means, &quats, &opacities, &dc}; }
};

HostParams download(int frame) {
    Temporal& t = *g_temporal;
    const size_t n = (size_t)t.splats;
    HostParams h;
    h.means.resize(3 * n);
    h.quats.resize(4 * n);
    h.opacities.resize(n);
    h.dc.resize(3 * n);
    const char* slot = static_cast<const char*>(t.slots[frame].mem);
    for (std::vector<float>* v : h.all()) {
        backend::memcpy_sync(v->data(), slot, v->size() * sizeof(float),
                             backend::MemcpyKind::DeviceToHost);
        slot += v->size() * sizeof(float);
    }
    return h;
}

void upload(int frame, HostParams& h) {
    char* slot = static_cast<char*>(g_temporal->slots[frame].mem);
    for (const std::vector<float>* v : h.all()) {
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
    t->splats = engine().cur_num_splats;
    for (const Field& f : per_frame_fields(t->splats)) t->slot_bytes += f.bytes;
    g_temporal = std::move(t);
    for (int k = 0; k < frames; k++) {
        g_temporal->slots.emplace_back();
        g_temporal->slots.back().mem =
            backend::device_malloc_checked(g_temporal->slot_bytes, "chunk training frames");
        copy_slot(k, false);
    }
    backend::device_synchronize();
}

void engine_temporal_end() {
    if (!g_temporal) return;
    backend::device_synchronize();
    for (Slot& s : g_temporal->slots) backend::device_free(s.mem);
    g_temporal.reset();
}

bool engine_temporal_active() { return g_temporal != nullptr; }
int engine_temporal_frames() { return g_temporal ? (int)g_temporal->slots.size() : 0; }
int engine_temporal_current() { return g_temporal ? g_temporal->active : -1; }

void engine_temporal_stash_data_manager(int frame) {
    if (!g_temporal || frame < 0 || frame >= engine_temporal_frames())
        throw std::runtime_error("chunk training: bad frame for a data source");
    if (!engine().dm) throw std::runtime_error("chunk training: no DataManager to stash");
    g_temporal->slots[frame].dm = std::move(engine().dm);
}

void engine_temporal_select(int frame) {
    Temporal& t = *g_temporal;
    if (frame == t.active) return;
    if (engine().cur_num_splats != t.splats)
        throw std::runtime_error("chunk training: the splat population changed");
    Slot& to = t.slots[frame];
    if (!to.dm && !to.held) throw std::runtime_error("chunk training: frame has no images");
    engine_temporal_park();
    copy_slot(frame, true);
    engine().dm = std::move(to.dm);
    t.active = frame;
}

void engine_temporal_park() {
    Temporal& t = *g_temporal;
    if (t.active < 0) return;
    copy_slot(t.active, false);
    t.slots[t.active].dm = std::move(engine().dm);
    t.active = -1;
}

namespace {

// Each splat follows its nearest four nodes, weighted exp(-d^2 / r^2), as Forge's
// GraciaWarp skins its graph; splats out of every node's reach stay put.
void apply_warp(const TemporalWarp& w, HostParams& h) {
    const size_t N = w.nodes.size() / 10, n = h.opacities.size();
    const float r = w.bind_radius, cell = 2.0f * r;
    std::unordered_map<int64_t, std::vector<int>> grid;
    auto key = [&](float x, float y, float z) {
        return ((int64_t)std::floor(x / cell) + (1 << 20)) * (int64_t(1) << 42) +
               ((int64_t)std::floor(y / cell) + (1 << 20)) * (int64_t(1) << 21) +
               ((int64_t)std::floor(z / cell) + (1 << 20));
    };
    for (size_t j = 0; j < N; j++) {
        const float* g = w.nodes.data() + 10 * j;
        grid[key(g[0], g[1], g[2])].push_back((int)j);
    }
    for (size_t i = 0; i < n; i++) {
        float* p = h.means.data() + 3 * i;
        std::pair<float, int> best[4] = {{1e30f, -1}, {1e30f, -1}, {1e30f, -1}, {1e30f, -1}};
        for (int dx = -1; dx <= 1; dx++)
            for (int dy = -1; dy <= 1; dy++)
                for (int dz = -1; dz <= 1; dz++) {
                    auto it = grid.find(key(p[0] + dx * cell, p[1] + dy * cell, p[2] + dz * cell));
                    if (it == grid.end()) continue;
                    for (int j : it->second) {
                        const float* g = w.nodes.data() + 10 * j;
                        const float d2 = (g[0] - p[0]) * (g[0] - p[0]) + (g[1] - p[1]) * (g[1] - p[1]) +
                                         (g[2] - p[2]) * (g[2] - p[2]);
                        if (d2 >= best[3].first || d2 > cell * cell) continue;
                        best[3] = {d2, j};
                        std::sort(best, best + 4);
                    }
                }
        float np[3] = {0, 0, 0}, nq[4] = {0, 0, 0, 0}, wsum = 0.0f;
        for (const auto& [d2, j] : best) {
            if (j < 0) continue;
            const float* g = w.nodes.data() + 10 * j;
            const float* t = g + 3;
            const float* q = g + 6;
            const float wt = std::exp(-d2 / (r * r));
            const float qw = q[0], qx = q[1], qy = q[2], qz = q[3];
            const float R[3][3] = {{1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy - qw * qz), 2 * (qx * qz + qw * qy)},
                                   {2 * (qx * qy + qw * qz), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz - qw * qx)},
                                   {2 * (qx * qz - qw * qy), 2 * (qy * qz + qw * qx), 1 - 2 * (qx * qx + qy * qy)}};
            const float e[3] = {p[0] - g[0], p[1] - g[1], p[2] - g[2]};
            for (int a = 0; a < 3; a++)
                np[a] += wt * (R[a][0] * e[0] + R[a][1] * e[1] + R[a][2] * e[2] + g[a] + t[a]);
            const float s = (nq[0] * qw + nq[1] * qx + nq[2] * qy + nq[3] * qz) < 0.0f ? -1.0f : 1.0f;
            for (int a = 0; a < 4; a++) nq[a] += s * wt * q[a];
            wsum += wt;
        }
        if (wsum <= 0.0f) continue;
        for (int a = 0; a < 3; a++) p[a] = np[a] / wsum;
        const float qn = std::sqrt(nq[0] * nq[0] + nq[1] * nq[1] + nq[2] * nq[2] + nq[3] * nq[3]);
        float* q = h.quats.data() + 4 * i;
        const float aw = nq[0] / qn, ax = nq[1] / qn, ay = nq[2] / qn, az = nq[3] / qn;
        const float bw = q[0], bx = q[1], by = q[2], bz = q[3];
        q[0] = aw * bw - ax * bx - ay * by - az * bz;
        q[1] = aw * bx + ax * bw + ay * bz - az * by;
        q[2] = aw * by - ax * bz + ay * bw + az * bx;
        q[3] = aw * bz + ax * by - ay * bx + az * bw;
    }
}

}  // namespace

void engine_temporal_push(float opacity_boost, const TemporalWarp* warp) {
    Temporal& t = *g_temporal;
    if (t.slots.empty() || !engine().dm)
        throw std::runtime_error("chunk training: push needs a frame to extend and images");
    if (t.active >= 0) copy_slot(t.active, false);
    Slot s;
    s.mem = backend::device_malloc_checked(t.slot_bytes, "chunk training frames");
    backend::memcpy_async(s.mem, t.slots.back().mem, t.slot_bytes,
                          backend::MemcpyKind::DeviceToDevice);
    const int n = (int)t.slots.size();
    t.slots.push_back(std::move(s));
    t.slots.back().dm = std::move(engine().dm);
    backend::device_synchronize();
    HostParams last = download(n - 1);
    if (warp) {
        apply_warp(*warp, last);
    } else if (n >= 2) {
        HostParams prev = download(n - 2);
        for (size_t i = 0; i < last.means.size(); i++)
            last.means[i] += last.means[i] - prev.means[i];
    }
    if (opacity_boost != 1.0f)
        for (float& x : last.opacities) {
            const float o = std::min(opacity_boost / (1.0f + std::exp(-x)), 0.99f);
            x = std::log(o / (1.0f - o));
        }
    upload(n, last);
    backend::device_synchronize();
}

void engine_temporal_hold(int frame) {
    Temporal& t = *g_temporal;
    t.slots[frame].held = true;
    if (frame == t.active) engine().dm.reset();
    t.slots[frame].dm.reset();
}

bool engine_temporal_held(int frame) { return g_temporal->slots[frame].held; }

void engine_temporal_drop_front() {
    Temporal& t = *g_temporal;
    if (t.active == 0) {
        engine().dm.reset();
        t.active = -1;
    } else if (t.active > 0) {
        t.active--;
    }
    backend::device_synchronize();
    backend::device_free(t.slots.front().mem);
    t.slots.erase(t.slots.begin());
}

void engine_temporal_smooth(const TemporalSmoothing& w) {
    Temporal& t = *g_temporal;
    const int frames = (int)t.slots.size();
    if (frames < 2) return;
    if (t.active >= 0) copy_slot(t.active, false);
    backend::device_synchronize();
    std::vector<HostParams> h;
    for (int k = 0; k < frames; k++) h.push_back(download(k));
    auto column = [&](std::vector<float> HostParams::* m) {
        std::vector<std::vector<float>*> c;
        for (auto& p : h) c.push_back(&(p.*m));
        return c;
    };
    auto means = column(&HostParams::means), quats = column(&HostParams::quats);
    auto opac = column(&HostParams::opacities), dc = column(&HostParams::dc);
    smooth(means, 3, w.position, 2);
    smooth(quats, 4, w.rotation, 2);
    // In opacity, not logit: a dead frame's logit is far more negative than a
    // live one's is positive, and averaging logits dimmed splats in every frame.
    if (w.opacity > 0.0f) {
        for (auto* v : opac)
            for (float& x : *v) x = 1.0f / (1.0f + std::exp(-x));
        smooth(opac, 1, w.opacity, 1);
        for (auto* v : opac)
            for (float& x : *v) {
                x = std::min(std::max(x, 1e-6f), 1.0f - 1e-6f);
                x = std::log(x / (1.0f - x));
            }
    }
    smooth(dc, 3, w.color, 1);
    for (int k = 0; k < frames; k++)
        if (!t.slots[k].held) upload(k, h[k]);
    if (t.active >= 0) copy_slot(t.active, true);
    backend::device_synchronize();
}

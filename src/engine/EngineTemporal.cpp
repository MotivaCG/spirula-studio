#include "engine/EngineTemporal.h"

#include "backend/api/BackendRuntime.h"
#include "data/DataManager.h"
#include "engine/EngineInternal.h"
#include "engine/EngineState.h"

#include <algorithm>
#include <cmath>
#include <cstring>
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
    std::vector<uint32_t> generation;
    bool held = false;
};

struct Temporal {
    int active = -1;
    int64_t splats = 0;
    size_t slot_bytes = 0;
    std::vector<Slot> slots;
    // Rows whose shared scale and SH no longer train: their record (row,
    // generation) is in a written frame, and .vgs keeps them constant per
    // record. A birth starts a new record and frees the row.
    bool lock_shared = false;
    // Scale and SH per frame (frames loaded whole, see load_frame): slots also
    // carry them, after the optimizer moments so every offset above holds.
    bool per_frame_shape = false;
    // Which rows each loaded frame shows: a refinement keeps it, or smoothing
    // lights rows a frame hid and every one of them is a new .vgs record.
    std::vector<std::vector<uint8_t>> shown;
    std::vector<uint8_t> locked;
    std::vector<float> locked_scales, locked_sh;
};

std::unique_ptr<Temporal> g_temporal;

// Alpha 1/255: what a renderer and the .vgs writer still show.
const float kShownLogit = std::log(1.0f / 254.0f);

// The slot layout: the per-frame parameters, then their Adam moments and
// bias-correction steps, so each frame resumes its own optimizer state.
std::vector<Field> per_frame_fields(int64_t n, bool shape) {
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
    if (shape) {
        const size_t sh = sizeof(float) * 3 * (size_t)engine().num_sh * n;
        fields.insert(fields.end(), {
            {w.scales.data_ptr(), f3}, {w.features_sh.data_ptr(), sh},
            {o.g1_scales.data_ptr(), f3}, {o.g2_scales.data_ptr(), f3},
            {o.g1_features_sh.data_ptr(), sh}, {o.g2_features_sh.data_ptr(), sh},
        });
    }
    for (const Field& f : fields)
        if (!f.live) throw std::runtime_error("chunk training: optimizer state not allocated");
    return fields;
}

void copy_slot(int frame, bool to_live) {
    Temporal& t = *g_temporal;
    char* slot = static_cast<char*>(t.slots[frame].mem);
    for (const Field& f : per_frame_fields(t.splats, t.per_frame_shape)) {
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
void smooth(std::vector<std::vector<float>*>& x, size_t width, float w, int order,
            const std::vector<Slot>& slots) {
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
        for (int64_t t = 0; t + order < T; t++) {
            const uint32_t generation = slots[(size_t)t].generation[i / width];
            bool same_life = true;
            for (int k = 1; k <= order; k++)
                same_life &= generation == slots[(size_t)t + (size_t)k].generation[i / width];
            if (!same_life) continue;
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

void engine_temporal_begin(int frames, bool fused, bool per_splat_bias, bool per_frame_shape) {
    if (frames < 1) throw std::runtime_error("chunk training needs at least one frame");
    engine_temporal_end();
    // Adam state is otherwise allocated by the first step; the slots copy it now.
    engine().optim.use_fused_proj_bwd_optim = fused;
    engine().optim.use_per_splat_bias_correction = per_splat_bias;
    engine_ensure_optim_state(32, 32, 32, per_splat_bias);
    auto t = std::make_unique<Temporal>();
    t->splats = engine().cur_num_splats;
    t->per_frame_shape = per_frame_shape;
    for (const Field& f : per_frame_fields(t->splats, per_frame_shape)) t->slot_bytes += f.bytes;
    g_temporal = std::move(t);
    for (int k = 0; k < frames; k++) {
        g_temporal->slots.emplace_back();
        g_temporal->slots.back().generation.assign((size_t)g_temporal->splats, 0);
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
        const float q2 = g[6] * g[6] + g[7] * g[7] + g[8] * g[8] + g[9] * g[9];
        if (!(q2 >= 0.98f && q2 <= 1.02f)) continue;
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
    s.generation = t.slots.back().generation;
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

namespace {

std::vector<float> get_floats(const void* src, size_t floats) {
    std::vector<float> v(floats);
    backend::device_synchronize();
    backend::memcpy_sync(v.data(), src, floats * 4, backend::MemcpyKind::DeviceToHost);
    return v;
}

void put_floats(void* dst, const std::vector<float>& v) {
    backend::memcpy_sync(dst, v.data(), v.size() * 4, backend::MemcpyKind::HostToDevice);
}

// Rows of the frame being written whose record goes on in the newest frame.
void lock_written_rows(int frame) {
    Temporal& t = *g_temporal;
    EngineState& s = engine();
    const size_t n = (size_t)t.splats, sh_row = 3 * (size_t)s.num_sh;
    if (t.locked.empty()) {
        t.locked.assign(n, 0);
        t.locked_scales.assign(3 * n, 0.0f);
        t.locked_sh.assign(sh_row * n, 0.0f);
    }
    const std::vector<float> scales = get_floats(s.world.scales.data_ptr(), 3 * n);
    const std::vector<float> sh = get_floats(s.world.features_sh.data_ptr(), sh_row * n);
    const std::vector<uint32_t>& written = t.slots[(size_t)frame].generation;
    const std::vector<uint32_t>& newest = t.slots.back().generation;
    for (size_t r = 0; r < n; r++) {
        if (t.locked[r] || written[r] != newest[r]) continue;
        t.locked[r] = 1;
        std::copy_n(scales.data() + 3 * r, 3, t.locked_scales.data() + 3 * r);
        std::copy_n(sh.data() + sh_row * r, sh_row, t.locked_sh.data() + sh_row * r);
    }
}

}  // namespace

void engine_temporal_lock_shared(bool on) { g_temporal->lock_shared = on; }

void engine_temporal_load_frame(int frame, const std::vector<float>& means,
                                const std::vector<float>& quats, const std::vector<float>& opacities,
                                const std::vector<float>& dc, const std::vector<float>& scales,
                                const std::vector<float>& sh) {
    Temporal& t = *g_temporal;
    EngineState& s = engine();
    const size_t n = (size_t)t.splats, sh_row = 3 * (size_t)s.num_sh;
    if (!t.per_frame_shape)
        throw std::runtime_error("chunk training: loading a whole frame needs per-frame shape");
    if (means.size() < 3 * n || quats.size() < 4 * n || opacities.size() < n || dc.size() < 3 * n ||
        scales.size() < 3 * n || sh.size() < sh_row * n)
        throw std::runtime_error("chunk training: a loaded frame has fewer rows than the chunk");
    if (t.active >= 0) copy_slot(t.active, false);
    auto put = [&](void* dst, const std::vector<float>& v, size_t floats) {
        backend::memcpy_sync(dst, v.data(), floats * 4, backend::MemcpyKind::HostToDevice);
    };
    put(s.world.means.data_ptr(), means, 3 * n);
    put(s.world.quats.data_ptr(), quats, 4 * n);
    put(s.world.opacities.data_ptr(), opacities, n);
    put(s.world.features_dc.data_ptr(), dc, 3 * n);
    put(s.world.scales.data_ptr(), scales, 3 * n);
    put(s.world.features_sh.data_ptr(), sh, sh_row * n);
    copy_slot(frame, false);
    t.shown.resize(t.slots.size());
    t.shown[(size_t)frame].resize(n);
    for (size_t r = 0; r < n; r++) t.shown[(size_t)frame][r] = opacities[r] > kShownLogit;
    if (t.active >= 0) copy_slot(t.active, true);
    backend::device_synchronize();
}

void engine_temporal_restore_locked() {
    Temporal& t = *g_temporal;
    if (t.locked.empty()) return;
    EngineState& s = engine();
    const size_t n = (size_t)t.splats, sh_row = 3 * (size_t)s.num_sh;
    std::vector<float> scales = get_floats(s.world.scales.data_ptr(), 3 * n);
    std::vector<float> sh = get_floats(s.world.features_sh.data_ptr(), sh_row * n);
    for (size_t r = 0; r < n; r++) {
        if (!t.locked[r]) continue;
        std::copy_n(t.locked_scales.data() + 3 * r, 3, scales.data() + 3 * r);
        std::copy_n(t.locked_sh.data() + sh_row * r, sh_row, sh.data() + sh_row * r);
    }
    put_floats(s.world.scales.data_ptr(), scales);
    put_floats(s.world.features_sh.data_ptr(), sh);
    backend::device_synchronize();
}

void engine_temporal_hold(int frame) {
    Temporal& t = *g_temporal;
    if (t.lock_shared) lock_written_rows(frame);
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
    smooth(means, 3, w.position, 2, t.slots);
    smooth(quats, 4, w.rotation, 2, t.slots);
    // In opacity, not logit: a dead frame's logit is far more negative than a
    // live one's is positive, and averaging logits dimmed splats in every frame.
    if (w.opacity > 0.0f) {
        for (auto* v : opac)
            for (float& x : *v) x = 1.0f / (1.0f + std::exp(-x));
        smooth(opac, 1, w.opacity, 1, t.slots);
        for (auto* v : opac)
            for (float& x : *v) {
                x = std::min(std::max(x, 1e-6f), 1.0f - 1e-6f);
                x = std::log(x / (1.0f - x));
            }
    }
    smooth(dc, 3, w.color, 1, t.slots);
    for (size_t k = 0; k < t.shown.size() && k < h.size(); k++)
        for (size_t r = 0; r < t.shown[k].size(); r++) {
            float& x = h[k].opacities[r];
            x = t.shown[k][r] ? std::max(x, kShownLogit + 0.01f) : std::min(x, kShownLogit - 0.01f);
        }
    for (int k = 0; k < frames; k++)
        if (!t.slots[k].held) upload(k, h[k]);
    if (t.active >= 0) copy_slot(t.active, true);
    backend::device_synchronize();
}

int64_t engine_temporal_birth(const std::vector<float>& points, float gap, int64_t max_new,
                              std::vector<TemporalBirth>* events) {
    Temporal& t = *g_temporal;
    EngineState& s = engine();
    const size_t n = (size_t)t.splats, frames = t.slots.size(), last = frames - 1;
    if (!(gap > 0.0f) || !std::isfinite(gap))
        throw std::runtime_error("chunk training: birth gap must be finite and positive");
    if (points.size() % 7)
        throw std::runtime_error("chunk training: invalid birth point rows");
    for (float value : points)
        if (!std::isfinite(value))
            throw std::runtime_error("chunk training: non-finite birth point");
    if (points.empty() || max_new <= 0 || frames == 0) return 0;
    if (s.world.sh_value_bits != 32)
        throw std::runtime_error("chunk training: births need full-precision SH");
    if (t.per_frame_shape)
        throw std::runtime_error("chunk training: no births into frames loaded whole");
    if (t.active >= 0) copy_slot(t.active, false);
    backend::device_synchronize();
    std::vector<HostParams> h;
    for (size_t k = 0; k < frames; k++) h.push_back(download((int)k));

    // Rows transparent in every frame: changing their shared scale and SH then
    // changes no frame, trained or already written.
    const float cutoff = 1.0f / 255.0f;
    const float dead = std::log(cutoff / (1.0f - cutoff)), live = std::log(0.1f / 0.9f);
    std::vector<int64_t> free_rows;
    for (size_t i = 0; i < n; i++) {
        bool gone = true;
        for (size_t k = 0; k < frames && gone; k++) gone = h[k].opacities[i] < dead;
        if (gone) free_rows.push_back((int64_t)i);
    }

    // Gaps: points with no live splat of the entering frame within `gap`.
    std::unordered_map<int64_t, std::vector<int>> grid;
    auto key = [&](float x, float y, float z) {
        return ((int64_t)std::floor(x / gap) + (1 << 20)) * (int64_t(1) << 42) +
               ((int64_t)std::floor(y / gap) + (1 << 20)) * (int64_t(1) << 21) +
               ((int64_t)std::floor(z / gap) + (1 << 20));
    };
    const HostParams& cur = h[last];
    for (size_t i = 0; i < n; i++)
        if (cur.opacities[i] > live)
            grid[key(cur.means[3 * i], cur.means[3 * i + 1], cur.means[3 * i + 2])].push_back((int)i);
    std::unordered_map<int64_t, std::vector<size_t>> new_grid;
    std::vector<size_t> born;
    for (size_t p = 0; p + 7 <= points.size() && born.size() < free_rows.size() &&
                       (int64_t)born.size() < max_new; p += 7) {
        const float* q = points.data() + p;
        bool covered = false;
        for (int dx = -1; dx <= 1 && !covered; dx++)
            for (int dy = -1; dy <= 1 && !covered; dy++)
                for (int dz = -1; dz <= 1 && !covered; dz++) {
                    auto it = grid.find(key(q[0] + dx * gap, q[1] + dy * gap, q[2] + dz * gap));
                    if (it == grid.end()) continue;
                    for (int i : it->second) {
                        const float* m = cur.means.data() + 3 * i;
                        const float d2 = (m[0] - q[0]) * (m[0] - q[0]) + (m[1] - q[1]) * (m[1] - q[1]) +
                                         (m[2] - q[2]) * (m[2] - q[2]);
                        if (d2 < gap * gap) { covered = true; break; }
                    }
                }
        for (int dx = -1; dx <= 1 && !covered; dx++)
            for (int dy = -1; dy <= 1 && !covered; dy++)
                for (int dz = -1; dz <= 1 && !covered; dz++) {
                    auto it = new_grid.find(key(q[0] + dx * gap, q[1] + dy * gap, q[2] + dz * gap));
                    if (it == new_grid.end()) continue;
                    for (size_t offset : it->second) {
                        const float* m = points.data() + offset;
                        const float d2 = (m[0] - q[0]) * (m[0] - q[0]) + (m[1] - q[1]) * (m[1] - q[1]) +
                                         (m[2] - q[2]) * (m[2] - q[2]);
                        if (d2 < gap * gap) { covered = true; break; }
                    }
                }
        if (!covered) {
            born.push_back(p);
            new_grid[key(q[0], q[1], q[2])].push_back(p);
        }
    }
    if (born.empty()) return 0;

    auto get = [&](void* src, size_t floats) {
        std::vector<float> v(floats);
        backend::memcpy_sync(v.data(), src, floats * 4, backend::MemcpyKind::DeviceToHost);
        return v;
    };
    auto put = [&](void* dst, const std::vector<float>& v) {
        backend::memcpy_sync(dst, v.data(), v.size() * 4, backend::MemcpyKind::HostToDevice);
    };
    const size_t sh_row = 3 * (size_t)s.num_sh;
    std::vector<float> scales = get(s.world.scales.data_ptr(), 3 * n);
    std::vector<float> sh = get(s.world.features_sh.data_ptr(), sh_row * n);
    constexpr float kSHC0 = 0.28209479177387814f;
    const float start = std::log(0.1f / 0.9f);
    for (size_t j = 0; j < born.size(); j++) {
        const float* q = points.data() + born[j];
        const size_t r = (size_t)free_rows[j];
        HostParams& f = h[last];
        std::copy(q, q + 3, f.means.data() + 3 * r);
        const float ident[4] = {1, 0, 0, 0};
        std::copy(ident, ident + 4, f.quats.data() + 4 * r);
        for (int c = 0; c < 3; c++) f.dc[3 * r + c] = (q[3 + c] - 0.5f) / kSHC0;
        f.opacities[r] = start;
        t.slots[last].generation[r]++;
        if (!t.locked.empty()) t.locked[r] = 0;
        if (events) events->push_back({(int64_t)r, t.slots[last].generation[r]});
        const float ls = std::log(std::max(q[6], 1e-4f) * 0.5f);
        for (int a = 0; a < 3; a++) scales[3 * r + a] = ls;
        std::fill_n(sh.data() + sh_row * r, sh_row, 0.0f);
    }
    for (size_t k = 0; k < frames; k++) upload((int)k, h[k]);
    // The new rows start with no optimizer history, in the entering frame's slot
    // (the moments follow the four parameter fields) and in the shared state.
    for (size_t frame = 0; frame < frames; frame++) {
        const size_t params = n * sizeof(float) * (3 + 4 + 1 + 3);
        std::vector<char> tail(t.slot_bytes - params);
        char* base = static_cast<char*>(t.slots[frame].mem) + params;
        backend::memcpy_sync(tail.data(), base, tail.size(), backend::MemcpyKind::DeviceToHost);
        size_t off = 0;
        for (const Field& f : per_frame_fields(t.splats, false)) {
            if (off < params) { off += f.bytes; continue; }
            const size_t per = f.bytes / n;
            for (size_t j = 0; j < born.size(); j++)
                std::memset(tail.data() + (off - params) + per * (size_t)free_rows[j], 0, per);
            off += f.bytes;
        }
        backend::memcpy_sync(base, tail.data(), tail.size(), backend::MemcpyKind::HostToDevice);
    }
    put(s.world.scales.data_ptr(), scales);
    put(s.world.features_sh.data_ptr(), sh);
    for (void* m : {s.optim.g1_scales.data_ptr(), s.optim.g2_scales.data_ptr()}) {
        std::vector<float> v = get(m, 3 * n);
        for (size_t j = 0; j < born.size(); j++) std::fill_n(v.data() + 3 * free_rows[j], 3, 0.0f);
        put(m, v);
    }
    if (!s.optim.sh_quantize_enabled())
        for (void* m : {s.optim.g1_features_sh.data_ptr(), s.optim.g2_features_sh.data_ptr()}) {
            std::vector<float> v = get(m, sh_row * n);
            for (size_t j = 0; j < born.size(); j++) std::fill_n(v.data() + sh_row * free_rows[j], sh_row, 0.0f);
            put(m, v);
        }
    if (t.active >= 0) copy_slot(t.active, true);
    backend::device_synchronize();
    return (int64_t)born.size();
}

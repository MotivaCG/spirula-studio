#include "engine/EngineSpacetime.h"

#include "backend/api/BackendRuntime.h"
#include "data/DataManager.h"
#include "engine/EngineInternal.h"
#include "engine/EngineSpacetimeMotion.h"
#include "engine/EngineState.h"
#include "nn/core/Parallel.h"

#include <algorithm>
#include <cmath>
#include <memory>
#include <random>
#include <stdexcept>

namespace {

constexpr float kEdge = 0.3f;  // window edge, in frames
constexpr float kBeta1 = 0.9f, kBeta2 = 0.999f, kEps = 1e-15f;
constexpr float kDcMax = 0.5f / 0.28209479177387814f;  // DC of colour 0 or 1
constexpr int kGradPos = 0, kGradRot = kGradPos + kSpacetimePos * 3, kGradColor = kGradRot + kSpacetimeRot * 4,
              kGradOpacity = kGradColor + kSpacetimeColor * 3, kGradWindow = kGradOpacity + kSpacetimeOpacity,
              kGradWidth = kGradWindow + 2;

float sigmoid(float x) { return 1.0f / (1.0f + std::exp(-x)); }

// One Adam state for a parameter array, with a step count per record: a step
// only touches the records the view saw. As the engine's: no first-moment bias
// correction, so a record's first steps are small.
struct Adam {
    std::vector<float> m, v;
    void resize(size_t n) { m.assign(n, 0.0f); v.assign(n, 0.0f); }
    void step(float* x, const float* g, size_t i, size_t width, float lr, float c2) {
        for (size_t k = 0; k < width; k++) {
            const size_t j = i * width + k;
            m[j] = kBeta1 * m[j] + (1.0f - kBeta1) * g[k];
            v[j] = kBeta2 * v[j] + (1.0f - kBeta2) * g[k] * g[k];
            x[j] -= lr * m[j] / (std::sqrt(v[j] / c2) + kEps);
        }
    }
};

struct Spacetime {
    SpacetimeRecords rec;
    int frames = 0, views_per_frame = 0, frame = -1;
    int64_t room = 0;
    // Basis weights per integer frame, [frames, K].
    std::vector<float> bpos, brot, bcolor, bopacity;
    Adam apos, arot, acolor, aopacity, awindow;
    std::vector<int32_t> steps;
    // Gradients of the batch's views per record (kGradWidth each), and whether
    // any view of the batch saw the record.
    std::vector<float> acc;
    std::vector<uint8_t> seen;
    int views = 0;
    // The room as it came in, put back before every step: trained one view at a
    // time, splats out of the view drifted up to metres in 100 steps (battery ST).
    std::vector<float> room_means, room_quats, room_scales, room_opacities, room_dc;
};

std::unique_ptr<Spacetime> g_st;

void* after_room(void* buffer, size_t row_bytes) {
    return static_cast<char*>(buffer) + row_bytes * (size_t)g_st->room;
}

std::vector<float> download(const void* src, size_t floats) {
    std::vector<float> v(floats);
    backend::memcpy_sync(v.data(), src, floats * 4, backend::MemcpyKind::DeviceToHost);
    return v;
}

void upload(void* dst, const std::vector<float>& v) {
    backend::memcpy_sync(dst, v.data(), v.size() * 4, backend::MemcpyKind::HostToDevice);
}

std::vector<float> basis_table(int K, int frames) {
    std::vector<float> b((size_t)frames * K);
    for (int f = 0; f < frames; f++) spacetime_basis(K, frames, (float)f, b.data() + (size_t)f * K);
    return b;
}

}  // namespace

void spacetime_basis(int K, int frames, float t, float* w) {
    constexpr int p = 3;
    if (K <= p) throw std::runtime_error("spacetime: a cubic spline needs more than 3 control points");
    const float u = frames > 1 ? std::clamp(t / (float)(frames - 1), 0.0f, 1.0f) : 0.0f;
    std::fill_n(w, K, 0.0f);
    if (u >= 1.0f) { w[K - 1] = 1.0f; return; }
    const int m = K + p + 1;
    std::vector<float> knot((size_t)m), N((size_t)m - 1);
    for (int i = 0; i < m; i++) knot[i] = i <= p ? 0.0f : i >= K ? 1.0f : (float)(i - p) / (float)(K - p);
    for (int i = 0; i + 1 < m; i++) N[i] = u >= knot[i] && u < knot[i + 1] ? 1.0f : 0.0f;
    for (int d = 1; d <= p; d++)
        for (int i = 0; i + d + 1 < m; i++) {
            const float a = knot[i + d] > knot[i] ? (u - knot[i]) / (knot[i + d] - knot[i]) * N[i] : 0.0f;
            const float b = knot[i + d + 1] > knot[i + 1]
                                ? (knot[i + d + 1] - u) / (knot[i + d + 1] - knot[i + 1]) * N[i + 1]
                                : 0.0f;
            N[i] = a + b;
        }
    std::copy_n(N.begin(), K, w);
}

float spacetime_window(float t0, float t1, float t) {
    return sigmoid((t - t0) / kEdge) * sigmoid((t1 - t) / kEdge);
}

void engine_spacetime_begin(SpacetimeRecords records, int frames, int views_per_frame, int64_t room) {
    if (frames < 2 || views_per_frame < 1) throw std::runtime_error("spacetime: needs frames and views");
    if (room + records.rows != engine().cur_num_splats)
        throw std::runtime_error("spacetime: the records do not fill the engine's rows");
    const size_t n = (size_t)records.rows;
    if (records.pos.size() != n * kSpacetimePos * 3 || records.rot.size() != n * kSpacetimeRot * 4 ||
        records.color.size() != n * kSpacetimeColor * 3 || records.opacity.size() != n * kSpacetimeOpacity ||
        records.window.size() != 2 * n)
        throw std::runtime_error("spacetime: record arrays of the wrong size");
    auto st = std::make_unique<Spacetime>();
    st->rec = std::move(records);
    st->frames = frames;
    st->views_per_frame = views_per_frame;
    st->room = room;
    st->bpos = basis_table(kSpacetimePos, frames);
    st->brot = basis_table(kSpacetimeRot, frames);
    st->bcolor = basis_table(kSpacetimeColor, frames);
    st->bopacity = basis_table(kSpacetimeOpacity, frames);
    st->apos.resize(st->rec.pos.size());
    st->arot.resize(st->rec.rot.size());
    st->acolor.resize(st->rec.color.size());
    st->aopacity.resize(n * kSpacetimeOpacity);
    st->awindow.resize(2 * n);
    st->steps.assign(n, 0);
    if (room > 0) {
        EngineState& s = engine();
        backend::device_synchronize();
        st->room_means = download(s.world.means.data_ptr(), 3 * (size_t)room);
        st->room_quats = download(s.world.quats.data_ptr(), 4 * (size_t)room);
        st->room_scales = download(s.world.scales.data_ptr(), 3 * (size_t)room);
        st->room_opacities = download(s.world.opacities.data_ptr(), (size_t)room);
        st->room_dc = download(s.world.features_dc.data_ptr(), 3 * (size_t)room);
    }
    g_st = std::move(st);
}

void engine_spacetime_end() { g_st.reset(); }
bool engine_spacetime_active() { return g_st != nullptr; }
int engine_spacetime_frame() { return g_st ? g_st->frame : -1; }
int32_t engine_spacetime_camera(int32_t view) { return g_st ? view % g_st->views_per_frame : view; }
const SpacetimeRecords& engine_spacetime_records() { return g_st->rec; }

void engine_spacetime_before_step(const TrainStep& step) {
    if (!g_st) return;
    int frame = -1;
    for (const auto& sub : step.subs)
        for (int32_t view : sub->indices) {
            const int f = view / g_st->views_per_frame;
            if (frame >= 0 && f != frame)
                throw std::runtime_error("spacetime: a step's views span two frames (batch size 1)");
            frame = f;
        }
    if (frame < 0 || frame >= g_st->frames) throw std::runtime_error("spacetime: view outside the chunk");
    engine_spacetime_set_frame(frame);
}

void engine_spacetime_set_frame(int frame, bool unit_quats) {
    Spacetime& st = *g_st;
    EngineState& s = engine();
    const size_t n = (size_t)st.rec.rows;
    std::vector<float> means(3 * n), quats(4 * n), opacities(n), dc(3 * n);
    const float* wp = st.bpos.data() + (size_t)frame * kSpacetimePos;
    const float* wr = st.brot.data() + (size_t)frame * kSpacetimeRot;
    const float* wc = st.bcolor.data() + (size_t)frame * kSpacetimeColor;
    const float* wo = st.bopacity.data() + (size_t)frame * kSpacetimeOpacity;
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        for (int64_t r = lo; r < hi; r++) {
            const float* P = st.rec.pos.data() + (size_t)r * kSpacetimePos * 3;
            const float* Q = st.rec.rot.data() + (size_t)r * kSpacetimeRot * 4;
            const float* C = st.rec.color.data() + (size_t)r * kSpacetimeColor * 3;
            for (int c = 0; c < 3; c++) {
                float x = 0.0f, y = 0.0f;
                for (int k = 0; k < kSpacetimePos; k++) x += wp[k] * P[k * 3 + c];
                for (int k = 0; k < kSpacetimeColor; k++) y += wc[k] * C[k * 3 + c];
                means[3 * r + c] = x;
                dc[3 * r + c] = y;
            }
            for (int c = 0; c < 4; c++) {
                float q = 0.0f;
                for (int k = 0; k < kSpacetimeRot; k++) q += wr[k] * Q[k * 4 + c];
                quats[4 * r + c] = q;
            }
            if (unit_quats) {
                const float* q = quats.data() + 4 * r;
                const float len = std::max(std::sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]), 1e-12f);
                for (int c = 0; c < 4; c++) quats[4 * r + c] /= len;
            }
            const float* w = st.rec.window.data() + 2 * r;
            const float* O = st.rec.opacity.data() + (size_t)r * kSpacetimeOpacity;
            float o = 0.0f;
            for (int k = 0; k < kSpacetimeOpacity; k++) o += wo[k] * O[k];
            const float a = std::clamp(sigmoid(o) * spacetime_window(w[0], w[1], (float)frame), 1e-7f, 1.0f - 1e-6f);
            opacities[r] = std::log(a / (1.0f - a));
        }
    });
    upload(after_room(s.world.means.data_ptr(), 12), means);
    upload(after_room(s.world.quats.data_ptr(), 16), quats);
    upload(after_room(s.world.opacities.data_ptr(), 4), opacities);
    upload(after_room(s.world.features_dc.data_ptr(), 12), dc);
    if (st.room > 0) {
        upload(s.world.means.data_ptr(), st.room_means);
        upload(s.world.quats.data_ptr(), st.room_quats);
        upload(s.world.scales.data_ptr(), st.room_scales);
        upload(s.world.opacities.data_ptr(), st.room_opacities);
        upload(s.world.features_dc.data_ptr(), st.room_dc);
    }
    backend::device_synchronize();
    st.frame = frame;
}

void engine_spacetime_after_step(const SpacetimeRates& lr) {
    Spacetime& st = *g_st;
    EngineState& s = engine();
    if (!s.grad.means.data_ptr() || !s.grad.quats.data_ptr() || !s.grad.opacities.data_ptr() ||
        !s.grad.features_dc.data_ptr())
        throw std::runtime_error("spacetime: no gradient buffers (needs --use-fused-proj-bwd-optim 0)");
    const size_t n = (size_t)st.rec.rows;
    if (st.acc.empty()) {
        st.acc.assign(n * kGradWidth, 0.0f);
        st.seen.assign(n, 0);
    }
    backend::device_synchronize();
    const std::vector<float> gm = download(after_room(s.grad.means.data_ptr(), 12), 3 * n);
    const std::vector<float> gq = download(after_room(s.grad.quats.data_ptr(), 16), 4 * n);
    const std::vector<float> go = download(after_room(s.grad.opacities.data_ptr(), 4), n);
    const std::vector<float> gd = download(after_room(s.grad.features_dc.data_ptr(), 12), 3 * n);
    const float t = (float)st.frame;
    const float* wp = st.bpos.data() + (size_t)st.frame * kSpacetimePos;
    const float* wr = st.brot.data() + (size_t)st.frame * kSpacetimeRot;
    const float* wc = st.bcolor.data() + (size_t)st.frame * kSpacetimeColor;
    const float* wo = st.bopacity.data() + (size_t)st.frame * kSpacetimeOpacity;
    const float reg = lr.opacity_reg / (float)s.cur_num_splats;
    // The view's gradients chained to each record it saw, added to the batch's.
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        for (int64_t r = lo; r < hi; r++) {
            const float* m3 = gm.data() + 3 * r;
            const float* q4 = gq.data() + 4 * r;
            const float* d3 = gd.data() + 3 * r;
            if (m3[0] == 0.0f && m3[1] == 0.0f && m3[2] == 0.0f && go[r] == 0.0f && d3[0] == 0.0f &&
                d3[1] == 0.0f && d3[2] == 0.0f && q4[0] == 0.0f && q4[1] == 0.0f && q4[2] == 0.0f &&
                q4[3] == 0.0f)
                continue;  // not in this view
            float* g = st.acc.data() + (size_t)r * kGradWidth;
            for (int j = 0; j < kSpacetimePos; j++)
                for (int c = 0; c < 3; c++) g[kGradPos + j * 3 + c] += wp[j] * m3[c];
            for (int j = 0; j < kSpacetimeRot; j++)
                for (int c = 0; c < 4; c++) g[kGradRot + j * 4 + c] += wr[j] * q4[c];
            for (int j = 0; j < kSpacetimeColor; j++)
                for (int c = 0; c < 3; c++) g[kGradColor + j * 3 + c] += wc[j] * d3[c];
            // Rendered logit l = logit(sigmoid(o) * phi): dl/do and dl/dt0,1 written
            // so that neither divides by a small alpha or window.
            const float* w = st.rec.window.data() + 2 * r;
            const float* O = st.rec.opacity.data() + (size_t)r * kSpacetimeOpacity;
            float o = 0.0f;
            for (int k = 0; k < kSpacetimeOpacity; k++) o += wo[k] * O[k];
            const float sb = sigmoid(o);
            const float s0 = sigmoid((t - w[0]) / kEdge), s1 = sigmoid((w[1] - t) / kEdge);
            const float a = std::clamp(sb * s0 * s1, 1e-7f, 1.0f - 1e-6f);
            // The penalty max(alpha, 0.5 + l / 4) on rendered splats, as the engine's.
            const float l = std::log(a / (1.0f - a));
            const float gl = go[r] == 0.0f ? 0.0f : go[r] + reg * (a > 0.5f + 0.25f * l ? a * (1.0f - a) : 0.25f);
            const float go_o = gl * (1.0f - sb) / (1.0f - a);
            for (int k = 0; k < kSpacetimeOpacity; k++) g[kGradOpacity + k] += wo[k] * go_o;
            g[kGradWindow] += -gl * (1.0f - s0) / ((1.0f - a) * kEdge);
            g[kGradWindow + 1] += gl * (1.0f - s1) / ((1.0f - a) * kEdge);
            st.seen[r] = 1;
        }
    });
    if (spacetime_motion_active()) {
        const std::vector<float> ls = download(after_room(s.world.scales.data_ptr(), 12), 3 * n);
        spacetime_motion_view({&st.rec, st.frame, ls.data(), gm.data(), gq.data(), go.data(), gd.data(),
                               st.acc.data() + kGradPos, kGradWidth});
    }
    if (++st.views < std::max(lr.batch, 1)) return;

    // One Adam step per record the batch saw, on the batch's mean gradient.
    const std::vector<float> scales = download(after_room(s.world.scales.data_ptr(), 12), 3 * n);
    const float inv = 1.0f / (float)st.views;
    st.views = 0;
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        for (int64_t r = lo; r < hi; r++) {
            if (!st.seen[r]) continue;
            st.seen[r] = 0;
            float* g = st.acc.data() + (size_t)r * kGradWidth;
            for (int k = 0; k < kGradWidth; k++) g[k] *= inv;
            const float c2 = 1.0f - std::pow(kBeta2, (float)++st.steps[r]);
            // Positions step in units of the splat's size, as the engine's
            // scale-agnostic means do: lr_means is a fraction of a splat a step.
            const float* ls = scales.data() + 3 * r;
            const float size = std::exp(std::max({ls[0], ls[1], ls[2]}));
            st.apos.step(st.rec.pos.data(), g + kGradPos, (size_t)r, kSpacetimePos * 3, lr.pos * size, c2);
            st.arot.step(st.rec.rot.data(), g + kGradRot, (size_t)r, kSpacetimeRot * 4, lr.rot, c2);
            st.acolor.step(st.rec.color.data(), g + kGradColor, (size_t)r, kSpacetimeColor * 3, lr.color, c2);
            // As the engine's Adam: base colour within [0, 1], where viewers clamp it;
            // the spline is a convex blend, so every frame's colour stays there too.
            float* C = st.rec.color.data() + (size_t)r * kSpacetimeColor * 3;
            for (int k = 0; k < kSpacetimeColor * 3; k++) C[k] = std::clamp(C[k], -kDcMax, kDcMax);
            st.aopacity.step(st.rec.opacity.data(), g + kGradOpacity, (size_t)r, kSpacetimeOpacity, lr.opacity, c2);
            st.awindow.step(st.rec.window.data(), g + kGradWindow, (size_t)r, 2, lr.window, c2);
            std::fill_n(g, kGradWidth, 0.0f);
        }
    });
}

int64_t engine_spacetime_relocate(int64_t max_new, float min_opacity, uint64_t seed) {
    Spacetime& st = *g_st;
    EngineState& s = engine();
    const size_t n = (size_t)st.rec.rows;
    const int F = st.frames;
    backend::device_synchronize();
    // The densification score since the last call, read and restarted.
    std::vector<float> score(2 * n);
    backend::memcpy_sync(score.data(), s.optim.accum_buffer.data_ptr() + st.room, 2 * n * sizeof(float),
                         backend::MemcpyKind::DeviceToHost);
    s.optim.accum_buffer.zero();
    if (max_new <= 0) return 0;

    // Each record's largest alpha over the chunk.
    std::vector<float> peak(n, 0.0f);
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        for (int64_t r = lo; r < hi; r++) {
            const float* O = st.rec.opacity.data() + (size_t)r * kSpacetimeOpacity;
            const float* w = st.rec.window.data() + 2 * r;
            float best = 0.0f;
            for (int f = 0; f < F; f++) {
                const float* wo = st.bopacity.data() + (size_t)f * kSpacetimeOpacity;
                float o = 0.0f;
                for (int k = 0; k < kSpacetimeOpacity; k++) o += wo[k] * O[k];
                best = std::max(best, sigmoid(o) * spacetime_window(w[0], w[1], (float)f));
            }
            peak[r] = best;
        }
    });
    std::vector<int64_t> dead;
    for (size_t r = 0; r < n; r++)
        if (peak[r] < min_opacity) dead.push_back((int64_t)r);
    // Sources drawn by score without replacement (keys u^(1/w), largest first).
    std::mt19937_64 rng(seed);
    std::uniform_real_distribution<float> uniform(1e-12f, 1.0f);
    std::vector<std::pair<float, int64_t>> keys;
    for (size_t r = 0; r < n; r++)
        if (peak[r] > 0.05f && score[2 * r] > 0.0f) keys.push_back({std::log(uniform(rng)) / score[2 * r], (int64_t)r});
    const size_t count = std::min({(size_t)max_new, dead.size(), keys.size()});
    if (count == 0) return 0;
    std::partial_sort(keys.begin(), keys.begin() + (std::ptrdiff_t)count, keys.end(),
                      [](const auto& a, const auto& b) { return a.first > b.first; });

    const size_t sh = (size_t)s.world.features_sh.size<1>() * 3;
    std::vector<float> scales = download(after_room(s.world.scales.data_ptr(), 12), 3 * n);
    std::vector<float> shs = download(after_room(s.world.features_sh.data_ptr(), 4 * sh), sh * n);
    auto reset = [&](size_t r) {
        auto zero = [&](Adam& a, size_t width) {
            std::fill_n(a.m.begin() + r * width, width, 0.0f);
            std::fill_n(a.v.begin() + r * width, width, 0.0f);
        };
        zero(st.apos, kSpacetimePos * 3);
        zero(st.arot, kSpacetimeRot * 4);
        zero(st.acolor, kSpacetimeColor * 3);
        zero(st.aopacity, kSpacetimeOpacity);
        zero(st.awindow, 2);
        st.steps[r] = 0;
        if (!st.acc.empty()) {
            std::fill_n(st.acc.begin() + r * kGradWidth, kGradWidth, 0.0f);
            st.seen[r] = 0;
        }
        spacetime_motion_forget((int64_t)r);
    };
    for (size_t j = 0; j < count; j++) {
        const size_t src = (size_t)keys[j].second, dst = (size_t)dead[j];
        // The long axis as the record turns at the middle of its life; the halves
        // stay that far apart all chunk long.
        const float* w = st.rec.window.data() + 2 * src;
        const int tm = std::clamp((int)std::lround(0.5f * (std::max(w[0], 0.0f) + std::min(w[1], (float)(F - 1)))), 0, F - 1);
        const float* wr = st.brot.data() + (size_t)tm * kSpacetimeRot;
        const float* Q = st.rec.rot.data() + src * kSpacetimeRot * 4;
        float q[4] = {0, 0, 0, 0};
        for (int k = 0; k < kSpacetimeRot; k++)
            for (int c = 0; c < 4; c++) q[c] += wr[k] * Q[k * 4 + c];
        const float qn = std::sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
        const float qw = q[0] / qn, x = q[1] / qn, y = q[2] / qn, z = q[3] / qn;
        const float R[3][3] = {{1 - 2 * (y * y + z * z), 2 * (x * y - z * qw), 2 * (x * z + y * qw)},
                               {2 * (x * y + z * qw), 1 - 2 * (x * x + z * z), 2 * (y * z - x * qw)},
                               {2 * (x * z - y * qw), 2 * (y * z + x * qw), 1 - 2 * (x * x + y * y)}};
        float* ls = scales.data() + 3 * src;
        const int a = ls[0] > ls[1] && ls[0] > ls[2] ? 0 : ls[1] > ls[2] ? 1 : 2;
        const float d = 0.5f * std::exp(ls[a]);
        float* Ps = st.rec.pos.data() + src * kSpacetimePos * 3;
        float* Pd = st.rec.pos.data() + dst * kSpacetimePos * 3;
        for (int k = 0; k < kSpacetimePos; k++)
            for (int c = 0; c < 3; c++) {
                Pd[k * 3 + c] = Ps[k * 3 + c] + d * R[c][a];
                Ps[k * 3 + c] -= d * R[c][a];
            }
        std::copy_n(Q, kSpacetimeRot * 4, st.rec.rot.data() + dst * kSpacetimeRot * 4);
        std::copy_n(st.rec.color.data() + src * kSpacetimeColor * 3, kSpacetimeColor * 3,
                    st.rec.color.data() + dst * kSpacetimeColor * 3);
        std::copy_n(w, 2, st.rec.window.data() + 2 * dst);
        // Opacity shared so the pair covers what the source did: 1 - (1 - o)^(1/2).
        float* Os = st.rec.opacity.data() + src * kSpacetimeOpacity;
        float* Od = st.rec.opacity.data() + dst * kSpacetimeOpacity;
        for (int k = 0; k < kSpacetimeOpacity; k++) {
            const float half = std::clamp(1.0f - std::sqrt(std::max(1.0f - sigmoid(Os[k]), 1e-6f)), 1e-6f, 1.0f - 1e-6f);
            Os[k] = Od[k] = std::log(half / (1.0f - half));
        }
        for (int c = 0; c < 3; c++) ls[c] += std::log(c == a ? 0.5f : 0.85f);
        std::copy_n(ls, 3, scales.data() + 3 * dst);
        std::copy_n(shs.data() + sh * src, sh, shs.data() + sh * dst);
        reset(src);
        reset(dst);
    }
    upload(after_room(s.world.scales.data_ptr(), 12), scales);
    upload(after_room(s.world.features_sh.data_ptr(), 4 * sh), shs);
    if (st.frame >= 0) engine_spacetime_set_frame(st.frame);
    return (int64_t)count;
}

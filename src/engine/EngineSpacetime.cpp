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

constexpr float kBeta1 = 0.9f, kBeta2 = 0.999f, kEps = 1e-15f;
constexpr float kDcMax = 0.5f / 0.28209479177387814f;  // DC of colour 0 or 1
constexpr float kCull = 0.01f;                          // gamma under this: not drawn
constexpr float kMinSigma = 0.15f;                      // frames (5 ms at 30 fps)
constexpr int kMaxCopies = 50;                          // clones of one donor per relocation
constexpr int kGradPos = 0, kGradRot = kGradPos + kSpacetimePos * 3, kGradColor = kGradRot + kSpacetimeRot * 4,
              kGradOpacity = kGradColor + kSpacetimeColor * 3, kGradMu = kGradOpacity + 1, kGradSigma = kGradMu + 1,
              kGradWidth = kGradSigma + 1;

float sigmoid(float x) { return 1.0f / (1.0f + std::exp(-x)); }
float logit(float a) { return std::log(a / (1.0f - a)); }

// One Adam state for a parameter array, with a step count per record: a step
// only touches the records the batch saw. As the engine's: no first-moment bias
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
    void forget(size_t i, size_t width) {
        std::fill_n(m.begin() + i * width, width, 0.0f);
        std::fill_n(v.begin() + i * width, width, 0.0f);
    }
};

struct Spacetime {
    SpacetimeRecords rec;
    int frames = 0, views_per_frame = 0, frame = -1;
    int64_t room = 0;
    // Basis weights per integer frame, [frames, K].
    std::vector<float> bpos, brot, bcolor;
    Adam apos, arot, acolor, aopacity, amu, asigma, ascale, ash;
    size_t sh = 0;  // SH floats per row
    std::vector<int32_t> steps;
    // Gradients of the batch's views per record (kGradWidth each, scale and SH
    // 3 + sh each), and whether the batch touched the record.
    std::vector<float> acc, acc_shape;
    std::vector<uint8_t> seen;
    int views = 0;
    // |dL/dmu| summed since the last relocation: records whose life wants to move.
    std::vector<float> mu_need;
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

void spline_at(const float* P, const float* w, int K, float* x) {
    x[0] = x[1] = x[2] = 0.0f;
    for (int k = 0; k < K; k++)
        for (int c = 0; c < 3; c++) x[c] += w[k] * P[k * 3 + c];
}

// 3DGS-MCMC's split (Kheradmand et al. 2024, eq. 9): a record and its n - 1 copies
// at alpha_new = 1 - (1 - alpha)^(1/n) and this scale factor cover what it covered.
float mcmc_scale_factor(float alpha, float alpha_new, int n) {
    double denom = 0.0;
    for (int i = 1; i <= n; i++) {
        double binom = 1.0;  // C(i - 1, k)
        for (int k = 0; k < i; k++) {
            denom += binom * (k % 2 ? -1.0 : 1.0) * std::pow((double)alpha_new, k + 1) / std::sqrt((double)k + 1);
            binom = binom * (double)(i - 1 - k) / (double)(k + 1);
        }
    }
    return denom > 0.0 ? std::min((float)(alpha / denom), 1.0f) : 1.0f;
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

float spacetime_life(float mu, float log_sigma, float t) {
    const float z = (t - mu) * std::exp(-log_sigma);
    const float g = std::exp(-0.5f * z * z);
    return g < kCull ? 0.0f : g;
}

float spacetime_alpha(const SpacetimeRecords& rec, int64_t r, float t) {
    return sigmoid(rec.opacity[(size_t)r]) * spacetime_life(rec.mu[(size_t)r], rec.log_sigma[(size_t)r], t);
}

void engine_spacetime_begin(SpacetimeRecords records, int frames, int views_per_frame, int64_t room) {
    if (frames < 2 || views_per_frame < 1) throw std::runtime_error("spacetime: needs frames and views");
    if (room + records.rows != engine().cur_num_splats)
        throw std::runtime_error("spacetime: the records do not fill the engine's rows");
    const size_t n = (size_t)records.rows;
    if (records.pos.size() != n * kSpacetimePos * 3 || records.rot.size() != n * kSpacetimeRot * 4 ||
        records.color.size() != n * kSpacetimeColor * 3 || records.opacity.size() != n || records.mu.size() != n ||
        records.log_sigma.size() != n)
        throw std::runtime_error("spacetime: record arrays of the wrong size");
    auto st = std::make_unique<Spacetime>();
    st->rec = std::move(records);
    st->frames = frames;
    st->views_per_frame = views_per_frame;
    st->room = room;
    st->bpos = basis_table(kSpacetimePos, frames);
    st->brot = basis_table(kSpacetimeRot, frames);
    st->bcolor = basis_table(kSpacetimeColor, frames);
    st->apos.resize(st->rec.pos.size());
    st->arot.resize(st->rec.rot.size());
    st->acolor.resize(st->rec.color.size());
    st->aopacity.resize(n);
    st->amu.resize(n);
    st->asigma.resize(n);
    st->sh = (size_t)engine().world.features_sh.size<1>() * 3;
    st->ascale.resize(3 * n);
    st->ash.resize(st->sh * n);
    st->steps.assign(n, 0);
    st->mu_need.assign(n, 0.0f);
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
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        for (int64_t r = lo; r < hi; r++) {
            spline_at(st.rec.pos.data() + (size_t)r * kSpacetimePos * 3, wp, kSpacetimePos, &means[3 * r]);
            spline_at(st.rec.color.data() + (size_t)r * kSpacetimeColor * 3, wc, kSpacetimeColor, &dc[3 * r]);
            const float* Q = st.rec.rot.data() + (size_t)r * kSpacetimeRot * 4;
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
            opacities[r] = logit(std::clamp(spacetime_alpha(st.rec, r, (float)frame), 1e-7f, 1.0f - 1e-6f));
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
    const size_t n = (size_t)st.rec.rows, shw = 3 + st.sh;
    const bool shape = lr.scale > 0.0f || lr.sh > 0.0f;
    if (shape && (!s.grad.scales.data_ptr() || (st.sh > 0 && !s.grad.features_sh.data_ptr())))
        throw std::runtime_error("spacetime: no scale or SH gradient buffers");
    if (st.acc.empty()) {
        st.acc.assign(n * kGradWidth, 0.0f);
        st.acc_shape.assign(n * shw, 0.0f);
        st.seen.assign(n, 0);
    }
    backend::device_synchronize();
    const std::vector<float> gm = download(after_room(s.grad.means.data_ptr(), 12), 3 * n);
    const std::vector<float> gq = download(after_room(s.grad.quats.data_ptr(), 16), 4 * n);
    const std::vector<float> go = download(after_room(s.grad.opacities.data_ptr(), 4), n);
    const std::vector<float> gd = download(after_room(s.grad.features_dc.data_ptr(), 12), 3 * n);
    std::vector<float> gs, gh;
    if (shape) {
        gs = download(after_room(s.grad.scales.data_ptr(), 12), 3 * n);
        gh = download(after_room(s.grad.features_sh.data_ptr(), 4 * st.sh), st.sh * n);
    }
    const float t = (float)st.frame;
    const float* wp = st.bpos.data() + (size_t)st.frame * kSpacetimePos;
    const float* wr = st.brot.data() + (size_t)st.frame * kSpacetimeRot;
    const float* wc = st.bcolor.data() + (size_t)st.frame * kSpacetimeColor;
    const float reg = lr.opacity_reg / (float)n;
    // The view's gradients chained to each record it saw, added to the batch's.
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        for (int64_t r = lo; r < hi; r++) {
            const float gamma = spacetime_life(st.rec.mu[r], st.rec.log_sigma[r], t);
            if (gamma == 0.0f) continue;  // not drawn at this frame
            float* g = st.acc.data() + (size_t)r * kGradWidth;
            const float sb = sigmoid(st.rec.opacity[r]);
            g[kGradOpacity] += reg * gamma * sb * (1.0f - sb);
            st.seen[r] = 1;
            const float* m3 = gm.data() + 3 * r;
            const float* q4 = gq.data() + 4 * r;
            const float* d3 = gd.data() + 3 * r;
            if (m3[0] == 0.0f && m3[1] == 0.0f && m3[2] == 0.0f && go[r] == 0.0f && d3[0] == 0.0f &&
                d3[1] == 0.0f && d3[2] == 0.0f && q4[0] == 0.0f && q4[1] == 0.0f && q4[2] == 0.0f &&
                q4[3] == 0.0f)
                continue;  // not in this view
            for (int j = 0; j < kSpacetimePos; j++)
                for (int c = 0; c < 3; c++) g[kGradPos + j * 3 + c] += wp[j] * m3[c];
            for (int j = 0; j < kSpacetimeRot; j++)
                for (int c = 0; c < 4; c++) g[kGradRot + j * 4 + c] += wr[j] * q4[c];
            for (int j = 0; j < kSpacetimeColor; j++)
                for (int c = 0; c < 3; c++) g[kGradColor + j * 3 + c] += wc[j] * d3[c];
            // Rendered logit l = logit(a), a = sigmoid(o) * gamma: every derivative
            // carries a / (a (1 - a)) = 1 / (1 - a), none divides by a small alpha.
            const float a = std::clamp(sb * gamma, 1e-7f, 1.0f - 1e-6f);
            const float gl = go[r] / (1.0f - a);
            const float z = (t - st.rec.mu[r]) * std::exp(-st.rec.log_sigma[r]);
            const float gmu = gl * z * std::exp(-st.rec.log_sigma[r]);
            g[kGradOpacity] += gl * (1.0f - sb);
            g[kGradMu] += gmu;
            g[kGradSigma] += gl * z * z;
            st.mu_need[r] += std::abs(gmu);
            if (shape) {
                float* h = st.acc_shape.data() + (size_t)r * shw;
                for (int c = 0; c < 3; c++) h[c] += gs[3 * r + c];
                for (size_t k = 0; k < st.sh; k++) h[3 + k] += gh[st.sh * r + k];
            }
        }
    });
    if (spacetime_motion_active()) {
        const std::vector<float> ls = download(after_room(s.world.scales.data_ptr(), 12), 3 * n);
        spacetime_motion_view({&st.rec, st.frame, ls.data(), gm.data(), gq.data(), go.data(), gd.data(),
                               st.acc.data() + kGradPos, kGradWidth});
    }
    if (++st.views < std::max(lr.batch, 1)) return;

    // One Adam step per record the batch touched, on the batch's mean gradient.
    std::vector<float> scales = download(after_room(s.world.scales.data_ptr(), 12), 3 * n);
    std::vector<float> shs;
    if (shape) shs = download(after_room(s.world.features_sh.data_ptr(), 4 * st.sh), st.sh * n);
    // The engine's shape penalties on their gradients (its optimizer's normalisation):
    // mcmc_scale_reg on log scales, sh_reg an L2 on the coefficients.
    const float scale_reg = lr.scale_reg * 1e-2f / 3.0f / (float)s.cur_num_splats;
    const float sh_reg = 2.0f * lr.sh_reg / (3.0f * (float)s.cur_num_splats);
    const float inv = 1.0f / (float)st.views;
    const float max_mu = (float)(st.frames - 1), min_ls = std::log(kMinSigma), max_ls = std::log((float)st.frames);
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
            st.aopacity.step(st.rec.opacity.data(), g + kGradOpacity, (size_t)r, 1, lr.opacity, c2);
            st.amu.step(st.rec.mu.data(), g + kGradMu, (size_t)r, 1, lr.mu, c2);
            st.asigma.step(st.rec.log_sigma.data(), g + kGradSigma, (size_t)r, 1, lr.sigma, c2);
            st.rec.mu[r] = std::clamp(st.rec.mu[r], 0.0f, max_mu);
            st.rec.log_sigma[r] = std::clamp(st.rec.log_sigma[r], min_ls, max_ls);
            std::fill_n(g, kGradWidth, 0.0f);
            if (!shape) continue;
            float* h = st.acc_shape.data() + (size_t)r * shw;
            for (int c = 0; c < 3; c++) h[c] = h[c] * inv + scale_reg;
            for (size_t k = 0; k < st.sh; k++) h[3 + k] = h[3 + k] * inv + sh_reg * shs[st.sh * r + k];
            st.ascale.step(scales.data(), h, (size_t)r, 3, lr.scale, c2);
            st.ash.step(shs.data(), h + 3, (size_t)r, st.sh, lr.sh, c2);
            std::fill_n(h, shw, 0.0f);
        }
    });
    if (shape) {
        upload(after_room(s.world.scales.data_ptr(), 12), scales);
        upload(after_room(s.world.features_sh.data_ptr(), 4 * st.sh), shs);
    }
}

int64_t engine_spacetime_relocate(int64_t max_new, float min_opacity, uint64_t seed) {
    Spacetime& st = *g_st;
    EngineState& s = engine();
    const size_t n = (size_t)st.rec.rows;
    const int F = st.frames;
    backend::device_synchronize();
    // The screen-gradient score (sum, views) since the last call, read and restarted.
    std::vector<float> score(2 * n);
    backend::memcpy_sync(score.data(), s.optim.accum_buffer.data_ptr() + st.room, 2 * n * sizeof(float),
                         backend::MemcpyKind::DeviceToHost);
    s.optim.accum_buffer.zero();
    std::vector<float> mu_need(n, 0.0f);
    std::swap(mu_need, st.mu_need);
    if (max_new <= 0) return 0;

    // Need of each live record: its alpha, how far it moves over its life, its
    // mean screen gradient and its life-centre gradient, each cue over its total.
    std::vector<int64_t> dead, live;
    for (size_t r = 0; r < n; r++) (sigmoid(st.rec.opacity[r]) < min_opacity ? dead : live).push_back((int64_t)r);
    if (dead.empty() || live.empty()) return 0;
    std::vector<float> cue(4 * live.size());
    double total[4] = {0, 0, 0, 0};
    for (size_t i = 0; i < live.size(); i++) {
        const size_t r = (size_t)live[i];
        const int f = std::clamp((int)std::lround(st.rec.mu[r]), 0, F - 2);
        float p0[3], p1[3];
        const float* P = st.rec.pos.data() + r * kSpacetimePos * 3;
        spline_at(P, st.bpos.data() + (size_t)f * kSpacetimePos, kSpacetimePos, p0);
        spline_at(P, st.bpos.data() + (size_t)(f + 1) * kSpacetimePos, kSpacetimePos, p1);
        const float speed = std::sqrt((p1[0] - p0[0]) * (p1[0] - p0[0]) + (p1[1] - p0[1]) * (p1[1] - p0[1]) +
                                      (p1[2] - p0[2]) * (p1[2] - p0[2]));
        const float c[4] = {sigmoid(st.rec.opacity[r]), speed * std::exp(st.rec.log_sigma[r]),
                            score[2 * r] / std::max(score[2 * r + 1], 1.0f), mu_need[r]};
        for (int k = 0; k < 4; k++) {
            cue[4 * i + k] = c[k];
            total[k] += c[k];
        }
    }
    std::vector<double> need(live.size());
    for (size_t i = 0; i < live.size(); i++)
        for (int k = 0; k < 4; k++) need[i] += total[k] > 0.0 ? cue[4 * i + k] / total[k] : 0.0;
    std::mt19937_64 rng(seed);
    std::discrete_distribution<size_t> draw(need.begin(), need.end());
    std::uniform_real_distribution<float> shift(-0.25f, 0.25f);
    const size_t want = std::min((size_t)max_new, dead.size());
    std::vector<int32_t> copies(live.size(), 0);
    std::vector<std::pair<size_t, int64_t>> moves;  // (live index, dead record)
    for (size_t j = 0; j < want; j++) {
        const size_t i = draw(rng);
        if (copies[i] >= kMaxCopies) continue;
        copies[i]++;
        moves.push_back({i, dead[moves.size()]});
    }
    if (moves.empty()) return 0;

    const size_t sh = (size_t)s.world.features_sh.size<1>() * 3;
    std::vector<float> scales = download(after_room(s.world.scales.data_ptr(), 12), 3 * n);
    std::vector<float> shs = download(after_room(s.world.features_sh.data_ptr(), 4 * sh), sh * n);
    auto forget = [&](size_t r) {
        st.apos.forget(r, kSpacetimePos * 3);
        st.arot.forget(r, kSpacetimeRot * 4);
        st.acolor.forget(r, kSpacetimeColor * 3);
        st.aopacity.forget(r, 1);
        st.amu.forget(r, 1);
        st.asigma.forget(r, 1);
        st.ascale.forget(r, 3);
        st.ash.forget(r, st.sh);
        st.steps[r] = 0;
        if (!st.acc.empty()) {
            std::fill_n(st.acc.begin() + r * kGradWidth, kGradWidth, 0.0f);
            std::fill_n(st.acc_shape.begin() + r * (3 + st.sh), 3 + st.sh, 0.0f);
            st.seen[r] = 0;
        }
        spacetime_motion_forget((int64_t)r);
    };
    // Donors first: alpha and scale shared with their copies, then the copies take them.
    for (size_t i = 0; i < live.size(); i++) {
        if (!copies[i]) continue;
        const size_t r = (size_t)live[i];
        const int parts = copies[i] + 1;
        const float alpha = sigmoid(st.rec.opacity[r]);
        const float alpha_new = std::max(1.0f - std::pow(1.0f - alpha, 1.0f / (float)parts), min_opacity);
        const float k = std::log(mcmc_scale_factor(alpha, alpha_new, parts));
        st.rec.opacity[r] = logit(std::min(alpha_new, 1.0f - 1e-6f));
        for (int c = 0; c < 3; c++) scales[3 * r + c] += k;
        forget(r);
    }
    for (const auto& [i, d] : moves) {
        const size_t src = (size_t)live[i], dst = (size_t)d;
        std::copy_n(st.rec.pos.data() + src * kSpacetimePos * 3, kSpacetimePos * 3,
                    st.rec.pos.data() + dst * kSpacetimePos * 3);
        std::copy_n(st.rec.rot.data() + src * kSpacetimeRot * 4, kSpacetimeRot * 4,
                    st.rec.rot.data() + dst * kSpacetimeRot * 4);
        std::copy_n(st.rec.color.data() + src * kSpacetimeColor * 3, kSpacetimeColor * 3,
                    st.rec.color.data() + dst * kSpacetimeColor * 3);
        st.rec.opacity[dst] = st.rec.opacity[src];
        st.rec.log_sigma[dst] = st.rec.log_sigma[src];
        // Exact copies would take the same gradients forever: the life shift parts them.
        st.rec.mu[dst] = std::clamp(st.rec.mu[src] + shift(rng) * std::exp(st.rec.log_sigma[src]), 0.0f,
                                    (float)(F - 1));
        std::copy_n(scales.data() + 3 * src, 3, scales.data() + 3 * dst);
        std::copy_n(shs.data() + sh * src, sh, shs.data() + sh * dst);
        forget(dst);
    }
    upload(after_room(s.world.scales.data_ptr(), 12), scales);
    upload(after_room(s.world.features_sh.data_ptr(), 4 * sh), shs);
    if (st.frame >= 0) engine_spacetime_set_frame(st.frame);
    return (int64_t)moves.size();
}

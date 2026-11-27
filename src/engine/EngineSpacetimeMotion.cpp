#include "engine/EngineSpacetimeMotion.h"

#include "engine/EngineSpacetime.h"
#include "nn/core/Parallel.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <limits>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <vector>

namespace {

constexpr float kSigma = 0.002f;     // robust scale of the step error (m)
constexpr float kRadius = 0.005f;    // field points a record reads (m), also the grid cell
constexpr float kAlong = 0.003f;     // their largest distance along the field point's normal (m)
constexpr float kNormalDot = 0.5f;   // compatible surfaces: |n_record . n_point| above this
constexpr float kDrift = 0.0025f;    // a cached target is read again past this move (m)
constexpr float kTurn = 0.866f;      // or past a 30 degree turn of the record's normal
constexpr float kFlat = 0.6f;        // a normal when the short axis is under this share of the middle one
constexpr float kMinDist = 0.0005f;  // inverse distance weights saturate here (m)
constexpr int kCalibrationViews = 200;
constexpr size_t kMinSamples = 1000;

int64_t cell_key(int64_t x, int64_t y, int64_t z) {
    constexpr int64_t o = int64_t(1) << 20;
    return ((x + o) << 42) | ((y + o) << 21) | (z + o);
}

int64_t cell_of(float v) { return (int64_t)std::floor(v / kRadius); }

// One direction of one frame's scene flow: points sorted by grid cell.
struct Field {
    std::vector<float> pos, step, normal, conf;
    std::vector<int64_t> keys;
};

Field load_field(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    char magic[4] = {};
    int32_t n = 0;
    in.read(magic, 4);
    in.read(reinterpret_cast<char*>(&n), 4);
    if (!in || std::string(magic, 4) != "MSF1" || n < 0) throw std::runtime_error("--spacetime-motion: cannot read " + path);
    std::vector<float> pos(3 * (size_t)n), step(3 * (size_t)n), normal(3 * (size_t)n), conf((size_t)n);
    in.read(reinterpret_cast<char*>(pos.data()), (std::streamsize)(pos.size() * 4));
    in.read(reinterpret_cast<char*>(step.data()), (std::streamsize)(step.size() * 4));
    in.read(reinterpret_cast<char*>(normal.data()), (std::streamsize)(normal.size() * 4));
    in.read(reinterpret_cast<char*>(conf.data()), (std::streamsize)(conf.size() * 4));
    if (!in) throw std::runtime_error("--spacetime-motion: " + path + " is truncated");
    std::vector<std::pair<int64_t, int32_t>> order;
    for (int32_t i = 0; i < n; i++)
        if (conf[(size_t)i] > 0.0f)
            order.push_back({cell_key(cell_of(pos[3 * (size_t)i]), cell_of(pos[3 * (size_t)i + 1]), cell_of(pos[3 * (size_t)i + 2])), i});
    std::sort(order.begin(), order.end());
    Field f;
    for (const auto& [key, i] : order) {
        f.keys.push_back(key);
        f.pos.insert(f.pos.end(), &pos[3 * (size_t)i], &pos[3 * (size_t)i] + 3);
        f.step.insert(f.step.end(), &step[3 * (size_t)i], &step[3 * (size_t)i] + 3);
        f.normal.insert(f.normal.end(), &normal[3 * (size_t)i], &normal[3 * (size_t)i] + 3);
        f.conf.push_back(conf[(size_t)i]);
    }
    return f;
}

// The field's step at p for a record of normal n (zero: none): points within
// kRadius on a compatible surface, weighted by confidence over distance. The
// confidence returned is their distance-weighted mean, 0 with none.
float read_field(const Field& f, const float* p, const float* n, float* s) {
    double su = 0.0, suc = 0.0, st[3] = {0.0, 0.0, 0.0};
    const int64_t cx = cell_of(p[0]), cy = cell_of(p[1]), cz = cell_of(p[2]);
    const bool has_n = n[0] != 0.0f || n[1] != 0.0f || n[2] != 0.0f;
    for (int64_t dx = -1; dx <= 1; dx++)
        for (int64_t dy = -1; dy <= 1; dy++)
            for (int64_t dz = -1; dz <= 1; dz++) {
                const auto range = std::equal_range(f.keys.begin(), f.keys.end(), cell_key(cx + dx, cy + dy, cz + dz));
                for (auto it = range.first; it != range.second; ++it) {
                    const size_t i = (size_t)(it - f.keys.begin());
                    const float* q = &f.pos[3 * i];
                    const float d[3] = {q[0] - p[0], q[1] - p[1], q[2] - p[2]};
                    const float dist = std::sqrt(d[0] * d[0] + d[1] * d[1] + d[2] * d[2]);
                    if (dist > kRadius) continue;
                    const float* m = &f.normal[3 * i];
                    if (m[0] != 0.0f || m[1] != 0.0f || m[2] != 0.0f) {
                        if (std::abs(d[0] * m[0] + d[1] * m[1] + d[2] * m[2]) > kAlong) continue;
                        if (has_n && std::abs(n[0] * m[0] + n[1] * m[1] + n[2] * m[2]) < kNormalDot) continue;
                    }
                    const double u = 1.0 / std::max(dist, kMinDist), uc = u * f.conf[i];
                    su += u;
                    suc += uc;
                    for (int c = 0; c < 3; c++) st[c] += uc * f.step[3 * i + c];
                }
            }
    for (int c = 0; c < 3; c++) s[c] = suc > 0.0 ? (float)(st[c] / suc) : 0.0f;
    return su > 0.0 ? (float)(suc / su) : 0.0f;
}

// A record's targets at one frame, read at position q with normal n.
struct Entry {
    float q[3] = {std::numeric_limits<float>::quiet_NaN(), 0.0f, 0.0f}, n[3] = {0.0f, 0.0f, 0.0f};
    float sf[3] = {0.0f, 0.0f, 0.0f}, cf = 0.0f, sb[3] = {0.0f, 0.0f, 0.0f}, cb = 0.0f;
};

struct Motion {
    std::vector<Field> fwd, bwd;  // by frame; fwd[F - 1] and bwd[0] empty
    int frames = 0;
    float weight = 0.0f, lambda = 0.0f;
    std::vector<float> bpos, brot;
    std::vector<Entry> cache;  // [rows, frames]
    int views = 0;
    std::vector<float> samples;
    std::mutex mu;
};

std::unique_ptr<Motion> g_motion;

std::vector<float> basis_table(int K, int frames) {
    std::vector<float> b((size_t)frames * K);
    for (int f = 0; f < frames; f++) spacetime_basis(K, frames, (float)f, b.data() + (size_t)f * K);
    return b;
}

// The record's short axis at a frame, zero when it has no clear one.
void record_normal(const float* Q, const float* wr, const float* ls, float* n) {
    float q[4] = {0, 0, 0, 0};
    for (int k = 0; k < kSpacetimeRot; k++)
        for (int c = 0; c < 4; c++) q[c] += wr[k] * Q[k * 4 + c];
    const float len = std::sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
    n[0] = n[1] = n[2] = 0.0f;
    if (len < 1e-12f) return;
    const float w = q[0] / len, x = q[1] / len, y = q[2] / len, z = q[3] / len;
    int a = 0;
    for (int c = 1; c < 3; c++)
        if (ls[c] < ls[a]) a = c;
    float mid = std::numeric_limits<float>::max();
    for (int c = 0; c < 3; c++)
        if (c != a) mid = std::min(mid, ls[c]);
    if (std::exp(ls[a] - mid) >= kFlat) return;
    const float R[3][3] = {{1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)},
                           {2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)},
                           {2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)}};
    for (int c = 0; c < 3; c++) n[c] = R[c][a];
}

}  // namespace

float spacetime_motion_pair(const float* P, const float* bf, const float* bg, const float* s, float w, float lambda,
                            float* grad) {
    float e[3];
    for (int c = 0; c < 3; c++) {
        float pf = 0.0f, pg = 0.0f;
        for (int k = 0; k < kSpacetimePos; k++) {
            pf += bf[k] * P[k * 3 + c];
            pg += bg[k] * P[k * 3 + c];
        }
        e[c] = pg - pf - s[c];
    }
    const float root = std::sqrt(1.0f + (e[0] * e[0] + e[1] * e[1] + e[2] * e[2]) / (kSigma * kSigma));
    const float coef = lambda * w / (kSigma * kSigma * root);
    for (int k = 0; k < kSpacetimePos; k++) {
        const float db = bg[k] - bf[k];
        for (int c = 0; c < 3; c++) grad[k * 3 + c] += coef * db * e[c];
    }
    return lambda * w * (root - 1.0f);
}

void spacetime_motion_begin(const std::string& dir, float weight, int frames, int64_t rows) {
    if (dir.empty() || dir == "none") throw std::runtime_error("--spacetime-motion-weight needs --spacetime-motion");
    auto m = std::make_unique<Motion>();
    m->frames = frames;
    m->weight = weight;
    m->fwd.resize((size_t)frames);
    m->bwd.resize((size_t)frames);
    size_t points = 0;
    for (int f = 0; f < frames; f++) {
        char name[32];
        if (f + 1 < frames) {
            std::snprintf(name, sizeof name, "/fwd_%03d.bin", f);
            m->fwd[(size_t)f] = load_field(dir + name);
            points += m->fwd[(size_t)f].conf.size();
        }
        if (f > 0) {
            std::snprintf(name, sizeof name, "/bwd_%03d.bin", f);
            m->bwd[(size_t)f] = load_field(dir + name);
            points += m->bwd[(size_t)f].conf.size();
        }
    }
    m->bpos = basis_table(kSpacetimePos, frames);
    m->brot = basis_table(kSpacetimeRot, frames);
    m->cache.assign((size_t)rows * (size_t)frames, Entry{});
    std::fprintf(stderr, "[spirula] spacetime motion: %zu field points over %d frames from %s, weight %g\n", points,
                 frames, dir.c_str(), weight);
    g_motion = std::move(m);
}

bool spacetime_motion_active() { return g_motion != nullptr; }

void spacetime_motion_forget(int64_t record) {
    if (!g_motion) return;
    Motion& m = *g_motion;
    std::fill_n(m.cache.begin() + record * m.frames, m.frames, Entry{});
}

void spacetime_motion_view(const SpacetimeMotionView& v) {
    Motion& m = *g_motion;
    const SpacetimeRecords& rec = *v.rec;
    const int F = m.frames, f = v.frame;
    const float* bf = m.bpos.data() + (size_t)f * kSpacetimePos;
    const float* wr = m.brot.data() + (size_t)f * kSpacetimeRot;
    const float* bnext = f + 1 < F ? m.bpos.data() + (size_t)(f + 1) * kSpacetimePos : nullptr;
    const float* bprev = f > 0 ? m.bpos.data() + (size_t)(f - 1) * kSpacetimePos : nullptr;
    const bool calibrating = m.views < kCalibrationViews;
    // Calibration: lambda where a step error of sigma (w = 1) pulls as hard as the
    // median photometric position gradient of the eligible records.
    float bnorm = 0.0f, dnorm = 0.0f;
    for (int k = 0; k < kSpacetimePos; k++) {
        const float d = (bnext ? bnext[k] : bprev[k]) - bf[k];
        bnorm += bf[k] * bf[k];
        dnorm += d * d;
    }
    const float to_lambda = std::sqrt(bnorm) * kSigma * std::sqrt(2.0f) / std::max(std::sqrt(dnorm), 1e-12f);
    nn::parallel_for(rec.rows, [&](int64_t lo, int64_t hi) {
        std::vector<float> samples;
        for (int64_t r = lo; r < hi; r++) {
            const float* m3 = v.grad_means + 3 * r;
            const float* q4 = v.grad_quats + 4 * r;
            const float* d3 = v.grad_dc + 3 * r;
            if (m3[0] == 0.0f && m3[1] == 0.0f && m3[2] == 0.0f && v.grad_opacities[r] == 0.0f && d3[0] == 0.0f &&
                d3[1] == 0.0f && d3[2] == 0.0f && q4[0] == 0.0f && q4[1] == 0.0f && q4[2] == 0.0f && q4[3] == 0.0f)
                continue;
            const float* P = rec.pos.data() + (size_t)r * kSpacetimePos * 3;
            float p[3] = {0, 0, 0}, n[3];
            for (int k = 0; k < kSpacetimePos; k++)
                for (int c = 0; c < 3; c++) p[c] += bf[k] * P[k * 3 + c];
            record_normal(rec.rot.data() + (size_t)r * kSpacetimeRot * 4, wr, v.log_scales + 3 * r, n);
            Entry& e = m.cache[(size_t)r * F + f];
            const float dq[3] = {p[0] - e.q[0], p[1] - e.q[1], p[2] - e.q[2]};
            const bool had_n = e.n[0] != 0.0f || e.n[1] != 0.0f || e.n[2] != 0.0f;
            const bool has_n = n[0] != 0.0f || n[1] != 0.0f || n[2] != 0.0f;
            const bool turned = had_n != has_n || (has_n && std::abs(n[0] * e.n[0] + n[1] * e.n[1] + n[2] * e.n[2]) < kTurn);
            if (std::isnan(e.q[0]) || dq[0] * dq[0] + dq[1] * dq[1] + dq[2] * dq[2] > kDrift * kDrift || turned) {
                std::copy_n(p, 3, e.q);
                std::copy_n(n, 3, e.n);
                e.cf = bnext ? read_field(m.fwd[(size_t)f], p, n, e.sf) : 0.0f;
                e.cb = bprev ? read_field(m.bwd[(size_t)f], p, n, e.sb) : 0.0f;
            }
            if (calibrating) {
                const float g = std::sqrt(m3[0] * m3[0] + m3[1] * m3[1] + m3[2] * m3[2]);
                if ((e.cf > 0.0f || e.cb > 0.0f) && g > 0.0f && r % 4 == 0) samples.push_back(g * to_lambda);
                continue;
            }
            const float alpha = spacetime_alpha(rec, r, (float)f);
            float* grad = v.acc + (size_t)r * v.stride;
            if (e.cf > 0.0f) spacetime_motion_pair(P, bf, bnext, e.sf, e.cf * alpha, m.lambda, grad);
            if (e.cb > 0.0f) spacetime_motion_pair(P, bf, bprev, e.sb, e.cb * alpha, m.lambda, grad);
        }
        if (!samples.empty()) {
            std::lock_guard<std::mutex> lock(m.mu);
            m.samples.insert(m.samples.end(), samples.begin(), samples.end());
        }
    });
    if (++m.views != kCalibrationViews) return;
    const size_t count = m.samples.size();
    if (count < kMinSamples)
        throw std::runtime_error("spacetime motion: " + std::to_string(count) + " calibration samples, too few");
    std::nth_element(m.samples.begin(), m.samples.begin() + (std::ptrdiff_t)(count / 2), m.samples.end());
    const float median = m.samples[count / 2];
    if (!(median > 0.0f)) throw std::runtime_error("spacetime motion: zero photometric gradients to calibrate on");
    m.lambda = m.weight * median;
    m.samples = {};
    std::fprintf(stderr, "[spirula] spacetime motion: lambda %g (weight %g x median %g over %zu samples)\n", m.lambda,
                 m.weight, median, count);
}

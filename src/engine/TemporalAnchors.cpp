#include "engine/TemporalAnchors.h"

#include "nn/core/Parallel.h"

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <unordered_set>

namespace {

int64_t cell_key(float x, float y, float z, float cell) {
    return ((int64_t)std::floor(x / cell) + (1 << 20)) * (int64_t(1) << 42) +
           ((int64_t)std::floor(y / cell) + (1 << 20)) * (int64_t(1) << 21) +
           ((int64_t)std::floor(z / cell) + (1 << 20));
}

size_t occupied(const std::vector<float>& points, float cell) {
    std::unordered_set<int64_t> cells;
    for (size_t i = 0; i + 2 < points.size(); i += 3)
        cells.insert(cell_key(points[i], points[i + 1], points[i + 2], cell));
    return cells.size();
}

// Solves the 4x4 symmetric positive definite system a x = b in place.
void solve4(double a[4][4], double b[4]) {
    for (int k = 0; k < 4; k++) {
        for (int i = k + 1; i < 4; i++) {
            const double f = a[i][k] / a[k][k];
            for (int j = k; j < 4; j++) a[i][j] -= f * a[k][j];
            b[i] -= f * b[k];
        }
    }
    for (int k = 3; k >= 0; k--) {
        for (int j = k + 1; j < 4; j++) b[k] -= a[k][j] * b[j];
        b[k] /= a[k][k];
    }
}

}  // namespace

AnchorRig anchor_rig(const std::vector<float>& all, const std::vector<float>& subject, int anchors,
                     size_t rows) {
    const float near = 0.04f;
    std::unordered_set<int64_t> around;
    for (size_t i = 0; i + 2 < subject.size(); i += 3)
        for (int dx = -1; dx <= 1; dx++)
            for (int dy = -1; dy <= 1; dy++)
                for (int dz = -1; dz <= 1; dz++)
                    around.insert(cell_key(subject[i] + dx * near, subject[i + 1] + dy * near,
                                           subject[i + 2] + dz * near, near));
    std::vector<float> points;
    for (size_t i = 0; i + 2 < all.size(); i += 3)
        if (around.count(cell_key(all[i], all[i + 1], all[i + 2], near)))
            points.insert(points.end(), &all[i], &all[i] + 3);
    if (anchors < 1 || points.size() < 3) throw std::runtime_error("anchors: no splats on the subject");
    float lo[3] = {1e30f, 1e30f, 1e30f}, hi[3] = {-1e30f, -1e30f, -1e30f};
    for (size_t i = 0; i + 2 < points.size(); i += 3)
        for (int a = 0; a < 3; a++) {
            lo[a] = std::min(lo[a], points[i + a]);
            hi[a] = std::max(hi[a], points[i + a]);
        }
    // The cell whose occupied count is closest to `anchors`, by bisection.
    float small = 1e-4f, large = std::max({hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2], 1e-3f});
    for (int it = 0; it < 30; it++) {
        const float mid = std::sqrt(small * large);
        (occupied(points, mid) > (size_t)anchors ? small : large) = mid;
    }
    AnchorRig rig;
    rig.spacing = large;
    std::unordered_map<int64_t, size_t> slot;
    std::vector<double> sum;
    std::vector<size_t> count;
    for (size_t i = 0; i + 2 < points.size(); i += 3) {
        const auto [it, fresh] =
            slot.try_emplace(cell_key(points[i], points[i + 1], points[i + 2], rig.spacing), count.size());
        if (fresh) {
            sum.insert(sum.end(), {0.0, 0.0, 0.0});
            count.push_back(0);
        }
        for (int a = 0; a < 3; a++) sum[3 * it->second + a] += points[i + a];
        count[it->second]++;
    }
    rig.rest.resize(sum.size());
    for (size_t k = 0; k < count.size(); k++)
        for (int a = 0; a < 3; a++) rig.rest[3 * k + a] = (float)(sum[3 * k + a] / (double)count[k]);
    rig.index.assign(rows, {0, 0, 0, 0});
    rig.weight.assign(rows, {0.0f, 0.0f, 0.0f, 0.0f});
    return rig;
}

AnchorGrid anchor_grid(const AnchorRig& rig, const std::vector<float>& at) {
    AnchorGrid g;
    g.at = &at;
    g.cell = rig.spacing;
    for (size_t k = 0; 3 * k + 2 < at.size(); k++)
        g.cells[cell_key(at[3 * k], at[3 * k + 1], at[3 * k + 2], g.cell)].push_back((int32_t)k);
    return g;
}

void anchor_bind(AnchorRig& rig, const AnchorGrid& grid, size_t row, const float* p) {
    const std::vector<float>& at = *grid.at;
    std::pair<float, int32_t> best[4] = {{1e30f, -1}, {1e30f, -1}, {1e30f, -1}, {1e30f, -1}};
    // Rings of cells outward until four anchors are found and no closer one can
    // lie in a ring not searched yet.
    for (int r = 1; r <= 8; r++) {
        for (int dx = -r; dx <= r; dx++)
            for (int dy = -r; dy <= r; dy++)
                for (int dz = -r; dz <= r; dz++) {
                    if (std::max({std::abs(dx), std::abs(dy), std::abs(dz)}) != r && r > 1) continue;
                    auto it = grid.cells.find(cell_key(p[0] + dx * grid.cell, p[1] + dy * grid.cell,
                                                       p[2] + dz * grid.cell, grid.cell));
                    if (it == grid.cells.end()) continue;
                    for (int32_t k : it->second) {
                        const float* a = at.data() + 3 * k;
                        const float d2 = (a[0] - p[0]) * (a[0] - p[0]) + (a[1] - p[1]) * (a[1] - p[1]) +
                                         (a[2] - p[2]) * (a[2] - p[2]);
                        if (d2 >= best[3].first) continue;
                        best[3] = {d2, k};
                        std::sort(best, best + 4);
                    }
                }
        const float reach = (float)(r - 1) * grid.cell;
        if (best[3].second >= 0 && best[3].first <= reach * reach) break;
    }
    // A stray splat far from the subject: every anchor.
    if (best[3].second < 0)
        for (int32_t k = 0; 3 * (size_t)k + 2 < at.size(); k++) {
            const float* a = at.data() + 3 * k;
            const float d2 = (a[0] - p[0]) * (a[0] - p[0]) + (a[1] - p[1]) * (a[1] - p[1]) +
                             (a[2] - p[2]) * (a[2] - p[2]);
            if (d2 >= best[3].first) continue;
            bool known = false;
            for (const auto& b : best) known |= b.second == k;
            if (known) continue;
            best[3] = {d2, k};
            std::sort(best, best + 4);
        }
    // Gaussian weights, then the nearest weights that sum to one and rebuild p:
    // minimise |w - w0|^2 + mu |sum w_j (a_j - p) / s|^2 + nu (sum w_j - 1)^2.
    const float s = grid.cell;
    double w0[4] = {0, 0, 0, 0}, total = 0.0;
    int found = 0;
    for (int j = 0; j < 4; j++) {
        if (best[j].second < 0) continue;
        found++;
        w0[j] = std::exp(-best[j].first / (s * s));
        total += w0[j];
    }
    if (found == 0) throw std::runtime_error("anchors: a chunk without anchors");
    if (best[0].first > 9.0f * s * s) {
        rig.index[row] = {best[0].second, best[0].second, best[0].second, best[0].second};
        rig.weight[row] = {0.0f, 0.0f, 0.0f, 0.0f};
        return;
    }
    for (double& w : w0) w = total > 0.0 ? w / total : 0.0;
    const double mu = 4.0, nu = 100.0;
    double e[4][3] = {};
    for (int j = 0; j < 4; j++)
        if (best[j].second >= 0)
            for (int c = 0; c < 3; c++) e[j][c] = (at[3 * best[j].second + c] - p[c]) / s;
    double m[4][4], b[4];
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            const bool both = best[i].second >= 0 && best[j].second >= 0;
            m[i][j] = (i == j ? 1.0 : 0.0) +
                      (both ? mu * (e[i][0] * e[j][0] + e[i][1] * e[j][1] + e[i][2] * e[j][2]) + nu : 0.0);
        }
        b[i] = w0[i] + (best[i].second >= 0 ? nu : 0.0);
    }
    solve4(m, b);
    for (int j = 0; j < 4; j++) {
        rig.index[row][j] = best[j].second >= 0 ? best[j].second : best[0].second;
        rig.weight[row][j] = best[j].second >= 0 ? (float)std::clamp(b[j], -1.0, 2.0) : 0.0f;
    }
}

void anchor_solve(const AnchorRig& rig, const std::vector<uint32_t>& rows,
                  const std::vector<float>& offsets, const std::vector<float>& importance,
                  std::vector<float>& displacement) {
    const size_t K = rig.rest.size() / 3, m = rows.size();
    if (m == 0) return;
    // Each anchor's rows (entry, weight), so both products run without races.
    std::vector<uint32_t> start(K + 1, 0);
    for (uint32_t r : rows)
        for (int j = 0; j < 4; j++) start[(size_t)rig.index[r][j] + 1]++;
    for (size_t k = 0; k < K; k++) start[k + 1] += start[k];
    std::vector<uint32_t> fill(start.begin(), start.end() - 1), entry(start[K]);
    std::vector<float> coef(start[K]);
    for (size_t q = 0; q < m; q++)
        for (int j = 0; j < 4; j++) {
            const size_t k = (size_t)rig.index[rows[q]][j];
            entry[fill[k]] = (uint32_t)q;
            coef[fill[k]++] = rig.weight[rows[q]][j];
        }
    std::vector<double> diag(K, 0.0);
    double diag_sum = 0.0;
    size_t seen = 0;
    for (size_t k = 0; k < K; k++) {
        for (uint32_t e = start[k]; e < start[k + 1]; e++)
            diag[k] += (double)importance[entry[e]] * coef[e] * coef[e];
        if (diag[k] > 0.0) {
            diag_sum += diag[k];
            seen++;
        }
    }
    if (seen == 0) return;
    // A small pull to the prior: it settles anchors few rows see, and no row's
    // anchors are underdetermined.
    const double lambda = 1e-3 * diag_sum / (double)seen;

    // (W' U W + lambda) x = W' U o + lambda x0, conjugate gradients, xyz at once.
    std::vector<double> z(3 * m);
    auto apply = [&](const std::vector<double>& x, std::vector<double>& y) {
        nn::parallel_for((int64_t)m, [&](int64_t lo, int64_t hi) {
            for (int64_t q = lo; q < hi; q++) {
                const uint32_t r = rows[(size_t)q];
                for (int c = 0; c < 3; c++) {
                    double v = 0.0;
                    for (int j = 0; j < 4; j++) v += rig.weight[r][j] * x[3 * (size_t)rig.index[r][j] + c];
                    z[3 * q + c] = importance[(size_t)q] * v;
                }
            }
        }, 4096);
        nn::parallel_for((int64_t)K, [&](int64_t lo, int64_t hi) {
            for (int64_t k = lo; k < hi; k++)
                for (int c = 0; c < 3; c++) {
                    double v = lambda * x[3 * k + c];
                    for (uint32_t e = start[k]; e < start[k + 1]; e++) v += coef[e] * z[3 * entry[e] + c];
                    y[3 * k + c] = v;
                }
        }, 256);
    };
    std::vector<double> x(displacement.begin(), displacement.end()), b(3 * K), r(3 * K), d(3 * K), ad(3 * K);
    for (size_t q = 0; q < m; q++)
        for (int c = 0; c < 3; c++) z[3 * q + c] = importance[q] * offsets[3 * q + c];
    for (size_t k = 0; k < K; k++)
        for (int c = 0; c < 3; c++) {
            double v = lambda * x[3 * k + c];
            for (uint32_t e = start[k]; e < start[k + 1]; e++) v += coef[e] * z[3 * entry[e] + c];
            b[3 * k + c] = v;
        }
    // Jacobi-preconditioned, from the prior. Done when no anchor moves 0.1 mm
    // (positions in metres) in an iteration: far below what a person's splat shows.
    const double settled = 1e-4;
    std::vector<double> s(3 * K);
    apply(x, ad);
    double rs = 0.0;
    for (size_t i = 0; i < 3 * K; i++) {
        r[i] = b[i] - ad[i];
        d[i] = s[i] = r[i] / (diag[i / 3] + lambda);
        rs += r[i] * s[i];
    }
    for (int it = 0; it < 60 && rs > 0.0; it++) {
        apply(d, ad);
        double dad = 0.0;
        for (size_t i = 0; i < 3 * K; i++) dad += d[i] * ad[i];
        const double alpha = rs / dad;
        double next = 0.0, moved = 0.0;
        for (size_t i = 0; i < 3 * K; i++) {
            x[i] += alpha * d[i];
            moved = std::max(moved, std::abs(alpha * d[i]));
            r[i] -= alpha * ad[i];
            s[i] = r[i] / (diag[i / 3] + lambda);
            next += r[i] * s[i];
        }
        if (moved < settled) break;
        for (size_t i = 0; i < 3 * K; i++) d[i] = s[i] + next / rs * d[i];
        rs = next;
    }
    for (size_t i = 0; i < 3 * K; i++) displacement[i] = (float)x[i];
}

std::array<float, 3> anchor_offset(const AnchorRig& rig, size_t row,
                                   const std::vector<float>& displacement) {
    std::array<float, 3> o = {0.0f, 0.0f, 0.0f};
    for (int j = 0; j < 4; j++)
        for (int c = 0; c < 3; c++)
            o[c] += rig.weight[row][j] * displacement[3 * (size_t)rig.index[row][j] + c];
    return o;
}

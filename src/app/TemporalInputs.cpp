#include "app/TemporalInputs.h"
#include "data/DatasetParser.h"
#include "external/stb_image.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <limits>
#include <map>
#include <stdexcept>
#include <unordered_map>

namespace fs = std::filesystem;

namespace {

// Subject: inside the mask in >= 80 % of the >= 6 views that see a point,
// masks read at a quarter of the camera's resolution.
constexpr float kHullRatio = 0.8f;
constexpr int kHullMinViews = 6, kMaskScale = 4;
// Warp: ~5000 nodes, 8 neighbours each, 10 rotation/translation rounds of 60
// Jacobi sweeps, as-rigid-as-possible weight 1.5, correspondences within 5 cm.
constexpr int kNodes = 5000, kNodeNeighbours = 8, kOuter = 10, kSweeps = 60;
constexpr double kArap = 1.5, kMaxCorrespondence = 0.05;
constexpr double kInf = std::numeric_limits<double>::infinity();

using Vec3 = std::array<double, 3>;
using Mat3 = std::array<double, 9>;  // row-major

Vec3 add(const Vec3& a, const Vec3& b) { return {a[0] + b[0], a[1] + b[1], a[2] + b[2]}; }
Vec3 sub(const Vec3& a, const Vec3& b) { return {a[0] - b[0], a[1] - b[1], a[2] - b[2]}; }
double norm(const Vec3& a) { return std::sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]); }
Vec3 mul(const Mat3& m, const Vec3& v) {
    return {m[0] * v[0] + m[1] * v[1] + m[2] * v[2], m[3] * v[0] + m[4] * v[1] + m[5] * v[2],
            m[6] * v[0] + m[7] * v[1] + m[8] * v[2]};
}
Vec3 cross(const Vec3& a, const Vec3& b) {
    return {a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]};
}

// Points bucketed in cubic cells: the k nearest within the (2 rings + 1)^3
// cells around a query, padded with (inf, -1).
class Grid {
public:
    Grid(const std::vector<Vec3>& pts, double cell) : _p(pts), _cell(cell) {
        for (int32_t i = 0; i < (int32_t)pts.size(); i++) _cells[key(cell_of(pts[i]), 0, 0, 0)].push_back(i);
    }
    void knn(const Vec3& q, int k, int rings, double* dist, int32_t* idx) const {
        std::fill(dist, dist + k, kInf);
        std::fill(idx, idx + k, -1);
        const std::array<int64_t, 3> c = cell_of(q);
        for (int dx = -rings; dx <= rings; dx++)
            for (int dy = -rings; dy <= rings; dy++)
                for (int dz = -rings; dz <= rings; dz++) {
                    auto it = _cells.find(key(c, dx, dy, dz));
                    if (it == _cells.end()) continue;
                    for (int32_t i : it->second) {
                        const double d = norm(sub(q, _p[(size_t)i]));
                        if (!(d < dist[k - 1])) continue;
                        int j = k - 1;
                        for (; j > 0 && d < dist[j - 1]; j--) { dist[j] = dist[j - 1]; idx[j] = idx[j - 1]; }
                        dist[j] = d;
                        idx[j] = i;
                    }
                }
    }

private:
    std::array<int64_t, 3> cell_of(const Vec3& p) const {
        return {(int64_t)std::floor(p[0] / _cell), (int64_t)std::floor(p[1] / _cell),
                (int64_t)std::floor(p[2] / _cell)};
    }
    static uint64_t key(const std::array<int64_t, 3>& c, int dx, int dy, int dz) {
        const uint64_t o = 1ull << 20;
        return ((uint64_t)(c[0] + dx + o) << 42) | ((uint64_t)(c[1] + dy + o) << 21) | (uint64_t)(c[2] + dz + o);
    }
    const std::vector<Vec3>& _p;
    double _cell;
    std::unordered_map<uint64_t, std::vector<int32_t>> _cells;
};

std::vector<Vec3> as_points(const std::vector<float>& xyz) {
    std::vector<Vec3> out(xyz.size() / 3);
    for (size_t i = 0; i < out.size(); i++) out[i] = {xyz[3 * i], xyz[3 * i + 1], xyz[3 * i + 2]};
    return out;
}

// Symmetric 3x3 eigen-decomposition by cyclic Jacobi: values descending, and
// the matching eigenvectors as the columns of v.
void symmetric_eigen(Mat3 a, double values[3], Mat3& v) {
    v = {1, 0, 0, 0, 1, 0, 0, 0, 1};
    for (int sweep = 0; sweep < 32; sweep++) {
        const double off = a[1] * a[1] + a[2] * a[2] + a[5] * a[5];
        if (off < 1e-30) break;
        for (int p = 0; p < 2; p++)
            for (int q = p + 1; q < 3; q++) {
                const double apq = a[3 * p + q];
                if (std::abs(apq) < 1e-300) continue;
                const double theta = (a[3 * q + q] - a[3 * p + p]) / (2 * apq);
                const double t = (theta >= 0 ? 1 : -1) / (std::abs(theta) + std::sqrt(theta * theta + 1));
                const double c = 1 / std::sqrt(t * t + 1), s = t * c;
                for (int k = 0; k < 3; k++) {  // a = J^T a J
                    const double akp = a[3 * k + p], akq = a[3 * k + q];
                    a[3 * k + p] = c * akp - s * akq;
                    a[3 * k + q] = s * akp + c * akq;
                }
                for (int k = 0; k < 3; k++) {
                    const double apk = a[3 * p + k], aqk = a[3 * q + k];
                    a[3 * p + k] = c * apk - s * aqk;
                    a[3 * q + k] = s * apk + c * aqk;
                }
                for (int k = 0; k < 3; k++) {
                    const double vkp = v[3 * k + p], vkq = v[3 * k + q];
                    v[3 * k + p] = c * vkp - s * vkq;
                    v[3 * k + q] = s * vkp + c * vkq;
                }
            }
    }
    int order[3] = {0, 1, 2};
    std::sort(order, order + 3, [&](int x, int y) { return a[4 * x] > a[4 * y]; });
    Mat3 sorted;
    for (int j = 0; j < 3; j++) {
        values[j] = a[4 * order[j]];
        for (int k = 0; k < 3; k++) sorted[3 * k + j] = v[3 * k + order[j]];
    }
    v = sorted;
}

// The rotation closest to s (Kabsch): u diag(1, 1, det) v^T from s = u S v^T.
Mat3 nearest_rotation(const Mat3& s) {
    Mat3 sts{};
    for (int i = 0; i < 3; i++)
        for (int j = 0; j < 3; j++)
            for (int k = 0; k < 3; k++) sts[3 * i + j] += s[3 * k + i] * s[3 * k + j];
    double sigma2[3];
    Mat3 v;
    symmetric_eigen(sts, sigma2, v);
    Vec3 vc[3], u[3];
    for (int j = 0; j < 3; j++) vc[j] = {v[j], v[3 + j], v[6 + j]};
    for (int j = 0; j < 2; j++) {
        u[j] = mul(s, vc[j]);
        if (j == 1) {  // Gram-Schmidt keeps a rank-one s well defined
            const double d = u[1][0] * u[0][0] + u[1][1] * u[0][1] + u[1][2] * u[0][2];
            u[1] = sub(u[1], {d * u[0][0], d * u[0][1], d * u[0][2]});
            if (norm(u[1]) < 1e-12) {
                const Vec3 axis = std::abs(u[0][0]) < 0.9 ? Vec3{1, 0, 0} : Vec3{0, 1, 0};
                u[1] = cross(u[0], axis);
            }
        }
        const double n = norm(u[j]);
        if (n < 1e-12) return {1, 0, 0, 0, 1, 0, 0, 0, 1};
        u[j] = {u[j][0] / n, u[j][1] / n, u[j][2] / n};
    }
    u[2] = cross(u[0], u[1]);
    const double det_v = vc[0][0] * (vc[1][1] * vc[2][2] - vc[1][2] * vc[2][1]) -
                         vc[1][0] * (vc[0][1] * vc[2][2] - vc[0][2] * vc[2][1]) +
                         vc[2][0] * (vc[0][1] * vc[1][2] - vc[0][2] * vc[1][1]);
    const double flip = det_v < 0 ? -1 : 1;
    Mat3 r{};
    for (int i = 0; i < 3; i++)
        for (int j = 0; j < 3; j++)
            r[3 * i + j] = u[0][i] * vc[0][j] + u[1][i] * vc[1][j] + flip * u[2][i] * vc[2][j];
    return r;
}

// One node per occupied cell (its lowest index), the cell sized for ~wanted.
std::vector<int32_t> sample_nodes(const std::vector<Vec3>& pts, int wanted) {
    Vec3 lo{kInf, kInf, kInf}, hi{-kInf, -kInf, -kInf};
    for (const Vec3& p : pts)
        for (int k = 0; k < 3; k++) { lo[k] = std::min(lo[k], p[k]); hi[k] = std::max(hi[k], p[k]); }
    double cell = norm(sub(hi, lo)) / std::cbrt((double)wanted) * 0.6;
    std::vector<int32_t> first;
    for (int round = 0; round < 12; round++) {
        std::map<std::array<int64_t, 3>, int32_t> cells;
        for (int32_t i = 0; i < (int32_t)pts.size(); i++) {
            std::array<int64_t, 3> c;
            for (int k = 0; k < 3; k++) c[k] = (int64_t)std::floor((pts[(size_t)i][k] - lo[k]) / cell);
            cells.emplace(c, i);
        }
        first.clear();
        for (const auto& [c, i] : cells) first.push_back(i);
        const double ratio = (double)first.size() / wanted;
        if (ratio > 0.75 && ratio < 1.4) break;
        cell *= std::cbrt(ratio);
    }
    std::sort(first.begin(), first.end());
    return first;
}

}  // namespace

SubjectPoints subject_points(const std::string& frame_dir) {
    fs::path sparse = fs::path(frame_dir) / "sparse";
    if (fs::exists(sparse / "0" / "points3D.bin")) sparse /= "0";
    const ColmapPoints3D cloud = read_points3D_binary(sparse.string());
    const std::map<int32_t, ColmapCamera> cameras = read_cameras_binary(sparse.string());
    const std::map<int32_t, ColmapImage> images = read_images_binary(sparse.string());
    const int64_t n = cloud.num();
    std::vector<int32_t> seen((size_t)n, 0), inside((size_t)n, 0);
    for (const auto& [id, image] : images) {
        const ColmapCamera& cam = cameras.at(image.camera_id);
        const bool one_focal = cam.model.rfind("SIMPLE_", 0) == 0 || cam.model.rfind("RADIAL", 0) == 0;
        const double fx = cam.params[0] / kMaskScale;
        const double fy = (one_focal ? cam.params[0] : cam.params[1]) / kMaskScale;
        const double cx = cam.params[one_focal ? 1 : 2] / kMaskScale;
        const double cy = cam.params[one_focal ? 2 : 3] / kMaskScale;
        const int mw = (int)cam.width / kMaskScale, mh = (int)cam.height / kMaskScale;

        const fs::path mask_path =
            fs::path(frame_dir) / "masks" / (fs::path(image.name).stem().string() + ".png");
        int w = 0, h = 0, channels = 0;
        uint8_t* pixels = stbi_load(mask_path.string().c_str(), &w, &h, &channels, 1);
        if (!pixels) throw std::runtime_error("subject points: cannot read " + mask_path.string());
        std::vector<uint32_t> sum((size_t)mw * mh, 0), count((size_t)mw * mh, 0);
        for (int y = 0; y < h; y++) {
            const int my = (int)((int64_t)y * mh / h);
            for (int x = 0; x < w; x++) {
                const size_t c = (size_t)my * mw + (size_t)((int64_t)x * mw / w);
                sum[c] += pixels[(size_t)y * w + x];
                count[c]++;
            }
        }
        stbi_image_free(pixels);

        const double qw = image.qvec[0], qx = image.qvec[1], qy = image.qvec[2], qz = image.qvec[3];
        const Mat3 r = {1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy - qz * qw), 2 * (qx * qz + qy * qw),
                        2 * (qx * qy + qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz - qx * qw),
                        2 * (qx * qz - qy * qw), 2 * (qy * qz + qx * qw), 1 - 2 * (qx * qx + qy * qy)};
        const Vec3 t = {image.tvec[0], image.tvec[1], image.tvec[2]};
        for (int64_t i = 0; i < n; i++) {
            const Vec3 pc = add(mul(r, {cloud.xyz[3 * i], cloud.xyz[3 * i + 1], cloud.xyz[3 * i + 2]}), t);
            if (!(pc[2] > 1e-3)) continue;
            const int64_t u = (int64_t)std::floor(fx * pc[0] / pc[2] + cx);
            const int64_t v = (int64_t)std::floor(fy * pc[1] / pc[2] + cy);
            if (u < 0 || u >= mw || v < 0 || v >= mh) continue;
            const size_t c = (size_t)v * mw + (size_t)u;
            seen[(size_t)i]++;
            if (count[c] && sum[c] > 127u * count[c]) inside[(size_t)i]++;
        }
    }
    SubjectPoints out;
    for (int64_t i = 0; i < n; i++) {
        if (seen[(size_t)i] < kHullMinViews ||
            inside[(size_t)i] < kHullRatio * std::max(seen[(size_t)i], 1))
            continue;
        for (int k = 0; k < 3; k++) {
            out.xyz.push_back(cloud.xyz[3 * i + k]);
            out.rgb.push_back(cloud.rgb[3 * i + k] / 255.0f);
        }
    }
    return out;
}

std::vector<float> subject_warp(const SubjectPoints& source, const SubjectPoints& target,
                                float& bind_radius, std::string& log) {
    if (source.size() < 16 || target.size() < 16)
        throw std::runtime_error("subject warp: too few subject points");
    const std::vector<Vec3> src = as_points(source.xyz), tgt = as_points(target.xyz);
    std::vector<Vec3> g;
    for (int32_t i : sample_nodes(src, kNodes)) g.push_back(src[(size_t)i]);
    const int N = (int)g.size(), K = kNodeNeighbours;

    // Node spacing from a subsample, then each node's neighbours within twice
    // the skinning radius (itself when none).
    double spacing = 0;
    {
        const Grid coarse(g, 0.05);
        int used = 0;
        double d[2];
        int32_t j[2];
        for (int i = 0; i < N; i += std::max(1, N / 512)) {
            coarse.knn(g[(size_t)i], 2, 10, d, j);
            if (std::isfinite(d[1])) { spacing += d[1]; used++; }
        }
        if (!used) throw std::runtime_error("subject warp: isolated nodes");
        spacing /= used;
    }
    const double bind = spacing * 3.0;
    std::vector<int32_t> nb((size_t)N * K);
    std::vector<uint8_t> valid((size_t)N * K);
    std::vector<int> deg((size_t)N, 0);
    {
        const Grid nodes(g, spacing);
        const int rings = (int)std::ceil(bind * 2 / spacing);
        std::vector<double> d(K + 1);
        std::vector<int32_t> j(K + 1);
        for (int i = 0; i < N; i++) {
            nodes.knn(g[(size_t)i], K + 1, rings, d.data(), j.data());
            for (int k = 0; k < K; k++) {
                const bool ok = j[k + 1] >= 0 && std::isfinite(d[k + 1]) && d[k + 1] < bind * 2;
                valid[(size_t)i * K + k] = ok;
                nb[(size_t)i * K + k] = ok ? j[k + 1] : i;
                deg[(size_t)i] += ok;
            }
        }
    }
    const Grid targets(tgt, spacing);
    const int rings = (int)std::ceil(kMaxCorrespondence / spacing);
    std::vector<Mat3> R((size_t)N, Mat3{1, 0, 0, 0, 1, 0, 0, 0, 1});
    std::vector<Vec3> t((size_t)N, Vec3{0, 0, 0}), next((size_t)N);
    std::vector<Vec3> corr((size_t)N);
    std::vector<uint8_t> has((size_t)N);
    auto rms = [&] {
        double s = 0, d;
        int32_t j, used = 0;
        for (int i = 0; i < N; i++) {
            targets.knn(add(g[(size_t)i], t[(size_t)i]), 1, rings, &d, &j);
            if (j >= 0) { s += d * d; used++; }
        }
        return used ? std::sqrt(s / used) * 1000 : 0.0;
    };
    const double before = rms();
    for (int outer = 0; outer < kOuter; outer++) {
        for (int i = 0; i < N; i++) {
            double d;
            int32_t j;
            targets.knn(add(g[(size_t)i], t[(size_t)i]), 1, rings, &d, &j);
            has[(size_t)i] = j >= 0 && d < kMaxCorrespondence;
            corr[(size_t)i] = has[(size_t)i] ? tgt[(size_t)j] : g[(size_t)i];
        }
        for (int i = 0; i < N; i++) {
            if (!deg[(size_t)i]) continue;
            Mat3 s{};
            const Vec3 gi = add(g[(size_t)i], t[(size_t)i]);
            for (int k = 0; k < K; k++) {
                if (!valid[(size_t)i * K + k]) continue;
                const int32_t m = nb[(size_t)i * K + k];
                const Vec3 e1 = sub(add(g[(size_t)m], t[(size_t)m]), gi);
                const Vec3 e0 = sub(g[(size_t)m], g[(size_t)i]);
                for (int a = 0; a < 3; a++)
                    for (int b = 0; b < 3; b++) s[3 * a + b] += e1[a] * e0[b];
            }
            R[(size_t)i] = nearest_rotation(s);
        }
        for (int sweep = 0; sweep < kSweeps; sweep++) {  // Jacobi on the translation step
            for (int i = 0; i < N; i++) {
                const double w = deg[(size_t)i] ? kArap / deg[(size_t)i] : 0.0;
                Vec3 rhs = has[(size_t)i] ? sub(corr[(size_t)i], g[(size_t)i]) : Vec3{0, 0, 0};
                double diag = has[(size_t)i] ? 1.0 : 0.0;
                for (int k = 0; k < K; k++) {
                    if (!valid[(size_t)i * K + k]) continue;
                    const int32_t m = nb[(size_t)i * K + k];
                    const Vec3 e0 = sub(g[(size_t)m], g[(size_t)i]);
                    const Vec3 base = sub(add(g[(size_t)m], t[(size_t)m]), g[(size_t)i]);
                    const Vec3 a = sub(base, mul(R[(size_t)i], e0));
                    const Vec3 b = sub(base, mul(R[(size_t)m], e0));
                    for (int c = 0; c < 3; c++) rhs[c] += w * (a[c] + b[c]);
                }
                diag += 2 * w * deg[(size_t)i];
                next[(size_t)i] = diag > 0 ? Vec3{rhs[0] / diag, rhs[1] / diag, rhs[2] / diag}
                                           : t[(size_t)i];
            }
            t.swap(next);
        }
    }
    const double after = rms();

    std::vector<float> rows((size_t)N * 10);
    double moved = 0;
    for (int i = 0; i < N; i++) {
        const Mat3& r = R[(size_t)i];
        const double qw = std::max(std::sqrt(std::max(0.0, 1 + r[0] + r[4] + r[8])) / 2, 1e-8);
        const double q[4] = {qw, (r[7] - r[5]) / (4 * qw), (r[2] - r[6]) / (4 * qw), (r[3] - r[1]) / (4 * qw)};
        float* row = &rows[(size_t)i * 10];
        for (int k = 0; k < 3; k++) { row[k] = (float)g[(size_t)i][k]; row[3 + k] = (float)t[(size_t)i][k]; }
        for (int k = 0; k < 4; k++) row[6 + k] = (float)q[k];
        moved += norm(t[(size_t)i]);
    }
    bind_radius = (float)bind;
    char line[160];
    std::snprintf(line, sizeof line, "%d nodes, bind %.1f mm, RMS %.1f -> %.1f mm, mean |t| %.1f mm", N,
                  bind * 1000, before, after, moved / N * 1000);
    log = line;
    return rows;
}

std::vector<float> subject_births(const SubjectPoints& points) {
    // One candidate per 15 mm cell: a depth-densified cloud (MoGe) is ten
    // times denser than the SfM one the births were tuned on (median spacing
    // 17 mm), and would fill the birth budget with tiny splats every frame.
    constexpr double kCell = 0.015;
    std::vector<size_t> keep;
    {
        std::unordered_map<uint64_t, size_t> cells;
        for (size_t i = 0; i < points.size(); i++) {
            uint64_t key = 0;
            for (int k = 0; k < 3; k++)
                key = key * 2097152u + (uint64_t)((int64_t)std::floor(points.xyz[3 * i + k] / kCell) + 1048576);
            if (cells.emplace(key, i).second) keep.push_back(i);
        }
    }
    std::vector<Vec3> p(keep.size());
    for (size_t j = 0; j < keep.size(); j++)
        p[j] = {points.xyz[3 * keep[j]], points.xyz[3 * keep[j] + 1], points.xyz[3 * keep[j] + 2]};
    const Grid grid(p, 0.02);
    std::vector<float> rows(p.size() * 7);
    double d[5];
    int32_t j[5];
    for (size_t i = 0; i < p.size(); i++) {
        grid.knn(p[i], 5, 2, d, j);
        float* row = &rows[i * 7];
        const size_t src = keep[i];
        for (int k = 0; k < 3; k++) { row[k] = points.xyz[3 * src + k]; row[3 + k] = points.rgb[3 * src + k]; }
        row[6] = std::isfinite(d[4]) ? (float)d[4] : 0.02f;
    }
    return rows;
}

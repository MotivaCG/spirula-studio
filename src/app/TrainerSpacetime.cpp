// Spacetime chunk training (--spacetime-init): the chunk trained whole, every
// subject row one .vgs record with a trajectory and a life (engine/EngineSpacetime.h).
// The records start from a finished frame-by-frame chunk run, fitted to its frames,
// or from a keyframe seed: per-keyframe clouds with their motion, short-lived.

#include "app/TrainerCore.h"
#include "engine/EngineSpacetime.h"
#include "engine/EngineSpacetimeMotion.h"
#include "nn/core/Parallel.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <map>
#include <sstream>
#include <stdexcept>

namespace fs = std::filesystem;

namespace spirula {

ColorResolution resolve_color(const TrainConfig& c);

namespace {

const float kShownLogit = std::log(1.0f / 254.0f);
constexpr int kMotionFloats = 8;  // motion.bin per row: mu, sigma (frames), velocity, acceleration (per frame)

// Least squares of K control points through samples (frame, value[width]), with
// a small second-difference penalty so records seen in few frames stay smooth.
void fit_spline(int K, int frames, const std::vector<int>& at, const std::vector<float>& values,
                int width, float* out) {
    std::vector<double> A((size_t)K * K, 0.0), b((size_t)K * width, 0.0);
    std::vector<float> w((size_t)K);
    for (size_t s = 0; s < at.size(); s++) {
        spacetime_basis(K, frames, (float)at[s], w.data());
        for (int i = 0; i < K; i++) {
            for (int j = 0; j < K; j++) A[(size_t)i * K + j] += (double)w[i] * w[j];
            for (int c = 0; c < width; c++) b[(size_t)i * width + c] += (double)w[i] * values[s * width + c];
        }
    }
    const double lambda = 1e-3;
    for (int i = 0; i + 2 < K; i++) {
        const int idx[3] = {i, i + 1, i + 2};
        const double d[3] = {1.0, -2.0, 1.0};
        for (int p = 0; p < 3; p++)
            for (int q = 0; q < 3; q++) A[(size_t)idx[p] * K + idx[q]] += lambda * d[p] * d[q];
    }
    for (int i = 0; i < K; i++) A[(size_t)i * K + i] += 1e-9;
    // Gauss-Jordan with partial pivoting on [A | b].
    for (int c = 0; c < K; c++) {
        int best = c;
        for (int r = c + 1; r < K; r++)
            if (std::abs(A[(size_t)r * K + c]) > std::abs(A[(size_t)best * K + c])) best = r;
        for (int j = 0; j < K; j++) std::swap(A[(size_t)c * K + j], A[(size_t)best * K + j]);
        for (int j = 0; j < width; j++) std::swap(b[(size_t)c * width + j], b[(size_t)best * width + j]);
        for (int r = 0; r < K; r++) {
            if (r == c) continue;
            const double f = A[(size_t)r * K + c] / A[(size_t)c * K + c];
            for (int j = c; j < K; j++) A[(size_t)r * K + j] -= f * A[(size_t)c * K + j];
            for (int j = 0; j < width; j++) b[(size_t)r * width + j] -= f * b[(size_t)c * width + j];
        }
    }
    for (int i = 0; i < K; i++)
        for (int c = 0; c < width; c++)
            out[i * width + c] = (float)(b[(size_t)i * width + c] / A[(size_t)i * K + i]);
}

struct Record {
    int64_t row;
    int first, last;  // the segment of the row's frames this record owns
};

void allocate(SpacetimeRecords& st, SeedSplats& seed, size_t n, size_t cap, size_t sh) {
    st.rows = (int64_t)n;
    st.pos.assign(n * kSpacetimePos * 3, 0.0f);
    st.rot.assign(n * kSpacetimeRot * 4, 0.0f);
    st.color.assign(n * kSpacetimeColor * 3, 0.0f);
    st.opacity.assign(n, 0.0f);
    st.mu.assign(n, 0.0f);
    st.log_sigma.assign(n, 0.0f);
    seed.num = (int64_t)n;
    seed.means.assign(3 * cap, 0.0f);
    seed.quats.assign(4 * cap, 0.0f);
    seed.scales.assign(3 * cap, -10.0f);
    seed.opacities.assign(cap, -20.0f);
    seed.features_dc.assign(3 * cap, 0.0f);
    seed.features_sh.assign(sh * cap, 0.0f);
}

void copy_row(const SeedSplats& from, size_t r, SeedSplats& to, size_t i, size_t sh) {
    std::copy_n(&from.means[3 * r], 3, &to.means[3 * i]);
    std::copy_n(&from.quats[4 * r], 4, &to.quats[4 * i]);
    std::copy_n(&from.scales[3 * r], 3, &to.scales[3 * i]);
    to.opacities[i] = from.opacities[r];
    std::copy_n(&from.features_dc[3 * r], 3, &to.features_dc[3 * i]);
    std::copy_n(&from.features_sh[sh * r], sh, &to.features_sh[sh * i]);
}

}  // namespace

bool TrainerSession::spacetime() const {
    return !cfg.spacetime_init.empty() && cfg.spacetime_init != "none";
}

SeedSplats TrainerSession::spacetime_seed(const ColorResolution& color, size_t cap) {
    const fs::path dir(cfg.spacetime_init);
    if (fs::exists(dir / "motion.bin")) return keyframe_seed(color, cap);
    return chunk_run_seed(color, cap);
}

// A keyframe seed (SPACETIME_KEYFRAMES.md): seed.ply holds every record's
// splat, motion.bin its life and motion at its keyframe. The trajectory is the
// motion over the life (+-2 sigma) and constant velocity past it, fitted.
SeedSplats TrainerSession::keyframe_seed(const ColorResolution& color, size_t cap) {
    const int F = (int)_chunk_dirs.size();
    const fs::path dir(cfg.spacetime_init);
    const SeedSplats kf = seed_splats_from_ply((dir / "seed.ply").string(), cfg, color);
    const size_t n = (size_t)kf.num, sh = kf.features_sh.size() / kf.opacities.size();
    std::vector<float> motion(n * kMotionFloats);
    std::ifstream in(dir / "motion.bin", std::ios::binary | std::ios::ate);
    if (!in || (size_t)in.tellg() != motion.size() * 4)
        throw std::runtime_error("--spacetime-init: motion.bin does not hold 8 floats per seed.ply row (cap_max?)");
    in.seekg(0);
    in.read(reinterpret_cast<char*>(motion.data()), (std::streamsize)(motion.size() * 4));
    if (n + (size_t)_room_rows > cap)
        throw std::runtime_error("--spacetime-init: the seed and the room exceed cap_max");

    SpacetimeRecords& st = _spacetime;
    SeedSplats seed;
    allocate(st, seed, n, cap, sh);
    std::vector<int> frames((size_t)F);
    for (int f = 0; f < F; f++) frames[(size_t)f] = f;
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        std::vector<float> x((size_t)F * 3);
        for (int64_t i = lo; i < hi; i++) {
            const float* m = motion.data() + (size_t)i * kMotionFloats;
            const float mu = m[0], sigma = std::max(m[1], 0.15f), *v = m + 2, *a = m + 5;
            const float* x0 = &kf.means[3 * (size_t)i];
            for (int f = 0; f < F; f++) {
                const float dt = (float)f - mu, e = std::clamp(dt, -2.0f * sigma, 2.0f * sigma);
                for (int c = 0; c < 3; c++)
                    x[(size_t)f * 3 + c] = x0[c] + v[c] * e + 0.5f * a[c] * e * e + (v[c] + a[c] * e) * (dt - e);
            }
            fit_spline(kSpacetimePos, F, frames, x, 3, st.pos.data() + (size_t)i * kSpacetimePos * 3);
            for (int k = 0; k < kSpacetimeRot; k++)
                std::copy_n(&kf.quats[4 * (size_t)i], 4, st.rot.data() + ((size_t)i * kSpacetimeRot + k) * 4);
            for (int k = 0; k < kSpacetimeColor; k++)
                std::copy_n(&kf.features_dc[3 * (size_t)i], 3, st.color.data() + ((size_t)i * kSpacetimeColor + k) * 3);
            st.opacity[(size_t)i] = kf.opacities[(size_t)i];
            st.mu[(size_t)i] = std::clamp(mu, 0.0f, (float)(F - 1));
            st.log_sigma[(size_t)i] = std::log(std::min(sigma, (float)F));
            copy_row(kf, (size_t)i, seed, (size_t)i, sh);
        }
    });
    log("spacetime: " + std::to_string(n) + " records from the keyframe seed " + cfg.spacetime_init);
    return seed;
}

// The chunk run's frames cut into records: a row's records follow one another,
// each starting at its birth event, and lives from its first shown frame to its
// last. Scale and SH come from the first; the trajectories are fitted.
SeedSplats TrainerSession::chunk_run_seed(const ColorResolution& color, size_t cap) {
    const int F = (int)_chunk_dirs.size();
    const fs::path run(cfg.spacetime_init);
    std::vector<SeedSplats> frames;
    for (int f = 0; f < F; f++) {
        char name[32];
        std::snprintf(name, sizeof name, "%03d", f);
        frames.push_back(seed_splats_from_ply((run / "frames" / name / "splat.ply").string(), cfg, color));
        if (frames.back().num != frames[0].num)
            throw std::runtime_error(std::string("--spacetime-init: frame ") + name + " has another row count");
    }
    const int64_t R = frames[0].num;
    std::map<int64_t, std::vector<int>> starts;  // row -> frames where a record begins
    std::ifstream events(run / "frames" / "birth_events.tsv");
    for (std::string line; std::getline(events, line);) {
        std::istringstream in(line);
        int frame = 0;
        int64_t row = 0;
        uint32_t generation = 0;
        if (in >> frame >> row >> generation && frame > 0 && frame < F) starts[row].push_back(frame);
    }
    std::vector<Record> records;
    for (int64_t r = 0; r < R; r++) {
        std::vector<int> cut = {0};
        if (auto it = starts.find(r); it != starts.end()) cut.insert(cut.end(), it->second.begin(), it->second.end());
        std::sort(cut.begin(), cut.end());
        cut.erase(std::unique(cut.begin(), cut.end()), cut.end());
        cut.push_back(F);
        for (size_t s = 0; s + 1 < cut.size(); s++) {
            int first = -1, last = -1;
            for (int f = cut[s]; f < cut[s + 1]; f++)
                if (frames[f].opacities[(size_t)r] > kShownLogit) {
                    if (first < 0) first = f;
                    last = f;
                }
            if (first >= 0) records.push_back({r, first, last});
        }
    }
    // --spacetime-spare: records shown nowhere, copies of the first ones, for relocation.
    const size_t real = records.size();
    const size_t spare = (size_t)(cfg.spacetime_spare * (float)real);
    for (size_t j = 0; j < spare; j++) records.push_back(records[j % real]);
    if (records.size() + (size_t)_room_rows > cap)
        throw std::runtime_error("--spacetime-init: " + std::to_string(records.size()) +
                                 " records and the room exceed cap_max");

    const size_t n = records.size(), sh = frames[0].features_sh.size() / frames[0].opacities.size();
    SpacetimeRecords& st = _spacetime;
    SeedSplats seed;
    allocate(st, seed, n, cap, sh);
    nn::parallel_for((int64_t)n, [&](int64_t lo, int64_t hi) {
        std::vector<int> at;
        std::vector<float> x, q, c;
        for (int64_t i = lo; i < hi; i++) {
            const Record& rec = records[(size_t)i];
            const size_t r = (size_t)rec.row;
            at.clear(), x.clear(), q.clear(), c.clear();
            const float* q0 = frames[rec.first].quats.data() + 4 * r;
            float peak = -9.0f;
            for (int f = rec.first; f <= rec.last; f++) {
                const SeedSplats& s = frames[f];
                if (s.opacities[r] <= kShownLogit) continue;
                at.push_back(f);
                x.insert(x.end(), &s.means[3 * r], &s.means[3 * r] + 3);
                c.insert(c.end(), &s.features_dc[3 * r], &s.features_dc[3 * r] + 3);
                // A quaternion and its negation are one rotation: one sign for the fit.
                const float* qf = &s.quats[4 * r];
                const float dot = qf[0] * q0[0] + qf[1] * q0[1] + qf[2] * q0[2] + qf[3] * q0[3];
                for (int k = 0; k < 4; k++) q.push_back(dot < 0.0f ? -qf[k] : qf[k]);
                peak = std::max(peak, std::min(s.opacities[r], 9.0f));
            }
            fit_spline(kSpacetimePos, F, at, x, 3, st.pos.data() + (size_t)i * kSpacetimePos * 3);
            fit_spline(kSpacetimeRot, F, at, q, 4, st.rot.data() + (size_t)i * kSpacetimeRot * 4);
            fit_spline(kSpacetimeColor, F, at, c, 3, st.color.data() + (size_t)i * kSpacetimeColor * 3);
            // The peak alpha over a Gaussian life as wide as the segment: 0.88 of it at the ends.
            st.opacity[(size_t)i] = peak;
            st.mu[(size_t)i] = 0.5f * (float)(rec.first + rec.last);
            st.log_sigma[(size_t)i] = std::log(std::clamp((float)(rec.last - rec.first + 1), 1.0f, (float)F));
            copy_row(frames[rec.first], r, seed, (size_t)i, sh);
        }
    });
    for (size_t i = real; i < n; i++) {
        st.opacity[i] = -20.0f;
        seed.opacities[i] = -20.0f;
    }
    log("spacetime: " + std::to_string(real) + " records from " + std::to_string(R) + " rows of " +
        cfg.spacetime_init + ", " + std::to_string(n - real) + " spare");
    return seed;
}

void TrainerSession::setup_spacetime() {
    const int F = (int)_chunk_dirs.size();
    // Every frame's views in one DataManager, frame-major: view v is frame v / N.
    std::vector<std::string> images, masks, depths, normals;
    auto add = [&](std::vector<std::string>& to, const std::vector<std::string>& files, bool on, int f) {
        const std::vector<std::string> mapped = on ? frame_files(files, f) : files;
        to.insert(to.end(), mapped.begin(), mapped.end());
    };
    for (int f = 0; f < F; f++) {
        add(images, ds.image_filenames, true, f);
        add(masks, ds.mask_filenames, has_mask, f);
        add(depths, ds.depth_filenames, has_depth, f);
        add(normals, ds.normal_filenames, has_normal, f);
    }
    install_data_manager(images, masks, depths, normals, F);
    engine_spacetime_begin(std::move(_spacetime), F, (int)ds.num_cameras, _room_rows);
    _spacetime = SpacetimeRecords{};
    if (cfg.spacetime_motion_weight > 0.0f)
        spacetime_motion_begin(cfg.spacetime_motion, cfg.spacetime_motion_weight, F, engine_spacetime_records().rows);
    fs::create_directories(out_dir / "frames");
    log("spacetime: " + std::to_string(F) + " frames x " + std::to_string(ds.num_cameras) + " views, " +
        std::to_string(engine_get_cur_num_splats()) + " splats");
}

// Every frame of the chunk, evaluated from the records, as the chunk runs write them.
void TrainerSession::save_spacetime(int step) {
    const int F = (int)_chunk_dirs.size();
    const int keep = engine_spacetime_frame();
    std::ofstream list(out_dir / "frames" / "frames.txt", std::ios::trunc);
    for (int f = 0; f < F; f++) {
        char name[32];
        std::snprintf(name, sizeof name, "%03d", f);
        engine_spacetime_set_frame(f, true);
        engine_save_checkpoint((out_dir / "frames" / name).string(), false, step,
                               cfg.background_export_height, "", false, "", true);
        if (_room_rows > 0)
            split_ply(out_dir / "frames" / name / "splat.ply", out_dir / "frames" / "room.ply", _room_rows);
        list << name << ' ' << _chunk_dirs[(size_t)f] << '\n';
    }
    if (keep >= 0) engine_spacetime_set_frame(keep);
    // For the .vgs writer: every row is one record over the whole chunk.
    std::ofstream events(out_dir / "frames" / "birth_events.tsv", std::ios::trunc);
    for (int64_t r = 0; r < engine_spacetime_records().rows; r++) events << 0 << '\t' << r << '\t' << 1 << '\n';
    if (!list || !events) throw std::runtime_error("spacetime: cannot write the frame list or birth events");
}

// Relocation runs from 1/12 to 5/6 of the steps: records need a settled need score
// before, and the last sixth polishes the copies without moving any more.
void TrainerSession::spacetime_after_step(int step, const EngineStepConfig& sc) {
    const int max_steps = cfg.max_steps.value_or(cfg.num_iterations);
    engine_spacetime_after_step({sc.optim.lr_means, sc.optim.lr_quats, sc.optim.lr_features_dc,
                                 sc.optim.lr_opacities, cfg.spacetime_window_lr, cfg.spacetime_window_lr,
                                 cfg.spacetime_batch, sc.optim.mcmc_opacity_reg_weight,
                                 scheduled_lr(step, max_steps, _spacetime_scales_lr, _spacetime_scales_lr_final),
                                 scheduled_lr(step, max_steps, _spacetime_sh_lr),
                                 sc.optim.mcmc_scale_reg_weight, sc.optim.sh_reg_weight});
    if (cfg.spacetime_relocate <= 0.0f || cfg.spacetime_relocate_every <= 0 ||
        (step + 1) % cfg.spacetime_relocate_every != 0)
        return;
    const bool open = step + 1 >= max_steps / 12 && 6 * (step + 1) <= 5 * max_steps;
    const int64_t budget = open ? (int64_t)(cfg.spacetime_relocate * (float)engine_spacetime_records().rows) : 0;
    const int64_t moved = engine_spacetime_relocate(budget, cfg.min_opacity, (uint64_t)step);
    if (open) log("spacetime: " + std::to_string(moved) + " of " + std::to_string(budget) + " records relocated");
}

}  // namespace spirula

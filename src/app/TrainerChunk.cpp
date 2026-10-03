// Chunk training (--temporal-frames): the TrainerSession members only it
// uses, kept out of TrainerCore.cpp, which reaches them through a few calls.
// The method and every experiment behind it: TEMPORAL_TRAINING.md.

#include "app/TrainerCore.h"
#include "engine/EngineTemporal.h"

#include <cmath>
#include <cstdio>
#include <fstream>
#include <stdexcept>

namespace fs = std::filesystem;

namespace spirula {

static bool unset(const std::string& v) { return v.empty() || v == "none"; }

ColorResolution resolve_color(const TrainConfig& c);

// check_config's part: the frame folders, and the run length they imply.
void TrainerSession::configure_chunk() {
    _chunk_dirs.clear();
    if (unset(cfg.temporal_frames)) return;
    _chunk_dirs.push_back(cfg.data);
    std::string rest = cfg.temporal_frames;
    for (size_t at = 0; at <= rest.size();) {
        size_t end = rest.find(';', at);
        if (end == std::string::npos) end = rest.size();
        if (end > at) _chunk_dirs.push_back(rest.substr(at, end - at));
        at = end + 1;
    }
    if (!cfg.resume.empty())
        throw std::runtime_error("--temporal-frames cannot be resumed");
    // Every frame shares one population and one optimizer layout: no
    // densification, full-precision Adam state.
    cfg.quantization_level = 0;
    if (cfg.temporal_window > 0) {
        // A frame enters every temporal_frame_steps steps and leaves the
        // window temporal_window entries later; the last ones then drain.
        const int n = (int)_chunk_dirs.size();
        cfg.num_iterations =
            first_frame_steps() + cfg.temporal_frame_steps * (n + cfg.temporal_window - 2);
        for (int j = 1; j < n; j++)
            if (is_keyframe(j)) cfg.num_iterations += keyframe_extra();
    }
    cfg.refine_start_iter = cfg.num_iterations + 1;
    cfg.export_keep_all_splats = true;
    log("chunk training over " + std::to_string(_chunk_dirs.size()) + " frames");
}

// Frame k's files are frame 0's with the dataset root swapped: the cameras are
// shared, so only the pixels differ.
void TrainerSession::install_frame_data(int frame) {
    const fs::path root = fs::path(cfg.data);
    const std::string& dir = _chunk_dirs[(size_t)frame];
    auto remap = [&](const std::vector<std::string>& files) {
        std::vector<std::string> out;
        out.reserve(files.size());
        for (const std::string& f : files) {
            if (f.empty()) { out.push_back(f); continue; }
            const fs::path p(f);
            const fs::path rel = p.is_absolute() ? p.lexically_relative(root) : p;
            if (rel.empty() || *rel.begin() == "..")
                throw std::runtime_error("chunk training: " + f + " is outside --data");
            const fs::path mapped = fs::path(dir) / rel;
            if (!fs::exists(mapped))
                throw std::runtime_error("chunk training: missing " + mapped.string());
            out.push_back(mapped.string());
        }
        return out;
    };
    install_data_manager(remap(ds.image_filenames),
                         has_mask ? remap(ds.mask_filenames) : ds.mask_filenames,
                         has_depth ? remap(ds.depth_filenames) : ds.depth_filenames,
                         has_normal ? remap(ds.normal_filenames) : ds.normal_filenames);
}

void TrainerSession::setup_chunk() {
    const int frames = cfg.temporal_window > 0 ? 1 : (int)_chunk_dirs.size();
    const bool whole_frames = !unset(cfg.temporal_init_dir);
    if (whole_frames && cfg.temporal_window > 0)
        throw std::runtime_error("--temporal-init-dir needs every frame in the chunk (no window)");
    engine_temporal_begin(frames, cfg.use_fused_proj_bwd_optim, cfg.use_per_splat_bias_correction,
                          whole_frames);
    engine_temporal_lock_shared(cfg.temporal_lock_shared);
    engine_temporal_stash_data_manager(0);
    for (int k = 1; k < frames; k++) {
        install_frame_data(k);
        engine_temporal_stash_data_manager(k);
    }
    // Each frame from its own PLY, row for row: a refinement of a finished chunk.
    for (int k = 0; whole_frames && k < frames; k++) {
        char name[32];
        std::snprintf(name, sizeof name, "%03d", k);
        const SeedSplats s = seed_splats_from_ply(
            (fs::path(cfg.temporal_init_dir) / "frames" / name / "splat.ply").string(), cfg,
            resolve_color(cfg));
        if (s.num != engine_get_cur_num_splats())
            throw std::runtime_error(std::string("--temporal-init-dir: frame ") + name +
                                     " has another row count");
        engine_temporal_load_frame(k, s.means, s.quats, s.opacities, s.features_dc, s.scales,
                                   s.features_sh);
    }
    engine_temporal_select(0);
    _window_first = 0;
    _window_next = frames;
    // Steps at which a frame enters (then, once all have, at which one drains);
    // num_iterations in check_config is the same sum.
    _advance_at.clear();
    _next_advance = 0;
    _solo_until = -1;
    if (cfg.temporal_window > 0) {
        int at = first_frame_steps();
        const int n = (int)_chunk_dirs.size();
        for (int j = 1; j < n; j++) {
            _advance_at.push_back(at);
            at += cfg.temporal_frame_steps + (is_keyframe(j) ? keyframe_extra() : 0);
        }
        for (int k = 0; k + 1 < cfg.temporal_window; k++, at += cfg.temporal_frame_steps)
            _advance_at.push_back(at);
    }
    _slot_age.assign((size_t)frames, 0);
    _window_schedule = cfg;
    _window_schedule.num_iterations = cfg.temporal_frame_steps;
    _window_schedule.max_steps = cfg.temporal_frame_steps;
    fs::create_directories(out_dir / "frames");
    std::ofstream(out_dir / "frames" / "frames.txt");
    log("chunk: " + std::to_string(_chunk_dirs.size()) + " frames" +
        (cfg.temporal_window > 0 ? ", window " + std::to_string(cfg.temporal_window) : "") +
        ", " + std::to_string(engine_get_cur_num_splats()) + " splats");
}

void TrainerSession::write_frame(int slot, int step) {
    // What is written is what gets frozen: the frozen values, not the drift
    // of the steps since they were last put back.
    if (cfg.temporal_lock_shared) engine_temporal_restore_locked();
    const int frame = _window_first + slot;
    char name[32];
    std::snprintf(name, sizeof name, "%03d", frame);
    const int keep = engine_temporal_current();
    engine_temporal_select(slot);
    engine_save_checkpoint((out_dir / "frames" / name).string(), false, step, true);
    std::ofstream(out_dir / "frames" / "frames.txt", std::ios::app)
        << name << ' ' << _chunk_dirs[(size_t)frame] << '\n';
    if (keep >= 0) engine_temporal_select(keep);
}

// Every temporal_frame_steps steps the next frame enters at the back, and once
// the window is full its oldest trainable frame is written and held: later
// frames are smoothed against it but never change it.
void TrainerSession::advance_window(int step) {
    const int W = cfg.temporal_window;
    if (_window_next < (int)_chunk_dirs.size()) {
        engine_temporal_park();
        TemporalWarp warp;
        bool warped = false;
        const bool auto_warp = cfg.temporal_warp_dir == "auto";
        const bool auto_births = cfg.temporal_birth_dir == "auto";
        if (auto_warp || auto_births) {
            if (_subject.xyz.empty()) _subject = subject_points(_chunk_dirs[0]);
            SubjectPoints entering = subject_points(_chunk_dirs[(size_t)_window_next]);
            if (auto_warp) {
                std::string line;
                warp.nodes = subject_warp(_subject, entering, warp.bind_radius, line);
                warped = true;
                log("warp " + std::to_string(_window_next - 1) + "->" +
                    std::to_string(_window_next) + " (" + std::to_string(_subject.size()) + " -> " +
                    std::to_string(entering.size()) + " subject points): " + line);
            }
            _subject = std::move(entering);
        } else if (!unset(cfg.temporal_warp_dir)) {
            char name[32];
            std::snprintf(name, sizeof name, "%03d.bin", _window_next);
            std::ifstream in(fs::path(cfg.temporal_warp_dir) / name, std::ios::binary);
            int32_t nodes = 0;
            if (in.read(reinterpret_cast<char*>(&nodes), 4) &&
                in.read(reinterpret_cast<char*>(&warp.bind_radius), 4) &&
                nodes > 0 && nodes <= 100000 &&
                warp.bind_radius > 0.0f && std::isfinite(warp.bind_radius)) {
                warp.nodes.resize((size_t)nodes * 10);
                warped = (bool)in.read(reinterpret_cast<char*>(warp.nodes.data()),
                                       (std::streamsize)(warp.nodes.size() * 4));
            }
            if (warped)
                for (float value : warp.nodes)
                    if (!std::isfinite(value)) warped = false;
            if (!warped || in.peek() != std::char_traits<char>::eof())
                throw std::runtime_error(std::string("invalid or missing temporal warp: ") + name);
        }
        install_frame_data(_window_next++);
        engine_temporal_push(cfg.temporal_entry_opacity_boost, warped ? &warp : nullptr);
        if (!unset(cfg.temporal_birth_dir)) {
            char name[32];
            std::snprintf(name, sizeof name, "%03d.bin", _window_next - 1);
            std::vector<float> points;
            if (auto_births) {
                points = subject_births(_subject);
            } else {
                std::ifstream in(fs::path(cfg.temporal_birth_dir) / name, std::ios::binary);
                int32_t count = 0;
                if (!in.read(reinterpret_cast<char*>(&count), 4) || count < 0 || count > 1000000)
                    throw std::runtime_error(std::string("invalid or missing temporal births: ") + name);
                if (count > 0) {
                    points.resize((size_t)count * 7);
                    if (!in.read(reinterpret_cast<char*>(points.data()), (std::streamsize)(points.size() * 4)))
                        throw std::runtime_error(std::string("truncated temporal births: ") + name);
                }
                if (in.peek() != std::char_traits<char>::eof())
                    throw std::runtime_error(std::string("trailing temporal births: ") + name);
            }
            std::vector<TemporalBirth> births;
            const int64_t born = engine_temporal_birth(
                points, cfg.temporal_birth_gap,
                (int64_t)(cfg.temporal_birth_fraction * (float)engine_get_cur_num_splats()), &births);
            if (!births.empty()) {
                fs::create_directories(out_dir / "frames");
                std::ofstream events(out_dir / "frames" / "birth_events.tsv", std::ios::app);
                if (!events) throw std::runtime_error("cannot write temporal birth events");
                for (const TemporalBirth& b : births)
                    events << _window_next - 1 << '\t' << b.row << '\t' << b.generation << '\n';
                if (!events) throw std::runtime_error("cannot write temporal birth events");
            }
            log(std::string("frame ") + name + ": " + std::to_string(born) + " splats born");
        }
        _slot_age.push_back(0);
    }
    int trainable = 0, oldest = -1;
    for (int k = 0; k < engine_temporal_frames(); k++)
        if (!engine_temporal_held(k)) { trainable++; if (oldest < 0) oldest = k; }
    // The last trainable frame is left for save_chunk, so a step always has one.
    const bool flushing = _window_next == (int)_chunk_dirs.size();
    if (oldest >= 0 && (trainable > W || (flushing && trainable > 1))) {
        write_frame(oldest, step);
        engine_temporal_hold(oldest);
    }
    int held_front = 0;
    while (held_front < engine_temporal_frames() && engine_temporal_held(held_front)) held_front++;
    while (held_front > cfg.temporal_history) {
        engine_temporal_drop_front();
        _slot_age.erase(_slot_age.begin());
        _window_first++;
        held_front--;
    }
}

void TrainerSession::save_chunk(int step) {
    if (cfg.temporal_window > 0) {
        for (int k = 0; k < engine_temporal_frames(); k++)
            if (!engine_temporal_held(k)) write_frame(k, step);
        return;
    }
    for (int k = 0; k < engine_temporal_frames(); k++) write_frame(k, step);
}

// train_step's part: a window frame may enter, then the frame this step
// trains is drawn, and a window frame runs its own schedule over its own steps.
void TrainerSession::chunk_step(int step, int& schedule_step, const TrainConfig*& schedule) {
    if (cfg.temporal_window > 0 && _next_advance < _advance_at.size() &&
        step == _advance_at[_next_advance]) {
        const int entering = _window_next;
        advance_window(step);
        _next_advance++;
        if (entering < (int)_chunk_dirs.size() && is_keyframe(entering))
            _solo_until = step + keyframe_extra();
    }
    std::vector<int> trainable;
    for (int k = 0; k < engine_temporal_frames(); k++)
        if (!engine_temporal_held(k)) trainable.push_back(k);
    if (step < _solo_until) trainable.erase(trainable.begin(), trainable.end() - 1);
    // splitmix64: a frame per step, independent of the DataManagers' draws.
    uint64_t z = (_chunk_rng += 0x9e3779b97f4a7c15ull);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ull;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebull;
    z ^= z >> 31;
    const int slot = trainable[(size_t)(z % trainable.size())];
    engine_temporal_select(slot);
    // A window frame runs its own learning-rate schedule, over its own steps.
    if (cfg.temporal_window > 0) {
        // The first frame's schedule is stretched over its own budget.
        const int frame = _window_first + slot;
        const int life = frame == 0             ? first_frame_steps()
                         : is_keyframe(frame)   ? cfg.temporal_frame_steps + keyframe_extra()
                                                : cfg.temporal_frame_steps;
        schedule_step = std::min(
            (int)((int64_t)_slot_age[(size_t)slot]++ * cfg.temporal_frame_steps / life),
            cfg.temporal_frame_steps);
        schedule = &_window_schedule;
    }
}

void TrainerSession::chunk_after_step(int step) {
    // Every 10 steps: 1 ms of transfers each time, and 10 steps of drift at a
    // slowed scale rate move a frozen splat by nothing measurable.
    if (cfg.temporal_lock_shared && (step + 1) % 10 == 0) engine_temporal_restore_locked();
    if (cfg.temporal_smooth_every > 0 && (step + 1) % cfg.temporal_smooth_every == 0)
        engine_temporal_smooth({cfg.temporal_smooth_position, cfg.temporal_smooth_rotation,
                                cfg.temporal_smooth_opacity, cfg.temporal_smooth_color});
}

void TrainerSession::eval_chunk() {
    if (cfg.temporal_window > 0) return;  // the frames scored are already gone
    for (int k = 0; k < engine_temporal_frames(); k++) {
        char name[32];
        std::snprintf(name, sizeof name, "%03d", k);
        engine_temporal_select(k);
        eval_frame(_chunk_dirs[k], out_dir / "frames" / name / "metrics.json");
    }
}

}  // namespace spirula

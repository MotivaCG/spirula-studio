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

// New records, for the .vgs writer; `first` is the chunk frame in slot 0.
static void append_births(const fs::path& out_dir, int first, const std::vector<TemporalBirth>& births) {
    if (births.empty()) return;
    fs::create_directories(out_dir / "frames");
    std::ofstream events(out_dir / "frames" / "birth_events.tsv", std::ios::app);
    for (const TemporalBirth& b : births)
        events << first + b.slot << '\t' << b.row << '\t' << b.generation << '\n';
    if (!events) throw std::runtime_error("cannot write temporal birth events");
}

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
    if (continues() && cfg.temporal_window <= 0)
        throw std::runtime_error("--temporal-continue needs --temporal-window");
    if (spacetime() && (cfg.temporal_window > 0 || continues()))
        throw std::runtime_error("--spacetime-init trains the chunk whole: no window, no continue");
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
    // Spacetime chains the engine's per-frame gradients to the records: the
    // unfused optimizer leaves them in engine().grad, one view a step.
    if (spacetime()) {
        cfg.use_fused_proj_bwd_optim = false;
        // Scale and SH, one per record as .vgs keeps them, step with the records on
        // the batch's gradients: the engine's one view a step cost 0.56 dB (battery ST).
        _spacetime_scales_lr = cfg.scales_lr;
        _spacetime_scales_lr_final = cfg.scales_lr_final;
        _spacetime_sh_lr = cfg.features_sh_lr;
        cfg.scales_lr = 0.0f;
        cfg.scales_lr_final = 0.0f;
        cfg.features_sh_lr = 0.0f;
    }
    log("chunk training over " + std::to_string(_chunk_dirs.size()) + " frames");
}

// --temporal-spare: dead rows after the seed's, copies of its first ones, for
// relocation to take: without them a chunk frees almost none (battery RG). A chunk
// continuing another keeps its rows, spare ones included: one row count per run.
static SeedSplats with_spare(SeedSplats seed, float fraction) {
    const size_t cap = seed.opacities.size();
    const size_t first = (size_t)seed.num;
    const size_t spare = std::min(cap - first, (size_t)(fraction * (float)first));
    auto copy = [&](std::vector<float>& v) {
        const size_t width = v.size() / cap;
        for (size_t i = 0; i < spare; i++)
            std::copy_n(v.begin() + width * (i % first), width, v.begin() + width * (first + i));
    };
    for (auto* v : {&seed.means, &seed.quats, &seed.scales, &seed.opacities, &seed.features_dc, &seed.features_sh})
        copy(*v);
    std::fill_n(seed.opacities.begin() + first, spare, -20.0f);
    seed.num += (int64_t)spare;
    return seed;
}

// --temporal-room-ply: the room's rows before the seed's, so a frame's row r
// is engine row room + r and the frames written hold the seed's rows only.
SeedSplats TrainerSession::with_room(SeedSplats seed, const ColorResolution& color) {
    _room_rows = 0;
    if (_chunk_dirs.size() < 2) return seed;
    const float spare = continues() || spacetime() ? 0.0f : cfg.temporal_spare;
    // Spacetime starts from the chunk run's room as it trained, not the one it
    // started from: frozen untrained, it cost the subject its colour (battery ST).
    const fs::path trained = fs::path(cfg.spacetime_init) / "frames" / "room.ply";
    const std::string room_ply = spacetime() && fs::exists(trained) ? trained.string() : cfg.temporal_room_ply;
    const SeedSplats room = unset(room_ply) ? SeedSplats{} : seed_splats_from_ply(room_ply, cfg, color);
    _room_rows = room.num;
    if (spacetime()) seed = spacetime_seed(color, seed.opacities.size());
    if (unset(room_ply)) return with_spare(std::move(seed), spare);
    const size_t cap = seed.opacities.size();
    if ((size_t)(room.num + seed.num) > cap)
        throw std::runtime_error("--temporal-room-ply: the room and the seed exceed cap_max");
    SeedSplats out = seed;
    auto place = [&](std::vector<float>& to, const std::vector<float>& first,
                     const std::vector<float>& then) {
        const size_t width = to.size() / cap;
        std::copy_n(first.begin(), width * (size_t)room.num, to.begin());
        std::copy_n(then.begin(), width * (size_t)seed.num, to.begin() + width * (size_t)room.num);
    };
    place(out.means, room.means, seed.means);
    place(out.quats, room.quats, seed.quats);
    place(out.scales, room.scales, seed.scales);
    place(out.opacities, room.opacities, seed.opacities);
    place(out.features_dc, room.features_dc, seed.features_dc);
    place(out.features_sh, room.features_sh, seed.features_sh);
    out.num = room.num + seed.num;
    log("chunk: a static room of " + std::to_string(room.num) + " splats before the seed's " +
        std::to_string(seed.num));
    return with_spare(std::move(out), spare);
}

void split_ply(const fs::path& from, const fs::path& to, int64_t rows) {
    std::ifstream in(from, std::ios::binary);
    std::string header, line, vertex;
    int64_t count = -1, columns = 0;
    while (std::getline(in, line)) {
        if (line.rfind("element vertex ", 0) == 0) {
            count = std::stoll(line.substr(15));
            vertex = line + "\n";  // as written: the engine zero-pads the count
        }
        else if (line.rfind("property float ", 0) == 0) columns++;
        else if (line.rfind("property ", 0) == 0)
            throw std::runtime_error(from.string() + ": only float properties are split");
        header += line + "\n";
        if (line == "end_header") break;
    }
    if (count < rows) throw std::runtime_error(from.string() + ": fewer rows than the room");
    std::vector<char> data((size_t)(count * columns * 4));
    in.read(data.data(), (std::streamsize)data.size());
    if (!in) throw std::runtime_error(from.string() + ": truncated");
    in.close();
    auto write = [&](const fs::path& path, int64_t first, int64_t n) {
        std::string h = header;
        h.replace(h.find(vertex), vertex.size(), "element vertex " + std::to_string(n) + "\n");
        std::ofstream out(path, std::ios::binary | std::ios::trunc);
        out << h;
        out.write(data.data() + first * columns * 4, (std::streamsize)(n * columns * 4));
        if (!out) throw std::runtime_error("cannot write " + path.string());
    };
    write(to, 0, rows);
    write(from, rows, count - rows);
}

// Frame k's files are frame 0's with the dataset root swapped: the cameras are
// shared, so only the pixels differ.
std::vector<std::string> TrainerSession::frame_files(const std::vector<std::string>& files,
                                                     int frame) const {
    const fs::path root = fs::path(cfg.data);
    const std::string& dir = _chunk_dirs[(size_t)frame];
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
}

void TrainerSession::install_frame_data(int frame) {
    install_data_manager(frame_files(ds.image_filenames, frame),
                         has_mask ? frame_files(ds.mask_filenames, frame) : ds.mask_filenames,
                         has_depth ? frame_files(ds.depth_filenames, frame) : ds.depth_filenames,
                         has_normal ? frame_files(ds.normal_filenames, frame) : ds.normal_filenames);
}

void TrainerSession::setup_chunk() {
    if (spacetime()) return setup_spacetime();
    const int frames = cfg.temporal_window > 0 ? 1 : (int)_chunk_dirs.size();
    const bool whole_frames = !unset(cfg.temporal_init_dir);
    if (whole_frames && cfg.temporal_window > 0)
        throw std::runtime_error("--temporal-init-dir needs every frame in the chunk (no window)");
    engine_temporal_begin(frames, cfg.use_fused_proj_bwd_optim, cfg.use_per_splat_bias_correction,
                          whole_frames, _room_rows);
    engine_temporal_lock_shared(cfg.temporal_lock_shared);
    if (cfg.temporal_anchors > 0) {
        if (_subject.xyz.empty()) _subject = subject_points(_chunk_dirs[0]);
        log("chunk: motion through " +
            std::to_string(engine_temporal_anchors(cfg.temporal_anchors, _subject.xyz)) + " anchors");
    }
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
        if (s.num != engine_get_cur_num_splats() - _room_rows)
            throw std::runtime_error(std::string("--temporal-init-dir: frame ") + name +
                                     " has another row count");
        engine_temporal_load_frame(k, s.means, s.quats, s.opacities, s.features_dc, s.scales,
                                   s.features_sh);
    }
    engine_temporal_select(0);
    // Retrained alone, the previous chunk's last frame lost 85k splats and the
    // boundary flickered twice the chunk's rate (FG6): it stays as written.
    if (continues()) {
        engine_temporal_hold(0);
        if (cfg.temporal_warp_dir == "auto" || cfg.temporal_birth_dir == "auto")
            _subject = subject_points(cfg.temporal_continue);
    }
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
    engine_temporal_project_motion();
    const int frame = _window_first + slot;
    char name[32];
    std::snprintf(name, sizeof name, "%03d", frame);
    const int keep = engine_temporal_current();
    engine_temporal_select(slot);
    engine_save_checkpoint((out_dir / "frames" / name).string(), false, step,
                           cfg.background_export_height, "", false, "", true);
    // The room is no frame's: the last frame written leaves it as the room's file.
    if (_room_rows > 0)
        split_ply(out_dir / "frames" / name / "splat.ply", out_dir / "frames" / "room.ply",
                  _room_rows);
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
            append_births(out_dir, _window_first, births);
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
    if (cfg.temporal_smooth_every > 0 && (step + 1) % cfg.temporal_smooth_every == 0) {
        engine_temporal_smooth({cfg.temporal_smooth_position, cfg.temporal_smooth_rotation,
                                cfg.temporal_smooth_opacity, cfg.temporal_smooth_color,
                                cfg.temporal_smooth_coherence});
        engine_temporal_project_motion();
    }
    // Without it each frame inherits the last one's splats and detail fades along
    // the chain (battery RL). Only while the newest frame is entering: draining the
    // window after the last one entered piled every split into that frame (RD2: 22k).
    if (cfg.temporal_relocate <= 0.0f || cfg.temporal_window <= 0 || cfg.temporal_relocate_every <= 0 ||
        (step + 1) % cfg.temporal_relocate_every != 0)
        return;
    const int newest = _window_next - 1;
    const int entered = newest == 0 ? 0 : _advance_at[(size_t)newest - 1];
    const int life = newest == 0         ? first_frame_steps()
                     : is_keyframe(newest) ? cfg.temporal_frame_steps + keyframe_extra()
                                           : cfg.temporal_frame_steps;
    if (step + 1 < entered + life) {
        // Asked and done both logged: free rows, not the budget, limit it (battery RS).
        const int64_t budget = (int64_t)(cfg.temporal_relocate * (float)engine_get_cur_num_splats());
        std::vector<TemporalBirth> births;
        const int64_t moved = engine_temporal_relocate(budget, cfg.min_opacity, (uint64_t)step, &births);
        append_births(out_dir, _window_first, births);
        log("frame " + std::to_string(newest) + ": " + std::to_string(moved) + " of " +
            std::to_string(budget) + " splats relocated");
    }
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

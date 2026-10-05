// Chunk training: one splat population shared by several frames of a take.
// Position, rotation, opacity and base colour are held per frame and swapped
// into the live buffers before each step; scale and higher-order SH stay shared.
// Frames are ordered in time; a sliding window appends at the back and drops
// the front. A held frame is neither trained nor smoothed but its neighbours
// are smoothed against it.
#pragma once
#include <cstdint>
#include <string>
#include <vector>

struct TemporalSmoothing {
    float position = 0.0f;
    float rotation = 0.0f;
    float opacity = 0.0f;
    float color = 0.0f;
};

// Snapshots the live splats into every frame. The population is fixed from here
// on: a densify step would change cur_num_splats and select() refuses that.
void engine_temporal_begin(int frames, bool fused, bool per_splat_bias, bool per_frame_shape);
void engine_temporal_end();
bool engine_temporal_active();
int engine_temporal_frames();
int engine_temporal_current();

// Takes ownership of the engine's current DataManager as `frame`'s image source.
void engine_temporal_stash_data_manager(int frame);
void engine_temporal_select(int frame);
// Writes the live frame back and returns its DataManager to it, leaving the
// engine without one, so a new one can be installed for push().
void engine_temporal_park();

// A deformation graph from one frame to the next: nodes g, translations t and
// rotations q (wxyz), as rows [g(3), t(3), q(4)], and the skinning radius.
struct TemporalWarp {
    std::vector<float> nodes;
    float bind_radius = 0.0f;
};

struct TemporalBirth {
    int64_t row = 0;
    uint32_t generation = 0;
};

// Appends a frame: the last one carried by `warp`, or moved on at the last
// velocity, opacity scaled by opacity_boost, with the last one's optimizer
// state. Its images are the engine's DataManager.
void engine_temporal_push(float opacity_boost, const TemporalWarp* warp);
void engine_temporal_hold(int frame);
// Holding a frame freezes the shared scale and SH of the records in it until a
// birth reuses the row (.vgs: one per record per chunk). The optimizer still
// moves them; restore_locked puts the frozen values back.
void engine_temporal_lock_shared(bool on);
void engine_temporal_restore_locked();
// A frame loaded whole into its slot, scale and SH included (per_frame_shape).
void engine_temporal_load_frame(int frame, const std::vector<float>& means,
                                const std::vector<float>& quats, const std::vector<float>& opacities,
                                const std::vector<float>& dc, const std::vector<float>& scales,
                                const std::vector<float>& sh);
bool engine_temporal_held(int frame);
void engine_temporal_drop_front();

// Births into the last frame: points (rows [xyz, rgb 0..1, spacing]) with no
// live splat within `gap` take rows dead in every frame, held ones included, so
// no frame already shown changes. Returns how many were born.
int64_t engine_temporal_birth(const std::vector<float>& points, float gap, int64_t max_new,
                              std::vector<TemporalBirth>* events = nullptr);

// One smoothing step along time per attribute, weights in [0, 1]: second
// difference for position and rotation, first for opacity and colour.
void engine_temporal_smooth(const TemporalSmoothing& weights);

// Motion through anchors (TemporalAnchors.h): about `anchors` placed over the
// splats shown now near `subject` (xyz rows); returns how many. A record is
// bound in the first held frame that shows it and moves freely until then.
int engine_temporal_anchors(int anchors, const std::vector<float>& subject);
// Every trainable frame: its anchors fitted to its bound rows, and those rows
// put back on them, so written frames move only as the anchors do.
void engine_temporal_project_motion();

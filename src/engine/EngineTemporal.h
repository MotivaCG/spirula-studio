// Chunk training: one splat population shared by several frames of a take.
// Position, rotation, opacity and base colour are held per frame and swapped
// into the live buffers before each step; scale and higher-order SH stay shared.
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
void engine_temporal_begin(int frames, bool fused, bool per_splat_bias);
void engine_temporal_end();
bool engine_temporal_active();
int engine_temporal_frames();
int engine_temporal_current();

// Takes ownership of the engine's current DataManager as `frame`'s image source.
void engine_temporal_stash_data_manager(int frame);
void engine_temporal_select(int frame);

// One smoothing step along time per attribute, weights in [0, 1]: second
// difference for position and rotation, first for opacity and colour.
void engine_temporal_smooth(const TemporalSmoothing& weights, bool hold_first);

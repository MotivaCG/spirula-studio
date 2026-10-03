#pragma once

// What chunk training needs from each frame's dataset besides its pixels: the
// subject's SfM points, the deformation graph that carries one frame's splats
// to the next, and the points where new splats may be born. Port of
// reference/temporal/{hull,warps,births}.py, which produced the files that
// --temporal-warp-dir and --temporal-birth-dir read.

#include <string>
#include <vector>

// The SfM points of a frame whose centre falls inside the mask in most of the
// views that see it: the subject, without the static room.
struct SubjectPoints {
    std::vector<float> xyz;  // [N, 3], COLMAP world frame
    std::vector<float> rgb;  // [N, 3], 0..1
    size_t size() const { return xyz.size() / 3; }
};

SubjectPoints subject_points(const std::string& frame_dir);

// Deformation graph from `source` to `target`: rows [g(3), t(3), q_wxyz(4)] and
// the skinning radius, as TemporalWarp takes them. `log` gets one line.
std::vector<float> subject_warp(const SubjectPoints& source, const SubjectPoints& target,
                                float& bind_radius, std::string& log);

// Birth candidates: rows [x, y, z, r, g, b, spacing], spacing being the
// distance to the 4th nearest subject point, as engine_temporal_birth takes.
std::vector<float> subject_births(const SubjectPoints& points);

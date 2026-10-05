// Motion through anchors (ReCon-GS's idea, translation only): every splat moves
// with a fixed blend of four anchors' displacements. That is what .vgs encoding 0
// stores per record, a base plus four weighted trajectories from a dictionary
// shared by the chunk, so a chunk trained this way leaves its codec nothing to
// approximate in position. Host-side math only; EngineTemporal holds the state.
#pragma once
#include <array>
#include <cstdint>
#include <unordered_map>
#include <vector>

struct AnchorRig {
    float spacing = 0.0f;
    std::vector<float> rest;  // anchors x 3, where they are with no displacement
    // Per row, once bound: its four anchors and their weights.
    std::vector<std::array<int32_t, 4>> index;
    std::vector<std::array<float, 4>> weight;
};

// About `anchors` anchors, one per occupied cell of a grid over the `points`
// (xyz rows) within a few centimetres of `subject`, at the mean of its points:
// the room around a person does not move. `rows` sizes the binding tables.
AnchorRig anchor_rig(const std::vector<float>& points, const std::vector<float>& subject, int anchors,
                     size_t rows);

// Where the anchors are (anchors x 3), indexed for nearest-anchor queries.
struct AnchorGrid {
    const std::vector<float>* at = nullptr;
    float cell = 0.0f;
    std::unordered_map<int64_t, std::vector<int32_t>> cells;
};
AnchorGrid anchor_grid(const AnchorRig& rig, const std::vector<float>& at);

// Binds `row` at position p to its four nearest anchors. The weights add up to
// one and rebuild p from the anchors' positions, so motion linear across the
// four (a turning limb) moves it as them. Far from every anchor it stays still.
void anchor_bind(AnchorRig& rig, const AnchorGrid& grid, size_t row, const float* p);

// The displacements (anchors x 3; in: the prior, out: the fit) that best explain
// `offsets` (3 per entry of `rows`: the row's position minus its base), each row
// weighted by `importance`. Anchors no row sees keep the prior.
void anchor_solve(const AnchorRig& rig, const std::vector<uint32_t>& rows,
                  const std::vector<float>& offsets, const std::vector<float>& importance,
                  std::vector<float>& displacement);

// A bound row's offset from its base under `displacement`.
std::array<float, 3> anchor_offset(const AnchorRig& rig, size_t row,
                                   const std::vector<float>& displacement);

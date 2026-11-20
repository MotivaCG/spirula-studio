// Spacetime chunk training: every subject row is one .vgs record over the whole
// chunk. Position, rotation, base colour and opacity are uniform cubic B-splines
// in time, opacity also times a soft window [t0, t1] (frames); scale and SH sit in
// the engine's buffers, constant per record as .vgs stores them. Each step evaluates the
// records at the frame of the step's view into the live buffers, the engine
// trains as usual, and the gradients it leaves in engine().grad are chained back
// to the records, which keep their own Adam state. Design: 4DGS_Papers PLAN.md.
#pragma once
#include <cstdint>
#include <vector>

struct TrainStep;

constexpr int kSpacetimePos = 16;   // position control points per record (8: p90 1.6 mm off the chain)
constexpr int kSpacetimeRot = 8;    // rotation control points (raw quaternions)
constexpr int kSpacetimeColor = 8;  // base colour control points (DC coefficients)
constexpr int kSpacetimeOpacity = 8;  // opacity logit control points (constant: less detail)

// Rows [room, room + rows) of the engine, record r at row room + r.
struct SpacetimeRecords {
    int64_t rows = 0;
    std::vector<float> pos;      // [rows, kSpacetimePos, 3]
    std::vector<float> rot;      // [rows, kSpacetimeRot, 4]
    std::vector<float> color;    // [rows, kSpacetimeColor, 3]
    std::vector<float> opacity;  // [rows, kSpacetimeOpacity] logit, times the window
    std::vector<float> window;   // [rows, 2] t0, t1 in frames, soft edges
};

struct SpacetimeRates {
    float pos = 0, rot = 0, color = 0, opacity = 0, window = 0;
    int batch = 1;  // views whose gradients one step averages
    // The engine's opacity penalty (mcmc_opacity_reg_weight): its optimizer adds
    // it past the gradient buffers, so the records take it here.
    float opacity_reg = 0;
    // Scale and SH, one per record over the chunk; their penalties as opacity_reg.
    float scale = 0, sh = 0, scale_reg = 0, sh_reg = 0;
};

// Weights of the K control points of a clamped uniform cubic B-spline at frame
// t of `frames` (t clamped to [0, frames - 1]).
void spacetime_basis(int K, int frames, float t, float* w);
// The soft life window's factor at frame t.
float spacetime_window(float t0, float t1, float t);

void engine_spacetime_begin(SpacetimeRecords records, int frames, int views_per_frame, int64_t room);
void engine_spacetime_end();
bool engine_spacetime_active();
// The camera of a view, for per-camera state (PPISP, bilagrid): views are
// frame-major, so view v is camera v mod views_per_frame. Identity when off.
int32_t engine_spacetime_camera(int32_t view);
// The engine's hook, after it draws a step's views: they must share a frame.
void engine_spacetime_before_step(const TrainStep& step);
// The records at `frame` into the live buffers (writing a frame, evaluating).
// unit_quats for files: the spline's quaternions are not unit, the renderer's are.
void engine_spacetime_set_frame(int frame, bool unit_quats = false);
int engine_spacetime_frame();
// The step's gradients chained to the records; every `batch` views, one Adam
// step on their mean.
void engine_spacetime_after_step(const SpacetimeRates& lr);
const SpacetimeRecords& engine_spacetime_records();
// Relocation in spacetime: records shown in no frame (alpha under min_opacity
// everywhere) take long-axis splits of the records the densification score
// points at, one record for the whole chunk each. Returns how many moved.
int64_t engine_spacetime_relocate(int64_t max_new, float min_opacity, uint64_t seed);

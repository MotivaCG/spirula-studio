// Motion supervision for spacetime training (MOTION_SUPERVISED_4D.md): each
// record's step to the next and the previous frame follows the multiview scene
// flow observed near it, a robust loss whose gradient joins the photometric one
// before the records' Adam step. Off unless --spacetime-motion-weight > 0.
#pragma once
#include <cstdint>
#include <string>

struct SpacetimeRecords;

// One view's state, from engine_spacetime_after_step.
struct SpacetimeMotionView {
    const SpacetimeRecords* rec = nullptr;
    int frame = 0;
    const float* log_scales = nullptr;  // [rows, 3]
    // The view's gradients per record: a record with none was not in the view.
    const float *grad_means = nullptr, *grad_quats = nullptr, *grad_opacities = nullptr, *grad_dc = nullptr;
    float* acc = nullptr;  // each record's position control point gradients, `stride` floats apart
    int stride = 0;
};

// Loads <dir>/fwd_NNN.bin (frame n to n + 1) and bwd_NNN.bin (n to n - 1).
// The loss weight is `weight` times the one calibrated on the first views.
void spacetime_motion_begin(const std::string& dir, float weight, int frames, int64_t rows);
bool spacetime_motion_active();
void spacetime_motion_view(const SpacetimeMotionView& v);
// A record whose trajectory was replaced (relocation) reads its targets again.
void spacetime_motion_forget(int64_t record);
// lambda * w * rho(|e| / sigma), e = p(g) - p(f) - s, with p = sum_k b_k P_k:
// adds its gradient to grad[K * 3] and returns it. s and w are held fixed.
float spacetime_motion_pair(const float* P, const float* bf, const float* bg, const float* s, float w, float lambda,
                            float* grad);

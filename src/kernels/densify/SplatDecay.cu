// SplatDecay.cu -- per-refine opacity/scale decay written onto the parameters.
//
// Part of the Densify family -- see DensifyCommon.cuh.

#include "kernels/densify/DensifyCommon.cuh"

// Written onto the parameters, not added to the loss: Adam normalizes a
// constant reg gradient to +-lr (m/sqrt(v) -> 1), so opacity_reg's magnitude
// never reaches a splat no camera supervises. Linear opacity keeps it selective.
__global__ void splat_decay_3dgs_kernel(
    long num_splats,
    float opacity_decay,
    float scale_decay,
    float* __restrict__ logit_opacs,
    float3* __restrict__ log_scales
) {
    size_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= num_splats)
        return;

    if (opacity_decay > 0.0f) {
        float opac = 1.0f / (1.0f + expf(-logit_opacs[idx])) - opacity_decay;
        opac = fminf(fmaxf(opac, 1e-12f), 1.0f - 1e-12f);
        logit_opacs[idx] = logf(opac / (1.0f - opac));
    }
    if (scale_decay > 0.0f) {
        const float shrink = logf(fmaxf(1.0f - scale_decay, 1e-12f));
        float3 s = log_scales[idx];
        log_scales[idx] = make_float3(s.x + shrink, s.y + shrink, s.z + shrink);
    }
}


/*[AutoHeaderGeneratorExport]*/
void splat_decay_tensor(
    int64_t num_splats,
    float opacity_decay,
    float scale_decay,
    DeviceVector<float> opacs,
    DeviceVector<float3> log_scales
) {
    if (num_splats <= 0 || (opacity_decay <= 0.0f && scale_decay <= 0.0f))
        return;
    splat_decay_3dgs_kernel<<<_LAUNCH_ARGS_1D(num_splats, 256)>>>(
        num_splats, opacity_decay, scale_decay,
        opacs.data_ptr(),
        log_scales.data_ptr()
    );
    CHECK_DEVICE_ERROR(cudaGetLastError());
}

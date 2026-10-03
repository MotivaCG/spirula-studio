#pragma once
#include "data/DataManager.h"
#include <cstdint>
#include <memory>
#include <vector>
struct float3 { float x, y, z; };
struct float4 { float x, y, z, w; };
struct Buffer {
    std::vector<float> values;
    void* data_ptr() { return values.empty() ? nullptr : values.data(); }
    void reset(size_t n, float value = 0) { values.assign(n, value); }
};
struct World {
    Buffer means, quats, opacities, features_dc, scales, features_sh;
    int sh_value_bits = 32;
};
struct Optim {
    Buffer g1_means, g2_means, g1_quats, g2_quats, g1_opacities, g2_opacities;
    Buffer g1_features_dc, g2_features_dc, g1_scales, g2_scales;
    Buffer g1_features_sh, g2_features_sh, bias_correction_steps;
    bool use_fused_proj_bwd_optim = false, use_per_splat_bias_correction = false;
    bool non_sh_quantize_enabled() const { return false; }
    bool sh_quantize_enabled() const { return false; }
};
struct EngineState {
    World world;
    Optim optim;
    int64_t cur_num_splats = 0;
    int num_sh = 3;
    std::unique_ptr<DataManager> dm;
};
inline EngineState& engine() { static EngineState state; return state; }

#pragma once

#include "generated/slang.cuh"

struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};

inline __device__ void _d_min_0(DiffPair_float_0 * dpx_0, DiffPair_float_0 * dpy_0, float dOut_0)
{
    DiffPair_float_0 _S1 = *dpx_0;
    float _S2;
    if(((*dpx_0).primal_0) < ((*dpy_0).primal_0))
    {
        _S2 = dOut_0;
    }
    else
    {
        if(((*dpx_0).primal_0) > ((*dpy_0).primal_0))
        {
            _S2 = 0.0f;
        }
        else
        {
            _S2 = 0.5f * dOut_0;
        }
    }
    dpx_0->primal_0 = _S1.primal_0;
    dpx_0->differential_0 = _S2;
    DiffPair_float_0 _S3 = *dpy_0;
    if(((*dpy_0).primal_0) < (_S1.primal_0))
    {
        _S2 = dOut_0;
    }
    else
    {
        if(((*dpy_0).primal_0) > ((*dpx_0).primal_0))
        {
            _S2 = 0.0f;
        }
        else
        {
            _S2 = 0.5f * dOut_0;
        }
    }
    dpy_0->primal_0 = _S3.primal_0;
    dpy_0->differential_0 = _S2;
    return;
}

struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    float3  primal_0;
    float3  differential_0;
};

inline __device__ void _d_dot_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_1, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpy_1, float dOut_1)
{
    float3  x_d_result_0;
    *&((&x_d_result_0)->x) = (*dpy_1).primal_0.x * dOut_1;
    float3  y_d_result_0;
    *&((&y_d_result_0)->x) = (*dpx_1).primal_0.x * dOut_1;
    *&((&x_d_result_0)->y) = (*dpy_1).primal_0.y * dOut_1;
    *&((&y_d_result_0)->y) = (*dpx_1).primal_0.y * dOut_1;
    *&((&x_d_result_0)->z) = (*dpy_1).primal_0.z * dOut_1;
    *&((&y_d_result_0)->z) = (*dpx_1).primal_0.z * dOut_1;
    dpx_1->primal_0 = (*dpx_1).primal_0;
    dpx_1->differential_0 = x_d_result_0;
    dpy_1->primal_0 = (*dpy_1).primal_0;
    dpy_1->differential_0 = y_d_result_0;
    return;
}

inline __device__ float dot_0(float3  x_0, float3  y_0)
{
    int i_0 = int(0);
    float result_0 = 0.0f;
    for(;;)
    {
        if(i_0 < int(3))
        {
        }
        else
        {
            break;
        }
        float result_1 = result_0 + _slang_vector_get_element(x_0, i_0) * _slang_vector_get_element(y_0, i_0);
        i_0 = i_0 + int(1);
        result_0 = result_1;
    }
    return result_0;
}

inline __device__ void _d_max_0(DiffPair_float_0 * dpx_2, DiffPair_float_0 * dpy_2, float dOut_2)
{
    DiffPair_float_0 _S4 = *dpx_2;
    float _S5;
    if(((*dpx_2).primal_0) > ((*dpy_2).primal_0))
    {
        _S5 = dOut_2;
    }
    else
    {
        if(((*dpx_2).primal_0) < ((*dpy_2).primal_0))
        {
            _S5 = 0.0f;
        }
        else
        {
            _S5 = 0.5f * dOut_2;
        }
    }
    dpx_2->primal_0 = _S4.primal_0;
    dpx_2->differential_0 = _S5;
    DiffPair_float_0 _S6 = *dpy_2;
    if(((*dpy_2).primal_0) > (_S4.primal_0))
    {
        _S5 = dOut_2;
    }
    else
    {
        if(((*dpy_2).primal_0) < ((*dpx_2).primal_0))
        {
            _S5 = 0.0f;
        }
        else
        {
            _S5 = 0.5f * dOut_2;
        }
    }
    dpy_2->primal_0 = _S6.primal_0;
    dpy_2->differential_0 = _S5;
    return;
}

inline __device__ void _d_clamp_0(DiffPair_float_0 * dpx_3, DiffPair_float_0 * dpMin_0, DiffPair_float_0 * dpMax_0, float dOut_3)
{
    DiffPair_float_0 _S7 = *dpx_3;
    bool _S8;
    if(((*dpx_3).primal_0) >= ((*dpMin_0).primal_0))
    {
        _S8 = ((*dpx_3).primal_0) <= ((*dpMax_0).primal_0);
    }
    else
    {
        _S8 = false;
    }
    float _S9;
    if(_S8)
    {
        _S9 = dOut_3;
    }
    else
    {
        _S9 = 0.0f;
    }
    dpx_3->primal_0 = _S7.primal_0;
    dpx_3->differential_0 = _S9;
    DiffPair_float_0 _S10 = *dpMin_0;
    if((_S7.primal_0) < ((*dpMin_0).primal_0))
    {
        _S9 = dOut_3;
    }
    else
    {
        _S9 = 0.0f;
    }
    dpMin_0->primal_0 = _S10.primal_0;
    dpMin_0->differential_0 = _S9;
    DiffPair_float_0 _S11 = *dpMax_0;
    if(((*dpx_3).primal_0) > ((*dpMax_0).primal_0))
    {
        _S9 = dOut_3;
    }
    else
    {
        _S9 = 0.0f;
    }
    dpMax_0->primal_0 = _S11.primal_0;
    dpMax_0->differential_0 = _S9;
    return;
}

inline __device__ float clamp_0(float x_1, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_1), (minBound_0)))), (maxBound_0)));
}

inline __device__ void _d_abs_0(DiffPair_float_0 * dpx_4, float dOut_4)
{
    float _S12 = _slang_select(((*dpx_4).primal_0) > 0.0f, 1.0f,_slang_select(((*dpx_4).primal_0) == 0.0f, 0.0f,-1.0f)) * dOut_4;
    dpx_4->primal_0 = (*dpx_4).primal_0;
    dpx_4->differential_0 = _S12;
    return;
}

inline __device__ void _d_abs_vector_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_5, float3  dOut_5)
{
    float3  _S13 = _slang_select(((*dpx_5).primal_0) > make_float3 (0.0f), make_float3 (1.0f),_slang_select(((*dpx_5).primal_0) == make_float3 (0.0f), make_float3 (0.0f),make_float3 (-1.0f))) * dOut_5;
    dpx_5->primal_0 = (*dpx_5).primal_0;
    dpx_5->differential_0 = _S13;
    return;
}

inline __device__ float3  abs_0(float3  x_2)
{
    float3  result_2;
    int i_1 = int(0);
    for(;;)
    {
        if(i_1 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_2, i_1) = (F32_abs((_slang_vector_get_element(x_2, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_2;
}

inline __device__ void _d_sqrt_0(DiffPair_float_0 * dpx_6, float dOut_6)
{
    float _S14 = 0.5f / (F32_sqrt(((F32_max((1.00000001168609742e-07f), ((*dpx_6).primal_0)))))) * dOut_6;
    dpx_6->primal_0 = (*dpx_6).primal_0;
    dpx_6->differential_0 = _S14;
    return;
}

inline __device__ void _d_rsqrt_0(DiffPair_float_0 * dpx_7, float dOut_7)
{
    float _S15 = -0.5f / ((*dpx_7).primal_0 * (F32_sqrt(((*dpx_7).primal_0)))) * dOut_7;
    dpx_7->primal_0 = (*dpx_7).primal_0;
    dpx_7->differential_0 = _S15;
    return;
}

inline __device__ void _d_log_0(DiffPair_float_0 * dpx_8, float dOut_8)
{
    float _S16 = 1.0f / (*dpx_8).primal_0 * dOut_8;
    dpx_8->primal_0 = (*dpx_8).primal_0;
    dpx_8->differential_0 = _S16;
    return;
}

inline __device__ void _d_lerp_0(DiffPair_float_0 * dpx_9, DiffPair_float_0 * dpy_3, DiffPair_float_0 * dps_0, float dOut_9)
{
    float _S17 = (1.0f - (*dps_0).primal_0) * dOut_9;
    dpx_9->primal_0 = (*dpx_9).primal_0;
    dpx_9->differential_0 = _S17;
    DiffPair_float_0 _S18 = *dpy_3;
    float _S19 = (*dps_0).primal_0 * dOut_9;
    dpy_3->primal_0 = (*dpy_3).primal_0;
    dpy_3->differential_0 = _S19;
    float _S20 = (_S18.primal_0 - (*dpx_9).primal_0) * dOut_9;
    dps_0->primal_0 = _S18.primal_0;
    dps_0->differential_0 = _S20;
    return;
}

inline __device__ float lerp_0(float x_3, float y_1, float s_0)
{
    return x_3 + (y_1 - x_3) * s_0;
}

inline __device__ void per_pixel_losses(float3  render_rgb_0, float3  ref_rgb_0, float render_depth_0, float ref_depth_0, float3  render_normal_0, float3  depth_normal_0, float3  ref_normal_0, float render_Ts_0, float3  rgb_dist_0, float depth_dist_0, float3  normal_dist_0, float median_depth_0, float3  median_normal_0, bool ref_alpha_0, bool has_mask_0, float saturation_threshold_0, FixedArray<float, 20>  weights_0, FixedArray<float, 33>  * _S21)
{
    bool _S22;
    bool _S23;
    bool _S24;
    FixedArray<float, 33>  losses_0;
    bool mask_0;
    if(has_mask_0)
    {
        mask_0 = ref_alpha_0;
    }
    else
    {
        mask_0 = true;
    }
    bool normal_mask_0;
    if(saturation_threshold_0 > 0.0f)
    {
        normal_mask_0 = (F32_min(((F32_min((render_rgb_0.x), (render_rgb_0.y)))), (render_rgb_0.z))) > saturation_threshold_0;
    }
    else
    {
        normal_mask_0 = false;
    }
    if(normal_mask_0)
    {
        normal_mask_0 = (F32_min(((F32_min((ref_rgb_0.x), (ref_rgb_0.y)))), (ref_rgb_0.z))) > saturation_threshold_0;
    }
    else
    {
        normal_mask_0 = false;
    }
    if(normal_mask_0)
    {
        mask_0 = false;
    }
    bool depth_mask_0 = ref_depth_0 != 0.0f;
    if((ref_normal_0.x + ref_normal_0.y + ref_normal_0.z) > -2.36599993705749512f)
    {
        normal_mask_0 = (dot_0(ref_normal_0, ref_normal_0)) > 0.25f;
    }
    else
    {
        normal_mask_0 = false;
    }
    float3  _S25;
    float _S26 = render_rgb_0.x;
    float _S27 = render_rgb_0.y;
    float _S28 = render_rgb_0.z;
    float _S29 = ref_rgb_0.x;
    float _S30 = ref_rgb_0.y;
    float _S31 = ref_rgb_0.z;
    float Y_0 = 0.29899999499320984f * _S29 + 0.58700001239776611f * _S30 + 0.11400000005960464f * _S31;
    float dY_0 = 0.29899999499320984f * _S26 + 0.58700001239776611f * _S27 + 0.11400000005960464f * _S28 - Y_0;
    float dU_0 = -0.14712999761104584f * _S26 - 0.28885999321937561f * _S27 + 0.43599998950958252f * _S28 - (-0.14712999761104584f * _S29 - 0.28885999321937561f * _S30 + 0.43599998950958252f * _S31);
    float dV_0 = 0.61500000953674316f * _S26 - 0.51498997211456299f * _S27 - 0.10001000016927719f * _S28 - (0.61500000953674316f * _S29 - 0.51498997211456299f * _S30 - 0.10001000016927719f * _S31);
    float _S32 = float(mask_0);
    float _S33 = _S32 * (1.0f + weights_0[int(19)] * clamp_0(1.0f - Y_0, 0.0f, 1.0f));
    float3  _S34 = ref_rgb_0 - render_rgb_0;
    float3  _S35 = abs_0(_S34);
    float _S36 = dot_0(_S34, _S34) * 0.3333333432674408f;
    losses_0[int(0)] = _S33 * (weights_0[int(0)] * ((_S35.x + _S35.y + _S35.z) * 0.3333333432674408f) + weights_0[int(1)] * _S36 + weights_0[int(2)] * (F32_abs((dY_0))) + weights_0[int(3)] * dY_0 * dY_0 + weights_0[int(4)] * dU_0 * dU_0 + weights_0[int(5)] * dV_0 * dV_0);
    losses_0[int(1)] = _S32 * clamp_0(_S36, 0.0f, 1.0f);
    float _S37 = float(depth_mask_0 & mask_0);
    float _S38 = _S37 * (F32_max((render_depth_0), (0.00009999999747379f)));
    float _S39 = _S37 * (F32_max((ref_depth_0), (0.00009999999747379f)));
    losses_0[int(2)] = _S38;
    losses_0[int(3)] = _S39;
    losses_0[int(4)] = _S38 * _S38;
    losses_0[int(5)] = _S39 * _S39;
    losses_0[int(6)] = _S38 * _S39;
    bool _S40 = normal_mask_0 & mask_0;
    for(;;)
    {
        float norm2_0 = dot_0(render_normal_0, render_normal_0);
        bool _S41 = norm2_0 == 0.0f;
        _S22 = _S41;
        if(_S41)
        {
            _S25 = make_float3 (0.0f);
            break;
        }
        _S25 = render_normal_0 * make_float3 ((F32_rsqrt((norm2_0))));
        break;
    }
    float3  _S42;
    bool _S43 = !_S22;
    for(;;)
    {
        float norm2_1 = dot_0(depth_normal_0, depth_normal_0);
        bool _S44 = norm2_1 == 0.0f;
        _S23 = _S44;
        if(_S44)
        {
            _S42 = make_float3 (0.0f);
            break;
        }
        _S42 = depth_normal_0 * make_float3 ((F32_rsqrt((norm2_1))));
        break;
    }
    float3  _S45;
    bool _S46 = !_S23;
    for(;;)
    {
        float norm2_2 = dot_0(ref_normal_0, ref_normal_0);
        if(norm2_2 == 0.0f)
        {
            _S45 = make_float3 (0.0f);
            normal_mask_0 = false;
            break;
        }
        _S45 = ref_normal_0 * make_float3 ((F32_rsqrt((norm2_2))));
        normal_mask_0 = _S40;
        break;
    }
    float3  _S47;
    float _S48 = float(_S43 & normal_mask_0);
    float cos_sim_loss_0 = 0.5f - 0.5f * dot_0(_S25, _S45);
    losses_0[int(7)] = weights_0[int(7)] * _S48 * (cos_sim_loss_0 + (F32_sqrt(((F32_max((cos_sim_loss_0), (9.999999960041972e-13f)))))));
    float _S49 = float(_S46 & normal_mask_0);
    float cos_sim_loss_1 = 0.5f - 0.5f * dot_0(_S42, _S45);
    losses_0[int(8)] = weights_0[int(7)] * _S49 * (cos_sim_loss_1 + (F32_sqrt(((F32_max((cos_sim_loss_1), (9.999999960041972e-13f)))))));
    float _S50 = float((_S43 & _S46) & mask_0);
    float cos_sim_loss_2 = 0.5f - 0.5f * dot_0(_S25, _S42);
    losses_0[int(11)] = weights_0[int(10)] * _S50 * (cos_sim_loss_2 + (F32_sqrt(((F32_max((cos_sim_loss_2), (9.999999960041972e-13f)))))));
    for(;;)
    {
        float norm2_3 = dot_0(median_normal_0, median_normal_0);
        bool _S51 = norm2_3 == 0.0f;
        _S24 = _S51;
        if(_S51)
        {
            _S47 = make_float3 (0.0f);
            break;
        }
        _S47 = median_normal_0 * make_float3 ((F32_rsqrt((norm2_3))));
        break;
    }
    bool _S52 = !_S24;
    bool mean_median_mask_0;
    if(mask_0)
    {
        mean_median_mask_0 = render_depth_0 > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_0 = false;
    }
    if(mean_median_mask_0)
    {
        mean_median_mask_0 = median_depth_0 > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_0 = false;
    }
    float _S53 = float(mean_median_mask_0);
    losses_0[int(16)] = weights_0[int(15)] * _S53 * (F32_abs(((F32_log(((F32_max((render_depth_0), (1.00000001335143196e-10f)))))) - (F32_log(((F32_max((median_depth_0), (1.00000001335143196e-10f)))))))));
    float _S54 = float((_S52 & _S46) & mask_0);
    float cos_sim_loss_3 = 0.5f - 0.5f * dot_0(_S47, _S42);
    losses_0[int(17)] = weights_0[int(16)] * _S54 * (cos_sim_loss_3 + (F32_sqrt(((F32_max((cos_sim_loss_3), (9.999999960041972e-13f)))))));
    float _S55 = float(_S52 & normal_mask_0);
    float cos_sim_loss_4 = 0.5f - 0.5f * dot_0(_S47, _S45);
    losses_0[int(18)] = weights_0[int(17)] * _S55 * (cos_sim_loss_4 + (F32_sqrt(((F32_max((cos_sim_loss_4), (9.999999960041972e-13f)))))));
    float _S56 = float((_S52 & _S43) & mask_0);
    float cos_sim_loss_5 = 0.5f - 0.5f * dot_0(_S47, _S25);
    losses_0[int(19)] = weights_0[int(18)] * _S56 * (cos_sim_loss_5 + (F32_sqrt(((F32_max((cos_sim_loss_5), (9.999999960041972e-13f)))))));
    float render_alpha_0 = clamp_0(1.0f - render_Ts_0, 0.0f, 1.0f);
    float _S57 = float(has_mask_0);
    float _S58 = float(ref_alpha_0);
    float _S59 = (F32_max((render_alpha_0), (_S58)));
    losses_0[int(9)] = weights_0[int(8)] * _S57 * - lerp_0((F32_log(((F32_max((1.0f - _S59), (9.99999997475242708e-07f)))))), (F32_log(((F32_max((_S59), (9.99999997475242708e-07f)))))), _S58);
    float _S60 = 1.0f - render_alpha_0;
    float _S61 = 1.0f - _S58;
    float _S62 = (F32_max((_S60), (_S61)));
    losses_0[int(10)] = weights_0[int(9)] * _S57 * - lerp_0((F32_log(((F32_max((1.0f - _S62), (9.99999997475242708e-07f)))))), (F32_log(((F32_max((_S62), (9.99999997475242708e-07f)))))), _S61);
    losses_0[int(12)] = weights_0[int(11)] * _S32 * 4.0f * render_alpha_0 * _S60;
    losses_0[int(13)] = weights_0[int(12)] * _S32 * ((rgb_dist_0.x + rgb_dist_0.y + rgb_dist_0.z) * 0.3333333432674408f);
    losses_0[int(14)] = weights_0[int(13)] * _S32 * depth_dist_0;
    losses_0[int(15)] = weights_0[int(14)] * _S32 * ((normal_dist_0.x + normal_dist_0.y + normal_dist_0.z) * 0.3333333432674408f);
    losses_0[int(20)] = 1.0f;
    losses_0[int(21)] = _S32;
    losses_0[int(22)] = _S37;
    losses_0[int(23)] = _S48;
    losses_0[int(24)] = _S49;
    losses_0[int(25)] = _S50;
    if(has_mask_0)
    {
        mask_0 = !ref_alpha_0;
    }
    else
    {
        mask_0 = false;
    }
    losses_0[int(26)] = float(mask_0);
    if(has_mask_0)
    {
        mask_0 = ref_alpha_0;
    }
    else
    {
        mask_0 = false;
    }
    losses_0[int(27)] = float(mask_0);
    losses_0[int(28)] = _S53;
    losses_0[int(29)] = _S54;
    losses_0[int(30)] = _S55;
    losses_0[int(31)] = _S56;
    losses_0[int(32)] = _S33;
    *_S21 = losses_0;
    return;
}

inline __device__ float s_primal_ctx_dot_0(float3  _S63, float3  _S64)
{
    return dot_0(_S63, _S64);
}

inline __device__ float s_primal_ctx_clamp_0(float _S65, float _S66, float _S67)
{
    return clamp_0(_S65, _S66, _S67);
}

inline __device__ float s_primal_ctx_rsqrt_0(float _S68)
{
    return (F32_rsqrt((_S68)));
}

inline __device__ float s_primal_ctx_log_0(float _S69)
{
    return (F32_log((_S69)));
}

inline __device__ void s_bwd_prop_lerp_0(DiffPair_float_0 * _S70, DiffPair_float_0 * _S71, DiffPair_float_0 * _S72, float _S73)
{
    _d_lerp_0(_S70, _S71, _S72, _S73);
    return;
}

inline __device__ void s_bwd_prop_log_0(DiffPair_float_0 * _S74, float _S75)
{
    _d_log_0(_S74, _S75);
    return;
}

inline __device__ void s_bwd_prop_clamp_0(DiffPair_float_0 * _S76, DiffPair_float_0 * _S77, DiffPair_float_0 * _S78, float _S79)
{
    _d_clamp_0(_S76, _S77, _S78, _S79);
    return;
}

inline __device__ void s_bwd_prop_sqrt_0(DiffPair_float_0 * _S80, float _S81)
{
    _d_sqrt_0(_S80, _S81);
    return;
}

inline __device__ void s_bwd_prop_dot_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S82, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S83, float _S84)
{
    _d_dot_0(_S82, _S83, _S84);
    return;
}

inline __device__ void s_bwd_prop_abs_0(DiffPair_float_0 * _S85, float _S86)
{
    _d_abs_0(_S85, _S86);
    return;
}

inline __device__ void s_bwd_prop_rsqrt_0(DiffPair_float_0 * _S87, float _S88)
{
    _d_rsqrt_0(_S87, _S88);
    return;
}

inline __device__ void s_bwd_prop_abs_1(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S89, float3  _S90)
{
    _d_abs_vector_0(_S89, _S90);
    return;
}

inline __device__ void s_bwd_prop_per_pixel_losses_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dprender_rgb_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpref_rgb_0, DiffPair_float_0 * dprender_depth_0, DiffPair_float_0 * dpref_depth_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dprender_normal_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpdepth_normal_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpref_normal_0, DiffPair_float_0 * dprender_Ts_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dprgb_dist_0, DiffPair_float_0 * dpdepth_dist_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpnormal_dist_0, DiffPair_float_0 * dpmedian_depth_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpmedian_normal_0, bool ref_alpha_1, bool has_mask_1, float saturation_threshold_1, FixedArray<float, 20>  * weights_1, FixedArray<float, 33>  * _s_dOut_0)
{
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S91 = *dprender_rgb_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S92 = *dpref_rgb_0;
    DiffPair_float_0 _S93 = *dprender_depth_0;
    DiffPair_float_0 _S94 = *dpref_depth_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S95 = *dprender_normal_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S96 = *dpdepth_normal_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S97 = *dpref_normal_0;
    DiffPair_float_0 _S98 = *dprender_Ts_0;
    DiffPair_float_0 _S99 = *dpmedian_depth_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S100 = *dpmedian_normal_0;
    float3  _S101 = make_float3 (0.0f);
    bool mask_1;
    if(has_mask_1)
    {
        mask_1 = ref_alpha_1;
    }
    else
    {
        mask_1 = true;
    }
    bool _S102 = saturation_threshold_1 > 0.0f;
    bool _S103;
    float _S104;
    float _S105;
    float _S106;
    float _S107;
    if(_S102)
    {
        float _S108 = _S91.primal_0.x;
        float _S109 = _S91.primal_0.y;
        float _S110 = (F32_min((_S108), (_S109)));
        float _S111 = _S91.primal_0.z;
        _S103 = (F32_min((_S110), (_S111))) > saturation_threshold_1;
        _S104 = _S110;
        _S105 = _S111;
        _S106 = _S108;
        _S107 = _S109;
    }
    else
    {
        _S103 = false;
        _S104 = 0.0f;
        _S105 = 0.0f;
        _S106 = 0.0f;
        _S107 = 0.0f;
    }
    bool normal_mask_1;
    float _S112;
    float _S113;
    float _S114;
    float _S115;
    if(_S103)
    {
        float _S116 = _S92.primal_0.x;
        float _S117 = _S92.primal_0.y;
        float _S118 = (F32_min((_S116), (_S117)));
        float _S119 = _S92.primal_0.z;
        normal_mask_1 = (F32_min((_S118), (_S119))) > saturation_threshold_1;
        _S112 = _S118;
        _S113 = _S119;
        _S114 = _S116;
        _S115 = _S117;
    }
    else
    {
        normal_mask_1 = false;
        _S112 = 0.0f;
        _S113 = 0.0f;
        _S114 = 0.0f;
        _S115 = 0.0f;
    }
    if(normal_mask_1)
    {
        mask_1 = false;
    }
    bool depth_mask_1 = (_S94.primal_0) != 0.0f;
    bool _S120 = (_S97.primal_0.x + _S97.primal_0.y + _S97.primal_0.z) > -2.36599993705749512f;
    if(_S120)
    {
        normal_mask_1 = (s_primal_ctx_dot_0(_S97.primal_0, _S97.primal_0)) > 0.25f;
    }
    else
    {
        normal_mask_1 = false;
    }
    float _S121 = _S91.primal_0.x;
    float _S122 = _S91.primal_0.y;
    float _S123 = _S91.primal_0.z;
    float _S124 = _S92.primal_0.x;
    float _S125 = _S92.primal_0.y;
    float _S126 = _S92.primal_0.z;
    float Y_1 = 0.29899999499320984f * _S124 + 0.58700001239776611f * _S125 + 0.11400000005960464f * _S126;
    float dY_1 = 0.29899999499320984f * _S121 + 0.58700001239776611f * _S122 + 0.11400000005960464f * _S123 - Y_1;
    float dU_1 = -0.14712999761104584f * _S121 - 0.28885999321937561f * _S122 + 0.43599998950958252f * _S123 - (-0.14712999761104584f * _S124 - 0.28885999321937561f * _S125 + 0.43599998950958252f * _S126);
    float dV_1 = 0.61500000953674316f * _S121 - 0.51498997211456299f * _S122 - 0.10001000016927719f * _S123 - (0.61500000953674316f * _S124 - 0.51498997211456299f * _S125 - 0.10001000016927719f * _S126);
    float _S127 = float(mask_1);
    float _S128 = _S127 * (1.0f + (*weights_1)[int(19)] * s_primal_ctx_clamp_0(1.0f - Y_1, 0.0f, 1.0f));
    float _S129 = (*weights_1)[int(0)];
    float3  _S130 = _S92.primal_0 - _S91.primal_0;
    float _S131 = (*weights_1)[int(1)];
    float _S132 = s_primal_ctx_dot_0(_S130, _S130) * 0.3333333432674408f;
    float _S133 = (*weights_1)[int(2)];
    float _S134 = (*weights_1)[int(3)];
    float _S135 = (*weights_1)[int(3)] * dY_1;
    float _S136 = (*weights_1)[int(4)];
    float _S137 = (*weights_1)[int(4)] * dU_1;
    float _S138 = (*weights_1)[int(5)];
    float _S139 = (*weights_1)[int(5)] * dV_1;
    float _S140 = float(depth_mask_1 & mask_1);
    float _S141 = _S140 * (F32_max((_S93.primal_0), (0.00009999999747379f)));
    float _S142 = _S140 * (F32_max((_S94.primal_0), (0.00009999999747379f)));
    bool _S143 = normal_mask_1 & mask_1;
    float _S144 = s_primal_ctx_dot_0(_S95.primal_0, _S95.primal_0);
    bool _S145 = _S144 == 0.0f;
    float3  _S146;
    if(_S145)
    {
        _S146 = make_float3 (0.0f);
    }
    bool _S147 = !_S145;
    float3  _S148;
    if(_S147)
    {
        float _S149 = s_primal_ctx_rsqrt_0(_S144);
        float3  _S150 = make_float3 (_S149);
        _S146 = _S95.primal_0 * make_float3 (_S149);
        _S148 = _S150;
    }
    else
    {
        _S148 = _S101;
    }
    float _S151 = s_primal_ctx_dot_0(_S96.primal_0, _S96.primal_0);
    bool _S152 = _S151 == 0.0f;
    float3  _S153;
    if(_S152)
    {
        _S153 = make_float3 (0.0f);
    }
    bool _S154 = !_S152;
    float3  _S155;
    if(_S154)
    {
        float _S156 = s_primal_ctx_rsqrt_0(_S151);
        float3  _S157 = make_float3 (_S156);
        _S153 = _S96.primal_0 * make_float3 (_S156);
        _S155 = _S157;
    }
    else
    {
        _S155 = _S101;
    }
    float _S158 = s_primal_ctx_dot_0(_S97.primal_0, _S97.primal_0);
    bool _S159 = _S158 == 0.0f;
    float3  _S160;
    if(_S159)
    {
        float3  _S161 = make_float3 (0.0f);
        normal_mask_1 = false;
        _S160 = _S161;
    }
    else
    {
        normal_mask_1 = _S143;
    }
    bool _S162 = !_S159;
    float3  _S163;
    if(_S162)
    {
        float _S164 = s_primal_ctx_rsqrt_0(_S158);
        float3  _S165 = make_float3 (_S164);
        _S160 = _S97.primal_0 * make_float3 (_S164);
        _S163 = _S165;
    }
    else
    {
        _S163 = _S101;
    }
    float _S166 = (*weights_1)[int(7)] * float(_S147 & normal_mask_1);
    float cos_sim_loss_6 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S146, _S160);
    float _S167 = (F32_max((cos_sim_loss_6), (9.999999960041972e-13f)));
    float _S168 = (*weights_1)[int(7)] * float(_S154 & normal_mask_1);
    float cos_sim_loss_7 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S153, _S160);
    float _S169 = (F32_max((cos_sim_loss_7), (9.999999960041972e-13f)));
    float _S170 = (*weights_1)[int(10)] * float((_S147 & _S154) & mask_1);
    float cos_sim_loss_8 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S146, _S153);
    float _S171 = (F32_max((cos_sim_loss_8), (9.999999960041972e-13f)));
    float _S172 = s_primal_ctx_dot_0(_S100.primal_0, _S100.primal_0);
    bool _S173 = _S172 == 0.0f;
    float3  _S174;
    if(_S173)
    {
        _S174 = make_float3 (0.0f);
    }
    bool _S175 = !_S173;
    float3  _S176;
    if(_S175)
    {
        float _S177 = s_primal_ctx_rsqrt_0(_S172);
        float3  _S178 = make_float3 (_S177);
        _S174 = _S100.primal_0 * make_float3 (_S177);
        _S176 = _S178;
    }
    else
    {
        _S176 = _S101;
    }
    bool mean_median_mask_1;
    if(mask_1)
    {
        mean_median_mask_1 = (_S93.primal_0) > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_1 = false;
    }
    if(mean_median_mask_1)
    {
        mean_median_mask_1 = (_S99.primal_0) > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_1 = false;
    }
    float _S179 = (*weights_1)[int(15)] * float(mean_median_mask_1);
    float _S180 = (F32_max((_S93.primal_0), (1.00000001335143196e-10f)));
    float _S181 = (F32_max((_S99.primal_0), (1.00000001335143196e-10f)));
    float _S182 = s_primal_ctx_log_0(_S180) - s_primal_ctx_log_0(_S181);
    float _S183 = (*weights_1)[int(16)] * float((_S175 & _S154) & mask_1);
    float cos_sim_loss_9 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S174, _S153);
    float _S184 = (F32_max((cos_sim_loss_9), (9.999999960041972e-13f)));
    float _S185 = (*weights_1)[int(17)] * float(_S175 & normal_mask_1);
    float cos_sim_loss_10 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S174, _S160);
    float _S186 = (F32_max((cos_sim_loss_10), (9.999999960041972e-13f)));
    float _S187 = (*weights_1)[int(18)] * float((_S175 & _S147) & mask_1);
    float cos_sim_loss_11 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S174, _S146);
    float _S188 = (F32_max((cos_sim_loss_11), (9.999999960041972e-13f)));
    float _S189 = 1.0f - _S98.primal_0;
    float _S190 = s_primal_ctx_clamp_0(_S189, 0.0f, 1.0f);
    float _S191 = float(has_mask_1);
    float _S192 = (*weights_1)[int(8)] * _S191;
    float _S193 = float(ref_alpha_1);
    float _S194 = (F32_max((_S190), (_S193)));
    float _S195 = 1.0f - _S194;
    float _S196 = (F32_max((_S195), (9.99999997475242708e-07f)));
    float _S197 = s_primal_ctx_log_0(_S196);
    float _S198 = (F32_max((_S194), (9.99999997475242708e-07f)));
    float _S199 = s_primal_ctx_log_0(_S198);
    float _S200 = (*weights_1)[int(9)] * _S191;
    float _S201 = 1.0f - _S190;
    float _S202 = 1.0f - _S193;
    float _S203 = (F32_max((_S201), (_S202)));
    float _S204 = 1.0f - _S203;
    float _S205 = (F32_max((_S204), (9.99999997475242708e-07f)));
    float _S206 = s_primal_ctx_log_0(_S205);
    float _S207 = (F32_max((_S203), (9.99999997475242708e-07f)));
    float _S208 = s_primal_ctx_log_0(_S207);
    float _S209 = (*weights_1)[int(11)] * _S127 * 4.0f;
    float _S210 = _S209 * _S190;
    float _S211 = (*weights_1)[int(12)] * _S127;
    float _S212 = (*weights_1)[int(13)] * _S127;
    float _S213 = (*weights_1)[int(14)] * _S127;
    float _S214 = (*_s_dOut_0)[int(0)];
    float _S215 = (*_s_dOut_0)[int(1)];
    float _S216 = (*_s_dOut_0)[int(2)];
    float _S217 = (*_s_dOut_0)[int(3)];
    float _S218 = (*_s_dOut_0)[int(4)];
    float _S219 = (*_s_dOut_0)[int(5)];
    float _S220 = (*_s_dOut_0)[int(6)];
    float _S221 = (*_s_dOut_0)[int(7)];
    float _S222 = (*_s_dOut_0)[int(8)];
    float _S223 = (*_s_dOut_0)[int(11)];
    float _S224 = 0.3333333432674408f * (_S213 * (*_s_dOut_0)[int(15)]);
    float _S225 = _S212 * (*_s_dOut_0)[int(14)];
    float _S226 = 0.3333333432674408f * (_S211 * (*_s_dOut_0)[int(13)]);
    float _S227 = _S210 * (*_s_dOut_0)[int(12)];
    float _S228 = _S209 * (_S201 * (*_s_dOut_0)[int(12)]);
    float _S229 = - (_S200 * (*_s_dOut_0)[int(10)]);
    DiffPair_float_0 _S230;
    (&_S230)->primal_0 = _S206;
    (&_S230)->differential_0 = 0.0f;
    DiffPair_float_0 _S231;
    (&_S231)->primal_0 = _S208;
    (&_S231)->differential_0 = 0.0f;
    DiffPair_float_0 _S232;
    (&_S232)->primal_0 = _S202;
    (&_S232)->differential_0 = 0.0f;
    s_bwd_prop_lerp_0(&_S230, &_S231, &_S232, _S229);
    DiffPair_float_0 _S233;
    (&_S233)->primal_0 = _S207;
    (&_S233)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S233, _S231.differential_0);
    DiffPair_float_0 _S234;
    (&_S234)->primal_0 = _S203;
    (&_S234)->differential_0 = 0.0f;
    DiffPair_float_0 _S235;
    (&_S235)->primal_0 = 9.99999997475242708e-07f;
    (&_S235)->differential_0 = 0.0f;
    _d_max_0(&_S234, &_S235, _S233.differential_0);
    DiffPair_float_0 _S236;
    (&_S236)->primal_0 = _S205;
    (&_S236)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S236, _S230.differential_0);
    DiffPair_float_0 _S237;
    (&_S237)->primal_0 = _S204;
    (&_S237)->differential_0 = 0.0f;
    DiffPair_float_0 _S238;
    (&_S238)->primal_0 = 9.99999997475242708e-07f;
    (&_S238)->differential_0 = 0.0f;
    _d_max_0(&_S237, &_S238, _S236.differential_0);
    float _S239 = _S234.differential_0 + - _S237.differential_0;
    DiffPair_float_0 _S240;
    (&_S240)->primal_0 = _S201;
    (&_S240)->differential_0 = 0.0f;
    DiffPair_float_0 _S241;
    (&_S241)->primal_0 = _S202;
    (&_S241)->differential_0 = 0.0f;
    _d_max_0(&_S240, &_S241, _S239);
    float _S242 = - (_S227 + _S240.differential_0);
    float _S243 = - (_S192 * (*_s_dOut_0)[int(9)]);
    DiffPair_float_0 _S244;
    (&_S244)->primal_0 = _S197;
    (&_S244)->differential_0 = 0.0f;
    DiffPair_float_0 _S245;
    (&_S245)->primal_0 = _S199;
    (&_S245)->differential_0 = 0.0f;
    DiffPair_float_0 _S246;
    (&_S246)->primal_0 = _S193;
    (&_S246)->differential_0 = 0.0f;
    s_bwd_prop_lerp_0(&_S244, &_S245, &_S246, _S243);
    DiffPair_float_0 _S247;
    (&_S247)->primal_0 = _S198;
    (&_S247)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S247, _S245.differential_0);
    DiffPair_float_0 _S248;
    (&_S248)->primal_0 = _S194;
    (&_S248)->differential_0 = 0.0f;
    DiffPair_float_0 _S249;
    (&_S249)->primal_0 = 9.99999997475242708e-07f;
    (&_S249)->differential_0 = 0.0f;
    _d_max_0(&_S248, &_S249, _S247.differential_0);
    DiffPair_float_0 _S250;
    (&_S250)->primal_0 = _S196;
    (&_S250)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S250, _S244.differential_0);
    DiffPair_float_0 _S251;
    (&_S251)->primal_0 = _S195;
    (&_S251)->differential_0 = 0.0f;
    DiffPair_float_0 _S252;
    (&_S252)->primal_0 = 9.99999997475242708e-07f;
    (&_S252)->differential_0 = 0.0f;
    _d_max_0(&_S251, &_S252, _S250.differential_0);
    float _S253 = _S248.differential_0 + - _S251.differential_0;
    DiffPair_float_0 _S254;
    (&_S254)->primal_0 = _S190;
    (&_S254)->differential_0 = 0.0f;
    DiffPair_float_0 _S255;
    (&_S255)->primal_0 = _S193;
    (&_S255)->differential_0 = 0.0f;
    _d_max_0(&_S254, &_S255, _S253);
    float _S256 = _S228 + _S242 + _S254.differential_0;
    DiffPair_float_0 _S257;
    (&_S257)->primal_0 = _S189;
    (&_S257)->differential_0 = 0.0f;
    DiffPair_float_0 _S258;
    (&_S258)->primal_0 = 0.0f;
    (&_S258)->differential_0 = 0.0f;
    DiffPair_float_0 _S259;
    (&_S259)->primal_0 = 1.0f;
    (&_S259)->differential_0 = 0.0f;
    s_bwd_prop_clamp_0(&_S257, &_S258, &_S259, _S256);
    float _S260 = - _S257.differential_0;
    float _S261 = _S187 * (*_s_dOut_0)[int(19)];
    DiffPair_float_0 _S262;
    (&_S262)->primal_0 = _S188;
    (&_S262)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S262, _S261);
    DiffPair_float_0 _S263;
    (&_S263)->primal_0 = cos_sim_loss_11;
    (&_S263)->differential_0 = 0.0f;
    DiffPair_float_0 _S264;
    (&_S264)->primal_0 = 9.999999960041972e-13f;
    (&_S264)->differential_0 = 0.0f;
    _d_max_0(&_S263, &_S264, _S262.differential_0);
    float _S265 = 0.5f * - (_S261 + _S263.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S266;
    (&_S266)->primal_0 = _S174;
    (&_S266)->differential_0 = _S101;
    float3  _S267 = _S146;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S268;
    (&_S268)->primal_0 = _S146;
    (&_S268)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S266, &_S268, _S265);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S269 = _S268;
    float _S270 = _S185 * (*_s_dOut_0)[int(18)];
    DiffPair_float_0 _S271;
    (&_S271)->primal_0 = _S186;
    (&_S271)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S271, _S270);
    DiffPair_float_0 _S272;
    (&_S272)->primal_0 = cos_sim_loss_10;
    (&_S272)->differential_0 = 0.0f;
    DiffPair_float_0 _S273;
    (&_S273)->primal_0 = 9.999999960041972e-13f;
    (&_S273)->differential_0 = 0.0f;
    _d_max_0(&_S272, &_S273, _S271.differential_0);
    float _S274 = 0.5f * - (_S270 + _S272.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S275;
    (&_S275)->primal_0 = _S174;
    (&_S275)->differential_0 = _S101;
    float3  _S276 = _S160;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S277;
    (&_S277)->primal_0 = _S160;
    (&_S277)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S275, &_S277, _S274);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S278 = _S277;
    float _S279 = _S183 * (*_s_dOut_0)[int(17)];
    DiffPair_float_0 _S280;
    (&_S280)->primal_0 = _S184;
    (&_S280)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S280, _S279);
    DiffPair_float_0 _S281;
    (&_S281)->primal_0 = cos_sim_loss_9;
    (&_S281)->differential_0 = 0.0f;
    DiffPair_float_0 _S282;
    (&_S282)->primal_0 = 9.999999960041972e-13f;
    (&_S282)->differential_0 = 0.0f;
    _d_max_0(&_S281, &_S282, _S280.differential_0);
    float _S283 = 0.5f * - (_S279 + _S281.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S284;
    (&_S284)->primal_0 = _S174;
    (&_S284)->differential_0 = _S101;
    float3  _S285 = _S153;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S286;
    (&_S286)->primal_0 = _S153;
    (&_S286)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S284, &_S286, _S283);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S287 = _S286;
    float _S288 = _S179 * (*_s_dOut_0)[int(16)];
    DiffPair_float_0 _S289;
    (&_S289)->primal_0 = _S182;
    (&_S289)->differential_0 = 0.0f;
    s_bwd_prop_abs_0(&_S289, _S288);
    float _S290 = - _S289.differential_0;
    DiffPair_float_0 _S291;
    (&_S291)->primal_0 = _S181;
    (&_S291)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S291, _S290);
    DiffPair_float_0 _S292;
    (&_S292)->primal_0 = _S99.primal_0;
    (&_S292)->differential_0 = 0.0f;
    DiffPair_float_0 _S293;
    (&_S293)->primal_0 = 1.00000001335143196e-10f;
    (&_S293)->differential_0 = 0.0f;
    _d_max_0(&_S292, &_S293, _S291.differential_0);
    DiffPair_float_0 _S294 = _S292;
    DiffPair_float_0 _S295;
    (&_S295)->primal_0 = _S180;
    (&_S295)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S295, _S289.differential_0);
    DiffPair_float_0 _S296;
    (&_S296)->primal_0 = _S93.primal_0;
    (&_S296)->differential_0 = 0.0f;
    DiffPair_float_0 _S297;
    (&_S297)->primal_0 = 1.00000001335143196e-10f;
    (&_S297)->differential_0 = 0.0f;
    _d_max_0(&_S296, &_S297, _S295.differential_0);
    DiffPair_float_0 _S298 = _S296;
    float3  _S299 = make_float3 (_S224, _S224, _S224);
    float3  _S300 = make_float3 (_S226, _S226, _S226);
    float3  _S301 = _S266.differential_0 + _S275.differential_0 + _S284.differential_0;
    float _S302;
    if(_S175)
    {
        float3  _S303 = _S100.primal_0 * _S301;
        float3  _S304 = _S176 * _S301;
        float _S305 = _S303.x + _S303.y + _S303.z;
        DiffPair_float_0 _S306;
        (&_S306)->primal_0 = _S172;
        (&_S306)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S306, _S305);
        _S302 = _S306.differential_0;
        _S146 = _S304;
    }
    else
    {
        _S302 = 0.0f;
        _S146 = _S101;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S307;
    (&_S307)->primal_0 = _S100.primal_0;
    (&_S307)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S308;
    (&_S308)->primal_0 = _S100.primal_0;
    (&_S308)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S307, &_S308, _S302);
    float _S309 = _S170 * _S223;
    DiffPair_float_0 _S310;
    (&_S310)->primal_0 = _S171;
    (&_S310)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S310, _S309);
    DiffPair_float_0 _S311;
    (&_S311)->primal_0 = cos_sim_loss_8;
    (&_S311)->differential_0 = 0.0f;
    DiffPair_float_0 _S312;
    (&_S312)->primal_0 = 9.999999960041972e-13f;
    (&_S312)->differential_0 = 0.0f;
    _d_max_0(&_S311, &_S312, _S310.differential_0);
    float _S313 = 0.5f * - (_S309 + _S311.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S314;
    (&_S314)->primal_0 = _S267;
    (&_S314)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S315;
    (&_S315)->primal_0 = _S285;
    (&_S315)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S314, &_S315, _S313);
    float _S316 = _S168 * _S222;
    DiffPair_float_0 _S317;
    (&_S317)->primal_0 = _S169;
    (&_S317)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S317, _S316);
    DiffPair_float_0 _S318;
    (&_S318)->primal_0 = cos_sim_loss_7;
    (&_S318)->differential_0 = 0.0f;
    DiffPair_float_0 _S319;
    (&_S319)->primal_0 = 9.999999960041972e-13f;
    (&_S319)->differential_0 = 0.0f;
    _d_max_0(&_S318, &_S319, _S317.differential_0);
    float _S320 = 0.5f * - (_S316 + _S318.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S321;
    (&_S321)->primal_0 = _S285;
    (&_S321)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S322;
    (&_S322)->primal_0 = _S276;
    (&_S322)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S321, &_S322, _S320);
    float _S323 = _S166 * _S221;
    DiffPair_float_0 _S324;
    (&_S324)->primal_0 = _S167;
    (&_S324)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S324, _S323);
    DiffPair_float_0 _S325;
    (&_S325)->primal_0 = cos_sim_loss_6;
    (&_S325)->differential_0 = 0.0f;
    DiffPair_float_0 _S326;
    (&_S326)->primal_0 = 9.999999960041972e-13f;
    (&_S326)->differential_0 = 0.0f;
    _d_max_0(&_S325, &_S326, _S324.differential_0);
    float _S327 = 0.5f * - (_S323 + _S325.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S328;
    (&_S328)->primal_0 = _S267;
    (&_S328)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S329;
    (&_S329)->primal_0 = _S276;
    (&_S329)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S328, &_S329, _S327);
    float3  _S330 = _S308.differential_0 + _S307.differential_0 + _S146;
    float3  _S331 = _S315.differential_0 + _S321.differential_0 + _S287.differential_0;
    float3  _S332 = _S314.differential_0 + _S328.differential_0 + _S269.differential_0;
    float3  _S333 = _S322.differential_0 + _S329.differential_0 + _S278.differential_0;
    if(_S162)
    {
        float3  _S334 = _S97.primal_0 * _S333;
        float3  _S335 = _S163 * _S333;
        float _S336 = _S334.x + _S334.y + _S334.z;
        DiffPair_float_0 _S337;
        (&_S337)->primal_0 = _S158;
        (&_S337)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S337, _S336);
        _S302 = _S337.differential_0;
        _S146 = _S335;
    }
    else
    {
        _S302 = 0.0f;
        _S146 = _S101;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S338;
    (&_S338)->primal_0 = _S97.primal_0;
    (&_S338)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S339;
    (&_S339)->primal_0 = _S97.primal_0;
    (&_S339)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S338, &_S339, _S302);
    float3  _S340 = _S339.differential_0 + _S338.differential_0 + _S146;
    if(_S154)
    {
        float3  _S341 = _S96.primal_0 * _S331;
        float3  _S342 = _S155 * _S331;
        float _S343 = _S341.x + _S341.y + _S341.z;
        DiffPair_float_0 _S344;
        (&_S344)->primal_0 = _S151;
        (&_S344)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S344, _S343);
        _S302 = _S344.differential_0;
        _S146 = _S342;
    }
    else
    {
        _S302 = 0.0f;
        _S146 = _S101;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S345;
    (&_S345)->primal_0 = _S96.primal_0;
    (&_S345)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S346;
    (&_S346)->primal_0 = _S96.primal_0;
    (&_S346)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S345, &_S346, _S302);
    float3  _S347 = _S346.differential_0 + _S345.differential_0 + _S146;
    if(_S147)
    {
        float3  _S348 = _S95.primal_0 * _S332;
        float3  _S349 = _S148 * _S332;
        float _S350 = _S348.x + _S348.y + _S348.z;
        DiffPair_float_0 _S351;
        (&_S351)->primal_0 = _S144;
        (&_S351)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S351, _S350);
        _S302 = _S351.differential_0;
        _S146 = _S349;
    }
    else
    {
        _S302 = 0.0f;
        _S146 = _S101;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S352;
    (&_S352)->primal_0 = _S95.primal_0;
    (&_S352)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S353;
    (&_S353)->primal_0 = _S95.primal_0;
    (&_S353)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S352, &_S353, _S302);
    float3  _S354 = _S353.differential_0 + _S352.differential_0 + _S146;
    float _S355 = _S142 * _S220;
    float _S356 = _S142 * _S219;
    float _S357 = _S141 * _S218;
    float _S358 = _S140 * (_S141 * _S220 + _S356 + _S356 + _S217);
    DiffPair_float_0 _S359;
    (&_S359)->primal_0 = _S94.primal_0;
    (&_S359)->differential_0 = 0.0f;
    DiffPair_float_0 _S360;
    (&_S360)->primal_0 = 0.00009999999747379f;
    (&_S360)->differential_0 = 0.0f;
    _d_max_0(&_S359, &_S360, _S358);
    DiffPair_float_0 _S361 = _S359;
    float _S362 = _S140 * (_S355 + _S357 + _S357 + _S216);
    DiffPair_float_0 _S363;
    (&_S363)->primal_0 = _S93.primal_0;
    (&_S363)->differential_0 = 0.0f;
    DiffPair_float_0 _S364;
    (&_S364)->primal_0 = 0.00009999999747379f;
    (&_S364)->differential_0 = 0.0f;
    _d_max_0(&_S363, &_S364, _S362);
    float _S365 = _S127 * _S215;
    DiffPair_float_0 _S366;
    (&_S366)->primal_0 = _S132;
    (&_S366)->differential_0 = 0.0f;
    DiffPair_float_0 _S367;
    (&_S367)->primal_0 = 0.0f;
    (&_S367)->differential_0 = 0.0f;
    DiffPair_float_0 _S368;
    (&_S368)->primal_0 = 1.0f;
    (&_S368)->differential_0 = 0.0f;
    s_bwd_prop_clamp_0(&_S366, &_S367, &_S368, _S365);
    float _S369 = _S128 * _S214;
    float _S370 = _S139 * _S369;
    float _S371 = _S138 * (dV_1 * _S369);
    float _S372 = _S137 * _S369;
    float _S373 = _S136 * (dU_1 * _S369);
    float _S374 = _S135 * _S369;
    float _S375 = _S134 * (dY_1 * _S369);
    float _S376 = _S133 * _S369;
    DiffPair_float_0 _S377;
    (&_S377)->primal_0 = dY_1;
    (&_S377)->differential_0 = 0.0f;
    s_bwd_prop_abs_0(&_S377, _S376);
    float _S378 = 0.3333333432674408f * (_S366.differential_0 + _S131 * _S369);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S379;
    (&_S379)->primal_0 = _S130;
    (&_S379)->differential_0 = _S101;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S380;
    (&_S380)->primal_0 = _S130;
    (&_S380)->differential_0 = _S101;
    s_bwd_prop_dot_0(&_S379, &_S380, _S378);
    float _S381 = 0.3333333432674408f * (_S129 * _S369);
    float3  _S382 = make_float3 (_S381, _S381, _S381);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S383;
    (&_S383)->primal_0 = _S130;
    (&_S383)->differential_0 = _S101;
    s_bwd_prop_abs_1(&_S383, _S382);
    float3  _S384 = _S380.differential_0 + _S379.differential_0 + _S383.differential_0;
    float _S385 = _S370 + _S371;
    float s_diff_V_T_0 = - _S385;
    float _S386 = _S372 + _S373;
    float s_diff_U_T_0 = - _S386;
    float _S387 = _S374 + _S375 + _S377.differential_0;
    float s_diff_Y_T_0 = - _S387;
    float _S388 = - s_diff_V_T_0;
    float _S389 = _S363.differential_0 + _S298.differential_0;
    float3  _S390 = _S384 + make_float3 (0.61500000953674316f * s_diff_V_T_0 + -0.14712999761104584f * s_diff_U_T_0 + 0.29899999499320984f * s_diff_Y_T_0, 0.51498997211456299f * _S388 + 0.28885999321937561f * - s_diff_U_T_0 + 0.58700001239776611f * s_diff_Y_T_0, 0.10001000016927719f * _S388 + 0.43599998950958252f * s_diff_U_T_0 + 0.11400000005960464f * s_diff_Y_T_0);
    float3  _S391 = - _S384 + make_float3 (0.61500000953674316f * _S385 + -0.14712999761104584f * _S386 + 0.29899999499320984f * _S387, 0.51498997211456299f * s_diff_V_T_0 + 0.28885999321937561f * s_diff_U_T_0 + 0.58700001239776611f * _S387, 0.10001000016927719f * s_diff_V_T_0 + 0.43599998950958252f * _S386 + 0.11400000005960464f * _S387);
    if(_S120)
    {
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S392;
        (&_S392)->primal_0 = _S97.primal_0;
        (&_S392)->differential_0 = _S101;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S393;
        (&_S393)->primal_0 = _S97.primal_0;
        (&_S393)->differential_0 = _S101;
        s_bwd_prop_dot_0(&_S392, &_S393, 0.0f);
        _S146 = _S393.differential_0 + _S392.differential_0 + _S340;
    }
    else
    {
        _S146 = _S340;
    }
    if(_S103)
    {
        DiffPair_float_0 _S394;
        (&_S394)->primal_0 = _S112;
        (&_S394)->differential_0 = 0.0f;
        DiffPair_float_0 _S395;
        (&_S395)->primal_0 = _S113;
        (&_S395)->differential_0 = 0.0f;
        _d_min_0(&_S394, &_S395, 0.0f);
        DiffPair_float_0 _S396;
        (&_S396)->primal_0 = _S114;
        (&_S396)->differential_0 = 0.0f;
        DiffPair_float_0 _S397;
        (&_S397)->primal_0 = _S115;
        (&_S397)->differential_0 = 0.0f;
        _d_min_0(&_S396, &_S397, _S394.differential_0);
        _S148 = _S390 + make_float3 (_S396.differential_0, _S397.differential_0, _S395.differential_0);
    }
    else
    {
        _S148 = _S390;
    }
    if(_S102)
    {
        DiffPair_float_0 _S398;
        (&_S398)->primal_0 = _S104;
        (&_S398)->differential_0 = 0.0f;
        DiffPair_float_0 _S399;
        (&_S399)->primal_0 = _S105;
        (&_S399)->differential_0 = 0.0f;
        _d_min_0(&_S398, &_S399, 0.0f);
        DiffPair_float_0 _S400;
        (&_S400)->primal_0 = _S106;
        (&_S400)->differential_0 = 0.0f;
        DiffPair_float_0 _S401;
        (&_S401)->primal_0 = _S107;
        (&_S401)->differential_0 = 0.0f;
        _d_min_0(&_S400, &_S401, _S398.differential_0);
        _S153 = _S391 + make_float3 (_S400.differential_0, _S401.differential_0, _S399.differential_0);
    }
    else
    {
        _S153 = _S391;
    }
    dpmedian_normal_0->primal_0 = (*dpmedian_normal_0).primal_0;
    dpmedian_normal_0->differential_0 = _S330;
    dpmedian_depth_0->primal_0 = (*dpmedian_depth_0).primal_0;
    dpmedian_depth_0->differential_0 = _S294.differential_0;
    dpnormal_dist_0->primal_0 = (*dpnormal_dist_0).primal_0;
    dpnormal_dist_0->differential_0 = _S299;
    dpdepth_dist_0->primal_0 = (*dpdepth_dist_0).primal_0;
    dpdepth_dist_0->differential_0 = _S225;
    dprgb_dist_0->primal_0 = (*dprgb_dist_0).primal_0;
    dprgb_dist_0->differential_0 = _S300;
    dprender_Ts_0->primal_0 = (*dprender_Ts_0).primal_0;
    dprender_Ts_0->differential_0 = _S260;
    dpref_normal_0->primal_0 = (*dpref_normal_0).primal_0;
    dpref_normal_0->differential_0 = _S146;
    dpdepth_normal_0->primal_0 = (*dpdepth_normal_0).primal_0;
    dpdepth_normal_0->differential_0 = _S347;
    dprender_normal_0->primal_0 = (*dprender_normal_0).primal_0;
    dprender_normal_0->differential_0 = _S354;
    dpref_depth_0->primal_0 = (*dpref_depth_0).primal_0;
    dpref_depth_0->differential_0 = _S361.differential_0;
    dprender_depth_0->primal_0 = (*dprender_depth_0).primal_0;
    dprender_depth_0->differential_0 = _S389;
    dpref_rgb_0->primal_0 = (*dpref_rgb_0).primal_0;
    dpref_rgb_0->differential_0 = _S148;
    dprender_rgb_0->primal_0 = (*dprender_rgb_0).primal_0;
    dprender_rgb_0->differential_0 = _S153;
    return;
}

inline __device__ void s_bwd_per_pixel_losses_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S402, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S403, DiffPair_float_0 * _S404, DiffPair_float_0 * _S405, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S406, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S407, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S408, DiffPair_float_0 * _S409, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S410, DiffPair_float_0 * _S411, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S412, DiffPair_float_0 * _S413, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S414, bool _S415, bool _S416, float _S417, FixedArray<float, 20>  * _S418, FixedArray<float, 33>  * _S419)
{
    s_bwd_prop_per_pixel_losses_0(_S402, _S403, _S404, _S405, _S406, _S407, _S408, _S409, _S410, _S411, _S412, _S413, _S414, _S415, _S416, _S417, _S418, _S419);
    return;
}

inline __device__ void per_pixel_losses_bwd(float3  render_rgb_1, float3  ref_rgb_1, float render_depth_1, float ref_depth_1, float3  render_normal_1, float3  depth_normal_1, float3  ref_normal_1, float render_Ts_1, float3  rgb_dist_1, float depth_dist_1, float3  normal_dist_1, float median_depth_1, float3  median_normal_1, bool ref_alpha_2, bool has_mask_2, float saturation_threshold_2, FixedArray<float, 20>  weights_2, FixedArray<float, 33>  v_losses_0, float3  * v_render_rgb_0, float3  * v_ref_rgb_0, float * v_render_depth_0, float * v_ref_depth_0, float3  * v_render_normal_0, float3  * v_depth_normal_0, float3  * v_ref_normal_0, float * v_render_Ts_0, float3  * v_rgb_dist_0, float * v_depth_dist_0, float3  * v_normal_dist_0, float * v_median_depth_0, float3  * v_median_normal_0)
{
    float3  _S420 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_render_rgb_0;
    (&dp_render_rgb_0)->primal_0 = render_rgb_1;
    (&dp_render_rgb_0)->differential_0 = _S420;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_ref_rgb_0;
    (&dp_ref_rgb_0)->primal_0 = ref_rgb_1;
    (&dp_ref_rgb_0)->differential_0 = _S420;
    DiffPair_float_0 dp_render_depth_0;
    (&dp_render_depth_0)->primal_0 = render_depth_1;
    (&dp_render_depth_0)->differential_0 = 0.0f;
    DiffPair_float_0 dp_ref_depth_0;
    (&dp_ref_depth_0)->primal_0 = ref_depth_1;
    (&dp_ref_depth_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_render_normal_0;
    (&dp_render_normal_0)->primal_0 = render_normal_1;
    (&dp_render_normal_0)->differential_0 = _S420;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_depth_normal_0;
    (&dp_depth_normal_0)->primal_0 = depth_normal_1;
    (&dp_depth_normal_0)->differential_0 = _S420;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_ref_normal_0;
    (&dp_ref_normal_0)->primal_0 = ref_normal_1;
    (&dp_ref_normal_0)->differential_0 = _S420;
    DiffPair_float_0 dp_render_Ts_0;
    (&dp_render_Ts_0)->primal_0 = render_Ts_1;
    (&dp_render_Ts_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_rgb_dist_0;
    (&dp_rgb_dist_0)->primal_0 = rgb_dist_1;
    (&dp_rgb_dist_0)->differential_0 = _S420;
    DiffPair_float_0 dp_depth_dist_0;
    (&dp_depth_dist_0)->primal_0 = depth_dist_1;
    (&dp_depth_dist_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_normal_dist_0;
    (&dp_normal_dist_0)->primal_0 = normal_dist_1;
    (&dp_normal_dist_0)->differential_0 = _S420;
    DiffPair_float_0 dp_median_depth_0;
    (&dp_median_depth_0)->primal_0 = median_depth_1;
    (&dp_median_depth_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_median_normal_0;
    (&dp_median_normal_0)->primal_0 = median_normal_1;
    (&dp_median_normal_0)->differential_0 = _S420;
    FixedArray<float, 20>  _S421 = weights_2;
    FixedArray<float, 33>  _S422 = v_losses_0;
    s_bwd_per_pixel_losses_0(&dp_render_rgb_0, &dp_ref_rgb_0, &dp_render_depth_0, &dp_ref_depth_0, &dp_render_normal_0, &dp_depth_normal_0, &dp_ref_normal_0, &dp_render_Ts_0, &dp_rgb_dist_0, &dp_depth_dist_0, &dp_normal_dist_0, &dp_median_depth_0, &dp_median_normal_0, ref_alpha_2, has_mask_2, saturation_threshold_2, &_S421, &_S422);
    *v_render_rgb_0 = dp_render_rgb_0.differential_0;
    *v_ref_rgb_0 = dp_ref_rgb_0.differential_0;
    *v_render_depth_0 = dp_render_depth_0.differential_0;
    *v_ref_depth_0 = dp_ref_depth_0.differential_0;
    *v_render_normal_0 = dp_render_normal_0.differential_0;
    *v_depth_normal_0 = dp_depth_normal_0.differential_0;
    *v_ref_normal_0 = dp_ref_normal_0.differential_0;
    *v_render_Ts_0 = dp_render_Ts_0.differential_0;
    *v_rgb_dist_0 = dp_rgb_dist_0.differential_0;
    *v_depth_dist_0 = dp_depth_dist_0.differential_0;
    *v_normal_dist_0 = dp_normal_dist_0.differential_0;
    *v_median_depth_0 = dp_median_depth_0.differential_0;
    *v_median_normal_0 = dp_median_normal_0.differential_0;
    return;
}

inline __device__ void _d_log10_0(DiffPair_float_0 * dpx_10, float dOut_10)
{
    float _S423 = 1.0f / ((*dpx_10).primal_0 * 2.30258512496948242f) * dOut_10;
    dpx_10->primal_0 = (*dpx_10).primal_0;
    dpx_10->differential_0 = _S423;
    return;
}

inline __device__ void per_pixel_losses_reduce(FixedArray<float, 33>  raw_losses_0, FixedArray<float, 20>  weights_3, FixedArray<float, 14>  * _S424)
{
    FixedArray<float, 14>  losses_1;
    losses_1[int(0)] = raw_losses_0[int(0)] / (F32_max((raw_losses_0[int(32)]), (1.0f)));
    float _S425 = (F32_max((raw_losses_0[int(21)]), (1.0f)));
    losses_1[int(1)] = -10.0f * (F32_log10((raw_losses_0[int(1)] / _S425)));
    bool _S426;
    if((raw_losses_0[int(22)]) > 0.0f)
    {
        _S426 = (raw_losses_0[int(3)]) != 0.0f;
    }
    else
    {
        _S426 = false;
    }
    float _S427;
    if(_S426)
    {
        _S427 = weights_3[int(6)] * clamp_0(1.0f - (raw_losses_0[int(6)] - raw_losses_0[int(2)] * raw_losses_0[int(3)] / raw_losses_0[int(22)]) / (F32_sqrt(((F32_max((9.999999960041972e-13f), ((raw_losses_0[int(4)] - raw_losses_0[int(2)] * raw_losses_0[int(2)] / raw_losses_0[int(22)]) * (raw_losses_0[int(5)] - raw_losses_0[int(3)] * raw_losses_0[int(3)] / raw_losses_0[int(22)]) + 1.0f)))))), 0.0f, 2.0f);
    }
    else
    {
        _S427 = 0.0f;
    }
    losses_1[int(2)] = _S427;
    losses_1[int(3)] = (raw_losses_0[int(7)] / (F32_max((raw_losses_0[int(23)]), (1.0f))) + raw_losses_0[int(8)] / (F32_max((raw_losses_0[int(24)]), (1.0f)))) / float((I32_max((int((raw_losses_0[int(23)]) > 0.5f) + int((raw_losses_0[int(24)]) > 0.5f)), (int(1)))));
    losses_1[int(4)] = raw_losses_0[int(9)] / (F32_max((raw_losses_0[int(26)]), (1.0f))) + raw_losses_0[int(10)] / (F32_max((raw_losses_0[int(27)]), (1.0f)));
    losses_1[int(5)] = raw_losses_0[int(11)] / (F32_max((raw_losses_0[int(25)]), (1.0f)));
    losses_1[int(6)] = raw_losses_0[int(12)] / _S425;
    losses_1[int(7)] = raw_losses_0[int(13)] / _S425;
    losses_1[int(8)] = raw_losses_0[int(14)] / _S425;
    losses_1[int(9)] = raw_losses_0[int(15)] / _S425;
    losses_1[int(10)] = raw_losses_0[int(16)] / (F32_max((raw_losses_0[int(28)]), (1.0f)));
    losses_1[int(11)] = raw_losses_0[int(17)] / (F32_max((raw_losses_0[int(29)]), (1.0f)));
    losses_1[int(12)] = raw_losses_0[int(18)] / (F32_max((raw_losses_0[int(30)]), (1.0f)));
    losses_1[int(13)] = raw_losses_0[int(19)] / (F32_max((raw_losses_0[int(31)]), (1.0f)));
    *_S424 = losses_1;
    return;
}

struct DiffPair_arrayx3Cfloatx2C33x3E_0
{
    FixedArray<float, 33>  primal_0;
    FixedArray<float, 33>  differential_0;
};

inline __device__ float s_primal_ctx_sqrt_0(float _S428)
{
    return (F32_sqrt((_S428)));
}

inline __device__ void s_bwd_prop_log10_0(DiffPair_float_0 * _S429, float _S430)
{
    _d_log10_0(_S429, _S430);
    return;
}

inline __device__ void s_bwd_prop_per_pixel_losses_reduce_0(DiffPair_arrayx3Cfloatx2C33x3E_0 * dpraw_losses_0, FixedArray<float, 20>  * weights_4, FixedArray<float, 14>  * _s_dOut_1)
{
    FixedArray<float, 33>  _S431 = dpraw_losses_0->primal_0;
    float _S432 = (F32_max((dpraw_losses_0->primal_0[int(32)]), (1.0f)));
    float _S433 = _S432 * _S432;
    float _S434 = (F32_max((dpraw_losses_0->primal_0[int(21)]), (1.0f)));
    float _S435 = dpraw_losses_0->primal_0[int(1)] / _S434;
    float _S436 = _S434 * _S434;
    bool _S437 = (dpraw_losses_0->primal_0[int(22)]) > 0.0f;
    bool _S438;
    if(_S437)
    {
        _S438 = (_S431[int(3)]) != 0.0f;
    }
    else
    {
        _S438 = false;
    }
    float _S439;
    float _S440;
    float _S441;
    float _S442;
    float _S443;
    float _S444;
    float _S445;
    float _S446;
    float _S447;
    float _S448;
    float _S449;
    float _S450;
    float _S451;
    float _S452;
    float _S453;
    if(_S438)
    {
        float _S454 = _S431[int(2)] * _S431[int(3)];
        float _S455 = _S431[int(22)] * _S431[int(22)];
        float _S456 = _S431[int(6)] - _S454 / _S431[int(22)];
        float _S457 = _S431[int(2)] * _S431[int(2)];
        float _S458 = _S431[int(4)] - _S457 / _S431[int(22)];
        float _S459 = _S431[int(3)] * _S431[int(3)];
        float _S460 = _S431[int(5)] - _S459 / _S431[int(22)];
        float _S461 = _S458 * _S460 + 1.0f;
        float _S462 = (F32_max((9.999999960041972e-13f), (_S461)));
        float _S463 = s_primal_ctx_sqrt_0(_S462);
        float _S464 = _S463 * _S463;
        float _S465 = 1.0f - _S456 / _S463;
        _S439 = (*weights_4)[int(6)];
        _S440 = _S465;
        _S441 = _S464;
        _S442 = _S456;
        _S443 = _S463;
        _S444 = _S462;
        _S445 = _S461;
        _S446 = _S458;
        _S447 = _S460;
        _S448 = _S455;
        _S449 = _S459;
        _S450 = _S431[int(3)];
        _S451 = _S457;
        _S452 = _S431[int(2)];
        _S453 = _S454;
    }
    else
    {
        _S439 = 0.0f;
        _S440 = 0.0f;
        _S441 = 0.0f;
        _S442 = 0.0f;
        _S443 = 0.0f;
        _S444 = 0.0f;
        _S445 = 0.0f;
        _S446 = 0.0f;
        _S447 = 0.0f;
        _S448 = 0.0f;
        _S449 = 0.0f;
        _S450 = 0.0f;
        _S451 = 0.0f;
        _S452 = 0.0f;
        _S453 = 0.0f;
    }
    float _S466 = (F32_max((_S431[int(23)]), (1.0f)));
    float _S467 = _S466 * _S466;
    float _S468 = (F32_max((_S431[int(24)]), (1.0f)));
    float _S469 = _S468 * _S468;
    float _S470 = float((I32_max((int((_S431[int(23)]) > 0.5f) + int((_S431[int(24)]) > 0.5f)), (int(1)))));
    float _S471 = (F32_max((_S431[int(26)]), (1.0f)));
    float _S472 = _S471 * _S471;
    float _S473 = (F32_max((_S431[int(27)]), (1.0f)));
    float _S474 = _S473 * _S473;
    float _S475 = (F32_max((_S431[int(25)]), (1.0f)));
    float _S476 = _S475 * _S475;
    float _S477 = (F32_max((_S431[int(28)]), (1.0f)));
    float _S478 = _S477 * _S477;
    float _S479 = (F32_max((_S431[int(29)]), (1.0f)));
    float _S480 = _S479 * _S479;
    float _S481 = (F32_max((_S431[int(30)]), (1.0f)));
    float _S482 = _S481 * _S481;
    float _S483 = (F32_max((_S431[int(31)]), (1.0f)));
    float _S484 = _S483 * _S483;
    float _S485 = (*_s_dOut_1)[int(0)];
    float _S486 = (*_s_dOut_1)[int(1)];
    float _S487 = (*_s_dOut_1)[int(2)];
    float _S488 = (*_s_dOut_1)[int(13)] / _S484;
    float _S489 = _S431[int(19)] * - _S488;
    float _S490 = _S483 * _S488;
    DiffPair_float_0 _S491;
    (&_S491)->primal_0 = _S431[int(31)];
    (&_S491)->differential_0 = 0.0f;
    DiffPair_float_0 _S492;
    (&_S492)->primal_0 = 1.0f;
    (&_S492)->differential_0 = 0.0f;
    _d_max_0(&_S491, &_S492, _S489);
    float _S493 = (*_s_dOut_1)[int(12)] / _S482;
    float _S494 = _S431[int(18)] * - _S493;
    float _S495 = _S481 * _S493;
    DiffPair_float_0 _S496;
    (&_S496)->primal_0 = _S431[int(30)];
    (&_S496)->differential_0 = 0.0f;
    DiffPair_float_0 _S497;
    (&_S497)->primal_0 = 1.0f;
    (&_S497)->differential_0 = 0.0f;
    _d_max_0(&_S496, &_S497, _S494);
    float _S498 = (*_s_dOut_1)[int(11)] / _S480;
    float _S499 = _S431[int(17)] * - _S498;
    float _S500 = _S479 * _S498;
    DiffPair_float_0 _S501;
    (&_S501)->primal_0 = _S431[int(29)];
    (&_S501)->differential_0 = 0.0f;
    DiffPair_float_0 _S502;
    (&_S502)->primal_0 = 1.0f;
    (&_S502)->differential_0 = 0.0f;
    _d_max_0(&_S501, &_S502, _S499);
    float _S503 = (*_s_dOut_1)[int(10)] / _S478;
    float _S504 = _S431[int(16)] * - _S503;
    float _S505 = _S477 * _S503;
    DiffPair_float_0 _S506;
    (&_S506)->primal_0 = _S431[int(28)];
    (&_S506)->differential_0 = 0.0f;
    DiffPair_float_0 _S507;
    (&_S507)->primal_0 = 1.0f;
    (&_S507)->differential_0 = 0.0f;
    _d_max_0(&_S506, &_S507, _S504);
    float _S508 = (*_s_dOut_1)[int(9)] / _S436;
    float _S509 = _S431[int(15)] * - _S508;
    float _S510 = _S434 * _S508;
    float _S511 = (*_s_dOut_1)[int(8)] / _S436;
    float _S512 = _S431[int(14)] * - _S511;
    float _S513 = _S434 * _S511;
    float _S514 = (*_s_dOut_1)[int(7)] / _S436;
    float _S515 = _S431[int(13)] * - _S514;
    float _S516 = _S434 * _S514;
    float _S517 = (*_s_dOut_1)[int(6)] / _S436;
    float _S518 = _S431[int(12)] * - _S517;
    float _S519 = _S434 * _S517;
    float _S520 = (*_s_dOut_1)[int(5)] / _S476;
    float _S521 = _S431[int(11)] * - _S520;
    float _S522 = _S475 * _S520;
    DiffPair_float_0 _S523;
    (&_S523)->primal_0 = _S431[int(25)];
    (&_S523)->differential_0 = 0.0f;
    DiffPair_float_0 _S524;
    (&_S524)->primal_0 = 1.0f;
    (&_S524)->differential_0 = 0.0f;
    _d_max_0(&_S523, &_S524, _S521);
    float _S525 = (*_s_dOut_1)[int(4)] / _S474;
    float _S526 = _S431[int(10)] * - _S525;
    float _S527 = _S473 * _S525;
    DiffPair_float_0 _S528;
    (&_S528)->primal_0 = _S431[int(27)];
    (&_S528)->differential_0 = 0.0f;
    DiffPair_float_0 _S529;
    (&_S529)->primal_0 = 1.0f;
    (&_S529)->differential_0 = 0.0f;
    _d_max_0(&_S528, &_S529, _S526);
    float _S530 = (*_s_dOut_1)[int(4)] / _S472;
    float _S531 = _S431[int(9)] * - _S530;
    float _S532 = _S471 * _S530;
    DiffPair_float_0 _S533;
    (&_S533)->primal_0 = _S431[int(26)];
    (&_S533)->differential_0 = 0.0f;
    DiffPair_float_0 _S534;
    (&_S534)->primal_0 = 1.0f;
    (&_S534)->differential_0 = 0.0f;
    _d_max_0(&_S533, &_S534, _S531);
    float _S535 = (*_s_dOut_1)[int(3)] / _S470;
    float _S536 = _S535 / _S469;
    float _S537 = _S431[int(8)] * - _S536;
    float _S538 = _S468 * _S536;
    DiffPair_float_0 _S539;
    (&_S539)->primal_0 = _S431[int(24)];
    (&_S539)->differential_0 = 0.0f;
    DiffPair_float_0 _S540;
    (&_S540)->primal_0 = 1.0f;
    (&_S540)->differential_0 = 0.0f;
    _d_max_0(&_S539, &_S540, _S537);
    float _S541 = _S535 / _S467;
    float _S542 = _S431[int(7)] * - _S541;
    float _S543 = _S466 * _S541;
    DiffPair_float_0 _S544;
    (&_S544)->primal_0 = _S431[int(23)];
    (&_S544)->differential_0 = 0.0f;
    DiffPair_float_0 _S545;
    (&_S545)->primal_0 = 1.0f;
    (&_S545)->differential_0 = 0.0f;
    _d_max_0(&_S544, &_S545, _S542);
    float _S546 = _S509 + _S512 + _S515 + _S518;
    FixedArray<float, 33>  _S547;
    _S547[int(0)] = 0.0f;
    _S547[int(1)] = 0.0f;
    _S547[int(2)] = 0.0f;
    _S547[int(3)] = 0.0f;
    _S547[int(4)] = 0.0f;
    _S547[int(5)] = 0.0f;
    _S547[int(6)] = 0.0f;
    _S547[int(7)] = 0.0f;
    _S547[int(8)] = 0.0f;
    _S547[int(9)] = 0.0f;
    _S547[int(10)] = 0.0f;
    _S547[int(11)] = 0.0f;
    _S547[int(12)] = 0.0f;
    _S547[int(13)] = 0.0f;
    _S547[int(14)] = 0.0f;
    _S547[int(15)] = 0.0f;
    _S547[int(16)] = 0.0f;
    _S547[int(17)] = 0.0f;
    _S547[int(18)] = 0.0f;
    _S547[int(19)] = 0.0f;
    _S547[int(20)] = 0.0f;
    _S547[int(21)] = 0.0f;
    _S547[int(22)] = 0.0f;
    _S547[int(23)] = 0.0f;
    _S547[int(24)] = 0.0f;
    _S547[int(25)] = 0.0f;
    _S547[int(26)] = 0.0f;
    _S547[int(27)] = 0.0f;
    _S547[int(28)] = 0.0f;
    _S547[int(29)] = 0.0f;
    _S547[int(30)] = 0.0f;
    _S547[int(31)] = 0.0f;
    _S547[int(32)] = 0.0f;
    _S547[int(31)] = _S491.differential_0;
    _S547[int(19)] = _S490;
    _S547[int(30)] = _S496.differential_0;
    _S547[int(18)] = _S495;
    _S547[int(29)] = _S501.differential_0;
    _S547[int(17)] = _S500;
    _S547[int(28)] = _S506.differential_0;
    _S547[int(16)] = _S505;
    _S547[int(15)] = _S510;
    _S547[int(14)] = _S513;
    _S547[int(13)] = _S516;
    _S547[int(12)] = _S519;
    _S547[int(25)] = _S523.differential_0;
    _S547[int(11)] = _S522;
    _S547[int(27)] = _S528.differential_0;
    _S547[int(10)] = _S527;
    _S547[int(26)] = _S533.differential_0;
    _S547[int(9)] = _S532;
    _S547[int(24)] = _S539.differential_0;
    _S547[int(8)] = _S538;
    _S547[int(23)] = _S544.differential_0;
    _S547[int(7)] = _S543;
    float _S548 = _S547[int(0)];
    float _S549 = _S547[int(1)];
    float _S550 = _S547[int(2)];
    float _S551 = _S547[int(3)];
    float _S552 = _S547[int(4)];
    float _S553 = _S547[int(5)];
    float _S554 = _S547[int(6)];
    float _S555 = _S547[int(7)];
    float _S556 = _S547[int(8)];
    float _S557 = _S547[int(9)];
    float _S558 = _S547[int(10)];
    float _S559 = _S547[int(11)];
    float _S560 = _S547[int(12)];
    float _S561 = _S547[int(13)];
    float _S562 = _S547[int(14)];
    float _S563 = _S547[int(15)];
    float _S564 = _S547[int(16)];
    float _S565 = _S547[int(17)];
    float _S566 = _S547[int(18)];
    float _S567 = _S547[int(19)];
    float _S568 = _S547[int(20)];
    float _S569 = _S547[int(21)];
    float _S570 = _S547[int(22)];
    float _S571 = _S547[int(23)];
    float _S572 = _S547[int(24)];
    float _S573 = _S547[int(25)];
    float _S574 = _S547[int(26)];
    float _S575 = _S547[int(27)];
    float _S576 = _S547[int(28)];
    float _S577 = _S547[int(29)];
    float _S578 = _S547[int(30)];
    float _S579 = _S547[int(31)];
    float _S580 = _S547[int(32)];
    FixedArray<float, 33>  _S581;
    if(_S438)
    {
        float _S582 = _S439 * _S487;
        DiffPair_float_0 _S583;
        (&_S583)->primal_0 = _S440;
        (&_S583)->differential_0 = 0.0f;
        DiffPair_float_0 _S584;
        (&_S584)->primal_0 = 0.0f;
        (&_S584)->differential_0 = 0.0f;
        DiffPair_float_0 _S585;
        (&_S585)->primal_0 = 2.0f;
        (&_S585)->differential_0 = 0.0f;
        s_bwd_prop_clamp_0(&_S583, &_S584, &_S585, _S582);
        float _S586 = - _S583.differential_0 / _S441;
        float _S587 = _S442 * - _S586;
        float _S588 = _S443 * _S586;
        DiffPair_float_0 _S589;
        (&_S589)->primal_0 = _S444;
        (&_S589)->differential_0 = 0.0f;
        s_bwd_prop_sqrt_0(&_S589, _S587);
        DiffPair_float_0 _S590;
        (&_S590)->primal_0 = 9.999999960041972e-13f;
        (&_S590)->differential_0 = 0.0f;
        DiffPair_float_0 _S591;
        (&_S591)->primal_0 = _S445;
        (&_S591)->differential_0 = 0.0f;
        _d_max_0(&_S590, &_S591, _S589.differential_0);
        float _S592 = _S446 * _S591.differential_0;
        float _S593 = _S447 * _S591.differential_0;
        float _S594 = - _S592 / _S448;
        float _S595 = _S450 * (_S431[int(22)] * _S594);
        float _S596 = - _S593 / _S448;
        float _S597 = _S452 * (_S431[int(22)] * _S596);
        float _S598 = - _S588 / _S448;
        float _S599 = _S431[int(22)] * _S598;
        float _S600 = _S595 + _S595 + _S452 * _S599;
        float _S601 = _S597 + _S597 + _S450 * _S599;
        float _S602 = _S449 * - _S594 + _S451 * - _S596 + _S453 * - _S598;
        FixedArray<float, 33>  _S603;
        _S603[int(0)] = 0.0f;
        _S603[int(1)] = 0.0f;
        _S603[int(2)] = 0.0f;
        _S603[int(3)] = 0.0f;
        _S603[int(4)] = 0.0f;
        _S603[int(5)] = 0.0f;
        _S603[int(6)] = 0.0f;
        _S603[int(7)] = 0.0f;
        _S603[int(8)] = 0.0f;
        _S603[int(9)] = 0.0f;
        _S603[int(10)] = 0.0f;
        _S603[int(11)] = 0.0f;
        _S603[int(12)] = 0.0f;
        _S603[int(13)] = 0.0f;
        _S603[int(14)] = 0.0f;
        _S603[int(15)] = 0.0f;
        _S603[int(16)] = 0.0f;
        _S603[int(17)] = 0.0f;
        _S603[int(18)] = 0.0f;
        _S603[int(19)] = 0.0f;
        _S603[int(20)] = 0.0f;
        _S603[int(21)] = 0.0f;
        _S603[int(22)] = 0.0f;
        _S603[int(23)] = 0.0f;
        _S603[int(24)] = 0.0f;
        _S603[int(25)] = 0.0f;
        _S603[int(26)] = 0.0f;
        _S603[int(27)] = 0.0f;
        _S603[int(28)] = 0.0f;
        _S603[int(29)] = 0.0f;
        _S603[int(30)] = 0.0f;
        _S603[int(31)] = 0.0f;
        _S603[int(32)] = 0.0f;
        _S603[int(5)] = _S592;
        _S603[int(4)] = _S593;
        _S603[int(3)] = _S600;
        _S603[int(2)] = _S601;
        _S603[int(6)] = _S588;
        float _S604 = _S549 + _S603[int(1)];
        float _S605 = _S550 + _S603[int(2)];
        float _S606 = _S551 + _S603[int(3)];
        float _S607 = _S552 + _S603[int(4)];
        float _S608 = _S553 + _S603[int(5)];
        float _S609 = _S554 + _S603[int(6)];
        float _S610 = _S555 + _S603[int(7)];
        float _S611 = _S556 + _S603[int(8)];
        float _S612 = _S557 + _S603[int(9)];
        float _S613 = _S558 + _S603[int(10)];
        float _S614 = _S559 + _S603[int(11)];
        float _S615 = _S560 + _S603[int(12)];
        float _S616 = _S561 + _S603[int(13)];
        float _S617 = _S562 + _S603[int(14)];
        float _S618 = _S563 + _S603[int(15)];
        float _S619 = _S564 + _S603[int(16)];
        float _S620 = _S565 + _S603[int(17)];
        float _S621 = _S566 + _S603[int(18)];
        float _S622 = _S567 + _S603[int(19)];
        float _S623 = _S568 + _S603[int(20)];
        float _S624 = _S569 + _S603[int(21)];
        float _S625 = _S570 + _S603[int(22)];
        float _S626 = _S571 + _S603[int(23)];
        float _S627 = _S572 + _S603[int(24)];
        float _S628 = _S573 + _S603[int(25)];
        float _S629 = _S574 + _S603[int(26)];
        float _S630 = _S575 + _S603[int(27)];
        float _S631 = _S576 + _S603[int(28)];
        float _S632 = _S577 + _S603[int(29)];
        float _S633 = _S578 + _S603[int(30)];
        float _S634 = _S579 + _S603[int(31)];
        float _S635 = _S580 + _S603[int(32)];
        _S581[int(0)] = _S548 + _S603[int(0)];
        _S581[int(1)] = _S604;
        _S581[int(2)] = _S605;
        _S581[int(3)] = _S606;
        _S581[int(4)] = _S607;
        _S581[int(5)] = _S608;
        _S581[int(6)] = _S609;
        _S581[int(7)] = _S610;
        _S581[int(8)] = _S611;
        _S581[int(9)] = _S612;
        _S581[int(10)] = _S613;
        _S581[int(11)] = _S614;
        _S581[int(12)] = _S615;
        _S581[int(13)] = _S616;
        _S581[int(14)] = _S617;
        _S581[int(15)] = _S618;
        _S581[int(16)] = _S619;
        _S581[int(17)] = _S620;
        _S581[int(18)] = _S621;
        _S581[int(19)] = _S622;
        _S581[int(20)] = _S623;
        _S581[int(21)] = _S624;
        _S581[int(22)] = _S625;
        _S581[int(23)] = _S626;
        _S581[int(24)] = _S627;
        _S581[int(25)] = _S628;
        _S581[int(26)] = _S629;
        _S581[int(27)] = _S630;
        _S581[int(28)] = _S631;
        _S581[int(29)] = _S632;
        _S581[int(30)] = _S633;
        _S581[int(31)] = _S634;
        _S581[int(32)] = _S635;
        _S439 = _S602;
    }
    else
    {
        _S581[int(0)] = _S548;
        _S581[int(1)] = _S549;
        _S581[int(2)] = _S550;
        _S581[int(3)] = _S551;
        _S581[int(4)] = _S552;
        _S581[int(5)] = _S553;
        _S581[int(6)] = _S554;
        _S581[int(7)] = _S555;
        _S581[int(8)] = _S556;
        _S581[int(9)] = _S557;
        _S581[int(10)] = _S558;
        _S581[int(11)] = _S559;
        _S581[int(12)] = _S560;
        _S581[int(13)] = _S561;
        _S581[int(14)] = _S562;
        _S581[int(15)] = _S563;
        _S581[int(16)] = _S564;
        _S581[int(17)] = _S565;
        _S581[int(18)] = _S566;
        _S581[int(19)] = _S567;
        _S581[int(20)] = _S568;
        _S581[int(21)] = _S569;
        _S581[int(22)] = _S570;
        _S581[int(23)] = _S571;
        _S581[int(24)] = _S572;
        _S581[int(25)] = _S573;
        _S581[int(26)] = _S574;
        _S581[int(27)] = _S575;
        _S581[int(28)] = _S576;
        _S581[int(29)] = _S577;
        _S581[int(30)] = _S578;
        _S581[int(31)] = _S579;
        _S581[int(32)] = _S580;
        _S439 = 0.0f;
    }
    if(_S437)
    {
        FixedArray<float, 33>  _S636;
        _S636[int(0)] = 0.0f;
        _S636[int(1)] = 0.0f;
        _S636[int(2)] = 0.0f;
        _S636[int(3)] = 0.0f;
        _S636[int(4)] = 0.0f;
        _S636[int(5)] = 0.0f;
        _S636[int(6)] = 0.0f;
        _S636[int(7)] = 0.0f;
        _S636[int(8)] = 0.0f;
        _S636[int(9)] = 0.0f;
        _S636[int(10)] = 0.0f;
        _S636[int(11)] = 0.0f;
        _S636[int(12)] = 0.0f;
        _S636[int(13)] = 0.0f;
        _S636[int(14)] = 0.0f;
        _S636[int(15)] = 0.0f;
        _S636[int(16)] = 0.0f;
        _S636[int(17)] = 0.0f;
        _S636[int(18)] = 0.0f;
        _S636[int(19)] = 0.0f;
        _S636[int(20)] = 0.0f;
        _S636[int(21)] = 0.0f;
        _S636[int(22)] = 0.0f;
        _S636[int(23)] = 0.0f;
        _S636[int(24)] = 0.0f;
        _S636[int(25)] = 0.0f;
        _S636[int(26)] = 0.0f;
        _S636[int(27)] = 0.0f;
        _S636[int(28)] = 0.0f;
        _S636[int(29)] = 0.0f;
        _S636[int(30)] = 0.0f;
        _S636[int(31)] = 0.0f;
        _S636[int(32)] = 0.0f;
        _S636[int(3)] = 0.0f;
        float _S637 = _S581[int(1)] + _S636[int(1)];
        float _S638 = _S581[int(2)] + _S636[int(2)];
        float _S639 = _S581[int(3)] + _S636[int(3)];
        float _S640 = _S581[int(4)] + _S636[int(4)];
        float _S641 = _S581[int(5)] + _S636[int(5)];
        float _S642 = _S581[int(6)] + _S636[int(6)];
        float _S643 = _S581[int(7)] + _S636[int(7)];
        float _S644 = _S581[int(8)] + _S636[int(8)];
        float _S645 = _S581[int(9)] + _S636[int(9)];
        float _S646 = _S581[int(10)] + _S636[int(10)];
        float _S647 = _S581[int(11)] + _S636[int(11)];
        float _S648 = _S581[int(12)] + _S636[int(12)];
        float _S649 = _S581[int(13)] + _S636[int(13)];
        float _S650 = _S581[int(14)] + _S636[int(14)];
        float _S651 = _S581[int(15)] + _S636[int(15)];
        float _S652 = _S581[int(16)] + _S636[int(16)];
        float _S653 = _S581[int(17)] + _S636[int(17)];
        float _S654 = _S581[int(18)] + _S636[int(18)];
        float _S655 = _S581[int(19)] + _S636[int(19)];
        float _S656 = _S581[int(20)] + _S636[int(20)];
        float _S657 = _S581[int(21)] + _S636[int(21)];
        float _S658 = _S581[int(22)] + _S636[int(22)];
        float _S659 = _S581[int(23)] + _S636[int(23)];
        float _S660 = _S581[int(24)] + _S636[int(24)];
        float _S661 = _S581[int(25)] + _S636[int(25)];
        float _S662 = _S581[int(26)] + _S636[int(26)];
        float _S663 = _S581[int(27)] + _S636[int(27)];
        float _S664 = _S581[int(28)] + _S636[int(28)];
        float _S665 = _S581[int(29)] + _S636[int(29)];
        float _S666 = _S581[int(30)] + _S636[int(30)];
        float _S667 = _S581[int(31)] + _S636[int(31)];
        float _S668 = _S581[int(32)] + _S636[int(32)];
        _S581[int(0)] = _S581[int(0)] + _S636[int(0)];
        _S581[int(1)] = _S637;
        _S581[int(2)] = _S638;
        _S581[int(3)] = _S639;
        _S581[int(4)] = _S640;
        _S581[int(5)] = _S641;
        _S581[int(6)] = _S642;
        _S581[int(7)] = _S643;
        _S581[int(8)] = _S644;
        _S581[int(9)] = _S645;
        _S581[int(10)] = _S646;
        _S581[int(11)] = _S647;
        _S581[int(12)] = _S648;
        _S581[int(13)] = _S649;
        _S581[int(14)] = _S650;
        _S581[int(15)] = _S651;
        _S581[int(16)] = _S652;
        _S581[int(17)] = _S653;
        _S581[int(18)] = _S654;
        _S581[int(19)] = _S655;
        _S581[int(20)] = _S656;
        _S581[int(21)] = _S657;
        _S581[int(22)] = _S658;
        _S581[int(23)] = _S659;
        _S581[int(24)] = _S660;
        _S581[int(25)] = _S661;
        _S581[int(26)] = _S662;
        _S581[int(27)] = _S663;
        _S581[int(28)] = _S664;
        _S581[int(29)] = _S665;
        _S581[int(30)] = _S666;
        _S581[int(31)] = _S667;
        _S581[int(32)] = _S668;
    }
    float _S669 = -10.0f * _S486;
    DiffPair_float_0 _S670;
    (&_S670)->primal_0 = _S435;
    (&_S670)->differential_0 = 0.0f;
    s_bwd_prop_log10_0(&_S670, _S669);
    float _S671 = _S670.differential_0 / _S436;
    float _S672 = _S434 * _S671;
    float _S673 = _S431[int(1)] * - _S671 + _S546;
    DiffPair_float_0 _S674;
    (&_S674)->primal_0 = _S431[int(21)];
    (&_S674)->differential_0 = 0.0f;
    DiffPair_float_0 _S675;
    (&_S675)->primal_0 = 1.0f;
    (&_S675)->differential_0 = 0.0f;
    _d_max_0(&_S674, &_S675, _S673);
    float _S676 = _S485 / _S433;
    float _S677 = _S431[int(0)] * - _S676;
    float _S678 = _S432 * _S676;
    DiffPair_float_0 _S679;
    (&_S679)->primal_0 = _S431[int(32)];
    (&_S679)->differential_0 = 0.0f;
    DiffPair_float_0 _S680;
    (&_S680)->primal_0 = 1.0f;
    (&_S680)->differential_0 = 0.0f;
    _d_max_0(&_S679, &_S680, _S677);
    FixedArray<float, 33>  _S681;
    _S681[int(0)] = 0.0f;
    _S681[int(1)] = 0.0f;
    _S681[int(2)] = 0.0f;
    _S681[int(3)] = 0.0f;
    _S681[int(4)] = 0.0f;
    _S681[int(5)] = 0.0f;
    _S681[int(6)] = 0.0f;
    _S681[int(7)] = 0.0f;
    _S681[int(8)] = 0.0f;
    _S681[int(9)] = 0.0f;
    _S681[int(10)] = 0.0f;
    _S681[int(11)] = 0.0f;
    _S681[int(12)] = 0.0f;
    _S681[int(13)] = 0.0f;
    _S681[int(14)] = 0.0f;
    _S681[int(15)] = 0.0f;
    _S681[int(16)] = 0.0f;
    _S681[int(17)] = 0.0f;
    _S681[int(18)] = 0.0f;
    _S681[int(19)] = 0.0f;
    _S681[int(20)] = 0.0f;
    _S681[int(21)] = 0.0f;
    _S681[int(22)] = 0.0f;
    _S681[int(23)] = 0.0f;
    _S681[int(24)] = 0.0f;
    _S681[int(25)] = 0.0f;
    _S681[int(26)] = 0.0f;
    _S681[int(27)] = 0.0f;
    _S681[int(28)] = 0.0f;
    _S681[int(29)] = 0.0f;
    _S681[int(30)] = 0.0f;
    _S681[int(31)] = 0.0f;
    _S681[int(32)] = 0.0f;
    _S681[int(22)] = _S439;
    _S681[int(21)] = _S674.differential_0;
    _S681[int(1)] = _S672;
    _S681[int(32)] = _S679.differential_0;
    _S681[int(0)] = _S678;
    FixedArray<float, 33>  _S682 = {
        _S581[int(0)] + _S681[int(0)], _S581[int(1)] + _S681[int(1)], _S581[int(2)] + _S681[int(2)], _S581[int(3)] + _S681[int(3)], _S581[int(4)] + _S681[int(4)], _S581[int(5)] + _S681[int(5)], _S581[int(6)] + _S681[int(6)], _S581[int(7)] + _S681[int(7)], _S581[int(8)] + _S681[int(8)], _S581[int(9)] + _S681[int(9)], _S581[int(10)] + _S681[int(10)], _S581[int(11)] + _S681[int(11)], _S581[int(12)] + _S681[int(12)], _S581[int(13)] + _S681[int(13)], _S581[int(14)] + _S681[int(14)], _S581[int(15)] + _S681[int(15)], _S581[int(16)] + _S681[int(16)], _S581[int(17)] + _S681[int(17)], _S581[int(18)] + _S681[int(18)], _S581[int(19)] + _S681[int(19)], _S581[int(20)] + _S681[int(20)], _S581[int(21)] + _S681[int(21)], _S581[int(22)] + _S681[int(22)], _S581[int(23)] + _S681[int(23)], _S581[int(24)] + _S681[int(24)], _S581[int(25)] + _S681[int(25)], _S581[int(26)] + _S681[int(26)], _S581[int(27)] + _S681[int(27)], _S581[int(28)] + _S681[int(28)], _S581[int(29)] + _S681[int(29)], _S581[int(30)] + _S681[int(30)], _S581[int(31)] + _S681[int(31)], _S581[int(32)] + _S681[int(32)]
    };
    dpraw_losses_0->primal_0 = dpraw_losses_0->primal_0;
    dpraw_losses_0->differential_0 = _S682;
    return;
}

inline __device__ void s_bwd_per_pixel_losses_reduce_0(DiffPair_arrayx3Cfloatx2C33x3E_0 * _S683, FixedArray<float, 20>  * _S684, FixedArray<float, 14>  * _S685)
{
    s_bwd_prop_per_pixel_losses_reduce_0(_S683, _S684, _S685);
    return;
}

inline __device__ void per_pixel_losses_reduce_bwd(FixedArray<float, 33>  raw_losses_1, FixedArray<float, 20>  weights_5, FixedArray<float, 14>  v_losses_1, FixedArray<float, 33>  * _S686)
{
    FixedArray<float, 33>  _S687 = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f };
    DiffPair_arrayx3Cfloatx2C33x3E_0 dp_raw_losses_0;
    (&dp_raw_losses_0)->primal_0 = raw_losses_1;
    (&dp_raw_losses_0)->differential_0 = _S687;
    FixedArray<float, 20>  _S688 = weights_5;
    FixedArray<float, 14>  _S689 = v_losses_1;
    s_bwd_per_pixel_losses_reduce_0(&dp_raw_losses_0, &_S688, &_S689);
    *_S686 = (&dp_raw_losses_0)->differential_0;
    return;
}


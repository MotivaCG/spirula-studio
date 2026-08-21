#pragma once

#include "generated/slang.cuh"

struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    float3  primal_0;
    float3  differential_0;
};

inline __device__ void _d_dot_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpy_0, float dOut_0)
{
    float3  x_d_result_0;
    *&((&x_d_result_0)->x) = (*dpy_0).primal_0.x * dOut_0;
    float3  y_d_result_0;
    *&((&y_d_result_0)->x) = (*dpx_0).primal_0.x * dOut_0;
    *&((&x_d_result_0)->y) = (*dpy_0).primal_0.y * dOut_0;
    *&((&y_d_result_0)->y) = (*dpx_0).primal_0.y * dOut_0;
    *&((&x_d_result_0)->z) = (*dpy_0).primal_0.z * dOut_0;
    *&((&y_d_result_0)->z) = (*dpx_0).primal_0.z * dOut_0;
    dpx_0->primal_0 = (*dpx_0).primal_0;
    dpx_0->differential_0 = x_d_result_0;
    dpy_0->primal_0 = (*dpy_0).primal_0;
    dpy_0->differential_0 = y_d_result_0;
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

struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};

inline __device__ void _d_max_0(DiffPair_float_0 * dpx_1, DiffPair_float_0 * dpy_1, float dOut_1)
{
    DiffPair_float_0 _S1 = *dpx_1;
    float _S2;
    if(((*dpx_1).primal_0) > ((*dpy_1).primal_0))
    {
        _S2 = dOut_1;
    }
    else
    {
        if(((*dpx_1).primal_0) < ((*dpy_1).primal_0))
        {
            _S2 = 0.0f;
        }
        else
        {
            _S2 = 0.5f * dOut_1;
        }
    }
    dpx_1->primal_0 = _S1.primal_0;
    dpx_1->differential_0 = _S2;
    DiffPair_float_0 _S3 = *dpy_1;
    if(((*dpy_1).primal_0) > (_S1.primal_0))
    {
        _S2 = dOut_1;
    }
    else
    {
        if(((*dpy_1).primal_0) < ((*dpx_1).primal_0))
        {
            _S2 = 0.0f;
        }
        else
        {
            _S2 = 0.5f * dOut_1;
        }
    }
    dpy_1->primal_0 = _S3.primal_0;
    dpy_1->differential_0 = _S2;
    return;
}

inline __device__ void _d_clamp_0(DiffPair_float_0 * dpx_2, DiffPair_float_0 * dpMin_0, DiffPair_float_0 * dpMax_0, float dOut_2)
{
    DiffPair_float_0 _S4 = *dpx_2;
    bool _S5;
    if(((*dpx_2).primal_0) >= ((*dpMin_0).primal_0))
    {
        _S5 = ((*dpx_2).primal_0) <= ((*dpMax_0).primal_0);
    }
    else
    {
        _S5 = false;
    }
    float _S6;
    if(_S5)
    {
        _S6 = dOut_2;
    }
    else
    {
        _S6 = 0.0f;
    }
    dpx_2->primal_0 = _S4.primal_0;
    dpx_2->differential_0 = _S6;
    DiffPair_float_0 _S7 = *dpMin_0;
    if((_S4.primal_0) < ((*dpMin_0).primal_0))
    {
        _S6 = dOut_2;
    }
    else
    {
        _S6 = 0.0f;
    }
    dpMin_0->primal_0 = _S7.primal_0;
    dpMin_0->differential_0 = _S6;
    DiffPair_float_0 _S8 = *dpMax_0;
    if(((*dpx_2).primal_0) > ((*dpMax_0).primal_0))
    {
        _S6 = dOut_2;
    }
    else
    {
        _S6 = 0.0f;
    }
    dpMax_0->primal_0 = _S8.primal_0;
    dpMax_0->differential_0 = _S6;
    return;
}

inline __device__ float clamp_0(float x_1, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_1), (minBound_0)))), (maxBound_0)));
}

inline __device__ void _d_abs_0(DiffPair_float_0 * dpx_3, float dOut_3)
{
    float _S9 = _slang_select(((*dpx_3).primal_0) > 0.0f, 1.0f,_slang_select(((*dpx_3).primal_0) == 0.0f, 0.0f,-1.0f)) * dOut_3;
    dpx_3->primal_0 = (*dpx_3).primal_0;
    dpx_3->differential_0 = _S9;
    return;
}

inline __device__ void _d_abs_vector_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_4, float3  dOut_4)
{
    float3  _S10 = _slang_select(((*dpx_4).primal_0) > make_float3 (0.0f), make_float3 (1.0f),_slang_select(((*dpx_4).primal_0) == make_float3 (0.0f), make_float3 (0.0f),make_float3 (-1.0f))) * dOut_4;
    dpx_4->primal_0 = (*dpx_4).primal_0;
    dpx_4->differential_0 = _S10;
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

inline __device__ void _d_sqrt_0(DiffPair_float_0 * dpx_5, float dOut_5)
{
    float _S11 = 0.5f / (F32_sqrt(((F32_max((1.00000001168609742e-07f), ((*dpx_5).primal_0)))))) * dOut_5;
    dpx_5->primal_0 = (*dpx_5).primal_0;
    dpx_5->differential_0 = _S11;
    return;
}

inline __device__ void _d_rsqrt_0(DiffPair_float_0 * dpx_6, float dOut_6)
{
    float _S12 = -0.5f / ((*dpx_6).primal_0 * (F32_sqrt(((*dpx_6).primal_0)))) * dOut_6;
    dpx_6->primal_0 = (*dpx_6).primal_0;
    dpx_6->differential_0 = _S12;
    return;
}

inline __device__ void _d_log_0(DiffPair_float_0 * dpx_7, float dOut_7)
{
    float _S13 = 1.0f / (*dpx_7).primal_0 * dOut_7;
    dpx_7->primal_0 = (*dpx_7).primal_0;
    dpx_7->differential_0 = _S13;
    return;
}

inline __device__ void _d_lerp_0(DiffPair_float_0 * dpx_8, DiffPair_float_0 * dpy_2, DiffPair_float_0 * dps_0, float dOut_8)
{
    float _S14 = (1.0f - (*dps_0).primal_0) * dOut_8;
    dpx_8->primal_0 = (*dpx_8).primal_0;
    dpx_8->differential_0 = _S14;
    DiffPair_float_0 _S15 = *dpy_2;
    float _S16 = (*dps_0).primal_0 * dOut_8;
    dpy_2->primal_0 = (*dpy_2).primal_0;
    dpy_2->differential_0 = _S16;
    float _S17 = (_S15.primal_0 - (*dpx_8).primal_0) * dOut_8;
    dps_0->primal_0 = _S15.primal_0;
    dps_0->differential_0 = _S17;
    return;
}

inline __device__ float lerp_0(float x_3, float y_1, float s_0)
{
    return x_3 + (y_1 - x_3) * s_0;
}

inline __device__ void per_pixel_losses(float3  render_rgb_0, float3  ref_rgb_0, float render_depth_0, float ref_depth_0, float3  render_normal_0, float3  depth_normal_0, float3  ref_normal_0, float render_Ts_0, float3  rgb_dist_0, float depth_dist_0, float3  normal_dist_0, float median_depth_0, float3  median_normal_0, bool ref_alpha_0, bool has_mask_0, FixedArray<float, 20>  weights_0, FixedArray<float, 33>  * _S18)
{
    bool _S19;
    bool _S20;
    bool _S21;
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
    bool depth_mask_0 = ref_depth_0 != 0.0f;
    bool normal_mask_0;
    if((ref_normal_0.x + ref_normal_0.y + ref_normal_0.z) > -2.36599993705749512f)
    {
        normal_mask_0 = (dot_0(ref_normal_0, ref_normal_0)) > 0.25f;
    }
    else
    {
        normal_mask_0 = false;
    }
    float3  _S22;
    float _S23 = render_rgb_0.x;
    float _S24 = render_rgb_0.y;
    float _S25 = render_rgb_0.z;
    float _S26 = ref_rgb_0.x;
    float _S27 = ref_rgb_0.y;
    float _S28 = ref_rgb_0.z;
    float Y_0 = 0.29899999499320984f * _S26 + 0.58700001239776611f * _S27 + 0.11400000005960464f * _S28;
    float dY_0 = 0.29899999499320984f * _S23 + 0.58700001239776611f * _S24 + 0.11400000005960464f * _S25 - Y_0;
    float dU_0 = -0.14712999761104584f * _S23 - 0.28885999321937561f * _S24 + 0.43599998950958252f * _S25 - (-0.14712999761104584f * _S26 - 0.28885999321937561f * _S27 + 0.43599998950958252f * _S28);
    float dV_0 = 0.61500000953674316f * _S23 - 0.51498997211456299f * _S24 - 0.10001000016927719f * _S25 - (0.61500000953674316f * _S26 - 0.51498997211456299f * _S27 - 0.10001000016927719f * _S28);
    float _S29 = float(mask_0);
    float _S30 = _S29 * (1.0f + weights_0[int(19)] * clamp_0(1.0f - Y_0, 0.0f, 1.0f));
    float3  _S31 = ref_rgb_0 - render_rgb_0;
    float3  _S32 = abs_0(_S31);
    float _S33 = dot_0(_S31, _S31) * 0.3333333432674408f;
    losses_0[int(0)] = _S30 * (weights_0[int(0)] * ((_S32.x + _S32.y + _S32.z) * 0.3333333432674408f) + weights_0[int(1)] * _S33 + weights_0[int(2)] * (F32_abs((dY_0))) + weights_0[int(3)] * dY_0 * dY_0 + weights_0[int(4)] * dU_0 * dU_0 + weights_0[int(5)] * dV_0 * dV_0);
    losses_0[int(1)] = _S29 * clamp_0(_S33, 0.0f, 1.0f);
    float _S34 = float(depth_mask_0 & mask_0);
    float _S35 = _S34 * (F32_max((render_depth_0), (0.00009999999747379f)));
    float _S36 = _S34 * (F32_max((ref_depth_0), (0.00009999999747379f)));
    losses_0[int(2)] = _S35;
    losses_0[int(3)] = _S36;
    losses_0[int(4)] = _S35 * _S35;
    losses_0[int(5)] = _S36 * _S36;
    losses_0[int(6)] = _S35 * _S36;
    bool _S37 = normal_mask_0 & mask_0;
    for(;;)
    {
        float norm2_0 = dot_0(render_normal_0, render_normal_0);
        bool _S38 = norm2_0 == 0.0f;
        _S19 = _S38;
        if(_S38)
        {
            _S22 = make_float3 (0.0f);
            break;
        }
        _S22 = render_normal_0 * make_float3 ((F32_rsqrt((norm2_0))));
        break;
    }
    float3  _S39;
    bool _S40 = !_S19;
    for(;;)
    {
        float norm2_1 = dot_0(depth_normal_0, depth_normal_0);
        bool _S41 = norm2_1 == 0.0f;
        _S20 = _S41;
        if(_S41)
        {
            _S39 = make_float3 (0.0f);
            break;
        }
        _S39 = depth_normal_0 * make_float3 ((F32_rsqrt((norm2_1))));
        break;
    }
    float3  _S42;
    bool _S43 = !_S20;
    for(;;)
    {
        float norm2_2 = dot_0(ref_normal_0, ref_normal_0);
        if(norm2_2 == 0.0f)
        {
            _S42 = make_float3 (0.0f);
            normal_mask_0 = false;
            break;
        }
        _S42 = ref_normal_0 * make_float3 ((F32_rsqrt((norm2_2))));
        normal_mask_0 = _S37;
        break;
    }
    float3  _S44;
    float _S45 = float(_S40 & normal_mask_0);
    float cos_sim_loss_0 = 0.5f - 0.5f * dot_0(_S22, _S42);
    losses_0[int(7)] = weights_0[int(7)] * _S45 * (cos_sim_loss_0 + (F32_sqrt(((F32_max((cos_sim_loss_0), (9.999999960041972e-13f)))))));
    float _S46 = float(_S43 & normal_mask_0);
    float cos_sim_loss_1 = 0.5f - 0.5f * dot_0(_S39, _S42);
    losses_0[int(8)] = weights_0[int(7)] * _S46 * (cos_sim_loss_1 + (F32_sqrt(((F32_max((cos_sim_loss_1), (9.999999960041972e-13f)))))));
    float _S47 = float(_S40 & _S43);
    float cos_sim_loss_2 = 0.5f - 0.5f * dot_0(_S22, _S39);
    losses_0[int(11)] = weights_0[int(10)] * _S47 * (cos_sim_loss_2 + (F32_sqrt(((F32_max((cos_sim_loss_2), (9.999999960041972e-13f)))))));
    for(;;)
    {
        float norm2_3 = dot_0(median_normal_0, median_normal_0);
        bool _S48 = norm2_3 == 0.0f;
        _S21 = _S48;
        if(_S48)
        {
            _S44 = make_float3 (0.0f);
            break;
        }
        _S44 = median_normal_0 * make_float3 ((F32_rsqrt((norm2_3))));
        break;
    }
    bool _S49 = !_S21;
    if(mask_0)
    {
        mask_0 = render_depth_0 > 1.00000001335143196e-10f;
    }
    else
    {
        mask_0 = false;
    }
    bool mean_median_mask_0;
    if(mask_0)
    {
        mean_median_mask_0 = median_depth_0 > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_0 = false;
    }
    float _S50 = float(mean_median_mask_0);
    losses_0[int(16)] = weights_0[int(15)] * _S50 * (F32_abs(((F32_log(((F32_max((render_depth_0), (1.00000001335143196e-10f)))))) - (F32_log(((F32_max((median_depth_0), (1.00000001335143196e-10f)))))))));
    float _S51 = float(_S49 & _S43);
    float cos_sim_loss_3 = 0.5f - 0.5f * dot_0(_S44, _S39);
    losses_0[int(17)] = weights_0[int(16)] * _S51 * (cos_sim_loss_3 + (F32_sqrt(((F32_max((cos_sim_loss_3), (9.999999960041972e-13f)))))));
    float _S52 = float(_S49 & normal_mask_0);
    float cos_sim_loss_4 = 0.5f - 0.5f * dot_0(_S44, _S42);
    losses_0[int(18)] = weights_0[int(17)] * _S52 * (cos_sim_loss_4 + (F32_sqrt(((F32_max((cos_sim_loss_4), (9.999999960041972e-13f)))))));
    float _S53 = float(_S49 & _S40);
    float cos_sim_loss_5 = 0.5f - 0.5f * dot_0(_S44, _S22);
    losses_0[int(19)] = weights_0[int(18)] * _S53 * (cos_sim_loss_5 + (F32_sqrt(((F32_max((cos_sim_loss_5), (9.999999960041972e-13f)))))));
    float render_alpha_0 = clamp_0(1.0f - render_Ts_0, 0.0f, 1.0f);
    float _S54 = float(has_mask_0);
    float _S55 = float(ref_alpha_0);
    float _S56 = (F32_max((render_alpha_0), (_S55)));
    losses_0[int(9)] = weights_0[int(8)] * _S54 * - lerp_0((F32_log(((F32_max((1.0f - _S56), (9.99999997475242708e-07f)))))), (F32_log(((F32_max((_S56), (9.99999997475242708e-07f)))))), _S55);
    float _S57 = 1.0f - render_alpha_0;
    float _S58 = 1.0f - _S55;
    float _S59 = (F32_max((_S57), (_S58)));
    losses_0[int(10)] = weights_0[int(9)] * _S54 * - lerp_0((F32_log(((F32_max((1.0f - _S59), (9.99999997475242708e-07f)))))), (F32_log(((F32_max((_S59), (9.99999997475242708e-07f)))))), _S58);
    losses_0[int(12)] = weights_0[int(11)] * 4.0f * render_alpha_0 * _S57;
    losses_0[int(13)] = weights_0[int(12)] * ((rgb_dist_0.x + rgb_dist_0.y + rgb_dist_0.z) * 0.3333333432674408f);
    losses_0[int(14)] = weights_0[int(13)] * depth_dist_0;
    losses_0[int(15)] = weights_0[int(14)] * ((normal_dist_0.x + normal_dist_0.y + normal_dist_0.z) * 0.3333333432674408f);
    losses_0[int(20)] = 1.0f;
    losses_0[int(21)] = _S29;
    losses_0[int(22)] = _S34;
    losses_0[int(23)] = _S45;
    losses_0[int(24)] = _S46;
    losses_0[int(25)] = _S47;
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
    losses_0[int(28)] = _S50;
    losses_0[int(29)] = _S51;
    losses_0[int(30)] = _S52;
    losses_0[int(31)] = _S53;
    losses_0[int(32)] = _S30;
    *_S18 = losses_0;
    return;
}

inline __device__ float s_primal_ctx_dot_0(float3  _S60, float3  _S61)
{
    return dot_0(_S60, _S61);
}

inline __device__ float s_primal_ctx_clamp_0(float _S62, float _S63, float _S64)
{
    return clamp_0(_S62, _S63, _S64);
}

inline __device__ float s_primal_ctx_rsqrt_0(float _S65)
{
    return (F32_rsqrt((_S65)));
}

inline __device__ float s_primal_ctx_log_0(float _S66)
{
    return (F32_log((_S66)));
}

inline __device__ void s_bwd_prop_lerp_0(DiffPair_float_0 * _S67, DiffPair_float_0 * _S68, DiffPair_float_0 * _S69, float _S70)
{
    _d_lerp_0(_S67, _S68, _S69, _S70);
    return;
}

inline __device__ void s_bwd_prop_log_0(DiffPair_float_0 * _S71, float _S72)
{
    _d_log_0(_S71, _S72);
    return;
}

inline __device__ void s_bwd_prop_clamp_0(DiffPair_float_0 * _S73, DiffPair_float_0 * _S74, DiffPair_float_0 * _S75, float _S76)
{
    _d_clamp_0(_S73, _S74, _S75, _S76);
    return;
}

inline __device__ void s_bwd_prop_sqrt_0(DiffPair_float_0 * _S77, float _S78)
{
    _d_sqrt_0(_S77, _S78);
    return;
}

inline __device__ void s_bwd_prop_dot_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S79, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S80, float _S81)
{
    _d_dot_0(_S79, _S80, _S81);
    return;
}

inline __device__ void s_bwd_prop_abs_0(DiffPair_float_0 * _S82, float _S83)
{
    _d_abs_0(_S82, _S83);
    return;
}

inline __device__ void s_bwd_prop_rsqrt_0(DiffPair_float_0 * _S84, float _S85)
{
    _d_rsqrt_0(_S84, _S85);
    return;
}

inline __device__ void s_bwd_prop_abs_1(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S86, float3  _S87)
{
    _d_abs_vector_0(_S86, _S87);
    return;
}

inline __device__ void s_bwd_prop_per_pixel_losses_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dprender_rgb_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpref_rgb_0, DiffPair_float_0 * dprender_depth_0, DiffPair_float_0 * dpref_depth_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dprender_normal_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpdepth_normal_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpref_normal_0, DiffPair_float_0 * dprender_Ts_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dprgb_dist_0, DiffPair_float_0 * dpdepth_dist_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpnormal_dist_0, DiffPair_float_0 * dpmedian_depth_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpmedian_normal_0, bool ref_alpha_1, bool has_mask_1, FixedArray<float, 20>  * weights_1, FixedArray<float, 33>  * _s_dOut_0)
{
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S88 = *dprender_rgb_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S89 = *dpref_rgb_0;
    DiffPair_float_0 _S90 = *dprender_depth_0;
    DiffPair_float_0 _S91 = *dpref_depth_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S92 = *dprender_normal_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S93 = *dpdepth_normal_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S94 = *dpref_normal_0;
    DiffPair_float_0 _S95 = *dprender_Ts_0;
    DiffPair_float_0 _S96 = *dpmedian_depth_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S97 = *dpmedian_normal_0;
    float3  _S98 = make_float3 (0.0f);
    bool mask_1;
    if(has_mask_1)
    {
        mask_1 = ref_alpha_1;
    }
    else
    {
        mask_1 = true;
    }
    bool depth_mask_1 = (_S91.primal_0) != 0.0f;
    bool _S99 = (_S94.primal_0.x + _S94.primal_0.y + _S94.primal_0.z) > -2.36599993705749512f;
    bool normal_mask_1;
    if(_S99)
    {
        normal_mask_1 = (s_primal_ctx_dot_0(_S94.primal_0, _S94.primal_0)) > 0.25f;
    }
    else
    {
        normal_mask_1 = false;
    }
    float _S100 = _S88.primal_0.x;
    float _S101 = _S88.primal_0.y;
    float _S102 = _S88.primal_0.z;
    float _S103 = _S89.primal_0.x;
    float _S104 = _S89.primal_0.y;
    float _S105 = _S89.primal_0.z;
    float Y_1 = 0.29899999499320984f * _S103 + 0.58700001239776611f * _S104 + 0.11400000005960464f * _S105;
    float dY_1 = 0.29899999499320984f * _S100 + 0.58700001239776611f * _S101 + 0.11400000005960464f * _S102 - Y_1;
    float dU_1 = -0.14712999761104584f * _S100 - 0.28885999321937561f * _S101 + 0.43599998950958252f * _S102 - (-0.14712999761104584f * _S103 - 0.28885999321937561f * _S104 + 0.43599998950958252f * _S105);
    float dV_1 = 0.61500000953674316f * _S100 - 0.51498997211456299f * _S101 - 0.10001000016927719f * _S102 - (0.61500000953674316f * _S103 - 0.51498997211456299f * _S104 - 0.10001000016927719f * _S105);
    float _S106 = float(mask_1);
    float _S107 = _S106 * (1.0f + (*weights_1)[int(19)] * s_primal_ctx_clamp_0(1.0f - Y_1, 0.0f, 1.0f));
    float _S108 = (*weights_1)[int(0)];
    float3  _S109 = _S89.primal_0 - _S88.primal_0;
    float _S110 = (*weights_1)[int(1)];
    float _S111 = s_primal_ctx_dot_0(_S109, _S109) * 0.3333333432674408f;
    float _S112 = (*weights_1)[int(2)];
    float _S113 = (*weights_1)[int(3)];
    float _S114 = (*weights_1)[int(3)] * dY_1;
    float _S115 = (*weights_1)[int(4)];
    float _S116 = (*weights_1)[int(4)] * dU_1;
    float _S117 = (*weights_1)[int(5)];
    float _S118 = (*weights_1)[int(5)] * dV_1;
    float _S119 = float(depth_mask_1 & mask_1);
    float _S120 = _S119 * (F32_max((_S90.primal_0), (0.00009999999747379f)));
    float _S121 = _S119 * (F32_max((_S91.primal_0), (0.00009999999747379f)));
    bool _S122 = normal_mask_1 & mask_1;
    float _S123 = s_primal_ctx_dot_0(_S92.primal_0, _S92.primal_0);
    bool _S124 = _S123 == 0.0f;
    float3  _S125;
    if(_S124)
    {
        _S125 = make_float3 (0.0f);
    }
    bool _S126 = !_S124;
    float3  _S127;
    if(_S126)
    {
        float _S128 = s_primal_ctx_rsqrt_0(_S123);
        float3  _S129 = make_float3 (_S128);
        _S125 = _S92.primal_0 * make_float3 (_S128);
        _S127 = _S129;
    }
    else
    {
        _S127 = _S98;
    }
    float _S130 = s_primal_ctx_dot_0(_S93.primal_0, _S93.primal_0);
    bool _S131 = _S130 == 0.0f;
    float3  _S132;
    if(_S131)
    {
        _S132 = make_float3 (0.0f);
    }
    bool _S133 = !_S131;
    float3  _S134;
    if(_S133)
    {
        float _S135 = s_primal_ctx_rsqrt_0(_S130);
        float3  _S136 = make_float3 (_S135);
        _S132 = _S93.primal_0 * make_float3 (_S135);
        _S134 = _S136;
    }
    else
    {
        _S134 = _S98;
    }
    float _S137 = s_primal_ctx_dot_0(_S94.primal_0, _S94.primal_0);
    bool _S138 = _S137 == 0.0f;
    float3  _S139;
    if(_S138)
    {
        float3  _S140 = make_float3 (0.0f);
        normal_mask_1 = false;
        _S139 = _S140;
    }
    else
    {
        normal_mask_1 = _S122;
    }
    bool _S141 = !_S138;
    float3  _S142;
    if(_S141)
    {
        float _S143 = s_primal_ctx_rsqrt_0(_S137);
        float3  _S144 = make_float3 (_S143);
        _S139 = _S94.primal_0 * make_float3 (_S143);
        _S142 = _S144;
    }
    else
    {
        _S142 = _S98;
    }
    float _S145 = (*weights_1)[int(7)] * float(_S126 & normal_mask_1);
    float cos_sim_loss_6 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S125, _S139);
    float _S146 = (F32_max((cos_sim_loss_6), (9.999999960041972e-13f)));
    float _S147 = (*weights_1)[int(7)] * float(_S133 & normal_mask_1);
    float cos_sim_loss_7 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S132, _S139);
    float _S148 = (F32_max((cos_sim_loss_7), (9.999999960041972e-13f)));
    float _S149 = (*weights_1)[int(10)] * float(_S126 & _S133);
    float cos_sim_loss_8 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S125, _S132);
    float _S150 = (F32_max((cos_sim_loss_8), (9.999999960041972e-13f)));
    float _S151 = s_primal_ctx_dot_0(_S97.primal_0, _S97.primal_0);
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
        _S153 = _S97.primal_0 * make_float3 (_S156);
        _S155 = _S157;
    }
    else
    {
        _S155 = _S98;
    }
    if(mask_1)
    {
        mask_1 = (_S90.primal_0) > 1.00000001335143196e-10f;
    }
    else
    {
        mask_1 = false;
    }
    bool mean_median_mask_1;
    if(mask_1)
    {
        mean_median_mask_1 = (_S96.primal_0) > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_1 = false;
    }
    float _S158 = (*weights_1)[int(15)] * float(mean_median_mask_1);
    float _S159 = (F32_max((_S90.primal_0), (1.00000001335143196e-10f)));
    float _S160 = (F32_max((_S96.primal_0), (1.00000001335143196e-10f)));
    float _S161 = s_primal_ctx_log_0(_S159) - s_primal_ctx_log_0(_S160);
    float _S162 = (*weights_1)[int(16)] * float(_S154 & _S133);
    float cos_sim_loss_9 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S153, _S132);
    float _S163 = (F32_max((cos_sim_loss_9), (9.999999960041972e-13f)));
    float _S164 = (*weights_1)[int(17)] * float(_S154 & normal_mask_1);
    float cos_sim_loss_10 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S153, _S139);
    float _S165 = (F32_max((cos_sim_loss_10), (9.999999960041972e-13f)));
    float _S166 = (*weights_1)[int(18)] * float(_S154 & _S126);
    float cos_sim_loss_11 = 0.5f - 0.5f * s_primal_ctx_dot_0(_S153, _S125);
    float _S167 = (F32_max((cos_sim_loss_11), (9.999999960041972e-13f)));
    float _S168 = 1.0f - _S95.primal_0;
    float _S169 = s_primal_ctx_clamp_0(_S168, 0.0f, 1.0f);
    float _S170 = float(has_mask_1);
    float _S171 = (*weights_1)[int(8)] * _S170;
    float _S172 = float(ref_alpha_1);
    float _S173 = (F32_max((_S169), (_S172)));
    float _S174 = 1.0f - _S173;
    float _S175 = (F32_max((_S174), (9.99999997475242708e-07f)));
    float _S176 = s_primal_ctx_log_0(_S175);
    float _S177 = (F32_max((_S173), (9.99999997475242708e-07f)));
    float _S178 = s_primal_ctx_log_0(_S177);
    float _S179 = (*weights_1)[int(9)] * _S170;
    float _S180 = 1.0f - _S169;
    float _S181 = 1.0f - _S172;
    float _S182 = (F32_max((_S180), (_S181)));
    float _S183 = 1.0f - _S182;
    float _S184 = (F32_max((_S183), (9.99999997475242708e-07f)));
    float _S185 = s_primal_ctx_log_0(_S184);
    float _S186 = (F32_max((_S182), (9.99999997475242708e-07f)));
    float _S187 = s_primal_ctx_log_0(_S186);
    float _S188 = (*weights_1)[int(11)] * 4.0f;
    float _S189 = _S188 * _S169;
    float _S190 = (*weights_1)[int(12)];
    float _S191 = (*weights_1)[int(13)];
    float _S192 = (*weights_1)[int(14)];
    float _S193 = (*_s_dOut_0)[int(0)];
    float _S194 = (*_s_dOut_0)[int(1)];
    float _S195 = (*_s_dOut_0)[int(2)];
    float _S196 = (*_s_dOut_0)[int(3)];
    float _S197 = (*_s_dOut_0)[int(4)];
    float _S198 = (*_s_dOut_0)[int(5)];
    float _S199 = (*_s_dOut_0)[int(6)];
    float _S200 = (*_s_dOut_0)[int(7)];
    float _S201 = (*_s_dOut_0)[int(8)];
    float _S202 = (*_s_dOut_0)[int(11)];
    float _S203 = 0.3333333432674408f * (_S192 * (*_s_dOut_0)[int(15)]);
    float _S204 = _S191 * (*_s_dOut_0)[int(14)];
    float _S205 = 0.3333333432674408f * (_S190 * (*_s_dOut_0)[int(13)]);
    float _S206 = _S189 * (*_s_dOut_0)[int(12)];
    float _S207 = _S188 * (_S180 * (*_s_dOut_0)[int(12)]);
    float _S208 = - (_S179 * (*_s_dOut_0)[int(10)]);
    DiffPair_float_0 _S209;
    (&_S209)->primal_0 = _S185;
    (&_S209)->differential_0 = 0.0f;
    DiffPair_float_0 _S210;
    (&_S210)->primal_0 = _S187;
    (&_S210)->differential_0 = 0.0f;
    DiffPair_float_0 _S211;
    (&_S211)->primal_0 = _S181;
    (&_S211)->differential_0 = 0.0f;
    s_bwd_prop_lerp_0(&_S209, &_S210, &_S211, _S208);
    DiffPair_float_0 _S212;
    (&_S212)->primal_0 = _S186;
    (&_S212)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S212, _S210.differential_0);
    DiffPair_float_0 _S213;
    (&_S213)->primal_0 = _S182;
    (&_S213)->differential_0 = 0.0f;
    DiffPair_float_0 _S214;
    (&_S214)->primal_0 = 9.99999997475242708e-07f;
    (&_S214)->differential_0 = 0.0f;
    _d_max_0(&_S213, &_S214, _S212.differential_0);
    DiffPair_float_0 _S215;
    (&_S215)->primal_0 = _S184;
    (&_S215)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S215, _S209.differential_0);
    DiffPair_float_0 _S216;
    (&_S216)->primal_0 = _S183;
    (&_S216)->differential_0 = 0.0f;
    DiffPair_float_0 _S217;
    (&_S217)->primal_0 = 9.99999997475242708e-07f;
    (&_S217)->differential_0 = 0.0f;
    _d_max_0(&_S216, &_S217, _S215.differential_0);
    float _S218 = _S213.differential_0 + - _S216.differential_0;
    DiffPair_float_0 _S219;
    (&_S219)->primal_0 = _S180;
    (&_S219)->differential_0 = 0.0f;
    DiffPair_float_0 _S220;
    (&_S220)->primal_0 = _S181;
    (&_S220)->differential_0 = 0.0f;
    _d_max_0(&_S219, &_S220, _S218);
    float _S221 = - (_S206 + _S219.differential_0);
    float _S222 = - (_S171 * (*_s_dOut_0)[int(9)]);
    DiffPair_float_0 _S223;
    (&_S223)->primal_0 = _S176;
    (&_S223)->differential_0 = 0.0f;
    DiffPair_float_0 _S224;
    (&_S224)->primal_0 = _S178;
    (&_S224)->differential_0 = 0.0f;
    DiffPair_float_0 _S225;
    (&_S225)->primal_0 = _S172;
    (&_S225)->differential_0 = 0.0f;
    s_bwd_prop_lerp_0(&_S223, &_S224, &_S225, _S222);
    DiffPair_float_0 _S226;
    (&_S226)->primal_0 = _S177;
    (&_S226)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S226, _S224.differential_0);
    DiffPair_float_0 _S227;
    (&_S227)->primal_0 = _S173;
    (&_S227)->differential_0 = 0.0f;
    DiffPair_float_0 _S228;
    (&_S228)->primal_0 = 9.99999997475242708e-07f;
    (&_S228)->differential_0 = 0.0f;
    _d_max_0(&_S227, &_S228, _S226.differential_0);
    DiffPair_float_0 _S229;
    (&_S229)->primal_0 = _S175;
    (&_S229)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S229, _S223.differential_0);
    DiffPair_float_0 _S230;
    (&_S230)->primal_0 = _S174;
    (&_S230)->differential_0 = 0.0f;
    DiffPair_float_0 _S231;
    (&_S231)->primal_0 = 9.99999997475242708e-07f;
    (&_S231)->differential_0 = 0.0f;
    _d_max_0(&_S230, &_S231, _S229.differential_0);
    float _S232 = _S227.differential_0 + - _S230.differential_0;
    DiffPair_float_0 _S233;
    (&_S233)->primal_0 = _S169;
    (&_S233)->differential_0 = 0.0f;
    DiffPair_float_0 _S234;
    (&_S234)->primal_0 = _S172;
    (&_S234)->differential_0 = 0.0f;
    _d_max_0(&_S233, &_S234, _S232);
    float _S235 = _S207 + _S221 + _S233.differential_0;
    DiffPair_float_0 _S236;
    (&_S236)->primal_0 = _S168;
    (&_S236)->differential_0 = 0.0f;
    DiffPair_float_0 _S237;
    (&_S237)->primal_0 = 0.0f;
    (&_S237)->differential_0 = 0.0f;
    DiffPair_float_0 _S238;
    (&_S238)->primal_0 = 1.0f;
    (&_S238)->differential_0 = 0.0f;
    s_bwd_prop_clamp_0(&_S236, &_S237, &_S238, _S235);
    float _S239 = - _S236.differential_0;
    float _S240 = _S166 * (*_s_dOut_0)[int(19)];
    DiffPair_float_0 _S241;
    (&_S241)->primal_0 = _S167;
    (&_S241)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S241, _S240);
    DiffPair_float_0 _S242;
    (&_S242)->primal_0 = cos_sim_loss_11;
    (&_S242)->differential_0 = 0.0f;
    DiffPair_float_0 _S243;
    (&_S243)->primal_0 = 9.999999960041972e-13f;
    (&_S243)->differential_0 = 0.0f;
    _d_max_0(&_S242, &_S243, _S241.differential_0);
    float _S244 = 0.5f * - (_S240 + _S242.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S245;
    (&_S245)->primal_0 = _S153;
    (&_S245)->differential_0 = _S98;
    float3  _S246 = _S125;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S247;
    (&_S247)->primal_0 = _S125;
    (&_S247)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S245, &_S247, _S244);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S248 = _S247;
    float _S249 = _S164 * (*_s_dOut_0)[int(18)];
    DiffPair_float_0 _S250;
    (&_S250)->primal_0 = _S165;
    (&_S250)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S250, _S249);
    DiffPair_float_0 _S251;
    (&_S251)->primal_0 = cos_sim_loss_10;
    (&_S251)->differential_0 = 0.0f;
    DiffPair_float_0 _S252;
    (&_S252)->primal_0 = 9.999999960041972e-13f;
    (&_S252)->differential_0 = 0.0f;
    _d_max_0(&_S251, &_S252, _S250.differential_0);
    float _S253 = 0.5f * - (_S249 + _S251.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S254;
    (&_S254)->primal_0 = _S153;
    (&_S254)->differential_0 = _S98;
    float3  _S255 = _S139;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S256;
    (&_S256)->primal_0 = _S139;
    (&_S256)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S254, &_S256, _S253);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S257 = _S256;
    float _S258 = _S162 * (*_s_dOut_0)[int(17)];
    DiffPair_float_0 _S259;
    (&_S259)->primal_0 = _S163;
    (&_S259)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S259, _S258);
    DiffPair_float_0 _S260;
    (&_S260)->primal_0 = cos_sim_loss_9;
    (&_S260)->differential_0 = 0.0f;
    DiffPair_float_0 _S261;
    (&_S261)->primal_0 = 9.999999960041972e-13f;
    (&_S261)->differential_0 = 0.0f;
    _d_max_0(&_S260, &_S261, _S259.differential_0);
    float _S262 = 0.5f * - (_S258 + _S260.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S263;
    (&_S263)->primal_0 = _S153;
    (&_S263)->differential_0 = _S98;
    float3  _S264 = _S132;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S265;
    (&_S265)->primal_0 = _S132;
    (&_S265)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S263, &_S265, _S262);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S266 = _S265;
    float _S267 = _S158 * (*_s_dOut_0)[int(16)];
    DiffPair_float_0 _S268;
    (&_S268)->primal_0 = _S161;
    (&_S268)->differential_0 = 0.0f;
    s_bwd_prop_abs_0(&_S268, _S267);
    float _S269 = - _S268.differential_0;
    DiffPair_float_0 _S270;
    (&_S270)->primal_0 = _S160;
    (&_S270)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S270, _S269);
    DiffPair_float_0 _S271;
    (&_S271)->primal_0 = _S96.primal_0;
    (&_S271)->differential_0 = 0.0f;
    DiffPair_float_0 _S272;
    (&_S272)->primal_0 = 1.00000001335143196e-10f;
    (&_S272)->differential_0 = 0.0f;
    _d_max_0(&_S271, &_S272, _S270.differential_0);
    DiffPair_float_0 _S273 = _S271;
    DiffPair_float_0 _S274;
    (&_S274)->primal_0 = _S159;
    (&_S274)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S274, _S268.differential_0);
    DiffPair_float_0 _S275;
    (&_S275)->primal_0 = _S90.primal_0;
    (&_S275)->differential_0 = 0.0f;
    DiffPair_float_0 _S276;
    (&_S276)->primal_0 = 1.00000001335143196e-10f;
    (&_S276)->differential_0 = 0.0f;
    _d_max_0(&_S275, &_S276, _S274.differential_0);
    DiffPair_float_0 _S277 = _S275;
    float3  _S278 = make_float3 (_S203, _S203, _S203);
    float3  _S279 = make_float3 (_S205, _S205, _S205);
    float3  _S280 = _S245.differential_0 + _S254.differential_0 + _S263.differential_0;
    float _S281;
    if(_S154)
    {
        float3  _S282 = _S97.primal_0 * _S280;
        float3  _S283 = _S155 * _S280;
        float _S284 = _S282.x + _S282.y + _S282.z;
        DiffPair_float_0 _S285;
        (&_S285)->primal_0 = _S151;
        (&_S285)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S285, _S284);
        _S281 = _S285.differential_0;
        _S125 = _S283;
    }
    else
    {
        _S281 = 0.0f;
        _S125 = _S98;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S286;
    (&_S286)->primal_0 = _S97.primal_0;
    (&_S286)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S287;
    (&_S287)->primal_0 = _S97.primal_0;
    (&_S287)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S286, &_S287, _S281);
    float _S288 = _S149 * _S202;
    DiffPair_float_0 _S289;
    (&_S289)->primal_0 = _S150;
    (&_S289)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S289, _S288);
    DiffPair_float_0 _S290;
    (&_S290)->primal_0 = cos_sim_loss_8;
    (&_S290)->differential_0 = 0.0f;
    DiffPair_float_0 _S291;
    (&_S291)->primal_0 = 9.999999960041972e-13f;
    (&_S291)->differential_0 = 0.0f;
    _d_max_0(&_S290, &_S291, _S289.differential_0);
    float _S292 = 0.5f * - (_S288 + _S290.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S293;
    (&_S293)->primal_0 = _S246;
    (&_S293)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S294;
    (&_S294)->primal_0 = _S264;
    (&_S294)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S293, &_S294, _S292);
    float _S295 = _S147 * _S201;
    DiffPair_float_0 _S296;
    (&_S296)->primal_0 = _S148;
    (&_S296)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S296, _S295);
    DiffPair_float_0 _S297;
    (&_S297)->primal_0 = cos_sim_loss_7;
    (&_S297)->differential_0 = 0.0f;
    DiffPair_float_0 _S298;
    (&_S298)->primal_0 = 9.999999960041972e-13f;
    (&_S298)->differential_0 = 0.0f;
    _d_max_0(&_S297, &_S298, _S296.differential_0);
    float _S299 = 0.5f * - (_S295 + _S297.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S300;
    (&_S300)->primal_0 = _S264;
    (&_S300)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S301;
    (&_S301)->primal_0 = _S255;
    (&_S301)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S300, &_S301, _S299);
    float _S302 = _S145 * _S200;
    DiffPair_float_0 _S303;
    (&_S303)->primal_0 = _S146;
    (&_S303)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S303, _S302);
    DiffPair_float_0 _S304;
    (&_S304)->primal_0 = cos_sim_loss_6;
    (&_S304)->differential_0 = 0.0f;
    DiffPair_float_0 _S305;
    (&_S305)->primal_0 = 9.999999960041972e-13f;
    (&_S305)->differential_0 = 0.0f;
    _d_max_0(&_S304, &_S305, _S303.differential_0);
    float _S306 = 0.5f * - (_S302 + _S304.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S307;
    (&_S307)->primal_0 = _S246;
    (&_S307)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S308;
    (&_S308)->primal_0 = _S255;
    (&_S308)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S307, &_S308, _S306);
    float3  _S309 = _S287.differential_0 + _S286.differential_0 + _S125;
    float3  _S310 = _S294.differential_0 + _S300.differential_0 + _S266.differential_0;
    float3  _S311 = _S293.differential_0 + _S307.differential_0 + _S248.differential_0;
    float3  _S312 = _S301.differential_0 + _S308.differential_0 + _S257.differential_0;
    if(_S141)
    {
        float3  _S313 = _S94.primal_0 * _S312;
        float3  _S314 = _S142 * _S312;
        float _S315 = _S313.x + _S313.y + _S313.z;
        DiffPair_float_0 _S316;
        (&_S316)->primal_0 = _S137;
        (&_S316)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S316, _S315);
        _S281 = _S316.differential_0;
        _S125 = _S314;
    }
    else
    {
        _S281 = 0.0f;
        _S125 = _S98;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S317;
    (&_S317)->primal_0 = _S94.primal_0;
    (&_S317)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S318;
    (&_S318)->primal_0 = _S94.primal_0;
    (&_S318)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S317, &_S318, _S281);
    float3  _S319 = _S318.differential_0 + _S317.differential_0 + _S125;
    if(_S133)
    {
        float3  _S320 = _S93.primal_0 * _S310;
        float3  _S321 = _S134 * _S310;
        float _S322 = _S320.x + _S320.y + _S320.z;
        DiffPair_float_0 _S323;
        (&_S323)->primal_0 = _S130;
        (&_S323)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S323, _S322);
        _S281 = _S323.differential_0;
        _S125 = _S321;
    }
    else
    {
        _S281 = 0.0f;
        _S125 = _S98;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S324;
    (&_S324)->primal_0 = _S93.primal_0;
    (&_S324)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S325;
    (&_S325)->primal_0 = _S93.primal_0;
    (&_S325)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S324, &_S325, _S281);
    float3  _S326 = _S325.differential_0 + _S324.differential_0 + _S125;
    if(_S126)
    {
        float3  _S327 = _S92.primal_0 * _S311;
        float3  _S328 = _S127 * _S311;
        float _S329 = _S327.x + _S327.y + _S327.z;
        DiffPair_float_0 _S330;
        (&_S330)->primal_0 = _S123;
        (&_S330)->differential_0 = 0.0f;
        s_bwd_prop_rsqrt_0(&_S330, _S329);
        _S281 = _S330.differential_0;
        _S125 = _S328;
    }
    else
    {
        _S281 = 0.0f;
        _S125 = _S98;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S331;
    (&_S331)->primal_0 = _S92.primal_0;
    (&_S331)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S332;
    (&_S332)->primal_0 = _S92.primal_0;
    (&_S332)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S331, &_S332, _S281);
    float3  _S333 = _S332.differential_0 + _S331.differential_0 + _S125;
    float _S334 = _S121 * _S199;
    float _S335 = _S121 * _S198;
    float _S336 = _S120 * _S197;
    float _S337 = _S119 * (_S120 * _S199 + _S335 + _S335 + _S196);
    DiffPair_float_0 _S338;
    (&_S338)->primal_0 = _S91.primal_0;
    (&_S338)->differential_0 = 0.0f;
    DiffPair_float_0 _S339;
    (&_S339)->primal_0 = 0.00009999999747379f;
    (&_S339)->differential_0 = 0.0f;
    _d_max_0(&_S338, &_S339, _S337);
    DiffPair_float_0 _S340 = _S338;
    float _S341 = _S119 * (_S334 + _S336 + _S336 + _S195);
    DiffPair_float_0 _S342;
    (&_S342)->primal_0 = _S90.primal_0;
    (&_S342)->differential_0 = 0.0f;
    DiffPair_float_0 _S343;
    (&_S343)->primal_0 = 0.00009999999747379f;
    (&_S343)->differential_0 = 0.0f;
    _d_max_0(&_S342, &_S343, _S341);
    float _S344 = _S106 * _S194;
    DiffPair_float_0 _S345;
    (&_S345)->primal_0 = _S111;
    (&_S345)->differential_0 = 0.0f;
    DiffPair_float_0 _S346;
    (&_S346)->primal_0 = 0.0f;
    (&_S346)->differential_0 = 0.0f;
    DiffPair_float_0 _S347;
    (&_S347)->primal_0 = 1.0f;
    (&_S347)->differential_0 = 0.0f;
    s_bwd_prop_clamp_0(&_S345, &_S346, &_S347, _S344);
    float _S348 = _S107 * _S193;
    float _S349 = _S118 * _S348;
    float _S350 = _S117 * (dV_1 * _S348);
    float _S351 = _S116 * _S348;
    float _S352 = _S115 * (dU_1 * _S348);
    float _S353 = _S114 * _S348;
    float _S354 = _S113 * (dY_1 * _S348);
    float _S355 = _S112 * _S348;
    DiffPair_float_0 _S356;
    (&_S356)->primal_0 = dY_1;
    (&_S356)->differential_0 = 0.0f;
    s_bwd_prop_abs_0(&_S356, _S355);
    float _S357 = 0.3333333432674408f * (_S345.differential_0 + _S110 * _S348);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S358;
    (&_S358)->primal_0 = _S109;
    (&_S358)->differential_0 = _S98;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S359;
    (&_S359)->primal_0 = _S109;
    (&_S359)->differential_0 = _S98;
    s_bwd_prop_dot_0(&_S358, &_S359, _S357);
    float _S360 = 0.3333333432674408f * (_S108 * _S348);
    float3  _S361 = make_float3 (_S360, _S360, _S360);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S362;
    (&_S362)->primal_0 = _S109;
    (&_S362)->differential_0 = _S98;
    s_bwd_prop_abs_1(&_S362, _S361);
    float3  _S363 = _S359.differential_0 + _S358.differential_0 + _S362.differential_0;
    float _S364 = _S349 + _S350;
    float s_diff_V_T_0 = - _S364;
    float _S365 = _S351 + _S352;
    float s_diff_U_T_0 = - _S365;
    float _S366 = _S353 + _S354 + _S356.differential_0;
    float s_diff_Y_T_0 = - _S366;
    float _S367 = - s_diff_V_T_0;
    float _S368 = _S342.differential_0 + _S277.differential_0;
    float3  _S369 = _S363 + make_float3 (0.61500000953674316f * s_diff_V_T_0 + -0.14712999761104584f * s_diff_U_T_0 + 0.29899999499320984f * s_diff_Y_T_0, 0.51498997211456299f * _S367 + 0.28885999321937561f * - s_diff_U_T_0 + 0.58700001239776611f * s_diff_Y_T_0, 0.10001000016927719f * _S367 + 0.43599998950958252f * s_diff_U_T_0 + 0.11400000005960464f * s_diff_Y_T_0);
    float3  _S370 = - _S363 + make_float3 (0.61500000953674316f * _S364 + -0.14712999761104584f * _S365 + 0.29899999499320984f * _S366, 0.51498997211456299f * s_diff_V_T_0 + 0.28885999321937561f * s_diff_U_T_0 + 0.58700001239776611f * _S366, 0.10001000016927719f * s_diff_V_T_0 + 0.43599998950958252f * _S365 + 0.11400000005960464f * _S366);
    if(_S99)
    {
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S371;
        (&_S371)->primal_0 = _S94.primal_0;
        (&_S371)->differential_0 = _S98;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S372;
        (&_S372)->primal_0 = _S94.primal_0;
        (&_S372)->differential_0 = _S98;
        s_bwd_prop_dot_0(&_S371, &_S372, 0.0f);
        _S125 = _S372.differential_0 + _S371.differential_0 + _S319;
    }
    else
    {
        _S125 = _S319;
    }
    dpmedian_normal_0->primal_0 = (*dpmedian_normal_0).primal_0;
    dpmedian_normal_0->differential_0 = _S309;
    dpmedian_depth_0->primal_0 = (*dpmedian_depth_0).primal_0;
    dpmedian_depth_0->differential_0 = _S273.differential_0;
    dpnormal_dist_0->primal_0 = (*dpnormal_dist_0).primal_0;
    dpnormal_dist_0->differential_0 = _S278;
    dpdepth_dist_0->primal_0 = (*dpdepth_dist_0).primal_0;
    dpdepth_dist_0->differential_0 = _S204;
    dprgb_dist_0->primal_0 = (*dprgb_dist_0).primal_0;
    dprgb_dist_0->differential_0 = _S279;
    dprender_Ts_0->primal_0 = (*dprender_Ts_0).primal_0;
    dprender_Ts_0->differential_0 = _S239;
    dpref_normal_0->primal_0 = (*dpref_normal_0).primal_0;
    dpref_normal_0->differential_0 = _S125;
    dpdepth_normal_0->primal_0 = (*dpdepth_normal_0).primal_0;
    dpdepth_normal_0->differential_0 = _S326;
    dprender_normal_0->primal_0 = (*dprender_normal_0).primal_0;
    dprender_normal_0->differential_0 = _S333;
    dpref_depth_0->primal_0 = (*dpref_depth_0).primal_0;
    dpref_depth_0->differential_0 = _S340.differential_0;
    dprender_depth_0->primal_0 = (*dprender_depth_0).primal_0;
    dprender_depth_0->differential_0 = _S368;
    dpref_rgb_0->primal_0 = (*dpref_rgb_0).primal_0;
    dpref_rgb_0->differential_0 = _S369;
    dprender_rgb_0->primal_0 = (*dprender_rgb_0).primal_0;
    dprender_rgb_0->differential_0 = _S370;
    return;
}

inline __device__ void s_bwd_per_pixel_losses_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S373, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S374, DiffPair_float_0 * _S375, DiffPair_float_0 * _S376, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S377, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S378, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S379, DiffPair_float_0 * _S380, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S381, DiffPair_float_0 * _S382, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S383, DiffPair_float_0 * _S384, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S385, bool _S386, bool _S387, FixedArray<float, 20>  * _S388, FixedArray<float, 33>  * _S389)
{
    s_bwd_prop_per_pixel_losses_0(_S373, _S374, _S375, _S376, _S377, _S378, _S379, _S380, _S381, _S382, _S383, _S384, _S385, _S386, _S387, _S388, _S389);
    return;
}

inline __device__ void per_pixel_losses_bwd(float3  render_rgb_1, float3  ref_rgb_1, float render_depth_1, float ref_depth_1, float3  render_normal_1, float3  depth_normal_1, float3  ref_normal_1, float render_Ts_1, float3  rgb_dist_1, float depth_dist_1, float3  normal_dist_1, float median_depth_1, float3  median_normal_1, bool ref_alpha_2, bool has_mask_2, FixedArray<float, 20>  weights_2, FixedArray<float, 33>  v_losses_0, float3  * v_render_rgb_0, float3  * v_ref_rgb_0, float * v_render_depth_0, float * v_ref_depth_0, float3  * v_render_normal_0, float3  * v_depth_normal_0, float3  * v_ref_normal_0, float * v_render_Ts_0, float3  * v_rgb_dist_0, float * v_depth_dist_0, float3  * v_normal_dist_0, float * v_median_depth_0, float3  * v_median_normal_0)
{
    float3  _S390 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_render_rgb_0;
    (&dp_render_rgb_0)->primal_0 = render_rgb_1;
    (&dp_render_rgb_0)->differential_0 = _S390;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_ref_rgb_0;
    (&dp_ref_rgb_0)->primal_0 = ref_rgb_1;
    (&dp_ref_rgb_0)->differential_0 = _S390;
    DiffPair_float_0 dp_render_depth_0;
    (&dp_render_depth_0)->primal_0 = render_depth_1;
    (&dp_render_depth_0)->differential_0 = 0.0f;
    DiffPair_float_0 dp_ref_depth_0;
    (&dp_ref_depth_0)->primal_0 = ref_depth_1;
    (&dp_ref_depth_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_render_normal_0;
    (&dp_render_normal_0)->primal_0 = render_normal_1;
    (&dp_render_normal_0)->differential_0 = _S390;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_depth_normal_0;
    (&dp_depth_normal_0)->primal_0 = depth_normal_1;
    (&dp_depth_normal_0)->differential_0 = _S390;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_ref_normal_0;
    (&dp_ref_normal_0)->primal_0 = ref_normal_1;
    (&dp_ref_normal_0)->differential_0 = _S390;
    DiffPair_float_0 dp_render_Ts_0;
    (&dp_render_Ts_0)->primal_0 = render_Ts_1;
    (&dp_render_Ts_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_rgb_dist_0;
    (&dp_rgb_dist_0)->primal_0 = rgb_dist_1;
    (&dp_rgb_dist_0)->differential_0 = _S390;
    DiffPair_float_0 dp_depth_dist_0;
    (&dp_depth_dist_0)->primal_0 = depth_dist_1;
    (&dp_depth_dist_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_normal_dist_0;
    (&dp_normal_dist_0)->primal_0 = normal_dist_1;
    (&dp_normal_dist_0)->differential_0 = _S390;
    DiffPair_float_0 dp_median_depth_0;
    (&dp_median_depth_0)->primal_0 = median_depth_1;
    (&dp_median_depth_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_median_normal_0;
    (&dp_median_normal_0)->primal_0 = median_normal_1;
    (&dp_median_normal_0)->differential_0 = _S390;
    FixedArray<float, 20>  _S391 = weights_2;
    FixedArray<float, 33>  _S392 = v_losses_0;
    s_bwd_per_pixel_losses_0(&dp_render_rgb_0, &dp_ref_rgb_0, &dp_render_depth_0, &dp_ref_depth_0, &dp_render_normal_0, &dp_depth_normal_0, &dp_ref_normal_0, &dp_render_Ts_0, &dp_rgb_dist_0, &dp_depth_dist_0, &dp_normal_dist_0, &dp_median_depth_0, &dp_median_normal_0, ref_alpha_2, has_mask_2, &_S391, &_S392);
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

inline __device__ void _d_log10_0(DiffPair_float_0 * dpx_9, float dOut_9)
{
    float _S393 = 1.0f / ((*dpx_9).primal_0 * 2.30258512496948242f) * dOut_9;
    dpx_9->primal_0 = (*dpx_9).primal_0;
    dpx_9->differential_0 = _S393;
    return;
}

inline __device__ void per_pixel_losses_reduce(FixedArray<float, 33>  raw_losses_0, FixedArray<float, 20>  weights_3, FixedArray<float, 14>  * _S394)
{
    FixedArray<float, 14>  losses_1;
    losses_1[int(0)] = raw_losses_0[int(0)] / (F32_max((raw_losses_0[int(32)]), (1.0f)));
    losses_1[int(1)] = -10.0f * (F32_log10((raw_losses_0[int(1)] / (F32_max((raw_losses_0[int(21)]), (1.0f))))));
    bool _S395;
    if((raw_losses_0[int(22)]) > 0.0f)
    {
        _S395 = (raw_losses_0[int(3)]) != 0.0f;
    }
    else
    {
        _S395 = false;
    }
    float _S396;
    if(_S395)
    {
        _S396 = weights_3[int(6)] * clamp_0(1.0f - (raw_losses_0[int(6)] - raw_losses_0[int(2)] * raw_losses_0[int(3)] / raw_losses_0[int(22)]) / (F32_sqrt(((F32_max((9.999999960041972e-13f), ((raw_losses_0[int(4)] - raw_losses_0[int(2)] * raw_losses_0[int(2)] / raw_losses_0[int(22)]) * (raw_losses_0[int(5)] - raw_losses_0[int(3)] * raw_losses_0[int(3)] / raw_losses_0[int(22)]) + 1.0f)))))), 0.0f, 2.0f);
    }
    else
    {
        _S396 = 0.0f;
    }
    losses_1[int(2)] = _S396;
    losses_1[int(3)] = (raw_losses_0[int(7)] / (F32_max((raw_losses_0[int(23)]), (1.0f))) + raw_losses_0[int(8)] / (F32_max((raw_losses_0[int(24)]), (1.0f)))) / float((I32_max((int((raw_losses_0[int(23)]) > 0.5f) + int((raw_losses_0[int(24)]) > 0.5f)), (int(1)))));
    losses_1[int(4)] = raw_losses_0[int(9)] / (F32_max((raw_losses_0[int(26)]), (1.0f))) + raw_losses_0[int(10)] / (F32_max((raw_losses_0[int(27)]), (1.0f)));
    losses_1[int(5)] = raw_losses_0[int(11)] / (F32_max((raw_losses_0[int(25)]), (1.0f)));
    float _S397 = (F32_max((raw_losses_0[int(20)]), (1.0f)));
    losses_1[int(6)] = raw_losses_0[int(12)] / _S397;
    losses_1[int(7)] = raw_losses_0[int(13)] / _S397;
    losses_1[int(8)] = raw_losses_0[int(14)] / _S397;
    losses_1[int(9)] = raw_losses_0[int(15)] / _S397;
    losses_1[int(10)] = raw_losses_0[int(16)] / (F32_max((raw_losses_0[int(28)]), (1.0f)));
    losses_1[int(11)] = raw_losses_0[int(17)] / (F32_max((raw_losses_0[int(29)]), (1.0f)));
    losses_1[int(12)] = raw_losses_0[int(18)] / (F32_max((raw_losses_0[int(30)]), (1.0f)));
    losses_1[int(13)] = raw_losses_0[int(19)] / (F32_max((raw_losses_0[int(31)]), (1.0f)));
    *_S394 = losses_1;
    return;
}

struct DiffPair_arrayx3Cfloatx2C33x3E_0
{
    FixedArray<float, 33>  primal_0;
    FixedArray<float, 33>  differential_0;
};

inline __device__ float s_primal_ctx_sqrt_0(float _S398)
{
    return (F32_sqrt((_S398)));
}

inline __device__ void s_bwd_prop_log10_0(DiffPair_float_0 * _S399, float _S400)
{
    _d_log10_0(_S399, _S400);
    return;
}

inline __device__ void s_bwd_prop_per_pixel_losses_reduce_0(DiffPair_arrayx3Cfloatx2C33x3E_0 * dpraw_losses_0, FixedArray<float, 20>  * weights_4, FixedArray<float, 14>  * _s_dOut_1)
{
    FixedArray<float, 33>  _S401 = dpraw_losses_0->primal_0;
    float _S402 = (F32_max((dpraw_losses_0->primal_0[int(32)]), (1.0f)));
    float _S403 = _S402 * _S402;
    float _S404 = (F32_max((dpraw_losses_0->primal_0[int(21)]), (1.0f)));
    float _S405 = dpraw_losses_0->primal_0[int(1)] / _S404;
    float _S406 = _S404 * _S404;
    bool _S407 = (dpraw_losses_0->primal_0[int(22)]) > 0.0f;
    bool _S408;
    if(_S407)
    {
        _S408 = (_S401[int(3)]) != 0.0f;
    }
    else
    {
        _S408 = false;
    }
    float _S409;
    float _S410;
    float _S411;
    float _S412;
    float _S413;
    float _S414;
    float _S415;
    float _S416;
    float _S417;
    float _S418;
    float _S419;
    float _S420;
    float _S421;
    float _S422;
    float _S423;
    if(_S408)
    {
        float _S424 = _S401[int(2)] * _S401[int(3)];
        float _S425 = _S401[int(22)] * _S401[int(22)];
        float _S426 = _S401[int(6)] - _S424 / _S401[int(22)];
        float _S427 = _S401[int(2)] * _S401[int(2)];
        float _S428 = _S401[int(4)] - _S427 / _S401[int(22)];
        float _S429 = _S401[int(3)] * _S401[int(3)];
        float _S430 = _S401[int(5)] - _S429 / _S401[int(22)];
        float _S431 = _S428 * _S430 + 1.0f;
        float _S432 = (F32_max((9.999999960041972e-13f), (_S431)));
        float _S433 = s_primal_ctx_sqrt_0(_S432);
        float _S434 = _S433 * _S433;
        float _S435 = 1.0f - _S426 / _S433;
        _S409 = (*weights_4)[int(6)];
        _S410 = _S435;
        _S411 = _S434;
        _S412 = _S426;
        _S413 = _S433;
        _S414 = _S432;
        _S415 = _S431;
        _S416 = _S428;
        _S417 = _S430;
        _S418 = _S425;
        _S419 = _S429;
        _S420 = _S401[int(3)];
        _S421 = _S427;
        _S422 = _S401[int(2)];
        _S423 = _S424;
    }
    else
    {
        _S409 = 0.0f;
        _S410 = 0.0f;
        _S411 = 0.0f;
        _S412 = 0.0f;
        _S413 = 0.0f;
        _S414 = 0.0f;
        _S415 = 0.0f;
        _S416 = 0.0f;
        _S417 = 0.0f;
        _S418 = 0.0f;
        _S419 = 0.0f;
        _S420 = 0.0f;
        _S421 = 0.0f;
        _S422 = 0.0f;
        _S423 = 0.0f;
    }
    float _S436 = (F32_max((_S401[int(23)]), (1.0f)));
    float _S437 = _S436 * _S436;
    float _S438 = (F32_max((_S401[int(24)]), (1.0f)));
    float _S439 = _S438 * _S438;
    float _S440 = float((I32_max((int((_S401[int(23)]) > 0.5f) + int((_S401[int(24)]) > 0.5f)), (int(1)))));
    float _S441 = (F32_max((_S401[int(26)]), (1.0f)));
    float _S442 = _S441 * _S441;
    float _S443 = (F32_max((_S401[int(27)]), (1.0f)));
    float _S444 = _S443 * _S443;
    float _S445 = (F32_max((_S401[int(25)]), (1.0f)));
    float _S446 = _S445 * _S445;
    float _S447 = (F32_max((_S401[int(20)]), (1.0f)));
    float _S448 = _S447 * _S447;
    float _S449 = (F32_max((_S401[int(28)]), (1.0f)));
    float _S450 = _S449 * _S449;
    float _S451 = (F32_max((_S401[int(29)]), (1.0f)));
    float _S452 = _S451 * _S451;
    float _S453 = (F32_max((_S401[int(30)]), (1.0f)));
    float _S454 = _S453 * _S453;
    float _S455 = (F32_max((_S401[int(31)]), (1.0f)));
    float _S456 = _S455 * _S455;
    float _S457 = (*_s_dOut_1)[int(0)];
    float _S458 = (*_s_dOut_1)[int(1)];
    float _S459 = (*_s_dOut_1)[int(2)];
    float _S460 = (*_s_dOut_1)[int(13)] / _S456;
    float _S461 = _S401[int(19)] * - _S460;
    float _S462 = _S455 * _S460;
    DiffPair_float_0 _S463;
    (&_S463)->primal_0 = _S401[int(31)];
    (&_S463)->differential_0 = 0.0f;
    DiffPair_float_0 _S464;
    (&_S464)->primal_0 = 1.0f;
    (&_S464)->differential_0 = 0.0f;
    _d_max_0(&_S463, &_S464, _S461);
    float _S465 = (*_s_dOut_1)[int(12)] / _S454;
    float _S466 = _S401[int(18)] * - _S465;
    float _S467 = _S453 * _S465;
    DiffPair_float_0 _S468;
    (&_S468)->primal_0 = _S401[int(30)];
    (&_S468)->differential_0 = 0.0f;
    DiffPair_float_0 _S469;
    (&_S469)->primal_0 = 1.0f;
    (&_S469)->differential_0 = 0.0f;
    _d_max_0(&_S468, &_S469, _S466);
    float _S470 = (*_s_dOut_1)[int(11)] / _S452;
    float _S471 = _S401[int(17)] * - _S470;
    float _S472 = _S451 * _S470;
    DiffPair_float_0 _S473;
    (&_S473)->primal_0 = _S401[int(29)];
    (&_S473)->differential_0 = 0.0f;
    DiffPair_float_0 _S474;
    (&_S474)->primal_0 = 1.0f;
    (&_S474)->differential_0 = 0.0f;
    _d_max_0(&_S473, &_S474, _S471);
    float _S475 = (*_s_dOut_1)[int(10)] / _S450;
    float _S476 = _S401[int(16)] * - _S475;
    float _S477 = _S449 * _S475;
    DiffPair_float_0 _S478;
    (&_S478)->primal_0 = _S401[int(28)];
    (&_S478)->differential_0 = 0.0f;
    DiffPair_float_0 _S479;
    (&_S479)->primal_0 = 1.0f;
    (&_S479)->differential_0 = 0.0f;
    _d_max_0(&_S478, &_S479, _S476);
    float _S480 = (*_s_dOut_1)[int(9)] / _S448;
    float _S481 = _S447 * _S480;
    float _S482 = (*_s_dOut_1)[int(8)] / _S448;
    float _S483 = _S447 * _S482;
    float _S484 = (*_s_dOut_1)[int(7)] / _S448;
    float _S485 = _S447 * _S484;
    float _S486 = (*_s_dOut_1)[int(6)] / _S448;
    float _S487 = _S447 * _S486;
    float _S488 = _S401[int(15)] * - _S480 + _S401[int(14)] * - _S482 + _S401[int(13)] * - _S484 + _S401[int(12)] * - _S486;
    DiffPair_float_0 _S489;
    (&_S489)->primal_0 = _S401[int(20)];
    (&_S489)->differential_0 = 0.0f;
    DiffPair_float_0 _S490;
    (&_S490)->primal_0 = 1.0f;
    (&_S490)->differential_0 = 0.0f;
    _d_max_0(&_S489, &_S490, _S488);
    float _S491 = (*_s_dOut_1)[int(5)] / _S446;
    float _S492 = _S401[int(11)] * - _S491;
    float _S493 = _S445 * _S491;
    DiffPair_float_0 _S494;
    (&_S494)->primal_0 = _S401[int(25)];
    (&_S494)->differential_0 = 0.0f;
    DiffPair_float_0 _S495;
    (&_S495)->primal_0 = 1.0f;
    (&_S495)->differential_0 = 0.0f;
    _d_max_0(&_S494, &_S495, _S492);
    float _S496 = (*_s_dOut_1)[int(4)] / _S444;
    float _S497 = _S401[int(10)] * - _S496;
    float _S498 = _S443 * _S496;
    DiffPair_float_0 _S499;
    (&_S499)->primal_0 = _S401[int(27)];
    (&_S499)->differential_0 = 0.0f;
    DiffPair_float_0 _S500;
    (&_S500)->primal_0 = 1.0f;
    (&_S500)->differential_0 = 0.0f;
    _d_max_0(&_S499, &_S500, _S497);
    float _S501 = (*_s_dOut_1)[int(4)] / _S442;
    float _S502 = _S401[int(9)] * - _S501;
    float _S503 = _S441 * _S501;
    DiffPair_float_0 _S504;
    (&_S504)->primal_0 = _S401[int(26)];
    (&_S504)->differential_0 = 0.0f;
    DiffPair_float_0 _S505;
    (&_S505)->primal_0 = 1.0f;
    (&_S505)->differential_0 = 0.0f;
    _d_max_0(&_S504, &_S505, _S502);
    float _S506 = (*_s_dOut_1)[int(3)] / _S440;
    float _S507 = _S506 / _S439;
    float _S508 = _S401[int(8)] * - _S507;
    float _S509 = _S438 * _S507;
    DiffPair_float_0 _S510;
    (&_S510)->primal_0 = _S401[int(24)];
    (&_S510)->differential_0 = 0.0f;
    DiffPair_float_0 _S511;
    (&_S511)->primal_0 = 1.0f;
    (&_S511)->differential_0 = 0.0f;
    _d_max_0(&_S510, &_S511, _S508);
    float _S512 = _S506 / _S437;
    float _S513 = _S401[int(7)] * - _S512;
    float _S514 = _S436 * _S512;
    DiffPair_float_0 _S515;
    (&_S515)->primal_0 = _S401[int(23)];
    (&_S515)->differential_0 = 0.0f;
    DiffPair_float_0 _S516;
    (&_S516)->primal_0 = 1.0f;
    (&_S516)->differential_0 = 0.0f;
    _d_max_0(&_S515, &_S516, _S513);
    FixedArray<float, 33>  _S517;
    _S517[int(0)] = 0.0f;
    _S517[int(1)] = 0.0f;
    _S517[int(2)] = 0.0f;
    _S517[int(3)] = 0.0f;
    _S517[int(4)] = 0.0f;
    _S517[int(5)] = 0.0f;
    _S517[int(6)] = 0.0f;
    _S517[int(7)] = 0.0f;
    _S517[int(8)] = 0.0f;
    _S517[int(9)] = 0.0f;
    _S517[int(10)] = 0.0f;
    _S517[int(11)] = 0.0f;
    _S517[int(12)] = 0.0f;
    _S517[int(13)] = 0.0f;
    _S517[int(14)] = 0.0f;
    _S517[int(15)] = 0.0f;
    _S517[int(16)] = 0.0f;
    _S517[int(17)] = 0.0f;
    _S517[int(18)] = 0.0f;
    _S517[int(19)] = 0.0f;
    _S517[int(20)] = 0.0f;
    _S517[int(21)] = 0.0f;
    _S517[int(22)] = 0.0f;
    _S517[int(23)] = 0.0f;
    _S517[int(24)] = 0.0f;
    _S517[int(25)] = 0.0f;
    _S517[int(26)] = 0.0f;
    _S517[int(27)] = 0.0f;
    _S517[int(28)] = 0.0f;
    _S517[int(29)] = 0.0f;
    _S517[int(30)] = 0.0f;
    _S517[int(31)] = 0.0f;
    _S517[int(32)] = 0.0f;
    _S517[int(31)] = _S463.differential_0;
    _S517[int(19)] = _S462;
    _S517[int(30)] = _S468.differential_0;
    _S517[int(18)] = _S467;
    _S517[int(29)] = _S473.differential_0;
    _S517[int(17)] = _S472;
    _S517[int(28)] = _S478.differential_0;
    _S517[int(16)] = _S477;
    _S517[int(15)] = _S481;
    _S517[int(14)] = _S483;
    _S517[int(13)] = _S485;
    _S517[int(20)] = _S489.differential_0;
    _S517[int(12)] = _S487;
    _S517[int(25)] = _S494.differential_0;
    _S517[int(11)] = _S493;
    _S517[int(27)] = _S499.differential_0;
    _S517[int(10)] = _S498;
    _S517[int(26)] = _S504.differential_0;
    _S517[int(9)] = _S503;
    _S517[int(24)] = _S510.differential_0;
    _S517[int(8)] = _S509;
    _S517[int(23)] = _S515.differential_0;
    _S517[int(7)] = _S514;
    float _S518 = _S517[int(0)];
    float _S519 = _S517[int(1)];
    float _S520 = _S517[int(2)];
    float _S521 = _S517[int(3)];
    float _S522 = _S517[int(4)];
    float _S523 = _S517[int(5)];
    float _S524 = _S517[int(6)];
    float _S525 = _S517[int(7)];
    float _S526 = _S517[int(8)];
    float _S527 = _S517[int(9)];
    float _S528 = _S517[int(10)];
    float _S529 = _S517[int(11)];
    float _S530 = _S517[int(12)];
    float _S531 = _S517[int(13)];
    float _S532 = _S517[int(14)];
    float _S533 = _S517[int(15)];
    float _S534 = _S517[int(16)];
    float _S535 = _S517[int(17)];
    float _S536 = _S517[int(18)];
    float _S537 = _S517[int(19)];
    float _S538 = _S517[int(20)];
    float _S539 = _S517[int(21)];
    float _S540 = _S517[int(22)];
    float _S541 = _S517[int(23)];
    float _S542 = _S517[int(24)];
    float _S543 = _S517[int(25)];
    float _S544 = _S517[int(26)];
    float _S545 = _S517[int(27)];
    float _S546 = _S517[int(28)];
    float _S547 = _S517[int(29)];
    float _S548 = _S517[int(30)];
    float _S549 = _S517[int(31)];
    float _S550 = _S517[int(32)];
    FixedArray<float, 33>  _S551;
    if(_S408)
    {
        float _S552 = _S409 * _S459;
        DiffPair_float_0 _S553;
        (&_S553)->primal_0 = _S410;
        (&_S553)->differential_0 = 0.0f;
        DiffPair_float_0 _S554;
        (&_S554)->primal_0 = 0.0f;
        (&_S554)->differential_0 = 0.0f;
        DiffPair_float_0 _S555;
        (&_S555)->primal_0 = 2.0f;
        (&_S555)->differential_0 = 0.0f;
        s_bwd_prop_clamp_0(&_S553, &_S554, &_S555, _S552);
        float _S556 = - _S553.differential_0 / _S411;
        float _S557 = _S412 * - _S556;
        float _S558 = _S413 * _S556;
        DiffPair_float_0 _S559;
        (&_S559)->primal_0 = _S414;
        (&_S559)->differential_0 = 0.0f;
        s_bwd_prop_sqrt_0(&_S559, _S557);
        DiffPair_float_0 _S560;
        (&_S560)->primal_0 = 9.999999960041972e-13f;
        (&_S560)->differential_0 = 0.0f;
        DiffPair_float_0 _S561;
        (&_S561)->primal_0 = _S415;
        (&_S561)->differential_0 = 0.0f;
        _d_max_0(&_S560, &_S561, _S559.differential_0);
        float _S562 = _S416 * _S561.differential_0;
        float _S563 = _S417 * _S561.differential_0;
        float _S564 = - _S562 / _S418;
        float _S565 = _S420 * (_S401[int(22)] * _S564);
        float _S566 = - _S563 / _S418;
        float _S567 = _S422 * (_S401[int(22)] * _S566);
        float _S568 = - _S558 / _S418;
        float _S569 = _S401[int(22)] * _S568;
        float _S570 = _S565 + _S565 + _S422 * _S569;
        float _S571 = _S567 + _S567 + _S420 * _S569;
        float _S572 = _S419 * - _S564 + _S421 * - _S566 + _S423 * - _S568;
        FixedArray<float, 33>  _S573;
        _S573[int(0)] = 0.0f;
        _S573[int(1)] = 0.0f;
        _S573[int(2)] = 0.0f;
        _S573[int(3)] = 0.0f;
        _S573[int(4)] = 0.0f;
        _S573[int(5)] = 0.0f;
        _S573[int(6)] = 0.0f;
        _S573[int(7)] = 0.0f;
        _S573[int(8)] = 0.0f;
        _S573[int(9)] = 0.0f;
        _S573[int(10)] = 0.0f;
        _S573[int(11)] = 0.0f;
        _S573[int(12)] = 0.0f;
        _S573[int(13)] = 0.0f;
        _S573[int(14)] = 0.0f;
        _S573[int(15)] = 0.0f;
        _S573[int(16)] = 0.0f;
        _S573[int(17)] = 0.0f;
        _S573[int(18)] = 0.0f;
        _S573[int(19)] = 0.0f;
        _S573[int(20)] = 0.0f;
        _S573[int(21)] = 0.0f;
        _S573[int(22)] = 0.0f;
        _S573[int(23)] = 0.0f;
        _S573[int(24)] = 0.0f;
        _S573[int(25)] = 0.0f;
        _S573[int(26)] = 0.0f;
        _S573[int(27)] = 0.0f;
        _S573[int(28)] = 0.0f;
        _S573[int(29)] = 0.0f;
        _S573[int(30)] = 0.0f;
        _S573[int(31)] = 0.0f;
        _S573[int(32)] = 0.0f;
        _S573[int(5)] = _S562;
        _S573[int(4)] = _S563;
        _S573[int(3)] = _S570;
        _S573[int(2)] = _S571;
        _S573[int(6)] = _S558;
        float _S574 = _S519 + _S573[int(1)];
        float _S575 = _S520 + _S573[int(2)];
        float _S576 = _S521 + _S573[int(3)];
        float _S577 = _S522 + _S573[int(4)];
        float _S578 = _S523 + _S573[int(5)];
        float _S579 = _S524 + _S573[int(6)];
        float _S580 = _S525 + _S573[int(7)];
        float _S581 = _S526 + _S573[int(8)];
        float _S582 = _S527 + _S573[int(9)];
        float _S583 = _S528 + _S573[int(10)];
        float _S584 = _S529 + _S573[int(11)];
        float _S585 = _S530 + _S573[int(12)];
        float _S586 = _S531 + _S573[int(13)];
        float _S587 = _S532 + _S573[int(14)];
        float _S588 = _S533 + _S573[int(15)];
        float _S589 = _S534 + _S573[int(16)];
        float _S590 = _S535 + _S573[int(17)];
        float _S591 = _S536 + _S573[int(18)];
        float _S592 = _S537 + _S573[int(19)];
        float _S593 = _S538 + _S573[int(20)];
        float _S594 = _S539 + _S573[int(21)];
        float _S595 = _S540 + _S573[int(22)];
        float _S596 = _S541 + _S573[int(23)];
        float _S597 = _S542 + _S573[int(24)];
        float _S598 = _S543 + _S573[int(25)];
        float _S599 = _S544 + _S573[int(26)];
        float _S600 = _S545 + _S573[int(27)];
        float _S601 = _S546 + _S573[int(28)];
        float _S602 = _S547 + _S573[int(29)];
        float _S603 = _S548 + _S573[int(30)];
        float _S604 = _S549 + _S573[int(31)];
        float _S605 = _S550 + _S573[int(32)];
        _S551[int(0)] = _S518 + _S573[int(0)];
        _S551[int(1)] = _S574;
        _S551[int(2)] = _S575;
        _S551[int(3)] = _S576;
        _S551[int(4)] = _S577;
        _S551[int(5)] = _S578;
        _S551[int(6)] = _S579;
        _S551[int(7)] = _S580;
        _S551[int(8)] = _S581;
        _S551[int(9)] = _S582;
        _S551[int(10)] = _S583;
        _S551[int(11)] = _S584;
        _S551[int(12)] = _S585;
        _S551[int(13)] = _S586;
        _S551[int(14)] = _S587;
        _S551[int(15)] = _S588;
        _S551[int(16)] = _S589;
        _S551[int(17)] = _S590;
        _S551[int(18)] = _S591;
        _S551[int(19)] = _S592;
        _S551[int(20)] = _S593;
        _S551[int(21)] = _S594;
        _S551[int(22)] = _S595;
        _S551[int(23)] = _S596;
        _S551[int(24)] = _S597;
        _S551[int(25)] = _S598;
        _S551[int(26)] = _S599;
        _S551[int(27)] = _S600;
        _S551[int(28)] = _S601;
        _S551[int(29)] = _S602;
        _S551[int(30)] = _S603;
        _S551[int(31)] = _S604;
        _S551[int(32)] = _S605;
        _S409 = _S572;
    }
    else
    {
        _S551[int(0)] = _S518;
        _S551[int(1)] = _S519;
        _S551[int(2)] = _S520;
        _S551[int(3)] = _S521;
        _S551[int(4)] = _S522;
        _S551[int(5)] = _S523;
        _S551[int(6)] = _S524;
        _S551[int(7)] = _S525;
        _S551[int(8)] = _S526;
        _S551[int(9)] = _S527;
        _S551[int(10)] = _S528;
        _S551[int(11)] = _S529;
        _S551[int(12)] = _S530;
        _S551[int(13)] = _S531;
        _S551[int(14)] = _S532;
        _S551[int(15)] = _S533;
        _S551[int(16)] = _S534;
        _S551[int(17)] = _S535;
        _S551[int(18)] = _S536;
        _S551[int(19)] = _S537;
        _S551[int(20)] = _S538;
        _S551[int(21)] = _S539;
        _S551[int(22)] = _S540;
        _S551[int(23)] = _S541;
        _S551[int(24)] = _S542;
        _S551[int(25)] = _S543;
        _S551[int(26)] = _S544;
        _S551[int(27)] = _S545;
        _S551[int(28)] = _S546;
        _S551[int(29)] = _S547;
        _S551[int(30)] = _S548;
        _S551[int(31)] = _S549;
        _S551[int(32)] = _S550;
        _S409 = 0.0f;
    }
    if(_S407)
    {
        FixedArray<float, 33>  _S606;
        _S606[int(0)] = 0.0f;
        _S606[int(1)] = 0.0f;
        _S606[int(2)] = 0.0f;
        _S606[int(3)] = 0.0f;
        _S606[int(4)] = 0.0f;
        _S606[int(5)] = 0.0f;
        _S606[int(6)] = 0.0f;
        _S606[int(7)] = 0.0f;
        _S606[int(8)] = 0.0f;
        _S606[int(9)] = 0.0f;
        _S606[int(10)] = 0.0f;
        _S606[int(11)] = 0.0f;
        _S606[int(12)] = 0.0f;
        _S606[int(13)] = 0.0f;
        _S606[int(14)] = 0.0f;
        _S606[int(15)] = 0.0f;
        _S606[int(16)] = 0.0f;
        _S606[int(17)] = 0.0f;
        _S606[int(18)] = 0.0f;
        _S606[int(19)] = 0.0f;
        _S606[int(20)] = 0.0f;
        _S606[int(21)] = 0.0f;
        _S606[int(22)] = 0.0f;
        _S606[int(23)] = 0.0f;
        _S606[int(24)] = 0.0f;
        _S606[int(25)] = 0.0f;
        _S606[int(26)] = 0.0f;
        _S606[int(27)] = 0.0f;
        _S606[int(28)] = 0.0f;
        _S606[int(29)] = 0.0f;
        _S606[int(30)] = 0.0f;
        _S606[int(31)] = 0.0f;
        _S606[int(32)] = 0.0f;
        _S606[int(3)] = 0.0f;
        float _S607 = _S551[int(1)] + _S606[int(1)];
        float _S608 = _S551[int(2)] + _S606[int(2)];
        float _S609 = _S551[int(3)] + _S606[int(3)];
        float _S610 = _S551[int(4)] + _S606[int(4)];
        float _S611 = _S551[int(5)] + _S606[int(5)];
        float _S612 = _S551[int(6)] + _S606[int(6)];
        float _S613 = _S551[int(7)] + _S606[int(7)];
        float _S614 = _S551[int(8)] + _S606[int(8)];
        float _S615 = _S551[int(9)] + _S606[int(9)];
        float _S616 = _S551[int(10)] + _S606[int(10)];
        float _S617 = _S551[int(11)] + _S606[int(11)];
        float _S618 = _S551[int(12)] + _S606[int(12)];
        float _S619 = _S551[int(13)] + _S606[int(13)];
        float _S620 = _S551[int(14)] + _S606[int(14)];
        float _S621 = _S551[int(15)] + _S606[int(15)];
        float _S622 = _S551[int(16)] + _S606[int(16)];
        float _S623 = _S551[int(17)] + _S606[int(17)];
        float _S624 = _S551[int(18)] + _S606[int(18)];
        float _S625 = _S551[int(19)] + _S606[int(19)];
        float _S626 = _S551[int(20)] + _S606[int(20)];
        float _S627 = _S551[int(21)] + _S606[int(21)];
        float _S628 = _S551[int(22)] + _S606[int(22)];
        float _S629 = _S551[int(23)] + _S606[int(23)];
        float _S630 = _S551[int(24)] + _S606[int(24)];
        float _S631 = _S551[int(25)] + _S606[int(25)];
        float _S632 = _S551[int(26)] + _S606[int(26)];
        float _S633 = _S551[int(27)] + _S606[int(27)];
        float _S634 = _S551[int(28)] + _S606[int(28)];
        float _S635 = _S551[int(29)] + _S606[int(29)];
        float _S636 = _S551[int(30)] + _S606[int(30)];
        float _S637 = _S551[int(31)] + _S606[int(31)];
        float _S638 = _S551[int(32)] + _S606[int(32)];
        _S551[int(0)] = _S551[int(0)] + _S606[int(0)];
        _S551[int(1)] = _S607;
        _S551[int(2)] = _S608;
        _S551[int(3)] = _S609;
        _S551[int(4)] = _S610;
        _S551[int(5)] = _S611;
        _S551[int(6)] = _S612;
        _S551[int(7)] = _S613;
        _S551[int(8)] = _S614;
        _S551[int(9)] = _S615;
        _S551[int(10)] = _S616;
        _S551[int(11)] = _S617;
        _S551[int(12)] = _S618;
        _S551[int(13)] = _S619;
        _S551[int(14)] = _S620;
        _S551[int(15)] = _S621;
        _S551[int(16)] = _S622;
        _S551[int(17)] = _S623;
        _S551[int(18)] = _S624;
        _S551[int(19)] = _S625;
        _S551[int(20)] = _S626;
        _S551[int(21)] = _S627;
        _S551[int(22)] = _S628;
        _S551[int(23)] = _S629;
        _S551[int(24)] = _S630;
        _S551[int(25)] = _S631;
        _S551[int(26)] = _S632;
        _S551[int(27)] = _S633;
        _S551[int(28)] = _S634;
        _S551[int(29)] = _S635;
        _S551[int(30)] = _S636;
        _S551[int(31)] = _S637;
        _S551[int(32)] = _S638;
    }
    float _S639 = -10.0f * _S458;
    DiffPair_float_0 _S640;
    (&_S640)->primal_0 = _S405;
    (&_S640)->differential_0 = 0.0f;
    s_bwd_prop_log10_0(&_S640, _S639);
    float _S641 = _S640.differential_0 / _S406;
    float _S642 = _S401[int(1)] * - _S641;
    float _S643 = _S404 * _S641;
    DiffPair_float_0 _S644;
    (&_S644)->primal_0 = _S401[int(21)];
    (&_S644)->differential_0 = 0.0f;
    DiffPair_float_0 _S645;
    (&_S645)->primal_0 = 1.0f;
    (&_S645)->differential_0 = 0.0f;
    _d_max_0(&_S644, &_S645, _S642);
    float _S646 = _S457 / _S403;
    float _S647 = _S401[int(0)] * - _S646;
    float _S648 = _S402 * _S646;
    DiffPair_float_0 _S649;
    (&_S649)->primal_0 = _S401[int(32)];
    (&_S649)->differential_0 = 0.0f;
    DiffPair_float_0 _S650;
    (&_S650)->primal_0 = 1.0f;
    (&_S650)->differential_0 = 0.0f;
    _d_max_0(&_S649, &_S650, _S647);
    FixedArray<float, 33>  _S651;
    _S651[int(0)] = 0.0f;
    _S651[int(1)] = 0.0f;
    _S651[int(2)] = 0.0f;
    _S651[int(3)] = 0.0f;
    _S651[int(4)] = 0.0f;
    _S651[int(5)] = 0.0f;
    _S651[int(6)] = 0.0f;
    _S651[int(7)] = 0.0f;
    _S651[int(8)] = 0.0f;
    _S651[int(9)] = 0.0f;
    _S651[int(10)] = 0.0f;
    _S651[int(11)] = 0.0f;
    _S651[int(12)] = 0.0f;
    _S651[int(13)] = 0.0f;
    _S651[int(14)] = 0.0f;
    _S651[int(15)] = 0.0f;
    _S651[int(16)] = 0.0f;
    _S651[int(17)] = 0.0f;
    _S651[int(18)] = 0.0f;
    _S651[int(19)] = 0.0f;
    _S651[int(20)] = 0.0f;
    _S651[int(21)] = 0.0f;
    _S651[int(22)] = 0.0f;
    _S651[int(23)] = 0.0f;
    _S651[int(24)] = 0.0f;
    _S651[int(25)] = 0.0f;
    _S651[int(26)] = 0.0f;
    _S651[int(27)] = 0.0f;
    _S651[int(28)] = 0.0f;
    _S651[int(29)] = 0.0f;
    _S651[int(30)] = 0.0f;
    _S651[int(31)] = 0.0f;
    _S651[int(32)] = 0.0f;
    _S651[int(22)] = _S409;
    _S651[int(21)] = _S644.differential_0;
    _S651[int(1)] = _S643;
    _S651[int(32)] = _S649.differential_0;
    _S651[int(0)] = _S648;
    FixedArray<float, 33>  _S652 = {
        _S551[int(0)] + _S651[int(0)], _S551[int(1)] + _S651[int(1)], _S551[int(2)] + _S651[int(2)], _S551[int(3)] + _S651[int(3)], _S551[int(4)] + _S651[int(4)], _S551[int(5)] + _S651[int(5)], _S551[int(6)] + _S651[int(6)], _S551[int(7)] + _S651[int(7)], _S551[int(8)] + _S651[int(8)], _S551[int(9)] + _S651[int(9)], _S551[int(10)] + _S651[int(10)], _S551[int(11)] + _S651[int(11)], _S551[int(12)] + _S651[int(12)], _S551[int(13)] + _S651[int(13)], _S551[int(14)] + _S651[int(14)], _S551[int(15)] + _S651[int(15)], _S551[int(16)] + _S651[int(16)], _S551[int(17)] + _S651[int(17)], _S551[int(18)] + _S651[int(18)], _S551[int(19)] + _S651[int(19)], _S551[int(20)] + _S651[int(20)], _S551[int(21)] + _S651[int(21)], _S551[int(22)] + _S651[int(22)], _S551[int(23)] + _S651[int(23)], _S551[int(24)] + _S651[int(24)], _S551[int(25)] + _S651[int(25)], _S551[int(26)] + _S651[int(26)], _S551[int(27)] + _S651[int(27)], _S551[int(28)] + _S651[int(28)], _S551[int(29)] + _S651[int(29)], _S551[int(30)] + _S651[int(30)], _S551[int(31)] + _S651[int(31)], _S551[int(32)] + _S651[int(32)]
    };
    dpraw_losses_0->primal_0 = dpraw_losses_0->primal_0;
    dpraw_losses_0->differential_0 = _S652;
    return;
}

inline __device__ void s_bwd_per_pixel_losses_reduce_0(DiffPair_arrayx3Cfloatx2C33x3E_0 * _S653, FixedArray<float, 20>  * _S654, FixedArray<float, 14>  * _S655)
{
    s_bwd_prop_per_pixel_losses_reduce_0(_S653, _S654, _S655);
    return;
}

inline __device__ void per_pixel_losses_reduce_bwd(FixedArray<float, 33>  raw_losses_1, FixedArray<float, 20>  weights_5, FixedArray<float, 14>  v_losses_1, FixedArray<float, 33>  * _S656)
{
    FixedArray<float, 33>  _S657 = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f };
    DiffPair_arrayx3Cfloatx2C33x3E_0 dp_raw_losses_0;
    (&dp_raw_losses_0)->primal_0 = raw_losses_1;
    (&dp_raw_losses_0)->differential_0 = _S657;
    FixedArray<float, 20>  _S658 = weights_5;
    FixedArray<float, 14>  _S659 = v_losses_1;
    s_bwd_per_pixel_losses_reduce_0(&dp_raw_losses_0, &_S658, &_S659);
    *_S656 = (&dp_raw_losses_0)->differential_0;
    return;
}


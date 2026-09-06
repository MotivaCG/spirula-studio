#pragma once

#include "generated/slang.cuh"

struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};

inline __device__ void _d_max_0(DiffPair_float_0 * dpx_0, DiffPair_float_0 * dpy_0, float dOut_0)
{
    DiffPair_float_0 _S1 = *dpx_0;
    float _S2;
    if(((*dpx_0).primal_0) > ((*dpy_0).primal_0))
    {
        _S2 = dOut_0;
    }
    else
    {
        if(((*dpx_0).primal_0) < ((*dpy_0).primal_0))
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
    if(((*dpy_0).primal_0) > (_S1.primal_0))
    {
        _S2 = dOut_0;
    }
    else
    {
        if(((*dpy_0).primal_0) < ((*dpx_0).primal_0))
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

inline __device__ float rendered_depth_to_expected_depth(float depth_0, float transmittance_0)
{
    return depth_0 / (F32_max((1.0f - transmittance_0), (1.00000001335143196e-10f)));
}

inline __device__ void s_bwd_prop_rendered_depth_to_expected_depth_0(DiffPair_float_0 * dpdepth_0, DiffPair_float_0 * dptransmittance_0, float _s_dOut_0)
{
    float _S4 = 1.0f - (*dptransmittance_0).primal_0;
    float _S5 = (F32_max((_S4), (1.00000001335143196e-10f)));
    float _S6 = _s_dOut_0 / (_S5 * _S5);
    float _S7 = (*dpdepth_0).primal_0 * - _S6;
    float _S8 = _S5 * _S6;
    DiffPair_float_0 _S9;
    (&_S9)->primal_0 = _S4;
    (&_S9)->differential_0 = 0.0f;
    DiffPair_float_0 _S10;
    (&_S10)->primal_0 = 1.00000001335143196e-10f;
    (&_S10)->differential_0 = 0.0f;
    _d_max_0(&_S9, &_S10, _S7);
    float _S11 = - _S9.differential_0;
    dptransmittance_0->primal_0 = (*dptransmittance_0).primal_0;
    dptransmittance_0->differential_0 = _S11;
    dpdepth_0->primal_0 = (*dpdepth_0).primal_0;
    dpdepth_0->differential_0 = _S8;
    return;
}

inline __device__ void s_bwd_rendered_depth_to_expected_depth_0(DiffPair_float_0 * _S12, DiffPair_float_0 * _S13, float _S14)
{
    s_bwd_prop_rendered_depth_to_expected_depth_0(_S12, _S13, _S14);
    return;
}

inline __device__ void rendered_depth_to_expected_depth_bwd(float depth_1, float transmittance_1, float v_out_depth_0, float * v_depth_0, float * v_transmittance_0)
{
    DiffPair_float_0 p_depth_0;
    (&p_depth_0)->primal_0 = depth_1;
    (&p_depth_0)->differential_0 = 0.0f;
    DiffPair_float_0 p_transmittance_0;
    (&p_transmittance_0)->primal_0 = transmittance_1;
    (&p_transmittance_0)->differential_0 = 0.0f;
    s_bwd_rendered_depth_to_expected_depth_0(&p_depth_0, &p_transmittance_0, v_out_depth_0);
    *v_depth_0 = p_depth_0.differential_0;
    *v_transmittance_0 = p_transmittance_0.differential_0;
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

inline __device__ float dot_1(float2  x_1, float2  y_1)
{
    int i_1 = int(0);
    float result_2 = 0.0f;
    for(;;)
    {
        if(i_1 < int(2))
        {
        }
        else
        {
            break;
        }
        float result_3 = result_2 + _slang_vector_get_element(x_1, i_1) * _slang_vector_get_element(y_1, i_1);
        i_1 = i_1 + int(1);
        result_2 = result_3;
    }
    return result_2;
}

inline __device__ void blend_background_bwd_impl_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dp_rgb_0, DiffPair_float_0 * dp_transmittance_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * dp_background_0, float3  v_out_0)
{
    DiffPair_float_0 _S15 = *dp_transmittance_0;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S16 = *dp_background_0;
    dp_rgb_0->primal_0 = (*dp_rgb_0).primal_0;
    dp_rgb_0->differential_0 = v_out_0;
    float _S17 = dot_0(_S16.primal_0, v_out_0);
    dp_transmittance_0->primal_0 = _S15.primal_0;
    dp_transmittance_0->differential_0 = _S17;
    float3  _S18 = make_float3 (_S15.primal_0) * v_out_0;
    dp_background_0->primal_0 = _S16.primal_0;
    dp_background_0->differential_0 = _S18;
    return;
}

inline __device__ float3  blend_background(float3  rgb_0, float transmittance_2, float3  background_0)
{
    return rgb_0 + make_float3 (transmittance_2) * background_0;
}

inline __device__ float3  min_0(float3  x_2, float3  y_2)
{
    float3  result_4;
    int i_2 = int(0);
    for(;;)
    {
        if(i_2 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_4, i_2) = (F32_min((_slang_vector_get_element(x_2, i_2)), (_slang_vector_get_element(y_2, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_4;
}

inline __device__ float3  max_0(float3  x_3, float3  y_3)
{
    float3  result_5;
    int i_3 = int(0);
    for(;;)
    {
        if(i_3 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_5, i_3) = (F32_max((_slang_vector_get_element(x_3, i_3)), (_slang_vector_get_element(y_3, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_5;
}

inline __device__ float3  overexposure_grad(float3  c_0, float scale_0)
{
    float3  _S19 = make_float3 (0.0f);
    return make_float3 (scale_0) * (min_0(c_0, _S19) + max_0(c_0 - make_float3 (1.0f), _S19));
}

inline __device__ void blend_background_bwd(float3  rgb_1, float transmittance_3, float3  background_1, float3  v_out_rgb_0, float overexposure_scale_0, float3  * v_rgb_0, float * v_transmittance_1, float3  * v_background_0)
{
    float3  _S20;
    if(overexposure_scale_0 != 0.0f)
    {
        _S20 = v_out_rgb_0 + overexposure_grad(rgb_1 + make_float3 (transmittance_3) * background_1, overexposure_scale_0);
    }
    else
    {
        _S20 = v_out_rgb_0;
    }
    float3  _S21 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 p_rgb_0;
    (&p_rgb_0)->primal_0 = rgb_1;
    (&p_rgb_0)->differential_0 = _S21;
    DiffPair_float_0 p_transmittance_1;
    (&p_transmittance_1)->primal_0 = transmittance_3;
    (&p_transmittance_1)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 p_background_0;
    (&p_background_0)->primal_0 = background_1;
    (&p_background_0)->differential_0 = _S21;
    blend_background_bwd_impl_0(&p_rgb_0, &p_transmittance_1, &p_background_0, _S20);
    *v_rgb_0 = p_rgb_0.differential_0;
    *v_transmittance_1 = p_transmittance_1.differential_0;
    *v_background_0 = p_background_0.differential_0;
    return;
}

inline __device__ void _d_pow_0(DiffPair_float_0 * dpx_2, DiffPair_float_0 * dpy_2, float dOut_2)
{
    if(((*dpx_2).primal_0) < 9.99999997475242708e-07f)
    {
        dpx_2->primal_0 = (*dpx_2).primal_0;
        dpx_2->differential_0 = 0.0f;
        dpy_2->primal_0 = (*dpy_2).primal_0;
        dpy_2->differential_0 = 0.0f;
    }
    else
    {
        float val_0 = (F32_pow(((*dpx_2).primal_0), ((*dpy_2).primal_0)));
        DiffPair_float_0 _S22 = *dpx_2;
        float _S23 = val_0 * (*dpy_2).primal_0 / (*dpx_2).primal_0 * dOut_2;
        dpx_2->primal_0 = (*dpx_2).primal_0;
        dpx_2->differential_0 = _S23;
        float _S24 = val_0 * (F32_log((_S22.primal_0))) * dOut_2;
        dpy_2->primal_0 = (*dpy_2).primal_0;
        dpy_2->differential_0 = _S24;
    }
    return;
}

inline __device__ DiffPair_float_0 _d_pow_1(DiffPair_float_0 * dpx_3, DiffPair_float_0 * dpy_3)
{
    float _S25 = dpx_3->primal_0;
    if((dpx_3->primal_0) < 9.99999997475242708e-07f)
    {
        DiffPair_float_0 _S26 = { 0.0f, 0.0f };
        return _S26;
    }
    float val_1 = (F32_pow((_S25), (dpy_3->primal_0)));
    DiffPair_float_0 _S27 = { val_1, val_1 * (F32_log((_S25))) * dpy_3->differential_0 + val_1 * dpy_3->primal_0 / _S25 * dpx_3->differential_0 };
    return _S27;
}

inline __device__ float linear_rgb_to_srgb(float x_4)
{
    float _S28;
    if(x_4 < 0.00313080009073019f)
    {
        _S28 = x_4 * 12.92000007629394531f;
    }
    else
    {
        _S28 = 1.0549999475479126f * (F32_pow((x_4), (0.4166666567325592f))) - 0.05499999970197678f;
    }
    return _S28;
}

inline __device__ float linear_rgb_to_srgb_grad(float x_5)
{
    float _S29;
    if(x_5 < 0.00313080009073019f)
    {
        _S29 = 12.92000007629394531f;
    }
    else
    {
        DiffPair_float_0 _S30;
        (&_S30)->primal_0 = x_5;
        (&_S30)->differential_0 = 1.0f;
        DiffPair_float_0 _S31;
        (&_S31)->primal_0 = 0.4166666567325592f;
        (&_S31)->differential_0 = 0.0f;
        DiffPair_float_0 _S32 = _d_pow_1(&_S30, &_S31);
        _S29 = _S32.differential_0 * 1.0549999475479126f;
    }
    return _S29;
}

inline __device__ float srgb_to_linear_rgb(float x_6)
{
    float _S33;
    if(x_6 < 0.04044999927282333f)
    {
        _S33 = x_6 * 0.07739938050508499f;
    }
    else
    {
        _S33 = (F32_pow((0.94786733388900757f * (x_6 + 0.05499999970197678f)), (2.40000009536743164f)));
    }
    return _S33;
}

inline __device__ float srgb_to_linear_rgb_grad(float x_7)
{
    float _S34;
    if(x_7 < 0.04044999927282333f)
    {
        _S34 = 0.07739938050508499f;
    }
    else
    {
        DiffPair_float_0 _S35;
        (&_S35)->primal_0 = 0.94786733388900757f * (x_7 + 0.05499999970197678f);
        (&_S35)->differential_0 = 0.94786733388900757f;
        DiffPair_float_0 _S36;
        (&_S36)->primal_0 = 2.40000009536743164f;
        (&_S36)->differential_0 = 0.0f;
        DiffPair_float_0 _S37 = _d_pow_1(&_S35, &_S36);
        _S34 = _S37.differential_0;
    }
    return _S34;
}

inline __device__ float splat_dc_encode(float dc_0)
{
    return 2.0f * (F32_log(((F32_max((0.564189612865448f * dc_0 + 1.0f), (9.999999960041972e-13f))))));
}

inline __device__ float splat_dc_decode(float x_8)
{
    return ((F32_exp((0.5f * x_8))) - 1.0f) * 1.77245378494262695f;
}

struct DiffPair_matrixx3Cfloatx2C3x2C3x3E_0
{
    Matrix<float, 3, 3>  primal_0;
    Matrix<float, 3, 3>  differential_0;
};

inline __device__ void _d_mul_0(DiffPair_matrixx3Cfloatx2C3x2C3x3E_0 * left_0, DiffPair_vectorx3Cfloatx2C3x3E_0 * right_0, float3  dOut_3)
{
    float _S38 = (*left_0).primal_0.rows[int(0)].x * dOut_3.x;
    Matrix<float, 3, 3>  left_d_result_0;
    *&(((&left_d_result_0)->rows + (int(0)))->x) = (*right_0).primal_0.x * dOut_3.x;
    float sum_0 = _S38 + (*left_0).primal_0.rows[int(1)].x * dOut_3.y;
    *&(((&left_d_result_0)->rows + (int(1)))->x) = (*right_0).primal_0.x * dOut_3.y;
    float sum_1 = sum_0 + (*left_0).primal_0.rows[int(2)].x * dOut_3.z;
    *&(((&left_d_result_0)->rows + (int(2)))->x) = (*right_0).primal_0.x * dOut_3.z;
    float3  right_d_result_0;
    *&((&right_d_result_0)->x) = sum_1;
    float _S39 = (*left_0).primal_0.rows[int(0)].y * dOut_3.x;
    *&(((&left_d_result_0)->rows + (int(0)))->y) = (*right_0).primal_0.y * dOut_3.x;
    float sum_2 = _S39 + (*left_0).primal_0.rows[int(1)].y * dOut_3.y;
    *&(((&left_d_result_0)->rows + (int(1)))->y) = (*right_0).primal_0.y * dOut_3.y;
    float sum_3 = sum_2 + (*left_0).primal_0.rows[int(2)].y * dOut_3.z;
    *&(((&left_d_result_0)->rows + (int(2)))->y) = (*right_0).primal_0.y * dOut_3.z;
    *&((&right_d_result_0)->y) = sum_3;
    float _S40 = (*left_0).primal_0.rows[int(0)].z * dOut_3.x;
    *&(((&left_d_result_0)->rows + (int(0)))->z) = (*right_0).primal_0.z * dOut_3.x;
    float sum_4 = _S40 + (*left_0).primal_0.rows[int(1)].z * dOut_3.y;
    *&(((&left_d_result_0)->rows + (int(1)))->z) = (*right_0).primal_0.z * dOut_3.y;
    float sum_5 = sum_4 + (*left_0).primal_0.rows[int(2)].z * dOut_3.z;
    *&(((&left_d_result_0)->rows + (int(2)))->z) = (*right_0).primal_0.z * dOut_3.z;
    *&((&right_d_result_0)->z) = sum_5;
    left_0->primal_0 = (*left_0).primal_0;
    left_0->differential_0 = left_d_result_0;
    right_0->primal_0 = (*right_0).primal_0;
    right_0->differential_0 = right_d_result_0;
    return;
}

inline __device__ float3  mul_0(Matrix<float, 3, 3>  left_1, float3  right_1)
{
    float3  result_6;
    int i_4 = int(0);
    for(;;)
    {
        if(i_4 < int(3))
        {
        }
        else
        {
            break;
        }
        int j_0 = int(0);
        float sum_6 = 0.0f;
        for(;;)
        {
            if(j_0 < int(3))
            {
            }
            else
            {
                break;
            }
            float sum_7 = sum_6 + _slang_vector_get_element(left_1.rows[i_4], j_0) * _slang_vector_get_element(right_1, j_0);
            j_0 = j_0 + int(1);
            sum_6 = sum_7;
        }
        *_slang_vector_get_element_ptr(&result_6, i_4) = sum_6;
        i_4 = i_4 + int(1);
    }
    return result_6;
}

inline __device__ void xfer_pass_grad_0(DiffPair_float_0 * dp_0, float v_out_1)
{
    dp_0->primal_0 = (*dp_0).primal_0;
    dp_0->differential_0 = v_out_1;
    return;
}

inline __device__ float xfer_max0_0(float x_9)
{
    return (F32_max((x_9), (0.0f)));
}

inline __device__ float xfer_filmic_0(float x_10)
{
    float t_0 = xfer_max0_0(x_10 - 0.00400000018998981f);
    float _S41 = 6.19999980926513672f * t_0;
    return t_0 * (_S41 + 0.5f) / (t_0 * (_S41 + 1.70000004768371582f) + 0.05999999865889549f);
}

inline __device__ float xfer_aces_0(float x_11)
{
    return x_11 * (2.50999999046325684f * x_11 + 0.02999999932944775f) / (x_11 * (2.43000006675720215f * x_11 + 0.5899999737739563f) + 0.14000000059604645f);
}

inline __device__ float clamp_0(float x_12, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_12), (minBound_0)))), (maxBound_0)));
}

inline __device__ float xfer_clamp01_0(float x_13)
{
    return clamp_0(x_13, 0.0f, 1.0f);
}

inline __device__ float xfer_hable_0(float x_14)
{
    float _S42 = 0.15000000596046448f * x_14;
    return (x_14 * (_S42 + 0.05000000074505806f) + 0.00400000018998981f) / (x_14 * (_S42 + 0.5f) + 0.06000000238418579f) - 0.06666666269302368f;
}

inline __device__ float xfer_uncharted2_0(float x_15)
{
    return xfer_hable_0(xfer_max0_0(x_15)) / xfer_hable_0(11.19999980926513672f);
}

inline __device__ float tone_encode_0(float x_16, int transfer_0)
{
    if(transfer_0 == int(3))
    {
        return xfer_filmic_0(x_16);
    }
    float _S43;
    if(transfer_0 == int(2))
    {
        float _S44 = xfer_clamp01_0(xfer_aces_0(xfer_max0_0(x_16)));
        if(_S44 < 0.00313080009073019f)
        {
            _S43 = _S44 * 12.92000007629394531f;
        }
        else
        {
            _S43 = 1.0549999475479126f * (F32_pow((_S44), (0.4166666567325592f))) - 0.05499999970197678f;
        }
        return _S43;
    }
    if(transfer_0 == int(4))
    {
        float _S45 = xfer_clamp01_0(xfer_uncharted2_0(x_16));
        if(_S45 < 0.00313080009073019f)
        {
            _S43 = _S45 * 12.92000007629394531f;
        }
        else
        {
            _S43 = 1.0549999475479126f * (F32_pow((_S45), (0.4166666567325592f))) - 0.05499999970197678f;
        }
        return _S43;
    }
    if(transfer_0 == int(1))
    {
        float _S46 = xfer_clamp01_0(x_16);
        if(_S46 < 0.00313080009073019f)
        {
            _S43 = _S46 * 12.92000007629394531f;
        }
        else
        {
            _S43 = 1.0549999475479126f * (F32_pow((_S46), (0.4166666567325592f))) - 0.05499999970197678f;
        }
        return _S43;
    }
    if(x_16 < 0.00313080009073019f)
    {
        _S43 = x_16 * 12.92000007629394531f;
    }
    else
    {
        _S43 = 1.0549999475479126f * (F32_pow((x_16), (0.4166666567325592f))) - 0.05499999970197678f;
    }
    return _S43;
}

inline __device__ float3  working_to_display(float3  rgb_2, Matrix<float, 3, 3>  color_matrix_0, int transfer_1, bool is_linear_0)
{
    float3  _S47;
    if(!is_linear_0)
    {
        float _S48 = rgb_2.x;
        float _S49;
        if(_S48 < 0.04044999927282333f)
        {
            _S49 = _S48 * 0.07739938050508499f;
        }
        else
        {
            _S49 = (F32_pow((0.94786733388900757f * (_S48 + 0.05499999970197678f)), (2.40000009536743164f)));
        }
        float _S50 = rgb_2.y;
        float _S51;
        if(_S50 < 0.04044999927282333f)
        {
            _S51 = _S50 * 0.07739938050508499f;
        }
        else
        {
            _S51 = (F32_pow((0.94786733388900757f * (_S50 + 0.05499999970197678f)), (2.40000009536743164f)));
        }
        float _S52 = rgb_2.z;
        float _S53;
        if(_S52 < 0.04044999927282333f)
        {
            _S53 = _S52 * 0.07739938050508499f;
        }
        else
        {
            _S53 = (F32_pow((0.94786733388900757f * (_S52 + 0.05499999970197678f)), (2.40000009536743164f)));
        }
        _S47 = make_float3 (_S49, _S51, _S53);
    }
    else
    {
        _S47 = rgb_2;
    }
    float3  _S54 = mul_0(color_matrix_0, _S47);
    return make_float3 (tone_encode_0(_S54.x, transfer_1), tone_encode_0(_S54.y, transfer_1), tone_encode_0(_S54.z, transfer_1));
}

inline __device__ float s_primal_ctx_pow_0(float _S55, float _S56)
{
    return (F32_pow((_S55), (_S56)));
}

inline __device__ float3  s_primal_ctx_mul_0(Matrix<float, 3, 3>  _S57, float3  _S58)
{
    return mul_0(_S57, _S58);
}

inline __device__ float s_primal_ctx_xfer_max0_0(float _S59)
{
    return xfer_max0_0(_S59);
}

inline __device__ float s_primal_ctx_xfer_aces_0(float dpx_4)
{
    return dpx_4 * (2.50999999046325684f * dpx_4 + 0.02999999932944775f) / (dpx_4 * (2.43000006675720215f * dpx_4 + 0.5899999737739563f) + 0.14000000059604645f);
}

inline __device__ float s_primal_ctx_xfer_clamp01_0(float _S60)
{
    return xfer_clamp01_0(_S60);
}

inline __device__ float s_primal_ctx_xfer_hable_0(float dpx_5)
{
    float _S61 = 0.15000000596046448f * dpx_5;
    return (dpx_5 * (_S61 + 0.05000000074505806f) + 0.00400000018998981f) / (dpx_5 * (_S61 + 0.5f) + 0.06000000238418579f) - 0.06666666269302368f;
}

inline __device__ float s_primal_ctx_xfer_uncharted2_0(float dpx_6)
{
    return s_primal_ctx_xfer_hable_0(s_primal_ctx_xfer_max0_0(dpx_6)) / s_primal_ctx_xfer_hable_0(11.19999980926513672f);
}

inline __device__ void s_bwd_prop_pow_0(DiffPair_float_0 * _S62, DiffPair_float_0 * _S63, float _S64)
{
    _d_pow_0(_S62, _S63, _S64);
    return;
}

inline __device__ void s_bwd_prop_xfer_clamp01_0(DiffPair_float_0 * _S65, float _S66)
{
    xfer_pass_grad_0(_S65, _S66);
    return;
}

inline __device__ void s_bwd_prop_xfer_hable_0(DiffPair_float_0 * dpx_7, float _s_dOut_1)
{
    float _S67 = 0.15000000596046448f * (*dpx_7).primal_0;
    float _S68 = _S67 + 0.05000000074505806f;
    float _S69 = _S67 + 0.5f;
    float _S70 = (*dpx_7).primal_0 * _S69 + 0.06000000238418579f;
    float _S71 = _s_dOut_1 / (_S70 * _S70);
    float _S72 = ((*dpx_7).primal_0 * _S68 + 0.00400000018998981f) * - _S71;
    float _S73 = _S70 * _S71;
    float _S74 = _S69 * _S72 + _S68 * _S73 + 0.15000000596046448f * ((*dpx_7).primal_0 * _S72 + (*dpx_7).primal_0 * _S73);
    dpx_7->primal_0 = (*dpx_7).primal_0;
    dpx_7->differential_0 = _S74;
    return;
}

inline __device__ void s_bwd_prop_xfer_max0_0(DiffPair_float_0 * _S75, float _S76)
{
    xfer_pass_grad_0(_S75, _S76);
    return;
}

inline __device__ void s_bwd_prop_xfer_uncharted2_0(DiffPair_float_0 * dpx_8, float _s_dOut_2)
{
    float _S77 = s_primal_ctx_xfer_hable_0(11.19999980926513672f);
    float _S78 = _S77 * (_s_dOut_2 / (_S77 * _S77));
    DiffPair_float_0 _S79;
    (&_S79)->primal_0 = s_primal_ctx_xfer_max0_0((*dpx_8).primal_0);
    (&_S79)->differential_0 = 0.0f;
    s_bwd_prop_xfer_hable_0(&_S79, _S78);
    DiffPair_float_0 _S80;
    (&_S80)->primal_0 = (*dpx_8).primal_0;
    (&_S80)->differential_0 = 0.0f;
    s_bwd_prop_xfer_max0_0(&_S80, _S79.differential_0);
    dpx_8->primal_0 = (*dpx_8).primal_0;
    dpx_8->differential_0 = _S80.differential_0;
    return;
}

inline __device__ void s_bwd_prop_xfer_aces_0(DiffPair_float_0 * dpx_9, float _s_dOut_3)
{
    float _S81 = 2.50999999046325684f * (*dpx_9).primal_0 + 0.02999999932944775f;
    float _S82 = 2.43000006675720215f * (*dpx_9).primal_0 + 0.5899999737739563f;
    float _S83 = (*dpx_9).primal_0 * _S82 + 0.14000000059604645f;
    float _S84 = _s_dOut_3 / (_S83 * _S83);
    float _S85 = (*dpx_9).primal_0 * _S81 * - _S84;
    float _S86 = _S83 * _S84;
    float _S87 = _S82 * _S85 + 2.43000006675720215f * ((*dpx_9).primal_0 * _S85) + _S81 * _S86 + 2.50999999046325684f * ((*dpx_9).primal_0 * _S86);
    dpx_9->primal_0 = (*dpx_9).primal_0;
    dpx_9->differential_0 = _S87;
    return;
}

inline __device__ void s_bwd_prop_xfer_filmic_0(DiffPair_float_0 * dpx_10, float _s_dOut_4)
{
    float _S88 = (*dpx_10).primal_0 - 0.00400000018998981f;
    float _S89 = s_primal_ctx_xfer_max0_0(_S88);
    float _S90 = 6.19999980926513672f * _S89;
    float _S91 = _S90 + 0.5f;
    float _S92 = _S90 + 1.70000004768371582f;
    float _S93 = _S89 * _S92 + 0.05999999865889549f;
    float _S94 = _s_dOut_4 / (_S93 * _S93);
    float _S95 = _S89 * _S91 * - _S94;
    float _S96 = _S93 * _S94;
    float _S97 = _S92 * _S95 + _S91 * _S96 + 6.19999980926513672f * (_S89 * _S95 + _S89 * _S96);
    DiffPair_float_0 _S98;
    (&_S98)->primal_0 = _S88;
    (&_S98)->differential_0 = 0.0f;
    s_bwd_prop_xfer_max0_0(&_S98, _S97);
    dpx_10->primal_0 = (*dpx_10).primal_0;
    dpx_10->differential_0 = _S98.differential_0;
    return;
}

inline __device__ void s_bwd_prop_tone_encode_0(DiffPair_float_0 * dpx_11, int transfer_2, float _s_dOut_5)
{
    DiffPair_float_0 _S99 = *dpx_11;
    bool _S100 = transfer_2 == int(3);
    bool _S101 = !_S100;
    bool _runFlag_0;
    bool _runFlag_1;
    bool _runFlag_2;
    bool _S102;
    bool _S103;
    bool _S104;
    float _S105;
    float _S106;
    float _S107;
    float _S108;
    float _S109;
    float _S110;
    if(_S101)
    {
        bool _S111 = transfer_2 == int(2);
        if(_S111)
        {
            float _S112 = s_primal_ctx_xfer_max0_0(_S99.primal_0);
            float _S113 = s_primal_ctx_xfer_aces_0(_S112);
            float _S114 = s_primal_ctx_xfer_clamp01_0(_S113);
            _runFlag_0 = false;
            _S105 = _S114;
            _S106 = _S113;
            _S107 = _S112;
        }
        else
        {
            _runFlag_0 = _S101;
            _S105 = 0.0f;
            _S106 = 0.0f;
            _S107 = 0.0f;
        }
        if(_runFlag_0)
        {
            bool _S115 = transfer_2 == int(4);
            if(_S115)
            {
                float _S116 = s_primal_ctx_xfer_uncharted2_0(_S99.primal_0);
                float _S117 = s_primal_ctx_xfer_clamp01_0(_S116);
                _runFlag_1 = false;
                _S108 = _S117;
                _S109 = _S116;
            }
            else
            {
                _runFlag_1 = _runFlag_0;
                _S108 = 0.0f;
                _S109 = 0.0f;
            }
            if(_runFlag_1)
            {
                bool _S118 = transfer_2 == int(1);
                if(_S118)
                {
                    float _S119 = s_primal_ctx_xfer_clamp01_0(_S99.primal_0);
                    _runFlag_2 = false;
                    _S110 = _S119;
                }
                else
                {
                    _runFlag_2 = _runFlag_1;
                    _S110 = 0.0f;
                }
                _S102 = _S118;
            }
            else
            {
                _runFlag_2 = false;
                _S102 = false;
                _S110 = 0.0f;
            }
            float _S120 = _S108;
            float _S121 = _S109;
            _S108 = _S110;
            _S103 = _S115;
            _S109 = _S120;
            _S110 = _S121;
        }
        else
        {
            _runFlag_1 = false;
            _runFlag_2 = false;
            _S102 = false;
            _S108 = 0.0f;
            _S103 = false;
            _S109 = 0.0f;
            _S110 = 0.0f;
        }
        float _S122 = _S105;
        float _S123 = _S106;
        float _S124 = _S107;
        _S105 = _S108;
        _S106 = _S109;
        _S107 = _S110;
        _S104 = _S111;
        _S108 = _S122;
        _S109 = _S123;
        _S110 = _S124;
    }
    else
    {
        _runFlag_0 = false;
        _runFlag_1 = false;
        _runFlag_2 = false;
        _S102 = false;
        _S105 = 0.0f;
        _S103 = false;
        _S106 = 0.0f;
        _S107 = 0.0f;
        _S104 = false;
        _S108 = 0.0f;
        _S109 = 0.0f;
        _S110 = 0.0f;
    }
    if(_S101)
    {
        if(_runFlag_0)
        {
            float _S125;
            if(_runFlag_1)
            {
                float _S126;
                if(_runFlag_2)
                {
                    if((_S99.primal_0) < 0.00313080009073019f)
                    {
                        _S125 = 12.92000007629394531f * _s_dOut_5;
                    }
                    else
                    {
                        float _S127 = 1.0549999475479126f * _s_dOut_5;
                        DiffPair_float_0 _S128;
                        (&_S128)->primal_0 = _S99.primal_0;
                        (&_S128)->differential_0 = 0.0f;
                        DiffPair_float_0 _S129;
                        (&_S129)->primal_0 = 0.4166666567325592f;
                        (&_S129)->differential_0 = 0.0f;
                        s_bwd_prop_pow_0(&_S128, &_S129, _S127);
                        _S125 = _S128.differential_0;
                    }
                    float _S130 = _S125;
                    _S125 = 0.0f;
                    _S126 = _S130;
                }
                else
                {
                    _S125 = _s_dOut_5;
                    _S126 = 0.0f;
                }
                if(_S102)
                {
                    if(_S105 < 0.00313080009073019f)
                    {
                        _S105 = 12.92000007629394531f * _S125;
                    }
                    else
                    {
                        float _S131 = 1.0549999475479126f * _S125;
                        DiffPair_float_0 _S132;
                        (&_S132)->primal_0 = _S105;
                        (&_S132)->differential_0 = 0.0f;
                        DiffPair_float_0 _S133;
                        (&_S133)->primal_0 = 0.4166666567325592f;
                        (&_S133)->differential_0 = 0.0f;
                        s_bwd_prop_pow_0(&_S132, &_S133, _S131);
                        _S105 = _S132.differential_0;
                    }
                    DiffPair_float_0 _S134;
                    (&_S134)->primal_0 = _S99.primal_0;
                    (&_S134)->differential_0 = 0.0f;
                    s_bwd_prop_xfer_clamp01_0(&_S134, _S105);
                    float _S135 = _S134.differential_0 + _S126;
                    _S105 = 0.0f;
                    _S125 = _S135;
                }
                else
                {
                    _S105 = _S125;
                    _S125 = _S126;
                }
            }
            else
            {
                _S105 = _s_dOut_5;
                _S125 = 0.0f;
            }
            if(_S103)
            {
                if(_S106 < 0.00313080009073019f)
                {
                    _S105 = 12.92000007629394531f * _S105;
                }
                else
                {
                    float _S136 = 1.0549999475479126f * _S105;
                    DiffPair_float_0 _S137;
                    (&_S137)->primal_0 = _S106;
                    (&_S137)->differential_0 = 0.0f;
                    DiffPair_float_0 _S138;
                    (&_S138)->primal_0 = 0.4166666567325592f;
                    (&_S138)->differential_0 = 0.0f;
                    s_bwd_prop_pow_0(&_S137, &_S138, _S136);
                    _S105 = _S137.differential_0;
                }
                DiffPair_float_0 _S139;
                (&_S139)->primal_0 = _S107;
                (&_S139)->differential_0 = 0.0f;
                s_bwd_prop_xfer_clamp01_0(&_S139, _S105);
                DiffPair_float_0 _S140;
                (&_S140)->primal_0 = _S99.primal_0;
                (&_S140)->differential_0 = 0.0f;
                s_bwd_prop_xfer_uncharted2_0(&_S140, _S139.differential_0);
                float _S141 = _S140.differential_0 + _S125;
                _S105 = 0.0f;
                _S106 = _S141;
            }
            else
            {
                _S106 = _S125;
            }
        }
        else
        {
            _S105 = _s_dOut_5;
            _S106 = 0.0f;
        }
        if(_S104)
        {
            if(_S108 < 0.00313080009073019f)
            {
                _S105 = 12.92000007629394531f * _S105;
            }
            else
            {
                float _S142 = 1.0549999475479126f * _S105;
                DiffPair_float_0 _S143;
                (&_S143)->primal_0 = _S108;
                (&_S143)->differential_0 = 0.0f;
                DiffPair_float_0 _S144;
                (&_S144)->primal_0 = 0.4166666567325592f;
                (&_S144)->differential_0 = 0.0f;
                s_bwd_prop_pow_0(&_S143, &_S144, _S142);
                _S105 = _S143.differential_0;
            }
            DiffPair_float_0 _S145;
            (&_S145)->primal_0 = _S109;
            (&_S145)->differential_0 = 0.0f;
            s_bwd_prop_xfer_clamp01_0(&_S145, _S105);
            DiffPair_float_0 _S146;
            (&_S146)->primal_0 = _S110;
            (&_S146)->differential_0 = 0.0f;
            s_bwd_prop_xfer_aces_0(&_S146, _S145.differential_0);
            DiffPair_float_0 _S147;
            (&_S147)->primal_0 = _S99.primal_0;
            (&_S147)->differential_0 = 0.0f;
            s_bwd_prop_xfer_max0_0(&_S147, _S146.differential_0);
            float _S148 = _S147.differential_0 + _S106;
            _S105 = 0.0f;
            _S106 = _S148;
        }
    }
    else
    {
        _S105 = _s_dOut_5;
        _S106 = 0.0f;
    }
    if(_S100)
    {
        DiffPair_float_0 _S149;
        (&_S149)->primal_0 = _S99.primal_0;
        (&_S149)->differential_0 = 0.0f;
        s_bwd_prop_xfer_filmic_0(&_S149, _S105);
        _S105 = _S149.differential_0 + _S106;
    }
    else
    {
        _S105 = _S106;
    }
    dpx_11->primal_0 = (*dpx_11).primal_0;
    dpx_11->differential_0 = _S105;
    return;
}

inline __device__ void s_bwd_prop_mul_0(DiffPair_matrixx3Cfloatx2C3x2C3x3E_0 * _S150, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S151, float3  _S152)
{
    _d_mul_0(_S150, _S151, _S152);
    return;
}

inline __device__ void s_bwd_prop_working_to_display_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dprgb_0, Matrix<float, 3, 3>  color_matrix_1, int transfer_3, bool is_linear_1, float3  _s_dOut_6)
{
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S153 = *dprgb_0;
    bool _S154 = !is_linear_1;
    float _S155;
    float _S156;
    float _S157;
    float3  _S158;
    if(_S154)
    {
        float _S159 = _S153.primal_0.x;
        if(_S159 < 0.04044999927282333f)
        {
            _S155 = _S159 * 0.07739938050508499f;
        }
        else
        {
            _S155 = s_primal_ctx_pow_0(0.94786733388900757f * (_S159 + 0.05499999970197678f), 2.40000009536743164f);
        }
        float _S160 = _S153.primal_0.y;
        if(_S160 < 0.04044999927282333f)
        {
            _S156 = _S160 * 0.07739938050508499f;
        }
        else
        {
            _S156 = s_primal_ctx_pow_0(0.94786733388900757f * (_S160 + 0.05499999970197678f), 2.40000009536743164f);
        }
        float _S161 = _S153.primal_0.z;
        if(_S161 < 0.04044999927282333f)
        {
            _S157 = _S161 * 0.07739938050508499f;
        }
        else
        {
            _S157 = s_primal_ctx_pow_0(0.94786733388900757f * (_S161 + 0.05499999970197678f), 2.40000009536743164f);
        }
        _S158 = make_float3 (_S155, _S156, _S157);
        _S155 = _S161;
        _S156 = _S160;
        _S157 = _S159;
    }
    else
    {
        _S158 = _S153.primal_0;
        _S155 = 0.0f;
        _S156 = 0.0f;
        _S157 = 0.0f;
    }
    float3  _S162 = s_primal_ctx_mul_0(color_matrix_1, _S158);
    float _S163 = _S162.x;
    float _S164 = _S162.y;
    float _S165 = _S162.z;
    DiffPair_float_0 _S166;
    (&_S166)->primal_0 = _S165;
    (&_S166)->differential_0 = 0.0f;
    s_bwd_prop_tone_encode_0(&_S166, transfer_3, _s_dOut_6.z);
    DiffPair_float_0 _S167;
    (&_S167)->primal_0 = _S164;
    (&_S167)->differential_0 = 0.0f;
    s_bwd_prop_tone_encode_0(&_S167, transfer_3, _s_dOut_6.y);
    DiffPair_float_0 _S168;
    (&_S168)->primal_0 = _S163;
    (&_S168)->differential_0 = 0.0f;
    s_bwd_prop_tone_encode_0(&_S168, transfer_3, _s_dOut_6.x);
    float3  _S169 = make_float3 (_S168.differential_0, _S167.differential_0, _S166.differential_0);
    Matrix<float, 3, 3>  _S170 = makeMatrix<float, 3, 3> (0.0f);
    DiffPair_matrixx3Cfloatx2C3x2C3x3E_0 _S171;
    (&_S171)->primal_0 = color_matrix_1;
    (&_S171)->differential_0 = _S170;
    float3  _S172 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S173;
    (&_S173)->primal_0 = _S158;
    (&_S173)->differential_0 = _S172;
    s_bwd_prop_mul_0(&_S171, &_S173, _S169);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S174 = _S173;
    if(_S154)
    {
        bool _S175 = _S155 < 0.04044999927282333f;
        if(_S175)
        {
            _S155 = 0.0f;
        }
        else
        {
            _S155 = 0.94786733388900757f * (_S155 + 0.05499999970197678f);
        }
        if(_S175)
        {
            _S155 = 0.07739938050508499f * _S174.differential_0.z;
        }
        else
        {
            DiffPair_float_0 _S176;
            (&_S176)->primal_0 = _S155;
            (&_S176)->differential_0 = 0.0f;
            DiffPair_float_0 _S177;
            (&_S177)->primal_0 = 2.40000009536743164f;
            (&_S177)->differential_0 = 0.0f;
            s_bwd_prop_pow_0(&_S176, &_S177, _S174.differential_0.z);
            _S155 = 0.94786733388900757f * _S176.differential_0;
        }
        bool _S178 = _S156 < 0.04044999927282333f;
        if(_S178)
        {
            _S156 = 0.0f;
        }
        else
        {
            _S156 = 0.94786733388900757f * (_S156 + 0.05499999970197678f);
        }
        if(_S178)
        {
            _S156 = 0.07739938050508499f * _S174.differential_0.y;
        }
        else
        {
            DiffPair_float_0 _S179;
            (&_S179)->primal_0 = _S156;
            (&_S179)->differential_0 = 0.0f;
            DiffPair_float_0 _S180;
            (&_S180)->primal_0 = 2.40000009536743164f;
            (&_S180)->differential_0 = 0.0f;
            s_bwd_prop_pow_0(&_S179, &_S180, _S174.differential_0.y);
            _S156 = 0.94786733388900757f * _S179.differential_0;
        }
        bool _S181 = _S157 < 0.04044999927282333f;
        if(_S181)
        {
            _S157 = 0.0f;
        }
        else
        {
            _S157 = 0.94786733388900757f * (_S157 + 0.05499999970197678f);
        }
        if(_S181)
        {
            _S157 = 0.07739938050508499f * _S174.differential_0.x;
        }
        else
        {
            DiffPair_float_0 _S182;
            (&_S182)->primal_0 = _S157;
            (&_S182)->differential_0 = 0.0f;
            DiffPair_float_0 _S183;
            (&_S183)->primal_0 = 2.40000009536743164f;
            (&_S183)->differential_0 = 0.0f;
            s_bwd_prop_pow_0(&_S182, &_S183, _S174.differential_0.x);
            _S157 = 0.94786733388900757f * _S182.differential_0;
        }
        _S158 = make_float3 (_S157, _S156, _S155);
    }
    else
    {
        _S158 = _S174.differential_0;
    }
    dprgb_0->primal_0 = (*dprgb_0).primal_0;
    dprgb_0->differential_0 = _S158;
    return;
}

inline __device__ void s_bwd_working_to_display_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S184, Matrix<float, 3, 3>  _S185, int _S186, bool _S187, float3  _S188)
{
    s_bwd_prop_working_to_display_0(_S184, _S185, _S186, _S187, _S188);
    return;
}

inline __device__ float3  working_to_display_bwd(float3  rgb_3, Matrix<float, 3, 3>  color_matrix_2, int transfer_4, bool is_linear_2, float3  v_out_rgb_1)
{
    float3  _S189 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 p_rgb_1;
    (&p_rgb_1)->primal_0 = rgb_3;
    (&p_rgb_1)->differential_0 = _S189;
    s_bwd_working_to_display_0(&p_rgb_1, color_matrix_2, transfer_4, is_linear_2, v_out_rgb_1);
    return p_rgb_1.differential_0;
}

inline __device__ void _d_sqrt_0(DiffPair_float_0 * dpx_12, float dOut_4)
{
    float _S190 = 0.5f / (F32_sqrt(((F32_max((1.00000001168609742e-07f), ((*dpx_12).primal_0)))))) * dOut_4;
    dpx_12->primal_0 = (*dpx_12).primal_0;
    dpx_12->differential_0 = _S190;
    return;
}

inline __device__ float xfer_filmic_inv_0(float y_4)
{
    float _S191 = (F32_min((y_4), (xfer_filmic_0(11.19999980926513672f))));
    float a_0 = 6.19999980926513672f * (1.0f - _S191);
    float b_0 = 0.5f - 1.70000004768371582f * _S191;
    return (- b_0 + (F32_sqrt(((F32_max((b_0 * b_0 - 4.0f * a_0 * (-0.05999999865889549f * _S191)), (0.0f))))))) / (2.0f * a_0) + 0.00400000018998981f;
}

inline __device__ float xfer_aces_inv_0(float y_5)
{
    float a_1 = 2.50999999046325684f - 2.43000006675720215f * y_5;
    float b_1 = 0.02999999932944775f - 0.5899999737739563f * y_5;
    return (- b_1 + (F32_sqrt(((F32_max((b_1 * b_1 - 4.0f * a_1 * (-0.14000000059604645f * y_5)), (0.0f))))))) / (2.0f * a_1);
}

inline __device__ float xfer_uncharted2_inv_0(float y_6)
{
    float r_0 = y_6 * xfer_hable_0(11.19999980926513672f) + 0.06666666269302368f;
    float a_2 = 0.15000000596046448f * (1.0f - r_0);
    float b_2 = 0.5f * (0.10000000149011612f - r_0);
    return (- b_2 + (F32_sqrt(((F32_max((b_2 * b_2 - 4.0f * a_2 * (0.20000000298023224f * (0.01999999955296516f - r_0 * 0.30000001192092896f))), (0.0f))))))) / (2.0f * a_2);
}

inline __device__ float tone_decode_0(float d_0, int transfer_5)
{
    if(transfer_5 == int(3))
    {
        return xfer_filmic_inv_0(d_0);
    }
    float _S192;
    if(transfer_5 == int(2))
    {
        if(d_0 < 0.04044999927282333f)
        {
            _S192 = d_0 * 0.07739938050508499f;
        }
        else
        {
            _S192 = (F32_pow((0.94786733388900757f * (d_0 + 0.05499999970197678f)), (2.40000009536743164f)));
        }
        return xfer_aces_inv_0(_S192);
    }
    if(transfer_5 == int(4))
    {
        if(d_0 < 0.04044999927282333f)
        {
            _S192 = d_0 * 0.07739938050508499f;
        }
        else
        {
            _S192 = (F32_pow((0.94786733388900757f * (d_0 + 0.05499999970197678f)), (2.40000009536743164f)));
        }
        return xfer_uncharted2_inv_0(_S192);
    }
    if(d_0 < 0.04044999927282333f)
    {
        _S192 = d_0 * 0.07739938050508499f;
    }
    else
    {
        _S192 = (F32_pow((0.94786733388900757f * (d_0 + 0.05499999970197678f)), (2.40000009536743164f)));
    }
    return _S192;
}

inline __device__ float3  display_to_working3(float3  rgb_4, int transfer_6, bool is_linear_3)
{
    float _S193 = tone_decode_0(rgb_4.x, transfer_6);
    float _S194 = tone_decode_0(rgb_4.y, transfer_6);
    float _S195 = tone_decode_0(rgb_4.z, transfer_6);
    float3  lin_0 = make_float3 (_S193, _S194, _S195);
    if(is_linear_3)
    {
        return lin_0;
    }
    float _S196;
    if(_S193 < 0.00313080009073019f)
    {
        _S196 = _S193 * 12.92000007629394531f;
    }
    else
    {
        _S196 = 1.0549999475479126f * (F32_pow((_S193), (0.4166666567325592f))) - 0.05499999970197678f;
    }
    float _S197;
    if(_S194 < 0.00313080009073019f)
    {
        _S197 = _S194 * 12.92000007629394531f;
    }
    else
    {
        _S197 = 1.0549999475479126f * (F32_pow((_S194), (0.4166666567325592f))) - 0.05499999970197678f;
    }
    float _S198;
    if(_S195 < 0.00313080009073019f)
    {
        _S198 = _S195 * 12.92000007629394531f;
    }
    else
    {
        _S198 = 1.0549999475479126f * (F32_pow((_S195), (0.4166666567325592f))) - 0.05499999970197678f;
    }
    return make_float3 (_S196, _S197, _S198);
}

inline __device__ void _d_cross_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * a_3, DiffPair_vectorx3Cfloatx2C3x3E_0 * b_3, float3  dOut_5)
{
    float _S199 = dOut_5.y;
    float _S200 = dOut_5.z;
    float _S201 = dOut_5.x;
    float _S202 = (*a_3).primal_0.z * _S199 + - (*a_3).primal_0.y * _S200;
    float _S203 = - (*a_3).primal_0.z * _S201 + (*a_3).primal_0.x * _S200;
    float _S204 = (*a_3).primal_0.y * _S201 + - (*a_3).primal_0.x * _S199;
    float3  _S205 = make_float3 (- (*b_3).primal_0.z * _S199 + (*b_3).primal_0.y * _S200, (*b_3).primal_0.z * _S201 + - (*b_3).primal_0.x * _S200, - (*b_3).primal_0.y * _S201 + (*b_3).primal_0.x * _S199);
    a_3->primal_0 = (*a_3).primal_0;
    a_3->differential_0 = _S205;
    float3  _S206 = make_float3 (_S202, _S203, _S204);
    b_3->primal_0 = (*b_3).primal_0;
    b_3->differential_0 = _S206;
    return;
}

inline __device__ float3  cross_0(float3  left_2, float3  right_2)
{
    float _S207 = left_2.y;
    float _S208 = right_2.z;
    float _S209 = left_2.z;
    float _S210 = right_2.y;
    float _S211 = right_2.x;
    float _S212 = left_2.x;
    return make_float3 (_S207 * _S208 - _S209 * _S210, _S209 * _S211 - _S212 * _S208, _S212 * _S210 - _S207 * _S211);
}

inline __device__ float length_0(float3  x_17)
{
    return (F32_sqrt((dot_0(x_17, x_17))));
}

inline __device__ float length_1(float2  x_18)
{
    return (F32_sqrt((dot_1(x_18, x_18))));
}

inline __device__ float3  points_to_normal(FixedArray<float3 , 4>  points_0)
{
    float3  _S213 = points_0[int(0)];
    bool _S214;
    if((dot_0(_S213, _S213)) == 0.0f)
    {
        _S214 = true;
    }
    else
    {
        float3  _S215 = points_0[int(1)];
        _S214 = (dot_0(_S215, _S215)) == 0.0f;
    }
    if(_S214)
    {
        _S214 = true;
    }
    else
    {
        float3  _S216 = points_0[int(2)];
        _S214 = (dot_0(_S216, _S216)) == 0.0f;
    }
    if(_S214)
    {
        _S214 = true;
    }
    else
    {
        float3  _S217 = points_0[int(3)];
        _S214 = (dot_0(_S217, _S217)) == 0.0f;
    }
    if(_S214)
    {
        return make_float3 (0.0f);
    }
    float3  normal_0 = cross_0(points_0[int(1)] - points_0[int(0)], - (points_0[int(3)] - points_0[int(2)]));
    float3  normal_1;
    if((dot_0(normal_0, normal_0)) != 0.0f)
    {
        normal_1 = normal_0 / make_float3 (length_0(normal_0));
    }
    else
    {
        normal_1 = normal_0;
    }
    return normal_1;
}

struct DiffPair_arrayx3Cvectorx3Cfloatx2C3x3Ex2C4x3E_0
{
    FixedArray<float3 , 4>  primal_0;
    FixedArray<float3 , 4>  differential_0;
};

inline __device__ float s_primal_ctx_dot_0(float3  _S218, float3  _S219)
{
    return dot_0(_S218, _S219);
}

inline __device__ float3  s_primal_ctx_cross_0(float3  _S220, float3  _S221)
{
    return cross_0(_S220, _S221);
}

inline __device__ void s_bwd_prop_sqrt_0(DiffPair_float_0 * _S222, float _S223)
{
    _d_sqrt_0(_S222, _S223);
    return;
}

inline __device__ void s_bwd_prop_length_impl_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_13, float _s_dOut_7)
{
    float _S224 = (*dpx_13).primal_0.x;
    float _S225 = (*dpx_13).primal_0.y;
    float _S226 = (*dpx_13).primal_0.z;
    DiffPair_float_0 _S227;
    (&_S227)->primal_0 = _S224 * _S224 + _S225 * _S225 + _S226 * _S226;
    (&_S227)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S227, _s_dOut_7);
    float _S228 = (*dpx_13).primal_0.z * _S227.differential_0;
    float _S229 = _S228 + _S228;
    float _S230 = (*dpx_13).primal_0.y * _S227.differential_0;
    float _S231 = _S230 + _S230;
    float _S232 = (*dpx_13).primal_0.x * _S227.differential_0;
    float _S233 = _S232 + _S232;
    float3  _S234 = make_float3 (0.0f);
    *&((&_S234)->z) = _S229;
    *&((&_S234)->y) = _S231;
    *&((&_S234)->x) = _S233;
    dpx_13->primal_0 = (*dpx_13).primal_0;
    dpx_13->differential_0 = _S234;
    return;
}

inline __device__ void s_bwd_length_impl_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S235, float _S236)
{
    s_bwd_prop_length_impl_0(_S235, _S236);
    return;
}

inline __device__ void s_bwd_prop_dot_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S237, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S238, float _S239)
{
    _d_dot_0(_S237, _S238, _S239);
    return;
}

inline __device__ void s_bwd_prop_cross_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S240, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S241, float3  _S242)
{
    _d_cross_0(_S240, _S241, _S242);
    return;
}

inline __device__ void s_bwd_prop_points_to_normal_0(DiffPair_arrayx3Cvectorx3Cfloatx2C3x3Ex2C4x3E_0 * dppoints_0, float3  _s_dOut_8)
{
    FixedArray<float3 , 4>  _S243 = dppoints_0->primal_0;
    float3  _S244 = make_float3 (0.0f);
    float3  _S245 = dppoints_0->primal_0[int(0)];
    bool _S246 = (s_primal_ctx_dot_0(_S245, _S245)) == 0.0f;
    bool _S247;
    float3  _S248;
    if(_S246)
    {
        _S247 = true;
        _S248 = _S244;
    }
    else
    {
        float3  _S249 = _S243[int(1)];
        _S247 = (s_primal_ctx_dot_0(_S249, _S249)) == 0.0f;
        _S248 = _S243[int(1)];
    }
    bool _S250;
    float3  _S251;
    if(_S247)
    {
        _S250 = true;
        _S251 = _S244;
    }
    else
    {
        float3  _S252 = _S243[int(2)];
        _S250 = (s_primal_ctx_dot_0(_S252, _S252)) == 0.0f;
        _S251 = _S243[int(2)];
    }
    bool _S253;
    float3  _S254;
    if(_S250)
    {
        _S253 = true;
        _S254 = _S244;
    }
    else
    {
        float3  _S255 = _S243[int(3)];
        _S253 = (s_primal_ctx_dot_0(_S255, _S255)) == 0.0f;
        _S254 = _S243[int(3)];
    }
    bool _S256 = !_S253;
    float3  _S257;
    float3  _S258;
    float3  _S259;
    float3  _S260;
    float3  _S261;
    if(_S256)
    {
        float3  dx_0 = _S243[int(1)] - _S243[int(0)];
        float3  _S262 = - (_S243[int(3)] - _S243[int(2)]);
        float3  _S263 = s_primal_ctx_cross_0(dx_0, _S262);
        bool _S264 = (s_primal_ctx_dot_0(_S263, _S263)) != 0.0f;
        if(_S264)
        {
            float _S265 = length_0(_S263);
            float3  _S266 = make_float3 (_S265);
            _S257 = make_float3 (_S265 * _S265);
            _S258 = _S266;
        }
        else
        {
            _S257 = _S244;
            _S258 = _S244;
        }
        float3  _S267 = _S258;
        _S253 = _S264;
        _S258 = _S263;
        _S259 = _S267;
        _S260 = dx_0;
        _S261 = _S262;
    }
    else
    {
        _S253 = false;
        _S257 = _S244;
        _S258 = _S244;
        _S259 = _S244;
        _S260 = _S244;
        _S261 = _S244;
    }
    FixedArray<float3 , 4>  _S268;
    if(_S256)
    {
        if(_S253)
        {
            float3  _S269 = _s_dOut_8 / _S257;
            float3  _S270 = _S258 * - _S269;
            float3  _S271 = _S259 * _S269;
            float _S272 = _S270.x + _S270.y + _S270.z;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S273;
            (&_S273)->primal_0 = _S258;
            (&_S273)->differential_0 = _S244;
            s_bwd_length_impl_0(&_S273, _S272);
            _S257 = _S271 + _S273.differential_0;
        }
        else
        {
            _S257 = _s_dOut_8;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S274;
        (&_S274)->primal_0 = _S258;
        (&_S274)->differential_0 = _S244;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S275;
        (&_S275)->primal_0 = _S258;
        (&_S275)->differential_0 = _S244;
        s_bwd_prop_dot_0(&_S274, &_S275, 0.0f);
        float3  _S276 = _S275.differential_0 + _S274.differential_0 + _S257;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S277;
        (&_S277)->primal_0 = _S260;
        (&_S277)->differential_0 = _S244;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S278;
        (&_S278)->primal_0 = _S261;
        (&_S278)->differential_0 = _S244;
        s_bwd_prop_cross_0(&_S277, &_S278, _S276);
        float3  s_diff_dy_T_0 = - _S278.differential_0;
        float3  _S279 = - s_diff_dy_T_0;
        float3  _S280 = - _S277.differential_0;
        FixedArray<float3 , 4>  _S281;
        _S281[int(0)] = _S244;
        _S281[int(1)] = _S244;
        _S281[int(2)] = _S244;
        _S281[int(3)] = _S244;
        _S281[int(2)] = _S279;
        _S281[int(3)] = s_diff_dy_T_0;
        _S281[int(1)] = _S277.differential_0;
        _S268[int(0)] = _S281[int(0)];
        _S268[int(1)] = _S281[int(1)];
        _S268[int(2)] = _S281[int(2)];
        _S268[int(3)] = _S281[int(3)];
        _S257 = _S280;
    }
    else
    {
        _S268[int(0)] = _S244;
        _S268[int(1)] = _S244;
        _S268[int(2)] = _S244;
        _S268[int(3)] = _S244;
        _S257 = _S244;
    }
    if(_S250)
    {
    }
    else
    {
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S282;
        (&_S282)->primal_0 = _S254;
        (&_S282)->differential_0 = _S244;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S283;
        (&_S283)->primal_0 = _S254;
        (&_S283)->differential_0 = _S244;
        s_bwd_prop_dot_0(&_S282, &_S283, 0.0f);
        float3  _S284 = _S283.differential_0 + _S282.differential_0;
        FixedArray<float3 , 4>  _S285;
        _S285[int(0)] = _S244;
        _S285[int(1)] = _S244;
        _S285[int(2)] = _S244;
        _S285[int(3)] = _S244;
        _S285[int(3)] = _S284;
        float3  _S286 = _S268[int(1)] + _S285[int(1)];
        float3  _S287 = _S268[int(2)] + _S285[int(2)];
        float3  _S288 = _S268[int(3)] + _S285[int(3)];
        _S268[int(0)] = _S268[int(0)] + _S285[int(0)];
        _S268[int(1)] = _S286;
        _S268[int(2)] = _S287;
        _S268[int(3)] = _S288;
    }
    if(_S247)
    {
    }
    else
    {
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S289;
        (&_S289)->primal_0 = _S251;
        (&_S289)->differential_0 = _S244;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S290;
        (&_S290)->primal_0 = _S251;
        (&_S290)->differential_0 = _S244;
        s_bwd_prop_dot_0(&_S289, &_S290, 0.0f);
        float3  _S291 = _S290.differential_0 + _S289.differential_0;
        FixedArray<float3 , 4>  _S292;
        _S292[int(0)] = _S244;
        _S292[int(1)] = _S244;
        _S292[int(2)] = _S244;
        _S292[int(3)] = _S244;
        _S292[int(2)] = _S291;
        float3  _S293 = _S268[int(1)] + _S292[int(1)];
        float3  _S294 = _S268[int(2)] + _S292[int(2)];
        float3  _S295 = _S268[int(3)] + _S292[int(3)];
        _S268[int(0)] = _S268[int(0)] + _S292[int(0)];
        _S268[int(1)] = _S293;
        _S268[int(2)] = _S294;
        _S268[int(3)] = _S295;
    }
    if(_S246)
    {
    }
    else
    {
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S296;
        (&_S296)->primal_0 = _S248;
        (&_S296)->differential_0 = _S244;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S297;
        (&_S297)->primal_0 = _S248;
        (&_S297)->differential_0 = _S244;
        s_bwd_prop_dot_0(&_S296, &_S297, 0.0f);
        float3  _S298 = _S297.differential_0 + _S296.differential_0;
        FixedArray<float3 , 4>  _S299;
        _S299[int(0)] = _S244;
        _S299[int(1)] = _S244;
        _S299[int(2)] = _S244;
        _S299[int(3)] = _S244;
        _S299[int(1)] = _S298;
        float3  _S300 = _S268[int(1)] + _S299[int(1)];
        float3  _S301 = _S268[int(2)] + _S299[int(2)];
        float3  _S302 = _S268[int(3)] + _S299[int(3)];
        _S268[int(0)] = _S268[int(0)] + _S299[int(0)];
        _S268[int(1)] = _S300;
        _S268[int(2)] = _S301;
        _S268[int(3)] = _S302;
    }
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S303;
    (&_S303)->primal_0 = _S243[int(0)];
    (&_S303)->differential_0 = _S244;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S304;
    (&_S304)->primal_0 = _S243[int(0)];
    (&_S304)->differential_0 = _S244;
    s_bwd_prop_dot_0(&_S303, &_S304, 0.0f);
    float3  _S305 = _S304.differential_0 + _S303.differential_0 + _S257;
    FixedArray<float3 , 4>  _S306;
    _S306[int(0)] = _S244;
    _S306[int(1)] = _S244;
    _S306[int(2)] = _S244;
    _S306[int(3)] = _S244;
    _S306[int(0)] = _S305;
    FixedArray<float3 , 4>  _S307 = {
        _S268[int(0)] + _S306[int(0)], _S268[int(1)] + _S306[int(1)], _S268[int(2)] + _S306[int(2)], _S268[int(3)] + _S306[int(3)]
    };
    dppoints_0->primal_0 = dppoints_0->primal_0;
    dppoints_0->differential_0 = _S307;
    return;
}

inline __device__ void s_bwd_points_to_normal_0(DiffPair_arrayx3Cvectorx3Cfloatx2C3x3Ex2C4x3E_0 * _S308, float3  _S309)
{
    s_bwd_prop_points_to_normal_0(_S308, _S309);
    return;
}

inline __device__ void points_to_normal_vjp(FixedArray<float3 , 4>  points_1, float3  v_normal_0, FixedArray<float3 , 4>  * v_points_0)
{
    FixedArray<float3 , 4>  _S310 = { make_float3 (0.0f), make_float3 (0.0f), make_float3 (0.0f), make_float3 (0.0f) };
    DiffPair_arrayx3Cvectorx3Cfloatx2C3x3Ex2C4x3E_0 dp_points_0;
    (&dp_points_0)->primal_0 = points_1;
    (&dp_points_0)->differential_0 = _S310;
    s_bwd_points_to_normal_0(&dp_points_0, v_normal_0);
    *v_points_0 = (&dp_points_0)->differential_0;
    return;
}

inline __device__ Matrix<float, 2, 2>  transpose_0(Matrix<float, 2, 2>  x_19)
{
    Matrix<float, 2, 2>  result_7;
    int r_1 = int(0);
    for(;;)
    {
        if(r_1 < int(2))
        {
        }
        else
        {
            break;
        }
        int c_1 = int(0);
        for(;;)
        {
            if(c_1 < int(2))
            {
            }
            else
            {
                break;
            }
            *_slang_vector_get_element_ptr(((&result_7)->rows + (r_1)), c_1) = _slang_vector_get_element(x_19.rows[c_1], r_1);
            c_1 = c_1 + int(1);
        }
        r_1 = r_1 + int(1);
    }
    return result_7;
}

inline __device__ float determinant_0(Matrix<float, 2, 2>  m_0)
{
    return m_0.rows[int(0)].x * m_0.rows[int(1)].y - m_0.rows[int(0)].y * m_0.rows[int(1)].x;
}

inline __device__ bool undistort_point_0(float2  uv_0, FixedArray<float, 1>  * dist_coeffs_0, int maxiter_0, float2  * uv_undist_0)
{
    *uv_undist_0 = uv_0;
    return true;
}

inline __device__ float2  DistOpenCV_distort_0(float2  uv_1, FixedArray<float, 4>  * coeffs_0)
{
    float u_0 = uv_1.x;
    float v_0 = uv_1.y;
    float r2_0 = u_0 * u_0 + v_0 * v_0;
    return uv_1 * make_float2 (1.0f + r2_0 * ((*coeffs_0)[int(0)] + r2_0 * (*coeffs_0)[int(1)])) + make_float2 (2.0f * (*coeffs_0)[int(2)] * u_0 * v_0 + (*coeffs_0)[int(3)] * (r2_0 + 2.0f * u_0 * u_0), 2.0f * (*coeffs_0)[int(3)] * u_0 * v_0 + (*coeffs_0)[int(2)] * (r2_0 + 2.0f * v_0 * v_0));
}

struct DiffPair_vectorx3Cfloatx2C2x3E_0
{
    float2  primal_0;
    float2  differential_0;
};

inline __device__ DiffPair_vectorx3Cfloatx2C2x3E_0 s_fwd_DistOpenCV_distort_0(DiffPair_vectorx3Cfloatx2C2x3E_0 * dpuv_0, FixedArray<float, 4>  * coeffs_1)
{
    float u_1 = dpuv_0->primal_0.x;
    float s_diff_u_0 = dpuv_0->differential_0.x;
    float v_1 = dpuv_0->primal_0.y;
    float s_diff_v_0 = dpuv_0->differential_0.y;
    float _S311 = s_diff_u_0 * u_1;
    float _S312 = s_diff_v_0 * v_1;
    float r2_1 = u_1 * u_1 + v_1 * v_1;
    float s_diff_r2_0 = _S311 + _S311 + (_S312 + _S312);
    float _S313 = (*coeffs_1)[int(0)] + r2_1 * (*coeffs_1)[int(1)];
    float radial_0 = 1.0f + r2_1 * _S313;
    float _S314 = 2.0f * (*coeffs_1)[int(2)];
    float _S315 = _S314 * u_1;
    float _S316 = 2.0f * u_1;
    float _S317 = 2.0f * (*coeffs_1)[int(3)];
    float _S318 = _S317 * u_1;
    float _S319 = 2.0f * v_1;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S320 = { dpuv_0->primal_0 * make_float2 (radial_0) + make_float2 (_S315 * v_1 + (*coeffs_1)[int(3)] * (r2_1 + _S316 * u_1), _S318 * v_1 + (*coeffs_1)[int(2)] * (r2_1 + _S319 * v_1)), dpuv_0->differential_0 * make_float2 (radial_0) + make_float2 (s_diff_r2_0 * _S313 + s_diff_r2_0 * (*coeffs_1)[int(1)] * r2_1) * dpuv_0->primal_0 + make_float2 (s_diff_u_0 * _S314 * v_1 + s_diff_v_0 * _S315 + (s_diff_r2_0 + (s_diff_u_0 * 2.0f * u_1 + s_diff_u_0 * _S316)) * (*coeffs_1)[int(3)], s_diff_u_0 * _S317 * v_1 + s_diff_v_0 * _S318 + (s_diff_r2_0 + (s_diff_v_0 * 2.0f * v_1 + s_diff_v_0 * _S319)) * (*coeffs_1)[int(2)]) };
    return _S320;
}

inline __device__ bool undistort_point_1(float2  uv_2, FixedArray<float, 4>  * dist_coeffs_1, int maxiter_1, float2  * uv_undist_1)
{
    int i_5 = int(0);
    float2  q_0 = uv_2;
    for(;;)
    {
        if(i_5 < maxiter_1)
        {
        }
        else
        {
            break;
        }
        float2  _S321 = DistOpenCV_distort_0(q_0, dist_coeffs_1);
        float2  r_2 = _S321 - uv_2;
        float2  _S322 = make_float2 (1.0f, 0.0f);
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S323;
        (&_S323)->primal_0 = q_0;
        (&_S323)->differential_0 = _S322;
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S324 = s_fwd_DistOpenCV_distort_0(&_S323, dist_coeffs_1);
        float2  _S325 = make_float2 (0.0f, 1.0f);
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S326;
        (&_S326)->primal_0 = q_0;
        (&_S326)->differential_0 = _S325;
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S327 = s_fwd_DistOpenCV_distort_0(&_S326, dist_coeffs_1);
        Matrix<float, 2, 2>  _S328 = transpose_0(makeMatrix<float, 2, 2> (_S324.differential_0, _S327.differential_0));
        float inv_det_0 = 1.0f / (_S328.rows[int(0)].x * _S328.rows[int(1)].y - _S328.rows[int(0)].y * _S328.rows[int(1)].x);
        float _S329 = r_2.x;
        float _S330 = r_2.y;
        float2  q_1 = q_0 - make_float2 ((_S329 * _S328.rows[int(1)].y - _S330 * _S328.rows[int(0)].y) * inv_det_0, (- _S329 * _S328.rows[int(1)].x + _S330 * _S328.rows[int(0)].x) * inv_det_0);
        i_5 = i_5 + int(1);
        q_0 = q_1;
    }
    *uv_undist_1 = q_0;
    float2  _S331 = make_float2 (1.0f, 0.0f);
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S332;
    (&_S332)->primal_0 = q_0;
    (&_S332)->differential_0 = _S331;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S333 = s_fwd_DistOpenCV_distort_0(&_S332, dist_coeffs_1);
    float2  _S334 = make_float2 (0.0f, 1.0f);
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S335;
    (&_S335)->primal_0 = q_0;
    (&_S335)->differential_0 = _S334;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S336 = s_fwd_DistOpenCV_distort_0(&_S335, dist_coeffs_1);
    Matrix<float, 2, 2>  _S337 = transpose_0(makeMatrix<float, 2, 2> (_S333.differential_0, _S336.differential_0));
    float _S338 = (F32_min((determinant_0(_S337)), ((F32_min((_S337.rows[int(0)].x), (_S337.rows[int(1)].y))))));
    bool _S339;
    if(_S338 > 0.25f)
    {
        _S339 = _S338 < 4.0f;
    }
    else
    {
        _S339 = false;
    }
    if(_S339)
    {
        float2  _S340 = DistOpenCV_distort_0(q_0, dist_coeffs_1);
        _S339 = (dot_1(q_0, _S340)) >= 0.0f;
    }
    else
    {
        _S339 = false;
    }
    if(_S339)
    {
        float2  _S341 = DistOpenCV_distort_0(*uv_undist_1, dist_coeffs_1);
        _S339 = (length_1(_S341 - uv_2)) < 0.00999999977648258f;
    }
    else
    {
        _S339 = false;
    }
    return _S339;
}

inline __device__ float2  DistThinPrism_distort_0(float2  uv_3, FixedArray<float, 8>  * coeffs_2)
{
    float u_2 = uv_3.x;
    float v_2 = uv_3.y;
    float r2_2 = u_2 * u_2 + v_2 * v_2;
    return uv_3 * make_float2 (1.0f + r2_2 * ((*coeffs_2)[int(0)] + r2_2 * ((*coeffs_2)[int(1)] + r2_2 * ((*coeffs_2)[int(2)] + r2_2 * (*coeffs_2)[int(3)])))) + make_float2 (2.0f * (*coeffs_2)[int(4)] * u_2 * v_2 + (*coeffs_2)[int(5)] * (r2_2 + 2.0f * u_2 * u_2) + (*coeffs_2)[int(6)] * r2_2, 2.0f * (*coeffs_2)[int(5)] * u_2 * v_2 + (*coeffs_2)[int(4)] * (r2_2 + 2.0f * v_2 * v_2) + (*coeffs_2)[int(7)] * r2_2);
}

inline __device__ DiffPair_vectorx3Cfloatx2C2x3E_0 s_fwd_DistThinPrism_distort_0(DiffPair_vectorx3Cfloatx2C2x3E_0 * dpuv_1, FixedArray<float, 8>  * coeffs_3)
{
    float u_3 = dpuv_1->primal_0.x;
    float s_diff_u_1 = dpuv_1->differential_0.x;
    float v_3 = dpuv_1->primal_0.y;
    float s_diff_v_1 = dpuv_1->differential_0.y;
    float _S342 = s_diff_u_1 * u_3;
    float _S343 = s_diff_v_1 * v_3;
    float r2_3 = u_3 * u_3 + v_3 * v_3;
    float s_diff_r2_1 = _S342 + _S342 + (_S343 + _S343);
    float _S344 = (*coeffs_3)[int(2)] + r2_3 * (*coeffs_3)[int(3)];
    float _S345 = (*coeffs_3)[int(1)] + r2_3 * _S344;
    float _S346 = (*coeffs_3)[int(0)] + r2_3 * _S345;
    float radial_1 = 1.0f + r2_3 * _S346;
    float _S347 = 2.0f * (*coeffs_3)[int(4)];
    float _S348 = _S347 * u_3;
    float _S349 = 2.0f * u_3;
    float _S350 = 2.0f * (*coeffs_3)[int(5)];
    float _S351 = _S350 * u_3;
    float _S352 = 2.0f * v_3;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S353 = { dpuv_1->primal_0 * make_float2 (radial_1) + make_float2 (_S348 * v_3 + (*coeffs_3)[int(5)] * (r2_3 + _S349 * u_3) + (*coeffs_3)[int(6)] * r2_3, _S351 * v_3 + (*coeffs_3)[int(4)] * (r2_3 + _S352 * v_3) + (*coeffs_3)[int(7)] * r2_3), dpuv_1->differential_0 * make_float2 (radial_1) + make_float2 (s_diff_r2_1 * _S346 + (s_diff_r2_1 * _S345 + (s_diff_r2_1 * _S344 + s_diff_r2_1 * (*coeffs_3)[int(3)] * r2_3) * r2_3) * r2_3) * dpuv_1->primal_0 + make_float2 (s_diff_u_1 * _S347 * v_3 + s_diff_v_1 * _S348 + (s_diff_r2_1 + (s_diff_u_1 * 2.0f * u_3 + s_diff_u_1 * _S349)) * (*coeffs_3)[int(5)] + s_diff_r2_1 * (*coeffs_3)[int(6)], s_diff_u_1 * _S350 * v_3 + s_diff_v_1 * _S351 + (s_diff_r2_1 + (s_diff_v_1 * 2.0f * v_3 + s_diff_v_1 * _S352)) * (*coeffs_3)[int(4)] + s_diff_r2_1 * (*coeffs_3)[int(7)]) };
    return _S353;
}

inline __device__ bool undistort_point_2(float2  uv_4, FixedArray<float, 8>  * dist_coeffs_2, int maxiter_2, float2  * uv_undist_2)
{
    int i_6 = int(0);
    float2  q_2 = uv_4;
    for(;;)
    {
        if(i_6 < maxiter_2)
        {
        }
        else
        {
            break;
        }
        float2  _S354 = DistThinPrism_distort_0(q_2, dist_coeffs_2);
        float2  r_3 = _S354 - uv_4;
        float2  _S355 = make_float2 (1.0f, 0.0f);
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S356;
        (&_S356)->primal_0 = q_2;
        (&_S356)->differential_0 = _S355;
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S357 = s_fwd_DistThinPrism_distort_0(&_S356, dist_coeffs_2);
        float2  _S358 = make_float2 (0.0f, 1.0f);
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S359;
        (&_S359)->primal_0 = q_2;
        (&_S359)->differential_0 = _S358;
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S360 = s_fwd_DistThinPrism_distort_0(&_S359, dist_coeffs_2);
        Matrix<float, 2, 2>  _S361 = transpose_0(makeMatrix<float, 2, 2> (_S357.differential_0, _S360.differential_0));
        float inv_det_1 = 1.0f / (_S361.rows[int(0)].x * _S361.rows[int(1)].y - _S361.rows[int(0)].y * _S361.rows[int(1)].x);
        float _S362 = r_3.x;
        float _S363 = r_3.y;
        float2  q_3 = q_2 - make_float2 ((_S362 * _S361.rows[int(1)].y - _S363 * _S361.rows[int(0)].y) * inv_det_1, (- _S362 * _S361.rows[int(1)].x + _S363 * _S361.rows[int(0)].x) * inv_det_1);
        i_6 = i_6 + int(1);
        q_2 = q_3;
    }
    *uv_undist_2 = q_2;
    float2  _S364 = make_float2 (1.0f, 0.0f);
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S365;
    (&_S365)->primal_0 = q_2;
    (&_S365)->differential_0 = _S364;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S366 = s_fwd_DistThinPrism_distort_0(&_S365, dist_coeffs_2);
    float2  _S367 = make_float2 (0.0f, 1.0f);
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S368;
    (&_S368)->primal_0 = q_2;
    (&_S368)->differential_0 = _S367;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S369 = s_fwd_DistThinPrism_distort_0(&_S368, dist_coeffs_2);
    Matrix<float, 2, 2>  _S370 = transpose_0(makeMatrix<float, 2, 2> (_S366.differential_0, _S369.differential_0));
    float _S371 = (F32_min((determinant_0(_S370)), ((F32_min((_S370.rows[int(0)].x), (_S370.rows[int(1)].y))))));
    bool _S372;
    if(_S371 > 0.25f)
    {
        _S372 = _S371 < 4.0f;
    }
    else
    {
        _S372 = false;
    }
    if(_S372)
    {
        float2  _S373 = DistThinPrism_distort_0(q_2, dist_coeffs_2);
        _S372 = (dot_1(q_2, _S373)) >= 0.0f;
    }
    else
    {
        _S372 = false;
    }
    if(_S372)
    {
        float2  _S374 = DistThinPrism_distort_0(*uv_undist_2, dist_coeffs_2);
        _S372 = (length_1(_S374 - uv_4)) < 0.00999999977648258f;
    }
    else
    {
        _S372 = false;
    }
    return _S372;
}

inline __device__ float2  DistRational_distort_0(float2  uv_5, FixedArray<float, 8>  * coeffs_4)
{
    float u_4 = uv_5.x;
    float v_4 = uv_5.y;
    float r2_4 = u_4 * u_4 + v_4 * v_4;
    return uv_5 * make_float2 ((1.0f + r2_4 * ((*coeffs_4)[int(0)] + r2_4 * ((*coeffs_4)[int(1)] + r2_4 * (*coeffs_4)[int(2)]))) / (1.0f + r2_4 * ((*coeffs_4)[int(3)] + r2_4 * ((*coeffs_4)[int(4)] + r2_4 * (*coeffs_4)[int(5)])))) + make_float2 (2.0f * (*coeffs_4)[int(6)] * u_4 * v_4 + (*coeffs_4)[int(7)] * (r2_4 + 2.0f * u_4 * u_4), 2.0f * (*coeffs_4)[int(7)] * u_4 * v_4 + (*coeffs_4)[int(6)] * (r2_4 + 2.0f * v_4 * v_4));
}

inline __device__ DiffPair_vectorx3Cfloatx2C2x3E_0 s_fwd_DistRational_distort_0(DiffPair_vectorx3Cfloatx2C2x3E_0 * dpuv_2, FixedArray<float, 8>  * coeffs_5)
{
    float u_5 = dpuv_2->primal_0.x;
    float s_diff_u_2 = dpuv_2->differential_0.x;
    float v_5 = dpuv_2->primal_0.y;
    float s_diff_v_2 = dpuv_2->differential_0.y;
    float _S375 = s_diff_u_2 * u_5;
    float _S376 = s_diff_v_2 * v_5;
    float r2_5 = u_5 * u_5 + v_5 * v_5;
    float s_diff_r2_2 = _S375 + _S375 + (_S376 + _S376);
    float _S377 = (*coeffs_5)[int(1)] + r2_5 * (*coeffs_5)[int(2)];
    float _S378 = (*coeffs_5)[int(0)] + r2_5 * _S377;
    float _S379 = 1.0f + r2_5 * _S378;
    float _S380 = (*coeffs_5)[int(4)] + r2_5 * (*coeffs_5)[int(5)];
    float _S381 = (*coeffs_5)[int(3)] + r2_5 * _S380;
    float _S382 = 1.0f + r2_5 * _S381;
    float radial_2 = _S379 / _S382;
    float _S383 = 2.0f * (*coeffs_5)[int(6)];
    float _S384 = _S383 * u_5;
    float _S385 = 2.0f * u_5;
    float _S386 = 2.0f * (*coeffs_5)[int(7)];
    float _S387 = _S386 * u_5;
    float _S388 = 2.0f * v_5;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S389 = { dpuv_2->primal_0 * make_float2 (radial_2) + make_float2 (_S384 * v_5 + (*coeffs_5)[int(7)] * (r2_5 + _S385 * u_5), _S387 * v_5 + (*coeffs_5)[int(6)] * (r2_5 + _S388 * v_5)), dpuv_2->differential_0 * make_float2 (radial_2) + make_float2 (((s_diff_r2_2 * _S378 + (s_diff_r2_2 * _S377 + s_diff_r2_2 * (*coeffs_5)[int(2)] * r2_5) * r2_5) * _S382 - _S379 * (s_diff_r2_2 * _S381 + (s_diff_r2_2 * _S380 + s_diff_r2_2 * (*coeffs_5)[int(5)] * r2_5) * r2_5)) / (_S382 * _S382)) * dpuv_2->primal_0 + make_float2 (s_diff_u_2 * _S383 * v_5 + s_diff_v_2 * _S384 + (s_diff_r2_2 + (s_diff_u_2 * 2.0f * u_5 + s_diff_u_2 * _S385)) * (*coeffs_5)[int(7)], s_diff_u_2 * _S386 * v_5 + s_diff_v_2 * _S387 + (s_diff_r2_2 + (s_diff_v_2 * 2.0f * v_5 + s_diff_v_2 * _S388)) * (*coeffs_5)[int(6)]) };
    return _S389;
}

inline __device__ bool undistort_point_3(float2  uv_6, FixedArray<float, 8>  * dist_coeffs_3, int maxiter_3, float2  * uv_undist_3)
{
    int i_7 = int(0);
    float2  q_4 = uv_6;
    for(;;)
    {
        if(i_7 < maxiter_3)
        {
        }
        else
        {
            break;
        }
        float2  _S390 = DistRational_distort_0(q_4, dist_coeffs_3);
        float2  r_4 = _S390 - uv_6;
        float2  _S391 = make_float2 (1.0f, 0.0f);
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S392;
        (&_S392)->primal_0 = q_4;
        (&_S392)->differential_0 = _S391;
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S393 = s_fwd_DistRational_distort_0(&_S392, dist_coeffs_3);
        float2  _S394 = make_float2 (0.0f, 1.0f);
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S395;
        (&_S395)->primal_0 = q_4;
        (&_S395)->differential_0 = _S394;
        DiffPair_vectorx3Cfloatx2C2x3E_0 _S396 = s_fwd_DistRational_distort_0(&_S395, dist_coeffs_3);
        Matrix<float, 2, 2>  _S397 = transpose_0(makeMatrix<float, 2, 2> (_S393.differential_0, _S396.differential_0));
        float inv_det_2 = 1.0f / (_S397.rows[int(0)].x * _S397.rows[int(1)].y - _S397.rows[int(0)].y * _S397.rows[int(1)].x);
        float _S398 = r_4.x;
        float _S399 = r_4.y;
        float2  q_5 = q_4 - make_float2 ((_S398 * _S397.rows[int(1)].y - _S399 * _S397.rows[int(0)].y) * inv_det_2, (- _S398 * _S397.rows[int(1)].x + _S399 * _S397.rows[int(0)].x) * inv_det_2);
        i_7 = i_7 + int(1);
        q_4 = q_5;
    }
    *uv_undist_3 = q_4;
    float2  _S400 = make_float2 (1.0f, 0.0f);
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S401;
    (&_S401)->primal_0 = q_4;
    (&_S401)->differential_0 = _S400;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S402 = s_fwd_DistRational_distort_0(&_S401, dist_coeffs_3);
    float2  _S403 = make_float2 (0.0f, 1.0f);
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S404;
    (&_S404)->primal_0 = q_4;
    (&_S404)->differential_0 = _S403;
    DiffPair_vectorx3Cfloatx2C2x3E_0 _S405 = s_fwd_DistRational_distort_0(&_S404, dist_coeffs_3);
    Matrix<float, 2, 2>  _S406 = transpose_0(makeMatrix<float, 2, 2> (_S402.differential_0, _S405.differential_0));
    float _S407 = (F32_min((determinant_0(_S406)), ((F32_min((_S406.rows[int(0)].x), (_S406.rows[int(1)].y))))));
    bool _S408;
    if(_S407 > 0.25f)
    {
        _S408 = _S407 < 4.0f;
    }
    else
    {
        _S408 = false;
    }
    if(_S408)
    {
        float2  _S409 = DistRational_distort_0(q_4, dist_coeffs_3);
        _S408 = (dot_1(q_4, _S409)) >= 0.0f;
    }
    else
    {
        _S408 = false;
    }
    if(_S408)
    {
        float2  _S410 = DistRational_distort_0(*uv_undist_3, dist_coeffs_3);
        _S408 = (length_1(_S410 - uv_6)) < 0.00999999977648258f;
    }
    else
    {
        _S408 = false;
    }
    return _S408;
}

inline __device__ float3  normalize_0(float3  x_20)
{
    return x_20 / make_float3 (length_0(x_20));
}

inline __device__ float3  unproject_raydir_0(float2  uv_7, int camera_model_0, bool is_ray_depth_0)
{
    float3  raydir_0;
    bool is_unit_0;
    if(camera_model_0 == int(1))
    {
        float theta_0 = length_1(uv_7);
        float3  _S411 = make_float3 ((uv_7 / make_float2 ((F32_max((theta_0), (1.00000001168609742e-07f)))) * make_float2 ((F32_sin((theta_0))))).x, (uv_7 / make_float2 ((F32_max((theta_0), (1.00000001168609742e-07f)))) * make_float2 ((F32_sin((theta_0))))).y, (F32_cos((theta_0))));
        is_unit_0 = true;
        raydir_0 = _S411;
    }
    else
    {
        bool _S412 = camera_model_0 == int(2);
        if(_S412)
        {
            float r_5 = length_1(uv_7);
            raydir_0 = make_float3 ((uv_7 * make_float2 ((F32_sqrt(((F32_max((0.0f), (1.0f - 0.25f * r_5 * r_5)))))))).x, (uv_7 * make_float2 ((F32_sqrt(((F32_max((0.0f), (1.0f - 0.25f * r_5 * r_5)))))))).y, 1.0f - 0.5f * r_5 * r_5);
        }
        else
        {
            raydir_0 = make_float3 (uv_7.x, uv_7.y, 1.0f);
        }
        is_unit_0 = _S412;
    }
    if(is_ray_depth_0)
    {
        if(is_unit_0)
        {
        }
        else
        {
            raydir_0 = normalize_0(raydir_0);
        }
    }
    else
    {
        raydir_0 = raydir_0 / make_float3 (raydir_0.z);
    }
    return raydir_0;
}

inline __device__ float3  generate_ray_d2n_none(float2  pix_pos_0, float4  intrins_0, FixedArray<float, 1>  dist_coeffs_4, int camera_model_1, bool is_ray_depth_1)
{
    float3  _S413;
    for(;;)
    {
        float2  uv_8 = (pix_pos_0 - float2 {intrins_0.z, intrins_0.w}) / float2 {intrins_0.x, intrins_0.y};
        FixedArray<float, 1>  _S414 = dist_coeffs_4;
        float2  uv_u_0;
        bool _S415 = undistort_point_0(uv_8, &_S414, int(12), &uv_u_0);
        if(!_S415)
        {
            int3  _S416 = make_int3 (int(0));
            float3  _S417 = make_float3 ((float)_S416.x, (float)_S416.y, (float)_S416.z);
            _S413 = _S417;
            break;
        }
        _S413 = unproject_raydir_0(uv_u_0, camera_model_1, is_ray_depth_1);
        break;
    }
    return _S413;
}

inline __device__ float3  depth_to_point_none(float2  pix_pos_1, float4  intrins_1, FixedArray<float, 1>  dist_coeffs_5, int camera_model_2, bool is_ray_depth_2, float depth_2)
{
    float3  _S418;
    for(;;)
    {
        float2  uv_9 = (pix_pos_1 - float2 {intrins_1.z, intrins_1.w}) / float2 {intrins_1.x, intrins_1.y};
        FixedArray<float, 1>  _S419 = dist_coeffs_5;
        float2  uv_u_1;
        bool _S420 = undistort_point_0(uv_9, &_S419, int(12), &uv_u_1);
        if(!_S420)
        {
            _S418 = make_float3 (0.0f);
            break;
        }
        _S418 = make_float3 (depth_2) * unproject_raydir_0(uv_u_1, camera_model_2, is_ray_depth_2);
        break;
    }
    return _S418;
}

struct s_bwd_prop_depth_to_point_Intermediates_0
{
    float2  _S421;
    bool _S422;
};

inline __device__ float s_primal_ctx_sin_0(float _S423)
{
    return (F32_sin((_S423)));
}

inline __device__ float s_primal_ctx_cos_0(float _S424)
{
    return (F32_cos((_S424)));
}

inline __device__ float s_primal_ctx_sqrt_0(float _S425)
{
    return (F32_sqrt((_S425)));
}

inline __device__ float3  s_primal_ctx_unproject_raydir_0(float2  dpuv_3, int camera_model_3, bool is_ray_depth_3)
{
    float3  raydir_1;
    bool is_unit_1;
    if(camera_model_3 == int(1))
    {
        float _S426 = length_1(dpuv_3);
        float3  _S427 = make_float3 ((dpuv_3 / make_float2 ((F32_max((_S426), (1.00000001168609742e-07f)))) * make_float2 (s_primal_ctx_sin_0(_S426))).x, (dpuv_3 / make_float2 ((F32_max((_S426), (1.00000001168609742e-07f)))) * make_float2 (s_primal_ctx_sin_0(_S426))).y, s_primal_ctx_cos_0(_S426));
        is_unit_1 = true;
        raydir_1 = _S427;
    }
    else
    {
        bool _S428 = camera_model_3 == int(2);
        if(_S428)
        {
            float _S429 = length_1(dpuv_3);
            raydir_1 = make_float3 ((dpuv_3 * make_float2 (s_primal_ctx_sqrt_0((F32_max((0.0f), (1.0f - 0.25f * _S429 * _S429)))))).x, (dpuv_3 * make_float2 (s_primal_ctx_sqrt_0((F32_max((0.0f), (1.0f - 0.25f * _S429 * _S429)))))).y, 1.0f - 0.5f * _S429 * _S429);
        }
        else
        {
            raydir_1 = make_float3 (dpuv_3.x, dpuv_3.y, 1.0f);
        }
        is_unit_1 = _S428;
    }
    if(is_ray_depth_3)
    {
        if(is_unit_1)
        {
        }
        else
        {
            raydir_1 = normalize_0(raydir_1);
        }
    }
    else
    {
        raydir_1 = raydir_1 / make_float3 (raydir_1.z);
    }
    return raydir_1;
}

inline __device__ float depth_to_point_vjp_none(float2  pix_pos_2, float4  intrins_2, FixedArray<float, 1>  dist_coeffs_6, int camera_model_4, bool is_ray_depth_4, float depth_3, float3  v_point_0)
{
    float2  _S430 = make_float2 (0.0f);
    s_bwd_prop_depth_to_point_Intermediates_0 _S431;
    (&_S431)->_S421 = _S430;
    (&_S431)->_S422 = false;
    float2  uv_10 = (pix_pos_2 - float2 {intrins_2.z, intrins_2.w}) / float2 {intrins_2.x, intrins_2.y};
    float2  _S432 = _S430;
    FixedArray<float, 1>  _S433 = dist_coeffs_6;
    bool _S434 = undistort_point_0(uv_10, &_S433, int(12), &_S432);
    (&_S431)->_S421 = _S432;
    (&_S431)->_S422 = _S434;
    s_bwd_prop_depth_to_point_Intermediates_0 _S435 = _S431;
    float3  _S436 = make_float3 (0.0f);
    bool _S437 = !!_S431._S422;
    float3  _S438;
    if(_S437)
    {
        _S438 = s_primal_ctx_unproject_raydir_0(_S435._S421, camera_model_4, is_ray_depth_4);
    }
    else
    {
        _S438 = _S436;
    }
    if(_S437)
    {
        _S438 = _S438 * v_point_0;
    }
    else
    {
        _S438 = _S436;
    }
    return _S438.x + _S438.y + _S438.z;
}

inline __device__ float3  depth_to_normal_none(float2  pix_center_0, float4  intrins_3, FixedArray<float, 1>  dist_coeffs_7, int camera_model_5, bool is_ray_depth_5, float4  depths_0)
{
    float3  normal_2;
    for(;;)
    {
        bool _S439;
        if((depths_0.x) == 0.0f)
        {
            _S439 = true;
        }
        else
        {
            _S439 = (depths_0.y) == 0.0f;
        }
        if(_S439)
        {
            _S439 = true;
        }
        else
        {
            _S439 = (depths_0.z) == 0.0f;
        }
        if(_S439)
        {
            _S439 = true;
        }
        else
        {
            _S439 = (depths_0.w) == 0.0f;
        }
        if(_S439)
        {
            normal_2 = make_float3 (0.0f);
            break;
        }
        float3  * _S440;
        float3  * _S441;
        float3  * _S442;
        float3  * _S443;
        int _S444;
        FixedArray<float3 , 4>  points_2;
        for(;;)
        {
            float2  _S445 = float2 {intrins_3.z, intrins_3.w};
            float2  _S446 = float2 {intrins_3.x, intrins_3.y};
            float2  uv_11 = (pix_center_0 + make_float2 (-1.0f, -0.0f) - _S445) / _S446;
            FixedArray<float, 1>  _S447 = dist_coeffs_7;
            float2  uv_u_2;
            bool _S448 = undistort_point_0(uv_11, &_S447, int(12), &uv_u_2);
            if(!_S448)
            {
                float3  _S449 = make_float3 (0.0f);
                _S444 = int(0);
                _S443 = nullptr;
                _S442 = nullptr;
                _S441 = nullptr;
                _S440 = nullptr;
                normal_2 = _S449;
                break;
            }
            points_2[int(0)] = make_float3 (depths_0.x) * unproject_raydir_0(uv_u_2, camera_model_5, is_ray_depth_5);
            for(;;)
            {
                float2  uv_12 = (pix_center_0 + make_float2 (1.0f, -0.0f) - _S445) / _S446;
                FixedArray<float, 1>  _S450 = dist_coeffs_7;
                float2  uv_u_3;
                bool _S451 = undistort_point_0(uv_12, &_S450, int(12), &uv_u_3);
                if(!_S451)
                {
                    float3  _S452 = make_float3 (0.0f);
                    _S444 = int(0);
                    _S443 = nullptr;
                    normal_2 = _S452;
                    break;
                }
                points_2[int(1)] = make_float3 (depths_0.y) * unproject_raydir_0(uv_u_3, camera_model_5, is_ray_depth_5);
                _S444 = int(2);
                _S443 = &points_2[int(1)];
                break;
            }
            if(_S444 != int(2))
            {
                _S442 = &points_2[int(0)];
                _S441 = nullptr;
                _S440 = nullptr;
                break;
            }
            float2  uv_13 = (pix_center_0 + make_float2 (0.0f, -1.0f) - _S445) / _S446;
            FixedArray<float, 1>  _S453 = dist_coeffs_7;
            float2  uv_u_4;
            bool _S454 = undistort_point_0(uv_13, &_S453, int(12), &uv_u_4);
            if(!_S454)
            {
                float3  _S455 = make_float3 (0.0f);
                _S444 = int(0);
                _S442 = &points_2[int(0)];
                _S441 = nullptr;
                _S440 = nullptr;
                normal_2 = _S455;
                break;
            }
            points_2[int(2)] = make_float3 (depths_0.z) * unproject_raydir_0(uv_u_4, camera_model_5, is_ray_depth_5);
            for(;;)
            {
                float2  uv_14 = (pix_center_0 + make_float2 (0.0f, 1.0f) - _S445) / _S446;
                FixedArray<float, 1>  _S456 = dist_coeffs_7;
                float2  uv_u_5;
                bool _S457 = undistort_point_0(uv_14, &_S456, int(12), &uv_u_5);
                if(!_S457)
                {
                    float3  _S458 = make_float3 (0.0f);
                    _S444 = int(0);
                    _S442 = nullptr;
                    normal_2 = _S458;
                    break;
                }
                points_2[int(3)] = make_float3 (depths_0.w) * unproject_raydir_0(uv_u_5, camera_model_5, is_ray_depth_5);
                _S444 = int(2);
                _S442 = &points_2[int(3)];
                break;
            }
            if(_S444 != int(2))
            {
                float3  * _S459 = _S442;
                _S442 = &points_2[int(0)];
                _S441 = _S459;
                _S440 = &points_2[int(2)];
                break;
            }
            float3  * _S460 = _S442;
            _S444 = int(1);
            _S442 = &points_2[int(0)];
            _S441 = _S460;
            _S440 = &points_2[int(2)];
            break;
        }
        if(_S444 != int(1))
        {
            break;
        }
        float3  normal_3 = cross_0(*_S443 - *_S442, - (*_S441 - *_S440));
        if((dot_0(normal_3, normal_3)) != 0.0f)
        {
            normal_2 = normal_3 / make_float3 (length_0(normal_3));
        }
        else
        {
            normal_2 = normal_3;
        }
        break;
    }
    return normal_2;
}

struct s_bwd_prop_depth_to_normal_Intermediates_0
{
    float2  _S461;
    bool _S462;
    float2  _S463;
    bool _S464;
    float2  _S465;
    bool _S466;
    float2  _S467;
    bool _S468;
};

inline __device__ void depth_to_normal_vjp_none(float2  pix_center_1, float4  intrins_4, FixedArray<float, 1>  dist_coeffs_8, int camera_model_6, bool is_ray_depth_6, float4  depths_1, float3  v_normal_1, float4  * v_depths_0)
{
    float2  _S469 = make_float2 (0.0f);
    s_bwd_prop_depth_to_normal_Intermediates_0 _S470;
    (&_S470)->_S461 = _S469;
    (&_S470)->_S462 = false;
    (&_S470)->_S463 = _S469;
    (&_S470)->_S464 = false;
    (&_S470)->_S465 = _S469;
    (&_S470)->_S466 = false;
    (&_S470)->_S467 = _S469;
    (&_S470)->_S468 = false;
    (&_S470)->_S461 = _S469;
    (&_S470)->_S462 = false;
    (&_S470)->_S463 = _S469;
    (&_S470)->_S464 = false;
    (&_S470)->_S465 = _S469;
    (&_S470)->_S466 = false;
    (&_S470)->_S467 = _S469;
    (&_S470)->_S468 = false;
    bool _S471 = (depths_1.x) == 0.0f;
    bool _runFlag_3;
    if(_S471)
    {
        _runFlag_3 = true;
    }
    else
    {
        _runFlag_3 = (depths_1.y) == 0.0f;
    }
    if(_runFlag_3)
    {
        _runFlag_3 = true;
    }
    else
    {
        _runFlag_3 = (depths_1.z) == 0.0f;
    }
    if(_runFlag_3)
    {
        _runFlag_3 = true;
    }
    else
    {
        _runFlag_3 = (depths_1.w) == 0.0f;
    }
    int _S472;
    if(!_runFlag_3)
    {
        float2  _S473 = float2 {intrins_4.z, intrins_4.w};
        float2  _S474 = float2 {intrins_4.x, intrins_4.y};
        float2  uv_15 = (pix_center_1 + make_float2 (-1.0f, -0.0f) - _S473) / _S474;
        float2  _S475 = _S469;
        FixedArray<float, 1>  _S476 = dist_coeffs_8;
        bool _S477 = undistort_point_0(uv_15, &_S476, int(12), &_S475);
        (&_S470)->_S461 = _S475;
        (&_S470)->_S462 = _S477;
        bool _S478 = !!_S477;
        if(_S478)
        {
            float2  uv_16 = (pix_center_1 + make_float2 (1.0f, -0.0f) - _S473) / _S474;
            float2  _S479 = _S469;
            FixedArray<float, 1>  _S480 = dist_coeffs_8;
            bool _S481 = undistort_point_0(uv_16, &_S480, int(12), &_S479);
            (&_S470)->_S463 = _S479;
            (&_S470)->_S464 = _S481;
            if(!!_S481)
            {
                _S472 = int(2);
            }
            else
            {
                _S472 = int(0);
            }
            if(_S472 != int(2))
            {
                _runFlag_3 = false;
            }
            else
            {
                _runFlag_3 = _S478;
            }
            if(_runFlag_3)
            {
                float2  uv_17 = (pix_center_1 + make_float2 (0.0f, -1.0f) - _S473) / _S474;
                float2  _S482 = _S469;
                FixedArray<float, 1>  _S483 = dist_coeffs_8;
                bool _S484 = undistort_point_0(uv_17, &_S483, int(12), &_S482);
                (&_S470)->_S465 = _S482;
                (&_S470)->_S466 = _S484;
                if(!_S484)
                {
                    _runFlag_3 = false;
                }
                if(_runFlag_3)
                {
                    float2  uv_18 = (pix_center_1 + make_float2 (0.0f, 1.0f) - _S473) / _S474;
                    float2  _S485 = _S469;
                    FixedArray<float, 1>  _S486 = dist_coeffs_8;
                    bool _S487 = undistort_point_0(uv_18, &_S486, int(12), &_S485);
                    (&_S470)->_S467 = _S485;
                    (&_S470)->_S468 = _S487;
                }
            }
        }
    }
    s_bwd_prop_depth_to_normal_Intermediates_0 _S488 = _S470;
    float3  _S489 = make_float3 (0.0f);
    if(_S471)
    {
        _runFlag_3 = true;
    }
    else
    {
        _runFlag_3 = (depths_1.y) == 0.0f;
    }
    if(_runFlag_3)
    {
        _runFlag_3 = true;
    }
    else
    {
        _runFlag_3 = (depths_1.z) == 0.0f;
    }
    if(_runFlag_3)
    {
        _runFlag_3 = true;
    }
    else
    {
        _runFlag_3 = (depths_1.w) == 0.0f;
    }
    bool _S490 = !_runFlag_3;
    bool _runFlag_4;
    bool _runFlag_5;
    bool _S491;
    bool _runFlag_6;
    bool _S492;
    bool _S493;
    FixedArray<float3 , 4>  points_3;
    float3  _S494;
    float3  _S495;
    float3  _S496;
    float3  _S497;
    float3  _S498;
    float3  _S499;
    float3  _S500;
    float3  _S501;
    float3  _S502;
    if(_S490)
    {
        bool _S503 = !!_S488._S462;
        if(_S503)
        {
            float3  _S504 = s_primal_ctx_unproject_raydir_0(_S488._S461, camera_model_6, is_ray_depth_6);
            float3  _S505 = make_float3 (depths_1.x) * _S504;
            bool _S506 = !!_S488._S464;
            if(_S506)
            {
                float3  _S507 = s_primal_ctx_unproject_raydir_0(_S488._S463, camera_model_6, is_ray_depth_6);
                float3  _S508 = make_float3 (depths_1.y) * _S507;
                _S472 = int(2);
                points_3[int(0)] = _S505;
                points_3[int(1)] = _S508;
                points_3[int(2)] = _S489;
                points_3[int(3)] = _S489;
                _S494 = _S507;
            }
            else
            {
                _S472 = int(0);
                points_3[int(0)] = _S505;
                points_3[int(1)] = _S489;
                points_3[int(2)] = _S489;
                points_3[int(3)] = _S489;
                _S494 = _S489;
            }
            if(_S472 != int(2))
            {
                _runFlag_3 = false;
            }
            else
            {
                _runFlag_3 = _S503;
                _S472 = int(0);
            }
            if(_runFlag_3)
            {
                if(!_S488._S466)
                {
                    _runFlag_4 = false;
                    _S472 = int(0);
                }
                else
                {
                    _runFlag_4 = _runFlag_3;
                }
                if(_runFlag_4)
                {
                    float3  _S509 = s_primal_ctx_unproject_raydir_0(_S488._S465, camera_model_6, is_ray_depth_6);
                    points_3[int(2)] = make_float3 (depths_1.z) * _S509;
                    bool _S510 = !!_S488._S468;
                    int _S511;
                    if(_S510)
                    {
                        float3  _S512 = s_primal_ctx_unproject_raydir_0(_S488._S467, camera_model_6, is_ray_depth_6);
                        points_3[int(3)] = make_float3 (depths_1.w) * _S512;
                        _S511 = int(2);
                        _S495 = _S512;
                    }
                    else
                    {
                        _S511 = int(0);
                        _S495 = _S489;
                    }
                    if(_S511 != int(2))
                    {
                        _runFlag_5 = false;
                        _S472 = _S511;
                    }
                    else
                    {
                        _runFlag_5 = _runFlag_4;
                    }
                    if(_runFlag_5)
                    {
                        _S472 = int(1);
                    }
                    _runFlag_5 = _S510;
                    _S496 = _S509;
                }
                else
                {
                    _runFlag_5 = false;
                    _S495 = _S489;
                    _S496 = _S489;
                }
            }
            else
            {
                _runFlag_4 = false;
                _runFlag_5 = false;
                _S495 = _S489;
                _S496 = _S489;
            }
            float3  _S513 = _S494;
            _S494 = _S495;
            _S495 = _S496;
            _S491 = _S506;
            _S496 = _S513;
            _S497 = _S504;
        }
        else
        {
            _S472 = int(0);
            points_3[int(0)] = _S489;
            points_3[int(1)] = _S489;
            points_3[int(2)] = _S489;
            points_3[int(3)] = _S489;
            _runFlag_3 = false;
            _runFlag_4 = false;
            _runFlag_5 = false;
            _S494 = _S489;
            _S495 = _S489;
            _S491 = false;
            _S496 = _S489;
            _S497 = _S489;
        }
        if(_S472 != int(1))
        {
            _runFlag_6 = false;
        }
        else
        {
            _runFlag_6 = _S490;
        }
        if(_runFlag_6)
        {
            float3  dx_1 = points_3[int(1)] - points_3[int(0)];
            float3  _S514 = - (points_3[int(3)] - points_3[int(2)]);
            float3  _S515 = s_primal_ctx_cross_0(dx_1, _S514);
            bool _S516 = (s_primal_ctx_dot_0(_S515, _S515)) != 0.0f;
            if(_S516)
            {
                float _S517 = length_0(_S515);
                float3  _S518 = make_float3 (_S517);
                _S498 = make_float3 (_S517 * _S517);
                _S499 = _S518;
            }
            else
            {
                _S498 = _S489;
                _S499 = _S489;
            }
            float3  _S519 = _S499;
            _S492 = _S516;
            _S499 = _S515;
            _S500 = _S519;
            _S501 = dx_1;
            _S502 = _S514;
        }
        else
        {
            _S492 = false;
            _S498 = _S489;
            _S499 = _S489;
            _S500 = _S489;
            _S501 = _S489;
            _S502 = _S489;
        }
        bool _S520 = _runFlag_3;
        bool _S521 = _runFlag_4;
        bool _S522 = _runFlag_5;
        float3  _S523 = _S494;
        float3  _S524 = _S495;
        bool _S525 = _S491;
        float3  _S526 = _S496;
        float3  _S527 = _S497;
        _runFlag_3 = _runFlag_6;
        _runFlag_4 = _S492;
        _S494 = _S498;
        _S495 = _S499;
        _S496 = _S500;
        _S497 = _S501;
        _S498 = _S502;
        _runFlag_5 = _S503;
        _S491 = _S520;
        _runFlag_6 = _S521;
        _S492 = _S522;
        _S499 = _S523;
        _S500 = _S524;
        _S493 = _S525;
        _S501 = _S526;
        _S502 = _S527;
    }
    else
    {
        _runFlag_3 = false;
        _runFlag_4 = false;
        _S494 = _S489;
        _S495 = _S489;
        _S496 = _S489;
        _S497 = _S489;
        _S498 = _S489;
        _runFlag_5 = false;
        _S491 = false;
        _runFlag_6 = false;
        _S492 = false;
        _S499 = _S489;
        _S500 = _S489;
        _S493 = false;
        _S501 = _S489;
        _S502 = _S489;
    }
    float4  _S528 = make_float4 (0.0f);
    float4  _S529;
    if(_S490)
    {
        if(_runFlag_3)
        {
            if(_runFlag_4)
            {
                float3  _S530 = v_normal_1 / _S494;
                float3  _S531 = _S495 * - _S530;
                float3  _S532 = _S496 * _S530;
                float _S533 = _S531.x + _S531.y + _S531.z;
                DiffPair_vectorx3Cfloatx2C3x3E_0 _S534;
                (&_S534)->primal_0 = _S495;
                (&_S534)->differential_0 = _S489;
                s_bwd_length_impl_0(&_S534, _S533);
                _S494 = _S532 + _S534.differential_0;
            }
            else
            {
                _S494 = v_normal_1;
            }
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S535;
            (&_S535)->primal_0 = _S495;
            (&_S535)->differential_0 = _S489;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S536;
            (&_S536)->primal_0 = _S495;
            (&_S536)->differential_0 = _S489;
            s_bwd_prop_dot_0(&_S535, &_S536, 0.0f);
            float3  _S537 = _S536.differential_0 + _S535.differential_0 + _S494;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S538;
            (&_S538)->primal_0 = _S497;
            (&_S538)->differential_0 = _S489;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S539;
            (&_S539)->primal_0 = _S498;
            (&_S539)->differential_0 = _S489;
            s_bwd_prop_cross_0(&_S538, &_S539, _S537);
            float3  s_diff_dy_T_1 = - _S539.differential_0;
            float3  _S540 = - s_diff_dy_T_1;
            float3  _S541 = - _S538.differential_0;
            FixedArray<float3 , 4>  _S542;
            _S542[int(0)] = _S489;
            _S542[int(1)] = _S489;
            _S542[int(2)] = _S489;
            _S542[int(3)] = _S489;
            _S542[int(2)] = _S540;
            _S542[int(3)] = s_diff_dy_T_1;
            _S542[int(0)] = _S541;
            _S542[int(1)] = _S538.differential_0;
            points_3[int(0)] = _S542[int(0)];
            points_3[int(1)] = _S542[int(1)];
            points_3[int(2)] = _S542[int(2)];
            points_3[int(3)] = _S542[int(3)];
        }
        else
        {
            points_3[int(0)] = _S489;
            points_3[int(1)] = _S489;
            points_3[int(2)] = _S489;
            points_3[int(3)] = _S489;
        }
        if(_runFlag_5)
        {
            if(_S491)
            {
                if(_runFlag_6)
                {
                    FixedArray<float3 , 4>  _S543 = points_3;
                    FixedArray<float3 , 4>  _S544 = points_3;
                    FixedArray<float3 , 4>  _S545 = points_3;
                    FixedArray<float3 , 4>  _S546 = points_3;
                    if(_S492)
                    {
                        float3  _S547 = _S499 * _S546[int(3)];
                        float _S548 = _S547.x + _S547.y + _S547.z;
                        float4  _S549 = _S528;
                        *&((&_S549)->w) = _S548;
                        points_3[int(0)] = _S543[int(0)];
                        points_3[int(1)] = _S544[int(1)];
                        points_3[int(2)] = _S545[int(2)];
                        points_3[int(3)] = _S489;
                        _S529 = _S549;
                    }
                    else
                    {
                        points_3[int(0)] = _S543[int(0)];
                        points_3[int(1)] = _S544[int(1)];
                        points_3[int(2)] = _S545[int(2)];
                        points_3[int(3)] = _S546[int(3)];
                        _S529 = _S528;
                    }
                    float3  _S550 = _S500 * points_3[int(2)];
                    float _S551 = _S550.x + _S550.y + _S550.z;
                    FixedArray<float3 , 4>  _S552 = points_3;
                    FixedArray<float3 , 4>  _S553 = points_3;
                    float4  _S554 = _S528;
                    *&((&_S554)->z) = _S551;
                    float4  _S555 = _S529 + _S554;
                    points_3[int(0)] = points_3[int(0)];
                    points_3[int(1)] = _S552[int(1)];
                    points_3[int(2)] = _S489;
                    points_3[int(3)] = _S553[int(3)];
                    _S529 = _S555;
                }
                else
                {
                    FixedArray<float3 , 4>  _S556 = points_3;
                    FixedArray<float3 , 4>  _S557 = points_3;
                    FixedArray<float3 , 4>  _S558 = points_3;
                    points_3[int(0)] = points_3[int(0)];
                    points_3[int(1)] = _S556[int(1)];
                    points_3[int(2)] = _S557[int(2)];
                    points_3[int(3)] = _S558[int(3)];
                    _S529 = _S528;
                }
            }
            else
            {
                FixedArray<float3 , 4>  _S559 = points_3;
                FixedArray<float3 , 4>  _S560 = points_3;
                FixedArray<float3 , 4>  _S561 = points_3;
                points_3[int(0)] = points_3[int(0)];
                points_3[int(1)] = _S559[int(1)];
                points_3[int(2)] = _S560[int(2)];
                points_3[int(3)] = _S561[int(3)];
                _S529 = _S528;
            }
            if(_S493)
            {
                FixedArray<float3 , 4>  _S562 = points_3;
                float3  _S563 = _S501 * points_3[int(1)];
                float _S564 = _S563.x + _S563.y + _S563.z;
                float4  _S565 = _S528;
                *&((&_S565)->y) = _S564;
                float4  _S566 = _S529 + _S565;
                points_3[int(0)] = _S489;
                points_3[int(1)] = _S489;
                points_3[int(2)] = _S489;
                points_3[int(3)] = _S489;
                _S494 = _S562[int(0)];
                _S529 = _S566;
            }
            else
            {
                FixedArray<float3 , 4>  _S567 = points_3;
                FixedArray<float3 , 4>  _S568 = points_3;
                FixedArray<float3 , 4>  _S569 = points_3;
                points_3[int(0)] = points_3[int(0)];
                points_3[int(1)] = _S567[int(1)];
                points_3[int(2)] = _S568[int(2)];
                points_3[int(3)] = _S569[int(3)];
                _S494 = _S489;
            }
            float3  _S570 = _S502 * (points_3[int(0)] + _S494);
            float _S571 = _S570.x + _S570.y + _S570.z;
            float4  _S572 = _S528;
            *&((&_S572)->x) = _S571;
            _S529 = _S529 + _S572;
        }
        else
        {
            _S529 = _S528;
        }
    }
    else
    {
        _S529 = _S528;
    }
    *v_depths_0 = _S529;
    return;
}

inline __device__ float ray_depth_to_linear_depth_factor_none(float2  pix_center_2, float4  intrins_5, FixedArray<float, 1>  dist_coeffs_9, int camera_model_7)
{
    float _S573;
    for(;;)
    {
        float2  uv_19 = (pix_center_2 - float2 {intrins_5.z, intrins_5.w}) / float2 {intrins_5.x, intrins_5.y};
        FixedArray<float, 1>  _S574 = dist_coeffs_9;
        float2  uv_u_6;
        bool _S575 = undistort_point_0(uv_19, &_S574, int(12), &uv_u_6);
        if(!_S575)
        {
            _S573 = 0.0f;
            break;
        }
        float3  raydir_2 = unproject_raydir_0(uv_u_6, camera_model_7, false);
        _S573 = float((F32_sign((raydir_2.z)))) / length_0(raydir_2);
        break;
    }
    return _S573;
}

inline __device__ float depth_normal_loss_none(float2  pix_center_3, float4  intrins_6, FixedArray<float, 1>  dist_coeffs_10, int camera_model_8, bool is_ray_depth_7, float4  depths_2, float3  gt_normal_0)
{
    float _S576;
    for(;;)
    {
        float3  _S577;
        float3  * _S578;
        float3  * _S579;
        float3  * _S580;
        float3  * _S581;
        int _S582;
        FixedArray<float3 , 5>  points_4;
        for(;;)
        {
            float2  _S583 = float2 {intrins_6.z, intrins_6.w};
            float2  _S584 = float2 {intrins_6.x, intrins_6.y};
            float2  uv_20 = (pix_center_3 + make_float2 (-1.0f, -0.0f) - _S583) / _S584;
            FixedArray<float, 1>  _S585 = dist_coeffs_10;
            float2  uv_u_7;
            bool _S586 = undistort_point_0(uv_20, &_S585, int(12), &uv_u_7);
            float3  _S587 = make_float3 (0.0f);
            if(!_S586)
            {
                _S582 = int(0);
                _S581 = nullptr;
                _S580 = nullptr;
                _S579 = nullptr;
                _S578 = nullptr;
                _S577 = _S587;
                break;
            }
            float3  raydir_3 = unproject_raydir_0(uv_u_7, camera_model_8, is_ray_depth_7);
            points_4[int(0)] = make_float3 (depths_2.x) * raydir_3;
            float2  uv_21 = (pix_center_3 + make_float2 (1.0f, -0.0f) - _S583) / _S584;
            FixedArray<float, 1>  _S588 = dist_coeffs_10;
            float2  uv_u_8;
            bool _S589 = undistort_point_0(uv_21, &_S588, int(12), &uv_u_8);
            if(!_S589)
            {
                _S582 = int(0);
                _S581 = nullptr;
                _S580 = &points_4[int(0)];
                _S579 = nullptr;
                _S578 = nullptr;
                _S577 = _S587;
                break;
            }
            float3  raydir_4 = unproject_raydir_0(uv_u_8, camera_model_8, is_ray_depth_7);
            points_4[int(1)] = make_float3 (depths_2.y) * raydir_4;
            float2  uv_22 = (pix_center_3 + make_float2 (0.0f, -1.0f) - _S583) / _S584;
            FixedArray<float, 1>  _S590 = dist_coeffs_10;
            float2  uv_u_9;
            bool _S591 = undistort_point_0(uv_22, &_S590, int(12), &uv_u_9);
            if(!_S591)
            {
                _S582 = int(0);
                _S581 = &points_4[int(1)];
                _S580 = &points_4[int(0)];
                _S579 = nullptr;
                _S578 = nullptr;
                _S577 = _S587;
                break;
            }
            float3  raydir_5 = unproject_raydir_0(uv_u_9, camera_model_8, is_ray_depth_7);
            points_4[int(2)] = make_float3 (depths_2.z) * raydir_5;
            float2  uv_23 = (pix_center_3 + make_float2 (0.0f, 1.0f) - _S583) / _S584;
            FixedArray<float, 1>  _S592 = dist_coeffs_10;
            float2  uv_u_10;
            bool _S593 = undistort_point_0(uv_23, &_S592, int(12), &uv_u_10);
            if(!_S593)
            {
                _S582 = int(0);
                _S581 = &points_4[int(1)];
                _S580 = &points_4[int(0)];
                _S579 = nullptr;
                _S578 = &points_4[int(2)];
                _S577 = _S587;
                break;
            }
            float3  raydir_6 = unproject_raydir_0(uv_u_10, camera_model_8, is_ray_depth_7);
            points_4[int(3)] = make_float3 (depths_2.w) * raydir_6;
            float2  uv_24 = (pix_center_3 + make_float2 (0.0f) * make_float2 (0.0f, 3.0f) - _S583) / _S584;
            FixedArray<float, 1>  _S594 = dist_coeffs_10;
            float2  uv_u_11;
            bool _S595 = undistort_point_0(uv_24, &_S594, int(12), &uv_u_11);
            if(!_S595)
            {
                _S582 = int(0);
                _S581 = &points_4[int(1)];
                _S580 = &points_4[int(0)];
                _S579 = &points_4[int(3)];
                _S578 = &points_4[int(2)];
                _S577 = _S587;
                break;
            }
            float3  raydir_7 = unproject_raydir_0(uv_u_11, camera_model_8, is_ray_depth_7);
            _S582 = int(1);
            _S581 = &points_4[int(1)];
            _S580 = &points_4[int(0)];
            _S579 = &points_4[int(3)];
            _S578 = &points_4[int(2)];
            _S577 = raydir_7;
            break;
        }
        if(_S582 != int(1))
        {
            _S576 = 0.0f;
            break;
        }
        float3  normal_4 = cross_0(*_S581 - *_S580, - (*_S579 - *_S578));
        float3  normal_5;
        if((dot_0(normal_4, normal_4)) != 0.0f)
        {
            normal_5 = normalize_0(normal_4);
        }
        else
        {
            normal_5 = normal_4;
        }
        float3  _S596;
        if((dot_0(gt_normal_0, gt_normal_0)) != 0.0f)
        {
            _S596 = normalize_0(gt_normal_0);
        }
        else
        {
            _S596 = gt_normal_0;
        }
        _S576 = (1.0f - dot_0(normal_5, _S596) + 0.00100000004749745f) / ((F32_max((dot_0(normal_5, - normalize_0(_S577))), (0.0f))) + 0.00100000004749745f);
        break;
    }
    return _S576;
}

struct s_bwd_prop_depth_normal_loss_Intermediates_0
{
    float2  _S597;
    bool _S598;
    float2  _S599;
    bool _S600;
    float2  _S601;
    bool _S602;
    float2  _S603;
    bool _S604;
    float2  _S605;
    bool _S606;
};

inline __device__ void s_bwd_prop_normalize_impl_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_14, float3  _s_dOut_9)
{
    float _S607 = length_0((*dpx_14).primal_0);
    float3  _S608 = (*dpx_14).primal_0 * _s_dOut_9;
    float3  _S609 = make_float3 (1.0f / _S607) * _s_dOut_9;
    float _S610 = - ((_S608.x + _S608.y + _S608.z) / (_S607 * _S607));
    float3  _S611 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S612;
    (&_S612)->primal_0 = (*dpx_14).primal_0;
    (&_S612)->differential_0 = _S611;
    s_bwd_length_impl_0(&_S612, _S610);
    float3  _S613 = _S609 + _S612.differential_0;
    dpx_14->primal_0 = (*dpx_14).primal_0;
    dpx_14->differential_0 = _S613;
    return;
}

inline __device__ void s_bwd_normalize_impl_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S614, float3  _S615)
{
    s_bwd_prop_normalize_impl_0(_S614, _S615);
    return;
}

inline __device__ void depth_normal_loss_vjp_none(float2  pix_center_4, float4  intrins_7, FixedArray<float, 1>  dist_coeffs_11, int camera_model_9, bool is_ray_depth_8, float4  depths_3, float3  gt_normal_1, float v_loss_0, float4  * v_depths_1, float3  * v_gt_normal_0)
{
    float2  _S616 = make_float2 (0.0f);
    s_bwd_prop_depth_normal_loss_Intermediates_0 _S617;
    (&_S617)->_S597 = _S616;
    (&_S617)->_S598 = false;
    (&_S617)->_S599 = _S616;
    (&_S617)->_S600 = false;
    (&_S617)->_S601 = _S616;
    (&_S617)->_S602 = false;
    (&_S617)->_S603 = _S616;
    (&_S617)->_S604 = false;
    (&_S617)->_S605 = _S616;
    (&_S617)->_S606 = false;
    (&_S617)->_S599 = _S616;
    (&_S617)->_S600 = false;
    (&_S617)->_S601 = _S616;
    (&_S617)->_S602 = false;
    (&_S617)->_S603 = _S616;
    (&_S617)->_S604 = false;
    (&_S617)->_S605 = _S616;
    (&_S617)->_S606 = false;
    float2  _S618 = float2 {intrins_7.z, intrins_7.w};
    float2  _S619 = float2 {intrins_7.x, intrins_7.y};
    float2  uv_25 = (pix_center_4 + make_float2 (-1.0f, -0.0f) - _S618) / _S619;
    float2  _S620 = _S616;
    FixedArray<float, 1>  _S621 = dist_coeffs_11;
    bool _S622 = undistort_point_0(uv_25, &_S621, int(12), &_S620);
    (&_S617)->_S597 = _S620;
    (&_S617)->_S598 = _S622;
    bool _S623 = !!_S622;
    bool _runFlag_7;
    if(_S623)
    {
        float2  uv_26 = (pix_center_4 + make_float2 (1.0f, -0.0f) - _S618) / _S619;
        float2  _S624 = _S616;
        FixedArray<float, 1>  _S625 = dist_coeffs_11;
        bool _S626 = undistort_point_0(uv_26, &_S625, int(12), &_S624);
        (&_S617)->_S599 = _S624;
        (&_S617)->_S600 = _S626;
        if(!_S626)
        {
            _runFlag_7 = false;
        }
        else
        {
            _runFlag_7 = _S623;
        }
        if(_runFlag_7)
        {
            float2  uv_27 = (pix_center_4 + make_float2 (0.0f, -1.0f) - _S618) / _S619;
            float2  _S627 = _S616;
            FixedArray<float, 1>  _S628 = dist_coeffs_11;
            bool _S629 = undistort_point_0(uv_27, &_S628, int(12), &_S627);
            (&_S617)->_S601 = _S627;
            (&_S617)->_S602 = _S629;
            if(!_S629)
            {
                _runFlag_7 = false;
            }
            if(_runFlag_7)
            {
                float2  uv_28 = (pix_center_4 + make_float2 (0.0f, 1.0f) - _S618) / _S619;
                float2  _S630 = _S616;
                FixedArray<float, 1>  _S631 = dist_coeffs_11;
                bool _S632 = undistort_point_0(uv_28, &_S631, int(12), &_S630);
                (&_S617)->_S603 = _S630;
                (&_S617)->_S604 = _S632;
                if(!_S632)
                {
                    _runFlag_7 = false;
                }
                if(_runFlag_7)
                {
                    float2  uv_29 = (pix_center_4 - _S618) / _S619;
                    float2  _S633 = _S616;
                    FixedArray<float, 1>  _S634 = dist_coeffs_11;
                    bool _S635 = undistort_point_0(uv_29, &_S634, int(12), &_S633);
                    (&_S617)->_S605 = _S633;
                    (&_S617)->_S606 = _S635;
                }
            }
        }
    }
    s_bwd_prop_depth_normal_loss_Intermediates_0 _S636 = _S617;
    float3  _S637 = make_float3 (0.0f);
    bool _S638 = !!_S617._S598;
    bool _runFlag_8;
    bool _runFlag_9;
    bool _runFlag_10;
    int _S639;
    float3  raydir_8;
    float3  _S640;
    float3  _S641;
    float3  _S642;
    float3  _S643;
    FixedArray<float3 , 5>  points_5;
    if(_S638)
    {
        float3  _S644 = s_primal_ctx_unproject_raydir_0(_S636._S597, camera_model_9, is_ray_depth_8);
        float3  _S645 = make_float3 (depths_3.x) * _S644;
        if(!_S636._S600)
        {
            _runFlag_7 = false;
        }
        else
        {
            _runFlag_7 = _S638;
        }
        if(_runFlag_7)
        {
            float3  _S646 = s_primal_ctx_unproject_raydir_0(_S636._S599, camera_model_9, is_ray_depth_8);
            float3  _S647 = make_float3 (depths_3.y) * _S646;
            if(!_S636._S602)
            {
                _runFlag_8 = false;
            }
            else
            {
                _runFlag_8 = _runFlag_7;
            }
            if(_runFlag_8)
            {
                float3  _S648 = s_primal_ctx_unproject_raydir_0(_S636._S601, camera_model_9, is_ray_depth_8);
                float3  _S649 = make_float3 (depths_3.z) * _S648;
                if(!_S636._S604)
                {
                    _runFlag_9 = false;
                }
                else
                {
                    _runFlag_9 = _runFlag_8;
                }
                if(_runFlag_9)
                {
                    float3  _S650 = s_primal_ctx_unproject_raydir_0(_S636._S603, camera_model_9, is_ray_depth_8);
                    float3  _S651 = make_float3 (depths_3.w) * _S650;
                    if(!_S636._S606)
                    {
                        _runFlag_10 = false;
                    }
                    else
                    {
                        _runFlag_10 = _runFlag_9;
                    }
                    if(_runFlag_10)
                    {
                        float3  _S652 = s_primal_ctx_unproject_raydir_0(_S636._S605, camera_model_9, is_ray_depth_8);
                        _S639 = int(1);
                        raydir_8 = _S652;
                    }
                    else
                    {
                        _S639 = int(0);
                        raydir_8 = _S650;
                    }
                    points_5[int(0)] = _S645;
                    points_5[int(1)] = _S647;
                    points_5[int(2)] = _S649;
                    points_5[int(3)] = _S651;
                    points_5[int(4)] = _S637;
                    _S640 = _S650;
                }
                else
                {
                    _S639 = int(0);
                    raydir_8 = _S648;
                    points_5[int(0)] = _S645;
                    points_5[int(1)] = _S647;
                    points_5[int(2)] = _S649;
                    points_5[int(3)] = _S637;
                    points_5[int(4)] = _S637;
                    _S640 = _S637;
                }
                _S641 = _S648;
            }
            else
            {
                _S639 = int(0);
                raydir_8 = _S646;
                points_5[int(0)] = _S645;
                points_5[int(1)] = _S647;
                points_5[int(2)] = _S637;
                points_5[int(3)] = _S637;
                points_5[int(4)] = _S637;
                _runFlag_9 = false;
                _S640 = _S637;
                _S641 = _S637;
            }
            _S642 = _S646;
        }
        else
        {
            _S639 = int(0);
            raydir_8 = _S644;
            points_5[int(0)] = _S645;
            points_5[int(1)] = _S637;
            points_5[int(2)] = _S637;
            points_5[int(3)] = _S637;
            points_5[int(4)] = _S637;
            _runFlag_8 = false;
            _runFlag_9 = false;
            _S640 = _S637;
            _S641 = _S637;
            _S642 = _S637;
        }
        _S643 = _S644;
    }
    else
    {
        _S639 = int(0);
        points_5[int(0)] = _S637;
        points_5[int(1)] = _S637;
        points_5[int(2)] = _S637;
        points_5[int(3)] = _S637;
        points_5[int(4)] = _S637;
        _runFlag_7 = false;
        _runFlag_8 = false;
        _runFlag_9 = false;
        _S640 = _S637;
        _S641 = _S637;
        _S642 = _S637;
        _S643 = _S637;
    }
    bool _S653 = !(_S639 != int(1));
    bool _S654;
    float3  normal_6;
    float3  _S655;
    float3  _S656;
    float3  _S657;
    float3  _S658;
    float _S659;
    float _S660;
    float _S661;
    float _S662;
    if(_S653)
    {
        float3  dx_2 = points_5[int(1)] - points_5[int(0)];
        float3  _S663 = - (points_5[int(3)] - points_5[int(2)]);
        float3  _S664 = s_primal_ctx_cross_0(dx_2, _S663);
        bool _S665 = (s_primal_ctx_dot_0(_S664, _S664)) != 0.0f;
        if(_S665)
        {
            normal_6 = normalize_0(_S664);
        }
        else
        {
            normal_6 = _S664;
        }
        bool _S666 = (s_primal_ctx_dot_0(gt_normal_1, gt_normal_1)) != 0.0f;
        if(_S666)
        {
            _S655 = normalize_0(gt_normal_1);
        }
        else
        {
            _S655 = gt_normal_1;
        }
        float3  _S667 = - normalize_0(raydir_8);
        float _S668 = s_primal_ctx_dot_0(normal_6, _S667);
        float _S669 = 1.0f - s_primal_ctx_dot_0(normal_6, _S655) + 0.00100000004749745f;
        float _S670 = (F32_max((_S668), (0.0f))) + 0.00100000004749745f;
        _S659 = _S670 * _S670;
        _S660 = _S669;
        _S661 = _S670;
        _S662 = _S668;
        raydir_8 = normal_6;
        normal_6 = _S667;
        _runFlag_10 = _S666;
        _S654 = _S665;
        _S656 = _S664;
        _S657 = dx_2;
        _S658 = _S663;
    }
    else
    {
        _S659 = 0.0f;
        _S660 = 0.0f;
        _S661 = 0.0f;
        _S662 = 0.0f;
        raydir_8 = _S637;
        normal_6 = _S637;
        _S655 = _S637;
        _runFlag_10 = false;
        _S654 = false;
        _S656 = _S637;
        _S657 = _S637;
        _S658 = _S637;
    }
    float4  _S671 = make_float4 (0.0f);
    if(_S653)
    {
        float _S672 = v_loss_0 / _S659;
        float _S673 = _S660 * - _S672;
        float s_diff_num_T_0 = _S661 * _S672;
        DiffPair_float_0 _S674;
        (&_S674)->primal_0 = _S662;
        (&_S674)->differential_0 = 0.0f;
        DiffPair_float_0 _S675;
        (&_S675)->primal_0 = 0.0f;
        (&_S675)->differential_0 = 0.0f;
        _d_max_0(&_S674, &_S675, _S673);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S676;
        (&_S676)->primal_0 = raydir_8;
        (&_S676)->differential_0 = _S637;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S677;
        (&_S677)->primal_0 = normal_6;
        (&_S677)->differential_0 = _S637;
        s_bwd_prop_dot_0(&_S676, &_S677, _S674.differential_0);
        float _S678 = - s_diff_num_T_0;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S679;
        (&_S679)->primal_0 = raydir_8;
        (&_S679)->differential_0 = _S637;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S680;
        (&_S680)->primal_0 = _S655;
        (&_S680)->differential_0 = _S637;
        s_bwd_prop_dot_0(&_S679, &_S680, _S678);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S681 = _S680;
        float3  _S682 = _S676.differential_0 + _S679.differential_0;
        if(_runFlag_10)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S683;
            (&_S683)->primal_0 = gt_normal_1;
            (&_S683)->differential_0 = _S637;
            s_bwd_normalize_impl_0(&_S683, _S681.differential_0);
            raydir_8 = _S683.differential_0;
        }
        else
        {
            raydir_8 = _S681.differential_0;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S684;
        (&_S684)->primal_0 = gt_normal_1;
        (&_S684)->differential_0 = _S637;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S685;
        (&_S685)->primal_0 = gt_normal_1;
        (&_S685)->differential_0 = _S637;
        s_bwd_prop_dot_0(&_S684, &_S685, 0.0f);
        float3  _S686 = _S685.differential_0 + _S684.differential_0 + raydir_8;
        if(_S654)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S687;
            (&_S687)->primal_0 = _S656;
            (&_S687)->differential_0 = _S637;
            s_bwd_normalize_impl_0(&_S687, _S682);
            raydir_8 = _S687.differential_0;
        }
        else
        {
            raydir_8 = _S682;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S688;
        (&_S688)->primal_0 = _S656;
        (&_S688)->differential_0 = _S637;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S689;
        (&_S689)->primal_0 = _S656;
        (&_S689)->differential_0 = _S637;
        s_bwd_prop_dot_0(&_S688, &_S689, 0.0f);
        float3  _S690 = _S689.differential_0 + _S688.differential_0 + raydir_8;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S691;
        (&_S691)->primal_0 = _S657;
        (&_S691)->differential_0 = _S637;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S692;
        (&_S692)->primal_0 = _S658;
        (&_S692)->differential_0 = _S637;
        s_bwd_prop_cross_0(&_S691, &_S692, _S690);
        float3  s_diff_dy_T_2 = - _S692.differential_0;
        float3  _S693 = - s_diff_dy_T_2;
        float3  _S694 = - _S691.differential_0;
        FixedArray<float3 , 5>  _S695;
        _S695[int(0)] = _S637;
        _S695[int(1)] = _S637;
        _S695[int(2)] = _S637;
        _S695[int(3)] = _S637;
        _S695[int(4)] = _S637;
        _S695[int(2)] = _S693;
        _S695[int(3)] = s_diff_dy_T_2;
        _S695[int(0)] = _S694;
        _S695[int(1)] = _S691.differential_0;
        points_5[int(0)] = _S695[int(0)];
        points_5[int(1)] = _S695[int(1)];
        points_5[int(2)] = _S695[int(2)];
        points_5[int(3)] = _S695[int(3)];
        points_5[int(4)] = _S695[int(4)];
        raydir_8 = _S686;
    }
    else
    {
        points_5[int(0)] = _S637;
        points_5[int(1)] = _S637;
        points_5[int(2)] = _S637;
        points_5[int(3)] = _S637;
        points_5[int(4)] = _S637;
        raydir_8 = _S637;
    }
    float4  _S696;
    if(_S638)
    {
        if(_runFlag_7)
        {
            if(_runFlag_8)
            {
                if(_runFlag_9)
                {
                    FixedArray<float3 , 5>  _S697 = points_5;
                    FixedArray<float3 , 5>  _S698 = points_5;
                    FixedArray<float3 , 5>  _S699 = points_5;
                    float3  _S700 = _S640 * points_5[int(3)];
                    float _S701 = _S700.x + _S700.y + _S700.z;
                    float4  _S702 = _S671;
                    *&((&_S702)->w) = _S701;
                    points_5[int(0)] = _S637;
                    points_5[int(1)] = _S637;
                    points_5[int(2)] = _S637;
                    points_5[int(3)] = _S637;
                    points_5[int(4)] = _S637;
                    _S640 = _S699[int(2)];
                    normal_6 = _S697[int(0)];
                    _S655 = _S698[int(1)];
                    _S696 = _S702;
                }
                else
                {
                    FixedArray<float3 , 5>  _S703 = points_5;
                    FixedArray<float3 , 5>  _S704 = points_5;
                    FixedArray<float3 , 5>  _S705 = points_5;
                    FixedArray<float3 , 5>  _S706 = points_5;
                    points_5[int(0)] = points_5[int(0)];
                    points_5[int(1)] = _S703[int(1)];
                    points_5[int(2)] = _S704[int(2)];
                    points_5[int(3)] = _S705[int(3)];
                    points_5[int(4)] = _S706[int(4)];
                    _S640 = _S637;
                    normal_6 = _S637;
                    _S655 = _S637;
                    _S696 = _S671;
                }
                float3  _S707 = _S641 * (points_5[int(2)] + _S640);
                float _S708 = _S707.x + _S707.y + _S707.z;
                float3  _S709 = points_5[int(0)] + normal_6;
                float3  _S710 = points_5[int(1)] + _S655;
                float4  _S711 = _S671;
                *&((&_S711)->z) = _S708;
                float4  _S712 = _S696 + _S711;
                points_5[int(0)] = _S637;
                points_5[int(1)] = _S637;
                points_5[int(2)] = _S637;
                points_5[int(3)] = _S637;
                points_5[int(4)] = _S637;
                _S640 = _S710;
                _S641 = _S709;
                _S696 = _S712;
            }
            else
            {
                FixedArray<float3 , 5>  _S713 = points_5;
                FixedArray<float3 , 5>  _S714 = points_5;
                FixedArray<float3 , 5>  _S715 = points_5;
                FixedArray<float3 , 5>  _S716 = points_5;
                points_5[int(0)] = points_5[int(0)];
                points_5[int(1)] = _S713[int(1)];
                points_5[int(2)] = _S714[int(2)];
                points_5[int(3)] = _S715[int(3)];
                points_5[int(4)] = _S716[int(4)];
                _S640 = _S637;
                _S641 = _S637;
                _S696 = _S671;
            }
            float3  _S717 = _S642 * (points_5[int(1)] + _S640);
            float _S718 = _S717.x + _S717.y + _S717.z;
            float3  _S719 = points_5[int(0)] + _S641;
            float4  _S720 = _S671;
            *&((&_S720)->y) = _S718;
            float4  _S721 = _S696 + _S720;
            points_5[int(0)] = _S637;
            points_5[int(1)] = _S637;
            points_5[int(2)] = _S637;
            points_5[int(3)] = _S637;
            points_5[int(4)] = _S637;
            _S640 = _S719;
            _S696 = _S721;
        }
        else
        {
            FixedArray<float3 , 5>  _S722 = points_5;
            FixedArray<float3 , 5>  _S723 = points_5;
            FixedArray<float3 , 5>  _S724 = points_5;
            FixedArray<float3 , 5>  _S725 = points_5;
            points_5[int(0)] = points_5[int(0)];
            points_5[int(1)] = _S722[int(1)];
            points_5[int(2)] = _S723[int(2)];
            points_5[int(3)] = _S724[int(3)];
            points_5[int(4)] = _S725[int(4)];
            _S640 = _S637;
            _S696 = _S671;
        }
        float3  _S726 = _S643 * (points_5[int(0)] + _S640);
        float _S727 = _S726.x + _S726.y + _S726.z;
        float4  _S728 = _S671;
        *&((&_S728)->x) = _S727;
        _S696 = _S696 + _S728;
    }
    else
    {
        _S696 = _S671;
    }
    *v_depths_1 = _S696;
    *v_gt_normal_0 = raydir_8;
    return;
}

inline __device__ float3  generate_ray_d2n_opencv(float2  pix_pos_3, float4  intrins_8, FixedArray<float, 4>  dist_coeffs_12, int camera_model_10, bool is_ray_depth_9)
{
    float3  _S729;
    for(;;)
    {
        float2  uv_30 = (pix_pos_3 - float2 {intrins_8.z, intrins_8.w}) / float2 {intrins_8.x, intrins_8.y};
        FixedArray<float, 4>  _S730 = dist_coeffs_12;
        float2  uv_u_12;
        bool _S731 = undistort_point_1(uv_30, &_S730, int(12), &uv_u_12);
        if(!_S731)
        {
            int3  _S732 = make_int3 (int(0));
            float3  _S733 = make_float3 ((float)_S732.x, (float)_S732.y, (float)_S732.z);
            _S729 = _S733;
            break;
        }
        _S729 = unproject_raydir_0(uv_u_12, camera_model_10, is_ray_depth_9);
        break;
    }
    return _S729;
}

inline __device__ float3  depth_to_point_opencv(float2  pix_pos_4, float4  intrins_9, FixedArray<float, 4>  dist_coeffs_13, int camera_model_11, bool is_ray_depth_10, float depth_4)
{
    float3  _S734;
    for(;;)
    {
        float2  uv_31 = (pix_pos_4 - float2 {intrins_9.z, intrins_9.w}) / float2 {intrins_9.x, intrins_9.y};
        FixedArray<float, 4>  _S735 = dist_coeffs_13;
        float2  uv_u_13;
        bool _S736 = undistort_point_1(uv_31, &_S735, int(12), &uv_u_13);
        if(!_S736)
        {
            _S734 = make_float3 (0.0f);
            break;
        }
        _S734 = make_float3 (depth_4) * unproject_raydir_0(uv_u_13, camera_model_11, is_ray_depth_10);
        break;
    }
    return _S734;
}

struct s_bwd_prop_depth_to_point_Intermediates_1
{
    float2  _S737;
    bool _S738;
};

inline __device__ float depth_to_point_vjp_opencv(float2  pix_pos_5, float4  intrins_10, FixedArray<float, 4>  dist_coeffs_14, int camera_model_12, bool is_ray_depth_11, float depth_5, float3  v_point_1)
{
    float2  _S739 = make_float2 (0.0f);
    s_bwd_prop_depth_to_point_Intermediates_1 _S740;
    (&_S740)->_S737 = _S739;
    (&_S740)->_S738 = false;
    float2  uv_32 = (pix_pos_5 - float2 {intrins_10.z, intrins_10.w}) / float2 {intrins_10.x, intrins_10.y};
    float2  _S741 = _S739;
    FixedArray<float, 4>  _S742 = dist_coeffs_14;
    bool _S743 = undistort_point_1(uv_32, &_S742, int(12), &_S741);
    (&_S740)->_S737 = _S741;
    (&_S740)->_S738 = _S743;
    s_bwd_prop_depth_to_point_Intermediates_1 _S744 = _S740;
    float3  _S745 = make_float3 (0.0f);
    bool _S746 = !!_S740._S738;
    float3  _S747;
    if(_S746)
    {
        _S747 = s_primal_ctx_unproject_raydir_0(_S744._S737, camera_model_12, is_ray_depth_11);
    }
    else
    {
        _S747 = _S745;
    }
    if(_S746)
    {
        _S747 = _S747 * v_point_1;
    }
    else
    {
        _S747 = _S745;
    }
    return _S747.x + _S747.y + _S747.z;
}

inline __device__ float3  depth_to_normal_opencv(float2  pix_center_5, float4  intrins_11, FixedArray<float, 4>  dist_coeffs_15, int camera_model_13, bool is_ray_depth_12, float4  depths_4)
{
    float3  normal_7;
    for(;;)
    {
        bool _S748;
        if((depths_4.x) == 0.0f)
        {
            _S748 = true;
        }
        else
        {
            _S748 = (depths_4.y) == 0.0f;
        }
        if(_S748)
        {
            _S748 = true;
        }
        else
        {
            _S748 = (depths_4.z) == 0.0f;
        }
        if(_S748)
        {
            _S748 = true;
        }
        else
        {
            _S748 = (depths_4.w) == 0.0f;
        }
        if(_S748)
        {
            normal_7 = make_float3 (0.0f);
            break;
        }
        float3  * _S749;
        float3  * _S750;
        float3  * _S751;
        float3  * _S752;
        int _S753;
        FixedArray<float3 , 4>  points_6;
        for(;;)
        {
            float2  _S754 = float2 {intrins_11.z, intrins_11.w};
            float2  _S755 = float2 {intrins_11.x, intrins_11.y};
            float2  uv_33 = (pix_center_5 + make_float2 (-1.0f, -0.0f) - _S754) / _S755;
            FixedArray<float, 4>  _S756 = dist_coeffs_15;
            float2  uv_u_14;
            bool _S757 = undistort_point_1(uv_33, &_S756, int(12), &uv_u_14);
            if(!_S757)
            {
                float3  _S758 = make_float3 (0.0f);
                _S753 = int(0);
                _S752 = nullptr;
                _S751 = nullptr;
                _S750 = nullptr;
                _S749 = nullptr;
                normal_7 = _S758;
                break;
            }
            points_6[int(0)] = make_float3 (depths_4.x) * unproject_raydir_0(uv_u_14, camera_model_13, is_ray_depth_12);
            for(;;)
            {
                float2  uv_34 = (pix_center_5 + make_float2 (1.0f, -0.0f) - _S754) / _S755;
                FixedArray<float, 4>  _S759 = dist_coeffs_15;
                float2  uv_u_15;
                bool _S760 = undistort_point_1(uv_34, &_S759, int(12), &uv_u_15);
                if(!_S760)
                {
                    float3  _S761 = make_float3 (0.0f);
                    _S753 = int(0);
                    _S752 = nullptr;
                    normal_7 = _S761;
                    break;
                }
                points_6[int(1)] = make_float3 (depths_4.y) * unproject_raydir_0(uv_u_15, camera_model_13, is_ray_depth_12);
                _S753 = int(2);
                _S752 = &points_6[int(1)];
                break;
            }
            if(_S753 != int(2))
            {
                _S751 = &points_6[int(0)];
                _S750 = nullptr;
                _S749 = nullptr;
                break;
            }
            float2  uv_35 = (pix_center_5 + make_float2 (0.0f, -1.0f) - _S754) / _S755;
            FixedArray<float, 4>  _S762 = dist_coeffs_15;
            float2  uv_u_16;
            bool _S763 = undistort_point_1(uv_35, &_S762, int(12), &uv_u_16);
            if(!_S763)
            {
                float3  _S764 = make_float3 (0.0f);
                _S753 = int(0);
                _S751 = &points_6[int(0)];
                _S750 = nullptr;
                _S749 = nullptr;
                normal_7 = _S764;
                break;
            }
            points_6[int(2)] = make_float3 (depths_4.z) * unproject_raydir_0(uv_u_16, camera_model_13, is_ray_depth_12);
            for(;;)
            {
                float2  uv_36 = (pix_center_5 + make_float2 (0.0f, 1.0f) - _S754) / _S755;
                FixedArray<float, 4>  _S765 = dist_coeffs_15;
                float2  uv_u_17;
                bool _S766 = undistort_point_1(uv_36, &_S765, int(12), &uv_u_17);
                if(!_S766)
                {
                    float3  _S767 = make_float3 (0.0f);
                    _S753 = int(0);
                    _S751 = nullptr;
                    normal_7 = _S767;
                    break;
                }
                points_6[int(3)] = make_float3 (depths_4.w) * unproject_raydir_0(uv_u_17, camera_model_13, is_ray_depth_12);
                _S753 = int(2);
                _S751 = &points_6[int(3)];
                break;
            }
            if(_S753 != int(2))
            {
                float3  * _S768 = _S751;
                _S751 = &points_6[int(0)];
                _S750 = _S768;
                _S749 = &points_6[int(2)];
                break;
            }
            float3  * _S769 = _S751;
            _S753 = int(1);
            _S751 = &points_6[int(0)];
            _S750 = _S769;
            _S749 = &points_6[int(2)];
            break;
        }
        if(_S753 != int(1))
        {
            break;
        }
        float3  normal_8 = cross_0(*_S752 - *_S751, - (*_S750 - *_S749));
        if((dot_0(normal_8, normal_8)) != 0.0f)
        {
            normal_7 = normal_8 / make_float3 (length_0(normal_8));
        }
        else
        {
            normal_7 = normal_8;
        }
        break;
    }
    return normal_7;
}

struct s_bwd_prop_depth_to_normal_Intermediates_1
{
    float2  _S770;
    bool _S771;
    float2  _S772;
    bool _S773;
    float2  _S774;
    bool _S775;
    float2  _S776;
    bool _S777;
};

inline __device__ void depth_to_normal_vjp_opencv(float2  pix_center_6, float4  intrins_12, FixedArray<float, 4>  dist_coeffs_16, int camera_model_14, bool is_ray_depth_13, float4  depths_5, float3  v_normal_2, float4  * v_depths_2)
{
    float2  _S778 = make_float2 (0.0f);
    s_bwd_prop_depth_to_normal_Intermediates_1 _S779;
    (&_S779)->_S770 = _S778;
    (&_S779)->_S771 = false;
    (&_S779)->_S772 = _S778;
    (&_S779)->_S773 = false;
    (&_S779)->_S774 = _S778;
    (&_S779)->_S775 = false;
    (&_S779)->_S776 = _S778;
    (&_S779)->_S777 = false;
    (&_S779)->_S770 = _S778;
    (&_S779)->_S771 = false;
    (&_S779)->_S772 = _S778;
    (&_S779)->_S773 = false;
    (&_S779)->_S774 = _S778;
    (&_S779)->_S775 = false;
    (&_S779)->_S776 = _S778;
    (&_S779)->_S777 = false;
    bool _S780 = (depths_5.x) == 0.0f;
    bool _runFlag_11;
    if(_S780)
    {
        _runFlag_11 = true;
    }
    else
    {
        _runFlag_11 = (depths_5.y) == 0.0f;
    }
    if(_runFlag_11)
    {
        _runFlag_11 = true;
    }
    else
    {
        _runFlag_11 = (depths_5.z) == 0.0f;
    }
    if(_runFlag_11)
    {
        _runFlag_11 = true;
    }
    else
    {
        _runFlag_11 = (depths_5.w) == 0.0f;
    }
    int _S781;
    if(!_runFlag_11)
    {
        float2  _S782 = float2 {intrins_12.z, intrins_12.w};
        float2  _S783 = float2 {intrins_12.x, intrins_12.y};
        float2  uv_37 = (pix_center_6 + make_float2 (-1.0f, -0.0f) - _S782) / _S783;
        float2  _S784 = _S778;
        FixedArray<float, 4>  _S785 = dist_coeffs_16;
        bool _S786 = undistort_point_1(uv_37, &_S785, int(12), &_S784);
        (&_S779)->_S770 = _S784;
        (&_S779)->_S771 = _S786;
        bool _S787 = !!_S786;
        if(_S787)
        {
            float2  uv_38 = (pix_center_6 + make_float2 (1.0f, -0.0f) - _S782) / _S783;
            float2  _S788 = _S778;
            FixedArray<float, 4>  _S789 = dist_coeffs_16;
            bool _S790 = undistort_point_1(uv_38, &_S789, int(12), &_S788);
            (&_S779)->_S772 = _S788;
            (&_S779)->_S773 = _S790;
            if(!!_S790)
            {
                _S781 = int(2);
            }
            else
            {
                _S781 = int(0);
            }
            if(_S781 != int(2))
            {
                _runFlag_11 = false;
            }
            else
            {
                _runFlag_11 = _S787;
            }
            if(_runFlag_11)
            {
                float2  uv_39 = (pix_center_6 + make_float2 (0.0f, -1.0f) - _S782) / _S783;
                float2  _S791 = _S778;
                FixedArray<float, 4>  _S792 = dist_coeffs_16;
                bool _S793 = undistort_point_1(uv_39, &_S792, int(12), &_S791);
                (&_S779)->_S774 = _S791;
                (&_S779)->_S775 = _S793;
                if(!_S793)
                {
                    _runFlag_11 = false;
                }
                if(_runFlag_11)
                {
                    float2  uv_40 = (pix_center_6 + make_float2 (0.0f, 1.0f) - _S782) / _S783;
                    float2  _S794 = _S778;
                    FixedArray<float, 4>  _S795 = dist_coeffs_16;
                    bool _S796 = undistort_point_1(uv_40, &_S795, int(12), &_S794);
                    (&_S779)->_S776 = _S794;
                    (&_S779)->_S777 = _S796;
                }
            }
        }
    }
    s_bwd_prop_depth_to_normal_Intermediates_1 _S797 = _S779;
    float3  _S798 = make_float3 (0.0f);
    if(_S780)
    {
        _runFlag_11 = true;
    }
    else
    {
        _runFlag_11 = (depths_5.y) == 0.0f;
    }
    if(_runFlag_11)
    {
        _runFlag_11 = true;
    }
    else
    {
        _runFlag_11 = (depths_5.z) == 0.0f;
    }
    if(_runFlag_11)
    {
        _runFlag_11 = true;
    }
    else
    {
        _runFlag_11 = (depths_5.w) == 0.0f;
    }
    bool _S799 = !_runFlag_11;
    bool _runFlag_12;
    bool _runFlag_13;
    bool _S800;
    bool _runFlag_14;
    bool _S801;
    bool _S802;
    FixedArray<float3 , 4>  points_7;
    float3  _S803;
    float3  _S804;
    float3  _S805;
    float3  _S806;
    float3  _S807;
    float3  _S808;
    float3  _S809;
    float3  _S810;
    float3  _S811;
    if(_S799)
    {
        bool _S812 = !!_S797._S771;
        if(_S812)
        {
            float3  _S813 = s_primal_ctx_unproject_raydir_0(_S797._S770, camera_model_14, is_ray_depth_13);
            float3  _S814 = make_float3 (depths_5.x) * _S813;
            bool _S815 = !!_S797._S773;
            if(_S815)
            {
                float3  _S816 = s_primal_ctx_unproject_raydir_0(_S797._S772, camera_model_14, is_ray_depth_13);
                float3  _S817 = make_float3 (depths_5.y) * _S816;
                _S781 = int(2);
                points_7[int(0)] = _S814;
                points_7[int(1)] = _S817;
                points_7[int(2)] = _S798;
                points_7[int(3)] = _S798;
                _S803 = _S816;
            }
            else
            {
                _S781 = int(0);
                points_7[int(0)] = _S814;
                points_7[int(1)] = _S798;
                points_7[int(2)] = _S798;
                points_7[int(3)] = _S798;
                _S803 = _S798;
            }
            if(_S781 != int(2))
            {
                _runFlag_11 = false;
            }
            else
            {
                _runFlag_11 = _S812;
                _S781 = int(0);
            }
            if(_runFlag_11)
            {
                if(!_S797._S775)
                {
                    _runFlag_12 = false;
                    _S781 = int(0);
                }
                else
                {
                    _runFlag_12 = _runFlag_11;
                }
                if(_runFlag_12)
                {
                    float3  _S818 = s_primal_ctx_unproject_raydir_0(_S797._S774, camera_model_14, is_ray_depth_13);
                    points_7[int(2)] = make_float3 (depths_5.z) * _S818;
                    bool _S819 = !!_S797._S777;
                    int _S820;
                    if(_S819)
                    {
                        float3  _S821 = s_primal_ctx_unproject_raydir_0(_S797._S776, camera_model_14, is_ray_depth_13);
                        points_7[int(3)] = make_float3 (depths_5.w) * _S821;
                        _S820 = int(2);
                        _S804 = _S821;
                    }
                    else
                    {
                        _S820 = int(0);
                        _S804 = _S798;
                    }
                    if(_S820 != int(2))
                    {
                        _runFlag_13 = false;
                        _S781 = _S820;
                    }
                    else
                    {
                        _runFlag_13 = _runFlag_12;
                    }
                    if(_runFlag_13)
                    {
                        _S781 = int(1);
                    }
                    _runFlag_13 = _S819;
                    _S805 = _S818;
                }
                else
                {
                    _runFlag_13 = false;
                    _S804 = _S798;
                    _S805 = _S798;
                }
            }
            else
            {
                _runFlag_12 = false;
                _runFlag_13 = false;
                _S804 = _S798;
                _S805 = _S798;
            }
            float3  _S822 = _S803;
            _S803 = _S804;
            _S804 = _S805;
            _S800 = _S815;
            _S805 = _S822;
            _S806 = _S813;
        }
        else
        {
            _S781 = int(0);
            points_7[int(0)] = _S798;
            points_7[int(1)] = _S798;
            points_7[int(2)] = _S798;
            points_7[int(3)] = _S798;
            _runFlag_11 = false;
            _runFlag_12 = false;
            _runFlag_13 = false;
            _S803 = _S798;
            _S804 = _S798;
            _S800 = false;
            _S805 = _S798;
            _S806 = _S798;
        }
        if(_S781 != int(1))
        {
            _runFlag_14 = false;
        }
        else
        {
            _runFlag_14 = _S799;
        }
        if(_runFlag_14)
        {
            float3  dx_3 = points_7[int(1)] - points_7[int(0)];
            float3  _S823 = - (points_7[int(3)] - points_7[int(2)]);
            float3  _S824 = s_primal_ctx_cross_0(dx_3, _S823);
            bool _S825 = (s_primal_ctx_dot_0(_S824, _S824)) != 0.0f;
            if(_S825)
            {
                float _S826 = length_0(_S824);
                float3  _S827 = make_float3 (_S826);
                _S807 = make_float3 (_S826 * _S826);
                _S808 = _S827;
            }
            else
            {
                _S807 = _S798;
                _S808 = _S798;
            }
            float3  _S828 = _S808;
            _S801 = _S825;
            _S808 = _S824;
            _S809 = _S828;
            _S810 = dx_3;
            _S811 = _S823;
        }
        else
        {
            _S801 = false;
            _S807 = _S798;
            _S808 = _S798;
            _S809 = _S798;
            _S810 = _S798;
            _S811 = _S798;
        }
        bool _S829 = _runFlag_11;
        bool _S830 = _runFlag_12;
        bool _S831 = _runFlag_13;
        float3  _S832 = _S803;
        float3  _S833 = _S804;
        bool _S834 = _S800;
        float3  _S835 = _S805;
        float3  _S836 = _S806;
        _runFlag_11 = _runFlag_14;
        _runFlag_12 = _S801;
        _S803 = _S807;
        _S804 = _S808;
        _S805 = _S809;
        _S806 = _S810;
        _S807 = _S811;
        _runFlag_13 = _S812;
        _S800 = _S829;
        _runFlag_14 = _S830;
        _S801 = _S831;
        _S808 = _S832;
        _S809 = _S833;
        _S802 = _S834;
        _S810 = _S835;
        _S811 = _S836;
    }
    else
    {
        _runFlag_11 = false;
        _runFlag_12 = false;
        _S803 = _S798;
        _S804 = _S798;
        _S805 = _S798;
        _S806 = _S798;
        _S807 = _S798;
        _runFlag_13 = false;
        _S800 = false;
        _runFlag_14 = false;
        _S801 = false;
        _S808 = _S798;
        _S809 = _S798;
        _S802 = false;
        _S810 = _S798;
        _S811 = _S798;
    }
    float4  _S837 = make_float4 (0.0f);
    float4  _S838;
    if(_S799)
    {
        if(_runFlag_11)
        {
            if(_runFlag_12)
            {
                float3  _S839 = v_normal_2 / _S803;
                float3  _S840 = _S804 * - _S839;
                float3  _S841 = _S805 * _S839;
                float _S842 = _S840.x + _S840.y + _S840.z;
                DiffPair_vectorx3Cfloatx2C3x3E_0 _S843;
                (&_S843)->primal_0 = _S804;
                (&_S843)->differential_0 = _S798;
                s_bwd_length_impl_0(&_S843, _S842);
                _S803 = _S841 + _S843.differential_0;
            }
            else
            {
                _S803 = v_normal_2;
            }
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S844;
            (&_S844)->primal_0 = _S804;
            (&_S844)->differential_0 = _S798;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S845;
            (&_S845)->primal_0 = _S804;
            (&_S845)->differential_0 = _S798;
            s_bwd_prop_dot_0(&_S844, &_S845, 0.0f);
            float3  _S846 = _S845.differential_0 + _S844.differential_0 + _S803;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S847;
            (&_S847)->primal_0 = _S806;
            (&_S847)->differential_0 = _S798;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S848;
            (&_S848)->primal_0 = _S807;
            (&_S848)->differential_0 = _S798;
            s_bwd_prop_cross_0(&_S847, &_S848, _S846);
            float3  s_diff_dy_T_3 = - _S848.differential_0;
            float3  _S849 = - s_diff_dy_T_3;
            float3  _S850 = - _S847.differential_0;
            FixedArray<float3 , 4>  _S851;
            _S851[int(0)] = _S798;
            _S851[int(1)] = _S798;
            _S851[int(2)] = _S798;
            _S851[int(3)] = _S798;
            _S851[int(2)] = _S849;
            _S851[int(3)] = s_diff_dy_T_3;
            _S851[int(0)] = _S850;
            _S851[int(1)] = _S847.differential_0;
            points_7[int(0)] = _S851[int(0)];
            points_7[int(1)] = _S851[int(1)];
            points_7[int(2)] = _S851[int(2)];
            points_7[int(3)] = _S851[int(3)];
        }
        else
        {
            points_7[int(0)] = _S798;
            points_7[int(1)] = _S798;
            points_7[int(2)] = _S798;
            points_7[int(3)] = _S798;
        }
        if(_runFlag_13)
        {
            if(_S800)
            {
                if(_runFlag_14)
                {
                    FixedArray<float3 , 4>  _S852 = points_7;
                    FixedArray<float3 , 4>  _S853 = points_7;
                    FixedArray<float3 , 4>  _S854 = points_7;
                    FixedArray<float3 , 4>  _S855 = points_7;
                    if(_S801)
                    {
                        float3  _S856 = _S808 * _S855[int(3)];
                        float _S857 = _S856.x + _S856.y + _S856.z;
                        float4  _S858 = _S837;
                        *&((&_S858)->w) = _S857;
                        points_7[int(0)] = _S852[int(0)];
                        points_7[int(1)] = _S853[int(1)];
                        points_7[int(2)] = _S854[int(2)];
                        points_7[int(3)] = _S798;
                        _S838 = _S858;
                    }
                    else
                    {
                        points_7[int(0)] = _S852[int(0)];
                        points_7[int(1)] = _S853[int(1)];
                        points_7[int(2)] = _S854[int(2)];
                        points_7[int(3)] = _S855[int(3)];
                        _S838 = _S837;
                    }
                    float3  _S859 = _S809 * points_7[int(2)];
                    float _S860 = _S859.x + _S859.y + _S859.z;
                    FixedArray<float3 , 4>  _S861 = points_7;
                    FixedArray<float3 , 4>  _S862 = points_7;
                    float4  _S863 = _S837;
                    *&((&_S863)->z) = _S860;
                    float4  _S864 = _S838 + _S863;
                    points_7[int(0)] = points_7[int(0)];
                    points_7[int(1)] = _S861[int(1)];
                    points_7[int(2)] = _S798;
                    points_7[int(3)] = _S862[int(3)];
                    _S838 = _S864;
                }
                else
                {
                    FixedArray<float3 , 4>  _S865 = points_7;
                    FixedArray<float3 , 4>  _S866 = points_7;
                    FixedArray<float3 , 4>  _S867 = points_7;
                    points_7[int(0)] = points_7[int(0)];
                    points_7[int(1)] = _S865[int(1)];
                    points_7[int(2)] = _S866[int(2)];
                    points_7[int(3)] = _S867[int(3)];
                    _S838 = _S837;
                }
            }
            else
            {
                FixedArray<float3 , 4>  _S868 = points_7;
                FixedArray<float3 , 4>  _S869 = points_7;
                FixedArray<float3 , 4>  _S870 = points_7;
                points_7[int(0)] = points_7[int(0)];
                points_7[int(1)] = _S868[int(1)];
                points_7[int(2)] = _S869[int(2)];
                points_7[int(3)] = _S870[int(3)];
                _S838 = _S837;
            }
            if(_S802)
            {
                FixedArray<float3 , 4>  _S871 = points_7;
                float3  _S872 = _S810 * points_7[int(1)];
                float _S873 = _S872.x + _S872.y + _S872.z;
                float4  _S874 = _S837;
                *&((&_S874)->y) = _S873;
                float4  _S875 = _S838 + _S874;
                points_7[int(0)] = _S798;
                points_7[int(1)] = _S798;
                points_7[int(2)] = _S798;
                points_7[int(3)] = _S798;
                _S803 = _S871[int(0)];
                _S838 = _S875;
            }
            else
            {
                FixedArray<float3 , 4>  _S876 = points_7;
                FixedArray<float3 , 4>  _S877 = points_7;
                FixedArray<float3 , 4>  _S878 = points_7;
                points_7[int(0)] = points_7[int(0)];
                points_7[int(1)] = _S876[int(1)];
                points_7[int(2)] = _S877[int(2)];
                points_7[int(3)] = _S878[int(3)];
                _S803 = _S798;
            }
            float3  _S879 = _S811 * (points_7[int(0)] + _S803);
            float _S880 = _S879.x + _S879.y + _S879.z;
            float4  _S881 = _S837;
            *&((&_S881)->x) = _S880;
            _S838 = _S838 + _S881;
        }
        else
        {
            _S838 = _S837;
        }
    }
    else
    {
        _S838 = _S837;
    }
    *v_depths_2 = _S838;
    return;
}

inline __device__ float ray_depth_to_linear_depth_factor_opencv(float2  pix_center_7, float4  intrins_13, FixedArray<float, 4>  dist_coeffs_17, int camera_model_15)
{
    float _S882;
    for(;;)
    {
        float2  uv_41 = (pix_center_7 - float2 {intrins_13.z, intrins_13.w}) / float2 {intrins_13.x, intrins_13.y};
        FixedArray<float, 4>  _S883 = dist_coeffs_17;
        float2  uv_u_18;
        bool _S884 = undistort_point_1(uv_41, &_S883, int(12), &uv_u_18);
        if(!_S884)
        {
            _S882 = 0.0f;
            break;
        }
        float3  raydir_9 = unproject_raydir_0(uv_u_18, camera_model_15, false);
        _S882 = float((F32_sign((raydir_9.z)))) / length_0(raydir_9);
        break;
    }
    return _S882;
}

inline __device__ float depth_normal_loss_opencv(float2  pix_center_8, float4  intrins_14, FixedArray<float, 4>  dist_coeffs_18, int camera_model_16, bool is_ray_depth_14, float4  depths_6, float3  gt_normal_2)
{
    float _S885;
    for(;;)
    {
        float3  _S886;
        float3  * _S887;
        float3  * _S888;
        float3  * _S889;
        float3  * _S890;
        int _S891;
        FixedArray<float3 , 5>  points_8;
        for(;;)
        {
            float2  _S892 = float2 {intrins_14.z, intrins_14.w};
            float2  _S893 = float2 {intrins_14.x, intrins_14.y};
            float2  uv_42 = (pix_center_8 + make_float2 (-1.0f, -0.0f) - _S892) / _S893;
            FixedArray<float, 4>  _S894 = dist_coeffs_18;
            float2  uv_u_19;
            bool _S895 = undistort_point_1(uv_42, &_S894, int(12), &uv_u_19);
            float3  _S896 = make_float3 (0.0f);
            if(!_S895)
            {
                _S891 = int(0);
                _S890 = nullptr;
                _S889 = nullptr;
                _S888 = nullptr;
                _S887 = nullptr;
                _S886 = _S896;
                break;
            }
            float3  raydir_10 = unproject_raydir_0(uv_u_19, camera_model_16, is_ray_depth_14);
            points_8[int(0)] = make_float3 (depths_6.x) * raydir_10;
            float2  uv_43 = (pix_center_8 + make_float2 (1.0f, -0.0f) - _S892) / _S893;
            FixedArray<float, 4>  _S897 = dist_coeffs_18;
            float2  uv_u_20;
            bool _S898 = undistort_point_1(uv_43, &_S897, int(12), &uv_u_20);
            if(!_S898)
            {
                _S891 = int(0);
                _S890 = nullptr;
                _S889 = &points_8[int(0)];
                _S888 = nullptr;
                _S887 = nullptr;
                _S886 = _S896;
                break;
            }
            float3  raydir_11 = unproject_raydir_0(uv_u_20, camera_model_16, is_ray_depth_14);
            points_8[int(1)] = make_float3 (depths_6.y) * raydir_11;
            float2  uv_44 = (pix_center_8 + make_float2 (0.0f, -1.0f) - _S892) / _S893;
            FixedArray<float, 4>  _S899 = dist_coeffs_18;
            float2  uv_u_21;
            bool _S900 = undistort_point_1(uv_44, &_S899, int(12), &uv_u_21);
            if(!_S900)
            {
                _S891 = int(0);
                _S890 = &points_8[int(1)];
                _S889 = &points_8[int(0)];
                _S888 = nullptr;
                _S887 = nullptr;
                _S886 = _S896;
                break;
            }
            float3  raydir_12 = unproject_raydir_0(uv_u_21, camera_model_16, is_ray_depth_14);
            points_8[int(2)] = make_float3 (depths_6.z) * raydir_12;
            float2  uv_45 = (pix_center_8 + make_float2 (0.0f, 1.0f) - _S892) / _S893;
            FixedArray<float, 4>  _S901 = dist_coeffs_18;
            float2  uv_u_22;
            bool _S902 = undistort_point_1(uv_45, &_S901, int(12), &uv_u_22);
            if(!_S902)
            {
                _S891 = int(0);
                _S890 = &points_8[int(1)];
                _S889 = &points_8[int(0)];
                _S888 = nullptr;
                _S887 = &points_8[int(2)];
                _S886 = _S896;
                break;
            }
            float3  raydir_13 = unproject_raydir_0(uv_u_22, camera_model_16, is_ray_depth_14);
            points_8[int(3)] = make_float3 (depths_6.w) * raydir_13;
            float2  uv_46 = (pix_center_8 + make_float2 (0.0f) * make_float2 (0.0f, 3.0f) - _S892) / _S893;
            FixedArray<float, 4>  _S903 = dist_coeffs_18;
            float2  uv_u_23;
            bool _S904 = undistort_point_1(uv_46, &_S903, int(12), &uv_u_23);
            if(!_S904)
            {
                _S891 = int(0);
                _S890 = &points_8[int(1)];
                _S889 = &points_8[int(0)];
                _S888 = &points_8[int(3)];
                _S887 = &points_8[int(2)];
                _S886 = _S896;
                break;
            }
            float3  raydir_14 = unproject_raydir_0(uv_u_23, camera_model_16, is_ray_depth_14);
            _S891 = int(1);
            _S890 = &points_8[int(1)];
            _S889 = &points_8[int(0)];
            _S888 = &points_8[int(3)];
            _S887 = &points_8[int(2)];
            _S886 = raydir_14;
            break;
        }
        if(_S891 != int(1))
        {
            _S885 = 0.0f;
            break;
        }
        float3  normal_9 = cross_0(*_S890 - *_S889, - (*_S888 - *_S887));
        float3  normal_10;
        if((dot_0(normal_9, normal_9)) != 0.0f)
        {
            normal_10 = normalize_0(normal_9);
        }
        else
        {
            normal_10 = normal_9;
        }
        float3  _S905;
        if((dot_0(gt_normal_2, gt_normal_2)) != 0.0f)
        {
            _S905 = normalize_0(gt_normal_2);
        }
        else
        {
            _S905 = gt_normal_2;
        }
        _S885 = (1.0f - dot_0(normal_10, _S905) + 0.00100000004749745f) / ((F32_max((dot_0(normal_10, - normalize_0(_S886))), (0.0f))) + 0.00100000004749745f);
        break;
    }
    return _S885;
}

struct s_bwd_prop_depth_normal_loss_Intermediates_1
{
    float2  _S906;
    bool _S907;
    float2  _S908;
    bool _S909;
    float2  _S910;
    bool _S911;
    float2  _S912;
    bool _S913;
    float2  _S914;
    bool _S915;
};

inline __device__ void depth_normal_loss_vjp_opencv(float2  pix_center_9, float4  intrins_15, FixedArray<float, 4>  dist_coeffs_19, int camera_model_17, bool is_ray_depth_15, float4  depths_7, float3  gt_normal_3, float v_loss_1, float4  * v_depths_3, float3  * v_gt_normal_1)
{
    float2  _S916 = make_float2 (0.0f);
    s_bwd_prop_depth_normal_loss_Intermediates_1 _S917;
    (&_S917)->_S906 = _S916;
    (&_S917)->_S907 = false;
    (&_S917)->_S908 = _S916;
    (&_S917)->_S909 = false;
    (&_S917)->_S910 = _S916;
    (&_S917)->_S911 = false;
    (&_S917)->_S912 = _S916;
    (&_S917)->_S913 = false;
    (&_S917)->_S914 = _S916;
    (&_S917)->_S915 = false;
    (&_S917)->_S908 = _S916;
    (&_S917)->_S909 = false;
    (&_S917)->_S910 = _S916;
    (&_S917)->_S911 = false;
    (&_S917)->_S912 = _S916;
    (&_S917)->_S913 = false;
    (&_S917)->_S914 = _S916;
    (&_S917)->_S915 = false;
    float2  _S918 = float2 {intrins_15.z, intrins_15.w};
    float2  _S919 = float2 {intrins_15.x, intrins_15.y};
    float2  uv_47 = (pix_center_9 + make_float2 (-1.0f, -0.0f) - _S918) / _S919;
    float2  _S920 = _S916;
    FixedArray<float, 4>  _S921 = dist_coeffs_19;
    bool _S922 = undistort_point_1(uv_47, &_S921, int(12), &_S920);
    (&_S917)->_S906 = _S920;
    (&_S917)->_S907 = _S922;
    bool _S923 = !!_S922;
    bool _runFlag_15;
    if(_S923)
    {
        float2  uv_48 = (pix_center_9 + make_float2 (1.0f, -0.0f) - _S918) / _S919;
        float2  _S924 = _S916;
        FixedArray<float, 4>  _S925 = dist_coeffs_19;
        bool _S926 = undistort_point_1(uv_48, &_S925, int(12), &_S924);
        (&_S917)->_S908 = _S924;
        (&_S917)->_S909 = _S926;
        if(!_S926)
        {
            _runFlag_15 = false;
        }
        else
        {
            _runFlag_15 = _S923;
        }
        if(_runFlag_15)
        {
            float2  uv_49 = (pix_center_9 + make_float2 (0.0f, -1.0f) - _S918) / _S919;
            float2  _S927 = _S916;
            FixedArray<float, 4>  _S928 = dist_coeffs_19;
            bool _S929 = undistort_point_1(uv_49, &_S928, int(12), &_S927);
            (&_S917)->_S910 = _S927;
            (&_S917)->_S911 = _S929;
            if(!_S929)
            {
                _runFlag_15 = false;
            }
            if(_runFlag_15)
            {
                float2  uv_50 = (pix_center_9 + make_float2 (0.0f, 1.0f) - _S918) / _S919;
                float2  _S930 = _S916;
                FixedArray<float, 4>  _S931 = dist_coeffs_19;
                bool _S932 = undistort_point_1(uv_50, &_S931, int(12), &_S930);
                (&_S917)->_S912 = _S930;
                (&_S917)->_S913 = _S932;
                if(!_S932)
                {
                    _runFlag_15 = false;
                }
                if(_runFlag_15)
                {
                    float2  uv_51 = (pix_center_9 - _S918) / _S919;
                    float2  _S933 = _S916;
                    FixedArray<float, 4>  _S934 = dist_coeffs_19;
                    bool _S935 = undistort_point_1(uv_51, &_S934, int(12), &_S933);
                    (&_S917)->_S914 = _S933;
                    (&_S917)->_S915 = _S935;
                }
            }
        }
    }
    s_bwd_prop_depth_normal_loss_Intermediates_1 _S936 = _S917;
    float3  _S937 = make_float3 (0.0f);
    bool _S938 = !!_S917._S907;
    bool _runFlag_16;
    bool _runFlag_17;
    bool _runFlag_18;
    int _S939;
    float3  raydir_15;
    float3  _S940;
    float3  _S941;
    float3  _S942;
    float3  _S943;
    FixedArray<float3 , 5>  points_9;
    if(_S938)
    {
        float3  _S944 = s_primal_ctx_unproject_raydir_0(_S936._S906, camera_model_17, is_ray_depth_15);
        float3  _S945 = make_float3 (depths_7.x) * _S944;
        if(!_S936._S909)
        {
            _runFlag_15 = false;
        }
        else
        {
            _runFlag_15 = _S938;
        }
        if(_runFlag_15)
        {
            float3  _S946 = s_primal_ctx_unproject_raydir_0(_S936._S908, camera_model_17, is_ray_depth_15);
            float3  _S947 = make_float3 (depths_7.y) * _S946;
            if(!_S936._S911)
            {
                _runFlag_16 = false;
            }
            else
            {
                _runFlag_16 = _runFlag_15;
            }
            if(_runFlag_16)
            {
                float3  _S948 = s_primal_ctx_unproject_raydir_0(_S936._S910, camera_model_17, is_ray_depth_15);
                float3  _S949 = make_float3 (depths_7.z) * _S948;
                if(!_S936._S913)
                {
                    _runFlag_17 = false;
                }
                else
                {
                    _runFlag_17 = _runFlag_16;
                }
                if(_runFlag_17)
                {
                    float3  _S950 = s_primal_ctx_unproject_raydir_0(_S936._S912, camera_model_17, is_ray_depth_15);
                    float3  _S951 = make_float3 (depths_7.w) * _S950;
                    if(!_S936._S915)
                    {
                        _runFlag_18 = false;
                    }
                    else
                    {
                        _runFlag_18 = _runFlag_17;
                    }
                    if(_runFlag_18)
                    {
                        float3  _S952 = s_primal_ctx_unproject_raydir_0(_S936._S914, camera_model_17, is_ray_depth_15);
                        _S939 = int(1);
                        raydir_15 = _S952;
                    }
                    else
                    {
                        _S939 = int(0);
                        raydir_15 = _S950;
                    }
                    points_9[int(0)] = _S945;
                    points_9[int(1)] = _S947;
                    points_9[int(2)] = _S949;
                    points_9[int(3)] = _S951;
                    points_9[int(4)] = _S937;
                    _S940 = _S950;
                }
                else
                {
                    _S939 = int(0);
                    raydir_15 = _S948;
                    points_9[int(0)] = _S945;
                    points_9[int(1)] = _S947;
                    points_9[int(2)] = _S949;
                    points_9[int(3)] = _S937;
                    points_9[int(4)] = _S937;
                    _S940 = _S937;
                }
                _S941 = _S948;
            }
            else
            {
                _S939 = int(0);
                raydir_15 = _S946;
                points_9[int(0)] = _S945;
                points_9[int(1)] = _S947;
                points_9[int(2)] = _S937;
                points_9[int(3)] = _S937;
                points_9[int(4)] = _S937;
                _runFlag_17 = false;
                _S940 = _S937;
                _S941 = _S937;
            }
            _S942 = _S946;
        }
        else
        {
            _S939 = int(0);
            raydir_15 = _S944;
            points_9[int(0)] = _S945;
            points_9[int(1)] = _S937;
            points_9[int(2)] = _S937;
            points_9[int(3)] = _S937;
            points_9[int(4)] = _S937;
            _runFlag_16 = false;
            _runFlag_17 = false;
            _S940 = _S937;
            _S941 = _S937;
            _S942 = _S937;
        }
        _S943 = _S944;
    }
    else
    {
        _S939 = int(0);
        points_9[int(0)] = _S937;
        points_9[int(1)] = _S937;
        points_9[int(2)] = _S937;
        points_9[int(3)] = _S937;
        points_9[int(4)] = _S937;
        _runFlag_15 = false;
        _runFlag_16 = false;
        _runFlag_17 = false;
        _S940 = _S937;
        _S941 = _S937;
        _S942 = _S937;
        _S943 = _S937;
    }
    bool _S953 = !(_S939 != int(1));
    bool _S954;
    float3  normal_11;
    float3  _S955;
    float3  _S956;
    float3  _S957;
    float3  _S958;
    float _S959;
    float _S960;
    float _S961;
    float _S962;
    if(_S953)
    {
        float3  dx_4 = points_9[int(1)] - points_9[int(0)];
        float3  _S963 = - (points_9[int(3)] - points_9[int(2)]);
        float3  _S964 = s_primal_ctx_cross_0(dx_4, _S963);
        bool _S965 = (s_primal_ctx_dot_0(_S964, _S964)) != 0.0f;
        if(_S965)
        {
            normal_11 = normalize_0(_S964);
        }
        else
        {
            normal_11 = _S964;
        }
        bool _S966 = (s_primal_ctx_dot_0(gt_normal_3, gt_normal_3)) != 0.0f;
        if(_S966)
        {
            _S955 = normalize_0(gt_normal_3);
        }
        else
        {
            _S955 = gt_normal_3;
        }
        float3  _S967 = - normalize_0(raydir_15);
        float _S968 = s_primal_ctx_dot_0(normal_11, _S967);
        float _S969 = 1.0f - s_primal_ctx_dot_0(normal_11, _S955) + 0.00100000004749745f;
        float _S970 = (F32_max((_S968), (0.0f))) + 0.00100000004749745f;
        _S959 = _S970 * _S970;
        _S960 = _S969;
        _S961 = _S970;
        _S962 = _S968;
        raydir_15 = normal_11;
        normal_11 = _S967;
        _runFlag_18 = _S966;
        _S954 = _S965;
        _S956 = _S964;
        _S957 = dx_4;
        _S958 = _S963;
    }
    else
    {
        _S959 = 0.0f;
        _S960 = 0.0f;
        _S961 = 0.0f;
        _S962 = 0.0f;
        raydir_15 = _S937;
        normal_11 = _S937;
        _S955 = _S937;
        _runFlag_18 = false;
        _S954 = false;
        _S956 = _S937;
        _S957 = _S937;
        _S958 = _S937;
    }
    float4  _S971 = make_float4 (0.0f);
    if(_S953)
    {
        float _S972 = v_loss_1 / _S959;
        float _S973 = _S960 * - _S972;
        float s_diff_num_T_1 = _S961 * _S972;
        DiffPair_float_0 _S974;
        (&_S974)->primal_0 = _S962;
        (&_S974)->differential_0 = 0.0f;
        DiffPair_float_0 _S975;
        (&_S975)->primal_0 = 0.0f;
        (&_S975)->differential_0 = 0.0f;
        _d_max_0(&_S974, &_S975, _S973);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S976;
        (&_S976)->primal_0 = raydir_15;
        (&_S976)->differential_0 = _S937;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S977;
        (&_S977)->primal_0 = normal_11;
        (&_S977)->differential_0 = _S937;
        s_bwd_prop_dot_0(&_S976, &_S977, _S974.differential_0);
        float _S978 = - s_diff_num_T_1;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S979;
        (&_S979)->primal_0 = raydir_15;
        (&_S979)->differential_0 = _S937;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S980;
        (&_S980)->primal_0 = _S955;
        (&_S980)->differential_0 = _S937;
        s_bwd_prop_dot_0(&_S979, &_S980, _S978);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S981 = _S980;
        float3  _S982 = _S976.differential_0 + _S979.differential_0;
        if(_runFlag_18)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S983;
            (&_S983)->primal_0 = gt_normal_3;
            (&_S983)->differential_0 = _S937;
            s_bwd_normalize_impl_0(&_S983, _S981.differential_0);
            raydir_15 = _S983.differential_0;
        }
        else
        {
            raydir_15 = _S981.differential_0;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S984;
        (&_S984)->primal_0 = gt_normal_3;
        (&_S984)->differential_0 = _S937;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S985;
        (&_S985)->primal_0 = gt_normal_3;
        (&_S985)->differential_0 = _S937;
        s_bwd_prop_dot_0(&_S984, &_S985, 0.0f);
        float3  _S986 = _S985.differential_0 + _S984.differential_0 + raydir_15;
        if(_S954)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S987;
            (&_S987)->primal_0 = _S956;
            (&_S987)->differential_0 = _S937;
            s_bwd_normalize_impl_0(&_S987, _S982);
            raydir_15 = _S987.differential_0;
        }
        else
        {
            raydir_15 = _S982;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S988;
        (&_S988)->primal_0 = _S956;
        (&_S988)->differential_0 = _S937;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S989;
        (&_S989)->primal_0 = _S956;
        (&_S989)->differential_0 = _S937;
        s_bwd_prop_dot_0(&_S988, &_S989, 0.0f);
        float3  _S990 = _S989.differential_0 + _S988.differential_0 + raydir_15;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S991;
        (&_S991)->primal_0 = _S957;
        (&_S991)->differential_0 = _S937;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S992;
        (&_S992)->primal_0 = _S958;
        (&_S992)->differential_0 = _S937;
        s_bwd_prop_cross_0(&_S991, &_S992, _S990);
        float3  s_diff_dy_T_4 = - _S992.differential_0;
        float3  _S993 = - s_diff_dy_T_4;
        float3  _S994 = - _S991.differential_0;
        FixedArray<float3 , 5>  _S995;
        _S995[int(0)] = _S937;
        _S995[int(1)] = _S937;
        _S995[int(2)] = _S937;
        _S995[int(3)] = _S937;
        _S995[int(4)] = _S937;
        _S995[int(2)] = _S993;
        _S995[int(3)] = s_diff_dy_T_4;
        _S995[int(0)] = _S994;
        _S995[int(1)] = _S991.differential_0;
        points_9[int(0)] = _S995[int(0)];
        points_9[int(1)] = _S995[int(1)];
        points_9[int(2)] = _S995[int(2)];
        points_9[int(3)] = _S995[int(3)];
        points_9[int(4)] = _S995[int(4)];
        raydir_15 = _S986;
    }
    else
    {
        points_9[int(0)] = _S937;
        points_9[int(1)] = _S937;
        points_9[int(2)] = _S937;
        points_9[int(3)] = _S937;
        points_9[int(4)] = _S937;
        raydir_15 = _S937;
    }
    float4  _S996;
    if(_S938)
    {
        if(_runFlag_15)
        {
            if(_runFlag_16)
            {
                if(_runFlag_17)
                {
                    FixedArray<float3 , 5>  _S997 = points_9;
                    FixedArray<float3 , 5>  _S998 = points_9;
                    FixedArray<float3 , 5>  _S999 = points_9;
                    float3  _S1000 = _S940 * points_9[int(3)];
                    float _S1001 = _S1000.x + _S1000.y + _S1000.z;
                    float4  _S1002 = _S971;
                    *&((&_S1002)->w) = _S1001;
                    points_9[int(0)] = _S937;
                    points_9[int(1)] = _S937;
                    points_9[int(2)] = _S937;
                    points_9[int(3)] = _S937;
                    points_9[int(4)] = _S937;
                    _S940 = _S999[int(2)];
                    normal_11 = _S997[int(0)];
                    _S955 = _S998[int(1)];
                    _S996 = _S1002;
                }
                else
                {
                    FixedArray<float3 , 5>  _S1003 = points_9;
                    FixedArray<float3 , 5>  _S1004 = points_9;
                    FixedArray<float3 , 5>  _S1005 = points_9;
                    FixedArray<float3 , 5>  _S1006 = points_9;
                    points_9[int(0)] = points_9[int(0)];
                    points_9[int(1)] = _S1003[int(1)];
                    points_9[int(2)] = _S1004[int(2)];
                    points_9[int(3)] = _S1005[int(3)];
                    points_9[int(4)] = _S1006[int(4)];
                    _S940 = _S937;
                    normal_11 = _S937;
                    _S955 = _S937;
                    _S996 = _S971;
                }
                float3  _S1007 = _S941 * (points_9[int(2)] + _S940);
                float _S1008 = _S1007.x + _S1007.y + _S1007.z;
                float3  _S1009 = points_9[int(0)] + normal_11;
                float3  _S1010 = points_9[int(1)] + _S955;
                float4  _S1011 = _S971;
                *&((&_S1011)->z) = _S1008;
                float4  _S1012 = _S996 + _S1011;
                points_9[int(0)] = _S937;
                points_9[int(1)] = _S937;
                points_9[int(2)] = _S937;
                points_9[int(3)] = _S937;
                points_9[int(4)] = _S937;
                _S940 = _S1010;
                _S941 = _S1009;
                _S996 = _S1012;
            }
            else
            {
                FixedArray<float3 , 5>  _S1013 = points_9;
                FixedArray<float3 , 5>  _S1014 = points_9;
                FixedArray<float3 , 5>  _S1015 = points_9;
                FixedArray<float3 , 5>  _S1016 = points_9;
                points_9[int(0)] = points_9[int(0)];
                points_9[int(1)] = _S1013[int(1)];
                points_9[int(2)] = _S1014[int(2)];
                points_9[int(3)] = _S1015[int(3)];
                points_9[int(4)] = _S1016[int(4)];
                _S940 = _S937;
                _S941 = _S937;
                _S996 = _S971;
            }
            float3  _S1017 = _S942 * (points_9[int(1)] + _S940);
            float _S1018 = _S1017.x + _S1017.y + _S1017.z;
            float3  _S1019 = points_9[int(0)] + _S941;
            float4  _S1020 = _S971;
            *&((&_S1020)->y) = _S1018;
            float4  _S1021 = _S996 + _S1020;
            points_9[int(0)] = _S937;
            points_9[int(1)] = _S937;
            points_9[int(2)] = _S937;
            points_9[int(3)] = _S937;
            points_9[int(4)] = _S937;
            _S940 = _S1019;
            _S996 = _S1021;
        }
        else
        {
            FixedArray<float3 , 5>  _S1022 = points_9;
            FixedArray<float3 , 5>  _S1023 = points_9;
            FixedArray<float3 , 5>  _S1024 = points_9;
            FixedArray<float3 , 5>  _S1025 = points_9;
            points_9[int(0)] = points_9[int(0)];
            points_9[int(1)] = _S1022[int(1)];
            points_9[int(2)] = _S1023[int(2)];
            points_9[int(3)] = _S1024[int(3)];
            points_9[int(4)] = _S1025[int(4)];
            _S940 = _S937;
            _S996 = _S971;
        }
        float3  _S1026 = _S943 * (points_9[int(0)] + _S940);
        float _S1027 = _S1026.x + _S1026.y + _S1026.z;
        float4  _S1028 = _S971;
        *&((&_S1028)->x) = _S1027;
        _S996 = _S996 + _S1028;
    }
    else
    {
        _S996 = _S971;
    }
    *v_depths_3 = _S996;
    *v_gt_normal_1 = raydir_15;
    return;
}

inline __device__ float3  generate_ray_d2n_prism(float2  pix_pos_6, float4  intrins_16, FixedArray<float, 8>  dist_coeffs_20, int camera_model_18, bool is_ray_depth_16)
{
    float3  _S1029;
    for(;;)
    {
        float2  uv_52 = (pix_pos_6 - float2 {intrins_16.z, intrins_16.w}) / float2 {intrins_16.x, intrins_16.y};
        FixedArray<float, 8>  _S1030 = dist_coeffs_20;
        float2  uv_u_24;
        bool _S1031 = undistort_point_2(uv_52, &_S1030, int(12), &uv_u_24);
        if(!_S1031)
        {
            int3  _S1032 = make_int3 (int(0));
            float3  _S1033 = make_float3 ((float)_S1032.x, (float)_S1032.y, (float)_S1032.z);
            _S1029 = _S1033;
            break;
        }
        _S1029 = unproject_raydir_0(uv_u_24, camera_model_18, is_ray_depth_16);
        break;
    }
    return _S1029;
}

inline __device__ float3  depth_to_point_prism(float2  pix_pos_7, float4  intrins_17, FixedArray<float, 8>  dist_coeffs_21, int camera_model_19, bool is_ray_depth_17, float depth_6)
{
    float3  _S1034;
    for(;;)
    {
        float2  uv_53 = (pix_pos_7 - float2 {intrins_17.z, intrins_17.w}) / float2 {intrins_17.x, intrins_17.y};
        FixedArray<float, 8>  _S1035 = dist_coeffs_21;
        float2  uv_u_25;
        bool _S1036 = undistort_point_2(uv_53, &_S1035, int(12), &uv_u_25);
        if(!_S1036)
        {
            _S1034 = make_float3 (0.0f);
            break;
        }
        _S1034 = make_float3 (depth_6) * unproject_raydir_0(uv_u_25, camera_model_19, is_ray_depth_17);
        break;
    }
    return _S1034;
}

struct s_bwd_prop_depth_to_point_Intermediates_2
{
    float2  _S1037;
    bool _S1038;
};

inline __device__ float depth_to_point_vjp_prism(float2  pix_pos_8, float4  intrins_18, FixedArray<float, 8>  dist_coeffs_22, int camera_model_20, bool is_ray_depth_18, float depth_7, float3  v_point_2)
{
    float2  _S1039 = make_float2 (0.0f);
    s_bwd_prop_depth_to_point_Intermediates_2 _S1040;
    (&_S1040)->_S1037 = _S1039;
    (&_S1040)->_S1038 = false;
    float2  uv_54 = (pix_pos_8 - float2 {intrins_18.z, intrins_18.w}) / float2 {intrins_18.x, intrins_18.y};
    float2  _S1041 = _S1039;
    FixedArray<float, 8>  _S1042 = dist_coeffs_22;
    bool _S1043 = undistort_point_2(uv_54, &_S1042, int(12), &_S1041);
    (&_S1040)->_S1037 = _S1041;
    (&_S1040)->_S1038 = _S1043;
    s_bwd_prop_depth_to_point_Intermediates_2 _S1044 = _S1040;
    float3  _S1045 = make_float3 (0.0f);
    bool _S1046 = !!_S1040._S1038;
    float3  _S1047;
    if(_S1046)
    {
        _S1047 = s_primal_ctx_unproject_raydir_0(_S1044._S1037, camera_model_20, is_ray_depth_18);
    }
    else
    {
        _S1047 = _S1045;
    }
    if(_S1046)
    {
        _S1047 = _S1047 * v_point_2;
    }
    else
    {
        _S1047 = _S1045;
    }
    return _S1047.x + _S1047.y + _S1047.z;
}

inline __device__ float3  depth_to_normal_prism(float2  pix_center_10, float4  intrins_19, FixedArray<float, 8>  dist_coeffs_23, int camera_model_21, bool is_ray_depth_19, float4  depths_8)
{
    float3  normal_12;
    for(;;)
    {
        bool _S1048;
        if((depths_8.x) == 0.0f)
        {
            _S1048 = true;
        }
        else
        {
            _S1048 = (depths_8.y) == 0.0f;
        }
        if(_S1048)
        {
            _S1048 = true;
        }
        else
        {
            _S1048 = (depths_8.z) == 0.0f;
        }
        if(_S1048)
        {
            _S1048 = true;
        }
        else
        {
            _S1048 = (depths_8.w) == 0.0f;
        }
        if(_S1048)
        {
            normal_12 = make_float3 (0.0f);
            break;
        }
        float3  * _S1049;
        float3  * _S1050;
        float3  * _S1051;
        float3  * _S1052;
        int _S1053;
        FixedArray<float3 , 4>  points_10;
        for(;;)
        {
            float2  _S1054 = float2 {intrins_19.z, intrins_19.w};
            float2  _S1055 = float2 {intrins_19.x, intrins_19.y};
            float2  uv_55 = (pix_center_10 + make_float2 (-1.0f, -0.0f) - _S1054) / _S1055;
            FixedArray<float, 8>  _S1056 = dist_coeffs_23;
            float2  uv_u_26;
            bool _S1057 = undistort_point_2(uv_55, &_S1056, int(12), &uv_u_26);
            if(!_S1057)
            {
                float3  _S1058 = make_float3 (0.0f);
                _S1053 = int(0);
                _S1052 = nullptr;
                _S1051 = nullptr;
                _S1050 = nullptr;
                _S1049 = nullptr;
                normal_12 = _S1058;
                break;
            }
            points_10[int(0)] = make_float3 (depths_8.x) * unproject_raydir_0(uv_u_26, camera_model_21, is_ray_depth_19);
            for(;;)
            {
                float2  uv_56 = (pix_center_10 + make_float2 (1.0f, -0.0f) - _S1054) / _S1055;
                FixedArray<float, 8>  _S1059 = dist_coeffs_23;
                float2  uv_u_27;
                bool _S1060 = undistort_point_2(uv_56, &_S1059, int(12), &uv_u_27);
                if(!_S1060)
                {
                    float3  _S1061 = make_float3 (0.0f);
                    _S1053 = int(0);
                    _S1052 = nullptr;
                    normal_12 = _S1061;
                    break;
                }
                points_10[int(1)] = make_float3 (depths_8.y) * unproject_raydir_0(uv_u_27, camera_model_21, is_ray_depth_19);
                _S1053 = int(2);
                _S1052 = &points_10[int(1)];
                break;
            }
            if(_S1053 != int(2))
            {
                _S1051 = &points_10[int(0)];
                _S1050 = nullptr;
                _S1049 = nullptr;
                break;
            }
            float2  uv_57 = (pix_center_10 + make_float2 (0.0f, -1.0f) - _S1054) / _S1055;
            FixedArray<float, 8>  _S1062 = dist_coeffs_23;
            float2  uv_u_28;
            bool _S1063 = undistort_point_2(uv_57, &_S1062, int(12), &uv_u_28);
            if(!_S1063)
            {
                float3  _S1064 = make_float3 (0.0f);
                _S1053 = int(0);
                _S1051 = &points_10[int(0)];
                _S1050 = nullptr;
                _S1049 = nullptr;
                normal_12 = _S1064;
                break;
            }
            points_10[int(2)] = make_float3 (depths_8.z) * unproject_raydir_0(uv_u_28, camera_model_21, is_ray_depth_19);
            for(;;)
            {
                float2  uv_58 = (pix_center_10 + make_float2 (0.0f, 1.0f) - _S1054) / _S1055;
                FixedArray<float, 8>  _S1065 = dist_coeffs_23;
                float2  uv_u_29;
                bool _S1066 = undistort_point_2(uv_58, &_S1065, int(12), &uv_u_29);
                if(!_S1066)
                {
                    float3  _S1067 = make_float3 (0.0f);
                    _S1053 = int(0);
                    _S1051 = nullptr;
                    normal_12 = _S1067;
                    break;
                }
                points_10[int(3)] = make_float3 (depths_8.w) * unproject_raydir_0(uv_u_29, camera_model_21, is_ray_depth_19);
                _S1053 = int(2);
                _S1051 = &points_10[int(3)];
                break;
            }
            if(_S1053 != int(2))
            {
                float3  * _S1068 = _S1051;
                _S1051 = &points_10[int(0)];
                _S1050 = _S1068;
                _S1049 = &points_10[int(2)];
                break;
            }
            float3  * _S1069 = _S1051;
            _S1053 = int(1);
            _S1051 = &points_10[int(0)];
            _S1050 = _S1069;
            _S1049 = &points_10[int(2)];
            break;
        }
        if(_S1053 != int(1))
        {
            break;
        }
        float3  normal_13 = cross_0(*_S1052 - *_S1051, - (*_S1050 - *_S1049));
        if((dot_0(normal_13, normal_13)) != 0.0f)
        {
            normal_12 = normal_13 / make_float3 (length_0(normal_13));
        }
        else
        {
            normal_12 = normal_13;
        }
        break;
    }
    return normal_12;
}

struct s_bwd_prop_depth_to_normal_Intermediates_2
{
    float2  _S1070;
    bool _S1071;
    float2  _S1072;
    bool _S1073;
    float2  _S1074;
    bool _S1075;
    float2  _S1076;
    bool _S1077;
};

inline __device__ void depth_to_normal_vjp_prism(float2  pix_center_11, float4  intrins_20, FixedArray<float, 8>  dist_coeffs_24, int camera_model_22, bool is_ray_depth_20, float4  depths_9, float3  v_normal_3, float4  * v_depths_4)
{
    float2  _S1078 = make_float2 (0.0f);
    s_bwd_prop_depth_to_normal_Intermediates_2 _S1079;
    (&_S1079)->_S1070 = _S1078;
    (&_S1079)->_S1071 = false;
    (&_S1079)->_S1072 = _S1078;
    (&_S1079)->_S1073 = false;
    (&_S1079)->_S1074 = _S1078;
    (&_S1079)->_S1075 = false;
    (&_S1079)->_S1076 = _S1078;
    (&_S1079)->_S1077 = false;
    (&_S1079)->_S1070 = _S1078;
    (&_S1079)->_S1071 = false;
    (&_S1079)->_S1072 = _S1078;
    (&_S1079)->_S1073 = false;
    (&_S1079)->_S1074 = _S1078;
    (&_S1079)->_S1075 = false;
    (&_S1079)->_S1076 = _S1078;
    (&_S1079)->_S1077 = false;
    bool _S1080 = (depths_9.x) == 0.0f;
    bool _runFlag_19;
    if(_S1080)
    {
        _runFlag_19 = true;
    }
    else
    {
        _runFlag_19 = (depths_9.y) == 0.0f;
    }
    if(_runFlag_19)
    {
        _runFlag_19 = true;
    }
    else
    {
        _runFlag_19 = (depths_9.z) == 0.0f;
    }
    if(_runFlag_19)
    {
        _runFlag_19 = true;
    }
    else
    {
        _runFlag_19 = (depths_9.w) == 0.0f;
    }
    int _S1081;
    if(!_runFlag_19)
    {
        float2  _S1082 = float2 {intrins_20.z, intrins_20.w};
        float2  _S1083 = float2 {intrins_20.x, intrins_20.y};
        float2  uv_59 = (pix_center_11 + make_float2 (-1.0f, -0.0f) - _S1082) / _S1083;
        float2  _S1084 = _S1078;
        FixedArray<float, 8>  _S1085 = dist_coeffs_24;
        bool _S1086 = undistort_point_2(uv_59, &_S1085, int(12), &_S1084);
        (&_S1079)->_S1070 = _S1084;
        (&_S1079)->_S1071 = _S1086;
        bool _S1087 = !!_S1086;
        if(_S1087)
        {
            float2  uv_60 = (pix_center_11 + make_float2 (1.0f, -0.0f) - _S1082) / _S1083;
            float2  _S1088 = _S1078;
            FixedArray<float, 8>  _S1089 = dist_coeffs_24;
            bool _S1090 = undistort_point_2(uv_60, &_S1089, int(12), &_S1088);
            (&_S1079)->_S1072 = _S1088;
            (&_S1079)->_S1073 = _S1090;
            if(!!_S1090)
            {
                _S1081 = int(2);
            }
            else
            {
                _S1081 = int(0);
            }
            if(_S1081 != int(2))
            {
                _runFlag_19 = false;
            }
            else
            {
                _runFlag_19 = _S1087;
            }
            if(_runFlag_19)
            {
                float2  uv_61 = (pix_center_11 + make_float2 (0.0f, -1.0f) - _S1082) / _S1083;
                float2  _S1091 = _S1078;
                FixedArray<float, 8>  _S1092 = dist_coeffs_24;
                bool _S1093 = undistort_point_2(uv_61, &_S1092, int(12), &_S1091);
                (&_S1079)->_S1074 = _S1091;
                (&_S1079)->_S1075 = _S1093;
                if(!_S1093)
                {
                    _runFlag_19 = false;
                }
                if(_runFlag_19)
                {
                    float2  uv_62 = (pix_center_11 + make_float2 (0.0f, 1.0f) - _S1082) / _S1083;
                    float2  _S1094 = _S1078;
                    FixedArray<float, 8>  _S1095 = dist_coeffs_24;
                    bool _S1096 = undistort_point_2(uv_62, &_S1095, int(12), &_S1094);
                    (&_S1079)->_S1076 = _S1094;
                    (&_S1079)->_S1077 = _S1096;
                }
            }
        }
    }
    s_bwd_prop_depth_to_normal_Intermediates_2 _S1097 = _S1079;
    float3  _S1098 = make_float3 (0.0f);
    if(_S1080)
    {
        _runFlag_19 = true;
    }
    else
    {
        _runFlag_19 = (depths_9.y) == 0.0f;
    }
    if(_runFlag_19)
    {
        _runFlag_19 = true;
    }
    else
    {
        _runFlag_19 = (depths_9.z) == 0.0f;
    }
    if(_runFlag_19)
    {
        _runFlag_19 = true;
    }
    else
    {
        _runFlag_19 = (depths_9.w) == 0.0f;
    }
    bool _S1099 = !_runFlag_19;
    bool _runFlag_20;
    bool _runFlag_21;
    bool _S1100;
    bool _runFlag_22;
    bool _S1101;
    bool _S1102;
    FixedArray<float3 , 4>  points_11;
    float3  _S1103;
    float3  _S1104;
    float3  _S1105;
    float3  _S1106;
    float3  _S1107;
    float3  _S1108;
    float3  _S1109;
    float3  _S1110;
    float3  _S1111;
    if(_S1099)
    {
        bool _S1112 = !!_S1097._S1071;
        if(_S1112)
        {
            float3  _S1113 = s_primal_ctx_unproject_raydir_0(_S1097._S1070, camera_model_22, is_ray_depth_20);
            float3  _S1114 = make_float3 (depths_9.x) * _S1113;
            bool _S1115 = !!_S1097._S1073;
            if(_S1115)
            {
                float3  _S1116 = s_primal_ctx_unproject_raydir_0(_S1097._S1072, camera_model_22, is_ray_depth_20);
                float3  _S1117 = make_float3 (depths_9.y) * _S1116;
                _S1081 = int(2);
                points_11[int(0)] = _S1114;
                points_11[int(1)] = _S1117;
                points_11[int(2)] = _S1098;
                points_11[int(3)] = _S1098;
                _S1103 = _S1116;
            }
            else
            {
                _S1081 = int(0);
                points_11[int(0)] = _S1114;
                points_11[int(1)] = _S1098;
                points_11[int(2)] = _S1098;
                points_11[int(3)] = _S1098;
                _S1103 = _S1098;
            }
            if(_S1081 != int(2))
            {
                _runFlag_19 = false;
            }
            else
            {
                _runFlag_19 = _S1112;
                _S1081 = int(0);
            }
            if(_runFlag_19)
            {
                if(!_S1097._S1075)
                {
                    _runFlag_20 = false;
                    _S1081 = int(0);
                }
                else
                {
                    _runFlag_20 = _runFlag_19;
                }
                if(_runFlag_20)
                {
                    float3  _S1118 = s_primal_ctx_unproject_raydir_0(_S1097._S1074, camera_model_22, is_ray_depth_20);
                    points_11[int(2)] = make_float3 (depths_9.z) * _S1118;
                    bool _S1119 = !!_S1097._S1077;
                    int _S1120;
                    if(_S1119)
                    {
                        float3  _S1121 = s_primal_ctx_unproject_raydir_0(_S1097._S1076, camera_model_22, is_ray_depth_20);
                        points_11[int(3)] = make_float3 (depths_9.w) * _S1121;
                        _S1120 = int(2);
                        _S1104 = _S1121;
                    }
                    else
                    {
                        _S1120 = int(0);
                        _S1104 = _S1098;
                    }
                    if(_S1120 != int(2))
                    {
                        _runFlag_21 = false;
                        _S1081 = _S1120;
                    }
                    else
                    {
                        _runFlag_21 = _runFlag_20;
                    }
                    if(_runFlag_21)
                    {
                        _S1081 = int(1);
                    }
                    _runFlag_21 = _S1119;
                    _S1105 = _S1118;
                }
                else
                {
                    _runFlag_21 = false;
                    _S1104 = _S1098;
                    _S1105 = _S1098;
                }
            }
            else
            {
                _runFlag_20 = false;
                _runFlag_21 = false;
                _S1104 = _S1098;
                _S1105 = _S1098;
            }
            float3  _S1122 = _S1103;
            _S1103 = _S1104;
            _S1104 = _S1105;
            _S1100 = _S1115;
            _S1105 = _S1122;
            _S1106 = _S1113;
        }
        else
        {
            _S1081 = int(0);
            points_11[int(0)] = _S1098;
            points_11[int(1)] = _S1098;
            points_11[int(2)] = _S1098;
            points_11[int(3)] = _S1098;
            _runFlag_19 = false;
            _runFlag_20 = false;
            _runFlag_21 = false;
            _S1103 = _S1098;
            _S1104 = _S1098;
            _S1100 = false;
            _S1105 = _S1098;
            _S1106 = _S1098;
        }
        if(_S1081 != int(1))
        {
            _runFlag_22 = false;
        }
        else
        {
            _runFlag_22 = _S1099;
        }
        if(_runFlag_22)
        {
            float3  dx_5 = points_11[int(1)] - points_11[int(0)];
            float3  _S1123 = - (points_11[int(3)] - points_11[int(2)]);
            float3  _S1124 = s_primal_ctx_cross_0(dx_5, _S1123);
            bool _S1125 = (s_primal_ctx_dot_0(_S1124, _S1124)) != 0.0f;
            if(_S1125)
            {
                float _S1126 = length_0(_S1124);
                float3  _S1127 = make_float3 (_S1126);
                _S1107 = make_float3 (_S1126 * _S1126);
                _S1108 = _S1127;
            }
            else
            {
                _S1107 = _S1098;
                _S1108 = _S1098;
            }
            float3  _S1128 = _S1108;
            _S1101 = _S1125;
            _S1108 = _S1124;
            _S1109 = _S1128;
            _S1110 = dx_5;
            _S1111 = _S1123;
        }
        else
        {
            _S1101 = false;
            _S1107 = _S1098;
            _S1108 = _S1098;
            _S1109 = _S1098;
            _S1110 = _S1098;
            _S1111 = _S1098;
        }
        bool _S1129 = _runFlag_19;
        bool _S1130 = _runFlag_20;
        bool _S1131 = _runFlag_21;
        float3  _S1132 = _S1103;
        float3  _S1133 = _S1104;
        bool _S1134 = _S1100;
        float3  _S1135 = _S1105;
        float3  _S1136 = _S1106;
        _runFlag_19 = _runFlag_22;
        _runFlag_20 = _S1101;
        _S1103 = _S1107;
        _S1104 = _S1108;
        _S1105 = _S1109;
        _S1106 = _S1110;
        _S1107 = _S1111;
        _runFlag_21 = _S1112;
        _S1100 = _S1129;
        _runFlag_22 = _S1130;
        _S1101 = _S1131;
        _S1108 = _S1132;
        _S1109 = _S1133;
        _S1102 = _S1134;
        _S1110 = _S1135;
        _S1111 = _S1136;
    }
    else
    {
        _runFlag_19 = false;
        _runFlag_20 = false;
        _S1103 = _S1098;
        _S1104 = _S1098;
        _S1105 = _S1098;
        _S1106 = _S1098;
        _S1107 = _S1098;
        _runFlag_21 = false;
        _S1100 = false;
        _runFlag_22 = false;
        _S1101 = false;
        _S1108 = _S1098;
        _S1109 = _S1098;
        _S1102 = false;
        _S1110 = _S1098;
        _S1111 = _S1098;
    }
    float4  _S1137 = make_float4 (0.0f);
    float4  _S1138;
    if(_S1099)
    {
        if(_runFlag_19)
        {
            if(_runFlag_20)
            {
                float3  _S1139 = v_normal_3 / _S1103;
                float3  _S1140 = _S1104 * - _S1139;
                float3  _S1141 = _S1105 * _S1139;
                float _S1142 = _S1140.x + _S1140.y + _S1140.z;
                DiffPair_vectorx3Cfloatx2C3x3E_0 _S1143;
                (&_S1143)->primal_0 = _S1104;
                (&_S1143)->differential_0 = _S1098;
                s_bwd_length_impl_0(&_S1143, _S1142);
                _S1103 = _S1141 + _S1143.differential_0;
            }
            else
            {
                _S1103 = v_normal_3;
            }
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1144;
            (&_S1144)->primal_0 = _S1104;
            (&_S1144)->differential_0 = _S1098;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1145;
            (&_S1145)->primal_0 = _S1104;
            (&_S1145)->differential_0 = _S1098;
            s_bwd_prop_dot_0(&_S1144, &_S1145, 0.0f);
            float3  _S1146 = _S1145.differential_0 + _S1144.differential_0 + _S1103;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1147;
            (&_S1147)->primal_0 = _S1106;
            (&_S1147)->differential_0 = _S1098;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1148;
            (&_S1148)->primal_0 = _S1107;
            (&_S1148)->differential_0 = _S1098;
            s_bwd_prop_cross_0(&_S1147, &_S1148, _S1146);
            float3  s_diff_dy_T_5 = - _S1148.differential_0;
            float3  _S1149 = - s_diff_dy_T_5;
            float3  _S1150 = - _S1147.differential_0;
            FixedArray<float3 , 4>  _S1151;
            _S1151[int(0)] = _S1098;
            _S1151[int(1)] = _S1098;
            _S1151[int(2)] = _S1098;
            _S1151[int(3)] = _S1098;
            _S1151[int(2)] = _S1149;
            _S1151[int(3)] = s_diff_dy_T_5;
            _S1151[int(0)] = _S1150;
            _S1151[int(1)] = _S1147.differential_0;
            points_11[int(0)] = _S1151[int(0)];
            points_11[int(1)] = _S1151[int(1)];
            points_11[int(2)] = _S1151[int(2)];
            points_11[int(3)] = _S1151[int(3)];
        }
        else
        {
            points_11[int(0)] = _S1098;
            points_11[int(1)] = _S1098;
            points_11[int(2)] = _S1098;
            points_11[int(3)] = _S1098;
        }
        if(_runFlag_21)
        {
            if(_S1100)
            {
                if(_runFlag_22)
                {
                    FixedArray<float3 , 4>  _S1152 = points_11;
                    FixedArray<float3 , 4>  _S1153 = points_11;
                    FixedArray<float3 , 4>  _S1154 = points_11;
                    FixedArray<float3 , 4>  _S1155 = points_11;
                    if(_S1101)
                    {
                        float3  _S1156 = _S1108 * _S1155[int(3)];
                        float _S1157 = _S1156.x + _S1156.y + _S1156.z;
                        float4  _S1158 = _S1137;
                        *&((&_S1158)->w) = _S1157;
                        points_11[int(0)] = _S1152[int(0)];
                        points_11[int(1)] = _S1153[int(1)];
                        points_11[int(2)] = _S1154[int(2)];
                        points_11[int(3)] = _S1098;
                        _S1138 = _S1158;
                    }
                    else
                    {
                        points_11[int(0)] = _S1152[int(0)];
                        points_11[int(1)] = _S1153[int(1)];
                        points_11[int(2)] = _S1154[int(2)];
                        points_11[int(3)] = _S1155[int(3)];
                        _S1138 = _S1137;
                    }
                    float3  _S1159 = _S1109 * points_11[int(2)];
                    float _S1160 = _S1159.x + _S1159.y + _S1159.z;
                    FixedArray<float3 , 4>  _S1161 = points_11;
                    FixedArray<float3 , 4>  _S1162 = points_11;
                    float4  _S1163 = _S1137;
                    *&((&_S1163)->z) = _S1160;
                    float4  _S1164 = _S1138 + _S1163;
                    points_11[int(0)] = points_11[int(0)];
                    points_11[int(1)] = _S1161[int(1)];
                    points_11[int(2)] = _S1098;
                    points_11[int(3)] = _S1162[int(3)];
                    _S1138 = _S1164;
                }
                else
                {
                    FixedArray<float3 , 4>  _S1165 = points_11;
                    FixedArray<float3 , 4>  _S1166 = points_11;
                    FixedArray<float3 , 4>  _S1167 = points_11;
                    points_11[int(0)] = points_11[int(0)];
                    points_11[int(1)] = _S1165[int(1)];
                    points_11[int(2)] = _S1166[int(2)];
                    points_11[int(3)] = _S1167[int(3)];
                    _S1138 = _S1137;
                }
            }
            else
            {
                FixedArray<float3 , 4>  _S1168 = points_11;
                FixedArray<float3 , 4>  _S1169 = points_11;
                FixedArray<float3 , 4>  _S1170 = points_11;
                points_11[int(0)] = points_11[int(0)];
                points_11[int(1)] = _S1168[int(1)];
                points_11[int(2)] = _S1169[int(2)];
                points_11[int(3)] = _S1170[int(3)];
                _S1138 = _S1137;
            }
            if(_S1102)
            {
                FixedArray<float3 , 4>  _S1171 = points_11;
                float3  _S1172 = _S1110 * points_11[int(1)];
                float _S1173 = _S1172.x + _S1172.y + _S1172.z;
                float4  _S1174 = _S1137;
                *&((&_S1174)->y) = _S1173;
                float4  _S1175 = _S1138 + _S1174;
                points_11[int(0)] = _S1098;
                points_11[int(1)] = _S1098;
                points_11[int(2)] = _S1098;
                points_11[int(3)] = _S1098;
                _S1103 = _S1171[int(0)];
                _S1138 = _S1175;
            }
            else
            {
                FixedArray<float3 , 4>  _S1176 = points_11;
                FixedArray<float3 , 4>  _S1177 = points_11;
                FixedArray<float3 , 4>  _S1178 = points_11;
                points_11[int(0)] = points_11[int(0)];
                points_11[int(1)] = _S1176[int(1)];
                points_11[int(2)] = _S1177[int(2)];
                points_11[int(3)] = _S1178[int(3)];
                _S1103 = _S1098;
            }
            float3  _S1179 = _S1111 * (points_11[int(0)] + _S1103);
            float _S1180 = _S1179.x + _S1179.y + _S1179.z;
            float4  _S1181 = _S1137;
            *&((&_S1181)->x) = _S1180;
            _S1138 = _S1138 + _S1181;
        }
        else
        {
            _S1138 = _S1137;
        }
    }
    else
    {
        _S1138 = _S1137;
    }
    *v_depths_4 = _S1138;
    return;
}

inline __device__ float ray_depth_to_linear_depth_factor_prism(float2  pix_center_12, float4  intrins_21, FixedArray<float, 8>  dist_coeffs_25, int camera_model_23)
{
    float _S1182;
    for(;;)
    {
        float2  uv_63 = (pix_center_12 - float2 {intrins_21.z, intrins_21.w}) / float2 {intrins_21.x, intrins_21.y};
        FixedArray<float, 8>  _S1183 = dist_coeffs_25;
        float2  uv_u_30;
        bool _S1184 = undistort_point_2(uv_63, &_S1183, int(12), &uv_u_30);
        if(!_S1184)
        {
            _S1182 = 0.0f;
            break;
        }
        float3  raydir_16 = unproject_raydir_0(uv_u_30, camera_model_23, false);
        _S1182 = float((F32_sign((raydir_16.z)))) / length_0(raydir_16);
        break;
    }
    return _S1182;
}

inline __device__ float depth_normal_loss_prism(float2  pix_center_13, float4  intrins_22, FixedArray<float, 8>  dist_coeffs_26, int camera_model_24, bool is_ray_depth_21, float4  depths_10, float3  gt_normal_4)
{
    float _S1185;
    for(;;)
    {
        float3  _S1186;
        float3  * _S1187;
        float3  * _S1188;
        float3  * _S1189;
        float3  * _S1190;
        int _S1191;
        FixedArray<float3 , 5>  points_12;
        for(;;)
        {
            float2  _S1192 = float2 {intrins_22.z, intrins_22.w};
            float2  _S1193 = float2 {intrins_22.x, intrins_22.y};
            float2  uv_64 = (pix_center_13 + make_float2 (-1.0f, -0.0f) - _S1192) / _S1193;
            FixedArray<float, 8>  _S1194 = dist_coeffs_26;
            float2  uv_u_31;
            bool _S1195 = undistort_point_2(uv_64, &_S1194, int(12), &uv_u_31);
            float3  _S1196 = make_float3 (0.0f);
            if(!_S1195)
            {
                _S1191 = int(0);
                _S1190 = nullptr;
                _S1189 = nullptr;
                _S1188 = nullptr;
                _S1187 = nullptr;
                _S1186 = _S1196;
                break;
            }
            float3  raydir_17 = unproject_raydir_0(uv_u_31, camera_model_24, is_ray_depth_21);
            points_12[int(0)] = make_float3 (depths_10.x) * raydir_17;
            float2  uv_65 = (pix_center_13 + make_float2 (1.0f, -0.0f) - _S1192) / _S1193;
            FixedArray<float, 8>  _S1197 = dist_coeffs_26;
            float2  uv_u_32;
            bool _S1198 = undistort_point_2(uv_65, &_S1197, int(12), &uv_u_32);
            if(!_S1198)
            {
                _S1191 = int(0);
                _S1190 = nullptr;
                _S1189 = &points_12[int(0)];
                _S1188 = nullptr;
                _S1187 = nullptr;
                _S1186 = _S1196;
                break;
            }
            float3  raydir_18 = unproject_raydir_0(uv_u_32, camera_model_24, is_ray_depth_21);
            points_12[int(1)] = make_float3 (depths_10.y) * raydir_18;
            float2  uv_66 = (pix_center_13 + make_float2 (0.0f, -1.0f) - _S1192) / _S1193;
            FixedArray<float, 8>  _S1199 = dist_coeffs_26;
            float2  uv_u_33;
            bool _S1200 = undistort_point_2(uv_66, &_S1199, int(12), &uv_u_33);
            if(!_S1200)
            {
                _S1191 = int(0);
                _S1190 = &points_12[int(1)];
                _S1189 = &points_12[int(0)];
                _S1188 = nullptr;
                _S1187 = nullptr;
                _S1186 = _S1196;
                break;
            }
            float3  raydir_19 = unproject_raydir_0(uv_u_33, camera_model_24, is_ray_depth_21);
            points_12[int(2)] = make_float3 (depths_10.z) * raydir_19;
            float2  uv_67 = (pix_center_13 + make_float2 (0.0f, 1.0f) - _S1192) / _S1193;
            FixedArray<float, 8>  _S1201 = dist_coeffs_26;
            float2  uv_u_34;
            bool _S1202 = undistort_point_2(uv_67, &_S1201, int(12), &uv_u_34);
            if(!_S1202)
            {
                _S1191 = int(0);
                _S1190 = &points_12[int(1)];
                _S1189 = &points_12[int(0)];
                _S1188 = nullptr;
                _S1187 = &points_12[int(2)];
                _S1186 = _S1196;
                break;
            }
            float3  raydir_20 = unproject_raydir_0(uv_u_34, camera_model_24, is_ray_depth_21);
            points_12[int(3)] = make_float3 (depths_10.w) * raydir_20;
            float2  uv_68 = (pix_center_13 + make_float2 (0.0f) * make_float2 (0.0f, 3.0f) - _S1192) / _S1193;
            FixedArray<float, 8>  _S1203 = dist_coeffs_26;
            float2  uv_u_35;
            bool _S1204 = undistort_point_2(uv_68, &_S1203, int(12), &uv_u_35);
            if(!_S1204)
            {
                _S1191 = int(0);
                _S1190 = &points_12[int(1)];
                _S1189 = &points_12[int(0)];
                _S1188 = &points_12[int(3)];
                _S1187 = &points_12[int(2)];
                _S1186 = _S1196;
                break;
            }
            float3  raydir_21 = unproject_raydir_0(uv_u_35, camera_model_24, is_ray_depth_21);
            _S1191 = int(1);
            _S1190 = &points_12[int(1)];
            _S1189 = &points_12[int(0)];
            _S1188 = &points_12[int(3)];
            _S1187 = &points_12[int(2)];
            _S1186 = raydir_21;
            break;
        }
        if(_S1191 != int(1))
        {
            _S1185 = 0.0f;
            break;
        }
        float3  normal_14 = cross_0(*_S1190 - *_S1189, - (*_S1188 - *_S1187));
        float3  normal_15;
        if((dot_0(normal_14, normal_14)) != 0.0f)
        {
            normal_15 = normalize_0(normal_14);
        }
        else
        {
            normal_15 = normal_14;
        }
        float3  _S1205;
        if((dot_0(gt_normal_4, gt_normal_4)) != 0.0f)
        {
            _S1205 = normalize_0(gt_normal_4);
        }
        else
        {
            _S1205 = gt_normal_4;
        }
        _S1185 = (1.0f - dot_0(normal_15, _S1205) + 0.00100000004749745f) / ((F32_max((dot_0(normal_15, - normalize_0(_S1186))), (0.0f))) + 0.00100000004749745f);
        break;
    }
    return _S1185;
}

struct s_bwd_prop_depth_normal_loss_Intermediates_2
{
    float2  _S1206;
    bool _S1207;
    float2  _S1208;
    bool _S1209;
    float2  _S1210;
    bool _S1211;
    float2  _S1212;
    bool _S1213;
    float2  _S1214;
    bool _S1215;
};

inline __device__ void depth_normal_loss_vjp_prism(float2  pix_center_14, float4  intrins_23, FixedArray<float, 8>  dist_coeffs_27, int camera_model_25, bool is_ray_depth_22, float4  depths_11, float3  gt_normal_5, float v_loss_2, float4  * v_depths_5, float3  * v_gt_normal_2)
{
    float2  _S1216 = make_float2 (0.0f);
    s_bwd_prop_depth_normal_loss_Intermediates_2 _S1217;
    (&_S1217)->_S1206 = _S1216;
    (&_S1217)->_S1207 = false;
    (&_S1217)->_S1208 = _S1216;
    (&_S1217)->_S1209 = false;
    (&_S1217)->_S1210 = _S1216;
    (&_S1217)->_S1211 = false;
    (&_S1217)->_S1212 = _S1216;
    (&_S1217)->_S1213 = false;
    (&_S1217)->_S1214 = _S1216;
    (&_S1217)->_S1215 = false;
    (&_S1217)->_S1208 = _S1216;
    (&_S1217)->_S1209 = false;
    (&_S1217)->_S1210 = _S1216;
    (&_S1217)->_S1211 = false;
    (&_S1217)->_S1212 = _S1216;
    (&_S1217)->_S1213 = false;
    (&_S1217)->_S1214 = _S1216;
    (&_S1217)->_S1215 = false;
    float2  _S1218 = float2 {intrins_23.z, intrins_23.w};
    float2  _S1219 = float2 {intrins_23.x, intrins_23.y};
    float2  uv_69 = (pix_center_14 + make_float2 (-1.0f, -0.0f) - _S1218) / _S1219;
    float2  _S1220 = _S1216;
    FixedArray<float, 8>  _S1221 = dist_coeffs_27;
    bool _S1222 = undistort_point_2(uv_69, &_S1221, int(12), &_S1220);
    (&_S1217)->_S1206 = _S1220;
    (&_S1217)->_S1207 = _S1222;
    bool _S1223 = !!_S1222;
    bool _runFlag_23;
    if(_S1223)
    {
        float2  uv_70 = (pix_center_14 + make_float2 (1.0f, -0.0f) - _S1218) / _S1219;
        float2  _S1224 = _S1216;
        FixedArray<float, 8>  _S1225 = dist_coeffs_27;
        bool _S1226 = undistort_point_2(uv_70, &_S1225, int(12), &_S1224);
        (&_S1217)->_S1208 = _S1224;
        (&_S1217)->_S1209 = _S1226;
        if(!_S1226)
        {
            _runFlag_23 = false;
        }
        else
        {
            _runFlag_23 = _S1223;
        }
        if(_runFlag_23)
        {
            float2  uv_71 = (pix_center_14 + make_float2 (0.0f, -1.0f) - _S1218) / _S1219;
            float2  _S1227 = _S1216;
            FixedArray<float, 8>  _S1228 = dist_coeffs_27;
            bool _S1229 = undistort_point_2(uv_71, &_S1228, int(12), &_S1227);
            (&_S1217)->_S1210 = _S1227;
            (&_S1217)->_S1211 = _S1229;
            if(!_S1229)
            {
                _runFlag_23 = false;
            }
            if(_runFlag_23)
            {
                float2  uv_72 = (pix_center_14 + make_float2 (0.0f, 1.0f) - _S1218) / _S1219;
                float2  _S1230 = _S1216;
                FixedArray<float, 8>  _S1231 = dist_coeffs_27;
                bool _S1232 = undistort_point_2(uv_72, &_S1231, int(12), &_S1230);
                (&_S1217)->_S1212 = _S1230;
                (&_S1217)->_S1213 = _S1232;
                if(!_S1232)
                {
                    _runFlag_23 = false;
                }
                if(_runFlag_23)
                {
                    float2  uv_73 = (pix_center_14 - _S1218) / _S1219;
                    float2  _S1233 = _S1216;
                    FixedArray<float, 8>  _S1234 = dist_coeffs_27;
                    bool _S1235 = undistort_point_2(uv_73, &_S1234, int(12), &_S1233);
                    (&_S1217)->_S1214 = _S1233;
                    (&_S1217)->_S1215 = _S1235;
                }
            }
        }
    }
    s_bwd_prop_depth_normal_loss_Intermediates_2 _S1236 = _S1217;
    float3  _S1237 = make_float3 (0.0f);
    bool _S1238 = !!_S1217._S1207;
    bool _runFlag_24;
    bool _runFlag_25;
    bool _runFlag_26;
    int _S1239;
    float3  raydir_22;
    float3  _S1240;
    float3  _S1241;
    float3  _S1242;
    float3  _S1243;
    FixedArray<float3 , 5>  points_13;
    if(_S1238)
    {
        float3  _S1244 = s_primal_ctx_unproject_raydir_0(_S1236._S1206, camera_model_25, is_ray_depth_22);
        float3  _S1245 = make_float3 (depths_11.x) * _S1244;
        if(!_S1236._S1209)
        {
            _runFlag_23 = false;
        }
        else
        {
            _runFlag_23 = _S1238;
        }
        if(_runFlag_23)
        {
            float3  _S1246 = s_primal_ctx_unproject_raydir_0(_S1236._S1208, camera_model_25, is_ray_depth_22);
            float3  _S1247 = make_float3 (depths_11.y) * _S1246;
            if(!_S1236._S1211)
            {
                _runFlag_24 = false;
            }
            else
            {
                _runFlag_24 = _runFlag_23;
            }
            if(_runFlag_24)
            {
                float3  _S1248 = s_primal_ctx_unproject_raydir_0(_S1236._S1210, camera_model_25, is_ray_depth_22);
                float3  _S1249 = make_float3 (depths_11.z) * _S1248;
                if(!_S1236._S1213)
                {
                    _runFlag_25 = false;
                }
                else
                {
                    _runFlag_25 = _runFlag_24;
                }
                if(_runFlag_25)
                {
                    float3  _S1250 = s_primal_ctx_unproject_raydir_0(_S1236._S1212, camera_model_25, is_ray_depth_22);
                    float3  _S1251 = make_float3 (depths_11.w) * _S1250;
                    if(!_S1236._S1215)
                    {
                        _runFlag_26 = false;
                    }
                    else
                    {
                        _runFlag_26 = _runFlag_25;
                    }
                    if(_runFlag_26)
                    {
                        float3  _S1252 = s_primal_ctx_unproject_raydir_0(_S1236._S1214, camera_model_25, is_ray_depth_22);
                        _S1239 = int(1);
                        raydir_22 = _S1252;
                    }
                    else
                    {
                        _S1239 = int(0);
                        raydir_22 = _S1250;
                    }
                    points_13[int(0)] = _S1245;
                    points_13[int(1)] = _S1247;
                    points_13[int(2)] = _S1249;
                    points_13[int(3)] = _S1251;
                    points_13[int(4)] = _S1237;
                    _S1240 = _S1250;
                }
                else
                {
                    _S1239 = int(0);
                    raydir_22 = _S1248;
                    points_13[int(0)] = _S1245;
                    points_13[int(1)] = _S1247;
                    points_13[int(2)] = _S1249;
                    points_13[int(3)] = _S1237;
                    points_13[int(4)] = _S1237;
                    _S1240 = _S1237;
                }
                _S1241 = _S1248;
            }
            else
            {
                _S1239 = int(0);
                raydir_22 = _S1246;
                points_13[int(0)] = _S1245;
                points_13[int(1)] = _S1247;
                points_13[int(2)] = _S1237;
                points_13[int(3)] = _S1237;
                points_13[int(4)] = _S1237;
                _runFlag_25 = false;
                _S1240 = _S1237;
                _S1241 = _S1237;
            }
            _S1242 = _S1246;
        }
        else
        {
            _S1239 = int(0);
            raydir_22 = _S1244;
            points_13[int(0)] = _S1245;
            points_13[int(1)] = _S1237;
            points_13[int(2)] = _S1237;
            points_13[int(3)] = _S1237;
            points_13[int(4)] = _S1237;
            _runFlag_24 = false;
            _runFlag_25 = false;
            _S1240 = _S1237;
            _S1241 = _S1237;
            _S1242 = _S1237;
        }
        _S1243 = _S1244;
    }
    else
    {
        _S1239 = int(0);
        points_13[int(0)] = _S1237;
        points_13[int(1)] = _S1237;
        points_13[int(2)] = _S1237;
        points_13[int(3)] = _S1237;
        points_13[int(4)] = _S1237;
        _runFlag_23 = false;
        _runFlag_24 = false;
        _runFlag_25 = false;
        _S1240 = _S1237;
        _S1241 = _S1237;
        _S1242 = _S1237;
        _S1243 = _S1237;
    }
    bool _S1253 = !(_S1239 != int(1));
    bool _S1254;
    float3  normal_16;
    float3  _S1255;
    float3  _S1256;
    float3  _S1257;
    float3  _S1258;
    float _S1259;
    float _S1260;
    float _S1261;
    float _S1262;
    if(_S1253)
    {
        float3  dx_6 = points_13[int(1)] - points_13[int(0)];
        float3  _S1263 = - (points_13[int(3)] - points_13[int(2)]);
        float3  _S1264 = s_primal_ctx_cross_0(dx_6, _S1263);
        bool _S1265 = (s_primal_ctx_dot_0(_S1264, _S1264)) != 0.0f;
        if(_S1265)
        {
            normal_16 = normalize_0(_S1264);
        }
        else
        {
            normal_16 = _S1264;
        }
        bool _S1266 = (s_primal_ctx_dot_0(gt_normal_5, gt_normal_5)) != 0.0f;
        if(_S1266)
        {
            _S1255 = normalize_0(gt_normal_5);
        }
        else
        {
            _S1255 = gt_normal_5;
        }
        float3  _S1267 = - normalize_0(raydir_22);
        float _S1268 = s_primal_ctx_dot_0(normal_16, _S1267);
        float _S1269 = 1.0f - s_primal_ctx_dot_0(normal_16, _S1255) + 0.00100000004749745f;
        float _S1270 = (F32_max((_S1268), (0.0f))) + 0.00100000004749745f;
        _S1259 = _S1270 * _S1270;
        _S1260 = _S1269;
        _S1261 = _S1270;
        _S1262 = _S1268;
        raydir_22 = normal_16;
        normal_16 = _S1267;
        _runFlag_26 = _S1266;
        _S1254 = _S1265;
        _S1256 = _S1264;
        _S1257 = dx_6;
        _S1258 = _S1263;
    }
    else
    {
        _S1259 = 0.0f;
        _S1260 = 0.0f;
        _S1261 = 0.0f;
        _S1262 = 0.0f;
        raydir_22 = _S1237;
        normal_16 = _S1237;
        _S1255 = _S1237;
        _runFlag_26 = false;
        _S1254 = false;
        _S1256 = _S1237;
        _S1257 = _S1237;
        _S1258 = _S1237;
    }
    float4  _S1271 = make_float4 (0.0f);
    if(_S1253)
    {
        float _S1272 = v_loss_2 / _S1259;
        float _S1273 = _S1260 * - _S1272;
        float s_diff_num_T_2 = _S1261 * _S1272;
        DiffPair_float_0 _S1274;
        (&_S1274)->primal_0 = _S1262;
        (&_S1274)->differential_0 = 0.0f;
        DiffPair_float_0 _S1275;
        (&_S1275)->primal_0 = 0.0f;
        (&_S1275)->differential_0 = 0.0f;
        _d_max_0(&_S1274, &_S1275, _S1273);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1276;
        (&_S1276)->primal_0 = raydir_22;
        (&_S1276)->differential_0 = _S1237;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1277;
        (&_S1277)->primal_0 = normal_16;
        (&_S1277)->differential_0 = _S1237;
        s_bwd_prop_dot_0(&_S1276, &_S1277, _S1274.differential_0);
        float _S1278 = - s_diff_num_T_2;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1279;
        (&_S1279)->primal_0 = raydir_22;
        (&_S1279)->differential_0 = _S1237;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1280;
        (&_S1280)->primal_0 = _S1255;
        (&_S1280)->differential_0 = _S1237;
        s_bwd_prop_dot_0(&_S1279, &_S1280, _S1278);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1281 = _S1280;
        float3  _S1282 = _S1276.differential_0 + _S1279.differential_0;
        if(_runFlag_26)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1283;
            (&_S1283)->primal_0 = gt_normal_5;
            (&_S1283)->differential_0 = _S1237;
            s_bwd_normalize_impl_0(&_S1283, _S1281.differential_0);
            raydir_22 = _S1283.differential_0;
        }
        else
        {
            raydir_22 = _S1281.differential_0;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1284;
        (&_S1284)->primal_0 = gt_normal_5;
        (&_S1284)->differential_0 = _S1237;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1285;
        (&_S1285)->primal_0 = gt_normal_5;
        (&_S1285)->differential_0 = _S1237;
        s_bwd_prop_dot_0(&_S1284, &_S1285, 0.0f);
        float3  _S1286 = _S1285.differential_0 + _S1284.differential_0 + raydir_22;
        if(_S1254)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1287;
            (&_S1287)->primal_0 = _S1256;
            (&_S1287)->differential_0 = _S1237;
            s_bwd_normalize_impl_0(&_S1287, _S1282);
            raydir_22 = _S1287.differential_0;
        }
        else
        {
            raydir_22 = _S1282;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1288;
        (&_S1288)->primal_0 = _S1256;
        (&_S1288)->differential_0 = _S1237;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1289;
        (&_S1289)->primal_0 = _S1256;
        (&_S1289)->differential_0 = _S1237;
        s_bwd_prop_dot_0(&_S1288, &_S1289, 0.0f);
        float3  _S1290 = _S1289.differential_0 + _S1288.differential_0 + raydir_22;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1291;
        (&_S1291)->primal_0 = _S1257;
        (&_S1291)->differential_0 = _S1237;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1292;
        (&_S1292)->primal_0 = _S1258;
        (&_S1292)->differential_0 = _S1237;
        s_bwd_prop_cross_0(&_S1291, &_S1292, _S1290);
        float3  s_diff_dy_T_6 = - _S1292.differential_0;
        float3  _S1293 = - s_diff_dy_T_6;
        float3  _S1294 = - _S1291.differential_0;
        FixedArray<float3 , 5>  _S1295;
        _S1295[int(0)] = _S1237;
        _S1295[int(1)] = _S1237;
        _S1295[int(2)] = _S1237;
        _S1295[int(3)] = _S1237;
        _S1295[int(4)] = _S1237;
        _S1295[int(2)] = _S1293;
        _S1295[int(3)] = s_diff_dy_T_6;
        _S1295[int(0)] = _S1294;
        _S1295[int(1)] = _S1291.differential_0;
        points_13[int(0)] = _S1295[int(0)];
        points_13[int(1)] = _S1295[int(1)];
        points_13[int(2)] = _S1295[int(2)];
        points_13[int(3)] = _S1295[int(3)];
        points_13[int(4)] = _S1295[int(4)];
        raydir_22 = _S1286;
    }
    else
    {
        points_13[int(0)] = _S1237;
        points_13[int(1)] = _S1237;
        points_13[int(2)] = _S1237;
        points_13[int(3)] = _S1237;
        points_13[int(4)] = _S1237;
        raydir_22 = _S1237;
    }
    float4  _S1296;
    if(_S1238)
    {
        if(_runFlag_23)
        {
            if(_runFlag_24)
            {
                if(_runFlag_25)
                {
                    FixedArray<float3 , 5>  _S1297 = points_13;
                    FixedArray<float3 , 5>  _S1298 = points_13;
                    FixedArray<float3 , 5>  _S1299 = points_13;
                    float3  _S1300 = _S1240 * points_13[int(3)];
                    float _S1301 = _S1300.x + _S1300.y + _S1300.z;
                    float4  _S1302 = _S1271;
                    *&((&_S1302)->w) = _S1301;
                    points_13[int(0)] = _S1237;
                    points_13[int(1)] = _S1237;
                    points_13[int(2)] = _S1237;
                    points_13[int(3)] = _S1237;
                    points_13[int(4)] = _S1237;
                    _S1240 = _S1299[int(2)];
                    normal_16 = _S1297[int(0)];
                    _S1255 = _S1298[int(1)];
                    _S1296 = _S1302;
                }
                else
                {
                    FixedArray<float3 , 5>  _S1303 = points_13;
                    FixedArray<float3 , 5>  _S1304 = points_13;
                    FixedArray<float3 , 5>  _S1305 = points_13;
                    FixedArray<float3 , 5>  _S1306 = points_13;
                    points_13[int(0)] = points_13[int(0)];
                    points_13[int(1)] = _S1303[int(1)];
                    points_13[int(2)] = _S1304[int(2)];
                    points_13[int(3)] = _S1305[int(3)];
                    points_13[int(4)] = _S1306[int(4)];
                    _S1240 = _S1237;
                    normal_16 = _S1237;
                    _S1255 = _S1237;
                    _S1296 = _S1271;
                }
                float3  _S1307 = _S1241 * (points_13[int(2)] + _S1240);
                float _S1308 = _S1307.x + _S1307.y + _S1307.z;
                float3  _S1309 = points_13[int(0)] + normal_16;
                float3  _S1310 = points_13[int(1)] + _S1255;
                float4  _S1311 = _S1271;
                *&((&_S1311)->z) = _S1308;
                float4  _S1312 = _S1296 + _S1311;
                points_13[int(0)] = _S1237;
                points_13[int(1)] = _S1237;
                points_13[int(2)] = _S1237;
                points_13[int(3)] = _S1237;
                points_13[int(4)] = _S1237;
                _S1240 = _S1310;
                _S1241 = _S1309;
                _S1296 = _S1312;
            }
            else
            {
                FixedArray<float3 , 5>  _S1313 = points_13;
                FixedArray<float3 , 5>  _S1314 = points_13;
                FixedArray<float3 , 5>  _S1315 = points_13;
                FixedArray<float3 , 5>  _S1316 = points_13;
                points_13[int(0)] = points_13[int(0)];
                points_13[int(1)] = _S1313[int(1)];
                points_13[int(2)] = _S1314[int(2)];
                points_13[int(3)] = _S1315[int(3)];
                points_13[int(4)] = _S1316[int(4)];
                _S1240 = _S1237;
                _S1241 = _S1237;
                _S1296 = _S1271;
            }
            float3  _S1317 = _S1242 * (points_13[int(1)] + _S1240);
            float _S1318 = _S1317.x + _S1317.y + _S1317.z;
            float3  _S1319 = points_13[int(0)] + _S1241;
            float4  _S1320 = _S1271;
            *&((&_S1320)->y) = _S1318;
            float4  _S1321 = _S1296 + _S1320;
            points_13[int(0)] = _S1237;
            points_13[int(1)] = _S1237;
            points_13[int(2)] = _S1237;
            points_13[int(3)] = _S1237;
            points_13[int(4)] = _S1237;
            _S1240 = _S1319;
            _S1296 = _S1321;
        }
        else
        {
            FixedArray<float3 , 5>  _S1322 = points_13;
            FixedArray<float3 , 5>  _S1323 = points_13;
            FixedArray<float3 , 5>  _S1324 = points_13;
            FixedArray<float3 , 5>  _S1325 = points_13;
            points_13[int(0)] = points_13[int(0)];
            points_13[int(1)] = _S1322[int(1)];
            points_13[int(2)] = _S1323[int(2)];
            points_13[int(3)] = _S1324[int(3)];
            points_13[int(4)] = _S1325[int(4)];
            _S1240 = _S1237;
            _S1296 = _S1271;
        }
        float3  _S1326 = _S1243 * (points_13[int(0)] + _S1240);
        float _S1327 = _S1326.x + _S1326.y + _S1326.z;
        float4  _S1328 = _S1271;
        *&((&_S1328)->x) = _S1327;
        _S1296 = _S1296 + _S1328;
    }
    else
    {
        _S1296 = _S1271;
    }
    *v_depths_5 = _S1296;
    *v_gt_normal_2 = raydir_22;
    return;
}

inline __device__ float3  generate_ray_d2n_rational(float2  pix_pos_9, float4  intrins_24, FixedArray<float, 8>  dist_coeffs_28, int camera_model_26, bool is_ray_depth_23)
{
    float3  _S1329;
    for(;;)
    {
        float2  uv_74 = (pix_pos_9 - float2 {intrins_24.z, intrins_24.w}) / float2 {intrins_24.x, intrins_24.y};
        FixedArray<float, 8>  _S1330 = dist_coeffs_28;
        float2  uv_u_36;
        bool _S1331 = undistort_point_3(uv_74, &_S1330, int(12), &uv_u_36);
        if(!_S1331)
        {
            int3  _S1332 = make_int3 (int(0));
            float3  _S1333 = make_float3 ((float)_S1332.x, (float)_S1332.y, (float)_S1332.z);
            _S1329 = _S1333;
            break;
        }
        _S1329 = unproject_raydir_0(uv_u_36, camera_model_26, is_ray_depth_23);
        break;
    }
    return _S1329;
}

inline __device__ float3  depth_to_point_rational(float2  pix_pos_10, float4  intrins_25, FixedArray<float, 8>  dist_coeffs_29, int camera_model_27, bool is_ray_depth_24, float depth_8)
{
    float3  _S1334;
    for(;;)
    {
        float2  uv_75 = (pix_pos_10 - float2 {intrins_25.z, intrins_25.w}) / float2 {intrins_25.x, intrins_25.y};
        FixedArray<float, 8>  _S1335 = dist_coeffs_29;
        float2  uv_u_37;
        bool _S1336 = undistort_point_3(uv_75, &_S1335, int(12), &uv_u_37);
        if(!_S1336)
        {
            _S1334 = make_float3 (0.0f);
            break;
        }
        _S1334 = make_float3 (depth_8) * unproject_raydir_0(uv_u_37, camera_model_27, is_ray_depth_24);
        break;
    }
    return _S1334;
}

struct s_bwd_prop_depth_to_point_Intermediates_3
{
    float2  _S1337;
    bool _S1338;
};

inline __device__ float depth_to_point_vjp_rational(float2  pix_pos_11, float4  intrins_26, FixedArray<float, 8>  dist_coeffs_30, int camera_model_28, bool is_ray_depth_25, float depth_9, float3  v_point_3)
{
    float2  _S1339 = make_float2 (0.0f);
    s_bwd_prop_depth_to_point_Intermediates_3 _S1340;
    (&_S1340)->_S1337 = _S1339;
    (&_S1340)->_S1338 = false;
    float2  uv_76 = (pix_pos_11 - float2 {intrins_26.z, intrins_26.w}) / float2 {intrins_26.x, intrins_26.y};
    float2  _S1341 = _S1339;
    FixedArray<float, 8>  _S1342 = dist_coeffs_30;
    bool _S1343 = undistort_point_3(uv_76, &_S1342, int(12), &_S1341);
    (&_S1340)->_S1337 = _S1341;
    (&_S1340)->_S1338 = _S1343;
    s_bwd_prop_depth_to_point_Intermediates_3 _S1344 = _S1340;
    float3  _S1345 = make_float3 (0.0f);
    bool _S1346 = !!_S1340._S1338;
    float3  _S1347;
    if(_S1346)
    {
        _S1347 = s_primal_ctx_unproject_raydir_0(_S1344._S1337, camera_model_28, is_ray_depth_25);
    }
    else
    {
        _S1347 = _S1345;
    }
    if(_S1346)
    {
        _S1347 = _S1347 * v_point_3;
    }
    else
    {
        _S1347 = _S1345;
    }
    return _S1347.x + _S1347.y + _S1347.z;
}

inline __device__ float3  depth_to_normal_rational(float2  pix_center_15, float4  intrins_27, FixedArray<float, 8>  dist_coeffs_31, int camera_model_29, bool is_ray_depth_26, float4  depths_12)
{
    float3  normal_17;
    for(;;)
    {
        bool _S1348;
        if((depths_12.x) == 0.0f)
        {
            _S1348 = true;
        }
        else
        {
            _S1348 = (depths_12.y) == 0.0f;
        }
        if(_S1348)
        {
            _S1348 = true;
        }
        else
        {
            _S1348 = (depths_12.z) == 0.0f;
        }
        if(_S1348)
        {
            _S1348 = true;
        }
        else
        {
            _S1348 = (depths_12.w) == 0.0f;
        }
        if(_S1348)
        {
            normal_17 = make_float3 (0.0f);
            break;
        }
        float3  * _S1349;
        float3  * _S1350;
        float3  * _S1351;
        float3  * _S1352;
        int _S1353;
        FixedArray<float3 , 4>  points_14;
        for(;;)
        {
            float2  _S1354 = float2 {intrins_27.z, intrins_27.w};
            float2  _S1355 = float2 {intrins_27.x, intrins_27.y};
            float2  uv_77 = (pix_center_15 + make_float2 (-1.0f, -0.0f) - _S1354) / _S1355;
            FixedArray<float, 8>  _S1356 = dist_coeffs_31;
            float2  uv_u_38;
            bool _S1357 = undistort_point_3(uv_77, &_S1356, int(12), &uv_u_38);
            if(!_S1357)
            {
                float3  _S1358 = make_float3 (0.0f);
                _S1353 = int(0);
                _S1352 = nullptr;
                _S1351 = nullptr;
                _S1350 = nullptr;
                _S1349 = nullptr;
                normal_17 = _S1358;
                break;
            }
            points_14[int(0)] = make_float3 (depths_12.x) * unproject_raydir_0(uv_u_38, camera_model_29, is_ray_depth_26);
            for(;;)
            {
                float2  uv_78 = (pix_center_15 + make_float2 (1.0f, -0.0f) - _S1354) / _S1355;
                FixedArray<float, 8>  _S1359 = dist_coeffs_31;
                float2  uv_u_39;
                bool _S1360 = undistort_point_3(uv_78, &_S1359, int(12), &uv_u_39);
                if(!_S1360)
                {
                    float3  _S1361 = make_float3 (0.0f);
                    _S1353 = int(0);
                    _S1352 = nullptr;
                    normal_17 = _S1361;
                    break;
                }
                points_14[int(1)] = make_float3 (depths_12.y) * unproject_raydir_0(uv_u_39, camera_model_29, is_ray_depth_26);
                _S1353 = int(2);
                _S1352 = &points_14[int(1)];
                break;
            }
            if(_S1353 != int(2))
            {
                _S1351 = &points_14[int(0)];
                _S1350 = nullptr;
                _S1349 = nullptr;
                break;
            }
            float2  uv_79 = (pix_center_15 + make_float2 (0.0f, -1.0f) - _S1354) / _S1355;
            FixedArray<float, 8>  _S1362 = dist_coeffs_31;
            float2  uv_u_40;
            bool _S1363 = undistort_point_3(uv_79, &_S1362, int(12), &uv_u_40);
            if(!_S1363)
            {
                float3  _S1364 = make_float3 (0.0f);
                _S1353 = int(0);
                _S1351 = &points_14[int(0)];
                _S1350 = nullptr;
                _S1349 = nullptr;
                normal_17 = _S1364;
                break;
            }
            points_14[int(2)] = make_float3 (depths_12.z) * unproject_raydir_0(uv_u_40, camera_model_29, is_ray_depth_26);
            for(;;)
            {
                float2  uv_80 = (pix_center_15 + make_float2 (0.0f, 1.0f) - _S1354) / _S1355;
                FixedArray<float, 8>  _S1365 = dist_coeffs_31;
                float2  uv_u_41;
                bool _S1366 = undistort_point_3(uv_80, &_S1365, int(12), &uv_u_41);
                if(!_S1366)
                {
                    float3  _S1367 = make_float3 (0.0f);
                    _S1353 = int(0);
                    _S1351 = nullptr;
                    normal_17 = _S1367;
                    break;
                }
                points_14[int(3)] = make_float3 (depths_12.w) * unproject_raydir_0(uv_u_41, camera_model_29, is_ray_depth_26);
                _S1353 = int(2);
                _S1351 = &points_14[int(3)];
                break;
            }
            if(_S1353 != int(2))
            {
                float3  * _S1368 = _S1351;
                _S1351 = &points_14[int(0)];
                _S1350 = _S1368;
                _S1349 = &points_14[int(2)];
                break;
            }
            float3  * _S1369 = _S1351;
            _S1353 = int(1);
            _S1351 = &points_14[int(0)];
            _S1350 = _S1369;
            _S1349 = &points_14[int(2)];
            break;
        }
        if(_S1353 != int(1))
        {
            break;
        }
        float3  normal_18 = cross_0(*_S1352 - *_S1351, - (*_S1350 - *_S1349));
        if((dot_0(normal_18, normal_18)) != 0.0f)
        {
            normal_17 = normal_18 / make_float3 (length_0(normal_18));
        }
        else
        {
            normal_17 = normal_18;
        }
        break;
    }
    return normal_17;
}

struct s_bwd_prop_depth_to_normal_Intermediates_3
{
    float2  _S1370;
    bool _S1371;
    float2  _S1372;
    bool _S1373;
    float2  _S1374;
    bool _S1375;
    float2  _S1376;
    bool _S1377;
};

inline __device__ void depth_to_normal_vjp_rational(float2  pix_center_16, float4  intrins_28, FixedArray<float, 8>  dist_coeffs_32, int camera_model_30, bool is_ray_depth_27, float4  depths_13, float3  v_normal_4, float4  * v_depths_6)
{
    float2  _S1378 = make_float2 (0.0f);
    s_bwd_prop_depth_to_normal_Intermediates_3 _S1379;
    (&_S1379)->_S1370 = _S1378;
    (&_S1379)->_S1371 = false;
    (&_S1379)->_S1372 = _S1378;
    (&_S1379)->_S1373 = false;
    (&_S1379)->_S1374 = _S1378;
    (&_S1379)->_S1375 = false;
    (&_S1379)->_S1376 = _S1378;
    (&_S1379)->_S1377 = false;
    (&_S1379)->_S1370 = _S1378;
    (&_S1379)->_S1371 = false;
    (&_S1379)->_S1372 = _S1378;
    (&_S1379)->_S1373 = false;
    (&_S1379)->_S1374 = _S1378;
    (&_S1379)->_S1375 = false;
    (&_S1379)->_S1376 = _S1378;
    (&_S1379)->_S1377 = false;
    bool _S1380 = (depths_13.x) == 0.0f;
    bool _runFlag_27;
    if(_S1380)
    {
        _runFlag_27 = true;
    }
    else
    {
        _runFlag_27 = (depths_13.y) == 0.0f;
    }
    if(_runFlag_27)
    {
        _runFlag_27 = true;
    }
    else
    {
        _runFlag_27 = (depths_13.z) == 0.0f;
    }
    if(_runFlag_27)
    {
        _runFlag_27 = true;
    }
    else
    {
        _runFlag_27 = (depths_13.w) == 0.0f;
    }
    int _S1381;
    if(!_runFlag_27)
    {
        float2  _S1382 = float2 {intrins_28.z, intrins_28.w};
        float2  _S1383 = float2 {intrins_28.x, intrins_28.y};
        float2  uv_81 = (pix_center_16 + make_float2 (-1.0f, -0.0f) - _S1382) / _S1383;
        float2  _S1384 = _S1378;
        FixedArray<float, 8>  _S1385 = dist_coeffs_32;
        bool _S1386 = undistort_point_3(uv_81, &_S1385, int(12), &_S1384);
        (&_S1379)->_S1370 = _S1384;
        (&_S1379)->_S1371 = _S1386;
        bool _S1387 = !!_S1386;
        if(_S1387)
        {
            float2  uv_82 = (pix_center_16 + make_float2 (1.0f, -0.0f) - _S1382) / _S1383;
            float2  _S1388 = _S1378;
            FixedArray<float, 8>  _S1389 = dist_coeffs_32;
            bool _S1390 = undistort_point_3(uv_82, &_S1389, int(12), &_S1388);
            (&_S1379)->_S1372 = _S1388;
            (&_S1379)->_S1373 = _S1390;
            if(!!_S1390)
            {
                _S1381 = int(2);
            }
            else
            {
                _S1381 = int(0);
            }
            if(_S1381 != int(2))
            {
                _runFlag_27 = false;
            }
            else
            {
                _runFlag_27 = _S1387;
            }
            if(_runFlag_27)
            {
                float2  uv_83 = (pix_center_16 + make_float2 (0.0f, -1.0f) - _S1382) / _S1383;
                float2  _S1391 = _S1378;
                FixedArray<float, 8>  _S1392 = dist_coeffs_32;
                bool _S1393 = undistort_point_3(uv_83, &_S1392, int(12), &_S1391);
                (&_S1379)->_S1374 = _S1391;
                (&_S1379)->_S1375 = _S1393;
                if(!_S1393)
                {
                    _runFlag_27 = false;
                }
                if(_runFlag_27)
                {
                    float2  uv_84 = (pix_center_16 + make_float2 (0.0f, 1.0f) - _S1382) / _S1383;
                    float2  _S1394 = _S1378;
                    FixedArray<float, 8>  _S1395 = dist_coeffs_32;
                    bool _S1396 = undistort_point_3(uv_84, &_S1395, int(12), &_S1394);
                    (&_S1379)->_S1376 = _S1394;
                    (&_S1379)->_S1377 = _S1396;
                }
            }
        }
    }
    s_bwd_prop_depth_to_normal_Intermediates_3 _S1397 = _S1379;
    float3  _S1398 = make_float3 (0.0f);
    if(_S1380)
    {
        _runFlag_27 = true;
    }
    else
    {
        _runFlag_27 = (depths_13.y) == 0.0f;
    }
    if(_runFlag_27)
    {
        _runFlag_27 = true;
    }
    else
    {
        _runFlag_27 = (depths_13.z) == 0.0f;
    }
    if(_runFlag_27)
    {
        _runFlag_27 = true;
    }
    else
    {
        _runFlag_27 = (depths_13.w) == 0.0f;
    }
    bool _S1399 = !_runFlag_27;
    bool _runFlag_28;
    bool _runFlag_29;
    bool _S1400;
    bool _runFlag_30;
    bool _S1401;
    bool _S1402;
    FixedArray<float3 , 4>  points_15;
    float3  _S1403;
    float3  _S1404;
    float3  _S1405;
    float3  _S1406;
    float3  _S1407;
    float3  _S1408;
    float3  _S1409;
    float3  _S1410;
    float3  _S1411;
    if(_S1399)
    {
        bool _S1412 = !!_S1397._S1371;
        if(_S1412)
        {
            float3  _S1413 = s_primal_ctx_unproject_raydir_0(_S1397._S1370, camera_model_30, is_ray_depth_27);
            float3  _S1414 = make_float3 (depths_13.x) * _S1413;
            bool _S1415 = !!_S1397._S1373;
            if(_S1415)
            {
                float3  _S1416 = s_primal_ctx_unproject_raydir_0(_S1397._S1372, camera_model_30, is_ray_depth_27);
                float3  _S1417 = make_float3 (depths_13.y) * _S1416;
                _S1381 = int(2);
                points_15[int(0)] = _S1414;
                points_15[int(1)] = _S1417;
                points_15[int(2)] = _S1398;
                points_15[int(3)] = _S1398;
                _S1403 = _S1416;
            }
            else
            {
                _S1381 = int(0);
                points_15[int(0)] = _S1414;
                points_15[int(1)] = _S1398;
                points_15[int(2)] = _S1398;
                points_15[int(3)] = _S1398;
                _S1403 = _S1398;
            }
            if(_S1381 != int(2))
            {
                _runFlag_27 = false;
            }
            else
            {
                _runFlag_27 = _S1412;
                _S1381 = int(0);
            }
            if(_runFlag_27)
            {
                if(!_S1397._S1375)
                {
                    _runFlag_28 = false;
                    _S1381 = int(0);
                }
                else
                {
                    _runFlag_28 = _runFlag_27;
                }
                if(_runFlag_28)
                {
                    float3  _S1418 = s_primal_ctx_unproject_raydir_0(_S1397._S1374, camera_model_30, is_ray_depth_27);
                    points_15[int(2)] = make_float3 (depths_13.z) * _S1418;
                    bool _S1419 = !!_S1397._S1377;
                    int _S1420;
                    if(_S1419)
                    {
                        float3  _S1421 = s_primal_ctx_unproject_raydir_0(_S1397._S1376, camera_model_30, is_ray_depth_27);
                        points_15[int(3)] = make_float3 (depths_13.w) * _S1421;
                        _S1420 = int(2);
                        _S1404 = _S1421;
                    }
                    else
                    {
                        _S1420 = int(0);
                        _S1404 = _S1398;
                    }
                    if(_S1420 != int(2))
                    {
                        _runFlag_29 = false;
                        _S1381 = _S1420;
                    }
                    else
                    {
                        _runFlag_29 = _runFlag_28;
                    }
                    if(_runFlag_29)
                    {
                        _S1381 = int(1);
                    }
                    _runFlag_29 = _S1419;
                    _S1405 = _S1418;
                }
                else
                {
                    _runFlag_29 = false;
                    _S1404 = _S1398;
                    _S1405 = _S1398;
                }
            }
            else
            {
                _runFlag_28 = false;
                _runFlag_29 = false;
                _S1404 = _S1398;
                _S1405 = _S1398;
            }
            float3  _S1422 = _S1403;
            _S1403 = _S1404;
            _S1404 = _S1405;
            _S1400 = _S1415;
            _S1405 = _S1422;
            _S1406 = _S1413;
        }
        else
        {
            _S1381 = int(0);
            points_15[int(0)] = _S1398;
            points_15[int(1)] = _S1398;
            points_15[int(2)] = _S1398;
            points_15[int(3)] = _S1398;
            _runFlag_27 = false;
            _runFlag_28 = false;
            _runFlag_29 = false;
            _S1403 = _S1398;
            _S1404 = _S1398;
            _S1400 = false;
            _S1405 = _S1398;
            _S1406 = _S1398;
        }
        if(_S1381 != int(1))
        {
            _runFlag_30 = false;
        }
        else
        {
            _runFlag_30 = _S1399;
        }
        if(_runFlag_30)
        {
            float3  dx_7 = points_15[int(1)] - points_15[int(0)];
            float3  _S1423 = - (points_15[int(3)] - points_15[int(2)]);
            float3  _S1424 = s_primal_ctx_cross_0(dx_7, _S1423);
            bool _S1425 = (s_primal_ctx_dot_0(_S1424, _S1424)) != 0.0f;
            if(_S1425)
            {
                float _S1426 = length_0(_S1424);
                float3  _S1427 = make_float3 (_S1426);
                _S1407 = make_float3 (_S1426 * _S1426);
                _S1408 = _S1427;
            }
            else
            {
                _S1407 = _S1398;
                _S1408 = _S1398;
            }
            float3  _S1428 = _S1408;
            _S1401 = _S1425;
            _S1408 = _S1424;
            _S1409 = _S1428;
            _S1410 = dx_7;
            _S1411 = _S1423;
        }
        else
        {
            _S1401 = false;
            _S1407 = _S1398;
            _S1408 = _S1398;
            _S1409 = _S1398;
            _S1410 = _S1398;
            _S1411 = _S1398;
        }
        bool _S1429 = _runFlag_27;
        bool _S1430 = _runFlag_28;
        bool _S1431 = _runFlag_29;
        float3  _S1432 = _S1403;
        float3  _S1433 = _S1404;
        bool _S1434 = _S1400;
        float3  _S1435 = _S1405;
        float3  _S1436 = _S1406;
        _runFlag_27 = _runFlag_30;
        _runFlag_28 = _S1401;
        _S1403 = _S1407;
        _S1404 = _S1408;
        _S1405 = _S1409;
        _S1406 = _S1410;
        _S1407 = _S1411;
        _runFlag_29 = _S1412;
        _S1400 = _S1429;
        _runFlag_30 = _S1430;
        _S1401 = _S1431;
        _S1408 = _S1432;
        _S1409 = _S1433;
        _S1402 = _S1434;
        _S1410 = _S1435;
        _S1411 = _S1436;
    }
    else
    {
        _runFlag_27 = false;
        _runFlag_28 = false;
        _S1403 = _S1398;
        _S1404 = _S1398;
        _S1405 = _S1398;
        _S1406 = _S1398;
        _S1407 = _S1398;
        _runFlag_29 = false;
        _S1400 = false;
        _runFlag_30 = false;
        _S1401 = false;
        _S1408 = _S1398;
        _S1409 = _S1398;
        _S1402 = false;
        _S1410 = _S1398;
        _S1411 = _S1398;
    }
    float4  _S1437 = make_float4 (0.0f);
    float4  _S1438;
    if(_S1399)
    {
        if(_runFlag_27)
        {
            if(_runFlag_28)
            {
                float3  _S1439 = v_normal_4 / _S1403;
                float3  _S1440 = _S1404 * - _S1439;
                float3  _S1441 = _S1405 * _S1439;
                float _S1442 = _S1440.x + _S1440.y + _S1440.z;
                DiffPair_vectorx3Cfloatx2C3x3E_0 _S1443;
                (&_S1443)->primal_0 = _S1404;
                (&_S1443)->differential_0 = _S1398;
                s_bwd_length_impl_0(&_S1443, _S1442);
                _S1403 = _S1441 + _S1443.differential_0;
            }
            else
            {
                _S1403 = v_normal_4;
            }
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1444;
            (&_S1444)->primal_0 = _S1404;
            (&_S1444)->differential_0 = _S1398;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1445;
            (&_S1445)->primal_0 = _S1404;
            (&_S1445)->differential_0 = _S1398;
            s_bwd_prop_dot_0(&_S1444, &_S1445, 0.0f);
            float3  _S1446 = _S1445.differential_0 + _S1444.differential_0 + _S1403;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1447;
            (&_S1447)->primal_0 = _S1406;
            (&_S1447)->differential_0 = _S1398;
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1448;
            (&_S1448)->primal_0 = _S1407;
            (&_S1448)->differential_0 = _S1398;
            s_bwd_prop_cross_0(&_S1447, &_S1448, _S1446);
            float3  s_diff_dy_T_7 = - _S1448.differential_0;
            float3  _S1449 = - s_diff_dy_T_7;
            float3  _S1450 = - _S1447.differential_0;
            FixedArray<float3 , 4>  _S1451;
            _S1451[int(0)] = _S1398;
            _S1451[int(1)] = _S1398;
            _S1451[int(2)] = _S1398;
            _S1451[int(3)] = _S1398;
            _S1451[int(2)] = _S1449;
            _S1451[int(3)] = s_diff_dy_T_7;
            _S1451[int(0)] = _S1450;
            _S1451[int(1)] = _S1447.differential_0;
            points_15[int(0)] = _S1451[int(0)];
            points_15[int(1)] = _S1451[int(1)];
            points_15[int(2)] = _S1451[int(2)];
            points_15[int(3)] = _S1451[int(3)];
        }
        else
        {
            points_15[int(0)] = _S1398;
            points_15[int(1)] = _S1398;
            points_15[int(2)] = _S1398;
            points_15[int(3)] = _S1398;
        }
        if(_runFlag_29)
        {
            if(_S1400)
            {
                if(_runFlag_30)
                {
                    FixedArray<float3 , 4>  _S1452 = points_15;
                    FixedArray<float3 , 4>  _S1453 = points_15;
                    FixedArray<float3 , 4>  _S1454 = points_15;
                    FixedArray<float3 , 4>  _S1455 = points_15;
                    if(_S1401)
                    {
                        float3  _S1456 = _S1408 * _S1455[int(3)];
                        float _S1457 = _S1456.x + _S1456.y + _S1456.z;
                        float4  _S1458 = _S1437;
                        *&((&_S1458)->w) = _S1457;
                        points_15[int(0)] = _S1452[int(0)];
                        points_15[int(1)] = _S1453[int(1)];
                        points_15[int(2)] = _S1454[int(2)];
                        points_15[int(3)] = _S1398;
                        _S1438 = _S1458;
                    }
                    else
                    {
                        points_15[int(0)] = _S1452[int(0)];
                        points_15[int(1)] = _S1453[int(1)];
                        points_15[int(2)] = _S1454[int(2)];
                        points_15[int(3)] = _S1455[int(3)];
                        _S1438 = _S1437;
                    }
                    float3  _S1459 = _S1409 * points_15[int(2)];
                    float _S1460 = _S1459.x + _S1459.y + _S1459.z;
                    FixedArray<float3 , 4>  _S1461 = points_15;
                    FixedArray<float3 , 4>  _S1462 = points_15;
                    float4  _S1463 = _S1437;
                    *&((&_S1463)->z) = _S1460;
                    float4  _S1464 = _S1438 + _S1463;
                    points_15[int(0)] = points_15[int(0)];
                    points_15[int(1)] = _S1461[int(1)];
                    points_15[int(2)] = _S1398;
                    points_15[int(3)] = _S1462[int(3)];
                    _S1438 = _S1464;
                }
                else
                {
                    FixedArray<float3 , 4>  _S1465 = points_15;
                    FixedArray<float3 , 4>  _S1466 = points_15;
                    FixedArray<float3 , 4>  _S1467 = points_15;
                    points_15[int(0)] = points_15[int(0)];
                    points_15[int(1)] = _S1465[int(1)];
                    points_15[int(2)] = _S1466[int(2)];
                    points_15[int(3)] = _S1467[int(3)];
                    _S1438 = _S1437;
                }
            }
            else
            {
                FixedArray<float3 , 4>  _S1468 = points_15;
                FixedArray<float3 , 4>  _S1469 = points_15;
                FixedArray<float3 , 4>  _S1470 = points_15;
                points_15[int(0)] = points_15[int(0)];
                points_15[int(1)] = _S1468[int(1)];
                points_15[int(2)] = _S1469[int(2)];
                points_15[int(3)] = _S1470[int(3)];
                _S1438 = _S1437;
            }
            if(_S1402)
            {
                FixedArray<float3 , 4>  _S1471 = points_15;
                float3  _S1472 = _S1410 * points_15[int(1)];
                float _S1473 = _S1472.x + _S1472.y + _S1472.z;
                float4  _S1474 = _S1437;
                *&((&_S1474)->y) = _S1473;
                float4  _S1475 = _S1438 + _S1474;
                points_15[int(0)] = _S1398;
                points_15[int(1)] = _S1398;
                points_15[int(2)] = _S1398;
                points_15[int(3)] = _S1398;
                _S1403 = _S1471[int(0)];
                _S1438 = _S1475;
            }
            else
            {
                FixedArray<float3 , 4>  _S1476 = points_15;
                FixedArray<float3 , 4>  _S1477 = points_15;
                FixedArray<float3 , 4>  _S1478 = points_15;
                points_15[int(0)] = points_15[int(0)];
                points_15[int(1)] = _S1476[int(1)];
                points_15[int(2)] = _S1477[int(2)];
                points_15[int(3)] = _S1478[int(3)];
                _S1403 = _S1398;
            }
            float3  _S1479 = _S1411 * (points_15[int(0)] + _S1403);
            float _S1480 = _S1479.x + _S1479.y + _S1479.z;
            float4  _S1481 = _S1437;
            *&((&_S1481)->x) = _S1480;
            _S1438 = _S1438 + _S1481;
        }
        else
        {
            _S1438 = _S1437;
        }
    }
    else
    {
        _S1438 = _S1437;
    }
    *v_depths_6 = _S1438;
    return;
}

inline __device__ float ray_depth_to_linear_depth_factor_rational(float2  pix_center_17, float4  intrins_29, FixedArray<float, 8>  dist_coeffs_33, int camera_model_31)
{
    float _S1482;
    for(;;)
    {
        float2  uv_85 = (pix_center_17 - float2 {intrins_29.z, intrins_29.w}) / float2 {intrins_29.x, intrins_29.y};
        FixedArray<float, 8>  _S1483 = dist_coeffs_33;
        float2  uv_u_42;
        bool _S1484 = undistort_point_3(uv_85, &_S1483, int(12), &uv_u_42);
        if(!_S1484)
        {
            _S1482 = 0.0f;
            break;
        }
        float3  raydir_23 = unproject_raydir_0(uv_u_42, camera_model_31, false);
        _S1482 = float((F32_sign((raydir_23.z)))) / length_0(raydir_23);
        break;
    }
    return _S1482;
}

inline __device__ float depth_normal_loss_rational(float2  pix_center_18, float4  intrins_30, FixedArray<float, 8>  dist_coeffs_34, int camera_model_32, bool is_ray_depth_28, float4  depths_14, float3  gt_normal_6)
{
    float _S1485;
    for(;;)
    {
        float3  _S1486;
        float3  * _S1487;
        float3  * _S1488;
        float3  * _S1489;
        float3  * _S1490;
        int _S1491;
        FixedArray<float3 , 5>  points_16;
        for(;;)
        {
            float2  _S1492 = float2 {intrins_30.z, intrins_30.w};
            float2  _S1493 = float2 {intrins_30.x, intrins_30.y};
            float2  uv_86 = (pix_center_18 + make_float2 (-1.0f, -0.0f) - _S1492) / _S1493;
            FixedArray<float, 8>  _S1494 = dist_coeffs_34;
            float2  uv_u_43;
            bool _S1495 = undistort_point_3(uv_86, &_S1494, int(12), &uv_u_43);
            float3  _S1496 = make_float3 (0.0f);
            if(!_S1495)
            {
                _S1491 = int(0);
                _S1490 = nullptr;
                _S1489 = nullptr;
                _S1488 = nullptr;
                _S1487 = nullptr;
                _S1486 = _S1496;
                break;
            }
            float3  raydir_24 = unproject_raydir_0(uv_u_43, camera_model_32, is_ray_depth_28);
            points_16[int(0)] = make_float3 (depths_14.x) * raydir_24;
            float2  uv_87 = (pix_center_18 + make_float2 (1.0f, -0.0f) - _S1492) / _S1493;
            FixedArray<float, 8>  _S1497 = dist_coeffs_34;
            float2  uv_u_44;
            bool _S1498 = undistort_point_3(uv_87, &_S1497, int(12), &uv_u_44);
            if(!_S1498)
            {
                _S1491 = int(0);
                _S1490 = nullptr;
                _S1489 = &points_16[int(0)];
                _S1488 = nullptr;
                _S1487 = nullptr;
                _S1486 = _S1496;
                break;
            }
            float3  raydir_25 = unproject_raydir_0(uv_u_44, camera_model_32, is_ray_depth_28);
            points_16[int(1)] = make_float3 (depths_14.y) * raydir_25;
            float2  uv_88 = (pix_center_18 + make_float2 (0.0f, -1.0f) - _S1492) / _S1493;
            FixedArray<float, 8>  _S1499 = dist_coeffs_34;
            float2  uv_u_45;
            bool _S1500 = undistort_point_3(uv_88, &_S1499, int(12), &uv_u_45);
            if(!_S1500)
            {
                _S1491 = int(0);
                _S1490 = &points_16[int(1)];
                _S1489 = &points_16[int(0)];
                _S1488 = nullptr;
                _S1487 = nullptr;
                _S1486 = _S1496;
                break;
            }
            float3  raydir_26 = unproject_raydir_0(uv_u_45, camera_model_32, is_ray_depth_28);
            points_16[int(2)] = make_float3 (depths_14.z) * raydir_26;
            float2  uv_89 = (pix_center_18 + make_float2 (0.0f, 1.0f) - _S1492) / _S1493;
            FixedArray<float, 8>  _S1501 = dist_coeffs_34;
            float2  uv_u_46;
            bool _S1502 = undistort_point_3(uv_89, &_S1501, int(12), &uv_u_46);
            if(!_S1502)
            {
                _S1491 = int(0);
                _S1490 = &points_16[int(1)];
                _S1489 = &points_16[int(0)];
                _S1488 = nullptr;
                _S1487 = &points_16[int(2)];
                _S1486 = _S1496;
                break;
            }
            float3  raydir_27 = unproject_raydir_0(uv_u_46, camera_model_32, is_ray_depth_28);
            points_16[int(3)] = make_float3 (depths_14.w) * raydir_27;
            float2  uv_90 = (pix_center_18 + make_float2 (0.0f) * make_float2 (0.0f, 3.0f) - _S1492) / _S1493;
            FixedArray<float, 8>  _S1503 = dist_coeffs_34;
            float2  uv_u_47;
            bool _S1504 = undistort_point_3(uv_90, &_S1503, int(12), &uv_u_47);
            if(!_S1504)
            {
                _S1491 = int(0);
                _S1490 = &points_16[int(1)];
                _S1489 = &points_16[int(0)];
                _S1488 = &points_16[int(3)];
                _S1487 = &points_16[int(2)];
                _S1486 = _S1496;
                break;
            }
            float3  raydir_28 = unproject_raydir_0(uv_u_47, camera_model_32, is_ray_depth_28);
            _S1491 = int(1);
            _S1490 = &points_16[int(1)];
            _S1489 = &points_16[int(0)];
            _S1488 = &points_16[int(3)];
            _S1487 = &points_16[int(2)];
            _S1486 = raydir_28;
            break;
        }
        if(_S1491 != int(1))
        {
            _S1485 = 0.0f;
            break;
        }
        float3  normal_19 = cross_0(*_S1490 - *_S1489, - (*_S1488 - *_S1487));
        float3  normal_20;
        if((dot_0(normal_19, normal_19)) != 0.0f)
        {
            normal_20 = normalize_0(normal_19);
        }
        else
        {
            normal_20 = normal_19;
        }
        float3  _S1505;
        if((dot_0(gt_normal_6, gt_normal_6)) != 0.0f)
        {
            _S1505 = normalize_0(gt_normal_6);
        }
        else
        {
            _S1505 = gt_normal_6;
        }
        _S1485 = (1.0f - dot_0(normal_20, _S1505) + 0.00100000004749745f) / ((F32_max((dot_0(normal_20, - normalize_0(_S1486))), (0.0f))) + 0.00100000004749745f);
        break;
    }
    return _S1485;
}

struct s_bwd_prop_depth_normal_loss_Intermediates_3
{
    float2  _S1506;
    bool _S1507;
    float2  _S1508;
    bool _S1509;
    float2  _S1510;
    bool _S1511;
    float2  _S1512;
    bool _S1513;
    float2  _S1514;
    bool _S1515;
};

inline __device__ void depth_normal_loss_vjp_rational(float2  pix_center_19, float4  intrins_31, FixedArray<float, 8>  dist_coeffs_35, int camera_model_33, bool is_ray_depth_29, float4  depths_15, float3  gt_normal_7, float v_loss_3, float4  * v_depths_7, float3  * v_gt_normal_3)
{
    float2  _S1516 = make_float2 (0.0f);
    s_bwd_prop_depth_normal_loss_Intermediates_3 _S1517;
    (&_S1517)->_S1506 = _S1516;
    (&_S1517)->_S1507 = false;
    (&_S1517)->_S1508 = _S1516;
    (&_S1517)->_S1509 = false;
    (&_S1517)->_S1510 = _S1516;
    (&_S1517)->_S1511 = false;
    (&_S1517)->_S1512 = _S1516;
    (&_S1517)->_S1513 = false;
    (&_S1517)->_S1514 = _S1516;
    (&_S1517)->_S1515 = false;
    (&_S1517)->_S1508 = _S1516;
    (&_S1517)->_S1509 = false;
    (&_S1517)->_S1510 = _S1516;
    (&_S1517)->_S1511 = false;
    (&_S1517)->_S1512 = _S1516;
    (&_S1517)->_S1513 = false;
    (&_S1517)->_S1514 = _S1516;
    (&_S1517)->_S1515 = false;
    float2  _S1518 = float2 {intrins_31.z, intrins_31.w};
    float2  _S1519 = float2 {intrins_31.x, intrins_31.y};
    float2  uv_91 = (pix_center_19 + make_float2 (-1.0f, -0.0f) - _S1518) / _S1519;
    float2  _S1520 = _S1516;
    FixedArray<float, 8>  _S1521 = dist_coeffs_35;
    bool _S1522 = undistort_point_3(uv_91, &_S1521, int(12), &_S1520);
    (&_S1517)->_S1506 = _S1520;
    (&_S1517)->_S1507 = _S1522;
    bool _S1523 = !!_S1522;
    bool _runFlag_31;
    if(_S1523)
    {
        float2  uv_92 = (pix_center_19 + make_float2 (1.0f, -0.0f) - _S1518) / _S1519;
        float2  _S1524 = _S1516;
        FixedArray<float, 8>  _S1525 = dist_coeffs_35;
        bool _S1526 = undistort_point_3(uv_92, &_S1525, int(12), &_S1524);
        (&_S1517)->_S1508 = _S1524;
        (&_S1517)->_S1509 = _S1526;
        if(!_S1526)
        {
            _runFlag_31 = false;
        }
        else
        {
            _runFlag_31 = _S1523;
        }
        if(_runFlag_31)
        {
            float2  uv_93 = (pix_center_19 + make_float2 (0.0f, -1.0f) - _S1518) / _S1519;
            float2  _S1527 = _S1516;
            FixedArray<float, 8>  _S1528 = dist_coeffs_35;
            bool _S1529 = undistort_point_3(uv_93, &_S1528, int(12), &_S1527);
            (&_S1517)->_S1510 = _S1527;
            (&_S1517)->_S1511 = _S1529;
            if(!_S1529)
            {
                _runFlag_31 = false;
            }
            if(_runFlag_31)
            {
                float2  uv_94 = (pix_center_19 + make_float2 (0.0f, 1.0f) - _S1518) / _S1519;
                float2  _S1530 = _S1516;
                FixedArray<float, 8>  _S1531 = dist_coeffs_35;
                bool _S1532 = undistort_point_3(uv_94, &_S1531, int(12), &_S1530);
                (&_S1517)->_S1512 = _S1530;
                (&_S1517)->_S1513 = _S1532;
                if(!_S1532)
                {
                    _runFlag_31 = false;
                }
                if(_runFlag_31)
                {
                    float2  uv_95 = (pix_center_19 - _S1518) / _S1519;
                    float2  _S1533 = _S1516;
                    FixedArray<float, 8>  _S1534 = dist_coeffs_35;
                    bool _S1535 = undistort_point_3(uv_95, &_S1534, int(12), &_S1533);
                    (&_S1517)->_S1514 = _S1533;
                    (&_S1517)->_S1515 = _S1535;
                }
            }
        }
    }
    s_bwd_prop_depth_normal_loss_Intermediates_3 _S1536 = _S1517;
    float3  _S1537 = make_float3 (0.0f);
    bool _S1538 = !!_S1517._S1507;
    bool _runFlag_32;
    bool _runFlag_33;
    bool _runFlag_34;
    int _S1539;
    float3  raydir_29;
    float3  _S1540;
    float3  _S1541;
    float3  _S1542;
    float3  _S1543;
    FixedArray<float3 , 5>  points_17;
    if(_S1538)
    {
        float3  _S1544 = s_primal_ctx_unproject_raydir_0(_S1536._S1506, camera_model_33, is_ray_depth_29);
        float3  _S1545 = make_float3 (depths_15.x) * _S1544;
        if(!_S1536._S1509)
        {
            _runFlag_31 = false;
        }
        else
        {
            _runFlag_31 = _S1538;
        }
        if(_runFlag_31)
        {
            float3  _S1546 = s_primal_ctx_unproject_raydir_0(_S1536._S1508, camera_model_33, is_ray_depth_29);
            float3  _S1547 = make_float3 (depths_15.y) * _S1546;
            if(!_S1536._S1511)
            {
                _runFlag_32 = false;
            }
            else
            {
                _runFlag_32 = _runFlag_31;
            }
            if(_runFlag_32)
            {
                float3  _S1548 = s_primal_ctx_unproject_raydir_0(_S1536._S1510, camera_model_33, is_ray_depth_29);
                float3  _S1549 = make_float3 (depths_15.z) * _S1548;
                if(!_S1536._S1513)
                {
                    _runFlag_33 = false;
                }
                else
                {
                    _runFlag_33 = _runFlag_32;
                }
                if(_runFlag_33)
                {
                    float3  _S1550 = s_primal_ctx_unproject_raydir_0(_S1536._S1512, camera_model_33, is_ray_depth_29);
                    float3  _S1551 = make_float3 (depths_15.w) * _S1550;
                    if(!_S1536._S1515)
                    {
                        _runFlag_34 = false;
                    }
                    else
                    {
                        _runFlag_34 = _runFlag_33;
                    }
                    if(_runFlag_34)
                    {
                        float3  _S1552 = s_primal_ctx_unproject_raydir_0(_S1536._S1514, camera_model_33, is_ray_depth_29);
                        _S1539 = int(1);
                        raydir_29 = _S1552;
                    }
                    else
                    {
                        _S1539 = int(0);
                        raydir_29 = _S1550;
                    }
                    points_17[int(0)] = _S1545;
                    points_17[int(1)] = _S1547;
                    points_17[int(2)] = _S1549;
                    points_17[int(3)] = _S1551;
                    points_17[int(4)] = _S1537;
                    _S1540 = _S1550;
                }
                else
                {
                    _S1539 = int(0);
                    raydir_29 = _S1548;
                    points_17[int(0)] = _S1545;
                    points_17[int(1)] = _S1547;
                    points_17[int(2)] = _S1549;
                    points_17[int(3)] = _S1537;
                    points_17[int(4)] = _S1537;
                    _S1540 = _S1537;
                }
                _S1541 = _S1548;
            }
            else
            {
                _S1539 = int(0);
                raydir_29 = _S1546;
                points_17[int(0)] = _S1545;
                points_17[int(1)] = _S1547;
                points_17[int(2)] = _S1537;
                points_17[int(3)] = _S1537;
                points_17[int(4)] = _S1537;
                _runFlag_33 = false;
                _S1540 = _S1537;
                _S1541 = _S1537;
            }
            _S1542 = _S1546;
        }
        else
        {
            _S1539 = int(0);
            raydir_29 = _S1544;
            points_17[int(0)] = _S1545;
            points_17[int(1)] = _S1537;
            points_17[int(2)] = _S1537;
            points_17[int(3)] = _S1537;
            points_17[int(4)] = _S1537;
            _runFlag_32 = false;
            _runFlag_33 = false;
            _S1540 = _S1537;
            _S1541 = _S1537;
            _S1542 = _S1537;
        }
        _S1543 = _S1544;
    }
    else
    {
        _S1539 = int(0);
        points_17[int(0)] = _S1537;
        points_17[int(1)] = _S1537;
        points_17[int(2)] = _S1537;
        points_17[int(3)] = _S1537;
        points_17[int(4)] = _S1537;
        _runFlag_31 = false;
        _runFlag_32 = false;
        _runFlag_33 = false;
        _S1540 = _S1537;
        _S1541 = _S1537;
        _S1542 = _S1537;
        _S1543 = _S1537;
    }
    bool _S1553 = !(_S1539 != int(1));
    bool _S1554;
    float3  normal_21;
    float3  _S1555;
    float3  _S1556;
    float3  _S1557;
    float3  _S1558;
    float _S1559;
    float _S1560;
    float _S1561;
    float _S1562;
    if(_S1553)
    {
        float3  dx_8 = points_17[int(1)] - points_17[int(0)];
        float3  _S1563 = - (points_17[int(3)] - points_17[int(2)]);
        float3  _S1564 = s_primal_ctx_cross_0(dx_8, _S1563);
        bool _S1565 = (s_primal_ctx_dot_0(_S1564, _S1564)) != 0.0f;
        if(_S1565)
        {
            normal_21 = normalize_0(_S1564);
        }
        else
        {
            normal_21 = _S1564;
        }
        bool _S1566 = (s_primal_ctx_dot_0(gt_normal_7, gt_normal_7)) != 0.0f;
        if(_S1566)
        {
            _S1555 = normalize_0(gt_normal_7);
        }
        else
        {
            _S1555 = gt_normal_7;
        }
        float3  _S1567 = - normalize_0(raydir_29);
        float _S1568 = s_primal_ctx_dot_0(normal_21, _S1567);
        float _S1569 = 1.0f - s_primal_ctx_dot_0(normal_21, _S1555) + 0.00100000004749745f;
        float _S1570 = (F32_max((_S1568), (0.0f))) + 0.00100000004749745f;
        _S1559 = _S1570 * _S1570;
        _S1560 = _S1569;
        _S1561 = _S1570;
        _S1562 = _S1568;
        raydir_29 = normal_21;
        normal_21 = _S1567;
        _runFlag_34 = _S1566;
        _S1554 = _S1565;
        _S1556 = _S1564;
        _S1557 = dx_8;
        _S1558 = _S1563;
    }
    else
    {
        _S1559 = 0.0f;
        _S1560 = 0.0f;
        _S1561 = 0.0f;
        _S1562 = 0.0f;
        raydir_29 = _S1537;
        normal_21 = _S1537;
        _S1555 = _S1537;
        _runFlag_34 = false;
        _S1554 = false;
        _S1556 = _S1537;
        _S1557 = _S1537;
        _S1558 = _S1537;
    }
    float4  _S1571 = make_float4 (0.0f);
    if(_S1553)
    {
        float _S1572 = v_loss_3 / _S1559;
        float _S1573 = _S1560 * - _S1572;
        float s_diff_num_T_3 = _S1561 * _S1572;
        DiffPair_float_0 _S1574;
        (&_S1574)->primal_0 = _S1562;
        (&_S1574)->differential_0 = 0.0f;
        DiffPair_float_0 _S1575;
        (&_S1575)->primal_0 = 0.0f;
        (&_S1575)->differential_0 = 0.0f;
        _d_max_0(&_S1574, &_S1575, _S1573);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1576;
        (&_S1576)->primal_0 = raydir_29;
        (&_S1576)->differential_0 = _S1537;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1577;
        (&_S1577)->primal_0 = normal_21;
        (&_S1577)->differential_0 = _S1537;
        s_bwd_prop_dot_0(&_S1576, &_S1577, _S1574.differential_0);
        float _S1578 = - s_diff_num_T_3;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1579;
        (&_S1579)->primal_0 = raydir_29;
        (&_S1579)->differential_0 = _S1537;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1580;
        (&_S1580)->primal_0 = _S1555;
        (&_S1580)->differential_0 = _S1537;
        s_bwd_prop_dot_0(&_S1579, &_S1580, _S1578);
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1581 = _S1580;
        float3  _S1582 = _S1576.differential_0 + _S1579.differential_0;
        if(_runFlag_34)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1583;
            (&_S1583)->primal_0 = gt_normal_7;
            (&_S1583)->differential_0 = _S1537;
            s_bwd_normalize_impl_0(&_S1583, _S1581.differential_0);
            raydir_29 = _S1583.differential_0;
        }
        else
        {
            raydir_29 = _S1581.differential_0;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1584;
        (&_S1584)->primal_0 = gt_normal_7;
        (&_S1584)->differential_0 = _S1537;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1585;
        (&_S1585)->primal_0 = gt_normal_7;
        (&_S1585)->differential_0 = _S1537;
        s_bwd_prop_dot_0(&_S1584, &_S1585, 0.0f);
        float3  _S1586 = _S1585.differential_0 + _S1584.differential_0 + raydir_29;
        if(_S1554)
        {
            DiffPair_vectorx3Cfloatx2C3x3E_0 _S1587;
            (&_S1587)->primal_0 = _S1556;
            (&_S1587)->differential_0 = _S1537;
            s_bwd_normalize_impl_0(&_S1587, _S1582);
            raydir_29 = _S1587.differential_0;
        }
        else
        {
            raydir_29 = _S1582;
        }
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1588;
        (&_S1588)->primal_0 = _S1556;
        (&_S1588)->differential_0 = _S1537;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1589;
        (&_S1589)->primal_0 = _S1556;
        (&_S1589)->differential_0 = _S1537;
        s_bwd_prop_dot_0(&_S1588, &_S1589, 0.0f);
        float3  _S1590 = _S1589.differential_0 + _S1588.differential_0 + raydir_29;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1591;
        (&_S1591)->primal_0 = _S1557;
        (&_S1591)->differential_0 = _S1537;
        DiffPair_vectorx3Cfloatx2C3x3E_0 _S1592;
        (&_S1592)->primal_0 = _S1558;
        (&_S1592)->differential_0 = _S1537;
        s_bwd_prop_cross_0(&_S1591, &_S1592, _S1590);
        float3  s_diff_dy_T_8 = - _S1592.differential_0;
        float3  _S1593 = - s_diff_dy_T_8;
        float3  _S1594 = - _S1591.differential_0;
        FixedArray<float3 , 5>  _S1595;
        _S1595[int(0)] = _S1537;
        _S1595[int(1)] = _S1537;
        _S1595[int(2)] = _S1537;
        _S1595[int(3)] = _S1537;
        _S1595[int(4)] = _S1537;
        _S1595[int(2)] = _S1593;
        _S1595[int(3)] = s_diff_dy_T_8;
        _S1595[int(0)] = _S1594;
        _S1595[int(1)] = _S1591.differential_0;
        points_17[int(0)] = _S1595[int(0)];
        points_17[int(1)] = _S1595[int(1)];
        points_17[int(2)] = _S1595[int(2)];
        points_17[int(3)] = _S1595[int(3)];
        points_17[int(4)] = _S1595[int(4)];
        raydir_29 = _S1586;
    }
    else
    {
        points_17[int(0)] = _S1537;
        points_17[int(1)] = _S1537;
        points_17[int(2)] = _S1537;
        points_17[int(3)] = _S1537;
        points_17[int(4)] = _S1537;
        raydir_29 = _S1537;
    }
    float4  _S1596;
    if(_S1538)
    {
        if(_runFlag_31)
        {
            if(_runFlag_32)
            {
                if(_runFlag_33)
                {
                    FixedArray<float3 , 5>  _S1597 = points_17;
                    FixedArray<float3 , 5>  _S1598 = points_17;
                    FixedArray<float3 , 5>  _S1599 = points_17;
                    float3  _S1600 = _S1540 * points_17[int(3)];
                    float _S1601 = _S1600.x + _S1600.y + _S1600.z;
                    float4  _S1602 = _S1571;
                    *&((&_S1602)->w) = _S1601;
                    points_17[int(0)] = _S1537;
                    points_17[int(1)] = _S1537;
                    points_17[int(2)] = _S1537;
                    points_17[int(3)] = _S1537;
                    points_17[int(4)] = _S1537;
                    _S1540 = _S1599[int(2)];
                    normal_21 = _S1597[int(0)];
                    _S1555 = _S1598[int(1)];
                    _S1596 = _S1602;
                }
                else
                {
                    FixedArray<float3 , 5>  _S1603 = points_17;
                    FixedArray<float3 , 5>  _S1604 = points_17;
                    FixedArray<float3 , 5>  _S1605 = points_17;
                    FixedArray<float3 , 5>  _S1606 = points_17;
                    points_17[int(0)] = points_17[int(0)];
                    points_17[int(1)] = _S1603[int(1)];
                    points_17[int(2)] = _S1604[int(2)];
                    points_17[int(3)] = _S1605[int(3)];
                    points_17[int(4)] = _S1606[int(4)];
                    _S1540 = _S1537;
                    normal_21 = _S1537;
                    _S1555 = _S1537;
                    _S1596 = _S1571;
                }
                float3  _S1607 = _S1541 * (points_17[int(2)] + _S1540);
                float _S1608 = _S1607.x + _S1607.y + _S1607.z;
                float3  _S1609 = points_17[int(0)] + normal_21;
                float3  _S1610 = points_17[int(1)] + _S1555;
                float4  _S1611 = _S1571;
                *&((&_S1611)->z) = _S1608;
                float4  _S1612 = _S1596 + _S1611;
                points_17[int(0)] = _S1537;
                points_17[int(1)] = _S1537;
                points_17[int(2)] = _S1537;
                points_17[int(3)] = _S1537;
                points_17[int(4)] = _S1537;
                _S1540 = _S1610;
                _S1541 = _S1609;
                _S1596 = _S1612;
            }
            else
            {
                FixedArray<float3 , 5>  _S1613 = points_17;
                FixedArray<float3 , 5>  _S1614 = points_17;
                FixedArray<float3 , 5>  _S1615 = points_17;
                FixedArray<float3 , 5>  _S1616 = points_17;
                points_17[int(0)] = points_17[int(0)];
                points_17[int(1)] = _S1613[int(1)];
                points_17[int(2)] = _S1614[int(2)];
                points_17[int(3)] = _S1615[int(3)];
                points_17[int(4)] = _S1616[int(4)];
                _S1540 = _S1537;
                _S1541 = _S1537;
                _S1596 = _S1571;
            }
            float3  _S1617 = _S1542 * (points_17[int(1)] + _S1540);
            float _S1618 = _S1617.x + _S1617.y + _S1617.z;
            float3  _S1619 = points_17[int(0)] + _S1541;
            float4  _S1620 = _S1571;
            *&((&_S1620)->y) = _S1618;
            float4  _S1621 = _S1596 + _S1620;
            points_17[int(0)] = _S1537;
            points_17[int(1)] = _S1537;
            points_17[int(2)] = _S1537;
            points_17[int(3)] = _S1537;
            points_17[int(4)] = _S1537;
            _S1540 = _S1619;
            _S1596 = _S1621;
        }
        else
        {
            FixedArray<float3 , 5>  _S1622 = points_17;
            FixedArray<float3 , 5>  _S1623 = points_17;
            FixedArray<float3 , 5>  _S1624 = points_17;
            FixedArray<float3 , 5>  _S1625 = points_17;
            points_17[int(0)] = points_17[int(0)];
            points_17[int(1)] = _S1622[int(1)];
            points_17[int(2)] = _S1623[int(2)];
            points_17[int(3)] = _S1624[int(3)];
            points_17[int(4)] = _S1625[int(4)];
            _S1540 = _S1537;
            _S1596 = _S1571;
        }
        float3  _S1626 = _S1543 * (points_17[int(0)] + _S1540);
        float _S1627 = _S1626.x + _S1626.y + _S1626.z;
        float4  _S1628 = _S1571;
        *&((&_S1628)->x) = _S1627;
        _S1596 = _S1596 + _S1628;
    }
    else
    {
        _S1596 = _S1571;
    }
    *v_depths_7 = _S1596;
    *v_gt_normal_3 = raydir_29;
    return;
}


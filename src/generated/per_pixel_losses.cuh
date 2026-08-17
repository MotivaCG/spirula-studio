#pragma once

#include "generated/slang.cuh"

struct s_bwdCallableCtx_lerp_0
{
    float _S1;
    float _S2;
    float _S3;
};

struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};

inline __device__ void _d_lerp_0(DiffPair_float_0 * dpx_0, DiffPair_float_0 * dpy_0, DiffPair_float_0 * dps_0, float dOut_0)
{
    float _S4 = (1.0f - (*dps_0).primal_0) * dOut_0;
    dpx_0->primal_0 = (*dpx_0).primal_0;
    dpx_0->differential_0 = _S4;
    DiffPair_float_0 _S5 = *dpy_0;
    float _S6 = (*dps_0).primal_0 * dOut_0;
    dpy_0->primal_0 = (*dpy_0).primal_0;
    dpy_0->differential_0 = _S6;
    float _S7 = (_S5.primal_0 - (*dpx_0).primal_0) * dOut_0;
    dps_0->primal_0 = _S5.primal_0;
    dps_0->differential_0 = _S7;
    return;
}

inline __device__ void s_bwdProp_lerp_0(s_bwdCallableCtx_lerp_0 * ctx_0, float * d_x_0, float * d_y_0, float * d_s_0, float d_out_0)
{
    DiffPair_float_0 _S8;
    (&_S8)->primal_0 = ctx_0->_S1;
    DiffPair_float_0 _S9;
    (&_S9)->primal_0 = ctx_0->_S2;
    DiffPair_float_0 _S10;
    (&_S10)->primal_0 = ctx_0->_S3;
    _d_lerp_0(&_S8, &_S9, &_S10, d_out_0);
    *d_x_0 = (&_S8)->differential_0;
    *d_y_0 = (&_S9)->differential_0;
    *d_s_0 = (&_S10)->differential_0;
    return;
}

struct Tuple_0
{
    float value0_0;
};

inline __device__ Tuple_0 s_apply_rsqrt_0(float x_0)
{
    Tuple_0 _S11 = { (F32_rsqrt((x_0))) };
    return _S11;
}

struct s_bwdCallableCtx_rsqrt_0
{
    float _S12;
};

inline __device__ void _d_rsqrt_0(DiffPair_float_0 * dpx_1, float dOut_1)
{
    float _S13 = -0.5f / ((*dpx_1).primal_0 * (F32_sqrt(((*dpx_1).primal_0)))) * dOut_1;
    dpx_1->primal_0 = (*dpx_1).primal_0;
    dpx_1->differential_0 = _S13;
    return;
}

inline __device__ void s_bwdProp_rsqrt_0(s_bwdCallableCtx_rsqrt_0 * ctx_1, float * d_x_1, float d_out_1)
{
    DiffPair_float_0 _S14;
    (&_S14)->primal_0 = ctx_1->_S12;
    _d_rsqrt_0(&_S14, d_out_1);
    *d_x_1 = (&_S14)->differential_0;
    return;
}

struct Tuple_1
{
    float value0_1;
};

inline __device__ float dot_0(float3  x_1, float3  y_0)
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
        float result_1 = result_0 + _slang_vector_get_element(x_1, i_0) * _slang_vector_get_element(y_0, i_0);
        i_0 = i_0 + int(1);
        result_0 = result_1;
    }
    return result_0;
}

inline __device__ Tuple_1 s_apply_dot_0(float3  x_2, float3  y_1)
{
    Tuple_1 _S15 = { dot_0(x_2, y_1) };
    return _S15;
}

struct s_bwdCallableCtx_dot_0
{
    float3  _S16;
    float3  _S17;
};

struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    float3  primal_0;
    float3  differential_0;
};

inline __device__ void _d_dot_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_2, DiffPair_vectorx3Cfloatx2C3x3E_0 * dpy_1, float dOut_2)
{
    float3  x_d_result_0;
    *&((&x_d_result_0)->x) = (*dpy_1).primal_0.x * dOut_2;
    float3  y_d_result_0;
    *&((&y_d_result_0)->x) = (*dpx_2).primal_0.x * dOut_2;
    *&((&x_d_result_0)->y) = (*dpy_1).primal_0.y * dOut_2;
    *&((&y_d_result_0)->y) = (*dpx_2).primal_0.y * dOut_2;
    *&((&x_d_result_0)->z) = (*dpy_1).primal_0.z * dOut_2;
    *&((&y_d_result_0)->z) = (*dpx_2).primal_0.z * dOut_2;
    dpx_2->primal_0 = (*dpx_2).primal_0;
    dpx_2->differential_0 = x_d_result_0;
    dpy_1->primal_0 = (*dpy_1).primal_0;
    dpy_1->differential_0 = y_d_result_0;
    return;
}

inline __device__ void s_bwdProp_dot_0(s_bwdCallableCtx_dot_0 * ctx_2, float3  * d_x_2, float3  * d_y_1, float d_out_2)
{
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S18;
    (&_S18)->primal_0 = ctx_2->_S16;
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S19;
    (&_S19)->primal_0 = ctx_2->_S17;
    _d_dot_0(&_S18, &_S19, d_out_2);
    *d_x_2 = (&_S18)->differential_0;
    *d_y_1 = (&_S19)->differential_0;
    return;
}

struct s_bwdCallableCtx_abs_0
{
    float3  _S20;
};

inline __device__ void _d_abs_vector_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_3, float3  dOut_3)
{
    float3  _S21 = _slang_select(((*dpx_3).primal_0) > make_float3 (0.0f), make_float3 (1.0f),_slang_select(((*dpx_3).primal_0) == make_float3 (0.0f), make_float3 (0.0f),make_float3 (-1.0f))) * dOut_3;
    dpx_3->primal_0 = (*dpx_3).primal_0;
    dpx_3->differential_0 = _S21;
    return;
}

inline __device__ void s_bwdProp_abs_0(s_bwdCallableCtx_abs_0 * ctx_3, float3  * d_x_3, float3  d_out_3)
{
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S22;
    (&_S22)->primal_0 = ctx_3->_S20;
    _d_abs_vector_0(&_S22, d_out_3);
    *d_x_3 = (&_S22)->differential_0;
    return;
}

struct Tuple_2
{
    float value0_2;
};

inline __device__ Tuple_2 s_apply_sqrt_0(float x_3)
{
    Tuple_2 _S23 = { (F32_sqrt((x_3))) };
    return _S23;
}

struct s_bwdCallableCtx_sqrt_0
{
    float _S24;
};

inline __device__ void _d_sqrt_0(DiffPair_float_0 * dpx_4, float dOut_4)
{
    float _S25 = 0.5f / (F32_sqrt(((F32_max((1.00000001168609742e-07f), ((*dpx_4).primal_0)))))) * dOut_4;
    dpx_4->primal_0 = (*dpx_4).primal_0;
    dpx_4->differential_0 = _S25;
    return;
}

inline __device__ void s_bwdProp_sqrt_0(s_bwdCallableCtx_sqrt_0 * ctx_4, float * d_x_4, float d_out_4)
{
    DiffPair_float_0 _S26;
    (&_S26)->primal_0 = ctx_4->_S24;
    _d_sqrt_0(&_S26, d_out_4);
    *d_x_4 = (&_S26)->differential_0;
    return;
}

struct s_bwdCallableCtx_log10_0
{
    float _S27;
};

inline __device__ void _d_log10_0(DiffPair_float_0 * dpx_5, float dOut_5)
{
    float _S28 = 1.0f / ((*dpx_5).primal_0 * 2.30258512496948242f) * dOut_5;
    dpx_5->primal_0 = (*dpx_5).primal_0;
    dpx_5->differential_0 = _S28;
    return;
}

inline __device__ void s_bwdProp_log10_0(s_bwdCallableCtx_log10_0 * ctx_5, float * d_x_5, float d_out_5)
{
    DiffPair_float_0 _S29;
    (&_S29)->primal_0 = ctx_5->_S27;
    _d_log10_0(&_S29, d_out_5);
    *d_x_5 = (&_S29)->differential_0;
    return;
}

struct Tuple_3
{
    float value0_3;
};

inline __device__ Tuple_3 s_apply_log_0(float x_4)
{
    Tuple_3 _S30 = { (F32_log((x_4))) };
    return _S30;
}

struct s_bwdCallableCtx_log_0
{
    float _S31;
};

inline __device__ void _d_log_0(DiffPair_float_0 * dpx_6, float dOut_6)
{
    float _S32 = 1.0f / (*dpx_6).primal_0 * dOut_6;
    dpx_6->primal_0 = (*dpx_6).primal_0;
    dpx_6->differential_0 = _S32;
    return;
}

inline __device__ void s_bwdProp_log_0(s_bwdCallableCtx_log_0 * ctx_6, float * d_x_6, float d_out_6)
{
    DiffPair_float_0 _S33;
    (&_S33)->primal_0 = ctx_6->_S31;
    _d_log_0(&_S33, d_out_6);
    *d_x_6 = (&_S33)->differential_0;
    return;
}

struct Tuple_4
{
    float value0_4;
};

inline __device__ Tuple_4 s_apply_max_0(float x_5, float y_2)
{
    Tuple_4 _S34 = { (F32_max((x_5), (y_2))) };
    return _S34;
}

struct s_bwdCallableCtx_max_0
{
    float _S35;
    float _S36;
};

inline __device__ void _d_max_0(DiffPair_float_0 * dpx_7, DiffPair_float_0 * dpy_2, float dOut_7)
{
    DiffPair_float_0 _S37 = *dpx_7;
    float _S38;
    if(((*dpx_7).primal_0) > ((*dpy_2).primal_0))
    {
        _S38 = dOut_7;
    }
    else
    {
        if(((*dpx_7).primal_0) < ((*dpy_2).primal_0))
        {
            _S38 = 0.0f;
        }
        else
        {
            _S38 = 0.5f * dOut_7;
        }
    }
    dpx_7->primal_0 = _S37.primal_0;
    dpx_7->differential_0 = _S38;
    DiffPair_float_0 _S39 = *dpy_2;
    if(((*dpy_2).primal_0) > (_S37.primal_0))
    {
        _S38 = dOut_7;
    }
    else
    {
        if(((*dpy_2).primal_0) < ((*dpx_7).primal_0))
        {
            _S38 = 0.0f;
        }
        else
        {
            _S38 = 0.5f * dOut_7;
        }
    }
    dpy_2->primal_0 = _S39.primal_0;
    dpy_2->differential_0 = _S38;
    return;
}

inline __device__ void s_bwdProp_max_0(s_bwdCallableCtx_max_0 * ctx_7, float * d_x_7, float * d_y_2, float d_out_7)
{
    DiffPair_float_0 _S40;
    (&_S40)->primal_0 = ctx_7->_S35;
    DiffPair_float_0 _S41;
    (&_S41)->primal_0 = ctx_7->_S36;
    _d_max_0(&_S40, &_S41, d_out_7);
    *d_x_7 = (&_S40)->differential_0;
    *d_y_2 = (&_S41)->differential_0;
    return;
}

struct s_bwdCallableCtx_abs_1
{
    float _S42;
};

inline __device__ void _d_abs_0(DiffPair_float_0 * dpx_8, float dOut_8)
{
    float _S43 = _slang_select(((*dpx_8).primal_0) > 0.0f, 1.0f,_slang_select(((*dpx_8).primal_0) == 0.0f, 0.0f,-1.0f)) * dOut_8;
    dpx_8->primal_0 = (*dpx_8).primal_0;
    dpx_8->differential_0 = _S43;
    return;
}

inline __device__ void s_bwdProp_abs_1(s_bwdCallableCtx_abs_1 * ctx_8, float * d_x_8, float d_out_8)
{
    DiffPair_float_0 _S44;
    (&_S44)->primal_0 = ctx_8->_S42;
    _d_abs_0(&_S44, d_out_8);
    *d_x_8 = (&_S44)->differential_0;
    return;
}

struct Tuple_5
{
    float value0_5;
};

inline __device__ float clamp_0(float x_6, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_6), (minBound_0)))), (maxBound_0)));
}

inline __device__ Tuple_5 s_apply_clamp_0(float x_7, float minBound_1, float maxBound_1)
{
    Tuple_5 _S45 = { clamp_0(x_7, minBound_1, maxBound_1) };
    return _S45;
}

struct s_bwdCallableCtx_clamp_0
{
    float _S46;
    float _S47;
    float _S48;
};

inline __device__ void _d_clamp_0(DiffPair_float_0 * dpx_9, DiffPair_float_0 * dpMin_0, DiffPair_float_0 * dpMax_0, float dOut_9)
{
    DiffPair_float_0 _S49 = *dpx_9;
    bool _S50;
    if(((*dpx_9).primal_0) >= ((*dpMin_0).primal_0))
    {
        _S50 = ((*dpx_9).primal_0) <= ((*dpMax_0).primal_0);
    }
    else
    {
        _S50 = false;
    }
    float _S51;
    if(_S50)
    {
        _S51 = dOut_9;
    }
    else
    {
        _S51 = 0.0f;
    }
    dpx_9->primal_0 = _S49.primal_0;
    dpx_9->differential_0 = _S51;
    DiffPair_float_0 _S52 = *dpMin_0;
    if((_S49.primal_0) < ((*dpMin_0).primal_0))
    {
        _S51 = dOut_9;
    }
    else
    {
        _S51 = 0.0f;
    }
    dpMin_0->primal_0 = _S52.primal_0;
    dpMin_0->differential_0 = _S51;
    DiffPair_float_0 _S53 = *dpMax_0;
    if(((*dpx_9).primal_0) > ((*dpMax_0).primal_0))
    {
        _S51 = dOut_9;
    }
    else
    {
        _S51 = 0.0f;
    }
    dpMax_0->primal_0 = _S53.primal_0;
    dpMax_0->differential_0 = _S51;
    return;
}

inline __device__ void s_bwdProp_clamp_0(s_bwdCallableCtx_clamp_0 * ctx_9, float * d_x_9, float * d_minBound_0, float * d_maxBound_0, float d_out_9)
{
    DiffPair_float_0 _S54;
    (&_S54)->primal_0 = ctx_9->_S46;
    DiffPair_float_0 _S55;
    (&_S55)->primal_0 = ctx_9->_S47;
    DiffPair_float_0 _S56;
    (&_S56)->primal_0 = ctx_9->_S48;
    _d_clamp_0(&_S54, &_S55, &_S56, d_out_9);
    *d_x_9 = (&_S54)->differential_0;
    *d_minBound_0 = (&_S55)->differential_0;
    *d_maxBound_0 = (&_S56)->differential_0;
    return;
}

inline __device__ void dadd_0(FixedArray<float, 32>  * a_0, FixedArray<float, 32>  * b_0, FixedArray<float, 32>  * _S57)
{
    FixedArray<float, 32>  result_2;
    result_2[int(0)] = (*a_0)[int(0)] + (*b_0)[int(0)];
    result_2[int(1)] = (*a_0)[int(1)] + (*b_0)[int(1)];
    result_2[int(2)] = (*a_0)[int(2)] + (*b_0)[int(2)];
    result_2[int(3)] = (*a_0)[int(3)] + (*b_0)[int(3)];
    result_2[int(4)] = (*a_0)[int(4)] + (*b_0)[int(4)];
    result_2[int(5)] = (*a_0)[int(5)] + (*b_0)[int(5)];
    result_2[int(6)] = (*a_0)[int(6)] + (*b_0)[int(6)];
    result_2[int(7)] = (*a_0)[int(7)] + (*b_0)[int(7)];
    result_2[int(8)] = (*a_0)[int(8)] + (*b_0)[int(8)];
    result_2[int(9)] = (*a_0)[int(9)] + (*b_0)[int(9)];
    result_2[int(10)] = (*a_0)[int(10)] + (*b_0)[int(10)];
    result_2[int(11)] = (*a_0)[int(11)] + (*b_0)[int(11)];
    result_2[int(12)] = (*a_0)[int(12)] + (*b_0)[int(12)];
    result_2[int(13)] = (*a_0)[int(13)] + (*b_0)[int(13)];
    result_2[int(14)] = (*a_0)[int(14)] + (*b_0)[int(14)];
    result_2[int(15)] = (*a_0)[int(15)] + (*b_0)[int(15)];
    result_2[int(16)] = (*a_0)[int(16)] + (*b_0)[int(16)];
    result_2[int(17)] = (*a_0)[int(17)] + (*b_0)[int(17)];
    result_2[int(18)] = (*a_0)[int(18)] + (*b_0)[int(18)];
    result_2[int(19)] = (*a_0)[int(19)] + (*b_0)[int(19)];
    result_2[int(20)] = (*a_0)[int(20)] + (*b_0)[int(20)];
    result_2[int(21)] = (*a_0)[int(21)] + (*b_0)[int(21)];
    result_2[int(22)] = (*a_0)[int(22)] + (*b_0)[int(22)];
    result_2[int(23)] = (*a_0)[int(23)] + (*b_0)[int(23)];
    result_2[int(24)] = (*a_0)[int(24)] + (*b_0)[int(24)];
    result_2[int(25)] = (*a_0)[int(25)] + (*b_0)[int(25)];
    result_2[int(26)] = (*a_0)[int(26)] + (*b_0)[int(26)];
    result_2[int(27)] = (*a_0)[int(27)] + (*b_0)[int(27)];
    result_2[int(28)] = (*a_0)[int(28)] + (*b_0)[int(28)];
    result_2[int(29)] = (*a_0)[int(29)] + (*b_0)[int(29)];
    result_2[int(30)] = (*a_0)[int(30)] + (*b_0)[int(30)];
    result_2[int(31)] = (*a_0)[int(31)] + (*b_0)[int(31)];
    *_S57 = result_2;
    return;
}

inline __device__ void dzero_0(FixedArray<float, 32>  * _S58)
{
    (*_S58)[int(0)] = 0.0f;
    (*_S58)[int(1)] = 0.0f;
    (*_S58)[int(2)] = 0.0f;
    (*_S58)[int(3)] = 0.0f;
    (*_S58)[int(4)] = 0.0f;
    (*_S58)[int(5)] = 0.0f;
    (*_S58)[int(6)] = 0.0f;
    (*_S58)[int(7)] = 0.0f;
    (*_S58)[int(8)] = 0.0f;
    (*_S58)[int(9)] = 0.0f;
    (*_S58)[int(10)] = 0.0f;
    (*_S58)[int(11)] = 0.0f;
    (*_S58)[int(12)] = 0.0f;
    (*_S58)[int(13)] = 0.0f;
    (*_S58)[int(14)] = 0.0f;
    (*_S58)[int(15)] = 0.0f;
    (*_S58)[int(16)] = 0.0f;
    (*_S58)[int(17)] = 0.0f;
    (*_S58)[int(18)] = 0.0f;
    (*_S58)[int(19)] = 0.0f;
    (*_S58)[int(20)] = 0.0f;
    (*_S58)[int(21)] = 0.0f;
    (*_S58)[int(22)] = 0.0f;
    (*_S58)[int(23)] = 0.0f;
    (*_S58)[int(24)] = 0.0f;
    (*_S58)[int(25)] = 0.0f;
    (*_S58)[int(26)] = 0.0f;
    (*_S58)[int(27)] = 0.0f;
    (*_S58)[int(28)] = 0.0f;
    (*_S58)[int(29)] = 0.0f;
    (*_S58)[int(30)] = 0.0f;
    (*_S58)[int(31)] = 0.0f;
    return;
}

struct DiffPair_arrayx3Cfloatx2C32x3E_0
{
    FixedArray<float, 32>  primal_0;
    FixedArray<float, 32>  differential_0;
};

struct s_paramCtx_s_bwdCallableCtx_per_pixel_losses_reduce_0
{
    FixedArray<float, 32>  value0_6;
    FixedArray<float, 20>  value1_0;
};

struct s_bwdCallableCtx_per_pixel_losses_reduce_0
{
    s_paramCtx_s_bwdCallableCtx_per_pixel_losses_reduce_0 value0_7;
};

inline __device__ void s_bwdProp_per_pixel_losses_reduce_0(s_bwdCallableCtx_per_pixel_losses_reduce_0 * _S59, FixedArray<float, 32>  * _S60, FixedArray<float, 14>  * _S61)
{
    float _S62 = (&_S59->value0_7)->value0_6[int(0)];
    Tuple_4 _S63 = s_apply_max_0((&_S59->value0_7)->value0_6[int(31)], 1.0f);
    s_bwdCallableCtx_max_0 _S64;
    (&_S64)->_S35 = (&_S59->value0_7)->value0_6[int(31)];
    (&_S64)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S65 = _S64;
    float _S66 = _S63.value0_4 * _S63.value0_4;
    float _S67 = (&_S59->value0_7)->value0_6[int(1)];
    Tuple_4 _S68 = s_apply_max_0((&_S59->value0_7)->value0_6[int(21)], 1.0f);
    s_bwdCallableCtx_max_0 _S69;
    (&_S69)->_S35 = (&_S59->value0_7)->value0_6[int(21)];
    (&_S69)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S70 = _S69;
    float _S71 = _S68.value0_4 * _S68.value0_4;
    s_bwdCallableCtx_log10_0 _S72;
    (&_S72)->_S27 = (&_S59->value0_7)->value0_6[int(1)] / _S68.value0_4;
    s_bwdCallableCtx_log10_0 _S73 = _S72;
    float _S74 = (&_S59->value0_7)->value0_6[int(22)];
    bool _S75 = ((&_S59->value0_7)->value0_6[int(22)]) > 0.0f;
    bool _S76;
    if(_S75)
    {
        _S76 = ((&_S59->value0_7)->value0_6[int(3)]) != 0.0f;
    }
    else
    {
        _S76 = false;
    }
    float _S77;
    float _S78;
    float _S79;
    float _S80;
    float _S81;
    float _S82;
    float _S83;
    float _S84;
    float _S85;
    float _S86;
    float _S87;
    float _S88;
    s_bwdCallableCtx_clamp_0 _S89;
    s_bwdCallableCtx_sqrt_0 _S90;
    s_bwdCallableCtx_max_0 _S91;
    if(_S76)
    {
        float _S92 = (&_S59->value0_7)->value0_6[int(2)] * (&_S59->value0_7)->value0_6[int(3)];
        float _S93 = _S74 * _S74;
        float _S94 = (&_S59->value0_7)->value0_6[int(6)] - _S92 / _S74;
        float _S95 = (&_S59->value0_7)->value0_6[int(2)] * (&_S59->value0_7)->value0_6[int(2)];
        float _S96 = (&_S59->value0_7)->value0_6[int(4)] - _S95 / _S74;
        float _S97 = (&_S59->value0_7)->value0_6[int(3)] * (&_S59->value0_7)->value0_6[int(3)];
        float _S98 = (&_S59->value0_7)->value0_6[int(5)] - _S97 / _S74;
        float _S99 = _S96 * _S98 + 1.0f;
        Tuple_4 _S100 = s_apply_max_0(9.999999960041972e-13f, _S99);
        s_bwdCallableCtx_max_0 _S101;
        (&_S101)->_S35 = 9.999999960041972e-13f;
        (&_S101)->_S36 = _S99;
        Tuple_2 _S102 = s_apply_sqrt_0(_S100.value0_4);
        s_bwdCallableCtx_sqrt_0 _S103;
        (&_S103)->_S24 = _S100.value0_4;
        float _S104 = _S102.value0_2 * _S102.value0_2;
        s_bwdCallableCtx_clamp_0 _S105;
        (&_S105)->_S46 = 1.0f - _S94 / _S102.value0_2;
        (&_S105)->_S47 = 0.0f;
        (&_S105)->_S48 = 2.0f;
        _S77 = (&_S59->value0_7)->value1_0[int(6)];
        _S89 = _S105;
        _S78 = _S104;
        _S79 = _S94;
        _S80 = _S102.value0_2;
        _S90 = _S103;
        _S91 = _S101;
        _S81 = _S96;
        _S82 = _S98;
        _S83 = _S93;
        _S84 = _S97;
        _S85 = (&_S59->value0_7)->value0_6[int(3)];
        _S86 = _S95;
        _S87 = (&_S59->value0_7)->value0_6[int(2)];
        _S88 = _S92;
    }
    else
    {
        _S77 = 0.0f;
        (&_S89)->_S46 = 0.0f;
        (&_S89)->_S47 = 0.0f;
        (&_S89)->_S48 = 0.0f;
        _S78 = 0.0f;
        _S79 = 0.0f;
        _S80 = 0.0f;
        (&_S90)->_S24 = 0.0f;
        (&_S91)->_S35 = 0.0f;
        (&_S91)->_S36 = 0.0f;
        _S81 = 0.0f;
        _S82 = 0.0f;
        _S83 = 0.0f;
        _S84 = 0.0f;
        _S85 = 0.0f;
        _S86 = 0.0f;
        _S87 = 0.0f;
        _S88 = 0.0f;
    }
    float _S106 = (&_S59->value0_7)->value0_6[int(7)];
    Tuple_4 _S107 = s_apply_max_0((&_S59->value0_7)->value0_6[int(23)], 1.0f);
    s_bwdCallableCtx_max_0 _S108;
    (&_S108)->_S35 = (&_S59->value0_7)->value0_6[int(23)];
    (&_S108)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S109 = _S108;
    float _S110 = _S107.value0_4 * _S107.value0_4;
    float _S111 = (&_S59->value0_7)->value0_6[int(8)];
    Tuple_4 _S112 = s_apply_max_0((&_S59->value0_7)->value0_6[int(24)], 1.0f);
    s_bwdCallableCtx_max_0 _S113;
    (&_S113)->_S35 = (&_S59->value0_7)->value0_6[int(24)];
    (&_S113)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S114 = _S113;
    float _S115 = _S112.value0_4 * _S112.value0_4;
    float _S116 = float((I32_max((int(((&_S59->value0_7)->value0_6[int(23)]) > 0.5f) + int(((&_S59->value0_7)->value0_6[int(24)]) > 0.5f)), (int(1)))));
    float _S117 = (&_S59->value0_7)->value0_6[int(9)] + (&_S59->value0_7)->value0_6[int(10)];
    Tuple_4 _S118 = s_apply_max_0((&_S59->value0_7)->value0_6[int(26)], 1.0f);
    s_bwdCallableCtx_max_0 _S119;
    (&_S119)->_S35 = (&_S59->value0_7)->value0_6[int(26)];
    (&_S119)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S120 = _S119;
    float _S121 = _S118.value0_4 * _S118.value0_4;
    float _S122 = (&_S59->value0_7)->value0_6[int(11)];
    Tuple_4 _S123 = s_apply_max_0((&_S59->value0_7)->value0_6[int(25)], 1.0f);
    s_bwdCallableCtx_max_0 _S124;
    (&_S124)->_S35 = (&_S59->value0_7)->value0_6[int(25)];
    (&_S124)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S125 = _S124;
    float _S126 = _S123.value0_4 * _S123.value0_4;
    float _S127 = (&_S59->value0_7)->value0_6[int(12)];
    Tuple_4 _S128 = s_apply_max_0((&_S59->value0_7)->value0_6[int(20)], 1.0f);
    s_bwdCallableCtx_max_0 _S129;
    (&_S129)->_S35 = (&_S59->value0_7)->value0_6[int(20)];
    (&_S129)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S130 = _S129;
    float _S131 = _S128.value0_4 * _S128.value0_4;
    float _S132 = (&_S59->value0_7)->value0_6[int(13)];
    float _S133 = (&_S59->value0_7)->value0_6[int(14)];
    float _S134 = (&_S59->value0_7)->value0_6[int(15)];
    float _S135 = (&_S59->value0_7)->value0_6[int(16)];
    Tuple_4 _S136 = s_apply_max_0((&_S59->value0_7)->value0_6[int(27)], 1.0f);
    s_bwdCallableCtx_max_0 _S137;
    (&_S137)->_S35 = (&_S59->value0_7)->value0_6[int(27)];
    (&_S137)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S138 = _S137;
    float _S139 = _S136.value0_4 * _S136.value0_4;
    float _S140 = (&_S59->value0_7)->value0_6[int(17)];
    Tuple_4 _S141 = s_apply_max_0((&_S59->value0_7)->value0_6[int(28)], 1.0f);
    s_bwdCallableCtx_max_0 _S142;
    (&_S142)->_S35 = (&_S59->value0_7)->value0_6[int(28)];
    (&_S142)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S143 = _S142;
    float _S144 = _S141.value0_4 * _S141.value0_4;
    float _S145 = (&_S59->value0_7)->value0_6[int(18)];
    Tuple_4 _S146 = s_apply_max_0((&_S59->value0_7)->value0_6[int(29)], 1.0f);
    s_bwdCallableCtx_max_0 _S147;
    (&_S147)->_S35 = (&_S59->value0_7)->value0_6[int(29)];
    (&_S147)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S148 = _S147;
    float _S149 = _S146.value0_4 * _S146.value0_4;
    float _S150 = (&_S59->value0_7)->value0_6[int(19)];
    Tuple_4 _S151 = s_apply_max_0((&_S59->value0_7)->value0_6[int(30)], 1.0f);
    s_bwdCallableCtx_max_0 _S152;
    (&_S152)->_S35 = (&_S59->value0_7)->value0_6[int(30)];
    (&_S152)->_S36 = 1.0f;
    s_bwdCallableCtx_max_0 _S153 = _S152;
    float _S154 = _S151.value0_4 * _S151.value0_4;
    FixedArray<float, 32>  _S155;
    dzero_0(&_S155);
    FixedArray<float, 32>  _S156 = _S155;
    float _S157 = (*_S61)[int(0)];
    float _S158 = (*_S61)[int(1)];
    float _S159 = (*_S61)[int(2)];
    float _S160 = (*_S61)[int(13)] / _S154;
    float _S161 = _S150 * - _S160;
    float _S162 = _S151.value0_4 * _S160;
    float _S163 = 0.0f;
    float _S164 = 0.0f;
    s_bwdCallableCtx_max_0 _S165 = _S153;
    s_bwdProp_max_0(&_S165, &_S163, &_S164, _S161);
    float _S166 = (*_S61)[int(12)] / _S149;
    float _S167 = _S145 * - _S166;
    float _S168 = _S146.value0_4 * _S166;
    float _S169 = 0.0f;
    float _S170 = 0.0f;
    s_bwdCallableCtx_max_0 _S171 = _S148;
    s_bwdProp_max_0(&_S171, &_S169, &_S170, _S167);
    float _S172 = (*_S61)[int(11)] / _S144;
    float _S173 = _S140 * - _S172;
    float _S174 = _S141.value0_4 * _S172;
    float _S175 = 0.0f;
    float _S176 = 0.0f;
    s_bwdCallableCtx_max_0 _S177 = _S143;
    s_bwdProp_max_0(&_S177, &_S175, &_S176, _S173);
    float _S178 = (*_S61)[int(10)] / _S139;
    float _S179 = _S135 * - _S178;
    float _S180 = _S136.value0_4 * _S178;
    float _S181 = 0.0f;
    float _S182 = 0.0f;
    s_bwdCallableCtx_max_0 _S183 = _S138;
    s_bwdProp_max_0(&_S183, &_S181, &_S182, _S179);
    float _S184 = (*_S61)[int(9)] / _S131;
    float _S185 = _S128.value0_4 * _S184;
    float _S186 = (*_S61)[int(8)] / _S131;
    float _S187 = _S128.value0_4 * _S186;
    float _S188 = (*_S61)[int(7)] / _S131;
    float _S189 = _S128.value0_4 * _S188;
    float _S190 = (*_S61)[int(6)] / _S131;
    float _S191 = _S128.value0_4 * _S190;
    float _S192 = _S134 * - _S184 + _S133 * - _S186 + _S132 * - _S188 + _S127 * - _S190;
    float _S193 = 0.0f;
    float _S194 = 0.0f;
    s_bwdCallableCtx_max_0 _S195 = _S130;
    s_bwdProp_max_0(&_S195, &_S193, &_S194, _S192);
    float _S196 = (*_S61)[int(5)] / _S126;
    float _S197 = _S122 * - _S196;
    float _S198 = _S123.value0_4 * _S196;
    float _S199 = 0.0f;
    float _S200 = 0.0f;
    s_bwdCallableCtx_max_0 _S201 = _S125;
    s_bwdProp_max_0(&_S201, &_S199, &_S200, _S197);
    float _S202 = (*_S61)[int(4)] / _S121;
    float _S203 = _S117 * - _S202;
    float _S204 = _S118.value0_4 * _S202;
    float _S205 = 0.0f;
    float _S206 = 0.0f;
    s_bwdCallableCtx_max_0 _S207 = _S120;
    s_bwdProp_max_0(&_S207, &_S205, &_S206, _S203);
    float _S208 = (*_S61)[int(3)] / _S116;
    float _S209 = _S208 / _S115;
    float _S210 = _S111 * - _S209;
    float _S211 = _S112.value0_4 * _S209;
    float _S212 = 0.0f;
    float _S213 = 0.0f;
    s_bwdCallableCtx_max_0 _S214 = _S114;
    s_bwdProp_max_0(&_S214, &_S212, &_S213, _S210);
    float _S215 = _S208 / _S110;
    float _S216 = _S106 * - _S215;
    float _S217 = _S107.value0_4 * _S215;
    float _S218 = 0.0f;
    float _S219 = 0.0f;
    s_bwdCallableCtx_max_0 _S220 = _S109;
    s_bwdProp_max_0(&_S220, &_S218, &_S219, _S216);
    FixedArray<float, 32>  _S221 = _S155;
    _S221[int(30)] = _S163;
    _S221[int(19)] = _S162;
    _S221[int(29)] = _S169;
    _S221[int(18)] = _S168;
    _S221[int(28)] = _S175;
    _S221[int(17)] = _S174;
    _S221[int(27)] = _S181;
    _S221[int(16)] = _S180;
    _S221[int(15)] = _S185;
    _S221[int(14)] = _S187;
    _S221[int(13)] = _S189;
    _S221[int(20)] = _S193;
    _S221[int(12)] = _S191;
    _S221[int(25)] = _S199;
    _S221[int(11)] = _S198;
    _S221[int(26)] = _S205;
    _S221[int(10)] = _S204;
    _S221[int(9)] = _S204;
    _S221[int(24)] = _S212;
    _S221[int(8)] = _S211;
    _S221[int(23)] = _S218;
    _S221[int(7)] = _S217;
    FixedArray<float, 32>  _S222 = _S155;
    FixedArray<float, 32>  _S223 = _S221;
    FixedArray<float, 32>  _S224;
    dadd_0(&_S222, &_S223, &_S224);
    FixedArray<float, 32>  _S225 = _S224;
    FixedArray<float, 32>  _S226;
    if(_S76)
    {
        float _S227 = _S77 * _S159;
        float _S228 = 0.0f;
        float _S229 = 0.0f;
        float _S230 = 0.0f;
        s_bwdCallableCtx_clamp_0 _S231 = _S89;
        s_bwdProp_clamp_0(&_S231, &_S228, &_S229, &_S230, _S227);
        float _S232 = - _S228 / _S78;
        float _S233 = _S79 * - _S232;
        float _S234 = _S80 * _S232;
        float _S235 = 0.0f;
        s_bwdCallableCtx_sqrt_0 _S236 = _S90;
        s_bwdProp_sqrt_0(&_S236, &_S235, _S233);
        float _S237 = 0.0f;
        float _S238 = 0.0f;
        s_bwdCallableCtx_max_0 _S239 = _S91;
        s_bwdProp_max_0(&_S239, &_S237, &_S238, _S235);
        float _S240 = _S81 * _S238;
        float _S241 = _S82 * _S238;
        float _S242 = - _S240 / _S83;
        float _S243 = _S85 * (_S74 * _S242);
        float _S244 = - _S241 / _S83;
        float _S245 = _S87 * (_S74 * _S244);
        float _S246 = - _S234 / _S83;
        float _S247 = _S74 * _S246;
        float _S248 = _S243 + _S243 + _S87 * _S247;
        float _S249 = _S245 + _S245 + _S85 * _S247;
        float _S250 = _S84 * - _S242 + _S86 * - _S244 + _S88 * - _S246;
        FixedArray<float, 32>  _S251 = _S156;
        _S251[int(5)] = _S240;
        _S251[int(4)] = _S241;
        _S251[int(3)] = _S248;
        _S251[int(2)] = _S249;
        _S251[int(6)] = _S234;
        FixedArray<float, 32>  _S252 = _S225;
        FixedArray<float, 32>  _S253 = _S251;
        FixedArray<float, 32>  _S254;
        dadd_0(&_S252, &_S253, &_S254);
        _S226 = _S254;
        _S77 = _S250;
    }
    else
    {
        _S226 = _S225;
        _S77 = 0.0f;
    }
    if(_S75)
    {
        FixedArray<float, 32>  _S255 = _S156;
        _S255[int(3)] = 0.0f;
        FixedArray<float, 32>  _S256 = _S226;
        FixedArray<float, 32>  _S257 = _S255;
        FixedArray<float, 32>  _S258;
        dadd_0(&_S256, &_S257, &_S258);
        _S226 = _S258;
    }
    else
    {
    }
    float _S259 = -10.0f * _S158;
    float _S260 = 0.0f;
    s_bwdCallableCtx_log10_0 _S261 = _S73;
    s_bwdProp_log10_0(&_S261, &_S260, _S259);
    float _S262 = _S260 / _S71;
    float _S263 = _S67 * - _S262;
    float _S264 = _S68.value0_4 * _S262;
    float _S265 = 0.0f;
    float _S266 = 0.0f;
    s_bwdCallableCtx_max_0 _S267 = _S70;
    s_bwdProp_max_0(&_S267, &_S265, &_S266, _S263);
    float _S268 = _S157 / _S66;
    float _S269 = _S62 * - _S268;
    float _S270 = _S63.value0_4 * _S268;
    float _S271 = 0.0f;
    float _S272 = 0.0f;
    s_bwdCallableCtx_max_0 _S273 = _S65;
    s_bwdProp_max_0(&_S273, &_S271, &_S272, _S269);
    FixedArray<float, 32>  _S274 = _S156;
    _S274[int(22)] = _S77;
    _S274[int(21)] = _S265;
    _S274[int(1)] = _S264;
    _S274[int(31)] = _S271;
    _S274[int(0)] = _S270;
    FixedArray<float, 32>  _S275 = _S226;
    FixedArray<float, 32>  _S276 = _S274;
    FixedArray<float, 32>  _S277;
    dadd_0(&_S275, &_S276, &_S277);
    *_S60 = _S277;
    return;
}

inline __device__ void _S278(DiffPair_arrayx3Cfloatx2C32x3E_0 * _S279, FixedArray<float, 20>  * _S280, FixedArray<float, 14>  * _S281)
{
    s_paramCtx_s_bwdCallableCtx_per_pixel_losses_reduce_0 _S282;
    (&_S282)->value0_6 = _S279->primal_0;
    (&_S282)->value1_0 = *_S280;
    s_bwdCallableCtx_per_pixel_losses_reduce_0 _S283;
    (&_S283)->value0_7 = _S282;
    s_bwdProp_per_pixel_losses_reduce_0(&_S283, &_S279->differential_0, _S281);
    return;
}

struct s_paramCtx_s_bwdCallableCtx_per_pixel_losses_0
{
    float3  value0_8;
    float3  value1_1;
    float value2_0;
    float value3_0;
    float3  value4_0;
    float3  value5_0;
    float3  value6_0;
    float value7_0;
    float value11_0;
    float3  value12_0;
    bool value13_0;
    bool value14_0;
    FixedArray<float, 20>  value15_0;
};

struct s_bwdCallableCtx_per_pixel_losses_0
{
    s_paramCtx_s_bwdCallableCtx_per_pixel_losses_0 value0_9;
};

struct Tuple_6
{
    float3  value0_10;
};

inline __device__ Tuple_6 s_apply_rgb_to_yuv_0(float3  _S284)
{
    float _S285 = _S284.x;
    float _S286 = _S284.y;
    float _S287 = _S284.z;
    Tuple_6 _S288;
    (&_S288)->value0_10 = make_float3 (0.29899999499320984f * _S285 + 0.58700001239776611f * _S286 + 0.11400000005960464f * _S287, -0.14712999761104584f * _S285 - 0.28885999321937561f * _S286 + 0.43599998950958252f * _S287, 0.61500000953674316f * _S285 - 0.51498997211456299f * _S286 - 0.10001000016927719f * _S287);
    return _S288;
}

struct s_paramCtx_s_bwdCallableCtx_l1_loss_0
{
    float3  value0_11;
    float3  value1_2;
};

struct Tuple_7
{
    float value0_12;
};

inline __device__ Tuple_7 s_apply_l2_loss_0(float3  _S289, float3  _S290)
{
    float3  _S291 = _S290 - _S289;
    Tuple_7 _S292;
    (&_S292)->value0_12 = s_apply_dot_0(_S291, _S291).value0_1 * 0.3333333432674408f;
    return _S292;
}

struct s_paramCtx_s_bwdCallableCtx_l2_loss_0
{
    float3  value0_13;
    float3  value1_3;
};

struct Tuple_8
{
    float3  value0_14;
};

inline __device__ Tuple_8 s_apply_normalize_normal_0(float3  _S293, bool * mask_0)
{
    bool _S294 = *mask_0;
    Tuple_1 _S295 = s_apply_dot_0(_S293, _S293);
    bool _S296 = (_S295.value0_1) == 0.0f;
    float3  _S297;
    bool _S298;
    if(_S296)
    {
        _S297 = make_float3 (0.0f);
        _S298 = false;
    }
    else
    {
        _S298 = _S294;
    }
    bool _S299 = !_S296;
    if(_S299)
    {
        _S297 = _S293 * make_float3 (s_apply_rsqrt_0(_S295.value0_1).value0_0);
    }
    else
    {
    }
    *mask_0 = _S298;
    Tuple_8 _S300;
    (&_S300)->value0_14 = _S297;
    return _S300;
}

struct s_paramCtx_s_bwdCallableCtx_normalize_normal_0
{
    float3  value0_15;
};

struct s_paramCtx_s_bwdCallableCtx_normal_loss_0
{
    float3  value0_16;
    float3  value1_4;
};

struct s_paramCtx_s_bwdCallableCtx_alpha_loss_0
{
    float value0_17;
    float value1_5;
};

inline __device__ void s_bwdProp_mean3_0(float3  * _S301, float _S302)
{
    float _S303 = 0.3333333432674408f * _S302;
    *_S301 = make_float3 (_S303, _S303, _S303);
    return;
}

struct s_bwdCallableCtx_alpha_loss_0
{
    s_paramCtx_s_bwdCallableCtx_alpha_loss_0 value0_18;
};

struct s_paramCtx_s_bwdCallableCtx_bce_loss_0
{
    float value0_19;
    float value1_6;
};

struct s_bwdCallableCtx_bce_loss_0
{
    s_paramCtx_s_bwdCallableCtx_bce_loss_0 value0_20;
};

inline __device__ void s_bwdProp_bce_loss_0(s_bwdCallableCtx_bce_loss_0 * _S304, float * _S305, float * _S306, float _S307)
{
    float _S308 = 1.0f - (&_S304->value0_20)->value0_19;
    Tuple_4 _S309 = s_apply_max_0(_S308, 9.99999997475242708e-07f);
    s_bwdCallableCtx_max_0 _S310;
    (&_S310)->_S35 = _S308;
    (&_S310)->_S36 = 9.99999997475242708e-07f;
    Tuple_3 _S311 = s_apply_log_0(_S309.value0_4);
    s_bwdCallableCtx_log_0 _S312;
    (&_S312)->_S31 = _S309.value0_4;
    Tuple_4 _S313 = s_apply_max_0((&_S304->value0_20)->value0_19, 9.99999997475242708e-07f);
    s_bwdCallableCtx_max_0 _S314;
    (&_S314)->_S35 = (&_S304->value0_20)->value0_19;
    (&_S314)->_S36 = 9.99999997475242708e-07f;
    Tuple_3 _S315 = s_apply_log_0(_S313.value0_4);
    s_bwdCallableCtx_log_0 _S316;
    (&_S316)->_S31 = _S313.value0_4;
    s_bwdCallableCtx_lerp_0 _S317;
    (&_S317)->_S1 = _S311.value0_3;
    (&_S317)->_S2 = _S315.value0_3;
    (&_S317)->_S3 = (&_S304->value0_20)->value1_6;
    float _S318 = - _S307;
    float _S319 = 0.0f;
    float _S320 = 0.0f;
    float _S321 = 0.0f;
    s_bwdCallableCtx_lerp_0 _S322 = _S317;
    s_bwdProp_lerp_0(&_S322, &_S319, &_S320, &_S321, _S318);
    float _S323 = 0.0f;
    s_bwdCallableCtx_log_0 _S324 = _S316;
    s_bwdProp_log_0(&_S324, &_S323, _S320);
    float _S325 = 0.0f;
    float _S326 = 0.0f;
    s_bwdCallableCtx_max_0 _S327 = _S314;
    s_bwdProp_max_0(&_S327, &_S325, &_S326, _S323);
    float _S328 = 0.0f;
    s_bwdCallableCtx_log_0 _S329 = _S312;
    s_bwdProp_log_0(&_S329, &_S328, _S319);
    float _S330 = 0.0f;
    float _S331 = 0.0f;
    s_bwdCallableCtx_max_0 _S332 = _S310;
    s_bwdProp_max_0(&_S332, &_S330, &_S331, _S328);
    *_S305 = _S325 + - _S330;
    *_S306 = _S321;
    return;
}

inline __device__ void s_bwdProp_alpha_loss_0(s_bwdCallableCtx_alpha_loss_0 * _S333, float * _S334, float * _S335, float _S336)
{
    Tuple_4 _S337 = s_apply_max_0((&_S333->value0_18)->value0_17, (&_S333->value0_18)->value1_5);
    s_bwdCallableCtx_max_0 _S338;
    (&_S338)->_S35 = (&_S333->value0_18)->value0_17;
    (&_S338)->_S36 = (&_S333->value0_18)->value1_5;
    s_paramCtx_s_bwdCallableCtx_bce_loss_0 _S339;
    (&_S339)->value0_19 = _S337.value0_4;
    (&_S339)->value1_6 = (&_S333->value0_18)->value1_5;
    float _S340 = 0.0f;
    float _S341 = 0.0f;
    s_bwdCallableCtx_bce_loss_0 _S342;
    (&_S342)->value0_20 = _S339;
    s_bwdProp_bce_loss_0(&_S342, &_S340, &_S341, _S336);
    float _S343 = 0.0f;
    float _S344 = 0.0f;
    s_bwdCallableCtx_max_0 _S345 = _S338;
    s_bwdProp_max_0(&_S345, &_S343, &_S344, _S340);
    float _S346 = _S341 + _S344;
    *_S334 = _S343;
    *_S335 = _S346;
    return;
}

struct s_bwdCallableCtx_normal_loss_0
{
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 value0_21;
};

inline __device__ void s_bwdProp_normal_loss_0(s_bwdCallableCtx_normal_loss_0 * _S347, float3  * _S348, float3  * _S349, float _S350)
{
    Tuple_1 _S351 = s_apply_dot_0((&_S347->value0_21)->value0_16, (&_S347->value0_21)->value1_4);
    s_bwdCallableCtx_dot_0 _S352;
    (&_S352)->_S16 = (&_S347->value0_21)->value0_16;
    (&_S352)->_S17 = (&_S347->value0_21)->value1_4;
    float cos_sim_loss_0 = 0.5f - 0.5f * _S351.value0_1;
    Tuple_4 _S353 = s_apply_max_0(cos_sim_loss_0, 9.999999960041972e-13f);
    s_bwdCallableCtx_max_0 _S354;
    (&_S354)->_S35 = cos_sim_loss_0;
    (&_S354)->_S36 = 9.999999960041972e-13f;
    s_bwdCallableCtx_sqrt_0 _S355;
    (&_S355)->_S24 = _S353.value0_4;
    float _S356 = 0.0f;
    s_bwdCallableCtx_sqrt_0 _S357 = _S355;
    s_bwdProp_sqrt_0(&_S357, &_S356, _S350);
    float _S358 = 0.0f;
    float _S359 = 0.0f;
    s_bwdCallableCtx_max_0 _S360 = _S354;
    s_bwdProp_max_0(&_S360, &_S358, &_S359, _S356);
    float _S361 = 0.5f * - (_S350 + _S358);
    float3  _S362 = make_float3 (0.0f);
    float3  _S363 = _S362;
    float3  _S364 = _S362;
    s_bwdCallableCtx_dot_0 _S365 = _S352;
    s_bwdProp_dot_0(&_S365, &_S363, &_S364, _S361);
    *_S348 = _S363;
    *_S349 = _S364;
    return;
}

struct s_bwdCallableCtx_normalize_normal_0
{
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 value0_22;
};

inline __device__ void s_bwdProp_normalize_normal_0(s_bwdCallableCtx_normalize_normal_0 * _S366, float3  * _S367, float3  _S368)
{
    float3  _S369 = make_float3 (0.0f);
    float3  _S370 = (&_S366->value0_22)->value0_15;
    Tuple_1 _S371 = s_apply_dot_0((&_S366->value0_22)->value0_15, (&_S366->value0_22)->value0_15);
    s_bwdCallableCtx_dot_0 _S372;
    (&_S372)->_S16 = (&_S366->value0_22)->value0_15;
    (&_S372)->_S17 = (&_S366->value0_22)->value0_15;
    s_bwdCallableCtx_dot_0 _S373 = _S372;
    bool _S374 = !((_S371.value0_1) == 0.0f);
    float3  _S375;
    s_bwdCallableCtx_rsqrt_0 _S376;
    if(_S374)
    {
        float3  _S377 = make_float3 (s_apply_rsqrt_0(_S371.value0_1).value0_0);
        s_bwdCallableCtx_rsqrt_0 _S378;
        (&_S378)->_S12 = _S371.value0_1;
        _S375 = _S377;
        _S376 = _S378;
    }
    else
    {
        _S375 = _S369;
        (&_S376)->_S12 = 0.0f;
    }
    float _S379;
    if(_S374)
    {
        float3  _S380 = _S370 * _S368;
        float3  _S381 = _S375 * _S368;
        float _S382 = _S380.x + _S380.y + _S380.z;
        float _S383 = 0.0f;
        s_bwdCallableCtx_rsqrt_0 _S384 = _S376;
        s_bwdProp_rsqrt_0(&_S384, &_S383, _S382);
        _S379 = _S383;
        _S375 = _S381;
    }
    else
    {
        _S379 = 0.0f;
        _S375 = _S369;
    }
    float3  _S385 = _S369;
    float3  _S386 = _S369;
    s_bwdCallableCtx_dot_0 _S387 = _S373;
    s_bwdProp_dot_0(&_S387, &_S385, &_S386, _S379);
    *_S367 = _S385 + _S386 + _S375;
    return;
}

struct s_bwdCallableCtx_l2_loss_0
{
    s_paramCtx_s_bwdCallableCtx_l2_loss_0 value0_23;
};

inline __device__ void s_bwdProp_l2_loss_0(s_bwdCallableCtx_l2_loss_0 * _S388, float3  * _S389, float3  * _S390, float _S391)
{
    float3  _S392 = (&_S388->value0_23)->value1_3 - (&_S388->value0_23)->value0_13;
    s_bwdCallableCtx_dot_0 _S393;
    (&_S393)->_S16 = _S392;
    (&_S393)->_S17 = _S392;
    float _S394 = 0.3333333432674408f * _S391;
    float3  _S395 = make_float3 (0.0f);
    float3  _S396 = _S395;
    float3  _S397 = _S395;
    s_bwdCallableCtx_dot_0 _S398 = _S393;
    s_bwdProp_dot_0(&_S398, &_S396, &_S397, _S394);
    float3  _S399 = _S396 + _S397;
    *_S389 = - _S399;
    *_S390 = _S399;
    return;
}

struct s_bwdCallableCtx_l1_loss_0
{
    s_paramCtx_s_bwdCallableCtx_l1_loss_0 value0_24;
};

inline __device__ void s_bwdProp_l1_loss_0(s_bwdCallableCtx_l1_loss_0 * _S400, float3  * _S401, float3  * _S402, float _S403)
{
    s_bwdCallableCtx_abs_0 _S404;
    (&_S404)->_S20 = (&_S400->value0_24)->value1_2 - (&_S400->value0_24)->value0_11;
    float3  _S405 = make_float3 (0.0f);
    float3  _S406 = _S405;
    s_bwdProp_mean3_0(&_S406, _S403);
    float3  _S407 = _S405;
    s_bwdCallableCtx_abs_0 _S408 = _S404;
    s_bwdProp_abs_0(&_S408, &_S407, _S406);
    *_S401 = - _S407;
    *_S402 = _S407;
    return;
}

inline __device__ void s_bwdProp_rgb_to_yuv_0(float3  * _S409, float3  _S410)
{
    float _S411 = - _S410.z;
    *_S409 = make_float3 (0.61500000953674316f * _S410.z + -0.14712999761104584f * _S410.y + 0.29899999499320984f * _S410.x, 0.51498997211456299f * _S411 + 0.28885999321937561f * - _S410.y + 0.58700001239776611f * _S410.x, 0.10001000016927719f * _S411 + 0.43599998950958252f * _S410.y + 0.11400000005960464f * _S410.x);
    return;
}

inline __device__ void s_bwdProp_per_pixel_losses_0(s_bwdCallableCtx_per_pixel_losses_0 * _S412, float3  * _S413, float3  * _S414, float * _S415, float * _S416, float3  * _S417, float3  * _S418, float3  * _S419, float * _S420, float3  * _S421, float * _S422, float3  * _S423, float * _S424, float3  * _S425, FixedArray<float, 32>  * _S426)
{
    bool mask_1;
    if((&_S412->value0_9)->value14_0)
    {
        mask_1 = (&_S412->value0_9)->value13_0;
    }
    else
    {
        mask_1 = true;
    }
    bool depth_mask_0 = ((&_S412->value0_9)->value3_0) != 0.0f;
    bool _S427 = ((&_S412->value0_9)->value6_0.x + (&_S412->value0_9)->value6_0.y + (&_S412->value0_9)->value6_0.z) > -2.36599993705749512f;
    Tuple_6 _S428 = s_apply_rgb_to_yuv_0((&_S412->value0_9)->value0_8);
    Tuple_6 _S429 = s_apply_rgb_to_yuv_0((&_S412->value0_9)->value1_1);
    float _S430 = _S429.value0_10.x;
    float dY_0 = _S428.value0_10.x - _S430;
    float dU_0 = _S428.value0_10.y - _S429.value0_10.y;
    float dV_0 = _S428.value0_10.z - _S429.value0_10.z;
    float _S431 = float(mask_1);
    float _S432 = _S431 * (1.0f + (&_S412->value0_9)->value15_0[int(19)] * s_apply_clamp_0(1.0f - _S430, 0.0f, 1.0f).value0_5);
    float _S433 = (&_S412->value0_9)->value15_0[int(0)];
    s_paramCtx_s_bwdCallableCtx_l1_loss_0 _S434;
    (&_S434)->value0_11 = (&_S412->value0_9)->value0_8;
    (&_S434)->value1_2 = (&_S412->value0_9)->value1_1;
    s_paramCtx_s_bwdCallableCtx_l1_loss_0 _S435 = _S434;
    float _S436 = (&_S412->value0_9)->value15_0[int(1)];
    Tuple_7 _S437 = s_apply_l2_loss_0((&_S412->value0_9)->value0_8, (&_S412->value0_9)->value1_1);
    s_paramCtx_s_bwdCallableCtx_l2_loss_0 _S438;
    (&_S438)->value0_13 = (&_S412->value0_9)->value0_8;
    (&_S438)->value1_3 = (&_S412->value0_9)->value1_1;
    s_paramCtx_s_bwdCallableCtx_l2_loss_0 _S439 = _S438;
    float _S440 = (&_S412->value0_9)->value15_0[int(2)];
    s_bwdCallableCtx_abs_1 _S441;
    (&_S441)->_S42 = dY_0;
    s_bwdCallableCtx_abs_1 _S442 = _S441;
    float _S443 = (&_S412->value0_9)->value15_0[int(3)];
    float _S444 = (&_S412->value0_9)->value15_0[int(3)] * dY_0;
    float _S445 = (&_S412->value0_9)->value15_0[int(4)];
    float _S446 = (&_S412->value0_9)->value15_0[int(4)] * dU_0;
    float _S447 = (&_S412->value0_9)->value15_0[int(5)];
    float _S448 = (&_S412->value0_9)->value15_0[int(5)] * dV_0;
    s_bwdCallableCtx_clamp_0 _S449;
    (&_S449)->_S46 = _S437.value0_12;
    (&_S449)->_S47 = 0.0f;
    (&_S449)->_S48 = 1.0f;
    s_bwdCallableCtx_clamp_0 _S450 = _S449;
    float _S451 = float(depth_mask_0 & mask_1);
    float _S452 = (&_S412->value0_9)->value2_0;
    Tuple_4 _S453 = s_apply_max_0((&_S412->value0_9)->value2_0, 0.00009999999747379f);
    s_bwdCallableCtx_max_0 _S454;
    (&_S454)->_S35 = (&_S412->value0_9)->value2_0;
    (&_S454)->_S36 = 0.00009999999747379f;
    s_bwdCallableCtx_max_0 _S455 = _S454;
    float _S456 = _S451 * _S453.value0_4;
    Tuple_4 _S457 = s_apply_max_0((&_S412->value0_9)->value3_0, 0.00009999999747379f);
    s_bwdCallableCtx_max_0 _S458;
    (&_S458)->_S35 = (&_S412->value0_9)->value3_0;
    (&_S458)->_S36 = 0.00009999999747379f;
    s_bwdCallableCtx_max_0 _S459 = _S458;
    float _S460 = _S451 * _S457.value0_4;
    bool _S461 = _S427 & mask_1;
    bool _S462 = true;
    Tuple_8 _S463 = s_apply_normalize_normal_0((&_S412->value0_9)->value4_0, &_S462);
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S464;
    (&_S464)->value0_15 = (&_S412->value0_9)->value4_0;
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S465 = _S464;
    bool render_normal_mask_0 = _S462;
    bool _S466 = true;
    Tuple_8 _S467 = s_apply_normalize_normal_0((&_S412->value0_9)->value5_0, &_S466);
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S468;
    (&_S468)->value0_15 = (&_S412->value0_9)->value5_0;
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S469 = _S468;
    bool depth_normal_mask_0 = _S466;
    bool _S470 = _S461;
    Tuple_8 _S471 = s_apply_normalize_normal_0((&_S412->value0_9)->value6_0, &_S470);
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S472;
    (&_S472)->value0_15 = (&_S412->value0_9)->value6_0;
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S473 = _S472;
    bool normal_mask_0 = _S470;
    float _S474 = (&_S412->value0_9)->value15_0[int(7)] * float(_S462 & _S470);
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S475;
    (&_S475)->value0_16 = _S463.value0_14;
    (&_S475)->value1_4 = _S471.value0_14;
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S476 = _S475;
    float _S477 = (&_S412->value0_9)->value15_0[int(7)] * float(_S466 & _S470);
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S478;
    (&_S478)->value0_16 = _S467.value0_14;
    (&_S478)->value1_4 = _S471.value0_14;
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S479 = _S478;
    float _S480 = (&_S412->value0_9)->value15_0[int(10)] * float(_S462 & _S466);
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S481;
    (&_S481)->value0_16 = _S463.value0_14;
    (&_S481)->value1_4 = _S467.value0_14;
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S482 = _S481;
    bool _S483 = true;
    Tuple_8 _S484 = s_apply_normalize_normal_0((&_S412->value0_9)->value12_0, &_S483);
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S485;
    (&_S485)->value0_15 = (&_S412->value0_9)->value12_0;
    s_paramCtx_s_bwdCallableCtx_normalize_normal_0 _S486 = _S485;
    bool median_normal_mask_0 = _S483;
    if(mask_1)
    {
        mask_1 = _S452 > 1.00000001335143196e-10f;
    }
    else
    {
        mask_1 = false;
    }
    bool mean_median_mask_0;
    if(mask_1)
    {
        mean_median_mask_0 = ((&_S412->value0_9)->value11_0) > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_0 = false;
    }
    float _S487 = (&_S412->value0_9)->value15_0[int(15)] * float(mean_median_mask_0);
    Tuple_3 _S488 = s_apply_log_0(_S452);
    s_bwdCallableCtx_log_0 _S489;
    (&_S489)->_S31 = _S452;
    s_bwdCallableCtx_log_0 _S490 = _S489;
    Tuple_3 _S491 = s_apply_log_0((&_S412->value0_9)->value11_0);
    s_bwdCallableCtx_log_0 _S492;
    (&_S492)->_S31 = (&_S412->value0_9)->value11_0;
    s_bwdCallableCtx_log_0 _S493 = _S492;
    s_bwdCallableCtx_abs_1 _S494;
    (&_S494)->_S42 = _S488.value0_3 - _S491.value0_3;
    s_bwdCallableCtx_abs_1 _S495 = _S494;
    float _S496 = (&_S412->value0_9)->value15_0[int(16)] * float(median_normal_mask_0 & depth_normal_mask_0);
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S497;
    (&_S497)->value0_16 = _S484.value0_14;
    (&_S497)->value1_4 = _S467.value0_14;
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S498 = _S497;
    float _S499 = (&_S412->value0_9)->value15_0[int(17)] * float(median_normal_mask_0 & normal_mask_0);
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S500;
    (&_S500)->value0_16 = _S484.value0_14;
    (&_S500)->value1_4 = _S471.value0_14;
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S501 = _S500;
    float _S502 = (&_S412->value0_9)->value15_0[int(18)] * float(median_normal_mask_0 & render_normal_mask_0);
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S503;
    (&_S503)->value0_16 = _S484.value0_14;
    (&_S503)->value1_4 = _S463.value0_14;
    s_paramCtx_s_bwdCallableCtx_normal_loss_0 _S504 = _S503;
    float _S505 = 1.0f - (&_S412->value0_9)->value7_0;
    Tuple_5 _S506 = s_apply_clamp_0(_S505, 0.0f, 1.0f);
    s_bwdCallableCtx_clamp_0 _S507;
    (&_S507)->_S46 = _S505;
    (&_S507)->_S47 = 0.0f;
    (&_S507)->_S48 = 1.0f;
    s_bwdCallableCtx_clamp_0 _S508 = _S507;
    float _S509 = float(depth_mask_0);
    float _S510 = (&_S412->value0_9)->value15_0[int(8)] * _S509;
    float _S511 = float((&_S412->value0_9)->value13_0);
    s_paramCtx_s_bwdCallableCtx_alpha_loss_0 _S512;
    (&_S512)->value0_17 = _S506.value0_5;
    (&_S512)->value1_5 = _S511;
    s_paramCtx_s_bwdCallableCtx_alpha_loss_0 _S513 = _S512;
    float _S514 = (&_S412->value0_9)->value15_0[int(9)] * _S509;
    float _S515 = 1.0f - _S506.value0_5;
    float _S516 = 1.0f - _S511;
    s_paramCtx_s_bwdCallableCtx_alpha_loss_0 _S517;
    (&_S517)->value0_17 = _S515;
    (&_S517)->value1_5 = _S516;
    s_paramCtx_s_bwdCallableCtx_alpha_loss_0 _S518 = _S517;
    float _S519 = (&_S412->value0_9)->value15_0[int(11)] * 4.0f;
    float _S520 = _S519 * _S506.value0_5;
    float _S521 = (&_S412->value0_9)->value15_0[int(12)];
    float _S522 = (&_S412->value0_9)->value15_0[int(13)];
    float _S523 = (&_S412->value0_9)->value15_0[int(14)];
    float _S524 = _S523 * (*_S426)[int(15)];
    float3  _S525 = make_float3 (0.0f);
    float3  _S526 = _S525;
    s_bwdProp_mean3_0(&_S526, _S524);
    float _S527 = _S522 * (*_S426)[int(14)];
    float _S528 = _S521 * (*_S426)[int(13)];
    float3  _S529 = _S525;
    s_bwdProp_mean3_0(&_S529, _S528);
    float _S530 = _S520 * (*_S426)[int(12)];
    float _S531 = _S519 * (_S515 * (*_S426)[int(12)]);
    float _S532 = _S514 * (*_S426)[int(10)];
    float _S533 = 0.0f;
    float _S534 = 0.0f;
    s_bwdCallableCtx_alpha_loss_0 _S535;
    (&_S535)->value0_18 = _S518;
    s_bwdProp_alpha_loss_0(&_S535, &_S533, &_S534, _S532);
    float _S536 = - (_S530 + _S533);
    float _S537 = _S510 * (*_S426)[int(9)];
    float _S538 = 0.0f;
    float _S539 = 0.0f;
    s_bwdCallableCtx_alpha_loss_0 _S540;
    (&_S540)->value0_18 = _S513;
    s_bwdProp_alpha_loss_0(&_S540, &_S538, &_S539, _S537);
    float _S541 = _S531 + _S536 + _S538;
    float _S542 = 0.0f;
    float _S543 = 0.0f;
    float _S544 = 0.0f;
    s_bwdCallableCtx_clamp_0 _S545 = _S508;
    s_bwdProp_clamp_0(&_S545, &_S542, &_S543, &_S544, _S541);
    float _S546 = - _S542;
    float _S547 = _S502 * (*_S426)[int(19)];
    float3  _S548 = _S525;
    float3  _S549 = _S525;
    s_bwdCallableCtx_normal_loss_0 _S550;
    (&_S550)->value0_21 = _S504;
    s_bwdProp_normal_loss_0(&_S550, &_S548, &_S549, _S547);
    float _S551 = _S499 * (*_S426)[int(18)];
    float3  _S552 = _S525;
    float3  _S553 = _S525;
    s_bwdCallableCtx_normal_loss_0 _S554;
    (&_S554)->value0_21 = _S501;
    s_bwdProp_normal_loss_0(&_S554, &_S552, &_S553, _S551);
    float _S555 = _S496 * (*_S426)[int(17)];
    float3  _S556 = _S525;
    float3  _S557 = _S525;
    s_bwdCallableCtx_normal_loss_0 _S558;
    (&_S558)->value0_21 = _S498;
    s_bwdProp_normal_loss_0(&_S558, &_S556, &_S557, _S555);
    float _S559 = _S487 * (*_S426)[int(16)];
    float _S560 = 0.0f;
    s_bwdCallableCtx_abs_1 _S561 = _S495;
    s_bwdProp_abs_1(&_S561, &_S560, _S559);
    float _S562 = - _S560;
    float _S563 = 0.0f;
    s_bwdCallableCtx_log_0 _S564 = _S493;
    s_bwdProp_log_0(&_S564, &_S563, _S562);
    float _S565 = 0.0f;
    s_bwdCallableCtx_log_0 _S566 = _S490;
    s_bwdProp_log_0(&_S566, &_S565, _S560);
    float3  _S567 = _S548 + _S552 + _S556;
    float3  _S568 = _S525;
    s_bwdCallableCtx_normalize_normal_0 _S569;
    (&_S569)->value0_22 = _S486;
    s_bwdProp_normalize_normal_0(&_S569, &_S568, _S567);
    float _S570 = _S480 * (*_S426)[int(11)];
    float3  _S571 = _S525;
    float3  _S572 = _S525;
    s_bwdCallableCtx_normal_loss_0 _S573;
    (&_S573)->value0_21 = _S482;
    s_bwdProp_normal_loss_0(&_S573, &_S571, &_S572, _S570);
    float _S574 = _S477 * (*_S426)[int(8)];
    float3  _S575 = _S525;
    float3  _S576 = _S525;
    s_bwdCallableCtx_normal_loss_0 _S577;
    (&_S577)->value0_21 = _S479;
    s_bwdProp_normal_loss_0(&_S577, &_S575, &_S576, _S574);
    float _S578 = _S474 * (*_S426)[int(7)];
    float3  _S579 = _S525;
    float3  _S580 = _S525;
    s_bwdCallableCtx_normal_loss_0 _S581;
    (&_S581)->value0_21 = _S476;
    s_bwdProp_normal_loss_0(&_S581, &_S579, &_S580, _S578);
    float3  _S582 = _S576 + _S580 + _S553;
    float3  _S583 = _S525;
    s_bwdCallableCtx_normalize_normal_0 _S584;
    (&_S584)->value0_22 = _S473;
    s_bwdProp_normalize_normal_0(&_S584, &_S583, _S582);
    float3  _S585 = _S572 + _S575 + _S557;
    float3  _S586 = _S525;
    s_bwdCallableCtx_normalize_normal_0 _S587;
    (&_S587)->value0_22 = _S469;
    s_bwdProp_normalize_normal_0(&_S587, &_S586, _S585);
    float3  _S588 = _S571 + _S579 + _S549;
    float3  _S589 = _S525;
    s_bwdCallableCtx_normalize_normal_0 _S590;
    (&_S590)->value0_22 = _S465;
    s_bwdProp_normalize_normal_0(&_S590, &_S589, _S588);
    float _S591 = _S460 * (*_S426)[int(6)];
    float _S592 = _S460 * (*_S426)[int(5)];
    float _S593 = _S456 * (*_S426)[int(4)];
    float _S594 = _S451 * (_S456 * (*_S426)[int(6)] + _S592 + _S592 + (*_S426)[int(3)]);
    float _S595 = 0.0f;
    float _S596 = 0.0f;
    s_bwdCallableCtx_max_0 _S597 = _S459;
    s_bwdProp_max_0(&_S597, &_S595, &_S596, _S594);
    float _S598 = _S451 * (_S591 + _S593 + _S593 + (*_S426)[int(2)]);
    float _S599 = 0.0f;
    float _S600 = 0.0f;
    s_bwdCallableCtx_max_0 _S601 = _S455;
    s_bwdProp_max_0(&_S601, &_S599, &_S600, _S598);
    float _S602 = _S431 * (*_S426)[int(1)];
    float _S603 = 0.0f;
    float _S604 = 0.0f;
    float _S605 = 0.0f;
    s_bwdCallableCtx_clamp_0 _S606 = _S450;
    s_bwdProp_clamp_0(&_S606, &_S603, &_S604, &_S605, _S602);
    float _S607 = _S432 * (*_S426)[int(0)];
    float _S608 = _S448 * _S607;
    float _S609 = _S447 * (dV_0 * _S607);
    float _S610 = _S446 * _S607;
    float _S611 = _S445 * (dU_0 * _S607);
    float _S612 = _S444 * _S607;
    float _S613 = _S443 * (dY_0 * _S607);
    float _S614 = _S440 * _S607;
    float _S615 = 0.0f;
    s_bwdCallableCtx_abs_1 _S616 = _S442;
    s_bwdProp_abs_1(&_S616, &_S615, _S614);
    float _S617 = _S603 + _S436 * _S607;
    float3  _S618 = _S525;
    float3  _S619 = _S525;
    s_bwdCallableCtx_l2_loss_0 _S620;
    (&_S620)->value0_23 = _S439;
    s_bwdProp_l2_loss_0(&_S620, &_S618, &_S619, _S617);
    float _S621 = _S433 * _S607;
    float3  _S622 = _S525;
    float3  _S623 = _S525;
    s_bwdCallableCtx_l1_loss_0 _S624;
    (&_S624)->value0_24 = _S435;
    s_bwdProp_l1_loss_0(&_S624, &_S622, &_S623, _S621);
    float _S625 = _S608 + _S609;
    float _S626 = _S610 + _S611;
    float _S627 = _S612 + _S613 + _S615;
    float3  _S628 = make_float3 (- _S627, - _S626, - _S625);
    float3  _S629 = _S525;
    s_bwdProp_rgb_to_yuv_0(&_S629, _S628);
    float3  _S630 = make_float3 (_S627, _S626, _S625);
    float3  _S631 = _S525;
    s_bwdProp_rgb_to_yuv_0(&_S631, _S630);
    float _S632 = _S599 + _S565;
    float3  _S633 = _S619 + _S623 + _S629;
    *_S413 = _S618 + _S622 + _S631;
    *_S414 = _S633;
    *_S415 = _S632;
    *_S416 = _S595;
    *_S417 = _S589;
    *_S418 = _S586;
    *_S419 = _S583;
    *_S420 = _S546;
    *_S421 = _S529;
    *_S422 = _S527;
    *_S423 = _S526;
    *_S424 = _S563;
    *_S425 = _S568;
    return;
}

inline __device__ void _S634(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S635, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S636, DiffPair_float_0 * _S637, DiffPair_float_0 * _S638, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S639, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S640, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S641, DiffPair_float_0 * _S642, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S643, DiffPair_float_0 * _S644, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S645, DiffPair_float_0 * _S646, DiffPair_vectorx3Cfloatx2C3x3E_0 * _S647, bool _S648, bool _S649, FixedArray<float, 20>  * _S650, FixedArray<float, 32>  * _S651)
{
    s_paramCtx_s_bwdCallableCtx_per_pixel_losses_0 _S652;
    (&_S652)->value0_8 = _S635->primal_0;
    (&_S652)->value1_1 = _S636->primal_0;
    (&_S652)->value2_0 = _S637->primal_0;
    (&_S652)->value3_0 = _S638->primal_0;
    (&_S652)->value4_0 = _S639->primal_0;
    (&_S652)->value5_0 = _S640->primal_0;
    (&_S652)->value6_0 = _S641->primal_0;
    (&_S652)->value7_0 = _S642->primal_0;
    (&_S652)->value11_0 = _S646->primal_0;
    (&_S652)->value12_0 = _S647->primal_0;
    (&_S652)->value13_0 = _S648;
    (&_S652)->value14_0 = _S649;
    (&_S652)->value15_0 = *_S650;
    s_bwdCallableCtx_per_pixel_losses_0 _S653;
    (&_S653)->value0_9 = _S652;
    s_bwdProp_per_pixel_losses_0(&_S653, &_S635->differential_0, &_S636->differential_0, &_S637->differential_0, &_S638->differential_0, &_S639->differential_0, &_S640->differential_0, &_S641->differential_0, &_S642->differential_0, &_S643->differential_0, &_S644->differential_0, &_S645->differential_0, &_S646->differential_0, &_S647->differential_0, _S651);
    return;
}

inline __device__ float lerp_0(float x_8, float y_3, float s_0)
{
    return x_8 + (y_3 - x_8) * s_0;
}

inline __device__ float3  abs_0(float3  x_9)
{
    float3  result_3;
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
        *_slang_vector_get_element_ptr(&result_3, i_1) = (F32_abs((_slang_vector_get_element(x_9, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_3;
}

inline __device__ void per_pixel_losses(float3  render_rgb_0, float3  ref_rgb_0, float render_depth_0, float ref_depth_0, float3  render_normal_0, float3  depth_normal_0, float3  ref_normal_0, float render_Ts_0, float3  rgb_dist_0, float depth_dist_0, float3  normal_dist_0, float median_depth_0, float3  median_normal_0, bool ref_alpha_0, bool has_mask_0, FixedArray<float, 20>  weights_0, FixedArray<float, 32>  * _S654)
{
    bool _S655;
    float3  _S656;
    bool _S657;
    float3  _S658;
    bool normal_mask_1;
    float3  _S659;
    bool _S660;
    float3  _S661;
    FixedArray<float, 32>  losses_0;
    bool mask_2;
    if(has_mask_0)
    {
        mask_2 = ref_alpha_0;
    }
    else
    {
        mask_2 = true;
    }
    bool depth_mask_1 = ref_depth_0 != 0.0f;
    bool normal_mask_2 = (ref_normal_0.x + ref_normal_0.y + ref_normal_0.z) > -2.36599993705749512f;
    float _S662 = render_rgb_0.x;
    float _S663 = render_rgb_0.y;
    float _S664 = render_rgb_0.z;
    float _S665 = ref_rgb_0.x;
    float _S666 = ref_rgb_0.y;
    float _S667 = ref_rgb_0.z;
    float Y_0 = 0.29899999499320984f * _S665 + 0.58700001239776611f * _S666 + 0.11400000005960464f * _S667;
    float dY_1 = 0.29899999499320984f * _S662 + 0.58700001239776611f * _S663 + 0.11400000005960464f * _S664 - Y_0;
    float dU_1 = -0.14712999761104584f * _S662 - 0.28885999321937561f * _S663 + 0.43599998950958252f * _S664 - (-0.14712999761104584f * _S665 - 0.28885999321937561f * _S666 + 0.43599998950958252f * _S667);
    float dV_1 = 0.61500000953674316f * _S662 - 0.51498997211456299f * _S663 - 0.10001000016927719f * _S664 - (0.61500000953674316f * _S665 - 0.51498997211456299f * _S666 - 0.10001000016927719f * _S667);
    float _S668 = float(mask_2);
    float _S669 = _S668 * (1.0f + weights_0[int(19)] * clamp_0(1.0f - Y_0, 0.0f, 1.0f));
    float3  _S670 = ref_rgb_0 - render_rgb_0;
    float3  _S671 = abs_0(_S670);
    float _S672 = dot_0(_S670, _S670) * 0.3333333432674408f;
    losses_0[int(0)] = _S669 * (weights_0[int(0)] * ((_S671.x + _S671.y + _S671.z) * 0.3333333432674408f) + weights_0[int(1)] * _S672 + weights_0[int(2)] * (F32_abs((dY_1))) + weights_0[int(3)] * dY_1 * dY_1 + weights_0[int(4)] * dU_1 * dU_1 + weights_0[int(5)] * dV_1 * dV_1);
    losses_0[int(1)] = _S668 * clamp_0(_S672, 0.0f, 1.0f);
    float _S673 = float(depth_mask_1 & mask_2);
    float _S674 = _S673 * (F32_max((render_depth_0), (0.00009999999747379f)));
    float _S675 = _S673 * (F32_max((ref_depth_0), (0.00009999999747379f)));
    losses_0[int(2)] = _S674;
    losses_0[int(3)] = _S675;
    losses_0[int(4)] = _S674 * _S674;
    losses_0[int(5)] = _S675 * _S675;
    losses_0[int(6)] = _S674 * _S675;
    bool _S676 = normal_mask_2 & mask_2;
    for(;;)
    {
        float norm2_0 = dot_0(render_normal_0, render_normal_0);
        bool _S677 = norm2_0 == 0.0f;
        _S655 = _S677;
        if(_S677)
        {
            _S656 = make_float3 (0.0f);
            break;
        }
        _S656 = render_normal_0 * make_float3 ((F32_rsqrt((norm2_0))));
        break;
    }
    bool _S678 = !_S655;
    for(;;)
    {
        float norm2_1 = dot_0(depth_normal_0, depth_normal_0);
        bool _S679 = norm2_1 == 0.0f;
        _S657 = _S679;
        if(_S679)
        {
            _S658 = make_float3 (0.0f);
            break;
        }
        _S658 = depth_normal_0 * make_float3 ((F32_rsqrt((norm2_1))));
        break;
    }
    bool _S680 = !_S657;
    for(;;)
    {
        float norm2_2 = dot_0(ref_normal_0, ref_normal_0);
        if(norm2_2 == 0.0f)
        {
            _S659 = make_float3 (0.0f);
            normal_mask_1 = false;
            break;
        }
        _S659 = ref_normal_0 * make_float3 ((F32_rsqrt((norm2_2))));
        normal_mask_1 = _S676;
        break;
    }
    float _S681 = float(_S678 & normal_mask_1);
    float cos_sim_loss_1 = 0.5f - 0.5f * dot_0(_S656, _S659);
    losses_0[int(7)] = weights_0[int(7)] * _S681 * (cos_sim_loss_1 + (F32_sqrt(((F32_max((cos_sim_loss_1), (9.999999960041972e-13f)))))));
    float _S682 = float(_S680 & normal_mask_1);
    float cos_sim_loss_2 = 0.5f - 0.5f * dot_0(_S658, _S659);
    losses_0[int(8)] = weights_0[int(7)] * _S682 * (cos_sim_loss_2 + (F32_sqrt(((F32_max((cos_sim_loss_2), (9.999999960041972e-13f)))))));
    float _S683 = float(_S678 & _S680);
    float cos_sim_loss_3 = 0.5f - 0.5f * dot_0(_S656, _S658);
    losses_0[int(11)] = weights_0[int(10)] * _S683 * (cos_sim_loss_3 + (F32_sqrt(((F32_max((cos_sim_loss_3), (9.999999960041972e-13f)))))));
    for(;;)
    {
        float norm2_3 = dot_0(median_normal_0, median_normal_0);
        bool _S684 = norm2_3 == 0.0f;
        _S660 = _S684;
        if(_S684)
        {
            _S661 = make_float3 (0.0f);
            break;
        }
        _S661 = median_normal_0 * make_float3 ((F32_rsqrt((norm2_3))));
        break;
    }
    bool _S685 = !_S660;
    if(mask_2)
    {
        mask_2 = render_depth_0 > 1.00000001335143196e-10f;
    }
    else
    {
        mask_2 = false;
    }
    bool mean_median_mask_1;
    if(mask_2)
    {
        mean_median_mask_1 = median_depth_0 > 1.00000001335143196e-10f;
    }
    else
    {
        mean_median_mask_1 = false;
    }
    float _S686 = float(mean_median_mask_1);
    losses_0[int(16)] = weights_0[int(15)] * _S686 * (F32_abs(((F32_log((render_depth_0))) - (F32_log((median_depth_0))))));
    float _S687 = float(_S685 & _S680);
    float cos_sim_loss_4 = 0.5f - 0.5f * dot_0(_S661, _S658);
    losses_0[int(17)] = weights_0[int(16)] * _S687 * (cos_sim_loss_4 + (F32_sqrt(((F32_max((cos_sim_loss_4), (9.999999960041972e-13f)))))));
    float _S688 = float(_S685 & normal_mask_1);
    float cos_sim_loss_5 = 0.5f - 0.5f * dot_0(_S661, _S659);
    losses_0[int(18)] = weights_0[int(17)] * _S688 * (cos_sim_loss_5 + (F32_sqrt(((F32_max((cos_sim_loss_5), (9.999999960041972e-13f)))))));
    float _S689 = float(_S685 & _S678);
    float cos_sim_loss_6 = 0.5f - 0.5f * dot_0(_S661, _S656);
    losses_0[int(19)] = weights_0[int(18)] * _S689 * (cos_sim_loss_6 + (F32_sqrt(((F32_max((cos_sim_loss_6), (9.999999960041972e-13f)))))));
    float render_alpha_0 = clamp_0(1.0f - render_Ts_0, 0.0f, 1.0f);
    float _S690 = float(depth_mask_1);
    float _S691 = float(ref_alpha_0);
    float _S692 = (F32_max((render_alpha_0), (_S691)));
    losses_0[int(9)] = weights_0[int(8)] * _S690 * - lerp_0((F32_log(((F32_max((1.0f - _S692), (9.99999997475242708e-07f)))))), (F32_log(((F32_max((_S692), (9.99999997475242708e-07f)))))), _S691);
    float _S693 = 1.0f - render_alpha_0;
    float _S694 = 1.0f - _S691;
    float _S695 = (F32_max((_S693), (_S694)));
    losses_0[int(10)] = weights_0[int(9)] * _S690 * - lerp_0((F32_log(((F32_max((1.0f - _S695), (9.99999997475242708e-07f)))))), (F32_log(((F32_max((_S695), (9.99999997475242708e-07f)))))), _S694);
    losses_0[int(12)] = weights_0[int(11)] * 4.0f * render_alpha_0 * _S693;
    losses_0[int(13)] = weights_0[int(12)] * ((rgb_dist_0.x + rgb_dist_0.y + rgb_dist_0.z) * 0.3333333432674408f);
    losses_0[int(14)] = weights_0[int(13)] * depth_dist_0;
    losses_0[int(15)] = weights_0[int(14)] * ((normal_dist_0.x + normal_dist_0.y + normal_dist_0.z) * 0.3333333432674408f);
    losses_0[int(20)] = 1.0f;
    losses_0[int(21)] = _S668;
    losses_0[int(22)] = _S673;
    losses_0[int(23)] = _S681;
    losses_0[int(24)] = _S682;
    losses_0[int(25)] = _S683;
    losses_0[int(26)] = _S690;
    losses_0[int(27)] = _S686;
    losses_0[int(28)] = _S687;
    losses_0[int(29)] = _S688;
    losses_0[int(30)] = _S689;
    losses_0[int(31)] = _S669;
    *_S654 = losses_0;
    return;
}

inline __device__ void per_pixel_losses_bwd(float3  render_rgb_1, float3  ref_rgb_1, float render_depth_1, float ref_depth_1, float3  render_normal_1, float3  depth_normal_1, float3  ref_normal_1, float render_Ts_1, float3  rgb_dist_1, float depth_dist_1, float3  normal_dist_1, float median_depth_1, float3  median_normal_1, bool ref_alpha_1, bool has_mask_1, FixedArray<float, 20>  weights_1, FixedArray<float, 32>  v_losses_0, float3  * v_render_rgb_0, float3  * v_ref_rgb_0, float * v_render_depth_0, float * v_ref_depth_0, float3  * v_render_normal_0, float3  * v_depth_normal_0, float3  * v_ref_normal_0, float * v_render_Ts_0, float3  * v_rgb_dist_0, float * v_depth_dist_0, float3  * v_normal_dist_0, float * v_median_depth_0, float3  * v_median_normal_0)
{
    float3  _S696 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_render_rgb_0;
    (&dp_render_rgb_0)->primal_0 = render_rgb_1;
    (&dp_render_rgb_0)->differential_0 = _S696;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_ref_rgb_0;
    (&dp_ref_rgb_0)->primal_0 = ref_rgb_1;
    (&dp_ref_rgb_0)->differential_0 = _S696;
    DiffPair_float_0 dp_render_depth_0;
    (&dp_render_depth_0)->primal_0 = render_depth_1;
    (&dp_render_depth_0)->differential_0 = 0.0f;
    DiffPair_float_0 dp_ref_depth_0;
    (&dp_ref_depth_0)->primal_0 = ref_depth_1;
    (&dp_ref_depth_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_render_normal_0;
    (&dp_render_normal_0)->primal_0 = render_normal_1;
    (&dp_render_normal_0)->differential_0 = _S696;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_depth_normal_0;
    (&dp_depth_normal_0)->primal_0 = depth_normal_1;
    (&dp_depth_normal_0)->differential_0 = _S696;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_ref_normal_0;
    (&dp_ref_normal_0)->primal_0 = ref_normal_1;
    (&dp_ref_normal_0)->differential_0 = _S696;
    DiffPair_float_0 dp_render_Ts_0;
    (&dp_render_Ts_0)->primal_0 = render_Ts_1;
    (&dp_render_Ts_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_rgb_dist_0;
    (&dp_rgb_dist_0)->primal_0 = rgb_dist_1;
    (&dp_rgb_dist_0)->differential_0 = _S696;
    DiffPair_float_0 dp_depth_dist_0;
    (&dp_depth_dist_0)->primal_0 = depth_dist_1;
    (&dp_depth_dist_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_normal_dist_0;
    (&dp_normal_dist_0)->primal_0 = normal_dist_1;
    (&dp_normal_dist_0)->differential_0 = _S696;
    DiffPair_float_0 dp_median_depth_0;
    (&dp_median_depth_0)->primal_0 = median_depth_1;
    (&dp_median_depth_0)->differential_0 = 0.0f;
    DiffPair_vectorx3Cfloatx2C3x3E_0 dp_median_normal_0;
    (&dp_median_normal_0)->primal_0 = median_normal_1;
    (&dp_median_normal_0)->differential_0 = _S696;
    FixedArray<float, 20>  _S697 = weights_1;
    FixedArray<float, 32>  _S698 = v_losses_0;
    _S634(&dp_render_rgb_0, &dp_ref_rgb_0, &dp_render_depth_0, &dp_ref_depth_0, &dp_render_normal_0, &dp_depth_normal_0, &dp_ref_normal_0, &dp_render_Ts_0, &dp_rgb_dist_0, &dp_depth_dist_0, &dp_normal_dist_0, &dp_median_depth_0, &dp_median_normal_0, ref_alpha_1, has_mask_1, &_S697, &_S698);
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

inline __device__ void per_pixel_losses_reduce(FixedArray<float, 32>  raw_losses_0, FixedArray<float, 20>  weights_2, FixedArray<float, 14>  * _S699)
{
    FixedArray<float, 14>  losses_1;
    losses_1[int(0)] = raw_losses_0[int(0)] / (F32_max((raw_losses_0[int(31)]), (1.0f)));
    losses_1[int(1)] = -10.0f * (F32_log10((raw_losses_0[int(1)] / (F32_max((raw_losses_0[int(21)]), (1.0f))))));
    bool _S700;
    if((raw_losses_0[int(22)]) > 0.0f)
    {
        _S700 = (raw_losses_0[int(3)]) != 0.0f;
    }
    else
    {
        _S700 = false;
    }
    float _S701;
    if(_S700)
    {
        _S701 = weights_2[int(6)] * clamp_0(1.0f - (raw_losses_0[int(6)] - raw_losses_0[int(2)] * raw_losses_0[int(3)] / raw_losses_0[int(22)]) / (F32_sqrt(((F32_max((9.999999960041972e-13f), ((raw_losses_0[int(4)] - raw_losses_0[int(2)] * raw_losses_0[int(2)] / raw_losses_0[int(22)]) * (raw_losses_0[int(5)] - raw_losses_0[int(3)] * raw_losses_0[int(3)] / raw_losses_0[int(22)]) + 1.0f)))))), 0.0f, 2.0f);
    }
    else
    {
        _S701 = 0.0f;
    }
    losses_1[int(2)] = _S701;
    losses_1[int(3)] = (raw_losses_0[int(7)] / (F32_max((raw_losses_0[int(23)]), (1.0f))) + raw_losses_0[int(8)] / (F32_max((raw_losses_0[int(24)]), (1.0f)))) / float((I32_max((int((raw_losses_0[int(23)]) > 0.5f) + int((raw_losses_0[int(24)]) > 0.5f)), (int(1)))));
    losses_1[int(4)] = (raw_losses_0[int(9)] + raw_losses_0[int(10)]) / (F32_max((raw_losses_0[int(26)]), (1.0f)));
    losses_1[int(5)] = raw_losses_0[int(11)] / (F32_max((raw_losses_0[int(25)]), (1.0f)));
    float _S702 = (F32_max((raw_losses_0[int(20)]), (1.0f)));
    losses_1[int(6)] = raw_losses_0[int(12)] / _S702;
    losses_1[int(7)] = raw_losses_0[int(13)] / _S702;
    losses_1[int(8)] = raw_losses_0[int(14)] / _S702;
    losses_1[int(9)] = raw_losses_0[int(15)] / _S702;
    losses_1[int(10)] = raw_losses_0[int(16)] / (F32_max((raw_losses_0[int(27)]), (1.0f)));
    losses_1[int(11)] = raw_losses_0[int(17)] / (F32_max((raw_losses_0[int(28)]), (1.0f)));
    losses_1[int(12)] = raw_losses_0[int(18)] / (F32_max((raw_losses_0[int(29)]), (1.0f)));
    losses_1[int(13)] = raw_losses_0[int(19)] / (F32_max((raw_losses_0[int(30)]), (1.0f)));
    *_S699 = losses_1;
    return;
}

inline __device__ void per_pixel_losses_reduce_bwd(FixedArray<float, 32>  raw_losses_1, FixedArray<float, 20>  weights_3, FixedArray<float, 14>  v_losses_1, FixedArray<float, 32>  * _S703)
{
    FixedArray<float, 32>  _S704;
    dzero_0(&_S704);
    DiffPair_arrayx3Cfloatx2C32x3E_0 dp_raw_losses_0;
    (&dp_raw_losses_0)->primal_0 = raw_losses_1;
    (&dp_raw_losses_0)->differential_0 = _S704;
    FixedArray<float, 20>  _S705 = weights_3;
    FixedArray<float, 14>  _S706 = v_losses_1;
    _S278(&dp_raw_losses_0, &_S705, &_S706);
    *_S703 = (&dp_raw_losses_0)->differential_0;
    return;
}


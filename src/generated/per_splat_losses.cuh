#pragma once

#include "generated/slang.cuh"

struct DiffPair_float_0
{
    float primal_0;
    float differential_0;
};

inline __device__ void _d_exp_0(DiffPair_float_0 * dpx_0, float dOut_0)
{
    float _S1 = (F32_exp(((*dpx_0).primal_0))) * dOut_0;
    dpx_0->primal_0 = (*dpx_0).primal_0;
    dpx_0->differential_0 = _S1;
    return;
}

inline __device__ void _d_max_0(DiffPair_float_0 * dpx_1, DiffPair_float_0 * dpy_0, float dOut_1)
{
    DiffPair_float_0 _S2 = *dpx_1;
    float _S3;
    if(((*dpx_1).primal_0) > ((*dpy_0).primal_0))
    {
        _S3 = dOut_1;
    }
    else
    {
        if(((*dpx_1).primal_0) < ((*dpy_0).primal_0))
        {
            _S3 = 0.0f;
        }
        else
        {
            _S3 = 0.5f * dOut_1;
        }
    }
    dpx_1->primal_0 = _S2.primal_0;
    dpx_1->differential_0 = _S3;
    DiffPair_float_0 _S4 = *dpy_0;
    if(((*dpy_0).primal_0) > (_S2.primal_0))
    {
        _S3 = dOut_1;
    }
    else
    {
        if(((*dpy_0).primal_0) < ((*dpx_1).primal_0))
        {
            _S3 = 0.0f;
        }
        else
        {
            _S3 = 0.5f * dOut_1;
        }
    }
    dpy_0->primal_0 = _S4.primal_0;
    dpy_0->differential_0 = _S3;
    return;
}

inline __device__ void _d_sqrt_0(DiffPair_float_0 * dpx_2, float dOut_2)
{
    float _S5 = 0.5f / (F32_sqrt(((F32_max((1.00000001168609742e-07f), ((*dpx_2).primal_0)))))) * dOut_2;
    dpx_2->primal_0 = (*dpx_2).primal_0;
    dpx_2->differential_0 = _S5;
    return;
}

inline __device__ float dot_0(float4  x_0, float4  y_0)
{
    int i_0 = int(0);
    float result_0 = 0.0f;
    for(;;)
    {
        if(i_0 < int(4))
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

inline __device__ float length_0(float4  x_1)
{
    return (F32_sqrt((dot_0(x_1, x_1))));
}

inline __device__ void _d_log_0(DiffPair_float_0 * dpx_3, float dOut_3)
{
    float _S6 = 1.0f / (*dpx_3).primal_0 * dOut_3;
    dpx_3->primal_0 = (*dpx_3).primal_0;
    dpx_3->differential_0 = _S6;
    return;
}

struct DiffPair_vectorx3Cfloatx2C3x3E_0
{
    float3  primal_0;
    float3  differential_0;
};

inline __device__ float3  exp_0(float3  x_2)
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
        *_slang_vector_get_element_ptr(&result_2, i_1) = (F32_exp((_slang_vector_get_element(x_2, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_2;
}

inline __device__ void _d_exp_vector_0(DiffPair_vectorx3Cfloatx2C3x3E_0 * dpx_4, float3  dOut_4)
{
    float3  _S7 = exp_0((*dpx_4).primal_0) * dOut_4;
    dpx_4->primal_0 = (*dpx_4).primal_0;
    dpx_4->differential_0 = _S7;
    return;
}

inline __device__ void _d_min_0(DiffPair_float_0 * dpx_5, DiffPair_float_0 * dpy_1, float dOut_5)
{
    DiffPair_float_0 _S8 = *dpx_5;
    float _S9;
    if(((*dpx_5).primal_0) < ((*dpy_1).primal_0))
    {
        _S9 = dOut_5;
    }
    else
    {
        if(((*dpx_5).primal_0) > ((*dpy_1).primal_0))
        {
            _S9 = 0.0f;
        }
        else
        {
            _S9 = 0.5f * dOut_5;
        }
    }
    dpx_5->primal_0 = _S8.primal_0;
    dpx_5->differential_0 = _S9;
    DiffPair_float_0 _S10 = *dpy_1;
    if(((*dpy_1).primal_0) < (_S8.primal_0))
    {
        _S9 = dOut_5;
    }
    else
    {
        if(((*dpy_1).primal_0) > ((*dpx_5).primal_0))
        {
            _S9 = 0.0f;
        }
        else
        {
            _S9 = 0.5f * dOut_5;
        }
    }
    dpy_1->primal_0 = _S10.primal_0;
    dpy_1->differential_0 = _S9;
    return;
}

inline __device__ void per_splat_losses(float3  scales_0, float opacity_0, float4  quat_0, float mcmc_opacity_reg_weight_0, float mcmc_scale_reg_weight_0, float max_gauss_ratio_0, float scale_regularization_weight_0, float erank_reg_weight_0, float erank_reg_weight_s3_0, float quat_norm_reg_weight_0, FixedArray<float, 5>  * _S11)
{
    FixedArray<float, 5>  losses_0;
    losses_0[int(0)] = mcmc_opacity_reg_weight_0 * (1.0f / (1.0f + (F32_exp((- opacity_0)))));
    float quat_norm_0 = length_0(quat_0);
    losses_0[int(4)] = quat_norm_reg_weight_0 * (quat_norm_0 - 1.0f - (F32_log((quat_norm_0))));
    losses_0[int(1)] = mcmc_scale_reg_weight_0 * 0.00999999977648258f * (scales_0.x + scales_0.y + scales_0.z) / 3.0f;
    float3  _S12 = exp_0(scales_0);
    float x_3 = _S12.x;
    float y_1 = _S12.y;
    float z_0 = _S12.z;
    losses_0[int(2)] = scale_regularization_weight_0 * ((F32_max(((F32_max(((F32_max((x_3), (y_1)))), (z_0))) / (F32_max(((F32_min(((F32_min((x_3), (y_1)))), (z_0)))), (1.00000000317107685e-30f)))), (max_gauss_ratio_0))) - max_gauss_ratio_0);
    float3  _S13 = exp_0(make_float3 (2.0f) * scales_0);
    float x_4 = _S13.x;
    float y_2 = _S13.y;
    float z_1 = _S13.z;
    float _S14 = (F32_max((x_4 + y_2 + z_1), (1.00000000317107685e-30f)));
    float s1_0 = (F32_max(((F32_max((x_4), (y_2)))), (z_1))) / _S14;
    float s3_0 = (F32_min(((F32_min((x_4), (y_2)))), (z_1))) / _S14;
    float _S15 = (F32_max((1.0f - s1_0 - s3_0), (0.0f)));
    float _S16;
    if(s1_0 > 0.0f)
    {
        _S16 = s1_0 * (F32_log((s1_0)));
    }
    else
    {
        _S16 = 0.0f;
    }
    float _S17 = - _S16;
    if(_S15 > 0.0f)
    {
        _S16 = _S15 * (F32_log((_S15)));
    }
    else
    {
        _S16 = 0.0f;
    }
    float _S18 = _S17 - _S16;
    if(s3_0 > 0.0f)
    {
        _S16 = s3_0 * (F32_log((s3_0)));
    }
    else
    {
        _S16 = 0.0f;
    }
    losses_0[int(3)] = erank_reg_weight_0 * (F32_max((- (F32_log(((F32_max(((F32_exp((_S18 - _S16))) - 0.99998998641967773f), (9.99999971718068537e-10f))))))), (0.0f))) + erank_reg_weight_s3_0 * s3_0;
    *_S11 = losses_0;
    return;
}

inline __device__ float s_primal_ctx_exp_0(float _S19)
{
    return (F32_exp((_S19)));
}

inline __device__ float3  s_primal_ctx_exp_1(float3  _S20)
{
    return exp_0(_S20);
}

inline __device__ float s_primal_ctx_log_0(float _S21)
{
    return (F32_log((_S21)));
}

inline __device__ void s_bwd_prop_log_0(DiffPair_float_0 * _S22, float _S23)
{
    _d_log_0(_S22, _S23);
    return;
}

inline __device__ void s_bwd_prop_exp_0(DiffPair_float_0 * _S24, float _S25)
{
    _d_exp_0(_S24, _S25);
    return;
}

inline __device__ void s_bwd_prop_exp_1(DiffPair_vectorx3Cfloatx2C3x3E_0 * _S26, float3  _S27)
{
    _d_exp_vector_0(_S26, _S27);
    return;
}

struct DiffPair_vectorx3Cfloatx2C4x3E_0
{
    float4  primal_0;
    float4  differential_0;
};

inline __device__ void s_bwd_prop_sqrt_0(DiffPair_float_0 * _S28, float _S29)
{
    _d_sqrt_0(_S28, _S29);
    return;
}

inline __device__ void s_bwd_prop_length_impl_0(DiffPair_vectorx3Cfloatx2C4x3E_0 * dpx_6, float _s_dOut_0)
{
    float _S30 = (*dpx_6).primal_0.x;
    float _S31 = (*dpx_6).primal_0.y;
    float _S32 = (*dpx_6).primal_0.z;
    float _S33 = (*dpx_6).primal_0.w;
    DiffPair_float_0 _S34;
    (&_S34)->primal_0 = _S30 * _S30 + _S31 * _S31 + _S32 * _S32 + _S33 * _S33;
    (&_S34)->differential_0 = 0.0f;
    s_bwd_prop_sqrt_0(&_S34, _s_dOut_0);
    float _S35 = (*dpx_6).primal_0.w * _S34.differential_0;
    float _S36 = _S35 + _S35;
    float _S37 = (*dpx_6).primal_0.z * _S34.differential_0;
    float _S38 = _S37 + _S37;
    float _S39 = (*dpx_6).primal_0.y * _S34.differential_0;
    float _S40 = _S39 + _S39;
    float _S41 = (*dpx_6).primal_0.x * _S34.differential_0;
    float _S42 = _S41 + _S41;
    float4  _S43 = make_float4 (0.0f);
    *&((&_S43)->w) = _S36;
    *&((&_S43)->z) = _S38;
    *&((&_S43)->y) = _S40;
    *&((&_S43)->x) = _S42;
    dpx_6->primal_0 = (*dpx_6).primal_0;
    dpx_6->differential_0 = _S43;
    return;
}

inline __device__ void s_bwd_length_impl_0(DiffPair_vectorx3Cfloatx2C4x3E_0 * _S44, float _S45)
{
    s_bwd_prop_length_impl_0(_S44, _S45);
    return;
}

inline __device__ void per_splat_losses_bwd(float3  scales_1, float opacity_1, float4  quat_1, FixedArray<float, 5>  v_loss_0, float3  * v_scales_0, float * v_opacity_0, float4  * v_quat_0, float mcmc_opacity_reg_weight_1, float mcmc_scale_reg_weight_1, float max_gauss_ratio_1, float scale_regularization_weight_1, float erank_reg_weight_1, float erank_reg_weight_s3_1, float quat_norm_reg_weight_1)
{
    float _S46 = - opacity_1;
    float _S47 = 1.0f + s_primal_ctx_exp_0(_S46);
    float _S48 = _S47 * _S47;
    float _S49 = length_0(quat_1);
    float _S50 = mcmc_scale_reg_weight_1 * 0.00999999977648258f;
    float3  _S51 = s_primal_ctx_exp_1(scales_1);
    float x_5 = _S51.x;
    float y_3 = _S51.y;
    float z_2 = _S51.z;
    float _S52 = (F32_max((x_5), (y_3)));
    float _S53 = (F32_max((_S52), (z_2)));
    float _S54 = (F32_min((x_5), (y_3)));
    float _S55 = (F32_min((_S54), (z_2)));
    float _S56 = (F32_max((_S55), (1.00000000317107685e-30f)));
    float _S57 = _S53 / _S56;
    float _S58 = _S56 * _S56;
    float3  _S59 = make_float3 (2.0f) * scales_1;
    float3  _S60 = s_primal_ctx_exp_1(_S59);
    float x_6 = _S60.x;
    float y_4 = _S60.y;
    float z_3 = _S60.z;
    float _S61 = x_6 + y_4 + z_3;
    float _S62 = (F32_max((_S61), (1.00000000317107685e-30f)));
    float _S63 = (F32_max((x_6), (y_4)));
    float _S64 = (F32_max((_S63), (z_3)));
    float s1_1 = _S64 / _S62;
    float _S65 = _S62 * _S62;
    float _S66 = (F32_min((x_6), (y_4)));
    float _S67 = (F32_min((_S66), (z_3)));
    float s3_1 = _S67 / _S62;
    float _S68 = 1.0f - s1_1 - s3_1;
    float _S69 = (F32_max((_S68), (0.0f)));
    bool _S70 = s1_1 > 0.0f;
    float _S71;
    float _S72;
    if(_S70)
    {
        float _S73 = s_primal_ctx_log_0(s1_1);
        _S71 = s1_1 * _S73;
        _S72 = _S73;
    }
    else
    {
        _S71 = 0.0f;
        _S72 = 0.0f;
    }
    float _S74 = - _S71;
    bool _S75 = _S69 > 0.0f;
    float _S76;
    if(_S75)
    {
        float _S77 = s_primal_ctx_log_0(_S69);
        _S71 = _S69 * _S77;
        _S76 = _S77;
    }
    else
    {
        _S71 = 0.0f;
        _S76 = 0.0f;
    }
    float _S78 = _S74 - _S71;
    bool _S79 = s3_1 > 0.0f;
    float _S80;
    if(_S79)
    {
        float _S81 = s_primal_ctx_log_0(s3_1);
        _S71 = s3_1 * _S81;
        _S80 = _S81;
    }
    else
    {
        _S71 = 0.0f;
        _S80 = 0.0f;
    }
    float _S82 = _S78 - _S71;
    float _S83 = s_primal_ctx_exp_0(_S82) - 0.99998998641967773f;
    float _S84 = (F32_max((_S83), (9.99999971718068537e-10f)));
    float _S85 = erank_reg_weight_s3_1 * v_loss_0[int(3)];
    float _S86 = erank_reg_weight_1 * v_loss_0[int(3)];
    DiffPair_float_0 _S87;
    (&_S87)->primal_0 = - s_primal_ctx_log_0(_S84);
    (&_S87)->differential_0 = 0.0f;
    DiffPair_float_0 _S88;
    (&_S88)->primal_0 = 0.0f;
    (&_S88)->differential_0 = 0.0f;
    _d_max_0(&_S87, &_S88, _S86);
    float _S89 = - _S87.differential_0;
    DiffPair_float_0 _S90;
    (&_S90)->primal_0 = _S84;
    (&_S90)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S90, _S89);
    DiffPair_float_0 _S91;
    (&_S91)->primal_0 = _S83;
    (&_S91)->differential_0 = 0.0f;
    DiffPair_float_0 _S92;
    (&_S92)->primal_0 = 9.99999971718068537e-10f;
    (&_S92)->differential_0 = 0.0f;
    _d_max_0(&_S91, &_S92, _S90.differential_0);
    DiffPair_float_0 _S93;
    (&_S93)->primal_0 = _S82;
    (&_S93)->differential_0 = 0.0f;
    s_bwd_prop_exp_0(&_S93, _S91.differential_0);
    float _S94 = - _S93.differential_0;
    if(_S79)
    {
        float _S95 = s3_1 * _S94;
        float _S96 = _S80 * _S94;
        DiffPair_float_0 _S97;
        (&_S97)->primal_0 = s3_1;
        (&_S97)->differential_0 = 0.0f;
        s_bwd_prop_log_0(&_S97, _S95);
        _S71 = _S96 + _S97.differential_0 + _S85;
    }
    else
    {
        _S71 = _S85;
    }
    if(_S75)
    {
        float _S98 = _S69 * _S94;
        float _S99 = _S76 * _S94;
        DiffPair_float_0 _S100;
        (&_S100)->primal_0 = _S69;
        (&_S100)->differential_0 = 0.0f;
        s_bwd_prop_log_0(&_S100, _S98);
        _S76 = _S99 + _S100.differential_0;
    }
    else
    {
        _S76 = 0.0f;
    }
    if(_S70)
    {
        float _S101 = s1_1 * _S94;
        float _S102 = _S72 * _S94;
        DiffPair_float_0 _S103;
        (&_S103)->primal_0 = s1_1;
        (&_S103)->differential_0 = 0.0f;
        s_bwd_prop_log_0(&_S103, _S101);
        _S72 = _S102 + _S103.differential_0;
    }
    else
    {
        _S72 = 0.0f;
    }
    DiffPair_float_0 _S104;
    (&_S104)->primal_0 = _S68;
    (&_S104)->differential_0 = 0.0f;
    DiffPair_float_0 _S105;
    (&_S105)->primal_0 = 0.0f;
    (&_S105)->differential_0 = 0.0f;
    _d_max_0(&_S104, &_S105, _S76);
    float _S106 = - _S104.differential_0;
    float _S107 = (_S106 + _S71) / _S65;
    float _S108 = _S67 * - _S107;
    float _S109 = _S62 * _S107;
    DiffPair_float_0 _S110;
    (&_S110)->primal_0 = _S66;
    (&_S110)->differential_0 = 0.0f;
    DiffPair_float_0 _S111;
    (&_S111)->primal_0 = z_3;
    (&_S111)->differential_0 = 0.0f;
    _d_min_0(&_S110, &_S111, _S109);
    DiffPair_float_0 _S112;
    (&_S112)->primal_0 = x_6;
    (&_S112)->differential_0 = 0.0f;
    DiffPair_float_0 _S113;
    (&_S113)->primal_0 = y_4;
    (&_S113)->differential_0 = 0.0f;
    _d_min_0(&_S112, &_S113, _S110.differential_0);
    float _S114 = (_S106 + _S72) / _S65;
    float _S115 = _S64 * - _S114;
    float _S116 = _S62 * _S114;
    DiffPair_float_0 _S117;
    (&_S117)->primal_0 = _S63;
    (&_S117)->differential_0 = 0.0f;
    DiffPair_float_0 _S118;
    (&_S118)->primal_0 = z_3;
    (&_S118)->differential_0 = 0.0f;
    _d_max_0(&_S117, &_S118, _S116);
    DiffPair_float_0 _S119;
    (&_S119)->primal_0 = x_6;
    (&_S119)->differential_0 = 0.0f;
    DiffPair_float_0 _S120;
    (&_S120)->primal_0 = y_4;
    (&_S120)->differential_0 = 0.0f;
    _d_max_0(&_S119, &_S120, _S117.differential_0);
    float _S121 = _S108 + _S115;
    DiffPair_float_0 _S122;
    (&_S122)->primal_0 = _S61;
    (&_S122)->differential_0 = 0.0f;
    DiffPair_float_0 _S123;
    (&_S123)->primal_0 = 1.00000000317107685e-30f;
    (&_S123)->differential_0 = 0.0f;
    _d_max_0(&_S122, &_S123, _S121);
    float3  _S124 = make_float3 (_S112.differential_0 + _S119.differential_0 + _S122.differential_0, _S113.differential_0 + _S120.differential_0 + _S122.differential_0, _S111.differential_0 + _S118.differential_0 + _S122.differential_0);
    float3  _S125 = make_float3 (0.0f);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S126;
    (&_S126)->primal_0 = _S59;
    (&_S126)->differential_0 = _S125;
    s_bwd_prop_exp_1(&_S126, _S124);
    float3  _S127 = make_float3 (2.0f) * _S126.differential_0;
    float s_diff_scale_reg_T_0 = scale_regularization_weight_1 * v_loss_0[int(2)];
    DiffPair_float_0 _S128;
    (&_S128)->primal_0 = _S57;
    (&_S128)->differential_0 = 0.0f;
    DiffPair_float_0 _S129;
    (&_S129)->primal_0 = max_gauss_ratio_1;
    (&_S129)->differential_0 = 0.0f;
    _d_max_0(&_S128, &_S129, s_diff_scale_reg_T_0);
    float _S130 = _S128.differential_0 / _S58;
    float _S131 = _S53 * - _S130;
    float _S132 = _S56 * _S130;
    DiffPair_float_0 _S133;
    (&_S133)->primal_0 = _S55;
    (&_S133)->differential_0 = 0.0f;
    DiffPair_float_0 _S134;
    (&_S134)->primal_0 = 1.00000000317107685e-30f;
    (&_S134)->differential_0 = 0.0f;
    _d_max_0(&_S133, &_S134, _S131);
    DiffPair_float_0 _S135;
    (&_S135)->primal_0 = _S54;
    (&_S135)->differential_0 = 0.0f;
    DiffPair_float_0 _S136;
    (&_S136)->primal_0 = z_2;
    (&_S136)->differential_0 = 0.0f;
    _d_min_0(&_S135, &_S136, _S133.differential_0);
    DiffPair_float_0 _S137;
    (&_S137)->primal_0 = x_5;
    (&_S137)->differential_0 = 0.0f;
    DiffPair_float_0 _S138;
    (&_S138)->primal_0 = y_3;
    (&_S138)->differential_0 = 0.0f;
    _d_min_0(&_S137, &_S138, _S135.differential_0);
    DiffPair_float_0 _S139;
    (&_S139)->primal_0 = _S52;
    (&_S139)->differential_0 = 0.0f;
    DiffPair_float_0 _S140;
    (&_S140)->primal_0 = z_2;
    (&_S140)->differential_0 = 0.0f;
    _d_max_0(&_S139, &_S140, _S132);
    DiffPair_float_0 _S141;
    (&_S141)->primal_0 = x_5;
    (&_S141)->differential_0 = 0.0f;
    DiffPair_float_0 _S142;
    (&_S142)->primal_0 = y_3;
    (&_S142)->differential_0 = 0.0f;
    _d_max_0(&_S141, &_S142, _S139.differential_0);
    float3  _S143 = make_float3 (_S137.differential_0 + _S141.differential_0, _S138.differential_0 + _S142.differential_0, _S136.differential_0 + _S140.differential_0);
    DiffPair_vectorx3Cfloatx2C3x3E_0 _S144;
    (&_S144)->primal_0 = scales_1;
    (&_S144)->differential_0 = _S125;
    s_bwd_prop_exp_1(&_S144, _S143);
    float _S145 = _S50 * (0.3333333432674408f * v_loss_0[int(1)]);
    float s_diff_quat_norm_reg_T_0 = quat_norm_reg_weight_1 * v_loss_0[int(4)];
    float _S146 = - s_diff_quat_norm_reg_T_0;
    DiffPair_float_0 _S147;
    (&_S147)->primal_0 = _S49;
    (&_S147)->differential_0 = 0.0f;
    s_bwd_prop_log_0(&_S147, _S146);
    float _S148 = _S147.differential_0 + s_diff_quat_norm_reg_T_0;
    float4  _S149 = make_float4 (0.0f);
    DiffPair_vectorx3Cfloatx2C4x3E_0 _S150;
    (&_S150)->primal_0 = quat_1;
    (&_S150)->differential_0 = _S149;
    s_bwd_length_impl_0(&_S150, _S148);
    DiffPair_vectorx3Cfloatx2C4x3E_0 _S151 = _S150;
    float _S152 = - (mcmc_opacity_reg_weight_1 * v_loss_0[int(0)] / _S48);
    DiffPair_float_0 _S153;
    (&_S153)->primal_0 = _S46;
    (&_S153)->differential_0 = 0.0f;
    s_bwd_prop_exp_0(&_S153, _S152);
    float _S154 = - _S153.differential_0;
    float3  _S155 = _S127 + _S144.differential_0 + make_float3 (_S145, _S145, _S145);
    *v_scales_0 = _S155;
    *v_opacity_0 = _S154;
    *v_quat_0 = _S151.differential_0;
    return;
}


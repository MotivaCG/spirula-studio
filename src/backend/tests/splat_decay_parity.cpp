#include "backend/api/Densify.h"
#include "core/Tensor.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <utility>
#include <vector>

int main() {
    constexpr int64_t n = 513;
    std::vector<float> opacity(n), scales(3 * n);
    for (int64_t i = 0; i < n; ++i) {
        opacity[i] = -6.0f + float(i % 25) * 0.5f;
        for (int j = 0; j < 3; ++j) scales[3 * i + j] = -5.0f + 0.2f * j;
    }
    auto* d_opacity = static_cast<float*>(backend::device_malloc(n * sizeof(float)));
    auto* d_scales = static_cast<float*>(backend::device_malloc(3 * n * sizeof(float)));
    try {
        for (const auto rates : {std::pair<float, float>{0.0f, 0.0f},
                                 {0.02f, 0.0f}, {0.0f, 0.1f}, {0.02f, 0.1f}}) {
            backend::memcpy_sync(d_opacity, opacity.data(), n * sizeof(float),
                                 backend::MemcpyKind::HostToDevice);
            backend::memcpy_sync(d_scales, scales.data(), 3 * n * sizeof(float),
                                 backend::MemcpyKind::HostToDevice);
            splat_decay_tensor(n, rates.first, rates.second,
                DeviceVector<float>(TorchTensorView{(uint64_t)d_opacity, 4, {n, 1}}),
                DeviceVector<float3>(TorchTensorView{(uint64_t)d_scales, 4, {n, 3}}));
            std::vector<float> got_opacity(n), got_scales(3 * n);
            backend::memcpy_sync(got_opacity.data(), d_opacity, n * sizeof(float),
                                 backend::MemcpyKind::DeviceToHost);
            backend::memcpy_sync(got_scales.data(), d_scales, 3 * n * sizeof(float),
                                 backend::MemcpyKind::DeviceToHost);
            for (int64_t i = 0; i < n; ++i) {
                const double probability = std::max(1e-12,
                    1.0 / (1.0 + std::exp(-double(opacity[i]))) - rates.first);
                const double expected = rates.first > 0
                    ? std::log(probability / (1.0 - probability)) : opacity[i];
                if (!std::isfinite(got_opacity[i]) ||
                    std::fabs(got_opacity[i] - expected) > 2e-4)
                    throw std::runtime_error("opacity decay differs from probability subtraction");
                for (int j = 0; j < 3; ++j) {
                    const double expected_scale = scales[3 * i + j] + std::log(1.0 - rates.second);
                    if (!std::isfinite(got_scales[3 * i + j]) ||
                        std::fabs(got_scales[3 * i + j] - expected_scale) > 2e-6)
                        throw std::runtime_error("scale decay differs from multiplicative shrinkage");
                }
            }
        }
        if (const char* error = backend::last_error()) throw std::runtime_error(error);
    } catch (const std::exception& error) {
        std::fprintf(stderr, "%s\n", error.what());
        backend::device_free(d_opacity);
        backend::device_free(d_scales);
        return 1;
    }
    backend::device_free(d_opacity);
    backend::device_free(d_scales);
    std::puts("splat_decay_parity: PASSED");
}

#include "engine/Engine.h"
#include "engine/EngineState.h"
#include "engine/EngineTemporal.cpp"
#include <cstdio>

static TorchTensorView view(const void* p, uint32_t size, std::vector<int64_t> shape) {
    return {(uint64_t)p, size, std::move(shape)};
}
static TorchTensorView none() { return view(nullptr, 4, {0}); }
static float read_scalar(const float* p) {
    float x;
    backend::memcpy_sync(&x, p, sizeof(x), backend::MemcpyKind::DeviceToHost);
    return x;
}
int main() {
    try {
        constexpr int W = 64, H = 64, N = 2;
        int failed = 0;
        for (float alpha : {0.001f, 1.0f / 255 - 1e-5f, 1.0f / 255 + 1e-5f, 0.0045f}) {
            for (bool smoothing : {false, true}) {
                engine_reset();
                std::vector<float> means{-0.4f, 0, 3, 0.4f, 0, 3}, quats{1, 0, 0, 0, 1, 0, 0, 0};
                std::vector<float> scales(6, -2.5f), opac{1, std::log(alpha / (1 - alpha))};
                std::vector<float> dc(6, 0.4f), sh(90, 0);
                set_data_3dgs(N, view(means.data(), 4, {N, 3}), view(quats.data(), 4, {N, 4}),
                    view(scales.data(), 4, {N, 3}), view(opac.data(), 4, {N, 1}),
                    view(dc.data(), 4, {N, 3}), view(sh.data(), 4, {N, 15, 3}));
                engine_temporal_begin(3, false, true, false, 0);
                for (int f = 0; f < 3; ++f) engine_temporal_hold(f);
                engine_temporal_select(0);
                std::vector<float> vm{1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
                std::vector<float> intr{60, 60, 32, 32};
                std::vector<float> dist(kCameraDistortionParams, 0);
                auto render = [&]() {
                    set_camera_params(W, H, "PINHOLE", "NONE", view(vm.data(), 4, {1, 4, 4}),
                                      view(intr.data(), 4, {1, 4}), view(dist.data(), 4, {1, kCameraDistortionParams}));
                    forward_3dgs("3dgs", 0, false, false, 0);
                    std::vector<float> rgb(W * H * 3);
                    engine_copy_render_to_host(view(rgb.data(), 4, {1, H, W, 3}), none(), none(), none(), none());
                    return rgb;
                };
                auto before = render();
                const auto count = engine_temporal_birth({0.8f, 0, 3, 1, 0, 0, 0.8f}, .01f, 1);
                auto after = render();
                float error = 0;
                for (size_t i = 0; i < before.size(); ++i) error = std::max(error, std::abs(before[i] - after[i]));
                bool pass = error <= 1e-6f && count == (alpha < 1.0f / 255 ? 1 : 0);
                if (count) {
                    engine_temporal_select(1);
                    g_temporal->slots[1].held = false;
                    EngineStepConfig cfg{};
                    cfg.loss.weights[(int)LossWeightIndex::RgbSupL1] = 1;
                    cfg.loss.num_loss_scales = 1;
                    cfg.optim.lr_opacities = .05f;
                    cfg.optim.sh_value_bits = 32;
                    cfg.densify.refine_start_iter = 1000000;
                    cfg.densify.refine_every = 1000000;
                    std::vector<uint8_t> gt(W * H * 3, 255);
                    for (int step = 1; step <= 100; ++step) {
                        engine_train_step(step, 100, "3dgs", 0, false, W, H, "PINHOLE", "NONE",
                            view(vm.data(), 4, {1, 4, 4}), view(intr.data(), 4, {1, 4}), view(dist.data(), 4, {1, kCameraDistortionParams}),
                            view(gt.data(), 1, {1, H, W, 3}), none(), none(), none(), none(), cfg);
                        if (smoothing) engine_temporal_smooth({0, 0, 1, 0});
                    }
                    const float a = 1 / (1 + std::exp(-read_scalar(engine().world.opacities.data_ptr() + 1)));
                    pass &= std::isfinite(a) && a < 1.0f / 255;
                    auto actual = render();
                    const float hidden = -30;
                    backend::memcpy_sync(engine().world.opacities.data_ptr() + 1, &hidden, 4,
                                         backend::MemcpyKind::HostToDevice);
                    auto absent = render();
                    for (size_t i = 0; i < actual.size(); ++i)
                        pass &= std::isfinite(actual[i]) && std::abs(actual[i] - absent[i]) <= 1e-6f;
                }
                std::printf("{\"alpha\":%.9g,\"smoothing\":%s,\"births\":%lld,\"held_max_error\":%.9g,\"pass\":%s}\n",
                            alpha, smoothing ? "true" : "false", (long long)count, error, pass ? "true" : "false");
                failed += !pass;
                engine_temporal_end();
            }
        }
        engine_reset();
        return failed ? 1 : 0;
    } catch (const std::exception& e) {
        std::fprintf(stderr, "%s\n", e.what());
        return 2;
    }
}

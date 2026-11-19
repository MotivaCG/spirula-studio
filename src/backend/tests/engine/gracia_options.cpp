#include "app/TrainerCore.h"
#include "checkpoint/BackgroundExport.h"
#include "engine/Engine.h"
#include "engine/EngineState.h"

#include <chrono>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <limits>
#include <stdexcept>
#include <vector>

namespace {
void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

TorchTensorView view(std::vector<float>& values, std::vector<int64_t> shape) {
    return {(uint64_t)values.data(), 4, std::move(shape)};
}

uint64_t vertices(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary);
    for (std::string line; std::getline(input, line) && line != "end_header";) {
        const std::string prefix = "element vertex ";
        if (line.rfind(prefix, 0) == 0) return std::stoull(line.substr(prefix.size()));
    }
    throw std::runtime_error("PLY vertex count missing");
}

std::vector<char> bytes(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(input), {}};
}
}

int main() {
    namespace fs = std::filesystem;
    using namespace spirula;
    const fs::path root = fs::temp_directory_path() / ("ss-gracia-" +
        std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    try {
        TrainConfig cfg;
        cfg.steps_scaler = 0.5f;
        cfg.sh_degree_warmup_every = 1000;
        cfg.supervision_warmup = 0;
        cfg.max_steps = 100;
        const auto original = cfg;
        train_apply_steps_scaler(cfg);
        require(cfg.num_iterations == original.num_iterations / 2 &&
                cfg.calib_warp_start_iter == original.calib_warp_start_iter / 2 &&
                cfg.pca_reg_start_iter == original.pca_reg_start_iter / 2 &&
                cfg.sh_degree_warmup_every == 500 && cfg.max_steps == 50 &&
                cfg.supervision_warmup == 0 && cfg.cap_max == original.cap_max &&
                cfg.refine_every == original.refine_every,
                "step scaling changed budgets or failed to move stage boundaries");
        train_apply_steps_scaler(cfg);
        require(cfg.num_iterations == original.num_iterations / 2 && cfg.steps_scaler == 1.0f,
                "step scaling compounded");
        cfg.num_iterations = 100;
        cfg.background_mode = "sh";
        cfg.background_sh_degree = 4;
        cfg.sh_decay = 0.1f;
        RunState state;
        state.ppisp_init = state.ppisp_frozen = true;
        require(build_step_config(cfg, state, 0).background.sh_degree == 4 &&
                build_step_config(cfg, state, 10).background.sh_degree == 3 &&
                build_step_config(cfg, state, 50).background.sh_degree == 0 &&
                build_step_config(cfg, state, 50).ppisp.lr == 0.0f,
                "SH decay schedule or frozen PPISP changed");

        engine_reset();
        std::vector<float> means{0, 0, 3, 0, 0, 3, 0, 0, 3,
                                std::numeric_limits<float>::quiet_NaN(), 0, 3};
        std::vector<float> quats{1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0};
        std::vector<float> scales(12, -2), opacity{0, -20, 0, 0}, color(12, .5f), sh;
        scales[6] = scales[7] = scales[8] = -50;
        set_data_3dgs(4, view(means, {4, 3}), view(quats, {4, 4}), view(scales, {4, 3}),
                     view(opacity, {4, 1}), view(color, {4, 3}), view(sh, {4, 0, 3}), 0);
        engine_init_ppisp(3, "no_crf_no_vig", true, true);
        std::vector<float> fit(engine().ppisp.params.numel());
        for (size_t i = 0; i < fit.size(); ++i) fit[i] = 0.001f * float(i);
        backend::memcpy_sync(engine().ppisp.params.data_ptr(), fit.data(), fit.size() * sizeof(float),
                             backend::MemcpyKind::HostToDevice);
        engine_save_checkpoint(root.string(), true, 7, 16, "filtered");
        engine_save_checkpoint(root.string(), true, 7, 16, "teacher", false, true);
        require(vertices(root / "filtered.ply") == 1 && vertices(root / "teacher.ply") == 3,
                "keep-all export changed filtering of finite or non-finite splats");
        std::vector<float> restored(fit.size(), 0.0f);
        backend::memcpy_sync(engine().ppisp.params.data_ptr(), restored.data(), restored.size() * sizeof(float),
                             backend::MemcpyKind::HostToDevice);
        require(engine_load_ppisp((root / "teacher.tar").string()), "PPISP teacher archive did not load");
        backend::memcpy_sync(restored.data(), engine().ppisp.params.data_ptr(), restored.size() * sizeof(float),
                             backend::MemcpyKind::DeviceToHost);
        require(restored == fit, "PPISP reuse changed the saved fit");
        engine_init_ppisp(2, "no_crf_no_vig", true, true);
        require(!engine_load_ppisp((root / "teacher.tar").string()), "PPISP accepted a mismatched camera count");

        engine_init_background_sh(2, 0, false);
        engine_set_background_step_params(0, 0, 1, 0, 0);
        std::vector<float> coefficients(27, 0.02f);
        backend::memcpy_sync(engine().background.sh_coeffs.data_ptr(), coefficients.data(),
                             coefficients.size() * sizeof(float), backend::MemcpyKind::HostToDevice);
        engine_save_checkpoint((root / "sky-a").string(), false, 8, 16);
        for (size_t i = 3; i < coefficients.size(); ++i) coefficients[i] = 0.1f * float(i);
        backend::memcpy_sync(engine().background.sh_coeffs.data_ptr(), coefficients.data(),
                             coefficients.size() * sizeof(float), backend::MemcpyKind::HostToDevice);
        engine_save_checkpoint((root / "sky-b").string(), true, 8, 16);
        require(bytes(root / "sky-a/background.webp") == bytes(root / "sky-b/background.webp"),
                "inactive SH bands leaked into the exported background");
        require(ckpt::export_background_from_checkpoint(root / "sky-b", root / "standalone.webp", 32, 16) &&
                bytes(root / "standalone.webp") == bytes(root / "sky-b/background.webp"),
                "standalone export restored inactive SH bands");
        require(engine_load_checkpoint((root / "sky-b").string()) == 8 &&
                engine().background.cur_sh_degree == 0,
                "checkpoint resume restored inactive SH bands");
        if (const char* error = backend::last_error()) throw std::runtime_error(error);
        engine_reset();
    } catch (const std::exception& error) {
        std::fprintf(stderr, "%s\n", error.what());
        engine_reset();
        fs::remove_all(root);
        return 1;
    }
    fs::remove_all(root);
    std::puts("gracia_options: PASSED");
}

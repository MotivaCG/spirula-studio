// Runs the production host algorithm with CPU memory in place of GPU transfers.
#include "engine/EngineTemporal.cpp"
#include <iostream>
#include <iomanip>
#include <limits>

int failures = 0;
void result(const char* id, bool pass, double observed, double expected) {
    failures += !pass;
    std::cout << "{\"id\":\"" << id << "\",\"status\":\"" << (pass ? "PASS" : "FAIL")
              << "\",\"observed\":" << observed << ",\"expected\":" << expected << "}\n";
}
float logit(float a) { return std::log(a / (1 - a)); }
float alpha(float x) { return 1 / (1 + std::exp(-x)); }
void setup(int n = 4, int frames = 2, float opacity = 0.001f) {
    engine_temporal_end();
    engine() = EngineState{};
    auto& s = engine();
    s.cur_num_splats = n;
    s.world.means.reset(3 * n, -1);
    s.world.quats.reset(4 * n);
    for (int i = 0; i < n; ++i) s.world.quats.values[4 * i] = 1;
    s.world.opacities.reset(n, logit(opacity));
    s.world.features_dc.reset(3 * n);
    s.world.scales.reset(3 * n, std::log(0.01f));
    s.world.features_sh.reset(9 * n, 0.1f);
    for (auto* b : {&s.optim.g1_means, &s.optim.g2_means, &s.optim.g1_features_dc,
                   &s.optim.g2_features_dc, &s.optim.g1_scales, &s.optim.g2_scales}) b->reset(3 * n, 0.25f);
    for (auto* b : {&s.optim.g1_quats, &s.optim.g2_quats}) b->reset(4 * n, 0.25f);
    for (auto* b : {&s.optim.g1_opacities, &s.optim.g2_opacities}) b->reset(n, 0.25f);
    for (auto* b : {&s.optim.g1_features_sh, &s.optim.g2_features_sh}) b->reset(9 * n, 0.25f);
    s.optim.bias_correction_steps.reset(n);
    engine_temporal_begin(frames, false, true);
    for (int k = 0; k < frames; ++k) {
        s.dm = std::make_unique<DataManager>();
        engine_temporal_stash_data_manager(k);
    }
}
std::vector<float> candidate(float x = 0) { return {x, 0, 0, 1, 0.2f, 0.1f, 0.02f}; }
float slot_momentum(int frame) {
    const size_t params = g_temporal->splats * 11 * sizeof(float);
    float v;
    std::memcpy(&v, static_cast<char*>(g_temporal->slots[frame].mem) + params, sizeof v);
    return v;
}
int main() {
    std::cout << std::setprecision(9);
    setup();
    engine_temporal_hold(0);
    auto before = download(0);
    engine_temporal_birth(candidate(), 0.01f, 1);
    auto after = download(0);
    result("H01_held_parameters_unchanged", before.means == after.means && before.dc == after.dc,
           after.means[0] - before.means[0], 0);
    result("H02_old_row_below_raster_cutoff", alpha(after.opacities[0]) <= 1.0f / 255,
           alpha(after.opacities[0]), 1.0 / 255);
    result("H03_entering_moments_zero", slot_momentum(1) == 0, slot_momentum(1), 0);

    setup(1, 2, 0.0045f);
    auto rejected = engine_temporal_birth(candidate(), 0.01f, 1);
    result("H11_cutoff_overlap_rejected", rejected == 0, double(rejected), 0);

    setup(1);
    bool bad_gap = false, bad_shape = false, bad_value = false;
    try { engine_temporal_birth(candidate(), 0, 1); } catch (const std::runtime_error&) { bad_gap = true; }
    auto short_row = candidate();
    short_row.pop_back();
    try { engine_temporal_birth(short_row, 0.01f, 1); } catch (const std::runtime_error&) { bad_shape = true; }
    auto nan_row = candidate();
    nan_row[0] = std::numeric_limits<float>::quiet_NaN();
    try { engine_temporal_birth(nan_row, 0.01f, 1); } catch (const std::runtime_error&) { bad_value = true; }
    result("H12_bad_gap_rejected", bad_gap, bad_gap, 1);
    result("H13_truncated_point_rejected", bad_shape, bad_shape, 1);
    result("H14_nan_point_rejected", bad_value, bad_value, 1);

    setup();
    engine_temporal_birth(candidate(), 0.01f, 1);
    result("H04_repurposed_old_moments_zero", slot_momentum(0) == 0, slot_momentum(0), 0);

    setup();
    auto points = candidate();
    auto near = candidate(0.001f);
    points.insert(points.end(), near.begin(), near.end());
    auto count = engine_temporal_birth(points, 0.01f, 4);
    result("H05_birth_spacing", count == 1, double(count), 1);

    setup(1, 2, 0.5f);
    engine_temporal_hold(0);
    count = engine_temporal_birth(candidate(), 0.01f, 1);
    result("H06_visible_held_blocks_reuse", count == 0, double(count), 0);

    setup(1, 2, 0.001f);
    engine_temporal_birth(candidate(), 0.01f, 1);
    engine_temporal_smooth({0, 0, 1, 0});
    float a = alpha(download(0).opacities[0]);
    result("H07_no_prebirth_visibility_with_smoothing", a <= 1.0f / 255, a, 1.0 / 255);

    setup(1, 3, 0.001f);
    auto old = download(0);
    old.opacities[0] = logit(0.8f);
    upload(0, old);
    count = engine_temporal_birth(candidate(), 0.01f, 1);
    result("H08_history_blocks_reuse", count == 0, double(count), 0);
    engine_temporal_drop_front();
    count = engine_temporal_birth(candidate(), 0.01f, 1);
    const uint32_t generation = g_temporal->slots.back().generation[0];
    result("H09_row_reuse_gets_new_generation", count == 1 && generation == 1,
           double(generation), 1);

    setup(1);
    std::vector<TemporalBirth> events;
    engine_temporal_birth(candidate(), 0.01f, 1, &events);
    auto old_life = download(1);
    old_life.opacities[0] = logit(0.001f);
    upload(1, old_life);
    engine().dm = std::make_unique<DataManager>();
    engine_temporal_push(1, nullptr);
    engine_temporal_birth(candidate(1), 0.01f, 1, &events);
    const bool two_lives = events.size() == 2 && events[0].row == 0 &&
                           events[0].generation == 1 && events[1].row == 0 &&
                           events[1].generation == 2;
    result("H15_second_reuse_increments_generation", two_lives,
           events.empty() ? -1 : double(events.back().generation), 2);

    setup(1, 2, 0.8f);
    HostParams h = download(1);
    h.means = {0, 0, 0};
    TemporalWarp warp{{0, 0, 0, 0.1f, 0.2f, 0.3f, 1, 0, 0, 0}, 0.1f};
    apply_warp(warp, h);
    float err = std::abs(h.means[0] - 0.1f) + std::abs(h.means[1] - 0.2f) + std::abs(h.means[2] - 0.3f);
    result("H10_warp_translation", err < 1e-6f, err, 0);
    h.means = {0, 0, 0};
    h.quats = {1, 0, 0, 0};
    TemporalWarp bad_warp{{0, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 0.1f};
    apply_warp(bad_warp, h);
    const bool safe = h.means == std::vector<float>{0, 0, 0} &&
                      h.quats == std::vector<float>{1, 0, 0, 0};
    result("H16_degenerate_warp_node_skipped", safe, double(safe), 1);
    engine_temporal_end();
    return failures ? 1 : 0;
}

#include "vgsframe.h"
#include <cmath>
#include <cstring>
#include <iostream>
#include <iomanip>

int failures = 0;
void result(const char* id, bool pass, double observed, double expected) {
    failures += !pass;
    std::cout << "{\"id\":\"" << id << "\",\"status\":\"" << (pass ? "PASS" : "FAIL")
              << "\",\"observed\":" << observed << ",\"expected\":" << expected << "}\n";
}
void page(vgs::DecodedChunk& chunk, unsigned group, unsigned attr, const vgs::Bytes& bytes) {
    vgs::DecodedPage p;
    p.descriptor.group = group;
    p.descriptor.attribute = attr;
    p.descriptor.totalRows = p.descriptor.spec.rows = bytes.size();
    p.bytes = bytes;
    chunk.pages.push_back(p);
}
template<class T> vgs::Bytes bytes(const std::vector<T>& values) {
    vgs::Bytes b(values.size() * sizeof(T));
    std::memcpy(b.data(), values.data(), b.size());
    return b;
}
vgs::DecodedChunk fixture(unsigned intervals, unsigned begin, unsigned end) {
    vgs::DecodedChunk c;
    vgs::Group shared, splats;
    shared.intervals = splats.intervals = intervals;
    shared.counts[2] = shared.counts[3] = 5;
    splats.type = 1;
    splats.flags = 3;
    splats.splats = 1;
    splats.positionMax = intervals;
    c.groups = {shared, splats};
    page(c, 0, vgs::ScaleLut, bytes(std::vector<float>(256, 1)));
    page(c, 0, vgs::Sh0Lut, vgs::Bytes(512));
    page(c, 0, vgs::Sh0Trajectories, vgs::Bytes(5 * (intervals + 1) * 6));
    std::vector<uint16_t> opacity(5 * (intervals + 1));
    for (unsigned i = 0; i <= intervals; ++i) opacity[i] = 0x3c00;
    page(c, 0, vgs::OpacityTrajectories, bytes(opacity));
    page(c, 1, vgs::ScaleIndices, vgs::Bytes(3));
    page(c, 1, vgs::Lifetimes, vgs::Bytes{uint8_t(begin), uint8_t(end)});
    page(c, 1, vgs::Sh0Base, vgs::Bytes(3));
    page(c, 1, vgs::Sh0Terms, vgs::Bytes(8));
    page(c, 1, vgs::OpacityTerms, vgs::Bytes(8));
    std::vector<uint64_t> pos;
    for (unsigned i = 0; i <= intervals; ++i) {
        uint64_t x = uint64_t(std::llround(double(i) * 2097151 / intervals));
        pos.push_back(x << 43);
    }
    page(c, 1, vgs::PositionSamples, bytes(pos));
    page(c, 1, vgs::RotationSamples, bytes(std::vector<uint32_t>(intervals + 1,
         (3u << 30) | (512u << 20) | (512u << 10) | 512u)));
    return c;
}
int main() {
    std::cout << std::setprecision(9);
    auto c = fixture(4, 1, 3);
    vgs::FrameDecoder decoder(c);
    auto f = decoder.evaluate(0.375, false);
    result("V01_direct_position_subframe_linear", std::abs(f.position[0] - 1.5f) < 1e-5,
           f.position[0], 1.5);
    auto knot = decoder.evaluate(0.25, false);
    result("V02_direct_position_sample_exact", std::abs(knot.position[0] - 1) < 1e-5,
           knot.position[0], 1);
    vgs::FrameDecoder one(fixture(1, 0, 1));
    auto middle = one.evaluate(0.5, false);
    result("V03_one_interval_position", std::abs(middle.position[0] - 0.5) < 1e-5,
           middle.position[0], 0.5);
    bool lifetime = !decoder.evaluate(0.249, false).active[0] && knot.active[0]
        && decoder.evaluate(0.749, false).active[0] && !decoder.evaluate(0.75, false).active[0];
    result("V04_lifetime_half_open", lifetime, lifetime, 1);
    std::vector<float> pos;
    decoder.evaluatePositions(0.375, &pos);
    result("V05_positions_and_full_agree", pos[0] == f.position[0], pos[0] - f.position[0], 0);
    result("V06_scale_static_per_record", f.scale == knot.scale, f.scale[0], 1);
    bool rejects = false;
    try { decoder.evaluate(1, false); } catch (const vgs::Error&) { rejects = true; }
    result("V07_endpoint_requires_explicit_policy", rejects, rejects, 1);
    return failures ? 1 : 0;
}

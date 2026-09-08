// Events.cpp -- see Events.h.

#include "sfm/core/Events.h"

#include <mutex>

namespace sfm {
namespace events {

namespace {
std::mutex g_mu;
Sink g_sink;
}  // namespace

void set_sink(Sink s) {
    std::lock_guard<std::mutex> lk(g_mu);
    g_sink = std::move(s);
}

bool armed() {
    std::lock_guard<std::mutex> lk(g_mu);
    return (bool)g_sink;
}

// Verification calls this from its worker pool, so the lock is what orders
// the stream; a sink must not call back into sfm::events.
void emit(const Event& e) {
    std::lock_guard<std::mutex> lk(g_mu);
    if (g_sink) g_sink(e);
}

void stage_begin(Stage s, int64_t total) {
    Event e;
    e.kind = Event::Kind::StageBegin;
    e.stage = s;
    e.total = total;
    emit(e);
}

void stage_end(Stage s) {
    Event e;
    e.kind = Event::Kind::StageEnd;
    e.stage = s;
    emit(e);
}

void progress(Stage s, int64_t done, int64_t total) {
    Event e;
    e.kind = Event::Kind::Progress;
    e.stage = s;
    e.done = done;
    e.total = total;
    emit(e);
}

}  // namespace events
}  // namespace sfm

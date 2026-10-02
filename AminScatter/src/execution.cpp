#include "execution.h"
#include <algorithm>
#include <atomic>
#include <stdexcept>

namespace amin {
namespace {
std::atomic<unsigned> threadLimit{0};
thread_local ComputeStats stats;
}
void setComputeThreads(unsigned limit) {
    if (limit > 64) throw std::invalid_argument("CPU thread limit must be 0..64");
    threadLimit.store(limit, std::memory_order_relaxed);
}
unsigned computeThreads() { return threadLimit.load(std::memory_order_relaxed); }
unsigned computeParticipants() {
    const auto available = std::max(1u, std::thread::hardware_concurrency());
    const auto requested = computeThreads();
    return std::max(1u, std::min(available, requested ? requested : 4u));
}
ComputeStats lastComputeStats() { return stats; }
namespace detail { void recordComputeStats(ComputeStats value) { stats = value; } }
}

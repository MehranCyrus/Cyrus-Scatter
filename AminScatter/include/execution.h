#pragma once
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <stdexcept>
#include <system_error>
#include <thread>
#include <vector>
#include <cfenv>
#if defined(_M_X64) || defined(__SSE2__)
#include <xmmintrin.h>
#endif

namespace amin {
// Session policy, never a scene parameter. 0 = automatic (at most 4 total
// participants); 1 = serial. Workers use owned numeric data only.
void setComputeThreads(unsigned limit);
unsigned computeThreads();
unsigned computeParticipants();
struct ComputeStats {
    unsigned participants{1};
    std::uint64_t clusterQueries{};
    bool threadLaunchFallback{false};
};
ComputeStats lastComputeStats();

namespace detail {
void recordComputeStats(ComputeStats stats);
struct RangeExecution { unsigned participants{1}; bool threadLaunchFallback{false}; };

// Synchronous, contiguous ranges. The calling thread participates; every worker
// is joined before returning or propagating the earliest indexed failure. No
// pool, detached work, loader initialization or third-party runtime is involved.
template<class F>
RangeExecution forRanges(std::size_t count, std::size_t minimumParallelItems, F fn) {
    const auto participants = count < minimumParallelItems ? 1u :
        static_cast<unsigned>(std::min<std::size_t>(computeParticipants(), count));
    if (participants <= 1) { fn(0, 0, count); return {}; }
    std::fenv_t environment;
    if (std::fegetenv(&environment) != 0) { fn(0, 0, count); return {1, true}; }
#if defined(_M_X64) || defined(__SSE2__)
    const auto simdEnvironment = _mm_getcsr();
#endif
    std::vector<std::exception_ptr> failures(participants);
    std::vector<std::thread> workers;
    workers.reserve(participants - 1);
    const auto run = [&](unsigned slot) {
        try {
            if (slot != 0) {
                if (std::fesetenv(&environment) != 0)
                    throw std::runtime_error("Could not copy compute floating-point environment");
#if defined(_M_X64) || defined(__SSE2__)
                _mm_setcsr(simdEnvironment);
#endif
            }
            // Quotient/remainder partition avoids count * slot overflow.
            const auto width = count / participants, remainder = count % participants;
            const auto begin = width * slot + std::min<std::size_t>(slot, remainder);
            fn(slot, begin, begin + width + (slot < remainder ? 1 : 0));
        } catch (...) { failures[slot] = std::current_exception(); }
    };
    try {
        for (unsigned slot = 1; slot < participants; ++slot) workers.emplace_back(run, slot);
    } catch (...) {
        for (auto& worker : workers) worker.join();
        // Recompute all slots serially; partial speculative values never escape.
        fn(0, 0, count);
        return {1, true};
    }
    run(0);
    for (auto& worker : workers) worker.join();
    for (const auto& failure : failures) if (failure) std::rethrow_exception(failure);
    return {participants, false};
}
}
}

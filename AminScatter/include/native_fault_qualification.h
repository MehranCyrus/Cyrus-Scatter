#pragma once
// Closed, nonshipping qualification seam. Normal modules contain no control,
// state or exception path. Tests simulate failure without exhausting host RAM.
#ifdef CYRUS_PLACEMENT_QUALIFICATION
#include <atomic>
#include <new>
namespace cyrus::owned {
inline std::atomic<int> faultStage{0},faultOccurrence{0},faultHits{0};
inline void fault(int stage){if(faultStage.load()==stage&&++faultHits>=faultOccurrence.load())throw std::bad_alloc();}
}
#else
namespace cyrus::owned {inline void fault(int)noexcept{}}
#endif

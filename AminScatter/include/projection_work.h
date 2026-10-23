#pragma once
#include <algorithm>
#include <cstdint>
#include <limits>
#include <stdexcept>

namespace amin {
// One synchronous successor owns this allowance; receiver calls only borrow it.
// Units charge every build face/comparison, query bound and exact triangle test,
// even when density or later eligibility rejects the candidate. No reset on a
// receiver boundary. Scratch is live index storage, released at call return.
struct ProjectionWorkBudget {
    static constexpr std::uint64_t defaultWorkLimit=200000000;
    static constexpr std::uint64_t defaultScratchLimit=256ULL*1024*1024;
    std::uint64_t workLimit=defaultWorkLimit,scratchLimit=defaultScratchLimit;
    std::uint64_t builds=0,queries=0,buildUnits=0,nodeVisits=0,triangleTests=0;
    std::uint64_t workUsed=0,peakScratchBytes=0,currentScratchBytes=0;

    void charge(std::uint64_t& counter,std::uint64_t amount=1) {
        if(workUsed>workLimit||amount>workLimit-workUsed||amount>std::numeric_limits<std::uint64_t>::max()-counter)
            throw std::invalid_argument("Projected movement exceeded the shared solve work limit. Reduce Count or receiver complexity; the previous result is retained.");
        workUsed+=amount;counter+=amount;
    }
    void acquire(std::uint64_t bytes) {
        if(currentScratchBytes>scratchLimit||bytes>scratchLimit-currentScratchBytes)
            throw std::invalid_argument("Projected movement exceeded the shared solve scratch memory limit. Reduce receiver complexity; the previous result is retained.");
        currentScratchBytes+=bytes;peakScratchBytes=std::max(peakScratchBytes,currentScratchBytes);
    }
    void release(std::uint64_t bytes) noexcept {currentScratchBytes-=bytes;}
};
}

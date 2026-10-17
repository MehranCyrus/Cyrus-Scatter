#pragma once
#include <cstdint>
#include <limits>
#include <stdexcept>
namespace cyrus::script_memory {
// A session allocation, not a saved Max heap preference. Keep an OS/host reserve.
inline std::uint64_t target(std::uint64_t heap,std::uint64_t free,
                            std::uint64_t required,std::uint64_t availableCommit) {
    if(free>heap)throw std::invalid_argument("Invalid script heap accounting");
    if(free>=required)return heap;
    constexpr std::uint64_t chunk=64ULL*1024*1024,margin=16ULL*1024*1024,hostReserve=256ULL*1024*1024;
    const auto deficit=required-free;
    if(heap>std::numeric_limits<std::uint64_t>::max()-margin-chunk||
       deficit>std::numeric_limits<std::uint64_t>::max()-heap-margin-chunk)
        throw std::overflow_error("Script workspace size overflow");
    const auto wanted=((heap+deficit+margin+chunk-1)/chunk)*chunk;
    if(wanted>std::uint64_t(std::numeric_limits<std::int64_t>::max()))throw std::overflow_error("Script workspace exceeds host integer size");
    const auto growth=wanted-heap;
    if(availableCommit<hostReserve||growth>availableCommit-hostReserve)
        throw std::runtime_error("Insufficient system commit headroom for the Update workspace");
    return wanted;
}
}

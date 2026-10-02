#include "preview_sampling.h"
#include <algorithm>
#include <array>
#include <cstdint>
#include <iostream>
#include <limits>
#include <stdexcept>

void require(bool value) { if(!value)throw std::runtime_error("Preview sample coverage regression"); }
int main() {
    // Exhaust small populations against the exact rational oracle. Every cap is
    // filled without repeats, out-of-range indices or reordering.
    for(std::uint64_t total=1;total<=500;++total) for(std::uint64_t budget=1;budget<=501;++budget) {
        const auto shown=std::min(total,budget);
        std::uint64_t previous=0;
        for(std::uint64_t i=0;i<shown;++i) {
            const auto index=amin::previewPointIndex(i,total,shown);
            require(index==(i*total)/shown && index<total && (i==0 || index>previous));
            previous=index;
        }
    }
    // One extra plant/sample must not nearly halve the visible point population.
    for(auto total:std::array<std::uint64_t,6>{500000,500001,500100,1000000,1000001,std::numeric_limits<std::uint64_t>::max()}) {
        constexpr std::uint64_t shown=500000;
        std::uint64_t previous=0;
        for(std::uint64_t i=0;i<shown;++i) {
            const auto index=amin::previewPointIndex(i,total,shown);
            require(index<total && (i==0 || index>previous));previous=index;
        }
        require(amin::previewPointIndex(0,total,shown)==0);
        require(total-previous<=total/shown+1);
    }
    std::cout<<"PASS exact budget, unique ordered coverage, boundary continuity, uint64 bounds\n";
}

#pragma once
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <vector>

namespace cyrus {
// Controller totals: idle/navigating points, proxy instances, mesh triangles.
// Zero removes the artist cap. Resource admission remains independent.
struct ViewportLimits {
    std::array<std::uint64_t,6> values{};
    bool operator==(const ViewportLimits& other) const { return values==other.values; }
    bool operator!=(const ViewportLimits& other) const { return !(*this==other); }
};
struct ViewportDemand { std::size_t count=0,cost=1; };
struct ViewportQuota { std::size_t count=0,cost=1;bool box=false; };

inline std::vector<ViewportQuota> viewportQuotas(const std::vector<ViewportDemand>& input,
                                               std::uint64_t limit,bool mesh=false,bool boxes=false) {
    std::vector<ViewportQuota> out(input.size());
    const auto active=std::count_if(input.begin(),input.end(),[](const auto& g){return g.count>0;});
    const auto share=active && limit ? limit/static_cast<std::uint64_t>(active) : 0;
    std::uint64_t remaining=limit;
    for(std::size_t i=0;i<input.size();++i) {
        auto& q=out[i];q.cost=std::max<std::size_t>(1,input[i].cost);
        q.box=mesh && (boxes || (limit && q.cost>std::max<std::uint64_t>(12,share)));
        if(q.box)q.cost=12;
        q.count=limit?std::min<std::uint64_t>(input[i].count,share/q.cost):input[i].count;
        if(limit)remaining-=q.count*q.cost;
    }
    // One bounded remainder pass. Prefer cheap groups without starving every
    // other source: each already received its fair-share admission above.
    if(limit) {
        std::vector<std::size_t> order(input.size());std::iota(order.begin(),order.end(),0);
        std::stable_sort(order.begin(),order.end(),[&](auto a,auto b){return out[a].cost<out[b].cost;});
        for(auto i:order) {
            auto& q=out[i];const auto extra=std::min<std::uint64_t>(input[i].count-q.count,remaining/q.cost);
            q.count+=static_cast<std::size_t>(extra);remaining-=extra*q.cost;
        }
    }
    return out;
}

// A fixed permutation of the prepared snapshot. Shorter draw prefixes remain
// nested and spread through the source instead of collecting at its first rows.
inline std::size_t viewportStride(std::size_t count) {
    if(count<2)return 1;
    auto stride=std::max<std::size_t>(1,count*618033/1000000);
    while(std::gcd(stride,count)!=1)++stride;
    return stride;
}
}

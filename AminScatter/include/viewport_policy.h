#pragma once
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <stdexcept>
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

struct ViewportDrawGroup {ViewportQuota idle,navigation;bool full=false;};
struct ViewportMeshLayer {
    bool lines=false;
    int mode=0;
    ViewportLimits limits;
    std::vector<ViewportDemand> groups;
    std::vector<bool> reduced;
};
// One shared controller-level policy for drawing and compact-pose admission.
inline std::vector<std::vector<ViewportDrawGroup>> viewportMeshPlan(const std::vector<ViewportMeshLayer>& layers,bool boxes=false){
    std::vector<std::vector<ViewportDrawGroup>> result(layers.size());
    for(std::size_t l=0;l<layers.size();++l)result[l].resize(layers[l].groups.size());
    for(int mode=1;mode<3;++mode){
        std::vector<ViewportDemand> demand;std::vector<std::pair<std::size_t,std::size_t>> owners;ViewportLimits limits;
        for(std::size_t l=0;l<layers.size();++l){const auto& layer=layers[l];if(layer.lines)continue;limits=layer.limits;
            if((mode==2)!=(layer.mode==4))continue;
            for(std::size_t g=0;g<layer.groups.size();++g){auto d=layer.groups[g];if(mode==1)d.cost=1;demand.push_back(d);owners.emplace_back(l,g);}}
        auto idle=viewportQuotas(demand,limits.values[mode*2],mode==2,boxes);
        auto moving=viewportQuotas(demand,limits.values[mode*2+1],mode==2,boxes);
        for(std::size_t i=0;i<owners.size();++i){const auto [l,g]=owners[i];
            if(mode==2&&layers[l].reduced.at(g))idle[i].box=moving[i].box=true;
            result[l][g]={idle[i],moving[i],(!idle[i].box&&idle[i].count)||(!moving[i].box&&moving[i].count)};}
    }
    return result;
}
// Inverse of the existing draw permutation, computed once per source rather
// than visiting every placement to find the few admitted poses.
class ViewportRanks {
    std::uint64_t count_=0,inverse_=0;
public:
    explicit ViewportRanks(std::size_t count):count_(count){
        if(count>0xffffffffull)throw std::invalid_argument("Viewport permutation exceeds instance admission");
        if(count<2){inverse_=1;return;}
        std::int64_t oldR=static_cast<std::int64_t>(count),r=static_cast<std::int64_t>(viewportStride(count));
        std::int64_t oldT=0,t=1;
        while(r){const auto q=oldR/r;const auto nextR=oldR-q*r;oldR=r;r=nextR;const auto nextT=oldT-q*t;oldT=t;t=nextT;}
        inverse_=static_cast<std::uint64_t>((oldT%static_cast<std::int64_t>(count)+static_cast<std::int64_t>(count))%static_cast<std::int64_t>(count));
    }
    std::size_t rank(std::size_t slot)const{
        if(slot>=count_)throw std::out_of_range("Viewport source slot exceeds instance admission");
        return static_cast<std::size_t>((std::uint64_t(slot)*inverse_)%count_);
    }
};
}

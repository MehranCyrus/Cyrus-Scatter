#pragma once
#include <cyrus_vegetation/prototype_v1.hpp>
#include <array>
#include <bit>
#include <cstdint>

namespace cyrus::interactions::detail {
// One entry belongs to one GuideMeshCheck, so its source, obstacle generation,
// clearance and attachment bindings cannot change. Reusing only the immediately
// preceding candidate also preserves that check's already-skinned points.
struct GuideCandidateMemo {
    using Guide=vegetation::prototype_v1::RestGuide;
    using Vec=vegetation::prototype_v1::Vec3;
    using Quat=vegetation::prototype_v1::Quat;
    static constexpr std::size_t maximumNodes=16;
    std::array<Vec,maximumNodes> nodes{};
    std::array<Quat,maximumNodes> frames{};
    vegetation::prototype_v1::Id guide=0;
    std::size_t count=0,work=0;
    bool valid=false,smooth=false,clear=false;
    static bool same(double a,double b){return std::bit_cast<std::uint64_t>(a)==std::bit_cast<std::uint64_t>(b);}
    bool matches(const Guide& candidate,bool smoothRoot)const{
        if(!valid||smooth!=smoothRoot||guide!=candidate.guide_id||count!=candidate.nodes.size()||count!=candidate.material_frames.size())return false;
        for(std::size_t i=0;i<count;++i){const auto& p=candidate.nodes[i];const auto& q=candidate.material_frames[i];
            if(!same(nodes[i].x,p.x)||!same(nodes[i].y,p.y)||!same(nodes[i].z,p.z)||
               !same(frames[i].x,q.x)||!same(frames[i].y,q.y)||!same(frames[i].z,q.z)||!same(frames[i].w,q.w))return false;}
        return true;
    }
    void remember(const Guide& candidate,bool smoothRoot,bool outcome,std::size_t logicalWork=0){
        valid=false;if(candidate.nodes.size()>maximumNodes||candidate.nodes.size()!=candidate.material_frames.size())return;
        guide=candidate.guide_id;count=candidate.nodes.size();smooth=smoothRoot;clear=outcome;work=logicalWork;
        for(std::size_t i=0;i<count;++i){nodes[i]=candidate.nodes[i];frames[i]=candidate.material_frames[i];}valid=true;
    }
};
static_assert(sizeof(GuideCandidateMemo)<=1024,"Update the admitted candidate memo charge if its bound changes");
inline constexpr std::size_t guideCandidateMemoBytes=sizeof(GuideCandidateMemo);
}

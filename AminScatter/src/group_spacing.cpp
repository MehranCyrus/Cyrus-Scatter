#include "group_spacing.h"
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <stdexcept>
#include <unordered_map>

namespace cyrus::groups {
namespace {
struct Cell {
    std::int64_t x,y,z;
    bool operator==(const Cell& b)const {return x==b.x&&y==b.y&&z==b.z;}
};
struct Hash {
    std::size_t operator()(Cell c)const {
        return std::hash<std::int64_t>{}(c.x)^(std::hash<std::int64_t>{}(c.y)*0x9e3779b9u)^(std::hash<std::int64_t>{}(c.z)*0x85ebca6bu);
    }
};
void valid(amin::Vec3 p) {
    if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z))throw std::invalid_argument("Non-finite planting position");
}
double maximum(const std::vector<double>& values,std::size_t size) {
    if(values.size()!=size)throw std::invalid_argument("Planting radius count mismatch");
    double m=0;
    for(double r:values){if(!std::isfinite(r)||r<0)throw std::invalid_argument("Invalid planting radius");m=std::max(m,r);}
    return m;
}
double squared(amin::Vec3 a,amin::Vec3 b,bool planar) {
    const auto d=a-b;return d.x*d.x+d.y*d.y+(planar?0:d.z*d.z);
}
struct Grid {
    double width;
    bool planar;
    std::unordered_map<Cell,std::vector<std::size_t>,Hash> cells;
    Grid(double w,bool p,std::size_t count):width(w),planar(p){cells.reserve(count);}
    Cell cell(amin::Vec3 p)const {
        const auto axis=[&](double a){
            const double c=std::floor(a/width);
            if(!std::isfinite(c)||std::abs(c)>9e15)throw std::invalid_argument("Planting spacing too small for scene coordinates");
            return static_cast<std::int64_t>(c);
        };
        return {axis(p.x),axis(p.y),planar?0:axis(p.z)};
    }
    void add(amin::Vec3 p,std::size_t i){if(width>0)cells[cell(p)].push_back(i);}
    template<class F> bool hit(amin::Vec3 p,F predicate)const {
        if(width<=0)return false;
        const auto c=cell(p);
        for(int z=planar?0:-1;z<=(planar?0:1);++z)for(int y=-1;y<=1;++y)for(int x=-1;x<=1;++x){
            const auto it=cells.find({c.x+x,c.y+y,c.z+z});
            if(it!=cells.end())for(auto i:it->second)if(predicate(i))return true;
        }
        return false;
    }
};
}
Result resolve(const std::vector<amin::Vec3>& positions,double withinDistance,
               const std::vector<Rule>& rules,const std::vector<bool>& protect) {
    if(!std::isfinite(withinDistance)||withinDistance<0||protect.size()!=positions.size())throw std::invalid_argument("Invalid group spacing settings");
    for(auto p:positions)valid(p);
    std::vector<Grid> obstacles;obstacles.reserve(rules.size());
    for(const auto& rule:rules){
        if(!std::isfinite(rule.gap)||rule.gap<0)throw std::invalid_argument("Invalid planting gap");
        const double width=rule.gap+maximum(rule.ownRadii,positions.size())+maximum(rule.blockerRadii,rule.blockers.size());
        if(!std::isfinite(width))throw std::invalid_argument("Planting radii overflow");
        obstacles.emplace_back(width,rule.planar,rule.blockers.size());
        for(std::size_t j=0;j<rule.blockers.size();++j){valid(rule.blockers[j]);obstacles.back().add(rule.blockers[j],j);}
    }
    const auto external=[&](std::size_t i){
        for(std::size_t k=0;k<rules.size();++k){const auto& r=rules[k];
            if(obstacles[k].hit(positions[i],[&](std::size_t j){const double distance=r.gap+r.ownRadii[i]+r.blockerRadii[j];return squared(positions[i],r.blockers[j],r.planar)<distance*distance;}))return true;
        }
        return false;
    };
    Grid own(withinDistance,false,positions.size());
    std::vector<bool> kept=protect,conflict(positions.size(),false);
    for(std::size_t i=0;i<positions.size();++i)if(protect[i])own.add(positions[i],i);
    const auto nearby=[&](std::size_t i){return own.hit(positions[i],[&](std::size_t j){return i!=j&&squared(positions[i],positions[j],false)<withinDistance*withinDistance;});};
    for(std::size_t i=0;i<positions.size();++i)if(protect[i])conflict[i]=external(i)||nearby(i);
    for(std::size_t i=0;i<positions.size();++i)if(!protect[i]&&!external(i)&&!nearby(i)){kept[i]=true;own.add(positions[i],i);}
    Result result;
    for(std::size_t i=0;i<positions.size();++i){if(kept[i])result.kept.push_back(i);if(conflict[i])result.conflicts.push_back(i);}
    return result;
}
DetailedResult resolveVariable(const std::vector<amin::Vec3>& positions,
    const std::vector<double>& radii,const DistanceRule& self,
    const std::vector<ScopedRule>& rules,const std::vector<bool>& protect,std::size_t target,std::uint64_t maxNeighborVisits) {
    if(protect.size()!=positions.size())throw std::invalid_argument("Protected flag count mismatch");
    for(auto p:positions){valid(p);if(std::max({std::abs(p.x),std::abs(p.y),std::abs(p.z)})>1e150)throw std::invalid_argument("Procedural coordinates exceed numeric range");}
    const double radiusMax=maximum(radii,positions.size());
    const auto check=[](double k,double gap){
        if(!std::isfinite(k)||k<0||!std::isfinite(gap)||gap<0)throw std::invalid_argument("Invalid procedural distance rule");
    };
    check(self.multiplier,self.gap);
    const double selfReach=self.enabled?self.multiplier*(2*radiusMax)+self.gap:0;
    if(!std::isfinite(selfReach)||selfReach>1e150)throw std::invalid_argument("Self radius overflow");
    std::vector<Grid> grids;grids.reserve(rules.size());
    for(const auto& rule:rules){
        const auto& r=rule.values;check(rule.multiplier,r.gap);
        if(rule.reason!=Reason::LayerSpacing&&rule.reason!=Reason::SetSpacing)throw std::invalid_argument("Invalid spacing scope");
        const double width=rule.multiplier*(maximum(r.ownRadii,positions.size())+maximum(r.blockerRadii,r.blockers.size()))+r.gap;
        if(!std::isfinite(width)||width>1e150)throw std::invalid_argument("Pair radius overflow");
        grids.emplace_back(width,r.planar,r.blockers.size());
        for(std::size_t j=0;j<r.blockers.size();++j){const auto p=r.blockers[j];valid(p);if(std::max({std::abs(p.x),std::abs(p.y),std::abs(p.z)})>1e150)throw std::invalid_argument("Procedural blocker exceeds numeric range");grids.back().add(p,j);}
    }
    DetailedResult result;result.reasons.assign(positions.size(),Reason::NotConsumed);
    const auto visit=[&](){if(result.neighborVisits>=maxNeighborVisits)throw std::invalid_argument("Procedural spacing work limit exceeded; reduce candidate count, radius variation or retry rounds");++result.neighborVisits;};
    Grid own(selfReach,self.planar,positions.size());
    std::size_t accepted=0;
    for(std::size_t i=0;i<positions.size();++i)if(protect[i]){own.add(positions[i],i);++accepted;}
    const auto violation=[&](std::size_t i){
        for(std::size_t k=0;k<rules.size();++k){const auto& rule=rules[k];const auto& r=rule.values;
            if(grids[k].hit(positions[i],[&](std::size_t j){
                visit();const double d=rule.multiplier*(r.ownRadii[i]+r.blockerRadii[j])+r.gap;
                return squared(positions[i],r.blockers[j],r.planar)<d*d;
            }))return rule.reason;
        }
        if(own.hit(positions[i],[&](std::size_t j){
            visit();const double d=self.multiplier*(radii[i]+radii[j])+self.gap;
            return i!=j&&squared(positions[i],positions[j],self.planar)<d*d;
        }))return Reason::SelfSpacing;
        return Reason::Accepted;
    };
    for(std::size_t i=0;i<positions.size();++i)if(protect[i]){
        if(violation(i)!=Reason::Accepted)result.conflicts.push_back(i);
        result.reasons[i]=Reason::Protected;
    }
    for(std::size_t i=0;i<positions.size();++i)if(!protect[i]&&accepted<target){
        result.reasons[i]=violation(i);
        if(result.reasons[i]==Reason::Accepted){own.add(positions[i],i);++accepted;}
    }
    for(std::size_t i=0;i<positions.size();++i)
        if(result.reasons[i]==Reason::Accepted||result.reasons[i]==Reason::Protected)result.kept.push_back(i);
    return result;
}
}

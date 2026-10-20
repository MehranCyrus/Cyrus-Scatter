#include "cyrus_arrange/placement_queries.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <map>
#include <set>
#include <stdexcept>
using namespace cyrus::arrange;
namespace {
std::size_t checks{};
void check(bool value,const char* message){++checks;if(!value)throw std::runtime_error(message);}
template<class F>void rejects(F f,const char* message){bool threw=false;try{f();}catch(const std::exception&){threw=true;}check(threw,message);}
Mesh box(double x,double y,double h,double dx=0,double z=0){Mesh m;m.vertices={{dx-x/2,-y/2,z},{dx+x/2,-y/2,z},{dx+x/2,y/2,z},{dx-x/2,y/2,z},{dx-x/2,-y/2,z+h},{dx+x/2,-y/2,z+h},{dx+x/2,y/2,z+h},{dx-x/2,y/2,z+h}};m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;}
Asset source(std::uint64_t id,double x,double y,double h){Asset a;a.id=id;a.name="Physical source";a.mesh=box(x,y,h);a.allowed_yaws_degrees={0};return prepare_asset(a);}
Region surface(std::uint32_t id,double dx,double x=100,double y=100){Region r;r.id=id;r.bounds={{dx-x/2,-y/2,0},{dx+x/2,y/2,0}};r.open_above=true;r.minimum_clearance_mm=INFINITY;r.sampled_area_mm2=r.usable_area_mm2=x*y;for(double a=-x/2+2.5;a<x/2;a+=5)for(double b=-y/2+2.5;b<y/2;b+=5)r.cells.push_back({{dx+a,b,0},INFINITY,true});return r;}
std::size_t count(const ArrangementResult& r,std::uint64_t id){return std::count_if(r.placements.begin(),r.placements.end(),[&](auto p){return p.asset_id==id;});}
void physics(const ArrangementResult& r,const std::vector<Asset>& assets,const std::vector<Region>& regions){
    std::set<std::uint64_t> ids;
    for(std::size_t i=0;i<r.placements.size();++i){const auto& p=r.placements[i];const auto a=std::find_if(assets.begin(),assets.end(),[&](auto& a){return a.id==p.asset_id;});const auto b=placement_bounds(*a,p);const auto s=std::find_if(regions.begin(),regions.end(),[&](auto& s){return s.id==p.region_id;});
        check(ids.insert(p.stable_id).second,"Stable identities must be unique");check(std::abs(b.center.z-b.half_extents.z)<1e-7,"Actual box contact must be at the receiver top");
        check(b.center.x-b.half_extents.x>=s->bounds.min.x-0.002&&b.center.x+b.half_extents.x<=s->bounds.max.x+0.002&&b.center.y-b.half_extents.y>=s->bounds.min.y-0.002&&b.center.y+b.half_extents.y<=s->bounds.max.y+0.002,"Full source envelope must remain supported");
        for(std::size_t j=0;j<i;++j){const auto& q=r.placements[j];const auto c=std::find_if(assets.begin(),assets.end(),[&](auto& a){return a.id==q.asset_id;});const auto d=placement_bounds(*c,q);check(std::abs(b.center.x-d.center.x)>=b.half_extents.x+d.half_extents.x-0.002||std::abs(b.center.y-d.center.y)>=b.half_extents.y+d.half_extents.y-0.002,"Actual full envelopes cannot overlap");}
    }
}
void large_and_required(){
    std::vector<Asset> assets{source(1,5,5,5),source(2,80,80,30)};std::vector<Region> regions{surface(10,0)};std::vector<FurnitureBody> bodies{{50,box(100,100,10,0,-10)}};QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(bodies,qs);
    ArrangeSettings s;s.amount_mode=AmountMode::Quantity;s.quantity=10;s.spacing_mm=0;s.edge_clearance_mm=0;s.cluster_strength=0;
    std::vector<AssetMinimum> minimums{{2,1}};
    for(std::uint64_t seed=1;seed<=24;++seed){s.seed=seed;ArrangementRequest request{regions,assets};request.minimums=minimums;const auto r=arrange(request,s,query);check(r.stats.requested==10&&r.placements.size()==10&&r.stats.minimum_unfilled==0,"A tight required large item must reserve space before small fill");check(r.placements.front().asset_id==2&&count(r,2)==1,"Required large source must precede small clutter");physics(r,assets,regions);const auto again=arrange(request,s,query);check(again.placements.size()==r.placements.size(),"Repeat count must match");for(std::size_t i=0;i<r.placements.size();++i)check(r.placements[i].stable_id==again.placements[i].stable_id&&r.placements[i].position.x==again.placements[i].position.x&&r.placements[i].position.y==again.placements[i].position.y,"Repeat seed must preserve IDs and geometry");}
    minimums={{2,11}};ArrangementRequest bad{regions,assets};bad.minimums=minimums;rejects([&]{arrange(bad,s,query);},"Minimum sum cannot exceed quantity");
    minimums={{2,1},{2,1}};bad.minimums=minimums;rejects([&]{arrange(bad,s,query);},"Duplicate minimum source IDs must reject");minimums={{99,1}};bad.minimums=minimums;rejects([&]{arrange(bad,s,query);},"Unknown minimum source IDs must reject");
}
void balanced_and_protected(){
    std::vector<Asset> assets{source(1,10,10,10)};std::vector<Region> regions;std::vector<FurnitureBody> bodies;for(std::uint32_t i=0;i<6;++i){regions.push_back(surface(10+i,i*200));bodies.push_back({50+i,box(100,100,10,i*200,-10)});}QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(bodies,qs);
    ArrangeSettings s;s.amount_mode=AmountMode::Quantity;s.quantity=48;s.spacing_mm=2;s.edge_clearance_mm=2;s.cluster_strength=0;s.seed=741;
    const auto r=arrange({regions,assets},s,query);std::map<std::uint32_t,std::size_t> counts;for(auto p:r.placements)++counts[p.region_id];check(r.placements.size()==48&&counts.size()==6,"Quantity must spread across all feasible equal surfaces");for(auto [id,c]:counts)check(c>=5&&c<=11,"Equal support spaces must receive comparable occupancy");physics(r,assets,regions);
    auto previous=r.placements;previous[0].locked=true;std::vector<AssetMinimum> minimums{{1,48}};s.seed=742;ArrangementRequest req{regions,assets,previous};req.minimums=minimums;const auto changed=arrange(req,s,query);check(changed.placements.size()==48&&changed.stats.kept==1&&changed.stats.minimum_unfilled==0,"Protected copies count toward total and minimum once");check(changed.placements.front().stable_id==previous[0].stable_id&&changed.placements.front().position.x==previous[0].position.x&&changed.placements.front().scale==previous[0].scale,"Protected pose must remain exact");physics(changed,assets,regions);
}
void impossible_reserved_and_fit(){
    std::vector<Asset> assets{source(1,10,10,10),source(2,200,200,100)};std::vector<Region> regions{surface(10,0)};std::vector<FurnitureBody> bodies{{50,box(100,100,10,0,-10)}};QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(bodies,qs);
    ArrangeSettings s;s.amount_mode=AmountMode::Quantity;s.quantity=10;s.spacing_mm=0;s.edge_clearance_mm=0;s.cluster_strength=0;std::vector<AssetMinimum> minimums{{2,1}};ArrangementRequest req{regions,assets};req.minimums=minimums;
    auto r=arrange(req,s,query);check(r.placements.size()==9&&count(r,2)==0&&r.stats.minimum_unfilled==1&&r.stats.underfilled==1,"An impossible required prop leaves its copy unfilled instead of substituting small props");physics(r,assets,regions);
    s.quantity=1;s.fit_to_space=true;s.scale_min=.4;r=arrange(req,s,query);check(r.placements.size()==1&&count(r,2)==1&&r.stats.minimum_unfilled==0,"Required fit uses uniform scale after original-size search");check(r.placements[0].asset_id==2&&r.placements[0].scale>=.4&&r.placements[0].scale<=.5001,"A verified fit must honor scale limits");physics(r,assets,regions);
    // Explicit minimums override a zero-density target without optional clutter.
    s.fit_to_space=false;s.amount_mode=AmountMode::Fill;s.density=0;s.empty_space=1;minimums={{1,2}};req.minimums=minimums;r=arrange(req,s,query);check(r.stats.requested==2&&r.placements.size()==2,"Explicit minimum raises a zero-density fill target without inventing optional clutter");
}
void extreme_protected_yaw(){
    struct RejectNew final:PlacementQuery {mutable std::vector<Vec3> probes;QueryResult validate(const PlacementProbe& p)const override{check(std::isfinite(p.collision.center.x)&&std::isfinite(p.collision.center.y),"All late adjacency proposals remain finite for extreme protected rotations");probes.push_back(p.collision.center);return {probes.size()==1?Rejection::None:Rejection::Obstacle,1};}} raw,normalized;
    std::vector<Asset> assets{source(1,10,10,10)};std::vector<Region> regions{surface(10,0)};std::vector<Placement> previous{{991,1,0,10,{0,0,0},1e308,1,true}};
    ArrangeSettings s;s.amount_mode=AmountMode::Quantity;s.quantity=2;s.spacing_mm=0;s.edge_clearance_mm=0;s.cluster_strength=0;s.seed=9103;
    const auto a=arrange({regions,assets,previous},s,raw);previous[0].yaw_degrees=std::remainder(previous[0].yaw_degrees,360.0);const auto b=arrange({regions,assets,previous},s,normalized);
    check(a.stats.kept==1&&b.stats.kept==1&&raw.probes.size()>32&&raw.probes.size()==normalized.probes.size(),"Extreme and normalized protected rotation must traverse the same bounded proposal search");
    for(std::size_t i=0;i<raw.probes.size();++i)check(raw.probes[i].x==normalized.probes[i].x&&raw.probes[i].y==normalized.probes[i].y,"Late neighbour proposals are invariant to finite full-turn rotation magnitude");
}
}
int main(){try{large_and_required();balanced_and_protected();impossible_reserved_and_fit();extreme_protected_yaw();std::cout<<checks<<" packing/priority checks passed\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL after "<<checks<<": "<<e.what()<<'\n';return 1;}}

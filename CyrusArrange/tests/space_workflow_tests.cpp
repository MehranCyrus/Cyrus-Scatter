#include "cyrus_arrange/placement_queries.h"
#include "cyrus_arrange/document_state.h"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace cyrus::arrange;
namespace {
std::size_t checks{};
void check(bool value,const char* message) {++checks;if(!value)throw std::runtime_error(message);}
Mesh box(double x0,double y0,double z0,double x1,double y1,double z1) {
    Mesh m;m.vertices={{x0,y0,z0},{x1,y0,z0},{x1,y1,z0},{x0,y1,z0},{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}};
    m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},
        {{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;
}
Asset prop(double width=30,double depth=100,double height=200) {
    Asset a;a.id=1;a.name="Any selected geometry";a.mesh=box(-width/2,-depth/2,0,width/2,depth/2,height);
    a.anchor={0,0,0};a.allowed_yaws_degrees={0};
    // This metadata used to exclude the source from a TV arrangement.
    a.category=AssetCategory::Kitchenware;a.allowed_furniture=furniture_bit(FurnitureCategory::KitchenCounter);
    return prepare_asset(std::move(a));
}
ArrangeSettings quantity(std::size_t count) {
    ArrangeSettings s;s.amount_mode=AmountMode::Quantity;s.quantity=count;s.cluster_strength=0;
    s.spacing_mm=0;s.edge_clearance_mm=5;s.max_stack_depth=1;return s;
}
bool same(const Placement& a,const Placement& b) {
    return a.stable_id==b.stable_id&&a.asset_id==b.asset_id&&a.region_id==b.region_id&&a.parent_stack_id==b.parent_stack_id&&
        a.position.x==b.position.x&&a.position.y==b.position.y&&a.position.z==b.position.z&&
        a.yaw_degrees==b.yaw_degrees&&a.scale==b.scale&&a.locked==b.locked;
}
void hundred_random_copies() {
    const std::vector<FurnitureBody> bodies{{1,box(0,0,0,6000,1200,20)}};
    Settings sample;sample.cell_size_mm=50;const auto inspected=inspect(bodies[0].mesh,sample);
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(bodies,qs);
    const std::vector<Asset> sources{prop()};auto s=quantity(100);s.random_scale=true;s.scale_min=.8;s.scale_max=1.1;
    std::vector<RegionPlacementRule> policies;
    for(const auto& r:inspected.regions){RegionPlacementRule p;p.region_id=r.id;p.allowed_asset_categories=0;policies.push_back(p);}
    const std::vector<CategoryRule> old_rules{{AssetCategory::Kitchenware,1,0,false}};
    const ArrangementRequest request{inspected.regions,sources,{},{},{},old_rules,true,policies};
    const auto result=arrange(request,s,query);
    check(result.stats.requested==100&&result.stats.accepted==100&&result.stats.underfilled==0,
          "One source repeats 100 times despite historical furniture, category masks and zero category caps");
    for(std::size_t i=0;i<result.placements.size();++i) {
        const auto& p=result.placements[i];
        check(p.scale>=.8&&p.scale<=1.1&&p.position.z==20&&p.yaw_degrees==0,"Random scale remains bounded, upright and supported");
        // Independent analytic dimensions; do not use placement_bounds or the query.
        check(p.position.x-15*p.scale>=5-.003&&p.position.x+15*p.scale<=5995+.003&&
              p.position.y-50*p.scale>=5-.003&&p.position.y+50*p.scale<=1195+.003,"Entire book footprint respects actual board edges");
        for(std::size_t j=0;j<i;++j) {
            const auto& q=result.placements[j];
            check(std::abs(p.position.x-q.position.x)>=15*(p.scale+q.scale)-.003||
                  std::abs(p.position.y-q.position.y)>=50*(p.scale+q.scale)-.003,"All actual scaled book boxes are nonintersecting");
        }
    }
    const auto repeated=arrange(request,s,query);
    check(result.placements.size()==repeated.placements.size(),"Repeated seed retains exact count");
    for(std::size_t i=0;i<result.placements.size();++i)check(same(result.placements[i],repeated.placements[i]),"Repeated seed retains exact poses and scales");
    check(std::any_of(result.placements.begin(),result.placements.end(),[&](const auto& p){return std::abs(p.scale-result.placements[0].scale)>.01;}),"Copies actually have different sizes");
    auto locked=result.placements;for(std::size_t i=0;i<locked.size();++i)locked[i].locked=i<5;
    s.seed=42;
    const auto regenerated=arrange({inspected.regions,sources,locked},s,query);
    check(regenerated.stats.requested==100&&regenerated.stats.accepted==100&&regenerated.stats.kept==5,
          "Quantity includes protected output instead of adding another 100 copies");
    for(std::size_t i=0;i<5;++i) {
        const auto at=std::find_if(regenerated.placements.begin(),regenerated.placements.end(),[&](const auto& p){return p.stable_id==locked[i].stable_id;});
        check(at!=regenerated.placements.end()&&same(*at,locked[i]),"Protected positions and sizes remain exact");
    }
    s.quantity=3;const auto excess=arrange({inspected.regions,sources,locked},s,query);
    check(excess.stats.requested==3&&excess.stats.kept==5&&excess.stats.accepted==5&&!excess.warnings.empty(),"A lower quantity preserves and reports protected excess");
    check(sources[0].bounds.max.z==200&&sources[0].bounds.max.x==15,"Random output scale never modifies original source dimensions");
}
void cabinet_fit_and_limits() {
    const std::vector<FurnitureBody> board{{1,box(0,0,0,600,400,20)}};
    const std::vector<FurnitureBody> roof{{2,box(0,0,300,600,400,320)}};
    Settings sample;sample.cell_size_mm=50;const auto inspected=inspect(board[0].mesh,sample);
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(board,qs,roof);
    const std::vector<Asset> sources{prop(100,100,450)};auto s=quantity(1);
    const auto full=arrange({inspected.regions,sources},s,query);
    check(full.stats.requested==1&&full.placements.empty()&&full.stats.underfilled==1,"450 mm device does not fit unchanged into 280 mm clearance");
    s.fit_to_space=true;s.scale_min=.5;
    const auto fitted=arrange({inspected.regions,sources},s,query);
    check(fitted.placements.size()==1&&fitted.stats.scaled_to_fit==1,"Explicit fit mode finds a reduced valid device");
    const auto& p=fitted.placements.front();
    check(p.scale>=.5&&p.scale<=280.003/450&&p.scale> .62,"Fit refines toward the actual overhead limit");
    check(p.position.z==20&&p.position.x-50*p.scale>=5-.003&&p.position.x+50*p.scale<=595+.003&&
          p.position.y-50*p.scale>=5-.003&&p.position.y+50*p.scale<=395+.003,"Scaled machine remains fully supported inside cabinet floor edges");
    const auto again=arrange({inspected.regions,sources},s,query);
    check(same(p,again.placements.front()),"Fit sampling and refinement repeat exactly");
    s.scale_min=.7;const auto impossible=arrange({inspected.regions,sources},s,query);
    check(impossible.placements.empty()&&impossible.stats.underfilled==1,"Fit never silently goes below permitted scale");
    s.scale_min=.5;s.random_scale=true;s.scale_max=1.1;
    const auto combined=arrange({inspected.regions,sources},s,query);
    check(combined.placements.size()==1&&combined.placements.front().scale>=.5&&combined.placements.front().scale<=280.003/450,
          "Combined random/fit scales pass actual final-size overhead checks");
    check(sources[0].bounds.max.z==450&&sources[0].mesh.vertices[4].z==450,"Fit leaves source geometry unchanged");
    auto stack_sources=sources;auto& top=stack_sources[0];top.stackable=true;top.stack_height_mm=450;top.allowed_on_top=all_asset_mask;
    top.stack_footprint={{-50,-50,450},{50,-50,450},{50,50,450},{-50,50,450}};
    s=quantity(2);s.fit_to_space=true;s.scale_min=.5;s.max_stack_depth=4;s.cluster_strength=1;s.style=ArrangeStyle::Layered;
    const auto stacked=arrange({inspected.regions,stack_sources},s,query);
    check(stacked.placements.size()==2&&stacked.stats.scaled_to_fit==2,"Fitted sources with stable tops retain their actual scaled parent pose during stack attempts");
    for(const auto& item:stacked.placements)check(item.parent_stack_id==0&&item.position.z==20&&item.position.z+450*item.scale<=300.003,
          "Overhead collision prevents an impossible child stack without aborting valid fitted floor placements");
}
void original_size_precedes_global_fit() {
    const std::vector<FurnitureBody> boards{{1,box(0,0,0,600,400,20)},{2,box(1000,0,0,1600,400,20)}};
    Mesh mesh=boards[0].mesh;const auto base=static_cast<std::uint32_t>(mesh.vertices.size());
    mesh.vertices.insert(mesh.vertices.end(),boards[1].mesh.vertices.begin(),boards[1].mesh.vertices.end());
    for(auto tri:boards[1].mesh.triangles){for(auto& v:tri.vertices)v+=base;mesh.triangles.push_back(tri);}
    Settings sample;sample.cell_size_mm=50;auto inspected=inspect(mesh,sample);
    std::sort(inspected.regions.begin(),inspected.regions.end(),[](const auto& a,const auto& b){return a.id<b.id;});
    check(inspected.regions.size()==2&&inspected.regions[0].bounds.max.x<inspected.regions[1].bounds.min.x,
          "Counterexample searches the low covered compartment before the large open one");
    QuerySettings qs;qs.require_front_access=false;const std::vector<FurnitureBody> roof{{3,box(0,0,300,600,400,320)}};
    FurniturePlacementQuery query(boards,qs,roof);const std::vector<Asset> sources{prop(100,100,450)};
    auto s=quantity(1);s.fit_to_space=true;s.scale_min=.5;
    const auto full=arrange({inspected.regions,sources},s,query);
    check(full.placements.size()==1&&full.placements[0].scale==1&&full.placements[0].position.x>1000&&full.stats.scaled_to_fit==0,
          "An original-size fit in a later compartment wins over shrinking into an earlier compartment");
    s.amount_mode=AmountMode::Fill;s.density=.1;s.empty_space=0;
    const auto fill=arrange({inspected.regions,sources},s,query);
    check(fill.stats.requested==6&&fill.stats.accepted==6&&fill.stats.scaled_to_fit==3,
          "Fill fallback recovers three missing slots without double-counting three original-size placements");
}
void preferred_size_in_divided_floor() {
    std::vector<FurnitureBody> furniture;std::vector<FurnitureBody> blockers;Mesh soup;
    auto append=[](Mesh& to,const Mesh& from){const auto offset=static_cast<std::uint32_t>(to.vertices.size());to.vertices.insert(to.vertices.end(),from.vertices.begin(),from.vertices.end());for(auto t:from.triangles){for(auto& i:t.vertices)i+=offset;to.triangles.push_back(t);}};
    auto panel=[&](Bounds b){auto m=box(b.min.x,b.min.y,b.min.z,b.max.x,b.max.y,b.max.z);append(soup,m);furniture.push_back({furniture.size()+1,std::move(m)});};
    panel({{-2630,-300,50},{-480,330,80}});panel({{-2630,-300,80},{-2600,330,800}});panel({{-510,-300,80},{-480,330,800}});
    panel({{-2000,-300,80},{-1970,330,800}});panel({{-1370,-300,80},{-1340,330,800}});panel({{-2630,300,80},{-480,330,800}});
    for(const auto cap:std::array<std::array<double,3>,3>{{{-2600,-2000,480},{-1970,-1370,750},{-1340,-510,480}}}) {
        panel({{cap[0],-300,cap[2]},{cap[1],300,cap[2]+30}});
        blockers.push_back({100+blockers.size(),box(cap[0],-300,cap[2]+30,cap[1],300,2000)});
    }
    Asset a;a.id=10;a.name="Physical device body and four feet";a.allowed_yaws_degrees={0,90,180,270};
    a.mesh=box(-230,-250,30,230,250,560);
    for(double x:{-190.,190.})for(double y:{-200.,200.})append(a.mesh,box(x-25,y-25,0,x+25,y+25,30));
    a.contact_footprint={{-215,-225,0},{215,-225,0},{215,225,0},{-215,225,0}};a=prepare_asset(std::move(a));
    const std::vector<Asset> sources{a};Settings sample;sample.cell_size_mm=25;sample.minimum_clearance_mm=1;
    auto inspected=inspect(soup,sample);for(std::size_t i=0;i<inspected.regions.size();++i)inspected.regions[i].id=11+static_cast<std::uint32_t>(i);
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(furniture,qs,blockers);
    Placement valid;valid.asset_id=a.id;valid.position={-1670,0,80};valid.scale=1;
    const auto footprint=placement_footprint(a,valid);PlacementProbe probe;probe.footprint_world=footprint;probe.collision=placement_bounds(a,valid);probe.support_z=80;probe.edge_clearance_mm=5;probe.spacing_mm=15;probe.remaining_work=50000000;
    check(query.validate(probe).reason==Rejection::None,"Actual divided-cabinet geometry admits a complete original-size device in the tall opening");
    auto s=quantity(1);s.fit_to_space=true;s.scale_min=.5;s.scale_max=1.1;s.spacing_mm=15;
    for(std::uint64_t seed=7712033;seed<7712049;++seed) {
        s.seed=seed;const auto r=arrange({inspected.regions,sources},s,query);
        check(r.placements.size()==1&&r.placements[0].scale==1&&r.stats.scaled_to_fit==0,"A small tall cubby on one continuous divided floor must be searched before shrinking");
        const auto b=placement_bounds(a,r.placements[0]);check(b.center.x-b.half_extents.x>=-1970-.003&&b.center.x+b.half_extents.x<=-1370+.003&&b.center.z+b.half_extents.z<=750+.003,"The actual preferred-size full body stays inside the tall cubby");
        const auto repeated=arrange({inspected.regions,sources},s,query);check(repeated.placements.size()==1&&same(r.placements[0],repeated.placements[0]),"Preferred-cell proposals retain exact repeat-seed identity and pose");
    }
    check(sources[0].bounds.max.z==560&&sources[0].contact_footprint.size()==4,"Preferred search leaves source geometry and contact metadata unchanged");
}
void quantity_packing_recovery() {
    const std::vector<FurnitureBody> bodies{{1,box(0,0,0,1185,780,20)}};
    Asset a;a.id=1;a.name="Complete body and four feet";a.mesh=box(-230,-250,30,230,250,560);
    const auto append=[](Mesh& to,const Mesh& from){const auto offset=static_cast<std::uint32_t>(to.vertices.size());to.vertices.insert(to.vertices.end(),from.vertices.begin(),from.vertices.end());for(auto t:from.triangles){for(auto& i:t.vertices)i+=offset;to.triangles.push_back(t);}};
    for(double x:{-190.,190.})for(double y:{-200.,200.})append(a.mesh,box(x-25,y-25,0,x+25,y+25,30));
    a.contact_footprint={{-215,-225,0},{215,-225,0},{215,225,0},{-215,225,0}};a=prepare_asset(std::move(a));const std::vector<Asset> sources{a};
    Settings sample;sample.cell_size_mm=50;sample.minimum_clearance_mm=1;const auto inspected=inspect(bodies[0].mesh,sample);
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(bodies,qs);
    const auto validate=[&](const Placement& p,std::span<const PlacedObstacle> prior){const auto foot=placement_footprint(a,p);PlacementProbe probe;probe.footprint_world=foot;probe.collision=placement_bounds(a,p);probe.support_z=p.position.z;probe.accepted=prior;probe.spacing_mm=15;probe.edge_clearance_mm=5;probe.remaining_work=50000000;return query.validate(probe).reason;};
    Placement left;left.stable_id=9001;left.asset_id=1;left.region_id=inspected.regions[0].id;left.position={342.5,390,20};left.scale=1;auto right=left;right.stable_id=9002;right.position.x=842.5;
    check(validate(left,{})==Rejection::None,"Literal left full-size device fits complete support");
    const std::vector<PlacedObstacle> occupied{{left.stable_id,placement_bounds(a,left)}};check(validate(right,occupied)==Rejection::None,"Literal right device fits beside first with authored separation");
    auto s=quantity(2);s.spacing_mm=15;s.empty_space=0;
    for(std::uint64_t seed=7712033;seed<7712049;++seed){
        s.seed=seed;const auto result=arrange({inspected.regions,sources},s,query);
        check(result.placements.size()==2&&result.stats.underfilled==0,"Quantity must recover two physically valid full-size devices from a blocking first proposal");
        std::vector<PlacedObstacle> prior;
        for(const auto& p:result.placements){check(p.scale==1&&validate(p,prior)==Rejection::None,"Recovered full-size devices retain exact physical validation");prior.push_back({p.stable_id,placement_bounds(a,p)});}
        const auto repeated=arrange({inspected.regions,sources},s,query);check(repeated.placements.size()==2&&same(result.placements[0],repeated.placements[0])&&same(result.placements[1],repeated.placements[1]),"Automatic recovery repeats saved-seed identities and poses exactly");
        check(result.stats.work<=s.max_work&&result.stats.candidates<=s.max_candidates,"Recovery charges all attempts to the command limits");
    }
    std::vector<Placement> protected_pose{left};protected_pose[0].locked=true;s.seed=7712034;
    const auto protected_result=arrange({inspected.regions,sources,protected_pose},s,query);
    check(protected_result.placements.size()==2&&same(protected_result.placements[0],protected_pose[0]),"Recovery retains protected complete-device poses exactly");
    auto central=left;central.position={592.5,390,20};central.locked=true;const std::vector<Placement> blocked_pose{central};
    const auto blocked=arrange({inspected.regions,sources,blocked_pose},s,query);
    check(blocked.placements.size()==1&&blocked.stats.underfilled==1&&same(blocked.placements[0],central),"An impossible protected central placement remains protected with honest underfill");
    const std::vector<FurnitureBody> blockers{{2,box(0,0,20,600,780,1000)}};FurniturePlacementQuery occupied_query(bodies,qs,blockers);
    const auto obstructed=arrange({inspected.regions,sources},s,occupied_query);
    check(obstructed.placements.size()==1&&obstructed.stats.underfilled==1&&obstructed.stats.work<=s.max_work,"Recovery does not publish two devices through an explicit large obstacle");
    const std::vector<AssetMinimum> minimums{{1,2}};ArrangementRequest required{inspected.regions,sources};required.minimums=minimums;
    const auto fulfilled=arrange(required,s,query);check(fulfilled.placements.size()==2&&fulfilled.stats.minimum_unfilled==0,"Recovery fulfills the required source copies without changing the global quantity");
    const auto missing=arrange(required,s,occupied_query);check(missing.placements.size()==1&&missing.stats.minimum_unfilled==1&&missing.stats.underfilled==1,"Impossible required capacity reports both actual total and minimum shortfall");
    s.random_scale=true;s.scale_min=.8;s.scale_max=1.1;
    for(std::uint64_t seed=7712033;seed<7712049;++seed){s.seed=seed;const auto r=arrange({inspected.regions,sources},s,query);check(r.placements.size()==2,"Random-scale quantity recovers both devices");for(const auto& p:r.placements)check(p.scale>=.8&&p.scale<=1.1,"Recovery preserves the authored random-scale range");}
    s.random_scale=false;s.max_work=1;bool limited=false;try{arrange({inspected.regions,sources},s,query);}catch(const std::exception&){limited=true;}check(limited,"Recovery preserves atomic command work-limit failure");
    check(sources[0].mesh.vertices.size()==40&&sources[0].mesh.triangles.size()==60&&sources[0].bounds.max.z==560,"Recovery leaves complete source geometry and dimensions unchanged");
}
void empty_and_global_quantity() {
    const std::vector<FurnitureBody> bodies{{1,box(0,0,0,100,100,20)},{2,box(300,0,0,6000,1200,20)}};
    Mesh merged=bodies[0].mesh;auto tail=bodies[1].mesh;
    for(auto& t:tail.triangles)for(auto& id:t.vertices)id+=static_cast<std::uint32_t>(merged.vertices.size());
    merged.vertices.insert(merged.vertices.end(),tail.vertices.begin(),tail.vertices.end());merged.triangles.insert(merged.triangles.end(),tail.triangles.begin(),tail.triangles.end());
    Settings sample;sample.cell_size_mm=50;const auto inspected=inspect(merged,sample);
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery query(bodies,qs);
    const std::vector<Asset> sources{prop()};auto s=quantity(100);
    const auto result=arrange({inspected.regions,sources},s,query);
    check(inspected.regions.size()>=2&&result.stats.requested==100&&result.stats.accepted==100,"Global quantity is not multiplied by region count and later space recovers earlier underfill");
    s.quantity=0;const auto zero=arrange({inspected.regions,sources},s,query);
    check(zero.stats.requested==0&&zero.placements.empty(),"Zero quantity is a valid explicit empty result");
    s.quantity=100;const auto missing=arrange({inspected.regions,{}},s,query);
    check(missing.stats.requested==100&&missing.stats.underfilled==100&&missing.placements.empty(),"No-source underfill retains the actual requested count");
}
void persistence() {
    host::DocumentState state;state.document_id="{01234567-89ab-cdef-0123-456789abcdef}";
    auto& s=state.arrangement;s.amount_mode=AmountMode::Quantity;s.quantity=77;s.random_scale=true;s.fit_to_space=true;s.scale_min=.4;s.scale_max=1.2;
    const auto bytes=host::encode_document_state(state,7);std::uint64_t high=0;const auto restored=host::decode_document_state(bytes,high);
    const auto& r=restored->arrangement;
    check(r.amount_mode==AmountMode::Quantity&&r.quantity==77&&r.random_scale&&r.fit_to_space&&r.scale_min==.4&&r.scale_max==1.2&&high==7,
          "Schema 7 roundtrip retains all new native quantity and scale settings");
    auto earlier=bytes;earlier.resize(earlier.size()-39);earlier[4]=4;
    const auto old=host::decode_document_state(earlier,high);
    check(old->arrangement.amount_mode==AmountMode::Fill&&!old->arrangement.fit_to_space&&!old->arrangement.random_scale,
          "Released schema 4 receives neutral quantity/scale defaults without input rewriting");
    auto bad=bytes;bad[bad.size()-18]=2;const auto before=high;bool rejected=false;
    try{host::decode_document_state(bad,high);}catch(const std::exception&){rejected=true;}
    check(rejected&&high==before,"Corrupt new Boolean rejects without publishing high-water changes");
}
}
int main() {
    try{hundred_random_copies();cabinet_fit_and_limits();original_size_precedes_global_fit();preferred_size_in_divided_floor();quantity_packing_recovery();empty_and_global_quantity();persistence();
        std::cout<<"Space workflow passed "<<checks<<" checks\n";return 0;
    }catch(const std::exception& e){std::cerr<<"Space workflow failure after "<<checks<<" checks: "<<e.what()<<'\n';return 1;}
}

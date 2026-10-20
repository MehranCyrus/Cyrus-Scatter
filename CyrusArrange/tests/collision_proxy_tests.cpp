#include "cyrus_arrange/placement_queries.h"
#include "cyrus_arrange/path.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace cyrus::arrange;
namespace {
std::size_t checks{};
void check(bool a,const char* label){++checks;if(!a)throw std::runtime_error(label);}
template<class F>void rejects(F f,const char* label){bool threw=false;try{f();}catch(const std::exception&){threw=true;}check(threw,label);}
Mesh box(double x0,double y0,double z0,double x1,double y1,double z1){Mesh m;m.vertices={{x0,y0,z0},{x1,y0,z0},{x1,y1,z0},{x0,y1,z0},{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}};m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;}
Mesh arch(){
    // One genuinely connected, closed concave extrusion, without overlapping
    // box shells or internal faces. Its interior gap is 70 x 40 x 80 mm.
    Mesh m;const std::array<Vec3,10> profile{{{-50,0,0},{-35,0,0},{-35,0,80},{35,0,80},{35,0,0},{50,0,0},{50,0,100},{-50,0,100},{-35,0,100},{35,0,100}}};
    for(double y:{-20.0,20.0})for(auto p:profile)m.vertices.push_back({p.x,y,p.z});
    const std::array<std::array<std::uint32_t,3>,8> cap{{{0,1,2},{0,2,8},{0,8,7},{4,5,6},{4,6,3},{3,6,9},{2,3,9},{2,9,8}}};
    for(auto t:cap){m.triangles.push_back({t});m.triangles.push_back({{t[2]+10,t[1]+10,t[0]+10}});}
    const std::array<std::uint32_t,10> outline{0,1,2,3,4,5,6,9,8,7};
    for(std::size_t i=0;i<outline.size();++i){const auto a=outline[i],b=outline[(i+1)%outline.size()];m.triangles.push_back({{a,a+10,b+10}});m.triangles.push_back({{a,b+10,b}});}return m;
}
Asset source(std::uint64_t id,Mesh m){Asset a;a.id=id;a.name="Actual concave source";a.mesh=std::move(m);a.allowed_yaws_degrees={0};return prepare_asset(std::move(a));}
bool contains(std::span<const Bounds> boxes,Vec3 p){return std::any_of(boxes.begin(),boxes.end(),[&](auto b){return p.x>=b.min.x-1e-8&&p.x<=b.max.x+1e-8&&p.y>=b.min.y-1e-8&&p.y<=b.max.y+1e-8&&p.z>=b.min.z-1e-8&&p.z<=b.max.z+1e-8;});}
void conservative_volume(){
    const auto a=source(1,arch());CollisionSource collider(a);const auto lease=collider.proxy(50000000);
    check(lease.pieces.size()>1&&lease.pieces.size()<=128&&lease.build_work>0&&lease.build_work<=20000000,"Closed concave source builds bounded connected band pieces");
    check(!contains(lease.pieces,{0,0,30}),"Refinement must leave the actual arch gap empty");
    for(int x=-50;x<=50;x+=2)for(int y=-20;y<=20;y+=4)for(int z=0;z<=100;z+=2)if(x<=-35||x>=35||z>=80)check(contains(lease.pieces,{double(x),double(y),double(z)}),"Every independently classified solid arch sample remains occupied");
    for(const auto& t:a.mesh.triangles)for(unsigned i=0;i<=6;++i)for(unsigned j=0;j<=6-i;++j){const auto p=a.mesh.vertices[t.vertices[0]],q=a.mesh.vertices[t.vertices[1]],r=a.mesh.vertices[t.vertices[2]];const double u=i/6.0,v=j/6.0;check(contains(lease.pieces,{p.x*(1-u-v)+q.x*u+r.x*v,p.y*(1-u-v)+q.y*u+r.y*v,p.z*(1-u-v)+q.z*u+r.z*v}),"All triangle barycentric samples are enclosed including band boundaries");}
    check(collider.proxy(1).build_work==0,"A warmed immutable source proxy does not rebuild");
    auto cube=source(2,box(-50,-20,0,50,20,100));CollisionSource solid(cube);const auto filled=solid.proxy(50000000);check(filled.pieces.size()==1&&contains(filled.pieces,{0,0,50}),"A solid cube retains its full interior and merges equal vertical slabs");
    auto open=a;open.mesh.triangles.pop_back();CollisionSource unproved(open);const auto coarse=unproved.proxy(50000000);check(contains(coarse.pieces,{0,0,30}),"An open source cannot claim a certified interior gap");
    auto nonmanifold=a;nonmanifold.mesh.triangles.push_back(a.mesh.triangles[0]);CollisionSource doubled(nonmanifold);check(contains(doubled.proxy(50000000).pieces,{0,0,30}),"Nonmanifold topology uses conservative complete bands");
    auto caps=source(4,box(-50,-20,0,50,20,100));caps.mesh.triangles.resize(4);CollisionSource incomplete(caps);check(contains(incomplete.proxy(50000000).pieces,{0,0,50}),"Uncertified disconnected caps cannot leave an unproved solid interior empty");
    CollisionSource low(a);const auto limited=low.proxy(1);check(limited.pieces.size()==1&&limited.build_work==0&&contains(limited.pieces,{0,0,30}),"A tiny refinement allowance retains all source bounds");check(!contains(low.proxy(50000000).pieces,{0,0,30}),"A zero-work coarse lease does not poison later admitted refinement");
}
void physical_queries(){
    const auto a=source(1,arch());CollisionSource collider(a);Placement p{11,1,0,1,{0,0,0},0,1};const auto root=placement_bounds(a,p);const auto footprint=placement_footprint(a,p);CollisionPose pose{&collider,p.position,0,1};
    const std::vector<FurnitureBody> floor{{1,box(-100,-100,-10,100,100,0)}};std::vector<FurnitureBody> obstacle{{2,box(-10,-10,0,10,10,60)}};QuerySettings settings;settings.require_front_access=false;FurniturePlacementQuery query(floor,settings,obstacle);
    PlacementProbe probe{footprint,root,0,1,{},0,{},0,0,50000000};
    check(query.validate(probe).reason==Rejection::Obstacle,"The original full source box rejects a device inside the arch gap");probe.collider=pose;
    check(query.validate(probe).reason==Rejection::None,"Actual connected arch clears the device after conservative source refinement");
    const auto empty_gap=query.validate(probe);check(empty_gap.witness.issue==FitIssue::None&&!empty_gap.witness.body_id,"Discarded broad-phase arch overlap cannot leak a false obstruction witness");
    obstacle[0].mesh=box(-46,-10,5,-40,10,30);FurniturePlacementQuery leg(floor,settings,obstacle);check(leg.validate(probe).reason==Rejection::Obstacle,"A real source leg collision still rejects");
    obstacle[0].mesh=box(-5,-10,90,5,10,110);FurniturePlacementQuery beam(floor,settings,obstacle);check(beam.validate(probe).reason==Rejection::Obstacle,"Actual beam/overhead interference still rejects");
    std::vector<PlacedObstacle> accepted{{22,{{0,0,30},{10,10,30},0},0}};probe.accepted=accepted;FurniturePlacementQuery pairs(floor,settings);
    check(pairs.validate(probe).reason==Rejection::None,"A prop in the real gap passes refined output collision");probe.spacing_mm=30;check(pairs.validate(probe).reason==Rejection::Spacing,"Spacing remains enforced against each occupied piece");probe.spacing_mm=10;check(pairs.validate(probe).reason==Rejection::None,"Gap uses occupied source pieces rather than the whole envelope");
    accepted[0].box.center.z=36.5;accepted[0].box.half_extents.z=36.5;probe.spacing_mm=0;check(pairs.validate(probe).reason==Rejection::None,"A tall device remains physically clear beneath the beam");probe.spacing_mm=10;check(pairs.validate(probe).reason==Rejection::Spacing,"Different collider bands cannot bypass the requested gap with a small vertical separation");
    probe.collider.position.x=5;rejects([&]{pairs.validate(probe);},"A collider descriptor cannot disagree with its complete bounds");probe.collider=pose;probe.remaining_work=1;rejects([&]{pairs.validate(probe);},"Source refinement cannot bypass the native query work allowance");
    const auto before=a.mesh.vertices[0];check(before.x==-50&&a.mesh.vertices.size()==20&&a.mesh.triangles.size()==36,"Refinement leaves complete visual/source geometry unchanged");
    // The root center is in the static device; the accepted result above must
    // refine solid containment as well as triangle/box surface intersections.
}
void transforms_and_budgets(){
    auto a=source(1,arch());a.anchor={10,-5,0};validate_asset(a);CollisionSource source_geometry(a);
    const auto point=[](Vec3 p,const CollisionPose& s){const double r=std::remainder(s.yaw_degrees,360.0)*3.14159265358979323846/180,x=(p.x-10)*s.scale,y=(p.y+5)*s.scale;return Vec3{s.position.x+std::cos(r)*x-std::sin(r)*y,s.position.y+std::sin(r)*x+std::cos(r)*y,s.position.z+p.z*s.scale};};
    for(double yaw:{0.0,37.5,-90.0,1e308})for(double scale:{.25,.65,1.0,2.0}){CollisionPose p{&source_geometry,{100,-40,7},yaw,scale};const auto root=collision_piece(p,a.bounds);const auto gap=point({0,0,30},p),leg=point({-42,0,30},p);
        const OrientedBox empty{gap,{3*scale,3*scale,3*scale},yaw},occupied{leg,{2*scale,2*scale,2*scale},yaw};check(!collision_overlap(root,p,empty,{},0,.000001,50000000).overlaps,"Scaled/rotated source retains its true gap with off-center contact anchor");check(collision_overlap(root,p,occupied,{},0,.000001,50000000).overlaps,"Scaled/rotated occupied source volume remains colliding");}
    const CollisionPose p{&source_geometry,{0,0,0},0,1};const auto root=collision_piece(p,a.bounds);rejects([&]{collision_overlap(root,p,root,p,0,.01,1);},"Pair refinement bounds its work before any compound search");
    rejects([&]{validate_collision_pose({{0,0,0},{0,1,1},0},{});},"Even unrefined boxes require valid positive dimensions");
    auto thin_mesh=arch();for(auto& v:thin_mesh.vertices)v.z*=.001;const auto thin=source(3,std::move(thin_mesh));CollisionSource thin_source(thin);const Placement placement{3,3,0,1,{0,0,0},0,1};const auto footprint=placement_footprint(thin,placement);
    Mesh plane;plane.vertices={{-46,-10,.05},{-40,-10,.05},{-40,10,.05},{-46,10,.05}};plane.triangles={{{0,1,2}},{{0,2,3}}};const std::vector<FurnitureBody> support{{1,box(-100,-100,-10,100,100,0)}},obstacle{{2,plane}};QuerySettings q;q.require_front_access=false;FurniturePlacementQuery physical(support,q,obstacle);
    PlacementProbe probe{footprint,placement_bounds(thin,placement),0,1,{},0,{},0,0,50000000};probe.collider={&thin_source,placement.position,0,1};
    check(physical.validate(probe).reason==Rejection::Obstacle,"Artificial thin band cuts cannot create tolerance holes through an occupied leg");
}
Region region(std::uint32_t id){Region r;r.id=id;r.bounds={{-50,-20,0},{50,20,0}};r.open_above=true;r.minimum_clearance_mm=INFINITY;r.usable_area_mm2=r.sampled_area_mm2=4000;for(double x=-47.5;x<50;x+=5)for(double y=-17.5;y<20;y+=5)r.cells.push_back({{x,y,0},INFINITY,true});return r;}
void solver_lifetime_and_paths(){
    auto a=source(1,arch()),b=source(2,box(-10,-10,0,10,10,50));a.weight=1e-9;b.weight=100;const std::vector<Asset> assets{a,b};const std::vector<Region> regions{region(10)};const std::vector<FurnitureBody> floors{{1,box(-50,-20,-10,50,20,0)}};QuerySettings q;q.require_front_access=false;FurniturePlacementQuery geometry(floors,q);
    std::vector<Placement> previous{{991,1,0,10,{0,0,0},0,1,true}};ArrangeSettings settings;settings.amount_mode=AmountMode::Quantity;settings.quantity=2;settings.spacing_mm=0;settings.edge_clearance_mm=0;settings.cluster_strength=0;
    for(std::uint64_t seed=1;seed<=12;++seed){settings.seed=seed;const auto result=arrange({regions,assets,previous},settings,geometry);check(result.stats.accepted==2&&result.stats.kept==1,"A protected arch allows an unlocked device in its real empty gap");const auto& p=result.placements[1];check(p.asset_id==2&&std::abs(p.position.x)+10<=35.001&&p.position.z==0&&p.scale==1,"Solver accepts actual original-size device inside the protected arch");const auto again=arrange({regions,assets,previous},settings,geometry);check(again.placements[1].stable_id==p.stable_id&&again.placements[1].position.x==p.position.x,"Refinement and lazy build remain seeded and repeatable");}
    settings.amount_mode=AmountMode::Fill;settings.density=1;settings.empty_space=0;std::vector<Region> duplicate{region(10),region(11)};const std::vector<Asset> only_arch{a};const auto fill=arrange({duplicate,only_arch},settings,geometry);check(fill.placements.size()==1,"Regional Fill's outside descriptor remains valid after a child solve and rejects true repeated legs");
    CubicBezier segment;segment.control={Vec3{0,0,0},Vec3{3333.333333,0,0},Vec3{6666.666667,0,0},Vec3{10000,0,0}};const std::array<CubicBezier,1> line{segment};const auto curve=PathCurve::build(line);const std::array<PathLane,2> lanes{{{1,1,0,200,10000,false,true},{2,1,0,200,10000,true,true}}};std::vector<AssetMinimum> minimums{{1,1},{2,1}};PathRequest request{curve,lanes,assets};request.minimums=minimums;settings.amount_mode=AmountMode::Quantity;settings.quantity=2;
    const auto nested=arrange_path(request,settings,{});check(nested.result.stats.accepted==2&&nested.result.stats.minimum_unfilled==0,"Path-only output collision also refines actual empty source volume");
}
}
int main(){try{conservative_volume();physical_queries();transforms_and_budgets();solver_lifetime_and_paths();std::cout<<checks<<" compound collider checks passed\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL after "<<checks<<": "<<e.what()<<'\n';return 1;}}

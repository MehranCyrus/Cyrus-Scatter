#include "cyrus_arrange/placement_queries.h"
#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace cyrus::arrange;
namespace {
void check(bool v,const char* why){if(!v)throw std::runtime_error(why);}
void rejects(const std::function<void()>& f){bool rejected=false;try{f();}catch(const std::exception&){rejected=true;}check(rejected,"Expected bounded rejection");}
void quad(Mesh& m,Vec3 a,Vec3 b,Vec3 c,Vec3 d){auto i=static_cast<std::uint32_t>(m.vertices.size());m.vertices.insert(m.vertices.end(),{a,b,c,d});m.triangles.push_back({{i,i+1,i+2}});m.triangles.push_back({{i,i+2,i+3}});}
void plane(Mesh& m,double x0,double y0,double x1,double y1,double z,bool up=true){if(up)quad(m,{x0,y0,z},{x1,y0,z},{x1,y1,z},{x0,y1,z});else quad(m,{x0,y0,z},{x0,y1,z},{x1,y1,z},{x1,y0,z});}
Mesh box(double x0,double y0,double z0,double x1,double y1,double z1){Mesh m;plane(m,x0,y0,x1,y1,z0,false);plane(m,x0,y0,x1,y1,z1);quad(m,{x0,y0,z0},{x1,y0,z0},{x1,y0,z1},{x0,y0,z1});quad(m,{x1,y0,z0},{x1,y1,z0},{x1,y1,z1},{x1,y0,z1});quad(m,{x1,y1,z0},{x0,y1,z0},{x0,y1,z1},{x1,y1,z1});quad(m,{x0,y1,z0},{x0,y0,z0},{x0,y0,z1},{x0,y1,z1});return m;}
void append(Mesh& a,const Mesh& b){auto base=static_cast<std::uint32_t>(a.vertices.size());a.vertices.insert(a.vertices.end(),b.vertices.begin(),b.vertices.end());for(auto f:b.triangles){for(auto& v:f.vertices)v+=base;a.triangles.push_back(f);}}
struct Probe {
    std::vector<Vec3> footprint;
    PlacementProbe value{};
    Probe(double x,double y,double z,double width=20,double depth=20,double height=30,double yaw=0){
        const double r=yaw*3.14159265358979323846/180,c=std::cos(r),s=std::sin(r);
        for(auto p:std::array<Vec3,4>{{{-width/2,-depth/2,z},{width/2,-depth/2,z},{width/2,depth/2,z},{-width/2,depth/2,z}}})footprint.push_back({x+c*p.x-s*p.y,y+s*p.x+c*p.y,z});
        value.footprint_world=footprint;value.collision={{x,y,z+height/2},{width/2,depth/2,height/2},yaw};value.support_z=z;value.region_id=1;value.remaining_work=50000000;
    }
};
FurniturePlacementQuery query(std::vector<FurnitureBody> bodies,bool access=false){QuerySettings s;s.require_front_access=access;return FurniturePlacementQuery(bodies,s);}
void submicron_real_edges(){
    const double tiny=1.0/4096;
    for(const Vec3 origin:std::array<Vec3,3>{{{0,0,0},{2407.015869140625,-390.0594787597656,213.40443420410156},{-2407.015869140625,390.0594787597656,-213.40443420410156}}}){
        Mesh mesh;const auto at=[&](Vec3 p){return Vec3{p.x+origin.x,p.y+origin.y,p.z+origin.z};};
        const auto triangle=[&](Vec3 a,Vec3 b,Vec3 c){auto n=static_cast<std::uint32_t>(mesh.vertices.size());mesh.vertices.insert(mesh.vertices.end(),{at(a),at(b),at(c)});mesh.triangles.push_back({{n,n+1,n+2}});};
        const std::array<Vec3,5> ring{{{0,0,0},{tiny,0,0},{100,0,0},{100,100,0},{0,100,0}}};
        for(std::size_t i=0;i<ring.size();++i){const auto a=ring[i],b=ring[(i+1)%ring.size()];const Vec3 a_top{a.x,a.y,10},b_top{b.x,b.y,10};
            triangle({50,50,0},b,a);triangle({50,50,10},a_top,b_top);
            triangle(a,b,b_top);triangle(a,b_top,a_top);
        }
        const std::vector<FurnitureBody> bodies{{1,mesh}};auto q=query(bodies);
        check(q.diagnostics().triangles==20&&q.diagnostics().closed_components==1&&q.diagnostics().open_components==0,"Nonzero sub-micron faces retain the complete closed topology");
        Probe supported(50+origin.x,50+origin.y,10+origin.z);check(q.validate(supported.value).reason==Rejection::None,"Valid support survives exact-coordinate topology fallback");
        QuerySettings s;s.require_support=false;s.require_front_access=false;FurniturePlacementQuery solid(bodies,s);Probe inside(50+origin.x,50+origin.y,2+origin.z,10,10,4);
        check(solid.validate(inside.value).reason==Rejection::Obstacle,"Whole-object containment survives tiny real edges");
        const std::vector<FurnitureBody> supports{{2,box(origin.x-100,origin.y-100,origin.z-10,origin.x+200,origin.y+200,origin.z)}};
        FurniturePlacementQuery obstacle(supports,s,bodies);check(obstacle.validate(inside.value).reason==Rejection::Obstacle,"Exact topology also preserves independent obstacle containment");
        s.max_build_work=q.diagnostics().build_work-1;rejects([&]{FurniturePlacementQuery limited(bodies,s);});
        check(bodies[0].mesh.vertices.size()==60&&bodies[0].mesh.triangles.size()==20&&bodies[0].mesh.vertices[5].x-bodies[0].mesh.vertices[4].x==tiny,"Fallback leaves original hard-edge vertices and faces unchanged");
    }
}
void mixed_zero_area_faces(){
    auto clean=box(0,0,0,100,100,10),mixed=clean;mixed.triangles.push_back({{0,0,0}});
    const auto n=static_cast<std::uint32_t>(mixed.vertices.size());mixed.vertices.push_back({0,0,5});mixed.vertices.push_back({0,0,7});mixed.triangles.push_back({{0,n,n+1}});
    const std::vector<FurnitureBody> bodies{{1,mixed}};auto q=query(bodies);
    check(q.diagnostics().triangles==clean.triangles.size()&&q.diagnostics().closed_components==1,"Zero-area faces must retain valid support and closed occupancy");
    Probe supported(50,50,10);check(q.validate(supported.value).reason==Rejection::None,"Valid support remains usable beside repeated-index and collinear faces");
    QuerySettings s;s.require_support=false;s.require_front_access=false;FurniturePlacementQuery solid(bodies,s);Probe contained(50,50,1,10,10,4);
    check(solid.validate(contained.value).reason==Rejection::Obstacle,"Zero-area filtering must retain closed-solid containment");
    check(bodies[0].mesh.triangles.size()==14&&bodies[0].mesh.vertices.size()==26&&bodies[0].mesh.triangles[12].vertices==std::array<std::uint32_t,3>{0,0,0},"Derived filtering leaves all original geometry unchanged");
    auto obstacle=box(45,45,10,55,55,60);obstacle.triangles.push_back({{0,0,0}});
    const std::vector<FurnitureBody> supports{{1,clean}},obstacles{{2,obstacle}};FurniturePlacementQuery blocked(supports,s,obstacles);
    check(blocked.validate(supported.value).reason==Rejection::Obstacle,"A mixed-degenerate obstacle retains real collisions");
    auto bad=bodies;bad[0].mesh.triangles.back().vertices[1]=static_cast<std::uint32_t>(bad[0].mesh.vertices.size());rejects([&]{query(bad);});
    bad=bodies;bad[0].mesh.vertices.back().x=std::numeric_limits<double>::quiet_NaN();rejects([&]{query(bad);});
    auto empty=mixed;empty.triangles={{{0,0,0}},{{0,n,n+1}}};rejects([&]{query({{1,empty}});});
    const std::vector<FurnitureBody> empty_obstacles{{2,empty}};rejects([&]{FurniturePlacementQuery unusable(supports,s,empty_obstacles);});
}
void surface_and_edge(){auto q=query({{1,box(0,0,0,100,100,10)}});Probe p(50,50,10);check(q.validate(p.value).reason==Rejection::None,"Analytic center fit");p.value.edge_clearance_mm=41;check(q.validate(p.value).reason==Rejection::Boundary,"Whole patch enforces inset");Probe over(95,50,10);check(q.validate(over.value).reason==Rejection::Boundary,"Center lies on surface but footprint overhang rejects");check(q.diagnostics().closed_components==1,"Welded hard-edge box is closed");}
void subcell_hole(){Mesh m;plane(m,0,0,49,100,0);plane(m,51,0,100,100,0);plane(m,49,0,51,49,0);plane(m,49,51,51,100,0);auto q=query({{1,m}});Probe p(50,50,0,20,20);check(q.validate(p.value).reason==Rejection::Boundary,"2 mm hole inside broad footprint rejects");Probe clear(25,25,0);check(q.validate(clear.value).reason==Rejection::None,"Same holed surface still admits clear patch");}
void concave_surface(){Mesh m;plane(m,0,0,100,25,0);plane(m,0,25,25,100,0);auto q=query({{1,m}});Probe p(25,25,0,20,20);check(q.validate(p.value).reason==Rejection::Boundary,"L-shaped notch rejects even though anchor touches support");Probe ok(50,12.5,0,20,20);check(q.validate(ok.value).reason==Rejection::None,"Arm fit accepted");}
void small_obstacle(){auto q=query({{1,box(0,0,0,100,100,10)},{2,box(49,49,10,51,51,11)}});Probe p(50,50,10);check(q.validate(p.value).reason==Rejection::Obstacle,"2 mm obstruction between inspector rays rejects");}
void overhead_and_touch(){auto q=query({{1,box(0,0,0,100,100,10)},{2,box(0,0,40,100,100,50)}});Probe touches(50,50,10,20,20,30);check(q.validate(touches.value).reason==Rejection::None,"Exact top contact is allowed without penetration");Probe crosses(50,50,10,20,20,31);check(q.validate(crosses.value).reason==Rejection::Obstacle,"One mm overhead penetration rejects");}
void nested_solid(){auto q=query({{1,box(0,0,0,100,100,100)},{2,box(30,30,10,70,70,20)}});Probe p(50,50,20,10,10,10);check(q.validate(p.value).reason==Rejection::Obstacle,"Buried support entirely inside another closed body rejects without intersecting its triangles");}
void disconnected_solids(){Mesh m=box(0,0,0,100,100,100);append(m,box(30,30,10,70,70,20));auto q=query({{1,m}});check(q.diagnostics().closed_components==2,"Disconnected solids classified separately within one source node");Probe p(50,50,20,10,10,10);check(q.validate(p.value).reason==Rejection::Obstacle,"Disconnected overlapping solids do not cancel occupancy by parity");}
void front_access(){std::vector<FurnitureBody> bodies{{1,box(0,0,0,100,100,10)},{2,box(0,0,10,100,5,100)}};Probe p(50,50,10);check(query(bodies).validate(p.value).reason==Rejection::None,"Interior shelf patch has direct geometric fit");check(query(bodies,true).validate(p.value).reason==Rejection::Obstacle,"Front wall blocks insertion sweep");bodies[1].mesh=box(0,95,10,100,100,100);check(query(bodies,true).validate(p.value).reason==Rejection::None,"Back wall does not obstruct front access");}
void rotated_access(){std::vector<FurnitureBody> bodies{{1,box(0,0,0,100,100,10)},{2,box(0,0,10,10,100,100)}};Probe p(50,50,10,20,10,30,45);QuerySettings s;s.front_direction={1,0,0};FurniturePlacementQuery q(bodies,s);check(q.validate(p.value).reason==Rejection::None,"Rotated asset can travel along explicitly set front axis");s.front_direction={-1,0,0};FurniturePlacementQuery blocked(bodies,s);check(blocked.validate(p.value).reason==Rejection::Obstacle,"Continuous rotated sweep catches side wall");}
void regional_front_override(){
    const std::vector<FurnitureBody> bodies{{1,box(0,0,0,100,100,10)},{2,box(0,0,10,100,5,100)}};
    auto q=query(bodies,true);Probe p(50,50,10);
    check(q.validate(p.value).reason==Rejection::Obstacle,"Missing override uses the default blocked front");
    p.value.front_direction_override=Vec3{0,7,0};
    check(q.validate(p.value).reason==Rejection::None,"Per-probe front overrides global front and normalizes authored magnitude");
    p.value.front_direction_override=Vec3{0,-3,0};
    check(q.validate(p.value).reason==Rejection::Obstacle,"Opposite regional front detects the known wall");
    check(query(bodies,false).validate(p.value).reason==Rejection::None,"Regional front does not enable globally disabled access checking");
    p.value.front_direction_override.reset();check(q.validate(p.value).reason==Rejection::Obstacle,"Clearing override restores global front");
    for(Vec3 direction:std::vector<Vec3>{{0,0,0},{0,1,1},{INFINITY,0,0},{1e308,1e308,0},{1e7,0,0}}){
        p.value.front_direction_override=direction;rejects([&]{q.validate(p.value);});
    }
    QuerySettings settings;settings.front_direction={1e308,1e308,0};rejects([&]{FurniturePlacementQuery invalid(bodies,settings);});
}
void independent_obstacle_support_and_collision(){
    const std::vector<FurnitureBody> furniture{{1,box(0,0,0,100,100,10)}};
    const std::vector<FurnitureBody> obstacles{{2,box(30,30,10,70,70,60)}};
    QuerySettings settings;settings.require_front_access=false;FurniturePlacementQuery q(furniture,settings,obstacles);
    Probe on_obstacle(50,50,60);
    check(q.validate(on_obstacle.value).reason==Rejection::Boundary,"An independent obstacle's fully covered horizontal top cannot authorize support");
    Probe overlaps(50,50,10);
    check(q.validate(overlaps.value).reason==Rejection::Obstacle,"Independent decor blocks a prop supported by furniture underneath");
    Probe clear(85,85,10);
    check(q.validate(clear.value).reason==Rejection::None,"Furniture remains available away from the independent obstacle");
    const auto stats=q.diagnostics();
    check(stats.bodies==2&&stats.support_bodies==1&&stats.obstacle_bodies==1&&stats.triangles==24&&stats.vertices==48,"Diagnostics describe combined collision scope and separate support/obstacle bodies");
    check(stats.support_planes==1,"Independent obstacle bottom/top planes never enter the support table");
}
void independent_obstacle_containment_and_access(){
    const std::vector<FurnitureBody> furniture{{1,box(0,0,0,100,100,10)}};
    QuerySettings settings;settings.require_front_access=false;
    const std::vector<FurnitureBody> enclosing{{2,box(-50,-50,-50,150,150,150)}};
    FurniturePlacementQuery solid(furniture,settings,enclosing);Probe interior(50,50,10,10,10,10);
    check(solid.validate(interior.value).reason==Rejection::Obstacle,"A prop entirely inside a separate closed obstacle is rejected without a triangle crossing");
    Mesh wall;quad(wall,{0,0,10},{100,0,10},{100,0,100},{0,0,100});
    std::vector<FurnitureBody> screen{{2,wall}};
    FurniturePlacementQuery no_access(furniture,settings,screen);Probe p(50,50,10);
    check(no_access.validate(p.value).reason==Rejection::None,"Open obstacle screen away from the final prop has no static collision");
    settings.require_front_access=true;FurniturePlacementQuery access(furniture,settings,screen);
    check(access.validate(p.value).reason==Rejection::Obstacle,"Independent open screen blocks the continuous front sweep");
    p.value.front_direction_override=Vec3{0,1,0};check(access.validate(p.value).reason==Rejection::None,"Regional front applies to furniture and independent obstacles together");
    for(auto& triangle:screen[0].mesh.triangles)std::swap(triangle.vertices[0],triangle.vertices[2]);
    p.value.front_direction_override.reset();FurniturePlacementQuery reversed(furniture,settings,screen);
    check(reversed.validate(p.value).reason==Rejection::Obstacle,"Open external obstacle collision is two-sided");
}
void independent_obstacle_world_geometry_and_ownership(){
    const std::vector<FurnitureBody> furniture{{1,box(0,0,0,300,100,10)}};
    std::vector<FurnitureBody> obstacles{{2,box(0,0,10,10,20,40)}};
    // Caller-applied 90-degree rotation and translation put the known box at
    // x=[130,150], y=[30,40]. The query receives the resulting physical-mm mesh.
    for(auto& p:obstacles[0].mesh.vertices){const double x=p.x;p.x=150-p.y;p.y=30+x;}
    QuerySettings settings;settings.require_front_access=false;FurniturePlacementQuery q(furniture,settings,obstacles);
    obstacles[0].mesh.vertices.clear();obstacles[0].mesh.triangles.clear();
    Probe occupied(140,35,10,6,6,10),clear(50,50,10,6,6,10);
    check(q.validate(occupied.value).reason==Rejection::Obstacle,"Caller-transformed obstacle intersects at its world-frame location after source buffers are released");
    check(q.validate(clear.value).reason==Rejection::None,"Obstacle is not silently recentered or transformed a second time");
}
void independent_obstacle_admission(){
    const std::vector<FurnitureBody> furniture{{1,box(0,0,0,100,100,10)}};
    std::vector<FurnitureBody> obstacles{{2,box(200,0,0,300,100,10)}};
    QuerySettings settings;settings.require_front_access=false;settings.max_triangles=24;settings.max_vertices=48;
    check(FurniturePlacementQuery(furniture,settings,obstacles).diagnostics().bodies==2,"Exact aggregate triangle/vertex admission includes both scopes");
    settings.max_triangles=23;rejects([&]{FurniturePlacementQuery q(furniture,settings,obstacles);});settings.max_triangles=24;
    settings.max_vertices=47;rejects([&]{FurniturePlacementQuery q(furniture,settings,obstacles);});settings.max_vertices=48;
    obstacles[0].id=1;rejects([&]{FurniturePlacementQuery q(furniture,settings,obstacles);});
    obstacles[0].id=0;rejects([&]{FurniturePlacementQuery q(furniture,settings,obstacles);});obstacles[0].id=2;
    obstacles.push_back(obstacles[0]);settings.max_triangles=100;settings.max_vertices=100;
    rejects([&]{FurniturePlacementQuery q(furniture,settings,obstacles);});obstacles.resize(1);
    obstacles[0].mesh.triangles[0].vertices[0]=999;rejects([&]{FurniturePlacementQuery q(furniture,settings,obstacles);});
    std::vector<FurnitureBody> many(4096);rejects([&]{FurniturePlacementQuery q(furniture,settings,many);});
    rejects([&]{FurniturePlacementQuery q({},settings,obstacles);});
    settings.max_vertices=3000001;rejects([&]{FurniturePlacementQuery q(furniture,settings);});
}
void spacing_and_rotation(){auto q=query({{1,box(0,0,0,200,200,10)}});Probe p(50,50,10,20,20,30,45);std::vector<PlacedObstacle> others{{1,{{78,50,25},{10,10,15},0}}};p.value.accepted=others;check(q.validate(p.value).reason==Rejection::None,"Separated rotated boxes fit");p.value.spacing_mm=5;check(q.validate(p.value).reason==Rejection::Spacing,"Oriented spacing gap enforced");others[0].box.center.x=60;p.value.spacing_mm=0;check(q.validate(p.value).reason==Rejection::Obstacle,"Rotated bounds penetration rejects");}
void stack_support(){auto q=query({{1,box(0,0,0,100,100,10)}});Probe p(50,50,30,10,10,10);std::vector<Vec3> top{{30,30,30},{70,30,30},{70,70,30},{30,70,30}};std::vector<PlacedObstacle> parent{{9,{{50,50,20},{20,20,10},0}}};p.value.support_parent_id=9;p.value.parent_support_world=top;p.value.accepted=parent;p.value.spacing_mm=50;check(q.validate(p.value).reason==Rejection::None,"Authored stack top supports child and contact is exempt from spacing");p.value.edge_clearance_mm=16;check(q.validate(p.value).reason==Rejection::Stack,"Stack top containment margin enforced");}
void bounded_errors(){auto q=query({{1,box(0,0,0,100,100,10)}});Probe p(50,50,10);p.value.remaining_work=1;rejects([&]{q.validate(p.value);});p.value.remaining_work=50000000;p.value.collision.yaw_degrees=std::numeric_limits<double>::quiet_NaN();rejects([&]{q.validate(p.value);});QuerySettings s;s.max_build_work=1;const std::vector<FurnitureBody> bodies{{1,box(0,0,0,100,100,10)}};rejects([&]{FurniturePlacementQuery bad(bodies,s);});}
void round_inset_preflight(){
    Mesh ring;plane(ring,-3000000,-3000000,-500000,3000000,0);plane(ring,500000,-3000000,3000000,3000000,0);
    plane(ring,-500000,-3000000,500000,-500000,0);plane(ring,-500000,500000,500000,3000000,0);
    auto holed=query({{1,ring}});Probe p(-1800000,0,0,20,20,10);p.value.edge_clearance_mm=1000000;
    bool preflight=false;try{holed.validate(p.value);}catch(const std::runtime_error& e){preflight=std::string(e.what()).find("offset preflight")!=std::string::npos;}
    check(preflight,"Huge concave/hole joins reject before tessellation, rather than allocating their roughly 140000-point rounded outline first");
    Mesh rectangle;plane(rectangle,-3000000,-3000000,3000000,3000000,0);auto convex=query({{1,rectangle}});
    check(convex.validate(p.value).reason==Rejection::None,"The same million-mm inward clearance on a convex rectangle needs only constant-size inward joins and remains admitted");
    p.value.remaining_work=200;preflight=false;try{convex.validate(p.value);}catch(const std::runtime_error& e){preflight=std::string(e.what()).find("offset preflight")!=std::string::npos;}
    check(preflight,"Raw join bound is admitted against the remaining polygon work before calling the offsetter");
    p.value.remaining_work=50000000;Probe too_close(-2000000,0,0,20,20,10);too_close.value.edge_clearance_mm=1000000;
    check(convex.validate(too_close.value).reason==Rejection::Boundary,"Admission never lowers the requested clearance to accept a footprint too near the outer edge");
    p.value.support_parent_id=9;
    std::vector<Vec3> patch{{-3000000,-3000000,0},{3000000,-3000000,0},{3000000,3000000,0},{-3000000,3000000,0}};
    p.value.parent_support_world=patch;check(convex.validate(p.value).reason==Rejection::None,"Positive parent-patch orientation follows inward convex branch");
    std::reverse(patch.begin(),patch.end());check(convex.validate(p.value).reason==Rejection::None,"Reversed parent-patch orientation uses the pinned group delta reversal, not huge false round joins");
    Mesh l_shape;plane(l_shape,0,0,100,25,0);plane(l_shape,0,25,25,100,0);auto concave=query({{1,l_shape}});
    Probe diagonal_clear(20,20,0,1,1,1),diagonal_close(21,21,0,1,1,1);diagonal_clear.value.edge_clearance_mm=diagonal_close.value.edge_clearance_mm=6;
    check(concave.validate(diagonal_clear.value).reason==Rejection::None,"Ordinary admitted concave joins retain Euclidean rounded clearance: closest corner distance sqrt(4.5^2+4.5^2) exceeds 6 mm");
    check(concave.validate(diagonal_close.value).reason==Rejection::Boundary,"A corner sqrt(3.5^2+3.5^2) from the notch still violates the unchanged 6 mm clearance");
}
}
int main(){int failures=0;for(auto test:std::vector<std::pair<const char*,void(*)()>>{{"surface_and_edge",surface_and_edge},{"subcell_hole",subcell_hole},{"concave_surface",concave_surface},{"small_obstacle",small_obstacle},{"overhead_and_touch",overhead_and_touch},{"nested_solid",nested_solid},{"disconnected_solids",disconnected_solids},{"front_access",front_access},{"rotated_access",rotated_access},{"regional_front_override",regional_front_override},{"independent_obstacle_support_and_collision",independent_obstacle_support_and_collision},{"independent_obstacle_containment_and_access",independent_obstacle_containment_and_access},{"independent_obstacle_world_geometry_and_ownership",independent_obstacle_world_geometry_and_ownership},{"independent_obstacle_admission",independent_obstacle_admission},{"spacing_and_rotation",spacing_and_rotation},{"stack_support",stack_support},{"mixed_zero_area_faces",mixed_zero_area_faces},{"submicron_real_edges",submicron_real_edges},{"bounded_errors",bounded_errors},{"round_inset_preflight",round_inset_preflight}}){try{test.second();std::cout<<"PASS "<<test.first<<'\n';}catch(const std::exception& e){++failures;std::cerr<<"FAIL "<<test.first<<": "<<e.what()<<'\n';}}return failures?1:0;}

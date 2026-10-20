#include "cyrus_arrange/placement_queries.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <functional>
#include <iostream>
#include <stdexcept>
#include <string>

using namespace cyrus::arrange;
namespace {
void check(bool value,const char* message){if(!value)throw std::runtime_error(message);}
void quad(Mesh& m,Vec3 a,Vec3 b,Vec3 c,Vec3 d,bool alternate=false){
    const auto i=static_cast<std::uint32_t>(m.vertices.size());m.vertices.insert(m.vertices.end(),{a,b,c,d});
    if(alternate){m.triangles.push_back({{i,i+1,i+3}});m.triangles.push_back({{i+1,i+2,i+3}});}
    else{m.triangles.push_back({{i,i+1,i+2}});m.triangles.push_back({{i,i+2,i+3}});}
}
void plane(Mesh& m,double x0,double y0,double x1,double y1,double z){quad(m,{x0,y0,z},{x1,y0,z},{x1,y1,z},{x0,y1,z});}
Mesh jittered(){Mesh m;quad(m,{0,0,0},{100,0,0.0008},{100,100,0.0016},{0,100,0.0008},true);return m;}
struct Probe{
    std::vector<Vec3> footprint;PlacementProbe value;
    Probe(double x,double y,double z,double width=20,double depth=20){
        footprint={{x-width/2,y-depth/2,z},{x+width/2,y-depth/2,z},{x+width/2,y+depth/2,z},{x-width/2,y+depth/2,z}};
        value.footprint_world=footprint;value.support_z=z;value.collision={{x,y,z+10},{width/2,depth/2,10},0};value.region_id=1;value.remaining_work=50000000;
    }
};
FurniturePlacementQuery query(const Mesh& m,double tolerance=default_contact_tolerance_mm){QuerySettings s;s.require_front_access=false;s.contact_tolerance_mm=tolerance;return FurniturePlacementQuery(std::vector<FurnitureBody>{{1,m}},s);}
void bounded_zero_degree_inspection(){
    const auto mesh=jittered();Settings s;s.maximum_slope_degrees=0;s.minimum_clearance_mm=1;
    const auto result=inspect(mesh,s);check(result.regions.size()==1&&result.sampled_cells==16,"Zero-degree inspection admits a complete 1.6-micron triangle band without losing the five-ray gate");
    for(const auto& cell:result.regions.front().cells)check(cell.usable,"Open jittered board is available, not a manufactured blocked layer");
    Mesh slope;quad(slope,{0,0,0},{100,0,1},{100,100,1},{0,100,0});
    check(inspect(slope,s).regions.empty(),"A one-millimetre ramp does not acquire zero-degree support");
    for(auto& triangle:slope.triangles)std::swap(triangle.vertices[1],triangle.vertices[2]);
    check(inspect(slope,s).regions.empty(),"Downward winding remains rejected");
}
void cross_triangle_and_height_bin_seam(){
    const auto mesh=jittered();auto q=query(mesh);check(q.diagnostics().support_planes==2,"Alternative diagonal deliberately places the two coplanar triangles in different 1-micron bins");
    Probe p(50,50,0.0008,40,40);const auto result=q.validate(p.value);check(result.reason==Rejection::None,"Complete footprint crossing the real diagonal requires the union of both eligible bins");
    // Independent affine surface z=.000008(x+y); the entire rectangular patch
    // is bounded by its four corners, not by any core output or sampled cell.
    for(const auto& corner:p.footprint)check(std::abs(0.000008*(corner.x+corner.y)-p.value.support_z)<=default_contact_tolerance_mm,"Every analytic footprint corner respects the physical height band");
    const auto again=q.validate(p.value);check(again.reason==result.reason&&again.work_units==result.work_units,"Near-flat multi-bin fit is deterministic");
    p.value.remaining_work=result.work_units-1;bool failed=false;try{q.validate(p.value);}catch(const std::runtime_error&){failed=true;}check(failed,"Exact one-unit-short query work bound rejects instead of bypassing union/inset work");
}
void realistic_float_import_jitter(){
    const double low=static_cast<double>(166.33824f)*10,high=static_cast<double>(166.33830f)*10;
    check(high-low>0.0001&&high-low<default_contact_tolerance_mm,"Fixture reproduces a real float-import span between old and physical numerical tolerances");
    Mesh m;quad(m,{0,0,low},{1200,0,high},{1200,535,high},{0,535,low});const auto original=m.vertices;
    Settings settings;settings.maximum_slope_degrees=0;settings.minimum_clearance_mm=1;const auto inspected=inspect(m,settings);
    check(!inspected.regions.empty()&&inspected.sampled_cells>500,"Full-size imported board yields useful zero-degree candidates");
    auto q=query(m);Probe p(600,267.5,(low+high)/2,220,220);check(q.validate(p.value).reason==Rejection::None,"Original-size prop fits original floating-point board without flattening or rescaling it");
    for(std::size_t i=0;i<m.vertices.size();++i)check(m.vertices[i].x==original[i].x&&m.vertices[i].y==original[i].y&&m.vertices[i].z==original[i].z,"Source/collision vertices are unchanged by analysis and query construction");
}
void source_height_range_is_authoritative(){
    Mesh step;plane(step,0,0,50,100,0);plane(step,50,0,100,100,0.0041);auto q=query(step);Probe crosses(50,50,0,30,30);
    check(q.validate(crosses.value).reason==Rejection::Boundary,"Adjacent source area above the full physical height band cannot bridge a step");
    Probe between(50,50,0.00205,30,30);check(q.validate(between.value).reason==Rejection::Boundary,"Choosing the middle of an out-of-tolerance step cannot authorize both sides");
    Mesh ramp;for(int i=0;i<10;++i){double x=i*10;quad(ramp,{x,0,x*0.00018},{x+10,0,(x+10)*0.00018},{x+10,100,(x+10)*0.00018},{x,100,x*0.00018});}
    auto rq=query(ramp);check(rq.diagnostics().support_planes>2,"Ramp consists of individually near-flat tiles; rejection cannot rely only on one large triangle");
    Probe broad(50,50,0.009,40,40);check(rq.validate(broad.value).reason==Rejection::Boundary,"A chain of height bins cannot accumulate into unsupported broad ramp coverage");
    Mesh slope;quad(slope,{0,0,0},{100,0,8.75},{100,100,8.75},{0,100,0});auto sq=query(slope);Probe s(50,50,4.375,40,40);
    check(sq.diagnostics().support_planes==0&&sq.validate(s.value).reason==Rejection::Boundary,"Inspector-scale five-degree inclination never becomes a level prop contact patch");
}
void union_precedes_edge_inset_and_preserves_holes(){
    Mesh adjacent;plane(adjacent,0,0,50,100,0);plane(adjacent,50,0,100,100,0.0009);auto q=query(adjacent);Probe seam(50,50,0.00045,20,20);seam.value.edge_clearance_mm=10;
    check(q.validate(seam.value).reason==Rejection::None,"Union before inset avoids inventing a forbidden gap along the internal numerical height-bin seam");
    Probe outside(5,50,0.00045,10,20);outside.value.edge_clearance_mm=1;check(q.validate(outside.value).reason==Rejection::Boundary,"True outer-edge clearance remains strict after combining bins");
    Mesh ring;plane(ring,0,0,49,100,0);plane(ring,51,0,100,100,0.0009);plane(ring,49,0,51,49,0);plane(ring,49,51,51,100,0.0009);auto hole=query(ring);Probe p(50,50,0.00045,20,20);
    check(hole.validate(p.value).reason==Rejection::Boundary,"Exact union retains a two-millimetre interior hole missed by sampled-cell authorization");
    // Ten disjoint strips per bin produce 81 bounded holes after union. Their
    // 324 hole corners alone exceed the lowered 100-vertex output admission,
    // although the two retained input outlines contain only 80 vertices.
    Mesh strips;for(int i=0;i<10;++i){const double a=5+i*10;plane(strips,0,a,100,a+2,0);plane(strips,a,0,a+2,100,0.0009);}
    QuerySettings limited;limited.require_front_access=false;limited.max_support_vertices=100;
    FurniturePlacementQuery limited_query(std::vector<FurnitureBody>{{1,strips}},limited);Probe inside(6,6,0.00045,1,1);
    check(limited_query.diagnostics().support_vertices==80,"Crossed-strip fixture has an independently known 80-vertex retained input");
    bool rejected=false;try{limited_query.validate(inside.value);}catch(const std::runtime_error& error){rejected=std::string(error.what()).find("combined support union exceeds vertex admission")!=std::string::npos;}
    check(rejected,"New union output complexity is rejected after union; the retained/input vertex cap is not a temporary byte cap");
}
void explicit_contact_settings_and_collision(){
    Mesh m;quad(m,{0,0,0},{100,0,0.0015},{100,100,0.0015},{0,100,0});Probe p(50,50,0.00075,20,20);
    check(query(m).validate(p.value).reason==Rejection::None,"Shared default tolerance admits the independently bounded source band");
    check(query(m,0.001).validate(p.value).reason==Rejection::Boundary,"An explicit tighter query contact tolerance remains authoritative");
    Mesh larger;quad(larger,{0,0,0},{100,0,0.003},{100,100,0.003},{0,100,0});Probe other(50,50,0.0015,20,20);
    check(query(larger).validate(other.value).reason==Rejection::Boundary&&query(larger,0.004).validate(other.value).reason==Rejection::None,"Only explicit query settings can admit a band larger than the two-micron default");
    Mesh obstacle;plane(obstacle,49,49,51,51,1);QuerySettings settings;settings.require_front_access=false;
    FurniturePlacementQuery blocked(std::vector<FurnitureBody>{{1,m}},settings,std::vector<FurnitureBody>{{2,obstacle}});
    check(blocked.validate(p.value).reason==Rejection::Obstacle,"Unmodified furniture/independent-obstacle collision still rejects material above the numerical band");
    const double base=1000000,too_high=std::nextafter(base+default_contact_tolerance_mm,INFINITY);
    check(too_high-base>default_contact_tolerance_mm,"Large-coordinate fixture has a stored height difference strictly above tolerance");
    Mesh high;plane(high,0,0,100,100,too_high);auto hq=query(high);Probe hp(50,50,base);
    check(hq.validate(hp.value).reason==Rejection::Boundary,"Rounded support_z+tolerance cannot admit an actually larger source height difference");
    Probe extreme(50,50,1e308);extreme.value.collision={{50,50,10},{10,10,10},0};bool invalid=false;
    try{hq.validate(extreme.value);}catch(const std::invalid_argument&){invalid=true;}
    check(invalid,"An extreme finite support height is rejected before integer-bin quantization, even with bounded collision geometry");
}
}
int main(){int failures=0;for(const auto& test:std::vector<std::pair<const char*,void(*)()>>{
    {"bounded_zero_degree_inspection",bounded_zero_degree_inspection},{"cross_triangle_and_height_bin_seam",cross_triangle_and_height_bin_seam},
    {"realistic_float_import_jitter",realistic_float_import_jitter},{"source_height_range_is_authoritative",source_height_range_is_authoritative},
    {"union_precedes_edge_inset_and_preserves_holes",union_precedes_edge_inset_and_preserves_holes},{"explicit_contact_settings_and_collision",explicit_contact_settings_and_collision}}){
    try{test.second();std::cout<<"PASS "<<test.first<<'\n';}catch(const std::exception& error){++failures;std::cerr<<"FAIL "<<test.first<<": "<<error.what()<<'\n';}}
    return failures?1:0;
}

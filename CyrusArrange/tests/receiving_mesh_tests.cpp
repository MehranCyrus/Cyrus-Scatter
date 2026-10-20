#include "cyrus_arrange/receiving_mesh.h"
#include "cyrus_arrange/placement_queries.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace cyrus::arrange;
namespace {
std::size_t checks{};
void check(bool value,const char* why){++checks;if(!value)throw std::runtime_error(why);}
void reject(const std::function<void()>& action){bool failed=false;try{action();}catch(const std::exception&){failed=true;}check(failed,"Invalid or over-budget receiving preparation must reject");}
Mesh box(double x0=0,double y0=0,double z0=0,double x1=100,double y1=100,double z1=20){
    Mesh m;m.vertices={{x0,y0,z0},{x1,y0,z0},{x1,y1,z0},{x0,y1,z0},{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}};
    m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;
}
void invert(Mesh& m){for(auto& t:m.triangles)std::swap(t.vertices[1],t.vertices[2]);}
void append(Mesh& to,const Mesh& from){const auto offset=static_cast<std::uint32_t>(to.vertices.size());to.vertices.insert(to.vertices.end(),from.vertices.begin(),from.vertices.end());for(auto t:from.triangles){for(auto& i:t.vertices)i+=offset;to.triangles.push_back(t);}}
bool equal(const Mesh& a,const Mesh& b){if(a.vertices.size()!=b.vertices.size()||a.triangles.size()!=b.triangles.size())return false;for(std::size_t i=0;i<a.vertices.size();++i){const auto x=a.vertices[i],y=b.vertices[i];if(x.x!=y.x||x.y!=y.y||x.z!=y.z)return false;}for(std::size_t i=0;i<a.triangles.size();++i)if(a.triangles[i].vertices!=b.triangles[i].vertices)return false;return true;}
ReceivingMeshPreparation prepare(Mesh& m,const ReceivingMeshLimits& limits={}){const std::array<Mesh*,1> scope{&m};return prepare_receiving_meshes(scope,limits);}
bool supported(const Mesh& m,double x=50,double y=50,double z=20){
    QuerySettings q;q.require_front_access=false;const std::vector<FurnitureBody> bodies{{1,m}};FurniturePlacementQuery query(bodies,q);
    const std::array<Vec3,4> foot{{{x-5,y-5,z},{x+5,y-5,z},{x+5,y+5,z},{x-5,y+5,z}}};PlacementProbe p;p.footprint_world=foot;p.collision={{x,y,z+15},{5,5,15},0};p.support_z=z;p.remaining_work=50000000;return query.validate(p).reason==Rejection::None;
}
void basic_and_preservation(){
    auto outward=box(),derived=outward;const auto original=outward;invert(derived);
    check(!supported(derived),"Authored inward glass reproduces invalid physical-top support");
    const auto result=prepare(derived);check(result.reversed_components==1&&result.reversed_faces==12&&result.open_components==0,"One closed inward board is prepared");
    check(equal(derived,outward)&&equal(original,outward),"Only derived face winding changes; original vertices and geometry remain intact");check(supported(derived),"Precise query accepts actual top after preparation");
    Settings s;s.cell_size_mm=20;s.minimum_clearance_mm=30;const auto inspected=inspect(derived,s);bool top=false;
    for(const auto& r:inspected.regions)for(const auto& c:r.cells)if(c.usable&&std::abs(c.center.z-20)<1e-8)top=true;
    check(top,"Inspector and precise query agree on the prepared physical top");
    const auto again=prepare(derived);check(again.reversed_components==0&&equal(derived,outward),"Preparation is idempotent");
    Result report;append_receiving_warnings(report,result);check(report.warnings.size()==1,"Actual preparation adds bounded contextual inspection feedback");
}
void mixed_and_open(){
    auto outward=box(),inward=box(200,0,0,300,100,20);invert(inward);Mesh open;open.vertices={{400,0,20},{500,0,20},{500,100,20},{400,100,20}};open.triangles={{{0,2,1}},{{0,3,2}}};
    const auto initial_out=outward,initial_open=open;std::array<Mesh*,3> scope{&outward,&inward,&open};const auto r=prepare_receiving_meshes(scope);
    check(r.reversed_components==1&&r.open_components==1,"Mixed receiving polarity prepares only the closed inward body");
    check(equal(outward,initial_out)&&equal(open,initial_open),"Outward and open authored faces remain unchanged");check(supported(inward,250),"Prepared second receiving node has real support");
    auto inconsistent=box();std::swap(inconsistent.triangles[0].vertices[1],inconsistent.triangles[0].vertices[2]);const auto before=inconsistent;const auto bad=prepare(inconsistent);
    check(bad.reversed_components==0&&bad.open_components==1&&equal(before,inconsistent),"Inconsistent edge orientations are never guessed");
    auto nonmanifold=box();invert(nonmanifold);nonmanifold.triangles.push_back(nonmanifold.triangles[0]);const auto copy=nonmanifold;
    check(prepare(nonmanifold).reversed_components==0&&equal(copy,nonmanifold),"Nonmanifold closed-looking faces retain authored winding");
}
void ambiguity(){
    auto outer=box(0,0,0,100,100,100),inner=box(20,20,20,80,80,80);invert(inner);const auto before=inner;
    const std::array<Mesh*,2> nested{&outer,&inner};const auto r=prepare_receiving_meshes(nested);check(r.reversed_components==0&&r.ambiguous_components==1&&equal(before,inner),"Nested separate receiving nodes stay conservative");
    auto a=box(),b=box(50,0,0,150,100,20);invert(a);const auto original=a;const std::array<Mesh*,2> overlapping{&a,&b};
    const auto overlap=prepare_receiving_meshes(overlapping);check(overlap.reversed_components==0&&overlap.ambiguous_components==1&&equal(a,original),"Potentially intersecting closed shells are not reinterpreted");
    a=box();invert(a);b=box(100,0,0,200,100,20);const auto touching=prepare_receiving_meshes(overlapping);check(touching.reversed_components==1&&touching.ambiguous_components==0,"Touching independent boards do not imply nested volumes");
    Mesh flat;flat.vertices={{0,0,0},{100,0,0},{0,100,0},{25,25,0}};flat.triangles={{{0,2,1}},{{0,1,3}},{{1,2,3}},{{2,0,3}}};const auto flat_before=flat;const auto zero=prepare(flat);
    check(zero.ambiguous_components==1&&zero.reversed_components==0&&equal(flat,flat_before),"Closed zero-volume topology keeps its authored faces");
}
void duplicate_and_tiny(){
    const auto base=box();Mesh hard;
    for(const auto& t:base.triangles){const auto n=static_cast<std::uint32_t>(hard.vertices.size());for(auto i:t.vertices)hard.vertices.push_back(base.vertices[i]);hard.triangles.push_back({{n,n+1,n+2}});}
    hard.triangles.push_back({{0,0,0}});invert(hard);const auto r=prepare(hard);check(r.reversed_components==1&&r.reversed_faces==12&&hard.triangles.size()==13&&supported(hard),"Hard-edge duplicates and zero-area authored faces retain valid closed support");
    Mesh m;const std::array<Vec3,5> ring{{{0,0,0},{1.0/4096,0,0},{100,0,0},{100,100,0},{0,100,0}}};
    const auto triangle=[&](Vec3 a,Vec3 b,Vec3 c){const auto n=static_cast<std::uint32_t>(m.vertices.size());m.vertices.insert(m.vertices.end(),{a,b,c});m.triangles.push_back({{n,n+1,n+2}});};
    for(std::size_t i=0;i<ring.size();++i){const auto a=ring[i],b=ring[(i+1)%ring.size()];const Vec3 at{a.x,a.y,20},bt{b.x,b.y,20};triangle({50,50,0},b,a);triangle({50,50,20},at,bt);triangle(a,b,bt);triangle(a,bt,at);}
    invert(m);const auto tiny=prepare(m);check(tiny.reversed_components==1&&tiny.reversed_faces==20&&supported(m),"Exact topology fallback preserves real sub-micron edges during preparation");
}
void concave_and_transformed(){
    Mesh m;m.vertices={{0,0,0},{100,0,0},{100,40,0},{40,40,0},{40,100,0},{0,100,0}};for(std::size_t i=0;i<6;++i){auto p=m.vertices[i];p.z=20;m.vertices.push_back(p);}
    for(auto t:std::array<Triangle,4>{{{{0,1,3}},{{1,2,3}},{{0,3,5}},{{3,4,5}}}}){m.triangles.push_back({{t.vertices[0],t.vertices[2],t.vertices[1]}});for(auto& i:t.vertices)i+=6;m.triangles.push_back(t);}
    for(std::uint32_t i=0;i<6;++i){auto j=(i+1)%6;m.triangles.push_back({{i,j,j+6}});m.triangles.push_back({{i,j+6,i+6}});}
    invert(m);check(prepare(m).reversed_components==1&&supported(m,20,80)&&!supported(m,80,80),"Concave closed receiving geometry keeps the real notch after orientation");
    auto mirrored=box();invert(mirrored);for(auto& p:mirrored.vertices){p.x=-p.x+1000000;p.y+=-2000000;p.z+=3000000;}invert(mirrored); // compensate capture parity; still authored inward
    const auto r=prepare(mirrored);check(r.reversed_components==1&&supported(mirrored,999950,-1999950,3000020),"Centered volume remains reliable after mirrored translated capture");
    Mesh many;for(int i=0;i<64;++i){auto piece=box(i*200.,0,0,i*200.+100,100,20);invert(piece);append(many,piece);}const auto sweep=prepare(many);
    check(sweep.reversed_components==64&&sweep.ambiguous_components==0&&sweep.work<50000000,"Large disjoint inward assemblies pass bounded sweep screening");
}
void atomic_limits(){
    auto a=box();invert(a);const auto initial=a;auto b=box(200,0,0,300,100,20);b.triangles[0].vertices[1]=999;
    const std::array<Mesh*,2> invalid{&a,&b};reject([&]{prepare_receiving_meshes(invalid);});check(equal(a,initial),"Later invalid body cannot partially prepare an earlier receiver");
    const std::array<Mesh*,2> duplicate{&a,&a};reject([&]{prepare_receiving_meshes(duplicate);});const std::array<Mesh*,1> null{nullptr};reject([&]{prepare_receiving_meshes(null);});
    auto changed=a;const auto full=prepare(changed);ReceivingMeshLimits limit;limit.max_work=full.work-1;reject([&]{prepare(a,limit);});check(equal(a,initial),"Final pass admission fails before any derived face mutation");
    limit={};limit.max_vertices=1;reject([&]{prepare(a,limit);});limit={};limit.max_triangles=1;reject([&]{prepare(a,limit);});
    auto nan=a;nan.vertices.push_back({NAN,0,0});reject([&]{prepare(nan);});check(equal(a,initial),"All preparation failures preserve original input vertices and faces");
}
}
int main(){try{basic_and_preservation();mixed_and_open();ambiguity();duplicate_and_tiny();concave_and_transformed();atomic_limits();std::cout<<"Receiving preparation passed "<<checks<<" checks\n";return 0;}catch(const std::exception& e){std::cerr<<"Receiving preparation failed after "<<checks<<" checks: "<<e.what()<<'\n';return 1;}}

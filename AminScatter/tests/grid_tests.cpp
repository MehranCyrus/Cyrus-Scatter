#include "grid.h"
#include "receiver_plan.h"
#include "mesh_density.h"
#include "surface_filter.h"
#include "execution.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <map>
#include <set>
#include <stdexcept>
#include <limits>
using namespace cyrus::grid;
namespace {
unsigned checks=0;
void check(bool v,const char* message){++checks;if(!v)throw std::runtime_error(message);}
template<class F>void denied(F fn){bool caught=false;try{fn();}catch(const std::invalid_argument&){caught=true;}check(caught,"Invalid grid admitted");}
bool near(double a,double b,double e=1e-9){return std::abs(a-b)<=e;}
bool same(amin::Vec3 a,amin::Vec3 b){return a.x==b.x&&a.y==b.y&&a.z==b.z;}
std::vector<amin::Triangle> plane(double lo,double hi,double z=0){return {{{lo,lo,z},{hi,lo,z},{lo,hi,z}},{{hi,lo,z},{hi,hi,z},{lo,hi,z}}};}
void identities(){
    std::set<std::uint64_t> ids;
    for(auto mode:{Mode::Rectangular,Mode::Staggered,Mode::Hexagonal})for(unsigned receiver=0;receiver<128;++receiver)
        for(auto x:{minCell,-1,0,1,maxCell})for(auto y:{minCell,-1,0,1,maxCell}){
            const auto id=identity({mode,receiver,x,y});Cell decoded;
            check(id<=std::uint64_t(INT64_MAX)&&decode(id,decoded),"Cell decode failed");
            check(decoded.mode==mode&&decoded.receiver==receiver&&decoded.column==x&&decoded.row==y,"Cell round trip changed coordinate");
            check(ids.insert(id).second,"Cell alias");unsigned slot=0,ordinal=0;
            check(!cyrus::receivers::decode(id,slot,ordinal),"Cell aliases existing random family");
            std::uint64_t local=0;check(cyrus::receivers::decodeCandidate(id,slot,local)&&slot==receiver,"Common cell decoder lost receiver");
            check(cyrus::receivers::candidateIdentity(slot,local)==id,"Common cell transport truncated identity");
        }
    Cell c;check(!decode(0,c)&&!decode(UINT64_MAX,c)&&!decode(marker|(3ULL<<59),c),"Invalid cell decoded");
    denied([]{identity({Mode::Rectangular,128,0,0});});denied([]{identity({Mode::Rectangular,0,minCell-1,0});});
    denied([]{identity({Mode::Hexagonal,0,0,maxCell+1});});
    for(unsigned receiver=0;receiver<128;++receiver)for(unsigned ordinal:{0u,1u,131071u,131072u,999999u}){
        const auto id=cyrus::receivers::identity(receiver,ordinal);unsigned slot=0;std::uint64_t local=0;
        check(cyrus::receivers::decodeCandidate(id,slot,local)&&slot==receiver&&local==ordinal,"Common decoder changed existing random IDs");
        check(cyrus::receivers::candidateIdentity(slot,local)==id,"Common transport changed existing random IDs");
    }
    denied([]{cyrus::receivers::candidateIdentity(0,1000000);});
    denied([]{cyrus::receivers::candidateIdentity(0,identity({Mode::Rectangular,1,0,0}));});
}
void positions(){
    Settings s;auto mesh=plane(-2,2);auto result=generate(mesh,s);
    check(result.anchors.size()==25&&result.enumeratedCells==25,"Rectangular analytic count");
    std::set<std::pair<int,int>> expected;
    for(int y=-2;y<=2;++y)for(int x=-2;x<=2;++x)expected.emplace(x,y);
    for(const auto& a:result.anchors){Cell c;check(decode(a.key,c),"No local key");
        check(expected.erase({c.column,c.row})==1&&near(a.position.x,c.column)&&near(a.position.y,c.row)&&a.position.z==0,"Rectangular analytic position");
        check(near(a.bary.x+a.bary.y+a.bary.z,1),"Invalid barycentric anchor");
        if(c.column+c.row==0)check(a.face==0,"Shared-edge tie must choose first face");
    }
    check(expected.empty(),"Analytic cell missing");
    s.mode=Mode::Staggered;result=generate(mesh,s);check(result.anchors.size()==23,"Staggered analytic count");
    for(const auto& a:result.anchors){Cell c;decode(a.key,c);const double shift=c.row%2==0?0:.5;
        check(near(a.position.x,c.column+shift)&&near(a.position.y,c.row),"Negative/positive stagger parity differs");}
    s.mode=Mode::Hexagonal;result=generate(plane(-3,3),s);
    for(const auto& a:result.anchors){Cell c;decode(a.key,c);const double shift=c.row%2==0?0:.5;
        check(near(a.position.x,c.column+shift)&&near(a.position.y,c.row*std::sqrt(3.)*.5),"Hex analytic position");
        double nearest=INFINITY;for(const auto& b:result.anchors)if(a.key!=b.key)nearest=std::min(nearest,amin::length(a.position-b.position));
        check(near(nearest,1),"Hex nearest-neighbor distance differs from spacing");}
    // Exact analytic rotation/origin/unit conversion, independent of bounds indexing.
    s={};s.originX=13;s.originY=-7;s.headingDegrees=31;s.columnSpacing=10;s.rowSpacing=10;
    const double angle=31*std::acos(-1.)/180,cs=std::cos(angle),sn=std::sin(angle);
    mesh=plane(-20,20);
    const auto move=[&](amin::Vec3& p){const auto x=p.x,y=p.y;p.x=13+x*cs-y*sn;p.y=-7+x*sn+y*cs;p.z=2*x+3*y;};
    for(auto& t:mesh){move(t.a);move(t.b);move(t.c);}
    result=generate(mesh,s);check(result.anchors.size()==25,"Rotated/unit-scaled cell count changed");
    for(const auto& a:result.anchors){Cell c;decode(a.key,c);const double x=c.column*10.,y=c.row*10.;
        check(near(a.position.x,13+x*cs-y*sn)&&near(a.position.y,-7+x*sn+y*cs)&&near(a.position.z,2*x+3*y),"Rotated sloped projection differs from analytic plane");}
}
void surfaces(){
    Settings s;auto mesh=plane(-2,2);auto upper=plane(-1,1,5);mesh.insert(mesh.end(),upper.begin(),upper.end());
    const auto result=generate(mesh,s);check(result.anchors.size()==25,"Stacked surfaces duplicated cells");
    for(const auto& a:result.anchors)check(a.position.z==((std::abs(a.position.x)<=1&&std::abs(a.position.y)<=1)?5:0),"Did not select highest projected surface");
    auto holes=plane(-3,-1);auto other=plane(1,3);holes.insert(holes.end(),other.begin(),other.end());
    const auto split=generate(holes,s);check(split.anchors.size()==18,"Projected holes emitted plants");
    for(const auto& a:split.anchors)check(a.position.x!=0&&a.position.y!=0,"Gap filled by nearest projection");
    std::vector<amin::Triangle> wall{{{0,0,0},{0,1,0},{0,0,1}}};denied([&]{generate(wall,s);});
    wall.insert(wall.end(),mesh.begin(),mesh.end());check(generate(wall,s).anchors.size()==25,"Vertical sides blocked valid top hits");
    // Barycentric evaluation must not fabricate height differences on coplanar
    // duplicates with different corner order, even far from the world origin.
    mesh={{{-.3,-.7,1e12},{2.7,-.7,1e12},{-.3,2.3,1e12}},{{-.3,2.3,1e12},{-.3,-.7,1e12},{2.7,-.7,1e12}}};
    s.columnSpacing=.1;s.rowSpacing=.1;
    for(const auto& a:generate(mesh,s).anchors)check(a.position.z==1e12&&a.face==0,"Coplanar height roundoff changed topmost tie");
}
bool sameRow(const amin::Instance& a,const amin::Instance& b){
    return a.candidateKey==b.candidateKey&&same(a.position,b.position)&&same(a.xAxis,b.xAxis)&&same(a.yAxis,b.yAxis)&&same(a.zAxis,b.zAxis)&&a.scale==b.scale&&a.source==b.source&&a.bandOwner==b.bandOwner;
}
void pipeline(){
    Settings grid;grid.jitter=.25;grid.receiverSalt=123;const auto mesh=plane(-10,10),expanded=plane(-12,12);
    const auto anchors=generate(mesh,grid).anchors,more=generate(expanded,grid).anchors;
    amin::Settings s;s.count=unsigned(anchors.size());s.sourceCount=3;s.sourceWeights={1,.5,0};s.receiverSalt=grid.receiverSalt;
    s.rotationDegrees={{{-20,20},{-15,15},{0,360}}};s.axisScale={{{.5,2},{.7,3},{.9,4}}};
    auto rows=amin::scatter(mesh,s,anchors);check(rows.size()==anchors.size(),"Explicit anchors lost to count/density controls");
    std::map<std::uint64_t,amin::Instance> baseline;for(const auto& a:rows){baseline.emplace(a.candidateKey,a);check(a.source<2,"Zero weight source used by a grid");}
    auto shuffled=anchors;std::reverse(shuffled.begin(),shuffled.end());
    for(const auto& a:amin::scatter(mesh,s,shuffled))check(sameRow(a,baseline.at(a.candidateKey)),"Anchor order changed source/transform randomness");
    s.count=unsigned(more.size());for(const auto& a:amin::scatter(expanded,s,more))if(baseline.count(a.candidateKey))check(sameRow(a,baseline.at(a.candidateKey)),"Expanded receiver rerolled surviving full grid row");
    s.count=unsigned(anchors.size());
    s.areas={{{{{-5,-5,0},{5,-5,0},{5,5,0},{-5,5,0}}},true}};
    auto masked=amin::scatter(mesh,s,anchors);check(!masked.empty()&&masked.size()<rows.size(),"Grid ignored Include mask");
    for(const auto& a:masked)check(sameRow(a,baseline.at(a.candidateKey)),"Include mask rerolled surviving grid row");
    s.areas.clear();s.distribution=2;s.densityWidth=s.densityHeight=2;s.density={.5,.5,.5,.5};
    masked=amin::scatter(mesh,s,anchors);check(!masked.empty()&&masked.size()<rows.size(),"Grid ignored UV density thinning");
    for(const auto& a:masked)check(sameRow(a,baseline.at(a.candidateKey)),"UV thinning rerolled surviving grid row");
    s.distribution=0;s.rotationDegrees[0]={0,0};
    for(const auto& a:amin::scatter(mesh,s,anchors)){const auto& b=baseline.at(a.candidateKey);check(same(a.position,b.position)&&a.source==b.source&&a.scale==b.scale,"Rotation changed grid positions/source/scale");}
    // Full cell keys reach stochastic downstream filters without ordinal casts.
    cyrus::surface_filter::Settings filter;filter.slope={true,0,45,0,15};
    for(const auto& a:rows){unsigned slot=0;std::uint64_t local=0;const auto encoded=cyrus::receivers::candidateIdentity(127,a.candidateKey);
        check(cyrus::receivers::decodeCandidate(encoded,slot,local)&&local==a.candidateKey,"Filter key transport changed");
        check(cyrus::mesh_density::accepts(.5,s.seed,local,s.receiverSalt)==cyrus::mesh_density::accepts(.5,s.seed,a.candidateKey,s.receiverSalt),"Mesh filter cell key mismatch");
        check(cyrus::surface_filter::accepts(filter,40,0,s.seed,local,s.receiverSalt)==cyrus::surface_filter::accepts(filter,40,0,s.seed,a.candidateKey,s.receiverSalt),"Slope filter cell key mismatch");
    }
    auto invalid=anchors;invalid.push_back(anchors.front());s.count=unsigned(invalid.size());denied([&]{amin::scatter(mesh,s,invalid);});
    s.count=unsigned(anchors.size());invalid=anchors;invalid[0].position.z+=1;denied([&]{amin::scatter(mesh,s,invalid);});
    s.candidateStart=1;denied([&]{amin::scatter(mesh,s,anchors);});s.candidateStart=0;
    s.analyzerPattern=true;s.analyzerBands.resize(1);s.analyzerBands[0].kind=5;denied([&]{amin::scatter(mesh,s,anchors);});
    s.analyzerBands[0].kind=6;denied([&]{amin::scatter(mesh,s,anchors);});
    s.analyzerPattern=false;s.analyzerBands.clear();s.sourceWeights={0,0,0};check(amin::scatter(mesh,s,anchors).empty(),"Zero-weight grid is not empty");
    s.count=0;check(amin::scatter(mesh,s,std::vector<amin::CandidateAnchor>{}).empty(),"Empty projected grid refilled random candidates");
    const auto wide=plane(-40,40);grid.jitter=0;const auto dense=generate(wide,grid).anchors;
    s={};s.count=unsigned(dense.size());s.sourceCount=3;s.clusterEnabled=true;s.clusterSize=7;
    amin::setComputeThreads(1);const auto serial=amin::scatter(wide,s,dense);
    amin::setComputeThreads(4);const auto parallel=amin::scatter(wide,s,dense);
    check(serial.size()==parallel.size()&&serial.size()==dense.size(),"Batched cluster grid count differs");
    for(std::size_t i=0;i<serial.size();++i)check(sameRow(serial[i],parallel[i]),"Parallel clustered grid differs from serial anchor pipeline");
    amin::setComputeThreads(0);
}
void stabilityAndLimits(){
    Settings s;s.jitter=.7;s.receiverSalt=12345;const auto small=generate(plane(-3,3),s),large=generate(plane(-5,5),s);
    std::map<std::uint64_t,Anchor> more;for(const auto& a:large.anchors)more.emplace(a.key,a);
    check(!small.anchors.empty(),"Empty jitter fixture");
    for(const auto& a:small.anchors){const auto& b=more.at(a.key);check(same(a.position,b.position),"Expanded footprint rerolled surviving cell");}
    const auto repeat=generate(plane(-3,3),s);check(repeat.anchors.size()==small.anchors.size(),"Jitter repeat count");
    for(std::size_t i=0;i<small.anchors.size();++i)check(small.anchors[i].key==repeat.anchors[i].key&&same(small.anchors[i].position,repeat.anchors[i].position),"Jitter repeat differs");
    s.receiverSalt=999;const auto changed=generate(plane(-3,3),s);bool differs=changed.anchors.size()!=small.anchors.size();
    for(const auto& a:changed.anchors)if(more.count(a.key)&&!same(a.position,more.at(a.key).position))differs=true;
    check(differs,"Receiver variation does not affect grid jitter");
    Limits lim;lim.cells=24;denied([&]{generate(plane(-2,2),Settings{},lim);});
    lim={};lim.visits=1;denied([&]{generate(plane(-2,2),Settings{},lim);});
    lim={};lim.triangles=1;denied([&]{generate(plane(-2,2),Settings{},lim);});
    lim={};lim.bytes=1;denied([&]{generate(plane(-2,2),Settings{},lim);});
    s={};s.columnSpacing=0;denied([&]{generate(plane(-2,2),s);});
    s={};s.jitter=1.1;denied([&]{generate(plane(-2,2),s);});
    s={};s.originX=std::numeric_limits<double>::infinity();denied([&]{generate(plane(-2,2),s);});
    s={};s.columnSpacing=1e-100;denied([&]{generate(plane(-2,2),s);});
    s={};denied([&]{generate(plane(double(maxCell)+1,double(maxCell)+2),s);});
    auto bad=plane(-2,2);bad[0].a.z=std::numeric_limits<double>::quiet_NaN();denied([&]{generate(bad,s);});
}
void tessellation(){
    std::vector<amin::Triangle> mesh;mesh.reserve(180000);
    constexpr unsigned n=300;const auto point=[](unsigned x,unsigned y){return amin::Vec3{double(x)*10,double(y)*10,double(x)*2+double(y)*3};};
    for(unsigned y=0;y<n;++y)for(unsigned x=0;x<n;++x){const auto a=point(x,y),b=point(x+1,y),c=point(x,y+1),d=point(x+1,y+1);mesh.push_back({a,b,c});mesh.push_back({b,d,c});}
    Settings s;s.columnSpacing=30;s.rowSpacing=30;const auto start=std::chrono::steady_clock::now();const auto result=generate(mesh,s);
    check(result.anchors.size()==10201,"Tessellated grid count");
    for(const auto& a:result.anchors)check(near(a.position.z,.2*a.position.x+.3*a.position.y,1e-8),"Tessellated sloped hit mismatch");
    check(result.projectionVisits<1000000,"Projection unexpectedly approaches exhaustive work");
    std::cout<<"180000 faces / 10201 hits: "<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count()<<" ms; visits="<<result.projectionVisits<<'\n';
}
}
int main(){try{identities();positions();surfaces();pipeline();stabilityAndLimits();tessellation();std::cout<<"PASS "<<checks<<" grid identity, analytic projection, pipeline, jitter and admission checks\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL after "<<checks<<": "<<e.what()<<'\n';return 1;}}

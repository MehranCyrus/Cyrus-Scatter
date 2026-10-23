#include "scatter.h"
#include "projected_movement.h"
#include "receiver_mesh_validation.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <limits>
#include <numeric>
#include <random>
#include <stdexcept>
#include <string>

using namespace amin;
namespace {
void check(bool ok,const char* text){if(!ok)throw std::runtime_error(text);}
template<class F> void rejects(F f,const char* text){bool threw=false;try{f();}catch(const std::invalid_argument&){threw=true;}check(threw,text);}
bool same(Vec3 a,Vec3 b){return a.x==b.x&&a.y==b.y&&a.z==b.z;}
void sameRows(const std::vector<Instance>& a,const std::vector<Instance>& b,const char* text){
    check(a.size()==b.size(),text);
    for(std::size_t i=0;i<a.size();++i)check(same(a[i].position,b[i].position)&&same(a[i].xAxis,b[i].xAxis)&&
        same(a[i].yAxis,b[i].yAxis)&&same(a[i].zAxis,b[i].zAxis)&&a[i].scale==b[i].scale&&a[i].source==b[i].source&&
        a[i].triangle==b[i].triangle&&a[i].candidateKey==b[i].candidateKey&&a[i].bandOwner==b[i].bandOwner,text);
}
std::vector<Triangle> strip(unsigned count){
    std::vector<Triangle> mesh;mesh.reserve(count);
    for(unsigned i=0;i<count;++i){const double x=i;mesh.push_back({{x,0,0},{x+1,0,0},{x,1,0},{0,0,0},{1,0,0},{0,1,0}});}return mesh;
}
std::vector<Triangle> square(){return {{{0,0,0},{1,0,0},{0,1,0},{0,0,0},{1,0,0},{0,1,0}},
    {{1,0,0},{1,1,0},{0,1,0},{1,0,0},{1,1,0},{0,1,0}}};}
std::vector<Instance> three(){
    std::vector<Instance> rows(3);rows[0].position={.1,.1,0};rows[1].position={.2,.1,0};rows[2].position={.1,.2,0};
    for(unsigned i=0;i<rows.size();++i){rows[i].candidateKey=i;rows[i].scale=1;rows[i].xAxis={1,0,0};rows[i].yAxis={0,1,0};rows[i].zAxis={0,0,1};}return rows;
}
Settings nativeImage(Settings s){
    auto image=std::make_shared<cyrus::density::ImageData>();image->width=s.densityWidth;image->height=s.densityHeight;image->pixels=s.density;
    s.densityImage=image;s.density.clear();s.densityWidth=s.densityHeight=0;return s;
}
std::vector<Instance> boundary(const std::vector<Triangle>& mesh,const Settings& s,const std::vector<Instance>& rows,FinalSettings f={}){
    f.relax=true;if(f.radius==1){f.strength=.3;f.maxMove=.1;f.iterations=1;}
    return finalize(mesh,s,rows,{},std::vector<double>(rows.size()),{},f);
}
double sampled(const std::vector<Triangle>& mesh,const Settings& s,const Instance& row){
    cyrus::density::ImageSampler sample(s.density,s.densityWidth,s.densityHeight,s.densityMapping);
    double u=0,v=0;
    if(s.densityMapping.coordinates==cyrus::density::Coordinates::UV){
        const auto& t=mesh[row.triangle];const auto ab=t.b-t.a,ac=t.c-t.a,ap=row.position-t.a;
        const double aa=dot(ab,ab),bb=dot(ac,ac),cc=dot(ab,ac),den=aa*bb-cc*cc;
        const auto b=(bb*dot(ap,ab)-cc*dot(ap,ac))/den,c=(aa*dot(ap,ac)-cc*dot(ap,ab))/den;
        const auto uv=t.uvA*(1-b-c)+t.uvB*b+t.uvC*c;u=uv.x;v=uv.y;
    }
    return sample.sample(u,v,row.position.x,row.position.y,row.position.z);
}
void density(){
    const auto mesh=square();Settings s;s.distribution=2;s.count=3;s.densityWidth=s.densityHeight=2;s.density.assign(4,1.);
    const auto input=three(),array=boundary(mesh,s,input),image=boundary(mesh,nativeImage(s),input);
    sameRows(array,image,"original native-image/array Boundary regression differs");
    check(!same(array[0].position,input[0].position),"original regression must actually move");
    auto preferred=nativeImage(s);preferred.density={NAN};preferred.densityWidth=99;
    sameRows(array,boundary(mesh,preferred,input),"native image must retain precedence over legacy vector");
    unsigned cells=0;
    for(int coordinate=0;coordinate<3;++coordinate)for(int wrapping=0;wrapping<2;++wrapping)
    for(int relax=0;relax<4;++relax)for(int pixels=0;pixels<5;++pixels){
        s=Settings{}; // Keep each case independent of previous mapping state.
        s.distribution=2;s.count=100;s.densityWidth=s.densityHeight=4;s.density.resize(16);
        for(int y=0;y<4;++y)for(int x=0;x<4;++x)s.density[y*4+x]=pixels==0?0.:pixels==1?1.:
            pixels==2||pixels==4?x/3.:double((x+y)%2);
        auto& m=s.densityMapping;m.coordinates=static_cast<cyrus::density::Coordinates>(coordinate);m.wrapping=static_cast<cyrus::density::Wrapping>(wrapping);
        m.rotation=19;m.offsetX=-.13;m.offsetY=.07;m.repeatX=1.4;m.repeatY=.8;m.sizeX=.7;m.sizeY=1.7;
        m.worldToFrame={.8,.3,0,-.2,1.7,0,0,0,1,.1,-.2,0};if(pixels==4)m.curve={0,0,0,1};
        s.relaxEnabled=(relax&1)!=0;s.relaxSpacing=.13;s.relaxStrength=.4;s.relaxIterations=2;
        s.movement={{{-.03,.03},{-.03,.03},{.02,.02}}};
        auto a=scatter(mesh,s),b=scatter(mesh,nativeImage(s));sameRows(a,b,"image mapping/wrapping/Point Relax representation parity");
        if(relax&2){a=boundary(mesh,s,a);b=boundary(mesh,nativeImage(s),b);sameRows(a,b,"Boundary Relax representation parity");}
        for(const auto& row:a)check(sampled(mesh,s,row)>0,"density/Relax emitted a row in zero sampled support");
        if(pixels==0)check(a.empty(),"zero image admitted rows");
        if(pixels==1)check(a.size()==s.count,"positive constant density lost rows");
        ++cells;
    }
    // The endpoint is positive, but an existing intermediate path sample crosses
    // a zero stripe. The first candidate must stay at its preceding position.
    s=Settings{};s.distribution=2;s.densityWidth=257;s.densityHeight=1;s.density.assign(257,1);
    for(unsigned i=40;i<=60;++i)s.density[i]=0;
    auto path=three();path[1].position={.4,.1,0};path[2].position={.4,.2,0};
    FinalSettings f;f.radius=2;f.strength=1;f.maxMove=.5;f.iterations=1;
    auto crossed=boundary(mesh,nativeImage(s),path,f);check(same(crossed[0].position,path[0].position),"Boundary movement crossed zero image support");
    s.densityMapping.curve={0,0};sameRows(path,boundary(mesh,nativeImage(s),path,f),"zero response must block every move");
    s=Settings{};s.distribution=2;s.densityWidth=s.densityHeight=2;s.density.assign(4,1);s.count=10;
    auto noUV=mesh;for(auto& t:noUV)t.uvA=t.uvB=t.uvC={NAN,NAN,NAN};
    for(auto mode:{cyrus::density::Coordinates::World,cyrus::density::Coordinates::Local}){
        s.densityMapping.coordinates=mode;check(scatter(noUV,nativeImage(s)).size()==10,"World/Local must not consume UVs");
        check(boundary(noUV,nativeImage(s),input).size()==3,"Boundary World/Local must not consume UVs");
    }
    s.densityMapping.coordinates=cyrus::density::Coordinates::UV;
    rejects([&]{scatter(noUV,s);},"nonfinite UV accepted");
    auto invalid=nativeImage(s);auto bad=std::make_shared<cyrus::density::ImageData>();bad->width=bad->height=2;bad->pixels={1};invalid.densityImage=bad;
    invalid.density=s.density;invalid.densityWidth=invalid.densityHeight=2;
    rejects([&]{boundary(mesh,invalid,input);},"malformed preferred native image accepted");
    invalid=nativeImage(s);bad=std::make_shared<cyrus::density::ImageData>(*invalid.densityImage);bad->pixels[0]=NAN;invalid.densityImage=bad;
    rejects([&]{boundary(mesh,invalid,input);},"nonfinite image accepted");
    invalid=s;invalid.densityMapping.worldToFrame[0]=INFINITY;rejects([&]{boundary(mesh,invalid,input);},"nonfinite frame accepted");
    invalid=s;invalid.densityWidth=0;rejects([&]{boundary(mesh,invalid,input);},"zero image dimensions accepted");
    invalid=s;invalid.densityMapping.coordinates=cyrus::density::Coordinates::Map;
    rejects([&]{boundary(mesh,invalid,input);},"receiver Map incorrectly accepted as an image");
    invalid.distribution=0;check(boundary(mesh,invalid,input).size()==3,"host Map distribution-0 path changed");
    std::cout<<"density_cross_product_cells="<<cells<<"\n";
}

// Independent frozen exhaustive oracle: keep this arithmetic and strict '<'
// unchanged when modifying the production index or its traversal.
Vec3 oracleClosest(Vec3 p,const Triangle& t){
    const Vec3 ab=t.b-t.a,ac=t.c-t.a,ap=p-t.a;const double d1=dot(ab,ap),d2=dot(ac,ap);
    if(d1<=0&&d2<=0)return t.a;
    const Vec3 bp=p-t.b;const double d3=dot(ab,bp),d4=dot(ac,bp);if(d3>=0&&d4<=d3)return t.b;
    const double vc=d1*d4-d3*d2;if(vc<=0&&d1>=0&&d3<=0)return t.a+ab*(d1/(d1-d3));
    const Vec3 cp=p-t.c;const double d5=dot(ab,cp),d6=dot(ac,cp);if(d6>=0&&d5<=d6)return t.c;
    const double vb=d5*d2-d1*d6;if(vb<=0&&d2>=0&&d6<=0)return t.a+ac*(d2/(d2-d6));
    const double va=d3*d6-d5*d4;if(va<=0&&(d4-d3)>=0&&(d5-d6)>=0)return t.b+(t.c-t.b)*((d4-d3)/((d4-d3)+(d5-d6)));
    return t.a+ab*(vb/(va+vb+vc))+ac*(vc/(va+vb+vc));
}
std::pair<Vec3,std::uint32_t> exhaustive(const std::vector<Triangle>& mesh,const std::vector<std::uint32_t>& eligible,Vec3 p){
    Vec3 q{};std::uint32_t face=0;double best=INFINITY;
    for(auto id:eligible){const auto candidate=oracleClosest(p,mesh[id]);const auto delta=candidate-p;const auto d=dot(delta,delta);
        if(d<best){best=d;q=candidate;face=id;}}
    return {q,face};
}
void compare(const std::vector<Triangle>& mesh,const std::vector<std::uint32_t>& eligible,const std::vector<Vec3>& targets){
    ProjectionWorkBudget budget;
    {detail::ProjectedMovementIndex index(mesh,eligible,budget);for(auto p:targets){const auto actual=index.project(p),expected=exhaustive(mesh,eligible,p);
        check(actual.second==expected.second&&same(actual.first,expected.first),"indexed closest point/first eligible tie differs from exhaustive oracle");}}
    check(budget.currentScratchBytes==0,"index scratch retained after return");
}
std::vector<std::uint32_t> ordered(std::size_t n){std::vector<std::uint32_t> result(n);std::iota(result.begin(),result.end(),0u);return result;}
void projection(){
    std::mt19937 rng(173);std::uniform_real_distribution<double> value(-50,50);
    std::vector<Triangle> random;std::vector<Vec3> targets;
    for(unsigned i=0;i<257;++i){const Vec3 p{value(rng),value(rng),value(rng)};random.push_back({p,p+Vec3{1+std::abs(value(rng)),.2,.1},p+Vec3{.1,2+std::abs(value(rng)),.7}});}
    for(unsigned i=0;i<1000;++i)targets.push_back({value(rng),value(rng),value(rng)});
    auto ids=ordered(random.size());compare(random,ids,targets);std::shuffle(ids.begin(),ids.end(),rng);compare(random,ids,targets);
    auto duplicates=std::vector<Triangle>(70,square()[0]);ids=ordered(duplicates.size());std::rotate(ids.begin(),ids.begin()+43,ids.end());
    compare(duplicates,ids,{{.2,.2,0},{.5,.5,1},{0,0,0},{1,0,0},{.5,0,-1}});
    auto edges=strip(90);edges[1]=square()[1];compare(edges,ordered(edges.size()),{{.5,.5,1},{1,0,0},{0,0,0},{1,1,2}});
    auto symmetric=strip(80);symmetric[0]={{-1,0,0},{-1,1,0},{-1,0,1}};symmetric[79]={{1,0,0},{1,1,0},{1,0,1}};
    compare(symmetric,ordered(symmetric.size()),{{0,.2,.2},{0,0,0}});
    auto large=strip(70);for(auto& t:large)for(auto* p:{&t.a,&t.b,&t.c})*p=*p*1000+Vec3{1e12,-1e12,1e12};
    compare(large,ordered(large.size()),{{1e12+32350,-1e12+350,1e12+700},{1e12-100,-1e12,1e12}});
    auto degenerate=strip(40);degenerate.push_back({{0,0,0},{0,0,0},{0,0,0}});compare(degenerate,ordered(40),{{.1,.1,0},{30.2,2,1}});
    // Full ordered transforms/source choices remain identical to projecting the
    // free-movement control when normal alignment and density are independent.
    Settings s;s.count=2000;s.sourceCount=3;s.sourceWeights={.2,.7,1};s.alignToNormal=false;
    s.movement={{{-.4,.4},{-.2,.2},{-.3,.3}}};s.uniformScale={.7,1.4};s.axisScale={{{.8,1.1},{.6,1.3},{1,1.5}}};
    s.projectMovement=false;auto oracle=scatter(random,s);for(auto& row:oracle){auto q=exhaustive(random,ordered(random.size()),row.position);row.position=q.first;row.triangle=q.second;}
    s.projectMovement=true;sameRows(oracle,scatter(random,s),"full scatter RNG/transforms/source/candidate parity changed");
    const auto small=strip(16);ProjectionWorkBudget budget;budget.workLimit=800;s=Settings{};s.count=32;s.projectionBudget=&budget;s.movement[0]={.1,.1};
    const auto publication=scatter(small,s);auto retained=publication;
    rejects([&]{retained=scatter(small,s);},"per-receiver reset evaded shared work allowance");sameRows(publication,retained,"failed successor replaced publication");
    check(budget.currentScratchBytes==0,"query failure retained index scratch");
    budget=ProjectionWorkBudget{};s.distribution=2;s.densityWidth=s.densityHeight=1;s.density={0};
    check(scatter(small,s).empty()&&budget.queries==s.count&&budget.triangleTests==std::uint64_t(s.count)*small.size(),"rejected candidates escaped projection work charging");
    budget=ProjectionWorkBudget{};s.distribution=0;s.movement={};scatter(small,s);check(budget.workUsed==0&&budget.builds==0&&budget.peakScratchBytes==0,"no movement allocated an index");
    s.movement[0]={.1,.1};s.projectMovement=false;scatter(small,s);check(budget.workUsed==0,"projection disabled consumed projection work");
    s.projectMovement=true;s.count=0;scatter(small,s);check(budget.workUsed==0,"zero count built index");
    s.count=32;budget.scratchLimit=1;rejects([&]{scatter(random,s);},"scratch admission allowed oversized index");check(budget.currentScratchBytes==0,"failed admission leaked scratch");
    budget=ProjectionWorkBudget{};budget.workLimit=50;rejects([&]{scatter(random,s);},"index build escaped work allowance");check(budget.currentScratchBytes==0,"failed build leaked scratch");
    budget=ProjectionWorkBudget{};{detail::ProjectedMovementIndex index(random,ids=ordered(random.size()),budget);
        budget.workLimit=budget.workUsed+1;rejects([&]{index.project({0,0,0});},"query escaped work allowance");}
    check(budget.currentScratchBytes==0,"failed query leaked scratch");
    budget=ProjectionWorkBudget{};{detail::ProjectedMovementIndex index(random,ids,budget);rejects([&]{index.project({NAN,0,0});},"nonfinite target accepted");}
}
void geometry(){
    using namespace cyrus::receiver_mesh;
    storage(0,0,false,false,0);storage(3,1,true,true,1);
    rejects([&]{storage(-1,1,true,true,1);},"negative vertex count accepted");
    rejects([&]{storage(3,-1,true,true,1);},"negative face count accepted");
    rejects([&]{storage(3,1,false,true,1);},"missing vertex buffer accepted");
    rejects([&]{storage(3,1,true,false,1);},"missing face buffer accepted");
    rejects([&]{storage(3,2,true,true,1);},"face limit accepted");
    for(std::uint64_t bad:{3ULL,999999ULL,std::uint64_t(UINT32_MAX)})rejects([&]{index(bad,3,4,2);},"invalid geometry vertex index accepted");
    index(2,3,0,2);position(1,2,3,"vertex",0);
    rejects([&]{position(NAN,0,0,"vertex",0);},"nonfinite geometry accepted");
    rejects([&]{position(0,INFINITY,0,"transform",0);},"nonfinite transform accepted");
}
void benchmark(){
    using Clock=std::chrono::steady_clock;
    for(unsigned faces:{1000u,4000u,16000u}){
        const auto mesh=strip(faces);const auto ids=ordered(faces);Settings s;s.count=2000;s.uniformScale={1,1};s.projectMovement=false;s.movement[0]={.1,.1};
        const auto rows=scatter(mesh,s);std::vector<double> bruteTimes,indexTimes;std::uint64_t tests=0,peak=0;
        for(int run=0;run<3;++run){
            auto begin=Clock::now();std::vector<std::pair<Vec3,std::uint32_t>> expected;expected.reserve(rows.size());
            for(const auto& row:rows)expected.push_back(exhaustive(mesh,ids,row.position));
            const auto bruteMs=std::chrono::duration<double,std::milli>(Clock::now()-begin).count();bruteTimes.push_back(bruteMs);
            ProjectionWorkBudget budget;begin=Clock::now();
            {detail::ProjectedMovementIndex index(mesh,ids,budget);const auto built=Clock::now();
                for(std::size_t i=0;i<rows.size();++i){const auto actual=index.project(rows[i].position);check(actual.second==expected[i].second&&same(actual.first,expected[i].first),"dense fixture oracle mismatch");}
                const auto end=Clock::now();const auto buildMs=std::chrono::duration<double,std::milli>(built-begin).count();
                const auto queryMs=std::chrono::duration<double,std::milli>(end-built).count();indexTimes.push_back(buildMs+queryMs);
                std::cout<<"projection faces="<<faces<<" run="<<run<<" build_ms="<<buildMs<<" query_ms="<<queryMs<<" brute_ms="<<bruteMs
                    <<" build_units="<<budget.buildUnits<<" node_visits="<<budget.nodeVisits<<" triangle_tests="<<budget.triangleTests<<" peak_scratch="<<budget.peakScratchBytes<<"\n";
            }
            check(budget.currentScratchBytes==0,"benchmark retained index memory");tests=budget.triangleTests;peak=budget.peakScratchBytes;
        }
        std::sort(bruteTimes.begin(),bruteTimes.end());std::sort(indexTimes.begin(),indexTimes.end());
        if(faces==16000)check(tests<std::uint64_t(faces)*s.count/10,"dense fixture failed exact-triangle reduction gate");
        std::cout<<"projection_median faces="<<faces<<" exhaustive_ms="<<bruteTimes[1]<<" indexed_ms="<<indexTimes[1]<<" exact_reduction="<<double(faces)*s.count/tests<<" peak_scratch="<<peak<<"\n";
    }
}
}
int main(){try{density();projection();geometry();benchmark();std::cout<<"PASS: native density, receiver validation, deterministic indexed projection and shared bounds\n";}
catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}return 0;}

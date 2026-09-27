#include "scatter.h"
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace amin;
void check(bool yes,const char* message) { if(!yes) throw std::runtime_error(message); }
bool near(double a,double b) {return std::abs(a-b)<1e-9;}
template<class F> void rejects(F f) {bool rejected=false;try{f();}catch(const std::invalid_argument&){rejected=true;}check(rejected,"invalid input accepted");}
int main() {
  try {
    // Disjoint triangles with a 1:9 area ratio expose face-uniform sampling bugs.
    const std::vector<Triangle> surface{{{0,0,0},{1,0,0},{0,1,0}},{{10,0,0},{13,0,0},{10,3,0}}};
    Settings s; s.count=20000;s.sourceCount=3;
    const auto a=scatter(surface,s),b=scatter(surface,s);
    std::size_t small=0; std::array<int,3> sources{};
    for(std::size_t i=0;i<a.size();++i) {
      const auto& v=a[i]; if(v.triangle==0) ++small;
      check(near(v.position.x,b[i].position.x)&&near(v.xAxis.y,b[i].xAxis.y)&&v.source==b[i].source,"seed not repeatable");
      check(near(v.position.z,0),"left surface");
      const double ox=v.triangle==0?0:10, extent=v.triangle==0?1:3;
      check(v.position.x>=ox&&v.position.y>=0&&(v.position.x-ox)+v.position.y<=extent+1e-9,"outside triangle");
      check(near(length(v.xAxis),1)&&near(length(v.yAxis),1)&&near(dot(v.xAxis,v.yAxis),0),"invalid frame");
      check(v.scale>=0.8&&v.scale<=1.2&&v.source<3,"random range failure"); ++sources[v.source];
    }
    check(small>1700&&small<2300,"area-weighted distribution failure");
    for(int n:sources) check(n>6000&&n<7300,"source distribution failure");
    s.count=100;const auto prefix=scatter(surface,s);check(near(prefix.back().position.x,a[99].position.x),"count changes earlier placements");
    s.rotationDegrees[2]={45,45}; const auto rotated=scatter(surface,s);
    check(near(rotated[0].position.x,prefix[0].position.x),"rotation changes positions");
    s.movement={{{-2,2},{-2,2},{-2,2}}};const auto moved=scatter(surface,s);
    for(const auto& v:moved) check(near(v.position.z,0),"movement not projected");
    s.movement={};s.rotationDegrees={};
    const auto tilted=scatter({{{0,0,0},{1,0,0},{0,1,1}}},s);
    check(near(tilted[0].zAxis.z,std::sqrt(0.5))&&near(tilted[0].position.y,tilted[0].position.z),"normal alignment failure");
    const auto samples=sampleSource(surface,80,7);
    const auto cloud=pointCloud(prefix,{samples,samples,samples},123);
    check(cloud.size()==123,"preview budget ignored");
    check(pointCloud(prefix,{samples,samples,samples},0).empty(),"zero preview budget ignored");
    check(pointCloud({}, {},100).empty(),"empty preview failure");
    Instance identity{{5,6,7},{1,0,0},{0,1,0},{0,0,1},2,0,0};
    const auto point=pointCloud({identity},{{{1,2,3}}},10)[0].position;
    check(near(point.x,7)&&near(point.y,10)&&near(point.z,13),"preview transform failure");
    rejects([&]{scatter({},s);});
    rejects([&]{scatter({{{0,0,0},{0,0,0},{0,0,0}}},s);});
    rejects([&]{pointCloud(prefix,{},10);});
    s.uniformScale={-1,1};rejects([&]{scatter(surface,s);});
    Settings advanced;advanced.count=2000;advanced.sourceCount=3;advanced.uniformScale={1,1};
    advanced.axisScale={{{2,2},{3,3},{4,4}}};advanced.rotationDegrees={};
    advanced.movement={{{0,0},{0,0},{5,5}}};advanced.projectMovement=false;
    auto xyz=scatter(surface,advanced);
    check(near(length(xyz[0].xAxis),2)&&near(length(xyz[0].yAxis),3)&&near(length(xyz[0].zAxis),4)&&near(xyz[0].position.z,5),"independent XYZ scale or free movement failed");
    advanced.movement={};advanced.distribution=1;advanced.clusterCount=1;advanced.clusterRadius=0.2;
    const std::vector<Triangle> square{{{0,0,0},{1,0,0},{0,1,0},{0,0,0},{1,0,0},{0,1,0}},{{1,0,0},{1,1,0},{0,1,0},{1,0,0},{1,1,0},{0,1,0}}};
    advanced.distribution=2;advanced.densityWidth=advanced.densityHeight=4;advanced.density.assign(16,0);
    check(scatter(square,advanced).empty(),"black texture produced points");
    advanced.density.assign(16,1);check(scatter(square,advanced).size()==2000,"white texture dropped points");
    for(int y=0;y<4;++y) for(int x=0;x<4;++x) advanced.density[y*4+x]=x<2?0:1;
    const auto masked=scatter(square,advanced);check(masked.size()==2000,"mask did not fill");
    double meanX=0;for(const auto& v:masked) {check(v.position.x>1.0/3,"point in zero-density UV region");meanX+=v.position.x;}
    check(meanX/masked.size()>0.68,"UV density bias missing");
    Settings grouped;grouped.count=2000;grouped.sourceCount=9;grouped.clusterSize=0.15;
    grouped.sourceGroups={0xff0000,0xff0000,0xff0000,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x0000ff};
    grouped.rotationDegrees={{{-20,20},{-30,30},{0,360}}};
    grouped.axisScale={{{0.5,2},{0.7,3},{1,4}}};
    grouped.movement={{{-0.01,0.01},{-0.01,0.01},{-0.01,0.01}}};
    auto sameVec=[](Vec3 a,Vec3 b){return a.x==b.x&&a.y==b.y&&a.z==b.z;};
    for(int mode: {0,2}) for(bool project: {false,true}) {
      grouped.distribution=mode;grouped.projectMovement=project;
      grouped.densityWidth=grouped.densityHeight=4;grouped.density=advanced.density;
      grouped.clusterEnabled=false;const auto baseline=scatter(square,grouped);
      grouped.clusterEnabled=true;
      for(int variation=0;variation<4;++variation) {
        grouped.clusterSize=0.08+variation*0.07;grouped.clusterSeed=42+variation;
        grouped.clusterRoughness=variation*0.2;grouped.clusterBlur=variation*0.2;grouped.clusterNoise=variation*0.1;
        const auto clustered=scatter(square,grouped),again=scatter(square,grouped);
        check(clustered.size()==baseline.size(),"diversity changed point count");
        int changed=0;std::array<int,9> seen{};
        for(std::size_t i=0;i<clustered.size();++i) {
          const auto& a=baseline[i];const auto& b=clustered[i];
          check(sameVec(a.position,b.position)&&sameVec(a.xAxis,b.xAxis)&&sameVec(a.yAxis,b.yAxis)&&sameVec(a.zAxis,b.zAxis)&&a.scale==b.scale&&a.triangle==b.triangle,"diversity changed transform");
          check(b.source==again[i].source,"diversity not repeatable");
          changed+=a.source!=b.source;++seen[b.source];
        }
        check(changed>500,"diversity did not change source assignments");
        for(int count:seen) check(count>0,"missing group member");
      }
    }
    // Nearby placements should share groups more often than uncorrelated choices.
    grouped.distribution=0;grouped.clusterSize=0.2;grouped.clusterRoughness=0.3;
    grouped.clusterBlur=grouped.clusterNoise=0;grouped.movement={};
    const auto coherent=scatter(square,grouped);
    int pairs=0,same=0;
    for(std::size_t i=0;i<coherent.size();++i) for(std::size_t j=i+1;j<coherent.size();++j) {
      if(length(coherent[i].position-coherent[j].position)<0.015) {
        ++pairs;same+=grouped.sourceGroups[coherent[i].source]==grouped.sourceGroups[coherent[j].source];
      }
    }
    check(pairs>100&&same>pairs*0.8,"color groups lack spatial coherence");
    grouped.sourceGroups.pop_back();rejects([&]{scatter(square,grouped);});
    Settings areas;areas.count=1000;areas.sourceCount=1;
    Area left{{{{0,0,0},{0.7,0,0},{0.7,1,0},{0,1,0}}},true};
    Area cut{{{{0.2,0.2,0},{0.5,0.2,0},{0.5,0.8,0},{0.2,0.8,0}}},false};
    areas.areas={left,cut};auto clipped=scatter(square,areas);
    check(clipped.size()==1000,"area didn't fill target");
    for(auto v:clipped) check(v.position.x<=0.7 && !(v.position.x>=0.2&&v.position.x<=0.5&&v.position.y>=0.2&&v.position.y<=0.8),"include/exclude violation");
    areas.movement={{{0.2,0.2},{0,0},{0,0}}};areas.projectMovement=false;
    for(auto v:scatter(square,areas)) check(v.position.x<=0.7,"movement escaped area");
    areas.movement={};areas.areas={cut};check(scatter(square,areas).size()==1000,"exclude-only failed");
    Area right{{{{0.8,0,0},{1,0,0},{1,1,0},{0.8,1,0}}},true};areas.areas={left,right};
    for(auto v:scatter(square,areas)) check(v.position.x<=0.7||v.position.x>=0.8,"include union failed");
    areas.areas={Area{{{{0,0,0},{1,0,0},{1,1,0},{0,1,0}}},false}};
    check(scatter(square,areas).empty(),"full exclusion produced plants");
    left.loops.push_back(cut.loops[0]);areas.areas={left};
    for(auto v:scatter(square,areas)) check(!(v.position.x>0.2&&v.position.x<0.5&&v.position.y>0.2&&v.position.y<0.8),"compound shape hole failed");
    areas.areas={Area{{{{0,0,0},{1,0,0},{2,0,0}}},true}};rejects([&]{scatter(square,areas);});
    areas.areas={Area{{{{0,0,0},{0.5,0,0},{0.5,1,0},{0,1,0}}},true}};
    areas.preserveDensity=true;areas.count=10000;
    auto population=scatter(square,areas);
    check(population.size()>4700&&population.size()<5300,"area changed density by refilling points");
    areas.areas.clear();areas.distribution=2;areas.densityWidth=areas.densityHeight=2;areas.density.assign(4,0.5);
    population=scatter(square,areas);
    check(population.size()>4700&&population.size()<5300,"density texture refilled rejected points");
    areas.count=0;check(scatter(square,areas).empty(),"zero population not supported");
    const std::vector<Triangle> field{{{-5,-5,0},{5,-5,0},{5,5,0}},{{-5,-5,0},{5,5,0},{-5,5,0}}};
    Settings line;line.count=10000;line.sourceCount=3;line.sourceGroups={10,20,20};
    auto original=scatter(field,line);
    line.linePattern=true;line.restGroup=10;
    Area boundary;boundary.loops={{{-1,-1,0},{1,-1,0},{1,1,0},{-1,1,0}}};
    line.lineBands.push_back({boundary,1,20});
    auto banded=scatter(field,line);int member1=0,member2=0;
    const auto distance=[](Vec3 p) {return std::hypot(std::max(0.0,std::abs(p.x)-1),std::max(0.0,std::abs(p.y)-1));};
    std::size_t next=0;
    for(const auto& baseline:original) {
        const double d=distance(baseline.position);
        if(d>0&&d<=1) {
            check(next<banded.size(),"missing stroke candidate");const auto& v=banded[next++];
            check(length(v.position-baseline.position)<1e-12&&length(v.xAxis-baseline.xAxis)<1e-12&&near(v.scale,baseline.scale),"stroke filtering changed placement or transform");
            check(v.source==1||v.source==2,"stroke source invalid");if(v.source==1)++member1;else ++member2;
        }
    }
    check(next==banded.size()&&member1>400&&member2>400,"outside stroke points leaked or members missing");
    line.lineBands.push_back({boundary,2,10});
    line.lineBands[0].sources={1,2};line.lineBands[0].scaleMin=1.25;line.lineBands[0].scaleMax=1.75;
    line.lineBands[1].sources={0};line.lineBands[1].scaleMin=line.lineBands[1].scaleMax=2;
    auto strokes=scatter(field,line);next=0;int outer=0;
    for(const auto& baseline:original) {
        const double d=distance(baseline.position);
        if(d>0&&d<=2) {
            check(next<strokes.size(),"missing outer stroke");const auto& v=strokes[next++];
            check(length(v.position-baseline.position)<1e-12,"stroke scale moved placements");
            if(d<=1) check(v.source!=0&&v.scale/baseline.scale>=1.25&&v.scale/baseline.scale<=1.75,"inner stroke assignment or scale");
            else {++outer;check(v.source==0&&near(v.scale/baseline.scale,2),"outer stroke assignment or scale");}
        }
    }
    check(next==strokes.size()&&outer>500,"outside final stroke leaked");
    line.restGroup=99;check(scatter(field,line).size()==strokes.size(),"legacy rest group still affects output");
    line.lineBands[0].sources={99};rejects([&]{scatter(field,line);});line.lineBands[0].sources={1};
    line.lineBands[0].scaleMin=0;rejects([&]{scatter(field,line);});line.lineBands[0].scaleMin=1;
    line.lineBands[0].scaleMax=0.5;rejects([&]{scatter(field,line);});line.lineBands[0].scaleMax=1;
    line.lineBands[0].width=0;rejects([&]{scatter(field,line);});
    line.lineBands.clear();check(scatter(field,line).empty(),"no strokes must produce zero objects");
    Settings sides;sides.count=10000;sides.sourceCount=3;sides.sourceGroups={10,20,30};sides.linePattern=true;
    LineBand outerBand{boundary,0.5,10};
    LineBand innerBand{boundary,0.25,20};innerBand.inside=true;
    LineBand innerNext{boundary,0.6,30};innerNext.inside=true;
    sides.lineBands={outerBand,innerBand,innerNext};
    auto both=scatter(field,sides);std::array<int,3> sideCounts{};
    for(const auto& v:both) {
        const auto p=v.position;const double inward=1-std::max(std::abs(p.x),std::abs(p.y));
        if(inward>=0) {
            check(inward<=0.6,"inside stroke leaked into center");
            check(v.source==(inward<=0.25?1u:2u),"inside cumulative priority");
        } else check(distance(p)<=0.5&&v.source==0,"outside stroke assignment");
        ++sideCounts[v.source];
    }
    check(sideCounts[0]>100&&sideCounts[1]>100&&sideCounts[2]>100,"missing inside/outside band");
    for(auto& band:sides.lineBands) std::reverse(band.boundary.loops[0].begin(),band.boundary.loops[0].end());
    auto reversed=scatter(field,sides);check(reversed.size()==both.size(),"winding changed stroke side");
    for(std::size_t i=0;i<both.size();++i) check(reversed[i].source==both[i].source&&length(reversed[i].position-both[i].position)<1e-12,"winding changed stroke assignment");
    Settings analysis;analysis.count=10000;analysis.sourceCount=2;analysis.linePattern=true;
    LineBand center;center.kind=3;center.width=.25;center.sources={0};center.boundary.loops={{{-2,0,0},{2,0,0}}};
    LineBand nextBand=center;nextBand.start=.25;nextBand.width=.5;nextBand.sources={1};
    analysis.lineBands={center,nextBand};auto centered=scatter(field,analysis);int sideNegative=0,sidePositive=0;
    for(const auto& v:centered) {const double d=std::hypot(std::max(0.0,std::abs(v.position.x)-2),v.position.y);check(d<=.5,"center spread leaked");check(v.source==(d<.25?0u:1u),"center cumulative source");if(v.position.y<0)++sideNegative;else++sidePositive;}
    check(sideNegative>100&&sidePositive>100,"center is not bilateral");
    LineBand patch;patch.kind=4;patch.width=.4;patch.sources={1};patch.boundary.loops={{{0,0,0}}};analysis.lineBands={patch};
    for(const auto& v:scatter(field,analysis)) check(length(v.position)<=.4&&v.source==1,"radius leaked");
    patch.kind=5;patch.boundary.loops={{{0,0,0},{.5,.5,0},{100,100,0}}};analysis.lineBands={patch};analysis.count=0;
    auto singles=scatter(field,analysis);check(singles.size()==2,"single anchors ignored surface membership/count independence");
    check(length(singles[0].position)<1e-10&&length(singles[1].position-Vec3{.5,.5,0})<1e-10,"single anchor moved");
    analysis.count=10000;outerBand.kind=1;innerBand.kind=2;outerBand.sources={0};innerBand.sources={1};analysis.lineBands={outerBand,innerBand};
    auto analyzedBorder=scatter(field,analysis);check(!analyzedBorder.empty(),"Analyzer border empty");
    for(const auto& v:analyzedBorder) {const double d=1-std::max(std::abs(v.position.x),std::abs(v.position.y));check(v.source==(d>=0?1u:0u),"Analyzer border side");}
    auto verticalField=field;for(auto& t:verticalField) for(auto* p:{&t.a,&t.b,&t.c}) std::swap(p->y,p->z);
    for(auto& band:analysis.lineBands) for(auto& path:band.boundary.loops) for(auto& p:path) std::swap(p.y,p.z);
    auto verticalBorder=scatter(verticalField,analysis);check(verticalBorder.size()==analyzedBorder.size(),"Tilt changed Analyzer border");
    for(std::size_t i=0;i<verticalBorder.size();++i) check(verticalBorder[i].source==analyzedBorder[i].source,"Tilt changed border assignment");
    std::cout<<"PASS: existing scatter tests plus Analyzer bilateral bands, radius, single anchors and border sides\n";
    Settings ends;ends.count=10000;ends.sourceCount=1;ends.linePattern=true;
    LineBand street;street.kind=2;street.width=.5;street.sources={0};
    street.boundary.loops={{{0,-1,0},{2,-1,0},{2,2,0},{-1,2,0},{-1,1,0},{0,1,0}}};
    street.boundaryMask={false,false,false,false,false,true};ends.lineBands={street};
    auto round=scatter(field,ends);ends.lineBands[0].straightEnds=true;auto straight=scatter(field,ends);
    check(!straight.empty()&&round.size()>straight.size(),"Straight cap did not remove rounded extension");
    for(const auto& p:straight)check(p.position.y>=-1&&p.position.y<=1&&p.position.x>=0&&p.position.x<=.5,"Straight rectangle bounds");
    for(auto& path:ends.lineBands[0].boundary.loops)for(auto& p:path)std::swap(p.y,p.z);
    auto straightTilt=scatter(verticalField,ends);check(straightTilt.size()==straight.size(),"Tilt changed straight cap");
    std::cout<<"PASS: straight Street rectangle, round extension and rotated plane\n";
    std::vector<Instance> finalInput;
    for(int y=0;y<3;++y)for(int x=0;x<3;++x)finalInput.push_back({{x*.2,y*.2,0},{1,0,0},{0,1,0},{0,0,1},1,0,0});
    finalInput.push_back({{2,2,0},{1,0,0},{0,1,0},{0,0,1},1,0,0});
    Settings domain;FinalSettings finish;finish.cleanup=true;finish.radius=.3;finish.minNeighbors=2;finish.minIsland=5;
    auto cleaned=finalize(field,domain,finalInput,{},std::vector<double>(10,0),{},finish);
    check(cleaned.size()==9,"Cleanup isolated point failed");for(std::size_t i=0;i<9;++i)check(length(cleaned[i].position-finalInput[i].position)==0,"Cleanup moved a survivor");
    finish.cleanup=false;finish.relax=true;finish.maxMove=.05;finish.strength=.3;finish.iterations=5;
    auto smoothed=finalize(field,domain,cleaned,{},std::vector<double>(9,0),{},finish);check(smoothed.size()==9,"Boundary relax deleted points");
    int movedFinal=0;for(std::size_t i=0;i<9;++i){double d=length(smoothed[i].position-cleaned[i].position);check(d<=.050001,"Final movement exceeded total cap");if(d>1e-8)++movedFinal;check(smoothed[i].source==cleaned[i].source,"Final changed source");}check(movedFinal>0,"Boundary relax did not move");
    auto repeat=finalize(field,domain,cleaned,{},std::vector<double>(9,0),{},finish);for(std::size_t i=0;i<9;++i)check(length(repeat[i].position-smoothed[i].position)<1e-12,"Final nondeterministic");
    std::vector<Instance> obstacle={{{-.1,0,0},{1,0,0},{0,1,0},{0,0,1},1,0,0}};
    auto constrained=finalize(field,domain,cleaned,obstacle,std::vector<double>(9,0),{.1},finish);
    for(auto p:constrained)check(length(p.position-obstacle[0].position)>=.1-1e-9,"Final crossed blocker");
    std::cout<<"PASS: final cleanup and count-preserving constrained boundary movement\n";
    return 0;
  } catch(const std::exception& e) { std::cerr<<e.what()<<'\n';return 1; }
}







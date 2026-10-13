#include "spline_bands.h"
#include "procedural.h"
using cyrus::procedural::transformedBounds;
#include "clipper2/clipper.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <map>
#include <random>
#include <stdexcept>

using namespace cyrus::bands;
namespace {
int assertions=0;
void check(bool ok,const char* message) { ++assertions;if(!ok)throw std::runtime_error(message); }
template<class F> void denied(F&& action,const char* message) { bool failed=false;try{action();}catch(const std::exception&){failed=true;}check(failed,message); }
Path box(Join join=Join::Rounded) { return {1,{{{{0,0,0},{100,0,0},{100,100,0},{0,100,0}}},true},join}; }
Band band(std::uint64_t id,double start,double end,double strength=1) {
    Band b;b.id=id;b.path=1;b.start=start;b.end=end;b.strength=strength;b.sources={{std::to_string(id),std::uint32_t(id-1),1,false}};return b;
}
void rangeAndDensity() {
    auto a=band(1,0,10),gap=band(2,10,35),c=band(3,35,135);gap.sources.clear();
    Field consecutive({box()},{a,gap,c},Arrangement::Consecutive);
    check(consecutive.select({105,50,0},.5,.5,.5,.5).band==1,"First interval");
    check(!consecutive.select({120,50,0},.5,.5,.5,.5).emitted,"Empty middle interval was filled");
    check(consecutive.select({150,50,0},.5,.5,.5,.5).band==3,"Successor interval lost");
    check(consecutive.select({110,50,0},.5,.5,.5,.5).band==1,"Consecutive shared endpoint must select nearer interval");
    check(!consecutive.select({100,50,0},.5,.5,.5,.5).emitted,"Outside includes original boundary");
    auto inside=a;inside.inside=true;Field inward({box()},{inside},Arrangement::Consecutive);
    check(inward.select({100,50,0},.5,.5,.5,.5).emitted,"Inside excludes original boundary");
    auto b=band(2,0,40,.25);Field overlap({box()},{a,b},Arrangement::Independent);
    const auto f=overlap.inspect({105,50,0});check(f.contributions.size()==2&&f.occupancy==1,"Combined saturated field");
    check(overlap.select({105,50,0},.9,.799999,.5,.5).band==1,"Sphere saturation share");
    check(overlap.select({105,50,0},.9,.8,.5,.5).band==2,"Box saturation share");
    check(overlap.select({120,50,0},.24999,.5,.5,.5).emitted,"Sparse continuation lost");
    check(!overlap.select({120,50,0},.25,.5,.5,.5).emitted,"Sparse continuation refilled");
    Field reordered({box()},{b,a},Arrangement::Independent);
    std::mt19937 random(91);std::size_t sphere=0,boxes=0;
    const auto unit=[&] {return double(random())/4294967296.;};
    for(int i=0;i<100000;++i) {
        const double x=unit(),y=unit(),z=unit(),w=unit();const auto first=overlap.select({105,50,0},x,y,z,w),second=reordered.select({105,50,0},x,y,z,w);
        check(first.band==second.band&&first.source==second.source&&first.scale==second.scale,"Independent order changed recipe");
        if(first.band==1)++sphere;else if(first.band==2)++boxes;
    }
    check(std::abs(double(sphere)-80000)<5*std::sqrt(100000*.8*.2)+1,"Sphere empirical probability");
    check(sphere+boxes==100000,"Saturated occupancy lost");
    a.strength=.4;b.strength=.1;Field partial({box()},{a,b},Arrangement::Independent);
    check(partial.inspect({105,50,0}).occupancy==.5,"Unsaturated occupancy");
    check(!partial.select({105,50,0},.5,0,0,0).emitted,"Occupancy equality must reject");
    a.sources.push_back({"9",4,1,true});a.strength=1;Field empty({box()},{a},Arrangement::Independent);
    const auto e=empty.select({105,50,0},0,0,.5,0);check(!e.emitted&&e.band==1&&e.sourceId=="9","Empty source probability reassigned");
    a.curve={0,1};Field ramp({box()},{a},Arrangement::Independent);
    check(std::abs(ramp.inspect({105,50,0}).occupancy-.5)<1e-12,"Rounded ramp progress");
    denied([&]{empty.select({105,50,0},1,0,0,0);},"Invalid variate admitted");
}
void nativeIntervalsAndOwners() {
    using namespace amin;
    const std::vector<Triangle> surface={{{100,1,0},{150,1,0},{150,99,0}},{{100,1,0},{150,99,0},{100,99,0}}};
    Settings settings;settings.count=20000;settings.sourceCount=1;settings.sourceWeights={1};
    const auto candidates=scatter(surface,settings);
    std::vector<Band> authored;
    for(unsigned i=0;i<3;++i){auto item=band(100+i,i==0?0:(i==1?10:35),i==0?10:(i==1?35:50));item.sources={{"model",0,1,false}};if(i==1)item.sources.clear();authored.push_back(item);}
    settings.splineField=std::make_shared<Field>(std::vector<cyrus::bands::Path>{box()},authored,Arrangement::Consecutive);
    const auto rows=scatter(surface,settings);check(!rows.empty(),"Native interval fixture empty");
    for(const auto& row:rows){const double distance=row.position.x-100;check(distance<=10||distance>=35,"Native empty middle band collapsed");check(row.bandOwner==(distance<=10?100u:102u),"Native Band provenance wrong");}
    const auto cloud=pointCloud(rows,{{{0,0,0}}},500);for(const auto& point:cloud)check(point.bandOwner==(point.position.x<=110?100u:102u),"Point Cloud lost Band owner");
    BoundaryFalloff fall;fall.scale=true;fall.scaleCurve={1,2};fall.scaleWidth=100;
    const auto transformed=boundaryFalloff(rows,box().area.loops,fall,42);for(std::size_t i=0;i<rows.size();++i)check(rows[i].bandOwner==transformed[i].bandOwner,"Falloff lost Band owner");
    // An explicitly empty first path wins before a later intersecting path.
    auto empty=authored[0];empty.sources.clear();empty.start=0;empty.end=50;
    auto filled=empty;filled.id=200;filled.path=2;filled.sources={{"model",0,1,false}};
    auto secondPath=box();secondPath.id=2;
    settings.splineField=std::make_shared<Field>(std::vector<cyrus::bands::Path>{box(),secondPath},std::vector<Band>{empty,filled},Arrangement::Consecutive);
    check(scatter(surface,settings).empty(),"Empty global winner fell through");
    // Compare the prepared field to the independent unfiltered candidate stream,
    // using this rectangle's analytic support rather than a second sampler.
    authored.clear();for(unsigned i=0;i<3;++i){auto item=band(100+i,i*15,(i+1)*15);item.sources={{"model",0,1,false}};authored.push_back(item);}
    settings.splineField=std::make_shared<Field>(std::vector<cyrus::bands::Path>{box()},authored,Arrangement::Consecutive);
    const auto after=scatter(surface,settings);
    const auto expected=std::count_if(candidates.begin(),candidates.end(),[](const Instance& row){return row.position.x<=145;});
    check(after.size()==static_cast<std::size_t>(expected),"Analytic consecutive support changed population");
    for(const auto& row:after){const auto& raw=candidates.at(row.candidateKey);check(length(raw.position-row.position)==0&&length(raw.xAxis-row.xAxis)==0&&length(raw.yAxis-row.yAxis)==0&&length(raw.zAxis-row.zAxis)==0&&raw.scale==row.scale&&raw.source==row.source,"Field filtering changed a candidate transform");}
}
void preparedGenerationAndMovement() {
    using namespace amin;
    const std::vector<Triangle> surface={{{100,1,0},{140,1,0},{140,99,0}},{{100,1,0},{140,99,0},{100,99,0}}};
    auto sphere=band(1,0,10),boxes=band(2,0,40,.25);
    sphere.scale={.5,1.5};boxes.scale={1,2};
    sphere.sources[0].id="source-sphere";boxes.sources[0].id="source-box";
    Settings s;s.sourceCount=2;s.count=60000;s.receiverSalt=1921;s.uniformScale={1,1};
    s.splineField=std::make_shared<Field>(std::vector<cyrus::bands::Path>{box()},std::vector<Band>{sphere,boxes},Arrangement::Independent);
    const auto rows=scatter(surface,s);
    std::size_t inner=0,outer=0,innerBox=0;
    std::map<std::uint64_t,Instance> original;
    for(const auto& row:rows){
        original.emplace(row.candidateKey,row);
        if(row.position.x<=110){++inner;innerBox+=row.source==1;}else ++outer;
        const auto decision=s.splineField->sample(row.position,s.seed,row.candidateKey,s.receiverSalt);
        check(decision.emitted&&decision.band==row.bandOwner&&decision.source==row.source&&decision.scale==row.scale,"Generation did not use candidate field variates");
    }
    check(std::abs(double(inner)-15000)<600&&std::abs(double(outer)-11250)<600,"Shared population occupancy is wrong");
    check(std::abs(double(innerBox)/inner-.2)<.02,"Overlap mixture is wrong");
    const auto same=[](const Instance& a,const Instance& b){return a.candidateKey==b.candidateKey&&a.bandOwner==b.bandOwner&&a.source==b.source&&a.scale==b.scale&&length(a.position-b.position)==0&&length(a.xAxis-b.xAxis)==0&&length(a.yAxis-b.yAxis)==0&&length(a.zAxis-b.zAxis)==0;};
    s.count=10000;const auto prefix=scatter(surface,s);
    for(const auto& row:prefix)check(same(row,original.at(row.candidateKey)),"Larger candidate budget moved an existing placement");
    s.splineField=std::make_shared<Field>(std::vector<cyrus::bands::Path>{box()},std::vector<Band>{boxes,sphere},Arrangement::Independent);
    const auto reordered=scatter(surface,s);check(prefix.size()==reordered.size(),"Independent reorder changed population");
    for(std::size_t i=0;i<prefix.size();++i)check(same(prefix[i],reordered[i]),"Independent reorder changed full transform/identity");
    s.receiverSalt=1922;const auto otherReceiver=scatter(surface,s);
    check(!otherReceiver.empty()&&length(prefix.front().position-otherReceiver.front().position)>0,"Receiver populations share placements");
    s.receiverSalt=1921;s.count=1200;s.relaxEnabled=true;s.relaxSpacing=3;s.relaxIterations=3;s.relaxStrength=.7;
    const auto relaxed=scatter(surface,s);
    for(const auto& row:relaxed){const auto d=s.splineField->sample(row.position,s.seed,row.candidateKey,s.receiverSalt);check(d.emitted&&d.band==row.bandOwner&&d.source==row.source,"Relax rerolled occupancy, owner or source");}
    s.relaxEnabled=false;const auto before=scatter(surface,s);FinalSettings f;f.relax=true;f.radius=10;f.maxMove=2;f.strength=.8;f.iterations=3;
    const auto after=finalize(surface,s,before,{},std::vector<double>(before.size(),0),{},f);
    check(after.size()==before.size(),"Final movement changed field population");
    std::size_t moved=0;
    for(std::size_t i=0;i<after.size();++i){const auto& row=after[i];const auto d=s.splineField->sample(row.position,s.seed,row.candidateKey,s.receiverSalt);check(d.emitted&&d.band==before[i].bandOwner&&d.source==before[i].source&&row.scale==before[i].scale,"Final movement rerolled field recipe");moved+=length(row.position-before[i].position)>0;}
    check(moved>0,"Final movement fixture exercised no moves");
    s.sourceCount=1;denied([&]{scatter(surface,s);},"Out-of-range prepared source accepted");
    s.sourceCount=2;s.analyzerPattern=true;denied([&]{scatter(surface,s);},"Mixed ordinary and Analyzer fields accepted");
}
void sharpOracles() {
    auto b=band(1,0,40);b.curve={0,1};const auto started=std::chrono::steady_clock::now();
    Field field({box(Join::Sharp)},{b},Arrangement::Independent);
    double worst=0;std::size_t visits=0;
    // Analytic rectangle miter levels are [-q,100+q]^2. In the corner q is
    // max(dx,dy), not Euclidean distance; this oracle does not call Clipper.
    for(int i=1;i<=97;++i)for(int j=1;j<=89;++j) {
        const double x=40.*i/98,y=40.*j/90,expected=std::max(x,y)/40;
        const auto query=field.inspect({100+x,100+y,8});check(query.contributions.size()==1,"Sharp corner clipped");
        const auto& c=query.contributions[0];worst=std::max(worst,std::abs(c.progress-expected));visits+=query.visits;
        check(std::abs(c.progress-expected)<=1./256,"Sharp rectangle progress oracle");
        check(std::abs(c.value-expected)<=.005,"Sharp rectangle density oracle");
    }
    // Inward collapse is successful geometry, never an undefined end distance.
    b.inside=true;b.end=80;Field inside({box(Join::Sharp)},{b},Arrangement::Independent);
    const auto center=inside.inspect({50,50,0});check(center.contributions.size()==1,"Collapsed end erased the inner band");
    check(std::abs(center.contributions[0].progress-50./80)<=1./256,"Collapse progress oracle");
    b.start=60;Field collapsed({box(Join::Sharp)},{b},Arrangement::Independent);
    check(collapsed.inspect({50,50,0}).contributions.empty(),"Collapsed start emits");
    // Same physical shape far from origin; coordinates conditioned before packing.
    auto far=box(Join::Sharp);for(auto& p:far.area.loops[0]){p.x+=1e9;p.y-=1e9;}b=band(1,0,40);b.curve={0,1};
    Field translated({far},{b},Arrangement::Independent);
    check(std::abs(translated.inspect({1e9+120,-1e9+115,0}).occupancy-.5)<.005,"Origin changed field");
    // Actual contour uncertainty at a cached intermediate level must widen the
    // bracket and still satisfy accuracy; it cannot be silently branched away.
    check(std::abs(field.inspect({120,110,0}).occupancy-.5)<=.005,"Intermediate contour uncertainty");
    std::vector<Band> many;
    for(std::uint64_t id=1;id<=32;++id){auto item=band(id,0,40,.03);item.curve={0,1};many.push_back(item);}
    Field aggregate({box(Join::Sharp)},many,Arrangement::Independent);
    const auto combined=aggregate.inspect({120,110,0});check(std::abs(combined.occupancy-.48)<=.005,"Aggregate density budget");
    check(combined.error<=.005,"Aggregate certified error");
    auto limits=Limits{};limits.levels=32;
    denied([&]{Field deniedField({box(Join::Sharp)},{b},Arrangement::Independent,limits);},"Level overflow admitted");
    limits=Limits{};limits.vertices=20;
    denied([&]{Field deniedField({box(Join::Sharp)},{b},Arrangement::Independent,limits);},"Vertex overflow admitted");
    limits=Limits{};limits.queryVisits=2;Field queryLimit({box()},{b},Arrangement::Independent,limits);
    denied([&]{queryLimit.inspect({120,50,0});},"Query work overflow admitted");
    std::cout<<"Sharp rectangle: max progress error="<<worst<<", levels="<<field.stats().levels<<", vertices="<<field.stats().vertices<<", prepared bytes="<<field.stats().bytes<<", query visits="<<visits<<", experiment ms="<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-started).count()<<'\n';
}
void geometryAndRadii() {
    auto p=box(Join::Sharp);p.area.loops.push_back({{40,40,0},{60,40,0},{60,60,0},{40,60,0}});
    auto b=band(1,0,8);Field hole({p},{b},Arrangement::Independent);
    check(hole.select({43,50,0},0,0,0,0).emitted,"EvenOdd hole outside support lost");
    check(!hole.select({50,50,0},0,0,0,0).emitted,"Hole core incorrectly filled");
    b.inside=true;Field holeInside({p},{b},Arrangement::Independent);
    check(holeInside.select({37,50,0},0,0,0,0).emitted,"Hole inner support lost");
    for(auto& loop:p.area.loops)std::reverse(loop.begin(),loop.end());Field reversed({p},{b},Arrangement::Independent);
    check(reversed.select({37,50,0},0,0,0,0).emitted,"Winding changed EvenOdd support");
    const std::array<amin::Vec3,3> basis{{{2,.5,1},{.1,-3,0},{.4,.8,2}}};
    const amin::Vec3 minimum{-2,-1,0},maximum{3,4,9};const auto r=transformedBounds(minimum,maximum,basis);
    check(r.spatial>=r.xy&&r.xy>0,"Radius pair metrics");
    // Dense independent interior points must be enclosed; use row matrix
    // multiplication explicitly instead of the implementation's corner loops.
    for(int x=0;x<=10;++x)for(int y=0;y<=10;++y)for(int z=0;z<=10;++z) {
        const double a=-2+.5*x,c=-1+.5*y,d=.9*z;
        const double px=2*a+.1*c+.4*d,py=.5*a-3*c+.8*d,pz=a+2*d;
        check(std::hypot(px,py)<=r.xy+1e-10&&std::hypot(px,py,pz)<=r.spatial+1e-10,"Auto bound does not enclose geometry");
    }
    const std::array<amin::Vec3,3> identity{{{1,0,0},{0,1,0},{0,0,1}}};
    const auto exact=transformedBounds({0,0,0},{3,4,12},identity);check(exact.xy==5&&exact.spatial==13,"Analytic 5/13 radius");
    check(transformedBounds({0,0,0},{0,0,0},identity).spatial==0,"Valid collapsed bound rejected");
    denied([&]{transformedBounds({3,0,0},{2,0,0},identity);},"Inverted bounds admitted");
    auto invalid=band(1,0,1);invalid.curve={0,NAN};denied([&]{Field bad({box()},{invalid},Arrangement::Independent);},"NaN curve admitted");
    invalid=band(1,0,1);invalid.sources[0].weight=-1;denied([&]{Field bad({box()},{invalid},Arrangement::Independent);},"Negative weight admitted");
}
void independentOffsetReference() {
    using namespace Clipper2Lib;
    cyrus::bands::Path concave{1,{{{{0,0,0},{100,0,0},{100,35,0},{35,35,0},{35,100,0},{0,100,0}}},true},Join::Sharp};
    Paths64 original;Path64 points;for(auto p:concave.area.loops[0])points.emplace_back(std::llround(p.x*1e6),std::llround(p.y*1e6));original.push_back(points);
    const auto contains=[](const Paths64& paths,Point64 p){bool hit=false;for(const auto& path:paths){const auto state=PointInPolygon(p,path);if(state==PointInPolygonResult::IsOn)return true;if(state==PointInPolygonResult::IsInside)hit=!hit;}return hit;};
    double worst=0;
    for(bool inside:{false,true}){
        auto b=band(1,0,30);b.inside=inside;b.curve={0,1};Field field({concave},{b},Arrangement::Independent);
        for(int k=0;k<220;++k){
            const double x=-25+150*double((k*73)%223)/223,y=-25+150*double((k*97)%227)/227;const Point64 point{std::llround(x*1e6),std::llround(y*1e6)};
            if(contains(original,point)!=inside)continue;
            const auto crosses=[&](double q){ClipperOffset offset(2);offset.AddPaths(original,JoinType::Miter,EndType::Polygon);Paths64 shape;offset.Execute((inside?-q:q)*1e6,shape);check(offset.ErrorCode()==0,"Independent reference offset failed");return contains(shape,point)!=inside;};
            const auto found=field.inspect({x,y,0});if(!crosses(30)){check(found.contributions.empty(),"Field extends beyond reference offset");continue;}
            double lo=0,hi=30;for(int step=0;step<24;++step){const double mid=(lo+hi)/2;if(crosses(mid))hi=mid;else lo=mid;}
            check(found.contributions.size()==1,"Concave reference lost support");const double error=std::abs(found.contributions[0].progress-(lo+hi)/60);worst=std::max(worst,error);
            check(error<=1./256,"Concave independent progress reference");
        }
    }
    std::cout<<"Concave independent finer-grid offset reference: max progress error="<<worst<<'\n';
}
void tessellationOracles() {
    const Cubic curved{{0,0,0},{0,100,0},{100,-100,0},{100,0,0}};
    const std::vector<Cubic> chain={curved,{{100,0,0},{100,0,0},{100,150,0},{100,150,0}},{{100,150,0},{100,150,0},{0,150,0},{0,150,0}},{{0,150,0},{0,150,0},{0,0,0},{0,0,0}}};
    const auto line=tessellate(chain,.001,8192);check(line.size()>64&&line.size()<8192,"Adaptive curve witness did not refine");
    double worst=0;
    for(int k=0;k<=2000;++k){const double t=double(k)/2000,u=1-t;const auto p=curved.a*(u*u*u)+curved.b*(3*u*u*t)+curved.c*(3*u*t*t)+curved.d*(t*t*t);double distance=INFINITY;
        for(std::size_t i=0;i<line.size();++i){const auto a=line[i],b=line[(i+1)%line.size()],d=b-a;const double n=d.x*d.x+d.y*d.y,v=n?std::clamp(((p.x-a.x)*d.x+(p.y-a.y)*d.y)/n,0.,1.):0;distance=std::min(distance,std::hypot(p.x-a.x-v*d.x,p.y-a.y-v*d.y));}
        worst=std::max(worst,distance);check(distance<=.001,"Independent cubic samples exceed tessellation tolerance");}
    check(std::find_if(line.begin(),line.end(),[](auto p){return p.x==100&&p.y==150;})!=line.end(),"Linear knot corner was dropped");
    auto open=chain;open.back().d.x=1;denied([&]{tessellate(open,.001,8192);},"Open Bezier chain admitted");
    denied([&]{tessellate(chain,.00001,20);},"Tessellation exceeded its output/work cap");
    auto broken=chain;broken.front().b.y=NAN;denied([&]{tessellate(broken,.001,8192);},"Nonfinite Bezier handle admitted");
    std::cout<<"Adaptive cubic: vertices="<<line.size()<<", independent max chord error="<<worst<<'\n';
}
void complexSharpReference() {
    using namespace Clipper2Lib;
    std::vector<cyrus::bands::Path> cases={
        {1,{{{{0,0,0},{150,0,0},{1,4,0}}},true},Join::Sharp},
        {1,{{{{0,0,0},{40,0,0},{40,18,0},{60,18,0},{60,0,0},{100,0,0},{100,40,0},{60,40,0},{60,22,0},{40,22,0},{40,40,0},{0,40,0}}},true},Join::Sharp},
        {1,{{{{0,0,0},{80,80,0},{0,80,0},{80,0,0}}},true},Join::Sharp},
        {1,{{{{0,0,0},{25,0,0},{25,25,0},{0,25,0}},{{40,0,0},{65,0,0},{65,25,0},{40,25,0}}},true},Join::Sharp}
    };
    const auto contains=[](const Paths64& paths,Point64 p){bool inside=false;for(const auto& path:paths){const auto location=PointInPolygon(p,path);if(location==PointInPolygonResult::IsOn)return true;if(location==PointInPolygonResult::IsInside)inside=!inside;}return inside;};
    std::size_t supported=0;double worst=0;
    for(const auto& path:cases)for(bool inward:{false,true}){
        auto b=band(1,0,12);b.inside=inward;b.curve={0,0,1,0,0};Field field({path},{b},Arrangement::Independent);
        Paths64 raw;for(const auto& loop:path.area.loops){Path64 points;for(auto p:loop)points.emplace_back(std::llround(p.x*1e6),std::llround(p.y*1e6));raw.push_back(std::move(points));}
        const auto normalized=Union(raw,FillRule::EvenOdd);
        for(int i=0;i<100;++i){const amin::Vec3 p{-10+180.*((i*43)%103)/103,-10+110.*((i*79)%107)/107,0};const Point64 packed{std::llround(p.x*1e6),std::llround(p.y*1e6)};
            if(contains(normalized,packed)!=inward)continue;
            const auto crosses=[&](double q){ClipperOffset offset(2);offset.AddPaths(normalized,JoinType::Miter,EndType::Polygon);Paths64 result;offset.Execute((inward?-q:q)*1e6,result);check(offset.ErrorCode()==0,"Complex reference failed");return contains(result,packed)!=inward;};
            const auto result=field.inspect(p);if(!crosses(12)){check(result.contributions.empty(),"Complex field exceeds true support");continue;}
            check(result.contributions.size()==1,"Complex Sharp support lost");++supported;
            double lo=0,hi=12;for(int j=0;j<25;++j){const double q=(lo+hi)*.5;if(crosses(q))hi=q;else lo=q;}
            const double t=(lo+hi)/24;const double expected=t<.25?0:t<.5?4*t-1:t<.75?3-4*t:0;
            const double error=std::abs(result.occupancy-expected);worst=std::max(worst,error);check(error<=.005,"Complex Sharp steep curve exceeds contribution error");
        }
    }
    check(supported>50,"Complex reference did not cover enough admitted points");
    auto ramp=band(1,0,1);ramp.curve={0,1};std::vector<Band> overlapping;
    for(int i=1;i<=32;++i){auto copy=ramp;copy.id=i;overlapping.push_back(copy);}Field saturated({box(Join::Sharp)},overlapping,Arrangement::Independent);
    const auto inspected=saturated.inspect({100.021,50,0});double sum=0;for(const auto& c:inspected.contributions)sum+=c.value;
    check(std::abs(sum-32*.021)<=.005&&inspected.error<=.005,"32 full-strength narrow ramps exceed aggregate error");
    ramp.curve.resize(257);for(int i=0;i<257;++i)ramp.curve[i]=i%2;
    denied([&]{Field tooSteep({box(Join::Sharp)},{ramp},Arrangement::Independent);},"Unattainable narrow curve silently degraded");
    std::cout<<"Complex Sharp: supported probes="<<supported<<", max contribution error="<<worst<<'\n';
}
void scaleProfiles() {
    using namespace amin;
    auto b=band(1,0,40);b.scale={.5,1.5};
    Field baseline({box()},{b},Arrangement::Consecutive);
    b.scaleCurve={.25,2};Field sized({box()},{b},Arrangement::Consecutive);
    for(unsigned i=0;i<1000;++i){
        const double t=(i+.5)/1000;const Vec3 p{100+40*t,50,0};
        const auto a=baseline.sample(p,42,i,791),v=sized.sample(p,42,i,791);
        check(a.emitted==v.emitted&&a.band==v.band&&a.source==v.source&&a.occupancy==v.occupancy,"Scale changed placement/source lottery");
        check(std::abs(v.scale-a.scale*(.25+1.75*t))<1e-12,"Scale curve must multiply the unchanged keyed random size");
    }
    b.scaleCurve={0,0};Field zero({box()},{b},Arrangement::Consecutive);
    const auto z=zero.sample({110,50,0},42,1,791);
    check(z.emitted&&z.scale==0&&z.occupancy==1,"Zero size must not act as density rejection");
    for(const auto values:std::vector<std::vector<double>>{{-1,1},{0,NAN},{1,INFINITY},{1,101},{1},std::vector<double>(258,1)}){
        auto bad=b;bad.scaleCurve=values;denied([&]{Field invalid({box()},{bad},Arrangement::Consecutive);},"Invalid scale trace admitted");
    }
    // Sharp size edits share density coordinates, never refine its lottery.
    b.curve={.25,1};b.scaleCurve={1,1};Field sharpBase({box(Join::Sharp)},{b},Arrangement::Independent);
    b.scaleCurve={.5,1.5};Field sharpSize({box(Join::Sharp)},{b},Arrangement::Independent);
    check(sharpSize.stats().levels==sharpBase.stats().levels,"Size changed density preparation geometry");
    for(unsigned i=0;i<200;++i){
        const double t=(i+.3)/200;const Vec3 p{100+40*t,50,0};
        const auto a=sharpBase.sample(p,31,i,702),v=sharpSize.sample(p,31,i,702);
        check(a.emitted==v.emitted&&a.band==v.band&&a.source==v.source&&a.occupancy==v.occupancy,"Sharp size altered density or ownership");
        if(v.emitted)check(std::abs(v.scale/a.scale-(.5+t))<=.005,"Sharp scale profile exceeds declared multiplier error");
    }
    b.curve={1,1};b.scaleCurve={0,100};Field steep({box(Join::Sharp)},{b},Arrangement::Consecutive);
    denied([&]{steep.inspect({113.12345,50,0});},"Uncertifiable Sharp scale silently approximated");
    auto other=band(2,0,40);other.scaleCurve={2,2};b.scaleCurve={.5,.5};
    Field overlap({box()},{b,other},Arrangement::Independent),reordered({box()},{other,b},Arrangement::Independent);
    for(unsigned i=0;i<100;++i){const auto a=overlap.sample({110,50,0},42,i,3),v=reordered.sample({110,50,0},42,i,3);check(a.band==v.band&&a.scale==v.scale,"Independent Band reorder changed scale owner");}
    // Full candidate transforms and source radii, with no spacing to hide changes.
    const std::vector<Triangle> surface={{{100,1,0},{140,1,0},{140,99,0}},{{100,1,0},{140,99,0},{100,99,0}}};
    Settings s;s.sourceCount=1;s.count=1000;s.uniformScale={1,1};s.receiverSalt=17;
    b.curve={1,1};b.scaleCurve={1,1};
    s.splineField=std::make_shared<Field>(std::vector<Path>{box()},std::vector<Band>{b},Arrangement::Consecutive);const auto before=scatter(surface,s);
    b.scaleCurve={.5,1.5};s.splineField=std::make_shared<Field>(std::vector<Path>{box()},std::vector<Band>{b},Arrangement::Consecutive);const auto after=scatter(surface,s);
    check(before.size()==after.size()&&!after.empty(),"Scale-only edit changed unspaced count");
    for(std::size_t i=0;i<after.size();++i){const auto& a=before[i];const auto& v=after[i];const double f=.5+(v.position.x-100)/40;
        check(a.candidateKey==v.candidateKey&&a.source==v.source&&a.bandOwner==v.bandOwner&&length(a.position-v.position)==0,"Scale-only edit moved a candidate");
        check(std::abs(v.scale-a.scale*f)<1e-12,"Scatter scale profile applied incorrectly");
        const auto ar=transformedBounds({-1,-2,0},{1,2,3},{a.xAxis*a.scale,a.yAxis*a.scale,a.zAxis*a.scale});
        const auto vr=transformedBounds({-1,-2,0},{1,2,3},{v.xAxis*v.scale,v.yAxis*v.scale,v.zAxis*v.scale});
        check(std::abs(vr.xy-ar.xy*f)<1e-12&&std::abs(vr.spatial-ar.spatial*f)<1e-12,"Auto radius missed or doubled the scale curve");
    }
}
void resourceAdmission() {
    const auto initial=reservedFieldBytes();auto b=band(1,0,20);b.curve={0,1};
    {
        Field live({box(Join::Sharp)},{b},Arrangement::Independent);
        check(reservedFieldBytes()==initial+live.stats().bytes,"Live field capacity was not reserved");
        auto shared=live;check(reservedFieldBytes()==initial+live.stats().bytes,"Sharing a field duplicated its reservation");
        const auto held=reservedFieldBytes();auto limits=Limits{};limits.constructionWork=100;
        denied([&]{Field successor({box(Join::Sharp)},{b},Arrangement::Independent,limits);},"Construction work limit ignored");
        check(reservedFieldBytes()==held&&live.inspect({110,50,0}).occupancy>0,"Failed preparation leaked its reservation or damaged the old field");
        limits=Limits{};limits.constructionBytes=1;
        denied([&]{Field successor({box(Join::Sharp)},{b},Arrangement::Independent,limits);},"Scratch preflight ignored");
        check(reservedFieldBytes()==held,"Scratch rejection leaked its reservation");
        limits=Limits{};limits.bytes=100;
        denied([&]{Field successor({box()},{b},Arrangement::Independent,limits);},"Retained byte limit ignored");
        check(reservedFieldBytes()==held,"Retained-byte rejection leaked its reservation");
    }
    check(reservedFieldBytes()==initial,"Last field owner did not release its reservation");
    std::vector<Band> overlaps;for(unsigned i=1;i<=32;++i){auto copy=b;copy.id=i;overlaps.push_back(copy);}
    std::vector<Field> retained;bool aggregateDenied=false;
    for(int i=0;i<24;++i){try{retained.emplace_back(std::vector<cyrus::bands::Path>{box(Join::Sharp)},overlaps,Arrangement::Independent);}
        catch(const std::invalid_argument& e){aggregateDenied=std::string(e.what()).find("aggregate memory allowance")!=std::string::npos;break;}}
    check(aggregateDenied&&!retained.empty(),"Simultaneous retained/staged fields were not bounded");
    check(retained.front().inspect({110,50,0}).occupancy==1,"Aggregate rejection damaged a retained field");
    retained.clear();check(reservedFieldBytes()==initial,"Aggregate field reservations leaked");
}
}
int main() {
    try{rangeAndDensity();nativeIntervalsAndOwners();preparedGenerationAndMovement();sharpOracles();geometryAndRadii();independentOffsetReference();tessellationOracles();complexSharpReference();scaleProfiles();resourceAdmission();std::cout<<"PASS "<<assertions<<" spline-field/Auto-radius assertions\n";}
    catch(const std::exception& e){std::cerr<<"FAIL after "<<assertions<<" assertions: "<<e.what()<<'\n';return 1;}
}

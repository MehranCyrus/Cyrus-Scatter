#include "spline_overlay.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <map>
#include <stdexcept>

using namespace cyrus::bands;
using amin::Vec3;
namespace {
int checks=0;
void check(bool value,const char* message){++checks;if(!value)throw std::runtime_error(message);}
template<class F> void denied(F&& f,const char* message){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed,message);}
bool close(double a,double b,double e=1e-9){return std::abs(a-b)<=e;}
bool close(Vec3 a,Vec3 b,double e=1e-9){return close(a.x,b.x,e)&&close(a.y,b.y,e)&&close(a.z,b.z,e);}
Path square(Join join=Join::Rounded){return {1,{{{{0,0,0},{100,0,0},{100,100,0},{0,100,0}}},true},join};}
Band band(std::uint64_t id=1,double start=0,double end=10,double strength=1){
    Band b;b.id=id;b.path=1;b.start=start;b.end=end;b.strength=strength;b.sources={{std::to_string(id),0,1,false}};return b;
}
void plane(std::vector<ReceiverTriangle>& out,std::uint64_t id,double z,double low=-20,double high=120){
    out.push_back({{low,low,z},{high,low,z},{high,high,z},id,0});
    out.push_back({{low,low,z},{high,high,z},{low,high,z},id,1});
}
double distance(const Path& p,Vec3 point){double value=INFINITY;
    for(const auto& loop:p.area.loops)for(std::size_t i=0;i<loop.size();++i){const auto a=loop[i],b=loop[(i+1)%loop.size()];
        const double dx=b.x-a.x,dy=b.y-a.y,den=dx*dx+dy*dy;
        const double t=den?std::clamp(((point.x-a.x)*dx+(point.y-a.y)*dy)/den,0.,1.):0;
        value=std::min(value,std::hypot(point.x-a.x-t*dx,point.y-a.y-t*dy));}
    return value;
}
void sampleParityAndSurfaces(){
    auto a=band(10,0,20,.6),b=band(20,0,40,.7);a.curve={0,.8,.2,1};
    Field field({square()},{a,b},Arrangement::Independent);std::vector<ReceiverTriangle> receivers;plane(receivers,12,0);plane(receivers,24,19);
    // A vertical receiver crossing several density values, plus a tiny receiver
    // that global area-only stratification would otherwise miss.
    receivers.push_back({{108,0,0},{108,100,0},{108,100,40},36,0});
    receivers.push_back({{108,0,0},{108,100,40},{108,0,40},36,1});
    receivers.push_back({{105,40,100},{105.0001,40,100},{105,40.0001,100},48,0});
    OverlayOptions options;options.samples=1000;options.boundaries=false;
    const auto combined=buildOverlay(field,receivers,options);options.band=10;const auto selected=buildOverlay(field,receivers,options);
    check(combined.samples.size()==1000&&selected.samples.size()==1000,"Sample count");
    check(combined.stats.receivers==4&&combined.stats.sampledReceivers==4,"All receiver surfaces participate");
    check(combined.stats.boundaryLines==0&&combined.lines.size()==3000,"Independent falloff toggle");
    std::map<std::uint64_t,std::size_t> seen;bool zero=false,nonzero=false,saturated=false;
    for(std::size_t i=0;i<combined.samples.size();++i){const auto& sample=combined.samples[i];const auto& chosen=selected.samples[i];++seen[sample.receiver];
        const auto triangle=std::find_if(receivers.begin(),receivers.end(),[&](const auto& t){return t.receiver==sample.receiver&&t.face==sample.face;});
        check(triangle!=receivers.end(),"Sample provenance");check(close(sample.bary.x+sample.bary.y+sample.bary.z,1),"Barycentric sum");
        check(std::min({sample.bary.x,sample.bary.y,sample.bary.z})>=0,"Barycentric outside receiver");
        check(close(sample.position,triangle->a*sample.bary.x+triangle->b*sample.bary.y+triangle->c*sample.bary.z),"Sample left receiver");
        const auto inspection=field.inspect(sample.position);double expected=0;for(const auto& c:inspection.contributions)if(c.band==10)expected=c.value;
        check(sample.value==inspection.occupancy&&sample.error==inspection.error,"Combined field drifted from generation");
        check(chosen.value==expected&&close(chosen.position,sample.position),"Selected contribution drifted");
        zero|=sample.value==0;nonzero|=sample.value>0;saturated|=sample.value==1;
        for(std::size_t k=0;k<3;++k){const auto& line=combined.lines[i*3+k];check(line.receiver==sample.receiver&&line.face==sample.face,"Glyph provenance");
            check(line.color==std::uint8_t(std::lround(sample.value*32)),"Glyph density bin");
            if(sample.receiver==12||sample.receiver==24||sample.receiver==48)check(close(line.a.z,sample.position.z)&&close(line.b.z,sample.position.z),"Glyph moved off horizontal receiver");
            if(sample.receiver==36)check(close(line.a.x,108)&&close(line.b.x,108),"Vertical glyph projection failed");
        }
    }
    check(seen.size()==4&&seen[48]>=1&&seen[48]<=2,"Tiny receiver coverage");check(zero&&nonzero&&saturated,"Density fixture coverage");
    check(close(overlayColor(0),{0,0,1})&&close(overlayColor(32),{1,0,0}),"Zero/100 legend colors");
    check(close(overlayColor(33),{1,1,1}),"Boundary palette");denied([]{overlayColor(34);},"Invalid color admitted");
    const auto repeated=buildOverlay(field,receivers,options);
    for(std::size_t i=0;i<selected.samples.size();++i)check(close(selected.samples[i].position,repeated.samples[i].position,0)&&selected.samples[i].value==repeated.samples[i].value,"Preview not deterministic");
    options.samples=3;denied([&]{buildOverlay(field,receivers,options);},"Missing receiver silently sampled");
}
void outlineOracle(){
    for(bool inside:{false,true}){
        auto path=square();path.area.loops.push_back({{30,30,0},{70,30,0},{70,70,0},{30,70,0}});
        auto b=band(1,2,10);b.inside=inside;Field field({path},{b},Arrangement::Independent);
        std::size_t edges=0;double worst=0;
        const auto before=reservedFieldBytes();const auto stats=field.visitOutlines(1,[&](Vec3 a,Vec3 c){++edges;
            // Independent raw-segment distance oracle, including arc chords.
            for(double t:{0.,.25,.5,.75,1.}){const auto p=a+(c-a)*t;const double d=distance(path,p);worst=std::max(worst,std::min(std::abs(d-2),std::abs(d-10)));}
        });
        check(edges>8&&stats.levels==2&&edges==stats.segments,"Rounded contours missing");
        check(worst<=stats.error+1e-8,"Rounded contours disagree with distance field");
        check(reservedFieldBytes()==before,"Outline scratch lease leaked");
    }
    // Self-overlap: a normalized polygon offset would discard raw internal
    // edges and violate the existing Rounded field distance interpretation.
    auto crossed=square();crossed.area.loops.push_back({{50,-25,0},{150,-25,0},{150,75,0},{50,75,0}});
    for(bool inside:{false,true}){auto b=band(1,0,8);b.inside=inside;Field field({crossed},{b},Arrangement::Independent);
        double worst=0;const auto stats=field.visitOutlines(1,[&](Vec3 a,Vec3 c){const auto p=(a+c)*.5;const double d=distance(crossed,p);worst=std::max(worst,std::min(d,std::abs(d-8)));});
        check(worst<=stats.error+1e-8,"Overlapping-loop distance boundary changed");}
    auto a=band(1,0,10),b=band(2,0,10);Field shared({square()},{a,b},Arrangement::Independent);
    const auto one=shared.visitOutlines(1,[](Vec3,Vec3){}),all=shared.visitOutlines(0,[](Vec3,Vec3){});
    check(one.segments==all.segments&&one.levels==all.levels,"Shared endpoints duplicated per Band");
    Field sharp({square(Join::Sharp)},{a},Arrangement::Consecutive);std::vector<Vec3> points;
    const auto sharpStats=sharp.visitOutlines(1,[&](Vec3 u,Vec3 v){points.push_back(u);points.push_back(v);});
    check(sharpStats.segments==8&&sharpStats.work==0&&sharpStats.scratchAllowance==0,"Sharp endpoints not reused");
    check(std::any_of(points.begin(),points.end(),[](auto p){return close(p,{-10,-10,0});}),"Sharp miter corner rounded");
    const auto before=reservedFieldBytes();denied([&]{shared.visitOutlines(0,[](Vec3,Vec3){throw std::runtime_error("visitor fault");});},"Visitor failure swallowed");
    check(reservedFieldBytes()==before,"Failed visitor scratch leaked");
    denied([&]{shared.visitOutlines(999,[](Vec3,Vec3){});},"Stale selected Band admitted");
}
void boundariesOnReceivers(){
    Field field({square(Join::Sharp)},{band()},Arrangement::Independent);std::vector<ReceiverTriangle> receivers;plane(receivers,1,0);plane(receivers,2,17);
    receivers.push_back({{-20,-20,10},{120,-20,80},{120,120,80},3,0});
    receivers.push_back({{-20,-20,10},{120,120,80},{-20,120,10},3,1});
    // Vertical receiver perpendicular to the boundary curtain.
    receivers.push_back({{50,-20,0},{50,20,0},{50,20,30},4,0});
    receivers.push_back({{50,-20,0},{50,20,30},{50,-20,30},4,1});
    // A face coplanar with x=-10, the outer boundary curtain.
    receivers.push_back({{-10,-20,0},{-10,120,0},{-10,120,30},5,0});
    receivers.push_back({{-10,-20,0},{-10,120,30},{-10,-20,30},5,1});
    OverlayOptions options;options.falloff=false;const auto result=buildOverlay(field,receivers,options);
    check(result.samples.empty()&&result.stats.boundaryLines==result.lines.size(),"Independent boundary toggle");
    std::map<std::uint64_t,std::size_t> seen;
    for(const auto& line:result.lines){++seen[line.receiver];check(line.color==33,"Boundary color");
        for(auto p:{line.a,line.b}){
            if(line.receiver==1)check(close(p.z,0),"Lower receiver lost");
            if(line.receiver==2)check(close(p.z,17),"Upper receiver lost");
            if(line.receiver==3)check(close(p.z,20+.5*p.x),"Sloped receiver clipping wrong");
            if(line.receiver==4)check(close(p.x,50)&&p.z>=-1e-8&&p.z<=30+1e-8,"Vertical intersection wrong");
            if(line.receiver==5)check(close(p.x,-10)&&p.y>=-10-1e-8&&p.y<=110+1e-8,"Coplanar receiver clipping wrong");
        }
    }
    check(seen.size()==5,"Receiver surfaces omitted by boundary projection");
    options.boundaries=false;const auto hidden=buildOverlay(field,receivers,options);check(hidden.lines.empty()&&hidden.samples.empty(),"Disabled overlay still draws");
    // A very narrow Band must retain both outlines even with no density samples.
    auto narrow=band(4,1,1.01);Limits precision;precision.quantum=1e-6;Field thin({square()},{narrow},Arrangement::Independent,precision);
    options.boundaries=true;std::vector<ReceiverTriangle> small;plane(small,1,0,102,108);
    // This surface deliberately misses both contours; no unbounded full-space lines.
    const auto miss=buildOverlay(thin,small,options);check(miss.lines.empty(),"Outlines not clipped to receivers");
    small.clear();plane(small,1,0,-2,102);const auto narrowVisible=buildOverlay(thin,small,options);
    bool first=false,last=false;
    for(const auto& line:narrowVisible.lines){const auto midpoint=(line.a+line.b)*.5;const auto d=distance(square(),midpoint);
        first|=std::abs(d-1)<narrowVisible.stats.outlines.error+1e-8;last|=std::abs(d-1.01)<narrowVisible.stats.outlines.error+1e-8;
        check(std::min(std::abs(d-1),std::abs(d-1.01))<=narrowVisible.stats.outlines.error+1e-8,"Narrow outline moved outside accuracy");}
    check(first&&last,"Sparse display lost a narrow Band endpoint");
}
void physicalScale(){
    OverlayOptions options;options.samples=50;auto source=square();auto b=band(1,0,10);b.curve={0,1};
    std::vector<ReceiverTriangle> receiver;plane(receiver,1,15);Field original({source},{b},Arrangement::Independent);
    const auto baseline=buildOverlay(original,receiver,options);
    for(double scale:{.001,1000.}){auto p=source;for(auto& loop:p.area.loops)for(auto& v:loop)v=v*scale;
        auto scaledBand=b;scaledBand.end*=scale;auto surface=receiver;for(auto& t:surface){t.a=t.a*scale;t.b=t.b*scale;t.c=t.c*scale;}
        Limits precision;precision.quantum*=scale;Field field({p},{scaledBand},Arrangement::Independent,precision);
        const auto result=buildOverlay(field,surface,options);
        if(result.lines.size()!=baseline.lines.size())std::cerr<<"Scale "<<scale<<": lines "<<result.lines.size()<<" vs "<<baseline.lines.size()<<", outlines "<<result.stats.outlines.segments<<" vs "<<baseline.stats.outlines.segments<<'\n';
        check(result.lines.size()==baseline.lines.size(),"Physical scaling changes display topology");
        for(std::size_t i=0;i<result.samples.size();++i)check(close(result.samples[i].position*(1/scale),baseline.samples[i].position,1e-8)&&close(result.samples[i].value,baseline.samples[i].value,1e-8),"Physical field sample mismatch");
        for(std::size_t i=0;i<result.lines.size();++i)check(close(result.lines[i].a*(1/scale),baseline.lines[i].a,1e-8)&&close(result.lines[i].b*(1/scale),baseline.lines[i].b,1e-8),"Physical boundary mismatch");
    }
}
void admissionAndFailure(){
    Field field({square()},{band()},Arrangement::Independent);std::vector<ReceiverTriangle> receivers;plane(receivers,1,0);OverlayOptions options;
    const auto previous=buildOverlay(field,receivers,options);const auto bytes=reservedFieldBytes();
    options.samples=20001;denied([&]{buildOverlay(field,receivers,options);},"Oversized samples admitted");options.samples=10;
    OverlayLimits limits;limits.work=2;denied([&]{buildOverlay(field,receivers,options,limits);},"Work limit ignored");
    limits={};limits.lines=40;denied([&]{buildOverlay(field,receivers,options,limits);},"Clipped line limit ignored");
    limits={};limits.bytes=100;denied([&]{buildOverlay(field,receivers,options,limits);},"Memory limit ignored");
    limits={};limits.outlines.segments=2;denied([&]{buildOverlay(field,receivers,options,limits);},"Outline segment limit ignored");
    limits={};limits.outlines.bytes=100;denied([&]{buildOverlay(field,receivers,options,limits);},"Outline scratch limit ignored");
    denied([&]{overlayPreparationBytes(200001,options);},"Face limit ignored");
    options.band=999;denied([&]{buildOverlay(field,receivers,options);},"Stale selection admitted");options.band=0;
    auto invalid=receivers;invalid[0].a.x=std::numeric_limits<double>::infinity();denied([&]{buildOverlay(field,invalid,options);},"Nonfinite receiver admitted");
    invalid=receivers;invalid[1].face=invalid[0].face;denied([&]{buildOverlay(field,invalid,options);},"Duplicate receiver face admitted");
    invalid=receivers;invalid[0].receiver=0;denied([&]{buildOverlay(field,invalid,options);},"Missing receiver identity admitted");
    const std::vector<ReceiverTriangle> empty;const auto noReceivers=buildOverlay(field,empty,options);check(noReceivers.lines.empty()&&noReceivers.samples.empty(),"Empty receiver behavior");
    const std::vector<ReceiverTriangle> degenerate={{{0,0,0},{0,0,0},{0,0,0},1,0}};
    const auto noArea=buildOverlay(field,degenerate,options);check(noArea.stats.degenerate==1&&noArea.lines.empty()&&noArea.samples.empty(),"Degenerate face behavior");
    check(previous.samples.size()==4000&&!previous.lines.empty(),"Failure changed existing result");
    check(reservedFieldBytes()==bytes,"Failure leaked field reservations");
    denied([&]{field.inspect({105,50,0},1);},"Query exceeded caller work budget");
}
}
int main(){try{sampleParityAndSurfaces();outlineOracle();boundariesOnReceivers();physicalScale();admissionAndFailure();
    std::cout<<checks<<" spline overlay checks passed\n";return 0;}catch(const std::exception& e){std::cerr<<"FAILED after "<<checks<<" checks: "<<e.what()<<'\n';return 1;}}

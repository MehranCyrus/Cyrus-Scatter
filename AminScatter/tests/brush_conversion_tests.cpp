#include "brush.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace cyrus::brush;
namespace {
unsigned checks=0;
void check(bool value,const char* text){++checks;if(!value)throw std::runtime_error(text);}
template<class F>void rejects(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed,"invalid import accepted");}
Contour square(double radius){return {{-radius,-radius},{radius,-radius},{radius,radius},{-radius,radius}};}
}
int main(){try{
    Surface surface({{{-100,-100,0},{100,-100,0},{100,100,0},{-100,100,0}},{{0,1,2},{0,2,3}}});
    const auto receiver=domain(surface);Document before;before.surface=surface.fingerprint();
    auto imported=importContours(before,{square(40),square(20),square(5)},receiver,false);
    Field field(surface,imported);
    for(int y=-49;y<50;++y)for(int x=-49;x<50;++x){
        const Point p{double(x)+.3,double(y)+.2};const double r=std::max(std::abs(p[0]),std::abs(p[1]));
        check(field.queryPoint(p).density==((r<40&&r>20)||r<5?1:0),"nested loop oracle");
    }
    auto loops=Contours{square(5),square(40),square(20)};
    std::reverse(loops[0].begin(),loops[0].end());std::reverse(loops[1].begin(),loops[1].end());
    auto reordered=importContours(imported,loops,receiver,false);
    check(encode(reordered)==encode(imported),"winding/order no-op preserves canonical bytes");
    auto roundtrip=importContours(imported,imported.contours,receiver,false);
    check(encode(roundtrip)==encode(imported),"export/import no-op");
    imported.falloff.inside=4;imported.falloff.outside=2;imported.falloff.scale=true;imported.falloff.scaleMin=.2;
    imported.falloff.densityCurve={0,.4,1};const auto frozen=encode(imported);
    auto added=importContours(imported,{square(30)},receiver,true);
    check(added.surface==imported.surface&&added.falloff.inside==4&&added.falloff.outside==2&&added.falloff.scale&&added.falloff.scaleMin==.2&&added.falloff.densityCurve==imported.falloff.densityCurve,"metadata survives");
    auto plainBefore=imported,plainAfter=added;plainBefore.falloff={};plainAfter.falloff={};
    Field oldField(surface,plainBefore),newField(surface,plainAfter);
    for(int y=-50;y<50;++y)for(int x=-50;x<50;++x){Point p{double(x)+.3,double(y)+.2};check(newField.queryPoint(p).density>=oldField.queryPoint(p).density,"Add erased coverage");}
    auto noopAdd=importContours(added,{square(10)},receiver,true);check(encode(noopAdd)==encode(added),"contained Add no-op");
    auto clipped=importContours(before,{square(500)},receiver,false);check(clipped.contours==receiver,"clip to receiver domain");
    auto shifted=square(5);for(auto& p:shifted)p[0]+=1000;
    auto outside=importContours(imported,{shifted},receiver,false);check(outside.contours.empty(),"outside Replace empties coverage");
    check(encode(importContours(imported,{shifted},receiver,true))==frozen,"outside Add is no-op");
    Contour bowtie{{-20,-20},{20,20},{-20,20},{20,-20}};
    auto crossed=importContours(before,{bowtie},receiver,false);Field crossField(surface,crossed);
    check(crossField.queryPoint({0,15}).density==1&&crossField.queryPoint({0,-15}).density==1&&crossField.queryPoint({15,0}).density==0,"self-intersection even-odd fill");
    rejects([&]{importContours(imported,{},receiver,false);});
    rejects([&]{importContours(imported,{{{0,0},{1,0}}},receiver,false);});
    rejects([&]{importContours(imported,{{{0,0},{1,0},{2,0}}},receiver,false);});
    rejects([&]{importContours(imported,{square(10),{{0,0},{1,0},{2,0}}},receiver,false);});
    rejects([&]{importContours(imported,{square(10),square(10)},receiver,false);});
    auto bad=square(2);bad[1][0]=NAN;rejects([&]{importContours(imported,{bad},receiver,false);});
    bad=square(2);bad[2][1]=1.1e9;rejects([&]{importContours(imported,{bad},receiver,false);});
    rejects([&]{importContours(imported,{square(.00001)},receiver,false);});
    Contour huge(maxVertices+1,{0,0});rejects([&]{importContours(imported,{huge},receiver,true);});
    check(encode(imported)==frozen,"failed successor mutated source");
    auto serialized=decode(encode(added));check(encode(serialized)==encode(added),"converted document storage round trip");
    std::cout<<"PASS "<<checks<<" Paint/spline normalization assertions\n";return 0;
}catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}}

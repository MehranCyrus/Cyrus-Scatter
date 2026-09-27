#include "scatter.h"
#include <iostream>
#include <chrono>
#include <stdexcept>
#include <cmath>
using namespace amin;
void check(bool p,const char* m) {if(!p) throw std::runtime_error(m);}
double energy(const std::vector<Instance>& p,double spacing) {
    double result=0;for(std::size_t i=0;i<p.size();++i) for(std::size_t j=0;j<i;++j) {
        const double d=length(p[i].position-p[j].position);if(d<spacing) result+=(spacing-d)*(spacing-d);
    }return result;
}
int main() {try {
    std::vector<Triangle> plane={{{0,0,0},{20,0,0},{20,20,0}},{{0,0,0},{20,20,0},{0,20,0}}};
    Settings s;s.count=1500;s.uniformScale={1,1};auto baseline=scatter(plane,s);
    s.relaxSpacing=.5;s.relaxIterations=20;s.relaxEnabled=true;
    auto relaxed=scatter(plane,s);check(relaxed.size()==baseline.size(),"Relax lost points");
    const double before=energy(baseline,.5),after=energy(relaxed,.5);
    check(after<before*.65,"Relax did not reduce overlap energy");
    for(const auto& p:relaxed) check(p.position.x>=0&&p.position.x<=20&&p.position.y>=0&&p.position.y<=20&&std::abs(p.position.z)<1e-9,"Relax left surface");
    auto again=scatter(plane,s);for(std::size_t i=0;i<again.size();++i) check(length(again[i].position-relaxed[i].position)==0,"Nondeterministic relaxation");
    s.collisionEnabled=true;s.collisionRadius=.2;auto combined=scatter(plane,s);
    for(std::size_t i=0;i<combined.size();++i) for(std::size_t j=0;j<i;++j) check(length(combined[i].position-combined[j].position)>=.4-1e-10,"Collision overlap survived");
    s.relaxEnabled=false;auto collision=scatter(plane,s);check(collision.size()<baseline.size(),"Collision did not remove overlaps");
    s.collisionEnabled=false;auto disabled=scatter(plane,s);for(std::size_t i=0;i<baseline.size();++i) check(length(disabled[i].position-baseline[i].position)==0,"Disabled controls changed output");
    Area exclude;exclude.include=false;exclude.loops={{{8,8,0},{12,8,0},{12,12,0},{8,12,0}}};
    s.areas={exclude};s.relaxEnabled=true;auto masked=scatter(plane,s);
    for(const auto& p:masked) check(!(p.position.x>=8&&p.position.x<=12&&p.position.y>=8&&p.position.y<=12),"Relax entered excluded area");
    s.areas.clear();s.linePattern=true;LineBand band;band.kind=3;band.width=.5;band.boundary.loops={{{0,10,0},{20,10,0}}};band.sources={0};s.lineBands={band};
    auto patterned=scatter(plane,s);for(const auto& p:patterned) check(std::abs(p.position.y-10)<=.5+1e-9,"Relax left line stroke");
    s.linePattern=false;auto tilted=plane;for(auto& t:tilted) for(auto* p:{&t.a,&t.b,&t.c}) p->z=p->x*.5;
    auto tilt=scatter(tilted,s);for(const auto& p:tilt) check(std::abs(p.position.z-p.position.x*.5)<1e-9,"Relax left tilted surface");
    std::cout<<"overlap_energy "<<before<<" -> "<<after<<"; collision "<<collision.size()<<"; combined "<<combined.size()<<"\n";
    std::vector<Triangle> large={{{0,0,0},{100,0,0},{100,100,0}},{{0,0,0},{100,100,0},{0,100,0}}};
    for(auto count:{10000u,100000u}) {
        s.count=count;s.relaxSpacing=.25;s.relaxIterations=10;s.collisionRadius=.1;s.collisionEnabled=true;
        auto start=std::chrono::steady_clock::now();auto result=scatter(large,s);
        std::cout<<"count="<<count<<" kept="<<result.size()<<" ms="<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count()<<"\n";
    }
    std::cout<<"PASS spacing, determinism, masks, strokes, tilted surface, disabled compatibility\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}

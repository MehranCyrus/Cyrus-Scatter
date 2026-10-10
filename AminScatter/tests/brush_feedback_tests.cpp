#include "brush.h"
#include <cmath>
#include <iostream>
#include <random>
#include <stdexcept>
using namespace cyrus::brush;
unsigned checks=0;
void require(bool v,const char* message){++checks;if(!v)throw std::runtime_error(message);}
void compare(const Coverage& a,const Coverage& b){
    require(a.limited==b.limited&&a.triangles.size()==b.triangles.size(),"Cached coverage topology/limit changed");
    for(std::size_t i=0;i<a.triangles.size();++i){
        require(std::abs(a.triangles[i].weight-b.triangles[i].weight)<1e-12,"Cached coverage weight changed");
        for(int k=0;k<3;++k)require(amin::length(a.triangles[i].vertices[k]-b.triangles[i].vertices[k])==0,"Cached preview geometry changed");
    }
}
int main(){
    Mesh mesh;mesh.vertices={{0,0,0},{20,0,0},{20,20,0},{0,20,0}};mesh.faces={{0,1,2},{0,2,3}};
    Surface surface(mesh);Hit hit;surface.hit({{10,10,100},{0,0,-1}},hit);
    Sample sample;sample.anchor=hit.anchor;sample.view={{0,0,100},{0,0,-1},false};
    Stroke stroke;stroke.radius=4;stroke.samples={sample};
    Document doc{surface.fingerprint(),{}};CoverageCache preview;SampleCache samples;std::unique_ptr<Field> previous;
    std::vector<Anchor> probes;
    for(unsigned f=0;f<2;++f)for(int y=0;y<=10;++y)for(int x=0;x<=10-y;++x)probes.push_back({f,{x/10.,y/10.,1-(x+y)/10.}});
    std::mt19937_64 rng(76);std::uniform_real_distribution<double> unit(0,1);
    for(int i=0;i<210;++i){
        stroke.id=i+1;stroke.strength=i<10?1:.3;stroke.softness=i<10?0:.6;stroke.erase=i%4==3;
        doc.strokes.push_back(stroke);auto field=std::make_unique<Field>(surface,doc,previous.get());
        auto cached=preview.build(surface,*field);auto values=samples.evaluate(*field,probes);
        if(i<12||i%50==0)compare(cached,coverage(surface,*field));
        for(std::size_t j=0;j<probes.size();++j){
            auto a=probes[j];double value=field->evaluate(a);require(std::abs(value-values[j])<1e-12,"Feedback samples differ");
            for(double density:{0.,.37,1.}){
                const double target=std::clamp(value*density,0.,1.);
                for(double u:{unit(rng),std::nextafter(target,0.),target,std::nextafter(target,1.)})if(u<1)
                    require(field->accepts(a,u,density)==(u<target),"Bounded decision differs at threshold");
            }
        }
        previous=std::move(field);
    }
    QueryStats fast,slow;const double v=previous->evaluate(hit.anchor,&slow);
    require(previous->accepts(hit.anchor,.2,1,&fast)==(.2<v),"Mixed erase decision");
    require(fast.dabs<slow.dabs,"Decision did not avoid irrelevant history");
    // Radius changes, history edits, Undo, Fill, limits, and formerly internal
    // nodes becoming leaves must not borrow stale cached values or bounds.
    for(int i=0;i<30;++i){
        doc.strokes.back().radius=i%2?1:5;doc.strokes.back().strength=.1+i*.02;
        if(i==8)doc.strokes[0].erase=true;
        if(i==12)doc.strokes.pop_back();
        if(i==16)doc.base=.4;
        if(i==20)doc.strokes.clear();
        auto next=std::make_unique<Field>(surface,doc,previous.get());
        auto budget=i%3==0?15u:32768u;
        compare(preview.build(surface,*next,budget),coverage(surface,*next,budget));
        previous=std::move(next);
        if(doc.strokes.empty())doc.strokes.push_back(stroke);
    }
    // A tiny off-center island is invisible at the original triangle corners.
    doc.strokes.clear();doc.base=0;surface.hit({{13,7,100},{0,0,-1}},hit);stroke.samples[0].anchor=hit.anchor;
    stroke.radius=.2;stroke.strength=1;stroke.softness=0;stroke.erase=false;doc.strokes.push_back(stroke);
    Field island(surface,doc,previous.get());auto small=preview.build(surface,island);
    require(!small.triangles.empty(),"Interior island disappeared");compare(small,coverage(surface,island));
    // An unfinished stroke keeps one opacity contribution, then commits without
    // changing feedback. Cancel returns to the committed document.
    doc.strokes.clear();stroke.radius=4;stroke.strength=.5;stroke.samples[0]=sample;
    Field base(surface,doc);previous=std::make_unique<Field>(base);preview.clear();samples.clear();
    for(int i=0;i<12;++i){stroke.samples.push_back(sample);auto next=std::make_unique<Field>(surface,doc,previous.get(),FieldLimits{},&stroke);
        require(next->evaluate(sample.anchor)==.5,"Pending dabs accumulated opacity");
        compare(preview.build(surface,*next),coverage(surface,*next));previous=std::move(next);
    }
    doc.strokes.push_back(stroke);Field commit(surface,doc,previous.get());compare(preview.build(surface,commit),coverage(surface,commit));
    doc.strokes.clear();Field cancel(surface,doc,&commit);require(preview.build(surface,cancel).triangles.empty(),"Cancel retained paint");
    // Surface identity is part of cache validity, not just face/bary coordinates.
    mesh.vertices[2].z=1;Surface changed(mesh);doc.surface=changed.fingerprint();Field replacement(changed,doc,&cancel);
    compare(preview.build(changed,replacement),coverage(changed,replacement));
    // Growing nonuniformly transformed strokes on a folded closed surface.
    // Verify prefix reuse, changed old dabs, occlusion, and partial erasure.
    Mesh folded;folded.vertices={{0,0,5},{0,0,-5},{5,0,0},{0,5,0},{-5,0,0},{0,-5,0}};
    folded.faces={{0,2,3},{0,3,4},{0,4,5},{0,5,2},{1,3,2},{1,4,3},{1,5,4},{1,2,5}};
    Surface curved(folded);Document drawing{curved.fingerprint(),{},.2};Stroke drag;drag.radius=3;drag.strength=.4;drag.softness=.8;
    preview.clear();samples.clear();previous.reset();std::vector<Anchor> curvedProbes;
    for(unsigned face=0;face<8;++face)curvedProbes.push_back({face,{.2,.3,.5}});
    for(int i=0;i<40;++i){
        Sample dab;dab.anchor={unsigned(i%4),{.2,.3,.5}};dab.view={{0,0,100},{0,0,-1},false};dab.basis={{{2,0,0},{.3,1,0},{0,0,.7}}};
        drag.samples.push_back(dab);
        if(i==15)drag.samples[0].anchor.bary={.4,.3,.3};
        if(i==25)drag.erase=true;
        auto next=std::make_unique<Field>(curved,drawing,previous.get(),FieldLimits{},&drag);
        compare(preview.build(curved,*next),coverage(curved,*next));
        auto values=samples.evaluate(*next,curvedProbes);
        for(std::size_t j=0;j<curvedProbes.size();++j){
            const auto a=curvedProbes[j];const double value=next->evaluate(a);
            require(std::abs(value-values[j])<1e-12,"Growing stroke feedback changed");
            for(double density:{1e-12,.6,1.})for(double u:{value*density,std::nextafter(value*density,0.),unit(rng)})
                if(u<1)require(next->accepts(a,u,density)==(u<value*density),"Curved membership changed");
        }
        previous=std::move(next);
    }
    std::cout<<"PASS "<<checks<<" feedback and exact membership checks\n";
}

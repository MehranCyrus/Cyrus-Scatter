#include "brush.h"
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <random>
#include <fstream>
#include <iomanip>

using namespace cyrus::brush;
static int checks=0;
void require(bool b,const char* message){if(!b)throw std::runtime_error(message);++checks;}
template<class F> void rejects(F f){bool rejected=false;try{f();}catch(const std::exception&){rejected=true;}require(rejected,"Invalid input was accepted");}
bool close(double a,double b){return std::abs(a-b)<1e-8;}
Mesh plane(){return {{{-10,-10,0},{10,-10,0},{10,10,0},{-10,10,0}},{{{0,1,2}},{{0,2,3}}}};}
Anchor at(const Surface& s,Vec3 p){Hit h;require(s.hit({{p.x,p.y,100},{0,0,-1}},h),"Missing plane hit");return h.anchor;}
int main(int argc,char** argv){
    if(argc==2){std::ifstream file(argv[1]);Mesh mesh;std::size_t vertices=0,faces=0;file>>vertices>>faces;mesh.vertices.resize(vertices);mesh.faces.resize(faces);
        for(auto& v:mesh.vertices)file>>v.x>>v.y>>v.z;for(auto& f:mesh.faces)file>>f[0]>>f[1]>>f[2];Ray ray;file>>ray.origin.x>>ray.origin.y>>ray.origin.z>>ray.direction.x>>ray.direction.y>>ray.direction.z;
        require(bool(file),"Bad pick fixture");Surface surface(std::move(mesh));Hit fast,reference;auto a=surface.hit(ray,fast),b=surface.hitReference(ray,reference);
        std::cerr<<std::setprecision(17)<<"BVH "<<a<<" face "<<fast.anchor.face<<" distance "<<fast.distance<<" reference "<<b<<" face "<<reference.anchor.face<<" distance "<<reference.distance<<"\n";
        require(a==b&&(!a||(fast.anchor.face==reference.anchor.face&&std::abs(fast.distance-reference.distance)<1e-7)),"Host pick fixture mismatch");return 0;
    }
    Surface surface(plane());Stroke stroke;stroke.id=1;stroke.radius=2;stroke.strength=.5;stroke.softness=0;
    Sample sample;sample.anchor=at(surface,{0,0,0});sample.view={{0,0,100},{0,0,-1},false};stroke.samples.push_back(sample);
    Document doc{surface.fingerprint(),{stroke}};Field one(surface,doc);
    require(close(one.evaluate(at(surface,{0,0,0})),.5),"Small paint on four-vertex plane failed");
    require(close(one.evaluate(at(surface,{1,0,0})),.5),"New candidate did not recover field");
    require(close(one.evaluate(at(surface,{3,0,0})),0),"Radius leaked");
    // The continuous overlay must find a tiny dab even on a two-triangle mesh.
    auto tint=coverage(surface,one);
    require(!tint.limited&&!tint.triangles.empty(),"Coverage missed coarse-mesh dab");
    for(const auto& t:tint.triangles){
        const auto centre=(t.vertices[0]+t.vertices[1]+t.vertices[2])*(1./3);
        require(close(t.weight,one.evaluateReference(at(surface,centre))),"Tint differs from the saved field");
    }
    auto tiny=doc;tiny.strokes[0].radius=.05;
    require(!coverage(surface,Field(surface,tiny)).triangles.empty(),"Tiny coverage disappeared");
    require(coverage(surface,one,2).limited,"Coverage budget was not reported");
    require(coverage(surface,Field(surface,{surface.fingerprint(),{},1})).triangles.size()==2,"Filled coverage should reuse the coarse mesh");
    for(int i=0;i<100;++i)doc.strokes[0].samples.push_back(sample);
    require(close(Field(surface,doc).evaluate(sample.anchor),.5),"Callbacks accumulated opacity");
    stroke.id=2;doc.strokes.push_back(stroke);
    require(close(Field(surface,doc).evaluate(sample.anchor),.75),"Separate strokes did not build opacity");
    stroke.id=3;stroke.erase=true;doc.strokes.push_back(stroke);
    require(close(Field(surface,doc).evaluate(sample.anchor),.375),"Erase semantics failed");
    doc.strokes[1].enabled=false;
    require(close(Field(surface,doc).evaluate(sample.anchor),.25),"Editing an earlier stroke failed");
    auto encoded=encode(doc);auto decoded=decode(encoded);
    require(encode(decoded)==encoded,"Document roundtrip failed");
    auto damaged=encoded;damaged[0]=255;rejects([&]{decode(damaged);});
    damaged=encoded;damaged.resize(damaged.size()-1);rejects([&]{decode(damaged);});
    damaged=encoded;damaged.push_back(0);rejects([&]{decode(damaged);});
    auto invalid=doc;invalid.strokes[0].radius=0;rejects([&]{encode(invalid);});
    Document full{surface.fingerprint(),{},1};
    require(Field(surface,full).evaluate(sample.anchor)==1,"Filled base was not preserved");
    auto erased=stroke;erased.erase=true;erased.strength=.25;erased.softness=0;
    full.strokes={erased};
    require(close(Field(surface,full).evaluate(sample.anchor),.75),"Erase from filled base failed");
    require(decode(encode(full)).base==1,"Saved filled base was lost");
    auto legacyBytes=encode(doc);legacyBytes[0]=2;
    legacyBytes.erase(legacyBytes.begin()+12,legacyBytes.begin()+20);
    require(decode(legacyBytes).base==0,"Legacy Brush v2 base was not recovered");
    full.base=2;rejects([&]{encode(full);});
    invalid=doc;invalid.surface++;rejects([&]{Field f(surface,invalid);});
    invalid=doc;invalid.strokes[0].samples[0].basis[0]={0,0,0};rejects([&]{encode(invalid);});
    // Persist the cursor path, then shrink its radius: midpoint coverage must
    // come from re-hit samples, not from interpolation through space.
    Stroke path;path.radius=.2;path.softness=0;path.strength=.5;
    Sample left=sample,right=sample;left.anchor=at(surface,{-8,0,0});right.anchor=at(surface,{8,0,0});
    left.hasPath=right.hasPath=true;right.connected=true;
    left.ray={{-8,0,100},{0,0,-1}};right.ray={{8,0,100},{0,0,-1}};
    left.screen={0,0};right.screen={100,0};path.samples={left,right};
    auto savedPath=decode(encode({surface.fingerprint(),{path}}));
    require(close(Field(surface,savedPath).evaluate(sample.anchor),.5),"Radius replay left gaps between callbacks");
    require(resample(surface,path).samples.size()>100,"Radius edit did not resample");
    path.samples[1].connected=false;
    require(Field(surface,{surface.fingerprint(),{path}}).evaluate(sample.anchor)==0,"Off-mesh gap was joined");
    path.samples[1].connected=true;path.samples[1].view.eye.x+=1;
    rejects([&]{resample(surface,path);});
    // Captured nonuniform object scale gives a world-radius footprint.
    stroke.erase=false;stroke.strength=1;stroke.samples={sample};stroke.samples[0].basis[0]={2,0,0};
    Field scaled(surface,{surface.fingerprint(),{stroke}});
    require(scaled.evaluate(at(surface,{1.1,0,0}))==0,"Nonuniform metric ignored");
    require(scaled.evaluate(at(surface,{0,1.1,0}))==1,"Nonuniform metric incorrectly shrank both axes");
    // A thin disconnected back sheet never acquires front-face paint.
    auto stacked=plane();for(int i=0;i<4;++i){auto v=stacked.vertices[i];v.z=-.1;stacked.vertices.push_back(v);}stacked.faces.push_back({4,5,6});stacked.faces.push_back({4,6,7});
    Surface sheets(stacked);stroke.samples={sample};stroke.radius=100;
    Field sheetField(sheets,{sheets.fingerprint(),{stroke}});
    require(sheetField.evaluate({2,{.5,0,.5}})==0,"Disconnected footprint leaked");
    require(!sheets.visible({2,{.5,0,.5}},sample.view),"Self-occlusion did not reject back sheet");
    // Both accelerated picking and indexed field results must match their oracles.
    Mesh grid;constexpr unsigned side=25;
    for(unsigned y=0;y<=side;++y)for(unsigned x=0;x<=side;++x)grid.vertices.push_back({double(x),double(y),std::sin(x*.3)*std::cos(y*.2)});
    for(unsigned y=0;y<side;++y)for(unsigned x=0;x<side;++x){auto a=y*(side+1)+x,b=a+1,c=a+side+1,d=c+1;grid.faces.push_back({a,b,d});grid.faces.push_back({a,d,c});}
    Surface terrain(grid);std::mt19937 rng(42);std::uniform_real_distribution<double> uniform(.01,24.99);QueryStats stats;
    Document history{terrain.fingerprint(),{}};
    for(unsigned i=0;i<40;++i){Hit h;terrain.hit({{uniform(rng),uniform(rng),100},{0,0,-1}},h);Stroke s;s.id=i+1;s.radius=1+(i%5);s.strength=.3;s.erase=i%4==0;s.samples={Sample{h.anchor,{{{1,0,0},{0,1,0},{0,0,1}}},sample.view}};history.strokes.push_back(s);}
    Field field(terrain,history);
    auto terrainTint=coverage(terrain,field,4096);
    require(!terrainTint.triangles.empty()&&terrainTint.triangles.size()<=4096,"Curved coverage preview exceeded budget");
    for(unsigned i=0;i<600;++i){Ray ray{{uniform(rng),uniform(rng),100},{0,0,-1}};Hit fast,slow;
        require(terrain.hit(ray,fast,INFINITY,&stats)==terrain.hitReference(ray,slow),"BVH/reference hit mismatch");
        require(close(fast.distance,slow.distance),"BVH/reference distance mismatch");
        require(close(field.evaluate(fast.anchor),field.evaluateReference(fast.anchor)),"Indexed/replay field mismatch");
    }
    require(stats.triangles<600*grid.faces.size()/10,"Ray index did not reduce triangle checks");
    for(std::uint64_t i=0;i<10000;++i){require(threshold(42,i)>=0&&threshold(42,i)<1,"Threshold range");require(!accepted(42,i,.25)||accepted(42,i,.75),"Mask nesting failed");require(!accepted(42,i,0)&&accepted(42,i,1),"Empty/full membership failed");}
    // Repeated opaque paint must not replay every old dab at a covered point.
    Stroke solid;solid.radius=2;solid.softness=0;solid.strength=1;solid.samples={sample};
    Document repeated{surface.fingerprint(),std::vector<Stroke>(1000,solid)};
    Field repeatedField(surface,repeated);QueryStats covered;
    require(repeatedField.evaluate(sample.anchor,&covered)==1,"Opaque repeated paint lost coverage");
    require(covered.dabs==1,"Covered point replayed redundant history");
    QueryStats outside;
    require(repeatedField.evaluate(at(surface,{5,0,0}),&outside)==0&&outside.dabs==0,"Outside coverage replayed history");
    repeated.strokes.back().erase=true;Field erasedField(surface,repeated);QueryStats removed;
    require(erasedField.evaluate(sample.anchor,&removed)==0&&removed.dabs==1,"Opaque erase replayed old paint");
    // Mixed opacity/order must retain old saved documents' exact semantics.
    for(unsigned i=0;i<100;++i){
        repeated.strokes.resize(1+i%31);repeated.base=(i%3)*.5;
        for(unsigned j=0;j<repeated.strokes.size();++j){auto& edit=repeated.strokes[j];edit=solid;edit.strength=((i+j*7)%11)/10.;edit.erase=(j%3)==0;edit.softness=.6;edit.enabled=(j%5)!=0;}
        Field mixed(surface,repeated);
        for(auto x:{0.,.8,1.3,1.9,2.1}){auto anchor=at(surface,{x,0,0});require(close(mixed.evaluate(anchor),mixed.evaluateReference(anchor)),"Reverse composition changed opacity/erase order");}
    }
    solid.samples[0].basis={{{2,.7,0},{.2,1,0},{0,0,-1}}};
    Field sheared(surface,{surface.fingerprint(),{solid}});
    for(int y=-8;y<=8;++y)for(int x=-8;x<=8;++x){auto anchor=at(surface,{x*.5,y*.5,0});require(close(sheared.evaluate(anchor),sheared.evaluateReference(anchor)),"Footprint bounds lost sheared/reflected coverage");}
    // Incremental preparation must be equivalent to a completely fresh field,
    // including destructive edits, Undo, base changes and surface replacement.
    auto current=history;auto prior=std::make_unique<Field>(terrain,current);
    for(unsigned edit=0;edit<45;++edit){
        if(edit%5==0)current.strokes.push_back(history.strokes[edit%history.strokes.size()]);
        if(edit%5==1)current.strokes.back().strength=.17;
        if(edit%5==2)current.strokes.back().enabled=!current.strokes.back().enabled;
        if(edit%5==3)current.strokes.pop_back();
        if(edit%5==4)current.base=current.base==0?.35:0;
        auto next=std::make_unique<Field>(terrain,current,prior.get());Field fresh(terrain,current);
        require(next->buildStats().reusedStrokes>=history.strokes.size(),"Unchanged brush history was recompiled");
        for(unsigned j=0;j<35;++j){Hit h;terrain.hit({{uniform(rng),uniform(rng),100},{0,0,-1}},h);
            require(close(next->evaluate(h.anchor),fresh.evaluateReference(h.anchor)),"Incremental brush changed ordered coverage");
        }
        prior=std::move(next);
    }
    auto edited=current;edited.strokes[0].samples[0].basis[0].x+=.25;
    Field changedBasis(terrain,edited,prior.get());
    require(changedBasis.buildStats().compiledStrokes==1,"Changed brush basis reused stale preparation");
    edited.strokes[0].samples[0].view.eye.x+=1;
    Field changedView(terrain,edited,&changedBasis);
    require(changedView.buildStats().compiledStrokes==1,"Changed brush visibility reused stale preparation");
    auto changedMesh=grid;changedMesh.vertices[0].z+=1;Surface otherSurface(changedMesh);edited.surface=otherSurface.fingerprint();
    Field replaced(otherSurface,edited,&changedView);
    require(replaced.buildStats().reusedStrokes==0,"Changed mesh reused old brush patches");
    // Aggregate limits include reused history and fail without damaging the
    // previous immutable publication. Low injected limits avoid huge tests.
    Stroke bounded;bounded.radius=2;bounded.samples={sample};bounded.strength=.4;
    Document limited{surface.fingerprint(),{bounded}};
    Field retained(surface,limited);
    require(retained.buildStats().derivedDabs==1&&retained.buildStats().faceLinks==2,"Prepared history accounting");
    require(retained.buildStats().indexBytes==3*sizeof(std::size_t)+2*2*sizeof(std::uint32_t),"Contiguous face-index allocation");
    Field exact(surface,limited,nullptr,{1,2});
    require(close(exact.evaluate(sample.anchor),retained.evaluate(sample.anchor)),"Exact preparation limits rejected valid field");
    rejects([&]{Field tooManyLinks(surface,limited,nullptr,{1,1});});
    rejects([&]{Field reusedOverLimit(surface,limited,&retained,{1,1});});
    limited.strokes.push_back(bounded);
    rejects([&]{Field tooManyDabs(surface,limited,&retained,{1,4});});
    rejects([&]{Field aggregateLinks(surface,limited,&retained,{2,3});});
    require(close(retained.evaluate(sample.anchor),.4),"Failed successor damaged previous field");
    Field recovered(surface,limited,&retained,{2,4});
    require(recovered.buildStats().reusedStrokes==1&&recovered.buildStats().compiledStrokes==1,"Recovery failed to reuse complete history");
    require(close(recovered.evaluate(sample.anchor),.64),"Recovery changed paint composition");
    auto connected=path;connected.samples[1].view=connected.samples[0].view;
    const auto derived=resample(surface,connected).samples.size();
    require(derived>connected.samples.size(),"Resampling witness failed");
    rejects([&]{resample(surface,connected,derived-1);});
    Document connectedHistory{surface.fingerprint(),{connected,connected}};
    Field firstConnected(surface,{surface.fingerprint(),{connected}});
    rejects([&]{Field aggregateDerived(surface,connectedHistory,&firstConnected,{derived*2-1,8000000});});
    Field enough(surface,connectedHistory,&firstConnected,{derived*2,8000000});
    require(enough.buildStats().derivedDabs==derived*2,"Derived dabs not counted across strokes");
    require(close(enough.evaluate(sample.anchor),enough.evaluateReference(sample.anchor)),"Bounded connected replay changed coverage");
    // Sparse face ranges and disabled histories must not borrow another face's
    // links, including empty ranges following a nonempty one.
    auto disabled=limited;for(auto& s:disabled.strokes)s.enabled=false;
    Field off(surface,disabled,&recovered,{2,0});
    require(off.buildStats().faceLinks==0&&off.evaluate(sample.anchor)==0,"Disabled stroke acquired links");
    require(encode(decode(encode(connectedHistory)))==encode(connectedHistory),"Preparation limits changed stored bytes");
    std::cout<<"PASS "<<checks<<" Brush checks: surface picking, footprint, opacity, erase, replay, identity, persistence and validation\n";
}

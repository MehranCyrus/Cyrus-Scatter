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
    for(unsigned i=0;i<600;++i){Ray ray{{uniform(rng),uniform(rng),100},{0,0,-1}};Hit fast,slow;
        require(terrain.hit(ray,fast,INFINITY,&stats)==terrain.hitReference(ray,slow),"BVH/reference hit mismatch");
        require(close(fast.distance,slow.distance),"BVH/reference distance mismatch");
        require(close(field.evaluate(fast.anchor),field.evaluateReference(fast.anchor)),"Indexed/replay field mismatch");
    }
    require(stats.triangles<600*grid.faces.size()/10,"Ray index did not reduce triangle checks");
    for(std::uint64_t i=0;i<10000;++i){require(threshold(42,i)>=0&&threshold(42,i)<1,"Threshold range");require(!accepted(42,i,.25)||accepted(42,i,.75),"Mask nesting failed");require(!accepted(42,i,0)&&accepted(42,i,1),"Empty/full membership failed");}
    std::cout<<"PASS "<<checks<<" Brush checks: surface picking, footprint, opacity, erase, replay, identity, persistence and validation\n";
}

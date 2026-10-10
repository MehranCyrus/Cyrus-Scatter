#include "brush.h"
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <chrono>
using namespace cyrus::brush;
unsigned checks=0;
void check(bool v,const char* message){++checks;if(!v)throw std::runtime_error(message);}
template<class F>void rejects(F f){bool caught=false;try{f();}catch(const std::exception&){caught=true;}check(caught,"expected rejection");}
int main(){try{
 Surface s({{{-100,-100,0},{100,-100,0},{100,100,0},{-100,100,0}},{{0,1,2},{0,2,3}}});
 validateProjection(s);Document d;d.surface=s.fingerprint();
 d=paint(d,{0,0},20,false);
 Field f(s,d);check(f.queryPoint({0,0}).density==1,"center");check(f.queryPoint({21,0}).density==0,"radius");
 const auto bytes=encode(d);auto roundtrip=decode(bytes);check(encode(roundtrip)==bytes,"canonical serialization");
 d=paint(d,{0,0},5,true);Field hole(s,d);check(hole.queryPoint({0,0}).density==0,"hole");check(hole.queryPoint({10,0}).density==1,"ring");
 d=paint(d,{0,0},3,false);Field island(s,d);check(island.queryPoint({0,0}).density==1,"island in hole");check(island.queryPoint({4,0}).density==0,"hole outside island");
 Document box;box.surface=s.fingerprint();box.contours={{{-10,-10},{10,-10},{10,10},{-10,10}}};
 box.falloff.inside=4;box.falloff.outside=6;box.falloff.scale=true;box.falloff.scaleMin=.2;box.falloff.scaleMax=1.;
 Field feather(s,box);
 check(std::abs(feather.queryPoint({10,0}).density-.6)<1.e-9,"border position within ramp");
 check(std::abs(feather.queryPoint({12,0}).density-.4)<1.e-9,"outside feather");
 check(feather.queryPoint({17,0}).density==0,"outside support");
 check(feather.queryPoint({0,0}).density==1,"interior");
 check(std::abs(feather.queryPoint({12,0}).scale-.52)<1.e-9,"independent scale");
 box.falloff.densityCurve={0,0,1};Field shaped(s,box);check(std::abs(shaped.queryPoint({10,0}).density-.2)<1.e-9,"curve");
 for(int i=0;i<1000;++i){double x=(i%100-50)*.3,y=(i/100-5)*.5;double oracle=std::min(10-std::abs(x),10-std::abs(y));
   if(std::abs(x)>10||std::abs(y)>10){double a=std::max(0.,std::abs(x)-10),b=std::max(0.,std::abs(y)-10);oracle=-std::sqrt(a*a+b*b);}
   check(std::abs(shaped.signedDistance({x,y})-oracle)<1.e-9,"distance BVH against box oracle");
 }
 Metric metric=Metric::fromBasis({2,0,0},{1,3,0});auto q=metric.unmap(metric.map({3,5}));check(std::abs(q[0]-3)<1.e-9&&std::abs(q[1]-5)<1.e-9,"metric inverse");
 Document stretched;stretched.surface=s.fingerprint();stretched=paint(stretched,{0,0},10,false,metric);Field sf(s,stretched,metric);
 check(sf.queryPoint({4,0}).density==1&&sf.queryPoint({6,0}).density==0,"world radius under scaling");
 rejects([&]{auto broken=bytes;broken[0]=0;decode(broken);});rejects([&]{auto broken=bytes;broken.pop_back();decode(broken);});
 rejects([&]{auto bad=box.falloff;bad.scaleMin=2;validate(bad);});rejects([&]{paint(d,{NAN,0},1,false);});
 Surface stacked({{{0,0,0},{10,0,0},{0,10,0},{0,0,1},{10,0,1},{0,10,1}},{{0,1,2},{3,4,5}}});rejects([&]{validateProjection(stacked);});
 Surface folded({{{0,0,0},{10,0,0},{0,10,0},{0,0,1}},{{0,1,2},{2,1,3}}});rejects([&]{validateProjection(folded);});
 Surface terrain({{{-100,-100,-10},{100,-100,10},{100,100,10},{-100,100,-10}},{{0,1,2},{0,2,3}}});validateProjection(terrain);
 auto terrainDoc=roundtrip;terrainDoc.surface=terrain.fingerprint();auto lines=boundary(terrain,terrainDoc);check(!lines.empty(),"terrain border");
 for(auto line:lines)for(auto v:line)check(std::abs(v.z-v.x*.1)<.001,"border lifted to terrain");
 auto fill=Document{};fill.surface=s.fingerprint();fill.contours=domain(s);Field full(s,fill);check(full.queryPoint({99,99}).density==1,"fill receiver");
 Document large;large.surface=s.fingerprint();large=constrain(paint(large,{0,0},1000,false),domain(s));
 check(!boundary(s,large).empty(),"oversized paint retains receiver-edge feedback");
 Field largeField(s,large);check(largeField.queryPoint({99,99}).density==1,"large brush fully covers receiver");
 Document growing;growing.surface=s.fingerprint();std::vector<Point> centers;
 for(int i=0;i<120;++i){Point center{60*std::sin(i*.13),60*std::cos(i*.17)};centers.push_back(center);growing=constrain(paint(growing,center,8,false),domain(s));Field current(s,growing);
   for(auto previous:centers)check(current.queryPoint(previous).density==1,"additive paint cannot erase prior centers");}
 // Separate strokes merge into one area; additive gestures cannot remove prior coverage.
 Document scribble;scribble.surface=s.fingerprint();auto start=std::chrono::steady_clock::now();Point last{0,0};
 for(int i=0;i<400;++i){Point p{60*std::sin(i*.09),60*std::cos(i*.071)};scribble=paint(scribble,p,3,false,{},i?&last:nullptr);last=p;}
 Field dense(s,scribble);QueryStats stats;for(int i=0;i<10000;++i)dense.queryPoint({double(i%100-50),double(i/100-50)},&stats);
 double ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();
 check(stats.segments<10000*vertexCount(scribble),"indexed queries");
 std::cout<<"PASS "<<checks<<" vector assertions; 400 edits + 10000 queries "<<ms<<" ms; vertices "<<vertexCount(scribble)<<"; examined segments "<<stats.segments<<"\n";
 return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}

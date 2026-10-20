#include "brush.h"
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace cyrus::brush;
unsigned checks=0;
void check(bool v,const char* message){++checks;if(!v)throw std::runtime_error(message);}
template<class F>void rejects(F f){bool caught=false;try{f();}catch(const std::exception&){caught=true;}check(caught,"Expected rejection");}
Document empty(const Surface& s,const SurfaceAtlas& a){Document d;d.surface=s.fingerprint();d.attached=true;d.topology=a.topology();return d;}
Mesh box(){return {{{-10,-10,-10},{10,-10,-10},{10,10,-10},{-10,10,-10},{-10,-10,10},{10,-10,10},{10,10,10},{-10,10,10}},
 {{4,5,6},{4,6,7},{5,1,2},{5,2,6},{1,0,3},{1,3,2},{0,4,7},{0,7,3},{7,6,2},{7,2,3},{0,1,5},{0,5,4}}};}
Anchor hit(const Surface& s,Vec3 o,Vec3 dir){Hit h;check(s.hit({o,dir},h),"Ray must hit receiver");return h.anchor;}
Mesh sphere(){Mesh m;m.vertices.push_back({0,0,10});constexpr unsigned around=24,rows=12;
 for(unsigned i=1;i<rows;++i)for(unsigned j=0;j<around;++j){double t=3.141592653589793*i/rows,p=6.283185307179586*j/around;m.vertices.push_back({10*std::sin(t)*std::cos(p),10*std::sin(t)*std::sin(p),10*std::cos(t)});}
 const auto bottom=static_cast<unsigned>(m.vertices.size());m.vertices.push_back({0,0,-10});
 for(unsigned j=0;j<around;++j){m.faces.push_back({0,1+j,1+(j+1)%around});m.faces.push_back({bottom,1+(rows-2)*around+(j+1)%around,1+(rows-2)*around+j});}
 for(unsigned i=0;i<rows-2;++i)for(unsigned j=0;j<around;++j){auto a=1+i*around+j,b=1+i*around+(j+1)%around,c=a+around,d=b+around;m.faces.push_back({a,c,b});m.faces.push_back({b,c,d});}return m;}
int main(){try{
 Surface s(box());auto atlas=std::make_shared<SurfaceAtlas>(s);auto d=empty(s,*atlas);
 auto center=hit(s,{0,0,50},{0,0,-1});d=atlas->paint(d,center,5,false);Field f(s,d,{},atlas);
 check(f.evaluate(center)==1,"Box top center painted");check(f.evaluate(hit(s,{0,0,-50},{0,0,1}))==0,"Box bottom not painted through");
 check(f.evaluate(hit(s,{6,0,50},{0,0,-1}))==0,"Radius excludes outside");
 auto roundtrip=decode(encode(d));check(encode(roundtrip)==encode(d),"Surface vector codec roundtrip");
 auto edge=hit(s,{9,0,50},{0,0,-1});auto crossEdge=atlas->paint(d,edge,4,false);Field edgeField(s,crossEdge,{},atlas);
 check(edgeField.evaluate(hit(s,{50,0,8},{-1,0,0}))==1,"Geodesic footprint crosses box edge");
 check(edgeField.evaluate(hit(s,{50,0,5},{-1,0,0}))==0,"Unfolded box distance excludes radius exterior");
 auto erased=atlas->paint(crossEdge,center,2,true);Field hole(s,erased,{},atlas);check(hole.evaluate(center)==0,"Surface erase hole");
 auto fill=atlas->fill(d,true);Field full(s,fill,{},atlas);for(unsigned i=0;i<s.mesh().faces.size();++i)check(full.evaluate({i,{.2,.3,.5}})==1,"Fill every face");
 check(atlas->boundary(fill).empty(),"Closed full box has no false triangulation borders");
 check(!atlas->boundary(d).empty(),"Partial coverage border");check(atlas->fill(d,false).faces.empty(),"Clear removes every face");
 auto feather=d;feather.falloff.inside=1;feather.falloff.outside=1;feather.falloff.scale=true;feather.falloff.scaleMin=.2;Field soft(s,feather,{},atlas);
 auto q=soft.query(hit(s,{5,0,50},{0,0,-1}));check(std::abs(q.density-.5)<.04,"Feather at independent circle border");check(std::abs(q.scale-.6)<.04,"Independent scale feather");
 Surface sheets({{{-10,-10,0},{10,-10,0},{10,10,0},{-10,10,0},{-10,-10,-.01},{10,-10,-.01},{10,10,-.01},{-10,10,-.01}},{{0,1,2},{0,2,3},{4,5,6},{4,6,7}}});
 auto sa=std::make_shared<SurfaceAtlas>(sheets);auto sd=sa->paint(empty(sheets,*sa),{0,{.25,.25,.5}},6,false);Field sheetField(sheets,sd,{},sa);
 check(sheetField.evaluate({0,{.25,.25,.5}})==1&&sheetField.evaluate({2,{.25,.25,.5}})==0,"Nearby disconnected sheet stays untouched");
 auto prior=encode(d);rejects([&]{atlas->paint(d,center,NAN,false);});check(encode(d)==prior,"Failed edit retains exact canonical coverage");
 auto curves=atlas->contours(d);check(curves.size()==1,"Box surface border exports as one closed curve");
 auto imported=atlas->importCurves(empty(s,*atlas),curves,.001,false);Field importedField(s,imported,{},atlas);
 check(importedField.evaluate(center)==1&&importedField.evaluate(hit(s,{0,0,-50},{0,0,1}))==0,"Surface contour import selects the bounded region on box");
 rejects([&]{auto bad=prior;bad.pop_back();decode(bad);});
 Surface ball(sphere());auto ba=std::make_shared<SurfaceAtlas>(ball);auto pole=hit(ball,{0,0,50},{0,0,-1});auto bd=ba->paint(empty(ball,*ba),pole,5,false);Field bf(ball,bd,{},ba);
 check(bf.evaluate(pole)==1,"Sphere pole painted");
 auto ballLoops=ba->contours(bd);check(ballLoops.size()==1,"Sphere border joins across mesh seams");
 auto ballImported=ba->importCurves(empty(ball,*ba),ballLoops,.001,false);Field bif(ball,ballImported,{},ba);
 check(bif.evaluate(pole)==1&&bif.evaluate(hit(ball,{0,0,-50},{0,0,1}))==0,"Curved spline roundtrip retains sphere cap and opposite-side isolation");
 for(double angle:{.1,.3,.4,.7,1.,2.,3.}){Vec3 ray{std::sin(angle),0,std::cos(angle)};check((bf.evaluate(hit(ball,ray*30,ray*(-1)))>0)==(angle<.5),"Sphere great-circle distance oracle away from tolerance band");}
 auto from=hit(ball,{30,0,0},{-1,0,0}),to=hit(ball,{0,30,0},{0,-1,0});auto stroke=ba->paint(empty(ball,*ba),from,1,false);stroke=ba->paint(stroke,to,1,false,&from);Field strokeField(ball,stroke,{},ba);
 check(strokeField.evaluate(hit(ball,{30,30,0},{-1,-1,0}))==1,"Continuous stroke follows sphere surface instead of interior chord");
 check(strokeField.evaluate(hit(ball,{-30,-30,0},{1,1,0}))==0,"Connected curved stroke does not affect opposite sphere side");
 auto huge=ba->paint(empty(ball,*ba),pole,1000,false);check(ba->boundary(huge).empty(),"Large geodesic brush covers closed receiver without triangulation borders");
 auto basis=identityBasis;basis[2]={0,0,3};auto scaled=std::make_shared<SurfaceAtlas>(s,basis);auto scaledDoc=scaled->paint(empty(s,*scaled),edge,4,false);Field scaledField(s,scaledDoc,{},scaled);
 check(scaledField.evaluate(hit(s,{50,0,9.5},{-1,0,0}))==1&&scaledField.evaluate(hit(s,{50,0,8.5},{-1,0,0}))==0,"Curved radius includes receiver Z scale");
 auto reflectedBasis=identityBasis;reflectedBasis[0]={-1,0,0};auto reflected=std::make_shared<SurfaceAtlas>(s,reflectedBasis);auto reflectedDoc=reflected->paint(empty(s,*reflected),edge,4,false);Field reflectedField(s,reflectedDoc,{},reflected);
 check(reflectedField.evaluate(hit(s,{50,0,8},{-1,0,0}))==1&&reflectedField.evaluate(hit(s,{50,0,5},{-1,0,0}))==0,"Mirrored receiver preserves physical radius");
 auto noXY=transfer(d,s,{0,0,0,0},1,1000);check(noXY.faces.size()==d.faces.size(),"Attached transfer does not depend on XY footprint");
 rejects([&]{transfer(d,ball,{0,0,0,0},1,1);});
 auto corrupted=d;corrupted.topology=0;rejects([&]{encode(corrupted);});
 auto invalidMesh=box();invalidMesh.faces.push_back(invalidMesh.faces[0]);rejects([&]{Surface invalid(invalidMesh);SurfaceAtlas rejected(invalid);});
 auto erasedAll=atlas->paint(d,center,1000,true);check(erasedAll.faces.empty(),"Oversized erase clears closed receiver");
 auto add=atlas->combine(erased,d,true);Field addField(s,add,{},atlas);check(addField.evaluate(center)==1,"Add spline snapshot fills erased hole");
 auto bigMesh=box();for(auto& v:bigMesh.vertices)v=v*10;Surface big(bigMesh);auto bigAtlas=std::make_shared<SurfaceAtlas>(big);auto bigHit=hit(big,{400,0,90},{-1,0,0});auto small=bigAtlas->paint(empty(big,*bigAtlas),bigHit,10,false);Field smallField(big,small,{},bigAtlas);check(smallField.evaluate(bigHit)==1,"Small brush on large coarse face refines without depth rejection");
 auto reserved=surfaceReservedBytes();{SurfaceAtlas temporary(s);check(surfaceReservedBytes()>reserved,"Retained mesh admission accounted");}check(surfaceReservedBytes()==reserved,"Retained admission released by destructor");
 reserved=surfaceReservedBytes();rejects([&]{atlas->importCurves(d,{{{0,0,100},{1,0,100},{0,1,100}}},.001,false);});check(surfaceReservedBytes()==reserved,"Failed curved import releases staged admission");
 std::cout<<"PASS "<<checks<<" surface Paint assertions\n";return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}

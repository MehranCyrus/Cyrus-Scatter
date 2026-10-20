#include "live_session.h"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
using namespace cpl;
unsigned checks=0;
void check(bool v,const char* message){++checks;if(!v)throw std::runtime_error(message);}
template<class F>void rejects(F f){bool rejected=false;try{f();}catch(const std::exception&){rejected=true;}check(rejected,"Invalid custom proxy was accepted");}
Mesh sphere(){Mesh m;constexpr unsigned n=32,rings=15;constexpr double radius=.01598299493,pi=3.141592653589793;m.vertices.push_back({0,0,radius});
 for(unsigned y=1;y<=rings;++y)for(unsigned x=0;x<n;++x){double a=pi*y/16,b=2*pi*x/n;m.vertices.push_back({radius*std::sin(a)*std::cos(b),radius*std::sin(a)*std::sin(b),radius*std::cos(a)});}
 unsigned bottom=unsigned(m.vertices.size());m.vertices.push_back({0,0,-radius});
 for(unsigned x=0;x<n;++x){unsigned next=(x+1)%n;m.faces.push_back({0,1+x,1+next});m.faces.push_back({bottom,1+(rings-1)*n+next,1+(rings-1)*n+x});for(unsigned y=0;y+1<rings;++y){unsigned a=1+y*n+x,b=1+y*n+next,c=a+n,d=b+n;m.faces.push_back({a,c,b});m.faces.push_back({b,c,d});}}return m;
}
Mesh plane(){Mesh m;for(unsigned y=0;y<5;++y)for(unsigned x=0;x<5;++x)m.vertices.push_back({-1.127207634+2.254415268*x/4,-.711496883+1.422993766*y/4,0});for(unsigned y=0;y<4;++y)for(unsigned x=0;x<4;++x){unsigned a=y*5+x;m.faces.push_back({a,a+1,a+6});m.faces.push_back({a,a+6,a+5});}return m;}
void same(const std::vector<BodyState>& a,const std::vector<BodyState>& b){check(a.size()==b.size(),"Restored body count changed");for(unsigned i=0;i<a.size();++i){check(encodeRow(a[i].row)==encodeRow(b[i].row),"Restored pose changed");check(length(a[i].velocity-b[i].velocity)<1e-12&&length(a[i].spin-b[i].spin)<1e-12&&a[i].sleeping==b[i].sleeping,"Restored motion changed");}}
int main(int argc,char** argv){Json report;try{
 auto render=sphere(),ground=plane();check(render.vertices.size()==482,"Sphere32 fixture differs from captured model topology");
 rejects([&]{proxySource(render,ground,.002);});auto coarse=boxMesh({.016,.016,.016});auto displaced=coarse;for(auto& p:displaced.vertices)p.x+=1;rejects([&]{proxySource(render,displaced,.002);});
 auto valid=proxySource(render,coarse,.002);check(valid.hulls[0].size()==8&&valid.render.vertices.size()==482,"Valid simplified proxy changed");
 auto leaf=ground;for(auto& p:leaf.vertices)p=p*.03;auto flat=proxySource(leaf,leaf,.002);check(flat.hulls[0].size()==50,"Valid thin custom proxy rejected");
 Input in;in.settings.maxBodies=128;in.settings.radius=.001;in.settings.scaleMin=.8;in.settings.scaleMax=1.2;in.sources={proxySource(render,render,.002,true)};in.colliders={ground};
 report["flat"]=Json::array();
 for(double friction:{0.,.6})for(double grip:{0.,.8}){in.settings.friction=friction;in.settings.stickiness=grip;auto world=joltWorld(in);
  for(unsigned y=0;y<8;++y)for(unsigned x=0;x<8;++x){Birth b;b.id=1+y*8+x;b.gesture=1;b.position={-.35+x*.1,-.35+y*.1,.4};b.scale=.8+.4*(b.id%11)/10;world->add(b);}
  double penetration=0;unsigned settledAt=0,peakStep=0;
  for(unsigned step=1;step<=3600;++step){world->step();auto states=world->states();bool asleep=true;for(auto& s:states){asleep&=s.sleeping;for(auto p:render.vertices){double depth=-(rotate(s.row.rotation,p*s.row.scale)+s.row.position).z;if(depth>penetration){penetration=depth;peakStep=step;}}}if(asleep){settledAt=step;break;}}
  std::cout<<"flat friction="<<friction<<" grip="<<grip<<" penetration="<<penetration<<" peak_step="<<peakStep<<" slept_at="<<settledAt<<std::endl;
  // Initial discrete contact can overlap briefly; distinguish that from a
  // body passing through the plane or retaining penetration after settling.
  check(settledAt>0,"Flat spheres never slept");check(penetration<.005,"Transient flat contact exceeds 5 mm");auto before=world->states();double finalPenetration=0;for(auto& s:before)for(auto p:render.vertices)finalPenetration=std::max(finalPenetration,-(rotate(s.row.rotation,p*s.row.scale)+s.row.position).z);check(finalPenetration<.001,"Settled sphere penetrates floor by more than 1 mm");for(int i=0;i<120;++i)world->step();same(before,world->states());
  report["flat"].push_back({{"friction",friction},{"stickiness",grip},{"bodies",64},{"slept_at_step",settledAt},{"maximum_transient_penetration_m",penetration},{"settled_penetration_m",finalPenetration}});
 }
 // A finite plane must not acquire invisible walls. Track the edge crossing,
 // rather than treating any negative Z after leaving the receiver as tunnelling.
 in.settings.friction=0;in.settings.stickiness=0;auto world=joltWorld(in);Birth b;b.id=b.gesture=1;b.position={.95,0,.018};b.velocity={1,0,0};world->add(b);bool crossed=false,fell=false;double minBefore=1e100;
 for(unsigned step=0;step<360;++step){world->step();auto s=world->states()[0];if(s.row.position.x>1.15)crossed=true;else minBefore=std::min(minBefore,s.row.position.z);if(s.row.position.z<-.2){check(crossed,"Sphere fell through the plane before crossing its edge");fell=true;break;}}
 check(crossed&&fell&&minBefore>-.001,"Finite receiver edge behavior failed");report["edge"]={{"crossed",crossed},{"fell_after_crossing",fell},{"minimum_centre_before_crossing_m",minBefore}};
 // Continuous gestures, missed rays, full-motion Undo/Redo and durable replay.
 in.settings.friction=.6;ContinuousCore core(in,ground);core.beginGesture();core.sample({-.3,0,0},{0,0,1},true);core.sample({.3,0,0},{0,0,1},true);core.endGesture();core.advance(10);unsigned count=unsigned(core.view().bodies.size());check(core.view().active>0,"Continuous case was already sleeping");core.beginGesture();core.sample({0,.2,0},{0,0,1},true);core.endGesture();check(core.view().bodies.size()>count,"Could not emit while earlier bodies were moving");core.advance(10);auto pending=core.view().bodies;core.undoGesture();check(core.view().bodies.size()==count,"Undo did not remove second gesture");core.redoGesture();same(pending,core.view().bodies);
 auto archive=core.archive();ContinuousCore restored(in,ground);restored.recover(archive);same(core.view().bodies,restored.view().bodies);auto before=core.view();core.beginGesture();core.sample({3,3,0},{0,0,1},false);core.endGesture();check(core.view().bodies.size()==before.bodies.size()&&core.view().undo==before.undo,"Outside stroke created bodies/history");
 core.finish();for(unsigned i=0;i<30&&!core.isDone();++i)core.advance(120);check(core.isDone()&&core.view().settled,"Continuous sphere Finish failed");check(core.view().lost==0,"Continuous spheres were lost through the surface");
 report["continuous"]={{"bodies",core.view().bodies.size()},{"finished",core.isDone()},{"lost",core.view().lost}};report["checks"]=checks;report["pass"]=true;std::cout<<"PASS "<<checks<<" collision checks\n";
 }catch(const std::exception& e){report["pass"]=false;report["checks"]=checks;report["error"]=e.what();std::cerr<<e.what()<<'\n';}
 if(argc>1)std::ofstream(argv[1])<<report.dump(2)<<'\n';return report["pass"].get<bool>()?0:1;}

#include "live_session.h"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
#include <limits>
using namespace cpl;
unsigned checks=0;
void check(bool value,const char* message){++checks;if(!value)throw std::runtime_error(message);}
template<class F>void rejects(F f){bool rejected=false;try{f();}catch(const std::exception&){rejected=true;}check(rejected,"Expected rejection");}
constexpr double pi=3.141592653589793;
Mesh terrain(const std::string& kind,double angle=0){
 Mesh m;unsigned count=24;double half=4;
 for(unsigned y=0;y<=count;++y)for(unsigned x=0;x<=count;++x){double a=-half+2*half*x/count,b=-half+2*half*y/count,z=0;
  if(kind=="slope")z=std::tan(angle*pi/180)*a;
  else if(kind=="hills")z=.35*std::sin(a*1.8)*std::cos(b*1.4);
  else if(kind=="ridge")z=1.-.65*std::abs(a)+.08*std::sin(b*3);
  else if(kind=="valley")z=.45*std::abs(a)+.12*std::sin(b*2);
  else if(kind=="rough")z=.35*std::sin(a*1.5)+.16*std::sin(a*5+b*3)+.08*std::cos(a*9-b*7);
  else if(kind=="terraces")z=.18*std::floor((a+4)*2)+.05*std::sin(b*4);
  m.vertices.push_back({a,b,z});
 }
 for(unsigned y=0;y<count;++y)for(unsigned x=0;x<count;++x){unsigned a=y*(count+1)+x,b=a+1,c=a+count+1,d=c+1;
  if(kind=="hole"&&x>=10&&x<14&&y>=10&&y<14)continue;
  m.faces.push_back({a,b,d});m.faces.push_back({a,d,c});}
 return m;
}
Source rounded(){Mesh mesh;mesh.vertices.push_back({0,0,.04});for(unsigned y=1;y<8;++y)for(unsigned x=0;x<12;++x){double a=pi*y/8,b=2*pi*x/12;mesh.vertices.push_back({.04*std::sin(a)*std::cos(b),.04*std::sin(a)*std::sin(b),.04*std::cos(a)});}mesh.vertices.push_back({0,0,-.04});
 for(unsigned x=0;x<12;++x){mesh.faces.push_back({0,1+x,1+(x+1)%12});mesh.faces.push_back({73+x,85,73+(x+1)%12});}
 for(unsigned y=0;y<6;++y)for(unsigned x=0;x<12;++x){unsigned a=1+y*12+x,b=1+y*12+(x+1)%12,c=a+12,d=b+12;mesh.faces.push_back({a,c,d});mesh.faces.push_back({a,d,b});}return proxySource(mesh,mesh,.002,true);}
Input input(const Mesh& mesh,double friction,double grip,bool ball=false){Input in;in.settings.friction=friction;in.settings.stickiness=grip;in.settings.bounce=0;in.settings.damping=0;in.settings.scaleMin=in.settings.scaleMax=1;in.settings.radius=.001;in.settings.height=.15;in.settings.maxBodies=100;in.sources={ball?rounded():boxSource({.035,.025,.005})};in.colliders={mesh};return in;}
void same(const std::vector<BodyState>& a,const std::vector<BodyState>& b){check(a.size()==b.size(),"State count mismatch");for(unsigned i=0;i<a.size();++i){check(encodeRow(a[i].row)==encodeRow(b[i].row),"Pose mismatch");check(length(a[i].velocity-b[i].velocity)<1e-12&&length(a[i].spin-b[i].spin)<1e-12&&a[i].sleeping==b[i].sleeping,"Motion state mismatch");}}
Json runSlope(double angle,double friction,double grip,bool ball){auto mesh=terrain("slope",angle);auto in=input(mesh,friction,grip,ball);auto world=joltWorld(in);Birth birth;birth.id=birth.gesture=1;birth.position={0,0,.15};double r=-angle*pi/180;birth.rotation={0,std::sin(r/2),0,std::cos(r/2)};world->add(birth);double penetration=0;Surface surface(mesh);
 for(unsigned i=0;i<480;++i){world->step();auto row=world->states()[0].row;for(auto p:in.sources[0].render.vertices){auto v=rotate(row.rotation,p)+row.position;Hit hit;if(surface.hit({v.x,v.y,100},{0,0,-1},hit))penetration=std::max(penetration,hit.point.z-v.z);}}
 auto state=world->states()[0];double drift=std::abs(state.row.position.x)/std::cos(angle*pi/180);
 check(std::isfinite(drift)&&std::isfinite(length(state.velocity)),"Non-finite slope result");
 if(penetration>=.005)throw std::runtime_error("Slope penetration angle="+std::to_string(angle)+" friction="+std::to_string(friction)+" grip="+std::to_string(grip)+" ball="+std::to_string(ball)+" penetration="+std::to_string(penetration));
 check(penetration<.005,"Slope penetration exceeds 5 mm vertical tolerance");
 return {{"angle",angle},{"friction",friction},{"grip",grip},{"ball",ball},{"drift_m",drift},{"speed",length(state.velocity)},{"spin",length(state.spin)},{"penetration_vertical_m",penetration},{"row",encodeRow(state.row)}};
}
int main(int argc,char** argv){Json report;try{
 if(argc>2&&std::string(argv[2])=="trace"){auto in=input(terrain("slope",30),.6,.5,true);auto world=joltWorld(in);Birth birth;birth.id=birth.gesture=1;birth.position={0,0,.15};birth.rotation={0,std::sin(-pi/12),0,std::cos(-pi/12)};world->add(birth);for(unsigned i=0;i<480;++i){world->step();auto state=world->states()[0];report.push_back({{"step",i},{"row",encodeRow(state.row)},{"velocity",{state.velocity.x,state.velocity.y,state.velocity.z}},{"spin",length(state.spin)}});}std::ofstream(argv[1])<<report.dump(2);return 0;}
 {auto in=input(terrain("slope"),.6,.75);auto encoded=encodeInput(in);check(encoded["version"]==2,"Input version missing");check(decodeInput(encoded).settings.stickiness==.75,"Grip roundtrip");encoded["settings"]["stickiness"]=-.1;rejects([&]{decodeInput(encoded);});encoded["settings"]["stickiness"]=1.01;rejects([&]{decodeInput(encoded);});encoded["settings"].erase("stickiness");rejects([&]{decodeInput(encoded);});encoded["version"]=1;check(decodeInput(encoded).settings.stickiness==0,"Old completed input not zero grip");in.settings.stickiness=std::numeric_limits<double>::quiet_NaN();rejects([&]{validate(in);});}
 report["slopes"]=Json::array();
 for(bool ball:{false,true})for(double angle:{0.,15.,30.,45.,60.,75.})for(double friction:{0.,.2,.6,2.})for(double grip:{0.,.25,.5,1.})report["slopes"].push_back(runSlope(angle,friction,grip,ball));
 // Assert useful grip, not merely finite output. High grip must retain both
 // source shapes on these slopes where the unassisted case leaves the support.
 for(bool ball:{false,true})for(double angle:{45.,60.,75.}){double off=-1,on=-1,previous=1e100;
  for(auto& row:report["slopes"])if(row["ball"]==ball&&row["angle"]==angle&&row["friction"]==.6){double drift=row["drift_m"];if(row["grip"]==0)off=drift;if(row["grip"]==1)on=drift;check(drift<=previous+.2,"Grip matrix regressed materially at a higher setting");previous=drift;}
  check(off>1&&on<.25&&on<off*.1,"High grip did not materially retain the sloped body");}
 // Vertical walls do not receive surface grip; upward departure is free too.
 for(bool wall:{false,true}){auto a=input(terrain("slope"),.6,0,true),b=a;b.settings.stickiness=1;
  if(wall){a.colliders={boxMesh({.1,4,4},{0,0,0})};b.colliders=a.colliders;}
  auto x=joltWorld(a),y=joltWorld(b);Birth birth;birth.id=birth.gesture=1;birth.position=wall?Vec{-.2,0,2}:Vec{0,0,.041};birth.velocity=wall?Vec{3,0,0}:Vec{0,0,2};birth.spin={3,2,1};x->add(birth);y->add(birth);
  for(unsigned i=0;i<(wall?100u:20u);++i){x->step();y->step();same(x->states(),y->states());}}
 // Supported bodies remain dynamic and can be displaced by another impact.
 {auto in=input(terrain("slope"),.6,1,true);auto world=joltWorld(in);Birth target;target.id=target.gesture=1;target.position={0,0,.15};world->add(target);for(unsigned i=0;i<240;++i)world->step();auto before=world->states()[0].row.position;
  Birth impact;impact.id=2;impact.gesture=2;impact.position={-.5,0,.045};impact.velocity={15,0,0};world->add(impact);for(unsigned i=0;i<120;++i)world->step();check(length(world->states()[0].row.position-before)>.02,"Surface grip incorrectly pinned the target");}
 // No support means no added damping, including contacts between dynamic bodies.
 {auto a=input(terrain("slope"),.6,0,true),b=a;b.settings.stickiness=1;a.colliders.clear();b.colliders.clear();auto x=joltWorld(a),y=joltWorld(b);for(unsigned i=0;i<2;++i){Birth birth;birth.id=i+1;birth.gesture=1;birth.position={i*.06,0,4};birth.velocity={1,2,-.2};birth.spin={3,4,2};x->add(birth);y->add(birth);}for(int i=0;i<90;++i){x->step();y->step();same(x->states(),y->states());}}
 // Exact in-memory continuation and canonical recovery on uneven terrain.
 report["terrains"]=Json::array();
 for(auto kind:{"hills","ridge","valley","rough","terraces","hole"}){
  auto mesh=terrain(kind);auto in=input(mesh,.6,.8);Surface surface(mesh);ContinuousCore core(in,mesh);
  for(int i=0;i<12;++i){double x=-1.4+(i%4)*.85,y=-1.+(i/4)*.9;Hit hit;if(!surface.hit({x,y,20},{0,0,-1},hit))continue;core.beginGesture();core.sample(hit.point,hit.normal,true);core.endGesture();core.advance(20);}
  for(int i=0;i<5;++i)core.advance(120);auto before=core.view();auto saved=core.archive();ContinuousCore restored(in,mesh);restored.recover(saved);same(before.bodies,restored.view().bodies);
  core.undoGesture();restored.undoGesture();same(core.view().bodies,restored.view().bodies);core.redoGesture();restored.redoGesture();same(core.view().bodies,restored.view().bodies);
  core.advance(120);restored.advance(120);same(core.view().bodies,restored.view().bodies);
  unsigned count=unsigned(core.view().bodies.size());core.beginGesture();core.sample({12,12,0},{0,0,1},false);core.endGesture();check(core.view().bodies.size()==count,"Outside terrain emitted");
  double penetration=0;for(auto& body:core.view().bodies){check(std::isfinite(length(body.row.position)),"Invalid terrain result");for(auto p:in.sources[0].render.vertices){auto v=rotate(body.row.rotation,p)+body.row.position;Hit hit;if(surface.hit({v.x,v.y,100},{0,0,-1},hit))penetration=std::max(penetration,hit.point.z-v.z);}}
  report["terrains"].push_back({{"kind",kind},{"bodies",count},{"lost",core.view().lost},{"max_penetration_vertical_m",penetration},{"recovery_bytes",saved.dump().size()}});
  check(penetration<.001,"Terrain penetration exceeds 1 mm vertical tolerance");
 }
 report["finish_slopes"]=Json::array();
 for(bool ball:{false,true})for(double angle:{15.,30.,45.,60.,75.}){auto mesh=terrain("slope",angle);auto in=input(mesh,.6,1,ball);ContinuousCore core(in,mesh);core.beginGesture();core.sample({0,0,0},normalized({-std::tan(angle*pi/180),0,1}),true);core.endGesture();core.finish();bool timeout=false;try{for(unsigned i=0;i<40&&!core.isDone();++i)core.advance(120);}catch(const std::exception&){timeout=true;}
  report["finish_slopes"].push_back({{"ball",ball},{"angle",angle},{"done",core.isDone()},{"timeout",timeout},{"step",core.stepCount()},{"active",core.view().active}});
  // The 0.1.7 footprint-clear birth removes the formerly embedded 75-degree
  // rounded-body witness. It must now Finish, rather than preserve that defect.
  check(core.isDone()&&!timeout,"High-grip slope did not Finish within its work budget");
 }
 // Qualify explicit work-bound/Freeze behavior independently of a bad birth.
 {auto mesh=terrain("slope");auto in=input(mesh,.6,1,true);in.settings.maxSteps=in.settings.quietSteps=1;ContinuousCore core(in,mesh);core.beginGesture();core.sample({0,0,0},{0,0,1},true);core.endGesture();core.finish();bool timeout=false;try{core.advance(2);}catch(const std::exception&){timeout=true;}check(timeout&&!core.isDone()&&core.view().bodies.size()==1,"Finish bound did not retain the preview");core.freeze();check(core.isDone()&&!core.view().settled,"Timeout Freeze failed");report["forced_timeout"]={{"retained",true},{"freeze",true}};}
 report["checks"]=checks;report["pass"]=true;
 if(argc>1){std::ofstream f(argv[1]);f<<report.dump(2)<<'\n';}
 std::cout<<"PASS "<<checks<<" grip/terrain checks\n";return 0;
 }catch(const std::exception& e){report["pass"]=false;report["checks"]=checks;report["error"]=e.what();if(argc>1){std::ofstream f(argv[1]);f<<report.dump(2)<<'\n';}std::cerr<<e.what()<<" after "<<checks<<" checks\n";return 1;}}

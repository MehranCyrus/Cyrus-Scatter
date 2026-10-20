#include "live_session.h"
#include <iostream>
#include <chrono>
#include <thread>
#include <atomic>
using namespace cpl;
unsigned checks=0;
void check(bool b,const char* message){++checks;if(!b)throw std::runtime_error(message);}
template<class F>void rejects(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed,"Expected bounded rejection");}
Input fixture(){Input in;in.settings.radius=.000001;in.settings.height=.4;in.settings.scaleMin=1;in.settings.scaleMax=1;in.sources={boxSource({.05,.025,.002})};in.colliders={boxMesh({2,2,.1},{0,0,-.1})};return in;}
void same(const LiveView& a,const LiveView& b){check(a.step==b.step&&a.bodies.size()==b.bodies.size(),"World count/time changed across Undo");for(std::size_t i=0;i<a.bodies.size();++i){auto& x=a.bodies[i];auto& y=b.bodies[i];check(encodeRow(x.row)==encodeRow(y.row),"Undo did not restore exact poses");check(length(x.velocity-y.velocity)<1e-12&&length(x.spin-y.spin)<1e-12&&x.sleeping==y.sleeping,"Undo did not restore velocities/sleep");}}
void steps(ContinuousCore& c,unsigned n){while(n){auto count=std::min(n,120u);c.advance(count);n-=count;}}
void stroke(ContinuousCore& c,Vec p){c.beginGesture();c.sample(p,{0,0,1},true);c.endGesture();}
int main(){try{
 auto in=fixture();auto receiver=in.colliders[0];
 {ContinuousCore c(in,receiver);stroke(c,{});steps(c,15);auto before=c.view();check(before.active>0,"Fixture must still move before next stroke");
  stroke(c,{});steps(c,120);check(c.view().bodies.size()==2,"Second moving stroke was rejected");auto after=c.view();auto high=c.view().nextId;
  c.undoGesture();same(before,c.view());check(c.view().nextId==high,"Undo reused artist IDs");c.redoGesture();same(after,c.view());
  for(int i=0;i<12;++i){stroke(c,{-.5+i*.08,.5,0});steps(c,3);}check(c.view().undo==14,"Continuous gesture history missing");
  auto saved=c.archive();ContinuousCore recovered(in,receiver);recovered.recover(saved);same(c.view(),recovered.view());
  c.undoGesture();recovered.undoGesture();same(c.view(),recovered.view());
  auto undone=c.archive();ContinuousCore undoneRecovery(in,receiver);undoneRecovery.recover(undone);undoneRecovery.redoGesture();recovered.redoGesture();same(recovered.view(),undoneRecovery.view());
  c.beginGesture();c.sample({0,1,0},{0,0,1},false);c.endGesture();check(c.view().undo==13,"Empty stroke created Undo");
  check(c.view().redo==1,"Empty stroke discarded Redo");
  c.beginGesture();c.sample({.4,.4,0},{0,0,1},true);auto next=c.view().nextId;c.cancelGesture();check(c.view().nextId==next&&c.view().undo==13,"Cancel gesture lost earlier strokes or rewound IDs");
 }
 {auto solid=in;solid.sources={boxSource({.05,.05,.05})};solid.settings.bounce=.5;ContinuousCore c(solid,receiver);
  stroke(c,{});steps(c,300);auto before=c.view();auto baseline=c.archive();ContinuousCore control(solid,receiver);control.recover(baseline);
  stroke(c,{.07,0,0});steps(c,240);steps(control,240);
  check(length(c.view().bodies[0].row.position-control.view().bodies[0].row.position)>1e-5,"Coupled fixture did not move an earlier body");
  auto after=c.view();c.undoGesture();same(before,c.view());c.redoGesture();same(after,c.view());
  c.undoGesture();stroke(c,{-.2,0,0});steps(c,50);check(c.view().redo==0,"New accepted stroke retained old Redo branch");
  auto branch=c.archive();ContinuousCore recovered(solid,receiver);recovered.recover(branch);same(c.view(),recovered.view());
  check(branch.at("undo")[0].contains("birth_ids")&&!branch.at("undo")[0].contains("births"),"Recovery duplicates full birth history");
  branch["solver"]="wrong-build";rejects([&]{recovered.recover(branch);});same(c.view(),recovered.view());
 }
 {auto holed=in;holed.colliders={boxMesh({.5,2,.1},{-1,0,-.1}),boxMesh({.5,2,.1},{1,0,-.1})};
  Mesh holedReceiver=holed.colliders[0];auto right=holed.colliders[1];auto offset=unsigned(holedReceiver.vertices.size());holedReceiver.vertices.insert(holedReceiver.vertices.end(),right.vertices.begin(),right.vertices.end());for(auto f:right.faces)holedReceiver.faces.push_back({f[0]+offset,f[1]+offset,f[2]+offset});
  ContinuousCore c(holed,holedReceiver);stroke(c,{});check(c.view().bodies.empty()&&c.view().skipped==1,"Hole accepted an unsupported candidate");stroke(c,{-1,0,0});steps(c,500);check(c.view().bodies.size()==1&&c.view().lost==0,"Solid part of holed receiver lost body");
 }
 {auto edge=in;edge.settings.radius=.3;ContinuousCore c(edge,receiver);for(int i=0;i<30;++i)stroke(c,{1.99,0,0});check(c.view().skipped>0&&c.view().bodies.size()>0,"Partial brush footprint did not clip");auto before=c.view().bodies.size();
  c.beginGesture();c.sample({100,0,0},{0,0,1},false);c.sample({-1.5,0,0},{0,0,1},true);c.sample({100,0,0},{0,0,1},false);c.endGesture();check(c.view().bodies.size()==before+1,"Outside gap bridged or rejected valid re-entry");
  c.beginGesture();c.sample({100,0,0},{0,0,1},true);c.endGesture();check(c.view().bodies.size()==before+1,"Off-surface birth was accepted");
 }
 {auto empty=in;empty.colliders={boxMesh({.1,.1,.1},{0,0,-.1})};ContinuousCore c(empty,receiver);stroke(c,{1,0,0});steps(c,240);check(c.view().bodies.empty()&&c.view().lost==1,"Falling body was not removed");
  c.finish();steps(c,120);check(c.view().done&&c.view().settled,"Lost body prevented Finish");
  c.undoGesture();check(c.view().lost==0,"Undo failed to restore removal history");c.redoGesture();check(c.view().lost==1&&c.view().bodies.empty(),"Redo lost removal state");
  auto lower=empty;lower.colliders.push_back(boxMesh({2,2,.1},{0,0,-3.1}));ContinuousCore supported(lower,receiver);stroke(supported,{1,0,0});steps(supported,900);check(supported.view().bodies.size()==1&&supported.view().lost==0,"Lower support was erased by lost-body policy");check(supported.view().bodies[0].row.position.z>-3.01,"Body penetrated lower floor");
 }
 {auto limited=in;limited.settings.maxBodies=1;ContinuousCore c(limited,receiver);stroke(c,{});c.beginGesture();rejects([&]{c.sample({.5,0,0},{0,0,1},true);});check(c.view().bodies.size()==1,"Admission destroyed earlier pending body");c.endGesture();c.freeze();check(c.view().done&&!c.view().settled,"Freeze claimed settled");}
 {ContinuousCore c(in,receiver);c.setHistoryLimit(1);rejects([&]{c.beginGesture();});check(c.view().bodies.empty(),"History failure changed world");}
 {auto tiny=in;tiny.settings.maxSteps=2;tiny.settings.quietSteps=1;ContinuousCore c(tiny,receiver);stroke(c,{});steps(c,10);check(c.view().step==10,"Live work inherited the Finish timeout");c.finish();rejects([&]{steps(c,3);});c.freeze();check(c.view().bodies.size()==1,"Finish timeout lost preview");}
 {std::atomic<unsigned> recordings=0;LiveSession worker(in,receiver,1,1,{},[&](const Json&){++recordings;});
  auto seq=worker.send(LiveCommandKind::Begin);worker.send(LiveCommandKind::Sample,{},{0,0,1},true);seq=worker.send(LiveCommandKind::End);check(worker.wait(seq),"Worker commands timed out");
  auto a=worker.view();std::this_thread::sleep_for(std::chrono::milliseconds(200));auto b=worker.view();check(b->step>a->step&&b->bodies.size()==1,"Simulation depended on host/timer callbacks");
  worker.send(LiveCommandKind::Begin);worker.send(LiveCommandKind::Sample,{.2,0,0},{0,0,1},true);seq=worker.send(LiveCommandKind::End);check(worker.wait(seq)&&worker.view()->bodies.size()==2,"Worker rejected continuous birth");
  seq=worker.send(LiveCommandKind::Pause);check(worker.wait(seq),"Pause timed out");auto paused=worker.view()->step;std::this_thread::sleep_for(std::chrono::milliseconds(100));check(worker.view()->step==paused,"Paused worker advanced");
  seq=worker.send(LiveCommandKind::Undo);check(worker.wait(seq)&&worker.view()->bodies.size()==1,"Worker Undo failed");seq=worker.send(LiveCommandKind::Redo);check(worker.wait(seq)&&worker.view()->bodies.size()==2,"Worker Redo failed");
  auto saved=worker.archive();check(saved.at("current").at("births").size()==2&&recordings>0,"Recovery archive absent");seq=worker.send(LiveCommandKind::Freeze);check(worker.wait(seq),"Freeze acknowledgment missing");auto result=worker.archive(true);check(result.at("current").at("births").size()==2&&!result.contains("undo"),"Publication copied recovery history");worker.stop();rejects([&]{worker.send(LiveCommandKind::Begin);});
 }
 {for(unsigned i=0;i<20;++i){LiveSession worker(in,receiver,1,1);worker.send(LiveCommandKind::Begin);worker.send(LiveCommandKind::Sample,{},{0,0,1},true);worker.stop();}check(true,"Retirement loop");}
 {std::atomic<bool> started=false,release=false;LiveSession worker(in,receiver,1,1,[&](const char* name,const Json&){if(std::string(name)=="live.created"){started=true;while(!release)std::this_thread::yield();}});
  while(!started)std::this_thread::yield();worker.send(LiveCommandKind::Begin);for(unsigned i=0;i<383;++i)worker.send(LiveCommandKind::Sample,{},{0,0,1},true);
  rejects([&]{worker.send(LiveCommandKind::Sample,{},{0,0,1},true);});auto seq=worker.send(LiveCommandKind::Pause);release=true;
  check(worker.wait(seq)&&worker.view()->paused&&worker.view()->sequence==seq&&worker.view()->bodies.size()==1,"Queue pressure lost accepted work or control command");
 }
 {ContinuousCore c(in,receiver);for(unsigned i=0;i<128;++i){stroke(c,{(int(i%16)-8)*.15,(int(i/16)-4)*.15,0});}auto before=c.view();rejects([&]{c.beginGesture();});same(before,c.view());}
 std::cout<<"PASS "<<checks<<" continuous-brush checks\n";return 0;
 }catch(const std::exception& e){std::cerr<<"FAIL "<<e.what()<<"\n";return 1;}}

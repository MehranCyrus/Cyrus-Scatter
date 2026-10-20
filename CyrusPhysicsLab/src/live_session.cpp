#include "live_session.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <limits>
#include <set>

namespace cpl {namespace {
constexpr unsigned liveStepLimit=120000,historyCountLimit=128;
constexpr std::size_t archiveLimit=32*1024*1024;
void need(bool value,const char* message){if(!value)throw std::runtime_error(message);}
struct Bounds {Vec lo{1e100,1e100,1e100},hi{-1e100,-1e100,-1e100};};
Bounds bounds(const Input& input,const Row& row){
 Bounds b;for(auto& hull:input.sources.at(row.source).hulls)for(auto v:hull){auto p=rotate(row.rotation,v*row.scale)+row.position;
  b.lo={std::min(b.lo.x,p.x),std::min(b.lo.y,p.y),std::min(b.lo.z,p.z)};
  b.hi={std::max(b.hi.x,p.x),std::max(b.hi.y,p.y),std::max(b.hi.z,p.z)};}return b;
}
const char* commandName(LiveCommandKind k){switch(k){
 case LiveCommandKind::Begin:return "begin";case LiveCommandKind::Sample:return "sample";
 case LiveCommandKind::End:return "end";case LiveCommandKind::CancelGesture:return "cancel_gesture";
 case LiveCommandKind::Pause:return "pause";case LiveCommandKind::Resume:return "resume";
 case LiveCommandKind::Finish:return "finish";case LiveCommandKind::Freeze:return "freeze";
 case LiveCommandKind::Undo:return "undo";case LiveCommandKind::Redo:return "redo";
 case LiveCommandKind::Archive:return "archive";case LiveCommandKind::Result:return "result";default:return "barrier";}}
}

const char* ContinuousCore::solverIdentity(){return CPL_SOLVER_ID;}
ContinuousCore::ContinuousCore(Input in,Mesh mesh,std::uint64_t id,std::uint64_t gesture,LiveTrace log,std::function<bool()> stop):
 input(std::move(in)),receiver(std::move(mesh)),surface(receiver),nextId(id),nextGesture(gesture),trace(std::move(log)),cancelled(std::move(stop)){
 validate(input);need(id>0&&gesture>0,"Invalid live identity");
 for(auto& row:input.frozen)need(row.id<nextId,"Live identity overlaps a completed body");
 double lowest=1e100,extent=0;
 for(auto& m:input.colliders)for(auto p:m.vertices)lowest=std::min(lowest,p.z);
 if(lowest==1e100)for(auto p:receiver.vertices)lowest=std::min(lowest,p.z);
 for(auto& source:input.sources)for(auto& hull:source.hulls)for(auto p:hull)extent=std::max(extent,length(p)*input.settings.scaleMax);
 need(std::isfinite(lowest)&&lowest<1e99,"Receiver has no usable bounds");
 lostZ=lowest-std::max(1.,10*extent);world=joltWorld(input);
 event("live.created",{{"lost_z",lostZ},{"solver",solverIdentity()},{"dt",input.settings.dt},{"contact_distance_m",joltContactDistance(input)}});
}
void ContinuousCore::event(const char* name,Json data)const{if(trace){data["step"]=step;data["next_id"]=nextId;trace(name,data);}}
std::shared_ptr<const ContinuousCore::Point> ContinuousCore::checkpoint()const{
 auto p=std::make_shared<Point>();p->world=world->checkpoint();p->births=births;p->lost=lost;p->step=step;p->quiet=quiet;p->skipped=skipped;p->blocked=blocked;return p;
}
std::size_t ContinuousCore::historyBytes()const{
 std::set<const Point*> seen;std::size_t bytes=0;auto count=[&](const std::shared_ptr<const Point>& p){if(p&&seen.insert(p.get()).second){bytes+=sizeof(Point)+p->births.capacity()*sizeof(Birth)+p->lost.capacity()*sizeof(p->lost[0]);if(p->world)bytes+=p->world->data.size()+p->world->bodies.capacity()*sizeof(p->world->bodies[0]);}};
 count(gestureStart);for(auto& h:undo){count(h.before);count(h.after);}for(auto& h:redo){count(h.before);count(h.after);}return bytes;
}
void ContinuousCore::beginGesture(){
 need(!finishing&&!done,"Finish or paused result is closed for new strokes");need(!emitter,"A gesture is already active");
 need(undo.size()<historyCountLimit,"Stroke history is full. Finish this session before adding more.");
 auto before=checkpoint();std::size_t added=before->world->data.size()+before->births.size()*sizeof(Birth)+before->world->bodies.size()*sizeof(before->world->bodies[0]);
 need(historyBytes()+added*2<=historyLimit,"Stroke history memory limit. Finish or freeze this session.");
 need(nextGesture<std::numeric_limits<std::uint64_t>::max(),"Gesture identity exhausted");
 gestureStart=std::move(before);emitter=std::make_unique<Emitter>(input.settings,nextGesture++,nextId,input.sources);++revision;
 event("live.gesture.begin");
}
void ContinuousCore::emit(std::vector<Birth> values){
 if(values.empty())return;
 need(births.size()+values.size()+input.frozen.size()<=input.settings.maxBodies,"Body limit reached. Finish, freeze or undo a stroke.");
 std::size_t vertices=0,faces=0;auto renderCost=[&](const Row& r){vertices+=input.sources.at(r.source).render.vertices.size();faces+=input.sources.at(r.source).render.faces.size();};
 for(auto& r:input.frozen)renderCost(r);for(auto& b:births)renderCost(b);for(auto& b:values)renderCost(b);
 need(vertices<=2000000&&faces<=2000000,"Preview geometry limit reached. Finish, freeze or undo a stroke.");
 auto old=checkpoint();auto oldSize=births.size();births.reserve(oldSize+values.size());
 std::vector<Bounds> blockers;for(auto& row:input.frozen)blockers.push_back(bounds(input,row));for(auto& b:world->states())blockers.push_back(bounds(input,b.row));
 std::vector<Birth> accepted;accepted.reserve(values.size());unsigned rejected=0;double largestLift=0;
 for(auto& birth:values){auto box=bounds(input,birth);double lift=0;
  for(auto& b:blockers)if(box.lo.x<b.hi.x&&box.hi.x>b.lo.x&&box.lo.y<b.hi.y&&box.hi.y>b.lo.y)lift=std::max(lift,b.hi.z-box.lo.z+input.settings.thickness*.25);
  // A ten-metre source may legitimately need more than five metres of lift.
  // Crowding is a rejected birth, not a reason to pause the accepted simulation.
  double limit=std::max(5.,2*(box.hi.z-box.lo.z));
  if(lift>limit){++rejected;largestLift=std::max(largestLift,lift);continue;}
  birth.position.z+=lift;box.lo.z+=lift;box.hi.z+=lift;blockers.push_back(box);accepted.push_back(birth);
 }
 if(rejected){blocked+=rejected;++revision;event("live.spawn.blocked",{{"count",rejected},{"required_lift_m",largestLift}});}
 if(accepted.empty())return;
 Json record=Json::array();for(auto& b:accepted)record.push_back(encodeBirth(b));event("live.births.intent",{{"births",record}});
 try{world->addBatch(accepted);births.insert(births.end(),accepted.begin(),accepted.end());}catch(...){restore(*old);throw;}
 quiet=0;++revision;event("live.births.applied",{{"births",record}});
}
void ContinuousCore::sample(Vec p,Vec n,bool hit){
 need(bool(emitter)&&!finishing&&!done,"No active emission gesture");
 auto generated=emitter->sample(p,n,hit,step);nextId=std::max(nextId,emitter->nextId());std::vector<Birth> accepted;
 for(auto& b:generated){Hit target;Vec normal=normalized(n),origin=b.position-Vec{0,0,input.settings.height}+normal;
  if(!surface.hit(origin,normal*(-1),target)){++skipped;continue;}
  double bottom=0;for(auto& hull:input.sources[b.source].hulls)for(auto v:hull)bottom=std::min(bottom,rotate(b.rotation,v*b.scale).z);
  b.position=target.point+Vec{0,0,std::max(input.settings.height,-bottom+input.settings.thickness)};
  // A pivot hit does not clear an entire model on slopes or a mountain peak.
  // Bound the receiver height under the whole XY AABB before adding the body.
  // The BVH query is conservative: adjacent triangle vertices can raise the
  // drop slightly, but no force or terrain projection is applied after birth.
  auto footprint=bounds(input,b);double highest;
  if(surface.heightBound(footprint.lo,footprint.hi,highest))b.position.z+=std::max(0.,highest+input.settings.thickness-footprint.lo.z);
  accepted.push_back(b);
 }
 if(accepted.size()!=generated.size())event("live.footprint.clipped",{{"skipped",generated.size()-accepted.size()}});
 emit(std::move(accepted));++revision;
}
void ContinuousCore::endGesture(){
 if(!emitter)return;
 nextId=std::max(nextId,emitter->nextId());emitter.reset();
 if(gestureStart&&births.size()>gestureStart->births.size()){redo.clear();undo.push_back({gestureStart,{}});}
 gestureStart.reset();++revision;event("live.gesture.end");
}
void ContinuousCore::cancelGesture(){if(!emitter)return;auto before=gestureStart;emitter.reset();gestureStart.reset();if(before)restore(*before);event("live.gesture.cancel");}
void ContinuousCore::cull(World& target,unsigned at,std::vector<std::pair<std::uint64_t,unsigned>>& removals)const{
 for(auto& b:target.states())if(bounds(input,b.row).hi.z<lostZ){target.remove(b.row.id);removals.emplace_back(b.row.id,at);}
}
void ContinuousCore::restore(const Point& p){
 auto next=joltWorld(input);
 if(p.world)next->restore(*p.world);
 else{
  std::size_t cursor=0;std::vector<std::pair<std::uint64_t,unsigned>> removed;
  for(unsigned at=0;at<=p.step;++at){
   if(cancelled&&cancelled())throw std::runtime_error("Recovery cancelled");
   while(cursor<p.births.size()&&p.births[cursor].step==at)next->add(p.births[cursor++]);
   if(at<p.step){next->step();cull(*next,at+1,removed);}
  }
  need(cursor==p.births.size()&&removed==p.lost,"Recovery replay differs from its recorded removals");
 }
 world=std::move(next);births=p.births;lost=p.lost;step=p.step;quiet=p.quiet;skipped=p.skipped;blocked=p.blocked;finishing=false;done=false;settled=false;++revision;
}
void ContinuousCore::undoGesture(){
 endGesture();need(!undo.empty(),"No live stroke to undo");auto after=checkpoint();
 need(historyBytes()+after->world->data.size()+after->births.size()*sizeof(Birth)<=historyLimit,"Undo checkpoint memory limit; pending result retained");
 auto h=undo.back();restore(*h.before);h.after=std::move(after);undo.pop_back();redo.push_back(std::move(h));event("live.undo");
}
void ContinuousCore::redoGesture(){
 need(!emitter,"End the active gesture before Redo");need(!redo.empty(),"No live stroke to redo");
 auto h=redo.back();restore(*h.after);redo.pop_back();h.after.reset();undo.push_back(std::move(h));event("live.redo");
}
void ContinuousCore::advance(unsigned count){
 need(count>0&&count<=120,"Invalid live step slice");
 for(unsigned i=0;i<count&&!done;++i){
  need(step<liveStepLimit,"Live session work limit. Finish or freeze the current preview.");
  need(!finishing||step-finishStep<input.settings.maxSteps,"Finish limit reached. Freeze the preview or resume brushing.");
  world->step();++step;auto previous=lost.size();cull(*world,step,lost);
  for(std::size_t j=previous;j<lost.size();++j)event("live.body.lost",{{"id",lost[j].first},{"lost_z",lostZ}});
  bool isQuiet=true;for(auto& b:world->states()){
   need(std::isfinite(length(b.row.position))&&std::isfinite(length(b.velocity))&&std::isfinite(length(b.spin)),"Non-finite live physics state");
   if(!b.sleeping&&(length(b.velocity)>input.settings.quietLinear||length(b.spin)>input.settings.quietAngular))isQuiet=false;
  }
  quiet=isQuiet?quiet+1:0;
  if(finishing&&quiet>=input.settings.quietSteps){done=true;settled=true;event("live.finish.ready");}
  ++revision;
 }
}
void ContinuousCore::finish(){endGesture();need(!done,"Session is already complete");finishing=true;finishStep=step;quiet=0;event("live.finish");}
void ContinuousCore::freeze(){endGesture();finishing=true;done=true;settled=false;++revision;event("live.freeze");}
void ContinuousCore::continueAuthoring(){need(!done,"Completed session must be published or cancelled");finishing=false;quiet=0;++revision;event("live.resume");}
LiveView ContinuousCore::view()const{
 LiveView v;v.ready=true;v.bodies=world->states();v.step=step;v.nextId=nextId;v.nextGesture=nextGesture;v.revision=revision;
 v.gesture=bool(emitter);v.finishing=finishing;v.done=done;v.settled=settled;v.lost=unsigned(lost.size());v.skipped=skipped;v.blocked=blocked;
 v.undo=unsigned(undo.size());v.redo=unsigned(redo.size());v.historyBytes=historyBytes();v.lostZ=lostZ;
 for(auto& b:v.bodies)if(!b.sleeping)++v.active;return v;
}
Json ContinuousCore::encodePoint(const Point& p,bool identitiesOnly)const{
 const char* key=identitiesOnly?"birth_ids":"births";Json j={{"step",p.step},{"quiet",p.quiet},{"skipped",p.skipped},{"blocked",p.blocked},{key,Json::array()},{"lost",p.lost}};
 for(auto& b:p.births)j[key].push_back(identitiesOnly?Json(b.id):encodeBirth(b));return j;
}
std::shared_ptr<const ContinuousCore::Point> ContinuousCore::decodePoint(const Json& j,const std::map<std::uint64_t,Birth>* catalog)const{
 auto p=std::make_shared<Point>();p->step=j.at("step");p->quiet=j.at("quiet");p->skipped=j.at("skipped");p->blocked=j.value("blocked",0u);
 auto& values=j.at(catalog?"birth_ids":"births");need(p->step<=liveStepLimit&&values.size()+input.frozen.size()<=input.settings.maxBodies&&j.at("lost").size()<=input.settings.maxBodies,"Recovery point exceeds admission");
 std::set<std::uint64_t> ids;for(auto& r:input.frozen)ids.insert(r.id);unsigned previous=0;
 for(auto& item:values){auto b=catalog?catalog->at(item.get<std::uint64_t>()):decodeBirth(item);need(b.source<input.sources.size()&&ids.insert(b.id).second&&b.step>=previous&&b.step<=p->step,"Invalid recovery birth schedule");previous=b.step;p->births.push_back(b);}
 p->lost=j.at("lost").get<decltype(p->lost)>();std::set<std::uint64_t> removed;
 for(auto [id,at]:p->lost)need(ids.contains(id)&&removed.insert(id).second&&at<=p->step,"Invalid recovery removal");return p;
}
Json ContinuousCore::archive()const{
 Point current;current.births=births;current.lost=lost;current.step=step;current.quiet=quiet;current.skipped=skipped;current.blocked=blocked;
 Input projected;projected.sources={boxSource({.01,.01,.01})};projected.colliders={receiver};
 Json j={{"schema",2},{"solver",solverIdentity()},{"input",encodeInput(input)},{"receiver",encodeInput(projected)["colliders"][0]},
  {"next_id",nextId},{"next_gesture",nextGesture},{"current",encodePoint(current)},{"catalog",Json::array()},{"undo",Json::array()},{"redo",Json::array()},{"preview",Json::array()}};
 std::set<std::uint64_t> stored;for(auto& b:births)stored.insert(b.id);
 auto point=[&](const Point& p){for(auto& b:p.births)if(stored.insert(b.id).second)j["catalog"].push_back(encodeBirth(b));return encodePoint(p,true);};
 for(auto& h:undo)j["undo"].push_back(point(*h.before));
 const bool activeBranch=gestureStart&&births.size()>gestureStart->births.size();
 if(activeBranch)j["undo"].push_back(point(*gestureStart));
 else for(auto& h:redo)j["redo"].push_back({{"before",point(*h.before)},{"after",point(*h.after)}});
 for(auto& b:world->states())j["preview"].push_back(encodeRow(b.row));
 return j;
}
void ContinuousCore::recover(const Json& j){
 need(j.at("schema")==2&&j.at("solver")==solverIdentity(),"Recovery requires its matching Physics Lab solver build");
 need(j.at("input")==encodeInput(input),"Recovery input identity differs");
 need(j.at("undo").size()+j.at("redo").size()<=historyCountLimit,"Recovery history count exceeded");
 auto current=decodePoint(j.at("current"));std::vector<History> restoredUndo,restoredRedo;
 std::map<std::uint64_t,Birth> catalog;for(auto& b:current->births)catalog.emplace(b.id,b);
 need(j.at("catalog").size()<=input.settings.maxBodies,"Recovery catalog exceeds admission");
 for(auto& item:j.at("catalog")){auto b=decodeBirth(item);need(b.source<input.sources.size()&&b.step<=liveStepLimit&&catalog.emplace(b.id,b).second,"Invalid recovery catalog");}
 for(auto& p:j.at("undo"))restoredUndo.push_back({decodePoint(p,&catalog),{}});
 for(auto& h:j.at("redo"))restoredRedo.push_back({decodePoint(h.at("before"),&catalog),decodePoint(h.at("after"),&catalog)});
 auto id=j.at("next_id").get<std::uint64_t>(),g=j.at("next_gesture").get<std::uint64_t>();need(id>0&&g>0,"Invalid recovery identity counters");
 auto checkIds=[&](const Point& p){for(auto& b:p.births)need(b.id<id&&b.gesture<g,"Recovery identity high-water mark is invalid");};
 checkIds(*current);for(auto& h:restoredUndo)checkIds(*h.before);for(auto& h:restoredRedo){checkIds(*h.before);checkIds(*h.after);}
 restore(*current);undo=std::move(restoredUndo);redo=std::move(restoredRedo);nextId=id;nextGesture=g;need(historyBytes()<=historyLimit,"Recovery history memory exceeded");
 event("live.recovered");
}

LiveSession::LiveSession(Input input,Mesh receiver,std::uint64_t id,std::uint64_t gesture,LiveTrace log,std::function<void(const Json&)> sink,Json recovery):trace(std::move(log)),recoverySink(std::move(sink)){
 worker=std::thread([this,input=std::move(input),receiver=std::move(receiver),id,gesture,recovery=std::move(recovery)]()mutable{run(std::move(input),std::move(receiver),id,gesture,std::move(recovery));});
}
LiveSession::~LiveSession(){stop();}
void LiveSession::stop(){stopping=true;wake.notify_all();if(worker.joinable())worker.join();}
std::uint64_t LiveSession::send(LiveCommandKind kind,Vec point,Vec normal,bool hit){
 std::lock_guard lock(mutex);need(!stopping,"Live worker is retired");
 need(commands.size()<(kind==LiveCommandKind::Sample?384u:512u),"Brush command queue is full; pause and let accepted commands complete");
 auto sequence=++submitted;commands.push_back({kind,point,normal,hit,sequence});wake.notify_all();return sequence;
}
bool LiveSession::wait(std::uint64_t sequence,unsigned milliseconds){std::unique_lock lock(mutex);return wake.wait_for(lock,std::chrono::milliseconds(milliseconds),[&]{return completed>=sequence||stopping;})&&completed>=sequence;}
std::shared_ptr<const LiveView> LiveSession::view(){std::lock_guard lock(mutex);return published;}
Json LiveSession::archive(bool resultOnly){auto seq=send(resultOnly?LiveCommandKind::Result:LiveCommandKind::Archive);need(wait(seq,15000),"Timed out waiting for a safe recovery boundary; pending work retained");std::lock_guard lock(mutex);need(archiveSequence==seq&&!savedArchive.is_null(),"Live recovery archive is unavailable; pending work retained");return savedArchive;}
void LiveSession::run(Input input,Mesh receiver,std::uint64_t id,std::uint64_t gesture,Json recovery)noexcept{
 using Clock=std::chrono::steady_clock;
 try{
  double dt=input.settings.dt;ContinuousCore core(std::move(input),std::move(receiver),id,gesture,trace,[&]{return stopping.load();});
  bool paused=!recovery.is_null();if(paused)core.recover(recovery);
  std::string error;double debt=0,lastStepMs=0;auto previous=Clock::now(),lastRecovery=previous,finishStarted=previous;
  std::uint64_t publication=0,sequence=0;bool recoveryDirty=true;
  auto publish=[&]{auto v=std::make_shared<LiveView>(core.view());v->paused=paused;v->error=error;v->lastStepMs=lastStepMs;v->debtSeconds=debt;v->sequence=sequence;v->revision=++publication;
   {std::lock_guard lock(mutex);v->queued=commands.size();published=std::move(v);completed=sequence;}wake.notify_all();};
  auto checkpoint=[&]{auto j=core.archive();if(recoverySink)recoverySink(j);lastRecovery=Clock::now();recoveryDirty=false;};
  publish();checkpoint();
  while(!stopping){
   std::deque<LiveCommand> work;
   {std::unique_lock lock(mutex);if(commands.empty())wake.wait_for(lock,std::chrono::milliseconds(paused?100:2),[&]{return stopping||!commands.empty();});
    for(unsigned n=0;n<32&&!commands.empty();++n){work.push_back(commands.front());commands.pop_front();}}
   bool changed=false,forceRecovery=false;
   for(auto& cmd:work){if(stopping)break;
    if(trace)trace("live.command.enter",{{"sequence",cmd.sequence},{"kind",commandName(cmd.kind)},{"point",{cmd.point.x,cmd.point.y,cmd.point.z}},{"normal",{cmd.normal.x,cmd.normal.y,cmd.normal.z}},{"hit",cmd.hit}});
    try{switch(cmd.kind){
     case LiveCommandKind::Begin:need(!paused,"Resume the brush before drawing");core.beginGesture();break;
     case LiveCommandKind::Sample:need(!paused,"Brush is paused");core.sample(cmd.point,cmd.normal,cmd.hit);break;
     case LiveCommandKind::End:core.endGesture();forceRecovery=true;break;
     case LiveCommandKind::CancelGesture:core.cancelGesture();forceRecovery=true;break;
     case LiveCommandKind::Pause:core.endGesture();paused=true;forceRecovery=true;break;
     case LiveCommandKind::Resume:core.continueAuthoring();paused=false;error.clear();debt=0;previous=Clock::now();break;
     case LiveCommandKind::Finish:core.finish();paused=false;error.clear();finishStarted=Clock::now();break;
     case LiveCommandKind::Freeze:core.freeze();paused=true;forceRecovery=true;break;
     case LiveCommandKind::Undo:core.undoGesture();paused=true;error.clear();forceRecovery=true;break;
     case LiveCommandKind::Redo:core.redoGesture();paused=true;error.clear();forceRecovery=true;break;
     case LiveCommandKind::Archive:{core.endGesture();paused=true;auto j=core.archive();need(j.dump().size()<=archiveLimit,"Recovery file exceeds 32 MiB; finish or freeze before saving");std::lock_guard lock(mutex);savedArchive=std::move(j);archiveSequence=cmd.sequence;forceRecovery=true;break;}
     case LiveCommandKind::Result:{need(core.isDone(),"Complete the live session before publication");Json j={{"current",{{"births",Json::array()}}}};for(auto& b:core.recipe())j["current"]["births"].push_back(encodeBirth(b));std::lock_guard lock(mutex);savedArchive=std::move(j);archiveSequence=cmd.sequence;break;}
     case LiveCommandKind::Barrier:break;
    }}catch(const std::exception& e){error=e.what();paused=true;core.endGesture();if(trace)trace("live.command.error",{{"sequence",cmd.sequence},{"message",error}});}
    sequence=cmd.sequence;changed=true;recoveryDirty=true;
    if(trace)trace("live.command.exit",{{"sequence",sequence},{"kind",commandName(cmd.kind)}});
   }
   auto now=Clock::now();double elapsed=std::chrono::duration<double>(now-previous).count();previous=now;
   auto state=core.view();
   if(!paused&&!state.done&&(state.active>0||state.finishing)){
    if(debt+elapsed>.1&&trace)trace("live.clock.clamped",{{"discarded_seconds",debt+elapsed-.1}});
    debt=std::min(.1,debt+elapsed);
    try{unsigned advanced=0;auto begin=Clock::now();
     while(debt>=dt&&advanced<8&&!stopping&&(advanced==0||std::chrono::duration<double,std::milli>(Clock::now()-begin).count()<6)){core.advance();debt-=dt;++advanced;if(core.isDone())break;}
     if(advanced){lastStepMs=std::chrono::duration<double,std::milli>(Clock::now()-begin).count();changed=true;recoveryDirty=true;if(trace)trace("live.tick",{{"steps",advanced},{"duration_ms",lastStepMs},{"step",core.stepCount()}});}
     if(state.finishing)need(std::chrono::duration<double>(now-finishStarted).count()<30,"Finish wall-time limit reached; freeze or resume the preview");
    }catch(const std::exception& e){error=e.what();paused=true;changed=true;forceRecovery=true;if(trace)trace("live.step.error",{{"message",error}});}
   }else debt=0;
   if(core.isDone())paused=true;
   if(changed)publish();
   if(recoveryDirty&&(forceRecovery||std::chrono::duration<double>(Clock::now()-lastRecovery).count()>=1.)){
    try{checkpoint();}catch(const std::exception& e){lastRecovery=Clock::now();recoveryDirty=false;error=std::string("Recovery recording failed: ")+e.what();paused=true;publish();}
   }
  }
  if(trace)trace("live.worker.retired",{{"sequence",sequence}});
 }catch(const std::exception& e){auto v=std::make_shared<LiveView>();v->paused=true;v->error=e.what();{std::lock_guard lock(mutex);published=std::move(v);completed=submitted;}stopping=true;wake.notify_all();if(trace)trace("live.worker.error",{{"message",e.what()}});}
 catch(...){auto v=std::make_shared<LiveView>();v->paused=true;v->error="Unknown native worker failure";{std::lock_guard lock(mutex);published=std::move(v);completed=submitted;}stopping=true;wake.notify_all();}
}
}

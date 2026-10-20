// Included in Document. All methods here run on Max's host thread.
bool hasPending()const{return bool(session)||bool(live)||!recovery.is_null();}
void trackIdentities(){if(live){auto v=live->view();idHighWater=std::max(idHighWater,v->nextId);gestureHighWater=std::max(gestureHighWater,v->nextGesture);}}
Json pendingArchive(){
 if(live&&!live->view()->ready&&!recovery.is_null())return recovery;
 if(live){auto data=live->archive();trackIdentities();recovery={{"schema",1},{"core",std::move(data)},{"prepared_origin",{staged->origin.x,staged->origin.y,staged->origin.z}},{"meters_per_unit",staged->metersPerUnit},{"base",encode(*state)}};}
 return recovery;
}
void prepareRecovery(){
 if(recovery.is_null())return;
 trace("recovery.prepare.input");const auto& core=recovery.at("core");staged=std::make_shared<State>(*state);staged->input=cpl::decodeInput(core.at("input"));staged->solverProfile="cpl-continuous-1";
 auto origin=recovery.at("prepared_origin");staged->origin={origin[0],origin[1],origin[2]};staged->metersPerUnit=recovery.at("meters_per_unit");
 if(!std::isfinite(cpl::length(staged->origin))||!std::isfinite(staged->metersPerUnit)||staged->metersPerUnit<=0)throw std::runtime_error("Invalid pending recovery frame");
 trace("recovery.prepare.receiver");cpl::Input rayInput;rayInput.sources={cpl::boxSource({.01,.01,.01})};auto data=cpl::encodeInput(rayInput);data["colliders"]=Json::array();data["colliders"].push_back(core.at("receiver"));receiver=cpl::decodeInput(data).colliders.at(0);picking=std::make_unique<cpl::Surface>(receiver);
 trace("recovery.prepare.preview");preview.clear();if(core.at("preview").size()>5000)throw std::runtime_error("Recovery preview count exceeded");for(auto& value:core.at("preview")){auto row=cpl::decodeRow(value);if(row.source>=staged->input.sources.size())throw std::runtime_error("Invalid recovery preview source");preview.push_back(row);}
 idHighWater=std::max(idHighWater,core.at("next_id").get<std::uint64_t>());gestureHighWater=std::max(gestureHighWater,core.at("next_gesture").get<std::uint64_t>());
}
void createLive(){
 if(live)return;
 if(!recovery.is_null()&&recovery.at("core").at("solver")!=cpl::ContinuousCore::solverIdentity())throw std::runtime_error("This pending session needs its original solver build to Resume. Freeze its saved preview or cancel.");
 int slot=-1;for(unsigned i=0;i<recoverySlots.size();++i)if(!recoverySlots[i]){slot=int(i);break;}
 if(slot<0)throw std::runtime_error("Eight paused Physics sessions already own recovery slots. Finish or cancel one first.");
 recoverySlots[slot]=true;recoverySlot=slot;staged->solverProfile="cpl-continuous-1";
 auto context=Json{{"schema",1},{"base",encode(*state)},{"prepared_origin",{staged->origin.x,staged->origin.y,staged->origin.z}},{"meters_per_unit",staged->metersPerUnit}};
 auto path=std::filesystem::path(cpl::diag::directory())/(L"live-recovery-"+std::to_wstring(slot)+L".json");recoveryPath=path;
 auto owner=ownerHandle;auto epoch=++liveEpochCounter;liveEpoch=epoch;
 auto logger=[owner,epoch](const char* event,const Json& data){Json j=data;j["owner"]=owner;j["session_epoch"]=epoch;cpl::diag::record(event,j.dump());};
 durableFile(path.wstring()+L".status.json",Json{{"state","active"},{"epoch",epoch}}.dump());
 auto sink=[context=std::move(context),path](const Json& core)mutable{context["core"]=core;durableFile(path,context.dump());};
 try{live=std::make_unique<cpl::LiveSession>(staged->input,receiver,std::max(state->nextId,idHighWater),std::max(state->gesture,gestureHighWater),std::move(logger),std::move(sink),recovery.is_null()?Json():recovery.at("core"));}
 catch(...){recoverySlots[slot]=false;recoverySlot=-1;throw;}
 liveRevision=0;commitFailed=false;error.clear();timedOut=false;
}
void validateRecoveryBindings(INode* owner){
 auto saved=staged;auto savedReceiver=receiver;
 try{prepare(owner,true);if(!sameCaptured(cpl::encodeInput(staged->input),cpl::encodeInput(saved->input))||receiver.vertices.size()!=savedReceiver.vertices.size()||!std::equal(receiver.vertices.begin(),receiver.vertices.end(),savedReceiver.vertices.begin(),[](Vec a,Vec b){return cpl::length(a-b)<=1e-9+2e-7*std::max(cpl::length(a),cpl::length(b));})||receiver.faces!=savedReceiver.faces)throw std::runtime_error("Saved session inputs differ from the scene. Freeze its cached preview or cancel.");
  // Opening/merging may convert metres to the current scene's centimetres.
  // Adopt that host frame only after every copied input still agrees in metres.
  saved->origin=staged->origin;saved->metersPerUnit=staged->metersPerUnit;auto base=std::make_shared<State>(*state);base->origin=saved->origin;base->metersPerUnit=saved->metersPerUnit;state=base;
  recovery["prepared_origin"]={saved->origin.x,saved->origin.y,saved->origin.z};recovery["meters_per_unit"]=saved->metersPerUnit;recovery["base"]=encode(*state);
  staged=saved;receiver=savedReceiver;picking=std::make_unique<cpl::Surface>(receiver);stale=false;trace("recovery.bindings.validated",{{"meters_per_unit",staged->metersPerUnit}});}
 catch(...){staged=saved;receiver=savedReceiver;picking=std::make_unique<cpl::Surface>(receiver);stale=true;throw;}
}
void retireLive(const char* reason){
 if(live){live->stop();trackIdentities();live.reset();}
 if(recoverySlot>=0){recoverySlots[recoverySlot]=false;recoverySlot=-1;}
 if(!recoveryPath.empty()){try{durableFile(recoveryPath.wstring()+L".status.json",Json{{"state",reason},{"epoch",liveEpoch}}.dump());}catch(const std::exception& e){trace("recovery.retire.error",{{"message",e.what()}});}recoveryPath.clear();}
}
void detachPainter(){
 if(ending)return;ending=true;gesture=false;
 if(painting&&painter){painter->EndPaintSession();painter->InitializeCallback(nullptr);Tab<INode*> none;painter->InitializeNodes(0,none);restoreOptions();}
 painting=false;if(active==this)active=nullptr;ending=false;
}
void pauseLive(bool archive=false){
 if(live){auto seq=live->send(cpl::LiveCommandKind::Pause);if(!live->wait(seq))throw std::runtime_error("Physics pause is pending; accepted work retained");if(archive)pendingArchive();}
 batchPaused=bool(session);detachPainter();pollLive(false);trace("brush.paused");
}
void appendLiveRecipe(State& next,const Json& current){
 next.recipe=state->recipe;
 if(state->solverProfile!="cpl-continuous-1"){std::uint64_t previous=0;unsigned offset=0,span=0;for(auto& b:next.recipe){if(previous&&previous!=b.gesture){offset+=span+next.input.settings.quietSteps;span=0;}previous=b.gesture;span=std::max(span,b.step);b.step+=offset;}}
 unsigned offset=0;for(auto& b:next.recipe)offset=std::max(offset,b.step+next.input.settings.quietSteps);
 if(next.recipe.size()+current.size()>5000)throw std::runtime_error("Saved birth history limit reached; previous result and pending preview retained");
 for(auto& value:current){auto b=cpl::decodeBirth(value);if(b.step>UINT_MAX-offset)throw std::runtime_error("Saved birth schedule exhausted");b.step+=offset;next.recipe.push_back(b);}
}
void finishLive(bool freeze){
 commitFailed=false;liveRevision=0;
 if(freeze&&live&&!live->view()->ready&&!recovery.is_null())retireLive("recovery-failed");
 if(!freeze&&stale)throw std::runtime_error("Inputs changed. Freeze the captured preview or cancel before starting a new session.");
 if(!live&&!recovery.is_null()){
  if(freeze){prepareRecovery();auto next=std::make_shared<State>(*staged);next->rows=state->rows;next->rows.insert(next->rows.end(),preview.begin(),preview.end());appendLiveRecipe(*next,recovery.at("core").at("current").at("births"));next->input.frozen.clear();next->nextId=idHighWater;next->gesture=gestureHighWater;next->settled=false;++next->revision;install(next,_T("Freeze recovered Physics session"));bakeOnFinish=false;recovery=Json();staged.reset();preview.clear();changed();return;}
  throw std::runtime_error("Resume the saved session before Finish, or Freeze its cached preview");
 }
 if(live){if(!live->view()->done)live->send(freeze?cpl::LiveCommandKind::Freeze:cpl::LiveCommandKind::Finish);released=true;gesture=false;detachPainter();pollLive();}
 else if(session){batchPaused=false;timedOut=false;if(freeze){session->acceptUnsettled();staged->settled=false;}else session->release();released=true;tick(1);}
}
void undoLive(bool redo){
 if(!live)throw std::runtime_error("Resume the pending session before editing live stroke history");
 detachPainter();auto seq=live->send(redo?cpl::LiveCommandKind::Redo:cpl::LiveCommandKind::Undo);
 if(!live->wait(seq,15000))throw std::runtime_error("Physics history restoration is still pending");pollLive(false);
}
void pollLive(bool publish=true){
 if(!live)return;auto v=live->view();trackIdentities();
 if(!v->ready){if(!v->error.empty())error=v->error;return;}
 if(v->revision==liveRevision)return;liveRevision=v->revision;
 auto* owner=GetCOREInterface()->GetINodeByHandle(ownerHandle);
 if(!owner){stop();error="Physics owner deleted";return;}
 auto frame=owner->GetNodeTM(GetCOREInterface()->GetTime());bool frameChanged=!sameUnit(GetSystemUnitScale(UNITS_METERS),staged->metersPerUnit);
 for(int i=0;i<4;++i)if(frame.GetRow(i)!=ownerFrame.GetRow(i))frameChanged=true;
 if(frameChanged){stale=true;error="Owner frame or units changed. Freeze or cancel the pending session.";if(!v->paused)live->send(cpl::LiveCommandKind::Pause);}
 if(!v->error.empty())error=v->error;
 preview.clear();for(auto& b:v->bodies)preview.push_back(b.row);released=v->finishing;timedOut=v->paused&&!v->error.empty();++ticks;
 if(v->done&&publish&&(!frameChanged||!v->settled)&&!commitFailed){
  try{auto archived=live->archive(true);auto next=std::make_shared<State>(*staged);next->rows=state->rows;next->rows.insert(next->rows.end(),preview.begin(),preview.end());next->recipe=state->recipe;
   appendLiveRecipe(*next,archived.at("current").at("births"));
   next->input.frozen.clear();next->nextId=idHighWater;next->gesture=gestureHighWater;next->settled=v->settled;++next->revision;
   if(next->rows.size()!=state->rows.size()||!archived.at("current").at("births").empty())install(next,v->settled?_T("Finish Physics session"):_T("Freeze Physics session"));
   retireLive("committed");recovery=Json();staged.reset();preview.clear();released=false;timedOut=false;authored=state->input.settings;bakeOnFinish=false;error.clear();
  }catch(const std::exception& e){error=e.what();trace("live.commit.error",{{"message",error}});commitFailed=true;}
 }
 changed();
}
BOOL startLiveStroke(){
 trace("stroke.start.enter");try{
  if(!painting||ending||stale||!live||!staged){trace("stroke.start.ignored.closed");return FALSE;}
  if(gesture)return TRUE;
  auto v=live->view();if(v->paused||v->finishing||v->done){trace("stroke.start.ignored.paused");return FALSE;}
  live->send(cpl::LiveCommandKind::Begin);gesture=true;released=false;rejectedGesture=false;error.clear();return TRUE;
 }catch(const std::exception& e){error=e.what();trace("stroke.start.error");return FALSE;}
}
void sampleLive(Vec world,Vec normal,bool hit){
 if(!gesture&&!startLiveStroke())throw std::runtime_error(error.empty()?"Start or resume the Physics brush first":error);
 if(!live||!staged||ending||stale)throw std::runtime_error("Physics brush input is closed");
 live->send(cpl::LiveCommandKind::Sample,(world-staged->origin)*staged->metersPerUnit,normal,hit);pollLive(false);
}

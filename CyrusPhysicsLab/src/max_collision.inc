// Included in Document. Host thread only; drawing never cooks geometry or steps physics.
bool collisionDisplay=false,collisionLimited=false;
ULONG collisionOwner=0;
std::shared_ptr<const cpl::CollisionGeometry> collisionGeometry;
Vec collisionOrigin;
std::uint64_t collisionBuilds=0,collisionDraws=0;
std::size_t collisionModelLines=0,collisionSurfaceLines=0,collisionBodies=0;
std::string collisionError;
void prepareCollisionDisplay(const State& frame)noexcept{
 collisionGeometry.reset();collisionError.clear();if(!collisionDisplay)return;
 try{collisionGeometry=cpl::joltCollisionGeometry(frame.input);collisionOrigin=frame.origin;++collisionBuilds;}
 catch(const std::exception& e){collisionError=e.what();trace("collision.display.error",{{"message",collisionError}});}
 catch(...){collisionError="Collision inspection preparation failed";}
}
void setCollisionDisplay(bool enabled,INode* owner){
 bool changed=collisionDisplay!=enabled;collisionDisplay=enabled;
 if(owner)collisionOwner=owner->GetHandle();
 if(enabled){collisionDisplays.insert(this);if(!collisionGeometry){if(staged&&(hasPending()||!stale))prepareCollisionDisplay(*staged);else if(!state->rows.empty())prepareCollisionDisplay(*state);}}
 else{collisionDisplays.erase(this);collisionModelLines=collisionSurfaceLines=collisionBodies=0;collisionLimited=false;}
 if(changed)trace("collision.display.visibility",{{"enabled",enabled}});
}
Json collisionDisplayInfo()const{
 return {{"enabled",collisionDisplay},{"prepared",bool(collisionGeometry)},{"builds",collisionBuilds},{"draws",collisionDraws},{"model_lines",collisionModelLines},{"surface_lines",collisionSurfaceLines},{"bodies",collisionBodies},{"cached_lines",collisionGeometry?collisionGeometry->segments:0},{"line_limit",200000},{"limited",collisionLimited||(collisionGeometry&&collisionGeometry->limited)},{"error",collisionError}};
}
void drawCollisionDisplay(ViewExp* view,std::size_t& remaining)noexcept{
 if(!collisionDisplay||!collisionGeometry||!view||!view->IsAlive())return;
 auto* owner=GetCOREInterface()->GetINodeByHandle(collisionOwner);if(!owner||owner->IsHidden())return;
 auto* gw=view->getGW();if(!gw)return;
 const auto limits=gw->getRndLimits();
 try{
  double unit=GetSystemUnitScale(UNITS_METERS);if(!std::isfinite(unit)||unit<=0)return;
  collisionModelLines=collisionSurfaceLines=collisionBodies=0;collisionLimited=collisionGeometry->limited;
  auto geometry=collisionGeometry;
  gw->setRndLimits(limits&~(GW_ILLUM|GW_Z_BUFFER));
  auto draw=[&](const std::vector<cpl::CollisionLine>& lines){
   std::size_t count=std::min(remaining,lines.size());if(count<lines.size())collisionLimited=true;
   for(std::size_t i=0;i<count;++i){Point3 points[3]={point(lines[i][0]),point(lines[i][1]),point(lines[i][1])};gw->polyline(2,points,nullptr,nullptr,FALSE,nullptr);}remaining-=count;return count;
  };
  auto row=[&](const cpl::Row& body){if(body.source>=geometry->sources.size())return;Matrix3 transform(1);double scale=body.scale/unit;
   transform.SetRow(0,point(cpl::rotate(body.rotation,{scale,0,0})));transform.SetRow(1,point(cpl::rotate(body.rotation,{0,scale,0})));transform.SetRow(2,point(cpl::rotate(body.rotation,{0,0,scale})));transform.SetTrans(point(body.position*(1/unit)+collisionOrigin));gw->setTransform(transform);
   collisionModelLines+=draw(geometry->sources[body.source]);++collisionBodies;
  };
  // Prefer current dynamic bodies if the diagnostic line budget is exhausted.
  gw->setColor(LINE_COLOR,Point3(.1f,1.f,1.f));
  if(live){auto snapshot=live->view();if(snapshot->ready)for(auto& b:snapshot->bodies)row(b.row);}
  else if(staged)for(auto& b:preview)row(b);
  for(auto& b:state->rows)row(b);
  Matrix3 surface(1);surface.SetScale(Point3(float(1/unit),float(1/unit),float(1/unit)));surface.SetTrans(point(collisionOrigin));gw->setTransform(surface);gw->setColor(LINE_COLOR,Point3(1.f,.65f,.15f));collisionSurfaceLines=draw(geometry->colliders);++collisionDraws;
 }catch(const std::exception& e){collisionError=e.what();}
 catch(...){collisionError="Collision inspection drawing failed";}
 gw->setTransform(Matrix3(1));gw->setRndLimits(limits);
}

#include <Jolt/Jolt.h>
#include <Jolt/RegisterTypes.h>
#include <Jolt/Core/Factory.h>
#include <Jolt/Core/TempAllocator.h>
#include <Jolt/Core/JobSystemSingleThreaded.h>
#include <Jolt/Physics/PhysicsSystem.h>
#include <Jolt/Physics/StateRecorderImpl.h>
#include <Jolt/Physics/Body/BodyCreationSettings.h>
#include <Jolt/Physics/Collision/ContactListener.h>
#include <Jolt/Physics/Collision/Shape/ConvexHullShape.h>
#include <Jolt/Physics/Collision/Shape/StaticCompoundShape.h>
#include <Jolt/Physics/Collision/Shape/ScaledShape.h>
#include <Jolt/Physics/Collision/Shape/MeshShape.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>
#include "core.h"
#include <mutex>
#include <cstdarg>
#include <cstdio>
#include <unordered_map>
#include <algorithm>
#include <stdexcept>
#include <set>
#include <limits>
namespace cpl { namespace {
constexpr float bodyMass=.01f;
JPH::Vec3 jv(Vec p){return{float(p.x),float(p.y),float(p.z)};}
Vec cv(JPH::Vec3 p){return{p.GetX(),p.GetY(),p.GetZ()};}
class Layers:public JPH::BroadPhaseLayerInterface {public:
 unsigned GetNumBroadPhaseLayers()const override{return 2;}
 JPH::BroadPhaseLayer GetBroadPhaseLayer(JPH::ObjectLayer layer)const override{return JPH::BroadPhaseLayer(static_cast<JPH::uint8>(layer));}
#if defined(JPH_EXTERNAL_PROFILE) || defined(JPH_PROFILE_ENABLED)
 const char* GetBroadPhaseLayerName(JPH::BroadPhaseLayer)const override{return "PhysicsLab";}
#endif
};
class BroadFilter:public JPH::ObjectVsBroadPhaseLayerFilter {public:bool ShouldCollide(JPH::ObjectLayer a,JPH::BroadPhaseLayer b)const override{return a!=0||b.GetValue()!=0;}};
class PairFilter:public JPH::ObjectLayerPairFilter {public:bool ShouldCollide(JPH::ObjectLayer a,JPH::ObjectLayer b)const override{return a!=0||b!=0;}};
void trace(const char* format,...){va_list args;va_start(args,format);std::vfprintf(stderr,format,args);va_end(args);std::fprintf(stderr,"\n");}
struct Runtime {Runtime(){JPH::RegisterDefaultAllocator();JPH::Trace=trace;JPH::Factory::sInstance=new JPH::Factory;JPH::RegisterTypes();}~Runtime(){JPH::UnregisterTypes();delete JPH::Factory::sInstance;JPH::Factory::sInstance=nullptr;}};
void ensureRuntime(){static Runtime runtime;}
// The sample arena aborts the process on exhaustion. A host plugin must reject
// its tentative solve instead. Outstanding scratch allocations are owned here.
// Pair/contact admission rejects oversized configurations before initialization;
// arbitrary allocation failure inside Jolt jobs is not qualified for unwinding.
class Scratch final:public JPH::TempAllocator {
 std::unordered_map<void*,unsigned> allocations;std::size_t used=0;
public:
 ~Scratch()override{for(auto [p,size]:allocations){(void)size;JPH::AlignedFree(p);}}
 void* Allocate(JPH::uint size)override{if(!size)return nullptr;if(used+size>128*1024*1024||allocations.size()>=16384)throw std::runtime_error("Jolt scratch admission exceeded");void* p=JPH::AlignedAllocate(size,JPH_RVECTOR_ALIGNMENT);if(!p)throw std::bad_alloc();try{allocations.emplace(p,size);}catch(...){JPH::AlignedFree(p);throw;}used+=size;return p;}
 void Free(void* p,JPH::uint)override{if(!p)return;auto it=allocations.find(p);if(it==allocations.end())throw std::runtime_error("Jolt scratch ownership error");used-=it->second;allocations.erase(it);JPH::AlignedFree(p);}
};
struct CookedHull {JPH::ShapeRefC shape;Vec offset;double scale;};
CookedHull cookedHull(const std::vector<Vec>& points,double thickness){
 if(points.size()<4||points.size()>256)throw std::runtime_error("Collision piece needs 4 to 256 points");
 Vec lo=points[0],hi=lo;for(auto p:points){if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z))throw std::runtime_error("Collision piece has a non-finite point");lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
 // Rank and error bounds are measured without changing the authored geometry.
 Vec offset=(lo+hi)*.5;double span=length(hi-lo);
 if(!(span>0)||!std::isfinite(span))throw std::runtime_error("Collision piece has no finite extent");
 Vec anchor=(points[0]-offset)*(1/span),edge{},normal{};double longest=0,largest=0,volume=0;
 for(auto p:points){auto delta=(p-offset)*(1/span)-anchor;double size=dot(delta,delta);if(size>longest){longest=size;edge=delta;}}
 for(auto p:points){auto n=cross(edge,(p-offset)*(1/span)-anchor);double size=dot(n,n);if(size>largest){largest=size;normal=n;}}
 for(auto p:points)volume=std::max(volume,std::abs(dot(normal,(p-offset)*(1/span)-anchor)));
 if(volume<=1.e-12)throw std::runtime_error("Collision piece is flat or degenerate; supply a volumetric proxy");
 // Finite retry budget, bounded by both source size and authored thickness.
 // Never replace a failed detailed compound with an unrelated box/single hull.
 double envelope=std::min({.00025,thickness*.1,span*.001});
 if(!(envelope>0))throw std::runtime_error("Collision piece has no finite extent");
 auto fits=[&](const JPH::ShapeRefC& shape,Vec origin,double scale){
  auto* hull=static_cast<const JPH::ConvexHullShape*>(shape.GetPtr());auto centre=cv(hull->GetCenterOfMass());double outside=0;
  for(unsigned face=0;face<hull->GetNumFaces();++face){JPH::uint indices[256];auto count=hull->GetFaceVertices(face,256,indices);if(count<3||count>256)return false;auto a=hull->GetPoint(indices[0]);JPH::Vec3 n=JPH::Vec3::sZero();for(unsigned i=1;i+1<count&&n.LengthSq()<1.e-20f;++i)n=(hull->GetPoint(indices[i])-a).Cross(hull->GetPoint(indices[i+1])-a);if(n.LengthSq()<1.e-20f)return false;auto normal=cv(n.Normalized());
   // Compare original doubles, including conversion loss, in source metres.
   for(auto p:points)outside=std::max(outside,dot(normal,(p-origin)*(1/scale)-centre-cv(a))*scale);
  }return outside<=envelope;
 };
 double oldRadius=std::min(.0001,thickness*.1),oldError=std::min(.00002,thickness*.01);
 JPH::Array<JPH::Vec3> raw;for(auto p:points)raw.push_back(jv(p));
 auto legacy=[&](double radius,double error){JPH::ConvexHullShapeSettings settings(raw);settings.mMaxConvexRadius=float(radius);settings.mHullTolerance=1.e-6f;settings.mMaxErrorConvexRadius=float(error);return settings.Create();};
 auto original=legacy(oldRadius,oldError);
 if(!original.HasError()&&fits(original.Get(),{},1)){
  auto initial=original.Get();double width=2*static_cast<const JPH::ConvexHullShape*>(initial.GetPtr())->GetInnerRadius();
  if(width<=std::max(.01,4*thickness))return {initial,{},1};
  auto rounded=legacy(std::max(oldRadius,std::min(.01,width*.05)),std::max(oldError,std::min(.001,width*.005)));
  if(!rounded.HasError()&&fits(rounded.Get(),{},1))return {rounded.Get(),{},1};
 }
 // Repair only pieces that failed the original cook or its accuracy check.
 // Preserve the established representation/dynamics for already valid pieces.
 JPH::Array<JPH::Vec3> v;for(auto p:points)v.push_back(jv((p-offset)*(1/span)));
 auto cook=[&](double radius,double error){
  std::string failure;double maximum=envelope*.25/span,tolerance=std::min(1.e-6/span,maximum);
  for(unsigned attempt=0;attempt<6;++attempt){
   JPH::ConvexHullShapeSettings settings(v);settings.mMaxConvexRadius=float(radius/span);settings.mHullTolerance=float(tolerance);settings.mMaxErrorConvexRadius=float(error/span);auto result=settings.Create();
   if(!result.HasError()){
    auto shape=result.Get();if(fits(shape,offset,span))return shape;
    failure="Cooked hull exceeds its bounded point envelope";
   }else failure=result.GetError().c_str();
   if(tolerance>=maximum)break;tolerance=std::min(maximum,tolerance*4);
  }
  throw std::runtime_error("Collision piece could not be built within "+std::to_string(envelope*1000)+" mm: "+failure);
 };
 JPH::ShapeRefC initial=cook(oldRadius,oldError);
 // Inner radius is measured from the mass centre to the hull planes. Unlike
 // AABB thickness this remains meaningful for an authored, tilted leaf card.
 double width=2*static_cast<const JPH::ConvexHullShape*>(initial.GetPtr())->GetInnerRadius()*span;
 if(width<=std::max(.01,4*thickness))return {initial,offset,span}; // Preserve thin hull cooking.
 // Jolt shrinks then rounds internally: this does not inflate the outer hull.
 // Near-zero leaf rounding is numerically fragile for rolling metre-sized hulls.
 return {cook(std::max(oldRadius,std::min(.01,width*.05)),std::max(oldError,std::min(.001,width*.005))),offset,span};
}
JPH::ShapeRefC shape(const Source& source,double thickness){JPH::StaticCompoundShapeSettings compound;
 for(unsigned i=0;i<source.hulls.size();++i)try{auto hull=cookedHull(source.hulls[i],thickness);auto child=hull.shape;if(hull.scale!=1){JPH::ScaledShapeSettings scaled(child,JPH::Vec3::sReplicate(float(hull.scale)));auto result=scaled.Create();if(result.HasError())throw std::runtime_error(result.GetError().c_str());child=result.Get();}compound.AddShape(jv(hull.offset),JPH::Quat::sIdentity(),child);}catch(const std::exception& e){throw std::runtime_error("Collision piece "+std::to_string(i+1)+": "+e.what());}
 auto result=compound.Create();if(result.HasError())throw std::runtime_error("Jolt compound shape failed");return result.Get();}
#include "jolt_collider.inc"
class JoltWorld final:public World,private JPH::ContactListener {
 Settings settings;double units=1;Layers layers;BroadFilter broad;PairFilter pairs;
 Scratch scratch;JPH::JobSystemSingleThreaded jobs{JPH::cMaxPhysicsJobs};
 JPH::PhysicsSystem system;std::vector<JPH::ShapeRefC> shapes;std::vector<JPH::BodyID> all;
 std::vector<std::pair<Birth,JPH::BodyID>> dynamic;
 struct Support {JPH::BodyID id;Vec normal;};
 std::vector<Support> support;
 void contact(const JPH::Body& a,const JPH::Body& b,const JPH::ContactManifold& manifold,JPH::ContactSettings& contactSettings){
  // Called inside Update with bodies locked. Only record bounded numeric data
  // and edit the allowed contact settings; never call the locking body API here.
  // Cached/speculative contact depths include the configured contact envelope.
  // Reject remote pairs, but retain support inside that same bounded envelope.
  if(manifold.mPenetrationDepth < -units*std::min(.002,settings.thickness))return;
  const JPH::Body* moving=nullptr;Vec normal;
  if(a.IsStatic()&&b.IsDynamic()){moving=&b;normal=cv(manifold.mWorldSpaceNormal);}
  else if(b.IsStatic()&&a.IsDynamic()){moving=&a;normal=cv(-manifold.mWorldSpaceNormal);}
  if(!moving||normal.z<=.05)return;
  contactSettings.mCombinedFriction+=float(4*settings.stickiness);
  auto id=moving->GetID();if(id.GetIndex()>=support.size())return;
  auto& item=support[id.GetIndex()];
  // The most upward support wins, with a deterministic tie-break across seams.
  if(item.id!=id||normal.z>item.normal.z||(normal.z==item.normal.z&&(normal.x>item.normal.x||(normal.x==item.normal.x&&normal.y>item.normal.y))))item={id,normal};
 }
 void OnContactAdded(const JPH::Body& a,const JPH::Body& b,const JPH::ContactManifold& m,JPH::ContactSettings& c)override{contact(a,b,m,c);}
 void OnContactPersisted(const JPH::Body& a,const JPH::Body& b,const JPH::ContactManifold& m,JPH::ContactSettings& c)override{contact(a,b,m,c);}
 void applyGrip(){
  auto& api=system.GetBodyInterface();
  for(auto& [birth,id]:dynamic){auto& item=support[id.GetIndex()];if(item.id!=id||!api.IsActive(id))continue;
   auto velocity=api.GetLinearVelocity(id);auto spin=api.GetAngularVelocity(id);float speed=spin.Length();
   // A separating/bouncing body is free immediately; no air drag or wall glue.
   auto normal=jv(item.normal);float outward=velocity.Dot(normal);if(outward>.02*units)continue;
   float linearBrake=float(4*settings.stickiness*settings.gravity*units*item.normal.z*settings.dt);
   auto tangent=velocity-normal*outward;float slide=tangent.Length();
   if(slide>0)velocity=normal*outward+tangent*(std::max(0.f,slide-linearBrake)/slide);
   // Absorb tiny contact-normal chatter as part of the artistic grip control.
   // This only removes speed inside the current support envelope; it never
   // attracts a body or affects meaningful bounce/separation above 2 cm/s.
   if(std::abs(outward)<=.02*units)velocity-=normal*(outward*float(settings.stickiness));
   double radius=std::max(.001*units,double(shapes.at(birth.source)->GetLocalBounds().GetExtent().Length())*birth.scale);
   // Bounded angular speed brake, normalized by source size.
   float brake=float(linearBrake/radius);
   if(speed>0)spin*=std::max(0.f,speed-brake)/speed;
   api.SetLinearAndAngularVelocity(id,velocity,spin);
  }
 }
 JPH::BodyID addRow(const Row& row,bool moving,Vec velocity={},Vec spin={},JPH::BodyID requested={},bool publish=true){
  if(all.size()>=settings.maxBodies+128)throw std::runtime_error("Jolt body capacity exceeded");
  JPH::ScaledShapeSettings scaled(shapes.at(row.source),JPH::Vec3::sReplicate(float(row.scale)));auto shapeResult=scaled.Create();if(shapeResult.HasError())throw std::runtime_error("Jolt scaled shape failed");
  JPH::BodyCreationSettings b(shapeResult.Get(),JPH::RVec3(float(row.position.x*units),float(row.position.y*units),float(row.position.z*units)),JPH::Quat(float(row.rotation.x),float(row.rotation.y),float(row.rotation.z),float(row.rotation.w)),moving?JPH::EMotionType::Dynamic:JPH::EMotionType::Static,moving?1:0);
  b.mFriction=float(settings.friction);b.mRestitution=float(settings.bounce);b.mLinearDamping=float(settings.damping);b.mAngularDamping=float(settings.damping);b.mLinearVelocity=jv(velocity*units);b.mMaxLinearVelocity*=float(units);b.mAngularVelocity=jv(spin);
  if(moving){b.mOverrideMassProperties=JPH::EOverrideMassProperties::CalculateInertia;b.mMassPropertiesOverride.mMass=bodyMass;b.mMotionQuality=settings.ccd?JPH::EMotionQuality::LinearCast:JPH::EMotionQuality::Discrete;}
  auto& api=system.GetBodyInterface();auto* body=requested.IsInvalid()?api.CreateBody(b):api.CreateBodyWithID(requested,b);if(!body)throw std::runtime_error("Jolt body allocation failed");auto id=body->GetID();all.push_back(id);if(publish)api.AddBody(id,moving?JPH::EActivation::Activate:JPH::EActivation::DontActivate);return id;
 }
public:
 explicit JoltWorld(const Input& in):settings(in.settings),units(joltSimulationScale(in)){all.reserve(settings.maxBodies+128);dynamic.reserve(settings.maxBodies);system.Init(settings.maxBodies+128,0,settings.maxPairs,settings.maxContacts,layers,broad,pairs);system.SetGravity(JPH::Vec3(0,0,-float(settings.gravity*units)));auto quality=system.GetPhysicsSettings();quality.mPenetrationSlop=float(units*std::min(.0001,settings.thickness*.1));quality.mSpeculativeContactDistance=float(units*joltContactDistance(in));quality.mNumPositionSteps=8;quality.mNumVelocitySteps=16;quality.mManifoldTolerance=float(1.e-5*units);quality.mBodyPairCacheMaxDeltaPositionSq=float(1.e-8*units*units);quality.mBodyPairCacheCosMaxDeltaRotationDiv2=.9999996f;quality.mContactPointPreserveLambdaMaxDistSq=float(1.e-8*units*units);quality.mPointVelocitySleepThreshold=float(.005*units);quality.mMaxPenetrationDistance*=float(units);quality.mMinVelocityForRestitution*=float(units);quality.mInternalEdgeRemovalVertexToleranceSq*=float(units*units);system.SetPhysicsSettings(quality);
  if(settings.stickiness>0){support.resize(settings.maxBodies+128);system.SetContactListener(this);}
  for(auto& source:in.sources){auto physical=shape(source,settings.thickness);if(units!=1){JPH::ScaledShapeSettings scaled(physical,JPH::Vec3::sReplicate(float(units)));auto result=scaled.Create();if(result.HasError())throw std::runtime_error(result.GetError().c_str());physical=result.Get();}shapes.push_back(physical);}
  for(unsigned index=0;index<in.colliders.size();++index){try{
   auto cooked=cookedCollider(in.colliders[index]);if(units!=1){JPH::ScaledShapeSettings scaled(cooked.shape,JPH::Vec3::sReplicate(float(units)));auto result=scaled.Create();if(result.HasError())throw std::runtime_error(result.GetError().c_str());cooked.shape=result.Get();}JPH::BodyCreationSettings b(cooked.shape,JPH::RVec3(float(cooked.offset.x*units),float(cooked.offset.y*units),float(cooked.offset.z*units)),JPH::Quat::sIdentity(),JPH::EMotionType::Static,0);b.mFriction=float(settings.friction);b.mRestitution=float(settings.bounce);auto* body=system.GetBodyInterface().CreateBody(b);if(!body)throw std::runtime_error("Jolt collider allocation failed");all.push_back(body->GetID());system.GetBodyInterface().AddBody(body->GetID(),JPH::EActivation::DontActivate);
  }catch(const std::exception& e){throw std::runtime_error("Static collider "+std::to_string(index+1)+": "+e.what());}}
  for(auto& r:in.frozen)addRow(r,false);system.OptimizeBroadPhase();
 }
 ~JoltWorld()override{system.SetContactListener(nullptr);for(auto id:all){system.GetBodyInterface().RemoveBody(id);system.GetBodyInterface().DestroyBody(id);}}
 void add(const Birth& b)override{dynamic.emplace_back(b,addRow(b,true,b.velocity,b.spin));}
 void addBatch(const std::vector<Birth>& values)override{
  if(dynamic.size()+values.size()>settings.maxBodies)throw std::runtime_error("Jolt batch body admission exceeded");
  std::vector<JPH::BodyID> ids;ids.reserve(values.size());auto before=all.size(),oldDynamic=dynamic.size();auto& api=system.GetBodyInterface();
  try{for(auto& b:values){auto id=addRow(b,true,b.velocity,b.spin,{},false);ids.push_back(id);dynamic.emplace_back(b,id);}}
  catch(...){for(auto id:ids)api.DestroyBody(id);all.resize(before);dynamic.resize(oldDynamic);throw;}
  if(!ids.empty()){auto prepared=api.AddBodiesPrepare(ids.data(),int(ids.size()));api.AddBodiesFinalize(ids.data(),int(ids.size()),prepared,JPH::EActivation::Activate);}
 }
 void remove(std::uint64_t id)override{
  auto it=std::find_if(dynamic.begin(),dynamic.end(),[&](const auto& item){return item.first.id==id;});
  if(it==dynamic.end())throw std::runtime_error("Unknown dynamic body removal");
  auto handle=it->second;system.GetBodyInterface().RemoveBody(handle);system.GetBodyInterface().DestroyBody(handle);
  std::erase(all,handle);dynamic.erase(it);
 }
 std::shared_ptr<const WorldCheckpoint> checkpoint()const override{
  auto out=std::make_shared<WorldCheckpoint>();JPH::StateRecorderImpl recorder;system.SaveState(recorder);
  if(recorder.IsFailed()||recorder.GetDataSize()>16*1024*1024)throw std::runtime_error("World checkpoint admission exceeded");
  out->data=recorder.GetData();for(auto& [birth,id]:dynamic)out->bodies.emplace_back(birth,id.GetIndexAndSequenceNumber());return out;
 }
 void restore(const WorldCheckpoint& value)override{
  if(value.data.size()>16*1024*1024||value.bodies.size()>settings.maxBodies)throw std::runtime_error("Invalid in-memory world checkpoint");
  while(!dynamic.empty())remove(dynamic.back().first.id);
  for(auto& [birth,id]:value.bodies)dynamic.emplace_back(birth,addRow(birth,true,birth.velocity,birth.spin,JPH::BodyID(id)));
  JPH::StateRecorderImpl recorder;recorder.WriteBytes(value.data.data(),value.data.size());recorder.Rewind();
  if(!system.RestoreState(recorder)||recorder.IsFailed())throw std::runtime_error("World checkpoint restore failed");
 }
 void step()override{if(settings.stickiness>0)std::fill(support.begin(),support.end(),Support{});auto errors=system.Update(float(settings.dt),int(settings.collisionSteps),&scratch,&jobs);if(errors!=JPH::EPhysicsUpdateError::None)throw std::runtime_error("Jolt contact/pair/manifold capacity exhausted: "+std::to_string(static_cast<unsigned>(errors)));if(settings.stickiness>0)applyGrip();}
 std::vector<BodyState> states()const override{auto& api=system.GetBodyInterface();std::vector<BodyState> out;out.reserve(dynamic.size());for(auto& [birth,id]:dynamic){BodyState state;state.row=birth;auto p=api.GetPosition(id);auto q=api.GetRotation(id);state.row.position={p.GetX()/units,p.GetY()/units,p.GetZ()/units};state.row.rotation={q.GetX(),q.GetY(),q.GetZ(),q.GetW()};state.velocity=cv(api.GetLinearVelocity(id))*(1/units);state.spin=cv(api.GetAngularVelocity(id));state.sleeping=!api.IsActive(id);out.push_back(state);}return out;}
};
}
std::unique_ptr<World> joltWorld(const Input& in){ensureRuntime();return std::make_unique<JoltWorld>(in);}
Json joltColliderInfo(const Mesh& mesh){ensureRuntime();return cookedCollider(mesh).info;}
void joltValidateSource(const Source& source,double thickness){ensureRuntime();shape(source,thickness);}
double joltSimulationScale(const Input& in){
 // Keep normal-sized scenes in their established metre representation. For
 // sub-2cm assets use a bounded uniform solver frame. Triangle GJK/EPA has
 // absolute numerical tolerances too: cooking alone cannot fix tiny contacts.
 double span=std::numeric_limits<double>::max();
 for(const auto& source:in.sources){if(source.weight<=0||source.render.vertices.empty())continue;Vec lo=source.render.vertices[0],hi=lo;for(auto p:source.render.vertices){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}span=std::min(span,length(hi-lo)*in.settings.scaleMin);}
 double scale=1;if(span>0&&span<.02)while(span*scale<.2&&scale<1024)scale*=2;
 return scale;
}
double joltContactDistance(const Input& in){
 // LinearCast sweeps translation, not the complete angular motion of tall assets.
 // Retain the small-asset envelope, and widen detection for larger source sets.
 // This is detection distance, not penetration slop or a larger collision hull.
 // Jolt's setting is world-wide: the smallest source span bounds it so adding
 // a tall model cannot impose a centimetre envelope on existing thin assets.
 double span=1e100;
 for(auto& source:in.sources){Vec lo{1e100,1e100,1e100},hi{-1e100,-1e100,-1e100};for(auto& hull:source.hulls)for(auto p:hull){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}auto size=hi-lo;span=std::min(span,std::max({size.x,size.y,size.z})*in.settings.scaleMin);}
 return std::clamp(span*.004,std::min(.002,in.settings.thickness),.02);
}
std::shared_ptr<const CollisionGeometry> joltCollisionGeometry(const Input& in){
 ensureRuntime();validate(in);constexpr std::size_t limit=200000;
 auto result=std::make_shared<CollisionGeometry>();result->sources.resize(in.sources.size());
 auto append=[&](std::vector<CollisionLine>& lines,Vec a,Vec b){if(result->segments>=limit){result->limited=true;return;}lines.push_back({a,b});++result->segments;};
 for(std::size_t i=0;i<in.sources.size();++i)for(auto& points:in.sources[i].hulls){
  if(result->segments>=limit){result->limited=true;break;}
  auto cooked=cookedHull(points,in.settings.thickness);auto* hull=static_cast<const JPH::ConvexHullShape*>(cooked.shape.GetPtr());
  std::vector<std::pair<unsigned,unsigned>> edges;
  for(unsigned face=0;face<hull->GetNumFaces();++face){JPH::uint indices[256];unsigned count=hull->GetFaceVertices(face,256,indices);if(count>256)throw std::runtime_error("Collision inspection face budget exceeded");for(unsigned n=0;n<count;++n)edges.push_back(std::minmax(indices[n],indices[(n+1)%count]));}
  std::sort(edges.begin(),edges.end());edges.erase(std::unique(edges.begin(),edges.end()),edges.end());
  result->sources[i].reserve(result->sources[i].size()+std::min(limit-result->segments,edges.size()));
  for(auto [a,b]:edges)append(result->sources[i],cv(hull->GetPoint(a)+hull->GetCenterOfMass())*cooked.scale+cooked.offset,cv(hull->GetPoint(b)+hull->GetCenterOfMass())*cooked.scale+cooked.offset);
 }
 for(auto& mesh:in.colliders){if(result->segments>=limit){result->limited=true;break;}Vec half,center;cpl::Mesh solid;
  const Mesh* geometry=&mesh;if(exactBox(mesh,half,center)||flatRectangle(mesh,half,center)){solid=boxMesh(half,center);geometry=&solid;}
  std::vector<std::pair<unsigned,unsigned>> edges;edges.reserve(geometry->faces.size()*3);
  for(auto face:geometry->faces)for(unsigned n=0;n<3;++n)edges.push_back(std::minmax(face[n],face[(n+1)%3]));
  std::sort(edges.begin(),edges.end());edges.erase(std::unique(edges.begin(),edges.end()),edges.end());
  result->colliders.reserve(result->colliders.size()+std::min(limit-result->segments,edges.size()));
  for(auto [a,b]:edges)append(result->colliders,geometry->vertices[a],geometry->vertices[b]);
 }
 return result;
}
}

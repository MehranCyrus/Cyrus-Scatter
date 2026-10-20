#include <PxPhysicsAPI.h>
#include "core.h"
#include <stdexcept>
namespace cpl {namespace {
using namespace physx;
PxVec3 pv(Vec p){return{float(p.x),float(p.y),float(p.z)};}
Vec cv(PxVec3 p){return{p.x,p.y,p.z};}
class Errors:public PxErrorCallback {public:std::string error;void reportError(PxErrorCode::Enum code,const char* message,const char*,int)override{if(code!=PxErrorCode::eDEBUG_INFO&&code!=PxErrorCode::eDEBUG_WARNING)error=message;}};
struct Runtime {
 PxDefaultAllocator allocator;Errors errors;PxFoundation* foundation=nullptr;PxPhysics* physics=nullptr;
 Runtime(){foundation=PxCreateFoundation(PX_PHYSICS_VERSION,allocator,errors);if(!foundation)throw std::runtime_error("PhysX foundation failed");physics=PxCreatePhysics(PX_PHYSICS_VERSION,*foundation,PxTolerancesScale(),false,nullptr);if(!physics){foundation->release();throw std::runtime_error("PhysX creation failed");}}
 ~Runtime(){physics->release();foundation->release();}
};
Runtime& runtime(){static Runtime value;return value;}
class PhysXWorld final:public World {
 Settings settings;Errors& errors;PxPhysics* physics=nullptr;PxScene* scene=nullptr;PxDefaultCpuDispatcher* dispatcher=nullptr;PxMaterial* material=nullptr;
 std::vector<std::vector<PxConvexMesh*>> shapes;std::vector<PxTriangleMesh*> meshes;std::vector<std::pair<Birth,PxRigidDynamic*>> dynamic;
 void check(){if(!errors.error.empty())throw std::runtime_error("PhysX: "+errors.error);}
 void attach(PxRigidActor& actor,const Row& row){for(auto* hull:shapes.at(row.source)){PxConvexMeshGeometry geometry(hull,PxMeshScale(PxVec3(float(row.scale))));auto* shape=physics->createShape(geometry,*material,true);if(!shape)throw std::runtime_error("PhysX shape allocation failed");shape->setContactOffset(float(std::min(.0002,settings.thickness*.1)));shape->setRestOffset(0);actor.attachShape(*shape);shape->release();}}
 void cleanup(){if(scene){PxActorTypeFlags flags=PxActorTypeFlag::eRIGID_DYNAMIC|PxActorTypeFlag::eRIGID_STATIC;std::vector<PxActor*> actors(scene->getNbActors(flags));scene->getActors(flags,actors.data(),PxU32(actors.size()));for(auto* actor:actors)actor->release();scene->release();scene=nullptr;}if(material)material->release();for(auto& list:shapes)for(auto* m:list)m->release();for(auto* m:meshes)m->release();if(dispatcher)dispatcher->release();}
public:
 explicit PhysXWorld(const Input& in):settings(in.settings),errors(runtime().errors){try{
  errors.error.clear();physics=runtime().physics;
  PxSceneDesc desc(physics->getTolerancesScale());desc.gravity=PxVec3(0,0,-float(settings.gravity));dispatcher=PxDefaultCpuDispatcherCreate(0);desc.cpuDispatcher=dispatcher;desc.filterShader=PxDefaultSimulationFilterShader;desc.solverType=PxSolverType::eTGS;if(settings.ccd)desc.flags|=PxSceneFlag::eENABLE_CCD;scene=physics->createScene(desc);if(!scene)throw std::runtime_error("PhysX scene failed");
  material=physics->createMaterial(float(settings.friction),float(settings.friction),float(settings.bounce));PxCookingParams cooking(physics->getTolerancesScale());cooking.planeTolerance=1e-6f;
  for(auto& source:in.sources){std::vector<PxConvexMesh*> list;for(auto& hull:source.hulls){std::vector<PxVec3> points;for(auto p:hull)points.push_back(pv(p));PxConvexMeshDesc d;d.points.count=PxU32(points.size());d.points.stride=sizeof(PxVec3);d.points.data=points.data();d.flags=PxConvexFlag::eCOMPUTE_CONVEX;auto* mesh=PxCreateConvexMesh(cooking,d,physics->getPhysicsInsertionCallback());if(!mesh)throw std::runtime_error("PhysX convex cook failed");list.push_back(mesh);}shapes.push_back(std::move(list));}
  for(auto& mesh:in.colliders){if(mesh.faces.empty())continue;Vec half,center;if(exactBox(mesh,half,center)||flatRectangle(mesh,half,center)){auto* actor=physics->createRigidStatic(PxTransform(pv(center)));auto* shape=physics->createShape(PxBoxGeometry(pv(half)),*material,true);if(!shape)throw std::runtime_error("PhysX static box allocation failed");actor->attachShape(*shape);shape->release();scene->addActor(*actor);continue;}std::vector<PxVec3> points;for(auto p:mesh.vertices)points.push_back(pv(p));PxTriangleMeshDesc d;d.points.count=PxU32(points.size());d.points.stride=sizeof(PxVec3);d.points.data=points.data();d.triangles.count=PxU32(mesh.faces.size());d.triangles.stride=sizeof(mesh.faces[0]);d.triangles.data=mesh.faces.data();auto* cooked=PxCreateTriangleMesh(cooking,d,physics->getPhysicsInsertionCallback());if(!cooked)throw std::runtime_error("PhysX triangle cook failed");meshes.push_back(cooked);auto* actor=physics->createRigidStatic(PxTransform(PxIdentity));PxTriangleMeshGeometry geometry(cooked);auto* shape=physics->createShape(geometry,*material,true);if(!shape)throw std::runtime_error("PhysX collider shape failed");actor->attachShape(*shape);shape->release();scene->addActor(*actor);}
  for(auto& row:in.frozen){auto* actor=physics->createRigidStatic(PxTransform(pv(row.position),PxQuat(float(row.rotation.x),float(row.rotation.y),float(row.rotation.z),float(row.rotation.w))));attach(*actor,row);scene->addActor(*actor);}check();
 }catch(...){cleanup();throw;}}
 ~PhysXWorld()override{cleanup();}
 void add(const Birth& b)override{auto* actor=physics->createRigidDynamic(PxTransform(pv(b.position),PxQuat(float(b.rotation.x),float(b.rotation.y),float(b.rotation.z),float(b.rotation.w))));if(!actor)throw std::runtime_error("PhysX body allocation failed");attach(*actor,b);PxRigidBodyExt::setMassAndUpdateInertia(*actor,.01f);actor->setSolverIterationCounts(10,4);actor->setSleepThreshold(1.e-6f);actor->setLinearVelocity(pv(b.velocity));actor->setAngularVelocity(pv(b.spin));actor->setLinearDamping(float(settings.damping));actor->setAngularDamping(float(settings.damping));if(settings.ccd)actor->setRigidBodyFlag(PxRigidBodyFlag::eENABLE_CCD,true);scene->addActor(*actor);dynamic.emplace_back(b,actor);check();}
 void step()override{for(unsigned i=0;i<settings.collisionSteps;++i){scene->simulate(float(settings.dt/settings.collisionSteps));if(!scene->fetchResults(true))throw std::runtime_error("PhysX step completion failed");check();}}
 std::vector<BodyState> states()const override{std::vector<BodyState> out;for(auto& [b,actor]:dynamic){BodyState state;state.row=b;auto pose=actor->getGlobalPose();state.row.position=cv(pose.p);state.row.rotation={pose.q.x,pose.q.y,pose.q.z,pose.q.w};state.velocity=cv(actor->getLinearVelocity());state.spin=cv(actor->getAngularVelocity());state.sleeping=actor->isSleeping();out.push_back(state);}return out;}
};
}
std::unique_ptr<World> physxWorld(const Input& in){if(in.settings.stickiness!=0)throw std::runtime_error("Surface grip is Jolt-only; use zero stickiness for engine comparisons");return std::make_unique<PhysXWorld>(in);}
}

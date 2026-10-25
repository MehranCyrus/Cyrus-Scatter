#include "interactions_host.h"
#include "license_boundary.h"
#include <filesystem>
#include <fstream>
#include <SingleWeakRefMaker.h>
#include <polyobj.h>
#include <triobj.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <chrono>
#include <cmath>
#include <unordered_map>
#include <sstream>
#include <iomanip>
#include <numeric>
#include <MeshNormalSpec.h>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

namespace cyrus {
namespace ci=interactions;
struct InteractionSourceWatch:MaxSDK::SingleWeakRefMaker {
    bool valid=true;Interval validity=FOREVER;
    explicit InteractionSourceWatch(INode* node):SingleWeakRefMaker(node){}
    RefResult NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate)override{
        if(message==REFMSG_TARGET_DELETED||(message==REFMSG_CHANGE&&(part&(PART_GEOM|PART_TOPO|PART_TEXMAP|PART_VERTCOLOR|PART_MTL|PART_TM|PART_TM_CHAN|PART_OBJECT_TYPE))))valid=false;
        return SingleWeakRefMaker::NotifyRefChanged(interval,target,part,message,propagate);
    }
};
namespace {
std::unordered_map<ULONG,std::weak_ptr<const InteractionHostSource>> sourceCache;
std::unordered_map<std::string,std::weak_ptr<const ci::Source>> rigCache;
std::unordered_map<AnimHandle,std::weak_ptr<InteractionRuntime>> runtimes;
template<class F> Value* guarded(F fn){try{return fn();}catch(const std::exception& e){const std::string s=e.what();throw RuntimeError(std::wstring(s.begin(),s.end()).c_str());}}
std::string utf8(const MCHAR* text){if(!text)return {};int n=WideCharToMultiByte(CP_UTF8,0,text,-1,nullptr,0,nullptr,nullptr);std::string out(std::max(0,n-1),'\0');if(n>1){std::vector<char> bytes(n);WideCharToMultiByte(CP_UTF8,0,text,-1,bytes.data(),n,nullptr,nullptr);out.assign(bytes.data(),n-1);}return out;}
Value* stringValue(const std::string& s){int n=MultiByteToWideChar(CP_UTF8,0,s.data(),int(s.size()),nullptr,0);std::wstring out(n,L'\0');if(n)MultiByteToWideChar(CP_UTF8,0,s.data(),int(s.size()),out.data(),n);return new String(out.c_str());}
ci::Vec core(Point3 p,double unit){return {double(p.x)*unit,double(p.z)*unit,-double(p.y)*unit};}
std::shared_ptr<const InteractionHostSource> capture(INode* node,const std::string& saved,prep::Settings settings,int flags,int proxy){
    if(!node||(flags&~3)||flags==0||proxy<1||proxy>2||saved.size()>32*1024*1024)throw std::runtime_error("Invalid interaction source request or definition over 32 MiB");
    const auto time=GetCOREInterface()->GetTime();const double unit=GetSystemUnitScale(UNITS_METERS);std::shared_ptr<const InteractionHostSource> old;
    if(auto found=sourceCache.find(node->GetHandle());found!=sourceCache.end())old=found->second.lock();
    const bool fresh=old&&old->watch&&old->watch->GetRef()==node&&old->watch->valid&&old->watch->validity.InInterval(time)&&old->unit==unit;
    const bool sameSettings=fresh&&old->settings.minimumLength==settings.minimumLength&&old->settings.foliageFraction==settings.foliageFraction;
    const bool sameProxy=fresh&&old->proxy==proxy;
    if(sameSettings&&sameProxy&&(!(flags&1)||old->rig)&&(!(flags&2)||old->collider)){
        if(!saved.empty()){auto data=ci::Json::parse(saved);if(data.at("format")!=1||!data.value("accepted",false)||data.at("source").at("fingerprint")!=old->fingerprint||data.at("settings")!=ci::Json::array({settings.minimumLength,settings.foliageFraction}))throw std::runtime_error("Prepared source or settings changed; Analyze and review again");}
        return old;
    }
    auto result=std::make_shared<InteractionHostSource>();result->nodeHandle=Animatable::GetHandleByAnim(node);result->unit=unit;result->settings=settings;result->proxy=proxy;
    prep::Snapshot snapshot;
    if(fresh){result->mesh=old->mesh;result->cornerNormals=old->cornerNormals;result->memory=old->memory;result->watch=old->watch;result->fingerprint=old->fingerprint;result->bounds=old->bounds;}
    else {
        auto* base=node->GetObjectRef()?node->GetObjectRef()->FindBaseObject():nullptr;
        const auto id=base?base->ClassID():Class_ID(0,0);
        if(id!=Class_ID(TRIOBJ_CLASS_ID,0)&&id!=Class_ID(EDITTRIOBJ_CLASS_ID,0)&&id!=EPOLYOBJ_CLASS_ID&&id!=Class_ID(SPHERE_CLASS_ID,0)&&id!=Class_ID(BOXOBJ_CLASS_ID,0))throw std::runtime_error("Interaction sources require an Editable Mesh/Poly or standard sphere/box; snapshot renderer proxies explicitly before preparation");
        auto state=node->EvalWorldState(time);auto* object=state.obj;
        if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw std::runtime_error("Interaction source has no evaluated mesh");
        auto reservation=reserveSourceMetadataMemory(64*viewport_memory::MiB);
        auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));if(!tri)throw std::runtime_error("Interaction source conversion failed");
        auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> owned(tri,cleanup);
        const auto& mesh=tri->GetMesh();if(mesh.getNumVerts()<3||mesh.getNumVerts()>1000000||mesh.getNumFaces()<1||mesh.getNumFaces()>2000000)throw std::runtime_error("Interaction source admission: 1M vertices / 2M triangles");
        auto bytes=std::size_t(mesh.getNumVerts())*192+std::size_t(mesh.getNumFaces())*128;
        for(int channel=-NUM_HIDDENMAPS;channel<mesh.getNumMaps();++channel)if(mesh.mapSupport(channel))bytes+=2*(std::size_t(mesh.getNumMapVerts(channel))*sizeof(UVVert)+std::size_t(mesh.getNumMapFaces(channel))*sizeof(TVFace));
        if(bytes>64*viewport_memory::MiB)reservation=reserveSourceMetadataMemory(bytes);
        auto copy=std::make_shared<Mesh>(mesh);auto tm=node->GetObjectTM(time)*Inverse(node->GetNodeTM(time));

        if(auto* normals=copy->GetSpecifiedNormals();normals&&normals->AnyExplicitNormalsSet()){
            normals->SetParent(copy.get());normals->CheckNormals();normals->Transform(tm,false,nullptr,true);auto corners=std::make_shared<std::vector<Point3>>();corners->reserve(std::size_t(mesh.getNumFaces())*3);
            if(normals->GetNumFaces()!=mesh.getNumFaces())throw std::runtime_error("Authored normal face correspondence differs from the source");
            for(int face=0;face<mesh.getNumFaces();++face)for(int k=0;k<3;++k){const auto id=normals->GetNormalIndex(face,k);if(id<0||id>=normals->GetNumNormals())throw std::runtime_error("Invalid authored source normal index");auto q=normals->Normal(id);if(!std::isfinite(q.x)||!std::isfinite(q.y)||!std::isfinite(q.z)||Length(q)<1e-8f)throw std::runtime_error("Invalid authored source normal");corners->push_back(Normalize(q));}result->cornerNormals=std::move(corners);
        }
        for(int i=0;i<copy->getNumVerts();++i){copy->verts[i]=copy->verts[i]*tm;const auto p=core(copy->verts[i],unit);if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z))throw std::runtime_error("Nonfinite interaction source geometry");result->bounds.include(p);}
        copy->InvalidateGeomCache();copy->buildBoundingBox();result->mesh=std::move(copy);result->memory=std::move(reservation);result->memory->trimCPU(bytes);result->memory->commit();
        result->watch=std::make_shared<InteractionSourceWatch>(node);result->watch->validity=state.Validity(time);node->GetNodeTM(time,&result->watch->validity);node->GetObjectTM(time,&result->watch->validity);
    }
    const auto& mesh=*result->mesh;snapshot.positions.reserve(mesh.getNumVerts());snapshot.faces.reserve(mesh.getNumFaces());snapshot.materials.reserve(mesh.getNumFaces());
    for(int i=0;i<mesh.getNumVerts();++i){auto p=mesh.verts[i];snapshot.positions.push_back({float(double(p.x)*unit),float(double(p.y)*unit),float(double(p.z)*unit)});}
    for(int i=0;i<mesh.getNumFaces();++i){auto f=mesh.faces[i];snapshot.faces.push_back({f.v[0],f.v[1],f.v[2]});snapshot.materials.push_back(f.getMatID());}
    result->fingerprint=prep::fingerprint(snapshot);
    if(flags&1){
        const auto cacheKey=result->fingerprint+":"+ci::Json::array({settings.minimumLength,settings.foliageFraction}).dump();
        ci::Json serialized;const ci::Json* definition=nullptr;
        if(!saved.empty()){if(saved.size()>32*1024*1024)throw std::runtime_error("Saved interaction definition exceeds 32 MiB");serialized=ci::Json::parse(saved);if(serialized.at("format")!=1||!serialized.value("accepted",false)||serialized.at("settings")!=ci::Json::array({settings.minimumLength,settings.foliageFraction}))throw std::runtime_error("Preparation settings changed; review and accept the source guides first");definition=&serialized.at("source");if(definition->at("fingerprint")!=result->fingerprint)throw std::runtime_error("Prepared source changed; Analyze and review again");}
        if(auto found=rigCache.find(cacheKey);found!=rigCache.end())result->rig=found->second.lock();
        if(!result->rig){
            if(rigCache.size()>=512)for(auto it=rigCache.begin();it!=rigCache.end();)if(it->second.expired())it=rigCache.erase(it);else++it;
            if(rigCache.size()>=512&&!rigCache.contains(cacheKey))throw std::runtime_error("Prepared profile budget: 512 retained geometry/settings definitions");
            result->rig=ci::prepareSource(snapshot,settings,definition);result->analysisCount=definition?0:1;rigCache[cacheKey]=result->rig;}
    }else if(sameSettings)result->rig=old->rig;
    if(result->rig){if(old&&old->rig==result->rig&&old->unit==unit&&old->lightGeometry)result->lightGeometry=old->lightGeometry;
        else {PreviewGeometry light;light.faces.reserve(result->rig->previewTriangles.size());const auto& rig=*result->rig->rig;
            auto host=[unit](ci::Vec p){return Point3(float(p.x/unit),float(-p.z/unit),float(p.y/unit));};
            for(auto tri:result->rig->previewTriangles)light.faces.push_back({host(rig.positions[tri[0]]),host(rig.positions[tri[1]]),host(rig.positions[tri[2]])});
            std::vector<PreviewGeometry> groups;groups.push_back(std::move(light));result->lightGeometry=std::make_shared<MeshSnapshot>(std::move(groups));}}
    if(flags&2){
        if(old&&old->proxy==proxy&&old->unit==unit&&old->fingerprint==result->fingerprint&&old->collider)result->collider=old->collider;
        else {std::vector<ci::Vec> points;std::vector<ci::Tri> faces;
            if(proxy==1){points.reserve(mesh.getNumVerts());for(int i=0;i<mesh.getNumVerts();++i)points.push_back(core(mesh.verts[i],unit));faces=snapshot.faces;}
            else {const auto& b=result->bounds;for(unsigned i=0;i<8;++i)points.push_back({i&1?b.hi.x:b.lo.x,i&2?b.hi.y:b.lo.y,i&4?b.hi.z:b.lo.z});faces={{0,3,1},{0,2,3},{4,5,7},{4,7,6},{0,1,5},{0,5,4},{1,3,7},{1,7,5},{3,2,6},{3,6,7},{2,0,4},{2,4,6}};}
            result->collider=std::make_shared<ci::MeshGeometry>(std::move(points),std::move(faces));}
    }else if(sameProxy)result->collider=old->collider;
    if(sourceCache.size()>=512)for(auto it=sourceCache.begin();it!=sourceCache.end();)if(it->second.expired())it=sourceCache.erase(it);else++it;
    if(sourceCache.size()>=512&&!sourceCache.contains(node->GetHandle()))throw std::runtime_error("More than 512 retained interaction sources");
    sourceCache[node->GetHandle()]=result;return result;
}
}
std::shared_ptr<InteractionRuntime> interactionRuntime(AnimHandle owner){auto it=runtimes.find(owner);return it==runtimes.end()?nullptr:it->second.lock();}
void interactionRegister(const std::shared_ptr<InteractionRuntime>& runtime){
    for(auto it=runtimes.begin();it!=runtimes.end();)if(it->second.expired())it=runtimes.erase(it);else++it;
    if(runtime&&runtime->controller)runtimes[runtime->controller]=runtime;
}
void interactionForget(AnimHandle owner,const std::shared_ptr<InteractionRuntime>& expected){auto found=runtimes.find(owner);if(found!=runtimes.end()&&found->second.lock()==expected)runtimes.erase(found);}
bool interactionLayer(AnimHandle owner,int key)noexcept{try{auto p=interactionRuntime(owner);if(!p||!p->live)return false;auto found=std::find(p->editKeys.begin(),p->editKeys.end(),key);if(found==p->editKeys.end())return false;auto slot=std::size_t(found-p->editKeys.begin());const auto& cfg=p->engine->layout().layers[slot];return cfg.obstacle||cfg.react||!p->byLayerRow[slot].empty();}catch(...){return false;}}
bool interactionObstacleLayer(AnimHandle owner,int key)noexcept{try{auto p=interactionRuntime(owner);if(!p||!p->live)return false;auto found=std::find(p->editKeys.begin(),p->editKeys.end(),key);return found!=p->editKeys.end()&&p->engine->layout().layers[found-p->editKeys.begin()].obstacle;}catch(...){return false;}}
bool interactionHasOverride(AnimHandle owner,int layer,const std::string& id)noexcept{try{auto p=interactionRuntime(owner);if(!p||!p->current)return false;auto found=p->byIdentity.find({layer,id});return found!=p->byIdentity.end()&&(p->current->overrides.contains(found->second)||p->current->disabled.contains(found->second));}catch(...){return false;}}
bool interactionTransform(AnimHandle owner,int layer,const std::string& id,Matrix3& out)noexcept{
    try{auto p=interactionRuntime(owner);if(!p||!p->live)return false;auto snapshot=p->pending?p->pending:p->current;if(!snapshot)return false;auto found=p->byIdentity.find({layer,id});if(found==p->byIdentity.end())return false;auto tm=snapshot->overrides.find(found->second);if(tm==snapshot->overrides.end())return false;
        const auto& rows=tm->second.rows;auto host=[](ci::Vec v){return Point3(float(v.x),float(-v.z),float(v.y));};out.SetRow(0,host(rows[0]));out.SetRow(1,host(ci::mul(rows[2],-1)));out.SetRow(2,host(rows[1]));out.SetRow(3,host(ci::mul(rows[3],1/snapshot->layout->metresPerUnit)));return true;
    }catch(...){return false;}
}
namespace {
Matrix3 hostMatrix(const ci::Transform& tm,double unit){auto host=[](ci::Vec v){return Point3(float(v.x),float(-v.z),float(v.y));};Matrix3 result(1);result.SetRow(0,host(tm.rows[0]));result.SetRow(1,host(ci::mul(tm.rows[2],-1)));result.SetRow(2,host(tm.rows[1]));result.SetRow(3,host(ci::mul(tm.rows[3],1/unit)));return result;}
placements::View interactionRows(const InteractionRuntime& runtime,const ci::Snapshot& snapshot,unsigned layer,bool restOnly){
    const auto& rows=runtime.rows.at(layer);if(runtime.byLayerRow[layer].empty())return rows;std::unique_ptr<placements::Builder> builder;
    for(const auto& [index,tm]:snapshot.overrides){const auto& instance=snapshot.layout->instances.at(index);if(instance.layer!=layer)continue;
        auto record=rows.at(instance.row);auto matrix=hostMatrix(tm,snapshot.layout->metresPerUnit);bool different=false;for(unsigned k=0;k<4;++k)for(unsigned j=0;j<3;++j)different|=record.transform[k*3+j]!=matrix.GetRow(k)[j];
        if(different){if(!builder)builder=std::make_unique<placements::Builder>(rows);for(unsigned k=0;k<4;++k)for(unsigned j=0;j<3;++j)record.transform[k*3+j]=matrix.GetRow(k)[j];builder->replace(instance.row,record);}}
    auto result=builder?builder->freeze():rows;bool filtered=false;
    for(auto index:snapshot.disabled)if(snapshot.layout->instances.at(index).layer==layer){filtered=true;break;}
    if(restOnly&&!filtered)for(const auto& [index,pose]:snapshot.poses){(void)pose;if(snapshot.layout->instances[index].layer==layer){filtered=true;break;}}
    if(!filtered)return result;std::vector<std::uint32_t> keep;keep.reserve(rows.size());for(unsigned row=0;row<rows.size();++row){auto index=runtime.byLayerRow[layer][row];if(!snapshot.disabled.contains(index)&&(!restOnly||!snapshot.poses.contains(index)))keep.push_back(row);}return result.select(keep);
}
}
std::optional<placements::View> interactionFeedbackView(AnimHandle owner,int key){
    auto runtime=interactionRuntime(owner);if(!runtime)return {};auto snapshot=runtime->pending?runtime->pending:runtime->current;if(!snapshot)return {};
    auto found=std::find(runtime->editKeys.begin(),runtime->editKeys.end(),key);if(found==runtime->editKeys.end())return {};unsigned layer=unsigned(found-runtime->editKeys.begin());
    if(runtime->byLayerRow[layer].empty())return {};auto& cached=runtime->feedbackViews.at(layer);
    if(cached.first.lock()!=snapshot||!cached.second){cached.second=interactionRows(*runtime,*snapshot,layer,false);cached.first=snapshot;}return cached.second;
}
void interactionFailure(AnimHandle owner,const char* message)noexcept{try{if(auto runtime=interactionRuntime(owner)){runtime->error=message;++runtime->failures;}}catch(...){} }
void interactionEdit(AnimHandle owner,const std::vector<InteractionEditPatch>& edits)noexcept{
    auto runtime=interactionRuntime(owner);if(!runtime||!runtime->live||runtime->busy||!runtime->current||!runtime->publish)return;
    runtime->busy=true;
    try{
        auto overrides=runtime->current->overrides;auto disabled=runtime->current->disabled;std::vector<std::size_t> changed;
        for(const auto& patch:edits){auto it=runtime->byIdentity.find({patch.layer,patch.identity});if(it==runtime->byIdentity.end())continue;
            auto index=it->second;
            ci::Layout conversion;conversion.metresPerUnit=runtime->engine->layout().metresPerUnit;ci::Instance row;
            for(int i=0;i<4;++i)for(int k=0;k<3;++k)row.hostTransform[i*3+k]=patch.transform.GetRow(i)[k];conversion.instances.push_back(row);auto tm=conversion.transform(0);
            auto old=overrides.find(index);const auto before=old==overrides.end()?runtime->engine->layout().transform(index):old->second;bool different=false;
            for(int k=0;k<4;++k)different|=ci::length(ci::sub(tm.rows[k],before.rows[k]))>0;
            different|=disabled.contains(index)!=patch.deleted;if(patch.deleted)disabled.insert(index);else disabled.erase(index);
            if(different){const auto base=runtime->engine->layout().transform(index);bool atBase=true;for(int k=0;k<4;++k)atBase&=ci::length(ci::sub(tm.rows[k],base.rows[k]))==0;
                if(atBase)overrides.erase(index);else overrides[index]=tm;changed.push_back(index);}}
        if(changed.empty()){++runtime->reuses;runtime->busy=false;return;}
        auto next=runtime->engine->evaluate(runtime->current,overrides,changed,disabled);
        runtime->pending=next;interactionRenderCommit(runtime,next,[&]{runtime->publish(next);});runtime->current=std::move(next);runtime->pending.reset();++runtime->updates;runtime->error.clear();
    }catch(const std::exception& e){runtime->error=e.what();++runtime->failures;}catch(...){runtime->error="Unexpected interaction successor failure; last complete result retained";++runtime->failures;}
    runtime->pending.reset();runtime->busy=false;
}
}

visible_class_debug_ok(CyrusInteractionSourceValue)
class CyrusInteractionSourceValue:public Value {
public:
    std::shared_ptr<const cyrus::InteractionHostSource> source;bool accepted=false;
    CyrusInteractionSourceValue(std::shared_ptr<const cyrus::InteractionHostSource> p,bool reviewed):source(std::move(p)),accepted(reviewed){tag=class_tag(CyrusInteractionSourceValue);}
    classof_methods(CyrusInteractionSourceValue,Value);
    void collect()override{delete this;}Value* deep_copy(HashTable*)override{return this;}
    void sprin1(CharStream* s)override{s->printf(_T("<CyrusInteractionSource>"));}
};
visible_class_instance(CyrusInteractionSourceValue,"CyrusInteractionSource");

// Explicit bounded diagnostic export of this immutable captured generation.
// It never reevaluates a scene object and refuses to overwrite an existing file.
def_visible_primitive(cyrusInteractionSourceSnapshot,"cyrusInteractionSourceSnapshot");
Value* cyrusInteractionSourceSnapshot_cf(Value** a,int n){check_arg_count(cyrusInteractionSourceSnapshot,2,n);return cyrus::guarded([&]()->Value*{
    type_check(a[0],CyrusInteractionSourceValue,_T("interaction source"));auto source=static_cast<CyrusInteractionSourceValue*>(a[0])->source;
    const std::filesystem::path path(a[1]->to_string());if(std::filesystem::exists(path))throw std::runtime_error("Diagnostic snapshot already exists");
    std::ofstream out(path,std::ios::binary);const auto& mesh=*source->mesh;unsigned header[]{0x53544c32u,unsigned(mesh.getNumVerts()),unsigned(mesh.getNumFaces()),0};out.write(reinterpret_cast<const char*>(header),sizeof(header));
    for(int i=0;i<mesh.getNumVerts();++i){const auto p=mesh.verts[i];const float v[]{float(double(p.x)*source->unit),float(double(p.y)*source->unit),float(double(p.z)*source->unit)};out.write(reinterpret_cast<const char*>(v),sizeof(v));}
    for(int i=0;i<mesh.getNumFaces();++i){const auto f=mesh.faces[i];const unsigned v[]{f.v[0],f.v[1],f.v[2]};out.write(reinterpret_cast<const char*>(v),sizeof(v));}
    for(int i=0;i<mesh.getNumFaces();++i){const unsigned material=mesh.faces[i].getMatID();out.write(reinterpret_cast<const char*>(&material),sizeof(material));}
    out.close();if(!out)throw std::runtime_error("Diagnostic source snapshot write failed");return cyrus::stringValue(source->fingerprint);});}
visible_class_debug_ok(CyrusInteractionStateValue)
class CyrusInteractionStateValue:public Value {
public:
    std::shared_ptr<cyrus::InteractionRuntime> runtime;
    explicit CyrusInteractionStateValue(std::shared_ptr<cyrus::InteractionRuntime> p):runtime(std::move(p)){tag=class_tag(CyrusInteractionStateValue);}
    classof_methods(CyrusInteractionStateValue,Value);
    void collect()override{delete this;}Value* deep_copy(HashTable*)override{return &undefined;}
    void sprin1(CharStream* s)override{s->printf(_T("<CyrusInteractionPublication>"));}
};
visible_class_instance(CyrusInteractionStateValue,"CyrusInteractionPublication");
namespace cyrus {
std::shared_ptr<InteractionRuntime> interactionRuntime(Value* value){type_check(value,CyrusInteractionStateValue,_T("interaction publication"));return static_cast<CyrusInteractionStateValue*>(value)->runtime;}
}
def_visible_primitive(cyrusInteractionVersion,"cyrusInteractionVersion");
Value* cyrusInteractionVersion_cf(Value**,int n){check_arg_count(cyrusInteractionVersion,0,n);return Integer::intern(1);}

def_visible_primitive(cyrusInteractionOwner,"cyrusInteractionOwner");
Value* cyrusInteractionOwner_cf(Value** a,int n){check_arg_count(cyrusInteractionOwner,2,n);auto runtime=cyrus::interactionRuntime(a[0]);return runtime->controller==Animatable::GetHandleByAnim(a[1]->to_node())?&true_value:&false_value;}
def_visible_primitive(cyrusInteractionSource,"cyrusInteractionSource");
Value* cyrusInteractionSource_cf(Value** a,int n){check_arg_count(cyrusInteractionSource,4,n);return cyrus::guarded([&]()->Value*{
    type_check(a[2],Array,_T("source preparation settings"));auto* settings=static_cast<Array*>(a[2]);if(settings->size!=3)throw std::runtime_error("Preparation settings require minimum length, foliage fraction and collider mode");
    const auto saved=a[1]==&undefined?std::string{}:cyrus::utf8(a[1]->to_string());prep::Settings cfg{settings->data[0]->to_float(),settings->data[1]->to_float()};
    auto source=cyrus::capture(a[0]->to_node(),saved,cfg,a[3]->to_int(),settings->data[2]->to_int());return new CyrusInteractionSourceValue(std::move(source),!saved.empty());});}
def_visible_primitive(cyrusInteractionAccept,"cyrusInteractionAccept");
Value* cyrusInteractionAccept_cf(Value** a,int n){check_arg_count(cyrusInteractionAccept,1,n);type_check(a[0],CyrusInteractionSourceValue,_T("interaction source"));auto* value=static_cast<CyrusInteractionSourceValue*>(a[0]);if(!cyrusBoundaryAllows(value->source.get()))throw RuntimeError(_T("Active Cyrus authoring license required to accept prepared guides"));return new CyrusInteractionSourceValue(value->source,true);}

def_visible_primitive(cyrusInteractionReviewModel,"cyrusInteractionReviewModel");
Value* cyrusInteractionReviewModel_cf(Value** a,int n){check_arg_count(cyrusInteractionReviewModel,2,n);return cyrus::guarded([&]()->Value*{type_check(a[0],CyrusInteractionSourceValue,_T("interaction source"));auto source=static_cast<CyrusInteractionSourceValue*>(a[0])->source;
    if(!cyrusBoundaryAllows(source.get()))throw std::runtime_error("Active Cyrus authoring license required for model review");
    const auto frame=a[1]->to_matrix3();for(int row=0;row<4;++row)for(int axis=0;axis<3;++axis)if(!std::isfinite(frame.GetRow(row)[axis]))throw std::runtime_error("Nonfinite model review transform");
    auto reservation=cyrus::reserveSourceMetadataMemory(std::size_t(source->mesh->getNumVerts())*192+std::size_t(source->mesh->getNumFaces())*128);
    auto deleter=[](TriObject* value){value->DeleteThis();};std::unique_ptr<TriObject,decltype(deleter)> pending(CreateNewTriObject(),deleter);pending->GetMesh()=*source->mesh;auto* node=GetCOREInterface()->CreateObjectNode(pending.get());if(!node)throw std::runtime_error("Model review creation failed");pending.release();
    try{node->SetNodeTM(GetCOREInterface()->GetTime(),frame);node->SetRenderable(FALSE);node->SetName(_T("Cyrus_Analyzed_Model_Review"));auto* original=Animatable::GetAnimByHandle(source->nodeHandle);if(original&&original->SuperClassID()==BASENODE_CLASS_ID)node->SetMtl(static_cast<INode*>(original)->GetMtl());return MAXNode::intern(node);}
    catch(...){GetCOREInterface()->DeleteNode(node,FALSE);throw;}});}
def_visible_primitive(cyrusInteractionSourceInfo,"cyrusInteractionSourceInfo");
Value* cyrusInteractionSourceInfo_cf(Value** a,int n){check_arg_count(cyrusInteractionSourceInfo,1,n);type_check(a[0],CyrusInteractionSourceValue,_T("interaction source"));auto* value=static_cast<CyrusInteractionSourceValue*>(a[0]);auto source=value->source;
    auto data=source->rig?source->rig->report:cyrus::interactions::Json::object();data["accepted"]=value->accepted;data["fingerprint"]=source->fingerprint;data["has_solid_collider"]=bool(source->collider);data["proxy_mode"]=source->proxy;data["analysis_count"]=source->analysisCount;return cyrus::stringValue(data.dump());}
def_visible_primitive(cyrusInteractionSerialize,"cyrusInteractionSerialize");
Value* cyrusInteractionSerialize_cf(Value** a,int n){check_arg_count(cyrusInteractionSerialize,1,n);return cyrus::guarded([&]()->Value*{type_check(a[0],CyrusInteractionSourceValue,_T("interaction source"));auto* value=static_cast<CyrusInteractionSourceValue*>(a[0]);if(!value->accepted||!value->source->rig)throw std::runtime_error("Review the prepared source before saving it");return cyrus::stringValue(cyrus::interactions::Json{{"format",1},{"accepted",true},{"settings",cyrus::interactions::Json::array({value->source->settings.minimumLength,value->source->settings.foliageFraction})},{"source",cyrus::interactions::saveSource(*value->source->rig)}}.dump());});}
static Value* buildInteractionStage(Value** a,int n,bool retargetEdits=false){return cyrus::guarded([&]()->Value*{
    auto* owner=a[0]->to_node();if(!owner)throw std::runtime_error("Interaction owner is missing");type_check(a[1],Array,_T("interaction layers"));auto* layers=static_cast<Array*>(a[1]);if(layers->size>10)throw std::runtime_error("Interaction layers exceed ten");
    auto runtime=std::make_shared<cyrus::InteractionRuntime>();runtime->controller=Animatable::GetHandleByAnim(owner);auto layout=std::make_shared<cyrus::interactions::Layout>();layout->metresPerUnit=GetSystemUnitScale(UNITS_METERS);
    std::size_t activeRows=0,allRows=0;for(int i=0;i<layers->size;++i){type_check(layers->data[i],Array,_T("interaction layer"));auto* item=static_cast<Array*>(layers->data[i]);if(item->size!=9)throw std::runtime_error("Invalid interaction layer contract");auto count=cyrusPlacementView(item->data[2]).size();allRows+=count;if(item->data[4]->to_int())activeRows+=count;}
    if(activeRows>1000000||allRows>10000000)throw std::runtime_error("Interaction layout admission: 1M active rows and 10M referenced rows");
    // Includes the numeric index, stable-ID maps, row lookup arrays and bounded
    // construction scratch. The exact payload counters remain separate.
    runtime->memory=cyrus::reserveSourceMetadataMemory(activeRows*512+allRows*8+1024*1024);layout->allocationLease=runtime->memory;
    std::shared_ptr<cyrus::InteractionRuntime> previous;if(n==3&&a[2]!=&undefined){previous=cyrus::interactionRuntime(a[2]);if(previous->controller!=runtime->controller)throw std::runtime_error("Previous contact state belongs to another owner");}
    for(int li=0;li<layers->size;++li){type_check(layers->data[li],Array,_T("interaction layer"));auto* layer=static_cast<Array*>(layers->data[li]);if(layer->size!=9)throw std::runtime_error("Invalid interaction layer contract");
        auto role=layer->data[4]->to_int();if(role<0||role>2)throw std::runtime_error("Choose Collider or React to colliders in a layer; two-way deforming colliders are not supported");const auto& rows=cyrusPlacementView(layer->data[2]);type_check(layer->data[3],Array,_T("interaction source definitions"));auto* sources=static_cast<Array*>(layer->data[3]);
        const auto cohort=rows.sourceCohort();if(role&&(!cohort||cohort->sources().size()!=std::size_t(sources->size)||rows.sources()!=std::size_t(sources->size)))throw std::runtime_error("Interaction source cohort is stale");
        runtime->rows.push_back(rows);runtime->layerIDs.push_back(cyrus::utf8(layer->data[0]->to_string()));runtime->editKeys.push_back(layer->data[1]->to_int());runtime->renderEnabled.push_back(layer->data[8]->to_bool()!=FALSE);
        cyrus::interactions::LayerSettings cfg{bool(role&1),bool(role&2),layer->data[5]->to_bool()!=FALSE,layer->data[6]->to_float(),layer->data[7]->to_float()};
        if(!std::isfinite(cfg.gap)||cfg.gap<0||cfg.gap>.100001||!std::isfinite(cfg.stiffness)||cfg.stiffness<0||cfg.stiffness>1)throw std::runtime_error("Contact gap must be 0..10 cm and stiffness 0..1");layout->layers.push_back(cfg);
        std::vector<std::shared_ptr<const cyrus::interactions::Definition>> definitions;std::vector<std::shared_ptr<const cyrus::InteractionHostSource>> captured;
        for(int i=0;i<sources->size;++i){type_check(sources->data[i],CyrusInteractionSourceValue,_T("interaction source"));auto* value=static_cast<CyrusInteractionSourceValue*>(sources->data[i]);if((role&2)&&!value->accepted)throw std::runtime_error("Accept the source guides before enabling reactions");
            auto src=value->source;if(src->unit!=layout->metresPerUnit)throw std::runtime_error("System units changed; Analyze the interaction source again");
            if(role&&cohort->sources()[i].handle!=src->nodeHandle)throw std::runtime_error("Interaction source no longer matches the frozen placement cohort");
            auto definition=std::make_shared<cyrus::interactions::Definition>();definition->rig=src->rig;definition->collider=src->collider;definition->geometryBounds=src->bounds;definition->key=src->fingerprint;definitions.push_back(std::move(definition));captured.push_back(std::move(src));}
        std::set<unsigned> history;
        if(!role&&previous){auto old=std::find(previous->layerIDs.begin(),previous->layerIDs.end(),runtime->layerIDs.back());if(old!=previous->layerIDs.end()){auto oi=std::size_t(old-previous->layerIDs.begin());if(previous->rows[oi].token()==rows.token()){
            for(const auto& [index,tm]:previous->current->overrides){(void)tm;const auto& item=previous->engine->layout().instances[index];if(item.layer==oi)history.insert(item.row);}
            for(auto index:previous->current->disabled){const auto& item=previous->engine->layout().instances[index];if(item.layer==oi)history.insert(item.row);}
            if(!history.empty()){definitions=previous->engine->layout().sources[oi];captured=previous->sources[oi];}}}}
        layout->sources.push_back(std::move(definitions));runtime->sources.push_back(std::move(captured));runtime->byLayerRow.emplace_back(role||!history.empty()?rows.size():0,UINT_MAX);runtime->feedbackViews.emplace_back();
        std::vector<unsigned> admitted;if(role){admitted.resize(rows.size());std::iota(admitted.begin(),admitted.end(),0);}else admitted.assign(history.begin(),history.end());
        for(unsigned row:admitted){const auto& r=rows.at(row);cyrus::interactions::Instance instance;instance.layer=li;instance.row=row;instance.source=r.source-1;instance.identity=rows.textIdentity(row);instance.hostTransform=r.transform;
            auto index=std::uint32_t(layout->instances.size());runtime->byLayerRow.back()[row]=index;runtime->byIdentity.emplace(std::make_pair(runtime->editKeys.back(),instance.identity),index);layout->instances.push_back(std::move(instance));}}
    std::map<std::size_t,cyrus::interactions::Transform> overrides;std::set<std::size_t> disabled;
    if(previous){
        for(unsigned li=0;li<runtime->rows.size();++li){auto old=std::find(previous->layerIDs.begin(),previous->layerIDs.end(),runtime->layerIDs[li]);if(old==previous->layerIDs.end())continue;unsigned oi=unsigned(old-previous->layerIDs.begin());
            // Contact settings and render-mode changes retain effective Edit
            // transforms only while the exact frozen placement view is reused.
            // A new placement epoch already contains its authored Edit stack.
            if(!(previous->rows[oi].token()==runtime->rows[li].token()))continue;
            for(const auto& [key,index]:runtime->byIdentity){if(key.first!=runtime->editKeys[li])continue;auto found=previous->byIdentity.find(key);if(found==previous->byIdentity.end())continue;
                auto transform=previous->current->overrides.find(found->second);if(transform!=previous->current->overrides.end())overrides[index]=transform->second;if(previous->current->disabled.contains(found->second))disabled.insert(index);}}
    }
    std::vector<int> historyLayers;if(previous){for(const auto& [index,tm]:previous->current->overrides){(void)tm;historyLayers.push_back(previous->editKeys[previous->engine->layout().instances[index].layer]);}for(auto index:previous->current->disabled)historyLayers.push_back(previous->editKeys[previous->engine->layout().instances[index].layer]);}
    for(const auto& patch:cyrus::interactionAuthoredEdits(owner,historyLayers,retargetEdits)){auto found=runtime->byIdentity.find({patch.layer,patch.identity});if(found==runtime->byIdentity.end())continue;const auto index=found->second;
        cyrus::interactions::Layout conversion;conversion.metresPerUnit=layout->metresPerUnit;cyrus::interactions::Instance row;for(int k=0;k<4;++k)for(int j=0;j<3;++j)row.hostTransform[k*3+j]=patch.transform.GetRow(k)[j];conversion.instances.push_back(row);auto tm=conversion.transform(0),base=layout->transform(index);bool equal=true;for(int k=0;k<4;++k)equal&=cyrus::interactions::length(cyrus::interactions::sub(tm.rows[k],base.rows[k]))==0;
        if(equal)overrides.erase(index);else overrides[index]=tm;if(patch.deleted)disabled.insert(index);else disabled.erase(index);}
    runtime->engine=std::make_shared<cyrus::interactions::Engine>(layout);runtime->current=runtime->engine->evaluate({},overrides,{},disabled);runtime->memory->commit();runtime->updates=1;return new CyrusInteractionStateValue(std::move(runtime));});}
def_visible_primitive(cyrusInteractionStage,"cyrusInteractionStage");
Value* cyrusInteractionStage_cf(Value** a,int n){check_arg_count(cyrusInteractionStage,2,n);return buildInteractionStage(a,n);}
def_visible_primitive(cyrusInteractionStageFrom,"cyrusInteractionStageFrom");
Value* cyrusInteractionStageFrom_cf(Value** a,int n){check_arg_count(cyrusInteractionStageFrom,3,n);return buildInteractionStage(a,n);}
def_visible_primitive(cyrusInteractionRestage,"cyrusInteractionRestage");
Value* cyrusInteractionRestage_cf(Value** a,int n){check_arg_count(cyrusInteractionRestage,3,n);return buildInteractionStage(a,n,true);}

def_visible_primitive(cyrusInteractionHasEdits,"cyrusInteractionHasEdits");
Value* cyrusInteractionHasEdits_cf(Value** a,int n){check_arg_count(cyrusInteractionHasEdits,1,n);auto p=cyrus::interactionRuntime(a[0]);return bool_result(!p->current->overrides.empty()||!p->current->disabled.empty());}
def_visible_primitive(cyrusInteractionSourcesFresh,"cyrusInteractionSourcesFresh");
Value* cyrusInteractionSourcesFresh_cf(Value** a,int n){check_arg_count(cyrusInteractionSourcesFresh,1,n);auto p=cyrus::interactionRuntime(a[0]);const auto time=GetCOREInterface()->GetTime();const auto unit=GetSystemUnitScale(UNITS_METERS);
    for(const auto& layer:p->sources)for(const auto& source:layer)if(!source->watch||!source->watch->valid||!source->watch->GetRef()||!source->watch->validity.InInterval(time)||source->unit!=unit)return &false_value;return &true_value;}

def_visible_primitive(cyrusInteractionSourceSummary,"cyrusInteractionSourceSummary");
Value* cyrusInteractionSourceSummary_cf(Value** a,int n){check_arg_count(cyrusInteractionSourceSummary,1,n);type_check(a[0],CyrusInteractionSourceValue,_T("interaction source"));const auto& p=*static_cast<CyrusInteractionSourceValue*>(a[0])->source;if(!p.rig)throw RuntimeError(_T("Analyze a plant source first"));std::ostringstream text;
    text<<p.rig->rig->guides.size()<<" guides / "<<p.rig->roots<<" planted roots\n"<<p.rig->previewFaces.size()<<" preview triangles\nInspect the green guides, root locations and branch directions, then accept. Detailed measurements are in the Listener.";return cyrus::stringValue(text.str());}
def_visible_primitive(cyrusInteractionRows,"cyrusInteractionRows");
Value* cyrusInteractionRows_cf(Value** a,int n){check_arg_count(cyrusInteractionRows,2,n);return cyrus::guarded([&]()->Value*{auto runtime=cyrus::interactionRuntime(a[0]);int li=a[1]->to_int()-1;if(li<0||li>=int(runtime->rows.size()))throw std::runtime_error("Invalid interaction layer");return cyrusPlacementValue(cyrus::interactionRows(*runtime,*runtime->current,li,true));});}
def_visible_primitive(cyrusInteractionInfo,"cyrusInteractionInfo");
Value* cyrusInteractionInfo_cf(Value** a,int n){check_arg_count(cyrusInteractionInfo,1,n);auto runtime=cyrus::interactionRuntime(a[0]);auto data=cyrus::interactions::statisticsJson(runtime->current->statistics);data["generation"]=runtime->current->generation;data["updates"]=runtime->updates;data["reuses"]=runtime->reuses;data["failures"]=runtime->failures;data["preview_ms"]=runtime->previewMs;data["host_runtime_reservation_bytes"]=runtime->memory?runtime->memory->cost().cpu:0;data["error"]=runtime->error;return cyrus::stringValue(data.dump());}
def_visible_primitive(cyrusInteractionLive,"cyrusInteractionLive");
Value* cyrusInteractionLive_cf(Value** a,int n){check_arg_count(cyrusInteractionLive,2,n);cyrus::interactionRuntime(a[0])->live=a[1]->to_bool()!=FALSE;return &ok;}

def_visible_primitive(cyrusInteractionValidate,"cyrusInteractionValidate");
Value* cyrusInteractionValidate_cf(Value** a,int n){check_arg_count(cyrusInteractionValidate,2,n);return cyrus::guarded([&]()->Value*{auto runtime=cyrus::interactionRuntime(a[0]);auto report=runtime->engine->audit(*runtime->current,a[1]->to_int());
    bool passed=true;std::size_t penetrations=0,crossings=0;double stem=0;
    for(const auto& row:report.at("results")){penetrations+=row.at("penetrating_vertex_obstacle_pairs").get<std::size_t>();crossings+=row.at("touching_triangle_obstacle_pairs").get<std::size_t>();stem=std::max(stem,row.at("maximum_stem_edge_change").get<double>());passed&=row.at("root_anchor_error_m").get<double>()<=1e-6&&row.at("maximum_rigid_part_edge_change").get<double>()<=1e-3;}
    passed&=penetrations==0&&crossings==0&&stem<=.25;report["passed"]=passed;report["quality_limit_maximum_stem_edge_change"]=.25;
    std::ostringstream summary;summary<<(passed?"Full visible mesh check passed":"Full visible mesh needs review")<<"\n"<<report.at("triangles").get<std::size_t>()<<" triangles; "<<penetrations<<" interior vertex pairs; "<<crossings<<" touching/crossing triangle pairs\nMaximum stem edge change: "<<std::fixed<<std::setprecision(1)<<100*stem<<"%. Details printed to the Listener.";
    one_typed_value_local(Array* result);vl.result=new Array(3);vl.result->append(passed?&true_value:&false_value);vl.result->append(cyrus::stringValue(summary.str()));vl.result->append(cyrus::stringValue(report.dump()));return_value(vl.result);});}

def_visible_primitive(cyrusInteractionSummary,"cyrusInteractionSummary");
Value* cyrusInteractionSummary_cf(Value** a,int n){check_arg_count(cyrusInteractionSummary,1,n);auto runtime=cyrus::interactionRuntime(a[0]);const auto& s=runtime->current->statistics;std::ostringstream text;
    text<<s.plants<<" plants / "<<s.obstacles<<" colliders\n"<<s.posed<<" bent plants / "<<s.hiddenRoots<<" covered rooted groups\nLast contact fit: "<<std::fixed<<std::setprecision(2)<<s.fitMs<<" ms; "<<s.affected<<" nearby candidates";
    if(!runtime->error.empty())text<<"\nPrevious result retained: "<<runtime->error;return cyrus::stringValue(text.str());}

def_visible_primitive(cyrusInteractionGuides,"cyrusInteractionGuides");
Value* cyrusInteractionGuides_cf(Value** a,int n){check_arg_count(cyrusInteractionGuides,1,n);type_check(a[0],CyrusInteractionSourceValue,_T("interaction source"));auto source=static_cast<CyrusInteractionSourceValue*>(a[0])->source;
    if(!source->rig)throw RuntimeError(_T("Analyze a plant source first"));const auto& guides=source->rig->rig->guides;
    if(guides.size()>4096)throw RuntimeError(_T("Guide review exceeds 4096 guides"));std::size_t count=0;for(const auto& guide:guides)count+=guide.rest.nodes.size();if(count>65536)throw RuntimeError(_T("Guide review exceeds 65536 stations"));
    two_typed_value_locals(Array* result,Array* path);vl.result=new Array(int(guides.size()));
    for(const auto& guide:guides){vl.path=new Array(int(guide.rest.nodes.size()));vl.result->append(vl.path);for(auto p:guide.rest.nodes)vl.path->append(new Point3Value(Point3(float(p.x/source->unit),float(-p.z/source->unit),float(p.y/source->unit))));}
    return_value(vl.result);
}

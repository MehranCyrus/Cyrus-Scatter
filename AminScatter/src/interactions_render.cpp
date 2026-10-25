#include "interactions_host.h"
#include "license_boundary.h"
#include <simpobj.h>
#include <triobj.h>
#include <SingleWeakRefMaker.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <atomic>
#include <map>
#include <MeshNormalSpec.h>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

extern HINSTANCE CyrusEditInstance;
namespace cyrus {
namespace ci=interactions;
namespace {
const Class_ID renderID(0x43b612ea,0x578124ce);
struct RenderSource {
    std::shared_ptr<const Mesh> mesh;
    std::shared_ptr<const ci::Source> rig;
    std::shared_ptr<const std::vector<Point3>> cornerNormals;
    std::shared_ptr<PreviewMemory> memory;
};
struct RenderPacket {
    std::shared_ptr<const ci::Snapshot> snapshot;
    RenderSource source; // Numeric data only: no weak scene watcher on render threads.
    unsigned layer=0,slot=0;
    Box3 bounds;
};
std::size_t renderAdmission(const Mesh& mesh,std::size_t count,bool authoredNormals=false){
    const auto vertices=std::size_t(mesh.getNumVerts())*count,faces=std::size_t(mesh.getNumFaces())*count;
    if(vertices>20000000||faces>20000000)throw std::runtime_error("Posed full-mesh output exceeds the 20M face/vertex source-binding budget");
    // Output Mesh plus construction buffers, per-instance remaps and map data.
    std::size_t bytes=2*(vertices*sizeof(Point3)+faces*sizeof(Face))+std::size_t(mesh.getNumVerts())*sizeof(unsigned)+std::size_t(mesh.getNumFaces())*sizeof(unsigned);
    if(authoredNormals)bytes+=2*faces*(3*sizeof(Point3)+sizeof(MeshNormalFace));
    for(int channel=-NUM_HIDDENMAPS;channel<mesh.getNumMaps();++channel)if(mesh.mapSupport(channel)&&mesh.getNumMapFaces(channel)==mesh.getNumFaces()&&mesh.getNumMapVerts(channel)>0)
        bytes+=2*count*(std::size_t(mesh.getNumMapVerts(channel))*sizeof(UVVert)+std::size_t(mesh.getNumFaces())*sizeof(TVFace))+std::size_t(mesh.getNumMapVerts(channel))*sizeof(unsigned);
    if(bytes>1024ull*1024*1024)throw std::runtime_error("Posed render construction exceeds 1 GiB explicit peak payload admission");return bytes;
}
Point3 host(ci::Vec p,double unit){return {float(p.x/unit),float(-p.z/unit),float(p.y/unit)};}
ci::Transform transform(const ci::Snapshot& p,std::size_t i){auto found=p.overrides.find(i);return found==p.overrides.end()?p.layout->transform(i):found->second;}
std::unique_ptr<Mesh> build(const RenderPacket& packet){
    const auto& snapshot=*packet.snapshot;const auto& source=packet.source;const auto& input=*source.mesh;const auto& rig=*source.rig;
    std::vector<std::pair<std::size_t,std::shared_ptr<const ci::Pose>>> instances;
    std::size_t upperFaces=0,upperVertices=0;
    for(const auto& [index,pose]:snapshot.poses){const auto& p=snapshot.layout->instances[index];if(p.layer!=packet.layer||p.source!=packet.slot||pose->allHidden||snapshot.disabled.contains(index))continue;
        upperFaces+=input.getNumFaces();upperVertices+=input.getNumVerts();instances.emplace_back(index,pose);}
    const auto bytes=renderAdmission(input,instances.size(),bool(source.cornerNormals));auto reservation=reserveSourceMetadataMemory(bytes);
    std::vector<Point3> vertices;std::vector<Face> faces;vertices.reserve(upperVertices);faces.reserve(upperFaces);
    std::vector<Point3> normals;if(source.cornerNormals)normals.reserve(upperFaces*3);
    struct UVData {std::vector<UVVert> vertices;std::vector<TVFace> faces;};std::map<int,UVData> maps;
    for(int channel=-NUM_HIDDENMAPS;channel<input.getNumMaps();++channel)if(input.mapSupport(channel)&&input.getNumMapFaces(channel)==input.getNumFaces()&&input.getNumMapVerts(channel)>0){auto& data=maps[channel];data.vertices.reserve(std::size_t(input.getNumMapVerts(channel))*instances.size());data.faces.reserve(upperFaces);}
    for(const auto& [index,pose]:instances){auto tm=transform(snapshot,index);std::vector<unsigned> remap(input.getNumVerts(),UINT_MAX);std::vector<unsigned> selected;selected.reserve(input.getNumFaces());
        for(unsigned fi=0;fi<unsigned(input.getNumFaces());++fi)if(ci::visibleFace(rig,*pose,fi)){
            selected.push_back(fi);auto f=input.faces[fi];
            for(int k=0;k<3;++k){unsigned original=f.v[k];if(remap[original]==UINT_MAX){remap[original]=unsigned(vertices.size());vertices.push_back(host(tm.point(ci::posePoint(rig,*pose,original)),snapshot.layout->metresPerUnit));}f.v[k]=remap[original];}
            faces.push_back(f);}
        if(source.cornerNormals){const auto& rows=tm.rows;for(auto fi:selected)for(unsigned k=0;k<3;++k){const auto original=(*source.cornerNormals)[fi*3+k];auto n=ci::poseDirection(rig,*pose,input.faces[fi].v[k],{original.x,original.z,-original.y});
            n=ci::unit(ci::add(ci::add(ci::mul(ci::cross(rows[1],rows[2]),n.x),ci::mul(ci::cross(rows[2],rows[0]),n.y)),ci::mul(ci::cross(rows[0],rows[1]),n.z)));normals.push_back(host(n,1));}}
        for(auto& [channel,out]:maps){std::vector<unsigned> uvRemap(input.getNumMapVerts(channel),UINT_MAX);const auto* sourceVertices=input.mapVerts(channel);const auto* sourceFaces=input.mapFaces(channel);
            for(auto fi:selected){TVFace f=sourceFaces[fi];for(int k=0;k<3;++k){unsigned original=f.t[k];if(original>=uvRemap.size())throw std::runtime_error("Source UV index outside the captured map");if(uvRemap[original]==UINT_MAX){uvRemap[original]=unsigned(out.vertices.size());out.vertices.push_back(sourceVertices[original]);}f.t[k]=uvRemap[original];}out.faces.push_back(f);}}
    }
    std::size_t payload=vertices.capacity()*sizeof(Point3)+faces.capacity()*sizeof(Face);for(const auto& [channel,data]:maps){(void)channel;payload+=data.vertices.capacity()*sizeof(UVVert)+data.faces.capacity()*sizeof(TVFace);}
    if(payload>1024ull*1024*1024)throw std::runtime_error("Posed render mesh exceeds 1 GiB explicit payload admission");
    auto result=std::make_unique<Mesh>();if(!result->setNumVerts(int(vertices.size()))||!result->setNumFaces(int(faces.size())))throw std::runtime_error("Posed render mesh allocation failed");
    for(std::size_t i=0;i<vertices.size();++i)result->verts[int(i)]=vertices[i];
    for(std::size_t i=0;i<faces.size();++i)result->faces[int(i)]=faces[i];
    for(const auto& [channel,data]:maps){result->setMapSupport(channel,TRUE);result->setNumMapVerts(channel,int(data.vertices.size()));result->setNumMapFaces(channel,int(data.faces.size()));std::copy(data.vertices.begin(),data.vertices.end(),result->mapVerts(channel));std::copy(data.faces.begin(),data.faces.end(),result->mapFaces(channel));}
    result->InvalidateGeomCache();result->buildBoundingBox();result->buildNormals();
    if(!normals.empty()){result->SpecifyNormals();auto* specified=result->GetSpecifiedNormals();specified->SetParent(result.get());if(!specified->SetNumFaces(int(faces.size()))||!specified->SetNumNormals(int(normals.size())))throw std::runtime_error("Posed authored normal allocation failed");
        for(unsigned fi=0;fi<faces.size();++fi)for(unsigned k=0;k<3;++k){specified->Normal(fi*3+k)=normals[fi*3+k];specified->Face(fi).SetNormalID(k,fi*3+k);specified->Face(fi).SetSpecified(k,true);}specified->SetAllExplicit(true);}
    return result;
}
class InteractionRender final:public SimpleObjectBase {
public:
    struct OwnerWatch:MaxSDK::SingleWeakRefMaker {
        InteractionRender* object;
        OwnerWatch(INode* n,InteractionRender* p):SingleWeakRefMaker(n),object(p){}
        RefResult NotifyRefChanged(const Interval& i,RefTargetHandle t,PartID& p,RefMessage m,BOOL b)override{if(m==REFMSG_TARGET_DELETED)object->packet.store({});return SingleWeakRefMaker::NotifyRefChanged(i,t,p,m,b);}
    };
    AnimHandle owner=0;
    std::string key;
    unsigned layer=0,slot=0;
    std::atomic<std::shared_ptr<const RenderPacket>> packet;
    std::unique_ptr<OwnerWatch> watch;
    InteractionRender(){ivalid.SetEmpty();}
    Class_ID ClassID()override{return renderID;}
    void DeleteThis()override{delete this;}
    const MCHAR* GetObjectName(bool)const override{return _T("Cyrus Interactions Output");}
    void GetClassName(MSTR& name,bool)const override{name=_T("Cyrus Interactions Output");}
    int NumRefs()override{return 0;}
    RefTargetHandle GetReference(int)override{return nullptr;}
    void SetReference(int,RefTargetHandle)override{}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
    RefTargetHandle Clone(RemapDir& remap)override{auto* copy=new InteractionRender;copy->key=key;BaseClone(this,copy,remap);return copy;}
    CreateMouseCallBack* GetCreateMouseCallBack()override{return nullptr;}
    void InvalidateUI()override{}
    BOOL OKtoDisplay(TimeValue)override{return FALSE;}
    void BuildMesh(TimeValue)override{mesh.setNumVerts(0);mesh.setNumFaces(0);ivalid=FOREVER;}
    int Display(TimeValue,INode*,ViewExp*,int)override{return 0;}
    int HitTest(TimeValue,INode*,int,int,int,IPoint2*,ViewExp*)override{return 0;}
    void GetLocalBoundBox(TimeValue,INode*,ViewExp*,Box3& box)override{auto p=packet.load();if(p)box=p->bounds;else box.Init();}
    void GetWorldBoundBox(TimeValue t,INode* n,ViewExp* v,Box3& box)override{GetLocalBoundBox(t,n,v,box);}
    Mesh* GetRenderMesh(TimeValue,INode*,View&,BOOL& needDelete)override{
        auto p=packet.load();needDelete=TRUE;if(!p)return new Mesh;return build(*p).release();
    }
    IOResult Save(ISave* save)override{if(key.size()>1024)return IO_ERROR;save->BeginChunk(0x7920);ULONG done=0;auto result=save->Write(key.data(),ULONG(key.size()),&done);save->EndChunk();return result==IO_OK&&done==key.size()?IO_OK:IO_ERROR;}
    IOResult Load(ILoad* load)override{IOResult result;while((result=load->OpenChunk())==IO_OK){if(load->CurChunkID()==0x7920){auto size=load->CurChunkLength();if(size>1024){load->CloseChunk();return IO_ERROR;}key.assign(size,'\0');ULONG done=0;if(load->Read(key.data(),ULONG(size),&done)!=IO_OK||done!=size){load->CloseChunk();return IO_ERROR;}}load->CloseChunk();}return result==IO_END?IO_OK:IO_ERROR;}
};
class InteractionRenderDesc final:public ClassDesc2 {
public:
    int IsPublic()override{return FALSE;}
    void* Create(BOOL)override{return new InteractionRender;}
    const MCHAR* ClassName()override{return _T("CyrusInteractionsOutput");}
    const MCHAR* NonLocalizedClassName()override{return _T("CyrusInteractionsOutput");}
    SClass_ID SuperClassID()override{return GEOMOBJECT_CLASS_ID;}
    Class_ID ClassID()override{return renderID;}
    const MCHAR* Category()override{return _T("Cyrus Internal");}
    const MCHAR* InternalName()override{return _T("CyrusInteractionsOutput");}
    HINSTANCE HInstance()override{return CyrusEditInstance;}
};
InteractionRender* output(INode* n){auto* object=n?n->GetObjectRef():nullptr;return object&&object->ClassID()==renderID?static_cast<InteractionRender*>(object):nullptr;}
std::shared_ptr<const RenderPacket> packet(const std::shared_ptr<InteractionRuntime>& runtime,const std::shared_ptr<const ci::Snapshot>& snapshot,unsigned layer,unsigned slot){
    auto result=std::make_shared<RenderPacket>();result->snapshot=snapshot;result->layer=layer;result->slot=slot;const auto& source=*runtime->sources[layer][slot];result->source={source.mesh,source.rig,source.cornerNormals,source.memory};result->bounds.Init();
    std::size_t count=0;
    for(const auto& [index,pose]:snapshot->poses){const auto& p=snapshot->layout->instances[index];if(p.layer!=layer||p.source!=slot||pose->allHidden||snapshot->disabled.contains(index))continue;
        ++count;
        const double reach=result->source.rig->reach*transform(*snapshot,index).scale();auto centre=transform(*snapshot,index).rows[3];result->bounds+=host(ci::sub(centre,{reach,reach,reach}),snapshot->layout->metresPerUnit);result->bounds+=host(ci::add(centre,{reach,reach,reach}),snapshot->layout->metresPerUnit);}
    renderAdmission(*result->source.mesh,count,bool(result->source.cornerNormals));return result;
}
}
void interactionRenderCommit(const std::shared_ptr<InteractionRuntime>& runtime,const std::shared_ptr<const ci::Snapshot>& snapshot,const std::function<void()>& publish){
    // Construct every packet before touching any source output.
    std::vector<std::pair<InteractionRender*,std::shared_ptr<const RenderPacket>>> stage;
    for(auto handle:runtime->renderNodes){auto* value=Animatable::GetAnimByHandle(handle);if(!value||value->SuperClassID()!=BASENODE_CLASS_ID)continue;auto* object=output(static_cast<INode*>(value));if(!object||object->owner!=runtime->controller)continue;stage.emplace_back(object,packet(runtime,snapshot,object->layer,object->slot));}
    if(publish)publish();
    for(auto& [object,data]:stage){object->packet.store(std::move(data));object->ivalid.SetEmpty();}
    for(auto& [object,data]:stage){(void)data;try{object->NotifyDependents(FOREVER,PART_GEOM,REFMSG_CHANGE);}catch(...){/* Observer failure cannot undo an already complete publication. */}}
}
}
extern "C" __declspec(dllexport) ClassDesc* CyrusInteractionsOutputDesc(){static cyrus::InteractionRenderDesc desc;return &desc;}

def_visible_primitive(cyrusInteractionRenderNodes,"cyrusInteractionRenderNodes");
Value* cyrusInteractionRenderNodes_cf(Value** a,int n){check_arg_count(cyrusInteractionRenderNodes,2,n);auto runtime=cyrus::interactionRuntime(a[0]);type_check(a[1],Array,_T("previous interaction output nodes"));auto* old=static_cast<Array*>(a[1]);
    auto* owner=Animatable::GetAnimByHandle(runtime->controller);if(!owner||owner->SuperClassID()!=BASENODE_CLASS_ID)throw RuntimeError(_T("Interaction owner was removed"));
    one_typed_value_local(Array* result);vl.result=new Array(0);
    struct Entry {INode* node;unsigned layer,slot;std::string key;Mtl* material;std::unique_ptr<cyrus::InteractionRender::OwnerWatch> watch;std::shared_ptr<const cyrus::RenderPacket> packet;};
    std::vector<Entry> stage;std::vector<INode*> created;std::vector<AnimHandle> handles;stage.reserve(512);created.reserve(512);handles.reserve(512);
    try{
        for(unsigned li=0;li<runtime->sources.size();++li)for(unsigned si=0;si<runtime->sources[li].size();++si){if(!runtime->renderEnabled[li]||!runtime->engine->layout().layers[li].react)continue;
            if(stage.size()>=512)throw std::runtime_error("Interaction output budget: 512 source bindings");
            auto key=runtime->layerIDs[li]+"|"+runtime->rows[li].sourceCohort()->sources()[si].id;INode* node=nullptr;
            for(int i=0;i<old->size;++i){auto* candidate=old->data[i]->to_node();auto* object=cyrus::output(candidate);if(object&&object->key==key&&(!object->owner||object->owner==runtime->controller)){node=candidate;break;}}
            if(!node){auto deleter=[](cyrus::InteractionRender* value){value->DeleteThis();};std::unique_ptr<cyrus::InteractionRender,decltype(deleter)> pending(new cyrus::InteractionRender,deleter);node=GetCOREInterface()->CreateObjectNode(pending.get());if(!node)throw std::runtime_error("Interaction output creation failed");pending.release();created.push_back(node);node->SetName(_T("Cyrus_Interactions_Source_Output"));node->SetNodeTM(GetCOREInterface()->GetTime(),Matrix3(1));node->IgnoreExtents(TRUE);}
            auto* source=Animatable::GetAnimByHandle(runtime->sources[li][si]->nodeHandle);auto* material=source&&source->SuperClassID()==BASENODE_CLASS_ID?static_cast<INode*>(source)->GetMtl():nullptr;
            auto* object=cyrus::output(node);stage.push_back({node,li,si,std::move(key),material,std::make_unique<cyrus::InteractionRender::OwnerWatch>(static_cast<INode*>(owner),object),cyrus::packet(runtime,runtime->current,li,si)});
            handles.push_back(Animatable::GetHandleByAnim(node));vl.result->append(MAXNode::intern(node));}
    }catch(const std::exception& error){stage.clear();for(auto* node:created)GetCOREInterface()->DeleteNode(node,FALSE);throw RuntimeError(MSTR::FromACP(error.what()));}
    catch(...){stage.clear();for(auto* node:created)GetCOREInterface()->DeleteNode(node,FALSE);throw;}
    // No fallible packet/vector/reference preparation remains. Previous output
    // nodes are untouched until every binding has a complete successor.
    for(auto& item:stage){auto* object=cyrus::output(item.node);object->owner=runtime->controller;object->layer=item.layer;object->slot=item.slot;object->key=std::move(item.key);object->watch=std::move(item.watch);object->packet.store(std::move(item.packet));object->ivalid.SetEmpty();}
    runtime->renderNodes.swap(handles);
    for(auto& item:stage){try{item.node->SetMtl(item.material);item.node->SetRenderable(TRUE);cyrus::output(item.node)->NotifyDependents(FOREVER,PART_GEOM,REFMSG_CHANGE);}catch(...){/* An observer cannot roll back complete numeric packets. */}}
    return_value(vl.result);
}

def_visible_primitive(cyrusInteractionBake,"cyrusInteractionBake");
Value* cyrusInteractionBake_cf(Value** a,int n){check_arg_count(cyrusInteractionBake,2,n);auto runtime=cyrus::interactionRuntime(a[0]);const int layer=a[1]->to_int()-1;
    if(!cyrusBoundaryAllows(runtime.get()))throw RuntimeError(_T("Active Cyrus authoring license required to Bake contacts"));
    if(layer<0||layer>=int(runtime->sources.size()))throw RuntimeError(_T("Invalid interaction Bake layer"));
    one_typed_value_local(Array* result);vl.result=new Array(0);std::vector<INode*> created;created.reserve(runtime->sources[layer].size());
    try{if(runtime->engine->layout().layers[layer].react)for(unsigned slot=0;slot<runtime->sources[layer].size();++slot){auto p=cyrus::packet(runtime,runtime->current,unsigned(layer),slot);auto mesh=cyrus::build(*p);if(!mesh->getNumFaces())continue;
        if(!cyrusBoundaryAllows(runtime.get()))throw std::runtime_error("Cyrus license expired before Bake publication; created nodes rolled back");
        auto deleter=[](TriObject* value){value->DeleteThis();};std::unique_ptr<TriObject,decltype(deleter)> pending(CreateNewTriObject(),deleter);pending->GetMesh()=*mesh;auto* node=GetCOREInterface()->CreateObjectNode(pending.get());if(!node)throw std::runtime_error("Posed Bake node allocation failed");pending.release();created.push_back(node);node->SetName(_T("Cyrus_Baked_Contact_Mesh"));node->SetNodeTM(GetCOREInterface()->GetTime(),Matrix3(1));
        auto* source=Animatable::GetAnimByHandle(runtime->sources[layer][slot]->nodeHandle);if(source&&source->SuperClassID()==BASENODE_CLASS_ID)node->SetMtl(static_cast<INode*>(source)->GetMtl());node->SetRenderable(TRUE);vl.result->append(MAXNode::intern(node));}
    }catch(const std::exception& error){for(auto* node:created)GetCOREInterface()->DeleteNode(node,FALSE);throw RuntimeError(MSTR::FromACP(error.what()));}
    return_value(vl.result);
}

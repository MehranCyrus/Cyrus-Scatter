// Native procedural Brush document and Max Painter adapter for Cyrus Scatter.
#include <max.h>
#include <iparamb2.h>
#include <triobj.h>
#include <IPainterInterface.h>
#include <notify.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "brush.h"
#include <algorithm>
#include <cmath>
#include <memory>
#include <chrono>
#include <string>

namespace {
namespace b=cyrus::brush;
const Class_ID documentID(0x5c743810,0x229f3ab6);
HINSTANCE instance=nullptr;
std::string storageTrace;
b::Vec3 vec(Point3 p){return {p.x,p.y,p.z};}
Point3 point(b::Vec3 p){return {float(p.x),float(p.y),float(p.z)};}
class PaintDocument;
class TargetPatch:public PostPatchProc {
    PaintDocument* copy;
    ReferenceTarget* original;
public:
    TargetPatch(PaintDocument* c,ReferenceTarget* t):copy(c),original(t){}
    int Proc(RemapDir&)override;
};
PaintDocument* active=nullptr;
void sceneEvent(void*,NotifyInfo*);
struct TriDelete{void operator()(TriObject* p)const{if(p)p->DeleteThis();}};
class PaintRestore:public RestoreObj {
    SingleRefMaker lifetime;
    PaintDocument* owner; b::Document before,after;
public:
    explicit PaintRestore(PaintDocument*);
    void Restore(int)override;void Redo()override;
    MSTR Description()override{return _T("Cyrus Brush stroke");}
};
class PaintDocument:public ReferenceTarget,public IPainterCanvasInterface_V5,public IPainterCanvasInterface_V26_1 {
public:
    struct RightClickHandler:public IPainterRightClickHandler {
        PaintDocument* owner;
        explicit RightClickHandler(PaintDocument* p):owner(p){}
        void RightClick()override{owner->stop();}
    } rightClick{this};
    INode* target=nullptr;
    b::Document document;
    std::unique_ptr<TriObject,TriDelete> snapshot;
    std::unique_ptr<b::Surface> surface;
    std::unique_ptr<b::Field> field;
    std::uint64_t fieldIndexRevision=0,maskApplications=0;
    Matrix3 objectTM{1};
    IPainterInterface_V14* painter=nullptr;
    bool invalid=true,painting=false,gesture=false,ending=false,pathConnected=false;
    b::Stroke pending;
    double radius=20,strength=1,softness=.5,density=1;
    bool erase=false;
    std::uint64_t revision=1,fieldRevision=0,picks=0,baseBuilds=0,fieldBuilds=0,queries=0;
    std::uint64_t repairedHits=0;
    TimeValue snapshotTime=0;
    double maxHitError=0,lastEvaluationMs=0;
    // An independent bounded surface overlay, unrelated to surviving plants.
    unsigned capacity=2048,seed=42;
    std::vector<amin::Instance> candidates;
    std::vector<b::Anchor> anchors;
    std::vector<double> weights;
    std::vector<std::pair<Point3,float>> overlay;
    std::string error;
    struct Options {
        BOOL gather,normalData,mirror,update,pressure,preSize,preStr,ring,normal,trace,spline;
        float minSize,maxSize,minStr,maxStr;int lag;
    } old{};
    PaintDocument(){for(int code:{NOTIFY_SYSTEM_PRE_RESET,NOTIFY_FILE_PRE_OPEN,NOTIFY_FILE_PRE_SAVE})RegisterNotification(sceneEvent,this,code);}
    ~PaintDocument()override{stop();for(int code:{NOTIFY_SYSTEM_PRE_RESET,NOTIFY_FILE_PRE_OPEN,NOTIFY_FILE_PRE_SAVE})UnRegisterNotification(sceneEvent,this,code);DeleteAllRefsFromMe();}
    void DeleteThis()override{delete this;}
    Class_ID ClassID()override{return documentID;}
    SClass_ID SuperClassID()override{return REF_TARGET_CLASS_ID;}
    void GetClassName(MSTR& s,bool)const override{s=_T("Cyrus Brush Document");}
    int NumRefs()override{return 1;}
    RefTargetHandle GetReference(int i)override{return i==0?target:nullptr;}
    void SetReference(int i,RefTargetHandle r)override{if(i==0)target=static_cast<INode*>(r);}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID& part,RefMessage message,BOOL)override{
        if(message==REFMSG_TARGET_DELETED){target=nullptr;invalid=true;error="Paint target was deleted";}
        if(message==REFMSG_CHANGE&&(part&(PART_GEOM|PART_TOPO|PART_TM))){invalid=true;error="Target changed; stop and validate before painting";}
        return REF_SUCCEED;
    }
    RefTargetHandle Clone(RemapDir& remap)override{
        auto* copy=new PaintDocument;copy->document=document;copy->radius=radius;copy->strength=strength;copy->softness=softness;copy->density=density;copy->capacity=capacity;copy->seed=seed;copy->erase=erase;
        // The surface is an external scene node. Copying a controller alone
        // keeps that reference; cloning both remaps it after all nodes exist.
        copy->ReplaceReference(0,target);remap.AddPostPatchProc(new TargetPatch(copy,target),true);
        BaseClone(this,copy,remap);return copy;
    }
    void* GetInterface(ULONG id)override{
        if(id==PAINTERCANVASINTERFACE_V5)return static_cast<IPainterCanvasInterface_V5*>(this);
        if(id==PAINTERCANVASINTERFACE_V26_1)return static_cast<IPainterCanvasInterface_V26_1*>(this);
        return ReferenceTarget::GetInterface(id);
    }
    bool IsGeometryConstant()override{return true;}
    void changed(){++revision;NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE);}
    void prepare(INode* node,bool requirePaintable=false){
        if(painting)throw std::runtime_error("End painting before binding the surface");
        if(!node||(requirePaintable&&(node->IsHidden()||node->IsFrozen())))throw std::runtime_error("Choose a visible unfrozen mesh target for painting");
        const auto t=GetCOREInterface()->GetTime();Object* obj=node->EvalWorldState(t).obj;
        if(!obj||!obj->CanConvertToType(triObjectClassID))throw std::runtime_error("Target cannot be triangulated");
        auto* tri=static_cast<TriObject*>(obj->ConvertToType(t,triObjectClassID));
        if(!tri)throw std::runtime_error("Target triangulation failed");
        std::unique_ptr<TriObject,TriDelete> owned(CreateNewTriObject());
        try{owned->GetMesh()=tri->GetMesh();}catch(...){if(tri!=obj)tri->DeleteThis();throw;}
        if(tri!=obj)tri->DeleteThis();
        auto& m=owned->GetMesh();b::Mesh mesh;mesh.vertices.reserve(m.numVerts);mesh.faces.reserve(m.numFaces);
        for(int i=0;i<m.numVerts;++i)mesh.vertices.push_back(vec(m.verts[i]));
        for(int i=0;i<m.numFaces;++i)mesh.faces.push_back({m.faces[i].v[0],m.faces[i].v[1],m.faces[i].v[2]});
        auto next=std::make_unique<b::Surface>(std::move(mesh));
        if(!document.strokes.empty()&&document.surface!=next->fingerprint())throw std::runtime_error("Surface shape/topology changed. Paint preserved; strokes are preserved; restore the original topology or create a new Brush document");
        objectTM=node->GetObjectTM(t);snapshotTime=t;
        if(std::abs(DotProd(objectTM.GetRow(0),CrossProd(objectTM.GetRow(1),objectTM.GetRow(2))))<1e-12)throw std::runtime_error("Singular target transform");
        ReplaceReference(0,node);snapshot=std::move(owned);surface=std::move(next);document.surface=surface->fingerprint();invalid=false;error.clear();
        rebuildCandidates();changed();
    }
    void pollTarget(){if(target&&GetCOREInterface()->GetTime()==snapshotTime)return;
        invalid=true;error="Target lifetime or time changed; validate before painting";}
    void valid(bool requirePaintable=true){pollTarget();if(!target||invalid||!surface)throw std::runtime_error("Brush target requires validation");if(requirePaintable&&(target->IsHidden()||target->IsFrozen()))throw std::runtime_error("Painting requires a visible unfrozen target");}
    void ensureSurface(bool requirePaintable=false){pollTarget();if((invalid||!surface)&&!painting)prepare(target,requirePaintable);valid(requirePaintable);}
    b::View captureView(){
        auto& view=GetCOREInterface()->GetActiveViewExp();if(!view.IsAlive())throw std::runtime_error("No active viewport");
        Matrix3 toView;view.GetAffineTM(toView);Matrix3 camera=Inverse(toView),toLocal=Inverse(objectTM);
        return {vec(camera.GetTrans()*toLocal),vec(VectorTransform(toLocal,-camera.GetRow(2))),view.IsPerspView()!=FALSE};
    }
    b::Ray ray(IPoint2 mouse){
        auto& view=GetCOREInterface()->GetActiveViewExp();if(!view.IsAlive())throw std::runtime_error("No active viewport");
        ::Ray r;view.MapScreenToWorldRay(float(mouse.x),float(mouse.y),r);
        Matrix3 tm;view.GetAffineTM(tm);const auto camera=Inverse(tm);
        const float depth=DotProd(r.dir,-Normalize(camera.GetRow(2)));
        if(std::abs(depth)<1e-8f)throw std::runtime_error("Invalid viewport projection");
        r.dir/=depth;const auto inv=Inverse(objectTM);return {vec(r.p*inv),vec(VectorTransform(inv,r.dir))};
    }
    b::Sample sample(b::Anchor a){b::Sample s;s.anchor=a;for(int i=0;i<3;++i)s.basis[i]=vec(objectTM.GetRow(i));s.view=captureView();return s;}
    void rebuildCandidates(){
        valid(false);std::vector<amin::Triangle> triangles;for(const auto& f:surface->mesh().faces)triangles.push_back({surface->mesh().vertices[f[0]],surface->mesh().vertices[f[1]],surface->mesh().vertices[f[2]]});
        amin::Settings settings;settings.count=capacity;settings.seed=seed;settings.uniformScale={1,1};settings.rotationDegrees={{{0,0},{0,0},{0,360}}};
        auto rows=amin::scatter(triangles,settings);std::vector<b::Anchor> next;next.reserve(rows.size());
        for(const auto& row:rows){const auto& tri=triangles.at(row.triangle);const auto v0=tri.b-tri.a,v1=tri.c-tri.a,v2=row.position-tri.a;
            const double d00=amin::dot(v0,v0),d01=amin::dot(v0,v1),d11=amin::dot(v1,v1),d20=amin::dot(v2,v0),d21=amin::dot(v2,v1),den=d00*d11-d01*d01;
            const double y=(d11*d20-d01*d21)/den,z=(d00*d21-d01*d20)/den;b::Anchor a{row.triangle,{1-y-z,y,z}};
            if(amin::length(surface->position(a)-row.position)>1e-6)throw std::runtime_error("Candidate anchor mismatch");next.push_back(a);
        }
        candidates=std::move(rows);anchors=std::move(next);weights.clear();++baseBuilds;fieldRevision=0;fieldIndexRevision=0;
    }
    const b::Field& fieldForRevision(){
        ensureSurface();
        if(!field||fieldIndexRevision!=revision){
            b::Document current=document;if(gesture&&!pending.samples.empty())current.strokes.push_back(pending);
            field=std::make_unique<b::Field>(*surface,current);fieldIndexRevision=revision;++fieldBuilds;
        }
        return *field;
    }
    void evaluate(){
        ensureSurface();if(fieldRevision==revision)return;
        const auto start=std::chrono::steady_clock::now();const auto& indexed=fieldForRevision();std::vector<double> next;next.reserve(anchors.size());b::QueryStats stats;
        std::vector<std::pair<Point3,float>> nextOverlay;
        for(std::size_t i=0;i<anchors.size();++i){const auto w=indexed.evaluate(anchors[i],&stats);next.push_back(w);if(w>0)nextOverlay.push_back({point(candidates[i].position)*objectTM,float(w)});}
        weights=std::move(next);overlay=std::move(nextOverlay);queries+=stats.fieldQueries;fieldRevision=revision;
        lastEvaluationMs=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();
    }
    void restoreOptions(){if(!painter)return;
        painter->SetEnablePointGather(old.gather);painter->SetBuildNormalData(old.normalData);painter->SetMirrorEnable(old.mirror);painter->SetUpdateOnMouseUp(old.update);painter->SetPressureEnable(old.pressure);painter->SetPredefinedSizeEnable(old.preSize);painter->SetPredefinedStrEnable(old.preStr);painter->SetDrawRing(old.ring);painter->SetDrawNormal(old.normal);painter->SetDrawTrace(old.trace);painter->SetUseSplineConstraint(old.spline);painter->SetMinSize(old.minSize);painter->SetMaxSize(old.maxSize);painter->SetMinStr(old.minStr);painter->SetMaxStr(old.maxStr);painter->SetLagRate(old.lag);
    }
    void begin(){
        if(painting)return;if(active)throw std::runtime_error("Another Cyrus Brush session is active");prepare(target,true);
        auto* ref=static_cast<ReferenceTarget*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,PAINTERINTERFACE_CLASS_ID));
        painter=ref?static_cast<IPainterInterface_V14*>(ref->GetInterface(PAINTERINTERFACE_V14)):nullptr;
        if(!painter)throw std::runtime_error("Max Painter V14/V7 unavailable");
        if(painter->InPaintMode())throw std::runtime_error("Another Max paint tool owns the viewport");
        old={painter->GetEnablePointGather(),painter->GetBuildNormalData(),painter->GetMirrorEnable(),painter->GetUpdateOnMouseUp(),painter->GetPressureEnable(),painter->GetPredefinedSizeEnable(),painter->GetPredefinedStrEnable(),painter->GetDrawRing(),painter->GetDrawNormal(),painter->GetDrawTrace(),painter->GetUseSplineConstraint(),painter->GetMinSize(),painter->GetMaxSize(),painter->GetMinStr(),painter->GetMaxStr(),painter->GetLagRate()};
        active=this;painting=true;
        try{
            painter->SetEnablePointGather(FALSE);painter->SetBuildNormalData(FALSE);painter->SetMirrorEnable(FALSE);painter->SetUpdateOnMouseUp(FALSE);painter->SetPressureEnable(FALSE);painter->SetPredefinedSizeEnable(FALSE);painter->SetPredefinedStrEnable(FALSE);painter->SetDrawRing(TRUE);painter->SetDrawNormal(TRUE);painter->SetDrawTrace(FALSE);painter->SetUseSplineConstraint(FALSE);painter->SetLagRate(0);
            // Painter's size is a diameter (the SDK halves it for its ring).
            painter->SetMinSize(float(2*radius));painter->SetMaxSize(float(2*radius));painter->SetMinStr(1);painter->SetMaxStr(1);
            if(!painter->InitializeCallback(this))throw std::runtime_error("Painter callback rejected");
            Tab<INode*> nodes;nodes.Append(1,&target);ObjectState state(snapshot.get());Tab<ObjectState> states;states.Append(1,&state);
            if(!painter->InitializeNodesByObjState(0,nodes,states)||!painter->StartPaintSession(&rightClick))throw std::runtime_error("Painter session failed");
        }catch(...){stop();throw;}
    }
    void stop(){
        if(!painting||ending)return;ending=true;CancelStroke();
        if(painter){painter->EndPaintSession();painter->InitializeCallback(nullptr);Tab<INode*> none;painter->InitializeNodes(0,none);restoreOptions();}
        painting=false;if(active==this)active=nullptr;ending=false;
    }
    BOOL StartStroke()override{try{valid();if(gesture)return TRUE;pending={};pending.id=1;for(const auto& s:document.strokes)pending.id=std::max(pending.id,s.id+1);pending.radius=radius;pending.strength=strength;pending.softness=softness;pending.erase=erase;gesture=true;pathConnected=false;return TRUE;}catch(const std::exception& e){error=e.what();return FALSE;}}
    void add(IPoint2 mouse,b::Anchor anchor){
        valid();if(!gesture&&!StartStroke())throw std::runtime_error(error);
        // Store raw cursor input. The core resamples/re-hits it when radius changes.
        auto s=sample(anchor);s.ray=ray(mouse);s.screen={double(mouse.x),double(mouse.y)};s.hasPath=true;
        if(!pending.samples.empty()){
            const auto& last=pending.samples.back();
            bool same=s.view.perspective==last.view.perspective&&amin::length(s.view.eye-last.view.eye)<1e-8&&amin::length(s.view.direction-last.view.direction)<1e-8;
            for(int k=0;k<3;++k)same=same&&amin::length(s.basis[k]-last.basis[k])<1e-8;
            s.connected=pathConnected&&same;
            if(s.connected&&s.screen==last.screen)return;
        }
        if(pending.samples.size()>=100000)throw std::runtime_error("Stroke sample limit reached");
        pending.samples.push_back(s);pathConnected=true;++revision;
    }
    BOOL PaintStroke(BOOL hit,IPoint2 mouse,Point3 world,Point3,Point3,Point3,Point3 bary,int face,BOOL,BOOL,BOOL,float,float,float,INode* node,BOOL,Point3,Point3,Point3,Point3)override{
        try{valid();if(!hit||node!=target){pathConnected=false;return TRUE;}if(face<0||static_cast<std::size_t>(face)>=surface->mesh().faces.size())throw std::runtime_error("Painter face outside supplied snapshot");
            // Painter's screen-space face choice can put barycentrics outside
            // the chosen triangle near an edge. Use an exact ray query on the
            // SAME indexed snapshot for persistent anchors and nearest depth.
            b::Hit canonical;if(!surface->hit(ray(mouse),canonical)){pathConnected=false;return TRUE;}
            const double delta=Length(point(surface->position(canonical.anchor))*objectTM-world);maxHitError=std::max(maxHitError,delta);++picks;
            if(canonical.anchor.face!=static_cast<unsigned>(face)||std::min({bary.x,bary.y,bary.z})<0)++repairedHits;
            add(mouse,canonical.anchor);return TRUE;
        }catch(const std::exception& e){error=e.what();CancelStroke();return FALSE;}
    }
    BOOL EndStroke()override{
        if(!gesture)return TRUE;
        bool holding=false;
        try{valid();if(!pending.samples.empty()){
            std::size_t total=pending.samples.size();for(const auto& s:document.strokes)total+=s.samples.size();
            if(document.strokes.size()>=10000||total>1000000)throw std::runtime_error("Brush document capacity reached");
            b::validate(pending);document.strokes.reserve(document.strokes.size()+1);
            auto restore=std::make_unique<PaintRestore>(this);
            theHold.Begin();holding=true;theHold.Put(restore.release());document.strokes.push_back(std::move(pending));gesture=false;changed();theHold.Accept(_T("Cyrus Brush stroke"));holding=false;
        }else gesture=false;return TRUE;
        }catch(const std::exception& e){if(holding)theHold.Cancel();CancelStroke();error=e.what();return FALSE;}
    }
    BOOL EndStroke(int n,BOOL* hit,IPoint2* mouse,Point3* world,Point3* normal,Point3* local,Point3* localNormal,Point3* bary,int* index,BOOL* shift,BOOL* ctrl,BOOL* alt,float* size,float* str,float* pressure,INode** nodes,BOOL mirror,Point3* mw,Point3* mn,Point3* ml,Point3* mln)override{
        for(int i=0;i<n;++i)if(!PaintStroke(hit[i],mouse[i],world[i],normal[i],local[i],localNormal[i],bary[i],index[i],shift[i],ctrl[i],alt[i],size[i],str[i],pressure[i],nodes[i],mirror,mw?mw[i]:Point3(0,0,0),mn?mn[i]:Point3(0,0,0),ml?ml[i]:Point3(0,0,0),mln?mln[i]:Point3(0,0,0)))return FALSE;return EndStroke();
    }
    BOOL CancelStroke()override{if(gesture){gesture=false;pending={};++revision;}return TRUE;}
    BOOL SystemEndPaintSession()override{CancelStroke();if(!ending){restoreOptions();painting=false;if(active==this)active=nullptr;}return TRUE;}
    void PainterDisplay(TimeValue,ViewExp* view,int)override{
        // Display consumes completed numeric overlay only; no mesh evaluation,
        // field queries, scene creation, or buffer publication belongs here.
        if(invalid||!painting||!view)return;auto* gw=view->getGW();if(!gw)return;const auto limits=gw->getRndLimits();gw->setTransform(Matrix3(1));gw->setRndLimits(limits|GW_Z_BUFFER);
        for(auto v:overlay){gw->setColor(LINE_COLOR,Point3(v.second,v.second,v.second));gw->marker(&v.first,POINT_MRKR);}gw->setRndLimits(limits);
    }
    IOResult Save(ISave* save)override{
        try{auto bytes=b::encode(document);save->BeginChunk(0x7301);ULONG done=0;auto result=save->Write(bytes.data(),static_cast<ULONG>(bytes.size()),&done);save->EndChunk();if(result!=IO_OK||done!=bytes.size())return IO_ERROR;
            save->BeginChunk(0x7302);double settings[]={radius,strength,softness,density,double(capacity),double(seed)};result=save->Write(settings,sizeof(settings),&done);save->EndChunk();return result;
        }catch(...){return IO_ERROR;}
    }
    IOResult Load(ILoad* load)override{
        IOResult result;try{while((result=load->OpenChunk())==IO_OK){const auto id=load->CurChunkID();const auto length=load->CurChunkLength();storageTrace+="Chunk "+std::to_string(id)+" bytes "+std::to_string(length)+"\n";if(length>240000000)throw std::runtime_error("Brush chunk size limit");ULONG done=0;
            if(id==0x7301){std::vector<std::uint8_t> bytes(static_cast<std::size_t>(length));if(load->Read(bytes.data(),static_cast<ULONG>(length),&done)!=IO_OK||done!=length)throw std::runtime_error("Brush payload read failed");document=b::decode(bytes);}
            if(id==0x7302){double values[6];if(length!=sizeof(values)||load->Read(values,sizeof(values),&done)!=IO_OK||done!=sizeof(values))throw std::runtime_error("Brush settings read failed");for(double v:values)if(!std::isfinite(v))throw std::runtime_error("Non-finite Brush settings");
                if(values[0]<=0||values[1]<0||values[1]>1||values[2]<0||values[2]>1||values[3]<0||values[3]>1||values[4]<1||values[4]>100000||values[5]<0||values[5]>INT_MAX)throw std::runtime_error("Invalid saved Brush settings");
                radius=values[0];strength=values[1];softness=values[2];density=values[3];capacity=static_cast<unsigned>(values[4]);seed=static_cast<unsigned>(values[5]);}
            load->CloseChunk();}
        }catch(const std::exception& e){storageTrace+=std::string("ERROR ")+e.what()+"\n";return IO_ERROR;}storageTrace+="Load end "+std::to_string(result)+"\n";return result==IO_END?IO_OK:result;
    }
};
int TargetPatch::Proc(RemapDir& remap){auto* mapped=remap.FindMapping(original);copy->ReplaceReference(0,mapped?mapped:original);return 0;}
PaintRestore::PaintRestore(PaintDocument* p):owner(p),before(p->document){lifetime.SetRef(p);}
void PaintRestore::Restore(int undo){owner->CancelStroke();if(undo)after=owner->document;owner->document=before;owner->changed();}
void PaintRestore::Redo(){owner->CancelStroke();owner->document=after;owner->changed();}
void sceneEvent(void* data,NotifyInfo* info){auto* doc=static_cast<PaintDocument*>(data);if(active!=doc)return;if(info->intcode==NOTIFY_FILE_PRE_SAVE)doc->EndStroke();doc->stop();}
class DocumentDesc:public ClassDesc2 {
public:
    int IsPublic()override{return FALSE;}
    void* Create(BOOL)override{return new PaintDocument;}
    const MCHAR* ClassName()override{return _T("Cyrus Brush Document");}
    const MCHAR* NonLocalizedClassName()override{return _T("Cyrus Brush Document");}
    SClass_ID SuperClassID()override{return REF_TARGET_CLASS_ID;}
    Class_ID ClassID()override{return documentID;}
    const MCHAR* Category()override{return _T("Cyrus");}
    const MCHAR* InternalName()override{return _T("CyrusBrushDocument");}
    HINSTANCE HInstance()override{return instance;}
};
PaintDocument* doc(Value* value){auto* r=value->to_reftarg();if(!r||r->ClassID()!=documentID)throw RuntimeError(_T("Expected Cyrus Brush document"));return static_cast<PaintDocument*>(r);}
template<class F> Value* api(F f){try{return f();}catch(const std::exception& e){std::string s=e.what();throw RuntimeError(MSTR(std::wstring(s.begin(),s.end()).c_str()));}}
}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Scatter 1.0 procedural Brush");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){static DocumentDesc desc;return i==0?&desc:nullptr;}
extern "C" __declspec(dllexport) ClassDesc* CyrusBrushDocumentDesc(){return LibClassDesc(0);}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE module,DWORD reason,LPVOID){if(reason==DLL_PROCESS_ATTACH)instance=module;return TRUE;}
static_assert(MAX_PRODUCT_YEAR_NUMBER==CYRUS_MAX_YEAR,"Brush SDK mismatch");

def_visible_primitive(cyrusBrushCreate,"cyrusBrushCreate");
Value* cyrusBrushCreate_cf(Value** a,int n){check_arg_count(cyrusBrushCreate,1,n);return api([&]()->Value*{std::unique_ptr<PaintDocument> p(static_cast<PaintDocument*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,documentID)));if(!p)throw std::runtime_error("Brush storage class unavailable. Load matching CyrusBrushStorage.dlh and CyrusBrush.dlx");p->prepare(a[0]->to_node());return MAXRefTarg::intern(p.release());});}
def_visible_primitive(cyrusBrushBind,"cyrusBrushBind");
Value* cyrusBrushBind_cf(Value** a,int n){check_arg_count(cyrusBrushBind,1,n);return api([&]()->Value*{auto* p=doc(a[0]);p->prepare(p->target);return &ok;});}
def_visible_primitive(cyrusBrushBegin,"cyrusBrushBegin");
Value* cyrusBrushBegin_cf(Value** a,int n){check_arg_count(cyrusBrushBegin,1,n);return api([&]()->Value*{doc(a[0])->begin();return &ok;});}
def_visible_primitive(cyrusBrushStop,"cyrusBrushStop");
Value* cyrusBrushStop_cf(Value**,int n){check_arg_count(cyrusBrushStop,0,n);if(active)active->stop();return &ok;}
def_visible_primitive(cyrusBrushSettings,"cyrusBrushSettings");
Value* cyrusBrushSettings_cf(Value** a,int n){check_arg_count(cyrusBrushSettings,6,n);return api([&]()->Value*{auto* p=doc(a[0]);if(p->gesture)throw std::runtime_error("Finish the stroke before changing settings");b::Stroke check;check.radius=a[1]->to_float();check.strength=a[2]->to_float();check.softness=a[3]->to_float();b::validate(check);const auto density=a[5]->to_float();if(!std::isfinite(density)||density<0||density>1)throw std::runtime_error("Density must be 0..1");p->radius=check.radius;p->strength=check.strength;p->softness=check.softness;p->erase=a[4]->to_bool()!=FALSE;p->density=density;if(p->painting){p->painter->SetMinSize(float(2*p->radius));p->painter->SetMaxSize(float(2*p->radius));}p->NotifyDependents(FOREVER,PART_DISPLAY,REFMSG_CHANGE);return &ok;});}
def_visible_primitive(cyrusBrushStats,"cyrusBrushStats");
Value* cyrusBrushStats_cf(Value** a,int n){check_arg_count(cyrusBrushStats,1,n);auto* p=doc(a[0]);p->pollTarget();if(p->painting&&(p->invalid||!p->target||p->target->IsHidden()||p->target->IsFrozen()))p->stop();one_typed_value_local(Array* result);vl.result=new Array(14);std::size_t samples=0;for(const auto& s:p->document.strokes)samples+=s.samples.size();for(auto v:{p->revision,std::uint64_t(p->document.strokes.size()),std::uint64_t(samples),std::uint64_t(!p->invalid),std::uint64_t(p->painting),std::uint64_t(p->gesture),p->picks,p->baseBuilds,p->fieldBuilds,p->queries})vl.result->append(Integer64::intern(v));vl.result->append(new String(std::wstring(p->error.begin(),p->error.end()).c_str()));vl.result->append(Float::intern(float(p->maxHitError)));vl.result->append(Float::intern(float(p->lastEvaluationMs)));vl.result->append(Integer64::intern(p->repairedHits));vl.result->append(Integer64::intern(p->maskApplications));vl.result->append(Integer::intern(int(p->overlay.size())));vl.result->append(Float::intern(float(p->document.base)));return_value(vl.result);}
def_visible_primitive(cyrusBrushRows,"cyrusBrushRows");
Value* cyrusBrushRows_cf(Value** a,int n){check_arg_count(cyrusBrushRows,1,n);return api([&]()->Value*{auto* p=doc(a[0]);p->evaluate();two_typed_value_locals(Array* result,Array* row);vl.result=new Array(0);
    const auto population=p->document.surface^p->seed^p->capacity;
    for(std::size_t i=0;i<p->candidates.size();++i)if(b::accepted(population,i,p->weights[i],p->density)){const auto& v=p->candidates[i];Matrix3 tm(1);tm.SetRow(0,point(v.xAxis*v.scale));tm.SetRow(1,point(v.yAxis*v.scale));tm.SetRow(2,point(v.zAxis*v.scale));tm.SetTrans(point(v.position));vl.row=new Array(2);vl.row->append(new Matrix3Value(tm*p->objectTM));vl.row->append(Integer::intern(1));vl.result->append(vl.row);}return_value(vl.result);});}
def_visible_primitive(cyrusBrushRefreshMask,"cyrusBrushRefreshMask");
Value* cyrusBrushRefreshMask_cf(Value** a,int n){check_arg_count(cyrusBrushRefreshMask,1,n);return api([&]()->Value*{doc(a[0])->evaluate();return &ok;});}
def_visible_primitive(cyrusBrushStroke,"cyrusBrushStroke");
Value* cyrusBrushStroke_cf(Value** a,int n){if(n!=5&&n!=7)throw RuntimeError(_T("Expected 5 or 7 Brush stroke arguments"));return api([&]()->Value*{auto* p=doc(a[0]);p->ensureSurface();if(p->gesture)throw std::runtime_error("Finish the active stroke");const int i=a[1]->to_int()-1;if(i<0||i>=int(p->document.strokes.size()))throw std::runtime_error("Invalid stroke index");auto s=p->document.strokes[i];s.enabled=a[2]->to_bool()!=FALSE;s.strength=a[3]->to_float();s.radius=a[4]->to_float();if(n==7){s.softness=a[5]->to_float();s.erase=a[6]->to_bool()!=FALSE;}b::validate(s);theHold.Begin();theHold.Put(new PaintRestore(p));p->document.strokes[i]=std::move(s);p->changed();theHold.Accept(_T("Edit Cyrus Brush stroke"));return &ok;});}
def_visible_primitive(cyrusBrushDab,"cyrusBrushDab");
Value* cyrusBrushDab_cf(Value** a,int n){check_arg_count(cyrusBrushDab,4,n);return api([&]()->Value*{auto* p=doc(a[0]);p->valid();b::Hit hit;if(!p->surface->hit({vec(a[1]->to_point3()),vec(a[2]->to_point3())},hit))return &false_value;if(!p->gesture)p->StartStroke();p->pending.samples.push_back(p->sample(hit.anchor));++p->revision;if(a[3]->to_bool())p->EndStroke();return &true_value;});}
def_visible_primitive(cyrusBrushCancel,"cyrusBrushCancel");
Value* cyrusBrushCancel_cf(Value** a,int n){check_arg_count(cyrusBrushCancel,1,n);doc(a[0])->CancelStroke();return &ok;}
def_visible_primitive(cyrusBrushProbe,"cyrusBrushProbe");
Value* cyrusBrushProbe_cf(Value** a,int n){check_arg_count(cyrusBrushProbe,2,n);return api([&]()->Value*{auto* p=doc(a[0]);p->valid();if(!p->painting)throw std::runtime_error("Start Painter before probing");auto xy=a[1]->to_point2();IPoint2 mouse(int(xy.x),int(xy.y));Point3 w,wn,l,ln,bary,mw,mwn,ml,mln;int face=-1;BOOL mirror=FALSE;
    ObjectState state(p->snapshot.get());Tab<ObjectState> states;states.Append(1,&state);p->painter->UpdateMeshesByObjState(FALSE,states);
    const BOOL hit=p->painter->TestHit(mouse,w,wn,l,ln,bary,face,p->target,mirror,mw,mwn,ml,mln);if(!hit)return &undefined;
    const auto& mesh=p->surface->mesh();const auto f=mesh.faces.at(face);
    const auto reconstructed=mesh.vertices[f[0]]*bary.x+mesh.vertices[f[1]]*bary.y+mesh.vertices[f[2]]*bary.z;
    const auto delta=Length(point(reconstructed)*p->objectTM-w);b::Hit ours;const bool ownHit=p->surface->hit(p->ray(mouse),ours);
    b::Hit oracle;const bool referenceHit=p->surface->hitReference(p->ray(mouse),oracle);
    if(ownHit!=referenceHit||(ownHit&&(std::abs(ours.distance-oracle.distance)>1e-7||ours.anchor.face!=oracle.anchor.face)))throw std::runtime_error("Brush BVH disagrees with exhaustive snapshot ray query");
    one_typed_value_local(Array* result);vl.result=new Array(6);vl.result->append(Integer::intern(face+1));vl.result->append(Float::intern(delta));vl.result->append(new Point3Value(w));vl.result->append(Float::intern(ownHit?float(Length(point(p->surface->position(ours.anchor))*p->objectTM-w)):-1));vl.result->append(std::min({bary.x,bary.y,bary.z})>=0?&true_value:&false_value);vl.result->append(&true_value);return_value(vl.result);});}
def_visible_primitive(cyrusBrushHistory,"cyrusBrushHistory");
Value* cyrusBrushHistory_cf(Value** a,int n){check_arg_count(cyrusBrushHistory,1,n);auto* p=doc(a[0]);two_typed_value_locals(Array* result,Array* row);vl.result=new Array(0);
    for(const auto& s:p->document.strokes){vl.row=new Array(6);vl.row->append(s.enabled?&true_value:&false_value);vl.row->append(s.erase?&true_value:&false_value);vl.row->append(Float::intern(float(s.radius)));vl.row->append(Float::intern(float(s.strength)));vl.row->append(Float::intern(float(s.softness)));vl.row->append(Integer::intern(int(s.samples.size())));vl.result->append(vl.row);}return_value(vl.result);}
def_visible_primitive(cyrusBrushOptions,"cyrusBrushOptions");
Value* cyrusBrushOptions_cf(Value** a,int n){check_arg_count(cyrusBrushOptions,1,n);auto* p=doc(a[0]);one_typed_value_local(Array* result);vl.result=new Array(5);for(auto v:{p->radius,p->strength,p->softness,p->density})vl.result->append(Float::intern(float(v)));vl.result->append(p->erase?&true_value:&false_value);return_value(vl.result);}
def_visible_primitive(cyrusBrushStorageLog,"cyrusBrushStorageLog");
Value* cyrusBrushStorageLog_cf(Value**,int n){check_arg_count(cyrusBrushStorageLog,0,n);return new String(std::wstring(storageTrace.begin(),storageTrace.end()).c_str());}

def_visible_primitive(cyrusBrushTarget,"cyrusBrushTarget");
Value* cyrusBrushTarget_cf(Value** a,int n){check_arg_count(cyrusBrushTarget,1,n);auto* p=doc(a[0]);return p->target?MAXNode::intern(p->target):&undefined;}

def_visible_primitive(cyrusBrushFill,"cyrusBrushFill");
Value* cyrusBrushFill_cf(Value** a,int n){check_arg_count(cyrusBrushFill,2,n);return api([&]()->Value*{
    auto* p=doc(a[0]);if(p->gesture)throw std::runtime_error("Finish the stroke before resetting the field");
    const auto value=a[1]->to_float();if(!std::isfinite(value)||value<0||value>1)throw std::runtime_error("Brush fill must be 0..1");
    theHold.Begin();theHold.Put(new PaintRestore(p));p->document.strokes.clear();p->document.base=value;p->changed();theHold.Accept(_T("Cyrus Brush fill"));return &ok;
});}

def_visible_primitive(cyrusBrushDeleteStroke,"cyrusBrushDeleteStroke");
Value* cyrusBrushDeleteStroke_cf(Value** a,int n){check_arg_count(cyrusBrushDeleteStroke,2,n);return api([&]()->Value*{
    auto* p=doc(a[0]);if(p->gesture)throw std::runtime_error("Finish the stroke before editing history");
    const int i=a[1]->to_int()-1;if(i<0||i>=int(p->document.strokes.size()))throw std::runtime_error("Invalid stroke index");
    theHold.Begin();theHold.Put(new PaintRestore(p));p->document.strokes.erase(p->document.strokes.begin()+i);p->changed();theHold.Accept(_T("Cyrus Brush delete stroke"));return &ok;
});}

// This accepts the layer's actual keyed population, not the independent mask
// overlay samples. Original transforms/source assignments and IDs are retained.
def_visible_primitive(cyrusBrushFilter,"cyrusBrushFilter");
Value* cyrusBrushFilter_cf(Value** a,int n){check_arg_count(cyrusBrushFilter,4,n);return api([&]()->Value*{
    auto* p=doc(a[0]);if(p->gesture)throw std::runtime_error("Finish the Brush stroke before publishing placements");
    type_check(a[1],Array,_T("keyed placements"));auto* rows=static_cast<Array*>(a[1]);
    const auto density=a[3]->to_float();if(!std::isfinite(density)||density<0||density>1)throw std::runtime_error("Brush density must be 0..1");
    const auto& field=p->fieldForRevision();const std::wstring identity=a[2]->to_string();std::uint64_t population=1469598103934665603ULL;
    for(const auto c:identity){population^=static_cast<std::uint16_t>(c);population*=1099511628211ULL;}
    one_typed_value_local(Array* result);vl.result=new Array(rows->size);b::QueryStats stats;
    for(int i=0;i<rows->size;++i){
        type_check(rows->data[i],Array,_T("keyed placement"));auto* row=static_cast<Array*>(rows->data[i]);if(row->size!=5)throw std::runtime_error("Brush requires canonical candidate identities and anchors");
        const auto face=row->data[3]->to_int()-1;const auto bary=vec(row->data[4]->to_point3());
        if(face<0||static_cast<std::size_t>(face)>=p->surface->mesh().faces.size())throw std::runtime_error("Brush candidate face does not match target snapshot");
        if(std::min({bary.x,bary.y,bary.z})<-1e-4||std::max({bary.x,bary.y,bary.z})>1.0001)throw std::runtime_error("Brush candidate is outside its receiving face; use projected movement");
        const double weight=field.evaluate({static_cast<unsigned>(face),bary},&stats);
        if(b::accepted(population,static_cast<std::uint64_t>(row->data[2]->to_int64()),weight,density)){
            // Downstream source offsets edit transient matrices in place. Never
            // expose a matrix owned by the immutable base-population cache.
            auto* copy=new Array(row->size);vl.result->append(copy);copy->append(new Matrix3Value(row->data[0]->to_matrix3()));for(int k=1;k<row->size;++k)copy->append(row->data[k]);
        }
    }
    p->queries+=stats.fieldQueries;++p->maskApplications;return_value(vl.result);
});}

def_visible_primitive(cyrusClonePlacementRows,"cyrusClonePlacementRows");
Value* cyrusClonePlacementRows_cf(Value** a,int n){check_arg_count(cyrusClonePlacementRows,1,n);type_check(a[0],Array,_T("placement rows"));auto* rows=static_cast<Array*>(a[0]);
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("placement row"));auto* input=static_cast<Array*>(rows->data[i]);if(input->size<2)throw RuntimeError(_T("Invalid placement row"));vl.row=new Array(input->size);vl.result->append(vl.row);vl.row->append(new Matrix3Value(input->data[0]->to_matrix3()));for(int k=1;k<input->size;++k)vl.row->append(input->data[k]);}
    return_value(vl.result);
}

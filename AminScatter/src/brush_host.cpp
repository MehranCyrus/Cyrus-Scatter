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
#include "license_boundary.h"
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
    int Size()override{return int(std::min<std::size_t>(INT_MAX,sizeof(*this)+(b::vertexCount(before)+b::vertexCount(after))*sizeof(b::Point)));}
    MSTR Description()override{return _T("Cyrus vector paint");}
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
    b::Contours receiverDomain;
    std::unique_ptr<TriObject,TriDelete> snapshot;
    std::unique_ptr<b::Surface> surface;
    std::unique_ptr<b::Field> field;
    std::vector<std::array<Point3,2>> border;
    b::Metric metric;
    b::Point lastPoint{};
    std::uint64_t fieldIndexRevision=0,maskApplications=0;
    Matrix3 objectTM{1};
    IPainterInterface_V14* painter=nullptr;
    bool invalid=true,painting=false,gesture=false,ending=false,pathConnected=false;
    b::Document pending;
    bool gestureChanged=false;
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
    cyrus::licensing::OperationPermit strokePermit;
#endif
    double radius=20;
    bool erase=false;
    std::uint64_t revision=1,fieldRevision=0,picks=0,baseBuilds=0,fieldBuilds=0,queries=0;
    std::uint64_t repairedHits=0,overlayDraws=0;
    TimeValue snapshotTime=0;
    Interval targetValidity=NEVER;
    double maxHitError=0,lastEvaluationMs=0;
    // An independent bounded surface overlay, unrelated to surviving plants.
    unsigned capacity=2048,seed=42;
    std::vector<amin::Instance> candidates;
    std::vector<b::Anchor> anchors;
    std::vector<double> weights;
    std::vector<std::pair<Point3,float>> overlay;
    int displayMode=2;
    Point3 displayColor{1.f,.65f,.2f};

    bool tintLimited=false;
    std::size_t tintFaces=0;
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
        auto* copy=new PaintDocument;copy->document=document;copy->radius=radius;copy->capacity=capacity;copy->seed=seed;copy->erase=erase;
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
    void requireAuthor(){if(!cyrusBoundaryAllows(this))throw std::runtime_error("Cyrus authoring license required; completed Brush work is preserved");}
    void prepare(INode* node,bool requirePaintable=false){
        if(painting)throw std::runtime_error("End painting before binding the surface");
        if(!node||(requirePaintable&&(node->IsHidden()||node->IsFrozen())))throw std::runtime_error("Choose a visible unfrozen mesh target for painting");
        const auto t=GetCOREInterface()->GetTime();const auto state=node->EvalWorldState(t);Object* obj=state.obj;
        Interval nextValidity=state.Validity(t);node->GetObjectTM(t,&nextValidity);
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
        if(!document.contours.empty()&&document.surface!=next->fingerprint())throw std::runtime_error("Surface shape/topology changed. Vector regions preserved; restore the original shape or create a new Paint Area");
        const auto nextTM=node->GetObjectTM(t);
        bool sameTM=true;for(int i=0;i<4;++i)sameTM=sameTM&&(objectTM.GetRow(i)==nextTM.GetRow(i));
        // Host notifications can be conservative (including a timeline change).
        // Revalidation of identical input keeps the complete prepared feedback
        // and field revision; Begin/Bind are not edits to the region.
        if(surface&&target==node&&sameTM&&surface->fingerprint()==next->fingerprint()){
            snapshotTime=t;targetValidity=nextValidity;invalid=false;error.clear();return;
        }
        auto nextDomain=b::domain(*next);
        objectTM=nextTM;metric=b::Metric::fromBasis(vec(objectTM.GetRow(0)),vec(objectTM.GetRow(1)));snapshotTime=t;targetValidity=nextValidity;
        if(std::abs(DotProd(objectTM.GetRow(0),CrossProd(objectTM.GetRow(1),objectTM.GetRow(2))))<1e-12)throw std::runtime_error("Singular target transform");
        ReplaceReference(0,node);snapshot=std::move(owned);surface=std::move(next);receiverDomain=std::move(nextDomain);document.surface=surface->fingerprint();invalid=false;error.clear();
        rebuildCandidates();changed();
    }
    void pollTarget(){if(target&&targetValidity.InInterval(GetCOREInterface()->GetTime()))return;
        invalid=true;error="Target lifetime or time changed; validate before painting";}
    void valid(bool requirePaintable=true){pollTarget();if(!target||invalid||!surface)throw std::runtime_error("Brush target requires validation");if(requirePaintable&&(target->IsHidden()||target->IsFrozen()))throw std::runtime_error("Painting requires a visible unfrozen target");}
    void ensureSurface(bool requirePaintable=false){pollTarget();if((invalid||!surface)&&!painting)prepare(target,requirePaintable);valid(requirePaintable);}
    b::Ray ray(IPoint2 mouse){
        auto& view=GetCOREInterface()->GetActiveViewExp();if(!view.IsAlive())throw std::runtime_error("No active viewport");
        ::Ray r;view.MapScreenToWorldRay(float(mouse.x),float(mouse.y),r);
        Matrix3 tm;view.GetAffineTM(tm);const auto camera=Inverse(tm);
        const float depth=DotProd(r.dir,-Normalize(camera.GetRow(2)));
        if(std::abs(depth)<1e-8f)throw std::runtime_error("Invalid viewport projection");
        r.dir/=depth;const auto inv=Inverse(objectTM);return {vec(r.p*inv),vec(VectorTransform(inv,r.dir))};
    }
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
            auto next=std::make_unique<b::Field>(*surface,gesture?pending:document,metric);
            field=std::move(next);
            fieldIndexRevision=revision;++fieldBuilds;
        }
        return *field;
    }
    void evaluate(){
        ensureSurface();if(fieldRevision==revision)return;
        const auto start=std::chrono::steady_clock::now();
        std::vector<std::pair<Point3,float>> nextOverlay;
        std::vector<std::array<Point3,2>> nextBorder;
        if(displayMode==1){
            const auto& indexed=fieldForRevision();
            for(std::size_t i=0;i<anchors.size();++i){const double w=indexed.evaluate(anchors[i]);if(w>0)nextOverlay.push_back({point(candidates[i].position)*objectTM,float(w)});}
            queries+=anchors.size();
        } else if(displayMode==2){
            for(const auto& line:b::boundary(*surface,gesture?pending:document))nextBorder.push_back({point(line[0])*objectTM,point(line[1])*objectTM});
        }
        overlay=std::move(nextOverlay);border=std::move(nextBorder);
        tintFaces=border.size();tintLimited=false;fieldRevision=revision;
        lastEvaluationMs=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();
    }

    void restoreOptions(){if(!painter)return;
        painter->SetEnablePointGather(old.gather);painter->SetBuildNormalData(old.normalData);painter->SetMirrorEnable(old.mirror);painter->SetUpdateOnMouseUp(old.update);painter->SetPressureEnable(old.pressure);painter->SetPredefinedSizeEnable(old.preSize);painter->SetPredefinedStrEnable(old.preStr);painter->SetDrawRing(old.ring);painter->SetDrawNormal(old.normal);painter->SetDrawTrace(old.trace);painter->SetUseSplineConstraint(old.spline);painter->SetMinSize(old.minSize);painter->SetMaxSize(old.maxSize);painter->SetMinStr(old.minStr);painter->SetMaxStr(old.maxStr);painter->SetLagRate(old.lag);
    }
    void begin(){
        requireAuthor();if(painting)return;if(active)throw std::runtime_error("Another Cyrus Brush session is active");prepare(target,true);
        auto* ref=static_cast<ReferenceTarget*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,PAINTERINTERFACE_CLASS_ID));
        painter=ref?static_cast<IPainterInterface_V14*>(ref->GetInterface(PAINTERINTERFACE_V14)):nullptr;
        if(!painter)throw std::runtime_error("Max Painter V14/V7 unavailable");
        if(painter->InPaintMode())throw std::runtime_error("Another Max paint tool owns the viewport");
        old={painter->GetEnablePointGather(),painter->GetBuildNormalData(),painter->GetMirrorEnable(),painter->GetUpdateOnMouseUp(),painter->GetPressureEnable(),painter->GetPredefinedSizeEnable(),painter->GetPredefinedStrEnable(),painter->GetDrawRing(),painter->GetDrawNormal(),painter->GetDrawTrace(),painter->GetUseSplineConstraint(),painter->GetMinSize(),painter->GetMaxSize(),painter->GetMinStr(),painter->GetMaxStr(),painter->GetLagRate()};
        active=this;painting=true;
        try{
            painter->SetEnablePointGather(FALSE);painter->SetBuildNormalData(FALSE);painter->SetMirrorEnable(FALSE);painter->SetUpdateOnMouseUp(FALSE);painter->SetPressureEnable(FALSE);painter->SetPredefinedSizeEnable(FALSE);painter->SetPredefinedStrEnable(FALSE);painter->SetDrawRing(TRUE);painter->SetDrawNormal(TRUE);painter->SetDrawTrace(FALSE);painter->SetUseSplineConstraint(FALSE);painter->SetLagRate(0);
            // Painter V14 size is a radius, matching the authored footprint.
            painter->SetMinSize(float(radius));painter->SetMaxSize(float(radius));painter->SetMinStr(1);painter->SetMaxStr(1);
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
    BOOL StartStroke()override{try{valid();if(gesture)return TRUE;
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
        strokePermit=cyrusBoundaryBegin(this);
        if(!strokePermit)throw std::runtime_error("Cyrus authoring license required; completed Brush work is preserved");
#endif
        pending=document;gestureChanged=false;gesture=true;pathConnected=false;return TRUE;}catch(const std::exception& e){error=e.what();return FALSE;}}
    void addPoint(b::Anchor anchor,bool connected){
        requireAuthor();valid();if(!gesture&&!StartStroke())throw std::runtime_error(error);
        const auto p=surface->position(anchor);b::Point center{p.x,p.y};
        auto next=b::constrain(b::paint(pending,center,radius,erase,metric,connected&&pathConnected?&lastPoint:nullptr),receiverDomain);
        pending=std::move(next);lastPoint=center;pathConnected=true;gestureChanged=true;++revision;
    }
    void add(IPoint2,b::Anchor anchor){addPoint(anchor,true);}
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
        try{valid();if(gestureChanged){
            auto restore=std::make_unique<PaintRestore>(this);
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
            if(!cyrusBoundaryCommit(strokePermit,this))throw std::runtime_error("Stroke authorization expired before commit; completed Brush work is preserved");
#endif
            theHold.Begin();holding=true;theHold.Put(restore.release());document=std::move(pending);gesture=false;changed();theHold.Accept(_T("Cyrus Brush stroke"));holding=false;
        }else gesture=false;return TRUE;
        }catch(const std::exception& e){if(holding)theHold.Cancel();CancelStroke();error=e.what();return FALSE;}
    }
    BOOL EndStroke(int n,BOOL* hit,IPoint2* mouse,Point3* world,Point3* normal,Point3* local,Point3* localNormal,Point3* bary,int* index,BOOL* shift,BOOL* ctrl,BOOL* alt,float* size,float* str,float* pressure,INode** nodes,BOOL mirror,Point3* mw,Point3* mn,Point3* ml,Point3* mln)override{
        for(int i=0;i<n;++i)if(!PaintStroke(hit[i],mouse[i],world[i],normal[i],local[i],localNormal[i],bary[i],index[i],shift[i],ctrl[i],alt[i],size[i],str[i],pressure[i],nodes[i],mirror,mw?mw[i]:Point3(0,0,0),mn?mn[i]:Point3(0,0,0),ml?ml[i]:Point3(0,0,0),mln?mln[i]:Point3(0,0,0)))return FALSE;return EndStroke();
    }
    BOOL CancelStroke()override{
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
        strokePermit={};
#endif
        if(gesture){gesture=false;pending={};++revision;}return TRUE;}
    BOOL SystemEndPaintSession()override{CancelStroke();if(!ending){restoreOptions();painting=false;if(active==this)active=nullptr;}return TRUE;}
    void PainterDisplay(TimeValue,ViewExp*,int)override{}
    void drawOverlay(ViewExp* view){
        // Display consumes completed numeric overlay only; no mesh evaluation,
        // field queries, scene creation, or buffer publication belongs here.
        if(invalid||!painting||!view||displayMode==0)return;++overlayDraws;auto* gw=view->getGW();if(!gw)return;const auto limits=gw->getRndLimits();gw->setTransform(Matrix3(1));gw->setRndLimits(limits|GW_Z_BUFFER);
        if(displayMode==1){
            gw->startMarkers();for(auto v:overlay){gw->setColor(LINE_COLOR,displayColor*(.3f+.7f*v.second));gw->marker(&v.first,HOLLOW_BOX_MRKR);}gw->endMarkers();
        }else{
            gw->setColor(LINE_COLOR,displayColor);
            for(auto& line:border){Point3 points[3]={line[0],line[1],line[1]};gw->polyline(2,points,nullptr,nullptr,FALSE,nullptr);}
        }
        gw->setRndLimits(limits);
    }
    IOResult Save(ISave* save)override{
        try{auto bytes=b::encode(document);save->BeginChunk(0x7301);ULONG done=0;auto result=save->Write(bytes.data(),static_cast<ULONG>(bytes.size()),&done);save->EndChunk();if(result!=IO_OK||done!=bytes.size())return IO_ERROR;
            save->BeginChunk(0x7302);double settings[]={radius,erase?1.:0.};result=save->Write(settings,sizeof(settings),&done);save->EndChunk();return result;
        }catch(...){return IO_ERROR;}
    }
    IOResult Load(ILoad* load)override{
        IOResult result;try{while((result=load->OpenChunk())==IO_OK){const auto id=load->CurChunkID();const auto length=load->CurChunkLength();storageTrace+="Chunk "+std::to_string(id)+" bytes "+std::to_string(length)+"\n";if(length>240000000)throw std::runtime_error("Brush chunk size limit");ULONG done=0;
            if(id==0x7301){std::vector<std::uint8_t> bytes(static_cast<std::size_t>(length));if(load->Read(bytes.data(),static_cast<ULONG>(length),&done)!=IO_OK||done!=length)throw std::runtime_error("Brush payload read failed");document=b::decode(bytes);}
            if(id==0x7302){double values[2];if(length!=sizeof(values)||load->Read(values,sizeof(values),&done)!=IO_OK||done!=sizeof(values))throw std::runtime_error("Brush settings read failed");for(double v:values)if(!std::isfinite(v))throw std::runtime_error("Non-finite Brush settings");
                if(values[0]<=0.0001||values[0]>1.e7||(values[1]!=0&&values[1]!=1))throw std::runtime_error("Invalid saved vector brush settings");
                radius=values[0];erase=values[1]!=0;}
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
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Scatter 0.78 vector Brush");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){static DocumentDesc desc;return i==0?&desc:nullptr;}
extern "C" __declspec(dllexport) ClassDesc* CyrusBrushDocumentDesc(){return LibClassDesc(0);}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE module,DWORD reason,LPVOID){if(reason==DLL_PROCESS_ATTACH)instance=module;return TRUE;}
static_assert(MAX_PRODUCT_YEAR_NUMBER==CYRUS_MAX_YEAR,"Brush SDK mismatch");

def_visible_primitive(cyrusBrushCreate,"cyrusBrushCreate");
Value* cyrusBrushCreate_cf(Value** a,int n){check_arg_count(cyrusBrushCreate,1,n);return api([&]()->Value*{std::unique_ptr<PaintDocument> p(static_cast<PaintDocument*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,documentID)));if(!p)throw std::runtime_error("Brush storage class unavailable. Load matching CyrusBrushStorage.dlh and CyrusBrush.dlx");p->requireAuthor();p->prepare(a[0]->to_node());return MAXRefTarg::intern(p.release());});}
def_visible_primitive(cyrusBrushBind,"cyrusBrushBind");
Value* cyrusBrushBind_cf(Value** a,int n){check_arg_count(cyrusBrushBind,1,n);return api([&]()->Value*{auto* p=doc(a[0]);p->prepare(p->target);return &ok;});}
def_visible_primitive(cyrusBrushBegin,"cyrusBrushBegin");
Value* cyrusBrushBegin_cf(Value** a,int n){check_arg_count(cyrusBrushBegin,1,n);return api([&]()->Value*{doc(a[0])->begin();return &ok;});}
def_visible_primitive(cyrusBrushStop,"cyrusBrushStop");
Value* cyrusBrushStop_cf(Value**,int n){check_arg_count(cyrusBrushStop,0,n);if(active)active->stop();return &ok;}
def_visible_primitive(cyrusBrushSettings,"cyrusBrushSettings");
Value* cyrusBrushSettings_cf(Value** a,int n){check_arg_count(cyrusBrushSettings,3,n);return api([&]()->Value*{
    auto* p=doc(a[0]);p->requireAuthor();if(p->gesture)throw std::runtime_error("Finish painting before changing radius/mode");
    double radius=a[1]->to_float();if(!std::isfinite(radius)||radius<=.0001||radius>1.e7)throw std::runtime_error("Invalid vector brush radius");
    p->radius=radius;p->erase=a[2]->to_bool()!=FALSE;
    if(p->painting){p->painter->SetMinSize(float(radius));p->painter->SetMaxSize(float(radius));}return &ok;});}
def_visible_primitive(cyrusBrushDisplay,"cyrusBrushDisplay");
Value* cyrusBrushDisplay_cf(Value** a,int n){check_arg_count(cyrusBrushDisplay,3,n);return api([&]()->Value*{
    auto* p=doc(a[0]);const int mode=a[1]->to_int();const auto color=a[2]->to_point3();
    if(mode<0||mode>2)throw std::runtime_error("Invalid Brush display mode");
    if(!std::isfinite(color.x)||!std::isfinite(color.y)||!std::isfinite(color.z))throw std::runtime_error("Invalid Brush display color");
    if(p->displayMode!=mode){p->displayMode=mode;p->fieldRevision=0;}
    p->displayColor=color/255.f;
    if(p->painting)p->evaluate();return &ok;
});}
def_visible_primitive(cyrusBrushStats,"cyrusBrushStats");
Value* cyrusBrushStats_cf(Value** a,int n){check_arg_count(cyrusBrushStats,1,n);auto* p=doc(a[0]);p->pollTarget();if(p->painting&&(p->invalid||!p->target||p->target->IsHidden()||p->target->IsFrozen()))p->stop();one_typed_value_local(Array* result);vl.result=new Array(20);const auto& current=p->gesture?p->pending:p->document;std::size_t samples=b::vertexCount(current);for(auto v:{p->revision,std::uint64_t(current.contours.size()),std::uint64_t(samples),std::uint64_t(!p->invalid),std::uint64_t(p->painting),std::uint64_t(p->gesture),p->picks,p->baseBuilds,p->fieldBuilds,p->queries})vl.result->append(Integer64::intern(v));vl.result->append(new String(std::wstring(p->error.begin(),p->error.end()).c_str()));vl.result->append(Float::intern(float(p->maxHitError)));vl.result->append(Float::intern(float(p->lastEvaluationMs)));vl.result->append(Integer64::intern(p->repairedHits));vl.result->append(Integer64::intern(p->maskApplications));vl.result->append(Integer::intern(int(p->overlay.size())));vl.result->append(Float::intern(0.f));vl.result->append(Integer::intern(p->tintLimited?1:0));vl.result->append(Integer::intern(int(p->tintFaces)));vl.result->append(Integer64::intern(p->overlayDraws));return_value(vl.result);}
def_visible_primitive(cyrusBrushRefreshMask,"cyrusBrushRefreshMask");
Value* cyrusBrushRefreshMask_cf(Value** a,int n){check_arg_count(cyrusBrushRefreshMask,1,n);return api([&]()->Value*{doc(a[0])->evaluate();return &ok;});}
def_visible_primitive(cyrusBrushDab,"cyrusBrushDab");
Value* cyrusBrushDab_cf(Value** a,int n){check_arg_count(cyrusBrushDab,4,n);return api([&]()->Value*{auto* p=doc(a[0]);
    try {p->requireAuthor();p->valid();b::Hit hit;if(!p->surface->hit({vec(a[1]->to_point3()),vec(a[2]->to_point3())},hit))return &false_value;
        if(!p->gesture&&!p->StartStroke())throw std::runtime_error(p->error);
        p->addPoint(hit.anchor,true);
        if(a[3]->to_bool()&&!p->EndStroke())throw std::runtime_error(p->error);
        return &true_value;
    }catch(...){p->CancelStroke();throw;}});}
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
def_visible_primitive(cyrusBrushOptions,"cyrusBrushOptions");
Value* cyrusBrushOptions_cf(Value** a,int n){check_arg_count(cyrusBrushOptions,1,n);auto* p=doc(a[0]);one_typed_value_local(Array* result);vl.result=new Array(2);vl.result->append(Float::intern(float(p->radius)));vl.result->append(p->erase?&true_value:&false_value);return_value(vl.result);}
def_visible_primitive(cyrusBrushFalloff,"cyrusBrushFalloff");
Value* cyrusBrushFalloff_cf(Value** a,int n){check_arg_count(cyrusBrushFalloff,1,n);return api([&]()->Value*{
    const auto& f=doc(a[0])->document.falloff;two_typed_value_locals(Array* result,Array* curve);vl.result=new Array(8);
    for(double v:{f.inside,f.outside})vl.result->append(Float::intern(float(v)));
    vl.result->append(f.density?&true_value:&false_value);vl.result->append(f.scale?&true_value:&false_value);
    for(double v:{f.scaleMin,f.scaleMax})vl.result->append(Float::intern(float(v)));
    for(const auto* values:{&f.densityCurve,&f.scaleCurve}){vl.curve=new Array(int(values->size()));vl.result->append(vl.curve);for(double v:*values)vl.curve->append(Float::intern(float(v)));}
    return_value(vl.result);});}
def_visible_primitive(cyrusBrushSetFalloff,"cyrusBrushSetFalloff");
Value* cyrusBrushSetFalloff_cf(Value** a,int n){check_arg_count(cyrusBrushSetFalloff,2,n);return api([&]()->Value*{
    auto* p=doc(a[0]);p->requireAuthor();if(p->gesture)throw std::runtime_error("Finish painting before editing feathering");
    type_check(a[1],Array,_T("vector feather settings"));auto* cfg=static_cast<Array*>(a[1]);if(cfg->size!=8)throw std::runtime_error("Expected eight vector feather settings");
    b::Falloff f;f.inside=cfg->data[0]->to_float();f.outside=cfg->data[1]->to_float();f.density=cfg->data[2]->to_bool()!=FALSE;f.scale=cfg->data[3]->to_bool()!=FALSE;f.scaleMin=cfg->data[4]->to_float();f.scaleMax=cfg->data[5]->to_float();
    int k=6;for(auto* curve:{&f.densityCurve,&f.scaleCurve}){type_check(cfg->data[k],Array,_T("curve samples"));auto* array=static_cast<Array*>(cfg->data[k++]);if(array->size<2||array->size>257)throw std::runtime_error("Curve needs 2..257 samples");curve->clear();for(int i=0;i<array->size;++i)curve->push_back(array->data[i]->to_float());}
    b::validate(f);const auto& old=p->document.falloff;
    if(f.inside==old.inside&&f.outside==old.outside&&f.density==old.density&&f.scale==old.scale&&f.scaleMin==old.scaleMin&&f.scaleMax==old.scaleMax&&f.densityCurve==old.densityCurve&&f.scaleCurve==old.scaleCurve)return &ok;
    const bool ownHold=!theHold.Holding();if(ownHold)theHold.Begin();theHold.Put(new PaintRestore(p));p->document.falloff=std::move(f);p->changed();if(ownHold)theHold.Accept(_T("Vector feather"));return &ok;});}
def_visible_primitive(cyrusBrushStorageLog,"cyrusBrushStorageLog");
Value* cyrusBrushStorageLog_cf(Value**,int n){check_arg_count(cyrusBrushStorageLog,0,n);return new String(std::wstring(storageTrace.begin(),storageTrace.end()).c_str());}

def_visible_primitive(cyrusBrushTarget,"cyrusBrushTarget");
Value* cyrusBrushTarget_cf(Value** a,int n){check_arg_count(cyrusBrushTarget,1,n);auto* p=doc(a[0]);return p->target?MAXNode::intern(p->target):&undefined;}

def_visible_primitive(cyrusBrushFill,"cyrusBrushFill");
Value* cyrusBrushFill_cf(Value** a,int n){check_arg_count(cyrusBrushFill,2,n);return api([&]()->Value*{
    auto* p=doc(a[0]);p->requireAuthor();if(p->gesture)throw std::runtime_error("Finish the stroke before resetting the field");
    const auto value=a[1]->to_float();if(value!=0&&value!=1)throw std::runtime_error("Vector Fill requires 0 (clear) or 1 (fill)");
    p->ensureSurface();auto next=p->document;next.contours=value==1?p->receiverDomain:b::Contours{};
    theHold.Begin();theHold.Put(new PaintRestore(p));p->document=std::move(next);p->changed();theHold.Accept(_T("Cyrus Brush fill"));return &ok;
});}

def_visible_primitive(cyrusClonePlacementRows,"cyrusClonePlacementRows");
def_visible_primitive(cyrusBrushRegionFilter,"cyrusBrushRegionFilter");
Value* cyrusBrushRegionFilter_cf(Value** a,int n){check_arg_count(cyrusBrushRegionFilter,6,n);return api([&]()->Value*{
    for(int i=0;i<5;++i)type_check(a[i],Array,_T("region coverage array"));
    auto* rows=static_cast<Array*>(a[0]);auto* documents=static_cast<Array*>(a[1]);auto* densities=static_cast<Array*>(a[2]);
    auto* receivers=static_cast<Array*>(a[3]);auto* counts=static_cast<Array*>(a[4]);
    if(documents->size>128||documents->size!=densities->size||receivers->size!=counts->size||receivers->size>128)throw std::runtime_error("Invalid bounded region coverage inputs");
    std::vector<INode*> nodes;std::vector<std::uint64_t> ends;std::uint64_t total=0;
    for(int i=0;i<receivers->size;++i){
        auto* node=receivers->data[i]->to_node();const int faces=counts->data[i]->to_int();
        if(!node||faces<0||std::find(nodes.begin(),nodes.end(),node)!=nodes.end())throw std::runtime_error("Invalid coverage receiver");
        nodes.push_back(node);total+=std::uint64_t(faces);ends.push_back(total);
    }
    struct Region{PaintDocument* doc;const b::Field* field;std::size_t receiver;double density;b::QueryStats stats;};
    std::vector<Region> regions;
    for(int i=0;i<documents->size;++i){
        auto* p=doc(documents->data[i]);const double density=densities->data[i]->to_float();
        if(!std::isfinite(density)||density<0||density>1)throw std::runtime_error("Invalid region density");
        auto found=std::find(nodes.begin(),nodes.end(),p->target);
        if(found==nodes.end())continue; // Removed targets retain their authored documents.
        if(p->gesture)throw std::runtime_error("Finish painting before evaluating");
        p->ensureSurface();const auto receiver=std::size_t(found-nodes.begin());
        if(p->surface->mesh().faces.size()!=std::size_t(counts->data[receiver]->to_int()))throw std::runtime_error("Region receiver topology differs from candidate anchors");
        regions.push_back({p,&p->fieldForRevision(),receiver,density,{}});
    }
    std::uint64_t population=1469598103934665603ULL;const std::wstring identity=a[5]->to_string();
    for(auto c:identity){population^=static_cast<std::uint16_t>(c);population*=1099511628211ULL;}
    two_typed_value_locals(Array* result,Array* copy);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i){
        type_check(rows->data[i],Array,_T("keyed placement"));auto* row=static_cast<Array*>(rows->data[i]);
        if(row->size!=5)throw std::runtime_error("Region coverage requires surface anchors");
        const int face=row->data[3]->to_int()-1;const auto bary=vec(row->data[4]->to_point3());
        if(face<0||std::uint64_t(face)>=total||!std::isfinite(bary.x)||!std::isfinite(bary.y)||!std::isfinite(bary.z)||std::abs(bary.x+bary.y+bary.z-1)>1e-3||std::min({bary.x,bary.y,bary.z})<-1e-4||std::max({bary.x,bary.y,bary.z})>1.0001)throw std::runtime_error("Region anchor requires projected movement");
        const auto receiver=std::size_t(std::upper_bound(ends.begin(),ends.end(),std::uint64_t(face))-ends.begin());
        const auto localFace=unsigned(std::uint64_t(face)-(receiver?ends[receiver-1]:0));double weight=0,scale=1;
        const double u=b::threshold(population,std::uint64_t(row->data[2]->to_int64()));
        // Union once; strongest effective density controls scale. Equal weights
        // use saved area order, preserving deterministic overlap behavior.
        for(auto& region:regions)if(region.receiver==receiver){
            const auto value=region.field->query({localFace,bary},&region.stats);const double w=std::clamp(value.density*region.density,0.,1.);
            if(w>weight){weight=w;scale=value.scale;}
        }
        if(u<weight){
            vl.copy=new Array(row->size);vl.result->append(vl.copy);Matrix3 tm=row->data[0]->to_matrix3();for(int k=0;k<3;++k)tm.SetRow(k,tm.GetRow(k)*float(scale));vl.copy->append(new Matrix3Value(tm));
            for(int k=1;k<row->size;++k)vl.copy->append(row->data[k]);
        }
    }
    for(auto& region:regions){region.doc->queries+=region.stats.fieldQueries;++region.doc->maskApplications;}
    return_value(vl.result);
});}

Value* cyrusClonePlacementRows_cf(Value** a,int n){check_arg_count(cyrusClonePlacementRows,1,n);type_check(a[0],Array,_T("placement rows"));auto* rows=static_cast<Array*>(a[0]);
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("placement row"));auto* input=static_cast<Array*>(rows->data[i]);if(input->size<2)throw RuntimeError(_T("Invalid placement row"));vl.row=new Array(input->size);vl.result->append(vl.row);vl.row->append(new Matrix3Value(input->data[0]->to_matrix3()));for(int k=1;k<input->size;++k)vl.row->append(input->data[k]);}
    return_value(vl.result);
}

// Nitrous overlay submission uses the normal redraw callback. Painter owns
// picking/strokes, but its legacy display callback is not invoked consistently.
def_visible_primitive(cyrusBrushDrawCurrent,"cyrusBrushDrawCurrent");
Value* cyrusBrushDrawCurrent_cf(Value**,int n){check_arg_count(cyrusBrushDrawCurrent,0,n);if(active){auto& view=GetCOREInterface()->GetActiveViewExp();if(view.IsAlive())active->drawOverlay(&view);}return &ok;}

#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
// Exercise the actual Painter callback at expiry, independently of script
// admission. This diagnostic is absent from ordinary builds.
def_visible_primitive(cyrusOwnedLabBrushEnd,"cyrusOwnedLabBrushEnd");
Value* cyrusOwnedLabBrushEnd_cf(Value** a,int n){check_arg_count(cyrusOwnedLabBrushEnd,1,n);return doc(a[0])->EndStroke()?&true_value:&false_value;}
#endif

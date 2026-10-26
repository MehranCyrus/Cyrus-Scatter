#include "lab_core.hpp" // Before MAXScript macros.
#include <algorithm>
#include <cmath>
#include <limits>
#include <max.h>
#include <iparamb2.h>
#include <triobj.h>
#include <units.h>
#include <istdplug.h>
#include <MeshNormalSpec.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>

static_assert(MAX_PRODUCT_YEAR_NUMBER==2027);
namespace {
const Class_ID documentId(0x6c58a113,0x2c4e7b89);
HINSTANCE moduleInstance=nullptr;
std::wstring wide(const std::string& s) {
    int n=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s.data(),int(s.size()),nullptr,0);
    if(n<=0&&!s.empty())throw std::runtime_error("Invalid UTF-8.");
    std::wstring out(n,L'\0');MultiByteToWideChar(CP_UTF8,0,s.data(),int(s.size()),out.data(),n);return out;
}
std::string narrow(const wchar_t* s) {
    int n=WideCharToMultiByte(CP_UTF8,0,s,-1,nullptr,0,nullptr,nullptr);std::string out(n,'\0');
    WideCharToMultiByte(CP_UTF8,0,s,-1,out.data(),n,nullptr,nullptr);if(n)out.pop_back();return out;
}
Value* text(const std::string& s){return new String(wide(s).c_str());}
template<class F> Value* api(F f){try{return f();}catch(const std::exception& e){throw RuntimeError(wide(e.what()).c_str());}}
double sceneUnit(){return GetSystemUnitScale(UNITS_METERS);}
bool sameUnit(double a,double b){return std::abs(a-b)<=1e-9*std::max(std::abs(a),std::abs(b));}
cvl::v::Vec3 vec(Point3 p){return {p.x,p.y,p.z};}
Point3 point(cvl::v::Vec3 p){return {float(p.x),float(p.y),float(p.z)};}
bool finite(Point3 p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
class Document;
class ResultRestore final:public RestoreObj {
    SingleRefMaker lifetime;Document* document;
    std::shared_ptr<const cvl::State> before,after;
public:
    ResultRestore(Document*,std::shared_ptr<const cvl::State>,std::shared_ptr<const cvl::State>);
    void Restore(int)override;void Redo()override;int Size()override;
    MSTR Description()override{return _T("Vegetation Lab result");}
};
class Document final:public ReferenceTarget {
public:
    std::shared_ptr<const cvl::State> state;
    std::uint64_t meshReads=0,fitAttempts=0,successfulFits=0;
    double lastFitMs=0;std::string error;
    void DeleteThis()override{delete this;}
    Class_ID ClassID()override{return documentId;}
    SClass_ID SuperClassID()override{return REF_TARGET_CLASS_ID;}
    void GetClassName(MSTR& name,bool)const override{name=_T("Vegetation Lab Document");}
    int NumRefs()override{return 0;}
    RefTargetHandle GetReference(int)override{return nullptr;}
    void SetReference(int,RefTargetHandle)override{}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
    RefTargetHandle Clone(RemapDir& remap)override{auto* copy=new Document;copy->state=state;BaseClone(this,copy,remap);return copy;}
    void changed(){NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE);}
    void install(std::shared_ptr<const cvl::State> next,const MCHAR* label) {
        auto restore=std::make_unique<ResultRestore>(this,state,next);
        const bool own=!theHold.Holding();if(own)theHold.Begin();
        theHold.Put(restore.release());state=std::move(next);error.clear();changed();
        if(own)theHold.Accept(label);
    }
    IOResult Save(ISave* save)override {
        try{if(!state)return IO_ERROR;auto bytes=cvl::encode(*state);save->BeginChunk(0x7310);ULONG done=0;
            const auto result=save->Write(bytes.data(),ULONG(bytes.size()),&done);save->EndChunk();return result==IO_OK&&done==bytes.size()?IO_OK:IO_ERROR;
        }catch(...){return IO_ERROR;}
    }
    IOResult Load(ILoad* load)override {
        try{IOResult result;bool found=false;while((result=load->OpenChunk())==IO_OK){
            if(load->CurChunkID()==0x7310){const auto count=load->CurChunkLength();if(found||count>cvl::maxSerializedBytes){load->CloseChunk();return IO_ERROR;}
                std::string bytes(count,'\0');ULONG done=0;if(load->Read(bytes.data(),ULONG(count),&done)!=IO_OK||done!=count){load->CloseChunk();return IO_ERROR;}
                state=cvl::decode(bytes);found=true;
            }load->CloseChunk();}return result==IO_END&&found?IO_OK:IO_ERROR;
        }catch(...){return IO_ERROR;}
    }
};
ResultRestore::ResultRestore(Document* d,std::shared_ptr<const cvl::State> a,std::shared_ptr<const cvl::State> b):document(d),before(std::move(a)),after(std::move(b)){lifetime.SetRef(d);}
void ResultRestore::Restore(int){document->state=before;document->error.clear();document->changed();}
void ResultRestore::Redo(){document->state=after;document->error.clear();document->changed();}
int ResultRestore::Size(){return int(std::min<std::size_t>(INT_MAX,sizeof(*this)+(before?cvl::estimatedBytes(*before):0)+(after?cvl::estimatedBytes(*after):0)));}
Document* doc(Value* value){auto* ref=value->to_reftarg();if(!ref||ref->ClassID()!=documentId)throw std::runtime_error("Missing Vegetation Lab document.");auto* d=static_cast<Document*>(ref);if(!d->state)throw std::runtime_error("Empty Vegetation Lab document.");return d;}
class Descriptor final:public ClassDesc2 {
public:
    int IsPublic()override{return FALSE;}void* Create(BOOL)override{return new Document;}
    const MCHAR* ClassName()override{return _T("CyrusVegetationDocument");}
    const MCHAR* NonLocalizedClassName()override{return _T("CyrusVegetationDocument");}
    SClass_ID SuperClassID()override{return REF_TARGET_CLASS_ID;}Class_ID ClassID()override{return documentId;}
    const MCHAR* Category()override{return _T("Cyrus Labs");}const MCHAR* InternalName()override{return _T("CyrusVegetationDocument");}
    HINSTANCE HInstance()override{return moduleInstance;}
};
// Host state is captured only for an explicit Fit. The solver retains copied numbers.
struct Capture {cvl::Sphere sphere;cvl::Json identity;};
double uniformScale(const Matrix3& tm,bool owner) {
    double lengths[3]{};for(int i=0;i<4;++i)if(!finite(tm.GetRow(i)))throw std::runtime_error("Nonfinite object transform.");
    for(int i=0;i<3;++i){lengths[i]=Length(tm.GetRow(i));if(!(lengths[i]>1e-8))throw std::runtime_error("Zero object scale.");}
    for(int i=0;i<3;++i)for(int j=i+1;j<3;++j)if(std::abs(DotProd(tm.GetRow(i),tm.GetRow(j)))>1e-5*lengths[i]*lengths[j])throw std::runtime_error("Sheared transforms are unsupported in this test.");
    if(tm.Parity()||std::abs(lengths[0]-lengths[1])>1e-5*lengths[0]||std::abs(lengths[0]-lengths[2])>1e-5*lengths[0])throw std::runtime_error("Use a positive, uniform object scale.");
    if(owner&&std::abs(lengths[0]-1)>1e-5)throw std::runtime_error("Keep the grass scale at 100%; move or rotate it instead.");return lengths[0];
}
cvl::Json matrix(const Matrix3& tm){cvl::Json rows=cvl::Json::array();for(int i=0;i<4;++i){auto p=tm.GetRow(i);rows.push_back({p.x,p.y,p.z});}return rows;}
Capture capture(INode* owner,INode* stone,double unit) {
    if(!owner||!stone||owner==stone)throw std::runtime_error("Pick a complete standard Sphere as the stone.");
    const auto time=GetCOREInterface()->GetTime();const auto ownerTM=owner->GetObjectTM(time),stoneTM=stone->GetObjectTM(time);
    uniformScale(ownerTM,true);const auto scale=uniformScale(stoneTM,false);
    if(Length(ownerTM.GetTrans())*unit>100)throw std::runtime_error("Keep the test patch within 100 m of the world origin.");
    auto* object=stone->EvalWorldState(time).obj;
    if(!object||object->ClassID()!=Class_ID(SPHERE_CLASS_ID,0))throw std::runtime_error("Use an unmodified standard Sphere. Arbitrary rocks are a later step.");
    auto* pb=object->GetParamBlock(0);if(!pb)throw std::runtime_error("Sphere parameters are unavailable.");
    Interval valid=FOREVER;float radius=0,hemi=0;int recenter=0,slice=0;
    pb->GetValue(SPHERE_RADIUS,time,radius,valid);pb->GetValue(SPHERE_HEMI,time,hemi,valid);
    pb->GetValue(SPHERE_RECENTER,time,recenter,valid);pb->GetValue(SPHERE_SLICEON,time,slice,valid);
    if(hemi!=0||recenter||slice)throw std::runtime_error("Use a complete Sphere with Hemisphere, Base to Pivot and Slice disabled.");
    auto local=stoneTM.GetTrans()*Inverse(ownerTM);Capture out;
    out.sphere={cvl::hostToCore(vec(local),unit),double(radius)*scale*unit};
    out.identity={{"time",time},{"unit",sceneUnit()},{"owner",matrix(ownerTM)},{"stone",matrix(stoneTM)},
        {"radius",radius},{"hemisphere",hemi},{"recenter",recenter},{"slice",slice}};return out;
}
std::unique_ptr<::Mesh> mesh(const cvl::State& s) {
    auto out=std::make_unique<::Mesh>();const int nv=int(s.meshes.size()*18),nf=int(s.meshes.size()*16);
    out->setNumVerts(nv);out->setNumFaces(nf);out->setMapSupport(1,TRUE);out->setNumMapVerts(1,nv);out->setNumMapFaces(1,nf);
    out->SpecifyNormals();auto* normals=out->GetSpecifiedNormals();if(!normals||!normals->SetNumNormals(nv)||!normals->SetNumFaces(nf))throw std::runtime_error("Cannot allocate explicit grass normals.");
    int vi=0,fi=0;
    for(const auto& m:s.meshes){for(std::size_t i=0;i<m.positions.size();++i){out->verts[vi+int(i)]=point(cvl::coreToHost(m.positions[i],s.metersPerUnit));out->mapVerts(1)[vi+int(i)]=UVVert(float(m.uvs[i].u),float(m.uvs[i].v),0.f);normals->Normal(vi+int(i))=Normalize(point(cvl::coreToHost(m.normals[i],1)));}
        for(auto t:m.triangles){const int a=vi+int(t[0]),b=vi+int(t[1]),c=vi+int(t[2]);auto& f=out->faces[fi];f.setVerts(a,b,c);f.setEdgeVisFlags(1,1,1);f.setMatID(0);f.setSmGroup(1);out->mapFaces(1)[fi].setTVerts(a,b,c);auto& n=normals->Face(fi);n.SetNormalID(0,a);n.SetNormalID(1,b);n.SetNormalID(2,c);n.SpecifyAll();++fi;}vi+=int(m.positions.size());}
    normals->SetAllExplicit();normals->SetParent(out.get());normals->SetFlag(MESH_NORMAL_NORMALS_BUILT);normals->SetFlag(MESH_NORMAL_NORMALS_COMPUTED);
    out->InvalidateGeomCache();out->buildBoundingBox();return out;
}
}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Vegetation Lab 0.1.0 - Max 2027");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) void LibInit(){}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){static Descriptor d;return i==0?&d:nullptr;}
extern "C" __declspec(dllexport) ClassDesc* CyrusVegetationDocumentDesc(){return LibClassDesc(0);}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID){if(reason==DLL_PROCESS_ATTACH)moduleInstance=instance;return TRUE;}
def_visible_primitive(cvlVersion,"cvlVersion");
Value* cvlVersion_cf(Value**,int n){check_arg_count(cvlVersion,0,n);return api([]()->Value*{wchar_t path[32768]{};GetModuleFileNameW(moduleInstance,path,32768);return text(cvl::Json({{"version","0.1.0"},{"host",2027},{"core",CVL_CORE_ID},{"module",narrow(path)}}).dump());});}
def_visible_primitive(cvlCreate,"cvlCreate");
Value* cvlCreate_cf(Value** a,int n){check_arg_count(cvlCreate,1,n);return api([&]()->Value*{auto prepared=cvl::makeRest(a[0]->to_int(),sceneUnit());auto* d=static_cast<Document*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,documentId));if(!d)throw std::runtime_error("Cannot create the lab document.");d->state=std::move(prepared);return MAXRefTarg::intern(d);});}
def_visible_primitive(cvlFit,"cvlFit");
Value* cvlFit_cf(Value** a,int n){check_arg_count(cvlFit,5,n);return api([&]()->Value*{auto* d=doc(a[0]);++d->fitAttempts;const auto old=d->state;const auto start=GetTickCount64();try{
    if(!sameUnit(sceneUnit(),old->metersPerUnit))throw std::runtime_error("System units changed. Restore them or create a new demo.");
    auto* owner=a[1]->to_node();auto* stone=a[2]->to_node();const auto before=capture(owner,stone,old->metersPerUnit);
    const double clearance=a[3]->to_float()*old->metersPerUnit;auto next=cvl::fit(*old,before.sphere,clearance,a[4]->to_bool()!=FALSE);
    if(d->state!=old||!sameUnit(sceneUnit(),old->metersPerUnit)||capture(owner,stone,old->metersPerUnit).identity!=before.identity)throw std::runtime_error("Inputs changed during Fit; previous result retained.");
    d->install(std::move(next),_T("Fit grass to stone"));++d->successfulFits;d->lastFitMs=double(GetTickCount64()-start);return &true_value;
    }catch(const std::exception& e){d->lastFitMs=double(GetTickCount64()-start);d->error=e.what();throw;}});}
def_visible_primitive(cvlReset,"cvlReset");
Value* cvlReset_cf(Value** a,int n){check_arg_count(cvlReset,1,n);return api([&]()->Value*{auto* d=doc(a[0]);auto old=d->state;if(!sameUnit(sceneUnit(),old->metersPerUnit))throw std::runtime_error("System units changed. Restore them or create a new demo.");if(old->revision==UINT64_MAX)throw std::runtime_error("Lab revision exhausted.");auto next=cvl::makeRest(int(old->poses.size()),old->metersPerUnit,old->revision+1,old->prepared);d->install(std::move(next),_T("Reset grass"));return &true_value;});}
def_visible_primitive(cvlMesh,"cvlMesh");
Value* cvlMesh_cf(Value** a,int n){check_arg_count(cvlMesh,1,n);return api([&]()->Value*{auto* d=doc(a[0]);++d->meshReads;auto result=mesh(*d->state);return new MeshValue(result.release(),TRUE);});}
def_visible_primitive(cvlStats,"cvlStats");
Value* cvlStats_cf(Value** a,int n){check_arg_count(cvlStats,1,n);return api([&]()->Value*{auto* d=doc(a[0]);auto j=cvl::summary(*d->state);j["mesh_reads"]=d->meshReads;j["fit_attempts"]=d->fitAttempts;j["successful_fits"]=d->successfulFits;j["last_fit_ms"]=d->lastFitMs;j["error"]=d->error;return text(j.dump());});}

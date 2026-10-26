#include "stem_core.hpp"
#include "analysis.hpp"
#include <future>
#include <fstream>
#include <filesystem>
#include <set>
#include <chrono>
#include <max.h>
#include <simpobj.h>
#include <triobj.h>
#include <iparamb2.h>
#include <units.h>
#include <istdplug.h>
#include <bcrypt.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER==2027);
namespace {
using Json=stem::Json;using Vec=stem::Vec;using Clock=std::chrono::steady_clock;
const Class_ID stemId(0x6c58a215,0x2c4e7c8b);HINSTANCE module=nullptr;
double ms(Clock::time_point start){return std::chrono::duration<double,std::milli>(Clock::now()-start).count();}
std::wstring wide(const std::string& s){int n=MultiByteToWideChar(CP_UTF8,0,s.data(),int(s.size()),nullptr,0);std::wstring out(n,L'\0');MultiByteToWideChar(CP_UTF8,0,s.data(),int(s.size()),out.data(),n);return out;}
Value* text(const Json& j){return new String(wide(j.dump()).c_str());}
Json parseBounded(const std::string& bytes){return Json::parse(bytes,[](int depth,Json::parse_event_t,Json&){if(depth>64)throw std::runtime_error("JSON nesting budget.");return true;});}
Vec core(Point3 p,double unit){return {double(p.x)*unit,double(p.z)*unit,-double(p.y)*unit};}
Point3 host(Vec p,double unit){return {float(p.x/unit),float(-p.z/unit),float(p.y/unit)};}
class Sha {
    BCRYPT_ALG_HANDLE algorithm=nullptr;BCRYPT_HASH_HANDLE hash=nullptr;std::vector<unsigned char> storage;
public:
    Sha(){if(BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)<0)throw std::runtime_error("SHA provider.");DWORD size=0,done=0;BCryptGetProperty(algorithm,BCRYPT_OBJECT_LENGTH,reinterpret_cast<PUCHAR>(&size),sizeof(size),&done,0);storage.resize(size);if(BCryptCreateHash(algorithm,&hash,storage.data(),size,nullptr,0,0)<0)throw std::runtime_error("SHA state.");}
    ~Sha(){if(hash)BCryptDestroyHash(hash);if(algorithm)BCryptCloseAlgorithmProvider(algorithm,0);}
    void add(const void* bytes,std::size_t n){if(n>UINT_MAX||BCryptHashData(hash,reinterpret_cast<PUCHAR>(const_cast<void*>(bytes)),ULONG(n),0)<0)throw std::runtime_error("SHA data.");}
    std::string finish(){unsigned char digest[32]{};if(BCryptFinishHash(hash,digest,32,0)<0)throw std::runtime_error("SHA finish.");std::string out;for(auto c:digest){out+="0123456789abcdef"[c>>4];out+="0123456789abcdef"[c&15];}return out;}
};
struct Sphere {Vec centre;double radius;Json key;};
struct Cache {
    std::shared_ptr<const stem::Prepared> prepared;
    std::unique_ptr<Mesh> fullBase,previewBase;
    stem::Pose pose;double unit=1,preparationMs=0;
    std::uint64_t meshGeneration=0,fullGeneration=0;
};
class StemObject final:public SimpleObjectBase {
public:
    INode* source=nullptr;INode* sphere=nullptr;
    std::string metadata;std::vector<unsigned> labels;std::unique_ptr<Cache> cache;
    Json savedPose,lastKey,savedKey,history=Json::array(),last;
    std::unique_ptr<Mesh> full;
    int mode=0;bool live=true,busy=false;double clearance=.001,stiffness=.5;
    std::uint64_t builds=0,solves=0,published=0,notifications=0,heldNotifications=0,preparations=0,renderRequests=0;
    std::string error;
    StemObject(){ivalid.SetEmpty();}
    ~StemObject()override{DeleteAllRefsFromMe();}
    void DeleteThis()override{delete this;}
    Class_ID ClassID()override{return stemId;}
    const MCHAR* GetObjectName(bool)const override{return _T("Cyrus Vegetation Stem Lab");}
    void GetClassName(MSTR& s,bool)const override{s=_T("Cyrus Vegetation Stem Lab");}
    int NumRefs()override{return 2;}
    RefTargetHandle GetReference(int i)override{return i==0?source:i==1?sphere:nullptr;}
    void SetReference(int i,RefTargetHandle ref)override{if(i==0)source=static_cast<INode*>(ref);else if(i==1)sphere=static_cast<INode*>(ref);}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle target,PartID& part,RefMessage message,BOOL)override{
        if(message==REFMSG_TARGET_DELETED){if(target==source)source=nullptr;if(target==sphere)sphere=nullptr;error="A required source or sphere was deleted; cached geometry retained.";ivalid.SetEmpty();}
        if(message==REFMSG_CHANGE){++notifications;if(GetAsyncKeyState(VK_LBUTTON)&0x8000)++heldNotifications;
            if(target==source&&(part&(PART_GEOM|PART_TOPO|PART_TM))){cache.reset();lastKey=nullptr;}
            ivalid.SetEmpty();part|=PART_GEOM;
        }return REF_SUCCEED;
    }
    RefTargetHandle Clone(RemapDir& remap)override{auto* copy=new StemObject;copy->metadata=metadata;copy->labels=labels;copy->mode=mode;copy->live=live;copy->clearance=clearance;copy->stiffness=stiffness;copy->error=error;if(cache)copy->savedPose=stem::savePose(cache->pose);else copy->savedPose=savedPose;copy->savedKey=lastKey;copy->ReplaceReference(0,remap.CloneRef(source));copy->ReplaceReference(1,remap.CloneRef(sphere));BaseClone(this,copy,remap);return copy;}
    CreateMouseCallBack* GetCreateMouseCallBack()override{return nullptr;}
    void InvalidateUI()override{}
    BOOL OKtoDisplay(TimeValue)override{return TRUE;}
    void ensure(TimeValue t){
        if(cache)return;if(!source||metadata.empty())throw std::runtime_error("Missing embedded stem preparation/source.");auto started=Clock::now();auto next=std::make_unique<Cache>();next->unit=GetSystemUnitScale(UNITS_METERS);if(!std::isfinite(next->unit)||next->unit<1e-9||next->unit>1000)throw std::runtime_error("Unsupported system units.");
        auto* object=source->EvalWorldState(t).obj;if(!object||!object->CanConvertToType(triObjectClassID))throw std::runtime_error("Source mesh unavailable.");auto* tri=static_cast<TriObject*>(object->ConvertToType(t,triObjectClassID));
        try{auto& input=tri->GetMesh();if(input.numVerts<3||input.numVerts>2000000||input.numFaces<1||input.numFaces>4000000||labels.size()!=std::size_t(input.numVerts))throw std::runtime_error("Source/label admission mismatch.");
            Json j=parseBounded(metadata);if(j.at("parts").size()>40000)throw std::runtime_error("Part budget.");std::vector<Point3> sourceXYZ;std::vector<Vec> points;sourceXYZ.reserve(input.numVerts);points.reserve(input.numVerts);auto tm=source->GetObjectTM(t);
            for(int i=0;i<input.numVerts;++i){Point3 p=(input.verts[i]*tm)*float(next->unit);sourceXYZ.push_back(p);points.push_back({p.x,p.z,-p.y});}
            std::vector<std::array<unsigned,3>> faces;std::vector<unsigned> materials;faces.reserve(input.numFaces);materials.reserve(input.numFaces);
            for(int i=0;i<input.numFaces;++i){auto f=input.faces[i];faces.push_back({f.v[0],f.v[1],f.v[2]});materials.push_back(f.getMatID());}
            Sha digest;unsigned header[]{0x53544c32u,unsigned(input.numVerts),unsigned(input.numFaces),unsigned(j.at("parts").size())};digest.add(header,sizeof(header));digest.add(sourceXYZ.data(),sourceXYZ.size()*sizeof(Point3));digest.add(faces.data(),faces.size()*sizeof(faces[0]));digest.add(materials.data(),materials.size()*4);digest.add(labels.data(),labels.size()*4);
            if(digest.finish()!=j.at("source_geometry_sha256").get<std::string>())throw std::runtime_error("Source geometry/units changed. Restore the prepared source; bindings were retained.");
            next->prepared=stem::prepare(j,points,faces,labels);next->pose=savedPose.is_null()?stem::restPose(*next->prepared):stem::loadPose(*next->prepared,savedPose);
            next->fullBase=std::make_unique<Mesh>(input);next->fullBase->ClearSpecifiedNormals();for(int i=0;i<input.numVerts;++i)next->fullBase->verts[i]=host(points[i],next->unit);
            next->previewBase=std::make_unique<Mesh>();auto& preview=*next->previewBase;const auto& p=*next->prepared;preview.setNumVerts(int(p.previewVertices.size()));preview.setNumFaces(int(p.previewTriangles.size()));
            for(unsigned i=0;i<p.previewVertices.size();++i)preview.verts[i]=host(points[p.previewVertices[i]],next->unit);
            for(unsigned i=0;i<p.previewTriangles.size();++i){auto f=p.previewTriangles[i];preview.faces[i].setVerts(p.previewRemap[f[0]],p.previewRemap[f[1]],p.previewRemap[f[2]]);preview.faces[i].setMatID(MtlID(p.previewMaterials[i]));preview.faces[i].setSmGroup(1);preview.faces[i].setEdgeVisFlags(1,1,1);}
            preview.InvalidateGeomCache();preview.buildBoundingBox();next->preparationMs=ms(started);cache=std::move(next);++preparations;if(!savedKey.is_null())lastKey=savedKey;
        }catch(...){if(tri!=object)tri->DeleteThis();throw;}if(tri!=object)tri->DeleteThis();
    }
    Sphere capture(TimeValue t){if(!sphere)throw std::runtime_error("Pick the sphere collider.");if(std::abs(GetSystemUnitScale(UNITS_METERS)-cache->unit)>1e-9*cache->unit)throw std::runtime_error("System units changed. Restore the scene's saved units.");auto* object=sphere->EvalWorldState(t).obj;if(!object||object->ClassID()!=Class_ID(SPHERE_CLASS_ID,0))throw std::runtime_error("Use a complete, unmodified standard Sphere.");auto* pb=object->GetParamBlock(0);if(!pb)throw std::runtime_error("Sphere parameters.");Interval valid=FOREVER;float r=0,h=0;int slice=0,recenter=0;pb->GetValue(SPHERE_RADIUS,t,r,valid);pb->GetValue(SPHERE_HEMI,t,h,valid);pb->GetValue(SPHERE_SLICEON,t,slice,valid);pb->GetValue(SPHERE_RECENTER,t,recenter,valid);if(h!=0||slice||recenter)throw std::runtime_error("Use a complete sphere.");auto tm=sphere->GetObjectTM(t);double scale=Length(tm.GetRow(0));if(!std::isfinite(scale)||scale<1e-8||tm.Parity())throw std::runtime_error("Unsupported sphere transform.");for(int i=0;i<3;++i){if(std::abs(Length(tm.GetRow(i))-scale)>1e-5*scale)throw std::runtime_error("Use uniform sphere scale.");for(int j=i+1;j<3;++j)if(std::abs(DotProd(tm.GetRow(i),tm.GetRow(j)))>1e-5*scale*scale)throw std::runtime_error("Sheared sphere.");}Vec centre=core(tm.GetTrans(),cache->unit);double radius=r*scale*cache->unit;return {centre,radius,Json::array({centre.x,centre.y,centre.z,radius,clearance,stiffness})};}
    bool evaluate(TimeValue t){ensure(t);if(!live)return false;auto s=capture(t);if(s.key==lastKey)return false;auto started=Clock::now();bool held=(GetAsyncKeyState(VK_LBUTTON)&0x8000)!=0;++solves;lastKey=s.key;auto solved=stem::solve(*cache->prepared,s.centre,s.radius,clearance,stiffness,cache->pose.generation+1);Json row=solved.metrics;row["mouse_down_at_capture"]=held;row["sphere"]={s.centre.x,s.centre.y,s.centre.z,s.radius};row["ok"]=solved.ok;
        if(solved.ok){cache->pose=std::move(solved.pose);savedPose=nullptr;error.clear();++published;}else error=solved.error;
        row["error"]=error;row["generation"]=cache->pose.generation;row["evaluation_ms"]=ms(started);last=row;if(history.size()>=128)history.erase(history.begin());history.push_back(row);return solved.ok;
    }
    std::unique_ptr<Mesh> realize(bool high){auto started=Clock::now();const auto& p=*cache->prepared;auto output=std::make_unique<Mesh>(high?*cache->fullBase:*cache->previewBase);for(int i=0;i<output->numVerts;++i){unsigned sourceIndex=high?unsigned(i):p.previewVertices[i];auto position=stem::point(p,cache->pose,sourceIndex);if(!std::isfinite(position.x)||!std::isfinite(position.y)||!std::isfinite(position.z))throw std::runtime_error("Nonfinite delivered position.");output->verts[i]=host(position,cache->unit);}output->InvalidateGeomCache();output->buildBoundingBox();last[high?"full_mesh_ms":"preview_mesh_ms"]=ms(started);last["mouse_down_at_publish"]=(GetAsyncKeyState(VK_LBUTTON)&0x8000)!=0;if(!history.empty()){history.back()=last;}return output;}
    void BuildMesh(TimeValue t)override{if(busy)return;busy=true;struct Guard{bool& b;~Guard(){b=false;}}guard{busy};auto started=Clock::now();try{evaluate(t);}catch(const std::exception& e){error=e.what();}try{if(cache&&(cache->meshGeneration!=cache->pose.generation||mesh.numFaces==0)){auto next=realize(mode==1);mesh=*next;cache->meshGeneration=cache->pose.generation;++builds;last["build_ms"]=ms(started);if(!history.empty())history.back()=last;}}catch(const std::exception& e){error=e.what();}ivalid=FOREVER;}
    Interval ObjectValidity(TimeValue t)override{try{if(cache&&live&&capture(t).key!=lastKey)ivalid.SetEmpty();}catch(...){ivalid.SetEmpty();}return SimpleObjectBase::ObjectValidity(t);}
    Mesh* GetRenderMesh(TimeValue t,INode*,View&,BOOL& needDelete)override{++renderRequests;needDelete=FALSE;try{evaluate(t);if(!full||cache->fullGeneration!=cache->pose.generation){auto candidate=realize(true);full=std::move(candidate);cache->fullGeneration=cache->pose.generation;}}catch(const std::exception& e){error=e.what();}return full?full.get():&mesh;}
    void changed(){ivalid.SetEmpty();if(cache)cache->meshGeneration=0;NotifyDependents(FOREVER,PART_GEOM|PART_TOPO,REFMSG_CHANGE);}
    IOResult Save(ISave* save)override{try{auto write=[&](USHORT id,const std::string& bytes){if(bytes.size()>16*1024*1024)throw std::runtime_error("Save chunk bound.");save->BeginChunk(id);ULONG done=0;auto result=save->Write(bytes.data(),ULONG(bytes.size()),&done);save->EndChunk();if(result!=IO_OK||done!=bytes.size())throw std::runtime_error("Save failed.");};write(0x7901,metadata);write(0x7902,std::string(reinterpret_cast<char*>(labels.data()),labels.size()*4));Json settings={{"schema",2},{"version","0.3.1"},{"mode",mode},{"live",live},{"clearance",clearance},{"stiffness",stiffness},{"key",lastKey},{"error",error},{"pose",cache?stem::savePose(cache->pose):savedPose}};write(0x7903,settings.dump());return IO_OK;}catch(...){return IO_ERROR;}}
    IOResult Load(ILoad* load)override{try{IOResult result;while((result=load->OpenChunk())==IO_OK){const auto chunkSize=load->CurChunkLength();if(chunkSize>16*1024*1024){load->CloseChunk();return IO_ERROR;}unsigned size=unsigned(chunkSize);std::string bytes(size,'\0');ULONG done=0;if(load->Read(bytes.data(),size,&done)!=IO_OK||done!=size){load->CloseChunk();return IO_ERROR;}switch(load->CurChunkID()){case 0x7901:metadata=std::move(bytes);break;case 0x7902:if(size%4||size>8000000){load->CloseChunk();return IO_ERROR;}labels.resize(size/4);memcpy(labels.data(),bytes.data(),size);break;case 0x7903:{auto j=parseBounded(bytes);if(j.at("schema")!=2||j.at("version")!="0.3.1"){load->CloseChunk();return IO_ERROR;}mode=j.at("mode");live=j.at("live");clearance=j.at("clearance");stiffness=j.at("stiffness");savedPose=j.at("pose");savedKey=j.at("key");error=j.value("error",std::string());if(mode<0||mode>1||!std::isfinite(clearance)||clearance<0||clearance>.05||!std::isfinite(stiffness)||stiffness<0||stiffness>1){load->CloseChunk();return IO_ERROR;}break;}}load->CloseChunk();}ivalid.SetEmpty();return result==IO_END&&!metadata.empty()&&!labels.empty()?IO_OK:IO_ERROR;}catch(...){return IO_ERROR;}}
};
class Descriptor final:public ClassDesc2 {
public:int IsPublic()override{return FALSE;}void* Create(BOOL)override{return new StemObject;}const MCHAR* ClassName()override{return _T("CyrusVegetationStemObject");}const MCHAR* NonLocalizedClassName()override{return _T("CyrusVegetationStemObject");}SClass_ID SuperClassID()override{return GEOMOBJECT_CLASS_ID;}Class_ID ClassID()override{return stemId;}const MCHAR* Category()override{return _T("Cyrus Labs");}const MCHAR* InternalName()override{return _T("CyrusVegetationStemObject");}HINSTANCE HInstance()override{return module;}
};
StemObject* object(Value* value){auto* node=value->to_node();if(!node||!node->GetObjectRef()||node->GetObjectRef()->ClassID()!=stemId)throw std::runtime_error("Select the Stem Lab output.");return static_cast<StemObject*>(node->GetObjectRef());}
template<class F>Value* api(F f){try{return f();}catch(const std::exception& e){throw RuntimeError(wide(e.what()).c_str());}}
}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Vegetation Stem Lab 0.3.1 - Max 2027");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
// The DLX owns primitives and implementation. Only the DLO registers the geometry class.
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
extern "C" __declspec(dllexport) ClassDesc* CyrusStemDescriptor(){static Descriptor descriptor;return &descriptor;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
extern "C" __declspec(dllexport) void LibInit(){}
BOOL WINAPI DllMain(HINSTANCE h,DWORD reason,LPVOID){if(reason==DLL_PROCESS_ATTACH)module=h;return TRUE;}
def_visible_primitive(cvsVersion,"cvsVersion");
Value* cvsVersion_cf(Value**,int n){check_arg_count(cvsVersion,0,n);return text({{"version","0.3.1"},{"host",2027},{"type","stem-guided live test"}});}
def_visible_primitive(cvsCreate,"cvsCreate");
Value* cvsCreate_cf(Value** a,int n){check_arg_count(cvsCreate,4,n);return api([&]()->Value*{std::filesystem::path meta=a[2]->to_string(),parts=a[3]->to_string();if(std::filesystem::file_size(meta)>16*1024*1024||std::filesystem::file_size(parts)>8000000)throw std::runtime_error("Preparation file bound.");std::ifstream file(meta,std::ios::binary);std::string data((std::istreambuf_iterator<char>(file)),{});std::ifstream labelfile(parts,std::ios::binary);std::vector<unsigned> labels(std::filesystem::file_size(parts)/4);labelfile.read(reinterpret_cast<char*>(labels.data()),labels.size()*4);if(!labelfile)throw std::runtime_error("Label file unavailable.");auto* created=static_cast<StemObject*>(GetCOREInterface()->CreateInstance(GEOMOBJECT_CLASS_ID,stemId));if(!created)throw std::runtime_error("Stem class registration missing.");try{created->metadata=std::move(data);created->labels=std::move(labels);created->ReplaceReference(0,a[0]->to_node());created->ReplaceReference(1,a[1]->to_node());created->ensure(GetCOREInterface()->GetTime());auto* node=GetCOREInterface()->CreateObjectNode(created);node->SetNodeTM(GetCOREInterface()->GetTime(),Matrix3());node->SetName(_T("CVS_Stem_Lavender"));return MAXNode::intern(node);}catch(...){created->DeleteThis();throw;}});}
def_visible_primitive(cvsStats,"cvsStats");
Value* cvsStats_cf(Value** a,int n){check_arg_count(cvsStats,1,n);return api([&]()->Value*{auto* o=object(a[0]);Json j={{"version","0.3.1"},{"mode",o->mode},{"live",o->live},{"error",o->error},{"preparations",o->preparations},{"builds",o->builds},{"solves",o->solves},{"published",o->published},{"notifications",o->notifications},{"held_notifications",o->heldNotifications},{"render_requests",o->renderRequests},{"last",o->last},{"history",o->history}};if(o->cache){j["guides"]=o->cache->prepared->guides.size();j["preview_faces"]=o->cache->prepared->previewTriangles.size();j["full_faces"]=o->cache->prepared->triangles.size();j["preparation_ms"]=o->cache->preparationMs;}return text(j);});}
def_visible_primitive(cvsStatus,"cvsStatus");
Value* cvsStatus_cf(Value** a,int n){check_arg_count(cvsStatus,1,n);return api([&]()->Value*{auto* o=object(a[0]);std::string status=o->error.empty()?(o->live?"Live | ":"Paused | ")+(o->mode==0?std::string("Light preview"):std::string("Full viewport")):o->error;if(o->cache&&o->error.empty())status+=" | "+std::to_string(o->last.value("active_stems",0))+" active stems | "+std::to_string(o->last.value("solve_ms",0.))+" ms solve";return new String(wide(status).c_str());});}
def_visible_primitive(cvsMode,"cvsMode");
Value* cvsMode_cf(Value** a,int n){check_arg_count(cvsMode,2,n);return api([&]()->Value*{auto* o=object(a[0]);int mode=a[1]->to_int();if(mode<0||mode>1)throw std::runtime_error("Mode 0 preview / 1 full.");o->mode=mode;o->changed();return &true_value;});}
def_visible_primitive(cvsLive,"cvsLive");
Value* cvsLive_cf(Value** a,int n){check_arg_count(cvsLive,2,n);return api([&]()->Value*{auto* o=object(a[0]);o->live=a[1]->to_bool()!=FALSE;o->changed();return &true_value;});}
def_visible_primitive(cvsAudit,"cvsAudit");
Value* cvsAudit_cf(Value** a,int n){check_arg_count(cvsAudit,1,n);return api([&]()->Value*{auto* o=object(a[0]);auto time=GetCOREInterface()->GetTime();auto tm=a[0]->to_node()->GetObjectTM(time);Matrix3 identity;for(int row=0;row<4;++row)if(Length(tm.GetRow(row)-identity.GetRow(row))>1e-6f)throw std::runtime_error("Prepared output world transform must remain identity for validation.");o->evaluate(time);auto sphere=o->capture(time);return text(stem::audit(*o->cache->prepared,o->cache->pose,sphere.centre,sphere.radius,o->cache->unit));});}

#include "preparation_host.inl"

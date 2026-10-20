#include "recipes.h" // Parse JSON before MAXScript type-test macros.
#include "recipe_library.h"
#include "recipe_store.h"
#include "asset_package.h"
#include "asset_mesh.h"
#include "placement_value.h"
#include "script_buffers.h"
#include <max.h>
#include <plugin.h>
#include <ColorManagement/IColorPipelineMgr.h>
#include <triobj.h>
#include <splshape.h>
#include <MeshNormalSpec.h>
#include <icurvctl.h>
#include <hold.h>
#include <iparamb2.h>
#include <notify.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include "maxscript_number_types.h"
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/name.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/maxwrapper/bitmaps.h>
#include <maxscript/mxsplugin/mxsPlugin.h>
#include <maxscript/foundation/ValueHolderMember.h>
#include <maxscript/foundation/hashtable.h>
#include <maxscript/compiler/thunks.h>
#include "maxscript_heap.h"
#include <bcrypt.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include <cmath>
#include <fstream>
#include <thread>
#include <atomic>
#include <mutex>
#include <set>

namespace {
namespace r=cyrus::recipes;
std::string recipeUTF8(Value* value,std::size_t limit=r::maxTotalPaintBytes*2){
    type_check(value,String,_T("recipe text"));const auto* text=value->to_string();
    if(wcslen(text)>limit)throw RuntimeError(_T("Recipe text exceeds bounds"));
    const int size=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,text,-1,nullptr,0,nullptr,nullptr);if(size<=0)throw RuntimeError(_T("Invalid recipe Unicode"));
    std::string result(static_cast<std::size_t>(size),'\0');WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,text,-1,result.data(),size,nullptr,nullptr);result.pop_back();if(result.size()>limit)throw RuntimeError(_T("Recipe UTF-8 exceeds bounds"));return result;
}
Value* recipeString(const std::string& text){const int size=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,text.c_str(),-1,nullptr,0);if(size<=0)throw RuntimeError(_T("Invalid recipe UTF-8"));std::wstring result(static_cast<std::size_t>(size),L'\0');MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,text.c_str(),-1,result.data(),size);return new String(result.c_str());}
r::Json recipeTree(Value* value,int depth=0){
    if(depth>32)throw RuntimeError(_T("Recipe nesting exceeds 32"));
    if(value==&undefined)return nullptr;
    if(value==&true_value||value==&false_value)return value==&true_value;
    if(is_string(value))return recipeUTF8(value);
    if(cyrus::host::integerNumber(value))return value->to_int64();
    if(cyrus::host::floatNumber(value)){const double n=value->to_double();if(!std::isfinite(n))throw RuntimeError(_T("Nonfinite recipe number"));return n;}
    type_check(value,Array,_T("recipe data array"));auto* input=static_cast<Array*>(value);if(input->size>65536)throw RuntimeError(_T("Recipe array exceeds bounds"));
    if(input->size==2&&input->data[0]==Name::intern(_T("recipeObject"))){
        type_check(input->data[1],Array,_T("recipe object fields"));auto* rows=static_cast<Array*>(input->data[1]);if(rows->size>4096)throw RuntimeError(_T("Recipe object field limit"));auto result=r::Json::object();
        for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("recipe key/value"));auto* pair=static_cast<Array*>(rows->data[i]);if(pair->size!=2)throw RuntimeError(_T("Recipe field requires a key and value"));const auto key=recipeUTF8(pair->data[0],160);if(result.contains(key))throw RuntimeError(_T("Duplicate recipe field"));result[key]=recipeTree(pair->data[1],depth+1);}return result;
    }
    auto result=r::Json::array();for(int i=0;i<input->size;++i)result.push_back(recipeTree(input->data[i],depth+1));return result;
}
std::uint64_t recipeHeapBytes(const r::Json& value){
    // Conservative allocation accounting for the exact tree emitted below:
    // value headers, array backing storage, UTF-16 text and allocator slack.
    // Native geometry/bitmap storage and scene objects are accounted separately.
    if(value.is_null()||value.is_boolean())return 0;
    if(value.type()==r::Json::value_t::string)return 2*(sizeof(String)+64+2*(value.get_ref<const std::string&>().size()+1));
    if((value.is_number)())return 2*(sizeof(Double)+32);
    auto array=[](std::size_t count){return 2*(sizeof(Array)+64+count*sizeof(Value*));};
    std::uint64_t bytes=array(value.size());
    if(value.is_object()){
        bytes+=array(2);
        for(const auto& item:value.items())bytes+=array(2)+recipeHeapBytes(r::Json(item.key()))+recipeHeapBytes(item.value());
    }else for(const auto& item:value)bytes+=recipeHeapBytes(item);
    return bytes;
}
Value* recipeValue(const r::Json& value,bool admitted=false){
    if(!admitted)cyrus::host::admitScriptHeap(recipeHeapBytes(value));
    if(value.is_null())return &undefined;if(value.is_boolean())return value.get<bool>()?&true_value:&false_value;
    if(value.type()==r::Json::value_t::string)return recipeString(value.get<std::string>());
    if(value.is_number_integer())return Integer64::intern(value.get<std::int64_t>());
    if((value.is_number)())return Double::intern(value.get<double>());
    three_typed_value_locals(Array* result,Array* rows,Array* pair);
    if(value.is_object()){
        vl.result=new Array(2);vl.result->append(Name::intern(_T("recipeObject")));vl.rows=new Array(static_cast<int>(value.size()));vl.result->append(vl.rows);
        for(const auto& item:value.items()){vl.pair=new Array(2);vl.rows->append(vl.pair);vl.pair->append(recipeString(item.key()));vl.pair->append(recipeValue(item.value(),true));}
    }else{vl.result=new Array(static_cast<int>(value.size()));for(const auto& item:value)vl.result->append(recipeValue(item,true));}
    return_value(vl.result);
}
template<class F>Value* recipeAPI(F f){try{return f();}catch(const std::exception& e){throw RuntimeError(_T("Recipe: "),recipeString(e.what()));}}
// Light MAXScript collection deliberately retains MAXWrapper objects. A newly
// imported setup can therefore retain its large local calculation arrays even
// after its creation has been undone and that Redo entry has been discarded.
// Keep its caches intact throughout Undo/Redo; reset only these transient locals
// when Max finally discards the undone creation. No scripts, scene mutations,
// garbage collection, or new MAXScript allocations run in the destructor.
class ImportedCacheLifetime final : public RestoreObj {
    ValueHolderMember owner_;
    std::vector<std::pair<Value*,ValueHolderMember>> initial_;
    bool undone_=false;
    static int localSlot(MSPlugin* plugin,Value* name) {
        auto* entry=plugin->pc->local_scope->get(name);
        if(!entry||!is_pluginlocalthunk(entry))return -1;
        const int slot=static_cast<PluginLocalThunk*>(entry)->index;
        return slot>=0&&slot<plugin->pc->local_count?slot:-1;
    }
    static Value* copyInitial(Value* value) {
        if(!is_array(value))return value;
        auto* source=static_cast<Array*>(value);
        if(source->size>16)throw RuntimeError(_T("Track the new recipe owner before calculation"));
        ValueHolderMember result(new Array(source->size));
        auto* array=static_cast<Array*>(result.get_value());
        for(int i=0;i<source->size;++i)array->append(copyInitial(source->data[i]));
        return array;
    }
    struct SceneDependent final : DependentEnumProc {
        bool found=false;
        int proc(ReferenceMaker* value) override {
            if(value&&value->SuperClassID()==BASENODE_CLASS_ID){found=true;return DEP_ENUM_HALT;}
            return DEP_ENUM_CONTINUE;
        }
    };
public:
    explicit ImportedCacheLifetime(Value* value):owner_(value) {
        auto* plugin=dynamic_cast<MSPlugin*>(value->to_reftarg());
        if(!plugin||value->to_reftarg()->ClassID()!=Class_ID(0x617d43a1,0x395c2e17))
            throw RuntimeError(_T("Expected a newly created Cyrus recipe owner"));
        const MCHAR* names[]={
            _T("procPreparedRows"),_T("procPreparedKey"),_T("procReceiverPlanData"),_T("procReceiverCache"),_T("procReceiverGeometry"),
            _T("procNativePublication"),_T("procNativeContext"),
            _T("procPublishedOwners"),_T("procPublishedSources"),_T("procPublishedFinalKeep"),_T("procPublishedRadii"),_T("procPublishedInfo"),_T("procPublishedMetadata"),_T("procPublishedDisplayKey"),
            _T("groupSnapshotRows"),_T("groupSnapshotKey"),_T("groupPrepareRows"),_T("groupPrepareKey"),
            _T("paintBaseRows"),_T("paintBaseKey"),_T("paintBaseFaceCounts"),_T("blockerCacheRows"),_T("blockerCacheKey"),
            _T("procOrientationReceivers"),_T("procDensityCache"),_T("procGridCache"),_T("procSplineField"),
            _T("cachedPoints"),_T("cachedDisabledPreview"),_T("inspectionCache"),_T("radiusPreview"),
            _T("procPreviewModes"),_T("procPreviewModesEpoch"),_T("procPreviewDisplayKey"),_T("procPreviewGeometryKey"),_T("procPreviewInspectionKey"),
            _T("procFieldCache"),_T("procFieldCacheKey")};
        for(const auto* name:names){auto* key=Name::intern(name);const int slot=localSlot(plugin,key);
            if(slot<0)throw RuntimeError(_T("Recipe cache lifetime needs its matching script"));
            initial_.emplace_back(key,ValueHolderMember(copyInitial(plugin->get_local(slot))));
        }
    }
    ~ImportedCacheLifetime() override {
        if(!undone_)return;
        auto* value=owner_.get_value();auto* plugin=dynamic_cast<MSPlugin*>(value->to_reftarg());
        if(!plugin)return;
        // A caller may have deliberately attached the object elsewhere. Never
        // invalidate resources still reachable from a scene node.
        SceneDependent live;value->to_reftarg()->DoEnumDependents(&live);
        if(live.found)return;
        for(const auto& entry:initial_){const int slot=localSlot(plugin,entry.first);if(slot>=0)plugin->set_local(slot,entry.second.get_value());}
    }
    void Restore(int) override {undone_=true;}
    void Redo() override {undone_=false;}
    MSTR Description() override {return _T("Cyrus imported cache lifetime");}
};
// A ready-preset Load explicitly calculates after its authored hold. Keep its
// complete transient publication with that hold, so Undo/Redo needs no files or
// new solve. Values are immutable cache generations, retained by reference.
class PresetPublicationRestore final : public RestoreObj {
    struct Field {Value* name;ValueHolderMember before,after;};
    struct Owner {ValueHolderMember value;std::vector<Field> fields;};
    std::vector<Owner> owners_;bool captured_=false;
    static int slot(MSPlugin* p,Value* name){auto* v=p->pc->local_scope->get(name);return v&&is_pluginlocalthunk(v)?static_cast<PluginLocalThunk*>(v)->index:-1;}
    void apply(bool redo){
        for(auto& owner:owners_){auto* p=dynamic_cast<MSPlugin*>(owner.value.get_value()->to_reftarg());if(!p)continue;
            for(auto& field:owner.fields){const int i=slot(p,field.name);if(i>=0)p->set_local(i,(redo?field.after:field.before).get_value());}
            const int flag=slot(p,Name::intern(_T("procPresetPublicationRestored")));if(flag>=0)p->set_local(flag,&true_value);
        }
    }
public:
    explicit PresetPublicationRestore(Array* owners){
        if(owners->size<1||owners->size>11)throw RuntimeError(_T("Preset publication owner limit"));
        const MCHAR* names[]={_T("procEpoch"),_T("procPublishedOwners"),_T("procPublishedSources"),_T("procPublishedFinalKeep"),_T("procPublishedRadii"),_T("procPublishedInfo"),_T("procPublishedMetadata"),_T("procPublishedDisplayKey"),_T("groupSnapshotRows"),_T("groupSnapshotKey"),_T("groupPrepareRows"),_T("groupPrepareKey"),_T("procPreparedRows"),_T("procPreparedKey"),_T("procReceiverCache"),_T("procReceiverGeometry"),_T("procReceiverPlanData"),_T("procOrientationReceivers"),_T("procGridCache"),_T("paintBaseRows"),_T("paintBaseKey"),_T("paintBaseFaceCounts"),_T("cachedPoints"),_T("cachedPointCount"),_T("generatedCount"),_T("radiusPreview"),_T("inspectionCache"),_T("procPreviewDisplayKey"),_T("procPreviewGeometryKey"),_T("procPreviewInspectionKey"),_T("procPreviewModes"),_T("procPreviewModesEpoch"),_T("procLastStats"),_T("procLastRounds"),_T("requestedCount"),_T("groupEligible"),_T("groupRemoved"),_T("groupConflicts"),_T("overlapBefore"),_T("overlapAfter"),_T("procLastSurfaceStats"),_T("procDependencyHandles"),_T("inputTimeObserved"),_T("orientationTimeObserved"),_T("previewBuildCount"),_T("previewError"),_T("dirty")};
        // The native publication and its scripted epoch/manifest are one frame.
        // Restoring only the old script fields leaves the newer native frame
        // pinned and rejects the first successor after preset Undo.
        const MCHAR* nativeNames[]={_T("procNativePublication"),_T("procNativeContext"),_T("procNativeLastAdmission")};
        for(int j=0;j<owners->size;++j){auto* value=owners->data[j];auto* p=dynamic_cast<MSPlugin*>(value->to_reftarg());if(!p||value->to_reftarg()->ClassID()!=Class_ID(0x617d43a1,0x395c2e17))throw RuntimeError(_T("Expected Cyrus preset owner"));Owner owner{ValueHolderMember(value),{}};
            for(const auto* name:nativeNames){auto* key=Name::intern(name);const int i=slot(p,key);if(i<0)throw RuntimeError(_T("Preset publication requires its matching native script"));owner.fields.push_back({key,ValueHolderMember(p->get_local(i)),ValueHolderMember(&undefined)});}
            for(const auto* name:names){auto* key=Name::intern(name);const int i=slot(p,key);if(i<0)throw RuntimeError(_T("Preset publication requires its matching script"));owner.fields.push_back({key,ValueHolderMember(p->get_local(i)),ValueHolderMember(&undefined)});}owners_.push_back(std::move(owner));}
    }
    void Restore(int) override {
        if(!captured_){for(auto& owner:owners_){auto* p=dynamic_cast<MSPlugin*>(owner.value.get_value()->to_reftarg());for(auto& field:owner.fields)field.after=p->get_local(slot(p,field.name));}captured_=true;}
        apply(false);
    }
    void Redo() override {if(captured_)apply(true);}
    MSTR Description() override {return _T("Cyrus preset publication");}
};
class PackageTask {
    std::thread worker_;std::atomic<bool> stop_{false},done_{true};std::mutex mutex_;
    std::uint64_t token_=0,bytes_=0;std::string state_="idle",stage_,error_,result_;
    std::shared_ptr<const cyrus::assets::PreparedPackage> prepared_;
public:
    ~PackageTask(){stop_=true;if(worker_.joinable())worker_.join();}
    std::uint64_t start(std::filesystem::path output,std::filesystem::path recipe,std::string hash,r::Json graph,std::map<std::string,std::filesystem::path> inputs,std::string declaration){
        if(!done_)throw std::runtime_error("Wait for the preceding package export to finish or cancel.");if(worker_.joinable())worker_.join();
        {std::lock_guard lock(mutex_);++token_;bytes_=0;state_="exporting";stage_="starting";error_.clear();result_.clear();prepared_.reset();}stop_=false;done_=false;
        try{worker_=std::thread([this,output=std::move(output),recipe=std::move(recipe),hash=std::move(hash),graph=std::move(graph),inputs=std::move(inputs),declaration=std::move(declaration)]{
            try{
                const auto result=cyrus::assets::writePackage(output,recipe,hash,graph,inputs,declaration,[this](const char* stage,std::uint64_t bytes){if(stop_)throw std::runtime_error("Package export cancelled.");std::lock_guard lock(mutex_);stage_=stage;bytes_=bytes;});
                std::lock_guard lock(mutex_);state_="complete";const auto utf8=result.u8string();result_={utf8.begin(),utf8.end()};
            }catch(const std::exception& e){std::lock_guard lock(mutex_);state_=stop_?"cancelled":"failed";error_=e.what();}
            done_=true;
        });}catch(...){done_=true;std::lock_guard lock(mutex_);state_="failed";throw;}
        return token_;
    }
    std::uint64_t read(std::filesystem::path directory,std::filesystem::path bitmapDirectory){
        if(!done_)throw std::runtime_error("Wait for the preceding package operation to finish or cancel.");if(worker_.joinable())worker_.join();
        {std::lock_guard lock(mutex_);++token_;bytes_=0;state_="preparing";stage_="verifying";error_.clear();result_.clear();prepared_.reset();}stop_=false;done_=false;
        try{worker_=std::thread([this,directory=std::move(directory),bitmapDirectory=std::move(bitmapDirectory)]{
            try{
                auto result=std::make_shared<cyrus::assets::PreparedPackage>(cyrus::assets::preparePackage(directory,[this](const char* stage,std::uint64_t bytes){if(stop_)throw std::runtime_error("Package preparation cancelled.");std::lock_guard lock(mutex_);stage_=stage;bytes_=bytes;},bitmapDirectory));
                std::lock_guard lock(mutex_);if(stop_)throw std::runtime_error("Package preparation cancelled.");prepared_=std::move(result);state_="ready";
            }catch(const std::exception& e){std::lock_guard lock(mutex_);state_=stop_?"cancelled":"failed";error_=e.what();}
            done_=true;
        });}catch(...){done_=true;std::lock_guard lock(mutex_);state_="failed";throw;}
        return token_;
    }
    std::shared_ptr<const cyrus::assets::PreparedPackage> prepared(std::uint64_t token){std::lock_guard lock(mutex_);if(token!=token_||state_!="ready"||!prepared_)throw std::runtime_error("Package snapshot is missing, still preparing or replaced. Review again.");return prepared_;}
    r::Json poll(std::uint64_t token){std::lock_guard lock(mutex_);if(token!=token_)throw std::runtime_error("Package task was replaced.");return r::Json::array({state_,stage_,bytes_,error_,result_});}
    void cancel(std::uint64_t token){std::lock_guard lock(mutex_);if(token!=token_)throw std::runtime_error("Package task was replaced.");stop_=true;}
    void release(std::uint64_t token){std::lock_guard lock(mutex_);if(token!=token_)return;stop_=true;prepared_.reset();if(state_=="ready")state_="released";}
};
PackageTask* packageTask=nullptr;
r::Library& recipeLibrary();
PackageTask& packages(){recipeLibrary();if(!packageTask)packageTask=new PackageTask;return *packageTask;}
}

#include "asset_mesh_host.inc"

def_visible_primitive(cyrusAssetPackageVersion,"cyrusAssetPackageVersion");
Value* cyrusAssetPackageVersion_cf(Value**,int n){check_arg_count(cyrusAssetPackageVersion,0,n);return Integer::intern(3);}
// This resolves the actual registered renderer class, not a guessed installation
// path or the active renderer caption. The host adapter checks the module version
// before constructing/staging any renderer graph. No module path is serialized.
def_visible_primitive(cyrusAssetRendererModule,"cyrusAssetRendererModule");
Value* cyrusAssetRendererModule_cf(Value**,int n){check_arg_count(cyrusAssetRendererModule,0,n);return recipeAPI([&]()->Value*{
    auto* descriptor=GetCOREInterface()->GetDllDir().ClassDir().FindClass(MATERIAL_CLASS_ID,Class_ID(1762831241u,2266306336u));
    if(!descriptor||!descriptor->HInstance())throw RuntimeError(_T("The qualified Corona material plugin is unavailable"));
    std::vector<wchar_t> path(32768);const auto size=GetModuleFileNameW(descriptor->HInstance(),path.data(),static_cast<DWORD>(path.size()));
    if(size==0||size>=path.size())throw RuntimeError(_T("Cannot identify the loaded Corona material module"));
    return new String(path.data());
});}
// Fixed Forest map identities only. Both classes must belong to the same actual
// registered module; authored names, search paths and package strings are unused.
def_visible_primitive(cyrusAssetForestModule,"cyrusAssetForestModule");
Value* cyrusAssetForestModule_cf(Value**,int n){check_arg_count(cyrusAssetForestModule,0,n);return recipeAPI([&]()->Value*{
    auto& classes=GetCOREInterface()->GetDllDir().ClassDir();
    auto* color=classes.FindClass(TEXMAP_CLASS_ID,Class_ID(1613723927u,104154128u));
    auto* edge=classes.FindClass(TEXMAP_CLASS_ID,Class_ID(1568227357u,1783892597u));
    if(!color||!edge||!color->HInstance()||color->HInstance()!=edge->HInstance())throw RuntimeError(_T("The qualified Forest map plugin is unavailable or inconsistent"));
    std::vector<wchar_t> path(32768);const auto size=GetModuleFileNameW(color->HInstance(),path.data(),static_cast<DWORD>(path.size()));
    if(size==0||size>=path.size())throw RuntimeError(_T("Cannot identify the loaded Forest map module"));
    return new String(path.data());
});}
def_visible_primitive(cyrusAssetSplineSnapshot,"cyrusAssetSplineSnapshot");
Value* cyrusAssetSplineSnapshot_cf(Value** a,int n){check_arg_count(cyrusAssetSplineSnapshot,2,n);return recipeAPI([&]()->Value*{
    auto* node=a[0]->to_node();const double metres=a[1]->to_double();if(!node||!std::isfinite(metres)||metres<=0)throw RuntimeError(_T("Invalid preset spline input"));
    const auto time=GetCOREInterface()->GetTime();auto* object=node->EvalWorldState(time).obj;
    if(!object||object->SuperClassID()!=SHAPE_CLASS_ID)throw RuntimeError(_T("Preset path requires a shape"));auto* shape=static_cast<ShapeObject*>(object);
    const int count=shape->NumberOfCurves(time);if(count<1||count>128||!shape->CanMakeBezier())throw RuntimeError(_T("Preset path exceeds supported curve bounds"));
    std::size_t pieces=0;for(int i=0;i<count;++i){const int n=shape->NumberOfPieces(time,i);if(n<1)throw RuntimeError(_T("Preset path is empty"));pieces+=std::size_t(n)+(shape->CurveClosed(time,i)?0:1);if(pieces>4096)throw RuntimeError(_T("Preset paths exceed 4096 knots"));}
    BezierShape copy;shape->MakeBezier(time,copy);if(copy.SplineCount()!=count)throw RuntimeError(_T("Preset path conversion changed curve count"));
    auto point=[&](const Point3& p){return cyrus::recipes::Json::array({p.x/metres,p.y/metres,p.z/metres});};
    cyrus::recipes::Json curves=cyrus::recipes::Json::array();std::size_t total=0;
    for(int i=0;i<count;++i){auto* spline=copy.GetSpline(i);const int knots=spline?spline->KnotCount():0;total+=std::size_t(std::max(0,knots));if(knots<2||total>4096)throw RuntimeError(_T("Preset paths exceed supported knot bounds"));cyrus::recipes::Json rows=cyrus::recipes::Json::array();
        for(int k=0;k<knots;++k){const int type=spline->GetKnotType(k);const char* name=type==KTYPE_CORNER?"corner":type==KTYPE_AUTO?"smooth":type==KTYPE_BEZIER?"bezier":type==KTYPE_BEZIER_CORNER?"bezierCorner":nullptr;if(!name)throw RuntimeError(_T("Unsupported preset knot type"));rows.push_back({{"type",name},{"line",spline->GetLineType(k)==LTYPE_LINE?"line":"curve"},{"point",point(spline->GetKnotPoint(k))},{"in",point(spline->GetInVec(k))},{"out",point(spline->GetOutVec(k))}});}
        curves.push_back({{"closed",spline->Closed()!=0},{"knots",rows}});
    }
    return recipeValue(curves);
});}
def_visible_primitive(cyrusAssetPackageStart,"cyrusAssetPackageStart");
Value* cyrusAssetPackageStart_cf(Value** a,int n){check_arg_count(cyrusAssetPackageStart,7,n);return recipeAPI([&]()->Value*{
    type_check(a[0],String,_T("package destination"));type_check(a[1],String,_T("package recipe"));type_check(a[4],Array,_T("package file bindings"));
    auto* rows=static_cast<Array*>(a[4]);if(rows->size>256)throw RuntimeError(_T("Package file binding limit exceeded"));std::map<std::string,std::filesystem::path> files;
    for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("package file binding"));auto* row=static_cast<Array*>(rows->data[i]);if(row->size!=2)throw RuntimeError(_T("Package file binding needs ID and path"));type_check(row->data[1],String,_T("package source path"));if(!files.emplace(recipeUTF8(row->data[0],80),std::filesystem::path(row->data[1]->to_string())).second)throw RuntimeError(_T("Duplicate package file binding"));}
    // The seventh argument pins the adapter capability, separate from product version.
    if(a[6]->to_int()!=1)throw RuntimeError(_T("Unsupported package adapter capability"));
    return Integer64::intern(packages().start(std::filesystem::path(a[0]->to_string()),std::filesystem::path(a[1]->to_string()),recipeUTF8(a[2],64),recipeTree(a[3]),std::move(files),recipeUTF8(a[5],1024)));
});}
def_visible_primitive(cyrusAssetPackagePoll,"cyrusAssetPackagePoll");
Value* cyrusAssetPackagePoll_cf(Value** a,int n){check_arg_count(cyrusAssetPackagePoll,1,n);return recipeAPI([&]()->Value*{return recipeValue(packages().poll(a[0]->to_int64()));});}
def_visible_primitive(cyrusAssetPackageCancel,"cyrusAssetPackageCancel");
Value* cyrusAssetPackageCancel_cf(Value** a,int n){check_arg_count(cyrusAssetPackageCancel,1,n);return recipeAPI([&]()->Value*{packages().cancel(a[0]->to_int64());return &ok;});}
def_visible_primitive(cyrusAssetPackageRead,"cyrusAssetPackageRead");
Value* cyrusAssetPackageRead_cf(Value** a,int n){check_arg_count(cyrusAssetPackageRead,1,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("package directory"));return recipeValue(cyrus::assets::readPackage(std::filesystem::path(a[0]->to_string())));});}
def_visible_primitive(cyrusAssetPackagePrepare,"cyrusAssetPackagePrepare");
Value* cyrusAssetPackagePrepare_cf(Value** a,int n){check_arg_count(cyrusAssetPackagePrepare,2,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("package directory"));type_check(a[1],String,_T("owned bitmap directory"));return Integer64::intern(packages().read(std::filesystem::path(a[0]->to_string()),std::filesystem::path(a[1]->to_string())));});}
def_visible_primitive(cyrusAssetPackagePrepared,"cyrusAssetPackagePrepared");
Value* cyrusAssetPackagePrepared_cf(Value** a,int n){check_arg_count(cyrusAssetPackagePrepared,2,n);return recipeAPI([&]()->Value*{const auto snapshot=packages().prepared(a[0]->to_int64());return recipeValue(a[1]->to_bool()?snapshot->document:snapshot->metadata);});}
def_visible_primitive(cyrusAssetPackageRelease,"cyrusAssetPackageRelease");
Value* cyrusAssetPackageRelease_cf(Value** a,int n){check_arg_count(cyrusAssetPackageRelease,1,n);return recipeAPI([&]()->Value*{packages().release(a[0]->to_int64());return &ok;});}
def_visible_primitive(cyrusAssetFileInfo,"cyrusAssetFileInfo");
Value* cyrusAssetFileInfo_cf(Value** a,int n){check_arg_count(cyrusAssetFileInfo,2,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("asset filename"));return recipeValue(cyrus::assets::fileInfo(std::filesystem::path(a[0]->to_string()),a[1]->to_bool()));});}
def_visible_primitive(cyrusAssetImageInfo,"cyrusAssetImageInfo");
Value* cyrusAssetImageInfo_cf(Value** a,int n){check_arg_count(cyrusAssetImageInfo,1,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("asset image filename"));return recipeValue(cyrus::assets::imageFileInfo(std::filesystem::path(a[0]->to_string())));});}
def_visible_primitive(cyrusAssetImageAdmission,"cyrusAssetImageAdmission");
Value* cyrusAssetImageAdmission_cf(Value** a,int n){check_arg_count(cyrusAssetImageAdmission,1,n);return recipeAPI([&]()->Value*{
    const auto pixels=a[0]->to_int64();if(pixels<0||static_cast<std::uint64_t>(pixels)>cyrus::assets::maxPlantBitmapPixels)throw RuntimeError(_T("Plant image map instances exceed the bounded profile"));
    // Conservative admission for the new profile, not a renderer allocation
    // measurement: two RGBA32F equivalents per map instance, plus 768 MiB for
    // admitted small meshes/material/staging overhead. Existing old state and
    // Undo allocations are already reflected in current available memory.
    const auto estimate=static_cast<std::uint64_t>(pixels)*32+768ull*1024*1024;
    constexpr auto reserve=2ull*1024*1024*1024;MEMORYSTATUSEX memory{};memory.dwLength=sizeof(memory);
    if(!GlobalMemoryStatusEx(&memory))throw RuntimeError(_T("Cannot check plant-image memory admission"));
    if(memory.ullAvailPhys<estimate+reserve||memory.ullAvailPageFile<estimate+reserve)throw RuntimeError(_T("Insufficient available physical/commit memory for the plant-image profile and its 2 GiB reserve. Existing planting is retained."));
    return recipeValue(r::Json::array({estimate,memory.ullAvailPhys,memory.ullAvailPageFile}));
});}
// Candidate large-plant host admission is separate from the existing image tier.
// Current free memory already includes retained output, source objects and Undo.
def_visible_primitive(cyrusAssetPlantSceneAdmission,"cyrusAssetPlantSceneAdmission");
Value* cyrusAssetPlantSceneAdmission_cf(Value** a,int n){check_arg_count(cyrusAssetPlantSceneAdmission,2,n);return recipeAPI([&]()->Value*{
    if(!cyrus::host::integerNumber(a[0])||!cyrus::host::integerNumber(a[1]))throw RuntimeError(_T("Plant resource counts require integers"));
    const auto meshes=a[0]->to_int64(),pixels=a[1]->to_int64();
    if(meshes<0||static_cast<std::uint64_t>(meshes)>cyrus::assets::maxPlantPackageBytes||pixels<0||static_cast<std::uint64_t>(pixels)>cyrus::assets::maxPlantBitmapPixels)throw RuntimeError(_T("Plant resources exceed the bounded profile"));
    // Six encoded mesh equivalents reserve SDK source/conversion/prototype and
    // publication overlap; two RGBA32F equivalents reserve bitmap map instances.
    // This conservative candidate plan requires actual workload qualification.
    const auto estimate=static_cast<std::uint64_t>(meshes)*6+static_cast<std::uint64_t>(pixels)*32+1024ull*1024ull*1024ull;
    constexpr auto reserve=2ull*1024ull*1024ull*1024ull;MEMORYSTATUSEX memory{};memory.dwLength=sizeof(memory);
    if(!GlobalMemoryStatusEx(&memory))throw RuntimeError(_T("Cannot check plant-asset memory admission"));
    if(memory.ullAvailPhys<estimate+reserve||memory.ullAvailPageFile<estimate+reserve)throw RuntimeError(_T("Insufficient available physical/commit memory for plant assets and their 2 GiB reserve. Existing planting is retained."));
    return recipeValue(r::Json::array({estimate,memory.ullAvailPhys,memory.ullAvailPageFile}));
});}

def_visible_primitive(cyrusAssetPreparedBitmap,"cyrusAssetPreparedBitmap");
Value* cyrusAssetPreparedBitmap_cf(Value** a,int n){check_arg_count(cyrusAssetPreparedBitmap,2,n);return recipeAPI([&]()->Value*{const auto snapshot=packages().prepared(a[0]->to_int64());const auto found=snapshot->bitmapPaths.find(recipeUTF8(a[1],80));if(found==snapshot->bitmapPaths.end())throw RuntimeError(_T("Bitmap is absent from the prepared package"));return new String(found->second.c_str());});}
#include "asset_bitmap_host.inc"
namespace {
Value* compareAssetBitmaps(Value* leftValue,Value* rightValue,int edge){
    type_check(leftValue,MAXBitMap,_T("source bitmap"));type_check(rightValue,MAXBitMap,_T("file bitmap"));auto* source=static_cast<MAXBitMap*>(leftValue)->bm;auto* file=static_cast<MAXBitMap*>(rightValue)->bm;
    if(!source||!file)throw RuntimeError(_T("Bitmap was closed"));const int width=source->Width(),height=source->Height();
    if(width<1||height<1||width>edge||height>edge||static_cast<std::uint64_t>(width)*height>static_cast<std::uint64_t>(edge)*edge)throw RuntimeError(_T("Bitmap comparison exceeds portable pixel bounds"));if(width!=file->Width()||height!=file->Height())return &false_value;
    std::vector<BMM_Color_fl> left(static_cast<std::size_t>(width)),right(static_cast<std::size_t>(width));
    for(int y=0;y<height;++y){if(!source->GetLinearPixels(0,y,width,left.data())||!file->GetLinearPixels(0,y,width,right.data()))throw RuntimeError(_T("Cannot verify bitmap pixels"));
        for(int x=0;x<width;++x){const auto& p=left[x];const auto& q=right[x];const float av[]={p.r,p.g,p.b,p.a},bv[]={q.r,q.g,q.b,q.a};for(int c=0;c<4;++c)if(!std::isfinite(av[c])||!std::isfinite(bv[c])||std::abs(av[c]-bv[c])>2e-6f)return &false_value;}}
    return &true_value;
}
}
def_visible_primitive(cyrusAssetBitmapEqual,"cyrusAssetBitmapEqual");
Value* cyrusAssetBitmapEqual_cf(Value** a,int n){check_arg_count(cyrusAssetBitmapEqual,2,n);return recipeAPI([&]()->Value*{return compareAssetBitmaps(a[0],a[1],4096);});}
def_visible_primitive(cyrusAssetImageEqual,"cyrusAssetImageEqual");
Value* cyrusAssetImageEqual_cf(Value** a,int n){check_arg_count(cyrusAssetImageEqual,2,n);return recipeAPI([&]()->Value*{return compareAssetBitmaps(a[0],a[1],8192);});}
def_visible_primitive(cyrusAssetDefaultCurves,"cyrusAssetDefaultCurves");
Value* cyrusAssetDefaultCurves_cf(Value** a,int n){check_arg_count(cyrusAssetDefaultCurves,2,n);return recipeAPI([&]()->Value*{
    auto collect=[](ReferenceTarget* root){std::vector<ICurveCtl*> curves;std::set<ReferenceTarget*> seen;
        std::function<void(ReferenceTarget*,int)> walk=[&](ReferenceTarget* ref,int depth){if(!ref||seen.count(ref))return;if(depth>8||seen.size()>=64)throw RuntimeError(_T("Texture output references exceed the supported adapter"));seen.insert(ref);
            if(ref->ClassID()==CURVE_CONTROL_CLASS_ID){curves.push_back(static_cast<ICurveCtl*>(ref));return;}for(int i=0;i<ref->NumRefs();++i)walk(ref->GetReference(i),depth+1);};walk(root,0);return curves;};
    const auto left=collect(a[0]->to_reftarg()),right=collect(a[1]->to_reftarg());bool same=left.size()==right.size();
    for(std::size_t i=0;same&&i<left.size();++i){auto* x=left[i];auto* y=right[i];same=x->GetNumCurves()==y->GetNumCurves()&&x->GetNumCurves()<=8&&x->GetXRange()==y->GetXRange()&&x->GetYRange()==y->GetYRange();
        for(int j=0;same&&j<x->GetNumCurves();++j){auto* p=x->GetControlCurve(j);auto* q=y->GetControlCurve(j);same=p&&q&&p->GetNumPts()==q->GetNumPts()&&p->GetNumPts()<=64&&p->GetOutOfRangeType()==q->GetOutOfRangeType();
            for(int k=0;same&&k<p->GetNumPts();++k){const auto u=p->GetPoint(GetCOREInterface()->GetTime(),k),v=q->GetPoint(GetCOREInterface()->GetTime(),k);same=!p->IsAnimated(k)&&u.p==v.p&&u.in==v.in&&u.out==v.out&&((u.flags^v.flags)&~CURVEP_SELECTED)==0;}}}
    if(!same)throw RuntimeError(_T("Authored texture-output curves require a separate portable adapter, including disabled curves"));return &ok;
});}
// Read the admitted immutable mesh without creating a temporary scene node.
def_visible_primitive(cyrusAssetPreparedMeshBounds,"cyrusAssetPreparedMeshBounds");
Value* cyrusAssetPreparedMeshBounds_cf(Value** a,int n){check_arg_count(cyrusAssetPreparedMeshBounds,2,n);return recipeAPI([&]()->Value*{
    const auto snapshot=packages().prepared(a[0]->to_int64());const auto id=recipeUTF8(a[1],80);
    const auto found=snapshot->meshes.find(id);if(found==snapshot->meshes.end())throw RuntimeError(_T("Saved receiver mesh is absent from the prepared package"));
    std::array<double,4> bounds{INFINITY,INFINITY,-INFINITY,-INFINITY};
    for(const auto& face:found->second->faces)for(const auto index:face.vertices){
        const auto& point=found->second->vertices[index];
        bounds[0]=std::min(bounds[0],point[0]);bounds[1]=std::min(bounds[1],point[1]);
        bounds[2]=std::max(bounds[2],point[0]);bounds[3]=std::max(bounds[3],point[1]);
    }
    if(!(bounds[2]>bounds[0])||!(bounds[3]>bounds[1]))throw RuntimeError(_T("Saved receiver has no usable local XY footprint"));
    return recipeValue(r::Json::array({bounds[0],bounds[1],bounds[2],bounds[3]}));
});}

def_visible_primitive(cyrusAssetReceiverBounds,"cyrusAssetReceiverBounds");
Value* cyrusAssetReceiverBounds_cf(Value** a,int n){check_arg_count(cyrusAssetReceiverBounds,1,n);return recipeAPI([&]()->Value*{
    auto* node=a[0]->to_node();if(!node)throw RuntimeError(_T("Preset receiver is missing"));const auto time=GetCOREInterface()->GetTime();
    auto* object=node->EvalWorldState(time).obj;
    if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw RuntimeError(_T("Preset receiver must provide a mesh"));
    auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));
    if(!tri)throw RuntimeError(_T("Preset receiver mesh evaluation failed"));
    const auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> holder(tri,cleanup);
    const auto& mesh=tri->GetMesh();if(mesh.getNumVerts()>2000000||mesh.getNumFaces()>2000000)throw RuntimeError(_T("Preset receiver exceeds 2 million vertices or faces"));
    std::array<double,4> bounds{INFINITY,INFINITY,-INFINITY,-INFINITY};
    for(int i=0;i<mesh.getNumFaces();++i)for(int k=0;k<3;++k){
        const auto index=mesh.faces[i].v[k];if(index>=DWORD(mesh.getNumVerts()))throw RuntimeError(_T("Preset receiver contains an invalid face"));const auto& point=mesh.verts[index];
        if(!std::isfinite(point.x)||!std::isfinite(point.y))throw RuntimeError(_T("Preset receiver contains nonfinite coordinates"));
        bounds[0]=std::min(bounds[0],double(point.x));bounds[1]=std::min(bounds[1],double(point.y));
        bounds[2]=std::max(bounds[2],double(point.x));bounds[3]=std::max(bounds[3],double(point.y));
    }
    if(!(bounds[2]>bounds[0])||!(bounds[3]>bounds[1]))throw RuntimeError(_T("Preset receiver has no usable local XY footprint"));
    return recipeValue(r::Json::array({bounds[0],bounds[1],bounds[2],bounds[3]}));
});}

def_visible_primitive(cyrusRecipeVersion,"cyrusRecipeVersion");
Value* cyrusRecipeVersion_cf(Value**,int n){check_arg_count(cyrusRecipeVersion,0,n);return Integer::intern(7);}
def_visible_primitive(cyrusRecipeTrackCreated,"cyrusRecipeTrackCreated");
def_visible_primitive(cyrusPresetTrackPublication,"cyrusPresetTrackPublication");
Value* cyrusPresetTrackPublication_cf(Value** a,int n){check_arg_count(cyrusPresetTrackPublication,1,n);type_check(a[0],Array,_T("Preset publication owners"));
    if(!theHold.Holding())throw RuntimeError(_T("Preset publication requires its authored hold"));auto restore=std::make_unique<PresetPublicationRestore>(static_cast<Array*>(a[0]));
    if(!theHold.Put(restore.get()))throw RuntimeError(_T("Cannot record preset publication"));restore.release();return &ok;
}
Value* cyrusRecipeTrackCreated_cf(Value** a,int n){
    check_arg_count(cyrusRecipeTrackCreated,1,n);
    if(!theHold.Holding())throw RuntimeError(_T("Recipe lifetime requires its authored hold"));
    auto restore=std::make_unique<ImportedCacheLifetime>(a[0]);
    if(!theHold.Put(restore.get()))throw RuntimeError(_T("Recipe lifetime could not join the authored hold"));
    restore.release();return &ok;
}
def_visible_primitive(cyrusRecipeImportWorkingBytes,"cyrusRecipeImportWorkingBytes");
Value* cyrusRecipeImportWorkingBytes_cf(Value** a,int n){check_arg_count(cyrusRecipeImportWorkingBytes,1,n);return recipeAPI([&]()->Value*{
    const auto document=recipeTree(a[0]);r::validate(document,true);
    std::uint64_t owners=1;for(const auto& layer:document.at("layers"))owners+=1+layer.at("areas").size();
    // Hold-era scalar/array copies, wrappers, correspondence and UI rebinding.
    // An allowance is admission, not a claim about total process memory.
    return Integer64::intern(static_cast<INT64>(8*1024*1024+owners*1024*1024+2*recipeHeapBytes(document)));
});}
def_visible_primitive(cyrusRecipeCheckStatic,"cyrusRecipeCheckStatic");
Value* cyrusRecipeCheckStatic_cf(Value** a,int n){check_arg_count(cyrusRecipeCheckStatic,1,n);auto* owner=a[0]->to_reftarg();if(!owner)throw RuntimeError(_T("Recipe owner is missing"));
    for(int b=0;b<owner->NumParamBlocks();++b){auto* block=owner->GetParamBlock(b);if(!block)continue;for(int p=0;p<block->NumParams();++p){const auto id=block->IndextoID(p);const int entries=is_tab(block->GetParameterType(id))?block->Count(id):1;for(int i=0;i<entries;++i){auto* control=block->GetControllerByIndex(p,i);if(!control)continue;const auto type=control->ClassID();bool supported=false;if(type.PartB()==0&&control->NumKeys()==0)switch(type.PartA()){case LININTERP_FLOAT_CLASS_ID:case HYBRIDINTERP_FLOAT_CLASS_ID:case TCBINTERP_FLOAT_CLASS_ID:case HYBRIDINTERP_POINT3_CLASS_ID:case HYBRIDINTERP_COLOR_CLASS_ID:case TCBINTERP_POINT3_CLASS_ID:supported=true;break;default:break;}if(!supported){const auto* name=block->GetParamDef(id).int_name;throw RuntimeError(_T("Save Everything requires a supported static parameter controller: "),new String(name?name:_T("unnamed parameter")));}}}}
    return &ok;
}
def_visible_primitive(cyrusRecipeSchema,"cyrusRecipeSchema");
Value* cyrusRecipeSchema_cf(Value**,int n){check_arg_count(cyrusRecipeSchema,0,n);return recipeAPI([&]()->Value*{r::Json result=r::Json::array();for(const auto& f:r::fields())result.push_back({f.name,f.type,f.distance});return recipeValue(result);});}
def_visible_primitive(cyrusRecipeValidate,"cyrusRecipeValidate");
Value* cyrusRecipeValidate_cf(Value** a,int n){check_arg_count(cyrusRecipeValidate,1,n);return recipeAPI([&]()->Value*{r::validate(recipeTree(a[0]),true);return &ok;});}

def_visible_primitive(cyrusRecipeStyleValidate,"cyrusRecipeStyleValidate");
Value* cyrusRecipeStyleValidate_cf(Value** a,int n){check_arg_count(cyrusRecipeStyleValidate,3,n);return recipeAPI([&]()->Value*{
    auto* owner=a[0]->to_reftarg();if(!owner)throw RuntimeError(_T("Style destination is missing"));
    r::validateSettings(recipeTree(a[1]));
    type_check(a[2],Array,_T("style fields"));auto* fields=static_cast<Array*>(a[2]);
    if(fields->size>128)throw RuntimeError(_T("Style field limit exceeded"));
    for(int f=0;f<fields->size;++f){
        type_check(fields->data[f],String,_T("style field name"));const auto* name=fields->data[f]->to_string();bool found=false;
        for(int b=0;b<owner->NumParamBlocks();++b){auto* block=owner->GetParamBlock(b);if(!block)continue;
            for(int p=0;p<block->NumParams();++p){const auto id=block->IndextoID(p);const auto* key=block->GetParamDef(id).int_name;
                if(!key||_wcsicmp(key,name)!=0)continue;found=true;
                // Scalar controllers are detached by the command. Array controller
                // transfer has no qualified adapter; reject before any assignment.
                if(is_tab(block->GetParameterType(id)))for(int i=0;i<block->Count(id);++i)if(block->GetControllerByIndex(p,i))
                    throw RuntimeError(_T("Apply Style preserves controlled arrays. Remove the selected group or use a controller-free destination: "),new String(name));
            }
        }
        if(!found)throw RuntimeError(_T("Unknown style destination field: "),new String(name));
    }
    return &ok;
});}
def_visible_primitive(cyrusRecipeWrite,"cyrusRecipeWrite");
Value* cyrusRecipeWrite_cf(Value** a,int n){check_arg_count(cyrusRecipeWrite,2,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("recipe filename"));r::writeNew(std::filesystem::path(a[0]->to_string()),recipeTree(a[1]));return &ok;});}
def_visible_primitive(cyrusRecipeRead,"cyrusRecipeRead");
Value* cyrusRecipeRead_cf(Value** a,int n){check_arg_count(cyrusRecipeRead,1,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("recipe filename"));return recipeValue(r::read(std::filesystem::path(a[0]->to_string())));});}
def_visible_primitive(cyrusRecipeReadMetadata,"cyrusRecipeReadMetadata");
Value* cyrusRecipeReadMetadata_cf(Value** a,int n){check_arg_count(cyrusRecipeReadMetadata,1,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("recipe filename"));return recipeValue(r::read(std::filesystem::path(a[0]->to_string()),false));});}
def_visible_primitive(cyrusRecipeContentFingerprint,"cyrusRecipeContentFingerprint");
Value* cyrusRecipeContentFingerprint_cf(Value** a,int n){check_arg_count(cyrusRecipeContentFingerprint,1,n);return recipeAPI([&]()->Value*{return recipeString(r::contentFingerprint(recipeTree(a[0])));});}
def_visible_primitive(cyrusRecipePublicationFingerprint,"cyrusRecipePublicationFingerprint");
Value* cyrusRecipePublicationFingerprint_cf(Value** a,int n){check_arg_count(cyrusRecipePublicationFingerprint,1,n);return recipeAPI([&]()->Value*{
    type_check(a[0],Array,_T("published layer rows"));auto* groups=static_cast<Array*>(a[0]);if(groups->size>10)throw RuntimeError(_T("Capture supports at most ten layers"));
    struct Hash {
        BCRYPT_ALG_HANDLE algorithm=nullptr;BCRYPT_HASH_HANDLE hash=nullptr;
        ~Hash(){if(hash)BCryptDestroyHash(hash);if(algorithm)BCryptCloseAlgorithmProvider(algorithm,0);}
        void add(const std::string& bytes){if(BCryptHashData(hash,reinterpret_cast<PUCHAR>(const_cast<char*>(bytes.data())),static_cast<ULONG>(bytes.size()),0)<0)throw std::runtime_error("Capture fingerprint failed");}
    } hash;
    if(BCryptOpenAlgorithmProvider(&hash.algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)<0||BCryptCreateHash(hash.algorithm,&hash.hash,nullptr,0,nullptr,0,0)<0)throw std::runtime_error("Capture fingerprint provider unavailable");
    hash.add("cyrus-published-rows-v1[");std::size_t count=0;
    for(int g=0;g<groups->size;++g){
        if(cyrusIsPlacementValue(groups->data[g])) {
            const auto& view=cyrusPlacementView(groups->data[g]);count+=view.size();if(count>1000000)throw RuntimeError(_T("Capture exceeds one million published rows"));
            hash.add("[");
            for(std::size_t i=0;i<view.size();++i) {
                const auto& p=view.at(i);auto matrix=r::Json::array();for(float component:p.transform)matrix.push_back(component);
                const auto identity=view.stage()==cyrus::placements::Stage::Candidates?r::Json(static_cast<std::int64_t>(p.identity)):r::Json(view.textIdentity(i));
                hash.add(r::Json::array({matrix,p.source,identity,p.face,r::Json::array({p.bary[0],p.bary[1],p.bary[2]}),static_cast<std::int64_t>(p.band),(p.flags&cyrus::placements::Protected)!=0,2}).dump());hash.add(",");
            }
            hash.add("]");continue;
        }
        type_check(groups->data[g],Array,_T("published rows"));auto* rows=static_cast<Array*>(groups->data[g]);count+=rows->size;if(count>1000000)throw RuntimeError(_T("Capture exceeds one million published rows"));
        hash.add("[");for(int i=0;i<rows->size;++i){
            type_check(rows->data[i],Array,_T("published row"));auto* row=static_cast<Array*>(rows->data[i]);if(row->size!=8)throw RuntimeError(_T("Capture requires complete eight-field rows"));
            type_check(row->data[0],Matrix3Value,_T("published transform"));const Matrix3& transform=row->data[0]->to_matrix3();
            auto vector=[](const Point3& v){if(!std::isfinite(v.x)||!std::isfinite(v.y)||!std::isfinite(v.z))throw RuntimeError(_T("Nonfinite capture transform"));return r::Json::array({v.x,v.y,v.z});};
            auto matrix=r::Json::array();for(int j=0;j<4;++j)for(const auto& component:vector(transform.GetRow(j)))matrix.push_back(component);
            for(int field:{1,3,5,7})if(!cyrus::host::integerNumber(row->data[field]))throw RuntimeError(_T("Invalid capture row integer"));
            if(!is_string(row->data[2])&&!cyrus::host::integerNumber(row->data[2]))throw RuntimeError(_T("Invalid capture row identity"));
            if(row->data[6]!=&true_value&&row->data[6]!=&false_value)throw RuntimeError(_T("Invalid capture row flag"));
            type_check(row->data[4],Point3Value,_T("published anchor"));
            const auto identity=is_string(row->data[2])?r::Json(recipeUTF8(row->data[2],256)):recipeTree(row->data[2]);
            hash.add(r::Json::array({matrix,recipeTree(row->data[1]),identity,recipeTree(row->data[3]),vector(row->data[4]->to_point3()),recipeTree(row->data[5]),recipeTree(row->data[6]),recipeTree(row->data[7])}).dump());hash.add(",");
        }hash.add("]");
    }hash.add("]");std::vector<unsigned char> bytes(32);if(BCryptFinishHash(hash.hash,bytes.data(),32,0)<0)throw std::runtime_error("Capture fingerprint could not finish");return recipeString(r::hex(bytes));});}

namespace {
r::Json placementMetadata(Value* v,std::size_t& nodes,std::size_t& characters,int depth=0) {
    if(depth>8||nodes==0)throw RuntimeError(_T("Publication metadata exceeds bounded depth/values"));--nodes;
    if(is_string(v)){auto text=recipeUTF8(v,4096);if(text.size()>characters)throw RuntimeError(_T("Publication metadata text exceeds one MiB"));characters-=text.size();return text;}
    if(v==&undefined||v==&true_value||v==&false_value||cyrus::host::integerNumber(v)||cyrus::host::floatNumber(v))return recipeTree(v);
    type_check(v,Array,_T("frozen publication metadata"));auto* a=static_cast<Array*>(v);if(a->size>4096)throw RuntimeError(_T("Publication metadata array exceeds bounds"));
    auto json=r::Json::array();for(int i=0;i<a->size;++i)json.push_back(placementMetadata(a->data[i],nodes,characters,depth+1));return json;
}
}
// Explicit diagnostic: rows + frozen radii + frozen source/receiver correspondence
// and statistics. It never solves or creates per-placement script rows/pairs.
def_visible_primitive(cyrusPlacementPublicationFingerprint,"cyrusPlacementPublicationFingerprint");
Value* cyrusPlacementPublicationFingerprint_cf(Value** a,int n){check_arg_count(cyrusPlacementPublicationFingerprint,4,n);return recipeAPI([&]()->Value*{
    type_check(a[0],Array,_T("published populations"));type_check(a[1],Array,_T("published radii"));
    auto* groups=static_cast<Array*>(a[0]);auto* radii=static_cast<Array*>(a[1]);
    if(groups->size>10||groups->size!=radii->size)throw RuntimeError(_T("Publication populations and radii differ"));
    std::size_t nodes=20000,characters=1048576;const auto bindings=placementMetadata(a[2],nodes,characters),stats=placementMetadata(a[3],nodes,characters);
    one_typed_value_local(Value* rows);vl.rows=cyrusRecipePublicationFingerprint_cf(a,1);
    struct Hash {
        BCRYPT_ALG_HANDLE algorithm=nullptr;BCRYPT_HASH_HANDLE value=nullptr;
        ~Hash(){if(value)BCryptDestroyHash(value);if(algorithm)BCryptCloseAlgorithmProvider(algorithm,0);}
        void add(const std::string& text){if(BCryptHashData(value,reinterpret_cast<PUCHAR>(const_cast<char*>(text.data())),static_cast<ULONG>(text.size()),0)<0)throw std::runtime_error("Publication fingerprint failed");}
    } hash;
    if(BCryptOpenAlgorithmProvider(&hash.algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)<0||BCryptCreateHash(hash.algorithm,&hash.value,nullptr,0,nullptr,0,0)<0)throw std::runtime_error("Publication fingerprint provider unavailable");
    hash.add("cyrus-publication-v2[");hash.add(r::Json::array({recipeUTF8(vl.rows,64),bindings,stats}).dump());hash.add("[");
    for(int g=0;g<groups->size;++g) {
        std::size_t size=0;
        if(cyrusIsPlacementValue(groups->data[g]))size=cyrusPlacementView(groups->data[g]).size();
        else {type_check(groups->data[g],Array,_T("published rows"));size=static_cast<Array*>(groups->data[g])->size;}
        if(cyrusRadiusCount(radii->data[g])!=size)throw RuntimeError(_T("Published radii do not match the frozen population"));
        hash.add("[");for(std::size_t i=0;i<size;++i){const auto pair=cyrusRadiusAt(radii->data[g],i);hash.add(r::Json::array({pair[0],pair[1]}).dump());hash.add(",");}hash.add("]");
    }
    hash.add("]]");std::vector<unsigned char> bytes(32);if(BCryptFinishHash(hash.value,bytes.data(),32,0)<0)throw std::runtime_error("Publication fingerprint could not finish");return_value(recipeString(r::hex(bytes)));
});}
def_visible_primitive(cyrusRecipeEntryWrite,"cyrusRecipeEntryWrite");
Value* cyrusRecipeEntryWrite_cf(Value** a,int n){check_arg_count(cyrusRecipeEntryWrite,7,n);return recipeAPI([&]()->Value*{
    type_check(a[0],String,_T("recipe filename"));type_check(a[3],String,_T("thumbnail filename"));
    if(a[6]!=&true_value&&a[6]!=&false_value)throw RuntimeError(_T("Metadata-only requires Boolean"));
    return recipeString(r::writeEntry(std::filesystem::path(a[0]->to_string()),recipeTree(a[1]),recipeTree(a[2]),std::filesystem::path(a[3]->to_string()),recipeTree(a[4]),recipeUTF8(a[5],64),a[6]==&true_value));});}
def_visible_primitive(cyrusRecipeInfo,"cyrusRecipeInfo");
Value* cyrusRecipeInfo_cf(Value** a,int n){check_arg_count(cyrusRecipeInfo,1,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("recipe filename"));return recipeValue(r::summary(std::filesystem::path(a[0]->to_string())));});}

namespace {
// Destroy the worker before Max unloads DLLs; joining a thread from a static
// destructor under the Windows loader lock can deadlock its thread teardown.
r::Library* libraryValue=nullptr;
bool libraryShuttingDown=false;
void libraryShutdown(void*,NotifyInfo*) {
    libraryShuttingDown=true;delete libraryValue;libraryValue=nullptr;delete packageTask;packageTask=nullptr;
}
r::Library& recipeLibrary(){
    if(libraryShuttingDown)throw std::runtime_error("The library is shutting down.");
    if(!libraryValue){
        auto value=std::make_unique<r::Library>();
        if(!RegisterNotification(libraryShutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN))throw std::runtime_error("Cannot register library shutdown.");
        libraryValue=value.release();
    }
    return *libraryValue;
}
}
void cyrusRecipeLibraryShutdown(){
    libraryShutdown(nullptr,nullptr);
    UnRegisterNotification(libraryShutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN);
}
#ifndef CYRUS_TEAM_LICENSE
extern "C" __declspec(dllexport) int LibShutdown(){cyrusRecipeLibraryShutdown();return TRUE;}
#endif
def_visible_primitive(cyrusRecipeLibraryVersion,"cyrusRecipeLibraryVersion");
Value* cyrusRecipeLibraryVersion_cf(Value**,int n){check_arg_count(cyrusRecipeLibraryVersion,0,n);return Integer::intern(4);}
def_visible_primitive(cyrusRecipeLibraryStart,"cyrusRecipeLibraryStart");
Value* cyrusRecipeLibraryStart_cf(Value** a,int n){check_arg_count(cyrusRecipeLibraryStart,1,n);return recipeAPI([&]()->Value*{
    type_check(a[0],Array,_T("library folders"));auto* rows=static_cast<Array*>(a[0]);if(rows->size<1||rows->size>4)throw RuntimeError(_T("Choose one to four library folders"));
    std::vector<std::filesystem::path> paths;for(int i=0;i<rows->size;++i){type_check(rows->data[i],String,_T("library folder"));paths.emplace_back(rows->data[i]->to_string());}
    return Integer64::intern(recipeLibrary().start(std::move(paths)));});}
def_visible_primitive(cyrusRecipeLibraryPage,"cyrusRecipeLibraryPage");
Value* cyrusRecipeLibraryPage_cf(Value** a,int n){check_arg_count(cyrusRecipeLibraryPage,4,n);return recipeAPI([&]()->Value*{
    return recipeValue(recipeLibrary().page(a[0]->to_int64(),recipeUTF8(a[1],1024),recipeUTF8(a[2],96),a[3]->to_int()));});}
def_visible_primitive(cyrusRecipeLibraryCancel,"cyrusRecipeLibraryCancel");
Value* cyrusRecipeLibraryCancel_cf(Value** a,int n){check_arg_count(cyrusRecipeLibraryCancel,1,n);return recipeAPI([&]()->Value*{recipeLibrary().cancel(a[0]->to_int64());return &ok;});}
def_visible_primitive(cyrusRecipeLibraryUpdate,"cyrusRecipeLibraryUpdate");
Value* cyrusRecipeLibraryUpdate_cf(Value** a,int n){check_arg_count(cyrusRecipeLibraryUpdate,2,n);return recipeAPI([&]()->Value*{type_check(a[1],String,_T("recipe filename"));recipeLibrary().update(a[0]->to_int64(),std::filesystem::path(a[1]->to_string()));return &ok;});}
def_visible_primitive(cyrusRecipePresentationWrite,"cyrusRecipePresentationWrite");
Value* cyrusRecipePresentationWrite_cf(Value** a,int n){check_arg_count(cyrusRecipePresentationWrite,3,n);return recipeAPI([&]()->Value*{
    type_check(a[0],String,_T("recipe filename"));type_check(a[2],String,_T("thumbnail filename"));r::writePresentation(std::filesystem::path(a[0]->to_string()),recipeTree(a[1]),std::filesystem::path(a[2]->to_string()));return &ok;});}
def_visible_primitive(cyrusRecipeThumbnail,"cyrusRecipeThumbnail");
Value* cyrusRecipeThumbnail_cf(Value** a,int n){check_arg_count(cyrusRecipeThumbnail,1,n);return recipeAPI([&]()->Value*{
    type_check(a[0],String,_T("recipe filename"));return new String(r::thumbnail(std::filesystem::path(a[0]->to_string())).c_str());});}

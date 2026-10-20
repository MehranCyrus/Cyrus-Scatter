#include "arrange_document.h"
#include "preview_service.h"
#include "path_capture.h"
#include "cyrus_arrange/placement_queries.h"
#include "cyrus_arrange/receiving_mesh.h"
#include "cyrus_arrange/fit_feedback.h"
#include "cyrus_arrange/contact_base.h"
#include "cyrus_arrange/geometry_cache.h"
#include <triobj.h>
#include <stdmat.h>
#include <MeshNormalSpec.h>
#include <units.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <algorithm>
#include <cmath>
#include <chrono>
#include <limits>
#include <filesystem>
#include <map>
#include <memory>
#include <random>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>
#include <maxscript/macros/define_instantiation_functions.h>

namespace {
namespace ca=cyrus::arrange;
namespace host=ca::host;
namespace cache=ca::cache;
// Reuse validated same-time geometry; fresh assets and solving remain mandatory.
// This transient diagnostic switch is never saved or restored by Undo.
bool geometry_reuse_enabled=true;
std::uint64_t command_sequence{};
struct CommandRecord {
    host::Document& doc;
    cache::CommandMetrics metrics;
    std::chrono::steady_clock::time_point started{std::chrono::steady_clock::now()};
    CommandRecord(host::Document& value,cache::Operation operation):doc(value) {
        metrics.operation=operation;
        if(command_sequence<std::numeric_limits<std::uint64_t>::max())++command_sequence;
        metrics.command_sequence=command_sequence;
    }
    ~CommandRecord() noexcept {
        const auto elapsed=std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now()-started).count();
        metrics.nanoseconds[static_cast<std::size_t>(cache::Phase::Total)]=elapsed>0?static_cast<std::uint64_t>(elapsed):0;
        doc.record_cache_command(metrics);
    }
};
constexpr double arrange_pi=3.14159265358979323846;
std::wstring wide(const std::string& s){if(s.empty())return {};const int n=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s.data(),static_cast<int>(s.size()),nullptr,0);if(n<=0)throw std::runtime_error("Invalid UTF-8 text.");std::wstring out(n,L'\0');MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s.data(),static_cast<int>(s.size()),out.data(),n);return out;}
std::string utf8(const wchar_t* s){const int len=static_cast<int>(wcslen(s)),n=WideCharToMultiByte(CP_UTF8,0,s,len,nullptr,0,nullptr,nullptr);std::string out(n,'\0');WideCharToMultiByte(CP_UTF8,0,s,len,out.data(),n,nullptr,nullptr);return out;}
template<class F>Value* api(F&& f){try{const auto hwnd=GetCOREInterface()->GetMAXHWnd();if(!hwnd||GetWindowThreadProcessId(hwnd,nullptr)!=GetCurrentThreadId())throw std::runtime_error("Arrange commands require the Max main thread.");return f();}catch(const std::exception& e){throw RuntimeError(wide(e.what()).c_str());}}
ca::Vec3 add(ca::Vec3 a,ca::Vec3 b){return {a.x+b.x,a.y+b.y,a.z+b.z};}
ca::Vec3 sub(ca::Vec3 a,ca::Vec3 b){return {a.x-b.x,a.y-b.y,a.z-b.z};}
ca::Vec3 mul(ca::Vec3 a,double s){return {a.x*s,a.y*s,a.z*s};}
ca::Vec3 vec(Point3 p){return {p.x,p.y,p.z};}
Point3 point(ca::Vec3 p){if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z)||std::max({std::abs(p.x),std::abs(p.y),std::abs(p.z)})>1e9)throw std::runtime_error("Arrange coordinate exceeds Max precision admission.");return {static_cast<float>(p.x),static_cast<float>(p.y),static_cast<float>(p.z)};}
double unit_mm(){const double s=GetSystemUnitScale(UNITS_MILLIMETERS);if(!std::isfinite(s)||s<=0)throw std::runtime_error("Invalid system units.");return s;}
Array* array(Value* v,const wchar_t* label){if(!is_array(v))throw std::runtime_error(utf8(label)+" must be an array.");return static_cast<Array*>(v);}
host::Document& document(Value* v){return *host::get_document(v->to_node());}
struct ArrangeHold {
    bool done{};
    ArrangeHold(){theHold.Begin();}
    ~ArrangeHold(){if(!done)theHold.Cancel();}
    void accept(const wchar_t* label){theHold.Accept(label);done=true;}
    void cancel(){if(!done){done=true;theHold.Cancel();}}
};
struct UpdatingGuard {
    host::Document& doc;
    explicit UpdatingGuard(host::Document& value) noexcept:doc(value){doc.set_updating(true);}
    ~UpdatingGuard() noexcept {doc.set_updating(false);}
};
bool generated(INode* node){BOOL value=FALSE;return node->GetUserPropBool(_T("CyrusArrangeGenerated"),value)&&value;}
std::vector<INode*> expand(const std::vector<INode*>& roots){
    std::vector<INode*> pending=roots,out;std::set<ULONG> visited;
    while(!pending.empty()){auto* n=pending.back();pending.pop_back();if(!n)throw std::runtime_error("A source node has been deleted; repair source bindings before Update.");if(!visited.insert(n->GetHandle()).second)continue;
        if(visited.size()>4096)throw std::runtime_error("Assembly exceeds 4096 nodes.");if(generated(n))throw std::runtime_error("Managed Arrange output cannot be used as a source.");
        if(n->IsGroupHead()){if(n->NumberOfChildren()>4096-static_cast<int>(pending.size()))throw std::runtime_error("Group expansion exceeds 4096 nodes.");for(int i=0;i<n->NumberOfChildren();++i)pending.push_back(n->GetChildNode(i));}else out.push_back(n);
    }std::sort(out.begin(),out.end(),[](auto* a,auto* b){return a->GetHandle()<b->GetHandle();});if(out.empty())throw std::runtime_error("Choose evaluated mesh source geometry.");return out;
}
std::vector<INode*> normalize_roots(std::vector<INode*> out){
    if(out.empty()||out.size()>4096)throw std::runtime_error("Choose 1..4096 nodes.");expand(out);
    const std::set<INode*> selected(out.begin(),out.end());
    out.erase(std::remove_if(out.begin(),out.end(),[&](INode* node){std::size_t depth=0;for(auto* parent=node->GetParentNode();parent;parent=parent->GetParentNode()){if(++depth>4096)throw std::runtime_error("Source hierarchy exceeds depth admission.");if(parent->IsGroupHead()&&selected.contains(parent))return true;}return false;}),out.end());
    std::sort(out.begin(),out.end(),[](auto* x,auto* y){return x->GetHandle()<y->GetHandle();});out.erase(std::unique(out.begin(),out.end()),out.end());return out;
}
std::vector<INode*> nodes(Value* v){
    const auto* a=array(v,L"Source nodes");if(a->size<1||a->size>4096)throw std::runtime_error("Choose 1..4096 nodes.");
    std::vector<INode*> out;for(int i=0;i<a->size;++i)out.push_back(a->data[i]->to_node());return normalize_roots(std::move(out));
}
void validate_receiver_types(const std::vector<INode*>& roots) {
    const auto time=GetCOREInterface()->GetTime();
    for(auto* node:expand(roots)) {
        auto* object=node->EvalWorldState(time).obj;
        if(!object||object->SuperClassID()!=GEOMOBJECT_CLASS_ID||!object->CanConvertToType(triObjectClassID))
            throw std::runtime_error("Choose receiving mesh geometry or groups of mesh geometry.");
    }
}
ca::Mesh capture_mesh(INode* n,ca::Vec3 origin,double unit,TimeValue t,Interval& validity,std::size_t vertex_limit=3000000,std::size_t triangle_limit=1000000){
    // Explicit final-pipeline frame: query before borrowing evaluated objects
    // or mesh data, since transform evaluation may invalidate those caches.
    Interval tm_valid=FOREVER;const auto tm=n->GetObjTMAfterWSM(t,&tm_valid);const auto a=vec(tm.GetRow(0)),b=vec(tm.GetRow(1)),c=vec(tm.GetRow(2)),d=vec(tm.GetRow(3));
    const double det=a.x*(b.y*c.z-b.z*c.y)-a.y*(b.x*c.z-b.z*c.x)+a.z*(b.x*c.y-b.y*c.x);
    if(!std::isfinite(det)||std::abs(det)<1e-12)throw std::runtime_error("Source has a singular transform.");
    validity&=tm_valid;
    auto state=n->EvalWorldState(t);auto* obj=state.obj;
    if(!obj||obj->SuperClassID()!=GEOMOBJECT_CLASS_ID||!obj->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw std::runtime_error("Source is not convertible triangle geometry: "+utf8(n->GetName()));
    validity&=obj->ObjectValidity(t);
    auto* tri=static_cast<TriObject*>(obj->ConvertToType(t,Class_ID(TRIOBJ_CLASS_ID,0)));if(!tri)throw std::runtime_error("Source mesh conversion failed.");
    const auto release=[obj](TriObject* p){if(p&&p!=obj)p->DeleteThis();};std::unique_ptr<TriObject,decltype(release)> owned(tri,release);const auto& mesh=tri->GetMesh();
    if(mesh.numVerts<=0||mesh.numFaces<=0||static_cast<std::size_t>(mesh.numFaces)>triangle_limit||static_cast<std::size_t>(mesh.numVerts)>vertex_limit)throw std::runtime_error("Source exceeds mesh admission or is empty.");
    ca::Mesh out;out.vertices.reserve(mesh.numVerts);out.triangles.reserve(mesh.numFaces);
    for(int i=0;i<mesh.numVerts;++i){const auto p=vec(mesh.verts[i]);auto world=mul(add(add(add(mul(a,p.x),mul(b,p.y)),mul(c,p.z)),d),unit);out.vertices.push_back(sub(world,origin));}
    for(int i=0;i<mesh.numFaces;++i){const auto& f=mesh.faces[i];for(int k=0;k<3;++k)if(f.v[k]>=static_cast<DWORD>(mesh.numVerts))throw std::runtime_error("Source face index is invalid.");out.triangles.push_back({{f.v[0],f.v[det<0?2:1],f.v[det<0?1:2]}});}
    return out;
}
void append_mesh(ca::Mesh& target,const ca::Mesh& source){if(source.triangles.size()>1000000-target.triangles.size()||source.vertices.size()>3000000-target.vertices.size())throw std::runtime_error("Combined source exceeds mesh admission.");const auto base=static_cast<std::uint32_t>(target.vertices.size());target.vertices.insert(target.vertices.end(),source.vertices.begin(),source.vertices.end());for(auto f:source.triangles){for(auto& v:f.vertices)v+=base;target.triangles.push_back(f);}}
ca::Asset prepare_support(ca::Asset metadata,host::AssetCapturePolicy policy){
    const auto bounds=ca::mesh_bounds(metadata.mesh);
    if(!policy.authored_contact){
        auto base=ca::infer_contact_base(metadata.mesh);
        if(base.kind==ca::ContactBaseKind::NoReferencedContact)throw std::runtime_error("The source's lowest geometry has no triangle contact. Remove unused lower vertices or repair its base.");
        metadata.anchor=base.anchor;metadata.contact_footprint=std::move(base.footprint);
    }
    if(!policy.authored_stack){
        metadata.stack_footprint.clear();
        if(metadata.stackable){if(metadata.category!=ca::AssetCategory::Book&&metadata.category!=ca::AssetCategory::BookStack)throw std::runtime_error("Automatic stack-top capture currently supports books/book stacks; other assets need an authored top patch.");metadata.stack_height_mm=bounds.max.z-metadata.anchor.z;metadata.allowed_on_top=ca::asset_bit(ca::AssetCategory::Book)|ca::asset_bit(ca::AssetCategory::BookStack);const double z=bounds.max.z;metadata.stack_footprint={{bounds.min.x,bounds.min.y,z},{bounds.max.x,bounds.min.y,z},{bounds.max.x,bounds.max.y,z},{bounds.min.x,bounds.max.y,z}};}
        else{metadata.stack_height_mm=0;metadata.allowed_on_top=0;}
    }
    auto prepared=ca::prepare_asset(std::move(metadata));
    if(prepared.stackable){
        ca::QuerySettings checks;checks.require_front_access=false;
        const std::vector<ca::FurnitureBody> body{{1,prepared.mesh}};
        const ca::FurniturePlacementQuery top_query(body,checks);
        ca::Bounds b{prepared.stack_footprint.front(),prepared.stack_footprint.front()};for(auto v:prepared.stack_footprint){b.min.x=std::min(b.min.x,v.x);b.min.y=std::min(b.min.y,v.y);b.max.x=std::max(b.max.x,v.x);b.max.y=std::max(b.max.y,v.y);}const double z=prepared.anchor.z+prepared.stack_height_mm;
        const ca::OrientedBox thin{{(b.min.x+b.max.x)/2,(b.min.y+b.max.y)/2,z+0.05},{(b.max.x-b.min.x)/2,(b.max.y-b.min.y)/2,0.05},0};
        const ca::PlacementProbe probe{prepared.stack_footprint,thin,z,1,{},0,{},0,0,50000000};
        if(top_query.validate(probe).reason!=ca::Rejection::None)throw std::runtime_error("Automatic stacking requires a fully covered planar rectangular top. Disable stacking for this source or author a supported top patch.");
    }
    return prepared;
}
ca::Asset capture_asset(INode* source,ca::Asset metadata,TimeValue time,Interval& validity,host::AssetCapturePolicy policy={}){
    ca::Mesh mesh;const double unit=unit_mm();const auto expanded=expand({source});const auto origin=mul(vec(source->GetNodeTM(time).GetTrans()),unit);
    for(auto* node:expanded)append_mesh(mesh,capture_mesh(node,origin,unit,time,validity));
    const auto bounds=ca::mesh_bounds(mesh);const ca::Vec3 anchor{(bounds.min.x+bounds.max.x)/2,(bounds.min.y+bounds.max.y)/2,bounds.min.z};
    for(auto& vertex:mesh.vertices)vertex=sub(vertex,anchor);
    metadata.mesh=std::move(mesh);return prepare_support(std::move(metadata),policy);
}
constexpr std::size_t max_intake_nodes=4096,max_intake_work=4000000;
struct IntakeWork {
    std::size_t used{};
    void charge(std::size_t n=1){if(n>max_intake_work-used)throw std::runtime_error("Prop intake exceeds its bounded scene/hierarchy work.");used+=n;}
};
std::vector<INode*> intake_hierarchy(const std::vector<INode*>& roots,IntakeWork& work,bool copying=false){
    std::vector<INode*> pending=roots,result;std::set<ULONG> visited;
    while(!pending.empty()){
        auto* node=pending.back();pending.pop_back();work.charge();if(!node)throw std::runtime_error("A prop source was deleted during intake.");
        if(!visited.insert(node->GetHandle()).second)continue;
        if(visited.size()>max_intake_nodes)throw std::runtime_error("A prop source hierarchy exceeds 4096 nodes.");
        const int count=node->NumberOfChildren();
        if(count<0||static_cast<std::size_t>(count)>max_intake_nodes||pending.size()>max_intake_nodes-static_cast<std::size_t>(count))throw std::runtime_error("Prop hierarchy expansion exceeds 4096 pending nodes.");
        if(copying&&count&&!node->IsGroupHead())throw std::runtime_error("Props must be mesh models or complete Max groups; ungrouped parent/child hierarchies must be prepared as a Max group first.");
        result.push_back(node);for(int i=0;i<count;++i)pending.push_back(node->GetChildNode(i));
    }
    std::sort(result.begin(),result.end(),[](auto* a,auto* b){return a->GetHandle()<b->GetHandle();});return result;
}
std::vector<INode*> intake_roots(Value* input){
    auto result=nodes(input);if(result.size()>host::max_document_assets)throw std::runtime_error("Choose at most 256 separate prop models or group roots.");return result;
}
// Host-only, command-local observation. Its native references never enter the
// numeric cache or authored state. Attach after filling to avoid insertion noise.
class IntakeWatch final:public ReferenceMaker {
    struct Stamp {INode* node;INode* parent;bool group;Matrix3 node_tm,object_tm;std::vector<INode*> children;};
    RefTargetHandle reference_{};std::vector<Stamp> stamps_;bool armed_{},changed_{},closing_{};TimeValue time_;std::uint32_t first_message_{};std::uint64_t first_part_{};
    static bool relevant(PartID part,RefMessage message)noexcept{
        if(message==REFMSG_CHANGE){const PartID passive=PART_SELECT|PART_SUBSEL_TYPE|PART_DISPLAY|PART_HIDESTATE;return !part||(part&~passive)!=0;}
        return message==REFMSG_NODE_LINK||message==REFMSG_TARGET_DELETED||message==REFMSG_CONTAINER_ELEMENT_NULLED||message==REFMSG_CONTAINER_ELEMENT_ADDED||message==REFMSG_CONTAINER_ELEMENT_REMOVED||message==REFMSG_CONTAINER_ELEMENT_SET;
    }
    static bool same_matrix(const Matrix3& a,const Matrix3& b){for(int r=0;r<4;++r)for(int c=0;c<3;++c)if(a.GetRow(r)[c]!=b.GetRow(r)[c])return false;return true;}
public:
    explicit IntakeWatch(const std::vector<INode*>& members,TimeValue time):time_(time){
        HoldSuspend silent;
        auto* created=IRefTargContainer::CreateInstance();if(!created)throw std::runtime_error("Cannot retain prop intake sources.");
        SingleRefMaker staging;staging.SetRef(created);
        try{
            for(auto* node:members){const int index=created->GetNumItems();created->AppendItem(node);if(created->GetItem(index)!=node)throw std::runtime_error("A prop source disappeared during intake observation.");}
            if(ReplaceReference(0,created)!=REF_SUCCEED)throw std::runtime_error("Cannot observe prop intake sources.");
            stamps_.reserve(members.size());
            for(std::size_t i=0;i<members.size();++i){
                auto* node=dynamic_cast<INode*>(created->GetItem(static_cast<int>(i)));if(node!=members[i])throw std::runtime_error("A prop source disappeared while starting intake.");
                Stamp stamp{node,node->GetParentNode(),node->IsGroupHead()!=FALSE,node->GetNodeTM(time),node->GetObjTMAfterWSM(time),{}};
                const int count=node->NumberOfChildren();if(count<0||count>static_cast<int>(max_intake_nodes))throw std::runtime_error("Prop hierarchy changed beyond admission.");
                for(int child=0;child<count;++child)stamp.children.push_back(node->GetChildNode(child));stamps_.push_back(std::move(stamp));
            }
            armed_=true;
        }catch(...){closing_=true;DeleteAllRefsFromMe();throw;}
    }
    ~IntakeWatch()override{closing_=true;HoldSuspend silent;DeleteAllRefsFromMe();}
    int NumRefs()override{return 1;}
    RefTargetHandle GetReference(int i)override{return i==0?reference_:nullptr;}
    void SetReference(int i,RefTargetHandle value)override{if(i==0)reference_=value;}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID& part,RefMessage message,BOOL)override{if(armed_&&!closing_&&relevant(part,message)){if(!changed_){first_message_=message;first_part_=part;}changed_=true;}return REF_SUCCEED;}
    std::string diagnostic()const{return " [source message="+std::to_string(first_message_)+" part="+std::to_string(first_part_)+"]";}
    bool intact(){
        if(changed_||!reference_)return false;auto* container=static_cast<IRefTargContainer*>(reference_->GetInterface(IID_IREFTARG_CONTAINER));
        if(!container||container->GetNumItems()!=static_cast<int>(stamps_.size()))return false;
        for(std::size_t i=0;i<stamps_.size();++i){const auto& stamp=stamps_[i];if(container->GetItem(static_cast<int>(i))!=stamp.node)return false;auto* node=stamp.node;
            if(node->GetParentNode()!=stamp.parent||(node->IsGroupHead()!=FALSE)!=stamp.group||node->NumberOfChildren()!=static_cast<int>(stamp.children.size()))return false;
            for(std::size_t child=0;child<stamp.children.size();++child)if(node->GetChildNode(static_cast<int>(child))!=stamp.children[child])return false;
            if(!same_matrix(stamp.node_tm,node->GetNodeTM(time_))||!same_matrix(stamp.object_tm,node->GetObjTMAfterWSM(time_)))return false;
        }return !changed_;
    }
};
void validate_intake_sources(host::Document& target,const std::vector<INode*>& roots,IntakeWork& work){
    std::map<INode*,INode*> membership;
    auto* scene_root=GetCOREInterface()->GetRootNode();
    for(auto* root:roots){
        bool in_scene=false;std::size_t depth=0;
        for(auto* parent=root;parent;parent=parent->GetParentNode()){work.charge();if(++depth>max_intake_nodes)throw std::runtime_error("Prop ancestry exceeds 4096 levels.");if(parent==scene_root){in_scene=true;break;}}
        if(!in_scene||root==scene_root)throw std::runtime_error("Choose original current-scene prop models.");
        for(auto* node:intake_hierarchy({root},work)){
            if(generated(node))throw std::runtime_error("Managed Arrange output cannot be registered or copied as a prop source.");
            if(node->TestForLoop(FOREVER,&target)!=REF_SUCCEED)throw std::runtime_error("Prop source references would create an Arrange dependency cycle.");
            if(!membership.emplace(node,root).second)throw std::runtime_error("Selected prop models overlap; choose their outer groups or independent models.");
            if(membership.size()>max_intake_nodes)throw std::runtime_error("Combined prop intake exceeds 4096 nodes.");
        }
    }
    for(const auto& row:host::scene_setups(std::span<INode* const>{})){
        auto* doc=host::get_document(row.owner);SingleRefMaker lifetime;lifetime.SetRef(doc);const auto bindings=doc->bindings();
        const auto reject_role=[&](INode* role){if(!role)return;for(auto* node:intake_hierarchy({role},work))if(membership.contains(node))throw std::runtime_error("A prop source contains or overlaps an Arrange setup, furniture, obstacle or managed output. Choose independent original decor.");};
        reject_role(row.owner);for(const auto* roles:{&bindings.furniture,&bindings.obstacles,&bindings.outputs,&bindings.paths})for(auto* node:*roles)reject_role(node);
        for(auto* source:bindings.assets){if(!source)continue;for(auto* node:intake_hierarchy({source},work))if(const auto found=membership.find(node);found!=membership.end()&&found->second!=source)
            throw std::runtime_error("Prop source partially overlaps an existing asset group. Select the same complete source root or an independent copy.");}
    }
}
struct IntakeTotals {
    std::size_t vertices{},triangles{};
    explicit IntakeTotals(const host::DocumentState& state){for(const auto& asset:state.assets.read()){vertices+=asset.mesh.vertices.size();triangles+=asset.mesh.triangles.size();}}
    void add(const ca::Asset& asset){const ca::AssetLimits limits;if(asset.mesh.vertices.size()>limits.max_total_vertices-vertices||asset.mesh.triangles.size()>limits.max_total_triangles-triangles)throw std::runtime_error("Prop intake exceeds the setup's total geometry budget.");vertices+=asset.mesh.vertices.size();triangles+=asset.mesh.triangles.size();}
};
ca::Asset capture_intake_asset(const std::vector<INode*>& roots,ca::Asset asset,TimeValue time,const IntakeTotals& totals){
    const ca::AssetLimits limits;const auto vertices=std::min(limits.max_vertices_per_asset,limits.max_total_vertices-totals.vertices),triangles=std::min(limits.max_triangles_per_asset,limits.max_total_triangles-totals.triangles);
    ca::Mesh mesh;Interval validity=FOREVER;const double unit=unit_mm();const auto origin=mul(vec(roots.front()->GetNodeTM(time).GetTrans()),unit);
    for(auto* node:expand(roots)){auto part=capture_mesh(node,origin,unit,time,validity,vertices-mesh.vertices.size(),triangles-mesh.triangles.size());append_mesh(mesh,part);}
    const auto bounds=ca::mesh_bounds(mesh);const ca::Vec3 anchor{(bounds.min.x+bounds.max.x)/2,(bounds.min.y+bounds.max.y)/2,bounds.min.z};for(auto& vertex:mesh.vertices)vertex=sub(vertex,anchor);
    asset.mesh=std::move(mesh);return prepare_support(std::move(asset),{});
}
ca::Asset intake_metadata(std::uint64_t id,INode* source,ca::AssetCategory category){ca::Asset asset;asset.id=id;asset.name=utf8(source->GetName());asset.category=category;return asset;}
ca::AssetCategory intake_category(Value* value){const int category=value->to_int();if(category<1||category>static_cast<int>(ca::AssetCategory::Count))throw std::runtime_error("Choose a prop category.");return static_cast<ca::AssetCategory>(category-1);}
void validate_intake_context(host::Document& doc,INode* owner,const std::shared_ptr<const host::DocumentState>& expected,const host::CommandDependencyTicket& dependencies,TimeValue time,double unit,IntakeWatch& watch){
    host::flush_dependency_events();
    if(doc.state()!=expected||doc.owner()!=owner||host::get_document(owner,false)!=&doc||GetCOREInterface()->GetTime()!=time||unit_mm()!=unit||!doc.dependencies_unchanged(dependencies)||!watch.intact())throw std::runtime_error("Prop inputs or arrangement changed during intake; previous catalog and output retained."+watch.diagnostic());
}
// CloneNodes' raw result tables are not references. Find each returned pointer
// in the current scene before dereferencing it, then retain it through rollback.
std::vector<std::unique_ptr<SingleRefMaker>> pin_intake_scene_nodes(const std::vector<INode*>& requested,IntakeWork& work){
    std::set<INode*> remaining;for(auto* node:requested)if(!node||!remaining.insert(node).second)throw std::runtime_error("Decor copy returned missing or duplicate nodes.");
    struct Pending {INode* identity;AnimHandle handle;};
    auto* root=GetCOREInterface()->GetRootNode();std::vector<Pending> pending{{root,Animatable::GetHandleByAnim(root)}};
    std::vector<std::unique_ptr<SingleRefMaker>> retained;retained.reserve(requested.size());
    while(!pending.empty()&&!remaining.empty()){
        const auto item=pending.back();pending.pop_back();work.charge();auto* node=dynamic_cast<INode*>(Animatable::GetAnimByHandle(item.handle));if(!node||node!=item.identity)continue;
        if(remaining.erase(node)){auto pin=std::make_unique<SingleRefMaker>();pin->SetRef(node);if(pin->GetRef()!=node)throw std::runtime_error("A decor copy was deleted while retaining its lifetime.");retained.push_back(std::move(pin));}
        const int count=node->NumberOfChildren();if(count<0||static_cast<std::size_t>(count)>max_intake_work-work.used||pending.size()>max_intake_work-static_cast<std::size_t>(count))throw std::runtime_error("Decor copy scene lookup exceeds admission.");
        for(int i=0;i<count;++i){auto* child=node->GetChildNode(i);if(child)pending.push_back({child,Animatable::GetHandleByAnim(child)});}
    }
    if(!remaining.empty())throw std::runtime_error("A decor copy disappeared from the scene; no prop group was registered.");for(const auto& pin:retained)if(!pin->GetRef())throw std::runtime_error("A retained decor copy disappeared during scene lookup.");return retained;
}
void validate_copied_pose(INode* original,INode* copied,TimeValue time,double unit){
    const auto before=original->GetNodeTM(time),after=copied->GetNodeTM(time);
    for(int row=0;row<3;++row)for(int column=0;column<3;++column)if(std::abs(before.GetRow(row)[column]-after.GetRow(row)[column])>0.00001f)throw std::runtime_error("Decor copying changed a component's rotation or scale.");
    if(Length(before.GetTrans()-after.GetTrans())*unit>0.01)throw std::runtime_error("Decor copying moved a component by more than 0.01 mm.");
}
std::size_t asset_index(const host::DocumentState& state,Value* value){const auto id=static_cast<std::uint64_t>(value->to_int64());for(std::size_t i=0;i<state.assets.size();++i)if(state.assets[i].id==id)return i;throw std::runtime_error("Unknown asset ID.");}
std::vector<double> read_yaws(Value* value){const auto* rows=array(value,L"Allowed rotations");if(rows->size<1||rows->size>64)throw std::runtime_error("Specify 1..64 rotations.");std::vector<double> result;for(int i=0;i<rows->size;++i)result.push_back(rows->data[i]->to_double());return result;}
std::vector<ca::Vec3> read_points(Value* value){const auto* rows=array(value,L"Footprint points");if(rows->size>64)throw std::runtime_error("Footprints allow at most 64 points.");std::vector<ca::Vec3> result;for(int i=0;i<rows->size;++i)result.push_back(vec(rows->data[i]->to_point3()));return result;}
Value* point_rows(std::span<const ca::Vec3> points){one_typed_value_local(Array* out);vl.out=new Array(static_cast<int>(points.size()));for(auto p:points)vl.out->append(new Point3Value(point(p)));return_value(vl.out);}
Value* policy_rows(const host::AssetCapturePolicy& p){one_typed_value_local(Array* out);vl.out=new Array(2);vl.out->append(p.authored_contact?&true_value:&false_value);vl.out->append(p.authored_stack?&true_value:&false_value);return_value(vl.out);}
Value* setting_rows(const host::DocumentState& state){one_typed_value_local(Array* out);vl.out=new Array(11);const auto& s=state.arrangement;vl.out->append(Integer64::intern(static_cast<INT64>(s.seed)));for(auto d:{s.density,s.spacing_mm,s.edge_clearance_mm,s.cluster_strength,s.height_variation,s.empty_space})vl.out->append(Double::intern(d));vl.out->append(Integer::intern(static_cast<int>(s.style)+1));vl.out->append(Integer::intern(static_cast<int>(s.category)+1));vl.out->append(Double::intern(state.inspection.cell_size_mm));vl.out->append(state.live?&true_value:&false_value);return_value(vl.out);}
struct StagedArrangeSettings {
    ca::ArrangeSettings arrangement;
    double cell_size_mm{};
    bool live{};
    bool automatic_sampling{};
    bool ordinary_geometry{};
    std::optional<host::PathLayout> path_override;
    std::optional<std::vector<ca::AssetMinimum>> minimum_override;
    std::optional<bool> front_access_override;
};
StagedArrangeSettings read_arrange_settings(Value* value,const host::DocumentState& state,bool nonnegative_seed=false){
    auto* a=array(value,L"Settings");if(a->size!=11)throw std::runtime_error("Expected 11 arrangement settings.");
    const auto seed=a->data[0]->to_int64();if(nonnegative_seed&&seed<0)throw std::runtime_error("Variation seed must be a nonnegative Integer64 value.");
    StagedArrangeSettings out{state.arrangement,a->data[9]->to_double(),a->data[10]->to_bool()!=FALSE};auto& s=out.arrangement;
    s.seed=static_cast<std::uint64_t>(seed);s.density=a->data[1]->to_double();s.spacing_mm=a->data[2]->to_double();s.edge_clearance_mm=a->data[3]->to_double();s.cluster_strength=a->data[4]->to_double();s.height_variation=a->data[5]->to_double();s.empty_space=a->data[6]->to_double();s.style=static_cast<ca::ArrangeStyle>(a->data[7]->to_int()-1);s.category=static_cast<ca::FurnitureCategory>(a->data[8]->to_int()-1);
    return out;
}
void apply_arrange_settings(host::DocumentState& state,const StagedArrangeSettings& value){
    state.arrangement=value.arrangement;state.inspection.cell_size_mm=value.cell_size_mm;state.live=value.live;
    // Current Modify commands choose geometry placement in this same successor.
    // Keep old groups/poses for protected closure; raw legacy APIs stay explicit.
    if(value.ordinary_geometry)state.composition.book_rows=false;
    if(value.path_override)state.path=value.path_override;
    if(value.minimum_override)state.minimums=*value.minimum_override;
    if(value.front_access_override)state.require_front_access=*value.front_access_override;
    if(state.path){state.path->lanes[0].quantity=state.arrangement.quantity;state.path->settings.amount=state.arrangement.amount_mode==ca::AmountMode::Quantity?ca::PathAmount::Quantity:ca::PathAmount::Spacing;}
}
std::uint64_t fresh_seed(std::uint64_t supplied,std::uint64_t previous){
    // Two bounded draws; not a cryptographic or placement-uniqueness claim.
    std::random_device random;constexpr auto mask=static_cast<std::uint64_t>(std::numeric_limits<INT64>::max());
    std::uint64_t seed=((static_cast<std::uint64_t>(static_cast<std::uint32_t>(random()))<<32)|static_cast<std::uint32_t>(random()))&mask;
    // There are at most two forbidden values. Incrementing twice (with wrap)
    // therefore finds a new nonnegative saved/displayable seed without retries.
    for(int i=0;i<2&&(seed==supplied||seed==previous);++i)seed=(seed+1)&mask;
    return seed;
}
void capture_visual(INode* source,const ca::Asset& asset,TimeValue time,double unit,::Mesh& output,SingleRefMaker& material_lifetime){
    // Only copies are edited. Preserve map channels, face IDs, smoothing and
    // authored normals while flattening a source group into its asset frame.
    // SDK CombineMaterials records raw temporary Multi* in SetSubRestore.
    // Intermediate material graphs are staging, not authored scene edits; their
    // lifetime ends before Undo. Only publication's node.SetMtl is undoable.
    HoldSuspend staging_without_undo;
    const auto sources=expand({source});std::size_t vertex_base=0;bool first=true;
    for(auto* node:sources){
        // Match numeric capture for mirrored winding and explicit normals.
        // Resolve the post-WSM frame before acquiring pipeline object pointers.
        const auto tm=node->GetObjTMAfterWSM(time);auto* object=node->EvalWorldState(time).obj;
        if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw std::runtime_error("Visual source changed during capture.");
        auto* converted=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));if(!converted)throw std::runtime_error("Cannot capture visual source mesh.");
        const auto release=[object](TriObject* p){if(p&&p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(release)> owned(converted,release);
        ::Mesh part=converted->GetMesh();if(part.numVerts<0||static_cast<std::size_t>(part.numVerts)>asset.mesh.vertices.size()-vertex_base)throw std::runtime_error("Source topology changed between numeric and visual capture.");
        for(int i=0;i<part.numVerts;++i)part.setVert(i,point(mul(sub(asset.mesh.vertices[vertex_base+i],asset.anchor),1/unit)));
        vertex_base+=part.numVerts;
        const auto a=tm.GetRow(0),b=tm.GetRow(1),c=tm.GetRow(2);const bool mirrored=DotProd(a,CrossProd(b,c))<0;
        auto* normals=part.GetSpecifiedNormals();
        if(mirrored)for(int i=0;i<part.numFaces;++i){
            const auto original_face=part.faces[i];
            const bool has_normals=normals&&i<normals->GetNumFaces();
            const auto original_normals=has_normals?normals->Face(i):MeshNormalFace{};
            part.FlipNormal(i);
            // Mesh::FlipNormal and MeshNormalFace::Flip use different corner
            // permutations in Max 2027. Follow the actual vertex permutation
            // so explicit IDs and per-corner specified flags stay attached.
            if(has_normals){
                bool used[3]{};
                for(int corner=0;corner<3;++corner){
                    int previous=0;
                    while(previous<3&&(used[previous]||original_face.v[previous]!=part.faces[i].v[corner]))++previous;
                    if(previous==3)throw std::runtime_error("Mirrored face changed its source vertex identities.");
                    used[previous]=true;
                    normals->Face(i).SetNormalID(corner,original_normals.GetNormalID(previous));
                    normals->Face(i).SetSpecified(corner,original_normals.GetSpecified(previous));
                }
            }
        }
        if(normals)normals->Transform(tm);
        SingleRefMaker part_material;Mtl* incoming=node->GetMtl();
        if(!incoming){auto* neutral=NewDefaultStdMat();const auto color=node->GetWireColor();neutral->SetDiffuse(Color(GetRValue(color)/255.0f,GetGValue(color)/255.0f,GetBValue(color)/255.0f),time);incoming=neutral;}
        part_material.SetRef(incoming);
        if(first){output=part;material_lifetime.SetRef(incoming);first=false;}
        else{
            auto* existing=static_cast<Mtl*>(material_lifetime.GetRef());
            if(existing!=incoming){FitMeshIDsToMaterial(output,existing);FitMeshIDsToMaterial(part,incoming);int offset=0;auto* combined=CombineMaterials(existing,incoming,offset);if(!combined)throw std::runtime_error("Cannot combine source materials.");material_lifetime.SetRef(combined);for(int i=0;i<part.numFaces;++i){const int id=part.faces[i].getMatID()+offset;if(id>65535)throw std::runtime_error("Group material IDs exceed 65535.");part.faces[i].setMatID(static_cast<MtlID>(id));}}
            ::Mesh merged;CombineMeshes(merged,output,part);output=merged;
        }
    }
    if(vertex_base!=asset.mesh.vertices.size()||static_cast<std::size_t>(output.numFaces)!=asset.mesh.triangles.size())throw std::runtime_error("Source topology changed during visual capture.");
    output.InvalidateGeomCache();output.InvalidateTopologyCache();
}
struct PreparedGeneration {
    std::shared_ptr<const host::DocumentState> original;
    std::shared_ptr<host::DocumentState> next;
    host::Bindings bindings;
    host::CommandDependencyTicket dependencies;
    cache::GeometryKey key;
    cache::CommandGeometry geometry;
    TimeValue time{};
    double unit{};
    Interval validity{FOREVER};
    ca::ArrangementResult result;
    std::shared_ptr<const ca::FitFeedback> feedback;
    std::optional<host::CapturedPath> path_input;
};
struct CapturedFurniture {
    std::vector<ca::FurnitureBody> bodies;
    ca::Result inspection; // Raw observation IDs; no authored policy/registry here.
    Interval validity{FOREVER};
};
cache::GeometryKey geometry_key(host::Document& doc,const host::DocumentState& state,const host::Bindings& bindings,TimeValue time,double unit) {
    cache::GeometryKey key;key.ticket=doc.geometry_ticket();key.time=time;key.mm_per_system_unit=unit;
    key.origin_mm={state.frame_origin_mm.x,state.frame_origin_mm.y,state.frame_origin_mm.z};
    key.inspection=cache::InspectionKey::from(state.inspection);
    ca::QuerySettings qs;qs.require_support=!state.path||!bindings.furniture.empty();qs.require_front_access=state.require_front_access&&qs.require_support;key.query=cache::QueryKey::from(qs);
    if(bindings.furniture.size()!=state.furniture_source_keys.size())throw std::runtime_error("Furniture source identities and bindings disagree.");
    for(std::size_t i=0;i<bindings.furniture.size();++i){auto* node=bindings.furniture[i];if(!node)throw std::runtime_error("A furniture source has been deleted.");key.roots.push_back({node->GetHandle(),state.furniture_source_keys[i],cache::ScopeRole::Furniture});}
    for(auto* node:bindings.obstacles){if(!node)throw std::runtime_error("An obstacle source has been deleted.");key.roots.push_back({node->GetHandle(),0,cache::ScopeRole::Obstacle});}
    if(bindings.furniture.empty()&&!state.path)throw std::runtime_error("Pick receiving geometry before Generate.");
    const auto furniture=bindings.furniture.empty()?std::vector<INode*>{}:expand(bindings.furniture);
    const auto obstacles=bindings.obstacles.empty()?std::vector<INode*>{}:expand(bindings.obstacles);
    if(obstacles.size()>4096-furniture.size())throw std::runtime_error("Combined furniture and obstacle scope exceeds 4096 geometry nodes.");
    std::set<ULONG> used;
    const auto append=[&](INode* node,cache::ScopeRole role){
        if(!used.insert(node->GetHandle()).second)throw std::runtime_error("Furniture and obstacle scopes overlap. Keep support furniture out of the independent obstacle list.");
        // Stamp exactly the evaluated frame used by numeric capture, including
        // its original validity interval. No relaxed hit/final-key comparison.
        Interval tm_valid=FOREVER;const auto tm=node->GetObjTMAfterWSM(time,&tm_valid);
        const auto a=tm.GetRow(0),b=tm.GetRow(1),c=tm.GetRow(2);
        const double determinant=static_cast<double>(a.x)*(static_cast<double>(b.y)*c.z-static_cast<double>(b.z)*c.y)-static_cast<double>(a.y)*(static_cast<double>(b.x)*c.z-static_cast<double>(b.z)*c.x)+static_cast<double>(a.z)*(static_cast<double>(b.x)*c.y-static_cast<double>(b.y)*c.x);
        if(!std::isfinite(determinant)||std::abs(determinant)<1e-12)throw std::runtime_error("Source has a singular transform.");
        auto* object=node->EvalWorldState(time).obj;
        if(!object||object->SuperClassID()!=GEOMOBJECT_CLASS_ID||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw std::runtime_error("Source is not convertible triangle geometry: "+utf8(node->GetName()));
        cache::NodeStamp stamp;stamp.handle=node->GetHandle();stamp.role=role;
        for(int row=0;row<4;++row){const auto value=tm.GetRow(row);stamp.object_tm[row*3]=value.x;stamp.object_tm[row*3+1]=value.y;stamp.object_tm[row*3+2]=value.z;}
        const auto id=object->ClassID();stamp.evaluated_class_id={id.PartA(),id.PartB()};stamp.evaluated_super_class=object->SuperClassID();
        const auto valid=object->ObjectValidity(time);stamp.object_validity={valid.Start(),valid.End()};stamp.transform_validity={tm_valid.Start(),tm_valid.End()};
        key.nodes.push_back(stamp);
    };
    for(auto* node:furniture)append(node,cache::ScopeRole::Furniture);
    for(auto* node:obstacles)append(node,cache::ScopeRole::Obstacle);
    return key;
}
std::string geometry_key_difference(const cache::GeometryKey& before,const cache::GeometryKey& after) {
    if(before.ticket!=after.ticket)return "dependency epoch";
    if(before.time!=after.time||before.mm_per_system_unit!=after.mm_per_system_unit)return "time or units";
    if(before.origin_mm!=after.origin_mm||before.inspection!=after.inspection||before.query!=after.query)return "geometry settings";
    if(before.roots!=after.roots||before.nodes.size()!=after.nodes.size())return "input scope";
    for(std::size_t i=0;i<before.nodes.size();++i) {
        const auto& a=before.nodes[i];const auto& b=after.nodes[i];
        const auto label="node "+std::to_string(a.handle)+": ";
        if(a.handle!=b.handle||a.role!=b.role)return label+"scope role";
        if(a.object_tm!=b.object_tm)return label+"object transform";
        if(a.evaluated_class_id!=b.evaluated_class_id||a.evaluated_super_class!=b.evaluated_super_class)return label+"evaluated class";
        const auto interval=[](cache::TickInterval v){return "["+std::to_string(v.first)+","+std::to_string(v.last)+"]";};
        if(a.object_validity!=b.object_validity)return label+"object validity "+interval(a.object_validity)+" -> "+interval(b.object_validity);
        if(a.transform_validity!=b.transform_validity)return label+"transform validity "+interval(a.transform_validity)+" -> "+interval(b.transform_validity);
    }
    return "unclassified key change";
}
CapturedFurniture capture_furniture(const host::DocumentState& next,const host::Bindings& bindings,TimeValue time,double unit,Interval& validity,cache::CommandMetrics* metrics=nullptr){
    CapturedFurniture captured;ca::Mesh soup;std::size_t vertices=0,triangles=0;
    const auto capture=[&]{for(auto* node:expand(bindings.furniture)){
        auto mesh=capture_mesh(node,next.frame_origin_mm,unit,time,captured.validity,next.inspection.max_triangles*3-vertices,next.inspection.max_triangles-triangles);
        vertices+=mesh.vertices.size();triangles+=mesh.triangles.size();
        captured.bodies.push_back({node->GetHandle(),std::move(mesh)});
    }};
    if(metrics){cache::ScopedPhase phase(*metrics,cache::Phase::FurnitureCapture);capture();}else capture();
    validity&=captured.validity;
    const auto inspect=[&]{
        std::vector<ca::Mesh*> receiving;receiving.reserve(captured.bodies.size());for(auto& body:captured.bodies)receiving.push_back(&body.mesh);
        ca::ReceivingMeshLimits limits;limits.max_work=next.inspection.max_work;limits.max_triangles=next.inspection.max_triangles;
        const auto prepared=ca::prepare_receiving_meshes(receiving,limits);
        if(prepared.work>=next.inspection.max_work)throw std::runtime_error("Receiving preparation exhausted the inspection allowance; previous arrangement retained.");
        for(const auto& body:captured.bodies)append_mesh(soup,body.mesh);
        auto sampling=next.inspection;sampling.max_work-=prepared.work;captured.inspection=ca::inspect(soup,sampling);captured.inspection.work+=prepared.work;
        ca::append_receiving_warnings(captured.inspection,prepared);
    };
    if(metrics){cache::ScopedPhase phase(*metrics,cache::Phase::Inspect);inspect();}else inspect();
    return captured;
}
void bind_furniture_regions(host::Document& doc,host::DocumentState& next,ca::Result& inspection,const host::Bindings& bindings,TimeValue time,double unit){
    std::vector<ca::RegionObservation> observations;observations.reserve(inspection.regions.size());
    for(const auto& region:inspection.regions)observations.push_back({&region,next.furniture_source_keys});
    auto plan=ca::plan_regions(next.regions,observations);const auto count=plan.required_new_ids();
    const auto update=ca::finish_regions(std::move(plan),count?doc.reserve_ids(count):0);next.regions=update.registry;
    std::map<std::uint32_t,std::uint32_t> ids;for(auto binding:update.bindings)ids.emplace(binding.observed_id,binding.stable_id);
    for(auto& region:inspection.regions)region.id=ids.at(region.id);
    next.capture_time=time;next.captured_mm_per_system_unit=unit;next.furniture_count=bindings.furniture.size();
}
CapturedFurniture analyze_furniture(host::Document& doc,host::DocumentState& next,const host::Bindings& bindings,TimeValue time,double unit,Interval& validity,cache::CommandMetrics* metrics=nullptr){
    auto captured=capture_furniture(next,bindings,time,unit,validity,metrics);
    if(metrics){cache::ScopedPhase phase(*metrics,cache::Phase::RegistryBind);bind_furniture_regions(doc,next,captured.inspection,bindings,time,unit);}else bind_furniture_regions(doc,next,captured.inspection,bindings,time,unit);
    return captured;
}
std::vector<ca::FurnitureBody> capture_obstacles(const host::DocumentState& state,const host::Bindings& bindings,std::span<const ca::FurnitureBody> furniture,TimeValue time,double unit,Interval& validity){
    std::vector<ca::FurnitureBody> bodies;if(bindings.obstacles.empty())return bodies;
    std::set<std::uint64_t> used;std::size_t vertices=0,triangles=0;
    for(const auto& body:furniture){used.insert(body.id);vertices+=body.mesh.vertices.size();triangles+=body.mesh.triangles.size();}
    const auto expanded=expand(bindings.obstacles);
    if(expanded.size()>4096-furniture.size())throw std::runtime_error("Combined furniture and obstacle scope exceeds 4096 geometry nodes.");
    for(auto* node:expanded){
        if(!used.insert(node->GetHandle()).second)throw std::runtime_error("Furniture and obstacle scopes overlap. Keep support furniture out of the independent obstacle list.");
        auto mesh=capture_mesh(node,state.frame_origin_mm,unit,time,validity);
        if(mesh.vertices.size()>3000000-vertices||mesh.triangles.size()>1000000-triangles)throw std::runtime_error("Combined furniture and obstacle geometry exceeds the vertex/triangle admission.");
        vertices+=mesh.vertices.size();triangles+=mesh.triangles.size();bodies.push_back({node->GetHandle(),std::move(mesh)});
    }
    return bodies;
}
PreparedGeneration prepare_generation(host::Document& doc,std::span<const std::uint32_t> chosen,cache::CommandMetrics& metrics,std::shared_ptr<const ca::RegionRegistry> preview_regions={},const StagedArrangeSettings* settings_override=nullptr){
    PreparedGeneration staged;staged.original=doc.state();staged.dependencies=doc.dependency_ticket();staged.next=std::make_shared<host::DocumentState>(*staged.original);staged.bindings=doc.bindings();staged.time=GetCOREInterface()->GetTime();staged.unit=unit_mm();
    auto& next=staged.next;auto& bindings=staged.bindings;const auto time=staged.time;const auto unit=staged.unit;auto& validity=staged.validity;
    if(settings_override){apply_arrange_settings(*next,*settings_override);host::validate_document_state(*next);}
    if(preview_regions)next->regions=std::move(preview_regions);
    // Fresh source sizes are needed before choosing automatic sampling. Source
    // appearance/support remain outside the retained receiver geometry cache.
    {
        cache::ScopedPhase phase(metrics,cache::Phase::AssetRefresh);
        for(std::size_t i=0;i<next->assets.size();++i){
            if(bindings.assets[i])next->assets[i]=capture_asset(bindings.assets[i],std::move(next->assets[i]),time,validity,next->asset_capture[i]);
            else if(next->asset_capture[i].source_required)throw std::runtime_error("A registered prop source is missing. Rebind it or Undo its deletion.");
        }
    }
    if(next->path){
        if(!chosen.empty())throw std::runtime_error("Generate the complete path; surface-region selection does not apply to lanes.");
        if(bindings.paths.size()!=1||!bindings.paths[0])throw std::runtime_error("The path is missing. Pick a spline again or clear the path.");
        metrics.disposition=cache::Disposition::ColdNotRetained;metrics.reason=cache::Reason::Disabled;
        {cache::ScopedPhase phase(metrics,cache::Phase::LookupStamp);staged.key=geometry_key(doc,*next,bindings,time,unit);}
        {cache::ScopedPhase phase(metrics,cache::Phase::FurnitureCapture);staged.path_input=host::capture_path(bindings.paths[0],next->path->curve_index,next->frame_origin_mm,unit,time);}
        validity&=staged.path_input->validity;
        const auto curve=ca::PathCurve::build(staged.path_input->curves,staged.path_input->closed);
        std::vector<ca::FurnitureBody> supports;std::size_t vertices=0,triangles=0;
        if(!bindings.furniture.empty()){
            cache::ScopedPhase phase(metrics,cache::Phase::FurnitureCapture);
            for(auto* node:expand(bindings.furniture)){auto mesh=capture_mesh(node,next->frame_origin_mm,unit,time,validity,3000000-vertices,1000000-triangles);vertices+=mesh.vertices.size();triangles+=mesh.triangles.size();supports.push_back({node->GetHandle(),std::move(mesh)});}
        }
        std::vector<ca::FurnitureBody> obstacles;
        {cache::ScopedPhase phase(metrics,cache::Phase::ObstacleCapture);obstacles=capture_obstacles(*next,bindings,supports,time,unit,validity);}
        ca::QuerySettings query_settings;query_settings.require_support=!supports.empty();query_settings.require_front_access=next->require_front_access&&query_settings.require_support;
        std::unique_ptr<ca::FurniturePlacementQuery> physical;
        ca::ReceivingMeshPreparation prepared;
        {cache::ScopedPhase phase(metrics,cache::Phase::QueryBuild);
            std::vector<ca::Mesh*> receiving;receiving.reserve(supports.size());for(auto& body:supports)receiving.push_back(&body.mesh);
            ca::ReceivingMeshLimits limits;limits.max_work=query_settings.max_build_work;prepared=ca::prepare_receiving_meshes(receiving,limits);
            if(prepared.work>=query_settings.max_build_work)throw std::runtime_error("Receiving preparation exhausted the path query-build allowance; previous arrangement retained.");
            query_settings.max_build_work-=prepared.work;physical=std::make_unique<ca::FurniturePlacementQuery>(supports,query_settings,obstacles);
        }
        metrics.query_build_work_original=metrics.query_build_work_executed=prepared.work+physical->diagnostics().build_work;
        const auto& layout=*next->path;
        const ca::PathRequest request{curve,std::span<const ca::PathLane>(layout.lanes.data(),layout.lane_count),next->assets.read(),next->placements,{},physical.get(),next->minimums};
        {cache::ScopedPhase phase(metrics,cache::Phase::Solve);staged.result=ca::arrange_path(request,next->arrangement,layout.settings).result;}
        staged.feedback=std::make_shared<ca::FitFeedback>(std::move(staged.result.feedback));
        metrics.solver_work=staged.result.stats.work;next->capture_time=time;next->captured_mm_per_system_unit=unit;++next->revision;
        return staged;
    }
    if(settings_override&&settings_override->automatic_sampling) {
        // A protected pose and an explicit region scope own their accepted
        // sampled support identities. Automatic source-size changes must not
        // replace that lattice before current geometry can validate them.
        // Still recapture/reconcile/query below; changed geometry or policy
        // never gets a fallback/remap or a protected-fit exemption.
        const bool retain_sampling=!chosen.empty()||
            std::any_of(next->placements.begin(),next->placements.end(),[](const auto& p){return p.locked;})||
            std::any_of(next->regions->records.begin(),next->regions->records.end(),[](const auto& r){return ca::has_nondefault_region_semantics(r.semantics);});
        if(!retain_sampling) {
            const auto leaves=expand(bindings.furniture);Box3 bounds;bounds.Init();
            for(auto* node:leaves) {
                auto tm=node->GetObjTMAfterWSM(time);auto* object=node->EvalWorldState(time).obj;
                if(!object)throw std::runtime_error("A receiving object is missing.");
                Box3 local;object->GetDeformBBox(time,local,&tm);bounds+=local;
            }
            double feature=150;
            for(const auto& asset:next->assets) {
                const auto b=ca::contact_base_bounds(asset);const auto factor=(next->arrangement.random_scale||next->arrangement.fit_to_space)?next->arrangement.scale_min:1.0;
                feature=std::min(feature,std::min(b.max.x-b.min.x,b.max.y-b.min.y)*factor);
            }
            next->inspection.cell_size_mm=ca::automatic_cell_size({mul(vec(bounds.pmin),unit),mul(vec(bounds.pmax),unit)},feature,next->inspection.max_cells);
        }
        next->inspection.minimum_clearance_mm=1;
    }
    cache::GeometryCache* service=nullptr;
    {
        cache::ScopedPhase phase(metrics,cache::Phase::LookupStamp);
        staged.key=geometry_key(doc,*next,bindings,time,unit);
        if(geometry_reuse_enabled)service=host::ensure_geometry_cache();
        metrics.reason=geometry_reuse_enabled?cache::Reason::MetadataAllocation:cache::Reason::Disabled;
        if(service){auto lookup=service->lookup(staged.key);staged.geometry.lease=std::move(lookup.lease);metrics.reason=lookup.reason;}
        metrics.lookup_validated=bool(staged.geometry.lease);
    }
    std::optional<CapturedFurniture> cold;
    ca::Result bound;
    if(staged.geometry.lease){
        metrics.disposition=cache::Disposition::Hit;
        const auto& bundle=staged.geometry.get();validity&=Interval(bundle.validity.first,bundle.validity.last);
        cache::ScopedPhase phase(metrics,cache::Phase::RegistryBind);bound=bundle.raw;
    }else{
        cold=capture_furniture(*next,bindings,time,unit,validity,&metrics);
        metrics.inspection_work_executed=cold->inspection.work;
        cache::ScopedPhase phase(metrics,cache::Phase::RegistryBind);bound=cold->inspection;
    }
    {
        cache::ScopedPhase phase(metrics,cache::Phase::RegistryBind);
        bind_furniture_regions(doc,*next,bound,bindings,time,unit);
    }
    if(cold){
        // Cache validity is geometry-only, not the just-refreshed asset validity.
        Interval geometry_validity=cold->validity;
        for(const auto& node:staged.key.nodes){geometry_validity&=Interval(node.object_validity.first,node.object_validity.last);geometry_validity&=Interval(node.transform_validity.first,node.transform_validity.last);}
        std::vector<ca::FurnitureBody> obstacles;
        {cache::ScopedPhase phase(metrics,cache::Phase::ObstacleCapture);obstacles=capture_obstacles(*next,bindings,cold->bodies,time,unit,geometry_validity);}
        validity&=geometry_validity;
        ca::QuerySettings settings;settings.require_front_access=next->require_front_access;
        {
            cache::ScopedPhase phase(metrics,cache::Phase::QueryBuild);
            ca::FurniturePlacementQuery query(cold->bodies,settings,obstacles);
            const auto memory=query.retained_storage();
            const cache::QueryStorage storage{memory.accounted_bytes,memory.wrapper_bytes,query.diagnostics().triangles,memory.complete};
            metrics.query_build_work_executed=query.diagnostics().build_work;
            staged.geometry.cold.emplace(std::move(cold->inspection),std::move(query),storage,cache::TickInterval{geometry_validity.Start(),geometry_validity.End()});
        }
        cold.reset();
        // Never retain data if an input changed during capture/evaluation.
        {cache::ScopedPhase phase(metrics,cache::Phase::FinalValidate);
            host::flush_dependency_events();
            if(!doc.dependencies_unchanged(staged.dependencies))throw std::runtime_error("Arrange source notifications changed during geometry capture; previous result retained. "+doc.dependency_failure_detail(staged.dependencies));
            if(doc.state()!=staged.original)throw std::runtime_error("Arrange setup settings changed during geometry capture; previous result retained.");
            const auto current_key=geometry_key(doc,*next,bindings,time,unit);
            if(!doc.dependencies_unchanged(staged.dependencies)||doc.state()!=staged.original)throw std::runtime_error("Arrange inputs changed during geometry validation; previous result retained.");
            if(current_key!=staged.key)throw std::runtime_error("Arrange geometry changed during capture ("+geometry_key_difference(staged.key,current_key)+"); previous result retained.");
        }
        if(service){auto offered=service->offer(staged.key,staged.geometry.cold);staged.geometry.lease=std::move(offered.lease);if(!staged.geometry.lease){metrics.disposition=cache::Disposition::ColdNotRetained;metrics.reason=offered.reason;}}
        else metrics.disposition=cache::Disposition::ColdNotRetained;
    }
    const auto& geometry=staged.geometry.get();metrics.inspection_work_original=geometry.raw.work;metrics.query_build_work_original=geometry.query.diagnostics().build_work;
    std::vector<ca::RegionPlacementRule> policies;policies.reserve(next->regions->records.size());
    for(const auto& record:next->regions->records){const auto& s=record.semantics;policies.push_back({record.stable_id,s.allowed_asset_categories,s.density_multiplier,s.allow_stacking,s.excluded,s.front_direction});}
    const ca::ArrangementRequest request{bound.regions,next->assets,next->placements,{},chosen,next->category_rules[static_cast<std::size_t>(next->arrangement.category)],true,policies,next->composition,next->composition_groups,next->minimums};
    {cache::ScopedPhase phase(metrics,cache::Phase::Solve);staged.result=ca::arrange(request,next->arrangement,geometry.query);}
    staged.feedback=std::make_shared<ca::FitFeedback>(std::move(staged.result.feedback));
    metrics.solver_work=staged.result.stats.work;
    next->capture_time=time;next->captured_mm_per_system_unit=unit;next->furniture_count=bindings.furniture.size();++next->revision;
    return staged;
}
void validate_generation(host::Document& doc,const PreparedGeneration& staged,const std::shared_ptr<const host::DocumentState>& expected,INode* owner,cache::CommandMetrics& metrics){
    cache::ScopedPhase phase(metrics,cache::Phase::FinalValidate);
    host::flush_dependency_events();
    if(doc.state()!=expected||doc.owner()!=owner||GetCOREInterface()->GetTime()!=staged.time||unit_mm()!=staged.unit||!doc.dependencies_unchanged(staged.dependencies))throw std::runtime_error("Arrange inputs changed during generation; previous result retained.");
    const auto key=geometry_key(doc,*staged.next,staged.bindings,staged.time,staged.unit);
    if(key!=staged.key||!doc.dependencies_unchanged(staged.dependencies)||doc.state()!=expected)throw std::runtime_error("Arrange input scope or transform changed during generation; previous result retained.");
    if(staged.path_input){
        const auto current=host::capture_path(staged.bindings.paths.at(0),staged.next->path->curve_index,staged.next->frame_origin_mm,staged.unit,staged.time);
        host::flush_dependency_events();
        if(!host::same_path(*staged.path_input,current)||!doc.dependencies_unchanged(staged.dependencies)||doc.state()!=expected)throw std::runtime_error("Path changed during generation; previous settings and output retained.");
    }
}
Value* result_rows(const ca::ArrangementResult& result){two_typed_value_locals(Array* out,Array* warnings);vl.out=new Array(6);vl.warnings=new Array(static_cast<int>(result.warnings.size()));for(auto n:{result.stats.requested,result.stats.accepted,result.stats.kept,result.stats.candidates,result.stats.underfilled})vl.out->append(Integer64::intern(n));for(const auto& w:result.warnings)vl.warnings->append(new String(wide(w).c_str()));vl.out->append(vl.warnings);return_value(vl.out);}
std::vector<std::uint32_t> region_selection(Value* value){auto* list=array(value,L"Regions");if(list->size>4096)throw std::runtime_error("Too many regeneration regions.");std::vector<std::uint32_t> chosen;for(int i=0;i<list->size;++i){const auto id=list->data[i]->to_int64();if(id<1||id>4294967295LL)throw std::runtime_error("Region IDs must be positive.");chosen.push_back(static_cast<std::uint32_t>(id));}return chosen;}
ca::ArrangementResult generate(INode* owner,host::Document& doc,std::span<const std::uint32_t> chosen,std::shared_ptr<const ca::RegionRegistry> preview_regions={},cache::Operation operation=cache::Operation::Generate,const StagedArrangeSettings* settings_override=nullptr){
    SingleRefMaker document_lifetime;document_lifetime.SetRef(&doc);
    SingleRefMaker owner_lifetime;owner_lifetime.SetRef(owner);
    CommandRecord record(doc,operation);host::flush_dependency_events();host::DependencyCommandScope command(doc);
    auto staged_generation=prepare_generation(doc,chosen,record.metrics,std::move(preview_regions),settings_override);auto& next=staged_generation.next;auto& bindings=staged_generation.bindings;const auto time=staged_generation.time;const auto unit=staged_generation.unit;const auto validity=staged_generation.validity;auto& result=staged_generation.result;
    // Build one immutable scene mesh per used asset; output nodes instance it.
    struct TriDelete{void operator()(TriObject* p)const{if(p)p->DeleteThis();}};
    std::map<std::uint64_t,std::unique_ptr<TriObject,TriDelete>> templates;
    std::map<std::uint64_t,std::unique_ptr<SingleRefMaker>> materials;
    std::map<std::uint64_t,std::size_t> asset_indices;
    {cache::ScopedPhase phase(record.metrics,cache::Phase::VisualCapture);
    for(std::size_t i=0;i<next->assets.size();++i)asset_indices.emplace(next->assets[i].id,i);
    for(const auto& placement:result.placements){if(templates.contains(placement.asset_id))continue;const auto& asset=next->assets[asset_indices.at(placement.asset_id)];std::unique_ptr<TriObject,TriDelete> tri(CreateNewTriObject());if(!tri)throw std::runtime_error("Cannot allocate output mesh.");auto& mesh=tri->GetMesh();if(!mesh.setNumVerts(static_cast<int>(asset.mesh.vertices.size()))||!mesh.setNumFaces(static_cast<int>(asset.mesh.triangles.size())))throw std::runtime_error("Cannot allocate output mesh buffers.");
        for(std::size_t i=0;i<asset.mesh.vertices.size();++i)mesh.setVert(static_cast<int>(i),point(mul(sub(asset.mesh.vertices[i],asset.anchor),1/unit)));
        for(std::size_t i=0;i<asset.mesh.triangles.size();++i){const auto f=asset.mesh.triangles[i].vertices;mesh.faces[i].setVerts(f[0],f[1],f[2]);mesh.faces[i].setEdgeVisFlags(1,1,1);mesh.faces[i].setSmGroup(1);mesh.faces[i].setMatID(0);}
        auto material=std::make_unique<SingleRefMaker>();
        if(auto* source=bindings.assets[asset_indices.at(asset.id)])capture_visual(source,asset,time,unit,mesh,*material);
        mesh.InvalidateGeomCache();mesh.InvalidateTopologyCache();materials.emplace(asset.id,std::move(material));templates.emplace(asset.id,std::move(tri));
    }
    }
    next->placements=result.placements;next->composition_groups=result.groups;host::validate_document_state(*next);
    validate_generation(doc,staged_generation,staged_generation.original,owner,record.metrics);
    ArrangeHold hold;UpdatingGuard updating(doc);const auto previous=bindings.outputs;bindings.outputs.clear();std::map<std::uint64_t,TriObject*> scene_templates;auto* ip=GetCOREInterface();
    try{
        {cache::ScopedPhase phase(record.metrics,cache::Phase::Publish);
        for(const auto& placement:result.placements){auto& staged=templates.at(placement.asset_id);auto* object=staged?staged.get():scene_templates.at(placement.asset_id);auto* node=ip->CreateObjectNode(object);if(!node)throw std::runtime_error("Cannot create arrangement output node.");if(staged){scene_templates[placement.asset_id]=staged.release();}
            bindings.outputs.push_back(node);const auto index=asset_indices.at(placement.asset_id);const auto& asset=next->assets[index];const auto name=L"CA_"+wide(asset.name)+L"_"+std::to_wstring(placement.stable_id);node->SetName(name.c_str());
            Matrix3 tm(TRUE);const double r=std::remainder(placement.yaw_degrees,360.0)*arrange_pi/180,c=std::cos(r)*placement.scale,s=std::sin(r)*placement.scale;tm.SetRow(0,Point3(static_cast<float>(c),static_cast<float>(s),0.0f));tm.SetRow(1,Point3(static_cast<float>(-s),static_cast<float>(c),0.0f));tm.SetRow(2,Point3(0.0f,0.0f,static_cast<float>(placement.scale)));tm.SetTrans(point(mul(add(placement.position,next->frame_origin_mm),1/unit)));node->SetNodeTM(time,tm);
            node->SetUserPropBool(_T("CyrusArrangeGenerated"),TRUE);node->SetUserPropString(_T("CyrusArrangeOwner"),wide(next->document_id).c_str());node->SetUserPropString(_T("CyrusArrangePlacementID"),std::to_wstring(placement.stable_id).c_str());node->SetWireColor(RGB(70,170,150));node->SetMtl(static_cast<Mtl*>(materials.at(asset.id)->GetRef()));
        }
        }
        if(doc.owner()!=owner||owner_lifetime.GetRef()!=owner)throw std::runtime_error("Arrange setup was removed during generation; previous result retained.");
        validate_generation(doc,staged_generation,staged_generation.original,owner,record.metrics);
        {cache::ScopedPhase phase(record.metrics,cache::Phase::Publish);
        doc.commit(next,bindings,_T("Cyrus Arrange generate"),true);
        doc.set_updating(true);
        for(auto* old:previous)if(old)ip->DeleteNode(old,FALSE);
        }
        validate_generation(doc,staged_generation,next,owner,record.metrics);
        doc.mark_clean(time,validity);
        validate_generation(doc,staged_generation,next,owner,record.metrics);
        {cache::ScopedPhase phase(record.metrics,cache::Phase::Publish);hold.accept(_T("Cyrus Arrange generate"));record.metrics.published=true;}
    }catch(...){hold.cancel();doc.set_updating(false);throw;}
    doc.set_updating(false);
    // Acceptance already published the complete result. A viewport exception
    // cannot roll it back or truthfully turn it into a failed generation.
    try{ip->RedrawViews(time);}catch(...){try{doc.set_error("Arrangement generated, but viewport refresh failed.");}catch(...){}}
    host::clear_preview(doc);
    // After Accept, callback edits are new pending changes, not rollback-able
    // failures. Do not restore the stats cleared by such an edit.
    if(doc.dependencies_unchanged(staged_generation.dependencies)&&doc.state()==next){doc.record_composition_stats(result.composition_stats);doc.record_fit_feedback(std::move(staged_generation.feedback));}
    record.metrics.completed=true;return std::move(result);
}
void live_update(INode* owner,host::Document& doc){generate(owner,doc,{});}
}

void CyrusArrangeInitializeBridge(){host::set_live_update_callback(live_update);}
void CyrusArrangeShutdownBridge(){host::shutdown_preview();host::shutdown_geometry_cache();}

namespace {
const wchar_t* operation_name(cache::Operation op) noexcept {
    switch(op){case cache::Operation::Generate:return L"generate";case cache::Operation::Preview:return L"preview";case cache::Operation::CommitPreview:return L"commitPreview";case cache::Operation::Analyze:return L"analyze";default:return L"unknown";}
}
const wchar_t* disposition_name(cache::Disposition value) noexcept {
    switch(value){case cache::Disposition::Cold:return L"cold";case cache::Disposition::Hit:return L"hit";case cache::Disposition::ColdNotRetained:return L"coldNotRetained";default:return L"unknown";}
}
const wchar_t* cache_reason_name(cache::Reason value) noexcept {
    switch(value){case cache::Reason::None:return L"none";case cache::Reason::Empty:return L"empty";case cache::Reason::KeyChanged:return L"keyChanged";case cache::Reason::DependencyChanged:return L"dependencyChanged";case cache::Reason::TimeChanged:return L"timeChanged";case cache::Reason::UnitsChanged:return L"unitsChanged";case cache::Reason::SceneChanged:return L"sceneChanged";case cache::Reason::OwnerRemoved:return L"ownerRemoved";case cache::Reason::ExplicitClear:return L"explicitClear";case cache::Reason::Disabled:return L"disabled";case cache::Reason::InvalidKey:return L"invalidKey";case cache::Reason::AccountingUnavailable:return L"accountingUnavailable";case cache::Reason::TooLarge:return L"tooLarge";case cache::Reason::PinnedBudget:return L"pinnedBudget";case cache::Reason::MetadataAllocation:return L"metadataAllocation";default:return L"unknown";}
}
Value* footprint_rows(const cache::Footprint& value){one_typed_value_local(Array* out);vl.out=new Array(4);for(auto n:{value.entries,value.bytes,value.triangles,value.cells})vl.out->append(Integer64::intern(static_cast<INT64>(n)));return_value(vl.out);}
Value* cache_total_rows(const cache::CacheTotals& value){one_typed_value_local(Array* out);vl.out=new Array(8);
    vl.out->append(Integer64::intern(static_cast<INT64>(value.resident)));vl.out->append(Integer64::intern(static_cast<INT64>(value.retired_borrowed)));
    vl.out->append(footprint_rows(value.live));vl.out->append(footprint_rows(value.peak));
    for(auto n:{value.entry_metadata_requested_live_bytes,value.entry_metadata_requested_peak_bytes,value.fixed_service_inline_bytes,value.fixed_control_object_bytes})vl.out->append(Integer64::intern(static_cast<INT64>(n)));
    return_value(vl.out);
}
Value* cache_phase_rows(const std::optional<cache::CommandMetrics>& metrics){two_typed_value_locals(Array* out,Array* row);vl.out=new Array(static_cast<int>(cache::Phase::Count));
    constexpr std::array<const wchar_t*,static_cast<std::size_t>(cache::Phase::Count)> names{L"lookupStamp",L"furnitureCapture",L"inspect",L"registryBind",L"obstacleCapture",L"queryBuild",L"assetRefresh",L"solve",L"visualCapture",L"publish",L"finalValidate",L"total"};
    for(std::size_t i=0;i<names.size();++i){vl.row=new Array(2);vl.row->append(new String(names[i]));vl.row->append(Integer64::intern(static_cast<INT64>(metrics?metrics->nanoseconds[i]:0)));vl.out->append(vl.row);}return_value(vl.out);
}
}
def_visible_primitive(caGeometryCacheInfo,"caGeometryCacheInfo");
Value* caGeometryCacheInfo_cf(Value** args,int count){check_arg_count(caGeometryCacheInfo,1,count);return api([&]()->Value*{
    const auto metrics=document(args[0]).last_cache_command();const auto* service=host::geometry_cache();const auto totals=service?service->totals():cache::CacheTotals{};
    two_typed_value_locals(Array* out,Array* last);vl.out=new Array(5);vl.out->append(Integer::intern(1));vl.out->append(geometry_reuse_enabled&&totals.enabled?&true_value:&false_value);
    if(metrics){const auto& m=*metrics;vl.last=new Array(12);vl.last->append(new String(operation_name(m.operation)));vl.last->append(new String(disposition_name(m.disposition)));vl.last->append(new String(cache_reason_name(m.reason)));
        for(auto b:{m.completed,m.published,m.lookup_validated})vl.last->append(b?&true_value:&false_value);
        for(auto n:{m.inspection_work_original,m.inspection_work_executed,m.query_build_work_original,m.query_build_work_executed,m.solver_work,m.command_sequence})vl.last->append(Integer64::intern(static_cast<INT64>(n)));vl.out->append(vl.last);
    }else vl.out->append(&undefined);
    vl.out->append(cache_total_rows(totals));vl.out->append(cache_phase_rows(metrics));return_value(vl.out);
});}
def_visible_primitive(caGeometryDependencyInfo,"caGeometryDependencyInfo");
Value* caGeometryDependencyInfo_cf(Value** args,int count){check_arg_count(caGeometryDependencyInfo,1,count);return api([&]()->Value*{
    const auto ticket=document(args[0]).geometry_ticket();one_typed_value_local(Array* out);vl.out=new Array(5);vl.out->append(Integer::intern(1));
    for(auto n:{ticket.document_instance,ticket.scene,ticket.geometry})vl.out->append(Integer64::intern(static_cast<INT64>(n)));vl.out->append(ticket.valid()?&true_value:&false_value);return_value(vl.out);
});}
def_visible_primitive(caClearGeometryCache,"caClearGeometryCache");
Value* caClearGeometryCache_cf(Value** args,int count){check_arg_count(caClearGeometryCache,1,count);return api([&]()->Value*{const auto ticket=document(args[0]).geometry_ticket();if(auto* service=host::geometry_cache())service->clear_document(ticket.document_instance);return &true_value;});}
def_visible_primitive(caClearAllGeometryCaches,"caClearAllGeometryCaches");
Value* caClearAllGeometryCaches_cf(Value**,int count){check_arg_count(caClearAllGeometryCaches,0,count);return api([]()->Value*{if(auto* service=host::geometry_cache())service->clear_all();return &true_value;});}
def_visible_primitive(caGeometryCacheEnabled,"caGeometryCacheEnabled");
Value* caGeometryCacheEnabled_cf(Value**,int count){check_arg_count(caGeometryCacheEnabled,0,count);return api([]()->Value*{return geometry_reuse_enabled?&true_value:&false_value;});}
def_visible_primitive(caSetGeometryCacheEnabled,"caSetGeometryCacheEnabled");
Value* caSetGeometryCacheEnabled_cf(Value** args,int count){check_arg_count(caSetGeometryCacheEnabled,1,count);return api([&]()->Value*{const bool previous=geometry_reuse_enabled;geometry_reuse_enabled=args[0]->to_bool()!=FALSE;if(!geometry_reuse_enabled)if(auto* service=host::geometry_cache())service->clear_all();return previous?&true_value:&false_value;});}

def_visible_primitive(caBindReceivers,"caBindReceivers");
Value* caBindReceivers_cf(Value** args,int count){check_arg_count(caBindReceivers,2,count);return api([&]()->Value*{
    auto* owner=args[0]->to_node();auto roots=nodes(args[1]);const auto leaves=expand(roots);
    validate_receiver_types(roots);
    if(std::find(roots.begin(),roots.end(),owner)!=roots.end()||std::find(leaves.begin(),leaves.end(),owner)!=leaves.end())
        throw std::runtime_error("An arrangement icon cannot receive its own props.");
    SingleRefMaker owner_lifetime;owner_lifetime.SetRef(owner);
    ArrangeHold hold;auto& doc=*host::initialize_setup(owner);SingleRefMaker lifetime;lifetime.SetRef(&doc);
    auto bindings=doc.bindings();const std::set<INode*> receiving(leaves.begin(),leaves.end());
    for(const auto* role:{&bindings.assets,&bindings.obstacles,&bindings.paths}) {
        std::vector<INode*> existing;for(auto* node:*role)if(node)existing.push_back(node);
        if(!existing.empty())for(auto* node:expand(existing))if(receiving.contains(node))
            throw std::runtime_error("Receiving geometry overlaps registered props or independent obstacles. Choose separate objects.");
    }
    if(bindings.furniture==roots){hold.accept(_T("Cyrus Arrange receiving geometry"));return &true_value;}
    auto next=std::make_shared<host::DocumentState>(*doc.state());next->furniture_count=roots.size();next->furniture_source_keys.clear();
    const auto first=doc.reserve_ids(roots.size());for(std::size_t i=0;i<roots.size();++i)next->furniture_source_keys.push_back(first+i);
    // Old output remains visible until Generate. A fresh registry cannot inherit
    // overrides from an unrelated receiving assembly.
    next->regions=std::make_shared<ca::RegionRegistry>();bindings.furniture=std::move(roots);++next->revision;
    doc.commit(next,bindings,_T("Cyrus Arrange receiving geometry"));hold.accept(_T("Cyrus Arrange receiving geometry"));return &true_value;
});}

def_visible_primitive(caBindPath,"caBindPath");
def_visible_primitive(caIsSplinePath,"caIsSplinePath");
def_visible_primitive(caInputKind,"caInputKind");
Value* caInputKind_cf(Value** args,int count){check_arg_count(caInputKind,1,count);return api([&]()->Value*{auto* node=args[0]->to_node();if(node&&node->IsGroupHead())return Integer::intern(1);auto* object=node?node->EvalWorldState(GetCOREInterface()->GetTime()).obj:nullptr;return Integer::intern(object?(object->SuperClassID()==SHAPE_CLASS_ID?2:object->SuperClassID()==GEOMOBJECT_CLASS_ID?1:0):0);});}
Value* caIsSplinePath_cf(Value** args,int count){check_arg_count(caIsSplinePath,1,count);return api([&]()->Value*{auto* node=args[0]->to_node();auto* object=node?node->EvalWorldState(GetCOREInterface()->GetTime()).obj:nullptr;return object&&object->SuperClassID()==SHAPE_CLASS_ID?&true_value:&false_value;});}
Value* caBindPath_cf(Value** args,int count){check_arg_count(caBindPath,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto* owner=args[0]->to_node();auto* source=args[1]->to_node();const int index=args[2]->to_int();
    if(index<1||index>256||!source||source==owner||generated(source))throw std::runtime_error("Pick an original spline and a curve number in 1..256.");
    SingleRefMaker owner_lifetime,lifetime,source_lifetime;owner_lifetime.SetRef(owner);lifetime.SetRef(&doc);source_lifetime.SetRef(source);
    host::flush_dependency_events();host::DependencyCommandScope command(doc);const auto original=doc.state();const auto dependency=doc.dependency_ticket();const auto time=GetCOREInterface()->GetTime();const auto unit=unit_mm();
    IntakeWork work;bool in_scene=false;for(auto* p=source;p;p=p->GetParentNode()){work.charge();if(p==GetCOREInterface()->GetRootNode()){in_scene=true;break;}}
    if(!in_scene||source->TestForLoop(FOREVER,&doc)!=REF_SUCCEED)throw std::runtime_error("Path must be an independent current-scene spline.");
    IntakeWatch watch({source},time);auto bindings=doc.bindings();
    for(const auto* roots:{&bindings.furniture,&bindings.assets,&bindings.outputs,&bindings.obstacles})for(auto* root:*roots)if(root)for(auto* member:intake_hierarchy({root},work))if(member==source)throw std::runtime_error("The spline overlaps another arrangement role. Choose an independent path.");
    host::validate_path_node(source,static_cast<std::uint32_t>(index-1),time);
    validate_intake_context(doc,owner,original,dependency,time,unit,watch);
    auto next=std::make_shared<host::DocumentState>(*original);
    if(!next->path){next->path=host::PathLayout{};const auto first=doc.reserve_ids(2);if(first>=std::numeric_limits<std::uint32_t>::max())throw std::runtime_error("Path lane identity range is exhausted.");next->path->lanes[0].id=static_cast<std::uint32_t>(first);next->path->lanes[1].id=static_cast<std::uint32_t>(first+1);}
    next->path->curve_index=static_cast<std::uint32_t>(index-1);next->path->lanes[0].quantity=next->arrangement.quantity;next->path->settings.amount=next->arrangement.amount_mode==ca::AmountMode::Quantity?ca::PathAmount::Quantity:ca::PathAmount::Spacing;
    bindings.paths={source};++next->revision;host::validate_document_state(*next);
    ArrangeHold hold;UpdatingGuard updating(doc);
    try{validate_intake_context(doc,owner,original,dependency,time,unit,watch);doc.commit(next,bindings,_T("Cyrus Arrange path"));doc.set_updating(true);validate_intake_context(doc,owner,next,dependency,time,unit,watch);hold.accept(_T("Cyrus Arrange path"));}catch(...){hold.cancel();throw;}
    return &true_value;
});}
def_visible_primitive(caCreateArrangement,"caCreateArrangement");
Value* caCreateArrangement_cf(Value** args,int count){if(count!=0&&count!=1){check_arg_count(caCreateArrangement,1,count);}return api([&]()->Value*{
    auto roots=count?nodes(args[0]):std::vector<INode*>{};
    const auto time=GetCOREInterface()->GetTime();const auto unit=unit_mm();
    auto* input=roots.size()==1?roots.front()->EvalWorldState(time).obj:nullptr;
    const bool path=input&&input->SuperClassID()==SHAPE_CLASS_ID;
    if(count&&!path)validate_receiver_types(roots);
    IntakeWork work;std::unique_ptr<IntakeWatch> watch;
    if(count)watch=std::make_unique<IntakeWatch>(intake_hierarchy(roots,work),time);
    three_value_locals(out,source,index);vl.source=&undefined;vl.index=Integer::intern(1);
    if(count) {
        if(path)vl.source=MAXNode::intern(roots.front());
        else {
            // Do not re-read a caller-owned mutable script array after a
            // nodeCreated callback; bind the normalized command snapshot.
            auto* copied=new Array(static_cast<int>(roots.size()));vl.source=copied;
            for(auto* root:roots)copied->append(MAXNode::intern(root));
        }
    }
    ArrangeHold hold;auto* owner=host::create_setup();vl.out=MAXNode::intern(owner);
    SingleRefMaker owner_lifetime,document_lifetime;owner_lifetime.SetRef(owner);
    auto& doc=*host::get_document(owner);document_lifetime.SetRef(&doc);
    const auto intact=[&]{return owner_lifetime.GetRef()==owner&&host::get_document(owner,false)==&doc&&GetCOREInterface()->GetTime()==time&&unit_mm()==unit&&(!watch||watch->intact());};
    if(!intact())throw std::runtime_error("Creation context changed; no arrangement was kept.");
    if(count) {
        Value* binding_args[3]={vl.out,vl.source,vl.index};
        // Shared native admission/publication stays inside this outer hold;
        // RuntimeError and other exceptions unwind it and cancel the new icon.
        if(path)caBindPath_cf(binding_args,3);else caBindReceivers_cf(binding_args,2);
        if(!intact())throw std::runtime_error("Creation inputs changed while binding; no arrangement was kept.");
        const auto expected_state=doc.state();auto next=std::make_shared<host::DocumentState>(*expected_state);
        Matrix3 marker(TRUE);marker.SetTrans(roots.front()->GetNodeTM(time).GetTrans());
        owner->SetNodeTM(time,marker);next->frame_origin_mm=mul(vec(marker.GetTrans()),unit);
        if(!intact()||doc.state()!=expected_state)throw std::runtime_error("The arrangement changed while positioning its icon; no arrangement was kept.");
        doc.commit(next,doc.bindings(),_T("Create Cyrus Arrange"));
        if(!intact()||doc.state()!=next)throw std::runtime_error("Creation context changed before completion; no arrangement was kept.");
    }
    hold.accept(_T("Create Cyrus Arrange"));return_value(vl.out);
});}

def_visible_primitive(caClearPath,"caClearPath");
Value* caClearPath_cf(Value** args,int count){check_arg_count(caClearPath,1,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto next=std::make_shared<host::DocumentState>(*doc.state());if(!next->path)return &false_value;
    if(next->path->settings.amount==ca::PathAmount::Quantity){next->arrangement.quantity=0;for(std::size_t i=0;i<next->path->lane_count;++i)next->arrangement.quantity+=next->path->lanes[i].quantity;}
    else next->arrangement.quantity=std::max(ca::validate_asset_minimums(next->minimums,next->assets.read()),std::min(next->arrangement.max_placements,next->placements.empty()?next->arrangement.quantity:next->placements.size()));
    next->path.reset();auto bindings=doc.bindings();bindings.paths.clear();++next->revision;doc.commit(next,bindings,_T("Cyrus Arrange clear path"));return &true_value;
});}
namespace {
Value* path_setting_rows(const host::PathLayout& p){one_typed_value_local(Array* out);vl.out=new Array(19);
    vl.out->append(Integer::intern(p.curve_index+1));vl.out->append(Integer::intern(static_cast<int>(p.lane_count)));vl.out->append(p.settings.align?&true_value:&false_value);vl.out->append(Double::intern(p.settings.source_forward_degrees));vl.out->append(p.lanes[0].reverse?&true_value:&false_value);
    for(double value:{p.lanes[0].offset_mm,p.lanes[0].width_mm,p.lanes[0].center_spacing_mm})vl.out->append(Double::intern(value));vl.out->append(p.lanes[0].limit_width?&true_value:&false_value);
    vl.out->append(Integer::intern(static_cast<int>(p.lanes[1].quantity)));for(double value:{p.lanes[1].offset_mm,p.lanes[1].width_mm,p.lanes[1].center_spacing_mm})vl.out->append(Double::intern(value));vl.out->append(p.lanes[1].reverse?&true_value:&false_value);vl.out->append(p.lanes[1].limit_width?&true_value:&false_value);
    for(double value:{p.settings.start_inset_mm,p.settings.end_inset_mm,p.settings.lateral_jitter_mm,p.settings.longitudinal_jitter_mm})vl.out->append(Double::intern(value));return_value(vl.out);
}
host::PathLayout read_path_settings(Value* value,const host::DocumentState& state){
    if(!state.path)throw std::runtime_error("Pick a spline path first.");auto p=*state.path;auto* a=array(value,L"Path settings");if(a->size!=19)throw std::runtime_error("Expected nineteen path settings from the matching Modify view.");
    const int index=a->data[0]->to_int(),lanes=a->data[1]->to_int();if(index<1||index>256||lanes<1||lanes>2)throw std::runtime_error("Choose an existing curve and one or two lanes.");p.curve_index=index-1;p.lane_count=lanes;p.settings.align=a->data[2]->to_bool()!=FALSE;p.settings.source_forward_degrees=a->data[3]->to_double();p.lanes[0].reverse=a->data[4]->to_bool()!=FALSE;
    p.lanes[0].offset_mm=a->data[5]->to_double();p.lanes[0].width_mm=a->data[6]->to_double();p.lanes[0].center_spacing_mm=a->data[7]->to_double();p.lanes[0].limit_width=a->data[8]->to_bool()!=FALSE;
    const double right=a->data[9]->to_double();if(!std::isfinite(right)||right<0||right>10000||std::floor(right)!=right)throw std::runtime_error("Right lane quantity must be a bounded whole number.");p.lanes[1].quantity=static_cast<std::size_t>(right);
    p.lanes[1].offset_mm=a->data[10]->to_double();p.lanes[1].width_mm=a->data[11]->to_double();p.lanes[1].center_spacing_mm=a->data[12]->to_double();p.lanes[1].reverse=a->data[13]->to_bool()!=FALSE;p.lanes[1].limit_width=a->data[14]->to_bool()!=FALSE;
    p.settings.start_inset_mm=a->data[15]->to_double();p.settings.end_inset_mm=a->data[16]->to_double();p.settings.lateral_jitter_mm=a->data[17]->to_double();p.settings.longitudinal_jitter_mm=a->data[18]->to_double();
    validate_path_settings(p.settings);for(const auto& lane:p.lanes)validate_path_lane(lane);return p;
}
StagedArrangeSettings read_placement_settings(Value* value,const host::DocumentState& state,bool fresh){
    auto* values=array(value,L"Placement settings");if(values->size!=10)throw std::runtime_error("Expected ten native placement settings from the matching Modify view.");
    const auto seed=values->data[0]->to_int64();if(seed<0)throw std::runtime_error("Seed must be a nonnegative Integer64.");const auto mode=values->data[1]->to_int();if(mode<1||mode>2)throw std::runtime_error("Choose Fill/Spacing or Quantity.");
    const double quantity=values->data[2]->to_double();if(!std::isfinite(quantity)||quantity<0||quantity>host::max_document_placements||(mode==2&&quantity>state.arrangement.max_placements)||std::floor(quantity)!=quantity)throw std::runtime_error("Quantity must be a whole number within this arrangement's output limit.");
    StagedArrangeSettings settings{state.arrangement,state.inspection.cell_size_mm,state.live,true};auto& s=settings.arrangement;
    settings.ordinary_geometry=true;
    s.seed=static_cast<std::uint64_t>(seed);s.amount_mode=static_cast<ca::AmountMode>(mode-1);s.quantity=static_cast<std::size_t>(quantity);s.density=values->data[3]->to_double();s.spacing_mm=values->data[4]->to_double();s.edge_clearance_mm=values->data[5]->to_double();s.random_scale=values->data[6]->to_bool()!=FALSE;s.fit_to_space=values->data[7]->to_bool()!=FALSE;s.scale_min=values->data[8]->to_double();s.scale_max=values->data[9]->to_double();s.style=ca::ArrangeStyle::Balanced;s.cluster_strength=0;s.empty_space=0;if(fresh)s.seed=fresh_seed(s.seed,state.arrangement.seed);return settings;
}
}
namespace {
std::vector<ca::AssetMinimum> read_minimums(Value* value,const host::DocumentState& state){
    const auto* rows=array(value,L"Prop minimums");if(rows->size>256)throw std::runtime_error("Choose minimums for at most 256 registered props.");
    std::vector<ca::AssetMinimum> result;std::set<std::uint64_t> seen;
    for(int i=0;i<rows->size;++i){const auto* row=array(rows->data[i],L"Prop minimum");if(row->size!=2)throw std::runtime_error("A prop minimum requires its source ID and minimum copies.");
        const auto id=static_cast<std::uint64_t>(row->data[0]->to_int64());const double count=row->data[1]->to_double();
        if(!std::isfinite(count)||count<0||count>10000||std::floor(count)!=count||!seen.insert(id).second)throw std::runtime_error("Minimum copies must be whole counts in 0..10000 with unique source IDs.");
        const auto& assets=state.assets.read();if(std::none_of(assets.begin(),assets.end(),[&](const auto& a){return a.id==id;}))throw std::runtime_error("A minimum refers to a removed prop. Refresh the arrangement view.");
        if(count)result.push_back({id,static_cast<std::size_t>(count)});
    }
    ca::validate_asset_minimums(result,state.assets.read());std::sort(result.begin(),result.end(),[](auto a,auto b){return a.asset_id<b.asset_id;});return result;
}
}
namespace {
std::shared_ptr<const ca::FitFeedback> current_fit_feedback(host::Document& doc){
    host::flush_dependency_events();const auto value=doc.fit_feedback();const auto state=doc.state();
    if(GetCOREInterface()->GetTime()!=state->capture_time||unit_mm()!=state->captured_mm_per_system_unit)return {};
    return value;
}
const ca::FitReport* fit_report(const ca::FitFeedback& feedback,std::uint64_t id){
    const auto it=std::find_if(feedback.reports.begin(),feedback.reports.end(),[&](const auto& r){return r.asset_id==id;});return it==feedback.reports.end()?nullptr:&*it;
}
}
def_visible_primitive(caFitFeedback,"caFitFeedback");
Value* caFitFeedback_cf(Value** args,int count){check_arg_count(caFitFeedback,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto feedback=current_fit_feedback(doc);const auto id=static_cast<std::uint64_t>(args[1]->to_int64());const auto* r=feedback?fit_report(*feedback,id):nullptr;
    one_typed_value_local(Array* out);vl.out=new Array(13);vl.out->append(r?&true_value:&false_value);
    vl.out->append(new String(r?wide(ca::fit_report_message(*r)).c_str():L"Generate after changes to check this prop's fit."));
    vl.out->append(Integer::intern(r?static_cast<int>(r->issue):0));vl.out->append(Double::intern(r&&r->has_suggestion?r->suggested.scale:0));
    vl.out->append(r&&r->below_minimum?&true_value:&false_value);vl.out->append(r&&r->has_failure?&true_value:&false_value);vl.out->append(r&&r->has_suggestion?&true_value:&false_value);
    vl.out->append(Double::intern(r?r->allowed_minimum:0));vl.out->append(Double::intern(r&&r->has_failure?r->failed.scale:0));
    vl.out->append(Integer64::intern(r?r->failed.region_id:0));vl.out->append(Integer::intern(feedback?static_cast<int>(feedback->probes):0));vl.out->append(Integer64::intern(feedback?feedback->work:0));vl.out->append(Double::intern(r?r->apply_percent:0));return_value(vl.out);
});}
def_visible_primitive(caShowFitFeedback,"caShowFitFeedback");
Value* caShowFitFeedback_cf(Value** args,int count){check_arg_count(caShowFitFeedback,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto feedback=current_fit_feedback(doc);const auto id=static_cast<std::uint64_t>(args[1]->to_int64());const auto* r=feedback?fit_report(*feedback,id):nullptr;
    if(!r||!r->has_failure)throw std::runtime_error("Fit feedback is stale or has no checked location. Generate again.");
    const auto state=doc.state();const auto asset=std::find_if(state->assets.begin(),state->assets.end(),[&](const auto& a){return a.id==id;});if(asset==state->assets.end())throw std::runtime_error("The source prop changed. Generate again.");
    std::array<ca::OrientedBox,2> boxes;std::size_t n=0;
    const auto context=r->witness.has_bounds?std::optional<ca::Bounds>(r->witness.bounds):(r->has_space?std::optional<ca::Bounds>(r->sampled_space):std::nullopt);
    if(context)boxes[n++]={mul(add(context->min,context->max),.5),mul(sub(context->max,context->min),.5),0};
    boxes[n++]=ca::placement_bounds(*asset,r->has_suggestion?r->suggested:r->failed);
    for(std::size_t i=0;i<n;++i)boxes[i].center=add(boxes[i].center,state->frame_origin_mm);
    host::show_fit_highlight(doc,id,std::span<const ca::OrientedBox>(boxes.data(),n),r->has_suggestion);return Integer::intern(static_cast<int>(n));
});}
def_visible_primitive(caHideFitFeedback,"caHideFitFeedback");
Value* caHideFitFeedback_cf(Value** args,int count){check_arg_count(caHideFitFeedback,1,count);return api([&]()->Value*{return host::hide_fit_highlight(document(args[0]))?&true_value:&false_value;});}
def_visible_primitive(caFitHighlightInfo,"caFitHighlightInfo");
Value* caFitHighlightInfo_cf(Value** args,int count){check_arg_count(caFitHighlightInfo,1,count);return api([&]()->Value*{
    const auto info=host::fit_highlight_info(document(args[0]));three_typed_value_locals(Array* out,Array* boxes,Array* row);vl.out=new Array(7);vl.boxes=new Array(static_cast<int>(info.boxes.size()));
    for(const auto& box:info.boxes){vl.row=new Array(3);vl.row->append(new Point3Value(point(box.center)));vl.row->append(new Point3Value(point(box.half_extents)));vl.row->append(Double::intern(box.yaw_degrees));vl.boxes->append(vl.row);}
    vl.out->append(info.present?&true_value:&false_value);vl.out->append(info.valid?&true_value:&false_value);vl.out->append(Integer64::intern(static_cast<INT64>(info.asset_id)));vl.out->append(Integer::intern(static_cast<int>(info.boxes.size())));vl.out->append(info.suggestion?&true_value:&false_value);vl.out->append(Integer64::intern(static_cast<INT64>(info.draws)));vl.out->append(vl.boxes);return_value(vl.out);
});}
def_visible_primitive(caPropMinimums,"caPropMinimums");
Value* caPropMinimums_cf(Value** args,int count){check_arg_count(caPropMinimums,1,count);return api([&]()->Value*{
    const auto state=document(args[0]).state();two_typed_value_locals(Array* out,Array* row);vl.out=new Array(static_cast<int>(state->minimums.size()));
    for(const auto& m:state->minimums){vl.row=new Array(2);vl.row->append(Integer64::intern(static_cast<INT64>(m.asset_id)));vl.row->append(Integer::intern(static_cast<int>(m.quantity)));vl.out->append(vl.row);}return_value(vl.out);
});}
def_visible_primitive(caGeneratePlacementMinimums,"caGeneratePlacementMinimums");
Value* caGeneratePlacementMinimums_cf(Value** args,int count){if(count!=5){check_arg_count(caGeneratePlacementMinimums,4,count);}return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);try{auto settings=read_placement_settings(args[1],*doc.state(),args[3]->to_bool()!=FALSE);settings.minimum_override=read_minimums(args[2],*doc.state());if(count==5)settings.front_access_override=args[4]->to_bool()!=FALSE;return result_rows(generate(args[0]->to_node(),doc,{}, {},cache::Operation::Generate,&settings));}catch(const std::exception& e){doc.set_error(e.what());throw;}
});}
def_visible_primitive(caGeneratePathMinimums,"caGeneratePathMinimums");
Value* caGeneratePathMinimums_cf(Value** args,int count){if(count!=6){check_arg_count(caGeneratePathMinimums,5,count);}return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);try{auto settings=read_placement_settings(args[1],*doc.state(),args[4]->to_bool()!=FALSE);settings.path_override=read_path_settings(args[2],*doc.state());settings.minimum_override=read_minimums(args[3],*doc.state());if(count==6)settings.front_access_override=args[5]->to_bool()!=FALSE;return result_rows(generate(args[0]->to_node(),doc,{}, {},cache::Operation::Generate,&settings));}catch(const std::exception& e){doc.set_error(e.what());throw;}
});}

def_visible_primitive(caPathSettings,"caPathSettings");
Value* caPathSettings_cf(Value** args,int count){check_arg_count(caPathSettings,1,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto state=doc.state();if(!state->path)return &undefined;const auto bindings=doc.bindings();two_typed_value_locals(Array* out,Array* placed);vl.out=new Array(3);auto* node=bindings.paths.size()==1?bindings.paths[0]:nullptr;vl.out->append(node?MAXNode::intern(node):&undefined);vl.out->append(path_setting_rows(*state->path));vl.placed=new Array(2);
    for(const auto& lane:state->path->lanes){std::size_t count=0;for(const auto& p:state->placements)if(p.region_id==lane.id)++count;vl.placed->append(Integer::intern(static_cast<int>(count)));}vl.out->append(vl.placed);return_value(vl.out);
});}
def_visible_primitive(caGenerateAlongPath,"caGenerateAlongPath");
Value* caGenerateAlongPath_cf(Value** args,int count){check_arg_count(caGenerateAlongPath,4,count);return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);try{auto settings=read_placement_settings(args[1],*doc.state(),args[3]->to_bool()!=FALSE);settings.path_override=read_path_settings(args[2],*doc.state());return result_rows(generate(args[0]->to_node(),doc,{}, {},cache::Operation::Generate,&settings));}catch(const std::exception& e){doc.set_error(e.what());throw;}
});}

def_visible_primitive(caCreateSetup,"caCreateSetup");
Value* caCreateSetup_cf(Value** args,int count){check_arg_count(caCreateSetup,2,count);return api([&]()->Value*{
    auto sources=nodes(args[0]);const auto category=args[1]->to_int();if(category<1||category>static_cast<int>(ca::FurnitureCategory::Count))throw std::runtime_error("Choose a furniture category.");
    ArrangeHold hold;auto* setup=host::create_setup();auto& doc=*host::get_document(setup);auto next=std::make_shared<host::DocumentState>(*doc.state());
    next->arrangement.category=static_cast<ca::FurnitureCategory>(category-1);next->require_front_access=false;next->inspection.minimum_clearance_mm=1;next->inspection.maximum_slope_degrees=0;
    // This raw eleven-field density API retains Fill; artist creation uses
    // caCreateArrangement and keeps its Quantity default.
    next->arrangement.amount_mode=ca::AmountMode::Fill;
    const auto time=GetCOREInterface()->GetTime();Matrix3 marker(TRUE);marker.SetTrans(sources.front()->GetNodeTM(time).GetTrans());setup->SetNodeTM(time,marker);
    next->frame_origin_mm=mul(vec(marker.GetTrans()),unit_mm());next->furniture_count=sources.size();const auto source_base=doc.reserve_ids(sources.size());for(std::size_t i=0;i<sources.size();++i)next->furniture_source_keys.push_back(source_base+i);
    host::Bindings b;b.furniture=sources;doc.commit(next,b,_T("Cyrus Arrange setup"));one_value_local(out);vl.out=MAXNode::intern(setup);hold.accept(_T("Cyrus Arrange setup"));return_value(vl.out);
});}
def_visible_primitive(caSceneSetups,"caSceneSetups");
def_visible_primitive(caReceiverNodes,"caReceiverNodes");
Value* caReceiverNodes_cf(Value** args,int count){check_arg_count(caReceiverNodes,1,count);return api([&]()->Value*{
    const auto bindings=document(args[0]).bindings();one_typed_value_local(Array* out);vl.out=new Array(static_cast<int>(bindings.furniture.size()));
    for(auto* node:bindings.furniture)vl.out->append(node?MAXNode::intern(node):&undefined);return_value(vl.out);
});}
Value* caSceneSetups_cf(Value** args,int count){check_arg_count(caSceneSetups,1,count);return api([&]()->Value*{
    const auto* input=array(args[0],L"Selected nodes");if(input->size>4096)throw std::runtime_error("Setup discovery accepts at most 4096 selected nodes.");
    std::vector<INode*> selected;selected.reserve(input->size);for(int i=0;i<input->size;++i)selected.push_back(input->data[i]->to_node());
    const auto rows=host::scene_setups(selected);three_typed_value_locals(Array* out,Array* row,Array* furniture);vl.out=new Array(static_cast<int>(rows.size()));
    for(const auto& entry:rows){vl.row=new Array(3);vl.furniture=new Array(static_cast<int>(entry.furniture.size()));
        vl.row->append(MAXNode::intern(entry.owner));vl.row->append(entry.matched?&true_value:&false_value);
        for(auto* node:entry.furniture)vl.furniture->append(node?MAXNode::intern(node):&undefined);
        vl.row->append(vl.furniture);vl.out->append(vl.row);
    }return_value(vl.out);
});}
def_visible_primitive(caSetupSummary,"caSetupSummary");
Value* caSetupSummary_cf(Value** args,int count){check_arg_count(caSetupSummary,1,count);return api([&]()->Value*{auto& doc=document(args[0]);const auto s=doc.state();one_typed_value_local(Array* out);vl.out=new Array(9);vl.out->append(new String(wide(s->document_id).c_str()));vl.out->append(new String(wide(s->label).c_str()));vl.out->append(Integer64::intern(s->revision));vl.out->append(Integer::intern(static_cast<int>(s->assets.size())));vl.out->append(Integer::intern(static_cast<int>(s->placements.size())));vl.out->append(Integer::intern(doc.lifecycle().dirty));vl.out->append(s->live?&true_value:&false_value);vl.out->append(new String(wide(doc.lifecycle().error).c_str()));vl.out->append(setting_rows(*s));return_value(vl.out);});}
def_visible_primitive(caSetArrangeSettings,"caSetArrangeSettings");
Value* caSetArrangeSettings_cf(Value** args,int count){check_arg_count(caSetArrangeSettings,2,count);return api([&]()->Value*{auto& doc=document(args[0]);const auto settings=read_arrange_settings(args[1],*doc.state());auto next=std::make_shared<host::DocumentState>(*doc.state());apply_arrange_settings(*next,settings);++next->revision;doc.commit(next,doc.bindings(),_T("Cyrus Arrange settings"));return &true_value;});}
def_visible_primitive(caRegisterAsset,"caRegisterAsset");
Value* caRegisterAsset_cf(Value** args,int count){check_arg_count(caRegisterAsset,10,count);return api([&]()->Value*{auto& doc=document(args[0]);auto* source=args[1]->to_node();ca::Asset asset;asset.id=doc.reserve_ids(1);asset.name=utf8(args[2]->to_string());asset.category=static_cast<ca::AssetCategory>(args[3]->to_int()-1);asset.allowed_furniture=static_cast<std::uint32_t>(args[4]->to_int64());auto* yaws=array(args[5],L"Allowed rotations");if(yaws->size<1||yaws->size>64)throw std::runtime_error("Specify 1..64 rotations.");asset.allowed_yaws_degrees.clear();for(int i=0;i<yaws->size;++i)asset.allowed_yaws_degrees.push_back(yaws->data[i]->to_double());asset.weight=args[6]->to_double();asset.min_scale=args[7]->to_double();asset.max_scale=args[8]->to_double();asset.stackable=args[9]->to_bool()!=FALSE;Interval validity=FOREVER;asset=capture_asset(source,std::move(asset),GetCOREInterface()->GetTime(),validity);auto next=std::make_shared<host::DocumentState>(*doc.state());next->assets.push_back(std::move(asset));next->asset_capture.push_back({true,false,false});++next->revision;auto b=doc.bindings();b.assets.push_back(source);doc.commit(next,b,_T("Cyrus Arrange register asset"));return Integer64::intern(static_cast<INT64>(next->assets.back().id));});}

def_visible_primitive(caRegisterAssets,"caRegisterAssets");
Value* caRegisterAssets_cf(Value** args,int count){check_arg_count(caRegisterAssets,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto* owner=args[0]->to_node();SingleRefMaker lifetime,owner_lifetime;lifetime.SetRef(&doc);owner_lifetime.SetRef(owner);
    host::flush_dependency_events();host::DependencyCommandScope command(doc);const auto original=doc.state();host::validate_document_state(*original);
    const auto dependencies=doc.dependency_ticket();const auto time=GetCOREInterface()->GetTime();const double unit=unit_mm();const auto category=intake_category(args[2]);
    const auto roots=intake_roots(args[1]);IntakeWork work;const auto members=intake_hierarchy(roots,work,true);IntakeWatch watch(members,time);
    validate_intake_sources(doc,roots,work);validate_intake_context(doc,owner,original,dependencies,time,unit,watch);
    auto bindings=doc.bindings();std::vector<INode*> pending;std::vector<std::uint64_t> added,existing;
    for(auto* source:roots){bool found=false;for(std::size_t i=0;i<bindings.assets.size();++i)if(bindings.assets[i]==source){existing.push_back(original->assets[i].id);found=true;}if(!found)pending.push_back(source);}
    if(pending.size()>host::max_document_assets-original->assets.size())throw std::runtime_error("Added props would exceed the 256-asset setup limit.");
    auto next=std::make_shared<host::DocumentState>(*original);IntakeTotals totals(*original);
    if(!pending.empty()){
        const auto first=doc.reserve_ids(pending.size());
        for(std::size_t i=0;i<pending.size();++i){auto asset=capture_intake_asset({pending[i]},intake_metadata(first+i,pending[i],category),time,totals);totals.add(asset);added.push_back(asset.id);next->assets.push_back(std::move(asset));next->asset_capture.push_back({true,false,false});bindings.assets.push_back(pending[i]);validate_intake_context(doc,owner,original,dependencies,time,unit,watch);}
        ++next->revision;host::validate_document_state(*next);
    }
    three_typed_value_locals(Array* out,Array* new_ids,Array* old_ids);vl.out=new Array(2);vl.new_ids=new Array(static_cast<int>(added.size()));vl.old_ids=new Array(static_cast<int>(existing.size()));
    for(auto id:added)vl.new_ids->append(Integer64::intern(static_cast<INT64>(id)));for(auto id:existing)vl.old_ids->append(Integer64::intern(static_cast<INT64>(id)));vl.out->append(vl.new_ids);vl.out->append(vl.old_ids);
    if(added.empty()){validate_intake_context(doc,owner,original,dependencies,time,unit,watch);return_value(vl.out);}
    ArrangeHold hold;UpdatingGuard updating(doc);
    try{
        validate_intake_sources(doc,roots,work);validate_intake_context(doc,owner,original,dependencies,time,unit,watch);
        doc.commit(next,bindings,_T("Cyrus Arrange add selected props"));doc.set_updating(true);
        validate_intake_context(doc,owner,next,dependencies,time,unit,watch);validate_intake_sources(doc,roots,work);validate_intake_context(doc,owner,next,dependencies,time,unit,watch);
        hold.accept(_T("Cyrus Arrange add selected props"));
    }catch(...){hold.cancel();doc.set_updating(false);throw;}
    return_value(vl.out);
});}

def_visible_primitive(caCreatePropGroup,"caCreatePropGroup");
Value* caCreatePropGroup_cf(Value** args,int count){check_arg_count(caCreatePropGroup,4,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto* owner=args[0]->to_node();SingleRefMaker lifetime,owner_lifetime;lifetime.SetRef(&doc);owner_lifetime.SetRef(owner);
    host::flush_dependency_events();host::DependencyCommandScope command(doc);const auto original=doc.state();host::validate_document_state(*original);
    const auto dependencies=doc.dependency_ticket();const auto time=GetCOREInterface()->GetTime();const double unit=unit_mm();const auto category=intake_category(args[3]);
    const auto requested_name=utf8(args[2]->to_string());if(requested_name.empty()||requested_name.size()>ca::AssetLimits{}.max_name_bytes)throw std::runtime_error("Use a nonempty decor-group name of at most 512 UTF-8 bytes.");
    const auto roots=intake_roots(args[1]);if(roots.size()<2)throw std::runtime_error("Select at least two independent prop models or complete groups to copy as one decor group.");
    if(original->assets.size()>=host::max_document_assets)throw std::runtime_error("The setup already contains 256 assets.");
    IntakeWork work;const auto members=intake_hierarchy(roots,work,true);if(members.size()>=max_intake_nodes)throw std::runtime_error("Decor copies and their new group head together must fit within 4096 nodes.");
    IntakeWatch originals(members,time);validate_intake_sources(doc,roots,work);validate_intake_context(doc,owner,original,dependencies,time,unit,originals);
    const auto id=doc.reserve_ids(1);ca::Asset metadata;metadata.id=id;metadata.name=requested_name;metadata.category=category;IntakeTotals totals(*original);
    // Validate the complete assembly before any Max node is created. The copied
    // group is recaptured afterward to prove its actual evaluated source frame.
    auto asset=capture_intake_asset(roots,std::move(metadata),time,totals);validate_intake_context(doc,owner,original,dependencies,time,unit,originals);
    ArrangeHold hold;UpdatingGuard updating(doc);
    try{
        auto* ip=GetCOREInterface();INodeTab input,result_source,result_target;for(auto* node:roots)input.Append(1,&node);Point3 offset(0,0,0);
        if(!ip->CloneNodes(input,offset,true,NODE_COPY,&result_source,&result_target))throw std::runtime_error("Max could not copy the selected prop models.");
        validate_intake_context(doc,owner,original,dependencies,time,unit,originals);
        if(result_source.Count()!=static_cast<int>(members.size())||result_target.Count()!=result_source.Count())throw std::runtime_error("Decor copying expanded unexpected external dependencies; use independent prepared models or complete groups.");
        std::set<INode*> expected(members.begin(),members.end()),seen;std::map<INode*,INode*> mapping;std::vector<INode*> targets;
        for(int i=0;i<result_source.Count();++i){auto* source=result_source[i];auto* target=result_target[i];if(!expected.contains(source)||!seen.insert(source).second||!target||expected.contains(target))throw std::runtime_error("Max returned an invalid decor copy mapping.");mapping.emplace(source,target);targets.push_back(target);}
        [[maybe_unused]] auto copied_lifetimes=pin_intake_scene_nodes(targets,work);
        for(auto* source:members){auto* copied=mapping.at(source);if((source->IsGroupHead()!=FALSE)!=(copied->IsGroupHead()!=FALSE))throw std::runtime_error("Decor copying changed a source group structure.");if(const auto parent=mapping.find(source->GetParentNode());parent!=mapping.end()&&copied->GetParentNode()!=parent->second)throw std::runtime_error("Decor copying did not preserve the nested source hierarchy.");validate_copied_pose(source,copied,time,unit);}
        INodeTab grouping;for(auto* source:roots){auto* copied=mapping.at(source);grouping.Append(1,&copied);}MSTR name(args[2]->to_string());auto* group=ip->GroupNodes(&grouping,&name,FALSE);
        validate_intake_context(doc,owner,original,dependencies,time,unit,originals);
        [[maybe_unused]] auto group_lifetime=pin_intake_scene_nodes({group},work);if(!group->IsGroupHead())throw std::runtime_error("Max did not create a complete decor source group.");
        const auto copied_members=intake_hierarchy({group},work,true);std::set<INode*> copied_set(copied_members.begin(),copied_members.end());
        if(copied_set.size()!=members.size()+1)throw std::runtime_error("Decor grouping changed the copied component count.");for(auto* copied:targets)if(!copied_set.contains(copied))throw std::runtime_error("A copied component is outside the new decor group.");
        for(auto* source:members)validate_copied_pose(source,mapping.at(source),time,unit);
        IntakeWatch copies(copied_members,time);validate_intake_sources(doc,{group},work);
        asset.name=utf8(group->GetName());asset=capture_intake_asset({group},std::move(asset),time,totals);totals.add(asset);
        auto next=std::make_shared<host::DocumentState>(*original);auto bindings=doc.bindings();next->assets.push_back(std::move(asset));next->asset_capture.push_back({true,false,false});bindings.assets.push_back(group);++next->revision;host::validate_document_state(*next);
        validate_intake_context(doc,owner,original,dependencies,time,unit,originals);if(!copies.intact())throw std::runtime_error("Copied decor changed during capture; group creation was cancelled.");
        one_typed_value_local(Array* out);vl.out=new Array(2);vl.out->append(MAXNode::intern(group));vl.out->append(Integer64::intern(static_cast<INT64>(id)));
        doc.commit(next,bindings,_T("Cyrus Arrange create decor group"));doc.set_updating(true);
        validate_intake_context(doc,owner,next,dependencies,time,unit,originals);if(!copies.intact())throw std::runtime_error("Copied decor changed during publication; group creation was cancelled.");validate_intake_sources(doc,{group},work);validate_intake_context(doc,owner,next,dependencies,time,unit,originals);if(!copies.intact())throw std::runtime_error("Copied decor changed during final validation; group creation was cancelled.");
        hold.accept(_T("Cyrus Arrange create decor group"));return_value(vl.out);
    }catch(...){hold.cancel();doc.set_updating(false);throw;}
});}
def_visible_primitive(caAssetRows,"caAssetRows");
Value* caAssetRows_cf(Value** args,int count){check_arg_count(caAssetRows,1,count);return api([&]()->Value*{auto& doc=document(args[0]);auto state=doc.state();auto b=doc.bindings();two_typed_value_locals(Array* out,Array* row);vl.out=new Array(static_cast<int>(state->assets.size()));for(std::size_t i=0;i<state->assets.size();++i){const auto& a=state->assets[i];vl.row=new Array(10);vl.row->append(Integer64::intern(static_cast<INT64>(a.id)));vl.row->append(new String(wide(a.name).c_str()));vl.row->append(Integer::intern(static_cast<int>(a.category)+1));vl.row->append(new Point3Value(point(sub(a.bounds.max,a.bounds.min))));vl.row->append(Integer::intern(a.allowed_furniture));vl.row->append(Double::intern(a.weight));vl.row->append(Double::intern(a.min_scale));vl.row->append(Double::intern(a.max_scale));vl.row->append(a.stackable?&true_value:&false_value);vl.row->append(b.assets[i]?&true_value:&false_value);vl.out->append(vl.row);}return_value(vl.out);});}
def_visible_primitive(caSaveAssetLibrary,"caSaveAssetLibrary");
Value* caSaveAssetLibrary_cf(Value** args,int count){check_arg_count(caSaveAssetLibrary,2,count);return api([&]()->Value*{ca::save_assets(std::filesystem::path(args[1]->to_string()),document(args[0]).state()->assets);return &true_value;});}
def_visible_primitive(caLoadAssetLibrary,"caLoadAssetLibrary");
Value* caLoadAssetLibrary_cf(Value** args,int count){check_arg_count(caLoadAssetLibrary,2,count);return api([&]()->Value*{
    auto incoming=ca::load_assets(std::filesystem::path(args[1]->to_string()));auto& doc=document(args[0]);
    if(incoming.empty())return &true_value;
    if(incoming.size()>host::max_document_assets-doc.state()->assets.size())throw std::runtime_error("Imported collection would exceed the 256-asset setup limit.");
    // A portable library has valid numeric metadata, but its authored stack top
    // still needs the same real-mesh coverage proof as a registered scene source.
    for(auto& asset:incoming)asset=prepare_support(std::move(asset),{false,true,true});
    auto next=std::make_shared<host::DocumentState>(*doc.state());auto b=doc.bindings();const auto base=doc.reserve_ids(incoming.size());
    for(std::size_t i=0;i<incoming.size();++i){incoming[i].id=base+i;next->assets.push_back(std::move(incoming[i]));next->asset_capture.push_back({false,true,true});b.assets.push_back(nullptr);}
    ++next->revision;doc.commit(next,b,_T("Cyrus Arrange import library"));return &true_value;
});}
def_visible_primitive(caRefreshAssets,"caRefreshAssets");
Value* caRefreshAssets_cf(Value** args,int count){check_arg_count(caRefreshAssets,1,count);return api([&]()->Value*{auto& doc=document(args[0]);auto next=std::make_shared<host::DocumentState>(*doc.state());auto b=doc.bindings();Interval validity=FOREVER;for(std::size_t i=0;i<next->assets.size();++i){if(b.assets[i])next->assets[i]=capture_asset(b.assets[i],std::move(next->assets[i]),GetCOREInterface()->GetTime(),validity,next->asset_capture[i]);else if(next->asset_capture[i].source_required)throw std::runtime_error("A registered asset source is missing; rebind it or use stored geometry explicitly.");}++next->revision;doc.commit(next,b,_T("Cyrus Arrange refresh assets"));return &true_value;});}
def_visible_primitive(caGenerate,"caGenerate");
Value* caGenerate_cf(Value** args,int count){check_arg_count(caGenerate,2,count);return api([&]()->Value*{auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);try{const auto chosen=region_selection(args[1]);return result_rows(generate(args[0]->to_node(),doc,chosen));}catch(const std::exception& e){doc.set_error(e.what());throw;}});}
def_visible_primitive(caGenerateVariation,"caGenerateVariation");
Value* caGenerateVariation_cf(Value** args,int count){check_arg_count(caGenerateVariation,4,count);return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);
    try{auto settings=read_arrange_settings(args[1],*doc.state(),true);const auto chosen=region_selection(args[2]);
        if(args[3]->to_bool()!=FALSE)settings.arrangement.seed=fresh_seed(settings.arrangement.seed,doc.state()->arrangement.seed);
        return result_rows(generate(args[0]->to_node(),doc,chosen,{},cache::Operation::Generate,&settings));
    }catch(const std::exception& e){doc.set_error(e.what());throw;}
});}

// The unified Modify view transports only bounded authored settings. Numerical
// targets/scales and publication remain native, with one staged transaction.
def_visible_primitive(caPlacementSettings,"caPlacementSettings");
Value* caPlacementSettings_cf(Value** args,int count){check_arg_count(caPlacementSettings,1,count);return api([&]()->Value*{
    const auto state=document(args[0]).state();const auto& s=state->arrangement;
    one_typed_value_local(Array* out);vl.out=new Array(10);
    vl.out->append(Integer64::intern(static_cast<INT64>(s.seed)));
    vl.out->append(Integer::intern(static_cast<int>(s.amount_mode)+1));
    vl.out->append(Integer64::intern(static_cast<INT64>(s.quantity)));
    for(double value:{s.density,s.spacing_mm,s.edge_clearance_mm})vl.out->append(Double::intern(value));
    vl.out->append(s.random_scale?&true_value:&false_value);vl.out->append(s.fit_to_space?&true_value:&false_value);
    vl.out->append(Double::intern(s.scale_min));vl.out->append(Double::intern(s.scale_max));return_value(vl.out);
});}
def_visible_primitive(caGeneratePlacement,"caGeneratePlacement");
Value* caGeneratePlacement_cf(Value** args,int count){check_arg_count(caGeneratePlacement,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);try{const auto settings=read_placement_settings(args[1],*doc.state(),args[2]->to_bool()!=FALSE);return result_rows(generate(args[0]->to_node(),doc,{}, {},cache::Operation::Generate,&settings));}catch(const std::exception& e){doc.set_error(e.what());throw;}
});}

def_visible_primitive(caOutputRows,"caOutputRows");
Value* caOutputRows_cf(Value** args,int count){check_arg_count(caOutputRows,1,count);return api([&]()->Value*{auto& doc=document(args[0]);const auto s=doc.state();const auto b=doc.bindings();two_typed_value_locals(Array* out,Array* row);vl.out=new Array(static_cast<int>(s->placements.size()));for(std::size_t i=0;i<s->placements.size();++i){const auto& p=s->placements[i];vl.row=new Array(9);vl.row->append(Integer64::intern(static_cast<INT64>(p.stable_id)));vl.row->append(Integer64::intern(static_cast<INT64>(p.asset_id)));vl.row->append(Integer64::intern(p.region_id));vl.row->append(new Point3Value(point(add(p.position,s->frame_origin_mm))));vl.row->append(Double::intern(p.yaw_degrees));vl.row->append(Double::intern(p.scale));vl.row->append(p.locked?&true_value:&false_value);vl.row->append(Integer64::intern(static_cast<INT64>(p.parent_stack_id)));vl.row->append(b.outputs[i]?MAXNode::intern(b.outputs[i]):&undefined);vl.out->append(vl.row);}return_value(vl.out);});}
def_visible_primitive(caSetLocked,"caSetLocked");
Value* caSetLocked_cf(Value** args,int count){check_arg_count(caSetLocked,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto* list=array(args[1],L"Placement IDs");if(list->size>10000)throw std::runtime_error("Too many lock IDs.");
    std::set<std::uint64_t> ids;for(int i=0;i<list->size;++i)ids.insert(static_cast<std::uint64_t>(list->data[i]->to_int64()));
    auto next=std::make_shared<host::DocumentState>(*doc.state());const auto bindings=doc.bindings();const bool locking=args[2]->to_bool()!=FALSE;
    // A row is one authored relationship: capture/lock or unlock all its members.
    // Ordinary stack lock flags retain their existing semantics; the solver
    // independently closes protection through support-connected stacks.
    std::set<std::uint64_t> affected_groups;
    for(const auto& group:next->composition_groups){
        if(std::any_of(group.member_ids.begin(),group.member_ids.end(),[&](auto id){return ids.contains(id);})){affected_groups.insert(group.stable_id);ids.insert(group.member_ids.begin(),group.member_ids.end());}
    }
    for(std::size_t i=0;i<next->placements.size();++i){auto& p=next->placements[i];if(!ids.erase(p.stable_id))continue;
        if(locking){
            auto* node=bindings.outputs[i];if(!node)throw std::runtime_error("Cannot lock a deleted output; regenerate it first.");
            const auto tm=node->GetObjectTM(GetCOREInterface()->GetTime());const auto x=tm.GetRow(0),y=tm.GetRow(1),z=tm.GetRow(2);const double scale=Length(x),tolerance=std::max(1e-6,scale*1e-5);
            if(!std::isfinite(scale)||scale<=0||std::abs(Length(y)-scale)>tolerance||std::abs(Length(z)-scale)>tolerance||std::abs(x.z)>tolerance||std::abs(y.z)>tolerance||std::abs(z.x)>tolerance||std::abs(z.y)>tolerance||z.z<=0||std::abs(DotProd(x,y))>tolerance*scale||DotProd(x,CrossProd(y,z))<=0)
                throw std::runtime_error("Locked output must remain upright with uniform positive scale and no shear.");
            p.position=sub(mul(vec(tm.GetTrans()),unit_mm()),next->frame_origin_mm);p.yaw_degrees=std::atan2(x.y,x.x)*180/arrange_pi;p.scale=scale;
        }
        p.locked=locking;
    }
    if(!ids.empty())throw std::runtime_error("Unknown placement ID; locks unchanged.");
    if(locking&&!affected_groups.empty()){
        std::map<std::uint64_t,const ca::Placement*> poses;for(const auto& p:next->placements)poses.emplace(p.stable_id,&p);
        for(const auto& group:next->composition_groups)if(affected_groups.contains(group.stable_id)){
            const auto region=std::find_if(next->regions->records.begin(),next->regions->records.end(),[&](const auto& r){return r.stable_id==group.region_id;});
            if(region==next->regions->records.end())throw std::runtime_error("Cannot lock a book row on a retired surface. Unlock and regenerate it first.");
            std::vector<ca::Placement> members;members.reserve(group.member_ids.size());for(auto id:group.member_ids)members.push_back(*poses.at(id));
            ca::validate_book_row_relationship(group,members,next->assets.read(),region->semantics.front_direction);
        }
    }
    ++next->revision;doc.commit(next,bindings,_T("Cyrus Arrange locks"));return &true_value;
});}
def_visible_primitive(caTick,"caTick");
Value* caTick_cf(Value**,int count){check_arg_count(caTick,0,count);return api([]()->Value*{return Integer::intern(static_cast<int>(host::process_live_updates()));});}

def_visible_primitive(caPreview,"caPreview");
Value* caPreview_cf(Value** args,int count){check_arg_count(caPreview,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);auto* owner=args[0]->to_node();SingleRefMaker owner_lifetime;owner_lifetime.SetRef(owner);
    CommandRecord record(doc,cache::Operation::Preview);
    try{host::flush_dependency_events();host::DependencyCommandScope command(doc);const auto chosen=region_selection(args[1]);const auto cached=host::preview_info(doc);const auto staged=prepare_generation(doc,chosen,record.metrics,cached.valid?host::preview_regions(doc):nullptr);std::map<std::uint64_t,const ca::Asset*> assets;for(const auto& a:staged.next->assets.read())assets.emplace(a.id,&a);
        std::vector<ca::OrientedBox> boxes;boxes.reserve(staged.result.placements.size());for(const auto& p:staged.result.placements){auto bounds=ca::placement_bounds(*assets.at(p.asset_id),p);bounds.center=add(bounds.center,staged.next->frame_origin_mm);boxes.push_back(bounds);}
        if(doc.owner()!=owner||owner_lifetime.GetRef()!=owner)throw std::runtime_error("Arrange setup was removed during preview.");
        validate_generation(doc,staged,staged.original,owner,record.metrics);
        host::stage_preview(doc,staged.original,staged.dependencies,staged.time,staged.unit,boxes,chosen,staged.result.stats,staged.next->regions);record.metrics.completed=true;return result_rows(staged.result);
    }catch(const std::exception& e){doc.set_error(e.what());throw;}
});}

def_visible_primitive(caPreviewInfo,"caPreviewInfo");
Value* caPreviewInfo_cf(Value** args,int count){check_arg_count(caPreviewInfo,1,count);return api([&]()->Value*{
    const auto info=host::preview_info(document(args[0]));one_typed_value_local(Array* out);vl.out=new Array(4);vl.out->append(info.present?&true_value:&false_value);vl.out->append(info.valid?&true_value:&false_value);vl.out->append(Integer::intern(static_cast<int>(info.box_count)));vl.out->append(new String(wide(info.reason).c_str()));return_value(vl.out);
});}
def_visible_primitive(caCommitPreview,"caCommitPreview");
Value* caCommitPreview_cf(Value** args,int count){check_arg_count(caCommitPreview,1,count);return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);try{host::flush_dependency_events();const auto chosen=host::preview_selection(doc);const auto regions=host::preview_regions(doc);return result_rows(generate(args[0]->to_node(),doc,chosen,regions,cache::Operation::CommitPreview));}catch(const std::exception& e){doc.set_error(e.what());throw;}
});}
def_visible_primitive(caClearPreview,"caClearPreview");
Value* caClearPreview_cf(Value** args,int count){check_arg_count(caClearPreview,1,count);return api([&]()->Value*{return host::clear_preview(document(args[0]))?&true_value:&false_value;});}
def_visible_primitive(caPreviewBounds,"caPreviewBounds");
Value* caPreviewBounds_cf(Value** args,int count){check_arg_count(caPreviewBounds,1,count);return api([&]()->Value*{
    const auto boxes=host::preview_bounds(document(args[0]));two_typed_value_locals(Array* out,Array* row);vl.out=new Array(static_cast<int>(boxes.size()));for(const auto& b:boxes){vl.row=new Array(3);vl.row->append(new Point3Value(point(b.center)));vl.row->append(new Point3Value(point(b.half_extents)));vl.row->append(Double::intern(b.yaw_degrees));vl.out->append(vl.row);}return_value(vl.out);
});}

def_visible_primitive(caAnalyzeSetup,"caAnalyzeSetup");
Value* caAnalyzeSetup_cf(Value** args,int count){check_arg_count(caAnalyzeSetup,1,count);return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);auto* owner=args[0]->to_node();SingleRefMaker owner_lifetime;owner_lifetime.SetRef(owner);
    CommandRecord record(doc,cache::Operation::Analyze);record.metrics.reason=cache::Reason::Disabled;
    try{
        host::flush_dependency_events();host::DependencyCommandScope command(doc);const auto original=doc.state();const auto dependencies=doc.dependency_ticket();auto next=std::make_shared<host::DocumentState>(*original);const auto bindings=doc.bindings();Interval validity=FOREVER;
        const auto time=GetCOREInterface()->GetTime();const auto unit=unit_mm();auto scope=bindings;scope.obstacles.clear();
        cache::GeometryKey key;
        {cache::ScopedPhase phase(record.metrics,cache::Phase::LookupStamp);key=geometry_key(doc,*next,scope,time,unit);}
        const auto furniture=analyze_furniture(doc,*next,bindings,time,unit,validity,&record.metrics);++next->revision;
        record.metrics.inspection_work_original=furniture.inspection.work;record.metrics.inspection_work_executed=furniture.inspection.work;
        const auto validate=[&](const std::shared_ptr<const host::DocumentState>& expected){
            cache::ScopedPhase phase(record.metrics,cache::Phase::FinalValidate);host::flush_dependency_events();
            if(doc.state()!=expected)throw std::runtime_error("Arrange setup settings changed during analysis; previous result retained.");
            if(doc.owner()!=owner||owner_lifetime.GetRef()!=owner||GetCOREInterface()->GetTime()!=time||unit_mm()!=unit)throw std::runtime_error("Arrange owner, time or units changed during analysis; previous result retained.");
            if(!doc.dependencies_unchanged(dependencies))throw std::runtime_error("Arrange source notifications changed during analysis; previous result retained. "+doc.dependency_failure_detail(dependencies));
            const auto current_key=geometry_key(doc,*next,scope,time,unit);
            if(!doc.dependencies_unchanged(dependencies)||doc.state()!=expected)throw std::runtime_error("Arrange inputs changed during analysis validation; previous result retained.");
            if(current_key!=key)throw std::runtime_error("Arrange geometry changed during analysis ("+geometry_key_difference(key,current_key)+"); previous result retained.");
        };
        validate(original);
        // Analysis remains furniture-only and publishes measured metadata only.
        // Missing obstacles/assets do not make Analyze run the full fit query.
        ArrangeHold hold;
        try{doc.commit(next,bindings,_T("Cyrus Arrange analyze furniture"));validate(next);hold.accept(_T("Cyrus Arrange analyze furniture"));}
        catch(...){hold.cancel();throw;}
        record.metrics.completed=true;return Integer::intern(static_cast<int>(next->regions->records.size()));
    }catch(const std::exception& e){doc.set_error(e.what());throw;}
});}

def_visible_primitive(caCollisionScope,"caCollisionScope");
Value* caCollisionScope_cf(Value** args,int count){check_arg_count(caCollisionScope,1,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto bindings=doc.bindings();three_typed_value_locals(Array* out,Array* rows,Array* row);
    vl.out=new Array(2);vl.rows=new Array(static_cast<int>(bindings.obstacles.size()));
    for(auto* node:bindings.obstacles){vl.row=new Array(2);vl.row->append(node?MAXNode::intern(node):&undefined);vl.row->append(new String(node?node->GetName():L"Missing obstacle source"));vl.rows->append(vl.row);}
    vl.out->append(doc.state()->require_front_access?&true_value:&false_value);vl.out->append(vl.rows);return_value(vl.out);
});}
namespace {
void set_collision_scope(host::Document& doc,std::vector<INode*> obstacles,bool front){
    if(obstacles.size()>4096)throw std::runtime_error("Choose at most 4096 obstacle roots.");
    auto bindings=doc.bindings();std::vector<INode*> present;for(auto* node:obstacles)if(node)present.push_back(node);
    if(!present.empty()){
        std::vector<INode*> receivers;for(auto* node:bindings.furniture)if(node)receivers.push_back(node);
        const auto furniture=receivers.empty()?std::vector<INode*>{}:expand(receivers);const auto expanded=expand(present);std::set<INode*> support(furniture.begin(),furniture.end());
        if(expanded.size()>4096-furniture.size())throw std::runtime_error("Combined furniture and obstacle scope exceeds 4096 geometry nodes.");
        for(auto* node:expanded)if(support.contains(node))throw std::runtime_error("Furniture and obstacle scopes overlap. Choose external geometry only.");
        std::set<INode*> forbidden{doc.owner()};
        for(const auto* role:{&bindings.assets,&bindings.paths}){
            std::vector<INode*> existing;for(auto* node:*role)if(node)existing.push_back(node);
            if(!existing.empty())for(auto* node:expand(existing))forbidden.insert(node);
        }
        for(auto* node:expanded)if(forbidden.contains(node))throw std::runtime_error("Obstacles overlap this arrangement's icon, props or path. Choose separate scene geometry.");
    }
    if(bindings.obstacles==obstacles&&doc.state()->require_front_access==front)return;
    bindings.obstacles=std::move(obstacles);auto next=std::make_shared<host::DocumentState>(*doc.state());next->obstacle_count=bindings.obstacles.size();next->require_front_access=front;++next->revision;
    doc.commit(next,bindings,_T("Cyrus Arrange collision scope"));
}
}
def_visible_primitive(caSetCollisionScope,"caSetCollisionScope");
Value* caSetCollisionScope_cf(Value** args,int count){check_arg_count(caSetCollisionScope,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto* list=array(args[1],L"Obstacle nodes");
    set_collision_scope(doc,list->size?nodes(args[1]):std::vector<INode*>{},args[2]->to_bool()!=FALSE);return &true_value;
});}
def_visible_primitive(caAddObstacles,"caAddObstacles");
Value* caAddObstacles_cf(Value** args,int count){check_arg_count(caAddObstacles,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto incoming=nodes(args[1]);std::size_t missing=0;
    for(auto* node:doc.bindings().obstacles)if(node)incoming.push_back(node);else ++missing;
    auto merged=normalize_roots(std::move(incoming));if(missing>4096-merged.size())throw std::runtime_error("Choose at most 4096 obstacle roots.");merged.insert(merged.end(),missing,nullptr);
    set_collision_scope(doc,std::move(merged),doc.state()->require_front_access);return &true_value;
});}
def_visible_primitive(caRemoveObstacle,"caRemoveObstacle");
Value* caRemoveObstacle_cf(Value** args,int count){check_arg_count(caRemoveObstacle,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto index=args[1]->to_int();const auto revision=static_cast<std::uint64_t>(args[2]->to_int64());auto roots=doc.bindings().obstacles;
    if(revision!=doc.state()->revision)throw std::runtime_error("Obstacle list changed. Refresh Modify before removing a row.");
    if(index<1||static_cast<std::size_t>(index)>roots.size())throw std::runtime_error("Choose an obstacle in the list first.");
    roots.erase(roots.begin()+index-1);set_collision_scope(doc,std::move(roots),doc.state()->require_front_access);return &true_value;
});}
def_visible_primitive(caRegionRows,"caRegionRows");
Value* caRegionRows_cf(Value** args,int count){check_arg_count(caRegionRows,1,count);return api([&]()->Value*{
    const auto state=document(args[0]).state();two_typed_value_locals(Array* out,Array* row);vl.out=new Array(static_cast<int>(state->regions->records.size()));
    for(const auto& record:state->regions->records){const auto& s=record.semantics;vl.row=new Array(13);
        vl.row->append(Integer64::intern(record.stable_id));vl.row->append(new String(wide(s.label).c_str()));vl.row->append(new String(wide(s.compartment_label).c_str()));
        vl.row->append(Integer::intern(static_cast<int>(s.role)+1));vl.row->append(new Point3Value(point(add(record.shape->bounds.min,state->frame_origin_mm))));vl.row->append(new Point3Value(point(add(record.shape->bounds.max,state->frame_origin_mm))));
        vl.row->append(Double::intern(std::isinf(record.minimum_clearance_mm)?-1:record.minimum_clearance_mm));vl.row->append(record.open_above?&true_value:&false_value);
        vl.row->append(Integer::intern(s.allowed_asset_categories));vl.row->append(Double::intern(s.density_multiplier));vl.row->append(s.allow_stacking?&true_value:&false_value);vl.row->append(s.excluded?&true_value:&false_value);
        vl.row->append(new Point3Value(point(s.front_direction)));vl.out->append(vl.row);
    }return_value(vl.out);
});}
def_visible_primitive(caSetRegionRules,"caSetRegionRules");
Value* caSetRegionRules_cf(Value** args,int count){check_arg_count(caSetRegionRules,10,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto id=args[1]->to_int64();if(id<1||id>4294967295LL)throw std::runtime_error("Region IDs must be positive 32-bit identities.");
    const auto role=args[4]->to_int();const auto mask=args[5]->to_int64();
    if(role<1||role>static_cast<int>(ca::SupportRole::Count)||mask<0||mask>ca::all_asset_mask)throw std::runtime_error("Invalid region role or allowed accessory mask.");
    auto registry=std::make_shared<ca::RegionRegistry>(*doc.state()->regions);
    auto found=std::find_if(registry->records.begin(),registry->records.end(),[&](const auto& record){return record.stable_id==id;});
    if(found==registry->records.end())throw std::runtime_error("Unknown or retired surface ID. Analyze the furniture and select a current surface.");
    found->semantics={utf8(args[2]->to_string()),utf8(args[3]->to_string()),static_cast<ca::SupportRole>(role-1),static_cast<std::uint32_t>(mask),args[6]->to_double(),args[7]->to_bool()!=FALSE,args[8]->to_bool()!=FALSE,vec(args[9]->to_point3())};
    ca::validate_region_registry(*registry);auto next=std::make_shared<host::DocumentState>(*doc.state());next->regions=std::move(registry);++next->revision;
    doc.commit(next,doc.bindings(),_T("Cyrus Arrange surface rules"));return &true_value;
});}

def_visible_primitive(caAssetDetail,"caAssetDetail");
Value* caAssetDetail_cf(Value** args,int count){check_arg_count(caAssetDetail,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto state=doc.state();const auto i=asset_index(*state,args[1]);const auto& a=state->assets[i];const auto b=doc.bindings();const auto policy=state->asset_capture[i];
    two_typed_value_locals(Array* out,Array* yaws);vl.out=new Array(13);vl.yaws=new Array(static_cast<int>(a.allowed_yaws_degrees.size()));for(auto angle:a.allowed_yaws_degrees)vl.yaws->append(Double::intern(angle));
    vl.out->append(Integer64::intern(static_cast<INT64>(a.id)));vl.out->append(new String(wide(a.name).c_str()));vl.out->append(Integer::intern(static_cast<int>(a.category)+1));vl.out->append(Integer::intern(a.allowed_furniture));vl.out->append(vl.yaws);
    vl.out->append(Double::intern(a.weight));vl.out->append(Double::intern(a.min_scale));vl.out->append(Double::intern(a.max_scale));vl.out->append(a.stackable?&true_value:&false_value);
    vl.out->append(Integer::intern(b.assets[i]?1:policy.source_required?3:2));vl.out->append(b.assets[i]?MAXNode::intern(b.assets[i]):&undefined);vl.out->append(new String(b.assets[i]?b.assets[i]->GetName():policy.source_required?L"Missing scene source":L"Embedded geometry"));vl.out->append(policy_rows(policy));return_value(vl.out);
});}
def_visible_primitive(caUpdateAsset,"caUpdateAsset");
Value* caUpdateAsset_cf(Value** args,int count){check_arg_count(caUpdateAsset,10,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto next=std::make_shared<host::DocumentState>(*doc.state());const auto i=asset_index(*next,args[1]);auto& a=next->assets[i];const bool was_stackable=a.stackable;
    a.name=utf8(args[2]->to_string());a.category=static_cast<ca::AssetCategory>(args[3]->to_int()-1);a.allowed_furniture=static_cast<std::uint32_t>(args[4]->to_int64());a.allowed_yaws_degrees=read_yaws(args[5]);a.weight=args[6]->to_double();a.min_scale=args[7]->to_double();a.max_scale=args[8]->to_double();a.stackable=args[9]->to_bool()!=FALSE;
    if(a.stackable!=was_stackable){auto policy=next->asset_capture[i];policy.authored_contact=true;policy.authored_stack=false;a=prepare_support(std::move(a),policy);next->asset_capture[i].authored_stack=false;}
    ca::validate_asset(a);++next->revision;doc.commit(next,doc.bindings(),_T("Cyrus Arrange edit asset"));return &true_value;
});}
def_visible_primitive(caRebindAsset,"caRebindAsset");
Value* caRebindAsset_cf(Value** args,int count){check_arg_count(caRebindAsset,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto next=std::make_shared<host::DocumentState>(*doc.state());const auto i=asset_index(*next,args[1]);auto* source=args[2]->to_node();Interval validity=FOREVER;
    next->assets[i]=capture_asset(source,std::move(next->assets[i]),GetCOREInterface()->GetTime(),validity,next->asset_capture[i]);next->asset_capture[i].source_required=true;auto b=doc.bindings();b.assets[i]=source;++next->revision;doc.commit(next,b,_T("Cyrus Arrange rebind asset"));return &true_value;
});}
def_visible_primitive(caUseStoredAsset,"caUseStoredAsset");
Value* caUseStoredAsset_cf(Value** args,int count){check_arg_count(caUseStoredAsset,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto next=std::make_shared<host::DocumentState>(*doc.state());const auto i=asset_index(*next,args[1]);auto b=doc.bindings();b.assets[i]=nullptr;next->asset_capture[i].source_required=false;++next->revision;doc.commit(next,b,_T("Cyrus Arrange use embedded geometry"));return &true_value;
});}
def_visible_primitive(caAssetSupport,"caAssetSupport");
Value* caAssetSupport_cf(Value** args,int count){check_arg_count(caAssetSupport,2,count);return api([&]()->Value*{
    const auto state=document(args[0]).state();const auto i=asset_index(*state,args[1]);const auto& a=state->assets[i];one_typed_value_local(Array* out);vl.out=new Array(9);
    vl.out->append(new Point3Value(point(a.anchor)));vl.out->append(point_rows(a.contact_footprint));vl.out->append(a.stackable?&true_value:&false_value);vl.out->append(Double::intern(a.stack_height_mm));vl.out->append(point_rows(a.stack_footprint));vl.out->append(Integer::intern(a.allowed_on_top));vl.out->append(policy_rows(state->asset_capture[i]));vl.out->append(new Point3Value(point(a.bounds.min)));vl.out->append(new Point3Value(point(a.bounds.max)));return_value(vl.out);
});}
def_visible_primitive(caSetAssetSupport,"caSetAssetSupport");
Value* caSetAssetSupport_cf(Value** args,int count){check_arg_count(caSetAssetSupport,8,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto next=std::make_shared<host::DocumentState>(*doc.state());const auto i=asset_index(*next,args[1]);auto& a=next->assets[i];a.anchor=vec(args[2]->to_point3());a.contact_footprint=read_points(args[3]);
    if(a.contact_footprint.size()<3)throw std::runtime_error("Author at least three counterclockwise contact points.");
    a.stackable=args[4]->to_bool()!=FALSE;a.stack_height_mm=args[5]->to_double();a.stack_footprint=read_points(args[6]);a.allowed_on_top=static_cast<std::uint32_t>(args[7]->to_int64());
    next->asset_capture[i].authored_contact=true;next->asset_capture[i].authored_stack=true;a=prepare_support(std::move(a),next->asset_capture[i]);++next->revision;doc.commit(next,doc.bindings(),_T("Cyrus Arrange author support patches"));return &true_value;
});}
def_visible_primitive(caResetAssetSupport,"caResetAssetSupport");
Value* caResetAssetSupport_cf(Value** args,int count){check_arg_count(caResetAssetSupport,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);auto next=std::make_shared<host::DocumentState>(*doc.state());const auto i=asset_index(*next,args[1]);const auto b=doc.bindings();auto& policy=next->asset_capture[i];policy.authored_contact=false;policy.authored_stack=false;Interval validity=FOREVER;
    if(b.assets[i])next->assets[i]=capture_asset(b.assets[i],std::move(next->assets[i]),GetCOREInterface()->GetTime(),validity,policy);
    else if(policy.source_required)throw std::runtime_error("Cannot reset from a missing scene source. Rebind it or explicitly use embedded geometry.");
    else next->assets[i]=prepare_support(std::move(next->assets[i]),policy);
    ++next->revision;doc.commit(next,b,_T("Cyrus Arrange reset support patches"));return &true_value;
});}
def_visible_primitive(caRemoveAssets,"caRemoveAssets");
Value* caRemoveAssets_cf(Value** args,int count){check_arg_count(caRemoveAssets,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);SingleRefMaker lifetime;lifetime.SetRef(&doc);const auto* ids=array(args[1],L"Asset IDs");if(ids->size<1||ids->size>256)throw std::runtime_error("Choose 1..256 asset IDs to remove.");
    std::set<std::uint64_t> removing;const auto state=doc.state();for(int n=0;n<ids->size;++n)removing.insert(state->assets[asset_index(*state,ids->data[n])].id);
    std::set<std::uint64_t> placements;for(const auto& p:state->placements)if(removing.contains(p.asset_id))placements.insert(p.stable_id);
    if(!placements.empty()&&!args[2]->to_bool())throw std::runtime_error("Assets are in use. Enable removal of their generated outputs to continue.");
    // Remove descendants, plus complete rows reached from an affected member.
    // A removed stack child does not require removing its otherwise valid parent.
    std::map<std::uint64_t,std::vector<std::uint64_t>> children;
    std::map<std::uint64_t,const ca::CompositionGroup*> membership;
    for(const auto& p:state->placements)if(p.parent_stack_id)children[p.parent_stack_id].push_back(p.stable_id);
    for(const auto& group:state->composition_groups)for(auto id:group.member_ids)membership.emplace(id,&group);
    std::vector<std::uint64_t> queue(placements.begin(),placements.end());
    for(std::size_t cursor=0;cursor<queue.size();++cursor){
        const auto id=queue[cursor];
        if(const auto found=children.find(id);found!=children.end())for(auto child:found->second)if(placements.insert(child).second)queue.push_back(child);
        if(const auto found=membership.find(id);found!=membership.end())for(auto member:found->second->member_ids)if(placements.insert(member).second)queue.push_back(member);
    }
    auto next=std::make_shared<host::DocumentState>(*state);auto b=doc.bindings();std::vector<INode*> deleted;
    for(std::size_t i=next->placements.size();i-->0;)if(placements.contains(next->placements[i].stable_id)){deleted.push_back(b.outputs[i]);b.outputs.erase(b.outputs.begin()+i);next->placements.erase(next->placements.begin()+i);}
    std::erase_if(next->composition_groups,[&](const auto& group){return placements.contains(group.member_ids.front());});
    std::erase_if(next->minimums,[&](const auto& minimum){return removing.contains(minimum.asset_id);});
    for(std::size_t i=next->assets.size();i-->0;)if(removing.contains(next->assets[i].id)){next->assets.erase(next->assets.cbegin()+i);next->asset_capture.erase(next->asset_capture.begin()+i);b.assets.erase(b.assets.begin()+i);}
    ++next->revision;ArrangeHold hold;doc.set_updating(true);try{doc.commit(next,b,_T("Cyrus Arrange remove assets"));doc.set_updating(true);for(auto* node:deleted)if(node)GetCOREInterface()->DeleteNode(node,FALSE);hold.accept(_T("Cyrus Arrange remove assets"));doc.set_updating(false);}catch(...){doc.set_updating(false);throw;}
    one_typed_value_local(Array* out);vl.out=new Array(2);vl.out->append(Integer::intern(static_cast<int>(removing.size())));vl.out->append(Integer::intern(static_cast<int>(placements.size())));return_value(vl.out);
});}
def_visible_primitive(caCategoryRules,"caCategoryRules");
Value* caCategoryRules_cf(Value** args,int count){check_arg_count(caCategoryRules,2,count);return api([&]()->Value*{
    const int category=args[1]->to_int();if(category<1||category>5)throw std::runtime_error("Choose a furniture category.");const auto state=document(args[0]).state();two_typed_value_locals(Array* out,Array* row);vl.out=new Array(11);
    for(const auto& r:state->category_rules[category-1]){vl.row=new Array(4);vl.row->append(Integer::intern(static_cast<int>(r.category)+1));vl.row->append(Double::intern(r.weight));vl.row->append(Integer::intern(r.maximum_count));vl.row->append(r.allow_on_stack?&true_value:&false_value);vl.out->append(vl.row);}return_value(vl.out);
});}
def_visible_primitive(caSetCategoryRules,"caSetCategoryRules");
Value* caSetCategoryRules_cf(Value** args,int count){check_arg_count(caSetCategoryRules,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const int category=args[1]->to_int();if(category<1||category>5)throw std::runtime_error("Choose a furniture category.");const auto* rows=array(args[2],L"Category rules");if(rows->size!=11)throw std::runtime_error("Provide all eleven category rule rows.");std::vector<ca::CategoryRule> rules;
    for(int i=0;i<rows->size;++i){const auto* row=array(rows->data[i],L"Category rule");if(row->size!=4)throw std::runtime_error("Category rule requires category, weight, maximum count and stack permission.");rules.push_back({static_cast<ca::AssetCategory>(row->data[0]->to_int()-1),row->data[1]->to_double(),static_cast<std::uint32_t>(row->data[2]->to_int()),row->data[3]->to_bool()!=FALSE});}
    ca::validate_category_rules(rules);std::sort(rules.begin(),rules.end(),[](const auto& a,const auto& b){return a.category<b.category;});auto next=std::make_shared<host::DocumentState>(*doc.state());next->category_rules[category-1]=std::move(rules);++next->revision;doc.commit(next,doc.bindings(),_T("Cyrus Arrange category rules"));return &true_value;
});}
def_visible_primitive(caResetCategoryRules,"caResetCategoryRules");
Value* caResetCategoryRules_cf(Value** args,int count){check_arg_count(caResetCategoryRules,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const int category=args[1]->to_int();if(category<1||category>5)throw std::runtime_error("Choose a furniture category.");const host::DocumentState defaults;auto next=std::make_shared<host::DocumentState>(*doc.state());next->category_rules[category-1]=defaults.category_rules[category-1];++next->revision;doc.commit(next,doc.bindings(),_T("Cyrus Arrange reset category rules"));return &true_value;
});}
def_visible_primitive(caSuggestFurniture,"caSuggestFurniture");
Value* caSuggestFurniture_cf(Value** args,int count){check_arg_count(caSuggestFurniture,1,count);return api([&]()->Value*{
    const auto roots=nodes(args[0]);std::set<int> explicit_tags,suggestions;bool invalid=false;for(auto* node:roots){if(node->UserPropExists(_T("CyrusArrangeFurnitureCategory"))){int category=0;if(!node->GetUserPropInt(_T("CyrusArrangeFurnitureCategory"),category)||category<1||category>5)invalid=true;else explicit_tags.insert(category);}const auto name=utf8(node->GetName());if(name.size()>512)throw std::runtime_error("Furniture inference accepts names up to 512 UTF-8 bytes.");if(const auto category=ca::infer_furniture_category(name))suggestions.insert(static_cast<int>(*category)+1);}
    int value=0;const wchar_t* reason=L"No unambiguous furniture category found; choose one explicitly.";
    if(invalid)reason=L"An explicit furniture tag is invalid; use category 1..5.";else if(explicit_tags.size()==1){value=*explicit_tags.begin();reason=L"Suggested from the explicit CyrusArrangeFurnitureCategory tag.";}else if(explicit_tags.size()>1)reason=L"Selected furniture has conflicting explicit category tags.";else if(suggestions.size()==1){value=*suggestions.begin();reason=L"Suggested from furniture names; confirm the category before creating a setup.";}
    one_typed_value_local(Array* out);vl.out=new Array(2);vl.out->append(Integer::intern(value));vl.out->append(new String(reason));return_value(vl.out);
});}

def_visible_primitive(caCompositionSettings,"caCompositionSettings");
Value* caCompositionSettings_cf(Value** args,int count){check_arg_count(caCompositionSettings,1,count);return api([&]()->Value*{
    const auto state=document(args[0]).state();const auto& options=state->composition;
    one_typed_value_local(Array* out);vl.out=new Array(5);
    vl.out->append(options.book_rows?&true_value:&false_value);vl.out->append(Integer::intern(options.minimum_books));vl.out->append(Integer::intern(options.maximum_books));
    vl.out->append(Double::intern(options.row_gap_mm));vl.out->append(Double::intern(options.row_height_balance));return_value(vl.out);
});}
def_visible_primitive(caSetCompositionSettings,"caSetCompositionSettings");
Value* caSetCompositionSettings_cf(Value** args,int count){check_arg_count(caSetCompositionSettings,2,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto* values=array(args[1],L"Composition settings");if(values->size!=5)throw std::runtime_error("Expected five composition settings.");
    const auto minimum=values->data[1]->to_int(),maximum=values->data[2]->to_int();if(minimum<2||maximum>6||minimum>maximum)throw std::runtime_error("Book rows need a minimum and maximum of two to six books.");
    auto next=std::make_shared<host::DocumentState>(*doc.state());next->composition={values->data[0]->to_bool()!=FALSE,static_cast<std::uint32_t>(minimum),static_cast<std::uint32_t>(maximum),values->data[3]->to_double(),values->data[4]->to_double()};
    ca::validate_composition_options(next->composition,next->arrangement.category);++next->revision;doc.commit(next,doc.bindings(),_T("Cyrus Arrange composition settings"));return &true_value;
});}
def_visible_primitive(caAssetBookRow,"caAssetBookRow");
Value* caAssetBookRow_cf(Value** args,int count){check_arg_count(caAssetBookRow,2,count);return api([&]()->Value*{
    const auto state=document(args[0]).state();const auto& asset=state->assets[asset_index(*state,args[1])];return Integer::intern(asset.book_row?static_cast<int>(asset.book_row->spine_face)+1:0);
});}
def_visible_primitive(caSetAssetBookRow,"caSetAssetBookRow");
Value* caSetAssetBookRow_cf(Value** args,int count){check_arg_count(caSetAssetBookRow,3,count);return api([&]()->Value*{
    auto& doc=document(args[0]);const auto tag=args[2]->to_int();if(tag<0||tag>4)throw std::runtime_error("Book row profile must be zero (disabled) or a spine side from one to four.");
    auto next=std::make_shared<host::DocumentState>(*doc.state());auto& asset=next->assets[asset_index(*next,args[1])];
    if(tag)asset.book_row=ca::BookRowProfile{static_cast<ca::SpineFace>(tag-1)};else asset.book_row.reset();
    ca::validate_asset(asset);++next->revision;doc.commit(next,doc.bindings(),_T("Cyrus Arrange book row profile"));return &true_value;
});}
def_visible_primitive(caCompositionRows,"caCompositionRows");
Value* caCompositionRows_cf(Value** args,int count){check_arg_count(caCompositionRows,1,count);return api([&]()->Value*{
    const auto state=document(args[0]).state();three_typed_value_locals(Array* out,Array* row,Array* members);vl.out=new Array(static_cast<int>(state->composition_groups.size()));
    for(const auto& group:state->composition_groups){
        vl.row=new Array(6);vl.members=new Array(static_cast<int>(group.member_ids.size()));for(auto id:group.member_ids)vl.members->append(Integer64::intern(static_cast<INT64>(id)));
        vl.row->append(Integer64::intern(static_cast<INT64>(group.stable_id)));vl.row->append(Integer::intern(static_cast<int>(group.kind)+1));vl.row->append(Integer64::intern(group.region_id));
        vl.row->append(vl.members);vl.row->append(new Point3Value(point(group.front_direction)));vl.row->append(Double::intern(group.gap_mm));vl.out->append(vl.row);
    }return_value(vl.out);
});}
def_visible_primitive(caCompositionStats,"caCompositionStats");
Value* caCompositionStats_cf(Value** args,int count){check_arg_count(caCompositionStats,1,count);return api([&]()->Value*{
    const auto& stats=document(args[0]).lifecycle().composition_stats;const auto value=stats.value_or(ca::CompositionStats{});one_typed_value_local(Array* out);vl.out=new Array(6);
    vl.out->append(stats?&true_value:&false_value);for(auto n:{value.row_attempts,value.rows_formed,value.row_failures,value.balance_anchor_attempts,value.rows_moved})vl.out->append(Integer64::intern(static_cast<INT64>(n)));return_value(vl.out);
});}

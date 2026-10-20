#include "arrange_document.h"
#include "arrange_presentation.h"
#include <iparamb2.h>
#include <custattrib.h>
#include <icustattribcontainer.h>
#include <INodeMonitor.h>
#include <ISceneEventManager.h>
#include <notify.h>
#include <units.h>
#include <objbase.h>
#include <algorithm>
#include <bit>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <stdexcept>
#include <utility>
#include <type_traits>

namespace cyrus::arrange::host {
static_assert(std::is_same_v<TimeValue,std::int32_t>,"Saved Arrange time must retain the Max int32 wire representation.");
class BindingInstallScope {
    Document& document_;
public:
    explicit BindingInstallScope(Document& doc)noexcept:document_(doc){++document_.installing_bindings_;}
    ~BindingInstallScope(){--document_.installing_bindings_;}
};
namespace {
const Class_ID doc_id(0x6a4387d1,0x4fa90372);
const Class_ID attr_id(0x6a4387d2,0x4fa90372);
constexpr USHORT state_chunk=0x7111;
constexpr std::size_t max_documents=512;
constexpr std::size_t max_dependency_nodes=8192;
HINSTANCE document_module{};
std::set<Document*> documents;
UpdateCallback update_callback{};
UINT_PTR service_timer{};
bool service_registered{}, service_stopped{}, scene_suspended{}, processing_live{};
ISceneEventManager::CallbackKey hierarchy_callback_key{};
cache::Epoch scene_epoch;
std::uint64_t next_geometry_instance{1};
std::unique_ptr<cache::GeometryCache> numeric_cache;

std::uint64_t reserve_geometry_instance()noexcept {
    if(!next_geometry_instance)return 0;
    const auto value=next_geometry_instance;
    next_geometry_instance=value==std::numeric_limits<std::uint64_t>::max()?0:value+1;
    return value;
}
bool structural_container_message(RefMessage message)noexcept {
    return message==REFMSG_CONTAINER_ELEMENT_ADDED||message==REFMSG_CONTAINER_ELEMENT_REMOVED||message==REFMSG_CONTAINER_ELEMENT_SET;
}
bool input_message(RefMessage message,PartID part)noexcept {
    if(message==REFMSG_CHANGE) {
        // Object/node selection and display-only changes are browsing, not a
        // new evaluated input. Mixed/unknown channels remain conservative.
        const PartID passive=PART_SELECT|PART_SUBSEL_TYPE|PART_DISPLAY|PART_HIDESTATE;
        return !part||(part&~passive)!=0;
    }
    return message==REFMSG_NODE_LINK||message==REFMSG_TARGET_DELETED||
           message==REFMSG_CONTAINER_ELEMENT_NULLED||structural_container_message(message);
}
std::uint32_t input_dirty(PartID part,RefMessage message)noexcept {
    if(message==REFMSG_TARGET_DELETED||message==REFMSG_CONTAINER_ELEMENT_NULLED)return DirtyMissingBinding;
    if(message==REFMSG_NODE_LINK||structural_container_message(message))return DirtyGeometry;
    if(message==REFMSG_CHANGE&&(part&(PART_GEOM|PART_TOPO|PART_TM|PART_OBJECT_TYPE)))
        return (part&PART_TM)?DirtyTransform:DirtyGeometry;
    return DirtyNone;
}
void invalidate_scene(cache::Reason reason,std::uint32_t dirty=DirtyNone)noexcept {
    scene_epoch.invalidate();
    for(auto* doc:documents)doc->observe_input_change(reason,dirty,{DependencyOrigin::Scene});
    defer_geometry_cache_all(reason);
}

void main_thread() {
    auto* ip=GetCOREInterface();
    if (!ip || !ip->GetMAXHWnd() || GetWindowThreadProcessId(ip->GetMAXHWnd(),nullptr)!=GetCurrentThreadId())
        throw std::runtime_error("Cyrus Arrange documents require Max's main thread.");
}
// Passive identity check: unlike get_document(), this never repairs/rebinds an
// owner monitor. Undo may keep a detached Document alive after its attribute
// was removed, so a non-null monitor alone is insufficient for Live ownership.
bool owns_document(INode* node,const Document* document) {
    if(!node)return false;
    auto* attributes=node->GetCustAttribContainer();if(!attributes)return false;
    bool found=false;
    for(int i=0;i<attributes->GetNumCustAttribs();++i) {
        auto* attribute=attributes->GetCustAttrib(i);
        if(!attribute||attribute->ClassID()!=attr_id)continue;
        if(found||attribute->GetReference(0)!=document)return false;
        found=true;
    }
    return found;
}
std::string guid() {
    GUID value{};
    if (FAILED(CoCreateGuid(&value))) throw std::runtime_error("Cannot allocate an Arrange setup identity.");
    wchar_t buffer[40]{};
    if (!StringFromGUID2(value,buffer,40)) throw std::runtime_error("Cannot format an Arrange setup identity.");
    std::string output;
    for (const auto ch:buffer) {if(!ch)break;output.push_back(static_cast<char>(ch));}
    return output;
}
// These keep native containers alive for Undo, rather than keeping raw INode*.
class BoundReferences final : public ReferenceMaker {
    std::array<RefTargetHandle,6> refs_{};
public:
    ~BoundReferences()override{DeleteAllRefsFromMe();}
    int NumRefs()override{return 6;}
    RefTargetHandle GetReference(int i)override{return i>=0&&i<6?refs_[i]:nullptr;}
    void SetReference(int i,RefTargetHandle value)override{if(i>=0&&i<6)refs_[i]=value;}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
    void set(int i,RefTargetHandle value){if(ReplaceReference(i,value)!=REF_SUCCEED)throw std::runtime_error("Cannot retain Arrange node references.");}
};
struct HoldSuspension {
    HoldSuspension(){theHold.Suspend();}
    ~HoldSuspension(){theHold.Resume();}
};
std::shared_ptr<BoundReferences> bound_from_document(Document& doc) {
    auto result=std::make_shared<BoundReferences>();
    for(int i=0;i<6;++i)result->set(i,doc.GetReference(i+1));
    return result;
}
std::shared_ptr<BoundReferences> stage_bindings(const Bindings& bindings) {
    HoldSuspension suspend;
    auto result=std::make_shared<BoundReferences>();
    std::vector<INode*> dependencies,pending=bindings.assets;
    pending.insert(pending.end(),bindings.furniture.begin(),bindings.furniture.end());
    pending.insert(pending.end(),bindings.obstacles.begin(),bindings.obstacles.end());
    pending.insert(pending.end(),bindings.paths.begin(),bindings.paths.end());
    std::set<ULONG> visited;
    while(!pending.empty()) {
        auto* node=pending.back();pending.pop_back();if(!node||!visited.insert(node->GetHandle()).second)continue;
        if(visited.size()>max_dependency_nodes)throw std::runtime_error("Furniture, asset and obstacle dependencies exceed 8,192 nodes.");
        dependencies.push_back(node);
        if(node->IsGroupHead()) {
            const int children=node->NumberOfChildren();
            if(children<0||pending.size()>max_dependency_nodes||static_cast<std::size_t>(children)>max_dependency_nodes-pending.size())throw std::runtime_error("Furniture, asset and obstacle expansion exceeds 8,192 pending nodes.");
            for(int child=0;child<children;++child)pending.push_back(node->GetChildNode(child));
        }
    }
    const std::vector<INode*>* groups[]={&bindings.furniture,&bindings.assets,&bindings.outputs,&dependencies,&bindings.obstacles,&bindings.paths};
    for(int group=0;group<6;++group) {
        auto* container=IRefTargContainer::CreateInstance();
        if(!container)throw std::runtime_error("Cannot allocate Arrange reference container.");
        result->set(group,container);
        for(std::size_t i=0;i<groups[group]->size();++i) {
            auto* node=(*groups[group])[i];container->SetItem(static_cast<int>(i),node);
            if(container->GetItem(static_cast<int>(i))!=node)
                throw std::runtime_error("Arrange reference rejected; do not parent setup inputs or outputs under their setup node.");
        }
    }
    return result;
}
void apply_bound(Document& doc,const BoundReferences& input) {
    BindingInstallScope installing(doc);
    auto& value=const_cast<BoundReferences&>(input);
    for(int i=0;i<6;++i)
        if(doc.ReplaceReference(i+1,value.GetReference(i))!=REF_SUCCEED)
            throw std::runtime_error("Cannot publish Arrange reference container.");
}

void scene_event(void*,NotifyInfo*);
class HierarchyEvents final : public INodeEventCallback {
    void changed(NodeKeyTab& nodes)noexcept {
        try {
            for(auto* doc:documents) {
                auto* furniture_ref=doc->GetReference(1);auto* source_ref=doc->GetReference(2);auto* dependency_ref=doc->GetReference(4);auto* obstacle_ref=doc->GetReference(5);auto* path_ref=doc->GetReference(6);
                auto* furniture=furniture_ref?static_cast<IRefTargContainer*>(furniture_ref->GetInterface(IID_IREFTARG_CONTAINER)):nullptr;
                auto* source=source_ref?static_cast<IRefTargContainer*>(source_ref->GetInterface(IID_IREFTARG_CONTAINER)):nullptr;
                auto* dependency=dependency_ref?static_cast<IRefTargContainer*>(dependency_ref->GetInterface(IID_IREFTARG_CONTAINER)):nullptr;
                auto* obstacles=obstacle_ref?static_cast<IRefTargContainer*>(obstacle_ref->GetInterface(IID_IREFTARG_CONTAINER)):nullptr;
                auto* paths=path_ref?static_cast<IRefTargContainer*>(path_ref->GetInterface(IID_IREFTARG_CONTAINER)):nullptr;
                if(!furniture||!source||!dependency||!obstacles||!paths)continue;
                bool relevant=false;
                if(nodes.Count()>4096) {
                    for(auto* roots:{furniture,source,obstacles,paths}) {
                        for(int i=0;i<roots->GetNumItems();++i)if(auto* n=dynamic_cast<INode*>(roots->GetItem(i)))if(n->IsGroupHead()){relevant=true;break;}
                        if(relevant)break;
                    }
                } else for(int i=0;i<nodes.Count()&&!relevant;++i) {
                    auto* node=NodeEventNamespace::GetNodeByKey(nodes[i]);
                    if(node&&dependency->FindFirstItem(node)>=0&&doc->observes_current_input(node)){relevant=true;break;}
                    std::size_t depth=0;
                    for(auto* parent=node?node->GetParentNode():nullptr;parent&&depth++<4096;parent=parent->GetParentNode())
                        if(furniture->FindFirstItem(parent)>=0||source->FindFirstItem(parent)>=0||obstacles->FindFirstItem(parent)>=0||paths->FindFirstItem(parent)>=0){relevant=true;break;}
                }
                if(relevant)doc->observe_input_change(cache::Reason::DependencyChanged,DirtyGeometry,{DependencyOrigin::Hierarchy});
            }
        }catch(...){} // No scene mutation or exceptions from SDK event delivery.
    }
public:
    void LinkChanged(NodeKeyTab& nodes)override{changed(nodes);}
    void GroupChanged(NodeKeyTab& nodes)override{changed(nodes);}
    void HierarchyOtherEvent(NodeKeyTab& nodes)override{changed(nodes);}
} hierarchy_events;
VOID CALLBACK service_tick(HWND,UINT,UINT_PTR,DWORD) {
    try {process_live_updates();}catch(...){} // Never let an exception cross Win32.
}
void ensure_service() {
    main_thread();if(service_registered)return;
    service_stopped=false;service_registered=true;
    for(auto code:{NOTIFY_SYSTEM_PRE_RESET,NOTIFY_SYSTEM_POST_RESET,NOTIFY_SYSTEM_PRE_NEW,NOTIFY_SYSTEM_POST_NEW,
                  NOTIFY_FILE_PRE_OPEN,NOTIFY_FILE_POST_OPEN,NOTIFY_FILE_OPEN_FAILED,NOTIFY_FILE_PRE_SAVE,NOTIFY_FILE_POST_SAVE,
                  NOTIFY_SCENE_PRE_UNDO,NOTIFY_SCENE_PRE_REDO,NOTIFY_SCENE_UNDO,NOTIFY_SCENE_REDO,
                  NOTIFY_FILE_PRE_MERGE,NOTIFY_FILE_POST_MERGE_PROCESS_FINALIZED,
                  NOTIFY_PRE_RENDER,NOTIFY_POST_RENDER,NOTIFY_UNITS_CHANGE,NOTIFY_SYSTEM_SHUTDOWN})
        RegisterNotification(scene_event,nullptr,code);
    service_timer=SetTimer(nullptr,0,250,service_tick);
    if(auto* manager=GetISceneEventManager())hierarchy_callback_key=manager->RegisterCallback(&hierarchy_events,TRUE);
}
void scene_event(void*,NotifyInfo* info) {
    if(!info)return;
    switch(info->intcode) {
    case NOTIFY_SYSTEM_SHUTDOWN: stop_document_service();return;
    case NOTIFY_UNITS_CHANGE:
        invalidate_scene(cache::Reason::UnitsChanged,DirtyUnits);return;
    case NOTIFY_FILE_PRE_MERGE:case NOTIFY_FILE_POST_MERGE_PROCESS_FINALIZED:
        invalidate_scene(cache::Reason::SceneChanged);return;
    case NOTIFY_SYSTEM_PRE_RESET:case NOTIFY_SYSTEM_PRE_NEW:case NOTIFY_FILE_PRE_OPEN:
    case NOTIFY_SCENE_PRE_UNDO:case NOTIFY_SCENE_PRE_REDO:
        invalidate_scene(cache::Reason::SceneChanged);scene_suspended=true;return;
    case NOTIFY_FILE_PRE_SAVE:case NOTIFY_PRE_RENDER:
        scene_suspended=true;return;
    case NOTIFY_SYSTEM_POST_RESET:case NOTIFY_SYSTEM_POST_NEW:case NOTIFY_FILE_POST_OPEN:case NOTIFY_FILE_OPEN_FAILED:
    case NOTIFY_FILE_POST_SAVE:case NOTIFY_SCENE_UNDO:case NOTIFY_SCENE_REDO:case NOTIFY_POST_RENDER:
        scene_suspended=false;return;
    }
}
class LoadFinished final : public PostLoadCallback {
    SingleRefMaker lifetime_;Document* doc_;
public:
    explicit LoadFinished(Document* doc):doc_(doc){lifetime_.SetRef(doc);}
    int Priority()override{return 10;}
    void proc(ILoad*)override {try{doc_->finish_load();}catch(const std::exception& e){doc_->set_error(e.what());}catch(...){doc_->set_error("Arrange post-load validation failed.");}delete this;}
};
class CloneFinished final : public PostPatchProc {
    SingleRefMaker lifetime_;
    Document* target_;const Bindings original_bindings_;INode* owner_;
    const std::shared_ptr<const DocumentState> original_state_;
public:
    CloneFinished(Document* target,Bindings bindings,INode* owner):target_(target),original_bindings_(std::move(bindings)),owner_(owner),original_state_(target->state()){lifetime_.SetRef(target);}
    int Proc(RemapDir& remap)override {
        // Backpatch can run more than once during a host clone. Never feed an
        // already-remapped node back into FindMapping or use an earlier partial
        // pass (which cleared outputs) as the next pass's authored baseline.
        auto bindings=original_bindings_;
        for(auto* rows:{&bindings.furniture,&bindings.assets,&bindings.obstacles,&bindings.paths})for(auto*& node:*rows)
            if(node)if(auto* mapped=remap.FindMapping(node))node=dynamic_cast<INode*>(mapped);
        bool complete=true;
        for(auto*& node:bindings.outputs) {
            auto* mapped=node?remap.FindMapping(node):nullptr;
            if(!mapped){complete=false;break;}node=dynamic_cast<INode*>(mapped);if(!node){complete=false;break;}
        }
        auto next=std::make_shared<DocumentState>(*original_state_);
        if(!complete){next->placements.clear();next->composition_groups.clear();bindings.outputs.clear();}
        auto* mapped_owner=owner_?dynamic_cast<INode*>(remap.FindMapping(owner_)):nullptr;
        target_->finish_clone(next,bindings,mapped_owner);
        return TRUE;
    }
};

class OwnerAttribute final : public CustAttrib {
    RefTargetHandle document_{};
public:
    ~OwnerAttribute()override{DeleteAllRefsFromMe();}
    void DeleteThis()override{delete this;}
    Class_ID ClassID()override{return attr_id;}
    const MCHAR* GetName(bool)override{return _T("Cyrus Arrange setup");}
    void GetClassName(MSTR& value,bool=true)const override{value=_T("Cyrus Arrange setup owner");}
    int NumRefs()override{return 1;}
    RefTargetHandle GetReference(int i)override{return i==0?document_:nullptr;}
    void SetReference(int i,RefTargetHandle value)override{if(i==0)document_=value;}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
    RefTargetHandle Clone(RemapDir& remap)override {
        auto* result=new OwnerAttribute;
        if(document_)result->ReplaceReference(0,remap.CloneRef(document_));
        BaseClone(this,result,remap);return result;
    }
};
class Descriptor final : public ClassDesc2 {
    bool owner_;
public:
    explicit Descriptor(bool owner):owner_(owner){}
    int IsPublic()override{return FALSE;}
    void* Create(BOOL loading)override{return owner_?static_cast<void*>(new OwnerAttribute):static_cast<void*>(new Document(loading!=FALSE));}
    const MCHAR* ClassName()override{return owner_?_T("Cyrus Arrange Setup Owner"):_T("Cyrus Arrange Document");}
    const MCHAR* NonLocalizedClassName()override{return ClassName();}
    SClass_ID SuperClassID()override{return owner_?CUST_ATTRIB_CLASS_ID:REF_TARGET_CLASS_ID;}
    Class_ID ClassID()override{return owner_?attr_id:doc_id;}
    const MCHAR* Category()override{return _T("Cyrus Arrange");}
    const MCHAR* InternalName()override{return owner_?_T("CyrusArrangeSetupOwner"):_T("CyrusArrangeDocument");}
    HINSTANCE HInstance()override{return document_module;}
};
} // namespace

class CommandDependencyWatch final : public ReferenceMaker {
    Document& document_;
    RefTargetHandle reference_{};
    bool filling_{true},closing_{};
public:
    explicit CommandDependencyWatch(Document& doc):document_(doc) {
        HoldSuspension suspend;
        try {
            const auto expected_state=doc.state();const auto dependencies=doc.dependency_ticket();
            const auto bindings=doc.bindings();
            auto* owner=doc.owner();
            std::set<INode*> owner_ancestors;
            for(auto* ancestor=owner;ancestor;ancestor=ancestor->GetParentNode()) {
                if(owner_ancestors.size()>=max_dependency_nodes||!owner_ancestors.insert(ancestor).second)
                    throw std::runtime_error("Arrange setup ancestry exceeds 8,192 nodes or contains a cycle.");
            }
            const std::set<INode*> outputs(bindings.outputs.begin(),bindings.outputs.end());
            struct PendingInput {INode* identity;AnimHandle handle;};
            std::vector<PendingInput> pending;std::set<ULONG> queued;
            const auto enqueue=[&](INode* node) {
                if(!node)return;
                // The Document->watch edge is intentionally not serialized as
                // a Max reference. Reject hidden self/owner cycles explicitly,
                // including an owner nested under an input group. TestForLoop
                // covers other pre-existing native reference paths to Document.
                if(owner_ancestors.contains(node))
                    throw std::runtime_error("Arrange setup and its ancestors cannot be input dependencies; move the setup outside input groups.");
                if(outputs.contains(node)||!queued.insert(node->GetHandle()).second)return;
                if(queued.size()>max_dependency_nodes)throw std::runtime_error("Command input dependencies exceed 8,192 nodes.");
                pending.push_back({node,Animatable::GetHandleByAnim(node)});
            };
            for(const auto* roots:{&bindings.furniture,&bindings.assets,&bindings.obstacles,&bindings.paths})for(auto* node:*roots)enqueue(node);
            auto* created=IRefTargContainer::CreateInstance();
            if(!created)throw std::runtime_error("Cannot allocate the Arrange command input observer.");
            const auto release=[](IRefTargContainer* p){if(p)p->DeleteThis();};
            std::unique_ptr<IRefTargContainer,decltype(release)> staging(created,release);
            // A silent native lifetime anchor owns the unobserved container;
            // it does not forward its insertion messages to Document.
            SingleRefMaker staging_lifetime;staging_lifetime.SetRef(created);staging.release();
            std::vector<INode*> observed;
            while(!pending.empty()) {
                const auto input=pending.back();pending.pop_back();
                // Previous SDK calls may synchronously invoke dependents.
                // Resolve the non-owning queue identity before dereferencing;
                // then keep a native lifetime through cycle/reference checks.
                auto* node=dynamic_cast<INode*>(Animatable::GetAnimByHandle(input.handle));
                if(!node||node!=input.identity)throw std::runtime_error("Arrange command input disappeared during observer staging.");
                SingleRefMaker node_lifetime;node_lifetime.SetRef(node);
                if(node_lifetime.GetRef()!=node||doc.state()!=expected_state||!doc.dependencies_unchanged(dependencies))
                    throw std::runtime_error("Arrange inputs changed before observer reference staging.");
                // SUCCEED means this reference is admissible. The 2027
                // ReferenceTarget/ref.h return-value sentence says the reverse,
                // contradicting both REFMSG_LOOPTEST documentation and shipped
                // controllers/attach.cpp, path_cnstrnt.cpp and link_cnstrnt.cpp.
                // SDK maxscript/mxsagni/avg_dlx.cpp's dependencyLoopTest returns
                // true specifically for TestForLoop==REF_FAIL. Follow the
                // executable SDK examples; reject every non-success result.
                if(node->TestForLoop(FOREVER,&doc)!=REF_SUCCEED)
                    throw std::runtime_error("Arrange input observation would create a native reference cycle.");
                if(node_lifetime.GetRef()!=node||doc.state()!=expected_state||!doc.dependencies_unchanged(dependencies))
                    throw std::runtime_error("Arrange inputs changed during observer cycle validation.");
                // Max emits REFMSG_CHANGE/PART_ALL as well as structural
                // messages when inserting items. Fully stage the container
                // before this ReferenceMaker subscribes, so own insertion is
                // not mistaken for an upstream edit. Persistent Document
                // references and the already-active command still observe
                // genuine input changes; their epochs are never reset.
                const auto index=created->GetNumItems();created->AppendItem(node);
                if(index<0||created->GetNumItems()!=index+1||created->GetItem(index)!=node||node_lifetime.GetRef()!=node||
                   doc.state()!=expected_state||!doc.dependencies_unchanged(dependencies))
                    throw std::runtime_error("Arrange input disappeared or changed while appending the current observer.");
                observed.push_back(node);
                if(node->IsGroupHead()) {
                    const int count=node->NumberOfChildren();
                    if(count<0||static_cast<std::size_t>(count)>max_dependency_nodes)
                        throw std::runtime_error("Command input expansion exceeds 8,192 pending nodes.");
                    for(int i=0;i<count;++i)enqueue(node->GetChildNode(i));
                }
            }
            if(doc.state()!=expected_state||!doc.dependencies_unchanged(dependencies))
                throw std::runtime_error("Arrange inputs changed while staging the command observer; previous result retained.");
            if(ReplaceReference(0,created)!=REF_SUCCEED)throw std::runtime_error("Cannot bind the Arrange command input observer.");
            if(created->GetNumItems()!=static_cast<int>(observed.size()))throw std::runtime_error("Arrange command observer reference count changed during staging.");
            for(std::size_t i=0;i<observed.size();++i)if(created->GetItem(static_cast<int>(i))!=observed[i])
                throw std::runtime_error("Arrange command observer input disappeared during staging.");
            if(doc.state()!=expected_state||!doc.dependencies_unchanged(dependencies))
                throw std::runtime_error("Arrange inputs changed while binding the command observer; previous result retained.");
            filling_=false;
        }catch(...){closing_=true;DeleteAllRefsFromMe();throw;}
    }
    ~CommandDependencyWatch()override {
        closing_=true;HoldSuspension suspend;DeleteAllRefsFromMe();
    }
    int NumRefs()override{return 1;}
    bool contains(RefTargetHandle target)const noexcept {
        if(!target||!reference_||filling_||closing_)return false;
        auto* container=static_cast<IRefTargContainer*>(reference_->GetInterface(IID_IREFTARG_CONTAINER));
        return container&&container->FindFirstItem(target)>=0;
    }
    RefTargetHandle GetReference(int i)override{return i==0?reference_:nullptr;}
    void SetReference(int i,RefTargetHandle value)override{if(i==0)reference_=value;}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle target,PartID& part,RefMessage message,BOOL)override {
        if(closing_||!input_message(message,part))return REF_SUCCEED;
        if(filling_&&structural_container_message(message))return REF_SUCCEED;
        DependencyEventDetail event{DependencyOrigin::CommandWatch};event.message=message;event.part=part;
        event.constructing=filling_;
        event.sender=reinterpret_cast<std::uintptr_t>(target);event.actual_sender=event.sender;
        // Changed-item accessors are borrowed for this notification only.
        if(target==reference_&&reference_) {
            auto* container=static_cast<IRefTargContainer*>(reference_->GetInterface(IID_IREFTARG_CONTAINER));
            if(container) {
                auto* changed=container->GetChangedRefTarget();const auto index=container->GetChangedRefTargetIndex();
                event.actual_sender=reinterpret_cast<std::uintptr_t>(changed);event.changed_index=index;
                // Read actual sender while valid. A removed/nulled item may no
                // longer be present; missing payloads invalidate conservatively.
                if(changed&&index>=0&&index<container->GetNumItems()&&message==REFMSG_CHANGE&&
                   container->GetItem(index)!=changed&&container->FindFirstItem(changed)<0) {
                    document_.observe_input_change(cache::Reason::DependencyChanged,DirtyGeometry,event);
                    return REF_SUCCEED;
                }
            }
        }
        if(message==REFMSG_TARGET_DELETED&&target==reference_)reference_=nullptr;
        document_.observe_input_change(cache::Reason::DependencyChanged,input_dirty(part,message),event);
        return REF_SUCCEED;
    }
};

DependencyCommandScope::DependencyCommandScope(Document& doc):document_(&doc) {
    main_thread();
    if(doc.active_command_)throw std::runtime_error("An Arrange command is already active for this setup; reentrant commands are not supported.");
    doc.drain_input_watch();doc.drain_deferred_dirty();drain_geometry_cache();
    if(doc.next_command_serial_!=std::numeric_limits<std::uint64_t>::max())++doc.next_command_serial_;
    serial_=doc.next_command_serial_;doc.active_command_=this;
    try {
        const auto expected_state=doc.state();const auto dependencies=doc.dependency_ticket();
        auto staged=std::make_unique<CommandDependencyWatch>(doc);
        if(doc.state()!=expected_state||!doc.dependencies_unchanged(dependencies))
            throw std::runtime_error("Arrange inputs changed before publishing the current input observer; previous result retained.");
        // Both the old watcher and persistent references stayed subscribed
        // during staging. The new complete observer survives this scope,
        // including Preview-only commands that never refresh refs_[4].
        doc.input_watch_.swap(staged);doc.input_watch_retired_=false;
    }
    catch(...){doc.active_command_=nullptr;doc.drain_input_watch();doc.drain_deferred_dirty();throw;}
}
DependencyCommandScope::~DependencyCommandScope()noexcept {
    if(document_&&document_->active_command_==this) {
        document_->active_command_=nullptr;
        document_->drain_input_watch();
        document_->drain_deferred_dirty();
    }
}

class StateRestore final : public RestoreObj {
    SingleRefMaker lifetime_;Document* document_;
    std::shared_ptr<const DocumentState> before_,after_;
    std::shared_ptr<BoundReferences> before_refs_,after_refs_;
    Lifecycle before_lifecycle_,after_lifecycle_;
    bool cancelled_{};
public:
    StateRestore(Document& doc,std::shared_ptr<const DocumentState> next,std::shared_ptr<BoundReferences> before_refs,
                 std::shared_ptr<BoundReferences> after_refs,Lifecycle after_lifecycle):document_(&doc),before_(doc.state()),after_(std::move(next)),
                 before_refs_(std::move(before_refs)),after_refs_(std::move(after_refs)),before_lifecycle_(doc.lifecycle()),after_lifecycle_(std::move(after_lifecycle)) {
        before_lifecycle_.updating=false;after_lifecycle_.updating=false;lifetime_.SetRef(&doc);
    }
    void cancel()noexcept{cancelled_=true;}
    void apply(bool after) {
        document_->restoring_=true;
        try {apply_bound(*document_,*(after&&!cancelled_?after_refs_:before_refs_));
             document_->restore_state(after&&!cancelled_?after_:before_,after&&!cancelled_?after_lifecycle_:before_lifecycle_);}
        catch(...){document_->restoring_=false;throw;}
        document_->restoring_=false;document_->drain_input_watch();
    }
    void Restore(int)override{apply(false);}
    void Redo()override{apply(true);}
    int Size()override {
        std::size_t total=sizeof(*this);
        for(const auto* state:{before_.get(),after_.get()}) {
            total+=state->placements.size()*sizeof(Placement);
            for(const auto& asset:state->assets)total+=asset.mesh.vertices.size()*sizeof(Vec3)+asset.mesh.triangles.size()*sizeof(Triangle);
        }
        return static_cast<int>(std::min<std::size_t>(total,std::numeric_limits<int>::max()));
    }
    MSTR Description()override{return _T("Cyrus Arrange native setup");}
};

Document::Document(bool loading) {
    main_thread();if(documents.size()>=max_documents)throw std::runtime_error("At most 512 native Arrange documents may be resident.");
    geometry_instance_=reserve_geometry_instance();dependency_time_=GetCOREInterface()->GetTime();
    auto value=std::make_shared<DocumentState>();if(!loading){value->document_id=guid();value->arrangement.edge_clearance_mm=0;}state_=std::move(value);
    try {if(!loading)initialize_references();ensure_service();documents.insert(this);GetCOREInterface()->RegisterTimeChangeCallback(this);}
    catch(...){DeleteAllRefsFromMe();documents.erase(this);throw;}
    initializing_=loading;
}
Document::~Document(){initializing_=true;input_watch_.reset();defer_geometry_cache_document(geometry_instance_,cache::Reason::OwnerRemoved);documents.erase(this);if(!service_stopped)GetCOREInterface()->UnRegisterTimeChangeCallback(this);DeleteAllRefsFromMe();}
void Document::DeleteThis(){delete this;}
Class_ID Document::ClassID(){return doc_id;}
SClass_ID Document::SuperClassID(){return REF_TARGET_CLASS_ID;}
void Document::GetClassName(MSTR& value,bool)const{value=_T("Cyrus Arrange native document");}
int Document::NumRefs(){return 7;}
RefTargetHandle Document::GetReference(int i){return i>=0&&i<7?refs_[i]:nullptr;}
void Document::SetReference(int i,RefTargetHandle value){if(i>=0&&i<7)refs_[i]=value;}
void Document::initialize_references() {
    if(!refs_[0]) {
        auto* monitor=static_cast<ReferenceTarget*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,NODEMONITOR_CLASS_ID));
        if(!monitor||ReplaceReference(0,monitor)!=REF_SUCCEED)throw std::runtime_error("Cannot allocate Arrange owner monitor.");
    }
    for(int i=1;i<7;++i)if(!refs_[i]) {
        auto* container=IRefTargContainer::CreateInstance();
        if(!container||ReplaceReference(i,container)!=REF_SUCCEED)throw std::runtime_error("Cannot allocate Arrange node-reference container.");
    }
}
IRefTargContainer* Document::container(int group)const {
    if(group<0||group>4)return nullptr;
    auto* value=refs_[group>=3?group+2:group+1];
    return value?static_cast<IRefTargContainer*>(value->GetInterface(IID_IREFTARG_CONTAINER)):nullptr;
}
Bindings Document::bindings()const {
    main_thread();Bindings result;
    std::vector<INode*>* groups[]={&result.furniture,&result.assets,&result.outputs,&result.obstacles,&result.paths};
    const std::size_t limits[]={max_furniture_nodes,max_document_assets,max_document_placements,max_obstacle_nodes,1};
    for(int group=0;group<5;++group)if(auto* source=container(group)) {
        const int count=source->GetNumItems();const std::size_t limit=limits[group];
        if(count<0||static_cast<std::size_t>(count)>limit)throw std::runtime_error("Arrange reference container exceeds admission.");
        groups[group]->reserve(static_cast<std::size_t>(count));
        for(int i=0;i<count;++i) {
            auto* item=source->GetItem(i);auto* node=dynamic_cast<INode*>(item);
            if(item&&!node)throw std::runtime_error("Arrange saved reference is not a scene node.");groups[group]->push_back(node);
        }
    }
    return result;
}
INode* Document::owner()const {
    if(!refs_[0])return nullptr;
    auto* monitor=static_cast<INodeMonitor*>(refs_[0]->GetInterface(IID_NODEMONITOR));return monitor?monitor->GetNode():nullptr;
}
void Document::bind_owner(INode* node) {
    main_thread();initialize_references();auto* monitor=static_cast<INodeMonitor*>(refs_[0]->GetInterface(IID_NODEMONITOR));
    if(!monitor)throw std::runtime_error("Arrange owner monitor is unavailable.");
    if(monitor->GetNode()!=node)observe_input_change(cache::Reason::OwnerRemoved,DirtyNone,{DependencyOrigin::Owner});
    monitor->SetNode(node);
}
RefResult Document::NotifyRefChanged(const Interval&,RefTargetHandle target,PartID& part,RefMessage message,BOOL) {
    bool input=false,output=false;
    DependencyEventDetail event{DependencyOrigin::Reference};event.message=message;event.part=part;
    event.sender=reinterpret_cast<std::uintptr_t>(target);event.actual_sender=event.sender;
    const bool owner_event=message==REFMSG_NODEMONITOR_TARGET_DELETED||message==REFMSG_NODEMONITOR_TARGET_SET||
        (target==refs_[0]&&message==REFMSG_TARGET_DELETED);
    if(owner_event){auto owner_detail=event;owner_detail.origin=DependencyOrigin::Owner;owner_detail.role_mask=1;observe_input_change(cache::Reason::OwnerRemoved,DirtyMissingBinding,owner_detail);}
    if(input_message(message,part)) {
        RefTargetHandle actual_sender=target;
        for(int i=1;i<7;++i)if(target&&target==refs_[i]) {
            auto* sender=static_cast<IRefTargContainer*>(target->GetInterface(IID_IREFTARG_CONTAINER));
            if(sender){event.changed_index=sender->GetChangedRefTargetIndex();if(auto* changed=sender->GetChangedRefTarget())actual_sender=changed;}
            break;
        }
        for(int i=1;i<7;++i)if(refs_[i]) {
            auto* container=static_cast<IRefTargContainer*>(refs_[i]->GetInterface(IID_IREFTARG_CONTAINER));
            if(!container)continue;
            bool matched=target==refs_[i];
            if(matched) {
                // SDK values are valid only in this callback. Structural
                // bookkeeping is distinguished from forwarded source events.
                auto* changed=container->GetChangedRefTarget();
                if(changed)actual_sender=changed;
                // A real current/deleted item is an input event even during
                // updating. An unknown payload remains conservative; only our
                // structural install messages are ignored. actual_sender is
                // also used to resolve its other native input/output roles.
            } else if(actual_sender)matched=container->FindFirstItem(actual_sender)>=0;
            if(!matched)continue;
            // refs_[4] is the last authored expansion and may contain a child
            // detached before a Preview-only refresh. A complete current
            // observer supersedes that known descendant membership only.
            // Missing/unknown payloads and all root roles stay conservative.
            if(i==4&&actual_sender&&actual_sender!=refs_[4]&&!observes_current_input(actual_sender))continue;
            event.role_mask|=std::uint32_t{1}<<i;
            if(i==3)output=true;else input=true;
        }
        event.actual_sender=reinterpret_cast<std::uintptr_t>(actual_sender);
        const bool bookkeeping=installing_bindings_&&structural_container_message(message);
        if(input&&!bookkeeping)observe_input_change(cache::Reason::DependencyChanged,input_dirty(part,message),event);
    }
    if(message==REFMSG_TARGET_DELETED)for(auto& reference:refs_)if(reference==target)reference=nullptr;
    if(output&&!input&&active_command_&&!lifecycle_.updating&&!restoring_&&!initializing_) {
        const auto dirty=input_dirty(part,message);
        if(dirty) {
            // A real edit of existing managed output before publication is
            // pending user work. Own output publication remains suppressed;
            // numeric furniture/query geometry does not change in either case.
            const auto before=dependency_epoch_.value;dependency_epoch_.invalidate();event.origin=DependencyOrigin::Output;
            record_dependency_failure(cache::Reason::DependencyChanged,event,geometry_epoch_.value,before);
            deferred_input_dirty_|=DirtyOutput|(dirty&DirtyMissingBinding);
        }
    }
    if(initializing_||restoring_||lifecycle_.updating||active_command_)return REF_SUCCEED;
    if(output&&!input) {
        if(message==REFMSG_CONTAINER_ELEMENT_NULLED||message==REFMSG_TARGET_DELETED)
            mark_dirty(DirtyMissingBinding|DirtyOutput,"A managed output was deleted; previous result retained.");
        else if(message==REFMSG_CHANGE&&(part&(PART_GEOM|PART_TOPO|PART_TM|PART_OBJECT_TYPE)))
            mark_dirty(DirtyOutput,"Managed output changed; lock edited objects before updating.");
    }
    return REF_SUCCEED;
}
cache::Ticket Document::geometry_ticket()const noexcept {
    return cache::Ticket::make(geometry_instance_,scene_epoch,geometry_epoch_);
}
CommandDependencyTicket Document::dependency_ticket()const noexcept {
    return {geometry_instance_,scene_epoch.value,dependency_epoch_.value,active_command_?active_command_->serial_:0,active_command_};
}
bool Document::dependencies_unchanged(const CommandDependencyTicket& ticket)const noexcept {
    return active_command_&&ticket.scope==active_command_&&!active_command_->invalidated_&&
        ticket.document_instance==geometry_instance_&&ticket.scene==scene_epoch.value&&
        ticket.dependency==dependency_epoch_.value&&ticket.command_serial==active_command_->serial_;
}
void Document::record_dependency_failure(cache::Reason reason,DependencyEventDetail event,std::uint64_t geometry_before,std::uint64_t dependency_before)noexcept {
    if(!active_command_||active_command_->invalidated_)return;
    active_command_->first_={event,reason,geometry_before,geometry_epoch_.value,dependency_before,dependency_epoch_.value,
        lifecycle_.updating,restoring_,initializing_,installing_bindings_!=0};
    active_command_->invalidated_=true;
}
void Document::observe_input_change(cache::Reason reason,std::uint32_t dirty,DependencyEventDetail event)noexcept {
    if(reason==cache::Reason::SceneChanged||reason==cache::Reason::OwnerRemoved||
       event.origin==DependencyOrigin::Hierarchy||event.message==REFMSG_NODE_LINK)input_watch_retired_=true;
    const auto geometry_before=geometry_epoch_.value,dependency_before=dependency_epoch_.value;
    geometry_epoch_.invalidate();dependency_epoch_.invalidate();
    record_dependency_failure(reason,event,geometry_before,dependency_before);
    defer_geometry_cache_document(geometry_instance_,reason);
    if(!dirty||initializing_)return;
    if(active_command_||lifecycle_.updating||restoring_)deferred_input_dirty_|=dirty;
    else mark_dirty(dirty,"Scene inputs changed. Generate to refresh placements.");
}
bool Document::observes_current_input(RefTargetHandle sender)const noexcept {
    return !input_watch_||input_watch_retired_||input_watch_->contains(sender);
}
void Document::drain_input_watch()noexcept {
    if(active_command_||lifecycle_.updating||restoring_||initializing_)return;
    try {
        const bool attached=owns_document(owner(),this);
        if(!attached) {
            if(!input_owner_detached_)observe_input_change(cache::Reason::OwnerRemoved,DirtyNone,{DependencyOrigin::Owner});
            input_owner_detached_=true;input_watch_retired_=true;lifecycle_.live_armed=false;
        } else input_owner_detached_=false;
        // Never release SDK references in a notification. Replaced bindings,
        // Undo/Redo, scene/owner changes only mark retirement until this point.
        if(input_watch_retired_)input_watch_.reset();
    }catch(...) {
        // Failed ownership inspection cannot make an observer authoritative or
        // re-arm a detached owner. Keep references until the next safe boundary.
        input_watch_retired_=true;lifecycle_.live_armed=false;
    }
}
std::string Document::dependency_failure_detail(const CommandDependencyTicket& ticket)const {
    std::ostringstream out;
    out<<" [dependency instance="<<geometry_instance_<<" scene="<<ticket.scene<<"->"<<scene_epoch.value
       <<" epoch="<<ticket.dependency<<"->"<<dependency_epoch_.value<<" command="<<ticket.command_serial
       <<" scope="<<(ticket.scope==active_command_?"same":"different");
    if(active_command_&&active_command_->invalidated_) {
        const auto& first=active_command_->first_;const auto& event=first.event;
        const char* origin="other";
        switch(event.origin){case DependencyOrigin::Reference:origin="reference";break;case DependencyOrigin::CommandWatch:origin="commandWatch";break;
        case DependencyOrigin::Hierarchy:origin="hierarchy";break;case DependencyOrigin::Time:origin="time";break;case DependencyOrigin::Scene:origin="scene";break;
        case DependencyOrigin::Restore:origin="restore";break;case DependencyOrigin::Owner:origin="owner";break;case DependencyOrigin::Output:origin="output";break;default:break;}
        out<<" first="<<origin<<" reason="<<static_cast<std::uint32_t>(first.reason)<<" message=0x"<<std::hex<<event.message
           <<" part=0x"<<event.part<<" roles=0x"<<event.role_mask<<" sender=0x"<<event.sender<<" actual=0x"<<event.actual_sender
           <<std::dec<<" index="<<event.changed_index<<" geometry="<<first.geometry_before<<"->"<<first.geometry_after
           <<" dependency="<<first.dependency_before<<"->"<<first.dependency_after<<" updating="<<first.updating
           <<" restoring="<<first.restoring<<" initializing="<<first.initializing<<" installing="<<first.installing
           <<" constructing="<<event.constructing;
    }else out<<" first=none";
    out<<"]";return out.str();
}
void Document::drain_deferred_dirty()noexcept {
    if(active_command_||lifecycle_.updating||restoring_||initializing_||!deferred_input_dirty_)return;
    const auto dirty=deferred_input_dirty_;deferred_input_dirty_=0;
    mark_dirty(dirty,"Scene inputs changed during an Arrange command; update again.");
}
void Document::set_updating(bool value)noexcept {
    lifecycle_.updating=value;
    if(!value){drain_input_watch();drain_deferred_dirty();}
}
void Document::mark_dirty(std::uint32_t reason,const char* message)noexcept {
    lifecycle_.dirty|=reason;if(lifecycle_.input_epoch<std::numeric_limits<std::uint64_t>::max())++lifecycle_.input_epoch;
    lifecycle_.composition_stats.reset();
    if(message)try{lifecycle_.error=message;}catch(...){}
}
void Document::set_error(const std::string& value){lifecycle_.error=value;}
void Document::mark_clean(TimeValue time,const Interval& validity)noexcept {
    // Caller explicitly flushes and checks its dependency ticket before Accept.
    // Deferred genuine input edits live outside Lifecycle and are not cleared.
    lifecycle_.dirty=DirtyNone;lifecycle_.error.clear();input_validity_=validity;valid_capture_time_=time;
    lifecycle_.live_armed=state_->live;lifecycle_.attempted_epoch=0;
}
void Document::TimeChanged(TimeValue time) {
    if(time==dependency_time_)return;
    dependency_time_=time;
    const bool relevant=!state_->placements.empty()&&!input_validity_.InInterval(time)&&time!=valid_capture_time_;
    observe_input_change(cache::Reason::TimeChanged,relevant?DirtyTime:DirtyNone,{DependencyOrigin::Time});
}
void Document::restore_state(std::shared_ptr<const DocumentState> value,const Lifecycle& lifecycle)noexcept {
    observe_input_change(cache::Reason::SceneChanged,DirtyNone,{DependencyOrigin::Restore});
    state_=std::move(value);
    try{lifecycle_=lifecycle;}catch(...){lifecycle_.dirty|=DirtyAuthored;}
    // Command diagnostics are transient. Undo/Redo restores authored state and
    // dirty flags, never an error from a rejected draft before a later success.
    lifecycle_.error.clear();
    input_validity_=NEVER;
    try{NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE);}catch(...){lifecycle_.dirty|=DirtyAuthored;}
}
std::uint64_t Document::reserve_ids(std::size_t count) {
    main_thread();if(!count||count>max_document_placements||count>std::numeric_limits<std::uint64_t>::max()-id_high_water_)
        throw std::runtime_error("Arrange stable identity reservation exceeds admission.");
    const auto first=id_high_water_;id_high_water_+=count;return first;
}
void Document::commit(std::shared_ptr<const DocumentState> next,const Bindings& next_bindings,const MCHAR* label,bool published) {
    main_thread();
    if(committing_)throw std::runtime_error("Reentrant Arrange state commits are not supported.");
    committing_=true;struct CommitReset {bool& value;~CommitReset(){value=false;}} reset{committing_};
    const auto expected_state=state_;
    if(!next)throw std::runtime_error("Missing Arrange successor.");validate_document_state(*next);
    if(next->document_id!=state_->document_id)throw std::runtime_error("Arrange successor belongs to a different setup.");
    if(next_bindings.furniture.size()!=next->furniture_count||next_bindings.assets.size()!=next->assets.size()||next_bindings.outputs.size()!=next->placements.size()||next_bindings.obstacles.size()!=next->obstacle_count||next_bindings.paths.size()!=(next->path?1u:0u))
        throw std::runtime_error("Arrange authored state and reference counts disagree.");
    auto* setup=owner();std::set<INode*> furniture,assets,outputs,obstacles;
    for(auto* node:next_bindings.furniture)if(node&&(node==setup||!furniture.insert(node).second))throw std::runtime_error("Furniture bindings include the setup or duplicates.");
    for(auto* node:next_bindings.assets)if(node&&node==setup)throw std::runtime_error("The setup cannot be its own source.");
    for(auto* node:next_bindings.outputs)if(node&&(node==setup||furniture.contains(node)||!outputs.insert(node).second))throw std::runtime_error("Output bindings include the setup, furniture or duplicate nodes.");
    for(auto* node:next_bindings.assets)if(node&&outputs.contains(node))throw std::runtime_error("An output cannot also be an asset source.");
    for(auto* node:next_bindings.obstacles)if(node&&(node==setup||furniture.contains(node)||outputs.contains(node)||!obstacles.insert(node).second))throw std::runtime_error("Obstacle bindings include the setup, furniture, output or duplicate nodes.");
    for(auto* node:next_bindings.paths)if(node&&(node==setup||furniture.contains(node)||outputs.contains(node)||obstacles.contains(node)||std::find(next_bindings.assets.begin(),next_bindings.assets.end(),node)!=next_bindings.assets.end()))throw std::runtime_error("Path binding overlaps another arrangement role.");
    auto before_refs=bound_from_document(*this);auto after_refs=stage_bindings(next_bindings);
    if(state_!=expected_state)throw std::runtime_error("Arrange state changed while staging its successor; previous result retained.");
    Lifecycle after=lifecycle_;after.error.clear();after.updating=false;after.composition_stats.reset();
    if(after.input_epoch<std::numeric_limits<std::uint64_t>::max())++after.input_epoch;
    after.attempted_epoch=0;
    if(published){after.dirty=DirtyNone;after.live_armed=next->live;}
    else after.dirty|=DirtyAuthored;
    auto restore=std::make_unique<StateRestore>(*this,next,before_refs,after_refs,after);
    const bool own_hold=!theHold.Holding();if(own_hold)theHold.Begin();
    auto* raw=restore.get();
    try {
        if(!theHold.Put(raw))throw std::runtime_error("Cannot register Arrange Undo state.");restore.release();
        // The new durable expansion takes over after publication. During an
        // active command the transient observer remains subscribed through
        // final guards and Accept/Cancel; only safe unwind releases it.
        input_watch_retired_=true;restoring_=true;apply_bound(*this,*after_refs);
        if(state_!=expected_state)throw std::runtime_error("Arrange state changed during reference publication; previous result retained.");
        state_=std::move(next);lifecycle_=std::move(after);
        id_high_water_=std::max(id_high_water_,state_->next_id);restoring_=false;
        if(published){input_validity_=NEVER;valid_capture_time_=state_->capture_time;}
        NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE);
        if(own_hold)theHold.Accept(label?label:_T("Cyrus Arrange setup"));
        drain_input_watch();
    } catch(...) {
        restoring_=false;
        if(!restore){raw->cancel();try{raw->apply(false);}catch(...){}}
        if(own_hold)theHold.Cancel();throw;
    }
}
void Document::install_bindings(const Bindings& bindings){auto staged=stage_bindings(bindings);apply_bound(*this,*staged);}
void Document::finish_clone(std::shared_ptr<const DocumentState> next,const Bindings& refs,INode* mapped_owner) {
    main_thread();validate_document_state(*next);restoring_=true;
    observe_input_change(cache::Reason::SceneChanged);
    try{install_bindings(refs);state_=std::move(next);bind_owner(mapped_owner);}
    catch(...){restoring_=false;throw;}
    restoring_=false;lifecycle_.live_armed=false;
    mark_dirty(DirtyCloned,"Cloned arrangement. Generate its own placements.");
}
RefTargetHandle Document::Clone(RemapDir& remap) {
    main_thread();auto* result=new Document;
    try {
        auto value=std::make_shared<DocumentState>(*state_);value->document_id=guid();result->state_=std::move(value);
        result->id_high_water_=id_high_water_;result->install_bindings(bindings());
        BaseClone(this,result,remap);
        remap.AddPostPatchProc(new CloneFinished(result,bindings(),owner()),true);
        result->mark_dirty(DirtyCloned);result->lifecycle_.live_armed=false;return result;
    } catch(...){result->DeleteThis();throw;}
}
IOResult Document::Save(ISave* save) {
    try {
        auto bytes=encode_document_state(*state_,id_high_water_);save->BeginChunk(state_chunk);ULONG written=0;
        const auto code=save->Write(bytes.data(),static_cast<ULONG>(bytes.size()),&written);save->EndChunk();
        return code==IO_OK&&written==bytes.size()?IO_OK:IO_ERROR;
    }catch(...){return IO_ERROR;}
}
IOResult Document::Load(ILoad* load) {
    bool found=false;IOResult status;
    try {
        while((status=load->OpenChunk())==IO_OK) {
            if(load->CurChunkID()==state_chunk) {
                if(found||load->CurChunkLength()>max_document_bytes)return IO_ERROR;found=true;
                std::vector<std::uint8_t> bytes(static_cast<std::size_t>(load->CurChunkLength()));ULONG read=0;
                if(load->Read(bytes.data(),static_cast<ULONG>(bytes.size()),&read)!=IO_OK||read!=bytes.size())return IO_ERROR;
                state_=decode_document_state(bytes,id_high_water_);
            }
            load->CloseChunk();
        }
        if(status!=IO_END||!found)return IO_ERROR;
        load->RegisterPostLoadCallback(new LoadFinished(this));return IO_OK;
    }catch(...){return IO_ERROR;}
}
void Document::finish_load() {
    main_thread();initialize_references();validate_document_state(*state_);
    observe_input_change(cache::Reason::SceneChanged);last_cache_command_.reset();
    const auto refs=bindings();
    auto* dependency=refs_[4]?static_cast<IRefTargContainer*>(refs_[4]->GetInterface(IID_IREFTARG_CONTAINER)):nullptr;
    if(!dependency||dependency->GetNumItems()<0||dependency->GetNumItems()>static_cast<int>(max_dependency_nodes))
        throw std::runtime_error("Saved Arrange furniture/asset/obstacle dependency count exceeds admission.");
    if(refs.furniture.size()!=state_->furniture_count||refs.assets.size()!=state_->assets.size()||refs.outputs.size()!=state_->placements.size()||refs.obstacles.size()!=state_->obstacle_count||refs.paths.size()!=(state_->path?1u:0u))
        throw std::runtime_error("Saved Arrange state/reference counts disagree; rebuild explicitly.");
    for(auto* other:documents)if(other!=this&&other->owner()&&other->state()->document_id==state_->document_id) {
        auto unique=std::make_shared<DocumentState>(*state_);unique->document_id=guid();state_=std::move(unique);break;
    }
    initializing_=false;lifecycle_.live_armed=false;mark_dirty(DirtyLoaded,"Scene loaded. Generate to refresh placement checks.");
}

Document* initialize_setup(INode* owner) {
    main_thread();
    auto* base=owner&&owner->GetObjectRef()?owner->GetObjectRef()->FindBaseObject():nullptr;
    if(!base||base->ClassID()!=arrange_icon_class_id())
        throw std::runtime_error("Choose a Cyrus Arrange scene icon.");
    if(auto* existing=get_document(owner,false))return existing;
    const bool own_hold=!theHold.Holding();if(own_hold)theHold.Begin();
    try {
        owner->SetUserPropBool(_T("CyrusArrangeSetup"),TRUE);owner->SetWireColor(RGB(40,180,220));owner->SetRenderable(FALSE);
        add_arrange_modifier(owner);
        owner->AllocCustAttribContainer();auto* attributes=owner->GetCustAttribContainer();
        if(!attributes)throw std::runtime_error("Cannot allocate Arrange setup attributes.");
        const auto delete_attribute=[](OwnerAttribute* value){if(value)value->DeleteThis();};
        const auto delete_document=[](Document* value){if(value)value->DeleteThis();};
        std::unique_ptr<OwnerAttribute,decltype(delete_attribute)> attribute(new OwnerAttribute,delete_attribute);
        std::unique_ptr<Document,decltype(delete_document)> document(new Document,delete_document);
        auto* document_pointer=document.get();
        if(attribute->ReplaceReference(0,document.get())!=REF_SUCCEED)throw std::runtime_error("Cannot anchor Arrange native document.");
        document.release();
        if(!attributes->AppendCustAttrib(attribute.get()))throw std::runtime_error("Cannot attach Arrange setup owner.");
        attribute.release();document_pointer->bind_owner(owner);
        auto initial=std::make_shared<DocumentState>(*document_pointer->state());
        initial->arrangement.amount_mode=AmountMode::Quantity;initial->arrangement.quantity=100;
        initial->inspection.minimum_clearance_mm=1;initial->inspection.maximum_slope_degrees=0;
        document_pointer->commit(initial,document_pointer->bindings(),_T("Initialize Cyrus Arrange"));
        if(own_hold)theHold.Accept(_T("Initialize Cyrus Arrange"));return document_pointer;
    }catch(...){if(own_hold)theHold.Cancel();throw;}
}
INode* create_setup(const MCHAR* name) {
    main_thread();auto* ip=GetCOREInterface();
    auto* point=create_arrange_icon();
    if(!point)throw std::runtime_error("Cannot create Arrange icon helper.");
    const bool own_hold=!theHold.Holding();if(own_hold)theHold.Begin();INode* owner=nullptr;
    try {
        owner=ip->CreateObjectNode(point);if(!owner){point->DeleteThis();point=nullptr;throw std::runtime_error("Cannot create Arrange setup node.");}
        point=nullptr;owner->SetName(name?name:_T("CyrusArrange_Setup"));initialize_setup(owner);
        if(own_hold)theHold.Accept(_T("Create Cyrus Arrange setup"));return owner;
    } catch(...) {
        if(own_hold)theHold.Cancel();else if(owner)ip->DeleteNode(owner,FALSE);if(point)point->DeleteThis();throw;
    }
}
Document* get_document(INode* owner,bool required) {
    main_thread();Document* found=nullptr;
    if(owner)if(auto* attributes=owner->GetCustAttribContainer())for(int i=0;i<attributes->GetNumCustAttribs();++i) {
        auto* attribute=attributes->GetCustAttrib(i);
        if(attribute&&attribute->ClassID()==attr_id) {
            auto* value=attribute->GetReference(0);
            if(value&&value->ClassID()==doc_id) {
                if(found)throw std::runtime_error("Setup has duplicate Arrange ownership attributes.");found=static_cast<Document*>(value);
            }
        }
    }
    if(!found&&required)throw std::runtime_error("Choose a Cyrus Arrange setup node.");
    if(found&&found->owner()!=owner)found->bind_owner(owner);return found;
}
std::vector<SceneSetupRow> scene_setups(std::span<INode* const> selected) {
    main_thread();
    if(selected.size()>4096)throw std::runtime_error("Setup discovery accepts at most 4096 selected nodes.");
    constexpr std::size_t maximum_work=4000000,maximum_roots=65536;
    std::size_t work=0,roots=0;
    const auto charge=[&](std::size_t count=1){if(count>maximum_work-work)throw std::runtime_error("Setup discovery exceeds its bounded hierarchy/reference work; choose fewer nodes.");work+=count;};
    auto* scene_root=GetCOREInterface()->GetRootNode();
    const auto current_scene=[&](INode* node){
        for(std::size_t depth=0;node&&depth<=4096;++depth){charge();if(node==scene_root)return true;node=node->GetParentNode();}
        if(node)throw std::runtime_error("Setup discovery hierarchy exceeds 4096 levels.");
        return false;
    };
    std::set<INode*> chosen,group_ancestors;
    for(auto* node:selected){
        charge();if(!node||node==scene_root||!current_scene(node))throw std::runtime_error("Choose current scene nodes for setup discovery.");
        if(!chosen.insert(node).second)continue;
        std::size_t depth=0;
        for(auto* parent=node->GetParentNode();parent&&parent!=scene_root;parent=parent->GetParentNode()){
            charge();if(++depth>4096)throw std::runtime_error("Setup discovery hierarchy exceeds 4096 levels.");
            if(parent->IsGroupHead())group_ancestors.insert(parent);
        }
    }
    std::vector<SceneSetupRow> result;
    result.reserve(documents.size());
    for(auto* document:documents){
        charge();auto* owner=document->owner();if(!owner||!current_scene(owner))continue;
        auto* attributes=owner->GetCustAttribContainer();if(!attributes)continue;
        const int count=attributes->GetNumCustAttribs();if(count<0||count>4096)throw std::runtime_error("Setup discovery owner attributes exceed admission.");
        charge(static_cast<std::size_t>(count));if(!owns_document(owner,document))continue;
        auto bindings=document->bindings();charge(bindings.furniture.size()+bindings.assets.size()+bindings.outputs.size()+bindings.obstacles.size()+bindings.paths.size());
        if(bindings.furniture.size()>maximum_roots-roots)throw std::runtime_error("Setup discovery exceeds 65536 furniture-root rows.");
        roots+=bindings.furniture.size();bool matched=chosen.contains(owner);
        for(auto* path:bindings.paths)if(path&&chosen.contains(path))matched=true;
        for(auto* output:bindings.outputs)if(output&&chosen.contains(output))matched=true;
        for(auto* furniture:bindings.furniture){
            if(!furniture)continue;
            if(chosen.contains(furniture)||group_ancestors.contains(furniture)){matched=true;continue;}
            std::size_t depth=0;
            for(auto* parent=furniture->GetParentNode();parent&&parent!=scene_root;parent=parent->GetParentNode()){
                charge();if(++depth>4096)throw std::runtime_error("Setup discovery hierarchy exceeds 4096 levels.");
                if(parent->IsGroupHead()&&chosen.contains(parent)){matched=true;break;}
            }
        }
        result.push_back({owner,matched,std::move(bindings.furniture)});
    }
    std::sort(result.begin(),result.end(),[](const auto& a,const auto& b){return a.owner->GetHandle()<b.owner->GetHandle();});
    return result;
}
void remove_document(INode* owner) {
    main_thread();auto* doc=get_document(owner,true);doc->observe_input_change(cache::Reason::OwnerRemoved);
    SingleRefMaker lifetime;lifetime.SetRef(doc);
    const bool own_hold=!theHold.Holding();if(own_hold)theHold.Begin();
    try {
        auto* attributes=owner->GetCustAttribContainer();
        for(int i=attributes->GetNumCustAttribs()-1;i>=0;--i)if(attributes->GetCustAttrib(i)->ClassID()==attr_id)attributes->RemoveCustAttrib(i);
        owner->SetUserPropBool(_T("CyrusArrangeSetup"),FALSE);
        if(own_hold)theHold.Accept(_T("Detach Cyrus Arrange setup"));
        doc->drain_input_watch();
    }catch(...){if(own_hold)theHold.Cancel();throw;}
}
Class_ID document_class_id(){return doc_id;}
Class_ID owner_attribute_class_id(){return attr_id;}
void set_document_module(HINSTANCE instance){document_module=instance;}
HINSTANCE document_module_handle()noexcept{return document_module;}
void set_live_update_callback(UpdateCallback callback){main_thread();update_callback=callback;if(callback)ensure_service();}
void flush_dependency_events(){main_thread();if(hierarchy_callback_key)if(auto* manager=GetISceneEventManager())manager->TriggerMessages(hierarchy_callback_key);}
cache::GeometryCache* geometry_cache()noexcept{return numeric_cache.get();}
cache::GeometryCache* ensure_geometry_cache()noexcept {
    try{main_thread();if(service_stopped)return nullptr;if(!numeric_cache)numeric_cache=std::make_unique<cache::GeometryCache>();return numeric_cache.get();}
    catch(...){return nullptr;} // Optional retention cannot fail a valid cold command.
}
void defer_geometry_cache_document(std::uint64_t instance,cache::Reason)noexcept {
    if(numeric_cache)numeric_cache->defer_document(instance);
}
void defer_geometry_cache_all(cache::Reason)noexcept {if(numeric_cache)numeric_cache->defer_all();}
void drain_geometry_cache()noexcept {if(numeric_cache)numeric_cache->drain_deferred();}
void shutdown_geometry_cache()noexcept {if(numeric_cache){numeric_cache->shutdown();numeric_cache.reset();}}
std::size_t process_live_updates(std::size_t maximum) {
    main_thread();if(!maximum||maximum>64)throw std::runtime_error("Arrange Live tick budget must be 1..64 setups.");
    if(service_stopped||scene_suspended||processing_live||!update_callback||theHold.Holding()||theHold.RestoreOrRedoing())return 0;
    flush_dependency_events();drain_geometry_cache();
    processing_live=true;std::size_t processed=0;
    try {
        // Registry is scheduling only: all authored/result ownership stays in scene documents.
        const std::vector<Document*> pending(documents.begin(),documents.end());
        // Releasing an observer can call SDK reference destructors and reenter
        // scene code. Never iterate the mutable registry across that boundary;
        // pin each still-registered document and block recursive Live service.
        for(auto* doc:pending) {
            if(!documents.contains(doc))continue;
            SingleRefMaker lifetime;lifetime.SetRef(doc);
            doc->drain_input_watch();doc->drain_deferred_dirty();
        }
        for(auto* doc:pending) {
            if(processed>=maximum)break;
            if(!documents.contains(doc))continue;
            auto state=doc->state();auto lifecycle=doc->lifecycle();auto* owner=doc->owner();
            if(!owner||doc->input_owner_detached_||!state->live||!lifecycle.live_armed||!lifecycle.dirty||lifecycle.updating||lifecycle.attempted_epoch==lifecycle.input_epoch)continue;
            // Manual output edits are never silently discarded by a timer.
            const auto upstream=DirtyGeometry|DirtyTransform|DirtyTime|DirtyUnits;
            if((lifecycle.dirty&DirtyOutput)&&!(lifecycle.dirty&upstream)) {
                doc->set_error("Generated objects changed. Use Protect selected to keep valid moves, or Generate to replace them.");continue;
            }
            SingleRefMaker lifetime;lifetime.SetRef(doc);
            doc->lifecycle_.attempted_epoch=lifecycle.input_epoch;
            doc->set_updating(true);++processed;
            try{update_callback(owner,*doc);}
            catch(const std::exception& error){doc->set_error(error.what());}
            catch(...){doc->set_error("Arrange Live update failed; previous complete arrangement retained.");}
            if(documents.contains(doc))doc->set_updating(false);
        }
        processing_live=false;return processed;
    }catch(...){processing_live=false;throw;}
}
void stop_document_service()noexcept {
    defer_geometry_cache_all(cache::Reason::SceneChanged);
    service_stopped=true;update_callback=nullptr;
    if(service_timer){KillTimer(nullptr,service_timer);service_timer=0;}
    if(hierarchy_callback_key){if(auto* manager=GetISceneEventManager())manager->UnRegisterCallback(hierarchy_callback_key);hierarchy_callback_key=0;}
    if(service_registered){UnRegisterNotification(scene_event,nullptr);service_registered=false;}
    try{for(auto* document:documents)GetCOREInterface()->UnRegisterTimeChangeCallback(document);}catch(...){}
}
} // namespace cyrus::arrange::host

extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeDocumentDesc(){static cyrus::arrange::host::Descriptor descriptor(false);return &descriptor;}
extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeOwnerDesc(){static cyrus::arrange::host::Descriptor descriptor(true);return &descriptor;}

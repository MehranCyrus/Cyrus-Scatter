// A small scene helper. It contains no Scatter evaluator or preview buffers.
// Frozen recipients are supplied by the model's event-driven ownership pass.
#include <max.h>
#include <notify.h>
#include <iparamb2.h>
#include <SingleWeakRefMaker.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include "diagnostics.h"
#include <memory>
#include <vector>
#include <string>
#include <cmath>
#include <stdexcept>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
extern HINSTANCE CyrusEditInstance;
extern bool CyrusContainerStaticNode(INode*);
namespace {
const Class_ID frameID(0x51732c40,0x42cf0973);
using WeakNode=MaxSDK::TypedSingleWeakRefMaker<INode>;
bool finite(const Matrix3& matrix){for(int r=0;r<4;++r)for(int axis=0;axis<3;++axis)if(!std::isfinite(matrix.GetRow(r)[axis]))return false;return true;}
bool same(const Matrix3& a,const Matrix3& b){if(!finite(a)||!finite(b))return false;for(int r=0;r<4;++r)if(Length(a.GetRow(r)-b.GetRow(r))>1e-4f)return false;return true;}
struct StartNode {std::shared_ptr<WeakNode> node,parent;Matrix3 tm;std::size_t root;};
class SourceFrame;
class FrameNode final:public WeakNode {
    SourceFrame* owner;
public:
    explicit FrameNode(SourceFrame* value):WeakNode(nullptr),owner(value){}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override;
};
class FrameMoveRestore;
class SourceFrame final : public HelperObject {
public:
    float width=500,length=300;bool show=true;
    std::wstring label=L"Unlinked source container",status=L"Ready";
    FrameNode node{this};std::vector<std::unique_ptr<WeakNode>> units,members;
    std::vector<StartNode> frozen;Matrix3 start{1};bool moving=false;
    std::vector<StartNode> ready;Matrix3 readyTM{1};bool readyValid=false,updating=false,restoredTM=false;
    unsigned begins=0,commits=0,cancels=0,failures=0;
    static void restoreCompleted(void* value,NotifyInfo*){
        auto* f=static_cast<SourceFrame*>(value);
        if(f->restoredTM){f->restoredTM=false;f->cache(GetCOREInterface()->GetTime());}
    }
    SourceFrame(){RegisterNotification(restoreCompleted,this,NOTIFY_SCENE_POST_UNDO);RegisterNotification(restoreCompleted,this,NOTIFY_SCENE_POST_REDO);}
    ~SourceFrame()override{UnRegisterNotification(restoreCompleted,this,NOTIFY_SCENE_POST_UNDO);UnRegisterNotification(restoreCompleted,this,NOTIFY_SCENE_POST_REDO);}
    void event(const char* name,const char* detail,std::size_t number=SIZE_MAX)const noexcept{
        auto& recorder=amin::diagnostics::recorder();if(!recorder.active())return;
        try{auto* owner=node.Get();recorder.record(name,"source_container",owner?std::to_string(owner->GetHandle()):"",0,number==SIZE_MAX?detail:std::string(detail)+std::to_string(number));}catch(...){}
    }
    Class_ID ClassID() override{return frameID;}
    void GetClassName(MSTR& out,bool)const override{out=_T("Cyrus Source Frame");}
    const MCHAR* GetObjectName(bool)const override{return _T("Cyrus Source Frame");}
    void InitNodeName(MSTR& out)override{out=_T("Cyrus Source Container");}
    void DeleteThis()override{delete this;}
    ObjectState Eval(TimeValue)override{return ObjectState(this);}
    Interval ObjectValidity(TimeValue)override{return FOREVER;}
    CreateMouseCallBack* GetCreateMouseCallBack()override{return nullptr;}
    void BeginEditParams(IObjParam*,ULONG,Animatable*)override{}
    void EndEditParams(IObjParam*,ULONG,Animatable*)override{}
    int NumRefs()override{return 0;}
    RefTargetHandle GetReference(int)override{return nullptr;}
    void SetReference(int,RefTargetHandle)override{}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
    RefTargetHandle Clone(RemapDir& remap)override{
        auto* out=new SourceFrame;out->width=width;out->length=length;out->show=show;out->label=label;BaseClone(this,out,remap);return out;
    }
    IOResult Save(ISave* save)override{
        save->BeginChunk(0x7301);ULONG written=0;
        const float data[]={width,length,show?1.0f:0.0f};const auto result=save->Write(data,sizeof(data),&written);save->EndChunk();return result;
    }
    IOResult Load(ILoad* load)override{
        IOResult result;while((result=load->OpenChunk())==IO_OK){if(load->CurChunkID()==0x7301){float data[3];ULONG read=0;result=load->Read(data,sizeof(data),&read);if(result==IO_OK&&read==sizeof(data)){width=data[0];length=data[1];show=data[2]!=0;}}load->CloseChunk();if(result!=IO_OK)return result;}return IO_OK;
    }
    Box3 bounds()const{return Box3(Point3(-width/2,-length/2,-.1f),Point3(width/2,length/2,.1f));}
    void GetLocalBoundBox(TimeValue,INode*,ViewExp*,Box3& box)override{box=bounds();}
    void GetWorldBoundBox(TimeValue t,INode* n,ViewExp*,Box3& box)override{box=bounds()*n->GetObjectTM(t);}
    void GetDeformBBox(TimeValue,Box3& box,Matrix3* tm,BOOL)override{box=bounds();if(tm)box=box**tm;}
    void lines(GraphicsWindow* gw)const{Point3 p[4]={{-width/2,-length/2,0.f},{width/2,-length/2,0.f},{width/2,length/2,0.f},{-width/2,length/2,0.f}};gw->polyline(4,p,nullptr,nullptr,TRUE,nullptr);}
    int Display(TimeValue t,INode* n,ViewExp* view,int)override{
        auto* gw=view->getGW();gw->setTransform(n->GetObjectTM(t));const Color color=n->Selected()?Color(GetUIColor(COLOR_SELECTION)):Color(n->GetWireColor());gw->setColor(LINE_COLOR,color);lines(gw);
        if(show&&!label.empty()){Point3 p(width/2+5.f,length/2,0.f);gw->text(&p,label.c_str());}return 0;
    }
    int HitTest(TimeValue t,INode* n,int type,int crossing,int flags,IPoint2* p,ViewExp* view)override{
        HitRegion region;MakeHitRegion(region,type,crossing,4,p);auto* gw=view->getGW();auto limit=gw->getRndLimits();gw->setRndLimits((limit|GW_PICK)&~GW_ILLUM);gw->setHitRegion(&region);gw->clearHitCode();gw->setTransform(n->GetObjectTM(t));lines(gw);const auto hit=gw->checkHitCode();gw->setRndLimits(limit);return hit;
    }
    void Snap(TimeValue,INode*,SnapInfo*,IPoint2*,ViewExp*)override{}
    void capture(TimeValue t){
        // These are transient weak observers, not scene references to restore.
        HoldSuspend hold;
        frozen.clear();status=L"Ready";
        auto* container=node.Get();if(!container)throw std::runtime_error("Container has no scene node");
        start=container->GetNodeTM(t);
        if(!finite(start))throw std::runtime_error("Restore a finite container transform before moving sources");
        if(!CyrusContainerStaticNode(container))throw std::runtime_error("Container movement requires unlocked static PRS controllers");
        auto* parent=container->GetParentNode();unsigned parentDepth=0;
        while(parent&&parent!=GetCOREInterface()->GetRootNode()){
            if(++parentDepth>64||!CyrusContainerStaticNode(parent))throw std::runtime_error("Container ancestors must have bounded static unlocked transforms");
            parent=parent->GetParentNode();
        }
        const auto frame=Inverse(container->GetObjectTM(t));
        for(auto& weak:units){auto* n=weak->Get();if(!n)throw std::runtime_error("A following source was deleted");
            std::vector<INode*> tree{n};const auto root=frozen.size();
            for(std::size_t i=0;i<tree.size();++i){auto* member=tree[i];
                if(frozen.size()>=1024)throw std::runtime_error("Container following supports at most 1024 total hierarchy nodes");
                for(auto& prior:frozen)if(prior.node->Get()==member)throw std::runtime_error("Overlapping movement hierarchies are unsupported");
                if(!CyrusContainerStaticNode(member))throw std::runtime_error("Following sources require unlocked static PRS controllers");
                if(!member->IsGroupHead()){
                    bool approved=false;for(auto& candidate:members)if(candidate->Get()==member)approved=true;
                    if(!approved)throw std::runtime_error("An unmanaged child prevents moving the whole source hierarchy");
                    const auto p=member->GetNodeTM(t).GetTrans()*frame;
                    const auto epsilon=std::max(1e-4f,std::max(width,length)*.5e-6f);
                    if(std::abs(p.x)>width/2+epsilon||std::abs(p.y)>length/2+epsilon)throw std::runtime_error("A parked source prevents moving the whole source hierarchy");
                }
                auto* ancestor=member->GetParentNode();unsigned depth=0;
                while(ancestor&&ancestor!=GetCOREInterface()->GetRootNode()){
                    if(++depth>64||!CyrusContainerStaticNode(ancestor))throw std::runtime_error("Source ancestors must have bounded static unlocked transforms");
                    ancestor=ancestor->GetParentNode();
                }
                const auto tm=member->GetNodeTM(t);if(!finite(tm))throw std::runtime_error("A source has an invalid transform");
                frozen.push_back({std::make_shared<WeakNode>(member),std::make_shared<WeakNode>(member->GetParentNode()),tm,root});
                for(int child=0;child<member->NumberOfChildren();++child){
                    if(tree.size()>=1024)throw std::runtime_error("Source hierarchy exceeds the movement budget");
                    tree.push_back(member->GetChildNode(child));
                }
            }
        }
    }
    void cache(TimeValue t){
        if(moving||updating)return;
        updating=true;
        const auto previous=status;
        try{capture(t);ready=std::move(frozen);readyTM=start;readyValid=true;status=previous;}
        catch(const std::exception& e){ready.clear();readyValid=false;status=std::wstring(e.what(),e.what()+strlen(e.what()));}
        frozen.clear();updating=false;
    }
    void begin(TimeValue t){
        if(moving)return;
        capture(t);moving=true;++begins;event("container.move.started","frozen_units=",frozen.size());
    }
    void finish(TimeValue t){
        if(!moving)return;
        auto* container=node.Get();if(!container)throw std::runtime_error("Container was deleted during movement");
        const auto current=container->GetNodeTM(t);auto expected=start;expected.SetTrans(current.GetTrans());
        if(!finite(current))throw std::runtime_error("Container translation produced an invalid transform");
        // Rotate/scale does not carry source models in the first translation slice.
        if(!same(current,expected)){moving=false;frozen.clear();status=L"Only translation carries sources";event("container.move.completed","rotation_or_scale_boundary_only");return;}
        const Point3 delta=current.GetTrans()-start.GetTrans();
        std::vector<std::pair<std::size_t,Matrix3>> changes;std::vector<bool> already(frozen.size(),false);
        for(std::size_t i=0;i<frozen.size();++i)if(frozen[i].root==i){auto* n=frozen[i].node->Get();if(!n)throw std::runtime_error("A managed source was deleted during movement");
            auto target=frozen[i].tm;target.SetTrans(target.GetTrans()+delta);const auto actual=n->GetNodeTM(t);
            already[i]=same(actual,target);if(!already[i]&&!same(actual,frozen[i].tm))throw std::runtime_error("A source changed independently during the move");
            if(!already[i])changes.emplace_back(i,target);
        }
        for(auto& entry:frozen){auto* n=entry.node->Get();if(!n||!CyrusContainerStaticNode(n))throw std::runtime_error("Source changed or was deleted during movement");
            if(n->GetParentNode()!=entry.parent->Get())throw std::runtime_error("Source hierarchy changed during movement");
            auto target=entry.tm;if(already[entry.root])target.SetTrans(target.GetTrans()+delta);
            if(!same(n->GetNodeTM(t),target))throw std::runtime_error("Move whole source groups; a child changed independently during the move");
        }
        AnimateSuspend animation;
        for(auto& change:changes){auto* source=frozen[change.first].node->Get();
            if(!source)throw std::runtime_error("A source was deleted during translation");source->SetNodeTM(t,change.second);
        }
        for(auto& entry:frozen){auto target=entry.tm;target.SetTrans(target.GetTrans()+delta);
            auto* source=entry.node->Get();if(!source||!same(source->GetNodeTM(t),target))throw std::runtime_error("Source transform inheritance prevented uniform translation");
        }
        moving=false;frozen.clear();status=L"Palette translated";++commits;event("container.move.completed","translated_units=",changes.size());
    }
    void rollback(TimeValue t){
        AnimateSuspend animation;HoldSuspend hold;
        for(auto& entry:frozen)if(auto* n=entry.node->Get())n->SetNodeTM(t,entry.tm);
        if(auto* n=node.Get())n->SetNodeTM(t,start);
        frozen.clear();moving=false;++failures;event("container.move.failed","transforms_restored");
    }
    void TransformStart(TimeValue t)override{try{begin(t);}catch(const std::exception& e){status=std::wstring(e.what(),e.what()+strlen(e.what()));moving=false;++failures;event("container.move.failed",e.what());}}
    void TransformHoldingFinish(TimeValue t)override{try{finish(t);}catch(const std::exception& e){status=std::wstring(e.what(),e.what()+strlen(e.what()));rollback(t);}}
    void TransformFinish(TimeValue)override{moving=false;frozen.clear();}
    void TransformCancel(TimeValue)override{moving=false;frozen.clear();status=L"Move cancelled";++cancels;event("container.move.cancelled","host_hold_cancelled");}
    void nodeChanged();
};
// Object::Transform* is a sub-object lifecycle, not the whole-node Move tool.
// Observe TM dirtiness and compare only the admitted static PRS node transform
// under a recursion guard. No geometry evaluation or scene mutation occurs in
// NotifyRefChanged. Frozen recipients come from the ownership event pass.
// EndHold carries the sources once, and this restore owns their Undo/Redo in
// Max's original Move transaction. There is no idle timer or redraw hook.
class FrameMoveRestore final:public RestoreObj {
    MaxSDK::TypedSingleWeakRefMaker<SourceFrame> owner;
    std::vector<StartNode> before,after;
    Matrix3 original,finalTM;
    TimeValue time;
    bool completed=false;
    void apply(const std::vector<StartNode>& values,const Matrix3& tm){
        auto* f=owner.Get();if(f)f->updating=true;
        AnimateSuspend animation;HoldSuspend hold;
        if(f)if(auto* n=f->node.Get())n->SetNodeTM(time,tm);
        // Roots carry their complete hierarchies. Setting children only when
        // needed also handles an interrupted or combined selection safely.
        for(auto& entry:values)if(auto* n=entry.node->Get())if(!same(n->GetNodeTM(time),entry.tm))n->SetNodeTM(time,entry.tm);
        if(f){f->updating=false;if(!theHold.Holding()){f->moving=false;f->frozen.clear();f->cache(time);}}
    }
public:
    explicit FrameMoveRestore(SourceFrame* f):owner(f),before(f->frozen),original(f->start),finalTM(f->start),time(GetCOREInterface()->GetTime()){}
    void seal(){
        if(auto* f=owner.Get())if(auto* n=f->node.Get()){
            finalTM=n->GetNodeTM(time);after=before;
            for(auto& entry:after)if(auto* source=entry.node->Get())entry.tm=source->GetNodeTM(time);
            completed=true;
        }
    }
    void Restore(int)override{apply(before,original);}
    void Redo()override{apply(completed?after:before,completed?finalTM:original);}
    int Size()override{return static_cast<int>(sizeof(*this)+(before.size()+after.size())*sizeof(StartNode));}
    MSTR Description()override{return _T("Cyrus source container recipients");}
    void EndHold()override{
        auto* f=owner.Get();if(!f)return;
        if(completed)return;
        f->updating=true;
        HoldSuspend hold;
        try{
            auto* n=f->node.Get();if(!n)throw std::runtime_error("Container was deleted during movement");
            if(same(n->GetNodeTM(time),original)){f->TransformCancel(time);}
            else{
                f->finish(time);seal();
            }
        }catch(const std::exception& e){f->status=std::wstring(e.what(),e.what()+strlen(e.what()));f->rollback(time);}
        f->updating=false;f->cache(time);
    }
};
void SourceFrame::nodeChanged(){
    if(theHold.RestoreOrRedoing()){restoredTM=true;return;}
    if(updating||moving||units.empty()||!readyValid||!theHold.Holding()||theHold.IsSuspended())return;
    // PART_TM can also be sent when Max validates an unchanged transform after
    // Redo. Recording that notification would add an empty MAXScript Undo.
    updating=true;
    const auto current=node.Get()?node->GetNodeTM(GetCOREInterface()->GetTime()):readyTM;
    updating=false;
    if(same(current,readyTM))return;
    frozen=ready;start=readyTM;moving=true;++begins;
    FrameMoveRestore* restore;
    {HoldSuspend hold;restore=new FrameMoveRestore(this);}
    if(!theHold.Put(restore)){delete restore;moving=false;frozen.clear();return;}
    event("container.move.started","frozen_units=",frozen.size());
}
RefResult FrameNode::NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate){
    const auto result=WeakNode::NotifyRefChanged(interval,target,part,message,propagate);
    if(message==REFMSG_CHANGE&&(part&PART_TM))owner->nodeChanged();
    return result;
}
SourceFrame* frame(Value* value){auto* obj=value->to_reftarg();if(!obj||obj->ClassID()!=frameID)throw RuntimeError(_T("Expected Cyrus Source Frame delegate"));return static_cast<SourceFrame*>(obj);}
class FrameDesc final:public ClassDesc2 {
public:
    int IsPublic()override{return FALSE;}void* Create(BOOL)override{return new SourceFrame;}
    const MCHAR* ClassName()override{return _T("Cyrus Source Frame");}const MCHAR* NonLocalizedClassName()override{return _T("Cyrus Source Frame");}
    SClass_ID SuperClassID()override{return HELPER_CLASS_ID;}Class_ID ClassID()override{return frameID;}
    const MCHAR* Category()override{return _T("Cyrus Internal");}const MCHAR* InternalName()override{return _T("CyrusSourceFrame");}HINSTANCE HInstance()override{return CyrusEditInstance;}
};
}
extern "C" __declspec(dllexport) ClassDesc* CyrusSourceFrameDesc(){static FrameDesc desc;return &desc;}
def_visible_primitive(cyrusContainerConfigure,"cyrusContainerConfigure");
Value* cyrusContainerConfigure_cf(Value** a,int count){
    check_arg_count(cyrusContainerConfigure,8,count);auto* f=frame(a[0]);auto* node=a[1]->to_node();type_check(a[2],Array,_T("container movement units"));auto* input=static_cast<Array*>(a[2]);
    type_check(a[7],Array,_T("authorized source members"));auto* members=static_cast<Array*>(a[7]);if(members->size>1024)throw RuntimeError(_T("Source membership exceeds the movement budget"));
    const auto w=a[3]->to_float(),l=a[4]->to_float();if(!(w>0)||!(l>0)||!std::isfinite(w)||!std::isfinite(l)||input->size>1024)throw RuntimeError(_T("Invalid source-container frame or movement budget"));
    // Automatic label/ownership notifications during a drag must not replace
    // its frozen recipients. Reconciliation runs again after the transaction.
    if(f->moving)return &ok;
    const std::wstring label=a[5]->to_string();const bool show=a[6]->to_bool()!=FALSE;
    const bool presentation=f->width!=w||f->length!=l||f->label!=label||f->show!=show;
    bool sameUnits=f->units.size()==static_cast<std::size_t>(input->size);
    if(sameUnits)for(int i=0;i<input->size;++i)if(f->units[i]->Get()!=input->data[i]->to_node())sameUnits=false;
    if(f->members.size()!=static_cast<std::size_t>(members->size))sameUnits=false;
    if(sameUnits)for(int i=0;i<members->size;++i)if(f->members[i]->Get()!=members->data[i]->to_node())sameUnits=false;
    if(sameUnits&&f->node.Get()==node&&!presentation){f->cache(MAXScript_time());return &ok;}
    HoldSuspend hold;
    std::vector<std::unique_ptr<WeakNode>> units;units.reserve(input->size);
    for(int i=0;i<input->size;++i)units.push_back(std::make_unique<WeakNode>(input->data[i]->to_node()));
    std::vector<std::unique_ptr<WeakNode>> authorized;authorized.reserve(members->size);
    for(int i=0;i<members->size;++i)authorized.push_back(std::make_unique<WeakNode>(members->data[i]->to_node()));
    f->node.Set(node);f->units=std::move(units);f->members=std::move(authorized);f->width=w;f->length=l;f->label=label;f->show=show;
    f->cache(MAXScript_time());
    if(presentation)f->NotifyDependents(FOREVER,PART_DISPLAY,REFMSG_CHANGE);return &ok;
}
def_visible_primitive(cyrusContainerMovable,"cyrusContainerMovable");
Value* cyrusContainerMovable_cf(Value** a,int count){check_arg_count(cyrusContainerMovable,1,count);return CyrusContainerStaticNode(a[0]->to_node())?&true_value:&false_value;}

def_visible_primitive(cyrusContainerDisable,"cyrusContainerDisable");
Value* cyrusContainerDisable_cf(Value** a,int count){
    check_arg_count(cyrusContainerDisable,1,count);auto* f=frame(a[0]);
    if(f->moving)throw RuntimeError(_T("Finish the container move before instancing it"));
    f->node.Set(nullptr);f->units.clear();f->members.clear();f->ready.clear();f->readyValid=false;f->status=L"Instanced container: make unique";return &ok;
}
def_visible_primitive(cyrusContainerTranslate,"cyrusContainerTranslate");
Value* cyrusContainerTranslate_cf(Value** a,int count){
    check_arg_count(cyrusContainerTranslate,2,count);auto* f=frame(a[0]);auto* node=f->node.Get();if(!node)throw RuntimeError(_T("Bind the container first"));
    if(f->moving)throw RuntimeError(_T("Finish the current container gesture first"));
    const auto delta=a[1]->to_point3();for(int axis=0;axis<3;++axis)if(!std::isfinite(delta[axis]))throw RuntimeError(_T("Invalid translation"));
    const auto t=MAXScript_time();const bool hold=!theHold.Holding();if(hold)theHold.Begin();
    try{
        f->begin(t);FrameMoveRestore* restore;
        {HoldSuspend suspend;restore=new FrameMoveRestore(f);}
        if(!theHold.Put(restore)){delete restore;throw std::runtime_error("Container translation requires a writable Undo transaction");}
        {HoldSuspend suspend;auto tm=node->GetNodeTM(t);tm.SetTrans(tm.GetTrans()+delta);node->SetNodeTM(t,tm);f->finish(t);restore->seal();}
        f->cache(t);if(hold)theHold.Accept(_T("Cyrus source container translation"));
    }
    catch(const std::exception& e){f->rollback(t);if(hold)theHold.Cancel();throw RuntimeError(MSTR::FromACP(e.what()));}
    return &ok;
}
def_visible_primitive(cyrusContainerMoveStats,"cyrusContainerMoveStats");
Value* cyrusContainerMoveStats_cf(Value** a,int count){
    check_arg_count(cyrusContainerMoveStats,1,count);auto* f=frame(a[0]);one_typed_value_local(Array* result);vl.result=new Array(6);
    for(auto value:{f->begins,f->commits,f->cancels,f->failures})vl.result->append(Integer::intern(value));vl.result->append(new String(f->status.c_str()));vl.result->append(f->moving?&true_value:&false_value);return_value(vl.result);
}
// Exercise the real SDK entry points in isolated fixtures without synthesizing
// mouse input. This API also gives explicit integrations the same lifecycle.
def_visible_primitive(cyrusContainerGesture,"cyrusContainerGesture");
Value* cyrusContainerGesture_cf(Value** a,int count){
    check_arg_count(cyrusContainerGesture,2,count);auto* f=frame(a[0]);const auto mode=a[1]->to_int(),t=MAXScript_time();
    if(mode==0)f->TransformStart(t);else if(mode==1)f->TransformHoldingFinish(t);else if(mode==2)f->TransformCancel(t);else throw RuntimeError(_T("Unknown container gesture phase"));return &ok;
}

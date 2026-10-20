#include "arrange_document.h" // Owned values before MAXScript macros.
#include "arrange_presentation.h"
#include "presentation_resource.h"
#include <iparamm.h>
#include <iparamb2.h>
#include <modstack.h>
#include <custattrib.h>
#include <icustattribcontainer.h>
#include <units.h>
#include <maxscript/maxscript.h>
#include <maxscript/UI/rollouts.h>
#include <maxscript/foundation/ValueHolderMember.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/mxsplugin/mxsCustomAttributes.h>
#include <algorithm>
#include <cmath>
#include <memory>
#include <stdexcept>
#include <vector>

namespace cyrus::arrange::host {
namespace {
const Class_ID modifier_id(0x6a4387d3,0x4fa90372);
const Class_ID icon_id(0x6a4387d4,0x4fa90372);
const Class_ID transient_view_id(0x6a4387d5,0x4fa90372);
constexpr std::size_t maximum_panel_nodes=4096;
bool panel_trace_enabled()noexcept {
    const auto previous=GetLastError();
    MCHAR enabled[4]{};
    const auto active=GetEnvironmentVariableW(_T("CYRUS_ARRANGE_PANEL_TRACE"),enabled,4)==1&&enabled[0]==_T('1');
    SetLastError(previous);return active;
}
// Private-host opt-in only: fixed numeric diagnostics, no scene strings, file
// IO or published API. Preserve caller's thread-local Win32 error value.
void trace_page(const MCHAR* stage,Rollout* rollout,IObjParam* ip,HINSTANCE instance,BOOL result,DWORD before,DWORD after)noexcept {
    if(!panel_trace_enabled())return;
    const auto saved=GetLastError();
    try {
        mprintf(_T("Cyrus Arrange page %s: result=%d page=%llu valid=%d flags=%u instance=%llu mxsInstance=%llu ip=%llu storedIp=%llu imp=%llu plugin=%llu structure=%llu floater=%llu mode=%d beforeError=%lu afterError=%lu controls=%d width=%d height=%d\n"),stage,result,
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(rollout?rollout->page:nullptr)),rollout&&IsWindow(rollout->page)?1:0,
            rollout?static_cast<unsigned int>(static_cast<unsigned short>(rollout->flags)):0,
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(instance)),
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(GetModuleHandleW(_T("Maxscrpt.dll")))),
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(ip)),
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(rollout?rollout->ip:nullptr)),
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(rollout?rollout->imp:nullptr)),
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(rollout?rollout->current_plugin:nullptr)),
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(rollout?rollout->current_struct:nullptr)),
            static_cast<unsigned long long>(reinterpret_cast<std::uintptr_t>(rollout?rollout->rof:nullptr)),
            ip?ip->GetCommandPanelTaskMode():-1,before,after,
            rollout?rollout->control_count:0,rollout?rollout->rollout_width:0,rollout?rollout->rollout_height:0);
    }catch(...){}
    SetLastError(saved);
}

class NoSceneOwner final:public DependentEnumProc {
public:
    std::size_t work{};
    bool scene_owned{},complete{true};
    int proc(ReferenceMaker* dependent)override {
        if(++work>maximum_panel_nodes){complete=false;return DEP_ENUM_HALT;}
        if(dependent&&dependent->SuperClassID()==BASENODE_CLASS_ID){scene_owned=true;return DEP_ENUM_HALT;}
        return DEP_ENUM_CONTINUE;
    }
};
void require_off_scene(ReferenceTarget* target) {
    NoSceneOwner check;target->DoEnumDependents(&check);
    if(!check.complete||check.scene_owned)throw std::runtime_error("Arrange Modify UI holder must be an independent off-scene object.");
}
// A real temporary scripted CA supplies MAXScript's standard Modify host. It
// contains only view locals/controls, never the saved native Document model.
// The native references and returned values remain rooted through reentrant
// Begin/End calls. No temporary reference or object cleanup enters artist Undo.
struct TransientView {
    std::unique_ptr<ValueHolderMember> values;
    SingleRefMaker holder_lifetime,attribute_lifetime;
    CustAttrib* attribute{};
    Rollout* rollout{};
    bool begun{};
    TransientView(Value* result,Modifier* holder,CustAttrib* ca,Rollout* page)
        :values(std::make_unique<ValueHolderMember>(result)),attribute(ca),rollout(page) {
        holder_lifetime.SetRef(holder);attribute_lifetime.SetRef(ca);
    }
    ~TransientView(){
        HoldSuspend silent;
        attribute_lifetime.SetRef(nullptr);holder_lifetime.SetRef(nullptr);values.reset();
    }
};
// This is an ephemeral view, not a native scene reference or an authored model.
// In particular there is no furniture -> modifier -> owner -> Document cycle.
class ModifyPanel {
    IObjParam* interface_{};
    std::shared_ptr<TransientView> view_;
    HWND fallback_{};
    std::uint64_t generation_{};
    static void close_view(const std::shared_ptr<TransientView>& view,IObjParam* ip,ULONG flags,Animatable* next) {
        if(!view||!view->begun)return;
        view->begun=false; // Nested End cannot close the same instance twice.
        trace_page(_T("beforeCAEnd"),view->rollout,ip,document_module_handle(),FALSE,GetLastError(),GetLastError());
        view->attribute->EndEditParams(ip,flags,next);
        trace_page(_T("afterCAEnd"),view->rollout,ip,document_module_handle(),FALSE,GetLastError(),GetLastError());
    }
public:
    ~ModifyPanel(){end();}
    void end(ULONG flags=END_EDIT_REMOVEUI,Animatable* next=nullptr) noexcept {
        ++generation_;
        auto* ip=interface_;interface_=nullptr;
        auto previous=std::move(view_);
        const auto fallback=fallback_;fallback_=nullptr;
        if(!ip)return;
        try {
            ScopedMaxScriptEvaluationContext context;
            HoldSuspend silent;close_view(previous,ip,flags,next);
        }catch(MAXScriptException& error){ProcessMAXScriptException(error,_T("Cyrus Arrange Modify close"),false,false,true);}
        catch(...){ProcessUnknownMAXScriptException(_T("Cyrus Arrange Modify close"),false,false,true);}
        if(fallback&&IsWindow(fallback))try{ip->DeleteRollupPage(fallback);}catch(...){}
    }
    void begin(IObjParam* ip,ULONG flags,Animatable* previous,std::vector<INode*> nodes) noexcept {
        end();if(!ip)return;interface_=ip;const auto generation=++generation_;
        try {
            if(nodes.size()>maximum_panel_nodes)throw std::runtime_error("Too many nodes share the edited Arrange modifier.");
            std::sort(nodes.begin(),nodes.end(),[](auto* a,auto* b){return a->GetHandle()<b->GetHandle();});
            nodes.erase(std::unique(nodes.begin(),nodes.end()),nodes.end());
            auto* context_node=nodes.size()==1?nodes.front():nullptr;
            INode* owner=nullptr;
            for(const auto& row:scene_setups(nodes))if(row.matched){if(owner){owner=nullptr;break;}owner=row.owner;}
            SingleRefMaker owner_lifetime,context_lifetime;
            if(owner)owner_lifetime.SetRef(owner);if(context_node)context_lifetime.SetRef(context_node);
            ScopedMaxScriptEvaluationContext evaluation;
            HoldSuspend temporary_ui;
            MAXScript_TLS* _tls=evaluation.Get_TLS();
            four_value_locals_tls(name,function,owner,context);
            ScopedSaveCurrentFrames frames(_tls);
            vl.name=Name::intern(_T("caCreateModifyView"));
            vl.function=globals->get(vl.name);
            while(vl.function&&is_globalthunk(vl.function))vl.function=static_cast<GlobalThunk*>(vl.function)->cell;
            if(vl.function&&vl.function->tag==class_tag(MAXScriptFunction)) {
                vl.owner=owner?MAXNode::intern(owner):&undefined;
                vl.context=context_node?MAXNode::intern(context_node):&undefined;
                Value* arguments[]{vl.owner,vl.context};
                ValueHolderMember result(static_cast<MAXScriptFunction*>(vl.function)->apply(arguments,2));
                if(interface_!=ip||generation_!=generation)return;
                auto* value=result.get_value();
                if(value&&is_array(value)) {
                    auto* items=static_cast<Array*>(value);
                    if(items->size!=3||!items->data[0]||!items->data[1]||!items->data[2]||!is_modifier(items->data[0])||!is_rollout(items->data[2]))
                        throw std::runtime_error("Arrange Modify provider must return its off-scene holder, real CA and per-instance rollout.");
                    auto* holder=items->data[0]->to_modifier();
                    // Native CAs can be wrapped, whereas a scripted CA can be
                    // exposed directly as its real multiply-inherited Value.
                    CustAttrib* ca=dynamic_cast<MSCustAttrib*>(items->data[1]);
                    if(!ca&&is_custattrib(items->data[1]))ca=static_cast<MAXCustAttrib*>(items->data[1])->to_custattrib();
                    auto* page=static_cast<Rollout*>(items->data[2]);
                    auto* container=holder?holder->GetCustAttribContainer():nullptr;
                    if(!holder||!ca||!dynamic_cast<MSCustAttrib*>(ca)||ca->ClassID()!=transient_view_id||!container||container->GetOwner()!=holder||container->GetNumCustAttribs()!=1||container->GetCustAttrib(0)!=ca)
                        throw std::runtime_error("Arrange Modify UI requires a real scripted CA on its own temporary holder.");
                    if(ca->NumParamBlocks()>1||ca->NumRefs()>1)throw std::runtime_error("Arrange Modify CA must contain only transient view data.");
                    for(int i=0;i<ca->NumParamBlocks();++i)if(auto* block=ca->GetParamBlock(i);!block||block->NumParams()!=0)
                        throw std::runtime_error("Arrange Modify CA must not duplicate authored Document parameters.");
                    require_off_scene(holder);require_off_scene(ca);
                    auto view=std::make_shared<TransientView>(value,holder,ca,page);
                    if(interface_!=ip||generation_!=generation)return;
                    view_=view;view->begun=true;
                    const auto before=GetLastError();trace_page(_T("beforeCABegin"),page,ip,document_module_handle(),FALSE,before,before);
                    ca->BeginEditParams(ip,flags,previous);
                    trace_page(_T("afterCABegin"),page,ip,document_module_handle(),TRUE,before,GetLastError());
                    if(interface_!=ip||generation_!=generation)return;
                    if(page->page&&IsWindow(page->page)&&ip->GetCommandPanelTaskMode()==TASK_MODE_MODIFY)return;
                    throw std::runtime_error("Arrange Modify CA did not create a visible command-panel page.");
                }
            }
        }catch(MAXScriptException& error){ProcessMAXScriptException(error,_T("Cyrus Arrange Modify open"),false,false,true);}
        catch(...){ProcessUnknownMAXScriptException(_T("Cyrus Arrange Modify open"),false,false,true);}
        if(interface_==ip&&generation_==generation&&view_) {
            auto failed=std::move(view_);
            try{ScopedMaxScriptEvaluationContext context;HoldSuspend silent;close_view(failed,ip,END_EDIT_REMOVEUI,nullptr);}
            catch(...){ProcessUnknownMAXScriptException(_T("Cyrus Arrange Modify failed view close"),false,false,true);}
        }
        if(interface_==ip&&generation_==generation)try {
            fallback_=ip->AddRollupPage(document_module_handle(),MAKEINTRESOURCE(IDD_CYRUS_ARRANGE_UI_UNAVAILABLE),
                [](HWND,UINT,WPARAM,LPARAM)->INT_PTR{return FALSE;},_T("Cyrus Arrange"));
        }catch(...){} // Presentation failure must not unwind into the host.
    }
};

std::vector<INode*> modifier_nodes(IObjParam* ip) {
    ModContextList contexts;INodeTab nodes;ip->GetModContexts(contexts,nodes);
    std::vector<INode*> result;
    try {
        if(nodes.Count()<0||static_cast<std::size_t>(nodes.Count())>maximum_panel_nodes)
            throw std::runtime_error("Too many selected modifier contexts.");
        result.reserve(nodes.Count());
        for(int i=0;i<nodes.Count();++i)if(nodes[i])if(auto* actual=nodes[i]->GetActualINode())result.push_back(actual);
    }catch(...){nodes.DisposeTemporary();throw;}
    nodes.DisposeTemporary();return result;
}

class ArrangeModifier final:public Modifier {
    ModifyPanel panel_;
public:
    void DeleteThis()override{delete this;}
    Class_ID ClassID()override{return modifier_id;}
    void GetClassName(MSTR& value,bool=true)const override{value=_T("Cyrus Arrange");}
    const MCHAR* GetObjectName(bool=true)const override{return _T("Cyrus Arrange");}
    ChannelMask ChannelsUsed()override{return NO_CHANNEL;}
    ChannelMask ChannelsChanged()override{return NO_CHANNEL;}
    Class_ID InputType()override{return anyObjectClassID;}
    bool AnyObjectFilter(Object* object)const override {
        return object&&(object->SuperClassID()==GEOMOBJECT_CLASS_ID||object->SuperClassID()==HELPER_CLASS_ID||object->SuperClassID()==SHAPE_CLASS_ID);
    }
    void ModifyObject(TimeValue,ModContext&,ObjectState*,INode*)override{} // Exact pass-through.
    Interval LocalValidity(TimeValue)override{return FOREVER;}
    CreateMouseCallBack* GetCreateMouseCallBack()override{return nullptr;}
    void BeginEditParams(IObjParam* ip,ULONG flags,Animatable* previous)override {
        try{panel_.begin(ip,flags,previous,modifier_nodes(ip));}
        catch(...){panel_.begin(ip,flags,previous,{});}
    }
    void EndEditParams(IObjParam*,ULONG flags,Animatable* next)override{panel_.end(flags,next);}
    int NumRefs()override{return 0;}
    RefTargetHandle GetReference(int)override{return nullptr;}
    void SetReference(int,RefTargetHandle)override{}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
    RefTargetHandle Clone(RemapDir& remap)override{auto* value=new ArrangeModifier;BaseClone(this,value,remap);return value;}
};

float icon_radius() noexcept {
    const double unit=GetSystemUnitScale(UNITS_MILLIMETERS);
    if(!std::isfinite(unit)||unit<=0)return 60.0f;
    return static_cast<float>(std::clamp(60.0/unit,0.0001,10000000.0));
}
Box3 icon_bounds() {
    const auto radius=icon_radius();return Box3(Point3(-radius,-radius,-radius*.15f),Point3(radius,radius,radius*.65f));
}
void icon_lines(GraphicsWindow* window) {
    const auto r=icon_radius();
    Point3 diamond[]{{-r,0.0f,0.0f},{0.0f,-r,0.0f},{r,0.0f,0.0f},{0.0f,r,0.0f}};
    window->polyline(4,diamond,nullptr,nullptr,TRUE,nullptr);
    Point3 letter[]{{r*.28f,r*.43f,0.0f},{-r*.32f,r*.43f,0.0f},{-r*.48f,0.0f,0.0f},{-r*.32f,-r*.43f,0.0f},{r*.28f,-r*.43f,0.0f}};
    window->polyline(5,letter,nullptr,nullptr,FALSE,nullptr);
    Point3 up[]{{0.0f,0.0f,0.0f},{0.0f,0.0f,r*.65f}};window->polyline(2,up,nullptr,nullptr,FALSE,nullptr);
}
struct GraphicsRestore {
    GraphicsWindow* window;
    Matrix3 transform;
    DWORD limits;
    explicit GraphicsRestore(GraphicsWindow* value):window(value),transform(value->getTransform()),limits(value->getRndLimits()){}
    ~GraphicsRestore(){window->setRndLimits(limits);window->setTransform(transform);}
};
class IconCreate final:public CreateMouseCallBack {
    Object* source_{};
public:
    void bind(Object* source){source_=source;}
    int proc(ViewExp* view,int message,int point,int,IPoint2 mouse,Matrix3& matrix)override {
        if(message==MOUSE_ABORT)return CREATE_ABORT;
        if(view&&(message==MOUSE_MOVE||message==MOUSE_POINT)) {
            matrix.SetTrans(view->SnapPoint(mouse,mouse,nullptr,SNAP_IN_3D));
            if(message==MOUSE_POINT&&point==0) {
                try {
                    const auto nodes=GetCOREInterface7()->FindNodesFromBaseObject(source_,false,false);
                    if(nodes.Count()==1)initialize_setup(nodes[0]);
                    return CREATE_STOP;
                }catch(...){return CREATE_ABORT;}
            }
        }
        return CREATE_CONTINUE;
    }
};
class ArrangeIcon final:public HelperObject {
    ModifyPanel panel_;
    IconCreate create_;
public:
    void DeleteThis()override{delete this;}
    Class_ID ClassID()override{return icon_id;}
    void GetClassName(MSTR& value,bool=true)const override{value=_T("Cyrus Arrange Icon");}
    const MCHAR* GetObjectName(bool=true)const override{return _T("Cyrus Arrange Icon");}
    void InitNodeName(MSTR& value)override{value=_T("CyrusArrange_Setup");}
    ObjectState Eval(TimeValue)override{return ObjectState(this);}
    Interval ObjectValidity(TimeValue)override{return FOREVER;}
    int UsesWireColor()override{return TRUE;}
    int DoOwnSelectHilite()override{return TRUE;}
    CreateMouseCallBack* GetCreateMouseCallBack()override{create_.bind(this);return &create_;}
    void BeginEditParams(IObjParam* ip,ULONG flags,Animatable* previous)override {
        if(ip&&ip->GetCommandPanelTaskMode()!=TASK_MODE_MODIFY)return;
        try {
            const auto nodes=GetCOREInterface7()->FindNodesFromBaseObject(this,false,false);
            if(nodes.Count()<0||static_cast<std::size_t>(nodes.Count())>maximum_panel_nodes)throw std::runtime_error("Too many icon instances.");
            std::vector<INode*> values;values.reserve(nodes.Count());for(int i=0;i<nodes.Count();++i)if(nodes[i])values.push_back(nodes[i]);
            panel_.begin(ip,flags,previous,std::move(values));
        }catch(...){panel_.begin(ip,flags,previous,{});}
    }
    void EndEditParams(IObjParam*,ULONG flags,Animatable* next)override{panel_.end(flags,next);}
    int NumRefs()override{return 0;}
    RefTargetHandle GetReference(int)override{return nullptr;}
    void SetReference(int,RefTargetHandle)override{}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
    RefTargetHandle Clone(RemapDir& remap)override{auto* value=new ArrangeIcon;BaseClone(this,value,remap);return value;}
    void GetLocalBoundBox(TimeValue,INode*,ViewExp*,Box3& value)override{value=icon_bounds();}
    void GetWorldBoundBox(TimeValue time,INode* node,ViewExp*,Box3& value)override{value=icon_bounds()*node->GetObjectTM(time);}
    void GetDeformBBox(TimeValue,Box3& value,Matrix3* matrix,BOOL)override{value=icon_bounds();if(matrix)value=value**matrix;}
    void Snap(TimeValue,INode*,SnapInfo*,IPoint2*,ViewExp*)override{}
    int Display(TimeValue time,INode* node,ViewExp* view,int)override {
        if(!view||!view->IsAlive()||!node)return 0;
        auto* window=view->getGW();GraphicsRestore restore(window);
        window->setTransform(node->GetObjectTM(time));window->setRndLimits((restore.limits|GW_WIREFRAME)&~GW_ILLUM);
        window->setColor(LINE_COLOR,node->Selected()?Color(GetUIColor(COLOR_SELECTION)):Color(node->GetWireColor()));
        icon_lines(window);return 0;
    }
    int HitTest(TimeValue time,INode* node,int type,int crossing,int,IPoint2* point,ViewExp* view)override {
        if(!view||!view->IsAlive()||!node)return FALSE;
        auto* window=view->getGW();GraphicsRestore restore(window);HitRegion region;MakeHitRegion(region,type,crossing,4,point);
        window->setRndLimits((restore.limits|GW_PICK)&~GW_ILLUM);
        window->setHitRegion(&region);window->clearHitCode();window->setTransform(node->GetObjectTM(time));
        icon_lines(window);return window->checkHitCode();
    }
};

class PresentationDesc final:public ClassDesc2 {
    bool icon_;
public:
    explicit PresentationDesc(bool icon):icon_(icon){}
    int IsPublic()override{return TRUE;}
    void* Create(BOOL)override{return icon_?static_cast<void*>(new ArrangeIcon):static_cast<void*>(new ArrangeModifier);}
    const MCHAR* ClassName()override{return _T("Cyrus Arrange");}
    const MCHAR* NonLocalizedClassName()override{return ClassName();}
    SClass_ID SuperClassID()override{return icon_?HELPER_CLASS_ID:OSM_CLASS_ID;}
    Class_ID ClassID()override{return icon_?icon_id:modifier_id;}
    const MCHAR* Category()override{return _T("Cyrus");}
    const MCHAR* InternalName()override{return icon_?_T("CyrusArrangeIcon"):_T("CyrusArrange");}
    HINSTANCE HInstance()override{return document_module_handle();}
};
} // namespace

Class_ID arrange_modifier_class_id(){return modifier_id;}
Class_ID arrange_icon_class_id(){return icon_id;}
Object* create_arrange_icon(){return new ArrangeIcon;}
void add_arrange_modifier(INode* node) {
    if(!node||!node->GetObjectRef())throw std::runtime_error("Arrange icon has no native object.");
    auto* object=node->GetObjectRef();
    for(std::size_t depth=0;object&&object->SuperClassID()==GEN_DERIVOB_CLASS_ID;++depth) {
        if(depth>=4096)throw std::runtime_error("Arrange modifier stack exceeds admission.");
        auto* stack=static_cast<IDerivedObject*>(object);
        if(stack->NumModifiers()<0||stack->NumModifiers()>4096)throw std::runtime_error("Arrange modifier stack exceeds admission.");
        for(int i=0;i<stack->NumModifiers();++i)if(auto* modifier=stack->GetModifier(i);modifier&&modifier->ClassID()==modifier_id)return;
        object=stack->GetObjRef();
    }
    auto* derived=CreateDerivedObject(node->GetObjectRef());
    if(!derived)throw std::runtime_error("Cannot create the Arrange icon modifier stack.");
    SingleRefMaker derived_lifetime,modifier_lifetime;derived_lifetime.SetRef(derived);
    auto* modifier=new ArrangeModifier;modifier_lifetime.SetRef(modifier);
    // The node and its original object already belong to the active authored
    // creation hold. Cancel restores/deletes this complete native stack.
    node->SetObjectRef(derived);derived->AddModifier(modifier);
}
} // namespace cyrus::arrange::host

extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeModifierDesc(){static cyrus::arrange::host::PresentationDesc value(false);return &value;}
extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeIconDesc(){static cyrus::arrange::host::PresentationDesc value(true);return &value;}

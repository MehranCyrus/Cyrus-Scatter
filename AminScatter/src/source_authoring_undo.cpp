// Scripted ParamBlock values do not acquire an authored RestoreObj merely by
// entering an `undo on` clause. Keep these small source commands explicit. This
// journal owns authored rows only; it never copies meshes, instance rows or a
// retained publication. The host thread owns every capture and restore.
#include <max.h>
#include <hold.h>
#include <iparamb2.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/foundation/colors.h>
#include <maxscript/foundation/ValueHolderMember.h>
#include <maxscript/foundation/hashtable.h>
#include <maxscript/compiler/thunks.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/mxsplugin/mxsPlugin.h>
#include "license_boundary.h"
#include <algorithm>
#include <limits>
#include <memory>
#include <stdexcept>
#include <string_view>
#include <unordered_map>
#include <vector>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

namespace {
constexpr std::size_t rowLimit=1024,nodeLimit=4096;
constexpr std::uint64_t byteLimit=256ull*1024*1024;
const Class_ID scatterID(0x617d43a1,0x395c2e17);
struct Binding { IParamBlock2* block=nullptr;ParamID id=0;ParamType2 type=static_cast<ParamType2>(TYPE_INT); };
Binding binding(ReferenceTarget* owner,const MCHAR* name) {
    for(int b=0;b<owner->NumParamBlocks();++b)if(auto* block=owner->GetParamBlock(b))
        for(int p=0;p<block->NumParams();++p){const auto id=block->IndextoID(p);const auto* key=block->GetParamDef(id).int_name;
            if(key&&_wcsicmp(key,name)==0)return {block,id,block->GetParameterType(id)};}
    throw RuntimeError(_T("Source Undo requires its matching scripted fields: "),new String(name));
}
int localSlot(MSPlugin* owner,const MCHAR* name) {
    auto* entry=owner->pc->local_scope->get(Name::intern(name));
    return entry&&is_pluginlocalthunk(entry)?static_cast<PluginLocalThunk*>(entry)->index:-1;
}
void setLocal(MSPlugin* owner,const MCHAR* name,Value* value) {
    const int slot=localSlot(owner,name);if(slot>=0)owner->set_local(slot,value);
}
const std::vector<const MCHAR*>& fields(int scope) {
    static const std::vector<const MCHAR*> membership={
        _T("sources"),_T("sourceRowIDs"),_T("sourcePoint"),_T("sourceEmpty"),_T("sourceColors"),
        _T("sourceWeights"),_T("sourceScales"),_T("sourceZOffsetsWU"),_T("sourceForwardAxes"),
        _T("sourceRadiiWU"),_T("sourceAutoRadius"),_T("sourceFollowScale"),_T("sourceShowRadius"),
        _T("procSourceSlots"),_T("procRadiusIDs"),_T("procRadiusModes"),_T("procRadiusValues"),_T("procRadiusDistances"),_T("procRadiusBinding"),
        _T("clearanceSourceIDs"),_T("clearanceCopies"),_T("clearanceOthers"),_T("clearanceExternal"),_T("clearanceTargets"),
        _T("clearancePreferred"),_T("clearanceFactors"),_T("clearanceGapsWU"),_T("clearancePlanar"),
        _T("interactionSourceIDs"),_T("interactionDefinitions"),_T("interactionProxySourceIDs"),_T("interactionProxyNodes")};
    static const std::vector<const MCHAR*> transform={_T("sourceScales"),_T("sourceZOffsetsWU")};
    static const std::vector<const MCHAR*> navigation={_T("viewportNavigationFaces")};
    static const std::vector<const MCHAR*> sceneColliders={_T("interactionSceneColliders")};
    static const std::vector<const MCHAR*> response={_T("interactionResponse"),_T("interactionBendStrength"),_T("interactionPruneAmount"),_T("interactionPruneThresholdWU"),_T("interactionNeighbors"),_T("interactionGapWU"),_T("interactionTrunkBend"),_T("interactionFixedBase"),_T("interactionBendTransition")};
    if(scope==1)return membership;if(scope==2)return transform;if(scope==3)return navigation;if(scope==4)return sceneColliders;if(scope==5)return response;
    throw RuntimeError(_T("Unknown source Undo scope"));
}
ParamType2 baseType(ParamType2 type) {return static_cast<ParamType2>(type&~TYPE_TAB);}
void supported(ParamType2 type) {
    switch(baseType(type)){
        case TYPE_FLOAT:case TYPE_WORLD:case TYPE_INT:case TYPE_BOOL:case TYPE_RGBA:case TYPE_STRING:case TYPE_INODE:return;
        default:throw RuntimeError(_T("Unsupported source Undo parameter storage"));
    }
}
struct Field { const MCHAR* name=nullptr;ParamType2 type=static_cast<ParamType2>(TYPE_INT);ValueHolderMember value; };
using Snapshot=std::vector<Field>;
struct SourceCommandState {
    ValueHolderMember owner;
    int scope=0;bool sealed=false,cancelled=false;TimeValue time=0;
    Snapshot before,after;
    std::uint64_t bytes=0;std::size_t nodes=0;
    // Views point into private immutable, rooted String objects. An unchanged
    // rig is retained once across before/after; it is not reparsed or cloned.
    std::vector<ValueHolderMember> textRoots;
    std::unordered_map<std::wstring_view,Value*> text;
    SourceCommandState(Value* value,int kind):owner(value),scope(kind),time(GetCOREInterface()->GetTime()) {
        // Undo's cache reset must never make a new charged string allocation
        // after a sealed record has already reached its admission boundary.
        string(_T(""));
    }
    ReferenceTarget* target()const {
        auto* result=owner.get_value()->to_reftarg();
        if(!result||result->ClassID()!=scatterID||!dynamic_cast<MSPlugin*>(result))throw RuntimeError(_T("Expected a Cyrus source authoring owner"));
        return result;
    }
    void charge(std::uint64_t size) {
        if(size>byteLimit-bytes)throw RuntimeError(_T("Source Undo snapshot exceeds 256 MiB of authored data; reduce unused prepared source definitions first"));
        bytes+=size;
    }
    Value* string(const MCHAR* input) {
        const auto* textValue=input?input:_T("");std::size_t length=0;
        constexpr auto characters=(byteLimit/sizeof(MCHAR))-1;
        while(length<=characters&&textValue[length])++length;
        if(length>characters)throw RuntimeError(_T("Source Undo text exceeds its authored-data bound"));
        const std::wstring_view value(textValue,length);
        if(auto found=text.find(value);found!=text.end())return found->second;
        if(value.size()>(byteLimit/sizeof(MCHAR))-1)throw RuntimeError(_T("Source Undo text exceeds its authored-data bound"));
        charge(128+(value.size()+1)*sizeof(MCHAR));
        ValueHolderMember root(new String(input?input:_T("")));auto* result=root.get_value();
        const std::wstring_view stable(result->to_string());textRoots.push_back(root);text.emplace(stable,result);return result;
    }
    Value* element(const Binding& field,int index) {
        Interval valid=FOREVER;
        switch(baseType(field.type)){
            case TYPE_FLOAT:case TYPE_WORLD:return Float::intern(field.block->GetFloat(field.id,time,valid,index));
            case TYPE_INT:return Integer::intern(field.block->GetInt(field.id,time,valid,index));
            case TYPE_BOOL:return field.block->GetInt(field.id,time,valid,index)?&true_value:&false_value;
            case TYPE_RGBA:{const auto color=field.block->GetColor(field.id,time,valid,index);return ColorValue::intern(AColor(color.r,color.g,color.b,1.f));}
            case TYPE_STRING:return string(field.block->GetStr(field.id,time,valid,index));
            case TYPE_INODE:{
                if(++nodes>nodeLimit)throw RuntimeError(_T("Source Undo snapshot exceeds 4,096 node references"));
                auto* node=field.block->GetINode(field.id,time,valid,index);return node?MAXNode::intern(node):&undefined;
            }
            default:throw RuntimeError(_T("Unsupported source Undo value"));
        }
    }
    Snapshot capture() {
        HoldSuspend noCapturedReferenceUndo;
        auto* object=target();Snapshot result;result.reserve(fields(scope).size());
        for(const auto* name:fields(scope)){
            const auto field=binding(object,name);supported(field.type);
            // This command journals static authored settings. Existing keyed
            // controllers are never replaced by a sampled scalar snapshot;
            // source-node transform animation is outside this field whitelist.
            const int entries=is_tab(field.type)?field.block->Count(field.id):1;
            if(entries<0||std::size_t(entries)>rowLimit)throw RuntimeError(_T("Source Undo supports at most 1,024 authored rows per field"));
            for(int i=0;i<entries;++i)if(auto* controller=field.block->GetControllerByID(field.id,i))
                if(controller->NumKeys()!=0)throw RuntimeError(_T("This source command requires static authored settings. Preserve the animated controller and use a static source setting first: "),new String(name));
            if(is_tab(field.type)){
                const int count=entries;
                charge(256+std::uint64_t(count)*96);ValueHolderMember root(new Array(count));auto* array=static_cast<Array*>(root.get_value());
                for(int i=0;i<count;++i)array->append(element(field,i));
                result.push_back({name,field.type,root});
            }else {charge(128);ValueHolderMember root(element(field,0));result.push_back({name,field.type,root});}
        }
        return result;
    }
    static bool equalElement(ParamType2 type,Value* a,Value* b) {
        if(a==b)return true;
        switch(baseType(type)){
            case TYPE_FLOAT:case TYPE_WORLD:return a->to_float()==b->to_float();
            case TYPE_INT:return a->to_int()==b->to_int();
            case TYPE_BOOL:return a->to_bool()==b->to_bool();
            case TYPE_RGBA:{const auto x=a->to_acolor(),y=b->to_acolor();return x.r==y.r&&x.g==y.g&&x.b==y.b;}
            // Strings use the private content-interned pool. MAXNode::intern
            // supplies one wrapper per node; undefined represents a missing row.
            case TYPE_STRING:case TYPE_INODE:return false;
            default:return false;
        }
    }
    static bool equal(const Field& a,const Field& b) {
        if(a.type!=b.type)return false;
        if(!is_tab(a.type))return equalElement(a.type,a.value.get_value(),b.value.get_value());
        const auto* x=static_cast<Array*>(a.value.get_value());const auto* y=static_cast<Array*>(b.value.get_value());if(x->size!=y->size)return false;
        for(int i=0;i<x->size;++i)if(!equalElement(a.type,x->data[i],y->data[i]))return false;return true;
    }
    void set(const Binding& field,Value* value,int index) {
        BOOL ok=FALSE;
        switch(baseType(field.type)){
            case TYPE_FLOAT:case TYPE_WORLD:ok=field.block->SetValue(field.id,time,value->to_float(),index);break;
            case TYPE_INT:ok=field.block->SetValue(field.id,time,value->to_int(),index);break;
            case TYPE_BOOL:ok=field.block->SetValue(field.id,time,value->to_bool()?1:0,index);break;
            case TYPE_RGBA:{const auto color=value->to_acolor();ok=field.block->SetValue(field.id,time,Color(color.r,color.g,color.b),index);break;}
            case TYPE_STRING:ok=field.block->SetValue(field.id,time,value->to_string(),index);break;
            case TYPE_INODE:{
                INode* node=nullptr;if(value!=&undefined){auto* wrapper=static_cast<MAXNode*>(value);if(!deletion_check_test(wrapper))node=wrapper->node;}
                ok=field.block->SetValue(field.id,time,node,index);break;
            }
            default:break;
        }
        if(!ok)throw RuntimeError(_T("Cannot restore Cyrus source parameter: "),new String(field.block->GetParamDef(field.id).int_name));
    }
    void apply(const Snapshot& snapshot,bool changedOnly) {
        auto* object=target();auto* plugin=dynamic_cast<MSPlugin*>(object);HoldSuspend noDerivedUndo;AnimateSuspend noNewKeys;
        // PB accessors only invalidate/schedule; no event pump or display solve
        // can observe partially restored parallel arrays in this native call.
        for(std::size_t f=0;f<snapshot.size();++f){
            if(changedOnly&&equal(before[f],after[f]))continue;
            const auto& saved=snapshot[f];const auto field=binding(object,saved.name);
            if(field.type!=saved.type)throw RuntimeError(_T("Source Undo parameter schema changed"));
            if(is_tab(field.type)){
                auto* array=static_cast<Array*>(saved.value.get_value());field.block->SetCount(field.id,array->size);
                for(int i=0;i<array->size;++i)set(field,array->data[i],i);
            }else set(field,saved.value.get_value(),0);
        }
        setLocal(plugin,_T("inputTimeValidity"),&undefined);setLocal(plugin,_T("orientationTimeValidity"),&undefined);
        setLocal(plugin,_T("dirty"),&true_value);setLocal(plugin,_T("containerUIChanged"),&true_value);
        if(scope==4||scope==5){setLocal(plugin,_T("interactionStateKey"),string(_T("")));setLocal(plugin,_T("interactionSceneDirty"),&true_value);}
        if(scope==1){
            setLocal(plugin,_T("containerConfigKey"),string(_T("")));
            setLocal(plugin,_T("interactionSourceCache"),new Array(0));setLocal(plugin,_T("interactionReview"),&undefined);
            setLocal(plugin,_T("interactionReviewNode"),&undefined);setLocal(plugin,_T("interactionReviewApproved"),&false_value);
            setLocal(plugin,_T("interactionReviewKind"),&undefined);
        }
        object->NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE);
    }
};
class SourceCommandRestore final:public RestoreObj {
    std::shared_ptr<SourceCommandState> state;
public:
    explicit SourceCommandRestore(std::shared_ptr<SourceCommandState> value):state(std::move(value)){}
    void Restore(int)override {if(!state->cancelled)state->apply(state->before,state->sealed);}
    void Redo()override {if(state->sealed&&!state->cancelled)state->apply(state->after,true);}
    int Size()override{return static_cast<int>(std::min<std::uint64_t>(std::numeric_limits<int>::max(),sizeof(*this)+state->bytes));}
    MSTR Description()override{return _T("Cyrus source authoring");}
};
template<class F>Value* sourceAPI(F action){try{return action();}catch(const std::exception& error){throw RuntimeError(MSTR::FromACP(error.what()));}}
}

visible_class_debug_ok(CyrusSourceCommandTicket)
class CyrusSourceCommandTicket:public Value {
public:
    std::shared_ptr<SourceCommandState> state;
    explicit CyrusSourceCommandTicket(std::shared_ptr<SourceCommandState> value):state(std::move(value)){tag=class_tag(CyrusSourceCommandTicket);}
    classof_methods(CyrusSourceCommandTicket,Value);
    void collect()override{delete this;}
    void sprin1(CharStream* output)override{output->printf(_T("<CyrusSourceCommandTicket>"));}
    Value* deep_copy(HashTable*)override{return this;}
};
visible_class_instance(CyrusSourceCommandTicket,"CyrusSourceCommandTicket");

def_visible_primitive(cyrusSourceCommandUndoVersion,"cyrusSourceCommandUndoVersion");
Value* cyrusSourceCommandUndoVersion_cf(Value**,int count){check_arg_count(cyrusSourceCommandUndoVersion,0,count);return Integer::intern(2);}
def_visible_primitive(cyrusSourceCommandBegin,"cyrusSourceCommandBegin");
Value* cyrusSourceCommandBegin_cf(Value** args,int count){
    check_arg_count(cyrusSourceCommandBegin,2,count);
    return sourceAPI([&]()->Value*{
    if(!theHold.Holding()||theHold.IsSuspended())throw RuntimeError(_T("Source authoring requires an active, unsuspended authored hold"));
    auto state=std::make_shared<SourceCommandState>(args[0],args[1]->to_int());
    if(!cyrusBoundaryAllows(state->target()))throw RuntimeError(_T("Cyrus source authoring denied"));
    state->before=state->capture();
    one_typed_value_local(CyrusSourceCommandTicket* ticket);vl.ticket=new CyrusSourceCommandTicket(state);
    auto restore=std::make_unique<SourceCommandRestore>(state);
    if(!theHold.Put(restore.get()))throw RuntimeError(_T("Cannot record the Cyrus source command"));restore.release();return_value(vl.ticket);
    });
}
def_visible_primitive(cyrusSourceCommandSeal,"cyrusSourceCommandSeal");
Value* cyrusSourceCommandSeal_cf(Value** args,int count){
    check_arg_count(cyrusSourceCommandSeal,1,count);type_check(args[0],CyrusSourceCommandTicket,_T("source authoring ticket"));
    return sourceAPI([&]()->Value*{
    auto& state=static_cast<CyrusSourceCommandTicket*>(args[0])->state;
    if(state->sealed||state->cancelled||!theHold.Holding()||theHold.IsSuspended())throw RuntimeError(_T("Source authoring ticket is not active"));
    state->after=state->capture();state->sealed=true;return &ok;
    });
}
def_visible_primitive(cyrusSourceCommandCancel,"cyrusSourceCommandCancel");
Value* cyrusSourceCommandCancel_cf(Value** args,int count){
    check_arg_count(cyrusSourceCommandCancel,1,count);type_check(args[0],CyrusSourceCommandTicket,_T("source authoring ticket"));
    return sourceAPI([&]()->Value*{
    auto& state=static_cast<CyrusSourceCommandTicket*>(args[0])->state;
    if(!state->cancelled){state->apply(state->before,false);state->cancelled=true;}return &ok;
    });
}

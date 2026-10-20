#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include "script_buffers.h"
#include "script_memory_budget.h"
#include "placement_store.h"
#include "procedural.h"
#include "native_fault_qualification.h"
#include <atomic>
#include <cmath>
#include <memory>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
namespace {
std::atomic<std::uint64_t> schedules{0},scheduleBytes{0},radiiBuffers{0},radiiBytes{0};
}
visible_class_debug_ok(CyrusCandidateSchedule)
class CyrusCandidateSchedule : public Value {
public:
    const std::vector<std::uint64_t> values;
    explicit CyrusCandidateSchedule(std::vector<std::uint64_t> v):values(std::move(v)){
        tag=class_tag(CyrusCandidateSchedule);++schedules;scheduleBytes+=values.capacity()*sizeof(std::uint64_t);
    }
    ~CyrusCandidateSchedule(){--schedules;scheduleBytes-=values.capacity()*sizeof(std::uint64_t);}
    classof_methods(CyrusCandidateSchedule,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* s) override {s->printf(_T("<CyrusCandidateSchedule:%llu>"),static_cast<unsigned long long>(values.size()));}
    Value* deep_copy(HashTable*) override {return this;}
    Value* get_property(Value** a,int n) override {
        if(n==1&&a[0]==Name::intern(_T("count")))return Integer::intern(int(values.size()));
        return Value::get_property(a,n);
    }
    Value* get_vf(Value** a,int n) override {
        if(n!=1)throw RuntimeError(_T("Schedule requires one index"));
        const int i=a[0]->to_int();if(i<1||std::size_t(i)>values.size())throw RuntimeError(_T("Schedule index out of range"));
        return Integer64::intern(values[std::size_t(i-1)]);
    }
};
visible_class_instance(CyrusCandidateSchedule,"CyrusCandidateSchedule");
visible_class_debug_ok(CyrusCollisionRadii)
class CyrusCollisionRadii : public Value {
public:
    const CyrusSharedRadii data;
    const std::vector<CyrusRadiusPair>& values() const{return *data;}
    explicit CyrusCollisionRadii(CyrusSharedRadii v):data(std::move(v)){tag=class_tag(CyrusCollisionRadii);}
    classof_methods(CyrusCollisionRadii,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* s) override {s->printf(_T("<CyrusCollisionRadii:%llu>"),static_cast<unsigned long long>(values().size()));}
    Value* deep_copy(HashTable*) override {return this;}
    Value* get_property(Value** a,int n) override {
        if(n==1&&a[0]==Name::intern(_T("count")))return Integer::intern(int(values().size()));
        return Value::get_property(a,n);
    }
    Value* get_vf(Value** a,int n) override {
        if(n!=1)throw RuntimeError(_T("Radii require one index"));
        const int i=a[0]->to_int();if(i<1||std::size_t(i)>values().size())throw RuntimeError(_T("Radius index out of range"));
        one_typed_value_local(Array* result);vl.result=new Array(2);
        for(auto v:values()[std::size_t(i-1)])vl.result->append(Float::intern(v));return_value(vl.result);
    }
};
visible_class_instance(CyrusCollisionRadii,"CyrusCollisionRadii");
Value* cyrusNativeSchedule(std::vector<std::uint64_t> values){return new CyrusCandidateSchedule(std::move(values));}
const std::vector<std::uint64_t>& cyrusScheduleValues(Value* value){
    // Disabled populations use the script's explicit empty schedule.
    if(value->is_kind_of(class_tag(Array))&&static_cast<Array*>(value)->size==0){static const std::vector<std::uint64_t> empty;return empty;}
    type_check(value,CyrusCandidateSchedule,_T("native candidate schedule"));return static_cast<CyrusCandidateSchedule*>(value)->values;
}
Value* cyrusNativeRadii(std::vector<CyrusRadiusPair> values){
    auto* data=new const std::vector<CyrusRadiusPair>(std::move(values));
    ++radiiBuffers;radiiBytes+=data->capacity()*sizeof(CyrusRadiusPair);
    CyrusSharedRadii shared(data,[](const std::vector<CyrusRadiusPair>* value){--radiiBuffers;radiiBytes-=value->capacity()*sizeof(CyrusRadiusPair);delete value;});
    return new CyrusCollisionRadii(std::move(shared));
}
CyrusSharedRadii cyrusRadiusData(Value* value){type_check(value,CyrusCollisionRadii,_T("native immutable collision radii"));return static_cast<CyrusCollisionRadii*>(value)->data;}
Value* cyrusRadiusValue(CyrusSharedRadii values){if(!values)throw RuntimeError(_T("Missing native radius ownership"));return new CyrusCollisionRadii(std::move(values));}
std::size_t cyrusRadiusCount(Value* value){
    if(value->is_kind_of(class_tag(CyrusCollisionRadii)))return static_cast<CyrusCollisionRadii*>(value)->values().size();
    type_check(value,Array,_T("collision radii"));return static_cast<Array*>(value)->size;
}
std::array<double,2> cyrusRadiusAt(Value* value,std::size_t i){
    if(i>=cyrusRadiusCount(value))throw RuntimeError(_T("Radius index out of range"));
    if(value->is_kind_of(class_tag(CyrusCollisionRadii))){const auto r=static_cast<CyrusCollisionRadii*>(value)->values()[i];return {r[0],r[1]};}
    auto* item=static_cast<Array*>(value)->data[i];type_check(item,Array,_T("radius pair"));auto* pair=static_cast<Array*>(item);
    if(pair->size!=2)throw RuntimeError(_T("Expected XY and 3D radii"));
    std::array<double,2> r{pair->data[0]->to_double(),pair->data[1]->to_double()};
    if(!std::isfinite(r[0])||!std::isfinite(r[1])||r[0]<0||r[1]<0)throw RuntimeError(_T("Invalid collision radius"));return r;
}
def_visible_primitive(cyrusScriptMemoryVersion,"cyrusScriptMemoryVersion");
Value* cyrusScriptMemoryVersion_cf(Value**,int n){check_arg_count(cyrusScriptMemoryVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusScriptMemoryTarget,"cyrusScriptMemoryTarget");
Value* cyrusScriptMemoryTarget_cf(Value** a,int n){
    check_arg_count(cyrusScriptMemoryTarget,3,n);
    const auto heap=a[0]->to_int64(),free=a[1]->to_int64(),required=a[2]->to_int64();
    if(heap<0||free<0||required<0)throw RuntimeError(_T("Invalid script workspace size"));
    MEMORYSTATUSEX status{};status.dwLength=sizeof(status);
    if(!GlobalMemoryStatusEx(&status))throw RuntimeError(_T("Cannot read system commit headroom"));
    try{return Integer64::intern(static_cast<INT64>(cyrus::script_memory::target(heap,free,required,status.ullAvailPageFile)));}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}

def_visible_primitive(cyrusNativeMemoryAdmit,"cyrusNativeMemoryAdmit");
Value* cyrusNativeMemoryAdmit_cf(Value** a,int n){
    check_arg_count(cyrusNativeMemoryAdmit,1,n);const auto pool=a[0]->to_int64();
    if(pool<0||pool>1000000)throw RuntimeError(_T("Invalid native successor population"));
    // Simultaneous receiver/base/prepared/output buffers, generator/Relax
    // scratch, acceptance Sample plus schedule/index/hash/neighbor allowance.
    // Clearance adds two metric grids, candidate admission/replay indices and
    // blocker state. Charge their coexistence before preparing any successor.
    // A conservative admission model, not reported physical allocation.
    constexpr std::uint64_t perCandidate=6*sizeof(cyrus::placements::Record)+4*sizeof(amin::Instance)+sizeof(cyrus::procedural::Sample)+384;
    const auto additional=std::uint64_t(pool)*perCandidate+64ULL*1024*1024;
    MEMORYSTATUSEX status{};status.dwLength=sizeof(status);
    if(!GlobalMemoryStatusEx(&status))throw RuntimeError(_T("Cannot read native commit headroom"));
    try{cyrus::owned::fault(1);cyrus::script_memory::admitNative(additional,status.ullAvailPageFile);return Integer64::intern(INT64(additional));}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusScriptBufferStats,"cyrusScriptBufferStats");
Value* cyrusScriptBufferStats_cf(Value**,int n){
    check_arg_count(cyrusScriptBufferStats,0,n);one_typed_value_local(Array* result);vl.result=new Array(4);
    for(auto value:{schedules.load(),scheduleBytes.load(),radiiBuffers.load(),radiiBytes.load()})vl.result->append(Integer64::intern(value));return_value(vl.result);
}

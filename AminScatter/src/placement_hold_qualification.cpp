// Compiled only with CYRUS_PLACEMENT_QUALIFICATION. Never part of a product
// package. Study actual Max holds without changing production Undo behavior.
#include <max.h>
#include <hold.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include "placement_value.h"
#include <array>
#include <limits>
#include <memory>
#include <optional>
#include <stdexcept>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
namespace {
using cyrus::placements::View;
struct Counters {std::uint64_t created=0,destroyed=0,restore0=0,restore1=0,redo=0,size=0,end=0;};
struct Event {std::uint64_t kind=0,record=0,pins=0;};
Counters counts;std::array<Event,256> events{};std::size_t eventCount=0;bool overflow=false;
std::optional<View> current;
class Probe;
std::array<Probe*,64> records{};
void event(std::uint64_t kind,std::uint64_t record,std::uint64_t pins) noexcept {
    if(eventCount<events.size())events[eventCount++]={kind,record,pins};else overflow=true;
}
std::uint64_t pins(const std::optional<View>& a,const std::optional<View>& b) {
    std::uint64_t size=a?a->baseBytes()+a->selectionBytes():0;
    if(b){if(!a||a->token().generation!=b->token().generation)size+=b->baseBytes();
        if(!a||a->token().view!=b->token().view)size+=b->selectionBytes();}
    return size;
}
class Probe final : public RestoreObj {
    std::optional<View> before_,after_;bool captured_=false;
    std::size_t slot_=0;std::uint64_t id_=0;
public:
    explicit Probe(const std::optional<View>& value):before_(value) {
        while(slot_<records.size()&&records[slot_])++slot_;
        if(slot_==records.size())throw std::runtime_error("Owned hold probe exceeds 64 records");
        id_=++counts.created;records[slot_]=this;event(1,id_,retained());
    }
    ~Probe(){records[slot_]=nullptr;++counts.destroyed;event(2,id_,retained());}
    std::uint64_t retained() const {return pins(before_,after_);}
    void Restore(int undo) override {
        if(undo){++counts.restore1;if(!captured_){after_=current;captured_=true;}}else ++counts.restore0;
        current=before_;event(undo?4:3,id_,retained());
    }
    void Redo() override {++counts.redo;if(captured_)current=after_;event(5,id_,retained());}
    int Size() override {++counts.size;const auto size=sizeof(Probe)+retained();event(6,id_,retained());return static_cast<int>(std::min(size,std::uint64_t(std::numeric_limits<int>::max())));}
    void EndHold() override {++counts.end;event(7,id_,retained());}
    MSTR Description() override {return _T("Native placement ownership qualification");}
};
template<class F> Value* api(F action){try{return action();}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}}
std::size_t live(){std::size_t n=0;for(auto* r:records)if(r)++n;return n;}
}
def_visible_primitive(cyrusOwnedPlacementProbeVersion,"cyrusOwnedPlacementProbeVersion");
Value* cyrusOwnedPlacementProbeVersion_cf(Value**,int n){check_arg_count(cyrusOwnedPlacementProbeVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusOwnedPlacementProbeSeed,"cyrusOwnedPlacementProbeSeed");
Value* cyrusOwnedPlacementProbeSeed_cf(Value** a,int n){check_arg_count(cyrusOwnedPlacementProbeSeed,1,n);return api([&]()->Value*{
    if(theHold.Holding()||live())throw RuntimeError(_T("Seed only before the owned probe history"));
    if(a[0]==&undefined)current.reset();else current=cyrusPlacementView(a[0]);return &ok;
});}
def_visible_primitive(cyrusOwnedPlacementProbeSet,"cyrusOwnedPlacementProbeSet");
Value* cyrusOwnedPlacementProbeSet_cf(Value** a,int n){check_arg_count(cyrusOwnedPlacementProbeSet,1,n);return api([&]()->Value*{
    if(!theHold.Holding()||!current)throw RuntimeError(_T("Owned publication probe requires its active hold and seed"));
    const auto& next=cyrusPlacementView(a[0]);if(next.token().owner!=current->token().owner)throw RuntimeError(_T("Owned hold probe owner differs"));
    auto restore=std::make_unique<Probe>(current);if(!theHold.Put(restore.get()))throw RuntimeError(_T("Cannot record owned native publication"));
    restore.release();current=next;event(8,counts.created,0);return &ok;
});}
def_visible_primitive(cyrusOwnedPlacementProbeHold,"cyrusOwnedPlacementProbeHold");
Value* cyrusOwnedPlacementProbeHold_cf(Value** a,int n){check_arg_count(cyrusOwnedPlacementProbeHold,2,n);return api([&]()->Value*{
    type_check(a[1],String,_T("owned hold label"));const std::wstring label=a[1]->to_string();if(label.size()>128)throw RuntimeError(_T("Owned hold label too long"));
    switch(a[0]->to_int()){
        case 1:theHold.Begin();break;case 2:theHold.Accept(MSTR(label.c_str()));break;case 3:theHold.Cancel();break;
        case 4:theHold.Restore();break;case 5:theHold.SuperBegin();break;case 6:theHold.SuperAccept(MSTR(label.c_str()));break;case 7:theHold.SuperCancel();break;
        default:throw RuntimeError(_T("Unknown owned hold operation"));
    }return &ok;
});}
def_visible_primitive(cyrusOwnedPlacementProbeState,"cyrusOwnedPlacementProbeState");
Value* cyrusOwnedPlacementProbeState_cf(Value**,int n){check_arg_count(cyrusOwnedPlacementProbeState,0,n);return api([&]()->Value*{
    const auto token=current?current->token():cyrus::placements::Token{};std::uint64_t retained=0;for(auto* r:records)if(r)retained+=r->retained();
    one_typed_value_local(Array* result);vl.result=new Array(20);
    for(auto v:{token.owner,token.generation,token.view,current?std::uint64_t(current->size()):0,
               counts.created,counts.destroyed,counts.restore0,counts.restore1,counts.redo,counts.size,counts.end,
               std::uint64_t(live()),retained,cyrus::placements::metrics().liveBytes,std::uint64_t(eventCount),std::uint64_t(overflow),
               std::uint64_t(theHold.Holding()),std::uint64_t(theHold.GetSuperBeginDepth())})vl.result->append(Integer64::intern(static_cast<INT64>(v)));
    return_value(vl.result);
});}
def_visible_primitive(cyrusOwnedPlacementProbeEvents,"cyrusOwnedPlacementProbeEvents");
Value* cyrusOwnedPlacementProbeEvents_cf(Value**,int n){check_arg_count(cyrusOwnedPlacementProbeEvents,0,n);
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(eventCount));
    for(std::size_t i=0;i<eventCount;++i){const auto e=events[i];vl.row=new Array(3);vl.result->append(vl.row);for(auto v:{e.kind,e.record,e.pins})vl.row->append(Integer64::intern(static_cast<INT64>(v)));}return_value(vl.result);
}
def_visible_primitive(cyrusOwnedPlacementProbeHoldSize,"cyrusOwnedPlacementProbeHoldSize");
Value* cyrusOwnedPlacementProbeHoldSize_cf(Value**,int n){check_arg_count(cyrusOwnedPlacementProbeHoldSize,0,n);return Integer64::intern(static_cast<INT64>(theHold.Size()));}

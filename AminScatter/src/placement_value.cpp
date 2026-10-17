#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include "placement_value.h"
#include "placement_transport.h"
#include "placement_materialization.h"
#include <charconv>
#include <limits>
#include <stdexcept>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

namespace p=cyrus::placements;
namespace {
template<class F> Value* api(F f){try{return f();}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}}
std::uint64_t unsignedValue(Value* v) {
    if(!cyrus::rows::integer(v)||v->to_int64()<0)throw RuntimeError(_T("Expected nonnegative native placement integer"));
    return std::uint64_t(v->to_int64());
}
p::Token token(Value* value) {
    type_check(value,Array,_T("native placement token"));auto* a=static_cast<Array*>(value);
    if(a->size!=3)throw RuntimeError(_T("Native placement token requires owner, generation and view"));
    return {unsignedValue(a->data[0]),unsignedValue(a->data[1]),unsignedValue(a->data[2])};
}
Value* tokenValue(p::Token t) {
    one_typed_value_local(Array* result);vl.result=new Array(3);
    for(auto n:{t.owner,t.generation,t.view})vl.result->append(Integer64::intern(static_cast<INT64>(n)));return_value(vl.result);
}
bool candidate(const std::string& id,std::uint64_t& key) {
    if(id.size()<3||id[0]!='c'||id[1]!=':'||(id.size()>3&&id[2]=='0'))return false;
    const auto parsed=std::from_chars(id.data()+2,id.data()+id.size(),key);
    return parsed.ec==std::errc{}&&parsed.ptr==id.data()+id.size()&&key<=std::uint64_t(std::numeric_limits<INT64>::max());
}
}
visible_class_debug_ok(CyrusPlacementBuffer)
class CyrusPlacementBuffer : public Value {
public:
    const p::View value;
    explicit CyrusPlacementBuffer(p::View view):value(std::move(view)){tag=class_tag(CyrusPlacementBuffer);}
    classof_methods(CyrusPlacementBuffer,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* s) override {s->printf(_T("<CyrusPlacementBuffer:%llu>"),static_cast<unsigned long long>(value.size()));}
    Value* deep_copy(HashTable*) override {return this;}
    Value* get_property(Value** a,int n) override {
        if(n==1&&a[0]==Name::intern(_T("count")))return Integer::intern(static_cast<int>(value.size()));
        return Value::get_property(a,n);
    }
};
visible_class_instance(CyrusPlacementBuffer,"CyrusPlacementBuffer");
Value* cyrusPlacementValue(p::View value){return new CyrusPlacementBuffer(std::move(value));}
bool cyrusIsPlacementValue(Value* value){return value&&value->is_kind_of(class_tag(CyrusPlacementBuffer));}
const p::View& cyrusPlacementView(Value* value){type_check(value,CyrusPlacementBuffer,_T("immutable native placement buffer"));return static_cast<CyrusPlacementBuffer*>(value)->value;}

def_visible_primitive(cyrusPlacementNativeVersion,"cyrusPlacementNativeVersion");
Value* cyrusPlacementNativeVersion_cf(Value**,int n){check_arg_count(cyrusPlacementNativeVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusPlacementOwner,"cyrusPlacementOwner");
Value* cyrusPlacementOwner_cf(Value**,int n){check_arg_count(cyrusPlacementOwner,0,n);return api([]{return Integer64::intern(static_cast<INT64>(p::newOwner()));});}
def_visible_primitive(cyrusPlacementToken,"cyrusPlacementToken");
Value* cyrusPlacementToken_cf(Value** a,int n){check_arg_count(cyrusPlacementToken,1,n);return tokenValue(cyrusPlacementView(a[0]).token());}
def_visible_primitive(cyrusPlacementSourceUsage,"cyrusPlacementSourceUsage");
Value* cyrusPlacementSourceUsage_cf(Value** a,int n){check_arg_count(cyrusPlacementSourceUsage,1,n);return api([&]()->Value*{
    const auto counts=cyrusPlacementView(a[0]).sourceUsage();
    one_typed_value_local(Array* result);vl.result=new Array(static_cast<int>(counts.size()));
    for(auto count:counts)vl.result->append(Integer::intern(int(count)));return_value(vl.result);
});}

// Explicit small boundary for authored commands/qualification. This is never a
// full-population fallback: migrated generation must construct native records.
def_visible_primitive(cyrusPlacementCapture,"cyrusPlacementCapture");
Value* cyrusPlacementCapture_cf(Value** a,int n){check_arg_count(cyrusPlacementCapture,5,n);return api([&]()->Value*{
    const auto owner=unsignedValue(a[0]),stage=unsignedValue(a[1]),sources=unsignedValue(a[2]),receiver=unsignedValue(a[3]);
    if(stage<1||stage>2||sources>p::maxSources||receiver>=128)throw RuntimeError(_T("Invalid native placement capture context"));
    type_check(a[4],Array,_T("bounded placement input"));auto* rows=static_cast<Array*>(a[4]);
    if(rows->size>int(p::maxPage))throw RuntimeError(_T("Explicit placement capture exceeds 500 rows; no bulk script fallback"));
    p::Builder builder(owner,stage==1?p::Stage::Candidates:p::Stage::Edited,static_cast<std::uint32_t>(sources),rows->size);
    for(int i=0;i<rows->size;++i) {
        type_check(rows->data[i],Array,_T("current placement row"));auto* row=static_cast<Array*>(rows->data[i]);
        if(stage==1)cyrus::rows::raw(row);else cyrus::rows::edited(row);
        p::Record r;const auto& tm=row->data[0]->to_matrix3();
        for(int j=0;j<4;++j)for(int k=0;k<3;++k)r.transform[std::size_t(j*3+k)]=tm.GetRow(j)[k];
        const auto b=row->data[4]->to_point3();r.bary={b.x,b.y,b.z};r.face=row->data[3]->to_int();r.source=row->data[1]->to_int();
        r.receiver=static_cast<std::uint32_t>(receiver);r.band=cyrus::rows::owner(row);r.flags=row->data[6]==&true_value?p::Protected:0;
        if(stage==1){r.identity=unsignedValue(row->data[2]);builder.appendGenerated(r);}
        else {
            const std::wstring wide=row->data[2]->to_string();std::string text;text.reserve(wide.size());
            if(wide.empty()||wide.size()>p::maxIdentity)throw RuntimeError(_T("Native placement identity exceeds current procedural key bounds"));
            for(auto c:wide){if(c<1||c>127)throw RuntimeError(_T("Native placement identity must be an ASCII key"));text.push_back(static_cast<char>(c));}
            if(candidate(text,r.identity))builder.appendGenerated(r);else builder.appendAuthored(r,text);
        }
    }
    return cyrusPlacementValue(builder.freeze());
});}
def_visible_primitive(cyrusPlacementPage,"cyrusPlacementPage");
Value* cyrusPlacementPage_cf(Value** a,int n){check_arg_count(cyrusPlacementPage,4,n);return api([&]()->Value*{
    const auto& view=cyrusPlacementView(a[0]);const auto offset=unsignedValue(a[2]);
    const auto records=view.page(std::size_t(offset),std::size_t(unsignedValue(a[3])),token(a[1]));
    p::MaterializationScope measurement(p::TransportStage::Readback);
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(records.size()));measurement.populationArray();
    for(std::size_t i=0;i<records.size();++i) {
        const auto& r=records[i];Matrix3 tm(1);for(int j=0;j<4;++j)tm.SetRow(j,Point3(r.transform[std::size_t(j*3)],r.transform[std::size_t(j*3+1)],r.transform[std::size_t(j*3+2)]));
        vl.row=new Array(8);measurement.row();vl.result->append(vl.row);auto* matrix=new Matrix3Value(tm);measurement.matrix();vl.row->append(matrix);vl.row->append(Integer::intern(r.source));
        if(view.stage()==p::Stage::Candidates)vl.row->append(Integer64::intern(static_cast<INT64>(r.identity)));
        else {const auto id=view.textIdentity(std::size_t(offset)+i);auto* text=new String(std::wstring(id.begin(),id.end()).c_str());measurement.string();vl.row->append(text);}
        vl.row->append(Integer::intern(r.face));vl.row->append(new Point3Value(Point3(r.bary[0],r.bary[1],r.bary[2])));
        vl.row->append(Integer64::intern(static_cast<INT64>(r.band)));vl.row->append(r.flags&p::Protected?&true_value:&false_value);vl.row->append(Integer::intern(2));
    }return_value(vl.result);
});}
def_visible_primitive(cyrusPlacementSelect,"cyrusPlacementSelect");
Value* cyrusPlacementSelect_cf(Value** a,int n){check_arg_count(cyrusPlacementSelect,3,n);return api([&]()->Value*{
    const auto& view=cyrusPlacementView(a[0]);view.require(token(a[1]));type_check(a[2],Array,_T("bounded native selection"));auto* ids=static_cast<Array*>(a[2]);
    if(ids->size>int(p::maxPage))throw RuntimeError(_T("Explicit placement selection exceeds 500 indices"));
    std::vector<std::uint32_t> selected;selected.reserve(ids->size);
    for(int i=0;i<ids->size;++i){const auto index=unsignedValue(ids->data[i]);if(index>=view.size())throw RuntimeError(_T("Native selection index is out of range"));selected.push_back(static_cast<std::uint32_t>(index));}
    return cyrusPlacementValue(view.select(selected));
});}
def_visible_primitive(cyrusPlacementCompact,"cyrusPlacementCompact");
Value* cyrusPlacementCompact_cf(Value** a,int n){check_arg_count(cyrusPlacementCompact,2,n);return api([&]()->Value*{const auto& view=cyrusPlacementView(a[0]);view.require(token(a[1]));return cyrusPlacementValue(view.compact());});}
// Native receiver-cache join. Bounded metadata only crosses the script boundary.
// Keep cache inputs immutable and preserve their explicit slots/face offsets.
def_visible_primitive(cyrusPlacementJoin,"cyrusPlacementJoin");
Value* cyrusPlacementJoin_cf(Value** a,int n){check_arg_count(cyrusPlacementJoin,1,n);return api([&]()->Value*{
    type_check(a[0],Array,_T("native receiver placements"));auto* inputs=static_cast<Array*>(a[0]);
    if(inputs->size<1||inputs->size>128)throw RuntimeError(_T("Native join requires 1..128 receiver buffers"));
    const auto& first=cyrusPlacementView(inputs->data[0]);std::size_t size=0;
    for(int i=0;i<inputs->size;++i){const auto& view=cyrusPlacementView(inputs->data[i]);
        if(view.token().owner!=first.token().owner||view.stage()!=first.stage()||view.sources()!=first.sources())throw RuntimeError(_T("Native join owner, stage or frozen source table differs"));
        if(view.size()>p::maxRecords-size)throw RuntimeError(_T("Native join exceeds one million candidates"));size+=view.size();}
    if(inputs->size==1)return inputs->data[0];
    p::Builder builder(first.token().owner,first.stage(),first.sources(),size);
    for(int i=0;i<inputs->size;++i){const auto& view=cyrusPlacementView(inputs->data[i]);for(std::size_t j=0;j<view.size();++j){auto r=view.at(j);if(r.flags&p::Authored)builder.appendAuthored(r,view.authored(j));else builder.appendGenerated(r);}}
    return cyrusPlacementValue(builder.freeze());
});}
def_visible_primitive(cyrusPlacementEdited,"cyrusPlacementEdited");
Value* cyrusPlacementEdited_cf(Value** a,int n){check_arg_count(cyrusPlacementEdited,2,n);return api([&]()->Value*{const auto& view=cyrusPlacementView(a[0]);view.require(token(a[1]));return cyrusPlacementValue(view.edited());});}
def_visible_primitive(cyrusPlacementTransportStats,"cyrusPlacementTransportStats");
Value* cyrusPlacementTransportStats_cf(Value** a,int n){
    if(n<0||n>1)throw RuntimeError(_T("Transport statistics accept an optional observation Boolean"));
    if(n==1){if(a[0]!=&true_value&&a[0]!=&false_value)throw RuntimeError(_T("Transport observation requires a Boolean"));p::observeMaterializations(a[0]==&true_value);}
    two_typed_value_locals(Array* result,Array* stage);vl.result=new Array(int(p::TransportStage::Count)+1);vl.result->append(p::observingMaterializations()?&true_value:&false_value);
    const bool covered[]={true,true,false,true,true,true,true,true,true,true};std::size_t index=0;
    static_assert(std::size(covered)==std::size_t(p::TransportStage::Count));
    for(const auto& c:p::materializations()){vl.stage=new Array(5);vl.result->append(vl.stage);vl.stage->append(covered[index++]?&true_value:&false_value);for(auto value:{c.rows,c.matrices,c.strings,c.populationArrays})vl.stage->append(Integer64::intern(static_cast<INT64>(value)));}
    return_value(vl.result);
}
def_visible_primitive(cyrusPlacementMemoryStats,"cyrusPlacementMemoryStats");
Value* cyrusPlacementMemoryStats_cf(Value**,int n){check_arg_count(cyrusPlacementMemoryStats,0,n);const auto s=p::metrics();one_typed_value_local(Array* result);vl.result=new Array(8);
    for(auto v:{s.liveBytes,s.peakBytes,s.totalBytes,s.allocations,s.liveAllocations,s.liveStores,s.liveSelections,s.readbackRows})vl.result->append(Integer64::intern(static_cast<INT64>(v)));return_value(vl.result);}

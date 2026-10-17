#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include "placement_value.h"
#include "placement_transport.h"
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
const p::View& cyrusPlacementView(Value* value){type_check(value,CyrusPlacementBuffer,_T("immutable native placement buffer"));return static_cast<CyrusPlacementBuffer*>(value)->value;}

def_visible_primitive(cyrusPlacementNativeVersion,"cyrusPlacementNativeVersion");
Value* cyrusPlacementNativeVersion_cf(Value**,int n){check_arg_count(cyrusPlacementNativeVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusPlacementOwner,"cyrusPlacementOwner");
Value* cyrusPlacementOwner_cf(Value**,int n){check_arg_count(cyrusPlacementOwner,0,n);return api([]{return Integer64::intern(static_cast<INT64>(p::newOwner()));});}
def_visible_primitive(cyrusPlacementToken,"cyrusPlacementToken");
Value* cyrusPlacementToken_cf(Value** a,int n){check_arg_count(cyrusPlacementToken,1,n);return tokenValue(cyrusPlacementView(a[0]).token());}

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
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(records.size()));
    for(std::size_t i=0;i<records.size();++i) {
        const auto& r=records[i];Matrix3 tm(1);for(int j=0;j<4;++j)tm.SetRow(j,Point3(r.transform[std::size_t(j*3)],r.transform[std::size_t(j*3+1)],r.transform[std::size_t(j*3+2)]));
        vl.row=new Array(8);vl.result->append(vl.row);vl.row->append(new Matrix3Value(tm));vl.row->append(Integer::intern(r.source));
        if(view.stage()==p::Stage::Candidates)vl.row->append(Integer64::intern(static_cast<INT64>(r.identity)));
        else {const auto id=view.textIdentity(std::size_t(offset)+i);vl.row->append(new String(std::wstring(id.begin(),id.end()).c_str()));}
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
def_visible_primitive(cyrusPlacementMemoryStats,"cyrusPlacementMemoryStats");
Value* cyrusPlacementMemoryStats_cf(Value**,int n){check_arg_count(cyrusPlacementMemoryStats,0,n);const auto s=p::metrics();one_typed_value_local(Array* result);vl.result=new Array(8);
    for(auto v:{s.liveBytes,s.peakBytes,s.totalBytes,s.allocations,s.liveAllocations,s.liveStores,s.liveSelections,s.readbackRows})vl.result->append(Integer64::intern(static_cast<INT64>(v)));return_value(vl.result);}

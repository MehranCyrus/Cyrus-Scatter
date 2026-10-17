// Explicit read-only diagnostic. Traversal is outside Update timing windows;
// nothing calls this from panel binding, redraw, generation or idle callbacks.
#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <chrono>
#include <cstdint>
#include <exception>
#include <unordered_set>
#include <vector>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

def_visible_primitive(cyrusObservePlacementValues,"cyrusObservePlacementValues");
Value* cyrusObservePlacementValues_cf(Value** args,int count) {
    check_arg_count(cyrusObservePlacementValues,1,count);
    type_check(args[0],Array,_T("explicit placement observation roots"));
    try {
    const auto start=std::chrono::steady_clock::now();
    // Count exact reachable Value identities once, including shared row/matrix
    // aliases and cycles. Do not traverse host references or execute getters.
    // This intentionally bounded diagnostic allocates its own visited table.
    constexpr std::size_t maxValues=8000000,maxSlots=64000000;
    std::unordered_set<Value*> seen;
    std::vector<Array*> pending{static_cast<Array*>(args[0])};
    std::uint64_t arrays=0,capacity=0,used=0,rows=0,matrices=0,anchors=0,
        strings=0,characters=0,integers=0,int64s=0,floats=0,doubles=0,other=0,objects=0;
    auto visit=[&](Value* value) {
        if(!value||!seen.insert(value).second)return;
        if(seen.size()>maxValues)throw RuntimeError(_T("Placement observation exceeds eight million unique values"));
        if(value->is_kind_of(class_tag(Array))) {
            auto* array=static_cast<Array*>(value);
            if(array->size<0||array->data_size<array->size)throw RuntimeError(_T("Invalid observed array capacity"));
            ++arrays;capacity+=std::uint64_t(array->data_size);used+=std::uint64_t(array->size);objects+=sizeof(Array);
            if(capacity>maxSlots)throw RuntimeError(_T("Placement observation exceeds 64 million array slots"));
            if(array->size==8&&array->data[0]&&array->data[0]->is_kind_of(class_tag(Matrix3Value)))++rows;
            pending.push_back(array);
        } else if(value->is_kind_of(class_tag(Matrix3Value))) {++matrices;objects+=sizeof(Matrix3Value);}
        else if(value->is_kind_of(class_tag(Point3Value))) {++anchors;objects+=sizeof(Point3Value);}
        else if(value->is_kind_of(class_tag(String))) {++strings;characters+=wcslen(value->to_string());objects+=sizeof(String);}
        else if(value->is_kind_of(class_tag(Integer64))) {++int64s;objects+=sizeof(Integer64);}
        else if(value->is_kind_of(class_tag(Integer))) {++integers;objects+=sizeof(Integer);}
        else if(value->is_kind_of(class_tag(Float))) {++floats;objects+=sizeof(Float);}
        else if(value->is_kind_of(class_tag(Double))) {++doubles;objects+=sizeof(Double);}
        else ++other;
    };
    // The supplied roots array is an observer container, excluded from totals.
    seen.insert(args[0]);
    for(std::size_t i=0;i<pending.size();++i) {
        const auto* array=pending[i];
        for(int j=0;j<array->size;++j)visit(array->data[j]);
    }
    const auto us=std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now()-start).count();
    one_typed_value_local(Array* result);vl.result=new Array(16);
    // knownObjectBytes and pointerBytes are exact requested SDK object/array
    // payload sizes, not allocator/GC, string capacity, host or process memory.
    for(auto value:{arrays,capacity,used,rows,matrices,anchors,strings,characters,
                   integers,int64s,floats,doubles,other,objects,capacity*sizeof(Value*),std::uint64_t(us)})
        vl.result->append(Integer64::intern(static_cast<INT64>(value)));
    return_value(vl.result);
    } catch(const std::exception& error) {
        throw RuntimeError(MSTR::FromACP(error.what()));
    }
}

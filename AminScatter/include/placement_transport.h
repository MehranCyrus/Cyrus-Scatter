#pragma once
// Host-only exact row contract. Include after MAXScript foundation headers.
#include <maxscript/foundation/strings.h>
#include <cmath>
#include <cstdint>

namespace cyrus::rows {
inline bool integer(Value* value) {
    return value->is_kind_of(class_tag(Integer))||value->is_kind_of(class_tag(Integer64));
}
inline void require(bool ok,const MCHAR* message) { if(!ok)throw RuntimeError(message); }
inline void validate(Array* row) {
    require(row->size==8,_T("Placement requires exactly eight fields"));
    require(integer(row->data[7])&&row->data[7]->to_int64()==2,_T("Unsupported placement row version"));
    require(integer(row->data[5])&&row->data[5]->to_int64()>=0,_T("Invalid Band owner identity"));
    require(row->data[6]==&true_value||row->data[6]==&false_value,_T("Invalid placement protection flag"));
    type_check(row->data[0],Matrix3Value,_T("placement transform"));
    require(integer(row->data[1])&&row->data[1]->to_int64()>0&&row->data[1]->to_int64()<=INT_MAX,_T("Invalid placement source"));
    require(integer(row->data[3])&&row->data[3]->to_int64()>0&&row->data[3]->to_int64()<=INT_MAX,_T("Invalid candidate surface face"));
    const auto b=row->data[4]->to_point3();
    require(std::isfinite(b.x)&&std::isfinite(b.y)&&std::isfinite(b.z),_T("Nonfinite surface anchor"));
}
inline void raw(Array* row) {
    validate(row);
    require(integer(row->data[2])&&row->data[2]->to_int64()>=0,_T("Invalid candidate identity"));
    require(row->data[6]==&false_value,_T("Raw candidate cannot contain protected Edit state"));
}
inline void edited(Array* row) {
    validate(row);type_check(row->data[2],String,_T("placement output identity"));
    require(row->data[2]->to_string()[0]!=0,_T("Empty output identity"));
}
// Copying, inspection and display accept either current pipeline stage. This
// does not relax the exact row layout or raw/edited identity/protection rules.
inline void current(Array* row) {
    if(row->size==8&&integer(row->data[2]))raw(row);else edited(row);
}
inline bool protectedEdit(Array* row) {
    edited(row);return row->data[6]==&true_value;
}
inline std::uint64_t owner(Array* row) { validate(row);return std::uint64_t(row->data[5]->to_int64()); }
}

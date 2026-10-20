#pragma once
#include "cyrus_arrange/path.h"
#include <max.h>
namespace cyrus::arrange::host {
struct CapturedPath {
    std::vector<CubicBezier> curves;
    bool closed{};
    Interval validity{FOREVER};
};
// Host-thread only. Validation evaluates the shape but does not sample or solve.
void validate_path_node(INode*,std::uint32_t curve_index,TimeValue);
CapturedPath capture_path(INode*,std::uint32_t curve_index,Vec3 origin_mm,double mm_per_unit,TimeValue);
bool same_path(const CapturedPath&,const CapturedPath&) noexcept;
}

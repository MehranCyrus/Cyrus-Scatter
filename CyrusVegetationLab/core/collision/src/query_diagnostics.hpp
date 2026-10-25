#pragma once

// Private test/diagnostic interface. This is not a frozen public declaration.
// Each thread observes its last operation; no diagnostic value changes a
// query's geometry, budgets or result. Reading this is not a host ABI promise.
#include <cyrus_vegetation/prototype_v1.hpp>
#include <cstddef>

namespace cyrus::vegetation::prototype_v1::collision_detail {

enum class NativeOperation { None, Point, Capsule };
struct QueryDiagnostics {
    NativeOperation operation = NativeOperation::None;
    std::size_t native_calls = 0;
    std::size_t native_hits = 0;
    std::size_t analytic_contacts = 0;
    std::size_t native_misses_refined = 0;
    std::size_t accounted_owned_bytes = 0;
    std::size_t accounted_scratch_bytes = 0;
    bool first_raw_hit_available = false;
    bool first_raw_normal_valid = false;
    Id first_raw_obstacle_id = 0;
    Vec3 first_raw_query_point, first_raw_obstacle_point;
    Vec3 first_raw_outward_normal;
    double first_raw_penetration_depth_m = 0.0;
    double first_raw_consistency_error_m = 0.0;
};

// A copy is returned so the next operation cannot overwrite a test's receipt.
QueryDiagnostics last_query_diagnostics() noexcept;

} // namespace cyrus::vegetation::prototype_v1::collision_detail

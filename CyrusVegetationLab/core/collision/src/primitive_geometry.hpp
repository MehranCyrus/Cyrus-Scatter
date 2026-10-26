#pragma once

// Owner A private analytic refinement. This is NOT the Jolt backend.
// The public adapter executes Jolt queries separately, then uses these primitive
// witnesses to qualify material coordinates and solid/exclusion semantics.
#include <cyrus_vegetation/prototype_v1.hpp>

namespace cyrus::vegetation::prototype_v1::collision_detail {

struct GeometryWitness {
    double u = 0.0;
    Vec3 axis, surface, normal;
    double axis_signed_distance = 0.0; // Before capsule radius / clearance.
    double numerical_bound_m = 0.0;   // Round-off allowance; not a depth estimate.
    bool qualified = false;
};

// Inputs are finite, in the adapter's admitted local coordinate/feature profile.
// Quaternion inputs must already have passed rigid/unit admission. The helpers
// normalize a local copy defensively; they never mutate an input obstacle.
// No dynamic allocation; all loops have small compile-time bounds.
GeometryWitness primitive_point(const Obstacle& obstacle, Vec3 point) noexcept;
GeometryWitness primitive_segment(const Obstacle& obstacle, Vec3 a, Vec3 b) noexcept;

// Independently rechecks u/axis, surface membership, unit outward normal,
// normal cone and signed-distance reconstruction. Query tolerances are NOT used
// to conceal failed qualification; this uses a scale-dependent floating-point
// round-off allowance and returns false for unsupported/nonfinite arithmetic.
bool qualify_primitive_witness(const Obstacle& obstacle, Vec3 a, Vec3 b,
                              const GeometryWitness& witness) noexcept;

} // namespace cyrus::vegetation::prototype_v1::collision_detail

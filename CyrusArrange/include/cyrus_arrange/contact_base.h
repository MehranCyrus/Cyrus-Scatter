#pragma once
#include "cyrus_arrange/assets.h"

namespace cyrus::arrange {
enum class ContactBaseKind { Refined, FullBounds, NoReferencedContact };
struct ContactBase {
    ContactBaseKind kind{ContactBaseKind::FullBounds};
    Vec3 anchor;
    std::vector<Vec3> footprint;
    std::uint64_t work{};
    std::size_t contact_points{};
    bool limited{};
};
// Automatic scene-source policy only. Does not alter portable authored metadata
// or mesh data. Convex support half-planes enclose every referenced triangle
// portion within the default contact band. Uncertain/limited shapes use bounds.
// At most 32 directions, 64 output vertices and 8m charged work. The requested
// budget must at least cover the admitted vertex bounds scan.
ContactBase infer_contact_base(const Mesh&,const AssetLimits& = {},std::uint64_t max_work=8000000);
// Local XY center of the existing contact envelope, at anchor.z. No host access.
Vec3 contact_base_center(const Asset&);
Bounds contact_base_bounds(const Asset&);
// The same center transformed by a pose; used by paths and fit feedback.
Vec3 placed_base_center(const Asset&,Vec3 position,double yaw_degrees,double scale);
}

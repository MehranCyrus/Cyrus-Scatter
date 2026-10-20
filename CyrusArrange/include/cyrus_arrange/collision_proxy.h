#pragma once
#include "cyrus_arrange/assets.h"
#include <array>

namespace cyrus::arrange {
struct OrientedBox { Vec3 center{},half_extents{};double yaw_degrees{}; };
struct CollisionProxyLease {std::span<const Bounds> pieces;std::uint64_t build_work{};};
// Solve-local, synchronous numeric cache. The previously validated immutable
// Asset must outlive this source and all borrowed probe descriptors. Never save
// a descriptor or retain it in a furniture/query cache. No host access.
class CollisionSource {
    const Asset* asset_{};
    std::array<Bounds,1> root_;
    mutable std::vector<Bounds> pieces_;
    mutable bool built_{};
public:
    explicit CollisionSource(const Asset& asset):asset_(&asset),root_{asset.bounds}{}
    CollisionProxyLease proxy(std::uint64_t remaining_work)const;
    Vec3 anchor()const noexcept{return asset_->anchor;}
    Bounds bounds()const noexcept{return root_[0];}
};
struct CollisionPose {
    const CollisionSource* source{};
    Vec3 position{};double yaw_degrees{},scale{1};
};
OrientedBox collision_piece(const CollisionPose&,const Bounds&,double contact_tolerance=0);
void validate_collision_pose(const OrientedBox&,const CollisionPose&);
struct CollisionOverlap {bool overlaps{};std::uint64_t work{};};
// Full OBB broad phase followed by conservative compound pieces when supplied.
// Absent descriptors deliberately mean the supplied complete box is occupied.
CollisionOverlap collision_overlap(const OrientedBox&,const CollisionPose&,
    const OrientedBox&,const CollisionPose&,double gap,double tolerance,std::uint64_t remaining_work);
}

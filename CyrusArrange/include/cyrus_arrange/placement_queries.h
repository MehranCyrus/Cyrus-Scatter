#pragma once
#include "cyrus_arrange/arrangement.h"
#include <memory>

namespace cyrus::arrange {
struct FurnitureBody { std::uint64_t id{}; Mesh mesh; };
struct QuerySettings {
    double contact_tolerance_mm{default_contact_tolerance_mm};
    bool require_front_access{true};
    Vec3 front_direction{0,-1,0}; // Normalized on admission; horizontal vector length [1e-9,1e6].
    std::size_t max_triangles{1000000}, max_support_vertices{32768};
    std::uint64_t max_build_work{200000000};
    std::size_t max_vertices{3000000}; // Aggregate across furniture and independent obstacles.
    bool require_support{true}; // False only for an authored free path; static collisions still apply.
};
struct QueryDiagnostics {
    std::size_t bodies{}, triangles{}, closed_components{}, open_components{}, support_planes{}, support_vertices{};
    std::uint64_t build_work{};
    std::size_t support_bodies{}, obstacle_bodies{}, vertices{};
};
// Successful retained allocation requests/capacities, not process RAM or scratch.
// accounted_bytes sums the nine byte components except tracking_state_bytes,
// which is already part of implementation_bytes. Incomplete totals cannot admit
// optional cache retention. A cache embedding this wrapper must count it once.
struct QueryRetainedStorage {
    std::size_t accounted_bytes{}, wrapper_bytes{}, implementation_bytes{};
    std::size_t triangle_bytes{}, component_bytes{}, order_bytes{}, tree_bytes{};
    std::size_t support_map_bytes{}, support_path_objects_bytes{}, support_point_bytes{};
    std::size_t support_map_allocations{};
    std::size_t triangle_capacity{}, component_capacity{}, order_capacity{}, tree_capacity{};
    std::size_t support_path_count{}, support_path_capacity{}, support_point_count{}, support_point_capacity{};
    std::size_t tracking_state_bytes{}; // Informational subset of implementation_bytes; do not sum twice.
    bool complete{};
};


// Owns copied furniture/obstacle geometry and a spatial hierarchy. Immutable after construction.
// Only furniture bodies contribute support polygons; obstacle bodies never authorize support.
// Support containment is quantized to 0.001 mm. Accessory collision uses conservative
// full bounds in broad phase, then optional conservative source compound pieces.
// These may still reject shapes within a coarse piece. Full support remains required.
// A probe's front_direction_override replaces the default direction, while the
// query-level require_front_access remains authoritative for enabling the sweep.
class FurniturePlacementQuery final : public PlacementQuery {
public:
    explicit FurniturePlacementQuery(std::span<const FurnitureBody> bodies, const QuerySettings& settings = {},
        std::span<const FurnitureBody> obstacle_bodies = {});
    ~FurniturePlacementQuery();
    FurniturePlacementQuery(FurniturePlacementQuery&&) noexcept;
    FurniturePlacementQuery& operator=(FurniturePlacementQuery&&) noexcept;
    FurniturePlacementQuery(const FurniturePlacementQuery&) = delete;
    FurniturePlacementQuery& operator=(const FurniturePlacementQuery&) = delete;
    QueryResult validate(const PlacementProbe& probe) const override;
    SupportCenterHint support_center(Vec3 near, std::uint64_t remaining_work) const override;
    QueryDiagnostics diagnostics() const;
    // Immutable O(1) snapshot of retained requested allocations, not process RAM.
    QueryRetainedStorage retained_storage() const noexcept;
private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};
}

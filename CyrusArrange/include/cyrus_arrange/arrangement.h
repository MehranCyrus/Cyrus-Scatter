#pragma once
#include "cyrus_arrange/assets.h"
#include "cyrus_arrange/composition_types.h"
#include "cyrus_arrange/collision_proxy.h"

#include <array>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <vector>

namespace cyrus::arrange {
enum class ArrangeStyle : std::uint32_t { Minimal, Balanced, Layered, Count };
enum class AmountMode : std::uint32_t { Fill, Quantity, Count };
struct Placement {
    std::uint64_t stable_id{}, asset_id{}, parent_stack_id{};
    std::uint32_t region_id{};
    Vec3 position{}; // World contact anchor, millimetres in the inspected frame.
    double yaw_degrees{}, scale{1.0};
    bool locked{};
};
struct ArrangeSettings {
    std::uint64_t seed{1};
    double density{0.5}, spacing_mm{20.0}, edge_clearance_mm{15.0};
    double cluster_strength{0.5}, height_variation{0.25}, empty_space{0.4};
    ArrangeStyle style{ArrangeStyle::Balanced};
    FurnitureCategory category{FurnitureCategory::TVConsole};
    std::size_t max_placements{2000}, max_candidates{100000}, max_stack_depth{4};
    std::uint64_t max_work{50000000};
    // Geometry-driven controls. Quantity is the total requested output,
    // including retained placements; it is not a per-region multiplier.
    AmountMode amount_mode{AmountMode::Fill};
    std::size_t quantity{100};
    bool random_scale{}, fit_to_space{};
    double scale_min{0.8}, scale_max{1.1};
};
struct PlacedObstacle { std::uint64_t stable_id{}; OrientedBox box; std::uint64_t composition_group_id{}; CollisionPose collider; };
struct GroupSpacing { std::uint64_t group_id{}; double gap_mm{}; };
enum class Rejection : std::uint32_t { None, Unsupported, Boundary, Obstacle, Spacing, Stack, Category, Count };
enum class FitIssue : std::uint32_t { None, Support, Width, Depth, Height, Occupied, Spacing, Access, Stack, Excluded, Lane, Search, Count };
struct FitWitness {
    FitIssue issue{FitIssue::None};
    std::uint64_t body_id{}, placement_id{}; // Separate numeric namespaces; never host pointers.
    Bounds bounds;
    bool has_bounds{};
};
struct PlacementProbe {
    std::span<const Vec3> footprint_world;
    OrientedBox collision;
    double support_z{};
    std::uint32_t region_id{};
    std::span<const PlacedObstacle> accepted;
    std::uint64_t support_parent_id{};
    std::span<const Vec3> parent_support_world; // Nonempty only for an authored parent top patch.
    double edge_clearance_mm{}, spacing_mm{};
    std::uint64_t remaining_work{};
    std::optional<Vec3> front_direction_override; // Horizontal world-frame direction; absent inherits the query default.
    std::optional<GroupSpacing> same_group_spacing; // Spacing only; never exempts static collision.
    CollisionPose collider; // Borrowed only for this synchronous query.
};
struct QueryResult { Rejection reason{Rejection::None}; std::uint64_t work_units{}; FitWitness witness; };
struct SupportCenterHint { std::optional<Vec3> center; std::uint64_t work_units{}; bool limited{}; };
class PlacementQuery {
public:
    virtual ~PlacementQuery() = default;
    // Implementations must bound their work by remaining_work or throw before exceeding it.
    // Returned spans are borrowed only for this synchronous call; never retained.
    virtual QueryResult validate(const PlacementProbe& probe) const = 0;
    // Optional copied proposal only; never authorizes a placement. No retained spans.
    virtual SupportCenterHint support_center(Vec3, std::uint64_t) const { return {}; }
};
struct RegionPlacementRule {
    std::uint32_t region_id{};
    std::uint32_t allowed_asset_categories{all_asset_mask};
    double density_multiplier{1.0};
    bool allow_stacking{true}, excluded{};
    Vec3 front_direction{0,-1,0};
};
// Arrangement-specific requirements, independent of tags and portable libraries.
// Zero entries are omitted; protected copies count toward the minimum.
struct AssetMinimum { std::uint64_t asset_id{}; std::size_t quantity{}; };
std::size_t validate_asset_minimums(std::span<const AssetMinimum>,std::span<const Asset>);
struct ArrangementRequest {
    std::span<const Region> regions;
    std::span<const Asset> assets;
    std::span<const Placement> previous;
    std::span<const std::uint64_t> locked_ids;
    std::span<const std::uint32_t> regenerate_region_ids; // Empty means regenerate every region.
    std::span<const CategoryRule> custom_rules;
    bool use_custom_rules{}; // Empty custom rules deliberately disable every category.
    std::span<const RegionPlacementRule> region_rules; // Missing regions use neutral policy and the query's front direction.
    CompositionOptions composition;
    std::span<const CompositionGroup> previous_groups;
    std::span<const AssetMinimum> minimums;
};
struct ArrangementStats {
    std::size_t requested{}, accepted{}, kept{}, candidates{}, underfilled{};
    std::array<std::uint64_t, static_cast<std::size_t>(Rejection::Count)> rejections{};
    std::uint64_t work{};
    std::size_t scaled_to_fit{};
    std::size_t minimum_unfilled{};
};
struct FitReport {
    std::uint64_t asset_id{};
    std::size_t placed{}, minimum{}, failed_attempts{};
    FitIssue issue{FitIssue::Search};
    Placement failed, suggested;
    FitWitness witness;
    Bounds sampled_space;
    double allowed_minimum{1};
    double apply_percent{}; // Verified value exactly representable by a float UI spinner.
    bool has_failure{}, has_space{}, has_suggestion{}, below_minimum{}, limited{}, preferred_fits{};
};
struct FitFeedback {
    std::vector<FitReport> reports; // At most 256; numeric values only.
    std::uint64_t work{}; // Separate conservative charged query work; not main solve work.
    std::size_t probes{};
    bool limited{};
};
struct ArrangementResult {
    std::vector<Placement> placements;
    ArrangementStats stats;
    std::vector<std::string> warnings;
    std::vector<CompositionGroup> groups;
    CompositionStats composition_stats;
    FitFeedback feedback;
};
void validate_composition_options(const CompositionOptions&, FurnitureCategory);
// Structural validation deliberately does not require current assets or support regions.
std::uint64_t validate_composition_structure(std::span<const CompositionGroup>, std::span<const Placement>,
    std::uint64_t work_limit = 50000000);
// Poses must follow member_ids order. Checks relationship with 0.01 mm / 0.0001 degree
// numerical tolerances, not furniture fit. Every retained member still needs PlacementQuery.
std::uint64_t validate_book_row_relationship(const CompositionGroup&, std::span<const Placement> ordered_member_poses,
    std::span<const Asset>, Vec3 current_front_direction, std::uint64_t work_limit = 50000000);
struct ProtectionClosure {
    std::vector<std::uint64_t> placement_ids, group_ids; // Sorted stable identities.
    std::uint64_t work{};
};
ProtectionClosure close_protected_placements(std::span<const Placement>, std::span<const CompositionGroup>,
    std::span<const std::uint64_t> initial_protected_ids, std::uint64_t work_limit = 50000000);
OrientedBox placement_bounds(const Asset& asset, const Placement& placement);
void validate_arrange_settings(const ArrangeSettings&);
std::vector<Vec3> placement_footprint(const Asset& asset, const Placement& placement, bool top_patch = false);
// Pure native, synchronous staging. Throws on invalid input/budget exhaustion; caller retains old result.
ArrangementResult arrange(const ArrangementRequest& request, const ArrangeSettings& settings, const PlacementQuery& geometry);
}

#pragma once
#include "cyrus_arrange/arrangement.h"
#include <memory>

namespace cyrus::arrange {
struct CubicBezier { std::array<Vec3,4> control; };
struct PathBuildSettings {
    double position_tolerance_mm{0.1}, length_tolerance_mm{1.0};
    std::size_t max_segments{4096}, max_samples{65536}, max_ribbon_vertices{32768};
    std::uint64_t max_work{50000000};
};
struct PathBuildStats {
    std::size_t segments{}, samples{};
    double length_error_bound_mm{}, maximum_deviation_bound_mm{};
    std::uint64_t work{};
};
struct PathFrame {
    Vec3 position{}, tangent{}, left{};
    double distance_mm{}, parameter{};
    std::size_t segment{};
    std::uint64_t work{};
};
// Owns copied immutable numeric data; no Max references or deferred host calls.
class PathCurve {
    struct Impl;
    std::shared_ptr<const Impl> impl_;
    explicit PathCurve(std::shared_ptr<const Impl>);
public:
    static PathCurve build(std::span<const CubicBezier>,bool closed=false,const PathBuildSettings& = {});
    double length_mm() const noexcept;
    bool closed() const noexcept;
    PathBuildStats diagnostics() const noexcept;
    // Closed paths wrap, open paths reject out-of-range distances. The position
    // is on the original cubic, not a linear parameter approximation.
    PathFrame at(double distance_mm,std::uint64_t remaining_work=50000000) const;
    std::span<const Vec3> polyline() const noexcept;
};
struct PathLane {
    std::uint32_t id{1};
    std::size_t quantity{3};
    double offset_mm{}, width_mm{3000}, center_spacing_mm{5000};
    bool reverse{}, limit_width{true};
};
enum class PathAmount : std::uint32_t { Quantity, Spacing, Count };
struct PathSettings {
    PathAmount amount{PathAmount::Quantity};
    bool align{true};
    double source_forward_degrees{}, start_inset_mm{}, end_inset_mm{};
    double lateral_jitter_mm{}, longitudinal_jitter_mm{};
    std::size_t attempts_per_slot{8};
};
// An enabled lane is a sampled, quantized ribbon, with flat open caps and closed
// inner holes. Full transformed bounds, including edges/interior, must fit.
class PathLaneMask {
    struct Impl;
    std::shared_ptr<const Impl> impl_;
    explicit PathLaneMask(std::shared_ptr<const Impl>);
public:
    static PathLaneMask build(const PathCurve&,const PathLane&,const PathBuildSettings& = {});
    QueryResult validate(const OrientedBox&,double margin_mm,std::uint64_t remaining_work=50000000) const;
    std::size_t vertices() const noexcept;
    std::uint64_t build_work() const noexcept;
};
struct PathRequest {
    const PathCurve& curve;
    std::span<const PathLane> lanes; // One or two lanes, with distinct stable IDs.
    std::span<const Asset> assets;
    std::span<const Placement> previous;
    std::span<const std::uint64_t> locked_ids;
    // Optional full support/static-obstacle query. Without it, authored path Z
    // defines placement height; lane and output collision checks remain active.
    const PlacementQuery* physical{};
    std::span<const AssetMinimum> minimums; // Global across active lanes; locks count once.
};
struct PathPlacementInfo {
    std::uint64_t stable_id{};
    std::uint32_t lane_id{};
    double distance_mm{}, lateral_mm{};
};
struct PathArrangementResult {
    ArrangementResult result;
    std::vector<PathPlacementInfo> locations;
    std::array<std::size_t,2> requested_per_lane{}, accepted_per_lane{};
};
void validate_path_settings(const PathSettings&);
void validate_path_lane(const PathLane&);
PathArrangementResult arrange_path(const PathRequest&,const ArrangeSettings&,const PathSettings&,
    const PathBuildSettings& = {});
}

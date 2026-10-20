#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace cyrus::arrange {
// Default numerical contact/support-height uncertainty: 2 micrometres. It is
// distinct from the inspector's 0.5 mm sample-to-plane matching tolerance.
inline constexpr double default_contact_tolerance_mm = 0.002;
struct Vec3 { double x{}, y{}, z{}; };
struct Triangle { std::array<std::uint32_t, 3> vertices{}; };
// Owned, evaluated geometry. Millimetres, Z up, near-origin frame; outward winding.
// Native receiving capture prepares private copies before inspection/query.
// Open/ambiguous shells retain authored winding; scene/source meshes are untouched.
struct Mesh { std::vector<Vec3> vertices; std::vector<Triangle> triangles; };
struct Bounds { Vec3 min{}, max{}; };
struct Settings {
    // Five sample positions per XY cell; values are physical millimetres.
    double cell_size_mm = 25.0;
    double minimum_clearance_mm = 100.0;
    double maximum_slope_degrees = 5.0;
    double height_tolerance_mm = 0.5;
    // These defaults are absolute implementation ceilings. Callers may lower them.
    std::size_t max_triangles = 1000000;
    std::size_t max_cells = 1000000;
    std::size_t max_regions = 4096;
    std::uint64_t max_work = 50000000;
};
struct Cell {
    Vec3 center; // Support height at centre, near-origin mm.
    double clearance_mm{}; // Infinity means no overhead hit in the captured geometry.
    bool usable{};
};
struct Region {
    std::uint32_t id{}; // Deterministic for this snapshot, not persistent topology identity.
    Bounds bounds;
    double sampled_area_mm2{}, usable_area_mm2{}; // Grid estimates, not exact mesh area.
    double minimum_clearance_mm{}; // Minimum across all supported cells, including blocked ones.
    bool open_above{}; // True only if every sampled cell has infinite clearance.
    std::vector<Cell> cells; // Includes supported cells rejected by minimum clearance.
};
struct Result {
    Bounds bounds;
    std::vector<Region> regions;
    std::size_t input_triangles{}, degenerate_triangles{}, sampled_cells{}; // sampled_cells counts all returned layers.
    std::uint64_t work{}; // Charged validation/index/query/sort/connectivity operations; not elapsed time.
    std::vector<std::string> warnings;
};
// Strong exception guarantee: returns a complete owned result or throws std::exception.
Result inspect(const Mesh& mesh, const Settings& settings = {});
// Bounded automatic sampling; minimum feature comes from registered prop size.
// Reserves headroom for multiple support layers. Does not prove feature coverage.
double automatic_cell_size(const Bounds&,double minimum_feature_mm,std::size_t max_cells=1000000);
}

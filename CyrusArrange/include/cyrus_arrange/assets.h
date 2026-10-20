#pragma once
#include "cyrus_arrange/geometry.h"
#include "cyrus_arrange/composition_types.h"
#include <cstdint>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace cyrus::arrange {
enum class FurnitureCategory : std::uint32_t {
    TVConsole, OpenShelf, CoffeeTable, KitchenCounter, DiningTable, Count
};
enum class AssetCategory : std::uint32_t {
    Book, BookStack, Plant, Candle, Frame, Vase, Accessory, Bowl, Tableware, Kitchenware, Tray, Count
};
constexpr std::uint32_t furniture_bit(FurnitureCategory value) {
    return value < FurnitureCategory::Count ? 1u << static_cast<std::uint32_t>(value) : 0u;
}
constexpr std::uint32_t asset_bit(AssetCategory value) {
    return value < AssetCategory::Count ? 1u << static_cast<std::uint32_t>(value) : 0u;
}
inline constexpr std::uint32_t all_furniture_mask = (1u << static_cast<unsigned>(FurnitureCategory::Count)) - 1u;
inline constexpr std::uint32_t all_asset_mask = (1u << static_cast<unsigned>(AssetCategory::Count)) - 1u;

struct Asset {
    std::uint64_t id{}; // Stable within the native document/library; zero is invalid.
    std::string name; // UTF-8, bounded, no embedded NUL.
    AssetCategory category{AssetCategory::Accessory};
    std::uint32_t allowed_furniture{all_furniture_mask};
    Mesh mesh; // Complete evaluated geometry, canonical asset-local millimetres, Z up.
    Bounds bounds; // Exact bounds of mesh; set by prepare_asset().
    Vec3 anchor{}; // Contact anchor in the same mesh coordinates.
    std::vector<Vec3> contact_footprint; // Convex, planar, counterclockwise; z == anchor.z.
    std::vector<double> allowed_yaws_degrees{0.0,90.0,180.0,270.0};
    double weight{1.0}, min_scale{1.0}, max_scale{1.0};
    bool stackable{}; // This asset may support another object on the authored top patch.
    double stack_height_mm{}; // Top patch z relative to anchor.z.
    std::vector<Vec3> stack_footprint; // Same XY frame; z == anchor.z + stack_height_mm.
    std::uint32_t allowed_on_top{}; // AssetCategory mask; zero forbids stacking on this asset.
    std::optional<BookRowProfile> book_row; // Explicit Book-only row eligibility; never inferred from shape/name.
};

struct AssetLimits {
    std::size_t max_assets{256};
    std::size_t max_vertices_per_asset{250000}, max_triangles_per_asset{250000};
    std::size_t max_total_vertices{1000000}, max_total_triangles{1000000};
    std::size_t max_name_bytes{512}, max_footprint_vertices{64}, max_yaws{64};
    std::size_t max_library_bytes{128u*1024u*1024u};
};

std::string asset_category_name(AssetCategory category);
std::string furniture_category_name(FurnitureCategory category);
// Bounded ASCII tag/name suggestions only; explicit metadata is authoritative.
std::optional<AssetCategory> infer_asset_category(std::string_view name);
std::optional<FurnitureCategory> infer_furniture_category(std::string_view name);
Bounds mesh_bounds(const Mesh& mesh);
// Computes bounds and, if absent, a conservative rectangular base contact patch.
// Does not silently repair explicit malformed footprints or stacking metadata.
Asset prepare_asset(Asset asset, const AssetLimits& limits = {});
void validate_asset(const Asset& asset, const AssetLimits& limits = {});
void validate_assets(const std::vector<Asset>& assets, const AssetLimits& limits = {});
// Writes library version 2; reads versions 1 (row profile absent) and 2 explicitly.
// Deterministic little-endian format; no pointers, Max IDs or native structs dumped.
std::vector<std::uint8_t> encode_assets(const std::vector<Asset>& assets, const AssetLimits& limits = {});
std::vector<Asset> decode_assets(std::span<const std::uint8_t> bytes, const AssetLimits& limits = {});
void save_assets(const std::filesystem::path& path, const std::vector<Asset>& assets, const AssetLimits& limits = {});
std::vector<Asset> load_assets(const std::filesystem::path& path, const AssetLimits& limits = {});

struct CategoryRule {
    AssetCategory category{AssetCategory::Accessory};
    double weight{1.0};
    std::uint32_t maximum_count{8};
    bool allow_on_stack{};
};
// Sparse portable rules are allowed; zero rows intentionally permits no categories.
void validate_category_rules(std::span<const CategoryRule> rules);
struct FurniturePreset {
    FurnitureCategory furniture{FurnitureCategory::TVConsole};
    std::string name;
    std::vector<CategoryRule> rules;
    double occupancy_target{0.3};
    double front_edge_margin_mm{20.0};
    double lateral_gap_mm{15.0};
};
std::vector<FurniturePreset> default_furniture_presets();
bool category_allowed(const FurniturePreset& preset, AssetCategory category);
}

#pragma once
#include "cyrus_arrange/assets.h"

#include <compare>
#include <memory>
#include <span>

namespace cyrus::arrange {
enum class SupportRole : std::uint32_t { Unknown, ExposedTop, OpenShelf, Tray, Ledge, Count };
struct RegionSemantics {
    std::string label, compartment_label; // Authored labels; no compartment inference.
    SupportRole role{SupportRole::Unknown};
    std::uint32_t allowed_asset_categories{all_asset_mask};
    double density_multiplier{1.0};
    bool allow_stacking{true}, excluded{};
    Vec3 front_direction{0,-1,0};
};
// Observable saved intent, not edit-history detection. Neutral sampled
// records may resample automatically; nondefault policy needs stable identity.
bool has_nondefault_region_semantics(const RegionSemantics&) noexcept;
struct RegionCellKey {
    std::int64_t x{},y{},z{}; // Canonical centre coordinates in 0.001 mm units.
    auto operator<=>(const RegionCellKey&) const = default;
};
struct RegionShape {
    std::int64_t cell_size_um{};
    std::vector<std::uint64_t> source_keys; // Persistent source identities, sorted and unique.
    std::vector<RegionCellKey> cells; // All supported cells, sorted and unique; ignores usability.
    Bounds bounds; // Derived sampled-cell bounds, not exact mesh extent.
};
struct RegionRecord {
    std::uint32_t stable_id{};
    std::shared_ptr<const RegionShape> shape;
    RegionSemantics semantics;
    double minimum_clearance_mm{}; // Computed snapshot measurement; may be +infinity.
    bool open_above{}; // Same all-samples meaning as Region.open_above.
};
struct RegionRegistry {
    std::uint32_t high_water{}; // Highest allocated region ID, including retired records.
    std::vector<RegionRecord> records; // Active records only; tombstones are unnecessary.
};
struct RegionObservation {
    const Region* region{};
    std::span<const std::uint64_t> source_keys;
};
struct RegionRegistrySettings {
    bool allow_overlap_matching{}; // Exact-only is the default.
    double overlap_threshold{0.98}, maximum_height_change_mm{0.01};
    std::size_t max_regions{4096},max_cells{1000000},max_source_keys{32768};
    std::size_t max_bytes{64u*1024u*1024u};
    std::uint64_t max_work{50000000};
};
struct RegionBinding { std::uint32_t observed_id{},stable_id{}; };
struct RegionRegistryUpdate;
class RegionRegistryPlan {
public:
    ~RegionRegistryPlan();
    RegionRegistryPlan(RegionRegistryPlan&&) noexcept;
    RegionRegistryPlan& operator=(RegionRegistryPlan&&) noexcept;
    RegionRegistryPlan(const RegionRegistryPlan&)=delete;
    RegionRegistryPlan& operator=(const RegionRegistryPlan&)=delete;
    std::size_t required_new_ids() const noexcept;
    std::uint64_t work() const noexcept;
private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
    explicit RegionRegistryPlan(std::unique_ptr<Impl>);
    friend RegionRegistryPlan plan_regions(std::shared_ptr<const RegionRegistry>,std::span<const RegionObservation>,const RegionRegistrySettings&);
    friend struct RegionRegistryUpdate;
    friend RegionRegistryUpdate finish_regions(RegionRegistryPlan&&,std::uint64_t);
};
struct RegionRegistryUpdate {
    std::shared_ptr<const RegionRegistry> registry;
    std::vector<RegionBinding> bindings; // Sorted by observation ID; apply to captured Region.id.
    std::vector<std::uint32_t> retired_ids;
    std::uint64_t work{};
};
RegionRegistryPlan plan_regions(std::shared_ptr<const RegionRegistry> previous,std::span<const RegionObservation> observations,
    const RegionRegistrySettings& settings = {});
// Reserve exactly required_new_ids() outside Undo before calling. Pass zero if none are needed.
// Host allocator high-water must survive failed publication/Undo; this function does not own it.
RegionRegistryUpdate finish_regions(RegionRegistryPlan&& plan,std::uint64_t first_reserved_id);
void validate_region_registry(const RegionRegistry&,const RegionRegistrySettings& settings = {});
std::vector<std::uint8_t> encode_region_registry(const RegionRegistry&,const RegionRegistrySettings& settings = {});
std::shared_ptr<const RegionRegistry> decode_region_registry(std::span<const std::uint8_t>,const RegionRegistrySettings& settings = {});
}

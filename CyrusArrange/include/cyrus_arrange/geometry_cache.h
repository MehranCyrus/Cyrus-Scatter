#pragma once
// Transient numerical cache contracts. No host pointers or persisted state.
#include "cyrus_arrange/geometry.h"
#include "cyrus_arrange/placement_queries.h"
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <limits>
#include <memory>
#include <optional>
#include <stdexcept>
#include <type_traits>
#include <utility>
#include <vector>

namespace cyrus::arrange::cache {
struct Epoch {
    std::uint64_t value{1};
    bool reusable{true};
    void invalidate() noexcept {
        if (value == std::numeric_limits<std::uint64_t>::max()) reusable = false;
        else ++value;
    }
};
struct Ticket {
    std::uint64_t document_instance{}, scene{}, geometry{};
    bool reusable{}; // Fail closed: aggregate construction without this cannot enable reuse.
    bool operator==(const Ticket&) const = default;
    static Ticket make(std::uint64_t instance,const Epoch& scene_epoch,const Epoch& geometry_epoch) noexcept {
        return {instance,scene_epoch.value,geometry_epoch.value,
                instance!=0 && scene_epoch.reusable && geometry_epoch.reusable};
    }
    bool valid() const noexcept { return reusable && document_instance && scene && geometry; }
};
struct TickInterval {
    std::int32_t first{}, last{};
    bool operator==(const TickInterval&) const = default;
    bool contains(std::int32_t time) const noexcept { return first <= time && time <= last; }
};
enum class ScopeRole : std::uint32_t { Furniture, Obstacle };
struct RootStamp {
    std::uint64_t handle{}, source_key{}; // source_key is zero for obstacle roots.
    ScopeRole role{};
    bool operator==(const RootStamp&) const = default;
};
struct NodeStamp {
    std::uint64_t handle{};
    ScopeRole role{};
    std::array<double,12> object_tm{}; // Four float source rows copied exactly into doubles.
    std::array<std::uint32_t,2> evaluated_class_id{};
    std::uint32_t evaluated_super_class{};
    TickInterval object_validity{}, transform_validity{};
    bool operator==(const NodeStamp&) const = default;
};
struct InspectionKey {
    double cell{}, clearance{}, slope{}, height_tolerance{};
    std::uint64_t triangles{}, cells{}, regions{}, work{};
    bool operator==(const InspectionKey&) const = default;
    static InspectionKey from(const Settings& s) noexcept {
        return {s.cell_size_mm,s.minimum_clearance_mm,s.maximum_slope_degrees,s.height_tolerance_mm,
                s.max_triangles,s.max_cells,s.max_regions,s.max_work};
    }
};
struct QueryKey {
    double tolerance{};
    bool require_front_access{};
    std::array<double,3> default_front{};
    std::uint64_t triangles{}, support_vertices{}, build_work{}, vertices{};
    bool require_support{};
    bool operator==(const QueryKey&) const = default;
    static QueryKey from(const QuerySettings& s) noexcept {
        return {s.contact_tolerance_mm,s.require_front_access,
                {s.front_direction.x,s.front_direction.y,s.front_direction.z},
                s.max_triangles,s.max_support_vertices,s.max_build_work,s.max_vertices,s.require_support};
    }
};
struct GeometryKey {
    Ticket ticket;
    std::int32_t time{};
    double mm_per_system_unit{};
    std::array<double,3> origin_mm{};
    InspectionKey inspection;
    QueryKey query;
    std::vector<RootStamp> roots; // Furniture roots first, then obstacle roots; preserve native binding order.
    std::vector<NodeStamp> nodes; // Each role's deterministic handle-sorted expansion, no overlaps.
    bool operator==(const GeometryKey&) const = default;
};
// Host must first run existing settings/scope/type/generated/singular/admission
// checks. This is a cheap optional-cache eligibility guard, not their replacement.
inline bool eligible_key(const GeometryKey& key) noexcept {
    if (!key.ticket.valid() || !std::isfinite(key.mm_per_system_unit) || key.mm_per_system_unit <= 0 ||
        key.roots.empty() || key.roots.size() > 4096 || key.nodes.empty() || key.nodes.size() > 4096) return false;
    for (double d : key.origin_mm) if (!std::isfinite(d)) return false;
    for (const auto& node : key.nodes) {
        if (!node.handle || !node.object_validity.contains(key.time) || !node.transform_validity.contains(key.time)) return false;
        for (double d : node.object_tm) if (!std::isfinite(d)) return false;
    }
    return true;
}

enum class Phase : std::size_t {
    LookupStamp, FurnitureCapture, Inspect, RegistryBind, ObstacleCapture,
    QueryBuild, AssetRefresh, Solve, VisualCapture, Publish, FinalValidate, Total, Count
};
enum class Disposition : std::uint32_t { Cold, Hit, ColdNotRetained };
enum class Operation : std::uint32_t { Generate, Preview, CommitPreview, Analyze };
enum class Reason : std::uint32_t {
    None, Empty, KeyChanged, DependencyChanged, TimeChanged, UnitsChanged,
    SceneChanged, OwnerRemoved, ExplicitClear, Disabled, InvalidKey,
    AccountingUnavailable, TooLarge, PinnedBudget, MetadataAllocation
};
struct CommandMetrics {
    Operation operation{};
    Disposition disposition{Disposition::Cold};
    Reason reason{Reason::Empty};
    bool completed{}, published{}, lookup_validated{};
    std::array<std::uint64_t,static_cast<std::size_t>(Phase::Count)> nanoseconds{};
    std::uint64_t inspection_work_executed{}, query_build_work_executed{};
    std::uint64_t inspection_work_original{}, query_build_work_original{};
    std::uint64_t solver_work{}, command_sequence{};
};
class ScopedPhase {
    using Clock = std::chrono::steady_clock;
    CommandMetrics* metrics_;
    Phase phase_;
    Clock::time_point started_{Clock::now()};
public:
    ScopedPhase(CommandMetrics& m,Phase phase) noexcept : metrics_(&m),phase_(phase) {}
    ScopedPhase(const ScopedPhase&)=delete;
    ~ScopedPhase() noexcept {
        const auto delta=std::chrono::duration_cast<std::chrono::nanoseconds>(Clock::now()-started_).count();
        if (delta>0) {
            auto& value=metrics_->nanoseconds[static_cast<std::size_t>(phase_)];
            const auto n=static_cast<std::uint64_t>(delta);
            value=n>std::numeric_limits<std::uint64_t>::max()-value ? std::numeric_limits<std::uint64_t>::max() : value+n;
        }
    }
};
struct QueryStorage {
    std::size_t bytes{}, wrapper_bytes{sizeof(FurniturePlacementQuery)}, triangles{};
    bool complete{};
};
struct GeometryBundle {
    Result raw; // Observation IDs ONLY. Never replace these with persistent region IDs.
    FurniturePlacementQuery query;
    QueryStorage storage;
    TickInterval validity;
    GeometryBundle(Result r,FurniturePlacementQuery q,QueryStorage s,TickInterval v) noexcept
        : raw(std::move(r)),query(std::move(q)),storage(s),validity(v) {}
    GeometryBundle(GeometryBundle&&) noexcept=default;
    GeometryBundle& operator=(GeometryBundle&&) noexcept=default;
    GeometryBundle(const GeometryBundle&)=delete;
};
static_assert(std::is_nothrow_move_constructible_v<GeometryBundle>);
static_assert(std::is_nothrow_move_assignable_v<GeometryKey>);

struct Footprint {
    std::size_t entries{}, bytes{}, triangles{}, cells{};
};
struct Limits {
    std::size_t entries{4}, bytes{256u*1024u*1024u}, triangles{1000000}, cells{1000000};
};
inline bool can_add(const Footprint& live,const Footprint& next,const Limits& cap) noexcept {
    return live.entries<=cap.entries && next.entries<=cap.entries-live.entries &&
           live.bytes<=cap.bytes && next.bytes<=cap.bytes-live.bytes &&
           live.triangles<=cap.triangles && next.triangles<=cap.triangles-live.triangles &&
           live.cells<=cap.cells && next.cells<=cap.cells-live.cells;
}
namespace detail { struct CacheEntry; struct Ledger; struct AllocationCounter; }
class GeometryLease {
    std::shared_ptr<const detail::CacheEntry> entry_;
    explicit GeometryLease(std::shared_ptr<const detail::CacheEntry>) noexcept;
    friend class GeometryCache;
public:
    GeometryLease() noexcept=default;
    GeometryLease(const GeometryLease&) noexcept=default;
    GeometryLease& operator=(const GeometryLease&) noexcept=default;
    GeometryLease(GeometryLease&&) noexcept=default;
    GeometryLease& operator=(GeometryLease&&) noexcept=default;
    explicit operator bool() const noexcept { return bool(entry_); }
    void reset() noexcept { entry_.reset(); }
    const GeometryBundle& get() const;
};
struct Offer {
    GeometryLease lease;
    Reason reason{Reason::None};
};
struct Lookup {
    GeometryLease lease;
    Reason reason{Reason::Empty};
};
struct CacheTotals {
    Footprint live, peak; // Includes charged entries with leases after eviction.
    std::size_t resident{}, retired_borrowed{};
    bool enabled{};
    std::size_t entry_metadata_requested_live_bytes{}, entry_metadata_requested_peak_bytes{};
    std::size_t fixed_service_inline_bytes{}, fixed_control_object_bytes{};
};
class GeometryCache {
    struct Slot {
        std::shared_ptr<const detail::CacheEntry> entry;
        std::uint64_t touched{};
        bool stale{};
    };
    std::array<Slot,4> slots_;
    std::shared_ptr<detail::Ledger> ledger_;
    std::shared_ptr<detail::AllocationCounter> metadata_;
    std::uint64_t clock_{};
    bool enabled_{true};
    void touch(Slot&) noexcept;
    int resident_for(std::uint64_t) const noexcept;
    int free_slot() const noexcept;
    int victim(std::uint64_t) const noexcept;
    static void subtract(Footprint&,const Footprint&) noexcept;
public:
    explicit GeometryCache(Limits limits={});
    GeometryCache(const GeometryCache&)=delete;
    GeometryCache& operator=(const GeometryCache&)=delete;
    ~GeometryCache();
    // Callback-safe flagging only; defer release to an ordinary command boundary.
    void defer_document(std::uint64_t) noexcept;
    void defer_all() noexcept;
    void drain_deferred() noexcept;
    Lookup lookup(const GeometryKey&) noexcept;
    Offer offer(const GeometryKey&,std::optional<GeometryBundle>&) noexcept;
    void clear_document(std::uint64_t) noexcept;
    void clear_all() noexcept;
    void shutdown() noexcept;
    CacheTotals totals() const noexcept;
};
// Command-local ownership: a valid cold query needs no allocate_shared or extra
// bundle heap allocation. Optional retention failure leaves cold populated.
struct CommandGeometry {
    std::optional<GeometryBundle> cold;
    GeometryLease lease;
    const GeometryBundle& get() const {
        if(lease)return lease.get();
        if(cold)return *cold;
        throw std::logic_error("Missing staged command geometry.");
    }
};
}

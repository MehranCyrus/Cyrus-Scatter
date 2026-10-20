#pragma once
#include "cyrus_arrange/arrangement.h"
#include "cyrus_arrange/region_registry.h"
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <vector>

namespace cyrus::arrange::host {
class Document;
struct DocumentState;
struct CommandDependencyTicket;

struct PreviewInfo {
    bool present{}, valid{};
    std::size_t box_count{};
    ArrangementStats stats;
    std::vector<std::uint32_t> selected_region_ids; // Empty means every region.
    std::uint64_t revision{}, input_epoch{};
    std::int32_t time{};
    std::string reason;
};

// Main-thread only. Bounds are copied in WORLD millimetres, including the
// document frame origin. No asset meshes, placement arrays or scene nodes are
// created/retained by this service. Max 8 cached previews, 10k boxes per preview,
// 80k boxes and 2m canonical region cells total in the retained cache. An optional
// immutable registry preserves newly reserved stable region IDs through Commit,
// without retaining asset meshes or changing authored document state. Preparing
// a successor can coexist with the old cache; this is not a process peak budget.
// Admission failure preserves the prior preview.
// Successful staging disarms native Live until explicit Generate/Commit.
void stage_preview(Document&,std::shared_ptr<const DocumentState> expected_state,
                   const CommandDependencyTicket& expected_dependencies,
                   std::int32_t expected_time,double expected_unit,
                   std::span<const OrientedBox> world_mm_bounds,
                   std::span<const std::uint32_t> selected_region_ids,
                   const ArrangementStats&,
                   std::shared_ptr<const RegionRegistry> staged_registry={});
PreviewInfo preview_info(Document&);
// Returns an owned bounded scope for recomputation, or throws when absent/stale.
// Commit must recompute/publish against unchanged current inputs; never publish
// these diagnostic boxes as an arrangement.
std::vector<std::uint32_t> preview_selection(Document&);
// Validates the same freshness stamp as preview_selection; null is permitted for
// callers that staged without a registry. Use as Commit's region matching base.
std::shared_ptr<const RegionRegistry> preview_regions(Document&);
// Bounded diagnostic copy (at most 10k OBBs), with the same freshness validation.
std::vector<OrientedBox> preview_bounds(Document&);
bool clear_preview(Document&);
struct FitHighlightInfo {
    bool present{},valid{},suggestion{};
    std::uint64_t asset_id{},draws{};
    std::vector<OrientedBox> boxes; // At most two; copied WORLD millimetres.
};
// Separate channel: never replaces Preview, changes scene nodes or disarms Live.
void show_fit_highlight(Document&,std::uint64_t asset_id,std::span<const OrientedBox>,bool suggestion);
bool hide_fit_highlight(Document&);
FitHighlightInfo fit_highlight_info(Document&);
// Call on Max's main thread before the native module unloads.
void shutdown_preview() noexcept;
}

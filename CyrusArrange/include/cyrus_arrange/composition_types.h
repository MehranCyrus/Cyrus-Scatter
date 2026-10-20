#pragma once
#include "cyrus_arrange/geometry.h"
#include <cstdint>
#include <vector>

namespace cyrus::arrange {
enum class SpineFace : std::uint32_t {
    NegativeX=0, PositiveX=1, NegativeY=2, PositiveY=3, Count=4
};
struct BookRowProfile { SpineFace spine_face{SpineFace::PositiveY}; };
enum class CompositionKind : std::uint32_t { BookRow=0, Count=1 };
struct CompositionOptions {
    bool book_rows{};
    std::uint32_t minimum_books{2}, maximum_books{6};
    double row_gap_mm{3.0}, row_height_balance{};
};
struct CompositionGroup {
    std::uint64_t stable_id{};
    CompositionKind kind{CompositionKind::BookRow};
    std::uint32_t region_id{};
    std::vector<std::uint64_t> member_ids; // Ordered along the region's lateral axis.
    Vec3 front_direction{0,-1,0};
    double gap_mm{3.0};
};
struct CompositionStats {
    std::uint64_t row_attempts{}, rows_formed{}, row_failures{};
    std::uint64_t balance_anchor_attempts{}, rows_moved{};
};
}

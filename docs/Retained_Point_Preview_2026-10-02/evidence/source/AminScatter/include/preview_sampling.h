#pragma once
#include <cstdint>

namespace amin {
// Evenly select exactly count entries from [0,total), in stable order.
// Preconditions: 0 < count <= total, ordinal < count, count <= 500000.
// Quotient/remainder decomposition avoids overflowing ordinal*total.
inline std::uint64_t previewPointIndex(std::uint64_t ordinal,std::uint64_t total,std::uint64_t count) {
    return ordinal*(total/count)+(ordinal*(total%count))/count;
}
}

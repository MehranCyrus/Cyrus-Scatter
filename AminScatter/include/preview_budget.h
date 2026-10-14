#pragma once
#include <atomic>
#include <cstddef>
#include <stdexcept>

namespace cyrus {
// Numeric/resource payload reservations, including CPU and SDK system copies.
// Driver, Max conversion and allocator overhead are measured separately.
class PreviewBudget {
    const std::size_t ceiling;
    std::atomic<std::size_t> live{0},peak{0};
public:
    explicit PreviewBudget(std::size_t maximum):ceiling(maximum) {}
    bool acquire(std::size_t bytes) {
        auto used=live.load();
        do { if(used>ceiling||bytes>ceiling-used)return false; }
        while(!live.compare_exchange_weak(used,used+bytes));
        auto before=peak.load();
        while(before<used+bytes&&!peak.compare_exchange_weak(before,used+bytes)) {}
        return true;
    }
    void release(std::size_t bytes) { live-=bytes; }
    std::size_t used() const { return live.load(); }
    std::size_t highWater() const { return peak.load(); }
};
class PreviewMemory {
    PreviewBudget& budget;
    std::size_t bytes;
public:
    PreviewMemory(PreviewBudget& owner,std::size_t value):budget(owner),bytes(value) {
        if(!budget.acquire(bytes))throw std::runtime_error("Preview process resource budget exceeded; reduce display limits or release older caches");
    }
    ~PreviewMemory() { budget.release(bytes); }
    PreviewMemory(const PreviewMemory&)=delete;
    PreviewMemory& operator=(const PreviewMemory&)=delete;
};
inline constexpr std::size_t pointPreviewOwnerLimit=64ull*1024*1024;
inline constexpr std::size_t pointPreviewProcessLimit=128ull*1024*1024;
// Per-controller preparation capacity, separate from either artist draw cap.
// Per point: doubled CPU vector capacity (26 bytes), retained HW/system/upload
// copies (48), and simultaneous preparation (26). Leave 8 MiB for groups,
// palettes, source samples and inspection bookkeeping. Zero draw caps still
// remove only the artist cap; preparation must fit a complete display successor.
inline constexpr std::size_t pointPreviewPreparationLimit=(pointPreviewOwnerLimit-8ull*1024*1024)/100;
inline constexpr std::size_t meshPreviewOwnerLimit=512ull*1024*1024;
inline constexpr std::size_t meshPreviewProcessLimit=1024ull*1024*1024;
}

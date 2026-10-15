#pragma once
#include "recipes.h"
#include <atomic>
#include <mutex>
#include <thread>

namespace cyrus::recipes {
constexpr std::size_t maxThumbnailBytes=2*1024*1024;
// Presentation is an optional, hash-bound sidecar. It never changes recipe v1.
void validateThumbnail(const std::vector<unsigned char>& bytes);
void writePresentation(const std::filesystem::path& recipe, const Json& metadata,
                       const std::filesystem::path& thumbnail={});
Json summary(const std::filesystem::path& recipe);
std::filesystem::path thumbnail(const std::filesystem::path& recipe);

struct LibraryLimits {
    std::size_t entries=10000, directoryEntries=100000, metadataBytes=32*1024*1024;
};
// File-only background work. No Max objects, callbacks, API calls or Paint reads.
// Cancellation requests return immediately; a pending scan must finish before
// another begins. Only a terminal worker is joined on the calling/UI thread.
class Library {
public:
    explicit Library(LibraryLimits limits={}) : limits_(limits) {}
    ~Library();
    std::uint64_t start(std::vector<std::filesystem::path> roots);
    void cancel(std::uint64_t token);
    Json page(std::uint64_t token, const std::string& search,
              const std::string& category, std::size_t pageNumber) const;
private:
    struct Entry { std::string path, search, category; Json info; };
    void scan(std::vector<std::filesystem::path> roots) noexcept;
    LibraryLimits limits_;
    mutable std::mutex mutex_;
    std::vector<Entry> entries_;
    std::thread worker_;
    std::atomic<bool> stop_{false}, done_{true};
    std::uint64_t generation_=0;
    std::size_t scanned_=0, invalid_=0;
    bool limited_=false;
    std::string error_;
};
}

#pragma once
#include "recipes.h"
#include <atomic>
#include <mutex>
#include <thread>
#include <memory>
#include <map>

namespace cyrus::recipes {
constexpr std::size_t maxThumbnailBytes=2*1024*1024;
// Presentation is an optional, hash-bound sidecar. It never changes recipe v1.
void validateThumbnail(const std::vector<unsigned char>& bytes);
void writePresentation(const std::filesystem::path& recipe, const Json& metadata,
                       const std::filesystem::path& thumbnail={});
Json summary(const std::filesystem::path& recipe, bool confined=false);
std::filesystem::path thumbnail(const std::filesystem::path& recipe);

struct LibraryLimits {
    std::size_t entries=10000, directoryEntries=100000, metadataBytes=32*1024*1024;
    bool confined=false;
    bool settingsPresets=false;
};
// File-only background work. No Max objects, callbacks, API calls or Paint reads.
// Cancellation requests return immediately; a pending scan must finish before
// another begins. Only a terminal worker is joined on the calling/UI thread.
class Library {
public:
    explicit Library(LibraryLimits limits={}) : limits_(limits) {}
    ~Library();
    std::uint64_t start(std::vector<std::filesystem::path> roots,std::string collection={});
    void cancel(std::uint64_t token);
    bool terminal() const noexcept { return done_.load(); }
    void update(std::uint64_t token,const std::filesystem::path& recipe);
    Json page(std::uint64_t token, const std::string& search,
              const std::string& category, std::size_t pageNumber) const;
    Json preset(std::uint64_t token,const std::string& key) const;
private:
    struct Entry { std::string path, search, category; Json info; std::size_t bytes=0; };
    struct Collection { std::string name; std::size_t count=0, representative=0; };
    void scan(std::vector<std::filesystem::path> roots) noexcept;
    LibraryLimits limits_;
    mutable std::mutex mutex_;
    std::vector<Entry> entries_;
    // Names/counts/entry indices only: bounded by entries_, no duplicated images or recipe JSON.
    mutable std::vector<Collection> collections_;
    mutable bool collectionsDirty_=true;
    std::vector<std::filesystem::path> roots_;
    std::string collection_;
    std::thread worker_;
    std::atomic<bool> stop_{false}, done_{true};
    std::uint64_t generation_=0;
    std::size_t scanned_=0, invalid_=0, metadataBytes_=0;
    bool limited_=false;
    std::string error_;
};

// Independent read-only catalog owners for automation. All registry methods run
// on the caller/host thread; workers own copied paths and file-only metadata.
// Close requests cancellation and revokes the handle immediately, without join.
// Retiring workers still occupy a slot until terminal; only then may they be reaped.
class Catalogs {
public:
    explicit Catalogs(bool settingsPresets=false) : settingsPresets_(settingsPresets) {}
    std::uint64_t open(const std::filesystem::path& root);
    Json page(std::uint64_t handle,const std::string& search,const std::string& category,std::size_t number) const;
    void close(std::uint64_t handle);
    void reap();
    Json presetPage(std::uint64_t handle,std::size_t number) const;
    Json preset(std::uint64_t handle,const std::string& key) const;
    std::size_t retained() const noexcept { return readers_.size(); }
private:
    struct Reader { std::unique_ptr<Library> library; std::uint64_t token; bool closed=false; };
    std::map<std::uint64_t,Reader> readers_;
    std::uint64_t next_=0;
    bool settingsPresets_=false;
};
}

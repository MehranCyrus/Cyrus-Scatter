#pragma once
#include <atomic>
#include <array>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <string>

namespace amin::diagnostics {
enum class Stage : std::size_t { Geometry, MeshChannel, Candidates, Mask, SurfaceFilter,
    Attributes, Spacing, Preview, Upload, Publication, MapBake, UiCreate, UiBind, UiLayout, UiLists, Count };
const char* stageName(Stage stage) noexcept;
std::uint64_t steadyMicroseconds() noexcept;
// Plain-data recorder. It never calls Max, redraw, a renderer or the filesystem.
struct Limits {
    std::size_t events = 4096;
    std::size_t bytes = 4 * 1024 * 1024;
    std::uint64_t durationMs = 600000;
};

class Recorder {
public:
    using Clock = std::function<std::uint64_t()>;
    explicit Recorder(Clock clock = {});
    void start(const std::string& session, Limits limits = {});
    void stop() noexcept;
    bool active() const noexcept;
    bool record(const std::string& name, const std::string& origin,
                const std::string& owner, std::uint64_t epoch,
                const std::string& detail, std::uint64_t action = 0) noexcept;
    std::string snapshot(std::uint64_t after = 0, std::size_t limit = 100) const;
    std::uint64_t token() const noexcept;
    bool measure(Stage stage, std::uint64_t microseconds, std::uint64_t generation, bool failed = false) noexcept;
private:
    struct Event {
        std::uint64_t sequence, elapsed, epoch, action;
        std::string name, origin, owner, detail;
        std::size_t bytes = 0;
    };
    Clock clock_;
    mutable std::mutex mutex_;
    std::atomic<bool> enabled_{false};
    std::atomic<std::uint64_t> deadline_{0}, generation_{0};
    std::atomic<std::uint64_t> lockDrops_{0}, failures_{0};
    std::deque<Event> events_;
    Limits limits_;
    std::string session_;
    std::uint64_t started_ = 0, startedUnixMs_ = 0, sequence_ = 0, evicted_ = 0, truncated_ = 0;
    std::uint64_t stoppedElapsed_ = 0;
    std::size_t bytes_ = 0, highWater_ = 0;
    bool expired_ = false;
    struct Measurement { std::uint64_t calls=0, microseconds=0, maximum=0, failed=0; };
    std::array<Measurement, static_cast<std::size_t>(Stage::Count)> measurements_{};
};

Recorder& recorder();
// No clock, allocation, lock or event strings while recording is disabled.
class StageTimer {
public:
    explicit StageTimer(Stage stage) noexcept;
    ~StageTimer() noexcept;
    StageTimer(const StageTimer&) = delete;
    StageTimer& operator=(const StageTimer&) = delete;
private:
    Stage stage_;
    std::uint64_t generation_=0, started_=0;
    int exceptions_=0;
};
} // namespace amin::diagnostics

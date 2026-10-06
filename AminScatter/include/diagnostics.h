#pragma once
#include <atomic>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <string>

namespace amin::diagnostics {
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
                const std::string& detail) noexcept;
    std::string snapshot(std::uint64_t after = 0, std::size_t limit = 100) const;
private:
    struct Event {
        std::uint64_t sequence, elapsed, epoch;
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
};

Recorder& recorder();
} // namespace amin::diagnostics

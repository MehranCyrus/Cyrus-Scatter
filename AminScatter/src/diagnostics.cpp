#include "diagnostics.h"
#include <algorithm>
#include <chrono>
#include <sstream>
#include <stdexcept>

namespace amin::diagnostics {
namespace {
std::uint64_t steadyMs() {
    return static_cast<std::uint64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count());
}
std::string bounded(const std::string& value, std::size_t size, bool& truncated) {
    if (value.size() <= size) return value;
    truncated = true;
    // Preserve a UTF-8 boundary. Max supplies valid UTF-8, including artist notes.
    while (size && (static_cast<unsigned char>(value[size]) & 0xc0) == 0x80) --size;
    return value.substr(0, size);
}
std::string quote(const std::string& value) {
    static constexpr char hex[] = "0123456789abcdef";
    std::string out = "\"";
    for (unsigned char c : value) {
        if (c == '"' || c == '\\') { out += '\\'; out += static_cast<char>(c); }
        else if (c < 32) { out += "\\u00"; out += hex[c >> 4]; out += hex[c & 15]; }
        else out += static_cast<char>(c);
    }
    return out + '"';
}
}
Recorder::Recorder(Clock clock) : clock_(clock ? std::move(clock) : Clock(steadyMs)) {}

void Recorder::start(const std::string& session, Limits limits) {
    if (session.empty() || session.size() > 96 ||
        session.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-") != std::string::npos)
        throw std::invalid_argument("Diagnostic session ID must be 1..96 ASCII identifier characters");
    if (!limits.events || limits.events > 16384 || limits.bytes < 2048 || limits.bytes > 4 * 1024 * 1024 ||
        !limits.durationMs || limits.durationMs > 600000)
        throw std::invalid_argument("Diagnostic limits exceed the bounded recording contract");
    std::lock_guard<std::mutex> lock(mutex_);
    if (enabled_.load() && clock_() < deadline_.load()) throw std::logic_error("Stop the active diagnostic session before starting another");
    ++generation_;
    events_.clear(); session_ = session; limits_ = limits; bytes_ = highWater_ = 0;
    sequence_ = evicted_ = truncated_ = 0; lockDrops_ = 0; failures_ = 0; expired_ = false;
    started_ = clock_(); stoppedElapsed_ = 0;
    deadline_.store(started_ + limits_.durationMs);
    startedUnixMs_ = static_cast<std::uint64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count());
    enabled_.store(true);
}
void Recorder::stop() noexcept {
    try {
        std::lock_guard<std::mutex> lock(mutex_);
        if (enabled_.exchange(false)) {
            const auto elapsed = clock_() - started_;
            stoppedElapsed_ = std::min(elapsed, limits_.durationMs);
            expired_ = elapsed >= limits_.durationMs;
            ++generation_;
        }
    } catch (...) { enabled_.store(false); ++failures_; }
}
bool Recorder::active() const noexcept {
    try { return enabled_.load() && clock_() < deadline_.load(); }
    catch (...) { return false; }
}

bool Recorder::record(const std::string& name, const std::string& origin,
                      const std::string& owner, std::uint64_t epoch,
                      const std::string& detail) noexcept {
    const auto generation = generation_.load();
    if (!enabled_.load()) return false;
    try {
        std::unique_lock<std::mutex> lock(mutex_, std::try_to_lock);
        if (!lock.owns_lock()) { ++lockDrops_; return false; }
        if (!enabled_.load() || generation != generation_.load()) return false;
        const auto elapsed = clock_() - started_;
        if (elapsed >= limits_.durationMs) { expired_ = true; stoppedElapsed_ = limits_.durationMs; enabled_.store(false); return false; }
        bool trimmed = false;
        Event event{sequence_ + 1, elapsed, epoch, bounded(name, 64, trimmed), bounded(origin, 32, trimmed),
                    bounded(owner, 96, trimmed), bounded(detail, 512, trimmed), 0};
        // Include owned string capacities and event storage. Container overhead is
        // separately bounded by the event count; this is not a process-RSS claim.
        event.bytes = sizeof(Event) + event.name.capacity() + event.origin.capacity() + event.owner.capacity() + event.detail.capacity();
        if (event.bytes > limits_.bytes) { ++failures_; return false; }
        while (!events_.empty() && (events_.size() >= limits_.events || bytes_ + event.bytes > limits_.bytes)) {
            bytes_ -= events_.front().bytes; events_.pop_front(); ++evicted_;
        }
        events_.push_back(std::move(event));
        bytes_ += events_.back().bytes; highWater_ = std::max(highWater_, bytes_);
        ++sequence_; if (trimmed) ++truncated_;
        return true;
    } catch (...) { ++failures_; return false; }
}

std::string Recorder::snapshot(std::uint64_t after, std::size_t limit) const {
    if (limit > 500) throw std::invalid_argument("Diagnostic page limit must be 0..500");
    std::lock_guard<std::mutex> lock(mutex_);
    std::ostringstream out;
    const auto elapsed = session_.empty() ? 0 : (enabled_.load() ? std::min(clock_() - started_, limits_.durationMs) : stoppedElapsed_);
    out << "{\"schema\":\"cyrus.diagnostic-page/1.0\",\"purpose\":\"engineering\",\"session_id\":" << quote(session_)
        << ",\"started_unix_ms\":" << startedUnixMs_ << ",\"elapsed_ms\":" << elapsed
        << ",\"active\":" << (enabled_.load() && elapsed < limits_.durationMs ? "true" : "false")
        << ",\"expired\":" << (expired_ || (enabled_.load() && elapsed >= limits_.durationMs) ? "true" : "false")
        << ",\"limits\":{\"events\":" << limits_.events << ",\"bytes\":" << limits_.bytes << ",\"duration_ms\":" << limits_.durationMs << '}'
        << ",\"health\":{\"retained\":" << events_.size() << ",\"retained_bytes\":" << bytes_ << ",\"high_water_bytes\":" << highWater_
        << ",\"evicted\":" << evicted_ << ",\"lock_drops\":" << lockDrops_.load() << ",\"failures\":" << failures_.load()
        << ",\"truncated\":" << truncated_ << "},\"oldest_sequence\":" << (events_.empty() ? 0 : events_.front().sequence)
        << ",\"last_sequence\":" << sequence_ << ",\"events\":[";
    std::size_t returned = 0; auto next = after;
    for (const auto& event : events_) {
        if (event.sequence <= after || returned >= limit) continue;
        if (returned++) out << ',';
        out << "{\"sequence\":" << event.sequence << ",\"elapsed_ms\":" << event.elapsed << ",\"epoch\":" << event.epoch
            << ",\"name\":" << quote(event.name) << ",\"origin\":" << quote(event.origin)
            << ",\"owner_id\":" << quote(event.owner) << ",\"detail\":" << quote(event.detail) << '}';
        next = event.sequence;
    }
    out << "],\"next_sequence\":" << next << ",\"has_more\":" << (next < sequence_ ? "true" : "false")
        << ",\"training_eligible\":false}";
    return out.str();
}
Recorder& recorder() { static Recorder instance; return instance; }
} // namespace amin::diagnostics

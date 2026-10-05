#pragma once
#include "policy.h"
#include <array>
#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <string_view>

namespace cyrus::licensing {
// Local software-key possession is an installation identity, not hardware
// attestation. Call only from activation/recovery/background work, never draw.
class InstallationKey {
public:
    InstallationKey(std::wstring name, bool create_if_missing);
    ~InstallationKey();
    InstallationKey(const InstallationKey&) = delete;
    InstallationKey& operator=(const InstallationKey&) = delete;
    std::array<unsigned char,64> publicKey() const;
    std::string deviceId() const;
    std::array<unsigned char,64> signChallenge(std::string_view challenge) const;
    bool privateExportDenied() const;
private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

struct LocalState {
    std::uint64_t generation = 0;
    std::int64_t highest_utc = 0;
    std::string device, token;
    std::string pending_nonce;
};

// DPAPI current-user protection, bounded payload, interprocess exclusion and
// flushed atomic replacement. Missing state is distinct from corrupt state;
// a corrupt/restored cache is never silently treated as a new activation.
class LocalStateStore {
public:
    explicit LocalStateStore(std::filesystem::path directory);
    std::optional<LocalState> read() const;
    LocalState update(const std::function<void(LocalState&)>& change) const;
private:
    std::filesystem::path directory_;
};

// Host-owned observations. New activation/recovery must supply an authenticated
// anchor separately; neither a token's nbf nor a caller timestamp is proof of
// current time. A protected high-water mark cannot defeat whole-state replay.
class ClockTracker {
public:
    ClockTracker(std::int64_t persisted_highest, std::int64_t utc_now,
                 std::uint64_t monotonic_ms) noexcept;
    ClockObservation observe(std::int64_t utc_now, std::uint64_t monotonic_ms) noexcept;
    std::int64_t highest() const noexcept { return highest_; }
private:
    std::int64_t start_=0, highest_=0;
    std::uint64_t ticks_=0;
    bool trusted_=false;
};
std::int64_t systemUtcSeconds() noexcept;
std::uint64_t systemMonotonicMs() noexcept;
} // namespace cyrus::licensing

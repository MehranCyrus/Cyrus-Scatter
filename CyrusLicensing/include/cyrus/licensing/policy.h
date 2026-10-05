#pragma once

#include <cstdint>

namespace cyrus::licensing {

// These are policy inputs, NOT a verified credential or security capability.
// Future adapters must establish them through a verifier and native-owned
// operation context. Never expose this interface as a production script gate.
enum class Operation : std::uint32_t {
    Inspect = 1,
    PreserveScene = 2,
    Recover = 3,
    RenderExisting = 4,
    AuthorScatter = 5,  // Includes same-product distribution/edit/Brush commands.
    AuthorAnalyzer = 6,
};

enum class Authority : std::uint8_t { Absent, Rejected, Verified };
enum class StateEvidence : std::uint8_t { Unproven, ApprovedExistingState };
enum class Reason : std::uint8_t {
    Allowed,
    Continuity,
    UnknownOperation,
    ExistingStateUnproven,
    AuthorityAbsent,
    AuthorityRejected,
    MalformedAuthority,
    WrongProduct,
    BuildIneligible,
    DeviceMismatch,
    CapacityUnavailable,
    TimeRecoveryRequired,
    NotYetValid,
    Expired,
};

constexpr std::uint32_t ScatterAuthorRight = 1u << 0;
constexpr std::uint32_t AnalyzerAuthorRight = 1u << 1;

struct AuthorityFacts {
    Authority authority = Authority::Absent;
    std::uint32_t rights = 0;
    bool build_eligible = false;
    bool device_matches = false;
    bool capacity_reserved = false;
    std::int64_t not_before_utc = 0;
    std::int64_t authoring_end_utc = 0;
};

struct ClockObservation {
    // Establishing confidence and detecting rollback are separate, unimplemented
    // responsibilities. A timestamp supplied by a script is not trusted time.
    bool trusted = false;
    std::int64_t utc_seconds = 0;
};

struct Decision {
    bool allowed;
    Reason reason;
};

// Pure, allocation-free and noexcept. Connectivity is deliberately not an
// authorization input: an outage does not cancel an otherwise valid grant.
// This prototype implements decisions, not signature/device/time verification.
Decision decide(Operation operation, const AuthorityFacts& facts,
                ClockObservation clock,
                StateEvidence existing_state = StateEvidence::Unproven) noexcept;

const char* reasonName(Reason reason) noexcept;

}  // namespace cyrus::licensing

#pragma once

#include "policy.h"
#include <array>
#include <optional>
#include <memory>
#include <atomic>
#include <string>
#include <string_view>
#include <vector>

namespace cyrus::licensing {

// Candidate JWS profile, not the final commercial protocol. Trust and host
// context belong to the application; never load them from a license file.
struct IssuerKey {
    std::string id;
    std::array<unsigned char, 64> p256_xy{};
};
struct TrustProfile {
    std::string issuer;
    std::string audience;
    std::string token_type;
    std::vector<IssuerKey> keys;
};
struct LicenseClaims {
    std::string id, subject, tenant, product, device;
    std::int64_t not_before = 0, expires = 0;
    std::uint32_t maximum_build = 0;
};
enum class TokenError {
    None, Size, Encoding, Json, Header, UntrustedKey, Signature,
    CryptoFailure, Claims, Scope, Device, Build
};
const char* tokenErrorName(TokenError error) noexcept;
struct Verification {
    TokenError error = TokenError::Claims;
    std::optional<LicenseClaims> claims;
};

// Uses Windows CNG ES256 and an explicit, bounded JWS profile. No network,
// file I/O, fallback algorithms, token-supplied keys or clock reads.
Verification verifyLicense(std::string_view compact_jws, const TrustProfile& trust) noexcept;

struct ActivationVerification {
    TokenError error = TokenError::Claims;
    std::int64_t server_utc = 0;
    std::string license;
};
// Separate purpose and fresh device-bound nonce. This authenticates a server
// observation; the caller must check response age and consume its pending nonce
// atomically. It does not authenticate an account or allocate a purchased seat.
ActivationVerification verifyActivation(std::string_view response, const TrustProfile& activation_trust,
    std::string_view nonce, std::string_view device) noexcept;

struct HostContext {
    std::string subject, tenant, product, device;
    std::uint32_t build_serial = 0;
};

class OperationPermit;

// Verification allocates only during import. Readers acquire an immutable
// snapshot; concurrent imports never expose partly replaced claims. Trust and
// host context are fixed for the lifetime of a session.
class LicenseSession {
public:
    LicenseSession(TrustProfile trust, HostContext host);
    LicenseSession(const LicenseSession&) = delete;
    LicenseSession& operator=(const LicenseSession&) = delete;
    TokenError install(std::string_view token) noexcept;
    Decision decide(Operation operation, ClockObservation clock,
                    StateEvidence state = StateEvidence::Unproven) const noexcept;
    bool hasLicense() const noexcept { return bool(snapshot()); }
    std::shared_ptr<const LicenseClaims> snapshot() const noexcept;
    OperationPermit admit(Operation operation, const void* owner, ClockObservation clock,
                          std::uint64_t monotonic_ms, std::uint32_t duration_ms) const noexcept;
    bool consume(OperationPermit& permit, Operation operation, const void* owner,
                 std::uint64_t monotonic_ms) const noexcept;
private:
    friend class LocalLicenseClient;
    // Only the native client may publish another internally verified session.
    // No external caller can manufacture a claims snapshot for admission.
    void adoptVerified(const LicenseSession& candidate) noexcept {
        current_.store(candidate.snapshot(),std::memory_order_release);
    }
    const TrustProfile trust_;
    const HostContext host_;
    std::atomic<std::shared_ptr<const LicenseClaims>> current_;
    const std::shared_ptr<const unsigned char> identity_ = std::make_shared<const unsigned char>(0);
};

// Move-only, native-local, single-use capability. It is never serialized or
// exposed to scripts. Cancellation is destruction. Admission captures the
// accepted grant; renewal cannot extend a permit already in flight. The host
// supplies its own monotonic clock and owner identity, never caller flags.
class OperationPermit {
public:
    OperationPermit() = default;
    OperationPermit(OperationPermit&& other) noexcept;
    OperationPermit& operator=(OperationPermit&& other) noexcept;
    OperationPermit(const OperationPermit&) = delete;
    OperationPermit& operator=(const OperationPermit&) = delete;
    explicit operator bool() const noexcept { return bool(session_); }
    Reason reason() const noexcept { return reason_; }
private:
    friend class LicenseSession;
    std::shared_ptr<const unsigned char> session_;
    std::shared_ptr<const LicenseClaims> grant_;
    const void* owner_ = nullptr;
    Operation operation_ = Operation::Inspect;
    std::uint64_t start_ = 0, deadline_ = 0;
    Reason reason_ = Reason::AuthorityAbsent;
};

} // namespace cyrus::licensing

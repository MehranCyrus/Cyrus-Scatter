#include "cyrus/licensing/signed_license.h"
#include <algorithm>
#include <limits>
#include <utility>

namespace cyrus::licensing {
OperationPermit::OperationPermit(OperationPermit&& other) noexcept { *this = std::move(other); }
OperationPermit& OperationPermit::operator=(OperationPermit&& other) noexcept {
    if (this != &other) {
        session_ = std::move(other.session_);
        grant_ = std::move(other.grant_);
        owner_ = std::exchange(other.owner_, nullptr);
        operation_ = other.operation_;
        start_ = other.start_;
        deadline_ = other.deadline_;
        reason_ = other.reason_;
    }
    return *this;
}

OperationPermit LicenseSession::admit(Operation operation, const void* owner,
    ClockObservation clock, std::uint64_t monotonic_ms, std::uint32_t duration_ms) const noexcept {
    OperationPermit result;
    if ((operation != Operation::AuthorScatter && operation != Operation::AuthorAnalyzer) ||
        !owner || duration_ms == 0 || duration_ms > 30000) {
        result.reason_ = Reason::UnknownOperation;
        return result;
    }
    const auto grant = snapshot();
    AuthorityFacts facts;
    if (grant) facts = {Authority::Verified,
        grant->product == "cyrus-scatter" ? ScatterAuthorRight : AnalyzerAuthorRight,
        true, true, true, grant->not_before, grant->expires};
    const auto decision = cyrus::licensing::decide(operation, facts, clock);
    result.reason_ = decision.reason;
    if (!decision.allowed) return result;
    // Use the beginning of the observed UTC second conservatively: never
    // grant an additional second beyond the signed deadline.
    const auto remaining_seconds = static_cast<std::uint64_t>(grant->expires - clock.utc_seconds);
    const auto remaining_ms = remaining_seconds > 30 ? 30000 : (remaining_seconds - 1) * 1000;
    const auto span = std::min<std::uint64_t>(duration_ms, remaining_ms);
    if (!span || monotonic_ms > std::numeric_limits<std::uint64_t>::max() - span) {
        result.reason_ = Reason::Expired;
        return result;
    }
    result.session_ = identity_;
    result.grant_ = grant;
    result.operation_ = operation;
    result.owner_ = owner;
    result.start_ = monotonic_ms;
    result.deadline_ = monotonic_ms + span;
    return result;
}

bool LicenseSession::consume(OperationPermit& permit, Operation operation,
    const void* owner, std::uint64_t monotonic_ms) const noexcept {
    const bool accepted = permit.session_ == identity_ && permit.owner_ == owner &&
        permit.operation_ == operation && monotonic_ms >= permit.start_ &&
        monotonic_ms < permit.deadline_;
    // Every attempted commit consumes the capability, including wrong-owner
    // or expired attempts. A caller cannot probe then replay it elsewhere.
    permit.session_.reset();
    permit.grant_.reset();
    permit.owner_ = nullptr;
    return accepted;
}
} // namespace cyrus::licensing

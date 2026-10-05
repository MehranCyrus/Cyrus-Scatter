#include "cyrus/licensing/policy.h"

namespace cyrus::licensing {

Decision decide(Operation operation, const AuthorityFacts& facts,
                ClockObservation clock, StateEvidence existing_state) noexcept {
    std::uint32_t required_right = 0;
    switch (operation) {
    case Operation::Inspect:
    case Operation::PreserveScene:
    case Operation::Recover:
        return {true, Reason::Continuity};
    case Operation::RenderExisting:
        // The caller must establish approved existing state independently of
        // editable script flags. L0 demonstrates why that boundary is open.
        return existing_state == StateEvidence::ApprovedExistingState
            ? Decision{true, Reason::Continuity}
            : Decision{false, Reason::ExistingStateUnproven};
    case Operation::AuthorScatter:
        required_right = ScatterAuthorRight;
        break;
    case Operation::AuthorAnalyzer:
        required_right = AnalyzerAuthorRight;
        break;
    default:
        return {false, Reason::UnknownOperation};
    }

    if (facts.authority == Authority::Absent)
        return {false, Reason::AuthorityAbsent};
    if (facts.authority == Authority::Rejected)
        return {false, Reason::AuthorityRejected};
    if (facts.authority != Authority::Verified || facts.not_before_utc < 0 ||
        facts.authoring_end_utc <= facts.not_before_utc)
        return {false, Reason::MalformedAuthority};
    if ((facts.rights & required_right) == 0)
        return {false, Reason::WrongProduct};
    if (!facts.build_eligible)
        return {false, Reason::BuildIneligible};
    if (!facts.device_matches)
        return {false, Reason::DeviceMismatch};
    if (!facts.capacity_reserved)
        return {false, Reason::CapacityUnavailable};
    if (!clock.trusted || clock.utc_seconds < 0)
        return {false, Reason::TimeRecoveryRequired};
    if (clock.utc_seconds < facts.not_before_utc)
        return {false, Reason::NotYetValid};
    if (clock.utc_seconds >= facts.authoring_end_utc)
        return {false, Reason::Expired};
    return {true, Reason::Allowed};
}

const char* reasonName(Reason reason) noexcept {
    switch (reason) {
    case Reason::Allowed: return "allowed";
    case Reason::Continuity: return "continuity";
    case Reason::UnknownOperation: return "unknown_operation";
    case Reason::ExistingStateUnproven: return "existing_state_unproven";
    case Reason::AuthorityAbsent: return "authority_absent";
    case Reason::AuthorityRejected: return "authority_rejected";
    case Reason::MalformedAuthority: return "malformed_authority";
    case Reason::WrongProduct: return "wrong_product";
    case Reason::BuildIneligible: return "build_ineligible";
    case Reason::DeviceMismatch: return "device_mismatch";
    case Reason::CapacityUnavailable: return "capacity_unavailable";
    case Reason::TimeRecoveryRequired: return "time_recovery_required";
    case Reason::NotYetValid: return "not_yet_valid";
    case Reason::Expired: return "expired";
    }
    return "unknown_reason";
}

}  // namespace cyrus::licensing

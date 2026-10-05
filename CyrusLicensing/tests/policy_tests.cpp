#include "cyrus/licensing/policy.h"

#include <cstdint>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>

using namespace cyrus::licensing;

namespace {
int checks = 0;
void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
AuthorityFacts grant(std::int64_t end = 200) {
    return {Authority::Verified, ScatterAuthorRight | AnalyzerAuthorRight,
            true, true, true, 100, end};
}
void expect(Operation op, const AuthorityFacts& facts, ClockObservation clock,
            bool allowed, Reason reason,
            StateEvidence state = StateEvidence::Unproven) {
    const auto result = decide(op, facts, clock, state);
    require(result.allowed == allowed, "unexpected permission");
    require(result.reason == reason, reasonName(result.reason));
}
void defaults() {
    expect(Operation::AuthorScatter, {}, {}, false, Reason::AuthorityAbsent);
    expect(Operation::AuthorAnalyzer, {}, {}, false, Reason::AuthorityAbsent);
    for (auto code : {0u, 7u, 255u, 256u, 0xffffffffu})
        expect(static_cast<Operation>(code), grant(), {true, 150}, false,
               Reason::UnknownOperation, StateEvidence::ApprovedExistingState);
    auto invalid = grant();
    invalid.authority = static_cast<Authority>(255);
    expect(Operation::AuthorScatter, invalid, {true, 150}, false,
           Reason::MalformedAuthority);
}
void lifecycle() {
    const auto original = grant();
    expect(Operation::AuthorScatter, original, {true, 150}, true, Reason::Allowed);
    expect(Operation::AuthorScatter, original, {true, 200}, false, Reason::Expired);
    expect(Operation::RenderExisting, original, {true, 250}, true,
           Reason::Continuity, StateEvidence::ApprovedExistingState);
    expect(Operation::AuthorScatter, grant(400), {true, 250}, true, Reason::Allowed);
    // The old snapshot is not mutated when a renewed one is evaluated.
    expect(Operation::AuthorScatter, original, {true, 250}, false, Reason::Expired);
}
void continuity() {
    for (auto authority : {Authority::Absent, Authority::Rejected, Authority::Verified}) {
        auto facts = grant(); facts.authority = authority;
        for (auto op : {Operation::Inspect, Operation::PreserveScene, Operation::Recover})
            expect(op, facts, {}, true, Reason::Continuity);
        expect(Operation::RenderExisting, facts, {true, 250}, false,
               Reason::ExistingStateUnproven);
        expect(Operation::RenderExisting, facts, {}, true, Reason::Continuity,
               StateEvidence::ApprovedExistingState);
    }
    expect(Operation::RenderExisting, grant(), {true, 150}, false,
           Reason::ExistingStateUnproven, static_cast<StateEvidence>(255));
}
void facts() {
    auto facts = grant(); facts.authority = Authority::Rejected;
    expect(Operation::AuthorScatter, facts, {true, 150}, false, Reason::AuthorityRejected);
    // Independent facts must not unlock access when combined. This is a
    // contract matrix, not an enum where e.g. "offline" overwrites "expired".
    for (unsigned mask = 0; mask < 32; ++mask) {
        auto candidate = grant();
        candidate.build_eligible = (mask & 1u) != 0;
        candidate.device_matches = (mask & 2u) != 0;
        candidate.capacity_reserved = (mask & 4u) != 0;
        candidate.rights = (mask & 8u) != 0 ? ScatterAuthorRight : 0;
        const auto result = decide(Operation::AuthorScatter, candidate,
                                   {(mask & 16u) != 0, 150});
        require(result.allowed == (mask == 31), "fact combination granted access");
    }
    facts = grant(); facts.rights = AnalyzerAuthorRight | (1u << 30);
    expect(Operation::AuthorScatter, facts, {true, 150}, false, Reason::WrongProduct);
    expect(Operation::AuthorAnalyzer, facts, {true, 150}, true, Reason::Allowed);
    facts = grant(); facts.device_matches = false;
    expect(Operation::AuthorScatter, facts, {true, 150}, false, Reason::DeviceMismatch);
    facts = grant(); facts.capacity_reserved = false;
    expect(Operation::AuthorScatter, facts, {true, 150}, false, Reason::CapacityUnavailable);
    facts = grant(); facts.build_eligible = false;
    expect(Operation::AuthorScatter, facts, {true, 150}, false, Reason::BuildIneligible);
}
void deadlines() {
    expect(Operation::AuthorScatter, grant(), {true, 99}, false, Reason::NotYetValid);
    expect(Operation::AuthorScatter, grant(), {true, 100}, true, Reason::Allowed);
    expect(Operation::AuthorScatter, grant(), {true, 199}, true, Reason::Allowed);
    expect(Operation::AuthorScatter, grant(), {true, 200}, false, Reason::Expired);
    expect(Operation::AuthorScatter, grant(), {false, 150}, false, Reason::TimeRecoveryRequired);
    expect(Operation::AuthorScatter, grant(), {true, -1}, false, Reason::TimeRecoveryRequired);
    expect(Operation::AuthorScatter, grant(100), {true, 100}, false, Reason::MalformedAuthority);
    expect(Operation::AuthorScatter, grant(99), {true, 100}, false, Reason::MalformedAuthority);
    auto invalid = grant(); invalid.not_before_utc = -1;
    expect(Operation::AuthorScatter, invalid, {true, 150}, false, Reason::MalformedAuthority);
    const auto max = std::numeric_limits<std::int64_t>::max();
    expect(Operation::AuthorScatter, grant(max), {true, max - 1}, true, Reason::Allowed);
    expect(Operation::AuthorScatter, grant(max), {true, max}, false, Reason::Expired);
    // A future-time observation stays expired. Rollback detection itself is
    // outside this pure function and must set clock.trusted appropriately.
    expect(Operation::AuthorScatter, grant(), {true, 1000000}, false, Reason::Expired);
}
void extension() {
    // Policy values can vary without changing calculation code. Workflow
    // extension is exercised by distinct Max operations in the separate lab.
    for (auto end : {160, 1000, 1000000}) {
        expect(Operation::AuthorScatter, grant(end), {true, end - 1}, true, Reason::Allowed);
        expect(Operation::AuthorScatter, grant(end), {true, end}, false, Reason::Expired);
    }
}
}

int main(int argc, char** argv) {
    try {
        if (argc != 2) throw std::runtime_error("Expected one test group");
        const std::string group = argv[1];
        if (group == "defaults") defaults();
        else if (group == "lifecycle") lifecycle();
        else if (group == "continuity") continuity();
        else if (group == "facts") facts();
        else if (group == "deadlines") deadlines();
        else if (group == "extension") extension();
        else throw std::runtime_error("Unknown test group");
        std::cout << "PASS " << group << ": " << checks << " assertions\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL after " << checks << " assertions: " << error.what() << '\n';
        return 1;
    }
}

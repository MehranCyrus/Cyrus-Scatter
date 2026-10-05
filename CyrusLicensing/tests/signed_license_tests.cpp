#include "signed_support.h"
#include <nlohmann/json.hpp>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <thread>
#include <atomic>

using namespace cyrus::licensing;
namespace {
int checks = 0;
void require(bool value, const std::string& message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
}
int main(int argc, char** argv) {
    try {
        if (argc != 3) throw std::runtime_error("Expected fixtures and test group");
        std::ifstream input(argv[1]);
        if (!input) throw std::runtime_error("Cannot open vectors");
        const auto vectors = nlohmann::json::parse(input);
        const std::string group = argv[2];
        const auto trust = signedLabTrust();
        const auto host = signedLabHost();
        for (const auto& item : vectors["cases"]) {
            if (item["group"] != group) continue;
            const auto name = item["name"].get<std::string>();
            const auto token = item["token"].get<std::string>();
            const auto result = verifyLicense(token, trust);
            require(item["verify"] == tokenErrorName(result.error), name + ": verify=" + tokenErrorName(result.error));
            require(result.claims.has_value() == (result.error == TokenError::None), name + ": claims leaked on failure");
            LicenseSession session(trust, host);
            const auto installed = session.install(token);
            require(item["install"] == tokenErrorName(installed), name + ": install=" + tokenErrorName(installed));
            const auto decision = session.decide(Operation::AuthorScatter, {true, item["now"].get<std::int64_t>()});
            require(decision.allowed == item["allowed"].get<bool>(), name + ": incorrect authoring decision");
        }
        const auto& samples = vectors["samples"];
        const auto active = samples["active"].get<std::string>();
        if (group == "lifecycle") {
            LicenseSession session(trust, host);
            require(!session.hasLicense(), "Session starts empty");
            require(!session.decide(Operation::AuthorScatter, {true, 1800000100}).allowed, "Absent license denied");
            require(session.install(active) == TokenError::None, "Install signed active token");
            require(session.decide(Operation::AuthorScatter, {true, 1800000100}).allowed, "Active authoring");
            require(!session.decide(Operation::AuthorAnalyzer, {true, 1800000100}).allowed, "Product rights are distinct");
            require(!session.decide(static_cast<Operation>(256), {true, 1800000100}).allowed, "Unknown operation denied");
            require(session.install(samples["tampered"].get<std::string>()) == TokenError::Signature, "Reject tampered import");
            require(session.decide(Operation::AuthorScatter, {true, 1800000100}).allowed, "Bad import retained active grant");
            require(session.install(samples["wrong-device"].get<std::string>()) == TokenError::Device, "Reject mismatched context");
            require(session.decide(Operation::AuthorScatter, {true, 1800000100}).allowed, "Bad device import retained grant");
            require(session.decide(Operation::AuthorScatter, {true, 1800003600}).reason == Reason::Expired, "Exact expiry");
            require(!session.decide(Operation::RenderExisting, {true, 1800003600}).allowed, "No assumed scene evidence");
            require(session.decide(Operation::RenderExisting, {}, StateEvidence::ApprovedExistingState).allowed, "Synthetic approved render");
            require(session.install(samples["renewed"].get<std::string>()) == TokenError::None, "Install signed renewal");
            require(session.decide(Operation::AuthorScatter, {true, 1800003700}).allowed, "Renewed authoring");
            require(session.decide(Operation::AuthorScatter, {false, 1800003700}).reason == Reason::TimeRecoveryRequired, "Untrusted time denied");
            require(session.install(active) == TokenError::None, "Old still-authentic token is parseable");
            require(session.decide(Operation::AuthorScatter, {true, 1800003700}).reason == Reason::Expired, "Replayed old token cannot extend term");
        } else if (group == "permits") {
            LicenseSession session(trust,host), other(trust,host);
            int owner=0, different=0;
            require(!session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000),"Absent admission denied");
            require(session.install(active)==TokenError::None,"Permit grant install");
            auto permit=session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000);
            require(bool(permit),"Admitted permit");
            auto moved=std::move(permit);
            require(!permit&&bool(moved),"Move transfers capability");
            require(session.consume(moved,Operation::AuthorScatter,&owner,1001),"Correct commit");
            require(!session.consume(moved,Operation::AuthorScatter,&owner,1002),"Replay denied");
            permit=session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000);
            require(!other.consume(permit,Operation::AuthorScatter,&owner,1001),"Cross-session denied");
            require(!session.consume(permit,Operation::AuthorScatter,&owner,1001),"Failed commit consumes permit");
            permit=session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000);
            require(!session.consume(permit,Operation::AuthorScatter,&different,1001),"Wrong owner denied");
            permit=session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000);
            require(!session.consume(permit,Operation::AuthorAnalyzer,&owner,1001),"Wrong operation denied");
            permit=session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000);
            require(!session.consume(permit,Operation::AuthorScatter,&owner,999),"Monotonic rollback denied");
            permit=session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000);
            require(!session.consume(permit,Operation::AuthorScatter,&owner,31000),"Operation hard deadline");
            permit=session.admit(Operation::AuthorScatter,&owner,{true,1800003598},1000,30000);
            require(session.install(samples["renewed"].get<std::string>())==TokenError::None,"Renew during operation");
            require(!session.consume(permit,Operation::AuthorScatter,&owner,2000),"Renewal cannot extend old permit");
            require(!session.admit(Operation::RenderExisting,&owner,{true,1800000100},1000,30000),"Public render intent is no author capability");
            require(!session.admit(Operation::AuthorScatter,nullptr,{true,1800000100},1000,30000),"Owner required");
            require(!session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30001),"No unbounded operation");
            require(!session.admit(Operation::AuthorScatter,&owner,{false,1800000100},1000,30000),"Time recovery prevents admission");
        } else if (group == "activation") {
            auto activationTrust=trust;activationTrust.token_type+=".activation";
            for(const auto& test:vectors["activation_cases"]) {
                const auto result=verifyActivation(test["token"].get<std::string>(),activationTrust,std::string(64,'c'),host.device);
                require(test["error"]==tokenErrorName(result.error),test["name"].get<std::string>()+": activation error");
                require((result.error==TokenError::None)==!result.license.empty(),"No activation payload leaked on failure");
                if(result.error==TokenError::None) {
                    require(result.server_utc==1800000100,"Authenticated server observation");
                    require((verifyLicense(result.license,trust).error==TokenError::None)==test["nested_valid"].get<bool>(),"Nested authority independently verified");
                }
            }
            require(verifyActivation(active,activationTrust,"",host.device).error==TokenError::Scope,"Empty expected nonce cannot authorize activation");
            require(verifyActivation(active,activationTrust,std::string(64,'c'),host.device).error==TokenError::Header,"License cannot double as activation response");
        } else if (group == "transfer") {
            LicenseSession deviceA(trust,host);
            auto hostB=host;hostB.device=std::string(64,'b');
            LicenseSession deviceB(trust,hostB);
            require(deviceA.install(active)==TokenError::None,"A receives full-term offline grant");
            // A is disconnected. Removing the portal activation cannot modify
            // A's signed token. A hypothetical immediate transfer issues B.
            require(deviceB.install(samples["transferred"].get<std::string>())==TokenError::None,"Immediate B grant authentic");
            require(deviceA.decide(Operation::AuthorScatter,{true,1800000100}).allowed&&
                deviceB.decide(Operation::AuthorScatter,{true,1800000100}).allowed,
                "Concrete B08 overlap: both offline grants remain valid");
            require(!deviceA.decide(Operation::AuthorScatter,{true,1800003600}).allowed,"A finally ends at original signed deadline");
            require(deviceA.snapshot()->id!=deviceB.snapshot()->id,"Separate issuance identities");
        } else if (group == "publication") {
            LicenseSession session(trust,host);
            require(session.install(active)==TokenError::None,"Initial snapshot");
            auto retained=session.snapshot();
            const auto renewal=samples["renewed"].get<std::string>();
            std::atomic<bool> stop{false},failed{false};
            std::thread reader([&]{
                while(!stop.load()) {
                    const auto snapshot=session.snapshot();
                    if(!snapshot||snapshot->device!=host.device||snapshot->not_before!=1800000000||
                        (snapshot->expires!=1800003600&&snapshot->expires!=1800007200))failed=true;
                    if(!session.decide(Operation::AuthorScatter,{true,1800000100}).allowed)failed=true;
                }
            });
            for(int i=0;i<200;++i) {
                if(session.install(i%2?active:renewal)!=TokenError::None)failed=true;
                if(session.install("invalid")==TokenError::None)failed=true;
            }
            stop=true;reader.join();
            require(!failed,"Concurrent readers see only whole verified snapshots");
            require(retained->expires==1800003600,"Previous snapshot immutable and alive");
        } else if (group == "isolation") {
            auto no_keys = trust; no_keys.keys.clear();
            require(verifyLicense(active, no_keys).error == TokenError::UntrustedKey, "No trusted issuer means denied");
            auto duplicate = trust; duplicate.keys.push_back(trust.keys[0]);
            require(verifyLicense(active, duplicate).error == TokenError::UntrustedKey, "Ambiguous key ID denied");
            auto bad_key = trust; bad_key.keys[0].p256_xy.fill(0);
            require(verifyLicense(active, bad_key).error != TokenError::None, "Invalid key point rejected");
            auto other_device = host; other_device.device = std::string(64, 'b');
            LicenseSession copy(trust, other_device);
            require(copy.install(active) == TokenError::Device, "Synthetic other host rejects copied token");
            // Bounded deterministic malformed input probes complement semantic
            // cases. This is not coverage-guided fuzzing or a security audit.
            for (int i = 0; i < 256; ++i) {
                const std::string malformed(static_cast<std::size_t>(i), static_cast<char>(i));
                require(!verifyLicense(malformed, trust).claims.has_value(), "Malformed input published claims");
            }
        }
        require(checks > 0, "Unknown or empty test group");
        std::cout << "PASS " << group << ": " << checks << " assertions\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL after " << checks << ": " << error.what() << '\n';
        return 1;
    }
}

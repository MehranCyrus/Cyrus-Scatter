#include "cyrus/licensing/client.h"
#include <windows.h>
#include <bcrypt.h>
#include <algorithm>
#include <stdexcept>

namespace cyrus::licensing {
namespace {
HostContext bind(HostContext host,const InstallationKey& key) { host.device=key.deviceId();return host; }
void verified(TokenError error) { if(error!=TokenError::None)throw std::runtime_error(tokenErrorName(error)); }
void sameDevice(const LocalState& state,const HostContext& host) {
    if(!state.device.empty()&&state.device!=host.device)throw std::runtime_error("Installation identity changed; recover activation");
}
}
LocalLicenseClient::LocalLicenseClient(TrustProfile trust,TrustProfile activation,HostContext host,
    std::wstring name,std::filesystem::path directory,bool create)
    : key_(std::move(name),create),store_(std::move(directory)),trust_(std::move(trust)),activation_trust_(std::move(activation)),
      host_(bind(std::move(host),key_)),session_(trust_,host_),clock_(0,systemUtcSeconds(),systemMonotonicMs()) {
    const auto state=store_.read();
    if(state) {
        sameDevice(*state,host_);
        if(!state->token.empty())verified(session_.install(state->token));
        generation_=state->generation;
        clock_=ClockTracker(state->highest_utc,systemUtcSeconds(),systemMonotonicMs());
    }
}
ClockObservation LocalLicenseClient::clock() { return clock_.observe(systemUtcSeconds(),systemMonotonicMs()); }
ActivationRequest LocalLicenseClient::requestActivation() {
    std::lock_guard lock(io_mutex_);
    std::array<unsigned char,32> random{};
    if(BCryptGenRandom(nullptr,random.data(),32,BCRYPT_USE_SYSTEM_PREFERRED_RNG)<0)throw std::runtime_error("Nonce generation failed");
    std::string nonce;constexpr char hex[]="0123456789abcdef";
    for(auto v:random){nonce+=hex[v>>4];nonce+=hex[v&15];}
    const auto challenge=nonce+"|"+host_.subject+"|"+host_.tenant+"|"+host_.product;
    const auto proof=key_.signChallenge(challenge);
    store_.update([&](LocalState& state){sameDevice(state,host_);state.device=host_.device;state.pending_nonce=nonce;});
    return {host_.device,nonce,host_.subject,host_.tenant,host_.product,key_.publicKey(),proof};
}
void LocalLicenseClient::activate(std::string_view response) {
    std::lock_guard lock(io_mutex_);
    const auto before=store_.read();
    if(!before||before->pending_nonce.empty())throw std::runtime_error("No pending activation request");
    sameDevice(*before,host_);
    const auto activation=verifyActivation(response,activation_trust_,before->pending_nonce,host_.device);
    verified(activation.error);
    const auto now=systemUtcSeconds();
    if(activation.server_utc>now+2||now-activation.server_utc>120)throw std::runtime_error("Activation response stale or system clock incorrect; request recovery");
    LicenseSession candidate(trust_,host_);verified(candidate.install(activation.license));
    const auto decision=candidate.decide(host_.product=="cyrus-scatter"?Operation::AuthorScatter:Operation::AuthorAnalyzer,{true,std::max(now,activation.server_utc)});
    if(!decision.allowed)throw std::runtime_error(reasonName(decision.reason));
    const auto next=store_.update([&](LocalState& state){
        sameDevice(state,host_);
        if(state.pending_nonce!=before->pending_nonce)throw std::runtime_error("Activation request changed or already consumed");
        state.token=activation.license;state.pending_nonce.clear();
        state.highest_utc=std::max(now,activation.server_utc);
    });
    generation_=next.generation;
    { std::lock_guard stateLock(mutex_);
      session_.adoptVerified(candidate);
      clock_=ClockTracker(next.highest_utc,systemUtcSeconds(),systemMonotonicMs()); }
}
void LocalLicenseClient::importRenewal(std::string_view token) {
    std::lock_guard lock(io_mutex_);
    const auto time=[&]{std::lock_guard stateLock(mutex_);return clock();}();
    if(!time.trusted)throw std::runtime_error("Authenticated activation/recovery required before import");
    LicenseSession candidate(trust_,host_);verified(candidate.install(token));
    const auto claims=candidate.snapshot();
    const auto decision=candidate.decide(host_.product=="cyrus-scatter"?Operation::AuthorScatter:Operation::AuthorAnalyzer,time);
    if(!decision.allowed)throw std::runtime_error(reasonName(decision.reason));
    const auto next=store_.update([&](LocalState& state){
        sameDevice(state,host_);
        if(!state.token.empty()) {
            const auto old=verifyLicense(state.token,trust_);verified(old.error);
            if(claims->expires<old.claims->expires)throw std::runtime_error("Older authority would shorten the existing term");
        }
        state.token=std::string(token);state.highest_utc=std::max(state.highest_utc,time.utc_seconds);
    });
    generation_=next.generation;
    { std::lock_guard stateLock(mutex_);session_.adoptVerified(candidate); }
}
void LocalLicenseClient::refresh() {
    std::lock_guard lock(io_mutex_);
    const auto state=store_.read();
    if(!state)throw std::runtime_error("Local state missing; recovery required");
    sameDevice(*state,host_);
    if(state->generation<generation_)throw std::runtime_error("Restored older state detected in this process");
    if(state->generation!=generation_) {
        if(!state->token.empty()) {
            LicenseSession candidate(trust_,host_);verified(candidate.install(state->token));
            std::lock_guard stateLock(mutex_);session_.adoptVerified(candidate);
        }
        generation_=state->generation;
    }
    // Refresh cannot clear this process's latched clock anomaly.
}
void LocalLicenseClient::checkpoint() {
    std::lock_guard lock(io_mutex_);
    const auto time=[&]{std::lock_guard stateLock(mutex_);return clock();}();
    if(!time.trusted)throw std::runtime_error("Time recovery required");
    store_.update([&](LocalState& state){sameDevice(state,host_);state.highest_utc=std::max(state.highest_utc,time.utc_seconds);});
}
Decision LocalLicenseClient::status(Operation operation) {
    std::lock_guard lock(mutex_);return session_.decide(operation,clock());
}
OperationPermit LocalLicenseClient::admit(Operation operation,const void* owner,std::uint32_t max_ms) {
    std::lock_guard lock(mutex_);return session_.admit(operation,owner,clock(),systemMonotonicMs(),max_ms);
}
bool LocalLicenseClient::consume(OperationPermit& permit,Operation operation,const void* owner) {
    std::lock_guard lock(mutex_);
    const bool allowed=session_.decide(operation,clock()).allowed;
    const bool consumed=session_.consume(permit,operation,owner,systemMonotonicMs());
    return allowed&&consumed;
}
}

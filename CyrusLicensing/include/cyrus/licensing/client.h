#pragma once
#include "local_state.h"
#include "signed_license.h"
#include <mutex>

namespace cyrus::licensing {
struct ActivationRequest {
    std::string device,nonce,subject,tenant,product;
    std::array<unsigned char,64> public_key{},proof{};
};
// Host-independent local client. Account identity is provided by the intended
// application/auth adapter; it is not accepted from a license. No network or
// account system is implemented by this class.
class LocalLicenseClient {
public:
    LocalLicenseClient(TrustProfile license_trust,TrustProfile activation_trust,HostContext host,
        std::wstring key_name,std::filesystem::path state_directory,bool create_installation=false);
    ActivationRequest requestActivation();
    void activate(std::string_view signed_response);
    void importRenewal(std::string_view license);
    void refresh();
    void checkpoint();
    Decision status(Operation operation=Operation::AuthorScatter);
    OperationPermit admit(Operation operation,const void* owner,std::uint32_t max_ms=30000);
    bool consume(OperationPermit&,Operation operation,const void* owner);
    const std::string& device() const noexcept { return host_.device; }
private:
    ClockObservation clock();
    InstallationKey key_;
    LocalStateStore store_;
    TrustProfile trust_,activation_trust_;
    HostContext host_;
    LicenseSession session_;
    ClockTracker clock_;
    std::uint64_t generation_=0;
    // Disk/key/verification operations serialize separately. The clock lock
    // protects only short in-memory decisions and final verified publication.
    std::mutex io_mutex_;
    std::mutex mutex_;
};
} // namespace cyrus::licensing

# 05 — LicenseCore API and Pseudocode

## Provider-neutral API

```cpp
struct ActivationRequest {
    std::string licenseKey;
    RuntimeContext runtime;
};

struct EntitlementSnapshot {
    std::string product;
    std::string licenseId;
    LicenseKind kind;
    std::vector<std::string> features;
    std::chrono::system_clock::time_point issuedAt;
    std::optional<std::chrono::system_clock::time_point> expiresAt;
    std::optional<std::chrono::system_clock::time_point> maintenanceUntil;
    std::optional<std::chrono::system_clock::time_point> offlineUntil;
    MachineBinding machine;
    SignatureInfo signature;
};

class ILicenseProvider {
public:
    virtual ~ILicenseProvider() = default;
    virtual ProviderResult activate(const ActivationRequest&) = 0;
    virtual ProviderResult deactivate() = 0;
    virtual ProviderResult refresh() = 0;
    virtual ProviderResult acquireFloating() = 0;
    virtual void releaseFloating() = 0;
    virtual ProviderResult importOffline(std::string_view response) = 0;
    virtual std::string createOfflineRequest(std::string_view key) = 0;
};

class LicenseCore {
public:
    static LicenseCore& instance();
    LicenseDecision authorize(Capability);
    LicenseStatus status();
    Result activate(std::string_view key);
    Result deactivate();
    Result refresh();
    Result importOffline(std::string_view);
    Result createOfflineRequest(std::string_view key);
};
```

## Startup

1. load release metadata;
2. initialize crypto/public verification material;
3. load local signed provider/cache state;
4. verify before parsing trusted claims;
5. derive RuntimeContext;
6. evaluate cached entitlement;
7. schedule background refresh only when appropriate.

## Gate

```cpp
auto d = LicenseCore::instance().authorize(Capability::AuthorScatter);
if (!d.allowed)
    throw RuntimeError(toMaxMessage(d));
```

## No provider calls in authorization hot path

`authorize()` should be local and fast. Network/provider refresh happens asynchronously or at explicit activation/refresh events.

## Diagnostics

Expose sanitized:
- product version;
- host version;
- state/reason;
- license kind;
- maintenance eligibility;
- activation mode;
- last successful refresh;
- grace/offline expiry;
- hashed machine identifier.

Never expose admin tokens, raw hardware identifiers or private provider payloads unnecessarily.

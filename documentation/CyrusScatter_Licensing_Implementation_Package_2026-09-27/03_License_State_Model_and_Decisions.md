# 03 — License State Model and Decisions

## State

```cpp
enum class LicenseState {
    Uninitialized,
    NoLicense,
    TrialActive,
    TrialExpired,
    LicensedOnline,
    LicensedCached,
    LicensedOffline,
    FloatingLeased,
    Grace,
    MaintenanceExpiredButBuildEligible,
    BuildNotEntitled,
    Suspended,
    Revoked,
    ClockSuspect,
    ProviderUnavailable,
    Error
};
```

## Decision object

```cpp
struct LicenseDecision {
    bool allowed;
    Capability capability;
    LicenseState state;
    ReasonCode reason;
    std::chrono::seconds retryAfter;
    bool shouldPromptUser;
};
```

Every gate consumes a `LicenseDecision`; UI can display the same reason without inventing its own policy.

## Example decisions

- perpetual license + expired maintenance + build published before maintenance expiry → allow;
- same license + newer build → `BuildNotEntitled`;
- render worker + existing-scene evaluation → allow `RenderExistingScene`;
- render worker + CS Edit move → deny `ModifyScatter`;
- provider temporarily unavailable + valid signed cache inside grace → allow and report `Grace`;
- revoked license with refreshed signed state → deny authoring;
- no license while loading a scene → preserve saved data, deny new authoring.

## State transitions

Online activation creates trusted local state. Background refresh updates it. Network failure can enter Grace. Grace expiry does not corrupt scene state; it blocks authoring capabilities. Offline activation produces a separately signed time-bounded entitlement snapshot. Floating uses a lease lifecycle.

## Policy purity

Make the capability policy a pure function over:
- entitlement snapshot;
- runtime context;
- release metadata;
- trusted time state;
- requested capability.

That makes the most important licensing behavior unit-testable without Max or a provider.

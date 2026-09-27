# 04 — Native Architecture and File Layout

## Recommended process-wide authority

Because Scatter and Surface Analyzer are separate native Max modules, use a small shared native DLL rather than statically duplicating provider/session state into each module.

```text
AminScatter.dlx -----------\
CyrusScatterEdit.dlm -------+--> CyrusLicenseCore.dll --> provider adapter
CyrusSurfaceAnalyzer.dlx ---/             |
                                         +--> signed cache
                                         +--> RuntimeContext
                                         +--> capability policy
```

Expose a narrow C ABI or otherwise ABI-stable boundary. Keep provider SDK types private.

## Proposed repository layout

```text
Licensing/
├─ CMakeLists.txt
├─ include/cyrus_license/
│  ├─ api.h
│  ├─ capability.h
│  ├─ decision.h
│  ├─ entitlement.h
│  ├─ runtime_context.h
│  └─ provider.h
├─ src/
│  ├─ license_core.cpp
│  ├─ policy.cpp
│  ├─ runtime_context.cpp
│  ├─ trusted_time.cpp
│  ├─ secure_cache.cpp
│  ├─ diagnostics.cpp
│  └─ providers/
│     ├─ fake_provider.cpp
│     ├─ cryptlex_provider.cpp
│     └─ keygen_provider.cpp
└─ tests/
   ├─ policy_tests.cpp
   ├─ state_tests.cpp
   ├─ maintenance_tests.cpp
   ├─ render_policy_tests.cpp
   └─ provider_contract_tests.cpp
```

## Why a DLL

- one process-wide state/lease;
- Analyzer and Scatter agree on status;
- provider SDK initialized once;
- one cache and trusted-time record;
- future provider replacement is isolated.

## Version-specific packaging

The DLL itself should not include Max SDK headers. Initially package/test a copy beside each Max-version native module rather than assuming one binary is safe across all hosts.

## Client secrets

Only public verification keys, product/account identifiers and non-secret endpoints may ship in the client. Management API keys, webhook secrets and signing private keys belong on server/CI systems.

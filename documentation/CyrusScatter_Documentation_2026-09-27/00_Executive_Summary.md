# 00 — Executive Summary

## What exists today

**VERIFIED CURRENT SYSTEM**

Cyrus Scatter contains a C++17 scatter core (`amin_scatter`), a native Max bridge (`AminScatter.dlx`), a native preview system, a native CS Edit modifier, a generator-driven MAXScript controller/UI, a PFlow-based final-render bridge, and a separate native Cyrus Surface Analyzer with its own tests and Max bridge.

The architecture is already suitable for commercial hardening. The valuable algorithms are not solely exposed as editable MAXScript.

## Recommended commercial model

**RECOMMENDATION**

- Perpetual ownership with 12 months of updates.
- Optional annual maintenance for newer releases.
- Solo: node-locked.
- Studio: hosted floating/concurrent.
- Trial: about 30 days, full feature.
- Render workers: free restricted `RenderExistingScene`.
- Offline: signed request/response or signed license-file workflow.
- Background/periodic validation; no WAN checks in viewport/render hot paths.
- Reasonable grace period for temporary outages.

## Recommended architecture

```text
Commerce / MoR
      |
      v
Provisioning service
      |
      v
Licensing provider
      |
      v
ILicenseProvider
      |
      v
Native LicenseCore
  |       |       |
  v       v       v
Bridge  CS Edit  Analyzer Bridge
  |               |
  v               v
Scatter Core   Analyzer Core
      \         /
       MAXScript UI/orchestration
              |
        Preview / PFlow render
```

The product should ask capability questions such as `AuthorScatter`, `ModifyScatter`, `UseSurfaceAnalyzer`, `RenderExistingScene` and `ExportOrBake`, rather than using one global `licensed?` flag.

## Security position

No desktop plugin is literally uncrackable. The goal is to stop casual copying/key sharing and make bypassing require meaningful native reverse engineering.

Highest-value layers:
1. native capability gates at multiple valuable operations;
2. asymmetric signed entitlements;
3. provider activation/concurrency limits;
4. tolerant device binding;
5. offline cache plus periodic refresh/grace;
6. signed binaries/packages;
7. protected release secrets;
8. selective obfuscation only if real piracy later justifies it.

Avoid always-online DRM, destructive scene behavior, and whole-product virtualization as the first defense.

## Immediate engineering priorities

1. Centralize version/product metadata.
2. Add `LicenseCore`, `ILicenseProvider`, `FakeLicenseProvider`, `RuntimeContext`.
3. Add policy unit tests.
4. Gate scatter authoring, CS Edit mutation and Analyzer use natively.
5. Validate render-only behavior on real render workers.
6. POC Cryptlex and Keygen behind the same interface.
7. Move commercial deployment toward Autodesk Application Plug-in Package format.
8. Add Authenticode signing and protected release CI.

## Release risks visible now

- Current native builds explicitly target 3ds Max 2026.
- Version numbers are fragmented.
- Current installer is development-oriented.
- Render-only policy is not yet implemented/tested.
- Repository visibility was public during this audit.

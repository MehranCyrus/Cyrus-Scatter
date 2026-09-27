# 06 — Implementation Roadmap

## Branch/worktree

Keep `main` stable. Use a dedicated licensing branch/worktree.

```powershell
git worktree add -b licensing-development "..\CyrusScatter-Licensing" main
```

## Phase 0 — baseline

- tag known pre-licensing state;
- confirm repo visibility;
- secret scan;
- archive representative MAX scenes;
- record Class IDs/chunk IDs;
- build Release;
- run all CTests;
- run clean Max 2026 smoke tests.

## Phase 1 — version source

Create one `version.json` feeding CMake, native descriptions, MAXScript About, package metadata, release filename and entitlement release eligibility.

Keep public product version separate from scene migration/storage versions.

## Phase 2 — provider-independent licensing

Implement `Entitlement`, `Capability`, `RuntimeContext`, `ILicenseProvider`, `FakeLicenseProvider`, local cache and policy unit tests.

Test valid/expired perpetual, maintenance, subscription, trial, offline, floating and render-worker states.

## Phase 3 — native gates

Gate scatter authoring, CS Edit mutation, Analyzer use and optional export/bake. Do not modify pure math cores.

## Phase 4 — generated licensing UI

Add generated status/activation/deactivation/offline/seat/maintenance diagnostics. Rename the existing non-commercial `activation.cjs` to avoid confusion.

## Phase 5 — provider POCs

Implement Cryptlex and Keygen behind the same interface. Use sandbox/test credentials only.

Acceptance tests: activation, second machine, transfer, offline request/response, offline expiry, outage, clock rollback, floating exhaustion, crash/zombie lease, revocation and render-only.

## Phase 6 — render farm

Validate actual production workflows: command-line/network worker, Deadline if targeted, Corona, Arnold, supported IR, multi-frame behavior and callback cleanup.

## Phase 7 — Autodesk package

Target:
```text
CyrusScatter.bundle/
├── PackageContents.xml
└── Contents/
    ├── 2026/
    ├── 2027/
    ├── Scripts/
    ├── Resources/
    └── Licensing/
```

## Phase 8 — signing/release

Authenticode-sign and timestamp binaries/package, protect production secrets, generate release hashes/manifest, test clean install/upgrade/uninstall.

## Phase 9 — beta

Include freelancer, studio/floating, render-farm and offline simulations. Measure support burden and false machine changes before adding heavier anti-tamper.

## Definition of done

- editing MAXScript alone cannot enable authoring;
- no private signing/admin secret ships;
- offline works;
- temporary outage does not instantly stop work;
- render workers render existing scenes without authoring seats;
- render workers cannot author/edit/bake;
- licensing never damages scene data;
- supported Max builds install and load cleanly;
- provider can be replaced without changing scatter algorithms.

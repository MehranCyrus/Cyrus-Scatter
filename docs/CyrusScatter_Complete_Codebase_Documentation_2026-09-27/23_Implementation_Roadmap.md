# 23 — Implementation Roadmap

## Phase 0 — prove baseline
- make repository private if appropriate;
- secret scan;
- build Release;
- run all CTests;
- capture clean Max 2026 load log;
- archive representative old scenes;
- capture current Class IDs/chunks/parameter schema.

## Phase 1 — documentation/build hygiene
- add top-level developer README;
- centralize product release metadata;
- add generator deterministic-output check;
- document supported renderer workflows.

## Phase 2 — LicenseCore without vendor
- entitlement/capability model;
- RuntimeContext;
- FakeLicenseProvider;
- local cache interface;
- unit tests.

## Phase 3 — native gates
- scatter authoring;
- CS Edit mutation;
- Analyzer interactive analysis;
- bake/export;
- restricted render evaluation.

## Phase 4 — generated license UI
Add generator stage/template for status, activate/deactivate, offline request/import, seat/machine status and diagnostics. Rename current feature `activation.cjs`.

## Phase 5 — provider POCs
Cryptlex and Keygen behind the same interface; compare integration/UX/support/cost.

## Phase 6 — render validation
Production render, cancellation, Corona IR, command-line/network worker, Deadline if targeted, multi-frame and renderer matrix.

## Phase 7 — Max 2027 + package migration
Dedicated native build, Application Plug-in Package, old-install migration.

## Phase 8 — signing/release CI
Protected signing, timestamping, hashes/manifest, reproducible generator step, release archive.

## Phase 9 — commercial beta
Freelancer + studio + render-farm + offline scenarios. Measure real support and piracy pressure before adding heavier protection.

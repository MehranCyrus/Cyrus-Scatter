# 10 — Quality, qualification and release operations

## Current verification baseline

Seven existing Release executables pass in this review. A previous isolated Max 2027.1 smoke test passed. The generator reproduces exactly. Packages pass integrity checks. These are useful starting gates; none replaces full scene, UI or renderer testing. See [evidence ledger](02_Current_System_and_Evidence.md).

## Required test layers

| Layer | Cases | Acceptance |
|---|---|---|
| Pure engine | Existing suites; degenerate/nonfinite input; ties; units; holes; ordered filters; limits | Deterministic outputs and meaningful failures |
| Generator | Two runs, production comparison, anchor counts, parameter/primitive/callback manifest | Expected output and schema; no silent patch omissions |
| Host integration | Native/script load, all modes, actual nonempty Analyzer output, edited stacks | Correct output across supported host builds |
| Persistence | Old/current scenes; save/reopen; legacy chunks; clone/merge; deleted dependencies | No lost/reassigned edits or silent parameter drift |
| Rendering | Exact transport data plus image comparison; abort/IR/time changes | Correct result, no duplicates/leaks, flags restored |
| Installation | Clean user, wrong host, upgrade/downgrade, old MZP migration, uninstall | Exactly intended modules loaded; scenes preserved |
| Resources | 32 GB, repeated rebuilds, undo growth, allocation/work limits | Bounded memory and graceful failure |
| Licensing | No license, trial/maintenance expiry, outage, offline, floating, worker | Correct capability decision; scene fidelity retained |
| Artist usability | First scatter, revision, troubleshooting, handoff | Task completed without developer rescue |

## Host and renderer matrix

Maintain one row per exact combination. Required host years remain 2024/2025/2026/2027; qualified updates are recorded individually. Test the lowest claimed update and current chosen update per year where API changes warrant it. A new host point release is not automatically covered by an earlier test.

| Dimension | Required values / policy |
|---|---|
| CPU | Intel and AMD coverage; baseline instruction set compatible with host/renderer; no accidental whole-binary AVX uplift |
| RAM | Real 32 GB machine plus a larger workstation |
| GPU | Ordinary supported viewport; compute absent; optional devices tested by named driver/runtime |
| OS | Windows 11 common target; any older-host Windows 10 support separately decided |
| Renderer | Exact chosen Corona/V-Ray/other builds; CPU/GPU/IR/DR separate where advertised |
| Paths | Spaces, Unicode, non-default install location, project paths and UNC assets |
| User profile | Clean non-developer profile without build PATH/SDK dependencies |
| UI | Common DPI scales, narrow/wide command panel, repeated open/close/select |

Autodesk's Max 2027 system requirements inform the host baseline; Cyrus's 32 GB requirement is a separate product target. [System requirements](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-3ds-Max-2027.html)

## Priority regression scenarios from this review

1. Legacy/basic-axis state with a zero density map and projection disabled.
2. Valid preview followed by invalid input; freshness and recovery behavior.
3. Unrelated sentinel node created during PFlow success/failure; cleanup must preserve it.
4. Two edited layers; remove an earlier layer and verify mapping/invalidation is explicit.
5. Nonempty CS Edit mutations: move, clone, delete, lower-modifier toggle, undo/redo, save/reopen.
6. Analyzer native success followed by Street Side failure; no mixed published arrays.
7. Truncated/oversized edit chunks; deterministic rejection without excessive allocation.
8. Clean worker renders without prior UI activity or optional compute dependency.

These are meaningful behavioral tests. Do not add tests merely to restate a function's implementation.

## Release pipeline

Freeze a filesystem source snapshot → regenerate and compare → build using pinned toolchains → native tests → package matched modules/scripts → host/scene/render tests → sign native artifacts → verify signatures → create final manifest/checksums → archive immutable package, symbols, evidence and release notes.

The current MZP packager is suitable for internal builds. Commercial deployment should implement a version-bounded Autodesk bundle, detect previous registrations, and provide rollback. Do not overwrite loaded DLLs or create duplicate class registration. Do not assume a deterministic ZIP implies bit-reproducible native binaries.

A release record needs product version, publication/entitlement date, host target, toolchain, source and generator hashes, native hashes, dependency/license inventory, signing identity and test evidence. Filesystem hashes/archive IDs fulfill provenance in this no-Git workflow.

## Build identity

Generate public version data from one source into About, diagnostics, installer and native metadata. Keep script/class schema versions separate. Include loaded module paths in local diagnostics so a stale DLL can be identified. Mask sensitive paths in a shareable support report.

Define consistent compiler warnings and static analysis for owned source; do not blindly promote third-party SDK warnings to errors. Add standalone memory/address tooling where supported and targeted to a concrete risk. Host stress tests remain necessary.

## Release gates

### Internal measurement build

Loads in the named host, preserves reference behavior, emits useful diagnostics, and has a reversible installer. Known gaps are listed explicitly.

### Artist beta

Flagship workflows pass, relevant correctness risks are resolved, interactive UI is inspected, selected renderer works, save/reopen and rollback pass, and a clear guide/test kit ships.

### Public paid release

Every advertised host/renderer row passes; no unresolved scene-loss/crash/incorrect-render blocker; licensing/recovery/provisioning and signing are exercised; support can reproduce and triage failures. If only a subset is qualified, release claims must match that subset while the broader support requirement remains unfinished.

## Severity and recovery

**Critical:** lost/corrupted scene data, wrong-instance edits, destructive cleanup, repeatable host crash. Stop affected distribution and provide rollback.

**High:** wrong final render, unrecoverable activation/worker failure, broken supported install, unbounded memory. Block the affected release claim.

**Medium:** recoverable workflow interruption, substantial measured slowdown, misleading state. Fix or document with a usable workaround before expanding beta.

Retain private symbols and an opt-in diagnostic bundle. A support report includes exact build/host/renderer, action sequence, fixture or sanitized reproduction, expected/actual output and relevant logs. Never require customers to upload a proprietary production scene as the first troubleshooting step.

## Safe experiments

Use scene copies, isolated processes and explicit fault injection. Do not inject faults into the artist's active Max session. Keep a known-good package and verify that rolling back restores the reference scene. A new feature and a performance optimization should normally arrive as separate reviewable changes.

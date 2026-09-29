# 12 — First implementation milestone: Baseline and Trust

## Intended outcome

Deliver a Max 2027.1 internal build that preserves known scene behavior, reports where time/memory goes, and includes reproducible scenes for choosing the next improvement. Resolve confirmed correctness failures on the exercised path before making speed claims.

The existing 2027 installers and source remain the comparison baseline. Do not add licensing enforcement, a new distribution algorithm, a Qt rewrite, or GPU execution to this measurement build.

## Work packages in order

### 1. Freeze the baseline and release identity

Use a filesystem archive and SHA-256 manifest for production source, generator inputs/output, native modules, installer and relevant tests. Include toolchain/SDK/host versions and scene schema. Preserve existing package files with a unique immutable build ID for new candidates; do not overwrite the only baseline copy.

Introduce one product metadata source, with separate fields for Scatter/Analyzer package versions, host target, channel and publication status. Publication/entitlement date must be finalized deliberately at release; a local build timestamp is not a maintenance entitlement rule.

**Files to inspect:** [build tool](../../tools/build_max.py), [shared CMake](../../cmake/CyrusMaxSDK.cmake), both CMake projects, installer templates and About/status output.

### 2. Turn generator repeatability into a gate

Use the successful [two-run result](evidence/generator_check.json). Add an isolated generation command/check with a readable first-difference report. Record class IDs, parameter names/types, callable primitives and callback IDs in a generated schema manifest. Guard transformations that currently use unchecked replacement/slicing.

Do not change generated output simply to satisfy a stale expectation. Intentional schema changes require their own migration review.

### 3. Add bounded measurement

Implement opt-in timing spans and counters at the actual controller, bridge, preview, Analyzer and PFlow boundaries. Export one local JSON report on demand; no upload. Capture cache miss reasons, requested/emitted/displayed counts, current/stale state, build hashes, host/renderer, units, operation ID and memory observations.

Proposed report shape:

```json
{
  "schema": 1,
  "buildId": "candidate-id",
  "host": {"year": 2027, "fullVersion": "record-at-runtime"},
  "operation": {"id": 1, "kind": "preview-update", "cache": "miss"},
  "counts": {"requested": 0, "emitted": 0, "displayed": 0},
  "spans": [],
  "memory": {"processPeakBytes": null, "pluginScratchPeakBytes": null},
  "warnings": []
}
```

This is a proposed schema, not an existing command. Missing measurements stay null; zero means a measured zero. Store raw samples with parent/child span relationships. Avoid per-instance log strings and unbounded traces.

### 4. Capture behavior and scene fixtures

Start with simple built-in assets and fixed seeds/units:

- Plane + box, 1k/10k/100k placements; all preview modes.
- Dense surface with anchors/projected movement and equal-distance face cases.
- Courtyard with holes, edge rows, falloff and two interacting layers.
- Analyzer corridors/rings/tilted disconnected elements, with nonempty expected output.
- Two real edited layers with move/clone/delete, undo and save/reopen.
- Small render scene with materials, mirrored/nonuniform transforms and repeated start/abort.

Create version-compatible scene builders rather than assuming one newer `.max` file opens in every older host. Golden output stores canonical numeric bits and original ordering with readable mismatch diagnostics.

### 5. Reproduce the review findings

Use C-01 through C-06 from [02](02_Current_System_and_Evidence.md). Classify each as confirmed defect, intended behavior needing documentation, or unresolved. A source suspicion is not a reason to silently rewrite semantics.

For a confirmed defect: preserve the reproducer, make an isolated fix in the authoritative source/template, regenerate, rerun affected regressions, then compare with the pre-fix scene. Explain any intentional behavior correction to users separately from performance gains.

Last-valid display and atomic Analyzer publication require explicit freshness/error behavior and memory bounds. PFlow ownership tests require sentinel nodes and injected failures in a disposable process.

### 6. Run the first measurement campaign

Use the existing warm/cold protocol on the working 2027.1 host. Include unchanged selection/navigation, input bursts, one-layer changes, Analyzer updates and render preparation. Add at least one representative artist scene when available.

Produce a ranked cost table: whole operation, active computation, event delay, marshaling, draw, transport, peak memory and cache reasons. Choose the first optimization only after that table exists.

## Acceptance checklist

- [ ] Unique baseline/candidate identities and preserved packages.
- [ ] Generator output reproducible; schema changes explained.
- [ ] Existing seven native suites pass from the candidate build.
- [ ] Diagnostic overhead measured enabled/disabled.
- [ ] Golden fixtures captured and candidate parity checked.
- [ ] Host smoke extended to actual edit mutations and nonempty Analyzer results.
- [ ] Small rendered result and lifecycle cleanup verified on the named renderer.
- [ ] Review findings classified with reproductions or documented uncertainty.
- [ ] Timings use matched work and include raw samples.
- [ ] One-page decision names the next bottleneck and its acceptance gate.

## What the user receives

A new clearly labeled MZP/internal installer, a short install/rollback guide, reproducible scenes or scene builders, diagnostics export instructions, a before/after behavior summary, and the first profile report. At this milestone, the improvement may be visibility and reliability rather than speed; do not rename it a performance release without measurements.

## Inputs still needed, without blocking independent work

Exact intended renderer/builds, representative production scenes, older-host test access, and a real 32 GB test machine. Baseline diagnostics, fixtures, policy design and source-level fixes can proceed while these are arranged. No renderer should be installed or purchased merely because this document lists it.

# Cyrus Scatter 0.7 — implementation and validation status

> **Later work is not complete:** The checklist below belongs to the 4 October candidate. The [5 October handoff](../Review_Handoff_2026-10-05/README.md) records the unfinished sidebar/native-column update and the remaining acceptance gates.

Baseline: `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`. Implementation follows the [reviewed procedural plan](../Procedural_Evaluation_2026-10-04/README.md).

The coding phase respected the user's no-computer-use constraint. The user subsequently authorized computer access; the isolated Max 2027 validation phase is now complete. The artist's process/profile and unrelated licensing work were preserved.

## Delivery checklist

- [x] Inspect baseline and preserve unrelated licensing work.
- [x] Add opt-in stable candidate random channels and ordinal ranges; preserve legacy streams.
- [x] Add native variable-radius rules and ordered three-scope evaluator with bounded cleanup/replay.
- [x] Compile and exercise independent native numerical oracles and old suites: 13/13 in each SDK build, including 240 exhaustive comparisons.
- [x] Wire versioned host transport, stable order/bindings, radius overrides, coverage/fill, transactional publication and candidate/prepared/display cache boundaries.
- [x] Wire native controls and regenerate the script/inventory at product version 0.7.0; 218 inventoried controls.
- [x] Extend read-only MCP configuration/diagnostics while preserving closed legacy apply schemas; 64 automated tests pass.
- [x] Build and hash-verify Max 2026/2027 candidate packages, verify generator reproducibility, and prepare a disposable Max fixture.
- [x] Write implementation, validation and artist testing documents; retain unexecuted runtime gates explicitly.

## Authorized Max validation

- [x] Compile/load the generated script in isolated Max 2027 with verified loaded native paths/hashes.
- [x] Fix case-label parsing, rethrow syntax and generated definition/owner scope; verify in a fresh process.
- [x] Execute procedural, Brush, UI, Undo/save/reopen, Edit binding/rollback and live MCP fixtures.
- [x] Measure 20k/100k navigation counters, synchronous latency and whole-process peak memory against the actual frozen 0.64 package.
- [x] Reproduce and document the automatic unit-rescale limitation and exact recovery by adopting file units.
- [x] Rebuild both script-containing MZPs against unchanged tested native binaries; verify package hashes.
- [x] Preserve concise runtime receipts and write [the full report](RUNTIME_REPORT.md).
- [ ] Max 2026 application/runtime and installer transition qualification (application unavailable locally).
- [ ] Artist acceptance on real project copies and wider production-asset qualification.

The current bounded implementation and remaining scope are described in [IMPLEMENTATION.md](IMPLEMENTATION.md). Per-edge final-layer result caching, cross-layer coverage composition, additional assignment adapters and ML remain future work; they are not silently represented as completed features.

Remaining engineering work includes coordinated Brush/Edit/radius unit migration and retained Proxy drawing for very high display counts. The new policy is read-only through MCP. These are explicit limits, not failed checks hidden by a passing test count. No new presented-FPS claim is made.

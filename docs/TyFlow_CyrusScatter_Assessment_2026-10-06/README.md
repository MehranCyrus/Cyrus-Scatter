# tyFlow and Cyrus Scatter: independent engineering assessment

**Frozen pre-0.72 assessment.** Its same-topic popup-owner P1 was subsequently fixed in [Scatter 0.72](../Integrated_UI_0.72_2026-10-06/RESULTS.md). Later bounded binary work establishes selected UI reuse and render paths that were unknown at this assessment. Use the [current comparative R&D review](../TyFlow_CyrusScatter_RnD_2026-10-06/README.md) for today's source/evidence/maturity and next loops. The original identities and results below are preserved.

6 October 2026. Research and source review of the actual working tree, including untracked playback changes. No production code was changed for this assessment.

The strongest explanation for the earlier Live playback problem is unnecessary work in the former unconditional time callback and clock-based cache keys. Those paths have been corrected in the current source, with matching private build and headless regression evidence. This does not establish the FPS improvement in the artist's installed session. UI interaction latency remains unmeasured. Proxy has a separate drawing limitation: it submits cached triangles on each redraw, while Mesh and Point Cloud use retained render items.

tyFlow's documentation establishes static-flow reuse, configurable caching and threading, separate simulation/upload profiling, and Qt parameter rollouts. The previously inspected binary confirms some Qt layout construction and native particle accessors. We cannot establish its private control-reuse strategy, scheduler, spatial structures or publication algorithm from the available interfaces. Its use of native C++ or Qt alone does not explain a measured advantage over Scatter.

**A new P1 source-review finding needs attention:** the popup's same-topic optimization can skip control rebinding when switching to another layer or Scatter owner. Its title can name the new owner while existing controls still refer to the preceding owner. This is a traced implementation regression, not a reproduced interactive Max test. See finding F1 in the report; no fix was applied during this research task.

Cyrus Scatter already has useful foundations to preserve: stable owner/source/candidate identities, explicit ordered evaluation, bounded collision/refill work, staged procedural publication, copied-data CPU workers, retained Mesh/Point Cloud buffers, and a bounded recorder. Next work should correct the binding regression, expose the selected layer in Modify with an optional separate view over the same model, make diagnostics accessible directly from Scatter, and qualify playback/UI/Corona on the exact matching script/native pair.

## Read the assessment

- [Engineering report](REPORT.md): evidence boundary, architecture comparison, scheduling, calculation, viewport/rendering, threading, severity-ranked findings, UI ownership and test quality.
- [Evidence and source identities](EVIDENCE.md): primary URLs, pinned GitHub file/line references, exact local source references, fingerprints and historical measurement boundaries.
- [Prioritized roadmap](ROADMAP.md): each recommendation's evidence, smallest change, benefit, tradeoff, acceptance criteria and uncertainty.
- [Controlled experiments](EXPERIMENTS.md): unresolved questions, benchmark matrix, reproducible cases and what each measurement can establish.

## Snapshot and verification

Reviewed branch: codex/floating-layer-editor-0.7.1. HEAD: 147e3f524aa3f4cd9db9bb2bffb7350f9f78de31. The starting tree had 15 modified tracked files plus untracked playback source, harnesses and documentation; nothing was staged. HEAD alone does not identify the reviewed implementation.

The current generated Scatter script SHA-256 is d1f264b7702d4ccc75eb782d60134b46ddcf04bf7f550f8a702c8a34fe65c772. The earlier 0.7.1 package script is c3f0b693a3854e9d11077bdea739469290e9a8a6e45f82ba44f38c6a1b486c8f. They are different candidates.

[Initial source inventory](evidence/source-state-before.json) fingerprints 532 tracked/untracked nonignored source/configuration files. [Receipt audit](evidence/receipt-audit.json) independently matched 20 indexed changed-source hashes, 13 preserved receipt files, all source entries in four SDK build receipts, and ten local native binary hashes. The [recorded final Max 2027 run](../Playback_Performance_2026-10-06/evidence/max2027-headless.json) identifies run19 and its loaded modules. That campaign was inspected, not rerun for this assessment.

[Final verification](evidence/verification.json) compares the [ending inventory](evidence/source-state-after.json) with the initial snapshot: all 532 inventoried source/configuration files, HEAD, branch and staged state are unchanged. The documentation index preserves its prior content and adds one assessment paragraph. Local report links/line ranges and preserved receipts/binaries were checked. A separate untracked docs/TyFlow_Architecture_Research_2026-10-06/ directory appeared after the initial snapshot; this assessment left it untouched and did not use it as evidence. The entire working-tree status therefore is not claimed to be unchanged.

Scope excludes plugin installation, changes to Max profiles or artist scenes, computer-use, production implementation, commits and pushes. Licensing implementation was not reviewed or changed. MCP policy 3 remains read-only; no ML capability is asserted.

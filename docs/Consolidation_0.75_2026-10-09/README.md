# Cyrus Scatter 0.75 — workflow consolidation

9 October 2026. This is a focused consolidation release, following the [0.59/0.64/current comparison](../Historical_Comparison_2026-10-09/README.md). Product/package **0.75.0**, UI **0.75**, saved schema **54**, calculation model **CyrusUnified1**. Analyzer and the MCP protocol/plan versions are unchanged.

## Artist workflow

**Layer → Surfaces → Models → Amount → Update scatter.**

Models are the first controls in their section. Source containers remain available under Advanced. Amount offers count or density. Painting is optional: when Use Paint Areas is off, the area/brush controls are hidden and the whole receiving surfaces are eligible. Turning it off retains saved paint. Turn it on, create/select an area and choose its receiver to paint again.

Ordinary layers offer two spacing choices: **Within this layer** and **Between layers**. The existing independent rules are preserved. Older multi-group files expose all five scopes using model-group wording, so simplifying a new layer does not silently change an old file’s rules. The workflow/help text now explains layers and optional Paint Areas.

## Completed

- [x] Bump product, installer, UI and help catalog to 0.75; preserve registration identities and saved schema.
- [x] Put the ordinary model list first; put source-container setup under Advanced.
- [x] Rename Population to Amount and the main action to Update scatter.
- [x] Hide area/brush authoring while Painting is off without deleting documents.
- [x] Present within-layer/between-layer spacing for ordinary layers; preserve independent rules and older group scopes.
- [x] Correct workflow/help wording that still described mandatory paint sets.
- [x] Reproduce and fix Manual-mode publication after unrelated Undo/Redo.
- [x] Reuse unchanged Brush stroke preparation, preserving exact coverage semantics.

## Manual-mode correction

In the frozen 0.74 private host, generate 1,000 plants, leave an edit to 1,234 pending, create an unrelated box in an Undo block, then Undo. The old host published **1,234** plants. This was a reproduced defect, not the separate cold container Undo-history finding.

The Undo callback marked the preview as cold; its refresh path could evaluate the pending recipe even in Manual mode. Passive refresh now evaluates only for Live, an explicit Update scope, or reconstruction of an absent initial publication. Manual invalidation preserves the warm preview state. The explicit scope is restored after errors, and failed successors keep the previous completed output. Explicit Refresh areas also uses the Update path.

## Brush preparation

The derived field now shares immutable prepared stroke entries with its preceding field when the complete stroke input and surface fingerprint match. Adding a stroke or extending the pending one does not rerun resampling and connected-surface patch preparation for every unchanged stroke. Radius, strength, softness, enable/erase, view, basis and sample changes invalidate the appropriate entry; changed surfaces reject reuse. Undo/removal and base-density changes preserve ordered paint/erase behavior.

This does **not** replace stroke storage with a final region. Field indexes still rebuild, raw stroke comparison has a cost, and live feedback includes other work. Prepared entries retain raw inputs for exact comparison, adding memory; aggregate memory admission and peak-memory qualification remain open. Entries share data directly, with no chain retaining every previous Field.

The paired CPU witness uses a 5,000-triangle plane with 300 existing strokes and one appended stroke. Five measured runs after warmup, alternating fresh/reuse order, gave median preparation **7.2561 ms fresh / 1.9192 ms reused**. Each reused run compiled one stroke, reused 300, and matched sampled fresh coverage exactly. This is field preparation timing, **not Max input latency, presented FPS or a vendor comparison**. [Reproducible source](../../tools/procedural_lab/brush_prepare_benchmark.cpp).

## Verification and delivery

Exact final test receipts, source/module identities and package identity are recorded in [EVIDENCE.json](EVIDENCE.json). The final scripted Max fixture is [Max_Consolidation_075.ms](../../tools/procedural_lab/Max_Consolidation_075.ms), combined with the existing layer/painting, shared-view, grip and older-scene fixtures. Owned private profiles are under `build/mcp-qualification/consolidation075-*`; no artist scene, normal profile or installed plugin was edited. No computer-use tools were used.

Passed: **14 native suites, 141 Python tests, 22 new Max checks, 45 layer/painting checks and 23 list grips**. Shared-view/container lifecycle and older single/multi-group regressions passed. The broader procedural acceptance campaign passed generation, background coverage, spacing, stable filtering, Undo/Redo, atomic error recovery, curved Brush and persistence. A frozen 0.74 Paint Areas scene reproduced its saved placement fingerprint. Native Brush tests passed 35,563 assertions.

The Max 2027 installer is [CyrusScatter-0.75.0-Max2027.mzp](../../dist/Consolidation_0.75_2026-10-09/Max2027/CyrusScatter-0.75.0-Max2027.mzp). Its script and four native modules match the final isolated host; [PACKAGE.json](PACKAGE.json) records hashes. The installer is built locally and ignored by Git; it has not been installed into the artist profile. [collect_evidence.py](collect_evidence.py) verifies retained source/build/host identities and gathers the receipts without launching Max.

The native suite additionally compares incremental fields to fresh ordered replay through append, strength/enable changes, Undo/removal, base-density changes, brush basis/view changes and receiver replacement. Generated control coverage remains 232; the calculation/display backends retain their existing contracts.

Intermediate fixture corrections are retained in private logs: the first model-list assertion used WinForms Visible in a hidden host, which includes parent-window visibility; the invalid-range witness initially edited inactive uniform settings while advanced axes were on; and Dropdown.selected is selected text, not a callable event. Corrected checks use model row retention/native disclosure state, an active invalid range, and the function dispatched by the dropdown handler. The version-pinned catalog test was updated to 0.75. These are not claims of product defects fixed by weakening assertions.

The additional procedural campaign required updating its historical version assertion and loading the performance JSON helpers before compiling the acceptance fixture. Its final run passed after those harness corrections.

## Still unfinished

- [ ] **Stable per-receiver generation and incremental placement calculations.** Adding/removing receivers can still relocate existing candidates. Candidate identity is also used by Brush, Edit, collision prefixes and saved overrides; changing only the sampler would be unsafe. This pass preserves generation rather than claiming that redesign is complete.
- [ ] **Canonical region storage and end-to-end Brush feedback timing.** Stroke storage and the feedback timer remain; preparation reuse is one measured improvement.
- [ ] **First cold container gesture losing Undo/Redo history.** The Manual-mode bug fixed here is a different issue. Scripted container lifecycle checks do not close the physical-gesture finding.
- [ ] Older multi-set population conversion, high-count Proxy drawing, aggregate Brush memory limits, physical UI/DPI/tablet/long-session acceptance, Max 2026 runtime and fresh renderer qualification.

The next calculation acceptance should cover 20→21 receivers, Density and Fixed Total, reorder/remove/restore, saved IDs, Brush membership, protected Edit/radius overrides, collision dependencies and per-stage reuse counters together. Do not treat this consolidation release as completion of all research priorities.

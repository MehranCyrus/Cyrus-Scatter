# Execution TODO and progress

Updated 15 October 2026. This is the checklist for the authorized eleven-phase
program. A checked box means the named task has evidence; it does not imply the
entire phase passed. Existing defect IDs stay in [BACKLOG](../../BACKLOG.md).

## Current action

**Active improvement program:** P06 is resumed by the [explicit goal](../improvement-program/OBJECTIVE.md).
I03 presets/browser/thumbnails passed scoped checks as [0.82.6.1](../improvement-program/I03_08261.md), with four initial examples; remaining deliveries
follow the dependency order and acceptance gates in the [execution ledger](../improvement-program/PROGRESS.md).
Later features are not complete. The active version policy replaces all provisional
future version assignments below; historical delivered labels remain unchanged.

**Preceding delivered checkpoint, 0.82.6 I01/I02:** lazy panels, retained controls/lists and bounded diagnostic stage timings/action correlation. See the [handoff, performance receipts and installer](../panel-performance-0826/PROGRESS.md).

Preceding delivery:

**0.82.5 complete static recipes**, including Paint, are implemented in the [recipe handoff](../recipes-0825/PROGRESS.md). This separate delivery implements the current P10 core; it does not resume P06 or complete future layout/map extensions, asset packaging, search or thumbnails. At that delivery P06-P09 planned 0.82.6-0.82.9, P10 follow-ups are unassigned and P11 provisionally remains 0.83.0. No normal-profile installation is included.

Preceding delivery: **0.82.4 mesh channel density and Paint help** are implemented and qualified in
Max 2027, including an isolated copy of the user's mountain. See
[MESH_MASK_0824](MESH_MASK_0824.md) for exact evidence, package and artist checks.
No normal-profile installation was included. At that delivery P06-P11
planned 0.82.5-0.83.0; the later recipe core supersedes that schedule. This is a separate delivery from the eleven phases.

Preceding delivery:

**Implemented and scoped Max 2027 checks passed: the authorized 0.82.3 performance correction**, tracked in
[PERFORMANCE_0823](PERFORMANCE_0823.md). This fixes the first five phases without
resuming P06. At that delivery, P06-P11 planned 0.82.4-0.82.9; the later mask
delivery supersedes that schedule.
The candidate passed 31 native suites, 161 Python tests, 467 inherited host
assertions, 440 heavy Point Cloud/Mesh assertions and 217 synthetic assertions.
Physical panel clicks/navigation preserved work counters. Full controller opening
still costs about two seconds in the terrace; B21 remains open. Normal installation
was last verified as 0.82.2. The subsequent user-requested 0.82.3 Max 2027 MZP
is packaged and hash-verified for manual installation; see the package section
in the performance handoff. No installation, push or deployment was performed.


**Historical checkpoint: paused after completed P05 (corrected label 0.82.2; original build 0.85.0), at the user's request for discussion.**
P01 through P05 were committed and pushed under their original labels; the latest verified implementation
checkpoint is `8985e040831813d02f61c863983fe1afc4b1f4b1`.
P06 has had preliminary source inspection only; implementation has not started.
Do not start another phase until the user resumes the program.
When resumed, use **Max 2027 only** for development and testing, as requested on
14 October 2026. Max 2026 testing requires a new explicit request; retain the
completed dual-version receipts. See [the agent workflow](../../AGENT_WORKFLOW.md).
The user's artist acceptance is at the end. Computer Use recovered during P05;
physical conversion controls passed in both Max versions. See [P05](P05.md).

The authorized numbering correction and fresh Max 2027 compilation are complete
(31 native suites, 161 Python tests and generated integration passed).
This metadata/build task does not resume P06. See the
[corrected phase versions](../../Release_Versioning.md#eleven-phase-numbering).
The authorized [0.82.2 Max 2027 installer and disk installation](INSTALLATION_0822.md)
are complete. The running older host needs a restart; the user will perform
[manual acceptance for Phases 1–5](ARTIST_ACCEPTANCE_0822.md). P06 remains paused.

## Enrollment / shared preparation

- [x] Read current README, workflow, version policy and latest linked viewport handoffs.
- [x] Recheck branch/HEAD, tracked changes and untracked source/report scope.
- [x] Check knowledge status and relevant search; stale evidence rejected; use direct source.
- [x] Reconcile all eleven scopes with current capabilities, including existing adaptive preview.
- [x] Record implementation scopes, dependencies, tests, performance and completion rules.
- [x] Check public vendor research/API routes and GitHub availability; no verified proprietary engine source found in the initial search.
- [x] Capture baseline identities/backups and tracked diff under `build/eleven-phases-20261014-01`; inspect P01 source paths. Full Git prerequisite review remains below.
- [x] Establish coherent Git prerequisite scope for 0.81.7 without including unrelated assets/knowledge/site work; see P01 and its delivery inventory.
- [x] Confirm current toolchain/owned-host paths and baseline checks needed for P01.

## P01 — workflow and feedback (0.81.8)

- [x] Inspect actual template, approved layout mapping and cached-status readers.
- [x] Freeze displayed-state/count semantics and phase acceptance cases.
- [x] Correct active feedback and retired ownership terminology.
- [x] Distinguish accepted placements, cached preview samples and pending settings.
- [x] Exercise real UI refresh/owner switching without solves, preparation or uploads.
- [x] Measure editor/status cold and warm costs; fix only demonstrated unnecessary work.
- [x] Regenerate and validate inventories/catalog where affected.
- [x] Run focused host/state/Manual/Live/failure/Undo/reopen checks and relevant regressions.
- [x] Record unavailable physical/visual checks for final artist acceptance, as explicitly directed by the user on 14 October; no visual pass is claimed.
- [x] Select/record final version, update docs and review final diff; recheck identities before delivery.
- [x] Commit coherent P01/prerequisite source; push and verify remote hash.

## P02 — settings and curve presets (0.81.9)

Preparatory [source/format research](P02_PREFLIGHT.md) is recorded. Implementation and scoped Max qualification passed; see the phase receipt.

- [x] Freeze allowed setting categories, typed format and application semantics.
- [x] Implement validated capture/atomic persistence and curve round trips.
- [x] Implement one-Undo apply with proper owner and Manual/Live invalidation.
- [x] Add a compact preset list and clear storage/error feedback.
- [x] Test units, missing/corrupt/oversized/unwritable files and unchanged browsing.
- [x] Validate host lifecycle and inherited P01 behavior.
- [x] Commit/push qualified P02 under its original 0.82.0 label and verify the remote hash; corrected phase label is 0.81.9.

## P03 — slope and altitude (0.82.0)

- [x] Freeze coordinates, normal/up convention, endpoint and soft-transition functions.
- [x] Implement settings, independent eligibility channel and receiver dependencies.
- [x] Integrate at the correct candidate/Edit/acceptance stages.
- [x] Add controls, explanatory feedback and bounded rejection diagnostics.
- [x] Test analytic slopes/heights, transforms/units, Paint/Bands/maps/refill/protected edits.
- [x] Measure disabled overhead and cold/warm reuse; run host lifecycle/regressions.
- [x] Update version/docs; commit, push and verify.

## P04 — map controls (0.82.1)

- [x] Verify SDK UV-channel ranges and freeze addressing/interpolation/color semantics.
- [x] Add saved UV-channel and 64/128/256/512 resolution choices with current defaults.
- [x] Update native receiver transport, bake dimensions and keyed map/UV caches.
- [x] Add precise missing/invalid-channel errors with previous-result retention.
- [x] Test multiple channels, resolutions, animated maps, invalid geometry and Manual/Live.
- [x] Measure map bake/receiver cache reuse and peak memory; run regressions.
- [x] Update version/docs; commit, push and verify.

## P05 — Paint/spline conversion (0.82.2)

- [x] Freeze contour fill/nesting, sampling tolerance and projection rules.
- [x] Implement non-destructive vector-to-spline snapshot export with holes/transforms.
- [x] Implement validated Replace/Add spline import into an explicit Paint Area.
- [x] Integrate one-Undo ownership, Manual/Live and bounded geometry handling.
- [x] Test coverage equivalence, self-intersections, transforms/units, failures and persistence.
- [x] Qualify actual conversion controls and unchanged other layers.
- [x] Update version/docs; commit, push and verify.

## P06 — grid layouts (I06 / 0.85.0)

- [x] Freeze lattice frame/origin, spacing, stagger/hex rules and projected-hit policy.
- [x] Prove bounded collision-free stable cell identities in the chosen transport.
- [x] Implement cell enumeration and independent deterministic jitter.
- [x] Integrate shared eligibility/source/transform/spacing/Edit publication.
- [x] Add mode-specific controls and unambiguous Count/Density interaction.
- [x] Test analytic positions/counts, boundary edits, identity stability and all masks/filters.
- [x] Measure bounded large-grid preparation/cache reuse; run host lifecycle/regressions.
- [ ] Update version/docs; commit, push and verify. — docs and package complete; Git checkpoint pending.

## P07 — direction controls (delivered as I04 / 0.83.0)

- [x] Freeze direction/target/up/roll and random-rotation composition semantics.
- [x] Implement fixed direction and Look At, including degenerate cases.
- [x] Include final basis in bounds/radii before acceptance.
- [x] Add relevant target animation/deletion dependencies and UI.
- [x] Test known axes, transformed sources, collisions, Manual/Live and persistence.
- [x] Measure unrelated-animation reuse; run regressions.
- [x] Update version/docs; commit, push and verify. — 0.83.0, implementation `a814513`, package and remote hash verified.

## P08 — paths, sequences and references (0.82.8)

- [ ] Freeze spacing/endpoints/seams/jitter, 3D versus receiver projection and identity rules.
- [ ] Implement bounded arc-length path sampling and P07 tangent orientation.
- [ ] Implement persistent source-row sequences; rejected stations retain sequence positions.
- [ ] Implement reference-pivot placement and explicit model assignment.
- [ ] Integrate existing constraints/Edit/cache/Manual/Live behavior and UI.
- [ ] Compare against an independent path oracle; test corners, seams, deletion and animation.
- [ ] Measure long-path preparation and reuse; run lifecycle and earlier layout regressions.
- [ ] Update version/docs; commit, push and verify.

## P09 — transform and assignment maps (0.82.9)

- [ ] Freeze each map's remap/composition/neutral/missing-input behavior.
- [ ] Implement sampled scale/rotation channels using P04's shared preparation.
- [ ] Implement deterministic color/source assignment and explicit assignment-mode precedence.
- [ ] Recompute final bounds before spacing; preserve independent random channels.
- [ ] Test analytic colors/ramps/ties, source roles, invalid maps and layout combinations.
- [ ] Measure shared-map reuse, animation dependencies and memory; run host/regressions.
- [ ] Update version/docs; commit, push and verify.

## P10 — recipes and browser (0.82.5 core; follow-up TBD)

- [x] Freeze the current static recipe core and explicit source/receiver/path/map role binding in 0.82.5. Future P06-P09 fields require a reviewed successor.
- [x] Implement bounded single/multi-layer static capture, including native Paint and dormant settings, with no runtime caches or executable data. Unsupported authored data blocks complete save.
- [x] Implement explicit role substitution, new identity mapping and transactional Add/new setup for the current static core. Compatible Paint binding is mandatory; orphan coverage remains unbound.
- [ ] Add search, thumbnails and distributable demo recipes. 0.82.5 supplies a local 128-entry page and 512-entry metadata cache; no idle polling.
- [ ] Test missing assets, duplicate names, units, internal references, cancellation and storage failures.
- [ ] Qualify full production recipe save/apply/Undo/reopen and passive browser performance.
- [ ] Update version/docs; commit, push and verify.

## P11 — adaptive viewport completion (0.83.0)

- [x] Identify existing 0.81.6/0.81.7 adaptive limits, fallback and mode-cache implementation.
- [ ] Recheck original failure witnesses against the final P10 source.
- [ ] Benchmark all new layouts/maps/recipes with simple and heavy supported sources.
- [ ] Improve the measured bottleneck and preview-status clarity within the chosen scope.
- [ ] Qualify idle/navigation, zero limits, repeated mode switches and bounded resource recovery.
- [ ] Run supported asset fixtures and the production terrace in Max 2027 only.
- [ ] Record physical/presented-frame evidence or explicit measurement limitations.
- [ ] Run the complete required eleven-phase interaction/lifecycle/output regression matrix.
- [ ] Update version/docs; commit, push and verify final program checkpoint.

## Decisions and evidence log

### 14 October 2026 — program enrollment

- Source baseline is 0.81.7, not the 0.81.5 source used for the preceding comparison.
- P01 is a bounded UX/status correction; provisional next patch 0.81.8. No product
  version was changed by creating these planning documents.
- P11 retains and validates the existing viewport work. It does not authorize a
  geometry-LOD, GPU-compute or new async-solver project.
- Current source references include `uiLayerStats`, `CyrusUILayerState`,
  `selected_detailsUI`, `selected_workflowUI`, approved-layout `helpOnly`,
  `meshOf` UV reading, density `renderMap`, `viewport_policy.h` and current
  viewport qualification tools. Historical observations retain their scope.
- All eleven phase-completion boxes remain open. There is no phase commit/push,
  new benchmark, host acceptance or installed build from this enrollment step.
- P01 source audit found that `selected_detailsUI` identifies the selected
  population through `leaf.paintSetName` (normally the internal Base name), while
  `root.layerCaption leaf` is the current layer-facing name. It labels
  `cachedPointCount` as Shown even though this is prepared preview data, not a
  measurement of the active navigating/idle draw quota. The cached status helper
  uses Preview error for failures without explaining retained-result state.
  These are implementation findings to qualify through the actual generated UI.
- The retained old workflow paragraphs are hidden by `approved-layout-rows.cjs`
  `helpOnly`; do not claim they are currently visible or use a hidden-text edit
  alone as evidence that P01's artist outcome is complete.
- Planning validation passed: four documents, twelve relative links resolved,
  exactly eleven specification/checklist sections and 84 open actionable tasks.
  Receipt: `build/eleven-phases-20261014-01/plan-validation.json`.
  Scoped `git diff --check` passed. The documentation index and backlog link this
  program. No plugin source, product version or normal profile changed during
  plan creation; these documentation checks do not qualify implementation.

For each subsequent entry record the exact change, evidence/receipt, failures,
version decision, commit/remote hash and next action. Keep detailed raw outputs
in the owned ignored run directory; link only evidence that actually exists.

Current successor: [I06/P06 0.85.0 grids](../improvement-program/I06_0850.md), following [I05 variation](../improvement-program/I05_0840.md) and [I04/P07 direction](../improvement-program/I04_0830.md). Six examples are scoped-qualified. I07/P08 paths is next; B26 and the remaining program/EXE stay open. Historical version proposals do not select future delivery numbers.

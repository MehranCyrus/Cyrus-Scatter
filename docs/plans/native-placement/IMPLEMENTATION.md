# Implementation sequence and TODO

The user activated implementation on 17 October 2026. The reviewed 0.85.4 implementation is checkpointed at `7379ea3`; [fresh regression evidence](BASELINE_0854_20261017.md) is recorded. N01–N09 remain open until their individual acceptance is proven. The first coherent qualified delivery is planned as 0.86.0; internal prototypes are not user deliveries. See [design](DESIGN.md) and [acceptance matrix](VALIDATION.md).

Each step must record source/native/script identities, actual checks, memory/timing changes and unresolved failures before proceeding. A private partial build is not a user delivery. Use Max 2027 only; preserve artist sessions, scenes, existing changes and independent product versions. Do not install/restart the artist session.

## N01 — Establish a comparable baseline (low–medium)

Dependencies: implementation authorization.

- [x] Freeze the 0.85.4 qualified pair and repeat the 5k/50k/200k, cold-copy, grid, Paint and ready-preset witnesses in an owned run; keep old artifacts immutable. [Baseline receipt](BASELINE_0854_20261017.md); implementation checkpoint `7379ea3` pushed.
- [x] Audit every production row consumer, including Brush, Edit, field/radius previews, PFlow, Bake, MCP and diagnostics. Identify hidden bulk serialization, hashing and array loops. [Consumer inventory](SOURCE_MAP.md).
- [ ] Add bounded opt-in stage allocation/ownership counters: logical size/capacity, unique live bytes, peak live bytes, allocation counts, wrapper/row materialization, history pins and peak coexistence. Keep default hot-path overhead measured and small.
- [ ] Establish full ordered semantic fingerprints (all eight current fields, radii, source/receiver mapping, accepted order and statistics), not only positions or viewport images.
- [ ] Measure ordinary Count Undo, Manual copy, ready-preset Undo and CS Edit history separately. Determine when native restores are created, sealed and destroyed.
- [x] Qualify Max hold ordering, repeated Restore/Redo and Size accounting with small disposable probes before redesigning history ownership. [Private Max 2027 probe](N03_N04_QUALIFICATION.json); production history redesign remains N05/N07.

Performance target: expose actual dominant costs without changing output or adding placement work to passive UI. Existing historical time ranges are context, not a fresh A/B baseline. Tests: V01–V03, V08–V10. Exit: reproducible baseline, named consumer inventory and an agreed measured byte model.

Partial execution: [ten warm repetitions per Count/terrain and 120-second idle](N01_BASELINE.json)
passed. Explicit reachability distinguishes shared values from actual requested
array capacity. Private hold/Size probes now pass; full stage/scratch/peak/history
ownership remains open. These measurements support the isolated N02 type prototype;
they do not close N01 or replace integrated before/after peak accounting.

## N02 — Native data and lifetime foundation (medium)

Dependencies: N01.

- [x] Implement typed immutable placement generation and builder in the existing native project; specify compact field layout and old rounding boundaries. 96-byte records; [implementation/evidence](EXECUTION_0860.md).
- [x] Implement numeric/tagged identity with bounded authored-key storage and exact external string round-trip. Pure and actual Max round-trip tests pass within the declared current key format.
- [x] Add native views/indices, bounded readback and source-use summaries, without implicit bulk Array conversion.
- [x] Add full native semantic fingerprint queries, including metadata/radii at integration boundaries. Native/legacy ordered semantic parity passes; supplied metadata is caller-owned, not yet bound automatically to an immutable publication epoch.
- [x] Establish GC wrapper ownership, native retention and a guarded cross-module Brush POD read lease. Real Max GC/release and Brush reads pass; write-stage adaptation is N03 work.
- [ ] Qualify controller scene/owner retirement and current publication-token routing; generic retained numeric snapshots alone do not establish it.
- [ ] Account for capacities, shared storage and index buffers; reject invalid/overflowing requests before mutation.
- [x] Add allocation-failure seams in a separate test executable; no product fault switch or replacement heap is linked into Max modules. Pure store construction/selection/successor failures and retry pass.

Likely files: `include/script_buffers.h`, `src/script_buffers.cpp`, new narrowly scoped placement headers/sources, `CMakeLists.txt`, `placement_transport.h` boundary adapter. Do not move registration/class IDs.

Performance target: native storage has no per-placement MAXScript object, no string for generated candidates, and no duplicate store per DLL. Tests: ownership/GC, immutable alias rejection, stale/wrong handle, malformed fields, numerical boundaries, module startup/shutdown, V04/V10/V11. Exit: proven native value usable from the real Max host without changing the active pipeline yet.

## N03 — Generation and preparation (medium–high)

Dependencies: N02. Integration acceptance also requires N04/N05.

- [x] Implement the direct Surface random native producer at existing precision boundaries. [Internal adapter parity](N03_N04_QUALIFICATION.json); main controller integration is still pending.
- [x] Feed rectangular/staggered/hexagonal projected grid generation into native records without changing cell identities, holes or admission counts. Direct-adapter parity passes; production routing remains pending.
- [ ] Replace receiver row joins/face-offset copies with native segments or explicit mapping; preserve receiver cache reuse.
- [ ] Adapt mesh masks, Analyzer Areas, boundary falloff and optional Relax to native views/builders in their exact order.
- [ ] Adapt Brush region eligibility/scale through the cross-module contract; preserve canonical Paint bytes, area union, binding and source independence.
- [ ] Adapt orientation, source filtering/scales/offsets and the special Analyzer orientation path. Avoid mutation of shared pre-transform caches.
- [ ] Initially adapt active Edit through a clearly measured temporary comparison boundary if needed; N07 removes its bulk row route. Do not label this intermediate path fully native.
- [ ] Adapt the existing surface filter to native inputs without changing its slope/altitude math, validation, authored controls or protected behavior.

Likely files: `max_bridge.cpp`, receiver/grid/mask/falloff/orientation adapters, `brush_host.cpp`, `unified-core.ms`. Tests: stage-by-stage parity for V02/V03/V05/V06 and failure release. Performance target: generation/preparation no longer expands to script arrays on migrated paths; unchanged receiver data remains shared. Exit: each optional feature has a parity witness and allocation counters; failed successors leave cached inputs/publication intact.

## N04 — Native acceptance (medium–high)

Dependencies: N03 simple path; expand alongside optional preparation adapters.

- [x] Implement numeric generated schedule lookup and sample identity in the native adapter, retaining exact ordinal order and authored-copy text. The comparison/production legacy route remains until N05–N09 integration and removal.
- [ ] Feed compact position/radius views into the existing solver; reduce redundant `Sample`/ID copies without changing its rules.
- [x] Keep radius overrides and Float32 rounding identical in the native adapter; source Auto bounds validate all admitted sources. Direct stage parity and rejection tests pass.
- [x] Return ordered native accepted selections/radii and bounded per-layer statistics without script placement lists. Full output parity passes; selection retention policy remains below.
- [x] Preserve independent collision scopes, protected reservations, target/refill rounds, cleanup visits and shortfall in the native adapter. [Plane/mountain and pure numerical witnesses](N03_N04_QUALIFICATION.json); production integration remains open.
- [ ] Choose bounded index-view versus accepted compaction policy from retained-byte measurements; do not pin enormous rejected pools unnecessarily.

Likely files: `procedural_bridge.inc`, `include/procedural.h`, `src/procedural.cpp`, receiver schedule adapter. Performance target: no full input/result script population; reduced schedule string/hash allocation; unchanged numeric winner order. Tests: V03/V06/V11, serial/parallel equality, near-limit rejected/refill scenes. Exit: full accepted output/radii/stats equal baseline, including protected zero-quota and work-limit cases.

## N05 — Publication, display and existing history (high)

Dependencies: N02–N04; active Edit may remain temporarily bridged until N07.

- [ ] Package root accepted data, source correspondence, metadata and statistics into immutable publication ownership; keep small UI summaries. The internal Surface-random route and immutable data container are implemented; the [execution handoff](EXECUTION_0860.md) distinguishes its scoped Max evidence from remaining optional/preset/render integration.
- [ ] Finish preview adapters: Point/Mesh/proxy/centres and bounded source-use output now consume native input with [actual Max parity/retained lifetime evidence](N05_PREVIEW_QUALIFICATION.json). Radius-ring preparation and production routing remain open; source-use work is cached at preparation/publication, never passive UI.
- [ ] Stage all owners and Edit visibility before installation; preserve the existing rollback boundary and post-commit observer distinction.
- [ ] Adapt ordinary Count/parameter Undo refresh without adding full snapshots for every scalar edit. Preserve Manual pending behavior.
- [ ] Replace preset publication's large field-list retention with coherent native references where appropriate, preserving its authored hold and ready Load Undo/Redo.
- [ ] Preserve abandoned Redo, imported setup lifetime, deletion/restoration and scene-reset release. No dangling native handle in a retained MAXWrapper.

Likely files: `unified-core.ms`, `preview.cpp`, `geometry_preview.inc`, `point_publication.inc`, `recipes_bridge.cpp`, `preset-loading.ms` as needed for history capture only. Performance target: no placement-scaled script allocation during Update/preview; unchanged displays reuse buffers; ordinary Count history does not grow by full snapshots per edit. Tests: V07–V12, all eight presets, 60k→90k copy. Exit: coherent simple and optional-feature pipeline through viewport with correct history. The active objective requires full N01–N09 acceptance before the first coherent native-foundation delivery, 0.86.0; isolated adapters and the internal simple route are checkpoints, not user releases.

## N06 — Inspection, rendering and Bake (high)

Dependencies: N05.

- [ ] Keep publication manifest and 500-row paging contract stable; readback must be cached, detached and epoch-bound.
- [ ] Move full fingerprinting/source grouping into native code so tests/diagnostics do not distort the production memory measurement.
- [ ] Replace persistent `CyrusPFData` transform arrays with publication-owned native groups; first prove bounded accessor behavior in the actual PFlow Script Operator.
- [ ] Qualify a native particle channel-fill route only if SDK inspection and measurements justify it. If unsupported, retain bounded access with explicit dispatch cost; do not retain full script arrays.
- [ ] Pin the same publication across render callbacks and release it correctly on render end/cancel, IR transitions, save/reset/shutdown and source deletion.
- [ ] Make Bake iterate native data or bounded pages in one authored host operation; preserve exact transforms, node ownership and failure cleanup.

Performance target: no second persistent per-placement script transform store for rendering. Bake memory is measured separately from its unavoidable real scene nodes/host Undo. Tests: V12–V14 plus source frame/scale/material/Point/Empty/proxy parity, cancellation and page invalidation. Exit: every supported consumer uses native data or bounded explicit readback. Renderer families without actual qualification stay listed as unqualified.

## N07 — Compact CS Edit and its Undo (very high)

Dependencies: N01 hold study and N02–N05 stable generation ownership. N06 can be developed separately but host mutations must be serialized.

- [ ] Separate authored edits/selection from derived matrices, source lists and published visibility IDs.
- [ ] Replace full `ProceduralEditTransaction` map copies with staged derived successors and rollback references.
- [ ] Replace `EditRestore` full-map history with small operation deltas or changed immutable blocks; large selection uses a compact representation.
- [ ] Avoid allocating an ordinary identity Edit record for every candidate unless required to preserve ordering/dormancy; prove any sparse representation against the old behavior.
- [ ] Preserve native Save/Load field contract initially. If sparse persistence cannot preserve current semantics, stop that substep and record a format proposal rather than inventing a migration path.
- [ ] Cover mixed parameter/Edit/Paint/preset history, repeated Restore/Redo, cancel, clone, delete, reset, lower/re-raise Count, missing receiver and abandoned Redo.
- [ ] Implement/qualify realistic restore-size attribution and unique retained-byte counters; do not clear host history or conceal costs with a constant Size.

Likely files: `cyrus_edit.cpp`, `cyrus_edit_stack.inc`, `cyrus_edit_storage.inc` only if justified, native publication owner. Performance target: moving/selecting a few instances must not copy all population transforms into each history record. Large authored edits still cost proportional memory. Tests: V08–V11 and dedicated 1/100/10k/all-selection history curves. Exit: no bulk script Edit transport and no unexplained population-scaled copies for sparse commands; exact semantics persist.

## N08 — Admission, cache retention and responsiveness (high)

Dependencies: N03–N07 measured final routes.

- [ ] Replace the placement-scaled MAXScript workspace estimate only after instrumentation proves all hot consumers are native/bounded. Keep justified script overhead protection.
- [ ] Account for old/new results, pinned Undo, source/receiver geometry, solver scratch, retained preview and graphics staging separately. Check growth overflow and system commit headroom.
- [ ] Evict reconstructible unpinned caches before rejection; bound scratch reuse and release abandoned generations. Do not evict required Undo/publication.
- [ ] Consolidate redundant evaluated receiver snapshots only after same-frame channel/geometry and animation tests prove fresh reuse; this is optional measured optimization, not a prerequisite rewrite.
- [ ] Verify held-interaction coalescing and latest-value publication. Passive UI never scans all placements or grows memory.
- [ ] Recheck cancellation/progress feasibility only at safe stage boundaries. If synchronous blocking remains material, document the separate scheduling gap; do not silently add asynchronous solving.

Performance target: meaningful measured peak reduction against N01, bounded post-Undo/Redo resource ownership, no UI regression. Existing work caps remain. Tests: V09–V11/V15, injected budget failure and sustained sessions. Exit: defensible byte-based admission and honest latency/memory claims, with every retained allocation attributed.

## N09 — Final acceptance and delivery (high validation effort)

Dependencies: all preceding required routes; optional renderer API optimization may remain explicitly excluded only if its bounded replacement is qualified.

- [ ] Run the complete validation matrix on one frozen source/script/native pair in private Max 2027 profiles, including normal and fault builds separately.
- [ ] Reconcile every current row consumer; no production hot path calls an unbounded legacy array adapter. Remove temporary duplicate engine/comparison routes from shipping builds.
- [ ] Document numerical parity, memory reduction, latency distributions, history behavior, failure recovery and unqualified boundaries; update B26 by actual evidence, not by completion of code.
- [ ] Select and record the release version before changing metadata; keep independent versions separate. Do not rename old receipts.
- [ ] Generate authoritative UI output, run focused/full appropriate native/Python checks, compile a final matching pair and qualify exact loaded hashes.
- [ ] Build Max 2027 MZP and EXE from that pair, verify archive/payload/version/host guards and EXE embedded payload. Supply install/test instructions; do not install.
- [ ] Update maintained architecture/artist docs and website sources only for proven behavior, and report any local website build separately from deployment.
- [ ] Commit/push only if separately authorized at delivery. Keep ignored scenes/binaries/installers backed up by their explicit artifact paths.

Exit: user can test the packaged version, documented limits are accurate, and no later roadmap phase has started. Phase 6 remains paused unless the user explicitly resumes it.

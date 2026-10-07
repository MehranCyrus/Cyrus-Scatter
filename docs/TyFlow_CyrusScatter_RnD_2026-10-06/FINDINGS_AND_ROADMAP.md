# Findings, useful improvements and the next implementation loops

**7 October continuation:** [approved UI, real scenes, exact evidence and remaining limits](../Full_Qualification_0.73_2026-10-07/RESULTS.md). The latest report supersedes older UI/runtime qualification claims; dated implementation and R&D evidence below remains historical. No artist installation or Git operations are part of this campaign.

6 October 2026. Review/documentation only. P0 = critical, P1 = major, P2 = bounded correctness/performance concern, P3 = optional improvement. Qualification gaps are labeled separately rather than invented as reproduced defects.

No new P0/P1 was verified in the 0.72 implementation diff. CR1 is the one changed-code P2; the findings below mainly concern the existing architecture. The earlier popup-owner P1 is fixed by 0.72. Nothing in this report warrants discarding the working placement/display foundation.

## Findings by severity and evidence

| ID | Priority / type | Result | Evidence |
| --- | --- | --- | --- |
| F1 | P2, existing CPU scaling | Projected movement/anchors scan all eligible receiver triangles per candidate. | Current source and reproduced E2. |
| F2 | P2, existing CPU scaling | A single very large radius can collapse grid selectivity and exhaust the bounded work limit despite no actual overlaps. | Current source, independent result oracle and reproduced E1. |
| F3 | P2, existing resource/preparation | Brush per-stroke/storage limits do not bound aggregate derived field links; wide histories have substantial preparation and memory costs. | Current source and reproduced E3; large-limit OOM was not attempted. |
| CR1 | P2, newly introduced failure path | Report cleanup can replace the primary export error and skip remaining cleanup. | Source + official .NET failure contract; no fresh Max failure reproduction. |
| F4 / BR-01 | Existing persistence gate | Tiny-coordinate Brush save/reopen can reject retained paint. Root cause remains unisolated. | Audited earlier real-scene result and current raw-byte fingerprint/guard. |
| F5 | P3, existing draw limitation | Proxy caches CPU triangles but resubmits them on redraw. | Source fact; no new matched high-count draw timing. |
| F6 | P2 documentation drift, partly corrected here | Active docs lagged the UI/tool/runtime state; product catalog help still has old renderer/learning descriptions. | Current source/catalog/document comparison. Docs corrected; product JSON deliberately unchanged. |
| Q1 | Qualification gate | Artist-visible 0.72 UI, presented FPS, complete renderer/host/long-session coverage are missing. | Absence in matching receipts, explicitly distinguished from failures. |
| R1 | P3, measured proposal | Better phase/cause summaries, peak-memory accounting and typed extensions would improve diagnosis. | Source review and vendor measurement models; not implementations. |

### F1 â€” Accelerate the specific exhaustive projection path

Location: [scatter.cpp:339](../../AminScatter/src/scatter.cpp#L339), [scatter.cpp:360](../../AminScatter/src/scatter.cpp#L360). These are nearest-surface loops for anchors/moved candidates. [scatter.h:40](../../AminScatter/include/scatter.h#L40) describes reference-core projection and suggests host acceleration, but the product bridge still calls this core path.

Impact: work grows with candidate count multiplied by eligible receiver triangles, before later collision budgets. E2's 1,000-candidate/20,000-triangle case measured 146.985 ms with projection versus 1.028 ms without, median of three runs. This CPU measurement is not animation FPS or proof that this option was active in the artist scene.

Reproduce: run [the neutral probe](reproduce/run_core_probe.py) into a new ignored output directory; E2 varies only receiver subdivisions and projection. [Full receipt](evidence/core-probe.json).

Smallest fix proposal: adapt the existing [nearest-surface tree](../../AminScatter/src/spacing.inc#L34) into a reusable numeric query over eligible faces, build/cache it once for a relevant geometry revision, and retain the exhaustive path as the equivalence oracle. Do not replace closest-point projection with ray casting.

Acceptance: equal candidate IDs, transforms, receiver/face/barycentric anchors, normals and sampled UV/density/Area behavior on planar/curved/disconnected and degenerate eligible meshes. Exact equal-distance ties must preserve the existing first-eligible-face rule: tree traversal/hints can otherwise change face choice and downstream data even when projected positions agree. Include mirrored/nonuniform transforms, movement disabled/on, source lift/scale, Edit and relevant invalidation. Repeat the scaling fixture, measure extraction/build/query separately, and verify repeated unchanged draws do not rebuild the tree.

### F2 â€” Isolate radius outliers without changing collision semantics

Location: [group_spacing.cpp:89](../../AminScatter/src/group_spacing.cpp#L89) and [100](../../AminScatter/src/group_spacing.cpp#L100). The self and external grid widths depend on global maximum radii, while every hit performs exact pair checks.

Impact: correctness can remain valid while the broad phase becomes nearly all-pairs. E1 changes one far-away radius from 0.5 to 1e9. At 10,000 points, neighbor visits rise from zero to 49,985,001; at 12,000 it explicitly fails at 50 million. All below-cap points are accepted; the far outlier overlaps none. This is an intentionally extreme workload demonstrating a structural bound, not a diagnosis of ordinary artist radii.

The [work-limit check](../../AminScatter/src/group_spacing.cpp#L106) is correct protection and should remain. The independent 503-case all-pairs oracle agrees with accepted indices, protection/conflicts and rejection scope in tested domains.

Smallest fix proposal: prototype an exceptional-radius side bucket or a few deterministic radius bands. Keep candidate consumption/order, protected reservations, layer-before-set-before-self reasons, XY/3D and strict contact boundaries identical. Count broad-phase allocation/build costs too; a more elaborate tree is not automatically better.

Acceptance: unchanged independent oracle results, tangency/zero-factor cases and deterministic refill/cleanup outcomes. A far radius outlier must no longer cause quadratic scans over the unrelated small-radius population. Genuine dense-overlap cases may still have high work and must fail cleanly at an explicit bound. Preserve the previous complete Max publication on a failed successor.

### F3 â€” Bound Brush derived state before allocating it

Location: [brush.cpp:109](../../AminScatter/src/brush.cpp#L109), [170](../../AminScatter/src/brush.cpp#L170), especially lines 175â€“176. Each enabled derived dab stores patch faces and face links; patch construction allocates a full-face visited vector. Disabled histories are resampled before the enabled check.

Impact: long/wide histories can multiply faceÃ—dab work and memory despite bounded serialized documents and per-stroke resampling. E3's 8,192-face/256-dab full-plane case takes 265.964 ms to build a Field and needs at least 24 MiB of patch/link payload; the radius-2 case takes 0.983 ms. This excludes Surface construction, vectors/capacities, retained documents, allocator overhead, SDK memory and old/new overlap.

No extreme-limit OOM/crash was induced. The finding is the missing checked aggregate derived-link/byte budget plus measured preparation cost, not an observed crash. Query caching does not make field construction free.

Smallest fix proposal: admit checked aggregate derived samples/patch links/bytes and return an actionable bounded failure before publishing a new field. Keep authored histories and the previous complete field/result. Reuse a generation-stamped visited scratch buffer where it preserves semantics; avoid disabled-history preparation only after proving the replay/reset/edit behavior. Incremental append fields are a later profile-driven option.

Acceptance: limits just below/at/above the cap, overflow arithmetic, path resampling versus stored dabs, disabled/re-enabled strokes, radius changes, Fill/Empty, curved/disconnected surfaces, captured views, Undo/reopen and failure rollback. Keep indexed influence equal to reference replay, and measure Field preparation, query cost and peak memory separately.

### CR1 â€” Small failure-reporting correction

See [the focused review](CODE_REVIEW.md#cr1--preserve-the-original-export-failure-through-cleanup) for [diagnostics-ui.ms:78](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/diagnostics-ui.ms#L78). Preserve the original export error and make cleanup best-effort; test actual write/flush/close/delete/replacement failure variants. Atomic destination preservation already has a useful design.

### F4 â€” Finish Brush save/reopen identity diagnosis

Locations: raw vertex bytes enter the fingerprint at [brush.cpp:78](../../AminScatter/src/brush.cpp#L78); retained strokes are denied on a new fingerprint at [brush_host.cpp:133](../../AminScatter/src/brush_host.cpp#L133); Save/Load at [294](../../AminScatter/src/brush_host.cpp#L294).

Historical reproduction: [real-scene findings, BR-01](../Real_Scene_0.7.1_2026-10-05/FINDINGS.md#p3--very-small-generated-coordinates-expose-a-brush-savereopen-boundary). Painting/replay passed before save, but reopening the tiny-Z terrain rejected retained paint. A scene-only normalization of coordinates below 0.001 cm to zero made that fixture pass. The earlier report called this P3; it remains a persistence qualification gate here. The precise signed-zero/subnormal/conversion/geometry cause is **not** established.

Smallest next step: isolate deterministic ordinary/tiny/signed-zero/subnormal/transformed fixtures, record indexed geometry bytes before/after Save/Load, and identify the first actual change. Decide whether a documented canonical geometry fingerprint can preserve semantic equality while still detecting real changes. Do not disable the guard or globally round all geometry just to make a test green.

Acceptance: equivalent supported save/reopen geometries retain paint and IDs; genuine topology/position changes still fail with preserved histories. Migration keeps class IDs/documents and Undo behavior; the chosen tolerance/canonicalization, if any, has explicit units and tradeoffs.

### F5 â€” Profile Proxy as drawing, not generation

Location: [preview.cpp:153](../../AminScatter/src/preview.cpp#L153), per-triangle submission through line 193; cached batch preparation in [preview_batches.inc](../../AminScatter/src/preview_batches.inc).

The cached world triangles avoid rebuilding placements, but GraphicsWindow submission remains per redraw. Existing retained Mesh/Point paths already avoid this category of repeated immediate work. This source fact can explain an architectural cost, not its magnitude in the artist session.

Smallest proposal after a matched profile: a bounded native retained Proxy representation over the existing publication/cache interface, or a simpler cheaper representation. Do not increase output merely because the draw path changes. Preserve source/color/material semantics, culling bounds, fallback, selection/hit behavior and retained lifecycle.

Acceptance: identical workload/camera/source complexity and visible budget, unchanged placement generations/uploads during navigation, lower measured CPU draw cost and independently reported presented frames. Test resources/culling/device recovery; do not claim zero draw cost.

### F6 â€” Documentation and generated help have different delivery boundaries

The active capability matrix, navigation and MCP README had stale 0.7.1/241-control/ten-tool and unqualified-IR descriptions. This review updates those documents for the actual 0.72/245-control/twelve-tool state. Historical reports receive dated scope notes rather than rewritten results.

The product [feature-catalog.json:199](../../CyrusMCP/cyrus_mcp/feature-catalog.json#L199) still embeds an older C28 renderer-help row and the prior documentation-source hash at line 4. [C34 at line 241](../../CyrusMCP/cyrus_mcp/feature-catalog.json#L241) also omits the implemented offline experimental ranker. Regenerating that artifact changes product behavior/data, so it is deliberately deferred in this review. The next coding loop must update/verify the generator output, not hand-edit the JSON or claim this review delivered new MCP help.

Acceptance: generated control count/location/permissions match source; C28 describes the narrowed qualified floating-IR slice plus remaining gates; C07 cached membership and C31/C32 actual passive reader boundaries remain correct. Keep plans 1/2 closed, policy 3 read-only and historical receipts immutable.

## Important missing scenarios

These are open qualification targets, not newly reproduced bugs:

- Real 0.72 expand/collapse, scroll/wheel/drag, tooltip placement, narrow/wide columns, 100/125/150/200% DPI and monitor transitions. The original UI test's hidden page/order defects do not qualify today's final implementation.
- Unrelated animation versus source/receiver/map animation, selected/unselected owner, optional popup states and mixed display modes, with phase timing plus presented FPS. Settled unchanged-input counters are necessary but insufficient.
- Successful docked IR, repeated floating/docked render/save/reopen/reset, interrupted renderer operations, long mixed sessions and other intended renderers. Preserve renderer-owned data on Stop failure.
- Max 2026 actual runtime, install/restart and load/recovery, beyond SDK/native tests. Intended host versions and module identities must be explicit.
- Device/resource loss/fallback, many source/material groups, large receiver geometry, extreme radii/refill, old+new generation peak memory and transformed bounds partly intersecting the frustum.
- Data-bearing persistence/migrations, tiny-coordinate BR-01, stale Edit/radius bindings and source deletion while a Manual published result exists. Cached reads should expose unavailable/stale fields honestly.

## Useful work not yet justified as a redesign

| Proposal | Useful when | Keep small / evidence required |
| --- | --- | --- |
| Phase durations and reset-cause/action correlation | A callback storm or apparent idle processing cannot be attributed. | Extend existing bounded events; correlate initiating action, publication epoch, affected owner and reason. Distinguish callback receipt from causal proof and avoid diagnostic printing in hot loops. |
| Cheap dirty revisions instead of rebuilding large textual keys | Profiling shows key construction/equality or container scans dominate. | Measure clean/dirty paths; cache a key behind relevant revisions. Do not replace safe dependency coverage with global time/scene polling or skip real geometry/map notifications. |
| Peak-memory/reservation summary | Large receiver/Brush/preview changes temporarily overlap old/new state. | Account CPU/SDK payload and generations separately; process RSS/driver metrics are measurements, not all-inclusive allocator guarantees. |
| Persistent numeric worker pool | Eligible repeated batches spend material time creating/joining threads. | Preserve copied data, synchronous completion, FP determinism, launch/exception handling and main-thread SDK access. No task-graph framework merely to imitate a private type name. |
| SIMD/structure-of-arrays scratch buffers | Profiles show repeated numeric loops are bandwidth/vectorization bound. | Pilot one kernel; include conversion/copy cost, small-batch regression and exact deterministic/tie behavior. Packed vendor positions alone do not prove one layout is universally better. |
| GPU compute | After CPU acceleration, a large independent numeric phase still dominates. | Include transfer/setup/readback, cancellation/failure and host threading. Rendering instancing is already GPU use; it is not GPU placement computation. |
| Adaptive preview detail/culling/material batching | Real draw/GPU work dominates a fixed publication. | Explicit visual budget, correct transformed bounds, near/far and camera-transition behavior; no resampling on navigation. Preserve full output separately. |
| Narrow policy-3 authoring and recipe/assets reconstruction | Native correctness/ownership slices and passive reader contracts are stable. | Typed enrollment, approval, freshness, bounded work, transaction/Undo; expand one family rather than arbitrary property execution. |
| Reference-image/artist learning | Real generation-linked artifacts and artist feedback exist. | Separate engineering traces from eligible creative data; compare held-out quality/time against a deterministic baseline before training/inference claims. |

## Prioritized implementation loops

Each loop is a separate reviewable change. Pin identity â†’ reproduce â†’ smallest change â†’ affected positive/failure tests â†’ freeze/retest â†’ record limits. Do not continue inventing features once that slice meets acceptance.

1. **Persistence and preparation failure bounds.** Isolate BR-01, add checked Brush derived-state admission and correct CR1 cleanup. Acceptance is F3/F4/CR1 above; keep original authored data/prior results on failure. Avoid broad licensing or UI rewrites.
2. **Two measured CPU accelerations, independently.** F1 projection first, then F2 radius broad phase. Use the exhaustive paths/oracles for unchanged result semantics; measure small and large cases, cache build and clean reuse. A speedup with changed anchors/accepted order is a failure.
3. **Artist workload and display qualification.** Follow the [controlled matrix](EXPERIMENTS.md#next-hostperformance-matrix--not-executed-here). Measure idle/animation/key/prepare/draw separately. Optimize Proxy or a dirty-key path only if its measured contribution warrants it. Pointer work requires a future permitted testing scope; this review uses none.
4. **Host/renderer/delivery closure.** Finish Max 2026 runtime, actual 0.72 UI, successful docked IR, intended other renderer/fidelity tests and long sessions. Preserve retained 0.63/0.64 performance/lifecycle and test bounded failures. Regenerate help/catalog only in this coding/delivery loop or an earlier explicitly scoped metadata change.
5. **Diagnostics and a narrow MCP authoring slice.** Add actionable cause/phase summaries to the existing recorder. Introduce one typed policy-3 operation with ownership/freshness/transaction/Undo tests; keep passive reads and schemas 1/2 unchanged. Complete reconstructable recipes/assets before calling published rows a portable scene recipe.
6. **Creative study then ML pilot.** Qualify bounded render/capture jobs with artifact proof and explicit accept/reject/tie/neither feedback. Keep training eligibility separate. Train/evaluate a small ranking pilot only after a useful dataset exists; reference interpretation and automated iterative composition are separate experiments.

Licensing stays on its separate [release roadmap](../licensing/ROADMAP.md), default-off and untouched here. Service/full operation/recovery readiness is a publication gate; reverse engineering another product's licensing would not address it.

Recommended next coding scope: loop 1, followed by the F1 projection slice. Broader GPU/Qt/MCP/ML abstraction should wait for these bounded correctness/resource results and actual phase measurements.

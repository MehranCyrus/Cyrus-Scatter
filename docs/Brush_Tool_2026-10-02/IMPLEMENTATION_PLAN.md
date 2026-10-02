# Brush implementation contracts and milestones

2 October 2026 — revision 3.1. Proposed work only. Read the [decision guide](README.md) first; source IDs below resolve in the [evidence register](PROCEDURAL_RESEARCH.md). The [codebase integration audit](CODEBASE_INTEGRATION.md) maps concrete cache, bridge, lifecycle and render changes to these milestones.

## 1. Own the data and its lifetime

Proposed native records; these are not existing APIs:

| Record | Required responsibility |
| --- | --- |
| PaintDocument | Schema/evaluator version, document ID, ordered strokes, eligible target references, reference-surface fingerprints and mask settings |
| TargetBinding | Persistent layer-local target ID, real Max node reference, explicit triangle mapping, object-local geometry and connectivity fingerprints |
| Stroke | Persistent ID, enabled state, operation, strength/softness, ordered samples and explicit breaks |
| Sample | Target/triangle/barycentric anchor, local position, captured radius/metric, capture-view information, optional pressure/time |
| CandidateBatch | Population identity, unique candidate keys, surface anchors, source/transform data and a sampling-definition key |
| MaskCache | Document/evaluator/target/sample-domain keys, spatial index, evaluated weights, bounded scratch/checkpoint data |
| PublishedResult | Complete placement revision and preview snapshot; never a partially modified array |

Recommend one native ReferenceTarget stored in a layer's MAXScript `#maxObject` parameter, with versioned native save chunks. A07 establishes that parameter type exists; M1 must prove creation, ownership, persistence and clone/remap behavior. Do not store the authoritative document only in globals, preview helpers, node names, session handles or external temporary files.

A copied layer gets independent editable paint. Target references follow Max's explicit clone/remap semantics. Instancing an entire controller may intentionally share its object. The existing layer-copy helper is also used for older-scene migration; distinguish migration transfer from independent duplication rather than relying on a shallow property assignment. A dedicated Copy Layer UI is not established by that helper alone (CB07).

Validate saved counts, lengths, enum values, finite numbers and size limits before allocation. Save history and bindings; initially omit derived caches. If load/replay cost later justifies saved caches, accept them only with matching keys. Unknown versions must preserve/report unsupported data instead of silently clearing paint.

Target deletion, hidden/frozen state changes and loss of eligibility must end or suspend the active transaction. Never automatically retarget by matching a name. Reject scatter output/source arrangements that introduce dependency cycles.

Ordinary live invalidation is gated by Realtime in the current code. The active Brush must validate its target in Manual mode too, independently of whether plant regeneration is allowed. Register and qualify that session-specific validity path before accepting hits (CB04).

## 2. Pick and evaluate one agreed surface

Start with Painter V7 supplied ObjectStates (A02). Build and own triangulated target snapshots on Max's main thread and use the same face mapping for hit reconstruction and scatter provenance. Keep temporary ObjectStates and backing objects valid until the session has ended or safely refreshed; verify actual SDK lifetime behavior in M0.

Set native point gathering off for the first probe. Disable and later restore unrelated global Painter options such as mirror/spline constraints that could alter our intended behavior. Acquire only one Cyrus painting session at a time; handle another host paint tool owning the interface. Copy callbacks' sample data into our records before returning.

The hit is a triangle interior, not a vertex. Reconstruct `p = w0*a + w1*b + w2*c`; compare it with the reported hit. Preserve node identity when concatenating surfaces. Validate Editable Poly triangulation, modifiers, object offsets, time and mirrored winding. Transform normals with the appropriate inverse-transpose convention under nonuniform scale. Cursor orientation does not change the layer's separate plant-normal alignment policy. The previous projection face-identity investigation is not a ready-made replacement for these checks.

### First footprint: visible patch on the hit target

Define the initial algorithm precisely:

1. Pick the nearest eligible target at the cursor. Each dab belongs to one target.
2. In that target's validated reference coordinates, start at the hit triangle. Traverse adjacent triangles only across shared edges intersecting the radius region. Broad-phase triangle bounds alone do not establish connectivity inside the brush.
3. At a queried surface location, evaluate the captured world-distance metric and falloff. Use point/triangle geometry, not triangle-centroid distance, so a small stroke works within a very large triangle.
4. Apply self-visibility from the captured view against that target's reference mesh. Use perspective rays or the captured orthographic direction as appropriate. A candidate normal test can reject obvious cases but cannot replace visibility.
5. Cache affected face regions and sample weights as derived data. Replay or new candidates use the same captured metric/view and the same valid reference geometry, never the current viewport camera.

Radius is world distance at capture, not exact distance along a curved surface. For local displacement `d` and capture linear transform `L`, use `distance² = dᵀ(LᵀL)d` in column-vector notation; adapt explicitly to Max's matrix convention. Storing that metric lets later object transforms carry old paint with the object, including its scale, while new strokes use the current world-unit radius.

The cursor ring is a guide; the evaluated overlay shows actual coverage. The initial visibility scope is **self-occlusion on the hit target**. Other eligible nodes choose the nearest seed but are not additional footprint blockers. This intentionally replaces revision 2's broader, unspecified occluder set. An all-target visibility option would need captured occluder dependencies or persisted coverage to remain reproducible after scene edits.

Treat ambiguous nonmanifold connections, singular transforms, degenerate triangles and coincident surfaces explicitly. Stop across ambiguous edges or reject the unsupported target; do not silently flood connected branches. Scale intersection tolerances to local geometry and scene units. Compare accelerated queries with a small brute-force reference, including shared-edge hits and deterministic tie handling.

This algorithm is an experiment until E06 passes. If sphere-intersection connectivity is visually unsuitable, compare a true surface-distance method before widening support. Do not label the initial distance metric geodesic.

### Shape changes

Static target geometry is the first contract. Object transforms can be supported; arbitrary deformation is not covered merely because topology is unchanged. Cache validation includes reference geometry and connectivity. A changed shape suspends affected paint with a clear Needs rebind status, preserving its history.

Later fixed-topology deformation needs an explicit retained rest surface and candidate anchors, then evaluation on the deformed triangles. H03/H04 support this workflow. Retopology requires an explicit transfer tool and an unmatched/ambiguous report. Recorded projection rays or optional texture UV/channel are recovery inputs, not guarantees.

## 3. Define brush mathematics once

All masks and influences are in `[0,1]`. For one stroke, build `q(x)` as the maximum influence of its resampled dabs, including strength, pressure if enabled, falloff and footprint eligibility.

Apply against the state before that stroke:

```text
Paint: M_after = M_before + (1 - M_before) * q
Erase: M_after = M_before * (1 - q)
```

This supersedes revision 2's `max(M,q)` paint rule. A half-strength stroke on empty ground gives 0.5; another separate stroke gives 0.75. Repeated evaluation of the same active stroke still gives 0.5. Erase is a recorded operation toward zero; it is not Undo and does not mean restore an upstream mask. These are proposed Cyrus semantics, not copied vendor formulas.

Use a defined soft-edge function, for example a flat core followed by smoothstep to zero, with explicit zero-softness and zero-radius handling. Version the evaluator; changing mathematics later must not silently reinterpret saved scenes.

Save the captured input path and its breaks separately from derived dabs, with sufficient view/ray information to resample it again. A later radius change must not reuse coarse dab spacing from a much larger brush. Resample by traveled distance relative to radius, preserving endpoints, pressure extrema and discontinuities. Start with at most one quarter of the smaller adjacent radius, then refine from E11 error measurements. Re-hit inserted screen-path samples on the agreed mesh; do not interpolate a chord through a folded surface. Break at off-mesh gaps, target changes or ambiguous jumps. Equal event counts are irrelevant; compare equivalent recorded paths.

During a stroke, keep pre-stroke values plus accumulated q only for touched sample IDs. Recompute the provisional mask from those values. Commit once; cancel discards scratch. Editing an old stroke replays the union of old/new affected regions in order, with compatible checkpoints if available. Full chronological replay is the oracle.

The field must answer new surface queries independently of existing plants. Cached candidate weights are an optimization, not the document. A four-vertex plane also requires an independently sampled overlay; original vertex colors alone cannot describe a detailed stroke. Bound overlay resolution without feeding it back into final mask acceptance.

A first global Mask amount multiplies the painted field; zero removes painted coverage. Disabling Brush bypasses the field instead. Keep those operations distinct. More elaborate remapping and mask sharing can follow.

## 4. Preserve identities through the actual pipeline

Do not insert Brush rejection into the current sequential sampler. Generate the eligible base without Brush, preserve its source/transform choices, then apply the additional factor. Existing area/density-map factors already applied to that base must not be applied twice.

Give each candidate a unique key before any Brush compaction. Prefer a population key plus generator-attempt key with explicit target provenance. Cache revisions and compacted output ordinals are not identities. Preserve keys and barycentric anchors through removal, movement and serialization.

Current native bridges export two-field rows and several reconstruct Instance records without surface provenance. Use an owned native CandidateBatch through the Brush pipeline; extend supported algorithm adapters to preserve metadata, then convert to legacy rows at endpoints. Adding fields to Instance alone cannot satisfy this contract (CB03).

Derive a fixed threshold from `hash(candidateKey, "brush-acceptance")` in `[0,1)`. Accept if `u < clamp(densityFraction * maskAmount * M, 0, 1)`. This gives nested membership for a fixed base; the hash is a randomization tool, not a collision-proof identifier.

Only use densityFraction when it is defined relative to the population's recorded capacity. Existing constraints can reduce achieved physical density. Raising capacity, changing seed or changing the sampling definition can create a new population; report that boundary. First prove mask-only stability, then add stable density adjustment within capacity. Do not add a speculative second sampler to the first milestone.

### Required integration order

```text
Existing candidate generation and qualified intra-layer spacing
  -> existing Analyzer/area/falloff and source transforms, preserving provenance
  -> Brush acceptance on the declared surface anchor
  -> raw blocker snapshot
  -> existing inter-layer overlap / final cleanup / final relaxation
  -> orientation and identity-aware CS Edit
  -> preview / render-specific source policy
```

The initial anchor is the base's surface root after any qualified projected movement/intra-layer spacing, before source Z offsets. Preserve or recompute its barycentric provenance when that root moves. Unprojected movement and later CS Edit offsets do not move the painted surface mask; this must be visible in the interaction tests.

The first probe stops before complex downstream operations. Before product integration:

- `rawOnly` blocker consumers must receive Brush-filtered raw candidates. A final-output-only filter leaves invisible blockers.
- Key blocker caches by Brush revision and invalidate dependent layers. Preserve the current raw-blocker policy, which avoids recursive final-layer evaluation; document that it does not include downstream CS Edit changes.
- Final cleanup can remove newly isolated survivors. Final relaxation can move roots beyond a painted boundary unless its admissibility predicate includes Brush. Qualify that predicate or explicitly disallow the combination. These operations are outside the unaffected-position promise.
- The `finalPass` recursion must not sample Brush a second time or lose identities.
- Distinguish bounds, render, bake/export, blocker and viewport consumers. Their quality limits must not define different underlying Brush populations.

Frozen base spacing followed by thinning is the initial policy. It preserves survivors but does not maximize packing in a small painted patch: hidden base candidates may have affected spacing. Compare E05 before considering redistribution. Changes to other layers' blockers can legitimately affect downstream results.

### CS Edit

Current external base IDs are `b:<row index>`, despite internal stack identity support (C03). Add an explicit keyed input path for painted layers. Paint-only membership changes keep the population binding key; masked-out edited candidates remain dormant, and their edits reactivate if the same candidates return. Derived copies retain their own IDs and parent association.

Retain the legacy path for Brush-disabled scenes. Migrate an existing edit binding only while its full original correspondence is provable. Otherwise preserve the edit records and require explicit rebind; never automatically Reset. Scope edit layers by persistent layer identity, not only current list position.

M0/M1 exclude CS Edit. M2 must either complete the keyed path or prevent the unsupported combination with a clear, non-destructive message. A prototype exclusion is not a claim of feature compatibility.

### Preview identity

Current point preview selection is spread across the compacted placement/sample range (C04). Removing rows can change samples elsewhere even when logical candidates stay fixed.

For the first stability probe, freeze the preview cohort against the full base, then apply Brush membership to that cohort. It can underfill the display budget; the independent mask overlay still shows painted intent. Test render identity separately from preview sample identity. Later budget refill/detail refinement may select additional stable-key samples, with any cap-driven replacement explicitly measured. Stable IDs alone do not make a changing global budget visually invariant.

## 5. Keep interaction transactional and bounded

Use session states: Inactive, Ready, Stroke, Pending publication, Suspended. Own callbacks and global Painter settings only during the session, restoring them on every exit path.

| Event | Required behavior |
| --- | --- |
| Mouse down / drag | Start one undoable stroke; copy/resample input; update bounded scratch/overlay |
| Mouse up | Commit once; schedule the completed placement revision |
| Escape / explicit cancel | Discard active scratch and restore the pre-stroke result |
| Navigation interruption / viewport switch | Finish the valid partial stroke once, close its Undo transaction and break the path before resuming |
| Target/layer deletion, scene reset, script reload | Cancel active scratch, invalidate jobs and release session ownership |
| Save / render request | Finish a valid active stroke at a safe host boundary; serialize committed history; render resolves the committed revision |
| Allocation/error during update | Keep the last valid display with an explicit stale/error status; do not publish partial or silently unmasked output |

Implement repeated Undo/Redo safely and report approximate undo memory (A04). One stroke's restore record owns document changes/deltas, not an entire scene copy per mouse event. Exercise autosave and interrupted callbacks, not only the normal mouse-up path.

Account for the existing global scene Undo callback: it currently forces all layers to refresh. Brush-owned Undo must invalidate its affected layer and genuine dependents without triggering that redundant global work. Keep the conservative fallback for other scene edits (CB06).

Start with synchronous, bounded native work. Keep Max evaluation, references, UI and publication on the main thread. If profiling justifies workers, send only immutable copied data and tag work with document, target, candidate and session generations. Discard obsolete results after Undo, deletion or newer edits. Never wait for a worker that is waiting for Max's main thread.

Coalesce preview publication, not the recorded brush path. Retain enough input to reproduce geometry within the sampling tolerance. A capped queue needs a defined response to overload; silently dropping a curved part of the stroke is not acceptable.

The held-input guard for navigation must remain. Introduce an explicit active-paint scheduling path; do not create helpers or mutate the scene inside Display/redraw callbacks. First use a modest plant-preview cadence, with immediate cursor feedback. Measure CPU processing, overlay cost, publication bytes and observed input-to-visible latency separately.

The current preview rebuild combines placement generation, source sampling and display construction, and clears the old cache before building. For Brush, separate those dependencies, build the replacement privately, and publish only a complete result. Retain a stale/error-marked last valid preview on failure; successfully publishing an empty mask must clear it. Unchanged base/source inputs must not regenerate during warm strokes (CB01/CB02).

Render keys must explicitly include the committed paint revision, without serializing history. Manual preview/IR waits for Update; production render and explicit bake resolve the current committed Brush state at their operation boundary. Existing baked nodes remain explicit output and require a visible rebake/removal workflow after painting. Qualify this Brush-enabled policy without altering old scenes' Manual behavior (CB05).

A large radius may touch the entire domain. Editing an early stroke or querying new candidates after many overlapping strokes may be expensive. Budget scratch, indexes, checkpoints and in-flight display data, and show pending work. Do not promise constant-time updates in these cases.

Outside Brush, navigation must perform zero Brush work. Inside Brush, view-dependent native picking rebuilds are a separate cost. If measured Painter cost fails, prototype a native mouse mode with an owned ray index; preserve the same mask/document contract.

## 6. Deliver in four reviewable milestones

All boxes below are outstanding implementation work.

### M0 — native interaction and geometry proof

- [ ] Disposable native harness on Max 2026/2027; verify loaded binary identity and SDK interface availability.
- [ ] Shared triangulated snapshot, V7 hit reconstruction, capture metric and cursor/overlay probe.
- [ ] Plane, terrain, wall, folded/stacked surfaces, transformed objects, orthographic/perspective and multiple viewports.
- [ ] Entry, navigation interruption, cancel, target deletion and session teardown; measure picking independently of scatter.

Exit: correct surface/face identity and no false through-surface coverage in the declared scope. Record cold entry and post-navigation picking latency. Do not publish an artist feature yet.

### M1 — editable mask and stable candidate proof

- [ ] Pure C++ evaluator, indexed affected-region queries and full-replay oracle.
- [ ] Registered native document holder, versioned save/load, isolated clone, whole-stroke Undo/Redo and cancellation; qualify the existing global callback and migration/copy paths.
- [ ] Cached identified population; mask-only changes preserve unaffected attributes.
- [ ] Four-vertex-plane overlay; new candidate queries recover paint; test earlier-stroke disable/strength/radius edits through the native harness.
- [ ] Freeze preview cohort; measure 10/100/1000 separate and overlapping strokes.

Exit: repeatable paint/erase/density demonstration with E01–E04, E06's basic scope and E11–E12 passing. This is the next useful demonstration, not a full compatibility release.

### M2 — supported product integration

- [ ] Add controls through `tools/ui/brush.cjs` and the authoritative generator; migrate old layers with Brush disabled. Include a compact history panel for enabling, deleting and adjusting a selected earlier stroke's strength/radius; a node editor is unnecessary.
- [ ] Preserve keys/anchors through all supported branches; resolve blockers, final operations and CS Edit as above.
- [ ] Realtime/Manual scheduling, target validity in both modes, transactional retained display publication and committed preview/render/bake revision policy.
- [ ] Layer/controller copy, reorder, merge, delete, source change and target-reference tests.
- [ ] Actual Max 2026 and 2027 sessions, with old scenes and supported renderer/export paths.

Exit: publish an explicit compatibility matrix. No silent disablement, edit reassignment or unchanged-old-scene regression.

### M3 — heavy-scene qualification and measured follow-up

- [ ] Sweep target complexity, candidate count, stroke history, affected area, target count and display mode.
- [ ] Verify inactive-navigation baseline and warm interaction latency; record worst stalls and memory, not only average FPS.
- [ ] Use findings to choose one optimization: picking, local field cache, buffer publication, or candidate-domain partitioning.
- [ ] Re-run correctness fixtures and the relevant old-scene tests after that change.

Do not increase every production limit to run a Brush benchmark. Current UI density generation and the advanced native bridge cap at 100,000 requested candidates; preview input caps at 500,000 points (C02/C04, CB03). A million-candidate native kernel experiment is a separate test until the product limits are deliberately reviewed.

## 7. Acceptance and measurement matrix

These are planned experiments, not completed tests.

| ID | Fixture / action | Required evidence |
| --- | --- | --- |
| E01 | Small stroke on four-vertex plane and dense terrain; change density/display detail | Same field at new query locations; no dependency on vertex or visible-instance count |
| E02 | 10/100/1000 separate and overlapping strokes | Incremental results match full replay; append cost, replay cost and memory reported separately |
| E03 | Disable/resize old stroke; Undo/Redo; save/reopen; copy/merge | Correct chronological result and independent copies; cache loss changes cost, not intent |
| E04 | Mask amount; density within capacity; then capacity/seed/spacing changes | Separate ID, position, species, transform and field assertions; declare regeneration boundaries |
| E05 | Base-spacing then mask near borders/holes | Document packing tradeoff; no unintended refill; no new solver without evidence |
| E06 | Folded sheet, thin shell, two objects, shared edges and coplanar ties | Correct declared visibility/target scope; accelerated query matches reference; capture-view replay |
| E07 | Move/scale target, deform same topology, retriangulate | Qualified transforms carry paint; unsupported geometry changes suspend instead of misbinding |
| E08 | Input-to-publish trace, all preview modes, Manual/Realtime | Counts/times for hits, conversions, field queries, base/source regeneration, upload bytes and stale results; warm paint reuses unchanged base/source data |
| E09 | Only if needed: partition candidate generation | No duplicates/gaps or changed identity at cell borders; halo/ownership oracle |
| E10 | Global mask amount; area/map filters; preview/render/bake; committed Manual edits | Same logical acceptance at the declared applied/committed revision; no double density weighting or preview-budget leakage; explicit stale-bake policy |
| E11 | Same path with sparse/dense input; repeat soft strokes; repeated callbacks | Event-frequency independence within tolerance; correct opacity buildup and erase |
| E12 | Escape, lost focus, viewport/panel changes, autosave, reload, Manual target edits, allocation failure | One well-formed transaction; no leaked callback, wrong-layer stroke, partial save, obsolete hit or publication; valid-empty output clears the preview |
| E13 | Painted blocking layer; final cleanup/relax; keyed CS Edit chains | No invisible raw blockers; masked edits dormant/reactivated; supported ordering and boundary rules |
| E14 | Erase small patch under saturated point budget; Undo with multiple controllers; then leave Brush | Distinguish preview resampling from plant changes; unrelated layers do not rebuild for Brush-only Undo; zero Brush work during ordinary navigation |

Provisional reference fixture: static 100k-triangle target, 100k eligible candidates, 100 strokes, small brush affecting about 1% of candidates, bounded Point Cloud display. Record hardware, viewport size, shading, binaries, all settings and target hashes before interpreting timings.

Provisional acceptance target: warm input-to-mask feedback p95 at most 33 ms, no growing publication backlog, and optional live plant feedback at least 10 Hz on that fixture. These targets are not measured achievements. Report cold entry, first hit after orbit, mouse-up completion and worst stall separately. Full-detail Mesh preview and whole-domain strokes need their own results.

Native arithmetic oracle: weights within 1e-6 for the same evaluator and replay path; identity and membership equality for identical inputs. Input-resampling tolerance is a separate spatial/coverage measurement, chosen in M0 from scene units and minimum supported brush radius. Compare identical recorded paths rather than pretending lost input can be reconstructed exactly.

For timing comparisons, warm caches, use fixed paths and multiple runs, record median/p95 and sample count, and compare Brush inactive with the same completed scene. Any claimed gain must identify the measured stage and preserve correctness.

## 8. File boundaries and escalation rules

Proposed additions: `include/brush.h` and `src/brush.cpp` for host-independent records/evaluation; `src/brush_host.cpp` for Painter/lifecycle; `src/brush_storage.cpp` only if storage warrants a separate file. Keep initial harnesses under `tools/performance/brush_probe/`, native tests with the other suites, and results under one dated Brush evidence directory.

Extend `max_bridge.cpp`, `scatter.h` and the relevant filtering/spacing paths to transport identity and anchors. Extend CS Edit with a keyed input path. Generate UI through `tools/ui/generate.cjs`; do not hand-edit only the generated MAXScript.

Do not introduce CUDA/OpenCL, a task framework, a full sparse atlas or a new scatter generator in M0/M1. Add workers for measured pure-data CPU work; add regional display buffers for measured uploads; add tiled generation for measured whole-domain memory/cold-start cost. Exact geodesics and deformation are workflow extensions, not generic performance cures.

A failed gate produces a smaller supported scope or one targeted alternative experiment. It does not justify an undocumented approximation or an open-ended rewrite.

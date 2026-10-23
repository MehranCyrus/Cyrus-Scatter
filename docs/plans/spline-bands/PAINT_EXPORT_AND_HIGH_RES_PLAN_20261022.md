# Paint spline export optimization and higher-resolution Bands

22 October 2026. **Implementation proposal only.** The user requested a detailed plan, including Max 2027 tests, with the original Paint unchanged. This document does not authorize or claim implementation, installation, qualification, publishing or Git operations.

## 1. Intended result

Make this workflow reliable: **paint an area → export an efficient independent spline → use that spline for inside/outside Bands in another layer**.

Deliver two complementary improvements:

1. A bounded, topology-preserving optimized export, with a visible physical error tolerance and an Exact snapshot choice.
2. Native Bands processing that admits substantially denser valid paths without relying on artist simplification to get past an overly conservative clipping estimate.

These have different correctness requirements. **Bands processing on unchanged geometry must preserve its geometric and sampling results. An optimized export intentionally changes its new copy within a certified error.** Assigning that copy to a new Band and updating can change placements near the adjusted boundary. Export itself must not change the source Paint or existing scatter publications.

Keep closed loops, separate islands, holes, useful corners, narrow features, receiver ownership, transforms and physical units explicit. Do not silently widen tolerance or drop geometry to reach a desired knot count. Bands remain world-XY distance fields; this work does not introduce geodesic Bands on curved receivers.

## 2. Baseline and inspected evidence

| Item | Established baseline |
| --- | --- |
| Branch / HEAD | `codex/workflow-0.75` / `3d387550cacf37fe1aeae7a01455f7644d9cf08b` |
| Current Scatter | 0.86.8.2, schema 59, recipe 8, publication capability 4, native placement capability 2 |
| Current spline/Brush interfaces | `cyrusSplineBandVersion() == 10`; `cyrusBrushConversionVersion() == 1` |
| Paint export | One corner/linear knot for every canonical boundary vertex; no reduction pass |
| Exact attached-surface snapshot | AppData chunk `0x8661` carries the original coverage payload and exported-geometry hash; matching frame/hash enables exact restoration |
| Existing generic spline import | 8,192 total pieces/samples; the guarded attached Exact snapshot has a separate canonical-contour restoration path |
| Bands | Up to 8,192 total sampled input vertices, shared across the prepared field; actual operation admission has additional bounds |
| Future build/host scope | **Max 2027 only**; previous Max 2024/2026 evidence remains historical |

The working tree contains unrelated Arrange, Physics, website and knowledge work. Preserve it. Product source under `AminScatter/` was unchanged at plan preparation. The exact artist spline has not been extracted or measured; screenshots establish the workflow, not an exact knot count.

The preceding investigation compiled a private reproduction against the unchanged qualified Max 2027 native libraries. It did not launch Max or modify a scene. A four-point rectangle passed; the same rectangular footprint subdivided into 1,024 points failed. A 720-point circle passed, while 721 points failed. Reservations returned to their preceding values after rejection. See the [native reproduction receipt](../../../build/spline-band-scratch-investigation-20261022-01/receipt.json).

### Source anchors

| Responsibility | Current source |
| --- | --- |
| Export knots, exact snapshot data, import restoration | [brush_host.cpp](../../../AminScatter/src/brush_host.cpp), `cyrusBrushExportSpline`, `cyrusBrushImportSpline`, `splineGeometryKey` |
| Canonical Paint, metric and surface contours | [brush.h](../../../AminScatter/include/brush.h), [brush.cpp](../../../AminScatter/src/brush.cpp), [brush_atlas.cpp](../../../AminScatter/src/brush_atlas.cpp) |
| Export/UI owner validation | [unified-core.ms](../../../AminScatter/tools/ui/templates/unified-core.ms), `validatePaintConversion`, `exportPaintSpline`, Painting controls |
| UI composition | [approved-layout-rows.cjs](../../../AminScatter/tools/ui/approved-layout-rows.cjs), `coverageUI`; [approved-layout.test.cjs](../../../AminScatter/tools/ui/approved-layout.test.cjs) |
| Path extraction and width-dependent tessellation | [spline_field_bridge.inc](../../../AminScatter/src/spline_field_bridge.inc), `cyrusPrepareSplineField` |
| Prepared fields, admission, queries and outlines | [spline_bands.cpp](../../../AminScatter/src/spline_bands.cpp), `admitClip`, `Field::Field`, `locate`, `visitOutlines`; [limits/API](../../../AminScatter/include/spline_bands.h) |
| Shared prepared field and publication | `preparedSplineField`, `procStagePreview`, `evaluateProcedural` in the unified template |
| Existing geometry contracts/tests | [Bands design](DESIGN.md), [spline_band_tests.cpp](../../../AminScatter/tests/spline_band_tests.cpp), [brush_conversion_tests.cpp](../../../AminScatter/tests/brush_conversion_tests.cpp) |

The existing Bands progress/delivery reports retain their historical source, host and limits. They are not new qualification of this proposal. Relevant foundation contracts are F01–F11, especially F04–F06 and F09–F11. Use the [agent workflow](../../AGENT_WORKFLOW.md) for isolated hosts and exact identities.

Knowledge generation `7bd37979ae4e3c242694fde44943d7ec54cfe6236112ce00c7d01bae18751fbc` passed full enrolled-source verification during planning; an exact export-symbol lookup returned no enrolled result. The relevant implementation was inspected directly. No index refresh/activation is part of this plan.

## 3. Root cause and why two changes are needed

The current clipping preflight estimates each operation as:

`scratch = edges × (edges + 1) × 512 bytes + 2 MiB`

Its default construction allowance is 256 MiB. This intentionally conservative estimate assumes potentially intersecting edge pairs. It is not a measurement of actual allocated memory, and it rejects a simple 721-edge input before clipping runs. The nominal 8,192-input limit therefore does not describe what all current paths can reach.

Rounded fields keep original floating-point segments for distance queries, including internal/self-overlapping segments, but still run a quantized EvenOdd union to establish valid filled geometry. Sharp fields need normalized geometry, offset families and nesting checks. Rounded boundary display separately performs normalization, offsets and Boolean operations. Improving only one call site leaves other versions of this failure possible.

Paint export currently passes every boundary point through as a linear knot. Those linear pieces remain separate during Band tessellation. A fitted Bezier with fewer visible knots can also generate many samples under the existing Band-width-dependent accuracy requirement. Modifier knot count alone is not a reliable estimate of Band construction cost.

### Autodesk tools considered

Autodesk's [Optimize Spline documentation](https://help.autodesk.com/cloudhelp/2025/ENU/3DSMax-Modifiers/files/GUID-A4D5E67D-429C-44D1-8350-28C5687A334B.htm) describes knot reduction and handle adjustment. The [Max 2027 MAXScript API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Modifier-MAXWrapper-and/Modifier-and-SpacewarpModifier/Modifiers/Patch-and-Spline-Editing/GUID-4D6345EE-68BB-47D2-8C44-07D56A65A1A5.html) exposes percentage/count reduction, angular collinearity preprocessing and creation of a separate optimized spline. Its documented controls do not supply the world-distance/topology certificate required here.

**Selected production approach:** a bounded C++ polyline simplifier over copied Paint contours, followed by validation of the final geometry Max receives. Keep Max's modifier as an artist tool and a bounded comparison case during qualification; do not automatically install it on the exported node or make it a second production optimization engine. This gives explicit error/work limits, avoids an uncontrolled modifier evaluation, and leaves Bands independent of the optimization tool used to author a path.

## 4. Ownership, preservation and failure contracts

| Record/resource | Owner and lifecycle |
| --- | --- |
| Canonical Paint document, falloff, receiver/topology binding | Existing Paint Area; read-only during export |
| Export settings and status | Captured export invocation/UI; not a new authored layer setting |
| Numeric source copy, candidate contours, proof/index scratch | One bounded native export operation; released on success, cancel or failure |
| Exported spline | One independent scene node with its own geometry and transform; creation is one Undo command |
| Exact coverage snapshot | Existing Exact export only; retain its current payload/hash/frame rules |
| Optimized-export provenance | New informational, versioned node metadata; never an exact-coverage restoration payload |
| Prepared Band field, classification and segment indexes | Immutable native Field data; shared through the existing prepared-field/publication lifetime |
| Clipping scratch/work | Per-operation budget nested within Field/outline reservations; never a process-global allocation override |

Required invariants:

- Export does not change encoded Paint bytes, receiver identity, falloff, source/layer settings, variation seeds, candidate IDs, existing placements or publication epochs. It does not invoke Update or Analyze. Selection of the new node remains the expected authored export effect.
- Undo/Redo of export removes/restores only that new node and its export metadata. Preceding Undo entries remain intact. No Undo clearing, forced full GC or artist preference changes.
- The old Exact native operation and its existing two-argument signature retain Exact behavior. Add an explicit optimized operation/options contract; do not silently reinterpret existing calls.
- A failed/cancelled export creates no partial node, leaves selection recoverable and releases temporary resources. An invalid Band successor retains the preceding complete field and scatter publication.
- All host object capture, spline construction/publication, Undo and UI work stay on the Max thread. C++ numerical work consumes owned copies. Keep the present synchronous execution model; no asynchronous scheduler is introduced.
- Optimized geometry is not a live link to Paint. Future painting does not move the exported spline or change a Band using it.
- Preserve existing Band population, source/owner lotteries, density/scale curves, Empty behavior, spacing and Manual/Live contracts. Do not apply the export simplifier silently to arbitrary Band inputs.

## 5. Artist-facing workflow and UI

Keep **Painting → Export spline** in its current location. It opens a compact export-options view bound to the captured Paint Area:

- **Mode:** Optimized / Exact snapshot.
- **Maximum deviation:** world-unit distance, enabled for Optimized. Proposed initial suggestion is **1 mm**, displayed in current scene units; this is an editable physical value, not a universal safe tolerance. Never increase it automatically to obtain a knot count.
- Brief mode help: Optimized reduces boundary points within tolerance; Exact preserves the snapshot/reimport behavior.
- **Create spline** and Cancel. Publish a concise result: original/output knot counts, certified deviation bound and any exact-retained portions/fallback. Do not claim reduction when none was safe.

For ordinary planar/terrain contour exports, suggest Optimized. For attached curved Paint, default to Exact until the applicable surface-preserving proof has passed; do not silently approximate nonplanar boundaries. Keep Exact directly selectable on every export.

Opening the view, changing its tolerance or switching modes performs no placement calculation or authored mutation. Validate the captured controller/area/document revision again before creating the node. If that owner was removed or painted again while options were open, report the stale context and require a fresh capture rather than exporting a newly selected area accidentally.

Export tolerance and the existing **Curve tolerance** used for spline import have separate meanings. Keep them separately labeled. A future Band's width is not known during export. If valid provenance shows a significant export-error-to-Band-width ratio, provide an actionable warning recommending a smaller export tolerance or Exact mode. Do not guess the future width or reject an otherwise valid artist-authored path solely because it originated from optimized export.

## 6. Native optimized-export design

### 6.1 Capture and metric

Capture the canonical boundary, receiver frame, document revision/fingerprint and relevant unit basis once. Retain correspondence from every candidate edge to the complete original contour span it replaces.

Perform deviation checks in the **world-space metric of the exported boundary**, including scale/shear. Return local-space knots under the original node transform. Do not confuse scene display units, system units, receiver-local distances and physical millimeters.

Terrain export retains its current local-XY snapshot convention. Attached Paint remains a 3D surface boundary. This plan does not change either representation or infer that an arbitrary projected curved loop is a planar Paint region.

### 6.2 Deterministic simplification

1. Validate finite values, closed loops and existing canonical limits. Remove consecutive duplicate/zero-length representation artifacts only when the geometric and topology meaning is unchanged.
2. Remove truly redundant collinear knots only when the middle point lies between the retained endpoints. Preserve reversals, contact vertices and feature-defining corners. Identify geometric features from the contour; the existing exporter marks every knot `KTYPE_CORNER`, which must not accidentally protect every dense smooth-boundary sample. An angle tolerance is approximation, not exact collinearity.
3. Simplify closed rings using deterministic anchors and stable original-span correspondence. Use an iterative, bounded chord-replacement/chain-reduction algorithm; do not apply an open-polyline reduction blindly across an arbitrary closure seam.
4. Certify every proposed chord against its **entire original span**, preventing accumulated error from repeated local reductions. Establish a continuous, bidirectional boundary-distance bound, not only distances at a few test samples. Document the chain-to-chord/capsule proof and its reverse-coverage conditions before implementation acceptance.
5. Test chord eligibility against retained edges and other contours through a spatial broad phase and robust narrow-phase predicates. Preserve component/hole count, containment hierarchy, meaningful orientation, contacts and narrow corridors. Distance error alone does not prove topology preservation.
6. When a removal is uncertain, keep the original detail. When the reduction-work budget is exhausted, stop reducing; never raise tolerance. Publish only after complete validation. If validation cannot complete, return a truthful Exact fallback or fail without publication.

Use checked robust predicates consistent with the existing coordinate range/quantization. Do not assume cross-products of large quantized coordinates fit an ordinary 64-bit integer. Protect near-coincident edges and original inter-loop contacts instead of silently welding them.

### 6.3 Curved receiver policy

Do not straighten a surface boundary through the interior of a sphere or across a fold. The initial optimized eligibility proof covers planar contour exports. For attached boundaries, permit reduction only within certified coplanar receiver patches where the entire replacement chord stays in the receiver domain and face-crossing/contact anchors remain protected. Otherwise retain those portions exactly or use Exact mode.

Merely finding coplanar endpoints/vertices is insufficient. Until the domain and error proof is qualified, attached output remains Exact. This is an explicit support boundary, not a claim of general geodesic spline fitting.

### 6.4 Final publication certificate

Validate the candidate after conversion to Max's single-precision knots and application of the final node matrix. Reserve part of the deviation allowance for host precision; fail or retain Exact when the requested bound cannot survive float conversion/large transforms. A double-precision local candidate alone is not the published result.

Return only a bounded summary to MAXScript: node, mode, counts, tolerance/certificate and status. Do not move contour-sized numerical arrays into MAXScript.

### 6.5 Exact versus optimized metadata

- **Exact:** retain current `0x8661` payload, geometry-hash and matching-frame restoration behavior. Preserve original chosen coverage on a closed receiver, including cases where the boundary alone does not determine the chosen side.
- **Optimized:** never attach an original Paint payload under the simplified geometry's exact-snapshot hash. Use a distinct versioned informational record if provenance is needed: mode, physical tolerance, source fingerprint and final geometry/frame/unit identity. Allocate its identifier after checking existing IDs.
- Modified geometry, modifiers, transform or unit changes invalidate the provenance certificate when it no longer describes the evaluated result; they do not make the path invalid or alter Paint automatically.
- Reimporting optimized geometry uses ordinary geometric import. On a closed receiver it does not inherit Exact mode's chosen-side guarantee. State this in UI/help and test it.
- Keep existing generic import capacity limits explicit. An optimized output still above 8,192 pieces/samples is not automatically importable; large terrain Exact exports also retain their existing generic-import restriction. Do not expand Paint import or claim every Exact export round-trips merely because Bands admission improved.

### 6.6 Work and memory admission

Keep the canonical Paint maximum of 200,000 vertices; the optimizer is not an excuse for quadratic work at that size. Bound input/output storage, candidate-pair checks, original-span verification and scratch separately. Proposed initial numerical-operation ceilings for profiling are **64 MiB scratch and 50 million checked work units**, with checked arithmetic. These are design targets to validate/freeze in Phase 0, not measured current guarantees. Host spline allocations require their own estimate and measured peak evidence.

Reserve enough work/memory for final validation before attempting further reductions. Charge actual vector capacities and simultaneous source/candidate/index/proof data. If a valid region cannot be simplified within the limit, retain detail or return Exact with clear status. Do not promise every 200,000-vertex Paint boundary becomes an 8,192-sample Band path.

## 7. Higher-resolution Band architecture

### 7.1 Separate geometry class from vertex count

Add bounded classification before expensive polygon operations. Use a spatial broad phase over segment bounds and robust tests for crossings, contacts, overlap and degeneracy. Classify a narrow, provable simple case first; treat uncertain results as fallback/rejection, not “probably simple.”

For the first Rounded fast path, require simple noncrossing closed rings, compatible exact-double and quantized topology, nonzero filled support and known containment/parity. Add nested/disjoint ring support only with its explicit proof and tests. Duplicate rings, touching/overlapping contours, self-intersections and quantization collapses do not qualify initially.

EvenOdd fill must remain EvenOdd. A sum of signed areas is not a sufficient nonempty-fill proof, and duplicate equal rings may cancel. Preserve the current zero-area/invalid-coordinate rejection semantics unless a separate correction is deliberately specified.

### 7.2 Rounded preparation

For a proved eligible Rounded input, avoid the unnecessary Clipper normalization used only for validity. Retain **all original floating-point segments**, original local origin, loop order and segment identities for distance and side evaluation. Do not normalize away internal segments or simplify arbitrary Band paths. Keep the old bounded path for ambiguous/non-simple cases until governed clipping is available.

The fast path must not change Band sampling tolerances, width/endpoints, source membership, random channels, contribution order or the interpretation of holes. Existing low-resolution accepted cases require complete differential parity. Dense simple paths should no longer fail merely because all their edges were assumed to intersect one another.

### 7.3 Query acceleration

Build an immutable segment index for sufficiently large prepared regions. Use deterministic segment IDs, conservative bounding boxes and stable nearest-distance/ray-crossing rules. Keep the original per-segment distance/ray expressions for evaluated candidates. Conservative pruning must not miss a nearest edge or ray crossing because of roundoff, horizontal edges or boundary endpoints.

Keep a linear path for small contours when measurement supports it; a rectangle should not acquire a costly index. Apply equivalent indexing to Sharp prepared regions only after its level-search/error behavior is protected.

Account for index nodes, scratch/build peak and retained capacity. Distinguish legacy logical segment visits from actual indexed node/edge work. Initially preserve existing query-admission semantics for previously accepted paths, and add separate bounded physical-work telemetry. Do not silently redefine `Inspection.visits` or claim all diagnostic fields are identical after changing their meaning.

### 7.4 Govern complex clipping, offsets and Sharp construction

Keep the existing caps while improving how admissible operations are proved. Raising `constructionBytes` or removing `admitClip` is not the proposed repair.

The bundled Clipper allocates output nodes, vertex arrays, containers and offset intermediates before returning. A post-operation vertex check does not bound transient memory. Audit `clipper.engine.cpp`, `clipper.offset.cpp`, headers and caller-owned input/output capacities before widening admission.

Selected route for expanded complex/Sharp/outline admission:

1. Introduce a contained **operation-local resource governor** in the vendored clipping boundary. Cover raw/array allocation, container capacity, generated output nodes, offset buffers and nested cleanup Boolean operations. Pass the context explicitly through the Bands clipping calls; keep unrelated Brush/other Clipper callers on their existing behavior. Test nested and concurrent operation isolation. No process-global `new` interception or allocator replacement.
2. Charge current/peak coexistence and bounded processing/intersection events, not only cumulative bytes. Generated offsets need preflight accounting for actual corner/arc production plus cleanup work.
3. Propagate budget failures through exception-safe native wrappers. Unwind partial structures and release reservations; do not convert allocator/Clipper failure into a successful empty region.
4. Keep Sharp's EvenOdd normalization, miter limit, offset-family nesting, inward collapse, progress/density/scale accuracy and current fixed random channels intact.
5. Replace blanket pair estimates only for operations whose allocation/work envelope is actually governed or conservatively proved. Retain current conservative admission elsewhere.

**Gate:** if the complete allocation/work path cannot be governed with a small auditable change, do not expand those operations' admission. Ship/describe only the geometry classes proven safe; full high-resolution Sharp/outline qualification remains incomplete. Do not introduce an unreviewed general allocator framework to force the milestone.

### 7.5 Boundary preview and publication

`visitOutlines` is its own operation with its own limits. Qualify Rounded normalization/tube construction and Sharp endpoint reuse separately from placement queries. A valid high-resolution field is not proof that every requested outline fits the display budget.

Preserve the current staged publication/failure policy. Required successor presentation is staged before installation; a boundary-preparation failure retains the prior complete result and identifies the display phase. Do not silently hide boundaries, disable masks or publish a partial result to conceal an error. Changing optional-overlay failure policy would require a separate explicit design decision.

### 7.6 Caches and dependencies

Keep the existing prepared-field key authoritative for evaluated geometry/transform/time, units, Band ranges, corner mode and required source/curve inputs. Build classification/index data once per immutable prepared geometry, shared by its Bands. Do not resample or rebuild the index once per candidate/Band, and do not rebuild static fields on selection, panel browsing or unrelated animation.

An export-provenance marker is not a geometry cache key or proof that a modified path is simple. Re-evaluate relevant changes through the existing dependency path. Material/identification edits retain their existing appearance/publication boundaries.

## 8. Capacity and accuracy targets

| Boundary | Proposed treatment |
| --- | --- |
| Paint canonical input | Preserve existing 200,000-vertex maximum and untouched document codec |
| Band input | First qualify existing **8,192 total sampled vertices**, shared across paths/contours; do not promise 8,192 per loop or raise this cap by habit |
| Dense reference fixtures | 720, 721, 1,000, 2,000, 4,000 and 8,192 total samples; above-cap cases must reject completely |
| Construction/retained bounds | Preserve existing 256 MiB construction, 128 MiB retained and 64 MiB bookkeeping allowances until measured reviewed changes justify anything different |
| Aggregate live/staged fields | Preserve 512 MiB accounting across retained and successor fields; include indexes/governor storage and old/new overlap |
| Other existing field caps | Preserve 32 Paths, 64 Bands, membership/output/level/query/work limits unless separately assessed and qualified |
| Outlines | Preserve 32,768 emitted segments, 50 million work and 128 MiB operation allowance; qualify output complexity independently |

Support is by **geometry class + operation + measured budget**, not an unconditional knot-count claim. Simple Rounded evaluation, Sharp construction and outlines get separate acceptance rows. Narrow Bands, steep curves, many offset levels or highly intersecting paths may still require more work than the bounds permit.

For optimized exports, retain an error ledger: reduction error + Max float/frame publication error ≤ requested export tolerance. Band tessellation/quantization and Sharp coordinate uncertainty are additional errors relative to the exported path. Near a support boundary any geometry change can change membership. Export error relative to a narrow Band width can also materially affect normalized progress; warn with validated provenance rather than claiming original-Paint parity.

## 9. Implementation phases and gates

| Phase | Work and likely files | Exit gate |
| --- | --- | --- |
| P0 — Characterize/freeze | Current export/field/probe sources, synthetic dense S-shape plus two islands, Exact round trips, Clipper allocation map, budgets and hardware/toolchain receipts | Reproduce old thresholds; record Paint bytes/frame/publications; settle proof obligations and export/governor caps before code changes |
| P1 — Export numerical core | Proposed `include/spline_export.h`, `src/spline_export.cpp`, focused native tests and CMake registration | Deterministic bounded reduction; continuous error and topology checks; original spans preserved; exact fallback on uncertainty |
| P2 — Export host/UI integration | `brush_host.cpp`, unified template, approved UI rows/generator tests, generated script/help | Final Max float certificate; captured valid owner; one node/Undo; original Paint unchanged; Exact/Optimized metadata cannot be confused |
| P3 — Rounded preparation fast path | `spline_bands.cpp/.h`, geometric classification/index helpers | Narrow proof passes differential geometry/sampling tests and the 720/721 threshold reproductions; dense simple paths reach declared tested capacities |
| P4 — Query indexing | Native region/segment index, field statistics and tests | Full result parity against linear reference, conservative pruning, bounded/accurate accounting and measured high-resolution benefit without small-path regression |
| P5 — Governed clipping/Sharp/outlines | Contained Clipper boundary/vendor changes, allocation/work faults, `visitOutlines` | All participating allocations/work bounded and unwound; Sharp/outline semantics/accuracy preserved; expanded admission only for governed cases |
| P6 — End-to-end Max 2027 | Owned fixture/harness, actual generated controls, exported splines assigned to another layer, lifecycle/resource campaigns | Mandatory matrix below passes on the exact final script/native pair; no export-induced Paint/publication changes |
| P7 — Documentation/delivery readiness | Maintained artist guide, geometry limits, current backlog/ledger, generated metadata and affected website chapters | Truthful mode/support/error descriptions; scoped reproducible receipts; qualified package only if subsequently authorized |

P1/P2 and P3 can be developed as independent review slices after P0. They converge for end-to-end tests. P5 is required for any high-resolution Sharp or outline claim beyond the conservative path. Do not bundle unrelated source-clearance, Physics, renderer, licensing or website-design changes.

Keep existing pure numerical tests, field failure/reservation tests and `tools/foundation_validation` seams. New host orchestration should reuse the owned-profile launcher and serialized request transport; require current-request completed assertions, not only transport success or an optional log file.

## 10. Native test matrix

These are proposed stable scenario IDs; no new pass is claimed by this document.

| ID | Fixture / action | Required result |
| --- | --- | --- |
| EXP-01 | Dense rectangle with exact redundant points | Large reduction with identical boundary, closure and topology; Paint encoding unchanged |
| EXP-02 | Smooth closed curve, dense S-ribbon and two circular islands | Certified complete-boundary error; islands/corners maintained; useful reduction |
| EXP-03 | Ring seam rotations/reversed input winding | Deterministic documented anchoring; no seam artifact; geometric/topological equivalence within tolerance |
| EXP-04 | Nested holes, small islands, thin necks and touching contours | No hole/component/containment loss, new crossing or narrow-feature collapse; retain detail when unsafe |
| EXP-05 | Large scale, shear, mirror, translation and unit changes | World-space tolerance survives final Max-float/frame conversion or rejects without publication |
| EXP-06 | Repeated candidate removals over a long arc | No accumulated error: every result certified against original spans |
| EXP-07 | Degenerate/nonfinite data, impossible tolerance and exhausted work | Bounded truthful fallback/failure; no leaks or partial result |
| EXP-08 | 200,000-input boundary | Bounded memory/work; safe reduction/retention, no unbounded all-pairs behavior or guaranteed target count |
| EXP-09 | Attached boundary crossing faces/folds | Nonplanar/protected parts remain exact; permitted chord stays on certified receiver domain |
| BAND-01 | 720/721 and 1k/2k/4k/8192 simple Rounded samples | No old all-pairs rejection for proved cases; correct inside/outside distances and declared cap behavior |
| BAND-02 | Low-resolution previously accepted scenes | Exact occupancy/contribution order/progress/uncertainty/source/scale/seed decisions and full placement fingerprints preserved |
| BAND-03 | Disjoint/nested holes, winding and loop order | Existing EvenOdd semantics preserved; duplicate cancellation/contact cases use correct fallback |
| BAND-04 | Bow-ties, overlapping/retraced edges, collinear contacts | No unsafe simple classification or lost original Rounded distance segment |
| BAND-05 | Index versus linear reference at edges/endpoints/horizontal rays | Exact per-segment result semantics; conservative pruning and bounded visit accounting |
| BAND-06 | Very narrow/steep Bands; Consecutive/Independent; Empty/source mixtures | Existing precision/underfill/rejection and random-domain contracts retained |
| BAND-07 | Sharp concavity, acute/reversal corners, holes and inward collapse | Offset/nesting semantics and independent progress/density/scale oracles remain within current accuracy |
| BND-01 | Simple/dense Rounded and Sharp outlines, selected/all Bands | Correct contours/error bound and explicit output/work cap; no placement-derived shortcut |
| BND-02 | Many near-overlapping paths and offsets | Measured bounded allocation/work or clear preflight rejection, not late unbounded allocation |
| RES-01 | Fail source/candidate/index/governor allocation at each stage | Previous valid Field queryable; reservations and partially allocated structures fully released |
| RES-02 | Live field + staged successor + retained consumers | Aggregate cap includes coexistence; sharing not double-charged; final-owner release correct |
| RES-03 | Budget overflow, allocator failure, Clipper error and valid empty erosion | Distinct truthful outcomes; failure never mislabeled as successful empty geometry |

Keep a linear geometry evaluator and independent analytic/high-resolution references in tests. A new fast path must not compute its expected answers using itself. For optimized output, compare to its certified geometry and original error/topology contract; do not demand unchanged placements after deliberately assigning a changed path.

## 11. Max 2027 integration and physical tests

Use fresh owned profiles/scenes and matched modules; record script fingerprint, native/managed hashes and loaded paths. Do not install into or reset the artist's working session. Use simple Standard-material leaf cards for redistributable tests, plus real supplied assets only where available and appropriate. No Max 2024/2026 launch/build is part of this scope.

| ID | Actual workflow / event | Required witness |
| --- | --- | --- |
| MAX-01 | Paint/Erase a dense S-ribbon and two islands, then export Optimized | Counts/certificate correct; original encoded document, receiver, falloff and current scatter publication unchanged |
| MAX-02 | Export Exact, reimport unchanged terrain within generic limits or guarded attached snapshot | Existing coverage and chosen closed-receiver side restored within their respective supported paths; Exact behavior unchanged |
| MAX-03 | Reimport Optimized, including closed-surface ambiguity | Ordinary geometric-import contract; no accidental restoration of hidden unsimplified coverage; original Paint changes only after explicit import |
| MAX-04 | Assign exported Exact and Optimized splines to another layer's inside/outside Bands | Both workflows work within qualified limits; new layer has intended sources; original layer/area preserved |
| MAX-05 | Keep dense Exact path; test 1k/2k/4k/8192 samples | Higher-resolution processing works independently of export optimization for each qualified geometry/operation class |
| MAX-06 | Wide/narrow Bands; Rounded/Sharp; range/curve/source changes | Existing semantics, adequate precision diagnostics and deterministic repeat; no silent tolerance increase or source reassignment |
| MAX-07 | Nonuniform transform/mirror, mm/cm/m save/reopen and copied path | Physical export tolerance and existing Band distance contract retained; stale certificates not trusted |
| MAX-08 | Export Undo/Redo with an unrelated Undo sentinel | Only exported node/history changes; Paint and completed placement fingerprints unchanged; no lost prior history |
| MAX-09 | Cancel, export failure, delete/paint owner while options open, switch layers/controllers | No partial node, stale-owner export, stuck dialog or wrong-area mutation; next valid export succeeds |
| MAX-10 | Dense path edit → failed construction/preview → Undo/retry | Prior complete field/publication retained; all owners recover coherently; no reservation leak |
| MAX-11 | Manual/Live export and later explicit Band edits | Export never solves placements; pending Manual stays pending; relevant Live Band changes follow existing scheduling |
| MAX-12 | Save/reopen/merge exported nodes and scenes | Geometry/metadata/policies persist correctly; no live dependency on source Paint or temporary files |
| MAX-13 | Show/Hide field/boundary previews; shared paths; unrelated selection/time | Correct outline failure scope; no unchanged solves/uploads; changed geometry invalidates its consumers |
| MAX-14 | Repeated export/delete/Undo/Redo and scene reset/reopen | One callback/UI lifetime, bounded native retention and correct release with legitimate history/render pins |
| PHY-01 | Real mouse/keyboard export controls at available 100/150/200% scale | Readable distances/status, correct units/focus/owner, usable narrow panel and clear mode selection |

Drive actual generated handlers and real event-loop callbacks. Direct primitive/function calls are useful supplemental tests, not substitutes for UI lifecycle evidence. Distinguish configured scale probes from actual physical DPI/monitor tests and mark unavailable hardware as unqualified.

## 12. Performance, evidence and acceptance

Use frozen equal-input scenes and sequential baseline/candidate runs. Measure export capture/reduction/proof/host construction separately; measure Field classification, construction, queries and outlines separately. Record cold/warm p50/p95, sample counts, work counters, native peak/retained bytes and relevant process commit. Stage timings are inclusive; redraw timing is not presented FPS.

Acceptance requires:

1. Original Paint bytes/binding/settings and existing placement fingerprints unchanged by export, success or failure.
2. Complete final-geometry error/topology validation for every optimized result; no tolerance escalation or hidden exact/optimized metadata confusion.
3. Dense accepted Rounded fixtures pass without the old blanket-pair rejection; high-resolution Sharp/outlines are claimed only after their own governor/accuracy gates pass.
4. Existing accepted geometric/sampling results retained on unchanged paths, with any deliberately extended accounting fields clearly versioned/documented.
5. Measurable high-resolution query benefit and no reproducible small-path or warm-passive-work regression outside the calibrated noise envelope.
6. Memory/work/output bounds proven before expanded admission; resource faults retain old results and recover without clearing Undo.
7. Actual Max 2027 end-to-end, lifecycle and available physical-input witnesses from the exact final pair.

Store source/fixture hashes, scenario IDs, assertion outcomes, measured results and limitations in a fresh ignored run directory. Preserve the earlier failure reproductions. Missing SDK/asset/device evidence is **not run/blocked**, not a pass. Current CTest/Python totals are context, not acceptance substitutes.

Existing future verification commands include generator consistency/approved layout, `tools/procedural_lab/check_generated.py`, focused native/CMake tests, `build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q`, and `offline_build.py --project scatter --year 2027` with a fresh output directory. New export/geometry and host-scenario commands are added/documented during implementation; none were run for this planning task.

## 13. Versioning, persistence and delivery boundary

- Planning changes no version. Before implementation delivery, assess the complete new export workflow and geometry support under [the version policy](../../Release_Versioning.md#choosing-the-next-version); select a distinct successor without replacing delivered 0.86.8.2 artifacts.
- Preserve schema 59, recipe 8, canonical Paint encoding, layer/source IDs and existing asset revisions unless a reviewed persistent contract truly requires a change. Transient export options do not justify a scene-schema bump.
- Preserve the Exact two-argument native entry point. The new optimized entry point, diagnostics and metadata need explicit bounded contracts and matching script/native capability checks. Assess Brush conversion and spline capability increments together; update generated assertions/catalog/help coherently. No new MCP mutation permission is implied.
- Maintain Exact snapshot compatibility; optimized informational metadata has its own version and cannot activate the old coverage decoder. Do not add retired scene migration paths.
- After implementation, update artist instructions for mode choice, physical tolerance, exact/optimized reimport and qualified high-resolution classes. Update affected website source/imports within authorized scope while preserving its current direct-EXE packaging policy; built/published website state remains distinct.
- A later authorized testing delivery includes the exact qualified Max 2027 MZP and matching package/hash/host guards, with **Scripting → Run Script**, then restart instructions. Packaging, installation, commit/push and live deployment are separate authorized actions; this plan performs none of them.

## 14. First implementation slice

Start with P0, then a bounded vertical slice: **planar dense Paint → optimized independent spline → final Max-float certificate → another layer's Rounded Band**, alongside the unchanged dense Exact-path regression through the new simple Rounded preparation path.

Review that slice before widening topology classes, attached-surface optimization or Sharp/outline admission. The complete delivery must identify exactly which geometry/operation gates passed. The original Paint and working scene remain untouched throughout planning and isolated qualification.

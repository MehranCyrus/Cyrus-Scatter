# Six-refinement implementation plan

Prepared 22 October 2026. **Planning only: implementation has not started.**

## 1. Outcome, order and scope

Implement the six requested refinements in this order:

1. **R1 — Surface Analyzer compatibility and delivery.**
2. **R2 — Optimized Paint spline exports.**
3. **R3 — High-resolution spline Bands.**
4. **R4 — Reusable UI and lifecycle regression coverage.**
5. **R5 — Maintainability improvements with unchanged behavior.**
6. **R6 — Library source selection and material access.**

Each refinement has its own tests and completion gate. R4 consolidates and
extends the test infrastructure; it does not postpone necessary R1–R3 tests.
R5 uses the qualified behavior produced by R1–R3 as its comparison baseline,
including their intentional new capabilities. It must not revert those changes
to reproduce the original 0.86.8.2 behavior.

**Original Paint remains unchanged.** Export reads a captured copy and creates
an independent spline. It must not simplify, resample, replace, re-encode or
otherwise mutate the canonical Paint document, receiver bindings or falloff.
Assigning the new spline to a Band and explicitly updating that consumer is a
separate artist action. Optimized geometry may change that consumer's placements
within its declared geometry-error contract; export itself changes no existing
placements.

All new SDK builds, native tests, host automation, performance measurements and
physical interaction in this program target **3ds Max 2027 only**. Historical
2024/2026 qualification retains its original identity. Use owned disposable
profiles/scenes and preserve the artist's running session and original files.

This plan joins and orders existing work rather than replacing its detailed
engineering arguments:

- [Analyzer compatibility investigation](../surface-analyzer/COMPATIBILITY_REVIEW_20261022.md).
- [Paint export and high-resolution Bands design](../spline-bands/PAINT_EXPORT_AND_HIGH_RES_PLAN_20261022.md).
- [Maintainability and lifecycle plan](../code-quality/IMPLEMENTATION_PLAN.md).

The user's current six-item order governs sequencing. The linked geometry plan
owns detailed proof obligations; the linked quality plan supplies additional
test cases. Website redesign, a shared Variation layer, physics, new collision
semantics, renderer expansion, general curved-surface Bands, library asset
authoring and an unrestricted codebase rewrite are outside this program.
Necessary artist/install documentation follows each proven change. The earlier
website lifecycle/type-cleanup track remains a separate scope; this plan does
not silently resume it.

## 2. Baseline and evidence

| Item | Baseline / applicability |
| --- | --- |
| Branch and HEAD | `codex/workflow-0.75`, `3d387550cacf37fe1aeae7a01455f7644d9cf08b` |
| Scatter | 0.86.8.2, schema 59, recipe 8, calculation model CyrusUnified2 |
| Native interfaces | Placement 2, procedural publication 4, spline Band 10, Brush conversion 1 |
| Analyzer | Independently labeled 0.14; installed/package identity differs from current repository source |
| Authoritative UI | `AminScatter/tools/ui/templates/` and generator modules; generated script alone is not an editable authority |
| Current delivery evidence | [0.86.8.2 report](../source-clearance/DELIVERY_08682.md); counts and older host results apply only to those artifacts |
| Workspace | Pre-existing Arrange, Physics, website, knowledge, private assets and planning changes; preserve them |

No tracked Scatter or Analyzer product changes were present when this plan was
prepared. Recheck all tracked and untracked scope before implementation; other
work continues in this workspace.

The recent Analyzer investigation reproduced the screenshot's exact exception
using copies of the installed Analyzer pair in a private Max 2027 process.
The old script lacks `analysisCurrent()`; its native module lacks
`cyrusAnalyzerInputValidity`. The existing Max 2027 MZP contains that old script.
A current-source Analyzer build passed its native executable, and the current
pair passed 31 bounded host assertions. These results establish a focused
compatibility path, not a delivered replacement installer or comprehensive UI,
Undo, merge, renderer or long-session qualification.

The Bands investigation reproduced conservative scratch rejection for simple
dense paths: a 720-sample circle passed and 721 failed; a four-point rectangle
passed while its 1,024-point subdivision failed. The current clipping estimate
is `edges * (edges + 1) * 512 + 2 MiB`. This is an admission estimate, not an
observed allocation failure. The detailed geometry plan preserves the receipt.

Knowledge generation
`7bd37979ae4e3c242694fde44943d7ec54cfe6236112ce00c7d01bae18751fbc`
passed full verification of its 48 enrolled parents during planning. Retrieval
of `requireCurrentAnalyzers` returned F12 with its full historical limitations;
the newer dated Analyzer investigation supplies the subsequent bounded witness.
Implementation, new reports and plans were inspected directly where enrollment
does not cover them. This plan does not refresh or activate an index.

### Critical implementation seams

| Concern | Existing source to inspect/change during implementation |
| --- | --- |
| Analyzer calculation, freshness and UI | [Analyzer script](../../../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms), [native bridge](../../../CyrusSurfaceAnalyzer/src/bridge.cpp), [CMake](../../../CyrusSurfaceAnalyzer/CMakeLists.txt) |
| Analyzer package/install | [installer](../../../CyrusSurfaceAnalyzer/installer/install.ms), [startup](../../../CyrusSurfaceAnalyzer/installer/CyrusSurfaceAnalyzerStartup.ms), [package builder](../../../tools/build_max.py) |
| Scatter integration and authored commands | [unified template](../../../AminScatter/tools/ui/templates/unified-core.ms): `requireCurrentAnalyzers`, `lineInputs`, `exportPaintSpline`, source controls and publication stages |
| Paint geometry/export/import | [brush_host.cpp](../../../AminScatter/src/brush_host.cpp), [brush.h](../../../AminScatter/include/brush.h), [brush.cpp](../../../AminScatter/src/brush.cpp), [brush_atlas.cpp](../../../AminScatter/src/brush_atlas.cpp) |
| Bands preparation, admission, queries and outlines | [spline_bands.cpp](../../../AminScatter/src/spline_bands.cpp), [spline_bands.h](../../../AminScatter/include/spline_bands.h), [host extraction](../../../AminScatter/src/spline_field_bridge.inc), [Clipper vendor source](../../../AminScatter/third_party/clipper2) |
| UI composition and lifecycle | [approved rows](../../../AminScatter/tools/ui/approved-layout-rows.cjs), [generator](../../../AminScatter/tools/ui/generate.cjs), [lazy pages](../../../AminScatter/tools/ui/lazy-pages.cjs), [main UI template](../../../AminScatter/tools/ui/templates/approved-main-ui.ms) |
| Library source import and browser | [recipes.ms](../../../AminScatter/tools/ui/templates/recipes.ms): `CyrusModelMerge`, captured browser context; [LibraryGallery.cs](../../../AminScatter/ui/LibraryGallery.cs) |
| Material/display reuse | [material_preview.inc](../../../AminScatter/src/material_preview.inc), [mesh_display.inc](../../../AminScatter/src/mesh_display.inc), template `procDisplayLayerKey`, `CyrusRenderNodeChanged` |
| Native readability targets | [source_clearance.cpp](../../../AminScatter/src/source_clearance.cpp), publication/display helpers only after characterized seams |
| Host isolation/transport | [private_host.py](../../../tools/procedural_lab/layer_editor_071/private_host.py), [run_generation.py](../../../tools/native_placement/run_generation.py), [current Relax driver](../../../tools/clearance_relax_08682/host.py) |

## 3. Contracts for every refinement

Apply [F01–F12](../../ENGINEERING_FOUNDATION.md), reading required behavior and
verification limits separately. The current schema is 59 even where historical
foundation evidence describes an earlier schema.

1. Preserve ordered layer ownership, receiver-bound Paint Areas, stable source
   row/layer/receiver/candidate identities, and source correspondence. Names,
   UI row positions and SDK handles alone are not persistent identities.
2. Preserve independent radius/clearance scopes, Count admission before conflict
   preference, protected/preferred/layer/candidate priority, quota/refill rules,
   source lotteries and conditional stability under Relax and quota changes.
3. Manual pending placement edits wait for an explicit calculation. Relevant
   Live dependencies update through current scheduling. Display-only actions do
   not consume pending placement settings. Preserve documented cold/structural
   reconstruction and publication-Undo exceptions.
4. Stage compatible rows, sources, radii, statistics and display before atomic
   installation. Failed successors retain the preceding complete result and
   recover on a valid retry. A post-commit observer failure must not cause a
   false partial rollback.
5. Keep host API access, material/editor interaction, spline construction,
   publication and Undo on the host thread. Numerical work consumes owned
   native data. No new asynchronous scheduler is required.
6. Declare owner, invalidation, work limits, peak old/new coexistence, Undo and
   failure behavior before implementing each slice. No process-global allocator
   override, unbounded polling, Undo clearing or forced full GC as a repair.
7. Compare full ordered identities, source/receiver choices, transforms, radii
   and relevant reasons. Counts alone do not establish parity. Use independent
   geometric/specification oracles as well as frozen characterization results.
8. Preserve schema 59, recipe 8, canonical Paint encoding and internal class IDs
   unless a reviewed persistent change proves necessary. New export APIs and
   metadata require explicit capabilities; they do not automatically require a
   scene-schema change or broaden MCP mutation permissions.

### State and resource ownership

| Operation | Owner / invalidation | Undo / failure / release |
| --- | --- | --- |
| Analyzer publication | Analyzer; relevant input/settings/time | Explicit Analyze owns guide mutation; failure retains cache; Scatter never implicitly Analyzes |
| Optimized export | Captured Area/document revision; one native operation | One new independent node in one Undo; original Paint read-only; scratch released on every exit |
| Prepared Band field/index | Immutable native field under existing key/consumers | Old and staged field coexist within admission; failure retains old publication; final consumer releases |
| UI page/request | Current valid captured owner plus view/request generation | Closing/rebinding cancels stale view work; no late write into a replacement owner |
| Source visibility | Captured existing scene nodes | One Undoable explicit batch; preserve original renderable flags; no automatic hide/unhide on close |
| Material access | Existing assigned material; Max editor owns editing UI | Opening does not assign/copy material; actual artist edits use Max's normal Undo; no long-lived Scatter hold |

## 4. R1 — Surface Analyzer compatibility and delivery

### Intended result

Install a current matched Analyzer pair in a disposable Max 2027 profile, restart
that owned host, and use all existing Scatter Analyzer channels without the
missing-script exception. Retain the separate distinction between software
compatibility and stale guides that need explicit recalculation.

### Implementation steps

1. Freeze the reproduced old payload and current source hashes. Preserve the
   old `0.14` MZP unchanged. Promote the private compatibility reproduction into
   a maintained fixture with exact expected failure and retained-result checks.
2. Select an independent Analyzer patch version under the
   [version policy](../../Release_Versioning.md#choosing-the-next-version).
   Align native description, CMake/package identity, UI help, manifest and
   documentation. Remove misleading `0.5`/`Schematic v0.4` release labels while
   preserving plugin class IDs and supported saved parameter identities.
3. Build the current script/native pair. Package both freshness support and
   `cyrusAnalyzerInputValidity`; do not ship the new script alone. Verify the
   required methods/primitives through a bounded post-restart host probe and
   manifest/hash checks rather than a caption comparison.
4. Replace Analyzer's hard-coded installer-year substitutions with explicit
   target-year/version/native-identity inputs in its own package path. Scope
   qualification to 2027; preserve historical builders/artifacts as needed.
   Do not run the full builder if it would regenerate/package unrelated Scatter
   work. Reuse existing packaging helpers through a narrow Analyzer-only entry.
5. Stage the complete runtime before switching startup/plugin registration.
   Keep immutable native directories, verify copies, preserve the previous
   registered pair on failure, and require restart. Test repeat installation,
   unavailable/locked files and registration failure before exposing the package.
   Include an existing older startup/registration in the owned profile: verify
   startup precedence loads exactly the new script/pair rather than allowing an
   older script to redefine the plugin afterward.
6. Improve Scatter's missing-API status with actionable wording: install the
   compatible Analyzer package and restart Max. Keep stale-guide wording as
   Analyze first, then Update scatter. Label the existing button/help clearly
   as guide recomputation; it must not download/install or silently Analyze
   during cached reads.
7. Document independent installation next to current Scatter install guidance.
   If Scatter wording changes, regenerate from authoritative templates and
   qualify/package that changed Scatter pair separately. An Analyzer-only
   update does not require relabeling unchanged Scatter binaries.

### Max 2027 acceptance

| ID | Scenario | Required result |
| --- | --- | --- |
| R1-M01 | Old Analyzer pair + current Scatter | Exact missing-interface failure; old complete Scatter result retained |
| R1-M02 | Fresh disposable installation → restart → inspect loaded paths/hashes; both mixed old/new combinations | Current pair actually loaded; mismatched pairs fail explicitly without partial publication |
| R1-M03 | Actual Layout picker, Select, Analyze button and channel controls | Correct owner; usable status; Border/Centerline/Points/Single/Edge Row assignment works |
| R1-M04 | Analyzer line/point Area masks and boundary falloff | Correct bounded filtering, deterministic repeat and source assignment |
| R1-M05 | Manual Analyzer pending edit + unchanged Scatter read + changed successor | Cache remains usable; changed successor rejects stale guides; explicit Analyze/Update recovers |
| R1-M06 | Relevant geometry/parent/parameter/animation versus unrelated edit/idle | Relevant Real-time update settles; unrelated activity does no Analyze; Manual remains pending |
| R1-M07 | Analyze, Undo/Redo and unrelated Undo sentinel | Authored settings/guides/freshness restored coherently; no lost earlier history |
| R1-M08 | Fresh/pending and old-Analyzer-authored scenes: save/reopen, copy and merge with same-name nodes | Settings/output preserved where supported; unprovable freshness becomes stale; saved-unit identity correct; no name-based rebinding or implicit Analyze |
| R1-M09 | Invalid solid/nonplanar/deleted input, then valid recovery | Clear failure; previous guides and Scatter publication retained; no repeated idle retries |
| R1-M10 | Repeat install, simulated wrong-host guard, copy/registration failure | Correct rejection/rollback and complete pair; no mixed startup binding; no older Max launch |

**Exit:** native tests, actual UI/lifecycle rows and disposable installer/restart
pass on final exact artifacts. Publish a scoped receipt and runnable Max 2027
MZP when implementation delivery is authorized. Continuously curved receiver
analysis, a new analysis algorithm and general orientation-independent Scatter
area masks remain outside this compatibility fix.

## 5. R2 — Optimized Paint spline exports

### Intended result and UI

Keep **Painting → Export spline**. Add a compact options view with
**Optimized / Exact snapshot**, physical **Maximum deviation**, Create and
Cancel. Suggest Optimized for qualified planar exports; keep attached curved
Paint Exact by default until a surface-domain proof is qualified. Proposed
initial deviation is editable **1 mm**, displayed in scene units; calibration
may revise that suggestion before delivery. Never increase tolerance silently.

Show original/output knot counts and a truthful certified bound or Exact
fallback reason. Counts are not an optimization target. Keep the existing
two-argument native export as Exact; introduce an explicit bounded optimized
entry/options contract and matching conversion capability.

### Native and host steps

1. Snapshot the canonical contours, selected coverage/receiver/frame and source
   document revision/fingerprint. Capture the export owner before opening UI;
   revalidate it immediately before committing. A newly selected Area must not
   replace a stale captured owner accidentally.
2. Implement an iterative deterministic C++ closed-polyline simplifier over
   copied data. Proposed seams are `include/spline_export.h` and
   `src/spline_export.cpp`; keep numerical contour arrays in native storage.
   Do not add a modifier to the source Paint or rely on Max Optimize Spline as
   a second production engine. Its documented knot/angle controls do not supply
   this program's world-error/topology certificate.
3. Preserve correspondence from each candidate chord to its **entire original
   span**. Remove exact redundancies safely, then accept approximate removals
   only after continuous bidirectional boundary-error validation. Avoid
   accumulated error from comparing only against already simplified neighbors.
   Deterministic closed-ring anchors must not create seam artifacts.
4. Prove topology separately: component/hole count, containment, contacts,
   meaningful orientation, useful corners, narrow passages and no new crossings.
   Use bounded conservative broad-phase queries and robust predicates. If a
   removal is uncertain, retain detail; deviation alone does not prove topology.
5. Measure error in the full world metric, including nonuniform scale/shear.
   Validate the final single-precision Max knots under the published node
   transform, budgeting float/frame error within the requested deviation.
   Reject Optimized when requested accuracy cannot survive publication. An
   explicitly identified Exact fallback retains its existing precision contract;
   never present it as satisfying an unachievable optimized tolerance.
6. Initially qualify planar contours. Attached nonplanar portions remain Exact.
   Any later coplanar-patch reduction must prove the whole chord stays on the
   receiver domain and protect face transitions/folds; coplanar endpoints alone
   are insufficient. General surface-curve fitting is not required here.
7. Preserve Exact AppData `0x8661`, geometry-hash and chosen-side restoration
   rules exclusively for Exact snapshots. Optimized output may use a distinct
   informational provenance record, never a hidden original-coverage decoder.
   Reimport of optimized geometry follows ordinary geometric-import rules,
   including closed-surface ambiguity and current import capacity limits.
8. Admit input/candidate/index/proof/output allocations together and bound work.
   Retain the canonical 200,000-vertex input limit. Start calibration with the
   detailed plan's proposed 64 MiB scratch and 50 million reduction-work ceilings;
   treat these as design values requiring peak measurements, not proven limits.
   Budget exhaustion stops reduction; complete final validation is still required
   before a truthful reduced/Exact result is published.
9. Construct one independent spline only after numerical validation. Use one
   short host Undo command. On cancel/stale owner/allocation/construction failure,
   leave no partial node or Paint edit and release every temporary allocation.

### Preservation witnesses and Max 2027 tests

Before/after each export capture encoded Paint bytes, receiver/binding identity,
falloff/settings, layer/source IDs, existing placement fingerprints and epochs.
These must match on success, cancellation and failure. Explicit later Paint
import is a separate mutating command and must not be triggered by export.

| ID | Scenario | Required result |
| --- | --- | --- |
| R2-M01 | Dense painted S-ribbon plus two islands → actual Optimized export controls | Useful reduction where safe; correct independent node; original Paint and publications unchanged |
| R2-M02 | Exact terrain and guarded attached snapshots | Existing geometry/metadata and supported exact restoration unchanged |
| R2-M03 | Holes, small islands, narrow necks, contacts and useful corners | No topology loss; retain detail when reduction is unsafe |
| R2-M04 | Nonuniform/mirrored/sheared/large transforms and mm/cm/m fixtures | Final published geometry satisfies physical tolerance or rejects cleanly |
| R2-M05 | Attached curved/folded receiver | Exact fallback; no chord cutting through the receiver or false optimization claim |
| R2-M06 | Export options open → switch/delete/paint owner, cancel or stale callback | Correct captured owner or explicit stale-context rejection; no wrong-Area export |
| R2-M07 | Export Undo/Redo with a prior unrelated sentinel | Only the exported node/metadata removed/restored; Paint and placements unchanged |
| R2-M08 | Optimized reimport and edited/modified exported spline | Ordinary import; no hidden unsimplified-coverage restoration or trusted stale certificate |
| R2-M09 | Repeated export/delete/history/reset and injected publication failure | Bounded scratch/history retention; no partial nodes; next valid export succeeds |

Also reopen/merge the exported-node fixtures using their saved system units and
compare both original Paint bytes and exported geometry/metadata. The new spline
must not depend on a temporary file or on the continued existence of its source
Paint Area. Unit-rescale support remains bounded by F10; saved-unit reopening is
not evidence that arbitrary Paint/Edit binding rescaling works.

Native tests additionally cover ring rotations/reversal, continuous error against
original spans, degeneracy/nonfinite data, precision limits and 200k-input work
exhaustion. Use independent analytic/topology checks, not the simplifier itself
to compute expected results.

**Exit:** export is independently useful and bounded, with final-geometry
certification and byte-identical original Paint. R2 can finish before R3 by using
small Bands/geometry fixtures; high-resolution Band support is not claimed yet.

## 6. R3 — High-resolution spline Bands

### Intended result

Bands must accept qualified dense valid paths independently of Paint export
optimization. An artist may keep an Exact dense export or supply a path from
another tool. Preserve geometric/sampling results for previously accepted,
unchanged input; improved admission and diagnostic accounting are intentional
changes and need separate evidence.

### Native steps

1. Reproduce the old thresholds and freeze Rounded, Sharp and outline reference
   results. Record evaluated sample counts rather than visible knot counts:
   Bezier curves can tessellate densely, especially for narrow Bands.
2. Add a narrowly proved simple-region classification to Rounded preparation.
   For eligible rings, avoid the unnecessary quantized union used only to
   establish nonempty filled geometry. Retain original floating-point segments
   for Rounded distance semantics, their order/origin and existing rejection
   of invalid/zero-area cases. Prove both original and quantized topology.
   Initially permit simple disjoint rings; add holes only after containment/
   parity proof. Duplicate, touching, self-intersecting, retraced, collapsed or
   ambiguous input uses the bounded conservative path.
3. Build an immutable conservative segment index once per prepared geometry.
   Use it for nearest-segment and ray-crossing queries without changing the
   existing per-segment expressions, threshold comparisons or tie handling.
   No index rebuild per candidate or Band. Keep a linear evaluator in tests.
4. Separate node traversal, evaluated segment work, construction operations and
   logical query diagnostics. Define counter meanings before changing admission.
   Bound both index traversal and narrow-phase work; do not hide cost by merely
   changing what the old visit counter counts. Check conservative bounds around
   endpoints, horizontal rays, exact boundaries and floating-point uncertainty.
5. For complex normalization, Sharp offsets and outlines, introduce an
   **operation-local allocation and work governor** at the contained clipping
   boundary. Audit raw/array allocations, `make_unique`, vector capacities,
   output paths, offsets and nested Boolean operations. Charge simultaneous
   peak allocations, allocator overhead and old/staged outputs. Allocation
   control alone does not bound intersection-processing work.
6. Keep the governor context confined to Bands calls. Shared Clipper users such
   as Paint must retain their existing behavior. No global `new` replacement
   or shared hidden thread state. Preserve vendor notices and add focused fault
   tests for every governed unwind path. Until coverage is complete, keep
   conservative admission for that operation; do not raise constants as a fix.
7. Qualify `visitOutlines` separately. Current publication stages required
   presentation before installation; an outline failure must retain the prior
   complete result with an accurate phase/error. Do not silently disable
   boundary display, publish partial output or change overlay-failure policy.
8. Keep existing dependency keys authoritative: evaluated shape/transform/time,
   units, ranges, corner mode and relevant source/curve settings. Provenance from
   R2 is informational, not a geometry cache key or simple-topology proof.
9. Report the actual failure class: input cap, normalization/offset work,
   scratch, retained aggregate, query or outline output. Valid empty erosion
   differs from failed construction. Give useful corrective guidance without
   claiming the artist must simplify every high-resolution spline.

### Capacity and measurement gates

| Resource | Initial requirement |
| --- | --- |
| Field input | Qualify the existing **8,192 total sampled vertices across the field**, not per loop/path |
| Reference sizes | 720, 721, 1k, 2k, 4k and 8,192 total; above-cap rejection remains complete |
| Field counts | Preserve 32 Paths, 64 Bands and other level/output/membership limits |
| Field memory | Preserve 256 MiB construction, 128 MiB retained, 64 MiB bookkeeping and 512 MiB aggregate accounting until measured review justifies changes |
| Outlines | Preserve 32,768 emitted segments, 50 million work and 128 MiB operation allowance |
| Index/governor | Include their memory and old/new coexistence; avoid double-charging genuinely shared storage |
| Performance | Measure construction, queries and outlines separately; equal-input serial baseline/candidate runs, cold/warm p50/p95 and bounded memory/work |

Support is a combination of geometry class, operation and budget. Simple
Rounded evaluation, simple Sharp preparation and outlines require separate
qualification. Highly intersecting shapes or many offset levels can still
reject within finite bounds. Unmet Sharp/outline gates remain open; they cannot
be described as completed by a passing Rounded fixture.

### Native and Max 2027 tests

| ID | Scenario | Required result |
| --- | --- | --- |
| R3-M01 | Dense Exact spline at the former 720/721 threshold and 1k/2k/4k/8192 totals | Qualified simple paths no longer hit the old blanket estimate; total cap remains explicit |
| R3-M02 | Previously accepted scene, same seed/path/settings | Full IDs, transforms, source/scale choices, membership/progress and contribution order preserved |
| R3-M03 | Rounded/Sharp, wide/narrow ranges and acute/concave corners | Current geometric accuracy and nesting semantics; no silent tolerance escalation |
| R3-M04 | Holes, winding, duplicate/touching rings, bow-ties and retraced edges | Correct EvenOdd/ambiguity behavior; no unsafe fast-path admission or lost distance segment |
| R3-M05 | Consecutive/Independent ranges, Empty/source mixtures and curves | Existing assignment, density, scale, Count/refill eligibility and underfill rules |
| R3-M06 | Field/boundary preview selected/all Bands, output and work exhaustion | Correct outline or complete retained prior publication; no hidden display fallback |
| R3-M07 | Relevant spline edit/animation versus browsing/unrelated animation | Consumer invalidates as required; static prepared fields and buffers reused otherwise |
| R3-M08 | First/later allocation, clipping, index and publication failures | Old result queryable/visible; reservations released; valid retry succeeds |
| R3-M09 | Shared paths, staged successor, Undo/Redo, save/reopen/merge/reset | Correct ownership/identity and bounded legitimate retained resources |
| R3-M10 | Paint → Exact/Optimized export → different layer's inside/outside Band → Update | New consumer follows its independent spline; original Paint/layer unchanged |

Native differential tests compare indexed and linear queries at adversarial
boundary cases; independent analytic oracles check distance/progress and offset
semantics. Compare full accepted outputs, not only the appearance of an outline.
Preserve old rejection receipts and report intentionally changed work counters.

**Exit:** declared dense geometry/operation fixtures pass within bounded work
and memory, unaffected inputs retain results, and the combined R2→R3 artist
workflow passes on the final matched Max 2027 pair.

## 7. R4 — Reusable UI and lifecycle regression coverage

### Intended result

One maintained scenario runner can reproduce current ownership, history,
publication and resource transitions without reconstructing dated campaign
directories. A missing result cannot pass. Preserve earlier receipts and port
R1–R3 assertions without silently dropping their coverage.

### Harness and suite architecture

1. Add shared helpers under proposed `tools/quality_validation/`: `host.py`,
   `results.py`, a versioned scenario manifest and grouped MAXScript fixtures.
   Reuse the existing isolated launcher and UUID transport. Keep diagnostic
   execution outside public MCP and shipping payloads.
2. Each result carries run/request/scenario IDs, fixture/build/script/native/
   managed hashes, loaded paths, prerequisite state, required assertion IDs,
   terminal completion and evidence paths. Validate **pass / fail / blocked /
   not run** separately. Transport `SUCCESS` and an optional log are insufficient.
3. Negative-test the harness with absent/stale/wrong-request results, truncated
   logs, duplicate assertions, early return, caught assertion errors, missing
   assertions, crash and timeout/late completion. Observe unresolved requests
   before any new mutation; never replay a potentially executed command.
4. Verify process/profile ownership before reset/load/close. Bound startup and
   settling by explicit state/counter completion. Keep failed and incomplete
   evidence, including input seed and a minimal reproduction where possible.
5. Drive actual generated handlers, native control notifications and the real
   mount/page/bind/status timers. Direct helper/native calls and manual `.tick()`
   calls are supplemental; they do not certify queued UI behavior.
6. Partition fast checks, focused host smoke, fault/resource campaigns and
   physical input. Use risk-based combinations instead of every setting's full
   Cartesian product. Include a deliberately pending Manual recipe in passive
   action tests so accidental calculation cannot hide behind equal output.
7. Read existing passive counters separately: calculation epochs, candidate/
   receiver preparation, map sampling, geometry/instance/appearance upload and
   live reservation counts. Observation must not secretly prepare/solve.

### Mandatory current Max 2027 matrix

| ID | Action / transition | Required witness |
| --- | --- | --- |
| R4-M01 | Cold mount, all pages restored open, collapse and reopen | Correct controls/values and valid owner; cold costs recorded separately |
| R4-M02 | Queue page/bind/status work, switch A→B→A, then dispatch | Latest valid owner; no stale writes or extra Manual solve |
| R4-M03 | Nested handler rebuilds/removes its own page; injected bind failure | No stale rollout continuation; action flags and next interaction recover |
| R4-M04 | Close/delete/reset/open while mount/bind/status work is pending | Old queues/timers retire; no late write into a replacement scene/owner |
| R4-M05 | Delete → Undo/Redo, copy/merge same-name nodes, script reload | Correct stable identities; one callback lifetime; no duplicate handlers |
| R4-M06 | Source multiselect, Point/model conversion and replacement | Row policies/identity preserved; correct owner and Undo grouping |
| R4-M07 | Clearance scopes, preference, Relax and Between layers controls | Independent inheritance/priority; no free-thunk exception; Boundary-only distance enabled |
| R4-M08 | Actual factor/gap edits and Hide surface at narrow panel width | Correct hit targets/values; no caption overlap or unintended node creation |
| R4-M09 | Container and Scatter views, Library destination switches/minimize/reopen | Same authored model; correct captured destination; retired scans/dialog references |
| R4-M10 | Active Brush across close, owner change, deletion and scene replacement | Correct session cancellation/retirement; no late Paint or wrong-Area edit |
| R4-M11 | Manual pending edit + unrelated Undo; structural/preset Undo; Live edit | Each documented history/publication policy preserved; no blanket Manual assumption |
| R4-M12 | Schema59 save/copy/merge and supported schema58 upgrade Undo/Redo | Correct identities/defaults/history; original file preserved; unsupported formats fail explicitly |
| R4-M13 | Admission, later-owner staging, script install/commit-tail and observer faults | Atomic retention/rollback before commit; coherent committed result after observer failure |
| R4-M14 | Warm browsing, selection, unrelated animation and appearance-only edits | No unnecessary solves/preparation/uploads; affected appearance work measured separately |
| R4-M15 | Bake/PFlow/render start/end with pending Manual state | Full output/source mapping and render pins preserved; preview caps do not trim output |

Add the existing quality plan's independent native/stateful clearance oracles:
scope equivalence, Count-before-preference, protected conflicts, stale blockers,
dormant sources/suffixes, cleanup/refill, XY/3D thresholds and hard budget edges.
Extend existing tests rather than creating a second acceptance engine.

Run physical mouse/keyboard checks for R1–R3 and clearance/history controls at
available 100/150/200% UI scaling and narrow panel widths. Distinguish configured
logical scale from actual display DPI, and child-window width probes from real
Modify-panel configuration. Unavailable monitors/tablets/renderers remain
unqualified. Keep B05 cold container Undo and B21 panel-performance acceptance
open unless their actual original triggers are reproduced and resolved.

Perform at least 100 bounded mount/owner/history cycles and a 30-minute mixed
scene/display resource campaign before shared lifecycle refactors; tune these
planning sample sizes after baseline measurement. Track legitimate Undo/render/
editor pins and compare settled plateaus, not raw process memory alone.

**Exit:** the harness fails every deliberately incomplete case; mandatory
scenarios have current request-bound evidence; the same runner reproduces R1–R3
without lost assertions. Product defects uncovered by characterization are
reported separately instead of silently repaired or blessed as new baselines.

## 8. R5 — Maintainability with unchanged behavior

### Freeze the correct baseline

Freeze the qualified post-R3 source/generated/native/managed tree, accepted
intentional changes, fixture hashes, dirty-tree scope and R4 results. A commit
caption or historical pass is insufficient. Keep characterization and independent
correctness oracles separate. Any unexplained mismatch blocks that refactor slice.

### Refactor slices

1. **Native clearance readability.** Start in `source_clearance.cpp`. Expand dense
   statements, name effective-policy compilation, prefix admission, priority
   settlement, stale-hint reconsideration, cleanup and refill advancement.
   Preserve arithmetic/branch order, stable sorting/ties, traversal order,
   exact threshold comparisons and work charging. Keep `CompiledClearance`'s
   `Plan` reference within the existing solve lifetime. No container replacement,
   new cache, acceptance rewrite or new collision policy.
2. **Appearance/display ownership.** Extract small named compatibility decisions
   inside `material_preview.inc`/`mesh_display.inc`: source geometry, instance
   streams, material/opacity/texture preparation and sharing. Preserve keys,
   weak references, LRU limits, release thread/timing and history/render pins.
   Keep private `.inc` context where justified; do not force a public framework
   merely to reduce file length.
3. **MAXScript organization.** First extract one coherent section of
   `unified-core.ms` through **build-time text assembly at its original location**.
   Candidate: source-clearance authoring or publication staging/restore. Preserve
   declaration order, plugin locals, forward declarations and rollout closure
   scope. The initial extraction must produce byte-identical final generated
   runtime text/fingerprint under identical generation settings. Update source
   locators to their real new authoring files rather than retaining false lines.
4. Add deterministic assembly checks for missing/duplicate/reordered fragments
   and generated-only edits. After the byte-identical extraction is qualified,
   evaluate any method cleanup as a separate reviewable slice with R4 parity.
   Inventory exception purposes; do not indiscriminately remove catches or add
   forced refresh loops to simplify control flow.
5. Keep responsibility and lifetime maps beside maintained architecture guidance:
   owner → dependency → staged data → commit → consumers → release. Document
   intentional precision/order constraints at the relevant code, not in a new
   abstraction layer. Every changed function must have a clear failure boundary.

### Per-slice acceptance

| ID | Verification | Required result |
| --- | --- | --- |
| R5-M01 | Same fixtures and toolchain, before/after full solve | Ordered identities, source/receiver mapping, full transforms/radii/reasons equal |
| R5-M02 | Serial/parallel, repeat solves, clearance/Relax/refill state sequences | Existing deterministic and independent-oracle results preserved |
| R5-M03 | Actual owner switches, generated controls and pending Manual state | Same UI/Undo behavior; no new invalidation or scope/free-thunk defect |
| R5-M04 | Faults before/after publication, history and final-consumer release | Same rollback/commit semantics, resource ownership and recovery |
| R5-M05 | Initial template extraction | Generated runtime bytes equal; new authoring provenance accurate |
| R5-M06 | Cold/warm equal-input performance and settled resource measurements | No reproducible regression beyond calibrated noise; same limits/reuse behavior |

Tests must not derive expected results through the same newly extracted solver
helper. Full result parity and resource/counter comparisons are primary; line
count, coverage percentage and stylistic ratings are supporting observations.
Avoid combining a new expectation, behavior correction and refactor in one diff.

**Exit:** each selected boundary is easier to follow and passes its independent
review, parity, failure and relevant host checks. This is a bounded first cleanup
of named responsibilities, not a promise that every module has been rewritten
or that an arbitrary numerical quality score has been reached.

## 9. R6 — Library source selection and material access

### Intended artist workflow

After **Add to selected layer**, the artist can identify the imported source,
select it, explicitly show/hide it, and open its assigned scene material.
Editing that material affects its normal scene instances. The library's packaged
MAX files, catalog, previews, manifests and shared content store remain unchanged.

Current import deliberately hides the source and sets `renderable=false`.
The existing **Select sources** toolbar command selects valid nodes but does
not unhide them. **Merge model** has a separate visible/renderable scene-merge
contract. Preserve those existing actions.

### UI proposal

Add a compact **Source access** disclosure to Models & Points near the object
name/Pick object controls, before source calculation settings:

- Keep the existing Select sources toolbar icon and improve its tooltip to say
  selection does not change visibility.
- Add **Show sources** and **Hide sources** for the captured valid model nodes.
- Add **Edit material** for exactly one valid model with an assigned material.
  Its tooltip says it opens the assigned scene material in Slate; no copy or
  reassignment. Point, Empty, deleted/missing nodes, no material and ambiguous
  multi-selection disable this action with concise status.
- Show bounded source/material identity and hidden-state feedback. Explain
  shared-material effects without requiring a scene-wide scan on every UI bind.

Use text controls sized through the shared generator. Test real narrow widths;
do not add another unexplained tiny toolbar icon or crowd the radius controls.

### Ownership, commands and invalidation

1. Resolve selection from captured layer/source-row IDs and actual node handles;
   deduplicate nodes. Revalidate owner membership and node validity after calls
   that can select another object, open Slate or rebuild/unmount the panel.
   Catalog model ID is provenance and is not a unique scene-node identity.
   Never resolve by display name or silently act on the newly selected layer.
2. Implement Show/Hide as one short Undoable batch over those nodes. Preserve
   **each node's existing `renderable` flag** and all other host visibility/render
   properties. Ordinary scene sources and Merge model nodes may be renderable.
   Do not unhide a layer/group, thaw objects, alter global category filters or
   frame/change the camera automatically. Report remaining layer/group/frozen
   restrictions honestly; unhide alone cannot guarantee viewport visibility.
3. Capture previous flags and validate the complete batch before mutation. On
   command failure, restore only the captured nodes/flags through the existing
   host hold policy. Never leave a hold open while an editor/dialog is active.
   Do not automatically hide sources again on page close or scene selection.
4. Open the **actual assigned material**, including a Multi/Sub root, without
   guessing a submaterial, replacing it, copying it, creating defaults, changing
   render mode or overwriting Compact Material Editor sample slots. Prefer
   `sme.Open()` plus `sme.SetMtlInParamEditor` as the bounded Slate integration;
   verify that path in Max 2027 before finalizing it. Autodesk documents direct
   parameter-editor access in its [SME interface reference](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Interfaces/Core-Interfaces/Core-Interfaces-Documentation/S/GUID-7E144C67-4F97-4A2A-924E-711870C7DF6E.html).
   That API documentation is a design input, not a Max 2027 execution witness.
5. Reuse the editor's material representation where supported; do not accumulate
   duplicate Slate nodes/views, clear artist graphs or change editor preferences
   to make repeated invocations appear clean. Opening is a presentation action;
   actual material edits retain Max's normal material Undo semantics.
6. Reuse existing consumed appearance keys, weak dependency watchers and bounded
   material cache. Pure appearance edits refresh affected consumers while
   retaining placement IDs/transforms and pending Manual settings. Unconsumed
   parameter changes do not rebake unchanged consumed appearance. Shared material
   edits can affect other Scatter sources/layers and ordinary scene objects;
   communicate this expected instancing behavior.
7. Do not impose a blanket zero-solve rule when the same map also drives a
   placement-density input or another genuine calculation dependency. Preserve
   existing Manual/Live scheduling for that separate role. Measure geometry,
   instance, material-partition and texture updates separately rather than
   assuming every material change has identical resource cost.
8. Retain `CyrusModelMerge`'s verification/rollback: declared single node,
   exact catalog scene hash, bounded graph/maps, missing-dependency rejection,
   one import hold and captured-node cleanup. New source-access actions neither
   remerge assets nor write into the content store. No Save to Library or new
   asset revision system is included.

### Max 2027 acceptance

| ID | Scenario | Required result |
| --- | --- | --- |
| R6-M01 | Actual library Add → Models & Points → Select sources | Correct imported node selected; hidden/renderable state and source policies unchanged |
| R6-M02 | Show/Hide imported, ordinary and Merge model sources | Only captured node hide flags change; original renderable flags preserved |
| R6-M03 | Mixed/multiple selections; Point/Empty/missing material | Defined enabled states; no accidental partial material selection or new material |
| R6-M04 | Edit material on hidden Standard and Multi/Sub sources | Assigned material instance/root opens; no unhide, assignment, copies or slot overwrite |
| R6-M05 | Shared material across layers and ordinary scene objects | Expected shared appearance changes; unrelated materials/placements remain reusable |
| R6-M06 | Consumed diffuse/opacity/map edit versus unconsumed parameter | Correct appearance refresh and counter deltas; no application of pending Manual placement edits |
| R6-M07 | Same map used for appearance and density; relevant animation/rewind | Both dependency roles obey existing Manual/Live policies; no broad unrelated invalidation |
| R6-M08 | Switch/delete/reorder source/owner during queued action or editor opening | Correct captured identity or clean cancellation; no wrong-source action |
| R6-M09 | Visibility Undo/Redo, material Undo/Redo, save/reopen/merge | Existing row IDs/material assignments/flags and prior Undo sentinel preserved |
| R6-M10 | Missing bitmap/unsupported material, source deletion and valid retry | Clear supported-scope status; existing material/publication preserved; no stuck UI |
| R6-M11 | Repeated open/close/select/edit/delete/reset with editor and history pins | Bounded watchers/resources; no duplicate handlers/views; legitimate editor/Undo references accounted |

Include physical mouse/keyboard selection and material edits, available renderer
materials/leaf opacity, and comparison of Textured mesh with exact output where
the renderer is installed. Unavailable shader plugins are explicit unmet scope,
not a reason to claim universal material editing/preview compatibility. The
standard-material suite must be reproducible without private plant assets.

**Exit:** the artist can reach and edit an imported source's scene material
without searching hidden objects manually, with scoped visibility/history and
appearance updates. Shared library assets are byte/hash unchanged and existing
import, source clearance, Paint, placement and output behavior remains intact.

## 10. Ordered execution and delivery gates

| Milestone | Work, in requested order | Gate before moving on |
| --- | --- | --- |
| M1 — Analyzer | R1 characterize old/current payloads → package/identity cleanup → owned installation/restart → actual UI/lifecycle tests | Matching separate Analyzer package, usable integration and preserved stale-guide contract |
| M2a — Paint export | R2 freeze Paint invariants → native simplifier/proof → host/UI/Undo → focused Max2027 tests | Certified independent export; original Paint unchanged on every exit |
| M2b — Bands | R3 classify/admit → query index → governed complex/Sharp/outlines → combined export/consumer workflow | Declared high-resolution classes pass; old accepted results preserved; finite failures retain old result |
| M3a — Regression infrastructure | R4 standardize fail-closed runner → migrate focused scenarios → add missing UI/history/failure/resource/physical coverage | Required current scenarios and negative harness cases complete with exact identities |
| M3b — Maintainability | R5 freeze post-geometry baseline → one native slice → one byte-identical template extraction → affected final-pair campaign | Reviewable responsibilities, exact parity and unchanged lifetime/reuse behavior |
| M4 — Source/material workflow | R6 captured-source commands → Slate proof → generated controls → appearance/history/lifetime qualification | Usable artist commands; scene-instance editing; unchanged catalog and placement contracts |

Complete R1 before R2, R2 before R3, and so on. Within a refinement, independent
read-only review may help, but shared generated outputs and host mutations remain
serialized. A difficult R3 proof is an explicit open gate, not permission to
skip ahead or call the whole program complete.

The coherent geometry user-testing delivery is M2a+M2b, after the combined
workflow passes. Keep internal slices reviewable without distributing a
partially qualified high-resolution claim. M1 can be delivered independently
because Analyzer has its own version and installer. A later M3 user-testing
binary still needs its own provenance/package even when behavior is unchanged.
M4 adds artist commands and requires a fresh version-impact assessment.

Suggested first implementation action, once authorized: freeze R1's old/current
artifacts and lift the exact missing-interface reproduction into a maintained
scenario, then build the separately identified Analyzer package. Do not begin
by rewriting the analysis engine or the entire host harness.

## 11. Verification strategy and completion evidence

### Tiers

| Tier | Runs when | Evidence |
| --- | --- | --- |
| T0 — generation/pure tests | Relevant source/generator/harness change | Deterministic generated output, ownership/control inventory, result-parser negative tests |
| T1 — native | Numerical, clipping, resource or native-refactor change | Independent oracles, differential parity, limits and fault/recovery executable results |
| T2 — Max 2027 focused host | Every affected UI/integration/publication slice | Actual generated controls, queued callbacks, identity/history and retained-result checks |
| T3 — extended lifecycle/performance | Geometry, shared lifetime and milestone boundaries | Repeated sequences, cold/warm timings, resource plateaus, real assets/renderers where available |
| T4 — physical acceptance | Before relevant artist testing delivery | Real mouse/keyboard, visible controls, available DPI/widths and material/output inspection |

Each scenario needs a trigger, owner/settings, unchanged comparison case,
expected observable, prerequisites, bounded settling condition and assertion
manifest. Record source tree plus dirty scope, toolchain/SDK/Max build, fixture
and asset hashes, loaded module/script paths, result status and failures.
Historical reports are context; copied test code is not an executed pass.

Keep these comparisons distinct:

- **Exact parity:** same environment, unchanged geometry/recipe, ordered full
  publication and result reasons; required for R5 and unaffected R1–R3 behavior.
- **Geometric correctness:** independent distance/topology/receiver witnesses;
  required for intentional R2 output geometry and R3 admissions.
- **Avoided work:** solve, preparation, sampling and upload deltas; equal output
  does not prove reuse.
- **Resource accounting:** unique native retained/peak storage, staged coexistence
  and legitimate history/editor/render consumers; process RAM is supplementary.
- **Presentation:** actual physical inspection; scripted redraw duration is not
  presented FPS and a configured scale is not every monitor's DPI qualification.

Calibrate timing noise using repeated equal-input baseline runs before setting
performance thresholds. Require a measurable dense-path benefit, and reject
reproducible small-path/passive-action regressions outside that envelope.
Record export capture/reduction/proof/host construction and Band preparation/
query/outline timings separately. Avoid simultaneous benchmark hosts that distort
the comparison. No absolute latency or unlimited-count promise is made here.

### Existing future command families

These commands are for later implementation. **They were not run for this plan.**
Use fresh output directories and the documented local toolchain.

```powershell
# From AminScatter after authoritative UI changes
node tools/ui/generate.cjs
node tools/ui/generate.cjs --check
node tools/ui/approved-layout.test.cjs

# From repository root, selecting the affected project/suites
python tools/procedural_lab/check_generated.py --output build/<fresh-run>/generated
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --project analyzer --year 2027 --output build/<fresh-run>/analyzer
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/<fresh-run>/scatter
```

New host scenario selectors, Analyzer-only package commands and optimizer test
targets must be implemented and documented in their owning refinement. Do not
claim an invented future CLI as an executed receipt. Reuse existing focused
native tests in `AminScatter/tests/` and `CyrusSurfaceAnalyzer/tests/`; only
broaden checks when a shared path, failure or unresolved concern warrants it.

### Final acceptance checklist

- All six gates have their exact artifact/fixture identities and explicit
  passed, failed, blocked or not-run scenarios. This plan's proposed matrix
  contains **61 host/host-related scenario rows**; rows may contain multiple
  assertions, and this is not a prediction of a final test-executable count.
- Original Paint bytes, settings, binding and existing publications are unchanged
  by export, including cancellation, failure, history and saved-unit reopen.
- Optimized output has a final published-geometry error/topology certificate;
  Exact restoration cannot be triggered by optimized provenance.
- High-resolution support is documented by qualified geometry/operation/budget;
  resource failures unwind completely and retain the previous result.
- Analyzer installation and loaded payloads match; guide recomputation and
  software update are unambiguous; old scenes cannot gain fabricated freshness.
- UI and source/material actions survive queued owner changes, lifecycle/history
  transitions and supported failures without extra Manual calculation.
- Refactors preserve the post-R3 behavior, arithmetic/order, limits, ownership
  and resource reuse; the initial template extraction is byte-identical.
- Library scene material access preserves packaged asset bytes and normal shared
  material semantics. Source visibility commands preserve renderable flags.
- Required unavailable hardware/renderer/production-scene evidence is stated as
  a qualification limit. No unrelated B05/B07/B21 issue is closed by inference.

## 12. Versioning, documents and authorization boundary

Planning selects no new product version and changes no saved schema. Before each
future delivery, assess the complete user-visible impact under the release
policy, record the independent Analyzer or Scatter version rationale, and align
build/parser/package/generator identities. Preserve delivered 0.86.8.2 and old
Analyzer artifacts/receipts. Do not reuse a label to conceal different payloads.

R2's explicit optimized API/provenance and R3's diagnostic semantics may require
capability increments. Determine them from the final contracts and update both
sides, generated metadata and guards together. Transient export UI and scene
source-access commands do not by themselves justify a schema or recipe bump.
Preserve supported schema58→59 upgrade behavior and reject retired formats.

Update maintained artist, install, geometry-limit, architecture and backlog/ledger
documentation after the corresponding proof. Reconcile F12's older verification
wording with the actual new receipt at R1 completion, without rewriting historic
results. Keep proposed, implemented, offline-tested, host-qualified and artist-
accepted states distinct. Knowledge enrollment/refresh/activation remains a
separately authorized process; never repair hashes merely to make retrieval pass.

For any future Scatter version delivered for testing, include a runnable
**Max 2027 MZP built from the exact qualified script/native pair**. Verify archive
integrity, payload hashes and host/version guards. Analyzer gets its own matched
MZP. Provide **Scripting → Run Script**, then restart instructions. Disposable
installer/restart tests are part of qualification; installing into or restarting
the artist's session requires the user's explicit request.

If website documentation/download sources are later updated, retain the accepted
direct-EXE route and EXE-only release payload policy. A Max MZP can accompany the
local testing delivery without being inserted into the website ZIP. Website
source changes, builds and live publication are separate evidence/actions.

This task authorizes writing this plan only. No plugin code, tests, generated
outputs, configurations, installers or asset files are changed now; no build,
Max session, package, commit, push, installation or deployment is executed.

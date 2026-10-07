# Implementation checklist and acceptance gates

**Implemented successor:** [0.73 completion](../Unified_System_0.73_2026-10-06/TASKS.md), [matching results](../Unified_System_0.73_2026-10-06/RESULTS.md) and [remaining gates](../Unified_System_0.73_2026-10-06/ROADMAP.md). Unchecked items below are the frozen preparation baseline, not current implementation status; wider artist/renderer/resource acceptance remains explicit.

6 October 2026. Prepared implementation sequence; all production tasks below remain **unchecked**. Follow the [requirements](README.md), [port/ownership map](CAPABILITY_PORT_MAP.md) and [container contract](SOURCE_CONTAINER_CONTRACT.md). Never substitute a build/pass count for behavioral evidence.

## Preparation completed

- [x] Gather the user's no-legacy decision and all three container changes: label, linked Modify editing and movement grouping.
- [x] Inspect current generator/model/ownership/container/time-validity/MCP dependencies against the actual generated 0.72 script.
- [x] Identify useful features still relying on old paths and specify port gates.
- [x] Record every current capability family and all 245 semantic controls, including planned merges/retirements.
- [x] Define preservation, dependency, failure and acceptance contracts; retain previous R&D findings as open gates.
- [x] Check official Autodesk helper/reference/hierarchy documentation for the proposed native-node direction; identify the unproven editor adapter.

## 1. Freeze comparison fixtures and field ownership

- [ ] Pin actual source/native/helper identities and create isolated fixtures in the existing ignored test workspace. Use disposable Max scenes/private profiles; no artist installation or computer-use tools.
- [ ] Extend the control register with every persisted field/caller and named comparison cases. Each field has one owner, unit, default, supported range, save/Undo behavior and invalidation class.
- [ ] Freeze deterministic placement/source/transform/radius/statistics/publication digests for existing procedural setups; capture candidate/preparation/Brush/upload counters separately.
- [ ] Capture independent old-feature comparison fixtures for Line/Analyzer assignment and supported point/boundary Relax. Do not turn old schema-load fixtures into new-architecture success claims.

**Exit:** every current control/capability has a disposition; required ports have fixtures and expected results. Normal procedural fixtures supply a before/after oracle. No source deletion starts from a label search alone.

## 2. Consolidate settings and port required capabilities

- [ ] Define the canonical ownership/default/rule fields and normalized input contract over the existing model.
- [ ] Consolidate inherited constant self-spacing and procedural overrides into one three-scope rule editor. Preserve defaults and valid minimum-distance semantics; automatic field saving needs no Apply spacing.
- [ ] Port Line Pattern and Analyzer assignment, including source/group choices, scaling, edge/corner/forward/street options and per-set resolution. Preserve the Analyzer's own cached publication/update policy.
- [ ] Port point Relax in a bounded eligibility-safe stage, then boundary Relax with complete staged collision/eligibility revalidation. Keep unsupported combinations explicit until qualified.
- [ ] Port the existing useful MCP authoring subset to an explicit closed successor schema with a real host adapter. Preserve passive policy-3 reads, enrollment, approval/freshness, budgets, Undo and rollback. Reject old schemas before any mutation; do not silently reinterpret them.

**Exit:** old features have a real new-model execution path, meaningful positive/failure tests and UI/MCP documentation. Placement changes from a deliberately changed Relax contract are isolated and explained. No old-mode dependency remains necessary for a required feature.

## 3. Remove legacy execution and presentation

- [ ] Make procedural the default and sole supported evaluator; remove conversion/upgrade actions and priority arbitration.
- [ ] Remove old-only serialization migrations, duplicate collision/radius/blocker settings and unused UI declarations/factories after checking all callers, including render/export/diagnostics/MCP.
- [ ] Simplify generator stages together with their inputs. Regenerate the script normally; verify deterministic regeneration and matching helper capabilities. Do not patch only the generated `.ms`.
- [ ] Keep useful compatibility-independent internal class IDs/names and native kernel interfaces. No broad rename or Qt/C++ rewrite for appearance.
- [ ] Check all control ownership/help/availability, native rollout layout and warm retargeting. Both Modify and popup write the same owning record; closed/inactive sections do not poll.

**Exit:** a new setup requires no policy switch, the UI contains no obsolete modes/controls and every retained field affects its documented stage. All required ports still pass after deleting old paths. Existing artist files are untouched; development-schema incompatibility is stated clearly.

## 4. Add source-container nodes and linked editing

- [ ] Prove a minimal dedicated container helper/frame adapter and linked editor while keeping the container selected. This is the first feasibility gate, before completing the rest of its UI.
- [ ] Add cached labels, durable identities, dimensions, global/layer/set consumers and explicit shared editing context.
- [ ] Add the rectangle creation/import workflow without silently replacing artist shapes. Handle unlinked/deleted owners, cloning and scene reset safely.
- [ ] Prove no second evaluator, duplicate source settings, strong reference cycle or continuous timer was introduced.

**Exit:** selecting either of two containers on the same editor topic binds the correct controller/layer/set; a shared container exposes its consumers; container dimensions stay editable; selection/topic/label browsing leaves generation, Brush and placement-upload counters unchanged.

## 5. Add transactional palette movement

- [ ] Implement fixed-start transform snapshots, one physical movement owner, frozen drag recipients and bounded commit reconciliation.
- [ ] Handle source exit/re-entry, overlapping containers, global/shared pools, combined selections and supported group/hierarchy movement without double transforms.
- [ ] Preflight unsupported locked/constrained/partial hierarchies; preserve relationships/controllers. Roll back all changes on failure or cancellation.
- [ ] Qualify one-step Undo/Redo, save/reopen, delete/unlink/clone and per-owner source setting retention.

**Exit:** a container translation moves active sources exactly once and leaves existing scattered instances/IDs/Brush/Edit/radius data unchanged for unchanged membership/geometry. A parked source stops following and returns with the same settings. Resize changes inclusion without scaling models. No half-moved state survives an error.

## 6. Run the combined regression and performance matrix

| Group | Required acceptance |
| --- | --- |
| Determinism/publication | Stable ordinals/source IDs, explicit order, repeatability, copy/remove/reorder, scoped blockers, protected edits and all-or-nothing publication. Exact output/export/render use the same accepted publication. |
| Collision/radius/cleanup/refill | Self/sibling/layer scope isolation; XY/3D/contact/zero factors; source/instance radius; protected conflicts; cleanup over the layer union; bounded target shortfall and failures. Use the exhaustive oracle, not implementation-shaped assertions alone. |
| Brush | Flat and curved/folded/disconnected surfaces; editable Paint/Erase/disabled strokes and captured views; density/Area/outside-coverage composition; Undo, geometry denial and ordinary/tiny-coordinate save/reopen. BR-01 remains a gate until diagnosed. |
| Dependencies | Real parameter/geometry/map/receiver/Brush edits rebuild the needed stages; return-to-previous-input reuse remains correct. Manual retains last publication; Live settles after coalesced relevant changes. |
| Idle/UI/animation | Selected/unselected controller/container; popup closed/open, all topics and rapid warm retargets; unrelated animated car versus actually animated inputs; no clean-input solve/Brush preparation/full membership scan or unchanged-buffer upload. Measure host callback receipt separately. |
| Display/resources | Retained Mesh/Point Cloud unchanged-input behavior, Proxy drawing cost, preview budgets, transformed bounds, old/new-generation peak memory, teardown and resource recovery. Report CPU phases and presented FPS separately. |
| Container behavior | Pivot/border/local-XY/height semantics; transform/resize/invalid dimensions; overlap owner conflicts; parked/new/deleted sources; multi-owner settings; hierarchy/double-selection movement; cancellation/failure rollback. |
| Host/renderer | Matching Max 2027 source/binary identities, private scripted host tests, production/floating/docked IR lifecycle, Manual pending output, repeated save/reset/reopen. Max 2026 runtime remains a separate qualification gate. |
| MCP/diagnostics | New closed-schema parity and old-schema rejection; cached inspection cannot solve or reconcile; stale/expired approvals; bounded failure/Undo. Recorder off/on overhead, loss counters and failed exports remain explicit. |

Run the existing relevant native/offline suites and build both intended SDK targets. Add tests for actual port boundaries, failures and invariants. Baseline R&D results were 14 native suites, 140 Python tests and 503 independent collision-oracle cases; those are dated prior results, not evidence that this future cleanup passes.

Real pointer/scroll/DPI/monitor usability and presented-FPS validation require later artist/manual testing under the current no-computer-use constraint. Scripted Max assertions and synchronous redraw timings cannot qualify those measurements. No promise of zero host processing or unlimited FPS is part of acceptance.

## 7. Freeze, document and stop the slice

- [ ] Regenerate/verify the actual control inventory and MCP feature catalog from source. Update artist workflow, ownership, supported combinations, diagnostics and capability docs; preserve historical reports.
- [ ] Freeze source/native/test identities and record exact reproduced results, pending gates and meaningful before/after CPU/resource measurements.
- [ ] Repeat affected regression tests after the final source change. Broaden testing only for changed dependencies, failures or unresolved concerns.
- [ ] Prepare a matching development package only in the later delivery scope; never mix a new script with an older loaded DLL. Installation, version bump and Git delivery are separate explicit tasks.

Licensing code, service plans and artist scenes/profiles remain protected from broad cleanup. ML, GPU placement, a general graph framework, new render workers and unlimited population counts are not bundled into this work. The [earlier CPU/resource/reporting findings](../TyFlow_CyrusScatter_RnD_2026-10-06/FINDINGS_AND_ROADMAP.md) stay visible, but optimizations beyond the required ports remain separate measured slices.

Implementation loop: pin → reproduce → smallest coherent change → affected positive/failure tests → final-change rerun → freeze evidence. Finish each slice against its acceptance rather than continuing an unbounded redesign.

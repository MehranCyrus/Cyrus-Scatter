# Cyrus Scatter code quality and regression plan

Prepared 21 October 2026. **Proposal only: no implementation, new qualification, version change or release is authorized by this document.** The user requested a detailed plan to improve maintainability and missing UI/lifecycle tests while preserving current behavior.

The [23 October review-remediation plan](REVIEW_REMEDIATION_PLAN_20261023.md) checks the four independent reviews against 0.86.8.6, records targeted reproductions and defines corrections for seven confirmed issues. Its [validation matrix](REVIEW_REMEDIATION_VALIDATION_20261023.md) supplements this broader proposal. Neither document implements the product changes.

## 1. Outcome and scope

Make the current system easier to understand, safely modify and verify. Preserve what artists see, save and calculate. The sequence is **characterize → test lifecycle boundaries → restructure small responsibilities → prove parity**.

“Closer to 10/10” means stronger evidence and clearer ownership, not a promise of zero defects. The independent [0.86.8.1 review](../source-clearance/REVIEW_08681_20261020.md) identified dense solver/resource control flow; the [0.86.8.2 review](../source-clearance/REVIEW_08682_20261021.md) retained an approximately 8/10 assessment and limited physical/DPI coverage. Neither review establishes that every subsystem was audited or that current functionality needs rewriting.

Primary scope:

- Scatter native calculation, publication, display-resource lifetime and generated MAXScript authoring/UI orchestration.
- Repeatable native, generated-source and owned Max 2027 UI/lifecycle regression tests.
- Shared test tools, scenario receipts, failure diagnosis and reproducible build prerequisites.
- A separate website track covering its existing React/imperative-controller lifetimes and direct installer download.

Preserve active Physics Lab work, CyrusArrange, private artwork/assets, artist scenes/profiles and unrelated working-tree changes. Analyzer, Licensing and MCP retain independent contracts and versions. Test their existing Scatter integration boundaries where relevant; do not redesign those products or expand MCP mutation authority.

Do not add features, a UI redesign, compiled-component caches, a new scheduler, asynchronous placement, GPU computation, new renderer support or additional scene migrations. Existing B05 cold container Undo, B11 cold realization and B21 panel latency/physical acceptance remain separate backlog items. Testing them does not itself fix them. The standalone Physics Lab is outside this plan.

## 2. Inspected baseline and evidence limits

| Item | Planning baseline |
| --- | --- |
| Branch / HEAD | `codex/workflow-0.75` / `3d387550cacf37fe1aeae7a01455f7644d9cf08b` |
| Scatter contract | 0.86.8.2, schema 59, CyrusUnified2, recipe 8, native placement capability 2, publication capability 4 |
| Current native architecture | Bulk generation/storage/acceptance/preparation already C++; MAXScript retains authored parameters, bounded orchestration and UI |
| Existing delivered tests | Reported 49 CTest suites per matched SDK build, including 40 Scatter and 9 Licensing suites; 176 Python tests; generator/layout checks and focused host scenarios |
| Current website | Existing uncommitted 0.86.8.2 update, static production build, exact-hash direct EXE download and website/EXE-only ZIPs |
| Working tree | Extensive pre-existing Physics and website changes and untracked assets; HEAD alone does not identify the current complete tree |
| Future host scope | **Max 2027 only** by default, including development builds, native qualification and physical interaction. Earlier 2024/2026 receipts remain historical; testing them again requires an explicit user request |

No tests, builds, installs or Max launches were performed for this planning task. Prior passing results retain their original scope. Current source was inspected directly, including templates/generators, native acceptance/publication/display code, test drivers and website lifetimes.

Knowledge full-source verification reported stale generation `c14f3d16e81bcf39ebd488d53bcec1239b522a0de37dcc8a81738bffdcf9be3e`; the relevant search also rejected changed evidence. This plan does not rely on that corpus being current and does not refresh or activate it. The separate RAG retrieval/timeout follow-up remains separate work.

### Current strengths and specific gaps

| Area | What already exists | Improvement needed |
| --- | --- | --- |
| Native clearance | Independent inheritance, Count-before-preference, stale-blocker/dormant-source regressions, bounded work and independent small-scene oracles | Readable stage/state boundaries; preserve and extend stateful regression coverage |
| Publication/recovery | Immutable native generations, complete successor staging, Edit commit last, native allocation/display failure seams | One discoverable failure matrix spanning native and script installation/observer boundaries |
| Generated UI | Authoritative templates, inventory, static layout assertions, lazy factories, captured owners and close cleanup | Durable current-panel owner/queue/reentrancy/teardown tests, beyond selected campaign scenarios |
| Host validation | Owned profiles, exact loaded-path/hash checks and serialized request transport | Parameterized, fail-closed scenario results and fewer dated-path assumptions |
| Appearance reuse | Weak appearance/cache ownership and immutable shared display resources; scoped repeated-edit measurements | Lifecycle/resource tests across destruction, history, scene replacement and shared consumers |
| Website | Content/hash checks, TypeScript/Vite, browser interaction scripts and recent real EXE download checks | Explicit test entry points, repeated route/unmount tests, dialog/focus failures and typed landing-controller boundaries |

Do not describe the project as having no UI or lifecycle tests. The gap is breadth, durability, discoverability and trustworthy completion evidence.

## 3. Behavior-preservation contract

These are acceptance constraints for every implementation slice, derived from [F01–F12](../../ENGINEERING_FOUNDATION.md), the [architecture](../../ARCHITECTURE.md) and current delivery contracts.

1. **Ownership and identity:** layers own populations; Paint Areas remain receiver-bound coverage; source rows own their radius/clearance policies. Keep layer UUIDs, source-row UUIDs, native source correspondence, receiver/variation identity, candidate IDs and display indices distinct. Rename must not become name-based rebinding.
2. **Calculation:** preserve source choices, full transforms, effective radii, admitted/accepted order, reasons, conflicts, shortfall and current limits on identical inputs in the same toolchain/environment. Preserve Count admission before protected/preferred/layer/candidate conflict resolution, effective-rule equivalence and independent scope inheritance.
3. **Numerical/order semantics:** retain floating-point operation order, exact threshold comparisons, cell traversal, stable sorting/ties, cleanup/refill order, dormant-source participation, budget charging and error conditions. A different container, sort or algebraically equivalent expression can change output or rejection behavior.
4. **Manual/Live:** ordinary pending Manual placement edits wait for explicit Update; relevant Live edits follow existing dependencies. Cold reconstruction, structural commands and preset/publication Undo restoration retain their separate existing rules. Do not encode “Manual never changes publication” as a blanket test.
5. **Publication and failure:** keep the preceding complete publication until successor installation succeeds; retain native Edit rollback through the script commit tail. Do not mix epochs/owners or erase the visible result on failure. Post-commit observer errors must not retroactively turn a completed commit into a partial rollback.
6. **Resources and threads:** host APIs/publication stay on the host thread; existing numerical workers consume owned inputs and join. Preserve release timing/thread, weak/shared ownership and required render/history/publication pins. RAII or shared-pointer changes are not automatically behavior-neutral.
7. **UI/persistence:** preserve control labels/order/visibility/enabling, gestures, selection modifiers, action/Undo grouping, saved presentation, schema/recipe/native capabilities, parameter-block/class/callback IDs and supported schema-58 upgrade. Do not add compatibility readers.
8. **Avoided work:** unchanged warm browsing/selection and unrelated animation retain the current zero-solve/zero-unnecessary-preparation/upload guarantees. Distinguish cold realization and changed appearance from unchanged work. Do not introduce polling or expanded invalidation to simplify code.
9. **Website/release:** retain the accepted design, routes, keyboard behavior, content meaning and direct EXE path/hash validation. The website download continues to exclude plant content and MZPs.

If a new test reveals a baseline defect, retain its reproduction and identify expected versus observed behavior. Do not silently fix it as a refactor or approve a new golden result. A correction needs a separately identified behavior decision; unaffected work can continue. A suspected issue, such as the website route animation-frame lifetime, is not a confirmed defect merely because a cleanup looks desirable.

## 4. Measurement and test architecture

### Evidence kept separate

- **Characterization:** frozen input → ordered IDs, source/receiver correspondence, matrices/radii and result/reason metadata. This proves preservation of the baseline, including any known defect.
- **Independent correctness:** existing brute-force/specification oracles and geometric invariants. Do not reuse optimized solver helpers to compute expected answers.
- **Host integration:** actual generated handlers plus real queued callbacks in a matched owned Max 2027 process.
- **Physical interaction:** real pointer/keyboard input, actual DPI/monitor state and viewport presentation, recorded separately from scripted notification tests.

Use exact equality for same-environment parity, including Relax results where deterministic. Use explicitly justified geometric tolerances for receiver support, energy/movement oracles and SDK readbacks. Do not weaken exact parity to accepted-count equality or claim cross-platform floating-point identity.

### Shared scenario record

Each scenario declares an ID, contract IDs, trigger, expected observable, unaffected control case, fixture prerequisites, host/update/display mode, bounded settling condition and timeout. Its result includes request/run ID, fixture hash, source/build/loaded hashes, assertion IDs with outcomes, terminal status and evidence paths. Report **pass / fail / blocked / not run** distinctly.

Observe existing diagnostic counters where possible: solve/preparation/publication epochs, map sampling, geometry/instance uploads, live items/generations, appearance dependencies and reserved memory. Any extra observation hooks must be test-only or passive/bounded, and must not evaluate the scene. Internal flags are useful diagnostics; primary pass criteria remain observable ownership/results/history/recovery.

### Test tiers

| Tier | Scope / intended cadence | Does not prove |
| --- | --- | --- |
| T0 | Generator/inventory, pure Python/JS and website content/types; every relevant change | MAXScript execution or physical UI |
| T1 | Native numeric/parity/fault suites on the prescribed Windows/Max 2027 build configuration | Host callbacks, rendering or GPU presentation |
| T2 | Matched private Max 2027 UI/lifecycle/failure smoke; changes to its boundaries | All DPI/devices/material graphs |
| T3 | Extended state sequences, real supplied assets/Corona where available and bounded resource soaks; shared-path/refactor milestones | Universal leak freedom or renderer fidelity |
| T4 | Physical mouse/keyboard and actual DPI/monitor acceptance; before a relevant testing delivery | Other unavailable hardware or Max versions |

A missing SDK, renderer, asset or device yields an explicit unmet gate, not a green skipped qualification. Avoid a full Cartesian product: use distinct ownership/lifetime transitions, pairwise risk combinations and a few deliberate combined stress scenes.

## 5. Work packages and dependencies

Proposed new test paths below are design destinations, not existing implementations. Reuse current modules first; a shared `tools/quality_validation/` layer should coordinate them, not become a second host-automation framework.

### CQ01 — Freeze the baseline and map responsibilities

**Priority:** first. **Product changes:** none.

- Record Git state and relevant tracked/untracked source hashes; freeze the current website changes as part of the website baseline. Record compiler/SDK/build settings, script fingerprint, native/managed hashes and fixture identities. Preserve original delivered packages.
- Select a small fixture set: two controllers with different layer/source values; multiple layers with scoped relationships; Point/Empty/model rows; planar and curved receivers; supported opacity cards; a shared animated map; a synthetic schema-58 scene. Generate redistributable synthetic fixtures; reference private assets separately without copying them into Git.
- Build an ownership/lifetime map for authored state, candidate/prepared/publication generations, display items, appearance watches, Undo/Redo pins, render pins, timers/scene callbacks, Brush and Gallery tasks. State acquire/invalidate/release thread and last consumer for each.
- Map error handling by purpose: best-effort teardown, optional diagnostics, operation restoration/rethrow and artist-facing recovery. Do not mechanically remove catches or change messages.
- Map affected source to current tests and known gaps. Correct current-versus-historical wording in the eventual maintained docs; for example F11's schema-58 wording conflicts with the current schema-59 header. Historical verification labels remain intact.

**Outputs:** baseline manifest, fixture catalog, responsibility/ID map and scenario coverage matrix under the new test area plus ignored run evidence. **Exit:** another maintainer can identify the owner, current contract and applicable test for every proposed refactor boundary. Baseline failures are classified as product, fixture or environment with their witnesses.

### CQ02 — Make the existing host harness fail closed

**Depends on:** CQ01. **Priority:** before trusting new host tests.

Relevant existing code: [private_host.py](../../../tools/procedural_lab/layer_editor_071/private_host.py), [run_generation.py](../../../tools/native_placement/run_generation.py), [0.86.8.2 host driver](../../../tools/clearance_relax_08682/host.py), current campaign scripts and [foundation validation](../../../tools/foundation_validation/README.md).

- Preserve the existing UUID request transport and its refusal to overlap/replay an unresolved mutation. A timeout remains observation uncertainty until the request/process state is reconciled.
- Parameterize run/output roots, matched payloads and fixture references in shared helpers. Default new runners to Max 2027. Keep historical campaign entry points and receipts rather than rewriting every old script.
- Require a current-request scenario result with expected assertion IDs and a terminal completion marker. Transport `SUCCESS` alone is insufficient: current `host.py` inspects a scenario log only if that log exists, while MAXScript fixtures can catch and log errors internally.
- Validate process/profile ownership and loaded identities before reset/load/close. Bound startup/scenario waits, report process exit distinctly and preserve incomplete results. Only verified owned PIDs may be closed.
- Add harness-only tests for absent/stale/truncated/duplicate results, wrong request/scenario/payload, early return, caught assertion exception, empty assertion set, crash and timeout followed by late completion. Do not rely on elapsed sleeps as proof of completion.

**Proposed paths:** `tools/quality_validation/host.py`, `results.py`, `scenarios.json`, with focused tests under `tools/tests/`. Keep the private diagnostic transport out of public MCP and release payloads.

**Exit:** deliberately broken fixtures cannot return a successful scenario; a complete valid fixture passes; no duplicate host mutation occurs during timeout recovery. One documented entry point can run selected current scenarios without reconstructing dated directories.

### CQ03 — Strengthen native parity, state and publication tests

**Depends on:** CQ01; CQ02 for host portions. **Product changes:** no algorithm changes.

Extend [source_clearance_tests.cpp](../../../AminScatter/tests/source_clearance_tests.cpp), procedural/spacing tests, placement/publication failure tests and relevant existing suites. Keep the 240 single-pass/500 refill oracle cases and explicit F1/F2 regressions; extend their generators instead of duplicating them.

- Add small state sequences that edit one field then restore it: independent scope inheritance, explicit/default equivalence, preference, target deletion/rename, radius/scale, cleanup and accepted-target refill. Compare complete per-owner results and important unaffected populations.
- Exercise exact-threshold distance, XY/3D disagreement, protected-only sources, authorized refill suffixes, dormant cached suffixes and dormant distance values, mixed protected conflicts, empty/zero-count owners and bounded underfill. Respect conditional stability under quotas/Relax.
- Test serial/parallel repeatability and overwrite-safe worker failure fallback through existing execution seams. Do not introduce asynchronous cancellation as part of testing synchronous workers.
- Extend publication failure tests across the staging/install/commit matrix below. Verify retry, pending authored state and unrelated Undo sentinels, not only successful return values.
- Keep `CYRUS_PLACEMENT_QUALIFICATION` allocation faults distinct from `CYRUS_PREVIEW_TEST_FAULTS`. Use guarded test builds and exact-source isolated script-copy instrumentation where appropriate; fail if a fault insertion site no longer uniquely matches.

**Exit:** same-environment ordered outputs and work accounting match the frozen baseline; independent oracles pass; hard limits still reject completely and valid recovery succeeds. No fault controls or diagnostic modules enter shipping packages.

### CQ04 — Add a current generated-UI and lifecycle suite

**Depends on:** CQ02 and CQ03's baseline observations. **Priority:** highest risk reduction.

Source targets: [approved-main-ui.ms](../../../AminScatter/tools/ui/templates/approved-main-ui.ms), [lazy-pages.cjs](../../../AminScatter/tools/ui/lazy-pages.cjs), [approved-layout.cjs](../../../AminScatter/tools/ui/approved-layout.cjs), [unified-core.ms](../../../AminScatter/tools/ui/templates/unified-core.ms) and [LibraryGallery.cs](../../../AminScatter/ui/LibraryGallery.cs).

Reuse current `tools/clearance_relax_08682/checks.ms`, `tools/source_clearance_0868/ui_events.ms`, `host_lifecycle.ms`, `tools/reliability_0870/lifecycle.ms` and relevant library/foundation fixtures. Older `tools/ui-tests/main-rollout-reopen.ms` uses earlier panel assumptions; do not count it as current `mainUI.slots/editors` coverage without adapting a new fixture.

- Drive actual generated controls, then let the real mount/page/bind/status timers and posted notifications dispatch. Direct function or `.tick()` calls can supplement this, but do not substitute for event-loop lifecycle evidence.
- Cover first mount, delayed owner changes, nested refresh, teardown/resurrection, scene replacement and repeated script registration. Include container and Scatter views of the same records, Library captured destinations and active Brush cancellation/retirement.
- Assert current valid owner/page, unchanged unrelated authored fields, correct action/Undo grouping, zero unintended Manual solves and recovery after an injected bind failure. After close, expect quiescent timers and released view references; after reopen, expect one functional set of handlers.
- Add static generator assertions for owner assignment after `addSubRollout`, close cleanup, pending-owner handling, action-context release and field geometry. Keep runtime tests as a separate gate.
- Turn the former Between layers free-thunk exception, source factor/gap overlap, Boundary-only distance availability and hide-surface handler failure into discoverable regressions with original triggers.

**Proposed fixture grouping:** `tools/quality_validation/ui_lifecycle.ms`, `scene_lifecycle.ms`, `history.ms`; reference existing native/managed tests rather than implementing UI logic in the test runner.

**Exit:** all mandatory UI/history/publication scenarios below have current Max 2027 evidence. Warm passive actions leave solve/preparation/unnecessary-upload counters unchanged. Close/reopen and failure/retry do not leave wedged flags, stale owners or duplicate callbacks.

### CQ05 — Refactor native code for readability, one responsibility at a time

**Depends on:** CQ03 and relevant CQ04 scenarios passing. **Product behavior:** unchanged.

First target [source_clearance.cpp](../../../AminScatter/src/source_clearance.cpp), then narrowly scoped helpers in [material_preview.inc](../../../AminScatter/src/material_preview.inc) and [mesh_display.inc](../../../AminScatter/src/mesh_display.inc).

1. Expand dense statements and document state transitions without moving work. Name the invariant around previous-round hints, same-prefix settlement, protected admission, post-cleanup reservations and refill limits.
2. Extract small internal operations where inputs/outputs are explicit: effective-policy/cohort compilation, stable-prefix admission, priority conflict settlement, stale-hint reconsideration, cleanup and prefix advancement. Preserve their existing sequence and exact budget charges.
3. Keep `CompiledClearance`'s reference to its `Plan` within the same solve lifetime. Do not introduce cross-evaluation caching or change API/policy representation merely to shorten signatures.
4. For display reuse, name compatibility decisions and separate source geometry, instance streams, opacity/color appearance and shared material initialization. Preserve exact keys/equality, weak references and immutable shared handles.
5. Leave `.inc` fragments in their implementation unit where shared private/SDK context justifies them. Split a translation unit only after its ownership seam and build impact are understood. Do not replace containers or introduce a general framework under a readability change.

Each slice must be independently reviewable: a local reviewer should be able to explain its state transition and failure path without reconstructing a long compound statement. File length and line-coverage percentages are supporting signals, not acceptance targets.

**Exit per slice:** native parity/oracles plus affected host/fault/resource tests pass; no new public API, serialization, scheduling, lifetime, bounds or reproducible performance regression. A whole-solver rewrite is not part of CQ05.

### CQ06 — Organize MAXScript source without changing runtime scope

**Depends on:** CQ04; can follow CQ05 independently after tests stabilize.

The approximately 7,100-line core mixes authored fields, ownership, invalidation, publication, output and UI. Existing generator/page modules are useful seams. Start with **build-time text inclusion at the original locations**, not new runtime helper files/functions or moved plugin locals.

- Extract bounded coherent template sections with explicit ordering and owner/dependency notes. Candidate areas are publication staging/restore, clearance authoring and lifecycle registration. Pick one initial section; do not split the entire core in one change.
- Have `generate.cjs` assemble exactly the previous text before inventory/layout/container transformations. Preserve declaration and local scope, forward declarations and rollout closure behavior. The original free-thunk exception makes this boundary particularly important.
- Require initial extraction to produce **byte-identical final generated MAXScript**, including normalized encoding/newlines and script fingerprint, with unchanged semantic identities and presentation values. Authoring-file hashes and source locators may legitimately change: update their provenance to the actual new files/lines rather than retaining misleading old references. If runtime text differs, explain and separate the change before acceptance.
- Add dependency/assembly checks for missing or duplicate fragments, accidental reorder and generated-only edits. Keep generation/check mode deterministic.
- Only after a byte-identical structural extraction, consider bounded method cleanup with full CQ04 parity. Inventory exception purposes first; never use blanket catch removal, forced refresh loops or Undo clearing as cleanup.

**Exit:** the authoritative source is easier to navigate, a responsibility maps to a small known section, and generated/runtime identity remains unchanged for the extraction. No new dynamic evaluation, scene callback, polling, owner abstraction or legacy compatibility is added.

### CQ07 — Add website lifecycle tests and remove typing blind spots

**Depends on:** CQ01 website baseline; browser test entry point can proceed alongside plugin tests.

Preserve [the current website delivery](../../../website/verification/WEBSITE_08682_20261021.md). Relevant sources: `website/src/App.tsx`, `components/SelectedLanding.tsx`, `components/landing-controller.ts`, `pages/PlantLibrary.tsx`, `content/release.ts`, `tools/stage_release.py` and `tools/package_site.py`.

- Expose documented unit/browser test commands alongside content checks, typecheck and build. Reuse `website/tools/check_selected_interactions.py` and its known scenarios where practical. Choose and pin one maintainable browser runner during implementation; do not claim a dependency/version decision is already validated.
- Add repeated landing → guide/library/download → landing transitions while playback, observers, local pointer interaction or a dialog is active. Verify one response per gesture, no detached-page writes, cancelled owned frames, disconnected observers, restored SVG/body state and independent local checklist state.
- Cover dialog Escape/cancel/backdrop, focus return, route unmount while open, image failure and category changes. Cover search/mobile drawer focus, back/forward anchors and reduced motion. Visual review uses the accepted cream/green layout at desktop and narrow/mobile widths.
- Characterize rapid navigation around the route-related `requestAnimationFrame` in `App.tsx`; do not silently turn a suspected callback race into a new fix. If cleanup is proven necessary, identify that correction separately.
- Then type the landing controller's environment, DOM helpers, state and disposer/frame collections, replacing `@ts-nocheck` gradually. Extract interaction islands behind the same `mountLanding(root) → dispose` contract only after mount/unmount tests pass. Preserve deterministic SVG inputs and event behavior.
- Add temporary-fixture tests for release staging/packaging: valid identity, size/hash mismatch, unsafe/mismatched path, symlink, unexpected download/binary, failed copy/replace and publication integrity. Use tiny fake installer bytes in isolated fixtures; retain one real-artifact download test.
- Keep real production-preview root/subfolder downloads and exact EXE hash checks. Source-only Vite dev serving is not the download qualification path. Packaging remains website assets plus one main EXE; the separate installer ZIP has exactly one member.

**Exit:** existing interaction/visual behavior remains, repeated mounts do not accumulate work, type suppression is removed from the touched subsystem without broad casts, and malformed release inputs cannot produce an accepted package. No live upload is implied.

### CQ08 — Qualify physical input and repeated resource lifetimes

**Depends on:** CQ04; repeat affected cases on the final matched refactored pair after CQ05/CQ06.

- Use owned Max 2027 profiles, real mouse/keyboard and actual event processing. Record installed/source/loaded identities before every campaign; never use an artist session for reset fixtures.
- Test real typing, spinner stepping/dragging, source multi-selection, Ctrl/Shift behavior, dropdown selection, rollup scrolling/collapse and first mount. Confirm model clearance and layer Relax still edit the intended owner with the same Undo behavior.
- Test actual narrow panel geometry at 100/150/200% UI scale where available; distinguish configured logical-scale probes from physical DPI. A 320-pixel child test host is not a wider artist Modify-panel preference qualification. Mixed-monitor/4K/tablet cases remain explicitly not run when unavailable.
- Characterize the first cold container move, cancel and Undo in a fresh profile. Retain B05 if its acceptance does not pass. Measure B21 cold first-ready, all-open completion and warm bind separately; do not promise a speed improvement from file organization.
- Run bounded repeated owner creation/deletion/Undo, mount/close, display switching, material/radius edits and scene replacement with valid shared consumers. Begin with fixed 100-cycle fixtures, then a 30-minute mixed soak; expand to two hours only at a justified milestone.
- Measure unique live generations/items, appearance dependencies, reservations and history/render pins, as well as process commit. Expect a bounded plateau or the documented remaining references, not absolute zero while legitimate consumers remain. Release the final consumer and verify the corresponding ownership is released without forcing full GC or flushing Undo to hide retention.
- Keep source geometry/maps versus changed transforms/upload counters separate. Relevant forward/backward material animation refreshes appearance; unrelated time changes do not solve static placements. Device loss is a separate targeted gate if a safe controlled test is available; scripted CPU allocation failure does not qualify it.

**Exit:** actual input results, owner correctness, retained/released resources and latency distributions are recorded with hardware/context. No new solve/upload work or reproducible resource growth is introduced. Unavailable physical/renderer coverage remains an explicit limitation, not a reason to broaden product scope.

### CQ09 — Make checks reproducible and maintain the quality record

**Depends on:** relevant earlier packages; final integration gate.

- Publish a short test index: contract → scenario → command → prerequisites → evidence. Keep historical receipts; promote current reusable scenarios rather than copying ignored logs into assertions.
- Establish a fast local gate for generator/Python/website tests, a native Windows gate, owned Max 2027 smoke and milestone physical/resource gates. A licensed SDK/Max/private asset requirement is explicit. Do not claim public CI can qualify unavailable proprietary environments.
- Use path/scenario-based selection for routine work; broad native/shared-owner changes run the wider affected suites. Do not repeatedly rebuild every host/year or run every artist fixture for a local wording change.
- Reproduce the selected gates from a clean checkout plus declared toolchain/private prerequisites after implementation inputs are backed up within authorized scope. Confirm required tracked third-party configure templates, generator sources and fixtures are present; ignored SDKs/content/installers remain separate artifacts.
- Keep generated source/help/catalog and maintained behavior docs aligned. Review current/historical qualifiers, including F11 schema wording, without relabeling earlier results. Knowledge enrollment/activation remains a separate operation.
- When a user-testing binary delivery is authorized, choose its successor version under the [version policy](../../Release_Versioning.md#choosing-the-next-version). Tests/docs alone need no product bump; changed delivered binaries need a distinct successor identity. Include the exact qualified Max 2027 MZP, archive/hash/guard checks and restart instructions. Do not install, push or deploy merely because this plan mentions delivery.

**Exit:** a maintainer can run a relevant regression without reading a campaign history; every claimed pass identifies exact inputs and execution scope; build/package provenance and remaining limitations are clear.

## 6. Mandatory scenario matrix

These are proposed stable IDs. Extend existing test bodies where possible. Each row needs an unaffected comparison and explicit completion evidence; no row below is marked newly passed by this plan.

### Harness and numeric contracts

| ID | Trigger | Required observable |
| --- | --- | --- |
| HAR-01 | Missing, stale, truncated or wrong-request scenario result | Fail closed; no success from transport status alone |
| HAR-02 | Early return, swallowed assertion exception or missing required assertion | Incomplete/fail, retaining diagnostic artifacts |
| HAR-03 | Timeout, late completion and next mutation | Observe the original request; no replay or overlapping mutation |
| NUM-01 | Same input, serial/parallel and repeat solve | Ordered IDs, sources, transforms/radii and reasons equal in the same environment |
| NUM-02 | One clearance scope inherits/overrides; explicit equals defaults | Other scopes unchanged; equivalent result/scheduling/work preserved |
| NUM-03 | Preferred/protected conflict with Count/refill | Count admitted first; protected/preferred/layer/candidate priority preserved |
| NUM-04 | Blocker displaced or removed by cleanup | Previously blocked authorized candidates reconsidered; no ghost reservation |
| NUM-05 | Unused source or unauthorized suffix changes | Dormant data does not change active scheduling/output; metadata validation remains |
| NUM-06 | XY/3D, exact distance, large radius and hard budget edge | Existing inequality, metric, underfill/error and work-limit behavior preserved |
| NUM-07 | Independent small random/stateful scenes | Independent oracle agrees; failures retain seed and minimal reproduction |

### UI, ownership and saved history

| ID | Trigger | Required observable |
| --- | --- | --- |
| UI-01 | First mount; collapse/reopen; all pages restored open | Same values/visibility; interactive owner binding after native initialization |
| UI-02 | Queue body/bind work, switch controller/layer A → B → A, dispatch | Latest valid owner; no stale writes or extra Manual solve |
| UI-03 | Nested handler rebuilds/unmounts its own page | No continuation through stale rollout references; action/edit flags recover |
| UI-04 | Close/reset/delete with mount/bind/page/status work pending | Queues/timers quiesce; late callbacks cannot affect a replacement owner |
| UI-05 | Delete then Undo/Redo restore; open/merge with same-name nodes | Correct identities/publication restored; no name-based or handle-based aliasing |
| UI-06 | Repeat panel mount/unmount and supported script reload | One registration/hook lifetime; no duplicate callback invocation or retained view owner |
| UI-07 | Hold/release real spinner/drag during deferred UI work | Existing deferral behavior; final value and owner exact; bounded recovery |
| UI-08 | Source multiselect, Point/model conversion, source replace, target rename | Per-row policies/identity preserved; untouched fields/layers unchanged; same Undo grouping |
| UI-09 | Toggle Own copies / Other models / Other layers and Relax modes | Independent scopes; Between layers callback works; correct visible/enabled shared distance |
| UI-10 | Narrow factor/gap input and hide-surface actual button notifications | Readable nonoverlapping fields; intended object state, no unintended node creation |
| UI-11 | Container/Scatter views; Library destination changes while open | Views share the correct records; Library action retains its captured destination |
| UI-12 | Active Brush/Library work across close, minimize, owner/scene change | Correct cancel/retirement; no stale task publication; reopening remains usable |
| HIS-01 | Pending Manual edits, unrelated Undo, structural/preset Undo and Live edits | Each retains its documented distinct publication/authoring semantics |
| HIS-02 | Schema59 save/reopen, copy/merge, deleted target and source identities | Authored relationships survive supported operations; caches are not mistaken for saved identities |
| HIS-03 | Explicit schema58 upgrade, Undo/Redo and save/reopen | One Undoable upgrade; preserved IDs/default result; original file retained; no repeated prompt |
| HIS-04 | Malformed/missing dependency or failed import/upgrade | Explicit failure with previous authored work/publication/history intact |
| HIS-05 | Supported save/reopen/merge unit conversions | Radius, extra gap and Relax distances preserve physical meaning; factors/weights remain dimensionless; unsupported Paint/Edit rescaling still rejects as documented |

### Failure, display and physical lifetime

| ID | Failure/event boundary | Required observable |
| --- | --- | --- |
| PUB-01 | Admission/allocation before successor staging | Previous publication/epoch and Undo sentinel intact; no staged mutation escapes |
| PUB-02 | First/later owner staging or display preparation failure | All owners retain the previous complete generation; staged resources released |
| PUB-03 | Script owner installation/commit tail before native Edit commit | Complete rollback of rows/radii/metadata/display/keys and native Edit state; retry succeeds |
| PUB-04 | Post-commit UI/diagnostic observer fails | Completed coherent commit preserved; truthful error/recovery; no false partial rollback |
| DSP-01 | Warm browsing, selection, rollups and unrelated animation | Stable output; zero solve and unnecessary preparation/map/upload deltas |
| DSP-02 | Radius-only, identification, map/opacity, UV and geometry edits | Only documented consumers invalidate; Manual geometry/publication rules preserved |
| DSP-03 | Shared map/source across owners; forward/backward relevant time | Each affected appearance refreshes once as required; no static placement solve |
| DSP-04 | Repeated display/owner/history/scene lifetimes | Bounded unique resources after settling; final-consumer release with legitimate pins accounted |
| OUT-01 | Bounded Bake/PFlow/exact output from the same complete publication | Existing source-frame mapping, full output transforms/counts and Undo behavior match baseline; preview caps do not trim final output |
| OUT-02 | Render start/end with shared display consumers and pending Manual settings | Existing auto-render/update policy and resource pins preserved; finishing a render neither loses the publication nor retains an abandoned owner |
| PHY-01 | Actual mouse/keyboard at supported available DPI/widths | Correct hit targets, values, focus, scroll and Undo; scale provenance recorded |
| PHY-02 | Fresh-profile first container move/cancel/Undo | B05 expected/observed evidence; no silent closure of the known acceptance gap |

### Website

| ID | Trigger | Required observable |
| --- | --- | --- |
| WEB-01 | Repeated route/unmount/re-entry during playback or pointer interaction | No departed-page work, duplicated listener/observer/frame or lost body/SVG cleanup |
| WEB-02 | Dialog Escape/backdrop/unmount and failed image | Correct close/focus/scroll restoration and existing fallback; next interaction works |
| WEB-03 | Fast anchors/back-forward/search/mobile/reduced motion | Correct destination/focus and deterministic illustration; no unexpected queued scroll |
| WEB-04 | Root/subfolder production EXE download | Correct path/name and exact qualified bytes; no content or MZP download introduced |
| WEB-05 | Invalid/missing installer, hash/size/path/symlink or extra payload | Staging/package fails; no falsely verified or partially accepted package |
| WEB-06 | Retained existing desktop/mobile design and library/filter controls | Current appearance/content/keyboard behavior preserved; no overflow or new console errors |

## 7. Performance and resource guardrails

Measure before and after on the same frozen fixtures, compiler, host, display subset and camera. Separate cold first mount/realization from warm binds/updates; report p50/p95 with sample count and machine load. Baseline calibration chooses practical budgets before refactoring, rather than raising thresholds after a regression.

Hard gates are result parity, current bounds, no additional warm passive solves/uploads, correct release ownership and no reproducible growth over identical settled cycles. Timing gates compare against repeated baseline variability; a suspicious increase is rerun under controlled conditions, not dismissed or automatically blamed on the refactor. Do not add inclusive stage timings together or call redraw duration presented FPS.

Record peak old/new generations, scratch, uniquely retained shared buffers, Undo/Redo, render pins and preview reservations separately. Process memory is useful context, not proof of GPU usage or a leak. Keep all existing resource-admission behavior; do not change the one-million candidate limit, retry limits or current settlement/neighbor-visit ceilings as part of cleanup.

## 8. Execution sequence, sizing and review gates

Recommended order:

1. CQ01 baseline, responsibility/error map and concrete case selection.
2. CQ02 result validation and harness negative tests.
3. CQ03 and CQ04 characterization/native/UI lifecycle coverage, with one short vertical slice first: queued source-page owner switch → actual edit → Manual retention → Update → Undo → close/reopen.
4. CQ05 small native readability slices and CQ06 a first byte-identical template extraction, each gated independently.
5. CQ07 website tests/types as a separate track after its current changes are frozen.
6. CQ08 final-pair physical/resource campaign and CQ09 reproduction/documentation closure.

Plan review units around one responsibility or lifecycle transition. Keep harness changes, new tests, native refactors, template extraction and website typing in separate reviewable changes. Avoid combining a new test expectation and a calculation change in the same refactor. Stop expansion once the selected boundary is proven; broaden only for a shared dependency, failure or newly identified risk.

Suggested effort is **roughly 15–25 focused engineering days** for the defined regression infrastructure, first native/template refactor slices and website track, plus hardware/renderer access and soak time. This is a planning range, not a commitment; CQ01/CQ02 should refine it before implementation. A complete audit/refactor of every subsystem or resolving known product defects would be a separate larger scope.

Before implementing each slice, write its owner, invalidation, peak coexistence, Undo and failure behavior. Afterward require an independent diff review and the affected test tiers. When practical, compare baseline and candidate in separate owned hosts using the same input, serialized so machine contention does not invalidate timing evidence.

### Proposed future command families

These are verification instructions for implementation, not commands run for this plan. Use fresh run directories and the documented toolchain.

```powershell
# Existing generator checks, from AminScatter
node tools/ui/generate.cjs --check
node tools/ui/approved-layout.test.cjs

# Existing repository checks, from repository root
python tools/procedural_lab/check_generated.py --output build/<fresh-run>/generated
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/<fresh-run>/scatter

# Existing website checks, from repository root
npm --prefix website run docs:check
npm --prefix website run typecheck
npm --prefix website run build
```

CQ02/CQ04/CQ07 add documented entry points for selected host/browser suites; their exact CLI is part of that implementation. Do not invent an executable command in the evidence before it exists. Build only the matched variant needed for the relevant suite; fault builds stay separate from normal qualified artifacts.

## 9. How quality will be assessed afterward

| Dimension | Evidence required for a higher assessment |
| --- | --- |
| Maintainability | A reviewer can locate the authoritative owner and follow each changed state transition; dense solver/resource paths have narrow documented operations without duplicated engines |
| Ownership/lifetimes | Explicit acquire/invalidate/release map agrees with repeatable owner switching, destruction/resurrection, history and scene replacement evidence |
| Regression protection | Independent oracles, full-result parity and actual generated-handler tests protect the same contracts; a missing/stale result cannot pass |
| Failure/recovery | Faults on both sides of staging/install boundaries preserve coherent output and history; recovery does not require clearing Undo or restarting blindly |
| UI assurance | Current callbacks, narrow geometry, actual input and available DPI have scoped receipts; configured tests and physical qualification remain distinguishable |
| Performance discipline | Warm avoided-work counters and resource plateaus remain; reproducible baseline/candidate measurements detect regressions |
| Reproducibility | Test index, prerequisites, tracked drivers, source/payload identities and clean-checkout reproduction allow another maintainer to repeat the claim |

Reassess by dimension after completed work, using **source-inspected / offline-tested / host-tested / physically-qualified** labels and remaining gaps. Do not award 10/10 from a test count, smaller files or a successful release alone. The practical target is that a new maintainer can understand one responsibility, change it safely and prove the artist's result and recovery behavior stayed intact.

## 10. Planning completion and next decision

This task produces this plan only. Product source, generated outputs, version metadata, packages, installed sessions, knowledge binding and Git history remain unchanged by the planning work. Existing website and Physics changes are preserved.

Recommended first implementation scope, if authorized later: **CQ01–CQ04's baseline/harness plus the queued-owner-switch vertical slice**, then review its reliability before expanding tests or starting refactors. This reduces the highest lifecycle risk first and gives subsequent cleanup a credible behavior-preservation gate.

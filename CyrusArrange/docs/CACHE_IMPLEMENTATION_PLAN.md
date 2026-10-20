# Implementation plan: reusable native furniture/query bundle

This plan was written against 0.1.2, which is now qualified and immutable. Working 0.1.3 implements it; the [runtime contract](CACHE_RUNTIME.md) describes current code and the [qualification ledger](RELEASE_VALIDATION_0.1.3.md) binds executed evidence. The post-WSM correction passes native37's general/appearance/inspector gates and native39's complete 1182-assertion boundary suite. The working default is now enabled, pending a fresh candidate's complete functional/performance/installer qualification. No measured cache speedup or final release qualification is claimed yet. The design reasoning and primary-source recommendations below remain separate from executed evidence.

## Recommendation

Reuse **one immutable raw furniture-inspection result plus one immutable furniture/obstacle fit query** per setup. Admit at most four retained entries globally. Start with same-time reuse: seed/rule/composition rerolls, repeated Preview and Preview→Commit at the same scene time are the useful first workloads. Do not initially promise reuse across different animation times, asset-source capture reuse, material reuse, retained output-node mutation, shared caches across setups or persistent disk caches.

This is a performance extension. It does not require another document/library schema: keep the new 4/2 persistence formats and put cache ownership/stamps outside `DocumentState`, `Lifecycle` and Undo restore snapshots. Native scene behavior and full-result publication remain authoritative.

## Current call path and implemented split

`src/arrange_bridge.cpp` currently executes:

1. The explicit command establishes native lifetimes, flushes hierarchy events and starts `DependencyCommandScope`. `prepare_generation` retains initial immutable state and dependency tickets, stages current bindings and stamps the exact geometry key.
2. When reuse is enabled and eligible, borrow raw furniture inspection plus the immutable query. Otherwise `capture_furniture` copies evaluated bodies/soup and inspects them. Copy the raw inspection into command-local storage in either path.
3. `bind_furniture_regions` reconciles that command-local copy against the current registry, or a valid Preview registry override, reserves new IDs and applies persistent mappings. Then recapture every source-backed asset and validate required-source provenance/support metadata, including on a hit.
4. On a miss, capture independent obstacles and build `FurniturePlacementQuery`. Before optional retention, recheck the initial state, dependencies and exact key. Release body meshes/soup; retain only the owned numerical bundle. A valid cold operation may continue when retention is ineligible or over budget.
5. Solve current category/region/lock/composition state.
6. Generate captures visual meshes/materials and publishes nodes plus state; Preview stores boxes and its staged registry.

The first cache eliminates only step 2's mesh capture/inspection and step 4 on a hit. Step 3, numerical solving, visual capture and publication still run. A source-backed multi-part book may still spend most of its time in asset/material capture; measure before promising substantial end-to-end acceleration. Analyze remains furniture-only cold capture/binding under the mandatory dependency guard; unrelated obstacle-query capture must not add Analyze failures.

The retained boundary follows three narrow responsibilities:

- Numeric capture/query construction: copied furniture/obstacle bodies → raw furniture-only inspection + immutable query + stamp/counts. Release body meshes and combined soup after construction.
- `bind_furniture_regions`: match raw observations against **this command's current registry**, or its valid Preview override, with current furniture source keys. Reserve identities normally. Apply mappings to a command-local region copy.
- Existing preparation continues with current asset capture, policies, placements, groups and solver.

Do not cache stable region IDs, labels, exclusions, front vectors, category policy, selected scope, placements or an old document/registry snapshot as authoritative geometry. `Region` currently owns its cells, so the initial bounded deep copy for ID remapping is explicit cost. Borrowed-cell views are a later optimization if measurements justify them.

`FurniturePlacementQuery` already owns the retained numerical representation: triangle coordinates/bounds/component IDs, connected-component bounds, support polygons, BVH order/tree and immutable query settings. Its `validate` method uses local scratch rather than mutating the query. Retaining the object is sufficient; storing duplicate body meshes provides no initial benefit.

## Exact key and eligibility checks

Use fieldwise values, not a hash of padded structs. A digest may accelerate comparison but never replaces equality/admission checks.

| Input | Initial rule |
| --- | --- |
| Setup lifetime | Unique transient document-instance token plus scene generation; not GUID alone or reusable raw pointer address |
| Dependency stamp | New monotonic geometry epoch outside restored state; never rewound by Undo |
| Furniture/obstacles | Ordered root identities, deterministic expanded geometry-node identities, scope roles and furniture source keys; root/descendant changes miss |
| Coordinates | Exact `frame_origin_mm`, mm-per-system-unit and each evaluated `GetObjTMAfterWSM` matrix, including its parity/scale and actual transform-validity interval |
| Time | Request time must equal capture time. Invalidate on time change initially; no cross-time/static-FOREVER performance promise |
| Inspection | Every `Settings` field: cell size, clearance, slope, height tolerance and all triangle/cell/region/work limits |
| Query | Every `QuerySettings` field: tolerance, approach bool, default front, max triangles/vertices/support vertices/build work |
| Geometry type/admission | Missing/generated/unsupported/singular inputs still reject. A hit must not conceal a new invalid scope |

On lookup, run the same bounded root/group normalization and ownership checks as cold capture; drain queued hierarchy events first. Compare current expanded identities/matrices on Max's main thread. Evaluate current world-state/type/validity as needed to preserve supported-conversion checks, without converting/copying meshes on a genuine hit. Do not retain an evaluated `Object*`, `TriObject`, material or node reference inside the numerical bundle.

The [Max 2027 INode reference](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_node.html) and installed `inode.h` describe `GetObjectTM` as context-dependent: it may return the before- or after-WSM frame. The current numeric capture and key explicitly call `GetObjTMAfterWSM(t, &tm_valid)` before obtaining a fresh `EvalWorldState` object, and capture intersects that returned transform validity with evaluated object validity. Key equality compares both intervals as well as the matrix. `GetNodeTM` validity is not substituted. Never retain a bundle whose captured validity excludes the capture time.

With deformable WSMs, the final frame may be identity because evaluated vertices are already in world space. The key's existing `object_tm` field now stores this explicit final-pipeline frame; mandatory dependency observation must still cover node/offset/WSM edits even if that matrix stays identity. Transform queries can invalidate borrowed pipeline data, so inspector capture and visual capture also query the final frame before borrowing a fresh evaluated mesh. Authored source-axis/locked-output transform checks are separate and were not universally rewritten. Native36 measured real support at 570 mm but native placement at 1070 mm under the prior context-dependent convention; the promoted source correction still requires a new exact-pair WSM/mirror/offset regression. See [the host evidence](research/CACHE_HOST_VALIDATION_2026-10-18.md).

The same-time restriction deliberately makes the first milestone smaller than the earlier cross-time design. Time notifications invalidate transient reuse without solving or changing Manual/Live state. Cross-time reuse can follow once the full evaluated object/WSM validity intersection is proven on representative animated fixtures.

## Invalidation: prerequisite before enabling hits

Existing `revision`, state-pointer identity and `Lifecycle::input_epoch` cannot be the geometry key. They change on seed/profile/policy edits and successful publication, so using them would invalidate the intended reroll hit. Conversely, restoring an old Lifecycle during Undo must never resurrect old geometry.

The implementation adds a private non-restorable geometry epoch and scene/document incarnation. Role-aware observation updates genuine dependency invalidation before publication scheduling suppression; it no longer simply returns early under `lifecycle_.updating`. A real upstream input event during capture/publication must invalidate the active command even then. Owned output creation/deletion/transform and fresh reference-container bookkeeping must not masquerade as upstream geometry changes.

Document ownership also retains a bounded transient expanded-input watcher between commands, including after Preview-only discovery of a new descendant. Its complete replacement is built silently before subscription; failed staging retains the predecessor. This watcher is separate from authored reference slots, Undo, serialization and numeric cache payloads. Scoped native34 general and publication-callback passes support those tested paths, but do not qualify the later post-WSM source pair or every native-cycle/detached-owner boundary.

Keep callbacks cheap: increment/flag invalidation only, with no capture/solve, large destruction, eviction or MAXScript call. Drain/release stale data later on the main-thread service/next explicit command. Qualify this role split in the real host: a successful Generate must leave a reusable bundle, while a deliberately induced upstream edit under the updating guard must refuse stale reuse/publication.

| Change/event | Cache behavior; scene behavior unchanged |
| --- | --- |
| Seed/density/style/spacing/edge gap/locks/selective scope/category rules | Geometry hit eligible; use current solver inputs |
| Composition options, profile metadata, saved groups | Geometry hit eligible; protected-row validation and new solving still run |
| Region label/mask/density/exclusion/front edits | Hit eligible: reconcile current registry and pass current per-probe policy/front |
| Approach toggle | Miss initially because the immutable query stores that setting |
| Inspection/query setting or any admission budget change | Miss; cold validation enforces the new bounds even if prior data would otherwise fit |
| Furniture/obstacle geometry/topology/TM/object offset/WSM/scope/hierarchy edit | Invalidate; fresh capture/query required |
| Asset-only geometry notification through combined descendant container | Conservative geometry miss is acceptable initially; classify separately later if it costs measurable time |
| Appearance-only edit | Keep numeric bundle only when numeric invalidation rules permit; always read current visual/material data on Generate |
| Output-only edit/deletion | Do not invalidate furniture/query data; retain current lock/row/deletion and Live protection policies |
| Unrelated scene node, browsing, selection, passive refresh | Neither solve nor rebuild; bookkeeping reads stay passive |
| Units/frame/time change | Invalidate/miss; no conversion of previously captured data in place |
| Undo/Redo/reset/new/open/merge/clone/owner removal/shutdown | Empty/invalidate transient entries, with no history restoration or serialization |

Source plugins must provide correct Max notifications/evaluated validity. A custom object that changes its geometry silently while all observed inputs remain unchanged is outside initial cache qualification. Provide an explicit forced-cold recovery path and document this limit; it is not a substitute for testing supported sources.

## Ownership, budgets and failure behavior

A small main-thread cache service owns four fixed slots keyed by live-document tokens, with non-owning registration in the document service. Numerical bundles hold no strong Document reference. Existing command lifetime guards keep document/owner valid only while the synchronous operation runs; an opaque strong-only `GeometryLease` keeps numerical entry data alive independently. Owner/document removal invalidates registration. Defer heavy payload release out of reference callbacks; still charge its bytes until actually released.

Undo records retain authored snapshots and scene references, never bundles. Clear on pre-Undo/pre-Redo, and recheck owner/token on lookup. Load/clone start empty. The geometry service and Preview service remain separate: Preview still owns only boxes/selected IDs/staged registry. Clearing geometry reuse alone does not rearm Live, publish, change authored revision or make a stale Preview valid again.

Implemented initial retained aggregate ceilings:

- Four entries globally, one per setup.
- 1,000,000 query triangles and 1,000,000 raw inspection cells in aggregate.
- 256 MiB of **accounted retained native allocations**, distinct from process RAM, transient cold scratch, registry/Preview/Undo memory and allocator overhead.
- Existing operation-level ceilings remain unchanged. An entry too large to retain still permits a valid cold command.

Checked query accounting now counts `Impl`, triangle/component/order/tree vector capacities and outer/inner support-path capacities. A narrow embedded counter tracks actual rebound `std::map` allocation requests for `supports`; it does not estimate map nodes with `sizeof(value_type)`. Cache accounting also charges raw regions/cells/warnings, key buffers and allocated entry/control storage. Fixed service storage and the two shared counter/ledger objects remain outside the retained-entry ceiling and are reported separately. Unsupported/incomplete accounting skips retention. Per-probe temporary sets/maps/Clipper buffers are scratch, not retained cache payload; none of these figures is complete process RAM.

The current BVH reserves `2 * triangle_count` tree nodes. At high admitted geometry counts, query storage alone can exceed the proposed retention byte cap: **skip retention**, rather than claiming every one-million-triangle input fits 256 MiB. The cap limits optional retention, not whether the cold algorithm is admitted.

Account resident, retired-but-borrowed and replacement bundles once each until their final release. Evicting an entry cannot free a command's lease. If pinned/old data prevents admission, use the complete cold candidate without retaining it. Optional retention bookkeeping/admission failure must not become a new arrangement failure. Ordinary capture/query/solver allocation or work-limit errors still retain the previous committed scene result.

Build privately and recheck the dependency ticket after capture/lookup, after numerical solve/visual capture and before transaction acceptance. If relevant inputs change, do not publish the stale successor; invalidate and fail clearly (or allow one explicitly bounded cold retry), never loop indefinitely. A geometry-valid entry may survive a later recipe failure, but cache status must not mark the document clean or imply an arrangement was published. Only ordinary successful Generate/Commit clears dirty state/rearms Live.

## Minimal commands and diagnostics

Preserve existing API row shapes. Add a bounded cache-info getter and a main-thread clear command, rather than embedding cache control into saved arrangement settings. Clear-before-Generate supplies reproducible forced-cold testing without changing the two-argument Generate API.

Report last-command disposition (hit/cold/not-retained), reason, retained counts/accounted bytes and timing phases. A passive info getter reports last-known diagnostics; it must not evaluate meshes to assert current physical freshness. Record actual lookup validation separately from the stored diagnostic status. Keep historical inspection/query build-work counters distinct from work actually executed this command: a hit must not claim it reran the original build work.

## Required tests

1. Cold versus reused **same authored input/current registry**: exact observed/support IDs, positions/yaws/scales, group IDs/order/gaps/fronts, lock flags, warnings, candidate/rejection counts, category counts and independent full-bounds fit. Build work saved is a separate diagnostic, not a changed logical solve result.
2. First-ever Preview→Commit and repeated Preview: cached raw observation IDs reconcile against the staged registry; newly reserved persistent IDs and composition/member poses stay identical. Clearing geometry reuse before Commit forces cold recomputation without invalidating a logically valid preview.
3. Each positive-reuse row above, including ordinary UI Apply/reroll paths that increment revision. Prove output publication itself does not cause a miss on the next operation.
4. Each invalidation row: child add/remove, shared-object instances, nonuniform/mirrored transforms, object offsets, WSM/deformation, topology replacement, source deletion/rebind, units, time, relevant animation and unrelated animation. Same-time input changes under `updating` must be observed; no silent stale reuse.
5. Lower every public admission/work limit after warming. No stale large result bypasses the new cold admission; query settings/front-access changes affect behavior immediately.
6. Native Manual/Live/Preview policies: no solve from getters/selection; armed recipe-only Live can reuse; upstream Live rebuilds; Preview disarms Live even with cache hits; clear/stale preview stays disarmed; output-only edits retain protection.
7. Undo/Redo, setup-only/full clone, save/reopen and merge have empty cache/new tickets. Cache leases and global slots do not keep deleted setup nodes alive. No per-history accumulation.
8. Inject failed capture/query/solve/material/publication and cache admission/eviction. Preserve authored groups/placements/output references and existing preview according to current failure contracts. A stale prior entry is never fallback geometry.
9. Account/evict four setups plus a fifth; borrow an evicted entry and build a replacement; verify aggregate live accounting, deferred release and shutdown. Test an admitted cold scene deliberately too large for retention.

The native core comparison should fix identity reservation or establish a registry once. Running two independent empty-registry paths with unrelated ID reservations would create false differences. Keep the original authored state and fixtures identical; do not compare a cached successor against a different previous placement/group history.

## Independent timing and memory plan

Instrument native steady-clock/QPC durations for lookup/stamp, furniture capture, inspection, region remap/cell copy, obstacle capture, query build, asset/support refresh, solve, visual/material capture, scene publication and total. Write raw per-operation CSV with QPC frequency/ticks or nanoseconds, cache reason and admitted counts. Script `timeStamp` alone is too coarse for small stage differences.

Use original fixed fixtures: small TV/open shelf, a medium closed assembly with many vertical/beveled faces, and a larger but actually admitted geometry/cell case. Preflight every fixture under existing budgets; do not raise ceilings or use rejected models for speedup claims. Include source-backed grouped books and geometry-only imported assets to expose different asset/material costs. Include a row/balance-enabled case without changing its authored inputs between paired measurements.

Measure separately:

- Cold numeric preparation versus reused numeric preparation, with unchanged inputs/registry and no output publication.
- Full Generate cold versus reused at the same time, including identical output replacement/Undo cost.
- First Preview and repeated Preview, followed by Commit.
- Retained bytes from the new allocator/capacity accounting; process working/private bytes as independent whole-host measurements; peak during old/new/scratch coexistence; memory after clear and after bounded history.

Clear geometry cache outside the timed cold command. Warm once, then collect at least ten alternating paired repetitions, reversing order in a second run; log raw samples, median and p95, not a single best time. Equalize/disclose Undo history because output replacement retains scene data. Use separate fresh owned profiles for no-history comparison and a separate representative history test; do not clear artist history. No renderer/viewport-FPS claim follows from these command timings.

Success requires identical logical results, tested invalidation/failure ownership and a measured preparation saving with separately reported end-to-end effect. If asset/material capture dominates and overall Generate barely improves, report that result and defer a second asset/template cache until independent profiling justifies its much harder material/reference/Undo lifetime boundary.

## Proposed implementation ownership

- Document/cache service owner: transient tokens/geometry epoch, role-aware invalidation, lifecycle clear/deferred release and bounded global ownership/accounting.
- Pure query owner: const bundle-facing query API and retained-allocation diagnostics; preserve probe behavior and core/golden results.
- Root bridge owner: capture/bind split, same-time lookup, registry override/ID remap, exact hit eligibility, transaction ticket checks and stage timings.
- Test owner: pure cache/accounting/failure tests plus isolated host equivalence/invalidation/performance scripts. Root serializes all Max launches.

Do not change schema 4/library 2 for this transient optimization. The next milestone needs fresh runtime/native/functional qualification; deployment-only installer reuse cannot qualify changed cache/native behavior.

## Verified procedural and C++ references

Research checked against the primary pages below on 2026-10-18. These sources explain useful design principles; they do not establish Max API behavior, current Cyrus performance, or qualification of this proposed cache.

### Dependency tracking before reuse

**SideFX documents:** Houdini cooks a data dependency graph. A node that consumes another node outside its visible input wiring must declare the extra data dependency; those extra dependencies must be declared again on each cook. Name/path dependencies are a separate concern that may need to exist before any cook, including after scene load. [HDK: Dependencies](https://www.sidefx.com/docs/hdk/_h_d_k__op_basics__overview__dependencies.html)

**Cyrus recommendation:** establish furniture, obstacle and descendant subscriptions when native bindings change or load, then validate the expanded current scope on each lookup. Geometry dependencies must include transform/offset/WSM inputs and external obstacle roots, even though the UI presents them in different lists. Stable names, matching revision numbers and a successful previous generation are insufficient evidence of unchanged geometry. The existing Max reference containers and hierarchy events need their own host tests; Houdini's `addExtraInput` does not apply to Max.

**SideFX documents:** SOP cooking receives an explicit time context, asks relevant inputs for cooked geometry, and can duplicate a source only when it changed. SOP geometry and the creator object's world transform are separate. [HDK: SOP Concepts](https://www.sidefx.com/docs/hdk/_h_d_k__data_flow__s_o_p.html)

**Cyrus recommendation:** keep geometry preparation separate from recipe solving, make scene time and the complete evaluated object-to-world transform explicit inputs, and initially miss on every different time. These principles support the proposed boundary; they do not justify cross-time Max validity reuse. Houdini's preserved locked-SOP geometry also differs from Cyrus locks, which protect authored placement relationships while still checking current support/collision validity.

### Conservative invalidation and bounded retention

**SideFX documents:** geometry data IDs allow downstream code to detect possible changes. Opting into fine-grained ID management transfers invalidation responsibility to the SOP; incorrect management can leave downstream consumers stale. Changes made outside ordinary cooking also require ID/cache metadata updates. [HDK: Geometry Introduction, Data IDs](https://www.sidefx.com/docs/hdk/_h_d_k__geometry__intro.html)

**Cyrus recommendation:** prefer a conservative geometry epoch first. A false miss costs time; a missed furniture/obstacle edit can place objects through geometry. In particular, notification suppression while Cyrus publishes its own outputs must not suppress genuine upstream edits. The Max epoch must be implemented and tested explicitly; there is no established shared data-ID mechanism between these hosts.

**SideFX documents:** Cache If is a RAM cache whose recache conditions can watch upstream edits, other geometry, parameters and expressions, with an explicit Recache action. It deliberately ignores the first input's time dependence. [Houdini: Cache If](https://www.sidefx.com/docs/houdini/nodes/sop/cacheif.html)

**Cyrus recommendation:** adopt explicit dependency-based eligibility and a reproducible forced-cold operation. Keep time in Cyrus's first key; do not import Cache If's intentional time-dependency removal into animated Max scenes. Cache controls should remain a small diagnostic/clear action, rather than a new graph editor that makes ordinary Generate/Preview harder to use.

**SideFX documents:** `SOP_CacheManager` tracks active SOP memory, culls under a memory limit, observes lifecycle/geometry changes and avoids culling data currently in use. [HDK: SOP_CacheManager](https://www.sidefx.com/docs/hdk/class_s_o_p___cache_manager.html)

**Cyrus recommendation:** enforce the proposed aggregate retained-allocation budget as well as entry/triangle/cell counts. Count leased and retired payloads until actual release, and let a valid but oversized cold result continue without retention. The proposed four-entry/256 MiB figures are engineering starting limits to measure, not SideFX-prescribed settings or a whole-process RAM guarantee.

### Borrowed geometry and C++ failure ownership

**SideFX documents:** locked SOP input geometry is borrowed; the returned detail pointer is valid only until the matching input unlock. The input context also identifies the requested evaluation time. [HDK: Changing Geometry](https://www.sidefx.com/docs/hdk/_h_d_k__op_basics__sop_filter.html)

**Cyrus recommendation:** retain only owned numeric geometry/query data after native capture. Do not retain evaluated Max mesh pointers or converted `TriObject` ownership in cache entries. SideFX input locks are unrelated to Max thread-safety guarantees; all Max capture, dependency inspection and scene mutation remain on the main thread.

**C++ guidance:** the Core Guidelines recommend RAII for paired resources, unique ownership unless sharing is required, and non-failing destruction/deallocation/swap. [C++ Core Guidelines: R.1, R.20–21, E.16](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)

**Cyrus recommendation:** privately build a bundle with scoped owners; use a shared immutable payload only where an active lease must outlive cache eviction. Keep scene ownership outside it. Cleanup must not throw. An immutable pointer does not prove thread safety, and RAII alone does not restore Max scene references or Undo state.

**Boost documents:** a strong exception guarantee means an operation either succeeds or leaves its previous state unchanged; this depends on compatible guarantees from constituent operations. [Boost Site Docs: Exception-Safety in Generic Components](https://docs.cppalliance.org/user-guide/exception-safety.html)

**Cyrus recommendation:** complete payload construction and validation before replacing an entry. Publish authored state/output nodes through the existing host transaction, independently from optional cache retention. Cache admission failure may skip retention; source/solve/publication failures remain errors and preserve prior committed outputs. Add targeted allocation/failure tests rather than assuming `try/catch` produces rollback.

### Evidence still required

These references justify the design direction, not a speed claim. Qualification must prove cold/reused equivalence, every invalidation boundary and host lifecycle/failure behavior, then report native phase timings and complete artist operations separately. Preserve the existing solver's fit, target, stable-region and relational checks on every hit. If asset/visual capture dominates, keep that measured limitation explicit before expanding ownership complexity.

## Preserved draft qualification, followed by integration

Two isolated drafts established the initial component boundary before their promotion. Their original receipts remain historical evidence, separate from the integrated source pair:

- `build/query-accounting-draft/build-01/receipt.json`: six CTest targets / 41 reported cases, warning-free pinned Release. Covers actual rebound map allocation requests, retained vector/path capacities, overflow, lifetime/moves and exact unchanged query results/work counters against frozen native26.
- `build/cache-implementation-draft/build-03/receipt.json`: eight pure cache suites, warning-free, matching final frozen draft headers/docs. Covers exact keys, fail-closed epoch saturation, raw observation isolation, optional allocation failure, aggregate budgets, pinned/retired entries, same-setup replacement and final release after cache-service destruction.

The cache draft uses opaque strong leases. It counts allocated entry/control storage and numeric payloads; its fixed service and two shared counter/ledger objects remain explicitly outside the retained-entry budget. These quantities are not whole-process RAM or cold construction peaks. The query draft returns incomplete accounting in unsupported MSVC iterator-debug configurations so optional reuse can be skipped without changing a valid cold command.

The adapter integration remains the hard acceptance boundary. `host_integration.md` in the cache draft identifies real notification senders before update suppression, deferred input-dirty flags after transaction unwind, same-time evaluated post-WSM validity, early time invalidation, Undo/merge/load/clone clearing and final dependency validation before Accept. Analyze remains furniture-only. The [dated host evidence](research/CACHE_HOST_VALIDATION_2026-10-18.md) records integrated failures and scoped successor passes; neither pure tests nor historical host pairs establish current full qualification or a speedup.

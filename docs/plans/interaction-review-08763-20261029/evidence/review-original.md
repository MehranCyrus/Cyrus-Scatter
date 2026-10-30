**CyrusScatter system review — 29 October 2026**

**Verdict: request changes.** The native placement, source preparation, retained preview and artistic interaction design is worth keeping. The current implementation still has a reproducible native crash, incorrect setting combinations, display inconsistencies and avoidable work in interactive updates. Passing the existing suite does not establish that those combinations are safe.

This was a review of the current working tree, including uncommitted and relevant untracked changes, rather than only the last commit. No product code was changed. All review probes and receipts live in this ignored build directory. No Max process was launched, no Computer Use was performed, and nothing was installed or packaged.

**Identity and scope**

| Item | Reviewed evidence |
| --- | --- |
| Repository | `F:/Cursor/_Cyrus_Apps/CyrusScatter` |
| Branch | `codex/workflow-0.75` |
| HEAD | `75c60d54dbfd736ffef135d211863516a63543a7` |
| Working source version | `0.87.6.2` |
| Previously recorded delivered version | `0.87.6.1`; its host receipts do not qualify the changed 0.87.6.2 selection work |
| Build exercised | Fresh Release, Max 2027 SDK, x64, MSVC 14.38.33130, Ninja |
| Selected source identity | 636 selected sources; 8,494 unique source/build/compiler/generated inputs rehashed, zero mismatches at verification |
| Fresh native module SHA-256 | `c337b04aaedeea1b0d300777d586126da579ad4a6ef5c27692a96eacbd629a73` |
| Generated MAXScript SHA-256 | `ac7bf5c883438fa1d2bc646e1a000c77cabbe9ab4d906f7aa71a72929b27fdf8` |

The review covered Scatter placement storage, Edit feedback, interaction capture and invalidation, source preparation, artistic and detailed response, neighbor handling, preview/deformation/picking, render output, relevant authored settings and persistence boundaries, compiler configuration and tests. Shared vegetation code was inspected where it participates in that pipeline. Independently versioned Physics Lab, Arrange, MCP and licensing were not given a separate complete audit in this review.

The compact knowledge scope was core contracts/native Scene Library/current artistic evidence. Its verification reported 23 current and nine stale parents out of 32. It was used for navigation; the findings below rely on direct source inspection and fresh execution. No index was refreshed and no broader-index freshness claim is made.

**R1 — P1: retained neighbor settings can produce an exception or native access violation after a role change**

The constructor creates neighbor branch geometry only for active reacting layers. Later update paths use `neighbors` without also requiring an active React role and a valid prepared rig. The UI preserves the authored neighbor checkbox when changing the layer role; the host also preserves edited rows when a layer becomes Off. That makes the supposedly inactive flag reachable in native evaluation.

Relevant locations: [engine constructor](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_engine.cpp:117), [changed-neighbor handling](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_engine.cpp:163), [edited-neighbor enumeration](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_engine.cpp:219), [neighbor cache lookup](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_engine.cpp:223), [UI role change](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/tools/ui/templates/interactions-ui.ms:109), [host capture and retained history](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_host.cpp:401).

Reproduction uses two distinct prepared plant sources, neighboring-tree response and an Edit transform. The all-reacting control produces a pose. With the edited first layer Off but its neighbor flag retained, actual `Engine::evaluate` throws `invalid unordered_map<K, T> key`. Clearing that flag in the control avoids the error. With a collider-only definition, the same stale neighbor participation dereferences a missing rig: the disposable native probe exits with `0xC0000005`.

This was an isolated native executable crash, not a Max crash observed in this review. The UI and host source establish the relevant state path. A C++ access violation is more serious than an ordinary reported evaluation error; the existing exception boundary is not an adequate guarantee against it.

Recommended repair: centralize an effective-neighbor predicate requiring React, the authored neighbor option and valid preparation. Apply it to construction, changed-row expansion, override enumeration and lookup. Keep inactive authored preferences separately if desired; do not rely on clearing a UI checkbox as the only safety measure. Add React → Off → React and React → Collider → React tests with edits, disabled rows, distinct sources and Undo/Redo/reload.

This finding was present in the earlier interaction review and remains in the current source.

**R2 — P2: Hide under collider and Hide margin can silently fail in the artistic response modes**

The local artistic solver implements root hiding for Bend, Trim and Bend then Trim. However, the engine's candidate search expands for the hiding margin and overhead coverage only when `response == 0`, the Detailed mode. The engine can therefore discard a collider before the otherwise-correct local solver sees it.

Source: [hideReach and reactRange](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_engine.cpp:15), [artistic root hiding](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_fast_bend.inc:14).

Two native fixtures reproduce the mismatch:

| Fixture | Detailed through engine | Bend / Trim / Bend then Trim through engine | Direct artistic solver |
| --- | --- | --- | --- |
| Collider overhead, above the plant's ordinary reach | One root hidden | Zero roots hidden | One root hidden |
| Collider within Hide margin but outside ordinary reach | Two roots hidden | Zero roots hidden | Two roots hidden |

This explains why an individual setting can look correct in a small test yet fail when combined with another response mode. Recommended repair: make root-coverage candidate selection independent of the response algorithm. Preserve bounded artistic guide work; fixing candidate coverage does not require bringing expensive detailed fitting back into a drag. Test both scene and scattered colliders, inside/under modes, margin boundaries, scale/rotation and move-away restoration.

**R3 — P2: neighbor batch edits copy both complete override maps for every changed item**

The expression below constructs an initializer list containing two map values. The reference on the loop variable does not prevent those copies:

```cpp
for (const auto& map : {previous->overrides, overrides})
```

It appears inside the changed-item loop at [interactions_engine.cpp:163](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_engine.cpp:163). For M changed neighbors and N overrides, this adds O(M × N) map-node allocation/copy work before useful contact fitting. `addNear` also scans edited overrides repeatedly, so removing the copies is the first improvement, not the entire scalability fix.

The focused expression test with 1,024 changes and 1,024 entries made 2,099,200 allocations and requested 285,491,200 bytes cumulatively. Borrowing the same maps in the control made zero allocations for that loop.

A separate test called the actual current production engine with separated plants and a small batch transform. It produced zero contact queries:

| Changed plants / overrides | Allocations during evaluate | Cumulative requested bytes | Query-stage time | Total evaluate time |
| --- | ---: | ---: | ---: | ---: |
| 64 | 9,202 | 1,153,080 | 1.84 ms | 2.43 ms |
| 256 | 135,830 | 17,988,799 | 19.41 ms | 20.85 ms |
| 1,024 | 2,118,614 | 285,908,326 | 417.77 ms | 429.29 ms |

These are single-run native measurements with allocation instrumentation. The bytes are allocation churn, not peak retained memory, and the timings are not Max frame times. The allocation growth and the copied-container expression are the strong evidence. Recommended repair: borrow the maps, then index transient edited reactors rather than rescanning them for each changed region. Verify deterministic output and restoration while recording allocation counts.

**R4 — P2: viewport draw limits do not sufficiently constrain pose-buffer preparation**

[interactions_preview.cpp:124](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_preview.cpp:124) counts all retained nonhidden poses of a source before row selection, memory reservation and packing. It rejects at the compact buffer's exact-index limit with advice to reduce viewport draw limits. Row filtering occurs later, at lines 129–130.

There is a second boundary: ordinary Mesh preview currently passes an unlimited preparation row count in [unified-core.ms:4140](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/tools/ui/templates/unified-core.ms:4140). Triangle quotas are applied later by the display planner. Reducing triangles actually drawn therefore does not necessarily reduce the poses packed or the admission count that caused the error.

An arithmetic admission probe used a real prepared synthetic source with 160 guides and 1,282 rest words. At 13,087 retained poses, the current formula requests 16,778,816 words, or 268,461,056 bytes, and exceeds the 2^24-word limit. If the admitted draw set required one posed instance, its rest-plus-pose payload would be 2,564 words, or 41,024 bytes. The one-instance figure is a counterfactual showing the opportunity; this was not an executed Max scene with one visible plant.

Recommended repair: coordinate pose admission with the union of the idle/navigation draw sets, or adopt a deliberately paged representation. Count and reserve only the required packed poses while preserving stable instance mapping, bounds and previous complete publication. If retaining all poses is intentional, the current error advice still needs to describe the limitation accurately. Increasing the memory cap alone will not repair the exact-index limit or unnecessary preparation.

**R5 — P2: Point Cloud hides fixed components that the mesh path keeps**

At [interactions_preview.cpp:68](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_preview.cpp:68), the root-hidden check is unconditional; only the second, hidden-guide check excludes `part.fixed`. The canonical face visibility path exempts fixed components from both. As a result, the Point Cloud and mesh representations disagree.

The prepared fixture has eight leaf roots and an eight-vertex fixed decoration. With the roots covered, the Point Cloud predicate skips all eight fixed vertices, while all 12 fixed decoration triangles remain visible through the canonical mesh predicate. This is a source-level predicate reproduction with real preparation and pose data, not a screenshot comparison in Max.

Recommended repair: share or enforce the same visibility predicate across Point Cloud, compact mesh, CPU/render and picking. Test root hiding and branch trimming with mixed fixed/deforming components. This also remains from the earlier review.

**R6 — P2: render bounds can exclude visible fixed geometry**

[interactions_render.cpp:153](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_render.cpp:153) constructs packet bounds using the source's guide-derived `reach`. The value is calculated from guide path length and bound offsets at [interactions_source.cpp:259](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_source.cpp:259), so it does not necessarily include fixed components.

The prepared fixture, with a fixed decoration offset to X = 5 m, has guide reach 0.859614 m and visible fixed extent X = 5.035 m. All eight fixed vertices lie outside the render packet bound; `allHidden` remains false, correctly retaining the decoration. The viewport deformation-bound calculation already starts from full source bounds, so it does not make the same assumption.

An incorrect render bounding box can lead to renderer culling or missed geometry/shadows. No Corona/V-Ray artifact was reproduced here. The proven defect is the bound not containing geometry the render path can emit. Recommended repair: union the transformed fixed/full-source bounds with a conservative deformation envelope, and assert containment of all emitted vertices in representative native fixtures.

**Additional performance work, separate from the defects above**

**A small Edit update can copy an entire placement layer.** [interactionRows](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/interactions_host.cpp:204) creates `placements::Builder(rows)` when the first transformed record differs. [That constructor](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/placement_store.cpp:163) copies and validates every row. The feedback cache reuses a view only for the same snapshot, so a new interactive snapshot can take this path again.

In the actual placement-store probe, changing one generated record allocated 9.6 MB of new row payload for 100,000 rows and 96 MB for 1,000,000 rows. The latter copy took approximately 40.7 ms in the final run. This excludes the rest of a Max frame. Edit's authored history already uses shared blocks; the issue is a later feedback/materialization boundary. Prefer a base view plus sparse transform overlays or block sharing for that path, and flatten only for consumers that need a flat buffer.

**A local pose change still has global bookkeeping costs.** Evaluation copies retained pose/warning containers, scans retained poses for aggregate statistics and prepares output by source. Render packet construction scans all poses twice per source and sorts matching indices. Preview reuse avoids uploads when a source type is unchanged, which is good, but a change within a type can still repack its retained poses. Consider touched-source and touched-instance indices, incremental statistics and immutable packet reuse after measuring realistic source mixes. Do not claim O(nearby plants) for the entire end-to-end update just because the contact solver is local.

**New 0.87.6.2 hover/picking needs host performance qualification.** [viewport_pick.inc:88](F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/src/viewport_pick.inc:88) scans admitted instance bounds for each new ray. When an instance box is hit, a group with deformation skips the existing static face-block rejection and tests its visible faces, reconstructing compact posed triangles on the CPU. Ray-result caching helps repeated requests for the same pointer ray, but not continuous pointer motion. Edit's `visible()` also walks rows and materializes a list for multiple display/pick operations. These are static scaling risks; no Max hover latency was measured. Benchmark high-polygon trees and dense foliage before accepting this work. A source/instance acceleration structure and a rest-pose fast path are candidates if the measurement justifies them.

**The 256 MiB pose limit is a payload check, not a peak-memory guarantee.** The engine checks the total after building new poses. Previous snapshots and worker scratch can coexist with those allocations. The existing bounded counters and retained-publication rules are valuable, but qualification should distinguish the retained result cap from actual peak allocation. Admit predictable pose/scratch requirements before work where possible and measure old/new coexistence in a soak test. This review did not force an out-of-memory condition or demonstrate a leak.

**What is technically strong and should be preserved**

- Placement data uses native records, stable identities and immutable views; source geometry and preparation can be shared across placements. The architecture avoids requiring a separate full source mesh allocation for every ordinary scattered object.
- Edit uses shared block storage for authored history, while source/proxy preparation and retained display resources have explicit owners. Keep that structure when repairing the feedback copy boundary.
- Host capture/publication is separated from numeric worker computation. Workers consume owned numeric data, and the executor joins before publication; it also handles worker launch failure and propagates ordered failures.
- Interaction spatial indexing and previous/current transform handling support local work and move-away restoration. Rest-based artistic deformation is deterministic and avoids accumulated drift.
- The fast Bend/Trim path deliberately uses bounded coarse guide work. Its zero-strength/fixed-region early-outs are appropriate. The artist-endorsed response should not be replaced with expensive iterative fitting merely to label it more physical.
- GPU preview shares source resources and compact poses, and unchanged source types can retain their buffers. Atomic complete publication and previous-result retention are the right failure contract.
- The render/Bake path works from the original source mesh, material/UV data and explicit normals, with chunked construction. A uniquely deformed output still has a geometry cost at the renderer boundary; instancing is not a promise that all posed output is free.
- Ordered layers, source correspondence and the separation between spacing rules and interaction response are useful boundaries. Off/Collider/React transitions need to obey them consistently, as R1 demonstrates.

The system is an artistic procedural adaptation system. Neighbor response uses deterministic priority against prepared rest proxies; it is not a mutually converged rigid-body simulation. Detailed fitting and artistic Bend/Trim have different cost and accuracy contracts. Residual intersections from the declared artistic approximation should not automatically be classified as regressions or used to justify removing its performance advantage.

**C++ build and maintainability assessment**

The fresh build used C++20 for the numeric core, x64, `/O2 /Ob2 /DNDEBUG /MD /EHsc` and the matching Max 2027 SDK. The `amin_scatter` numeric target adds `/W4 /WX /permissive-`. These are reasonable optimized build settings. There is no evidence here that changing the C++ language level or a compiler optimization switch would remove the measured allocation/copy work.

Strict warning settings are not equally applied to the host module and shared interaction-rig target. Extend useful diagnostics to owned code with targeted treatment of SDK warnings. Fresh Release output did not include matching PDBs; preserve optimized debug symbols for crash triage. Use isolated sanitizer/heap-verifier campaigns for native boundary tests, and measure representative workloads before adopting LTO, PGO, wider SIMD or different worker scheduling. Enabling aggressive floating-point shortcuts without precision/determinism evidence is inappropriate for this geometry code.

Several critical functions compress multiple phases and conditions onto long single lines. The role predicate, visibility predicate, broad-phase policy and map-copy mistake are easier to miss in this style. Extract small named policies and format these boundaries for review. This is a focused maintainability recommendation, not a request for a repository-wide cosmetic rewrite.

The executor uses bounded participants and carries the numeric floating-point environment to workers. Repeated thread startup may still have a cost; a persistent pool should be justified by measurements and its lifetime requirements rather than assumed to be an improvement.

**Settings and persistence confidence**

The focused matrix exercised 648 combinations on a simple two-blade prepared fixture: three artistic responses, three bend strengths, three trim amounts, three fixed-base values, two trunk values, root hiding on/off and inside/under coverage. All repeated outputs were deterministic, all 6,480 face visibility comparisons agreed between canonical CPU and compact deformation evaluation, and move-away restored rest. Maximum point-position disagreement was approximately 3.27e-9 m.

That proves a useful local slice of the system. It does not prove every tree hierarchy, every source preparation, role transition, cache transition, output mode, material or renderer. R1/R2/R5 show why state transitions and representation combinations must be tested in addition to numeric parameter cross-products. The compact evaluator was exercised on the CPU; this matrix is not a fresh GPU rasterization test.

Scene-authored settings and portable recipes have different scopes. The portable recipe contract remains intentionally narrower and rejects active unsupported broader interaction features; it must not be advertised as round-tripping every new Interactions setting. Relevant source IDs, pending Manual state and dependency ownership were inspected, but save/load, Undo/Redo and renderer integration were not newly executed inside Max for this review.

**Executed validation and evidence**

| Check | Result | Limit |
| --- | --- | --- |
| Fresh Max 2027 SDK build | Configure/build/tests exit zero | SDK compilation is not host execution |
| Existing native suite | 62/62 pass, 33.38 s | Does not cover the new adverse cases below |
| Generated UI check | Pass; 379 controls, 245 baseline controls accounted for, 32 fixture delimiters | MAXScript not compiled by Max; UI not operated |
| Focused settings matrix | 648 cases / 6,480 face comparisons pass | Simple fixture; CPU compact evaluator |
| Neighbor role probes | Off throws; collider-only exits 0xC0000005 | Disposable native executable; no Max crash induced |
| Hiding comparison | Artistic engine misses both fixtures | Actual numeric engine versus direct solver |
| Fixed component visibility and bounds | Inconsistencies reproduced | Predicate/numeric bounds, not renderer screenshots |
| Pose admission example | Limit/arithmetic mismatch established | No 13,087-pose Max scene executed |
| Allocation and placement probes | Map churn and full-layer copy measured | Instrumented native costs, not presented FPS |
| Source/input identity | 8,494 rehashed inputs; zero mismatches | Selected build scope; no installed/loaded identity claim |

Commands executed:

```powershell
python tools/procedural_lab/check_generated.py --output build/review-system-20261029-01/generated
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --generator Ninja --jobs 4 --output build/review-system-20261029-01/native
python build/review-system-20261029-01/run_probe.py
```

Receipts: [native build receipt](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/review-system-20261029-01/native/receipt.json), [native test log](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/review-system-20261029-01/native/tests.log), [generated check](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/review-system-20261029-01/generated/generated-check.json), [probe source](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/review-system-20261029-01/probe.cpp), [probe results](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/review-system-20261029-01/probe-results.json), [identity check](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/review-system-20261029-01/identity-check.json).

The normal probe exits zero when its checks execute successfully; several checks deliberately demonstrate existing defects. That exit code must not be summarized as all additional product scenarios passing. The collider-only child is expected to crash on this reviewed implementation, and its process exit code is recorded separately.

Existing 0.87.6.1 Terraces and 0.87.5.6 artist-baseline receipts remain useful historical evidence within their stated scope. They do not establish current 0.87.6.2 host behavior. CPU evaluation/redraw timings also do not establish GPU presented frame rate or interactive feel.

**Recommended order and acceptance criteria**

1. Repair role-state safety and add transition regressions first. No null rig/cache access for Off or collider-only retained history; old complete output survives ordinary failed evaluation.
2. Repair response-independent hiding, fixed-component visibility and render-bound containment. Exercise these across preview representations, source changes, movement/restoration and scale.
3. Remove copied override maps and measure the remaining repeated override scans. Preserve deterministic poses and stable IDs; add allocation-count coverage for separated batches with zero contacts.
4. Keep sparse Edit feedback sparse and align prepared pose data with admitted drawing. Verify quotas, navigation/idle changes and memory rejection without corrupting the last complete result.
5. Qualify the new picker and touched-source publication costs using representative trees/grass, multiple sources and both inactive/active interactions. Measure compute, preparation, upload and actually presented results separately.
6. Run owned Max 2027 lifecycle scenarios: role changes with Edit overrides; Undo/Redo; save/reload; source replacement/preparation; Manual pending versus Live; ordinary and scattered animated colliders; output modes; and final render/Bake parity. Add a memory soak and keep matching symbols/diagnostics.

The next work should improve correctness and avoid unnecessary work within the existing design. A general C++ rewrite, indiscriminate extra threading or conversion of every source into a simpler proxy is not supported by this evidence. The current architecture is a credible foundation; broad production approval should wait for the reproduced defects and the current host acceptance gaps to be closed.

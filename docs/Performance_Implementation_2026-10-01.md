# First measured CPU performance implementation

**Date:** 2026-10-01. **Candidate:** Cyrus Scatter 0.60 / native engine 0.22 / scripted class version 45, Max 2027. **Decision:** retain for the artist's interactive test; broader release qualification remains open.

## Result

The saved heavy scene's full controller refresh now takes **1.01–1.17 seconds**, compared with **3.98–4.05 seconds** for the frozen original. Across the five defined geometry states, this is **3.44–3.99× faster**, a **71–75% reduction**. Clover placement is **8.66–12.18× faster**. All **60 ordered preview/render outputs** match the original exactly.

These are synchronous calculation and preview-preparation measurements. They exclude automatic callback scheduling, Analyzer execution time, GPU frame completion and Corona rendering. They do not establish near-real-time mouse editing or a viewport FPS improvement. Follow the [upgrade test](Performance_Upgrade_Test_2026-10-01.md) to measure that experience.

## What changed

| Change | Implementation and limits |
|---|---|
| Source policy filtering | Evaluate empty/point policy once per source; filter rows natively in stable order. Keep filtering after area/falloff so index-based density decisions retain their meaning. Render point-placeholder exclusion remains at its original stage. |
| Source scale/Z offset | Validate every row first, then update transient Matrix3 values natively on the calling thread. Preserve the old float arithmetic, alias behavior and signed-zero operations. |
| CPU cluster queries | Serially sample candidates in the original RNG order; evaluate independent cluster fields in disjoint worker ranges; finish ordered source selection, transforms and acceptance on the caller. Weighting mode is selected once per query. |
| Closed Analyzer band queries | Lazily prepare kind 1/2 path normals, bases, ordered edges and denominators once per scatter evaluation. Preserve plane tests, holes, mask offsets, distances, strict thresholds and first matching band. Other band kinds retain their existing predicate. |
| Boundary orientation | Remove the deep copy of an entire LineBand for each point. Pass the same kind override to the existing membership predicate. |
| Edit redraw batching | Keep each invalidation, then request one redraw at the end of a Scatter NodeEventCallback batch. Independent Analyzer batches/timers may still trigger additional work. |
| Diagnostics | Recorder 0.2.2 records optional CPU policy/helper availability/batch counters. Placement traces include output count and preview/raw/final flags. |

The main implementation owners are `AminScatter/src/max_bridge.cpp`, `src/scatter.cpp`, `src/cluster.inc`, `src/prepared_band.inc`, `src/orientation.inc`, `include/execution.h`, `src/execution.cpp`, and `tools/ui/compute-performance.cjs`. The generated script is produced by `tools/ui/generate.cjs`; editing that generated file alone is insufficient.

`tools/build_max.py` now regenerates that script before compiling/packaging. Missing Node.js or a generator anchor failure stops the build instead of shipping a stale script. MZP users need no compiler, SDK or Node.js.

No class IDs or persisted parameters changed. Session CPU policy is not saved into scenes. Surface Analyzer's own calculation algorithm is unchanged. Licensing work is outside this iteration.

## CPU execution policy

- `cyrusScatterCPUThreads 0`: automatic, **at most four total participants including the caller**, bounded by the machine's logical processor count.
- `cyrusScatterCPUThreads 1`: serial. Requests 2–64 are available for controlled tests and are also bounded by hardware availability.
- The parallel cluster path starts at **4,096 candidates**, with clustering active, no movement, no area masks, no UV-density rejection and no anchors. Unsupported pipelines and smaller inputs keep ordered serial computation.
- Workers receive owned native numeric data. They do not call MAXScript, evaluate nodes, manipulate scene objects, use GraphicsWindow or touch Max GC values.
- Every worker is joined before return or error. Contiguous ranges preserve earliest-index error selection. Workers copy the caller's floating-point environment and SSE control state.
- A thread-launch failure joins already-started work and recomputes serially. Allocation/other calculation failures retain the existing error path. There is no detached work, thread pool, asynchronous publication, DLL-loader initialization or additional oneTBB runtime.

`cyrusScatterCPUThreads()` returns the requested policy. `cyrusScatterComputeStats()` returns `#(participants, cluster_queries, thread_launch_fallback)` for the most recent successful native scatter call on that calling thread. A dependent layer can be that call; these values are not a per-layer timing attribution. `CyrusScatterLiveBatchStats()` returns batch count, redraw-request count, nesting depth, pending-redraw flag and change-handler call count. A redraw request is not a completed frame.

The candidate scratch vector is approximately **5.34 MiB for 100,000 candidates**, additional to existing instance/output storage. It is evaluation-owned and released after workers finish; no cell cache or persistent scene cache was added. This is an allocation estimate, not a measured process-memory peak. Large-scene memory and the requested 32 GB floor still require qualification.

The four-participant default is provisional for this local test build. Higher limits slightly improve the isolated cluster kernel, but the remaining host work limits complete-operation benefit. Corona IR/render contention has not been measured.

## Saved-scene comparison

**Machine:** Ryzen 5 5600X, 6 physical / 12 logical processors, approximately 96 GiB installed RAM, RTX 3090. **Host:** Max 2027.1, 29.1.0.11426. **Build:** MSVC 14.38.33130, Release, matching Max 2027 SDK, no fast-math change.

**Scene:** `Test Scene/SaveSelect 2.max`, SHA-256 `8a40f6a1a5c47eacbbee92920e131f4cae04cfb0de6be1991b4719ea2860bd2c`. Its file hash was unchanged after the tests.

**Recipe:** controller `Cyrus Scatter001`; Editable Poly surface `Plane001`; right world-X boundary edge 7, vertices 3/6, moved +150 cm; exactly one Undo; left edge 1, vertices 4/1, moved −150 cm; exactly one Undo. Each Undo verifies all original world vertex coordinates. This recipe differs from the earlier unspecified manual movement, so its timings must not be directly compared with the old named-edit windows.

Each phase warms the controller, then performs five measured `refreshAll()` calls. Manual revision invalidation includes blocker work in each full refresh. Five placement timings per layer follow; they can benefit from an existing blocker cache. Preview and render rows are exported separately: every Matrix3 float component and source index must match in original order.

| Geometry state | Original full refresh, ms | 0.60 full refresh, ms | Speedup | Original Clover placement, ms | 0.60 Clover placement, ms |
|---|---:|---:|---:|---:|---:|
| Base | 4,053.01 | 1,060.39 | 3.82× | 1,605.39 | 131.76 |
| Right extension | 4,022.92 | 1,095.00 | 3.67× | 1,830.05 | 152.66 |
| Undo right | 4,020.33 | 1,169.07 | 3.44× | 1,565.63 | 180.77 |
| Left expansion | 3,975.95 | 1,030.58 | 3.86× | 1,565.82 | 152.41 |
| Undo left | 4,025.55 | 1,007.98 | 3.99× | 1,589.15 | 132.95 |

All values are medians of five samples. Candidate full-refresh maxima by phase were 1,083 / 1,120 / 1,217 / 1,044 / 1,063 ms. Clover still has occasional 405–440 ms samples; the median is not a guarantee for every update. Five samples are insufficient for a reliable tail-latency claim.

Border placement improved from approximately 287–314 ms to 241–259 ms. Grass placement medians remain close to their previous range; no across-the-board per-layer speedup is claimed. Full controller refresh and individual placement timings have different cache states and overlapping work, so they must not be added together.

**Raw evidence:** `build/scene-benchmark-v4-final/results.json`, its per-engine `timings.csv`, `recipe.txt`, logs and 60 `.bin` outputs. The final candidate reused the verified reference measurements from `build/scene-benchmark-v2-final`; the report records that source and the original reference timestamp. Scene/recipe/trial count and frozen native/script hashes were checked before reuse. Candidate timings were measured again after the last native change. No simultaneous developer performance benchmark was run during these measurements.

The private batch configuration did not load Corona or all Forest/legacy mental ray material extensions, and the scene reports a missing renderer there. Both engines used the same configuration and source geometry, making this a useful CPU/output comparison. Material appearance, Corona 15 final rendering and IR behavior remain interactive qualification tasks.

## Native comparison

The standalone harness builds frozen/current cores with the same compiler and compares every ordered position, basis, scale, source and triangle field as exact binary data. Every timed output is checked against its own warmup; candidate outputs also match the frozen reference, including the invalid tiny-cluster error.

| Fixture | Frozen serial, ms | Candidate serial, ms | 2 participants, ms | 4, ms | 8, ms | 12, ms | Automatic, ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| 32,000 clustered candidates | 19.18 | 19.54 | 13.49 | 10.27 | 9.11 | 8.70 | 10.48 |
| 64,000 clustered candidates | 38.54 | 38.34 | 26.80 | 19.81 | 17.46 | 16.97 | 19.70 |

The final sweep uses one warmup and seven measured trials across **17 cases** at limits 1/2/4/8/12/0. It covers weighted/unweighted/legacy clustering, blur/noise, small inputs, projected movement, thinning/refill, density rejection, ordered collision/relaxation, and two closed-band cases. The 4,096-candidate automatic case took 1.48 ms versus 2.34 ms; 4,095 candidates stayed serial. A preceding 30-trial check resolved the serial unweighted-cluster regression; the final sweep retains both weighted and unweighted parity.

Small and unchanged cases show some run-to-run variation. The 200-candidate automatic median was 0.130 ms versus 0.144 ms; the 4,095-candidate case was 2.413 ms versus 2.332 ms. These are not claims of a universal improvement. The raw samples retain the differences. Closed-band preparation adds modest benefit for these short-loop native fixtures; its primary contract is exact classification and avoiding repeated preparation on larger boundaries.

**Raw evidence:** `build/cpu-benchmark-v4-final/results.json` and `build/cpu-benchmark-v4-check/results.json`. The latter is the longer development check before comment/format cleanup. [Persistent evidence summary](Performance_Evidence_2026-10-01.json) retains final build identities, sample data, output hashes and qualification results without depending on large local build artifacts.

## Experiments that were not shipped

1. A per-cell cluster-site cache increased serial cost and did not earn its complexity. It was removed; evidence is preserved under `build/performance-experiments/cluster-cell-cache`.
2. Splitting serial field evaluation from final group selection caused a repeatable unweighted-case slowdown. A first combined-return revision then slowed a weighted case. The retained implementation specializes immutable weighting mode and serial/field return mode using the same math; both rejected versions are preserved under `build/performance-experiments/serial-cluster-return*`.

The final package uses the retained implementation, not either rejected experiment.

## Verification

| Gate | Result / scope |
|---|---|
| Scatter native suites | **8 passed**, including deterministic thread limits, floating-point mode, error joins and 160,000 raw/prepared classification comparisons |
| Analyzer native suite | **1 passed**, unchanged algorithm |
| Native performance fixtures | **17 cases passed** at every tested limit; ordered binary output and error parity |
| Saved scene | **60 outputs matched**; both fixed edge moves and exact Undo restoration; original file unchanged |
| Real Max source/worker/batch fixture | Stable row identity; empty/point render policy; source scale/offset equivalence; invalid-input atomicity; serial/worker parity; multiple SDK notification types; clean layer invalidated with **one redraw request per batch** |
| Max compatibility/lifecycle fixture | Native load, script registration, placements/previews, CS Edit stack, Analyzer and synthetic scene save/reopen |
| Recorder/report fixtures | Recorder 0.2.2 context fields, sampler completion, passive/forced modes, nested traces, advancing edit IDs, errors, installer backup/idempotence/unknown-version guard; **14 Python report checks passed** |
| Generator | Isolated generation matches the packaged script byte-for-byte |
| Packages | ZIP integrity, per-file SHA-256 manifests; packaged binaries/script match the measured files |

The Max fixtures use fresh, separate hidden batch processes. They do not install into or control the artist's live Max session. Thread-launch resource failure is handled in code but was not forced in Max. Race sanitizers, renderer contention, long interactive sessions, clone/merge/reset stress, other host years and 32 GB memory qualification remain open.

## Packages and rollback

- [CyrusScatter-0.60-Max2027.mzp](../dist/CyrusScatter-0.60-Max2027.mzp): native content ID `8e008627cd38`; package SHA-256 `5babb2ac0f86c237e4db117fa51a9d4dad0e111646847e117332bf41ee810539`.
- [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp): unchanged Analyzer native engine; current tracing script.
- [Exact pre-performance reference](../dist/CyrusScatter-0.59-PrePerformance-Max2027.mzp): old native content ID `15aa02e078d4`, frozen tracing script. The ordinary 0.59 package remains preserved.

Install through Run Script, restart Max and compare the original saved scene. See the [upgrade test](Performance_Upgrade_Test_2026-10-01.md). A rollback package is not a guarantee that the older class can reopen scenes newly saved by the candidate.

## Next decisions toward interactive editing

1. **Run the artist's fixed edge/Undo test on 0.60.** Measure input-event batches, previews per edit, child-excluded work and remaining waits with the same recorder. Keep calculations, human visible-result markers and viewport FPS distinct.
2. **If repeated rebuilds remain:** trace the Scatter/Analyzer revision and callback ordering. The current batching covers one Scatter callback batch, not the whole dependency graph. Coalesce only after proving the newest result is published and Undo/redo is correct.
3. **If source/preview preparation dominates:** instrument source snapshot extraction, sampling, geometry/shading preparation, packing and drawing separately. Reuse immutable data only with complete invalidation keys. Investigate persistent blocker reuse against manual revision, CS Edit, source transforms and Analyzer changes.
4. **If drawing dominates:** prototype a supported native Nitrous instanced display, retain current budget/selection/color semantics and a fallback. Establish integration with the scripted controller before replacing the live display path. Check Standard/High Quality, navigation, topology/count changes, picking and lifecycle.
5. **If a large independent compute stage remains:** evaluate additional CPU row work or one optional GPU kernel, including transfers, synchronization, failure recovery and renderer contention. Keep sampling/RNG and ordered collision/final decisions compatible.
6. **Qualify the product:** other Max-year SDK builds and runtime tests, 32 GB systems, Intel/AMD CPUs, Corona 15 production/IR, lifecycle and memory stress. This local candidate does not complete that matrix.

No full plugin rewrite is needed for the gains already demonstrated. Async editing needs its own snapshot/generation/commit and lifetime design; it cannot be achieved merely by moving Max API calls onto workers. GPU compute is **not enabled** in 0.60. The small native cluster times, compared with the remaining roughly one-second refresh, make host preparation and display important next measurements.

## Vendor basis for the implementation and next experiment

Autodesk documents single-threaded reference/node evaluation and broader SDK thread-safety limits; this implementation confines host/runtime access to the caller. The available developer guidance is for 2026, while the extension is built and tested with the matching 2027 SDK. [Autodesk thread safety](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html)

The 2027 Node Event System documents callback begin/end around queued batches and polling for explicit dispatch; the fixture uses actual SDK dispatch to verify the batching behavior. [Autodesk Node Event System](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.html)

Max 2027 exposes `InstanceDisplayGeometry` for viewport GPU instancing, with creation/update modes and per-instance matrices/colors. Update requires an existing allocation; changes to instance count or source topology require rebuilding. The locally installed header was also inspected. Its documented sample path was absent from this SDK extraction. This API is a supported candidate for investigation, not an implemented Cyrus feature or a new capability unique to 2027. [Autodesk InstanceDisplayGeometry](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_display_geometry.html), [Autodesk IObjectDisplay2](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html)

All work in this implementation iteration stayed in the current workspace; no Git commands or subagents were used. Historical planning documents retain their original dates and scope, with current progress linked from the index and results ledger.

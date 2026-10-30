# Performance, C++ and graphics assessment

## Measurement protocol

All measurements below belong to the recorded 0.87.6.3 build/test payload. Later concurrent working-tree changes are listed in `evidence/identity.json` and are not qualified by these timings.

Machine: AMD Ryzen 5 5600X, 6 physical / 12 logical processors; NVIDIA RTX 3090, driver `32.0.16.1742`. Windows, Max 2027 SDK, MSVC 14.38.33130, Windows SDK 10.0.19041.0. Fresh x64 Release compilation uses C++20, `/O2 /Ob2 /DNDEBUG /MD /EHsc`; the numeric target additionally uses `/W4 /WX /permissive-`. These are sensible optimized settings. Not every SDK-facing or third-party target inherits the strict numeric warning policy. No new sanitizer, PGO, LTO or hardware performance-counter campaign was run.

Native microbenchmarks use one unreported warm-up, eight ordinary measured samples and a ninth separately instrumented allocation sample. The final controlled run is [benchmark.csv](evidence/benchmark.csv); [summary](evidence/benchmark-summary.json) excludes allocation-instrumented timing. The first earlier run is retained separately. No p95/p99 is claimed from eight samples. Allocation traffic counts requested ordinary `operator new` bytes, not allocator headers, all aligned/third-party allocations, RSS or peak live memory.

The independent regression probe uses fixed synthetic prepared blades and fixed seeds. `population` explicitly declares metres per unit = 1; the real garden uses centimetres. Cold source preparation and index construction are outside the warm local-update figures. No benchmark was run against the artist's active scene.

## Removed work

The original 1,024-neighbor witness no longer copies both override maps per changed neighbor. The current probe measures **39,856 allocation calls / 1,358,775 cumulative bytes**, versus the historical **2,118,614 / 285,908,326**. Timing is a few milliseconds now, but different host activity means the allocation reduction is stronger evidence than a precise elapsed-time speedup claim.

One changed transform in 1,000,000 immutable placement records now adds **208 tracked overlay bytes**, rather than copying the historical 96 MB row buffer. Selection, compaction and later consumers retain the changed transform and original identity. This does not mean the original 96 MB population or all downstream display/render data disappears.

Draw planning now constrains compact pose packing before the exact index allowance. The unchanged CPU-baked test route has its separate cost; it is not an automatic production fallback. Source capture, preparation, contact solving, pose packaging and drawing remain distinct stages.

## CPU parallelism

The same contact results matched across serial, 2, 4 and 8 participants and repeated runs. Each row below is a full numeric contact evaluation of identical simple blades against one collider, with neighbors disabled. This deliberately isolates parallel fitting and is not a representative large tree.

| Plants | 1 participant median | 2 | 4 | 8 |
|---:|---:|---:|---:|---:|
| 128 | 1.271 ms | 0.771 ms | 0.533 ms | 0.471 ms |
| 512 | 5.083 ms | 2.901 ms | 1.709 ms | 1.255 ms |

`execution.h` joins workers synchronously, carries the floating-point environment, propagates indexed failures and falls back to overwrite-safe serial work after launch failure. Interaction jobs claim work dynamically but merge in deterministic input order. Automatic policy expands to at most eight participants for a large update, and scratch admission may reduce the count. Max SDK access remains outside these numerical jobs.

Do not extrapolate eight participants as the optimum for every model. Tree guide count, contact density, per-job allocation, memory bandwidth and other Max work change the result. A persistent worker pool could avoid thread creation, but needs a measured benefit and correct shutdown/cancellation ownership. It is not the first repair required here.

## Locality and remaining global work

With one local interaction and increasing **unposed distant vegetation**, the upward-footprint index remained local: warm update medians were **0.00390 / 0.00345 / 0.00365 ms** for 1k / 10k / 100k plants. These are tiny synthetic numeric operations with no drawing. They establish that the repaired index does not automatically scan all distant vegetation for that query.

When every distant plant already has its own pose and collider, unchanged snapshot metadata becomes a different cost. The one-local-edit benchmark rises from **0.0287 ms at 128**, to **0.1457 ms at 1,024**, to **1.36645 ms at 8,192**, still with one affected plant/two contact queries. See OPT-01 for allocation evidence and a narrow optimization sequence. This is avoidable bookkeeping growth; it is not proof that normal 8,192-instance scenes are slow.

## Actual Max garden

Input was an owned byte-identical copy of the delivered `Terraces_Garden_0.87.6.1_Max2027.max`, loaded by the newly built 0.87.6.3 product with test trust. It contains six controllers and placement counts `[0,146,15845,188,1868,182]`, total **18,229**. This is the delivered planted garden, not an assumption about the original bare Terraces file. The original SHA-256 remains unchanged.

| Experiment | Fresh observation | What it establishes |
|---|---|---|
| 77 screen rays across controllers | Median 0.0554 ms; maximum 21.6825 ms including cold pick setup | Picking cost and successful bounded owner queries; no placement/upload changes |
| 24 camera submissions | Median 21.899 ms | Cached navigation with unchanged epochs and stream counters |
| 12 held Edit movements | Median native fit 17.322 ms; median CPU submission 56.350 ms | Display tickets advance while input is held; no repeated capture/preparation/cook/layout |
| 12 held scene-collider movements | Median native fit 18.867 ms; median CPU submission 61.213 ms | Same preservation and presentation behavior for a scene collider |
| Six subsequent orbit steps | Work counters unchanged | No fresh contact work for unchanged planting |

Raw [picking](evidence/garden-pick.json), [navigation](evidence/garden-navigation.json) and [held replay](evidence/garden-drag.json) preserve all samples. Do not treat cached `fit_ms` printed during orbit as a new solve. Presented-ticket observations come from the plugin; they are not hardware GPU/compositor timestamps. CPU redraw/submission duration is not FPS or physical mouse-to-screen latency. No controlled speedup over the artist-endorsed 0.87.5.6 is claimed from these runs.

## GPU path and CPU/GPU opportunities

`mesh_display.inc` uses Max graphics handles, reusable source/instance/appearance resources, HLSL Shader Model 5 programs and `DrawInstanced`. Compact guide poses and sparse transform changes reach the shader; CPU contact fitting remains in `interactions_engine.cpp`. Source geometry sharing, pose-buffer sharing and controller-wide idle/navigation quotas are real implemented features. Visibility/picking/rendering agreement needs separate checks despite their shared source math.

The current product path does not use a raw Direct3D device, CUDA/OpenCL solver or compute dispatch. It does not establish that every possible Max 2027 interop API is unavailable. A new compute path would need a versioned SDK prototype before promising zero-copy reuse, fences, device recovery or vendor-independent support.

| Candidate | Resident data / transfer and synchronization | Assessment |
|---|---|---|
| Keep current GPU deformation | Shared source corners/bindings, compact guide nodes and sparse changes; existing graphics lifetime | Preserve. Already avoids expanded per-instance vertex uploads on the normal path. |
| Batch broad-phase / simple guide contact | Numeric source guides, colliders and transforms could be resident; upload changed obstacles, retrieve or retain affected poses | Research only. Small/local batches may lose to launch/transfer costs; CPU render/audit/picking consumers still need a consistent result. |
| Detailed mesh contact on GPU | Irregular queries, branch divergence and variable work; potentially substantial residency and result handling | Higher complexity; no measured break-even or interop proof. Preserve artistic responsiveness first. |
| CPU bookkeeping and pick acceleration | Dirty obstacle slots, shared metadata, better pick broad phase; no new device synchronization | Lower-risk first experiments when profiles justify them. The 21.7ms cold pick spike is not evidence of a persistent warm bottleneck. |

Amdahl's law matters: if a measured phase were 30% of end-to-end latency, making it ten times faster would improve the whole operation only about **1.37×**, with an infinite-speed ceiling of **1.43×**. That is an illustration, not a GPU forecast. Paired phase/transfer/presentation measurements are required; dividing unrelated medians cannot prove an end-to-end speedup.

## Memory and build conclusions

The sparse-row repair is excellent; immutable generations and graphics allocation leases are worth preserving. Remaining qualifications are old/new pose coexistence, per-worker scratch, render-owned meshes, long-session resource retirement and true device loss. Render construction has explicit chunk/element/byte sizing, but renderer-owned retention is not a process-wide cap. Release symbols and a repeatable crash-symbol pipeline would improve diagnosis; they do not fix an algorithmic issue.

No evidence suggests that switching language level, turning on fast floating-point math, or adding more threads would remove the remaining global copies. Optimize measured ownership/copy boundaries before compiler or GPU research.

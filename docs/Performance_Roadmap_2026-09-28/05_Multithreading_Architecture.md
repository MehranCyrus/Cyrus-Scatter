# 05 — CPU multithreading architecture

**Proposed design:** a bounded executor for independent native work, with a serial implementation for reference/fallback. Begin with synchronous parallel calls. Multithreading can shorten an operation while the UI still waits; asynchronous UI work is a separate milestone.

## Host boundary

Autodesk documents single-threaded reference/node evaluation and broader SDK thread-safety limits. This roadmap conservatively confines scene and runtime access to the host thread. [Autodesk thread safety](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html)

```text
Host thread: validate -> evaluate scene -> copy to owned native snapshot
Workers:     read immutable data -> write disjoint indexed results
Host thread: validate result -> create Max values -> publish -> draw/update scene
```

Workers must not evaluate nodes, call MAXScript, touch GC values, create/delete scene objects, manipulate undo, access GraphicsWindow, or mutate CS Edit/modifier state. For preview math, copy Max Point3/Matrix3 data into owned plain numeric structures and verify equivalent math before dispatch. Do not assume an SDK object is thread-safe because it resembles a value type.

## T01 — Executor proof of concept

Evaluate oneTBB `parallel_for` inside a dedicated `task_arena`. Its concurrency limit applies to the arena; it is not a global limit on Max or a renderer. Explicit completion is required before teardown; destroying an arena alone does not synchronize outstanding work. [oneTBB task_arena](https://oneapi-spec.uxlfoundation.org/specifications/oneapi/latest/elements/onetbb/source/task_scheduler/task_arena/task_arena_cls)

Add a small internal interface for `forRange` and execution policy, not a general scheduling framework. Serial remains buildable with the dependency disabled. Proposed configuration names and task IDs in this package are design labels, not existing APIs.

- Use a pinned tested dependency and explicit runtime packaging. Check compatibility with the v142 and v143 compiler builds and DLLs already loaded by Max/renderers. Never overwrite a host-shipped TBB DLL.
- Record loaded module paths/versions during qualification. Test startup with other common renderer plugins. If a safe packaged dependency cannot be established, retain serial and evaluate a small private executor as a separately measured alternative.
- Start experiment limits at 1, 2 and 4 total participants; sweep higher available counts. “4” includes the calling participant when it executes work, not four workers plus the caller.
- Use serial below a measured workload threshold. Keep one parallel level active; do not nest Analyzer elements and raster tiles without a shared concurrency/memory budget.
- Select defaults from idle and renderer-contention measurements. All logical CPUs is not automatically the best default.

## Candidate stages

| Stage | Worker unit | Ordered work retained |
|---|---|---|
| Point preview transform | Selected point or fixed contiguous range | Selection, per-source offsets, stable output sequence and host publication |
| Relaxation | Output point within one iteration | Grid build, neighbor visit order, per-point sum order, iteration barrier and stopping test |
| Boundary orientation | Placement row after immutable preparation | First matching band, segment ties, deterministic error selection |
| Boundary falloff | Original placement row | Original index hashing and stable compaction |
| Analyzer raster | Row/tile writes to fixed cells | Row-major tie reduction and mode/path decisions |
| Analyzer elements | Bounded batch of `analyzeElement` calls | Original-order merge, global spacing, minimum overrides, aggregate sums and first serial error |

Keep stateful scatter sampling, growing collision acceptance, final proposal/acceptance, global Analyzer exclusion, and scene/PFlow creation serial initially. Thread-safe access to shared state alone would not preserve their algorithmic order.

## Deterministic result construction

Allocate final indexed arrays before dispatch. Each worker writes only its assigned indices and local scratch. For filtering, write flags plus un-compacted row results, then compute stable offsets and compact in original order. Avoid concurrent `push_back`, lock-contended output, `vector<bool>` bit writes, and shared RNG.

Preserve per-row arithmetic order. Store per-range statistics and combine in a fixed order if they affect decisions. Exception handling must reproduce the first failure the serial evaluation would observe; collect failures with stage/index and publish none until the ordered check succeeds. Speculative Analyzer results must not outrank an earlier serial global-spacing error.

## Memory and cache lifetime

The invocation owns inputs and outputs until every task finishes. Reference-counted immutable cache generations may be shared; invalidation creates another generation rather than mutating a live one. Scratch is bounded by tasks in flight, not one complete mesh/raster copy per logical processor.

Estimate peak as retained caches + immutable input + output + per-task scratch + simultaneous old/new cache. Reuse and eviction policies must fit the 32 GB test envelope. Fail before overflow/allocation where possible; an allocation failure must leave the old valid preview/state intact and release temporary work.

## Cancellation and reentrancy

Synchronous v1 has no detached jobs and no custom message pump. Workers can poll a native cancellation token at bounded batch boundaries if the host safely signals it, but do not promise an interactive Cancel button while the host is blocked. Handle errors by joining all work before returning.

Guard nested evaluation from callbacks and multiple controllers sharing a runtime. Do not hold a global cache lock while waiting on tasks or entering host APIs. No lazy worker startup, waiting, or loader-sensitive initialization from `DllMain`.

Before reset, unload or shutdown, reject new work, signal cancellation, join tasks, then release caches/runtime objects. Test repeated initialization and host shutdown with the dependency enabled.

## T02–T04 acceptance

Run [03](03_Compatibility_and_Regression.md) across serial/parallel modes and thread limits, repeated schedules and small/large inputs. Use race/memory tooling supported by the standalone harness and selected compiler where available; host stress tests remain necessary. Check renderer contention, worker lifetime, deterministic failures and memory high-water marks.

Enable only stages that improve total operations under [02](02_Baseline_and_Benchmarks.md). Keep individual stage switches in diagnostic builds so failures can be isolated without replacing scene data.

## Optional later asynchronous architecture

Only if active waits remain unacceptable: host captures versioned immutable requests; one bounded background job computes; newer requests cancel/coalesce older ones; host publishes only if controller lifetime, time, source, settings and scene generation still match. Keep the last valid preview. Define render/save synchronization and teardown before implementing this. Stale results and reentrancy are the main extra risks; this is not part of the first threading build.

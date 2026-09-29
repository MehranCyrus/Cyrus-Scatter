# 07 — Performance and resource strategy

## User outcomes

Measure time to the first correct preview after an input, smoothness of unchanged navigation, editing response, Analyzer completion, render preparation, and peak memory. CPU/GPU utilization is diagnostic information; the artist's waiting time and confidence are the outcomes.

Keep the existing [benchmark specification](../Performance_Roadmap_2026-09-28/02_Baseline_and_Benchmarks.md) and [compatibility contract](../Performance_Roadmap_2026-09-28/03_Compatibility_and_Regression.md). This document updates sequencing and adds product interpretation; it does not replace the detailed algorithms.

## Cost model

```text
Visible update latency = event/coalescing wait + host extraction
                      + native computation + marshaling/cache publication
                      + next display opportunity

Render startup = Cyrus evaluation + transport preparation
               + renderer translation + renderer initialization
```

Instrument nested spans with inclusive/exclusive time, cache reasons, operation counts and memory. Do not sum nested inclusive spans. Do not report a warm cache hit as a recomputation speedup or a sampling gain as a whole-render gain.

## Recommended sequence

| Step | Work | Why / exit condition |
|---|---|---|
| 1 | Baseline diagnostics and exact fixtures on 2027.1 | Identify cost and preserve behavior |
| 2 | Correctness fixes in isolated changes | A fast incorrect result has no value |
| 3 | Remove repeated work and improve measured algorithms | Better scaling can exceed the gain from more threads |
| 4 | Bound independent CPU parallel work | Improve remaining pure-native hot loops |
| 5 | Improve display/render transport when dominant | Host work may remain the limiting cost |
| 6 | Optional OpenCL experiment | Promote only if total cost beats the accepted CPU path |
| 7 | Async preview or new algorithm mode | Separate projects if measured latency still justifies them |

Steps 3 and 5 are selected by profiles. Researching a transport option can happen while baseline work proceeds, but production switching needs comparison evidence.

## CPU candidates already grounded in source

- Prepared boundary metadata and removal of repeated full `LineBand` copies.
- Exact nearest-surface queries for anchors/projected movement, retaining original face tie winners and arithmetic semantics.
- Separate accelerators for nearest-segment distance and inside/outside parity.
- Evaluation-scoped mesh/settings reuse across pipeline calls.
- Stable reserved/grouped point-preview construction.
- Bounded shading or retained-display caches if redraw costs dominate.
- Complete CS Edit visibility invalidation; global edit revision alone is insufficient.
- Analyzer boundary/raster preparation with ordered global spacing.
- PFlow grouping/ownership/signature improvements if preparation dominates.

Keep linear/small-workload paths when an index's preparation exceeds the saved work. Preserve lazy validation/error order as well as successful output.

## Threading

Independent per-row transforms, some boundary operations, relaxation output rows, and Analyzer raster tiles are plausible candidates. Growing collision acceptance, sequential final proposals, and global Analyzer spacing must retain their current order initially.

Evaluate a pinned oneTBB implementation through a narrow executor boundary and bounded arena. Its arena limit is not a global limit on Max/renderers; teardown still requires explicit task completion. The online reference is a provisional specification page, so select and test a stable library release separately. [task_arena reference](https://oneapi-spec.uxlfoundation.org/specifications/oneapi/latest/elements/onetbb/source/task_scheduler/task_arena/task_arena_cls)

Compare 1/2/4 and higher available participants, with small/large workloads and active rendering. Avoid nested unbounded parallelism, shared RNG, nondeterministic push-backs, and one executor per object. CPU saturation during IR can make the artist experience worse.

## GPU / OpenCL

Retain the [existing OpenCL experiment](../Performance_Roadmap_2026-09-28/06_GPU_OpenCL_Feasibility.md): optional runtime, live point-preview transform candidate, fixed selected indices, measured uploads/downloads and CPU fallback. If the optimized CPU kernel is too small, close the experiment or nominate another measured independent workload.

Probe actual device memory and numeric capabilities. FP64 is optional; a version string or GPU brand is insufficient. [Khronos device queries](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clGetDeviceInfo.html)

Preserve explicit buffer layout and alignment; do not assume three-component device vectors match three packed host scalars. [Khronos vector types](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/vectorDataTypes.html)

GPU math cannot be allowed to invalidate persisted edit fingerprints. A preview-only tolerance must stay out of authoritative placement, picking and render decisions. Recoverable failures disable the backend for the session and return to CPU; an in-process driver hang is not guaranteed recoverable.

No second GPU backend until the first demonstrates a supportable user benefit. Do not require a new GPU purchase to receive CPU improvements.

## 32 GB is a workload qualification target

The user's minimum is 32 GB. It is not a guarantee that every scene fits. Measure Max, scene assets, old/new caches, undo, plugin scratch, renderer translation and GPU staging together. The current higher-RAM workstation cannot establish this floor.

Retain initial experiment caps of 2 GiB transient plugin scratch and 512 MiB GPU buffers as engineering limits to validate, not advertised hardware requirements. Add a global budget across layers and operations; per-layer face limits alone do not constrain the whole plugin. Track retained capacity after stress scenes and release oversized scratch when appropriate.

Publish envelopes using instance count **and** mesh complexity, source count, boundaries, layers, display mode, host and renderer. A million cheap points and a million complex animated assets are different workloads.

## Acceptance and reporting

- Default target: at least 25% median reduction in the nominated full operation, or explicitly justify a smaller meaningful absolute saving.
- Investigate regressions beyond `max(5%, 2 ms)` and memory increases beyond `max(10%, 64 MiB)` on required cases.
- Use three warmups and 30 measured warm recomputations; separate 30 cache-hit samples and five process-cold runs. Report raw values and the limits of small samples.
- Exact relevant output/identity checks pass first; no lost edits, stale publication, leaks or renderer mismatch.
- Match actual displayed/emitted workload, not only requested count.

These are proposed experiment gates, not present speed claims. Set a baseline-derived latency budget for each flagship workflow after measurement. Do not invent a universal FPS or subsecond promise before testing.

## Responsiveness beyond compute

Existing release/IR timers contribute deliberate delay. Separate their wait from active computation before tuning them. If drag responsiveness needs background work, implement generation-safe cancellation/publication as its own milestone. Avoid custom message pumping to make a synchronous call appear asynchronous.

The performance package's F01/F03 and the 2027 portion of F02 have progressed; generator repeatability is now observed. B01–B04, actual optimization, threading and GPU implementation remain pending. The [master backlog](11_Master_Roadmap_and_Backlog.md) is the current status authority.

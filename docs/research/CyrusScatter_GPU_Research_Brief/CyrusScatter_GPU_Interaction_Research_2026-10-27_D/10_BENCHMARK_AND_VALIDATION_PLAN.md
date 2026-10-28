<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 10 — Benchmark and validation plan

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Status

All benchmark plans in this document are **[R][U] not executed** in this research environment. No GPU, D3D, Max or private Cyrus build was available.

## Questions the benchmark must answer

1. What stage dominates current input-to-present and explicit Update latency?
2. What are the actual distributions of `N`, `K`, active guides/spans, contacts and visible vertices?
3. Where is the CPU-to-GPU crossover for each source/quality/hardware class?
4. Does shader deformation reduce upload/publication cost without breaking bounds, picking or output agreement?
5. If fitting moves to GPU, do transfer, synchronization, validation and materialization preserve the gain?
6. Is CUDA materially better than OpenCL on the same NVIDIA GPU after equal tuning?
7. Can failure/device-loss/runtime-absence preserve the last complete result and CPU fallback?

## Core test dimensions

| Dimension | Core values | Stress extension |
|---|---|---|
| total instances `N` | 1k, 10k, 100k, 1M | beyond 1M only as future capability, not current support |
| affected instances `K` | 1, 10, 100, 1k, 10k | all-active where admitted |
| guides/source `G` | 1, 8, 64, supplied 451 | branched tree/shrub classes |
| spans/guide `S` | short 2–4, medium 8–16, long 32+ | highly uneven mix |
| source vertices `V` | low, medium, supplied 22,032 | high-poly/unique source stress |
| relevant colliders | 1, 8, 64 | large global collider population with few local |
| obstacle type | analytic, convex/compound, mesh BVH, SDF proxy | open/malformed/thin/animated future cases |
| pose state | rest, sparse guides, many changed, hidden groups | many unique retained poses |
| cache | cold, warm | driver/shader cache invalidated |
| change | transform-only, collider geometry, source geometry, settings | delete/Undo/scene reset/device loss |

Use a manageable fractional-factorial core, then targeted stress cases. Do not run a blind full Cartesian product.

## Required fixture classes

### Numerical micro fixtures

- one rooted guide against sphere, capsule, axis box and rotated OBB;
- segment crosses obstacle while endpoints are clear;
- visible ribbon/card intersects while guide envelope is intentionally too small;
- root inside solid;
- narrow gap and two colliders;
- sharp corner and concave closed rock;
- open/thin/malformed mesh;
- large local coordinates after/without rebasing;
- zero-length, nearly collinear and near-full-turn frames.

### Source fixtures

- single segmented blade;
- disconnected multi-blade clump;
- supplied 451-guide grass source;
- broad leaf/card source;
- branching plant with parent sockets and fixed attachments;
- multiple source revisions and seam/custom-normal cases.

### Host fixtures

- 200 plants + moving collider analogue of supplied case;
- 5k mostly unaffected with one local neighborhood;
- 100k/1M resident layouts with tiny `K`;
- increasing `K` at fixed `N`;
- mixed shaded/wireframe viewports;
- renderer/Bake/output request on same pose;
- GPU renderer active on same device where applicable.

## Metadata recorded for every run

```json
{
  "fixture_id": "...",
  "fixture_sha256": "...",
  "seed": 0,
  "units": "metres",
  "source_revisions": ["..."],
  "collider_revisions": ["..."],
  "N": 100000,
  "K": 100,
  "active_guides": 600,
  "active_spans": 4200,
  "candidate_pairs": 800,
  "visible_vertices": 2203200,
  "quality": "final|interactive-proxy",
  "precision": "cpu-fp64|gpu-fp32-local|mixed",
  "backend": "cpu|hlsl|cuda|opencl",
  "build_flags": "...",
  "os_host_sdk_renderer": "...",
  "gpu_driver_vram_display_adapter": "...",
  "warmup_iterations": 20,
  "measured_iterations": 200
}
```

## Stage measurements

Measure completed work, not command submission alone.

1. host capture and revision checks;
2. old/new neighborhood query;
3. active-list compaction/grouping;
4. contact generation;
5. guide fitting/convergence;
6. visible-surface refinement/validation;
7. canonical vertex/normal deformation;
8. H2D/D2H bytes and completed duration;
9. queue/fence synchronization;
10. host publication;
11. viewport resource update/draw;
12. input event to presented frame;
13. renderer/Bake materialization;
14. CPU RAM/VRAM reserved, committed, peak and retained;
15. cold compile/cook/cache creation;
16. failure/recovery path.

CUDA event timings, OpenCL profiling events and PIX GPU timings are useful stage evidence but are not input-to-present latency. Correlate them with host and presentation timestamps.

## Statistical reporting

For each stable configuration:

- discard or report warm-up separately;
- at least enough repetitions to estimate p50/p95/p99 and worst spikes;
- report confidence/bootstrap interval when feasible;
- report convergence/failure/fallback counts;
- report workload counters, not only scene label;
- preserve raw event traces and machine-readable summaries;
- do not average successful and failed requests into one latency number.

30/60/120 Hz (33.3/16.7/8.3 ms) are target budgets, not claims. A 4.05 ms provided contact measurement is one internal stage observation, not a frame-rate qualification.

## CPU reference fairness

Before comparing APIs:

- compile release builds with explicit vectorization/FP flags;
- use the current bounded CPU executor and record participant count;
- preallocate equivalent pools;
- separate algorithm changes from backend changes;
- run the same exact validator and output quality;
- record NUMA/core/clock/power state where relevant;
- include single-thread reference for deterministic diagnosis, not as the only CPU competitor.

## Matched CUDA versus OpenCL protocol

1. Freeze buffer schema and equations.
2. Implement the same decomposition and iteration count/convergence rule.
3. Use the same NVIDIA GPU and same resident buffers.
4. Match FP mode and fast-math policy.
5. Match scan/sort behavior or separately account for library differences.
6. Match transfer policy and queue overlap.
7. Tune both to a documented, comparable effort budget.
8. Run cold compile/JIT and warm cached cases.
9. Measure complete path and correctness.
10. Record source commit/toolkit/runtime/driver.

If OpenCL lacks an optional feature, test a portable fallback and record the capability difference rather than silently changing the algorithm.

## Crossover experiment

For each source class, sweep active work while holding resident scene constant:

```text
K = 1, 2, 4, 8, ...
active guides = measured distribution per K
```

Define:

```text
T_cpu(K) = capture + query + CPU solve + validation + publication + draw
T_gpu(K) = capture + query + transfer + GPU solve + validation + publication + draw
```

The crossover is the smallest robust workload where GPU p95 is lower by the required product margin and quality/failure behavior is equal. Store it by hardware/backend/quality/source class. Do not use a universal hard-coded `K` derived from one asset.

## Correctness metrics

| Metric | Report |
|---|---|
| root position/orientation drift | max, p99 and offending IDs |
| span length/strain | max and distribution |
| parent socket error | max translation/angle |
| residual guide envelope penetration | max depth/count |
| visible triangle clearance | min distance, overlap/containment counts |
| rest restoration | max vertex/normal error after collider departure |
| normal/tangent error | max angle and visual review |
| bounds | containment failure count and excess ratio |
| hidden groups | exact expected/actual IDs |
| source identity | topology/UV/material/source revision equality |
| CPU/GPU pose difference | max/RMS with local and world scale |
| repeatability | stable IDs/status; numeric spread under same seed |

## Max input-to-present instrumentation

Local engineering should combine:

- high-resolution timestamps at input, capture, enqueue, completion, validation and publish;
- Max redraw/upload counters;
- Windows ETW/GPUView or PresentMon-style presentation events where attachable;
- PIX for D3D frame/GPU work where permitted;
- Nsight Systems/Compute for CUDA processes/kernels **[S18–S19]**;
- OpenCL profiling events and vendor tools;
- screen/high-speed pointer-to-pixel validation for final user-perceived latency if needed; PresentMon/ETW may assist where locally validated **[S31–S32]**.

Instrument without changing event coalescing or forcing synchronous waits that invalidate the tested design.

## Memory measurement

Record:

```text
CPU source cache
CPU collider cache
CPU published result
CPU successor snapshot/scratch
GPU source/collider cache
GPU active/scratch/output
upload/readback staging
graphics buffers
renderer allocations if visible
Undo/history
peak during old+new overlap
```

Use allocator telemetry plus OS/vendor counters. Nominal device memory minus free memory is not a precise per-subsystem attribution.

## Failure and recovery tests

- missing CUDA/OpenCL runtime at plugin start;
- unsupported GPU/extension;
- allocation failure before dispatch;
- allocation failure during cache growth;
- shader/kernel compile failure;
- stale request completion;
- cancellation during each stage;
- device reset/recreation/TDR simulation where safe;
- scene reset/load/unload and plugin shutdown;
- renderer active and VRAM pressure;
- multi-adapter mismatch;
- CPU fallback correctness and last-good retention.

## Acceptance examples

### P1 shader deformation go

- exact two-instance differing poses and hidden groups;
- no source-buffer rebuild for pose changes;
- correct bounds/picking fallback;
- p95 upload+draw improves or materially reduces unique mesh expansion;
- renderer/Bake materialization matches.

### GPU solver go

- exact fixture pass and no new unresolved category;
- p95 complete path improvement at observed production workload;
- bounded memory and cancellation;
- CPU fallback and device recovery;
- distribution/load policy accepted.

### No-go

- only kernel time improves;
- final validator/materializer erases benefit;
- requires unsupported/private Max API;
- typical active work is below crossover;
- quality tier silently misses visible geometry;
- plugin cannot load or preserve last good result without runtime/device.

## Output files from local campaign

- `run-metadata.jsonl`
- `stage-timings.csv`
- `correctness-results.jsonl`
- `memory-trace.csv`
- raw profiler captures with tool/version notes
- screenshots/videos linked to fixture IDs
- signed summary with exclusions and failed runs

Do not report a single speedup number without these conditions.

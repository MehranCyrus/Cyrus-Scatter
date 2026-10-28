<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 09 — Memory, precision and hardware

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Precision policy

**[R] Mixed precision is the baseline.** Keep scene/world origins, host transforms and revisioned snapshots in high precision where the current CPU system requires it; rebase each active plant/collider query into a small local metric frame before FP32 GPU work.

### Coordinate sequence

```text
Max scene units / +Z-up / potentially large world coordinates
    → host-thread validated transform
    → metres / +Y-up authoritative numerical snapshot
    → plant-local or request-local rebase near origin
    → FP32 GPU kernels
    → local pose output
    → high-precision host transform for publication/materialization
```

A tolerance is expressed in physical metres and scaled from source dimensions, not copied as a universal epsilon.

## Numerical hazards and policy

| Hazard | Policy |
|---|---|
| large world coordinates | local rebasing; keep world origin/transform high precision |
| tiny stems | reject below admitted physical scale or use scale-relative tolerances |
| zero-length spans | preparation error; never normalize silently |
| nearly parallel/coplanar features | robust branch, bounded fallback and independent validation |
| grazing contacts | conservative gap plus exact final distance; report tolerance band |
| nonuniform/mirror/shear | unsupported in current qualification; CPU diagnostic rather than approximate GPU transform |
| NaN/Inf | validate every input/output stage; fail generation atomically |
| quaternion sign/full turn | shortest-path sign normalization; reject ambiguous full-turn preparation |
| parallel reduction | stable key and tolerance comparison; no bitwise promise |
| fast math | off by default; enable only after adversarial acceptance |

## Correctness versus reproducibility

- **Mathematical correctness:** constraints and visible clearance meet declared tolerances.
- **Stable behavior:** stable IDs, deterministic work ordering and bounded visual variation.
- **Bitwise reproducibility:** not required across CPU/GPU/architectures unless separately qualified.
- **Visual acceptance:** independent from numerical pass.

Report all four separately.

## Suggested scale-aware acceptance variables

Let `L` be source diagonal, `r_min` minimum admitted blade radius/envelope and `g` requested Contact gap.

```text
root_position_tol = max(abs_floor, rel_root * L)
length_tol_i      = max(abs_floor, rel_length * rest_length_i)
clearance_tol     = max(abs_floor, rel_clear * max(r_min, g, L))
frame_angle_tol   = declared radians
bounds_tol        = max(abs_floor, rel_bounds * L)
```

The actual constants must be calibrated against the current CPU reference and artist fixtures; none is claimed here.

## Memory categories

| Category | Residency | Invalidation |
|---|---|---|
| immutable source geometry/bindings | CPU + optional GPU | source/evaluator revision |
| collider asset BVH/SDF/proxy | CPU + optional GPU | collider geometry/representation revision |
| instance transforms/bounds/IDs | CPU, optional persistent GPU | placement/transform revision |
| compact active lists/pairs | request CPU/GPU | request |
| changed-guide poses/masks | retained publication + display | contact/source/settings revision |
| solver scratch | GPU/CPU pool | request completion/device generation |
| upload/readback staging | pooled | fence completion |
| renderer/Bake meshes | CPU/renderer | output request/pose generation |
| Undo/history | CPU persistence policy | transaction/history trim |
| compiled kernels/shaders | disk/driver cache | backend/device/driver/kernel revision |

## Lower-bound calculations

**[A]** Supplied source: `G=451`, `V=22,032`. Binary units use MiB/GiB.

### Resident instances

| Item | Assumption | 1k | 100k | 1M |
|---|---:|---:|---:|---:|
| transforms | 48 B/instance | 0.046 MiB | 4.58 MiB | 45.78 MiB |
| bounds/ID/flags | 32 B/instance | 0.031 MiB | 3.05 MiB | 30.52 MiB |
| combined lower bound | 80 B/instance | 0.076 MiB | 7.63 MiB | 76.29 MiB |

This excludes index nodes, allocator padding, overrides, source references and history.

### Pose and geometry

| Item | Per plant | 100 | 1k | 10k |
|---|---:|---:|---:|---:|
| full guide pose, 48 B × 451 | 21.14 KiB | 2.02 MiB | 20.65 MiB | 206.45 MiB |
| hidden mask, 451 bits | 57 B | 0.005 MiB | 0.054 MiB | 0.544 MiB |
| position+normal, 24 B × 22,032 | 0.504 MiB | 50.43 MiB | 504.27 MiB | 4.92 GiB |
| position+normal+tangent, 40 B × 22,032 | 0.840 MiB | 84.05 MiB | 840.45 MiB | 8.21 GiB |

Compact changed guides can be much smaller than full poses. The package therefore rejects a default design that retains full deformed meshes for every affected detailed plant.

## SDF memory examples

**[A]** Dense scalar FP32 grid memory:

```text
128³  = 2,097,152 voxels  ≈ 8 MiB
256³  = 16,777,216 voxels ≈ 64 MiB
512³  = 134,217,728 voxels ≈ 512 MiB
```

Add gradients, mip levels, occupancy/material data, alignment and multiple obstacles and the cost multiplies. A narrow-band/sparse representation reduces empty volume but adds hierarchy/index overhead and irregular access. Exact values must be measured with the chosen implementation.

## BVH memory

A triangle BVH is approximately `O(T)` nodes and leaves. Node encoding can range from compact quantized structures to wide float boxes. Report actual bytes/triangle from the selected builder, including vertices, indices and auxiliary winding/inside data. Do not use a generic node-size assumption as a production budget.

## GPU hardware qualification

### No specific card is required by this report

**[V]** Current NVIDIA product documentation includes Blackwell consumer devices with 16–32 GB classes, and CUDA documentation maps current architectures to compute capabilities. **[S15–S17]** This establishes representative test categories, not a purchase recommendation.

Test at least:

1. a lower supported VRAM device representative of artist workstations;
2. a higher VRAM device used for heavy scenes;
3. a system where the NVIDIA compute GPU is not the display adapter;
4. the same GPU under viewport-only and GPU-renderer contention.

### Feature requirements derive from implementation

- ordinary CUDA kernels require only the minimum architecture supported by the selected toolkit/build;
- graph/update/external-memory features require their documented runtime/device support;
- OpenCL requires queried extensions/version/features;
- HLSL path follows the Max graphics API/shader model actually supported in the matched host.

Do not select a CUDA minimum because it is newest. Select it after the prototype's feature set and support matrix are fixed.

## One GPU shared by Max, compute and rendering

Potential contention:

- viewport drawing and shader compilation;
- interaction kernels and transfers;
- GPU renderer BVHs/textures/kernels;
- Windows desktop composition;
- driver cache and memory eviction.

Benchmark the realistic concurrent case. A standalone idle-GPU kernel result is not an artist drag result.

## Allocation strategy

- immutable caches by source/collider revision;
- slab/capacity-class pools for active lists, pairs, contacts, poses and scratch;
- explicit per-request admission before enqueue;
- bounded one-in-flight/one-pending policy;
- no `cudaMalloc`/OpenCL allocation in the pointer-event critical path if avoidable;
- report reserved, committed, peak and fragmentation/failure separately;
- lazy eviction of unused caches by a documented policy, never current publication.

## Unified/shared memory caution

Unified memory or shared virtual memory does not remove synchronization, residency migration, page faults or adapter ownership. Treat it as an implementation option that must be profiled under Max/renderer pressure, not as free zero-copy.

## Hardware stop criteria

Reject a GPU quality tier for a qualified device when:

- minimum scene + safety reserve cannot fit without evicting critical Max/renderer resources;
- p95/p99 includes unacceptable page migration/allocation spikes;
- device/driver does not expose required extensions/features;
- compute/display adapter mismatch makes sharing unavailable and compact transfer is not worthwhile;
- recovery cannot preserve plugin and last-good scene behavior.

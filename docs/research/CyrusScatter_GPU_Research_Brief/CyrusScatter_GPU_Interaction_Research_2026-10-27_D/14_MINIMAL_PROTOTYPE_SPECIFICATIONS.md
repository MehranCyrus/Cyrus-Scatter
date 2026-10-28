<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 14 — Minimal prototype specifications

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Execution status

Every prototype below is **not executed** in this research environment. They are intentionally small, separable and falsifiable.

## P0 — Current CPU stage profiler and workload recorder

**Question:** where is the actual latency and active work?

**Build:** instrument existing native stages without changing algorithms.

**Record per request:**

```text
request key; N; candidate Q; K; sources; active groups/guides/spans;
collider pairs; iterations; visible vertices/triangles;
capture/query/fit/refine/deform/publication/upload/draw times;
CPU memory; result status; input-to-present where available.
```

**Fixtures:** supplied-style 200/1 case, 5k sparse case, production traces, increasing `K`.

**Pass:** ≥95% of measured request time attributable; counters stable; no material behavior change.

**Decision:**

- deformation/upload dominant → P1 priority;
- fit/refinement dominant at meaningful `K` → P3 priority after P1/I2 feasibility;
- publication/snapshot dominant → optimize CPU state/lifetimes before GPU.

## P1 — Max public HLSL pose-buffer proof

**Question:** can the existing public Max graphics path deform shared geometry per instance?

**Asset:** one segmented ribbon/blade with 4–8 guide nodes, UV seam, two materials and a hidden rooted group.

**Scene:** two instances sharing one source; one rest, one authored bend.

**Implementation constraints:**

- only documented Max 2027 SDK headers/methods;
- custom HLSL vertex shader through supported material handle;
- structured/typed buffer through supported graphics handle;
- no raw D3D pointer/private cast;
- CPU bounds and hit proxy.

**Checks:**

- distinct positions/normals for each instance;
- source vertex/index buffer identity unchanged after pose edit;
- correct `SV_InstanceID`/`SV_VertexID` indexing;
- wireframe/shaded mixed viewports;
- resize/device recreation/plugin unload;
- no solve/upload on camera navigation;
- CPU evaluator comparison.

**Pass:** all checks plus documented ownership.  
**No-go:** missing buffer capability, incorrect culling/picking, private API requirement.

## P2 — Canonical evaluator and visible validator

**Question:** does one pose definition produce the same deliverable geometry everywhere?

**Inputs:** authored rest and deformed guide frames; explicit span/u/full XYZ offsets; sphere/OBB/triangle obstacles.

**Implement:**

- CPU double/reference evaluator;
- CPU FP32 evaluator matching shader math;
- optional HLSL capture/readback only through supported route;
- independent visible triangle clearance routines.

**Cases:** rest reconstruction, nonzero longitudinal offset, seam IDs, quaternion sign, unsupported full turn, broad ribbon, containment, rotated box, two obstacles, cancellation/resource limit.

**Pass:** topology/UV/material IDs exact; positions/normals/bounds within tolerance; unsupported cases reject; visible contact independently clear.

## P3 — Standalone CUDA/OpenCL matched fitter

**Question:** where is the backend crossover and which API lowers total risk?

**Host:** one Windows executable with identical fixture loader and CPU reference.

**Kernels/stages:**

1. active list already supplied by CPU;
2. analytic sphere/OBB and mesh-BVH contact generation;
3. fixed-root length/rest-frame fit;
4. residual/diagnostic reduction;
5. compact pose output.

**Implementations:** CUDA and OpenCL using the same layouts/equations. Optional HLSL/D3D compute control if practical.

**Matrix:** `K=1..10k`, multiple `G/S/C`, exact and declared proxy quality, cold/warm.

**Measurements:** complete host+transfer+kernel+sync+validation, p50/p95/p99, memory, compile cold cost.

**Pass:** exact fixtures match; meaningful complete-path win at observed workloads; bounded memory/failures.

**No-go:** only kernel time wins, typical workload below crossover, output needs full mesh readback, quality diverges.

## P4 — Standalone D3D sharing proof

**Question:** can selected backend safely share an application-owned D3D11 buffer?

**CUDA variant:** reproduce official external-resource or graphics-registration pattern with explicit device/adapter and keyed mutex/map-unmap as appropriate.

**OpenCL variant:** create context for the D3D11 device; wrap buffer; acquire/write/release; draw.

**Cases:** same adapter, wrong adapter, repeated ownership, device removal, timeout, no extension.

**Pass:** correct synchronization and recovery.  
**Scope:** explicitly not Max proof.

## P5 — In-Max compact-pose asynchronous backend

**Question:** does GPU solving improve the artist path without unsafe sharing?

**Path:** CPU capture/query → GPU solve → compact pose readback → CPU independent validation → public HLSL pose upload → publish.

**Coordinator:** one in-flight + newest pending; revision keys; device generation; CPU fallback.

**Fault injections:** stale Undo, delete owner, source revision, scene reset, allocation failure, compile failure, device recreation.

**Pass:** no partial/stale publication; last-good result; p95 input-to-present improvement; no host SDK calls from callback/workers.

## P6 — Renderer/Bake/output equality

**Question:** is the feature more than viewport appearance?

**Inputs:** rest and two authored poses, hidden group, UV seams, two materials, changed normals/bounds.

**Outputs:**

- Max viewport capture/mesh diagnostics;
- selected production renderer mesh/image;
- Max Bake/export mesh and reimport;
- canonical CPU reference OBJ/debug dump.

**Pass:** same pose generation; exact topology/UV/material; position/normal/bounds tolerance; hidden groups; stable IDs; no stale output.

## P7 — Optional direct Max interop probe

Run only if installed public headers/documentation reveal a supported native resource/device interface.

**Question:** can compute write a Max-drawn buffer without host copies under documented ownership?

**Rules:**

- exact interface/header/method recorded;
- no private SDK/downcast;
- same-adapter LUID verified;
- explicit fence/ownership sequence;
- device recreation and multiple viewports;
- comparison against compact readback path.

**Pass:** material complete-path improvement and robust lifecycle.  
**No-go:** undocumented pointer extraction, ambiguous ownership, no recovery, or negligible gain.

## Common fixture format

```json
{
  "schema": "cyrus.gpu-prototype-fixture/1",
  "units": "metres",
  "up_axis": "+Y",
  "source_fingerprint": "sha256:...",
  "guides": [],
  "bindings": [],
  "triangles": [],
  "uvs": [],
  "materials": [],
  "instances": [],
  "colliders": [],
  "expected": {
    "status": "pass|fail|unsupported",
    "root_ids": [],
    "hidden_groups": [],
    "max_root_error_m": 0.0,
    "max_strain": 0.0,
    "min_visible_clearance_m": 0.0
  }
}
```

Hash each fixture and never change expected results without review/versioning.

## Common result format

```json
{
  "backend": "cpu|hlsl|cuda|opencl",
  "backend_version": "...",
  "fixture_sha256": "...",
  "request_serial": 0,
  "quality": "final|interactive-approximate",
  "actual_status": "pass|fail|fallback|unsupported",
  "stage_ns": {},
  "bytes": {"h2d":0,"d2h":0,"gpu_peak":0,"cpu_peak":0},
  "metrics": {},
  "diagnostics": []
}
```

## Prototype order

```text
P0 → P1 → P2
          ↓
          P3 → P4 → P5
          ↓          ↓
          P6 ←───────┘
P7 only after an explicit public Max API discovery
```

P0/P1/P2 can deliver value and de-risk the product even if every GPU solver prototype is rejected.

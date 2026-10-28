<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 13 — Phased implementation plan

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Sequence principle

Prove the bottleneck and output path before solving more equations on a GPU. Each phase has an explicit rollback to the CPU architecture and does not require shipping the next phase.

## Phase 0 — CPU reference, instrumentation and corpus

**Goal:** make current work and correctness observable.

**Inputs**

- current CPU fitter/validator and supplied-style fixtures;
- production anonymized traces where available;
- stable source/collider fingerprints.

**Deliverables**

- per-stage timing/counter telemetry;
- exact fixture corpus and independent visible validation;
- active workload distributions (`N,K,G,S,V,C,P,I`);
- CPU memory peaks and publication-copy costs;
- baseline p50/p95/p99 input-to-present/Update.

**Exit criteria**

- timings account for capture/query/solve/refine/deform/upload/draw/publication;
- no quality result depends only on guide centers;
- failure retention/cancel/stale fixtures pass;
- typical and stress workload distributions are documented.

**Stop/rollback:** if current CPU meets product latency at p99 and production `K` remains tiny, reject a GPU solver and continue only to Phase 1 if deformation/upload is material.

## Phase 1 — Public Max pose-buffer and HLSL deformation proof

**Goal:** test the lowest-risk GPU value.

**Inputs**

- one prepared blade/clump source;
- compact pose/mask schema;
- installed Max 2027 SDK only.

**Deliverables**

- two or more instances sharing source buffers but displaying different poses;
- CPU-computed conservative/exact bounds;
- declared hit-test path;
- buffer identity/update telemetry;
- mixed viewport/device recreation tests.

**Exit criteria**

- public API only;
- correct per-instance indexing, UV/material/visibility/normals;
- no immutable source rebuild on pose edit;
- CPU canonical materialization matches viewport positions within tolerance;
- fallback displays/restores correctly.

**No-go:** if public buffer/HLSL path cannot bind enough structured pose data or correct culling/picking is infeasible, retain CPU materialization and skip shader delivery.

## Phase 2 — Canonical CPU evaluator and output equality

**Goal:** establish one pose-to-mesh truth for viewport comparison, renderer and Bake.

**Deliverables**

- immutable source/binding contract;
- rest reconstruction tests;
- finite normals/tangents under declared policy;
- exact bounds and topology/UV/material correspondence;
- renderer/Bake/export fixture for the intended renderer.

**Exit criteria**

- viewport/CPU materialized mesh agreement;
- selected renderer and Bake consume the correct generation;
- source edit invalidation and save/reopen behavior pass;
- no GPU-only scene truth.

**No-go:** if renderer/Bake cannot receive the canonical result, stop feature release regardless of viewport success.

## Phase 3 — Standalone matched GPU fitter benchmark

**Goal:** determine whether collision/guide solving deserves GPU integration.

**Inputs**

- frozen buffer schema and CPU reference fixtures;
- CUDA and OpenCL implementations on the same NVIDIA GPU;
- no Max dependency.

**Deliverables**

- exact/approximate contact kernels;
- length/root/rest-frame constraints;
- stable diagnostic output;
- matched correctness and complete timing/memory results;
- measured crossover by source class and quality.

**Exit criteria**

- all adversarial fixtures pass or unsupported cases route to CPU;
- complete GPU path materially improves target workload p95, not only kernel time;
- bounded memory and compile/cold costs;
- no unbounded divergence or TDR-length dispatch.

**No-go:** if typical work lies below crossover or exact validation erases benefit, reject production GPU fitter.

## Phase 4 — In-Max asynchronous compact-pose backend

**Goal:** integrate only the proven solver using the safest transfer path.

**Preferred order**

1. GPU solve → compact pose readback → public Max HLSL upload.
2. Direct shared resources only after separate public interop proof.

**Deliverables**

- revisioned request coordinator;
- one in-flight/one pending bound;
- cancellation/stale/device-loss handling;
- CPU fallback and last-good retention;
- telemetry and artist status.

**Exit criteria**

- Undo/Redo/delete/reset/load/shutdown tests pass;
- no scene API from workers/GPU callbacks;
- p95 input-to-present improves under real Max load;
- device/runtime absence does not stop plugin load;
- memory peak fits supported class with reserve.

**No-go:** unsupported device ownership/private API, stale publication, or inability to recover.

## Phase 5 — Large sparse scenes and large active regions

**Goal:** qualify different scaling regimes separately.

**Campaigns**

- large `N`, tiny `K`;
- moderate `N`, large `K`;
- many sources versus one shared source;
- many colliders but few local;
- all-active offline/explicit Update tier.

**Deliverables**

- spatial-index and grouping profiles;
- cache/pool/VRAM behavior;
- chunking/admission policy;
- measured quality-tier boundaries.

**Exit criteria**

- no `N×G` or `N×V` hidden allocation;
- predictable failure/admission diagnostics;
- stable frame/Update budgets and no broad-phase locality regression;
- full-scene stress is not marketed as local realtime unless measured.

## Phase 6 — Distribution and production qualification

**Goal:** turn an optional backend into supportable product behavior.

**Deliverables**

- installer/runtime discovery and signed binaries;
- qualified GPU/driver/OS/Max matrix;
- kernel/shader cache lifecycle;
- selected renderer/Bake/export qualification;
- support diagnostics and logs;
- third-party notice/license review;
- artist documentation and recovery workflow.

**Exit criteria**

- clean systems with no GPU runtime load CPU plugin;
- unsupported devices get clear fallback, not a crash;
- update/reopen/Undo/Copy/merge work with no transient GPU data persisted;
- renderer/Bake agreement and failure retention pass;
- support team can identify backend/device/cache/failure from logs.

## Phase decision table

| Phase | Main evidence gained | Investment exposed | Rollback |
|---|---|---|---|
| 0 | true bottleneck/workload | instrumentation/tests | retain CPU |
| 1 | Max shader/buffer feasibility | small SDK prototype | CPU meshes |
| 2 | output truth | evaluator/renderer tests | no feature release |
| 3 | solver speed/correctness | standalone kernels | CPU solver |
| 4 | host lifecycle/latency | async backend | disable backend |
| 5 | scale/admission | workload campaign | bounded support |
| 6 | distribution/support | installer/matrix | CPU-only product |

## Ownership boundaries by phase

- Native C++ owns source/collider snapshots, CPU reference, active work, pose generations and lifecycle coordinator.
- Max SDK adapter runs capture/publication/display resource operations on supported host threads.
- HLSL owns display-only canonical evaluation of already-computed poses.
- CUDA/OpenCL backend, if approved, owns transient device buffers and kernels behind an optional interface.
- MAXScript/managed UI owns settings and bounded commands, not placement-sized arrays.
- renderer/Bake adapter asks the native canonical evaluator for explicit generation geometry.

## Artist-facing rollout

1. internal hidden diagnostic mode;
2. opt-in “GPU viewport deformation” beta with CPU solve;
3. optional “GPU fitting (experimental)” only after Phase 4;
4. supported GPU tier after Phase 6;
5. CPU remains a tested fallback and comparison path.

Do not expose backend selection as a promise of quality; the selected quality mode and validation status are the artist-relevant concepts.

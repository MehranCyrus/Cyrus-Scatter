# 18 — Acceptance checklist

[Contents](00_README.md) · [Research metadata](RESEARCH_METADATA.json) · [Artifact verification](ARTIFACT_VERIFICATION.json)

## Research delivery — executed checks versus implementation claims

| Requirement | This return | Evidence |
|---|---|---|
| Researcher ID A, supplied current baseline | Complete | [02](02_REQUIREMENTS_AND_CURRENT_SYSTEM.md), metadata |
| Independent current primary-source research | Complete within stated access limits | [17](17_SOURCE_LEDGER.md); exact source revisions/inspection scope |
| Separate S/V/X/E/P/U evidence classes | Applied | [00](00_README.md), chapter status statements |
| All five architecture alternatives | Analyzed | [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) |
| Four distinct population classes, no hidden N×G/N×V | Analyzed and arithmetic checked | [03](03_PARALLELISM_AND_DATA_LAYOUT.md), [09](09_MEMORY_PRECISION_AND_HARDWARE.md) |
| Public 2027 Max API findings and staged interop proof | Documented; host proof **not executed** | [07](07_MAX_2027_INTEROP_FEASIBILITY.md) |
| Matched CUDA/OpenCL comparison and graphics baseline | Reproducible plan; **not executed** | [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md), [10](10_BENCHMARK_AND_VALIDATION_PLAN.md) |
| Root/contact/visibility/static semantics | Specified | [05](05_COLLISION_AND_GUIDE_SOLVING.md) |
| Source/pose/deformation/render/Bake contract | Proposed and local gates identified | [06](06_GPU_DEFORMATION_AND_INSTANCING.md) |
| Async ownership, stale results, cancellation and recovery | Proposed, with adversarial sequences | [08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md), [14](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) |
| Memory, precision, representative hardware | Evidence and explicit estimates | [09](09_MEMORY_PRECISION_AND_HARDWARE.md) |
| Failure matrix with triggers/hazards/tests/status | Complete research matrix | [11](11_EDGE_CASE_AND_FAILURE_MATRIX.md) |
| Papers, inspected source paths, pins and licenses | Complete scoped review | [12](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md), ledger |
| Implementation gates and stop criteria | Specified; **not implemented** | [13](13_PHASED_IMPLEMENTATION_PLAN.md), [14](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) |
| Distribution/fallback and simple artist workflow | Specified | [15](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) |
| Precise local source/SDK/host questions | Specified; **not executed** | [16](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md) |
| Small executable analytic program | X01–X10 passed | [source](optional/research_checks.py), [output](optional/executed_checks.json) |
| Source manifest, relative links and ZIP checks | Actual machine-checked results included | [MANIFEST.sha256](MANIFEST.sha256), verification JSON |

## Local product gate — all unchecked

These boxes are deliberately empty. This research does not certify a production GPU backend.

- [ ] CPU evaluator and source/binding/normal/visibility contract frozen and replayable.
- [ ] Complete quality audit includes whole spans, solid containment and visible triangle surfaces.
- [ ] Exact actual G451 node/parent/binding counts and geometry fingerprint captured locally.
- [ ] P0 stage costs, map-copy/publication work and true input-to-present timing measured.
- [ ] P1 supported shader pose lookup, seams/normals/tangents, local bounds and stable per-instance picking pass.
- [ ] P2 standalone compute/sharing results separated from supported in-Max resource lifetime proof.
- [ ] Native device/context ownership and device identity documented; no private pointer extraction.
- [ ] CPU-readable completed poses remain available for validation and final geometry.
- [ ] CUDA/OpenCL algorithms, precision, populations and quality matched on one NVIDIA GPU.
- [ ] Crossover determined from complete end-to-end p95/p99 and absolute latency, not kernel-only speed.
- [ ] Sparse million-resident and large-active cases measured separately; oversized all-active configurations rejected honestly.
- [ ] Every count/work/depth/field/budget failure is incomplete or unsupported, never clear.
- [ ] Contact gap and Hide margin applied independently once in a common metric frame.
- [ ] Root position and orientation controls preserve authored semantics and infeasibility policy.
- [ ] Source/collider/binding revisions and shape/pose generations survive sorting and reuse.
- [ ] Dirty changes survive coalescing; full-map successor checks base publication sequence.
- [ ] Undo/Redo, source edits, deletion/recreation, units, load/reset and shutdown cannot publish stale jobs.
- [ ] Peak owned/scratch/staging/retirement/renderer memory measured, including opaque external allocation categories.
- [ ] No unsynchronized compute/draw access; buffers released only after all users retire.
- [ ] Device loss/reset, timeout, allocation/kernel errors and missing runtime preserve recoverable CPU data.
- [ ] Actual production renderer/version, Bake/export, off-screen instances and cancellation pass parity/ownership tests.
- [ ] Scene persistence contains no device pointers, OS sharing handles or transient compute state.
- [ ] Optional backend absence does not prevent CPU plugin startup; compiler/CRT/installer imports and notices checked.
- [ ] Cold JIT/AOT, cache corruption/invalidation and driver/architecture changes have bounded recovery.
- [ ] Camera/selection/F3/unrelated animation reuse unchanged static results and uploads.
- [ ] Artist sees accurate Ready/Updating/Retained/Preview/CPU fallback state and actionable failures.

## Explicit non-deliverables

No production repository modification, new Cyrus version, host migration, plugin binary, CUDA/OpenCL interaction backend, Max test result, renderer qualification, GPU benchmark or hardware purchase recommendation is claimed. The optional code checks mathematical controls and storage arithmetic only. The full engineering program is deliberately small enough to reject the wrong path early, but it remains local implementation and validation work.

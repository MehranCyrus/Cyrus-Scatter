<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 16 — Open questions for local Codex / engineering probes

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## How to use this list

These are precise local probes, not vague requests to “test performance.” Repository paths are supplied pointers only; researcher A did not inspect them.

## A. Current workload and CPU architecture

| ID | Local probe | Why it matters | Required evidence / decision rule |
|---|---|---|---|
| A01 | Instrument `interactions_engine.cpp` and `interactions_source.cpp` by capture/query/classify/fit/refine/deform/merge/publish. | Determines actual bottleneck before GPU design. | p50/p95/p99 plus active counters for production traces; if fit/refine is not material, reject GPU solver priority. |
| A02 | Measure successor map copying in `interactions_engine.cpp` as retained pose count grows. | GPU arithmetic cannot fix CPU generation-copy cost. | bytes/time versus retained poses; redesign state sharing if it dominates. |
| A03 | Record production distributions of `N,K,G,S,V,C,P,I`, hidden groups and unique sources. | Establishes crossover and memory design. | anonymized histogram/quantiles; no GPU capacity claim without it. |
| A04 | Verify exact CPU validator used for visible geometry and independent obstacle math. | Defines correctness reference. | source path, invariants, precision, tolerance policy and fixtures. |
| A05 | Confirm warm-start ancestry rules and whether results are history-independent for identical endpoint snapshots. | Prevents dynamic semantics leaking into static fitting. | repeated endpoint fixture from different prior paths; decision on cache key. |

## B. Source and pose schema

| ID | Local probe | Why it matters | Required evidence / decision rule |
|---|---|---|---|
| B01 | Inspect `interactions_source.h` pose representation: exact bytes per rest/changed guide, mask and rigid part. | Replaces analytical assumptions with actual memory. | `sizeof`, vector capacities, allocation traces and serialized fields. |
| B02 | Confirm binding supports explicit guide/span/u/full XYZ rest offset and frame interpolation semantics. | Required for canonical GPU/CPU evaluator. | schema/code/tests; unsupported cases and source revision key. |
| B03 | Verify semantic render vertex IDs, seam preservation, UV/material/normal/tangent ownership. | Coincident positions cannot be welded. | rest reconstruction and topology/UV/material fixture. |
| B04 | Measure certified envelope radius/width creation and failure reporting. | Guide contact is valid only if envelope covers visible geometry. | audit per guide, worst vertex witness, invalid fixture rejection. |
| B05 | Identify source edits that retain versus invalidate bindings. | Required cache/reopen behavior. | revision dependency table and tests for geometry, UV, material, guide and role changes. |

## C. Max 2027 public SDK and viewport

| ID | Local probe | Why it matters | Required evidence / decision rule |
|---|---|---|---|
| C01 | Search installed 2027 headers/samples for public buffer creation/update suitable for structured pose data. Name header/class/method. | Gate for shader deformation. | compiling minimal plugin with no private API. |
| C02 | Prove `HLSLMaterialHandle::SetBufferParameter` layout, capacity, VS access and lifetime with two instanced poses. | Determines M1 feasibility. | screenshot + captured values + source + buffer/upload counters. |
| C03 | Verify `SV_InstanceID`/draw-instance ordering across batches and material groups. | Stable pose-to-instance association. | IDs encoded into output/debug color for thousands of instances. |
| C04 | Determine whether `IVirtualDevice` has any public compute dispatch or only draw/UAV target operations. | D3D compute feasibility. | exact header methods and official sample; absence recorded, no private cast. |
| C05 | Search public SDK for native D3D device/resource access, sharing/import/export or adapter LUID. | Direct CUDA/OpenCL gate. | explicit API + ownership/sync docs. If none, choose compact transfer. |
| C06 | Determine graphics-handle invalidation/device recreation callbacks. | Safe cache lifetime. | resize/device reset/plugin unload test and documented callback sequence. |
| C07 | Verify subrange buffer updates and whether unchanged source buffers stay retained. | Drag upload cost. | buffer identity/upload counters over repeated pose edits. |
| C08 | Verify custom render item bounds/culling and separate hit-test path for shader-deformed geometry. | Viewport correctness. | deformed-extremity culling and click fixture. |
| C09 | Test mixed wireframe/shaded viewports and F3 without solve/reupload. | Preserve current behavior. | generation/upload counters remain unchanged. |

## D. CUDA/OpenCL/toolchain

| ID | Local probe | Why it matters | Required evidence / decision rule |
|---|---|---|---|
| D01 | Compile an empty CUDA backend DLL with the exact Max 2027 MSVC 14.38/CRT/plugin settings and selected toolkit. | Toolchain feasibility. | clean CI build/load, no runtime dependency in CPU core. |
| D02 | Compile OpenCL backend using pinned headers/loader with dynamic vendor platform discovery. | Portable comparator feasibility. | clean system/no platform still loads CPU plugin. |
| D03 | Record CUDA driver/runtime and OpenCL platform feature queries including graphs/command buffers/subgroups/FP64/D3D sharing. | Avoid assumed optional features. | machine-readable capability dump. |
| D04 | Run matched standalone CUDA/OpenCL fitter with identical schema/equations. | API decision. | complete-path p50/p95/p99, correctness, memory and tuning log. |
| D05 | Test CUDA Graph/OpenCL command-buffer replay only after baseline. | Submission overhead optimization. | improvement at short repeated dispatches without stale parameter bugs. |
| D06 | Verify AOT/JIT cache keys, cold time and invalidation across driver/GPU/kernel versions. | Distribution/support. | bounded cold start and reliable fallback. |

## E. Direct graphics interop

| ID | Local probe | Why it matters | Required evidence / decision rule |
|---|---|---|---|
| E01 | Standalone CUDA D3D11 buffer proof based on current sample/external-resource API. | Separates vendor API from Max. | same-adapter success, wrong-adapter failure, explicit ownership. |
| E02 | Standalone OpenCL `cl_khr_d3d11_sharing` proof. | Portability comparator. | extension query, acquire/write/release/draw, wrong adapter/no extension. |
| E03 | If C05 succeeds, reproduce direct sharing inside Max using only documented public API. | Final direct-share gate. | exact methods, LUID match, fences, mixed viewports, device recreation. |
| E04 | Compare E03 against compact pose readback/upload. | Direct sharing may not justify complexity. | complete input-to-present and memory; require meaningful margin. |

## F. Renderer, Bake and output

| ID | Local probe | Why it matters | Required evidence / decision rule |
|---|---|---|---|
| F01 | Trace `interactions_render.cpp` output ownership and selected renderer mesh request path. | GPU-only viewport is insufficient. | source methods/threads/copy count/generation key. |
| F02 | Materialize same pose through CPU evaluator for Arnold and intended production renderer(s). | Renderer qualification. | topology/UV/material/normal/position/bounds comparison. |
| F03 | Bake/export/reimport same pose and hidden groups. | Portable output and stable IDs. | exact source correspondence and tolerances. |
| F04 | Run renderer and interaction on same GPU and separate GPUs. | Contention/adapter behavior. | p95/p99, VRAM peaks, fallback status. |
| F05 | Decide authored custom normal/tangent support for first GPU tier. | Shading fidelity and binding schema. | error corpus and explicit supported/deferred contract. |

## G. Asynchrony and failure

| ID | Local probe | Why it matters | Required evidence / decision rule |
|---|---|---|---|
| G01 | Implement a fake asynchronous backend/fence without GPU. | Test lifecycle before device complexity. | Undo/delete/reset/stale/cancel/fault injection passes. |
| G02 | Prove one in-flight + newest pending coalescing and bounded arenas. | Prevent event/VRAM growth. | peak memory and skipped/stale counters under event storm. |
| G03 | Simulate allocation/compile/device failure at every boundary. | Last-good guarantee. | no partial publication; CPU fallback; clear diagnostic. |
| G04 | Test shutdown/unload while callbacks/fences pending. | Avoid use-after-free. | clean leak/crash instrumentation. |
| G05 | Verify scene persistence contains no GPU handles/cache addresses. | Portability. | save/reopen diff and CPU-only reopen. |

## H. Product and support decisions blocked

| Decision | Blocked by |
|---|---|
| ship HLSL shared-source deformation | C01–C09, P2/P6 |
| invest in GPU fitter | A01–A05 and D04 crossover |
| choose CUDA over OpenCL | D04 plus distribution/tooling economics |
| support direct zero-copy | C05, E03, E04 |
| recommend/require NVIDIA hardware | D04, E03/E04, F04 and support matrix |
| support custom normals/tangents | B03, F05 |
| claim renderer/Bake agreement | F01–F03 |
| add persistent GPU broad phase | A01/A03 plus large-`N` profile |
| add SDF interactive quality | exact mesh comparison and thin-feature error corpus |

## Required local return format

For each probe return:

```json
{
  "probe_id": "C05",
  "status": "pass|fail|not-found|not-executed",
  "environment": {},
  "source_paths_or_sdk_headers": [],
  "commands": [],
  "artifacts": [],
  "measurements": {},
  "decision": "...",
  "limitations": []
}
```

“Not found” is useful evidence when the searched SDK version, paths and terms are recorded. It is not permission to use a private interface.

# 16 — Precise questions and probes for local Codex

[Index](00_README.md) · [Max APIs](07_MAX_2027_INTEROP_FEASIBILITY.md) · [Prototype inputs](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)

**[P/U]** Repository paths below are supplied coordinator pointers, not files inspected by Researcher A. The answers must come from the actual checkout, installed 2027 SDK, host, hardware and release binaries. Report file hashes, line references and observed outputs; do not close a question by quoting this research's proposal. [PROJ02](17_SOURCE_LEDGER.md#proj02)

## Product and source probes

| Probe | Exact local action / evidence to return | Why it matters / decision blocked |
|---|---|---|
| L01 — Baseline identity | Verify build 0.87.4.3, capability 11 and schema 63 against the actual checkout and `docs/plans/interaction-hide-wireframe-20261027/DELIVERY_08743.md`; export original scoped logs and fixture hashes | Prevents comparison against a different baseline; no GPU speed claim until the reference identity is fixed |
| L02 — Source packet | Inspect `AminScatter/include/interactions_source.h` and prepared types; export one actual 451-guide source with node/span/group counts, rest lengths/frames, root modes, bindings, fixed parts and byte counts | Replaces the eight-node memory assumption; determines the admitted shader/solver schema |
| L03 — CPU objective and modes | In `interactions_source.cpp` and `CyrusVegetationLab/core/fitter/`, identify the exact objective/projection order, numerical coefficients, initialization, root position/frame implementation, failure/residual checks and budget enforcement | A mathematically different GPU algorithm cannot be presented as parity; determines supported modes |
| L04 — Surface validator | Trace per-guide mesh checks, occupancy/triangle contacts and the final audit; capture tolerances, full versus sampled coverage, actual CPU precision and cost | Establishes what final validation means; the supplied double-precision audit does not prove every fitter calculation uses double precision |
| L05 — Contact query ABI | In `interactions_geometry.h/.cpp`, inspect whole-span coverage, width/gap conventions, query completeness, overflow/inside states and witness lifetime | Blocks the GPU query port and any claim of exact clearance |
| L06 — Active-set locality | In `interactions_engine.cpp`, record the union of old, new and prior-contact neighborhoods, independently edited transforms, restoration after removal/Undo, and horizontal splitting of projected bounds | Ensures local drags do not dispatch all `N` instances or fail to restore rest |
| L07 — Retained-state copies | Measure successor map/root-count copy bytes and time at `R = 0, 1k, 10k, 100k`, if admitted, while `K = 1`; inspect clone/delta behavior | Determines whether changing the arithmetic device can affect the dominant cost |
| L08 — Evaluator/normal policy | Trace current guide-to-mesh mapping, interpolation, twist turns, rigid/fixed parts, multi-guide regions, UVs, corner normals/tangents and materials in source/render paths | Freezes one canonical evaluator; blocks shader equivalence claims |
| L09 — Fingerprint/invalidation | List which geometry/topology/UV/material/root/guide/binding edits change source keys; inspect `interactions-authoring.ms` and native consumers | Prevents stale binding/pose caches; source edits may need different invalidation scopes |
| L10 — Host capture/publication | Inspect `interactions_host.cpp`, `interactions_render.cpp`, `point_display.cpp`; log SDK thread, ownership, mesh leases and publication atomicity | Defines asynchronous ownership; no scene calls from arbitrary workers |

## Exact SDK, graphics and compiler probes

| Probe | Exact local action / evidence to return | Decision blocked |
|---|---|---|
| L11 — Installed header/version | Record Max patch, SDK version macros, compiler `cl /Bv`, `_MSC_VER/_MSC_FULL_VER`, C++ mode, v143 selection, Windows SDK and CRT; compare the official 2027 table with the supplied 14.38 build | Establishes the supported build matrix; do not assume all VS2022 compilers are equivalent |
| L12 — Retained handle surface | Inspect `Graphics/IVirtualDevice.h`, `DrawContext.h`, `VertexBufferHandle.h`, `IndexBufferHandle.h`, `TextureHandle.h`, `HLSLMaterialHandle.h`, `SmartHandle.h` and samples; record public map/import/export/native-resource operations and restrictions | Determines the compact upload/deformation route; no cast to internal `IRefObject` |
| L13 — Native D3D candidate | Inspect `id3d11graphicswindow.h`, `IDX11VertexShader` headers/examples and a valid `GraphicsWindow::GetInterface` pattern; null-check the public IID in actual callbacks and log active Nitrous/style and lifetime, initially without state mutation | Determines whether the documented native device is available through a supported current path |
| L14 — Resource bridge | Identify supported creation/import/binding of a plugin-owned, compute-written buffer/texture into retained drawing; record exact descriptor flags, formats, device, context, thread and fence ownership | Direct CUDA/OpenCL/D3D compute go/no-go; a non-null device alone does not close this question |
| L15 — Pose shader | In existing `mesh_display.inc`, add an isolated authored-pose test: SM5 integer lookup, float texture precision/indexing, page limits, vertex-stage fetch, and clipping/hit-test/Wireframe/material pass behavior | Determines whether A2 can ship without a compute runtime; avoid encoding stable 64-bit IDs in floats |
| L16 — Device lifecycle | Identify documented reset/recreation callbacks, the handle-release thread, rendering-thread behavior, multiviewport devices and SDK pointer lifetime | Establishes asynchronous interop/retirement safety; do not retain pointers beyond their documented callback lifetime |
| L17 — CUDA compiler | With the selected Toolkit 13.4 candidate, record exact `nvcc`, host compiler, `crt/host_config.h` guards, CUB compilation and architecture flags; compare with a separate C ABI build if necessary | Resolves the literal 193x/194x documentation gap; never use an unsupported-compiler bypass as qualification |
| L18 — OpenCL capabilities | Dump platform/device numeric version, driver, compiler/IL support, FP64 configuration, subgroup limits and extension versions/entry points; explicitly test D3D11 sharing and command-buffer features | Specification 3.1.2 and headers 3.1.1 do not prove device implementation support |
| L19 — Adapter identity | Record the actual Max DXGI adapter LUID, CUDA device LUID/UUID or D3D-specific query, OpenCL D3D devices and monitor topology before/after reset | Determines same-adapter sharing or compact transfer fallback; do not assume device ordinal 0 |

A useful **unexecuted search recipe** in the actual source/SDK workspace is:

```powershell
rg -n 'GetDevice|GetVertexBuffer|GetIndexBuffer|D3D11_GRAPHICS_WINDOW_INTERFACE_ID' "<sdk>/include/id3d11graphicswindow.h"
rg -n 'Dispatch|UnorderedAccess|OutputStreams|CopyFrom|Map|UnMap|Lock|GetPointer' "<sdk>/include/Graphics"
rg -n 'generation|revision|fingerprint|root|capsule|budget|cancel|peak' AminScatter/include/interactions_source.h AminScatter/src/interactions_source.cpp AminScatter/src/interactions_engine.cpp
```

`<sdk>` is a placeholder to replace with the installed root. These are targeted searches, not claims that a particular production symbol exists. Do not modify SDK/private headers to create a route that the public contract does not provide.

## Performance, delivery and release probes

| Probe | Exact local action / evidence to return | Decision blocked |
|---|---|---|
| L20 — Stage traces | Instrument capture, map copy, neighborhood, root classification, fit, surface refinement, deformation, upload completion, publication and presented generation for B01–B16 | Establishes the empirical crossover and actual bottleneck; CUDA event time alone is insufficient |
| L21 — Resident memory | Record source/BVH/field bytes, dense guide lookup if any, sparse poses, map nodes, graphics/renderer copies, staging/scratch and held generations; use allocator counters and the OS budget | Determines capacity/admission and retained-map redesign; nominal VRAM is insufficient |
| L22 — Actual field/proxy | If proposing an SDF, record producer/version, sign guarantee, cell size/band/error, invalidation and inside/background rules; compare with exact queries, including thin features | Determines conservatism for final use versus preview-only use; a local gradient does not certify global distance |
| L23 — Renderer identity | Name intended production renderer(s), exact builds and CPU/GPU modes; trace the interface actually consumed and the geometry path for the requested time | Final acceptance for Arnold/V-Ray/Corona; broad compatibility remains unresolved |
| L24 — Bake/export | Compare one accepted packet across the viewport, ordinary Max mesh Bake and named export formats; check indices, UVs, normals, materials, units, bounds and root errors, and confirm the source hash is unchanged | Establishes consistent output; GPU-only viewport geometry cannot substitute for Bake |
| L25 — Fault injection | Delay completions, cap allocations/queries, remove the backend DLL, invalidate source/unit/owner, simulate supported device loss/reset, abort render and close Max | Determines whether the optional backend preserves the CPU plugin and last complete publication |
| L26 — Dependency inventory | Run `dumpbin /DEPENDENTS` or equivalent on produced binaries; report exact DLL names/versions/SHA256/origin/terms and transitive core imports; test a clean machine without the Toolkit | Establishes redistribution and optional startup; generic EULA names are not the final binary inventory |
| L27 — Cold cache | Test empty/corrupt caches and changes to driver/architecture/kernel; record compilation/load bytes, time, cancellation and fallback | Establishes bounded AOT/JIT cost; cache keys must not use filenames alone |
| L28 — Pointer-to-present | Hash the saved timestamped input trace; attribute each accepted generation to a specific displayed viewport frame using ETW/PresentMon or hardware measurement | Establishes actual drag latency and staleness, not merely FPS or host submission time |

## Required decisions after probes

Return a compact decision log: **observed result → affected assumption → chosen path → remaining limitation**. If L14 fails but L15 passes, choose CPU fit + shader or compute readback + shader based on actual costs. If L04/L20 show that surface validation dominates, investigate that cost before further solver optimization. If L23 is unanswered, renderer qualification remains open even after a successful viewport demo. If the exact host/compiler combination is unsupported, isolate or change it with an explicitly qualified build; do not call a successful unofficial compilation a supported matrix.

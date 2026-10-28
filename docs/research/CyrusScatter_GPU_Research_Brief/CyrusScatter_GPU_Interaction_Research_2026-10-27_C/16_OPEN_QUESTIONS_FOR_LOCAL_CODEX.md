# 16 — Precise local source, SDK and host probes

[Contents](00_README.md) · [Interop](07_MAX_2027_INTEROP_FEASIBILITY.md) · [Memory](09_MEMORY_PRECISION_AND_HARDWARE.md) · [Benchmark plan](10_BENCHMARK_AND_VALIDATION_PLAN.md) · [Prototypes](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)

**Status: proposed; none of these local probes was executed here.** The repository paths below come from the supplied context. They are investigation pointers, not files inspected by researcher A. Public SDK evidence is established in chapter 07; its applicability to the installed plugin remains unresolved. Return a repository commit, Max/SDK build, configuration, fixture fingerprints, commands, logs and explicit pass/fail/unsupported status for each probe. Missing access leaves a decision blocked, not passed.

## L01 — Freeze the actual preparation and pose schema

**Inspect:** `AminScatter/include/interactions_source.h`, `CyrusVegetationLab/experiments/stem-live/` and `CyrusVegetationLab/core/fitter/`.

Export the supplied 451-guide source's actual node-count histogram, total nodes, span counts, parent depths, root groups, fixed rings, binding influences, rigid parts and rest/posed sharing. Identify allocation ownership and source-edit invalidation. Eight nodes per guide is this report's hypothetical arithmetic input.

**Artifact/gate:** machine-readable inventory and schema/fixture hashes. Recalculate chapter 09 with real counts. Reject a GPU layout that loses authored overrides, rest curvature, twist or attachment identity. This blocks accurate memory admission and guide-kernel scheduling.

## L02 — Separate neighborhood cost from retained-state copying

**Inspect:** `AminScatter/include/interactions_engine.h` and `AminScatter/src/interactions_engine.cpp`.

Instrument old/new lookup, candidate deduplication, job preparation, worker execution, map copying, merge and publication separately. Hold one active fixture constant while increasing unrelated retained deformations; then vary resident `N` with fixed active `K/H/Q`. Record copied entries/bytes and allocations alongside elapsed time. Track Manual pending versus published populations explicitly.

**Artifact/gate:** stage CSV with counts, p50/p95/p99 and completion boundaries using chapter 10. If cost follows retained `D` despite constant active work, prioritize persistent/chunked maps before GPU solving. A faster kernel does not pass this gate when successor-ready latency remains dominated by copies.

## L03 — Count collision, refinement and materialization work

**Inspect:** `AminScatter/src/interactions_source.cpp`, `AminScatter/include/interactions_geometry.h`, `AminScatter/src/interactions_geometry.cpp` and `AminScatter/src/interactions_render.cpp`.

Count root classifications, whole-span queries, BVH visits, generated contacts, refinement passes, audited vertices/triangles, mesh materializations and copied bytes. Identify exact budget exits and completeness propagation. Replay endpoints-outside crossing, fully contained spans, broad leaves, two obstacles and a deliberately exhausted budget; do not rerun historical results under a new label.

**Artifact/gate:** call graph, bounded counters and failure-preservation trace. Reject a candidate query API that converts missing samples or exhausted work into clear. Surface-audit/materialization dominance favors deformation work; query dominance justifies a narrow solver experiment.

## L04 — Establish the compiler and binary boundary

**Inspect:** actual plugin `.vcxproj`/`.props`/`.targets`, installed Max 2027 SDK sample property sheets and backend imports. Search `PlatformToolset`, `VCToolsVersion`, `RuntimeLibrary`, `LanguageStandard`, iterator/debug settings and exception configuration; record `cl /Bv` and NVCC host selection.

The public requirement is v143/C++20; Autodesk separately identifies v14.38 build tools. IDE version alone is insufficient. [M28](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html) [M29](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/)

**Artifact/gate:** exact compiler/CRT/flags matrix, imported-DLL report and CPU-only startup log with optional runtime absent. Reject backend adoption if it breaks baseline loading or requires unsafe cross-DLL allocation ownership. This blocks packaging, not mathematical prototyping.

## L05 — Identify the real native device and resource bridge

**Inspect:** `mesh_display.inc`, `point_display.cpp` under `AminScatter/src/`, plus installed `id3d11graphicswindow.h`, `Graphics/DrawContext.h` and SDK DX11 examples.

In an allowed current-viewport scope, probe `D3D11_GRAPHICS_WINDOW_INTERFACE_ID` and `ID3D11GraphicsWindow::GetDevice`; resolve the actual acquisition signature without forced casts. Record DXGI LUID, vendor/device, CUDA/OpenCL match and graphics-device epoch across viewports/recreation. Then identify a documented plugin-owned resource consumption path. `GetVertexBuffer(length,FVF)` does not unwrap a retained handle. [M10](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d3_d11_graphics_window.html)

**Artifact/gate:** minimal source, ownership citations and I2b logs from chapter 07. Device discovery alone passes no sharing gate. Reject private extraction, undocumented COM ownership or unsafe context submission; retain compact readback/public upload.

## L06 — Prove pose lookup and stable instance addressing

**Inspect:** current HLSL and stream declarations in `mesh_display.inc`; SDK `VertexBufferHandle`, `HLSLMaterialHandle`, `TextureHandle` and `MaterialRequiredStreamElement` headers.

Try documented buffer binding, then float-texture integer loads, using one ribbon with two different CPU poses. Test partial updates, offsets, strides, page boundaries, sorted instances and IDs beyond FP32's exact-integer range. Keep integer identity lookup separate from float transforms. Verify the last-stream instance restriction and material pass requirements.

**Artifact/gate:** shader source, compilation diagnostics, byte/stride assertions and per-instance output checks. The proposed 80-byte scalar transfer record needs explicit offsets; a 16-byte-aligned quaternion can pad it. Use a separate rebased graphics stream. Reject silent misindexing or fallback to an unbounded constant palette.

## L07 — Qualify normals, visibility, picking and culling

**Inspect:** `AminScatter/src/point_display.cpp`, `mesh_display.inc`, `ICustomRenderItem` and `CustomRenderItemHandle`.

Run seam-split broad leaves, branch attachments and hidden rooted groups through mixed shaded/Wireframe viewports. Compare normals/tangents with the canonical CPU evaluator. Test stable per-instance picking after sorting and compaction: default render-node hit detection is insufficient. Publish conservative **item-local** deformed bounds before culling; `Realize` may be skipped for culled items. `SetVisibilityGroup` is not a root mask. [M01](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_custom_render_item_handle.html) [M02](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html)

**Artifact/gate:** numeric comparisons, pick-ID trace and viewport captures. Camera/selection/F3 changes must not recook contact or upload unchanged poses. Reject disappearing geometry, stale bounds or hidden-group picking discrepancies.

## L08 — Identify the production renderer and final-geometry path

**Inspect:** `AminScatter/src/interactions_render.cpp`, host object mesh callbacks and actual Bake/export entry points. Record renderer name/version, render mode and exporter; these were not supplied.

Trace requested time/revision to validated CPU source/bindings/poses and final mesh ownership, including `GetRenderMesh`/multiple-mesh callbacks where used. Test off-screen objects, pending previews, UV/normal splits, materials, hidden groups, cancellation and reload.

**Artifact/gate:** renderer/Bake/export comparison from identical pose IDs and explicit mesh deletion policy. Reject rest geometry substituted for missing viewport data or approximate previews promoted to final. Keep canonical CPU materialization until the selected renderer passes I3; Nitrous success does not qualify renderer delivery.

## L09 — Prove notification coverage and revision-safe publication

**Inspect:** `AminScatter/src/interactions_host.cpp`, `interactions_engine.cpp`, `AminScatter/tools/ui/templates/interactions-authoring.ms` and `docs/ENGINEERING_FOUNDATION.md`.

Identify actual callbacks for collider/source/placement edits, unit changes, Undo/Redo, deletion and reset; log their threads. Queue A, supersede it with B, then Undo/delete before completion. Coalesce desired states while preserving dirty IDs since the **last validated publication**, including abandoned jobs. Carry `base_publication_sequence`; stale full-map successors must fail replacement or undergo explicit validated rebasing.

**Artifact/gate:** event/dependency trace and fault-injection tests. Pass only when no dirty region is lost, stale results never overwrite newer state, host objects remain off workers, and pose/visibility/bounds publish together. This blocks asynchronous production use.

## L10 — Bound device cleanup and validate the reference scope

**Inspect:** display/backend owners plus `docs/plans/interaction-hide-wireframe-20261027/DELIVERY_08743.md`. Verify precisely which historical fixtures and tolerances form the CPU reference.

Inject cancellation, failed upload, device recreation, renderer-held leases and shutdown with work outstanding. Record CPU/GPU pages, registrations, staging and retirement by generation. Cancellation must stop future chunks without freeing submitted buffers; device failure retains validated CPU poses and rebuilds display through allowed callbacks. A timeout does not permit unloading code still executing.

**Artifact/gate:** lifetime state trace, peak allocation table and clean teardown/recovery logs. Reject unexplained memory growth, dangling readers or success reported before validation/publication. Apply chapters 09/10/14 before expanding the qualified hardware or asset profile.

## Return order

Resolve L01–L04 first; run public shader proof L06–L07 independently of native sharing L05. Final geometry L08 and lifetime/revision tests L09–L10 remain release gates. Return failed and unsupported cases with evidence alongside passes, so the coordinator can choose CPU, shader deformation, staged GPU solving or direct sharing without assuming one route must win.

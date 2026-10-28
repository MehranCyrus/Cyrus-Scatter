# 07 — Max 2027 interoperability feasibility

[Index](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Source ledger](17_SOURCE_LEDGER.md)

Researcher A · 2026-10-27 · **Research and proposed tests; no Max or GPU execution**

## Decision

**Prototype the CPU-pose-to-HLSL route through public APIs first, while running a small, separate native-device feasibility probe.** Public Max 2027 documentation contains a genuine raw Direct3D 11 candidate: `ID3D11GraphicsWindow::GetDevice()`. It would therefore be wrong to conclude that the public SDK exposes no native device. It would also be wrong to treat this declaration as proof that the existing Nitrous retained render path supports asynchronous CUDA/OpenCL ownership of its resources. The missing evidence concerns active-Nitrous acquisition, buffer import/export, thread scheduling, device recreation, and retirement. [MAX11](17_SOURCE_LEDGER.md#max11) [MAX12](17_SOURCE_LEDGER.md#max12)

The current Cyrus draw path uses public handles and does not use a raw device **[Provided]**. The recommendation preserves that functioning path while investigating the additional interface, rather than turning an unproved graphics bridge into a prerequisite for all GPU work **[Proposal]**.

## 1. What the public 2027 documentation actually establishes

| Surface and header | Verified public capability | What it does not establish |
|---|---|---|
| `Graphics/IObjectDisplay2.h` | `PrepareDisplay`, `UpdatePerNodeItems`, `UpdatePerViewItems` organize shared, node-specific and view-specific display preparation. | Compute-runtime synchronization or background scene access. |
| `Graphics/ICustomRenderItem.h` | `Realize(DrawContext&)`, `Display(DrawContext&)`, `HitTest(...)`; `Display` may run multiple times per frame and culled items may not realize. | A reliable simulation clock, an unconditional per-edit job callback, or permission to fit inside Draw. |
| `Graphics/IVirtualDevice.h` | `SetVertexStreams`, `SetIndexBuffer`, `Draw`, `DrawInstanced`, output streams, `SetTargetsAndUnorderedAccessViews`, `ClearUnorderedAccessView`. | The inspected member list contains no compute `Dispatch` or native-device getter. This is a bounded finding about this interface, not the entire SDK. |
| `Graphics/DrawContext.h` | `GetVirtualDevice`, `GetViewExp`, material and transform context. | A device reference that can be retained indefinitely: the documentation warns not to store it and explains that DX11 calls can have different devices in a multithreaded environment. |
| `Graphics/VertexBufferHandle.h` | `Initialize`, range `Lock`/`Unlock`, `CopyFrom`, system/hardware realization. | An `ID3D11Buffer*` export or external native-resource import. |
| `Graphics/IndexBufferHandle.h` | Initialization, index type, range access, copy, realization. | An external-memory handle or compute ownership protocol. |
| `Graphics/TextureHandle.h` | Explicit format/usage initialization, rectangle writes, inherited `Map`/`UnMap`, subtargets. | NT shared handle creation, CUDA registration or arbitrary UAV binding. |
| `Graphics/HLSLMaterialHandle.h` | Shader source/file/resource initialization, scalar/array parameters, texture parameters, required streams. | An independently dispatchable compute pipeline, arbitrary structured-buffer import, or production-renderer material equivalence. |
| `Graphics/SmartHandle.h` | Reference-managed internal graphics objects. | `GetPointer()` returns `IRefObject*`, and the docs mark this and `GetObjectID()` for internal use. Neither is a sanctioned D3D-resource extraction route. |
| `id3d11graphicswindow.h` | `ID3D11Device* GetDevice()`, `ID3D11Buffer* GetVertexBuffer(UINT,DWORD)`, `GetIndexBuffer(UINT,DXGI_FORMAT)`; interface ID `(0x155a3968,0x14fa1b03)`. | That the returned buffer corresponds to an arbitrary retained `VertexBufferHandle`, or that the interface is available in the running Nitrous callback. |

Sources: [MAX03](17_SOURCE_LEDGER.md#max03), [MAX04](17_SOURCE_LEDGER.md#max04), [MAX05](17_SOURCE_LEDGER.md#max05), [MAX06](17_SOURCE_LEDGER.md#max06), [MAX07](17_SOURCE_LEDGER.md#max07), [MAX08](17_SOURCE_LEDGER.md#max08), [MAX09](17_SOURCE_LEDGER.md#max09), [MAX11](17_SOURCE_LEDGER.md#max11), [MAX12](17_SOURCE_LEDGER.md#max12), [MAX16](17_SOURCE_LEDGER.md#max16), [MAX17](17_SOURCE_LEDGER.md#max17).

The UAV and stream-output methods matter: a claim that Nitrous can only read CPU-created vertices would be too strong. They justify a bounded graphics-generated-buffer experiment. They do **not** by themselves establish general D3D11 compute dispatch, access to every native resource, or efficient use of many iterative collision passes. The inspected API documentation also contains legacy DX9 wording and example identifiers inconsistent with the displayed current member surface. Compile against the installed 2027 headers; do not turn old snippets into invented contemporary methods. [MAX03](17_SOURCE_LEDGER.md#max03) [MAX33](17_SOURCE_LEDGER.md#max33)

## 2. Concrete native-device candidate, with a deliberately narrow claim

Current public declarations allow the following **proposed probe**, not a tested acquisition guarantee:

1. Obtain a valid `ViewExp` through the actual supported host/display callback and its documented lifetime.
2. Obtain its `GraphicsWindow*` through `ViewExp::getGW()`.
3. Null-check `GraphicsWindow::GetInterface(D3D11_GRAPHICS_WINDOW_INTERFACE_ID)` before treating the returned documented interface as `ID3D11GraphicsWindow`.
4. If present, inspect `GetDevice()` and record adapter identity and device feature level without changing render state.
5. Establish whether this device belongs to the current Nitrous viewport and whether it is stable only for the callback or for a documented longer lifetime.

The component declarations are verified; their successful composition in the current retained path is **Unknown**. `DrawContext::GetViewExp()` gives a `const ViewExp*`; do not insert an unreviewed const-cast into production code to force this sketch to compile. Resolve the intended acquisition pattern from installed examples or Autodesk support. [MAX04](17_SOURCE_LEDGER.md#max04) [MAX12](17_SOURCE_LEDGER.md#max12) [MAX13](17_SOURCE_LEDGER.md#max13) [MAX14](17_SOURCE_LEDGER.md#max14)

There is also an explicit callback family: `IDX11VertexShader::ConfirmDevice(ID3D11GraphicsWindow*)` and `SetVertexShader(ID3D11GraphicsWindow*,int)` receive the interface. That establishes a documented caller-supplied route in the hardware-shader interface, not compatibility of this callback family with Cyrus's existing render items. Inspect the actual 2027 sample path and active visual-style behavior before choosing it. [MAX15](17_SOURCE_LEDGER.md#max15)

`ID3D11GraphicsWindow::LifetimeControl()` returning `noRelease` governs that Max interface; it is not a documented transfer of COM ownership for every pointer returned by its methods. Determine reference ownership and reset notifications before retaining a device or registering a resource. A supported route must identify both **how the pointer is acquired** and **when it becomes unusable**. [MAX11](17_SOURCE_LEDGER.md#max11)

### Conditions that stop direct sharing

Reject the direct route if it requires internal `IRefObject` casts, private virtual-table layout, detouring Max's context/swapchain, undocumented state hooks, or retaining a callback-only reference. A non-null device getter is insufficient if the only way to draw the computed resource is to bypass the retained rendering contract. These are engineering stop conditions **[Proposal]**, not assertions that every such route is intrinsically impossible.

## 3. Three different meanings of D3D interoperability

### 3.1 CUDA graphics registration

CUDA 13.4 still documents `cudaD3D11GetDevice(s)` and `cudaGraphicsD3D11RegisterResource`. Registration can retain a D3D resource; buffers and selected texture formats are accepted, while primary render targets and depth/stencil surfaces are excluded. Registration can be expensive, so resource-generation creation is the appropriate point to attempt it. [MAX22](17_SOURCE_LEDGER.md#max22)

A registered resource must be mapped for CUDA access and unmapped before graphics access. The map/unmap calls define graphics-to-CUDA and CUDA-to-graphics ordering; concurrent graphics use while mapped is undefined. Reacquire mapped pointers each mapping. This is a resource ownership exchange, not unrestricted concurrent access. [MAX23](17_SOURCE_LEDGER.md#max23)

**Proposed sequence:** create/register a plugin-owned back buffer once; wait for previous graphics readers; map; compute; unmap; signal/observe completion; publish this completed generation; draw only that generation. Current front buffers remain drawable until the new generation is ready. Registration of an arbitrary Max-owned retained buffer remains blocked until the bridge and lifetime are proven.

### 3.2 CUDA external memory and semaphores

This is a different protocol: an exporting API creates shareable resources and synchronization objects, and CUDA imports compatible handles. The CUDA 12.9.1 guide's D3D11 section documents NT handles, dedicated imports and same-device LUID matching; it also documents imported fences/keyed mutexes. The current CUDA guide refers readers to legacy D3D11 material, so this detailed recipe is labeled **archived API guidance**, with current-runtime validation required. [MAX24](17_SOURCE_LEDGER.md#max24) [MAX34](17_SOURCE_LEDGER.md#max34)

For Windows, resource creation flags are part of the contract. `D3D11_RESOURCE_MISC_SHARED`, keyed-mutex and NT-handle sharing are distinct options, with restrictions; adding a flag after creation is not an operation. `IDXGIResource1::CreateSharedHandle` requires the appropriate shareable creation combination, returns an NT handle with explicit closing requirements, and does not make an arbitrary existing buffer shareable. [MAX25](17_SOURCE_LEDGER.md#max25) [MAX26](17_SOURCE_LEDGER.md#max26)

**Proposed sequence:** own allocation and fence creation; record exact resource description; export/import on the matching adapter; establish monotonically increasing producer/consumer fence values; queue required waits before accessing; publish only completed generations; retire CUDA mappings, imported objects, OS handles and graphics resources in their documented order. Verify exact buffer/texture flags in a standalone proof before attempting them inside Max. Do not transplant one D3D11 texture example's flags into every buffer type.

### 3.3 OpenCL D3D11 sharing

`cl_khr_d3d11_sharing` defines device selection, creation from D3D buffers/textures and acquire/release commands. Feature availability must be queried; OpenCL availability alone is insufficient. A shared buffer requires a context using the corresponding D3D11 device; immutable resources are rejected by `clCreateFromD3D11BufferKHR`. [MAX27](17_SOURCE_LEDGER.md#max27) [MAX28](17_SOURCE_LEDGER.md#max28)

Acquire/release ordering is mandatory. With `CL_CONTEXT_INTEROP_USER_SYNC` false or unspecified, the acquire operation provides the documented graphics-to-OpenCL ordering; true transfers that responsibility to the application. Use completion events and correctly ordered queues. This changes neither Max resource access nor Max scene-thread requirements. [MAX29](17_SOURCE_LEDGER.md#max29)

### 3.4 D3D11 compute is a candidate, not automatically the easiest option

If an approved callback exposes the native device/context plus an approved resource path, compute shaders can avoid a separate CUDA/OpenCL graphics-sharing boundary. That may lower integration cost. However, `ID3D11Device` thread safety does not make `ID3D11DeviceContext` concurrently callable; Microsoft distinguishes them explicitly. A plugin-only mutex cannot serialize against unknown Max users of the same immediate context. [MAX30](17_SOURCE_LEDGER.md#max30)

An owned deferred context or a standalone device would still need documented command-list submission, resource compatibility and host synchronization. Do not create a new D3D12/Vulkan viewport or replace Max's swapchain to solve this problem **[Proposal]**. A supported graphics stream-output implementation could be a narrower deformation option; it needs its own resource and readback proof and does not automatically justify an iterative contact solver.

## 4. Adapter identity and topology

**Proposal based on the matching requirements above:** enumerate the actual display/render adapter and compute devices and record their identities; never assume CUDA device ordinal zero corresponds to Nitrous. For D3D11, obtain the adapter LUID through DXGI and match it to the CUDA device or use the documented CUDA D3D11 device query. UUID matching is relevant to other APIs such as Vulkan and should not be substituted for the Windows LUID contract. [MAX22](17_SOURCE_LEDGER.md#max22) [MAX24](17_SOURCE_LEDGER.md#max24)

| Configuration | Required behavior |
|---|---|
| One NVIDIA adapter drives Max and CUDA | Candidate for same-adapter sharing; still prove resources, fences and context lifetime. |
| Two NVIDIA cards | Select by identity; measure contention and explicit cross-device transfers if intentionally choosing the other card. |
| AMD/Intel display, NVIDIA compute | Use compact host readback/reupload unless a separately qualified cross-adapter route exists; no zero-copy claim. |
| Hybrid laptop / Optimus | Record the adapter actually owning the device, not only the monitor connection or marketing GPU name; repeat after power/display changes. |
| Multiple monitors | Enumerate every relevant viewport/device and test moving Max between monitors; one tested viewport is insufficient evidence. |
| Remote/headless/software viewport | Use supported CPU geometry delivery; absence of Nitrous hardware does not imply absence of a standalone compute GPU or the reverse. |

The same GPU can be busy with Nitrous and a GPU renderer. Solver kernel time without concurrent drawing/rendering is therefore only one benchmark condition. Readback may still be preferable when renderer-bound work dominates or the display adapter differs **[Proposal]**.

## 5. Fallback paths and explicit transfer cost

Let `H` be changed guides, `Q` changed guide nodes, `K` affected plants, and `Vd` materialized display vertices. This packet proposal uses 32 bytes/node and 16 bytes/changed-guide header. Exclude visibility masks, revision headers and diagnostics from the following lower bounds only when clearly itemized elsewhere.

| Path | Transfers and synchronization | Quality/host implications |
|---|---|---|
| CPU solve → supported HLSL deformation | CPU-produced pose upload `32Q + 16H`; publish completed CPU-validated result and matching draw data. | No compute-runtime bridge needed; pose texture/stream access and normals still require the in-Max proof. |
| Standalone CUDA/OpenCL solve → host → HLSL | Device-to-host `32Q + 16H`, validate/refine, then upload equivalent compact data to Max; completion and host publication between stages. | Keeps compute on another device possible; CPU refinement can erase benefit and must be measured. |
| Standalone compute → host → CPU mesh → Max | Compact readback, CPU evaluator, then at least `24Vd` upload for FP32 positions/normals. | Most conservative integration fallback; topology/material streams usually remain shared/cached. |
| Compute produces complete meshes | At least `24Vd` readback plus display upload if direct sharing absent. | Often destroys the intended bandwidth advantage; valuable only for justified large batches or final offline delivery. |

**Analytical example, not a benchmark:** assume 451 changed guides/plant, eight nodes/guide (not supplied source fact), and the provided 22,032 vertices. One fully active plant has 115,456 bytes of node poses plus 7,216 bytes of guide headers, versus 528,768 bytes of positions/normals. For 10,000 fully active plants, node poses alone are 1.15456 GB, guide headers 72.16 MB and positions/normals 5.28768 GB. A host round trip doubles the compact payload traffic before accounting for other copies. At a hypothetical completed payload rate `B` bytes/s the transfer-only lower bound is `bytes/B`; do not advertise that as drag latency. Sparse changes can be far smaller; all-active detailed clumps are not free through instancing.

## 6. Interop proof: four separate passes

All tests below are **Not executed**. Passing one row does not pass later rows.

| Gate | Minimal input and output | Instrumentation and pass condition | Stop/fallback |
|---|---|---|---|
| I0: standalone computation | Deterministic small pose/vertex packet; CPU reference and one CUDA/OpenCL/D3D compute backend. | Readback completion; element errors and nonfinite flags; actual compiler/device/runtime recorded. | Fix arithmetic/toolchain; no Max claim. |
| I1: standalone sharing | Plugin-owned D3D11 buffer/float texture, matching-adapter compute writer, draw/readback checker. | Repeated producer/consumer generations, checksums/canaries, wrong-adapter rejection, recreation and teardown; no concurrent ownership or stale samples. | Use host transfer; no in-Max claim. |
| I2a: in-Max public acquisition | Tiny independent SDK utility/custom item; enumerate documented interface and device identities without state mutation. | Actual headers/build, callback/thread logs, null/validity behavior, available resource bridge and documented ownership. | If absent or unsupported, retain public-handle upload. |
| I2b: in-Max delivery | Shared-source blade strip + two distinct pose packets, mixed shaded/Wireframe views, picking, resize/reset. | Latest complete generation only; correct geometry/normals/visibility; no uploads on unchanged redraws; no private casts; supported lifetime path identified. | CPU-pose/HLSL or CPU mesh. A draw succeeding once is insufficient. |
| I3: final delivery | Same revision materialized via CPU canonical evaluator, Bake, exporter and each selected renderer/build. | Topology/material/UV/corner-normal/bounds parity; final collision audit; render abort; no unpublished pose. | Do not advertise production GPU feature for an unqualified renderer/export path. |

**Proposed size:** 256 vertices, two guides, two instances, one hidden root group, two material slots, an explicit normal seam and UV seam. Then increase only pose-table pages to test indexing and resource limits. Use deliberately alternating generation tags and delayed completions to expose stale publication. Include frame quaternion sign changes that represent the same rotation. No collision solver is required for I2: authored pose packets isolate graphics feasibility.

For I2b, run 1,000 deterministic update/publication/retirement cycles plus deletion/Undo/Redo/scene reset/device recreation at designated cycles. Require zero invalid reads, stale publications or leaked live generations, and exact expected hidden-group topology. This is a proposed test count and acceptance gate, not a measured reliability figure. Profile actual upload/readback completion and input-to-present separately.

## 7. Toolchain discrepancy must be resolved before investment

The public 2027 requirement table specifies VS 2022 17.14.13, v143, C++20, Windows SDK 10.0.19041.0, .NET 10 and Qt 6.8.3. Autodesk's 13 April 2026 announcement also notes DirectX 9 header removal and migration to DX11 equivalents. The supplied MSVC 14.38.33130 build is a **provided observed compilation**, not automatically the current official combination. [MAX01](17_SOURCE_LEDGER.md#max01) [MAX02](17_SOURCE_LEDGER.md#max02)

Record `cl /Bv`, complete `nvcc --version`/host flags, installed SDK build, `_MSC_VER`, language mode and CRT ownership. Resolve the CUDA guide's host-compiler table against the actual compiler diagnostics and NVIDIA support statement; omission of a compiler family from a table is a documentation/qualification gap, not proof of successful or impossible compilation. A separately loaded C ABI compute DLL is a proposed isolation technique, not permission to mix CRT allocators or C++ objects across module boundaries.

## 8. Precise local probes

- Search installed `maxsdk/include` and `maxsdk/howto` for `ID3D11GraphicsWindow`, `D3D11_GRAPHICS_WINDOW_INTERFACE_ID`, `ID3D11DeviceContext`, `SetTargetsAndUnorderedAccessViews`, `SetOutputStreams`, `SharedHandle`, `Dispatch`, and creation/release/reset callbacks. Record exact 2027 files and whether each method is public. A search hit in an internal header is not permission.
- Inspect actual `AminScatter/src/mesh_display.inc` and `point_display.cpp` only locally: identify current resource owners, upload points, instance stream layouts, material passes, culling/picking and reset behavior. External Researcher A did not access them.
- Determine whether public handles support the required FP32 pose-texture reads in the vertex stage, integer indexing, partial writes and page sizes. Compare a constant-array microprototype with a paged texture route.
- Ask Autodesk specifically whether native compute submission on the `ID3D11GraphicsWindow` device is supported from this custom render-item path; what context/callback is authorized; and whether there is a public native-resource import/export bridge and retirement notification. “Does Max support CUDA?” is too vague.
- Inspect renderer output implementation and identify which of the standard mesh, multiple-mesh, particle/instance or renderer-specific interfaces each production renderer actually requests. Measure whether unique poses materialize once per generation or repeatedly per pass.
- Establish how graphically retained results are destroyed when Nitrous is already invalid; do not call dead-device methods during plugin shutdown.

The unresolved high-risk question is thus precise: **Can the actual Max 2027 retained path consume plugin-owned compute-written resources through documented interfaces, with supported synchronization and lifetime?** The public native-device declaration makes this worth testing; it does not settle it.

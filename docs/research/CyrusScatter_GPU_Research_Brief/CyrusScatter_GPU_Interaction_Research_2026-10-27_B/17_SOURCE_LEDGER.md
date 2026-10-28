# 17 — Source ledger

[Index](00_README.md) · [Evidence vocabulary](00_README.md#evidence-labels) · [Reusable implementations](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md)

**Researcher A · Source access cutoff: 27 October 2026.** This ledger has 143 reference records: 141 public-source records and two supplied project documents. Multiple records can describe different inspected sections or versions of the same URL; the public records contain 134 distinct URLs. It is not a count of independent experiments.

Public capabilities below come from official documentation, original papers, or inspectable source. Release/tag identity, readable rolling source, a pinned source body, and executed behavior are different evidence levels. A verified release commit does not imply that an inaccessible pinned file body was inspected. Dates are reported as shown or left unknown; a software version is not a publication date. Historical sources are identified explicitly.

The two project records are supplied context. No private checkout or underlying host evidence was accessed. Report-local results from papers or vendors do not become measurements of Cyrus. Researcher A's actual executions are restricted to the small scripts and package checks in [analysis/EXECUTED_CHECKS.md](analysis/EXECUTED_CHECKS.md).

License entries are scoped research observations, not a complete dependency or installer audit. No third-party source tree, binary, paper PDF, or proprietary asset is redistributed in this package. Exact adopted revisions and their transitive dependencies require the local audit specified in chapters 12, 15 and 16.

The same records are available as [source_ledger.json](analysis/source_ledger.json). Reference IDs remain stable within this package.

## Supplied project evidence

<a id="proj01"></a>

### PROJ01 — Supplied research assignment

**Source:** [Supplied research assignment](inputs/RESEARCH_PROMPT.md)

- **Organization / author:** User / local coordinator
- **Version / revision:** GPU interaction research brief
- **Publication / update date:** 2026-10-27
- **Access date:** 2026-10-27
- **Exact inspected location:** All 14 numbered assignment sections and required file list
- **Claim supported:** Scope, evidence rules, populations, research questions and return structure.
- **Limits:** Provided instructions/context, not independent implementation evidence.
- **License / reuse observation:** User-supplied file copied unchanged for this return package.
- **Evidence confidence:** Supplied project evidence, not independently verified implementation behavior.

<a id="proj02"></a>

### PROJ02 — Supplied current system context

**Source:** [Supplied current system context](inputs/CURRENT_SYSTEM_CONTEXT.md)

- **Organization / author:** User / local coordinator
- **Version / revision:** Cyrus0.87.4.3; capability11; schema63
- **Publication / update date:** 2026-10-27
- **Access date:** 2026-10-27
- **Exact inspected location:** Present data flow, CPU/host boundaries, geometry, admissions, observed qualification, local source map
- **Claim supported:** Project facts and narrowly scoped local observations; exact provided source paths and compiler observation.
- **Limits:** No production repository, private evidence or 61-test/host campaign was independently accessed or repeated.
- **License / reuse observation:** User-supplied file copied unchanged for this return package.
- **Evidence confidence:** Supplied project evidence, not independently verified implementation behavior.


## Autodesk and geometry delivery

<a id="max01"></a>

### MAX01 — SDK Requirements

**Source:** [SDK Requirements](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html)

- **Organization / author:** Autodesk
- **Version / revision:** 2027 / 29.0
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** 2027 row of supported environment table
- **Claim supported:** VS2022 17.14.13, v143, C++20, Windows SDK10.0.19041.0, .NET10 and Qt6.8.3.
- **Limits:** Supplied MSVC14.38 build observation is not this exact published compiler matrix; no local compilation performed.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max02"></a>

### MAX02 — What's new in 3ds Max 2027?

**Source:** [What's new in 3ds Max 2027?](https://blog.autodesk.io/whats-new-in-3ds-max-2027/)

- **Organization / author:** Autodesk
- **Version / revision:** 2027 release announcement
- **Publication / update date:** 2026-04-13
- **Access date:** 2026-10-27
- **Exact inspected location:** SDK Changes
- **Claim supported:** Reports removal of DX9 SDK headers, DX11 replacements and updated core dependencies.
- **Limits:** Announcement not an interop proof; do not rely on obsolete examples still present elsewhere.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max03"></a>

### MAX03 — IVirtualDevice

**Source:** [IVirtualDevice](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_virtual_device.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/IVirtualDevice.h; member list; SetTargetsAndUnorderedAccessViews; ClearUnorderedAccessView; IsValid
- **Claim supported:** Public drawing, stream-output and UAV methods; inspected member list has no native-device getter or Dispatch.
- **Limits:** Bounded interface finding only. Other public native interfaces exist; examples retain stale DX9 references.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max04"></a>

### MAX04 — DrawContext

**Source:** [DrawContext](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_draw_context.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/DrawContext.h; GetVirtualDevice; GetViewExp
- **Claim supported:** Virtual device must be used in pipeline context rather than retained by client; exposes current ViewExp/material/transform context.
- **Limits:** No public-resource ownership transfer or successful native-device acquisition demonstrated.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max05"></a>

### MAX05 — SmartHandle

**Source:** [SmartHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_smart_handle.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/SmartHandle.h; GetPointer and GetObjectID notes
- **Claim supported:** GetPointer returns IRefObject*, with internal-use qualification.
- **Limits:** Not a supported ID3D11Resource export or reinterpret-cast route.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max06"></a>

### MAX06 — VertexBufferHandle

**Source:** [VertexBufferHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_vertex_buffer_handle.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/VertexBufferHandle.h; Initialize, Lock/Unlock, CopyFrom, RealizeToSysMemory/RealizeToHWMemory
- **Claim supported:** Public buffer creation/access/copy/realization operations.
- **Limits:** Inspected interface does not establish native-resource import/export or sharing flags.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max07"></a>

### MAX07 — IndexBufferHandle

**Source:** [IndexBufferHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_index_buffer_handle.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/IndexBufferHandle.h; Initialize, Lock/Unlock, CopyFrom, realization
- **Claim supported:** Public retained index resource operations.
- **Limits:** No compute-runtime bridge qualified.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max08"></a>

### MAX08 — TextureHandle

**Source:** [TextureHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_texture_handle.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/TextureHandle.h; Initialize; WriteOnlyLockRectangle; inherited Map/UnMap
- **Claim supported:** Texture creation and CPU writes/locks allow a pose-texture candidate.
- **Limits:** Actual vertex-stage access, updates and performance need local proof. No NT handle export established.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max09"></a>

### MAX09 — HLSLMaterialHandle

**Source:** [HLSLMaterialHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_h_l_s_l_material_handle.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/HLSLMaterialHandle.h; initialization, array/texture parameters; Detailed Description
- **Claim supported:** Public custom HLSL material and array/texture parameters, documented for viewport/Quicksilver.
- **Limits:** Not general compute dispatch or production renderer material parity.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max10"></a>

### MAX10 — RenderEnums.h

**Source:** [RenderEnums.h](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/_render_enums_8h.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/RenderEnums.h; TargetFormat; ResourceUsage
- **Claim supported:** Floating texture formats, integer formats and resource usage enums are public.
- **Limits:** Enums do not qualify every combination or maximum size on installed hardware.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max11"></a>

### MAX11 — ID3D11GraphicsWindow

**Source:** [ID3D11GraphicsWindow](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d3_d11_graphics_window.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** id3d11graphicswindow.h; GetDevice; GetVertexBuffer; GetIndexBuffer; LifetimeControl
- **Claim supported:** Public raw ID3D11Device/ID3D11Buffer accessors exist.
- **Limits:** Active Nitrous availability, correct acquisition, COM ownership and retained-buffer association remain unexecuted/unknown.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max12"></a>

### MAX12 — id3d11graphicswindow.h

**Source:** [id3d11graphicswindow.h](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/id3d11graphicswindow_8h.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** D3D11_GRAPHICS_WINDOW_INTERFACE_ID macro
- **Claim supported:** Public IID is Interface_ID(0x155a3968,0x14fa1b03); header includes Direct3D11/DXGI types.
- **Limits:** Declaration not a success guarantee for GraphicsWindow::GetInterface on a particular active driver.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max13"></a>

### MAX13 — GraphicsWindow

**Source:** [GraphicsWindow](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_graphics_window.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** GraphicsWindow.h; inherited InterfaceServer::GetInterface
- **Claim supported:** GraphicsWindow exposes an interface query mechanism.
- **Limits:** Composition with the D3D11 IID is a proposed null-checked probe; docs carry legacy warnings and state model.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max14"></a>

### MAX14 — ViewExp

**Source:** [ViewExp](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_view_exp.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** maxapi.h; getGW, IsAlive and view properties
- **Claim supported:** Current ViewExp can expose its GraphicsWindow.
- **Limits:** Correct host callback/reference lifetime must be established locally.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max15"></a>

### MAX15 — IDX11VertexShader

**Source:** [IDX11VertexShader](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d_x11_vertex_shader.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** idx11vertexshader.h; ConfirmDevice; SetVertexShader
- **Claim supported:** Documented callbacks receive ID3D11GraphicsWindow*.
- **Limits:** Callback family support in current custom render-item path is not demonstrated.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max16"></a>

### MAX16 — ICustomRenderItem

**Source:** [ICustomRenderItem](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/ICustomRenderItem.h; Realize, Display, HitTest
- **Claim supported:** Realize can be skipped when culled; Display may occur multiple times; custom hit-test hook exists.
- **Limits:** These callbacks are not solver scheduling or per-edit guarantees.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max17"></a>

### MAX17 — IObjectDisplay2

**Source:** [IObjectDisplay2](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/IObjectDisplay2.h; PrepareDisplay, UpdatePerNodeItems, UpdatePerViewItems
- **Claim supported:** Distinct shared/node/view display preparation and no-change update guidance.
- **Limits:** No async computation lifetime protocol is implied.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max18"></a>

### MAX18 — InstanceDisplayGeometry

**Source:** [InstanceDisplayGeometry](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_display_geometry.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graphics/InstanceDisplayGeometry.h; CreateInstanceData; UpdateInstanceData; GenerateInstances
- **Claim supported:** Public per-instance data and geometry stream operations.
- **Limits:** Not evidence for arbitrary custom guide lookup or external compute handles.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max19"></a>

### MAX19 — MaxSDK::Graphics instance-generation functions

**Source:** [MaxSDK::Graphics instance-generation functions](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_graphics.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** GenerateInstanceData and GenerateInstanceRenderItem overloads
- **Claim supported:** Built-in instancing generates transform-based shared geometry; extended instance geometry can override additional attributes.
- **Limits:** No automatic contact solve or unique-deformation sharing.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max20"></a>

### MAX20 — GeomObject

**Source:** [GeomObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_geom_object.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** object.h; GetRenderMesh; NumberOfRenderMeshes; GetMultipleRenderMesh and TM
- **Claim supported:** Renderer mesh methods, time parameter, abort and ownership flags.
- **Limits:** Renderer-specific instance preservation and custom GPU-resource consumption unqualified.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max21"></a>

### MAX21 — MeshNormalSpec

**Source:** [MeshNormalSpec](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_mesh_normal_spec.html)

- **Organization / author:** Autodesk
- **Version / revision:** 3ds Max 2027 public C++ API reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** MeshNormalSpec.h; per-face/corner normal indices; explicit normal flags
- **Claim supported:** Supports authored explicit corner normals and associated face topology.
- **Limits:** Correct evaluator normal policy and renderer transfer must be tested.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max22"></a>

### MAX22 — CUDA Runtime API — Direct3D 11 Interoperability

**Source:** [CUDA Runtime API — Direct3D 11 Interoperability](https://docs.nvidia.com/cuda/cuda-runtime-api/cuda_runtime_api/group__CUDART__D3D11.html)

- **Organization / author:** NVIDIA
- **Version / revision:** CUDA Runtime API 13.4
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** cudaD3D11GetDevice(s); cudaGraphicsD3D11RegisterResource
- **Claim supported:** Documents adapter matching, resource types/limits, registration ownership and potentially high registration overhead.
- **Limits:** Standalone API capability, not Max host permission.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max23"></a>

### MAX23 — CUDA Runtime API — Graphics Interoperability

**Source:** [CUDA Runtime API — Graphics Interoperability](https://docs.nvidia.com/cuda/cuda-runtime-api/cuda_runtime_api/group__CUDART__INTEROP.html)

- **Organization / author:** NVIDIA
- **Version / revision:** CUDA Runtime API 13.4
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** cudaGraphicsMapResources; cudaGraphicsUnmapResources; mapped pointer queries
- **Claim supported:** Defines mapping lifetime and ordering; graphics access while mapped is undefined.
- **Limits:** Must be combined with the host resource publication protocol.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max24"></a>

### MAX24 — CUDA C++ Programming Guide — Direct3D 11 external interoperability

**Source:** [CUDA C++ Programming Guide — Direct3D 11 external interoperability](https://docs.nvidia.com/cuda/archive/12.9.1/cuda-c-programming-guide/index.html#direct3d-11-interoperability)

- **Organization / author:** NVIDIA
- **Version / revision:** Archived CUDA 12.9.1
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Section 6.2.16.4, memory and synchronization objects
- **Claim supported:** D3D11 external memory, dedicated imports, LUID matching, NT handles and fence/keyed-mutex protocols.
- **Limits:** Archived detail consulted because current guide points to old D3D11 guidance. Must validate selected current runtime; not a Max proof.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max25"></a>

### MAX25 — D3D11_RESOURCE_MISC_FLAG

**Source:** [D3D11_RESOURCE_MISC_FLAG](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_resource_misc_flag)

- **Organization / author:** Microsoft
- **Version / revision:** Current D3D11 reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Shared, SharedKeyedMutex, SharedNTHandle constants and remarks
- **Claim supported:** Resource sharing depends on creation flags and resource-specific restrictions.
- **Limits:** Do not conflate texture and buffer recipes or assume Max requests these flags.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max26"></a>

### MAX26 — IDXGIResource1::CreateSharedHandle

**Source:** [IDXGIResource1::CreateSharedHandle](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/nf-dxgi1_2-idxgiresource1-createsharedhandle)

- **Organization / author:** Microsoft
- **Version / revision:** Current DXGI1.2 reference
- **Publication / update date:** 2022-05-24
- **Access date:** 2026-10-27
- **Exact inspected location:** Remarks and Requirements
- **Claim supported:** Shared NT-handle creation requirements, handle ownership and closing rules.
- **Limits:** No arbitrary retained resource retrofit; exact OS/device support needs probe.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max27"></a>

### MAX27 — cl_khr_d3d11_sharing

**Source:** [cl_khr_d3d11_sharing](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/cl_khr_d3d11_sharing.html)

- **Organization / author:** Khronos
- **Version / revision:** Extension revision1.0.0
- **Publication / update date:** 2020-04-21
- **Access date:** 2026-10-27
- **Exact inspected location:** Extension description; commands; version history
- **Claim supported:** Ratified extension for D3D11 device/resource sharing.
- **Limits:** Must query actual driver extension availability.
- **License / reuse observation:** Reference documentation: CC-BY-4.0; no implementation redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max28"></a>

### MAX28 — clCreateFromD3D11BufferKHR

**Source:** [clCreateFromD3D11BufferKHR](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clCreateFromD3D11BufferKHR.html)

- **Organization / author:** Khronos
- **Version / revision:** Current unified OpenCL reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Parameters, Description and error conditions
- **Claim supported:** Requires matching D3D11 context/device; immutable buffers excluded; object reference lifetime documented.
- **Limits:** Not a Max handle-import API.
- **License / reuse observation:** Reference documentation: CC-BY-4.0; no implementation redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max29"></a>

### MAX29 — clEnqueueAcquireD3D11ObjectsKHR

**Source:** [clEnqueueAcquireD3D11ObjectsKHR](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clEnqueueAcquireD3D11ObjectsKHR.html)

- **Organization / author:** Khronos
- **Version / revision:** Current unified OpenCL reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Description; CL_CONTEXT_INTEROP_USER_SYNC
- **Claim supported:** Acquire before CL use; distinguishes automatic ordering from caller-owned synchronization.
- **Limits:** Correct release and graphics publication still needed; no in-Max execution.
- **License / reuse observation:** Reference documentation: CC-BY-4.0; no implementation redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max30"></a>

### MAX30 — Introduction to Multithreading in Direct3D 11

**Source:** [Introduction to Multithreading in Direct3D 11](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-render-multi-thread-intro)

- **Organization / author:** Microsoft
- **Version / revision:** Current Direct3D11 reference
- **Publication / update date:** 2020-08-19
- **Access date:** 2026-10-27
- **Exact inspected location:** Thread safety discussion and Multithreading and DXGI
- **Claim supported:** Device and device-context thread safety differ; immediate context access requires serialization.
- **Limits:** A plugin lock alone does not coordinate with Max internal users.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max31"></a>

### MAX31 — What are the system requirements of Corona?

**Source:** [What are the system requirements of Corona?](https://support.chaos.com/hc/en-us/articles/4665349542417-What-are-the-system-requirements-of-Corona)

- **Organization / author:** Chaos
- **Version / revision:** Vendor support article current at access
- **Publication / update date:** 2026-06-10
- **Access date:** 2026-10-27
- **Exact inspected location:** Basic Facts
- **Claim supported:** Corona rendering is CPU-based, with optional GPU denoising.
- **Limits:** No exact Corona build or Cyrus renderer pass qualified here. Do not use generic host version range as plugin compatibility proof.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max32"></a>

### MAX32 — Arnold Scene Source

**Source:** [Arnold Scene Source](https://help.autodesk.com/cloudhelp/ENU/AR-Houdini/files/tutorials/kick/arnold_for_houdini_kick_ah_Arnold_Scene_Source_html.html)

- **Organization / author:** Autodesk
- **Version / revision:** Rolling Arnold documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Polymesh arrays; arrays; motion blur
- **Claim supported:** Arnold geometry has position/normal indices, UV data and explicit motion keys.
- **Limits:** General Arnold format shown in Houdini-host documentation; not a MAXtoA custom-plugin pass or current renderer pin.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max33"></a>

### MAX33 — Low-level Device API

**Source:** [Low-level Device API](https://help.autodesk.com/cloudhelp/2022/ENU/Max-Developer-Help/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/low-level_device_api.html)

- **Organization / author:** Autodesk
- **Version / revision:** Historical Max2022 developer help
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Nitrous low-level interfaces and customize material shaders
- **Claim supported:** Historical explanation of retained graphics handles and HLSL effects.
- **Limits:** Explicitly historical; DX9 references and example API cannot qualify Max2027. Current API declarations checked separately.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.

<a id="max34"></a>

### MAX34 — CUDA Interoperability with APIs

**Source:** [CUDA Interoperability with APIs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Rolling CUDA Programming Guide13.4 at access
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** 4.21.2.2 Direct3D Interoperability, especially line 868 in retrieved document: current guide explicitly directs D3D11 detail to CUDA Programming Guide 12.9; section 4.21.1 provides current map/unmap overview.
- **Claim supported:** Current guide distinguishes registration/map and external-memory/synchronization approaches; directs detailed D3D11 discussion to archived guide.
- **Limits:** Current capability not Max bridge/lifetime proof.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** High for stated public declaration; host execution unverified.


## Compute APIs, toolchains, hardware and distribution

<a id="api01"></a>

### API01 — CUDA Toolkit Release Notes

**Source:** [CUDA Toolkit Release Notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** 13.4 Update 2
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Component versions table; driver compatibility/release tables; Windows driver installation paragraph
- **Claim supported:** Compiler/runtime/NVRTC 13.4.92; CCCL 3.4.3; R615 association; Windows driver no longer bundled from 13.1.
- **Limits:** Live documentation; no Toolkit installer or driver tested.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api02"></a>

### API02 — CUDA Installation Guide for Microsoft Windows

**Source:** [CUDA Installation Guide for Microsoft Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** 13.4
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** System Requirements, table of native x86_64 compiler support
- **Claim supported:** Table lists MSVC 195x/VS2026, 193x/VS2022, 192x/VS2019; specified C++ dialect support.
- **Limits:** Literal table omits 194x; does not prove all VS2022 194x unsupported. Verify installed host_config and actual compiler.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api03"></a>

### API03 — NVIDIA CUDA Compiler Driver NVCC

**Source:** [NVIDIA CUDA Compiler Driver NVCC](https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** 13.4
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Supported GPU architectures; --gpu-architecture/--gpu-code; --use_fast_math, --ftz, --prec-div, --prec-sqrt, --fmad
- **Claim supported:** Architecture targets begin at sm_75; separate virtual/real architecture code; fast-math options alter numerical behavior.
- **Limits:** Documentation only; no compiler run, AOT binary, PTX or compatibility test.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api04"></a>

### API04 — Minor Version Compatibility

**Source:** [Minor Version Compatibility](https://docs.nvidia.com/deploy/cuda-compatibility/minor-version-compatibility.html)

- **Organization / author:** NVIDIA
- **Version / revision:** CUDA 13.x compatibility
- **Publication / update date:** 2026-09-09
- **Access date:** 2026-10-27
- **Exact inspected location:** Compatibility table and limitations
- **Claim supported:** CUDA 13.x minor compatibility requires driver family 580 or newer, with feature and PTX limitations.
- **Limits:** Not an exact qualified Windows driver build for Cyrus; newer features may require newer drivers.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api05"></a>

### API05 — OpenCL API Specification

**Source:** [OpenCL API Specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html)

- **Organization / author:** Khronos Group
- **Version / revision:** 3.1.2; commit 219be24fc8947c68ee45b4d25b55a92b8f799f29
- **Publication / update date:** 2026-09-17
- **Access date:** 2026-10-27
- **Exact inspected location:** Version header; device feature queries; UUID/LUID validity; execution/memory model
- **Claim supported:** Current specification version and device capability model; adapter identity must honor validity and implementation support.
- **Limits:** Specification version is not the installed NVIDIA implementation version.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api06"></a>

### API06 — cl_khr_command_buffer

**Source:** [cl_khr_command_buffer](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/cl_khr_command_buffer.html)

- **Organization / author:** Khronos Group
- **Version / revision:** Ratified 1.0.0
- **Publication / update date:** 2026-09-09
- **Access date:** 2026-10-27
- **Exact inspected location:** Status; version history; command recording limitations; companion extension references
- **Claim supported:** Base command-buffer extension is ratified; device support and mutable/multi-device extensions require separate checks.
- **Limits:** Page retains older experimental wording; status/history explicitly mark ratification. No target-driver feature probe.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api07"></a>

### API07 — clBuildProgram

**Source:** [clBuildProgram](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clBuildProgram.html)

- **Organization / author:** Khronos Group
- **Version / revision:** Current unified OpenCL reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Description; options; callback; compiler/build errors
- **Claim supported:** Program building and asynchronous callback/build-status obligations.
- **Limits:** Compiler and IL/binary support are implementation/device dependent; no build executed.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api08"></a>

### API08 — CUDA Core Compute Libraries README

**Source:** [CUDA Core Compute Libraries README](https://github.com/NVIDIA/cccl)

- **Organization / author:** NVIDIA
- **Version / revision:** Live main, retrieved 2026-10-27
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** README Overview and usage
- **Claim supported:** CCCL comprises CUB, Thrust and libcu++; supplied as reusable source/header libraries.
- **Limits:** Live README is not the exact release-pin implementation review.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api09"></a>

### API09 — CCCL v3.4.3 release

**Source:** [CCCL v3.4.3 release](https://github.com/NVIDIA/cccl/releases/tag/v3.4.3)

- **Organization / author:** NVIDIA
- **Version / revision:** v3.4.3
- **Publication / update date:** 2026-09-30
- **Access date:** 2026-10-27
- **Exact inspected location:** Release tag and commit link
- **Claim supported:** Release identity for proposed CCCL qualification.
- **Limits:** Release evidence, no build or performance qualification.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api10"></a>

### API10 — CCCL License inventory

**Source:** [CCCL License inventory](https://github.com/NVIDIA/cccl/blob/main/LICENSE)

- **Organization / author:** NVIDIA and listed contributors
- **Version / revision:** Live main
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Top-level LICENSE component and third-party entries
- **Claim supported:** CUB, Thrust and libcu++ have distinct BSD/Apache/LLVM-exception terms and additional dependencies.
- **Limits:** Live license read; exact pinned per-file license inventory remains a local release gate.
- **License / reuse observation:** License evidence discussed; exact selected file/component notices require inventory. No third-party source redistributed in report.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api11"></a>

### API11 — CUB device_radix_sort.cuh

**Source:** [CUB device_radix_sort.cuh](https://github.com/NVIDIA/cccl/blob/main/cub/cub/device/device_radix_sort.cuh)

- **Organization / author:** NVIDIA
- **Version / revision:** Live main retrieved 2026-10-27
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** DeviceRadixSort stability/numeric notes; SortPairs; select_tuning_and_dispatch; temporary-storage query example
- **Claim supported:** Inspected actual live code for stable radix sorting, temporary storage, stream dispatch and input/output rules.
- **Limits:** Pinned 3.4.3 file fetch failed; no claim live file equals pin. No build or timing.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for inspected live source; exact pin equality unverified.

<a id="api12"></a>

### API12 — CUB device-wide primitives API

**Source:** [CUB device-wide primitives API](https://nvidia.github.io/cccl/unstable/cub/api/device.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Unstable/latest API documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Device-wide primitive list
- **Claim supported:** Documents DeviceScan, DeviceSelect, DeviceRadixSort and reductions as reusable primitives.
- **Limits:** Latest documentation, not exact 3.4.3 API conformance proof; compile chosen APIs locally.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api13"></a>

### API13 — CUDA Graphs

**Source:** [CUDA Graphs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/cuda-graphs.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current CUDA programming guide
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Graph construction, capture, execution and updates
- **Claim supported:** Graph representation and repeated launch facilities.
- **Limits:** API availability does not establish workload speedup or Max scheduling support.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api14"></a>

### API14 — Stream-Ordered Memory Allocation

**Source:** [Stream-Ordered Memory Allocation](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/stream-ordered-memory-allocation.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current CUDA programming guide
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Memory pools; allocation/free ordering; support checks
- **Claim supported:** Stream-ordered pools and explicit lifetime/reuse ordering.
- **Limits:** Does not remove peak memory accounting; no target-device pool probe.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api15"></a>

### API15 — Floating Point and IEEE 754 Compliance for NVIDIA GPUs

**Source:** [Floating Point and IEEE 754 Compliance for NVIDIA GPUs](https://docs.nvidia.com/cuda/floating-point/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Fused multiply-add, operation order, CPU/GPU comparisons
- **Claim supported:** Non-associativity and FMA rounding affect CPU/GPU comparisons.
- **Limits:** General numerical guidance; supplies no vegetation tolerances.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api16"></a>

### API16 — Unified Memory

**Source:** [Unified Memory](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/unified-memory.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current CUDA programming guide
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Windows/WSL/Tegra; concurrentManagedAccess and limited Unified Memory support
- **Claim supported:** Limited systems have restrictions including no oversubscription/demand paging and CPU access during GPU activity.
- **Limits:** Query actual device/system; do not universalize Linux full support to Windows Max.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api17"></a>

### API17 — CUDA Graphics Interoperability

**Source:** [CUDA Graphics Interoperability](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current guide section 4.21
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Direct graphics APIs; external memory; D3D sections and 12.9 reference
- **Claim supported:** Current graphics interoperability categories and explicit archived D3D11 detail reference.
- **Limits:** Standalone API documentation is not Max SDK ownership permission.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api18"></a>

### API18 — CUDA Runtime API Direct3D 11 Interoperability

**Source:** [CUDA Runtime API Direct3D 11 Interoperability](https://docs.nvidia.com/cuda/cuda-runtime-api/cuda_runtime_api/group__CUDART__D3D11.html)

- **Organization / author:** NVIDIA
- **Version / revision:** 13.4
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** cudaD3D11GetDevice/GetDevices; cudaGraphicsD3D11RegisterResource
- **Claim supported:** Device matching and resource registration constraints/lifetime; registration cost and supported resource limits.
- **Limits:** Must inspect resource descriptors and supported Max lifecycle; no interop test executed.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api19"></a>

### API19 — CUDA C Programming Guide 12.9 — Direct3D 11 external interoperability

**Source:** [CUDA C Programming Guide 12.9 — Direct3D 11 external interoperability](https://docs.nvidia.com/cuda/archive/12.9.0/cuda-c-programming-guide/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Archived 12.9.0
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Section 4.2.16.4: Direct3D 11 interoperability
- **Claim supported:** LUID matching, shared handles, external memory, dedicated flags, NT/KMT ownership and synchronization.
- **Limits:** Historical version explicitly referenced by current guide; not a Max 2027 integration contract.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api20"></a>

### API20 — cl_khr_d3d11_sharing

**Source:** [cl_khr_d3d11_sharing](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/cl_khr_d3d11_sharing.html)

- **Organization / author:** Khronos Group
- **Version / revision:** Ratified 1.0.0
- **Publication / update date:** 2020-04-21
- **Access date:** 2026-10-27
- **Exact inspected location:** Extension overview, context properties, create/acquire/release APIs
- **Claim supported:** OpenCL D3D11 resource/device sharing facilities.
- **Limits:** Extension support and Max resource eligibility remain unverified.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api21"></a>

### API21 — clEnqueueAcquireD3D11ObjectsKHR

**Source:** [clEnqueueAcquireD3D11ObjectsKHR](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clEnqueueAcquireD3D11ObjectsKHR.html)

- **Organization / author:** Khronos Group
- **Version / revision:** Current extension reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Acquisition ordering and CL_CONTEXT_INTEROP_USER_SYNC
- **Claim supported:** Default/user-managed synchronization obligations for D3D11 acquisition.
- **Limits:** No zero-copy, cross-adapter or host-lifecycle guarantee.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api22"></a>

### API22 — Compute Shader — Direct3D 11

**Source:** [Compute Shader — Direct3D 11](https://learn.microsoft.com/en-us/windows/win32/direct3d11/direct3d-11-advanced-stages-compute-shader)

- **Organization / author:** Microsoft
- **Version / revision:** D3D11 public documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Compute shader stage and capabilities
- **Claim supported:** Compute dispatch is a separate programmable graphics stage.
- **Limits:** Public D3D capability is not proof of access through Nitrous.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api23"></a>

### API23 — ID3D11DeviceContext::CSSetUnorderedAccessViews

**Source:** [ID3D11DeviceContext::CSSetUnorderedAccessViews](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/nf-d3d11-id3d11devicecontext-cssetunorderedaccessviews)

- **Organization / author:** Microsoft
- **Version / revision:** D3D11 / d3d11.h
- **Publication / update date:** 2021-10-13
- **Access date:** 2026-10-27
- **Exact inspected location:** Method syntax, UAV binding and requirements
- **Claim supported:** Exact compute UAV binding API.
- **Limits:** Does not prove Max buffers possess UAV creation flags or permitted context access.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api24"></a>

### API24 — Dynamic-Link Library Security

**Source:** [Dynamic-Link Library Security](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-security)

- **Organization / author:** Microsoft
- **Version / revision:** Current Win32 documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** DLL search-order attacks and recommended controls
- **Claim supported:** Restrict DLL search and use explicit safe loading paths.
- **Limits:** Proposed plugin loader architecture is not executed.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api25"></a>

### API25 — LoadLibraryExW

**Source:** [LoadLibraryExW](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadlibraryexw)

- **Organization / author:** Microsoft
- **Version / revision:** Win32 / libloaderapi.h
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** lpLibFileName, flags, search/dependency behavior
- **Claim supported:** Absolute-path and restricted-search loading semantics and failures.
- **Limits:** Top DLL path alone does not qualify all dependencies; no Windows run.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api26"></a>

### API26 — DllMain entry point

**Source:** [DllMain entry point](https://learn.microsoft.com/en-us/windows/win32/dlls/dllmain)

- **Organization / author:** Microsoft
- **Version / revision:** Win32 / Process.h
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Remarks on loader lock, constructors/destructors and library calls
- **Claim supported:** Loader-lock restrictions apply to entry-point and CRT static construction/destruction.
- **Limits:** Supports deferred initialization proposal; does not qualify arbitrary plugin shutdown.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api27"></a>

### API27 — Redistributing Visual C++ Files

**Source:** [Redistributing Visual C++ Files](https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files?view=msvc-170)

- **Organization / author:** Microsoft
- **Version / revision:** Current MSVC documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Redistribution rights and deployment methods
- **Claim supported:** Use permitted release redistributables and licensed redistribution paths.
- **Limits:** Exact installed CRT inventory and project license not inspected.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api28"></a>

### API28 — C++ binary compatibility between Visual Studio versions

**Source:** [C++ binary compatibility between Visual Studio versions](https://learn.microsoft.com/en-us/cpp/porting/binary-compat-2015-2017?view=msvc-170)

- **Organization / author:** Microsoft
- **Version / revision:** Current 2015–2026 compatibility guidance
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Restrictions: toolset/linker, runtime, /GL and /LTCG
- **Claim supported:** Compatible-family guidance still has linker, redistributable and whole-program optimization restrictions.
- **Limits:** Does not supersede Autodesk or CUDA exact compiler qualification.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api29"></a>

### API29 — CUDA Toolkit End User License Agreement

**Source:** [CUDA Toolkit End User License Agreement](https://docs.nvidia.com/cuda/eula/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** CUDA Toolkit EULA
- **Publication / update date:** 2026-01-26
- **Access date:** 2026-10-27
- **Exact inspected location:** Sections 1.1.1–1.1.2; Attachment A redistributable components
- **Claim supported:** Redistribution is component/condition specific; generic names permit applicable versioned filenames.
- **Limits:** No blanket legal clearance; actual binary names/dependencies unavailable here.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api30"></a>

### API30 — CUDA GPU Compute Capability

**Source:** [CUDA GPU Compute Capability](https://developer.nvidia.com/cuda/gpus)

- **Organization / author:** NVIDIA
- **Version / revision:** Live GPU table
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Current/legacy device tables
- **Claim supported:** Representative Turing/Ampere/Ada/Blackwell capability values.
- **Limits:** Capability is not workload performance; actual installed GPU unknown.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api31"></a>

### API31 — CUDA Compute Capabilities appendix

**Source:** [CUDA Compute Capabilities appendix](https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/compute-capabilities.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current programming guide
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Architecture capability/feature/limit tables
- **Claim supported:** Architecture feature limits differ and require exact device qualification.
- **Limits:** No application speed or memory-fit guarantee.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api32"></a>

### API32 — GeForce RTX 3060 and 3060 Ti specifications

**Source:** [GeForce RTX 3060 and 3060 Ti specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/30-series/rtx-3060-3060ti/)

- **Organization / author:** NVIDIA
- **Version / revision:** Live official specifications
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Full specifications: standard memory configurations
- **Claim supported:** 3060 Ti 8 GB; 3060 12 GB/8 GB variants.
- **Limits:** Exact installed board/availability unverified; no purchase recommendation.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api33"></a>

### API33 — GeForce RTX 4070 family specifications

**Source:** [GeForce RTX 4070 family specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/40-series/rtx-4070-family/)

- **Organization / author:** NVIDIA
- **Version / revision:** Live official specifications
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Full specifications: memory
- **Claim supported:** 4070 Ti SUPER 16 GB; listed 4070 Ti/SUPER/4070 12 GB.
- **Limits:** Nominal capacity is not memory available to Cyrus.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api34"></a>

### API34 — GeForce RTX 5090 specifications

**Source:** [GeForce RTX 5090 specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/)

- **Organization / author:** NVIDIA
- **Version / revision:** Live official specifications
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Memory specifications
- **Claim supported:** 32 GB GDDR7 nominal capacity.
- **Limits:** No measured workload throughput or purchasing advice.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api35"></a>

### API35 — RTX PRO 6000 Blackwell Workstation Edition

**Source:** [RTX PRO 6000 Blackwell Workstation Edition](https://www.nvidia.com/en-us/products/workstations/professional-desktop-gpus/rtx-pro-6000/)

- **Organization / author:** NVIDIA
- **Version / revision:** Live official specifications
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Memory and maximum power specifications
- **Claim supported:** 96 GB GDDR7 ECC and 600 W maximum power.
- **Limits:** Upper memory/power example; no claim it is necessary or sufficient.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api36"></a>

### API36 — Nsight Systems User Guide

**Source:** [Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current guide; Toolkit release lists 2026.3.2
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** CLI tracing, CUDA/NVTX and Windows requirements
- **Claim supported:** CPU/CUDA tracing and profiling setup.
- **Limits:** No OpenCL tracing equivalence assumed; no instrumented Max run.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api37"></a>

### API37 — Nsight Compute CLI

**Source:** [Nsight Compute CLI](https://docs.nvidia.com/nsight-compute/NsightComputeCli/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current guide; Toolkit release lists 2026.3.1
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Kernel metrics and replay modes
- **Claim supported:** Kernel profiling may replay work and change observed execution.
- **Limits:** Instrumented kernel measurement is not input-to-present latency.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api38"></a>

### API38 — Compute Sanitizer

**Source:** [Compute Sanitizer](https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** memcheck, racecheck, initcheck, synccheck
- **Claim supported:** Device memory/initialization/synchronization diagnostic tools.
- **Limits:** Does not establish geometry/collision correctness; not executed.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api39"></a>

### API39 — clGetEventProfilingInfo

**Source:** [clGetEventProfilingInfo](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clGetEventProfilingInfo.html)

- **Organization / author:** Khronos Group
- **Version / revision:** Current unified reference
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Profiling timestamps, event status, timer resolution
- **Claim supported:** Queue/submission/execution timestamps on profiling-enabled completed events.
- **Limits:** Not whole-frame/pointer latency and not directly interchangeable CPU clocks.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api40"></a>

### API40 — CUDA samples README and releases

**Source:** [CUDA samples README and releases](https://github.com/NVIDIA/cuda-samples)

- **Organization / author:** NVIDIA
- **Version / revision:** Live README; v13.4 lead
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Build prerequisites, sample organization and performance disclaimer
- **Claim supported:** CMake build organization and samples as examples, not a validation/performance suite.
- **Limits:** README inspected; pinned sample implementation fetches unavailable.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api41"></a>

### API41 — CUDA samples v13.4 commit

**Source:** [CUDA samples v13.4 commit](https://github.com/NVIDIA/cuda-samples/commit/5443602d89ed99aede2e4b7bf329daddeadb320e)

- **Organization / author:** NVIDIA
- **Version / revision:** v13.4 / 5443602d89ed99aede2e4b7bf329daddeadb320e
- **Publication / update date:** 2026-09-09
- **Access date:** 2026-10-27
- **Exact inspected location:** Release-to-commit page and file tree
- **Claim supported:** Exact proposed release commit identity.
- **Limits:** No local clone/build; some pinned blobs inaccessible.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for identified commit/diff; execution unverified.

<a id="api42"></a>

### API42 — CUDA samples LICENSE

**Source:** [CUDA samples LICENSE](https://github.com/NVIDIA/cuda-samples/blob/master/LICENSE)

- **Organization / author:** NVIDIA
- **Version / revision:** Live master
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** LICENSE
- **Claim supported:** BSD 3-Clause text with CUDA license reference.
- **Limits:** Exact pinned license file requires local comparison.
- **License / reuse observation:** License evidence discussed; exact selected file/component notices require inventory. No third-party source redistributed in report.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api43"></a>

### API43 — CUDA Domain-Specific samples README

**Source:** [CUDA Domain-Specific samples README](https://github.com/NVIDIA/cuda-samples/blob/master/cpp/5_Domain_Specific/README.md)

- **Organization / author:** NVIDIA
- **Version / revision:** Live master
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** simpleD3D11, simpleD3D11Texture, simpleD3D12 entries
- **Claim supported:** Documented sample directories and interop demonstration purpose.
- **Limits:** Sample descriptions only; full pinned implementation unavailable.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api44"></a>

### API44 — OpenCL SDK releases

**Source:** [OpenCL SDK releases](https://github.com/KhronosGroup/OpenCL-SDK/releases)

- **Organization / author:** Khronos Group
- **Version / revision:** v2026.05.29
- **Publication / update date:** 2026-06-01
- **Access date:** 2026-10-27
- **Exact inspected location:** Release tag and synchronization note
- **Claim supported:** SDK release synchronizes with OpenCL 3.1.1.
- **Limits:** Not a vendor GPU implementation or current spec 3.1.2 implementation claim.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api45"></a>

### API45 — OpenCL SDK release commit

**Source:** [OpenCL SDK release commit](https://github.com/KhronosGroup/OpenCL-SDK/commit/e26922bdf54eaa9fcc31fe1f91d21b8d2bd6970f)

- **Organization / author:** Khronos Group
- **Version / revision:** e26922bdf54eaa9fcc31fe1f91d21b8d2bd6970f
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Release-to-commit page
- **Claim supported:** Exact proposed SDK commit identity.
- **Limits:** Pinned sample bodies unavailable; no build.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for identified commit/diff; execution unverified.

<a id="api46"></a>

### API46 — OpenCL SDK README

**Source:** [OpenCL SDK README](https://github.com/KhronosGroup/OpenCL-SDK)

- **Organization / author:** Khronos Group
- **Version / revision:** Live repository README
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Build organization, components and license metadata
- **Claim supported:** Official SDK organization and Apache-2.0 metadata.
- **Limits:** Dependency/per-file notices require exact checkout inspection.
- **License / reuse observation:** License evidence discussed; exact selected file/component notices require inventory. No third-party source redistributed in report.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api47"></a>

### API47 — OpenCL ICD Loader README

**Source:** [OpenCL ICD Loader README](https://github.com/KhronosGroup/OpenCL-ICD-Loader)

- **Organization / author:** Khronos Group
- **Version / revision:** Live README
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Introduction, Windows registration, build/tests and license metadata
- **Claim supported:** Loader enumerates/forwards to ICDs and contains no OpenCL implementation; Apache-2.0 repository.
- **Limits:** Private loader packaging proposal does not confer vendor-driver redistribution rights.
- **License / reuse observation:** License evidence discussed; exact selected file/component notices require inventory. No third-party source redistributed in report.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api48"></a>

### API48 — Prevent Windows library unloading at process termination

**Source:** [Prevent Windows library unloading at process termination](https://github.com/KhronosGroup/OpenCL-ICD-Loader/commit/b7bd2803acc779c03d96588e9ca9e9568a18698a)

- **Organization / author:** Khronos Group
- **Version / revision:** b7bd2803acc779c03d96588e9ca9e9568a18698a
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Exact diff: loader/icd.c, loader/icd.h, loader/windows/icd_windows.c and related callers
- **Claim supported:** Inspected unloadLibraries parameter and Windows DllMain termination distinction.
- **Limits:** Actual diff inspection, no whole-loader build/test or Cyrus lifecycle proof.
- **License / reuse observation:** License evidence discussed; exact selected file/component notices require inventory. No third-party source redistributed in report.
- **Evidence confidence:** High for identified commit/diff; execution unverified.

<a id="api49"></a>

### API49 — OpenCL ICD Loader releases

**Source:** [OpenCL ICD Loader releases](https://github.com/KhronosGroup/OpenCL-ICD-Loader/releases)

- **Organization / author:** Khronos Group
- **Version / revision:** v2026.05.29
- **Publication / update date:** 2026-05-29
- **Access date:** 2026-10-27
- **Exact inspected location:** Latest release entry and commit link
- **Claim supported:** Release synchronizes with specification 3.1.1 and identifies b7bd280.
- **Limits:** Does not install an ICD or establish driver features.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for stated public documentation; runtime/host execution unverified.

<a id="api50"></a>

### API50 — CCCL v3.4.3 commit

**Source:** [CCCL v3.4.3 commit](https://github.com/NVIDIA/cccl/commit/5fb1013e3c6f72877a2ebd30f54fe5158d64eec4)

- **Organization / author:** NVIDIA
- **Version / revision:** 5fb1013e3c6f72877a2ebd30f54fe5158d64eec4
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Release-to-commit page
- **Claim supported:** Exact proposed CCCL release commit identity.
- **Limits:** Pinned implementation blobs inaccessible; live source inspection separately identified.
- **License / reuse observation:** Documentation/source consulted only; no third-party code redistributed.
- **Evidence confidence:** High for identified commit/diff; execution unverified.


## Collision, constraints and reusable implementations

<a id="col01"></a>

### COL01 — Position Based Dynamics

**Source:** [Position Based Dynamics](https://matthias-research.github.io/pages/publications/posBasedDyn.pdf)

- **Organization / author:** Müller, Heidelberger, Hennix, Ratcliff
- **Version / revision:** VRIPHYS 2006 author paper; journal version followed in 2007
- **Publication / update date:** 2006
- **Access date:** 2026-10-27
- **Exact inspected location:** Solver algorithm and constraint projection sections
- **Claim supported:** Direct positional projection and fixed-particle treatment.
- **Limits:** Finite projection passes do not prove complete nonlinear feasibility.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col02"></a>

### COL02 — XPBD: Position-Based Simulation of Compliant Constrained Dynamics

**Source:** [XPBD: Position-Based Simulation of Compliant Constrained Dynamics](https://mmacklin.com/xpbd.pdf)

- **Organization / author:** Macklin, Müller, Chentanez
- **Version / revision:** MIG 2016; DOI 10.1145/2994258.2994272
- **Publication / update date:** 2016-10-10
- **Access date:** 2026-10-27
- **Exact inspected location:** Section 4; Eq. 18
- **Claim supported:** Compliance and accumulated multipliers have an elastic-energy derivation.
- **Limits:** Dynamic time-step formulation; finite solver iteration count still matters. Not a static plant implementation.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col03"></a>

### COL03 — Discrete Elastic Rods

**Source:** [Discrete Elastic Rods](https://www.cs.columbia.edu/cg/rods/index.html)

- **Organization / author:** Bergou, Wardetzky, Robinson, Audoly, Grinspun
- **Version / revision:** ACM TOG 27(3), 63:1–12
- **Publication / update date:** 2008-08
- **Access date:** 2026-10-27
- **Exact inspected location:** Author project, framed-curve, parallel-transport and constraint description
- **Claim supported:** Dynamic centerline, quasistatic material frame, twist and inextensibility model.
- **Limits:** Not a complete GPU branched-plant contact and binding package.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col04"></a>

### COL04 — Position and Orientation Based Cosserat Rods

**Source:** [Position and Orientation Based Cosserat Rods](https://animation.rwth-aachen.de/media/papers/2016-SCA-Cosserat-Rods.pdf)

- **Organization / author:** Kugelstadt, Schömer
- **Version / revision:** SCA 2016; DOI 10.2312/sca.20161234
- **Publication / update date:** 2016
- **Access date:** 2026-10-27
- **Exact inspected location:** Section 6, stretch/shear Eq. 37 and bend/twist Eq. 40
- **Claim supported:** Position and quaternion constraints implement rod stretch, shear, bend and twist.
- **Limits:** Published relative speed or convergence claims are not transferred to Cyrus.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col05"></a>

### COL05 — Direct Position-Based Solver for Stiff Rods

**Source:** [Direct Position-Based Solver for Stiff Rods](https://www.animation.rwth-aachen.de/media/papers/2018-CGF-Rods.pdf)

- **Organization / author:** Deul, Kugelstadt, Weiler, Bender
- **Version / revision:** CGF 37(6), 313–324; DOI 10.1111/cgf.13326
- **Publication / update date:** 2018
- **Access date:** 2026-10-27
- **Exact inspected location:** Newton formulation and direct acyclic-tree solve
- **Claim supported:** Coupled structural solve for stiff Cosserat rods.
- **Limits:** Structural tree solution does not complete arbitrary active contacts or host integration.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col06"></a>

### COL06 — Projective Dynamics: Fusing Constraint Projections for Fast Simulation

**Source:** [Projective Dynamics: Fusing Constraint Projections for Fast Simulation](https://www.projectivedynamics.org/)

- **Organization / author:** Bouaziz, Martin, Liu, Kavan, Pauly
- **Version / revision:** TOG 33(4), 154; DOI 10.1145/2601097.2601116
- **Publication / update date:** 2014
- **Access date:** 2026-10-27
- **Exact inspected location:** Author project and paper local/global optimization formulation
- **Claim supported:** Local projection and global structural solve.
- **Limits:** Direct PDF open failed; author page and retrieved PDF search text support this bounded summary. Factorization reuse depends on fixed system structure.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col07"></a>

### COL07 — Local Optimization for Robust Signed Distance Field Collision

**Source:** [Local Optimization for Robust Signed Distance Field Collision](https://mmacklin.com/sdfcontact.pdf)

- **Organization / author:** Macklin, Erleben, Müller, Chentanez, Jeschke, Corse
- **Version / revision:** Proc. ACM Computer Graphics and Interactive Techniques 3(1), article 8; DOI 10.1145/3384538
- **Publication / update date:** 2020
- **Access date:** 2026-10-27
- **Exact inspected location:** Continuous edge/face element optimization; projected-gradient, Frank–Wolfe and line-search discussion
- **Claim supported:** Local element searches address misses inherent to vertex-only field contact.
- **Limits:** Full PDF direct-open exceeded retrieval limit; primary indexed text and coauthor publication metadata consulted. Local search is not a global distance certificate.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col08"></a>

### COL08 — Maximizing Parallelism in Construction of BVHs, Octrees, and k-d Trees

**Source:** [Maximizing Parallelism in Construction of BVHs, Octrees, and k-d Trees](https://research.nvidia.com/publication/2012-06_maximizing-parallelism-construction-bvhs-octrees-and-k-d-trees)

- **Organization / author:** Tero Karras / NVIDIA Research
- **Version / revision:** HPG 2012; DOI 10.2312/EGGH/HPG12/033-037
- **Publication / update date:** 2012-06
- **Access date:** 2026-10-27
- **Exact inspected location:** Paper sections 4–5: binary radix tree, bounds and evaluation
- **Claim supported:** Morton/radix parallel tree construction; duplicate keys can include primitive indices.
- **Limits:** Historical CUDA 4.0/GTX 480/Core i7/Windows 7 evaluation; no modern performance inference.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col09"></a>

### COL09 — Unified Particle Physics for Real-Time Applications

**Source:** [Unified Particle Physics for Real-Time Applications](https://mmacklin.com/uppfrta_preprint.pdf)

- **Organization / author:** Macklin, Müller, Chentanez, Kim
- **Version / revision:** TOG 33(4), 153; DOI 10.1145/2601097.2601152
- **Publication / update date:** 2014-07-27
- **Access date:** 2026-10-27
- **Exact inspected location:** Section 4: parallel SOR and constraint averaging
- **Claim supported:** GPU-friendly parallel decomposition and averaged constraint corrections.
- **Limits:** Particle/radius assumptions differ from full-width plant surfaces; throughput not transferred.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col10"></a>

### COL10 — Fast Simulation of Inextensible Hair and Fur

**Source:** [Fast Simulation of Inextensible Hair and Fur](https://matthias-research.github.io/pages/publications/FTLHairFur.pdf)

- **Organization / author:** Müller, Kim, Chentanez
- **Version / revision:** VRIPHYS 2012, 39–44; DOI 10.2312/PE/vriphys/vriphys12/039-044
- **Publication / update date:** 2012
- **Access date:** 2026-10-27
- **Exact inspected location:** Follow-the-leader chain construction
- **Claim supported:** Efficient rooted-chain length restoration.
- **Limits:** Inextensibility result is not simultaneous multi-obstacle contact or broad-leaf clearance.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col11"></a>

### COL11 — Small Steps in Physics Simulation

**Source:** [Small Steps in Physics Simulation](https://mmacklin.com/smallsteps.pdf)

- **Organization / author:** Macklin et al.
- **Version / revision:** SCA 2019; DOI 10.1145/3309486.3340247
- **Publication / update date:** 2019-07
- **Access date:** 2026-10-27
- **Exact inspected location:** Comparison of dynamic substeps with iterations in one large step
- **Claim supported:** Dynamic substepping can change solver accuracy and damping.
- **Limits:** A fresh-rest static fit has no physical frame step to subdivide; paper timings not adopted.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col12"></a>

### COL12 — Incremental Potential Contact

**Source:** [Incremental Potential Contact](https://ipc-sim.github.io/)

- **Organization / author:** Li, Ferguson, Schneider, Langlois, Zorin, Panozzo, Jiang, Kaufman
- **Version / revision:** SIGGRAPH 2020 / TOG 39(4), 49
- **Publication / update date:** 2020
- **Access date:** 2026-10-27
- **Exact inspected location:** Author project: barrier/contact and collision-safe methodology
- **Claim supported:** Reference for intersection/inversion-safe contact under the stated algorithm assumptions.
- **Limits:** Not a drop-in bounded static fitter starting from arbitrary penetrations; complete CCD and initial-state assumptions matter.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col13"></a>

### COL13 — Computation of Rotation Minimizing Frames

**Source:** [Computation of Rotation Minimizing Frames](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/12/Computation-of-rotation-minimizing-frames.pdf)

- **Organization / author:** Wang, Jüttler, Zheng, Liu
- **Version / revision:** TOG 27(1), article 2; DOI 10.1145/1330511.1330513
- **Publication / update date:** 2008-03
- **Access date:** 2026-10-27
- **Exact inspected location:** Double-reflection frame transport and zero-curvature discussion
- **Claim supported:** Rotation-minimizing transport avoids reliance on Frenet curvature.
- **Limits:** Authored twist and full-turn information require separate data; hosting URL year is not publication year.
- **License / reuse observation:** Paper consulted; no paper or associated code redistributed. Publication access does not establish a reusable code license.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col14"></a>

### COL14 — GPU-Generated Procedural Wind Animations for Trees

**Source:** [GPU-Generated Procedural Wind Animations for Trees](https://developer.nvidia.com/gpugems/gpugems3/part-i-geometry/chapter-6-gpu-generated-procedural-wind-animations-trees)

- **Organization / author:** Renaldas Zioma / NVIDIA GPU Gems 3
- **Version / revision:** GPU Gems 3, chapter 6
- **Publication / update date:** 2007
- **Access date:** 2026-10-27
- **Exact inspected location:** Sections 6.2–6.3: hierarchy and vertex shader animation
- **Claim supported:** Procedural wind deformation and instance/hierarchy economy.
- **Limits:** Phenomenological animation, not obstacle contact solving. Associated media/code license not audited.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col15"></a>

### COL15 — NVIDIA Warp releases

**Source:** [NVIDIA Warp releases](https://github.com/NVIDIA/warp/releases)

- **Organization / author:** NVIDIA
- **Version / revision:** v1.18.0 current release; v1.17.0 query introduction
- **Publication / update date:** 2026-10-05
- **Access date:** 2026-10-27
- **Exact inspected location:** v1.18.0 and v1.17.0 release notes
- **Claim supported:** Version chronology, default wheel requirements and introduction of spatial query APIs.
- **Limits:** Runtime availability and documentation do not establish Max compatibility or execution performance. Repository source bodies separately qualified.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col16"></a>

### COL16 — Warp 1.18.0 release commit

**Source:** [Warp 1.18.0 release commit](https://github.com/NVIDIA/warp/commit/f2eaed82d8d03b37bf1014cc975954067fefcf16)

- **Organization / author:** NVIDIA
- **Version / revision:** v1.18.0; v1.17.0 secondary pin in related URL
- **Publication / update date:** 2026-10-05
- **Access date:** 2026-10-27
- **Exact inspected location:** Version/config diff setting 1.18.0
- **Claim supported:** Full release SHA verified.
- **Limits:** Exact native mesh/BVH file bodies at this SHA were not retrieved; do not equate rolling source with pin.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col17"></a>

### COL17 — warp.bvh_query_capsule

**Source:** [warp.bvh_query_capsule](https://nvidia.github.io/warp/stable/language_reference/_generated/warp.bvh_query_capsule.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Warp 1.18.0 page on final refresh; an earlier cached retrieval labeled 1.17.0
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Generated API description: inflated AABB, unnormalized dir, bvh_query_next(max_dist=1.0), zero-length exclusion
- **Claim supported:** Capsule-BVH traversal is conservative broadphase rather than capsule–triangle narrow phase.
- **Limits:** Callers require proper candidate iteration and exact/custom element tests; stable URL is mutable.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col18"></a>

### COL18 — warp.mesh_query_point_sign_winding_number

**Source:** [warp.mesh_query_point_sign_winding_number](https://nvidia.github.io/warp/v1.17/language_reference/_generated/warp.mesh_query_point_sign_winding_number.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Version-qualified 1.17 documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** support_winding_number, maximum distance, fallback and return-value notes
- **Claim supported:** Winding support must be enabled; otherwise ray-majority fallback. Closest-point limit differs from whole-mesh sign calculation.
- **Limits:** Do not infer intended solid for arbitrary open meshes; check result validity. 1.18 exact page not retrieved.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col19"></a>

### COL19 — Warp README and license/dependency declarations

**Source:** [Warp README and license/dependency declarations](https://github.com/NVIDIA/warp/blob/main/README.md)

- **Organization / author:** NVIDIA
- **Version / revision:** Rolling main observed with 1.18 environment guidance
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Installing; CUDA requirements; license and third-party software
- **Claim supported:** Apache 2.0 project; Python authoring and selected CUDA/device requirements; separate libmathdx terms.
- **Limits:** Rolling body not pinned. Generated/native runtime dependencies require selected-file audit; Python need not ship with documented AOT output.
- **License / reuse observation:** Apache-2.0 declared for Warp; libmathdx and other dependencies separately licensed. No third-party code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col20"></a>

### COL20 — TressFX v4.1.0 release

**Source:** [TressFX v4.1.0 release](https://github.com/GPUOpen-Effects/TressFX/releases/tag/v4.1.0)

- **Organization / author:** AMD GPUOpen
- **Version / revision:** Standalone v4.1.0
- **Publication / update date:** 2020-01-24
- **Access date:** 2026-10-27
- **Exact inspected location:** Release features and prerequisites
- **Claim supported:** DX12/Vulkan standalone sample; SM6 prerequisite and historical VS/CMake/Vulkan build requirements.
- **Limits:** Release page gives Jan 24 without year in retrieved body; year contextualized by AMD Jan 27, 2020 announcement COL41. Not the latest Unreal-patch product.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col21"></a>

### COL21 — TressFX v4.1.0 source commit

**Source:** [TressFX v4.1.0 source commit](https://github.com/GPUOpen-Effects/TressFX/commit/ba0bdacdfb964e38522fda812bf23169bc5fa603)

- **Organization / author:** AMD GPUOpen
- **Version / revision:** v4.1.0 release commit
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Release tree, shader paths, Cauldron submodule and CMake entries
- **Claim supported:** Full release SHA and relevant paths verified.
- **Limits:** Readable current shader body was not established byte-identical to this commit.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col22"></a>

### COL22 — TressFXSimulation.hlsl

**Source:** [TressFXSimulation.hlsl](https://github.com/GPUOpen-Effects/TressFX/blob/master/src/Shaders/TressFXSimulation.hlsl)

- **Organization / author:** AMD GPUOpen
- **Version / revision:** Rolling master source body; 1,143 lines in retrieved view
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** LocalShapeConstraints; LengthConstriantsWindAndCollision; ResolveCapsuleCollisions; UpdateFollowHairVertices
- **Claim supported:** Inspectable strand/vertex scheduling and guide-follow deformation.
- **Limits:** Vertex collision call does not certify complete spans or derived broad leaves. Rolling-source hash unresolved.
- **License / reuse observation:** Permissive MIT-style copyright notice in shader; retain notices for any copied code.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col23"></a>

### COL23 — TressFX 4.x Developer Guide

**Source:** [TressFX 4.x Developer Guide](https://raw.githubusercontent.com/GPUOpen-Effects/TressFX/master/doc/TressFX4xDeveloperGuide.pdf)

- **Organization / author:** AMD GPUOpen
- **Version / revision:** 4.x guide in current public standalone repository
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Simulation dispatch and SDF collision generation sections
- **Claim supported:** Documents simulation stages and SDF collision resource workflow.
- **Limits:** Retrieved primary indexed PDF content; SDF shader body was unavailable. No undocumented GPU collision guarantee asserted.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col24"></a>

### COL24 — AMD TressFX current product page

**Source:** [AMD TressFX current product page](https://gpuopen.com/tressfx/)

- **Organization / author:** AMD GPUOpen
- **Version / revision:** Standalone 4.1 and linked TressFX 5.0 Unreal products
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Standalone download, MIT statement, related TressFX 5.0 links
- **Claim supported:** Standalone and Unreal patch lines have different versions and access requirements.
- **Limits:** Page contains an inconsistent historical 4.1 date label; use COL20/COL41 for January 2020 release context. Unreal patch source not accessed.
- **License / reuse observation:** Standalone MIT declared; Unreal patch access/EULA and dependency terms require separate review.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col25"></a>

### COL25 — TressFX src/CMakeLists.txt

**Source:** [TressFX src/CMakeLists.txt](https://github.com/GPUOpen-Effects/TressFX/blob/master/src/CMakeLists.txt)

- **Organization / author:** AMD GPUOpen
- **Version / revision:** Rolling master
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** GFX_API selection and sample libraries
- **Claim supported:** Cauldron and selected DX12/DXC/d3dcompiler/AGS/ImGUI/Vulkan sample dependencies.
- **Limits:** Build declarations inspected; no build performed and no complete dependency license audit.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col26"></a>

### COL26 — Jolt Physics 5.6.0 release notes

**Source:** [Jolt Physics 5.6.0 release notes](https://github.com/jrouwe/JoltPhysics/releases)

- **Organization / author:** Jorrit Rouwe and contributors
- **Version / revision:** Public 5.6.0
- **Publication / update date:** 2026-07-11
- **Access date:** 2026-10-27
- **Exact inspected location:** 5.6.0: GPU compute and experimental hair bullets
- **Claim supported:** Experimental GPU Cosserat hair, guide/follow data and hull/compound environment contact.
- **Limits:** Release capability evidence only. Not the private Physics Lab pin and not inspected hair implementation.
- **License / reuse observation:** Project license checked separately in COL40.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col27"></a>

### COL27 — Jolt Physics 5.6.0 version commit

**Source:** [Jolt Physics 5.6.0 version commit](https://github.com/jrouwe/JoltPhysics/commit/e77f175595e64cb44218cc9d9d56fc365ad0e36a)

- **Organization / author:** Jorrit Rouwe and contributors
- **Version / revision:** Public 5.6.0
- **Publication / update date:** 2026-07-11
- **Access date:** 2026-10-27
- **Exact inspected location:** Version-update diff
- **Claim supported:** Full public release SHA verified.
- **Limits:** Exact Hair source body not retrieved; no conclusion about a private dependency checkout.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col28"></a>

### COL28 — PhysX GPU Simulation

**Source:** [PhysX GPU Simulation](https://nvidia-omniverse.github.io/PhysX/physx/5.6.1/docs/GPURigidBodies.html)

- **Organization / author:** NVIDIA
- **Version / revision:** PhysX 5.6.1 documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** GPU dynamics/broadphase flags, CUDA context manager and Direct GPU API
- **Claim supported:** GPU broadphase and dynamics activation are distinct; APIs partition supported simulation features.
- **Limits:** Version-local requirements do not establish current CUDA device compatibility or prepared vegetation semantics. Full selected binary/source license audit not conducted.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col29"></a>

### COL29 — PositionBasedDynamics repository README

**Source:** [PositionBasedDynamics repository README](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics)

- **Organization / author:** Interactive Computer Graphics / contributors
- **Version / revision:** Rolling master; exact commit unresolved
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Features, constraints, dependencies and tested configurations
- **Claim supported:** Rod/XPBD constraints and graph-coloring CPU reference; dependencies enumerated.
- **Limits:** Listed historical tested compilers do not qualify Max 2027 or CUDA. No code execution.
- **License / reuse observation:** MIT verified separately COL39; dependency terms separate.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col30"></a>

### COL30 — PositionBasedElasticRods.h

**Source:** [PositionBasedElasticRods.h](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics/blob/master/PositionBasedDynamics/PositionBasedElasticRods.h)

- **Organization / author:** Interactive Computer Graphics / contributors
- **Version / revision:** Rolling master; 601 lines in retrieved body
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** PositionBasedCosseratRods::solve_StretchShearConstraint; solve_BendTwistConstraint; stiff rod tree declarations
- **Claim supported:** Declarations expose position/quaternion weights, rest length and rest Darboux information.
- **Limits:** Corresponding cpp body and immutable source pin not retrieved. Eigen and host containers imply real GPU-port work.
- **License / reuse observation:** Repository MIT, retain relevant notices; dependencies separately audited.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col31"></a>

### COL31 — OpenVDB releases

**Source:** [OpenVDB releases](https://github.com/AcademySoftwareFoundation/openvdb/releases)

- **Organization / author:** Academy Software Foundation
- **Version / revision:** Retrieved latest index 13.1.0
- **Publication / update date:** 2026-09-16
- **Access date:** 2026-10-27
- **Exact inspected location:** 13.1.0 release notes and NanoVDB tools
- **Claim supported:** Tools can create new grid topology; core immutable-grid shorthand is not a limit on all tools.
- **Limits:** Release index is behind official 13.2.0 notes retrieved at COL38; do not conclude 13.2 absent.
- **License / reuse observation:** Current project license separately COL34.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col32"></a>

### COL32 — OpenVDB 13.1.0 release commit

**Source:** [OpenVDB 13.1.0 release commit](https://github.com/AcademySoftwareFoundation/openvdb/commit/e26f5a569201d3236e0c30580572101022d3d754)

- **Organization / author:** Academy Software Foundation
- **Version / revision:** 13.1.0
- **Publication / update date:** 2026-09-16
- **Access date:** 2026-10-27
- **Exact inspected location:** CMake version and release-note diff
- **Claim supported:** Full 13.1.0 SHA verified.
- **Limits:** Not a 13.2.0 pin; 13.2 exact commit remains unresolved.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col33"></a>

### COL33 — NanoVDB.h generated source documentation

**Source:** [NanoVDB.h generated source documentation](https://www.openvdb.org/documentation/doxygen/NanoVDB_8h_source.html)

- **Organization / author:** Academy Software Foundation
- **Version / revision:** Generated docs identify 13.2.0
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** NanoVDB.h opening description, buffer alignment and ReadAccessor requirements
- **Claim supported:** Linearized grid, 32-byte alignment and per-thread accessor/cache lifetime requirements.
- **Limits:** Container layout does not establish field numerical/sign error bounds. Generated version known; matching immutable commit unresolved.
- **License / reuse observation:** SPDX Apache-2.0 in inspected header.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col34"></a>

### COL34 — OpenVDB LICENSE

**Source:** [OpenVDB LICENSE](https://github.com/AcademySoftwareFoundation/openvdb/blob/master/LICENSE)

- **Organization / author:** Academy Software Foundation
- **Version / revision:** Rolling master license
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Root LICENSE Apache 2.0 text
- **Claim supported:** Current project root license states Apache 2.0.
- **Limits:** Exact selected revision and dependency notices still need audit; do not apply historical license assumptions.
- **License / reuse observation:** Apache-2.0.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col35"></a>

### COL35 — NVIDIA cuBQL

**Source:** [NVIDIA cuBQL](https://github.com/NVIDIA/cuBQL)

- **Organization / author:** NVIDIA
- **Version / revision:** Rolling main; exact commit unresolved
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** README overview, build/query API and licensing
- **Claim supported:** Header-oriented CUDA/C++ BVH build and traversal evaluation candidate.
- **Limits:** README inspected; implementation bodies, stack limits, traversal overflow semantics and exact commit not resolved.
- **License / reuse observation:** Apache-2.0 declared; 3rdParty.txt still requires selected-dependency audit.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col36"></a>

### COL36 — Discregrid

**Source:** [Discregrid](https://github.com/InteractiveComputerGraphics/Discregrid)

- **Organization / author:** Interactive Computer Graphics / contributors
- **Version / revision:** Rolling repository; exact commit unresolved
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** README CubicLagrangeDiscreteGrid construction, interpolation and field reduction
- **Claim supported:** CPU cubic-grid field representation and optional gradient access.
- **Limits:** Cubic interpolation does not inherit convex trilinear error bound. Full implementation/pin not inspected.
- **License / reuse observation:** MIT declared; Eigen/OpenMP/TriangleMeshDistance dependency terms separately audited before reuse.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col37"></a>

### COL37 — Warp C++ and CUDA workflows

**Source:** [Warp C++ and CUDA workflows](https://nvidia.github.io/warp/stable/user_guide/programming_model/cpp_cuda_workflows.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Warp documentation 1.18.0
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** warp/examples/cpp/00_cubin_launch; 01_source_include; native/aot.h; external compilation notes
- **Claim supported:** Documented AOT output can run through native C++/CUDA routes.
- **Limits:** Examples were not compiled. External compilation is experimental; matching version headers/runtime/modules required; no Max delivery proof.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col38"></a>

### COL38 — OpenVDB release notes: 13.2.0

**Source:** [OpenVDB release notes: 13.2.0](https://www.openvdb.org/documentation/doxygen/changes.html)

- **Organization / author:** Academy Software Foundation
- **Version / revision:** 13.2.0
- **Publication / update date:** 2026-10-26
- **Access date:** 2026-10-27
- **Exact inspected location:** Version 13.2.0 NanoVDB API and bug-fix sections
- **Claim supported:** Current dated notes establish 13.2.0 and relevant NanoVDB maintenance changes.
- **Limits:** Exact release commit not retrieved. GitHub release index discrepancy recorded rather than silently resolved.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col39"></a>

### COL39 — PositionBasedDynamics LICENSE

**Source:** [PositionBasedDynamics LICENSE](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics/blob/master/LICENSE)

- **Organization / author:** PositionBasedDynamics contributors
- **Version / revision:** Rolling master license; copyright 2015–present
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** MIT grant, notice preservation and disclaimer
- **Claim supported:** Project declares MIT terms.
- **Limits:** Dependency licenses and a specific frozen checkout require separate audit.
- **License / reuse observation:** MIT.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col40"></a>

### COL40 — JoltPhysics LICENSE

**Source:** [JoltPhysics LICENSE](https://github.com/jrouwe/JoltPhysics/blob/master/LICENSE)

- **Organization / author:** Jorrit Rouwe
- **Version / revision:** Rolling master license; copyright 2021
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Root LICENSE permission, notice and disclaimer text
- **Claim supported:** Public project uses MIT-style permission and notice terms.
- **Limits:** Exact chosen files and dependencies still require frozen-source license review.
- **License / reuse observation:** MIT.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.

<a id="col41"></a>

### COL41 — TressFX 4.1, Engine Integration with Unreal 4.22 and Radeon Cauldron

**Source:** [TressFX 4.1, Engine Integration with Unreal 4.22 and Radeon Cauldron](https://gpuopen.com/news/tressfx-4-1-engine-integration-unreal-4-22-radeon-cauldron/)

- **Organization / author:** AMD GPUOpen
- **Version / revision:** TressFX 4.1 release announcement
- **Publication / update date:** 2020-01-27
- **Access date:** 2026-10-27
- **Exact inspected location:** Originally posted date, framework integration and prerequisites
- **Claim supported:** Dated primary announcement establishes 2020 release context and separate Unreal patch access.
- **Limits:** Article prerequisites differ from standalone release SM6 list; use exact artifact requirements rather than generalizing one list.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary source inspected; no implementation or performance execution.


## Windows, profiling and measurement

<a id="sys01"></a>

### SYS01 — WDDM timeout detection and recovery

**Source:** [WDDM timeout detection and recovery](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/timeout-detection-and-recovery)

- **Organization / author:** Microsoft
- **Version / revision:** Living Windows driver documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Timeout detection in WDDM; preparation/recovery
- **Claim supported:** Default preemption timeout is two seconds; recovery can reset GPU state.
- **Limits:** Not a safe interactive dispatch target and not a Max recovery implementation.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys02"></a>

### SYS02 — Testing and debugging TDR

**Source:** [Testing and debugging TDR](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/tdr-registry-keys)

- **Organization / author:** Microsoft
- **Version / revision:** Living Windows driver documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** TDR registry keys for testing and debugging
- **Claim supported:** Applications/end users should not manipulate TDR keys outside targeted driver testing.
- **Limits:** No registry change proposed or performed.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys03"></a>

### SYS03 — IDXGIAdapter3::QueryVideoMemoryInfo

**Source:** [IDXGIAdapter3::QueryVideoMemoryInfo](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_4/nf-dxgi1_4-idxgiadapter3-queryvideomemoryinfo)

- **Organization / author:** Microsoft
- **Version / revision:** dxgi1_4.h
- **Publication / update date:** 2024-02-22
- **Access date:** 2026-10-27
- **Exact inspected location:** Signature, Remarks, Requirements
- **Claim supported:** Queries process budget/usage; exceeding assigned budget can cause paging/stutter.
- **Limits:** Requires a qualified adapter path; does not prove Max resource interoperability.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys04"></a>

### SYS04 — Nsight Systems release notes

**Source:** [Nsight Systems release notes](https://docs.nvidia.com/nsight-systems/ReleaseNotes/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** 2026.5.1
- **Publication / update date:** 2026-09-09
- **Access date:** 2026-10-27
- **Exact inspected location:** 2026.5.1 highlights and last-updated footer
- **Claim supported:** Current retrieved tool version; CUDA13.4 support and tracing updates.
- **Limits:** Not installed or executed; target GPU/driver privileges/features need qualification.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys05"></a>

### SYS05 — Nsight Systems user guide

**Source:** [Nsight Systems user guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Live guide alongside2026.5.1
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Marking/labeling regions, command options, CUDA trace, WDDM and memory tracing
- **Claim supported:** NVTX/CUDA correlation and Windows WDDM events support stage and residency investigation.
- **Limits:** Profiler overhead and feature availability matter; CUDA event timings are not complete drag latency.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys06"></a>

### SYS06 — Nsight Compute release notes

**Source:** [Nsight Compute release notes](https://docs.nvidia.com/nsight-compute/ReleaseNotes/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** 2026.3.1
- **Publication / update date:** 2026-08-27
- **Access date:** 2026-10-27
- **Exact inspected location:** Updates2026.3.1/2026.3 and footer
- **Claim supported:** Current retrieved release and CUDA13.4 support in2026.3.
- **Limits:** No profiler installed/run.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys07"></a>

### SYS07 — Nsight Compute profiling guide

**Source:** [Nsight Compute profiling guide](https://docs.nvidia.com/nsight-compute/ProfilingGuide/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** Current2026.3-series guide
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Metric collection, replay modes and overhead
- **Claim supported:** Metric sets/replay alter measured execution; separate focused profiling from uninstrumented latency runs.
- **Limits:** No specific Cyrus kernel profiled.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys08"></a>

### SYS08 — PresentMon release and commit

**Source:** [PresentMon release and commit](https://github.com/GameTechDev/PresentMon/releases/tag/v2.6.0)

- **Organization / author:** Intel / GameTechDev
- **Version / revision:** v2.6.0; commit e13fce6acdb55a808fd8318175a56863e532d95f
- **Publication / update date:** 2026-09-21
- **Access date:** 2026-10-27
- **Exact inspected location:** Release tag; commit link; metrics and capture changes
- **Claim supported:** Version-qualified presentation instrumentation candidate; release commit identity verified.
- **Limits:** Pinned full file views were inaccessible; live README/code inspected separately; no local build/run.
- **License / reuse observation:** Repository MIT license inspected separately in SYS16; bundled dependencies require exact build audit.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys09"></a>

### SYS09 — PresentMon console application documentation

**Source:** [PresentMon console application documentation](https://github.com/GameTechDev/PresentMon/blob/main/README-ConsoleApplication.md)

- **Organization / author:** Intel / GameTechDev
- **Version / revision:** Rolling main retrieved2026-10-27
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** CLI table and CSV column descriptions
- **Claim supported:** Process targeting, QPC output, display metadata, presented versus displayed metrics and instrumented input timing.
- **Limits:** Live README not established byte-identical to v2.6.0; generic input metrics do not uniquely identify a Cyrus generation.
- **License / reuse observation:** MIT repository; see SYS16. No code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys10"></a>

### SYS10 — Acquiring high-resolution timestamps

**Source:** [Acquiring high-resolution timestamps](https://learn.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps)

- **Organization / author:** Microsoft
- **Version / revision:** Living Win32 documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** QPC guidance, multi-thread timestamp ambiguity, frequency and interval conversion
- **Claim supported:** QPC is native interval clock; record frequency and avoid confusing UTC and elapsed-time clocks.
- **Limits:** No Windows timing collected in this environment.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys11"></a>

### SYS11 — About Event Tracing

**Source:** [About Event Tracing](https://learn.microsoft.com/en-us/windows/win32/etw/about-event-tracing)

- **Organization / author:** Microsoft
- **Version / revision:** Win32 ETW
- **Publication / update date:** 2026-07-17
- **Access date:** 2026-10-27
- **Exact inspected location:** Providers/controllers/consumers, TraceLogging, missing events
- **Claim supported:** Application stage markers can be correlated with OS traces; lost events require reporting.
- **Limits:** Does not itself link a specific Max draw result to physical photons.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys12"></a>

### SYS12 — Floating Point and IEEE754 on NVIDIA GPUs

**Source:** [Floating Point and IEEE754 on NVIDIA GPUs](https://docs.nvidia.com/cuda/floating-point/index.html)

- **Organization / author:** NVIDIA
- **Version / revision:** CUDA13.4 documentation
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Formats, operations/accuracy, fused multiply-add, CPU/GPU comparisons
- **Claim supported:** Operation ordering and fused arithmetic can change results despite IEEE-format compliance.
- **Limits:** Cyrus tolerances and performance are independent proposed/experimental questions.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys13"></a>

### SYS13 — LoadLibraryExW

**Source:** [LoadLibraryExW](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadlibraryexw)

- **Organization / author:** Microsoft
- **Version / revision:** libloaderapi.h
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR / SYSTEM32 / DEFAULT_DIRS; return/errors
- **Claim supported:** Explicit absolute paths and dependency search flags; failed loads return null with error.
- **Limits:** No installer/dependency scan was executed; see deployment chapter.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys14"></a>

### SYS14 — DXGI_ERROR

**Source:** [DXGI_ERROR](https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/dxgi-error)

- **Organization / author:** Microsoft
- **Version / revision:** Winerror.h
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Device removed/reset/hung and other error categories
- **Claim supported:** Distinguishes device failure categories for diagnostic and recovery design.
- **Limits:** Not a tested Max recovery procedure.
- **License / reuse observation:** Documentation consulted; no vendor code redistributed.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys15"></a>

### SYS15 — PresentMon DXGI event consumer source

**Source:** [PresentMon DXGI event consumer source](https://github.com/GameTechDev/PresentMon/blob/main/PresentData/PresentMonTraceConsumer.cpp)

- **Organization / author:** Intel / GameTechDev
- **Version / revision:** Rolling main body inspected2026-10-27
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** PMTraceConsumer::HandleDXGIEvent; RuntimePresentStart/Stop and swapchain handling
- **Claim supported:** Actual inspected code maps DXGI event metadata to tracked presents; supports instrument choice.
- **Limits:** Pinned v2.6.0 file body was inaccessible; no complete source audit or execution.
- **License / reuse observation:** MIT notice in repository; dependency terms separate. No code included in package.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.

<a id="sys16"></a>

### SYS16 — PresentMon license

**Source:** [PresentMon license](https://github.com/GameTechDev/PresentMon/blob/main/LICENSE.txt)

- **Organization / author:** Intel / GameTechDev
- **Version / revision:** Live root license; copyright2017–2024
- **Publication / update date:** Not established from the inspected page; access date is not a publication date.
- **Access date:** 2026-10-27
- **Exact inspected location:** Root LICENSE.txt permission/notice/warranty terms
- **Claim supported:** MIT permission and notice requirements for repository code.
- **Limits:** License body date is not release date; selected dependencies/binaries still need inventory.
- **License / reuse observation:** MIT; no third-party code redistributed by this report.
- **Evidence confidence:** Primary page/source inspected; no Windows/Max/GPU execution.


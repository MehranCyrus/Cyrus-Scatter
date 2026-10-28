# 17 — Source ledger

[Contents](00_README.md) · [Reusable implementations](12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md) · [Metadata](RESEARCH_METADATA.json)

**Cutoff:** 27 October 2026. Researcher **A**. This ledger records 116 source IDs, including the supplied project packet and repeated citations to different sections/files of some projects. It does not mean 116 independent implementations or benchmark results.

Dates below are publication/release/commit dates where established. An undated live page is labeled as such; its retrieval date is not substituted for publication. “Verified” means the scoped public text or source was read, not that it was compiled, run in Max, or audited in its entirety. Code pins identify inspected snapshots; live documentation may describe a different release. Consequential discrepancies are preserved.

No third-party paper, full source tree, binary or proprietary project asset is included. Reuse recommendations in chapter 12 require the exact component/dependency notices and applicable redistribution terms; a top-level permissive license is not a blanket license for every dependency. Mathematical estimates and design choices are identified in their chapters, not presented as quotations from these sources.

| Group | Entries | Scope |
|---|---:|---|
| [S](#s-sources) | 1 | Supplied baseline |
| [M](#m-sources) | 32 | Max 2027 and graphics interoperability |
| [C](#c-sources) | 29 | Compute APIs, tooling and distribution |
| [A](#a-sources) | 28 | Original algorithms and inspected implementations |
| [R](#r-sources) | 26 | Numerics, measurement, deformation and hardware |

Machine-readable mirror: [SOURCE_LEDGER.json](SOURCE_LEDGER.json). It contains URLs, source locations, versions and inspected-file hashes where recorded; browser-internal reference IDs are omitted.

<a id="s-sources"></a>
## S — Supplied baseline

<a id="s01"></a>
### S01 — Supplied Cyrus Scatter GPU research brief and current-system context

- **Source:** user-supplied attachment; no public URL.
- **Version/date:** Cyrus Scatter 0.87.4.3; native capability 11; scene schema 63; Windows x64 / 3ds Max 2027; recorded date 2026-10-27.
- **Accessed:** 2026-10-27.
- **Exact location:** RESEARCH_PROMPT(2).md, CURRENT_SYSTEM_CONTEXT(2).md, README(4).md, BRIEF_METADATA(2).json and MANIFEST(2).sha256 in the supplied upload
- **Supported claim:** Defines the assignment and supplied baseline: static fitting semantics, source preparation, limits, threading, paths and scoped historical observations.
- **Limits / what remains unproved:** S — provided project facts only. No production repository, Max host or original benchmark was inspected or rerun. Attachment names carry upload suffixes; canonical names and actual hashes are in RESEARCH_METADATA.json.
- **License / redistribution scope:** User-supplied project context; original proprietary assets and source are not redistributed.
- **Evidence / confidence:** Supplied project context; Authoritative for the requested baseline, not independently verified..

<a id="m-sources"></a>
## M — Max 2027 and graphics interoperability

<a id="m01"></a>
### M01 — Autodesk 3ds Max 2027 — CustomRenderItemHandle

- **Primary source:** [Autodesk 3ds Max 2027 — CustomRenderItemHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_custom_render_item_handle.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/CustomRenderItemHandle.h; SetCustomImplementation, inherited SetObjectBox
- **Supported claim:** Custom item implementation and local bounds setters
- **Limits / what remains unproved:** No native buffer import declared
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m02"></a>
### M02 — Autodesk 3ds Max 2027 — ICustomRenderItem

- **Primary source:** [Autodesk 3ds Max 2027 — ICustomRenderItem](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/ICustomRenderItem.h; Realize, Display, HitTest
- **Supported claim:** Realize may be culled; Display multiple calls/frame; default HitTest draws
- **Limits / what remains unproved:** Not an event solver scheduler
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m03"></a>
### M03 — Autodesk 3ds Max 2027 — DrawContext

- **Primary source:** [Autodesk 3ds Max 2027 — DrawContext](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_draw_context.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/DrawContext.h; GetVirtualDevice
- **Supported claim:** Do not retain virtual device; context can vary in DX11 multithreading
- **Limits / what remains unproved:** Does not describe raw compute ownership
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m04"></a>
### M04 — Autodesk 3ds Max 2027 — IVirtualDevice

- **Primary source:** [Autodesk 3ds Max 2027 — IVirtualDevice](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_virtual_device.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/IVirtualDevice.h; member list; UAV and output stream methods
- **Supported claim:** DrawInstanced, stream output, render-target/UAV binding public
- **Limits / what remains unproved:** Inspected list lacks Dispatch/native export; not entire SDK absence proof
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m05"></a>
### M05 — Autodesk 3ds Max 2027 — VertexBufferHandle

- **Primary source:** [Autodesk 3ds Max 2027 — VertexBufferHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_vertex_buffer_handle.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/VertexBufferHandle.h; Initialize, Lock, Realize, CopyFrom
- **Supported claim:** CPU and hardware realization; GetPointer is IRefObject
- **Limits / what remains unproved:** No native ID3D11Resource unwrap declared
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m06"></a>
### M06 — Autodesk 3ds Max 2027 — HLSLMaterialHandle

- **Primary source:** [Autodesk 3ds Max 2027 — HLSLMaterialHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_h_l_s_l_material_handle.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/HLSLMaterialHandle.h; SetBufferParameter
- **Supported claim:** Buffer setter requires static|target usage; HLSL initialization/error access
- **Limits / what remains unproved:** Exact resource/stage behavior requires host probe
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m07"></a>
### M07 — Autodesk 3ds Max 2027 — TextureHandle

- **Primary source:** [Autodesk 3ds Max 2027 — TextureHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_texture_handle.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/TextureHandle.h; Initialize, WriteOnlyLockRectangle, Map
- **Supported claim:** Texture upload path
- **Limits / what remains unproved:** No interop import established
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m08"></a>
### M08 — Autodesk 3ds Max 2027 — MaxSDK::Graphics buffer enums

- **Primary source:** [Autodesk 3ds Max 2027 — MaxSDK::Graphics buffer enums](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_graphics.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/GeometryEnums.h; BufferUsageType, BufferPoolType
- **Supported claim:** Structure requires hardwarepool; Buffer requires datatype; UAV flags
- **Limits / what remains unproved:** OGS flags not a D3D creation/export contract
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m09"></a>
### M09 — Autodesk 3ds Max 2027 — MaterialRequiredStreamElement

- **Primary source:** [Autodesk 3ds Max 2027 — MaterialRequiredStreamElement](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/struct_max_s_d_k_1_1_graphics_1_1_material_required_stream_element.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/MaterialRequiredStreams.h; SetIsInstanceStream
- **Supported claim:** Last buffer only for instance data; GPUParticle sample pointer
- **Limits / what remains unproved:** Sample itself not locally compiled/inspected
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m10"></a>
### M10 — Autodesk 3ds Max 2027 — ID3D11GraphicsWindow

- **Primary source:** [Autodesk 3ds Max 2027 — ID3D11GraphicsWindow](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d3_d11_graphics_window.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** id3d11graphicswindow.h; GetDevice, GetVertexBuffer, GetIndexBuffer
- **Supported claim:** Native D3D11 device and buffer returns documented
- **Limits / what remains unproved:** Nitrous availability/native resource ownership/retained-handle bridge unresolved
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m11"></a>
### M11 — Autodesk 3ds Max 2027 — IRefObject

- **Primary source:** [Autodesk 3ds Max 2027 — IRefObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_ref_object.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/IRefObject.h; QueryInterface(Interface_ID)
- **Supported claim:** Autodesk refobject interface differs from COM resource pointer
- **Limits / what remains unproved:** Do not reinterpret SmartHandle pointer as native resource
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m12"></a>
### M12 — Autodesk — What’s new in 3ds Max 2027?

- **Primary source:** [Autodesk — What’s new in 3ds Max 2027?](https://blog.autodesk.io/whats-new-in-3ds-max-2027/)
- **Version/date:** 2026-04-13; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** SDK Changes
- **Supported claim:** DX9 removal; public DX11 equivalents; C++20/v143
- **Limits / what remains unproved:** Release-level overview, not interop demonstration
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m13"></a>
### M13 — Autodesk 3ds Max 2027 — id3d11graphicswindow.h

- **Primary source:** [Autodesk 3ds Max 2027 — id3d11graphicswindow.h](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/id3d11graphicswindow_8h.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** D3D11_GRAPHICS_WINDOW_INTERFACE_ID
- **Supported claim:** Macro value 0x155a3968,0x14fa1b03
- **Limits / what remains unproved:** Actual return in current viewport not tested
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m14"></a>
### M14 — Autodesk 3ds Max 2027 — ViewExp

- **Primary source:** [Autodesk 3ds Max 2027 — ViewExp](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_view_exp.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** maxapi.h; getGW
- **Supported claim:** Public GraphicsWindow getter
- **Limits / what remains unproved:** Current-callback const/lease use must follow installed SDK
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m15"></a>
### M15 — Autodesk 3ds Max 2027 — GraphicsWindow

- **Primary source:** [Autodesk 3ds Max 2027 — GraphicsWindow](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_graphics_window.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** GraphicsWindow.h; inherited InterfaceServer::GetInterface
- **Supported claim:** Public typed interface query is present
- **Limits / what remains unproved:** Does not guarantee desired ID is returned in Nitrous
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m16"></a>
### M16 — Autodesk 3ds Max 2027 — IDX11VertexShader

- **Primary source:** [Autodesk 3ds Max 2027 — IDX11VertexShader](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d_x11_vertex_shader.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** idx11vertexshader.h; ConfirmDevice/SetVertexShader
- **Supported claim:** Typed native graphics-window callback parameter
- **Limits / what remains unproved:** Distinct from custom render item; bridge unresolved
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m17"></a>
### M17 — Microsoft — Introduction to Multithreading in Direct3D11

- **Primary source:** [Microsoft — Introduction to Multithreading in Direct3D11](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-render-multi-thread-intro)
- **Version/date:** current docs accessed2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Multithreaded context access
- **Supported claim:** Shared context access requires synchronization
- **Limits / what remains unproved:** Does not authorize Max worker access
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m18"></a>
### M18 — Microsoft — ID3D11Device::GetImmediateContext

- **Primary source:** [Microsoft — ID3D11Device::GetImmediateContext](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/nf-d3d11-id3d11device-getimmediatecontext)
- **Version/date:** last updated2024-02-22; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Remarks
- **Supported claim:** Returned context refcount increments and must be released
- **Limits / what remains unproved:** Different from unspecified Max GetDevice return ownership
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m19"></a>
### M19 — NVIDIA CUDA Runtime — D3D11 Interoperability

- **Primary source:** [NVIDIA CUDA Runtime — D3D11 Interoperability](https://docs.nvidia.com/cuda/cuda-runtime-api/cuda_runtime_api/group__CUDART__D3D11.html)
- **Version/date:** 13.4; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** cudaD3D11GetDevice(s), cudaGraphicsD3D11RegisterResource
- **Supported claim:** Device matching; native resources; refcount and format restrictions
- **Limits / what remains unproved:** Standalone API capability, not Max approval
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m20"></a>
### M20 — NVIDIA CUDA Programming Guide — Graphics interoperability

- **Primary source:** [NVIDIA CUDA Programming Guide — Graphics interoperability](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html)
- **Version/date:** live guide accessed2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** 4.21.1 and4.21.2
- **Supported claim:** Graphics registration vs external resources; mapped exclusivity
- **Limits / what remains unproved:** Current D3D11 external details redirected to12.9
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m21"></a>
### M21 — NVIDIA CUDA Runtime — External Resource Interoperability

- **Primary source:** [NVIDIA CUDA Runtime — External Resource Interoperability](https://docs.nvidia.com/cuda/cuda-runtime-api/cuda_runtime_api/group__CUDART__EXTRES__INTEROP.html)
- **Version/date:** 13.4; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** import/map/wait/signal/destroy functions
- **Supported claim:** Imported memory and semaphore lifecycles are separate
- **Limits / what remains unproved:** Exportable host resource and legal consumption still needed
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m22"></a>
### M22 — NVIDIA CUDA12.9.1 — D3D11 external interoperability

- **Primary source:** [NVIDIA CUDA12.9.1 — D3D11 external interoperability](https://docs.nvidia.com/cuda/archive/12.9.1/cuda-c-programming-guide/index.html#direct3d-11-interoperability)
- **Version/date:** 12.9.1 archived; referenced by current guide; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** 6.2.16.4 matchingLUIDs, import memory, keyedmutex/fence
- **Supported claim:** Same-device resource import, dedicated flag, handle ownership
- **Limits / what remains unproved:** Historical detailed recipe; check selected toolkit restrictions
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m23"></a>
### M23 — Microsoft — D3D11_RESOURCE_MISC_FLAG

- **Primary source:** [Microsoft — D3D11_RESOURCE_MISC_FLAG](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_resource_misc_flag)
- **Version/date:** current docs accessed2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** SHARED,SHARED_NTHANDLE,SHARED_KEYEDMUTEX
- **Supported claim:** Creation flags and ownership synchronization requirements
- **Limits / what remains unproved:** Some support depends resource type, driver and OS; not all flags interchangeable
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m24"></a>
### M24 — Khronos OpenCL unified API — D3D11 sharing

- **Primary source:** [Khronos OpenCL unified API — D3D11 sharing](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html#cl_khr_d3d11_sharing)
- **Version/date:** v3.1.2 /2026-09-17 /219be24fc8947c68ee45b4d25b55a92b8f799f29; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** 4.2.4;5.2.5;D3D11 acquire/release
- **Supported claim:** Extension/device matching/acquire-release/user-sync protocol
- **Limits / what remains unproved:** Spec publication does not establish installed implementation support
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m25"></a>
### M25 — Microsoft — DXGI_ADAPTER_DESC

- **Primary source:** [Microsoft — DXGI_ADAPTER_DESC](https://learn.microsoft.com/en-us/windows/win32/api/dxgi/ns-dxgi-dxgi_adapter_desc)
- **Version/date:** current docs accessed2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Members AdapterLuid,VendorId,DeviceId,DedicatedVideoMemory
- **Supported claim:** Device identity and reported physical capacity fields
- **Limits / what remains unproved:** Capacity is not current budget/free memory
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m26"></a>
### M26 — Autodesk 3ds Max 2027 — QueryHandle

- **Primary source:** [Autodesk 3ds Max 2027 — QueryHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_query_handle.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/QueryHandle.h; Begin/End/GetData
- **Supported claim:** Graphics query readiness; optional flush
- **Limits / what remains unproved:** Not external CUDA semaphore; no full async qualification
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m27"></a>
### M27 — Autodesk 3ds Max 2027 — GeomObject

- **Primary source:** [Autodesk 3ds Max 2027 — GeomObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_geom_object.html)
- **Version/date:** 2027 / generated Doxygen1.15.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** object.h; GetRenderMesh/multiple mesh methods
- **Supported claim:** Renderer mesh ownership and transform APIs
- **Limits / what remains unproved:** No automatic custom viewport-shader renderer integration
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m28"></a>
### M28 — Autodesk — Max2027 SDK Requirements

- **Primary source:** [Autodesk — Max2027 SDK Requirements](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html)
- **Version/date:** 2027; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Requirements table
- **Supported claim:** VS2022IDE17.14.13,v143,C++20,WinSDK19041,.NET10,Qt6.8.3
- **Limits / what remains unproved:** Table alone does not resolve exact minor tools/CRT flags
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m29"></a>
### M29 — Autodesk — Max2027 SDK with VisualStudio2026

- **Primary source:** [Autodesk — Max2027 SDK with VisualStudio2026](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/)
- **Version/date:** 2026-07-31; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** What SDK requires;toolset distinction
- **Supported claim:** v14.38(17.8) tools pinned despite newer IDE
- **Limits / what remains unproved:** Local installed samples and exact build still required
- **License / redistribution scope:** Documentation; no SDK code or binaries redistributed
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m30"></a>
### M30 — Autodesk2027 IDisplayManager

- **Primary source:** [Autodesk2027 IDisplayManager](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_display_manager.html)
- **Version/date:** 2027; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/IDisplayManager.h; GetDeviceCaps
- **Supported claim:** Documented feature-capability query
- **Limits / what remains unproved:** Host capability/layout must be verified; no executed shader test
- **License / redistribution scope:** Documentation; no thirdparty code packaged
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m31"></a>
### M31 — Autodesk2027 DeviceCaps

- **Primary source:** [Autodesk2027 DeviceCaps](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/struct_max_s_d_k_1_1_graphics_1_1_device_caps.html)
- **Version/date:** 2027; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Graphics/DeviceCaps.h; FeatureLevel
- **Supported claim:** Current virtual-device feature level field
- **Limits / what remains unproved:** Host capability/layout must be verified; no executed shader test
- **License / redistribution scope:** Documentation; no thirdparty code packaged
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="m32"></a>
### M32 — Microsoft Direct3D11 resource limits

- **Primary source:** [Microsoft Direct3D11 resource limits](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-resources-limits)
- **Version/date:** current docs;lastupdated2020-08-19; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Feature-level11 resource table
- **Supported claim:** 4096constant-buffer elements; dimension/allocation limits
- **Limits / what remains unproved:** Host capability/layout must be verified; no executed shader test
- **License / redistribution scope:** Documentation; no thirdparty code packaged
- **Evidence / confidence:** Verified public documentation; high for the scoped declaration, not host execution.

<a id="c-sources"></a>
## C — Compute APIs, tooling and distribution

<a id="c01"></a>
### C01 — NVIDIA CUDA Toolkit Archive

- **Primary source:** [NVIDIA CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive)
- **Version/date:** Live archive lists CUDA 13.4.3, October 2026; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Latest Release / Archived Releases
- **Supported claim:** Archive lists 13.4.3 as latest, while the separately inspected live release notes identify Update 2.
- **Limits / what remains unproved:** No toolkit installed. Attempted archived 13.4.3 notes did not open; archive availability is not a qualified installation.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c02"></a>
### C02 — CUDA Toolkit13.4 Update2 Release Notes

- **Primary source:** [CUDA Toolkit13.4 Update2 Release Notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)
- **Version/date:** CUDA 13.4 Update 2; components 13.4.92; CCCL 3.4.3; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Tables 1–3 / CUDA Driver
- **Supported claim:** R615 is the corresponding driver branch; CUDA 13.x has limited-feature minor compatibility from R580. Toolkit and driver are separate.
- **Limits / what remains unproved:** Live mutable documentation, not an installed payload. Bundled profiler versions differ from current standalone versions.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c03"></a>
### C03 — CUDA Installation Guide for Microsoft Windows

- **Primary source:** [CUDA Installation Guide for Microsoft Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html)
- **Version/date:** CUDA 13.4; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Section 2.1, Table 1
- **Supported claim:** MSVC 193x / VS2022 supports native x64 C++20. This does not authorize changing the Max host toolset.
- **Limits / what remains unproved:** Compiler-family support is not proof of the exact Max/backend build combination.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c04"></a>
### C04 — CUDA Compatibility—Minor Version Compatibility

- **Primary source:** [CUDA Compatibility—Minor Version Compatibility](https://docs.nvidia.com/deploy/cuda-compatibility/minor-version-compatibility.html)
- **Version/date:** Current documentation accessed 2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Table 1 / Application Considerations
- **Supported claim:** CUDA 13.x compatibility starts at R580; CUDA 12.x at the R525 family. Limited features, PTX restrictions and explicit architecture targets matter.
- **Limits / what remains unproved:** Not every feature or interop route is guaranteed on a family floor. Pin and test an exact Windows driver.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c05"></a>
### C05 — CUDA13.0 Release Notes—Deprecated Architectures

- **Primary source:** [CUDA13.0 Release Notes—Deprecated Architectures](https://docs.nvidia.com/cuda/archive/13.0.0/cuda-toolkit-release-notes/index.html)
- **Version/date:** CUDA 13.0, August 2025; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Sections 2.6.2 and 2.6.4
- **Supported claim:** CUDA 13 removes offline compilation/library support for Maxwell, Pascal and Volta. CUDA 12.x is the older-target build route. nvprof/Visual Profiler removed.
- **Limits / what remains unproved:** Compiler support floor is not an intrinsic hardware requirement of vegetation geometry.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c06"></a>
### C06 — Khronos Unified OpenCL API Specification

- **Primary source:** [Khronos Unified OpenCL API Specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html)
- **Version/date:** v3.1.2, 2026-09-17; commit 219be24fc8947c68ee45b4d25b55a92b8f799f29; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Section 4.2 queries; Section 5.17 command buffers; Appendices E/H
- **Supported claim:** OpenCL 3.0 optional features require queries. 3.1 requires subgroups and SPIR-V 1.0–1.4. Command buffers remain extension APIs.
- **Limits / what remains unproved:** A published specification does not establish installed NVIDIA/AMD/Intel driver support. The older 3.0 URL redirects here.
- **License / redistribution scope:** Khronos specification copyright/IP terms, not an implementation license
- **Evidence / confidence:** Verified public documentation/source; Verified public specification.

<a id="c07"></a>
### C07 — Khronos OpenCL C Specification

- **Primary source:** [Khronos OpenCL C Specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_C.html)
- **Version/date:** v3.1.2, 2026-09-17; commit 219be24fc8947c68ee45b4d25b55a92b8f799f29; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Sections 6.2, 6.15.8, 6.15.20 and 7
- **Supported claim:** Optional feature macros, local memory/barriers, subgroup operations and numeric behavior require explicit capability profiles.
- **Limits / what remains unproved:** Portable language syntax does not guarantee portable performance; record compiler options.
- **License / redistribution scope:** Khronos specification copyright/IP terms
- **Evidence / confidence:** Verified public documentation/source; Verified public specification.

<a id="c08"></a>
### C08 — CUDA Programming Guide—CUDA Graphs

- **Primary source:** [CUDA Programming Guide—CUDA Graphs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/cuda-graphs.html)
- **Version/date:** CUDA 13.4 generation live guide; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Section 4.2: definition, instantiation, replay and updates
- **Supported claim:** Graph definition is separate from replay; dependencies remain. Replay can reduce repeated submission work.
- **Limits / what remains unproved:** No Cyrus speedup or cancellation guarantee. Graph update compatibility needs local validation.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c09"></a>
### C09 — CUDA Programming Guide—Stream-Ordered Memory Allocator

- **Primary source:** [CUDA Programming Guide—Stream-Ordered Memory Allocator](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/stream-ordered-memory-allocation.html)
- **Version/date:** CUDA 13.4 generation live guide; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Section 4.3.2: allocation, freeing and cross-stream dependencies
- **Supported claim:** cudaMallocAsync/cudaFreeAsync and pools require explicit access/free ordering across streams.
- **Limits / what remains unproved:** Pool release threshold is not a hard application budget; no measured allocation cost here.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c10"></a>
### C10 — NVIDIA CCCLv3.4.3 / CUB source

- **Primary source:** [NVIDIA CCCLv3.4.3 / CUB source](https://github.com/NVIDIA/cccl/tree/5fb1013e3c6f72877a2ebd30f54fe5158d64eec4)
- **Version/date:** v3.4.3, commit 5fb1013e3c6f72877a2ebd30f54fe5158d64eec4, 2026-08-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** cub/cub/device/device_scan.cuh; device_radix_sort.cuh; LICENSE
- **Supported claim:** Scan and sort expose scratch sizing; radix sort is stable. Floating pseudo-associative scan results are not deterministic.
- **Limits / what remains unproved:** Selected public source/license files read, not compiled or benchmarked. Release pin differs from moving tip.
- **License / redistribution scope:** CUB BSD 3-Clause; Thrust Apache 2.0 with exceptions; libcu++ Apache 2.0 with LLVM exceptions; preserve per-file terms
- **Evidence / confidence:** Verified public documentation/source; Verified public source and license.

<a id="c11"></a>
### C11 — NVIDIA cuda-samples13.4 source

- **Primary source:** [NVIDIA cuda-samples13.4 source](https://github.com/NVIDIA/cuda-samples/tree/5443602d89ed99aede2e4b7bf329daddeadb320e)
- **Version/date:** Commit 5443602d89ed99aede2e4b7bf329daddeadb320e, 2026-09-09; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** cpp/5_Domain_Specific/simpleD3D11/simpleD3D11.cpp; sinewave_cuda.cu; cpp/3_CUDA_Features/simpleCudaGraphs/simpleCudaGraphs_capture.cu; LICENSE
- **Supported claim:** Current D3D11 sample owns its device/swapchain and imports shared keyed-mutex buffer memory/semaphore. Graph sample captures and replays.
- **Limits / what remains unproved:** Standalone application, not Nitrous. Sample infinite waits are not recommended host policy. No execution.
- **License / redistribution scope:** Repository BSD 3-Clause; toolkit components have separate EULA
- **Evidence / confidence:** Verified public documentation/source; Verified public source and license.

<a id="c12"></a>
### C12 — Khronos OpenCL-SDK source

- **Primary source:** [Khronos OpenCL-SDK source](https://github.com/KhronosGroup/OpenCL-SDK/tree/6090378a113db8dab20ae278c8fa57ab10b92300)
- **Version/date:** Commit 6090378a113db8dab20ae278c8fa57ab10b92300, 2026-09-22; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** README.md; LICENSE; samples/core/binaries/main.cpp; samples/extensions/khr/externalmemory/main.cpp
- **Supported claim:** SDK assembles headers, bindings, loader and utilities; examples demonstrate binary caching and Vulkan external memory.
- **Limits / what remains unproved:** Pin/audit submodules and dependencies. Selected source read, not compiled. Not a solver or Max D3D11 integration.
- **License / redistribution scope:** SDK Apache 2.0; submodules and sample dependencies have separate terms
- **Evidence / confidence:** Verified public documentation/source; Verified public source and license.

<a id="c13"></a>
### C13 — Khronos OpenCL ICD Loader source

- **Primary source:** [Khronos OpenCL ICD Loader source](https://github.com/KhronosGroup/OpenCL-ICD-Loader/tree/5192c84f8059e5f703e5452929b613f9487f6e4c)
- **Version/date:** Commit 5192c84f8059e5f703e5452929b613f9487f6e4c, 2026-09-22; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** README introduction and Windows ICD registration; LICENSE
- **Supported claim:** Loader enumerates implementations and forwards calls; it does not contain a vendor OpenCL implementation.
- **Limits / what remains unproved:** Loader redistribution does not license a vendor ICD. No installed runtime was queried.
- **License / redistribution scope:** Loader Apache 2.0; vendor ICD has separate terms
- **Evidence / confidence:** Verified public documentation/source; Verified public source and license.

<a id="c14"></a>
### C14 — Microsoft Direct3D11 Compute Shader Overview

- **Primary source:** [Microsoft Direct3D11 Compute Shader Overview](https://learn.microsoft.com/en-us/windows/win32/direct3d11/direct3d-11-advanced-stages-compute-shader)
- **Version/date:** Updated 2021-04-09; current Microsoft reference; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Using Compute Shader on Direct3D 11.x Hardware
- **Supported claim:** cs_5_0 has dispatch, group synchronization, UAVs and a 1,024-thread group maximum; FP64 requires a feature query.
- **Limits / what remains unproved:** API capability does not establish Max access. Maximum limits are not tuning recommendations.
- **License / redistribution scope:** Microsoft documentation
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c15"></a>
### C15 — Microsoft HLSL Shader Model6.0

- **Primary source:** [Microsoft HLSL Shader Model6.0](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/hlsl-shader-model-6-0-features-for-direct3d-12)
- **Version/date:** Current Microsoft reference; SM6 wave intrinsics; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Shader Model 6.0 / Wave operations
- **Supported claim:** Wave intrinsics began with SM6; they are not part of the supplied Cyrus SM5.0 baseline.
- **Limits / what remains unproved:** Does not establish D3D12 replacement or SM6 qualification inside Max.
- **License / redistribution scope:** Microsoft documentation
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c16"></a>
### C16 — NVIDIA NVCC Compiler Driver

- **Primary source:** [NVIDIA NVCC Compiler Driver](https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html)
- **Version/date:** CUDA 13.4; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Section 1.2; Sections 4.2.7.7–10
- **Supported claim:** NVCC delegates host compilation. Fast-math changes FTZ, division, square-root and FMA settings.
- **Limits / what remains unproved:** Prototype flags were not compiled. Matching options does not prove bitwise cross-API output.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c17"></a>
### C17 — NVIDIA Floating Point andIEEE754

- **Primary source:** [NVIDIA Floating Point andIEEE754](https://docs.nvidia.com/cuda/floating-point/index.html)
- **Version/date:** CUDA 13.4 documentation; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Sections 2 and 5
- **Supported claim:** Nonassociativity, fused multiply-add and operation ordering affect CPU/GPU comparisons.
- **Limits / what remains unproved:** No Cyrus hardware-specific error bound or performance result is implied.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c18"></a>
### C18 — CUDA Programming Guide—Interoperability with APIs

- **Primary source:** [CUDA Programming Guide—Interoperability with APIs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html)
- **Version/date:** CUDA 13.4 generation live guide; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Section 4.21 graphics/external resource interoperability
- **Supported claim:** Direct map/unmap and OS-handle external sharing are distinct. Graphics access while CUDA-mapped is undefined.
- **Limits / what remains unproved:** Max resource acquisition, ownership, synchronization and reset must be proved independently.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c19"></a>
### C19 — NVIDIA SDK License and CUDA Supplement

- **Primary source:** [NVIDIA SDK License and CUDA Supplement](https://docs.nvidia.com/cuda/eula/index.html)
- **Version/date:** Last updated 2026-01-26; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Sections 1.1.1–1.1.2 and Attachment A
- **Supported claim:** Specific runtime/NVRTC portions are distributable under conditions; developer-tool redistribution is not blanket permission.
- **Limits / what remains unproved:** Engineering inventory, not legal clearance. Review exact shipped versions and notices.
- **License / redistribution scope:** NVIDIA CUDA EULA
- **Evidence / confidence:** Verified public documentation/source; Verified public license text.

<a id="c20"></a>
### C20 — NVRTC User Guide

- **Primary source:** [NVRTC User Guide](https://docs.nvidia.com/cuda/nvrtc/index.html)
- **Version/date:** CUDA 13.4; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Sections 1, 2.1–2.2 and 3
- **Supported claim:** NVRTC compiles source to GPU code, supports Windows x64 and can compile without a GPU. DLL/builtins packaging is documented.
- **Limits / what remains unproved:** Compilation without GPU does not imply execution without GPU; not required by the AOT proposal.
- **License / redistribution scope:** NVIDIA CUDA EULA; redistributable listing checked separately
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c21"></a>
### C21 — Microsoft LoadLibraryExW

- **Primary source:** [Microsoft LoadLibraryExW](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadlibraryexw)
- **Version/date:** Current Win32 reference; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Parameters, search flags and Remarks
- **Supported claim:** Explicit loading and restricted dependency search are available; module/dependency absence fails loading.
- **Limits / what remains unproved:** Loader proposal is not implemented; an absolute top-level path does not isolate all transitive dependencies.
- **License / redistribution scope:** Microsoft documentation
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c22"></a>
### C22 — Microsoft Dynamic-Link Library Best Practices

- **Primary source:** [Microsoft Dynamic-Link Library Best Practices](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-best-practices)
- **Version/date:** Historical 2006 guidance, current Win32 reference; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** General Best Practices / DllMain loader lock
- **Supported claim:** Minimal DllMain and deferred initialization avoid loader-lock hazards; do not load DLLs or synchronize workers there.
- **Limits / what remains unproved:** Historical guidance, not Max-specific lifetime qualification.
- **License / redistribution scope:** Microsoft documentation
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c23"></a>
### C23 — Microsoft Visual C++ Redistributable latest supported downloads

- **Primary source:** [Microsoft Visual C++ Redistributable latest supported downloads](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170)
- **Version/date:** Current v14 reference for Visual Studio 2017–2026; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Redistribution terms and v14 notes
- **Supported claim:** Redistribution has Visual Studio licensing conditions; target architecture and runtime age must match the build.
- **Limits / what remains unproved:** Does not establish Max ABI or CRT flags; exact redistributable package still needs a pin.
- **License / redistribution scope:** Visual Studio licensing terms apply separately
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c24"></a>
### C24 — Microsoft SignTool

- **Primary source:** [Microsoft SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- **Version/date:** Current Windows SDK tool reference; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Sign, timestamp, verify and digest requirements
- **Supported claim:** SignTool signs, timestamps and verifies files; Microsoft recommends SHA256 digest selection.
- **Limits / what remains unproved:** Signing does not grant graphics interoperability or driver rights. No package built or signed here.
- **License / redistribution scope:** Microsoft documentation
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c25"></a>
### C25 — Autodesk3dsMax2027 SDKRequirements

- **Primary source:** [Autodesk3dsMax2027 SDKRequirements](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html)
- **Version/date:** 3ds Max 2027 / 29.0; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** SDK Requirements table, 2027 row
- **Supported claim:** VS2022 IDE17.14.13, v143, C++20, Windows SDK10.0.19041.0, .NET10 and Qt6.8.3 are listed.
- **Limits / what remains unproved:** IDE version does not uniquely identify compiler patch; inspect local SDK property sheets.
- **License / redistribution scope:** Autodesk SDK/documentation terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c26"></a>
### C26 — Autodesk—Setting Up3dsMax2027 SDKDevelopment withVisualStudio2026

- **Primary source:** [Autodesk—Setting Up3dsMax2027 SDKDevelopment withVisualStudio2026](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/)
- **Version/date:** Published 2026-07-31; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** SDK requirements / toolset explanation
- **Supported claim:** Autodesk clarifies v14.38 / 17.8 build tools independently from IDE, with Windows SDK10.0.19041.0 and C++20.
- **Limits / what remains unproved:** Primary vendor clarification, not a local build pass or universal ABI proof.
- **License / redistribution scope:** Autodesk documentation
- **Evidence / confidence:** Verified public documentation/source; Verified primary vendor clarification.

<a id="c27"></a>
### C27 — NVIDIA Compute Sanitizer

- **Primary source:** [NVIDIA Compute Sanitizer](https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html)
- **Version/date:** Current standalone reference accessed 2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Introduction / tools / invocation
- **Supported claim:** Memcheck, racecheck, initcheck and synccheck instrument CUDA implementation correctness.
- **Limits / what remains unproved:** These do not prove geometric contact correctness. Record exact tool version locally. Not executed here.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c28"></a>
### C28 — CUDA Driver API—Primary Context Management

- **Primary source:** [CUDA Driver API—Primary Context Management](https://docs.nvidia.com/cuda/cuda-driver-api/cuda_driver_api/group__CUDA__PRIMARY__CTX.html)
- **Version/date:** CUDA 13.4; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** cuDevicePrimaryCtxRetain, Release and Reset
- **Supported claim:** Primary context is shared with runtime; reset destroys resources and requires assurance that other process modules are not using it.
- **Limits / what remains unproved:** Does not prove renderer coexistence in Max; context policy remains a local qualification.
- **License / redistribution scope:** NVIDIA documentation / applicable toolkit terms
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="c29"></a>
### C29 — Khronos clGetDeviceInfo reference

- **Primary source:** [Khronos clGetDeviceInfo reference](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clGetDeviceInfo.html)
- **Version/date:** Current unified OpenCL 3.1 reference; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Device query table
- **Supported claim:** Device admission can query memory, workgroup, numerical, compiler and language capabilities.
- **Limits / what remains unproved:** Use version-valid query enums; no actual GPU device was queried here.
- **License / redistribution scope:** Khronos documentation
- **Evidence / confidence:** Verified public documentation/source; Verified public documentation.

<a id="a-sources"></a>
## A — Original algorithms and inspected implementations

<a id="a01"></a>
### A01 — Müller et al. — Position Based Dynamics

- **Primary source:** [Müller et al. — Position Based Dynamics](https://matthias-research.github.io/pages/publications/posBasedDyn.pdf)
- **Version/date:** Original VRIPHYS 2006 paper; later journal version often cited as 2007; recorded date 2006.
- **Accessed:** 2026-10-27.
- **Exact location:** §3, Algorithm steps 5–16; projection solver
- **Supported claim:** Position-level constraints coexist with time integration and velocity update; Gauss–Seidel order matters.
- **Limits / what remains unproved:** Original dynamics method, not a ready static fitter; no paper performance used.
- **License / redistribution scope:** Paper copyright; no software license inferred.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a02"></a>
### A02 — Macklin, Müller, Chentanez — XPBD

- **Primary source:** [Macklin, Müller, Chentanez — XPBD](https://mmacklin.com/xpbd.pdf)
- **Version/date:** MiG 2016; DOI 10.1145/2994258.2994272; recorded date 2016-10-10.
- **Accessed:** 2026-10-27.
- **Exact location:** Algorithm 1, Eq.18, §7
- **Supported claim:** Compliance/multiplier formulation; time-step scaling; finite-iteration artificial compliance.
- **Limits / what remains unproved:** No speedup predicted; physical-time formulation needs explicit adaptation for static fitting.
- **License / redistribution scope:** Paper copyright; independent implementation required.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a03"></a>
### A03 — Bergou et al. — Discrete Elastic Rods

- **Primary source:** [Bergou et al. — Discrete Elastic Rods](https://www.cs.columbia.edu/cg/pdfs/143-rods.pdf)
- **Version/date:** SIGGRAPH/TOG27(3), DOI10.1145/1360612.1360662; recorded date 2008-08.
- **Accessed:** 2026-10-27.
- **Exact location:** §§4–8, Algorithm1, Table1
- **Supported claim:** Framed rest curves, anisotropy, inextensibility; quasistatic twist with dynamic centerline; collision is separate.
- **Limits / what remains unproved:** Paper/source formulation not GPU or Max qualification; no timing extrapolation.
- **License / redistribution scope:** Paper copyright.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a04"></a>
### A04 — Kugelstadt, Schömer — Position and Orientation Based Cosserat Rods

- **Primary source:** [Kugelstadt, Schömer — Position and Orientation Based Cosserat Rods](https://animation.rwth-aachen.de/media/papers/2016-SCA-Cosserat-Rods.pdf)
- **Version/date:** SCA2016, DOI10.2312/sca.20161234; recorded date 2016.
- **Accessed:** 2026-10-27.
- **Exact location:** Algorithm1, §§5–6, Eq.37; publisher https://diglib.eg.org/handle/10.2312/sca20161234
- **Supported claim:** Position/quaternion coupling, stretch/shear and bend/twist constraints.
- **Limits / what remains unproved:** Selected original-paper passages indexed by search and publisher metadata; direct PDF fetch blocked/timeout; companion PBD source inspected separately. No whole-paper execution.
- **License / redistribution scope:** Eurographics paper copyright; companion software license separately A23.
- **Evidence / confidence:** Verified public documentation/source; High for cited algorithm passages; full PDF access limited.

<a id="a05"></a>
### A05 — Deul et al. — Direct Position-Based Solver for Stiff Rods

- **Primary source:** [Deul et al. — Direct Position-Based Solver for Stiff Rods](https://animation.rwth-aachen.de/publication/0557/)
- **Version/date:** CGF37(6),313–324, DOI10.1111/cgf.13326; recorded date 2018.
- **Accessed:** 2026-10-27.
- **Exact location:** Author abstract, original indexed §4.2; companion code A23
- **Supported claim:** Direct solver for acyclic rod structures; collisions alternated with rod solve.
- **Limits / what remains unproved:** Direct author-page/PDF fetch timed out; original indexed passages and current code inspected. No paper speedup adopted.
- **License / redistribution scope:** Paper copyright; companion MIT code separately A23.
- **Evidence / confidence:** Verified public documentation/source; High for abstract/inspected code; limited paper access.

<a id="a06"></a>
### A06 — Bouaziz et al. — Projective Dynamics

- **Primary source:** [Bouaziz et al. — Projective Dynamics](https://users.cs.utah.edu/~ladislav/bouaziz14projective/bouaziz14projective.pdf)
- **Version/date:** SIGGRAPH/TOG33(4); DOI10.1145/2601097.2601116; recorded date 2014.
- **Accessed:** 2026-10-27.
- **Exact location:** §§3,8,9
- **Supported claim:** Local/global projection energy; fixed structure prefactorization; dynamic constraint matrix updates; original CPU OpenMP implementation and hard-constraint limitations.
- **Limits / what remains unproved:** Original GPU implementation was future work; no Cyrus timing inference.
- **License / redistribution scope:** Paper copyright.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "pd.pdf",
    "sha256": "41a0e0ba0de70dfdddc59dca047130394bc7a6ae3ebca695237729ead8af23d0",
    "bytes": 18166821
  }
]
```

<a id="a07"></a>
### A07 — Macklin et al. — Unified Particle Physics for Real-Time Applications

- **Primary source:** [Macklin et al. — Unified Particle Physics for Real-Time Applications](https://mmacklin.com/uppfrta_preprint.pdf)
- **Version/date:** SIGGRAPH/TOG33(4); recorded date 2014.
- **Accessed:** 2026-10-27.
- **Exact location:** §3 fixed-radius particles, §4 parallel SOR/averaging
- **Supported claim:** Parallel constraint averaging and relaxation; plain Jacobi can oscillate; particle representation tradeoffs.
- **Limits / what remains unproved:** Not full vegetation surface collision, material calibration or stateless fitting.
- **License / redistribution scope:** Paper copyright.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a08"></a>
### A08 — Müller et al. — Fast Simulation of Inextensible Hair and Fur

- **Primary source:** [Müller et al. — Fast Simulation of Inextensible Hair and Fur](https://matthias-research.github.io/pages/publications/FTLHairFur.pdf)
- **Version/date:** VRIPHYS2012; recorded date 2012.
- **Accessed:** 2026-10-27.
- **Exact location:** §3.1 static FTL, §3.2 dynamics, §§3.6–4 hardware and measurements
- **Supported claim:** Root-to-tip geometric enforcement; dynamic extension uses history. Authors report 47,000 hairs / 776,000 particles at 25 fps on GTX 480 including rendering and eight ellipsoids; long-hair 1.9M particles at 8 fps.
- **Limits / what remains unproved:** Historical author results, not executed here; collider/quality scope unlike Cyrus; follower hair limitation discussed.
- **License / redistribution scope:** Eurographics paper copyright.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a09"></a>
### A09 — Macklin et al. — Local Optimization for Robust Signed Distance Field Collision

- **Primary source:** [Macklin et al. — Local Optimization for Robust Signed Distance Field Collision](https://mmacklin.com/sdfcontact.pdf)
- **Version/date:** PACMCGIT3(1),Article8; DOI10.1145/3384538; recorded date 2020-05.
- **Accessed:** 2026-10-27.
- **Exact location:** Abstract; original indexed §9 limitations; author-institution page https://di.ku.dk/english/research/groups/simulation/research-results/local-optimization-for-robust-signed-distance-field-collision/
- **Supported claim:** Per-element contact search improves point sampling; local minima and one contact per element may miss multiple features.
- **Limits / what remains unproved:** Full file exceeded web retrieval limit and direct download403; indexed original sections and institution abstract inspected. No claim full-PDF inspection.
- **License / redistribution scope:** Paper copyright.
- **Evidence / confidence:** Verified public documentation/source; High for accessible original abstract and limitations; full file not retrieved.

<a id="a10"></a>
### A10 — Barill et al. — Fast Winding Numbers for Soups and Clouds

- **Primary source:** [Barill et al. — Fast Winding Numbers for Soups and Clouds](https://www.dgp.toronto.edu/projects/fast-winding-numbers/)
- **Version/date:** SIGGRAPH/TOG37(4),Article43; DOI10.1145/3197517.3201337; recorded date 2018-07-30.
- **Accessed:** 2026-10-27.
- **Exact location:** Author project and original abstract
- **Supported claim:** Hierarchical winding approximation useful for defect-tolerant occupancy.
- **Limits / what remains unproved:** Threshold on open/inconsistent geometry is not a uniquely defined physical solid. Source licenses must be checked independently; no performance inferred.
- **License / redistribution scope:** Paper copyright; linked implementation licenses not imported.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a11"></a>
### A11 — Karras — Maximizing Parallelism in Construction of BVHs, Octrees and k-d Trees

- **Primary source:** [Karras — Maximizing Parallelism in Construction of BVHs, Octrees and k-d Trees](https://research.nvidia.com/publication/2012-06_maximizing-parallelism-construction-bvhs-octrees-and-k-d-trees)
- **Version/date:** HPG2012; recorded date 2012-06.
- **Accessed:** 2026-10-27.
- **Exact location:** §§3–5, original PDF https://research.nvidia.com/sites/default/files/pubs/2012-06_Maximizing-Parallelism-in/karras2012hpg_paper.pdf
- **Supported claim:** Parallel binary radix tree from Morton codes; duplicate keys need care; useful bulk-build primitive.
- **Limits / what remains unproved:** Original CUDA4.0/GTX480/Windows7 timings; simulated larger-core cases explicitly distinguished in paper. No Cyrus performance prediction.
- **License / redistribution scope:** Eurographics paper copyright.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a12"></a>
### A12 — Zioma — GPU-Generated Procedural Wind Animations for Trees

- **Primary source:** [Zioma — GPU-Generated Procedural Wind Animations for Trees](https://developer.nvidia.com/gpugems/gpugems3/part-i-geometry/chapter-6-gpu-generated-procedural-wind-animations-trees)
- **Version/date:** GPU Gems3 chapter6; recorded date 2007.
- **Accessed:** 2026-10-27.
- **Exact location:** §§6.2–6.4
- **Supported claim:** Vertex-shader procedural hierarchy works with instancing; visual wind rather than collision/physical-force solve.
- **Limits / what remains unproved:** Historical technique; no Max SDK or collision quality evidence.
- **License / redistribution scope:** Book/example terms require separate review before code reuse.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a13"></a>
### A13 — NVIDIA Warp v1.18.0 release

- **Primary source:** [NVIDIA Warp v1.18.0 release](https://github.com/NVIDIA/warp/releases/tag/v1.18.0)
- **Version/date:** v1.18.0; recorded date 2026-10-05.
- **Repository pin:** `f2eaed82d8d03b37bf1014cc975954067fefcf16`.
- **Accessed:** 2026-10-27.
- **Exact location:** Official release notes + API release metadata
- **Supported claim:** Default wheels CUDA13.4, R580+, Turing+; CUDA12 variants; unversioned latest docs differ.
- **Limits / what remains unproved:** Package floor is not intrinsic fitter floor; no wheels installed or GPU executed.
- **License / redistribution scope:** Top-level Apache2 and dependency licenses separately A18.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "warp/README.md",
    "sha256": "ed7ff3659bdc21acaebbccd22d8d23fe577e0a8aea7c5374176de21c6569cd15",
    "bytes": 21974
  }
]
```

<a id="a14"></a>
### A14 — Warp native mesh queries

- **Primary source:** [Warp native mesh queries](https://github.com/NVIDIA/warp/blob/f2eaed82d8d03b37bf1014cc975954067fefcf16/warp/native/mesh.h)
- **Version/date:** v1.18.0; recorded date 2026-10-05.
- **Repository pin:** `f2eaed82d8d03b37bf1014cc975954067fefcf16`.
- **Accessed:** 2026-10-27.
- **Exact location:** mesh_query_point; mesh_query_point_sign_winding_number; mesh_query_inside_ray_tracing
- **Supported claim:** Sign only assigned after successful nearest-face search; max_dist strict comparison; winding-data fallback; sliver skip and FP32 geometry.
- **Limits / what remains unproved:** No query execution. Must not interpret false as outside; underlying interface lacks Cyrus complete/budget status.
- **License / redistribution scope:** Apache2 with separate winding-number MIT notice; full dependency audit not performed.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "warp/warp/native/mesh.h",
    "sha256": "2ca8ad8b30761f8afe5f0b0f54a540b703b8f64afb8ae60ad96a8b0a530a3bfa",
    "bytes": 86702
  },
  {
    "path": "warp/licenses/windingnumber-LICENSE.txt",
    "sha256": "86027b5213fc4e89aacb0636ebdec4034f949d33c7c0c65ac8e48bae58e07954",
    "bytes": 1083
  }
]
```

<a id="a15"></a>
### A15 — Warp BVH device refit and traversal

- **Primary source:** [Warp BVH device refit and traversal](https://github.com/NVIDIA/warp/blob/f2eaed82d8d03b37bf1014cc975954067fefcf16/warp/native/bvh.cu)
- **Version/date:** v1.18.0; recorded date 2026-10-05.
- **Repository pin:** `f2eaed82d8d03b37bf1014cc975954067fefcf16`.
- **Accessed:** 2026-10-27.
- **Exact location:** bvh_refit_kernel,bvh_refit_device, builder depth limits; bvh.h BVH_QUERY_STACK_SIZE
- **Supported claim:** GPU refit available; fixed 32-entry query stack is coupled to builder invariants.
- **Limits / what remains unproved:** No proof of complete work budgeting; no benchmarks or exhaustive builder audit.
- **License / redistribution scope:** Apache2; cuBQL dependency separately licensed Apache2 at inspected pin.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "warp/warp/native/bvh.h",
    "sha256": "79eaa461669dd4ac99ddbdadde6846e1e1a80e57bbb8f3aeb894a8d31eb66321",
    "bytes": 25994
  },
  {
    "path": "warp/warp/native/bvh.cu",
    "sha256": "15fad0fdf07b69f756ff6bacf87281f44273028e54e144bb0def2c7b707c85ed",
    "bytes": 34379
  },
  {
    "path": "warp/licenses/cubql-LICENSE.txt",
    "sha256": "73f9a72b376af37a63d1ce98cc5f49a4bc20d3b25f63e73fde36c1b9b745cf8f",
    "bytes": 11472
  }
]
```

<a id="a16"></a>
### A16 — Warp sparse-volume sampling

- **Primary source:** [Warp sparse-volume sampling](https://github.com/NVIDIA/warp/blob/f2eaed82d8d03b37bf1014cc975954067fefcf16/warp/native/volume.h)
- **Version/date:** v1.18.0; recorded date 2026-10-05.
- **Repository pin:** `f2eaed82d8d03b37bf1014cc975954067fefcf16`.
- **Accessed:** 2026-10-27.
- **Exact location:** volume_sample,volume_sample_grad,volume_sample_f
- **Supported claim:** Volume sampling and gradient operations; stored background values do not by themselves establish valid signed distance.
- **Limits / what remains unproved:** No field construction/error correctness proven by sampling API.
- **License / redistribution scope:** Apache2 plus NanoVDB/dependencies to audit.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "warp/warp/native/volume.h",
    "sha256": "a536cc157f9a45fc7d23dfa664517ca3f824238d221d0429dd2b9475b1874867",
    "bytes": 38573
  }
]
```

<a id="a17"></a>
### A17 — Warp standalone C++ integration examples

- **Primary source:** [Warp standalone C++ integration examples](https://github.com/NVIDIA/warp/blob/f2eaed82d8d03b37bf1014cc975954067fefcf16/warp/examples/cpp/README.md)
- **Version/date:** v1.18.0; recorded date 2026-10-05.
- **Repository pin:** `f2eaed82d8d03b37bf1014cc975954067fefcf16`.
- **Accessed:** 2026-10-27.
- **Exact location:** 00_cubin_launch,01_source_include,02_apic_visualization,03_apic_visualization_cpu
- **Supported claim:** AOT CUBIN/generated source and APIC C++ replay examples, optional CPU replay path.
- **Limits / what remains unproved:** Examples not built; not every Warp feature or Max runtime qualified.
- **License / redistribution scope:** Apache2 plus CUDA/LLVM/runtime dependencies.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "warp/warp/examples/cpp/README.md",
    "sha256": "852fe78f461cfe625b03ac2a2d5fd004271cf0a8a0a3b9c79a72746fe03d5498",
    "bytes": 7266
  },
  {
    "path": "warp/warp/examples/cpp/00_cubin_launch/README.md",
    "sha256": "e314f1837d6196cbfbc8024b5a30f5472b7668a78917172e26ef890a81d60439",
    "bytes": 5764
  }
]
```

<a id="a18"></a>
### A18 — Warp license and third-party notice tree

- **Primary source:** [Warp license and third-party notice tree](https://github.com/NVIDIA/warp/blob/f2eaed82d8d03b37bf1014cc975954067fefcf16/LICENSE.md)
- **Version/date:** v1.18.0; recorded date 2026-10-05.
- **Repository pin:** `f2eaed82d8d03b37bf1014cc975954067fefcf16`.
- **Accessed:** 2026-10-27.
- **Exact location:** LICENSE.md,licenses/ directory
- **Supported claim:** Apache-2.0 main software; separate notices for CUDA, NVRTC, libmathdx, winding-number, cuBQL and other components.
- **Limits / what remains unproved:** Only selected notices inspected; packaging needs exact transitive/binary audit.
- **License / redistribution scope:** Apache-2.0 main code; other component terms separately apply.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "warp/LICENSE.md",
    "sha256": "47107323a174bfffeaffdc5b778152c3f9bdf66b2ecec4229542480d5937bcf9",
    "bytes": 11431
  },
  {
    "path": "warp/licenses/windingnumber-LICENSE.txt",
    "sha256": "86027b5213fc4e89aacb0636ebdec4034f949d33c7c0c65ac8e48bae58e07954",
    "bytes": 1083
  },
  {
    "path": "warp/licenses/cubql-LICENSE.txt",
    "sha256": "73f9a72b376af37a63d1ce98cc5f49a4bc20d3b25f63e73fde36c1b9b745cf8f",
    "bytes": 11472
  }
]
```

<a id="a19"></a>
### A19 — TressFX public simulation shader

- **Primary source:** [TressFX public simulation shader](https://github.com/GPUOpen-Effects/TressFX/blob/ba0bdacdfb964e38522fda812bf23169bc5fa603/src/Shaders/TressFXSimulation.hlsl)
- **Version/date:** Public4.1 repository snapshot; recorded date 2020-01-24.
- **Repository pin:** `ba0bdacdfb964e38522fda812bf23169bc5fa603`.
- **Accessed:** 2026-10-27.
- **Exact location:** IntegrationAndGlobalShapeConstraints;LocalShapeConstraints;LengthConstriantsWindAndCollision
- **Supported claim:** Vertex, strand, colored-edge pass mappings; previous positions/history and dynamic integration.
- **Limits / what remains unproved:** No shader compiled; public4.1 source, not5.0 Unreal patch.
- **License / redistribution scope:** MIT header/repository; dependencies separately apply.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "TressFX/src/Shaders/TressFXSimulation.hlsl",
    "sha256": "c8f09bf49a3b30ebf4e2b2cc11d753b42baee811e3b6d12bd5cac06ba62eb734",
    "bytes": 45388
  }
]
```

<a id="a20"></a>
### A20 — TressFX SDF construction and collision shader

- **Primary source:** [TressFX SDF construction and collision shader](https://github.com/GPUOpen-Effects/TressFX/blob/ba0bdacdfb964e38522fda812bf23169bc5fa603/src/Shaders/TressFXSDFCollision.hlsl)
- **Version/date:** Public4.1 repository snapshot; recorded date 2020-01-24.
- **Repository pin:** `ba0bdacdfb964e38522fda812bf23169bc5fa603`.
- **Accessed:** 2026-10-27.
- **Exact location:** ConstructSignedDistanceField;CollideHairVerticesWithSdf;forward variant;TressFXSDFCollision.cpp
- **Supported claim:** Vertex-only hair collision; interpolated distances and approximate gradients; out-of-grid/uninitialized early returns; forward variant skips the first two strand vertices.
- **Limits / what remains unproved:** Does not establish whole-span, visible-leaf or rooted-solid coverage; no execution.
- **License / redistribution scope:** MIT main shader code; no binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "TressFX/src/Shaders/TressFXSDFCollision.hlsl",
    "sha256": "fbe949965e7d3c41ee4e9f0af1bd237559c1ff7cc2c50f558ad50f58fd0f9d6e",
    "bytes": 26132
  },
  {
    "path": "TressFX/src/TressFX/TressFXSDFCollision.cpp",
    "sha256": "faa5b1e5220cd663dd1228f3dec424ec07aaac3193209c907c71c1a4a02a4f8d",
    "bytes": 9219
  }
]
```

<a id="a21"></a>
### A21 — TressFX public repository README, license, submodules

- **Primary source:** [TressFX public repository README, license, submodules](https://github.com/GPUOpen-Effects/TressFX/tree/ba0bdacdfb964e38522fda812bf23169bc5fa603)
- **Version/date:** Public4.1 repository snapshot; recorded date 2020-01-24.
- **Repository pin:** `ba0bdacdfb964e38522fda812bf23169bc5fa603`.
- **Accessed:** 2026-10-27.
- **Exact location:** README.md,license.txt,.gitmodules
- **Supported claim:** DX12/Vulkan Cauldron sample; MIT license; separate Cauldron dependency.
- **Limits / what remains unproved:** Historical public repository; 5.0 Unreal patch is separate; no claim of active 2026 maintenance.
- **License / redistribution scope:** MIT main repo; Cauldron/assets must be audited independently.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "TressFX/README.md",
    "sha256": "cd18572ce77e9b5e5a34572da13fcc0b68b5e891d2a73d487868e5ae4bc32ff4",
    "bytes": 8994
  },
  {
    "path": "TressFX/license.txt",
    "sha256": "e008031a95f6f655def9eaf914118531c9e1055b8ea201eb98b9f95f1af9bec4",
    "bytes": 1094
  },
  {
    "path": "TressFX/.gitmodules",
    "sha256": "eafad80bb9a9d5a740848797375d2953446837b540b18b4ffd42de360e0347cb",
    "bytes": 110
  }
]
```

<a id="a22"></a>
### A22 — AMD TressFX5.0 for UnrealEngine5 update

- **Primary source:** [AMD TressFX5.0 for UnrealEngine5 update](https://gpuopen.com/learn/tressfx-5-0-unreal-engine-5-update/)
- **Version/date:** TressFX 5.0 for Unreal Engine 5.4; recorded date 2025-08-04.
- **Accessed:** 2026-10-27.
- **Exact location:** Official release announcement; download/access section
- **Supported claim:** Separate 5.0 UE patch; access requires registered Unreal developer / Epic repository access.
- **Limits / what remains unproved:** Patch not accessed or inspected; does not prove Max/D3D11 capability.
- **License / redistribution scope:** Unreal patch licensing context not audited; no distribution proposed.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a23"></a>
### A23 — InteractiveComputerGraphics PositionBasedDynamics

- **Primary source:** [InteractiveComputerGraphics PositionBasedDynamics](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics/tree/10a70bc146a97873dc3c8fef372f5217e010542e)
- **Version/date:** Source snapshot; recorded date 2026-09-01.
- **Repository pin:** `10a70bc146a97873dc3c8fef372f5217e010542e`.
- **Accessed:** 2026-10-27.
- **Exact location:** PositionBasedElasticRods.cpp;Simulation/TimeStepController.cpp;SimulationModel.cpp;LICENSE
- **Supported claim:** Cosserat constraints, direct stiff rods; sequential constraint groups with OpenMP within groups.
- **Limits / what remains unproved:** CPU reference, notGPUport. Only listed files inspected; dependency/demoassetsauditneeded.
- **License / redistribution scope:** MIT main software.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "PositionBasedDynamics/README.md",
    "sha256": "149fb00d627cf8b013a6c7d1253a1fdcfc68fc4c992b382d3d692a62bb0f184f",
    "bytes": 10366
  },
  {
    "path": "PositionBasedDynamics/LICENSE",
    "sha256": "825d46292692c501a88ddd745cddf69e2198b8354f44ae1f192627d79bad2ae7",
    "bytes": 1111
  },
  {
    "path": "PositionBasedDynamics/PositionBasedDynamics/PositionBasedElasticRods.cpp",
    "sha256": "2e0fca926ff386445cc9252b4f651904d3f60e8567143db963b6383a5ac46751",
    "bytes": 44688
  },
  {
    "path": "PositionBasedDynamics/Simulation/TimeStepController.cpp",
    "sha256": "2c1e7fb2fac9bca142c4c3695e3b01d784c6e44b06d1781a994c25dff55c7311",
    "bytes": 13408
  },
  {
    "path": "PositionBasedDynamics/Simulation/SimulationModel.cpp",
    "sha256": "e21838513f2b053b5f9bd4699633d066763781e6830510b1ab180e07cac264ab",
    "bytes": 59314
  }
]
```

<a id="a24"></a>
### A24 — OpenVDB/NanoVDB current source snapshot

- **Primary source:** [OpenVDB/NanoVDB current source snapshot](https://github.com/AcademySoftwareFoundation/openvdb/tree/2ad72431a9f96084910ea5d9a6bb6f46d9073e62)
- **Version/date:** Source snapshot; NanoVDB header ABI/API 32.10.0, not asserted tagged release; recorded date 2026-10-24.
- **Repository pin:** `2ad72431a9f96084910ea5d9a6bb6f46d9073e62`.
- **Accessed:** 2026-10-27.
- **Exact location:** NanoVDB.h leading notes,GridBuilder.h,MeshToVolume.h,LICENSE,RE-LICENSE_NOTE.txt
- **Supported claim:** Compact GPU/CPU-friendly data, 32-byte alignment, per-thread read accessor, and current Apache-2.0 relicense.
- **Limits / what remains unproved:** Data-layout reuse only; no field-accuracy/solid-correctness benchmark or full dependency audit.
- **License / redistribution scope:** Apache-2.0 at inspected pin; historical MPL labels not applied.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "openvdb/LICENSE",
    "sha256": "a6cba85bc92e0cff7a450b1d873c0eaa2e9fc96bf472df0247a26bec77bf3ff9",
    "bytes": 10173
  },
  {
    "path": "openvdb/RE-LICENSE_NOTE.txt",
    "sha256": "ac78fb9ed20b3276fb7892e81adcc9a1d483feb46a554a4529a40c92779f0744",
    "bytes": 824
  },
  {
    "path": "openvdb/nanovdb/nanovdb/NanoVDB.h",
    "sha256": "41a5f4f8d8c1f169337c9cd5a424a6b2b6f2cd6106b0450fc87bca8498361f35",
    "bytes": 295955
  },
  {
    "path": "openvdb/nanovdb/nanovdb/tools/GridBuilder.h",
    "sha256": "16390379aa1646395754b5c48b528a795e44cf03d4cc24b096aa0536e8d46ee6",
    "bytes": 92179
  },
  {
    "path": "openvdb/openvdb/openvdb/tools/MeshToVolume.h",
    "sha256": "c51a5b5c5781151a63d670dd4e2c3f6c8d36987343b3f7ac2ebed720581e6db8",
    "bytes": 152943
  }
]
```

<a id="a25"></a>
### A25 — Jolt exact historical comparator pin: CPU rods and separate GPU hair

- **Primary source:** [Jolt exact historical comparator pin: CPU rods and separate GPU hair](https://github.com/jrouwe/JoltPhysics/tree/1b2e77e3c6c09709e5edc79dc208459b8ff32051)
- **Version/date:** Header 5.6.1; exact historical pin; separate publication date not independently established.
- **Repository pin:** `1b2e77e3c6c09709e5edc79dc208459b8ff32051`.
- **Accessed:** 2026-10-27.
- **Exact location:** Core.h;SoftBodySharedSettings.h;DetermineCollisionPlanes;Physics/Hair/Hair.h
- **Supported claim:** CPU rod constraints; vertex collision-plane path; experimental hair TODOs include convex-hull-only collision, missing LOD/wind, duplicated memory.
- **Limits / what remains unproved:** Not a current Cyrus implementation claim; no build/run; not tag 5.6.0; no GPU capacity claim.
- **License / redistribution scope:** MIT.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "Jolt/Jolt/Core/Core.h",
    "sha256": "8dd35545f20ec75b4dd7730502a8dd646c1292f50d0ce8ad410ee56655058a5a",
    "bytes": 26755
  },
  {
    "path": "Jolt/Jolt/Physics/SoftBody/SoftBodySharedSettings.h",
    "sha256": "7b5074c9ba88463d2f017433478df597c4350062a9db206a61b9d6f75a8f6146",
    "bytes": 22275
  },
  {
    "path": "Jolt/Jolt/Physics/SoftBody/SoftBodyMotionProperties.cpp",
    "sha256": "75e579649b8087ca4c06925869f3281d82cff3a384bfc8a79649d52885ea4697",
    "bytes": 58218
  },
  {
    "path": "Jolt/Jolt/Physics/Hair/Hair.h",
    "sha256": "f159a3a1f68d6b130da2bb1b96fef8f44904d6bfeb51a3f5844354c62ccb2cfb",
    "bytes": 13636
  },
  {
    "path": "Jolt/LICENSE",
    "sha256": "800abe35d64ad9defd636ff1ee8c961e06f0ebca3ef8d10083e8aa0e8ef86ac3",
    "bytes": 1052
  }
]
```

<a id="a26"></a>
### A26 — Current PhysX source snapshot and license

- **Primary source:** [Current PhysX source snapshot and license](https://github.com/NVIDIA-Omniverse/PhysX/tree/b97365c6ddb32fda8469bc788ec18024862b0368)
- **Version/date:** Header 5.12.0; recorded date 2026-10-15.
- **Repository pin:** `b97365c6ddb32fda8469bc788ec18024862b0368`.
- **Accessed:** 2026-10-27.
- **Exact location:** physx/include/foundation/PxPhysicsVersion.h;physx/README.md;physx/LICENSE.md
- **Supported claim:** Current version 5.12.0 and Apache-2.0; README describes separate GPU binary download.
- **Limits / what remains unproved:** Source/license inspection only; binary terms and current GPU features not fully audited. Older public-guide BSD statement conflicts with source pin.
- **License / redistribution scope:** Apache-2.0 main code; separately downloaded binary terms not fully reviewed.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

**Recorded inspected files:**

```json
[
  {
    "path": "PhysX/README.md",
    "sha256": "af32e07810117e00790d741ce1ce8a5b775e972e2cacf97b170134f3ba0f52e8",
    "bytes": 3900
  },
  {
    "path": "PhysX/physx/README.md",
    "sha256": "aef21d90e2ab560b5ac2d6b19c9ff8f52e48435c3812487e8f7d35c277a1eb65",
    "bytes": 3100
  },
  {
    "path": "PhysX/physx/include/foundation/PxPhysicsVersion.h",
    "sha256": "219cb2660a64cc3f00382f0bf6baaace34b26bd75b85e9bbfed18594d9a25b0d",
    "bytes": 1310
  },
  {
    "path": "PhysX/physx/LICENSE.md",
    "sha256": "c1b9df1275e769f3dbab000d1e457a2d4b0f28eb5da6c77e48dc37eeba202ed7",
    "bytes": 11359
  }
]
```

<a id="a27"></a>
### A27 — PhysX public latest GPU Simulation documentation

- **Primary source:** [PhysX public latest GPU Simulation documentation](https://nvidia-omniverse.github.io/PhysX/physx/latest/docs/GPURigidBodies.html)
- **Version/date:** Public latest guide built May 18, 2026; not assumed 5.12 parity; recorded date 2026-05-18.
- **Accessed:** 2026-10-27.
- **Exact location:** GPU Memory; GPU Simulation Compatibility; introduction
- **Supported claim:** GPU simulation does not mean GPU scene-query availability; budgets/overflows and CPU feature boundaries.
- **Limits / what remains unproved:** Older than current source pin; any 5.12 behavior requires local verification. No adoption/performance claim.
- **License / redistribution scope:** Documentation copyright; software license A26.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="a28"></a>
### A28 — Macklin et al. — Small Steps in Physics Simulation

- **Primary source:** [Macklin et al. — Small Steps in Physics Simulation](https://matthias-research.github.io/pages/publications/smallsteps.pdf)
- **Version/date:** SCA 2019; DOI 10.1145/3309486.3340247; recorded date 2019-07-26.
- **Accessed:** 2026-10-27.
- **Exact location:** Abstract,§§1–3
- **Supported claim:** Substep versus iteration tradeoff relevant to future time-integrated dynamics.
- **Limits / what remains unproved:** Not a static-fitting proof; no timings applied to Cyrus.
- **License / redistribution scope:** Paper copyright.
- **Evidence / confidence:** Verified public documentation/source; High for stated scope.

<a id="r-sources"></a>
## R — Numerics, measurement, deformation and hardware

<a id="r01"></a>
### R01 — NVIDIA — Floating Point and IEEE 754

- **Primary source:** [NVIDIA — Floating Point and IEEE 754](https://docs.nvidia.com/cuda/floating-point/index.html)
- **Version/date:** Live CUDA floating-point documentation inspected 2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** IEEE 754 formats, fused multiply-add and reproducibility discussion
- **Supported claim:** Precision, FMA and evaluation order affect numerical results; identical mathematics does not guarantee identical rounded answers.
- **Limits / what remains unproved:** Not a geometric error certificate or measured consumer-GPU FP64 throughput.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r02"></a>
### R02 — Microsoft — IDXGIAdapter3::QueryVideoMemoryInfo / DXGI_QUERY_VIDEO_MEMORY_INFO

- **Primary source:** [Microsoft — IDXGIAdapter3::QueryVideoMemoryInfo / DXGI_QUERY_VIDEO_MEMORY_INFO](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_4/nf-dxgi1_4-idxgiadapter3-queryvideomemoryinfo)
- **Version/date:** DXGI 1.4, Windows API documentation; recorded date 2024-02-22.
- **Accessed:** 2026-10-27.
- **Exact location:** QueryVideoMemoryInfo and companion DXGI_QUERY_VIDEO_MEMORY_INFO members Budget and CurrentUsage
- **Supported claim:** Process budgets and current usage must be tracked separately from advertised physical VRAM; exceeding the budget can cause stutter.
- **Limits / what remains unproved:** Budget is dynamic and querying it does not reserve memory. Companion: https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_4/ns-dxgi1_4-dxgi_query_video_memory_info
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r03"></a>
### R03 — Microsoft — Timeout detection and recovery

- **Primary source:** [Microsoft — Timeout detection and recovery](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/timeout-detection-and-recovery)
- **Version/date:** WDDM TDR documentation; recorded date 2025-11-05.
- **Accessed:** 2026-10-27.
- **Exact location:** GPU scheduler/preemption timeout and recovery
- **Supported claim:** Windows uses a default two-second timeout in the documented TDR mechanism and can reset a hung device.
- **Limits / what remains unproved:** This is not an acceptable interactive dispatch target or a guarantee of exactly two seconds for every workload.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r04"></a>
### R04 — Microsoft — TDR registry keys

- **Primary source:** [Microsoft — TDR registry keys](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/tdr-registry-keys)
- **Version/date:** WDDM driver-development guidance; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Testing/debugging use warning and TdrDelay
- **Supported claim:** These controls are for targeted driver testing/debugging; end-user applications should not manipulate them.
- **Limits / what remains unproved:** No proposed production fix depends on disabling or increasing TDR.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r05"></a>
### R05 — Microsoft — Acquiring high-resolution time stamps

- **Primary source:** [Microsoft — Acquiring high-resolution time stamps](https://learn.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps)
- **Version/date:** Windows QueryPerformanceCounter guidance; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** QPC interval timing, frequency and clock-domain discussion
- **Supported claim:** QPC is suitable for high-resolution intervals on a system; use its frequency and a consistent domain.
- **Limits / what remains unproved:** QPC and device-event epochs are not automatically identical; submission time is not completion time.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r06"></a>
### R06 — Intel — PresentMon v2.6.0 release

- **Primary source:** [Intel — PresentMon v2.6.0 release](https://github.com/GameTechDev/PresentMon/releases/tag/v2.6.0)
- **Version/date:** v2.6.0; recorded date 2026-09-21.
- **Repository pin:** `e13fce6acdb55a808fd8318175a56863e532d95f`.
- **Accessed:** 2026-10-27.
- **Exact location:** Release entry and tagged repository commit
- **Supported claim:** Current inspected standalone release provides a version to pin for presentation tracing.
- **Limits / what remains unproved:** No PresentMon binary was installed or executed in this environment.
- **License / redistribution scope:** License text at the pinned path was not independently retrieved in this environment; no PresentMon code or binary is redistributed. Verify the exact release license/notices before redistribution.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r07"></a>
### R07 — Intel — PresentMon console application documentation

- **Primary source:** [Intel — PresentMon console application documentation](https://github.com/GameTechDev/PresentMon/blob/main/README-ConsoleApplication.md)
- **Version/date:** Live main documentation inspected; separately pin release R06; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Command-line flags process_name, output_file, qpc_time, write_display_metadata; latency metrics
- **Supported claim:** Console capture can target 3dsmax.exe and export timestamp/presentation information.
- **Limits / what remains unproved:** The README example binary version is older; verify the installed 2.6.0 help before running. A presented-frame metric does not itself identify the first visible collider-edit result or physical input-to-photon latency. Attempt to retrieve the commit-pinned README through the web reader failed; this record claims the main README only.
- **License / redistribution scope:** Report contains a proposed invocation, no tool binary. Exact release license/notices remain a redistribution check; the attempted pinned license retrieval was unavailable.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r08"></a>
### R08 — NVIDIA — Nsight Systems User Guide

- **Primary source:** [NVIDIA — Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/)
- **Version/date:** Live guide; standalone release notes label 2026.5.1 (R09); separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** CLI profile, trace=cuda/nvtx/dx11/wddm, wddm-memory-trace, NVTX capture-range/end and registered strings, kill options, Unified Memory tracing
- **Supported claim:** CUDA/NVTX/Windows graphics/WDDM traces and memory events can separate execution, transfer, scheduling and migration costs.
- **Limits / what remains unproved:** Proposed command was not executed. Verify Windows privileges, exact installed options and target support. The 2026.3 archive index was reachable, but its guessed UserGuide/index.html URL was not; no inaccessible archive content is claimed.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r09"></a>
### R09 — NVIDIA — Nsight Systems Release Notes

- **Primary source:** [NVIDIA — Nsight Systems Release Notes](https://docs.nvidia.com/nsight-systems/ReleaseNotes/index.html)
- **Version/date:** Live documentation label 2026.5.1; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Release title/version and platform support
- **Supported claim:** The standalone documentation version is distinct from CUDA 13.4 Update 2's bundled Nsight Systems 2026.3.2.476.
- **Limits / what remains unproved:** Exact standalone release date was not independently established; no installed profiler version is asserted.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r10"></a>
### R10 — NVIDIA — Nsight Compute Profiling Guide

- **Primary source:** [NVIDIA — Nsight Compute Profiling Guide](https://docs.nvidia.com/nsight-compute/ProfilingGuide/index.html)
- **Version/date:** Live guide inspected 2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Replay, application/kernel/range replay and memory save/restore overhead
- **Supported claim:** Detailed kernel analysis can replay work and incur overhead; profile throughput and uninstrumented host latency separately.
- **Limits / what remains unproved:** No Nsight Compute capture or GPU kernel timing was executed.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r11"></a>
### R11 — Microsoft — Using GPUView

- **Primary source:** [Microsoft — Using GPUView](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/using-gpuview)
- **Version/date:** Windows Performance Toolkit / ADK guidance; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Log.cmd tracing and GPUView CPU/GPU event views
- **Supported claim:** ETW traces expose CPU/GPU scheduling and presentation-related activity for host-level investigation.
- **Limits / what remains unproved:** Companion main-window documentation: https://learn.microsoft.com/en-us/windows-hardware/drivers/display/gpuview-main-window (2022-06-07). Exact installed ADK and privileges remain local prerequisites; not executed.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r12"></a>
### R12 — Microsoft — Direct3D 11 resource limits

- **Primary source:** [Microsoft — Direct3D 11 resource limits](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-resources-limits)
- **Version/date:** D3D11 feature-level resource limits; recorded date 2020-08-19.
- **Accessed:** 2026-10-27.
- **Exact location:** Constant-buffer element count and resource caps
- **Supported claim:** A 4,096-element constant buffer with 16-byte elements is 64 KiB, so it cannot be treated as an unbounded pose palette.
- **Limits / what remains unproved:** Actual Max shader effect bindings and reserved slots still need testing. Duplicates M32 for the numerical/delivery chapter.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r13"></a>
### R13 — Microsoft — ID3D11DeviceContext::Dispatch

- **Primary source:** [Microsoft — ID3D11DeviceContext::Dispatch](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/nf-d3d11-id3d11devicecontext-dispatch)
- **Version/date:** Direct3D 11 API; recorded date 2024-02-22.
- **Accessed:** 2026-10-27.
- **Exact location:** Thread-group dispatch and limits
- **Supported claim:** Native D3D11 exposes compute dispatch with explicit group dimensions.
- **Limits / what remains unproved:** Native API existence is not permission to submit through Max's context or proof that a retained resource can be consumed.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r14"></a>
### R14 — Microsoft — ID3D11DeviceContext::GetData

- **Primary source:** [Microsoft — ID3D11DeviceContext::GetData](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/nf-d3d11-id3d11devicecontext-getdata)
- **Version/date:** Direct3D 11 API; recorded date 2021-10-13.
- **Accessed:** 2026-10-27.
- **Exact location:** Asynchronous query completion and immediate-context restriction
- **Supported claim:** S_OK and S_FALSE distinguish available from unavailable query data; completion must be established explicitly.
- **Limits / what remains unproved:** This is not an imported CUDA semaphore or a guarantee of supported Max callback polling.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r15"></a>
### R15 — Tero Karras — Maximizing Parallelism in the Construction of BVHs, Octrees, and k-d Trees

- **Primary source:** [Tero Karras — Maximizing Parallelism in the Construction of BVHs, Octrees, and k-d Trees](https://research.nvidia.com/sites/default/files/pubs/2012-06_Maximizing-Parallelism-in/karras2012hpg_paper.pdf)
- **Version/date:** HPG 2012 original paper; recorded date 2012.
- **Accessed:** 2026-10-27.
- **Exact location:** Parallel binary radix tree and hierarchy construction
- **Supported claim:** Morton/radix organization provides a parallel hierarchy-building method suitable for large rebuilds.
- **Limits / what remains unproved:** Does not justify a full rebuild for each sparse Cyrus edit. Historical performance is not used as a current speedup estimate.
- **License / redistribution scope:** Original paper copyright; no software implementation/license inferred.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r16"></a>
### R16 — Scott Le Grand — GPU Gems 3, Chapter 32: Broad-Phase Collision Detection with CUDA

- **Primary source:** [Scott Le Grand — GPU Gems 3, Chapter 32: Broad-Phase Collision Detection with CUDA](https://developer.nvidia.com/gpugems/gpugems3/part-v-physics-simulation/chapter-32-broad-phase-collision-detection-cuda)
- **Version/date:** GPU Gems 3, 2007; recorded date 2007.
- **Accessed:** 2026-10-27.
- **Exact location:** Spatial subdivision, sorting and object-size disparity discussion
- **Supported claim:** Spatial grids and sort/group processing are parallel broad-phase options; cell size and object disparity matter.
- **Limits / what remains unproved:** Historical hardware/results are not Cyrus throughput evidence; hierarchical handling or alternate indexes may be needed.
- **License / redistribution scope:** Chapter copyright; separately audit any copied code.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r17"></a>
### R17 — Wang, Jüttler, Zheng, Liu — Computation of Rotation Minimizing Frames

- **Primary source:** [Wang, Jüttler, Zheng, Liu — Computation of Rotation Minimizing Frames](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/12/Computation-of-rotation-minimizing-frames.pdf)
- **Version/date:** ACM TOG 27(1); DOI 10.1145/1330511.1330513; recorded date 2008-03.
- **Accessed:** 2026-10-27.
- **Exact location:** Double-reflection frame construction and comparison to Frenet frames
- **Supported claim:** Rotation-minimizing transport offers a stable frame construction basis for curves; authored twist must be carried separately.
- **Limits / what remains unproved:** A frame method does not establish binding quality, self-intersection freedom or contact clearance.
- **License / redistribution scope:** Original paper copyright; no third-party source code redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r18"></a>
### R18 — Kavan et al. — Geometric Skinning with Approximate Dual Quaternion Blending

- **Primary source:** [Kavan et al. — Geometric Skinning with Approximate Dual Quaternion Blending](https://users.cs.utah.edu/~ladislav/kavan08geometric/kavan08geometric.html)
- **Version/date:** ACM TOG 27(4), 2008; recorded date 2008.
- **Accessed:** 2026-10-27.
- **Exact location:** Paper and author project page, dual-quaternion blending
- **Supported claim:** Dual-quaternion blending is a useful GPU deformation method for rigid-transform blends.
- **Limits / what remains unproved:** Does not enforce root constraints, guide length or collision, and must not silently replace the existing binding evaluator.
- **License / redistribution scope:** Original paper/project rights; no sample-code license inferred.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r19"></a>
### R19 — Renaldas Zioma — GPU Gems 3, Chapter 6: GPU-Generated Procedural Wind Animations for Trees

- **Primary source:** [Renaldas Zioma — GPU Gems 3, Chapter 6: GPU-Generated Procedural Wind Animations for Trees](https://developer.nvidia.com/gpugems/gpugems3/part-i-geometry/chapter-6-gpu-generated-procedural-wind-animations-trees)
- **Version/date:** GPU Gems 3, 2007; recorded date 2007.
- **Accessed:** 2026-10-27.
- **Exact location:** Hierarchical procedural tree deformation in shaders
- **Supported claim:** Vertex-shader deformation can animate shared vegetation without a full collision solver.
- **Limits / what remains unproved:** Phenomenological wind and shallow hierarchy are not evidence of strict static obstacle contact or Cyrus quality/performance.
- **License / redistribution scope:** Chapter copyright; separately audit any code reuse.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r20"></a>
### R20 — NVIDIA — CUDA GPU compute-capability table

- **Primary source:** [NVIDIA — CUDA GPU compute-capability table](https://developer.nvidia.com/cuda/gpus)
- **Version/date:** Live hardware capability table inspected 2026-10-27; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Turing, Ampere, Ada and Blackwell device rows
- **Supported claim:** Representative graphics generations expose compute capabilities 7.5, 8.6, 8.9 and 12.0 respectively for the cited models.
- **Limits / what remains unproved:** Capability number is not measured throughput, memory availability or a qualified product support floor.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r21"></a>
### R21 — NVIDIA GeForce RTX 3060 family specifications

- **Primary source:** [NVIDIA GeForce RTX 3060 family specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/30-series/rtx-3060-3060ti/)
- **Version/date:** Ampere; RTX 3060 and 3060 Ti; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Official product technical specifications
- **Supported claim:** RTX 3060 has documented 8 GB and 12 GB variants; the exact SKU matters.
- **Limits / what remains unproved:** Advertised capacity is not free VRAM or a Cyrus performance result. No purchase recommendation or special FP64 throughput is inferred.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r22"></a>
### R22 — NVIDIA GeForce RTX 4070 family specifications

- **Primary source:** [NVIDIA GeForce RTX 4070 family specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/40-series/rtx-4070-family/)
- **Version/date:** Ada; RTX 4070 and 4070 Ti SUPER; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Official product technical specifications
- **Supported claim:** RTX 4070 has 12 GB; RTX 4070 Ti SUPER has 16 GB.
- **Limits / what remains unproved:** Advertised capacity is not free VRAM or a Cyrus performance result. No purchase recommendation or special FP64 throughput is inferred.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r23"></a>
### R23 — NVIDIA GeForce RTX 5080 specifications

- **Primary source:** [NVIDIA GeForce RTX 5080 specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5080/)
- **Version/date:** Blackwell RTX 5080; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Official product technical specifications
- **Supported claim:** RTX 5080 is specified with 16 GB GDDR7.
- **Limits / what remains unproved:** Advertised capacity is not free VRAM or a Cyrus performance result. No purchase recommendation or special FP64 throughput is inferred.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r24"></a>
### R24 — NVIDIA GeForce RTX 5090 specifications

- **Primary source:** [NVIDIA GeForce RTX 5090 specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/)
- **Version/date:** Blackwell RTX 5090; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Official product technical specifications
- **Supported claim:** RTX 5090 is specified with 32 GB GDDR7.
- **Limits / what remains unproved:** Advertised capacity is not free VRAM or a Cyrus performance result. No purchase recommendation or special FP64 throughput is inferred.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r25"></a>
### R25 — NVIDIA RTX 6000 Ada specifications

- **Primary source:** [NVIDIA RTX 6000 Ada specifications](https://www.nvidia.com/en-us/products/workstations/rtx-6000/)
- **Version/date:** RTX 6000 Ada Generation; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Official product technical specifications
- **Supported claim:** RTX 6000 Ada is specified with 48 GB memory.
- **Limits / what remains unproved:** Advertised capacity is not free VRAM or a Cyrus performance result. No purchase recommendation or special FP64 throughput is inferred.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

<a id="r26"></a>
### R26 — NVIDIA RTX PRO 6000 Blackwell Workstation specifications

- **Primary source:** [NVIDIA RTX PRO 6000 Blackwell Workstation specifications](https://www.nvidia.com/en-us/products/workstations/professional-desktop-gpus/rtx-pro-6000/)
- **Version/date:** RTX PRO 6000 Blackwell Workstation Edition; separate publication date not independently established.
- **Accessed:** 2026-10-27.
- **Exact location:** Official product technical specifications
- **Supported claim:** The workstation model is specified with 96 GB memory.
- **Limits / what remains unproved:** Advertised capacity is not free VRAM or a Cyrus performance result. No purchase recommendation or special FP64 throughput is inferred.
- **License / redistribution scope:** Vendor documentation; no code or binaries redistributed.
- **Evidence / confidence:** Verified public documentation/source; High for the scoped documented claim; implementation applicability remains untested..

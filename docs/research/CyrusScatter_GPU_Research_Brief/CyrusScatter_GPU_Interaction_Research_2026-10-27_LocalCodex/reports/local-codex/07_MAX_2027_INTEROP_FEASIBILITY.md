# Max 2027 public SDK interoperability audit

**Verdict:** there are useful public entry points. A supported, runtime-validated bridge from compute-produced resources into our retained preview remains an open gate.

## Scope and inspection identity

Read-only inspection used the installed SDK under `build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk`. Header identities are recorded in [the scoped source record](evidence/local_source_identity.json). No Autodesk headers or libraries are redistributed in this package. The production draw path was inspected in `point_display.cpp`, `mesh_display.inc` and `point_publication.inc`.

No Max process was launched, injected into, installed into, or changed by this research. The two GPU executables create their own resources outside Max. Existing 0.87.4.3 Max receipts remain historical CPU qualification.

## Public declarations found

| API/source | Verified declaration or constraint | What it does not establish |
|---|---|---|
| `ID3D11GraphicsWindow` | `GetDevice()`, `GetVertexBuffer(length,FVF)`, `GetIndexBuffer(...)`; interface lifetime `noRelease` | Runtime availability on our Nitrous path, arbitrary retained buffer extraction, permission to alter host state |
| `VertexBufferHandle` | Initialize, Lock/Unlock, CopyFrom, pool/usage/access, hardware realization | No documented raw D3D resource import/extractor was found in the reviewed class |
| `HLSLMaterialHandle` | `SetBufferParameter(name/index, SmartHandle)`; comments request `BufferUsageStatic | BufferUsageTarget` | Which concrete buffer formats/types update reliably in our shader and host configuration |
| `SmartHandle` | Pointer/object-ID helpers are marked internally used | A supported reinterpret-cast into private graphics objects |
| `IVirtualDevice` | Target/UAV-related methods are declared | A public compute `Dispatch` path was not found in this reviewed interface |

Primary references: [ID3D11GraphicsWindow](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d3_d11_graphics_window.html), [VertexBufferHandle member list](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_vertex_buffer_handle-members.html), [HLSLMaterialHandle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_h_l_s_l_material_handle.html).

The inherited `GetPointer()` appearing in a public member list is not enough: its original header labels the helper internal. Treat this as a shipping boundary. Absence of a method in these reviewed interfaces is also not proof that Autodesk has no other supported route; request vendor clarification if a later prototype requires one.

## What the current plugin uses

The inspected retained draw code uses public SDK buffer/material handles and instanced triangle rendering with HLSL shader model 5.0. It does not currently import a CUDA resource, obtain a raw D3D device for compute, or dispatch an OpenCL kernel. GPU drawing already happens, but guide fitting and full posed-geometry preparation remain CPU work.

Changing a shader to read compact poses is therefore a smaller boundary crossing than introducing a second compute runtime that must write the same draw buffers. It still needs a real Max experiment; header presence is not execution.

## Standalone platform sharing results: E

On this RTX 3090, an owned D3D11 device created on a CUDA-matched DXGI adapter supported:

- CUDA registration/map, a kernel writing 1,024 float4 values, unmap, and exact D3D11 staging readback.
- OpenCL `cl_nv_d3d11_sharing` acquisition, kernel write, release, and exact D3D11 staging readback.

Feature level was 11.0. Both checks passed. See [source](prototype/interop_probe.cpp) and [results](prototype/interop_results.json). They demonstrate application-owned sharing only. They do not measure rendering latency, guarantee absence of hidden driver copies, prove device-loss recovery, or qualify an Autodesk resource/callback.

## Four integration routes

### Route A — CPU poses, public shader buffer: preferred first probe

Create an SDK-owned buffer using documented usage/pool/data types, bind it by name with `SetBufferParameter`, and read a few indexed float4 values in a small test shader. Add a per-instance pose index, then compare positions with CPU `posePoint`. Run updates from a host-owned permitted callback. This route does not require taking a raw Max resource into CUDA.

The first probe must prove parameter reflection, element indexing, partial/full updates, device recreation, multi-viewport use, and cleanup. If this fails, stop and resolve the SDK issue before writing a GPU fitter.

### Route B — CUDA compute, compact pose readback

Run numeric fitting in a private compute context/stream, read back only poses/status/masks, and let the host upload SDK-owned buffers. This can avoid unsupported resource import. It adds latency and two transfers, but compact output can be far smaller than full vertices. Measure actual bytes and events. Do not dismiss it based only on the full-vertex readback experiment.

### Route C — compute shares Max-consumed buffers

First query the documented graphics-window interface in a disposable Max 2027 profile and record whether it exists and which adapter/device it returns. Then establish a documented resource creation/import and render-item consumption path. Confirm who owns every COM reference, GPU allocation, context and synchronization point. Registration and unregistration belong to resource lifetime, not every mouse event.

The reviewed `GetVertexBuffer(length,FVF)` declaration should not be interpreted as “extract this `VertexBufferHandle`.” The relation between those paths must be demonstrated. A private object-layout cast is a failed gate, not a fallback.

### Route D — custom drawing on the raw device

Even with `GetDevice`, custom context calls can conflict with Nitrous state caching, command ordering and render callbacks. This route needs explicit supported callback/state rules and a small isolated sample. A second device and a shared texture rendered in another window would not prove integrated scene drawing or correct picking.

## Thread and lifetime constraints

Direct3D 11 device/context thread rules are separate from Max host rules. Microsoft documents that the immediate context must be serialized; the host may impose stricter access/callback requirements. A worker cannot acquire scene nodes or manipulate the Max immediate context merely because a device supports concurrent creation. [D3D11 multithreading](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-render-multi-thread-intro).

Never release the host-owned graphics-window interface as if it were our allocation. Conversely, an API query that explicitly adds a COM reference requires the corresponding release. Resource wrappers must distinguish borrowed host interfaces from owned COM/device objects and SDK handle lifetimes.

## Local compilation caveat

The inspected `id3d11graphicswindow.h` includes legacy `d3dx11.h`. That header was not found in the inspected SDK tooling tree or the standard June 2010 DirectX SDK include location on this machine. No Max adapter-query probe was compiled here. Do not fabricate a replacement header/interface layout to force compilation. The public shader-buffer route may avoid this dependency; otherwise resolve the documented SDK prerequisites before runtime qualification.

## Required evidence before a product commitment

One owned Max 2027 test must show the exact source/native/script identities, public APIs used, adapter identity, buffer ownership diagram, synchronization timeline, two-view redraw, correct bounds/picking/wireframe, teardown/device recreation, and a before/after edit-to-present trace. Until then, **“platform sharing works; Max integration unqualified”** is the accurate statement.

# Retained instanced Mesh preview

2 October 2026. Scatter 0.64 candidate, native engine 0.25, Analyzer unchanged at 0.14. This loop addresses the severe Mesh-mode navigation slowdown reported after the successful Point Cloud and Proxy improvements. It preserves the existing geometry selection and viewport limits, and replaces repeated CPU triangle submission with retained GPU instancing through Autodesk's public SDK.

## What the implementation does

The old Mesh path already cached source triangles and placement transforms. During every redraw it nevertheless visited every triangle of every displayed instance, transformed two edges, calculated the face shade, and submitted the triangle through `GraphicsWindow`. Caching placement calculations did not remove this display cost. One call to `GraphicsWindow::triangle` is **not** evidence of one hardware draw call.

The new path shares an immutable source-local triangle snapshot with the existing fallback cache. Each displayed source group gets three retained vertex streams: positions and the two local triangle edges. A fourth stream contains the exact four matrix rows for each accepted instance. An embedded HLSL shader applies those rows and the existing flat shading formula. A group is submitted with `IVirtualDevice::DrawInstanced`. Camera movement changes the view transform, not the source buffers or placement data.

This is ordinary graphics instancing through Max's supported display interfaces. It is separate from CUDA/OpenCL computation. It requires no additional GPU runtime, external shader file, service, login or new user-facing display mode.

The choice follows Autodesk's `howto/Graphics/GPUParticle` example in both installed SDKs. The higher-level `InstanceDisplayGeometry` and Mesh render-item/decorator APIs were also reviewed. They are useful candidates for a later native material/wireframe display implementation. For this loop, the custom item reuses the existing transient display owner and preserves Cyrus's current two-sided, solid/source-color preview and fixed directional face shading. No claim is made about FStorm's private implementation.

## Geometry and lifecycle contract

The same cache supplies the old and new paths. Accepted row indices, source IDs, source pivot conversion, whole-instance face budgeting, instance limits, transforms, source colors and placeholder markers are preserved. Mesh still shows evaluated **viewport** source geometry, not renderer material/texture shading. No smoothing, UV/material preview, automatic LOD or hidden density reduction was added. Filled preview behavior in a wireframe viewport is retained from the old path.

The native owner is the existing disposable helper. It consumes native shared snapshots, not MAXScript wrappers or live source nodes. The host thread publishes generations outside drawing. The weak controller reference disables a generation on controller deletion/hiding; a cache mismatch disables stale output until publication. Save/open/reset handling, locked helper transforms, nonrenderability, exclusion from Zoom Extents, and controller/CS Edit picking are inherited from the Point Cloud integration. No scene schema change was required.

Mesh item bounds cover the transformed source boxes. Nitrous can cull a whole source-group item. This implementation does **not** build spatial tiles or cull individual plants inside a group. Off-screen items need not have GPU buffers yet: the fallback decision uses item publication, rather than requiring every culled item to have been realized. Visible items are realized by Nitrous before drawing.

## Memory and fallback

For a source group with `F` local triangles and `I` accepted instances, the explicit graphics-buffer payload is `108*F + 48*I` bytes. It does not scale as `108*F*I`. Sources are shared within each cached layer/source group; different layers/controllers do not yet share a global GPU source pool.

Mesh payload reservations are bounded at **512 MiB per generation and 1 GiB per process**. Point payload caps remain 64/128 MiB independently. These are payload accounting limits, **not measured total VRAM or RAM**. The source snapshot, temporary upload stream, SDK system copies, driver overhead and outstanding older generations also consume memory. The SDK keeps system copies for resource management. Group count remains bounded at 1,024 per generation.

Unsupported graphics feature level, shader/resource failure or a reservation rejection disables retained drawing for that generation. The existing geometry cache remains available to the legacy path; a visible fallback status is reported. Refresh replaces the cache and retries. First use or an edit may still take time to extract meshes, prepare streams and upload data. A device-loss simulation and second graphics vendor remain unqualified.

## Try the candidate

Use the matching package under `dist/retained-mesh-0.64/`: run the MZP through **Scripting > Run Script**, then restart Max. Use a saved scene copy and select **Viewport and Render → Mesh**. Start with your existing limits so the before/after comparison displays the same content. Max 2027 runtime evidence and Max 2026 build-only status are recorded in [RESULTS.md](RESULTS.md).

The session-only Listener comparison is `CyrusRetainedMeshDrawing false` for the original triangle path and `CyrusRetainedMeshDrawing true` for retained instancing. It does not alter placement generation. `CyrusRetainedPointDrawing` still controls Point Cloud separately. When retained drawing is enabled, `CyrusPointOwner controller`, `cyrusRetainedStats owner`, and `cyrusRetainedMeshStats owner` expose diagnostics.

The seven Mesh statistics are displayed triangles, mesh instances, source triangles with accepted instances, generation payload reservation, process reservation, generation cap and process cap. Existing point statistic indices stay stable; its upload/draw/failure counters now include both native item types. Issued draws and explicit uploads are not GPU completion or presented-frame measurements.

## Evidence and further work

See [RESULTS.md](RESULTS.md) for accepted comparisons, image checks, lifecycle coverage and qualification gaps. Reproduction scripts are in [the private harness](../../tools/performance/mesh_integration/README.md). They are not installer contents and must not run in the artist's session.

The next choices should follow measurements: native materials if artists need them; spatial groups if large invisible regions consume GPU time; source sharing across layers if memory duplicates matter; progressive Point Cloud detail for landscape navigation. The 5,000-node control also exposed a separate investigation target: the redraw callback enumerates all scene objects to find controllers. A cached controller registry could reduce that cost, but its creation/merge/delete lifecycle needs its own measured change.

The 0.63 Point Cloud report and older research remain historical evidence. Licensing, subscriptions, MCP, placement algorithms and renderer transport were not implemented or redesigned in this loop. Earlier licensing codebase hashes/declaration counts are snapshots and must be refreshed before licensing implementation.

## Official references checked

- [Autodesk plug-in display interfaces](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/plug-in_display_interface.html): prepare common data and attach persistent render items.
- [Autodesk render items and decorators](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/about_renderitem.html): alternatives for reusing Mesh render items and overriding transforms/materials.
- [Autodesk IVirtualDevice](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_virtual_device.html): supported draw calls and graphics state access. Its `SetInstanceCount` note is stale relative to the shipped headers; no such method exists there.
- [Autodesk instance stream layout](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/struct_max_s_d_k_1_1_graphics_1_1_material_required_stream_element.html): `SetIsInstanceStream`, explicit offsets, and the requirement that instance data use the last vertex buffer. Verified against the shipped `GPUParticle.cpp` sample, not just the stale note above.
- [Autodesk HLSL material handle](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_h_l_s_l_material_handle.html): embedded shader initialization and parameters.
- [Autodesk InstanceDisplayGeometry](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_display_geometry.html): higher-level viewport instancing alternative, reviewed but not implemented here.
- [Microsoft DrawInstanced](https://learn.microsoft.com/en-us/windows/win32/api/d3d11/nf-d3d11-id3d11devicecontext-drawinstanced): instancing reuses geometry with per-instance data. Cyrus calls Autodesk's wrapper, not a raw Direct3D device.

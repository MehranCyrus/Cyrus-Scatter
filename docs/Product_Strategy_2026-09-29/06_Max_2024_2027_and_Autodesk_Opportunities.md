# 06 — Max compatibility and Autodesk opportunities

**Required product range: Max 2024–2027. Verified local host evidence: Max 2027.1 only. Research checked 2026-09-29.**

## Compatibility is a matrix

Record exact Max update/build, SDK, compiler/runtime, renderer build, OS, package and scene schema. “Supports 2027” must not hide a dependency on 2027.2. Use per-year native binaries and explicit package bounds; do not load the 2027 module into earlier hosts.

| Host | Build guidance | Current Cyrus evidence / next step |
|---|---|---|
| 2024 | Autodesk lists VS 2019 16.10.4, v142, Windows SDK 10.0.19041.0; C++17 | Required port; no local Cyrus build/runtime qualification |
| 2025 | VS 2022/v143; resolve Windows SDK discrepancy against installed SDK props | Required port; no local Cyrus qualification |
| 2026 | VS 2022/v143, current shared configuration uses C++17 | Source configuration exists; no build/runtime result from this review |
| 2027.1 baseline | Local SDK props: v143 14.38.33130, Windows SDK 10.0.19041.0, C++20 | Existing build + batch smoke; UI/render/farm tests pending |
| 2027.2 opportunity | Separately verify update SDK/API availability and runtime | Vendor-documented features; not installed or tested by this review |

Sources: [2024 SDK changes](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/what_s_new/whats_new_3dsmax_2024_sdk.html), [2025 requirements](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html), [2026 requirements](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html), [2027 Autodesk setup article](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/).

The 2025 page lists Windows SDK 10.0.22621.0; a historical row on the 2026 page differs. Do not silently choose a toolchain from that conflict. The local 2027 SDK props were inspected and corroborate the already-used compiler components. A newer IDE does not authorize changing the compiler ABI/toolset.

## What 2027 changes for Cyrus

Autodesk lists C++20, Qt 6.8, .NET Core 10, new Field Helper functionality, startup/environment improvements and DirectX 9 removal. These require qualification of native builds, WinForms timers, generated UI/callbacks and display behavior. They do not automatically accelerate Cyrus code. [Max 2027 What's New](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/GUID-7CC2F041-F797-4DB9-B2F9-326AAB994F37.html)

Keep the existing UI architecture for the next milestone. A Qt migration must justify its cross-version adapter and maintenance cost through measured UX limitations. Test UI scale, event disposal and repeated object selection across the .NET/runtime changes.

## Opportunity A — Field Helper

Autodesk documents spatial field shapes, falloff and typed outputs associated with selection/controller workflows. [Field Helper](https://help.autodesk.com/cloudhelp/2027/ENU/3DSMax-What-s-New/files/GUID-5E3B9F92-1654-4561-9E65-BD993B49B905.htm)

**Proposed experiment:** an artist picks a field to modulate one Cyrus density/scale control. First establish a supported sampling interface and evaluation context. Define coordinate space, value range, animation, dependencies and sample cost. If arbitrary point sampling is not exposed safely, use a documented bake path or defer.

For earlier hosts, retain portable Cyrus masks. A cached sampled field may support exchange only if explicitly baked with bounds/resolution/time metadata; it is not automatically equivalent to the live field. Never silently drop the influence on downgrade.

## Opportunity B — 2027.2 Points and Point Instance

Autodesk's 2027.2 pages introduce a Points object family and Point Instance modifier for render-time instancing. The documentation explicitly excludes Point Cloud objects and particle data as supported Point Instance inputs. Cyrus's current point cache/PFlow data therefore cannot be assumed to connect directly. [Points introduction](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/whats_new_in_3ds_max_2027.2/GUID-22B0EA0E-B000-4B5E-8516-8510B62A8001.html), [True Instancing](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/whats_new_in_3ds_max_2027.2/GUID-223DCC38-B950-4EF4-A5CF-FAEB2BA3B6AB.html)

**Proposed experiment:** represent an already-computed Cyrus result through a supported native Points/instance adapter. Preserve Cyrus as the authoring/placement authority. Verify per-instance source selection, full transform mapping, negative/nonuniform scale, material assignment, identity and motion samples before considering adoption.

Autodesk specifically documents use of Point Instance with MAXtoA 5.9.3.0. This does not prove Corona or V-Ray support. [Arnold 5.9.3 in Max 2027.2](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/whats_new_in_3ds_max_2027.2/GUID-BE5A5907-54D4-455C-9B0F-AD06B52FB711.html)

Make the prototype disposable, with exact transform and image comparisons, memory/preparation timings, abort/save cleanup, and a baseline transport fallback. Ship no dependency on it until the intended combinations pass. Do not update the user's working host as part of research.

## Opportunity C — Retained viewport data

Current preview still submits geometry through GraphicsWindow. Autodesk warns that this interface has particular sequencing and internal-thread behavior. It should not be treated as a generic graphics API. [GraphicsWindow reference](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_graphics_window.html)

The local SDK has Graphics display interfaces. If submission dominates, investigate supported retained render items using matching SDK samples. Prove bounds, picking, color management, transforms, device loss and teardown. Do not equate a compute kernel with a retained display implementation.

## Opportunity D — USD and pipeline exchange

Treat USD as an interchange project with its own schema/material/asset contract. A documented USD update in Max is not automatic export support for Cyrus's scripted object. A first prototype should export explicit evaluated instances and prototypes, with a clear snapshot limitation. See [08](08_Renderers_Assets_and_Studio_Pipelines.md).

## Deployment and environment

Autodesk's package specification supports component-specific runtime ranges, including update/build bounds. Use this to isolate host-specific modules and optional newer capabilities. Match startup ordering to documented component types and test upgrade from the existing MZP registrations. [Package format](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/writing_plug-ins/plugin_package/packagexml_format.html)

Use documented private startup/plugin configurations for tests. Keep Safe Scene Script Execution enabled in qualification; the new SDK exposes security state, but Cyrus should not change global security to make itself work. [Security interface](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_i_scene_script_security_manager.html)

## Evidence limits

The 2027 developer requirement URL and several deep-linked 2027.2 pages were inaccessible through the research tool; the update overview and feature pages were accessible. The linked 2027.2 release-notes route returned Page Not Found. Therefore this document establishes a worthwhile experiment, not an API implementation specification. Acquire and inspect the matching SDK/sample/runtime before coding that adapter.

Maintain the 2024–2027 commitment through explicit qualification, not silent feature deletion. A newer optional workflow must have a documented bake/export alternative or an honest unsupported-on-older-host message.

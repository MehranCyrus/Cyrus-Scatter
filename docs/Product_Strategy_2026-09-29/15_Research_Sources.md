# 15 — Research sources and evidence limits

**Checked 2026-09-29.** Primary sources only are used for external technical claims. Product recommendations and architecture inferences are Cyrus proposals. A vendor capability is not a Cyrus integration test. Search crawl dates are not release dates.

## Autodesk

| ID | Source | Supported finding / limitation |
|---|---|---|
| A01 | [Max 2027 What's New](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/GUID-7CC2F041-F797-4DB9-B2F9-326AAB994F37.html) | Foundation/runtime changes, Field Helper, startup changes, DirectX 9 removal. Does not prove Cyrus gains |
| A02 | [2027 SDK setup article](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/) | Autodesk developer article dated July 31, 2026; compiler components differ from IDE version. Corroborated with local SDK props |
| A03 | [2027 SDK version macros](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/group___version_macros.html) | 2027 API versions identify a binary break from 2026; reinforces separate targets |
| A04 | [Max 2024 SDK changes](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/what_s_new/whats_new_3dsmax_2024_sdk.html) | Compiler/C++ baseline, SDK break, color-management and mesh API context |
| A05 | [Max 2025 SDK requirements](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html) | Host-specific prerequisites; Windows SDK value differs from later historical table |
| A06 | [Max 2026 SDK requirements](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html) | Compiler/runtime baseline; does not qualify Cyrus 2026 |
| A07 | [Max 2027 system requirements](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-3ds-Max-2027.html) | Host hardware/OS basis. Cyrus 32 GB floor is the user's additional requirement |
| A08 | [Thread safety](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html) | SDK/reference/node evaluation concurrency restrictions; API-specific exceptions still need validation |
| A09 | [GraphicsWindow](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_graphics_window.html) | Sequencing and internal-thread caveats; not a generic GPU API |
| A10 | [Application Plug-in Package format](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/writing_plug-ins/plugin_package/packagexml_format.html) | Component ordering and explicit host/update bounds; migrate old registrations carefully |
| A11 | [New Field Helper](https://help.autodesk.com/cloudhelp/2027/ENU/3DSMax-What-s-New/files/GUID-5E3B9F92-1654-4561-9E65-BD993B49B905.htm) | Field shapes, outputs and falloff; arbitrary Cyrus sampling API remains unproven |
| A12 | [Max 2027.2 overview](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/GUID-D11D1F34-C9FF-4981-AAE3-5A969986FCF4.html) | Update feature overview accessible; local runtime not qualified |
| A13 | [New Points object type](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/whats_new_in_3ds_max_2027.2/GUID-22B0EA0E-B000-4B5E-8516-8510B62A8001.html) | New object/modifier family; distinction from Point Cloud/particle input |
| A14 | [True Instancing](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/whats_new_in_3ds_max_2027.2/GUID-223DCC38-B950-4EF4-A5CF-FAEB2BA3B6AB.html) | Candidate transport direction; public Cyrus adapter mapping still an experiment |
| A15 | [MAXtoA 5.9.3](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-WhatsNew/files/whats_new_in_3ds_max_2027.2/GUID-BE5A5907-54D4-455C-9B0F-AD06B52FB711.html) | Explicit Arnold Point Instance support; no conclusion about Chaos renderers |
| A16 | [Scene script security interface](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_i_scene_script_security_manager.html) | Security-state inspection exists; no reason to disable scene protections |
| A17 | [2027 command-line options](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-Basics/files/3ds_max_interface_overview/start_3ds_max_from_the_command_line/GUID-1A97CFEC-60A3-4221-B9C3-5C808E2AED35.html) | Private INI/plugin and silent/security options for controlled test setup |
| A18 | [2027 environment variables](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-Basics/files/3ds_max_interface_overview/start_3ds_max_from_the_command_line/GUID-D7D373FD-CA78-4986-AB3D-B1E25F2A37CC.html) | Version/startup/environment configuration; not trustworthy license authority |

## Chaos and competitive context

| ID | Source | Supported finding / limitation |
|---|---|---|
| C01 | [Chaos Scatter advanced features for Corona/Max](https://support.chaos.com/hc/en-us/articles/4953359913617-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Advanced-Features) | Existing competitor workflow breadth; supports the need for task-level differentiation |
| C02 | [V-Ray 7 Update 3 announcement](https://forums.chaos.com/t/v-ray-7-update-3-available-for-download/124628) | Staff announcement April 3, 2026 identifies 7.30.02 and Max 2027 support; not a claim that this is the latest available build |
| C03 | [Corona 14 Update 1 Hotfix 2 announcement](https://forums.chaos.com/t/chaos-corona-14-update-1-hotfix-2-released-for-3ds-max/160584) | Staff announcement April 23, 2026 identifies Max 2027 compatibility; not Cyrus qualification |
| C04 | [Chaos Scatter documentation landing page](https://documentation.chaos.com/space/VMAX/113586948/Chaos%20Scatter) | Discovered through official search; direct open returned no readable body. Detailed claims use C01 instead |
| C05 | [ForestPack official product page](https://www.itoosoft.com/forestpack) | Renderer/library/display ecosystem as a benchmark; vendor marketing is not comparative testing |

Older `docs.chaos.com` results often describe 2025-era pages. Direct VRayInstancer and Corona Proxy URLs redirected to broad documentation roots with no readable article. No undocumented native renderer API or current proxy compatibility claim was inferred from those redirects. Maya and Cinema 4D feature pages were excluded from Max-specific conclusions.

## Runtime, deployment and interchange

| ID | Source | Supported finding / limitation |
|---|---|---|
| T01 | [oneTBB task_arena](https://oneapi-spec.uxlfoundation.org/specifications/oneapi/latest/elements/onetbb/source/task_scheduler/task_arena/task_arena_cls) | Bounded scheduling concept; page labels itself provisional. Pin a tested stable implementation separately |
| T02 | [OpenCL device queries](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/clGetDeviceInfo.html) | Probe numeric/device/memory capabilities, including optional FP64 |
| T03 | [OpenCL vector data types](https://registry.khronos.org/OpenCL/specs/unified/refpages/man/html/vectorDataTypes.html) | Explicit device data layout; host layout must be validated |
| T04 | [OpenUSD PointInstancer](https://openusd.org/release/api/class_usd_geom_point_instancer.html) | Prototype/instance data model; not a Cyrus export or material translator |
| T05 | [Windows DLL security](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-security) | Deliberate dependency search/loading practices |
| T06 | [SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool) | Signing, timestamping and verification tools; integrity hashes alone do not authenticate the publisher |
| T07 | [Deadline 10 maintenance FAQ](https://docs.thinkboxsoftware.com/products/deadline/10.4/1_User%20Manual/manual/maintenance-mode-faq.html) | Maintenance-mode transition; farm plan should be driven by actual studio launchers |

The full OpenCL HTML specification URLs returned retrieval errors on direct open; official reference-page/search results remained available. This review makes no dependency on a claimed newest OpenCL version. A compatible feature subset and actual device probes govern the experiment.

## Local evidence

- [Input inventory](evidence/review_input_inventory.json): 198 files, filesystem-only raw hashes; generated strategy output excluded.
- [Generator check](evidence/generator_check.json): Node v22.14.0; two exact reproductions; production output untouched.
- [Native rerun](evidence/native_test_rerun.json): seven existing Release test executables, exit codes and output; not a new build or full host test.
- [Package check](evidence/package_check.json): delivered MZP hash/integrity verification, not publisher-signature verification.
- [Prior runtime evidence](evidence/prior_runtime_evidence.json): copies of 2026-09-28 logs and smoke script, captured to prevent later build-log overwrites.

The installed 2027 SDK's `3dsmax.common.tools.settings.props`, `3dsmax.general.project.settings.common.props` and `3dsmax.general.project.settings.props` confirm C++20, v143, Windows SDK 10.0.19041.0 and tools 14.38.33130. SDK presence/toolchain facts are local build evidence, not redistributable SDK content.

## Research limits and refresh triggers

The direct 2027 SDK requirement/developer What's New URLs were unavailable, and the 2027.2 release-notes route returned Page Not Found. Deep Point Instance help links also failed retrieval. Acquire the appropriate official SDK/runtime before treating the overview as sufficient to implement an adapter.

No provider pricing, legal entitlement, payment availability or current repository visibility was revalidated. Existing vendor-selection documents remain dated hypotheses. Recheck relevant sources at each host port, renderer qualification, provider decision and public release. Preserve exact tested binaries and versions even when online documentation later changes.

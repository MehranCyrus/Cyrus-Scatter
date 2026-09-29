# 11 — Platforms and minimum requirements

**User requirements:** support Max 2024 through the current release and 32 GB RAM or more. As of 2026-09-28 this means **2024, 2025, 2026 and 2027**. The current implementation targets 2026; all runtime support remains to be qualified.

## Proposed product requirements

| Component | Base CPU operation | Optional acceleration / recommendation |
|---|---|---|
| OS | Windows 11 x64 is the common qualification platform for all four Max versions | Older-host Windows 10 support is a separate test/support decision; do not promise it across the full range |
| CPU | Intel or AMD x64 multicore CPU supporting SSE4.2 and the chosen Max/renderer requirements | More cores may help independent work; qualify practical 4-core and 6/8-core tiers where available before publishing throughput claims |
| RAM | **32 GB minimum** for the defined tested scene envelope | 64 GB+ is a capacity recommendation for larger scenes, not a prerequisite for base operation |
| Graphics | A GPU/driver suitable for the selected Max version's viewport | Compute features are optional; CPU execution must work without OpenCL |
| GPU compute | None required | G01 capability probe and G04 qualification determine supported devices; initial prototype targets a compatible OpenCL 1.2 subset |
| VRAM | Follow the Max viewport/renderer requirements; no additional numeric Cyrus minimum is established yet | Enough available space for bounded plugin buffers plus viewport/render workloads; reject/fallback when allocation cannot fit |
| Storage | Space for Max, renderers, assets, output, plugin and diagnostics | SSD recommended for scene/cache work; publish plugin package footprint after packaging, not a guessed GB requirement |
| Runtime dependencies | Version-matched Cyrus binaries and required compiler runtime | Packaged threading dependency if enabled; optional OpenCL loader/device driver only for compute mode |

Autodesk's current requirements specify x64 multicore/SSE4.2 and Windows 11 for Max 2027. The 32 GB floor is Cyrus's user-requested target, not Autodesk's published minimum. [Autodesk system requirements](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-3ds-Max-2027.html)

Do not require CUDA, RTX, AVX2 or a fixed GPU brand in the baseline build. Renderer-specific hardware requirements still apply when using that renderer. CPU fallback means no compute GPU dependency; it does not remove Max's normal graphics requirements.

## Build matrix — F01/F02

Build separate Max-native modules for each row with its matching SDK. Keep the pure core source portable; compile/link it consistently with the corresponding host binary's runtime and configuration. Never assume one `.dlx`/`.dlm` serves all years.

| Host | SDK | Compiler guidance | C++ / Windows SDK | Status |
|---|---|---|---|---|
| 2024 | 2024 | VS 2019 16.10.4 / v142 | C++17; Windows SDK 10.0.19041.0 | To provision/build/test |
| 2025 | 2025 | VS 2022 17.8.3 / v143 | C++17 core baseline; release page lists Windows SDK 10.0.22621.0; resolve source discrepancy below | To provision/build/test |
| 2026 | 2026 | VS 2022 17.8.3 / v143 | C++17 current project; Windows SDK 10.0.19041.0 | Current source target; no successful build here |
| 2027 | 2027 | Provisional: VS 2022 17.14.13 host IDE, v143 **14.38** tools | Provisional C++20 host compilation; Windows SDK 10.0.19041.0 | Confirm installed SDK samples before pinning |

Sources: [2024 SDK changes](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/what_s_new/whats_new_3dsmax_2024_sdk.html), [2025 requirements](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html), [2026 requirements](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html), [2027 Autodesk setup guidance](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/).

The 2025 Windows SDK values differ across Autodesk pages, and the 2027 article's linked requirements page was unavailable. Treat installed SDK samples/release notes as a setup gate and record the resolved versions. IDE version, compiler toolset minor version and Windows SDK are separate choices. Verify oneTBB/compiler compatibility for both v142 and v143 builds rather than choosing a dependency that silently drops 2024.

End users do not need CMake, Node, Python, Max SDKs or a compiler to run a packaged build. Developers need the relevant SDK/toolchain; Node is needed to regenerate the UI. No direct Qt rewrite is part of this roadmap.

## Required source and packaging work

1. Parameterize the target host year/SDK at configure time in both CMake projects. Validate header year against the selected target, rather than removing the guard entirely.
2. Compile `AminScatter`, `CyrusScatterEdit` and `CyrusSurfaceAnalyzer` against the corresponding headers/import libraries. Audit API signatures and exports; add small version adapters only where necessary.
3. Audit generated MAXScript/WinForms/runtime behavior in each Max release, including startup, callbacks, PFlow operators and UI events. Successful native compilation does not prove script compatibility.
4. Replace hardcoded 2026 checks, path registration keys, uninstall keys and user messages in both installers with version-matched package metadata. Each installation must register only its own host's binaries.
5. Produce version-separated artifacts, dependency manifests and checksums. Test missing dependency, wrong-host package, upgrade and uninstall paths. Never overwrite Max's bundled runtime libraries.
6. Preserve scene class IDs, storage and parameter schema. Version adapters must not create separate incompatible scatter scene types.
7. Establish a per-host baseline before performance patches. Retest saves/edits across supported scene transfer paths; document host-native `.max` backward-opening limitations instead of promising universal file interchange.

## 32 GB memory qualification

Measure the complete Max process and intended renderer, not only native arrays. Record baseline scene memory, active-compute peak, retained-cache size, undo growth, GPU staging, renderer translation and post-cleanup memory.

Use an initial **2 GiB transient plugin scratch ceiling** for benchmark experiments, with bounded eviction and lower dynamic limits when available memory is tight. This is a proposed engineering budget to validate, not a guarantee that any scene fits in 32 GB. Do not count persistent scene/renderer data as free headroom. Old and new caches may coexist during publication.

Sweep workload until latency/paging or allocation limits become unacceptable, then publish the largest *tested fixture envelope* with its geometry, source complexity, boundaries and display mode. An instance count alone is not a memory specification. Test graceful resource errors/fallback while preserving the last valid state.

## Qualification tiers

- **Required:** all four Max versions; 32 GB RAM; Intel and AMD CPU coverage; compute unavailable; low and high display budgets; intended renderer combinations.
- **Recommended:** 64 GB+ large-scene system; higher-core machine; active renderer contention; mixed CPU capability levels to verify dispatch fallback.
- **Optional GPU:** named NVIDIA/AMD/Intel devices and driver/runtime versions actually tested. Broader GPU support remains experimental until coverage exists.

Only mark a row supported after the tests in [08](08_Manual_Test_Runbook.md) and the applicable gates in [07](07_Implementation_Backlog_and_Gates.md) pass. Future Max releases add another row, matching SDK build and runtime tests.

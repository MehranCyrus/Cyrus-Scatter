# Cyrus Scatter

Native C++ and MAXScript sources for Cyrus Scatter and Cyrus Surface Analyzer for Autodesk 3ds Max. This repository backs up the code, build/test tools, documentation and curated research evidence. SDKs, compiled plugins, installers, scene assets and temporary previews stay local.

## Current state

**Release direction: Cyrus Scatter 0.7 pre-release.** Version 1.0 is reserved for publication readiness. The source/UI currently carries the historical development label 1.2.3; the next implementation/build will align it to 0.7.0 while keeping the latest functionality. See the [versioning decision and build checklist](docs/Release_Versioning.md).

- **Scatter 1.2.3 / Analyzer 0.14:** [classic flowing layout](docs/Classic_Layout_2026-10-04/README.md) with [wheel and background-drag scrolling](docs/Classic_Layout_2026-10-04/SCROLLING_1.2.3.md). Layer Manager is followed by named layers that each own their full settings; named paint sets share their parent's budget, areas, transforms, collision and cleanup. Start with the [artist guide](docs/Classic_Layout_2026-10-04/ARTIST_GUIDE.md), [1.2 implementation report](docs/Layers_First_2026-10-03/REPORT.md) and [qualification checklist](docs/Layers_First_2026-10-03/CHECKLIST.md). Retained display, Reset, Edit and legacy scene policy remain. Brush-constrained Relax remains paused.
- **Measured integration:** the [Mesh results](docs/Retained_Mesh_Preview_2026-10-02/RESULTS.md) cover visible foliage, an equivalent native Max control, lifecycle and bounded memory fallback. Timings distinguish camera/redraw steps from presented FPS. The [0.63 Point Cloud results](docs/Retained_Point_Preview_2026-10-02/RESULTS.md) remain historical evidence.
- **Planting follow-up:** the [1.0.1 diagnosis](docs/Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_REVIEW.md) and [updated implementation tracker](docs/Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_IMPLEMENTATION.md) link the reproduced failures to the 1.1 changes and remaining limits. Adaptive point detail remains a separate [performance track](docs/Heavy_Scene_Viewport_2026-10-02/ROADMAP.md).
- **Procedural Brush:** saved per-layer Paint/Erase histories, curved receiving meshes, Fill/Empty, Undo, stable candidates and CS Edit integration are in the [v1 report](docs/Cyrus_Scatter_V1_2026-10-03/REPORT.md). The earlier [prototype report](docs/Brush_Tool_2026-10-02/IMPLEMENTATION_2026-10-03.md) remains historical evidence.
- **Local MCP 1.1:** nine tools, typed plan 2.0 settings, include/exclude regions, pair spacing, preview controls, effective configuration and versioned actual-result exports. See [CyrusMCP](CyrusMCP/README.md) and the [control/capability map](docs/Layers_First_2026-10-03/CAPABILITIES.md). Brush-history automation and ML remain future work.
- **Artist style learning — research:** the [4 October design guide](docs/Artist_Style_ML_2026-10-04/README.md) defines a separate companion, personal style profiles, learning from authored planting patches, optional preference models/LoRA, and a staged implementation plan. It includes a current source audit and checked synthetic plan examples; no ML inference or training has been implemented.
- **Next procedural work:** [implementation guide and roadmap](docs/Procedural_Evaluation_2026-10-04/README.md) for independent self/set/layer collision, adjustable instance radii, background fill, bounded replenishment, cache dependencies and qualification. Artist/renderer/Max 2026 testing, semantic zones, density-map exchange and bounded MCP expansion remain in scope of their linked plans. Adaptive point detail remains a separate measured performance track.

Max 2026 and 2027 SDK builds exist; the recorded interactive retained-display experiment ran in Max 2027. SDK compilation is not Max 2026 runtime qualification.

## Repository layout

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Scatter native engine, generated MAXScript, authoritative UI generator, installer templates and native tests |
| `CyrusSurfaceAnalyzer/` | Analyzer native engine, script, installer templates and tests |
| `cmake/` | Shared Autodesk SDK configuration |
| `tools/` | Build/package tools, regression fixtures, diagnostics and performance experiments |
| `docs/` | [Documentation index](docs/README.md), current findings, plans and dated evidence |

The `AminScatter` internal class/native filename is retained for existing scene and Edit linkage compatibility. Public creation and installation use Cyrus names. Generate `AminScatter/scripts/AminScatterObject.ms` from `AminScatter/tools/ui/generate.cjs` with `AminScatter` as the working directory; do not treat the generated file as the only source. See [v1 developer qualification](tools/v1/README.md).

## Build and verification

See [Max 2027 installation / rebuild](docs/Max_2027_Installation.md#rebuild-for-developers) for the pinned toolchain and commands. The build tool regenerates the script, builds with the matching SDK, runs native suites and creates version-specific packages:

```powershell
python tools/build_max.py --max-year 2027 --sdk-root "<path-to-the-2027-maxsdk>"
```

Use `--max-year 2026` with the matching 2026 SDK for that target. Host tests require the appropriate installed Max application. The [private point probe](tools/performance/native_point_probe/README.md) has separate build, launch and cleanup instructions; it is excluded from product packaging.

## Local workspace

| Ignored path | What stays here |
| --- | --- |
| `build/` | SDK/toolchain downloads, compiled outputs, isolated Max configurations and raw experiment runs |
| `dist/` | Generated installers and package checksums |
| `Test Scene/` | Original artist scenes, renderer proxies and textures; kept at the existing path to preserve asset references |
| `_local/handoffs/` | Prepared review packages, including the boss's Max 2026 folder |
| `_local/archives/` | Loose project ZIP backups |
| `_local/scratch/` | Temporary document-rendering images and other disposable working files |
| `_local/maintenance/` | Cleanup move inventory and pre-cleanup working-state backup |

These local files are **not included in the Git backup**. The [workspace organization guide](docs/Workspace_Organization.md) records the moved paths. No artist assets or prior measurements were deleted during the October 2 cleanup. Small, deliberately selected CSV/JSON records, screenshots, exact recipes and one frozen source archive remain with the reports that rely on them.

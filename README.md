# Cyrus Scatter

Native C++ and MAXScript sources for Cyrus Scatter and Cyrus Surface Analyzer for Autodesk 3ds Max. This repository backs up the code, build/test tools, documentation and curated research evidence. SDKs, compiled plugins, installers, scene assets and temporary previews stay local.

## Current state

- **Scatter 1.0.1 / Analyzer 0.14:** current foundation. Standard native Max rollouts replace the nested layer UI; layers have cached statistics, separate viewport visibility and integrated editable procedural Brush. Start with the [v1 guide and qualification](docs/Cyrus_Scatter_V1_2026-10-03/README.md). The [1.0.1 follow-up](docs/Brush_Relax_Reset_2026-10-03/REPORT.md) adds native randomization resets and pauses unsupported Relax while painted density is active. Retained Mesh, Point Cloud, CPU and Proxy improvements remain.
- **Measured integration:** the [Mesh results](docs/Retained_Mesh_Preview_2026-10-02/RESULTS.md) cover visible foliage, an equivalent native Max control, lifecycle and bounded memory fallback. Timings distinguish camera/redraw steps from presented FPS. The [0.63 Point Cloud results](docs/Retained_Point_Preview_2026-10-02/RESULTS.md) remain historical evidence.
- **Next implementation:** simplify shared-surface plant groups and correct Brush preview feedback and collision ordering. The [fresh diagnosis](docs/Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_REVIEW.md) reproduces independent coverage dots, pre-mask spacing and intermediate blockers in installed 1.0.1; the [implementation plan](docs/Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_IMPLEMENTATION.md) defines the next gates. Adaptive point detail remains a separate [performance track](docs/Heavy_Scene_Viewport_2026-10-02/ROADMAP.md).
- **Procedural Brush:** saved per-layer Paint/Erase histories, curved receiving meshes, Fill/Empty, Undo, stable candidates and CS Edit integration are in the [v1 report](docs/Cyrus_Scatter_V1_2026-10-03/REPORT.md). The earlier [prototype report](docs/Brush_Tool_2026-10-02/IMPLEMENTATION_2026-10-03.md) remains historical evidence.
- **Local MCP 1.0:** source, offline installer and seven automation tools are in [CyrusMCP](CyrusMCP/README.md), with bounded Max 2027 qualification in the [report](docs/MCP_Implementation_2026-10-03/REPORT.md).
- **Next work:** artist/renderer/Max 2026 testing, unified semantic zones, density-map exchange and bounded MCP access to the new inputs. Follow the [v1 roadmap](docs/Cyrus_Scatter_V1_2026-10-03/ROADMAP.md) and the [artist-zone contracts](docs/Artist_Zones_Integration_2026-10-03/README.md). Adaptive point detail remains a separate measured performance track.

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

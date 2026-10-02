# Cyrus Scatter

Native C++ and MAXScript sources for Cyrus Scatter and Cyrus Surface Analyzer for Autodesk 3ds Max. This repository backs up the code, build/test tools, documentation and curated research evidence. SDKs, compiled plugins, installers, scene assets and temporary previews stay local.

## Current state

- **Scatter 0.62 / Analyzer 0.14:** current local test candidate, including the CPU and proxy-display improvements. See the [installation and verification guide](docs/Max_2027_Installation.md).
- **Retained point display:** successful private prototype, not integrated into the product or installers. The [October 2 results](docs/Heavy_Scene_Viewport_2026-10-02/RESULTS.md) distinguish measured redraw time, visual differences and remaining gates.
- **Next implementation:** integrate retained preview ownership and the requested Preview / Full Detail switch, then qualify appearance, source support and lifecycle. Follow the [working roadmap](docs/Heavy_Scene_Viewport_2026-10-02/ROADMAP.md) and [implementation plan](docs/Heavy_Scene_Viewport_2026-10-02/IMPLEMENTATION_PLAN.md).

Max 2026 and 2027 SDK builds exist; the recorded interactive retained-display experiment ran in Max 2027. SDK compilation is not Max 2026 runtime qualification.

## Repository layout

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Scatter native engine, generated MAXScript, authoritative UI generator, installer templates and native tests |
| `CyrusSurfaceAnalyzer/` | Analyzer native engine, script, installer templates and tests |
| `cmake/` | Shared Autodesk SDK configuration |
| `tools/` | Build/package tools, regression fixtures, diagnostics and performance experiments |
| `docs/` | [Documentation index](docs/README.md), current findings, plans and dated evidence |

The `AminScatter` internal name is retained for existing scene and installation compatibility. Generate `AminScatter/scripts/AminScatterObject.ms` from `AminScatter/tools/ui/generate.cjs`; do not treat the generated file as the only source.

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

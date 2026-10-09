# Cyrus Scatter

**Layer surfaces and Paint Areas — 9 October 2026:** [Current workflow, tested changes, compatibility and remaining work](docs/Layer_Paint_Areas_0.74_2026-10-09/README.md). Layers now own receiving surfaces; optional named areas can paint different receivers in one layer. The individual stroke editor is removed. Canonical region storage and stable per-receiver generation remain unfinished.

**0.74 list resize correction — 8 October 2026:** [Fixed cursor errors, revised handles, regression evidence and corrected Max 2027 installer](docs/UI_Refinements_0.74_2026-10-08/GRIP_FIX.md). This supersedes the first 0.74 package.

**0.74 UI refinement work — 8 October 2026:** [Implemented changes, checklist and remaining acceptance](docs/UI_Refinements_0.74_2026-10-08/README.md). This development pass adds surface-list management, remembered sections, list grips, Properties disclosures, compact actions and separate identification labels/colors. [The layer/paint-area ownership recommendation](docs/Product_Discussion_2026-10-08/MODELS_AND_PAINTING.md) remains a design decision. The normal installation is unchanged; earlier 0.73 installer receipts remain historical evidence.

**Agent entry point:** [Repository guidelines](AGENTS.md) and [engineering workflow](docs/AGENT_WORKFLOW.md). Read these with the current status/handoff below before changing source or running host fixtures.

**Max 2026 build — 7 October 2026:** [Current compact 0.73 installers and build verification](docs/Max2026_Build_0.73_2026-10-07/README.md). Fresh SDK compilation/native tests passed; Max 2026 runtime remains untested.

**Historical 0.73 baseline review and handoff — 7 October 2026:** [Verified 0.73 status, fresh offline checks and open gates](docs/Status_0.73_And_Website_2026-10-07/README.md), [next-conversation handoff](docs/Status_0.73_And_Website_2026-10-07/HANDOFF.md) and [local visual website](website/index.html). At that review, source and the Add-layer package matched; the inspected installed script predated that correction. Those observations describe the 0.73 checkpoint. The 0.74 handoff above supersedes it for current source and UI changes.

**Historical compact-layout artist documentation — 7 October 2026:** [Plain-language control guide](docs/Artist_Reference_0.73_2026-10-07/README.md), [complete control index](docs/Artist_Reference_0.73_2026-10-07/15_CONTROL_INDEX.md), and [documentation review / next artist walkthrough](docs/Artist_Reference_0.73_2026-10-07/14_REVIEW_AND_WALKTHROUGH.md). Use the October 9 workflow above for layer surfaces and Painting; this guide describes the earlier compact layout; earlier dated artist guides describe their original layouts. This documentation round changes no plugin behavior.

**Cyrus Scatter 0.73: Add layer callback correction:** [the latest fix, actual button regression tests and matching delivery](docs/Layer_Actions_Fix_0.73_2026-10-07/README.md) follows the [compact UI layout](docs/Compact_UI_0.73_2026-10-07/README.md). The [earlier full qualification](docs/Full_Qualification_0.73_2026-10-07/README.md) retains its frozen engine, real-scene and renderer evidence.

Native C++ and MAXScript sources for Cyrus Scatter and Cyrus Surface Analyzer for Autodesk 3ds Max. This repository backs up the code, build/test tools, documentation and curated research evidence. SDKs, compiled plugins, installers, scene assets and temporary previews stay local.

## Current state

**Cyrus Scatter 0.74 development**, package/native **0.74.0**, serialization **54**, model **`CyrusUnified1`**. [Current UI changes and evidence](docs/UI_Refinements_0.74_2026-10-08/README.md). The [unified implementation](docs/Unified_System_0.73_2026-10-06/README.md) removes unpublished old scene policies/schema compatibility, ports useful Line/Analyzer and constrained Relax features, and adds labelled source-container helpers with linked Modify editing and transactional static source following. [Current layer/painting workflow](docs/Layer_Paint_Areas_0.74_2026-10-09/README.md), [results](docs/Unified_System_0.73_2026-10-06/RESULTS.md), [packages](docs/Unified_System_0.73_2026-10-06/PACKAGE.md) and [remaining roadmap](docs/Unified_System_0.73_2026-10-06/ROADMAP.md).

The last packaged 0.73 Max 2027 development test build is in [Layer_Actions_Fix_0.73_2026-10-07](dist/Layer_Actions_Fix_0.73_2026-10-07/Max2027/START_HERE.txt). It pairs the compact workflow and corrected button lifetimes with the verified unchanged native binaries. [Exact build identities](dist/Layer_Actions_Fix_0.73_2026-10-07/BUILD.json) and [known findings](docs/Full_Qualification_0.73_2026-10-07/RESULTS.md) identify this delivery; the version caption alone does not.

Selected-layer Modify sections remain primary; the optional popup and selected-container view use the same records. The 232-control catalog includes the new identification and surface-list fields and accounts for every previous control. Ordered scopes, stable Brush/Edit/source identities, relevant-input Manual/Live scheduling, atomic publication and retained Point Cloud/Mesh data reuse remain the engineering contracts. Source rectangles organize palette models; receiving surfaces carry instances.

MCP **0.73.0** has twelve tools/seven resources and the **closed Plan 0.73** authoring subset with enrollment, local approval, units, ownership, freshness, work limits and rollback. Plans 1/2 are retired. Full recipe/Brush/container/Edit writes, render jobs and portable asset reconstruction remain unavailable. [MCP guide](CyrusMCP/README.md) and [capability matrix](docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md) define the boundary. Diagnostics are integrated in Scatter and need no MCP.

Analyzer stays **0.14**. Licensing remains the independent default-off foundation; commercial coverage is incomplete and unchanged here. Design Lab retains a small offline experimental ranker; no artist-trained/reference-image model or training loop was added. [Prior R&D](docs/TyFlow_CyrusScatter_RnD_2026-10-06/README.md) still identifies open projection, extreme-radius, Brush-memory, Proxy and reporting costs. Historical reports qualify their exact versions, not every later build.

The supplied artist scene and normal installed product files are unchanged. Schemas before the supported 0.74 baseline still require a fresh setup; tested 0.74 single/multi-set files retain their result, with multi-set conversion still pending; original files remain untouched. The historical 0.73 compact UI continuation includes Max 2027 pointer tests, measured widget bounds and idle/cache checks; these do not qualify the new 0.74 grips or colored lists. Earlier 100k navigation/playback and Corona 15 IR/production measurements remain tied to their frozen script/native pair. The first cold container Undo lost its history and remains unisolated; high-count Proxy drawing is expensive and seven original material maps are missing in the private profile. All-control/DPI/long-session/other-renderer and Max 2026 runtime gates remain. **1.0** is reserved for publication readiness; see [versioning](docs/Release_Versioning.md).

## Repository layout

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Scatter native engine, generated MAXScript, authoritative UI generator, installer templates and native tests |
| `CyrusSurfaceAnalyzer/` | Analyzer native engine, script, installer templates and tests |
| `cmake/` | Shared Autodesk SDK configuration |
| `CyrusMCP/` | External MCP server, bounded Max host adapter, schemas, operation journal and tests |
| `CyrusLicensing/` | Independent default-off licensing foundation and laboratory tests; not complete commercial enforcement |
| `tools/` | Build/package tools, regression fixtures, diagnostics and performance experiments |
| `docs/` | [Documentation index](docs/README.md), current findings, plans and dated evidence |

The `AminScatter` internal class/native filename remains a Max registration identity, not a promise of old-development scene compatibility. Public creation and installation use Cyrus names. Generate `AminScatter/scripts/AminScatterObject.ms` from `AminScatter/tools/ui/generate.cjs` with `AminScatter` as the working directory; do not treat the generated file as the only source. See [v1 developer qualification](tools/v1/README.md).

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

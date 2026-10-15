# Cyrus Scatter

Native C++ and generated MAXScript for Cyrus Scatter and Cyrus Surface Analyzer in 3ds Max.

**Current development source: Scatter 0.82.6 / schema 58 / CyrusUnified1.** The [I01/I02 handoff](docs/plans/panel-performance-0826/PROGRESS.md) records lazy panel creation, retained controls/lists, bounded stage timings, correlated edit events and Max 2027 performance checks. The [complete authored recipes handoff](docs/plans/recipes-0825/PROGRESS.md) records multi-layer Save Everything, including native Paint, explicit dependency binding, transactional Add/new setup, qualification and package identity. Models, maps, paths and receivers remain external roles. Unsupported authored Edit/radius overrides or nonstatic parameter controllers block complete save. Phase 6 remains paused; its next provisional step is 0.82.7. The preceding [mesh channel density and Paint help handoff](docs/plans/eleven-phase-roadmap/MESH_MASK_0824.md) records the mask implementation, Max 2027 qualification and installer. The layer-owned mask reads evaluated vertex colors or numbered mesh channels, including Curvature from Data Channel, and composes with existing Paint and density controls. The preceding [0.82.3 performance correction](docs/plans/eleven-phase-roadmap/PERFORMANCE_0823.md) covers idle scheduling and panel binding. Phase 6 remains paused. The [Phase 5 record](docs/plans/eleven-phase-roadmap/P05.md) and [corrected numbering](docs/Release_Versioning.md#eleven-phase-numbering) preserve earlier evidence. Final artist acceptance remains separate.

**Preceding 0.81.7 baseline:** The [viewport correction record](docs/plans/terrace-0815/VIEWPORT_0817.md) is the current handoff for zero-limit Point Cloud preparation and mode-cache reuse. The preceding [adaptive viewport record](docs/plans/terrace-0815/VIEWPORT_0816.md) covers Mesh fallback and independent navigating/idle limits. The preceding [terrace work](docs/plans/terrace-0815/PROGRESS.md) covers: expanded bounded populations, compact source-rectangle selection, cheaper palette refreshes, bounded point preparation and viewport/render source-frame parity. It records exact source/build identities, successful checks, failed iterations and remaining acceptance. The [spline Bands record](docs/plans/spline-bands/PROGRESS.md) preserves preceding feature evidence. **The preceding 0.81.6 delivery covered Max 2026 and 2027; the last recorded agent installation was Max 2027 0.82.2; the current artist installation has not been re-audited**; the [installation record](docs/plans/terrace-0815/INSTALLATION_0816.md) pins packages, backups and the subsequent Max 2027 loaded-module check. Artist terrace acceptance remains pending. This is ongoing development, not release certification. The [offline team licensing pilot](docs/licensing/TEAM_PILOT_0.79_2026-10-11.md) describes unchanged activation and expiry behavior. Analyzer remains 0.14; MCP package/plan remain 0.73.0/0.73.

**Max 2027 installer ready:** [CyrusScatter 0.82.6 MZP](dist/CyrusScatter-0.82.6-20261015/CyrusScatter-0.82.6-Max2027.mzp), with [package verification and panel test instructions](docs/plans/panel-performance-0826/PROGRESS.md). Run it through **Scripting > Run Script**, then restart Max 2027. The 0.82.6 behavior campaign tested recipes, native Paint, Undo, reopen, Live and idle work in isolated profiles. A verified caption-only successor received fresh complete-row and panel-layout checks at 100% and 150% Max UI scale; the handoff distinguishes the two script hashes. The preceding 0.82.4 mask delivery also tested an owned copy of the user's mountain scene. This task did not install it or audit the normal running host. The [0.82.2 installation receipt](docs/plans/eleven-phase-roadmap/INSTALLATION_0822.md) and [first-five-phase checklist](docs/plans/eleven-phase-roadmap/ARTIST_ACCEPTANCE_0822.md) remain available. New development/testing uses Max 2027 only.

## Start here

Start with the [engineering foundation](docs/ENGINEERING_FOUNDATION.md) for the relevant behavioral contracts and the [current implementation evidence](docs/plans/panel-performance-0826/PROGRESS.md) for their measured limits. The [0.79.6 foundation correction](docs/Foundation_0.79.6_2026-10-12/README.md) and 0.79.5 [creation-icon correction](docs/Terrace_Workflow_0.79.5_2026-10-11/CREATION_FIX.md) are historical source/package witnesses.

| Need | Maintained document |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md) |
| Understand ownership and implementation | [Architecture and source map](docs/ARCHITECTURE.md) |
| See what needs fixing next | [Current backlog](docs/BACKLOG.md) |
| Install or rebuild | [Max 2026/2027 installation/build](docs/Max_2027_Installation.md) |
| Work on the repository | [AGENTS.md](AGENTS.md), [agent workflow](docs/AGENT_WORKFLOW.md) |
| Find tests and exact results | [0.79.5 campaign](docs/Terrace_Workflow_0.79.5_2026-10-11/README.md), [current coverage](docs/Terrace_Workflow_0.79.5_2026-10-11/COVERAGE.md), [control register](docs/Terrace_Workflow_0.79.5_2026-10-11/CONTROL_REGISTER.md), [0.79.1 Point/falloff qualification](docs/Point_Workflow_0.79.1_2026-10-11/README.md), [vector integration](docs/Vector_Brush_0.78_2026-10-10/README.md) and [0.75 system qualification](docs/System_Qualification_0.75_2026-10-09/README.md) |
| Other documentation | [Documentation index](docs/README.md) |
| Product website and public roadmap | [Website source and local preview](website/README.md), [product and AI direction](docs/PRODUCT_AND_AI_ROADMAP.md) |

The current candidate uses receiver-bound vector regions, cached border feedback, inward/outward feathering and independent density/scale curves. Paint unions outlines; Erase cuts holes. Layers retain their models, population, stable candidates and receiver caches. Spline Bands add persistent ownership, Consecutive/Independent ranges, Rounded/Sharp joins, independent density/scale curves and bounded field feedback; Auto Radius uses conservative XY/3D source bounds. Consult the current evidence for qualified scenarios and open gates.

**Current schema only:** create fresh schema-58 setups. Earlier development scenes are rejected; migration handlers and old placement formats have been removed. Preserve original scene files. Current setups retain typed distances and current-schema save/reopen, copy and unit handling; native Paint/Edit bindings still require saved scene units when conversion changes receiver geometry.

Vector painting supports single-valued local-XY terrain and planes, including transformed receivers. Closed, vertical, folded or overlapping projected receivers are explicitly rejected. General scattering on curved receivers remains supported. Physical artist input, sustained heavy scenes and renderer/platform release qualification are still acceptance gates; version captions alone do not identify a build.

## Repository

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Scatter native engine, authoritative UI templates/generator, generated script and tests |
| `CyrusSurfaceAnalyzer/` | Independently versioned Analyzer |
| `CyrusMCP/` | Bounded automation; [supported operations](CyrusMCP/README.md) |
| `CyrusLicensing/` | Independent foundation and public team trust; enabled in Scatter 0.79 team builds, not complete commercial enforcement |
| `tools/` | Build, tests, diagnostics and private host qualification |
| `docs/` | Maintained guides, current work, dated evidence and separate research |

Author UI changes in `AminScatter/tools/ui/templates/unified-core.ms` and relevant generator modules; regenerate `scripts/AminScatterObject.ms`. Internal AminScatter names remain registration identities.

Build/test commands and host isolation rules are in the agent workflow. SDK compilation is not Max runtime qualification. The 0.78.3 report records container controls, brush cursor sizing and qualification limits.

`build/`, `dist/`, `Test Scene/` and `_local/` contain ignored local toolchains, installers, experiments and artist assets. They are not backed up by Git. Preserve scene paths and the artist's normal Max profile; see [workspace organization](docs/Workspace_Organization.md).

Historical development labels, old installers and previous test results remain available through [history](docs/HISTORY.md). They are not alternative current instructions.

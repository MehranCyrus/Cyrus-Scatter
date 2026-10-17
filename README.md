# Cyrus Scatter

Native C++ and generated MAXScript for Cyrus Scatter and Cyrus Surface Analyzer in 3ds Max.

**0.85.4 Count memory correction is compiled and scoped-qualified for Max 2027.** See [the current handoff, tests and installers](docs/plans/memory-0854/README.md). It preserves the [0.85.3 ready presets](docs/plans/preset-gallery-improvements/LOAD_0853.md), [0.85.2 panel navigation/library sizing correction](docs/plans/preset-gallery-improvements/UI_CORRECTION_0852.md) and [0.85.1 gallery delivery](docs/plans/preset-gallery-improvements/DELIVERY_0851.md). Their historical receipts retain their original scope; broader B26, adapters and production-renderer acceptance remain open.

**Current development source: Scatter 0.85.4 / schema 58 / CyrusUnified1.** The [Count memory correction](docs/plans/memory-0854/README.md) reduces temporary script transports and reserves session working memory before actual Updates, retaining Undo and complete-result rollback. It follows the [0.85.3 ready presets](docs/plans/preset-gallery-improvements/LOAD_0853.md); historical receipts remain frozen. Ready presets, supported settings and Paint remain available. Saved Max heap preferences are unchanged. Follow the [execution ledger](docs/plans/improvement-program/PROGRESS.md). P01–P07 are implemented; further roadmap feature work is paused. I07/P08 paths is the next pending feature. Slope and altitude behavior is unchanged. Broader heavy-session qualification and later features remain open.

The preceding [0.82.6 panel handoff](docs/plans/panel-performance-0826/PROGRESS.md) records lazy controls and bounded diagnostics. The [0.82.5 recipe core](docs/plans/recipes-0825/PROGRESS.md), [0.82.4 mesh mask/Paint help](docs/plans/eleven-phase-roadmap/MESH_MASK_0824.md) and [0.82.3 performance correction](docs/plans/eleven-phase-roadmap/PERFORMANCE_0823.md) remain historical evidence for retained behavior. Current host qualification is Max 2027 only; normal-profile artist acceptance remains separate.

**Preceding 0.81.7 baseline:** The [viewport correction record](docs/plans/terrace-0815/VIEWPORT_0817.md) is the current handoff for zero-limit Point Cloud preparation and mode-cache reuse. The preceding [adaptive viewport record](docs/plans/terrace-0815/VIEWPORT_0816.md) covers Mesh fallback and independent navigating/idle limits. The preceding [terrace work](docs/plans/terrace-0815/PROGRESS.md) covers: expanded bounded populations, compact source-rectangle selection, cheaper palette refreshes, bounded point preparation and viewport/render source-frame parity. It records exact source/build identities, successful checks, failed iterations and remaining acceptance. The [spline Bands record](docs/plans/spline-bands/PROGRESS.md) preserves preceding feature evidence. **The preceding 0.81.6 delivery covered Max 2026 and 2027; the last recorded agent installation was Max 2027 0.82.2; the current artist installation has not been re-audited**; the [installation record](docs/plans/terrace-0815/INSTALLATION_0816.md) pins packages, backups and the subsequent Max 2027 loaded-module check. Artist terrace acceptance remains pending. This is ongoing development, not release certification. The [offline team licensing pilot](docs/licensing/TEAM_PILOT_0.79_2026-10-11.md) describes unchanged activation and expiry behavior. Analyzer remains 0.14; MCP package/plan remain 0.73.0/0.73.

**Max 2027 delivery:** [0.85.4 handoff, installer paths and qualification](docs/plans/memory-0854/README.md). Run the MZP through **Scripting > Run Script**, or use the unsigned Windows EXE, then restart Max 2027. No artist installation is performed by this task. Physical viewport/input, production renderers and general heavy-session acceptance remain separate.

## Start here

Start with the [engineering foundation](docs/ENGINEERING_FOUNDATION.md) for relevant behavioral contracts and [current implementation evidence](docs/plans/memory-0854/README.md) for measured limits. Earlier dated handoffs remain historical source/package witnesses.

| Need | Maintained document |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md) |
| Understand ownership and implementation | [Architecture and source map](docs/ARCHITECTURE.md) |
| See what needs fixing next | [Current backlog](docs/BACKLOG.md) |
| Plan the remaining native placement migration | [Source findings, staged implementation and Max 2027 acceptance](docs/plans/native-placement/README.md) — planning only; 0.85.4 remains current; further roadmap implementation is paused |
| Follow preset/gallery improvements | [PG01–PG10 plan, easiest to hardest](docs/plans/preset-gallery-improvements/README.md), [delivery and remaining scope](docs/plans/preset-gallery-improvements/DELIVERY_0851.md), [performance/Max 2027 acceptance](docs/plans/preset-gallery-improvements/VALIDATION.md) and [checklist](docs/plans/preset-gallery-improvements/TODO.md) |
| Install or rebuild | [Max 2027 installation/build](docs/Max_2027_Installation.md) |
| Work on the repository | [AGENTS.md](AGENTS.md), [agent workflow](docs/AGENT_WORKFLOW.md) |
| Find tests and exact results | [0.79.5 campaign](docs/Terrace_Workflow_0.79.5_2026-10-11/README.md), [current coverage](docs/Terrace_Workflow_0.79.5_2026-10-11/COVERAGE.md), [control register](docs/Terrace_Workflow_0.79.5_2026-10-11/CONTROL_REGISTER.md), [0.79.1 Point/falloff qualification](docs/Point_Workflow_0.79.1_2026-10-11/README.md), [vector integration](docs/Vector_Brush_0.78_2026-10-10/README.md) and [0.75 system qualification](docs/System_Qualification_0.75_2026-10-09/README.md) |
| Other documentation | [Documentation index](docs/README.md) |
| Product website and public roadmap | [Website source and local preview](website/README.md), [product and AI direction](docs/PRODUCT_AND_AI_ROADMAP.md) |

The current implementation uses receiver-bound vector regions, cached border feedback, inward/outward feathering and independent density/scale curves. Paint unions outlines; Erase cuts holes. Layers retain their models, population, stable candidates and receiver caches. Spline Bands add persistent ownership, Consecutive/Independent ranges, Rounded/Sharp joins, independent density/scale curves and bounded field feedback; Auto Radius uses conservative XY/3D source bounds. Consult the current evidence for qualified scenarios and open gates.

**Current schema only:** create fresh schema-58 setups. Earlier development scenes are rejected; migration handlers and old placement formats have been removed. Preserve original scene files. Current setups retain typed distances and current-schema save/reopen, copy and unit handling; native Paint/Edit bindings still require saved scene units when conversion changes receiver geometry.

Vector painting supports single-valued local-XY terrain and planes, including transformed receivers. Closed, vertical, folded or overlapping projected receivers are explicitly rejected. General scattering on curved receivers remains supported. Physical artist input, sustained heavy scenes and renderer/platform release qualification are still acceptance gates; version captions alone do not identify a build.

The maintained [engineering foundation](docs/ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries) governs native data ownership, caching, Undo and future physics/animation. The [execution ledger](docs/plans/improvement-program/PROGRESS.md#original-phase-status) distinguishes completed phases from pending features and paused implementation. The [knowledge repair and activation report](tools/rag/KNOWLEDGE_REPAIR_2026-10-17.md) records the active index and retrieval limits. Documentation maintenance does not implement the proposed native migration.

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

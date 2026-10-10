# Cyrus Scatter

Native C++ and generated MAXScript for Cyrus Scatter and Cyrus Surface Analyzer in 3ds Max.

**Current development: Scatter 0.78.2 / package 0.78.2 / schema 55 / CyrusUnified1.** Analyzer remains 0.14; MCP package/plan remain 0.73.0/0.73. This is not 1.0 release certification.

## Start here

| Need | Maintained document |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md) |
| Understand ownership and implementation | [Architecture and source map](docs/ARCHITECTURE.md) |
| See what needs fixing next | [Current backlog](docs/BACKLOG.md) |
| Install or rebuild | [Max 2026/2027 installation/build](docs/Max_2027_Installation.md) |
| Work on the repository | [AGENTS.md](AGENTS.md), [agent workflow](docs/AGENT_WORKFLOW.md) |
| Find tests and exact results | [Current drawing responsiveness qualification](docs/Brush_Responsiveness_0.78.2_2026-10-10/README.md), [vector integration](docs/Vector_Brush_0.78_2026-10-10/README.md), [0.76 receiver stability](docs/Receiver_Stability_0.76_2026-10-10/README.md), [Brush fixes](docs/Brush_Scaling_0.76_2026-10-10/README.md), [retained Proxy/Analyzer fixes](docs/Courtyard_Fixes_0.75_2026-10-10/README.md), [0.75 system qualification](docs/System_Qualification_0.75_2026-10-09/README.md) and [feature checklist](docs/System_Qualification_0.75_2026-10-09/CHECKLIST.md) |
| Other documentation | [Documentation index](docs/README.md) |

The current candidate replaces stroke replay with receiver-bound vector regions, cached border feedback, inward/outward feathering and independent density/scale curves. Paint unions outlines; Erase cuts holes. Layers retain their models, population, stable candidates and receiver caches. Schema 55 explicitly rejects older development setups; there is no conversion or legacy brush fallback. Start a new setup and preserve old scenes with their matching build.

Vector painting supports single-valued local-XY terrain and planes, including transformed receivers. Closed, vertical, folded or overlapping projected receivers are explicitly rejected. General scattering on curved receivers remains supported. Physical artist input, sustained heavy scenes and renderer/platform release qualification are still acceptance gates; version captions alone do not identify a build.

## Repository

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Scatter native engine, authoritative UI templates/generator, generated script and tests |
| `CyrusSurfaceAnalyzer/` | Independently versioned Analyzer |
| `CyrusMCP/` | Bounded automation; [supported operations](CyrusMCP/README.md) |
| `CyrusLicensing/` | Independent default-off foundation; not complete commercial enforcement |
| `tools/` | Build, tests, diagnostics and private host qualification |
| `docs/` | Maintained guides, current work, dated evidence and separate research |

Author UI changes in `AminScatter/tools/ui/templates/unified-core.ms` and relevant generator modules; regenerate `scripts/AminScatterObject.ms`. Internal AminScatter names remain registration identities.

Build/test commands and host isolation rules are in the agent workflow. SDK compilation is not Max runtime qualification. The 0.78.2 report records the drawing changes, measurements and qualification limits.

`build/`, `dist/`, `Test Scene/` and `_local/` contain ignored local toolchains, installers, experiments and artist assets. They are not backed up by Git. Preserve scene paths and the artist's normal Max profile; see [workspace organization](docs/Workspace_Organization.md).

Historical development labels, old installers and previous test results remain available through [history](docs/HISTORY.md). They are not alternative current instructions.

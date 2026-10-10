# Cyrus Scatter

Native C++ and generated MAXScript for Cyrus Scatter and Cyrus Surface Analyzer in 3ds Max.

**Current development: Scatter 0.76 / package 0.76.0 / schema 54 / CyrusUnified1.** Analyzer remains 0.14; MCP package/plan remain 0.73.0/0.73. This is not 1.0 release certification.

## Start here

| Need | Maintained document |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md) |
| Understand ownership and implementation | [Architecture and source map](docs/ARCHITECTURE.md) |
| See what needs fixing next | [Current backlog](docs/BACKLOG.md) |
| Install or rebuild | [Max 2027 installation/build](docs/Max_2027_Installation.md) |
| Work on the repository | [AGENTS.md](AGENTS.md), [agent workflow](docs/AGENT_WORKFLOW.md) |
| Find tests and exact results | [Latest 0.76 Brush fixes and matched packages](docs/Brush_Scaling_0.76_2026-10-10/README.md), [retained Proxy/Analyzer fixes](docs/Courtyard_Fixes_0.75_2026-10-10/README.md), [0.75 system qualification](docs/System_Qualification_0.75_2026-10-09/README.md) and [feature checklist](docs/System_Qualification_0.75_2026-10-09/CHECKLIST.md) |
| Other documentation | [Documentation index](docs/README.md) |

The latest matched candidate adds bounded Brush preparation and faster history indexing to the retained Proxy, root Update and Analyzer fixes. Its bounded native, Python, scripted Max and Corona geometry checks pass. Cold viewport realization, the earlier intermittent display observation, receiver stability, full-scene Brush memory/latency and broader artist acceptance remain open. Install the matching Scatter/Analyzer pair linked above; version captions alone do not identify a build. See the backlog and exact receipts before treating a feature as qualified.

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

Build/test commands and host isolation rules are in the agent workflow. SDK compilation is not Max runtime qualification. Max 2026 runtime remains an open gate.

`build/`, `dist/`, `Test Scene/` and `_local/` contain ignored local toolchains, installers, experiments and artist assets. They are not backed up by Git. Preserve scene paths and the artist's normal Max profile; see [workspace organization](docs/Workspace_Organization.md).

Historical development labels, old installers and previous test results remain available through [history](docs/HISTORY.md). They are not alternative current instructions.

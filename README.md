# Cyrus Scatter

Native C++ scattering and generated MAXScript UI for 3ds Max.

**Current delivery: Scatter 0.86.2 / schema 58 / CyrusUnified1, qualified within scope for Max 2026/2027; Max 2024 preview.** The [density and recipe report](docs/plans/preset-gallery-improvements/DELIVERY_0862.md) owns the exact installers, demonstration and scoped tests. It adds projected image density, separate mesh-channel density, persistent surface masks, complete image/Paint recipes and layout fixes. The latest same-version UI follow-up fixes dropdown focus, simplifies Amount, bundles three starter masks and preserves metadata beside long Layer/Model names; use the latest installers in that report. The current universal EXE includes matching Max 2024/2026/2027 payloads; 2024 remains preview because no runnable host was available. Earlier receipts retain their original identities. The [execution ledger](docs/plans/improvement-program/PROGRESS.md) owns remaining work. Unrelated roadmap work and knowledge activation remain paused.

| Need | Maintained source |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md), [Layout and falloff](docs/LAYOUT_AND_FALLOFF.md) |
| Install or build | [Max 2027 installation/build](docs/Max_2027_Installation.md); [qualified MZP/EXE and artist tests](docs/plans/preset-gallery-improvements/DELIVERY_0862.md) |
| Understand implementation | [Architecture](docs/ARCHITECTURE.md), [engineering contracts](docs/ENGINEERING_FOUNDATION.md) |
| Find remaining work | [Execution ledger](docs/plans/improvement-program/PROGRESS.md), [defects and acceptance](docs/BACKLOG.md) |
| Work in this repository | [AGENTS.md](AGENTS.md), [agent workflow](docs/AGENT_WORKFLOW.md), [version policy](docs/Release_Versioning.md) |
| Find current documents and research | [Documentation index](docs/README.md) |
| Find older results | [History and evidence](docs/HISTORY.md), [archive](docs/archive/README.md) |

The current controller keeps bulk placement generation, masks/Paint, transforms, Edit, acceptance and preview preparation in native storage. MAXScript retains authored parameter blocks, UI and bounded coordination. Particle Flow still uses a Script Operator over native transforms; Bake creates real scene nodes through bounded pages. Heavy operations remain synchronous and the one-million candidate cap remains. Read the delivery report for measurements rather than assuming every operation is native or instantaneous.

Layers own receivers, models and population rules. Paint Areas retain receiver-bound vector coverage; overlapping areas union coverage. Painting supports single-valued local-XY terrain and rejects vertical, folded or overlapping projections. Current schema 58 is required; older development schemas are not migrated. Preserve original scenes and saved units for guarded Paint/Edit bindings.

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Native engine, authoritative UI templates/generator, generated script and tests |
| `CyrusSurfaceAnalyzer/` | Independently versioned Analyzer 0.14 |
| `CyrusMCP/` | Bounded automation, package/plan 0.73.0/0.73 |
| `CyrusLicensing/` | Independent licensing foundation |
| `docs/` | Maintained guidance, contracts, evidence and separately labeled research |
| `tools/rag/` | Local knowledge tooling and [current selection/verification](tools/rag/README.md) |

Edit UI templates/generator modules, never only `AminScatter/scripts/AminScatterObject.ms`. Internal AminScatter names are registration identities. The [native boundary and physics/animation contract](docs/ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries) governs future work; the standalone Physics Lab is separate from integrated Scatter support.

Use **Scripting > Run Script** with the MZP matching your Max year, then restart that Max version. The unsigned universal EXE provides a host selector. No artist installation or restart was performed. `build/`, `dist/`, `_local/` and `Test Scene/` contain ignored local artifacts and assets, not Git backups; see [workspace organization](docs/Workspace_Organization.md).

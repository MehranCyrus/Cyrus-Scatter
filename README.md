# Cyrus Scatter

Native C++ scattering and generated MAXScript UI for 3ds Max.

**Current delivery: Scatter 0.86.6 / schema 58 / CyrusUnified1, qualified within scope for Max 2027.** The [surface brush delivery](docs/plans/preset-gallery-improvements/DELIVERY_0866.md) owns the exact MZP/EXE and evidence. It restores painting on spheres, boxes and manifold curved receivers. The preceding library/Amount feature baseline is 0.86.5 by user correction; its original [0.87.0 receipts](docs/plans/preset-gallery-improvements/DELIVERY_0870.md) retain their actual labels and hashes. It adds receiver-aware maps, reusable Paint across units/footprints, relative-elevation presets and Clear/source/window lifecycle fixes. Earlier [0.86.2 older-host deliveries](docs/plans/preset-gallery-improvements/DELIVERY_0862.md) retain their original scope. The [execution ledger](docs/plans/improvement-program/PROGRESS.md) owns remaining work; unrelated roadmap work is outside this delivery.

| Need | Maintained source |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md), [Layout and falloff](docs/LAYOUT_AND_FALLOFF.md) |
| Install or build | [Max 2027 installation/build](docs/Max_2027_Installation.md); [qualified Max 2027 MZP/EXE and artist tests](docs/plans/preset-gallery-improvements/DELIVERY_0866.md) |
| Understand implementation | [Architecture](docs/ARCHITECTURE.md), [engineering contracts](docs/ENGINEERING_FOUNDATION.md) |
| Find remaining work | [Execution ledger](docs/plans/improvement-program/PROGRESS.md), [defects and acceptance](docs/BACKLOG.md) |
| Work in this repository | [AGENTS.md](AGENTS.md), [agent workflow](docs/AGENT_WORKFLOW.md), [version policy](docs/Release_Versioning.md) |
| Find current documents and research | [Documentation index](docs/README.md) |
| Find older results | [History and evidence](docs/HISTORY.md), [archive](docs/archive/README.md) |

The separate private real-plant artist-test delivery uses **0.86.6.1**, explicitly
selected by the user to correct its original 0.88.0 label. The eight presets and
rendered previews are unchanged; historical receipts retain their original
identities. See the [current library handoff](docs/plans/improvement-program/PROGRESS.md#real-model-library-planning).
Its [Max 2027 installer](dist/CyrusScatter-0.86.6.1-20261020/CyrusScatter-0.86.6.1-Max2027.mzp)
lives in the repository's `dist/` folder alongside previous releases.
The qualified 0.86.6 baseline above remains separately identified.

The current controller keeps bulk placement generation, masks/Paint, transforms, Edit, acceptance and preview preparation in native storage. MAXScript retains authored parameter blocks, UI and bounded coordination. Particle Flow still uses a Script Operator over native transforms; Bake creates real scene nodes through bounded pages. Heavy operations remain synchronous and the one-million candidate cap remains. Read the delivery report for measurements rather than assuming every operation is native or instantaneous.

Layers own receivers, models and population rules. Paint Areas retain receiver-bound vector coverage; overlapping areas union coverage. Painting keeps the terrain vector path and adds surface-attached vector regions for spheres, boxes and manifold curved receivers. Curved strokes follow surface distance; disconnected sheets stay independent. Current schema 58 is required; older development schemas are not migrated. Preserve original scenes and saved units for guarded Paint/Edit bindings.

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Native engine, authoritative UI templates/generator, generated script and tests |
| `CyrusSurfaceAnalyzer/` | Independently versioned Analyzer 0.14 |
| `CyrusMCP/` | Bounded automation, package/plan 0.73.0/0.73 |
| `CyrusLicensing/` | Independent licensing foundation |
| `docs/` | Maintained guidance, contracts, evidence and separately labeled research |
| `tools/rag/` | Local knowledge tooling and [current selection/verification](tools/rag/README.md) |

Edit UI templates/generator modules, never only `AminScatter/scripts/AminScatterObject.ms`. Internal AminScatter names are registration identities. The [native boundary and physics/animation contract](docs/ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries) governs future work; the standalone Physics Lab is separate from integrated Scatter support.

Use **Scripting > Run Script** with the MZP matching your Max year, then restart that Max version. The prior 0.86.2 universal EXE retains its separate host scope. No artist installation or restart was performed. `build/`, `dist/`, `_local/` and `Test Scene/` contain ignored local artifacts and assets, not Git backups; see [workspace organization](docs/Workspace_Organization.md).

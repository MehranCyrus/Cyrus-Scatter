# Cyrus Scatter

Native C++ scattering and generated MAXScript UI for 3ds Max.

**Current test delivery: Scatter 0.86.9 / schema 59 / CyrusUnified2, with Surface Analyzer 0.14.2 for Max 2024, 2026 and 2027.** The [delivery report](docs/plans/edit-instances/DELIVERY_0869.md) records source-aware Edit preservation, identification colours, final-position feedback, focused lifecycle tests and the exact combined installer. Original Paint, source-clearance calculation and content revision 0.86.7 are preserved. Save upgraded Edit scenes as new copies; older plugins cannot read the new source-aware Edit format.

Whole-object Copy of Edit stacks that reference lower-modifier clones, and radius
overrides targeting cloned instances, still needs coordinated ID remapping. The
[artist guide](docs/ARTIST_GUIDE.md#copy-and-recipe-variation-0840) explains the
trigger; [B37](docs/BACKLOG.md#edit-instance-findings--0869) owns the remaining
repair. Current documentation is separate from the still-stale selected
[knowledge index](tools/rag/README.md); inspect current originals when retrieval
cannot verify them.

The historical [0.86.8.7 review and memory delivery](docs/plans/code-quality/DELIVERY_08687.md) retains its Max 2027 evidence. The [0.86.8.6 combined delivery](docs/plans/combined-installer/DELIVERY_08686.md) retains its earlier three-host scope and Analyzer 0.14.1. The [execution ledger](docs/plans/improvement-program/PROGRESS.md) records remaining roadmap work.

| Need | Maintained source |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md), [Layout and falloff](docs/LAYOUT_AND_FALLOFF.md) |
| Install or build | [Installation/build](docs/Max_2027_Installation.md); [0.86.9 delivery, checks and limits](docs/plans/edit-instances/DELIVERY_0869.md) |
| Understand implementation | [Architecture](docs/ARCHITECTURE.md), [engineering contracts](docs/ENGINEERING_FOUNDATION.md) |
| Find remaining work | [Execution ledger](docs/plans/improvement-program/PROGRESS.md), [defects and acceptance](docs/BACKLOG.md) |
| Work in this repository | [AGENTS.md](AGENTS.md), [agent workflow](docs/AGENT_WORKFLOW.md), [version policy](docs/Release_Versioning.md) |
| Find current documents and research | [Documentation index](docs/README.md) |
| Find older results | [History and evidence](docs/HISTORY.md), [archive](docs/archive/README.md) |

The private **0.86.7 individual library** retains 96 prepared models and their
original previews, covering all 104 catalog cards. **Display mode > Textured
mesh** previews supported materials and leaf opacity. **Surfaces > Hide surface**
keeps receivers available for painting and rendering. New layers inherit the
selected layer's current surfaces.
**Models & Points** uses **+** to add objects, places **Add Point** beside **Make
point**, and lets **Pick object** replace either a Point or a model.
Put `CyrusScatter-Content-0.86.7.zip` beside the EXE and check **Install / update
plant library** to install content. Qualified plugin packages are under
`dist/CyrusScatter-0.86.9-20261023/`; distribute the existing content ZIP separately
for recipients who need it. Leave the option unchecked to keep existing
content. Content keeps its independent revision and is shared by standard profiles
across the supported Max 2024, 2026 and 2027 profiles. Plugin-only updates do not
copy the models. The ZIP streams
into one shared store, reusing verified existing bytes; success shows a brief
completion message. Prepared files were saved back to Max 2024 format; model geometry and image
assets were reused. Corona/Forest material dependencies still require matching
host plug-ins. Actual Corona leaf material tests were performed in Max 2027;
the older local hosts lack those dependencies. See the delivery report for
exact scope and receipts. Private content and installers remain outside Git.

The separate [panel loading/threading investigation](docs/plans/panel-performance-0826/PANEL_THREADING_20261020.md)
records existing lazy controls, a small frozen Max 2027 timing probe, safe worker
boundaries and a recommended optimization order. It introduces no UI rewrite or
new performance delivery by itself. The patch report records the later implementation.

The [shared-library and panel implementation plan](docs/plans/preset-gallery-improvements/UI_AND_CONTENT_IMPLEMENTATION_PLAN.md)
combines independent plugin/content updates, one selectable library location
for all three hosts, migration/storage accounting and scoped panel optimization.
Its [research](docs/plans/preset-gallery-improvements/SHARED_CONTENT_RESEARCH_20261020.md)
records the artist's disk-space failure and official Chaos/ITOOSOFT workflows.
The authorized 0.86.7.1 implementation covers independent updates, verified
adoption/managed storage and scoped panel work. Automatic retirement of old
scene-dependent paths and fully lazy Advanced controls remain future work.

The current controller keeps bulk placement generation, masks/Paint, transforms, Edit, acceptance and preview preparation in native storage. MAXScript retains authored parameter blocks, UI and bounded coordination. Particle Flow still uses a Script Operator over native transforms; Bake creates real scene nodes through bounded pages. Heavy operations remain synchronous and the one-million candidate cap remains. Read the delivery report for measurements rather than assuming every operation is native or instantaneous.

Layers own receivers, models and population rules. Paint Areas retain receiver-bound vector coverage; overlapping areas union coverage. Painting keeps the terrain vector path and adds surface-attached vector regions for spheres, boxes and manifold curved receivers. Curved strokes follow surface distance; disconnected sheets stay independent. Current schema 59 is required. Schema 58 has an explicit Undoable upgrade; earlier development schemas remain unsupported. Preserve original scenes and saved units for guarded Paint/Edit bindings.

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Native engine, authoritative UI templates/generator, generated script and tests |
| `CyrusSurfaceAnalyzer/` | Independently versioned Analyzer 0.14.2 |
| `CyrusMCP/` | Bounded automation, package/plan 0.73.0/0.73 |
| `CyrusLicensing/` | Independent licensing foundation |
| `docs/` | Maintained guidance, contracts, evidence and separately labeled research |
| `tools/rag/` | Local knowledge tooling and [current selection/verification](tools/rag/README.md) |

Edit UI templates/generator modules, never only `AminScatter/scripts/AminScatterObject.ms`. Internal AminScatter names are registration identities. The [native boundary and physics/animation contract](docs/ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries) governs future work; the standalone Physics Lab is separate from integrated Scatter support.

The shareable `CyrusScatter-0.86.9-Setup.exe` installs Scatter and Analyzer for the selected supported Max versions. Save and close those hosts first, then reopen after installation. Alternatively use **Scripting > Run Script** with the matching `CyrusScatter-0.86.9-Max2027.mzp` (or 2024/2026 counterpart), then restart that host. Analyzer's standalone MZP uses the same transaction engine as the EXE. Both products retain verified create-only v2 backups and block unknown/custom startup files or registrations. Follow the [installation and recovery instructions](docs/Max_2027_Installation.md). No artist installation or restart was performed. `build/`, `dist/`, `_local/` and `Test Scene/` contain ignored local artifacts and assets, not Git backups; see [workspace organization](docs/Workspace_Organization.md).

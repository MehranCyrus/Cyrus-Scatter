# Cyrus Scatter

**Current artist-test delivery: Scatter 0.87.3 / schema 61.** A [three-host installer](docs/plans/preset-gallery-improvements/INSTALLER_0873_COMPATIBILITY.md) is prepared for Max 2024, 2026 and 2027. New 2024/2026 payloads have native tests only; scoped runtime qualification remains Max 2027. The [Library startup hotfix](docs/plans/preset-gallery-improvements/LIBRARY_STARTUP_0873.md) corrects the default saved-folder lookup and remembering a new library location. Normal settings paths and the actual Layers > Recipes button pass in an owned host, alongside a retained interaction-scene smoke. Use its matched MZP and restart Max. Exposed-root fitting remains on hold; Analyzer 0.14.2 and content 0.86.7 retain their independent versions.

**Preceding Interactions delivery: Scatter 0.87.2 / schema 61, Max 2027 only.** The [Interactions correction](docs/plans/scatter-interactions-garden-20261025/DELIVERY_0872.md) adds explicit SI preparation settings with legacy repair, Arthropodium folded-leaf/branch preparation and separate lightweight trunk/custom colliders while retaining full visual trees. Use its matched MZP and saved small-scene copy. The preceding 0.87.1 shared-library delivery retains its separate three-host qualification; this successor does not extend 0.87.2 to older hosts. Analyzer 0.14.2 and content 0.86.7 remain independent.

Native C++ scattering and generated MAXScript UI for 3ds Max.

**Historical 0.86.9.1 acceptance is withdrawn:** its Modify-panel crash was reproduced and corrected in 0.86.9.2. The current delivery below retains Max's native column ownership; small native insets may remain.

**Preceding shared-library delivery: Scatter 0.87.1 / schema 60, with scoped Max 2024, 2026 and 2027 qualification.** The [shared-library delivery](docs/plans/preset-gallery-improvements/DELIVERY_0871.md) adds models/images stored once, reusable standalone models, pinned recipes, collections, portable sharing and explicit migration/storage management. The three hosts pass the ten-look fresh-scene workflow and personal-model campaign with source-matched payloads; ten-look tests also exercise automatic installed startup. Portable textures require the supported default OCIO profile. Analyzer 0.14.2 and installed content 0.86.7 remain independently versioned.

**Historical Interactions trial: Scatter 0.87.0 / schema 60 / CyrusUnified2, Max 2027 only.** The [Interactions delivery](docs/plans/scatter-interactions-garden-20261025/DELIVERY_0870.md) adds reviewed shared plant preparation, Collider/React layer roles, local contact poses, reversible covered roots and individual Cyrus Edit stone movement. Its report distinguishes large-scene command measurements, held-pointer evidence, full-mesh audits and remaining artist checks. Use the matching Max 2027 MZP and saved trial copies. Surface Analyzer 0.14.2 and content 0.86.7 remain independently versioned; this delivery does not update their packages or older Max hosts. Original Paint, source-clearance calculation and native Edit storage 2 remain in place. Preserve original scenes when saving schema 60.

**Historical build-only installer:** [0.87.0 EXE for Max 2024, 2026 and 2027](docs/plans/scatter-interactions-garden-20261025/INSTALLER_0870_COMPATIBILITY.md). The user requested packaging without further tests: 2024/2026 are newly built and untested; the 2027 package is unchanged from r4. Analyzer and content installations remain independent. No Max session was launched or installed for this packaging request.

The historical [0.86.9.2 delivery](docs/plans/edit-instances/DELIVERY_08692.md) retains its Max 2027 patch evidence and built-only Max 2024/2026 counterparts. Its combined EXE does not install 0.87.0. Plugins older than 0.86.9 cannot read source-aware Edit storage.

Whole-object Copy of Edit stacks that reference lower-modifier clones, and radius
overrides targeting cloned instances, still needs coordinated ID remapping. The
[artist guide](docs/ARTIST_GUIDE.md#copy-and-recipe-variation-0840) explains the
trigger; [B37](docs/BACKLOG.md#edit-instance-findings--0869) owns the remaining
repair. [Knowledge selection and full-source verification](tools/rag/README.md) are recorded separately; inspect current originals whenever retrieval is stale or outside its enrolled scope.

The historical [0.86.8.7 review and memory delivery](docs/plans/code-quality/DELIVERY_08687.md) retains its Max 2027 evidence. The [0.86.8.6 combined delivery](docs/plans/combined-installer/DELIVERY_08686.md) retains its earlier three-host scope and Analyzer 0.14.1. The [execution ledger](docs/plans/improvement-program/PROGRESS.md) records remaining roadmap work.

| Need | Maintained source |
| --- | --- |
| Use the plugin | [Artist guide](docs/ARTIST_GUIDE.md), [Layout and falloff](docs/LAYOUT_AND_FALLOFF.md) |
| Install or build | [Installation/build](docs/Max_2027_Installation.md); [0.87.3 Library startup correction](docs/plans/preset-gallery-improvements/LIBRARY_STARTUP_0873.md) |
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
plant library** to install content. Historical compatibility packages are under
`dist/CyrusScatter-0.86.9.2-20261023/`; distribute the existing content ZIP separately
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

Layers own receivers, models and population rules. Paint Areas retain receiver-bound vector coverage; overlapping areas union coverage. Painting keeps the terrain vector path and adds surface-attached vector regions for spheres, boxes and manifold curved receivers. Curved strokes follow surface distance; disconnected sheets stay independent. Current schema 61 stores prepared contact definitions, SI minimums and source-bound collider references. Schema 60 preparation settings need explicit reviewed migration. Schema 59 opens with Interactions off; schema 58 retains its explicit Undoable upgrade. Earlier development schemas remain unsupported. Preserve original scenes and saved units for guarded Paint/Edit bindings.

| Path | Purpose |
| --- | --- |
| `AminScatter/` | Native engine, authoritative UI templates/generator, generated script and tests |
| `CyrusSurfaceAnalyzer/` | Independently versioned Analyzer 0.14.2 |
| `CyrusMCP/` | Bounded automation, package/plan 0.73.0/0.73 |
| `CyrusLicensing/` | Independent licensing foundation |
| `CyrusVegetationLab/` | Shared preparation/fitting core used by Scatter 0.87.0; the [independent Lab 0.3.1](CyrusVegetationLab/experiments/stem-live/GUIDE_031.md) and [historical Lab 0.1.0](CyrusVegetationLab/README.md) retain their own qualification |
| `docs/` | Maintained guidance, contracts, evidence and separately labeled research |
| `tools/rag/` | Local knowledge tooling and [current selection/verification](tools/rag/README.md) |

Edit UI templates/generator modules, never only `AminScatter/scripts/AminScatterObject.ms`. Internal AminScatter names are registration identities. The [native boundary and physics/animation contract](docs/ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries) governs future work; the standalone Physics Lab is separate from integrated Scatter support.

The historical `CyrusScatter-0.86.9.2-Setup.exe` installs Scatter and Analyzer for the selected Max versions. Save and close those hosts first, then reopen after installation. Alternatively use **Scripting > Run Script** with `CyrusScatter-0.86.9.2-Max2027.mzp` and the matching Analyzer MZP, then restart that host. The folder also contains the built, untested 2024/2026 counterparts. Analyzer's standalone MZP uses the same transaction engine as the EXE. Both products retain verified create-only v2 backups and block unknown/custom startup files or registrations. Follow the [installation and recovery instructions](docs/Max_2027_Installation.md). No artist installation or restart was performed. `build/`, `dist/`, `_local/` and `Test Scene/` contain ignored local artifacts and assets, not Git backups; see [workspace organization](docs/Workspace_Organization.md).

# Forest library review: saved content and destination terrain

18 October 2026. Research only. No plugin implementation, version change, installer, installation, roadmap resumption or knowledge-index activation.

This review answers the artist's question about saving a complete planting design and loading it onto a selected terrain. It supplements the [16 October runtime report](FOREST_RUNTIME_2026-10-16.md); that report's Cyrus comparison describes **0.85.2**, not today's 0.86.1 source.

## Main finding

Forest's useful library behavior is an asset-backed planting-style operation: bring the required models/materials and apply selected distribution/appearance settings to a destination Forest object. The selected native implementation preserves destination receiver configuration and most authored Area data. It is not a demonstrated transplant of every saved scene dependency or the source's generated population.

That distinction explains part of our misunderstanding. Saving a Forest object into a `.max` file, applying that object through the Library, and restoring the original scene are different operations. We must not infer automatic curvature-producer reconstruction or arbitrary Paint transfer from the phrase "complete preset."

## Evidence and qualification

| Evidence | Scope |
| --- | --- |
| Official documentation checked on 18 October | General parameter presets, library entry authoring, asset collection, thumbnails, creation workflow and map-coordinate requirements; documentation is separate from executable observations |
| Fresh Ghidra/MCP reinspection | Four previously identified core functions, 11,243 decoded bytes / 2,521 instructions; all decompilations complete and instruction listings match the earlier exports |
| Existing Max runtime evidence | Forest Pack Lite 9.4.3 / native 9,4,3,766 in Max 2027 / 29.1.0.11426 on 16 October; actual catalog Load actions, model/preset distinction and save/reopen witnesses |
| Current Cyrus inspection | 0.86.1 working-tree templates/codecs and eight inventoried examples; branch `codex/workflow-0.75`, HEAD `56b6e09`; product changes were already uncommitted |
| Not performed in this review | New Max launches, Forest Pro user-library authoring, missing-channel/curvature/Paint-transfer runtime fixtures, renderer tests or performance measurements |

The core pin is SHA-256 `23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d`, image base `0x180000000`. The installed GitHub-derived tool is Ghidra 12.1.4 with bethington Ghidra MCP 6.0.0, used through its isolated loopback backend. The GitHub repository connector itself is not a binary decompiler. No tool installation or upgrade was needed.

Fresh raw exports, requests, eight structural checks, preservation checks and shutdown receipt are private ignored evidence under [the owned analysis run](<F:/Cursor/_Cyrus_Apps/Forest Reverse/build/library-portability-20261018-01>). They may be unavailable in another checkout. Long vendor decompiler listings are not reproduced here. The copied Ghidra project was saved/closed and only the verified owned backend was stopped.

## 1. Forest has several different reusable-content operations

| Operation | Purpose and established boundary |
| --- | --- |
| General parameter preset / `.fpe` / `forest_presets.ini` | Numeric/options reuse. This is not the asset-backed planting library. The manual describes retained external references; the earlier static serializer analysis found narrower exclusions, so universal reference preservation still needs runtime qualification |
| Plain 3D library entry | Supply a model from an external `.max` file. In the earlier runtime fixture, loading Wild grass replaced only the selected Geometry slot and retained the other slots/style |
| Forest library preset | A catalog entry refers to a completed Forest object in an external `.max` file. It supplies geometry and selected planting-style data; source acquisition is followed by selective application |
| Effect template / `.eff` | Reuse an effect definition through the effects workflow. It is not the whole planting setup or its authored population |
| Original scene save/open | Host persistence of the actual scene/object graph. Persistence of a source object's data does not prove the Library applies all of that data to a different target |

Sources: [General](https://docs.itoosoft.com/forestpack/forest-plugin/general), [Library Browser](https://docs.itoosoft.com/forestpack/forest-library/library-browser), [Effects Library](https://docs.itoosoft.com/forestpack/forest-plugin/effects/effects-library), [parameter serializer analysis](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/33_PARAMETER_PRESET_SAVE_LOAD_APPLY.md>), [effect/library boundaries](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/35_EFFECT_AND_LIBRARY_PRESET_BOUNDARIES.md>).

## 2. What Forest saves for the library

Official authoring procedures support adding selected scene objects, including a Forest object and its sources. The authoring operation can create a `.max` file, a separate material library, collected external assets and viewport thumbnails. An existing external `.max` object can also be registered as an entry. The catalog uses an XML index and thumbnail folders; user-editable libraries are Pro-only. [Official editing documentation](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library).

Thus library metadata, saved scene assets and external files are separate resources. A thumbnail is an index preview, not the planting data. The prior read-only catalog study found 17 indexes, 341 indexed entries and 21 callback declarations; these counts do not mean every entry is a loadable preset or has passed import tests. [Catalog/reference research](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/40_LIBRARY_REFERENCES_AND_LIFECYCLE.md>).

This review did not save a custom Forest library entry: the local installation is Lite. The documented Pro authoring workflow remains distinct from our measured destination-scene save/reopen tests.

## 3. What Forest loads and retains

The earlier catalog trace connects Use Items/double-click/Enter to native parent dispatch. Creation queues use a shared acquisition helper; the selected queue consumer is not a full-object clone. Native `.max` acquisition uses Max object-XRef machinery; a Merge outcome can subsequently merge the acquired record. Model references and materials are repaired/processed around style transfer. [Detailed path](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/38_LIBRARY_MAX_IMPORT_APPLY.md>).

Freshly reinspected core RVAs:

| RVA | Selected responsibility |
| --- | --- |
| `0x129580` | Parameter/style transfer, five curve graphs, bitmap refresh and validity invalidation |
| `0x131e40` | Consume queued creation entries through the shared acquisition route |
| `0x12e760` | Resolve/acquire entries and managed templates, apply Forest style, material/merge/hook stages |
| `0x124790` | Native `.max` validation and XRef-based scene acquisition |

The transfer helper's block policy remains:

| Saved content | Selected target behavior |
| --- | --- |
| Geometry/source tables | Eligible for replacement/transfer; this changes the existing Forest's source collection |
| Distribution and transform settings | Eligible with explicit distribution-reference exclusions |
| General/root seed | Entire destination General block retained |
| Surface configuration | Entire destination Surface block retained; this includes more than just the terrain reference |
| Area data | Only nine density/scale/falloff controls assigned; this is not a complete copy of source Area records |
| Effects | Model parameters eligible; compiled VM/runtime caches are not explicitly copied |
| Authored custom scatter items | No explicit collection copy in the selected style/queue helpers; mode assignment alone does not establish item transfer |

This is a scoped native policy, not a guarantee about every callback or Pro entry. Five authored curve graphs transfer; bitmap-derived storage is refreshed and output validity is invalidated. Saved seeds or generated placements are not evidence of an identical result after changing terrain, models or distribution inputs. [Seeds/effects/custom-item qualifications](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/39_LIBRARY_SEEDS_EFFECTS_CUSTOM_ITEMS.md>).

The official creation guide describes choosing a ready scatter and then assigning an area/surface. That supports the simple artist workflow, without promising arbitrary dependency adaptation. [First scatter](https://docs.itoosoft.com/forestpack/getting-started/first-scatter).

### Earlier actual Max observations

The [durable runtime receipt](FOREST_RUNTIME_2026-10-16.json) records thirteen snapshots, 72 raw evidence files and two saved-scene witnesses:

- Common grass 01 (detail) brought one hidden source mesh and its material, retaining the existing Forest and receiver.
- Common grass 01 (large) brought three sources and changed distribution settings. Root seed 54321 and receiver survived; the saved/reopened fixture retained 105 generated items.
- Loading Wild grass 09 as a model replaced only the selected source slot, preserving the other sources and the planting style.
- A fresh XRef model load produced a resolved XRefObject and survived save/reopen. Selecting XRef on an already merged source did not convert it in the earlier warm-source fixture.
- The tested preset source materials included MultiMaterial/PhysicalMaterial; 36 consumed bitmap maps resolved through Max. No renderer/pixel qualification follows.
- Actual preset Load changed Manual to false and cleared preceding Undo history in that fixture. The helper's exclusion of `manualupdate` did not predict the whole UI operation. We should preserve Cyrus's stronger transaction/history requirements rather than copy this side effect.

These are historical runtime observations, not tests rerun on 18 October. The current review rehashes their 72 raw files and two scene witnesses before relying on their stored results.

## 4. Channels, curvature, Paint and terrain are not interchangeable

Forest's map documentation requires appropriate surface mapping for the chosen coordinate mode. It supports world/distribution-image sizing as well as surface map coordinates; ordinary portable styles need not depend on an artist-created channel 2. [Image mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode).

Earlier native channel research establishes a consumer route for positive mesh-channel values. For curvature stored in a channel, the numeric meaning comes from the evaluated mesh; the channel number does not compute curvature. [Curvature channel analysis](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/65_CHANNEL7_CURVATURE.md>).

The selected Library style path retains destination Surface configuration and transfers only selected Area controls. It does **not** establish automatic copying of the old terrain's Data Channel modifier stack, generation of missing destination channels, transfer of arbitrary Paint footprints, or remapping of a full authored item population. None of those cases was executed in the earlier runtime campaign. Missing native channel lookups producing zero in some selected sampling paths also do not prove the Library offers a deliberate graceful fallback.

Forest documents Paint Areas and conversion to/from splines, but a Paint editing feature is not evidence of library portability. [Areas documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas). Callback scripts can extend catalog behavior; the finite inspected script set is not a proof about every user entry.

The important conclusion is limited: **we have no evidence that Forest solves the current Cyrus channel/Paint portability problem by reconstructing arbitrary terrain modifiers automatically.** A Pro authoring and cross-terrain fixture is needed before claiming that behavior.

## 5. Comparison with current Cyrus 0.86.1

Authoritative sources inspected: [recipes](../../../AminScatter/tools/ui/templates/recipes.ms), [ready loading](../../../AminScatter/tools/ui/templates/preset-loading.ms), [asset capture/import](../../../AminScatter/tools/ui/templates/assets.ms), native package/recipe codecs and [the bundled inventory](../../../AminScatter/library/inventory.json).

| Concern | Forest evidence | Current Cyrus behavior |
| --- | --- | --- |
| Ready assets | Supplied in measured preset loads | All eight inventoried examples now have ready-package manifests; the 0.85.2 absence reported on 16 October is historical |
| Destination | Retained receiver in tested style application | Captured selected terrain is authoritative; creates a setup or adds layers to its unambiguous owner |
| Existing planting | Applying a preset changes the target Forest's source/style data | Adds new layers and preserves existing layer/settings ownership; this is the user's deliberate Cyrus choice, not exact Forest equivalence |
| Seed | Root seed retained in measured loads | Direct ready Load explicitly requests New variation; selective Apply Style has Keep/Saved/New policies |
| Full design save | External Forest object and supported dependencies through Max | Complete supported layer settings, Paint, static assets and paths; evaluated terrain snapshot includes captured channels |
| Terrain producer stack | No proven reconstruction on destination | Terrain snapshot is explicitly not a serialized modifier stack |
| Channel requirement | Full missing-channel library outcome untested | Direct Load samples the destination channel; any capture exception becomes the generic channel-required message |
| Paint | Cross-terrain library behavior untested | Complete coverage saved, but restore checks compatible geometry/frame/saved units; no arbitrary transfer |
| Materials/XRefs | Broader material classes and fresh XRef observed | Closed static mesh/Standard-Blinn/PNG package adapter; broader renderer graphs/XRefs remain pending |
| Undo/Manual | Historical tested Load lost prior history/Manual | Existing explicit publication/Undo and Manual contracts should be retained; no new Cyrus host qualification in this review |

The current errors reveal two different boundaries. Missing a matching `cyrus.package.json` is classified as "settings-only" even though a missing/moved package can cause the same branch. Channel-capture failures are all classified as needing the selected channel, even though the native capture can also reject unsupported/incomplete geometry or other channel data. This research does not establish which underlying exception occurred in the artist's scene.

### The eight bundled examples

Read directly from the inventoried recipe files; every listed ready manifest was present locally:

| Entry | Layers | Enabled channel mask | Saved Paint documents |
| --- | ---: | --- | ---: |
| Layered meadow | 3 | None | 0 |
| Trees and understory | 3 | None | 0 |
| Mountain planting | 2 | None | 0 |
| Painted garden and spline borders | 2 | None | 1 |
| Rectangular orchard | 2 | None | 0 |
| Hexagonal hillside planting | 2 | None | 0 |
| Four garden rooms | 3 | None | 3 |
| Valley moss and rocky crests | 3 | Channel 2 / R-X in all three layers | 0 |

Absence of those two dependencies does not prove universal suitability: paths, explicit grid origins, units and other adapter limits still apply. In particular, Valley moss is a channel-driven demonstration, not evidence of a curvature generator that follows any new terrain.

## 6. Recommendations, not implemented changes

1. Keep the main artist action simple: select terrain, choose a planting entry, Load. Preserve the user's add-as-new-layers behavior and all existing authored data.
2. Distinguish reusable planting-style application from complete authored-design restoration in the operation contract. Store complete Paint/context as requested; do not silently discard them to make loading succeed.
3. Make general starter styles usable without undocumented terrain preparation. Display specialized channel/Paint/path dependencies on the entry before Load; describe terrain-specific examples honestly.
4. For channel-driven designs, distinguish a saved channel reference, captured values on original geometry and an executable producer recipe. Only the last can recalculate the intended field on a different terrain. A supported producer adapter or deliberate transfer rule would be future work; generic modifier cloning should not be assumed.
5. For Paint, define an explicit transfer coordinate/frame policy before supporting different geometry. A complete save must retain original coverage even when a particular destination cannot use it.
6. Keep actionable diagnostics: missing assets, incomplete packages, missing channels and incompatible Paint should be separate cases with the underlying failure preserved.
7. Retain Cyrus's atomic publication, Undo/Redo, content checks and Manual/Live behavior. Reproduce Forest's useful asset-backed loading without reproducing the measured history loss.

This review does not authorize these implementations or unpause the roadmap. It corrects the assumptions to use when the next implementation scope is chosen.

## 7. Remaining tests needed for stronger Forest claims

- Pro user-library Save, asset collection, thumbnail and reload, using one actual custom entry.
- Load the same entry onto different terrain with and without the expected channel; inspect the receiving mesh/channel values and all modifier stacks before/after.
- Separate UV-dependent density textures from numeric vertex/channel masks and curvature producers; measure the actual resulting distribution rather than just successful import.
- Painted/include/exclude areas and custom items on same versus changed geometry; compare authored records, frames and source mappings.
- New creation versus applying to an existing populated Forest, including prior Undo, Manual mode, repeated load, failure/cancel and unavailable source files during Redo.

The current Lite installation and selected static paths do not qualify those Pro workflows. No licensing restrictions were bypassed.

## Prompt for an independent AI investigation

```text
Investigate Forest Pack's preset and Library Browser system, focusing on what is actually saved and what happens when an entry is loaded onto a different surface.

Our project:
F:\Cursor\_Cyrus_Apps\CyrusScatter

Existing Forest research:
F:\Cursor\_Cyrus_Apps\Forest Reverse

Read applicable AGENTS.md files and existing evidence first. Use the available GitHub/Ghidra tools, official Forest documentation and, where available, controlled Max tests. Do not change Cyrus code or installed plugins. Preserve artist scenes. Clearly separate documented behavior, static binary evidence, runtime observations and inference. Identify the Forest version/build behind each finding.

The artist workflow we want is:
Select terrain -> open library -> choose a saved planting design -> Load.
The plugin imports required models/materials and creates saved layers/settings on that terrain, preserving existing planting.

Investigate:
1. Distinguish settings presets, effects/templates, individual library assets and complete planting/library entries. Which operation matches our goal?
2. For each type, determine whether it saves source geometry, materials, textures, distribution settings, seeds, surfaces, splines, maps, painted/custom items, modifier stacks and generated placements.
3. Trace Save, indexing/thumbnails, selection, Load, asset merge, reference remapping, surface assignment, invalidation and Undo.
4. When applying to an existing populated Forest, which fields/assets are added, replaced, preserved or cleared? Compare new-object creation. Do not equate one Forest object with Cyrus's ordered multi-layer setup.
5. What happens to original receiving terrain? Is it packaged, merged, ignored or replaced by destination terrain?
6. Investigate a density texture requiring UV/map channel 2; Data Channel curvature; VertexPaint/mesh-channel values; painted coverage; include/exclude splines; custom placements. Does Forest recreate the producer, transfer/bake output, retain a reference, request binding, disable an option or report a missing dependency?
7. Does different-terrain loading restore exact placements or reuse rules and calculate a new result? Explain coordinate frames, units, scale and seeds.
8. Compare current Cyrus Save Recipe, ready-package capture and direct selected-terrain Load from authoritative source, not docs alone. Preserve the artist's requirement to save Paint too.

For runtime work use a disposable Max 2027 scene/profile and genuine available Forest entries. Test a plain plane, different terrain, an existing populated object, missing channel 2, a custom saved entry and Undo/Redo. Record exact actions/results and loaded identities. Do not label static checks as runtime tests. If access/licensing prevents a test, report it unverified; do not bypass it.

Deliver a plain-language Save/Load explanation; an evidence table with links, file paths and function identifiers; a current Cyrus comparison and corrections to our assumptions; recommendations for the simplest reliable artist workflow; and explicit unknowns/tests. Do not assume arbitrary Paint transfer or Data Channel modifier reconstruction. Do not implement anything.
```

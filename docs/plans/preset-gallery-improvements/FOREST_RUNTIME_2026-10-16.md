# Forest library: actual Max tests and Cyrus comparison

16 October 2026. **Research only; no product implementation, version change, installer, installation or push.** This report follows the user's request to use Forest itself before proposing another library implementation. It supplements the earlier static investigation; it does not rewrite its historical receipts or authorize roadmap work.

**Finding:** the tested Forest presets supply their models and materials, and apply a planting style to an existing Forest object while retaining its receiver and root seed. Our bundled gallery currently opens complete **settings recipes with external model roles**. Our portable asset importer exists separately, but the bundled examples are not those packages. The difference is functional, not a thumbnail-layout problem.

## Evidence and scope

- Forest Pack **Lite 9.4.3**, native file version **9,4,3,766**; Max **2027 / 29.1.0.11426**. This does not qualify Forest Pro or another release.
- Cyrus source **0.85.2**, branch `codex/workflow-0.75`, HEAD `5aee4ef2242307b92e16c96e0106ee095d6a4215`.
- Actual library interaction used the Geometry rollout's **Library** button, selected installed available entries and clicked **Load Selected**. MAXScript/pymxs captured scene state and exercised Update/save/reopen. No licensing restrictions were bypassed.
- Tests used owned disposable scenes/profile, PID 46868, under [the private host directory](../../../build/mcp-qualification/foundation-roadmap-forest-library-20261016-02). That process was closed after testing; closure marker and process absence were checked. No other Max process was controlled by these tests.
- [Durable evidence](FOREST_RUNTIME_2026-10-16.json) embeds 13 state snapshots, loaded-module identities, material/map observations and hashes of 72 raw files plus two scene witnesses. Raw binaries/scenes remain ignored local evidence, not Git backups.

The loaded core SHA-256 is `23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d`; the evidence pins the actual catalog/Qt modules too. All **134** baseline installed/catalog/script files and **155** Cyrus native-receipt source inputs rehashed unchanged. This is preservation evidence, not a fresh Cyrus release certification. Consumed vendor `.max` assets were not pre/post hash-qualified; vendor UI preferences stored outside the private Max profile were not baseline-compared.

## What Forest actually did

The main fixture used one flat receiver and one existing Forest object, seed **54321**, frame **0**. Terrain began at 4 m × 4 m; Undo sentinels made small dimensional edits. Counts below belong to the captured fixture state, not a benchmark across identical dimensions.

| Operation | Measured result | Meaning / limit |
| --- | --- | --- |
| Load **Common grass 01 (detail)** | One hidden `Editable_mesh`, assigned `_fp_grass` MultiMaterial, in `forest_templates`; existing Forest and receiver retained | Models/materials came from the entry. No manual source binding was needed |
| Repeat that preset | Scene object count stayed three; source handle changed **38 → 76** | Cleanup avoided accumulating source nodes in this fixture. This was **not** an identical-node reuse pass |
| Activate existing Surface Area and explicitly Update | **15,449** generated items and visible point preview | The scripted starting object had an inactive Surface Area. Source import success and coverage activation are separate |
| Open library, then select **Common grass 01 (large)** | Source handle, root seed, Manual setting and preceding Undo sentinel remained unchanged through opening/selection | Selection was not application for these inspected fields. No engine-counter claim follows |
| Click **Load Selected** for large | Source table changed from one to **three** hidden meshes; **105** generated items; distribution changed to `full.bmp`, units X **3960**, Y **10000**, threshold **50** | The preset supplied geometry and distribution style together |
| Save/reopen large witness | Three sources, receiver, seed and **105** items retained | Actual Max persistence round trip; system units centimetres, scale 1 |
| Select first Geometry slot, load **Wild grass 09**, **Merge into scene / Use Scene Material** | First source **115 → 124**; remaining **116/117** unchanged; material handle **56392** retained; distribution and Area state retained | Plain model loading replaces the selected source slot; it did not apply a whole planting preset |
| Select XRef for the already merged Wild grass source | Source remained handle **124**, `Editable_mesh` | Changing the option did not convert this existing managed source into an XRef in this fixture. Exact reuse cause was not isolated |
| Reset owned scene; load Wild grass into a fresh Forest with **XRef to library** | Real `XRefObject`, one resolved Max XRef record pointing to `3D/Flowers and grass/objects/_fp_grass.max` | Initial XRef loading works. This resolves the uncertainty left by the warm-source test |
| Save/reopen XRef witness | XRef source and resolved record retained | Persistence established for this one external dependency |

The large preset's three sources shared `_fp_grass`, a MultiMaterial with five **PhysicalMaterial** submaterials. All **36 consumed BitmapTexture objects** resolved to existing files through Max's map-path resolution. Arnold was current; **no render or pixel qualification ran**. Resolving files does not establish correct shading in every renderer.

### Scheduling and Undo: an important correction

Before both repeat/detail and large loads, the fixture set `manualupdate=true` and created a preceding Undo sentinel. For the large test, snapshots before opening, after opening and after selection retain both. After actual Load Selected, **Manual was false and the preceding Undo history was empty**.

The older [style-copy analysis](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/38_LIBRARY_MAX_IMPORT_APPLY.md>) says its selected helper excludes `manualupdate`. That helper observation is insufficient to promise the complete UI operation retains Manual. The runtime result qualifies the tested outer route; it does not identify the exact writer or prove every Forest library operation behaves this way. Likewise, this report does not claim Forest offers a single reversible apply transaction.

Our future parity work should reproduce the useful loading behavior while retaining our explicit Manual/publication and Undo contracts. Copying the observed history loss is not a requirement.

## How the library logic fits together

Forest's public browser separates billboards, external `.max` models and Forest presets. Model import supports Merge/XRef and duplicate-material choices. Its manual describes presets as reusable distribution/appearance styles and says Areas/Surfaces may need adjustment. [Official browser documentation](https://docs.itoosoft.com/forestpack/forest-library/library-browser).

The [local static trace](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/38_LIBRARY_MAX_IMPORT_APPLY.md>) supplies the deeper connection:

1. The catalog holds entry metadata, source file/object names, thumbnails and options. Selecting an item resolves a catalog entry; it is not the population itself.
2. Catalog Load dispatches to the selected Forest object. A separate queued-creation route exists statically; it was not qualified by this campaign.
3. Native `.max` acquisition initially uses Max's object-XRef machinery. A Merge outcome can subsequently merge the acquired record into the scene. Therefore the final `Editable_mesh` class does not prove acquisition bypassed XRefs.
4. A plain geometry entry supplies a model to a Geometry slot. A Forest entry supplies models plus selected style fields, curves and distribution data. The trace excludes General/root variation and receiver configuration from its selected style-copy stage.
5. Source resolution repairs model bindings. Material processing follows style transfer, and catalog callbacks can contribute renderer/material/path behavior. Hidden source nodes are managed in `forest_templates`; the selected static lookup uses catalog identity markers and names.
6. Target invalidation/rebuild follows application. Saved source geometry, authored parameters, receiver captures, compiled effects and the final generated population are different state classes. Importing the first two is not proof that published placements or runtime caches were copied.

Our runtime results corroborate model supply, selected-slot replacement versus preset replacement, root-seed/receiver retention, hidden-source management, materials and initial XRefs. Effects, custom-item remapping, nested Forests, groups and source-file freshness remain static or untested boundaries. **A matching catalog/name tag is not a demonstrated content fingerprint.** See [ownership/lifetime research](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/40_LIBRARY_REFERENCES_AND_LIFECYCLE.md>).

### Saving is a separate qualification boundary

Forest documents saving selected objects, including a Forest preset and its sources, to an external `.max` file; material libraries, collected dependencies and viewport thumbnails are separate parts of that authoring workflow. User-library editing is **Pro-only**. It also supports configurable local/network library locations. [Official editing documentation](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library).

This installation is Lite, so **no Forest user-library save/editor round trip was attempted**. Saving and reopening our disposable destination scenes tests scene persistence, not Forest catalog authoring. The existing catalog/index research is substantial but its **17 indexes / 341 entries** does not mean 341 imports have passed.

## Comparison with the current Cyrus implementation

Direct source anchors are the authoritative [recipes template](../../../AminScatter/tools/ui/templates/recipes.ms), [assets template](../../../AminScatter/tools/ui/templates/assets.ms), [package contract](PACKAGE_CONTRACT.md) and [bundled example documentation](../../../AminScatter/library/README.md). No generated-only fix or product edit was made.

| Concern | Forest evidence | Cyrus source today | Assessment |
| --- | --- | --- | --- |
| Thumbnail gallery | Tested catalog navigation/selection/load | Collection tree, tiles, search and thumbnails exist | Similar presentation does not establish loading parity |
| Bundled preset models | Detail/large brought one/three models automatically | Bundled entries are `.csrecipe.json` plus presentation/Paint payloads, without `cyrus.package.json` asset manifests | Main everyday gap |
| Existing terrain | Receiver retained in tested style loads | Complete recipe opens every saved role unbound; user assigns terrain and sources | Our current default action is recipe transfer rather than Forest-style apply |
| Plain model library | Wild grass replaced only selected Geometry slot | Package import adds layers/sources; Apply Style retains destination models | Equivalent selected-model library replacement is missing |
| Style application | Selected style and source table transferred | `CyrusStylePrepare/Commit` transfers selected groups, retaining terrain, sources, Paint, Bands and relationships | Useful foundation; not equivalent to Forest's model-backed style load |
| Material/dependency scope | MultiMaterial/PhysicalMaterial and resolved external maps observed | Closed static mesh + Standard/Blinn + supported PNG adapter; scene-source reuse is explicit | Forest test assets exceed our portable material adapter |
| XRefs | Fresh model XRef and reopen passed | `CyrusAssetReview` rejects XRef policy; only clone/share supported | Real capability gap |
| Multiple Cyrus layers | No direct equivalence tested | Complete recipe preserves ordered layers and spacing relationships | Keep the existing multi-layer contract; do not equate one Forest object to all Cyrus layer semantics |
| Paint | Transfer semantics not tested in Forest | Complete recipe/package retains saved compatible receiver-bound Paint | Preserve Save Everything, including Paint; Forest style behavior does not authorize dropping it |
| Apply safety | Source acquisition/global side effects only partially qualified; Undo history loss observed | Held authored import, dependency checks, rollback, Manual retention, content/review guards and supported no-op paths exist | Retain these foundations; their broader acceptance remains scoped to existing receipts |

The gallery's Load handler explicitly routes a folder with `cyrus.package.json` to `CyrusOpenAssetImport`; otherwise it calls `CyrusOpenRecipeLoad`. That latter dialog starts every role as `undefined`, suggests only unique matching scene names and labels its action **Add layers** or **Create new setup**. This explains both the user's manual model-picking experience and the missing-looking “Load” button: the scene-edit button is named for recipe import.

It would be inaccurate to say Cyrus has no asset packaging. `CyrusAssetStage` already creates supported independent meshes/materials/maps and supplies their roles to recipe import. The gap is the supported content, bundled delivery and existing-target operation, not a need to discard the working serializer/gallery.

### Why the user's channel-2 error occurred

[Valley moss and rocky crests](../../../AminScatter/library/2b0a6ec1-2638-415c-a511-13b6037c5c5e.csrecipe.json) enables `meshMaskEnabled` on all three layers, selecting **channel 2, component R/X**. The rock layer inverts that field. Its demonstration terrain contains an authored numeric map; the recipe stores the channel selection and response, not arbitrary replacement terrain's vertex data or a curvature-producing modifier stack.

`CyrusRecipeImport` calls `cyrusMeshDensityKey` on bound receivers before appending imported layers. [The native reader](../../../AminScatter/src/mesh_density_bridge.inc) rejects missing/incomplete maps rather than interpreting them as valid zero. Consequently a plain plane with no channel 2 fails even after every model role is bound. The check protects the previous result; **the gallery did not make this terrain requirement clear or provide a prepared compatible receiver through that action**.

The tested Forest grass presets use supplied distribution bitmaps and did not require creating channel 2 on our flat receiver. That observation does not prove Forest can make an arbitrary curvature-dependent preset portable without its producer/data. Future Cyrus behavior must distinguish included asset dependencies from receiver-dependent fields before commit, rather than silently disabling a mask or inventing channel values.

## What the new receiver-cache research changes

The supplied [68 summary](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/68_SAME_FRAME_CHANNEL_INVALIDATION_SUMMARY.md>), [69 notification audit](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/69_RECEIVER_REFERENCE_NOTIFICATIONS.md>), [70 refresh analysis](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/70_SHARED_RECEIVER_REFRESH_AND_MANUAL.md>) and [revision proposal](<F:/Cursor/_Cyrus_Apps/Forest Reverse/design/21_RECEIVER_CHANNEL_REVISION_SPEC.md>) distinguish output invalidation from receiver-mesh refresh. Their selected same-frame refresh path requires pending/force state; invalid output alone is insufficient. Their modern VertexPaint/Curvature notification campaign remains unexecuted here. Forest also publicly documents shared terrain caching, explicit Update and Auto. [Official Surface documentation](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).

Current Cyrus is not simply the same time-only gate:

- `markInputDirty` clears input/orientation validity; the NodeEventCallback registers geometry, topology and mapping changes. Relevant dependency classification precedes dirtying, and Live batch callbacks consolidate redraw requests.
- `procPlanReceivers` obtains geometry and enabled mesh-field content keys. `cyrusMeshDensityKey` evaluates/converts the current receiver and hashes selected per-face corner values. `cyrusMeshDensityFilter` independently captures those values again on a cache miss; sampling then interpolates the selected component and applies range/inversion/curve/deterministic acceptance.
- The receiver result key includes geometry and mesh-mask keys. Complete receiver-cache replacement happens after receiver preparation succeeds. This is existing source behavior, not a new same-frame runtime pass.

There is a concrete optimization opportunity: **key construction and a subsequent filter miss can recapture the same channel, and layers do not receive a shared immutable snapshot token through these APIs**. It does not mean channel reads happen continually while idle. Counters must measure relevant-event capture, cross-layer reuse and idle avoidance before changing this logic. Hashing effective selected corners also differs from storing separate support/map-face/all-vector revisions; equal effective scalar content can be reusable, but structural diagnostics and other consumers need their own keys.

Future parity qualification needs actual modern VertexPaint/map0 and Curvature→map7/X at unchanged time, raw evaluated data plus event/capture/solve/upload counters, Manual/Live/shared consumers, support removal/recreation and forced Update. Mesh channel 7, SDK validity category 7 and notification masks are different namespaces. No library import result in this report closes those gates.

There is also a documentation discrepancy: report 38's numeric block labels and report 69's later Surface registration labels differ. Their numeric tables should not be combined without reconciling the preserved descriptor/transfer evidence. This report uses runtime property names and qualified semantic findings instead of guessing the mapping.

## Requirements established before coding

These are proposed acceptance requirements derived from the evidence, not implemented features or a new authorization:

1. **Loadable asset-backed entries:** a preset entry supplies its own permitted models/materials/maps. Declare any external receiver/channel/path dependencies before scene mutation. Ship actual packages for the supported subset instead of presenting only settings recipes as Forest-equivalent presets.
2. **Two context-sensitive operations:** a model entry replaces/adds the selected source; a planting-style entry applies to the intended existing layer/setup with an explicit retained-field contract. Keep complete multi-layer Save/Load, including Paint, as its existing distinct capability.
3. **Retained destination context:** preserve terrain, compatible authored Paint/Areas, Manual policy and destination variation according to the reviewed operation. A new setup still needs a terrain choice. Do not claim matching seeds guarantee matching placements after changing models/terrain/masks.
4. **Qualified asset/material ownership:** import or reuse through declared policies; add native `.max`/broader materials/XRefs only with host adapters and dependency-lifetime tests. Never infer share/replace rights from matching names or copy vendor vegetation into Cyrus distribution.
5. **Transactional application:** cancel/failure leaves preceding authored state and complete publication intact; one successful authored operation supports Undo/Redo without reloading source files or rerolling variation. Preserve prior Undo history and Manual pending behavior.
6. **Bounded performance:** browsing only reads catalog/thumbnail data. Measure asset evaluation, channel capture, source preparation, solve and upload separately; repeated identical application requires content validation and no-op evidence. A stable object count is insufficient proof of a cache hit.

The next implementation plan can build on our current gallery, recipe transactions and supported package importer. It must qualify these visible behaviors against the actual Forest witnesses before claiming parity. Pro authoring, renderer variants, nested XRefs/effects/custom populations and modern modifier event delivery remain explicit open work.

## Reproduction and limits

Open [Forest library large witness.max](<../../../build/mcp-qualification/foundation-roadmap-forest-library-20261016-02/project/scenes/Forest library large witness.max>) or [Forest XRef model witness.max](<../../../build/mcp-qualification/foundation-roadmap-forest-library-20261016-02/project/scenes/Forest XRef model witness.max>) only in a disposable Max 2027 profile with the matching installed Forest. The XRef witness needs its recorded installed library path. [Point-preview screenshot](../../../build/forest-library-runtime-20261016/grass-loaded.png) shows the detail fixture after coverage activation. Snapshots/requests and hashes are listed in the durable evidence.

The first private launch failed to establish readiness and is not a pass. Initial standalone-catalog/double-click attempts did not perform the accepted import; acceptance uses the actual Geometry Library → Load Selected route. An initial bitmap enumeration included unrelated material-library maps and unresolved relative paths; the targeted 36-map, Max-resolved successor supersedes it. Exploratory interface/indexer errors were fixture errors, not product failures. They were not used as acceptance evidence.

This campaign does not establish general Forest performance, Pro library editing, arbitrary material correctness, cancellation/rollback, multi-selection, cloning, custom-item/effect transfer or same-frame modifier freshness. It also does not certify all current Cyrus contracts. The report records the narrower tests, source facts and remaining requirements without treating the research plan as implementation.

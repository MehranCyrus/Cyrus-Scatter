# Cyrus Arrange asset library

Register one prepared accessory model per entry, then reuse it on the furniture categories and surfaces you allow. Keep its live source when generated objects need the original materials and mapping. For the overall workflow, start with the [arrangement quick start](ARRANGE_QUICKSTART.md); individual book rows have a separate [artist guide](BOOK_ROWS.md).

This document describes the retained detailed library and the **Cyrus Arrange
0.3.1** quick intake workflow for Max 2027, introduced in 0.3.0. Use native
modules and UI from the same package. Current qualification, including the
passed installer and installed-startup gates, is recorded in the [0.3.1 report](RELEASE_VALIDATION_0.3.1.md).
Historical packages and receipts identify their original pairs.

## Quick bulk intake and decor groups

Open **Props...** from the main window or a bound icon's native Modify panel.
Both views edit the same arrangement's catalog. Select several source models or existing groups,
choose their shared type and press **Add selected props**. Native code normalizes
the selection and stages the entire batch before one catalog commit. A selected
outer group remains one asset. Existing source entries are skipped without edits.
Individual entries can be given different categories afterward in the detailed
library. Each catalog is limited to 256 entries.

For a composed reusable prop, position its pieces first, select at least two
models/groups, enter its name and press **Create decor group**. This copies the
pieces into a new scene group and adds it as one physical-size source asset.
Original source nodes and their hierarchy remain intact. Select the new group
to add it to another setup; each setup owns its own metadata and generated result.
Save the Max scene to retain the source hierarchy and materials. Generated output
uses one flattened mesh per placement, preserving the evaluated group appearance
under the existing material adapter.

Both commands require independent mesh models or complete Max groups. Convert
ordinary parent/child assemblies into a complete Max group first.

Both commands are atomic and support Undo/Redo. Invalid or forbidden members
reject the complete command. Ownership is determined from actual source bindings,
not names. Furniture, obstacles, setup owners and generated outputs are excluded.
Group creation preserves relative positions; it does not arrange scattered source
pieces into a new composition. Geometry-only portable library limits below remain.

## Register an accessory

Open **Asset Library** from an Arrange setup, or call `caShowAssetUI setupNode` after loading `scripts/ArrangeAssets.ms`.

1. Select one accessory model or its group head and press **Use selected model / group**. An upright book and a flat book are separate prepared models. Prepare each source upright on its intended base, with a consistent front direction, before registration.
2. Choose the category and allowed furniture. Set permitted yaw angles as a short comma-separated list, a selection weight and an allowed uniform scale range. Leave both scales at 1 to retain physical size.
3. Enable **Has a stable flat top for stacking** only for a suitable prepared prop, such as a flat book. The host checks the derived top patch against actual horizontal source triangles. This is authored metadata with geometric validation; checking it is not a physical stability simulation.
4. Press **Register new asset**. Native code snapshots the evaluated model assembly in millimetres and retains the source reference. The source geometry is preserved. Registration belongs to the setup and participates in Undo.

The panel lists the stable asset ID, name, category, local physical dimensions and source state. **Refresh library list** reads metadata; it does not recalculate arrangements. Select a row to load its metadata, edit the fields and press **Update selected metadata**. This preserves the asset ID and captured mesh. Choosing a scene model with **Use selected model / group** starts a new registration instead. Closed groups and nested groups are reduced to their selected outer group root; unrelated selected assemblies remain an error.

The source states are **live scene source**, **stored geometry** and **MISSING scene source**. A deleted scene model is distinct from an intentionally imported library asset. A missing required source prevents Generate and source refresh, retaining the previous complete result. Select a replacement model and press **Rebind to selected model** to preserve the asset ID and metadata while validating the replacement geometry. Alternatively, **Use stored geometry** explicitly detaches the source requirement and keeps the captured mesh. Matching source materials are then unavailable for subsequent generation.

**Remove asset entry** preserves artist source models. When an asset is in use, enable **Also remove generated outputs, their complete book rows and supported stack children** to remove it together with its owned placements, including dependent children from another asset. The native command publishes the catalog, bindings and output removal in one Undo operation. Without that explicit option, an in-use asset is retained and the command reports why removal failed.

For generated Book rows, removal also removes the complete affected relationship and all its member outputs, even members using another catalog asset. Those other catalog assets remain registered. Undo restores the catalog, group records and real output references together; a partial row is not retained.

Current categories, in the one-based order used by MAXScript, are Book, Book stack, Plant, Candle, Frame, Vase, Accessory, Bowl, Tableware, Kitchenware and Tray. A book stack is a prebuilt asset. A flat Book can also participate in a generated stack. The initial stacking recipe permits Book children only when their prepared height is at most 0.75 times their smaller horizontal dimension; upright books remain available as individual props. This is a deliberate initial recipe heuristic.

Furniture eligibility combines the asset's allowed furniture, the setup's **Allowed-category rules** and each surface's allowed categories. For example, the TV console preset includes books, plants, candles, frames and decorative objects; kitchenware belongs to the kitchen counter preset. A category maximum of zero disables it. Setup density, spacing and edge gap remain the artist's placement controls; preset record fields do not silently replace those settings.

**Selection weight** belongs to an individual asset. Its effective draw weight is its own weight multiplied by its category's weight. With three eligible Book entries and one Vase entry, all asset and category weights set to 1 give books three of the four shares before fit checks. Equal category weights do not reserve equal totals for categories. Eligibility, count limits and rejected fits affect the final mix; these are relative preferences, not promised percentages. For later members of a Book row, only explicitly profiled books with compatible yaw angles participate.

## Reuse a library

**Save asset library** writes a `.cyalib` file containing stable IDs, all captured vertex/triangle geometry and the placement metadata. **Load asset library** validates the complete file before importing its assets into the setup. The host assigns fresh IDs in the destination document to avoid collisions with existing assets; the core file decoder itself preserves the stored IDs. A malformed or over-budget successor is rejected. Failed saves retain the previous destination file; publication uses an owned temporary file and an atomic rename/replacement.

The current writer emits library **format 2**, introduced in 0.1.2; its reader explicitly accepts delivered **format 1** and current format 2. Format-1 assets retain every previous field and acquire no upright-book profile. Format 2 appends one bounded per-asset tag: 0 absent, 1 −X, 2 +X, 3 −Y, 4 +Y. Unknown tags/versions reject. Both formats retain explicit little-endian fields, complete-payload CRC32 and the same admission ceilings. Reading does not rewrite an input library; an explicit save writes the current format. Keep original format-1 files for use with older binaries.

Scene documents independently advance from delivered schema 3 to schema 4. The new reader preserves old schema-3/library-1 state in memory with composition disabled and empty generated-group records; new scene saves embed library 2 in schema 4. Registry format remains 1. See [SCENE_OWNERSHIP.md](SCENE_OWNERSHIP.md) for reference, Undo and migration ownership.

Neither supported library format includes UV channels, renderer materials, textures or a complete Max modifier stack. Live source scene references preserve mesh mapping channels, face material IDs and evaluated source materials when the host creates output, including material combinations for an accessory group. A library-only asset retains geometry and metadata; matching rendered appearance requires its source materials or a future richer asset format. Geometry-only rows are marked in the panel. A `.cyalib` file is not a replacement for preserving an artist's source `.max` library.

Saving a library does not grant new rights to third-party models. The supplied procedural fixtures are original geometry and use materials created in the test scene; they do not require an external download.

The separate [imported examples](IMPORTED_EXAMPLES.md) use licensed original
models and supplied texture files. Copy their complete example folder and follow
the explicit map-relocation instructions; a geometry-only `.cyalib` does not
replace that source scene/map bundle.

## Metadata and geometry contract

`Asset` lives in `include/cyrus_arrange/assets.h`. Its uint64 stable ID is separate from host reference slots and generated placement IDs. Geometry, anchor, contact footprint and top patch share a captured millimetre frame with Z up. Capture evaluates source transforms, including rotation and scale, into world-oriented geometry, then subtracts the base-bounds centre. It does not rotate geometry back into the source pivot's local axes. The captured axes therefore follow the scene's world axes at capture; yaw rotates this captured geometry about +Z. The initial fallback contact patch is the full XY bounds rectangle: conservative for fitting, not semantic recognition of feet, cavities or the actual load-bearing contact area.

The full mesh is retained for reuse and future geometric queries. The current arrangement collision query uses conservative oriented bounds; retaining a mesh does not mean every placement has undergone full triangle-to-triangle collision testing. Library validation is not a watertightness, centre-of-mass or real-world safety certificate.

An authored top patch is a convex counterclockwise polygon at the mesh's top height. Stack metadata includes an allowed-child-category mask and a support height relative to the anchor. Non-stackable records cannot carry active top-patch metadata. Explicit malformed footprints are rejected, rather than silently repaired. Names may contain printable Unicode and quotes; they are bounded UTF-8 without embedded NUL or control characters.

**Edit contact / stack support** opens a separate bounded editor for an existing asset. Enter the anchor in local millimetres and 3–64 counterclockwise points per convex polygon, one `x,y,z` point per line. Select the permitted child categories and the top height above the anchor. Applying the editor marks the support as authored. Source refresh and Generate preserve authored anchors and patches, and reject incompatible successors instead of replacing them with bounds rectangles. **Reset support from geometry** explicitly restores derived support. This editor does not provide a separate front-direction gizmo; the prepared source orientation and allowed yaw list define the initial orientation convention.

Native name/tag inference is a suggestion utility only. `infer_asset_category` and `infer_furniture_category` recognize bounded ASCII aliases such as `TV_Set`, `bookshelf` and `BookStack`. Unknown or ambiguous names return no suggestion. Explicit metadata remains authoritative; changing a name does not rewrite registered category data.

### Explicit upright-book profile

After registration, **Upright book row profile...** opens an editor. Enable **This asset is an individual upright book** and choose its physical outside spine side in the captured frame: −X, +X, −Y or +Y. Apply the profile explicitly. Only Book-category assets may carry it; a flat Book, old library entry or suggestive name is not automatically eligible. Disable the profile before changing a Book entry to another category.

The regional front vector determines facing. Only already allowed yaw angles that align the authored spine side are eligible; native code does not add rotations silently. Set both scale limits to 1 to preserve physical size; enabling the profile does not change those limits. A grouped source is still one captured asset/output placement, even if its source geometry contains multiple modeled books. Generated rows select separate assets and persist ordered placement membership.

Source refresh, automatic capture during Generate and rebind retain the saved spine tag. They do not recognize a spine or reinterpret the tag after source geometry or orientation changes. Use Manual mode while revising a source/profile. Recheck the physical captured axes and explicitly correct the tag/yaws before generating. The original upright fixtures face −Y; after a +90-degree world-Z source rotation, that physical spine faces +X in a new capture. Merely refreshing the list or profile editor does not change the tag.

### Current hard ceilings

| Resource | Ceiling |
| --- | ---: |
| Assets per library | 256 |
| Vertices / triangles per asset | 250,000 each |
| Total vertices / triangles | 1,000,000 each |
| Encoded library size | 128 MiB |
| Asset name | 512 UTF-8 bytes |
| Contact or top polygon | 64 vertices |
| Allowed yaw angles | 64 |
| Uniform scale | 0.01–100 |

Callers may lower these ceilings but cannot raise them. Count and byte budgets are admitted before mesh-sized allocations during decoding. Library blobs use explicit little-endian values, a version marker and CRC32; no pointers or native C++ structure layouts are dumped. CRC detects accidental damage and is not an authentication mechanism.

## Host component contract

The native bridge owns geometry, placement metadata and library serialization;
the scripted panel holds bounded metadata views and sends authored commands.
MAXScript category indices are one-based; C++ enums are zero-based. The commands
below are technical reference; artist steps remain above.

```text
caRegisterAsset setup sourceNode name categoryIndex allowedMask yawArray weight minScale maxScale stackable
caAssetRows setup
caSaveAssetLibrary setup path
caLoadAssetLibrary setup path
caAssetDetail setup assetID
caUpdateAsset setup assetID name categoryIndex allowedMask yawArray weight minScale maxScale stackable
caRebindAsset setup assetID sourceNode
caUseStoredAsset setup assetID
caRemoveAssets setup assetIDArray removeOwnedOutputs
caAssetSupport setup assetID
caSetAssetSupport setup assetID anchor contactPoints stackEnabled stackHeight topPoints allowedTopMask
caResetAssetSupport setup assetID
caAssetBookRow setup assetID
caSetAssetBookRow setup assetID profileTag
```

`caAssetRows` returns at most 256 rows, each exactly:

```text
#(stableId, name, categoryIndex, dimensionsMMPoint3, allowedFurnitureMask,
  weight, minScale, maxScale, stackable, sourceReferenceValid)
```

Furniture-mask bits are 1 TV console, 2 Open shelf, 4 Coffee table, 8 Kitchen counter and 16 Dining table. The scripted panel edits only this small metadata. `caAssetUI.onSave path:...` and `onLoad path:...` allow private tests to use fixed paths without opening file dialogs. Public `caShowAssetUI setup` does not create an accessory or run an arrangement.

`caAssetDetail` returns thirteen fields: ID, name, category, furniture mask, yaw array, weight, minimum scale, maximum scale, stackable, source state (1 live / 2 stored / 3 missing), source node or undefined, source label, and `#(authoredContact, authoredStack)`. `caAssetSupport` returns nine fields: anchor, contact points, stack enabled, stack height, top points, allowed-top mask, authored flags, minimum bounds and maximum bounds. These are bounded authored metadata, with no mesh arrays. `caRemoveAssets` returns `#(removedAssetCount, removedPlacementCount)`.

The separate book-row profile getter/setter uses the 0–4 tag contract above; existing ten-/thirteen-/nine-field asset rows retain their shapes. Library import remaps asset IDs and keeps profiles; it does not import historical generated row relationships.

## Related artist workflows

Use the [arrangement quick start](ARRANGE_QUICKSTART.md) for setup creation,
allowed-category rules, surface and obstacle controls, Preview/Commit and
Manual/Live updates. Those controls use the assets registered in the selected
native setup; opening a panel or refreshing its list does not run Generate.

Use the [book-row guide](BOOK_ROWS.md) for profile authoring, front alignment,
2–6 individual members, row gap, height balance and whole-row selection/locks.
A row lock retains its placement relationship and valid poses. A successful
Generate may replace the actual output nodes, including locked ones; refresh
selection from the current output or row list. Permanent external references
and manual material/mesh edits on generated nodes are not preserved overrides.

The [arrangement API](ARRANGEMENT_API.md) defines the native record shapes,
weighting, selective-generation rules, budgets, persistence and transient
statistics. UI controls send authored commands to that same native document;
there is no separate scripted placement database.

## Original procedural models and tests

`tests/max/asset_fixtures.ms` defines `caCreateAccessoryFixtures offsetMM:[0,0,0]`. Loading the file creates nothing. Calling the factory creates eleven original models: an upright detailed book, a flat book, a three-book stack, a potted plant with branches and leaves, a brass candle holder, a standing picture frame, a hollow ceramic vase, a stoneware bowl, a ring sculpture, a mug and a round tray. They use physical millimetre dimensions independently of the current system units, and scene-created standard materials. The returned small rows are `#(groupHead, label, categoryIndex, stackable)`.

Every created part/group has `CyrusArrangeFixture` and `CyrusArrangeAssetFixture` tags. Group heads additionally carry suggested fixture category and stacking metadata. No scene reset occurs in this fixture file. Only a root-controlled disposable Max 2027 host may create, clear or save test scenes.

`tests/assets_tests.cpp` exercises metadata and geometry rejection, prepared support patches, all category roundtrips, deterministic geometry serialization, Unicode/quoted names, corruption/truncation and malicious-count rejection, lowered budgets, duplicate IDs, atomic file replacement and native preset contents. Pure-core tests do not qualify Max UI, material cloning or renderer output; the private host workflow supplies that separate evidence.

`tests/max/arrange_workflow_tests.ms` is the private-host workflow harness. The root runner supplies trailing-slash `CA_TEST_ROOT` and `CA_TEST_OUTPUT` paths. It writes `result.txt` beginning with `SUCCESS` or `ERROR`, per-check results, stage breadcrumbs and exception details. It exercises the actual rollout button handlers, all original accessory groups, source preservation, live-source materials, library save/import, deterministic Generate, locks/rerolls, selected regions, Undo/Redo, failed-publication retention, scene save/load and Live arming/dependency changes. It creates and resets only its disposable Max 2027 scene. A script existing in the repository is not evidence that a particular host run passed; the runner's result and build receipt provide that evidence.

`tests/max/arrange_regions_tests.ms` supplies a separate private-host surface workflow. Two original board fixtures provide independent physical height witnesses. It checks cached-only opening, explicit analysis, repeated and retessellated identity, region policy Undo/Redo and persistence, actual category filtering, deny-all and density-zero suppression, stacking permission, exclusion, analysis output preservation, locked conflicts and stale-ID rejection after a board is removed. Both host harnesses persist `RUNNING` stage/check progress immediately, then write final `SUCCESS` or `ERROR`; a crash cannot be mistaken for a passed run.

The 0.1.2 additions include `tests/max/book_row_fixtures.ms`: original,
separately modeled upright books of 100/200/300 mm height, with explicit −Y
spine geometry and factory-only loading. Library tests use independent
format-1/format-2 byte fixtures and exercise profile preservation, malformed
tags, truncation, CRC and admission limits. Composition, lifecycle and gallery
harnesses separately check real row membership, fit, Preview/Commit, locks,
save/load and rendered source appearance.

This guide does not turn a test's existence or an earlier run into final
acceptance. The [0.3.1 release report](RELEASE_VALIDATION_0.3.1.md) records current
matched native/host evidence, remaining gates and package status. The qualified
[0.3.0 report](RELEASE_VALIDATION_0.3.0.md) remains bound to its earlier pair.
Historically, the unchanged 0.1.2 installer passed
43 installation and 12 automatic-startup checks; its external receipt records
the qualified archive. Historical failures and the 0.1.1 baseline remain
preserved. Those historical results do not qualify a different source pair.

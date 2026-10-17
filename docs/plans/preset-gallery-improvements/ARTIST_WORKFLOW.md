# Cyrus Library — 0.85.3 workflow

This retains the [0.85.2 navigation/scale correction](UI_CORRECTION_0852.md) and adds [0.85.3 ready presets](LOAD_0853.md). Its handoff contains the current package, tests and artist checklist.

## Browse collections

Open **Layers > Recipes**. The left tree chooses **My recipes**, **Bundled examples** or a **Custom library**. A library opens its collection tiles; open a tile or choose **All recipes** to see individual previews. Search, compact-list/thumbnail view and three tile sizes are in the toolbar. The window resizes. Max’s default scale uses normal-size text and tiles; configured 150% also scales the library. Choose Small, Medium or Large tiles in the toolbar. Physical monitor transitions remain separate acceptance. **Load + Update**, double-click and Enter open a collection or load a ready preset. Ready presets supply their own supported models/materials and add layers; the loader identifies current or included terrain. The existing Modify navigation and scale fixes are retained.

Browsing reads saved metadata and images. It does not calculate plants, capture previews, merge models or change the scene. **Refresh** explicitly discovers file changes; there is no idle folder scan. Missing images show placeholders. The gallery displays at most 128 items per page and keeps a bounded decoded-image cache.

## Save a complete planting recipe

Choose **Save Recipe**, select the layers, and enter the name, collection, tags and description. **Include models, materials, terrain and paths** is checked by default; its progress window confirms a complete ready package. Terrain is an evaluated snapshot, not a saved modifier stack. Saved settings include enabled and disabled values, model roles/weights, variation, spacing, Paths/Bands, editable curves, density/scale controls, and all supported native Paint Areas with their holes and fades. Save preserves pending Manual settings without calculating them.

Choose an existing PNG or explicitly capture the current published viewport. A pending Manual change cannot be labeled as a current preview: use the explicit Update-and-capture action, or save without a thumbnail. A later authored change invalidates the captured preview until it is cleared or recaptured. Capturing is optional and runs only when requested.

**Update selected** writes a new revision of that recipe; **Save Copy** creates another recipe identity. **Edit details** changes its name, collection, tags, description or preview without applying settings to the scene. Bundled examples are read-only; save a personal copy. If another writer changes the reviewed file, refresh and review it again.

## Load or apply a style

For a ready preset, select its thumbnail and use **Load + Update**. It adds new layers and calculates once, keeping the existing authored planting and Manual/Live mode. This explicit Update also applies pending setup edits. Compatible current terrain is used when unambiguous; Paint/channel/path context uses the included receiver when required. Shared viewport preparation still distributes the controller's budget across the resulting layers. Undo/Redo restores complete publications and asset ownership.

For a settings-only recipe, use **Recipe actions > Review bindings (advanced)**. For a settings recipe, **Load selected** opens terrain/model/map/path/spacing bindings. **Match unique scene names** supplies suggestions; missing or ambiguous roles remain unbound. Review them before loading. **Add layers** retains the selected setup's controller preferences. **New setup** creates a separate controller with the saved preferences. Both use fresh ownership identities. **Saved variation** keeps saved random inputs; **New variation** is the default. Exact arrangements also require matching geometry, source order, quotas, masks and spacing context.

Native Paint needs compatible receiver geometry, frame and saved system units. It is preserved in the file; an arbitrary replacement terrain does not automatically make the footprint compatible. Import is one authored Undo operation. Manual mode waits for **Update scatter**.

**Apply Style** copies only chosen supported setting groups into the captured layer. It keeps the layer's models, receivers and Paint by default. Review any explicit map/target binding and the Keep/Saved/New variation policy. Applying identical effective settings does not create another Undo or calculation. Authored Edit/radius records and unsupported controllers are rejected by this bounded style adapter.

## Share supported models and materials

Choose **Export portable package** on a saved recipe. Bind the sources/maps to capture, choose a new destination folder and confirm permission to distribute those assets. A package includes the recipe, Paint and a verified dependency manifest. The current adapter supports static standalone meshes, supported Standard/Blinn materials and static PNG maps. Terrain, paths and other declared external roles still need destination bindings.

When loading a package, choose independent packaged models/materials or explicitly bind existing scene models/maps for reuse. Reuse keeps those models' current materials and their other scene users. It is deliberate substitution, not a claim that equal names mean equal assets. A change after Review requires another review. Imported bitmap files are kept in a persistent owned asset store so Redo and saved scenes do not depend on the original package folder.

XRefs, nested populations, renderer-specific shaders/proxies, material-variant browsing, animated dependencies and automatic arbitrary-terrain Paint transfer are not supported by this adapter. Complete save also rejects authored Scatter Edit/per-instance radius content until its required codec exists; it never silently omits those records.

## Examples and installation

The [eight examples](../../../AminScatter/library/README.md) include matching editable Max 2027 scenes and rendered previews. The geometry is intentionally simple and replaceable. Open a copy of the matching scene to examine compatible bindings, then make your own variation.

The 0.85.3 handoff links the MZP and unsigned Windows EXE after qualification. Both use a versioned plugin/library folder and preserve personal recipes and activation. Neither starts or restarts Max. Run the MZP through **Scripting > Run Script**, then restart Max 2027. The EXE's Unregister action removes owned registration while retaining personal recipes, imported assets and versioned recovery files.

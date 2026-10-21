# Cyrus Library — current model and recipe workflow

The [0.86.8.2 delivery](../source-clearance/DELIVERY_08682.md) owns current Max 2024/2026/2027 packages and focused qualification. Content keeps its independent 0.86.7 revision. The [0.86.7 report](DELIVERY_0867.md) records model thumbnails and supported material preview; [0.86.6](DELIVERY_0866.md) and [original 0.87.0 evidence](DELIVERY_0870.md) retain their historical brush/reliability labels and limits. Model imports and complete planting recipes are different actions.

## Individual plant models

The supplied private content has 96 prepared single-model files covering the 104 catalog cards. Select **Plant models**, choose a model, then **Merge model** to add a scene source or **Add to selected layer** to add it to the captured Scatter layer. The completion/error banner reports the result. Thumbnails load as visible items need them. This action imports a model; it does not apply a complete planting recipe or replace receiving surfaces. The [artist guide](../../ARTIST_GUIDE.md) owns source controls, clearance and supported viewport material behavior.

## Browse collections

Select one terrain mesh and open **Cyrus Library** from the Cyrus action category, or **Layers > Recipes** from an existing setup with one selected-layer receiver. The browser captures this terrain; later scene selection does not redirect loading. The left tree separates My recipes, Bundled examples and Custom library. Open a collection tile or All recipes, search, choose thumbnail/list view and tile size. Max default scaling and explicit 150% use readable controls. Physical mixed-monitor transitions remain separately qualified.

Pressing **Recipes** restores a minimized Library to its normal size and brings the existing window forward. Closing with X and opening Recipes creates a normal window. Opening Recipes for a different setup or selected receiver updates the captured destination and invalidates callbacks from the previous destination. Windows can restrict foreground activation when another application is active.

Browsing reads saved metadata and images. It does not calculate plants, capture previews, merge models or change the scene. **Refresh** explicitly discovers file changes; there is no idle folder scan. Missing images show placeholders. The gallery displays at most 128 items per page and keeps a bounded decoded-image cache.

## Save a complete planting recipe

Choose **Save Recipe**, select the layers, and enter the name, collection, tags and description. **Include models, materials, terrain and paths** is checked by default; its progress window confirms a complete ready package. Terrain is an evaluated snapshot, not a saved modifier stack. Saved settings include enabled and disabled values, model roles/weights, variation, spacing, Paths/Bands, editable curves, density/scale controls, and all supported native Paint Areas with their holes and fades. Save preserves pending Manual settings without calculating them.

Choose an existing PNG or explicitly capture the current published viewport. A pending Manual change cannot be labeled as a current preview: use the explicit Update-and-capture action, or save without a thumbnail. A later authored change invalidates the captured preview until it is cleared or recaptured. Capturing is optional and runs only when requested.

**Update selected** writes a new revision of that recipe; **Save Copy** creates another recipe identity. **Edit details** changes its name, collection, tags, description or preview without applying settings to the scene. Bundled examples are read-only; save a personal copy. If another writer changes the reviewed file, refresh and review it again.

## Load or apply a style

For a ready preset, select its thumbnail and use **Load onto surface**, double-click or Enter. It creates a Scatter setup if none uses the captured terrain, or adds layers to its unambiguous existing setup. If several setups use the terrain, open Recipes from the intended setup. Existing layers, identities and Manual/Live mode are retained. Loading explicitly updates once, also applying pending Manual edits. One Undo/Redo includes imported assets, layers and complete publication.

The captured surface is authoritative: no included terrain is substituted and no mask is silently disabled. Explicit missing numeric channels are reported before scene mutation. Complete presets fit saved Paint contours and spline guide positions from the saved local-XY footprint to the selected footprint. Units convert automatically; plant size, spacing, brush radius, falloff and path widths keep physical dimensions. Terrain Paint transfer requires a single-valued local-XY receiver. Surface-attached Paint transfers between matching indexed mesh topologies; new Paint Areas can be drawn on spheres, boxes and manifold curved receivers. Source coverage remains unchanged. Settings-only exact Paint restoration retains its original compatibility checks. Grids keep their explicit world-space origin.

Settings-only recipes have no packaged models. Save them from a valid setup with Include models, materials, terrain and paths enabled before direct loading. The old advanced binding dialog is retired from the default browser. Typed internal import/reuse contracts remain available for qualified engineering workflows; they are not another normal loading step.

**Apply Style** copies only chosen supported setting groups into the captured layer. It keeps the layer's models, receivers and Paint by default. Review any explicit map/target binding and the Keep/Saved/New variation policy. Applying identical effective settings does not create another Undo or calculation. Authored Edit/radius records and unsupported controllers are rejected by this bounded style adapter.

## Share supported models and materials

Choose **Export portable package** on a saved recipe. Bind the sources/maps to capture, choose a new destination folder and confirm permission to distribute those assets. A package includes the recipe, Paint and a verified dependency manifest. The current adapter supports static standalone meshes, supported Standard/Blinn materials and static PNG maps. Terrain, paths and other declared external roles still need destination bindings.

The default browser imports independent packaged models/materials. Explicit scene reuse remains an internal qualified adapter; it is not exposed by direct loading. Imported bitmap files persist so Redo and saved scenes do not depend on the package folder. Unsupported external dependencies must be resolved when saving a ready preset.

XRefs, nested populations, renderer-specific shaders/proxies, material-variant browsing, animated dependencies and Paint transfer onto folded or stacked local-XY surfaces are not supported by this adapter. Complete save also rejects authored Scatter Edit/per-instance radius content until its required codec exists; it never silently omits those records.

## Examples and installation

The [historical eight examples](../../../AminScatter/library/README.md) retain their own matching-host scenes and previews; their simple replaceable geometry is separate from the real-model library. The earlier [real-model pilot roadmap](real-model-library/ROADMAP.md) is a staged recipe program, not a claim that every catalog model has a qualified planting preset.

For the current EXE, close the selected Max versions, select their cards and click **Install/Update**. Check **Install / update plant library** with `CyrusScatter-Content-0.86.7.zip` beside the EXE for a content installation; an absent ZIP fails before installation. Leave it unchecked to reuse existing content. One shared content store serves standard profiles across all three hosts, with verified bytes reused on repeat updates. **Uninstall** retains shared content, personal recipes and recovery paths. Alternatively run the matching MZP through **Scripting > Run Script**, then restart that host. The [installation guide](../../Max_2027_Installation.md) gives current paths and dependencies. No online content download or automatic Max restart is performed.


## Density and portable images

The [artist guide](../../ARTIST_GUIDE.md) owns projected image mapping, receiver-aware procedural maps, Show/Hide mask and explicit portable snapshots. Receiver-aware graphs use their own UV/data channels and remain editable in Max scenes; arbitrary graph export is outside the portable adapter. Valley and Mountain use relative local elevation without original-scene channel/altitude dependencies. Recipes preserve image bytes/settings and required mesh/UV channels; they do not recreate Data Channel or VertexPaint producers on arbitrary terrain. The library details distinguish settings-only, incomplete and packaged entries and show channel/Paint requirements before Load. Load validates required data before adding layers. A failure in the first calculation rolls back the staged recipe and retains previous output/history.

# Cyrus Library â€” 0.86.2 workflow

The [current delivery report](DELIVERY_0862.md) owns package identities, qualification and limits. Earlier navigation and static asset contracts remain supported where not superseded here.

## Browse collections

Select one terrain mesh and open **Cyrus Library** from the Cyrus action category, or **Layers > Recipes** from an existing setup with one selected-layer receiver. The browser captures this terrain; later scene selection does not redirect loading. The left tree separates My recipes, Bundled examples and Custom library. Open a collection tile or All recipes, search, choose thumbnail/list view and tile size. Max default scaling and explicit 150% use readable controls. Physical mixed-monitor transitions remain separately qualified.

Browsing reads saved metadata and images. It does not calculate plants, capture previews, merge models or change the scene. **Refresh** explicitly discovers file changes; there is no idle folder scan. Missing images show placeholders. The gallery displays at most 128 items per page and keeps a bounded decoded-image cache.

## Save a complete planting recipe

Choose **Save Recipe**, select the layers, and enter the name, collection, tags and description. **Include models, materials, terrain and paths** is checked by default; its progress window confirms a complete ready package. Terrain is an evaluated snapshot, not a saved modifier stack. Saved settings include enabled and disabled values, model roles/weights, variation, spacing, Paths/Bands, editable curves, density/scale controls, and all supported native Paint Areas with their holes and fades. Save preserves pending Manual settings without calculating them.

Choose an existing PNG or explicitly capture the current published viewport. A pending Manual change cannot be labeled as a current preview: use the explicit Update-and-capture action, or save without a thumbnail. A later authored change invalidates the captured preview until it is cleared or recaptured. Capturing is optional and runs only when requested.

**Update selected** writes a new revision of that recipe; **Save Copy** creates another recipe identity. **Edit details** changes its name, collection, tags, description or preview without applying settings to the scene. Bundled examples are read-only; save a personal copy. If another writer changes the reviewed file, refresh and review it again.

## Load or apply a style

For a ready preset, select its thumbnail and use **Load onto surface**, double-click or Enter. It creates a Scatter setup if none uses the captured terrain, or adds layers to its unambiguous existing setup. If several setups use the terrain, open Recipes from the intended setup. Existing layers, identities and Manual/Live mode are retained. Loading explicitly updates once, also applying pending Manual edits. One Undo/Redo includes imported assets, layers and complete publication.

The captured surface is authoritative: no included terrain is substituted and no mask is silently disabled. Missing numeric channels or incompatible receiver-bound Paint are reported before scene mutation. Paint requires matching evaluated geometry, frame and saved system units. Static spline paths transfer relative to the saved terrain frame while retaining authored dimensions; this is not arbitrary reprojection or fit-to-bounds scaling. Grids keep their explicit world-space origin.

Settings-only recipes have no packaged models. Save them from a valid setup with Include models, materials, terrain and paths enabled before direct loading. The old advanced binding dialog is retired from the default browser. Typed internal import/reuse contracts remain available for qualified engineering workflows; they are not another normal loading step.

**Apply Style** copies only chosen supported setting groups into the captured layer. It keeps the layer's models, receivers and Paint by default. Review any explicit map/target binding and the Keep/Saved/New variation policy. Applying identical effective settings does not create another Undo or calculation. Authored Edit/radius records and unsupported controllers are rejected by this bounded style adapter.

## Share supported models and materials

Choose **Export portable package** on a saved recipe. Bind the sources/maps to capture, choose a new destination folder and confirm permission to distribute those assets. A package includes the recipe, Paint and a verified dependency manifest. The current adapter supports static standalone meshes, supported Standard/Blinn materials and static PNG maps. Terrain, paths and other declared external roles still need destination bindings.

The default browser imports independent packaged models/materials. Explicit scene reuse remains an internal qualified adapter; it is not exposed by direct loading. Imported bitmap files persist so Redo and saved scenes do not depend on the package folder. Unsupported external dependencies must be resolved when saving a ready preset.

XRefs, nested populations, renderer-specific shaders/proxies, material-variant browsing, animated dependencies and automatic arbitrary-terrain Paint transfer are not supported by this adapter. Complete save also rejects authored Scatter Edit/per-instance radius content until its required codec exists; it never silently omits those records.

## Examples and installation

The [eight examples](../../../AminScatter/library/README.md) include matching-host editable scene copies and rendered previews. The geometry is intentionally simple and replaceable. Open a copy of the matching scene to examine compatible bindings, then make your own variation.

The [current delivery report](DELIVERY_0862.md) links the qualified MZP and unsigned Windows EXE. Both use a versioned plugin/library folder and preserve personal recipes and activation. Neither starts or restarts Max. Run the MZP through **Scripting > Run Script**, then restart the selected Max version. Max 2024 is preview only; consult the report before team testing. The EXE's Unregister action removes owned registration while retaining personal recipes, imported assets and versioned recovery files.


## Density and portable images

The [artist guide](../../ARTIST_GUIDE.md) owns image mapping, Show/Hide mask and explicit portable snapshots. Recipes preserve image bytes/settings and required mesh/UV channels; they do not recreate Data Channel or VertexPaint producers on arbitrary terrain. The library details distinguish settings-only, incomplete and packaged entries and show channel/Paint requirements before Load. Load validates required data before adding layers. A failure in the first calculation rolls back the staged recipe and retains previous output/history.

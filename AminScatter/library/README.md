# Cyrus planting presets — 0.86.6 / Max 2027

Select one terrain mesh and run **Cyrus Library** (Customize > Cyrus category), or open **Layers > Recipes** from an existing setup. Choose a preset and **Load onto surface**. Browsing creates no scene objects. Loading imports its supported models/materials and creates a setup when needed. Otherwise it adds layers to the captured setup, preserving existing layers and Manual/Live mode, then explicitly updates once. One Undo removes the added preset; Redo restores it.

| Example | Demonstrates |
| --- | --- |
| Layered meadow | Independent grass, shrub and flower layers |
| Trees and understory | Upright canopy, shrubs and normal-aligned groundcover |
| Mountain planting | Soft slope and receiver-relative summit exclusion |
| Painted garden and spline borders | Complete Paint, clearing, fading and two spline Bands |
| Rectangular orchard | Regular tree rows and low groundcover |
| Hexagonal hillside planting | Nearest-neighbor layout and normal blending |
| Four garden rooms | Topiary, soft painted flower beds and gravel |
| Valley moss and rocky crests | Relative local elevation, inversion, curves and slope fading |

Changing scene selection after opening the browser does not redirect loading. Reopen the library to choose another terrain. If several setups use the same terrain, open Recipes from the intended setup. No saved terrain is substituted automatically. Shared viewport budgets distribute across the resulting layers. The explicit Update also applies pending Manual edits.

**Save Recipe** includes supported models, materials, evaluated terrain, static paths and complete Paint by default. A progress window confirms ready saving. Uncheck **Include models, materials, terrain and paths** for an advanced settings-only recipe. Ready terrain is a baked snapshot of evaluated geometry and channels, not an editable modifier stack. Rename/tag edits preserve ready package linkage through a file worker. Unsupported dependencies report the adapter needed; they are never silently omitted from a complete preset.

Each ready package lives under `Presets/<full-recipe-SHA256>/`. Keep library entries, immutable Paint/thumbnail payloads and corresponding package directories together when copying a library. Save personal copies in **My recipes** (`Documents/CyrusScatter/Library`) or a custom folder. Bundled examples are read-only. Settings-only recipes must be saved with their assets before direct loading.

The maintained `.max` examples are reauthored Max 2027 copies. Original scenes, hashes and receipts remain in the preserved baseline. Open a copy, select the controller, change a layer and press **Update scatter**. Thumbnails depict the saved placements; loading uses a new variation and may produce a different arrangement. Models are original procedural placeholders. No Forest/Chaos vegetation is bundled.

Ready presets convert physical model sizes and distance settings into the destination system units. Packaged Paint and spline guides fit the selected receiver's local XY footprint; brush radius, falloff and band widths retain physical sizes. Paint supports terrain that is single-valued in local XY, including rotated and mirrored nodes. Closed, folded and stacked receivers are rejected before import. Settings-only Paint retains its exact receiver requirement. The original Paint payload is preserved.

Valley moss and Mountain planting now use **Amount > Surface density > Relative elevation**. Local low/high values normalize to 0/1; flat terrain uses 0. These bundled examples require no numeric channel 2 and do not depend on world elevation. Artist-created recipes with explicit mesh channels retain those requirements; the loader never invents missing channel data. Grids retain explicit world-XY origins. Direct avenue/sequencing tools remain separate work.

The static asset adapter supports the documented standalone meshes, Standard/Blinn materials and static PNG maps. XRefs, arbitrary renderer proxies/shaders, animated dependencies and authored Edit/radius codecs remain separate work. Package and memory admission limits can reject work while preserving the previous complete result.

## Content permission

The procedural geometry, recipes and thumbnails were created for Cyrus Scatter. Permission is granted to use, modify and redistribute this demonstration content with Cyrus Scatter and in users' scenes. This grant does not change the plugin license or cover substituted third-party assets.

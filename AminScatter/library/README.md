# Cyrus planting presets — 0.85.3

Eight ready-to-use procedural examples for 3ds Max 2027. Open **Layers > Recipes > Bundled examples**, select a preset and use **Load + Update**. Its models and materials load with its layers. Model picking is unnecessary.

| Example | Demonstrates |
| --- | --- |
| Layered meadow | Independent grass, shrub and flower layers |
| Trees and understory | Upright canopy, shrubs and normal-aligned groundcover |
| Mountain planting | Soft slope/altitude exclusion and normal alignment |
| Painted garden and spline borders | Complete Paint, clearing, fading and two spline Bands |
| Rectangular orchard | Regular tree rows and low groundcover |
| Hexagonal hillside planting | Nearest-neighbor layout and normal blending |
| Four garden rooms | Topiary, soft painted flower beds and gravel |
| Valley moss and rocky crests | Included channel-2 numeric mask, inversion, curves and slope fading |

Load adds new layers, preserving existing authored planting and Manual/Live mode. It explicitly updates the setup once, including any pending Manual edits. Ordinary presets use an unambiguous compatible current terrain. If the preset needs saved Paint, channel data or spline context that the destination cannot provide, its included terrain is used and reported. Existing terrain is preserved. Shared viewport budgets distribute across the resulting layers.

**Save Recipe** includes supported models, materials, evaluated terrain, static paths and complete Paint by default. A progress window confirms ready saving. Uncheck **Include models, materials, terrain and paths** for an advanced settings-only recipe. Ready terrain is a baked snapshot of evaluated geometry and channels, not an editable modifier stack. Rename/tag edits preserve ready package linkage through a file worker. Unsupported dependencies report the adapter needed; they are never silently omitted from a complete preset.

Each ready package lives under `Presets/<full-recipe-SHA256>/`. Keep the library entries, immutable Paint/thumbnail payloads and corresponding package directories together when copying a library. Save personal copies in **My recipes** (`Documents/CyrusScatter/Library`) or a custom folder. Bundled examples are read-only. **Recipe actions > Review bindings (advanced)** retains explicit settings/package substitution workflows.

The matching `.max` scenes preserve their original bytes and remain useful for inspection. Open a copy, select the controller, change a layer and press **Update scatter**. The original thumbnails are renders of those saved placements; a ready Load uses a new variation and does not promise the identical arrangement. Models are original procedural placeholders to replace with your own assets. No Forest/Chaos vegetation is bundled.

Paint is receiver-bound. Included compatible terrain permits its saved geometry/frame/units to be restored safely; arbitrary replacement terrain does not acquire that footprint automatically. The valley field is authored numeric channel data, not an automatic curvature engine. Grids use explicit world-XY origins. Direct avenue/sequencing tools remain outside this delivery.

The static asset adapter supports the documented standalone meshes, Standard/Blinn materials and static PNG maps. XRefs, arbitrary renderer proxies/shaders, animated dependencies and authored Edit/radius codecs remain separate work. Package and memory admission limits can reject work while preserving the previous complete result.

## Content permission

The procedural geometry, recipes and thumbnails were created for Cyrus Scatter. Permission is granted to use, modify and redistribute this demonstration content with Cyrus Scatter and in users' scenes. This grant does not change the plugin license or cover substituted third-party assets.

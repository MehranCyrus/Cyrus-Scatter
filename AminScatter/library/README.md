# Cyrus planting examples

Six editable procedural examples for Cyrus Scatter 0.85.0 and 3ds Max 2027. The original four format-1 recipes, scenes and thumbnails remain unchanged; format 4 reads them with neutral defaults. The orchard and hexagonal hillside examples use format 4 and the grid generator. Replace their pyramids and simple flower shapes with your own models; no third-party vegetation library is required.

| Example | Demonstrates |
| --- | --- |
| Layered meadow | Three independent grass, shrub and flower layers |
| Trees and understory | Upright canopy, shrubs and normal-aligned groundcover |
| Mountain planting | Soft slope/altitude exclusion, upright trees and aligned groundcover |
| Painted garden and spline borders | Saved Paint with a clearing, density/scale fading and two spline Bands |
| Rectangular orchard | Even tree rows with independent low groundcover |
| Hexagonal hillside planting | Regular nearest-neighbor planting, surface projection and normal blending |

Open the matching `.max` file to inspect the editable result. Select the Cyrus
controller, choose a layer, change settings and press **Update scatter**. These
examples use Manual mode. The sources are parked beside the terrain.

To reuse a recipe, open **Layers > Recipes**, choose **Bundled examples**, select
the recipe and click **Review bindings**. Explicitly bind its terrain, models and
paths. Match unique scene names can suggest bindings in the included scene. Choose
**New setup**, or leave it unchecked to **Add layers** to the selected controller.
Choose **Saved variation** to reproduce the saved arrangement with identical
terrain, source order, quotas, masks and collision context; **New variation** is
the default for a fresh arrangement. Both create independent layer ownership.
Import is one Undo; Manual mode calculates when you press Update scatter.
Under MAXScript heap pressure, a heavy Update can clear Max Undo history; this
known host-memory boundary remains under investigation.

Paint belongs to compatible receiver geometry, frame and saved system units.
The painted-garden example includes matching terrain. An arbitrary replacement
mountain is not automatically compatible with that Paint footprint.

Save your own versions in **My recipes** (`Documents/CyrusScatter/Library`) or
an explicit custom folder. Bundled files occupy a versioned folder and are not
overwritten by later versions. Keep each recipe, its Paint payload folder,
`.library.json` presentation sidecar and PNG together when sharing a recipe.

Thumbnails are actual renders of the saved accepted placements. These are
demonstration assets, not botanical models or renderer-specific proxy packages.
Grid presets use explicit world XY origins. Spacing determines their population; masks and collision rules thin it. Path and formal-garden examples remain planned.

## Content permission

The procedural example geometry, recipe data and thumbnails in this folder were
created for Cyrus Scatter. Permission is granted to use, modify and redistribute
this demonstration content with Cyrus Scatter and in users' scenes. This grant
does not change the plugin license or cover users' substituted third-party assets.

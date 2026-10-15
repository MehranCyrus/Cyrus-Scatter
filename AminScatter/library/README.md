# Cyrus planting examples

Four editable examples for Cyrus Scatter 0.82.6.1 and 3ds Max 2027. They use
procedural pyramids as groundcover, shrubs, flowers and trees. Replace these model
roles with your own assets; no third-party vegetation library is required.

| Example | Demonstrates |
| --- | --- |
| Layered meadow | Three independent grass, shrub and flower layers |
| Trees and understory | Upright canopy, shrubs and normal-aligned groundcover |
| Mountain planting | Soft slope/altitude exclusion, upright trees and aligned groundcover |
| Painted garden and spline borders | Saved Paint with a clearing, density/scale fading and two spline Bands |

Open the matching `.max` file to inspect the editable result. Select the Cyrus
controller, choose a layer, change settings and press **Update scatter**. These
examples use Manual mode. The sources are parked beside the terrain.

To reuse a recipe, open **Layers > Recipes**, choose **Bundled examples**, select
the recipe and click **Review bindings**. Explicitly bind its terrain, models and
paths. Match unique scene names can suggest bindings in the included scene. Choose
**New setup**, or leave it unchecked to **Add layers** to the selected controller.
Import is one Undo; Manual mode calculates when you press Update scatter.

Paint belongs to compatible receiver geometry, frame and saved system units.
The painted-garden example includes matching terrain. An arbitrary replacement
mountain is not automatically compatible with that Paint footprint.

Save your own versions in **My recipes** (`Documents/CyrusScatter/Library`) or
an explicit custom folder. Bundled files occupy a versioned folder and are not
overwritten by later versions. Keep each recipe, its Paint payload folder,
`.library.json` presentation sidecar and PNG together when sharing a recipe.

Thumbnails are actual renders of the saved accepted placements. These are
demonstration assets, not botanical models or renderer-specific proxy packages.
Grid/path examples will be added when their features are delivered.

## Content permission

The procedural example geometry, recipe data and thumbnails in this folder were
created for Cyrus Scatter. Permission is granted to use, modify and redistribute
this demonstration content with Cyrus Scatter and in users' scenes. This grant
does not change the plugin license or cover users' substituted third-party assets.

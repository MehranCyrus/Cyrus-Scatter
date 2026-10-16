# Cyrus planting examples

Eight editable procedural examples for Cyrus Scatter 0.85.1 and 3ds Max 2027. The format-5 reader accepts the earlier recipe formats with neutral defaults. The six earlier scene, recipe and image sets retain their original bytes. Replace their pyramids and simple flower shapes with your own models; no third-party vegetation library is required.

| Example | Demonstrates |
| --- | --- |
| Layered meadow | Three independent grass, shrub and flower layers |
| Trees and understory | Upright canopy, shrubs and normal-aligned groundcover |
| Mountain planting | Soft slope/altitude exclusion, upright trees and aligned groundcover |
| Painted garden and spline borders | Saved Paint with a clearing, density/scale fading and two spline Bands |
| Rectangular orchard | Even tree rows with independent low groundcover |
| Hexagonal hillside planting | Regular nearest-neighbor planting, surface projection and normal blending |
| Four garden rooms | Topiary rows, soft flower beds and gravel paths in three painted layers |
| Valley moss and rocky crests | Channel 2 R/X density, inverted rock mask, normal blending and slope fading |

Open the matching `.max` file to inspect the editable result. Select the Cyrus
controller, choose a layer, change settings and press **Update scatter**. These
examples use Manual mode. The sources are parked beside the terrain.

To reuse a recipe, open **Layers > Recipes**, choose **Bundled examples**, select
the recipe and click **Load selected**. Review and explicitly bind its terrain, models and
paths. Match unique scene names can suggest bindings in the included scene. Choose
**New setup**, or leave it unchecked to **Add layers** to the selected controller.
Choose **Saved variation** to reproduce the saved arrangement with identical
terrain, source order, quotas, masks and collision context; **New variation** is
the default for a fresh arrangement. Both create independent layer ownership.
Import is one Undo; Manual mode calculates when you press Update scatter.
The candidate checks available MAXScript working space before importing or
preparing a heavy Update. Rejected work preserves the last complete result.
This conservative guard is not a guarantee against every host-memory failure.

Paint belongs to compatible receiver geometry, frame and saved system units.
The painted-garden example includes matching terrain. An arbitrary replacement
mountain is not automatically compatible with that Paint footprint.

Save your own versions in **My recipes** (`Documents/CyrusScatter/Library`) or
an explicit custom folder. Bundled files occupy a versioned folder and are not
overwritten by later versions. Keep each recipe and all files listed by its
manifest together when copying it. Older entries also have a `.library.json`
presentation sidecar. New entries store their presentation and immutable
revision payload references in the recipe itself. Use **Export portable
package** when sharing supported source meshes, Standard/Blinn materials and
PNG maps as well as settings and Paint; the export review lists external roles
that must still be bound in the destination scene.

Thumbnails are actual renders of the saved accepted placements. These are
demonstration assets, not botanical models or renderer-specific proxy packages.
Grid presets use explicit world XY origins. Spacing determines their population; masks and collision rules thin it. The formal garden uses grids and painted footprints. Direct spline avenue placement remains dependent on I07.

## Content permission

The procedural example geometry, recipe data and thumbnails in this folder were
created for Cyrus Scatter. Permission is granted to use, modify and redistribute
this demonstration content with Cyrus Scatter and in users' scenes. This grant
does not change the plugin license or cover users' substituted third-party assets.

## Added in 0.85.1

- **Four garden rooms:** regular topiary rows, soft flower beds and gravel paths; three complete painted layers.
- **Valley moss and rocky crests:** channel 2 R/X density, an inverted rock mask, a density curve, normal blending and slope fading. The stored numeric field is authored in the demo terrain; it does not claim automatic curvature analysis.

Each entry includes an editable Max 2027 scene and a rendered preview made from its exact published placements. Models are original procedural placeholders that you can substitute with your own assets. Recipes preserve settings and Paint; bind compatible terrain/models when loading them. The six earlier scene/recipe/image sets retain their original bytes.

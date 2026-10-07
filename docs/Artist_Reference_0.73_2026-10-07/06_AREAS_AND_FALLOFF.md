# 6. Include / exclude areas and falloff

[Guide contents](README.md)

Area limits belong to the **layer**, so every paint set in that layer shares them. These masks use a top-down, world-XY footprint. They are different from Brush coverage painted directly on a curved receiver.

## Closed areas

| Control | Meaning |
| --- | --- |
| Closed lines / shapes list | Selects linked area shapes. Rows show whether each is Include or Exclude. |
| Add: pick closed line | Links a suitable closed shape from the viewport. |
| Select From Scene... | Links suitable closed shapes by name. |
| Remove selected rows | Unlinks the selected area shapes and their falloff settings. It keeps the scene splines. |
| Selected area mode: Include | Permits planting inside the selected shapes. Multiple include shapes form the allowed areas. |
| Selected area mode: Exclude | Removes planting inside the selected shapes. Exclude wins where Include and Exclude overlap. |

With no include shapes, ordinary receiving-surface space remains available, subject to exclusions and other restrictions. With include shapes, planting is limited to the included space. Selecting several rows changes the mode for those rows together.

**Example:** use an Include outline for a flower bed and an Exclude outline for the building footprint. Changing those shapes affects all paint sets in this layer.

## Advanced: Refresh and Surface Analyzer Area

| Control | Meaning |
| --- | --- |
| Refresh areas / preview | Explicitly refreshes area information and requests a preview update. Use this as an update action, not as passive inspection. |
| Pick Surface Analyzer | Links an existing Analyzer to the layer's area mask. This link is separate from the Analyzer used for source assignment or boundary falloff. |
| Remove Area Analyzer | Unlinks this area-mask Analyzer and turns off its line/point masks. |
| Center Line | Uses a band around the Analyzer's central path as an allowed area. |
| Full width | Total width of that band, not the width on each side. |
| Line ends: Flat / Round | Chooses the shape of the band's end caps. |
| Street offset | Moves the center-line mask sideways. It shares the layer offset used by Centerline source assignment. |
| Points | Uses discs around Analyzer sample points as allowed areas. |
| Radius | Radius of those discs. This is an area-mask radius, not a model collision radius. |

Center Line and Points together allow the union of their areas. Width and ends need Center Line enabled; point Radius needs Points enabled. These Analyzer masks are used with Random/Clusters assignment. The mask is world XY even when the Analyzer's own planar element is tilted.

## Advanced: Edge falloff

Falloff changes planting near a boundary rather than making an abrupt full-density edge.

| Control | Meaning |
| --- | --- |
| Edge falloff target: Analyzer Boundary | Edits the boundary effects driven by the falloff Analyzer. |
| Edge falloff target: Selected Area line | Edits the independent effects of exactly one highlighted area shape. Select one row before using these fields. |
| Pick Surface Analyzer | In Analyzer Boundary mode, links the Analyzer whose boundary drives the falloff. |
| Remove Analyzer | Removes that falloff link and disables its boundary effects. It does not delete the Analyzer. |
| Target name / direction | Identifies the selected boundary. Include boundaries work inward; exclusion boundaries work outward into the remaining plantable space. |
| Delete edge band | Removes planting in a strip beside the boundary. Starts off. |
| Delete width | Width of that removed strip. Default 0. |
| Scale ramp | Changes plant size progressively with distance from the boundary. Starts off. |
| Scale width | Distance over which the scale curve is applied. Default 100 scene units. |
| Edit Scale Graph... | Opens the shape of the scale transition. |
| Density ramp | Changes how much planting is permitted as distance from the boundary increases. Starts off. |
| Density width | Distance over which the density curve is applied. Default 100 scene units. |
| Edit Density Graph... | Opens the shape of the density transition. |

Both ramps start **after** the deleted edge band. Each linked Area line has its own values. Changing the selected line does not give every line the same ramp.

## The falloff graph window

| Control | Meaning |
| --- | --- |
| Graph | Horizontal position is distance through the chosen ramp: left is its start, right is its end. Vertical value is percentage. Move points and their curve handles to shape the transition. |
| Apply | Stores the graph. Graph edits also store as you edit them. |
| Close / window close | Stores the current graph and closes it. This is not Cancel. |

For density, 0% allows none and 100% permits full density at that distance, subject to other restrictions. For scale, 100% means unchanged size at that point. The graph does not alter the Width value: shape and distance are separate controls.

**Example:** remove a narrow strip beside a walkway, then raise flower density gradually over the next metre. This creates a deliberate clear edge and a softer transition behind it.

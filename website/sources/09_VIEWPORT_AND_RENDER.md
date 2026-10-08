# 9. Viewport and render

[Guide contents](README.md)

These are **setup-wide display and output controls**. Viewport display can show fewer plants or less detail than the completed planting. A low viewport budget does not lower the layer's requested population.

## Common controls

| Control | Meaning |
| --- | --- |
| Display mode: Point Cloud | Draws samples of the source shapes. The usual starting choice for browsing larger plantings. |
| Display mode: Proxy | Draws simplified shapes at plant positions. These are preview shapes, not renderer-specific proxy files. |
| Display mode: Mesh | Shows source geometry within the display budgets. Use it to inspect shape and placement more closely. |
| Display mode: Plant centres | Shows one marker at each represented plant centre. Useful for checking positions without source-shape detail. |
| Show preview | Shows or hides the setup's viewport preview. It keeps the setup enabled and does not act as a render-disable switch. |
| Automatic final render | Prepares the Scatter's full accepted model output for rendering. Starts on. Point Cloud markers are not the final render geometry. |
| Status | Reports the current display/result state. A limited preview is not necessarily an incomplete planting. |

The full accepted output can still be smaller than the request because of coverage and spacing. A Point placeholder has no source mesh to render. Missing original materials/maps are a separate problem from whether the Scatter supplies geometry.

## Advanced: Display budgets and feedback

| Control | Meaning |
| --- | --- |
| Proxy shape | Chooses Box, Sphere or Pyramid in Proxy mode. Box is the starting choice. |
| Instances/layer | Limits displayed instances in geometry-preview modes. Starts at 2,000; allows 1–100,000. It does not set the number of generated plants. |
| Faces/layer | Limits geometry-preview complexity. Starts at 2,000,000; allows 12–20,000,000. A dense source model can exhaust the budget with relatively few plants. |
| Preview color: Solid Color | Uses one chosen preview color. |
| Preview color: Source Group Colors | Uses the source groups' colors; this is the starting choice. These colors help inspect assignment and do not replace model materials. |
| Solid | Picks the color used in Solid Color mode. |
| Point limit | Overall point-preview budget, shared among enabled populations. Starts at 20,000; allows 1,000–500,000. |
| Points/plant | Requested shape samples per plant in Point Cloud. Starts at 80; allows 10–10,000. The point budget may reduce how much can be shown. It is not needed for one-marker Plant centres. |
| Radii / layer | Limits the number of enabled source-radius guides displayed. Starts at 2,000. Zero hides those guides when the limit is in use. |
| Show All Radii | Bypasses that radius-guide count limit. Individual sources still need Show Radius enabled. Starts off. |
| Icon size | Size of the Scatter scene icon, in scene units. Default 10. It does not scale plants or their radii. |
| Refresh preview | Explicitly updates the preview. This can also apply pending recipe edits; do not use it as a passive statistics-reading action. |
| Remove old baked output | Removes output objects owned as baked output by this Scatter. It does not mean remove the original source models. |

Some labels say “per layer,” while paint sets also consume display work as separate populations. Treat these as display ceilings and inspect the shown counts; do not assume the total across many sets equals one field's value.

Changing radius-guide limits currently requests an update too. Ordinary recipe edits in Manual still wait for an update action, but an explicit preview/radius refresh is not a promise to preserve all pending edits untouched.

## Practical use

1. Start in Point Cloud with a moderate point budget.
2. Use Plant centres to inspect distribution and spacing.
3. Use Mesh for a closer check, remembering the instance and face limits.
4. Check the layer statistics to distinguish placed plants from shown preview elements.
5. Enable Automatic final render when testing actual rendered geometry.

Displaying many meshes, boxes or radius guides still costs time even when placement is unchanged. Very large Proxy displays remain expensive. No mode guarantees a particular frame rate.

If interactive rendering repeatedly restarts while the scene is untouched, record that as a problem. It is not the intended Live behavior, and a successful ordinary render does not by itself explain the restart. The [recording guide](10_STATISTICS_AND_RECORDING.md) describes how to capture a useful report.

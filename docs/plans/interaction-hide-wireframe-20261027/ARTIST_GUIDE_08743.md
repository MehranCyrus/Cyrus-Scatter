# Hide margin and Wireframe — 0.87.4.3

Install the [Max 2027 MZP](../../../dist/CyrusScatter-0.87.4.3-20261027-r3/CyrusScatter-0.87.4.3-Max2027.mzp) with **Scripting > Run Script**, follow its result, then restart Max. This package contains the matched script and native Interactions 11 modules. Do not replace only the script.

Select the reacting plant layer and open **Interactions**:

1. Enable **Hide covered roots**.
2. For clearing grass beneath stones, choose **Hide area > Under collider**. This projects the collider's actual footprint down along world up. It also applies to floating colliders above the plants; use Inside solid if plants should remain below an overhead object.
3. Increase **Hide margin** to clear a wider area around that footprint. Zero keeps the collider's footprint. Inside solid instead uses the solid volume and a surrounding distance band.
4. Adjust **Contact gap** separately to control bending clearance. It does not enlarge the hidden area.

Hide controls update automatically. You do not need Prepare model again. In Manual mode, pending placement changes still require Update scatter. Undo and Redo restore Hide margin and the resulting coverage.

Hiding removes a whole rooted blade/stem group and its attached leaves. It does not erase triangles arbitrarily, remove scatter placements, or merely conceal root vertices. Remaining groups can bend around the collider. Moving the collider away restores the hidden groups.

Saved older scenes open with **Inside solid** and their former Contact gap copied into Hide margin, preserving the prior hiding behavior. Choose Under collider explicitly when you want the newly requested clearing beneath stones. Both distances use the current scene's units.

If a fixed root lies inside bending clearance but outside your selected hiding area, a failed update retains the previous complete result. Reduce Contact gap, enlarge Hide margin with hiding enabled, or move the collider. The plugin does not silently hide extra groups to conceal an impossible rooted fit.

**Mesh** and **Textured mesh** previews now follow the viewport's Wireframe mode, including F3. Wireframe draws triangle edges without texture opacity clipping; dense plants may need a closer view to distinguish individual edges. F3 returns to the chosen shaded preview. The mode switch reuses geometry buffers and does not regenerate placements. This patch addresses Wireframe; it does not add an Edged Faces overlay to shaded scatter previews.

See [implementation and ownership](IMPLEMENTATION_08743.md) and [executed checks and limitations](DELIVERY_08743.md).

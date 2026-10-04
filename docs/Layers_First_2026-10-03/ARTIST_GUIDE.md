# Cyrus Scatter 1.2 — layers and paint sets

4 October 2026. The UI uses ordinary Max controls. The HTML prototype is a design reference; no browser, CSS or Qt skin is embedded in Scatter.

## Install and first exercise

1. Save your scene. Run `CyrusScatter-1.2.0-Max2027.mzp` through Scripting → Run Script, then restart Max. Use the matching 2026 installer only with Max 2026. Max 2026 has SDK/native-test coverage; its actual host remains unqualified.
2. Create → Geometry → Cyrus → Cyrus Scatter. In Modify, expand General and choose the receiving surface. Brush supports one static mesh receiver, including rounded geometry.
3. Expand Layers. Add **Grass**, then **Flowers**. Each header opens that layer's complete settings. Multiple layers can remain open; scrolling inside one editor does not change which layer another editor controls.
4. In Grass → Plant assets, add your grass. Set Population and spacing as usual.
5. In Flowers → Paint sets, rename Base to **Red**, add **Blue** and **Yellow**. Select a set, then assign its Plant assets and paint its Coverage / Brush. Each set has its own source list and saved paint/erase history.
6. Adjust Flowers → Population, Area, Randomize XYZ, Collision / Relax or Spacing / Cleanup. These common controls apply to all Flowers sets. They do not change Grass.
7. In Manual mode, click **Update planting** after edits. In real-time mode, edits update the preview automatically. Cross-layer dependencies mean an update may rebuild other affected populations too.

`Cyrus_Scatter_1.2_Layers_Demo.max` is a synthetic Max 2027 scene with Grass and Flowers, and Red/Blue/Yellow paint sets. It uses simple built-in geometry and needs no external vegetation assets.

## What belongs where

| Level | Controls |
| --- | --- |
| General / Update / Viewport and Render | Receiver, master enable, Manual/real-time, update, shared display/budgets, render options |
| Each layer | Name, visible/output enable, copy/remove, statistics, population, area include/exclude and falloff, diversity, randomization/reset, collision/Relax, inter-layer spacing and cleanup |
| Each paint set | Source assets and weights/properties, share of parent population, independent paint/erase document, name/color, enable and viewport visibility |

The selected paint set changes only **Plant assets** and **Coverage / Brush**. All other sections remain bound to their enclosing layer. Copying a layer copies all its sets with new IDs and independent paint histories. Removing a layer removes its sets together; Undo restores them. The base set cannot be removed separately, but can be renamed, disabled, erased or have its sources cleared.

## Counts, painting and display

The parent count is one shared **candidate budget**. For example, 900 candidates with equal Red/Blue/Yellow weights allocates 300 to each before coverage, collision and cleanup. It is not 900 per set. Disabling a set reallocates that shared budget to the remaining enabled sets. Density mode also shares one total; its 100,000-candidate cap applies to the parent.

Painting is a procedural density mask, not direct placement of one plant per dot. Brush tint/samples visualize coverage. **Plant centres** displays one point per accepted preview plant; **Point Cloud** displays many shape samples per plant. Mesh and Proxy have independent display limits. A lower displayed count does not necessarily mean fewer final plants. Statistics show the last completed build and mark pending Manual changes; legacy-only unavailable statistics say `n/a`.

Include/exclude shapes use world XY projection. Exclude wins inside overlapping regions. The common Area policy applies to every set in that layer; it is separate from the set's surface-attached Brush mask. Closed areas may refill the requested candidate count inside the allowed region. Painting and collision can subsequently reduce it.

## Spacing and visibility

- Within a layer, enabled sets participate in the same 3D centre-spacing rule: minimum gap is twice the collision radius. Cleanup uses their accepted union, so a Red and a Blue plant can count as neighbors.
- Between layers, choose pair spacing, priority, XY versus 3D and optional source-radius footprints. These rules apply to all sets in both parents. Radius footprints are approximations, not exact mesh intersections.
- Hidden layers/sets disappear from the viewport but still participate in spacing and final output. Disabled layers/sets do not contribute to output or spacing.
- Manually edited plants keep the existing CS Edit protection/conflict semantics. Changing seed, count or set allocation can invalidate an Edit generation binding. Preserve or Undo the change, or explicitly reset Edit; the plugin does not silently discard edits.

## Current limits

Ten total population slots per controller, including each layer's base set and each added set. The UI reports capacity rather than implying unlimited children. Existing independent layers remain independent after loading an older scene; converting legacy spacing remains explicit and undoable.

Random and Clusters support multiple sets. Line Pattern and Analyzer assignment remain available on independent single-set layers; adding sets to those modes is rejected before mutation. Analyzer Area controls still require the separate Analyzer plugin.

Point Relax is paused while an enabled set in that parent has an active Brush mask. Boundary Relax remains paused under shared spacing. Stored values are retained and the UI explains the pause; these solvers have not been replaced with a paint-constrained implementation.

Native nested editors have fixed heights and native scrollbars. They deliberately keep their windows when collapsed, which avoids the former root resizing/remount behavior. Collapsing all layers leaves unused space inside the bounded Layers host. Narrow panels need vertical scrolling; arbitrary DPI layouts are not certified.

MCP 1.1 is optional and separately packaged. It supports typed plan 2.0 settings, exclusions, spacing, preview modes and actual-result export. Brush-set creation/history, map enrollment, renderer/Bake/Edit mutations and ML are not yet automated. See the accompanying capability document; local controls remain available.

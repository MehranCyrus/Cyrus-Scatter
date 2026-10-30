# Mesh selection outline — 0.87.6.5

The user requests the previous mesh-shaped yellow highlight on a single hovered
instance, a persistent outline on selected instances that disappears during
transforms, and an EXE for Max 2024, 2026 and 2027.

This is a presentation patch from delivered 0.87.6.4 to 0.87.6.5. Scene 65,
Interactions 16, Edit 4/storage 3, viewport selection 2 and recipe 9 remain.
No calculation, source preparation, placement, contact or saved selection
semantics change. F04/F05/F06/F07/F08 apply.

- Retain the separate non-rendering pick helper and stable layer/instance routing.
- Derive yellow lines from committed visible triangles, including posed/trimmed
  geometry, only for the hovered/selected instances. Never snapshot source nodes.
- Cache hover by visible generation and picked entry; cache selection by editor,
  selection revision and visible generation. Warm redraws reuse these lines.
- Admit overlay memory before construction. Optional outline failure leaves the
  complete scatter result and authored selection untouched.
- Bound detail on dense assets and large multi-selections; retain existing edit
  markers for selections beyond the outline draw budget. This never limits which
  instances can be selected or transformed.
- Suppress outlines during the native transform gesture, then restore them from
  the published result. Clearing selection/leaving Edit retires its cache.
- Max 2027 scoped host checks: individual mesh hover, click routing, persistent
  selection after pointer exit, transform suppression/restoration, Undo, posed
  geometry and unchanged placement/upload counters on warm redraw.
- Matching SDK builds and integrity-checked packages for all three requested
  hosts; runtime qualification remains Max 2027. Preserve artist sessions/scenes.

Implemented and scoped qualification completed. [Delivery](DELIVERY.md) and
[exact qualification](QUALIFICATION.json) record results and limits; this design
document does not expand that acceptance scope.

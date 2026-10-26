# Source-first Interactions — 0.87.3

Use the matching **workflow** Max 2027 MZP and restart Max. Older packages carrying
the same 0.87.3 caption have different native capabilities. This revision requires
native Interactions capability 5 and keeps saved schema 61.

[Installer, prepared trial copy and exact test scope](DELIVERY_WORKFLOW_0873.md).
Install through **Scripting > Run Script**, then restart Max. The trial opens
with 50 grass placements and 100% blade preview; the original scene is preserved.

## Sphere, stone or tree layer

1. Add the visual model to **Models & Points** and create its scatter normally.
2. In **Interactions**, choose **Layer role > Collider**.
3. A closed sphere or stone uses **Original closed mesh**. It needs no second pick
   and no plant analysis. Move a scattered copy with **Cyrus Edit**.

For a detailed tree, use **Build trunk colliders**, or **Assign custom collider...**
to pick a separately modeled closed shape for the selected source. Full visual
trees remain unchanged. A simple trunk does not reproduce exposed roots: use an
appropriate custom mesh for those. **Bounding box** is a deliberately coarse
alternative. Partial custom assignments do not switch a multi-source layer into
an incomplete configuration. Picking the visual source itself restores Original
closed mesh. Escape cancels the pick.

**Show collider** is one on/off toggle. Its temporary, frozen overlay appears at
the original source. **Frame source** brings that location into a perspective or
orthographic viewport; it does not move an instance or modify a camera.

## Grass or flower layer

1. Choose **Layer role > React to colliders**. Unprepared sources stay visible as
   ordinary scatter while the panel explains how many sources need preparation.
2. Select an **Original source model**, or use **Pick source in scene** to select
   one already assigned to that layer.
3. Click **Analyze source model**. **Show source guides** turns on automatically.
   Inspect roots, branch directions and attachments on the original model.
4. Click **Accept guides and enable**. When every source is prepared, its scattered
   copies reuse the accepted local guides with their own placement transforms.

**Show source guides** toggles the review later. Hidden source nodes get a temporary
review copy; their authored visibility is preserved. The guide overlay displays at
most 4096 guides. This display limit does not reduce the prepared definition.
Switching layers removes the previous overlay. These helpers are not render output
and are removed before saving.

There is no normal **Apply interactions** step. Role, collision shape, clearance,
coverage and preview changes update contact results automatically. Pending **Manual**
placement edits such as Amount still wait for **Update scatter**. **Advanced > Retry
contact update** retries a failed update after its cause is corrected.

## Appearance and limits

- **Preview leaves / blades (%)** accepts 1–100%. It samples whole foliage pieces;
  reducing it can make a clump look sparse. It reuses accepted guides. Full render
  and Bake are independent; source, preview-triangle and memory admissions still
  apply. This is not a remeshing percentage.
- **Contact gap** adds nonnegative clearance. Zero adds no artist gap. Conservative
  stem/foliage envelopes and the chosen collision shape can still leave visible
  space. For an overlarge tree proxy, improve the proxy rather than expecting a
  negative clearance control.
- **Hide roots under colliders** hides covered rooted groups reversibly. When off,
  those groups remain at rest and may intersect a collider; nearby uncovered groups
  still bend. The status reports retained covered roots.
- Preparation limits remain in Advanced. Increasing a limit admits more work; it
  does not make the work faster. Changed source geometry or guide settings requires
  fresh analysis and acceptance.
- When retiring a source, remove it from Models & Points and update Scatter before
  deleting its original scene node. Immediate deletion before the retained result
  updates remains an open lifetime edge case.
- **Check full visible mesh** independently checks complete visible triangles,
  anchoring and strain. It is slower than interactive preview. Its numerical audit
  is separate from renderer float delivery and final visual judgement.

The fitter now checks actual bound geometry when conservative guide envelopes
cannot fit. This fallback has explicit work and geometry limits. An unresolved
case still retains the previous complete result and reports the failure. It does
not silently shrink the collider or discard a failed plant.

This remains static contact fitting, not wind, flexible tree dynamics or arbitrary
topology reconstruction. Multiple disconnected closed solids, very dense nearby
collider sets, unsupported transforms and renderer-specific sources retain their
documented admission limits.

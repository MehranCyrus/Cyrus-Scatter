# 24 — Worked production scenario: a terraced architectural garden

**Status: original Cyrus design example, not a reconstruction of unseen video frames. Research inspiration: R0 §9.**

## 1. Scene inputs

Use a 60×40 m main terrain, two balcony slabs sharing some XY coordinates, a curved pedestrian path, a building with a large overhang, and a planting-bed outline. Assets include three tree variants, four grasses, three flower variants, two shrubs, and five rocks.

The dimensions and settings below are illustrative fixture inputs, not measured recommendations or ForestPack defaults.

Create role-based collections for receivers, tree sources, ground cover, and architectural exclusions. The balcony slabs have separate receiver UUIDs. The path and bed definitions are shared shapes, not duplicated curves.

## 2. Tree layer

Choose projected density with a fixed candidate domain, low density probability, world-up orientation, modest scale variation, and 3D sphere spacing. Use root-clearance metadata separately from canopy bounds.

Area program:

```text
1 Include main garden
2 Exclude building footprint, clipped to the selected ground-height band
3 Exclude pedestrian path with a 1.2 m clearance
```

The building's overhang is not automatically its ground-contact exclusion. The object-area representation and Top Limit decide that explicitly.

Choose a clustered species field to create broad groups without changing candidate locations. Two trees near the entrance receive manual edits: one constrained nudge, one explicit pin.

## 3. Grass layer

Use a dense image pattern or progressive density generator. Keep the source grass patches reusable. Normal alignment is enabled; tall-tree alignment remains independent.

The main terrain is a receiver, but its implicit full-surface include is disabled because the garden area supplies coverage. Exclude the path and consume the **final edited tree layer** as a root-clearance field.

Set density falloff near root clearances and height-only scale falloff near the path. The former creates gaps; the latter shortens surviving grass. The controls have independent curves.

## 4. Flower layer

Paint Region Paint on the upper balcony only, using receiver-scoped projected paint. The lower slab must remain untouched despite shared XY coordinates. Use surface-attached paint only where the receiver deforms or folds in a way projected paint cannot represent.

Choose a local source subset containing flowers and ornamental grass. Cluster size changes the species patches, not paint coverage or raw candidate density. Add a Density Paint field for intentional thinning inside part of the bed.

A paint overlay remains visible when collision rules reject plants, making it clear that the artist's coverage still exists.

## 5. Rock border

Use an open-spline corridor around the path for irregular rocks. Its width defines a band. Use Path mode instead for regularly spaced stepping stones. These are two different recipes consuming the same path definition.

Apply limited yaw, source-relative offsets where useful, and footprint boundaries. A large rock enclosing a small excluded drain must fail the footprint test even if all its vertices lie outside the drain.

## 6. Trace one flower candidate

```text
Identity: flower layer + balcony paint contribution + sample address + receiver UUID
S2: enumerate canonical sample
S3: resolve upper slab hit and UV/normal
S4: painted region, density field, slope/material-ID gates
S5: clustered source choice and transform values
S6: apply any saved edit/tombstone
S7: final receiver/boundary checks
S8: collision acceptance
S9: tint and animation sample attributes
S10: viewport subset or full renderer instance
```

If the candidate is invisible, the inspector identifies the stage. A viewport-budget omission is not a collision rejection and does not remove it from final rendering.

## 7. Change the path

The shared path definition revision changes. Grass and rock area uses become dirty over old/new path support plus their response ranges. Tree exclusion also changes. Updated trees can change grass root-clearance dependencies.

Evaluate trees first, then grass against their new final revision. The flower paint on a separately bound balcony is unchanged unless it explicitly references the path. The rock corridor updates from the path, not from the grass population.

The renderer acquires a coherent dependency closure. It cannot mix new trees with old grass clearances and claim current output.

## 8. Increase tree scale

Candidate addresses remain. Source transforms and occupancy radii change. Strict boundary checks and tree collisions rerun. Some constrained edits may become inactive; the pin remains an explicit obstacle unless its source/binding becomes invalid.

Grass updates from changed root proxies only if its configured clearance metadata depends on tree scale. A fixed-world root radius can intentionally remain constant. The dependency is explicit in that proxy policy.

## 9. Change flower tint

Only appearance attributes and relevant output representations become dirty. No source mesh reload, receiver BVH rebuild, candidate enumeration, or collision solve is required unless a custom Effect explicitly links tint to another operation.

This is a useful performance acceptance test because the expected dependency is narrow.

## 10. Move and deform the balcony

A receiver-local projected paint domain follows a rigid slab transform. It does not promise deformation-following coverage. A surface-attached domain follows compatible vertex deformation through its atlas/bindings.

After topology changes, affected paint/edits report invalid attachments. The artist chooses explicit reproject/repair with a preview. The engine does not move flowers to the lower slab merely because it is now the nearest surface.

## 11. Preview and render

Use a bounded point-cloud or proxy representation during layout. Selecting a tree temporarily increases its display detail. The full accepted population remains unchanged.

Render with a qualified adapter, shared prototypes, and per-instance attributes. Camera-only removal is off by default so off-frame trees can contribute shadows/reflections. Animation sample caches are bounded and pinned during active rendering.

## 12. Acceptance summary

The scene passes when path edits preserve independent paint, manual edits behave according to their saved policy, stacked surfaces stay distinct, changing appearance does not rebuild placement, full/incremental evaluations agree, and save/reopen/headless rendering reproduce the declared state.

This scenario is more useful than a single beauty image because it tests revisions after the initial scene has been built—the point where artists most need procedural tools to remain trustworthy.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S10]: https://docs.itoosoft.com/forestpack/forest-plugin/display

# 17 — End-to-end implementation recipes and connected feature scenarios

These are original scenario specifications for Cyrus, not claims that the commercial tutorial uses identical internal operations. Each is designed to expose interactions among multiple subsystems and to become a test scene.

## Recipe A — Lawn and winding path with worn grass

### Scene

Flat or gently sloped garden, one receiving terrain, one curved pedestrian-path spline, three grass source meshes, optional stone source.

### Authoring setup

1. Register terrain as receiver; XY projection; do **not** enable unrestricted surface inclusion if the lawn coverage is separately defined.
2. Add Lawn Include closed spline; add Path Exclude above it in ordered Area stack.
3. Add three grass sources with relative weights, explicit empty-slot probability if needed.
4. Image generator uses dense repeatable tile pattern and stable seed; apply density field for broad patches.
5. Path Exclude uses density falloff over narrow world-space range; height-only scale falloff makes near-edge grass shorter.
6. Turn on source-width collision or small-radius spacing only if appropriate for grass density.
7. Enable diagnostic overlay for Area coverage, falloff and collision rejections.

### Evaluation relationships

`terrain snapshot + lawn/path geometry -> projected candidates -> ordered regions -> grass source choice -> scale/density falloff -> collisions -> final instances`.

### Change test

Move one spline knot of Path. Exactly its geometry and dependent region fields become dirty. Candidate reservoirs and grass meshes remain cacheable. Population may require wider collision recomputation. No random rotation should change for stable surviving candidate IDs.

### Acceptance

Grass near path is shorter and/or less dense by independent controls; no unintentional full-terrain scatter; position/scale falloff match declared curves; rerun preserves stable IDs outside edited path influence.

## Recipe B — Layered forest that influences understory

### Scene

200 × 200 m irregular terrain with 5 deciduous/conifer source alternatives, 2 shrub species, 3 grasses.

### Authoring setup

1. Create Trees scatter with broad inclusion, source clusters, probability and per-tree footprint radius; slope/altitude restrictions.
2. Build Grass scatter sharing terrain acceleration and geometry cache.
3. Add Trees scatter as **exclusion input** for Grass with explicit trunk/root zone radius rather than complete crown bounds.
4. Add Shrubs scatter with partially overlapping planted regions; source grouping/boundary falloff.
5. Mark one foreground tree as artist-pinned, with source and transform override.

### Dependency graph

```text
Terrain ──┬──> Trees [clusters/constraints] ──> TreeFootprintField
          ├──> Grass [image distribution] ───────┘ (exclusion input)
          └──> Shrubs [local Area overrides]
```

### Change test

Move foreground tree and change its scale. Tree accepted result updates; derived exclusion field changes; affected Grass updates. Shrubs should not rebuild unless they depend on the same tree field or altered terrain. If a collision chain extends beyond the original local region, solver must expand/fallback.

### Acceptance

No cyclic dependencies, no duplicate terrain BVH builds, manual tree pin survives grass-density updates, per-stage counters prove limited invalidation.

## Recipe C — Architectural balconies on stacked surfaces

### Scene

Three vertically stacked terraces at identical XY coordinates, matching railing and planting-bed spline outlines, multiple receivers and a few UV-unwrapped curved surfaces.

### Authoring setup

1. Register each receiver with stable unique identity.
2. Use separate Areas or sub-spline entries for each balcony, with `Separate Sub-Splines` behavior where applicable.
3. Choose whether generation is XY-projected with explicit hit-selection or UV-bound per balcony.
4. Apply `Randomize Stacked` equivalent so overlapping XY positions don't accidentally share identical source/random transform results, when desired.
5. Restrict surface hit matching to selected balcony IDs; avoid plants teleporting to the floor above.

### Change test

Move the second balcony vertically without changing topology. Its attachments update; other floor IDs/plant variations remain stable. Delete second receiver: authored paint/manually edited items tied to it enter recoverable orphan state.

### Acceptance

No Z-crossing placements, no accidental cross-floor 2D collision under receiver-only policy, resolved orphan warning, correct save/reload.

## Recipe D — CAD marker trees and regular street furniture

### Scene

Imported CAD tree-point blocks, custom benches, lamps and a spline sidewalk.

### Authoring setup

- Trees use Reference Pivot generator, geometry match by naming convention/regex and inherited transforms where appropriate.
- Lamps use Path generator with physical arc-length spacing and fixed orientation.
- Benches use a compound source retaining seat and planter assembly local transforms.
- Empty/disabled source slots can deliberately create missing lamps/benches with selection weights.

### Change test

CAD marker moves, name changes, path is resampled, bench source enlarged. Reference identity survives move; name-matching changes only source choice; path spacing alters expected candidate anchors; bench collision stage recomputes.

### Acceptance

Stable reference tree positions, accurate path spacing including seam behavior, explicit unmatched-names warnings, correct compound source transforms.

## Recipe E — Painted flowering islands with procedural species transition

### Scene

One 40×40 m garden receiving terrain with painted flower areas and three flower sources.

### Authoring setup

1. Paint a binary include region in world-space XY with transactions.
2. Erase a small interior hole; then add another small island.
3. Compile tile coverage and distance transform; apply density falloff at edge.
4. Apply spatial source clusters within region, controlling mix and roughness.
5. Use spatial tint field to vary flower tones across the island.
6. Convert to editable spline copy and compare coverage under declared tolerance.

### Change test

Paint 1,000 additional overlapping strokes; change clustering Size only; change tint only; undo last stroke; alter whole-scatter density. Check each change touches only relevant stages.

### Acceptance

Brush overlay instantly reflects paint; generation result is correct after erase; source clustering changes source distribution rather than paint coverage; tint-only update never causes candidate or surface rebuild.

## Recipe F — Two-million-item environment and a moving camera

### Scene

Large terrain with dense grass, trees, animated leaf source, camera flythrough, preview point budget and renderer-specific output.

### Authoring setup

- Candidate buffers and accepted instance data persist as immutable snapshots.
- Point-cloud preview deterministic and decoupled from renderer count.
- Camera culling and LOD apply at output (unless camera-based density mode intentionally changes population).
- Native render instances share source geometry; shader attributes carry per-instance color.
- Animation sample cache has bounded memory, keyed by source/time sample.

### Change test

Orbit camera; compare dirty-stage counters to confirm no placement rebuild in camera-independent mode. Enable distance-based density generation and verify camera becomes a dependency. Render consecutive frames and inspect clipping, shadows, LOD transitions and materials.

### Acceptance

Stable navigation and deterministic preview subset, declared renderer capability support, bounded cache and measured output preparation time. Exact FPS/latency budgets determined after baseline.

## Recipe G — Effects with real constraints

### Scene

Garden plants near building wall and rock pathway.

### Effect chain

1. `DistanceToWall` field computes proximity.
2. `LeanAwayFromWall` rotates plants, changing footprint bounds.
3. `RepulsionFromPath` shifts XY and reprojects to surface.
4. `TintByAltitude` modifies shading attributes only.
5. Occupancy solver reevaluates after positional changes.

### Change test

Move wall only, then change tint intensity only. The first update changes spatial field and transform/constraints; the second changes only shading attributes. If a post-constraint effect is configured to move position, UI must block it or route to a constrained reevaluation stage.

### Acceptance

No stale overlaps from spatial Effects; pure tint update doesn't recompute geometry; missing wall reference disables effect safely and reports it.

## Recipe H — Full edit, save, reload and render handoff

Artist scatters vegetation, paints areas, manually adjusts heroes, assigns materials/LOD, saves scene, closes and opens on another workstation, relinks missing assets, renders Arnold/Corona/V-Ray as supported. Compare authored UUIDs, authoritative fields, manual overrides and output counts before/after. Treat derived caches as rebuildable, not source of truth.

## General template for each production recipe

Every recipe becomes one machine-readable fixture and accompanying human markdown: source versions, unit settings, seed/time, interface screenshots, scene assets, expected population counts, change sequence, dependency traces, performance metrics and known differences from ForestPack. Include at least one artist-visible screenshot and one debug-field visualization once tested in actual software.

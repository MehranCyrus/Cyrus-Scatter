# Planting groups and Brush preview diagnosis

3 October 2026. This follow-up investigates artist feedback against the installed **Cyrus Scatter 1.0.1** package in an isolated **Max 2027.1** process. It adds a diagnostic fixture and a revised implementation plan. It does not deliver a new product build or change the artist's open scene.

The recommended workflow is **one shared receiving surface, with independent Grass, Red Flowers, Blue Flowers and Yellow Flowers groups inside the same planting setup**. Brush paints the selected group's coverage. All groups participate in a common spacing system. Reuse the existing controller, group records, saved strokes, stable candidates and retained preview; correct their interaction and presentation.

The investigation confirmed two distinct problems: density dots can misrepresent the expected plant count, and the current ordering of spacing/masking/editing can reserve space around plants that do not survive. A label change alone will not resolve both.

## What the artist should manage

For the first implementation, an existing Scatter controller serves as the artist's shared planting layer. Its existing rows become named **plant groups**. This does not require another scene object or another nesting level in the command panel.

| Shared setup | Plant group | Assets | Coverage |
| --- | --- | --- | --- |
| Garden on the selected surface | Grass | One or more grass models | Whole surface, or a painted mask |
| Same Garden | Red flowers | Red flower models | Independent painted coverage |
| Same Garden | Blue flowers | Blue flower models | Independent painted coverage |
| Same Garden | Yellow flowers | Yellow flower models | Independent painted coverage |

Choose a group, choose its plants, and Paint or Erase. Another stroke extends that group's history; it does not create another plant group. Selecting Blue Flowers changes the active Brush destination and must preserve Red Flowers. Each group can contain a palette of model variants. Red, blue and yellow here identify plant groups, not RGB channels or material IDs.

Use one ordinary Max list and the existing reusable selected-group rollouts. Show the shared surface once, the active paint group prominently, and the selected group's sources, coverage, density and spacing. Avoid restoring the old nested, dynamically rebuilt rollout design. A new three-level hierarchy is not necessary for this workflow.

Independent scalar masks are still the right data representation. Red and blue coverage may overlap before spacing removes conflicting plants. A single categorical image would lose that overlap. Display colors help identify the groups; they do not replace their saved surface-attached strokes.

## What the current product actually does

The root already owns shared surfaces and multiple independent layer objects. Each layer has its own sources, count/density, randomization and optional Brush document. Brush filters that layer's candidate population; it does not create a second population.

The confusing parts are real:

- Brush has a separate receiving-surface picker. Its target overrides the shared surface for that group, and the current implementation requires a separate document for each group.
- Point Generation Count means potential candidates across the receiving surface. Painting a small region selects a subset; it does not put that entire Count into the painted patch. The default Count is 200.
- Brush's `Density %` is a further acceptance multiplier, not a new absolute number of plants per square metre.
- Within-group collision and between-group overlap removal are different controls and run at different stages.
- Coverage samples, Point Cloud points, actual placement centres and Mesh instances are different quantities.

The four-group test confirms that independent paint is already possible under one controller: initial counts were Grass 1,000, Red 249, Blue 257 and Yellow 246. Making Grass avoid the flower groups left 697 grass plants. Erasing Red left Blue at 257 and Yellow at 246, while Grass increased to 764. This used one synthetic model for every group to isolate grouping behavior, rather than qualifying real flower assets or the proposed UI.

## Why many dots become a few meshes

The Brush host creates an independent default population of **2,048 surface samples** for its mask overlay. It draws a sample when mask weight is positive and uses brightness for weight. It does not apply the layer's Count, layer density multiplier, collisions, CS Edit or Mesh budget to those dots. Soft edges can therefore show many faint dots even where very few plants are accepted.

The actual placements come from a different population and pass through more filters. Point Cloud then samples the source geometry multiple times per accepted plant. Mesh displays instances of accepted plants, subject to instance and triangle budgets.

Fresh diagnostic results:

| Synthetic case | Coverage dots | Final plants | Preview shown |
| --- | ---: | ---: | ---: |
| Plane, Count 200, one hard paint dab | 259 | 36 | 36 Mesh instances |
| Same placements in Point Cloud, 80 samples per plant | 259 | 36 | 2,880 points |
| Same placements as centres | 259 | 36 | 36 centres |
| Same placements, Mesh instance limit 7 | 259 | 36 | 7 instances |
| Same placements, face budget sufficient for 5 plants | 259 | 36 | 5 instances |
| Same plane and mask, Count increased to 4,000 | 259 | 489 | 489 Mesh instances |
| Sphere, Count 200, one soft paint dab | 309 | 22 | 22 Mesh instances |

The repeated overlay count after changing Count proves that the overlay is independent of the plant population. Uncapped Mesh and placement centres agreed on the accepted count in these tests. This does **not** establish the exact settings, loaded version or additional causes in the artist's screenshot; that open scene was not queried or changed.

Manual mode adds a timing distinction: after clearing the mask, the overlay became empty while the published preview still contained 489 plants. Update then published zero. This is the existing Manual contract, but the editor should make the pending mask change unmistakable.

### Required preview correction

Separate **Paint coverage**, **Plant centres**, **Point Cloud**, **Proxy** and **Mesh** in labels and behavior. A plant-centre marker should represent one final placement. A coverage indicator should look like a mask, preferably an optional tinted receiving-surface overlay, with a distinct appearance from centre markers.

The first step can make existing feedback explicit without waiting for a new drawing implementation. A continuous tint needs a bounded display experiment on coarse and curved meshes; simply coloring existing vertices may miss small brush features. Do not modify the artist's material, save a new bitmap automatically, or imply that coverage visualization supplies additional plants.

Show **Placed 489 / Mesh shown 489**, or **Placed 489 / Mesh shown 100 — preview limited**. For Point Cloud, label the second number as points. Separately show pending mask changes in Manual mode. Surface coverage samples are not an artist-facing plant total.

## Collision findings

### Spacing currently runs before Brush membership

Native `scatter()` applies within-group spacing before MAXScript calls `applyPaint`. On a 200 × 200 plane with 2,000 candidates and collision radius 10, spacing produced 69 candidates across the whole surface. Painting then left only 7. With spacing disabled, the same painted area contained 255 candidates. Of the rejected candidates, 37 were at least 20 units from all 7 final plants.

Those 37 cannot necessarily all coexist with each other. The test establishes avoidable exclusion relative to the final survivors, not a promise of 37 additional placements or a maximally packed result. This is a consequence of the current ordering, not proof that the native spacing grid is incorrect.

For the new group workflow, evaluate the eligible painted population before removal-only spacing. Coverage edits should retain candidate identities and saved transforms; they may legitimately change which neighboring candidates survive spacing. Do not promise an unchanged survivor set after every mask edit.

### Between-group blocking uses intermediate rows

`cachedBlockerRows` calls `placements rawOnly:true`. These rows include the blocker group's generation, within-group spacing, Brush and source transforms, but exclude its own between-group removal, final cleanup and CS Edit. This avoids recursive evaluation, but it does not describe the final visible planting.

The isolated test reproduced three consequences:

| Rule or edit | Current result | Consequence |
| --- | --- | --- |
| A avoids B; C avoids A only; all have one coincident candidate | B has 1 plant; A has 0; C has 0; raw A still has 1 | A's removed plant still blocks C. B and C are deliberately allowed to overlap in this test. |
| A avoids B and B avoids A; coincident candidates | Both finish with 0 | Mutual configuration removes both instead of choosing a winner. |
| Move B by 500 units with CS Edit; A avoids B | B moves, but a freshly rebuilt raw blocker stays at its old position; A remains empty | Edited locations and collision locations disagree; this is not just a stale cache. |

Within-group collision uses a fixed centre separation of twice its radius. Between-group removal uses a centre-distance threshold, optionally adding each source's configured radius and scale response. Planar mode ignores world Z; spatial mode uses world distance. These are artist-defined footprint approximations, not exact mesh intersection tests or a physical simulation.

### Recommended conflict rule

Use a stable priority order and the **final accepted positions** of higher-priority groups. Resolve coverage, transforms, supported edits, spacing and cleanup for a group before publishing its blockers to dependent groups. Let the common preset place painted flower groups before the base grass cover, with visible, editable priority. Grass then fills remaining eligible space. Flower groups can avoid one another with configurable gaps.

Avoid mutual recursive evaluation. A rule that two groups must keep apart needs a declared winner when two candidates conflict. Stable priority makes that decision repeatable; selecting a group or painting it most recently must not change priority. This is a deterministic greedy arrangement, not a guarantee of maximum density or optimal composition.

Keep current scenes on their existing collision policy until explicit conversion. A new policy can change output substantially. Manual moves/deletions, copied plants, final cleanup, hidden groups and saved scenes all need tests; replacing `rawOnly:true` with a recursive final call is not a safe patch.

## Source anchors

These anchors refer to product source at commit `336d18eb0ac03d7e98f6655af6bd70f9a714624c`; line numbers may move after implementation.

| File | Relevant location |
| --- | --- |
| `AminScatter/src/brush_host.cpp` | Default independent sample capacity at line 71; overlay evaluation at 166; drawing at 242; actual keyed population filtering at 354 |
| `AminScatter/scripts/AminScatterObject.ms` | `cachedBlockerRows` at 947; `cspImpl_placements` at 969; `applyPaint` at 1023; inter-group removal at 1041; CS Edit at 1077; preview generation at 1107 |
| `AminScatter/tools/ui/templates/brush-integration.ms` | Authoritative Brush UI, separate target picker, density multiplier and mask publication |
| `AminScatter/tools/ui/templates/brush-session.ms` | Overlay refresh during the active Brush session and publication after committed revisions |
| `AminScatter/src/scatter.cpp` and `spacing.inc` | Within-group spacing before returning the generated candidates; removal threshold `2 * collisionRadius` |
| `AminScatter/src/geometry_preview.inc` | Source copying and Mesh instance/face limits |
| `AminScatter/src/preview.cpp` | Source point sampling and Point Cloud budget |

## Evidence and next work

The [implementation plan](PLANTING_GROUPS_IMPLEMENTATION.md) is the next-work authority for this feedback. It advances the existing artist-zone proposal; it does not replace its later zone/map/MCP contracts.

Reproduction is in [group_mask_diagnostic.ms](../../tools/v1/group_mask_diagnostic.ms). The [diagnostic results](evidence/group-mask-diagnostic.json) and [provenance](evidence/group-mask-provenance.json) record the tested package, actual loaded modules, source hashes and scope. These are characterization tests of current limitations, not passing acceptance tests for the proposed solver.

No new viewport FPS claim, renderer qualification or Max 2026 host qualification is made by this investigation. The production engine, installed artist plugin and original scene remain at their prior state; only developer diagnostics and documentation were added.

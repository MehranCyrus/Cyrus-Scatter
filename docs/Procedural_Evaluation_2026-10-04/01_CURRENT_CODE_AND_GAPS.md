# 01 — Current implementation and gap analysis

Baseline: Scatter 1.2.3, MCP 1.1.0, commit `e3518f8f87f3144d531f20afbb6790ce243f2cfc`. Findings below are static source observations unless explicitly described as historical evidence. No current-scene execution or benchmark was performed for this guide.

## Read the generated program and its generators together

The shipped MAXScript is [AminScatterObject.ms](../../AminScatter/scripts/AminScatterObject.ms). Its behavior is assembled by [generate.cjs](../../AminScatter/tools/ui/generate.cjs). The late [layers-first transformer](../../AminScatter/tools/ui/layers-first.cjs) materially changes the earlier [planting-model template](../../AminScatter/tools/ui/templates/planting-model.ms).

For example, the final program normalizes layer-pair rules to logical parents, adds sibling-set spacing, allocates a shared population and performs cleanup over the sibling union. Reviewing the planting template alone misses those behaviors. Future edits must update the appropriate generators/templates and regenerate the artifact; editing only the generated script is not a maintainable fix.

## What exists, what is missing

| Area | Verified current behavior | Required extension |
| --- | --- | --- |
| Ownership | A parent population is also the base set; child population objects reference `logicalParentID` | A normalized evaluation view of Layer + Sets, without immediately replacing scene storage |
| Set autonomy | Each set owns sources, weights, source radii and Brush history | Independent spacing rules for self versus sibling sets; preserve existing source/coverage ownership |
| Shared defaults | `syncLogicalSettings` copies most parent fields to children | Explicit effective-settings resolution; prevent new set overrides being silently overwritten |
| Population | Parent amount is allocated by enabled set weights using largest remainders; density is shared similarly | Clearly separate legacy candidate budget from accepted target/replenishment |
| Ordering | Descending `groupPriority`, then stable parent/leaf Edit keys | Persist and display the effective order; explicit move-up/down semantics |
| Within-set spacing | Native `withinDistance = 2 * collisionRadius`; fixed 3D centre distance | Set-specific rule, variable radii and explicit metric |
| Between-set spacing | Siblings use the same parent collision toggle/radius, with zero per-source radii in that rule | Sparse set-pair rules plus defaults, independently adjustable |
| Between-layer spacing | Parent-pair enabled/gap/footprint/XY-or-3D rules; optional source radii | Unify rule representation and add radius multiplier; retain compatibility |
| Cleanup | Removal-only cleanup on accepted union of a logical layer before another layer consumes it | Account for holes released inside that layer; bounded repair/refill contract |
| Manual edits | Protected rows reserve actual positions; conflicting edits survive and are counted | Preserve this exception, report pair-level conflicts, add separately keyed radius overrides |
| Prepared cache | Per-population prepared rows, brush/base caches and a controller result snapshot | Narrow revision domains and dependency-aware reuse |
| Final cache | Whole-controller string key and final rows; publish after enabled groups succeed | Layer-result dependencies and transactional publication using unchanged results by reference |
| Display | Retained Point Cloud and Mesh; cached/batched Proxy path; display budgets separate from final output | Preserve paths; new solver outputs adapt to existing preview builders |
| Statistics | Requested/eligible/placed/removed/shown/build time/errors, aggregate protected conflicts | Exclusive rejection reasons, fill outcomes, per-stage timing and attributable cache accounting |
| Automation | Nine bounded MCP tools; typed current settings, configuration and actual-result export | New versioned fields/operations only after native contracts pass tests |
| ML | Export/lineage contracts; no trained model or learning runtime | Future recipe consumer, not a prerequisite for this solver |

### Population example

With one layer, 500 requested candidates and three enabled equal-weight sets, allocation is **167, 167, 166** in stable membership order. Coverage, source policies, collision and cleanup can reduce each result. The engine does not transfer unused shares to another set or guarantee 500 final plants.

### Current evaluation trace

The final generated `evaluateGroups` currently:

1. Synchronizes logical settings and shared surfaces.
2. Builds the controller key; returns its completed snapshot on a match.
3. Prepares enabled populations, including coverage/transforms and CS Edit application, and collects protected rows.
4. Sorts populations by priority and stable parent/set keys, keeping siblings together.
5. Resolves each population against earlier accepted rows and protected rows from populations not yet completed.
6. Applies layer-union cleanup when the last sibling has completed.
7. Publishes Edit results and installs the final controller snapshot only after all enabled populations succeed.

This already avoids several older raw-blocker errors. Do not describe all previous ghost-blocker problems as still present. The remaining distinction is that an earlier sibling can be removed by union cleanup **after** a later sibling was rejected; no automatic sibling retry then fills the released hole. Later logical layers do see the cleaned union.

## Specific source findings

| Source / stable symbol | Finding and significance |
| --- | --- |
| [logical-layers.ms](../../AminScatter/tools/ui/templates/logical-layers.ms): `populationAllocation`, `syncLogicalSettings`, `cleanLogicalLayer` | Shared budgets/defaults and a parent cleanup barrier are real dependencies. Sets cannot be treated as completely independent nodes. |
| [layers-first.cjs](../../AminScatter/tools/ui/layers-first.cjs): transformations of `groupPair`, sibling rules and cleanup | Parent rules are not current set-pair rules. This is a principal integration point. |
| [AminScatterObject.ms](../../AminScatter/scripts/AminScatterObject.ms): `placementRadii`, `evaluateGroups`, `paintBaseInputKey` | Effective radius currently uses source radius and optionally the largest transform-row length. Post-spacing settings are excluded from prepared-base keys under shared spacing. |
| [group_spacing.h](../../AminScatter/include/group_spacing.h), [group_spacing.cpp](../../AminScatter/src/group_spacing.cpp) | Pure numeric solver; per-rule uniform grids, external radius sums, fixed-distance self-grid, protected-first deterministic acceptance. A strong reusable core. |
| [group_spacing_bridge.inc](../../AminScatter/src/group_spacing_bridge.inc) | MAXScript/native boundary returns original kept rows and a conflict count; cleanup also preserves original rows/identities. Extend with typed diagnostics rather than losing row ownership. |
| [final.inc](../../AminScatter/src/final.inc) | Cleanup computes neighbors/components on its input and performs one removal pass. It is not an iterative minimum-degree guarantee on the surviving graph. Keep that meaning explicit. |
| [scatter.h](../../AminScatter/include/scatter.h), [scatter.cpp](../../AminScatter/src/scatter.cpp) | Candidate keys exist before rejection. Separate source/placement/transform streams and a bounded CPU parallel path exist. They do not establish arbitrary cross-setting identity stability. |
| [brush_host.cpp](../../AminScatter/src/brush_host.cpp), [brush.h](../../AminScatter/include/brush.h) | Indexed surface snapshots and face/barycentric anchors support static curved painting. Arbitrary topology changes are not equivalent to repainting a flat bitmap. |
| [retained-points.cjs](../../AminScatter/tools/ui/retained-points.cjs), [point_display.cpp](../../AminScatter/src/point_display.cpp), [mesh_display.inc](../../AminScatter/src/mesh_display.inc) | Point/Mesh generations retain device buffers. Stable warm drawing should not rebuild them. Device loss or changed display data is a legitimate rebuild. |
| [preview.cpp](../../AminScatter/src/preview.cpp), [preview_batches.inc](../../AminScatter/src/preview_batches.inc), [geometry_preview.inc](../../AminScatter/src/geometry_preview.inc) | Proxy preparation/batching and preview limits already exist; Proxy is not simply the same retained path as Mesh. |
| [layers-first-details.ms](../../AminScatter/tools/ui/templates/layers-first-details.ms) | Statistics read the last completed build. Help already distinguishes coverage samples, plant centres, display limits and hidden versus disabled. |
| [settings.py](../../CyrusMCP/cyrus_mcp/settings.py), [models.py](../../CyrusMCP/cyrus_mcp/models.py), [records.py](../../CyrusMCP/cyrus_mcp/records.py) | Closed automation settings and generation-scoped export lineage; new fields must be explicitly supported. |

Generated-script anchors at this baseline include `placementRadii` near line 12600, `populationAllocation` near 12846, `groupInputKey` near 13027, `evaluateGroups` near 13062 and `paintBaseInputKey` near 13609. Prefer symbols over line numbers after regeneration. Source hashes are recorded in [the snapshot](evidence/source_snapshot.json).

## What we got right

- Separating compact placement information from source geometry and viewport representation.
- Preserving deterministic candidate identity through rejection rather than re-numbering kept rows.
- Applying edits before shared collision and reserving protected positions.
- Keeping native numerical work free of Max API calls in the group solver.
- Publishing completed results and supporting Manual mode.
- Retaining native UI, reusable preview resources, source metadata and bounded automation.

## What needs correction or clarification

- The UI ownership model became richer faster than the spacing contract. A Paint Set looks independent, but its self and sibling spacing are still one setting.
- Paint coverage, requested candidates, final plants and cloud samples are different quantities. A dense paint overlay is not a promise of an equally dense mesh result.
- Radius values exist, but they do not currently drive all three scopes. Nor are source radii a persisted per-instance override system.
- Broad controller/global revision keys limit selective reuse. Do not replace them with incomplete keys: missed invalidation is worse than extra calculation.
- Execution uses numeric priority and stable creation keys, not simply visible row position. Showing an unrelated list order is misleading for a top-to-bottom workflow.
- Parent cleanup creates a real dependency barrier. Treating every Paint Set as independently final would be incorrect.
- Current radius scaling is appropriate for ordinary scale/rotation transforms; its largest-row-length formula is not a general conservative bound for arbitrary shear. Test and define such transforms before promising exact footprint bounds.

The [existing native tests](../../AminScatter/tests/group_spacing_tests.cpp) include 180 comparisons against an exhaustive oracle, protected edits, boundary distances and dense coincident candidates. This guide inspected those tests; it did not rerun them. New three-scope and refill behavior needs new oracles rather than borrowing historical pass claims.

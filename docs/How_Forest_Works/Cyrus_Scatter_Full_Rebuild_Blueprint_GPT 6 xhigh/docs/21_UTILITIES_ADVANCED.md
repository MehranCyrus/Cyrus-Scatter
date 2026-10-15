# 21 — Shared input collections, libraries, utilities, ForestIvy and specialized extensions

## 1. Keep the family of tools separated

"Replicate all ForestPack" can mean several distinct deliverables: Forest scatter object/rollouts, material helpers (Forest Color/Edge), ForestLOD, ForestSet, library management, Forest Lister, bake/conversion scripts, and ForestIvy. These are not one engine feature and should not share one unbounded milestone.

## 2. ForestSet-like shared input collections

**[FP-DOC]** ForestSet exposes reusable scene groups/collections used in source, surface, area, reference and path contexts; nested and scene-layer-driven behaviors have documented restrictions. [ForestSet](https://docs.itoosoft.com/forestpack/forestset-plugin).

### Design

`InputCollection {UUID, members[], dynamicLayerQuery?, nestedCollections[], rolePolicy}`.

A Geometry collection may supply one randomly selected source; a Surface collection often supplies all eligible receivers; a Spline collection may represent multiple region/path inputs. Role-specific adapters must be explicit so the same collection type doesn't behave mysteriously depending on context.

Manage nested collections as DAGs; detect cycles and empty/missing members. Dynamic membership updates via host scene-layer notifications, not constant polling.

### Example

```
Master Landscape Collection
  terrain: Landscape_Main
  footpaths: Pedestrian_Path_* (dynamic layer membership)
  exclusions: Building_Outline_*

Grass Scatter: terrain + footpaths as exclusion
Trees Scatter: terrain + exclusions as clearance
Flower Scatter: terrain + footpaths as distance-driven density field
```

## 3. Linked Areas

Shared definition (spline/object/paint source) with local behavior (falloff, source subset, density response) per scatter. Preserve link source UUID, actual region geometry revision and local parameter overrides. Changing master boundary invalidates all consumers; changing one consumer's falloff should not invalidate others. Define what happens when master area is deleted or its type changes.

## 4. Scatter manager / Forest Lister equivalent

Scene-level table of all scatters with name, status, enabled, selected source count, accepted count, viewport mode, manual/auto update, dirty state, render visibility, cache memory and recent build times. Bulk actions: set update mode, freeze/unfreeze, choose display quality, refresh surfaces, choose renderer profile, validate links, export list and select scene objects. All changes create clear Undo actions where authored state changes.

## 5. Forest Tools equivalent

Bake/convert procedure:

1. Capture selected scatters and exact frame.
2. Choose output type: standard Max instances, clones, combined mesh, external manifest or compatible proxy group.
3. Validate estimated nodes/faces/memory before operation.
4. Convert source transforms and grouping without changing world-space meaning.
5. Preserve source/material IDs where possible.
6. Execute undoable host operation; optionally hide (not delete) original scatter.
7. Produce report on omitted unsupported source types and approximate output size.

Mass conversion to 100,000 Max scene nodes is often prohibitively heavy; don't offer it as a silent default.

## 6. Asset library

Support thumbnails, tags (grass, shrubs, flowers, trees, architectural props), preview geometry bounds, material/renderer variants, source categories, recipes and scene setup collections. Store metadata separately from actual scene-instantiated geometry. Respect asset licensing; never bundle ForestPack's copyrighted commercial vegetation without authorization. Scene preset portability and user library roots belong to the asset resolver (chapter 20).

## 7. ForestLOD and material helpers

LOD and Color/Edge-style helper functions should be independent modules exposed through source/renderer interfaces. For example, a source can declare multiple LODs and all renderer adapters consume the resolved selected level. Color/Edge material helper nodes must be recreated independently, not copied shader code; prioritize artist-visible output parity and clear support caveats.

## 8. ForestIvy is a separate plant-generation system

**[FP-DOC]** ITOOSOFT documents ForestIvy as a distinct procedural system for ivy/growth-related work, rather than merely an ordinary scatter distribution mode. [ForestIvy overview](https://docs.itoosoft.com/forestpack/forest-ivy/forest-ivy-overview).

A serious independently built equivalent would need its own architecture:

```text
Guidance curves / start seeds / attraction fields
  -> surface-following branch propagation
  -> collision and support attachment
  -> branching grammar / growth state
  -> branch geometry synthesis
  -> leaf/flower instancing
  -> wind and growth animation
  -> material/renderer output
```

Requirements to define: growth direction (gravity, light, attractors), branching probability and pruning, attachment strength to walls, tip collision, self-avoidance, vein geometry, per-leaf orientation, growth time, controllable vine silhouettes and temporal consistency. This is **not covered in sufficient detail by the provided Forest scatter tutorial or current research** to claim full ForestIvy parity. Treat it as a separate research/specification project after core scatter platform is stable.

## 9. Legacy billboard shadow modes

ForestPack's Shadows rollout includes historical billboard-specific workflows and renderer-specific behavior. These may not be relevant to a modern archviz mesh-centric deployment. Track separately with documented deprecation/renderer decisions; do not let them delay core geometry/renderer parity.

## 10. RailClone and external systems

A RailClone-aware adapter should use public documented data/SDK contracts to consume segment transforms, source mapping tags and metadata. Do not reverse-engineer private scene formats. The generalized external provider should support stable IDs, time, attribute schema and per-element transforms so future integrations (CAD/BIM/particle/geometry nodes) do not require a new core engine.

## 11. Remote automation / MCP interfaces

For Cyrus's scene-building workflows, expose a **versioned command API** above the domain model:

```
CreateScatter(name)
AddSources(scatterId, sourceIds, probabilities)
AssignReceivers(scatterId, receiverIds)
SetGenerator(scatterId, spec)
AddArea(scatterId, areaSpec, order)
PaintCoverage(scatterId, areaId, worldOrUVStroke)
SetFalloff(areaId, curve, range)
SetSourceCluster(scatterId, params)
GetScatterStats(scatterId)
EvaluateScatter(scatterId, quality)
GetInstancePreview(scatterId, region, cap)
```

Commands validate active scene, user selection and permissions, return structured errors, use Undo transactions and never expose raw unsafe C++ pointers. Bulk commands should be atomic where possible. An LLM agent can then create a scene using this API while retaining human review and deterministic scene state.

## 12. Prioritize extensions explicitly

- **Core-dependent helpers (high):** shared input collections, linked areas, diagnostics manager, library and bake tools.
- **Renderer-related (medium):** Color/Edge helper equivalents, specialized LOD and animated sources.
- **Specialized (separate):** ivy growth/wind, old billboard shadow modes, complex third-party procedural source protocols.

Do not claim comprehensive ForestPack ecosystem parity until separate acceptance matrices cover every component.

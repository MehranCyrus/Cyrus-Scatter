# 10 — Collisions, boundary checking, cross-scatter exclusion and manual editing

## 1. The three different constraint problems

1. **Candidate-to-candidate overlap:** two selected items conflict with geometric spacing rules.
2. **Item-to-region boundary:** a plant center or footprint lies outside a permitted region.
3. **Inter-scatter relationship:** grass or rocks must avoid trees, paths, buildings or another procedural population.

They use related spatial data but have different dependency and ordering semantics. Never put them behind one undocumented `avoidOverlap()` function.

## 2. ForestPack's documented collision model

[FP-DOC] ForestPack documents scattering items then deleting colliding neighbors using virtual bounding spheres; per-source `Geometry > Collision Radius` is multiplied by a global collision-radius percentage, while `Height` adjusts sphere center. Dense candidates can create many rejected items with little gain in final count. Collision support was expanded to Path/Reference/PFlow in release 9.3.5. [Image docs](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode) · [Release notes](https://docs.itoosoft.com/changelog/2026/03/15/forestpack-9_3_5).

The precise winner-selection algorithm, 3D/2.5D sphere interpretation under nonuniform scaling, and processing order are **[TEST-NEEDED]**.

## 3. Proposed Cyrus collision shape

```cpp
struct CollisionProxy {
    CandidateId candidate;
    Vec3 center;
    double radius;
    float priority;
    uint32_t compatibilityMask;
};
```

`center` derives from final transforms + configured height offset; radius from source dimensions × per-source radius × global factor × relevant scale. For tall trees, the collision region might represent trunk footprint, crown, or a configurable physical envelope; do not equate tree mesh bounds with plant-spacing intent. Optional later ellipsoids/capsules/convex footprints are Cyrus extensions.

Narrow sphere test in 3D: `dot(A.center-B.center,A.center-B.center) < (A.radius+B.radius)^2`. A 2D circular-footprint test ignores Z; which mode is correct depends on intended behavior, particularly stacked floors. Expose **2D projected spacing**, **3D spherical spacing** and **same-receiver-only** policies as distinct modes if implemented.

## 4. Broadphase and narrowphase

Naive `O(N²)` is unacceptable for large populations. Use a sparse spatial hash grid, BVH or neighborhood bins to find nearby candidates; then evaluate exact chosen proxy tests. For variable source radii, choose grid cell size carefully or multi-level bins; enormous objects can span many cells. Record candidate and pair-test counts.

Simple spatial-hash scheme:

```text
For each candidate in deterministic priority order:
    derive effective shape
    query grid cells intersecting shape bounds
    inspect accepted contenders from those cells
    if no incompatible overlap: accept and insert into cells
    else: mark rejected (winner/loser reason)
```

This is a fast **greedy** solver and not necessarily ForestPack's method. Its output depends on priority/order; define stable candidate priority independent of worker thread order. Avoid emitting accepted items in hash-table iteration order.

## 5. Winner policy and stability

Possible policies:

- Lowest immutable priority hash wins (deterministic).
- Earlier procedural Area contribution wins.
- Larger source gets priority (spatially useful, but source changes cascade).
- Artist-pinned manual items win over generated candidates.
- Local layer precedence controls cross-layer collisions.

Choose one default and make exceptions explicit. A visually stable user workflow generally benefits from preserving already accepted candidates when density increases, but that is not always achievable under all global constraint rules. Document what can and cannot be promised.

## 6. Incremental collision solving

A paint edit changes candidate acceptance inside region. If a removed accepted item previously blocked a rejected neighbor, that neighbor may become valid and then block another accepted item. This **propagation chain** can exceed one tile halo. A single dirty-bounds expansion isn't a proof of equivalence.

Recommendation:

1. Begin with deterministic full occupancy recomputation and profile.
2. Add conflict graph `candidate ↔ conflicting candidates`, stable winner IDs, and region-indexed dependencies.
3. On change, activate reevaluation frontier until stable or budget/time limit reached.
4. If frontier grows beyond threshold, fall back to full rebuild (same semantics).
5. Differential-test random edit sequences against full solution.

Do not sacrifice correctness for claimed "only modified tiles" updates.

## 7. Boundary checking

**[FP-DOC]** ForestPack exposes Point, Size and Edge approaches. Point tests placement pivot, Size tests approximate item extent/clearance, Edge can remove renderable geometry elements near boundaries without Boolean clipping, with renderer-dependent mechanisms (V-Ray native and Forest Edge map for some renderers). [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) · [Forest Edge](https://docs.itoosoft.com/forestpack/forest-edge-map).

### Point

`inside(region, pivot)`; fast, geometry may extend outside. If random translation happens afterward, result may visually overflow.

### Size

Require approximate footprint inside region, e.g. `signedDistanceInside(pivot) >= radius` in appropriate signed-distance convention. Different geometry aspect ratios warrant oriented bounding footprints rather than one circle if parity/quality requires.

### Edge/Element trimming

Treat independently per renderable sub-element (usually connected faces and material grouping), based on boundary tests of anchor points or shader cutout. Don't promise clipping arbitrary triangles. Shader-side cutouts require appropriate material insertion and renderer support, and viewport may not preview exact final result.

## 8. Cross-population suppression

ForestPack's Forest Area may use spheres or meshes to exclude other instances. For Cyrus use directed field contributions, not uncontrolled mutual collision. Tree → grass exclusion can query stable accepted tree occupancy; tree source scale changes invalidate related grass fields. Give users scale multipliers, root/trunk footprint selection and directional graph visibility. Cycles rejected by default.

## 9. Manual edits require a persistent overlay

[FP-DOC] ForestPack documents separate Generate/Custom Edit modes with warnings; manual edits in Custom Edit are **not proof** of arbitrary regeneration-stable overlays. [Items Editor](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor). Cyrus can improve here, integrating existing CS Edit after repository audit.

```text
Generated candidate population
  -> accepted instance list
  -> suppressions by stable ID
  -> source replacements
  -> transform overrides
  -> artist pins / forced priority
  -> explicit manually added instances
  -> final validation / viewport/render
```

Keep authored overrides separate from generated instance data. An artist should be able to move a hero tree, later change global plant density, and still retain that edit when the target candidate exists and conditions allow.

## 10. What if a source instance disappears?

State machine:

`ACTIVE_OVERRIDE`: candidate exists; override applied.

`SUPPRESSED_BY_RULE`: candidate exists but no longer accepted; preserve override, do not render by default.

`ORPHAN`: candidate ID or attachment invalid; preserve data with warning.

`PINNED_MANUAL`: convert to durable manual instance independent of candidate generator.

Define policies `preserve hidden`, `convert to manual`, `attempt spatial rebind` and `discard with confirmation`. Default should never silently delete authored work.

## 11. How manual moves affect constraints

Consider artist moves tree A into generated tree B. Policies:

- **Pin wins:** B is suppressed; reevaluate collision chain.
- **Warn but allow overlap:** both remain, user explicitly accepts visual intersection.
- **Constrain manual move:** snap/limit A to free space.

Choose a clear default and provide a per-override "Ignore collisions" flag. Don't let a hidden solver silently move an artist-pinned tree against their instruction.

## 12. CS Edit interaction contract

Before integrating, audit existing CS Edit data model. The target contract should provide:

- Stable `InstanceId` pick/selection across viewport modes.
- Batch selection/transform/source replacement on sub-object-like instances.
- Undo grouping for moved/deleted/replaced selections.
- Clear separation between "regenerate variety" and "delete this instance".
- Rebinding/orphan tool when scene geometry changes.
- Reliable camera/renderer output for edited instances.

Do not rewrite CS Edit until its present responsibilities are cataloged and tested.

## 13. Example: path moves after local tree editing

1. Tree A was generated inside a grass/tree region.
2. Artist rotates Tree A and pins its transform.
3. Footpath spline moves into A's footprint.
4. Area Exclude marks A as ineligible.
5. UI indicates pinned edited tree conflicts with exclusion.
6. User chooses: respect exclusion (temporarily hide), keep pinned as manual, or relocate/rebind.
7. Decision is serialized and undoable.

An engine that simply deletes A from an output array loses design intent and breaks trust.

## 14. Acceptance tests

- Collision winner independent of worker count and hash-map iteration order.
- Candidate counts and collision rejection diagnostics agree with final output.
- Dense saturating area doesn't spawn ever-growing candidate work without warnings.
- Size boundary rejects an oversized object while Point may allow it.
- Exact Edge behavior matches each renderer's declared capability.
- Stacked balcony items do not collide under same-receiver-only policy.
- Incremental occupancy matches full rebuild over hundreds of random add/remove cases.
- Manually moved/pinned item survives source/tint/density updates according to contract.
- Orphan state survives save/load; no silent fallback to world origin.
- Undo collision-relevant edit restores exact prior accepted IDs/overrides.

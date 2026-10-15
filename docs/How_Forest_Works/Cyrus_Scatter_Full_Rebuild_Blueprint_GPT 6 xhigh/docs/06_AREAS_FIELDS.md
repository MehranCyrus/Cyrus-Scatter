# 06 — Ordered Areas, spatial fields, splines, object exclusions and falloffs

**Primary reference:** [ITOOSOFT Areas rollout](https://docs.itoosoft.com/forestpack/forest-plugin/areas). **Important [FP-DOC]:** documented types include Spline, Object, Forest, Paint and Surface; Areas process from bottom to top; linked areas inherit source-specific parameters while some common properties are local. Object exclusions use projected masks; Forest exclusions can use virtual spheres or mesh representation. Exact behavior across older/newer versions must be version-tagged.

## 1. The core problem: areas are ordered operations, not one unordered mask

Consider the list, bottom to top:

```text
3 Include flower island  ← evaluated last
2 Exclude walkway
1 Include garden          ← evaluated first
```

An implementation `union(all includes) - union(all excludes)` is **wrong** for this behavior: the final Include can add plants after an earlier Exclude. Forest documentation warns that Include areas may overlap, causing overlapping instance geometry. [FP-DOC]

### Recommended Cyrus representation

```cpp
enum class AreaKind { Spline, Object, Scatter, Paint, Surface, Linked };
enum class AreaOperation { Include, Exclude };

struct AreaDefinition {
    Uuid id;
    AreaKind kind;
    bool active;
    AreaOperation operation;
    SpatialReference input;
    AreaOverrides overrides;
    FalloffConfiguration falloff;
    BoundaryPolicy boundary;
    int visualOrder; // explicitly persisted; bottom-to-top semantics
};
```

Object and Scatter Area modes should expose only combinations supported by our capability matrix; ForestPack documents them predominantly as exclusion inputs. A `Surface` may be a placement receiver independent of being active as a covering Include.

## 2. Ordered evaluator with contribution provenance

A robust conceptual model is a list of **population contributions**, each tagged with the Include that generated it.

```text
contributions = []
for area in bottom_to_top(activeAreaStack):
    if area.op == Include:
        candidates = generateForRegion(area)
        candidates = applyAreaSpecificDistributionOverrides(candidates, area)
        append(contributions, tag(candidates, origin=area.id))
    else:
        removeContributionsInsideArea(contributions, area)

apply_remaining_common_rules(contributions)
```

This is **not guaranteed to be ForestPack's internal implementation**. It reproduces the essential ordered behavior while preserving provenance. Two candidate sets produced by overlapping Includes may coexist; a global deduplication option would be a separate Cyrus policy, not automatic parity.

**Open design point:** at which exact stage each Area's local source subset, probability, scale and falloff is applied must be determined by reference tests. Candidate-specific provenance should allow us to encode that policy without redesigning all data structures.

## 3. Spatial region interface

```cpp
struct SpatialQuery {
    Vec3 worldPoint;
    Vec2 uv;
    Optional<SurfaceBinding> receiver;
    uint32_t projectionAxis;
};

struct RegionSample {
    bool inside;
    double signedDistance;    // negative inside, positive outside — Cyrus convention
    Vec3 nearestBoundary;
    Vec3 boundaryNormal;
    Uuid regionId;
    bool valid;
};

class IRegionEvaluator {
public:
    virtual RegionSample Query(const SpatialQuery&) const = 0;
    virtual Bounds3 ConservativeAffectedBounds() const = 0;
    virtual RevisionInputs Dependencies() const = 0;
};
```

Not all regions are true signed-distance fields. For raster masks, nearest-boundary distance can be a separately compiled distance transform. `valid=false` is required when a projection is ambiguous or no receiver is hit.

## 4. Spline region algorithms

### Closed outlines

- Snapshot every contour, winding, transform and knot configuration.
- Flatten to line segments with chosen world-space approximation tolerance; preserve contour/hole metadata.
- Inside test via robust winding rule or even-odd rule; **declare the policy** for nested contours and self-intersections.
- Signed distance from point to nearest segment; build segment BVH/grid for acceleration.
- Resolve heights/axes: XY-plane projected outlines, or explicitly specified UV/axis projection.

**Complexity:** naive nearest-segment queries for `N` plants and `M` segments cost `O(N*M)`; grid/BVH reduces normal workloads dramatically.

### Open bands / Force Open

Open curves become a corridor around the path with chosen half/full `Thickness` semantics. Evaluate signed distance to the polyline and compare with band width. **[TEST-NEEDED]** Match exact ForestPack Thickness interpretation and corner/cap rules. Configurable caps (`round`, `square`, `butt`) and join policy (`miter`, `round`, `bevel`) should be explicit Cyrus settings if diverging.

**Do not confuse open corridor region with Path generator's evenly spaced placements.** They share spline data but use different samplers.

### Multiple sub-splines

Preserve sub-spline identities; support `Separate Sub-Splines` as independently evaluated region contributions. Define overlaps between distinct sub-splines and their local source restrictions.

## 5. Object exclusion masks

**[FP-DOC]** ForestPack projects object geometry along world Z into a black-white bitmap. It documents `Resolution` (commonly default 512 pixels), footprint `Scale`, and `Top Limit` to disregard high geometry. [Source](https://docs.itoosoft.com/forestpack/forest-plugin/areas).

### Recommended independent implementation

1. Capture object triangle snapshot (evaluated with correct transform and time).
2. Filter relevant triangles according to Top Limit; define whether world/local Z and clipping/intersection are used.
3. Determine projected footprint bounds and target raster resolution.
4. Rasterize triangles conservatively into coverage tiles, then build optional distance transform.
5. Apply padding/erosion for `Scale` in units meaningful to artist; if matching Forest behavior, validate percentage semantics.
6. Cache by geometry revision + projection + resolution + policy.
7. Query samples with declared binary filtering/precision; compile to GPU texture only if needed for overlay.

If a 100 m footprint is rasterized to 512 pixels across its width, pixel pitch is approximately `100/512 = 0.195 m`. This illustrates why fixed pixel resolution loses detail in large scenes; it is not a ForestPack error measurement.

Prefer a user-facing **target world-space accuracy** mode backed by adaptive tiles, with a legacy/resolution-parameter mode for parity.

### Tall and stacked geometry problem

A pure XY mask does not distinguish under a roof from above a roof unless `Top Limit`, other height filtering or 3D occupancy is added. Support a separate future **3D Volume Exclusion** feature, clearly labeled as a Cyrus extension.

## 6. Scatter-driven exclusion / cross-population field

Take another scatter's stable accepted positions and effective per-source collision footprints. Represent as:

- Spheres: spatial index over center/radius with area scale.
- Mesh footprints: cached projection/coverage derived from geometry, more accurate but expensive.
- User-defined footprints: explicit trunk/root zone, optional radius curve, physically meaningful for landscaping.

Declare directed dependency `Trees → Grass`. If Trees change, Grass exclusion field invalidates; if Grass changes, Trees need not rebuild. Reject cyclic dependencies unless the user explicitly creates frozen snapshots/iterative solver policy.

## 7. Paint regions

Painted coverage compiles to a spatial region evaluator. Brush strokes and erase operations are handled in `08_PAINT_ENGINE.md`. **[FP-DOC]** ForestPack Paint Areas support include/exclude, pressure-sensitive size, erase, falloff preview and conversion between paint and spline. Its published paint workflow expects a receiving Surface in XY mode (with unrestricted surface inclusion disabled). General Area UV support in ForestPack 8 does not imply every Paint/UV combination is equivalent.

## 8. Surface entries: two roles, one frequent user mistake

A Surface can:

1. Supply a physical receiver for projected candidates.
2. Act as an unrestricted **Include area** if enabled in the Area stack.

The artist often wants the first role without the second. UI should label these independently, e.g. **Use as receiver** and **Fill entire surface**. Do not auto-disable valid user-authored coverage silently; offer a contextual warning when a painted region is present but the receiver is still unrestricted Include.

## 9. Local Area overrides and precedence

Store every setting as one of: `Inherit`, `Replace`, `Multiply`, `Add`, or `CustomOp`; not a plain numeric value whose semantics depend on unrelated code. Proposed examples:

| Setting | Global | Area-local policy to support |
|---|---|---|
| Density | Base intensity | Replace or Multiply (explicitly chosen) |
| Source subset | All eligible sources | Filter by UUID set |
| Source probabilities | Global weights | Local override table |
| Map | Global map | Replace, compose, or independent map |
| Map threshold | Global | Override |
| Random scale range | Global | Replace or range-modulate |
| Falloff | None/global | Local curve on area distance |
| Collision | Common solver | Optionally local radius multiplier |

**[TEST-NEEDED]** ForestPack's precise precedence and combination rules for all Area-local controls. Do not claim multiplication when only the existence of overrides is documented.

## 10. Falloff engine

A falloff is a reusable field driven by spatial distance, not a hardwired slider.

```cpp
float EvaluateFalloff(double signedDistance,
                      double range,
                      Curve1D response,
                      bool invert) {
    if (range <= 0.0) return BoundaryStep(signedDistance);
    float t = Clamp(DistanceOnInfluenceSide(signedDistance)/range,0,1);
    float v = response.Evaluate(t);
    return invert ? 1-v : v;
}
```

Define curve orientation carefully: the ForestPack editor labels distance in a direction that must be matched experimentally. Retain independent include/exclude ranges, density curve, scale curve, curve inversion, strength and height-only scaling.

### Examples

- Footpath exclude: acceptance fades to zero as distance approaches path boundary.
- Meadow edge: size curves from 0.45 to 1.0 without changing count.
- Worn grass: `Scale.z` reduced only, preserving XY width.
- Plant border: inverted density curve produces a band near exclude outline.
- Linked boundary: same spline, different local falloff curves for grass and shrubs.

### Multiple falloff overlap

`multiply`, `min`, `max`, `priority`, and `ordered contribution` yield different results. Define a deterministic default and optionally expose combiners. For parity, test overlapping areas. Every field should expose its influence support so dirty-region expansion is safe.

## 11. Boundary checking belongs near final transforms

Point boundary: test pivot. Size boundary: test approximate footprint. Element-based Edge: test renderable sub-elements, usually requires renderer/shader cooperation. Treat edge logic as a separate output capability, not a CPU Boolean clip. See `10_CONSTRAINTS_MANUAL_EDITS.md` and `19_RENDERER_ADAPTERS.md`.

## 12. Area acceptance tests

- Ordered Include–Exclude–Include matches expected contribution ordering.
- Swapping area order changes only expected contribution subsets.
- Overlapping Includes preserve duplicates under parity mode; optional dedup is explicit.
- Open curve corridor width, junction and cap behavior.
- Object raster mask catches a narrow obstacle within declared world error tolerance.
- Stacked floors share XY coordinates yet differ by receiver identity if randomize-stacked enabled.
- Local source subset restriction does not silently affect other areas.
- Paint add/erase region is consistent before/after serialized reload.
- Linked area updates dependent scatters while preserving local response curves.
- Incremental affected-tile update agrees with full rebuild, including collision propagation.

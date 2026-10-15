# 08 — Ordered areas, exclusions, overrides, and boundaries

**Status: proposed Cyrus implementation. Research basis: R0 §3. Official anchor: S01.**

## 1. An area list is a program

ForestPack documents bottom-to-top area evaluation and exclusions affecting earlier contributions [S01]. Reproduce the relationship explicitly rather than flattening every include into a union and subtracting every exclude.

In Cyrus, the saved list has a clear execution index. The UI may display the last operation at the top, but export and debugging show execution order numerically.

```text
1 Include Garden
2 Exclude Path
3 Include FlowerIsland
```

The path excludes eligible Garden candidates. FlowerIsland is a later contribution and can add candidates inside the path. Its identity includes its own area UUID, so an overlap is not accidentally deduplicated.

## 2. Compile contribution scopes

For each include operation, derive a contribution plan containing its generator, receiver constraints, local settings, and later applicable exclusions. A shared generator can provide addresses, but each include contribution gets separate provenance.

An exclusion can optionally target named contributions; default scope is all earlier contributions. Source-selective exclusion is a separately typed operation because it requires source selection before evaluation.

Provide an explicit `Union region` operation for artists who want overlapping shapes to define one population. Do not silently switch independent includes into union behavior as an optimization.

## 3. Area representation

```text
AreaOperation
    UUID / enabled / execution order
    type and operation
    definition reference
    projection domain / receiver restrictions
    local parameter overrides
    density and scale response
    boundary policy
    dependency revisions
```

Definition and use are separable. A shared path outline can be referenced by grass and shrubs with different falloff ranges. Shared geometry is not shared local response unless explicitly linked.

## 4. Spline regions

A closed planar curve becomes an interior region with a saved fill rule, default even-odd. Nested loops create holes. Self-intersections are either evaluated under that rule or rejected in strict polygon mode; do not let different triangulators decide silently.

An open spline creates a corridor. Define `Width` as the full width, with radius `Width/2`. This avoids ambiguous “thickness” semantics. Round caps and joins are the default; bevel/miter options have a miter limit. `Force open` applies corridor construction even to a closed loop.

Curves are flattened with a geometric tolerance before polygon queries. Cache the flattened curve under shape and tolerance revisions. Distance evaluation uses a segment index, not an O(segments) scan for every grass candidate.

Nonplanar spline projection is explicit: project into the area's saved frame or use a 3D curve-distance field. Those produce different regions.

## 5. Object exclusions

The supplied research and official reference describe projected object exclusions rather than universally exact 3D intersection [R0 §3.2; S01]. Cyrus offers separately named representations:

**Projected footprint:** clip source geometry against a saved height interval, project into a frame, rasterize or polygonize its footprint.

**Sphere/footprint proxy:** use a configurable simplified occupancy shape.

**3D clearance query:** test spatial separation against geometry; more expensive and not equivalent to a top-down footprint.

For `Top limit`, clip triangles crossing the limit plane rather than rejecting a triangle solely because one vertex is above it. Save whether the limit is absolute or relative to the object's bound origin. This is a Cyrus choice requiring a compatibility test for matching another product.

`Scale footprint` scales around a saved footprint origin. `Clearance` dilates by a distance. Scaling and dilation are not the same; expose both separately.

## 6. Raster accuracy contract

Specify a target world-space texel size and a maximum allocation budget. A fixed pixel count can be offered as an advanced option but must display its world-space effect.

The default hard exclusion uses conservative coverage: an occupied cell cannot produce a false-clear result without refinement. Near a boundary, refine against the authoritative projected contour. Avoid silently enlarging every exclusion by one texel if exact clearance matters.

A distance tile can store a conservative interval or a bounded approximation. Changing resolution is a quality/authoring decision recorded in the recipe; it is not a hidden viewport optimization for final eligibility.

## 7. Scatter-derived exclusions

A layer can export final accepted-instance footprints as a field. Choose trunk/root clearance independently of visual canopy bounds. A grass layer consuming tree occupancy should not inherit the tree's entire mesh radius accidentally.

Input identity includes the upstream final population revision, edited transforms, source footprint metadata, and the selected exclusion representation. A tree move invalidates both old and new regions.

Use directed links. `Trees -> Grass` is allowed. Adding `Grass -> Trees` creates a cycle and is rejected with a readable dependency path. A simultaneous multi-population solver is a separate advanced feature, not the default interpretation of mutual links.

## 8. Surface and paint areas

A surface area can be enabled as a coverage contribution independently of that surface's receiver role. Paint areas reference a Paint Set; deleting an area use need not delete a shared paint asset.

Projected paint uses an explicit receiver scope. Surface-attached paint uses receiver topology bindings. Both provide the same region/field query interface but have different persistence and conversion contracts; see chapter 09.

## 9. Local overrides

Use three states for each property: inherit, replace, and multiply where mathematically meaningful. Do not overload zero to mean inherit.

| Property | Default local combination |
|---|---|
| Source subset | Replace eligible set when enabled |
| Source weights | Optional multiplier within eligible set |
| Generator choice | Replace contribution generator |
| Distribution map | Replace field reference |
| Map transform | Replace local field transform |
| Density | Multiply global density |
| Random scale range | Replace global random range |
| Fixed scale multiplier | Multiply source/global scale |
| Boundary mode | Replace layer boundary policy |
| Falloff curves | Local response, not inherited from linked shape by default |

The inspector displays resolved values. A setting edited in a disabled override retains its authored value but has no effect until enabled.

## 10. Three boundary questions

**Point policy:** does the selected test point lie in the permitted region?

**Footprint policy:** does the transformed source footprint fit within the permitted region?

**Element policy:** which source elements should contribute to rendering?

They require different data and costs. Use labels that describe the test, not simply “better quality.”

### Point timing

Offer `At resolved sample` and `At final placement`. The latter runs after random translation, placement Effects, and constrained manual edits. Default CyrusV1 uses final placement for strict boundaries. A compatibility profile can intentionally allow post-placement leakage.

### Footprint fitting

For a circular footprint, minimum boundary clearance can be compared with radius, provided the distance query and area geometry satisfy that model. For a general convex footprint, a center-distance test is insufficient. Use polygon containment and boundary intersection, including holes and narrow excluded islands. Checking vertices alone can miss an exclusion completely enclosed inside a large footprint.

Nonuniform scaling and shear transform the footprint. A conservative bounding sphere is allowed as a separately named fast approximation; it can reject placements that an exact footprint would accept.

### Element boundaries

Element selection is not triangle clipping. A source preprocessing step identifies connected elements according to the chosen material/connectivity rule and a representative point. The renderer uses per-instance boundary information to suppress selected elements. Exact material integration is addressed in chapter 15; unsupported renderers must not advertise equivalent behavior.

## 11. Boundary conflict policy

An applicable exclusion wins over an earlier include at shared boundary points. A later include can create a new contribution. Pinned manual items can bypass coverage by explicit policy, but the UI shows that override.

Sources with zero footprint can still use point tests. Sources with missing footprint metadata use a diagnostic fallback or fail strict fitting according to saved policy. Never assume mesh bounds exist for an opaque renderer procedural.

## 12. Conversions

Spline-to-paint samples a region into the selected paint representation with a recorded error/resolution. Paint-to-spline extracts a contour at an explicit threshold, preserves holes, and simplifies only within a specified tolerance.

Round-trip conversion is not guaranteed lossless. Report changed area, boundary deviation estimate, and discarded tiny components where applicable. Converting surface-attached paint to planar splines requires an explicit projection and can collapse stacked regions.

## 13. Update rules

Reordering operations recompiles affected contribution scopes. Moving a spline updates its old/new support plus falloff/footprint influence. Changing a global source radius can affect footprint boundaries and collisions even when area geometry is unchanged. A linked definition edit invalidates all uses; changing one use's local falloff does not alter its siblings.

## 14. Required tests

Three-operation include/exclude/include, overlapping independent includes, union includes, spline holes, self-intersection, a narrow wall footprint, a balcony overhang with Top Limit, a large footprint enclosing a small excluded island, a moved tree affecting grass, and a pinned item outside coverage. Compare both membership and contribution provenance, not only visible counts.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S01]: https://docs.itoosoft.com/forestpack/forest-plugin/areas

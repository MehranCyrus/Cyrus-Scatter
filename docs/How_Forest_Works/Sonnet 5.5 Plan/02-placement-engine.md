# Cyrus Scatter — Rebuild Blueprint

## 02 · The Placement Engine

This file covers *where things go*: sources, distribution providers, surfaces, areas, paint, falloffs, boundaries and collisions. Tags: **[Doc]** verified in iToo docs, **[Doc\*]** from your research notes (unverified), **[Inf]** inference, **[Prop]** my design, **[Test]** needs an experiment.

---

## A. Sources (the Geometry list)

### A.1 What a source list really is

A list of things that may appear, each with a **relative weight**, plus data that affects placement (not just looks): collision radius, size, Color ID, Z offset, material override, and grouping behavior.

**Weighted selection.** Probability is `w_k / Σw`; weights do not need to sum to 100. Selection probability is **not** the final visible proportion, because collisions, boundaries and other rules reject some picks. Statistics must report both *selected* and *accepted* counts per source.

```cpp
SourceId PickWeighted(const SourceRegistry& r, float u) {   // u = Random01(seed,id,ChSource)
  float t = u * r.cumulativeWeight.back();
  auto it = std::upper_bound(r.cumulativeWeight.begin(), r.cumulativeWeight.end(), t);
  return SourceId(it - r.cumulativeWeight.begin());
}
```

### A.2 The empty slot — two different operations

In the reference, a disabled source keeps its probability share and produces nothing; this is used for gaps (missing fence planks, empty positions in color-ID maps) **[Doc]**. Cyrus must expose both operations explicitly **[Prop]**:

| Operation | Meaning |
|---|---|
| **Remove from selection** | Its weight is redistributed among remaining sources |
| **Keep as empty choice** | Weight is kept; candidates that pick it emit nothing (`Reason::EmptySourceSlot`) |

Do not hide this behind one "Disable" checkbox.

### A.3 Source kinds and grouping

| Kind | Notes |
|---|---|
| Mesh | Plain geometry |
| Proxy | Renderer proxy; viewport uses a stand-in, render uses the proxy |
| Group | Several objects arranged together (e.g. a flower clump) |
| LOD set | Alternative representations of one source (file 04 §7) |
| Template | Built-in simple stand-ins (planes, boxes) — low priority, Tier C |
| None | The empty slot above |

**Groups need an explicit contract.** The reference's *Keep Group Hierarchy* decides whether members share transforms and culling or are treated separately **[Doc\*]**. Cyrus: two distinct types **[Prop]**:

- **Compound source (atomic):** one parent transform × each child's local transform. One placement, one collision footprint, one LOD decision. Default.
- **Selection pool (expanded):** children are independent candidates each choosing their own transform. Higher cost; build later.

"A collection of source objects" and "one compound source" must never be the same data type.

### A.4 Source dimensions affect more than looks

Size feeds: boundary Size mode, translation expressed as a **percentage of width (X/Y) and height (Z)** **[Doc]**, collision footprint, point-cloud/box previews, and group handling. Replacing a 30 cm shrub with a 4 m tree keeps candidate ids but forces boundary and collision re-evaluation (the dependency table in file 01 §6.3 already encodes this).

### A.5 Per-area source subsets

An area may restrict itself to a subset of the source list (*Select Models*) **[Doc]**. Store as a bitmask on the area; the diversity stage consults the **generating area's** mask. Weights are renormalized within the subset.

---

## B. Distribution providers

All providers implement one interface and produce candidates with stable ids.

```cpp
class IDistributionProvider {
public:
  virtual ProviderKind Kind() const = 0;
  virtual void Generate(const DistributionContext&, const Bounds3& tileBounds, CandidateBuffer& out) const = 0;
  virtual uint64_t Revision() const = 0;
};
```

Providers generate in a **local frame** (`posLocal`); the surface-resolve stage converts to world positions.

### B.1 Image provider (the main generator)

**Reference model [Doc].** A distribution image is scaled to a size in scene units and **tiled in all directions**. Each pixel is a potential position: white places an item, black leaves a gap. The perimeter of the forest is always defined by an area (spline/surface); the map only decides arrangement inside it. Any Max map can serve as the image if it can be generated before render time.

**Parameters and what they mean:**

| Parameter | Meaning | Notes |
|---|---|---|
| Bitmap / Map | The pattern | Procedural/animated maps are **baked** to a raster on the main thread (file 01 §8) |
| X/Y Units | World size of one tile | Halving both quadruples candidate density **[Inf]** |
| X/Y Pixels | Resolution of a *procedural* map independent of X/Y Units | Locked to bitmap pixel counts for bitmaps **[Doc]** |
| Map Channel | Take scale from the surface UVs instead of X/Y Units | Requires an assigned surface **[Doc]** |
| Fit to Scene | Fit the map to two picked corners (adjusts offset and size) | For aerial-photo maps with one white pixel per tree |
| Lock Aspect | Ignore Y size, derive from X | |
| Offset / Rotation | Shift/rotate the pattern | |
| Threshold | Convert grayscale/color pixels to on/off | |
| Use as Density Map | Treat gray as density, not mask | Introduced in 9.3 **[Doc]** |
| Max Density | Limit on possible positions (default 10 M), counting black pixels too | |

**Enumeration algorithm.**

```
cellSize = (unitsX / pixelsX, unitsY / pixelsY)         # world size of one pixel
for each include area A (or each tile ∩ area bounds):
    ix0..ix1, iy0..iy1 = integer cell range covering bounds ∩ tile (+ halo)
    guard: (ix1-ix0+1)*(iy1-iy0+1) <= maxDensity, else clamp + warn
    for ix, iy in range (parallel over rows):
        px = mod(ix, pixelsX), py = mod(iy, pixelsY)    # tiling = modulo
        v  = map[px,py]                                  # 0..1
        id = HashCell(scatterGuid, Image, ix, iy, receiver=0)   # receiver/hit added at surface stage
        if (!useDensityMap):  keep iff v > threshold
        else:                 keep iff Random01(seed,id,ChNoise) < v     # reused u → slider-stable
        posLocal = origin + (ix + 0.5 + jitterX, iy + 0.5 + jitterY) * cellSize   # jitter: [Test]
        emit candidate
```

Why the density-map form matters: reusing the same `u_i = Random01(seed,id,…)` means dragging a density slider **adds or removes** items instead of reshuffling the population **[Prop]**.

**[Test]** whether the reference centers items on pixels or jitters inside them; start with no jitter and a `cellJitter` parameter defaulting to 0.

**Efficiency warning from the reference [Doc]:** a sparse map at a tiny X/Y Units wastes time evaluating empty pixels; increase map density first, then lower X/Y. Mirror this in the stats window ("62% of positions were empty").

**Better generation [Prop].** For dense grass, generate a **blue-noise / Poisson-disk** candidate set at the target minimum distance instead of a dense grid followed by rejection. Keep the image provider for parity; offer "Min-distance" as an optional provider for efficiency.

### B.2 Diversity — which source goes at each position

Three strategies **[Doc]**:

**1. Random.** Weighted pick (A.1) using the source weights.

**2. Match Color ID.** The map's pixel color is matched to the **closest** source Color ID; source weights are **ignored**; a "Noise" amount adds random exceptions; gaps come from a *Disabled* source assigned to a color.
```cpp
SourceId MatchColor(Rgb pixel, const SourceRegistry& r) {
  // nearest in a perceptual space (Lab/Oklab) — cheaper than it sounds with ≤ 32 sources
  float best = 1e30f; SourceId bi = 0;
  for (auto& s : r.entries) { float d = DeltaE(pixel, s.colorId); if (d < best) { best = d; bi = s.id; } }
  return bi;
}
```
Recommend high-contrast key colors (red, green, blue, yellow) in docs **[Doc]**.

**3. Clusters.** Groups items of the same type like nature does. Controls **[Doc]**: **Size** (scene units), **Roughness** (0 smooth – 100% rough), **Blurry Edge** (0 sharp – 100% blurred), **Noise** (0–100% random items). Needs more than one source or it has no effect.

*Proposed algorithm* ([Prop]; the real one is private, so tune visually against the reference):

```
species field S(x,y):
   1. Worley/Voronoi cells with feature points jittered at scale = Size.
   2. Each cell hashes to a species using weighted pick (weights = source weights [Test]).
   3. Roughness: warp the lookup coordinate with fBm noise, amplitude = roughness * Size.
   4. Blurry Edge: use the two nearest cells; blend weights w = smoothstep(−blur*Size, +blur*Size, d2−d1);
      choose species A with probability (1−w), species B with probability w, using u = Random01(...,ChCluster).
   5. Noise: with probability noise, ignore the field and pick randomly (weighted).
```
Important: **cluster Size must not secretly change density.** Size only changes the scale of the species patches. Provide a unit test that candidate counts are identical when only Size changes.

A texture can supply density, species and transform data, but each use must be a distinct, named binding: *density field* ("should something exist here?"), *species field* ("which source?"), *transform field* ("how is it transformed?"). A red region used for species must not silently mean high density.

### B.3 Path provider

**Reference [Doc\*]:** regular spacing along splines, placement at vertices, source sequencing, positional variation, perpendicular offset, and orientation following the path.

**Algorithm.** Spacing must be by **arc length**, not by curve parameter.

```
for each spline, each sub-spline:
   polyline = adaptive flatten(bezier, tolerance)            # store cumulative length table
   L = total length
   for k = 0 .. floor(L / spacing):
        s = k * spacing (+ startOffset)
        (p, tangent) = EvaluateAtLength(table, s)            # binary search + lerp
        lateral = normalize(cross(up, tangent))
        p += lateral * splineOffset
        p += random along-path jitter  (keyed by id)
        id = Hash(scatterGuid, Path, splineGuid, subIndex, k)
        source = Sequence ? entries[k % N] : weighted/random
        orientation = FollowPath ? basis(tangent, up) : identity
```
Define explicitly: **which curve supplies the spacing measure when an offset is applied?** (An offset curve has different arc length.) Default: the original spline; **[Test]** the reference. Also specify closed-spline seams, endpoints, sharp corners and multiple splines.

*Use Path for repeated lamps/fence posts; use an open-spline **area** + Image provider for irregular rocks along a path.*

### B.4 Reference provider

**Reference [Doc\*]:** places an item at each reference object's pivot, or on mesh faces (with items per face), optionally randomized within faces; inherits orientation/scale; matches source by name or regex; keeps a dynamic link so moving a marker moves its item.

- **Id:** from marker identity (+ face index + item index). Moving a marker must **move its tree, not respawn it with a new random look** (hence ids never use position here).
- **Random point in a triangle** (do not use two raw uniform barycentrics):
```cpp
float3 RandomInTriangle(float r1, float r2) {           // uniform
  float s = std::sqrt(r1);
  return { 1.0f - s,  s * (1.0f - r2),  s * r2 };       // barycentric (a,b,c)
}
```
- Face-index ids break on topology edits; store a quantized face centroid as a fallback key.
- Name/regex matching selects the source: `source = FindByName(entries, marker.name)`; unmatched markers follow the configured fallback.

### B.5 Particle provider

Consume particle position/rotation/scale, filtered by selected events, with a live animated link **[Doc\*]**. Keep this a **provider** (input). Using particles as a render *transport* in another plugin is a different, unrelated adapter. Id = particle birth id.

### B.6 Imported markers (RailClone-style segments)

The reference added an integration where exported segments become placement inputs, with tag-based geometry matching, and leaves deformation behind **[Doc\*]**. For Cyrus: define a neutral **marker file/interface** (`position, rotation, scale, wireColor, tag, id`) consumed through the Reference provider. Do not reduce imported inputs to anonymous XYZ — keep tags and identifiers.

### B.7 Manual provider

Hand-placed items from the item editor are another provider with `uniqueId`s (file 03 §3). They flow through the same later stages, except they skip area rejection by policy.

---

## C. Surfaces

### C.1 Reference behavior [Doc]

- A list of receiving meshes (**simple meshes, not groups**); trees are placed along the Forest object's local Z.
- **XY mode:** scatter in the object's local XY plane, then drop each item along Z onto the surface. Best for smooth terrain, and the default with no surface assigned (splines act as boundaries).
- **UV mode:** use mapping coordinates as the alignment guide for the distribution map. Better for rough terrain or convex objects (spheres). UVs must be well-defined.
- Terrain edits are **not** applied automatically; an internal table is built for speed, shared by all Forest objects using that surface; an *Auto* option updates automatically at a performance cost.
- *Get From Forest* reuses another object's surface list.
- **Direction:** −100 (down) … 0 (normal-aligned) … +100 (up).
- **Scale to Fit sloped areas** (XY): scales item **width** proportionally to slope; forces Direction 0; unavailable in UV mode.
- **Altitude range** (limited top/bottom + density/scale falloff curves by altitude) and **Slope range** (0° horizontal … 90° vertical).
- **Material ID** filter: only faces with listed IDs (requires XY mode).

### C.2 Shared surface cache [Prop]

```
SurfaceCache (owned by the scene, not by one scatter)
   key: (node handle, mesh revision, transform revision)
   value: world-space BVH over triangles  +  per-triangle UV/MatID/normal tables
   optional: 2D uniform grid in a given projection Frame (built on demand per frame orientation)
```
- Many scatters on the same terrain share one entry (matches the reference's shared table **[Doc]**).
- **Invalidation granularity:** topology change → full rebuild; vertex deformation → refit BVH; transform change → update matrix only; UV or MatID edit → patch tables only. Do not force full rebuilds for everything.
- Expose a user control: *Auto-update surfaces* (default **on** in Cyrus, since revision tracking is cheap) versus manual.

### C.3 XY projection

```
for each candidate with local XY (x,y):
    ray origin = frame * (x, y, +big), direction = frame * (0,0,-1)
    hits = bvh.AllHitsAlongRay(...)          # multi-hit for bridges, floors, overhangs
    for each hit h (per receiver surface list order):
        emit candidate with receiver, triangle, barycentric, normal, uv, materialId, hitIndex
```
Fast path for terrain-like height fields: a 2D grid in the frame's XY holding triangle lists; point-in-triangle in XY then barycentric Z.

**Density caveat [Doc/Inf].** Equal density in the projection plane means **fewer items per surface area on steep slopes**: `ρ_surface = ρ_projected · |n·z|` (60° → half). The reference does *not* compensate by default; its *Scale to Fit* instead widens/narrows items. Cyrus default = same; offer optional **world-area density compensation** ([Prop]) as an explicit mode.

**Stacked surfaces.** Items at identical XY on different surfaces would share random values under XY seeding (the reference's *Randomize Stacked* problem **[Doc]**). Cyrus ids include `receiverId` and `hitIndex`, so this problem does not exist by default.

### C.4 UV mode

```
build once per (mesh, channel, revision): UV spatial grid over [0,1]^2 (tile-aware) → triangle lists
for each candidate in UV space (u,v):
    triangles containing (u,v)  →  all hits (overlapping UV islands produce multiple hits)
    barycentric inverse → world position, normal
```
Problems you must handle: seams, mirrored islands, overlapping UVs, stretched islands.

Three honest promises the UI must distinguish **[Prop]**:
1. Uniform in **projection** space.
2. Uniform in **UV** space.
3. Uniform per **actual surface area** (compensated).

Optional compensation: let `s_i = uvArea_i / worldArea_i` for the triangle; world density is `ρ_uv · s_i`. To equalize, thin by `p_i = clamp(s_ref / s_i, 0, 1)` with `s_ref` a chosen percentile; warn if the map is too sparse for the densest region.

### C.5 Orientation, slope, altitude

```cpp
float SlopeDeg(float3 n, float3 up) { return degrees(acos(clamp(dot(n, up), -1.f, 1.f))); }
// 'up' = Forest object local Z, world Z, or user axis -> [Test] which the reference uses; make it a parameter.
float3 OrientAxis(float3 normal, float direction /*-100..100*/, float3 up) {
  float t = direction / 100.0f;
  return normalize(t >= 0 ? lerp(normal,  up, t) : lerp(normal, -up, -t));   // [Inf]; verify by test
}
// Scale to Fit (width): widthScale = 1 / max(cos(slope), eps)  [Test the exact formula]
```
Altitude: `a = (pos.z − bottom)/(top − bottom)`, then apply density/scale curves; limit flag cuts outside range.

The surface query must return one structure supporting placement, texture sampling, slope filtering, alignment, paint attachment and later re-binding: **position, normal, receiver, triangle, barycentric, UV, material ID** (`SurfaceSample`, file 01 §2).

---

## D. Areas

### D.1 Reference semantics [Doc]

Five types: **Spline, Object, Forest, Paint, Surface** (+ *Linked* areas). Each is **Include** (additive; creates items in the region) or **Exclude** (subtractive). Areas are processed **bottom to top**; an exclude only affects items from areas **below** it in the list; excludes must be above an include to work. Avoid overlapping includes (coplanar duplicates). A surface left active alongside other includes fills the whole terrain — the classic "I painted a small region, why is everything filled?" bug.

### D.2 Evaluation algorithm [Prop]

Do **not** flatten to one mask; evaluate an ordered list of operations on populations:

```
order(e) = position from bottom (0) to top
population P = ∅
for area in areas sorted by order ascending (bottom → top):
    if area.kind == Include:
        for candidate c produced by providers whose posLocal ∈ area.region:
            c.areaOrder = area.order
            c.distInclude = area.DistanceToBoundaryInside(c)
            P.insert(c)                                  # dedupe by cell id; keep topmost owner [Test]
    if area.kind == Exclude:
        for c in P where c.areaOrder < area.order and area.Contains(c):
            reject(c, ExcludedByArea)
        for c in P where c.areaOrder < area.order:
            c.distExclude = min(c.distExclude, area.DistanceOutside(c))
```
Provenance (`areaOrder`) is also what lets per-area overrides (source subset, scale, local distribution map) apply to the right items.

### D.3 Region types

| Type | Region constructor | Notes |
|---|---|---|
| Spline (closed) | 2D polygon | Inside test + boundary distance. Multiple sub-splines optionally treated as separate areas (*Separate Sub-Splines*) **[Doc]** |
| Spline (open) | Polyline + **Thickness** | Corridor either side. *Force Open Splines* makes a closed spline behave as a band around its outline **[Doc]** |
| Object | Projected raster mask of geometry | Projected along world Z; resolution default 512; **Top Limit** ignores geometry above a height; **Scale** grows/shrinks the exclusion (<100% lets items get closer, >100% pushes away) **[Doc]**. Exclude only |
| Forest | Another scatter's items as exclusion | **Sphere** (fast bounding spheres, radius from area Scale or per-item Collision Radius) or **Mesh** (exact, slower); resolution default 512 **[Doc]** |
| Paint | Artist-painted coverage | Requires an XY surface (kept switched off to restrict scatter to paint) **[Doc]** |
| Surface | Whole receiving surface | Also an include area; toggled in the Areas list **[Doc]** |
| Linked | Area borrowed from another scatter | Type-specific data inherited; common data (falloff) stays local; some combinations unsupported, e.g. a linked Object area works only as Exclude **[Doc]** |

**Separate concerns in the UI [Prop]:** *receiving geometry* (Surface) versus *coverage sources* (areas). Keep the "full terrain filled" trap obvious (a warning when a Surface include is active alongside other includes).

### D.4 Object and Forest exclusion rasters

The reference rasterizes to a 512-px black/white bitmap along world Z **[Doc]**. Consequences and improvements **[Prop]**:

- Pixel size = `extent / resolution`: a 100 m footprint at 512 px is ≈ 19.5 cm. One fixed resolution cannot be right for every scene scale.
- Cyrus: expose **target world-space error** (e.g. 5 cm) and compute the resolution; use **tiled rasters** for large objects; compute a **distance transform** (exact Euclidean, two-pass) so the same raster feeds both the hard exclusion and the exclude falloff.
- *Top Limit* means: ignore triangles whose **minimum** Z is above the limit, or clamp geometry at the limit **[Test]** which. Overhangs make whole-silhouette exclusion different from ground contact.

### D.5 Falloffs (one distance, many effects)

**Reference [Doc].** Independent **Density** and **Scale** falloffs; **Include Range** is measured from an include area's boundary; **Exclude Range** from an exclude area's boundary; editable curves (separate per effect), default linear; **Invert Curve** (used to scatter *around* the perimeter of an exclude); **Falloff Affect** scales strength (0 disables); **Affect Height Only** limits scale falloff to Z.

```
t(p)   = clamp(d(p) / R, 0, 1)                  # d = distance to relevant boundary, R = range
F(p)   = curve(t(p))                             # artist curve, may rise/fall/rise
Dens(p)= lerp(1, F_D(p), affect)                 # density multiplier   [Inf]
Scale(p)= lerp(1, F_S(p), affect)                # scale multiplier     [Inf]
accept candidate iff Random01(seed,id,ChNoise2) < Dens(p)      # stable thinning
```
- **Curve orientation (which end is the boundary) and Invert Curve semantics (1−f vs mirrored x)** are **[Test]**.
- Density falloff changes *how many*; scale falloff changes *what remains*; Height-Only changes vertical extent without narrowing footprints. Test them independently and together.
- **Overlap policy** when several influences apply: multiply densities, multiply scales, **[Test]** the reference; make the policy explicit in code.
- Build **one** scalar-field/distance service and reuse it for density, scale, source weights, tint, effects. Never hard-code linear falloff; the curve must support non-monotonic shapes from day one.

**Distance sources:** polyline distance via spatial index (min over segments), paint/raster via EDT, forest-sphere via nearest-center distance minus radius.

### D.6 Per-area overrides — precedence

Per-area controls **[Doc]**: model subset, **Random Scale by Area** (applied **in addition to** Transform-rollout randomization), override distribution map (own scale, threshold, map; not supported in UV mode), material IDs, falloff settings.

Precedence must be explicit **[Prop]**. Default: model subset **replaces**; scales **multiply** (consistent with "in addition to" **[Doc]**; exact math **[Test]**); map override **replaces** the global map. Example: global scale 1.2 × area 0.8 = 0.96 (multiply) vs 0.8 (replace); document which one each control uses.

---

## E. Paint areas

### E.1 Reference behavior [Doc]

Paint/erase with mouse or tablet (min/max brush size, optional pressure sensitivity), falloff preview, convert **paint → spline** and **spline → paint**, Ctrl switches to erase and Alt to paint while painting. Paint needs an **XY surface**. Changing the **projection axis** of a non-empty paint area can give unexpected results (so paint is stored relative to the projection) **[Doc]**. Your notes mention conflicting shortcut descriptions across pages — verify in the target build **[Doc\*]**.

### E.2 Three representations [Prop]

| Layer | Purpose | Contents |
|---|---|---|
| **Authoring** | Editable intent; undo | Ordered strokes: samples `{pos (projection space), radius, strength, pressure, op}`, receiver binding, projection axis |
| **Evaluation** | Fast queries | Tiled coverage raster (8–16-bit) at a world-space resolution + distance field per tile |
| **Display** | What the artist sees | Brush overlay, falloff preview; independent of plants so a rejected plant isn't mistaken for missing paint |

Design questions to settle *before* optimizing: can an old stroke's width change; does paint follow a deforming receiver (optional **surface-attached** mode via barycentric binding = improvement); can it survive topology edits; does *erase* remove authored coverage or merely hide plants (it must remove coverage).

### E.3 Stroke pipeline

```
Begin    (hit, pressure, radius, receiver)       main thread (viewport callback)
Update   (...)                                   interpolate samples at ≤ 0.25 × radius spacing
         → stamp into affected tiles (SDF-style disc, feathered by falloff)
         → mark dirty tiles = brush footprint + falloff range + collision halo
         → enqueue incremental regeneration for those tiles (cancel superseded jobs)
End      commit stroke to authoring list (one undo step)
```
- The brush cursor and paint overlay must update **immediately**, independent of how long plant regeneration takes.
- **History cost:** never re-evaluate all strokes per query. Strokes are only for undo/redo and conversion; the tile raster is authoritative for evaluation and is periodically checkpointed (bake old strokes into base tiles, keep recent N as undo window).
- The 3ds Max SDK exposes painter callbacks (start/update/finish/cancel with hit position, normal, barycentric coordinates, face index, radius, strength, pressure, modifier keys) via `IPainterCanvasInterface_V5` **[Doc\*]**; confirm in your SDK version.

### E.4 Conversion

- **Paint → spline:** threshold coverage at 0.5 → marching squares → Douglas-Peucker simplification (tolerance tied to brush radius) → holes become separate sub-splines.
- **Spline → paint:** scanline-rasterize polygons into tiles with the area's falloff range as feather.

---

## F. Boundary checking

Three modes **[Doc]**, applied per area:

| Mode | Test | Result |
|---|---|---|
| **Point** | Item pivot only | Entire item removed if outside; may produce overlaps across the border |
| **Size** | Item width + collision radius | Entire item removed; no overlaps, but uneven edges for large items |
| **Edge** | Lowest-Z vertex of each **element** (connected faces sharing a material ID, the same elements Forest Color uses) | Only that element is removed → clean edge without slicing geometry. Evaluated **at render time**, not previewed in viewports by default (Ctrl-click to preview) |

Edge support is renderer-dependent: V-Ray handles it natively (including proxies in Full Mesh preview, V-Ray 6+), while Arnold and Corona use a *Forest Edge* map in the material's Opacity/Cutout slot **[Doc]**. Edge needs a spline or paint area (not a bare surface) and, in UV mode, specific projection handling **[Doc]**.

**Cyrus plan [Prop]:**
- Core computes, per instance, a **boundary mask** (bit per element: inside/outside) by evaluating area coverage at each element's lowest vertex in world space; stored as an optional attribute stream.
- The render backend publishes the mask to the material system (native hook or opacity-map node). Renderers without support fall back to Size.
- The element table (elements, lowest-vertex local offset) is cached **per source**.
- It cannot be reproduced with a CPU "trim" flag alone — it needs renderer/material integration (file 04 §5).

**Order of operations.** Because random translation happens after placement **[Doc]**, items can leave the area. Offer: *Check before translation* (parity default) and *Check after translation* (strict) as an explicit option.

---

## G. Occupancy and collisions

### G.1 Reference behavior [Doc]

Scatter first, then **delete** items that collide with neighbors. Test = intersection of virtual bounding spheres. Sphere size = **item Radius × global Radius**, both percentages of tree size (1–100%). **Height** sets the sphere center Z (0% = ground; raise for tall crowns). Raising density mostly produces extra rejected candidates; stats warn above 50% discarded. Later versions extended collisions to Path, Reference and Particle modes **[Doc\*]**.

### G.2 Cyrus algorithm [Prop]

```
sort/iterate candidates by priority(id) ascending           # deterministic winner rule
spatial hash grid, cell size = 2 * rMax
for c in order:
    r_c = effectiveRadius(c)                                # source radius × global × scale?  [Test whether scale applies]
    for n in grid.neighborhood(c.center):
        if n.accepted and dist2(c.center,n.center) < (r_c + r_n)^2:   # cached sqrt-free test
            c.reject(CollisionLost); goto next
    c.accept(); grid.insert(c)
```
Questions every implementation must answer explicitly: Which candidate wins? Does scale change radius? Can species overlap other species? Is clearance measured at trunk, canopy or whole asset (use the Height parameter plus per-source radius)? Does processing order change the result? (Here: no, by construction.)

**Cross-population exclusion.** "Grass avoids trees" is a **directed** relationship: `Trees → exclusion field → Grass`, not a symmetric joint solve. Mutual dependency is refused (file 01 §6.4) unless a deliberate solver exists. Trunk-zone vs crown-zone footprints should be separate controls so ground cover can thin near trunks without vanishing under the whole canopy.

**Complexity.** The grid keeps the average cost near linear; naive pairwise testing is O(N²). Performance also depends on radius variation and local density.

**Better than reject-after.** Offer Poisson-disk / dart-throwing generation to avoid wasted candidates; keep the parity path for matching legacy scenes.

---

## H. Putting it together: ordering checklist

For every new feature, answer these before coding:

1. Which stage does it belong to and which attributes does it read/write?
2. What is its combination rule with existing controls (replace, multiply, add, filter, ordered)?
3. What identity behavior does it have when inputs change?
4. Which changes invalidate it?
5. How does it persist and undo?
6. How does it differ between viewport and render?
7. What are its documented limits and unsupported combinations?
8. What is the evidence level — **[Doc]**, **[Inf]**, **[Prop]** or **[Test]**?

Continue with `03-transforms-editing-effects.md`.

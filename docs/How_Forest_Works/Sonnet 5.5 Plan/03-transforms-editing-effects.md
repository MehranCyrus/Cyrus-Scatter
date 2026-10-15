# Cyrus Scatter — Rebuild Blueprint

## 03 · Transforms, Editing, Effects, Materials and Animation

Tags: **[Doc]** verified in iToo docs, **[Doc\*]** from your research notes (unverified), **[Inf]** inference, **[Prop]** my design, **[Test]** needs an experiment.

---

## 1. Transform system

### 1.1 What the reference does [Doc]

| Control | Behavior |
|---|---|
| **Translation** | Random offset, expressed as a **percentage of item width (X/Y) and height (Z)**. Applied **after** the item is placed at its distribution position, so large values can push items outside the area spline |
| **Rotation** | Random rotation per axis between Min and Max (0–359°). **Ignored when "facing camera" is enabled** in the Camera rollout |
| **Scale** | Random scale with independent XYZ ranges, optional locked aspect |
| **Probability Curves** | Curve over the Min–Max range: X axis = value range, Y axis = 0–100% probability. Can concentrate rotation on discrete angles (0°, 90°, 270°) or make large scales rare |
| **Maps** | Grayscale: white = Max, black = Min. With *Color map*: R/G/B drive X/Y/Z scale. Three grayscale maps can be merged with a Composite texture |
| **Probability Map** | Black = no randomization, white = full-range randomization |
| **Mirroring** | Flip horizontally; by default only for template sources, enable *Use on Custom Objects* for others |

### 1.2 Value versus probability — three different things

Keep these as separate concepts in code and UI **[Prop]**:

| Concept | Question it answers | Implementation |
|---|---|---|
| **Range** | What values are allowed? | `[min, max]` |
| **Probability distribution** | How likely is each value? | Curve → CDF → inverse sampling |
| **Spatial map** | Where does a value apply? | Field sampled at the instance position |

A range alone says nothing about whether most objects are small or large.

### 1.3 Sampling a probability curve correctly

Evaluating the curve at a uniform random x is **not** the same as treating it as a probability density. Do this instead **[Prop]**:

```cpp
struct CurveSampler {
  std::vector<float> cdf;       // N+1 samples, cdf[0]=0, cdf[N]=1  (built once per curve revision)
  float min, max;
  explicit CurveSampler(const Curve& pdfCurve, float mn, float mx, int N = 1024) {
    min = mn; max = mx; cdf.resize(N + 1); double acc = 0; cdf[0] = 0;
    for (int i = 0; i < N; ++i) {
      double p = std::max(0.0, double(pdfCurve.Eval((i + 0.5f) / N)));   // height = relative likelihood
      acc += p; cdf[i + 1] = float(acc);
    }
    if (acc <= 0) { for (int i = 0; i <= N; ++i) cdf[i] = float(i) / N; }   // flat fallback
    else for (auto& v : cdf) v /= float(acc);
  }
  float Sample(float u) const {                       // u = Random01(seed,id,channel)
    auto it = std::upper_bound(cdf.begin(), cdf.end(), u);
    size_t i = std::clamp<size_t>(size_t(it - cdf.begin()), 1, cdf.size() - 1);
    float t = (u - cdf[i-1]) / std::max(1e-12f, cdf[i] - cdf[i-1]);
    return min + (max - min) * ((float(i-1) + t) / float(cdf.size() - 1));
  }
};
```
The reference describes curve height as relative likelihood across the configured range **[Doc]**; this is the mathematically consistent way to honor it. Cache one sampler per curve revision. A curve with narrow spikes (discrete angles) needs the high sample count above.

### 1.4 Transform evaluation order (an explicit contract)

```
1. choose source                       (weights / color ID / clusters)
2. place at candidate position (+ surface orientation: Direction, Scale-to-Fit)
3. area scale/density falloff multipliers
4. random scale  (curve sampler × maps × area "random scale by area")
5. random rotation (curve × map)           [skipped if facing camera]
6. mirror
7. [Boundary check — "before translation" parity mode]
8. random translation  (% of scaled width/height)
9. [Boundary check — "after translation" strict mode]
10. effects (geometry-affecting) → boundary + occupancy
```
Why order matters: choosing scale *before* computing the collision footprint differs from computing the footprint and scaling afterward; translating before or after the boundary test changes which items survive **[Doc]** (translation is applied after placement). Encode the order once, document it, and test combinations.

Final transform composition, with `⊙` = component-wise multiplication **[Prop]**:

```
S_final = S_source ⊙ S_global_random ⊙ S_area ⊙ S_falloff ⊙ S_map
```
Multiplication is the default combine rule (consistent with "in addition to" for area scale **[Doc]**), but make the rule configurable per control, because the reference's exact internal blend is **[Test]**.

### 1.5 Maps

```cpp
// grayscale → value
float v = lerp(min, max, map.SampleGray(uv_or_xy));
// color map for scale
float3 s = lerp(minV, maxV, map.SampleRGB(uv_or_xy));        // R→X, G→Y, B→Z
// probability map: modulates how much randomness applies
float amount = probMap.SampleGray(...);                       // 0 = none, 1 = full range
float value  = lerp(neutral, randomValueInFullRange, amount); // neutral = range midpoint or min  [Test]
```
A **value map** says *set the rotation from this texture*. A **probability map** says *allow more random rotation in the bright areas*. Name and preview them differently.

All map sampling goes through `IScalarField` (file 01 §2), so painted masks, slope, altitude, distance-to-spline and noise can drive transforms without new code.

### 1.6 Randomness for transforms

Use the keyed streams from file 01 §4 (one channel per property). Changing the rotation range never alters scale values. A single global **Seed** is a deliberate "give me a different variation" control, not an accidental coupling.

---

## 2. Materials and color variation

### 2.1 Reference [Doc\*, partly Doc]

- Material rollout: tint (from gradient or map), tint-strength randomization, hue/saturation/brightness correction. These require **compatible Forest Color / Forest Material integration**; a **Material Optimizer** can insert the required map structure; 9.4.3 fixed it duplicating Forest Color already in a map chain **[Doc]**.
- Forest Color supports variation per **whole item** or per **element** (connected faces sharing a material ID, *not* each face), alternative maps, tinting and blending **[Doc\*]**.

### 2.2 What it means for Cyrus

Per-instance appearance is **attribute streams**, not duplicated materials **[Prop]**:

```
InstanceBuffer attribute streams:
   tintRgba, tintStrength, randomMaterialIndex, animOffset, userFloat[4], boundaryMask (file 02 §F)
```
Three layers combine (multiplication is the default; make the blend operation configurable):

```
final color = base material
              × broad spatial variation   (a field: e.g. a dry-yellow patch crossing many trees)
              × per-instance variation    (one tint per tree)
              × per-element variation     (one tint per leaf cluster)
```
Keep **random** tint (independent per object) and **spatial** tint (a field across many objects) as different concepts.

### 2.3 Material integration plan

| Piece | Behavior |
|---|---|
| **Cyrus Color map** (shader node, one per renderer) | Reads per-instance tint, element index, random index through the renderer's per-instance data mechanism |
| **Material Optimizer** | **Idempotent** wrapper: detect an existing Cyrus Color node anywhere in the map chain and do nothing; never duplicate; preserve existing opacity, normal maps and other shader inputs |
| **Viewport color** | Point-cloud/proxy color from tint or Diffuse; random tint visible in real time **[Doc]** |
| **Fallback** | If a renderer cannot take per-instance data, bake tint into the "Meshes" backend's vertex colors |

Source elements need **stable ids** (connected-face groups per material ID) so per-element variation stays stable when other things change. Cache the element table per source.

---

## 3. Manual editing and the override layer

### 3.1 What the reference does [Doc]

Two modes: **Generate** and **Custom Edit**. Custom Edit allows adding items one by one, transforming them with standard tools, replacing models, randomizing models/transforms (*Randomize*, *Re-Seed*), **Store Transform** (freezes random transforms into the items and disables randomness), attach/detach other Forest objects (with *Consolidate Geometry List* matching by name and type), and creating items along paths or on reference pivots/faces. Switching modes always shows a warning to avoid losing changes. **Areas are not available in Custom Edit.** New items sit at Z=0 unless a surface is active with *Link to Surface*.

In practice this is a **mode switch that bakes items**, not a persistent edit layer on top of procedural generation.

### 3.2 Cyrus override layer [Prop]

Make manual edits **sparse overrides** keyed by stable id, always active, never a mode:

```cpp
struct InstanceOverride {
  StableId id;                      // the generated instance this edit targets
  bool     deleted      = false;
  bool     hasTransform = false;    Mat4 transform;       // full replacement
  bool     hasSource    = false;    SourceId source;
  bool     pinned       = false;    // survive density/seed changes
  uint32_t flags;                   // e.g. "stored randomness"
};
struct ManualItem {                 // exists independently of generation
  StableId uniqueId; SourceId source; Mat4 transform; SurfaceBinding binding; bool linkToSurface;
};
```
- An **override** modifies a procedurally generated instance. A **manual item** exists on its own.
- Overrides are stage 12 in the pipeline (file 01 §5); manual items are a provider (file 02 §B.7).
- **Artists can paint and still hand-edit**: unlike the reference, areas remain active, and edits survive regeneration where the id still exists.

### 3.3 Policy table (must be visible, not accidental)

| Situation | Policy |
|---|---|
| Density increased | Existing overrides keep; new candidates are added around them |
| Seed changed | Ids may change on purpose → overrides become orphans; offer *keep as manual*, *keep inactive*, or *delete after confirmation* (default: keep as manual item and show a count) |
| Receiving surface removed | Edit becomes "unbound": keep world transform, flag it |
| Topology change | Barycentric binding invalid → fall back to nearest-surface re-bind or flag |
| Edited instance later rejected by new exclusion | `pinned` instances ignore density/exclusion rejects (but still count in stats); unpinned ones disappear and the override waits |
| Detach to new scatter | Items copy with their stored transforms; the new scatter gets a new `scatterGuid` |
| Attach another scatter | Merge geometry lists by (name, kind) when *Consolidate* is on; else append |

An **orphaned override** is an edit whose original generated instance no longer exists; it must never silently disappear.

### 3.4 Tools to build in the item editor

Select by type; randomize source; reset size; re-seed transform (sets a per-item seed override); store transform; add (model / random / sequence modes **[Doc]**); move/rotate/scale with standard gizmos; snapping to surface; box/paint selection; attach/detach; convert selection to manual items; undo as **one command per gesture**.

Viewport selection of millions of items uses an acceleration structure over the point-cloud representation with a capped hit-test sample (the reference exposes a hit-test point cap and denser points for the selected set in Custom Edit **[Doc]** — mirror both).

---

## 4. The Effects system (expression-driven modifiers)

### 4.1 Reference [Doc\*] — verify against the Effects pages before relying on names

Effects expose mathematical expressions that read and write per-instance attributes and can take artist-facing parameters (numbers, scene objects, controllers, textures, curves). Reported writable attributes: position, rotation, scale, visibility, source id, tint, animation sample, surface direction. Reported read-only: surface normal, slope, include/exclude distance, distribution-map coordinates, path position. Reported functions: surface hit height/normal, inside-spline, distance-to-spline, nearest position/tangent on spline, texture evaluate, curve evaluate, random geometry pick. A published *Repulsion* effect moves items away from a target object **and then explicitly re-queries the surface for Z**, showing that lateral moves do not automatically re-project onto the surface.

### 4.2 Design goals for Cyrus [Prop]

1. Effects are **programmable relationships between data the engine already has** — distance to boundary, surface normal, path position, textures, curves — not a second hidden scatter system.
2. Each effect has a **declared (and automatically verified) set of attributes it reads and writes** (§4.4).
3. Evaluation is **batched** over SoA arrays for speed; no per-instance interpreter overhead in the hot loop.
4. Safe: no scene API access on workers; scene objects used by effects are snapshotted.

### 4.3 Language and engine

- **Surface syntax:** a small expression language with `let` bindings, `if/else` expressions, vector types, and built-in functions. Use your own names, e.g. `item.pos`, `item.scale`, `surface.slope`, `area.distInclude`, `spline.distance(s, p)`.
- **Implementation:** parse → typed AST → constant folding → bytecode. Evaluate with a small VM over **blocks of 64–256 instances**, using SIMD for arithmetic ops. Embedding a mature header-only expression library is acceptable for a prototype (check its license); plan to own the compiler once semantics settle.
- **Parameters:** `number`, `vec3`, `color`, `object` (spline/mesh snapshot), `texture` (pre-baked field), `curve` (sampler). Each parameter becomes UI automatically.
- **Functions needing scene data** (`spline.distance`, `surface.heightAt`, `texture.eval`) run against core structures (polyline index, surface cache, field rasters) — the same services stages 2–6 already use.

Starter built-ins to implement:

| Group | Functions |
|---|---|
| Math | `min max clamp lerp smoothstep pow sqrt sin cos atan2 abs floor frac` |
| Random | `random(channelName)` (keyed by id), `randomRange(a,b)`, `pickSource()` |
| Surface | `surface.heightAt(xy)`, `surface.normalAt(xy)`, `surface.slope` |
| Spline | `spline.inside`, `spline.distance`, `spline.nearestPos`, `spline.nearestTangent` |
| Fields | `texture.eval(tex, uvOrPos)`, `curve.eval(c, t)` |
| Item | read/write position, rotation, scale, source, visible, tint, animSample |

### 4.4 Dependency analysis — the core idea

After parsing, **static analysis collects every attribute name used** and classifies it as read or written:

```cpp
struct EffectDeps { AttrMask reads, writes; bool readsCamera, readsSurface, readsArea; };
```
Then the scheduler places the effect automatically **[Prop]**:

| Effect writes | Pipeline slot | Downstream re-run |
|---|---|---|
| position / scale / rotation / source / visibility | **Pre** (stage 9, before boundary and occupancy) | boundary + collisions + overrides + output |
| tint / animSample only | **Post** (stage 13) | output only |
| anything + reads camera | marked camera-dependent | output prep each camera change |

A tint-only effect never invalidates surface intersections. An effect that moves or enlarges instances triggers boundary and collision reevaluation. Without declared dependencies, a flexible effect system quietly becomes a source of stale caches.

**Surface re-projection.** After an effect moves an instance laterally, the engine can auto re-project to the surface when `writes ⊇ {position.xy}` and the effect does not itself write `position.z` — configurable per effect (matches the reference's explicit re-query, but safer).

### 4.5 Example effects to ship as presets

| Effect | Behavior |
|---|---|
| Edge shrink | Scale = lerp(0.3, 1, smoothstep(0, R, area.distInclude)) |
| Lean from wall | Rotate away from nearest tangent of a spline |
| Elevation species | Source = f(item.pos.z) |
| Repulsion | Push away from a target object, re-project to surface |
| Row of vehicles | Orientation from path tangent, offset from path position |
| Wind phase | animSample from a noise texture |

Ordering questions to answer in tests: what if an effect changes the source and the new source has a larger collision radius; what if it moves outside the boundary; what if it changes scale after LOD selection? The declared-writes rule answers these automatically.

---

## 5. Animation

### 5.1 Reference [Doc]

Disabled by default (animated sources appear static). Four modes:

| Mode | Behavior |
|---|---|
| **Follow Geometry** | Every instance follows the source animation in sync |
| **Random Samples** | Start frame chosen randomly among `Count` samples spaced by `Time Offset` frames (Count 4, Offset 10 → frames 0, 10, 20, 30) |
| **Random From Map** | A grayscale map selects among samples; gray values interpolate between them (UVs from the assigned surface) |
| **Frames From Map** | A (possibly animated) grayscale map sets the **absolute frame** within a Start–End range |

Also: *Animate Only at Render Time* toggle; ForestPack 9 keeps a ~10 GB sample cache with oldest-first eviction (`samplesCacheLimit` in KB; 0 disables) **[Doc]**. **Some renderers using the older custom interface cannot honor the random/map modes** and treat everything as Follow Geometry **[Doc]**.

### 5.2 Cyrus design [Prop]

- **Source state cache** keyed by `(sourceId, timeSample, sourceRevision)` → evaluated mesh (or renderer-native animated object). 50,000 animated plants sharing 20 samples must cost 20 evaluated meshes, not 50,000.
- Per instance store only `animSample` (u16) — an **index** into the sample table — plus, for *Frames From Map*, a float frame.
- **Bounded cache:** byte budget with LRU eviction, default configurable (reference: ~10 GB), reported in stats.
- **Time models differ** — keep them separate in code:
  - Offset model: `t_i = t_scene + Δt_i` (phase offsets of continuous animation).
  - Sample-index model: a map or random value picks a sample start, which then plays.
  - Absolute-frame model: `t_i = g(M(x_i))`.
- **Capability flags per renderer backend:** `perInstanceAnimation`. If false, warn and fall back to Follow Geometry (matching the reference).
- Scatter animation is **not** wind deformation from scratch; procedural growth/wind belongs to the plant-generation product (out of scope, Tier D). Document that.

### 5.3 Cache memory rule

The cost is `(#distinct samples) × (source memory)`, not `#instances × source memory`. Cap total, evict least-recently-used, and surface "cache hit rate" and "samples resident" in stats.

---

## 6. Interactions to test explicitly

| Interaction | Expected behavior |
|---|---|
| Rotation range + facing camera | Rotation is skipped (reference) |
| Translation + Point boundary | Item may leave region; no re-check in parity mode |
| Scale change + collisions | Footprint recomputed if "scale affects radius" |
| Probability map + curve | Curve defines distribution inside the amount the map allows |
| Effect swaps source | Boundary + occupancy re-run; stats show it |
| Override + density slider | Pinned override survives; unpinned may vanish and wait |
| Re-run tint twice | Optimizer does nothing the second time |
| Animation mode on unsupported renderer | Visible warning, Follow Geometry fallback |

Continue with `04-viewport-rendering-performance.md`.

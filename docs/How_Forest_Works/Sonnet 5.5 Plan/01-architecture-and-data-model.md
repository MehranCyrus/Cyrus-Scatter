# Cyrus Scatter — Rebuild Blueprint

## 01 · Architecture and Data Model

Everything in this file is **[Prop]** (my proposed design) unless tagged otherwise. It describes the skeleton that all features hang on. If you get this file right, the features in files 02–05 become mostly *configuration of shared services* instead of one-off code.

---

## 1. Layering and module boundaries

```
cyrus_core/        Pure C++17/20. No 3ds Max headers. Builds and tests on any machine.
  ids/             StableId, hashing, keyed random
  data/            Candidate/Instance buffers (SoA), Source registry, Region types
  fields/          Scalar-field interface, curves, distance fields, raster tiles
  surface/         Mesh acceleration (BVH + 2D grid), UV index, SurfaceSample
  providers/       Image, Path, Reference, Particle, Imported, Manual
  stages/          Area stack, Source selection, Transform, Boundary, Occupancy, Overrides
  effects/         Expression compiler + VM + dependency analysis
  scheduler/       Revisions, dependency graph, job system, tile cache, cancellation
  output/          Read-only views for viewport / render / export
  serialize/       Versioned binary + JSON schema
  stats/           Counters, timers, reason codes

cyrus_max/         3ds Max SDK layer
  scene_object/    The scatter object, param blocks, references, undo
  snapshot/        Copies host data into immutable core inputs (main thread only)
  viewport/        Drawing, picking, gizmos, paint tool hooks
  ui/              Rollouts, curve editors, lister, library browser

cyrus_render/      One folder per renderer
  meshes/          Universal fallback (single combined mesh)
  vray/  corona/  arnold/  ...
```

**Rule:** `cyrus_core` never includes anything from `cyrus_max` or `cyrus_render`. Dependencies point inward only. This single rule buys you unit tests without 3ds Max, thread safety by construction, and the ability to move renderer integration forward or backward without touching the engine.

**Rule:** the Max layer is thin. If a function can be written without a Max type, it belongs in core.

---

## 2. Core data types

All hot data is **Structure-of-Arrays (SoA)** so a stage that only needs positions never loads material data, and passes over contiguous memory vectorize.

```cpp
// ---- identity ---------------------------------------------------------------
using StableId = uint64_t;                 // see §4
using SourceId = uint32_t;                 // index into SourceRegistry; kNoneSource = empty slot
constexpr SourceId kNoneSource = 0xFFFFFFFFu;

// ---- why a candidate died ---------------------------------------------------
enum class Reason : uint8_t {
  Accepted = 0, OutsideArea, ExcludedByArea, DensityFalloff, DensityMap,
  SlopeLimit, AltitudeLimit, MaterialIdFilter, NoSurfaceHit,
  BoundaryPoint, BoundarySize, CollisionLost, EmptySourceSlot,
  EffectHidden, OverrideDeleted, CameraCulled, PreviewSubset, MaxItemsCap
};

// ---- candidates: positions that *might* become instances ---------------------
struct CandidateBuffer {
  std::vector<StableId>  id;
  std::vector<float3>    posLocal;       // placement position in the generator's frame
  std::vector<float3>    pos;            // after surface resolve (world)
  std::vector<float3>    normal;
  std::vector<float2>    uv;
  std::vector<uint32_t>  receiverId;     // which surface
  std::vector<uint32_t>  triangleId;
  std::vector<uint32_t>  areaOrder;      // which include area generated it (provenance)
  std::vector<float>     densityWeight;  // accumulated density multipliers
  std::vector<float>     scaleWeight;    // accumulated scale multipliers
  std::vector<float>     distInclude;    // distance to generating include boundary
  std::vector<float>     distExclude;    // distance to nearest exclude boundary
  std::vector<SourceId>  source;
  std::vector<Reason>    status;
};

// ---- accepted instances: what outputs consume --------------------------------
struct InstanceBuffer {
  std::vector<StableId>  id;
  std::vector<float3>    position;
  std::vector<quatf>     rotation;
  std::vector<float3>    scale;
  std::vector<SourceId>  source;
  std::vector<uint32_t>  receiverId;
  std::vector<uint32_t>  tintRgba;       // packed
  std::vector<uint16_t>  animSample;
  std::vector<uint32_t>  flags;          // visible, manual, pinned, lodLevel...
  // optional attribute streams are added per feature, not stored when unused
};
```

**Why two buffers?** A candidate is a position that has not yet survived the rules. An instance has. Counting both separately is what makes the stats honest (candidates generated vs accepted), and it matches the reference product's own distinction between candidate density and final population **[Doc]**.

### Sources

```cpp
struct SourceEntry {
  SourceId       id;
  std::string    name;                   // also used for name-matching in Reference mode [Doc*]
  SourceKind     kind;                   // Mesh | Proxy | Group | LodSet | Template | None
  NodeRef        object;                 // resolved to a snapshot handle by the host layer
  float          weight;                 // relative selection weight (not required to sum to 100)
  bool           isEmptySlot;            // "keep as empty choice" (§ file 02 §A)
  Rgb            colorId;                // for color-map selection
  float          collisionRadiusPct;     // 1..100 of source size
  float3         sizeLocal;              // bounding box, used by translation %, boundaries, collisions
  float          zOffset;
  GroupMode      groupMode;              // Atomic | Expanded
  MaterialRef    materialOverride;
  std::vector<SourceId> children;        // for Group / LodSet
};

struct SourceRegistry {
  std::vector<SourceEntry> entries;
  uint64_t revision;
  // derived, cached per revision:
  std::vector<float> cumulativeWeight;   // for weighted pick
};
```

### The scalar-field interface (the workhorse abstraction)

Painted masks, splines, distance-to-boundary, slope, altitude, textures, noise and effect outputs are all "a number at a place". One interface covers them all, so falloffs, transform maps and effects reuse the same plumbing.

```cpp
struct FieldContext {
  float3 worldPos; float2 uv; float3 normal; StableId id; /* … */
};

class IScalarField {
public:
  virtual ~IScalarField() = default;
  virtual float Eval(const FieldContext& c) const = 0;                  // single
  virtual void  EvalBatch(const FieldContext* c, float* out, size_t n) const; // vectorized default
  virtual uint64_t Revision() const = 0;                                // for invalidation
};
```

### Regions and surfaces

```cpp
struct SurfaceSample {                 // returned by every surface query
  float3 position, normal; float2 uv;
  uint32_t receiverId, triangleId, materialId;
  float3 barycentric;                  // lets us re-bind after mesh deformation
};

class ISurfaceQuery {
public:
  virtual bool ProjectAlongAxis(const float3& originLocal, const Frame& f,
                                SmallVec<SurfaceSample>& hits) const = 0; // XY mode, multi-hit
  virtual bool SampleUV(const float2& uv, int channel,
                        SmallVec<SurfaceSample>& hits) const = 0;           // UV mode
};
```

---

## 3. Placement is separate from presentation

Take the sentence from your research seriously: *the placement record and the thing used to display or render it are separate concepts.* Concretely:

- The engine produces an **Accepted InstanceBuffer** (immutable once published, shared pointer).
- The viewport, picking, render backend and export each build their **own derived representation** from that buffer.
- Changing the display mode (mesh/proxy/point cloud) rebuilds only the viewport representation, never the population.

---

## 4. Stable identity and deterministic randomness

This is the single most valuable design decision in the system.

### 4.1 What the reference does **[Doc]**

Forest Pack computes each item's random seed from its **XY position**. Items at identical XY (stacked surfaces/splines) therefore share random properties, which is why a "Randomize Stacked" option exists (off by default for backward compatibility). Consequence: random properties are a function of *where the item is*, not *which item it is*.

### 4.2 What Cyrus should do **[Prop]**

Identify every candidate by a **stable id derived from how it was generated**, not from its mutable properties:

| Provider | Id inputs |
|---|---|
| Image | `scatterGuid, Image, cellX, cellY, receiverId, hitIndex` (cell = integer grid cell of the global distribution grid) |
| Path | `scatterGuid, Path, splineGuid, subSplineIndex, sampleIndex` |
| Reference | `scatterGuid, Reference, referenceNodeGuid, faceIndexOrNone, itemIndexInFace` |
| Particle | `scatterGuid, Particle, particleBornId` |
| Manual | `uniqueId` assigned at creation, never reused |

Then **every random value is a pure function of `(seed, id, channel)`**:

```cpp
inline uint64_t Mix64(uint64_t x) {             // SplitMix64 finalizer
  x += 0x9E3779B97F4A7C15ull;
  x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ull;
  x = (x ^ (x >> 27)) * 0x94D049BB133111EBull;
  return x ^ (x >> 31);
}
enum Channel : uint32_t {
  ChSource=1, ChRotX, ChRotY, ChRotZ, ChScaleX, ChScaleY, ChScaleZ, ChTranslateX, ChTranslateY,
  ChTranslateZ, ChTint, ChTintStrength, ChAnim, ChMirror, ChPriority, ChPreview, ChLodJitter, ChCluster, ChNoise
};
inline float Random01(uint64_t seed, StableId id, uint32_t ch) {
  uint64_t h = Mix64(seed ^ Mix64(id ^ (uint64_t(ch) << 56) ^ 0xA5A5A5A5ull));
  return float(h >> 40) * (1.0f / 16777216.0f);   // 24 bits → [0,1)
}
```

Properties this gives you:

- Change tint range → only `ChTint*` outputs change. Positions, rotations, collisions are untouched.
- Add a fourth source → source selection changes for some candidates; rotation/scale values for survivors do **not** shift.
- Edit one tile → ids in other tiles are identical, so nothing else reshuffles.
- A global **Seed** parameter simply changes `seed`, producing a fresh variation on demand.

### 4.3 Compatibility switch **[Prop]**

Provide `IdentityMode::LegacyXY` where the id is a hash of quantized world XY. Use it **only** while running parity experiments (file 06, test P-01) to reproduce the reference product's behavior when moving areas or changing X/Y units. Default to `IdentityMode::Cell`.

### 4.4 Edge cases to define up front

| Situation | Policy |
|---|---|
| Two include areas overlap and both generate the same grid cell | Deduplicate by cell id; keep one record whose provenance is the **topmost** include in the list **[Test]** which one the reference prefers |
| Distribution scale (X/Y Units) changes | Cell grid changes → new ids. This is expected; it is a new pattern |
| Candidate hits two stacked surfaces | One candidate per hit, `hitIndex` in the id |
| Reference marker moves | Id unchanged (based on marker identity), so its tree follows it with the same look |
| Face-derived ids and topology edits | Face indices may shift; store a secondary key (quantized face centroid) and re-match on mismatch |

---

## 5. The evaluation pipeline

Each stage has defined inputs, outputs and invalidation triggers. Stages are **logical**; the scheduler may run them per tile, in parallel, and revisit them when a dependency demands it.

| # | Stage | Reads | Writes | Re-runs when… |
|---|---|---|---|---|
| 1 | **Input snapshot** | host scene | immutable snapshots (meshes, splines, baked maps, camera, particles) | host change notifications |
| 2 | **Spatial prep** | meshes, splines, object/forest exclusions, paint tiles | BVH / 2D grid, polyline index, raster masks + distance fields | the specific input revision changes |
| 3 | **Candidate generation** | provider settings, include-area bounds, seed | `CandidateBuffer` (ids, `posLocal`) | provider settings, area bounds, seed |
| 4 | **Surface resolve** | candidates, surface cache | `pos, normal, uv, receiver, triangle`, `NoSurfaceHit` rejects | surface revision, XY/UV mode, frame |
| 5 | **Area stack** | resolved candidates, ordered area list, falloff curves | `areaOrder`, `densityWeight`, `scaleWeight`, distances, area rejects | area list, paint, splines, curves |
| 6 | **Surface filters** | normals, altitude | slope/altitude/material-ID rejects and weights | slope/altitude/ID settings |
| 7 | **Source selection** | source registry, diversity mode, cluster field, per-area subsets | `source` (incl. empty slot) | weights, mode, cluster params, seed |
| 8 | **Transform** | source sizes, transform settings, maps, curves | position offsets, rotation, scale, mirror | transform settings, maps |
| 9 | **Effects (geometry-affecting)** | any attributes | position, scale, source, visibility | effect definitions/params |
| 10 | **Boundary** | final footprints, area boundary fields | boundary rejects | boundary mode, areas |
| 11 | **Occupancy** | final footprints, radii | collision winners/losers | radii, positions, scale |
| 12 | **Overrides** | override store | deletions, replaced transforms/sources, manual items | edits |
| 13 | **Effects (appearance-only)** | attributes | tint, animation sample | effect params |
| 14 | **Output prep** | accepted buffer, camera, display settings | derived views (viewport, render stream, picking) | display/camera/LOD |

**Ordering contracts that must be explicit (never accidental):**

- Transform order matters. `choose scale → compute collision footprint` ≠ `compute footprint → scale afterward`. In the reference product **random translation is applied after placement, so items can leave their area** **[Doc]**. Cyrus therefore needs an explicit option: *check boundary before translation* (reference parity) or *after* (strict).
- Boundary check on Point uses the pivot; Size uses width + collision radius; Edge is element-wise and evaluated at render time **[Doc]**.
- Collision needs the selected source's effective radius, so source selection (7) precedes occupancy (11). An effect that swaps the source forces re-running 10–11. That is why effects declare reads/writes (file 03 §4).

---

## 6. Dependency graph and invalidation

### 6.1 Revision counters

Every input object (mesh, spline, map, curve, source entry, area, setting group) carries a monotonically increasing `revision`. A stage's **cache key** is a hash of the revisions of everything it reads.

```cpp
struct StageKey { uint64_t hash; };           // combine(revisions of all declared inputs)
template<class Out> struct StageCache {
  StageKey key; std::shared_ptr<const Out> value;
  bool Valid(StageKey now) const { return value && key.hash == now.hash; }
};
```

If the key is unchanged, the stage is skipped. If a stage produces output **bitwise identical** to its cached value (e.g. a tint change that leaves positions alone), downstream stages that did not read the changed attribute are also skipped. That "early cutoff" is what prevents a flower-color tweak from recomputing the garden.

### 6.2 Declared reads/writes

Each stage and each user parameter declares an `AttributeSet` bitmask:

```cpp
enum Attr : uint32_t { A_Position=1<<0, A_Scale=1<<1, A_Rotation=1<<2, A_Source=1<<3,
  A_Visibility=1<<4, A_Tint=1<<5, A_Anim=1<<6, A_Surface=1<<7, A_AreaDist=1<<8, A_Camera=1<<9 };
```

Rules:
- A stage re-runs if any attribute it **reads** was **written** by a re-run stage with changed output.
- Effects (file 03) have their read/write sets derived by static analysis of their expression text.

### 6.3 Initial change → work table

| User changes | Recompute | Reuse |
|---|---|---|
| Tint range / color curve | Stage 13 + output prep | everything up to 12 |
| Preview percentage / display mode | Output prep only | whole population |
| Source weight | 7 → 8 … 14 | candidate positions, surface hits |
| Collision radius | 11 → 12 … 14 | candidates, areas, transforms |
| Source scale/size | 8, 10, 11 … 14 | candidates, surface hits |
| Seed | 7, 8, 11 … 14 (random-dependent) | geometry accel., surface hits |
| Paint stroke | affected tiles from 5 onward + collision neighborhood | all other tiles |
| Spline edit | tiles under old+new boundary | everything else |
| Terrain deformation | surface cache for changed triangles; affected tiles from 4 | source library, other tiles |
| Camera move | 14 only (unless a camera-dependent rule rebuilds) | whole population |

This table becomes **data** in the scheduler, not documentation.

### 6.4 Cross-object dependencies

Forest areas (exclusions from another scatter), linked areas, shared sets, and RailClone-style imports create edges **between** scatter objects. Requirements:

- Dependencies are directed: `Trees → exclusion field → Grass`.
- **Cycle detection** at assignment time and again before evaluation. Mutual dependency is refused unless a deliberate solving policy exists.
- A dependent object re-runs only the affected tiles when its upstream population changes (it asks the upstream's published buffer for that tile region).

---

## 7. Tiling and halos

Large scenes are split into world-space **tiles** (default 16–64 m, auto-tuned so a tile holds roughly 5,000–50,000 candidates).

```cpp
struct ScatterTile {
  TileKey key;                       // (ix, iy) in a global lattice
  uint64_t inputRevision, surfaceRevision, areaRevision;
  Bounds3 bounds;
  CandidateBuffer candidates;        // generated + resolved
  InstanceBuffer  instances;         // final for this tile
  uint8_t dirty;                     // bitmask: distribution|surface|area|occupancy|display
};
```

**Halo.** A tile cannot treat its borders as hard walls or plants on adjacent tiles will overlap. Each tile evaluates a **halo** around itself:

```
halo = max( 2 × maxCollisionRadius,
            maxRandomTranslation,
            maxFalloffRange,
            brushRadius + paintFalloff )     // for paint edits
```

**Deterministic cross-tile collisions.** Use a priority rule from the id, not from processing order:

```cpp
priority(id) = Random01(seed, id, ChPriority);   // lower value wins
// accept candidate c iff no accepted neighbor n with priority(n) < priority(c)
//                         and dist(c,n) < r_c + r_n
```

Because priority depends only on the id, two threads or two tiles resolve the same conflict the same way.

**Incremental re-solve (fixed-point expansion).**
1. Mark dirty tiles from the edit footprint (+ halo).
2. Re-solve those tiles using accepted neighbors from clean tiles as fixed obstacles.
3. If any candidate **inside the halo band** changed status (accepted↔rejected), mark the adjacent tile dirty and repeat.
4. Stop when no halo-band status changes.

Greedy collision chains can propagate, so this loop terminates only when the local result is **consistent with a full rebuild**. A configurable safety cap falls back to a wider (or full) recompute and logs it in stats.

---

## 8. Threading and the 3ds Max constraint

The SDK is generally not thread-safe **[Doc\*]**; most scene operations must stay on the main thread. So:

```
Main thread:   read scene  →  build immutable Snapshot (meshes, splines, baked maps, camera)
                  │            attach settings revision R
                  ▼
Worker pool:   Compute(Snapshot, Settings, caches)  →  new InstanceBuffer (never mutates the shown one)
                  │            cancellable; checks token each tile
                  ▼
Main thread:   Publish(result) only if result.R == latest revision;  else discard (stale)
```

Requirements:

- **Immutable inputs.** Workers receive `std::shared_ptr<const Snapshot>`.
- **Procedural textures are baked on the main thread** at the distribution resolution (X/Y Pixels) before generation, so workers sample plain rasters. The reference states that any Max map works if it can be generated before render **[Doc]**; baking mirrors that.
- **Cancellation tokens** per job; a new brush stroke supersedes an in-flight job.
- **Atomic publish.** The viewport and renderer hold `shared_ptr<const InstanceBuffer>`; publishing swaps the pointer. No reader ever sees a half-built array.
- **Thread-count independence.** Output must be identical with 1 or N workers (priority-from-id, no arrival-order dependence, no floating-point reductions that vary by partition without a fixed tree).

---

## 9. Memory model

Budget by category (and show it in the stats window):

```
M ≈ M_source_states + M_instance_records + M_candidate_scratch + M_spatial_indexes
  + M_surface_cache + M_field_rasters + M_display_caches + M_render_streams
```

Guidelines:
- Candidate buffers are **scratch**: freed or pooled after a tile finishes; only accepted instances persist.
- Source geometry is stored once and referenced (instancing); 10,000 instances sharing 10 meshes are a different problem from 10,000 unique deformed meshes.
- Use `uint32` indices and packed colors; avoid per-instance heap allocations; use arena/pool allocators per tile.
- Reducing source triangle count does not fix a problem caused by too many candidates or duplicated caches. Measure first (file 04 §9).

---

## 10. Persistence, undo and cloning

- **Versioned schema.** Every saved block begins with `schemaVersion`; loaders migrate forward. Never remove a field without a migration.
- **What is saved:** settings, areas (including paint **authoring** data), source references, override store, effect definitions, seed. **Not saved:** candidates, accepted instances, derived rasters — they are regenerated deterministically. (Optionally cache accepted instances to speed up scene open, marked with the revision hash that produced them.)
- **Missing references.** Unresolved nodes/maps/assets are kept as named placeholders with a visible warning. Never silently substitute unrelated geometry.
- **Undo.** Each user action is a command (`SetParam`, `AddArea`, `PaintStroke`, `EditInstances`). Paint strokes store enough to invert exactly. Heavy derived data is never in the undo stack.
- **Clone/instance behavior.** Cloning a scatter copies settings and overrides but assigns a **new `scatterGuid`**, so ids (and therefore random values) can diverge intentionally. Provide "Re-seed copy" for artists who want an identical look instead.
- **XRef / merge.** Ids use `scatterGuid`, not scene handles, so merged scenes keep stable behavior.

---

## 11. Errors and diagnostics

Every stage writes counters into a `Stats` object:

```cpp
struct Stats {
  uint64_t candidates, accepted;
  uint64_t rejected[Reason_Count];       // per-reason counters
  double   msStage[Stage_Count];         // per-stage timings
  uint32_t tilesTotal, tilesRebuilt, tilesReused;
  size_t   bytesByCategory[Mem_Count];
  std::vector<Warning> warnings;         // e.g. "62% of candidates lost to collisions"
};
```

Standard warnings: no surface assigned; no include area; candidate cap reached; >50% collision rejects (matching the reference's own alert **[Doc]**); missing assets; cycle refused; raster resolution too coarse for scene scale; renderer lacks a requested feature.

---

## 12. Step 0 — map existing Cyrus code onto this architecture

Before writing new code, fill in this table for what you already have (including Surface Analyzer and CS Edit):

| Existing component | Which layer/stage does it implement? | Core-safe (no Max types)? | Keep / refactor / replace | Owner |
|---|---|---|---|---|
| … | … | … | … | … |

Then list **missing contracts** (stable ids? keyed RNG? dependency tracking? snapshot boundary?) and rank them by how many features they block. Fix the highest-leverage contract first (usually identity + RNG, then snapshot boundary, then scheduler). Do not rewrite everything: improve only the parts that fail measurable workflows from file 06.

Continue with `02-placement-engine.md`.

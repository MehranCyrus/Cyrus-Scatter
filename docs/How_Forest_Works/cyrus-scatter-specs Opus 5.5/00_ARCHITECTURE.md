# 00: Cyrus Scatter: System Architecture

> The master design. Every other spec file (01 to 11) plugs into the types, stage contract, and rules defined here. If another file contradicts this one, this one wins; fix the other file.

Status labels used across all specs:
- **[FP-DOC]** Forest Pack behavior documented by iToo (we match it on purpose).
- **[FP-OBS]** Forest Pack behavior seen in tutorials/forum (match it, but verify in Forest Lite first).
- **[DESIGN]** Our decision. Not a claim about Forest Pack internals.
- **[OPEN]** Needs a Forest Lite test scene or a profiling run before it's frozen (see 11_TESTING_ROADMAP.md).

---

## 1. What we're building

A 3ds Max geometry-object plugin, **Cyrus Scatter**, that reproduces the Forest Pack feature set: procedural scattering of millions of instances on surfaces, constrained by ordered include/exclude areas, with model diversity, randomized transforms, collisions, falloff, painting, manual editing, camera-aware culling, a fast viewport, and native render-time instancing.

### Goals
1. **Feature parity** with the Forest Pack behaviors in the "Forest Pack, Decoded" guide.
2. **Deterministic**: the same inputs give bit-identical item sets on any machine, any thread count, viewport or render node.
3. **Stable under edits**: moving a spline changes items near that spline only. Lowering density removes items; it never reshuffles the survivors.
4. **Interactive**: incremental re-evaluation from the first dirty stage; viewport work is budgeted and asynchronous.
5. **Scales**: 10M+ render instances per object without per-item meshes or nodes.
6. **Edits survive regeneration** (beats Forest's one-way Custom Edit).

### Non-goals (v1)
- Bit-for-bit compatibility with Forest Pack scenes or file formats.
- Reading Forest Pack objects.
- GPU compute for generation (keep the door open; CPU first).

---

## 2. Layered architecture

```text
┌──────────────────────────────────────────────────────────────────────┐
│ L4  MAX ADAPTER (needs 3ds Max headers)                              │
│     CyrusScatterObject : GeomObject  · ClassDesc2 · ParamBlock2      │
│     References & notifications · Rollout UI (Qt) · Create modes      │
│     Sub-object Custom Edit · Paint mode (PainterInterface)           │
│     FPInterface (MAXScript) · Save/Load chunks · Undo (RestoreObj)   │
├──────────────────────────────────────────────────────────────────────┤
│ L3  SNAPSHOT BUILDER (Max headers; main thread only)                 │
│     Turns live scene state at time t into an immutable SceneSnapshot │
│     Evaluates nodes, meshes, shapes, texmaps-to-samplers, camera     │
├──────────────────────────────────────────────────────────────────────┤
│ L2  CORE ENGINE (NO Max headers; pure C++20; unit-testable)          │
│     Services: StableRNG, SurfaceCache/BVH, Boundary2D, RasterMask,   │
│               SpatialHash, MapSampler interface, JobSystem           │
│     Pipeline: ordered Stages S0..S12 over a Population (SoA)         │
│     Caches: per-object stage outputs + global SharedCacheRegistry    │
├──────────────────────────────────────────────────────────────────────┤
│ L1  OUTPUT ADAPTERS (Max headers)                                    │
│     ViewportAdapter (Nitrous: InstanceDisplayGeometry, point cloud)  │
│     RenderAdapter (RenderTimeInstancingInterface + GetRenderMesh)    │
│     BakeAdapter (real Max instances), Exporter (JSON/XML/CSV)        │
└──────────────────────────────────────────────────────────────────────┘
```

**Rule 1: The core never includes Max headers.** [DESIGN] Everything Max-specific is converted to plain data in L3. This gives you: offline unit tests, a command-line benchmark harness, safe worker threads (Max scene access off the main thread is forbidden), and a future port to other DCCs.

**Rule 2: Snapshots are immutable.** [DESIGN] Once built, a `SceneSnapshot` is shared read-only by worker threads (`std::shared_ptr<const SceneSnapshot>`). A new edit creates a new snapshot (sharing unchanged sub-objects by pointer).

**Rule 3: Populations are outputs, not state.** [DESIGN] The authored truth is: parameters + references + paint strokes + overrides + Custom Edit items. A `Population` is always recomputable from those. Never save a population as truth (only optional caches).

---

## 3. Coordinate spaces and units

| Space | Definition | Used by |
|---|---|---|
| **World** | Max world space | Snapshot input, render output |
| **Forest-local (FL)** | The Cyrus node's object space. XY plane = generation plane in XY mode, +Z = drop direction reversed | Lattice, areas, falloff, seeds |
| **Surface-local (SL)** | Each surface node's object space | Surface BVH storage, ray casts |
| **UV** | A surface mapping channel | UV-mode generation |
| **Item-local** | Source mesh object space | Instances |

- All core math in **double for positions in FL during generation**, float for stored items (positions relative to the object; use a per-chunk origin if scenes exceed ~10 km at mm units). [DESIGN] Forest reports numeric-limit crashes at huge extents with mm units [FP-OBS]; chunk origins avoid that.
- Distances in the core are in **system units** (whatever Max uses). Percentages are stored as 0..1 floats internally, shown as % in UI.
- Rotations stored as **unit quaternions** in the core. UI shows degrees; the Effects VM uses radians (like Forest [FP-DOC]).

---

## 4. Core data types (the contract every module uses)

```cpp
namespace cyrus {

using u8=uint8_t; using u16=uint16_t; using u32=uint32_t; using u64=uint64_t; using i32=int32_t;

// ---- Identity -------------------------------------------------------------
// A StableKey identifies a candidate independent of density, thread count,
// list order and evaluation order. See 01_CORE_SERVICES §5.1 for the hash.
struct StableKey { u64 v; };

enum class GenKind : u8 { Lattice=1, Path=2, Reference=3, Particle=4, Manual=5 };

// Packed into the key hash (not stored separately in the hot path):
struct KeyParts {
  GenKind kind;
  u32     sourceId;    // area id (lattice), path id, reference node id, PFlow id, manual id
  i32     tileX, tileY;// lattice tile, or path segment, or face index
  u32     subX, subY;  // pixel within tile, or sample index, or sub-face sample
  u32     layer;       // stacked-surface layer / sub-spline id (0 unless RandomizeStacked)
};

// ---- Population (structure of arrays) -------------------------------------
// One entry per candidate that survives at least Stage S1.
struct Population {
  // identity / provenance
  std::vector<StableKey> key;
  std::vector<u32>       areaIndex;   // which area program entry generated it
  std::vector<u32>       pixelX, pixelY; std::vector<i32> tileX, tileY; // lattice only
  std::vector<float>     pathPos;     // 0..1 (path only)
  // surface hit
  std::vector<Vec3f>     pos;         // FL position (after surface drop)
  std::vector<Vec3f>     normal;      // FL surface normal
  std::vector<float>     slopeDeg, altitude;
  std::vector<u16>       surfaceId, matId;
  std::vector<Vec3f>     uvw;
  // area / falloff
  std::vector<float>     incDist, excDist;   // distance to nearest include/exclude boundary (+inf if none)
  std::vector<float>     densityFactor;      // product of all density falloffs, 0..1
  std::vector<Vec3f>     scaleFactor;        // product of all scale falloffs (xyz; height-only => (1,1,s))
  // model
  std::vector<u16>       geomId;             // index into GeometryTable (NOT UI order; see §6)
  // transform (final)
  std::vector<Quatf>     rot;
  std::vector<Vec3f>     scale;
  std::vector<u8>        mirror;
  // render payload
  std::vector<u32>       tintRGBA8;          // packed tint color + multiplier in A
  std::vector<u16>       animSample;
  std::vector<u8>        lod;
  // status
  std::vector<u32>       flags;              // ItemFlags bitset below
};

enum ItemFlags : u32 {
  F_ALIVE          = 1u<<0,   // passed all generation-time filters
  F_CULL_BOUNDARY  = 1u<<1,   // removed by Size boundary check
  F_CULL_COLLISION = 1u<<2,
  F_CULL_DENSITY   = 1u<<3,   // falloff / density map thinning
  F_CULL_FILTER    = 1u<<4,   // slope / altitude / matid
  F_HIDDEN_EFFECT  = 1u<<5,   // Effects set visible=0
  F_HIDDEN_USER    = 1u<<6,   // override: deleted by user
  F_OVERRIDDEN     = 1u<<7,   // has an OverrideRecord applied
  F_MANUAL         = 1u<<8,   // Custom Edit manual item
  F_EDGE_CLIP      = 1u<<9,   // straddles boundary; Edge mode trims elements at render
  // view-dependent bits live in ViewMask, never here
};

// ---- View-dependent mask (per view / per render camera) -------------------
struct ViewMask {
  u64 populationVersion;          // must match Population version
  std::vector<u8> visible;        // camera frustum/far clip/back offset result
  std::vector<u8> lod;            // LOD index chosen for this view
  std::vector<float> camDensity;  // optional camera-distance density factor
};
}
```

Why SoA: each stage touches few fields, so SoA keeps caches hot and makes SIMD and chunked threading trivial. A stage that removes items **sets flags; it never erases**. Compaction happens once, at output time (§7, S12). [DESIGN]

**Memory budget.** Hot output per item: pos 12 + rot 16 + scale 12 + geomId 2 + tint 4 + flags 4 + key 8 ≈ **58 B**. 10M items ≈ 580 MB. To stay sane: (a) provenance fields (pixel/tile/uvw/dist) are kept only until S12 and freed in render mode, (b) render evaluation can stream in chunks (01 §5.7), (c) rot can be packed to 8 B (smallest-three quaternion) in the render buffer. [DESIGN]

---

## 5. Authored state (what gets saved)

| Data | Storage | Spec |
|---|---|---|
| Scalar/enum parameters (rollouts) | ParamBlock2 blocks, one per rollout | 02 |
| Lists (geometry list, areas list, surfaces list) | Tab-based ParamBlock2 params **plus** a stable `u32 id` per entry | 02 |
| Node references (surfaces, splines, objects, other Cyrus objects, sources) | References via the param blocks (`TYPE_INODE_TAB`) | 02 |
| Paint strokes | Custom save chunk, versioned | 05 |
| Overrides (edits on procedural items) | Custom save chunk: `map<StableKey, OverrideRecord>` | 10 |
| Manual items (Custom Edit adds) | Custom save chunk: array of `ManualItem` with ids | 10 |
| Generator algorithm version | Saved u32 `algoVersion` | 01 |

**`algoVersion` rule** [DESIGN]: whenever a code change would alter output for the same inputs (hash change, sampling change), bump the algorithm version and keep the old code path available for old files. Old scenes must render the same after a plugin update; Forest has shipped "distributions may differ from 9.2" warnings [FP-DOC] and you don't want that.

---

## 6. Identity of list entries

Forest's lists are parallel arrays indexed by UI position [FP-OBS], which breaks scripts and edits when users reorder. Ours:

- Every geometry entry, area entry, and surface entry has an immutable **`u32 entryId`**, assigned from a per-object counter on creation, never reused.
- The UI order is a separate array of ids.
- `Population.geomId` stores a **GeometryTable index** resolved per evaluation from entryIds; overrides and manual items store **entryId**, not the index.
- Area **order** matters for semantics (bottom→top program, 04 §6); area **identity** (entryId) goes into StableKeys only for an area that defines its own distribution frame (D1); ordinary Include areas don't appear in keys at all. So reordering or reshaping areas changes results only where order semantics say it should, and never re-seeds items.

---

## 7. The pipeline

### 7.1 Stage list and contracts

Each stage is a pure function of (snapshot, params, upstream stage outputs). Fixed order:

| # | Stage | Reads | Writes | Spec |
|---|---|---|---|---|
| S0 | **Snapshot** (L3, main thread) | Max scene | `SceneSnapshot` | 02 |
| S1 | **Generate** candidates: one lattice per distribution frame (D1), plus path / reference / particle + manual items | params.distribution, area program, surfaces bounds | key, areaIndex, provenance, pos(xy) | 03 |
| S2 | **Surface resolve** (drop / UV map) | surfaces | pos(z), normal, slope, altitude, matId, uvw, surfaceId | 04 |
| S3 | **Area program** (ordered include/exclude, linked areas, Object/Forest masks) + filters (matId, slope, altitude) | area program, masks | flags (F_ALIVE / F_CULL_FILTER), incDist, excDist | 04 |
| S4 | **Falloff** (boundary, altitude; density + scale) | incDist, excDist, altitude, curves | densityFactor, scaleFactor | 05 |
| S5 | **Density thinning** (density map grey, falloff density) | densityFactor, map value | flags (F_CULL_DENSITY) | 03, 05 |
| S6 | **Choose model** (probability / color match / clusters / area model subsets / sequence) | GeometryTable, maps | geomId | 06 |
| S7 | **Transform** (direction, path follow, random T/R/S + curves + maps, mirror, scale composition; Look-At is view-dependent, see D5) | geomId, normal, scaleFactor | pos, rot, scale, mirror | 07 |
| S8 | **Boundary check** (Point / Size; marks Edge candidates) | geomId footprint, scale, boundary service | flags | 04 |
| S9 | **Collisions** | geomId radius, scale, pos | flags (F_CULL_COLLISION) | 06 |
| S10 | **Overrides & Effects** (apply OverrideRecords, then Effects VM) | everything | any writable field, flags | 10 |
| S11 | **Shading payload** (tint, animation sample) | maps, gradients | tintRGBA8, animSample | 07 |
| S12 | **Compact & publish** → immutable `PublishedPopulation` with version | flags | dense arrays | 01 |
| V  | **View pass** (per viewport / per render camera, NOT part of the population) | PublishedPopulation, camera | ViewMask (frustum, far clip, back offset, LOD, camera falloff) | 08 |

Notes on the order (all [DESIGN] unless noted):
- S1 before S2: Forest generates in FL XY then drops along Z [FP-DOC].
- S6 before S8/S9: Size boundary and collisions need each item's radius, which depends on the model.
- S9 after S7: radius depends on final scale.
- Collision losses are dropped before Custom Edit snapshot [FP-OBS], consistent with S9 < S10.
- S10 applies **overrides before Effects** so scripts see user edits. Effects writing `geomId` or `scale` **does not** re-run collisions (documented limitation; Forest doesn't document either way [OPEN]).
- The view pass never mutates the population. Orbiting the camera can never reshuffle items.

### 7.2 Stage interface

```cpp
struct StageContext {
  const SceneSnapshot&  snap;
  const ScatterParams&  params;     // POD copy of all param blocks at time t
  Services&             svc;        // RNG, caches, job system, map samplers
  EvalMode              mode;       // Viewport | Render | Export
  CancelToken&          cancel;     // checked per chunk
  Stats&                stats;      // counters per stage (Forest-style Stats window)
};

class IStage {
public:
  virtual StageId id() const = 0;
  virtual DirtyBits consumes() const = 0;   // which param groups / inputs invalidate me
  virtual void run(StageContext&, Population&) = 0;
  virtual ~IStage() = default;
};
```

### 7.3 Incremental re-evaluation

- Every parameter and input belongs to a **DirtyBits group** (e.g. `D_DIST_MAP`, `D_AREA_GEOM(areaId)`, `D_AREA_ORDER`, `D_SURFACE_GEOM(surfId)`, `D_SURFACE_LIST`, `D_SURFACE_PARAMS`, `D_SURFACE_FILTER`, `D_FALLOFF(areaId)`, `D_PAINT_STROKES(areaId)`, `D_GEOM_LIST`, `D_TRANSFORM`, `D_COLLISION`, `D_EFFECTS`, `D_OVERRIDES`, `D_MANUAL`, `D_VIEWPORT`, `D_TIME`). The authoritative group-to-first-stage table lives in 02 (notifications) and each feature spec lists its groups.
- A static table maps groups → **first dirty stage**. Change rotation range → restart at S7. Move a spline → restart at S1 for that area (and S3 for areas above it).
- Each stage keeps its output **checkpoint** (copy-on-write SoA buffers). Restart = load checkpoint of stage k-1, run k..S12.
- **Spatial locality** (DESIGN, v2): for area/geometry edits, compute the dirty FL rectangle (old bounds ∪ new bounds, + max falloff range + max collision radius) and re-run S1..S9 only for tiles intersecting it. Requires tile-chunked populations (01 §5.7). Ship v1 with whole-population restarts from the dirty stage; add tile-locality when profiling says so.

### 7.4 Viewport vs render evaluation

| | Viewport | Render |
|---|---|---|
| Trigger | Coalesced invalidation (no fixed timer) | `RenderBegin` / per-frame `GetRenderMesh` or instancing call |
| Threads | Background job; result published when complete; stale generations dropped | Synchronous (blocking) on all cores |
| Budget | `viewportMaxItems` density multiplier (approximate, like Forest [FP-DOC]) | `renderMaxItems` hard cap with warning |
| Camera | Optional (off by default, slow [FP-DOC]) | Limit to visibility on/off |
| Collisions | Optional preview (Forest: "Preview on Viewport") | Always |
| Edge mode | Off (preview via toggle) | On |

**Budget rule** [DESIGN] (refined in D6): the viewport budget is applied as an **extra global density factor** `k = min(1, maxItems / estimatedCount)` fed into S5. Because S5 uses stable hashes, raising the budget only adds items; it never moves them. That's the same trick that makes Forest's Max Items approximate [FP-OBS], and it's what keeps it multithread-friendly.

---

## 8. Threading model

- **Main thread**: Max API, snapshot building (S0), UI, undo, notifications, publishing results to Nitrous.
- **Job system** (01 §5.7): fixed worker pool; work split into **tiles** of FL space (default 64×64 m, auto-scaled to scene extent so there are ≥ 4×cores tiles).
- **Determinism**: every random value is a pure function `hash(seed, key, purpose)` (01 §5.1). Tiles produce independent results; merge order is **by tile index, then key**: never by completion order.
- **Cross-tile stages**: collisions (S9) and Forest-area masks need neighbours. Collisions use a two-phase scheme (01 §5.5): tiles with halo; conflicts resolved by deterministic priority, so the result is independent of thread scheduling.
- **Cancellation**: each new viewport generation bumps `evalGeneration`; workers check `cancel` per chunk and abandon. Render evaluations are never cancelled by viewport activity.
- **No Max calls on workers.** Texmaps are pre-baked to `MapSampler` grids in S0 (02 §6.5 / 01 §5.6). If a map is too complex to pre-bake (procedural with huge resolution), evaluate on the main thread in batches.

---

## 9. Dependency graph between Cyrus objects

A Cyrus object can depend on another Cyrus object (Forest areas, linked areas, linked surfaces, "Get From Forest", Render Mode=Meshes as a source). [FP-DOC]

- Model as Max references (so Max handles save/load/notifications).
- **Cycle detection** at assignment time: walk dependents; refuse and show a message if a cycle would form.
- A dependency reads the other object's **PublishedPopulation** (immutable, versioned). Cache key includes the upstream `populationVersion`.
- Evaluate upstream first: the snapshot builder requests upstream objects' populations synchronously (render) or uses their latest published population (viewport; re-evaluates when the upstream publishes a new version).

---

## 10. Caches

Two tiers. Full details in 01 §5.8.

**Global `SharedCacheRegistry`** (process-wide, ref-counted, LRU with a memory cap, default 4 GB):
- `SurfaceAccel` keyed by (node handle, geometry validity/version, topology version, uv channel). Shared by every Cyrus object using that surface, which matches Forest's shared "terrain table" [FP-DOC].
- `PolyShape2D` keyed by (node, shape version, steps, projection axis, FL transform).
- `RasterMask` (Object / Forest areas) keyed by (source, version, resolution, top limit, FL transform).
- `SourceSnapshot` (mesh + materials + bounds + point samples for point cloud) keyed by (node, time-or-anim-sample, version).
- `MapGrid` (pre-baked texmap) keyed by (texmap, time, resolution, channel).

**Per-object** stage checkpoints (§7.3) and the PublishedPopulation history (keep current + previous for async consumers).

---

## 11. Persistence and versioning

- ParamBlock2 with explicit version numbers; `IParamBlock2PostLoadCallback` / `ParamBlockPLCB` for migrations.
- Custom chunks (`Save`/`Load` on the object) for strokes, overrides, manual items: each chunk starts with `u32 chunkVersion`.
- Saved `algoVersion` (§5).
- Never save populations (optional future: a cache file next to the .max for huge scenes, always rebuildable).

---

## 12. Diagnostics (build these early; they pay for themselves)

- **Stats panel** (Forest has a "real time status window" [FP-DOC]): candidates generated, killed per reason (flags), survivors, time per stage, cache hits/misses, memory.
- **Debug overlays** in the viewport: area masks, boundary loops, falloff heatmap, collision spheres, tile grid, surface hit normals, cluster cells.
- **Export**: `cyrus.export(path, channels)` dumping any Population fields to CSV/JSON for diffing between builds and against Forest's `exportData` [FP-DOC].
- **Determinism self-test**: evaluate twice with 1 thread and N threads; hash the published population; must match.

---

## 13. Source tree

```text
cyrus/
  core/                 # L2, no Max headers
    types/              # Vec, Quat, Population, keys
    services/           # rng, surface_accel, boundary2d, raster_mask, spatial_hash, map_sampler, jobs, cache_registry
    pipeline/           # stages s1_generate ... s12_publish, view_pass
    effects/            # expression lexer, parser, compiler, VM
    paint/              # stroke model, coverage engine (from the surface painting research)
    io/                 # export, binary chunk (de)serialization helpers
  max/                  # L3 + L4 + L1
    plugin/             # ClassDesc, CyrusScatterObject, param blocks, create callbacks
    snapshot/           # builders: mesh, shape, texmap bake, camera, dependencies
    ui/                 # rollouts (Qt), list widgets, curve editor
    edit/               # Custom Edit sub-object mode, paint command mode, undo objects
    display/            # Nitrous adapters, point cloud render item, proxies
    render/             # RenderTimeInstancing provider, GetRenderMesh fallback, Cyrus Color texmap, Edge
    script/             # FPInterface
    tools/              # bake to instances, library browser
  tests/                # core unit tests, golden populations, perf harness (no Max)
  bench/                # command-line benchmarks on recorded snapshots
```

---

## 14. File map

| File | Covers |
|---|---|
| 01_CORE_SERVICES.md | StableRNG & keys, surface accel, Boundary2D, raster masks, spatial hash, map sampler, job system, caches |
| 02_PLUGIN_SHELL.md | Max object, param blocks, references, notifications, UI, create modes, snapshot builder, geometry list, library/presets |
| 03_GENERATORS.md | Lattice (Image mode), distribution maps, Path, Reference, Particle, manual source |
| 04_SURFACES_AREAS.md | Surfaces XY/UV, filters, area program, all area types, linked areas, boundary check |
| 05_FALLOFF_PAINT.md | Boundary/altitude falloff, curve editor, paint areas |
| 06_DIVERSITY_COLLISIONS.md | Geometry table, probability, color match, clusters, collisions |
| 07_TRANSFORMS_ANIM_MATERIAL.md | Transform composition, random ranges, curves, maps, animation samples, tint |
| 08_CAMERA_DISPLAY.md | View pass, camera culling, LOD, viewport display modes, point cloud, budgets |
| 09_RENDER.md | Render instancing, per-instance data, Cyrus Color, Edge mode, bake tool |
| 10_EDITING_SCRIPTING.md | Custom Edit with stable overrides, undo, Effects VM, MAXScript interface |
| 11_TESTING_ROADMAP.md | Test strategy, Forest Lite comparison scenes, benchmarks, milestones |

---

## 15. Decisions log (cross-spec resolutions)

These were settled while reviewing files 01 to 11 together. They override anything in the feature specs that reads differently.

**D1. Overlapping Include areas union; keys belong to distribution frames, not areas.** S1 generates one lattice per *distribution frame*. Frame 0 is the object's global map; an Include area whose Override Distribution Map changes lattice geometry (map Scale, different map resolution) gets its own frame with id = that area's entryId. For Lattice keys, `KeyParts.sourceId = frameId`. S3 assigns ownership: `areaIndex` = the lowest (first evaluated) Include of the same frame containing the candidate; a candidate no Include of its frame contains is killed. Excludes act on `areaIndex` (only lower owners). Why: no coplanar duplicates where Includes overlap (Forest warns about these [FP-DOC]), and moving or reordering an Include spline never re-seeds items it still covers (matches Forest's XY-position seeding [FP-DOC]). A test-only `overlapPolicy = DuplicatePerArea` reproduces per-area generation for Forest Lite comparison [OPEN]. (03 section 4.7, 04 section 6.1.)

**D2. `KeyParts.sourceId` is always an authored, immutable id** (frameId, path entryId, reference node's stable id, PFlow source id, manual item id), never a UI position. 01 section 5.1 owns the canonical byte encoding of keys; other files show it for illustration only.

**D3. Collision results are provisional until reconciliation.** Tile-local collision results (S9) may not be published until the border reconciliation / stable-priority scan in 01 section 5.5 completes. This is what makes the outcome independent of thread count. (01, 06.)

**D4. Packed rotation format.** Render and display buffers may store rotations as smallest-three quaternions (3 x 16-bit + 2-bit index, 8 bytes) as specified in 01 section 5.9. With 16-bit components the worst-case angular error is on the order of 1e-4 radians (about 0.005 degrees); measure it in a unit test and record the bound. One shared codec; S12 and both output adapters must use it.

**D5. Look-At / Facing Camera lives in the view pass.** It never overwrites `Population.rot`. The view pass produces an optional per-view derived transform buffer (extension of `ViewMask`); when Facing Camera is on, random rotation is skipped for those items, as Forest does [FP-DOC]. (07, 08.)

**D6. Viewport budget: two levels.** (a) Generation level: when the estimated candidate count exceeds the viewport budget, S5 multiplies `k = min(1, maxItems / estimatedCount)` into the keep probability using the same `Density` hash purpose, so viewport survivors are a subset of render survivors before collisions. (b) Display level: point cloud and instance draw caps (08) thin further inside the generated viewport population with a separate `DisplayBudget` purpose. Known consequence: with a budget active, viewport collisions can keep items that render would remove. That's accepted; the viewport is a preview (Forest behaves the same way: its Max Items is approximate [FP-OBS]).

**D7. Camera-derived scale and density never write `Population.scaleFactor` or `densityFactor`.** Those are S4 outputs reused across views. Camera factors live in `ViewMask` (`camDensity`, optional `camScale`). `ViewMask` also carries a `ViewKey` and its own `viewMaskVersion`. (08.)

**D8. Transient checkpoint sidecars are allowed.** Stages may attach sidecar arrays to their checkpoints (e.g. `CandidateExtras` for reference/particle source transforms in 03; `surfaceHit`, `includeOwner`, `excludeOwner`, model allowlist and edge records in 04; `CollisionSphere` in 06; an animation sample side table for Frame-from-Map frames in 07). Sidecars are evaluation outputs, are freed at S12 unless an output adapter needs them, and are never saved.

**D9. Manual items** enter at S1 with `F_MANUAL`, consume `D_SURFACE_GEOM` only when linked to a surface, and S12 publishes all rows in canonical key order (tile, then key) regardless of where they were appended. (03, 10.)

**D10. Canonical population hash.** The golden-test hash of a PublishedPopulation is computed over rows sorted by (tile index, StableKey, ManualId) as in 11 section 4, fields serialized little-endian in the order of the `Population` struct, floats as raw IEEE-754 bits after quantization to the stored type. Defined once (11 section 4) and used by every determinism test.

**D11. Separate random channels for area random scale and falloff scale.** Area "Random Scale by Area" is a seeded random factor (purpose `AreaScale`), falloff scale is deterministic (`scaleFactor`). They're multiplied in S7 but invalidated independently. (05, 07.)

**D12. The recorded-snapshot benchmark harness is an M0 deliverable**, not a late optimization tool. Without it you can't measure stage boundaries, cache hits or determinism. (11.)

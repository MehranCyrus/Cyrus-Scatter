# 01: Cyrus Scatter core services

## 1. Purpose and scope

This document specifies L2 services used by stages S1 through S12 and view pass V. It extends the contracts in `00_ARCHITECTURE.md`; it does not replace the `StableKey`, `KeyParts`, `Population`, `StageContext`, `IStage`, `DirtyBits`, `SharedCacheRegistry`, or stage ordering already defined there. The core remains pure C++20 and includes no 3ds Max headers. Max scene evaluation, notifications, parameter blocks, and texmap baking belong to L3 and L4 adapters.

The services covered here are:

1. StableRNG and StableKey.
2. SurfaceAccel for mesh and UV queries.
3. Boundary2D for spline and projected boundary operations.
4. RasterMask for object and Forest area masks.
5. SpatialHash and the deterministic collision resolver.
6. MapSampler for immutable baked maps.
7. JobSystem, tiling, cancellation, and streaming.
8. SharedCacheRegistry.
9. Mathematical foundations and compact representations.

It specifies deterministic Cyrus behavior where Forest documents behavior, and explicit choices where internals are unpublished. Claims use `[FP-DOC]` or `[FP-OBS]`; choices use `[DESIGN]`; experiments use `[OPEN]`.

### 1.1 Service invariants

Every service follows these invariants:

* Inputs are immutable during a stage evaluation.
* Results are either immutable cache objects or tile-local writable buffers.
* Any order-sensitive operation has an explicit stable ordering, never completion order.
* Floating point tolerances are named and versioned. A tolerance change that changes an accept or reject decision bumps `algoVersion`.
* A cancellation request stops work at a chunk boundary and never publishes a partial `Population`.
* A cache hit is only an optimization. Rebuilding from its key must produce the same bytes, subject to documented serialization precision.

Why: a one-bit density difference can alter later collision winners. Hidden dependence on scheduling, pointer addresses, or cache state would reshuffle a scene without an authored edit.

## 2. Forest Pack behavior to match

The following source behavior constrains these services:

* Forest creates candidates in Forest-local XY and then drops them along local Z in XY surface mode. UV mode uses the surface UVs as the distribution guide. `[FP-DOC]` See [Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces) and the research notes in `B_areas.md`.
* Forest maintains an internal processed terrain table shared by Forest objects using the same surface. Auto updating is available, while a manual update can be used for expensive terrain. `[FP-DOC]` See [Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces). `SurfaceAccel` is the Cyrus equivalent.
* Surface Areas and spline Areas are used as Include or Exclude regions. Boundary checking has Point, Size, and Edge behavior. Point tests a pivot, Size accounts for item size and collision radius, and Edge trims geometry at render time. `[FP-DOC]` See [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas).
* Object and Forest areas are masks projected from geometry. Forest's distribution and area documentation describes Image, Path, Reference, and Particle Flow modes but does not publish its rasterizer, hash, BVH, or cache internals. `[FP-DOC]` See [Distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution) and [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode). The raster rules below are therefore `[DESIGN]`.
* Forest collision checking uses virtual bounding spheres, with global and per-geometry radius controls and a collision height. Colliding neighbors are deleted, but the exact priority order is not documented. `[FP-DOC]` for the sphere behavior, `[OPEN]` for priority. See [Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry) and [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode).
* Forest's viewport Max Items is an approximate density adjustment rather than necessarily an exact count. `[FP-DOC]` See [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display) and [forum explanation](https://forum.itoosoft.com/forest-pro-(*)/forestpack-display-count-doesn-t-work-with-limit-to-visibility-enabled/). This supports applying a stable global density factor in S5.
* A Forest object can use surfaces and areas supplied by another Forest or ForestSet, and a processed surface table may be reused among consumers. `[FP-DOC]` See [ForestSet](https://docs.itoosoft.com/forestpack/forestset-plugin) and [Forest Pack 8 changes](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-8).
* Camera changes must not reseed canonical items. The camera pass is separate in `00_ARCHITECTURE.md`. `[DESIGN]` This follows Forest's documented view-dependent clipping and falloff while avoiding camera-induced reshuffling. See [Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera).

Forest does not specify the private hash, numeric conversion, BVH, polygon kernel, collision priority, map resolution, or thread partitioning. Those parts below are Cyrus contracts.

## 3. Parameters

These settings are service-facing settings. The UI names and rollout ownership are suggestions for `02_PLUGIN_SHELL.md`; internal names are the stable names used in `ScatterParams` and cache keys. Unless stated otherwise, percentages are stored as normalized 0 to 1 values in core.

| UI name | Internal name | Type | Default | Range and units | Rollout | DirtyBits group | Notes |
|---|---|---:|---:|---|---|---|---|
| Random Seed | `seed` | `u64` | 1 | Any `u64` | Distribution | `D_DISTRIBUTION` | Object seed. Never use pointer or node address. |
| Random Algorithm Version | `algoVersion` | `u32` | 1 | Positive integer | Advanced | `D_ALGO` | Saved with object. Any output-changing algorithm change increments it. |
| Seed by Forest XY | `seedByForestXY` | `bool` | true | On or off | Distribution | `D_DISTRIBUTION` | When on, key includes quantized Forest-local XY cell identity. When off, source `KeyParts` identity alone seeds the candidate. |
| Randomize Stacked | `randomizeStacked` | `bool` | false | On or off | Surfaces | `D_SURFACE` | Adds `KeyParts.layer` to the key for stacked surface hits. |
| Surface Ray Padding | `surfaceRayPadding` | `double` | 1.0 | Scene units, nonnegative | Surfaces | `D_SURFACE` | Extends ray origin and max distance to avoid coplanar misses. `[DESIGN]` |
| Double-sided Surface | `surfaceDoubleSided` | `bool` | true | On or off | Surfaces | `D_SURFACE` | If off, only front-facing triangles accept the configured ray direction. |
| Boundary Tolerance | `boundaryTolerance` | `double` | `1e-7` | Relative to scene scale | Areas | `D_AREA_GEOM` | Used for robust on-edge classification. Actual epsilon is `max(absTol, relTol * localExtent)`. |
| Boundary Steps | `boundarySteps` | `u32` | 1 | 0 to 64 per spline segment | Areas | `D_AREA_GEOM` | Max approximation steps for curved spline extraction in the snapshot. |
| Raster Resolution | `rasterResolution` | `u32` | 512 | 16 to 8192 pixels per axis | Areas | `D_AREA_GEOM` | Default 512 is the requested Cyrus baseline. Higher values increase memory and bake time quadratically. |
| Raster Conservative | `rasterConservative` | `bool` | true | On or off | Areas | `D_AREA_GEOM` | Expands coverage to every pixel touched by a projected triangle. Keep on for masks. |
| Top Limit | `topLimit` | `double` | +infinity | Scene units | Areas | `D_AREA_GEOM` | Clip projected geometry by the selected axis before rasterization. |
| Mask Scale | `maskScale` | `double` | 0 | Scene units | Areas | `D_AREA_GEOM` | Positive dilates, negative erodes using Euclidean distance transform. |
| Map Filter | `mapFilter` | enum | Bilinear | Nearest or Bilinear | Distribution/Transform | `D_DIST_MAP` or `D_TRANSFORM_MAP` | Lattice density maps use nearest by default; transform maps use bilinear. |
| Map Tile Mode | `mapTileMode` | enum | Clamp | Clamp, Repeat, Mirror | Distribution/Transform | `D_DIST_MAP` | Applies in normalized map coordinates. |
| Collision Enabled | `collisionEnabled` | `bool` | false | On or off | Distribution | `D_COLLISION` | Render default follows the authored setting; viewport may disable collision preview per `00`. |
| Collision Radius | `collisionRadius` | `float` | 1.0 | 0 to 100, multiplier | Distribution | `D_COLLISION` | Combined with geometry radius. Forest documents a percentage-like radius control. |
| Collision Height | `collisionHeight` | `float` | 0.5 | 0 to 1 of item height | Distribution | `D_COLLISION` | Sphere center fraction along local item height. Exact Forest default is version-specific, so this is `[DESIGN]`. |
| Collision Cell Size | `collisionCellSize` | `double` | 0 | Auto | Advanced | `D_COLLISION` | Zero selects a deterministic automatic size from radii. |
| Collision Tile Size | `collisionTileSize` | `double` | 64 | 8 to 1024 m | Advanced | `D_COLLISION` | Matches the default FL tile size in `00`. |
| Collision Priority | `collisionPriority` | enum | StableKey | StableKey, Area order, or XY | Advanced | `D_COLLISION` | StableKey is the only default independent of tile layout. |
| Cache Memory Cap | `cacheMemoryCap` | `u64` | 4 GiB | 256 MiB to 64 GiB | Advanced | `D_CACHE` | Process-wide SharedCacheRegistry cap. `[FP-DOC]` 4 GB is the architecture default, not a Forest claim. |
| Cache Debug | `cacheDebug` | enum | Off | Off, log, overlay, assert | Advanced | `D_CACHE` | No semantic impact. |
| Worker Count | `workerCount` | `u32` | Hardware concurrency | 1 to 256 | Advanced | `D_JOB` | Zero means hardware concurrency. Only affects timing, never results. |
| Tile Size | `tileSize` | `double` | 64 | Scene units | Advanced | `D_JOB` | Worker generation tile size. Must be included in cache diagnostics, not in StableKey. |
| Render Stream Chunk | `renderChunkItems` | `u32` | 65536 | 4096 to 1,048,576 | Advanced | `D_JOB` | Bound for render memory. |
| Surface Auto Rebuild | `surfaceAutoRebuild` | `bool` | true | On or off | Surfaces | `D_SURFACE` | Mirrors documented manual versus auto terrain processing choice. |

A zero or invalid value is normalized at snapshot construction and recorded in diagnostics. User-visible defaults that are not published by Forest, such as the exact collision height or service tolerances, are Cyrus defaults, not compatibility claims.

## 4. Data structures

### 4.1 Stable identity and purpose tags

`00_ARCHITECTURE.md` defines `StableKey` and `KeyParts`. The following types extend that contract:

```cpp
namespace cyrus {

enum class RngPurpose : u16 {
    ModelPick = 1,
    RotX = 2, RotY = 3, RotZ = 4,
    ScaleX = 5, ScaleY = 6, ScaleZ = 7,
    Mirror = 8,
    TranslateX = 9, TranslateY = 10, TranslateZ = 11,
    DensityKeep = 12,
    ClusterNoise = 13,
    CollisionPriority = 14,
    Tint = 15,
    AnimSample = 16,
    PathJitter = 17,
    MapJitter = 18,
    LODVariation = 19,
    UserReseed = 20
};

struct RngAddress {
    u64 objectSeed;
    u32 algoVersion;
    StableKey key;
    RngPurpose purpose;
    u32 lane;
};

struct Aabb3d { Vec3d lo, hi; };
struct Aabb2d { Vec2d lo, hi; };

struct RayHit {
    double t;
    u32 face;
    Vec3d bary;
    Vec3d position;
    Vec3f normal;
    Vec3f uvw;
    u16 matId;
    bool backFace;
};

struct SurfaceTriangle {
    Vec3f p0, p1, p2;
    Vec3f n0, n1, n2;
    Vec2f uv0, uv1, uv2;
    u16 matId;
    Aabb3f bounds;
};

struct BoundarySegment {
    Vec2d a, b;
    u32 loopIndex;
    u32 segmentIndex;
    u32 subSplineId;
    bool closed;
};

struct MapSamplerDesc {
    u32 width, height, channels;
    MapStorageType storage;
    MapFilter filter;
    MapTileMode tile;
    Aabb2d domain;
    u64 bakedVersion;
};

class MapSampler {
public:
    virtual ~MapSampler() = default;
    virtual MapSamplerDesc desc() const = 0;
    virtual Vec4f sample(Vec2d uv, MapFilter overrideFilter) const = 0;
};
}
```

`KeyParts` is packed into a fixed byte sequence before hashing. It is not serialized as a compiler-dependent C++ struct. The exact packing is: one byte `GenKind`, three zero bytes, four bytes `sourceId` little endian, four bytes `tileX` two's-complement little endian, four bytes `tileY`, four bytes `subX`, four bytes `subY`, and four bytes `layer`, for 28 bytes total. Signed coordinates are converted by their fixed-width two's-complement representation, not by a cast to an implementation-sized type. The object seed and algorithm version are separate 64-bit and 32-bit fields in the hash input. Saved version retains old paths, and explicit packing prevents ABI padding from changing identity.

### 4.2 SurfaceAccel

```cpp
struct SurfaceAccel {
    std::vector<SurfaceTriangle> triangles;
    std::vector<BvhNode3d> nodes;
    std::vector<u32> triIndices;
    std::unique_ptr<UvAccel> uv;
    Aabb3d bounds;
    u64 topologyVersion;
    u16 uvChannel;
    bool hasVertexNormals;
};
```

Triangle coordinates are stored in the immutable source surface's local space. S2 transforms a ray from FL to surface-local space using the snapshot transform, then transforms the hit position and normal back to FL. Storing local triangles permits sharing the same acceleration object among Cyrus objects with different Forest transforms.

### 4.3 Boundary2D and RasterMask

```cpp
struct Boundary2D {
    std::vector<BoundarySegment> segments;
    std::vector<BoundaryLoop> loops;
    SegmentIndex index;
    Aabb2d bounds;
};

struct RasterMask {
    u32 width, height;
    Aabb2d domain;
    BitGrid inside;
    std::vector<u8> coverage;
    u64 sourceVersion;
    float topLimit;
    float scale;
};
```

`BoundaryLoop` records `closed`, `subSplineId`, winding convention, and the segment range. Open loops are retained for distance and nearest-point queries but do not contribute to point-in-polygon inclusion unless a caller explicitly requests a closed-by-policy conversion.

### 4.4 Spatial hash and collision records

```cpp
struct SphereRecord {
    StableKey key;
    Vec3d center;
    double radius;
    u32 candidateIndex;
    i32 tileX, tileY;
};

struct SpatialHash {
    double cellSize;
    Aabb3d originBounds;
    std::vector<u32> offsets;
    std::vector<u32> members;
    std::unordered_map<Cell3, CellRange> sparse;
};

struct CollisionDecision {
    StableKey key;
    bool alive;
    StableKey blocker;
};
```

The published collision stage records only `F_CULL_COLLISION`, but diagnostics may retain the blocker key and separation distance in a non-hot side channel.

## 5. Algorithms

### 5.1 StableRNG and StableKey

#### Exact hash design

Use a four-lane counter-based hash based on SplitMix64 finalization. The primitive is the standard bijective 64-bit finalizer:

```cpp
static inline u64 mix64(u64 z) {
    z += 0x9E3779B97F4A7C15ull;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
    return z ^ (z >> 31);
}
```

The counter input is formed without undefined overflow, because unsigned arithmetic wraps by definition:

```cpp
u64 hash64(const RngAddress& a) {
    ByteArray b;
    appendLE64(b, a.objectSeed);
    appendLE32(b, a.algoVersion);
    appendLE64(b, a.key.v);
    appendLE16(b, static_cast<u16>(a.purpose));
    appendLE32(b, a.lane);

    u64 h = 0xD6E8FEB86659FD93ull;
    for (u64 word : padAndLoadLE64(b)) {
        h = mix64(h ^ word ^ 0xA0761D6478BD642Full);
    }
    return mix64(h ^ static_cast<u64>(b.size()) * 0xE7037ED1A0B428DBull);
}
```

For a family of values, lane 0, 1, and so on are separate counter values. Do not advance mutable generator state. A call is therefore a pure function of object seed, algorithm version, key, purpose, and lane. SplitMix64 finalization is chosen over a stateful PRNG because random values must be addressable in any order and independently reproducible across tiles and threads. A Philox-like counter PRF would also satisfy the property, but it costs more instructions and has no visible advantage for our scalar and SIMD lanes. This is not cryptography and must not be used for security.

The stable key is produced from packed KeyParts:

```cpp
StableKey makeKey(u64 objectSeed, u32 algoVersion,
                  const KeyParts& p, bool seedByForestXY,
                  Vec2d forestXY, double cellSize) {
    KeyParts q = p;
    if (seedByForestXY) {
        q.tileX = floorToI32(forestXY.x / cellSize);
        q.tileY = floorToI32(forestXY.y / cellSize);
    }
    ByteArray bytes = packKeyParts(q);
    u64 h = mix64(objectSeed ^ (u64(algoVersion) << 32));
    for (u64 word : padAndLoadLE64(bytes))
        h = mix64(h ^ word);
    return {mix64(h ^ 0x8CB92BA72F3D8DD7ull)};
}
```

The `sourceId` is the stable entry ID, not a UI list index. `layer` is normally zero and becomes the stacked-hit layer only when Randomize Stacked is enabled. A key never includes a worker index, cache address, face traversal order, or current time unless time is an authored component of the source identity. A map's time sample belongs in the map cache key and snapshot; it does not silently alter an otherwise identical candidate key.

#### Seed by Forest-local XY

The `seedByForestXY` option needs a precise definition because it changes stability under generator edits. When enabled, the key's `tileX` and `tileY` are the floor of Forest-local XY divided by the generator's stable lattice cell size. For lattice generation, this is exactly the lattice tile. For path and reference modes, source identity remains in `sourceId`, `subX`, and `subY`, while XY cell identity replaces the positional tile fields. The result is that a candidate stays associated with a spatial cell if nearby source ordering changes. It does not mean floating point XY values are hashed directly. Raw floating point hashing would make tiny transform changes create unrelated random values.

When disabled, key identity is based only on generator provenance. This is useful for source-indexed modes where the authored source ordering is intentionally the identity. The UI should warn that disabling XY seeding can alter random assignments after local source edits.

`Randomize Stacked` adds layer to identity only when enabled. Without it, multiple coplanar or stacked surface hits at one XY share the random stream and can intentionally receive the same transform. With it, each ordered hit receives a separate stream. Layer numbering is deterministic: sort accepted hits by `t`, then face index, then barycentric lexicographic order, and assign zero-based layer numbers.

#### Float conversion

For an unbiased, exact half-open conversion from `u64` to a binary32-friendly value, use the top 24 bits and multiply by `2^-24`:

```cpp
float unitFloat24(u64 x) {
    u32 mantissa = static_cast<u32>(x >> 40);
    return static_cast<float>(mantissa) * 0x1.0p-24f;
}
```

This returns exactly one of `2^24` representable values from 0 inclusive through the largest value below 1. It is appropriate for UI-scale random parameters and avoids `u64 / UINT64_MAX`, which can round to 1.0. For very subtle bias in a continuous double parameter, use the top 53 bits and `ldexp(double(x >> 11), -53)`, giving exactly `[0,1)` on the binary64 grid. Never use `std::uniform_real_distribution`, because its implementation is library-dependent and may change across standard libraries.

Integer selection uses rejection sampling when the range is not a power of two:

```cpp
u32 bounded(u32 n, const RngAddress& base) {
    if (n == 0) return 0;
    const u64 M = u64(1) << 32;
    const u64 limit = M - (M % n);
    for (u32 lane = 0;; ++lane) {
        u32 x = static_cast<u32>(hash64({base.objectSeed, base.algoVersion,
                                          base.key, base.purpose, lane}));
        if (u64(x) < limit) return x % n;
    }
}
```

The 32-bit rejection form avoids the inclusive `UINT64_MAX` corner case. It is also enough for geometry-list selection. For `n` near `2^32`, the rejection probability remains bounded and deterministic.

#### Purpose isolation

Each semantic random choice has its own `RngPurpose`. For example, changing rotation range must not alter model selection or collision priority. Use one purpose per component where a component may be edited independently: `RotX`, `RotY`, `RotZ`, and `ScaleX` through `ScaleZ` are separate. `ModelPick` consumes a lane per geometry-list entry or uses one weighted-selection draw. `DensityKeep` is the only stream used for probabilistic survival in S5. `CollisionPriority` is available for a deliberate authored priority variation, but the default collision ordering is the key itself and does not require a random draw.

### 5.2 SurfaceAccel

#### Building the mesh BVH

L3 converts a surface node into triangles and local-space metadata. Degenerate triangles with area below `areaEpsilon = max(1e-18, 1e-14 * extentSquared)` are retained in diagnostics but excluded from hit testing. Vertex normals are copied if available; otherwise the normalized face cross product is used. UVs are copied from the selected channel; missing UVs are marked invalid rather than invented.

Build a binary BVH using binned surface area heuristic (SAH):

1. Compute each triangle's bounds and centroid.
2. For a node with more than 8 triangles, evaluate each of three axes. Divide the centroid extent into 16 equal bins.
3. For each split between bins, compute prefix and suffix triangle counts and bounds. Cost is `leftArea * leftCount + rightArea * rightCount`.
4. Compare the best split against a leaf cost of `nodeArea * triangleCount`. Split only when the best cost improves the leaf by at least 1 percent or the leaf exceeds 64 triangles.
5. Partition by centroid and stable triangle index as the tie breaker. Recurse until a leaf is formed.

Use iterative arrays for nodes and a contiguous triangle index array. The stable tie breaker ensures equal-cost geometry builds the same tree regardless of sort implementation. SAH is preferred over a median split because terrain has long, uneven triangles and query cost matters in S2. Build complexity is `O(T log T)` in the common case and memory is `O(T)`.

#### Ray queries

For XY mode, convert the FL ray origin and direction into surface-local coordinates. Default ray direction is the transformed negative FL Z axis, with origin one `surfaceRayPadding` above the surface bounds and maximum distance extending padding below the bounds. Use watertight Moller-Trumbore style intersection, with dominant-axis shearing if available. Reject `t < -epsilon` and `t > maxT + epsilon`; clamp tiny negative `t` to zero.

`firstHit(ray, policy)` traverses the BVH with a min-t priority stack. On equal `t`, choose lower face index, then lexicographically smaller barycentrics. A front-face-only policy rejects intersections where `dot(faceNormal, ray.direction) >= 0` after a sign-consistent orientation check. The default double-sided policy accepts both faces, and `backFace` is recorded. If a mesh has inconsistent winding, double-sided still returns a normal whose orientation is chosen by interpolated normal and flipped against the ray only if the snapshot requests face-oriented normals. Do not silently flip normals for normal-mapped or vertex-normal surfaces.

`allHits` traverses all intersections in `[tMin,tMax]`, deduplicates hits within `tEpsilon = max(1e-9, 1e-8 * maxT)` by face and position, and sorts using `(t, face, bary.x, bary.y)`. It is needed by stacked surface handling and point-in-solid tests. S2 uses the first hit by default. If Randomize Stacked is off, multiple hits at nearly identical t are collapsed to the first deterministic hit.

Interpolate outputs as:

```cpp
position = b0*p0 + b1*p1 + b2*p2;
normal = normalize(b0*n0 + b1*n1 + b2*n2);
uv = b0*uv0 + b1*uv1 + b2*uv2;
matId = triangle.matId;
```

The face normal is retained as a fallback if interpolation has near-zero length. Barycentrics are normalized after intersection and clamped only within a small tolerance. UVs may be outside 0 to 1 because tiling is a map sampling policy, not a mesh query policy.

#### UV-space index

UV mode requires a second 2D BVH over UV triangles. Each node stores the axis-aligned UV bounds and references to the same source triangle IDs. A point location query collects candidate UV triangles whose bounds contain the map coordinate, then computes 2D barycentrics. Accept if all barycentrics are at least `-uvEpsilon`, with the same tie order by triangle index. If multiple triangles overlap in UV space, return the triangle with smallest absolute reconstruction error from the query point, then lowest face ID. If no UV triangle contains the point, return a miss and let the caller apply the configured UV hole policy, default reject.

A UV hit reconstructs surface-local position and normal with the 3D barycentrics. UV seams naturally produce multiple candidate triangles. The index is optional and built only if any consumer requests UV mode. It is invalidated by topology, selected UV channel, or source geometry changes.

#### Memory and lifecycle

A triangle with position, normal, UV, bounds, and material ID is approximately 96 to 112 bytes depending on alignment. A compact build can store positions and query attributes separately at approximately 80 bytes per triangle plus 32 to 48 bytes per triangle of BVH/index overhead. Report actual `sizeof` values in diagnostics rather than relying on this estimate. Rebuild on topology or vertex data changes. Refit only when topology and triangle membership are unchanged and all vertex positions move: update leaf bounds, then update internal bounds bottom-up. Refit preserves triangle order and is cheaper, but repeated large deformations degrade SAH quality. Rebuild after a refit when the root surface area ratio or sampled traversal cost exceeds 1.5 times the build baseline.

Sharing is through `SharedCacheRegistry`, keyed by source node identity, source geometry validity, topology version, selected UV channel, and relevant normal policy. The FL transform is not part of the `SurfaceAccel` key because geometry is stored in surface-local space. A surface object used by many Forest objects therefore has one shared local acceleration structure.

### 5.3 Boundary2D

#### Linearization

L3 samples spline shapes into immutable `PolyShapeData`: loops, open or closed state, sub-spline ID, vertex positions, and any source parameter needed for debugging. Boundary2D receives that plain data and transforms points into FL XY. It never calls Max spline methods.

A closed spline with fewer than three non-collinear points is retained for nearest-point and debug display but contributes no area. An open spline always contributes distance and nearest tangent; it contributes inclusion only in an explicit `OpenAsClosed` caller mode, which should not be used for ordinary area semantics. Duplicate consecutive points are removed if their squared distance is below epsilon. Collinear points may be retained to preserve sub-spline identity but are not needed by the kernel.

#### Point-in-polygon

Use the nonzero winding rule, evaluated with robust orientation predicates. For each closed loop, classify a point as on-boundary if the minimum segment distance is within epsilon. On-boundary returns inside for Include and outside for Exclude only after the caller applies its boundary policy. This keeps the geometric query unambiguous.

The winding increment for an upward crossing is +1 if `orient(a,b,p) > 0`, and a downward crossing is -1 if `orient(a,b,p) < 0`. Use a filtered predicate: compute the determinant in double, estimate an error bound, and fall back to a 128-bit integer or long double predicate when source coordinates are representable in fixed-point scale. The snapshot should preserve enough precision that a robust fallback is rarely needed. Holes are represented by opposite winding or by loop role supplied from the shape adapter. The Boundary2D result is the total nonzero winding, not an even-odd shortcut.

A point query first uses the segment index's loop bounds to skip distant loops. Complexity is `O(log S + K)` for an index query, where `S` is segment count and `K` is nearby candidate segments. A brute force debug path remains available for small shapes and golden tests.

#### Signed distance, nearest point, tangent

For the nearest boundary point, query the segment index, then project onto each candidate segment with clamped parameter `t`. Tie-break by squared distance, loop index, segment index, and parameter. Return position, tangent, loop and sub-spline IDs. For a zero-length segment, return its endpoint and use the nearest nonzero neighboring tangent, otherwise `(1,0)`.

Distance to an open loop is unsigned. For a closed loop, signed distance is negative inside and positive outside, with the sign based on winding. The magnitude is the exact nearest segment distance in double. `distanceSpline`, `nearestPosSpline`, and `nearestTangSpline` in Effects consume the same query, so they cannot each implement a different nearest-point tie rule.

A uniform segment grid is the default for large, bounded, mostly uniform shapes: choose cell width from `sqrt(area / segmentCount)` clamped to 16 times the median segment length. A compact BVH is preferable for highly clustered or very elongated boundaries. The index choice is recorded in diagnostics but not in results. Both indexes use the same sorted segment IDs and exact fallback.

#### Polygon operations

The minimum required operations are point classification, nearest distance, and clipping a candidate footprint against a boundary. Boolean union, intersection, and difference are optional in v1 because the ordered area program can evaluate loops without constructing a new polygon. Paint and contour workflows may request polygon union or offset; implement these through a robust integer-scaled clipping library behind an interface only after profiling. Never use an unvalidated floating point polygon boolean in the generation path. `[OPEN]` Validate edge cases against Forest Paint and Surface area scenes.

### 5.4 RasterMask

A RasterMask projects mesh triangles, or the published instances of another Cyrus object, along a selected axis into a 2D bit grid. The default resolution is 512 by 512, matching the requested service baseline and marked `[DESIGN]` because the public Forest reference does not specify this implementation value.

#### Domain and projection

The snapshot supplies a projection transform and domain. For a mesh, transform each vertex into mask-local coordinates. For an instance source, transform its source bounds or triangles by its item transform. Compute the XY domain from the source bounds, then expand by one pixel so conservative coverage does not clip a boundary. If the caller supplies a domain, preserve it and clip outside pixels.

Top Limit clipping is performed before rasterization. For a selected projection axis, clip every triangle against the half-space `axis <= topLimit` using Sutherland-Hodgman in double precision. Triangles wholly above the limit are discarded. A triangle crossing the limit is split, preserving conservative projected coverage.

#### Conservative rasterization

For each clipped triangle, convert vertices to pixel coordinates. Determine an integer box expanded by one pixel. For each pixel square in that box, test triangle versus square using the separating axis theorem. Mark the bit if they intersect or if the pixel center is inside. The one-pixel expansion and triangle-square test are conservative: no pixel whose square intersects the projected triangle is missed. For a source with an empty triangle set, the mask is all zero.

To support paint blending or debug, optionally retain an 8-bit coverage value. The semantic area mask uses one bit, not anti-aliased coverage. This prevents a thin edge from changing with SIMD or raster traversal order. If a caller specifically requests a soft map, coverage is accumulated by `max`, not floating point addition order.

Rasterization is parallel by coarse row blocks. Each row block has private bits and merges by bitwise OR in increasing block order, although OR is commutative and therefore insensitive to order. The source triangle iteration is sorted by stable source face ID.

#### Scale using Euclidean distance transform

`maskScale` changes the mask after binary rasterization. For positive scale, dilate inside pixels by Euclidean distance less than or equal to `scale / pixelSize`; for negative scale, erode inside pixels by the absolute distance. Use Felzenszwalb and Huttenlocher's exact separable squared-distance transform in two one-dimensional passes. First compute distance to the nearest feature along columns, then along rows. Use squared distances and compare against squared pixel radius. Distances are measured in physical domain units, using separate X and Y pixel sizes if the domain is non-square.

For a positive dilation, transform the complement and set pixels whose distance to inside is at most the radius. For erosion, transform inside and clear pixels whose distance to outside is less than the radius. A scale larger than the domain produces all inside for dilation or all outside for erosion. This operation is deterministic and `O(W H)`.

#### Sampling and memory

Nearest sampling maps a FL or UV point to the containing pixel and returns its bit. Bilinear sampling reads four scalar coverage values. For binary masks, nearest is the default; bilinear is useful for transform maps and returns a float in 0 to 1. Tiling applies after converting normalized coordinates to the map domain: Clamp clamps to the edge, Repeat wraps with a positive modulo, and Mirror reflects every other interval. Pixel centers are at `(x + 0.5) / width`.

A 512 by 512 bitmask is 32 KiB. A byte coverage plane is 256 KiB. At 8192 by 8192, these become 8 MiB and 64 MiB, before optional mip levels. The cache should store bit-only masks unless coverage or debug is requested. A mask is immutable and shareable for the same source version, projection, resolution, top limit, and transform.

### 5.5 SpatialHash and deterministic collision resolution

#### Hash grid

Collisions and Forest-area Sphere mode insert a sphere into every cell touched by its AABB. The cell coordinate is `floor((p - origin) / cellSize)`, with floor toward negative infinity, not truncation. Use 64-bit intermediate coordinates and reject or diagnose overflow beyond the configured supported world extent.

Choose automatic cell size as the median collision diameter sampled from live candidates, clamped to `[1e-6 * sceneExtent, sceneExtent / 16]`. If radii vary by more than 16 times, use the geometric mean of the 10th and 90th percentile diameters, and insert large spheres into a secondary large-object list when their AABB spans more than 64 cells. A caller-provided cell size is honored after clamping to positive finite values.

For deterministic parallel construction, each worker emits `(Cell3, candidateIndex)` pairs. Sort pairs by cell coordinate, then candidate stable key, then candidate index. Build CSR offsets. Query returns candidate IDs from intersecting cells, then the caller sorts and deduplicates IDs by stable key before exact sphere distance testing. This avoids unordered-map iteration affecting the broad phase.

#### Collision interface

The collision service has this core API:

```cpp
struct CollisionParams {
    bool enabled;
    double globalRadius;
    double collisionHeight;
    double epsilon;
    CollisionPriorityMode priority;
};

class CollisionResolver {
public:
    void resolve(const std::vector<SphereRecord>& spheres,
                 const CollisionParams& params,
                 const TileLayout& layout,
                 std::span<u8> alive,
                 std::span<CollisionDecision> diagnostics,
                 CancelToken& cancel);
};
```

S9 passes one sphere per live candidate after S7. The radius is the geometry-specific collision radius multiplied by global radius and by the maximum absolute horizontal scale unless the geometry table provides an explicit precomputed radius. The center includes the configured collision-height offset in item-local or normal-aligned coordinates, as defined by `06_DIVERSITY_COLLISIONS.md`.

#### Two-phase tiled algorithm

The required scheme is deterministic at any thread count and does not depend on where a tile border falls.

1. **Stable priority.** Define an ordering key for every sphere: `(priorityClass, stableKey.v, candidateIndex)`. The default priority class is zero for all spheres. `AreaOrder` and `XY` modes are optional alternatives, but all ties end with `stableKey.v` and candidate index. A lower tuple wins.
2. **Tile ownership.** Assign a sphere to the tile containing its center. A tile's halo width is the maximum collision radius in the evaluation, rounded up to cells. A tile reads all spheres whose AABBs intersect its core expanded by that halo.
3. **Local proposal phase.** Each tile processes its core-owned spheres in priority order. For a sphere, query the local spatial hash and test only higher-priority spheres already accepted in the local proposal set. If an overlap exists, mark the current sphere rejected and record the lowest-priority blocker. Otherwise accept it provisionally. Because all higher-priority neighbors within the halo are present, every conflict whose winner can affect the current core is visible.
4. **Border reconciliation.** A provisional decision is not final if a lower tile ID has not yet finalized a potentially higher-priority neighbor. Build a conflict edge list for every overlapping pair whose owners differ. Sort edges by `(winnerPriority, loserPriority, winnerKey, loserKey)` and process them globally in that order. A union of thread-local edge lists is made by concatenating then sorting, never by unordered iteration.
5. **Final deterministic scan.** Scan all spheres globally in priority order. A sphere is alive if every overlapping sphere with a lower priority is alive and no such sphere overlaps it. Since the scan is over stable sorted keys and the broad phase only supplies a sorted candidate set, this is exactly a deterministic greedy maximal independent set. The final scan can be tiled in chunks for parallelism by using prefix dependencies, but the reference implementation is serial and is used in tests.
6. **Publish.** Set `F_CULL_COLLISION` for rejected candidates and retain all other fields. No tile may publish its local decision directly to the population.

The final scan is the correctness barrier: acceptance is a pure function of sorted spheres and overlap relation. Tiles change only discovery. Local winners alone are insufficient because deleting a border winner can expose a second candidate. Candidate index is forbidden because tile generation can change it.

The expected broad-phase complexity is `O(N + P)` where `P` is candidate-cell pair count, plus exact overlap tests. Worst-case dense scenes can be quadratic; large-object lists and radius caps prevent pathological cell explosion, and the service reports pair counts.

### 5.6 MapSampler

MapSampler is an immutable view of an L3-baked grid. It supports mono maps as one channel and RGB maps as three channels, with an optional alpha channel represented as four channels. The core does not know `Texmap`, `ShadeContext`, material classes, or Max time types.

The sampling contract is:

```cpp
struct MapSampleRequest {
    Vec2d coordinate;
    MapFilter filter;
    MapTileMode tile;
};

struct MapGrid final : MapSampler {
    MapSamplerDesc metadata;
    std::shared_ptr<const std::byte[]> bytes;
    Vec4f sample(Vec2d c, MapFilter f) const override;
};
```

For lattice density masks, sample the nearest pixel by default. The candidate's lattice cell is an integer identity and should not receive a different density decision merely because a neighboring pixel's bilinear value changed. For transform maps, use bilinear filtering in normalized map space. A caller can explicitly override the filter for a diagnostic or special mode.

Coordinate handling is precise: apply domain normalization, then tile mode, then map pixel conversion. Clamp uses `x = min(max(x,0),1-epsilon)`. Repeat uses `x - floor(x)`. Mirror uses the fractional part of `x` in alternating unit intervals. Nearest chooses `floor(x * width)` after clamping; bilinear samples pixel centers at `(i + 0.5) / width` and blends four values in float. All four texels are fetched before blending, and missing channels are defined as zero for alpha or replicated mono for RGB only when the descriptor says so.

L3 bakes a Max Texmap on the main thread using the SDK's `ShadeContext` in `SCMODE_TEXMAP` mode, after verifying the exact constructor and setup against the installed SDK headers. The core must never construct a ShadeContext. The bake loop sets time, UV or FL coordinates, and map channel data in a main-thread-only batch. The result is quantized to UNorm8 for ordinary density/tint maps, Half or Float32 for transform maps requiring more precision, and stored in a `MapGrid`.

Resolution rules are deterministic. If the parameter is explicit, use it. Otherwise, derive dimensions from the map's source bitmap dimensions, clamped to a configured maximum. Procedural maps with no source dimensions use the object domain and the service default of 512 by 512. Non-square domains preserve aspect ratio by scaling the longer side to the requested maximum and rounding the other dimension with `ceil`, with a minimum of 16. Dimensions become part of the cache key.

Animated maps are baked for the requested evaluation time or requested motion samples. The map cache key includes texmap identity, map validity, time tick, resolution, channel, coordinate domain, renderer-independent bake mode, and `algoVersion`. For motion blur, bake each required sample time into a separate immutable grid or an array of grids with sample times. Never let worker threads call into Max to evaluate an animated map.

### 5.7 JobSystem and tiling

The JobSystem owns a fixed worker pool created at plugin startup or lazily on first evaluation. It provides `parallelForChunks`, `parallelForTiles`, task groups, and cancellation-aware waits. Worker count is fixed for an evaluation generation. Nested parallelism is disabled by default to prevent oversubscription.

A `TileLayout` divides FL XY by floor-based integer tile coordinates. The default is 64 by 64 scene units, adjusted only by explicit settings or a deterministic auto rule that chooses the smallest power-of-two size giving at least four tiles per worker across the larger scene dimension. Tile IDs are sorted lexicographically by `(tileY,tileX)` or by a documented Morton order; this specification uses lexicographic order for simple debugging.

Each tile owns chunked SoA buffers. A chunk contains no more than `renderChunkItems` candidates and stores keys and provenance first, then optional fields allocated when a stage needs them. Stages set flags and do not erase records. At the merge barrier, tile chunks are concatenated by tile ID and within a tile by StableKey, then assigned published positions. No worker appends into a global vector.

Stages with no cross-tile dependency run independently. Surface BVH and map lookups are read-only shared data. Boundary indexes are read-only. Collisions use the halo and final stable scan described above. A Forest mask that depends on another Cyrus population reads an immutable published version and is not built from partially completed tiles.

Cancellation uses a token containing `evalGeneration` and an atomic stop flag. Workers check at least once per chunk and after every cache build. The main thread increments generation before starting a replacement viewport evaluation. A completed result is published only if its generation still matches the requested generation. Render evaluation has a separate token and is not cancelled by viewport edits.

Render mode may stream: generate and process one bounded batch of tiles, resolve all stages that can be tile-local, retain collision halo records until the collision barrier, then compact and hand batches to the render adapter. Provenance fields can be released after their last consumer. The stream must preserve the same global tile and key order as a resident evaluation. A memory pressure failure returns a diagnostic and a controlled over-limit output, not a partial random population.

### 5.8 SharedCacheRegistry

`SharedCacheRegistry` is process-wide and stores immutable cache entries with typed keys. Required key shapes are:

```cpp
struct SurfaceCacheKey {
    NodeIdentity node;
    u64 geometryValidity;
    u64 topologyVersion;
    u16 uvChannel;
    u32 algoVersion;
};
struct BoundaryCacheKey {
    NodeIdentity node;
    u64 shapeVersion;
    u32 steps;
    Axis projection;
    TransformFingerprint flTransform;
    u32 algoVersion;
};
struct RasterCacheKey {
    SourceIdentity source;
    u64 sourceVersion;
    u32 width, height;
    double topLimit, scale;
    TransformFingerprint projection;
    u32 algoVersion;
};
struct MapCacheKey {
    TexmapIdentity map;
    u64 mapValidity;
    TimeValue time;
    u32 width, height, channel;
    DomainFingerprint domain;
    BakeMode mode;
    u32 algoVersion;
};
```

`NodeIdentity`, `TexmapIdentity`, and validity values are supplied by L3 as stable snapshot identifiers. A raw pointer is never a key by itself. A key includes every input that can change bytes, including algorithm version, selected UV channel, projection transform, and map time.

The registry stores a type-erased entry with byte size, strong payload pointer, last-use counter, and reference count. `getOrBuild` uses a concurrent map and per-key build gate so only one thread builds a miss. Other threads wait or receive cancellation. Only unreferenced entries enter the LRU list; eviction is locked, while payload destruction is outside the lock.

The default cap is 4 GiB. If an insertion exceeds the cap, evict least-recently-used unreferenced entries until the cap is met. If all entries are referenced, permit a temporary high-water mark up to 125 percent and report it. If allocation still fails, the caller may rebuild without caching, but must not change results.

Max notifications do not mutate cache entries. L3 translates a geometry, shape, texmap, node transform, or dependency notification into a bumped `validity` and a dirty bit. New keys naturally invalidate old entries. An explicit `invalidate(NodeIdentity)` removes matching unreferenced entries and marks referenced entries stale for diagnostic purposes. This avoids freeing an object while a worker is reading it.

Cache debugging records hit, miss, wait, build time, bytes, eviction, key hash, and dependency versions. The overlay can show a human-readable key summary without exposing pointers. A deterministic cache test clears the registry, builds, clears, and rebuilds, then compares semantic output hashes.

### 5.9 Math foundations

The core math library is a small, explicitly named set of POD types. `Vec2f`, `Vec3f`, `Vec4f`, `Quatf`, and their double precision counterparts provide component access, finite checks, dot, cross, length, normalized, clamp, lerp, and componentwise min/max. There is no implicit conversion from a Max `Point3`, `Matrix3`, or `Quat`; L3 performs explicit copies into core types.

Positions, bounds, ray parameters, barycentrics, distance calculations, BVH construction, and boundary predicates use double. Stored published item positions, normals, scales, and map samples use float unless a service explicitly promises double. The reason is precision where decisions occur and compact bandwidth where data is streamed. Conversion to float happens relative to the owning chunk origin:

```cpp
struct ChunkFrame {
    Vec3d origin;
    Vec3f toRelative(Vec3d p) const {
        return Vec3f(p - origin);
    }
    Vec3d toAbsolute(Vec3f p) const {
        return origin + Vec3d(p);
    }
};
```

Choose an origin as the exact double center of the tile bounds, rounded to a stable scene-unit grid. The grid is a function of tile coordinates and `tileSize`, not of candidate data. Store the origin with the chunk and use it in render transforms. A position outside the configured float error budget causes a diagnostic and may force a smaller tile.

Quaternions are stored normalized. Construct them from axis-angle or from a robust frame. For a surface normal `n`, select the basis axis with the smallest absolute component of `n`, cross it with `n`, normalize to obtain tangent `t`, then compute `b = cross(n,t)`. This avoids the near-parallel failure of always crossing with world Z. If a path tangent is available, project it onto the tangent plane, normalize, and use it when its length exceeds epsilon; otherwise use the robust arbitrary tangent. Ensure frame handedness by checking `dot(cross(t,b),n) > 0` and flipping `b` if required.

Use shortest-arc quaternion construction for aligning a source up vector to a normal. If vectors are nearly equal, return identity. If nearly opposite, rotate 180 degrees around the robust tangent axis. Normalize after multiplication and after interpolation. The transform stage defines multiplication order; the math library does not silently reorder quaternions.

For render streaming, pack a unit quaternion using smallest-three representation. Find the largest absolute component index `k`. Store `k` in two bits and store the signs of the omitted component by forcing the largest component positive before packing. Quantize the remaining three components from `[-1/sqrt(2), 1/sqrt(2)]` to signed 16-bit values. The packed form is 8 bytes: 2 bits index plus 3 times 16 bits, with the remaining two bits reserved and written zero. On unpack, reconstruct the omitted component as `sqrt(max(0, 1 - x*x - y*y - z*z))`, then normalize. If preserving the original largest-component sign is needed, encode it in one reserved bit and reduce the component quantizer only after measuring the error budget. The v1 form uses the positive-largest convention, which is valid because `q` and `-q` represent the same rotation.

The packing error is bounded by the quantizer step and should be measured as angular error against the float quaternion. Unit tests must cover each omitted component, zero rotations, 180 degree rotations, and values close to the sign boundary. Store unpacked `Quatf` in the canonical Population contract and use packed quaternions only in a render or cache buffer. This avoids making Effects and Custom Edit depend on a lossy representation.

Normalization returns a caller-supplied fallback for short or nonfinite vectors. Matrix inverse uses a scale-relative determinant threshold and reports failure. Intersections and distances receive explicit service tolerances rather than reading hidden globals.

## 6. Pipeline integration

The following table states service use in the architecture's stages:

| Stage | Services | Reads | Writes and flags | Determinism rule |
|---|---|---|---|---|
| S1 Generate | StableKey, StableRNG, JobSystem, MapSampler | `ScatterParams`, area data, map grids | key, provenance, XY position | Key from `KeyParts`; density uses `DensityKeep` only in S5. |
| S2 Surface resolve | SurfaceAccel, StableKey for stacked layer | surface cache, rays, UV map | pos, normal, uvw, matId, surfaceId, altitude | First hit or sorted stacked hits. |
| S3 Area program | Boundary2D, RasterMask, MapSampler | area loops, object/Forest masks | alive/filter flags, distances | Ordered area program, stable nearest ties. |
| S4 Falloff | Boundary2D, MapSampler | distances, curves | densityFactor, scaleFactor | Pure arithmetic and stable map sample. |
| S5 Density | StableRNG, MapSampler | densityFactor, maps | `F_CULL_DENSITY` | Compare `unitFloat24(hash(...DensityKeep...))` with threshold. |
| S6 Model | StableRNG | geometry probabilities, color map | geomId | Weighted selection with `ModelPick`, stable geometry entry IDs. |
| S7 Transform | StableRNG, MapSampler, math | normal, curves, maps | rot, scale, mirror, pos | Purpose-isolated streams. |
| S8 Boundary | Boundary2D, source bounds | footprint, scale | boundary and edge flags | Deterministic footprint sampling and nearest queries. |
| S9 Collisions | SpatialHash, CollisionResolver | final transforms, radii | `F_CULL_COLLISION` | Global stable priority finalization. |
| S10 Effects | math, MapSampler indirectly through pre-baked inputs | all fields | overrides and effect writes | Effects VM cannot call Max or mutate key. |
| S11 Shading | StableRNG, MapSampler | tint and animation maps | tintRGBA8, animSample | `Tint` and `AnimSample` purposes. |
| S12 Publish | JobSystem, math packing | live fields | immutable PublishedPopulation | Merge tile ID, then key. |
| V | Surface-independent camera data and JobSystem | published population | ViewMask only | Never changes canonical keys or alive flags. |

Changing cache memory or worker count does not dirty a stage semantically. Changing `algoVersion` dirties S1 through S12 because the key and potentially all service tolerances change. A surface geometry notification dirties S2 onward, while a map bake version dirties the consuming stage onward. The exact mapping belongs to the dirty table in `00` and `02`.

## 7. 3ds Max integration

The Max layer creates snapshot records on the main thread. For surfaces, it evaluates the node at time `t`, converts to a mesh representation using verified SDK APIs, copies vertices, faces, normals, UV channel data, material IDs, and validity versions, then releases the Max object before worker evaluation. The source notes recommend `INode::EvalWorldState` and conversion to `TriObject`; verify SDK ownership and deletion against installed headers. See Autodesk's [mesh extraction guidance](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/modeling/meshes/extracting_the_mesh_from_a_node.html).

For shapes, the adapter extracts splines into plain loops with sub-spline IDs, open or closed flags, and sampled positions. For Object and Forest areas, it supplies source triangle snapshots and transforms. For another Cyrus object, it requests the upstream immutable `PublishedPopulation` and source geometry metadata, then constructs a RasterMask key containing that upstream population version.

For maps, L3 owns all `Texmap` and `ShadeContext` interaction. It must guard evaluation with the main-thread policy and avoid calling the map from workers. A bake failure produces a constant fallback defined by the caller, normally zero for density and one for transform multipliers, and records a warning. The Max adapter also supplies time ticks and animated sample times as explicit key fields.

Notifications bump source validity and map to `DirtyBits`. A surface notification does not directly destroy a shared SurfaceAccel. It invalidates the key and requests a new snapshot. The registry may keep old entries alive until all evaluations release them. The UI's manual surface update action can force a validity bump; Auto rebuild performs that action when the dependency changes.

No service exposes Max classes in public headers. A narrow adapter may implement `IMapBaker`, `ISurfaceSnapshotProvider`, or `INodeIdentityProvider` in the Max layer, but it returns only core POD types and immutable shared buffers.

## 8. Edge cases and failure modes

* **Large coordinates:** use double for FL generation and local BVH builds. Store item positions as float relative to chunk origins. If a chunk origin cannot be represented safely, fail the chunk with a diagnostic instead of silently overflowing.
* **Negative coordinates:** all grid and tile calculations use mathematical floor. Test values exactly at negative integer boundaries.
* **NaN and infinity:** snapshot validation rejects nonfinite transforms, vertices, map values, radii, and bounds. A nonfinite map sample becomes the documented fallback and increments a counter.
* **Degenerate triangles:** skip for intersection, retain source face IDs for diagnostics. If all triangles are degenerate, SurfaceAccel is valid but returns no hits.
* **Coplanar rays:** treat coplanar triangle hits as misses by default to avoid duplicate surfaces. A caller can request interval hits only through a versioned future policy.
* **T-junctions and stacked hits:** sort by t, face ID, and barycentrics. Apply layer numbering only after deduplication.
* **UV seams and overlaps:** search all overlapping UV candidates and tie-break by reconstruction error and face ID. Missing UVs cause a miss, not a fabricated `(0,0)`.
* **Open boundaries:** no inside classification, but distance and tangent remain available. Effects using nearest tangent can therefore work on open splines.
* **Self-intersecting loops:** nonzero winding is used. Warn in debug overlays because the result can differ from an artist's even-odd expectation.
* **Zero-length boundary segments:** omit from index but preserve sub-spline metadata. Tangent falls back to neighboring nonzero segments.
* **Thin raster features:** conservative triangle-square intersection and one-pixel domain expansion prevent disappearing narrow geometry. Small features can still be lost if the entire source is narrower than one pixel; expose resolution and report it.
* **Top Limit at a vertex:** use a tolerance around the clipping plane and a deterministic inside convention. Test triangles exactly touching the limit.
* **Mask scale beyond bounds:** saturate to all inside or all outside as described, never allocate a larger image.
* **Hash collisions:** StableKey is 64-bit. A collision is extraordinarily unlikely but possible. In debug builds, detect duplicate keys with distinct packed KeyParts within one population and report. Do not use pointer addresses to disambiguate in release because that breaks reproducibility. `[OPEN]` Consider a 128-bit key in a future file version if collision evidence appears.
* **Weighted model probabilities:** negative probabilities clamp to zero with a warning. If total weight is zero, use the first enabled geometry entry by stable entry ID, or mark the candidate as no geometry if none is enabled.
* **Collision radius zero:** the sphere is a point. It collides only when centers are within epsilon. Negative radii are invalid and clamp to zero.
* **Collision chains:** only the globally stable priority scan determines winners. Never resolve only the first pair returned from a hash cell.
* **Cancellation:** a cancelled build may leave temporary cache entries, but never publishes a partial population. Cache build gates release waiters with cancellation status.
* **Memory pressure:** release coverage, provenance, and debug side channels at their last consumer. If a resident population exceeds the render cap, use streaming or the configured hard warning. Do not randomly subsample after S9.
* **Cache invalidation races:** old immutable entries remain safe under shared ownership. A stale entry can be used only by an evaluation whose snapshot key references it. New evaluations use bumped keys.
* **Different CPU architectures:** Stable hash and packed serialization use explicit little-endian operations. Floating results are required to be deterministic within the supported IEEE 754 build configuration. If cross-architecture bit identity is required, add a strict math mode using controlled FMA settings and compare golden hashes.

## 9. Performance and memory targets

These are Cyrus targets, marked `[DESIGN]`, not Forest claims.

* StableRNG: at least 300 million `hash64` calls per second per modern core in a microbenchmark, with no allocations.
* SurfaceAccel: build one million triangles in under 1.5 seconds on 16 cores when the source is already in core arrays. A first-hit query should average under 100 node visits on a terrain-like mesh.
* Boundary2D: build and query one million segments in under 2 seconds on 16 cores; nearest queries should remain under 2 microseconds on a typical 100k-segment boundary after warm cache.
* RasterMask: conservative 512 by 512 bake under 10 ms for a 100k-triangle source after transforms are available. Distance transform under 2 ms at 512 squared.
* SpatialHash: insert and query one million spheres in under 250 ms on 16 cores for a well-behaved radius distribution. Report pair count and cell occupancy percentiles.
* Collision: resolve one million candidates with moderate density in under 1 second on 16 cores including broad phase. The serial correctness scan may dominate dense scenes; optimize only after proving equivalence to the reference.
* MapSampler: a cached nearest sample should be a few dozen instructions and no allocation. Bilinear sampling must be vectorizable over a tile.
* JobSystem: scheduling overhead should be below 1 percent of a 64k-item chunked stage.

Memory targets follow the architecture's estimate of approximately 58 bytes per hot output item, excluding temporary provenance. `SurfaceAccel` should stay below 160 bytes per source triangle including nodes for ordinary meshes. A 512 by 512 bit RasterMask is 32 KiB; MapGrid storage is `width * height * channels * bytesPerChannel` plus a small descriptor. Collision CSR memory is `8 * pairCount` bytes approximately, plus cells and records.

Avoid one object or full mesh per candidate, unordered-map iteration in result paths, and retaining arrays after their last stage. The harness compares published hashes at one and many worker counts as well as timing.

## 10. Tests

### 10.1 Unit tests

1. **Packing:** known `KeyParts` byte vectors, including negative tile coordinates, match golden hex.
2. **Hash vectors:** known `(seed, version, key, purpose, lane)` tuples match fixed 64-bit outputs.
3. **Purpose isolation:** changing `RotX` parameters or lane does not alter `ModelPick` output.
4. **Float conversion:** all sampled values are `< 1.0`; zero and maximum mantissa map to exact expected floats.
5. **Stable merge:** randomized task completion order produces the same tile/key order and hash.
6. **Surface intersections:** triangles, back faces, shared edges, degenerate faces, equal t, and transformed rays.
7. **UV point location:** seams, overlaps, holes, wrap values, and barycentric interpolation.
8. **Boundary:** clockwise and counterclockwise loops, holes, self-intersections, open loops, on-edge points, negative coordinates, and nearest ties.
9. **Raster:** a single triangle, thin diagonal, top clipping, empty source, domain edges, repeat/mirror tiling, and dilation/erosion against a brute-force distance result.
10. **Spatial hash:** negative cells, large spheres, duplicate cell memberships, sorted query candidates, and radius boundaries.
11. **Collision reference:** compare tiled proposal plus final scan with a simple serial all-pairs greedy algorithm for small random scenes.
12. **MapSampler:** nearest, bilinear, mono and RGB, clamp/repeat/mirror, edge pixels, and animated key separation.
13. **Cache:** concurrent `getOrBuild`, ref counts, cap eviction, invalidation during use, and rebuild equivalence.
14. **Cancellation:** no partial publication and no leaked build gate.

### 10.2 Golden and integration tests

Record immutable snapshots and compare:

* S1 keys and XY positions for lattice, path, reference, and particle inputs.
* S2 hit face, barycentrics, normal, UV, and stacked layer numbering.
* S3 boundary distances and area flags for Include, Exclude, Surface, Object, and Forest masks.
* S5 survival masks at several seeds and density values.
* S7 transform fields and purpose-specific random values.
* S9 collision flags and blocker keys.
* S12 packed quaternion and final population hash.

Every golden test runs at worker counts 1, 2, 7, and hardware concurrency. It also runs with cache cold and warm. A changed golden result requires an `algoVersion` increment and migration note.

### 10.3 Forest Lite comparison scenes

Use the documented Forest Lite and Pro references as behavioral test inputs, but mark exact internals unknown:

* A flat plane with Image distribution and a density map tests XY candidate identity, nearest density map sampling, and Max Items approximation. See [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode).
* A UV sphere tests UV point location, UV holes, and transform map coordinates. See [Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).
* Open and closed splines test nearest tangent, Include and Exclude, and boundary Point versus Size. See [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas).
* A two-object Forest area tests RasterMask projection and upstream population versioning. See [ForestSet](https://docs.itoosoft.com/forestpack/forestset-plugin).
* Uneven terrain with stacked surfaces tests first hit and Randomize Stacked.
* A grid of different-size spheres tests collision priority, collision radius, and collision height. Record only observable survivors because Forest's private order is not published.
* An animated procedural map tests main-thread baking and time-key invalidation.

Compare positions, available keys, cull counts, and viewport versus render differences. These tests do not claim bit-for-bit Forest compatibility.

## 11. Open questions

1. `[OPEN]` Verify with Forest Lite whether multiple stacked surface hits share random transforms by default and exactly what Randomize Stacked changes.
2. `[OPEN]` Measure Forest's effective boundary tolerance on points exactly on a spline and at very large scene units.
3. `[OPEN]` Determine whether Object and Forest area masks use conservative rasterization or a supersampled coverage threshold. Cyrus uses conservative binary coverage unless testing shows a required compatibility mode.
4. `[OPEN]` Compare Forest collision winners on three-way chains and equal-priority candidates. Cyrus's stable-key greedy priority is deterministic but is not claimed to be Forest's private algorithm.
5. `[OPEN]` Verify how Forest handles UV-overlap ambiguity and missing UVs.
6. `[OPEN]` Determine whether density maps use nearest, bilinear, or mode-specific filtering in each Forest distribution mode. Cyrus makes lattice nearest and transform bilinear explicit.
7. `[OPEN]` Confirm which Max SDK APIs and `ShadeContext` initialization sequence are valid for the supported Max versions. Do not invent class or method names in the adapter.
8. `[OPEN]` Profile refit quality thresholds on animated surfaces and establish a rebuild policy based on measured traversal cost.
9. `[OPEN]` Decide whether a future 128-bit StableKey is warranted for extremely large populations. The v1 contract remains 64-bit and detects duplicate packed identities in debug builds.
10. `[OPEN]` Test cross-platform bit identity under MSVC and Clang, especially fused multiply-add and long double behavior in robust predicates.
11. `[OPEN]` Determine whether polygon boolean operations are needed for v1 Paint and contour workflows. Keep them behind an optional service until the relevant scenes are collected.
12. `[OPEN]` Validate whether SurfaceAccel can be shared across different normal-generation policies or whether normal policy must become a cache-key field in every renderer.

## 12. Architecture feedback

`00_ARCHITECTURE.md` is internally consistent for these services. Two clarifications would reduce implementation ambiguity:

1. The `KeyParts` comment says `sourceId` is an area, path, reference, PFlow, or manual ID, while `00` also says area identity is an immutable entry ID. Add a sentence that the ID is the authored stable entry ID in all modes, not a UI position.
2. The architecture's memory estimate says a packed rotation can be 8 bytes. Add the smallest-three quaternion format and its error tolerance to the shared math contract so S12 and render adapters do not choose incompatible packing.
3. The collision note in `00` says two-phase tiled resolution. This file makes the required final stable priority scan explicit. Add that a local tile result is provisional and cannot be published until border reconciliation or the global reference scan completes.
4. The architecture says SurfaceAccel is keyed by node handle, geometry validity, topology version, and UV channel. Add the normal-generation policy and `algoVersion` if either can change stored query results.

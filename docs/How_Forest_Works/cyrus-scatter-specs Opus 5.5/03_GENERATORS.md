# 03: Generators

## 1. Purpose and scope

This specification defines candidate generation for S1 and the density part of S5. It covers Image mode, which is a tiled pixel lattice, plus Path, Reference, Particle Flow, and Manual sources. It also specifies our distribution-map library, map coordinate rules, deterministic keys, candidate-count estimation, and the interfaces consumed by S2 through S5.

S1 creates candidates, not final instances. It writes the provenance and initial Forest-local position into `Population`; S2 resolves surfaces; S3 applies the ordered area program; S4 calculates falloff; and S5 performs density thinning. This separation is important: a density edit must remove candidates without moving survivors, while a surface or transform edit must not silently reseed the map.

The implementation extends, rather than replaces, 00_ARCHITECTURE.md. The core remains free of Max headers. Max-specific nodes, maps, particle interfaces, and parameter blocks are converted by S0 into immutable snapshot records. All positions generated here use double precision in Forest-local coordinates and are stored as float only when written to the SoA, following 00 section 3.

### 1.1 Behavior evidence and replication posture

[FP-DOC] Forest documents Image, Path, Reference, and PFlow as distribution modes. Image creates a potential location for every image pixel, and white or threshold-passing pixels create items. A density-map option interprets gray as a probability. Path places items at intervals or vertices, Reference supports pivots and mesh faces, and PFlow follows particles. See [Distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution), [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode), [Path Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode), and [Reference Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode).

[FP-DOC] Image controls include X and Y Units, procedural X and Y Pixels, Offset, Rotation, Lock Aspect Ratio, Fit to Scene with Pick Start and Pick End, Threshold, Use as Density Map, and Max Density. Max Density defaults to 10 million and counts black pixels as well as white pixels. See the [Distribution Maps tutorial](https://www.itoosoft.com/tutorials/back-to-basics-distribution-maps).

[FP-OBS] Tutorials use names such as Full, Dense, Spread, Grid, and Diagonal. The exact installed list is version dependent. We therefore reproduce the behavior with an owned, versioned map library instead of pretending that a Forest filename is an algorithm.

[DESIGN] A candidate has one permanent identity derived from `KeyParts`. Candidate acceptance is a pure comparison between a stable hash score and a density value. This gives monotone density: reducing density can only remove existing items, and raising it can only add them at their already defined keys.

## 2. Parameters

The names below are authored names. `D_DISTRIBUTION` means a new S1/S5 checkpoint is needed. `D_AREA_GEOM(areaId)` is the area dirty group from 00. `D_TIME` is required for animated maps and particles. A percentage is stored as 0 to 1 in core and shown as percent in the UI.

| UI name | Internal name | Type | Default | Range and units | Rollout | DirtyBits group | Notes |
|---|---|---|---|---|---|---|---|
| Distribution mode | `distribution.mode` | enum | Image | Image, Path, Reference, Particle | Distribution | `D_DISTRIBUTION` | Selects one generator program. |
| Distribution map | `image.map` | MapRef or BuiltinMapId | Full | map or built-in | Image | `D_DIST_MAP` | Bitmap, Max map, or shipped procedural map. |
| X Units | `image.unitsX` | double | 100.0 | greater than 0 system units | Image | `D_DIST_MAP` | Width of one repeated map tile. |
| Y Units | `image.unitsY` | double | 100.0 | greater than 0 system units | Image | `D_DIST_MAP` | Height of one map tile. Ignored for Lock Aspect. |
| X Pixels | `image.pixelsX` | u32 | 100 | 1 to 16384 | Image | `D_DIST_MAP` | Procedural map resolution. Bitmap resolution wins. |
| Y Pixels | `image.pixelsY` | u32 | 100 | 1 to 16384 | Image | `D_DIST_MAP` | Procedural map resolution. |
| Threshold | `image.threshold` | float | 0.50 | 0 to 1 | Image | `D_DIST_MAP` | Binary mode keeps samples at or above threshold. |
| Use as Density Map | `image.useDensityMap` | bool | false | on or off | Image | `D_DIST_MAP` | Gray value becomes keep probability. |
| Offset X, Y | `image.offset` | Vec2d | (0, 0) | system units | Image | `D_DIST_MAP` | Applied before rotation in map coordinates. |
| Rotation | `image.rotation` | double | 0 degrees | -180 to 180 degrees | Image | `D_DIST_MAP` | Rotation about map origin. |
| Lock Aspect Ratio | `image.lockAspect` | bool | false | on or off | Image | `D_DIST_MAP` | Uses X Units for Y tile size. |
| Fit to Scene | `image.fit.enabled` | bool | false | on or off | Image | `D_DIST_MAP` | Replaces authored tile frame with picked corners. |
| Pick Start, Pick End | `image.fit.start/end` | Vec2d | unset | FL XY | Image | `D_DIST_MAP` | Opposite corners of a fitted tile frame. |
| Max Density | `image.maxDensity` | u64 | 10000000 | 0 to 2^63 minus 1 | Image | `D_DIST_MAP` | Zero means unlimited, subject to memory and render caps. Counts black positions. |
| Map channel | `image.channel` | enum | Luminance | RGB, alpha, luminance, named scalar | Image | `D_DIST_MAP` | Baked by S0 into MapSampler. |
| Jitter within cell | `image.jitter` | float | 0.0 | 0 to 0.5 cell | Image | `D_DIST_MAP` | [DESIGN] Deterministic sub-pixel jitter. Zero preserves exact grid. |
| Surface coordinate rule | `image.surfaceRule` | enum | XY | XY, UV, Builtin, Map | Image | `D_DIST_MAP` | Described in section 4. |
| Density multiplier | `image.densityMultiplier` | float | 1.0 | 0 to 1 | Image | `D_DIST_MAP` | Includes viewport budget factor from 00 section 7.4. |
| Paths | `path.sources` | NodeRef list | empty | splines | Path | `D_AREA_GEOM` or `D_DISTRIBUTION` | Each spline gets stable source identity. |
| Spacing | `path.spacing` | double | 100.0 | greater than 0 system units | Path | `D_DISTRIBUTION` | Used with arc-length table. |
| In Vertex Positions | `path.vertices` | bool | false | on or off | Path | `D_DISTRIBUTION` | One candidate at each usable vertex. |
| Spline Offset | `path.offset` | double | 0.0 | system units | Path | `D_DISTRIBUTION` | Signed local planar normal. |
| Random Position | `path.randomPosition` | float | 0.0 | 0 to 1 of interval | Path | `D_DISTRIBUTION` | Stable offset inside each interval. |
| Follow Path X, Z | `path.followX/Z` | bool | false | on or off | Path | `D_DISTRIBUTION` | Writes frame hints consumed by S7. |
| Path Geom ID | `path.geomMode` | enum | Random | Random, Sequence | Path | `D_GEOM_LIST` or `D_DISTRIBUTION` | Selection policy is consumed again by S6. |
| Reference mode | `reference.mode` | enum | Pivot | Pivot, Faces | Reference | `D_DISTRIBUTION` | Dynamic source node link. |
| Items per face | `reference.itemsPerFace` | u32 | 1 | 1 to 4096 | Reference | `D_DISTRIBUTION` | Triangular lattice or randomized barycentrics. |
| Randomize Position | `reference.randomize` | bool | false | on or off | Reference | `D_DISTRIBUTION` | Stable per face/sample. |
| Material ID | `reference.materialId` | i32 | any | any or specific ID | Reference | `D_DISTRIBUTION` | Filters faces before candidate creation. |
| Align and Scale | `reference.align/scale` | bool | false | on or off | Reference | `D_DISTRIBUTION` | Copies source pivot orientation and scale. |
| Match Geometry by Name | `reference.matchName` | bool | false | on or off | Reference | `D_GEOM_LIST` | Regex is a separate toggle. |
| Regular Expression | `reference.regex` | bool | false | on or off | Reference | `D_GEOM_LIST` | Verify against standard ECMAScript regex. |
| Particle source | `particle.source` | NodeRef | unset | PFlow node | Particle | `D_TIME` or source version | Snapshot particle channels in S0. |
| Particle event filter | `particle.events` | set | all | event IDs | Particle | `D_TIME` | All events or selected events. |
| Match particle alignment | `particle.align` | bool | false | on or off | Particle | `D_DISTRIBUTION` | Uses particle rotation. |
| Match particle scale | `particle.scale` | bool | false | on or off | Particle | `D_DISTRIBUTION` | Uses particle scale. |

Per-area overrides extend 00's area program record: `mapScale`, `threshold`, `alternateMap`, and optional `surfaceRule`. A Threshold-only or same-geometry map override does not change candidate identity; it changes survival of candidates owned by that area. An override that changes lattice geometry (map Scale, different map resolution) creates a separate distribution frame keyed by the area's entryId (00 D1). This preserves stable keys while allowing different areas to use different image patterns.

## 3. Data structures

The following types extend 00 sections 4, 7, and 10. Names are illustrative C++20 core names. They contain no `INode`, `Texmap`, `Point3`, or other Max type.

```cpp
struct ImageFrame {
    Vec2d origin;                 // FL XY tile origin after offset
    Vec2d axisX, axisY;           // unit axes after rotation
    double sizeX, sizeY;          // Units, or fitted extents
    u32 pixelsX, pixelsY;
};

enum class SurfaceRule : u8 { XY, UV, Builtin, Map };
struct DistributionMapSpec {
    MapId map;
    u32 mapVersion;
    u32 pixelsX, pixelsY;
    double unitsX, unitsY;
    float threshold;
    bool densityMap;
    bool lockAspect;
    SurfaceRule surfaceRule;
    Channel channel;
    float jitter;
    ImageFrame frame;
};

struct AreaDistributionOverride {
    bool enabled;
    float scale;
    std::optional<float> threshold;
    std::optional<MapId> map;
    std::optional<SurfaceRule> surfaceRule;
};

struct CandidateProvenance {
    GenKind kind;
    u32 sourceId;
    KeyParts keyParts;
    Vec2d baseXY;
    Vec2d cellJitter;
    float mapValue;
    u32 particleIndex;
    u32 faceIndex;
    u32 sampleIndex;
    Quatd sourceRotation;
    Vec3d sourceScale;
    Vec3d pathTangent;
    float pathS;
};

struct ParticleSnapshot {
    u32 stableParticleId;
    Vec3d positionFL;
    Quatd rotation;
    Vec3d scale;
    Vec3d velocity;
    i32 ageTicks;
    float speed;
    i32 eventId;
    bool alive;
};

struct PathTable {
    std::vector<double> s;       // cumulative arc length
    std::vector<Vec3d> p;
    std::vector<Vec3d> tangent;
    double length;
};
```

The existing `Population` receives `pathPos`, `pixelX`, `pixelY`, `tileX`, `tileY`, `areaIndex`, and `key`. Add a sidecar `CandidateExtras` checkpoint until S7, because particle values and path frames are not in 00's hot output. At S6, path and reference source fields are mapped into the normal transform inputs. At S10, particle attributes are read-only expression inputs.

### 3.1 StableKey construction

The key is a versioned hash of a canonical byte encoding. Do not serialize a C++ struct directly because padding and endianness would be hazards.

```cpp
// Canonical encoder lives in 01 section 5.1; shown here for the generator's view.
// For Lattice keys, p.sourceId = frameId (0 = global frame, else the overriding area's entryId; 00 D1).
StableKey makeKey(const ObjectId object, const KeyParts& p, const u32 algoVersion) {
    ByteWriter w;
    w.u32(algoVersion);
    w.u64(object.value);
    w.u8(static_cast<u8>(p.kind));
    w.u32(p.sourceId);
    w.i32(p.tileX); w.i32(p.tileY);
    w.u32(p.subX); w.u32(p.subY); w.u32(p.layer);
    return StableKey{sipHashLike64(w.bytes(), kCyrusKeySeed)};
}
```

`frameId` identifies the **distribution frame**, not the Include area (see 00 decision D1). Frame 0 is the object's global distribution map. An Include area that overrides the distribution map with a different map, Scale or frame gets its own frame, whose id is that area's immutable entryId (00 section 6). For Image candidates, `sourceId` holds the frameId (0 for the global frame), tile coordinates are signed floor indices, `subX/subY` are pixel coordinates, and `layer` is a stacked surface layer. Consequence: moving, reshaping or reordering an Include spline never re-seeds the candidates it still covers, which matches Forest's "seed from XY position" behavior [FP-DOC]. If a single area changes only Threshold or alternate map contents while keeping the same lattice geometry, the key does not change: changing a map adds or removes positions instead of reseeding them.

Path keys use path entry ID as source, segment index as `tileX`, sample number as `subX`, and spline sub-ID in `layer`. Reference keys use node ID as source, face index in `tileX`, and face sample in `subX`. Particle keys use PFlow node ID as source, stable particle ID as `subX`, and event ID or stream layer in `layer`. Never use the array position alone because particle order and Max evaluation order may change.

RNG values use `hash(key, purpose, optionalCounter)`, never a mutable stream. Purpose constants include `Jitter`, `PathRandomPosition`, `ReferenceBarycentric`, `Density`, `ModelSelection`, `Cluster`, and `CollisionPriority`. A purpose change is an algorithm change and bumps `algoVersion`.

## 4. Image mode lattice

### 4.1 Coordinate model

Image mode is a Cartesian pixel lattice. A map tile has real dimensions `sizeX` by `sizeY` and `pixelsX` by `pixelsY`. Pixel center `(i,j)` maps to local tile coordinates:

```text
q = ((i + 0.5) / pixelsX - 0.5, (j + 0.5) / pixelsY - 0.5)
local = (q.x * sizeX, q.y * sizeY)
worldXY = frame.origin + frame.axisX * local.x + frame.axisY * local.y
```

The origin convention is tile center, which makes rotation and fitting symmetric. The UI can display a corner gizmo without changing this internal convention. Offset is applied in the frame's unrotated map units, then rotation constructs `axisX` and `axisY`. A compatibility toggle can use corner-origin sampling for old scenes, but it must be part of `algoVersion`.

[FP-DOC] X and Y Units are the size of a repeated tile. X and Y Pixels control procedural maps, while a bitmap's native dimensions control its source pattern. Smaller Units create more pixels per scene area. The map is tiled in both directions. A bitmap with `W x H` source samples always contributes one candidate position per source pixel per tile, including black pixels.

Lock Aspect sets `sizeY = sizeX * pixelsY / pixelsX` for a procedural map, or uses the source bitmap aspect ratio when the map is a bitmap. It does not change pixel count. Fit to Scene replaces the tile origin and axes with a rectangle between Pick Start and Pick End. If both points are equal or non-finite, fitting is rejected with a UI warning and the authored Units remain active.

### 4.2 Map evaluation and threshold

S0 turns a Max bitmap or map into an immutable `MapSampler`. For built-in procedural maps, the core can evaluate a scalar sample directly. For arbitrary Max maps, L3 bakes a fixed-resolution grid with the requested channel, time, and UV conventions. The key is `(texmap, time, resolution, channel)` as required by 00's `MapGrid` cache. S1 only samples the immutable object, so worker threads never call Max.

Binary mode keeps a candidate when `mapValue >= threshold`. The comparison is intentionally inclusive at the threshold. It is useful for a threshold of 0: all cells should be candidates, including exact black. A threshold of 1 keeps exact white only. Empty or failed maps fall back to a black sampler and produce no candidates, with a diagnostic, unless the authored map is the `Full` built-in.

Density mode keeps a candidate using a stable hash. Let `g` be the clamped grayscale channel and `d` be the product of the area scale, global density multiplier, and S4 density factor. The base map probability is `g`, while Threshold is a lower acceptance gate:

```cpp
float p = clamp01(g * d);
if (g < threshold) reject(F_CULL_DENSITY);
float score = stable01(key, Purpose::Density);
if (score >= p) reject(F_CULL_DENSITY);
```

The UI can expose Threshold as a density floor. If `densityMap` is on and Threshold is zero, black pixels are still evaluated and simply have zero probability. If map value is exactly one, hash scores in `[0,1)` always pass provided `d` is one. This is monotone in every density multiplier. For binary mode, S5 may still apply `densityFactor` using the same hash, so falloff is monotone too.

[DESIGN] Density thinning belongs in S5, not S1, even though the map value is sampled here. S1 emits every map position up to the safety cap and records `mapValue`; S5 applies the combined area and map probability. This keeps area falloff, viewport budget, and map density in one deterministic thinning stage. The exception is a hard binary threshold: positions below Threshold can be flagged immediately to avoid carrying them through S2 when profiling says it matters. The candidate estimate always counts them before rejection.

### 4.3 Sub-pixel jitter

[DESIGN] Jitter is a displacement inside the pixel cell, not a second random candidate. With normalized jitter `j` in `[0, 0.5]`, generate two independent stable values in `[-1,1]` and add:

```text
local.x += hashSigned(key, JitterX) * j * sizeX / pixelsX
local.y += hashSigned(key, JitterY) * j * sizeY / pixelsY
```

The map sample remains at the unjittered pixel center. This preserves the map's intended pixel classification while preventing a `Full` map from looking like a mathematically perfect grid. At `j=0`, locations are exact centers. At `j=0.5`, a point can move to a cell boundary, but never more than half a cell from center. Use a deterministic hash rather than thread-local randomness so a viewport rebuild and a render rebuild agree.

[FP-OBS] Forest's Full distribution often appears less rigid than an exact grid, but public material does not establish whether that comes from hidden jitter, transforms, surface projection, or a display representation. We do not claim to know its private cause. Our explicit jitter is preferable because it is inspectable, reproducible, and optional. A golden scene should compare `j=0` for lattice compatibility and a separate scene should assert the naturalized appearance at `j>0`.

### 4.4 Efficient overlapping-tile enumeration

Do not scan every possible tile in an unbounded scene. Convert the area's FL bounds into lattice coordinates. For a rotated frame, transform all four area-bound corners by the inverse frame rotation and compute a conservative axis-aligned rectangle. Expand it by one pixel cell for floating point safety. Then enumerate integer tile ranges:

```cpp
TileRange overlap(const Aabb2d& area, const ImageFrame& f) {
    Aabb2d q = inverseTransformBounds(area, f);
    double hx = f.sizeX * 0.5;
    double hy = f.sizeY * 0.5;
    i32 tx0 = floorDiv(q.min.x - hx, f.sizeX);
    i32 tx1 = floorDiv(q.max.x + hx, f.sizeX);
    i32 ty0 = floorDiv(q.min.y - hy, f.sizeY);
    i32 ty1 = floorDiv(q.max.y + hy, f.sizeY);
    return {tx0, tx1, ty0, ty1};
}
```

For each tile, transform its four corners back to FL and intersect its AABB with the area bound. A cheap tile-level reject comes first. Exact Include membership belongs to S3, so S1 uses the area's broad bound and does not invoke Max spline tests. A map tile that overlaps a rotated rectangular bound can generate a few corner candidates outside the area; those are harmless and are removed by S3. For very thin or concave areas, use an optional rasterized area mask to reduce work, but retain exact S3 semantics.

Use signed floor division, not truncation, for negative coordinates. Tile iteration order is `(tileY, tileX)` ascending; candidate merge order is tile index then key. The order does not affect output but makes diagnostics stable.

The tile work unit should be bounded by both spatial tile and map tile. The global job tiler from 00 may use 64 by 64 meters, while Image S1 uses map tiles as an inner loop. A worker receives a list of map tile indices that intersect its job tile. It writes a private append buffer, then the coordinator sorts or merges by `(tileY, tileX, pixelY, pixelX, layer)`.

### 4.5 Surface coordinate rules: XY, UV, Builtin, and Map

The four rules are not interchangeable labels. They describe which coordinate system supplies the candidate lattice and which system supplies the map sample. This follows the distinctions in the [Distribution Maps tutorial](https://www.itoosoft.com/tutorials/back-to-basics-distribution-maps) and [Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).

* **XY:** construct the lattice in Cyrus FL XY, using Units, Pixels, Offset, Rotation, and tiling. A built-in bitmap or a directly loaded Bitmap is sampled in that local map frame. Surface UVs do not move the map. S2 subsequently drops the candidate along the configured surface direction. This is the default for flat terrain and makes map tiling independent of mesh topology.
* **UV:** use the selected surface's UV coordinates as the placement domain. The map frame is defined in UV, and a UV sample is resolved to a surface point in S2. For a built-in or Bitmap map, UVs scale the pattern over the surface while Units still controls candidate spacing. UV islands and seams can therefore create discontinuities; the surface ID and triangle tie break remain part of the provenance.
* **Builtin:** use a Cyrus built-in map as a procedural local XY lattice. The sampler is evaluated in normalized pixel coordinates, never through Max texture evaluation. This is the fast and version-stable path for Full, Grid, Noise, and the other shipped patterns. It follows the tutorial's built-in map behavior, while making the exact library ours.
* **Map:** use an arbitrary Max map or bitmap as a filter. In XY mode, the candidate lattice is still governed by local Units and Pixels, but the map sample can be evaluated at surface UVW when a Surface Map Channel is configured. In UV mode, the same map is sampled using the surface channel and Units controls the world or UV candidate density according to the surface mode. S0 bakes all Map results into a `MapSampler`, including channel selection, time, and UV channel.

The rule and source type are stored separately. Thus `source=Builtin, rule=UV` and `source=Map, rule=XY` are legal, but they intentionally have different cache keys and previews. A map sample never silently changes the candidate frame. If a requested UV channel is missing, report the channel error and use the configured fallback channel only when the user explicitly enables it.

### 4.6 Shipped distribution-map library

[DESIGN] Cyrus ships its own roughly 35-entry library, with the exact procedural recipe versioned in `algoVersion`. The library is not presented as Forest's private pixel content. It provides useful names and repeatable behavior while allowing a future import of an installed Forest `index.dat` as a separate compatibility catalog. All maps return a scalar in `[0,1]` or a color where noted. A deterministic 64-bit seed is derived from the map ID and tile, so repeated tiles match exactly.

| ID and display name | Procedural recipe and intended appearance |
|---|---|
| `full` Full | Constant 1.0. Every pixel is eligible, yielding a complete lattice. |
| `empty` Empty | Constant 0.0. Useful as a gap source and test map. |
| `grid` Grid | Keep pixels where both integer coordinates are even, otherwise 0. |
| `grid_fine` Fine Grid | Keep coordinates satisfying `x mod 3 == 0` and `y mod 3 == 0`. |
| `grid_offset` Offset Grid | Alternating row offset: even rows use even x, odd rows use odd x. |
| `diagonal` Diagonal | Keep when `(x + y) mod 4 == 0`. |
| `diagonal_wide` Wide Diagonal | Distance to diagonal stripes from `sin(2*pi*(u+v)*8)` remapped to binary. |
| `checker` Checker | `((x xor y) & 1)` remapped to alternating 0 and 1. |
| `dense` Dense | A 2D Bayer-like thresholded pattern with 75% of cells at one. |
| `sparse` Sparse | A 2D Bayer-like pattern with 25% of cells at one. |
| `spread` Spread | Blue-noise-like rank pattern from a fixed 8 by 8 permutation, keep the lowest 35% ranks. |
| `rows` Rows | Keep every fourth row, with a mild within-row value variation. |
| `columns` Columns | Keep every fourth column, the transpose of Rows. |
| `double_rows` Double Rows | Keep two rows, skip two rows. |
| `orchard` Orchard | Staggered row points, using `(x + 2*y) mod 7 == 0`. |
| `orchard_loose` Loose Orchard | Staggered points with a second valid phase on every third row. |
| `hedgerow` Hedgerow | Narrow continuous bands along Y, modulated by low-frequency noise. |
| `clumps` Clumps | Threshold low-frequency value noise at 0.58. |
| `clumps_soft` Soft Clumps | Return a smooth value-noise field for Density Map mode. |
| `patches` Patches | Threshold two-octave value noise at 0.62, producing larger islands. |
| `patches_small` Small Patches | Threshold three-octave noise at 0.57 for smaller islands. |
| `noise_white` White Noise | One hash per pixel, scalar uniform noise. |
| `noise_value` Value Noise | Bilinear interpolation of hashed lattice values. |
| `noise_perlin` Gradient Noise | Deterministic 2D gradient noise with quintic fade. |
| `noise_fractal` Fractal Noise | Four octaves of gradient noise, amplitudes 1, .5, .25, .125. |
| `noise_ridged` Ridged Noise | `1 - abs(noise)` over three octaves, creating lines and ridges. |
| `noise_worley` Cell Noise | Nearest seeded feature distance, inverted and normalized. |
| `noise_worley_edge` Cell Edges | Difference between nearest and second-nearest feature distances. |
| `rings` Rings | Radial bands from `sin(2*pi*radius*12)`, centered in a tile. |
| `radial` Radial Gradient | `1 - length(uv*2-1)`, useful as a density map. |
| `waves` Waves | Horizontal sine bands with a small vertical domain warp. |
| `crosshatch` Crosshatch | Maximum of diagonal stripe fields, thresholded at .65. |
| `speckles` Speckles | Sparse thresholded white noise followed by a 3 by 3 dilation. |
| `painted` Painted | Multi-octave noise multiplied by a smooth irregular mask. |
| `terrace` Terrace | Quantized value noise with five plateaus. |
| `edge` Edge Bias | Minimum distance to a tile edge, remapped for border planting. |

Recipes share `BuiltinMapContext { mapId, algoVersion, u, v, pixelX, pixelY }`. Hash noise uses integer lattice coordinates and a purpose-specific hash, never floating point coordinates as a seed. Continuous noise uses double precision interpolation and clamps final values. Thresholded maps are evaluated at pixel centers, so a tile repeated at a different world offset has the same pixel pattern unless `WorldSeeded` is explicitly selected in a future version.

The on-disk format is a small binary or JSON catalog named `distribution_maps.cyrus`. The JSON authoring form is easier to inspect and is compiled into a binary index at install time:

```json
{
  "format": 1,
  "libraryVersion": 1,
  "maps": [
    {"id":"full", "name":"Full", "kind":"constant", "params":{"value":1}},
    {"id":"noise_fractal", "name":"Noise Fractal", "kind":"fbm",
     "params":{"octaves":4,"gain":0.5,"lacunarity":2.0,"seed":1843}}
  ]
}
```

The compiled index stores ID, localized display name, recipe kind, parameter blob, thumbnail key, recommended default Threshold, and a recipe version. A loader rejects duplicate IDs, unsupported recipe kinds, NaN parameters, and a library version newer than the plugin. User maps can be appended in a user catalog but cannot override a shipped ID without a migration record. Thumbnails are generated from the same sampler and fixed seed, not from a separate image. This avoids a preview that disagrees with render.

### 4.7 Distribution frames, per-area generation and overrides

S1 generates **one lattice per distribution frame**, not one per Include area (00 decision D1). This is what makes overlapping Include areas union cleanly instead of producing coplanar duplicates (Forest warns against overlapping Includes for exactly that reason [FP-DOC]).

For each distribution frame f:

1. Collect the Include areas that use frame f (frame 0 = all Includes without a lattice override).
2. Compute the union of their FL broad bounds (a list of AABBs, not one big box, so far-apart areas don't enumerate the gap).
3. Resolve effective map, Units, Pixels, frame transform and surface rule for f.
4. Enumerate map tiles overlapping any of those bounds; emit each pixel position once, with `sourceId = frameId = f` in the key, up to Max Density.
5. Leave ownership to S3: S3 assigns `areaIndex` = the lowest (first evaluated) Include area of the same frame that contains the candidate, and kills candidates no Include of their frame contains. Exclude then acts on `areaIndex` exactly as 04 specifies.

A compatibility switch `overlapPolicy = DuplicatePerArea` (test only) restores per-area generation with the area entryId as frame, so Forest Lite comparison scenes can check which behavior Forest has [OPEN].

An area Scale multiplies the effective density probability and does not scale world Units. An alternate map changes samples but does not reorder the key. If an area override is active and its map has different resolution, candidate provenance records the effective map dimensions for diagnostics. The global Max Density is per object evaluation and includes all areas and all map positions, including pixels below Threshold. This avoids a sparse black map bypassing the safety limit.

### 4.8 Candidate cap and estimation

Estimate before allocation:

```text
N_raw = sum over areas (number of overlapping tiles * pixelsX * pixelsY)
N_after_threshold = sum of sampled positions with mapValue >= threshold
N_expected_density = sum(mapValue * areaScale * densityFactor)
```

`N_raw` is the safety quantity because Max Density counts black positions. If `N_raw > MaxDensity`, stop generation before allocating the full population and report the first offending area and tile range. [FP-DOC] A value of zero means no explicit Max Density limit, but Cyrus still applies a hard process safety limit from preferences and must warn rather than exhaust memory. The estimate for viewport budgeting should use `N_expected_density`, but cap its confidence interval at `N_raw`; a `Full` map should estimate near all positions.

For Path, Reference, Particle, and Manual, `N_raw` is the source count, not a map count. A single Image object can report `raw`, `thresholdPass`, `densityExpected`, `generated`, and `capRejected`. These counts feed the S12 Stats panel.

## 5. Path mode

[FP-DOC] Path mode supports one or more splines, regular Spacing, In Vertex Positions, Spline Offset, Random Position, Follow Path X, Follow Path Z, and Geom ID Random or Sequence. See [Path Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode).

### 5.1 Arc-length tables

S0 samples each spline into a `PathTable`. For a Bezier or NURBS spline, use adaptive subdivision until chord error is below `max(1e-5 * length, 1e-4 scene units)` and tangent angle change is below a configurable tolerance. Store cumulative lengths, positions, and normalized tangents. At evaluation, binary search `s` and interpolate position and tangent, then renormalize. A zero-length segment inherits the nearest nonzero tangent; an entirely degenerate spline produces no candidates with a diagnostic.

For open paths, place samples at `s = 0, spacing, ...` while `s <= length`. A `Random Position` value selects `s = n*spacing + r*spacing*randomPosition`, but clamps the final interval to `length`. For closed paths, sample a half-open interval `[0,length)` so the seam does not duplicate. The first sample is at zero unless the UI's random position is nonzero. Use path ID, segment index, and sample index in the key, not the computed floating point distance.

Spline Offset uses the local planar normal. For tangent `(tx,ty)`, define `n = normalize((-ty,tx))` in the spline's generation plane. For a 3D spline, project into the active FL plane or construct a stable frame from the tangent and the configured up axis. At a cusp, inherit the previous normal and mark the frame discontinuity for S7.

Vertex mode emits one sample for each source vertex. Closed paths do not duplicate the final vertex if it equals the first. A vertex tangent is the normalized sum of incoming and outgoing segment tangents, with one-sided fallback at open endpoints. Random Position is ignored in vertex mode with a UI notice.

### 5.2 Follow path and geometry

Path generation writes `pathPos` as normalized arc length and a tangent frame hint. S7 composes Follow Path X and Z after surface alignment according to the transform policy in 07. X points along tangent; Z is derived by cross with the active up or surface normal. If only Z is enabled, preserve the item's local X heading and rotate its local Z toward the tangent. This explicit policy avoids ambiguous Euler order.

Sequence mode cycles geometry list entries by sample index and path source order. Random mode chooses through the S6 GeometryTable using the stable model-selection hash. The generator need not choose the final model, but it records `pathSampleIndex` so Sequence is independent of thread completion.

## 6. Reference mode

[FP-DOC] Reference mode dynamically links reference nodes and supports pivots, faces, multiple items per face, randomization, Align, Scale, Material ID filtering, and name or regular-expression geometry matching. See [Reference Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode).

### 6.1 Pivot mode

For each reference node, emit one candidate at its pivot in FL. The snapshot stores the pivot transform, node name, and stable reference ID. Align copies the source orientation into a frame hint; Scale copies source scale. If disabled, candidates still use the reference pivot location but inherit the Cyrus surface or transform orientation.

Name matching is evaluated against the node's name after Max's case policy is normalized. If regex is enabled, compile once per evaluation, reject invalid expressions with a parameter error, and match the full name unless the UI explicitly says search. A match to no geometry falls back to the first GeometryTable item. If the first item is disabled or empty, emit a gap. This matches the documented fallback behavior without silently inventing an object.

### 6.2 Face mode

Snapshot mesh faces, vertex positions, normals, material IDs, and a stable source face index. Filter by Material ID before generating. For one item per face, use the face centroid. For `k` items per face, enumerate a triangular barycentric lattice. One deterministic enumeration for integer `m` where `m(m+1)/2 >= k` is:

```cpp
for (u32 row = 0; row < m; ++row)
  for (u32 col = 0; col <= row; ++col) {
      float b0 = float(m - row) / m;
      float b1 = float(col) / m;
      float b2 = 1.0f - b0 - b1;
      emit(b0, b1, b2);
  }
```

Stop after `k` samples using a documented row-major policy. Better visual uniformity can use a triangular lattice with `m` chosen so that the exact requested count is represented by a clipped row. Randomize Position applies a seeded barycentric perturbation that stays inside the triangle. Generate two uniform random values, reflect when their sum exceeds one, and blend toward the lattice point by the Randomize amount. The key is face index plus sample index, so changing face order in a rebuilt mesh must preserve the source face ID when topology identity is available.

Position is `b0*v0 + b1*v1 + b2*v2`. Face alignment uses the vector from face center to the farthest triangle vertex as local X, as documented. If that vector is degenerate, use the longest edge, then a stable axis. The normal is normalized with a fallback for degenerate faces. Store material ID and face provenance for effects and diagnostics.

## 7. Particle Flow mode

[FP-DOC] PFlow mode places items on Particle Flow particles and exposes age, rotation, scale, speed, and event ID to Effects. See [Particle Flow mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode) and [Attributes](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes).

### 7.1 Max adapter and snapshot contract

L3 accesses the evaluated particle object on the main thread through the 3ds Max SDK's particle extension interface. The implementation must verify the exact installed SDK declarations for `IParticleObjectExt`, method names, channel ownership, and time units in headers. Do not call the interface from workers. The adapter converts each live particle into `ParticleSnapshot` with FL position, stable particle ID, rotation, scale, velocity, age in ticks, speed, event ID, and alive state.

Particle systems differ in whether particle indices remain stable. Prefer the SDK's particle ID or birth ID if exposed. If only an index exists, combine source node ID, event ID, birth time, and index, mark identity as provisional, and label the result [OPEN] for a Forest Lite test. Do not use vector order as a permanent key when a stable channel is available.

Verify names and units in the target SDK and record them in a compile-time adapter test. The source notes document `particleAge` as ticks, `particleRotation` as incremental world XYZ rotation in radians, `particleScale` and `particleSpeed` as vectors, and `particleEventID` as a numeric ID derived from event name. We preserve those values as source channels without interpreting them until S7 or S10.

### 7.2 Emission and event filtering

Filter dead particles and selected event IDs in S0 or at S1. If all events are enabled, include every live event. A particle emits one candidate. Position is the particle position in FL. Align and Scale flags determine whether S7 uses source rotation and scale. The default does not copy them, because a scatter object normally controls its own transform; this is [DESIGN] and should be compared against Forest.

Particle time edits dirty S1 through S12 because particle membership and source channels can change. A pure transform edit to Cyrus need not re-query PFlow if the snapshot remains valid. Particle candidate keys use particle ID and event layer. If a particle dies, its old key simply fails to emit; no surviving particle is reseeded.

## 8. Manual item source

Custom Edit items enter S1 as `GenKind::Manual` with `F_MANUAL`. The authored `ManualItem` record is owned by 10, not by the generated Population. S0 converts it to a candidate with position, rotation, scale, geometry entry ID, and manual ID. Manual candidates bypass Image, Path, Reference, and Particle generation and are not thinned by the distribution map. They still participate in S2 surface behavior only if the manual item's mode says project to surface; otherwise their position is authoritative. They pass through S3 filters according to the Custom Edit policy, and S9 collisions follow the explicit manual collision policy.

A manual key is based on immutable manual ID and object ID, never its array order. A user delete creates an override or removes the authored item as specified by 10. Manual candidates can coexist with generated candidates at the same position; S9 decides whether collision settings remove one. Preserve `F_MANUAL` through S12 so editing and diagnostics can identify the source.

## 9. Density S5 integration

S1 writes raw positions and map values. S2 and S3 add surface and area factors. S4 writes `densityFactor`. S5 computes a final probability:

```cpp
float densityProbability(const Candidate& c, const AreaParams& a,
                         const ScatterParams& p) {
    float mapP = p.mode == Image && p.useDensityMap ? c.mapValue : 1.0f;
    float binary = (p.mode == Image && !p.useDensityMap &&
                    c.mapValue < c.threshold) ? 0.0f : 1.0f;
    return clamp01(binary * mapP * c.areaScale * c.densityFactor *
                   p.globalDensityMultiplier);
}

void thin(Population& pop, size_t i) {
    float p = densityProbability(pop.candidate[i]);
    if (p <= 0.0f || stable01(pop.key[i], Purpose::Density) >= p)
        pop.flags[i] |= F_CULL_DENSITY;
    else
        pop.flags[i] |= F_ALIVE;
}
```

For non-Image generators, `mapP` is one unless a shared map is explicitly enabled by the area program. For Image binary mode, `mapValue` is only a gate. For Image density mode, gray is the probability source and Threshold is a floor. This is a design choice because the public wording does not specify whether Threshold is ignored in density mode; expose a compatibility switch if Forest Lite tests demonstrate otherwise.

S5 must process all candidates in stable key order only for diagnostics. The hash makes acceptance independent of order. The viewport budget from 00 is another multiplier, `min(1, maxItems / estimatedCount)`, and therefore adds or removes positions monotonically.

## 10. Pipeline integration and caches

S1 reads distribution parameters, Include area bounds, source snapshots, and the map sampler. It writes key, area index, pixel and tile coordinates, path position, and FL XY or source position. It sets no final cull flag except optional early map rejection; the normative cull flag is set by S5.

S5 reads `densityFactor`, map value, and area overrides. It writes `F_CULL_DENSITY` or `F_ALIVE`. S6 reads map color and provenance for model diversity. The published render and viewport results carry the immutable population version into `ViewMask`; view culling never changes StableKey or reruns density. S7 reads path frames and particle/reference source transforms. S10 reads candidate pixel and particle channels for the Effects VM.

Cache keys:

* `MapGrid`: map identity, time, resolution, channel, and bake settings.
* `PathTable`: source shape version, time, FL transform, subdivision tolerance.
* `ReferenceSnapshot`: node handle, topology and transform versions, time, material channel.
* `ParticleSnapshot`: PFlow node, time, source validity version, event filter.
* `ImageEstimate`: area bounds, frame, map version, map dimensions, threshold, and effective Units.

The `SharedCacheRegistry` owns shared source accelerators. Per-object S1 and S5 checkpoints are copy-on-write. A map offset change invalidates S1. A pure density-factor curve change starts at S4 or S5 as specified by 00. A surface move normally restarts S1 for candidate domains that use UV placement, and S2 onward for XY placement.

Threading uses independent tile jobs. Each job samples maps and writes a private SoA append buffer. No job accesses Max. Merge by tile order and key. Cancellation is checked after each map tile, path chunk, face block, or particle block. Render evaluation does not accept viewport cancellation.

## 11. 3ds Max integration

ParamBlock2 parameters map to the table in section 2. Use tab parameters for paths, references, and area overrides, each with immutable entry IDs stored in the authored record. The UI should provide a map preview, tile gizmo, threshold histogram, candidate count, and a warning when the Max Density estimate includes many black pixels.

S0's Max layer evaluates map channels and bakes a `MapGrid`. For arbitrary procedural maps, evaluate on the main thread through the appropriate `Texmap` and `ShadeContext` path after verifying the SDK signatures. Never retain a `ShadeContext` in core. For mesh references, extract a plain triangle snapshot. For paths, convert Max shape data to a polyline or curve sample table. For PFlow, use the verified particle extension adapter described above.

Notifications from a map, area, path, reference node, or particle source must mark the matching DirtyBit. Time changes mark animated maps and PFlow. UI changes use `NotifyDependents` and schedule an asynchronous generation; a render callback requests a synchronous immutable evaluation. A map preview may use lower resolution, but its cache key and algorithm version must differ from the final map to avoid accidentally publishing preview samples as render output.

## 12. Edge cases and failure modes

* **Negative FL coordinates:** use floor division for tile indices and canonical modulo for pixels.
* **Huge extents:** estimate with checked 128-bit multiplication or saturating u64 arithmetic. Refuse allocation when count exceeds Max Density or hard safety caps.
* **Zero Units or Pixels:** clamp invalid UI input, set a parameter error, and emit no candidates rather than divide by zero.
* **NaN map sample:** treat as zero, count it in diagnostics, and report the source map.
* **Rotated fit rectangle:** if Pick Start and Pick End are not an axis-aligned rectangle, define the diagonal frame and preserve sign; a zero area fit falls back.
* **Concave areas:** S1 broad bounds may over-generate; S3 exact area tests decide survival.
* **Overlapping Include areas:** candidates of the same frame are generated once and owned by the lowest containing Include (00 D1). Areas with their own lattice override overlap the global frame by design; if both cover a point, both frames emit candidates there. The UI shows a warning badge for that case, like Forest's overlapping-Include caution.
* **Surface UV seams:** UV mode can produce nearby world points with discontinuous UV. Keep the surface hit and tie breaking in S2; do not deduplicate.
* **Animated maps:** S0 bakes at time and invalidates on time. A missing animation evaluation is a hard diagnostic, not a worker-thread fallback.
* **Missing reference node:** emit no candidates and preserve the source ID in diagnostics.
* **Particle reorder:** use SDK stable IDs; if absent, mark identity provisional and expose a warning.
* **Degenerate face or spline:** skip with source and index in Stats.
* **Regex compile failure:** reject the match filter, use first-item fallback only for a valid matching operation, and show a parameter error.
* **Manual item outside areas:** follow 10's authored policy. Default is to retain the manual item but set a diagnostic if an Exclude removes it.

## 13. Performance targets

[DESIGN] On a 16-core desktop, generate and density-process 1 million raw lattice positions in under 120 ms when the map is a cached scalar grid and the area has a simple bound. The target excludes Max map baking and surface ray casting. Generate 10 million positions in under 1.5 seconds with less than 160 bytes of transient provenance per candidate by chunking and releasing checkpoints after S5.

The dominant traps are too-small Units, counting black pixels incorrectly, calling a Max map from worker threads, and storing a full map sample per tile repeatedly. Cache each tile's scalar samples, use contiguous SoA appends, and stream estimates before allocation. For a Full map, use a fast path that fills map values with one while still counting every logical pixel. For sparse maps, do not search for white pixels: the documented model still processes black positions and Max Density must see them.

## 14. Tests and Forest Lite scenes

### Unit tests

1. A 2 by 2 map and one tile produce exactly four center coordinates and four stable keys.
2. Negative bounds produce the same keys when the scene is evaluated with one or many worker tiles.
3. Threshold 0 accepts black in binary mode; Threshold 1 accepts only exact white.
4. Density scores are stable across thread counts and are monotone as probability changes.
5. Max Density counts black cells and stops before allocation.
6. Lock Aspect preserves source aspect; Fit to Scene maps selected corners exactly.
7. Jitter zero is exact; jitter remains within half a cell.
8. Open and closed paths do not duplicate seam endpoints.
9. Face barycentrics sum to one and stay inside the triangle.
10. Particle stable IDs survive a reordered snapshot.
11. Manual keys survive list reorder.

### Golden scenes

* Full map on a rectangular area, Units and Pixels varied independently.
* Threshold gradient and density map with a fixed seed, exported to CSV.
* Rotated and offset map crossing negative FL coordinates.
* Same area with two alternate map overrides to prove per-area independence.
* Path with a cusp, an open endpoint, a closed seam, offsets, and random position.
* Reference mesh with material IDs, a degenerate face, face grids, and regex geometry matching.
* PFlow scene containing multiple events and animated age, rotation, scale, speed.
* Custom Edit items mixed with generated items.

Compare Forest Lite only for documented or observed behavior, and record version and renderer. Exact hash values and jitter are Cyrus design decisions, not compatibility claims.

## 15. Open questions

* [OPEN] Does Forest apply Threshold as a gate in Density Map mode, or does Density Map replace Threshold entirely?
* [OPEN] Is Forest's Full apparent irregularity hidden jitter, transform variation, surface projection, or display behavior?
* [OPEN] Does changing a map resolution preserve correspondence of existing pixel keys in Forest, or reseed the lattice?
* [OPEN] Verify the exact Max SDK `IParticleObjectExt` declarations, stable particle identifier, event ID source, and tick versus frame conversion.
* [OPEN] Verify closed-spline endpoint and Random Position rules in the target Forest version.
* [OPEN] Verify whether reference face randomization is uniform barycentric or another distribution.
* [OPEN] Verify regex matching mode, case sensitivity, and fallback when the first item is disabled.

## 16. Architecture feedback

00's S1 contract says it writes `pos(xy)` and provenance, which is sufficient for Image and Path but not for Reference source orientation or Particle channels. This specification extends it with a checkpoint sidecar `CandidateExtras`; no existing hot `Population` field is redefined. The explicit use of S5 for density thinning follows 00's stage table and preserves the intended monotone budget behavior.

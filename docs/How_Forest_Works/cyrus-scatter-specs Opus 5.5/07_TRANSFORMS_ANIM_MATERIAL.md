# 07: Transforms, animation, and material payload

## 1. Purpose and scope

This specification defines stages S7 and S11 of Cyrus Scatter. S7 converts a surviving, model-selected population entry into a final object transform. It consumes the generated position, the surface normal, path provenance, the selected geometry metadata, and S4 falloff factors. It writes the `Population` transform fields `rot`, `scale`, and `mirror`, and it may update `pos` for translation jitter, pivot displacement, and Z offset. S11 writes the render payload fields `tintRGBA8` and `animSample`.

The design extends, rather than replaces, the contracts in `00_ARCHITECTURE.md`. `Population`, `StableKey`, `KeyParts`, `StageContext`, `IStage`, `ItemFlags`, `DirtyBits`, and `SharedCacheRegistry` remain the authoritative types. The core implementation has no 3ds Max headers. Max-specific controls are converted in S0 to immutable plain-data structures in `SceneSnapshot` and `ScatterParams`.

This file covers:

* base orientation from a surface normal and a user `Direction` vector;
* path following on X or Z;
* camera or target Look-At, including the deliberate boundary between S7 and the view pass;
* random translation, rotation, scale, mirror, pivot, center displacement, Z offset, and falloff;
* deterministic random draws, probability curves, transform maps, Store Transform, and Re-Seed;
* animation modes, source snapshots, sample caching, and motion blur;
* gradient tint, map tint, color correction, packed tint data, Cyrus Color texmap semantics, and material consolidation.

It does not define area generation, surface resolution, distribution maps, collision rejection, effect expressions, or renderer-specific material plumbing. S9 handles collision after S7. S10 handles saved overrides and the Effects VM after S7 and before S11. File 09 owns render adapter calls and renderer material binding.

### 1.1 Forest behavior to match

Forest's public workflow places geometry, surfaces, areas, distribution, then transform randomization. Surface documentation describes XY placement followed by movement along Z to the surface in XY mode, while UV mode uses the surface's UV alignment. [FP-DOC: Forest first scatter](https://docs.itoosoft.com/forestpack/getting-started/first-scatter), [FP-DOC: Forest Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces)

Forest documents random position, rotation, and scale as Pro functionality, camera Look-At for billboards, geometry scale, Global Scale, Z Offset, and Center Displace. The Transform reference documents independent X, Y, and Z rotation ranges in degrees, and explicitly says rotation is not applied when Camera > Facing Camera is enabled. [FP-DOC: Forest Transform](https://docs.itoosoft.com/forestpack/forest-plugin/transform) It does not publish its private matrix multiplication order. [FP-DOC: Forest Lite and Pro](https://docs.itoosoft.com/forestpack/lite-and-pro), [FP-DOC: Forest Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera), [FP-DOC: Forest Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)

Forest documents Store Transform as baking the current randomized transforms and disabling randomness, and Re-Seed as changing transform seeds. [FP-DOC: Forest Item Editor](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor)

The exact relationship among normal alignment, Direction, path following, Look-At, random Euler rotations, mirror, pivot displacement, and scale is not public. Cyrus therefore disables random rotation when Facing Camera is active, matching the documented Forest rule, rather than attempting to apply a camera-relative random spin. [FP-DOC] The composition below is a Cyrus decision, with [OPEN] tests where Forest parity requires observation.

## 2. Parameter model

The following table lists authored parameters. Percent values are represented internally as normalized floating point values in the range 0 to 1 unless otherwise stated. The UI may display 0% to 100% or signed percentages. `D_TRANSFORM` means S7 or later; `D_TIME`, `D_GEOM_LIST`, and map-specific groups are included when they affect S11.

| UI name | Internal name | Type | Default | Range and units | Rollout | DirtyBits group | Notes |
|---|---|---|---|---|---|---|---|
| Direction mode | `directionMode` | enum | Surface Normal | Normal, custom, path | Transform | `D_TRANSFORM` | Custom direction is a Forest-local vector. |
| Direction | `direction` | `Vec3f` | (0,0,1) | Unit vector after normalization | Transform | `D_TRANSFORM` | Zero vector falls back to +Z and emits a diagnostic. |
| Align to surface | `alignToSurface` | bool | true | On or off | Transform | `D_TRANSFORM` | Normal alignment is the base frame. |
| Path follow axis | `pathFollowAxis` | enum | None | None, X, Z | Transform | `D_TRANSFORM` | X or Z is the local item axis tangent to path. |
| Facing mode | `facingMode` | enum | None | None, render camera, active viewport camera, target node | Camera/Transform | `D_CAMERA` or `D_TRANSFORM` | See the view-dependent policy below. |
| Look-At target | `lookAtTarget` | node handle or null | null | Snapshot reference | Camera | `D_CAMERA` | A node target is evaluated in S0. |
| Look-At up mode | `lookAtUpMode` | enum | Surface normal | Surface normal, world Z, custom up | Camera | `D_CAMERA` | Avoids roll singularity. |
| Random rotation X | `rotationX` | min/max degrees | 0/0 | Signed degrees, recommended -180 to 180 | Transform | `D_TRANSFORM` | Uniform draw unless curve/map changes it. |
| Random rotation Y | `rotationY` | min/max degrees | 0/0 | Signed degrees | Transform | `D_TRANSFORM` | Applied in local frame. |
| Random rotation Z | `rotationZ` | min/max degrees | 0/0 | Signed degrees | Transform | `D_TRANSFORM` | Local spin after alignment. |
| Random rotation distribution | `rotationDistribution` | enum | Uniform | Uniform, curve | Transform | `D_TRANSFORM` | Curve is inverse-CDF sampled. |
| Mirror X/Y/Z | `mirrorAxes` | bit mask | none | Three axes | Transform | `D_TRANSFORM` | A single reflected transform is stored as mirror bits plus positive scale. |
| Mirror probability | `mirrorProbability` | float | 0 | 0 to 1 | Transform | `D_TRANSFORM` | Independent axis draws use separate purposes. |
| Item Scale | `itemScale` | `Vec3f` | (1,1,1) | Positive dimensionless factor | Geometry | `D_GEOM_LIST` | Per geometry entry. |
| Global Scale | `globalScale` | float | 1 | 0 to positive, dimensionless | Transform | `D_TRANSFORM` | Forest documents 100% as the default. |
| Random scale X/Y/Z | `randomScaleMin/Max` | Vec3f pair | (1,1,1) | Positive dimensionless | Transform | `D_TRANSFORM` | Uniform or curve driven. |
| Uniform scale | `uniformRandomScale` | bool | true | On or off | Transform | `D_TRANSFORM` | One draw is reused for all axes when on. |
| Height-only falloff | `heightOnlyScale` | bool | false | On or off | Falloff | `D_FALLOFF` | S4 supplies `(1,1,s)` when on. |
| Translation jitter X | `translationX` | min/max percent | 0/0 | Percent of item width | Transform | `D_TRANSFORM` | Width is geometry metadata after source snapshot. |
| Translation jitter Y | `translationY` | min/max percent | 0/0 | Percent of item width | Transform | `D_TRANSFORM` | Forest local lateral axis. |
| Translation jitter Z | `translationZ` | min/max percent | 0/0 | Percent of item height | Transform | `D_TRANSFORM` | Applied after distribution and base surface placement. |
| Z Offset | `zOffset` | float | 0 | System units | Geometry | `D_GEOM_LIST` | Along Forest-local +Z by default, or normal in surface mode [OPEN]. |
| Center Displace | `centerDisplace` | float | 0 | Percent of width | Geometry | `D_GEOM_LIST` | Lateral pivot shift for billboards and custom objects. |
| Pivot mode | `pivotMode` | enum | Source pivot | Source pivot, base, explicit | Geometry | `D_GEOM_LIST` | Source pivot is read from `SourceSnapshot`. |
| Pivot offset | `pivotOffset` | `Vec3f` | zero | Source units | Geometry | `D_GEOM_LIST` | Applied before final object transform. |
| Distribution map | `transformMap` | map sampler | null | Mono or RGB | Transform | `D_TRANSFORM_MAP` | Mono controls range, RGB maps XYZ. |
| Probability curves | `rotationCurve`, etc. | LUT | identity | Normalized 0 to 1 | Transform | `D_TRANSFORM` | Baked to fixed LUT in S0. |
| Store Transform | `storeTransform` | bool/action | off | Action or state | Item Editor | `D_OVERRIDES` | Stores a stable per-item transform override and turns off randomness for that item. |
| Re-Seed | `reseed` | action plus u64 | object seed | Integer seed | Item Editor | `D_TRANSFORM` | Changes only the seed namespace, not candidate identity. |
| Animation mode | `animationMode` | enum | Disabled | Disabled, Follow Geometry, Random Samples, Random from Map, Frame from Map | Animation | `D_TIME` or `D_ANIM_MAP` | S11 only. |
| Random sample count | `animationSampleCount` | u16 | 1 | 1 to implementation cap | Animation | `D_TIME` | Forest random samples are Pro functionality. |
| Time Offset | `animationTimeOffset` | float | 0 | Frames or time units | Animation | `D_TIME` | Applied to per-item source time. |
| Animation map | `animationMap` | map sampler | null | Mono | Animation | `D_ANIM_MAP` | Interpreted according to mode. |
| Frame start/end | `frameStart`, `frameEnd` | float pair | scene range | Frames | Animation | `D_TIME` | Frame from Map remaps map value into this interval. |
| Gradient tint strength | `gradientTintStrength` | float | 0 | 0 to 1 | Material | `D_MATERIAL` | Random strength is independently sampled. |
| Gradient tint map | `gradientTintMap` | gradient | null | Color stops | Material | `D_MATERIAL` | Base color may be item or element scoped. |
| Map tint mode | `mapTintMode` | enum | Random values | Random values, as texture | Material | `D_MATERIAL` | Determines whether map affects item payload or shader lookup. |
| Hue range/width | `hueRange`, `hueWidth` | float pair | 0/0 | Degrees or normalized turns | Material | `D_MATERIAL` | Range center and width. |
| Hue shift | `hueShift` | float | 0 | Degrees or normalized turns | Material | `D_MATERIAL` | Applied in HSV/HSL-like working space. |
| Saturation | `saturation` | float | 1 | 0 to positive | Material | `D_MATERIAL` | Multiplicative. |
| Brightness | `brightness` | float | 1 | 0 to positive | Material | `D_MATERIAL` | Multiplicative. |
| Tint packing | `tintRGBA8` | u32 | opaque white | 8 bits per channel | Material | `D_MATERIAL` | RGB color plus A tint multiplier. |

Forest defaults and ranges have changed across versions. Values not explicitly documented above are [DESIGN] starting values, not compatibility claims.

## 3. Data structures

### 3.1 Core transform descriptions

Add these POD structures to `core/types/transform.h`. They extend the architecture's `Population` fields and do not replace them.

```cpp
struct RangeF { float min = 0.0f; float max = 0.0f; };
struct RangeDeg { float minDeg = 0.0f; float maxDeg = 0.0f; };

struct TransformMapConfig {
    MapSamplerId sampler;
    enum class Mode : u8 { None, MonoRange, RGBScale } mode = Mode::None;
    bool invert = false;
    float black = 0.0f;
    float white = 1.0f;
};

struct TransformParams {
    bool alignToSurface = true;
    Vec3f direction{0,0,1};
    enum class PathAxis : u8 { None, X, Z } pathAxis = PathAxis::None;
    enum class Facing : u8 { None, RenderCamera, ViewCamera, Target } facing = Facing::None;
    Vec3f up{0,0,1};
    RangeDeg rotX, rotY, rotZ;
    bool uniformRandomScale = true;
    Vec3f itemScale{1,1,1};
    float globalScale = 1.0f;
    Vec3f randomScaleMin{1,1,1}, randomScaleMax{1,1,1};
    Vec3f translationMinPercent{0,0,0};
    Vec3f translationMaxPercent{0,0,0};
    float zOffset = 0.0f;
    float centerDisplacePercent = 0.0f;
    Vec3f pivotOffset{0,0,0};
    u64 reseed = 0;
    TransformMapConfig map;
};
```

The source snapshot must expose immutable dimensions, source pivot, material and element metadata, animation frame availability, and a conservative local bounding sphere. S7 needs dimensions to convert percentage jitter into scene units and to perform the later boundary and collision stages. It must not retain Max `INode`, `Mesh`, or `Texmap` pointers in core structures.

### 3.2 Animation and material payload descriptions

```cpp
enum class AnimationMode : u8 {
    Disabled, FollowGeometry, RandomSamples, RandomFromMap, FrameFromMap
};

struct AnimationParams {
    AnimationMode mode = AnimationMode::Disabled;
    u16 sampleCount = 1;
    float timeOffset = 0.0f;
    float startFrame = 0.0f;
    float endFrame = 0.0f;
    MapSamplerId map;
    u64 reseed = 0;
};

struct AnimationSample {
    float sourceTime = 0.0f;
    u16 sourceFrame = 0;
    SourceSnapshotId source;
    Vec3f linearVelocity{0,0,0};
    Vec3f angularVelocity{0,0,0};
};

struct MaterialPayloadParams {
    GradientSamplerId gradient;
    MapSamplerId tintMap;
    enum class MapMode : u8 { RandomValues, Texture } mapMode = MapMode::RandomValues;
    float gradientStrength = 0.0f;
    RangeF randomHue;
    float hueShift = 0.0f;
    float saturation = 1.0f;
    float brightness = 1.0f;
    enum class BlendMode : u8 { Normal, Color, Additive, Average, Multiply } blend = BlendMode::Normal;
};
```

`Population.animSample` remains the compact per-item index mandated by 00. A `PublishedPopulation` extension can carry an optional `AnimationSampleTable` keyed by `(populationVersion, sampleIndex, sourceSnapshotId)`. `tintRGBA8` remains the render-facing compact value. S11 may keep a larger transient `TintWork` buffer until packing.

### 3.3 Stable random namespaces

StableRNG is defined in 01. S7 must use its purpose namespace rather than one sequential random stream. Suggested purpose constants are:

```cpp
enum class RandomPurpose : u32 {
    TransformRotX = 0x0701, TransformRotY, TransformRotZ,
    TransformScaleUniform, TransformScaleX, TransformScaleY, TransformScaleZ,
    TransformTranslateX, TransformTranslateY, TransformTranslateZ,
    TransformMirrorX, TransformMirrorY, TransformMirrorZ,
    TransformCurveJitter, AnimationSample, AnimationFrame,
    TintGradient, TintHue, TintSaturation, TintBrightness,
    LODVariation = 0x0801
};
```

Each draw is `StableRNG(seed, StableKey, purpose, reseed)`. It is illegal to consume an extra value conditionally and then use the next value for a different property. A purpose gets a fixed draw shape even if its control is disabled, or the implementation uses independent keyed draws that have no sequence position. This ensures changing translation does not perturb rotation and that tile scheduling does not alter results.

## Algorithms

The following subsections are the normative S7 and S11 algorithms. They use immutable snapshot inputs, chunked SoA writes, and purpose-keyed StableRNG draws.

## 4. Transform composition

### 4.1 Proposed order

The proposed local-to-world composition, from right to left for column vectors, is:

```text
M_item = T(basePosition)
       * T(translationJitter)
       * T(pivotWorldCorrection)
       * R_facing_or_path_or_base
       * R_randomLocal
       * Mirror
       * S(itemScale * globalScale * randomScale * areaScale * falloffScale)
       * T(-sourcePivot)
       * T(pivotOffset)
```

This notation is conceptual. The implementation should use a `TransformTRS` or matrix builder that preserves reflection state and avoids decomposing a negative determinant into a quaternion. The final position stored in `Population.pos` is the base anchor plus translation jitter and explicit Z offset. Source pivot correction remains in the per-instance matrix payload if the render adapter needs it; if the architecture requires `pos` to mean final visual origin, S7 must apply the same correction there and document it in `TransformDiagnostics`.

The operational steps are:

1. Start from the S2 surface hit `p` and normal `n`. Normalize `n` with a robust fallback to the configured Direction if its length is below `1e-8`.
2. Build `B`, the base frame, from the selected alignment mode.
3. Replace or supplement `B` with path tangent alignment if path follow is enabled.
4. Apply Look-At if enabled and if the selected evaluation context has a camera or target.
5. Generate and apply local random Euler rotations.
6. Generate mirror bits and positive scale.
7. Apply item scale, Global Scale, random scale, area scale, and S4 falloff scale componentwise.
8. Convert percentage translation to units from the source width and height, then translate after distribution and explicit Z offset.
9. Apply Z Offset and center displacement using the defined frame.
10. Record the transform and any diagnostics for S8 and S9.

Why this order: alignment establishes what X, Y, and Z mean. Random rotations should vary the aligned object rather than alter how a path tangent is found. Scale should not alter normals or distribution positions, but must precede pivot correction so the pivot remains fixed at the anchor. Translation jitter must happen after distribution as requested, so a nonzero jitter does not change candidate identity or surface hit. The exact Forest order is [OPEN].

### 4.2 Base frame from surface normal and Direction

When `alignToSurface` is true, set local +Z to `n`. Choose a reference vector `r` from the configured Direction. Project it onto the tangent plane:

```cpp
Vec3f z = safeNormalize(normal, safeNormalize(direction, Vec3f{0,0,1}));
Vec3f r = safeNormalize(direction, Vec3f{0,0,1});
Vec3f x = r - z * dot(r, z);
if (lengthSquared(x) < 1e-10f) {
    Vec3f fallback = abs(z.z) < 0.9f ? Vec3f{0,0,1} : Vec3f{0,1,0};
    x = fallback - z * dot(fallback, z);
}
x = safeNormalize(x, Vec3f{1,0,0});
Vec3f y = safeNormalize(cross(z, x), Vec3f{0,1,0});
x = cross(y, z); // re-orthogonalize
Mat3f B{x, y, z};
```

This makes Direction an azimuth reference, not an arbitrary rotation axis. A custom Direction parallel to the normal therefore falls back predictably instead of producing NaNs. If `alignToSurface` is false, the base frame is Forest local identity, or a Direction frame if the UI explicitly requests it. [OPEN] Verify whether Forest's Direction is a world vector, local vector, or only a path mode control.

### 4.3 Path follow X and Z

S1 must retain `pathPos` and a path tangent in the provenance or a path cache. S7 consumes a tangent `t` and optional path normal or binormal. For X follow, local +X points along `t`. For Z follow, local +Z points along `t`. The remaining axes are chosen by parallel transport from the surface normal when available. A simple frame is:

```cpp
Vec3f tangent = safeNormalize(path.tangent, Vec3f{1,0,0});
Vec3f up = safeNormalize(surfaceNormal, Vec3f{0,0,1});
if (abs(dot(tangent, up)) > 0.999f) up = orthogonalFallback(tangent);
Vec3f side = safeNormalize(cross(up, tangent), Vec3f{0,1,0});
up = safeNormalize(cross(tangent, side), up);
Mat3f pathFrame = axisIsX ? Mat3f{tangent, side, up}
                          : Mat3f{side, up, tangent};
```

For curved paths, recomputing a frame independently at each sample can flip 180 degrees. Store a path frame in the path sampler using parallel transport, then choose the sign closest to the previous segment frame. Since path frames are generation data, their cache key includes path geometry version, path id, and algorithm version. [OPEN] Determine whether Forest uses world-up, surface normal, or a path's own normal when a path lies on an uneven surface.

### 4.4 Look-At and Facing Camera

Look-At is view-dependent. It cannot be part of the immutable canonical population if it references a camera that can change without a scene edit. The proposed policy is:

* target-node Look-At with a static target snapshot may run in S7 because the target is part of `SceneSnapshot`, but the target transform must be in the dirty graph;
* render-camera Facing Camera runs in the render view pass, after S7, using the render camera captured in the render snapshot;
* viewport-camera Facing Camera runs in V, not S7, using the current viewport camera;
* if a user requests a camera-facing item but the render adapter requires a transform in the population, S7 stores a camera-independent billboard basis and V produces a per-view derived matrix without changing `rot`.

This split honors deterministic camera-independent population and prevents orbiting the camera from reshuffling or rewriting overrides. Forest documents that Look-At rotates items toward a camera or another node, and that camera clipping is view-dependent. [FP-DOC: Forest Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera)

[OPEN] Forest's internal order for Facing Camera versus random rotation is unknown. Cyrus should test two scenes: a one-plane billboard with random Z and a camera orbit, then compare whether random spin is camera-relative or world-relative. Proposed behavior: Look-At establishes the view-facing frame first, but because Forest documents that Facing Camera disables random rotation, Cyrus does not apply `R_randomLocal` in that mode. For target-node Look-At without Facing Camera, random local rotation remains enabled. This distinction is [FP-DOC] for Facing Camera and [DESIGN] for target-node Look-At. The render and viewport adapters must use the same mathematical function to avoid a viewport or render orientation mismatch.

A robust Look-At frame projects the view vector onto a plane orthogonal to the chosen up vector. If the target is behind the item or coincident with it, preserve the previous valid frame or use the base frame. Never construct a quaternion from two nearly opposite vectors without handling the 180 degree case.

### 4.5 Random rotation in degrees

The UI stores min and max in degrees. S0 bakes them to radians only after validating finite values. For each axis, draw a normalized `u` and map it through an optional inverse-CDF curve. The angle is:

```cpp
float u = stableUnit(key, purpose, reseed);
float q = curve ? inverseCdf(curve, u) : u;
float angleRad = radians(lerp(minDeg, maxDeg, q));
```

Use intrinsic local X then local Y then local Z, represented as a quaternion product `qRandom = qZ * qY * qX` for column-vector convention. [OPEN] Verify Forest's Euler order and whether ranges are sampled as independent axes or a single Euler vector. We choose independent axes because it exposes stable controls and matches typical Transform rollout expectations.

Do not clamp a user range by silently swapping endpoints. Preserve the authored values, swap for sampling if `min > max`, and report a parameter warning. NaN and infinite values become defaults. Angles greater than one full turn are legal in the internal representation but normalize only for display.

### 4.6 Mirror

Mirror is a reflection across item-local axes. For deterministic independent axes, draw one value per axis using `TransformMirrorX`, `TransformMirrorY`, and `TransformMirrorZ`. A mirror bit is set when the draw is less than `mirrorProbability`, or when the explicit axis toggle is on. Keep positive scale in `Population.scale` and store mirror in `Population.mirror`; the render adapter composes `diag(-1,+1,+1)` from the bitset. This avoids a negative scale being mistaken for an ordinary scale by collision and LOD code.

If a user selects an explicit mirror axis, it is not a random draw. If `mirrorProbability` is zero, do not call the RNG. The identity key is unchanged by mirror. Material winding and normal handling are renderer responsibilities in 09, but S7 must set a reflection diagnostic so tangent-space normals can be corrected.

### 4.7 Scale composition

The required composition is componentwise:

```text
finalScale = itemScale
           * globalScale
           * randomScale
           * areaRandomScale
           * falloffScale
```

`areaRandomScale` is an optional S3 or area-program factor. The architecture's `Population.scaleFactor` currently represents the product of all S4 scale falloffs. Extend it with a separate transient area random factor if the area program has random scale; do not overload a deterministic falloff field with a random value. If `heightOnlyScale` is true, the area and falloff scale factors are `(1,1,s)`, but random scale remains full XYZ unless the user separately disables its X and Y ranges.

The item and Global Scale controls are documented by Forest, while their exact multiplication order is not. Multiplication is commutative for scalar factors but not for later pivot behavior, so scale must occur before source pivot correction. [FP-DOC: Forest Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)

For uniform random scale, consume one draw and reuse it on XYZ. For independent scale, consume three purpose-specific draws. A zero scale is legal for preview but should mark the item non-renderable and avoid inverse matrices. Negative scale is rejected from parameters and represented only by mirror bits.

### 4.8 Translation jitter, Z offset, pivot, and center displacement

Translation jitter is authored as percentages. X and Y use source width, and Z uses source height. For each component:

```cpp
jitter.x = width  * lerp(tx.min, tx.max, sampleX);
jitter.y = width  * lerp(ty.min, ty.max, sampleY);
jitter.z = height * lerp(tz.min, tz.max, sampleZ);
```

The vector is transformed by the aligned frame when the controls are item-local. This is applied after the distribution anchor and surface placement. [OPEN] Forest labels position controls in percent but does not publicly specify whether X and Y use width independently, the bounding-box diagonal, or another size metric. Start with width for X and Y and height for Z because it is predictable for billboard controls.

Z Offset is applied after scale and alignment as a displacement along the selected placement normal for surface-aligned geometry, or Forest-local +Z for flat XY generation. This distinction is [OPEN]. A compatibility switch in `TransformParams` should permit either interpretation until Forest Lite scenes settle it.

Center Displace is a pivot correction measured as a percentage of width. For one-plane billboards, use the aligned local X axis. `centerWorld = frame.x * width * centerDisplacePercent`. Apply it as a pivot displacement, not as an independent visible translation, so Look-At rotates around the displaced center. `pivotOffset` is a source-space offset applied before the final transform and scaled with the source. Forest documents Center Displace as important for camera-facing billboards. [FP-DOC: Forest Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)

## 5. Curves and transform maps

### 5.1 Probability curves

A Probability Curve defines a distribution over a normalized random draw. It is not a remap that may collapse all values without controlling probability mass. In S0, sample the curve into a monotone cumulative distribution LUT with 1024 entries [DESIGN]. Clamp negative density to zero, integrate trapezoidally, normalize by total area, and force the final CDF value to one. If the curve area is zero, fall back to uniform.

At S7, inverse-CDF sample by binary search or a 10-bit direct index plus two refinement steps. This gives a stable draw independent of worker count and avoids evaluating a UI spline on workers. A curve edit invalidates only stages that consume it. Store the LUT version in the cache key.

```cpp
float inverseCdf(const CdfLut& lut, float u) {
    u = clamp(u, 0.0f, nextafter(1.0f, 0.0f));
    u32 i = upperBound(lut.cdf, u);
    float a = lut.cdf[i-1], b = lut.cdf[i];
    float t = (b > a) ? (u-a)/(b-a) : 0.0f;
    return lerp(lut.x[i-1], lut.x[i], t);
}
```

[OPEN] Verify whether Forest curves are probability distributions or ordinary min/max remaps. The inverse-CDF implementation is required by this brief and is the Cyrus interpretation.

### 5.2 Transform maps

Map semantics are explicit:

* mono map: black means the minimum random value, white means the maximum;
* RGB map: red, green, and blue independently map X, Y, and Z scales or rotations according to the control using the map;
* probability map: black means no randomization, white means full randomization.

For mono maps, `v = saturate(sampleMono)` and `q = min + v*(max-min)`. For an RGB map, read linearized RGB and map each channel through its corresponding axis range. Do not use display-gamma RGB for scale or angle control. A probability map multiplies the random amplitude, not the stable seed:

```cpp
float p = saturate(mapMono(itemUv));
float q = inverseCdf(curve, stableUnit(key, purpose, seed));
float amplitude = p * q;
value = lerp(minValue, maxValue, amplitude);
```

Black therefore gives the minimum, which for a random offset around zero means no offset only if the range is authored as zero to maximum. For a signed min/max range, the parameter editor should make this explicit and [OPEN] test Forest's black behavior.

Map samples use the S0 `MapSampler` interface and a cache key including map node version, channel, time, and resolution. If a map is missing or black because of a load error, return a neutral sample, not a random substitute, and increment stats.

## 6. Store Transform and Re-Seed

Store Transform is an item-level authored operation. It captures the current computed transform for the selected `StableKey`, writes an `OverrideRecord` as defined in [10, Editing and Scripting](10_EDITING_SCRIPTING.md), and marks `F_OVERRIDDEN`. It then disables the random transform components represented by that override for that item. It must not mutate the global transform parameters and must not replace the candidate's StableKey. The stored record should include base transform space, position, quaternion, scale, mirror, and an optional source time sample.

Re-Seed increments or sets the object's transform seed namespace. Existing candidate keys remain unchanged, so the item set, density thinning, model selection, and area membership do not change. Only random properties whose purpose is in the transform or material namespace change. This is consistent with Forest's Item Editor distinction between Re-Seed and Store Transform. [FP-DOC: Forest Item Editor](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor)

The override application remains S10. S7 computes the procedural transform, S10 replaces it for keys with a transform override, and S11 samples tint and animation after the override has been applied. `D_OVERRIDES` therefore restarts at S10, not S7, unless an override changes model dimensions and the caller requests a conservative S7 restart.

## 7. Animation

### 7.1 Modes

`Disabled` sets `animSample = 0` and uses the source snapshot at evaluation time. `Follow Geometry` evaluates the selected source at the current scene time plus `Time Offset`; each item follows the same source animation phase. `Random Samples` chooses one of `Count` source samples per item using `AnimationSample`, then holds that sample for the item. `Random from Map` remaps the animation map value to a sample index or time interval, with a stable keyed tie-break at boundaries. `Frame from Map` maps a mono value to `[Start, End]` and evaluates the exact frame.

Forest documents all five animation modes, including Random Samples Count and Time Offset, Random from Map grayscale selection among samples, and Frame from Map interpolation from Start to End. [FP-DOC: Forest Animation](https://docs.itoosoft.com/forestpack/forest-plugin/animation) The wording “Random from Map” is [OPEN] only for the internal representation because the public page does not expose whether Cyrus should store a discrete sample index, a normalized time, or a frame. Cyrus should support both internal representations and expose the selected interpretation in diagnostics. Frame from Map is deterministic: black maps to Start and white to End, with clamping.

### 7.2 Per-item sample selection

```cpp
u16 chooseAnimSample(const Population& pop, u32 i,
                     const AnimationParams& a, const MapSampler& maps) {
    if (a.mode == AnimationMode::Disabled) return 0;
    if (a.mode == AnimationMode::FollowGeometry) return 0;
    float u = stableUnit(pop.key[i], RandomPurpose::AnimationSample, a.reseed);
    if (a.mode == AnimationMode::RandomFromMap && a.map) {
        float m = saturate(maps.sampleMono(a.map, pop.uvw[i]));
        u = m * nextafter(1.0f, 0.0f);
    }
    return min<u16>(a.sampleCount - 1, u16(floor(u * a.sampleCount)));
}
```

For Frame from Map, evaluate a source time rather than storing only a sample index. Add a side-table record and quantize `animSample` to an index in a frame table if the renderer requires compact data. Stable sample selection must be independent of viewport versus render evaluation. S11 must not derive samples from the current camera.

### 7.3 Source snapshots and cache

S0 creates immutable source snapshots for each source, time, geometry validity, material state, and animation sample. A snapshot contains mesh topology, bounds, pivot, material slots, and optional motion data. `SharedCacheRegistry` owns deduplicated snapshots, with a per-evaluation reference held until S12 publishes.

The sample cache key is:

```text
(source node identity, source geometry version, source material version,
 source time or frame, animation sample policy, algorithm version)
```

Forest Pack 9 documents automatic animation-sample memory eviction with a default 10 GB cache limit. [FP-DOC: Forest Pack 9 notes](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-9) The default memory cap is therefore 10 GB for the Cyrus compatibility profile. Exact version-specific eviction details remain [OPEN], and a Forest support thread reports a sample-cache cleaning performance issue in Forest Pack 9.0 that was temporarily worked around with `sampleCacheLimit=0`. [FP-OBS: sample cache thread](https://forum.itoosoft.com/forest-pro-beta/slow-custom-edit-mode-on-non-frame-0/) Use a process-wide weighted LRU only for completed immutable snapshots. If a single source exceeds the cap, stream samples and retain only the current and motion-blur neighbor frames. Never evict a snapshot referenced by an in-flight render evaluation.

Store cache accounting by CPU bytes, GPU bytes, topology bytes, and material bytes. Evict least-recently-used entries at 90% cap, stop at 75%, and report pressure. A cache miss may increase render time but must not alter selection or transforms.

### 7.4 Motion blur

For motion blur, render adapters need transforms and source geometry at shutter endpoints or renderer-requested subframes. `Follow Geometry` evaluates source snapshots at each motion sample. `Random Samples` holds the chosen item sample while the source itself may animate. A random frame per blur substep would produce noise and is prohibited. For Frame from Map, the mapped frame is fixed for the item over the shutter unless an explicit “animate map with time” option is added [OPEN].

Compute linear velocity from position samples and angular velocity from quaternion delta. Do not finite-difference across a discontinuity caused by a changed sample index. If source topology changes between frames, mark topology motion unsupported and use renderer fallback, with a warning. Render-time instance targets should expose motion data through the API verified in 09, but this file does not bind SDK calls.

## 8. Material and tint payload

### 8.1 Gradient tint and random strength

S11 starts with the source or item base color in linear working space. A gradient tint evaluates a normalized coordinate, usually height, world altitude, or a user map coordinate. The gradient gives `g`; random strength is a stable draw in `[0,1]` multiplied by the authored strength `s`:

```text
strength = gradientTintStrength * StableRNG(key, TintGradient)
tinted = lerp(baseColor, gradientColor(g), strength)
```

[OPEN] Verify whether Forest random tint chooses a random gradient position, random blend strength, or random color. The proposed design uses random strength because it preserves the gradient spatial relationship while adding item variation.

### 8.2 Map tint

A map tint has two semantic modes:

* `RandomValues`: sample the map during S11, derive stable per-item color values, and pack them into the item payload. This is suitable for renderers that cannot evaluate Cyrus Color at shading time.
* `Texture`: retain a map binding and coordinates in the render material payload. The item tint is a neutral multiplier and the map is evaluated per element or shading point by the Cyrus Color texmap.

If a map is used as a random-value source, never interpret a missing map as a random color. Use white or the configured neutral. If used as a texture, preserve UV channel, mapping transform, and source snapshot identity for 09.

### 8.3 Color correction

Apply correction in a documented working space. Convert linear RGB to a stable perceptual hue representation, shift hue by `hueShift`, clamp or wrap within the authored `hueRange` and `hueWidth`, multiply saturation and brightness, then convert back to linear RGB. For physically sensible output, clamp only at final packing, not between every operation. Negative or NaN values become zero and increment a material diagnostic.

The hue range and width controls have no sufficiently detailed public Forest specification, so the exact wrapping rule is [OPEN]. Proposed rule: width zero means no random hue; nonzero width samples a stable offset around the range center, then applies deterministic hue shift. Saturation and brightness are multiplicative, with defaults one.

### 8.4 Packing into tintRGBA8

Pack after converting to display-linear transfer expected by the renderer payload, unless 09 explicitly requires linear bytes. To avoid ambiguity, `tintRGBA8` is defined as sRGB RGB bytes and a linear alpha multiplier byte. The alpha byte stores `round(saturate(multiplier) * 255)`. If a renderer requires linear RGB, 09 performs the conversion at binding, not by changing the population contract.

```cpp
u32 packTint(Vec3f linearRgb, float multiplier) {
    Vec3f srgb = linearToSrgb(clamp(linearRgb, 0.0f, 1.0f));
    u32 r = roundEven(srgb.x * 255.0f);
    u32 g = roundEven(srgb.y * 255.0f);
    u32 b = roundEven(srgb.z * 255.0f);
    u32 a = roundEven(clamp(multiplier, 0.0f, 1.0f) * 255.0f);
    return r | (g<<8) | (b<<16) | (a<<24);
}
```

Round-to-even makes packing reproducible across CPU vector paths. Store the color correction version in the material cache key.

## 9. Cyrus Color texmap semantics

Cyrus Color is a shading abstraction, not a second population stage. It can expose item and element modes, up to N maps selected by item or element, variation blending, and the blend modes Normal, Color, Additive, Average, and Multiply. S09 owns render plumbing, but S11 must produce the item identity, element identity, tint payload, map coordinates, and variation seed needed by that plumbing.

At the shading math level, define normalized source `C`, map color `M`, and blend amount `a`:

* Normal: `out = lerp(C, M, a)`.
* Color: convert `C` and `M` to HSV, take hue and saturation from `M`, value from `C`, then lerp the result by `a`.
* Additive: `out = C + a*M`.
* Average: `out = lerp(C, (C+M)*0.5, a)`.
* Multiply: `out = C * lerp(1, M, a)`.

Clamp only after the blend chain. Variation blend is a stable scalar derived from the item's tint random purpose, or an element purpose if element mode is active. It must not use a renderer's global random generator.

Item mode selects one map or one map blend per scattered item. Element mode selects based on source face or material element, allowing different parts of one source to vary. The map list limit N is a parameter and capability flag, not a magic constant. If fewer than N maps are assigned, missing slots are neutral. If more are assigned, reject at authoring time with a clear diagnostic rather than silently changing selection.

A map selection function may be:

```cpp
u32 mapIndex(StableKey key, u32 elementId, u32 count, bool elementMode) {
    if (count == 0) return Invalid;
    RandomPurpose p = elementMode ? RandomPurpose::TintGradient
                                  : RandomPurpose::TintGradient;
    u32 salt = elementMode ? elementId : 0;
    return stableInt(key, p, salt, count);
}
```

Use a separate purpose in production if the 01 RNG API supports a sub-purpose field. The item and element mode should produce the same result when a source has one element. This gives an excellent unit test.

### 9.1 Automatic Multi/Sub material consolidation

Forest auto-builds a Multi/Sub material because a single scene node cannot directly carry independent source materials per scattered item without material IDs. [FP-DOC: Forest Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)

Cyrus should consolidate after source snapshots are normalized, before render publication, using a stable key:

```text
(source material identity, renderer, material state version,
 Cyrus Color graph version, item material override, LOD state)
```

Assign deterministic sub-material IDs by sorted stable material identity, not by worker completion order or current list order. `Population` retains `geomId` and the source element material ID. S11 retains tint and Cyrus Color payload. 09 maps those IDs to renderer material slots.

If consolidation is disabled, preserve each source material binding and let the renderer batch by material. If a source material is missing, use a neutral material and issue a warning. A geometry list reorder must not change consolidated IDs for unchanged material identities. An item material override invalidates S11 and the material table, not S1 to S7 unless source dimensions also change.

## 10. Pipeline integration and invalidation

S7 reads `Population.pos`, `normal`, `pathPos`, `scaleFactor`, `geomId`, `key`, and source metadata. It writes `rot`, `scale`, `mirror`, and transient final position corrections. S8 then uses final scale and source bounds. S9 uses the same transform for collisions. S10 may replace fields. S11 reads the post-S10 fields plus time and map samplers and writes `tintRGBA8`, `animSample`.

Suggested dirty-stage table:

| Change | First dirty stage | Reason |
|---|---|---|
| Direction, path follow, random transform, mirror, pivot | S7 | Candidate set and model do not change. |
| Geometry item Scale, dimensions, Z Offset, center displacement | S6 or S7 | Model dimensions may alter S8 and S9. Conservative restart at S6 when source metadata changes. |
| Area falloff scale | S4 | S7 consumes `scaleFactor`. |
| Store Transform or override record | S10 | Apply after procedural S7 output. |
| Animation time, mode, sample count | S11 | Source snapshots may be requested in S0 for render. |
| Tint or Cyrus Color parameters | S11 | No placement effect. |
| Source topology or dimensions | S0 or S6 | Rebuild source snapshot and model metadata. |

Use chunked SoA evaluation. Each worker processes a stable range of population indices, reads immutable maps and source snapshots, and writes disjoint output slices. For map-driven animation, source snapshot requests are collected in a deterministic key set during S0 or a prepass so workers never touch Max.

Cache keys include population version, transform parameter hash, map sampler versions, source snapshot versions, animation policy, and algorithm version. A pure S7 cache can be reused between viewport and render only if it excludes camera-facing transforms. Camera-derived matrices belong to V or the render adapter cache.

## 11. 3ds Max integration

S0 reads ParamBlock2 values and referenced nodes on the main thread. The transform rollout should use degree spinners with linked min and max controls, XYZ color or vector controls, curve editors, map buttons, and explicit units. Re-Seed and Store Transform are undoable buttons. Param block change notifications map to `DirtyBits` and enqueue a coalesced evaluation.

Node target references for Look-At use a Max reference slot and are converted to a snapshot transform. Camera references are copied into a `CameraSnapshot` for render evaluation, but the active viewport camera is not read by workers. Animation source nodes are sampled on the main thread into `SourceSnapshot` objects. Map samplers are baked through the snapshot builder according to 01 and 02 rules.

Do not call `INode::GetObjectTM`, `Texmap::EvalColor`, or any other Max API on a worker. A Max-layer `TransformNotificationAdapter` can translate time changes, node changes, and map changes into dirty groups.

## 12. Edge cases and failure modes

* A zero or near-zero normal uses Direction, then +Z. Log the candidate key and surface id.
* A Direction parallel to the normal uses a deterministic orthogonal fallback.
* A path tangent of zero uses the preceding valid tangent, then +X.
* A coincident Look-At target preserves the base frame.
* A 180 degree Look-At vector uses a stable perpendicular axis derived from the up vector.
* NaN or infinite map samples become neutral values and increment map error stats.
* Negative scales are rejected and represented through mirror bits only.
* Zero scale makes the item non-renderable and skips collision sphere inversion.
* A missing source snapshot marks `F_ALIVE` false at publish only if the source is required; otherwise a proxy placeholder is emitted according to display policy.
* An animation source whose topology changes between blur samples falls back to a static sample and warns.
* A tint map with no UV uses object or world coordinates according to the map sampler's declared fallback.
* Material consolidation collisions are resolved by stable material identity, never by array position.
* Changing Re-Seed must not change density thinning or geometry choice. This is a golden determinism test.
* Camera movement must not change canonical `rot`, `scale`, `mirror`, `tintRGBA8`, or `animSample` unless a view-dependent animation or Facing Camera render payload is explicitly requested.

## 13. Performance and memory targets

[DESIGN] On a 16-core desktop, S7 should process 1M surviving candidates in under 120 ms when source metadata and maps are cached, and S11 should process 1M candidates in under 100 ms with no texture-mode renderer calls. These are targets to measure, not guarantees.

Keep transform working data under 64 bytes per item beyond the architecture's hot output. Do not allocate quaternions or matrices per candidate. Use SIMD-friendly float vectors and scalar double only for source positions whose extent requires it. The largest transient is animation source snapshots. Enforce the 10 GB sample cache cap, but prefer per-evaluation streaming when many source frames are requested.

The main traps are repeated map evaluation, per-item source mesh duplication, cache misses caused by unstable material keys, and camera-dependent transforms invalidating point-cloud caches. S7 must not read a render camera for ordinary surface alignment. S11 must not call renderer material code in worker threads.

## 14. Tests and Forest Lite comparison scenes

### 14.1 Unit tests

1. Base frame with normals +Z, +X, and degenerate zero vectors.
2. Direction parallel and anti-parallel to the normal.
3. Path X and Z alignment on straight and curved paths, including a 180 degree tangent turn.
4. Quaternion Euler order against known axis rotations.
5. Scale multiplication including height-only falloff and mirror determinant.
6. Percentage jitter conversion for width and height, with stable purpose isolation.
7. CDF integration, monotonicity, inverse-CDF endpoints, and zero-area fallback.
8. Mono and RGB map semantics, black and white endpoints, linear RGB handling.
9. Store Transform round trip through the override serializer.
10. Re-Seed changes transforms but not keys, density, or model selection.
11. Animation sample stability across thread counts and map values at endpoints.
12. Motion blur sample holding and topology-change fallback.
13. Tint packing byte exactness and blend-mode equations.
14. Cyrus Color item mode versus element mode with one and multiple elements.
15. Material consolidation identity and list reorder stability.

### 14.2 Golden scenes

* Flat plane, one billboard, no randomization: validates pivot, width, height, Z Offset, and center displacement.
* Uneven mesh, normal alignment, custom Direction: validates surface frame.
* Curved Path with X and Z follow: validates tangent frame and random local rotations.
* One-plane billboard with Facing Camera: orbit camera in viewport and render, verifying canonical population stays stable.
* Three source objects with 1:2:7 scale probabilities and Re-Seed: validates model and transform purpose separation.
* Mono, RGB, and probability maps with black, mid-gray, and white tiles.
* Animated mesh with all five animation modes and motion blur enabled.
* Gradient and random tint with Cyrus Color item and element modes.
* Source materials consolidated, then geometry list reordered, proving stable sub-material IDs.

Compare Cyrus exports using key, base position, quaternion, scale, mirror, tint, and animation sample. Forest output is an observable reference, not a bitwise target. Record unresolved transform ordering as [OPEN] in the comparison report.

## 15. Open questions

1. [OPEN] What is Forest's exact transform multiplication order for base frame, path, Look-At, random rotation, mirror, scale, pivot, center displacement, and Z Offset?
2. [OPEN] Is Direction world-space, Forest-local, or a path-only control?
3. [OPEN] Is Z Offset along world Z, Forest-local Z, or the surface normal on uneven surfaces?
4. [OPEN] Does Forest use intrinsic XYZ, ZYX, or another Euler rotation order?
5. [OPEN] Are random position percentages measured against width, height, local bounds, or another size metric?
6. [OPEN] Does Facing Camera occur before or after random rotation, and is random rotation camera-relative?
7. [OPEN] Are transform curves inverse-CDF probability curves or ordinary remap curves in each rollout?
8. [OPEN] Does Random from Map select a discrete sample, a normalized source time, or a frame?
9. [OPEN] What exact memory accounting and eviction rules apply to Forest's 10 GB animation sample cache, and does the cap vary by version?
10. [OPEN] Does Forest pack tint bytes as linear or sRGB RGB, and what exactly does alpha represent in each renderer?
11. [OPEN] What is the maximum Cyrus Color map count N in supported Forest-compatible workflows?

## 16. Architecture feedback

The architecture's fixed S7 then S11 ordering is sound. One extension is necessary: camera-facing orientation must not overwrite canonical `Population.rot`. Add an optional per-view derived transform buffer to `ViewMask` or the render view context. A second extension is an animation sample side table because `Population.animSample` alone cannot represent Frame from Map's arbitrary frame or motion-blur source snapshots. Finally, distinguish `scaleFactor` from area random scale so deterministic falloff and random area scale remain independently invalidatable.

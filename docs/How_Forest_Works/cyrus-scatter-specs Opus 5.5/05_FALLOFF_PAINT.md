# 05: Falloff and Paint Areas

## 1. Purpose and scope

This specification defines area-boundary falloff, altitude falloff, curve evaluation, density thinning, and the Paint Area type. It implements the falloff portion of S4 and S5 in `00_ARCHITECTURE.md`, while reusing Cyrus's existing surface-anchored stroke paint engine. The paint engine is the source of coverage truth. This file defines the adapter that exposes that coverage as an Area query, not a second brush implementation.

The intended reader is the engineer implementing core C++20 code and the Max adapter. Every data structure in the core is free of Max headers. Max PainterInterface, scene references, notifications, undo, and viewport invalidation stay in L4. The core receives immutable surface snapshots and immutable paint documents, then updates derived caches on worker threads in deterministic order.

In scope:

* Include and Exclude boundary ranges, separate Density and Scale curves, Falloff Affect, Invert Curve, Affect Height only, and altitude falloff.
* A proposed combination rule for multiple areas, with explicit compatibility tests because Forest's exact algebra is not public.
* Bezier and piecewise cubic curves, LUT evaluation, monotone options, and preview overlays.
* Density thinning that is stable under edits and monotone under paint and erase.
* Camera-distance falloff as an interface only. Its detailed view-pass behavior belongs to 08.
* Paint Area coverage, inside thresholding, signed distance from a coverage field, Include and Exclude semantics, brush settings, pressure, modifiers, conversions, dirty regions, preview, and undo.
* Reuse of the existing Cyrus paint engine: surface anchors, strength and softness, paint and erase affine blend operators, maximum within a stroke, maximum across Paint Areas, PainterInterface, persistent preview structures, and candidate coverage caches.
* Incremental S1 to S9 re-evaluation and the reason Cyrus avoids Forest's stroke-to-spline rebuild lag.

Out of scope: the Max render shader implementation for Edge mode, camera distance evaluation details, geometry diversity, collisions, and the full Effects VM. This file specifies their input contracts.

**Why coverage is an interface:** a spline, raster mask, or PaintField can all answer the same Area query. S3 need not know how a PaintField is represented, and S4 can ask for distance without walking saved stroke history.

## 2. Forest Pack behavior to match

* **[FP-DOC]** Forest Area falloff can affect Density, Scale, or both. Include Range measures from Include spline or surface boundaries; Exclude Range measures from Exclude object, Forest, or spline boundaries. Density and Scale have separate curves. Source: [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas).
* **[FP-DOC]** The default displayed curve is linear. The curve editor shows a distance or remaining-effect axis from 100% to 0% and an output from 0% to 100%. The exact internal orientation is not public, so Cyrus normalizes distance explicitly. Source: [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas).
* **[FP-DOC]** Falloff Affect controls strength, and zero disables area falloff. Invert Curve reverses the effect. Affect Height only applies Scale falloff to height and leaves X and Y unchanged. Source: [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas).
* **[FP-DOC]** Altitude falloff is separate from boundary falloff and is applied over Surface Altitude Range Top and Bottom values. Source: [Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).
* **[FP-DOC]** Effects attributes expose nearest Include and Exclude distances and positions plus applied falloff scale, which confirms that distance is a useful observable contract. Source: [Effects attributes](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes).
* **[FP-OBS]** Support describes Include and Exclude range controls as global in some Forest releases. This file allows a per-area curve and range as a Cyrus improvement while retaining object-level defaults for compatibility. Source: [Falloff from spline area](https://forum.itoosoft.com/forest-pro-(*)/densityscale-falloff-from-spline-area/).
* **[FP-DOC]** Paint Areas are parametric Include or Exclude regions painted onto terrain, require a Surface in XY mode in the documented workflow, and should normally have the Surface Area switched Off when paint is the intended boundary. Source: [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas).
* **[FP-DOC]** Paint exposes Paint, Erase, Painter Settings, Brush Size, Preview Falloff, and Convert to Spline. Brush pressure controls are documented, but public pages omit many numeric defaults. Source: [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas).
* **[FP-DOC]** The documented modifier assignment varies by release: one page describes Ctrl as Erase, while FP9.3 notes Ctrl for Paint and Alt for Erase. Cyrus exposes configurable modifiers and records the resolved operation in the stroke, rather than relying on a future keyboard assignment. Sources: [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas), [Forest Pack 9.3](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-9-3).
* **[FP-OBS]** iToo support describes Forest Paint as a spline rebuilt as the artist paints. Lag grows more than linearly with area complexity. Recommended workarounds include multiple Paint Areas or Convert to Spline. Sources: [Area Brush lag](https://forum.itoosoft.com/forest-pro-(*)/area-brush-tool-is-lag-and-not-responsive/), [Paint slow](https://forum.itoosoft.com/forest-lite/forest-pack-using-64gb-ram-and-im-not-ever-scattering-anything/).
* **[FP-DOC]** Paint can convert to a spline and a spline can convert to Paint. The exact contour algorithm and simplification tolerance are private, so Cyrus defines them as explicit deterministic choices.
* **[INFERRED]** Cyrus's existing engine should retain ordered strokes as authored truth, use a surface-anchored coverage field for queries, and maintain separate per-area fields combined by maximum. The research prototype establishes why a persistent interval preview hierarchy and candidate cache make appended strokes local without changing coverage semantics. Sources: [Surface Painting Architecture](https://app.clickup.com/90122138736/docs/2kxv5d3g-532/2kxv5d3g-72), [Technical deep dive](https://app.clickup.com/90122138736/docs/2kxv5d3g-532/2kxv5d3g-192), [Revision 2](https://app.clickup.com/90122138736/docs/2kxv5d3g-532/2kxv5d3g-212).

## 3. Parameters

Percent values are normalized to 0 to 1 in the core. Distances are system units. A public Forest default that is not numeric remains marked [FP-DOC] without a guessed value; proposed Cyrus defaults are explicitly [DESIGN].

### 3.1 Falloff parameters

| UI name | Internal name | Type | Default | Range and units | Rollout | DirtyBits group | Notes |
|---|---|---:|---:|---|---|---|---|
| Density falloff On | `falloffDensityOn` | bool | true | on or off | Areas | `D_FALLOFF(id)` | Separate from Scale. |
| Scale falloff On | `falloffScaleOn` | bool | true | on or off | Areas | `D_FALLOFF(id)` | Separate from Density. |
| Include range | `includeRange` | double | 0 [DESIGN] | system units, 0 means no range | Areas | `D_FALLOFF(id)` | Range from Include boundary. |
| Exclude range | `excludeRange` | double | 0 [DESIGN] | system units, 0 means no range | Areas | `D_FALLOFF(id)` | Range from Exclude boundary. |
| Density curve | `densityCurve` | Curve1D | linear | normalized | Areas | `D_FALLOFF(id)` | Independent curve. |
| Scale curve | `scaleCurve` | Curve1D | linear | normalized | Areas | `D_FALLOFF(id)` | Independent curve. |
| Falloff Affect | `falloffAffect` | float | 1 | 0 to 1 | Areas | `D_FALLOFF(id)` | 0 disables this area contribution. |
| Invert Curve | `invertCurve` | bool | false | on or off | Areas | `D_FALLOFF(id)` | Inverts output around 1. |
| Affect Height only | `affectHeightOnly` | bool | false | on or off | Areas | `D_FALLOFF(id)` | Scale only; leaves X and Y. |
| Altitude Density On | `altDensityOn` | bool | false [DESIGN] | on or off | Surfaces | `D_SURFACE_FILTER` | Uses surface Top and Bottom. |
| Altitude Scale On | `altScaleOn` | bool | false [DESIGN] | on or off | Surfaces | `D_SURFACE_FILTER` | Separate factor. |
| Altitude Density curve | `altDensityCurve` | Curve1D | linear | normalized | Surfaces | `D_SURFACE_FILTER` | Stored with surface params. |
| Altitude Scale curve | `altScaleCurve` | Curve1D | linear | normalized | Surfaces | `D_SURFACE_FILTER` | Stored with surface params. |
| Curve monotone | `curveMonotone` | bool | true [DESIGN] | on or off | Curve editor | `D_FALLOFF(id)` | Prevents overshoot at control points. |
| Preview Falloff | `previewFalloff` | bool | true [FP-DOC] | on or off | Paint | `D_PAINT_PREVIEW(id)` | Overlay and viewport density preview. |
| Camera falloff enabled | `cameraFalloffOn` | bool | false [DESIGN] | on or off | Camera | `D_CAMERA_FALLOFF` | Evaluation contract for 08. |

### 3.2 Paint area and brush parameters

| UI name | Internal name | Type | Default | Range and units | Rollout | DirtyBits group | Notes |
|---|---|---:|---:|---|---|---|---|
| Paint operation | `paintOp` | enum | Paint | Paint, Erase | Areas | `D_PAINT_STROKES(id)` | Operation is saved in each stroke. |
| Coverage threshold | `insideThreshold` | float | 0.5 [DESIGN] | 0 to 1 | Areas | `D_PAINT_PARAMS(id)` | Include inside test and contour iso-level. |
| Brush minimum size | `brushMinRadius` | double | 1.0 [DESIGN] | system units | Painter | `D_PAINT_PARAMS(id)` | Forest numeric default is unknown. |
| Brush maximum size | `brushMaxRadius` | double | 100.0 [DESIGN] | system units | Painter | `D_PAINT_PARAMS(id)` | Clamp protects scene scale. |
| Strength | `brushStrength` | float | 1 | 0 to 1 | Painter | `D_PAINT_PARAMS(id)` | Maps to q amplitude. |
| Softness | `brushSoftness` | float | 0.5 [DESIGN] | 0 to 1 | Painter | `D_PAINT_PARAMS(id)` | 0 hard edge, 1 full soft ramp. |
| Pressure enabled | `pressureEnabled` | bool | true [FP-DOC] | on or off | Painter | `D_PAINT_PARAMS(id)` | Tablet pressure multiplies size or strength per mode. |
| Pressure affects | `pressureTarget` | enum | Strength | Strength, Radius, Both | Painter | `D_PAINT_PARAMS(id)` | Explicit Cyrus choice. |
| Dab spacing | `dabSpacing` | float | 0.1 [DESIGN] | 0.01 to 1 radii | Painter | `D_PAINT_PARAMS(id)` | Resampling interval in captured space. |
| Ctrl modifier | `ctrlMode` | enum | Erase | None, Paint, Erase | Painter | `D_PAINT_PARAMS(id)` | Version-stable configurable mapping. |
| Alt modifier | `altMode` | enum | Erase | None, Paint, Erase | Painter | `D_PAINT_PARAMS(id)` | If both, explicit priority is required. |
| Projection | `paintProjection` | enum | XY | XY, UV | Painter | `D_PAINT_PARAMS(id)` | XY requires surface; UV needs fixed Project Axis. |
| Convert to Spline | `convertTolerance` | double | 0.5 [DESIGN] | system units | Paint | `D_PAINT_CONVERSION(id)` | Simplification tolerance. |
| Paint cache resolution | `previewResolution` | u32 | adaptive | 16 to 512 samples per face | Paint | `D_PAINT_PREVIEW(id)` | Derived per-face lattice, not a saved truth. |

## 4. Data structures

These structures extend `00_ARCHITECTURE.md`. The existing `Population::densityFactor`, `Population::scaleFactor`, `incDist`, and `excDist` remain the output channels. The existing `StableKey` and purpose-specific StableRNG are used for thinning. The paint document and derived caches are separate because authored strokes are truth and caches are rebuildable.

```cpp
namespace cyrus {

enum class BrushOp : u8 { Paint, Erase };
enum class PressureTarget : u8 { Strength, Radius, Both };
enum class CurveKind : u8 { PiecewiseCubic, Bezier };

typedef u64 PaintStrokeId;
typedef u32 PaintAreaId;
typedef u32 PaintReceiverFace;

struct CurvePoint { float x, y; };
struct CurveSegment {
    CurvePoint p0, p1, p2, p3;
};
struct Curve1D {
    CurveKind kind;
    bool monotone;
    std::vector<CurveSegment> segments;
    std::array<float, 1024> lut;
    u64 revision;
};

struct PaintDab {
    Vec3d surfacePosition;
    u32 faceIndex;
    Vec3f barycentric;
    float radius;
    float strength;
    float pressure;
    u32 visibilityFlags;
    u64 ordinal;
};

struct PaintStroke {
    PaintStrokeId id;
    PaintAreaId areaId;
    BrushOp op;
    u64 sequence;
    SurfaceProjection projection;
    u32 receiverSurfaceId;
    u64 capturedTopologyVersion;
    Mat4d capturedSurfaceToFL;
    std::vector<PaintDab> dabs;
};

struct PaintDocument {
    u64 revision;
    std::vector<PaintStroke> strokes;     // immutable snapshot order
    float insideThreshold;
};

struct AffineCoverage { float a, b; }; // v' = a + b*v
struct CoverageInterval { float lo, hi; };

enum class PreviewNodeState : u8 { Empty, Full, Mixed };
struct PreviewNode {
    u32 firstChild;
    CoverageInterval interval;
    u8 depth;
    PreviewNodeState state;
};
struct CoverageVertexKey { u32 face; u16 i, j; };
struct PaintPreviewTree {
    std::vector<PreviewNode> nodes;
    FlatHashMap<CoverageVertexKey, float> vertices;
    u64 builtRevision;
};

struct CandidatePaintCache {
    FlatHashMap<StableKey, float> coverage;
    FlatHashMap<StableKey, u8> accepted;
    u64 paintRevision;
    u64 areaRevision;
};

struct PaintField {
    PaintDocument document;
    std::vector<PaintPreviewTree> perAreaPreview;
    std::vector<CandidatePaintCache> perAreaCandidates;
    u64 receiverTopologyVersion;
    u64 fieldRevision;
};

struct FalloffFactors {
    float densityBoundary = 1;
    float scaleBoundary = 1;
    float densityAltitude = 1;
    float scaleAltitude = 1;
    float density = 1;
    Vec3f scale = {1,1,1};
};
}
```

The `PaintDab` stores a surface anchor and barycentrics, not only a world point. This keeps paint attached to a receiver face and avoids UV seam problems. Topology changes are detected by the receiver topology version. If topology changes, Cyrus attempts closest-point remapping from the captured position, then re-projection from the captured view if enabled, and otherwise marks the stroke unresolved. It never silently applies stale barycentrics.

### 4.1 Coverage semantics from the existing engine

For a point `p`, each dab has an influence `q_d(p)` in 0 to 1 from strength, pressure, radius, softness, and visibility. Within one stroke:

```text
q_stroke(p) = max over dabs q_d(p)
```

Across ordered strokes, Paint and Erase use the existing affine operators:

```text
Paint: v'  = q + (1 - q) * v
Erase: v'  = (1 - q) * v
```

Both are `v' = a + b*v`, where Paint has `a=q, b=1-q` and Erase has `a=0, b=1-q`. Across separate Paint Areas, the documented research decision is to retain one field per Area and combine with `max` at read time. Thus erasing Area A cannot reveal a lower value from A after Area B has been erased: if A was 0.8, B was 0.6, and A erases to 0.4, the combined value remains 0.6. This is the key reason not to save only one combined field.

## 5. Falloff curve model and algorithms

### 5.1 Curve representation

The curve editor stores normalized points in x and y. Cyrus supports cubic Bezier segments and piecewise cubic Hermite segments. Segment x intervals must be nondecreasing. When `monotone` is true, tangents are generated with a monotone cubic method and clamped to avoid overshoot. When false, explicit handles are honored, but evaluation still clamps the final y to 0 to 1.

At S0, validate points, sort only by authored sequence where legal, split segments at duplicate x values, and build the 1024-entry LUT. The LUT is a derived cache keyed by curve revision. Evaluate with a binary search over x and one cubic interpolation. For a high-throughput S4 tile, use a uniform LUT index and linear interpolation, then run exact cubic evaluation only when the LUT error estimate exceeds the configured tolerance. The default tolerance is 1e-4 [DESIGN].

The UI displays Forest's 100% to 0% direction, but the core uses distance normalized outward:

```cpp
float normalizedDistance(double d, double range) {
    if (!(range > 0) || !std::isfinite(d)) return 1.0f;
    return float(clamp(d / range, 0.0, 1.0));
}
```

For an Include, `d=0` means the boundary and `d=range` means fully away from the boundary. A curve is authored as `effectAtDistance`, where 1 means no reduction and 0 means maximum reduction unless Invert Curve changes it. This convention keeps the pipeline independent of UI axis direction.

### 5.2 Boundary factor

For each applicable Area, obtain `incDist` or `excDist` from S3. Compute an area-side factor:

```cpp
float sideFactor(float distance, float range, const Curve1D& curve,
                 float affect, bool invert) {
    if (affect <= 0 || range <= 0 || !std::isfinite(distance)) return 1.0f;
    float u = clamp(distance / range, 0.0f, 1.0f);
    float f = curve.evalLUT(u);       // 0 to 1 reduction/effect convention
    if (invert) f = 1.0f - f;
    float blended = lerp(1.0f, f, clamp(affect, 0.0f, 1.0f));
    return clamp(blended, 0.0f, 1.0f);
}
```

The exact endpoint interpretation is [OPEN]. The proposed default is a curve output of 0 at the boundary and 1 outside the range for ordinary fade-out, with Invert Curve producing the complementary effect. For an Include candidate, use nearest applicable Include distance. For Exclude, use nearest applicable Exclude distance. `Falloff Affect` linearly blends the curve result toward neutral 1, so zero is a no-op.

### 5.3 Multiple-area combination

Forest's complete overlap algebra is not public. Cyrus proposes **nearest-boundary-per-side, then multiply** [DESIGN]:

1. Gather each active Include contribution that owns or affects the candidate. Select the smallest finite Include distance and evaluate that area's Density and Scale curves.
2. Gather each active Exclude contribution that applies to the candidate. Select the smallest finite Exclude distance and evaluate that area's curves.
3. Multiply Include and Exclude factors with altitude factors and the distribution density map.
4. Clamp all factors to 0 to 1.

This choice is stable, local, and avoids order-dependent products from a large number of overlapping boundaries. It also matches the public Effects attributes that expose nearest Include and Exclude distances. It is explicitly **[OPEN]** whether Forest multiplies, sums, takes minimum, or uses last-write for multiple boundaries. Test these scenes: two concentric Includes, two adjacent Includes, Include plus Exclude, overlapping Excludes with different curves, and a Paint area over a Spline area.

The per-area owner and nearest boundary identity remain in diagnostics even when only one contribution is selected. A Cyrus improvement can offer `MultiplyAll` and `Minimum` compatibility modes for experiments, but only the proposed nearest-per-side mode is allowed as the default in saved algorithm version 1.

### 5.4 Density and Scale channels

S4 retains channels until the end:

```cpp
FalloffFactors evaluateFalloff(const ItemContext& x) {
    FalloffFactors f;
    f.densityBoundary = boundaryDensity(x);
    f.scaleBoundary = boundaryScale(x);
    f.densityAltitude = altitudeDensity(x);
    f.scaleAltitude = altitudeScale(x);
    f.density = clamp(f.densityBoundary * f.densityAltitude, 0, 1);
    float s = clamp(f.scaleBoundary * f.scaleAltitude, 0, 1);
    f.scale = x.affectHeightOnly ? Vec3f{1,1,s} : Vec3f{s,s,s};
    return f;
}
```

`Population.densityFactor` receives `f.density`. `Population.scaleFactor` receives the multiplicative vector, preserving a height-only scale as `(1,1,s)`. S7 composes this with geometry and random scales. The scale factor should not alter collision radius until S9 sees final S7 scale. Density is not yet a cull in S4. S5 performs stable thinning and sets `F_CULL_DENSITY`.

### 5.5 Altitude falloff

If the surface Altitude Range is Limited, S3 has already culled items outside Bottom and Top. If altitude falloff is enabled, normalize:

```cpp
float h = clamp((altitude - bottom) / max(epsilon, top - bottom), 0, 1);
float density = altDensityCurve.evalLUT(h);
float scale = altScaleCurve.evalLUT(h);
```

Altitude orientation is a [DESIGN] choice: h=0 is Bottom and h=1 is Top. Invert Curve is not applied to altitude unless explicitly exposed as a separate surface option. Keep the four channels separate because a user can request Density falloff without Scale, or Scale with Affect Height only.

### 5.6 Camera-distance falloff interface

The View pass in 08 computes camera distance and a camera falloff factor. S4 accepts a `CameraFalloffSampler` interface but does not call Max camera APIs:

```cpp
struct CameraFalloffSampler {
    virtual float densityAt(Vec3f flPos, float current) const = 0;
    virtual float scaleAt(Vec3f flPos, float current) const = 0;
};
```

In Render mode, camera factors are applied in the view-dependent mask unless a parameter explicitly opts into population-affecting falloff. Default is view-only so orbiting never reshuffles stable candidates. The interface is here to reserve the factor path; 08 defines camera ranges, view invalidation, LOD, and per-view density.

## 6. Paint Area adapter

### 6.1 Area query contract

S3 calls a Paint Area through a narrow contract:

```cpp
struct PaintQueryResult {
    float coverage;          // 0 to 1, max across this Area's field
    bool inside;             // coverage >= insideThreshold
    double signedDistance;   // positive inside, negative outside where known
    bool distanceExact;
    u64 fieldRevision;
};

class IPaintAreaQuery {
public:
    virtual PaintQueryResult query(const SurfacePoint& p,
                                   float threshold) const = 0;
    virtual AABB3d dirtyBounds() const = 0;
    virtual u64 revision() const = 0;
};
```

The query requires the same `SurfacePoint` produced by S2: receiver ID, face index, barycentrics, FL position, normal, and UVW. A world point alone is insufficient on stacked or folded receivers. In XY mode, PainterInterface hit points are projected onto the active surface and stored as surface anchors. In UV mode, Project Axis must be selected before the first stroke and changing it invalidates or requires an explicit reproject operation.

Include uses `inside = coverage >= threshold`. Exclude uses the same test to cull lower candidates. A soft coverage does not automatically mean a candidate is partially present. S5 uses coverage as a density factor, so a point with coverage 0.3 can survive with a 0.3 probability under a stable hash. If a user wants a hard mask, threshold is set to 1 or a hard brush is used.

### 6.2 Distance to a coverage field

A PaintField does not have a single geometric border while coverage is soft. For falloff and Size checks, Cyrus defines the boundary as the coverage iso-contour at `insideThreshold`. The engine supplies one of three distance modes:

1. **Sparse signed distance cache:** for touched faces and preview cells, compute distance to the threshold contour using the existing preview hierarchy and a local distance transform. Positive is inside, negative outside.
2. **Contour distance:** use the latest extracted marching-squares contour and a spatial index. This is exact only relative to the contour tolerance.
3. **Fallback:** return `distanceExact=false` and query the conservative distance to touched PaintField support. Point mode remains valid, but Size and falloff report a diagnostic if no certified distance exists.

A face-local signed distance avoids world-cell leakage between nearby sheets. Coverage caches are per Paint Area and per receiver face. For a triangle with a barycentric sample, find neighboring samples whose values straddle the threshold, linearly interpolate an edge crossing, and compute the nearest segment distance. If no crossing exists in the face, use the interval state: all below means negative, all above means positive, and mixed unresolved means refine before returning a distance.

### 6.3 Paint and erase blending

A brush dab computes distance in captured surface space. Radius and softness are applied as:

```cpp
float dabInfluence(const PaintDab& d, Vec3d p) {
    float r = max(d.radius, 1e-9f);
    float q = 1.0f - float(distanceCaptured(d, p) / r);
    q = clamp(q, 0.0f, 1.0f);
    float hard = 1.0f - d.softness; // stored in stroke settings or dab
    q = q <= hard ? 1.0f : smoothstep(1.0f, hard, q);
    return clamp(q * d.strength * pressureFactor(d), 0.0f, 1.0f);
}
```

The exact falloff kernel is an existing engine contract. Do not introduce a second kernel here. Within one gesture, dabs combine by maximum, not repeated paint operations. This prevents two overlapping 0.5 dabs in one stroke from becoming 0.75. Across committed strokes, apply the saved operation order with the affine formulas. Paint and erase do not reorder when a brush crosses tiles.

### 6.4 Pressure and modifiers

PainterInterface provides screen hit points, pressure where supported, and stroke callbacks. Radius and strength are sampled per dab. The configured Pressure Target determines whether pressure multiplies radius, strength, or both. If a tablet reports no pressure, use 1.0. Record the resolved pressure and operation in the dab so replay is independent of the device.

Modifier mapping is configurable because public Forest pages disagree across versions. At stroke start, resolve Ctrl and Alt to Paint or Erase, with Alt priority when both are held [DESIGN]. Save the operation in `PaintStroke.op`. Releasing a modifier does not rewrite earlier dabs.

## 7. Incremental paint evaluation

### 7.1 Authoritative document and derived caches

Saved truth is ordered strokes, their surface anchors, captured transform and projection, brush parameters, and receiver identity. Compiled dabs, face links, preview nodes, candidate values, accepted bits, contours, and GPU buffers are derived. A cache may be discarded and rebuilt from strokes.

The existing engine's revision guidance is followed:

* Keep a persistent per-face preview hierarchy with certified coverage intervals.
* Keep a fixed pre-stroke value `c0` and pending maximum influence `qPending` during an active gesture.
* Store one candidate coverage cache per Paint Area. Combine Area values by maximum at read time.
* Keep explicit receiver topology, strokes, preview, GPU, and population versions.
* Use exact interval decisions for candidate membership, and optional epsilon only for display values.

A preview node stores `[lo, hi]`, which is a conservative coverage interval over its face region. For a stroke influence range `[qlo, qhi]`, monotone composition is:

```text
Paint: lo' = qlo + (1-qlo)*lo, hi' = qhi + (1-qhi)*hi
Erase: lo' = lo*(1-qhi),       hi' = hi*(1-qlo)
```

This catches a small painted island inside a large triangle even when all corner samples are zero. It also lets a node skip a stroke whose qhi is zero. A node may become Full only when its certified interval proves coverage 1 under the selected tolerance. On undo, structural edits and before-values are restored through a delta, not by trying to invert affine maps.

### 7.2 Active gesture stencil

Do not copy the entire document for every mouse move. For each touched cell or vertex:

```text
base = coverage of committed strokes before gesture
qPending = max influence of dabs received in current gesture
Paint display = qPending + (1-qPending)*base
Erase display = base*(1-qPending)
```

On a new dab, update only cells in its surface support, mark preview chunks dirty, and request one coalesced redraw. On release, append one stroke to the immutable document, apply its exact affine update to candidate caches, run local collision fix-up if needed, and push one undo delta. On cancel, clear `qPending`; no authored data changes.

### 7.3 Stable candidate coverage and S5

S1 candidates are independent of Paint coverage. Candidate identity is determined by `StableKey` and the generator algorithm, not by whether a brush currently covers it. For each candidate and Paint Area, update coverage with the new stroke's affine map. At S5, derive a fixed uniform `u` from `hash(sceneSeed, StableKey, Purpose::PaintDensity, areaId)` and accept when:

```cpp
bool keep = coverage * otherDensityFactor > u;
```

As coverage increases, acceptance can only change from false to true for Paint, and only from true to false for Erase. This monotone thinning ensures that painting more does not reshuffle unrelated items. It also means a small dirty region changes only candidates in that region, subject to collision dependencies in S9.

For a cold candidate not present in the cache, use an exact decision walk over newest strokes, maintaining `[acc, acc+P]` until the interval lies entirely above or below the threshold. This is exact and often visits far fewer strokes than waiting for `P=0`. For display value queries, use the cached value or a declared epsilon mode such as 1/4096; never use the epsilon result for candidate membership.

### 7.4 Dirty regions and pipeline re-evaluation

Each dab produces a receiver-face support set and FL AABB. The dirty region is the union of old and new support for edits and Undo, expanded by:

* the maximum Paint brush radius and falloff range;
* the S8 boundary footprint;
* the S9 collision radius and its halo;
* any linked area or Forest Area dependency that samples the changed population.

A new Paint stroke normally re-evaluates S1 to S9 only for candidates whose surface points intersect the dirty support. In v1, the architecture may restart the whole population from S3 or S4 while preserving stable candidates. The tile-local optimization is the target because PaintArea revisions should not rebuild untouched tiles. S10 overrides and S11 shading consume the changed candidate set and publish a new immutable population version.

The dirty bit map adds `D_PAINT_STROKES(id)`, `D_PAINT_PARAMS(id)`, `D_PAINT_PREVIEW(id)`, and `D_PAINT_CONVERSION(id)`. Brush preview changes affect only viewport overlay and pending population; committing a stroke affects S3 onward. Changing the threshold affects S3 to S9 because inside tests and distances change. Changing a curve affects S4 to S9. Changing projection or receiver topology starts at S1 or S2 as appropriate.

### 7.5 Collision locality

Paint thinning is local, but collision rejection can spread. S9 uses the 00 architecture's deterministic priority. For a dirty region, expand by two times the largest collision radius, recompute accepted candidates by fixed priority, and grow again if an acceptance change reaches the border. If the dependency chain does not settle by the configured iteration cap, fall back to a full S9 pass. This preserves deterministic output while keeping ordinary strokes local.

## 8. Convert to Spline and spline to Paint

### 8.1 Paint to spline

Convert at the current threshold. On each face, extract cell edges where coverage crosses `insideThreshold`, using marching squares on the preview lattice. For triangular receiver faces, use a barycentric triangle contour extractor rather than assuming a quad. Stitch segments across shared face edges only when receiver face adjacency and threshold crossings agree. Do not stitch across disconnected sheets or UV seams without an explicit adjacency edge.

Project the contour to the selected area plane. Simplify with a deterministic Ramer-Douglas-Peucker tolerance `convertTolerance`, then remove collinear points and preserve holes. Preserve closed loops and open fragments separately. Create a new Spline Area or replace the Paint Area only after a confirmation transaction. The paint strokes remain available in Undo and can be retained as a hidden source if the user chooses non-destructive conversion.

The contour is an approximation to a soft field. The UI reports the threshold, simplification tolerance, unresolved faces, and maximum measured contour error. If the field has no distance-certified preview nodes, refine those nodes before conversion.

### 8.2 Spline to paint

Rasterize or sample the source spline against surface faces in the active projection. Generate a synthetic stroke document or a baked PaintField according to the user's choice. The preferred non-destructive conversion stores a `SplineSeed` source and generates paint coverage through a deterministic contour distance query, but if the saved format requires strokes, emit a centerline stroke set with a boundary-preserving simplification and mark the conversion approximate. The UI must not imply that arbitrary splines can be exactly represented by a finite dab set.

Because Forest's public conversion details are private, Cyrus's exact conversion tolerance, sampling density, and whether a converted spline remains linked are [OPEN]. Tests compare region area, boundary Hausdorff distance, and candidate membership rather than expecting identical internal stroke counts.

## 9. Falloff and paint pipeline integration

### S4 Falloff

Reads S3 `incDist`, `excDist`, altitude, area parameters, Curve1D LUTs, Paint signed distance where available, and optional camera interface. Writes `densityFactor` and `scaleFactor`. It never changes `F_ALIVE` directly. The stage is tile-parallel and deterministic. A falloff edit starts S4. A paint stroke can bypass full curve recomputation by updating only dirty candidate factors.

### S5 Density thinning

Reads `densityFactor`, distribution map value, viewport budget factor, and candidate StableKey. Computes a threshold and uses a stable purpose hash. Sets `F_CULL_DENSITY` for rejected candidates and clears `F_ALIVE`; it never erases SoA entries. The same candidate with the same density input must produce the same decision independent of thread count. Camera distance density remains in V unless the user explicitly enables population-affecting mode.

### Paint S3 and S4 interaction

S3 calls Paint coverage for area membership and distance. S4 uses the same coverage field's signed distance for Include or Exclude boundary falloff. S5 uses the coverage value as a factor. This avoids a bug where the hard membership contour and soft density field come from different brush evaluations.

## 10. 3ds Max integration

The Max layer enters a dedicated Paint sub-object or command mode and uses the installed `PainterInterface` API. Autodesk names and signatures are SDK-version sensitive, so verify exact classes and methods in the target headers. The project research has verified `IPainterInterface_V5::AddToStroke`, pressure access, `IPainterInterface_V7::UpdateMeshesByObjState`, and V14 spline constraints as useful references. Sources: [PainterInterface V5](https://help.autodesk.com/cloudhelp/2021/ENU/Max-Developer-Help/cpp_ref/class_i_painter_interface___v5.html), [PainterInterface V7](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_i_painter_interface___v7.html), [PainterInterface V14](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_interface___v14.html), [PainterInterface MAXScript](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Interfaces/Other-Interfaces/Other-Interfaces-1/GUID-01A9145F-54A0-4283-93BD-6F942C118E6C.html).

Main-thread responsibilities are PainterInterface callbacks, viewport hit testing, receiver snapshot acquisition, `theHold`, `RestoreObj`, dependency notifications, and redraw requests. Workers receive copied mesh snapshots and immutable strokes. A single ordered paint job queue prevents two commits from racing. Completion checks the object generation and receiver topology version before publication.

A stroke command begins one undo transaction. On mouse down, capture the active surface, projection, transform metric, brush settings, and modifier operation. During motion, update pending dabs and retained preview buffers. On release, commit one `PaintStroke`, dirty the union of old and new support, update candidates, and close the transaction. `RestoreObj::Size()` reports the actual stroke plus touched cell, node, vertex, candidate, and structural-edit storage. If memory protection is needed, fall back to stroke-only undo and rebuild from history, but make the slower mode visible.

Paint UI has operation buttons, Min and Max Size, Brush Size, Strength, Softness, pressure options, configurable Ctrl and Alt mappings, Preview Falloff, Convert to Spline, and a stale or unresolved receiver warning. Changing Project Axis after paint prompts for Reproject, because the paint anchors were authored in the old projection.

## 11. Preview overlay

When Preview Falloff is on, render an overlay from the retained preview lattice or certified preview nodes, not by replaying every stroke each redraw. Color maps coverage and can optionally show Density and Scale separately. Draw the brush cursor independently from the coverage geometry. Dirty chunks are uploaded only when their node values change. Camera navigation changes only the display transform and does not rebuild coverage buffers.

The overlay must show unresolved topology, unresolved distance, and stale population states. A coverage preview can be exact at cached vertices while the interpolated display is approximate. The overlay labels the chosen epsilon or resolution so artists do not mistake a preview tolerance for population membership.

## 12. Performance and memory

These are [DESIGN] targets to benchmark on the project hardware:

* Painter callback p95 at or below 4 ms and p99 at or below 8 ms for a bounded brush support.
* Cursor input to visible overlay p95 at or below 33 ms.
* Mask feedback p95 at or below 50 ms and p99 at or below 100 ms.
* Per-append cost at 10,000 identical strokes no more than 1.2 times cost at 100 for fixed preview complexity.
* Candidate membership has zero differences from the exact reference evaluator.
* Unchanged viewport navigation causes zero coverage rebuilds and zero uploads.
* A local stroke updates only touched preview chunks plus collision halo in ordinary scenes.

The existing research prototype reported operation-count evidence, not native timing: a persistent preview tree stayed near 88,000 dab evaluations per append for opaque cases while stateless replay grew to millions, and exact interval decisions had zero mismatches against full replay. These numbers are evidence for the architecture, not Cyrus performance guarantees. Source: [Revision 2](https://app.clickup.com/90122138736/docs/2kxv5d3g-532/2kxv5d3g-212).

Do not store authoritative coverage in 8 or 16 bits. Repeated affine updates in float32 are bounded and can be rebuilt from strokes on load; repeated quantization would compound error. Quantize only for GPU upload. Keep per-area caches sparse: EMPTY and FULL regions need no sample array, while MIXED boundary bands retain values. A candidate cache is one float and one accepted bit per affected candidate per Paint Area, plus spatial bins.

Avoid a full history scan during a drag, document copies per callback, rebuilding face links, and world-space tiles that merge nearby sheets. Use face-local or surface-anchored caches. A new stroke may pay a one-time exact initialization when it enters a cold preview node; instrument this separately. If cold-region initialization dominates, build the sparse surface atlas experiment described in the research notes.

## 13. Edge cases and failure modes

* **No active surface:** Paint mode refuses to start rather than storing unanchored strokes.
* **UV mode without Project Axis:** block painting and show a required-setting warning.
* **Receiver topology changed:** mark anchors unresolved, attempt explicit remap, and never reuse stale face and barycentric IDs silently.
* **Nonuniform transform:** capture the chosen metric. The default is captured-space distance, so later node scaling does not stretch an existing brush field. A current-space compatibility option is [OPEN].
* **Mirrored receiver:** transform normals with inverse transpose and preserve winding diagnostics.
* **Folded surface:** use the existing engine's reach and connectivity policy. A connected face walk must not use unrestricted Euclidean distance across a fold. Test surface-distance limits and normal cones.
* **Two nearby disconnected sheets:** face-local storage prevents coverage leaking through a world-space cache cell.
* **Soft brush edges:** signed distance may be uncertain. Refine the preview or report `distanceExact=false`; do not fabricate a hard contour.
* **Erase reveals another Paint Area:** per-area fields and max-at-read are mandatory.
* **Multiple dabs in one stroke:** maximum within stroke, not sequential affine application.
* **Pending gesture cancel:** discard only pending values, not committed base values.
* **Undo of a Full node:** restore saved structural edits and before-values. Do not attempt affine inversion through `b=0`.
* **Threshold change:** recompute membership and contour distance, but retain strokes.
* **Strength or softness change on an old stroke:** treat as an authored stroke edit, dirty old and new support, and re-evaluate from the changed stroke sequence. Do not mutate a cached result without versioning.
* **Paint Include plus Surface Include:** both contribute under S3's proposed union policy; UI warns that Surface On may fill the entire terrain.
* **Paint Exclude below Include:** it has no effect on lower generated candidates by ordered Area semantics. UI warns that an Exclude should be moved above its target.
* **Brush larger than receiver:** cap support to receiver bounds and retain the stroke. The coverage result remains valid over the receiver.
* **Pressure absent:** use 1.0 and record that fallback.
* **Render while a stroke is active:** commit or cancel on the main thread before render evaluation. Never render a half-committed document.
* **Stale worker completion:** compare paint revision, receiver version, and object evaluation generation; discard stale results.
* **Memory budget exceeded:** evict derived caches and rebuild from strokes. Never delete authored strokes.

## 14. Tests

### 14.1 Curve and factor unit tests

1. Linear curve maps normalized endpoints correctly and matches the LUT within tolerance.
2. Monotone curve never overshoots 0 to 1 and preserves ordered control points.
3. Invert Curve complements the output.
4. Falloff Affect 0 is neutral and Affect 1 is the raw curve.
5. Include and Exclude ranges use nearest boundary and correct endpoint distances.
6. Density and Scale remain independent.
7. Affect Height only produces `(1,1,s)`.
8. Altitude Bottom and Top produce expected normalized values and clamp outside range.
9. Multiply nearest Include and Exclude factors across two and three areas.
10. Camera sampler is not called in the default population path.

### 14.2 Paint engine unit tests

1. One full-strength hard dab produces coverage 1 inside and 0 outside.
2. Strength and softness map to the existing kernel.
3. Two overlapping 0.5 dabs in one stroke produce 0.5, not 0.75.
4. Ordered Paint and Erase reproduce affine formulas.
5. Two Paint Areas combine by maximum; erasing one reveals the other.
6. Exact interval decisions have zero membership mismatches against full replay.
7. Epsilon preview values are labeled and never used for membership.
8. Certified intervals catch an interior island whose corners are all zero.
9. Active gesture stencil matches committed replay after release.
10. Undo restores a node that previously became Full.
11. Candidate caches update only changed StableKeys and preserve unrelated values.
12. Topology version mismatch never silently reads stale barycentrics.
13. Nonuniform scale tests captured metric, current metric, and mirrored transforms.
14. Folded and disconnected sheets do not leak coverage under the chosen reach policy.

### 14.3 Conversion and integration tests

1. Marching squares and triangle contour extraction preserve an island.
2. Contour simplification stays within configured tolerance.
3. Paint to spline to paint preserves candidate membership within the declared tolerance.
4. Spline and Paint Area Include and Exclude order matches S3.
5. Project Axis is required before UV painting and changes trigger reproject.
6. Painter modifier mapping is configurable and saved operation is stable.
7. Stroke undo is one transaction and `Size()` is within 20 percent of measured storage.
8. Worker completion after Undo or receiver edit is discarded.
9. Preview Falloff toggling does not mutate population.
10. One thread and N threads produce the same field hash and PublishedPopulation.

### 14.4 Forest Lite comparison scenes

Build a plane, sloped terrain, vertical surface, and a UV sphere. Compare a hard Paint Include, soft Paint Include, Paint Exclude above an Include, Preview Falloff, brush pressure, Ctrl and Alt modifiers, Surface Area On and Off, Paint to Spline, and Spline to Paint. Record coverage contours, item counts, boundary positions, and whether later density changes preserve surviving item identity. Forest's Paint is described as a spline rebuilt each stroke, so use comparison only for visible semantics, not for internal stroke representation or performance.

The [OPEN] overlap tests are especially important: two overlapping Includes, two Paint Areas with erase in one, Paint plus Spline, and a Paint field with a Surface Area left On. Test density, scale, and both falloff curves independently. Keep a CSV of candidate StableKey, coverage, accepted bit, and flags for both implementations.

## 15. Open questions

* **[OPEN]** Does Forest combine multiple area falloffs by nearest, product, minimum, maximum, sum, or last write?
* **[OPEN]** Are Include and Exclude ranges global in all versions, or can they differ per Area internally?
* **[OPEN]** Is the displayed curve's 100% endpoint the boundary or the far edge in all releases?
* **[OPEN]** What exact curve interpolation and LUT resolution does Forest use?
* **[OPEN]** What are Forest defaults for brush Min Size, Max Size, Strength, Softness, spacing, pressure mapping, and threshold?
* **[OPEN]** Does Forest's Paint field use a hard threshold for membership or a continuous density interpretation at all stages?
* **[OPEN]** Does Paint coverage follow receiver topology, projected XY coordinates, or a private hybrid after the surface changes?
* **[OPEN]** How does Forest handle a receiver topology edit below existing paint?
* **[OPEN]** What is the exact Ctrl and Alt mapping in the target Forest version?
* **[OPEN]** Does Convert to Spline preserve holes, soft boundaries, and separate paint components?
* **[OPEN]** Is Paint to Spline destructive, linked, or a one-time copy?
* **[OPEN]** Does Forest use a current or captured transform metric for brush radius after nonuniform scaling?
* **[OPEN]** Are camera falloff factors population-affecting or view-only in every mode?
* **[OPEN]** What is the compatibility behavior when Area falloff and Randomize Stacked are both enabled?

## 16. Architecture feedback

`00_ARCHITECTURE.md` already provides the necessary Population channels, StableKey, StageContext, DirtyBits, tile jobs, immutable snapshots, and SharedCacheRegistry. Add the following explicit extensions:

1. Add a transient `PaintField` handle or per-area coverage sampler to the StageContext services. It must carry field revision and receiver topology version.
2. Add `D_FALLOFF(areaId)`, `D_PAINT_STROKES(areaId)`, `D_PAINT_PARAMS(areaId)`, `D_PAINT_PREVIEW(areaId)`, and `D_PAINT_CONVERSION(areaId)`. Map curve edits to S4, threshold edits to S3, and committed strokes to S3 to S9.
3. Add per-area transient coverage cache references and optional `F_PAINT_UNRESOLVED` diagnostics. The published Population need not retain coverage after S12.
4. Define `Population.scaleFactor` as a vector whose `(1,1,s)` value is legal for Affect Height only. The existing type already supports this.
5. Keep the existing S5 stable-thinning rule and extend its purpose namespace with `PaintDensity`. A paint edit must never derive a new random value from the current coverage.
6. Add a per-gesture RestoreObj delta contract to the Max integration notes. A full Population snapshot is not needed for ordinary paint undo.

No change to the core rule that authored inputs are truth is needed. The most important architectural constraint is to keep saved strokes and derived caches distinct. That is what lets Cyrus reuse its existing paint engine as an Area type while avoiding Forest's history-dependent stroke-to-spline rebuild.

## 17. Summary of implementation decisions

Cyrus evaluates boundary falloff through separate density and scale channels, nearest Include and Exclude boundary distances, and a proposed multiply combination that remains [OPEN] for compatibility testing. Curves are monotone-capable cubic representations with LUTs. Altitude falloff is separate from boundary falloff, and Affect Height only writes a Z scale factor. Camera distance is an interface to the view pass.

A Paint Area delegates coverage to the existing Cyrus surface-anchored stroke engine. S3 gets coverage, inside threshold, and signed distance from the same field. The engine stores ordered Paint and Erase strokes, uses maximum within a stroke and maximum across Paint Areas, applies affine operators across committed strokes, and maintains persistent preview and candidate caches. PainterInterface remains a Max-layer input mechanism, while worker threads process copied immutable snapshots. Stable hash thinning, dirty regions, collision halos, retained overlay buffers, and per-gesture undo deltas make painting incremental. Convert to Spline uses contour extraction and simplification with explicit tolerance. Forest's stroke-rebuilt-spline lag is avoided because Cyrus never rebuilds the full history for every mouse move.

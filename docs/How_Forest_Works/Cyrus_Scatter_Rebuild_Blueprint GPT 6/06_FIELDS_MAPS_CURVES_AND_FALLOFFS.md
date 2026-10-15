# 06 — Fields, maps, curves, and falloffs

**Status: proposed Cyrus design. Research basis: R0 §§3.6, 4.3–4.4, 6.**

## 1. One query layer, several value types

A field is a function evaluated in a declared domain. It can return density, color, a direction, a category, or distance. A bitmap, spline distance, painted mask, terrain slope, and noise pattern can all be field providers, but their value semantics remain distinct.

```cpp
struct FieldQuery {
    Vec3d worldPosition;
    Vec3d receiverLocalPosition;
    SurfaceBinding binding;
    MapCoordinateSet uvChannels;
    CandidateId candidate;
    TimeCode time;
};

struct FieldDescriptor {
    FieldValueType valueType;
    CoordinateDomain domain;
    DependencySet reads;
    SupportBound influence; // finite, global, or unknown
    SamplingPolicy sampling;
};
```

Never interpret every RGB field as density. Color-ID selection, physical color, and scalar mask data require different treatment.

## 2. Required field providers

Implement constants, bitmap sampling, canonical paint sampling, region membership, signed boundary distance, curve distance/tangent, surface attributes, deterministic noise, and a safe host-map adapter. Add compositors for multiplication, addition, minimum, maximum, remapping, and category selection.

A field graph is acyclic. References to upstream final scatter occupancy are explicit graph edges. Detect cycles when a command creates a link, not after recursive evaluation overflows.

## 3. Bitmap semantics

Store source URI/content hash, channel interpretation, color-space intent, alpha interpretation, wrap mode, filtering, coordinate transform, and resolution. Density and ID maps are data; do not silently apply photographic display transforms to them.

Defaults: scalar masks use a selected channel or declared luminance formula; categorical maps use nearest sampling unless the user chooses color-distance matching; continuous fields use bilinear sampling. Wrap behavior is explicit: repeat, clamp, mirror, or border value.

Use `floor`, not truncation toward zero, for negative repeated coordinates. Half-open sample ownership prevents duplicate border candidates.

Texture filtering alters the field. It is a saved artistic policy, not a quality optimization that changes unnoticed between viewport and final render.

## 4. Host procedural maps

A native Max map may depend on time, UV channels, object identity, world position, shading context, derivatives, or renderer state. Do not promise that any arbitrary map can be evaluated safely by a pure worker.

Classify adapters:

| Class | Evaluation route |
|---|---|
| Copied bitmap | Pure worker sampling |
| Cyrus-native field | Pure deterministic evaluation |
| Qualified bakeable host map | Main-thread or documented safe baking into a versioned domain |
| Qualified host evaluator | Only the thread/context contract proven by that adapter |
| Render-time/view-dependent map | Unsupported for authoring placement unless an explicit approximation is selected |

Bake keys include all mapping inputs and time. A world-space map baked for one receiver cannot be reused for another solely because they share a UV channel number.

When a bake is approximate, record its resolution and error policy. Do not substitute a low-resolution preview bake into a final population without reevaluation.

## 5. Coordinate transforms

Separate the generator's physical pattern transform from a field's texture transform. Moving a density texture need not move candidate points. Moving the generator pattern does move them. The UI exposes those as different controls.

A field may sample at original projected position, resolved surface position, final edited position, source-local coordinates, or UV coordinates. The field descriptor names the domain and evaluation stage; no implicit “current position” that changes meaning midway through the pipeline.

## 6. Signed distance convention

Use positive distance inside an inclusion domain and negative outside. For an exclusion, derive outside clearance explicitly rather than changing the global sign convention.

A distance result can be an interval `[lower, upper]` when produced by an approximate accelerator. A hard decision is valid only when the interval lies entirely on one side of the threshold. Otherwise refine using the authoritative contour or geometry.

For raster paint, the saved reconstruction rule defines a polygonal contour. Exact distance means exact relative to that declared contour, not to an unknown continuous shape the artist intended.

## 7. Falloff composition

For an inclusion interior distance `d >= 0` and range `R > 0`:

```text
t = clamp(d/R, 0, 1)
F = responseCurve(t)
```

Default response is linear from 0 at the boundary to 1 at or beyond R. Density uses `clamp(F,0,1)`. Scale can use a separately configured nonnegative output range; values greater than one are allowed only for scale or explicitly unbounded attributes.

An exclusion clearance falloff is evaluated outside the excluded region. The excluded interior remains ineligible unless a later include contribution adds a new population under ordered-area semantics.

`Invert` means `1 - F` for the normalized response, not reversing control-point order. These differ for asymmetric curves. Reversing X is a separately named operation.

`Affect height only` multiplies source-local Z scale; it does not modify world Z coordinates. After normal alignment, source-local up can differ from world up.

## 8. Combining influences

The proposed default density is a product of independent normalized multipliers:

```text
D = clamp(baseDensity * map * areaFalloff * altitudeFalloff * explicitEffects, 0, 1)
```

Sample one stable density random value against the resulting probability. Do not test each factor against the same random value independently: that behaves like a minimum, not a product. Testing each factor with independent channels is statistically equivalent to a product but yields a different layout; save the selected policy.

Area overlap does not automatically use this product. Independent include contributions remain distinct. Within one contribution, the compiler resolves which local settings replace global values and which multiply them.

## 9. Probability curves versus response curves

A response curve maps an input to an output. A probability-density curve determines how frequently outputs occur. They need different implementations and UI labels.

For a probability curve `f(x) >= 0` on `[0,1]`, integrate to obtain a CDF, normalize by total area, and invert it for a uniform random value. Cache the normalized table under the curve revision and sampling tolerance.

A negative curve segment is invalid. A zero integral produces a validation error or an explicit uniform fallback selected by policy—not a divide by zero. Represent discrete outcomes as weighted atoms, not infinitely tall curve spikes.

For monotonic CDF interpolation, preserve monotonicity and clamp endpoint error. Test uniform, triangular, bimodal, narrow-peak, and discrete-atom distributions.

## 10. Finite support and dirty bounds

A finite-range falloff around a changed boundary expands the dirty region by that range, plus reconstruction/filter error. If a user changes a curve inside a globally used region, the whole region can be dirty even when its geometric boundary did not move.

Distance-to-nearest queries can have global influence when the nearest object is removed. A local cached nearest-object ID is not proof that the effect is local. Use a finite query radius or conservatively invalidate the dependency closure.

## 11. Cache layers

Cache source image decoding separately from transformed sampling. Cache region contours separately from distance tiles. Cache normalized probability tables separately from instance samples. These are different invalidation domains.

A paint edit should not decode every source image again. A tint-curve change should not rebuild a spline BVH. A UV edit should not rebuild unrelated object-space exclusion contours.

## 12. Artist-facing debugging

Provide field inspection at the cursor: field name, coordinate domain, sampled value, coverage membership, distance, and relevant revision. Provide a heatmap overlay independent of plant visibility.

An “Explain this candidate” command reports the resolved probability and first rejection reason. It should distinguish `Paint outside`, `Density rejected`, `Source empty`, `Slope rejected`, and `Collision rejected`.

## 13. Acceptance cases

A constant 0.25 density field should retain approximately one quarter of a large fixed candidate set before collisions. Raising it to 0.5 should include the original retained candidates under stable thinning. A field-coordinate edit should move the mask, not reseed source transforms. A zero-width falloff should act as a hard boundary. Negative UV repeat, identical maps in different coordinate frames, and overlapping exclusions must have explicit fixtures.

These tests establish Cyrus semantics. They do not establish the private field pipeline of ForestPack, whose documentation exposes user-facing controls rather than a full numerical execution order [R0 §§3.6, 4.4].

# 05 — Candidate generation: Image, Path, Reference, Particle and external providers

**[FP-DOC]** ForestPack documents four main distribution modes: Image, Path, Reference, Particle Flow. RailClone segment input was added through Reference-mode integration in 9.4.1. Sources: [Image](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode), [Path](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode), [Reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode), [PFlow](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode), [RailClone](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/railclone-integration).

## 1. Common provider contract

```cpp
struct CandidateRequest {
    Uuid scatterId;
    Uuid generatorId;
    Bounds queryBounds;
    GeneratorParameters parameters;
    FieldSamplingContext fields;
    CancellationToken cancellation;
};

class IPlacementProvider {
public:
    virtual Capabilities Capabilities() const = 0;
    virtual void Generate(const CandidateRequest&, CandidateWriter&) const = 0;
    virtual DirtyBounds AffectedBy(const ChangeSet&) const = 0;
};
```

All providers emit candidates with stable IDs, original/proposed position, generator-space coordinates and provenance. They **must not** instantiate host objects. Downstream area tests, source choice, transforms, constraints and outputs consume one representation. A provider can supply orientation/scale hints without forcing the entire scatter to use them.

## 2. Image mode — implement the actual distinction between pattern and density

ForestPack's documented distribution image uses pixels as potential positions; patterns can be bitmaps or procedural maps. Its controls distinguish world dimensions X/Y Units, procedural resolution X/Y Pixels, offsets, rotation, map channel and fit/alignment; `Max Density` counts candidates, including black/empty pixels. Clusters and color selection operate on the resulting candidates. Version 9.3 added **Use as Density Map** for grayscale acceptance. [Reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode).

### Proposed sampler

1. Choose coordinate domain: scatter-local planar XY or appropriate UV map space.
2. Apply inverse map transform (scale/rotation/offset) to candidate-query extent.
3. Enumerate repeating image tiles covering extent; use signed tile coordinates for stability with negative scene positions.
4. Enumerate pixel candidate centers (or documented pattern-defined sample positions) in deterministic order. Optional spatial jitter is an independent control.
5. For each candidate, sample binary threshold / grayscale density mode and assign deterministic acceptance RNG keyed to candidate ID.
6. Emit accepted preliminary candidates with base probability and map coordinates; defer areas/surface/collisions to later stages.
7. Stop or report when candidate budget is exceeded; distinguish generated candidate limit from accepted-instance limit.

**Proposed density acceptance:** `hash01(candidateID,"density") < saturate(coverage(x,y))`. This produces monotonic acceptance when coverage increases for a fixed candidate reservoir. It is not a confirmed ForestPack algorithm.

### Key formulas

For a tiled map with `Px * Py` possible samples and a tile covering `Ux * Uy` world-space units²:

`candidate density ≈ Px*Py/(Ux*Uy)` (before masks, excludes, collisions). Halving both world dimensions increases nominal candidate density about 4×. At large dimensions, guard integer overflow and unbounded tile enumeration.

### What controls must be kept independent

| Control | Target behavior | Key dependencies |
|---|---|---|
| Bitmap/Procedural map | Defines tile values / optional candidate pattern | Sampling and mapping |
| X/Y Units | World or mapping-space footprint | Candidate coordinates, count |
| X/Y Pixels | Procedural map sampling resolution | Candidate reservoir |
| Rotation / Offset | Pattern transform | Candidate positions |
| UV/map channel | Which coordinate domain drives map | Receiver UV snapshot |
| Threshold | Binary acceptance rule | Acceptance only |
| Use as Density Map | Continuous acceptance probability | Density random channel |
| Max Density | Safety budget for potential positions | Diagnostics and abort policy |
| Color ID | Which source to choose by pixel colors | Source selection |
| Clusters | Spatially correlated source types | Diversity field |
| Collisions | Reject overlapping instances | Item bounds / occupancy |
| Distribution seed | Deterministic variety | Candidate RNG, not geometry snapshots |

**[TEST-NEEDED]** Exact virtual-grid jitter, threshold interpretation, map-channel transform, "Fit to Scene" alignment, and duplicate Color ID tie resolution should be empirically measured for the target Forest version. Avoid claiming pixel centers are the exact commercial implementation.

### Avoid re-evaluating expensive procedural maps for every plant

A host-managed Texmap may be unsafe off-thread and expensive per query. If its evaluator is not explicitly supported in worker threads, pre-sample it into a tiled texture/mipmap or host-approved immutable field snapshot. Declare blur/filter/UV sampling behavior; record precision and interpolation (nearest, bilinear, anisotropic). Do not assume standard color-space gamma is correct for density maps; density data should normally be treated as non-color scalar.

## 3. Path mode — parametric spline sampling

[FP-DOC] Path mode supports spacing or vertex positions, several path splines, source `Random/Sequence`, spline offset, random position and `Follow Path` rotation on X/Z. This is placement along a curve, **not** an open-spline area band. [Reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode).

### Arc-length algorithm

1. Snapshot spline segments with transforms and sub-spline identities.
2. Build `(parameter t, cumulative length s)` lookup adaptively with curvature/tolerance bound.
3. For even spacing `d`, sample at arclength positions `s_k = startOffset + k*d`.
4. Invert lookup to get curve position `P(s_k)` and normalized tangent `T(s_k)`.
5. Compute a stable path-plane right vector; define lateral offset and orientation convention.
6. Jitter longitudinal/lateral directions with separate keyed random channels.
7. Emit candidate with path UUID, sub-spline ID and stable ordinal/parameter identity.

Example:

```cpp
for (auto contour : path.contours) {
    ArcLengthTable t = BuildArcTable(contour, tolerance);
    for (uint32_t k=0; k<CountAtSpacing(t.length, spacing); ++k) {
        double s = ComputeSampleArc(k, spacing, endpointPolicy);
        Vec3 p = t.PositionAtArc(s);
        Vec3 tangent = t.TangentAtArc(s);
        writer.Add(MakeCandidate(contour.id, k, p, tangent));
    }
}
```

### Edge cases to define

- Closed loop seam and duplicate at start/end.
- Endpoint inclusion for length shorter than spacing.
- Multiple sub-splines within one object; separate or continuous sequencing.
- Abrupt knot corners and zero-length segments.
- Mirrored/nonuniformly transformed source spline.
- Tangent up-vector singularity; frame flip avoidance.
- Offset on self-intersecting curves.
- Generator change when spacing changes and manual edits need remapping.
- `Sequence` source choice versus disabled entries and gaps.

Arc-length sampling is a **recommended** algorithm; exact commercial path parameterization and jitter order require reference testing.

## 4. Reference mode — preserve authored layout

[FP-DOC] Reference mode takes object pivots or mesh-face positions, supports one/multiple items per face, material-ID filtering, reference orientation and scale inheritance, name/regex matching, and collision settings. A missing name match can fall back to the first source entry. [Reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode).

### Pivot implementation

Use persistent `StableNodeId`, relative reference transform, and a deterministic source-selection key. On moving a CAD marker, update position/rotation/scale without changing candidate identity. For `Align=false`, document how object/world axes are interpreted. For `Scale=true`, decide whether nonuniform/mirrored reference transforms are supported directly or normalized.

### Face implementation

Snapshot triangulated face records; filter material IDs; compute centroid/normal and prescribed orientation frame. For `itemsPerFace > 1` sample a regular deterministic grid or uniform face positions. Correct uniform random barycentric sampling on a triangle uses `r1, r2∈[0,1]`, `a=1-sqrt(r1)`, `b=sqrt(r1)*(1-r2)`, `c=sqrt(r1)*r2`; resulting point `a*A+b*B+c*C`.

**[TEST-NEEDED]** This formula is our recommended uniform mode; ForestPack's default regular grid and per-face align rule are documented, but exact random sequence/layout is not completely established. Do not conflate face index stability with persistent surface identity after topology edits.

### Name/regex matching

Compile patterns once, handle syntax errors in UI, define match priority and Unicode/case rules. Preserve ordered fallback behavior as a compatibility option. Log source match counts and unmatched references; empty source slot intentionally generates no geometry.

## 5. Particle Flow provider

[FP-DOC] ForestPack supports using PFlow particles and either all events or selected events, with optional align/scale inheritance and live animated particle input. [Reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode).

Implementation: snapshot `particleId (if exposed)`, emitter/event ID, age, velocity, transform/scale, time, and parent reference. Only call host particle APIs on documented safe threads. Re-evaluation time changes particle population; treat identity as `stable` only when the source exposes durable IDs. Effect variables can consume age, speed and event metadata. Model read-only PFlow **input** separately from a hypothetical particle output/bake adapter.

## 6. External procedural input adapters

RailClone segments in ForestPack 9.4.1 are an example of preserving source tags/names and transforms from another system, not only anonymous points. For Cyrus, define an `IExternalPlacementAdapter` with source UUID, stable external element key, transform, attributes and provenance. Add adapters one at a time after confirming license/API interoperability. Do not reverse-engineer a private binary protocol.

## 7. Density and candidates: two independent selectors

For every mode distinguish:

- Input **candidate count** (positions available).
- Eligibility **density acceptance** (a reproducible rejection field).
- **Source choice** (weights, Color ID or clusters).
- **Constraints** (collisions, geometric boundaries).
- Final **accepted count** and viewer-preview count.

The debug UI should offer stages separately. An artist increasing density on a saturated forest must see high collision rejection rather than concluding the slider does not work.

## 8. Distribution acceptance tests

- Known tiny bitmap (8x8) on flat plane yields predictable candidate count and tile alignment.
- Moving/repeating map tiles produces stable deterministic IDs outside changed definition.
- Increasing grayscale density is monotonic at pre-collision acceptance stage.
- Path test with unequal-length spline segments yields equal **world-distance** placement.
- Closed path has exactly one seam item under chosen endpoint policy.
- Reference pivot keeps the same ID and random source when moving node.
- Reference face sampling is spatially uniform in statistical tests.
- PFlow filter excludes exactly non-selected events.
- Worker-count changes cannot change final deterministic candidate keys.
- All modes pass through one common area/surface/transform/collision pipeline.

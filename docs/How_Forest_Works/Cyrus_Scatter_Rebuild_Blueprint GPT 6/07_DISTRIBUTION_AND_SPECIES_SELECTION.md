# 07 — Distribution generators and species selection

**Status: proposed Cyrus algorithms. Research basis: R0 §2. Official feature anchors: S02, S04–S06.**

## 1. One interface, different semantic addresses

Each generator enumerates canonical candidates and supplies optional initial position, orientation, source hints, and external attributes. It must declare its domain, identity scheme, dependence on time, and finite enumeration bounds.

```cpp
class ICandidateGenerator {
public:
    virtual GeneratorCapabilities Describe() const = 0;
    virtual Result Enumerate(const GeneratorRequest& request,
                             CandidateSink& sink,
                             CancellationToken cancel) const = 0;
    virtual ~ICandidateGenerator() = default;
};
```

This is an interface sketch. A production sink supports bounded pages, deterministic addresses, cancellation, and typed errors. It does not append to a shared unsynchronized vector from many workers.

## 2. Image-grid generation

ForestPack describes a distribution image whose pixels correspond to possible placements, with physical map dimensions controlling repetition [S02]. Cyrus can implement a comparable, explicitly specified mode.

For pixel `(i,j)` in a `Px × Py` tile with integer repeat address `(tx,ty)`:

```text
u = (tx + (i + 0.5)/Px) * Ux
v = (ty + (j + 0.5)/Py) * Uy
p = patternTransform(u,v)
```

Pixel centers are a **Cyrus sampling choice**, not a claim about all ForestPack versions. Optional jitter uses independent X/Y channels bounded within the pixel cell. Save whether jitter applies before or after field evaluation.

Use half-open tile bounds. Include negative repeat indices. Pattern enumeration occurs only over the conservative inverse-transformed bounds of the include contribution, expanded for permitted offsets/footprints when required by its boundary policy.

### Binary and grayscale interpretations

Binary mode accepts a sample when the selected map value is at least a saved threshold. Grayscale mode turns the sampled value into a probability and uses the density channel. A separate `Empty` source can create intentional gaps after this gate.

Color matching samples categorical/color data separately from density. A black pixel does not necessarily mean `Empty` in a color-ID map unless that is explicitly configured.

### Physical dimensions and resolution

`Ux/Uy` move samples and change candidate density. `Px/Py` change the sampling lattice. The latter increments its identity epoch in this profile. Locked aspect ratio derives the second dimension from the selected image aspect; record which dimension is authoritative.

`Fit to bounds` is a command calculating dimensions and transform, not a magical alternative coordinate mode. Save the resulting values so the same scene reopens identically.

### Sparse patterns

Precompute active addresses for a static binary tile. In probability mode, skip guaranteed zero regions but preserve the canonical addresses of surviving potential samples. Report both the virtual potential count and the actually evaluated count. Optimizing away zeros must not change identities or random choices.

## 3. Independent density mode

Image scaling is useful for reproducing a pattern but is a poor universal density slider. Provide a separate progressive density generator.

Use a saved world-domain cell size and deterministic sample sequence per cell. Each address is `(cellX, cellY, rank)`. Within a fixed configured capacity, a density probability gates the existing candidate universe. Growing capacity appends ranks; it does not replace earlier ranks.

The UI separates capacity from artistic density. Changing the cell layout itself is a structural edit with an identity warning. An exact-count generator is another mode, not a hidden interpretation of the same slider.

For count mode, default requested count refers to candidates before constraints. `Fill accepted count` can repeatedly extend a sequence until it reaches the target or an explicit attempt/memory limit. Failure reports the achieved count and rejection causes. Do not loop indefinitely in saturated collision regions.

## 4. Path generation

ForestPack documents spacing/vertex approaches, source sequencing, offsets, and following path direction [S04]. Cyrus defines the geometry precisely.

Build an adaptive arc-length table from the evaluated curve. Subdivide until chord/length error is below the saved tolerance. Invert cumulative arc length to find positions at requested distances. Do not use equal spline parameter increments and call them even spacing.

For an open path, use `s = startOffset + k*spacing` while `s <= length-endOffset`, according to a saved endpoint-inclusion policy. For a closed path, omit the duplicated seam endpoint. An optional `Fit count evenly` mode distributes N samples around total length and is distinct from fixed spacing.

### Offset and orientation

The default measures spacing on the original centerline, then applies lateral offset. An optional reparameterized-offset path is a different mode because its length can differ. On self-intersections, the path address remains unambiguous even if two positions coincide.

Construct a stable orientation frame using the tangent and an explicit up reference. For 3D paths, use parallel-transport frames to reduce twisting; define initial frame and closed-loop seam correction. At zero-length tangents, use neighboring nondegenerate segments or mark the sample invalid.

Position randomness has separate along-path and lateral channels. Source sequencing uses explicit authored order; ordinary random source selection uses UUID-canonical order. Reversing a curve intentionally reverses its traversal and can alter rank-to-position correspondence.

## 5. Reference generation

A pivot provider emits one candidate per referenced object UUID. Initial transform inheritance has separate position, orientation, scale, and shear policies. A source-name matcher produces a source hint, not a new candidate generator.

Face mode snapshots the evaluated mesh and emits addresses containing topology epoch, face identity, and sample rank. Triangulate polygons deterministically and preserve polygon provenance. Uniform triangle sampling uses the barycentric formula in chapter 05; arbitrary barycentric pairs are not uniform.

`Items per face` is not equal to world-area density when face sizes differ. Expose both modes separately. Face material-ID restrictions are resolved against the snapshot used to sample positions.

### Name and regular-expression matching

Normalize names according to a saved case/Unicode policy. Exact matching is default. Regex mode uses a bounded, non-backtracking implementation or a strict complexity/time budget; never freeze Max on an adversarial expression. Multiple matches use an explicit priority list or report ambiguity. Missing matches produce a diagnostic and configured skip/fallback policy, never a random silent choice.

## 6. Particle input

The Particle Flow input adapter must establish access to positions, transforms, event membership, stable birth identities, and time evaluation. Those capabilities are documented conceptually in the research and ForestPack reference [R0 §2.7; S06], but Cyrus's exact SDK adapter must be qualified.

Birth IDs are preferable to the current particle array index. If stable identity is unavailable, declare the adapter's identity limits and disable persistent per-particle overrides rather than pretending they are reliable.

Read the particle system through a host snapshot adapter. Guard dependency cycles, especially when the same setup also writes a Particle Flow output stream. **PFlow input and PFlow render transport are separate modules.**

## 7. External procedural input, including RailClone-like providers

Define an external candidate protocol containing provider UUID, item UUID, transform, optional source tag, optional color, time, and revision. A specific vendor bridge is supported only after the vendor's export interface and redistribution contract are established.

Do not infer that a referenced product's internal segment API is public merely because ForestPack integrates with it. A bridge may need a cooperation agreement or a documented export format. Until then, a generic transform/metadata import can provide related capability without claiming live RailClone parity.

## 8. Source selection

For nonnegative weights, normalize over eligible sources in canonical source-UUID order. Zero weights are excluded. Zero total weight produces an empty population with a specific diagnostic. Disabled-as-empty entries retain their weight; excluded-from-selection entries do not.

A local area source subset restricts eligibility before normalization. An empty local subset means no eligible source, not “use every source.” Missing assets retain their identities and weights and produce missing-source diagnostics.

Changing probabilities can change chosen species and collision outcomes while leaving candidate addresses intact. This is expected and should be explained by the inspector.

## 9. Color-ID matching

CyrusV1 uses a saved color-distance metric, default Euclidean distance in declared linear RGB data space. This is not a claim about ForestPack's private color metric. Categorical IDs can instead use exact integer labels.

If several sources share an ID, select among that ID's sources using their local weights and a separate channel. Tie-breaking between equally close different IDs is canonical. Specify alpha and out-of-range handling. Filtering can blur category boundaries; default nearest sampling avoids inventing intermediate labels.

## 10. Clusters

Implement clustering as a spatial species-probability field, not as moving already-generated plants together.

A concrete initial algorithm:

1. Divide an immutable macro-domain into cells derived from `clusterSize`.
2. Generate one deterministic jittered site per macro-cell.
3. Assign a species label to each site using the base weights.
4. Warp query coordinates with bounded deterministic noise for roughness.
5. Find nearby sites using a search with a provable lower bound for unexplored cells.
6. Convert distances to normalized mixing weights; aggregate by species.
7. Blend with the base species probabilities using `outlierNoise`.
8. Select a source using the candidate's source channel.

`Edge mixing = 0` uses the nearest site's category. Positive mixing uses a finite-support kernel or a clearly bounded nearest-K mixture. Do not assume an arbitrary 3×3 site neighborhood always gives the correct nearest sites without a bound.

`Cluster size` changes patch dimensions. `Roughness` distorts boundaries. `Edge mixing` blends species near transitions. `Outlier noise` adds exceptions throughout patches. Candidate locations and density do not change merely because the species field changed, although collision acceptance can change afterward.

## 11. Complexity and bounded work

Estimate candidate count before allocation. Image limits count the virtual grid and report skipped zeros separately. Curve tables and reference snapshots have their own budgets. Large candidate sets are paged; hard final limits trigger an explicit error or a user-selected bounded population policy.

Do not use a global random sample from the current vector to cap candidates: changing enumeration order would reshuffle the result. Stable key ordering or stable hash thresholds can produce a deterministic cap, but a cap still changes artistic semantics and must be visible.

## 12. Acceptance tests

Use a hand-authored 4×4 bitmap, negative tile coordinates, a curved spline with nonuniform parameters, a closed loop, two different-size faces, overlapping references, a changing particle event, shared Color IDs, and clustered species on a fixed point grid. Validate positions, identities, source frequencies, and no unintended coupling between density and patch size.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S02]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode
[S04]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode
[S06]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode

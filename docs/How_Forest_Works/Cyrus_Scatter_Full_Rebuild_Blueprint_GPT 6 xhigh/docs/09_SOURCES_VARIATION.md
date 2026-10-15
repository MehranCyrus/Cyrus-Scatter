# 09 — Source Library, probability, Color ID, clustering and transform variation

**[FP-DOC]** ForestPack Geometry list supports custom objects, billboards, grouping, source scale/offset, collision radius, source probability, disabled/empty choices, Color IDs and material handling. Transform includes translation/rotation/scale ranges, probability curves, spatial maps, probability maps and mirroring. [Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry) · [Transform](https://docs.itoosoft.com/forestpack/forest-plugin/transform) · [Image diversity](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode).

## 1. One source entry is a rich object

`SourceDefinition` combines scene/external asset binding, source bounds, pivot, group hierarchy, materials, mesh variant/renderer proxy, source probability, Color ID, collision radius, optional animation, LOD, source state and previews. Group membership and a set of randomly chosen source alternatives are different concepts.

**Source kinds:** mesh, source scene node, XRef, verified renderer proxy/procedural, billboards, group/compound source, supported lights/non-geometry, and `Empty` reserved for intentional gaps. This last state participates in selection but produces no drawable geometry. Do not implement it as "deleted source".

## 2. Relative source weights

Given weights `w_i >= 0`, `p_i = w_i / Σ(w_j)`. Zero-sum behavior must be declared: no source or equal fallback, not an accidental division by zero.

For large source lists build an Alias table or cumulative weights cache, keyed by source-weight revision. Use candidate-stable `random01(id, SOURCE_SELECT)`.

Example: grass 60, shrub 30, empty 10 -> 10% of raw source selections intentionally produce no object **before** subsequent constraints, if compatibility ordering is chosen. Final visible frequency may differ because larger sources collide more often. Show both selected-source histogram and accepted-source histogram in diagnostics.

### Source selection versus source filtering

`Filter source subset to {A,C}` is not the same as `set B probability=0` if cluster/color-selection semantics depend on all source colors/slots. Preserve explicit eligible source sets per region and matching strategy.

## 3. Source Color ID mapping

[FP-DOC] `Match Color ID on Map` picks the most similar source color and bypasses ordinary source probabilities (subject to source-color duplicate semantics in supported versions). For Cyrus:

1. Sample RGB map in declared color space, convert appropriately (scene linear vs display sRGB).
2. Compare to enabled source Color IDs via a **declared metric** (e.g. RGB Euclidean or perceptual Lab) and stable tie-break.
3. Choose source or `Empty` entry; no hidden weighted random unless documented mode requests it.
4. Provide source-color legend and visual map preview.

**[TEST-NEEDED]** ForestPack's exact color-distance metric, shared Color ID behavior, noise mixing and tolerance. The designer can choose RGB distance for parity-like simplicity or Lab for better perceptual regions; don't call the latter an exact replication without testing.

## 4. Spatial clusters — algorithm design

ForestPack's cluster controls are `Size`, `Roughness`, `Blurry Edge`, `Noise`, and require more than one source to have meaningful grouping. [FP-DOC] How the proprietary fields are generated is not public.

### One independent implementation: warped cellular territory fields

Create a deterministic set of cluster centers across space (Poisson-like seeded grid or Voronoi sites). Each center has assigned dominant source/species. For position `x`:

- Warp `x' = x + amplitude * lowFrequencyNoise(x / warpScale)`.
- Find nearest and second-nearest territory distances `d1`, `d2`.
- Let `edgeDistance ≈ (d2 - d1)` after appropriate normalization.
- `Size` controls site spacing or field frequency.
- `Roughness` controls domain-warp amplitude/frequency.
- `Blurry Edge` controls probability interpolation between dominant and neighbor species at border.
- `Noise` mixes in a stable random independent species choice at selected positions.

Then use categorical sampling from `p_species(x)` to pick a source; the **candidate positions remain unchanged** unless collision behavior depends on selected source.

### Pseudocode

```cpp
SpeciesWeights EvaluateSpecies(Vec2 xy, ClusterSettings s) {
    Vec2 q = xy + s.roughness * NoiseVector(xy / s.warpScale);
    auto nearest = clusterIndex.FindNearestTwo(q, s.size);
    float edgeMix = SmoothTransition(nearest.d2-nearest.d1, s.blurryEdge);
    auto weights = MixDominantNeighbors(nearest.speciesIds, edgeMix);
    return Lerp(weights, baseSourceWeights, s.noise);
}
```

**Cautions:** noise need not change population density; `Size` needs scene units; clusters must tile seamlessly; low species counts and equal weights need stable handling; near edges may produce visual "salt and pepper" if blending is too noisy. Compare with reference imagery using spatial species autocorrelation, patch-size histogram, entropy, boundary lengths and source-count statistics.

### Cluster verification scenes

Two high-contrast box sources on flat plane; sweep Size, Roughness, Blurry Edge and Noise individually with identical candidate positions. Heatmap each source; retain image histograms and accepted counts. Verify source grouping independently of collision.

## 5. Transform stage and mathematical ordering

A conceptual transform might be:

`WorldInstance = ReceiverFrame × GeneratorOrientation × RandomRotation × Mirror × Scale × PivotOffset`.

This is **not a claim about ForestPack's exact matrix order**. Matrix multiplication is not commutative: source pivot translation before scaling differs from afterward. The engine must define and document a consistent order; source objects with rotations/nonuniform scale expose mistakes quickly.

Maintain clear separation of:

1. Geometry source-local transform/pivot.
2. Receiver alignment/orientation.
3. Generator path/reference orientation hint.
4. Random yaw/XYZ rotation.
5. Random translation (source-relative or absolute world units).
6. Source/global/area scale and size falloff.
7. Manually authored overrides.
8. World transform for renderer.

## 6. Translation

[FP-DOC] ForestPack translation is specified as a percentage of source width for X/Y and source height for Z; it is applied **after** initial distribution placement, so it can push items outside initial Area boundaries. [Transform docs](https://docs.itoosoft.com/forestpack/forest-plugin/transform).

For compatibility-style behavior, compute translation from evaluated source dimensions, choose random displacement, and allow boundary overflow under `Pivot-before-translation` policy. Offer alternate `Revalidate after translation` mode as an explicit Cyrus improvement.

## 7. Random rotation and scale

`RotationXYZ`: axis-specific degrees converted to radians once; optional joint/independent channel selection. `ScaleXYZ`: axis-specific min/max with option to lock XY or all axes, guard zero/negative values/mirrored winding. Source global scale and per-area scale should use explicit combine policies.

### Probability curves

An artist-painted probability curve is a density function, not the transformation `value = curve(randomUniform())` unless the curve is explicitly a remapping function.

For a normalized positive weight function `w(t)`, define `CDF(t)=∫[0,t] w(x)dx / ∫[0,1]w(x)dx`, then sample `t = inverseCDF(U)`. Precompute a sufficiently resolved lookup for interactive use; optionally support discrete peaks/steps. Test uniform curve for uniform samples, sharp spikes for rare/bias distribution, and zero weights.

**[FP-DOC]** ForestPack calls these Probability Curves and shows discrete rotation/value variations. We should implement the intended statistical semantics, not infer internal numerical methods.

## 8. Spatial transform maps vs probability maps

- **Value map:** black picks min, white picks max; in RGB scale mode channels R/G/B control scale X/Y/Z.
- **Probability map:** black suppresses randomization, white permits full random range. Thus bright region adds variation rather than assigning a specific maximum transform.
- **Curve:** changes frequency of sampled value.
- **Source weight:** changes model identity, not rotation/scale.

Expose map domain (planar, UV, world), filtering and color-space handling. Host map evaluation may require a baked field for worker use.

## 9. Mirroring

Mirroring is distinct from negative scale in artist semantics, though a transform may encode it with a negative axis determinant. Correct inverted-winding normals and tangent handedness at rendering; handle proxies that don't support mirror instancing, or warn. A mirror decision must use its own random channel and source compatibility flag.

## 10. Compound groups

Represent a compound source as parent local coordinate frame plus child source/geometry and local transform array. Policies:

- **Atomic:** one placement, one parent transform/collision footprint and shared culling.
- **Expanded:** each child sampled/filtered/collided separately according to explicit grouping options.

ForestPack's Keep Group Hierarchy changes transforms and culling relationship of group elements. Do not assume renderer API supports nested instances natively; adapters may flatten child transforms into repeated instance records while still sharing meshes.

## 11. Per-instance attributes

Separate transform and source decisions from shading: `tintRGB`, `materialVariant`, `randomSalt`, `animationSample`, optional user scalar/vector attributes. Stable channels prevent changing tint from reshuffling rotations. Material and renderer bridges implement how attributes are consumed; never create per-instance unique materials unnecessarily.

## 12. Acceptance tests

- Weights 6/3/1 and 60/30/10 yield statistically equivalent source frequencies.
- Blank/disabled weighted source produces intentional empty selection slots.
- Source replacement with different bounds invalidates collision but not candidate coordinates.
- Color ID map chooses specified species in known colored regions.
- Cluster Size changes patch scale without directly changing candidate count.
- Probability curve peaks create correct distribution; CDF histogram checked.
- Map value and map probability modes produce distinct documented results.
- Same candidate IDs keep rotation/tint channels stable across unrelated parameter changes.
- Mirroring preserves correct material normals/backface behavior across supported renderers.
- Groups remain spatially composed according to selected policy and are not accidentally treated as unrelated alternatives.

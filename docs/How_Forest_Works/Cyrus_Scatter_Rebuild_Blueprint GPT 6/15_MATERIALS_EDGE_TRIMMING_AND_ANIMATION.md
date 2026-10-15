# 15 — Materials, element boundaries, and animation sampling

**Status: proposed Cyrus design. Research basis: R0 §§4.5, 5.5–5.6. Official anchors: S13–S16.**

## 1. Material variation is instance data plus shader support

A source material defines baseline appearance. The population provides per-instance attributes. A renderer/material adapter makes those attributes available during shading. A UI tint slider without the third part is not a completed feature.

Forest Color documents variation at whole-item and element levels [S14]. Cyrus uses independent keys for spatial, per-instance, and per-element variation so that one layer of variation does not accidentally reseed another.

## 2. Proposed attribute streams

```text
instance ID / source UUID
instance tint color and strength
material variant index
spatial color sample
animation sample ID
optional element-random seed
custom typed attributes
```

These streams are allocated only when needed. A tint-only update can leave source geometry, candidate positions, surface bindings, and collision results unchanged.

## 3. Color composition

Define the working color space and operation. The initial policy blends base color with a tint in declared linear working space using a bounded strength. Hue/saturation/value controls require an explicit conversion policy; do not treat RGB component multiplication as equivalent to a hue shift.

A broad spatial map produces coherent patches across many plants. Per-instance random tint changes each plant coherently. Per-element variation changes leaves or disconnected pieces inside a plant. A user can combine them, but the order and blend operation are saved.

Material-ID replacement and color tint are distinct. A material variant can change roughness, opacity, or other structure and may need a different renderer prototype/material binding.

## 4. Source element decomposition

Forest Edge documents elements as connected faces sharing a material ID, with a representative lowest-Z vertex for boundary testing [S15]. A comparable Cyrus mode can use that definition, but stores the coordinate-frame and tie-break policy explicitly.

Preprocess a source mesh into element IDs using adjacency and material IDs. Save an element representative point and bounds. For equal minimum-Z vertices, use a canonical vertex/provenance tie-break. A topology or face-material-ID change invalidates the decomposition.

Renderer proxies with no accessible element topology cannot automatically support this route. A provider can supply element metadata only through a qualified contract.

## 5. Element boundary evaluation

For each instance/element, transform its representative point into the boundary query domain and evaluate the applicable contribution/exclusion program. Cache or evaluate an element-visibility mask according to the adapter's memory and shading capabilities.

This removes whole elements. It does not slice triangles along an arbitrary curve. A single connected grass blade can disappear as a unit; a source modeled as one connected mesh may behave very differently from many separate blades.

The instance itself must exist before element masking can help. If candidate-center eligibility rejects the entire patch, render-time masking cannot recreate it. Supporting patches straddling boundaries requires an explicit candidate-envelope/eligibility policy.

## 6. Shader implementation routes

A renderer-native element filter can avoid unnecessary shading work. An opacity/cutout wrapper can combine original opacity with an element boundary mask:

```text
finalOpacity = originalOpacity * elementVisibility
```

The actual shader must have valid instance/element identity and boundary data in its shading context. Do not sample the arbitrary shading point and call that equivalent to representative-element removal; that would clip within elements instead.

Forest's documented renderer paths differ between V-Ray and Corona/Arnold [S15]. Cyrus must qualify its own paths rather than infer that the same automatic behavior is available.

## 7. Material wrapping and optimizer

The optimizer traverses material graphs through safe host APIs. It detects existing Cyrus wrappers by persistent metadata and version, making repeated optimization idempotent. It preserves existing opacity, maps, material instances, and artist assignments.

Default operation previews changes and creates one Undo transaction. Shared materials require an explicit choice: modify the shared material or clone for the selected setup. Never unexpectedly retint unrelated objects using the same source material.

Removing the wrapper restores original connections when possible. Unsupported shader graph nodes are reported and left unchanged rather than partially rewritten.

## 8. Animation modes

Provide disabled/static, synchronized source time, discrete random offsets, map-selected offset samples, and map-selected absolute frame. These correspond to the broad capabilities described in the source study and animation reference [R0 §5.6; S16].

Cyrus defines their time equations explicitly:

```text
Synchronized:  sourceTime = sceneTime
Offset:        sourceTime = sceneTime + selectedOffset
Absolute map:  sourceTime = frameMap(value)
```

A selected offset is stable per instance. A mapped sample selects from a saved sample table; it is not the same as continuously interpolating all geometry states.

## 9. Time units, looping, and rounding

Store time in a rational or integer tick representation tied to the host conversion contract. Frame-rate changes must not silently change whether an authored value means frames or seconds. Controls declare their units.

Loop mode uses an explicit half-open interval and mathematical modulo for negative times. Clamp mode uses defined endpoints. Discrete sample selection uses a specified rounding policy. Motion blur samples are evaluated at shutter times, not rounded to viewport frames unless an explicit approximation is selected.

## 10. Geometry-sample cache

Key samples by source UUID/content revision, evaluated time, topology/material requirements, and renderer profile. Many instances can share one sample. A bounded cache evicts only unreferenced samples; active render references pin entries.

Forest documents bounded animation-sample caching [S16]. Cyrus's default budget is a proposed value in the control catalog, not copied as a universal optimum. The actual memory model includes both host-evaluated geometry and renderer-translated prototypes.

If animated topology changes, element IDs and per-element masks can become invalid. Either regenerate decomposition per sample with declared identity limits or disable incompatible per-element persistence. Do not reuse a first-frame triangle index blindly.

## 11. Wind is a separate capability

Varying the phase of an already animated plant does not generate wind deformation. Wind requires a source deformation system or a plant-generation module. The companion design in chapter 26 can provide it later without redefining scatter animation semantics.

## 12. Motion bounds and collisions

Default collision checks use the selected static placement proxy, not a full motion envelope. An optional motion-clearance mode uses conservative bounds across the configured time interval. It costs more and can reject more objects.

LOD and render culling use bounds appropriate to their sampled time or motion policy. A plant swaying outside its cached static bound must not disappear due to stale object-level culling.

## 13. Tests

Use two instances of one mesh with different tint, two disconnected elements with different tint, a shared leaf-opacity material, repeated optimizer runs, a patch crossing a boundary, animated topology, negative frame offsets, different frame rates, and repeated headless renders. Confirm that material-only edits do not regenerate placements and that unsupported element routes fail explicitly.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S13]: https://docs.itoosoft.com/forestpack/forest-plugin/material
[S14]: https://docs.itoosoft.com/forestpack/forest-color
[S15]: https://docs.itoosoft.com/forestpack/forest-edge-map
[S16]: https://docs.itoosoft.com/forestpack/forest-plugin/animation

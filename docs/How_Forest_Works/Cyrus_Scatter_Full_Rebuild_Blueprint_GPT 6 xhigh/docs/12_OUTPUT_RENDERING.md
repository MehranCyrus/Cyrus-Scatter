# 12 — Viewport, camera/LOD, renderer output, shading and animation

## 1. One accepted population, several representations

The central invariant is that preview, picking, render, and baking consume the same stable accepted instance snapshot but may represent it differently.

```text
AcceptedInstanceSnapshot + SourceLibrary
    ├── GPU point/box/proxy/mesh preview
    ├── instance-ID picking and manipulation
    ├── camera/LOD-filtered render streams
    ├── scatter statistics
    └── bake to editable objects or independent scene assets
```

**[FP-DOC]** ForestPack's Display rollout separates mesh/adaptive/proxy/point-cloud viewport modes and renderer modes. Its point cloud defaults to a capped ~250,000 points per Forest object, with GPU data generally updated when the Forest object changes rather than on every orbit. [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display).

## 2. Viewport representation modes

Recommended modes:

| Mode | Representation | Cost/usage |
|---|---|---|
| Points | Stable selected subset of points, optional tinted/shaded | Fast large-scene overview |
| Cross/Arrows | One marker per chosen preview instance | Orientation diagnostics |
| Boxes | Simplified source bounds | Spatial occupancy and collision preview |
| Proxy | Low-poly replacement or specialized preview mesh | Understand individual silhouette |
| Mesh | Full source mesh preview under budget | Detailed close-up work |
| Adaptive | Select representation based on pixel/face/instance budgets | General default |
| Diagnostic | Color by source/area/reject/receiver/ID | Debug and authoring |

Viewport drawing should reuse immutable buffers and avoid regenerating candidates on pure navigation except when a camera-dependent population or Effect explicitly requires it. GPU uploads should be measured separately from GPU draw time and CPU evaluation.

### Stable preview subset

For a desired preview fraction `q`, accept preview item when `hash01(instanceID,"preview") < q`. Increasing preview quality then adds items instead of reshuffling previously visible ones. A hard point-count budget requires deterministic rank selection or representative sampling over spatial cells; naive first-N leads to biased previews. ForestPack's exact method is not documented.

### Picking

Associate each preview item with stable `InstanceId`; implement GPU-ID picking or CPU ray/BVH picking with a visible selection-quality budget. A low-density point preview shouldn't make an artist unable to select intended hero trees; selected items may use a denser dedicated overlay. Handle multiple scatters and instances at the same screen position with disambiguation UI.

## 3. Camera culling is not population density reduction

[FP-DOC] ForestPack Camera options include visibility limits, Expand, Far Clipping, Back Offset, Look At, LOD activation, distance/scale falloffs, environment range and look-at target. The docs warn camera-dependent scatter/view changes may cause popping or performance overhead. [Camera reference](https://docs.itoosoft.com/forestpack/forest-plugin/camera).

Different operations:

- **Cull for output:** skip instances invisible under declared camera visibility/shadow policy.
- **Reduce distant population:** change accepted/selected item count with distance, potentially causing popping.
- **Select LOD:** preserve instance, change geometry/material representation.
- **Look-at:** modify presentation orientation, e.g. billboard facing camera.

Culling is output dependent: shadows and reflections can require outside-frustum geometry. Provide `Strict Primary Camera`, `Conservative with Margin`, and `No Culling` as selectable modes with warnings.

For animation, define shot-aware bounds (union of frusta over frames) and optional hysteresis/temporal coherence; do not re-randomize instance source/rotation per frame. A swept camera envelope is proposed Cyrus enhancement.

## 4. LOD

**[FP-DOC]** ForestLOD selects source alternatives by camera distance or screen-space size and supports varying materials. It is not automatic polygon decimation. [Forest LOD](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod).

Source contains:

```cpp
struct LODLevel {
    SourceAssetId asset;
    MaterialBinding optionalMaterial;
    float minScreenSizePx;
    float maxDistanceWorld;
    float hysteresis;
};
```

Distance vs screen-area selection are different policies; use ordered levels and explicitly defined boundary inclusivity. Preserve per-item LOD state across frames if animation needs hysteresis. Renderer-specific proxy systems may already implement LOD; avoid double-switching and feature interference.

## 5. Rendering

Use renderer-native instances where verified. The host renderer adapter receives source references evaluated at a particular time, material binding, transforms, per-instance attributes, motion blur/time samples, and clipping policies. Avoid creating separate Max scene nodes for every plant.

**[FP-DOC]** ForestPack Automatic render mode uses supported renderer instancing/proxy capabilities where available; Meshes mode combines geometry and has different scaling limitations. [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display). Details of actual renderer interfaces must be verified in target SDK versions.

Renderer adapter contracts are in `19_RENDERER_ADAPTERS.md`. Always include a safe generic fallback where possible, but label degraded semantics clearly (e.g. no native per-instance tint/animation, high memory, missing edge trimming).

## 6. Per-instance shading

**[FP-DOC]** ForestPack Material rollout supports randomized gradients and maps, color correction and Forest Color/Material integration. Forest Color can vary at whole-instance and sub-element granularity; Forest Edge depends on compatible rendering/material handling. [Material](https://docs.itoosoft.com/forestpack/forest-plugin/material) · [Forest Color](https://docs.itoosoft.com/forestpack/forest-color) · [Forest Edge](https://docs.itoosoft.com/forestpack/forest-edge-map).

Cyrus attribute stream should include `itemId`, `sourceId`, `tint`, `tintStrength`, `colorCorrect`, `materialVariant`, `animationOffset`, optional user fields, and a stable per-mesh-element hash where needed.

Avoid making 100,000 copied materials just to vary tint. Adapter should attach attributes through renderer-supported instance attributes, material maps/shaders, or another verified pathway. If a renderer cannot consume it, warn and offer bake/fallback mode.

### Material wrapping must be idempotent

For any material optimizer/cutout injection, inspect whether a compatible node has already been inserted; update parameters instead of wrapping again. Preserve existing opacity, normals, reflection, UV, bump, displacement and user-defined material hierarchy. Use undoable transactions and support recovery of original material graph.

## 7. Animation and time-varying sources

**[FP-DOC]** ForestPack documents Disabled, Follow Geometry, Random Samples, Random from Map and Frames from Map. ForestPack 9 has bounded animation sample memory with a documented default ~10 GB cache. Some custom renderer integration interfaces do not support every mode. [Animation](https://docs.itoosoft.com/forestpack/forest-plugin/animation).

Design:

- `Disabled`: freeze source to declared reference time.
- `FollowGeometry`: source evaluated at scene time for all instances.
- `RandomSamples`: pick one of fixed start offsets deterministically using item ID.
- `RandomFromMap`: map controls offset/sample index, preserve UV semantics.
- `FramesFromMap`: map selects absolute source sample; can vary over time.

Key geometry-state cache as `(sourceId, sampleTime, sourceRevision, evaluationMode, rendererVersion)`, bounded LRU. One cached source state can serve thousands of instances. If source animation is deformation per frame, distinguish instance time offset from a static sampled geometry snapshot.

### Motion blur caveat

Renderer motion blur may need multiple source/transform samples per frame. A one-frame mesh snapshot is insufficient for deformation blur; the adapter must supply multiple appropriate time samples and handle topology-changing animations with documented limitations.

## 8. Render-source types

Mesh, proxy, external procedural, compound group, billboard, camera-facing object and supported non-geometric objects need separate capability checks. Lights are not equivalent to triangles and may require host/renderer-specific instancing APIs or explicit fallbacks. Geometry/material use on groups must preserve child transforms and material IDs.

## 9. Export / bake

Artist selects output target: Max instances (where practical), actual cloned objects, combined mesh, renderer-native proxy transform list, or neutral per-instance interchange data. Baking should be undoable and allow only selected scatters/areas/sources. Warn about very large node/face counts. Preserve IDs in custom properties where feasible for later lookup, and never destroy the original scatter unless explicitly requested.

## 10. Viewport/render test matrix

- 1M accepted grass, point cloud budget stable during camera orbit.
- Small subset picked with stable IDs after density/preview changes.
- Camera orbit does not rebuild candidate reservoir without camera-dependent rules.
- Camera expansion/back offset reduces obvious clipping/popping on animation.
- LOD switches stable under hysteresis and supports material variants.
- V-Ray/Corona/Arnold each receive unique source, transform, tint and animation according to declared adapter capabilities.
- Material helper applied twice leaves identical effective graph.
- Renderer edge trimming matches declared element semantics.
- Motion-blurred animation output tested at several frames.
- GPU device loss recovers derived buffers; accepted instances unchanged.

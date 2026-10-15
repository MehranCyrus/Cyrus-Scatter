# 19 — Renderer adapter contracts and per-renderer capability validation

## 1. Do not design the engine around a single renderer's API

A scatter source can be a native mesh, renderer proxy, procedural, animated object, group or compatible light. Arnold, Corona and V-Ray support different pathways for instancing, per-instance shader data, motion blur, clipping and procedural source evaluation. This chapter proposes a neutral contract; **actual renderer hooks/class IDs must be confirmed against installed renderer SDKs**. No claim is made that all features are supported identically today.

**[FP-DOC]** ForestPack Automatic render mode uses renderer capabilities, while Meshes mode combines geometry. Its documentation also describes renderer-specific Forest Edge and sampled-animation differences. [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display), [Animation](https://docs.itoosoft.com/forestpack/forest-plugin/animation), [Forest Edge](https://docs.itoosoft.com/forestpack/forest-edge-map).

## 2. Common neutral render stream

```cpp
struct RenderSource {
    SourceId sourceId;
    RenderAssetHandle rendererSpecificOrMesh;
    MaterialBinding material;
    TimeSampleId evaluatedTimeState;
    Bounds3 conservativeBounds;
    uint32_t sourceFlags;
};

struct RenderInstance {
    InstanceId instanceId;
    uint32_t sourceIndex;
    Matrix4 transform;
    float time;
    AttributeIndex attributes;
    uint32_t elementMaskIndex;
};

struct RenderStream {
    uint64_t snapshotRevision;
    std::vector<RenderSource> sources;
    std::vector<RenderInstance> instances;
    AttributeBuffers attributes;
    CameraVisibilityPolicy cullingPolicy;
};
```

The backend resolves source handles and adapts to renderer semantics. Group children can expand to multiple render instances while sharing one parent logical `InstanceId`; stable child keys are required for per-element selection/tint.

## 3. Capability discovery

```cpp
struct RendererCapabilities {
    bool nativeMeshInstancing;
    bool customProxyInstancing;
    bool proceduralSourceSupport;
    bool nonGeometryInstances;
    bool perInstanceColor;
    bool perInstanceFloat;
    bool animatedSourceSamples;
    bool transformMotionBlur;
    bool deformMotionBlur;
    bool elementBoundaryTrim;
    bool visibilityFlags;
    bool sourceMaterialOverride;
    bool cameraCullingSafety;
};
```

Every feature with renderer dependence queries capabilities before enabling or committing a render. Capabilities are versioned (renderer build + Max version + adapter version), not guessed from renderer name alone.

## 4. Rendering handshake

1. Renderer requests scene geometry at evaluation time and camera context.
2. Cyrus obtains or rebuilds an immutable accepted population snapshot consistent with time and scene revisions.
3. Camera/output policy computes visible subset and LOD, respecting shadow/reflection options.
4. Source resolver prepares renderer-compatible source assets and time samples.
5. Render adapter streams instance transforms and attributes.
6. Adapter registers/releases renderer resources according to SDK lifecycle.
7. Error/fallback counters report omitted sources, downgraded materials and unsupported animation.

Protect against recursive render callbacks or scene mutations originating from render export. Renderer source evaluation may depend on current time; don't cache across frames incorrectly.

## 5. Primary renderers: an initial verification matrix

**Unverified by design**. Fill results only after testing installed SDKs. `T` = required test, `—` = not established, never infer support.

| Capability | V-Ray | Corona | Arnold | Fallback |
|---|---|---|---|---|
| Native mesh instancing | T | T | T | Combined mesh / node bake |
| V-Ray/Corona/Arnold proxy source | T | T | T | Host mesh if resolvable |
| Per-instance tint | T | T | T | Baked material variants (limited) |
| Per-element tint | T | T | T | Specialized shader or unsupported |
| Boundary Edge trim | T | T | T | Preprocess/opacity material if safe |
| LOD source switching | T | T | T | Explicit level-selected mesh |
| Discrete animation source samples | T | T | T | Evaluated mesh source state per sample |
| Deformation motion blur | T | T | T | Warn if unavailable |
| Non-geometry/lights | T | T | T | Warning or explicit native node bake |
| Camera shadow margin policy | T | T | T | Conservative no-cull |
| Interactive render/live updates | T | T | T | Refresh-compatible fallback |

The intention is not to imply missing capabilities; it is to avoid silently promising them before SDK validation.

## 6. Material and attribute bridge

Use stable item/source/element IDs to derive tint and material variation. Preferred path is **one source mesh/material plus per-instance attributes** when renderer supports it. Otherwise consider a bounded variant palette; document limits and color quantization. Shader injection must preserve existing opacity/cutout, displacement, normal/bump, layered materials and referenced material graph.

For Forest Edge-style trimming, evaluate sub-element classification using boundary data and supply an element visibility/cutout field through renderer capability. Don't implement arbitrary triangle Boolean clipping under the name Edge.

## 7. Motion blur and animation

Handle:

- static transform instances;
- animated transform with sampled transforms;
- animated deformation with source-geometry time samples;
- per-instance animation time offsets;
- topology-changing sources (possible loss of deformation interpolation);
- shutter samples and renderer motion ranges.

Cache `(source, time, revision)` samples, not one unique mesh per instance. Bound memory and evict LRU states only when renderer no longer holds references. A lifetime bug can crash render process after cache eviction.

## 8. Renderer resource ownership

Adapters must explicitly specify thread ownership, host references, ref counts, callbacks, resource-release timing, cancellation and scene shutdown behavior. Do not release a source buffer while a render worker is consuming it. Use immutable snapshot handles with strong ownership through render completion, separate from UI refresh lifetimes.

## 9. Camera visibility and shadows

Camera FOV culling can remove geometry casting shadows/reflections into frame. Conservative expansion and back offset can alleviate popping, but they do not guarantee perfect secondary visibility. Provide `No Cull`, `Primary FOV only`, `Expanded FOV`, `Shot Envelope` policies and surface warnings. Include rays/visibility extensions only when renderer exposes suitable data safely.

## 10. Render acceptance tests

One scene, fixed IDs, fixed time, three sources including source material IDs, tint, two LODs, animated source and boundary trim. Compare:

- distinct source usage;
- transform/scale/orientation correctness;
- per-instance tint and sub-element tint;
- opacity/cutout/material preservation;
- camera and shadow correctness;
- source animation phase/motion blur;
- asset lifetime and render memory;
- live IPR updates and render cancellation.

Export a per-renderer capability report, screenshots and memory/log metrics. Any renderer that fails must surface an accurate specific warning and a documented fallback.

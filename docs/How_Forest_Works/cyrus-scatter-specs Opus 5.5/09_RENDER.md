# 09 Render Output

## 1. Purpose and scope

This specification defines how Cyrus Scatter turns the immutable S12 `PublishedPopulation` into render output. It covers the Autodesk render-time instancing provider, aggregate mesh fallback, per-instance channels, motion blur, Edge boundary behavior, renderer adapters, source hiding, lifecycle, streaming, baking, and export. It extends the S0 to S12 contract in 00 and does not redefine the core `Population`, `ViewMask`, `StableKey`, `GeometryTable`, or `SharedCacheRegistry` types.

The render layer is in `max/render`, with shared plain-data batching in the core. Max scene access and renderer SDK calls stay in the adapter. A render evaluation pins one immutable snapshot and one published population version. No viewport rebuild may mutate that data while the renderer is traversing it.

The primary path is native render-time instancing through Autodesk's documented `MaxSDK::RenderTimeInstancing::RenderTimeInstancingInterface`, with `RenderInstanceSource` and `RenderInstanceTarget` objects. The exact method signatures and namespace spelling must be verified in the SDK headers for the target Max version. The public Autodesk API is the authority. Do not substitute unverified names such as `IRenderInstance` or `IInstanceShapeProvider`.

## 2. Forest Pack behavior to match

* **[FP-DOC]** Forest Automatic render mode uses renderer capabilities and source type to choose instances, meshes, or proxies. Meshes mode builds one mesh and is useful when one Forest is used as another Forest's source: [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display).
* **[FP-DOC]** Current Forest render limits are 1,000,000 objects and 5,000,000 faces. At a limit Forest shows an F icon and reports a warning. Zero removes a limit but may cause slowdowns or crashes: [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display).
* **[FP-DOC]** Hide Custom Objects before rendering prevents the original source geometry from rendering a second time: [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display).
* **[FP-DOC]** Compatible renderers can instance ordinary mesh sources. Proxies can stream from disk and use less RAM, but require files on render nodes and may be slower: [Rendering best practice](https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice).
* **[FP-DOC]** Forest Color and Forest Material carry per-instance tint and material behavior; Forest Color can work at Item or Element level. An Element is a connected face group sharing a material ID, not an individual face: [Forest Color](https://docs.itoosoft.com/forestpack/forest-color), [Material](https://docs.itoosoft.com/forestpack/forest-plugin/material).
* **[FP-DOC]** Forest Edge trims at render time. V-Ray can use Edge without a map; Corona and Arnold use a Forest Edge map in Opacity or Cutout, optionally wrapping an existing alpha: [Forest Edge](https://docs.itoosoft.com/forestpack/forest-edge-map).
* **[FP-OBS]** Forest's render-facing instance data includes a `tintUVW` clue in Forest Pack 7 beta material. That is evidence for carrying tint state into a renderer, not proof of a public Cyrus ABI: [Forest Pack 7 beta](https://www.itoosoft.com/blog/forest-pack-7-beta-try-it-now).
* **[FP-DOC]** Forest Tools converts a scatter into ordinary instances, can put them in a layer, freeze them, display boxes, auto-delete previous output, and disable or hide source geometry after baking: [Forest Tools](https://docs.itoosoft.com/forestpack/instantiating-and-exporting/forest-tools).
* **[FP-DOC]** Autodesk documents `RenderTimeInstancingInterface`, `RenderInstanceSource`, and `RenderInstanceTarget`. Renderers can iterate sources and targets from multiple threads. The API supports transforms, custom data channels, and motion data: [RenderTimeInstancingInterface](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_render_time_instancing_1_1_render_time_instancing_interface.html), [RenderInstanceSource](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_render_instance_source.html), [RenderInstanceTarget](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_render_instance_target.html).
* **[UNKNOWN]** Public Forest material does not prove whether Forest internally uses Autodesk's current interface or a renderer-specific bridge. Cyrus will expose the Autodesk provider and optional renderer adapters, but will not claim internal Forest compatibility.

## 3. Render parameters

These parameters are in the Render rollout unless noted. The defaults 1,000,000 and 5,000,000 match current Forest documentation. Other defaults are Cyrus choices and are marked [DESIGN].

| UI name | Internal name | Type | Default | Range or units | Rollout | DirtyBits | Notes |
|---|---|---|---|---|---|---|---|
| Render Mode | `p_renderMode` | enum | Automatic | Automatic, Meshes | Render | `D_RENDER` | Automatic selects native provider, adapter, or fallback. |
| Render Max Items | `p_renderMaxItems` | u32 | 1,000,000 | 0 or positive count | Render | `D_RENDER` | Zero means no limit, subject to safety policy. |
| Render Max Faces | `p_renderMaxFaces` | u32 | 5,000,000 | 0 or positive count | Render | `D_RENDER` | Applied to aggregate fallback; native instance paths may ignore it. |
| Source hiding | `p_hideSources` | bool | true | on/off | Render | `D_RENDER` | Hide only during the Cyrus render transaction. |
| Hide source policy | `p_hideSourcePolicy` | enum | ReferencedOnly | ReferencedOnly, AllList, Never | Render | `D_RENDER` | ReferencedOnly avoids hiding unrelated nodes. |
| Automatic adapter | `p_autoAdapter` | enum | Autodesk | Autodesk, RendererModule, MaxInstances | Render | `D_RENDER` | Renderer module is selected by capability matrix. |
| Stream sources | `p_streamSources` | bool | true | on/off | Render | `D_RENDER` | Allows source batches to be released after renderer consumption. |
| Source memory cap | `p_sourceMemoryCap` | u64 | 4 GB | bytes | Render | `D_RENDER` | Per-process budget [DESIGN], SharedCacheRegistry also has a cap. |
| Motion blur | `p_motionBlur` | bool | true | on/off | Render | `D_ANIMATION` | Requires renderer and source support. |
| Motion samples | `p_motionSamples` | int | 2 | 1 to 16 | Render | `D_ANIMATION` | Shutter endpoints plus optional sub-samples. |
| Velocity channel | `p_velocityChannel` | enum | Auto | Off, Auto, Custom | Render | `D_ANIMATION` | Custom data when renderer can read it. |
| Edge mode | `p_edgeMode` | enum | Disabled | Disabled, ElementMask, CyrusEdgeMap | Render | `D_BOUNDARY` | Capability matrix may force fallback. |
| Edge preview | `p_edgePreview` | bool | false | on/off | Render | `D_BOUNDARY` | Viewport preview is expensive. |
| Edge softness | `p_edgeSoftness` | float | 0 | system units | Render | `D_BOUNDARY` | Zero is a hard element decision. |
| LOD policy | `p_renderLodPolicy` | enum | Camera | Source, Camera, Override | Render | `D_CAMERA` | LOD is part of source dedup key. |
| F warning icon | `p_showLimitWarning` | bool | true | on/off | Display | `D_DISPLAY` | Draws the F icon and diagnostic. |
| Bake layer | `p_bakeLayerName` | string | `Cyrus_Baked` | layer name | Tools | none | Tool setting, not population input. |
| Bake freeze | `p_bakeFreeze` | bool | true | on/off | Tools | none | Freezes baked nodes after creation. |
| Bake boxes | `p_bakeBoxes` | bool | false | on/off | Tools | none | Display optimization. |
| Bake auto-delete | `p_bakeAutoDelete` | bool | true | on/off | Tools | none | Deletes prior tagged bake only. |
| Export format | `p_exportFormat` | enum | JSON | JSON, XML, CSV | Tools | none | Export is a snapshot operation. |
| Export channels | `p_exportChannels` | string | standard | field list | Tools | none | StableKey, transform, source, color, visibility by default. |

## 4. Data model and provider design

### 4.1 Core render records

The core converts S12 into source batches without Max headers:

```cpp
struct SourceKey {
    u64 nodeHandle;
    i64 timeOrAnimSample;
    u64 materialState;
    u16 lod;
    u16 proxyState;
    bool operator==(const SourceKey&) const = default;
};

struct RenderInstanceRecord {
    StableKey key;
    u32 sourceIndex;
    Mat4f tm;
    Mat4f prevTm;
    Vec3f velocity;
    Vec3f angularVelocity;
    u32 tintRGBA8;
    float randomValue;
    u16 geomColorId;
    u16 materialOffset;
    u16 animSample;
    u16 edgeMaskIndex;
    u32 flags;
};

struct RenderSourceBatch {
    SourceKey key;
    SourcePayload payload;       // immutable mesh, proxy token, or renderer source
    std::vector<RenderInstanceRecord> records;
};
```

`sourceIndex` points into a per-render immutable source table. `RenderInstanceRecord` carries only values that vary per instance. GeometryTable source identity and entryId remain available for diagnostics and export. `tm` is in world space for the renderer provider. The conversion from FL to world is done once per record batch, not by reconstructing a Max node for every item.

The `randomValue` is the StableRNG output for a named shading purpose, not a random sequence position. `tintRGBA8` is the final S11 tint. `geomColorId` is the Geometry List Color ID. `materialOffset` points into a deterministic combined material table. `edgeMaskIndex` is an index into an element mask table or zero when Edge is disabled.

### 4.2 Source deduplication

Deduplicate by:

```text
(node handle, time or animation sample, material state, LOD state, proxy state)
```

This matches the required source key and extends the 00 cache key with renderer state only at the render boundary. Material state includes the source material identity, override material identity, consolidated Multi/Sub remap, and a renderer adapter version. LOD state includes the selected source level and screen or distance policy. Proxy state includes file path, file hash, renderer, and proxy animation state.

Two list rows can point to the same node and share a source batch when all key fields match. They still retain distinct entry IDs and per-instance Color IDs or material offsets. Do not merge records across different material overrides merely because their mesh topology is equal. A future content hash optimization can merge identical geometry with a separate material binding, but it must not change StableKey identity.

Source creation is lazy. Build a source descriptor during batch planning, then materialize its mesh or renderer source on first use. The source descriptor is immutable and reference counted. The source cache key includes `SourceKey` and `snapshot.sourceVersion`; a source change cannot contaminate a concurrent render.

## 5. RenderTimeInstancingInterface provider

### 5.1 Verified API surface and naming caution

Autodesk's current documented public API is in `MaxSDK::RenderTimeInstancing`. Use the documented class `RenderTimeInstancingInterface` and its `RenderInstanceSource` and `RenderInstanceTarget` types. The exact virtual methods, ownership conventions, custom-channel accessors, and motion signatures must be read from the SDK headers used by the plug-in. Documentation links use names such as source and target, but code must compile against the installed Max SDK rather than copy a signature from a different version.

The Cyrus class is a thin adapter:

```cpp
class CyrusRenderInstancing final
    : public MaxSDK::RenderTimeInstancing::RenderTimeInstancingInterface {
public:
    explicit CyrusRenderInstancing(std::shared_ptr<const RenderFrame> frame);
    // Override the exact source, target, count, and channel methods
    // declared by the selected Max SDK.
private:
    std::shared_ptr<const RenderFrame> frame_;
};
```

`GetInterface` returns the provider when the requested interface ID matches the SDK declaration. The provider pins `RenderFrame` until every source and target has been released. It must not hold a raw pointer to a temporary mesh or to a mutable Population.

### 5.2 Source and target mapping

A `RenderInstanceSource` describes one deduplicated source. Depending on the API method and renderer, the source may be associated with an evaluated node, a mesh, or a source object interface. Cyrus supplies the immutable source payload and material binding using the documented source methods. If the source API requires a node, use a private hidden source node only when the SDK contract requires it, and reuse one node per source key. Do not create one node per instance.

A `RenderInstanceTarget` describes one placed instance. Its transform methods return `tm` and, when motion is active, a sequence or pair of transforms. Custom data methods expose channels from `RenderInstanceRecord`. The target must be cheap to construct and safe for renderer iteration. Store target records in a contiguous immutable array and use a renderer-thread-local wrapper around each record.

The provider must obey Autodesk's threading rule: multiple renderer threads may iterate source and target collections, but a single thread must not concurrently access multiple targets in a way disallowed by the API. The safest design is immutable arrays, no lazy mutation in accessors, no Max scene calls from accessors, and thread-local scratch for conversion. Source materialization happens before traversal or under a once-only render-frame barrier.

### 5.3 Custom data channels

Register channels with stable names and documented types. The minimum Cyrus channels are:

| Channel | Type | Meaning |
|---|---|---|
| `cyrus.tintRGBA8` | uint32 | Final per-instance tint and multiplier. |
| `cyrus.random` | float | Stable random shading value. |
| `cyrus.geomColorId` | uint16 | Geometry List Color ID. |
| `cyrus.materialOffset` | uint16 | Combined material or sub-material offset. |
| `cyrus.animSample` | uint16 | Selected animation sample. |
| `cyrus.stableKeyLo` | uint32 | Low key bits for diagnostics and external shaders. |
| `cyrus.edgeMask` | uint16 | Element mask table index. |
| `cyrus.tintUVW` | Vec3f | Optional UVW fallback for Cyrus Color. |
| `cyrus.velocity` | Vec3f | Per-instance linear velocity when supported. |

The exact Autodesk channel registration method is SDK-version-specific. Use typed channels if the API supplies them. If it supplies only a generic custom-data blob, define a packed, aligned structure with a schema version and endian-neutral field order. Never rely on C++ struct padding as an ABI.

`Cyrus Color` reads `cyrus.tintRGBA8`, `cyrus.random`, and optional `cyrus.tintUVW`. If a renderer cannot read custom instance channels, the render adapter writes a per-instance fallback UVW or material payload according to the capability matrix. The UVW fallback is not a license to mutate source UVs globally. It is a stable per-instance mapping, normally encoded in a reserved map channel or generated shader coordinate.

## 6. Motion blur and animation samples

The canonical S12 population stores `animSample` but not a renderer-specific motion object. At render begin, the adapter requests snapshots at shutter sample times. For each sample, it evaluates animated source geometry and transforms on the main thread, builds immutable source batches, and computes per-instance transforms using the same StableKey and random purposes. A moving object therefore moves the same item rather than creating a new item at each sub-frame.

For transform-only motion, `prevTm` and `tm` or the SDK's multi-transform method are enough. For deforming source geometry, the source key includes animation sample and the provider supplies a motion-capable source representation if the renderer supports it. If the renderer cannot accept deforming source motion, use discrete sub-frame source batches or disable source motion blur with a diagnostic. Do not interpolate topology or material changes blindly.

Velocity is derived in world space from the transform samples:

```cpp
Vec3 linearVelocity(const Mat4& a, const Mat4& b, double dt) {
    if (dt <= 0.0) return Vec3(0, 0, 0);
    return (translation(b) - translation(a)) / float(dt);
}
```

Angular velocity is optional and should be reported only if the target API supports it. A robust fallback is to provide two transforms and let the renderer interpolate. All samples use a bounded shutter range and are checked for cancellation only before render traversal. Once a renderer has received a frame, its data remains pinned.

The S0 validity interval for a render frame is the intersection of the source and parameter validities at all requested samples. If an animation controller changes during a render, Max's render transaction rules take precedence. Cyrus must not publish a partially sampled frame.

## 7. Render lifecycle and memory streaming

The lifecycle is:

1. `RenderBegin` receives the render context, time, camera, renderer identity, and motion sample request.
2. Resolve `EvalMode::Render` and build or retrieve S0 to S12 snapshots for all needed times.
3. Build the `RenderFrame` capability matrix and apply camera ViewMask if render clipping is enabled.
4. Hide referenced source nodes if `p_hideSources` is enabled, recording their original render visibility and hidden state.
5. Build source descriptors and instance batch indexes. Enforce limits before materialization where possible.
6. Expose the `RenderTimeInstancingInterface` provider. A renderer may iterate it from multiple threads.
7. Stream source payloads and target records. Keep source payloads alive until the renderer signals completion or the render frame ends.
8. At end of frame or render, restore hidden source states, release pinned source caches, and publish Stats diagnostics.
9. `RenderEnd` clears transient frame data but leaves reusable SharedCacheRegistry entries subject to LRU eviction.

For large populations, do not allocate one target object per instance. Store compact records in chunks, for example 64K records per chunk [DESIGN]. A source batch index maps each source to chunks. The renderer adapter exposes a chunk and releases it only after consumption. If the SDK requires random target access, keep compressed records and page in source chunks while respecting renderer lifetime requirements.

The memory budget is tracked separately for source topology, target records, material tables, motion samples, Edge masks, and fallback meshes. If `sourceMemoryCap` is reached, prefer proxy streaming, then source batch serialization, then a diagnostic error. Do not silently drop instances. If the render Max Items cap is reached, the output is intentionally limited and receives the F warning.

Render caches are keyed by render frame sourceVersion, camera and renderer capability where relevant. A camera-only ViewMask change should not rebuild source topology. A source geometry edit invalidates source descriptors and all batches that use the source key. The object pins only the cache entries it needs for the frame.

## 8. Aggregate GetRenderMesh fallback

`GetRenderMesh(t, inode, view, needDelete)` is used when the renderer does not consume the provider, when `Render Mode=Meshes`, or when a capability matrix forces fallback. The algorithm is:

1. Build a render frame and compact all `F_ALIVE` records visible in the render ViewMask.
2. Sort records by source key, material binding, and stable key. Sorting makes output deterministic and improves source reuse.
3. Check Render Max Items before adding geometry. If exceeded, stop at the deterministic prefix and set `limitedByItems`.
4. For each source group, transform and append vertices and faces to an output `Mesh`, remapping material IDs.
5. Check Max Faces after each source group and stop before exceeding the cap. Set `limitedByFaces`.
6. Build or assign a combined material table if the fallback mesh uses multiple source materials.
7. Set `needDelete` according to Max's ownership contract and return the mesh.

For a Meshes mode that is consumed as another Cyrus source, preserve a source-to-element map so Edge and material offsets can still be applied where supported. If the output is a single aggregate mesh and the target renderer has no per-instance channel path, Cyrus Color and element-level Edge may be unavailable. Report that limitation rather than baking tint into source materials in a way that changes subsequent instances.

The F icon is a display diagnostic, not geometry. When the render cap truncates output or a source fails, `Display` and `IObjectDisplay2` draw a small F badge at the Cyrus node icon position and Stats reports the reason, requested count, emitted count, face count, and relevant limit. If both caps are zero, the safety policy can still abort at a hard process limit [DESIGN] to protect Max; this must be clearly labeled as a Cyrus safety limit.

`GetRenderMesh` must call `View::CheckForRenderAbort()` at bounded intervals. A render abort releases temporary batches and restores source visibility through the render transaction guard.

## 9. Render modes and source visibility

Automatic mode chooses in this order:

1. Autodesk render-time instancing provider when the renderer advertises support and the source can be represented.
2. Optional renderer adapter when it provides a more capable native path, for example renderer-specific proxy or channel support.
3. Aggregate `GetRenderMesh` when instancing is unavailable or the user selects Meshes.
4. Max-instance bake only when explicitly requested by the user, never as a hidden render side effect.

Meshes mode always uses the aggregate path unless a renderer adapter exposes a better equivalent while preserving Meshes semantics. Automatic mode may still select an aggregate path for non-geometric sources, unsupported Edge channels, or a renderer that requires a mesh.

When hiding sources, first gather all GeometryTable rows with a referenced source node. Resolve children under the authored Include Children and Keep Group Hierarchy policies. Record each node's render visibility, display state, and any existing hide reason. Set only render visibility for the render transaction. At `RenderEnd`, restore exact prior state even after abort or exception. Never hide a source node that is also the Cyrus object itself or an upstream node required to evaluate the pinned snapshot.

Source hiding is not applied to XRef assets that are not present as ordinary scene nodes. Proxy renderer assets are hidden only if they have a scene representation that would otherwise double render.

## 10. Cyrus Color and per-instance shading

`Cyrus Color` is a Max texmap plug-in, separate from the scatter object. It reads a per-instance tint payload and multiplies or blends it with the incoming color according to its map parameters. The map supports Item and Element assignment where the renderer exposes a channel. Item mode reads the target's `cyrus.tintRGBA8`, while Element mode combines the source element identity, `geomColorId`, and the target tint/random payload.

The preferred path is a renderer-visible custom instance channel. The fallback path uses `cyrus.tintUVW` in a reserved map channel or an adapter-generated coordinate. A final fallback for aggregate mesh is a baked color or Multi/Sub material only when the user accepts loss of dynamic per-instance shading. Do not claim that all renderers can evaluate a Max texmap on native instances.

The map must be deterministic and stateless. It reads the channel supplied by the current instance and never looks up a mutable global map keyed by target pointer. If a channel is absent, it returns the input color and sets a one-time diagnostic. This behavior keeps ordinary source materials valid outside Cyrus.

`Cyrus Color` has a compatibility test scene with one source object, two instances with different tint and random values, and a third instance missing the channel. Each renderer must produce the expected fallback behavior, or its capability matrix must mark the unsupported channel.

## 11. Edge boundary mode

### 11.1 Canonical data

S8 marks a candidate `F_EDGE_CLIP` when its footprint intersects an include boundary under Edge mode. S0 GeometryTable extraction also builds an element table for each source:

```cpp
struct SourceElement {
    u32 elementId;
    u16 materialId;
    Bounds3f localBounds;
    std::vector<u32> vertexIndices;
    float lowestLocalZ;
};

struct InstanceEdgeMask {
    StableKey key;
    std::vector<u8> elementVisible;
    float softDistance;
};
```

An element is a connected face group sharing a material ID, matching the Forest terminology. At render planning time, transform each element's lowest-Z and relevant footprint vertices into FL or boundary space. Mark an element visible if its test point is inside the boundary, or partially visible with a soft distance if edge softness is enabled. Do not physically cut topology per instance in the canonical population.

### 11.2 Two implementation paths

**Element mask path:** If the renderer can consume custom per-instance element data or a renderer adapter can apply a source-element mask, provide `edgeMaskIndex` and a mask table. The source retains one immutable topology; the adapter rejects or fades elements during shading or geometry traversal.

**Cyrus Edge map path:** Create a `Cyrus Edge` texmap that evaluates opacity or cutout from instance edge data. For Corona and Arnold, connect it to Opacity or Cutout, optionally wrapping the source alpha. For V-Ray, use the native adapter or map path according to capability. The map can use a reserved UVW channel or custom target channel. This matches the documented Forest behavior at the concept level without claiming identical renderer ABI.

Hard edge mode sets element visibility to zero or one. Soft mode computes a clamped opacity over distance. No element is split. Therefore an element that crosses a boundary remains whole, with a potential visible pop at the element level. This matches the documented Forest Edge behavior that removes outside elements without slicing geometry.

### 11.3 Capability matrix

| Renderer path | Native instances | Custom channels | Cyrus Color | Edge mask | Edge map | Motion |
|---|---:|---:|---:|---:|---:|---:|
| Autodesk provider | verify | verify | adapter dependent | verify | Max map dependent | verify |
| V-Ray CPU | optional adapter | adapter dependent | native or fallback | adapter preferred | supported conceptually | adapter dependent |
| V-Ray GPU | renderer version dependent | renderer version dependent | partial | [OPEN] | [OPEN] | renderer dependent |
| Corona | renderer version dependent | renderer version dependent | adapter or map | [OPEN] | Opacity/Cutout path | renderer dependent |
| Arnold | renderer version dependent | renderer version dependent | adapter or Legacy Map | [OPEN] | Opacity path, Legacy Map may be required | renderer dependent |
| Unsupported | no | no | aggregate fallback | no dynamic mask | aggregate fallback | transform-only fallback |

Every cell marked verify or OPEN requires an adapter test before the renderer is advertised as supporting that feature. If Edge is requested but unsupported, use Point or Size behavior for the render and emit a prominent diagnostic. Never silently claim exact Edge trimming.

## 12. Renderer-specific adapters

### 12.1 Adapter boundary

The generic render frame exposes `SourcePayload`, transforms, material bindings, custom channels, Edge data, and motion. A renderer module translates that model into its own API. Modules are optional shared libraries and must be loaded only when the renderer is detected. The core and Autodesk provider do not include V-Ray, Corona, or Arnold headers.

Each adapter reports capabilities:

```cpp
struct RendererCapabilities {
    bool nativeInstances;
    bool sourceProxies;
    bool customInstanceData;
    bool motionTransforms;
    bool deformingMotion;
    bool elementMasks;
    bool cyrusColor;
    bool edgeMap;
    bool nonGeometricSources;
};
```

### 12.2 V-Ray

V-Ray has a mature native instancing ecosystem and Forest documentation identifies V-Ray native instancing and V-Ray Edge support. Cyrus should first implement the Autodesk provider and test whether the installed V-Ray version consumes it. An optional V-Ray adapter can supply proxy payloads, native material offsets, native tint or Edge behavior, and renderer-specific motion. The adapter must be version-gated because V-Ray CPU and GPU capabilities differ. V-Ray GPU Color limitations documented by iToo are a warning that Random Values and As Texture on Surface may not work uniformly: [Requirements](https://docs.itoosoft.com/forestpack/requirements).

Do not invent V-Ray class names in the generic module. Isolate them behind a version-specific header adapter and provide an aggregate fallback if headers or runtime ABI are unavailable.

### 12.3 Corona

Forest documents Corona native instancing and Edge maps through Opacity or Cutout, but public notes do not establish a separate `CoronaProxy` source class. Cyrus should treat Corona as a capability-tested renderer, not assume a proprietary proxy interface. The initial Corona adapter can consume the Autodesk provider if supported, pass ordinary mesh sources and material bindings, and use `Cyrus Edge` through the documented map connection when renderer map evaluation permits it. If custom instance data is unavailable, use an aggregate fallback or bake.

### 12.4 Arnold

Arnold support requires testing the Max integration version. Forest notes say Arnold may require Legacy 3ds Max Map support for Forest Color and Edge. Cyrus should expose a map-based fallback with clear setup instructions and keep custom data optional. Ordinary mesh source deduplication and motion transforms should be attempted through the Autodesk provider first. Arnold procedurals can be represented as proxy source payloads only in an adapter that verifies path resolution on every render node.

### 12.5 What remains unknown

The public Autodesk and iToo documents do not specify the private ABI that Forest uses for each renderer, the exact custom data layouts, or whether all current renderer versions consume Max's `RenderTimeInstancingInterface`. These are real limitations. The capability matrix, adapter logs, and Forest Lite comparison scenes are the source of truth for each release. A renderer must not be listed as fully supported based only on marketing compatibility pages.

## 13. Bake to Max instances

The bake tool is an explicit `CyrusBakeCommand`, not an automatic render fallback. It evaluates a render frame or current viewport frame, resolves final transforms and source bindings, and creates ordinary Max instance nodes or renderer-specific instances.

Options match the Forest Tools behavior:

* target layer name, creating it if missing;
* stand-alone nodes, group, or layer output;
* Freeze after creation;
* Boxes display mode;
* auto-delete previous bake;
* enable Cyrus before baking;
* hide or disable source geometry after baking;
* preserve materials and optional Cyrus Color or Edge bake;
* one node per source instance or a renderer-specific instanced array.

Each baked node receives a custom attribute block:

```text
cyrusBake.scatterHandle
cyrusBake.populationVersion
cyrusBake.stableKey
cyrusBake.sourceEntryId
cyrusBake.sourceKeyHash
cyrusBake.bakeRevision
```

Auto-delete removes only nodes whose `scatterHandle` and bake revision match the selected Cyrus object. Never delete by name alone. If the target layer contains unrelated objects, leave them untouched. If a source is an XRef or proxy, the baked node may remain an instance or proxy depending on the tool option. Missing sources are reported and skipped, not replaced by a random row.

Use Max's undo hold for the entire bake. For very large outputs, create in chunks and update a progress dialog with cancellation. On cancellation, delete only nodes created by this invocation, identified by a temporary bake transaction ID. The tool should warn that Max becomes slow with huge groups and recommend a layer with ungrouped nodes, matching Forest documentation.

## 14. Export XML, CSV, and JSON

Export is based on an immutable `ExportSnapshot`, never on UI list indexes. Standard channels are:

```text
stableKey, sourceEntryId, sourceKeyHash, geomId, position, rotation,
scale, mirror, tintRGBA8, random, materialOffset, animSample,
normal, uvw, surfaceId, matId, flags, edgeMask, populationVersion
```

JSON is the canonical lossless format. It includes schemaVersion, algoVersion, coordinate space, units, object handle, frame time, source table, material table, and an array or chunk stream of records. Large exports should use newline-delimited JSON or a binary sidecar with JSON metadata.

CSV is flat and intended for analysis. Quaternion fields are separate `qx,qy,qz,qw`, vectors are separate columns, and StableKey is hexadecimal plus decimal for tools that cannot handle 64-bit integers. CSV records state whether transforms are FL or world. The default is world for export tools and FL for core debugging, with an explicit header.

XML supports a Forest-style field list for pipeline consumers and legacy comparison. It must escape strings, write explicit units and schema version, and preserve unknown future channels in an extension element. A command line or FPInterface method accepts a channel list. Export must be deterministic: sort by tile index then StableKey, never by worker completion order.

## 15. Algorithms and numerical robustness

Render batch planning is O(N log N) if records are sorted by source key, or O(N) expected with a deterministic hash map followed by stable source-index order. Source materialization is O(total unique source topology). Edge mask computation is O(N times E) in the naive form, where E is source element count. Use per-source transformed element bounds and spatial culling to reduce this; for very high element counts, cache an element BVH and test only elements near the boundary.

World transforms are double precision while converting FL positions and bounds. Renderer matrices use the precision requested by the SDK. Normalize quaternions and reject non-finite values before constructing matrices. If a matrix has a negative determinant, preserve mirror state and winding policy rather than silently correcting it.

Limit enforcement is deterministic. Compute a render priority from the population order defined in 00: tile index then StableKey. Do not take whichever targets happen to be encountered first by renderer threads. For source batching, a stable prefix by sorted records makes repeated capped renders identical.

A camera ViewMask changes visibility but not StableKey or random values. A LOD choice may change the source key and target source index, but it must not reseed transforms. Motion samples reuse the same candidate key at every sample.

## 16. Diagnostics and failure modes

Stats must include:

* render mode selected and why;
* renderer name and adapter version;
* provider consumed or fallback selected;
* unique source count and source memory;
* target count before and after ViewMask;
* material and custom channel capability results;
* motion sample count;
* Edge requested, supported, and actual path;
* items and faces emitted;
* cap type and F warning state;
* source nodes hidden and restored;
* proxy paths missing or unresolved;
* export or bake transaction ID.

Failures are handled as follows:

* Provider construction fails: use aggregate fallback and report the renderer/API reason.
* A source cannot convert to render payload: disable only that source row, keep deterministic gaps, and show an error.
* A source disappears during render: the pinned snapshot remains valid; do not call the live node again. Render the last captured source or fail the affected batch clearly.
* Custom channel unsupported: Cyrus Color returns input color or uses UVW fallback. Edge reports unsupported rather than silently disabling the boundary mode.
* Max aborts GetRenderMesh: free transient geometry and restore hidden sources.
* Motion source validity differs across shutter samples: build per-sample source keys. Do not reuse the first mesh.
* Face count overflows a 32-bit mesh index: split aggregate output or fall back to native instances. Never wrap indices.
* Memory cap exceeded: prefer streaming, then proxy, then bounded fallback. Report the chosen action.

## 17. Performance targets

These [DESIGN] targets are initial acceptance criteria:

* Planning 10 million compact records into source batches: under 500 ms on 16 cores when S12 and source descriptors are cached.
* Zero per-instance Max nodes for native render output.
* One source topology copy per unique `(node,time,material,LOD,proxy)` key.
* Streaming target chunks of 64K records with less than 128 MB transient overhead per active source batch.
* Aggregate fallback must stop before its item or face cap and must not allocate an unbounded mesh.
* Edge mask generation should reuse source element caches and avoid copying topology per instance.

Measure source cache hit rate, material consolidation time, provider construction, renderer traversal time where available, and fallback mesh time separately. A fast generator can still render slowly if source materials are rebuilt per batch.

## 18. Tests and Forest Lite comparison scenes

### Unit tests

1. Equal SourceKeys deduplicate; different material, LOD, time, or proxy state does not.
2. Record order and capped output are identical at one worker and many workers.
3. `tm` and motion transforms remain finite under negative scale and mirror.
4. Custom channels preserve tint, random, Color ID, material offset, animation sample, and StableKey bits.
5. Missing channels produce defined Cyrus Color fallback.
6. Edge masks classify an element by lowest-Z test point and never mutate source topology.
7. Render abort restores source visibility and frees temporary batches.
8. Auto-delete bake deletes only nodes with matching scatter handle and revision.
9. JSON, XML, and CSV exports contain the same StableKey set and transform values.
10. Render Max Items and Max Faces produce deterministic prefixes and set F diagnostics.

### Golden render scenes

Create small scenes with one mesh source and 100 instances:

* two rows sharing a source but using different materials, proving source deduplication boundaries;
* billboard with Center Displace and Z Offset;
* source group with Include Children on and Keep Group Hierarchy on and off;
* animated source and transform motion blur at two shutter samples;
* two instances with different Cyrus Color tint and random payloads;
* Edge boundary with one element inside, one outside, and one crossing;
* V-Ray, Corona, and Arnold capability tests using the exact installed versions;
* Max Items and Max Faces limits that intentionally trigger F;
* source hiding with pre-hidden and pre-disabled source nodes;
* bake, edit source, auto-delete and rebake;
* JSON, XML, and CSV round trip.

Compare Cyrus and Forest Lite or Pro only at behavior points documented by the cited source. Renderer pixels are not a valid comparison until material and sampling settings are matched. Label exact feature differences [OPEN] until a Forest Lite test or adapter profile confirms them.

## 19. Open questions

* Which exact Max SDK release supplies the target method signatures for `RenderTimeInstancingInterface`, custom channels, and motion? Resolve at compile time and record the header version in the adapter.
* Do V-Ray, Corona, and Arnold versions selected for release consume the Autodesk provider, and which custom data types survive their traversal?
* Can the selected renderer evaluate a Max `Cyrus Color` or `Cyrus Edge` texmap on a native instance target, or must the adapter supply native shader data?
* Does each renderer support element masks without topology duplication? If not, Edge remains a renderer-specific map or aggregate fallback.
* How should deforming source geometry be represented for each provider, especially when source topology changes across shutter samples?
* What are the exact lifetime callbacks after renderer traversal, and can source chunks be released before `RenderEnd`?
* Does a renderer require source nodes rather than mesh payloads for non-geometric and proxy items?
* Can Meshes mode preserve per-instance tint and Edge semantics when it produces one aggregate mesh? If not, report the documented loss.

## 20. Architecture feedback

The 00 architecture correctly separates canonical population, view masks, render adapters, and `GetRenderMesh` fallback. One implementation requirement should be treated as non-negotiable: custom channels and renderer objects must live entirely behind the Max output layer, while the core retains plain render records. Another is that source deduplication must include material, time, LOD, and proxy state, not only a node handle. Finally, the public Autodesk API is sufficient to design the provider boundary, but renderer-specific claims remain capability-tested work, not assumptions from Forest marketing documentation.

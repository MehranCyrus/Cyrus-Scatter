# 08: Camera, view pass, and viewport display

## 1. Purpose and scope

This specification defines the view pass `V` and Cyrus Scatter's viewport representation. It covers camera capture in the snapshot, frustum culling, camera distance density and scale falloff, LOD, `ViewMask` versioning, viewport display modes, point-cloud generation and caching, viewport budgets, Nitrous integration, asynchronous publishing, selection, hit testing, diagnostics, and performance limits.

The design extends `00_ARCHITECTURE.md` without redefining its `Population`, `PublishedPopulation`, `ViewMask`, `StageContext`, `IStage`, `DirtyBits`, and `SharedCacheRegistry` contracts. The canonical population is view-independent. V reads an immutable published population and an immutable camera snapshot, then creates a view-specific `ViewMask` and optional derived transforms. V never reorders candidates, changes `StableKey`, changes density random draws, or writes canonical transform fields. The core layer has no Max headers. Max camera and Nitrous types exist only in L3 and L1 adapters.

This file does not define S1 to S12 candidate generation, renderer material plumbing, or render-time instancing. File 07 defines the canonical transform and tint payload. File 09 binds view results to renderers.

### 1.1 Forest behavior to match

Forest documents Limit to Visibility, Expand, Far Clipping Plane, Back Offset, Enable on Viewport, Copy Parameters, camera distance falloff, Look-At target distance origin, LOD distance and screen-size modes, and variation to hide LOD popping. [FP-DOC: Forest Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera), [FP-DOC: Forest LOD](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod)

Forest's current documentation states that from Forest Pack 7 the last camera view is automatically used, and the public camera page does not describe a manual camera selector in the current workflow. An explicit camera pick is still valuable for Cyrus. The documented Auto Last Used behavior and observed explicit-camera workflows are kept as a compatibility distinction, labelled [FP-DOC vs FP-OBS], because a local Forest version or tutorial may expose different behavior. [FP-DOC: Forest Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera)

Forest documents Mesh and Proxy display modes, with Plane(s), Pyramid, Box, Thin Box, Plant, and Arrow proxy shapes. Adaptive switches display representation using a face threshold. Point Cloud supports a default cap of 250,000 points per Forest object, color by item ID, diffuse color, or tint, fake shading, local density, and cached GPU data. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display)

The replication notes report `cloudPointsByObject=250000`, `cloudHitTestMaxPoints=1000`, selected density 300%, and unselected density 100%. The official current page does not publish a viewport Max Items default; the assignment requests 5,000 from a tutorial observation, so use 5,000 as [FP-OBS] and keep it version-configurable. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display), [FP-OBS: Forest display tutorial and forum notes](https://forum.itoosoft.com/forest-pro-(*)/forestpack-display-count-doesn-t-work-with-limit-to-visibility-enabled/)

Autodesk documents `IObjectDisplay2`, including `PrepareDisplay`, `UpdatePerNodeItems`, and `UpdatePerViewItems`, and documents `MaxSDK::Graphics::ViewportInstancing::InstanceDisplayGeometry` for GPU-level instances. Autodesk also documents custom Nitrous `RenderItem` support. These are verified API names, but exact SDK signatures vary by Max release and must be checked against the installed headers. [FP-DOC: Autodesk plug-in display interface](https://help.autodesk.com/cloudhelp/2020/ENU/Max-Developer-Help/files/developer/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/plug-in_display_interface.html), [FP-DOC: IObjectDisplay2](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html), [FP-DOC: InstanceDisplayGeometry](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_display_geometry.html), [FP-DOC: RenderItem](https://help.autodesk.com/cloudhelp/2023/ENU/Max-Developer-Help/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/about_renderitem.html)

Forest also documents a serious tradeoff: camera clipping or camera Enable on Viewport can force point-cloud rebuilds on view changes and reduce the cache benefit. Nested objects can lag, and legacy GraphicsWindow drawing is too slow for dense populations. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display), [FP-DOC: Forest rendering best practice](https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice)

## 2. Parameter model

Parameters below are converted by S0 into plain data. Defaults explicitly requested by the brief are labelled `[FP-DOC]` or `[FP-OBS]`; otherwise they are Cyrus starting values marked `[DESIGN]`. A camera parameter invalidates V and display caches, not S1 to S12, unless the user has enabled a feature that intentionally changes canonical render preparation.

| UI name | Internal name | Type | Default | Range and units | Rollout | DirtyBits group | Notes |
|---|---|---|---|---|---|---|---|
| Limit to Visibility | `limitToVisibility` | bool | false | On or off | Camera | `D_CAMERA` | Render culling is opt-in. |
| Camera source | `cameraSource` | enum | Auto Last Used | Auto last used, explicit node, current viewport | Camera | `D_CAMERA` | Auto behavior is documented; explicit pick is Cyrus extension. |
| Camera node | `cameraNode` | node ref | null | Max camera reference | Camera | `D_CAMERA` | Used when source is explicit. |
| Expand | `frustumExpand` | float | 0.10 | 0 to 10, fraction or percent | Camera | `D_CAMERA` | UI displays percent, for example 10%. |
| Far Clipping Plane | `farClip` | float | 0 | System units, 0 means disabled | Camera | `D_CAMERA` | A positive distance overrides camera far range for scatter visibility. |
| Back Offset | `backOffset` | float | 0 | System units | Camera | `D_CAMERA` | Extends generation behind camera along view direction. |
| Enable on Viewport | `enableOnViewport` | bool | false | On or off | Camera | `D_CAMERA` | Off by default because view changes may be expensive. |
| Copy Parameters | `copyCameraParameters` | action | none | Action | Camera | `D_CAMERA` | Copies settings to selected Cyrus objects in Max layer. |
| Density falloff | `cameraDensityFalloff` | curve | identity | Camera distance normalized 0 to 1 | Camera | `D_CAMERA` | Applied as stable thinning in V. |
| Scale falloff | `cameraScaleFalloff` | curve | identity | Camera distance normalized 0 to 1 | Camera | `D_CAMERA` | Applied as view-derived scale, not canonical scale. |
| Falloff range | `cameraFalloffRange` | float | 0 | System units | Camera | `D_CAMERA` | 0 means use camera far range or explicit far clip. |
| Use Environment Range | `useEnvironmentRange` | bool | false | On or off | Camera | `D_CAMERA` | Forest uses active camera environment range. |
| Use Look-At Target | `useLookAtTargetOrigin` | bool | false | On or off | Camera | `D_CAMERA` | Distance origin can be target pivot. |
| Look-At target | `lookAtTarget` | node ref | null | Snapshot node | Camera | `D_CAMERA` | Separate from camera selection. |
| LOD mode | `lodMode` | enum | Distance | Distance, minimum screen size | Camera | `D_CAMERA` | Forest LOD supports both. |
| LOD variation | `lodVariation` | float | 0 | 0 to 1 | Camera | `D_CAMERA` | Stable per-item threshold offset. |
| Override Max Distance | `lodMaxDistanceOverride` | float | 0 | System units, 0 means source value | Camera | `D_CAMERA` | Forest documented zero semantics. |
| LOD viewport update | `lodUpdateOnViewport` | bool | true | On or off | Display | `D_VIEWPORT` | Version-sensitive compatibility option. |
| Viewport display | `displayMode` | enum | Adaptive | Mesh, proxy, adaptive, point cloud | Display | `D_VIEWPORT` | Adaptive is a representation policy. |
| Proxy shape | `proxyShape` | enum | Box | Plane(s), Pyramid, Box, Thin Box, Plant, Arrow | Display | `D_VIEWPORT` | Proxy geometry is not a source mesh. |
| Adaptive face threshold | `adaptiveFaceThreshold` | u32 | 10,000 | Face count | Display | `D_VIEWPORT` | Default [DESIGN], verify Forest version. |
| Point budget | `pointCloudPointsByObject` | u32 | 250,000 | 0 to implementation cap | Display | `D_VIEWPORT` | `[FP-DOC]`, 0 may restore distance mode in Forest. |
| Point local density | `pointCloudLocalDensity` | float | 1 | 0 to 10 | Display | `D_VIEWPORT` | Per-object multiplier. |
| Point global density | `pointCloudGlobalDensity` | float | 1 | 0 to 10 | Display | `D_VIEWPORT` | Global user preference. |
| Point color | `pointCloudColorMode` | enum | Tint | Item ID, diffuse, tint | Display | `D_VIEWPORT` | `[FP-DOC]`. |
| Fake Shade | `pointCloudShade` | float | 0.5 | 0 to 1 | Display | `D_VIEWPORT` | Approximate lighting only. |
| Use Color ID | `useColorId` | bool | false | On or off | Display | `D_VIEWPORT` | Overrides normal item color for viewport. |
| Max Items | `viewportMaxItems` | u32 | 5,000 | 0 to implementation cap | Display | `D_VIEWPORT` | Tutorial value `[FP-OBS]`; current official default unknown. |
| Manual Update | `manualUpdate` | bool | false | On or off | Display | `D_VIEWPORT` | Requires Update action when on. |
| Disable Object | `disableObject` | bool | false | On or off | Display | `D_VIEWPORT` | Hides viewport and render outputs. |
| Freeze All | `freezeAll` | bool | false | On or off | Display | `D_VIEWPORT` | Global Max-layer operation, not per-population data. |
| Point selection density | `selectedPointDensity` | float | 3 | 0 to 10 | Display | `D_VIEWPORT` | `[FP-DOC]` 300%. |
| Point unselected density | `unselectedPointDensity` | float | 1 | 0 to 10 | Display | `D_VIEWPORT` | `[FP-DOC]` 100%. |
| Hit-test point cap | `pointHitTestMax` | u32 | 1,000 | 1 to implementation cap | Display | `D_VIEWPORT` | `[FP-DOC]`. |
| Point size | `pointSize` | enum | Small | Small, large | Display | `D_VIEWPORT` | Global or per-object capability varies by Forest release. |
| Debug overlays | `debugOverlays` | bit mask | none | Areas, falloff, collision, tiles, normals, frustum | Display | `D_VIEWPORT` | Never included in render output. |

The viewport Max Items value is a density factor, not a promise that exactly that many visible objects will be drawn. Forest documentation and forum material describe approximate behavior and camera interactions. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display), [FP-OBS: Forest Max Items discussion](https://forum.itoosoft.com/forest-pro-(*)/forestpack-display-count-doesn-t-work-with-limit-to-visibility-enabled/)

## 3. Data structures

### 3.1 Camera snapshot

The Max adapter captures a camera on the main thread. The core receives only this immutable value object:

```cpp
struct CameraSnapshot {
    u64 cameraIdentity = 0;
    u64 transformVersion = 0;
    Mat4d worldToView;
    Mat4d viewToWorld;
    Mat4d projection;
    Vec3d position;
    Vec3d forward;
    Vec3d up;
    double nearClip = 0.1;
    double farClip = 0.0;
    double horizontalFov = 0.0;
    double verticalFov = 0.0;
    u32 viewportWidth = 0;
    u32 viewportHeight = 0;
    bool orthographic = false;
    double orthoWidth = 0.0;
    double environmentRange = 0.0;
};
```

A camera snapshot is part of a `ViewKey`, not part of the canonical `Population` version. The key includes camera identity and transform version, projection version, viewport dimensions, and all V parameters. A viewport camera that moves every frame therefore invalidates only its view result and display visibility mask.

`SceneSnapshot` should carry both `lastUsedCamera` and an optional explicit camera snapshot. If no camera exists, V uses a conservative all-visible mask unless `Limit to Visibility` is enabled, in which case it reports a diagnostic and does not silently cull everything.

### 3.2 View key and ViewMask extension

```cpp
struct ViewKey {
    u64 populationVersion;
    u64 cameraIdentity;
    u64 cameraTransformVersion;
    u64 projectionVersion;
    u64 parameterHash;
    u32 viewportWidth, viewportHeight;
    EvalMode mode;
};

struct ViewMaskExtension {
    ViewKey key;
    u64 viewMaskVersion;
    std::vector<u8> visible;
    std::vector<u8> lod;
    std::vector<float> camDensity;
    std::vector<float> camScale;
    std::vector<u32> visibleIndices;
    std::shared_ptr<const DerivedTransformBuffer> facingTransforms;
};
```

This extends architecture's `ViewMask`. The `populationVersion` check remains mandatory. A `ViewMask` from a previous population must be rejected even if the candidate count happens to match. `viewMaskVersion` is a monotonically increasing per-object publication counter, while `populationVersion` identifies the data it masks. A wraparound is handled as an unsigned serial comparison with a full reset on persisted version mismatch.

### 3.3 Display cache records

```cpp
struct DisplayItem {
    StableKey key;
    Vec3f position;
    Quatf rotation;
    Vec3f scale;
    u16 geomId;
    u32 tintRGBA8;
    u32 colorId;
    Sphere bounds;
    u32 flags;
};

struct PointCloudCacheKey {
    u64 populationVersion;
    u64 sourceGeometryVersion;
    u64 viewMaskVersion;
    u32 budget;
    u32 colorMode;
    u32 densityRevision;
    bool fakeShade;
};

struct PointCloudBuffer {
    PointCloudCacheKey key;
    std::shared_ptr<const GpuVertexBuffer> vertices;
    std::shared_ptr<const GpuIndexBuffer> indices;
    Aabb bounds;
    u32 pointCount;
};
```

The CPU display array is compact and has no source topology. Mesh and proxy display can use `InstanceDisplayGeometry`; point clouds use custom RenderItems and vertex buffers. A cache record is immutable after publication, so Nitrous can safely retain it while a newer buffer is prepared.

## 4. Camera capture and selection

### 4.1 Snapshot timing

On `RenderBegin`, L3 captures the render camera and environment range at the render time. On a viewport draw, L3 captures the viewport camera and dimensions on the main thread. It copies projection and world transforms, clipping, orthographic state, and any target pivot needed for distance origin. Workers never query the Max viewport or camera.

For an explicit camera parameter, the referenced node's world transform and camera settings are captured. For Auto Last Used, the adapter records the last render camera or viewport camera according to the Max event that triggered evaluation. When the view is perspective or orthographic without a camera, the previous last-used camera is retained in the authored runtime state, not serialized as scene truth unless the user explicitly chooses one.

### 4.2 Auto last-used versus explicit pick

Forest's current camera documentation says Forest Pack 7 onward automatically uses the last camera view from viewport or render, and switching to perspective or orthographic leaves the last camera retained. [FP-DOC: Forest Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera)

Cyrus offers both modes. `Auto Last Used` matches the documented behavior. `Explicit Node` is a [DESIGN] extension and a practical pipeline requirement for predictable batch render. If both an explicit node and auto mode are available in a Forest compatibility profile, selecting the profile decides which UI is shown. [OPEN] Check a Forest Lite scene to see whether a manual camera node is exposed in the installed version or whether all camera references are implicit.

`Copy Parameters` is a Max-layer action. It copies the camera rollout values, not the camera node or the captured matrix, to selected Cyrus objects. The action must be undoable and should avoid copying an explicit node unless the user opts into it. Forest documents Copy Parameters. [FP-DOC: Forest Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera)

## Algorithms

The following algorithms operate on an immutable PublishedPopulation and camera snapshot. They produce a versioned ViewMask or display cache and never mutate canonical population fields.

## 5. View pass algorithms

### 5.1 Frustum culling

V first selects the camera, computes an expanded frustum, then tests each item's conservative world-space bounding sphere or oriented bounds. Expand is applied to the frustum planes by a distance proportional to the plane's scale and the configured percentage. To avoid popping, include the margin in both the left/right/top/bottom planes and in the near or far decision where appropriate. Back Offset extends the accepted region behind the camera along the camera backward direction. Far Clipping Plane limits accepted distance from the camera or target origin.

```cpp
bool visible(const CameraSnapshot& c, const ViewParams& p,
             const Sphere& s) {
    Frustum f = makeFrustum(c, p.frustumExpand);
    if (!f.intersects(s)) return false;
    Vec3d origin = distanceOrigin(c, p);
    double depth = dot(Vec3d(s.center) - origin, c.forward);
    if (depth < -p.backOffset - s.radius) return false;
    double farLimit = effectiveFar(c, p);
    if (farLimit > 0 && distance(Vec3d(s.center), origin) - s.radius > farLimit)
        return false;
    return true;
}
```

Test the sphere against expanded planes, not item pivots, so large objects are retained when their geometry intersects the view. Forest describes Expand as widening visibility to reduce edge popping, Far Clipping Plane as a scene-unit distance, and Back Offset as creating items behind the camera. [FP-DOC: Forest Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera)

If `Limit to Visibility` is off in render, V still computes LOD and optional camera falloff when those controls are enabled, but `visible` remains true except for explicit render limits in 09. If `Enable on Viewport` is off, viewport frustum culling is not applied. This separation prevents an orbit from rebuilding a point cloud unnecessarily.

### 5.2 Camera-distance density and scale falloff

Distance origin is the camera position by default. If `Use Look-At Target` is on and a valid target exists, use the target pivot as the distance origin. If `Use Environment Range` is on, use the captured environment range as the falloff range. Otherwise use explicit `cameraFalloffRange`, far clip, or the population bounds diagonal as a conservative fallback.

For item distance `d`, normalized distance is `x = saturate(d / range)`. Evaluate the density curve `D(x)` and scale curve `S(x)`. Density does not erase canonical candidates. It sets `camDensity[i]`, then uses a stable hash to add or remove distant items:

```cpp
float q = saturate(camDensityCurve(distance01));
float u = stableUnit(pop.key[i], RandomPurpose::CameraDensity, viewSeed);
visibleByDensity = u <= q;
```

The view seed includes camera distance parameters and `populationVersion`, but not a continuously changing random sequence. As the camera moves, an item can cross the threshold and be removed or re-added deterministically. Nearby items remain stable; moving the camera does not reshuffle the survivors. The assignment requires that camera moves only add or remove far items. Use hysteresis around the threshold to reduce one-frame flicker: retain the previous state when `u` is within `epsilon` of `q`, provided the previous mask belongs to the same population and compatible camera mode.

Scale falloff is a derived per-view multiplier. Store `camScale[i] = Vec3f{S,S,S}` or `(1,1,S)` when a height-only view policy is selected. It does not overwrite `Population.scale`; the render and viewport adapters multiply it when building a view transform. This keeps render population caches reusable and lets the camera move without invalidating S7.

[OPEN] Forest's camera density falloff may use a deterministic hash or may regenerate samples. Cyrus chooses stable hashing to satisfy the architecture's deterministic camera rule. Compare density thresholds in a Forest Lite scene before claiming exact parity.

### 5.3 LOD

Each source or Forest LOD item declares a mode and thresholds. In distance mode, compare distance from the configured origin to the maximum distance. In minimum screen-size mode, project the source bounding-box diagonal and compare its pixels or normalized screen diagonal to the minimum. Variation shifts each item's threshold using `LODVariation` and a stable key draw:

```cpp
float variation = (stableUnit(key, RandomPurpose::LODVariation, lodSeed) * 2.0f - 1.0f)
                  * lodVariation;
float threshold = baseThreshold * (1.0f + variation);
```

The sign and multiplicative form are [DESIGN]. Avoid a threshold of zero and clamp to a valid range. `Override Max Distance` of zero means use the ForestLOD source setting; a positive value overrides it, matching the documented Forest behavior. [FP-DOC: Forest LOD](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod)

If `lodUpdateOnViewport` is false, retain the last published LOD selection in the display cache until render, but still compute render LOD. If a source has no LOD, set `lod=0`. If a LOD asset is missing, use the highest quality available and report a warning.

Minimum screen-size mode must account for orthographic cameras, where projected size is independent of depth. Perspective projection uses the camera focal scale and depth, with a lower depth clamp to avoid division by zero. Frustum culling occurs before expensive screen-size projection, but the bounds used by LOD must be source-specific and scaled by the view scale.

## 6. ViewMask lifecycle and versioning

The lifecycle is:

1. S12 publishes an immutable `PublishedPopulation` with a new `populationVersion`.
2. Any existing ViewMask whose population version differs is invalid immediately.
3. A view request constructs a `ViewKey` from the population, camera snapshot, viewport dimensions, display settings, and view parameters.
4. V reads the population and computes a private mask in chunks.
5. The main thread or display adapter publishes the completed mask atomically with `viewMaskVersion`.
6. Nitrous consumes only the latest compatible mask. Stale async results are discarded by `(populationVersion, ViewKey)` comparison.
7. On object deletion or scene close, display consumers release the mask and GPU resources through reference-counted handles.

Keep current and previous masks while a draw is in progress. If a new population arrives, display the previous compatible population until the new mask is ready, or draw a lightweight bounding box if the user selected Manual Update. Never combine a mask from one population with a buffer from another.

ViewMask serialization is not authored truth and is not saved in the .max file. The `populationVersion` and algorithm version are diagnostics only. A plugin restart rebuilds masks.

## 7. Viewport display modes

### 7.1 Mesh

Mesh mode displays original geometry through GPU instancing rather than making one Max node or mesh per item. Group source meshes by `geomId`, material table, and LOD. Build an `InstanceDisplayGeometry` for each compatible source representation and publish transforms in chunks. Mesh mode is highest fidelity and should be disabled automatically when the source is unsupported by the viewport or exceeds the configured face budget.

The source display transform includes canonical rotation, scale, mirror, camera scale falloff, and any view-derived Facing Camera matrix. It does not alter the `Population`.

### 7.2 Proxy shapes

Proxy mode renders a low-cost shape per item. Supported shapes are Plane(s), Pyramid, Box, Thin Box, Plant, and Arrow. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display)

Define each proxy in object-local coordinates with a conservative bound. Plane(s) use the source width and height and can be camera-facing; Pyramid uses a tapered vertical shape; Box and Thin Box use source bounds; Plant uses a cross or low-poly silhouette; Arrow is useful for normals and debug orientation. The shape choice is authored, while the transform and tint remain per item.

Proxies should be grouped by shape, color mode, and selection state. Do not generate unique vertex buffers per item. Use a shared geometry buffer and an instance buffer. If a proxy is too small on screen, V can emit a point instead of a proxy under the Adaptive policy.

### 7.3 Adaptive

Adaptive mode chooses Mesh, Proxy, or Point Cloud based on source face count, projected screen size, and population count. First apply the face threshold. Then apply a screen-size threshold to avoid drawing expensive tiny meshes. Thresholds have hysteresis so a small camera move does not alternate every frame:

```cpp
if (previous == Mesh && projectedPixels < lowThreshold) useProxy;
else if (previous == Proxy && projectedPixels > highThreshold) useMesh;
```

The face threshold UI means the source's face count, not the scattered item count. The exact Forest threshold default is not public, so Cyrus's 10,000 starting value is [DESIGN].

### 7.4 Point Cloud

Point Cloud displays precomputed surface sample points from each source mesh. It is not one point per scattered item unless the source itself has one sample per item. Build a deterministic point set for each source mesh, transform those points per item, and choose at most `pointCloudPointsByObject` points per Cyrus object after density controls. Forest documents a default of 250,000 points per object, colors by item ID or diffuse color, fake Shade, and GPU caching. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display)

Point samples are created in source local space from triangle area weighted sampling. The point seed includes source geometry identity and version. For each item, map selected source points to the item transform. To avoid an O(items times source points) explosion, distribute a fixed point budget across surviving items proportionally to item weights, then sample item and source point indices with stable hashes. For a dense population, a reservoir algorithm over item and source point candidates gives an exact cap without materializing all points.

Color modes:

* Item ID: hash `geomId` or stable item identity to a deterministic color palette.
* Diffuse: use source material diffuse color for the selected source point or element.
* Tint: use `tintRGBA8` and apply any point-cloud color correction.
* Use Color ID: if enabled, override with the geometry entry's Color ID.

Fake Shade derives a normal-like brightness from source point normals and a fixed view-independent light direction. It is intentionally not a renderer preview. The color and shade computation happens when the point buffer is built, not in every draw call.

Local density multiplies the object's share of the global budget. Global density applies after all local factors. Selected and unselected density multipliers are 3.0 and 1.0 by default, matching the documented Forest tuning. Hit testing uses an independently capped subset of 1,000 points by default. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display)

## 8. Point-cloud cache and invalidation

Forest documents GPU point-cloud data as cached and updated when the Forest object changes. Cyrus matches that baseline: camera-only changes do not rebuild an all-points buffer. A setting that changes point positions or colors necessarily invalidates the corresponding cache. A camera move alone must not rebuild the point vertices if camera clipping is off. The point buffer cache key includes:

```text
populationVersion, sourceGeometryVersion, point budget,
local/global density, display color mode, tint revision,
fake shade, selected state, algorithmVersion
```

The view mask is deliberately not in the key for an unculled point cloud. For a visible-only point cloud, the view mask is included and camera motion may trigger a rebuild. This is the Forest trap: camera viewport culling can force point-cloud rebuilds and erase the cache's performance advantage. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display)

Use two strategies:

1. Cached-all-points: keep one GPU point buffer and apply a per-view visibility mask or shader discard where supported.
2. Visible-only points: rebuild a compact buffer when V visibility changes, only when the user explicitly enables viewport camera clipping.

Prefer strategy 1 for interactive orbiting. If Nitrous cannot efficiently discard points, use coarse chunks and retain the chunks' bounds, so only changed chunks are rebuilt.

## 9. Viewport Max Items, manual update, disable, and freeze

Forest's viewport Max Items is an approximate display count that adjusts density instead of necessarily counting exactly, and zero removes the limit at the risk of excessive geometry. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display)

Cyrus implements `viewportMaxItems` as a density multiplier before point and instance selection. Estimate the unthinned survivor count `N`. Set `k = min(1, maxItems / max(N,1))`. Use a stable per-item `CameraBudget` purpose to retain items with `u <= k`. Raising Max Items therefore adds items and never reshuffles existing survivors. This is consistent with the architecture's S5 stable-thinning rule.

Because the visible count depends on source representation, report both `estimatedCandidates`, `estimatedDisplayedItems`, and `actualDisplayPrimitives`. A user who asks for 5,000 may see fewer points or more triangles, and the stats panel must make the distinction clear.

Manual Update coalesces parameter changes without starting a view rebuild. The Update button takes a snapshot of all pending changes and publishes an evaluation generation. Disable Object returns no display items and releases optional GPU buffers after a grace period. Freeze All is a Max-layer global state that keeps existing display buffers and suppresses updates for all Cyrus objects except render preparation. It must not set each object's authored `disableObject` flag.

## 10. Nitrous integration

### 10.1 Verified API surface

The intended Max adapter is `IObjectDisplay2`. Implement or expose it through the object's `GetInterface` path according to the installed SDK. Use:

* `PrepareDisplay` for shared source geometry, material and render-item preparation;
* `UpdatePerNodeItems` for node-specific instance data;
* `UpdatePerViewItems` for camera-dependent masks and derived transforms.

Autodesk documents these methods and explicitly describes per-view updates. [FP-DOC: Autodesk IObjectDisplay2](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html)

For proxy and mesh instances, use the verified namespace and class `MaxSDK::Graphics::ViewportInstancing::InstanceDisplayGeometry`. Its documented helpers include instance data creation and generation of instance render items. Use the installed header to verify overloads such as `GenerateInstanceData` and `GenerateInstanceRenderItem`; do not copy signatures from another Max release. [FP-DOC: Autodesk InstanceDisplayGeometry](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_display_geometry.html)

For point clouds, use a custom Nitrous `RenderItem` with vertex and optional index buffers, or an instanced point primitive if the target SDK supports it. Autodesk's RenderItem documentation confirms custom RenderItems are part of the plug-in display architecture. [FP-DOC: Autodesk RenderItem](https://help.autodesk.com/cloudhelp/2023/ENU/Max-Developer-Help/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/about_renderitem.html)

Do not rely on GraphicsWindow legacy immediate drawing for populated forests. It creates CPU draw overhead and blocks the path to cached GPU buffers. [FP-DOC: Forest rendering best practice](https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice)

### 10.2 Prepare, publish, and update

`PrepareDisplay` obtains or references source geometry buffers and material resources. It may run on a Nitrous-managed thread, so use immutable caches and no Max scene calls. `UpdatePerNodeItems` publishes the latest population and display settings for the Cyrus node. `UpdatePerViewItems` applies the compatible `ViewMask`, selects or generates per-view derived transforms, and appends render items to the provided container.

Never block the UI waiting for a full 10M-item rebuild. A background job builds CPU masks, display records, and chunked GPU upload payloads. The main thread hands completed resource handles to Nitrous at a safe synchronization point. If a draw arrives before a new result, use the previous published result or a placeholder. Stale results are discarded by evaluation generation and population version.

### 10.3 Chunked buffers and partial updates

Partition instance records into stable chunks, for example 16,384 items, ordered by tile and then StableKey. Each chunk owns a transform buffer range, bounds, and cache key. A change to a camera mask or selected state can update only changed chunks. A source or transform change invalidates affected chunks, or all chunks in v1 if locality is not yet implemented.

Use double-buffered or reference-counted GPU buffers. Upload complete immutable chunks, then atomically swap a display set. Never mutate a buffer that Nitrous may be drawing. For large populations, queue uploads with a byte budget per frame so the UI stays responsive. The first frame can display proxies or a point cloud while high-fidelity mesh chunks upload.

### 10.4 Selection and hit testing

Viewport selection has two levels: selecting the Cyrus node and sub-object editing of an individual instance. A CPU spatial index maps instance bounds to StableKeys. Build a BVH or uniform grid over displayed item bounds; retain only entries for visible or selectable items. For point cloud, use at most 1,000 hit-test points by default, as Forest documents, and test the nearest point against a screen-space tolerance. [FP-DOC: Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display)

The GPU buffer may contain point or proxy indices, but the hit result must resolve to a stable key. Selection density can be 300% for selected items and 100% for unselected items, but selection should not change the canonical population. When entering Custom Edit, increase hit-test detail on demand and build the spatial index asynchronously. If a selected item has been thinned by Max Items, temporarily include it in the display set without changing other stable budget decisions.

For sub-object transforms, S10 writes an `OverrideRecord` keyed by StableKey. Do not store a transient array position as the editable identity. If a source has nested elements, retain an optional element id for element-level material or selection, but the instance identity remains the population key.

## 11. Async evaluation and nested Cyrus objects

A Cyrus object can consume another Cyrus object's PublishedPopulation. View preparation must resolve the dependency version before building display chunks. If the upstream object publishes while a downstream view job is running, the downstream job is cancelled or marked stale, and its result is not published.

Nested objects are a known lag trap. Avoid recursive synchronous display generation on the UI thread. A downstream object should use the latest published upstream population for viewport display, schedule a refresh, and render synchronously only when the render contract requires it. Detect cycles at assignment time as specified in 00.

Async jobs check `evalGeneration` per chunk. Publish only if the generation, population version, parameter hash, and view key still match. A cancelled job releases temporary CPU arrays and uncommitted GPU resources. The previous display result remains valid until replaced.

## 12. Debug overlays

Implement overlays as separate low-count RenderItems or line buffers, never by injecting debug geometry into the population. Supported overlays include:

* area masks: include and exclude boundaries, with translucent fill;
* falloff heatmaps: sample density and scale factors in FL tiles;
* collision spheres: draw S9 spheres, with rejected candidates in red;
* tile grid: show worker tiles and dirty tile halos;
* surface normals: short arrows at sampled positions;
* frustum and far clip: draw expanded camera frustum and back offset plane;
* LOD bands: draw distance rings or screen-size annotations;
* point-cloud cache chunks: bounds and dirty state.

Overlay colors and labels must be deterministic and should include object name, population version, and view mask version. Disable overlays for render output. Because overlays depend on intermediate stages, request the relevant checkpoint through the diagnostic service rather than recomputing candidates in the display adapter.

## 13. Performance targets and known traps

[DESIGN] Target a 16-core desktop with a 1M-item view mask in under 20 ms when bounds are resident, and a 250,000-point GPU buffer rebuild in under 80 ms after CPU sampling. Aim for under 4 ms main-thread work per viewport update, excluding driver submission. For 10M render candidates, V should stream mask chunks and avoid a full duplicate `DisplayItem` array where possible.

Memory targets:

* `ViewMask.visible` and LOD arrays: about 2 bytes per item, excluding optional floats;
* point cloud CPU staging: under 24 bytes per point before upload;
* GPU point position and color: 16 bytes per point in the common packed path;
* instance transforms: 48 to 64 bytes per item depending on quaternion packing;
* chunk metadata: below 1 KB per 16,384-item chunk.

Known traps:

1. Camera viewport culling can force point-cloud rebuilds on every orbit. Keep all-points buffers and apply masks where possible.
2. Nested Cyrus objects can synchronously cascade evaluations. Use published upstream versions and async refresh.
3. GraphicsWindow legacy drawing becomes unusable at high item counts. Use Nitrous RenderItems and instance display geometry.
4. Allocating one RenderItem or node per item destroys CPU and GPU performance. Batch by source and shape.
5. Rebuilding all point vertices when only tint changes wastes the cache. Separate position and color buffers where SDK support permits.
6. Uploading one giant buffer can stall the driver. Use chunks and a per-frame upload budget.
7. Recomputing bounds from source meshes in V is too expensive. S0 or S6 must provide conservative bounds.
8. Applying camera density by compacting the canonical population changes indices and invalidates editing. Keep the mask sparse and resolve StableKeys.
9. Letting selection density alter StableRNG seeds makes selecting an item reshuffle the view. Selection is only a display multiplier.
10. Calling Max APIs from workers can deadlock or corrupt the scene. Capture every required value in S0.

## 14. 3ds Max integration details

The Max object should expose `IObjectDisplay2` through its display interface. The exact registration mechanism and `GetInterface` constants must be verified in the target Max SDK because the public documentation names the interface but does not provide a universal plug-in template. [OPEN]

A Qt rollout provides camera controls, display mode, proxy shape, point settings, viewport budget, update controls, and debug toggles. Camera node pickers create or clear a reference slot. Auto Last Used does not create a persistent node reference. Enable on Viewport must show a warning or tooltip explaining that camera movement may force visibility and point-cloud rebuilds.

Notifications:

* camera transform or viewport change: invalidate V and `UpdatePerViewItems` only;
* frustum settings: invalidate V and any visible-only point cache;
* source geometry change: invalidate source display cache and population version through S0;
* tint change: invalidate color buffers and material payload, not point positions;
* point budget or display mode: invalidate display buffers, not population;
* Manual Update: defer all display invalidation until Update action;
* Disable Object and Freeze All: switch display state without deleting authored parameters.

The adapter must register a redraw or display invalidation on the main thread after an async result is published. It must not force a synchronous full evaluation from a viewport paint callback.

## 15. Edge cases and failure modes

* No camera with Limit to Visibility enabled: retain all items and show a diagnostic rather than culling all.
* Camera far clip less than near clip: use the camera's valid far clip and report a parameter error.
* Far Clipping Plane of zero: disabled, not zero-distance culling.
* Negative Expand or Back Offset: clamp to zero and warn.
* Orthographic camera: use orthographic projection for frustum and screen-size LOD; do not divide by depth.
* Camera inside an item bound: sphere intersection keeps the item visible.
* Look-At target missing: use camera origin and report fallback.
* Environment range unavailable: use explicit range, far clip, or population bounds.
* Population has zero items: publish an empty mask and release display buffers.
* Item has invalid bounds: use a small conservative sphere at its position, never NaN bounds.
* Point budget larger than available points: draw all available points without duplication unless source policy explicitly permits replacement.
* Selected item is outside the current mask: include it in a temporary selection overlay, not in the canonical mask.
* A stale async result arrives after object deletion: discard using a lifetime token before touching Nitrous resources.
* GPU device reset: rebuild display buffers from immutable CPU cache without regenerating the population.
* Source material has no diffuse color: use neutral gray for diffuse point mode.
* Use Color ID with no item Color ID: use a deterministic fallback from `geomId`.
* LOD source missing at one distance: clamp to the nearest available LOD.
* Point cloud with camera clipping on: warn in stats that camera motion invalidates visible-only buffers.

## 16. Tests and Forest Lite comparison scenes

### 16.1 Core tests

1. Frustum sphere tests for perspective, orthographic, near plane, far plane, Expand, and Back Offset.
2. Camera selection tests for auto last-used persistence, explicit node, and no-camera fallback.
3. ViewMask rejection when `populationVersion` differs despite equal count.
4. Stable camera density: move camera slightly and verify only threshold-crossing far items change.
5. Target-origin distance tests with camera and Look-At target separated.
6. Distance and screen-size LOD tests, including orthographic projection and variation.
7. Max Items monotonicity: increasing budget adds or retains items, never moves existing items.
8. Point budget exact cap, selected and unselected densities, and hit-test cap.
9. Point cloud cache key tests proving camera moves do not invalidate all-points cache.
10. Material, tint, diffuse, item ID, and Color ID point colors.
11. ViewMask and GPU buffer publication race tests with stale generations.
12. Chunk partial update tests for selection and camera mask changes.
13. Spatial index hit testing resolves StableKeys after compaction.
14. Nested published population version changes invalidate downstream views without UI blocking.

### 16.2 Golden scenes

* A large flat area and a perspective camera at three distances, comparing Expand, Back Offset, and Far Clip.
* A moving camera with density and scale falloff, verifying far-item add or remove behavior without nearby reshuffle.
* A Look-At target offset from the camera, comparing target-origin and camera-origin LOD.
* ForestLOD with distance and screen-size modes, threshold variation, and viewport update off.
* One high-face source rendered in Mesh, each proxy shape, Adaptive, and Point Cloud.
* A 1M-item point cloud with camera culling disabled, then enabled, measuring rebuild count.
* Nested Cyrus objects with upstream population changes during a downstream viewport job.
* Manual Update and Freeze All while edits accumulate.
* Sub-object selection in a point cloud with selected density 300% and hit-test cap 1,000.

Record mask hashes, displayed StableKeys, LOD index arrays, point buffer cache keys, upload timings, and main-thread time. Compare Forest behavior by screenshots, item counts, rebuild observations, and camera movement, not by assuming Forest's private cache implementation.

## 17. Open questions

1. [OPEN] Does the installed Forest version expose an explicit camera picker, or is Auto Last Used the only documented behavior?
2. [OPEN] Is Expand interpreted as a percentage of frustum dimensions, world distance, or a renderer-specific margin?
3. [OPEN] Does Forest camera density use stable hashes, regenerate samples, or apply a deterministic spatial reduction?
4. [OPEN] Does camera scale falloff affect canonical transforms before render, or only derived view transforms?
5. [OPEN] How exactly does Forest compute Minimum Screen Size, especially for orthographic cameras and nonuniform scale?
6. [OPEN] What are the version-specific defaults and ranges for Adaptive face threshold, point local density, and point size?
7. [OPEN] Is the tutorial's viewport Max Items default of 5,000 universal, version-specific, or scene-preset-specific? The official current page does not publish it.
8. [OPEN] Can the target Max SDK update point cloud RenderItem vertex buffers in place, or must Cyrus swap complete resources?
9. [OPEN] Which `IObjectDisplay2` registration and RenderItem buffer ownership calls are stable across supported Max releases? Verify in installed headers.
10. [OPEN] Does Forest retain all point-cloud vertices and mask them, or rebuild visible-only points when camera culling is enabled?
11. [OPEN] What exact nested-object invalidation and display behavior does Forest expose?

## 18. Architecture feedback

The architecture's separation of canonical population and V is essential and should remain fixed. Extend `ViewMask` with a `ViewKey`, `viewMaskVersion`, optional `camScale`, and an optional derived-facing-transform buffer. Add a display cache registry alongside `SharedCacheRegistry`, with explicit CPU and GPU byte accounting and chunk-level ownership. Keep camera-derived density and scale out of `Population.scaleFactor`; that field is generated by S4 and must remain reusable across views.

The 00 memory note says V owns view-dependent masks but does not specify whether point positions are cached. Add a documented rule: point positions are cached by population and source version, while camera masks are separate unless the user explicitly enables visible-only point-cloud mode. This avoids the cache trap documented by Forest and keeps camera orbit responsive.

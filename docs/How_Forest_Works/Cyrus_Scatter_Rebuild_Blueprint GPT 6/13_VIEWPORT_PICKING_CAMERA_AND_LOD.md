# 13 — Viewport, picking, camera policies, and LOD

**Status: proposed Cyrus design. Research basis: R0 §5. Official anchors: S10–S12, S24.**

## 1. The viewport is a consumer

The authoritative population can contain millions of instances while the viewport displays a bounded representation. A viewport limit is not a final population limit. ForestPack exposes distinct display representations and budgets [S10]; Cyrus should make the distinction visible rather than infer population from the image.

Use immutable `PopulationSnapshot` input and separate `DisplaySnapshot` output. Selection translates display addresses back to canonical IDs. Display invalidation cannot erase authoring data.

## 2. Representations

| Representation | Data needed | Appropriate use |
|---|---|---|
| Points | Position, optional tint/size | Coverage and broad composition |
| Arrows | Position and orientation | Path alignment and transform debugging |
| Bounds/proxies | Transform and source proxy | Large objects and spacing |
| Sampled source point cloud | Reusable source sample points + instance transforms | Plant silhouette at controlled cost |
| Instanced mesh | Source geometry + transform stream | Detailed local inspection |
| Field overlay | Canonical region/field data | Paint and mask debugging independent of plants |

Point-cloud sampling should be stable per source element/sample rank. Do not resample a plant's point cloud whenever the camera rotates.

## 3. Retained resources

Cache reusable source geometry and point samples. Upload instance attributes only when the relevant population/display stream changes. A camera orbit normally changes per-view visibility, not source geometry or candidate generation.

Autodesk's `IObjectDisplay2` separates shared preparation, per-node items, and optional per-view updates [S24]. Use these as host integration boundaries; exact buffer APIs and resource ownership must be compiled and tested against each supported Max SDK.

Do not assume a particular GPU-instancing route exists merely because the core stores transforms efficiently. Build a host display spike and measure draw-call, upload, and lifetime behavior before committing to it.

## 4. Stable preview budgets

Use a stable per-instance preview key. A percentage threshold produces nested subsets. A fixed item budget can select the lowest keys; increasing the budget adds items rather than reshuffling all of them.

A point budget is different from an instance budget. Allocate sample points per visible source/instance according to a documented policy, with a minimum representation for large objects. A million grass patches cannot each receive hundreds of points under a 250,000-point budget.

Selected and edited instances can receive a temporary priority boost without changing the underlying population. Report that preview counts include selection exceptions where applicable.

## 5. GPU lifetime and publication

Build new buffers without modifying ones currently in use. Publish a coherent display snapshot. Retire old buffers after the graphics API confirms they are no longer referenced; CPU job completion alone is not enough.

Handle device loss, viewport recreation, scene reset, plugin unload, hidden objects, multiple views, and multiple nodes referencing one object. The plugin can reconstruct display resources from the population snapshot.

Bounds must update when source dimensions, animation samples, or transforms change. Incorrect stale bounds can make correct instances disappear because the host culls the entire scatter object.

## 6. Picking

For large populations, use a CPU acceleration structure over final instance proxies or a qualified GPU ID-buffer route. GPU IDs are snapshot-local handles; translate them to canonical IDs using the same displayed revision.

Provide exact selected-source mesh picking as an optional narrow phase. A point-cloud-only pick is not necessarily geometrically exact. Expose “pick displayed subset” versus “pick all accepted instances.”

A stale pick result is rejected or revalidated against the current population. Never apply an edit to whichever object now occupies the same array index.

## 7. Three camera features, three semantics

**View culling:** removes representations from a particular viewport or output visibility set.

**Distance density:** changes candidate eligibility and may change collision winners.

**LOD:** preserves logical instance identity but chooses another source representation.

ForestPack provides camera-related population and representation controls [S11–S12]. Cyrus stores those as separate dependency paths.

## 8. Render culling safety

Default final rendering retains instances needed by the renderer, even when outside the primary camera frame. Off-camera objects can affect shadows, reflections, refractions, and indirect lighting. A primary-frustum-only optimization is explicitly approximate.

Expose `Approximate camera cull`, expansion, backward offset, far range, and shot envelope as opt-in policies. A sampled union of camera frusta is not mathematically guaranteed to include every position during continuous motion unless a conservative motion bound is used. It also does not solve all secondary-ray visibility.

A renderer-specific ray-visibility adapter can do more only after its contract is tested. Do not copy a viewport frustum mask directly into final renderer existence.

## 9. LOD source sets

A source's LOD set contains ordered representation providers, thresholds, material alternatives, and a bounding policy. It does not automatically simplify meshes. Each level has a compatible anchor/pivot convention.

Distance thresholds use world units. Screen-size thresholds use projected bounds and camera projection type. Perspective and orthographic cameras need different calculations. Include source scale and animation bounds.

Default LOD is deterministic and stateless for offline frame reproducibility. Per-instance threshold variation can reduce simultaneous switching without depending on playback history. Stateful hysteresis can be offered for interactive preview, but final render should use a saved deterministic policy or a precomputed shot assignment.

Cross-fading requires renderer/material support and can double representation cost during transitions. Do not promise it from a threshold slider alone.

## 10. Interaction targets

Target ordinary camera navigation without generation work for a static camera-independent layer. Target bounded display upload after local changes. Target stable selections across publications. Actual frame rate depends on source complexity, point budget, GPU, and host scene; measure rather than claiming universal smoothness.

Use diagnostics to distinguish CPU generation, main-thread resource creation, GPU transfer, and draw time. A source-point sampling bottleneck cannot be fixed by only reducing collision checks.

## 11. Tests

Static camera orbit must leave authoritative IDs/transforms unchanged. Raising preview percentage must preserve the old subset. Changing source mesh should invalidate its representation without reseeding placements. Test selected overrides, multiple viewports, orthographic cameras, device/resource reset, changing LOD materials, and off-camera shadow/reflection fixtures.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S10]: https://docs.itoosoft.com/forestpack/forest-plugin/display
[S11]: https://docs.itoosoft.com/forestpack/forest-plugin/camera
[S12]: https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod
[S24]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html

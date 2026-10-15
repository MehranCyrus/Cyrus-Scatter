# 02 Plugin Shell and Inputs

## 1. Purpose and scope

This specification defines the Max-facing shell for Cyrus Scatter and the immutable input snapshot that feeds the core pipeline. It covers stages S0 through the publication boundary, with emphasis on object lifetime, ParamBlock2 persistence, reference notifications, geometry sources, UI, libraries, and creation workflows. The core engine remains pure C++20 and must not include 3ds Max headers. All Max SDK work described here belongs in `max/plugin`, `max/snapshot`, `max/ui`, `max/tools`, and `max/script` from 00 section 13.

The shell owns authored truth: parameters, stable list entry IDs, node references, paint and edit chunks, and dependency subscriptions. It does not own a mutable generated population. A generation is a request to build an immutable `SceneSnapshot` at time `t`, then run S1 through S12. The shell publishes the resulting population and schedules Nitrous or render consumers. This distinction prevents a viewport callback from changing a render result and makes save files independent of temporary caches.

The implementation target is 3ds Max 2025 and later initially, but all SDK names must be checked against the exact SDK headers used by the build. Where an interface is documented but its method signature varies by SDK version, the code should use a small adapter and a compile-time version guard rather than spreading version tests across the object.

### Architecture contract

This file extends 00 as follows:

* `SceneSnapshot` extends the immutable input concept in 00 section 2. It is a Max-free data object after S0 returns.
* `GeometryTable`, `GeometryEntrySnapshot`, `NodeSnapshot`, `CameraSnapshot`, and `MapGrid` extend the snapshot and `Population` inputs in 00 sections 4 and 7.
* `ParamId`, `DirtyBits`, and `ReferenceRole` extend the stable IDs and invalidation contract in 00 sections 5, 6, and 7.
* `S0` is main-thread-only. S1 through S12 may run on worker threads, but no Max scene access is allowed there.

## 2. Forest Pack behavior to match

The following are compatibility targets, not claims about private Forest implementation.

* **[FP-DOC]** Generate creates an object by picking a spline or surface and assigns the picked node to the corresponding input. Icon Mode creates an empty icon object for later setup. Populate from Selection can add selected source objects when the object is created. The Create panel documents these paths: [Create panel](https://docs.itoosoft.com/forestpack/forest-plugin/create).
* **[FP-DOC]** Forest evaluates XY distribution in local coordinates, then drops points along Z to a surface. UV mode uses surface UVs: [Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).
* **[FP-DOC]** The Geometry List supports custom objects, templates, billboards, groups and hierarchies, non-geometric objects, renderer proxies, disabled slots, and Forest LOD sources. Include Children and Keep Group Hierarchy affect whether children are expanded and whether transforms and culling occur per child: [Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry).
* **[FP-DOC]** Geometry entries expose names, scale, dimensions, Z offset, center displacement, collision radius, probability, Color ID, and material. Probability can be normalized or randomized. Disabled entries still consume selection probability and leave gaps: [Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry).
* **[FP-DOC]** Library entries include billboards, 3D objects and presets. A user library uses an XML index and thumbnail folders. 3D items may be XReferenced or merged: [Library Browser](https://docs.itoosoft.com/forestpack/forest-library/library-browser), [Editing a library](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library).
* **[FP-OBS]** Forest has a real-time status window, point-cloud and proxy viewport modes, and a Max Items budget. The current page documents a point-cloud cap of 250,000 points per object and says Max Items is an approximation, not an exact count: [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display), [display-count thread](https://forum.itoosoft.com/forest-pro-(*)/forestpack-display-count-doesn-t-work-with-limit-to-visibility-enabled/).
* **[FP-DOC]** Current render limits are 1,000,000 objects and 5,000,000 faces. At a limit Forest shows an F icon and a warning. Zero removes a limit, but can cause slowdowns or crashes: [Display](https://docs.itoosoft.com/forestpack/forest-plugin/display).
* **[FP-DOC]** `INode::EvalWorldState(t)` is the correct scene evaluation boundary for source nodes. A converted `TriObject` must be deleted when conversion returns a different object: [Extracting a mesh](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/modeling/meshes/extracting_the_mesh_from_a_node.html).
* **[FP-DOC]** Autodesk documents `GeomObject` as the geometric object base with `Eval`, `GetRenderMesh`, `CanConvertToType`, and `ConvertToType`: [GeomObject](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_geom_object.html). Nitrous integration is through `IObjectDisplay2` and instance rendering can use `InstanceDisplayGeometry`: [IObjectDisplay2](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html), [InstanceDisplayGeometry](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_display_geometry.html).

## 3. Object class and ClassDesc2

### 3.1 GeomObject versus SimpleObject2

Choose `GeomObject` as the direct base for `CyrusScatterObject`.

`SimpleObject2` is attractive because it supplies a common simple mesh-object implementation and may reduce boilerplate for an object whose normal display is a mesh. It is the wrong abstraction for the canonical Cyrus result. Cyrus is a parametric graph with view-dependent instance display, render-time source batches, custom interfaces, and an aggregate mesh only as a fallback. Treating the generated mesh as the object identity encourages expensive rebuilding inside `BuildMesh`, loses the distinction between authored truth and published population, and makes native instance providers awkward.

`GeomObject` is the documented geometric plug-in base and gives explicit control over `Eval`, `GetRenderMesh`, conversion, bounds, hit testing, validity, and reference behavior. We implement the standard GeomObject methods, while the normal viewport path is an `IObjectDisplay2` provider that displays instance buffers. `SimpleObject2` remains a possible internal helper for a future proxy-only object, not this class.

```cpp
class CyrusScatterObject final : public GeomObject {
public:
    static constexpr uint32_t kPluginVersion = 1;
    CyrusScatterObject();
    ~CyrusScatterObject() override;

    ObjectState Eval(TimeValue t) override;
    Mesh* GetRenderMesh(TimeValue t, INode* inode, View& view,
                        int& needDelete) override;
    int HitTest(TimeValue t, INode* inode, int type, int crossing,
                int flags, IPoint2* p, ViewExp* vpt) override;
    void GetWorldBoundBox(TimeValue t, INode* inode, ViewExp* vpt,
                          Box3& box) override;
    void GetLocalBoundBox(TimeValue t, INode* inode, ViewExp* vpt,
                          Box3& box) override;
    int Display(TimeValue t, INode* inode, ViewExp* vpt,
                int flags) override;
    RefTargetHandle Clone(RemapDir& remap) override;
    IOResult Save(ISave* isave) override;
    IOResult Load(ILoad* iload) override;
    BaseInterface* GetInterface(Interface_ID id) override;
    RefResult NotifyRefChanged(const Interval& changeInt,
                               RefTargetHandle hTarget,
                               PartID& partID,
                               RefMessage msg) override;
};
```

The exact virtual signatures must be matched to the Max SDK headers, especially `Display`, `HitTest`, and `GetRenderMesh`, because Autodesk has adjusted constness and interface aliases in different releases. The declaration above is the design surface, not a substitute for compiling against the SDK.

### 3.2 Class IDs and descriptor

Reserve a product-unique pair and never change it after shipping. The values below are placeholders and must be replaced by IDs allocated for the Cyrus plug-in; do not use them in a released binary.

```cpp
#define CYRUS_SCATTER_CLASS_ID Class_ID(0x5A31C1D2, 0x0B7E48A9)
#define CYRUS_SCATTER_SUPERCLASS_ID GEOMOBJECT_CLASS_ID
#define CYRUS_COLOR_TEXMAP_CLASS_ID Class_ID(0x5A31C1D3, 0x0B7E48A9)
#define CYRUS_EDGE_TEXMAP_CLASS_ID  Class_ID(0x5A31C1D4, 0x0B7E48A9)
```

Use a `ClassDesc2` descriptor with `Create`, `ClassName`, `SuperClassID`, `ClassID`, `Category`, `InternalName`, `HInstance`, and `IsPublic`. `Create` must construct one object with default ParamBlock2s and no scene references. The descriptor should expose a stable internal name such as `CyrusScatter`, a localized display name such as `Cyrus Scatter`, and a unique category such as `Cyrus Objects`.

Install one `ParamBlockDesc2` descriptor for each rollout. A single monolithic block would serialize, but independent blocks provide smaller invalidation units, cleaner migration, and UI lifetime isolation. Do not assume block order is stable after a plugin update. Identify blocks by an explicit `BlockId` and find them by ID during `Load` and post-load migration.

### 3.3 Required overrides and behavior

`Eval(t)` returns an `ObjectState` whose `obj` is this object and whose validity covers the time for which all authored inputs and the generated publication remain valid. Do not run a full generation synchronously from `Eval` during interactive viewport edits. If no matching publication exists, return a small icon/proxy object or the last valid publication and schedule generation. Render evaluation uses a blocking path in the render adapter.

`GetRenderMesh` is an aggregate fallback only. It must request a render-mode S0 to S12 evaluation, compact only visible render items, batch by GeometryTable source and material, and merge into a TriObject or `Mesh`. It must enforce Render Max Items and Max Faces. On a cap breach, set a diagnostic `renderLimited` state, return a bounded fallback if safe, and make `Display` draw the F warning icon. Check `view.CheckForRenderAbort()` in the loop as recommended by Autodesk.

`GetWorldBoundBox` transforms the published or conservative input bounds through the node world transform. For a dirty object, return the union of the last published world bounds and a conservative authored bound, not an empty box. This avoids viewport disappearance during asynchronous rebuilds. `GetLocalBoundBox` uses FL bounds from S0 and adds the largest source radius, maximum falloff, and optional camera expansion. For an empty Icon object use a small configurable icon box.

`Display` handles legacy viewport drawing and selection brackets. It should not loop through every item. If `IObjectDisplay2` is available, submit the Nitrous display provider and let it own instance buffers. Legacy `Display` draws the icon, stale-result indicator, F warning, and a low-count proxy when Nitrous is unavailable.

`HitTest` uses a compact spatial index of item bounds or point-cloud samples. It may fall back to the object icon if no publication exists. Respect selection level, crossing, and hidden flags. Hit test sampling has its own cap (`displayHitTestMax`, default 1,000 [DESIGN] based on the Forest point-cloud tuning clue) and must never force a million-item mesh build.

`NotifyRefChanged` is the only path by which scene changes become DirtyBits. It must not run worker jobs or call Max UI APIs. It records dirty state under a mutex or Max main-thread guard, invalidates the appropriate checkpoints, and sends `PART_OBJ` or the smallest relevant part ID to the dependency graph.

`Clone` copies authored parameters, list entry IDs, override chunks, manual items, and library asset IDs. It does not copy generated checkpoints, GPU buffers, render target vectors, or source dependency registrations. Remap node and material references through the supplied `RemapDir`; stable entry IDs remain unchanged within a clone unless the operation explicitly requests a new identity. The clone gets a new object generation counter.

`Save` and `Load` serialize ParamBlock2s through Max's normal mechanism, then write versioned chunks for `algoVersion`, entry ID counters, paint strokes, overrides, manual items, and library provenance. Never serialize a Population as authored state. On load, rebuild reference maps and schedule S0 after post-load notifications settle.

`GetInterface` returns the object-level `IObjectDisplay2`, `RenderTimeInstancingInterface` provider, and a Cyrus `FPInterface` implementation when requested. Return `nullptr` for unsupported IDs. Use the SDK's exact interface ID declarations and do not expose a guessed interface such as `IRenderInstance`.

## 4. ParamBlock2 layout and stable parameter IDs

### 4.1 Naming rules

Every parameter has a numeric ID that never changes. The internal name is a code symbol, not a localized UI string. List parameters are parallel arrays for Max compatibility, but each list row includes an explicit stable `entryId`. UI order is stored separately from entry identity. The `TYPE_INODE_TAB` slot and the stable ID tab have equal lengths and are resized together under one undo transaction.

The table below is the required shell layout. Defaults marked [DESIGN] are Cyrus defaults, not assertions about undocumented Forest defaults. Dirty bits refer to the groups in 00 section 7. The actual enum values should be generated in one header and asserted against this table in tests.

### 4.2 Rollout parameters

| UI name | Internal name | Type | Default | Range or units | Rollout | DirtyBits | Notes |
|---|---|---|---|---|---|---|---|
| Enabled | `p_enabled` | bool | true | on/off | General | `D_GENERAL` | Disable object in viewport and render separately below. |
| Seed | `p_seed` | u32 | 1 | 0 to 2^32-1 | General | `D_DISTRIBUTION` | Feeds StableRNG, never use global RNG. |
| Mode | `p_generationMode` | enum | Generate | Generate, Icon, Selection, Preset | General | `D_INPUTS` | Create mode is not the authored distribution mode. |
| Coordinate mode | `p_coordinateMode` | enum | XY | XY, UV | General | `D_SURFACE_GEOM` | XY generation then Z drop; UV uses surface map. |
| Distribution type | `p_distributionType` | enum | Image | Image, Path, Reference, Particle, Manual | Distribution | `D_DISTRIBUTION` | Maps to GenKind. |
| Density | `p_density` | float | 1.0 | 0 to 1, normalized | Distribution | `D_DISTRIBUTION` | UI percentage. |
| Spacing | `p_spacing` | float | 100.0 | system units | Distribution | `D_DISTRIBUTION` | Used by lattice/path sampling. |
| Distribution map | `p_distributionMap` | texmap ref | null | map or null | Distribution | `D_DIST_MAP` | Baked to MapGrid in S0. |
| Map channel | `p_distributionMapChannel` | int | 1 | 1 to 99 | Distribution | `D_DIST_MAP` | Explicit channel, zero means generated FL coordinates. |
| Path nodes | `p_pathNodes` | `TYPE_INODE_TAB` | empty | spline nodes | Distribution | `D_AREA_GEOM` | Stable path row IDs in `p_pathEntryIds`. |
| Reference nodes | `p_referenceNodes` | `TYPE_INODE_TAB` | empty | Cyrus or reference nodes | Distribution | `D_INPUTS` | Dependency and cycle checks apply. |
| Particle node | `p_particleNode` | inode | null | Particle Flow node | Distribution | `D_INPUTS` | Snapshot particles on main thread. |
| Area nodes | `p_areaNodes` | `TYPE_INODE_TAB` | empty | spline, mesh, Cyrus | Areas | `D_AREA_GEOM` | Ordered program entries. |
| Area role | `p_areaRole` | enum tab | Include | Include, Exclude, Mask | Areas | `D_AREA_GEOM` | Per area entry. |
| Area blend | `p_areaBlend` | enum tab | Replace | Replace, Add, Subtract, Multiply | Areas | `D_AREA_GEOM` | Per area entry. |
| Area entry IDs | `p_areaEntryIds` | u32 tab | generated | immutable | Areas | `D_AREA_PROGRAM` | Never use UI index as StableKey identity. |
| Surface nodes | `p_surfaceNodes` | `TYPE_INODE_TAB` | empty | mesh, patch, poly | Surfaces | `D_SURFACE_GEOM` | Slot type is validated at assignment. |
| Surface IDs | `p_surfaceEntryIds` | u32 tab | generated | immutable | Surfaces | `D_SURFACE_GEOM` | Used by surfaceId and cache keys. |
| Drop direction | `p_dropDirection` | Point3 | (0,0,-1) | unit vector | Surfaces | `D_SURFACE_GEOM` | FL direction, normalize on write. |
| Surface offset | `p_surfaceOffset` | float | 0 | system units | Surfaces | `D_SURFACE_GEOM` | Applied after hit. |
| Boundary mode | `p_boundaryMode` | enum | Point | Point, Size, Edge | Areas | `D_BOUNDARY` | Edge is render-time and capability dependent. |
| Include falloff | `p_includeFalloff` | float | 0 | system units | Areas | `D_FALLOFF` | Curve in shared curve widget. |
| Exclude falloff | `p_excludeFalloff` | float | 0 | system units | Areas | `D_FALLOFF` | Curve in shared curve widget. |
| Falloff curve | `p_falloffCurve` | curve | linear | normalized | Areas | `D_FALLOFF` | Shared core curve serialization. |
| Geometry names | `p_geomNames` | string tab | source name | UTF-8 | Geometry | `D_GEOM_LIST` | Editable label. |
| Geometry nodes | `p_geomNodes` | `TYPE_INODE_TAB` | null | object nodes | Geometry | `D_GEOM_LIST` | One row can be a group, proxy, LOD, or non-geometric node. |
| Geometry entry IDs | `p_geomEntryIds` | u32 tab | generated | immutable | Geometry | `D_GEOM_LIST` | Resolve to GeometryTable index per snapshot. |
| Geometry disabled | `p_geomDisabled` | bool tab | false | on/off | Geometry | `D_GEOM_LIST` | Still consumes selection probability. |
| Geometry source kind | `p_geomSourceKind` | enum tab | CustomObject | CustomObject, Template, Billboard, LOD, Proxy, Null | Geometry | `D_GEOM_LIST` | Template ID or source node supplies data. |
| Geometry scale | `p_geomScale` | float tab | 1.0 | 0 to 100 | Geometry | `D_GEOM_LIST` | Per-entry scalar. |
| Geometry global scale | `p_geomGlobalScale` | float tab | 1.0 | 0 to 100 | Geometry | `D_GEOM_LIST` | Stored per row for library portability; object-wide shortcut can write all rows. |
| Width / Height | `p_geomWidth`, `p_geomHeight` | float tab | source bounds | system units | Geometry | `D_GEOM_LIST` | Billboard dimensions or explicit override. |
| Z Offset | `p_geomZOffset` | float tab | 0 | system units | Geometry | `D_GEOM_LIST` | Along local up after pivot placement. |
| Center Displace | `p_geomCenterDisplace` | float tab | 0 | normalized width | Geometry | `D_GEOM_LIST` | Billboard pivot offset. |
| Collision Radius | `p_geomCollisionRadius` | float tab | 1.0 | 0 to 100 | Geometry | `D_COLLISION` | Multiplies global collision radius. |
| Probability | `p_geomProbability` | float tab | 1.0 | 0 to 100 | Geometry | `D_GEOM_LIST` | Normalize and Randomize alter values in one undo step. |
| Color ID | `p_geomColorId` | Point3 or color | white | RGB / ID | Geometry | `D_GEOM_LIST` | Used by viewport and color matching. |
| Material | `p_geomMaterial` | material ref tab | null | material | Geometry | `D_MATERIAL` | Auto Multi/Sub is built in S0. |
| Include Children | `p_geomIncludeChildren` | bool tab | false | on/off | Geometry | `D_GEOM_LIST` | Expands hierarchy at snapshot time. |
| Keep Group Hierarchy | `p_geomKeepHierarchy` | bool tab | true | on/off | Geometry | `D_GEOM_LIST` | Group transform and culling policy. |
| Non-geometric | `p_geomNonGeometric` | bool tab | false | on/off | Geometry | `D_GEOM_LIST` | Permit lights and procedural objects. |
| LOD source | `p_geomLodNode` | inode tab | null | ForestLOD-like node | Geometry | `D_GEOM_LIST` | Capture child levels and switching thresholds. |
| Renderer proxy | `p_geomProxyAsset` | string tab | empty | asset path | Geometry | `D_GEOM_LIST` | Resolve only in render adapter. |
| Collision enabled | `p_collisionEnabled` | bool | false | on/off | Distribution | `D_COLLISION` | Preview option is separate. |
| Collision radius | `p_collisionRadius` | float | 1.0 | normalized | Distribution | `D_COLLISION` | Global radius multiplier. |
| Collision priority | `p_collisionPriority` | enum | StableKey | StableKey, spatial order | Distribution | `D_COLLISION` | StableKey preserves thread independence. |
| Transform translation | `p_transformTranslation` | Point3 | zero | system units | Transform | `D_TRANSFORM` | Random range center. |
| Transform rotation | `p_transformRotation` | Point3 | zero | degrees | Transform | `D_TRANSFORM` | UI degrees, core radians. |
| Transform scale | `p_transformScale` | Point3 | one | normalized | Transform | `D_TRANSFORM` | Per-axis range. |
| Mirror | `p_mirror` | bool | false | on/off | Transform | `D_TRANSFORM` | Stable random sign. |
| Follow normal | `p_followNormal` | float | 1.0 | 0 to 1 | Transform | `D_TRANSFORM` | Slerp upright to surface alignment. |
| Camera clipping | `p_cameraClipping` | bool | false | on/off | Camera | `D_CAMERA` | Feeds ViewMask, not canonical population. |
| Camera node | `p_cameraNode` | inode | null | camera | Camera | `D_CAMERA` | Capture at S0. |
| Expand frustum | `p_cameraExpand` | float | 0.1 | normalized | Camera | `D_CAMERA` | Conservative view margin. |
| Far clip | `p_cameraFarClip` | float | 0 | system units | Camera | `D_CAMERA` | Zero means unlimited. |
| Back offset | `p_cameraBackOffset` | float | 0 | system units | Camera | `D_CAMERA` | Camera-space depth margin. |
| LOD override distance | `p_lodMaxDistance` | float | 0 | system units | Camera | `D_CAMERA` | Zero means source LOD setting. |
| Viewport display | `p_displayMode` | enum | Adaptive | Mesh, Proxy, PointCloud, Adaptive | Display | `D_DISPLAY` | Nitrous path. |
| Viewport max items | `p_viewportMaxItems` | u32 | 5000 | item count estimate | Display | `D_DISPLAY` | Default is [DESIGN], not verified Forest behavior. |
| Point cloud cap | `p_pointCloudCap` | u32 | 250000 | points | Display | `D_DISPLAY` | Matches documented Forest cap. |
| Manual update | `p_manualUpdate` | bool | false | on/off | Display | `D_DISPLAY` | Requires explicit update action. |
| Render mode | `p_renderMode` | enum | Automatic | Automatic, Meshes | Render | `D_RENDER` | Automatic uses instance provider when possible. |
| Render max items | `p_renderMaxItems` | u32 | 1000000 | item count | Render | `D_RENDER` | Current documented value. |
| Render max faces | `p_renderMaxFaces` | u32 | 5000000 | faces | Render | `D_RENDER` | Current documented value. |
| Hide sources | `p_hideSources` | bool | true | on/off | Render | `D_RENDER` | Hide custom objects before render. |
| Edge preview | `p_edgePreview` | bool | false | on/off | Render | `D_RENDER` | Expensive and off by default. |
| Material tint | `p_tint` | color | white | RGBA | Material | `D_MATERIAL` | Shading payload. |
| Tint map | `p_tintMap` | texmap ref | null | map | Material | `D_MATERIAL` | Baked to MapGrid. |
| Surface map channel | `p_surfaceMapChannel` | int | 0 | 0 to 99 | Material | `D_MATERIAL` | Zero means distribution map coordinates. |
| Animation samples | `p_animSamples` | int | 1 | 1 to 64 | Animation | `D_ANIMATION` | Render sample cap is separate from storage cap. |
| Effects enabled | `p_effectsEnabled` | bool | true | on/off | Effects | `D_EFFECTS` | Effects execute at S10. |
| Effects program | `p_effectsProgram` | blob/string | empty | versioned bytecode | Effects | `D_EFFECTS` | Core VM input, no Max objects. |
| Edit mode | `p_editMode` | enum | Generate | Generate, CustomEdit | Edit | `D_OVERRIDES` | Manual items and overrides are chunks. |

A release may add parameters only by appending IDs. Removing a field means retaining a hidden deprecated parameter so old ParamBlock2 indexes remain loadable.

## 5. References, dependencies, and notifications

### 5.1 Reference layout

The object has ParamBlock2 references for each block plus direct references for implementation-owned objects such as the `FPInterface` state if required by the SDK. Node references use `TYPE_INODE_TAB` where a rollout exposes a list. A row has a parallel stable ID, role enum, and optional source metadata. Never infer a row's identity from an index.

Reference roles include `Area`, `Surface`, `Path`, `ReferenceSource`, `ParticleSource`, `GeometrySource`, `Material`, `TextureMap`, `Camera`, `LodSource`, and `CyrusUpstream`. A single node can occur in multiple roles, but a source in a cycle must be rejected before it is written into the ParamBlock2.

For Cyrus to Cyrus references, walk the candidate upstream object's dependency edges before assignment. If `A` references `B`, adding an edge `B -> A` is rejected. The check must include transitive edges and use object handles, not names. If a reference is loaded from an old file and creates a cycle, retain the reference as unresolved, mark the object invalid, and show a repair diagnostic instead of recursively evaluating.

Upstream populations are immutable and versioned. In viewport mode, use the latest published upstream version and schedule reevaluation when it changes. In render mode, request an upstream render snapshot synchronously in topological order. The cache key includes upstream object handle and populationVersion, as required by 00 section 9.

### 5.2 Notification mapping

Notifications must be mapped narrowly enough to preserve incremental evaluation but conservatively enough to avoid stale snapshots. The mapping below is the implementation baseline. The exact `REFMSG_*` names available can vary, so guard optional messages with SDK version checks.

| Notification | Typical source | DirtyBits | Part ID |
|---|---|---|---|
| `REFMSG_CHANGE` from ParamBlock2 | scalar or tab edit | parameter's declared group | `PART_OBJ` plus group token |
| `REFMSG_CHANGE` from area node | spline topology, transform, visibility | `D_AREA_GEOM(entryId)` | `PART_OBJ` |
| `REFMSG_CHANGE` from surface node | mesh, transform, topology | `D_SURFACE_GEOM(entryId)` | `PART_OBJ` |
| `REFMSG_CHANGE` from geometry node | source mesh, material, children | `D_GEOM_LIST` | `PART_OBJ` |
| `REFMSG_CHANGE` from material or texmap | shader or map data | `D_MATERIAL` or `D_DIST_MAP` | `PART_OBJ` |
| `REFMSG_NODE_NAMECHANGE` | source label only | none for generation | `PART_OBJ` for UI refresh |
| `REFMSG_TARGET_DELETED` | node or map deleted | input group, remove/disable row | `PART_OBJ` |
| `REFMSG_NODE_LINK` / `REFMSG_NODE_UNLINK` | hierarchy membership | `D_GEOM_LIST` | `PART_OBJ` |
| `REFMSG_SUBANIM_STRUCTURE_CHANGED` | animated controller structure | `D_TIME` and owning group | `PART_OBJ` |
| `REFMSG_CONTROLREF_CHANGE` | controller changed | `D_TIME` and owning group | `PART_OBJ` |
| `REFMSG_IS_OK_TO_CHANGE` | Max asks before mutation | no dirtying | return approval |
| `REFMSG_NODE_HANDLE_CHANGED` | handle remap/load | rebuild role maps | `PART_OBJ` |
| `REFMSG_USER + Cyrus population published` | upstream Cyrus | `D_INPUTS` | `PART_OBJ` |

`PART_ALL` is reserved for migrations, algorithm-version changes, corrupted reference maps, and unknown structural notifications. Do not use `PART_ALL` for every parameter click.

The first-dirty-stage table is:

```text
D_GENERAL, D_INPUTS                  -> S0
D_AREA_GEOM, D_AREA_PROGRAM           -> S1
D_SURFACE_GEOM                        -> S2
D_FALLOFF, D_BOUNDARY                 -> S3 or S4 as applicable
D_DIST_MAP, D_DISTRIBUTION            -> S1 or S5
D_GEOM_LIST                           -> S0, then S6
D_TRANSFORM                           -> S7
D_COLLISION                           -> S9
D_OVERRIDES, D_EFFECTS                -> S10
D_MATERIAL, D_ANIMATION               -> S11
D_CAMERA, D_DISPLAY                   -> V or display cache only
D_RENDER                              -> render adapter only
D_TIME                                -> S0, with time-aware cache keys
```

A geometry source change must restart S0 because its bounds, topology, material table, and element masks may change even if the list row is unchanged. A source transform may be treated as S0 too, because the snapshot transforms geometry into FL.

## 6. Snapshot builder S0

### 6.1 Main-thread contract

`SnapshotBuilder::build(CyrusScatterObject&, TimeValue t, EvalMode mode)` executes only on the main thread. It creates a `std::shared_ptr<const SceneSnapshot>` after all Max calls are complete. The builder first reads parameter blocks into a POD `ScatterParams`, captures node handles and validity intervals, then evaluates scene inputs. Worker stages receive only immutable plain data.

A snapshot contains:

```cpp
struct SceneSnapshot {
    uint64_t sourceVersion;
    TimeValue time;
    Interval validity;
    Transform forestToWorld, worldToForest;
    ScatterParams params;
    std::vector<AreaSnapshot> areas;
    std::vector<SurfaceSnapshot> surfaces;
    GeometryTable geometry;
    CameraSnapshot camera;
    std::vector<MapGrid> maps;
    std::vector<UpstreamPopulation> upstream;
    DiagnosticsInput diagnostics;
};
```

All pointer-like fields in core are IDs or shared immutable buffers. Max node handles are retained only in a Max-layer provenance record used by render adapters and diagnostics.

### 6.2 Evaluating nodes and converting to TriObject

For each referenced node, call `EvalWorldState(t)`. Inspect the returned `ObjectState::obj`. If it is already a `TriObject`, use its mesh without deleting the object. Otherwise check `CanConvertToType(triObjectClassID)`, call `ConvertToType(t, triObjectClassID)`, and wrap the returned object in an RAII holder that deletes it only if the returned pointer differs from the source object. Never store a `Mesh*` into a worker snapshot without copying its vertices, faces, map channels, material IDs, and validity metadata.

For patch and poly sources, prefer a safe conversion to TriObject for the render and surface paths. Where a shape is expected, do not triangulate blindly. A spline node may evaluate to `ShapeObject`; extract its `PolyShape` data, including closed/open state, knot types, interpolation flags, and per-spline IDs. Use the SDK's exact `ShapeObject` and `PolyShape` accessors for the selected version. A shape snapshot stores double precision FL vertices and winding, not live Max pointers.

Apply node object transforms and the inverse Cyrus node transform in S0. For a source mesh:

```cpp
Matrix3 nodeWorld = node->GetObjectTM(t);
Matrix3 toForest = cyrusWorld.inverse() * nodeWorld;
for (vertex : tri.mesh.verts)
    dst.vertices.push_back(toForest.PointTransform(vertex));
```

Use the actual world transform convention from the Max SDK and validate with a one-axis test. Preserve source local pivot and group hierarchy policy separately from transformed geometry. If a source has animated geometry, include time or animation sample in the `SourceSnapshot` key.

### 6.3 Shapes, surfaces, and areas

For areas, retain closed spline loops and polygon meshes as `Boundary2D` inputs. For surface nodes, build the surface acceleration data needed by S2: triangles, normals, material IDs, UV channels, FL bounds, and a BVH or grid. The `SharedCacheRegistry` key follows 00 section 10: node handle, geometry validity/version, topology version, UV channel, and FL transform.

A Cyrus upstream source is not converted to a mesh at S0 unless `Render Mode=Meshes` explicitly requires it. Instead, request its immutable `PublishedPopulation`, source geometry table, and populationVersion. Preserve source identity and transform into this forest's FL space. Cycle detection has already run at assignment, but S0 detects a corrupt legacy cycle and fails closed.

### 6.4 Camera and time

Capture the active render camera or explicitly assigned camera at `t`, its world transform, projection, near and far settings, environment range if available, and a stable camera ID. If no camera is assigned, camera clipping is disabled in the snapshot. Camera changes dirty V rather than S1 unless a render setting explicitly requests render-time visibility generation.

Validity is the intersection of ParamBlock2 validity, source object validity, material and texmap validity, camera validity when used, and upstream population validity. `Eval` can return that intersection. A controller's validity that ends before the next frame forces a new snapshot. Do not claim a multi-frame validity for an animated source merely because its mesh happens to be unchanged at the current time.

### 6.5 Texmaps to MapGrids

Texmaps can call back into Max and therefore are sampled on the main thread in S0. For each map, create a `MapGrid` keyed by texmap handle, time, resolution, channel, and mapping transform. Determine resolution from the distribution grid and an explicit cap. Evaluate in batches using the map's bitmap or shade context APIs available in the target SDK. Store normalized color, alpha, and any needed scalar channel in a contiguous grid. If a procedural map cannot be safely sampled at the requested resolution, mark it `mainThreadBatchOnly` and sample bounded batches during S0 rather than leaking it to workers.

Map grids use deterministic addressing and clamp or wrap according to the authored map settings. Do not use floating point texture coordinates as cache keys. Include the mapping origin and scale in the key. S5 and S11 consume only `MapSampler` methods from core.

## 7. Geometry List and GeometryTable

### 7.1 Row semantics

The Geometry List is a UI list, not the runtime table. Each row has a stable `entryId` and all properties in the required input list:

* Name
* Disable
* Custom Object or Template or billboard
* Scale
* Global Scale
* Width and Height
* Z Offset
* Center Displace
* Collision Radius
* Probability
* Color ID
* Material
* Include Children
* Keep Group Hierarchy
* Non-geometric
* ForestLOD-like LOD source
* renderer proxy metadata

Custom Object stores a live node reference. Template stores a versioned template ID and optional library asset ID. A billboard stores a generated plane recipe and material reference, not a fake source node. Null or disabled rows remain table entries so probability and StableKey selection remain deterministic.

### 7.2 Snapshot construction

For every UI row in stable UI order:

1. Read the immutable `entryId` and row fields.
2. Resolve the source node at time `t` if present.
3. Expand children only if Include Children is enabled. If Keep Group Hierarchy is true, preserve one group source with child element metadata. If false, create child source entries that share the parent row's selection identity but have independent element transforms and bounds.
4. Convert geometric sources to a compact `SourceSnapshot`. For non-geometric sources, call a renderer adapter later and store a conservative bound and source token.
5. Read or build the material binding. If an item material is absent, retain source materials. If an override exists, assign a material table entry.
6. Compute source bounds, footprint radius, collision radius, pivot, Z offset, center displacement, and LOD metadata.
7. Append a `GeometryTableEntry` and map row `entryId` to its runtime index.

```cpp
struct GeometryTableEntry {
    uint32_t entryId;
    SourceKind kind;
    SourceRef source;
    Bounds3f bounds;
    Vec3f pivot;
    Vec3f footprint;
    float scale;
    float globalScale;
    float zOffset;
    float centerDisplace;
    float collisionRadius;
    float probability;
    uint32_t colorId;
    MaterialBinding material;
    LODRecipe lod;
    ItemFlags defaultFlags;
    bool disabled, nonGeometric, keepHierarchy;
};
```

The footprint is conservative. For a mesh, project transformed vertices into the placement plane and store an oriented or circular bound. For a billboard, use Width and Height and the center displacement to shift its pivot. For a group, union child bounds in group-local space if hierarchy is retained. `pivot` is the source origin after Max object pivot and authored center displacement have been resolved.

The transform used at S7 is conceptually:

```text
itemWorld = forestWorld
          * placement(surface position and orientation)
          * authored pivot correction
          * random transform
          * source local transform
```

The exact matrix multiplication is centralized in the core transform service. Do not bake Z offset into source vertices because that would make a library import destructive and would complicate LOD and Edge element tests.

### 7.3 Probability normalization and randomization

Normalize computes `p_i = max(0, p_i) / sum(max(0, p))` across enabled and disabled rows alike, because disabled rows intentionally consume selection probability. If the sum is zero, use a deterministic uniform distribution among rows [DESIGN]. Randomize assigns stable pseudo-random weights using `hash(objectSeed, entryId, Purpose::GeometryProbability)` and normalizes them. Both operations are one undo transaction and preserve entry IDs. Runtime selection uses the cumulative table and a StableRNG value derived from candidate key, not a mutable sequential RNG.

### 7.4 Material consolidation

When auto consolidation is enabled, collect every distinct material binding and build a Cyrus Multi/Sub material with deterministic material IDs sorted by a stable material key: scene material handle when available, then serialized asset ID, then row entry ID. Remap source face material IDs into the combined table. A row material override therefore becomes a GeometryTable material offset, not a destructive edit to the source node. If the renderer rejects a combined material, render adapters may split batches while preserving the same per-instance material ID payload.

## 8. Create modes and CreateMouseCallBack

`CyrusCreateCallback` implements the Max create tool and delegates hit testing to a mode state machine.

* **Generate by picking spline:** first click picks a spline node, validates that it contains a usable `ShapeObject`, creates the Cyrus node, assigns an Area row with a new entry ID, and ends creation or continues for additional inputs according to the tool option.
* **Generate by picking surface:** first click picks a mesh, patch, or poly node, assigns a Surface row, and creates a default rectangular or surface-bound area if no area was selected. The default is a convenience, not an implicit permanent area type.
* **Icon Mode:** mouse down records the icon center in world space. Drag sets icon width. The callback creates an object with no areas and a conservative FL icon bound. It does not pick a surface.
* **Populate from Selection:** before creation, copy selected eligible source nodes into Geometry List rows as references. Do not clone meshes. If a selected node is a Cyrus object, run cycle detection before adding it.
* **Preset:** selecting a library preset first loads serialized parameter values and geometry assets into the new object, then Generate or Icon Mode supplies scene-specific area and surface references. Scene references from a preset are not silently redirected to arbitrary nodes.

Use `CreateMouseCallBack::proc` with the SDK's exact callback signature. On abort or right-click, delete the incomplete object and roll back temporary references. If a picked node is invalid, leave the creation tool active and show a non-modal status message. Creation is undoable as one Max hold transaction: create object, add initial list entries, and place icon.

## 9. Library and presets

### 9.1 Preset model

A preset is a serialized `ScatterPreset` consisting of ParamBlock2 values, stable geometry and area entry metadata, curves, material asset references, and library provenance, with all live scene references removed or replaced by asset IDs. It must not include node handles, node handles from a source scene, cached populations, GPU buffers, or absolute dependency edges.

```cpp
struct ScatterPreset {
    uint32_t schemaVersion;
    uint32_t algoVersion;
    std::string presetId;
    std::string displayName;
    std::vector<uint8_t> paramsBlob;
    std::vector<GeometryAssetRef> geometry;
    std::vector<MaterialAssetRef> materials;
    std::vector<CurveBlob> curves;
    ThumbnailRef thumbnail;
    CapabilityTags capabilities;
};
```

On import, restore all scalar and list settings, allocate new local entry IDs unless the import explicitly requests identity preservation, and ask the user or import policy how to resolve each asset. Area and Surface references are intentionally left empty by default. A preset can optionally include a binding manifest with node names, but names are hints and must never silently bind.

### 9.2 Library index

Use an XML `index.xml` for interoperability with Forest-style libraries, but define a Cyrus namespace and a versioned JSON sidecar for fields XML cannot safely represent. A library folder contains:

```text
library-root/
  index.xml
  cyrus-assets.json
  thumbnails/
  geometry/
  materials/
  presets/
```

The index entry includes `id`, `type` (`billboard`, `object`, `preset`), display name, category path, version, thumbnail relative path, source `.max` or material path, object name or preset file, checksum, renderer tags, and an import policy. Paths are relative and normalized. The index parser rejects path traversal and records missing assets as unresolved.

Use atomic writes: save to a temporary index, flush, then replace. A library scan runs off the UI thread only after it has copied file metadata; Max scene import still runs on the main thread. Cache thumbnails by checksum.

### 9.3 XRef versus merge

For a 3D library object, XRef mode records an external file path, object identifier, file timestamp or content hash, and a proxy bound. It keeps source topology out of the scene and allows updates, but requires the file on render nodes. Merge mode imports a copy into the current scene and records the imported node handle and original asset ID. It survives missing library files but increases scene size and can create duplicate materials.

The import dialog must expose: XRef, Merge, or Cancel on missing asset; material policy `Use Scene`, `Use Library`, or `Ask`; and whether to inherit Width, Height, Z Offset, and Center Displace. [FP-DOC] Forest documents the same broad choices, but the Cyrus serialization and asset resolver are our design. Re-importing a preset must be idempotent when an asset ID and version match.

## 10. UI architecture and Stats window

Use Qt widgets embedded in Max rollouts. Each rollout owns a controller connected to ParamBlock2 and an undo command. The controller never stores a second authoritative value. It reads the parameter, edits under a hold, and updates the block. List widgets use stable entry IDs as row user data, so drag reorder changes order IDs only.

Required widgets:

* `CyrusGeometryListWidget`: thumbnails, drag reorder, multi-select, inline Name edit, Disable, probability, source picker, material picker, and context actions Normalize, Randomize, Include Children, and Consolidate.
* `CyrusNodeListWidget`: reference rows with role validation, cycle diagnostic, node name, and remove button.
* `CyrusCurveEditor`: shared by boundary falloff, density, scale, camera falloff, and transform curves. Store a versioned normalized curve independent of Qt object lifetime.
* `CyrusMapPicker`: texmap reference and channel controls, plus bake resolution and cache status.
* `CyrusStatsWindow`: modeless, refreshable status view. It displays candidates, survivors, culls by reason, stage times, cache hits and misses, source memory, map bake time, worker count, publication version, and render cap status. It must support copy to clipboard and export JSON.

The Stats window must identify whether figures describe canonical population, viewport ViewMask, or render output. A common debugging error is comparing a camera-culling count with a population count.

Viewport updates are coalesced with a short Qt timer. ParamBlock2 notifications mark dirty bits immediately, but the worker request is delayed until a burst of edits ends. Manual Update suppresses generation requests while preserving dirty state. A stale worker result is discarded by `evalGeneration` comparison.

## 11. Save, load, migration, and undo

ParamBlock2 handles ordinary values. Custom chunks use four-byte IDs and a `u32 chunkVersion`:

```text
CYRS: header, file schema, algoVersion
CYID: entry ID counters and order arrays
CYPA: paint strokes
CYOV: StableKey -> OverrideRecord
CYMN: ManualItem array
CYLB: library provenance and unresolved asset IDs
CYDG: optional diagnostics only, never required for evaluation
```

`CYDG` is optional and may be omitted in production. No population is saved as truth. Post-load processing uses `IParamBlock2PostLoadCallback` or `ParamBlockPLCB` to migrate block versions, then a Cyrus post-load callback to repair parallel tab lengths, allocate missing stable IDs, rebuild reference roles, and detect cycles.

Migration steps are explicit and monotonic. Example: schema 1 had UI-index overrides, schema 2 introduced entry IDs. During migration, map an old index to the saved row order, allocate an entry ID, and rewrite each override to that ID. If multiple rows are ambiguous, preserve the override as unresolved and show it in Stats. An algoVersion change never silently claims identical output. Keep old hash and sampling paths for files whose algoVersion requires them, as required by 00 section 5.

Parameter edits use `theHold.Begin()` and `theHold.Accept()` around the complete logical action. A slider drag should be one restore object, not hundreds. List reorder, Normalize, Randomize, add/remove row, material assignment, and preset import each have explicit restore records. Cancel invokes `Restore`, marks the relevant DirtyBits, and republishes the prior valid publication if available.

For async generation, undo is authored-state-only. A completed worker result from an earlier generation is discarded if its captured `sourceVersion` no longer matches. Undo never restores a GPU buffer directly.

## 12. Algorithms and pipeline integration

S0 reads every input needed by later stages and writes `SceneSnapshot`, including `GeometryTable`, surface acceleration, area shapes, camera, map grids, and upstream populations. S1 reads only snapshot POD data and writes candidate identity and XY provenance. S2 resolves surfaces. S3 evaluates ordered areas and filters. S4 and S5 use curves and MapGrids. S6 resolves `Population.geomId` to a GeometryTable index. S7 consumes pivot, footprint, and transforms. S8 uses bounds and marks `F_EDGE_CLIP` where Edge requires render masks. S9 uses collision radius. S10 reads override chunks and Effects bytecode. S11 reads material maps and animation state. S12 publishes a compact population.

Every random choice uses 00's StableRNG with an explicit purpose. Suggested purposes include `GeometryProbability`, `TransformTranslation`, `TransformRotation`, `TransformScale`, `Mirror`, `AnimationSample`, `Tint`, `LODVariation`, and `ViewportBudget`. Never call `std::rand`, a thread-local sequence RNG, or a random generator whose order depends on task completion.

The snapshot builder itself is O(total source topology plus map bake pixels plus referenced area vertices). It should cache source and map snapshots aggressively. The core stages are tileable except collision and cross-area operations, which use the halo strategy in 00 section 8. The shell owns cancellation and publication, not stage-specific thread primitives.

## 13. Edge cases and failure modes

* A deleted source node leaves a disabled unresolved row, not a shifted row. The UI shows the old name and an error icon.
* An invalid or non-closed spline is accepted as a Path input only if the distribution mode supports open paths. It is rejected for an Include boundary.
* A mesh with no faces produces a source with zero footprint and a diagnostic. It does not crash triangulation.
* A material or texmap that cannot be evaluated at S0 uses a neutral fallback and sets a diagnostic bit. Rendering must not call Max map code on workers.
* A source hierarchy with a cycle, or an upstream Cyrus cycle, fails closed with no generated population and an actionable error.
* A library asset disappears: XRef rows retain provenance, display the last safe bounds if available, and render as disabled until resolved.
* A NaN or infinite parameter is clamped at the ParamBlock2 boundary and logged. All vectors and quaternions are normalized with a zero-length fallback.
* Huge FL extents use chunk origins as required by 00 section 3. Bounds and collision distances remain double precision until stored output.
* Render and viewport can race only through immutable snapshots and publication versions. A render adapter pins its snapshot for the entire render frame.

## 14. Performance targets

These are [DESIGN] targets for a first production profile, not measured facts:

* S0 source snapshot of 50 million source faces from cache: under 100 ms main-thread wall time; a cache miss may be slower and should show in Stats.
* One million candidate S1 to S8 items on 16 workers: under 250 ms for simple planar input, excluding source and map builds.
* Geometry List with 1,000 rows: under 20 ms to rebuild metadata when source snapshots are cached.
* No per-item Max node and no per-item source mesh clone.
* Render target storage should stay below 64 bytes per live item where possible, with streaming for 10M items.

The primary traps are calling `EvalWorldState` from workers, rebuilding Multi/Sub materials per item, triangulating a source for each candidate, and treating a camera edit as a canonical population dirty. Stats should make all four visible.

## 15. Tests and Forest Lite comparison scenes

Unit tests in `tests/max_snapshot` use mocked node evaluations and verify:

1. TriObject conversion ownership deletes only converted objects.
2. Shape extraction preserves spline IDs, closure, winding, and FL transforms.
3. Stable entry IDs survive reorder, clone, save/load, and migration.
4. Normalize includes disabled probability rows.
5. GeometryTable footprints and billboard pivots are correct for negative scales and center displacement.
6. A cycle assignment is rejected, including a three-object cycle.
7. MapGrid cache keys separate time, channel, and mapping transform.
8. Param validity is the intersection of animated inputs.
9. Worker results are discarded after undo or a newer `evalGeneration`.

Forest Lite scenes should compare Generate by spline, Generate by surface, Icon Mode, a billboard with center displacement, a group with and without Keep Group Hierarchy, a disabled probability row, a source material plus override material, library XRef versus merge, and a moving animated mesh. Record source screenshots and exportable Cyrus snapshots. Mark all exact numeric differences [OPEN] until verified against the relevant Forest version.

## 16. Open questions

* The exact stable SDK signatures for `IObjectDisplay2`, RenderTimeInstancing, and Qt rollout integration must be checked against the chosen Max SDK.
* Forest's complete preset serialization schema is not public. Cyrus should document its own schema and only claim compatibility at the behavior level.
* Current Forest versions removed some older Geometry dimension controls in favor of Scale. Test whether a compatibility mode is needed for imported scenes.
* The exact order of area program, filtering, boundary checks, and collision is not fully public. The stage order in 00 is the Cyrus contract and should be validated with Forest Lite scenes.
* The active camera selection behavior differs by Forest version. Capture explicit camera when available and record the source version in diagnostics.
* Renderer-specific non-geometric and proxy source capture remains adapter work and must not be guessed in the core snapshot.

## 17. Architecture feedback

No conflict with 00 is required. One implementation caution is worth recording: `TYPE_INODE_TAB` is a Max serialization mechanism, while core identity is the stable `entryId`. The shell must never let a UI reorder or a deleted row alter a StableKey identity. A second caution is that S0 includes expensive main-thread work by design; source and map cache hits are therefore a release-critical feature, not an optional optimization.

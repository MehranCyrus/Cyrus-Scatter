# Cyrus Scatter: supplied engineering context for GPU research

Prepared 27 October 2026 for independent external researchers. These are supplied facts and pointers from the local coordinator. External researchers must label them as provided context and must not claim they inspected the repository or executed its tests.

## Product and task boundary

Cyrus Scatter 0.87.4.3 is a procedural scattering plugin. Current development and the cited scoped qualification use Windows x64 and 3ds Max 2027. The matched delivery has native interaction capability 11 and scene schema 63. This research request does not authorize a new plugin version, migration, installer, production rewrite, or support claim for other Max hosts.

Our immediate operation is moving an independently edited collider instance through scattered plants. Nearby plants receive a collision-dependent fitted shape. Leaving the area restores rest geometry. Wind, inertia, settling, and time-integrated physics are possible future applications, not the semantics of the current fitter.

We can recommend NVIDIA if justified. No CUDA-versus-OpenCL benchmark or supported Max GPU-compute integration has been established. Our hardware, GPU model/VRAM, display adapter, available CUDA toolkit, and external researchers' execution facilities are unspecified.

## Present data flow

```text
original scene source
    -> copied geometry / authored preparation
    -> immutable shared source definition + fingerprint
         geometry, guides, anchors, hierarchy, bindings, fixed parts

published scatter placement identities + instance transforms
    + independently edited collider transforms
    -> old/new neighborhood lookup
    -> relevant collider geometry in each plant's local frame
    -> CPU root classification / guide fit / surface refinement
    -> complete successor pose and visibility snapshot
    -> affected preview geometry / retained GPU drawing
    -> separate renderer / Bake / export geometry paths
```

Preparation is shared across instances. A posed plant keeps an array indexed by source guides, shared pointers to changed guide poses, hidden-root masks, and sparse rigid-part results. Unchanged guides reuse rest definitions. The pose object does not itself store a full duplicate of every source vertex; later preview/render materialization can still create substantial unique geometry for differently deformed instances.

That distinction matters: shared source meshes do not make all per-instance guide state or differently deformed vertex output free. Investigate compact active-guide storage and shared-source drawing with pose lookup before proposing millions of duplicated vertex buffers.

Branches depend on their parent guides. Bound leaves/flowers follow guide frames; some parts remain fixed. The editor can override inferred roles, roots, parents, and guide points. A GPU architecture must preserve authored decisions and stable bindings rather than inferring a new skeleton for every instance or drag event.

## CPU and host boundaries

The numerical implementation is native C++. The engine builds/reuses plant and collider spatial indexes, gathers affected work, schedules CPU jobs dynamically, joins them, and merges results in stable input order before publication. Its executor is synchronous. Large automatic batches can use up to eight CPU participants under current policy; session overrides and memory admission also affect participation. This is not an already asynchronous task system.

Workers consume owned numerical data. Host SDK evaluation, scene references, and publication remain on Max's host thread. An asynchronous compute path needs new ownership, source/session revision checks, stale-result suppression, progress, and retirement rules.

The current successor copies maps of retained poses/root counts before updating affected entries. This is another cost to profile as the number of retained deformations grows. Do not assume neighborhood search is the only scaling cost, or that GPU arithmetic solves CPU snapshot-copy/publication overhead.

MAXScript/managed code owns UI, persisted settings, and bounded coordination. Bulk placement-sized work should not move back into script. Source changes, published placement changes, contact changes, and viewport-style changes have different invalidation scopes.

## Geometry and correctness

Internal numeric coordinates use metres and +Y up; Max uses scene units and +Z up. Source and instance transforms require explicit frame conversion. Positive uniform instance scale is admitted; arbitrary nonuniform/mirrored/sheared transforms are not current qualification.

Contact handling includes mesh signed-distance/occupancy queries, capsule/whole-guide checks, fixed anchors and surfaces, constrained guide fitting, and bounded detailed surface refinement. Source foliage can intersect even when its guide is clear, so a guide-only GPU result cannot automatically satisfy existing visible-mesh expectations.

Collision gap is distinct from exclusion:

- Contact gap expands the clearance used to fit bending geometry.
- Hide margin expands the independently selected root exclusion area.
- Inside solid uses actual solid geometry near roots/anchors.
- Under collider adds downward footprint exclusion along world up, clipped to collider geometry above the root. It deliberately applies to floating objects too.
- Hiding removes a rooted group and its attachments. It does not Boolean-cut the mesh or excuse a failed fit by removing arbitrary blades.

If a root is fixed inside required bending clearance and outside the chosen hidden region, the successor may be infeasible. Retain the preceding complete publication and report the failure. GPU acceleration must not turn this into silent root drift, missing geometry, or partial publication.

The footprint's artificial upward extent previously threatened BVH split quality during development. The delivered plant index splits these projected bounds horizontally. Future GPU grids/BVHs must preserve useful ground-plane locality and support old/new edited neighborhoods, including undoing or removing a collider.

Do not conflate deterministic IDs/merge ordering with bitwise CPU/GPU floating-point equality. State numerical and visual acceptance separately. Current independent audits use double-precision complete visible geometry; renderer float delivery remains a distinct boundary.

## Current viewport path

The renderer uses Max public SDK custom render items, `IVirtualDevice`, vertex-buffer handles, HLSL material handles, and instanced triangle draws. Current shaders use shader model 5.0. Their existence establishes a GPU display path, not a public raw-resource interoperability API.

`MeshItem::Display` reads the current viewport's legacy `ViewExp::IsWire()` flag and Nitrous visual style, switches raster fill, and selects the existing untextured stream/material for Wireframe. GPU buffers and placement results remain retained across F3/style changes. No raw Direct3D device, compute runtime, scene evaluation, or MAXScript is introduced inside Draw.

Any future compute design must separately prove how completed compute buffers/poses become supported Max display inputs. Windows CUDA/D3D sharing samples alone do not establish that Max's SDK permits equivalent resource access.

## Admissions and their meaning

The current engine admits at most 1,000,000 instances in an interaction layout, 16,384 collider instances, 64 relevant colliders for one plant, and 4,096 transient edited-instance overrides. Layout/index/query scratch has bounded admission; fitting and exact checks have additional work, memory, and source/guide limits. These are not one universal limit on all objects in a Max scene and are not performance guarantees.

Current live work may fail an admission and retain the old result. Propose evidence-based chunking, pooling, and artist diagnostics if these boundaries need to evolve. Do not simply remove them or allocate N×V output without a budget.

## Observed qualification: useful, narrowly scoped

The 0.87.4.3 r3 Max 2027 delivery passed 61 native tests and a scoped private-profile host campaign. Relevant observations:

| Observation | Scope |
|---|---|
| One grass source: 451 guides, 22,032 vertices, 27,501 triangles | Source-specific preparation, reused by its instances |
| 200 plants + 1 collider; 3 nearby candidates; 6 fitted guides; 62 hidden rooted groups | One localized direct instance-transform update |
| Native contact evaluation approximately 4.05 ms | One observed run; not p95, complete frame time, physical pointer latency, presented FPS, or GPU timing |
| Independent audit: 23,497 visible triangles, zero penetrating vertex pairs, zero touching triangle pairs, zero root-anchor error | One fitted plant, double-precision audit; maximum checked stem edge change about 9.145% |
| Raised collider: 0 groups hidden in Inside solid; 81 in Under collider; 451 with expanded Hide margin | Contact gap remained zero |
| Hide margin Undo/Redo, source reuse, Manual pending edits, save/reload and moved-collider restoration | Scoped Max 2027 checks |
| 5,000-instance native footprint test finds exactly one affected neighborhood | Simple numerical test; not 5,000 detailed plants simultaneously bending |
| Mixed Wireframe/shaded viewports and retained upload counters | Display behavior, not GPU-compute qualification |

Do not derive a million-object capacity or CUDA speedup from these observations.

## Local source/evidence map

These paths are pointers for the coordinator or later source review. They are not files the external researcher should pretend to have accessed:

| Local repository path | Relevant responsibility |
|---|---|
| `AminScatter/include/interactions_source.h` | Shared source and sparse pose representations; prepare/fit/audit interfaces |
| `AminScatter/src/interactions_source.cpp` | Root classification, guide fit, per-guide mesh checks, deformation and budgets |
| `AminScatter/include/interactions_geometry.h` | Transforms, closed geometry queries and numerical collision-world adapter |
| `AminScatter/src/interactions_geometry.cpp` | BVH/mesh queries, directional projected footprint and collision witnesses |
| `AminScatter/include/interactions_engine.h` | Layer settings, stable instances, layouts and snapshots |
| `AminScatter/src/interactions_engine.cpp` | Spatial indexes, local jobs, sparse overrides, merge and admission |
| `AminScatter/src/interactions_host.cpp` | Max capture, native/script protocol and source/runtime ownership |
| `AminScatter/src/interactions_render.cpp` | Renderer-facing interaction outputs and host publication |
| `AminScatter/src/point_display.cpp` | Retained viewport ownership, publication, GPU resource admission and telemetry |
| `AminScatter/src/mesh_display.inc` | Public SDK instanced mesh drawing and HLSL shaders |
| `AminScatter/tools/ui/templates/interactions-authoring.ms` | Settings ownership, source definitions and contact orchestration |
| `CyrusVegetationLab/experiments/stem-live/` | Preparation, topology, guide bindings and authored-role numerical code |
| `CyrusVegetationLab/core/fitter/` | Numerical guide-fitting foundation |
| `docs/ENGINEERING_FOUNDATION.md` | Native boundaries, failure preservation and future async/simulation contracts |
| `docs/plans/interaction-hide-wireframe-20261027/DELIVERY_08743.md` | Exact scoped release evidence and limitations |

The reference development build used MSVC tools 14.38.33130 and Windows SDK 10.0.19041.0 for the recorded Max 2027 compilation. This is an observed local toolchain, not a claim that every current CUDA toolkit or Autodesk's full published support matrix accepts it. Verify the proposed combination explicitly.

## What local engineers still need from the research

Give us exact Max SDK probes, supported resource-access findings, candidate buffer/pose schemas, numerical acceptance definitions, feasible interop alternatives, a fair CPU/CUDA/OpenCL benchmark protocol, and staged prototypes with stop criteria. We can subsequently run Max and hardware tests locally. A generic recommendation to “use GPU physics” is insufficient.

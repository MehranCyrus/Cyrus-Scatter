# Shared geometry and per-instance GPU deformation

**First prototype target: P — CPU-produced authoritative poses, GPU vertex evaluation in the Max retained display.**

## What should stay shared

Retain one rest mesh per prepared source/preview revision, including vertex correspondence, guide bindings, UV/material data and immutable rest frames. Unchanged instances reference this geometry and their transforms. Changed instances reference compact pose/visibility data. Merely turning each bent instance into a unique full mesh sacrifices much of the memory and upload advantage.

Instancing saves shared mesh storage and CPU submission. Every visible instance still invokes vertex shading and rasterizes its triangles. A million instances of a 27,501-triangle clump still represent 27.5 billion input triangles before culling. Solve throughput and draw throughput need independent budgets.

## Match current geometry before optimizing it

The CPU reference is `posePoint`, `poseDirection`, `skinTransform` and `visibleFace` in `interactions_source.cpp`. It includes anchors, rest-to-posed material frames, shortest-path spherical interpolation, parent attachments, rigid foliage, root smoothing, and explicit visibility. A generic two-bone blend is not an equivalent replacement.

For a representative stem point, the conceptual operation is:

```text
q_rest(s)  = interpolated rest material frame
q_pose(s)  = interpolated posed material frame
R(s)       = q_pose(s) * inverse(q_rest(s))
p_result   = posed center(s) + R(s) * (p_rest - rest center(s))
```

This describes the type of mapping to reproduce, not complete production code. Rigid leaves may use a single part attachment transform; fixed vertices bypass deformation. Port the actual boundary and smoothing rules, then verify vertex-by-vertex against the CPU. The local research surrogate uses normalized interpolation of already supplied quaternion/translation pairs and only proves a narrower arithmetic path.

## Public Max shader path

Prototype a shader-readable pose buffer bound through `HLSLMaterialHandle::SetBufferParameter`, an SDK-owned instance record that carries a pose page/index, and the existing source vertex/index buffers. Start with one source and one pose. Prove the exact buffer type, flags, element indexing and updates inside Max before designing a large page allocator. [SDK feasibility details](07_MAX_2027_INTEROP_FEASIBILITY.md).

An unchanged guide uses the shared rest definition. An untouched instance must remain on the cheap existing draw path or an equivalent shader rest branch. A sparse changed-guide table can point to compact pose pages; dense guide pages may be cheaper for plants whose many guides are all active. Measure both patterns with realistic cache misses rather than assuming maximum compression is fastest.

In this first candidate, CPU fitting writes compact poses; the host thread uploads those poses and publishes the new render state. Full vertex output need never return to the CPU during a preview drag. A final renderer or Bake request can still materialize the CPU reference geometry. This is a proposed architecture, not a path already tested in Max.

## Normals, tangents and surfaces

Rigid attached foliage can rotate normals/tangents with its attachment frame under admitted uniform scale. Smoothly varying stem deformation may require a derivative/Jacobian treatment or recomputed normals; merely rotating a normal by one local quaternion may not match deformed face geometry. Keep hard edges, explicit smoothing groups and tangent handedness coherent. Validate textured lighting, not only gray silhouettes.

For geometric normal recomputation, one thread per face plus segmented vertex accumulation is possible, but introduces extra memory, reductions and determinism issues. An analytic frame-based normal may be cheaper and sufficient if compared against a declared visual/angle tolerance. Do not add this cost to the surrogate benchmark retrospectively; it was not measured there.

Preserve original UV corners and material partitioning. A mirrored or nonuniform object transform is currently outside qualified interaction support; do not silently let a convenient shader normal matrix imply new solver support.

## Visibility without broken geometry

Root-group hiding requires all triangles belonging to a hidden group to disappear together. A vertex may participate in multiple corners/groups in awkward source topology. Test shared vertices explicitly. Options include per-group draw ranges, compacted visible index buffers, or shader clipping based on a consistent per-triangle/group attribute. Clipping all vertices of one triangle is different from setting selected shared vertices to arbitrary positions.

Do not implement hiding by collapsing vertices to the origin; that can create large accidental triangles, invalid bounds or shadow artifacts. Do not confuse Preview leaves/blades percentage with root exclusion or solver participation. At 100% preview, all admitted visible pieces should appear; lower percentages are explicit display LOD only.

## Bounds, picking and wireframe

A shader-deformed plant can extend beyond its rest bounds. Use conservative source reach or a validated pose-bounds reduction before publication, with an explicit CPU-side bound available to Max. Incorrectly small bounds cause culling, missing hit tests and clipped frames even when the shader is correct.

Picking must identify the same stable instance as Cyrus Edit and intersect either coherent deformed geometry or a documented conservative proxy. A rest-pose hit test while displaying bent leaves is a user-visible bug. CPU picking can evaluate only candidate instances/triangles; it need not read every GPU vertex each frame.

The current retained Wireframe path has its own representation and visual-style handling. A GPU deformation change must deform its edge positions too, preserving Mesh/Textured mesh/Point Cloud/box modes and selected-instance display. Multiple viewports should share prepared GPU data while respecting each view's culling/style; changing a view must not re-fit the plants.

## Final geometry consumers

Viewport shader output does not automatically provide geometry to a renderer, export, snapshot, mesh conversion or Bake. Preserve a CPU materialization function keyed by the same complete pose revision. Render synchronization must wait for the requested authoritative generation or execute the CPU path, never use whatever older preview happens to be on screen without an explicit policy.

Motion blur needs time samples, not merely the last interactive pose. Static fitting at a sampled time and a future dynamic simulation need different cache contracts. This research does not qualify GPU render geometry, motion blur, displacement or renderer-specific procedural APIs.

## When compute-produced vertex buffers make sense

If many downstream draws reuse the same expensive deformation, compute-to-vertex buffers can amortize evaluation. They also allocate full posed output and require supported sharing/import/synchronization. Vertex-shader evaluation avoids that output storage but repeats work for multiple passes. Benchmark one viewport, several viewports, wireframe overlay and shadow passes before deciding. Neither approach eliminates leaf transparency overdraw or texture memory pressure.

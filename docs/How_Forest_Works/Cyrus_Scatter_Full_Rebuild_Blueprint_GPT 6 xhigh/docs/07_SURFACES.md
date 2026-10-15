# 07 — Surface evaluation: XY, UV, projection, normals and attachment

**[FP-DOC]** ForestPack supports XY projection along the scatter's local Z axis and UV-aligned distribution, multiple surfaces, normal direction control, altitude limits/falloff and slope filtering. It caches prepared receiving-surface information across Forest objects and may require manual refresh unless Auto is enabled. [Official reference](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).

## 1. Why surface placement must be a separate engine

Placement generators usually establish **candidate coordinates**; surfaces decide how/where those coordinates occupy 3D geometry. This service is also needed by painting, surface-informed source selection, Effects, collision clearance, object exclusions and manual attachments.

Input: candidate, receiver set, coordinate mode, projection rules, time. Output: position, normal, derivative frame, UV, material ID, face binding, slope, altitude, validity/ambiguity reason.

## 2. Receiver preparation

On host main thread, capture evaluated mesh vertices, triangle indices, face material IDs, mapping channels, transforms, geometry revision and time. Convert to owned immutable arrays. Build BVH/acceleration off-thread from snapshots. Cache prepared geometry by receiver ID and relevant revisions. Keep node bindings in host layer, not compute structures.

Consider:

- Large architectural meshes, sub-objects, instancing, inherited transforms.
- Degenerate/zero-area triangles and invalid normals.
- Open/non-manifold meshes, two-sided surfaces.
- Mirrored transforms reversing winding/normal orientation.
- Multiple UV channels, missing mapping data.
- Skinned/deforming topology, evaluated-time accuracy.
- Nan/Inf geometry and 3ds Max system unit conversions.

## 3. XY projection

**[FP-DOC]** XY mode enumerates positions in the Forest object's local XY plane and projects along its local Z to the receiving surface. The user's visually perceived "vertical" may not match world Z when the scatter is rotated.

### Algorithm

1. Transform candidate `(x,y)` from scatter-local to world, construct a ray along configured scatter-local ±Z.
2. Query receiver BVHs for ray intersections.
3. Apply explicit hit-selection policy (nearest positive hit, highest/lowest, all hits, preferred receiver, surface index priority, etc.).
4. Compute barycentric position/normal, UV coordinates and material ID.
5. Produce canonical `SurfaceBinding` so deformation can re-evaluate.
6. Apply normal-alignment policy, source pivot offset and final transforms downstream.

**[TEST-NEEDED]** Exact Forest behavior for multiple stacked hits, two-sided flags and local projection direction. Do not assume "highest" unless the target test confirms it.

### A subtle density consequence

For a smooth height-field surface, projection of a planar XY process produces approximate density per *actual* surface area `rho_surface = rho_xy * |normal · projectionAxis|`. Thus for a 60° incline, if no compensation is applied, world surface area density is roughly half that of a horizontal patch. This is geometric reasoning, not a claim about ForestPack's internal compensation.

Offer Cyrus modes: `Uniform in projection space` (fast/default compatibility), `Correct for surface-area stretch` (separate algorithm), and `Artist texture controlled`.

## 4. UV placement

UV mode enumerates samples in UV/map space and projects onto mesh faces through mapping coordinates. Inverse UV mapping is not always unique:

- Multiple faces can share the same UV region (stacked islands).
- A seam has discontinuous UV but continuous world geometry.
- Mirrored UV islands invert orientation.
- UV distortion changes world-space area per texture unit.
- Thin/degenerated UV triangles can have zero area even if world geometry is valid.

### Proposed UV sampling algorithm

Build per-face UV triangles and a UV-space BVH/grid. For UV sample `(u,v)`, find triangle candidates containing that coordinate; calculate UV barycentric weights; interpolate world point and normal. Choose among multiple hits using declared `All Islands`, `First`, `Receiver Filter` or `Disambiguate By Face ID` policy. Keep UV island/face in binding.

For uniform **world surface-area** density, weight UV samples by local Jacobian area scale `|dP/du × dP/dv|` or sample triangles directly by world area. These represent different artist controls; do not silently reinterpret existing UV density maps.

**[FP-DOC]** ForestPack 8 enabled Areas on UV surfaces with restrictions; the Paint Area instructions specifically call for XY. Our compatibility matrix should distinguish *general UV areas* from *UV-bound painting* if Cyrus chooses to implement the latter as a new feature.

## 5. Surface orientation frame

Inputs: surface normal `N`, projected up axis `U`, random yaw, generator tangent when applicable. Construct an orthonormal basis robustly:

```text
Z = normalize(BlendDirection(U, N, alignmentWeight))
X = normalize(ProjectOntoPlane(referenceTangent or worldEast, Z))
Y = normalize(cross(Z, X))
```

Handle nearly parallel reference tangents via a fallback axis; store quaternion rather than accumulating Euler rotations. User-facing rotation axes must map to the same convention in viewport and render output.

Forest's `Direction` uses values from −100 (Down) through 0 (normal-aligned) to +100 (Up). Precise interpolation and negative-direction behavior are **[TEST-NEEDED]**; provide a comparable artist-visible slider through a versioned mapping.

## 6. Slope filtering

With world-up vector `U`, triangle normal `N`, slope `theta = acos(clamp(dot(N,U),-1,1))`. For common upward-facing terrain, 0° horizontal and 90° vertical. Decide how double-sided downward faces are treated (use signed angle, absolute dot or reject backfaces). Preserve semantics under rotated receiver/scatter transforms.

Slope range: inclusive/exclusive limits, `max=min` behavior, falloff near limits and units need explicit testing. Evaluate slope after surface resolution, before source/collision in normal pipeline; Effects may read it later.

## 7. Altitude limits and falloff

Use configurable axis and coordinate frame (world altitude vs scatter local Z); the compatibility implementation should follow documented ForestPack behavior. `Bottom/Top` limit candidates; density/scale curves in this range can modify acceptance and dimensions. For multiple overlapping falloffs, defer to area/field composition contract.

## 8. Scale-to-fit-sloped-areas

**[FP-DOC]** ForestPack exposes width adjustment to help compensate XY-mode spacing on slopes, requires normal alignment and is unavailable in UV mode. Details of exact dimension adjustment require reference tests. Independent Cyrus implementation can estimate metric distortion and widen footprints along steep slope direction, but guard near-vertical blow-up with clamps.

Do not market this as automatically changing candidate density unless that behavior is actually implemented.

## 9. Stable surface attachment

`Binding = {receiver UUID, evaluated-time policy, face anchor, barycentric location, optional UV island/coordinate, local offset, attachment revision}`.

- Deformation with identical topology: interpolate stored barycentrics on updated face.
- Topology edit: try correspondence if reliable; otherwise orphan and allow manual rebind.
- Node transform change: update world transform without resampling local position unless rules require.
- UV edit: recompute UV-dependent fields, but world-face-bound manual item can remain attached.
- Receiver deletion: preserve authoring state; show broken reference; never teleport to origin.

## 10. Painting and multiple receivers

A brush ray may hit several floors. Record which receiver the artist intended; provide pick-through, active-receiver filter and surface list selection. For `XY world mask`, strokes may intentionally affect all receivers sharing XY coordinates; for `surface-bound paint`, strokes remain tied to the chosen receiver. Those are **distinct tools** and need distinct user messaging.

## 11. Surface cache invalidation

| Change | Rebuild |
|---|---|
| Material property/tint | Usually shading only |
| Object transform | World-space transform and derived indexes if not transformable cheaply |
| Vertex deformation, same topology | Update vertex positions, BVH refit if safe, normal/slope dependent fields |
| Topology edit | Rebuild BVH, face anchors, mapping correspondence |
| UV channel change | UV mapper and UV-based generator/field results |
| Time change | Evaluated receiver snapshot if animated |
| Source-only edit | Do not invalidate receiver geometry |

Every shortcut must be tested against full rebuild.

## 12. Required edge-case tests

Flat plane; extremely steep slope; rotated scatter; two stacked balconies; thin overhang; UV seam; overlapping UV islands; missing UV channel; mirrored transform; negative world coordinates; deforming terrain; material-ID filter; exact ray edge; two receivers with different transforms; large world origin. Render a diagnostic normal/UV/face-ID view to visualize the sampler.

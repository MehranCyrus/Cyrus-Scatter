# 05 — Surfaces, coordinates, projection, and geometric queries

**Status: proposed Cyrus implementation. Research basis: R0 §§3.4–3.5, 8.7.**

## 1. Separate receiving geometry from coverage

A receiver answers where a placement lands and what the surface is like. An include area answers where placements are requested. Assigning a receiver must not implicitly fill it unless `Use receiver as include region` is enabled.

ForestPack documents both XY projection and UV placement, along with slope/altitude controls and shared prepared terrain information [S03]. The numerical policies below are Cyrus decisions.

## 2. Required receiver snapshot

```text
ReceiverSnapshot
    persistent receiver UUID
    evaluated-stack fingerprint
    topology / position / transform / UV / face-attribute revisions
    local positions, triangle indices, face provenance
    object-to-world and world-to-object transforms
    geometric and optional shading normals
    requested mapping channels
    face material IDs / custom face attributes
    time and validity interval
    connected-component information
```

Reject degenerate triangles from geometric queries while preserving a provenance map for diagnostics. Do not assume Max polygon indices equal triangulated face indices. Record the mapping.

A BVH can be built in object space and reused after rigid transforms. Ray conversion must preserve comparable world-space hit distances, especially with nonuniform scale; do not compare unrelated normalized local ray parameters across receivers.

## 3. Projection frame

Define an orthonormal frame `(origin, U, V, W)`. A projected candidate has planar coordinates `(u,v)` and ray `origin + uU + vV + tW`. “XY” means the selected frame's U/V plane, not always world X/Y.

Save the frame binding: world-fixed, setup-local, or receiver-local. Rotating the setup should have a predictable result because the frame choice is explicit.

The ray interval is finite and configured from receiver bounds plus a margin. A missing hit produces `NoReceiverHit`; it does not silently place an object at Z=0 unless an explicitly selected planar-fallback mode permits that.

## 4. Multiple hits and stacked receivers

Support named policies:

| Policy | Result |
|---|---|
| Nearest front hit | One hit from the ray origin within allowed receivers |
| Highest along frame W | Topmost eligible surface in the projection interval |
| Selected receiver only | Ignore other receiver objects |
| All receiver hits | Expand a planar candidate into independently identified bound candidates |
| Explicit surface sheet | Restrict hits to a saved sheet/component where the topology supports it |

Sort equal-distance hits with a stable receiver/face tie-break. The paint brush defaults to the frontmost selected receiver under the cursor; a population's `All hits` option must not implicitly make the brush paint every floor.

For a single folded mesh, object identity alone cannot distinguish two projected sheets. Use surface-attached paint or an explicit sheet restriction. A UV island is not automatically a surface sheet.

## 5. Surface bindings

A binding contains receiver identity, evaluated topology fingerprint, triangle identity, and barycentric coordinates. For unchanged topology, position can be reconstructed from current triangle vertices:

```text
p = b0*v0 + b1*v1 + b2*v2, where b0+b1+b2 = 1
```

A rigid transform updates world position without changing the binding. Vertex deformation updates the reconstructed position. Topology changes invalidate the triangle address unless the host supplies a proven correspondence.

Rebinding is an explicit operation with search distance, normal-angle tolerance, receiver restrictions, and a report. Preserve before/after information for Undo. “Closest point anywhere” is not an acceptable silent repair on stacked balconies.

## 6. Projection density versus surface density

A uniform projected pattern is uniform per projected area. On a simple sloped surface its density per actual surface area is multiplied by `abs(dot(normal,W))`. It becomes sparse near vertical surfaces.

Provide separate, honestly named sampling modes:

**Projected density:** retain the image/pattern layout in the projection plane.

**UV density:** uniform in the chosen UV domain, not necessarily in square meters.

**World-area density:** sample surface area directly, with optional texture masks.

Do not compensate by arbitrarily enlarging objects and claim that population density is now surface-uniform. Footprint fitting and sampling density solve different problems.

## 7. Uniform world-area sampling

For a fixed receiver topology, compute each triangle's world-space area. Allocate candidates using an area-weighted selector and sample a triangle uniformly using two independent values:

```text
s = sqrt(u)
b0 = 1-s
b1 = s*(1-v)
b2 = s*v
```

A straightforward alias/CDF triangle selector is suitable for static fixtures. However, deforming areas can change which triangle a sample selects. An identity-stable deforming implementation needs per-triangle sampling addresses and explicit capacity/probability policies rather than a global selector that silently reassigns every sample.

For count mode, specify whether the requested count is before gates or a target after filtering. The default is **candidate count**. Filling exactly N accepted items under collisions is a different bounded search problem and must report failure when the requested packing is impossible.

## 8. UV mode

A UV triangle defines a mapping from UV coordinates to geometric barycentric coordinates. Build a UV-space acceleration structure for each requested channel. Reject zero-area UV triangles or handle them through an explicit fallback.

Overlapping UV triangles produce multiple valid receivers of the same UV coordinate. Provide `All mapped faces` or a documented priority selection. Include geometric face/receiver identity in resulting IDs. Never drop overlaps accidentally because a map lookup returns only the first face.

Mirrored islands affect tangent orientation and handedness. Seams duplicate UV vertices but need not split physical adjacency. Keep UV adjacency and geometric adjacency as separate structures.

For world-area density under a UV texture, sample in world area and evaluate the texture through the hit UV. This is often simpler and more stable than attempting to repair arbitrary UV sampling using a Jacobian, although it is not the same image-grid distribution.

## 9. Normals and alignment

Distinguish geometric face normals used for slope eligibility from interpolated shading normals used for optional smooth orientation. An artist should not change cliff eligibility merely by editing shading normals unless they explicitly choose that behavior.

Default instance up is the selected world/setup up axis. A normal-alignment slider blends toward the receiver normal through a stable quaternion construction. If exposing a Forest-like `-100 Down / 0 Normal / +100 Up` mapping, define the mapping in a compatibility profile; do not assume a simple linear normal interpolation reproduces it.

At opposite vectors, choose a deterministic fallback rotation axis. Normalize after interpolation. Build tangent frames with a stable reference axis and avoid abrupt flips near singular alignments.

## 10. Slope and altitude

Calculate slope using:

```text
theta = acos(clamp(dot(unitGeometricNormal, referenceUp), -1, 1))
```

The default supported range is 0–180 degrees; a UI preset can restrict to upward-facing 0–90. Backface handling is separate from slope. Altitude is the signed projection onto the saved reference axis from the chosen origin.

Ranges use inclusive endpoints. An inverted range is rejected at command validation. Falloff ramps have zero-width behavior defined as a hard gate rather than division by zero.

Altitude scale, density, and source-choice changes are separate channels. Sampling an altitude mask must not overwrite the original height attribute that other Effects read.

## 11. Scale-to-fit slopes

Treat slope footprint fitting as a special transform policy, not a hidden correction. A candidate implementation stretches the source along the downslope tangent by a bounded factor derived from the projection. Near vertical angles the theoretical factor can diverge; clamp at a saved maximum and report excessive fitting.

This is an approximation suitable for some ground-cover patches, not tall trees and not a guarantee of perfect contact. Source-local footprint shape, normal alignment, and nonuniform scaling must participate in subsequent collision and boundary calculations.

## 12. Queries exposed to other modules

```text
ProjectRay / ClosestPoint
EvaluateBinding
SampleUV / SampleFaceAttribute
DistanceToSurface
FindConnectedComponent
QueryTrianglesInBounds
SurfaceFrameAtBinding
```

Every query declares coordinate frames, error tolerance, hit policy, and snapshot lifetime. Results never contain a live Max mesh pointer.

Effects can request a fresh hit after moving a point. This is explicit: moving a placement laterally does not imply the original binding is still correct.

## 13. Invalidation policy

| Receiver change | Reuse | Rebuild/revalidate |
|---|---|---|
| Rigid transform | Object-space topology and BVH | World bounds, placements, world-dependent fields |
| Vertex deformation | Topology correspondence | BVH refit/rebuild, positions, normals, world-area measures |
| Topology | Source UUID only | Bindings, adjacency, BVH, per-face fields |
| UV edits | Geometry/BVH | UV acceleration and dependent map samples |
| Material IDs | Positions/projection | Face filters, element-related attributes |
| Shading normals | Geometric slope if configured | Smooth alignment and shading outputs |

BVH refit is an optimization with a quality threshold. If traversal cost becomes poor after large deformation, rebuild. The choice must not change query semantics.

## 14. Verification fixtures

Use a plane, 60-degree ramp, vertical wall, sphere with UV seam, overlapping UV islands, stacked slabs, one folded mesh, nonuniformly scaled receiver, mirrored receiver, and a topology-changing modifier. Measure density by the declared coordinate domain.

Test brush hits against the exact evaluated stack snapshot. Autodesk's Painter callback documentation warns that face/barycentric data may refer to a different evaluated mesh than a modifier's local input [S21]. The adapter must resolve that mismatch before storing a binding.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S03]: https://docs.itoosoft.com/forestpack/forest-plugin/surfaces
[S21]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html

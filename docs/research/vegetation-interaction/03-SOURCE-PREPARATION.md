# 03 Source preparation

**Status: proposed asset contract and audit method, with scoped offline representation evidence.** R08 supplies the earlier preparation study; R11 adds a concrete framed-guide mapping, two public assets and supplied arithmetic/topology results. No production asset library, automatic preparation system or Max delivery was qualified. See the [R11 evidence review](references/R11-evidence-review.json).

## Choose the representation deliberately

| Tier | Suitable use | Preparation and limitation |
| --- | --- | --- |
| A: whole-clump guide/cage | Broad deflection for middle or distant views | Few controls; cannot guarantee independent blade paths around a stone |
| B: blade/card guides or ribbons | Close grass, narrow gaps and multiple obstacles | Explicit membership, roots and frames; strongest initial product candidate for prepared assets |
| C: authored advanced driver | Branches, wide leaves, complex scans and existing rigs | Specialized cage, skeleton or surface binding; separate qualification |

The first source should be intentionally prepared. Automatic discovery can be investigated after an audit identifies which geometry families actually dominate the intended library.

## Preparation record

Store one immutable record per compatible source revision, with the following information:

- Source identity, geometry/topology signature, reference pose, units and local coordinate system.
- Component/blade membership, declared root positions or patches, root tangents and width/frame directions.
- Ordered rest guides or driver surface, rest lengths, sample spacing and a declared frame convention.
- Mesh-to-driver correspondence, weights or local coordinates, unbound vertices and cross-piece restrictions.
- Collision envelope policy, supported scale/transform range and any protected attachment region.
- UV/map channels, material IDs, smoothing and explicit-normal policy, plus preparation version and diagnostics.
- Separate render-corner, logical-position and semantic-part identities; verified duplicate correspondence and sidedness classification.
- Fixed rest binding coordinates, complete residual offsets, rest directors and any unwrapped twist; shared-base and parent/child attachment policies.

This is a proposed data contract, not a new serialized schema. Existing recipe and scene formats require a separate design decision before extension.

## Automatic preparation limits

Disconnected mesh components can be useful candidates for separate blades. A connected component is not necessarily a botanical blade: joined roots, welded cards, branching stems and scans can violate that assumption. Conversely, UV seams or split shading normals can divide vertex indices without dividing the physical surface.

An optional virtual weld must use explicit tolerances, preserve analysis provenance and show ambiguous merges. A root-cut analysis graph may help separate joined blades while leaving the original mesh intact. Neither method should destructively detach or rewrite the artist's source.

R11 makes the distinction concrete. An independent recount of the assets embedded in its evidence archive matched these results:

| Public source | OBJ position vertices / components | Expanded vertices / components | Triangles |
| --- | --- | --- | --- |
| Kenney grass | 84 / 9 | 264 / 66 | 132 |
| Kenney grass_leafs | 30 / 6 | 84 / 24 | 36 |

Expansion here uses each distinct position/UV/normal index tuple; the supplied GLB counts agree. None of these component counts establishes botanical blade identity. Both GLBs are opaque materials, so these are not tests of alpha-masked foliage. The recount inspected archive data without running its bundled scripts; provenance and exact scope are recorded in the review receipt.

Each OBJ triangle also has an opposite-winding mate using the same position IDs. Such explicit two-sided construction can inflate raw face-incidence counts. A reversible analysis-only representative can simplify that graph while preserving every original render face and channel. Do not classify the source as corrupt, or delete its back faces, merely from a raw nonmanifold-edge count. Deliberately independent coincident blades must remain separate logical positions.

A shared vertex has one output position. Two independent blade drivers cannot assign it incompatible motion. Choose an explicit common base, pinned transition, reviewed blend or a separately authorized topology change. For attached leaves, evaluate the attachment in the parent's current frame; a child attachment is not a pin to its old world position.

Simple ribbons can support a root-to-tip traversal if width, branching and ordering checks pass. A height threshold is acceptable for a controlled upright fixture, not a general terrain or curved-source root finder. Show suggested roots and frames before treating them as accepted preparation.

Opacity cards contain geometry and a shading silhouette. One textured card showing several grass blades can bend as a card; it does not provide independent geometry for every pictured blade. Alpha-pixel collision and reconstruction are outside the first scope.

Opaque renderer proxies require a verified path to full canonical geometry and attributes. A coarse preview representation is insufficient for a source contract or final contact validation.

## Frames and mesh decoding

A centerline supplies position and tangent. It needs a cross-section direction to determine ribbon orientation. Two fixed collinear root samples constrain a tangent but leave axial roll free. A noncollinear base patch can define a geometric frame. For a soft base, the root position can remain fixed while a separate angular constraint permits bending.

Use one explicitly tested decoder first. A framed single-guide mapping or a small ribbon driver is easier to verify than a universal skin/cage abstraction. Interpolation must not blend nearby independent blades merely because their vertices are close.

For vendor comparisons, SideFX warns that ordinary Point Deform is unsuitable for wire models; a piece attribute does not remove that limitation. A curve-aware framed decoder or an actual surface/volume cage needs its own correspondence checks. [Point Deform](https://www.sidefx.com/docs/houdini/nodes/sop/pointdeform.html), [Wire Deform](https://www.sidefx.com/docs/houdini/nodes/sop/wiredeform.html).

Dual-quaternion skinning can be a useful option, but a fixed four-influence DQ design is not established as the right universal decoder. Matching an imported Max Skin result also requires its deformation mode and per-vertex DQ blend behavior, not only bone weights. [ISkinContextData](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_skin_context_data.html).

## Framed-offset reference candidate from R11

R11 proposes a specific mapping for already prepared bindings. For each logical vertex, store a fixed rest-guide coordinate, nonnegative normalized influence weights and the complete offset in the rest material frame. Retain the longitudinal offset as well as width/thickness. At evaluation, move that offset by the accepted guide center and frame, blend the influences, then apply the placement transform once.

The proposed mapping can be written as:

- `d_ik = transpose(R0_k(s_ik)) * (p0_i - C0_k(s_ik))`
- `q_i = sum_k w_ik * (C_k(s_ik) + R_k(s_ik) * d_ik)`
- `p_i = a_i * p0_i + (1 - a_i) * q_i`

Here p0 is the rest position, C/R are guide centers/frames, s is a fixed rest coordinate, w is an influence weight and a is a mesh-patch hold mask. Guide-root orientation is an upstream constraint. A hard patch hold is not a tunable angular spring, and a soft hold blend can shrink geometry.

Use the same sampler at capture and evaluation; do not reproject vertices to newly nearest guide points after bending. R11's example separates shortest-path director interpolation from unwrapped twist so complete turns are retained. It consumes authored frames: it does not build or validate a physical rod frame, guarantee alignment with the interpolated centerline tangent, or solve contact.

Rest-to-rest reconstruction is a preparation gate. Single-guide, equal-coordinate cross-sections preserve width only under the stated proper-frame and zero-hold conditions. Multiple influences can collapse width; R11 includes an intentional counterexample. Representative stress poses must detect these failures. Imported Skin/cage behavior must pass conversion/pose comparisons before this mapping can replace it. This remains a reference candidate, not a selected universal production evaluator.

For a CPU rod comparator, R13 adds a separate solver-index contract. Rod-property calculation can reverse endpoints and optimization can reorder constraints. Keep semantic guide/segment identities mapped through those changes. Engine-generated transported frames do not recover authored blade width or twist. Build fresh rest settings, derive the ordinary properties, then apply any validated material-frame overrides and recompute consistent relative rest rotations. Prefilling a frame alone can skip derived work; inspect the exact implementation and prove rest reconstruction. [Rod data and remaps](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/SoftBody/SoftBodySharedSettings.h).

## Appearance and geometry parity

Verify that decoding preserves vertex/face association, UV seams, mapping channels, material IDs and intentionally edited foliage normals. Recomputing geometric normals can change the appearance of an asset with authored normals. Rotating every source normal by a guide frame is also not universally equivalent to the normal of a blended deformation. Choose and test the policy with the actual materials and lighting.

R11 distinguishes geometric-normal reconstruction from an explicitly artistic transport of authored corner normals. A weighted rotation blend is not the exact inverse-transpose deformation Jacobian. Preserve corner splits, diagnose near-zero blended normals, rebuild tangents under a declared convention and qualify the result through the actual renderer and Bake path. Its supplied tests cover geometric placement-normal arithmetic, not general authored-normal preservation.

Nonuniform scale, mirroring and shear need an explicit rule. A circular local envelope may become elliptical in world space, and normals require the appropriate transform. The first prototype may reject unsupported transforms with a clear diagnosis; it must not silently assume uniform positive scale.

## Invalidation and asset audit

Rebuild preparation when source topology, reference pose, root metadata, membership, guide construction or binding semantics change. UV/material edits can remain appearance-only only if those channels were not used to discover roots, membership, stiffness or other geometry behavior.

A surviving placement ID is insufficient for fit reuse. Its full transform, source revision, preparation revision, relevant obstacles, fit settings and evaluation-time policy must still be compatible. Density, quota, Relax and acceptance changes may alter surviving placement inputs under the current foundation.

Use the [asset audit template](checklists/ASSET-AUDIT.md) on a representative set: clean ribbons, disconnected blades, joined-base clumps, precurved blades, opacity cards, broad leaves, scans and proxy sources. Record manual preparation time and rejection causes. Do not turn an untested “usually automatic” claim into an asset support promise.

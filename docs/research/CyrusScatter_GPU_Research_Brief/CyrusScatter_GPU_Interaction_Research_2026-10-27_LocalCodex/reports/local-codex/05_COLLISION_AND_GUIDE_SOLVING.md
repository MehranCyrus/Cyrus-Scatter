# Collision, rooted guides, and surface correctness

**Status: P — proposed GPU algorithms. Existing CPU behavior remains the reference. No GPU contact fitter was implemented for this report.**

## Separate three problems

1. **Relevance:** which plants/guides can this edit affect?
2. **Feasible fitting:** can those rooted guide chains move clear of the relevant solids within the permitted shape change?
3. **Visible geometry:** do all delivered leaves, stems and fixed parts actually clear those solids?

A fast centerline solver answers only part of the second problem. A leaf can be much wider than its stem, and a triangle can cross a stone while its three vertices are outside. GPU throughput does not remove either geometric issue.

## Broad phase: preserve local work

Keep immutable source bounds/acceleration structures and a revisioned instance-level index. Query the union of previous and new collider influence regions, expanded by source reach, contact gap and the independently relevant hide distance. Include edited transforms that have left their published bounds. Sort/deduplicate by stable IDs. For a teleport, old/new endpoint neighborhoods restore and recompute the final static result; sweeping the entire intervening path would be necessary only for explicitly continuous dynamics.

Use a two-level structure: instance bounds first, source-local collider geometry second. Transform queries to the collider's local coordinates rather than duplicating every triangle at every placement. Start with the existing CPU BVHs. GPU grids or LBVHs become candidates only when pair generation is measured to dominate. Mixed tiny grasses and huge buildings make one fixed grid cell size risky. [Karras, broad-phase workload discussion](https://developer.nvidia.com/blog/thinking-parallel-part-i-collision-detection-gpu/).

Compute clearance in one coordinate system once. With positive uniform scale `s`, world metre distances convert to source distances by division by `s`. Do not expand a proxy, enlarge the guide radius, and add the same Contact gap again in the solver.

## Collision representations

| Shape | Good use | Accuracy caveat |
|---|---|---|
| Sphere/capsule/tapered trunk segments | Fast test fixtures and smooth trunk proxies | Does not reproduce exposed roots, forks or concavities |
| Oriented box / convex hull | Buildings, walls, simple rock approximations | One hull fills concave gaps and may overbend vegetation |
| Compound convex/segment proxy | Root flares, branching trunks, complex bases | Needs authoring/error controls and overlap-aware queries |
| Closed triangle mesh + BVH | Detailed stones, architectural boundaries | Sign/classification, slivers, traversal and edge witnesses are more complex |
| Source-local SDF | Many repeated queries against static geometry | Voxel error, thin features, narrow bands and sign validity must be explicit |
| Coarse SDF + exact mesh refinement | Fast candidate fitting with authoritative final check | Two representations need aligned transforms/revisions and bounded refinement |

A render tree containing disconnected leaf cards is often unsuitable as a solid collider. Keep the full visible tree while preparing a separate trunk/root proxy. For the Tea Tree models with radial exposed roots, one cylinder cannot fit the actual footprint. A manually authored closed proxy, a compound trunk/root proxy, or a qualified mesh/SDF representation is needed. Decimation alone does not make an open foliage mesh into a valid solid.

## Segment and surface queries

For an analytic sphere, the closest point of a guide span `a + u(b-a)` to center `c` uses `u = clamp(dot(c-a,b-a)/|b-a|²,0,1)`. Its distance minus sphere radius and guide radius gives a capsule clearance witness. This is a useful independent control because endpoint-only sampling misses crossings. Degenerate spans require a point fallback with an explicit tolerance.

For general solids, use qualified segment/capsule distance or intersection queries and a reliable outward normal. The minimum signed distance sampled at a few nodes is not the exact minimum along a span. Contact data should identify material parameter, witness, normal, signed gap, obstacle ID/revision and completeness. Refresh contacts after finite guide updates; stale contacts can point at a surface the guide has already passed.

Closed-mesh classification must distinguish outside, inside, boundary and ambiguous/invalid input. Near edges or thin shells, parity rays and nearest-face normals can disagree. Do not convert ambiguous status to “outside” to make a frame succeed. Use independent controls and explicit failed-successor behavior.

## A bounded static fitting objective

One proposed model uses node positions `x` and material frames `q` to minimize rest-shape change subject to:

```text
root/anchor:       x_anchor = authored position
stretch:           |x_i+1 - x_i| approximates rest length, within a declared tolerance
shape/bend:        curvature/frame deviation weighted by an explicit stiffness model
contact:           distance(guide capsule, collider) >= Contact gap
attachment:        child root/foliage follows parent at its material parameter
```

This is not a claim that the current fitter minimizes one global energy, nor that the constraints are always feasible. A stone through an immovable planted root can make root preservation and complete surface separation incompatible. More iterations cannot solve an infeasible configuration. Report this and retain the prior complete result, or use the artist's explicit hide-root rule; never silently delete a failed stem.

Parallel fitting can use independent root groups and parent-depth levels. Within a chain, compare sequential projection with colored constraints or Jacobi iterations. Record residuals, anchor drift, edge change and surface penetration after each candidate, rather than treating a fixed iteration count as convergence.

XPBD introduces compliance into position-based constraint updates; its stiffness behavior is less dependent on iteration/time-step choices than basic PBD. That does not imply finite-iteration convergence or equivalence to a quasistatic rest-pose fit. [Macklin, Müller and Chentanez, XPBD, 2016](https://matthias-research.github.io/pages/publications/XPBD.pdf).

For a time-step formulation, a scalar update has the familiar form `Δλ = (-C - α̃λ)/(Σ w_i |∇C_i|² + α̃)`, with `α̃ = α/Δt²`. Its compliance units depend on the constraint; an arbitrary static “stiffness” slider must not be relabeled as physical compliance without a model and unit mapping. A static fitting prototype should document how its iteration schedule, regularizer and warm start affect the final result.

## Frames, hierarchy and attachments

The current CPU implementation uses rest/posed material frames and shortest-path interpolation. A GPU port must preserve quaternion hemisphere handling, normalization, antiparallel tangents, degenerate edges, root smoothing and attachment semantics. A child attached midway along a parent needs the parent's transform at that material position, not the parent tip transform.

Rod literature provides useful frame/twist models, but these are larger changes than parallelizing existing arithmetic. [Discrete Elastic Rods](https://www.cs.columbia.edu/cg/rods/index.html) and [Position and Orientation Based Cosserat Rods](https://vci.rwth-aachen.de/publication/0550/) are appropriate references for a later physical model. Keep that work separate from first achieving CPU/GPU deformation parity.

## SDF error must be a contract

A sampled distance field needs its resolution, reconstruction method, sign convention, narrow-band extent and measured error recorded per source. A cell diagonal is a geometric scale, not an automatic proof of total field error. Voxelization, interpolation, thin geometry and invalid sign can add more error. Measure against exact mesh queries; classify uncertain near-surface regions for exact refinement.

Use collider-local fields so moved/rotated/uniformly scaled instances share one field. Rebuilding a world-volume SDF on every drag would discard this benefit. Sample gradients carefully near zero gradients/cell boundaries. A narrow-band miss is unknown, not a valid large positive distance. Fall back or reject outside the admitted band.

## Leaves and final validation

After fitting guides, validate broad leaves and attached geometry. A proposed hierarchy is: conservative leaf bounds → swept segment/triangle candidates → vertex/edge/triangle distance checks → bounded guide/frame adjustment → full validation for final publication. The exact ordering must be profiled; checking every triangle against every obstacle is unnecessary.

Use a validator independent of the accelerated approximation. A GPU SDF fitter validated only by the same sampled field can miss the same feature twice. Validate exact analytic fixtures and qualified closed-mesh cases on the CPU, with declared linear/angular tolerances. Compare visible topology, UV/material mapping and root-group masks as well as positions.

## Hiding is an independent operation

**Contact gap** changes bending clearance. **Hide margin** expands root-group exclusion, in either Inside solid or explicit Under collider mode. A hidden group includes its assigned attachments; it is not random triangle thinning and is not an error-recovery mechanism. Fixed trunk/pot geometry and independent leaf groups require explicit ownership.

Future wind uses time, velocities and reset/cache policy. The Small Steps paper is relevant to dynamic integration, but its substep results do not prove a benefit for static contact fitting or permit skipping collision refresh when an obstacle moves significantly. [Small Steps in Physics Simulation, 2019](https://matthias-research.github.io/pages/publications/smallsteps.pdf).

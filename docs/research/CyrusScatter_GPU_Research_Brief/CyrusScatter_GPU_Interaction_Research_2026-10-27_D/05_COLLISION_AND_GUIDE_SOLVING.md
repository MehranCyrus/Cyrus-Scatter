<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 05 — Collision and guide solving

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Required semantics

The initial product is a **quasistatic one-way fit**. For every edited request, the plant seeks a valid successor pose against fixed collider snapshots. It does not integrate velocity or promise swept continuous collision detection between pointer samples.

**[R]** Keep a focused static fitter as the CPU reference. GPU acceleration should reproduce its constraints and independent visible validator before introducing time-dependent rod simulation.

## Collision representation comparison

| Representation | Concavity / thin features | Build/update | Query fit | Best use | Main failure |
|---|---|---|---|---|---|
| sphere/capsule/box | no concavity; explicit thickness | trivial; transform-only | analytic distance/gradient/cast | simple stones, stems, temporary proxy tier | poor shape fidelity |
| convex hull | one convex region | moderate cook; transform reuse | stable support/GJK or plane tests | ordinary rocks and proxy pieces | fills cavities |
| compound convex hulls | approximates concavity | higher cook; child BVH | good reusable obstacle proxy | production interactive proxy | authoring/cook quality and child count |
| triangle-mesh BVH | exact surface topology; open/one-sided semantics explicit | expensive build, cheap transform reuse/refit for deforming mesh | closest point, segment/triangle, occupancy for closed solids | final exact static collision | inside ambiguity for open/malformed meshes; branch divergence |
| dense SDF | concavity and smooth gradient at voxel resolution | expensive volume build | coherent point/segment sampling | repeated dense GPU queries | memory and thin-feature loss |
| sparse/narrow-band SDF | same within band | more complex build/cache | local repeated queries | high-reuse obstacles | outside-band/inside policy and sparse traversal cost |

### Instance-space reuse

Store one collider asset shape/BVH/field per geometry revision. Each collider instance contributes a transform and material/semantic flags. Transform guide queries into collider local space when the admitted transform is positive uniform scale; apply clearance once in physical metres. Do not rebuild a mesh BVH for every instance move.

## Broad phase and invalidation

1. Query both previous and current edited collider bounds.
2. Expand plant bounds by guide reach plus the maximum visible envelope and influence setting.
3. Use ground-plane-aware cells or a BVH split policy that is not destroyed by the artificial vertical extent of Under-collider footprints.
4. Compact unique stable plant IDs.
5. On collider deletion or Undo, the old neighborhood is still queried so retained deformations can be removed.
6. Geometry revision changes rebuild/refit the collider asset; transform-only changes update instance records.

A persistent GPU broad phase is a later option only if CPU neighborhood search is measured material. Uploading/rebuilding all `N` bounds on every drag is rejected.

## Contact types

### Vertex-only contact is insufficient

A segment can cross a sphere, box edge or triangle while both endpoints remain outside. Broad leaves/cards can intersect even when the center guide is clear. Therefore:

- use segment/capsule-to-obstacle tests for guide spans;
- include a source-authored or inferred envelope radius/half-width;
- use visible triangle validation for final quality;
- test containment separately because a wholly contained visible triangle can have no surface intersection edge.

### Segment/capsule contact

For span endpoints `a,b`, radius `r`, and obstacle signed/closest distance `d(x)`, a practical constraint is:

```text
c = min_{u∈[0,1]} d(a + u(b-a)) - (r + contact_gap) ≥ 0
```

The minimizer must include interior span points, not only endpoints. Analytic shapes have closed-form or robust closest-segment routines; triangle meshes use BVH candidates and segment/triangle or capsule/triangle distance.

### Visible envelope

The collision radius for a guide is a certificate for bound geometry only if preprocessing proves every bound render point lies within that envelope in rest space and the evaluator preserves it under pose interpolation. A too-small envelope is invalid input, not proof that conservative guide collision failed.

## Exact mesh versus SDF

### Mesh/BVH

**Advantages:** exact triangle surface, no voxel resolution, source feature IDs, precise final witnesses.  
**Costs:** irregular traversal, difficult signed classification, expensive broad leaves and many contacts.

For closed oriented manifolds, inside/outside can use winding/solid-angle or robust ray parity plus degeneracy handling. Open geometry must not silently produce a solid sign. Treat it as a two-sided surface or require an authored proxy.

### SDF

For voxel spacing `h`, trilinear interpolation cannot resolve features significantly thinner than the grid and its gradient is an approximation. A conservative interactive field must use an offset accounting for field error, interpolation and envelope thickness. Record the field resolution and approximation status.

**[R]** Use SDF only as an explicit interactive approximation after comparing against exact BVH fixtures. Final Update/refinement rechecks the visible mesh against exact geometry.

## Root and hierarchy constraints

### Position anchor

For a fixed root node `x0*`:

```text
C_root_position(x0) = x0 - x0* = 0
```

Do not relax this to solve penetration unless the artist selected a different root policy.

### Orientation anchor

Position-only anchoring allows the first span to rotate. Clamp-frame anchoring fixes root frame. A soft frame applies a weighted angular/rest objective. These are independent controls.

### Length and rest shape

For span `i` with rest length `L_i`:

```text
C_length = ||x_{i+1} - x_i|| - L_i
```

A curvature/rest-frame objective penalizes change from adjacent rest tangents or relative quaternions. For branch guides, child sockets are evaluated from the parent frame and must remain continuous.

## Solver families

| Method | Static task fit | Benefits | Costs / semantic risk | Decision |
|---|---|---|---|---|
| analytic/root-weighted bend | good for simple one-sided contacts | very cheap, deterministic | corners/multiple obstacles/length error | keep as quality-0 control and fallback |
| iterative projection + smoothing | moderate | simple and local | shrink/stretch/order sensitivity | only with explicit length/rest constraints |
| constrained quasistatic optimization | strong | matches current semantics directly | nonlinear contacts and convergence handling | **recommended reference** |
| PBD | strong | robust geometric constraints | stiffness depends on iterations/timestep unless formulated carefully | useful implementation family |
| XPBD **[S33]** | strong | compliance parameter reduces timestep/iteration dependency | still iterative and not automatic exactness | candidate when compliant bending is needed |
| discrete elastic/Cosserat rod **[S34–S35, S38, S41]** | strong for bend/twist/frame | physical frame and rest twist | more state/math; collision still custom | comparison prototype, future Animate path |
| projective dynamics **[S36]** | good for many quadratic constraints | global/local structure | contact/nonlinear constraints and system solve complexity | not first implementation |
| dynamic hair/cloth | future motion | velocity/inertia/wind | history, timestep, seeking, reset, motion blur | explicitly deferred |

## Focused static fitter proposal

For each active guide:

1. initialize from rest or a warm pose only if request ancestry/revisions match;
2. enforce root position and root frame policy;
3. generate all relevant span/envelope contacts against all admitted colliders;
4. iterate length, rest-curvature/frame, socket and nonpenetration constraints;
5. cap bend/strain and reject nonfinite/degenerate states;
6. regenerate contacts if the guide moves outside the prior local candidate set;
7. evaluate visible bound geometry;
8. run independent exact triangle clearance validation;
9. publish only if the requested quality is achieved.

Pseudo-code:

```cpp
for plant in stable_active_plants:
    pose = rest_or_valid_warm_start(plant)
    for guide in parent_depth_order(plant):
        for iter in 0..max_iterations:
            contacts = whole_span_contacts(guide, colliders, envelope, gap)
            project_root_and_socket_constraints(guide)
            project_length_constraints(guide)
            project_rest_bend_twist_constraints(guide)
            project_contacts(guide, contacts)
            if converged(guide): break
        if invalid_or_overstrain(guide): fail(plant)
    mesh = evaluate_visible_geometry(source, pose, hidden_groups)
    if !independent_visible_clearance(mesh, colliders): fail(plant)
    stage_complete(plant, pose, diagnostics)
```

## Multiple colliders and infeasibility

A plant between two obstacles may have no valid shape within stretch/bend/root limits. Detect:

- fixed root inside required clearance and not selected for hiding;
- gap narrower than two envelopes plus requested clearance;
- iteration limit with residual penetration;
- length/strain above the source limit;
- frame inversion or visible geometry self/fold failure;
- memory/contact admission exceeded.

Behavior:

- preserve the prior complete result;
- report the plant/guide/collider and exact or conservative witness;
- never drift the root, arbitrarily hide a blade, or publish a partial pose;
- allow explicit artist choices: larger hide region, smaller gap, softer/max bend, different proxy, or source preparation.

## Initial penetration

- Analytic/closed-solid obstacles can provide a depenetration direction if the fixed root is not the conflicting point.
- A root inside required clearance is infeasible unless hidden/excluded by declared policy.
- An entire blade or triangle inside a solid needs containment classification; surface intersection alone misses it.
- Open meshes do not provide reliable inside volume and require a surface-only policy or authored closed proxy.

## Fast drag and temporal coherence

Endpoint quasistatic fitting is not continuous collision detection. For the intended static semantics:

- coalesce input events;
- solve the newest snapshot;
- use old/new neighborhoods to restore and discover candidates;
- optionally warm-start only from a compatible prior request;
- avoid publishing intermediate stale poses.

Swept collider/guide queries are required only if product semantics demand no transient tunneling during displayed intermediate motion. That is a separate acceptance criterion.

## Quality metrics

| Metric | Exact / approximate | Use |
|---|---|---|
| root position/orientation error | exact numerical invariant | hard pass/fail |
| span length strain | exact from pose | hard limit and report worst |
| rest curvature/frame deviation | numerical objective | quality/visual limit |
| guide envelope clearance | conservative certificate if preparation valid | fast contact gate |
| triangle-to-obstacle distance | exact for analytic/triangle routines within tolerance | final visible validation |
| SDF penetration | approximate, resolution-dependent | interactive diagnostics only |
| convergence residual | exact solver residual under declared constraints | completed ≠ achieved quality distinction |

## What a GPU solver must reproduce

- all root modes and branch sockets;
- all colliders, not only nearest center;
- whole-span and visible-envelope contact;
- independent final visible validation;
- exact application of Contact gap and separate Hide margin;
- stable diagnostic IDs;
- cancellation/staleness checks at request boundaries;
- failure retention.

A GPU implementation that clears centerlines but misses visible triangles is rejected regardless of speed.

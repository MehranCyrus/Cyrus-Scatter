# 05 — Collision and guide solving

[Index](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Source ledger](17_SOURCE_LEDGER.md)

**Researcher A • 27 October 2026.** Public documentation/source statements below are **verified public evidence [V]**. Product behavior is **provided project context [P]**. Equations, algorithms, thresholds and architecture choices explicitly introduced here are **proposals [D]** or **analytical deductions [E]**, not executed solver results. No collision implementation, GPU kernel, Max plugin or benchmark was executed for this chapter.

## Decision

**[D] Preserve the current bounded static-fitting problem and move only measured bottlenecks.** Start with shared collider assets, CPU neighborhood discovery, immutable rest data and sparse fitted-guide output. If a GPU solver is justified, first implement a small analytic-collider, whole-span contact workload with complete final checks. Add closed triangle meshes only after the analytic fixtures pass. Treat SDFs as an explicitly bounded approximation or a search accelerator; they do not remove the need for trustworthy solid classification and visible-surface validation.

An API that accelerates rigid bodies, hair particles, BVH traversal or SDF samples supplies useful pieces. None establishes Cyrus's root constraints, rest restoration, authored bindings, foliage contact correctness or Max geometry delivery. The recommended initial solver is a constrained static optimization/projection design. PBD/XPBD and rod research inform its operators and scheduling; time integration must not be smuggled into its product semantics.

## 1. The collision contract to share across backends

**[P]** Cyrus currently admits positive uniform instance scale, uses metres and +Y up internally, discovers old/new neighborhoods, and retains complete prior publication on failure. Contact gap, Inside solid exclusion and Under collider exclusion have separate meanings. The supplied 64 relevant-collider limit is an admission limit, not a promise that 64 concurrent contacts are cheap.

**[D]** Freeze a backend-neutral numerical query contract before comparing CPU, CUDA and OpenCL:

| Request/result component | Required meaning |
|---|---|
| Collider asset | Immutable geometry/proxy plus asset fingerprint, solid-admission result, coordinate frame and acceleration revision |
| Collider instance | Stable ID, transform revision, positive scale, inverse transform and broad-phase bounds; never duplicate unchanged triangle assets per instance |
| Query | Whole segment endpoints, envelope radius, physical Contact gap, search/proposal bounds and required generation |
| Contact witness | Collider/feature IDs, point on segment or visible element, point/feature on collider, sign/classification, local separation direction, distance or conservative bound, validity neighborhood |
| Completion | Complete, overflow, ambiguous occupancy, degenerate, numerical failure, unsupported or cancelled; an empty incomplete list is not a clear result |
| Work | Traversed nodes, narrow-phase pairs, occupancy work, maximum contacts, scratch peak and refresh count |
| Final report | Actual root, attachment, segment-length, frame and full-surface residuals; approximation/error bound; source/world generation |

For multiple stones, retain every relevant collider and the contacts necessary to constrain the current configuration. “Nearest obstacle only” can alternate corrections through opposite stones. Contact-list truncation must set an incomplete status and trigger a bounded retry or CPU fallback; it must not be reinterpreted as convergence. A contact witness is local evidence for a current linearization, not a permanent weld to a triangle.

### Coordinate conversion and applying clearance once

**[E/D]** Let a collider's admitted world transform be `x_world = s R x_local + t`, with `s > 0` and orthonormal `R`. Transform a plant query into collider space once. Collider-local distances and radii are world distances divided by `s`; transform an outward normal with `R` and renormalize. Compose the explicit Max +Z/scene-unit boundary with these transforms, rather than rotating only positions and forgetting frames or normals.

Choose exactly one convention: query the **uninflated** collider with `effective_radius = envelope_radius + ContactGap`, or query an appropriately inflated collider with the unexpanded envelope. Do not perform both. Numerical uncertainty is a separately recorded safety allowance. Hide margin goes only into the independently selected root-group exclusion test. It is not added to contact thickness and is not an escape route for failed guides.

## 2. Collider representations

The following is a **proposed implementation comparison [D]**, not a claim that every backend supports every shape identically. All colliders in this assignment are fixed during one solve; no dynamic-body mass/inertia support is required.

| Representation | What it is useful for | Correctness and cost conditions | Initial penetration and thin geometry |
|---|---|---|---|
| Analytic sphere/capsule | First prototype, stones approximated conservatively, stems/rounded obstacles | Exact formulas and small resident records; conservative fit may overbend compared with the render mesh | Signed distance identifies inside states. A capsule/capsule query must cover both segments, not just endpoints. At the exact center/axis, a unique escape normal may not exist |
| Oriented box | Curbs, blocks, fixture corners | Transform to box-local coordinates; distinguish rounded clearance from an enlarged AABB | Sharp features yield multiple equally valid normals. A point inside a box needs nearest exit-face logic; one smooth gradient is insufficient at ties |
| Convex hull | Closed convex rock proxy | Support-map distance/penetration methods or face-based tests; hull tolerance and degeneracy must be admitted | Concave recesses are filled by the hull. Deep penetration needs an inside/penetration path, not only outside GJK distance |
| Compound hulls/primitives | Concave approximation from a union of small components | Query all intersecting children, deduplicate shared boundaries, bound child count; outer union must contain intended collider when used conservatively | Overlaps introduce redundant contacts and can trap a local projection. Small gaps may vanish under conservative decomposition |
| Closed triangle mesh + BVH | Accurate reusable detailed stones and final checks | Geometry admission, robust segment–triangle/triangle–triangle distances, solid classification and bounded traversal; static geometry BVH is reused | A surface BVH alone does not classify an entirely enclosed blade. Thin shells require explicit thickness/solid policy; open sheets are not automatically solids |
| Dense SDF | Many repeated queries over a small fixed domain | Constant-size sampling work but cubic storage growth and field-construction cost; error and sign assumptions required | Features below field resolution may disappear. Saturated interior cells can have zero gradient. Outside the valid band/domain is not automatically clear |
| Sparse/narrow-band SDF | Reusable large collider with localized detail | Storage follows active voxels plus hierarchy; record band width, background semantics, precision and geometry revision | Missing fine features/sign ambiguity remain; a deeply embedded guide may lie outside useful gradient support |

**[V]** PhysX 5.6.1's GPU documentation distinguishes GPU rigid-body dynamics, GPU broad phase, PBD particles, FEM deformables and SDF collision, with different enablement and device requirements. It does not expose Cyrus's prepared rooted-guide contract. Jolt 5.6.0 introduces a separate GPU hair system, with environment collision restricted there to convex hulls and compounds and with work-in-progress warnings. Neither is evidence that an existing CPU rigid-body integration can simply be recompiled into the desired GPU fitter. [COL28](17_SOURCE_LEDGER.md#col28), [COL26](17_SOURCE_LEDGER.md#col26)

### Asset-space reuse and local invalidation

**[D]** Build a triangle BVH or field once per admitted collider geometry fingerprint and quality setting. A rigid transform edit changes the instance transform and top-level bounds; it does not require rebuilding the source mesh BVH or resampling a field in world coordinates. A positive uniform scale edit reuses local geometry if the transformed query radii/error budget remain valid. Source deformation can refit a BVH while topology is fixed, but poor tree quality after large changes requires a measured rebuild policy. A field requires regeneration when its defining geometry or sampling/offset policy changes.

The affected set is the union of prior contact/exclusion dependencies, the old influence region and the new influence region, including independently edited collider transforms. This restores plants when a stone departs and captures newly entered plants. Do not compute this from only the last published stone transform if authored edits are ahead of publication.

For Under collider, use horizontal projected bounds and a separate vertical condition. Do not feed an effectively infinite upward extent into a general 3D split heuristic and lose ground-plane locality. A local rigid edit should update its index entry, not trigger an unconditional full-scene rebuild. GPU LBVH construction is relevant when many entries truly change; it is not a reason to replace a cheap CPU localized lookup. Karras's original construction paper is evidence for a parallel tree-building method, not for Cyrus drag latency. [COL08](17_SOURCE_LEDGER.md#col08)

## 3. Whole-span contact and visible width

**[E]** A simple adversarial sphere shows why vertex tests fail. Let a sphere of radius `0.1 m` be centered at the origin; a guide span joins `(-0.2, 0, 0)` and `(0.2, 0, 0)`. Both endpoints are outside and the span crosses the solid. Increasing the count of endpoint tests does not fix the wrong primitive.

**[D]** A prepared span should carry a conservative envelope for all bound geometry assigned to it. The envelope includes blade half-width/thickness, offsets of bound leaves/flowers, and the evaluator's actual interpolation behavior. A rest-space radius is only valid after deformation if the binding map preserves the required radial bound. Blended frames, cubic centerline overshoot and child attachments must be accounted for. Large leaf envelopes can be conservative enough to prevent an otherwise feasible visible-mesh fit; diagnose envelope conservatism rather than claiming the physical scene has no solution.

For a sphere, minimize the segment-to-center distance analytically and compare it with `sphere_radius + envelope_radius + ContactGap`. For a mesh, traverse a radius-expanded segment AABB/capsule against the collider BVH, evaluate the actual segment–triangle distances/intersections, and separately classify inside states. A surface query that finds no nearby face cannot certify that a guide is outside: it may be deep inside a large closed solid.

**[V]** Warp's documented `bvh_query_capsule` returns conservative overlaps with **stored bounding boxes**. It inflates each node box before a ray/slab test. To cover a closed segment, pass the unnormalized `p1-p0` direction and `max_dist=1.0` to iteration; zero-length segments require a sphere query. With `mesh_get_bvh`, returned items identify triangle candidates. These are useful broad-phase primitives, not a complete capsule–triangle contact manifold, penetration depth or static plant solver. [COL17](17_SOURCE_LEDGER.md#col17), [COL15](17_SOURCE_LEDGER.md#col15)

### Local witnesses and root conflicts

**[E/D]** For a temporary witness at `p(u)=(1-u)x_i+u x_{i+1}`, use the local constraint

\[
c = n\cdot(p(u)-q)-r-g \ge 0.
\]

Here `q,n,u` are qualified by the current collider feature and pose; `r` is the envelope radius and `g` the gap. With endpoint mobilities `w_i,w_j`, the point-linearized denominator is

\[
D=w_i(1-u)^2+w_j u^2,
\quad
\Delta x_i=\frac{-c}{D}w_i(1-u)n,
\quad
\Delta x_j=\frac{-c}{D}w_j u n.
\]

Apply only for violated `c`, valid nonzero gradient and sufficiently positive `D`; cap displacement and requery. These are **proposed local correction equations**, not a convergence guarantee. At a fixed root with `u=0`, `D=0`; arbitrarily dividing by epsilon creates huge motion without resolving the anchored contact. Classify the fixed root against the required envelope and gap. A verified root-inside contradiction is a local infeasibility certificate for those fixed constraints. A stalled tangent direction elsewhere is only a failed local search.

At exact symmetry, sharp corners or deep inside a solid, a unique normal can be absent. Use stable feature tie-breaking and a bounded, explicitly declared set of alternative search directions, or return `AmbiguousContact`/`LocalSearchStalled`. Do not manufacture a normal and report a successful complete query. Rebuild witnesses after every bounded correction batch and whenever a feature changes. Multiple contacts share nodes and must be reconciled with length and bending, not merely pushed once in collider order.

## 4. What SDFs can and cannot certify

**[V]** The 2020 SDF-contact paper investigates local optimization over mesh elements because vertex-only sampling misses continuous surface contacts. It compares projected gradient descent, Frank–Wolfe and golden-section search. This supports element-level search; it does not turn a bounded local minimizer into a proof of a global minimum over a nonconvex field. [COL07](17_SOURCE_LEDGER.md#col07)

**[E] Conditional error derivation.** Suppose the intended solid has a true 1-Lipschitz signed distance `φ`; every stored corner sample has known absolute error at most `ε_s`; the cell spacings are `h_x,h_y,h_z`; evaluation uses convex trilinear weights; and numerical evaluation adds at most `ε_fp`. Then

\[
|\tilde\phi(x)-\phi(x)|\le E=\epsilon_s+\tfrac12\sqrt{h_x^2+h_y^2+h_z^2}+\epsilon_{fp}.
\]

The interpolation term follows from the Lipschitz bound, the weighted corner distances, and Jensen's inequality: the weighted squared distance to the corners is `Σ a_d(h_d-a_d) ≤ Σ h_d²/4`. This is a conservative analytical bound, not a measured interpolation error. It does **not** apply automatically to incorrectly signed data, cubic interpolation with negative weights, quantized/background values without a bound, or fields with unknown Lipschitz constant.

For samples covering a straight span with maximum spacing `δ`, any point on the span is at most `δ/2` from a sample. Therefore a sufficient point-sampling certificate is

\[
\tilde\phi(p_k) \ge r+g+E+\delta/2
\]

at all samples, with valid samples across the complete span and a constant conservative `r`. Adaptive interval subdivision may use local lower bounds and stop when all intervals are certified. Budget exhaustion means unknown, not clear. For a broad triangle, analogous certification requires a proven covering radius over the triangle or exact continuous-element narrow phase; checking only its three corners is inadequate.

**[D] Consequences.** A 1 mm isotropic grid contributes at most about 0.866 mm from this generic interpolation bound before other errors. That can consume more than an artist's small clearance. Either refine, use a tighter proved local bound, move exact checks to the CPU, or label the preview approximate. Do not announce subvoxel clearance accuracy from grid spacing alone.

Distance correctness and gradient usefulness are separate. At a medial axis, sharp edge, or saturated narrow-band interior, finite differences may be zero or unstable. A zero gradient cannot be normalized safely. Requery the source mesh/analytic proxy for an exit witness or fail diagnostically. A truncated positive background can certify a distance only if it carries a conservative lower-bound guarantee; an unqualified sentinel cannot. Record field validity domain, signed band, voxel transform, topology/geometry fingerprint and construction tolerance in its cache key.

**[V]** Warp's winding-number query documentation distinguishes sign classification from closest-point search radius; it requires inspecting the result flag and warns that a mesh not configured for winding support falls back to ray-based sign classification. Poor/open geometry can have a smooth winding-based classification, but a threshold does not resolve the artist's intended solid semantics. [COL18](17_SOURCE_LEDGER.md#col18)

## 5. Solver families against the actual operation

| Family | Verified idea and transfer | Proposed Cyrus choice / limitation |
|---|---|---|
| PBD | Position-level projection with sequential constraint treatment [COL01](17_SOURCE_LEDGER.md#col01) | Useful operators; plain finite-iteration stiffness is solver-dependent. Reset state and use explicit final residuals |
| XPBD | Compliant constraints and accumulated multipliers derived from an implicit dynamics formulation [COL02](17_SOURCE_LEDGER.md#col02) | Good dynamic reference; using its algebra in static optimization requires declared penalty/compliance semantics, not an invented physical time step |
| Discrete elastic rods | Framed curves, rest bending/twist and inextensibility; original centerline dynamics with quasistatic material frame [COL03](17_SOURCE_LEDGER.md#col03) | Appropriate when twist/anisotropic stems justify cost; not itself branch binding, contact, final mesh validation or a GPU implementation |
| Position/orientation Cosserat rods | Coupled quaternion/position constraints for stretch/shear and bend/twist [COL04](17_SOURCE_LEDGER.md#col04) | More expressive than a centerline-only grass fitter; frame normalization and rotation branch conventions required |
| Direct stiff-rod tree solve | Newton/direct solution over an acyclic constrained structure improves stiff-rod convergence [COL05](17_SOURCE_LEDGER.md#col05) | Serious comparator for long/branched plants when local projections require too many rounds; contact active-set changes remain |
| Projective dynamics | Alternating local projections/global solve for selected energy potentials [COL06](17_SOURCE_LEDGER.md#col06) | Shared topology may allow reusable structural factorization; changing contact/weights or boundary conditions can reduce that reuse. Not the smallest first prototype |
| Bounded quasistatic optimization | Explicit rest objective plus geometric constraints, independently started each request | Recommended initial semantics; local failures must remain diagnostics, not feasibility conclusions |
| Hinge/analytic bend | Few authored rotations and a simple rest preference | Useful explicit low-detail quality level, but a one-hinge shape cannot route a long blade around arbitrary multiple stones |
| Follow-the-leader hair | Fast root-to-tip length enforcement [COL10](17_SOURCE_LEDGER.md#col10) | Useful length-restoration operator; the later contact pass can violate length and vice versa. Its dynamic hair claim is not simultaneous exact contact proof |
| Hair/cloth dynamic solvers | GPU scheduling, compact strands, constraint coloring, SDF generation | Reuse isolated techniques; histories, wind, damping and collision approximations differ from static fitting |

**[D] Numerical baseline.** Use prepared node positions and material frames in plant-local metres, source rest lengths, rooted-group membership, hierarchy, width/thickness envelopes, and authored root mode. Define a dimensionless objective comprising weighted rest displacement, rest relative-frame bending/twist and optional soft root orientation. Treat root position, parent attachment and length/strain bounds as hard acceptance constraints. Scale terms by declared reference lengths and material arc quadrature so tessellation changes do not silently multiply stiffness. Numerical weights are artistic/optimization weights unless an independently calibrated physical model is adopted.

Do not minimize distance to the previously published pose as a hidden primary objective. That would create path-dependent fitting and obstruct exact rest restoration. The previous pose may be a separately measured optional acceleration guess only if the accepted result is checked against the same fresh-rest problem and repeat-call semantics; the first prototype should simply start from rest.

### Root position is not root orientation

**[D]** PositionOnly fixes `x_root` but allows the first tangent to turn; the rest objective discourages gratuitous rotation. ClampFrame fixes an admitted root material frame. For a tangent-aligned first segment with fixed rest length, this also fixes its next endpoint; nearby obstacles can make that configuration infeasible. SoftFrame fixes position but penalizes finite angular deviation with its own coefficient and measured angle residual. Pinning two points is an orientation condition, not merely a stronger position pin. Preserve authored fixed root rings as all specified fixed samples, not one averaged root.

A child guide root follows its parent attachment's evaluated position and frame at a persistent material coordinate. Parent and child constraints must be solved jointly or in an explicitly one-way hierarchy. If a child contact may bend the parent, forward depth evaluation alone cannot communicate that correction: include a reverse accumulation/solve pass or formulate the coupled block. The first narrow prototype can admit independent rooted grass groups and explicitly defer coupled branch feedback; it must not claim equivalent support for all branched plants.

### Bounded algorithm sketch — not compiled or executed

```text
fit(snapshot, admitted_source, affected_groups, settings, budgets):
    validate all lengths, indices, frames, transforms, IDs and revisions
    admit peak memory including old publication, working poses and contact scratch
    perform explicit root-group exclusion using only the chosen hide policy
    pose = immutable rest for every active visible rooted group
    if complete rest/envelope/surface audit is clear:
        return exact-rest successor
    for iteration in [0, max_iterations):
        stop if superseded, cancelled, query budget exhausted or numeric failure
        contacts = complete refreshed whole-span and required visible-element queries
        fail diagnostically on ambiguous occupancy or contact-list overflow
        detect anchored contradictions; never move roots or hide failed groups
        propose bounded rest/bend/length/contact correction
        reconcile shared nodes using colors or deterministic Jacobi gathers
        solve/evaluate parent attachments under the admitted coupling policy
        regenerate tangent-aligned material frames and authored twist
        bounded line/trust-region search; refresh contacts after accepted proposal
        if actual residuals meet the stopping criteria: break
    run fresh complete collision, root, length, frame and attachment checks
    materialize required visible geometry and run independent surface verification
    publishable only if every required check is complete and the generation matches
    otherwise return diagnostic and retain prior complete publication
```

The final geometry check is intentionally separate from guide convergence. If full visible refinement is deferred during drag, publish that preview only through an explicit approximate-preview policy, keep the last exact result available, and require complete final refinement before Bake/export or an exact-status update. Never achieve a budget by silently dropping unsolved visible guides.

## 6. Parallelism without changing the mathematical problem

**[V]** Parallel PBD work includes Jacobi-like constraint averaging; TressFX's inspected shader mixes strand-serial local shape work with vertex-level dispatches and alternating even/odd length updates separated by group barriers. Its capsule routine operates on current vertex positions, and its first two hair vertices are treated as immovable. Those details are why copying a hair sample wholesale would change Cyrus's contact/root semantics. [COL09](17_SOURCE_LEDGER.md#col09), [COL22](17_SOURCE_LEDGER.md#col22)

**[D]** Independent rooted groups are natural parallel jobs. Bucket them by chain length, contact-count estimate and solver mode. Short grass guides can use a warp/subgroup per guide with all lane masks explicit; longer chains can use a workgroup and tiled shared scratch. A whole 451-guide clump need not occupy one block or one thread. Contact generation can run one job per span/collider pair; refresh, compact and sort output by stable `(instance, guide, span, collider, feature)` IDs.

For length constraints on a simple chain, even/odd edge coloring prevents shared-node writes within a color. Bend constraints spanning triples need a suitable conflict coloring, not the same two-color assumption. Dynamic contacts can instead emit corrections into bounded records and gather per node in a defined order. Jacobi reads a fixed input pose and writes a separate output pose; in-place unsynchronized updates are not Jacobi. Gauss–Seidel generally needs sequential dependencies or independent colors. Neither stable contact sorting nor a fixed kernel order guarantees bitwise equality across floating-point implementations.

Structural colors and depth offsets are prepared once per source. Contact dependencies and active depth sets are rebuilt for the affected work only. A wave/subgroup operation needs the same participating lanes at the corresponding operation; divergence around barriers is not a safe optimization. Avoid assuming a CUDA warp is interchangeable with every OpenCL subgroup or HLSL wave.

Long thin guides can converge slowly under local corrections because information propagates through many edges. Measure residual decrease per total work, not merely rounds per second. If the projected local method fails long/branched fixtures under the agreed work limit, compare a batched tree/direct method before increasing iteration counts without a bound. Small Steps is evidence for a different **dynamic substepping** tradeoff, not permission to turn each collider update into an animation that eventually settles. [COL05](17_SOURCE_LEDGER.md#col05), [COL11](17_SOURCE_LEDGER.md#col11)

## 7. Frames, finite rotations and rest preservation

**[V]** Rotation-minimizing frames avoid the zero-curvature singularity of Frenet frames; the original double-reflection work is from 2008, despite the later PDF hosting path. [COL13](17_SOURCE_LEDGER.md#col13)

**[D]** Regenerate unit tangent-aligned frames with deterministic transport from the admitted root frame and preserve authored unwrapped twist relative to rest. Normalize quaternions and make neighboring signs consistent before interpolation, since `q` and `−q` denote the same rotation. Shortest-path quaternion interpolation cannot reconstruct a blade's authored multiple turns from endpoint quaternions alone. Store the additional twist information or reject an ambiguous binding. Near anti-parallel tangents need a documented axis choice or admission limit, not an arbitrary floating-point cross-product direction.

Preserve guide/span identities and material coordinates. Refine contact sampling privately rather than changing public topology every drag. For a clear/rest group, reuse the exact immutable rest result instead of round-tripping through float poses and re-normalization. This prevents tiny permanent deformations on unchanged geometry.

## 8. Failure and motion semantics

| Case | Required response / decisive fixture |
|---|---|
| Whole span crosses a sphere while endpoints clear | Detect span contact in analytic and mesh modes; point-only backend fails qualification |
| Entire blade is inside a large solid | Occupancy detects inside even without nearby surface; incomplete narrow-band query cannot be clear |
| Root lies inside required clearance but hide policy does not exclude it | Keep root, diagnose anchored conflict, retain prior exact result |
| Two stones squeeze a guide or broad leaf | Simultaneous contacts plus length/frame checks; failed bounded search is not a proof of global infeasibility |
| Guide clear but leaf edge/face crosses | Visible-element validation rejects or invokes bounded refinement |
| Narrow gap smaller than conservative envelope | Explain conservative envelope failure; do not quietly shrink physical width |
| Sharp corner/medial axis/zero gradient | Qualified feature alternative or explicit ambiguity/stall status |
| Open, nonmanifold or self-intersecting collider | Reject solid admission or require an explicit repaired/thickened proxy; winding threshold alone is insufficient |
| Small stems and large coordinates | Double host capture/rebase before FP32 conversion; reject tolerances below admitted resolution |
| Teleport or fast drag | Fit the final obstacle configuration from rest and refresh old/new affected sets; no false CCD claim |
| Collider rotation or scale | Recompute influence bounds and local conversion/error budget; rigid asset data can remain shared |
| Stone removed / Undo / source edited | Revision invalidation restores rest or rebuilds binding as appropriate; no historical deformation accumulation |

**[D]** Endpoint quasistatic fitting has no obligation to reproduce the path traveled between pointer events. It also does not provide continuous collision detection. If the product later promises collision-free interpolation between successive published plant poses, add swept leaf/segment/triangle checks and a path policy. Such checks do not solve an infeasible final state, and the union of only old/new AABBs can miss a rotating shape's intermediate extent. For current endpoint semantics, a smooth-looking transition is a separately labeled display interpolation unless it is also collision-validated.

A barrier/contact framework such as IPC is useful evidence for geometric correctness methods, but its trajectory guarantee has mathematical and implementation assumptions and should not be claimed for a bounded locally projected fitter starting from intersecting rest geometry. [COL12](17_SOURCE_LEDGER.md#col12)

## 9. Smallest experiments that decide the next solver investment

All are **proposed and not executed**; inputs and acceptance belong to the benchmark package.

1. **Whole-span analytic parity:** sphere, box, capsule and two-obstacle tests, including off-axis feasible scenes and an authored feasible positive control. CPU double, CPU float, CUDA and OpenCL must use the same finite algorithm and limits. Verify actual constraints on successes.
2. **SDF certification:** exact sphere distance sampled at several grid spacings. Verify the conservative error formula, field-domain rejection and span-sampling coverage. Add subvoxel thin protrusions and deep interior cases that must reject or refine.
3. **Root-mode separation:** PositionOnly succeeds by turning the first span in a scene where ClampFrame is blocked; SoftFrame reports its actual root angle. A zero-denominator case must diagnose, not explode.
4. **Visible leaf control:** guide clearance with an intersecting wide leaf, then a correctly fitted pose. Measure the incremental cost of complete visible refinement instead of crediting the guide kernel with whole-mesh correctness.
5. **Long-chain/branch comparator:** residual-versus-work curves for colored projections, deterministic Jacobi and batched tree/direct methods. Decide from total capture/transfer/solve/validation cost at equal quality.

Use the proposed numerical thresholds in [09](09_MEMORY_PRECISION_AND_HARDWARE.md) and [10](10_BENCHMARK_AND_VALIDATION_PLAN.md); they are new qualification targets, not claimed current Cyrus thresholds. The provided approximately 9.145% maximum checked stem-edge change is a visible-mesh observation in one local audit, not a guide rest-length tolerance or an acceptable universal stretch limit.

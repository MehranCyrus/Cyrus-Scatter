# 05 — Collision and guide solving

[Contents](00_README.md) · [Parallel layout](03_PARALLELISM_AND_DATA_LAYOUT.md) · [Validation](10_BENCHMARK_AND_VALIDATION_PLAN.md) · [Source ledger](17_SOURCE_LEDGER.md)

**Decision — proposal.** Preserve the existing static fitter as the correctness reference. First accelerate deformation; if solving subsequently dominates a sufficiently large active set, implement a narrow GPU static fitting path for prepared guides and qualified collider representations. Neither a hair simulation nor a GPU rigid-body engine is a drop-in replacement. All solver and contact prototypes in this chapter are **not executed**.

## 1. Define the operation before the solver

**Provided project facts.** An edit maps the current prepared source, placements, collider geometry/poses, settings, and authored overrides to a complete successor. Unaffected instances remain cached. Removing influence restores rest shape. Contact gap controls fitting; Hide margin and the selected exclusion mode control whole rooted-group visibility. These are distinct operations. The repository and its recorded host tests were not inspected or rerun here.

**Proposed contract.** Define a stateless map `Fit(rest, attachments, currentColliders, settings)`. Previous poses may accelerate a solve, but must not become unrecorded physics state. No velocity, inertia, friction history, accumulated plasticity, or frame-rate-dependent compliance enters this map. A warm start that selects a visibly different local minimum is a behavior change, even if both outputs are penetration-free. Qualify it with cold-versus-warm and drag-path permutation tests; otherwise use canonical initialization and tie-breaking. A deterministic fallback to rest is valid only after proving the current visible geometry is clear.

PBD is a framework of position-level constraints originally embedded in a time-stepping loop. XPBD introduces compliance and accumulated multipliers derived from implicit dynamics; its compliance scaling contains the time step. Reusing projection formulas for an editing problem requires an explicitly defined static objective and convergence criterion. Simply setting gravity to zero and executing a fixed number of frames does not establish stateless fitting. [A01](https://matthias-research.github.io/pages/publications/posBasedDyn.pdf) [A02](https://mmacklin.com/xpbd.pdf)

### Candidate methods

| Method | Transferable part | Consequence for Cyrus | Recommendation |
|---|---|---|---|
| Analytical arc/hinge or root-to-tip geometric bending | Few degrees of freedom, fast initialization, easily bounded work | Does not generally satisfy competing contacts, branch coupling, or broad leaf surfaces | Proposed simple-asset initializer; accept only after full geometric checks |
| PBD-style projection | Local equality/inequality updates and fixed anchors | Finite-iteration result depends on order and stiffness tuning | Match current reference behavior before parallelizing; retain residual checks |
| XPBD | Separate compliance from arbitrary iteration stiffness; useful reusable constraint form | Dynamic formulation includes a time step; early termination still leaves error | Candidate only with a specified static adaptation or a separately named dynamics product |
| Discrete elastic/Cosserat rods | Rest curvature, material frames, anisotropic bending, twist and length | More state and nonlinear coupling; collision remains a separate subsystem | Worth a later quality comparison for stems/branches, not the first acceleration dependency |
| Direct tree rod solver | Solve coupled acyclic rod constraints together | Contact edges can break the tree structure; requires alternating or extended solves | Evaluate if stiff long branches defeat local projection |
| Projective dynamics | Parallel local projections plus a global solve; reusable structure for fixed constraints | Changing contacts complicate factorization/update costs; original formulation uses soft constraints | Not the smallest sparse-edit prototype |
| Hair techniques | Strand batches, colored edge constraints, local shape preservation, shared rest definitions | Common implementations use particles, history, follower strands and approximate collision | Reuse scheduling ideas; replace semantics and validate contact coverage |

The rod distinctions are substantive: DER represents a framed centerline and treats twist quasistatically while retaining dynamic centerline motion; the Cosserat PBD paper explicitly couples positions and quaternion orientations. Deul et al. solve acyclic rod structures with a direct method, with separate treatment of collisions. Projective dynamics provides local/global energy minimization, but its original paper identifies hard constraints and changing global systems as limitations. These are evidence for candidate ingredients, not evidence of a ready Cyrus GPU fitter. [A03](https://www.cs.columbia.edu/cg/pdfs/143-rods.pdf) [A04](https://animation.rwth-aachen.de/media/papers/2016-SCA-Cosserat-Rods.pdf) [A05](https://animation.rwth-aachen.de/publication/0557/) [A06](https://users.cs.utah.edu/~ladislav/bouaziz14projective/bouaziz14projective.pdf)

## 2. A narrow static formulation

**Proposed design, not a recovered implementation.** Variables are guide positions `x`, material orientations `q`, and any admitted rigid-part offsets. Minimize a weighted rest-shape energy while enforcing hard anchors, attachments, admitted strain limits, and collision inequalities:

\[
\min_{x,q}\ E_{\mathrm{bend/twist}}(x,q; x^0,q^0)
              + E_{\mathrm{rest}}(x,q)
\quad\text{subject to}\quad
A(x,q)=0,\quad \epsilon_{\min}\leq \epsilon_e\leq\epsilon_{\max},\quad g_j(x,q)\geq0.
\]

Here `εe = |xᵢ₊₁−xᵢ|/ℓe⁰ − 1` is axial strain relative to the nonzero rest span length. The rest term selects the authored unforced shape; it is not a new target inferred during dragging. Store rest arc lengths, intrinsic curvature and twist, cross-section axes, root-group membership, and parent sockets once in preparation. Derive weights with consistent physical dimensions or explicitly label them artistic dimensionless weights. Do not advertise calibrated material physics without calibration.

**Position and orientation anchoring are independent.** Eliminate fixed root positions from the unknown vector, or restore them exactly at every accepted iteration. A nonzero root-ring extent can fix more than a single point. Root orientation is separately clamped or penalized, for example by `kθ ||Log(Rrestᵀ Rroot)||²`, where `Log` is the rotation vector. Pinning one point does not prevent rotation; pinning two points does not determine all twist. Test both independent controls. Keep authored rest curvature as the preferred energy minimum, not a hard rule preventing bending.

**Hierarchy.** A child root follows its parent socket's current position and material frame, with the authored socket transform preserved. Parent-depth scheduling suffices for one-way attachment evaluation after parent poses are known. It is not a complete coupled branch solver if a child's collision must bend its parent. For coupled solving, batch constraints by conflict-free color or solve a tree block, repeating contact and internal passes. If a parent and child share writable degrees of freedom, they cannot independently update them without a specified reduction or synchronization.

**Rotations.** Normalize quaternions, choose consistent hemisphere signs for interpolation, preserve rest twist, and handle nearly antiparallel tangents explicitly. Do not average quaternion components without normalization and a sign convention. Near-π rotation branches and nearly zero spans must trigger the qualified special case or admission failure, not NaNs. Material-frame continuity is also a visible leaf-orientation requirement.

## 3. Collision representations and their roles

All choices below are proposed for **fixed obstacles with edited instance transforms**, not a new dynamic-body world. Geometry and acceleration structures are shared by source fingerprint; transforms and revision tokens belong to instances.

| Representation | Good use | Cost/ambiguity that must remain explicit |
|---|---|---|
| Sphere, capsule, rigid oriented box | Small analytic reference fixtures and authored simple proxies | Shape mismatch is an approximation; record maximum proxy error or qualify it as artistic |
| Convex hull | Compact irregular stones, stable convex queries | Concavities are filled. A gap in the render mesh can disappear in its hull |
| Compound convex/trunk-root proxies | Concave overall envelope without a dense mesh | Components increase contact pairs. Overlapping components need union-aware containment and useful exterior witnesses |
| Closed triangle mesh + BVH | Detailed fixed collider geometry and final validation | Closest surface distance alone does not establish inside/outside; degenerate faces, winding and open boundaries require admission rules |
| Dense SDF | Many repeated queries against compact fixed geometry | Memory grows cubically with inverse voxel size; field build, sign, interpolation and gradient errors must be budgeted |
| Sparse/narrow-band SDF | Reusable detailed surfaces with large empty regions | Missing tiles and out-of-band regions require known occupancy or fallback; absence of a sample is not clearance |
| GPU proxy/field plus CPU refinement | Interactive batches with expensive final surface checks | Refinement can dominate total latency. An approximate pose has an explicit status and cannot silently replace a required complete result |

**Query contract — proposal.** Every query returns `CompleteClear`, `CompleteContact`, `Incomplete`, or `Unsupported`, plus the geometry-and-pose generation, stable collider IDs, work consumed, and any tolerance/error bound. A complete result means all relevant admitted candidates were considered. Budget exhaustion, traversal overflow, contact-array overflow, missing field data, degenerate normal, nonfinite input, or cancellation are never converted to clear.

An inspected counterexample matters: Warp v1.18.0 `mesh_query_point` and its winding-number variant return `false` when no face is strictly closer than `max_dist`; their native code assigns sign only after finding such a face. The winding variant falls back to ray-based classification when winding data was not built. Its nearest-face traversal skips sufficiently sliver-like triangles. A Cyrus wrapper therefore needs explicit mesh admission, data-presence checks and complete containment logic. [A14](https://github.com/NVIDIA/warp/blob/f2eaed82d8d03b37bf1014cc975954067fefcf16/warp/native/mesh.h)

Generalized/fast winding numbers provide a useful defect-tolerant classification signal; on an open mesh, however, the threshold is an interpretation of imperfect geometry, not discovery of an unambiguous physical solid. Admit a repaired closed proxy, explicitly select two-sided surface collision without solid exclusion, or return unsupported/ambiguous. Do not silently treat a single open terrain sheet as a closed stone. [A10](https://www.dgp.toronto.edu/projects/fast-winding-numbers/)

## 4. Whole spans, blade width and visible surfaces

**Proposed contact invariant.** For a centerline span `p(u)=(1−u)a+ub`, `u∈[0,1]`, conservative cross-section envelope `r(u)`, and signed obstacle distance positive outside, require `φ(p(u))−r(u)−ContactGap ≥ 0` over the whole span. Apply geometric radius and Contact gap once. Hidden-root decisions instead use their own Hide margin and exclusion definition.

A segment with both endpoints outside can cross a stone. A segment wholly inside a stone may have no surface intersection. Both are mandatory tests. For triangles, combine segment/triangle feature tests and distance queries with complete solid classification; for analytic spheres/boxes use analytic controls. A mesh distance routine called at the two endpoints does not qualify a capsule query.

Store qualified witnesses: span parameter `u`, centerline point, obstacle point, outward normal, signed gap, stable obstacle/subfeature ID, and tolerance. Reconstruct the witness in tests. At a sharp feature the supporting normal may be nonunique; choose a deterministic valid normal and retain multiple active contacts when needed. Do not invent `u` from an unrelated raw hit or normalize an undefined zero vector.

**Broad leaves.** A leaf edge or face can cross a collider while its guide remains clear. Either a provably covering envelope rejects such poses conservatively, or the actual bound surface must participate in refinement. An envelope must cover offsets along as well as across the guide, attached rigid parts, and thickness; using only stem radius cannot cover a broad leaf. Conservative envelopes may reject a fit that the actual leaf could achieve—report this approximation. Final checks must include edge/face intersection and solid containment, not merely render vertices.

Macklin et al.'s SDF collision work searches over mesh elements rather than checking only sampled vertices. Its limitations explicitly include local minima and one contact per element missing multiple features. This supports adaptive element search/refinement, but not a blanket guarantee from one local minimization. [A09](https://mmacklin.com/sdfcontact.pdf)

### A defensible field-error policy

**Analytical bound, not measured accuracy.** Suppose stored grid-node values approximate a genuine 1-Lipschitz signed distance with error at most `εbuild`, grid spacing is `h`, and evaluation roundoff is bounded by `εfp`. Trilinear interpolation is a convex combination. Cauchy–Schwarz bounds its weighted corner distance by `√3 h/2`, giving the conservative bound:

\[
|\tilde\phi(x)-\phi(x)|\leq\epsilon_{\mathrm{build}}+\frac{\sqrt3}{2}h+\epsilon_{\mathrm{fp}}=\delta.
\]

This requires correct sign and valid surrounding samples. Unknown sign, a non-distance field, quantization outside its stated bound, absent tiles, or truncated background values invalidate the proof. Include coordinate conversion, sample quantization and arithmetic error in the stated bound; in world units use `δworld = scale × δlocal + εtransform`. All radii, gaps, sample distances and error bounds in one test must share that metric space. Gradient accuracy does not follow automatically; near a medial axis or sharp corner the normal can remain ill-conditioned. Use a qualified geometric witness or report ambiguity.

For a constant covering radius `r` and endpoint-inclusive samples at spacing no greater than `s` along a straight segment (or another proven covering radius no larger than `s/2`), `min(φ̃samples)−r−gap > δ+s/2` certifies clearance between samples by the same Lipschitz reasoning. Otherwise refine or use a direct query. This is a conservative sufficient test, not an instruction to accept all unsampled intervals. A narrow feature below voxel resolution can change topology; it requires a better field or mesh fallback.

## 5. Sparse invalidation and acceleration

**Proposal.** Keep source-local collider BVHs/fields immutable and reuse them when only a rigid/uniformly scaled pose changes. Transform queries into the collider frame. Update only changed instance bounds in the scene index. Refit into a new immutable generation or copy-on-write pages while previous jobs/readers retain old generations; never mutate a leased BVH. Refit top-level bounds when connectivity is unchanged; rebuild when measured traversal degradation warrants it, not on each pointer event. For moving/deforming collider vertices, refit leaf bounds only when topology permits and rerun shape/solid validation; topology edits require rebuilding affected structures and fingerprints.

Gather candidates from the last *published* collider influence and the newest edited influence, including removal and Undo. Include previously deformed instances whose old influence has disappeared. Coalesced, never-published intermediate requests need not create persistent state. Rotations and scale changes require conservative transformed bounds, not merely translation deltas. A fast teleport is an endpoint fit by current semantics; swept collision is required only if the product separately promises continuous motion/path exclusion. Sweeping a long drag can unnecessarily touch a huge corridor for a stateless endpoint result.

For Under collider, maintain projected ground-plane bounds and height intervals; query horizontal locality before the upward/root test. Artificially infinite vertical boxes must not control a 3D split heuristic. A large global collider count does not justify testing every collider for every guide. Count relevant plant–collider and span–collider pairs separately; stable-ID sort, bounded count/scan/fill, and explicit overflow status prevent silent truncation.

Karras's radix-tree construction is a relevant large-batch building block, not a reason to rebuild a mostly static million-instance index. Warp's inspected BVH code includes device refitting and fixed-size query-stack assumptions; preserving those builder/traverser invariants is part of reuse. Neither provides a general application-level query-work budget automatically. [A11](https://research.nvidia.com/publication/2012-06_maximizing-parallelism-construction-bvhs-octrees-and-k-d-trees) [A15](https://github.com/NVIDIA/warp/blob/f2eaed82d8d03b37bf1014cc975954067fefcf16/warp/native/bvh.cu)

## 6. Bounded parallel solver sketch

**Uncompiled pseudocode.** The launch policy is selected by measured active work, not total resident instance count.

```text
admit(snapshot, geometry, finite values, positive uniform scales, budgets)
candidates = stable_unique(oldPublishedNeighborhood ∪ newNeighborhood)
classify_complete_roots(candidates, exclusionMode, HideMargin)
if any classification incomplete: reject successor
active = compact(visible groups needing fit or rest restoration)
poses = canonical_rest_or_qualified_warm_start(active)
for bounded nonlinear pass:
    contacts = count_then_fill_complete_span_and_surface_candidates(poses)
    if count/work/field limit exceeded: reject successor
    for fixed internal-constraint color:
        solve_disjoint_constraints(poses)       # barrier between colors
    solve_contact_blocks_or_reduced_Jacobi(poses, contacts)
    enforce_hard_anchors_and_attachments(poses)
    update_frames_and_recompute_required_contacts()
    if convergence + complete_geometric_validation: break
if not converged or any required check incomplete: reject successor
return complete_pose_visibility_diagnostics(snapshot_revision)
```

One thread per query/vertex, subgroup per similarly sized guide, and workgroup per bounded plant chunk are alternatives, not interchangeable defaults. Bucket by chain length, branch depth and contact workload to reduce divergence. A huge clump can span workgroups; inter-workgroup dependencies then require separate launches or a supported synchronization scheme. No lane may leave a workgroup barrier while participating lanes still need it.

Jacobi evaluates constraints against the previous iterate and combines their updates. Gauss–Seidel observes earlier updates and cannot be obtained by racing simultaneous writes. Coloring permits parallel updates only for constraints without shared writable variables. Contact coloring changes with contacts; fixed guide colors alone do not protect contact writes. Deterministic segmented reductions avoid order-dependent floating atomic accumulation, at extra storage/work. The unified-particle paper explicitly addresses the convergence problems of plain parallel Jacobi through relaxation; its particle representation and concessions do not establish foliage-surface correctness. [A07](https://mmacklin.com/uppfrta_preprint.pdf)

**Acceptance.** Several stones can make the constraints infeasible. A fixed visible root inside required clearance is not repaired by drifting the root or hiding it because solving is expensive. Preserve the preceding complete publication, identify the conflicting root group/colliders, and allow the artist to change exclusion, clearance, preparation or geometry. If an optional interactive approximation is offered, label it, bound its field/envelope error, cover every admitted visible group, and require full refinement before a result is called verified. See the [failure matrix](11_EDGE_CASE_AND_FAILURE_MATRIX.md).

## 7. Coordinate and cache rules

**Provided convention:** internal metres and +Y up; Max scene units and +Z up; positive uniform scale only. **Proposal:** perform Max conversion once at capture/publication boundaries, retain double host transforms, and rebase local GPU work before FP32 conversion. For uniform scale `s>0`, `φworld=s φlocal`, `gaplocal=gapworld/s`, and `hworld=s hlocal`. Rotate normals and renormalize; nonuniform scale/shear/mirroring remain outside admission. Store the frame and unit generation in every result key.

Field keys include collider geometry fingerprint, voxel transform/resolution, distance/sign algorithm, precision, build version and coverage band. A pose-only edit changes instance transforms; it does not rebuild a source-local field. Geometry edits invalidate fields and cached witnesses. Source preparation edits invalidate guide and foliage bindings. Completed contact results carry both shape and pose revisions. All field/contact/scratch allocations are reserved before work begins, with failure leaving the previous complete result intact.

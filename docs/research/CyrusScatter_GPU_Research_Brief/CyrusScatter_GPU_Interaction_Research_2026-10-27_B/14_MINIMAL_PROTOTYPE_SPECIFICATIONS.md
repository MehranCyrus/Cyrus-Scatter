# 14 — Minimal reproducible prototype specifications

[Index](00_README.md) · [Phases](13_PHASED_IMPLEMENTATION_PLAN.md) · [Benchmark](10_BENCHMARK_AND_VALIDATION_PLAN.md)

## Status and smallest useful next action

**NOT EXECUTED:** no executable Max/CUDA/OpenCL/HLSL prototype is delivered by this research. The following isolated specifications are implementable local tasks. The optional [analysis scripts](analysis/README.md) are runnable and executed, but are arithmetic/oracle tools, not these prototypes.

Start with **P0 baseline trace + P1 two-instance pose delivery**, using authored poses and the existing CPU evaluator. This can prove or reject the highest-risk graphics assumption without first implementing a GPU collision solver.

## P0 — Extract and instrument the real workload

**Owner:** native CPU/host maintainer. **Inputs:** a read-only export of actual S3 prepared data, the scoped200-plant fixture, fixed seed/transform sequence and current release build. **Output:** CPU reference packets and trace manifest, including source/guide/node/span counts, root modes, all relevant colliders, gap/hide settings, rest/posed positions, binding roles, surface-audit results and full key.

Add counters/timers at the supplied source locations listed in [16](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md), not guessed APIs. Separate source capture, map cloning, neighborhood, root classification, contact fit, mesh refinement, deformation, publication and completed upload. Repeat sparse updates after growing retained state `R`; this isolates map-copy overhead from `K`.

**Pass:** reproduce the intended behavior under the current code and explain all wall time; valid positive controls pass; failed/incomplete query status cannot publish. **Reject:** discrepancies with supplied observations are investigated, not hidden by treating4.05ms as a target or invariant.

## P1 — Public Max pose-driven draw proof

**Inputs:** exactly two rooted guides, two instance transforms,256render vertices, an authored curved rest pose, two different bent poses, two material slots, one fixed part, one hidden root group, one UV seam and one hard-normal seam. **No fitter.**

1. CPU reference computes the canonical output and expected topology/visibility/bounds.
2. Draw shared source through the present public-handle/HLSL route. Bind a small constant pose array first; then a paged float texture using verified public operations, if needed.
3. Toggle pose generation tags. Deliberately delay a producer; verify the old complete packet remains until a new complete packet is accepted.
4. Repeat in shaded, Wireframe and hit-test passes, two viewports, camera movement, selection and source replacement.
5. Record source uploads, pose uploads, draw counts, bytes, normals/tangents and actual presented-generation correspondence.

**Pass:** [09](09_MEMORY_PRECISION_AND_HARDWARE.md) tolerances, categorical IDs/material/visibility exactness, conservative bounds, unchanged-camera/F3 no solves or source/pose reuploads, and1,000update/retirement cycles without leaked generations. **Fallback:** CPU vertex/normal materialization, or CPU normals with an explicitly qualified compatible shader position path; no false claim of exact normal equivalence.

### Separate P1b: native D3D candidate probe

Use the exact public2027 interfaces in [07](07_MAX_2027_INTEROP_FEASIBILITY.md). A null interface is a recorded outcome. Record `ID3D11GraphicsWindow` acquisition callback, adapter LUID, resource ownership and recreation behavior. Never cast internal handle storage. Only after this nonmutating probe is documented should a plugin-owned compute-written resource be attempted. Standalone sharing success remains a separate test record.

## P2 — Async lifecycle with a fake backend

**Inputs:** P0 snapshots; fake backend returning reference results after deterministic delayed completions; injected allocation/query/device errors. **Outputs:** publication/retirement event log and live allocation graph. No real GPU is required.

Use deterministic delay sequence `[3,1,5,2]` scheduler ticks; interleave requests A,B,C,Undo,source-replace,delete,reset. Move collider A, move collider B, then delete A before a completion; verify coalescing retains the union of dirty/restoration dependencies and the latest target values. Force each transition before/after capture, upload, solve, validation, completion and publication. Test backend service destruction while render readers hold accepted snapshots. Confirm cancellation stops further scheduling and retains allocated pages until simulated completion.

**Pass:** zero stale/partial publications, no source mutation, one pending/one in-flight cap, release of every owned allocation after readers finish, and last-good behavior matching [08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md). A counter-only test without held readers is insufficient.

## P3 — Matched static guide solver off-host

**Inputs:** S1/S2/S3s/S4, spheres/capsules/boxes and a small closed-mesh BVH, prepared root/binding data, static snapshot and budgets. **Outputs:** compact posed nodes/frames, whole-group visibility, status, actual residuals and work/memory metrics. CPU exact/reference validation is mandatory.

Implement the same bounded rest-based projection/optimization on CPU, CUDA and OpenCL. Start with independent chains; parent hierarchy is a second capability flag, explicitly distinguishing one-way attachment from coupled child-to-parent feedback. Do not replace it with dynamic hair settling. Worklist construction and visibility classification are identical across backends. A backend can return Unsupported for an unimplemented root-frame or binding mode; it cannot silently relax it or pass that capability's qualification by routing to CPU.

### A finite baseline to freeze before comparison

The first synthetic comparison may use the following **proposed, unexecuted** profile, `static_projection_v0`. It is a reproducible experiment choice, not an assertion that these coefficients converge on all fixtures or match current Cyrus code. P0 must instead freeze the actual CPU equations if strict current-implementation parity is the experiment.

```yaml
initialization: immutable_rest
supported_first_mode: PositionOnly_independent_chains
root_mobility: 0
free_node_mobility: 1
maximum_iterations: 64
maximum_backtracking_trials_per_iteration: 8
backtracking_factors: [1, 0.5, 0.25, 0.125, 0.0625, 0.03125, 0.015625, 0.0078125]
maximum_combined_node_proposal: 0.05_times_minimum_positive_rest_span
maximum_trial_node_motion_after_projection: same_cap_relative_to_iteration_start
rest_displacement_weight: 0.05
rest_curvature_weight: 0.20
soft_root_orientation: unsupported_in_first_profile
length_projection_sweeps_per_trial: 4
length_schedule: fixed_even_then_odd_edge_colors
contact_schedule: deterministic_Jacobi_gather_from_complete_sorted_witnesses
contact_relaxation: 0.8
contact_refresh: every_trial_and_after_every_projection_sweep
maximum_narrow_phase_evaluations_per_job: 10000000
maximum_contact_records_resident: 1000000
maximum_source_nodes_per_job: 262144
maximum_owned_gpu_bytes: 536870912
state_across_requests: none
```

Use `L` equal to the guide's rest arclength. Node displacement is normalized by `L`. For an interior node define rest-length-based discrete curvature

`D_i = L × [(x_(i+1)−x_i)/l_i − (x_i−x_(i−1))/l_(i−1)] / [(l_i+l_(i−1))/2]`.

The proposed rest energy is `0.05/2 Σ ω_i ||(x_i−x_i_rest)/L||² + 0.20/2 Σ ω_i ||D_i−D_i_rest||²`. Node quadrature weight `ω_i` is half the sum of its adjacent rest-span lengths divided by `L`; endpoints have one adjacent span. The curvature sum includes interior nodes only and uses those same weights without renormalizing that subset. Its coefficients are numerical artistic preferences, not material constants. Preserve the rest twist in frame reconstruction; the first profile does not independently optimize torsion or claim Cosserat-rod equivalence.

First perform complete initial collision and constraint checks. If rest passes, return the exact rest representation. Otherwise take one diagonally preconditioned gradient proposal for the quadratic rest energy: each free coordinate uses `−gradient / Hessian_diagonal`, with the diagonal computed from this same energy and rest coefficients. The positive displacement weight supplies a positive diagonal on admitted nondegenerate guides; reject nonfinite/invalid values rather than inventing a direction. Compute all local contact corrections from the same iteration-start pose with unit qualified normals and the witness formula in [05](05_COLLISION_AND_GUIDE_SOLVING.md), gather in stable feature order, and divide each node's gathered correction by the number of contributing violated constraints before the 0.8 relaxation. Sum rest and relaxed contact proposals, then cap the **combined vector** for each free node to `0.05 × minimum positive rest span`. Fixed roots have zero correction.

Each backtracking trial starts afresh from the unchanged iteration-start pose, adds its listed factor times that combined proposal, and applies four even/odd length sweeps. Restore fixed anchors after each color and refresh complete contacts after each sweep. Reject/backtrack a trial if any node's final displacement from its iteration-start position exceeds the same motion cap; length projection cannot silently evade it. Global barriers are explicit kernel boundaries. An incomplete query aborts the trial/job; it cannot supply a merit value indicating clearance. Unknown/zero-gradient contacts are diagnostic unless a separately specified qualified witness supplies a usable direction; no symmetry-breaking rule is implied.

Compare a fresh deterministic merit `E_rest + 10,000 × (sum of squared length residuals normalized by rest length + sum of squared clearance deficits normalized by L)`; the large penalty is a search heuristic, while actual hard acceptance remains [09](09_MEMORY_PRECISION_AND_HARDWARE.md). Choose the first strictly improving admissible trial in the listed factor order; if a completely checked trial satisfies all hard acceptance tests, it can return a candidate even without a merit improvement. Keep the best completely evaluated candidate, but never publish it merely because it has the smallest merit. Count all initial/trial/sweep/final queries against the job cap. Before returning a search failure, check any fully evaluated best candidate against the hard acceptance contract using complete final queries within the remaining budget. If no admissible improving or feasible trial exists, return `LocalSearchStalled`; if no feasible candidate is verified within 64 iterations or the query budget, return work/search exhaustion. Neither status proves the geometry impossible. Any later alternate-direction search must get a new profile ID and an explicit shared budget before comparison.

### Concrete positive control

Use a 0.30 m straight eight-node guide at `(0, i×0.30/7, 0)`, envelope radius 0.004 m, fixed root `(0,0,0)`, contact gap 0.003 m, and sphere centre `(0.025,0.160,0)` radius 0.050 m. A separate reference pose rotated 20° toward negative X has exactly the same lengths/root and minimum centreline-to-sphere-centre distance about 0.0782 m, exceeding the 0.057 m envelope+gap requirement. It is an existence control, never the solver output supplied to a backend. Verify the actual polygon strip too. Repeat with offsets, rotations and positive uniform scale; freeze new exact arrays/hashes.

For a separate first-span orientation fixture, place a sphere at `(0.001,0.035,0)` of radius 0.008 m with the same root/lengths, 0.004 m envelope and 0.003 m gap. A straight clamped first span conflicts, whereas a 30° negative X rigid rotation has centreline distance `0.001 cos(30°) + 0.035 sin(30°) ≈ 0.018366 m`, greater than 0.015 m. PositionOnly must distinguish this from ClampFrame; an implementation that does not support ClampFrame says Unsupported rather than passing its capability gate. Preserve the centred variant `(0,0.035,0)` as a separate zero-gradient diagnostic/extension test: the rest span passes through the centre and the first profile does not promise a symmetry-breaking escape.

Proposed interface sketch, **not compiled code and not an existing Cyrus header**:

```cpp
struct FitRequestView {
    uint32_t abi_version;
    RevisionKey key;
    ImmutableSourceViews sources;
    ColliderWorldView world;
    ActiveWorkView work;
    FitSettings settings;       // explicit objective, root modes, gap
    ExclusionSettings hide;     // independent whole-root-group classification
    ResourceBudget budget;
};
struct FitResultHeader {
    RevisionKey key;
    ResultStatus status;       // Candidate != final surface-validated publication
    uint64_t nodes_written, contact_queries, bytes_owned, peak_scratch;
    ResidualSummary actual_final_residuals;
    uint32_t query_complete, numeric_valid, constraints_valid;
};
// No Max pointers, transient C++ containers, or GPU pointers in portable output.
```

Test clear rest, one-sphere known-feasible control, translated/rotated/scaled variants away from the nominal geometry, simultaneous obstacles, root-inside conflict, whole-span crossing, zero gradient, width-envelope failure, quaternion signs, cancellation, work overflow and input immutability. Use supplied feasible poses only as independent existence controls. Test same snapshot from different edit history.

**Pass:** every known-feasible synthetic control within the explicitly declared supported capability set must converge and be accepted only after actual constraints pass; no false clear in adversarial controls; incomplete queries cannot return complete candidate; bounded loops/counts/memory and deterministic status under limits. An unresolved status remains honest but fails a known-feasible capability gate. **Performance gate:** matched completed pipeline, including readback/validation/graphics upload where applicable, meets [10](10_BENCHMARK_AND_VALIDATION_PLAN.md). Unsupported features are counted and routed to CPU, without claiming the backend implements them.

## P4 — Field approximation with a measurable certificate

**Inputs:** one sphere and one watertight triangulated box with exact reference queries; a thin slab and narrow gap; local scalar fields at cells1/2/5/10mm, with explicit sign coverage/error. **Output:** query residual/uncertainty distributions and final exact audit outcomes, plus field build/update bytes and cost.

Compare exact segment/capsule queries against the proposed conservative sample/interpolation bound in [05](05_COLLISION_AND_GUIDE_SOLVING.md). Randomize sampling phase deterministically; include entire-span-inside and outside-band cases. Rigidly move and uniformly scale collider instances without rebuilding source fields; edit topology to force invalidation. Account for cell error in world units exactly once.

**Pass:** every returned Clear has a complete lower-bound clearance certificate; an interval straddling the clearance boundary returns uncertain/refine, including within the error band. Final accepted surfaces pass exact validation. An empirically low error on a few random points is not a certificate for an arbitrary mesh/SDF generator. **Reject:** underresolved geometry or unreliable signs used as final clearance proof; keep it preview-only or use exact fallback.

## P5 — Delivery and integration parity

**Inputs:** one complete accepted packet from each supported lane; actual selected Max2027 renderer/exporter versions; static time and requested subframes. **Output:** viewport/Bake/export/reference-render geometry and diagnostic manifest, not merely screenshots.

Compare positions, indices, UV corners, normals/tangents, material slots, visibility, roots, attachments, bounds and instance identity before shading. Then test materials/opacity and renderer-specific semantics. Use large coordinates and source scale variants. Cancel a render during pending compute and verify no dangling snapshots. Save/reopen; transient GPU state is rebuilt, authored state preserved. Explicitly test no compute runtime and unsupported display adapter.

**Pass:** accepted geometry and renderer/Bake/export contracts agree, source remains unchanged, and final errors/pending state are surfaced. A visually plausible screenshot does not prove nonpenetration or publication safety.

## Required output of every local prototype

Record source/build hashes, exact command lines and environment, fixture fingerprints, inputs/outputs, stage traces, actual memory/query counts, numerical residuals, success/failure counts and known limitations. Keep failed runs. Distinguish standalone compute, standalone graphics sharing, supported in-Max drawing and renderer/export qualification as separate evidence classes. No gate can be marked Passed solely because the preceding gate passed.

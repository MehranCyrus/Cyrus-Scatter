# Cyrus vegetation core — owner B static rooted fitter

**Edition:** `CyrusScatter_Vegetation_Core_Handoff_v1`  
**Role:** B; independent implementation of `fit_rooted_guide`  
**Starting frozen header SHA-256:** `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`

This module implements a bounded, synchronous, one-way static fit of one prepared
rooted polyline around a fixed `CollisionWorld`. Each call starts from the supplied
immutable rest guide. It returns a private guide candidate or a diagnostic result;
it has no scene handles, timeline, renderer, publication callback or persistent
warm-start state. Only this directory is owned by B. The shared header, scaffold,
fixture catalog and research originals are unchanged.

`ConvergedCandidate` means that B completed its guide-envelope collision and
constraint checks. **C must still independently evaluate and validate the visible
mesh.** This module contains no mesh-validated flag. It cannot inspect actual
bound vertex offsets, source topology, triangles, UVs or renderer geometry.

## Build and interface

Requirements: C++20, CMake >= 3.20, the unmodified handoff starter tree. There are
no downloaded or linked numerical dependencies. The only linked target is the
frozen `cyrus_prototype_contract` interface target. No A, C, Jolt, Max SDK or
production plugin implementation is needed.

From the handoff root:

```sh
cmake -S docs/research/vegetation-core-handoff/starter \
  -B docs/research/vegetation-core-handoff/starter/fitter/build-release \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build docs/research/vegetation-core-handoff/starter/fitter/build-release --parallel 4
ctest --test-dir docs/research/vegetation-core-handoff/starter/fitter/build-release \
  -R '^fitter_' --output-on-failure
```

Exported target: **`cyrus_vegetation_fitter`** (static library). Entry point:

```cpp
cyrus::vegetation::prototype_v1::SolveResult fit_rooted_guide(
    const RestGuide&, Generation, const CollisionWorld&,
    const SolveOptions&, Cancellation);
```

Use the namespace declarations and exact signature from the frozen header. The
private math header is implementation detail. All test names start with `fitter_`.
With GCC/Clang, `-DCYRUS_FITTER_SANITIZERS=ON` enables AddressSanitizer and
UndefinedBehaviorSanitizer on the library and both test executables. Assertions in
the test harness use throwing checks and remain active in Release.

`tools/run_checks.py --cmake /path/to/cmake --compiler /path/to/c++` reproduces
Release and sanitized Debug runs and writes actual receipts to `evidence/executed`.
It is a GCC/Clang-style command runner, not an MSVC qualification script. Its
default build directories are inside this module and are excluded from the ZIP.
Retained execution logs and `execution_summary.json` establish observed results;
commands printed in this README are instructions, not execution evidence.

The retained run passed all 19 tests in Release and all 19 with ASan/UBSan in
Debug when `ASAN_OPTIONS=detect_leaks=0:halt_on_error=1`. The original
`detect_leaks=1` run failed with LeakSanitizer process-inspection errors; that log
is retained and leak checking is **not qualified**. Reproduce the successful
sanitizer profile in this restricted environment with `--profile sanitized
--leak-detection off --evidence-dir /new/evidence/directory`. Both profiles used
the same compiled-source hashes. See `evidence/VALIDATION-NOTES.md`.

## Supported root modes

| Mode | Position / first span / material frame | Root-angle metric |
|---|---|---|
| PositionOnly | `x[0]` equals rest exactly. Node 1 is movable, so the first span may rotate. Root frame follows the current first-span tangent using the shortest swing from its rest frame. | Sign-invariant quaternion geodesic angle between fitted and rest root frames. It is measured, not constrained to zero. |
| ClampFrame | `x[0]` and `x[1]` equal rest exactly; the root material quaternion is retained exactly. With fixed first-span length, fixing its direction also fixes node 1. Later nodes may bend. | Same geodesic angle; candidate also checks first-span direction error against `frame_radians`. Both are zero up to floating arithmetic in implemented fixtures. |
| SoftFrame | **Unsupported**, including when an angle weight is supplied. No substitution by PositionOnly. | Unknown: no solved pose or angular compliance is claimed. |

`root_angle_weight` is admitted as finite and nonnegative but is unused in the two
supported hard policies. Its intended finite-compliance mode is not implemented.
Position anchoring alone never implies angular anchoring. Fixing only the root
quaternion while allowing the first span to turn would violate tangent alignment;
ClampFrame explicitly constrains both.

## Admission, identity and contact trust boundary

Admission checks all eight nonzero `Limits` fields; array counts; node budget;
nonzero guide/source/generation identity; positive finite tolerances and maximum
proposal; finite nonnegative clearance/weights; mode enum; finite positions;
positive finite span lengths and radii; nonnegative offsets; and
`span_radius_m >= max_bound_offset_m`. Radius plus clearance must remain finite.
`frame_radians` must be less than pi. Coordinate subtraction and norm results are
checked, not just the original components.

Frames use xyzw active rotations, with local +Z along the contract node tangent:
the end span direction, or the normalized sum of adjacent unit span directions.
Quaternion norm error is admitted within `1e-10`; tangent angular error uses the
supplied tolerance. Near-antiparallel tangent sums and transports are explicitly
unsupported. Adjacent frame rotations at pi are rejected using an absolute
normalized quaternion-dot threshold of `1e-12`. Hidden full turns require
information absent from v1 and return Unsupported.

Numeric/frame admission precedes solver-sized reservations. Bounded sorted ID
scratch then verifies unique nonzero node and span IDs in their separate
namespaces before allocating the remaining buffers. Arithmetic size overflow is
rejected. Semantic array order, node count, span count and all caller inputs remain
unchanged. B can validate a nonzero source revision and echo it; checking it against
an external prepared mesh revision belongs to the coordinator/C because that mesh
is not an argument to B.

One complete root-envelope classification, at radius `span_radius_m[0] + clearance`,
provides the obstacle-ID roster. Inside/penetrating fixed-root envelopes return
RootConflict. Ambiguous and unsupported classifications stay non-success. All
subsequent spans are queried as **whole capsules**, using radius and clearance
separately and exactly once. There is no endpoint-only shortcut.

Every contact is retained within the declared capacities and checked for known
obstacle/guide/span IDs, qualified witness, finite `u` in [0,1], finite points, unit
outward normal, `axis_point = (1-u)a + u b`, and the signed-gap equation:

```text
g = n dot ((1-u)a + u b - obstacle_point) - radius - clearance
```

Equation/axis consistency tolerance is `128*double_epsilon*coordinate_magnitude`
plus `0.01*min(penetration_m, rest_reconstruction_m)`. It does not relax the final
penetration threshold. The more negative of reported and recomputed gap is used.
Zero normals, invalid fractions, inconsistent gaps, unqualified witnesses,
incomplete results and ambiguity cannot yield a candidate. Rows are sorted by
stable identities and witness values for reproducible local ordering.

B verifies local algebra. It cannot prove that an opaque backend's claimed
obstacle point is on its surface, that an outward normal is geometrically correct,
or that a response marked complete actually contains every required contact. A
qualified backend is a necessary integration dependency. The test world's geometry
and oracle are authored independently of the production private helpers.

## Declared numerical method

This is **alternating projected feasibility search with rest/bend regularization**,
not time integration or a material simulation. The original polyline discretization
is retained. There is no resampling, time step, velocity, acceleration, mass,
damping, friction, self-collision, vegetation deletion or random reseeding.

Let `r_i` be immutable rest nodes and `x_i` trial nodes. The recorded rest objective
is the actual value of

```text
E(x) = 0.5*w_rest * sum_i |x_i-r_i|^2
     + 0.5*w_bend * sum_interior_i |D2(x)_i-D2(r)_i|^2
D2(x)_i = x_(i-1) - 2*x_i + x_(i+1)
```

Each supported call proceeds as follows:

1. Admit input and memory, copy immutable rest into private result storage,
   classify the root, then audit every capsule and all geometry constraints.
   An already-clear guide returns **exact rest coordinates and original quaternion
   representatives**, including their signs, with zero iterations and objective.
2. Apply a normalized gradient step toward the rest objective. Its effective
   coefficients are `0.2*w_rest/(w_rest+16*w_bend)` and
   `0.2*w_bend/(w_rest+16*w_bend)`, evaluated by first scaling the weights to
   avoid overflow. Both zero means no regularization. Node steps are capped.
3. Refresh every whole-span query at that regularized proposal. For each local
   row, recompute its gap after preceding row corrections and project penetrating
   rows with endpoint mobilities 0 for fixed nodes and 1 for free nodes.
4. Apply 20 alternating forward/backward length sweeps toward every original rest
   span length, resetting exact anchors after each sweep. A collapsed trial span
   uses its rest direction. Both contact and length corrections are capped.
5. Cap the complete outer proposal: no node moves more than
   `max_proposal_step_m` from the last installed private pose. Regenerate frames.
   At most 12 proposal halvings repair an invalid frame/geometry chart; this is
   **not** an energy or collision-merit line search.
6. Refresh **all** capsule contacts again after the last position change. Compute
   actual root, relative-length, root-angle and objective residuals. Only a complete
   final audit can install that proposal as the new diagnostic pose or candidate.
   Accept the first pose meeting the declared guide constraints; otherwise repeat
   within iteration/query budgets.

For a locally frozen witness, endpoint coefficients are `(1-u)` and `u`.
The hard projection denominator is `D = mobility0*(1-u)^2 + mobility1*u^2`.
The implementation scales by the largest movable coefficient before division so
that a tiny nonzero coefficient is not squared into a false zero. An actually
zero movable gradient with penetration beyond tolerance is an explicit local
RootConflict. No fictitious epsilon mobility releases a planted node. Per-row
endpoint motion and cumulative contact-pass motion are capped by the proposal
limit. A witness is discarded at the next refresh; it never becomes a persistent
surface attachment.

The `0.2`, `16`, 20 sweeps, 12 halvings and binary mobilities are numerical choices.
The two user weights are experimental artistic regularizers, **not real material
properties**. This index-based second difference is not an arc-length-normalized
elastic rod constitutive law. Uneven sampling changes its response. Increasing
all positive weights together leaves the normalized proposal unchanged but scales
the reported objective. Increasing contact pressure may increase rest energy;
there is no monotonicity, stationarity, unique-answer or global-minimum claim.

The regularizer supplies a preference for the original position and curvature;
the exact-rest early exit prevents gratuitous bending in clear cases. Finite
contact and length constraints can require substantial deviation. Static iterates
need not trace a physically collision-free motion path; the acceptance condition
is the final pose. A failed bounded search is not proof that no feasible route
exists. The supplied feasible pose is a separate positive control and is never
passed into the production solver.

## Frames and width

Rest frames are aligned to their admitted node tangents for incremental transport
calculation. Adjacent rest frames determine a shortest incremental roll after
minimal tangent transport. Deformed frames propagate that same roll along the new
tangent field. Every generated quaternion is normalized; equivalent signs are
chosen continuously. A near-antipodal transport is rejected/backtracked, not given
an arbitrary perpendicular axis. The tested nonzero-roll fixture verifies this
branch separately from q/-q sign tests.

The conservative per-span capsule radius contains the declared full bound-offset
norm. This is an orientation-independent envelope: a thin ribbon might fit edge-on
where its enclosing capsule cannot. B does not rotate ribbon edges independently
to exploit such a gap. Rest lengths are enforced to `relative_length`; root error
is checked against `root_m`, and actual unit/tangent/frame constraints use the
declared angular tolerance. C remains responsible for the sampler, original full
offsets, mesh reconstruction, visible geometry and independent final validation.

## Bounds, cancellation, metrics and failures

Worst-case contact-row reservation is `(node_count-1)*max_contacts_per_query`.
All large reservation arithmetic is checked before allocation. Private arrays use
a budget-checking allocator, output pose capacities are accounted explicitly, and
incoming response capacities are inspected before consuming their contents.
Returned issue arrays are capacity-admitted first; issue strings are then counted
incrementally with cancellation between entries. A rejected large response may
have only a partially observed string payload, which is recorded honestly.

`peak_owned_and_scratch_bytes` is the high-water **accounted payload**: requested
private buffer bytes, public pose capacity, observed response vector/string
capacity, the context size, and an 8,192-byte conservative allowance for bounded
diagnostics/small local state. It is not a measured allocator/OS/process peak.
The fixed allowance is an accounting bound; small-string capacity may be counted
conservatively even when inline. Borrowed input arrays, persistent world storage,
allocator overhead and opaque backend scratch are outside this B metric.
Before working storage is admitted, the context size is the recorded known
payload; residuals may still be unknown. With an impossibly tiny requested budget,
even the fixed stack context exceeds it and the call returns WorkLimit.

The frozen interface returns owning vectors after the backend has allocated them.
Their capacity, or earlier opaque scratch, can exceed the requested aggregate
budget before B can reject it. The observed peak can consequently exceed the cap
on that failure path. If B stops during an over-budget response inspection, the
metric records the inspected payload, not unvisited strings. A strict aggregate
allocation cap cannot be promised under v1; see `CONTRACT_CHANGE_REQUEST.md`.

Every virtual query attempt counts, including failed and final-audit queries.
Maximum successful-call query usage is bounded by
`1 + (N-1)*(1 + 2*max_iterations)` and also by `max_query_calls`; early failures
use fewer. Numeric loops check cancellation/generation at node/span/contact or
sweep boundaries; sorting checks at most every 64 comparisons. Standard-library
allocation/copy operations are bounded by admitted arrays but cannot be interrupted
inside the allocator/copy. Backend latency depends on its cancellation contract.

Generation is checked before/after queries, in bounded numerical loops and before
candidate acceptance. Backend response generation must match too. The caller must
provide an immutable snapshot for that generation and recheck job/source/world
versions before publication. Merely checking a number cannot make an illegally
mutating backend coherent.

If a new trial scan fails, the previous completely audited private pose and its
actual geometric/collision residuals are retained. Work counters include the
failed trial. Before any complete audit, penetration is `+infinity` and unresolved
contact count is `size_t::max()`; `CollisionMetricsUnknown` is supplied when the
diagnostic allowance permits. Floating residuals with no admitted pose also use
`+infinity`. Test JSON serializes unknowns as `null`. No unmeasured zero certifies
clearance. Successful residuals are independently recomputed in the test harness.

| Status | Meaning here |
|---|---|
| ConvergedCandidate | Complete final guide audit and constraint checks passed; C validation still pending. |
| RootConflict | Fixed root-envelope conflict or actually immovable local endpoint gradient. The local form is not a global infeasibility theorem. |
| UnresolvedContact | Incomplete/ambiguous/unqualified/inconsistent contact, invalid numerical trial, or exhausted local frame chart. |
| InvalidInput | Malformed contract values, mismatched generations, or backend input rejection. |
| Unsupported | SoftFrame, full-turn twist, unsupported transport chart/backend profile. |
| WorkLimit | Iteration/query/node/contact/obstacle or accounted memory bound reached. No feasibility claim. |
| Cancelled | Cancellation observed; no candidate accepted. |
| AllocationFailure / InternalError | Allocation or unexpected/backend failure. Diagnostic data only. |

## Tests, evidence and limits

The test suite includes catalog clear/rest, known-feasible one sphere, root-inside,
whole-segment crossing, invalid and admitted width envelopes, simultaneous spheres
and rotated boxes, fixed-span gap conflict, cancellation, work limits, returned
capacity inflation, generation changes, malformed witnesses, q/-q, nonzero roll,
root modes, repeated calls, source/options immutability, transformed/scaled geometry,
different discretization, numeric admission and tight-memory admission order.
The standalone analytic oracle has exact controls and an independent dense-sampling
Lipschitz check. See `tests/README.md` and retained execution receipts.

Evidence categories remain separate: source reviews in `evidence/*review.md`;
authored fixture/analytic controls; actually executed C++ tests in
`evidence/executed`; and proposed future contract experiments. Historical R11–R14
report results are background evidence only and are never counted as current
module passes. No performance benchmark or throughput target is claimed from
CTest wall times.

Current qualification is the recorded Linux/GCC build and synthetic patch-local
metre-scale fixtures. The math uses doubles but there is no universal scale range
or robustness proof for subnormal/astronomical coordinates, dense production
assets or arbitrary obstacle backends. Overflow/invalid charts stay diagnostic.
Float conversion, rebasing, open/triangle-mesh solid semantics, obstacle admission
and shape construction belong upstream. Large-origin/millimetre production,
Windows/MSVC, Max 2027, intended renderer, A/C integration, visible-mesh validation,
threaded orchestration and production performance are **Not executed** here.

Integration: merge this directory only, build its exported target through the
frozen scaffold, provide a qualified immutable CollisionWorld and prepared rest
guide, call synchronously, and pass only a current ConvergedCandidate to C. The
coordinator owns generation rechecks and atomic publication. Moving a stone
invalidates dependent placement results; the next call solves again from rest.

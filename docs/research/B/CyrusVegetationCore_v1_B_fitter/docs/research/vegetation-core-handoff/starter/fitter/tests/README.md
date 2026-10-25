# Owner B independent fixture tests

These tests use only the frozen C++20 contract and B's fitter. `analytic_world.hpp`
is authored test code, not owner A's backend, a Jolt adapter or owner C's mesh
validator. No historical report-local result is counted as a run of these tests.

`fitter_tests <case>` uses explicit checks that throw on failure; assertions are
not disabled in Release builds. `tests/CMakeLists.txt` registers 18 fitter cases
and one additional analytic-oracle qualification case. The parent module's real
execution logs, rather than this file, establish which runs were performed.

JSON records encode nonfinite/unknown numeric metrics as `null`, never zero.
`collision_metrics_complete` describes the native guide audit of the returned
diagnostic pose; it is not a mesh-validation flag. When a successor scan is
interrupted, a reported complete metric may belong to the retained previously
audited pose, as documented by the fitter. The work-limit group also returns an
oversized contact-vector capacity with a small valid element count to check
post-query memory admission, rather than checking only vector size.
The admission-order case combines a tight nonzero memory budget with invalid
coordinates/radii/frames and unsupported twist charts: data rejection must occur
before large solver reservations and before any collision query. Both executables
are instrumented when `CYRUS_FITTER_SANITIZERS` is enabled on GCC or Clang.

## Positive checks

`one_sphere` reconstructs catalog F02's guide, obstacle and settings. It requires
`ConvergedCandidate`, then measures complete segment/primitive clearance, exact
root equality, relative span-length errors, unit tangent-aligned frames,
root-angle residual, counters, finite objective, budget compliance and input
immutability. A failure status is a failed positive test. The tests never pass
the supplied authored feasible answer into the fitter.

`positive_control` constructs the supplied 45-degree-away pose only as an analytic
existence/control test; its output explicitly says `fitter_executed=false`.
Other required-success tests include a whole crossing single span, a correctly
admitted wide envelope, two simultaneously contacting spheres, two rotated boxes,
a translated/rotated/scaled fixture, a new seven-node geometry and a clamp-mode
fixture with a clear initial span. Empty, clear nonempty and curved clear cases
must preserve rest coordinates exactly.

The sphere oracle is the analytic minimum distance from the obstacle center to
the complete finite segment. OBB tests minimize signed box distance along the
segment: outside intervals have quadratic squared distance, and inside distance
is the maximum of six affine functions. All interval boundaries, stationary
points and affine intersections are examined. `fitter_analytic_oracle` tests
known exact controls, rigid-transform invariance, surface/gap equations and a
separate dense-sampling Lipschitz bound. This is a guide-envelope oracle; it
does not inspect actual visible triangles or replace C's validation.

## Deterministic fixture geometry

- Catalog baseline: 9 nodes, 0.075 m spacing, root (-0.2,0,0), radius 0.015 m,
  clearance 0.005 m; sphere center (0,0.2,0), radius 0.25 m.
- Two spheres: 10-node guide rooted at (-0.25,0,0), spacing 0.075 m; centers
  (0,0.25,-0.065) and (0,0.25,0.065), radii 0.27 m. A 45-degree-away straight
  chain is an independently checked existence control. At least one query must
  retain both obstacles' contacts.
- Two rotated boxes: same guide; centers (0,0.22,-0.05) and (0,0.22,0.05),
  half-extents (0.28,0.07,0.09), Z rotations +0.18 and -0.18 radians. The same
  authored control is checked before requiring an independently computed fit.
- Blocked control: ClampFrame freezes the first 0.4 m span along +Y. Two boxes
  centered at x=+/-0.12,y=0.25 with half-extents (0.1,0.05,0.1) leave a 0.04 m
  gap for a 0.05 m diameter capsule. The root itself is clear; the unchanged
  first span contacts both boxes. This is a local clamped-span contradiction,
  not a claim that an unconstrained guide has no path around the boxes.
- Clamp feasible control: root (-0.18,0,0), 9 nodes at 0.075 m; sphere center
  (0,0.35,0), radius 0.22. The first span remains vertical and clear; later
  spans may bend away. SoftFrame must explicitly return Unsupported in this
  implementation edition.
- Away fixture: rotate catalog geometry by 0.7 rad around normalized (1,2,3),
  scale dimensions/clearance/proposal by 1.7, translate by (0.45,-0.2,0.7), and
  change semantic IDs, source revision and world generation. A second fixture
  has 7 nodes at 0.067 m, root (-0.14,0,0.03), radius 0.012 m, clearance 0.003 m,
  sphere center (0,0.16,0.03), radius 0.16 m.

## Rejection and lifecycle checks

Root containment, insufficient width envelope, mismatched/changing generation,
all zero limits, tiny memory/query/iteration/contact/obstacle budgets,
nonfinite/count/ID/revision/frame errors, hidden full turns, cancellation before
and during queries, incomplete/ambiguous/malformed results, query exceptions and
a qualified zero-denominator clamped-span conflict cannot return a candidate.
Quaternion sign changes must preserve geometry. Repeated calls start from rest;
moving the test obstacle away must restore exact rest rather than retain a prior
bent result. These tests cover B's part of F09, not A's owned-world lifetime tests.

The frame case also adds authored roll `0.25 + 0.08*i` radians to catalog F02's
node frames. It requires a successful fit with the same centerline as the
untwisted case, and independently measures each incremental roll after minimal
Rodrigues transport of the preceding material X axis. The 0.08-radian increments
must survive deformation; this does not claim support for hidden full turns.

The local-conflict case retains the genuine zero-mobility clamped-span test and
adds a synthetic locally consistent witness with positive `u=1e-200` and a fixed
root. Squaring this coefficient underflows in binary64. With a two-iteration
limit, it must return WorkLimit or UnresolvedContact, never classify the positive
coefficient as an exact zero-denominator RootConflict. The fake roster/row do not
claim to describe a physical primitive scene or establish feasible geometry.

The analytic world's counters and temporary query storage are test-backend
resources, outside B's allocator ownership. The frozen interface does not let B
cap allocations performed inside a third-party virtual world call. That boundary
must remain explicit in the module's memory-accounting documentation.

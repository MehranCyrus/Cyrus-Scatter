# Independent numerical/source review — owner B

**Review type:** independent source and contract inspection. This review did not
compile or execute the C++ module, run A or C, validate a rendered mesh, or measure
performance. Execution claims belong to the retained build/test receipts, not to
this document. Reviewed files: `fitter.cpp`, `private/math.hpp`, the frozen shared
contract/header and the analytic test definitions.

The frozen header inspected by this reviewer is edition
`CyrusScatter_Vegetation_Core_Handoff_v1`, SHA-256
`f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`.

## Numerical interpretation

The implementation is a bounded alternating projected feasibility search with
rest/bend regularization. It has no velocity, timestep or retained deformed state.
Its second-difference objective is expressed in guide index space, so changes in
sampling or unequal span spacing change that artistic regularization. The
coefficients are not calibrated material properties.

The normalized gradient step is bounded before the first trial query. Contact
corrections, twenty alternating length sweeps and a cap on the complete proposal
then produce the next trial. Frame-chart backtracking can shorten that proposal.
A complete refreshed capsule scan follows all those geometric changes before
installation or success. This is the appropriate ordering for the chosen local
model.

There is no objective/merit line search proving monotonic decrease of penetration
or rest energy. The frame backtracking checks representability, not optimality.
The first candidate meeting the explicit collision and constraint tolerances may
be returned. It must not be described as a stationary point, minimum-energy pose,
unique fit or proof that a failed search has no solution.

## Root and first-span semantics

- PositionOnly copies the planted point exactly while allowing the first outgoing
  span to rotate. Regenerated root orientation follows its tangent; it is not a
  disguised clamp.
- ClampFrame fixes the first two nodes to their rest positions and keeps the root
  frame exactly. This fixes the initial span direction and length. Its positive
  fixture must have a clear fixed initial span; the catalog's PositionOnly
  rotated control is not such a fixture.
- SoftFrame is explicitly Unsupported. The supported modes do not implement a
  finite root-angle penalty, and should not claim that `root_angle_weight` changes
  their behavior.

Root-envelope classification and a penetrating local row with zero movable
endpoint denominator can establish a local rooted conflict. Neither establishes
global infeasibility of a different root policy or geometry representation.

## Contacts and trust boundary

The production code queries complete spans, keeps all returned rows, validates
semantic IDs and local witness algebra, and sorts rows deterministically. It
recomputes a frozen-plane gap as endpoints move during the row sweep, then
performs fresh world queries. This avoids treating material fraction and witness
as permanent attachments. Opposing contacts remain separate constraints.

B cannot independently establish that an obstacle witness lies on its primitive:
the frozen `CollisionWorld` interface does not expose obstacle geometry. Its trust
boundary therefore includes the backend's qualified/complete contract. The
independent analytic tests check their own backend mathematics; they do not
qualify A's implementation. A candidate still needs C's independent visible-mesh
validation and coordinator generation/source checks.

The result retains its last fully audited pose until a complete trial succeeds.
A query failure during a new proposal therefore does not attach old residuals to
unexamined new positions. Before the first full audit, collision metrics must be
explicitly unknown. Root admission, malformed witnesses, cancellation, capacity
limits and incomplete queries must never produce ConvergedCandidate.

## Frames and supported chart

The deformed frame construction uses tangent alignment, sequential transport and
stored incremental rest roll. Quaternion hemisphere choices affect representation
only. The root-angle metric uses a sign-invariant quaternion geodesic; ClampFrame
also checks the outgoing direction.

Undefined tangent bisectors, near-antipodal transport and ambiguous adjacent pi
rotations are explicitly rejected/backtracked. This is a restricted numerical
chart, not support for every possible guide fold or hidden full turn. Unchanged
clear data returns the supplied quaternion representatives exactly, which is
appropriate for the rest-preservation contract.

The test definitions include straight untwisted, quaternion-sign and globally
rotated cases. Following review, a low-twist deformed F02 control was added. It
checks unchanged centerline response and preserved 0.08-radian incremental roll
using independent vector/Rodrigues transport, rather than the fitter's quaternion
helper. Execution of the added test was still pending when this reviewer inspected
the change; use the final retained test receipts for its observed outcome.
Full-turn support remains outside this edition regardless of that outcome.

## Actionable disposition

The two reported admission/metric issues are corrected in the source inspected
in the follow-up review. Numeric, tangent/frame and unsupported-mode checks now
precede solver-sized reservations. A bounded sorted-ID scratch buffer admits
uniqueness before the other buffers are created. An unmeasured unresolved-contact
count uses `size_t::max()` alongside infinite unknown floating residuals, including
the outer fallback path. Tight-memory malformed-input test definitions were added;
their execution was still pending at this review boundary.

The follow-up also accounts external query payloads incrementally, checks
cancellation between issue strings, and checks cancellation/generation every
64 sort comparisons. These changes preserve failure-only behavior on incomplete
or stale work. Accounting still cannot preempt allocations performed inside the
opaque backend or measure its hidden scratch usage; that frozen-interface
limitation remains explicit.

No additional false-acceptance or root/frame/contact-order defect was identified
in this source review. This is a scoped review conclusion, not a correctness proof
for arbitrary geometry, discretization, numeric range or backend behavior.

# Owner B — independent contract and evidence review

## Scope and identity

This note records source/document inspection for owner B's static rooted fitter.
It is not an execution receipt. Test results, compilation and numerical residuals
belong to the implementation owner's separate logs. No historical report result
is promoted to a newly executed B, A, C, Max, renderer or performance test here.

Edition: `CyrusScatter_Vegetation_Core_Handoff_v1`.

The actual input header SHA-256 is
`f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`.
All four frozen input files were rehashed and matched the supplied manifest:

| Frozen file | Bytes | SHA-256 |
|---|---:|---|
| `SHARED-CONTRACT.md` | 12222 | `61463bdf7e354b31191b6d9030686eb1ab0d8c1b83d6a7e4167713e92bdf2d80` |
| `starter/include/cyrus_vegetation/prototype_v1.hpp` | 8709 | `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f` |
| `starter/CMakeLists.txt` | 594 | `61df6a0f24d23c3183168577eaf3e36a21b0210fac79d0148e49c94c8b1bb086` |
| `fixtures/catalog.json` | 20047 | `0cbbaf16cbe619ba638048f58b35e534720b44b7a7a60a26ca5e05b0b9b04c7f` |

Reviewed inputs: frozen contract/header, catalog, owner-B prompt, return checklist,
synthesis chapters 01/03/04/05/07/08/09, R11–R14 evidence-review scopes/findings/
limitations, and relevant preserved original sections. Original sections included
R11's canonical evaluator/root/frame/invalidation discussion, R12's static
fitter and failure contract, R13's proposed static architecture, and R14's
whole-span witness, local projection, static fitter and lifecycle sections.

## Which prior evidence informs B

| Source | Evidence used | Boundary retained |
|---|---|---|
| R11 | Fixed material coordinates, complete offsets, root position versus orientation, quaternion winding ambiguity and reconstruction | Supplied representation arithmetic does not implement source extraction or collision fitting. The v1 frozen sampler rejects full turns and is narrower than the report's unwrapped-twist example. |
| R12 | Rooted static fitting and whole-span contact are separate from stock CPU rod mechanics | Source-only report; its proposed experiments were not runtime results. |
| R13 | Segment/width/containment counterexamples and scale-qualified query requirements | Its stored native results are from a separate Linux/GCC double-world-position build. A clamped one-rod detection case is not a feasible-routing test. |
| R14 | Qualified local witness fractions, endpoint gradients, zero denominator, coherent generations and bounded lifecycle | Its native/analytic receipts are distinct profiles; the local frozen-witness equation is a proposed ingredient, not a completed optimizer. |

As a limited source recheck, the accessible exact-pin Jolt files were inspected:
`Core.h:8–10` identifies 5.6.1;
`SoftBodyMotionProperties.cpp:257–265` calls `CollideSoftBodyVertices`;
`SoftBodySharedSettings.cpp:471–480` derives orientation inverse mass from endpoint
minimum inverse mass. These facts explain why B owns its response. B's public
implementation does not call or depend on Jolt; its math is defined by the frozen
CollisionWorld contract, so no engine contact sign or COM assumption is imported.
No engine source/build experiment was executed by this review.

## Required admission and result invariants

- Check every `Limits` member for nonzero values, even render limits unused by B.
  Validate counts against node/obstacle/contact and checked byte arithmetic before
  large allocations. Do not allow `size_t` multiplication/addition wraparound.
- All IDs and generation/source revision values must be nonzero. Node and span
  IDs are unique in their respective namespaces. Semantic order is retained;
  no resampling, deletion, reseeding or index permutation is silently introduced.
- Finite input components are not sufficient: subtraction, length, radius plus
  clearance, weighted objective and correction arithmetic must remain finite.
  Unsupported numerical ranges need an explicit non-success result.
- Validate positive span radii, nonnegative finite bound offsets and
  `span_radius >= max_bound_offset`. B cannot independently inspect the actual
  mesh offsets because they are not in its signature; C owns that verification.
- Unit xyzw quaternions must align local +Z with the contract's node tangents:
  endpoint span direction, or the normalized sum of incoming/outgoing unit
  directions. Reject zero spans, antiparallel bisectors and ambiguous pi relative
  frame rotations. `requires_full_turn_twist` must produce Unsupported.
- Preserve the planted root exactly for all supported modes. A tolerance is an
  acceptance comparison, not permission to move the anchor deliberately.
- `source_revision` can be checked for nonzero and echoed by B. A match against a
  PreparedRibbon's revision is C/coordinator work because that source is absent
  from B's inputs.

## Contact, generation and acceptance traps

Every root point-classification and span query counts toward the query budget,
including final checks and failed backend calls. Check requested/world generation
before and after calls, response generation, and generation again before returning
ConvergedCandidate. The world contract must hold one immutable geometry generation;
checking the number does not repair a backend that mutates geometry under it.

A successful complete root classification supplies an obstacle-ID roster. Check
nonzero unique IDs and obstacle count; validate subsequent contact IDs against
that roster. Check qualified witness flag, guide/span IDs, finite u in [0,1], unit
normal, `axis_point = lerp(a,b,u)` and the signed-gap equation using radius and
clearance exactly once. B can check these local consistencies but cannot prove
surface membership or query completeness independently of an opaque backend.

Retain all relevant contacts and use deterministic ordering. A frozen witness is
valid for a local correction only. Refresh after finite updates; length or bend
projection can reintroduce contact, so a final complete scan must follow the last
geometry change. A contact correction with zero denominator is a local immovable
conflict, not a denominator to regularize into apparent success. A nonzero but
tiny denominator needs bounded motion and finite arithmetic, not a fabricated
global infeasibility claim.

For a static final-pose contract, intermediate optimization iterates need not
trace collision-free animation. Whole-span coverage certifies a pose, not swept
bending through time. Do not add an unrequested dynamic/CCD guarantee.

Root-angle error is the sign-invariant geodesic quaternion angle, using the
absolute quaternion dot product after valid normalization. ClampFrame also checks
the first directed span. Missing root modes must be Unsupported. Regenerated
frames must be unit and tangent-aligned; sign continuity may choose equivalent
representatives, but already-clear output should preserve original rest values
exactly, including quaternion signs.

If a budget or cancellation interrupts a scan, returned diagnostic geometry can
still have actual root/length/frame measurements. Contact metrics must be labeled
partial/unknown or refer to a retained fully checked pose; a default zero must not
be described as an established final maximum penetration. Only a complete final
scan plus mandatory constraint checks can produce ConvergedCandidate.

## Interface limitation requiring an explicit coordinator decision

The frozen interface cannot guarantee a strict aggregate peak allocation budget
across an arbitrary CollisionWorld implementation. Queries return owning vectors
and strings by value. The backend can allocate result/scratch storage before B
receives it; B cannot pass remaining bytes, contact capacity or a caller-owned
workspace into that call. The backend's retained memory, transient peak, configured
query tolerance and minimum-feature profile are not exposed. Inspecting returned
capacity is useful but cannot retroactively bound a backend's unseen temporary
allocations. `BackendIdentity` strings are descriptive rather than structured
admission metadata.

B should therefore bound and label its own dynamic buffers and known result
capacities, promptly reject oversized query responses, avoid unbounded diagnostic
copying, catch allocation failures, and state the trust boundary. An arithmetic
storage upper bound must not be labeled a measured allocator/process peak.

For a later coordinated edition, the smallest useful resource extension is either
(a) a query request carrying remaining byte/contact budgets and a backend-reported
peak, or (b) caller-owned bounded result/scratch spans with a status/count return.
Structured immutable backend admission metadata would also allow preflight of
query tolerance, feature range and compatible limits. The shared header must not
be changed by B; the owner's separate CONTRACT_CHANGE_REQUEST should record the
chosen request and affected over-budget fake-world test.

There is also a wording ambiguity: the last B paragraph of SHARED-CONTRACT says
not to report “convergence” when the independent mesh check is missing. The user's
explicit assignment permits ConvergedCandidate after B's own complete checks,
with C still required. Interpret that status as guide-candidate completion only;
do not add a mesh-validated flag or claim publication acceptance.

## Test and handback review priorities

F01 must preserve rest exactly. F02 must actually reach ConvergedCandidate with
independent geometric checks; accepting any failure status would not complete
that gate. The supplied 45-degree pose proves a local feasible control but must
never be fed to the solver as its answer. Add translated/rotated/curved or otherwise
different fixtures. Pair obstruction rejection with feasible controls. Report
multiple simultaneous obstacles, intermediate generations, incomplete/ambiguous
responses, cancellation, memory/contact/query/iteration limits, root conflict,
quaternion signs, zero-denominator conflict and repeated calls from rest separately.

Return only the owned module, root handback report and manifest. Preserve frozen
files unchanged. Include exact file hashes, actual compiler/commands/exit codes,
logs, coverage and numerical limits. C's independent triangle validation, A's
Jolt integration, Windows/Max/renderer and production throughput remain separate
Not executed items until their owners or coordinator run them.

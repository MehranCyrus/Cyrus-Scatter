# New collision adapter controls

`collision_tests.cpp` is a C++20 executable against the frozen public header.
Its separate `native_observations` case reads a private, thread-local diagnostic
receipt; the analytic controls neither use private geometry helpers nor link
a historical harness.
Run one named case, or run `cyrus_collision_tests all`; CMake registers the
individual cases with the `collision_` CTest prefix.

## Oracles and tolerances

The sphere and rigid oriented box controls compute expected geometry with
independent double arithmetic. The box tests use an independently implemented
active quaternion rotation and supporting-plane tests at all eight corners.
Every inspected contact must have a finite, unit, obstacle-outward normal,
a surface witness, a qualified material coordinate in `[0, 1]`, and an axis
point reconstructed from that coordinate. The signed gap must reconstruct
from the witnesses with the geometric radius and clearance subtracted once.

The ordinary exact controls allow `2e-10` numeric error. The tiny feature and
large translation controls declare separate tolerances in their source.
These thresholds measure the public adapter's refined analytic result. They
are **not** a claim that raw Jolt GJK witnesses have double precision. A sphere
center or a parallel box face can have a nonunique correct witness; those
cases check qualification and repeatability without inventing a unique normal
or material coordinate.

The reported `largest_expected_numeric_error` is the maximum absolute
difference among the case's numeric comparisons. Those comparisons include
positions, normals, gaps, and material coordinates; this value is not a single
physical error metric or a penetration residual.

## Case inventory

| Argument / CTest suffix | Controls |
| --- | --- |
| `identity_empty` | Exact dependency pin, declared precision and flags, complete empty world queries. |
| `point_sphere` | Interior, center, exterior, root exclusion radius, boundary tolerance band. |
| `point_box` | Rotated box interior, off-center interior, face/edge distance, exclusion band. |
| `capsule_sphere` | Side contact, clear control, endpoint and reversed endpoint, endpoints outside with crossing segment, wholly contained segment. |
| `capsule_box` | Rotated face and edge controls, separated face, complete crossing segment, wholly contained segment; 200 seeded boxes with 501 independent point-SDF samples per span. |
| `capsule_axes` | Both directions of all principal axes and an oblique direction, expected directed material coordinate. |
| `two_obstacles` | All relevant obstacles, irrelevant obstacle exclusion, caller IDs through sorting, input-order independence. |
| `invalid_inputs` | Invalid IDs/revisions, dimensions, quaternion, nonfinite active and inactive data, unknown shape kind, degenerate query. |
| `limits` | Every zero limit, memory and obstacle admission, contact overflow, per-operation native query budget, incomplete-empty is never clear. |
| `cancellation` | Already-cancelled build/query, empty scene cancellation, token reset. |
| `snapshot` | Caller geometry, pose, ID, revision and generation edits; caller vector destruction; independent successor generation. |
| `lifetime` | Two nonempty and two empty worlds, destruction in either order, survivor queries, subsequent lifetime acquisition. |
| `scale_profile` | Below-profile features, excessive dimensions/coordinates, short and long spans, admitted tiny features and large translation; incomplete ambiguity when the coordinate-dependent precision allowance exceeds the requested tolerance. |
| `repeatability` | Repeated immutable queries, equivalent quaternion signs, reversed input ordering. |
| `native_observations` | Actual native point/capsule dispatch and hit receipts; raw shallow-contact witnesses for sphere X/Z spans and rotated-box local Y/Z spans. |

## Scope

Cancellation controls use a token already set before the call. They do not
measure asynchronous cancellation latency. Lifetime controls exercise one
standalone process and do not establish cross-DLL host ABI safety.

The query budget is per public operation: one obstacle with a budget of one
can be queried repeatedly; two obstacles with a budget of one cannot produce
a complete result. The tests require failed, cancelled, or resource-limited
queries to have `complete == false` and empty result vectors.

Actual functional execution and compiler/build identity belong in the module's
return evidence. Merely having this test source or compiling it does not imply
any test passed.

The sampled OBB controls use a fixed integer generator and bounded geometry.
A sampled point in the contact band disproves a complete-clear claim. Positive
samples alone cannot prove that the continuous span is clear. Every returned
contact must additionally match the independent point SDF at its reconstructed
axis point. The requirement that its gap is no greater than the sampled
minimum validates this adapter's declared deepest-centerline-witness profile;
it is not asserted as a requirement on all conceivable CollisionWorld backends.
The sampled-control output is labelled `independent_analytic_sampled_obb`.

The native-observation output is separately labelled
`raw_public_jolt_observation`. It requires a native dispatch and hit, checks
shallow raw contact depths and surface witnesses at a declared `3e-4 m`
allowance, and checks the raw obstacle-outward sign. This tolerance applies to
metre-scale controls; it is not a blanket engine accuracy claim. A projection
onto the span is used solely to check raw capsule surface membership; the test
does not assign a material coordinate to a raw Jolt hit. The returned public
contacts remain a separate analytic-refinement product.

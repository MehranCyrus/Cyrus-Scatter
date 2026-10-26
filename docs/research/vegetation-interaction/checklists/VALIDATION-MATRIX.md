# Validation matrix

**All rows Pending.** These are proposed acceptance experiments, not results. Set physical tolerances, exact versions and budgets in an [experiment record](experiment-record.json) before execution. VG references point to [the proposed engineering guidelines](../08-ENGINEERING-GUIDELINES.md).

| ID | Case | Required observation | Guide | Status |
| --- | --- | --- | --- | --- |
| V01 | One authored bent blade through viewport/render/Bake | Same intended visible shape, bounds and root | VG12 | Pending |
| V02 | Untouched source before/after fitting | No source topology/position mutation | VG02 | Pending |
| V03 | Position-only anchor | Root stays fixed while hinge motion is permitted | VG03 | Pending |
| V04 | Fixed tangent | First direction respects its declared clamp tolerance | VG03 | Pending |
| V05 | Full base frame | Width/roll attachment is measured independently | VG03 | Pending |
| V06 | Soft angular base | Root stays fixed; angular response follows selected policy | VG03 | Pending |
| V07 | Fixed stone with intersecting rest source | Recovery attempt judged on contact, strain and work limit | VG06 | Pending |
| V08 | Clear initial shape with separate rest target | Restoring load and orientation initialization are explicit | VG06 | Pending |
| V09 | Moving-stone conditioning | Loading history recorded; not substituted for V07 | VG06 | Pending |
| V10 | Segment endpoints outside but interior crossing | Whole-segment contact detects obstruction | VG05 | Pending |
| V11 | Component entirely inside closed obstacle | Classification catches embedded geometry | VG05 | Pending |
| V12 | Guide clear, ribbon edge intersecting | Visible-mesh validation rejects false success | VG05 | Pending |
| V13 | Two stones, joint contact | Both obstacles respected in one solve | VG05 | Pending |
| V14 | Narrow channel with 3D escape route | Route recorded; no unsupported infeasibility claim | VG05 | Pending |
| V15 | Protected root inside obstacle | Explicit root conflict; no movement/deletion | VG01 | Pending |
| V16 | Sharp corner and thin obstacle | Proxy/discretization limitations diagnosed | VG05 | Pending |
| V17 | Open or invalid obstacle mesh | Declared sign/contact policy enforced | VG04 | Pending |
| V18 | Two neighboring independent blades | No cross-binding or accidental joint identity | VG02 | Pending |
| V19 | Joined-base and opacity-card sources | Correct tier or explicit preparation limitation | VG02 | Pending |
| V20 | Nonuniform, mirrored or sheared transform | Supported evaluation or clear rejection | VG12 | Pending |
| V21 | Stone moves into/out of contact | New and released plants reconsidered | VG07 | Pending |
| V22 | Stone crosses field or is deleted | Old/new regions and prior dependencies included | VG07 | Pending |
| V23 | Same inputs, fresh versus repeated update | Declared repeatability and rest policy hold | VG06 | Pending |
| V24 | Density/quota/Relax or source swap | Full-input compatibility governs reuse | VG08 | Pending |
| V25 | Appearance versus semantic channel edits | Only compatible appearance changes reuse shape | VG08 | Pending |
| V26 | Manual pending edit | No refit before Update; prior output marked stale | VG11 | Pending |
| V27 | Relevant Live edit/animation | Correct dependencies schedule bounded updates | VG11 | Pending |
| V28 | Navigation/selection/unrelated animation | No static solve or unchanged buffer upload | VG11 | Pending |
| V29 | Cancellation and stale worker completion | No late or partial publication | VG09 | Pending |
| V30 | Owner deletion, reset and shutdown | Workers/readers retire safely | VG09 | Pending |
| V31 | Allocation/work-limit failure | Previous complete publication retained | VG10 | Pending |
| V32 | Undo/Redo and repeated history | Coherent state restored; memory release measured | VG13 | Pending |
| V33 | Save/reopen and missing dependencies | Current/stale/unavailable states preserved honestly | VG14 | Pending |
| V34 | UV seams, material IDs and authored normals | Appearance policy matches across output paths | VG15 | Pending |
| V35 | Smooth/shell/subdivision output changes | Final evaluated contact revalidated or unsupported | VG12 | Pending |
| V36 | Many unaffected placements, sparse local contact | Work and output scale with relevant changes | VG13 | Pending |
| V37 | Dense contact/high-vertex sources | Whole-pipeline peak/work budgets measured | VG13 | Pending |
| V38 | Approximate deformed variant reuse | Error budget, contact and popping revalidated | VG12 | Pending |
| V39 | Optional flagged partial acceptance | Complete atomic generation with explicit exception policy | VG14 | Pending |
| V40 | Rigid versus deformable leaf | Mode-specific expected behavior remains distinct | VG16 | Pending |
| V41 | Render/logical/semantic identity and independent coincidence | Verified duplicate mapping preserves seams without welding independent pieces | VG17 | Pending |
| V42 | Explicit opposite-winding faces | Analysis classifies sidedness while original render faces/channels remain intact | VG17 | Pending |
| V43 | Curved rest binding and complete-turn twist | Rest reconstruction, fixed coordinates and frame/twist sampling meet declared limits | VG18 | Pending |
| V44 | Opposing-guide and soft-hold blends | Width/area collapse is detected; limited preservation claims remain conditional | VG18 | Pending |
| V45 | Shared vertex with competing blade motion | One explicit shared-base/attachment policy resolves or rejects the request | VG18 | Pending |
| V46 | Imported bone/cage preparation | Conversion passes representative pose comparisons or remains unsupported | VG18 | Pending |
| V47 | Borrowed/shared mesh channels and renderer caches | Owned adapters survive actual readers without source mutation or early release | VG19 | Pending |
| V48 | Object offsets, parents and world-space modifiers | Evaluated source and transform are captured coherently and applied once | VG19 | Pending |
| V49 | Mirrored Bake with corner channels | Winding, map/normal indices and tangent handedness stay consistent | VG15 | Pending |
| V50 | Non-geometric authored foliage normals | Selected renderer/custom mesh/Bake paths honor the declared normal policy | VG19 | Pending |
| V51 | Exact solver source/build/loaded identity | Commit, local patches, build flags, precision, enabled modules and binary hashes agree with the inspected baseline | VG20 | Pending |
| V52 | CPU rod root-mass coupling | Initialized rod inverse mass, canonical zero root velocity and measured angular behavior distinguish position-only, soft and hard attachment | VG03 | Pending |
| V53 | Direct BVH versus Jolt contact queries | Same fixtures expose contact agreement, multi-contact, cold/warm cost, storage and lifecycle differences | VG20 | Pending |
| V54 | Engine contact/pair/manifold capacity exhaustion | Error bits prevent false acceptance; failed successor preserves the previous complete publication | VG21 | Pending |
| V55 | Scene units, scale and distant origin | Equivalent physical inputs and local-origin transforms preserve declared contact/root quality within measured tolerances | VG21 | Pending |
| V56 | Engine scheduling and cooperative cancellation | Bounded update boundaries, nested jobs/barriers, shutdown and measured cancellation latency satisfy the adapter contract | VG21 | Pending |
| V57 | Closed-mesh parity degeneracy | Center/off-axis, shared-edge/vertex and open-mesh controls produce verified solid classification or an explicit ambiguous state | VG22 | Pending |
| V58 | Tiny-geometry contact regression | Equivalent crossings, scaled tolerance and proposed normalization are checked against analytic overlap and mapped-back units | VG22 | Pending |
| V59 | Shape-query construction and coordinates | Capsule-Y/rod-Z conversion, dimensions/scale, query sign, separation depth, base offset and COM/body-origin transforms match known primitive controls | VG22 | Pending |
| V60 | Canonical rod rest/reset/remaps | Particle and rod velocities/frames reset coherently; authored rest state and semantic mapping survive property calculation and optimization | VG23 | Pending |
| V61 | Soft iterations versus contact refresh | Timing/substep changes are distinguished from collision-plane refresh, with one stepping owner and no double update | VG23 | Pending |
| V62 | Sleeping rigid body with residual overlap | Independent final contact/visible-proxy metrics govern acceptance even when sleep and zero error bits are reported | VG22 | Pending |
| V63 | Static pose versus deformation trajectory | Declared final-pose or continuous-path contract is tested; a rigid translation cast does not certify arbitrary bending motion | VG05 | Pending |
| V64 | Independent oracle and equal-contract comparison | Separate checks expose shared false negatives; both candidates include the contact adapter and accept feasible companions as well as rejecting invalid inputs | VG22 | Pending |
| V65 | Immutable query generation during obstacle edits | Every iteration uses one owned shape/pose generation; per-query locking and a final revision check cannot substitute for coherence | VG24 | Pending |
| V66 | Shared runtime and multiple solve worlds | Actual module/build/allocator ownership supports service overlap and shutdown without replacing global hooks or retiring another world's resources | VG24 | Pending |
| V67 | Qualified witness and endpoint/frame response | Material fraction, normal, mobility weights, pinned endpoints and zero-denominator conflicts pass frozen-witness controls before full nonlinear fitting | VG25 | Pending |
| V68 | Dynamic interior ejection versus accepted static fit | Contact and escape alone do not pass; final velocity, root/rest/length and visible clearance meet the selected mode's stopping criteria | VG06 | Pending |

## Required result fields

Store pass/fail/pending per row, numeric errors with units, declared tolerances, accepted frame or work count, source/obstacle identities, output artifacts and any unsupported scope. Include a reason for skipped rows. A documentation integrity pass does not change this matrix's Pending status.

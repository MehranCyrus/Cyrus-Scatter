# Solver decision experiments

**Eight proposed experiments from R12; all Pending.** This is a focused decision checklist within the [validation plan](../07-VALIDATION-PLAN.md), not an implementation authorization or a second progress ledger. Use an [experiment record](experiment-record.json) and preserve failures alongside successes. Source review is recorded separately in [R12-source-review.json](../references/R12-source-review.json).

## Sequence and shared controls

Confirm identity, then run tiny root/contact probes alongside the first authored Max 2027 viewport/render/Bake experiment. R12 proposes native fixtures before UI work; the consolidated plan keeps output feasibility early as an independent risk. Neither requires a substantial production solver first.

Use the same prepared geometry, units, rest state, initial pose, root policy, decoder and contact tolerances across methods. Record timestep, iterations, physical scale, local origin, supported transforms and budgets. V55 unit/translation invariance and V56 scheduling/cancellation checks apply across the engine experiments. Every status below remains Pending; inspected source is not a fixture pass.

## R13 evidence and follow-up gates

R13 adds a [reproduction archive](../sources/evidence/cyrus_jolt_reuse_reproduction.zip) and [reported result JSON](../sources/evidence/cyrus_jolt_probe_results.json). Our [review](../references/R13-evidence-review.json) verifies package/source consistency without running the harness. These records partially exercise the questions behind E3/E4/E5/E7 in one external build; they do not complete those Cyrus experiments. In particular, the clamped one-segment rod does not test feasible routing, and the gap rows are queries rather than fits.

All five R13 follow-up gates remain Pending. They refine the shared plan as follows:

| Gate | Decisive evidence needed | Shared plan mapping |
| --- | --- | --- |
| G0 Geometry adapter | Independent primitive truth, occupancy ambiguity, query sign/COM, tiny-scale normalization and rebasing through actual snapshots | E1/E3/E4/E6; V51, V53, V55, V57-V59, V64 |
| G1 Root/rest/state | Curved and twisted guide, zero initial root velocity, free/soft/hard angle response, semantic remaps and complete reset | E2; V03-V06, V43, V52, V60 |
| G2 Contact correction | Feasible multi-segment one/two-stone route, inside start, root conflict and sharp corner with an independent final validator | E3/E4/E5; V07-V17, V61, V63 |
| G3 Equal-contract comparison | Fitter versus rods with the required contact adapter; same evaluator/tolerances before measuring time and memory | E6; V37, V53, V64 |
| G4 Host/result lifecycle | Changed input during work, cancellation, reset/reload, selected-renderer/Bake/picking parity and retirement | E8; V01, V21-V35, V47-V50, V56 |

A separate rigid acceptance probe must preserve the reported sleep-with-residual counterexample (V62). The reported 66-update result is not a clearance pass, a throughput measurement or completion of E7's population/lifecycle scope.

## Final study R14 and identifier mapping

R14's [evidence package](../sources/evidence/R14/Cyrus_Collision_Research_Evidence.zip) contains a different native harness/build and separate analytic oracles. Its report-local E1/E2 supply reported witness/containment baselines, not completion of our similarly numbered experiments. Map R14-E1/E2 into our E1/E3/E4 questions; R14-E3 into root experiment E2; R14-E4/E5 into contact/backend experiments E3-E6; R14-E6 into lifecycle/output E8; and R14-E7 into equivalent-acceptance cost work E6/E7. All of our eight statuses remain Pending.

Use the [review receipt](../references/R14-evidence-review.json) for exact configuration and evidence boundaries. H02/H02b compare 5/50 soft iterations on a clamped three-point rod; H04b is free-rod ejection, not a static-fit success. Nine analytic fixtures/fifteen reported checks establish expectations, not solver passes. Add feasible companions, one coherent query generation (V65), shared runtime lifetime (V66), qualified witness/endpoint response (V67) and an ejection/stopping control (V68).

## R12-E1: exact-pin build and provenance

**Status: Pending. Matrix: V51.** In a later authorized task, build the chosen harness against commit `1b2e77e3c6c09709e5edc79dc208459b8ff32051` and record local patches, compiler/configuration, precision and enabled modules, job adapter and binary hashes. Record loaded identity when entering Max; header version 5.6.1 alone is insufficient.

**Decision:** do not attribute an observed result to the inspected source until the built/loaded identity is established. Our eleven-file source comparison is a useful prerequisite, not completion of this experiment.

## R12-E2: root anchoring modes

**Status: Pending. Matrix: V03-V06, V52.** Use one curved eight-segment rod without obstacles. Compare zero-inverse-mass root initialization with an explicitly designed position attachment and a reference-rod construction. Treat those alternatives as prototypes whose constraints need inspection, not ready-made equivalent controls.

Measure root drift, first-segment angle, material-frame angle, length and rest-curvature error under the same small load. Check the adjacent rod's initialized inverse mass and effective angular response. R14 clarifies that the reference rod can be a separate fixed pair, excluded from visible binding; preserve its remap and never use a zero-length dummy. **Decision:** identify separate position-only, soft angular and hard angular policies, or reject a construction that cannot provide the intended mode.

## R12-E3: segment-crossing falsification

**Status: Pending. Matrix: V10, V12.** Place endpoints outside a sphere/box with the segment interior crossing it. Compare stock rods, the focused fitter and its contact backends; repeat with 1, 2, 4 and 8 subdivisions and a declared radius/visible-width envelope.

Measure generated contacts and independently computed residual segment/capsule and decoded-mesh penetration. **Decision:** a missed crossing rejects that configuration as a complete contact solution. Improvement with subdivision is an approximation result, not proof for arbitrary obstacle feature sizes or continuous motion.

## R12-E4: deep-inside and protected-root cases

**Status: Pending. Matrix: V11, V15, V17.** Put a movable guide entirely inside a convex solid, then inside a closed triangle mesh; repeat with a protected root inside each. Include an open surface as a separately declared policy.

Measure containment classification, available contacts, exit direction, strain and final diagnostic status. **Decision:** require explicit root-conflict and solid/surface preflight regardless of solver. Preserve roots and plants; finite triangle backface thickness is not a global inside test.

## R12-E5: two obstacles, narrow gap and sharp corner

**Status: Pending. Matrix: V13, V14, V16.** Test two stones together, a channel above/equal/below the declared effective diameter, and a right-angle corner. Retain opposing contacts separately. Add a possible out-of-plane escape route and a visible ribbon whose width changes the available route.

Measure simultaneous contacts, oscillation, penetration, root/frame error and strain under a fixed work limit. **Decision:** select the method that meets those criteria or reports an honest failure. A blocked specified channel does not prove every three-dimensional route infeasible.

## R12-E6: Jolt capsule queries versus direct BVH

**Status: Pending. Matrix: V10-V17, V53.** Use identical segment capsules against analytic, convex, compound and mesh obstacles with matched geometry/representation tolerances. Keep the fitter unchanged when switching contact backends, and use an independent reference where practical to identify shared false negatives.

Measure contact agreement and multi-contact completeness, cold cooking, warm query/update time, peak/retained storage, cancellation latency and lifecycle cost. Keep query-level and complete-pipeline timings separate. **Decision:** reuse Jolt queries only if they reduce total implementation/maintenance risk within the measured quality and resource budgets; otherwise retain direct BVH contact. No winner is established yet.

## R12-E7: separate rigid-debris baseline

**Status: Pending. Matrix: V37, V40, V54-V56.** R12 proposes 100, 1,000 and 10,000 dynamic convex/compound stones over fixed irregular terrain. The current local Lab declares a 5,000-body default/admitted profile. Keep experiments within that profile; the 10,000-body proposal needs a separately scoped standalone harness and admission/resource decision. This checklist raises no existing limit.

Measure residual overlaps, settling criteria, update error bits, peak memory, repeatability and completed stable-ID transform capture. Add deliberately bounded capacity-error cases. **Decision:** qualify rigid settling independently; sleep alone or a normal update return cannot establish accepted quality or qualify vegetation bending.

## R12-E8: shape parity and atomic publication

**Status: Pending. Matrix: V01, V02, V29-V35, V47-V50.** Start with one authored bend through the minimal evaluator; then use two placements of one prepared source bent differently around two stones. Record accepted placement IDs, immutable source data, completed bounds and exact selected renderer/build/mode.

Compare visible positions, root/frame registration, UVs/materials/normals and Bake output. Exercise cancelled, stale and failed successors while readers use the previous complete result. **Decision:** stop expansion if distinct deformed output or coherent publication fails. Guide-level contact success cannot bypass this gate.

## What to bring back

Attach exact fixtures, source/build/binary identity, settings and tolerances, per-case measurements, work/memory/cancellation records, diagnostics and output artifacts. Mark unsupported or skipped cases explicitly. A later choice may adopt a method only for the scope actually demonstrated; no reported estimate or source inspection changes a Pending row to Pass.

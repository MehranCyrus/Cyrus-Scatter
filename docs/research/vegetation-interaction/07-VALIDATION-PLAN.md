# 07 Validation and prototype plan

**Status: proposed experiments; every implementation/host row starts Pending.** This plan is available for a later authorized task. Documentation generation and integrity checks are recorded separately in [VERIFICATION.md](VERIFICATION.md).

## Gate 0: fix the experiment boundary

Select one prepared source, fixed obstacle fixture, source/rest convention, supported transform range and one production renderer/build. Define numeric acceptance tolerances in physical units before running. Record clearance, permitted strain, root position/frame error and output comparison metrics. Candidate values in research remain starting hypotheses until calibrated.

Keep an original-intersection fixture for the user's actual request. Add a collision-free initial guide and a moving-obstacle conditioning variant as separate experiments. No pass in the conditioned branch substitutes for a fixed-from-start overlap-recovery result.

Use owned disposable scenes/profiles and exact matched script/native identities. Max 2027 is the development/qualification host. Preserve artist sessions and Test Scene assets. Offline arithmetic or source inspection must not be reported as a Max pass.

R13 supplies an authored headless harness and reported Linux results. Preserve those failures as regression seeds; rerunning them through a future Cyrus unit/snapshot adapter is new work. For primitives, use analytic geometry as an independent reference. For meshes, separate surface intersection from solid classification and test edge/vertex degeneracy. The same query under evaluation cannot be the sole acceptance oracle.

R14 adds seven reported native records across five families, plus nine analytic fixtures with fifteen stored checks. Its single-world-precision/SSE2/assert build differs from R13's double-world-position/AVX build. Keep separate receipts and distinguish native physics, arithmetic expectations and proposed solver response. R14's E1-E7 are report-local gates; they do not share the meanings/status of our R12-E1 through R12-E8 identifiers.

## Gate 1: output feasibility and asset audit

Run R12's smallest source-falsification probes alongside this gate: exact dependency identity, bare-rod segment crossing and root attachment behavior. They can use a tiny native harness without waiting for a large Max integration. They do not replace the authored output-parity experiment below. The [eight decision experiments](checklists/SOLVER-DECISION-EXPERIMENTS.md) map these questions to the shared validation matrix; none has been executed here.

Create one authored deformation through a minimal CPU reference decoder and carry it through viewport, chosen final renderer and Bake. Compare actual positions/bounds, root registration, UVs, material IDs and explicit normals. This gate can precede a sophisticated solver and can expose an unsuitable output design early.

Audit representative assets at the same time. Record topology families, necessary manual work, root/frame ambiguity, unsupported proxy access and binding errors. Do not build a broad automatic preparation product before measuring this asset burden.

Use R11's embedded public/synthetic examples as small representation fixtures. Distinguish our independently recounted topology from its supplied seven topology and ten evaluator result records. All Max/renderer gates remain pending. Add explicit two-sided faces, independent coincident blades, shared vertices, full-turn twist and opposing-frame blends before generalizing the decoder.

Exit evidence: a matched output fixture plus actual audit records, or an explicit failed gate identifying the representation/output limitation. The current research library contains no such execution evidence.

## Gate 2: contact and numerical comparison

Run the same prepared blade/stone fixtures through a focused fitter and a rod/constraint comparator. Compare direct triangle-BVH contact with Jolt shape queries inside the fitter, keeping the same source, decoder, physical scale and acceptance criteria. Include deep initial overlap, segment crossings between samples, visible-width contact and root conflicts. Do not count contact-query time alone as the solver or full-update cost.

R13's clamped one-segment crossing is a detection test. Add a feasible multi-segment detour and implement the required rod contact adapter before comparing total correction quality or speed. Measure canonical reset, root orientation, authored frames/remaps and collision-refresh cadence. Specify whether acceptance covers only the final static pose or a continuous deformation path.

Retain R14's 5/50-iteration three-point crossing as another detection seed, and its free-rod ejection as a failed static-fit control. For the first response experiment, provide root freedom and enough guide length for a demonstrably feasible route. Test local witness/endpoint correction with an independently known parameter, capsule-Y/rod-Z frame conversion and an immovable-contact denominator. Every rejected or ambiguous fixture needs a feasible companion that must be accepted; blanket rejection is not product success.

Then test two fixed obstacles in one solve. Include a narrow channel, a possible out-of-plane route, contradictory protected-root constraints and symmetric alternatives. A failure should identify unresolved contact or work exhaustion; do not infer global infeasibility from a local failure.

For a relaxation method, refine timestep/iterations and discretization separately. Measure residual motion, strain and contact error; reaching a chosen frame is not convergence. Record whether results depend on initialization, obstacle approach order or previous fitted state.

## Gate 3: lifecycle and product behavior

Move an obstacle into contact, across the vegetation, away from contact, then delete it. Include old/new influence and released plants. Compare recomputation with a fresh setup using the same declared rest/initial state.

Exercise Manual pending edits, relevant Live edits/animation, unrelated animation, selection/navigation, owner switching, cancel, stale completion, deletion, scene reset, save/reopen and Undo/Redo. Check that failures retain the prior complete publication and that its status honestly reports staleness.

Move an obstacle between repeated queries while a job runs: that job must keep one coherent geometry/pose generation even though its successor becomes stale. Also exercise rigid and fitting services starting/stopping together under the actual shared-runtime/module ownership. A safe individual query or a final revision check does not prove either lifecycle contract.

Test placement-input changes: source swap, density/quota, masks, Relax, transform edits, relevant source topology and appearance-only changes. Reuse should follow compatible full inputs, not stable IDs alone.

## Gate 4: bounded scale and memory

Measure cold preparation, warm update and no-op reuse separately. Scale affected and unaffected populations independently; a mostly unaffected field must not pay full deformation/output cost. Increase contact density and source vertex count independently of placement count.

Capture neighborhood candidates, active contacts, guide samples, solve work, decoded vertices, output variants, cache reuse, uploads, wall time and actual responsiveness. Account for retained source data, staged/published overlap, render copies and Undo/Redo history. Test allocation/budget failure and resource retirement.

Add unit/local-origin invariance, engine error-bit handling, job/barrier safety and cancellation-latency measurements before accepting engine reuse. The current Lab declares a 5,000-body default/admitted profile. R12's proposed 10,000-body comparison exceeds that profile and requires a separately scoped harness/admission decision; this research update changes no limits or settings.

A GPU or approximate variant path is justified only if these measurements identify a bottleneck and the proposed optimization preserves acceptance. Report absolute memory and complete-pipeline timings with hardware/build/input identity.

## Required fixture families

| Family | Key cases |
| --- | --- |
| Basic shape | Straight ribbon, precurved blade, two disconnected blades, joined-base clump |
| Contact | One stone, two stones, sharp corner, thin gap, open mesh, deeply embedded component |
| Anchoring | Position-only hinge, fixed tangent, full base frame, soft angular attachment, root conflict |
| Geometry delivery | Driver-clear/mesh-penetrating case, UV seams, authored normals, materials, Bake/render parity |
| Preparation identity | Render/logical/semantic IDs, opposite-winding pairs, independent coincident blades, shared-base policy |
| Decoder stress | Rest reconstruction, unwrapped twist, opposing blend collapse, authored rig conversion and mirrored corner channels |
| Lifecycle | Into/out of contact, obstacle deletion, relevant animation, Manual pending, stale/cancelled work |
| Resources | Many unaffected placements, dense local contact, high-vertex source, failure during publication |

The [validation matrix](checklists/VALIDATION-MATRIX.md) expands these into individually trackable rows. The [experiment record](checklists/experiment-record.json) defines the evidence to attach to each run.

Record renderer profile qualification separately from source preparation readiness. Supplied JSON saying an arithmetic check passed, or recording an external headless run, does not change a Cyrus integration row to Pass. The matrix now contains 68 proposed cases: the prior 64 plus four query-generation, runtime-lifetime, witness-response and ejection controls from R14. All remain Pending. R13/R14's report-local gates refine the existing eight decision experiments rather than creating another execution ledger.

## What a completed result must report

State exact source/package/loaded identities, scene and dependency hashes, host/renderer versions, hardware, initialization and changed parameters. Attach measured values, diagnostic IDs, screenshots/renders, output files and command/test logs as relevant. Separate numeric, host automation, physical artist interaction and renderer evidence.

Report pass/fail for the declared criteria, untested rows, unsupported geometry and remaining risks. A future installer is required when delivering a new Scatter version for user testing under the repository workflow; this documentation packet is not that delivery.

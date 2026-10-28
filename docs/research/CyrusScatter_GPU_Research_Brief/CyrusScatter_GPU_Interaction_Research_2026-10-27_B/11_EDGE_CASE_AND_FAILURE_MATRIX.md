# 11 — Edge cases and failure matrix

[Index](00_README.md) · [Numerical gates](09_MEMORY_PRECISION_AND_HARDWARE.md) · [Prototypes](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)

## Status vocabulary

**P-Supported** means the supplied baseline says a scoped behavior is supported; it is not Researcher A's execution. **Proposed** is a required GPU/reference test not yet executed. **Rejected** is outside the proposed admitted input or an explicitly forbidden recovery. **Unknown** means an SDK/device/algorithm proof is still needed. The six small analytic oracles in [analysis](analysis/README.md) are **executed mathematical counterexamples only**, not passes for a fitter or backend.

Failure outputs must distinguish invalid input, unsupported capability, root/attachment conflict, uncertain solid/query, numerical breakdown, work/memory exhaustion, cancelled/superseded and final-surface failure. “Search exhausted” does not prove global infeasibility. A known fixed root inside mandatory clearance can establish a **local constraint conflict**, while a feasible alternative route around a stone may remain undiscovered.

## Geometry and contact

All fixture dimensions below are metres in +Y-up unless specified. Rotate/translate variants must preserve analytic expectations. Reference tests include hidden and unhidden versions so exclusion never masks a solver defect.

| ID / trigger | Expected behavior | Algorithm hazard | Mitigation | Reproducible test | Status |
|---|---|---|---|---|---|
| E01 clear rest | Reuse exact immutable rest | Solver relaxation changes clear plants | Complete clear check, rest sentinel | S1 with no collider and distant sphere; compare source/pose bytes and zero solve count | Proposed; oracle not a solver pass |
| E02 endpoints clear, span crosses stone | Detect contact | Node-only sampling misses interior | Whole-span capsule/triangle query | Segment (−2,0,0)→(2,0,0), unit sphere at origin; endpoints +1, interior −1 | Analytic oracle executed; GPU test proposed |
| E03 guide clear, blade edge intersects | Reject guide-only acceptance | Ignored width/foliage offset | Conservative envelope + visible audit | Segment at y=1.1 across unit sphere, envelope radius0.2; guide +0.1, envelope −0.1 | Analytic oracle executed; full surface test proposed |
| E04 span entirely inside solid | Diagnose occupancy, do not call clear | Surface-crossing test sees no intersection | Signed classification plus distance | Segment x=−0.2→0.2 inside unit sphere; endpoint distances −0.8, continuous minimum −1 | Analytic oracle executed; GPU test proposed |
| E05 root inside required contact clearance, hide disabled | Retain old result; root conflict | Moving fixed root or inventing normal | Fixed inverse weight; classify explicit conflict | Root at sphere centre; zero gradient; run PositionOnly and root-frame modes | Analytic zero-denominator oracle executed; solver test proposed |
| E06 same root inside selected hide region | Hide whole rooted group and attachments | Solver failure used to infer hide | Independent root classification first | Toggle Inside solid with margin0; compare rooted-group ownership | P-Supported scoped semantics; GPU proposed |
| E07 root outside hide but inside contact gap | Report conflict, remain visible in last accepted state | Conflating margin and gap | Apply separate settings exactly once | Root0.01 outside sphere, gap0.02, hide margin0 | Proposed |
| E08 two obstacles squeeze a plant | Consider both and all local contacts | First-hit/nearest-hit-only resolution oscillates | Refresh active contact set; bounded coupled solve | Parallel planes gap0.03 and capsule diameter0.04; then gap0.05 positive control | Analytic gap conflict executed; solver proposed |
| E09 narrow route with feasible detour | Known-feasible qualification must succeed; unresolved is an honest runtime status but fails that qualification | Local search failure declared impossible | Deterministic alternative proposals; independent feasible witness | Two spheres with an authored verified side route; vary spacing away from nominal | Proposed |
| E10 sharp corner / equal nearest faces | Stable diagnostic, no random normal jump | Discontinuous/zero field gradient | Multiple local witnesses; trust-region updates; exact fallback | Box edge/corner grazing; ±epsilon perturbation and rotated box | Proposed |
| E11 open mesh | Reject solid occupancy or explicit surface-only mode | Invalid inside/outside sign | Solid admission, explicit mode; no accidental volume | Cube missing one face, plus oriented plane | Rejected for solid mode; alternate mode unknown |
| E12 nonmanifold/inverted/degenerate solid | Deterministic admission/uncertainty | Wrong winding, NaN triangle normal | Mesh checks and robust classification | Duplicate/opposite triangle, zero-area triangle, self-overlap | Proposed rejection/diagnostic |
| E13 broad leaf wholly contained | Detect despite no boundary crossing | Triangle intersection alone misses containment | Vertex/region occupancy plus triangle contact | Closed leaf slab fully inside larger sphere/cube | Proposed |
| E14 leaf triangle crosses obstacle, vertices outside | Detect visible-surface failure | Vertex-only mesh validation | Triangle/solid query with occupancy | Large thin triangle through a small sphere or closed box | Proposed |
| E15 thin collider below field cell size | No false clear | Aliased/saturated SDF erases feature | Error-qualified field; exact fallback; reject underresolution | 1mm slab at 5mm voxel, translations across cell phases | Proposed; uncertified field rejected as final proof |
| E16 narrow-band missing interior | Unknown or exact fallback | Background “far outside” used for interior | Store sign/coverage provenance | Fully inside point beyond stored band; both signed backgrounds | Proposed |
| E17 multiple collider instances share one asset | Correct instance-space queries | Wrong inverse scale/transform; duplicated fields | Shared BLAS/field, per-instance transforms | 32 rotated/translated uniformly scaled copies, same fingerprint | Proposed |
| E18 >64 relevant colliders | Current admission failure retained | Dropping excess pairs yields false acceptance | Explicit cap/overflow status or separately qualified chunking | 65 overlapping relevant instances vs64 boundary | P-Supported cap; GPU proposed |

## Constraints, frames and numerical scale

| ID / trigger | Expected behavior | Algorithm hazard | Mitigation | Reproducible test | Status |
|---|---|---|---|---|---|
| E19 position-only root | Root fixed; first span may rotate | Root position mistaken for root angle | Independent root-mode residuals | Bent S1; compare first-span angle and zero root displacement | Proposed |
| E20 clamped/soft root frame | Hard residual or declared soft objective; Unsupported if absent | Fake stiffness from position pin | Explicit frame/tangent/twist constraint | Identical root, different frame targets and soft weights | Proposed; exact current modes unknown |
| E21 child contact while parent moves | Child anchor follows accepted parent frame; parent feedback only in an explicitly coupled mode | Depth race, stale parent pose, or mistaken one-way feedback | Level schedule for one-way attachments; reverse/coupled solve for child feedback; final audit | S4 child-only contact then parent collision under both declared modes | Proposed |
| E22 curved rest / no contact | Preserve rest curvature and twist | Straightening as implicit “rest” | Immutable authored rest objective | Quarter-arc and helical-twist sources, obstacle leaves | Proposed |
| E23 q and −q frames | Same geometry, no zero interpolation | Quaternion sign flip | Hemisphere alignment; explicit twist branch | Antipodal unit quaternions; random sign per node | Analytic rotation equivalence executed; evaluator proposed |
| E24 near-180° tangent reversal/full turn | Deterministic frame policy or rejection | Undefined transport axis, hidden shortest-turn assumption | Guarded transport and stored unwrapped twist | Folded guide, 179.9/180/180.1° and 2π twist | Proposed |
| E25 zero-length span/zero denominator | Invalid input or explicit fixed conflict | Division by zero, NaN progress | Validate rest lengths, scaled thresholds | Duplicate nodes; contact all supported by fixed endpoints | Proposed |
| E26 nearly singular/nonuniform/mirrored/sheared transform | Reject current unqualified form | Wrong capsule/SDF radius and normal | Positive uniform scale admission | determinant<0; scales(1,2,1); shear; scale≈0 | Rejected under current contract |
| E27 distant world/small blade | Equivalent rebased result within tolerance | FP32 loses contact gap | Double origin subtraction before packing | Repeat S1 at1km/100km/1000km; 1mm offsets | FP32 arithmetic executed; solver proposed |
| E28 very small asset | Reject insufficient resolution or route double | Tolerance larger than physical feature | Scale-aware admission and declared units | Scale S1 by1e−4 and1e−6, same dimensionless obstacle | Proposed; support unknown |
| E29 NaN/Inf/invalid indices/frame norm | Reject before device access | OOB/undefined kernels | Validate all arrays/count products/fingerprints | Corrupt one field at a time | Proposed |
| E30 CPU/GPU reduction differences | Same declared acceptance, not bitwise claim | Atomic order/FMA changes residual | Stable order, fixed reduction, matched flags | Repeat seeds, shuffle pair input then stable-sort | Proposed |

## Edits, display, lifetime and recovery

| ID / trigger | Expected behavior | Algorithm hazard | Mitigation | Reproducible test | Status |
|---|---|---|---|---|---|
| E31 fast drag/teleport | Correct final endpoint; no claim of continuous path safety | Treating static endpoint solve as CCD | Old/new/prior affected sets; optional swept operation separate | Collider jumps across patch and lands beyond it | Proposed |
| E32 collider leaves/deletes | Exact rest and unhide according to current settings | Only new neighborhood searched | Previous contacts + old/new union | B15, delete collider, Undo/Redo | P-Supported scoped restoration; GPU proposed |
| E33 floating obstacle Under collider | Downward footprint hides intended root groups | Infinite Y bounds destroy spatial locality | Horizontal index partition/projected footprint | Raise object; distant columns must not become all candidates | P-Supported scoped behavior; GPU proposed |
| E34 mixed Wireframe/shaded/camera | Correct pose/visibility/picking; no new static solve | Draw callback triggers update/upload | Retained buffers; pass-consistent evaluator | F3, camera orbit, two viewports, repeated unchanged frames | P-Supported scoped draw; new shader proposed |
| E35 source edit during in-flight job | Reject old result; new source remains immutable | Binding offsets refer to replaced source | Full revision key and pinned ownership | Delay completion, edit topology/material/root binding | Proposed |
| E36 Undo/Redo/reset/load/owner deletion | No stale publication/use-after-free | Generation reuse/dangling host pointer | Document epoch + owner lifetime lease | Inject at every job-state transition | Proposed |
| E37 newer request while old GPU work runs | Coalesce, bound queue, newest-only accepted publication | Work freed early or starvation concealed | One in-flight/one pending; record result age | 240Hz input over slow fixture; release and await exact final | Proposed |
| E38 resource/VRAM/query overflow | Retain old accepted result; report counts | Partial list mistaken for complete | Checked prefix sums/caps, tiled retry, CPU fallback | Force allocation cap, contact-list cap and query limit | Proposed |
| E39 wrong/multiple adapters / Optimus | Identity match or readback fallback | Ordinal0 assumption | LUID/device probe and reset epoch | Intel display+NVIDIA compute; two NVIDIA GPUs | Unknown until local topology test |
| E40 device loss/TDR/recreation | CPU canonical result survives; safe rebuild | Stale registrations/fences | Backend failure state, drain/retire per API | Supported device-reset harness; no normal TDR registry workaround | Proposed |
| E41 renderer/Bake/export request during fit | Pin complete compatible state; explicit pending/failure policy | GPU-only geometry or mixed revisions | Canonical evaluator, request-time policy | I3 across Arnold/V-Ray/Corona actually targeted | Unknown until renderer pinned/tested |
| E42 absent runtime/headless/remote session | CPU plugin loads and remains usable | Static DLL import makes entire plugin fail | Optional backend module, capability probe | Clean VM/noCUDA/noOpenCL; remote display | Proposed |
| E43 render abort/plugin shutdown | No leaked live readers or callbacks into unloaded code | Epoch mistaken for lifetime ownership | Cancel/drain and DLL/service lease | Abort render during GPU readback; unload/reset loops | Proposed |
| E44 same edit repeated/from different history | Rest-based result within declared deterministic tolerance | Hidden accumulated simulation state | Reset rest/temporary multipliers each request | A→B→A vsfreshA; call same snapshot100times | Proposed |
| E45 many source variants/materials | Preserve IDs/materials while batching | Source mismatch/page aliasing | Versioned tables and draw-slot remap | S6, shared geometry distinct material sets | Proposed |
| E46 approximate preview promoted to final | Must be blocked until full required validation | Guide-only success called mesh clear | Separate status/result store and explicit final gate | Force proxy success + broad-leaf audit failure | Rejected promotion; test proposed |

## Failure reporting to artists

**[D]** Show one primary state—Ready, Updating, Approximate preview, Last validated result, or Failed—with affected counts and a selected diagnostic overlay. Details can name root conflict, unsupported collider, underresolved field, surface collision, work limit or device issue. A failure highlights stable instance/root/guide IDs and the obstacle. It never silently reseeds, deletes blades, drifts roots or changes Hide margin. The recovery is to adjust obstacle/gap/preparation, choose a qualified quality/backend route, or explicitly reduce the scope and retry.

# Stage 08 — Demo and benchmark scenes

## Goal

Create a small reusable scene kit: seven scenes that support QA, tutorials, presentation and measured comparisons.

## Why this matters

The same inputs should demonstrate the product, reproduce bugs and validate improvements. A pretty image without a reproducible setup is weak engineering evidence.

## What we currently know

Only [the synthetic smoke scene](../../build/max2027-smoke.max) was found in the scoped product/tools/dist and top-level build scene search. It is not a polished or renderer-qualified demo. The following seven scenes are **PROPOSED**; this task defines them and does not claim to have created rendered scenes.

Use [the flagship workflows](../Product_Strategy_2026-09-29/03_Product_Positioning_and_Workflows.md) and [benchmark protocol](../Performance_Roadmap_2026-09-28/02_Baseline_and_Benchmarks.md).

## My tasks

- [ ] Build S01 first using the walkthrough.
- [ ] Create simple original assets or use assets whose display/distribution rights you have recorded.
- [ ] Save original inputs, procedural setup, accepted revision and output variants.
- [ ] Record screenshot/video angles and scene settings.
- [ ] Separate raw diagnostic scenes from approved public media.

## Engineering / Codex tasks

- [ ] Provide version-compatible scene builders for complex fixtures.
- [ ] Capture golden transforms/counts, dependencies and scene/package hashes.
- [ ] Add actual stage measurements; do not mistake a display limit for reduced generation cost.
- [ ] Qualify the renderer and save/cleanup paths before scenes become release evidence.

## Boss / Product-owner decisions

Approve public asset rights, chosen renderer scope and lead demo after the results exist. No commercial library is needed for the first kit.

## Step-by-step procedure

1. Build S01, save/reopen and render it on an available named renderer.
2. Use it as a known working template; add one principal task per subsequent scene.
3. Preserve a simple QA version with primitives and a separate presentation version using approved assets.
4. Record units, seeds, requested/emitted/displayed/render counts, topology and source complexity.
5. Add one meaningful revision and failure/recovery test per scene.
6. Capture approved screenshots only after its qualification status is known.
7. Use matched scene/builds for measurements; retain raw samples.

## Seven-scene production brief

| Scene | Purpose / features | Source assets / geometry | Expected result | Measure | Screenshots / video | Renderer / reuse |
|---|---|---|---|---|---|---|
| S01 Basic scatter | Install/tutorial and baseline | 10 m plane, box + sphere, simple original materials | Repeatable 200 placements; count/density/preview understood; save/reopen/render correct | First-task time, refresh and small render prep | Full setup + UI; 45–60 s creation recording | Actual available renderer/build; QA and first-use tutorial |
| S02 Courtyard | Masks, falloff, layered planting, hero edits | Original courtyard surfaces/exclusion lines; primitive QA plants or licensed-display vegetation | Protected paving, controlled edge transition, explicit edit handling after revised planter | Initial setup, boundary revision, recovery, prep/memory | Before/after planter + close-up edge; 60–90 s revision | Qualified renderer; lead workflow/homepage |
| S03 Landscape/environment | Source weights/clusters/layers/budget | Modest terrain, three source types with recorded triangle counts | Believable variation, inspectable clearance and display limits; no proxy assumptions | Generation, cache-hit navigation, full render prep, peak RAM | Wide/close render + Point Cloud/Proxy/Mesh; 45–60 s | Selected qualified mesh path first; feature/tutorial |
| S04 Road/path/boundary | Analyzer Street Side, Edge Border, corners/axes/trims | Open planar roadside strips, straight/curved reference line; simple lamp/tree/furniture | Ordered rows with predictable corners, offsets and revision | Analyze, row build, source/curve revision | Top view guides + UI + final row; 45–75 s | Qualified renderer; precision feature/demo |
| S05 Surface Analyzer | Auto/Straight/Ring/Branched, holes/disconnected planar elements, exports | Original rectangles/L-shape/star/holed surfaces, tilted copies | Meaningful nonempty data for eligible input; invalid nonplanar input explained; outputs match | Resolution/candidate cost, fit/point behavior, error recovery | Colored boundary/path/points + output splines; 45–60 s | Viewport essential, optional qualified render; docs/QA |
| S06 CS Edit | Selection/move/rotate/scale/clone/delete, stacked suspension, undo/reopen | 20–200 simple instances, fixed base generation | Intentional edits survive allowed operations; incompatible changes clearly invalidate/suspend | Selection/edit latency, repeated operations, save/reopen | Selected edit close-up + count/status; 45–75 s | Same qualified renderer; editing feature and regressions |
| S07 Heavy/resource | Matched workload scaling and memory envelope | Simple and heavier sources, fixed topology/source counts; 1k/10k/100k requested cases | Complete output with recorded limits; graceful stop/failure; reliable render/cleanup | Warm/cold full operation, median/p95, cache hits, navigation frame time and peak memory | Workload/settings overlay; raw recording and later verified chart | Exact renderer/hardware, including real 32 GB; benchmarks/QA |

The scene IDs are this playbook's kit identifiers; existing performance fixtures have their own mapping. Record that mapping instead of assuming similarly named files are identical.

## How to benchmark S07

First define the operation: preview rebuild, unchanged navigation, edit update, Analyzer analysis, or render preparation. Match actual work, source complexity, display budget, resolution and renderer settings.

Have engineering use the existing protocol: three warmups, 30 warm recomputation samples, separately 30 cache-hit samples and five process-cold runs. Record raw timings, output parity and peak memory. A manual spinner observation helps choose the bottleneck; it does not establish an optimized before/after result.

Never advertise requested count as rendered/displayed count. A GPU renderer does not mean Cyrus computation uses GPU. A video speed change must be disclosed and excluded from timing proof.

## Evidence to collect

Scene card:

~~~text
Scene ID / owner / creation and qualified dates:
QA and presentation file paths / hashes:
Max / renderer / package:
Units / seeds / layers / topology / source triangle counts:
Requested / emitted / edited / displayed / rendered counts:
Asset creators / rights / dependency list:
Baseline settings and expected result:
Revision + recovery action:
Manual/automated results:
Raw measurement location:
Screenshot/video shot IDs:
Public-media approval:
Known limitations / retest trigger:
~~~

Keep QA materials simple; screenshots can use polished materials after qualification. Do not distribute customer or library assets in test kits without explicit redistribution rights.

## Status table

| Scene | Status | Scene/evidence / media readiness |
|---|---|---|
| S01 Basic | NOT TESTED | — |
| S02 Courtyard | NOT TESTED | — |
| S03 Landscape | NOT TESTED | — |
| S04 Road/boundary | NOT TESTED | — |
| S05 Analyzer | NOT TESTED | — |
| S06 CS Edit | NOT TESTED | — |
| S07 Heavy | NOT TESTED | — |

## Completion criteria

Each selected scene has reproducible inputs, expected output, rights and qualification notes. At minimum S01 and one chosen lead workflow are usable for a limited beta; unbuilt/untested scenes stay pending. Public media uses only the qualified shortlist. Paid workload claims require the specific S07 evidence.

## Do not do yet

Do not require expensive commercial libraries, fabricate renders, copy competitor media, or add benchmark numbers before measurements. Do not build the future website here.

## Optional / later

Animated sources, studio farm/handoff and newer transport can become additional fixture variants once named customers need them.

## Next stage

[Stage 09 — Commercial and licensing decisions](09_Commercial_and_Licensing_Decisions.md).


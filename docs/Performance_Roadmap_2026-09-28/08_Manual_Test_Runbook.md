# 08 — Manual test runbook

**Use after a test bundle is delivered.** Today this is a procedure; the scene kit, backend selector and diagnostic export are planned implementation deliverables. No benchmark result has been recorded yet.

## What you will receive

- Separate baseline and candidate packages for each supported Max version, with binary/script hashes and install paths.
- Synthetic scenes or version-compatible scene builders, expected counts, fixed seeds/units, and a short list of steps per case.
- A developer diagnostic control for backend/thread limit and local result export; the exact commands will ship with the bundle.
- A list of changed stages and the specific operations expected to improve.

The user has requested all three performance areas and has no prepared scene/toolchain test setup yet. Begin with supplied synthetic scenes; add real production scene copies when available.

## 1. Prepare the comparison

1. Record Max full version/update, renderer/build, OS, CPU/cores, RAM, GPU/driver and display size. Use the sheet in [09](09_Results_and_Decisions.md).
2. Keep a copy of the original scene and the baseline package. Save test files to a separate folder.
3. Close Max before changing native binaries. Install one version-matched package, restart, and confirm the loaded module paths/build label. Never compare two accidentally loaded plugin copies.
4. Set the same viewport, point/face budgets, seeds, units, source geometry, renderer settings and machine power mode. Stop unrelated heavy work for idle tests.
5. Validate the expected scene counts and a screenshot before timing. A candidate that displays less work is not a valid speed comparison.

## 2. Quick smoke test after each build

| Action | Pass condition |
|---|---|
| Create scatter on a simple plane | Correct source/placement count and visible result |
| Change count, seed, transform and density settings | Correct refresh; old state does not overwrite new state |
| Switch point, proxy and full geometry display | Expected budget/selection and no stale cache |
| Create an Analyzer area | Expected mode, paths and sample count |
| Add CS Edit, select/move/delete, undo/redo | Same instances are edited; no unexpected Reset Edits |
| Start/stop a render | Correct particles/materials/transforms; no duplicate temporary objects |
| Save/reopen, clone, reset | Correct persisted state and cleanup |

Any crash, lost edit, changed layout or leaked scene object is a correctness failure. Record the scene and last action before resuming performance tests.

## 3. Scatter and editing comparison

Use S01–S04 and E01. Measure a seed change, parameter change, surface transform, source transform, blocker change, and no-change refresh separately. Test 1k/10k/100k instances; use larger stress cases only after checking memory.

For a drag, measure from release/input event to the first correct final preview, then compare the active-compute span. Existing throttling can affect perceived delay. Verify a burst of changes produces the final requested state and a bounded number of builds.

For CS Edit, repeat moves and selection after source/layer activity changes, lower-stack edits, undo/redo and reopening. A cache must keep picking and visible markers aligned. Compare placement/identity hashes from the diagnostic pack; screenshots alone do not prove compatibility.

## 4. Viewport comparison

Use V01/V02, fixed camera and display resolution. First measure rebuilding a changed preview. Then leave the scene unchanged and orbit along the supplied path for the same duration. Record frame-time median/p95, point/face counts, and build counters.

Test each proxy mode and full geometry at the same face budget. Include nonuniform and negative scale. Check colors, shading, occlusion and selection markers. Unchanged camera movement should not rerun scatter or Analyzer. Increasing FPS by silently lowering the display budget fails this comparison.

## 5. Analyzer comparison

Use S05 at 48/192/384/768 resolution where the fixture specifies it. Compare one element and many elements, nearby surfaces with shared exclusion, holes and tilted loops. Change fit radius, minimum points and relaxation. Record mode/path/point outputs and active analysis count as well as latency.

Test invalid topology and too-small radius errors. A new implementation must not publish partial results from successful elements when another element fails.

## 6. Render preparation and large scenes

Use R01/R02. Measure first render preparation, a repeated unchanged render, and a render after changing one source/layer. Keep render resolution/quality fixed. Record Cyrus/PFlow preparation separately from renderer translation and image-render time wherever diagnostics allow.

During interactive rendering, change a parameter several times, move a source, then stop. Verify the final scene, build counts, particle counts and material assignment. Test abort, save, reopen and scene reset. Temporary objects must have the same documented cleanup lifecycle as baseline; do not assume they disappear immediately at `postRender`.

Use M01 on a real 32 GB machine before declaring the minimum configuration qualified. Watch process memory and paging. A machine with more RAM cannot prove the 32 GB experience by a successful run alone. Record peak memory and whether the scene remained responsive.

## 7. CPU threading and GPU comparisons

Compare Reference CPU, Optimized CPU serial, and Optimized CPU with supplied limits such as 2/4/6 participants. Test idle and active-render sessions separately. Record the actual selected backend and limit.

Once a GPU bundle exists, compare its total path with the fastest accepted CPU mode. Include first-use compilation/startup and warm runs. Test explicit CPU mode, unavailable/disabled compute device, and a developer-provided allocation-failure test. Do not deliberately reset drivers in a production Max session.

Confirm GPU failure falls back to CPU for recoverable errors and reports why. GPU acceleration must not be required to open a scene or render it on a CPU-only compute configuration.

## 8. Collect results consistently

For quick screening use a small repeat set and label it preliminary. For acceptance, use three warmups and 30 measured warm operations plus five separate process-cold runs from [02](02_Baseline_and_Benchmarks.md). Export raw samples and correctness comparisons. A stopwatch can supplement diagnostics but is insufficient for tiny stage differences.

Repeat baseline and candidate in separate Max sessions and alternate their order. Do not compare different scene files, budgets or renderer settings without labeling the result as a separate experiment.

## 9. Report or roll back

Fill in case ID, build, expected/actual output, timings, peak memory, backend and steps to reproduce. Keep error logs and screenshots beside the result file; never overwrite the baseline evidence.

For a failure, close Max, restore the baseline package, restart and reopen the original scene copy. Confirm behavior recovers. Do not save an unexpectedly changed scene over the original. The implementation team uses the result to fix or disable the failing optimization before the next build.

# Detailed spline-edit recording review — October 1, 2026

Recording: [20261001-075219-b5cb2f6d](../build/performance-runs/20261001-075219-b5cb2f6d). Recovered [HTML report](../build/edit-trace-20261001-075219.html) and [JSON report](../build/edit-trace-20261001-075219.json).

## Was the test performed correctly?

**Yes, as a diagnostic editing test.** Detailed tracing was active on Max 2027.1 with Corona 15. The target remained `Cyrus Scatter001`, the artist explicitly watched `Plane001`, and all three edits have matching Begin/Result visible markers: `corner_move`, `extend_side`, `undo_extension`. This captures real editing updates rather than a forced preview benchmark.

The session lasted 151.68 seconds. Its 421 stage starts all have matching ends. There were 73 watched input notifications, no dropped rows, no collector errors, no unclosed spans, no unfinished edit and no recorded stage errors. All 1,350 passive layer observations were error-free. The external sampler stopped normally with 287 resource samples. A header-only `operations.csv` and zero measured controlled operations are expected for this workflow.

### Recorder defect found and corrected

Recorder 0.2.0 reused raw edit ID `1` after each Result visible marker. The earlier report grouped by raw ID, which would overwrite markers and mix work from separate edits. This was a recorder/report defect, not an artist mistake.

The labels, timestamps and complete marker sequence survived. The updated report reconstructs each marker occurrence separately and assigns stages from their starts within matching edit boundaries. Its window IDs are 1, 2 and 3; raw IDs remain `1` with an explicit recovery note. Repeated labels are also supported. The original recording files were not edited, and this test does not need to be repeated to recover its findings.

Recorder 0.2.1 now advances a separate edit sequence. Stop and close the recorder, then rerun [CyrusPerformanceMonitor.ms](../tools/performance/CyrusPerformanceMonitor.ms) for future recordings. The installed tracing hooks already worked in this run; this correction needs no plugin reinstall or Max restart.

## Edit windows

| Named edit | Begin to Result visible | First to last traced stage | Covered stage intervals, overlaps counted once | Preview builds across six layers | Analyzer calls |
|---|---:|---:|---:|---:|---:|
| `corner_move` | 13.43 s | 5.78 s | 5.46 s | 11 | 1 |
| `extend_side` | 15.40 s | 10.87 s | 5.55 s | 11 | 1 |
| `undo_extension` | 26.71 s | 23.25 s | 14.97 s | 34 | 2 |

Manual windows include preparation, editing and reaction time. First-to-last windows include gaps: the extension contains approximately 5.32 seconds outside recorded stage intervals, and Undo contains 8.27 seconds. Those gaps can include artist activity, event scheduling and uninstrumented host work; the trace cannot attribute them precisely. Covered intervals are wall time inside hooks, which may include waits. These figures are not exact mouse-release-to-visible latency or completed GPU frame measurements.

Another 151 completed stages occurred outside named edits, including work before the first marker. The whole-session aggregates include them; per-edit tables exclude them. Input notifications are handler receipts, not counts of artist gestures.

## What the nested timings tell us

| Metric | Corner move | Extension | Undo window |
|---|---:|---:|---:|
| Clover placement calls | 3 | 3 | 8 |
| Clover placement wall time | 4,571.74 ms | 4,489.87 ms | 11,138.01 ms |
| Clover share of covered intervals | 83.81% | 80.93% | 74.40% |
| Analyzer inclusive wall time | 3,545.93 ms | 3,506.50 ms | 7,164.98 ms across two calls |
| Analyzer wall time excluding recorded child spans | 85.18 ms | 89.31 ms | 150.79 ms across two calls |

**Clover is the strongest measured calculation target in this scene.** A clover placement call is nested inside Grass placements during Analyzer-triggered rebuilding. Clover is also calculated during its own preview rebuilds. This explains why a Grass preview can take about 1.5 seconds and why clover placements have more calls than clover preview rebuilds. Whether those calls can share results depends on their requested outputs and cache keys; repeated calls alone do not prove redundant computation.

**The complete Analyzer timer mostly contains scatter work.** Its recorded child spans include synchronous layer rebuilds. Treating the 3.5-second timer as an isolated surface-analysis cost would direct optimization toward the wrong measurement. Child-excluded time is the remaining wall time after recorded children, including uninstrumented work and waits; it is not a separately profiled native Analyzer kernel.

**The Undo-marked window contains substantially more repeated work.** Grass, clover, BushesCenter, Bourder and Street_Plant rebuilt six times each, and Leaves four times; the other two windows have two builds per most layers and one for Leaves. Twelve passive counter resets occurred during Undo in two groups of six layers. The detailed spans still count every traced call, so reset counters do not lose these measurements. The trace cannot establish whether the artist issued exactly one Undo or whether all repeated work was unnecessary.

Inclusive durations must not be added across parents and children. The report now shows child-excluded stage totals and covered intervals to make these relationships visible.

## Output and resources

| Last traced preview state within each edit | Generated placements | Displayed instances |
|---|---:|---:|
| Corner move | 52,143 | 6,314 |
| Extension | 71,410 | 6,404 |
| Undo window | 52,143 | 6,314 |

The extension produced more placements, and Undo restored the same generated/displayed counts as the corner-move result. Matching counts support a plausible Undo round-trip but do not prove identical transforms, source assignments or complete shape correctness.

Sampled peak whole-process private memory was **6.42 GiB**, working set **3.90 GiB**. Maximum sampled CPU was **21% of total capacity across 12 logical processors** on a Ryzen 5 5600X. These are whole-Max samples, including other host work and idle periods; they cannot establish per-stage CPU parallelism or imply a specific threading speedup. The recorded GPU is an RTX 3090, but GPU utilization/timing and Corona render statistics were not captured.

## How to proceed

1. Keep this recording as valid exploratory evidence. For a controlled before/after baseline, save and reopen a fixed starting scene, then record a specified vertex/edge displacement and one Undo with settling between edits. This run started with `scene_dirty: true` and `frozen_copy_attested: false`; its disk fingerprint does not identify the precise in-memory starting geometry.
2. Audit clover placement calls, especially the nested Grass/blocker dependency, and determine which outputs can reuse a cache safely. Add argument/cache-hit detail where needed before deciding that duplicate-looking calls can be removed.
3. Trace rebuild scheduling around Analyzer publication and Undo: source-change handling, analysis revision, invalidation and final preview publication. Check whether one final settled revision can replace multiple intermediate builds while preserving correct results and required live feedback.
4. Measure the chosen clover native stages before selecting algorithm, CPU threading or GPU changes. Verify matching placement output, Undo correctness and the same saved edit sequence after each change. This run supplies bottleneck evidence; it does not establish a speedup or require a rewrite.

## Verification of the recorder/report correction

Fourteen report checks passed: the original eight comparison checks and six edit-trace regression checks. The separate Max 2027.1 fixture passed compilation, real native Analyzer/preview calls, three advancing edit IDs, repeated labels, unmarked work, nested timing parsing, point/count parity, failures, cleanup and installer checks. Its successful trace is [20261001-080654-2b6946ca](../build/performance-monitor-test/runs/20261001-080654-2b6946ca), with logs under `build/performance-monitor-test`.

The correction changes recorder IDs, reporting and related documentation/tests. Scatter/Analyzer algorithms and installed plugin scripts were not changed in this review. Heavy-scene tracing overhead and exact input-to-frame latency remain unmeasured.

## Saved-scene follow-up — 20261001-083505-04babad4

Recording: [20261001-083505-04babad4](../build/performance-runs/20261001-083505-04babad4). [HTML report](../build/edit-trace-20261001-083505.html) and [JSON report](../build/edit-trace-20261001-083505.json).

**The `heavy_preview` case label did not change the recording behavior.** In the recorder it is stored as metadata; detailed tracing is controlled separately. This run has detailed tracing enabled, activity `idle`, complete named-edit markers and no controlled preview operations. Its actual workload is interactive surface-edge editing. No rerun is required merely to change the label, and the raw manifest is retained as recorded. The forced-preview comparison tool checks matching case labels but is not a comparison tool for these manual edit traces.

Recorder 0.2.1 produced distinct edit IDs 1, 2 and 3. All 396 recorded stages paired correctly, with no trace integrity warnings, dropped rows, collector failures, unfinished spans/markers or stage errors. The session lasted 110.79 seconds, with 68 watched input notifications, 852 error-free layer observations and 207 normally completed resource samples. Watching the controller first and then `Plane001` added watched nodes; the recorded Scatter target remained `Cyrus Scatter001`.

The recording started with `scene_dirty: false`, using the saved scene [SaveSelect 2.max](../Test%20Scene/SaveSelect%202.max). Its recorded SHA-256 is `8a40f6a1a5c47eacbbee92920e131f4cae04cfb0de6be1991b4719ea2860bd2c`; the scene on disk still matched that fingerprint when reviewed. Recorder, trace companion and sampler files also matched their recorded hashes. The manual saved-copy attestation checkbox was unchecked, so that explicit attestation remains absent. These observations improve starting-state provenance without retroactively changing the recorded checkbox value.

| Named window | Begin to Result visible | First to last traced stage | Covered stage intervals | Preview builds | Analyzer calls |
|---|---:|---:|---:|---:|---:|
| `corner_move` | 26.39 s | 4.33 s | 4.08 s | 11 | 1 |
| `extend_side` | 20.51 s | 15.18 s | 11.26 s | 22 | 2 |
| `undo_extension` | 27.77 s | 22.83 s | 20.72 s | 51 | 3 |

The same timing limits described above apply. In particular, Result visible for the corner move was clicked approximately 18.29 seconds after the last recorded stage ended; that interval cannot be assigned to plugin calculation from this trace. Thirty-six completed stages were outside named edits.

Clover placements again dominate: 3 calls totaling 3.34 seconds in the corner window, 6 totaling 9.11 seconds during extension, and 12 totaling 16.10 seconds during Undo. These account for approximately 81.92%, 80.87% and 77.70% of their respective covered stage intervals. Analyzer inclusive timers again contain scatter rebuilds; child-excluded Analyzer wall time was 66.36 ms, 155.69 ms across two calls, and 210.01 ms across three calls.

| Preview state | Generated placements | Displayed instances |
|---|---:|---:|
| Initially observed | 52,143 | 6,314 |
| Last corner-move output | 33,596 | 6,255 |
| Last extension output | 64,898 | 6,379 |
| Last Undo output | 33,596 | 6,255 |

Undo restored the corner-move output counts, not the initial counts. Counts alone do not establish identical transforms or an exact Undo sequence. Twelve passive layer-counter resets were observed; the detailed trace retained the individual calls. Sampled peak private memory was 6.36 GiB, working set 3.98 GiB, and maximum CPU 17% of the machine's total logical-processor capacity.

### Artist clarification and decision

The artist identified the edited boundaries as the left and right edges. Screenshots show `Plane001` in Editable Poly Edge mode, with `Edge 10 Selected` visible in one view. This is direct polygon-surface editing; the suggested `heavy_spline_edit` name was only a descriptive label. The movement distances, coordinate axes, identity of both edges and number of Undo commands are not known. The trace contains multiple update cycles in the extension and Undo windows, but callback counts cannot establish how many artist actions caused them.

**Retain this as usable saved-scene diagnostic evidence and begin the focused code audit.** There is no need to repeat arbitrary dragging just to rename the case or tick a checkbox. Its consistent hotspots support inspecting clover dependency/cache reuse and rebuild scheduling. Exact movement details are needed for a reproducible before/after claim, so the first optimization experiment should specify or automate fixed edge IDs, offsets, coordinate space and one defined Undo transaction, recording that recipe along with starting geometry/output checks. Capture the reference with the current implementation and repeat the same procedure with the candidate. No numerical speedup is established by comparing this run to the earlier recordings, which used different starting geometry, edit sequences and recorder versions.

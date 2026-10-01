# Spline-edit recording review — October 1, 2026

Recording: [20261001-072038-c3cf626b](../build/performance-runs/20261001-072038-c3cf626b).

## Does this record the intended workload?

**Partly.** This recording captures natural scatter rebuild activity and Max process resources while the artist edits the scene. It does not measure the exact elapsed time from a particular spline edit or mouse release to the final visible scatter result. It is sufficient to identify important instrumentation gaps before optimizing the plugin.

The session is labelled `heavy_spline_edit`, activity `idle`, targeting `Cyrus Scatter001`, and lasted about 54.1 seconds. It contains 492 layer observations (82 observations of six layers) and 98 independent process-resource samples. Both recorders stopped normally. No layer errors or counter resets were observed. `operations.csv` is header-only and the summary's measured-operation count is zero, which is expected: the forced preview benchmark was not run. There are no artist event markers; `events.csv` contains only the stop event. Thus individual changes cannot be labelled as corner move, extension or Undo from the data alone.

## Observed update bursts

| Observation window, seconds from recording start | Gap between observations | Rebuild-counter increase per layer |
|---|---:|---|
| 21.942–26.302 | 4.360 s | Grass, clover, BushesCenter, Bourder, Street_Plant: +2 each; Leaves: +1 |
| 37.298–43.237 | 5.938 s | Grass, clover, BushesCenter, Bourder, Street_Plant: +2 each; Leaves: +1 |

These are gaps in a nominal 500 ms UI-timer observer, **not exact edit-to-result timings**. They are consistent with the UI thread being busy during update activity but include sampling delay and potentially other Max work. A separate 3.724-second gap at startup coincides with recorder initialization and must not be labelled a spline-edit stall.

The counters show 22 layer-build increments across the session. Since most counters jump by two between observations, the recorder misses intermediate build durations and transient states. This supports investigating repeated rebuilds, but does not prove they are redundant: one drag can emit several legitimate geometry/dependency changes. No edit-event trace or Analyzer timing was collected to establish causality.

### Latest layer duration available at each burst

| Layer | First burst | Second burst |
|---|---:|---:|
| Grass | 1,000 ms | 1,544 ms |
| Leaves | 4 ms | 4 ms |
| clover | 1,172 ms | 1,467 ms |
| BushesCenter | 70 ms | 83 ms |
| Bourder | 195 ms | 231 ms |
| Street_Plant | 14 ms | 17 ms |

Each value is the **last** preview duration observed for that layer, not the sum of its builds in the gap. Adding these values cannot recover the total edit latency. Grass now has a substantial cost, unlike the roughly 60 ms Grass timer in the earlier forced-rebuild trial. The different workload/state prevents a controlled numerical comparison, but clearly shows why clover alone is insufficient as the editing-performance target.

Generated placements changed from 56,923 initially to 35,748 after the first burst and 46,816 after the second. These count changes show that new scatter output was produced. They do not verify shape correctness, complete fill, visual stability or an Undo round-trip.

## Resources and remaining limitations

- Sampled peak whole-process private memory: **6.46 GiB**; working set: **3.79 GiB**.
- Whole-session sampled CPU median **10%**, maximum **22%**, normalized across 12 logical processors. These samples include idle periods and all Max work; they are not per-stage utilization measurements.
- GPU utilization and FPS were not recorded. There are no Corona VFB measurements.
- The scene was already marked modified when recording began. Its saved-file fingerprint therefore does not define the exact starting state of this edit experiment.
- No changed-spline identity, vertex/edge displacement, mouse-release timestamp, Analyzer duration or final-frame completion was recorded. The passive reader also does not capture source geometry at each edit.
- A clean final layer state and an absence of sampled errors do not prove that every intermediate build was successful.

## Next engineering step

Keep this recording as exploratory evidence. Before changing performance behavior, add targeted tracing of the input-change event, Analyzer start/end, each affected layer's rebuild start/end and invalidation reason, and preview submission. Use event identifiers to connect successive work to an edit and distinguish repeated necessary updates from duplicate work. Track user release separately from the start of the drag; a lightweight screen recording or an explicitly qualified presentation measurement is still needed for visible completion.

Validate that instrumentation on a small scene first and measure its overhead. Then repeat a saved, specified edit sequence on the heavy scene: one small corner move, one fixed-distance extension, and Undo, with full settling between actions. Preserve the starting scene, update mode, density and display budgets. This provides a reproducible editing baseline; thirty forced rebuilds would measure a different workload.

No production plugin code, scene or original recording files were changed for this review.

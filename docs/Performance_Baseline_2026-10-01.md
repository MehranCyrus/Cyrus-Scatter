# First artist-scene performance trial — October 1, 2026

## Result and status

Recording: [20261001-063203-c5d0e48f](../build/performance-runs/20261001-063203-c5d0e48f). [Generated HTML report](../build/performance-baseline-20261001.html).

The recorder completed normally (`user_stopped`), including the external resource sampler. Two test batches each contained one warmup and three measured rebuilds: eight operations, six measured successes, zero failed operations. This is useful diagnostic evidence, **not yet an unchanged-scene engineering baseline**: source and Analyzer node positions changed between the batches. The report correctly blocks a before/after speedup comparison for this recording. No recorded settings changed during any individual timed operation. Generated/displayed output signatures stayed identical across the measured runs; equal counts do not prove identical placements or appearance.

## Measured preview rebuilds

The operation is the selected `Cyrus Scatter001` controller's `refreshDisplay()` call, including synchronization, preview rebuilding and redraw submission. It excludes completed GPU frames, interactive navigation latency and Corona render timing.

| Result | Value |
|---|---:|
| Combined measured median (descriptive only) | 1,886.68 ms |
| Measured range | 1,818.98–1,917.40 ms |
| First batch median | 1,868.67 ms |
| Second batch median | 1,886.77 ms |
| Successful measured operations | 6 |
| Failed operations, including warmups | 0 |
| p95 | Not reported: fewer than 20 measured samples |

### Layer observations immediately after measured operations

These are medians of each layer's existing preview timer, sampled after the six measured rebuilds. They include multiple stages; they do not identify an individual native algorithm. Combining these observations is descriptive because inputs changed between batches.

| Layer | Median preview time | Generated placements | Displayed instances |
|---|---:|---:|---:|
| Grass | 59.5 ms | 36,351 | 2,000 |
| Leaves | 4.5 ms | 200 | 200 |
| clover | 1,425.5 ms | 2,990 | 2,000 |
| BushesCenter | 76.0 ms | 57 | 57 |
| Bourder | 225.0 ms | 2,938 | 2,000 |
| Street_Plant | 17.5 ms | 33 | 33 |
| Total counts | — | 42,569 | 6,290 |

The clover timer is roughly 76% of the whole-operation median, making it the first profiling target. Layer medians need not sum to the whole-operation median. Clover records 90,066 requested placements and 2,990 generated placements. Its settings include density 600/m², diversity mode 2, fall-delete width 50, and an intentionally empty second source (`sourceEmpty #(false,true)`) weighted 1.0 against the plant source's 0.05. The undefined second source is therefore not, by itself, a missing-asset defect. The timer does not yet distinguish candidate generation, diversity/empty-source filtering, Analyzer falloff, source preparation or preview packing. Profile those stages before attributing the cost to any one of them.

## Resources and environment

- Max 2027.1, build 29.1.0.11426; Corona 15, build timestamp May 25, 2026 16:07:51.
- Ryzen 5 5600X: 6 cores / 12 logical processors; RTX 3090; approximately 96 GiB installed RAM.
- 231 external resource samples over approximately 119 seconds, nominal 500 ms interval.
- Sampled peak Max private memory: **6.58 GiB**; sampled peak working set: **4.01 GiB**. These are whole-process session peaks, not Cyrus-only memory or exact allocation peaks.
- Whole-session CPU sample median **7.5%**, maximum **15%**, normalized across all 12 logical processors. Session values include waiting and unrelated Max work. They do not prove a particular function is single-threaded or predict a threading speedup.
- GPU utilization was not measured. Corona VFB measurements were left blank. Reported FPS recording was disabled; the screenshot's 1 FPS is not a controlled navigation benchmark.
- The saved scene fingerprint is for `Test Scene/SaveSelect.max` (185,281,080 bytes), SHA-256 `0e0e3c32d23c1625c7d097d0bfa7e266ecebcc430e53022a894a153fc3c36d98`. It was reported clean at recording start.

## Why this recording cannot be the final comparison baseline

Between the first batch ending at 06:32:44 UTC and the next batch starting at 06:33:53 UTC, recorded source coordinates changed. For example, `grass_small` moved from approximately `[1196.34,3944.20,0]` to `[-587.50,658.44,0]`; the Analyzer reference moved from `[2498.97,2800.51,0]` to `[726.32,1271.33,0]`. Source references in five layers changed position, along with several Analyzer-reference settings. The log does not identify who or what moved them. The initial saved-scene fingerprint cannot represent both states.

The screenshot's **Start recording first** message is an inactive-recorder guard used by the rebuild and VFB-stat buttons. The exported session contains both completed test batches and a clean stop, so this message is not evidence that those recorded operations failed. The exact button/action that produced the message was not logged.

## Next run

1. Finish arranging sources, controllers and the viewport, then save a separate fixed scene copy. Close temporary diagnostic panels before saving.
2. Start a fresh recording with the same controller, `baseline-current`, `heavy_preview`, activity `idle`, and rendering/IR stopped. Confirm the saved scene matches the open scene.
3. Use **3 warmups and 30 measured runs**. Click the rebuild-test button once. Leave objects, parameters and viewport unchanged throughout the recording.
4. After completion, Stop & save and send the new folder path. Do not enter optional VFB statistics for this preview-only test.
5. Once the baseline passes validation, profile clover's stages first. Separately measure steady-state viewport navigation and Corona preparation/rendering. Do not use this preview timing as a GPU benchmark or an argument for an immediate rewrite.

Raw recording files were preserved. This analysis generated a report and documentation; it changed no production plugin code or scene.

# Artist editing retest of Cyrus Scatter 0.60

**Reviewed:** 2026-10-01. **Recording:** `20261001-104244-f41dc684`. **Verdict:** a complete, useful interactive recording that supports the artist's reported improvement. It is an exploratory edge-edit test; it does not complete the fixed three-repeat edge/Undo qualification.

## Evidence and setup

- [Original recording](../build/performance-runs/20261001-104244-f41dc684/manifest.json), [trace integrity summary](../build/performance-runs/20261001-104244-f41dc684/trace-summary.json), and [generated trace report](../build/edit-trace-20261001-104244.html). The accompanying JSON retains every paired stage and input notification.
- Recorder **0.2.2**, label **`cpu-v1-0.60-auto4`**, case **`heavy_surface_edge_edit`**, detailed tracing enabled. Normal user stop after **155.03 seconds**.
- Max **2027.1**, Corona **15** selected, activity recorded as `idle`. This recording supplies editing measurements, with no recorded Corona VFB measurements or completed GPU frames.
- Native module path contains content ID **`8e008627cd38`**. Its recorded disk SHA-256 matches the measured 0.60 engine: `c3656015ff349e0e9a8382eb694cc24ce39620da6d0758424abcb9d2750609fc`. CS Edit and Analyzer module hashes also match their delivered files.
- Max process started about **3 minutes 21 seconds** before recording. Installed Scatter/Analyzer script candidates and both measurement scripts match the expected hashes. Disk script hashes alone are not in-memory provenance, but the fresh process, native identity, working trace hooks and capability fields are consistent with the intended installation.
- CPU request **0**, automatic mode with at most four total participants for eligible queries. Native source filtering and transforms are available. The recording does not include per-call worker statistics; it cannot establish worker participation for every layer.
- Saved scene **`Test Scene/SaveSelect 2.max`**, clean at recording start, saved-copy attestation checked. Saved file SHA-256 **`8a40f6a1a5c47eacbbee92920e131f4cae04cfb0de6be1991b4719ea2860bd2c`** matches the earlier saved-scene recording and developer benchmark.
- Starting serialized layer/root settings match `20261001-083505-04babad4` exactly. Both recordings initially observed **52,143 generated placements and 6,314 displayed instances**. The viewport size/camera and subsequent geometry edits differ.

### Recording integrity

All **654** stages have matching start/end rows. There are **zero** dropped rows, collector errors, stage errors, unfinished stages or unfinished edit markers. Four named windows have distinct IDs and matching Result visible markers; none contains traced work ending after its visible marker.

There are **105** watched input notifications, **1,602** error-free layer observations and **292** resource samples. `Plane001` appears in the recorded input events, including the first edit: the recorder discovers referenced surfaces automatically. Clicking Watch selected edit object after the first window did not invalidate that window.

`operations.csv` contains only its header because this was a passive editing recording. **Zero controlled rebuild trials is expected here**, not a failed recording. Twelve observed layer-counter resets occurred during revert; the detailed trace preserves the calls independently of those counters.

## Observed timings

Comparison uses [the earlier manual recording](../build/performance-runs/20261001-083505-04babad4/manifest.json). These are whole-session medians **per layer preview rebuild**, including any nested work.

| Stage | Earlier median | 0.60 median | Earlier / current |
|---|---:|---:|---:|
| Clover preview | 1,496.30 ms | 304.74 ms | 4.91× |
| Grass preview | 298.26 ms | 221.90 ms | 1.34× |
| BushesCenter preview | 96.26 ms | 86.83 ms | 1.11× |
| Bourder preview | 200.25 ms | 196.32 ms | 1.02× |

The earlier recording has 15 previews per listed layer; this recording has 20. Clover's median observed preview duration is approximately **80% lower**, consistent with the improvement the artist felt. Border calculation remains substantial and changes little in these session medians.

**These are observational comparisons across different movements and output populations**, rather than a controlled measurement of an identical edit. They must not be presented as a universal 4.91× editing speedup. The [implementation report](Performance_Implementation_2026-10-01.md) retains the separate fixed-geometry comparisons and exact output checks.

Analyzer's inclusive median fell from **3,589.39 ms to 1,108.31 ms** across six earlier and nine current calls. Its child-excluded median is essentially unchanged: **69.37 ms versus 70.24 ms**. The large inclusive reduction comes from recorded nested scatter work; it does not show a faster isolated Analyzer algorithm.

### Named edit windows

| Window | Label | Begin to Result visible | Covered traced intervals | Layer previews | Analyzer calls |
|---|---|---:|---:|---:|---:|
| 1 | `right edg` | 18.83 s | 3.11 s | 22 | 2 |
| 2 | `right edg` | 13.98 s | 3.36 s | 22 | 2 |
| 3 | `left edg` | 37.03 s | 5.26 s | 33 | 3 |
| 4 | `revert` | 12.77 s | 5.40 s | 34 | 2 |

Covered intervals count overlapping parent/child stages once. Manual windows include artist movement, gaps and reaction time. Each contains multiple update cycles; **3.11–5.40 seconds is not the duration of one defined edge movement**. The trace records notification receipt after Max dispatch, rather than exact mouse-release latency, and does not time completed viewport frames.

The names are valid; spelling and reusing the same label for windows 1/2 do not affect the recording. The raw data does not specify exact offsets, edge IDs or Undo transaction count, so it cannot certify the prescribed +150/−150 cm sequence or three repetitions.

## Remaining work identified by this trace

There are **111 layer previews** across nine Analyzer calls. For the first seven Analyzer updates, the trace shows a six-layer preview pass followed by an Analyzer call containing another five-layer pass. Counts can change between those passes as Analyzer results update; removing the second pass without dependency checks would risk publishing stale results.

The revert window adds two pairs of consecutive six-layer passes with identical generated/display counts within each pair. The second passes took approximately **775 ms** and **678 ms** of covered preview work. Matching counts alone do not prove identical transforms or input revisions, but these are concrete candidates for checking unnecessary invalidation and rebuild scheduling.

| Actor | Share of named-window traced wall time after excluding recorded children |
|---|---:|
| Clover | 40.50% |
| Bourder | 23.80% |
| Grass | 18.95% |
| BushesCenter | 10.32% |
| Analyzer | 3.89% |

These shares describe the approximately **17.12 seconds of covered stage work** across all four windows. They include uninstrumented work and waits inside those stages; they are not CPU utilization or native-kernel shares. Clover remains the largest contributor, but it no longer accounts for roughly four-fifths of recorded work as in the earlier trace.

**Next engineering priority:** inspect the ordering of surface invalidation, Analyzer publication, blocker revisions and Scatter rebuilds. Aim to rebuild dependent layers from the current Analyzer result and reuse valid blocker/source data. Verify revisions and output parity before suppressing any pass. If preparation remains costly after that, add finer stage timings around Clover/Grass/Border preparation and preview construction. This recording does not justify choosing CUDA/OpenCL as the next change.

## Output and resources

| Settled observation | Generated placements | Displayed instances |
|---|---:|---:|
| Start | 52,143 | 6,314 |
| Window 1 visible | 48,183 | 6,303 |
| Window 2 visible | 38,979 | 6,276 |
| Window 3 visible | 38,370 | 6,272 |
| Final revert visible | 62,646 | 6,369 |

The final revert **does not restore the starting counts**. This does not establish an Undo defect: a window may include several moves, and the number of Undo operations is unspecified. It means this recording cannot verify restoration to the initial geometry. Counts also cannot prove exact transform/source parity. All layers are clean and report no error at the final observation.

Sampled peak private memory was **6.60 GiB**, working set **4.04 GiB**, and CPU **21% of total logical-processor capacity** on the 6-core/12-thread Ryzen 5 5600X. The earlier session peaked at 6.36 GiB private memory and 3.98 GiB working set. Different geometry, session duration and allocation history prevent attributing this difference to the upgrade or diagnosing a leak. Samples can miss short allocation peaks. This is not a 32 GB minimum-system qualification or a renderer-contention test.

## Decision

**Keep this recording; no rerun is needed to make it useful.** It validates installation, error-free interactive tracing and a substantial reduction in the previously dominant Clover stage, consistent with the artist's experience. It also supplies the next rebuild-scheduling investigation.

For reproducible interactive Undo/latency qualification, use the [fixed edge/Undo runbook](Performance_Upgrade_Test_2026-10-01.md): one specified world-space offset, one Undo after each move, and three repetitions from the original saved scene. Treat that as a distinct qualification run. Corona production/IR, exact interactive output restoration, other Max versions and longer memory/lifecycle tests remain open.

This review generated reports and updated documentation only. The raw recording, plugin code, installed files and scene were not changed.

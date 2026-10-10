# Four painting prototypes — initial 0.1.0 results

Four independent Max 2027 trials are implemented and packaged. **9,792 native assertions, 186 scripted Max checks and four extracted-package smoke tests passed.** These passes cover the features exercised below, not the full qualification plan. **C and D fail the connected-fold surface-distance test. No winner or Cyrus integration is proposed.**

Baseline: Cyrus 0.77, `880ea89b654a389191c02e7a373807044ec713f1`, branch `codex/workflow-0.75`. All implementation lives in `experiments/paint-methods/`. Production source/version and installed plugins were not changed. Tests used owned hidden Max processes and disposable profiles; no computer use. The artist's Max process remained open and was not used for these tests. All final test processes exited normally.

## The delivered experiments

| Method | Authoritative representation | Implemented behavior | Important limit |
| --- | --- | --- | --- |
| A — Vector Regions | Current closed integer contours and holes, using pinned public Clipper2 | Hard swept union/difference, exact contour display, polygon inclusion queries, Undo/Redo | Projected terrain; no soft interior opacity, fade or spline interchange yet; contour queries have no spatial index |
| B — Tiled Density Mask | Current grayscale values in sparse 32×32 projected tiles | Hard/soft paint and erase, per-gesture maximum-influence stencil, copy-on-write history | Projected terrain; accuracy/storage depend on pixel size |
| C — Surface Stroke Volumes | Ordered analytic variable-radius swept segments, face/barycentric anchors and BVH | Hard/soft chronological queries; sphere paint/erase; derived resolved border | Euclidean footprint reaches nearby parts of the same mesh; history and index/snapshot costs grow |
| D — Baked Surface Field | Current grayscale values in sparse face-local grids | Sub-face detail on a two-triangle plane, soft paint, seam regression, sphere paint/erase | Current footprint uses connectivity/normal-restricted Euclidean distance; geodesic propagation is **not implemented** and connected folds leak |

Each has its own `PaintLab1..4.dlx`, `paintLabA..D` API and window. The adapter and low-level utilities are shared; the authoritative representations are distinct. Each extracted package loaded independently without Cyrus, Analyzer, Licensing or MCP. The common core was written independently of Cyrus paint code. Public Clipper2 is pinned with its license and file hashes under [third_party](../../third_party/clipper2/PROVENANCE.json); no proprietary pseudocode was copied.

All four support explicit receiver-bound named regions, repeated gestures editing one region, hard Paint/Erase, variable-radius sweeps, dedicated Undo/Redo, Cancel, Clear, `.plab` export/import and boundary/fill/sample diagnostics. Receiver changes suspend a region and preserve data. These transient lab regions are **not embedded in saved Max scenes**; export before closing. There is no full scatter/model/population system in this lab.

## What passed

- Independent analytic disk and dense variable-radius disk-sweep oracles outside a declared five-unit error band on the test fixture; chronological erase/repaint, continuous sweep and miss-gap breaks.
- Exact saved-state Undo/Redo equivalence, Cancel, external save/load and geometry-mismatch rejection. Invalid edits/display-budget refusal retained authoritative paint.
- Twenty-four growing islands retained all earlier sampled centers. Complete previews above the old 32,768-triangle threshold retained earlier coverage after a second region was added.
- All four host APIs loaded from verified owned paths. Scripted native Painter screen-ray callback replay, Start/Stop, receiver deletion, 21 independent receivers, window compilation/binding/start/stop/close.
- Sphere paint/erase for C/D. A/B explicitly rejected their unsupported sphere domain.
- Cached CPU preview consumed on redraw without another paint evaluation. This does **not** prove retained GPU uploads or viewport FPS.
- Four individually extracted packages verified hashes, opened/bound their window, started/stopped Painter, closed/shut down and exited normally.

The [feature matrix](FEATURE_STATUS.md) distinguishes partial rows from completed checks. Physical mouse/tablet behavior, Escape/selection-change handling, display correctness to a numerical border-error target, deformation and the entire test contract remain open.

## Failures and repairs

The [connected-fold diagnostic](domain-diagnostics.csv) joins two close parallel sheets with a distant bridge. Painting the first sheet with radius 20 also gives weight **1** on the second sheet in C and D, although distance along the mesh is much greater than the radius. A/B reject this projection domain. C's Euclidean behavior is expected from its current definition; D's current restriction fails the planned freeform surface-distance requirement. Distinct face storage alone does not solve footprint leakage. General freeform acceptance requires another footprint experiment or an explicit domain restriction.

The first D host test exposed lost coverage along a reversed triangle diagonal. Clamping face-grid edge samples to the triangle fixed the tested seam; native and Max regressions now pass. This does not qualify arbitrary mixed-size/non-manifold seams.

Early soft feedback hid values at or below 50%. Fill/samples now show all nonzero weights with brightness; the derived soft border is explicitly a **50% contour**. Early MAXScript windows had cast/closure errors; final windows compile. The first extracted-package smoke failed because the startup script treated the rollout global as a local undefined value; the launcher now declares it explicitly. [Draft failure receipt](package-smoke-draft.json) is retained alongside the [four final passes](package-smoke.json).

A final SDK inspection caught a radius/diameter mistake in the shared adapter: `SetMinSize`/`SetMaxSize` take radius. Doubling the requested value would have made physical brush footprints too wide; the original direct callback replay would not catch it. The adapter now passes the requested radius unchanged, replay reads the effective SDK radius, and host checks verify the SDK value plus inside/outside footprint probes. Physical cursor presentation and cross-unit calibration still require artist trials.

Several fixture repairs corrected the harness: snapshotAsMesh was already world-space (an extra transform incorrectly moved the 21-receiver probes), path comparison needed normalization, and MAXScript exception/scope syntax needed correction. None of those fixture failures is counted as a passed prototype feature before rerunning.

## Repeated CPU measurements

Ten independent process repetitions, Release x64, fixed seeded 100,000 queries on a 1,000-unit two-triangle plane, precision 5; radius 20; 1,000 growing-area gestures. Edit time includes all 1,000 gestures, commits and their current Undo/index work. Query timing excludes candidate generation. These are CPU microbenchmarks, **not individual pointer latency**.

| Method | Edit 1,000 gestures, median ms | Query 100k, median ms (min–max) | Current state bytes | Conservative logical history bytes | Accepted candidates |
| --- | ---: | ---: | ---: | ---: | ---: |
| A | 53.585 | 18.897 (18.703–20.219) | 7,584 | 6,446,624 | 79,595 |
| B | 12.492 | 4.901 (4.810–5.064) | 150,192 | 88,225,284 | 79,810 |
| C | 233.699 | 57.849 (56.870–59.678) | 288,048 | 147,429,632 | 79,641 |
| D | 14.748 | 5.011 (4.891–5.338) | 192,152 | 112,095,732 | 79,768 |

Source data: [all 320 benchmark rows](core-timings.csv), [summary and executable hash](core-summary.json), [benchmark recipe](../../tests/benchmark.cpp). Runs also cover 1/10/100 gestures and repeated same-footprint overlap.

A produced the smallest current-state footprint on this fixture. B/D queries read current values and avoid historical stroke evaluation. C exceeded the provisional 50 ms/100k query target here; its current history snapshots/index rebuilds also contribute to edit cost. That is a result for this implementation, not a lower bound for the whole method family.

Accepted counts differ because approximations differ. The five-unit oracle band is not a measured maximum error, and these trials do not complete the planned 1/2/5 mm accuracy tiers. **Do not rank methods by timing until error and supported domains are matched.** Logical byte counters omit some container/allocator/display overhead and conservatively double-count shared tiles/contours across history. They are neither actual resident allocations nor peak memory.

## Max observations

One final complete host campaign: Max file version `29.1.0.11426` (2027), AMD Ryzen 5 5600X / 6 cores / 12 threads, RTX 3090 / driver `32.0.16.1047`, 102,986,215,424 bytes physical RAM. Artist Max remained open; this was not an idle-workstation performance certification.

For the large-preview fixture (1,000-unit plane, radius 400, paint precision 2, display step 4), complete CPU preview preparation produced:

| Method | Preview preparation ms | Filled preview triangles |
| --- | ---: | ---: |
| A | 66.740 | 125,839 |
| B | 56.907 | 125,964 |
| C | 74.911 | 125,976 |
| D | 61.771 | 125,964 |

These are single scripted observations, not meaningful p95/p99 estimates. The callback replay contains only three timed samples per method. Presented input latency, FPS, upload reuse, GPU draw cost and physical brush feel are **unmeasured**. The current shared preview rebuilds the complete subdivided CPU mesh; it does not implement dirty-chunk retained Nitrous rendering. Its 300,000-cell/2,048-subdivision guard refuses an oversized complete preview rather than publishing a truncated tint. That protects completeness in the tested cases but can still interrupt interaction.

The 128 MiB state and 512 MiB logical history guards are initial controls, not qualified bounds on peak process allocation. Allocation-failure injection and long-session memory plateau tests remain open.

## Try and reproduce

Use the [trial instructions](../../docs/USAGE.md). Open one extracted folder and run **Try.cmd**; it starts a separate Max 2027 process. Do not manually install these into the normal profile.

- [A — Vector Regions package](../../dist/0.1.0-final/01-vector-regions/)
- [B — Tiled Density Mask package](../../dist/0.1.0-final/02-tiled-mask/)
- [C — Surface Stroke Volumes package](../../dist/0.1.0-final/03-surface-volumes/)
- [D — Baked Surface Field package](../../dist/0.1.0-final/04-surface-field/)

Source is portable experimental C++; build/launch scripts currently pin this workstation's MSVC/SDK/English Max paths. Packages are local ignored outputs, not tracked binaries. ZIP and content identities are recorded in [packages.json](packages.json). [Delivery validation](delivery-validation.json) and [native assertion output](native-checks.txt) are retained. Native build/source/DLL identities are in [build-receipt.json](build-receipt.json); the initial CPU benchmark build is retained in [core-build-receipt.json](core-build-receipt.json), whose kernel sources match the final build. The corrected final host fixture identity is in [host-launch.json](host-launch.json). Host receipts: [loaded paths](host-loaded.tsv), [186 checks](host-checks.tsv), [timings](host-timings.csv), [machine/limits summary](summary.json).

From the repository root, choose fresh output folders:

```powershell
python experiments/paint-methods/tools/generate_ui.py
python experiments/paint-methods/tools/build.py --output experiments/paint-methods/build/reproduce-01
python experiments/paint-methods/tools/measure.py --build experiments/paint-methods/build/reproduce-01 --output experiments/paint-methods/results/raw/reproduce-01
experiments/paint-methods/build/reproduce-01/lab_diagnostics.exe
python experiments/paint-methods/tools/host.py --build experiments/paint-methods/build/reproduce-01
python experiments/paint-methods/tools/package.py --build experiments/paint-methods/build/reproduce-01 --output experiments/paint-methods/dist/reproduce-01
python experiments/paint-methods/tools/smoke_packages.py --packages experiments/paint-methods/dist/reproduce-01 --output experiments/paint-methods/results/raw/reproduce-01/package-smoke.json
```

The host command returns an owned run directory; inspect its done/error files and wait for its process to exit before another timing run. Native build tests run automatically. No production build is required.

## Next acceptance steps

1. Artist draws the same expanding scribble with each package, checking border/fill/query disagreement and comfort at small/large radii.
2. Match measured accuracy tiers; extend long physical traces, event rates, dense/coarse geometry, rotated/scaled receivers and complex cuts. Capture actual event tails and peak memory.
3. Test a true surface-distance footprint for D and an explicit alternative/restriction for C. Rerun the connected-fold counterexample before any freeform recommendation.
4. Measure dirty preview extraction and retained draw transport separately, then add the useful vector spline/fade workflow. Qualify lifecycle/storage before selection.

We can revise or reject any candidate. Existing implementation effort is not a selection criterion.

# Performance measurements and acceptance

Performance work must preserve placement correctness. An operation that silently reduces spacing, ignores authored surface/obstacle rules, changes physical scale or returns an incomplete native transaction is not a valid speed improvement. Surface exclusions govern the anchor; explicit obstacle volumes define physical keep-clear space, as described in the [quick start](ARRANGE_QUICKSTART.md).

The **0.3.1** work adds passive native Modify controls and a real prepared-model
fixture. Its correctness campaign checks unchanged cache/placement work during
panel browsing, but supplies no new controlled timing or FPS comparison. The
timings below remain historical measurements on their explicitly named builds;
they are not benchmarks of the new real-model scene. Current evidence is in
[the 0.3.1 release record](RELEASE_VALIDATION_0.3.1.md).

## What is implemented

The archived **0.1.2 baseline** captures geometry, inspects support, builds the fit query, solves and publishes synchronously on Max's main thread. Asset capture and material/visual extraction are part of Generate. Its historical repeated-seed measurements below include full recapture and query construction.

**0.1.3 implements same-time numerical geometry/query reuse**, enabled by default in the current source, with phase diagnostics and retained requested-allocation accounting. Commands still reconcile current region rules, recapture source-backed assets, solve, and stage current visual/material data before publication. Native46 has completed the exact functional and two-order performance campaigns described below. Current installer/distribution status belongs to the [release ledger](RELEASE_VALIDATION_0.1.3.md), rather than being inferred from performance. See the [cache runtime contract](CACHE_RUNTIME.md) and [implementation plan](CACHE_IMPLEMENTATION_PLAN.md).

Work, geometry, candidate and placement limits constrain admitted operations. They are distinct from elapsed-time guarantees and whole-process RAM limits. Library operations and allocator overhead require their own admission analysis. Native26 admits expected round-join tessellation before the Clipper operation, preserving the requested clearance and tolerance. The bound covers raw joins, not all temporary finishing-union storage; result admission remains in place.

## Native46 paired cache measurements

The completed exact-build campaign is recorded in `build/final-46-performance/receipt.json`. Its two fresh private Max processes each pass **1,109 checks**, and `tools/verify_cache_performance.py` independently validates both raw exports. A separate arithmetic replay in `build/final-performance-independent-review-01` reproduces every condition summary, paired delta and order stratum from the CSVs. These timings belong to native46; installer/distribution status remains governed by the [release ledger](RELEASE_VALIDATION_0.1.3.md).

Each run contains 144 commands: 120 paired measurements, four seed baselines and twenty separately recorded context Generates. The two runs supply 240 paired command samples, not 240 independent scenes. Every fixture/operation/condition below has ten samples per run. Positive saving is the median of **matched cold-minus-reused differences**, not a subtraction of unrelated condition medians. Preparation sums lookup stamping, furniture capture, inspection, registry binding, obstacle capture and query construction. Whole-command Stopwatch time also includes asset refresh, solving, visual/material staging, publication and Undo. Cold clears optional geometry before timing; reuse stays enabled in both conditions.

All values are milliseconds. A condition's nearest-rank p95 is its maximum at this sample size; no tail-latency guarantee follows.

| Order | Fixture / operation | Prep median cold → reused | Paired prep saving | Whole cold median / p95 | Whole reused median / p95 | Paired whole saving |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Forward | TV / Generate | 2.804 → 0.645 | 2.107 | 162.744 / 207.285 | 157.750 / 201.481 | 3.035 |
| Forward | TV / Preview | 2.808 → 0.649 | 2.106 | 7.953 / 11.887 | 5.819 / 7.246 | 2.377 |
| Forward | TV / Commit Preview | 2.844 → 0.670 | 2.103 | 176.524 / 208.319 | 157.546 / 205.954 | 1.903 |
| Forward | Shelf rows / Generate | 3.036 → 0.661 | 2.366 | 164.998 / 220.787 | 170.358 / 226.049 | 0.860 |
| Forward | Shelf rows / Preview | 2.976 → 0.660 | 2.383 | 10.645 / 13.725 | 8.145 / 11.024 | 2.372 |
| Forward | Shelf rows / Commit Preview | 2.853 → 0.624 | 2.234 | 165.618 / 221.899 | 167.737 / 253.033 | 2.059 |
| Reverse | TV / Generate | 2.949 → 0.755 | 2.191 | 168.353 / 203.924 | 155.725 / 204.905 | 2.103 |
| Reverse | TV / Preview | 2.814 → 0.686 | 2.135 | 7.895 / 10.941 | 5.876 / 8.538 | 2.093 |
| Reverse | TV / Commit Preview | 2.744 → 0.662 | 2.108 | 159.587 / 205.754 | 156.454 / 199.899 | 2.616 |
| Reverse | Shelf rows / Generate | 3.027 → 0.608 | 2.415 | 165.396 / 221.725 | 165.337 / 212.698 | 2.185 |
| Reverse | Shelf rows / Preview | 2.943 → 0.607 | 2.326 | 10.174 / 15.914 | 8.136 / 9.612 | 2.300 |
| Reverse | Shelf rows / Commit Preview | 3.059 → 0.627 | 2.346 | 168.176 / 224.524 | 163.952 / 208.751 | 3.065 |

Preparation consistently saves about **2.1–2.4 ms per paired median** in these fixtures. Whole Generate has a smaller, variable effect: TV saves 3.035 / 2.103 ms and shelf rows 0.860 / 2.185 ms in the forward/reverse paired medians. Some individual reused calls are slower. For example, shelf Commit's forward paired differences range from −90.191 to 11.137 ms; no outlier was discarded. The forward shelf Generate's reused condition median is higher even though its paired median saving is positive. Pairing matters, and these results do not establish a universal whole-command improvement.

Reused Generate spends a median **96.4% / 96.2% (TV)** and **95.2% / 95.2% (shelf)** of native total time in visual capture plus publication, computed from each command's phase fraction. Its visual-capture medians are approximately 138–145 ms and publication medians 13–18 ms. Skipping a few milliseconds of geometry preparation does not remove the main Generate cost. Preview omits visual/node publication; its reused medians are about 5.8–8.1 ms, with paired savings about 2.1–2.4 ms.

The second process reverses condition order and its seed association. **Both processes still run TV before shelf**; fixture order is not reversed. Whole-command paired medians split by condition order as follows, with five pairs per cell:

| Fixture / operation | Forward cold first | Forward cold second | Reverse cold first | Reverse cold second |
| --- | ---: | ---: | ---: | ---: |
| TV / Generate | 1.282 | 6.505 | 1.389 | 2.816 |
| TV / Preview | 1.908 | 2.434 | 1.916 | 2.404 |
| TV / Commit Preview | 1.869 | 7.757 | 2.309 | 4.418 |
| Shelf rows / Generate | -1.318 | 1.376 | 4.645 | 0.166 |
| Shelf rows / Preview | 2.163 | 2.700 | 1.890 | 2.327 |
| Shelf rows / Commit Preview | 1.249 | 6.313 | 0.962 | 3.300 |

A context Generate establishes the same previous complete logical state before each condition. Within all sixty pairs per run, solver work matches exactly. Every measured reused command and all twenty context commands per run are native validated hits, with zero executed inspection/query work and zero furniture-capture, inspection, obstacle-capture and query-build phase time. All sixty measured cold commands execute the original geometry work. Asset refresh and solving still run. These diagnostics establish hits; elapsed time does not.

Both orders retain full-size props, complete seed-specific pose/ID/group/warning/statistic equivalence, actual Preview bounds and committed-node retention. The independent raw validator checks analytic board support, actual dimensions/transforms, nonpenetration and row adjacency. TV accepts **44 / 44 props**, five regions and no groups; shelf accepts **56 / 56 props**, eight regions and thirteen or sixteen rows by seed. Both have zero underfill and one unchanged conservative-fit warning. The procedural source geometry is 84 triangles / 3,784 sampled cells for TV and 120 triangles / 3,660 cells for shelf. These moderate fixtures do not establish imported high-polygon-scene timing.

Measured worker PIDs are **20,604 and 32,708**; launcher PIDs differ. The root orchestrator records serial scheduling and no overlapping owned build, QA or render workload. Two artist/project Max processes remained open, with background activity uncontrolled. Machine context is Windows 11 Pro build 26300, AMD Ryzen 5 5600X, six physical cores / twelve logical processors, about 103 GB physical RAM, Max 2027.1, and a 10 MHz high-resolution Stopwatch. Serial ownership does not establish an idle machine.

Paired samples accumulate between three and fifty-one prior publications per fixture. There is no forced garbage collection or Undo flush. Accounted live retained cache totals are **223,560 bytes (TV)** / **214,616 bytes (shelf)**; the included metadata breakdown is also exported separately. Whole-process private memory spans roughly 4.19–4.39 GB and includes Max, materials, source geometry, output nodes and history. Neither process deltas nor lifetime working-set peaks measure per-command allocation or prove a leak.

The audit's `summary.json` preserves conditional median/p95/min/max, paired distributions, native phases, order strata and input hashes. Raw data and the exact schedule are described in [PERFORMANCE_PROTOCOL.md](PERFORMANCE_PROTOCOL.md). No viewport FPS, renderer speed, arbitrary proxy/displacement behavior, stress-scene guarantee or user-interaction latency target was measured. Functional import/render and installer qualification remain separate evidence.

## Historical native25 gallery samples

| Exact run | Operation | First / repeat Generate |
| --- | --- | --- |
| `build/host-book-rows-gallery-02`, native25 | Original TV console, 16 props including three separate rows | 155.19 / 155.15 ms |
| Same run | Original open shelf, 25 props including five separate rows | 239.82 / 240.70 ms |

These are Stopwatch samples from `book-row-performance.csv`, including recapture, support/query construction, solve, visual/node publication and history. The gallery overlapped a separate isolated inspector test process. They are not a controlled benchmark or a cold-versus-cache comparison. Render work also changes process memory between later samples, so the before/after balance samples must not be interpreted as a performance comparison.

The CSV records the process working set before/after each command and its lifetime peak. Those include Max, plugins, scene/history and rendering resources; they are not native solver allocation counts. The original 0.1.1 gallery measurements remain separately preserved in its [release validation](RELEASE_VALIDATION_0.1.1.md).

## Measurement requirements

A serial isolated Max harness is implemented in `tests/max/arrange_performance_tests.ms`, with an independent CSV validator in `tools/summarize_performance.py`. Prefer running without other test/build processes contending for the same machine. Existing artist applications and unrelated project tasks remain untouched; record competing processes instead of closing them. A run with background workloads can validate the schedule and result equivalence, but is not an idle-machine performance baseline.

Measure a representative small TV console and medium open shelf before expanding to larger admitted inputs. Use original procedural furniture and source-backed physical-scale books. For each case record initial Generate, ten unchanged-seed repetitions and ten alternating-seed generations, followed by Preview/Commit operations. Keep file writing, report formatting and independent oracles outside the timed command interval.

Record raw samples, median, p95, requested/accepted/underfilled counts, candidates, fixture dimensions, native module/source identity, Max version and process memory. Check complete placement/group records by seed, actual full-bounds support, Preview/Commit agreement and unchanged published nodes during Preview. Log errors and rejected inputs; never omit failed samples to improve the reported result.

Do not impose a fabricated universal speed threshold. Report the observed scope and identify commands that interrupt practical interaction. If profiling motivates a change, compare the same admitted fixture and authored state, disclose history/background load, and retain the raw before/after evidence.

## Cache acceptance boundaries

The implemented cache retains raw furniture inspection and immutable fit-query geometry at the same scene time. It reapplies current region identities and rules, recaptures required sources, solves and publishes through the existing transaction. Hits cannot bypass invalidation, lower budgets, source validation, full fit or locked-row checks.

Native46's completed opposite-condition-order schedules and independent raw validation supply the measured scope above. Retained allocations and old/new/scratch overlap remain separate from whole-Max memory. Eviction, active leases, Undo/Redo, load/clone, time/unit changes, transforms, topology, hierarchy, source edits and injected failures belong to the exact-candidate functional campaign; timing cannot replace those checks, and earlier scoped receipts do not qualify a later build. A valid command too large for optional retention must still run cold.

See [qualification scopes](QUALIFICATION_SCOPES.md), [the active requirement ledger](GOAL.md), [qualified 0.1.2 evidence](RELEASE_VALIDATION_0.1.2.md) and [working 0.1.3 evidence](RELEASE_VALIDATION_0.1.3.md) for completed versus pending gates.

## Historical 0.1.2 native28 repeated-command evidence

`build/host-performance-03/measurement-qualification.json` binds the exact native28 build, host receipt, validator and raw files. The host passes **292 assertions**, covering **86 complete Generate/Preview/Commit calls** and **20 actual passive UI refresh pairs**. The independent CSV validator passes; pointer-sized Max node handles roundtrip through text and resolve back to their actual nodes. The two earlier runs preserve the formatter failures and are not used for timing summaries.

| Fixture | Requested / accepted | Repeat Generate median / p95 | Repeat Preview median / p95 |
| --- | ---: | ---: | ---: |
| TV console, ordinary physical books | 44 / 44 | 236.12 / 309.00 ms | 5.99 / 7.90 ms |
| Open shelf, book rows and height balance | 56 / 56 | 225.36 / 279.44 ms | 7.60 / 9.19 ms |

Each repeated column has ten samples; p95 is the nearest-rank maximum at this sample size. Both fixtures have zero underfill in these schedules. Full pose/group identities, physical sizes/support/nonpenetration, Preview output retention, Commit agreement and passive refresh behavior pass. These moderate original fixtures do not measure imported high-polygon scenes or worst-case population limits.

Only this task's performance process ran during measurement, but artist sessions and unrelated project Max processes were present. The saved process inventory records them. This is a valid scoped command/equivalence measurement under background load, not an idle-machine baseline. Generate includes source visual/material capture and scene publication; Preview omits publication. Their difference motivates phase instrumentation but does not alone attribute the cost to one internal stage. No geometry-cache speedup is claimed.

Raw files and the complete schedule are described in [PERFORMANCE_PROTOCOL.md](PERFORMANCE_PROTOCOL.md). Whole-process memory remains distinct from retained native allocations, and native Undo history accumulates during each case.

## Historical preliminary native40 forward cache measurement

`build/host-cache-perf-forward-01` passes **1109/0**, with independent raw-CSV validation, exact loaded modules/private profile and unchanged artist profiles. It records 144 trace commands: 120 paired samples, four seed-baseline commands and twenty separate predecessor-context commands. Each fixture/operation has ten cold/reused pairs. Native hit/work diagnostics and complete poses/groups/stats/warnings match the appropriate seed; shorter time alone is not used as proof of reuse.

The observed median **within-pair geometry-preparation savings are approximately 2.1–2.5 ms** on these two original fixtures. Preparation comprises lookup stamping, furniture capture/inspection, registry binding, obstacle capture and query construction. Whole-command timing also includes asset refresh, solving, visual/material staging, publication and Undo.

| Fixture / operation | Median paired preparation saving, ms | Median paired whole-command saving, ms |
| --- | ---: | ---: |
| TV / Generate | 2.070 | −0.802 |
| TV / Preview | 2.183 | 2.136 |
| TV / Commit Preview | 2.104 | 2.472 |
| Shelf rows / Generate | 2.194 | 0.871 |
| Shelf rows / Preview | 2.508 | 2.756 |
| Shelf rows / Commit Preview | 2.474 | 5.644 |

Positive saving means cold minus reused elapsed time; a negative value means the reused call was slower. A median paired difference is not the difference between separate condition medians. **This run does not show a consistent whole-Generate improvement.** Visual capture and publication account for about 95–96% of reused Generate's native time in these fixtures. All samples and outliers remain included; with ten samples, nearest-rank p95 is the maximum.

This is one preliminary schedule on **native40**, with other artist/project Max processes present. The schedule alternates cold-first/reused-first pairs, but the second fresh process must reverse the seed/order association. Later builds and imported assets are not qualified by these timings. At that historical point, final order runs, the final functional collection and delivery qualification were pending. Native46 above supersedes its performance scope without combining their samples; no blanket Generate speedup, idle-machine result or large/imported-scene performance claim follows. The preserved detailed audit is `build/cache-performance-observations-01.md`.

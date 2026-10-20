# Command performance protocol

The qualified **0.1.2 full-rebuild baseline** uses `tests/max/arrange_performance_tests.ms` and `tools/summarize_performance.py`. Its schedule is preserved below. The separate **0.1.3 cache comparison** is specified at the end and is still awaiting host correctness qualification. Run either through `tools/run_max_tests.py` with an exact matched SDK build and fresh output directory. Never load a scene-resetting harness in an artist session. The old measurements do not establish geometry-cache performance.

Run one owned performance process at a time, with no other owned build/QA/render workload. Record unrelated processes and background workload without changing them; concurrent runs validate behavior but cannot establish idle-machine timing. After successful completion, run the Python summarizer and retain its JSON beside the untouched raw CSVs and host receipt.

## Workloads and schedule

Both cases use freshly modeled `tests/max/book_row_fixtures.ms` original books. That helper is explicitly declared global before `fileIn`; grouped geometry is measured recursively with `caBRWorldGeometryBounds`, rather than using a helper/group-head bounding box. The factory also creates unused furniture variants; these remain unchanged in the disposable scene and contribute to whole-process memory. No asset gets pre-baked into a stored-only library: source-backed multi-part mesh and material capture costs remain inside actual Generate/Commit.

| Case label | Actual source scope | Recipe |
|---|---|---|
| small TV ordinary books | Modeled 1800 × 450 × 600 mm TV console, internal shelves/divider/back | Three physical upright books, fixed scale/yaw, composition disabled, density 0.15 |
| medium open shelf book rows | Modeled 1200 × 350 × 1800 mm shelf, four internal boards/divider/back | Explicit minus-Y book profiles, rows of 2–4, 3 mm row gap, 0.5 height balance, density 0.20 |

Both retain the native front-access policy, current 25 mm inspection grid, 20 mm global spacing, 12 mm edge setting, manual lifecycle and existing work/admission limits. Other accessory categories are disabled. The Book category cap is 500 so it does not artificially force a tiny population. Counts and targets come from the actual solver; partial fit/underfill is reported, never relabeled as a requested population success. Fixtures are intentionally moderate. A larger artificial fixture is deferred until these cases demonstrate real admission and costs; raising work limits or publishing rejected-scene timings would not establish practical usability.

Per case, run:

1. One first Generate with seed 7231 and an empty registry/output state.
2. Ten repeated Generate calls with that exact seed and current state.
3. Ten Generate calls alternating 9349/7231; each seed must reproduce its own observed IDs/poses/groups/statistics.
4. Ten actual workflow/asset UI `onRefresh` handler pairs, with passive setup selection; assert no revision, group, pose or actual output-node-handle change.
5. One first Preview after generation, then ten fixed-seed repeated Previews.
6. Ten Previews alternating 9349/7231, retaining every committed output node and revision.
7. One CommitPreview for the final seed 7231; require complete equality to the earlier Generate seed-7231 result.

There are **43 native solver commands per case, 86 total**, plus 20 separately timed passive UI-handler pairs. The first-command rows are kept separate from repeated rows. The second case's first command is a fresh-scene first command in the same process, not a second fresh-process/OS-cold measurement. Alternate seeds are recipe rerolls; they are not synthetic source edits. All generated output nodes stay untouched by the harness: only native Generate/Commit replaces them; it never repositions, bakes, deletes or relocks them.

## Timing, memory and correctness evidence

The native command alone lies inside a .NET `Stopwatch` interval. Stage logging, CSV writing, seed setters, memory refreshes, UI opening and independent mesh/pose comparisons are outside it. Store `ElapsedTicks`, actual timer frequency/high-resolution status and fractional `Elapsed.TotalMilliseconds`. No waits, forced collection, Undo flushing or redraw suppression are inserted between trials. Native command viewport redraw/publication costs are included; idle rendering/viewport FPS and perceived UI responsiveness are not measured.

Native setting/generation transactions accumulate bounded Undo history during each case. Record prior publication count and before/after revisions; memory/timing trends can include history. Reset between cases is outside timing. There is no history-neutral cache comparison and no claim that repeated-command differences isolate an optimization. Reversing case order in a fresh process is a useful follow-up if case-order bias matters.

Call `Process.Refresh` before memory samples. Record current `WorkingSet64`, `PrivateMemorySize64` and `PeakWorkingSet64` before/after the command. The last is the **maximum working set since this process started**; it cannot establish a per-command allocation peak or native query storage. Working/private bytes include Max, source geometry, script tables, materials, Undo, output objects and all loaded modules. Do not interpret the before/after delta as a leak or cache size.

Files are stage-flushed so a crash or timeout retains the last started operation:

- `result.txt`: progress/assertions/exceptions and stack, ending SUCCESS only after the full schedule.
- `performance-environment.txt`: Max/native paths/version, private INI, actual owned PID, runtime/timer information and observed Max process IDs. Root must still independently establish serial scheduling and external workload conditions.
- `metrics.csv`: every native command, observed requested/accepted/kept/candidates/underfill/warnings, committed/preview counts, revisions, history ordinal, timings and process memory. Labels deliberately include whitespace and CSV is quoted.
- `poses.csv`: every actual committed record's stable/asset/region/stack IDs, full anchor/yaw/scale/lock, actual output handle, measured world mesh bounds and complete node transform. For Preview rows, the seed column is the **requested preview seed** and these are still the retained committed outputs, not unpublished preview placement IDs.
- `groups.csv`: complete persisted group membership/front/gap for each committed snapshot.
- `regions.csv`: observed native region identity/role/bounds/clearance and exclusion after each command.
- `preview-bounds.csv`: actual returned candidate boxes by serial/index; the public API does not expose unpublished IDs. Compare these against independently measured prior Generate outputs for that seed.
- `browsing.csv`: separately timed actual passive handler pairs and process memory.

Equivalence compares stable IDs, every native pose field, complete ordered group records, actual mesh bounds/transforms and solver statistics by seed; generation may replace node handles. Preview/browsing additionally require the exact original handles. Independent physical checks use actual source-box bounds: every complete book envelope must sit on a physical board top, stay out of all furniture solids, keep its source-measured dimensions/unit scale, match the recorded anchor, and avoid other output solids. Rows additionally require disjoint members, measured gap/front/base agreement and matching region/stack state. This original box-fixture oracle does not certify arbitrary curved/proxy geometry or all solver acceptance boundaries; existing functional fit suites remain necessary.

Report all raw samples and separate medians/p95 by case, operation and schedule. With ten samples, nearest-rank p95 is the maximum; this is a small command baseline, not a general worst-case guarantee. Report target/accepted/underfill ranges beside elapsed time. No numeric pass/fail latency threshold is invented before measurements and professional workflow targets are agreed from real evidence.

## Primary API references checked

- Microsoft documents Stopwatch's elapsed interval, frequency and high-resolution counter behavior: [Stopwatch](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.stopwatch). Fractional millisecond totals are documented in [TimeSpan.TotalMilliseconds](https://learn.microsoft.com/en-us/dotnet/api/system.timespan.totalmilliseconds?view=net-6.0).
- Process properties can be cached; Refresh discards the component snapshot so subsequent reads obtain current process information: [Process.Refresh](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.refresh?view=net-10.0).
- The memory properties mean physical working set, non-shareable private bytes and process-lifetime maximum working set respectively: [WorkingSet64](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.workingset64?view=net-6.0), [PrivateMemorySize64](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.privatememorysize64), [PeakWorkingSet64](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.peakworkingset64?view=netframework-4.7.2).
- Autodesk documents automatic MAXScript/.NET conversions, including Int64→Integer64 and Double→Double: [MAXScript / DotNet Value Conversions, Max 2027](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/Interaction-with-Other/DotNet-In-MAXScript/GUID-FB52FDC5-CC83-46FB-A430-B90E7107805A.html). The first actual run exposed an integer-overload serialization bug. The successor formats native integers explicitly and validates process/node identities before accepting summaries; see [release evidence](RELEASE_VALIDATION_0.1.2.md).

## 0.1.3 paired cache comparison — executed on final native46

Both fresh serial orders passed on native46: **1,109 assertions and 144 commands per process**, followed by independent validation of the raw schedules, timing rows, physical results and exact source/module identities. The opposite schedule reverses cold/reused order association; both processes still run TV before shelf. [Performance results](PERFORMANCE.md) report measured paired differences and environment limits. `build/final-46-performance/receipt.json` binds both runs and the independent validation. The protocol below describes the executed schedule and remains the reproducible procedure for successors.

The reviewed forward/reverse entries are promoted to `tests/max/arrange_cache_performance_tests.ms` and `tests/max/arrange_cache_performance_reverse_tests.ms`; the independent validator is `tools/verify_cache_performance.py`. The promotion and its 36 passing offline regressions are recorded in `build/cache-performance-promotion-01`. Frozen drafting snapshots remain under `build/cache-performance-draft`. These offline checks and preserved physical-oracle replays are not Max execution or timing evidence. Rebuild the exact promoted source/native pair and pass notification/lifecycle correctness before collecting performance evidence.

Use the same two procedural fixtures, dimensions, book assets, settings and seeds as above. Each fresh process records 144 actual commands: four explicit seed baselines, twenty context Generate calls, and 120 paired measurements (ten pairs × two fixtures × Generate/Preview/CommitPreview × cold/warm). Alternate the seed and condition order. Run the reverse schedule in a second fresh process after the first has exited, with no overlapping owned build/QA/render jobs. The two runs together contain 240 paired samples and 48 separately recorded baseline/context commands.

Cold keeps reuse enabled but clears optional geometry outside each timed command. Warm keeps same-time geometry available. Before either condition, a separately logged context Generate establishes the current seed's previous complete placements/groups. This is necessary because solver work includes validating the prior publication. Comparing an initially empty or different-seed prior result with an established repeat would be a different workload. Preserve exact cold/warm solver-work equality within each matched pair; do not discard that assertion to accommodate different histories.

A warm sample must report an actual native validated `hit`, zero executed inspection/query work, and zero furniture-capture, inspection, obstacle-capture and query-build phase times. Cold must execute its complete recorded construction work. Both conditions must refresh current assets, solve and validate full placements. Timing alone never proves a hit.

Compare complete native records in their returned order, ordered group membership/front/gap, requested/accepted/underfill/candidate statistics, all six published composition-statistic fields, warnings, Preview bounds and actual committed meshes. Strict nested-value equality must cover all array elements. Native anchors/yaw/scale compare exactly; separately measured mesh bounds and host transforms keep explicit physical tolerances. Explicit decimal integer serialization preserves node/placement/member identities. The additional `composition-stats.csv` records every command's complete last-published statistics; Preview must retain its predecessor's statistics. An independent physical oracle reconstructs all seven TV boards or ten shelf boards from the authored fixture dimensions and checks source sizes, complete support, nonpenetration and row relationships. Native sampled regions are not that oracle.

Export all twelve native phases, original versus executed work, dependency tickets, accounted live/peak retained entries and metadata, complete output evidence, process memory, revisions and publication-history ordinals. Keep history accumulating during a fixture; do not insert forced GC or clear Undo between timed operations. Reset only between fixtures, outside timing. Accounted cache bytes exclude Max and Undo; process private/working-set measurements include them.

Report ten-sample median, nearest-rank p95 (the maximum), min/max, each pair's cold-minus-warm difference and the two condition-order strata. Separate preparation savings from whole-command effects, including zero or negative savings. Keep raw samples and bind both runs to the same exact native/UI/source/runner inputs with an external qualification receipt. Preserve observed background artist processes and disclose them; serial owned scheduling does not prove an idle machine. No renderer, viewport FPS, universal speedup or arbitrary-scene guarantee follows.

# Cyrus performance baseline recorder

**October 1 update:** Recorder 0.2 adds opt-in per-build and Analyzer tracing for spline edits. Recorder 0.2.1 corrects successive edit IDs and the report recovers existing 0.2.0 recordings. See [Detailed edit tracing and installation](Performance_Edit_Tracing.md) and the [first detailed heavy-scene review](Spline_Edit_Trace_2026-10-01.md). The original 0.1 measurements below remain scoped to their historical verification; initial tracing installation requires the updated plugin scripts and a Max restart. Updating an existing tracing recorder to 0.2.1 only requires stopping/closing the recorder and running its script again.

**Started:** 2026-09-30. **First target:** 3ds Max 2027, with the artist's Corona 15 scene. **Status:** implemented; synthetic Max 2027.1 smoke test and eight report checks passed. Heavy-scene and Corona measurements are pending.

This standalone tool records the current implementation before optimization. Run it with the existing Cyrus installation. The production plugin and its generated scripts are not replaced by this tool.

## Start here — a short trial on your scene

1. Save a separate scene copy as `Cyrus_Performance_Baseline.max`. Keep its external textures, proxies and other assets fixed. Close rendering and interactive rendering for this first test.
2. In Max, select the **Cyrus Scatter controller** you want to measure. The first version tests one controller, including its enabled layers. Repeat with another controller in a separate recording if needed.
3. Choose **Scripting > Run Script** and open [CyrusPerformanceMonitor.ms](../tools/performance/CyrusPerformanceMonitor.ms). Keep [Measure-CyrusProcess.ps1](../tools/performance/Measure-CyrusProcess.ps1) in the same folder.
4. Click **Use selected Cyrus controller**. Keep build label `baseline-current`, case `heavy_preview`, and activity `idle`. Enter the exact Corona build in the renderer field; the tool also attempts to read Corona's version through its published interface.
5. Confirm **Saved test copy matches the current scene settings** only if that is true. Click **Start recording** and wait for **Recording**. The separate resource recorder fingerprints the saved scene and relevant files first; a large scene can take time.
6. Confirm the test-copy/render-stopped checkbox. Keep **1 warmup / 3 measured runs**, then click **Run preview rebuild test**. Leave the scene and viewport unchanged during the test.
7. When the test finishes, click **Stop & save**, then **Open results folder**. Keep this folder; it is the evidence we will use before changing the plugin. The memory recorder finishes within approximately one sampling interval after stopping.

The panel shows the latest per-layer preview times and generated/displayed counts. A heavy rebuild can block Max's interface; the separate process continues sampling CPU and memory. **Cancel next runs** takes effect between rebuilds, not inside a running native operation.

Default result location: [build/performance-runs](../build/performance-runs). Every recording receives a new timestamp/ID folder. Closing the panel stops recording. The tool neither saves your scene nor starts a render. The deliberate preview test does call Cyrus's existing preview refresh operation, including its normal layer synchronization and cache updates.

## What version 0.1 measures

| Measurement | Meaning and limits |
|---|---|
| Controlled rebuild milliseconds | Stopwatch around the selected controller's `refreshDisplay()` call. Includes layer synchronization, preview work and redraw submission. Does not prove GPU completion or input-to-visible latency. |
| Existing per-layer preview milliseconds | Cyrus's most recent `refreshPreview()` timer, including placements, source sampling and preview construction. Not isolated native scatter time. |
| Generated, requested, displayed counts | Separate values, with display units (`points` or `shown_instances`) and density-cap state. Counts are checked before reporting a comparison. Equal counts do not establish visual/layout parity. |
| Build and blocker-cache counters | Raw counts, observed deltas and detectable resets. The observer does not force a refresh. Multiple rebuilds between polls expose only the most recent duration. A reset followed by rebuilding between polls may be undetectable. |
| Max process resources | Private bytes, working set and CPU every 500 ms, recorded outside Max. Includes every plugin and renderer in that process. Peaks are sampled session peaks, not exact operation allocation peaks. |
| CPU percentage | Process CPU normalized across all logical processors. One saturated thread can look like a small percentage; low total utilization does not itself prove a defect. |
| Optional reported viewport FPS | Available only after the artist explicitly opts in. Enable viewport Statistics and disable Adaptive Degradation first. It is a coarse reported rate, not per-frame timing or a reliable frame-time p95. |
| Optional Corona VFB values | Manually enter parsing, geometry and rendering seconds, passes and noise. Blank means unavailable. These are whole-scene renderer values and are retained separately. |
| Identity/context | Saved-scene SHA-256, loaded module files, measurement tool files, installed script candidate, Max version, available Corona version, CPU/GPU model/driver, RAM, OS, active power scheme, scene units/frame, viewport and Cyrus settings. |

GPU utilization, kernel timings, exact first-visible-frame latency, exact Cyrus render-preparation duration, automatic camera-path playback and native stage profiling remain future additions. This version does not implement threading or GPU computation.

The file fingerprints describe disk content. An installed script file is a candidate, not proof of which script version was loaded into memory. Start Max fresh with the intended installation for trustworthy build identity. A saved scene fingerprint also cannot describe unsaved edits or changing external assets.

## Passive editing, viewport and Corona sessions

Use separate recordings so each has a clear purpose:

- **Editing:** case `heavy_editing`, activity `idle`. Start recording, use **Event note / Mark** before each prescribed action (for example, changing seed 42 to 43 once), wait for the result, and stop. Raw observations show rebuild activity and the latest durations; polling cannot reconstruct every intermediate build or measure precise user-input latency.
- **Viewport:** case `heavy_navigation`, activity `idle`. Keep the preview valid, camera route, viewport size/mode and display budgets fixed. Opt in to FPS only with Statistics enabled and Adaptive Degradation disabled. This is exploratory until we add reproducible camera playback and frame timing.
- **Corona IR:** case `heavy_corona_ir`, activity `interactive_rendering`. Start recording, mark events, then start IR yourself and repeat prescribed edits. Stop IR yourself. The controlled preview test is restricted to idle sessions and refuses known active Corona render types, including docked IR.
- **Production preparation:** case `heavy_corona_production`, activity `production_rendering`. Start recording, mark the action, start your render and copy VFB statistics when available. Use the same camera, resolution, passes/noise target, displacement, GI/cache settings and denoiser across comparisons. Save a VFB screenshot with the recording. The tool does not attribute VFB parsing time wholly to Cyrus.

Do not pool these activities into one speed number. Corona image rendering is a separate workload from Cyrus preview generation. Passive sessions intentionally have no controlled-rebuild median; the report will say that a controlled comparison is unavailable.

## The baseline and optimization cycle

After the short trial establishes a practical duration:

1. Reopen the frozen scene copy and start a **new recording**. Use **3 warmups / 30 measured runs** for the first controlled engineering baseline. The forced test rebuilds previews with identical inputs; it is not a cache-hit or natural parameter-drag test.
2. Keep the same tool version, case name, machine, host/renderer builds, settings, display budgets and background workload. Preserve all raw samples, including slow valid ones. For repeated sessions, restart Max and document whether scene, asset and OS caches were warm; this first tool does not automate cold starts.
3. Make one optimization, restart Max with that candidate, reopen the exact frozen scene and repeat. Only the build label and intended plugin build should differ.
4. Compare timings and inspect the scene visually. Instance counts, positions/appearance, filtering, editing and render output must remain correct. Small timing differences require repeat sessions. Alternate build order where practical.
5. Investigate the largest measured whole-operation cost. Add native stage instrumentation when we need to distinguish sampling, filtering, source conversion, preview packing or render transport. Measure that instrumentation's overhead and apply it equally to both builds.

The tool's own CPU/memory and logging overhead has not yet been quantified on the heavy scene. No speedup or maximum achievable gain is established by installing this recorder.

## Read a report

The Max panel writes `summary.json` with successful measured runs, failed operations, median and p95 (only with at least 20 successful measured samples). Raw data is always retained. For a readable HTML report, use the standard-library Python utility:

```powershell
python tools/performance/compare_runs.py "build/performance-runs/BASELINE_FOLDER" --out "build/performance-baseline.html"
python tools/performance/compare_runs.py "build/performance-runs/BASELINE_FOLDER" "build/performance-runs/CANDIDATE_FOLDER" --out "build/performance-comparison.html"
```

Replace the folder names with real recordings, or provide those folders in this chat and have the report generated here. HTML has expandable evidence sections; the adjacent JSON contains the same comparison data.

The comparator suppresses speedup claims for failures, incomplete recordings, dirty/unconfirmed saved scenes, changed scene content, incompatible settings/counts, different measurement tools, changed host/renderer/hardware context, and insufficient samples. Passing these checks remains a **preliminary timing comparison**, not a visual-correctness certificate. Session memory peaks are shown separately because session length and activity can differ. Corona's manually entered fields are not automatically compared.

### Recording files

| File | Contents |
|---|---|
| `manifest.json` | Session context and initial direct parameter snapshot |
| `host.json` | Resource recorder's hardware and file fingerprints |
| `operations.csv` | Every warmup/measured call, errors, output signature and settings snapshots |
| `observations.csv` | Per-layer passive snapshots, counters, optional reported FPS and global PFlow build count |
| `resources.csv` | Independent process CPU/private-memory/working-set samples |
| `live.txt` | Latest resource sample for the panel, updated by the separate recorder |
| `events.csv` | User markers and tool lifecycle events |
| `corona.csv` | Optional manually entered VFB measurements |
| `summary.json` | Max-side end status and timing summary |
| `sampler-summary.json` | Resource recorder completion and sampled peaks |
| `sampler-error.txt` | Present when resource recorder initialization/sampling fails |

Everything remains local. Paths, machine name, node names and configuration can appear in these exports. Max stops recording on its next timer tick after 30 minutes or 60,000 layer rows; a running rebuild must finish before that tick. The external sampler also exits when Max exits, a stop marker appears, or its one-hour sampling limit is reached. There are no persistent Max callbacks, startup installation entries, automatic uploads or automatic renderer configuration changes.

If the resource recorder fails, open its error file and share the message. PowerShell must be allowed to run this local helper under the machine's existing execution policy; the tool does not change that policy. Keep all companion files in their original folder.

## Verification and limits

The automated checks are [the Max batch smoke test](../tools/test_performance_monitor.py) and [report comparison tests](../tools/tests/test_performance_reports.py). The disposable scene, raw outputs and logs are under `build/performance-monitor-test`; they are tool-verification evidence, not measurements of the artist's scene.

Verified in a separate **Max 2027.1 / 29.1.0.11426** batch process:

- Passive reads preserve layer settings, the global field list, dirty state and build counters.
- The queued test executes one warmup and three successful measured rebuilds, each producing 200 instances and 16,000 displayed points, without creating scene nodes.
- Counter reset recording and a deliberately missing-surface failure work. Failed timings are excluded from successful summaries.
- The separate resource recorder starts, collects process samples and stops through its marker file.
- All exported JSON and CSV parse, numeric durations are valid, and the report generator reads the real recording.
- The rollout can be created and closed; optional VFB numeric validation accepts decimals/blanks and rejects negative values.
- Eight report tests cover warmup exclusion, percentile rules, failure/nonfinite durations, output mismatch, changed settings/tool identity, dirty/incomplete scenes, settings order and HTML escaping.

Evidence: [Max test result](../build/performance-monitor-test/result.txt), [synthetic report](../build/performance-monitor-test/smoke-report.html). The successful raw recording is named in the test result. Its timings are a tool smoke test, not a performance claim. SHA-256 comparison confirmed that all 63 pre-existing files in the inspected Scatter/Analyzer source, script and generator directories remained unchanged.

The artist's heavy scene, Corona 15 rendering, interactive visual layout, logging overhead and older Max releases require their own qualification. The currently open artist session was not used by the test runner.

## Primary API references

- [Autodesk — viewport information and GetFPS](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Viewports/GUID-8AA71F9E-F4F0-4437-A44E-9683619E89DE.html): statistics/degradation restrictions on FPS.
- [Chaos — MAXScript interface](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124394405/MAXScript): read-only Corona version and active-render type queries.
- [Chaos — Corona VFB](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/125082327): definitions of scene parsing, geometry preparation and renderer statistics.

This implements a limited first part of [Baseline and Trust](Product_Strategy_2026-09-29/12_First_Implementation_Milestone.md). The detailed [benchmark protocol](Performance_Roadmap_2026-09-28/02_Baseline_and_Benchmarks.md) remains the guide for future stage profiling and broader qualification.

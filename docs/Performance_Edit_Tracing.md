# Detailed surface/spline-edit tracing — recorder 0.2.2

This adds optional synchronous timing hooks to the Scatter and Surface Analyzer scripts, plus a local recorder and report. The original tracing-only change preserved algorithms and binaries. The current Scatter 0.60 package also includes the [CPU performance implementation](Performance_Implementation_2026-10-01.md). Hooks are inactive when the recorder is stopped. The generator owns Scatter timing through `tools/ui/trace.cjs`; do not edit its generated script alone.

## Install once, then restart Max

**For the current performance test, install the complete 0.60 MZP and restart as described in the [upgrade test](Performance_Upgrade_Test_2026-10-01.md). Its Scatter script already includes tracing.** The script-only installer below cannot upgrade the native engine; it rejects unknown installed script hashes, including some intermediate tracing builds. Use the complete package for this comparison.

1. Save your work. Run [Install-CyrusPerformanceTracing.ms](../tools/performance/Install-CyrusPerformanceTracing.ms) using **Scripting > Run Script**.
2. Click **Install tracing scripts for next Max start**. It preflights both installed scripts against the tested originals/current files, backs them up, copies the tracing scripts and verifies their hashes. An unknown installed version is rejected before either file is changed.
3. Save and close Max, then reopen Max and your saved test scene. The installer deliberately does not redefine classes in your open scene. Installing without restarting is insufficient.

The installer targets the current Max version's user scripts directory. It installs no DLLs. Backups are stored beneath `scripts/CyrusPerformanceTraceBackups/<timestamp>/`; the installer shows the exact path. To roll back, close Max and copy the backed-up `AminScatterObject.ms` and `CyrusSurfaceAnalyzer.ms` into their original `scripts/AminScatter/` and `scripts/CyrusSurfaceAnalyzer/` folders, respectively, then restart. Do not run the backup scripts in a populated scene as a hot reload.

## Record the next editing test

1. Save a fixed starting scene. Stop Corona rendering/IR. Keep Cyrus/Analyzer's intended live-update settings enabled. Keep viewport filters configured so the controllers remain selectable.
2. Run [CyrusPerformanceMonitor.ms](../tools/performance/CyrusPerformanceMonitor.ms). Select the Scatter controller and click **Use selected Cyrus controller**.
3. Use case `heavy_spline_edit`, activity `idle`, and leave **Detailed edit tracing** checked. Confirm the saved copy matches the scene, then Start recording and wait for Recording. Missing hooks cause a clear error instead of silently collecting only passive data. Leave FPS unchecked for this test.
4. Select the actual spline or editable object you will modify and click **Watch selected edit object**. This does not change the recorded Scatter target. Direct surface/source/Analyzer references are also watched automatically; this button adds an upstream object where needed.
5. Enter `corner_move` in **Edit name**, click **Begin named edit**, make ONE change, release the mouse and wait until the scatter visibly finishes. Click **Result visible**.
6. Repeat with `extend_side` and then `undo_extension`, allowing each update to finish. Note the vertices/edges and distances used so the sequence can be repeated. Do not add/remove layers or change source assignments within this recording; the traced object mapping is captured at Start.
7. Click **Stop & save**, then **Open results folder** and send its path. Do not run the controlled preview rebuild button in this editing session.

For multiple repetitions, use descriptive edit names and start from the same saved state. Timing comparisons need the same instrumentation mode and file versions; do not compare recorder 0.1 timings directly against 0.2 as evidence of plugin speedup.

**0.2.1 recorder correction:** successive edits now receive IDs 1, 2, 3, etc. Recorder 0.2.0 accidentally reset the ID after Result visible. The report recovers older recordings by matching marker occurrences, labels and timestamps, preserving their raw IDs. After stopping and closing the recorder, run `CyrusPerformanceMonitor.ms` again to load this correction. Existing tracing installations need no reinstall or Max restart for this recorder-only update. The [first detailed heavy-scene review](Spline_Edit_Trace_2026-10-01.md) documents the recovered three-edit recording.

**0.2.2 context:** the manifest adds `cpu_thread_request`, `native_source_filter`, `native_source_transforms`, and `callback_batch_stats_at_start` where available. A request of 0 means automatic (up to four total CPU participants in 0.60); it does not mean zero workers. Callback counters describe batches and requested redraws, not completed viewport frames. Placement end metadata now includes the result count and preview/raw/final-pass flags. Native compute diagnostics describe the latest call on the calling thread and must not be attributed to a layer when a dependency ran afterwards.

## What the new data means

| Data | What is measured | Limit |
|---|---|---|
| `input_received` | Existing Scatter/Analyzer event handlers receive a watched node notification, including event type and node identity | Callback receipt may be delayed until after mouse-up and by the host's event queue. Two handlers seeing one change is not two artist edits. |
| `analyzer_run` | Each connected Analyzer's complete `runAnalysis` call | Can include synchronously triggered scatter rebuilds as well as script/native work and redraw submission; no native substage or GPU timing. Metadata includes published revision and sample-point count. |
| `preview_rebuild` | Each selected controller layer's complete `refreshPreview` call, including consecutive builds between UI timer ticks | Inclusive wall time; captures errors and per-build generated/displayed counts/build number. |
| `placements` | Each traced placement call, including nested blocker/dependency calls mapped to the controller's layers | Usually nested inside preview time. Do not add these durations to parent preview time. |
| `external_invalidation` | Each traced layer's `externalChanged` call and its returned changed flag | A processed external-input notification, not a complete explanation of every dirty-state transition. Analyzer revision polling and UI parameter handlers can also invalidate layers. |
| Named edit markers | Artist clicks Begin named edit and Result visible | Includes time to perform the edit and human reaction; not exact mouse-release-to-visible latency. Unmarked work is labelled separately. |

`trace.csv` has start/end rows sharing a span ID, parent span IDs for nested work, edit ID/label, actor, elapsed timestamp, stage, inclusive duration and details. For preview end rows, detail is JSON `[error, generated, displayed, build_counter]`; Analyzer detail is `[error, analysis_revision, sample_point_count]`. Each stage captures exceptions without replacing the plugin's existing error behavior.

Rows are buffered during blocking work and flushed by the recorder's timer and at Stop. A 100,000-row buffer limit prevents unbounded growth. `trace-summary.json` reports dropped rows, collector failures, stage errors, unfinished spans and unfinished edit markers. Any loss/error must be considered before comparing results. A Max crash may leave buffered work absent and the summary missing. The buffer holds primitive metadata, not native preview caches.

The recorder does not register another geometry-change listener or poll meshes. It uses opt-in hooks in the existing handlers. Stopping/reloading/closing the recorder clears the hook callbacks and releases watched references. Disabling Detailed edit tracing retains the earlier passive/forced-test modes.

## Report

```powershell
python tools/performance/summarize_edit_trace.py "build/performance-runs/RUN_FOLDER" --out "build/edit-trace-report.html"
```

The report includes named edit windows, individual spans, per-edit and whole-session stage aggregates, layer rebuild counts and Analyzer runs. Report window IDs identify marker occurrences even when an old recorder reused its raw edit ID or the artist repeats an edit label. Unmarked stages remain outside those windows.

The traced-work window runs from the first recorded stage start to the final recorded stage end within an edit, including gaps. Covered-work time counts the union of recorded stage intervals, counting overlaps once. Neither is complete UI response latency or CPU time. Manual windows also include preparation, the edit itself and human reaction.

All stage durations are inclusive. Analyzer calls can contain layer rebuilds; a layer's placements can invoke another layer's placements. Child-excluded time removes the union of immediate recorded child intervals from each span. It includes remaining uninstrumented native/script work and waits, so it is not an isolated algorithm benchmark. Child-excluded values are unavailable when span loss or an incomplete tree makes that subtraction unreliable. The report flags incomplete traces, stage errors and work ending after Result visible; it makes no automatic speedup claim.

CPU/RAM sampling remains external to Max. The main script, trace companion and sampler are fingerprinted, along with installed Scatter/Analyzer script candidates. Disk hashes cannot prove the exact in-memory script contents; restarting after installation and the instance capability checks are both required.

## Verification and limits

The separate Max 2027.1 fixture exercises recorder compilation, normal passive/forced modes, trace input receipt, a real native Analyzer call, consecutive preview builds with nested placement spans, output/count parity, exception/error reporting, three advancing edit IDs, repeated labels, unmarked work and callback cleanup. The Python runner verifies trace parsing and renders an edit report. Six edit-report regression checks cover recovery of reused IDs/repeated labels, nested timing subtraction, partial spans, mismatched/early result markers, span identity and error/HTML preservation. The installer is tested against temporary copies, including backup/copy, idempotence and unknown-version rejection. These tests never operate on the artist's running Max session.

The installer test uses the pre-change script copies under `build/performance-trace-originals`, alongside the existing native test builds. Retain these fixtures when rerunning that test. Tests of the original eight report checks still apply to forced rebuild comparisons.

Heavy-scene tracing overhead has **not** been quantified. Synchronous logging adds some overhead even though file writes are buffered; disabled hooks still add a small wrapper cost. Actual mouse-release timestamps, GPU presentation completion, complete invalidation causality, renderer tracing and native per-algorithm stages remain outside this version. A short screen recording can supplement the manual visible-result markers.

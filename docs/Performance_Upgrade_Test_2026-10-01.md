# Test the first CPU performance upgrade

**Build:** Cyrus Scatter 0.60, Max 2027. **Recorder:** 0.2.2. This test checks the actual editing experience after the isolated comparisons in the [implementation report](Performance_Implementation_2026-10-01.md).

## 1. Install and restart

1. Save your work and keep the original saved scene as the comparison starting point.
2. In Max 2027, choose **Scripting > Run Script** and open [CyrusScatter-0.60-Max2027.mzp](../dist/CyrusScatter-0.60-Max2027.mzp).
3. Finish installation, close Max and **restart Max**. Copying the loose script cannot replace the loaded native engine.
4. Reopen the original saved test scene. Surface Analyzer remains version 0.14; its calculation algorithm was not changed. If it is missing, install [its Max 2027 package](../dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp) and restart.
5. Check that the six layers look correct, controller selection works, and generated/displayed counts remain plausible for the saved state.

The packaged Scatter script already contains tracing hooks. Do not run the script-only tracing installer for this upgrade. The candidate has not been installed into your live Max session by the developer tests.

## 2. Record the same surface edits

1. Stop Corona rendering and interactive rendering. Keep the same live-update mode, layer settings, sources, display mode, budgets and viewport as the baseline.
2. Run [CyrusPerformanceMonitor.ms](../tools/performance/CyrusPerformanceMonitor.ms), select **Cyrus Scatter001**, and click **Use selected Cyrus controller**.
3. Set **Build label** to `cpu-v1-0.60-auto4`, **Test case** to `heavy_surface_edge_edit`, and leave **Detailed edit tracing** checked. Confirm the saved copy matches the scene, then click **Start recording** and wait for Recording.
4. Select **Plane001** and click **Watch selected edit object**. The controller remains the recorded target.
5. Use the table below. Before each operation, enter its edit name and click **Begin named edit**. Perform one operation, wait until the updated scatter is visible, then click **Result visible**.
6. Repeat the four-operation sequence three times. The scene should return to its starting geometry after each Undo. Finish with **Stop & save** and send the new run folder.

| Edit name | Operation |
|---|---|
| `right_extend_1` | Move the right outer boundary edge **+150 cm in world X** |
| `undo_right_1` | Press **Ctrl+Z once** and wait for the original result |
| `left_expand_1` | Move the left outer boundary edge **−150 cm in world X** |
| `undo_left_1` | Press **Ctrl+Z once** and wait for the original result |

Use suffixes `_2` and `_3` for later repetitions. In the saved `SaveSelect 2.max` used by the developer benchmark, the right edge is **7**, vertices **3/6**, and the left edge is **1**, vertices **4/1**. If your scene topology differs, choose the corresponding outer edges and record their actual IDs. Use **World** coordinates and an offset value in Transform Type-In; entering an absolute position is a different operation. Your scene is an Editable Poly surface, so the test name reflects that.

Do not change layers/settings between the named edits or mix controlled rebuild trials into the editing recording. The name itself does not affect performance; repeatable geometry and settings do.

## 3. Check correctness and feel

- Does the scatter refill the expanded surface and restore correctly after each Undo?
- Do points, source assignments, border orientation and layer overlap look consistent?
- Is the wait after releasing the edge shorter? Is navigation smoother once the result has settled?
- Are there blank previews, errors, unexpected repeated rebuilds or memory growth over the three repetitions?

The visible-result marker includes your reaction time. The trace provides the actual recorded calculation intervals. Reported FPS describes the viewport; it is not a GPU compute benchmark.

## 4. Optional CPU comparison

Automatic mode is the starting test. To isolate the multicore contribution, open the MAXScript Listener (F11) and enter:

```maxscript
cyrusScatterCPUThreads 1
```

Reopen the same saved scene and record the same sequence with label `cpu-v1-0.60-serial`. This retains the native source and boundary improvements while disabling worker participation. Restore automatic mode afterwards:

```maxscript
cyrusScatterCPUThreads 0
```

The setting is session-only. `0` uses up to four total participants, including the caller; `1` is serial. Larger requests, such as 8 or 12, are available for controlled experiments, bounded by the machine's logical processor count. Only eligible large cluster queries use workers; a lower process CPU percentage does not imply the setting failed.

## 5. Exact old-build comparison or rollback

[CyrusScatter-0.59-PrePerformance-Max2027.mzp](../dist/CyrusScatter-0.59-PrePerformance-Max2027.mzp) contains the frozen old native engine **and** its tracing script. Use the same install/restart procedure and reopen the original saved scene. Record the identical sequence with label `pre-performance-reference`. Keep recorder 0.2.2 and instrumentation mode the same for both builds.

The older regular 0.59 package is also preserved, but its script predates some tracing changes. Use the reference package for this comparison. Compare original saved test copies; backward reopening of scenes newly saved by the candidate has not been qualified.

## 6. After the editing test

Test a small Corona 15 production render, then a separate IR session. Check final count, point-placeholder exclusion, materials, source transforms, stop/restart and scene reopen. Record those separately from the stopped-render editing test.

The next engineering change will be selected from your new trace: remaining duplicate rebuilds, source/preview preparation, or viewport drawing. GPU/OpenCL/CUDA and asynchronous editing are separate future experiments; this package supplies a measured CPU comparison first.

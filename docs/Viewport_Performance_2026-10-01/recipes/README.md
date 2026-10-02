# Viewport investigation recipes

These are the final local fixtures used in the October 1 investigation, retained for inspection and adaptation. They are not one-click production utilities. They assume this exact installed plugin, scene, global variables and local output directory. Several scripts load a scene, change its temporary display state or unregister drawing callbacks. Read the code before using it on a new saved copy.

`CyrusViewportBenchmark.ms` and `summarize_viewport.py` are frozen copies of the new tools in `tools/performance/`. The existing `CyrusPerformanceMonitor.ms` supplies serialization and process recording. The bootstrap's local command timer was a temporary desktop test transport; `20-restore.ms` disposes it. Neither is installed at startup.

## Fixture map

| File | Purpose |
| --- | --- |
| bootstrap.ms | Load the monitor headlessly and establish a local request-file timer |
| 01-04 | Load/inspect the disposable scene and discover viewport settings; later inventory handles empty source slots |
| 05-07 | Initialize the navigation harness and pilot; retry wrappers reflect harness development |
| 08-measure.ms | Main callback/Manual isolation matrix and process sampler |
| 09-layer-profile.ms | Inclusive per-layer draw timings and script-stage attribution |
| 10-display-matrix.ms | Display density, shape, point budget and centers |
| 11-retained-mesh.ms | Final v2 matched-count mesh and world-space batch prototypes |
| 12-retained-retry.ms | Historical wrapper; it calls the final 11 script in this snapshot |
| 13-layout-and-assets.ms | Maximized/two-view control and missing-source inspection |
| 14-retained-controlled.ms | Calls final 11 for the accepted v2 controlled prototype run |
| 15-frame-phases.ms | Stationary redraw and callback counts by navigation phase |
| 16-18 | Instrument actual mouse-held callbacks, switch the Scatter drawing control, and restore |
| 19-analyzer-no-flush.ms | Paired Analyzer callback with only updateScreen removed |
| 20-restore.ms | Restore settings/callbacks, reopen the original unchanged scene, dispose test timers |

The authoritative accepted geometry trials are `evidence/retained-mesh-v2`, with displayed-count assertions in `evidence/retained-mesh-build.json`. The earlier v1 run is not reproduced by the final edited 11 script and is not part of the retained 3,900-step total. Of those 3,900 steps, 360 Point Cloud steps have a known BushesCenter source-sampling error and incomplete display; 3,540 have no recorded preview error. These fixtures must not be replayed blindly in filename order.

## Interpreting the files

`frames.csv` contains wall-clock steps, callback time and callback counts. A step may execute more than one callback. `reported_fps_unverified` is retained as an observation only. `cases.json` preserves original cache and operation counters before/after each measured interval. Prototype mesh counts are independently recorded because original cache counters continue to exist while alternative representations are drawn.

Layer count arrays use: `[controller handle, layer index, name, enabled, viewport mode, generated count, cached display count, cached triangle count, build count, dirty, error, radius count]`.

In `layer-profile/stages.csv`, the controller pseudo-row reuses the two cache timing columns: `cache_first_ms` is icon generation/drawing and `cache_second_ms` is `layerEntries`. Real layer rows use those columns for the two `previewCache` calls. Timings are inclusive; do not add medians as an exact total.

All retained measured trials have zero preview/Analyzer/PFlow increments and stable populations. Point Cloud trials explicitly retain a BushesCenter sampling error; they are degraded-display observations, not successful complete-display qualification. `evidence/validation.json` distinguishes the two categories and audits final restoration. The evidence index records SHA-256 hashes for the copied files and source snapshot. No `.max` file is duplicated into this documentation package.

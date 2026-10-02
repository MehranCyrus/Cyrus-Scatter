# Integrated Point Cloud candidate harness

These tools build and test the real Scatter controller with retained drawing. They are not startup scripts or instructions to execute in an artist session. See the [candidate report](../../../docs/Retained_Point_Preview_2026-10-02/README.md).

## Private build and launch

Use the existing pinned VS 2022 toolset 14.38.33130, Windows SDK 10.0.19041.0, Python/Node/CMake and the repository's extracted Max SDKs. `build.py --year 2027` or `--year 2026` regenerates the script and builds/runs nine Scatter suites under `build/retained-integration-2026-10-02/maxYEAR`. Build one year at a time: the generated script is shared. No production installation is changed.

`launch.py --run runNN` creates a new directory and refuses to overwrite an existing run. It copies the exact candidate binaries/script, redirects the Max INI/startup/plugin/temp paths and starts a visible private Max 2027 process. Its INI seed is the recorded `build/viewport-round2-2026-10-01/desktop.ini`; this local dependency is deliberate. The original `.max` is hashed, not modified. It starts from an empty disposable scene. Wait for `ready.json` and inspect it; `transport-ready.txt` alone does not mean setup passed.

Submit one recipe at a time with:

```powershell
python tools/performance/retained_integration/request.py --run runNN tools/performance/retained_integration/lifecycle.ms
```

Wait for completion before sending another. On a timeout, inspect `response.txt` and the private Max process; do not assume the recipe stopped. Every submitted recipe has a unique saved copy. `restart_fixture.ms` resets only the launcher's disposable scene.

## Recipes

| Recipe | Purpose |
| --- | --- |
| `bootstrap.ms` | Fresh actual controller, 5,000 placements / 500,000 dots, loaded-module identities |
| `lifecycle.ms` | Navigation counters, modes, manual/auto, colors, visibility, clone/delete, undo/redo, multi-view, save/open, GC |
| `hardening.ms` | Shared point export, process memory cap/fallback, missing-source error/recovery, idle requests, source edits, PFlow counts and final-placement fingerprint |
| `synthetic_benchmark.ms` | Matched disabled/GW/retained camera steps for the synthetic controller |
| `artist_scene.ms` | Load original scene read-only, change preview settings only in the private process, inspect all source sampling |
| `artist_benchmark.ms` | Artist fixture and saved-layout comparison |
| `artist_single_view.ms` | Separate single-view comparison (window dimensions still matter) |
| `artist_fullsize.ms` | Comparison after the operator visibly maximizes the private window; requires >1,000×650 viewport pixels |
| `quality.ms` | Real 10,000-shrub wide/close cloud, then separate 50-shrub dense-detail fixture; not automatic LOD |
| `manual_navigation_begin.ms`, `manual_navigation_end.ms` | Bracket a real Pan View mouse drag; trace file operations and assert stable cached data |
| `shutdown.ms` | Strip owners, reset the disposable scene, stop timers and request private Max exit |

`benchmark.ms` defines reusable functions. It uses full GC outside each timed arm, warm-up, reversed arm order, three repeats and 90 camera steps per arm. It validates immutable snapshot fingerprints, stable placement-build counts, stable explicit buffer initialization/failure counters and actual native draw calls. Metadata includes dimensions, style and counts. This measures `completeRedraw` plus message processing, **not completed-frame FPS**. Do not compile, run another workload, resize, minimize or switch viewport layouts during a timed comparison. Record foreground/window state; background throttling and machine activity can distort results.

`analyze.py <run-directory>` writes median, p95 and p99 step summaries. Run it after all recordings finish. Early runs with failed fixture scripts, GC transients, concurrent compilation, restored-small windows or different layouts are preserved as pilots and must not be mixed with the final controlled run.

`package.py --run runNN` checks tested/current binary and script identities before creating the candidate MZPs. `archive.py --run runNN` verifies their embedded manifests and copies curated text/images into the dated documentation package. It refuses to overwrite an existing archive. `archive.py --verify` checks the archive's byte manifest without running Max or modifying files.

Shutdown acknowledges before quitting; verify the recorded private PID actually exited. Original artist scenes, current installed plugins and the old boss handoff are not overwritten. The `.max` files, native binaries and raw build output stay in ignored directories.

## Native counters

`cyrusRetainedStats (CyrusPointOwner controller)` returns:

1. Owner point count.
2. Nonempty source groups.
3. Owner publication revision.
4. Owner PrepareDisplay calls.
5. Owner UpdatePerNodeItems calls.
6. Process successful explicit buffer initializations/realizations (cumulative).
7. Process requested position-buffer bytes (cumulative).
8. Process issued native draw calls (cumulative, not frames).
9. Process allocation/initialization failures (including deliberate cap tests).
10. Process live custom render items.
11. Process reserved position payload bytes (not total RAM/VRAM).
12. Generation status: 0 pending/no generation, 1 ready, 2 failed/fallback.
13. Ordered layer snapshot fingerprints.

Zero new explicit initializations during navigation is evidence about this implementation, not a measurement of driver transfers or hardware residency. Stock native point rasterization is finer than the old GraphicsWindow marker footprint; equal data is not pixel equivalence.

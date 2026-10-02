# Reproducing the second viewport investigation

These are the recipes and source snapshots used for the 0.62 investigation. They include rejected experiments as well as the accepted change. Read [the report](../../Viewport_Performance_Round2_2026-10-01.md) before comparing timings. The recipes use absolute paths for the original workstation and are not a one-click production installer.

## Inputs and startup

Use a disposable copy of `Test Scene/SaveSelect 2.max` with the hash in the evidence snapshot. Restore the experiment files to `build/viewport-round2-2026-10-01`, including the `probe` subdirectory. `build-probe.py` expects that location and the existing Max 2027 SDK/toolchain. The probe is diagnostic only. Its legacy mesh/hardware draw paths failed visual validation.

Use a private Max INI and private plugin configuration. `plugins.ini` records the native search paths used here; adapt them to your machine. Keep other test sessions and the normal user installation separate. The tested executable was Max 2027.1, version 29.1.0.11426.

Before running `desktop-start.ms` for the exploratory phase, change its Scatter script `fileIn` path to the frozen `baseline-061.ms` supplied here. At the time of the original run, the repository path named by that bootstrap contained those exact 0.61 bytes. The repository has since advanced to 0.62. Do not relabel current source as the baseline. The Analyzer script and benchmark helpers are under `source/`; arrange their paths explicitly as needed.

The launch command used the following arguments on `3dsmax.exe`:

```text
-q -i F:/Cursor/_Cyrus_Apps/CyrusScatter/build/viewport-round2-2026-10-01/desktop.ini -p F:/Cursor/_Cyrus_Apps/CyrusScatter/build/viewport-round2-2026-10-01/plugins.ini -U MAXScript F:/Cursor/_Cyrus_Apps/CyrusScatter/build/viewport-round2-2026-10-01/desktop-start.ms -listenerlog F:/Cursor/_Cyrus_Apps/CyrusScatter/build/viewport-round2-2026-10-01/listener.log
```

The INI was a private copy of the user's Max configuration with this experiment's startup and paths; create a fresh private copy for a retest. Verify loaded module paths and `desktop-ready.json` before proceeding. The original active viewport was 953 × 750 in a two-view layout. Adaptive geometry degradation was disabled for measurements and restored afterward.

## Run order and comparison

Send one recipe path at a time through the bootstrap's `request.txt` bridge and require a matching `SUCCESS` in `response.txt` before continuing. Use unique request paths for retries. All mutations belong to the disposable scene.

1. `01-probe-pilot.ms` tests immediate flat triangles and the unsuccessful legacy draw APIs. Check images; invisible output invalidates timing.
2. `02-retained-pilot.ms` creates ordinary nonrenderable mesh nodes using the exported proxy triangles. Its brightness mismatch disqualifies it from release.
3. `03-profile-and-matrix.ms` captures stage timings and the seven-condition exploratory matrix. Three repeats reverse order in the middle; retain all raw samples and rebuild counters.
4. Point the script load in `04-candidate-comparison.ms` to the archived `source/AminScatter/scripts/AminScatterObject.ms` (0.62). This recipe reloads the original scene copy, removing diagnostic nodes, and compares the captured 0.61 callback with 0.62. It runs 720 steps and exports the image pair. It must follow the exploratory initialization because it uses globals and the captured old callback from those recipes.
5. Execute `05-gesture-start.ms`, make four real pan strokes in the observed viewport, run `06-gesture-candidate.ms`, then repeat the four strokes. The original test used two outward/return pairs between window coordinates (1100,650) and (1280,650), with the pan tool active. Reobserve actual window bounds before input; those coordinates only apply to the original layout.
6. Execute `07-gesture-end.ms` to write the mouse samples and restore production callbacks, then `08-cleanup.ms` to restore camera, degradation and event state and dispose the command timers. Verify only the two production redraw callbacks remain.

`source/tools/performance/summarize_viewport.py` produces matrix summaries. Restore `analyze-round2.py` to the original scratch directory and use Python with Pillow and NumPy for gesture, stage and pixel comparison summaries. It reads saved viewport captures; it does not treat the changing statistics overlay as geometry evidence.

## Release checks

The three fresh Max test result files are under `../evidence/tests/`. The new held/released surface and Undo/Redo assertions are in the archived viewport fixture. Run the corresponding repository Python wrappers with the frozen source/native files before qualifying another build.

`package-062.py` reused the already tested 0.61 native binaries; it did not rebuild a DLL loaded in the open Max sessions. It verifies generator idempotence, package hashes and exact native equality with the preserved 0.61 MZP. `archive-evidence.py` records the as-tested files, source diff and preservation checks. Those scripts expect the original repository layout when executed.

The evidence index fingerprints this archive. Native payloads and the original scene are identified by hashes rather than duplicated here. The source snapshots, initial baseline and before-change ZIP distinguish this iteration from pre-existing uncommitted CPU and viewport work.

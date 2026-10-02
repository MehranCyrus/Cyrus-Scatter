# Reproducing the viewport candidate comparison

These are the final local recipes used for the October 1 candidate, with raw output retained in `../evidence`. They are engineering fixtures with explicit local paths, not scripts to run in an unsaved working scene.

1. Build the Max 2027 candidate using `tools/build_max.py`; run the three Max test wrappers listed in the installation guide. Keep any process using those DLLs closed while rebuilding them.
2. Copy the original supplied scene to `build/viewport-investigation-2026-10-01/SaveSelect 2 - viewport test.max`. Preserve its saved assets, controllers, camera and budgets.
3. Start a separate desktop Max with `-i` pointing at a separate Max INI and `-p` at a private plugin INI. Include the standard Max PlugIns folder, `build/max2027-release/AminScatter`, and `build/max2027-release/CyrusSurfaceAnalyzer`. Do not also register the installed native copies.
4. Run `desktop-start.ms` in that private session. It loads the candidate scripts, monitor helpers and test copy, then starts a local request-file timer. Its retained JSON export casts diagnostic Integer64 values; that formatting correction followed the original run. Set the original two-view layout and verify the active viewport is 953 × 750 before measuring. Paths assume the original checkout location.
5. Write the absolute path of `01-benchmark.ms` to `build/viewport-optimization-2026-10-01/request.txt`. A changed request triggers one recipe; read `response.txt` and wait for completion. The five conditions run three times, reversing their order in repeat two.
6. Run `summarize_viewport.py` on the resulting `matrix` folder. It recomputes medians/P95 and verifies layer identities. Check the counts and zero rebuild deltas; do not use the CSV's unverified on-screen FPS field as a frame rate.
7. Run `02-visual-and-parity.ms` for exact scene geometry/shading/color comparisons and six pairs of viewport images. It restores original proxy settings on completion or failure.
8. Optionally run `03-gesture-start.ms`, apply mouse pans in the perspective viewport, run `04-gesture-batch.ms`, and repeat the same pans. Finish with `05-gesture-end.ms`. The accepted trial contained two held callbacks per condition; it is only a path check.
9. Run `06-cleanup.ms` and verify `cleanup-complete.txt`. It restores the production callbacks, camera and original degradation setting and disposes the local timers. It leaves the disposable candidate scene open without saving it.

The request path must change between executions. A one-line wrapper that `fileIn`s the intended recipe is sufficient for an intentional retry. The accepted run's early setup/fixture compile errors are not measurement samples; corrected recipes and final successful test logs are retained here. The normal installed profile and original scene are outside this workflow.

Image comparison used Pillow/NumPy, discarding the top 140 rows for menu/statistics text, taking absolute signed channel differences over RGB, counting any changed pixel and pixels with a channel difference above 16, and reporting mean absolute channel difference. Raw PNGs are retained for independent inspection.

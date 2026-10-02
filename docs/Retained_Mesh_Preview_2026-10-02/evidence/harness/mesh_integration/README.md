# Private Mesh preview qualification

This harness builds and launches isolated Max 2027 sessions. It reuses the retained-point build/transport helpers but writes only to `build/mesh-integration-2026-10-02/`. Recipes reset and replace the **private** scene. Never run them in the artist session. No fixture is installed or included in an MZP.

1. Build each SDK with `python tools/performance/mesh_integration/build.py --year 2027` and `--year 2026`. Finish compilation before timing.
2. Launch `python tools/performance/mesh_integration/launch.py --run run02` with a fresh run name. Inspect `ready.json` and module paths. A private INI, startup folder and native DLL copies isolate it from the installed plugin.
3. Submit `smoke.ms`, `lifecycle.ms`, `point_regression.ms`, then `synthetic.ms` through `request.py --run RUN SCRIPT`. Wait for each response. After a timeout inspect the response file and process before another submission.
4. Submit `artist.ms`. Inspect `artist-mesh-200k-initial.png`: the foliage must actually be visible. Only then submit `artist_benchmark.ms` with `--timeout 900`. The scene on disk is opened read-only in practice: recipes never save it; save/reopen tests use a different local filename.
5. Submit `memory.ms`, optionally `stress.ms`, then `parity.ms`. The memory fixture needs the copied artist scene at the 2M-per-layer setting. The stress fixture measures the retained-only 20M-per-layer case and restores the 2M setting. The parity fixture resets the private scene.
6. Run `analyze.py --run RUN` with Python containing Pillow and NumPy (available in the bundled workspace runtime). It reads the original captured images without editing them. Inspect images as well as pixel differences: matching empty images do not prove correct display.
7. Submit `shutdown.ms` and independently verify the launched PID exited. Check that the artist scene hash and original artist process remain unchanged. Package only the tested script and binaries using `package.py --run RUN`.
8. Curate accepted receipts with `archive.py --run RUN` after recording `environment.json` and `protection.json` in that run directory. It copies only evidence and recipes into the report folder and hashes each file; scenes, native binaries and SDK files are excluded.

The synthetic control uses 200 ordinary native cone instances with matching accepted transforms and 870,400 triangles. The first triangle is checked in world coordinates and the total count is asserted. Native Max uses its ordinary material/lighting path, so this is geometry/placement parity, not shader equivalence. Hidden comparison nodes exist in every arm. An earlier exploratory 5,000-node control has substantial scene/callback overhead and is not the headline comparison.

The metric is a timed `viewport.setTM` + `completeRedraw` + posted-message processing step in milliseconds. Warmups and generation changes happen outside the timed region. Arms alternate order; counters must show no cache rebuild, generation change, explicit upload or new failure during navigation. This does not measure completed GPU frames, displayed FPS or hardware mouse-to-photon latency. Do not run compilers or other benchmarks simultaneously.

`run01` artist measurements are rejected: changing layout reset the camera, leaving foliage out of view. Its source and native-control experiments are exploratory only. Final evidence uses `run02` or the explicitly named final run in the report. Original raw attempts are preserved locally; only accepted evidence is curated into the report folder.

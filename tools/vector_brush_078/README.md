# Vector 0.78.1 qualification

These scripts use owned, hidden Max 2026 or 2027 processes with redirected profile paths. Never run the reset-scene fixtures in an artist process. The launcher refuses an existing host directory, verifies native module paths, copies the generated script, and waits for readiness. Native modules must come from the same fresh build and match the selected host year.

From the repository root, with the documented local toolchain:

```powershell
python tools/procedural_lab/check_generated.py --output build/vector-brush-078/generated-new
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/vector-brush-078/native-new
python tools/vector_brush_078/callback_probe/build.py --year 2027
python tools/vector_brush_078/launch.py --host host-new --native native-new --year 2027 --probe
python tools/vector_brush_078/run_suite.py --host host-new
```

Use 2026 consistently in both build and launch commands for that host. `run_suite.py` serializes the button/callback fixture, layout measurements/mode coverage, vector fixtures, passive inspection, performance and playback. Native layout validation fails on clipping or overlap. The callback probe is a private SDK test module and must never enter an installer. The button fixture controls the existing interaction-held provider and restores it, so the two artist desktop sessions cannot make a hidden-host release assertion nondeterministic. It verifies both deferral and release.

To run the later fixtures individually after the button/layout checks:

```powershell
python tools/vector_brush_078/request.py tools/vector_brush_078/acceptance.ms --host host-new --timeout 240
python tools/vector_brush_078/request.py tools/vector_brush_078/extended.ms --host host-new --timeout 240
python tools/vector_brush_078/request.py tools/vector_brush_078/inspection.ms --host host-new
python tools/vector_brush_078/request.py tools/vector_brush_078/performance.ms --host host-new --timeout 240
python tools/vector_brush_078/request.py tools/vector_brush_078/playback.ms --host host-new --timeout 240
```

Keep requests sequential. After a timeout, inspect `dev-result.txt` and the owned process before submitting another request. The extended and inspection fixtures depend on the scene produced by acceptance; playback resets that scene and runs last. The two thin `.ms` dispatchers use the workspace's explicit `F:/Cursor/_Cyrus_Apps/CyrusScatter` path; adjust those paths if reproducing in another checkout.

Results are `vector-checks.txt`, `vector-timings.csv`, `population-timings.csv`, `cache-counters.txt`, `inspection.json`, `playback/result.txt`, `launch.json`, `loaded.tsv`, and disposable `.max` scenes inside that host directory. The 400-gesture timings include authoring/commit/Undo capture and prepared vector borders. The separate 40-edit workload measures authoring, border preparation and forced population publication individually. Explicit Update may rebuild the combined row array while reusing receiver-local candidate caches. Neither timing measures presented viewport FPS.

`package_tested.py` accepts `--host`, `--native`, `--analyzer`, `--output`, and `--receipt`. It requires completed button, native layout and broader host checks, verifies matching build/host years, current compiled sources, pinned Clipper2 files and tested script/native hashes, then uses the ordinary package builder. It explicitly packages only the four product modules, excluding the private callback probe. It does not install anything. Check the owned process command line against `launch.json` before stopping only its PID; never stop all Max processes.

Coverage and remaining physical-input, heavy-scene and platform gates are recorded in [the current patch report](../../docs/Brush_Start_0.78.1_2026-10-10/README.md). The [original integration report](../../docs/Vector_Brush_0.78_2026-10-10/README.md) retains 0.78.0's historical results and missed button path.

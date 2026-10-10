# Procedural Brush laboratory

Historical harness for the retired stroke API, through 0.77. Its scripts and benchmarks require their matching frozen checkout; they do not qualify or build the 0.78 vector brush. Use [the vector campaign](../vector_brush_078/README.md) for current qualification. These files preserve reproducibility of [the original implementation report](../../docs/Brush_Tool_2026-10-02/IMPLEMENTATION_2026-10-03.md); they are not packaged product code.

## Build and launch

From the repository root in PowerShell:

```powershell
python tools/brush_lab/build.py --year 2027
python tools/brush_lab/build.py --year 2026
python tools/brush_lab/launch.py --run my-brush-test
```

Use a new lowercase run name each time. The launcher refuses to overwrite a run. It starts a separate visible Max 2027 process with private plug-in binaries, INI, startup, temp, plugcfg and autoback directories under `build/brush-lab-2026-10-03/<run>`. It reads the installed user's Max INI as a template; `--config <path>` overrides that input. It never installs into or resets the artist's Max process.

Prerequisites match this workspace: Python, CMake, Visual Studio 2022 Community, MSVC 14.38.33130, Windows SDK 10.0.19041.0, and extracted Max SDKs under `build/tooling/max<year>-sdk/Program Files/Autodesk/3ds Max <year> SDK/maxsdk`. The launcher currently targets Max 2027; a successful 2026 build does **not** qualify the feature in the Max 2026 application. Use `--core-only` to build/test without Max SDKs.

Four matching binaries are copied into each run: `AminScatter.dlx`, `CyrusScatterEdit.dlm`, `CyrusBrush.dlx`, and **`CyrusBrushStorage.dlh`**. The last DLL registers the saved scene class and is essential for loading paint documents. Do not copy only the Brush DLX into a production install.

## Try the prototype

1. Click **Use flat test surface** or **Use curved test surface**.
2. Set Paint/Erase, radius, strength and softness. Click **Start brushing**, then drag on that surface.
3. Click **Stop / navigate** before ordinary scene navigation. Right-click also exits on the final candidate.
4. Choose a recorded stroke, change its enabled state, radius or strength, then click **Apply stroke edit**. Ctrl+Z/Ctrl+Y undo/redo a whole stroke or history edit.
5. Adjust Density from 0 to 1: it reveals a stable subset of a fixed 10,000-candidate population. It is a prototype fraction, not plants per square metre.
6. Uncheck **Update plants while painting** for Manual mode. Cursor/mask processing continues; plants wait for **Update preview**, including after Stop.

The source is a small cone so orientation is visible. Only the selected lab layer is displayed; the other layer's history stays saved. **New layer on picked surface** creates another isolated document on a visible, unfrozen mesh-convertible node. Arbitrary target support still needs the qualification matrix in the report. These controls are a test harness, not the final layer-manager design.

The mask overlay is bounded candidate-sampled dots. It is not a continuous heatmap and may be sparse on small patches. Original mesh vertex density does not define the painted field.

## Reproduction scripts

Send a script only to its private run:

```powershell
python tools/brush_lab/request.py --run my-brush-test tools/brush_lab/picking.ms
```

| Script | Preconditions and purpose |
| --- | --- |
| `picking.ms` | Plane/sphere, top/perspective grid; compare canonical BVH hits with exhaustive snapshot hits and record Painter discrepancies. |
| `verify.ms` | One real mouse stroke on each fixture, curved stroke last, no intervening Undo entry. Tests whole-gesture Undo, radius/disable edits, density, cancellation, inactive navigation, clone, translation and topology suspension. Saves `BrushLab.max` without derived display owners. |
| `manual_begin.ms`, `manual_verify.ms` | After verification, prepare Manual Erase; make one real erase drag through the curved strip, press Stop, then verify. Tests no automatic uploads, stable survivors, explicit publication and Undo/Redo. |
| `lifecycle.ms` | Disposable pair clone, remapped target, hide/delete suspension, pending-input cancellation; preserves the two demonstration layers. |
| `cancel_begin.ms`, `cancel_verify.ms` | Prepare provisional test input; right-click the viewport; verify the session and provisional input were canceled. |
| `reopen.ms` | Called by `launch.py --scene <saved BrushLab.max>`. Reconstructs the named fixture layers from native saved data. |
| `inspect.ms` | Record counts/stats and a viewport capture. |
| `storage_smoke.ms` | Destructive to the **private fixture**: save/load smoke test. |
| `restart_fixture.ms` | Reset and recreate the **private fixture**. |
| `export_pick_fixture.ms` | Export the current sphere-center ray/triangles for the native numerical regression. |

For fresh-process persistence:

```powershell
python tools/brush_lab/launch.py --run my-brush-reopen --scene build/brush-lab-2026-10-03/my-brush-test/BrushLab.max
```

Compare row counts and signatures in the first run's `verification.json` and the second run's `reopen.json`. `ready.json` records actual loaded module paths; `identity.json` records copied binary SHA-256 hashes. Raw scenes, binaries and screenshots stay in ignored `build/`; concise results belong in the report's evidence folder.

For the CPU history cost probe:

```powershell
python tools/brush_lab/build.py --year 2027 --history-benchmark
& ./build/brush-lab-2026-10-03/max2027/brush_history_benchmark.exe
```

It measures full field replay over 10,000 queries on a four-vertex plane with 10/100/1000 single-dab strokes. It does not measure Max interaction latency, retained uploads, GPU time, peak/Undo memory, or long cursor paths. Preserve that distinction when comparing results.

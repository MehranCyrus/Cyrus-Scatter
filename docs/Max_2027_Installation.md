# Cyrus Scatter — install and use in 3ds Max 2027

**Current source is Cyrus Scatter 0.72 (package 0.72.0).** Use the [current matching package guide](Integrated_UI_0.72_2026-10-06/PACKAGE.md), [workflow](Integrated_UI_0.72_2026-10-06/WORKFLOW.md) and [qualification boundaries](Integrated_UI_0.72_2026-10-06/RESULTS.md). This page preserves the older 0.64 installation workflow and pinned developer toolchain below. Historical 1.x development labels do not indicate publication readiness.

**Historical candidate:** 0.64, built 2026-10-02. **Tested host:** 3ds Max 2027.1, version 29.1.0.11426. The earlier packages are preserved. Read the [retained Mesh guide](Retained_Mesh_Preview_2026-10-02/README.md) and its [integration results](Retained_Mesh_Preview_2026-10-02/RESULTS.md).

The 0.64 candidate adds retained GPU instancing to Mesh, preserving its geometry limits and preview colors. It includes the [0.63 retained Point Cloud work](Retained_Point_Preview_2026-10-02/README.md), the [held-input synchronization improvements](Viewport_Performance_Round2_2026-10-01.md), [native proxy batches](Viewport_Performance_Implementation_2026-10-01.md), and the [CPU improvements](Performance_Implementation_2026-10-01.md). Automatic camera-dependent point detail, GPU computation of placements and asynchronous editing remain future work.

## Install

1. Save your current scene.
2. In Max 2027 choose **Scripting > Run Script**.
3. Run [CyrusScatter-0.64-Max2027.mzp](../dist/retained-mesh-0.64/CyrusScatter-0.64-Max2027.mzp).
4. For Surface Analyzer features, install [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp) if it is not already installed; its version is unchanged.
5. Close and **restart Max**. Native modules become available at startup.
6. Open **Create > Geometry**, choose the **Cyrus** category, then **Cyrus Scatter** or **Surface Analyzer**.

Use Run Script for these packages. Do not run the loose legacy `installer/install.ms` files: those remain 2026 source templates. The package builder produces the version-specific 2027 installers and includes their compiled native modules.

No compiler or Max SDK is needed to use these installers. Packages are restricted to Max 2027 and do not install into the Max program directory. The source and other Max versions are left in place.

## First scatter

1. Create a Plane and a small Box, teapot or plant source.
2. Create a **Cyrus Scatter** controller by clicking and dragging in the viewport.
3. Select the controller and open **Modify**.
4. Under **Surface Scatter**, click **Add: pick surface** and choose the plane.
5. Under **Layer Manager**, click **Add Layer**.
6. In that layer's **Source Object**, click **Add: pick in viewport** and choose the source.
7. Under **Point Generation**, choose **Count**, initially 200.
8. Under **Viewport and Render**, enable **Show preview**. Start with **Point Cloud** or **Proxy**; **Mesh** displays evaluated source geometry.
9. Click **Update now** or **Refresh preview** as needed. Change **Seed** to get another arrangement.

Manual update keeps the previous preview until you refresh. Real-time update tracks relevant changes and coalesces work. Display point/face budgets affect viewport representation, not the requested render population. Area/density/line filtering can reduce actual output count.

**Automatic final render** enables the existing PFlow preparation. Production renderer compatibility is not established by the batch smoke test below; test a small scene with your renderer before using a large production scene.

## Surface Analyzer

Create **Cyrus > Surface Analyzer**, select it and use Modify to pick an open planar surface, then Analyze. Each connected element must be planar; welded boundaries and holes are supported. Fit radius controls boundary clearance; Point radius controls sample separation. Start with moderate resolution.

To use the result as a scatter area, open a scatter layer's **Area > Surface Analyzer Area**, pick the Analyzer, and enable Center Line and/or Points. This filters placements; it does not automatically refill the requested count.

## Earlier 0.62 verification (retained as history)

- Built all three native modules against the genuine Max 2027 SDK with MSVC 14.38.33130 / compiler 19.38.33145, C++20, Windows SDK 10.0.19041.0, Release x64.
- All eight scatter CTest suites and the Analyzer CTest suite passed, including threading and prepared-boundary regressions.
- A separate Max 2027.1 batch process loaded extensions through a private plugin configuration and registered both scripts.
- Checked repeatable 200-instance native sampling, controller/layer placement, 400 point-preview samples, a 1,200-face box-proxy cache, CS Edit stack application, Analyzer execution, and scene save/reopen.
- MZP contents have SHA-256 manifests and ZIP integrity checks. Adjacent `.sha256` files fingerprint each package.
- The CPU differential harness compares every ordered numeric field against frozen pre-performance sources. The saved artist-scene harness compares preview/render transforms and source IDs for both fixed edge moves and their single-Undo states. See the implementation report for exact results and measurement scope.
- Separate Max fixtures check native filtering/transforms, serial/worker parity, actual queued SDK callbacks with preserved invalidation and one redraw request per batch, plus recorder 0.2.2 and trace/report exports.
- The viewport fixture checks all three proxy shapes, exact position/shading/color parity, chunk boundaries, memory caps and fallback, cache collection, Manual refresh, mouse-held deferral, clone and save/reopen. In the supplied scene, all 37,704 triangles match the previous draw data exactly.
- An isolated desktop comparison records 900 navigation steps with zero measured rebuilds and unchanged display counts. Median step time falls from 88.10 ms with the preserved native loop to 30.16 ms with batching. See the viewport report for Manual results, raw samples, visual differences and measurement boundaries.
- The 0.62 script change passed fresh viewport, general Max and compute fixtures, including held/released surface changes and Undo/Redo. A separate 720-step comparison records the additional held-input gain with unchanged counts and zero measured rebuilds. Eight real mouse pan strokes provide supporting smoke evidence. Native binaries match 0.61 exactly; no experimental retained-mesh renderer is packaged.

Still pending for 0.62: the artist's full interactive Modify/CS Edit/Undo retest beyond the scoped fixtures, installer dialogs in the normal user profile, Corona 15 production/IR behavior, other Max updates/host years and 32 GB hardware qualification. Desktop navigation and mouse-held callbacks have been tested; neither calculation nor synchronous redraw measurements establish completed GPU frames. Tests load the binaries/scripts via isolated startup paths and leave the normal installed profile and original open Max session unchanged.

The synthetic saved scene is [build/max2027-smoke.max](../build/max2027-smoke.max); it is a smoke-test artifact, not a production scene. Native and batch logs are under `build/`.

## Installation locations and upgrades

Scatter scripts go under the current Max user's `userScripts/AminScatter`; Analyzer uses `userScripts/CyrusSurfaceAnalyzer`. Each package's binaries use a host-year and native-content-hash subfolder. The generated installer registers only that folder in `Plugin.UserSettings.ini`, with a 2027 key. Startup scripts load the scripted classes after restart.

If Cyrus is missing after restart, check that the 2027 MZP was run, review the installation error, and check Max's plugin-loading log. Avoid registering extra copies of the native modules in additional plugin directories. A differing loaded native build requires a restart; copying a script alone cannot replace it.

Scatter includes an installed `Uninstall.ms` under its userScripts folder. It removes its 2027 registration/startup entries and describes the restart procedure. Do not delete your original scene files or unrelated plugin folders.

For the previous viewport candidate, use [CyrusScatter-0.61-Max2027.mzp](../dist/CyrusScatter-0.61-Max2027.mzp). For the pre-viewport build, install [CyrusScatter-0.60-Max2027.mzp](../dist/CyrusScatter-0.60-Max2027.mzp), restart and reopen the original saved test copy. For an exact pre-CPU-performance comparison, use [CyrusScatter-0.59-PrePerformance-Max2027.mzp](../dist/CyrusScatter-0.59-PrePerformance-Max2027.mzp); it restores the frozen native engine and tracing script. The ordinary [0.59 package](../dist/CyrusScatter-0.59-Max2027.mzp) remains available but predates some tracing script changes. Backward reopening of candidate-saved scenes has not been qualified.

## Rebuild for developers

The SDK is a build dependency and is not redistributed in the MZP. The extracted SDK used here is under `build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk`. Its MSI was obtained from the official Autodesk APS page and verified with a valid Autodesk digital signature.

From the repository root:

```powershell
python tools/build_max.py --max-year 2027 --sdk-root "F:\Cursor\_Cyrus_Apps\CyrusScatter\build\tooling\max2027-sdk\Program Files\Autodesk\3ds Max 2027 SDK\maxsdk"
python tools/test_max2027.py
python tools/test_compute_performance.py
python tools/test_viewport_performance.py
```

The build script regenerates the owned Scatter script using Node.js before compiling and packaging, preventing a stale/missing generated script from entering a fresh build. Developers need Node.js on PATH or can pass `--node` with its executable path; MZP users do not need it. The script supports explicit compiler/SDK paths via `--help`, runs native tests before packaging, and uses a pinned NMake environment because CMake's Visual Studio instance discovery failed on this machine. The shared CMake module rejects a mismatched SDK year. The separate [Max 2026 handoff](handoffs/max2026/README.md) was subsequently built against Autodesk's Max 2026 SDK, with all nine native suites passing. Its installers and interactive behavior still require testing in Max 2026, which is not installed here; 2024/2025 ports remain future work.

A source backup from the earlier host-compatibility work is stored at `build/baseline-before-max2027.zip`. The viewport change also preserves its starting workspace files in `build/viewport-optimization-2026-10-01/before-viewport-changes.zip`.

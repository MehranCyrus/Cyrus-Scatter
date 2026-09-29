# Cyrus Scatter — install and use in 3ds Max 2027

**Build date:** 2026-09-28. **Tested host:** 3ds Max 2027.1, version 29.1.0.11426.

This is a Max 2027 compatibility build of the current CPU implementation. The performance roadmap's multithreading and GPU work is still future work.

## Install

1. Save your current scene.
2. In Max 2027 choose **Scripting > Run Script**.
3. Run [CyrusScatter-0.59-Max2027.mzp](../dist/CyrusScatter-0.59-Max2027.mzp).
4. For Surface Analyzer features, also run [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp).
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

## Verification performed

- Built all three native modules against the genuine Max 2027 SDK with MSVC 14.38.33130 / compiler 19.38.33145, C++20, Windows SDK 10.0.19041.0, Release x64.
- All six scatter CTest suites and the Analyzer CTest suite passed.
- A separate Max 2027.1 batch process loaded extensions through a private plugin configuration and registered both scripts.
- Checked repeatable 200-instance native sampling, controller/layer placement, 400 point-preview samples, a 1,200-face box-proxy cache, CS Edit stack application, Analyzer execution, and scene save/reopen.
- MZP contents have SHA-256 manifests and ZIP integrity checks. Adjacent `.sha256` files fingerprint each package.

Not yet verified: visual inspection of the interactive Modify panel/viewport, the installer dialogs in the normal user profile, final renderer/IR behavior, other Max 2027 updates, performance comparisons, or other host years. The test loaded the same binaries/scripts via isolated startup paths; it did not install into or manipulate the already-open Max session.

The synthetic saved scene is [build/max2027-smoke.max](../build/max2027-smoke.max); it is a smoke-test artifact, not a production scene. Native and batch logs are under `build/`.

## Installation locations and upgrades

Scatter scripts go under the current Max user's `userScripts/AminScatter`; Analyzer uses `userScripts/CyrusSurfaceAnalyzer`. Each package's binaries use a host-year and native-content-hash subfolder. The generated installer registers only that folder in `Plugin.UserSettings.ini`, with a 2027 key. Startup scripts load the scripted classes after restart.

If Cyrus is missing after restart, check that the 2027 MZP was run, review the installation error, and check Max's plugin-loading log. Avoid registering extra copies of the native modules in additional plugin directories. A differing loaded native build requires a restart; copying a script alone cannot replace it.

Scatter includes an installed `Uninstall.ms` under its userScripts folder. It removes its 2027 registration/startup entries and describes the restart procedure. Do not delete your original scene files or unrelated plugin folders.

## Rebuild for developers

The SDK is a build dependency and is not redistributed in the MZP. The extracted SDK used here is under `build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk`. Its MSI was obtained from the official Autodesk APS page and verified with a valid Autodesk digital signature.

From the repository root:

```powershell
python tools/build_max.py --max-year 2027 --sdk-root "F:\Cursor\_Cyrus_Apps\CyrusScatter\build\tooling\max2027-sdk\Program Files\Autodesk\3ds Max 2027 SDK\maxsdk"
python tools/test_max2027.py
```

The build script supports explicit compiler/SDK paths via `--help`, runs native tests before packaging, and uses a pinned NMake environment because CMake's Visual Studio instance discovery failed on this machine. The shared CMake module rejects a mismatched SDK year. Max 2026 configuration is retained but was not rebuilt or runtime-tested during this 2027 task; 2024/2025 ports remain future work.

A pre-change source backup is stored at `build/baseline-before-max2027.zip`. No Git commands or subagents were used.

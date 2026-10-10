# Install and build Cyrus Scatter for Max 2027

Use the matching **Scatter 0.75.0 + Analyzer 0.14 development pair** recorded in [the latest courtyard qualification](Courtyard_Fixes_0.75_2026-10-10/README.md). Earlier installers are historical comparison artifacts; the unchanged version captions do not identify this candidate.

## Install

1. Save the scene and use a copy for development-build acceptance.
2. In Max 2027, choose **Scripting > Run Script** and run both [CyrusScatter-0.75.0-Max2027.mzp](../dist/Courtyard_Fixes_0.75_2026-10-10/Max2027/CyrusScatter-0.75.0-Max2027.mzp) and [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../dist/Courtyard_Fixes_0.75_2026-10-10/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp).
3. Restart Max so both scripts and their native modules load together. Do not load a loose new script over older DLLs.
4. Create **Geometry > Cyrus > Cyrus Scatter** and follow the [artist guide](ARTIST_GUIDE.md): Layer → Surfaces → Models → Amount → Update scatter.

[PACKAGE.json](Courtyard_Fixes_0.75_2026-10-10/PACKAGE.json) pins both local installers. Their payloads match the runtime-tested modules/scripts and their archive hashes were verified. Installer execution itself was not repeated, and neither package was installed into the artist profile. `dist/` is ignored and is not supplied by a source-only Git clone. If absent, build matching source with the documented toolchain; do not substitute an older package.

Existing Analyzer guides without the new saved freshness record need one explicit **Analyze / Update Analyzer**, followed by **Update scatter** when Scatter is Manual. The previous complete Scatter result is preserved if a successor encounters a stale guide. Analyzer's [guide](../CyrusSurfaceAnalyzer/README.md) explains supported planar inputs; curved Brush painting is a separate Scatter feature.

## Installed files and recovery

The generated installer uses the current Max user's scripts directory: `CyrusScatter` for Scatter and `CyrusSurfaceAnalyzer` for Analyzer. Native modules use a host-year/content-specific subfolder registered in the user's plugin configuration. Startup scripts load the scripted classes. No compiler or SDK is required to use a built MZP.

Use the packaged installer, not loose legacy installer templates. If the category is missing after restart, check the selected Max year, installer error and plugin-loading log. Avoid duplicate module registrations. Use the installed `Uninstall.ms` for that product and restart as instructed; retain original scenes and unrelated plugins.

## Rebuild for developers

The local qualified Max 2027 toolchain uses the matching Autodesk SDK, Visual Studio 2022/MSVC **14.38.33130**, Windows SDK **10.0.19041.0**, Release x64. Max 2027 uses C++20. Node.js generates MAXScript; Python drives build/test tools. Check the source tools' `--help` for explicit paths.

From the repository root, first follow the [agent workflow](AGENT_WORKFLOW.md) and choose fresh output directories:

```powershell
python tools/procedural_lab/check_generated.py --output build/<run>/generated
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --year 2027 --project scatter --output build/<run>/scatter
python tools/procedural_lab/offline_build.py --year 2027 --project analyzer --output build/<run>/analyzer
```

For a build plus package:

```powershell
python tools/build_max.py --max-year 2027 --sdk-root "<path-to-the-2027-maxsdk>"
```

The package builder regenerates owned UI, checks version consistency, builds with the target SDK, runs native tests and produces versioned archives. It does not make an old host qualification apply to newly changed source. SDKs are local build dependencies, not redistributed product files.

Max 2026 requires its own matching SDK/package and runtime qualification; the latter remains open. The older boss handoff and legacy smoke launchers target frozen builds, not this current acceptance campaign. Use [current test receipts and reproduction](Courtyard_Fixes_0.75_2026-10-10/README.md) for the active baseline.

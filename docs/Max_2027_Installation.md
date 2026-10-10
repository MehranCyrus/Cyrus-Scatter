# Install and build Cyrus Scatter for Max 2026 and 2027

Use the matching **Scatter 0.78.1 + Analyzer 0.14 development pair** recorded in [the current qualification](Brush_Start_0.78.1_2026-10-10/README.md). The earlier 0.78.0 package has a Start Brush session defect. Exact payload hashes identify the corrected candidate.

## Install

1. Save the scene and use a copy for development-build acceptance.
2. Choose **Scripting > Run Script** and run the Scatter and Analyzer installers for your Max year from [the delivery links](Brush_Start_0.78.1_2026-10-10/README.md). A Max 2027 binary cannot be used in Max 2026.
3. Restart Max so both scripts and their native modules load together. Do not load a loose new script over older DLLs.
4. Create **Geometry > Cyrus > Cyrus Scatter** and follow the [artist guide](ARTIST_GUIDE.md): Layer → Surfaces → Models → Amount → Update scatter.

[The delivery receipts](Brush_Start_0.78.1_2026-10-10/README.md) pin each year's local installers. Scatter matches the runtime-tested modules/script. Analyzer uses unchanged 0.14 source with a matching SDK build and core test; full Analyzer renderer qualification was not repeated in this brush campaign. Archive contents and hashes are verified. Installer execution itself was not repeated, and neither package was installed into the artist profile. `dist/` is ignored and is not supplied by a source-only Git clone. If absent, build matching source with the documented toolchain; do not substitute an older package.

0.78 keeps receiver-local sampling and replaces painting with a new canonical vector format.

**Create a new 0.78 setup.** Schema 55 rejects older development setups and stroke payloads; it does not convert them. Preserve the original scene and its old matching build. Vector painting supports single-valued local-XY terrain/planes; spheres, vertical/folded/stacked receivers are not supported for this brush.

Existing Analyzer guides without the new saved freshness record need one explicit **Analyze / Update Analyzer**, followed by **Update scatter** when Scatter is Manual. The previous complete Scatter result is preserved if a successor encounters a stale guide. Analyzer's [guide](../CyrusSurfaceAnalyzer/README.md) explains supported planar inputs; ordinary scattering on curved receivers is separate from the projected vector brush.

## Installed files and recovery

The generated installer uses the current Max user's scripts directory: `CyrusScatter` for Scatter and `CyrusSurfaceAnalyzer` for Analyzer. Native modules use a host-year/content-specific subfolder registered in the user's plugin configuration. Startup scripts load the scripted classes. No compiler or SDK is required to use a built MZP.

Use the packaged installer, not loose legacy installer templates. If the category is missing after restart, check the selected Max year, installer error and plugin-loading log. Avoid duplicate module registrations. Use the installed `Uninstall.ms` for that product and restart as instructed; retain original scenes and unrelated plugins.

## Rebuild for developers

The local toolchain uses the matching Autodesk SDK, Visual Studio 2022/MSVC **14.38.33130**, Windows SDK **10.0.19041.0**, Release x64. Max 2026 uses C++17; Max 2027 uses C++20. Node.js generates MAXScript; Python drives build/test tools. Use separate output folders and the matching `--year`/`--max-year` for each host. Check the source tools' `--help` for explicit paths.

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

The older boss handoff and legacy smoke launchers target frozen builds, not this current acceptance campaign. Use [current test receipts and reproduction](Brush_Start_0.78.1_2026-10-10/README.md) for the tested Max 2026/2027 scope and remaining physical-input, DPI and renderer gates.

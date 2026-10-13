# Install and build Cyrus Scatter for Max 2026 and 2027

Current Scatter development packages are **0.81.2 / schema 58**, with **Analyzer 0.14** independently versioned. Use the [matched installers and installation receipt](plans/spline-bands/INSTALLATION.md) under `dist/CyrusScatter-0.81.2-20261013/`. Both local Max profiles have been upgraded on disk at the user's request; restart is required and fresh normal-profile launch acceptance is pending. Existing team licensing remains unchanged; see [owner/teammate instructions](../tools/licensing/README.md).

## Install

1. Save the scene and use a copy for development-build acceptance.
2. Choose **Scripting > Run Script** and run the [Scatter 0.81.2 installer](plans/spline-bands/INSTALLATION.md) for your Max year. The local profiles already contain it. If you need the separate Analyzer, use the [unchanged Analyzer 0.14 delivery](Container_and_Radius_0.78.3_2026-10-10/README.md). A Max 2027 binary cannot be used in Max 2026.
3. Restart Max so both scripts and their native modules load together. Do not load a loose new script over older DLLs.
4. Create **Geometry > Cyrus > Cyrus Scatter** and follow the [artist guide](ARTIST_GUIDE.md): Layer → Surfaces → Models → Amount → Update scatter.

[The current delivery receipt](plans/spline-bands/INSTALLATION.md) pins each year's package and installed files against the runtime-tested modules/script. Installation used verified package payloads with backups; the interactive installer dialog was not run in the open artist session. Analyzer was not changed. `dist/` is ignored and is not supplied by a source-only Git clone. If absent, build matching source with the documented toolchain; do not substitute an older package.

0.78 keeps receiver-local sampling and replaces painting with a new canonical vector format.

**Use schema-58 setups for 0.81.2.** Existing 0.81.1 setups open directly; create a fresh setup for an earlier schema. Earlier development scenes are rejected without migration. Preserve the original scene and its old matching build. Vector painting supports single-valued local-XY terrain/planes; spheres, vertical/folded/stacked receivers are not supported for this brush.

Keep the file's system units when opening the packaged 25-case examples in their matching historical build. Current 0.81.2 uses typed distances and current-only placement transport. The [implementation evidence](plans/spline-bands/PROGRESS.md) and [installation receipt](plans/spline-bands/INSTALLATION.md) distinguish host qualification from delivery. Native Paint/Edit geometry bindings still reject unsupported conversion; preserve original scenes and never combine a new script with stale native modules.

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

The older boss handoff and historical smoke launchers target frozen builds. Use [current test receipts and reproduction](plans/spline-bands/PROGRESS.md) for the tested Max 2026/2027 scope and remaining physical-input, DPI and renderer gates.

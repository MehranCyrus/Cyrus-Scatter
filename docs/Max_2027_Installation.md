# Install and build Cyrus Scatter for Max 2027

The **0.83.0 / schema 58** installer is ready for manual installation in **Max 2027**.
This package was verified against the qualified script/native pair; it has not
been installed by this task. Historical installation evidence is retained in
[0.82.2](plans/eleven-phase-roadmap/INSTALLATION_0822.md). The current
[package record and preset checklist](plans/improvement-program/I04_0830.md)
pins the archive and its verification. Follow the
[phase-by-phase artist checklist](plans/eleven-phase-roadmap/ARTIST_ACCEPTANCE_0822.md).
Max 2026 retains the [preceding 0.81.6 installation](plans/terrace-0815/INSTALLATION_0816.md).
New development/testing uses Max 2027 only. Analyzer 0.14 and existing team
licensing are unchanged; see [owner/teammate instructions](../tools/licensing/README.md).

## Install

0.83.0 adds [direction/target controls and angular normal blending, retaining the preceding recipe library and four examples](plans/improvement-program/I04_0830.md). It preserves [0.82.6 lazy panels and bounded stage diagnostics](plans/panel-performance-0826/PROGRESS.md), retaining the preceding [complete static recipes including Paint](plans/recipes-0825/PROGRESS.md). It retains mesh channel density and Paint tooltips.
It retains the [0.82.3 idle/panel correction](plans/eleven-phase-roadmap/PERFORMANCE_0823.md),
the five completed phases and the preceding
[zero-limit Point Cloud/mode-switch fixes](plans/terrace-0815/VIEWPORT_0817.md).
The scripts and native modules must be installed and loaded together.

1. Save the scene and use a copy for development-build acceptance.
2. Choose **Scripting > Run Script** and run the [0.83.0 Max 2027 installer](../dist/CyrusScatter-0.83.0-20261016/CyrusScatter-0.83.0-Max2027.mzp). If you need the separate Analyzer, use the [unchanged Analyzer 0.14 delivery](Container_and_Radius_0.78.3_2026-10-10/README.md). A Max 2027 binary cannot be used in Max 2026.
3. Restart Max so both scripts and their native modules load together. Do not load a loose new script over older DLLs.
4. Create **Geometry > Cyrus > Cyrus Scatter** and follow the [artist guide](ARTIST_GUIDE.md): Layer → Surfaces → Models → Amount → Update scatter.

The [0.83.0 package record](plans/improvement-program/I04_0830.md)
pins the exact archive and qualified bytes. Manual installation, restart and
normal-profile artist acceptance remain separate from the private-host tests. Earlier
installation receipts remain historical evidence for their deliveries/backups.
Analyzer was not changed. `dist/` is ignored and is not supplied by a source-only
Git clone. If absent, build matching source with the documented toolchain.

0.78 keeps receiver-local sampling and replaces painting with a new canonical vector format.

**Use schema-58 setups for 0.83.0.** The saved format remains 58; new capabilities
require the complete matching native/script pair. Create a fresh setup for an
earlier schema. Earlier development scenes are rejected without migration.
Preserve original files and their matching older build. Vector painting supports
single-valued local-XY terrain/planes; spheres, vertical/folded/stacked receivers
are not supported for this brush.

Keep the file's system units when opening historical examples in their matching
build. Current settings use typed distances and current-only placement transport.
Native Paint/Edit geometry bindings still reject unsupported conversion; preserve
original scenes and never combine a new script with stale native modules.

Existing Analyzer guides without the new saved freshness record need one explicit **Analyze / Update Analyzer**, followed by **Update scatter** when Scatter is Manual. The previous complete Scatter result is preserved if a successor encounters a stale guide. Analyzer's [guide](../CyrusSurfaceAnalyzer/README.md) explains supported planar inputs; ordinary scattering on curved receivers is separate from the projected vector brush.

## Installed files and recovery

The generated installer uses the current Max user's scripts directory: `CyrusScatter` for Scatter and `CyrusSurfaceAnalyzer` for Analyzer. Native modules use a host-year/content-specific subfolder registered in the user's plugin configuration. Startup scripts load the scripted classes. No compiler or SDK is required to use a built MZP.

Use the packaged installer, not loose legacy installer templates. If the category is missing after restart, check the selected Max year, installer error and plugin-loading log. Avoid duplicate module registrations. Use the installed `Uninstall.ms` for that product and restart as instructed; retain original scenes and unrelated plugins.

## Rebuild for developers

The local toolchain uses the Max 2027 SDK, Visual Studio 2022/MSVC
**14.38.33130**, Windows SDK **10.0.19041.0**, Release x64 and C++20. Node.js
generates MAXScript; Python drives build/test tools. Use fresh output folders and
explicit `--year 2027` / `--max-year 2027`. Max 2026 work requires a new explicit
user request. Check the source tools' `--help` for paths.

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

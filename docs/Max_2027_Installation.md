# Install and build Cyrus Scatter

The **0.86.2 / schema 58** delivery includes matching Max 2024, 2026 and 2027 MZPs and one universal EXE. Max 2026/2027 have scoped runtime qualification; **Max 2024 remains preview** without a runnable local host. Eight ready examples and three starter masks are bundled. See the [current delivery](plans/preset-gallery-improvements/DELIVERY_0862.md) for exact files and limits. The explicit older-host request applies to this compatibility delivery; ordinary development remains Max 2027 by default. No artist installation/restart was performed.

## Install

0.86.2 retains the native foundation, Modify-panel scrolling/dragging and library scale corrections. It simplifies [library loading](plans/preset-gallery-improvements/ARTIST_WORKFLOW.md): select terrain, open Cyrus Library and Load onto surface. It retains eight examples, revisioned recipes, selective style, bounded portable assets, grids/orientation, lazy panels, complete supported Paint and mesh-channel density.
It retains the [0.82.3 idle/panel correction](plans/eleven-phase-roadmap/PERFORMANCE_0823.md),
the implemented P01–P07 features and the preceding
[zero-limit Point Cloud/mode-switch fixes](plans/terrace-0815/VIEWPORT_0817.md).
The scripts and native modules must be installed and loaded together.

1. Save the scene and use a copy for development-build acceptance.
2. Open the intended Max version once to initialize its user profile, then save/close it and run the [universal EXE](../dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Setup.exe). Select that year and Install / Repair. Alternatively use **Scripting > Run Script** with the matching-year MZP from the [delivery report](plans/preset-gallery-improvements/DELIVERY_0862.md); use this route for custom Max installation paths.
3. Restart Max so both scripts and their native modules load together. Do not load a loose new script over older DLLs.
4. For presets, add **Cyrus Library** from Customize > Cyrus actions to a toolbar/menu, select one terrain mesh and run it. Load onto surface creates the setup or adds layers. Manual creation remains **Geometry > Cyrus > Cyrus Scatter**, then Layer → Surfaces → Models → Amount → Update scatter.

The [0.86.2 package record](plans/preset-gallery-improvements/DELIVERY_0862.md)
pins the exact archive and qualified bytes. Manual installation, restart and
normal-profile artist acceptance remain separate from the private-host tests. Earlier
installation receipts remain historical evidence for their deliveries/backups.
Analyzer was not changed. `dist/` is ignored and is not supplied by a source-only
Git clone. If absent, build matching source with the documented toolchain.

0.78 keeps receiver-local sampling and replaces painting with a new canonical vector format.

**Use schema-58 setups for 0.86.2.** The saved format remains 58; new capabilities
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

Scatter installs under the selected Max user's scripts directory in `CyrusScatter/Releases/<version-content-id>`. The release contains the matching script, native modules, managed gallery and immutable `Library-0.86.2`. Startup and plugin registration point to that complete release. Personal recipes in `Documents/CyrusScatter/Library` and activation are preserved. Analyzer uses its separate installer and directory. No compiler or SDK is required to use either built Scatter installer.

Both routes use the same hash-verified staging and journal recovery engine. A locked file or changed registration can reject installation while preserving the preceding bindings. Save your work and follow the reported recovery/restart guidance. Old release folders, imported texture storage and personal recipes are intentionally retained; unregistering is not a general disk cleanup.

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

The older boss handoff and historical smoke launchers target frozen builds. Use [current Max 2027 receipts and reproduction](plans/native-placement/DELIVERY_0860.md); older Max 2026 receipts remain historical. Physical-input, DPI and renderer claims retain their stated limits.

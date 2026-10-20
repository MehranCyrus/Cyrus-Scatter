# Install and build Cyrus Scatter

The **0.86.6 / schema 58** delivery provides a matched Max 2027 MZP and shareable Windows EXE with eight revised examples and three starter masks. See the [current delivery](plans/preset-gallery-improvements/DELIVERY_0866.md). The earlier [0.86.2 multi-host delivery](plans/preset-gallery-improvements/DELIVERY_0862.md) retains its distinct Max 2024/2026/2027 scope. No artist installation/restart was performed.

## Install

0.86.2 retains the native foundation, Modify-panel scrolling/dragging and library scale corrections. It simplifies [library loading](plans/preset-gallery-improvements/ARTIST_WORKFLOW.md): select terrain, open Cyrus Library and Load onto surface. It retains eight examples, revisioned recipes, selective style, bounded portable assets, grids/orientation, lazy panels, complete supported Paint and mesh-channel density.
It retains the [0.82.3 idle/panel correction](plans/eleven-phase-roadmap/PERFORMANCE_0823.md),
the implemented P01–P07 features and the preceding
[zero-limit Point Cloud/mode-switch fixes](plans/terrace-0815/VIEWPORT_0817.md).
The scripts and native modules must be installed and loaded together.

1. Save the scene and use a copy for development-build acceptance.
2. Run [CyrusScatter-0.86.6-Setup.exe](../dist/CyrusScatter-0.86.6-20261019/CyrusScatter-0.86.6-Setup.exe), choose Max 2027, then Install / Repair. Alternatively, in Max 2027, use **Scripting > Run Script** and select [CyrusScatter-0.86.6-Max2027.mzp](../dist/CyrusScatter-0.86.6-20261019/CyrusScatter-0.86.6-Max2027.mzp). Follow the installer result before restarting.
3. Restart Max so both scripts and their native modules load together. Do not load a loose new script over older DLLs.
4. For presets, add **Cyrus Library** from Customize > Cyrus actions to a toolbar/menu, select one terrain mesh and run it. Load onto surface creates the setup or adds layers. Manual creation remains **Geometry > Cyrus > Cyrus Scatter**, then Layer → Surfaces → Models → Amount → Update scatter.

The [0.86.6 package record](plans/preset-gallery-improvements/DELIVERY_0866.md)
pins the exact archive and qualified bytes. Manual installation, restart and
normal-profile artist acceptance remain separate from the private-host tests. Earlier
installation receipts remain historical evidence for their deliveries/backups.
Analyzer was not changed. `dist/` is ignored and is not supplied by a source-only
Git clone. If absent, build matching source with the documented toolchain.

0.78 keeps receiver-local sampling and replaces painting with a new canonical vector format.

**Use schema-58 setups for 0.86.6.** The saved format remains 58; new capabilities
require the complete matching native/script pair. Create a fresh setup for an
earlier schema. Earlier development scenes are rejected without migration.
Preserve original files and their matching older build. Vector painting retains the local-XY terrain path and restores spheres, boxes,
vertical sides and manifold curved receivers. Geometry changes remain guarded;
curved coverage requires indexed face correspondence.

Keep the file's system units when opening historical examples in their matching
build. Current settings use typed distances and current-only placement transport.
Native Paint/Edit geometry bindings still reject unsupported conversion; preserve
original scenes and never combine a new script with stale native modules.

Existing Analyzer guides without the new saved freshness record need one explicit **Analyze / Update Analyzer**, followed by **Update scatter** when Scatter is Manual. The previous complete Scatter result is preserved if a successor encounters a stale guide. Analyzer's [guide](../CyrusSurfaceAnalyzer/README.md) explains supported planar inputs; Analyzer remains separate from the surface brush, which now supports manifold curved receivers.

## Installed files and recovery

Standard Max profiles install the immutable runtime under `%LOCALAPPDATA%/CyrusScatter/<year>/r/<content-id>`. An explicitly relocated profile uses `<profile>/cs/r/<content-id>`. The short archive names are mapped back to their full logical library paths during verified installation. The release contains the matching script, native modules, managed gallery and immutable `Library-0.86.2`. Startup, macros, the install receipt and plugin registration remain in the selected Max profile and point to that complete release. Personal recipes in `Documents/CyrusScatter/Library` and activation are preserved. Older `userScripts/CyrusScatter/Releases/` directories remain recovery content. Analyzer uses its separate installer and directory. No compiler or SDK is required to use either built Scatter installer.

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

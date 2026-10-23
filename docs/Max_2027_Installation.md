# Install and build Cyrus Scatter

The **0.86.8.6 / schema 59** combined installer contains matched **Max 2024, 2026 and 2027** Scatter payloads and **Surface Analyzer 0.14.1**. See the [current qualification report](plans/combined-installer/DELIVERY_08686.md). Earlier packages retain their original host scope.

## Install

Run `dist/CyrusScatter-0.86.8.6-20261023/CyrusScatter-0.86.8.6-Setup.exe`.
Close the selected Max versions, select their cards, then click
**Install** or **Update**. Detection, validation and storage checks run
automatically. **Uninstall** keeps shared content and other hosts. Success shows
**Installation completed**. **Error details** is available only after a failure.

A profile without an installation receipt can migrate exact recognized startup/macro files from 0.81.6, 0.85.0, 0.86.8.2, 0.86.8.3 or 0.86.8.4. Original bytes are preserved under `scripts/CyrusScatter/Backups/wrappers-<hash>/` before registration changes. A valid receipt continues to own its exact recorded files. Unknown/custom files are retained; **Error details** names the Max version and conflicting paths. Do not delete an unrecognized file just to bypass the check.

Leave **Install / update plant library** unchecked to update only the plugin
and reuse the registered library or recognized older runtime's library.
For new content, place **CyrusScatter-Content-0.86.7.zip** beside the EXE and
check that option. A missing or mismatched ZIP produces an error before install.
The installer streams verified files directly into one shared library; it does
not unpack an extra temporary library or create a copy for each Max version.
Identical installed content is reused. Content remains revision 0.86.7 because
the models, materials and previews have not been regenerated.

The combined EXE installs both products for each selected host. Save your work and restart Max after installation. **Uninstall Scatter** retains the independent Analyzer and shared library. Matched MZPs remain embedded/recovery artifacts; separate MZP installation is not required when using this EXE.
Analyzer's **Analyze / Update Analyzer** button recalculates guides rather than updating installed software.
The hosted route resolves an existing shared or legacy library. For a fresh
recipient, use the EXE with the content ZIP and its library checkbox.
There is no automatic online content download.

Standard profiles for Max 2024, 2026 and 2027 share one selected library.
Content revision is independent of the plugin revision. Share the content
separately with recipients who do not have it; the EXE/MZPs contain the plugin.
Save your work and restart Max after installation. Old paths are retained
because saved scenes may still reference their textures.
Corona/Forest plug-ins matching the host are required by the supplied materials.
The instructions below retain the separate historical 0.86.6 build evidence.

0.86.2 retains the native foundation, Modify-panel scrolling/dragging and library scale corrections. It simplifies [library loading](plans/preset-gallery-improvements/ARTIST_WORKFLOW.md): select terrain, open Cyrus Library and Load onto surface. It retains eight examples, revisioned recipes, selective style, bounded portable assets, grids/orientation, lazy panels, complete supported Paint and mesh-channel density.
It retains the [0.82.3 idle/panel correction](plans/eleven-phase-roadmap/PERFORMANCE_0823.md),
the implemented P01–P07 features and the preceding
[zero-limit Point Cloud/mode-switch fixes](plans/terrace-0815/VIEWPORT_0817.md).
The scripts and native modules must be installed and loaded together.

1. Save the scene and use a copy for development-build acceptance.
2. For the historical three-host 0.86.8.2 delivery only, run [CyrusScatter-0.86.8.2-Setup.exe](../dist/CyrusScatter-0.86.8.2-20261021/CyrusScatter-0.86.8.2-Setup.exe), select Max 2024, 2026 and/or 2027 and click **Install/Update**. Alternatively use **Scripting > Run Script** with the matching MZP from that folder. Follow the installer result before restarting.
3. Restart Max so both scripts and their native modules load together. Do not load a loose new script over older DLLs.
4. Open **Layers > Recipes** or the **Cyrus Library** action. Plant models offers **Merge model** or **Add to selected layer**. Personal recipes remain separate. Manual setup remains **Geometry > Cyrus > Cyrus Scatter**, then Layer → Surfaces → Models → Amount → Update scatter.

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

## Historical 0.86.2 installer: Max version support

The **0.86.2 / schema 58** delivery included matched Max 2024, 2026 and 2027 MZPs and a universal EXE, with scoped runtime qualification, eight examples and three starter masks. Its [original delivery report](plans/preset-gallery-improvements/DELIVERY_0862.md) retains exact files, the same-version installer correction and limits. That historical release is not the current installation target.

## Installed files and recovery

Standard Max profiles install the immutable runtime under `%LOCALAPPDATA%/CyrusScatter/<year>/r/<content-id>`. An explicitly relocated profile uses `<profile>/cs/r/<content-id>`. The release contains the matching script, native modules, managed gallery and a small `LibraryBinding.txt`. Standard profiles resolve `%LOCALAPPDATA%/CyrusScatter/library-state.txt` to the selected shared library. Startup, macros, the install receipt and plugin registration remain in the selected Max profile and point to that complete release. Personal recipes in `Documents/CyrusScatter/Library` and activation are preserved. Older runtime/library paths remain recovery content. Analyzer uses its separate installer and directory. No compiler or SDK is required to use either built Scatter installer.

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

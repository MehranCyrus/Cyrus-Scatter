# Install and build Cyrus Scatter

Current [0.87.3 three-host EXE](plans/preset-gallery-improvements/INSTALLER_0873_COMPATIBILITY.md) packages Max 2024, 2026 and 2027 separately; native checks do not establish older-host runtime acceptance. Save work, close selected Max versions, run the EXE and reopen.

## Current 0.87.3 Library startup correction — Max 2027

Run [CyrusScatter-0.87.3-Max2027.mzp](../dist/CyrusScatter-0.87.3-20261026/CyrusScatter-0.87.3-Max2027.mzp) through **Scripting > Run Script**, follow the result and restart Max. Existing schema-61 scenes and plant content are retained. [Cause, tests and limits](plans/preset-gallery-improvements/LIBRARY_STARTUP_0873.md). This package updates Scatter for Max 2027 only; no artist installation or restart was performed.

## Preceding 0.87.2 Interactions correction — Max 2027

Run [CyrusScatter-0.87.2-Max2027.mzp](../dist/CyrusScatter-0.87.2-20261026-r2/CyrusScatter-0.87.2-Max2027.mzp) using **Scripting > Run Script**, follow the installer result, then restart Max before opening [the prepared trial copy](../dist/CyrusScatter-0.87.2-20261026-r2/Trials/Small_Test_Interaction_0.87.2.max). Save other work first. If an older installer helper is already loaded, restart before retrying. The package is Scatter-only; the existing library store, content and Analyzer remain independent. No artist installation or restart was performed. [Exact payload tests, units and limits](plans/scatter-interactions-garden-20261025/DELIVERY_0872.md). This successor uses schema 61; preserve original scenes. The first internal 0.87.2 package was withdrawn after a lazy-panel spinner error; only the **r2** path is delivered.

## 0.87.1 shared-library delivery — Max 2024, 2026 and 2027

Use the [three-host EXE](../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Setup.exe), or the matching [2024](../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Max2024.mzp), [2026](../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Max2026.mzp) or [2027 MZP](../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Max2027.mzp) through **Scripting > Run Script**. Save work and close target hosts for the EXE; restart the selected host after installation. A stale loaded installer helper may require restarting before retrying an MZP. The installer defaults to retaining the independent plant content; personal libraries and Analyzer remain independent. No artist profile was installed or restarted during qualification.

The [delivery report](plans/preset-gallery-improvements/DELIVERY_0871.md) and [qualification manifest](plans/preset-gallery-improvements/QUALIFICATION_0871.json) bind the exact SDK, scripts, archive hashes, owned installer transactions and automatic-startup tests. The shared-library workflows are tested on each host, with default OCIO selected explicitly in owned Max 2024 scenes. This does not extend unrelated Interactions, Paint or independent-product historical qualifications.

## Build-only 0.87.0 EXE — Max 2024, 2026 and 2027

[Download the installer](../dist/CyrusScatter-0.87.0-20261025-Compatibility/CyrusScatter-0.87.0-Setup.exe). Save work, close the target Max versions, run the EXE, select versions and choose **Install / Update**, then reopen Max. [Build scope and hashes](plans/scatter-interactions-garden-20261025/INSTALLER_0870_COMPATIBILITY.md): 2024/2026 are newly compiled and untested; the 2027 archive is unchanged from r4. No new tests, host launches or installation were performed, as requested. Existing library content and the independent Analyzer installation are retained. This build-only delivery does not expand the prior Max 2027 runtime qualification.

## Original Max 2027 r4 Interactions trial — 0.87.0

Use [CyrusScatter-0.87.0-Max2027.mzp](../dist/CyrusScatter-0.87.0-20261025-r4/CyrusScatter-0.87.0-Max2027.mzp) through **Scripting > Run Script**, follow the installer result and restart Max. The [delivery report](plans/scatter-interactions-garden-20261025/DELIVERY_0870.md) pins the matched payload, archive checks, extracted-payload host tests and remaining qualification. Save work first. A different already loaded installer helper may require a restart before retrying.

This is a Max 2027 Scatter-only trial with saved schema 60. It reuses your existing library and leaves the independent Analyzer installation in place. No new older-host package or combined EXE is included. No artist installation or restart was performed. Preserve original scenes and use the supplied trial copies. The compatibility routes below retain their historical versions and scope.

## Historical 0.86.9.2 compatibility delivery

The **0.86.9.2 / schema 59 delivery** contains distinct matched **Max 2024, 2026 and 2027** Scatter payloads and **Surface Analyzer 0.14.2** in one EXE. **This patch is runtime-tested only in Max 2027. Max 2024/2026 were built without running native tests or launching those hosts, as requested.** The [delivery report](plans/edit-instances/DELIVERY_08692.md) records density UI, native column lifecycle, physical Edit movement, persistence and exact payload checks. The [0.86.9 report](plans/edit-instances/DELIVERY_0869.md) retains its original three-host installer/startup qualification; it does not qualify new bytes. Original Paint and content revision 0.86.7 are preserved. Keep original scenes and save upgraded copies: source-aware Edit storage requires 0.86.9 or later.

The historical [0.86.8.6 combined delivery](plans/combined-installer/DELIVERY_08686.md) retains its matched Max 2024, 2026 and 2027 packages and Analyzer 0.14.1 qualification. Its files remain in `dist/CyrusScatter-0.86.8.6-20261023/`; earlier packages keep their original host scope.

## Historical combined installation route

The installer is [CyrusScatter-0.86.9.2-Setup.exe](../dist/CyrusScatter-0.86.9.2-20261023/CyrusScatter-0.86.9.2-Setup.exe).
Save work and close the target Max versions, select their cards, then click
**Install** or **Update**. Detection, validation and storage checks run
automatically. **Uninstall Scatter** keeps Analyzer, shared content and other hosts. Success shows
**Installation completed**. **Error details** is available only after a failure.

A profile without an installation receipt can migrate exact recognized startup/macro files from 0.81.6, 0.85.0, 0.86.8.2, 0.86.8.3 or 0.86.8.4. Original bytes are preserved under `scripts/CyrusScatter/Backups/v2/wrappers-<hash>/` before registration changes. Analyzer uses its independent `scripts/CyrusSurfaceAnalyzer/Backups/v2/` directory. Both use verified create-only backup publication: bytes are flushed and read back before the final backup becomes available. Interrupted temporary files do not prevent a retry; older differing final backups remain intact, with the verified replacement and migration record stored under v2.

A valid receipt continues to own its exact recorded files, including repair of missing owned payload files. Unknown/custom startup or macro files, receipts and plugin registrations block the update and are retained; **Error details** names the Max version and conflicting paths. A differing v2 final backup is also preserved and reported for review. Do not delete an unrecognized file just to bypass the check.

Leave **Install / update plant library** unchecked to update only the plugin
and reuse the registered library or recognized older runtime's library.
For new content, place **CyrusScatter-Content-0.86.7.zip** beside the EXE and
check that option. A missing or mismatched ZIP produces an error before install.
The installer streams verified files directly into one shared library; it does
not unpack an extra temporary library or create a copy for each Max version.
Identical installed content is reused. Content remains revision 0.86.7 because
the models, materials and previews have not been regenerated.

The combined EXE installs both products for each selected host. Reopen Max after installation. For hosted installation, use **Scripting > Run Script** with the matching Scatter and Analyzer MZPs, then restart that host. The [package folder](../dist/CyrusScatter-0.86.9.2-20261023/) contains all three builds, including [CyrusScatter-0.86.9.2-Max2027.mzp](../dist/CyrusScatter-0.86.9.2-20261023/CyrusScatter-0.86.9.2-Max2027.mzp) and [CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp](../dist/CyrusScatter-0.86.9.2-20261023/CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp). Separate MZP installation is not required when using the EXE. Both MZPs verify the installer helper before changing the profile. A different helper already loaded in Max requires a restart before retrying.
Analyzer's **Analyze / Update Analyzer** button recalculates guides rather than updating installed software.
The hosted route resolves an existing shared or legacy library. For a fresh
recipient, use the EXE with the content ZIP and its library checkbox.
There is no automatic online content download.

Standard Max 2024, 2026 and 2027 profiles share one selected library.
Content revision is independent of the plugin revision. Share the content
separately with recipients who do not have it; the EXE/MZPs contain the plugin.
Save your work and restart Max after installation. Old paths are retained
because saved scenes may still reference their textures.
Corona/Forest plug-ins matching the host are required by the supplied materials.

## Historical scene and installation evidence

The following records retain their separate original versions and host scopes.

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
Analyzer was not changed in that 0.86.6 delivery. `dist/` is ignored and is not supplied by a source-only
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

Standard Max profiles install the immutable runtime under `%LOCALAPPDATA%/CyrusScatter/<year>/r/<content-id>`. An explicitly relocated profile uses `<profile>/cs/r/<content-id>`. The release contains the matching script, native modules, managed gallery and a small `LibraryBinding.txt`. Standard profiles resolve `%LOCALAPPDATA%/CyrusScatter/library-state.txt` to the selected shared library. Startup, macros, the install receipt and plugin registration remain in the selected Max profile and point to that complete release. Personal recipes in `Documents/CyrusScatter/Library` and activation are preserved. Older runtime/library paths remain recovery content. Analyzer retains its independent receipt and runtime under `scripts/CyrusSurfaceAnalyzer/r/<runtime-id>/`. No compiler or SDK is required to use the built installers.

Each product uses the same transaction path through its EXE and MZP routes; Analyzer .14.2's standalone adapter now invokes the managed engine used by the combined EXE. Hash-verified staging, retained v2 backups and journal recovery protect the preceding bindings. A locked file, changed registration or differing verified backup can reject installation without replacing the conflicting bytes. Save your work and follow the reported recovery/restart guidance. Old release folders, imported texture storage and personal recipes are intentionally retained; unregistering is not a general disk cleanup.

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

The normal package workflow regenerates owned UI, checks version consistency, builds with the target SDK, runs native tests and produces versioned archives. For this explicitly requested 0.86.9.2 older-host build-only delivery, `offline_build.py --build-only` records `tests_run: false`; package admission accepts that explicit receipt without presenting it as qualification. This flag skips test execution even if the CMake graph compiles test targets. It does not make an old host qualification apply to newly changed source. SDKs are local build dependencies, not redistributed product files.

Version 2 producer receipts bind selected sources, effective build configuration, compiler/SDK/reference identities and nested Gallery/installer producers before and after their work. Changed or missing inputs leave pending/failed evidence and prevent package admission. Keep native `receipt.json`, managed/package `.build.json` sidecars and their original producer outputs together; original generated identity paths remain part of the recorded inputs. Historical receipts keep their original completeness limits and are not rewritten as v2 qualification.

The [0.86.9.2 report](plans/edit-instances/DELIVERY_08692.md) and [qualification manifest](plans/edit-instances/QUALIFICATION_08692.json) own current focused Max 2027 and package evidence. The [0.86.9 report](plans/edit-instances/DELIVERY_0869.md) retains its earlier three-host installation evidence. The [0.86.8.7 review/memory report](plans/code-quality/DELIVERY_08687.md), older boss handoff and historical smoke launchers retain their original builds and scope. The [0.86.0 Max 2027 native-foundation receipts](plans/native-placement/DELIVERY_0860.md) and older Max 2026 receipts remain historical. Physical-input, DPI and renderer claims retain their stated limits. Save upgraded Edit scenes as new copies; B37's clone-dependent full-object Copy limit remains open.

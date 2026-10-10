# Cyrus Scatter 1.x developer qualification

These tools build and qualify the main product in disposable Max profiles. They are privileged local fixtures, are not shipped in the MZP and must never run through the artist's live scene/session. The original foundation result is in [the v1 report](../../docs/Cyrus_Scatter_V1_2026-10-03/REPORT.md); current script/UI changes are in [the 1.0.1 follow-up](../../docs/Brush_Relax_Reset_2026-10-03/REPORT.md).

## Current 1.1 planting campaign

The [1.1 report](../../docs/Planting_Groups_2026-10-03/REPORT.md) is the current qualification. After generating/building below, launch a new private profile and run:

```powershell
python tools/v1/launch.py --run my-groups
python tools/v1/request.py --run my-groups --timeout 60 tools/v1/planting_qualification.ms
python tools/v1/request.py --run my-groups --timeout 45 tools/v1/navigation_fixture.ms
python tools/v1/launch.py --run my-groups-reopen --scene build/cyrus-v1/hosts/my-groups/groups-qualified.max --reopen-expected build/cyrus-v1/hosts/my-groups/groups-reopen-expected.ms
python tools/v1/request.py --run my-groups-reopen --timeout 45 tools/v1/planting_reopen_fixture.ms
```

`planting_qualification.ms` resets only the disposable scene, runs group, output/overlay and advanced Edit/curved fixtures, and saves exact reopen expectations. `planting_reopen_fixture.ms` loads its companion expectations itself. For a real 1.0.1 saved fixture, pass its `v1-qualified.max` and original `reopen-expected.ms` to a fresh launch, then use `planting_legacy_fixture.ms`. The historical `qualification.ms` includes pre-1.1 row/cache assumptions and is not the new-policy campaign.

Run `planting_demo.ms` for the four-group artist exercise; run `render_fixture.ms` against that clean demo. Open Coverage / Brush for Red flowers, record the demo's initial globals, use Start Brush, drag a new patch, right-click, then `planting_gesture_fixture.ms`. It checks the real gesture, actual overlay submissions and Manual publication before issuing Update. It cannot substitute for inspecting the visible tint. A sphere and exact Edit cases are supplied by the advanced fixture.

Package and install through the same private MZP workflow below, restart with `--installed-from`, verify loaded identity and repeat qualification against the installed bytes. `planting_release_fixture.ms` chains identity, fresh reopen, group qualification, native UI, navigation, the clean demo and Scanline render; allow up to 120 seconds while the asynchronous request runs, and inspect its result before another request. Copy only the clean demo into `dist/v1/`; do not ship the qualification scene or private transport. `collect_planting_evidence.py` curates this campaign separately from the frozen 1.0 evidence.

## Build and package

The installed toolchain is MSVC 14.38.33130 / Windows SDK 10.0.19041.0. `build.py` expects the matching Autodesk SDK under ignored `build/tooling/max<year>-sdk/Program Files/Autodesk/3ds Max <year> SDK/maxsdk`.

From the repository root:

```powershell
Push-Location AminScatter
node tools/ui/generate.cjs
Pop-Location
python tools/v1/build.py --year 2027
python tools/v1/build.py --year 2026
python tools/v1/package.py
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
```

The ordinary `tools/build_max.py --max-year ... --sdk-root ...` also builds/tests/packages Scatter and the unchanged Analyzer. The Scatter package version comes from the generated script's `uiVersion`; packaging rejects a conflicting version. `package.py` packages already built native files; it does not compile or install them. Confirm source/build identity before using it. Native files, logs, packages and private scenes remain under ignored `build/` and `dist/`.

## Private Max 2027 campaign

Choose unused run names. `launch.py` redirects scripts, macros, startup, native configuration, temporary files and Autoback into that run directory. Wait for `transport-ready.txt`. The transport accepts a copied recipe inside that directory; this capability is intentionally absent from the product.

```powershell
python tools/v1/launch.py --run my-v1
python tools/v1/request.py --run my-v1 --timeout 45 tools/v1/qualification.ms
python tools/v1/request.py --run my-v1 --timeout 45 tools/v1/navigation_fixture.ms
```

`qualification.ms` serially checks editor binding, Brush, caching/copy, curved geometry/Edit and output/save preparation. `navigation_fixture.ms` checks 20,000 retained Mesh instances and work counters; its synchronous camera/redraw steps are not FPS. If the client times out, inspect `response.txt` before another request. A `RUNNING` recipe must finish or be investigated; do not overwrite it with a second request.

Saved-scene qualification uses a fresh process and the explicit companion expectation file:

```powershell
python tools/v1/launch.py --run my-reopen --scene build/cyrus-v1/hosts/my-v1/v1-qualified.max --reopen-expected build/cyrus-v1/hosts/my-v1/reopen-expected.ms
python tools/v1/request.py --run my-reopen --timeout 45 tools/v1/reopen_fixture.ms
```

For the original artist file, use a different private run with `--with-analyzer --scene 'Test Scene/SaveSelect 2.max'`, then `legacy_fixture.ms`. This dependency loads the unchanged local Analyzer 0.14 build. The fixture performs no save to that file. Native 2026 builds do not provide a 2026 interactive host test.

## Actual installation and startup

`installer_fixture.ms` runs the actual MZP in the redirected private directories. Close only its verified success message. `verify_install.py` checks the installed bytes against the current package, not merely file existence.

```powershell
python tools/v1/request.py --run my-v1 --timeout 45 tools/v1/installer_fixture.ms
python tools/v1/verify_install.py build/cyrus-v1/hosts/my-v1
python tools/v1/launch.py --run my-installed --installed-from build/cyrus-v1/hosts/my-v1
python tools/v1/request.py --run my-installed --timeout 45 tools/v1/identity_fixture.ms
python tools/v1/verify_install.py build/cyrus-v1/hosts/my-v1 --loaded-profile build/cyrus-v1/hosts/my-installed
```

The restarted profile copies the actual installed files and uses their real Cyrus startup registration; it does not load the project script as a fallback. The identity fixture records all four loaded module paths. Repeat the product campaign against this profile after final changes.

For 1.0.1, run `brush_relax_reset_fixture.ms` for Brush compatibility and group Reset/Undo/Redo assertions. `random_reset_ui_fixture.ms` prepares known values; arm, actually click, then verify each group using the helpers documented in [the patch report](../../docs/Brush_Relax_Reset_2026-10-03/REPORT.md). Save with `brush_relax_save_fixture.ms`; launch a fresh installed profile with its private `.max` and `patch-reopen-expected.ms`, then run `brush_relax_reopen_fixture.ms`. `collect_patch_evidence.py` curates this campaign separately and checks both installers' payloads against the unchanged native baseline.

After qualification, `uninstall_fixture.ms` checks that only the owned registrations/startup are removed and that unrelated registration and scene controllers survive. It stops product callbacks in that process. Reinstall and restart into another private profile before using the product again; do not treat a hot-loaded, uninstalled process as the final demo.

`demo.ms` creates a self-contained plane/cone/shrub scene and saves it inside the private run. It records the published count/history baseline before any UI painting. `render_fixture.ms` checks a real 128 × 128 Scanline render and hidden-layer final membership. `ui_gesture_fixture.ms` and `ui_update_fixture.ms` are assertions after the documented actual mouse interaction; they do not manufacture it. They expect the demo's initial three dabs, one new connected Paint stroke, right-click exit and the native Update button. `status_verify.ms` checks the subsequent native session-exit label update. The copy fixture compares transforms, sources and IDs at fractional mask density, independently of new ownership GUIDs.

`group_mask_diagnostic.ms` characterizes installed 1.0.1 after artist feedback. It reproduces independent coverage dots, Mesh/Point Cloud/centre counts, display caps, Manual publication, four independent groups sharing a surface, pre-mask spacing, removed/mutual blockers and blockers ignoring CS Edit moves. It intentionally asserts the current limitations; it is not acceptance of the proposed replacement solver. Run it only in a disposable profile after `identity_fixture.ms`. The [diagnosis and evidence](../../docs/Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_REVIEW.md) and [next plan](../../docs/Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_IMPLEMENTATION.md) explain its scope.

## Evidence, MCP and cleanup

For **1.2.1 full-width layers**, see the [patch report](../../docs/Layer_Width_2026-10-04/README.md). `layers_width_probe.ms` and `layers_width_acceptance.ms` require a disposable `layers-width*` profile with the existing 1.2 demo loaded. They inspect native bounds, retained controls and passive generation/display counters. `collect_width_evidence.py` curates the separate patch evidence and checks package native bytes against frozen 1.2.0. `package.py` now defaults to the generated version's folder so a patch cannot overwrite the old handoff by default.

For **1.2 layers-first**, use `layers_release_fixture.ms` in a fresh installed private profile. Reopen `layers-qualified.max` with `layers-reopen-expected.ms` and run `layers_reopen_fixture.ms`. `layers_features_fixture.ms` covers inherited areas, independent erase, compatibility guards and Manual/live. `layers_ui_prepare.ms` and `layers_ui_verify.ms` bracket actual native expansion/count input; `layers_gesture_prepare.ms` and `layers_gesture_verify.ms` bracket a real Blue-set drag and right-click. `layers_set_picker_verify.ms` checks a real Blue selection. `layers_legacy_fixture.ms` compares the frozen 1.0.1 scene. `collect_layers_evidence.py` curates this campaign separately and verifies current package/runtime identities. See the [1.2 report](../../docs/Layers_First_2026-10-03/REPORT.md). Do not run old singleton-UI fixtures against the new per-layer host without adapting their UI references.

`collect_evidence.py` belongs to the frozen 1.0.0 campaign at commit `c78c349`: it curates selected results, suite logs and package manifests into the v1 docs. Do not run it against a subsequent patch or overwrite dated evidence. Patch campaigns have separate report/evidence directories. Collect only public assertions and hashes, never connection secrets, private journals, scene files, installers or binaries. A collector result is provenance, not a substitute for the assertions above.

`tools/mcp/launch.py` defaults to the v1 SDK build. Campaigns remain serial per host and use a private connection. `--host-package <installed-host>` imports the installed Python package without claiming the artist's default connection. `layers_release_campaign.py` runs the 1.1 automation matrix, including plan 2.0 and effective ownership inspection; see [CyrusMCP](../../CyrusMCP/README.md).

Close only processes whose recorded `launch.json` PID and actual command line identify this exact private run; check this before stopping them. Do not terminate a Max instance based only on its executable name or window title. Retain failing raw output locally until investigated. The historical `tools/brush_lab` requires its matching pre-0.78 stroke API checkout; current vector qualification is in [tools/vector_brush_078](../vector_brush_078/README.md).

For **1.2.2 classic layout**, see [the current layout report](../../docs/Classic_Layout_2026-10-04/README.md). Use a private `classic-layout*` profile and the frozen layers demo. `classic_layout_prepare.ms` selects it; `classic_layout_acceptance.ms` checks all root/feature toggles, native bounds and cache/handle retention. `classic_layout_flow.ms` samples native displacement on later timer ticks, since Max/Qt HWND positions settle after the script event. Wait for `classic-native-flow.json` before any other recipe. `classic_manager_acceptance.ms` tests selection, Add/Remove, open-state restoration and root/leaf binding. The existing `layers_first_qualification.ms` and `layers_features_fixture.ms` exercise the unchanged planting model. `package.py` defaults to `dist/classic-layout-<version>`; older handoffs are not overwritten.

For **1.2.3 native scrolling**, see [the scrolling patch report](../../docs/Classic_Layout_2026-10-04/SCROLLING_1.2.3.md). `scrolling_prepare.ms` requires a private `classic-layout-scroll-*` profile, the frozen layers demo, and the new native build. Use actual mouse-wheel/left-drag input, then call `CSScrollCheck` with the expected movement direction. It verifies outer movement while retaining authoring, generation, Brush, HWND and display-upload state. Recheck after `classic_manager_acceptance.ms` recreates the UI; reassign `CFNode=LFRoot` and `CFRoot=LFRoot.baseObject`, open a long editor, and call `CSScrollArm()` before the gesture. Do not install a prototype DLL in the release test process.

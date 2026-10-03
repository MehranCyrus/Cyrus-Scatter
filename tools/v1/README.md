# Cyrus Scatter 1.0 developer qualification

These tools build and qualify the main product in disposable Max profiles. They are privileged local fixtures, are not shipped in the MZP and must never run through the artist's live scene/session. The original foundation result is in [the v1 report](../../docs/Cyrus_Scatter_V1_2026-10-03/REPORT.md); current script/UI changes are in [the 1.0.1 follow-up](../../docs/Brush_Relax_Reset_2026-10-03/REPORT.md).

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

## Evidence, MCP and cleanup

`collect_evidence.py` belongs to the frozen 1.0.0 campaign at commit `c78c349`: it curates selected results, suite logs and package manifests into the v1 docs. Do not run it against a subsequent patch or overwrite dated evidence. Patch campaigns have separate report/evidence directories. Collect only public assertions and hashes, never connection secrets, private journals, scene files, installers or binaries. A collector result is provenance, not a substitute for the assertions above.

`tools/mcp/launch.py` now defaults to the v1 SDK build. The existing MCP campaign tools remain serial and use their own private connection directory. Their authorization/schema scope is unchanged; see [CyrusMCP](../../CyrusMCP/README.md).

Close only processes whose recorded `launch.json` PID and actual command line identify this exact private run; check this before stopping them. Do not terminate a Max instance based only on its executable name or window title. Retain failing raw output locally until investigated. The historical `tools/brush_lab` remains a separate diagnostic harness using the current public native API; its old dated evidence is unchanged.

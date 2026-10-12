# 0.79.5 creation-icon correction

11 October 2026. Follow-up to the artist report that placing/sizing Scatter looks frozen and another click produces two controllers. This is a focused correction to the original [garden delivery](README.md), with the same version, native modules, schema 55 and licensing behavior.

## Reproduced cause and correction

The new controller existed and `iconSize` changed during the real SDK creation callback. However, after the empty scene had published its display records, the new controller was absent from `CyrusViewportRecords`; that list remained empty and its dirty flag stayed false through all ten sizing moves. The old draw callback drew controller icons only while traversing that placement/display list. A zero-area picking mesh does not provide the visible red icon. This explains the missing visual feedback; it was not a placement calculation freeze in the isolated witness.

The authoritative `unified-core.ms` now draws controller icons from the existing registered Scatter nodes, independently of placement records. This also works while mouse-held interaction defers publication. Cached numeric icon paths still update by `iconSize`; existing plant preparation/uploads are unchanged. Undo/Redo rebuilds node registration so a deleted, pruned controller regains its icon when restored. The generated script was regenerated. No native calculation or UI ownership changes were made.

Max's repeated creation behavior remains: first click places, movement sizes, second click finishes; another placement click begins another object. Right-click exits. The callback test confirms one completed object after two clicks and removes only the unfinished second object on abort. It does not demonstrate a duplicate creation inside one two-click sequence.

Autodesk documents automatic invocation of a scripted plugin's creation tool and node attachment during creation in its [scripted-plugin clauses](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.html). The defect diagnosis above comes from Cyrus source and owned-host observations, not from an assumption about another scatter product.

## Qualification

Both Max 2026 and Max 2027 use isolated profiles with the tested script and unchanged, matching 0.79.5 native modules. The [compact evidence](creation-evidence.json) pins inputs, raw receipt locations, assertions, measurements and package identities.

| Witness | Checks per year | Result |
| --- | ---: | --- |
| Real SDK Create command and two-click sizing callbacks | 1 | One completed controller; ten size updates recorded |
| Draw submission and lifecycle | 17 | Old body submits no new icon; corrected body submits its three polylines at three sizes, including held interaction; hide/show, delete, Undo/Redo and reopen pass |
| Creation beside a populated setup | 7 | Placement/cache/upload counters unchanged; repeated creation and abort preserve the finished objects |
| Generated controls/workflow | 11 | Layer, receiver, Point/model replacement, second layer/removal, Include/Exclude, falloff, painting and browsing witness passes |
| Existing point-example navigation | 24 | Unchanged placement/preparation/upload counters across scripted navigation |
| **Total** | **60** | **120 focused host assertions across both years** |

The draw trace runs a copy of each frozen script's draw function with only its polyline sink instrumented and its held-state input fixed. It calls the real GraphicsWindow polyline operation and captures the submitted ring coordinate. The unmodified product draw callback is also invoked. This qualifies submitted geometry and callback logic, **not presented pixels, physical mouse interaction or perceived latency**. The private SDK helper directly calls the active Create command's MouseCallBack; it does not send OS input and is excluded from installers.

Generation/integration and approved-layout checks pass. C++ is unchanged, so the previously tested native modules were reused rather than rebuilt. The earlier full garden/render campaign remains evidence for its original script; it was not rerun or relabeled as qualification of this correction.

**Remaining B21:** entering Create still took about 1.99 s in Max 2026 and 2.36 s in Max 2027 before the deferred panel-message step. This correction does not claim to accelerate settings-panel construction. Physical artist creation/sizing acceptance and that separate UI optimization remain outstanding. Scripted navigation timings are retained in the evidence and are not presented FPS.

One attempted parallel private-host launch exited before bootstrap readiness, without a product exception receipt. It was not counted as a pass; the subsequent isolated launch completed the campaign. An initial trace attempted to replace a read-only plugin method and was corrected to instrument a copy of the frozen draw body; no product workaround was added for that fixture error.

## Corrected installers

Use these packages instead of the earlier `dist/refinement-0.79.5/` pair:

- [Max 2027 corrected installer](../../dist/refinement-0.79.5-creation/CyrusScatter-0.79.5-Max2027.mzp) — [receipt](creation-package-2027.json)
- [Max 2026 corrected installer](../../dist/refinement-0.79.5-creation/CyrusScatter-0.79.5-Max2026.mzp) — [receipt](creation-package-2026.json)

Corrected script SHA-256: `cacf3e6b1af8796d96bca7ed2698cfb762d3baff7f90bc35a507b100ee0af4b4`.
Original script SHA-256: `47ed50ed18aab79da76f511cc74b95a81f1d518fa9fd02b2fa647ec5eba3a100`.

Run the installer for your Max year through Scripting > Run Script, then restart Max. Installation into the artist profile and physical interaction were not performed by this campaign. Existing scenes, the artist Max process, unrelated working changes and website work were preserved; no Git commit/push was made. Original packages and receipts remain unchanged.

## Reproduction and handoff

Harnesses are under `tools/refine0795/`: `build_create_probe.py`, `create_callbacks.py`, `create_visibility.py`, `create_existing.py`, `workflow.py`, `navigation.py`, `package.py --creation-fix`, and `summarize_creation.py`. Use `launch.py` and `request.py` only with a fresh owned profile; never send the reset/load fixtures to an artist host. The visibility comparison needs the preserved baseline script from the original 0.79.5 package/profile.

Final profiles are `build/mcp-qualification/refine0795-create-fixed-2026-01` and `...2027-02`. Native candidates remain `build/refine0795-20261011/max2026-02` and `max2027-02`. The baseline creation witness is in `...refine0795-create-baseline-2027-01`. Build/profile/installer files are ignored local artifacts and are not included in a source-only Git clone. Use the hash-pinned evidence when reproducing them.

Next acceptance: install the corrected year-specific package, verify that the red icon appears on the first placement click and tracks sizing without an extra click, then right-click after finishing. If a real freeze persists, capture that exact scene and loaded identity; the separately measured settings-panel mount cost is still open.

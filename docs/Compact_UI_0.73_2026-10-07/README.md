# Cyrus Scatter 0.73 — compact native UI

7 October 2026. This continuation reduces empty space in the approved workflow after the artist compared it with Chaos Scatter. Version stays **0.73.0**, serialization **54**, calculation model **CyrusUnified1**. The final generated script SHA-256 is **`53bf85f9a2cfe1034468919c408d4c73ca6e865f7e1b9c816cc7375fe12f10fa`**; its loaded payload fingerprint is **`d74672d06df57514d70accd5632bfa187a1546633e6327d6b8360905e202ea94`**. The version caption alone cannot distinguish this UI from previous 0.73 packages.

The ten-section order and folded Advanced options remain. Related layer/container buttons share rows; Enabled/Visible controls sit together; numeric captions sit beside their fields when space permits. Min/max scale fields stay beneath their headers. Buttons use 22-pixel heights and small row gaps. Lists retain their native visible-row counts. Help and feedback wrap to their content instead of reserving large fixed areas. Source-container properties use the same compact spacing.

## What the tests caught

Max's checkbox and pick-button controls do not expose a writable `width` property. Their creation width could describe the wider panel before Max allocated individual columns: a measured Replace Point button was **416 pixels wide in a 162-pixel rollout**, clipping its caption. The final layout sizes these single-window controls through the documented Max SDK window API. Spinners keep their fixed native fields and position their arrows; the layout never assigns an unsupported spinner width.

The popup also lost ten pixels of usable width when a scrollbar appeared after layout. Its controls could retain the previous width and extend into the edge. Rollouts now reflow on actual width changes, with a cached width preventing height changes from recursively triggering layout. This adds no polling timer. Text feedback reflows on its existing refresh events.

The authoritative edits are in [the composer](../../AminScatter/tools/ui/approved-layout.cjs), [row definitions](../../AminScatter/tools/ui/approved-layout-rows.cjs), [header template](../../AminScatter/tools/ui/templates/approved-main-ui.ms) and [container-properties template](../../AminScatter/tools/ui/templates/container-properties-ui.ms). The generated script and existing generator assertion were updated. The installer's guidance now names the current sections. [The new Max regression](../../tools/procedural_lab/Max_Compact_Layout_073.ms) measures real widget rectangles, overlaps and min/max alignment through narrow/wide popup cycles.

## Verification and scope

| Evidence | Result and boundary |
| --- | --- |
| Generator checks | Passed; all 240 semantic controls remain mapped; 21 fixture delimiters checked. These are offline checks, not a Max compilation certificate. |
| Native inputs/binaries | Every non-script input and binary matches the earlier frozen builds; 14 native tests passed for each SDK year. These are verified reused binaries, not newly compiled native engines. |
| Max 2027 integrated campaign | Eight core probes passed: ordered pipeline/Brush, containers, source/group movement, native/popup ownership and Advanced lifecycle, persistence and Analyzer assignment. |
| Measured widget campaign | Passed: 20 native basic/Advanced snapshots and 64 popup snapshots at 720, 920 and 1280 pixels, including scrollbar width changes. Native checkbox/picker bounds do not exceed their columns or overlap each other. UI browsing does not build candidates or publish placements. |
| Live/Manual idle campaign | All eight cases passed, including open editors/sections, pending Manual edits, real Live edits, density-map edits, failed successor, restored recipe and diagnostic recording. Work counters, retained identities and timer inactivity are checked; draw callbacks are recorded separately. |
| Actual private garden | Final script/native pair loaded in an isolated Max 2027 profile. Native columns, Advanced scrolling, transform fields, popup and source-container properties were checked. The separately recorded browsing samples verify actual work/cache identities. |
| Source scope | Removing the 33 rollout bodies and generated payload fingerprint leaves byte-identical source outside presentation. This does not certify handlers inside rollouts; the integration tests exercise those. Native calculation, Brush, retained display, MCP and licensing source were not changed in this continuation. |

The strict first comparison of active browsing also counted host notifications: it recorded 12 callbacks, 16 group-cache hits, two redraw requests and two deferred IR checks over 428 seconds. Its original failing counter receipt is preserved. These did not query a render key, build a render bridge, regenerate candidates, rescan containers, publish placements or upload new buffers. The browsing acceptance receipt reports these events separately instead of calling them zero processing. A subsequent **98-second settled interval**, with the container view open in Live mode, changed no sampled counter or identity and left all five plugin timers inactive. Max's own CPU use is not inferred from these plugin counters.

Receipts and exact source identities are allowlisted under [evidence](evidence/index.json). Intermediate failing UI candidates are not used as passing receipts. Full logs, DLLs and disposable scene/profile data remain in the ignored test workspace. No artist scene or normal installed product was modified, and no commit/push was performed.

This is UI qualification at the current desktop scale. Other DPI/font combinations, long sessions, all feature combinations and Max 2026 runtime remain broader gates. The [earlier qualification](../Full_Qualification_0.73_2026-10-07/README.md) remains the source for retained Mesh/Point Cloud, 100k navigation/playback and actual Corona measurements on its frozen pair; those measurements were not rerun or relabelled here. The existing first cold container Undo history finding, very large Proxy cost and original missing material maps remain open. No presented-FPS improvement is claimed from tighter layout.

## Delivery

[Max 2027 compact UI installer](../../dist/Compact_UI_0.73_2026-10-07/Max2027/CyrusScatter-0.73.0-Max2027.mzp), [installation notes](../../dist/Compact_UI_0.73_2026-10-07/Max2027/START_HERE.txt), [exact package identities](../../dist/Compact_UI_0.73_2026-10-07/BUILD.json). Run the MZP through **Scripting > Run Script**, then **restart Max**. The Analyzer 0.14 package is unchanged. Max 2026 packages are labelled SDK-only and have no runtime UI qualification. Earlier packages remain historical artifacts.

The existing [garden and stress scenes](../Full_Qualification_0.73_2026-10-07/ARTIST_GUIDE.md) remain at their original paths; this continuation does not overwrite them. Next acceptance work is artist feedback on density, wider DPI coverage and the existing [prioritized correctness/performance findings](../Full_Qualification_0.73_2026-10-07/ROADMAP.md).

API contracts used: Autodesk's [common layout parameters](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/GUID-EA37E7DB-1E74-4377-B3D8-EDAE19CE27E7.html), [native window methods](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/Interaction-With-The-Operating/GUID-282F32AC-5A80-4FDB-B8C0-275D2CC15845.html) and [rollout resize events](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html). Source facts, measured widget results and earlier performance evidence are kept distinct.

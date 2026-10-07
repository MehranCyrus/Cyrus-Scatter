# UI performance focus and next implementation loop

**Later implementation:** [0.72 results](../Integrated_UI_0.72_2026-10-06/RESULTS.md) implement the integrated selected-layer view, warm popup retarget correction and direct Scatter recorder. Native category/visibility and zero-work invariants have private API evidence; pointer/DPI and presented-FPS qualification remain separate. The requirements and source findings below preserve this earlier planning snapshot.

6 October 2026. This records the user's current direction and the source inspection after the 0.7.1 runtime/package campaign. It is a planning checkpoint; the integrated replacement UI and direct Scatter recording controls are not implemented by this document.

## Product direction

**Later coding slice:** [Playback and idle-work results](../Playback_Performance_2026-10-06/README.md) correct blanket time invalidation, recurring Analyzer polling and Point Cloud matching. They also guard current layer/set/topic selections and retain unchanged dropdown contents in the existing editor. The integrated column replacement and direct recording controls remain pending; headless script execution does not qualify visual layout or latency.

- Keep the primary workflow integrated with 3ds Max. The user has tried the floating layer editor and now prefers an integrated interface without a mandatory popup.
- Keep Edit Layer available as an optional popup over the same stored settings. Opening another view must not create a second evaluator or a recurring refresh loop.
- Present one ordered layer list and one settings view for the selected layer. Global settings remain separate from layer and paint-set settings.
- Retain controls and list contents where possible. Refresh the affected fields when their actual data changes; opening a dropdown, expanding a section or scrolling unchanged controls should not regenerate placements or re-upload unchanged buffers.
- Put Start recording, Stop and Save report controls in Scatter's global Help / Diagnostics area. The current recorder is native and process-wide; its current friendly controls live in the separate Cyrus MCP Automation panel. Ordinary debugging should be accessible without that companion installation or an assistant connection.
- Evaluate a native SDK/Qt implementation against measured UI costs. The `.dlo` extension, a particular folder, and floating versus integrated placement do not themselves establish responsiveness. Preserve scene class IDs, saved data, artist edits and the retained display engine.

## What source inspection establishes

| Observation | Source | Evidence boundary |
| --- | --- | --- |
| `bindEditors()` reconstructs layer/set list contents and binds all active-topic sections. | [layer-editor.ms](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/layer-editor.ms), function `bindEditors` | Real UI work; no timing or direct attribution to the reported delay yet. |
| `showTopic()` calls that binding path on topic changes; sections are created only on first use while the editor remains open. | Same file, `showTopic` | Controls are partly retained, but broad rebinding remains. |
| Paint-set selection invokes broad binding; choosing the same selection is not explicitly excluded by `selectSet`. | Same file, `selectSet` | Identify which set-specific fields actually changed before choosing a narrower update. |
| Closing destroys the dialog and drops its sections; reopening constructs them again. | Same file, `CyrusCloseLayerEditor` and editor close/open handlers | Retention lasts for the open dialog, not across destruction. |
| The inspected dropdown handlers respond to item selection. | Same file, layer/set selection handlers | Mere opening without selection has not been reproduced as a binding trigger. Trace this separately from selecting an item. |

The user's observed lag is a report, not a measured diagnosis. TyFlow's internal UI implementation is not established from its panel appearance. Prior idle and navigation checks establish their recorded calculation/upload invariants; they do not qualify every UI action's latency.

## Ordered tasks and acceptance

1. **Pin and measure the current UI.** Use a matching script/native pair in a disposable Max 2027 profile. Record first and repeated opening, dropdown open/cancel, same-item selection, different-item selection, topic changes, layer changes, expansion, scrolling and resizing. Compare one-layer and several-layer scenes. Record UI creation/binding/layout counts and elapsed times alongside preparation, publication, preview, render-bridge and upload counters. State measurement boundaries and distinguish cold from warm operations.
2. **Expose recording inside Scatter.** Provide clear recording status, limits and process-wide scope; reuse the existing bounded recorder and local JSON export. Starting, stopping and exporting require no MCP connection. Test cancel, unwritable/disk-full export, closing the view, selection changes, reset/open and multiple controllers. Recording and inspections must not drive evaluation or recurring idle polling.
3. **Build the integrated selected-layer view.** Select its SDK/Qt host integration after the measurement and a bounded layout prototype. Retain unchanged lists/controls, suppress writeback while displaying values, and update affected fields from parameter, source, Undo/Redo and publication changes. Keep all feature families reachable and preserve ownership, Manual/Live behavior, stable IDs and persistence. Add no general framework unless the measured requirements justify it.
4. **Resolve the reported Corona stop failure.** The user supplied an installed-script callback exception, `Corona IR stop failed: 2`, reported at line 4879. Verify that session's source/binary identities before reproducing. Its cause remains unisolated. Test ordinary stop, repeated stop, close IR, floating/docked modes, production rendering, edits during IR and error recovery; retain useful failure context without swallowing unexpected errors or retrying indefinitely.
5. **Resolve Brush BR-01.** Preserve authored documents and genuine topology protection while qualifying signed-zero/subnormal versus ordinary-coordinate save/reopen identity behavior.
6. **Repeat affected regressions and deliver a matching candidate.** Verify browsing and settled idle perform no placement preparation/publication, bridge rebuild or unchanged-buffer upload. Preserve retained Mesh/Point Cloud behavior; qualify layout, scrolling, automatic spacing, Brush/Edit, containers, Undo/Redo and reopen on the exact packaged pair. Broader host/DPI/renderer qualification remains explicit work.

## Existing results and later work

The [runtime campaign](../Live_Runtime_2026-10-06/README.md) and [package evidence](../Live_Runtime_2026-10-06/PACKAGE.md) remain the evidence for the tested 0.7.1 candidate. The new Corona report is not resolved by those earlier passing cases.

Expanded MCP policy-3 authoring, searchable diagnostic history, render-job qualification and artistic learning follow the [remaining-work gates](../Live_Runtime_2026-10-06/NEXT_WORK.md). Commercial licensing retains its separate [roadmap](../licensing/ROADMAP.md). Version 0.7.1 remains a development label; 1.0 is reserved for publication readiness.

## Backup checks on 6 October

- Fresh generator/integration check passed with 241 inventoried controls and generated script SHA-256 `c3f0b693a3854e9d11077bdea739469290e9a8a6e45f82ba44f38c6a1b486c8f`.
- Fresh Python/MCP suite: 123 tests passed in 11.33 seconds.
- All 53 indexed runtime/package evidence files matched their stored sizes and hashes. Git attributes preserve the dated receipts' original bytes.
- The working diff whitespace check passed. These backup checks do not constitute a new interactive Max campaign or a fix for the newly reported UI/Corona behavior.

## Primary references checked during this discussion

- [Autodesk plugin extensions](https://help.autodesk.com/cloudhelp/2022/ENU/Max-Developer-Help/writing_plug-ins/creating_a_plug-in_project/manually_creating_a_new_plug-in_/plug-in_file_extensions.html): DLL classification, not a responsiveness benchmark.
- [Autodesk dropdown events](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/Rollout-User-Interface-Controls-3/GUID-172DE6D6-796F-419B-936E-4FD64AD24CB9.html): `selected` is documented for selecting an item.
- [Autodesk Qt integration](https://help.autodesk.com/cloudhelp/2023/ENU/Max-Developer-Help/writing_plug-ins/using_qt_with_3ds_max_plug-ins.html) and [docking guidance](https://blog.autodesk.io/saving-qwidget-docking-states-per-3ds-max-scene/): supported UI integration options; use the exact target SDK before implementation.
- [TyFlow installation](https://docs.tyflow.com/download/installation/), [performance](https://docs.tyflow.com/faq/performance/) and [cache](https://docs.tyflow.com/tyflow_objects/tyFlow/cache/): published delivery, computation and playback information; no measured explanation of this UI comparison.

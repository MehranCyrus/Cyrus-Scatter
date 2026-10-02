# Cyrus Scatter: UI rollback and focused diagnosis

Historical rollback checkpoint: 2026-10-02. Product **0.64**, native library **0.25**, UI **2026-10-02.4**.
**Revision 3 is withdrawn. Visible flicker is not claimed fixed.**

**Current follow-up:** [UI 2026-10-02.5 fixes the main rollout's narrow-until-hover repaint defect](UI_Architecture_Investigation_2026-10-02/MAIN_ROLLOUT_REPAINT.md). It is staged in the local Max 2027 profile for the next restart. First-time layer construction remains a separate issue; the sections below describe revision 4, not current installation status.

**Follow-up:** the [comparative UI investigation](UI_Architecture_Investigation_2026-10-02/README.md) now records private interactive measurements, the mounted diagnostic's warmed path, a verified width reset/repair sequence, and reusable-editor/Qt prototypes. It adds no production UI changes. The verification section below records the earlier rollback checkpoint, not the full later investigation.

## Reduction

Removed revision 3's section placeholders, replacement queue, cancellation state and extra generator stage, together with its dedicated tests and unfinished lifecycle recipe. The experiment is preserved locally in `_local/maintenance/ui-layer-r3-2026-10-02/withdrawn-r3/`.

The generated script is back from **12,969 to 12,319 lines**: 650 lines removed. Compared with the preserved revision 2 baseline, four source lines differ:

- Disable automatic scrolling inside the host subrollout.
- Disable automatic scrolling inside each layer subrollout.
- Remove Collision / Relax's unconditional hide-then-show cycle.
- Update the UI revision tag.

Max's outer command panel still scrolls. No new loading system, framework or product timer remains. Revision 2's selection, cached statistics and first-expansion correctness repairs remain. Native files and renderer script tail are checked against retained-Mesh 0.64.

Removing section-level deferred loading also removes its timing benefit. The earlier roughly 650-to-120 ms observation applies only to withdrawn revision 3. It measured synchronous opening work and never established flicker-free display.

## Boolean comparison and verified suspects

The user's Boolean modifier is a useful reference for expected responsiveness. Its internal implementation cannot be inferred from the screenshot. Our source does show extra work beyond displaying controls:

- `templates/containers.ms`: settings sit inside a layer subrollout, inside the host subrollout. First layer opening constructs six settings sections.
- `templates/host.ms`, `layoutPanels`: computes heights across layers and roots, assigns changed sizes and calls `fitWidth`.
- The existing 300 ms timer checks width. A change can invoke `rebuildWidth`, removing and recreating panels. Statistics refresh shares this timer, throttled to 500 ms while the manager is open.

These are verified code paths, not proof of which causes the user's flash. Do not blame polygon count or assume all MAXScript interfaces are slow.

## One-shot diagnostic outside the installed plugin

Select Cyrus Scatter in Modify, open its main panel, and run [diagnose-selected.ms](../tools/ui-tests/diagnose-selected.ms) through **Scripting > Run Script**. The report path appears in the MAXScript Listener (F11). It supports revision 2 or 4.

It records loaded UI revision, whether controls already existed, section mounting times, two opening times, ten unchanged layout calls, statistics time, root-handle replacement, and preview build/dirty changes. It restores the mount function and layer open/scroll state. Constructed controls stay constructed: repeated reports are warm measurements. It installs nothing, adds no persistent callbacks, does not explicitly rebuild scatter, and does not save the scene. Incidental existing redraw behavior is why build/dirty state is checked rather than assumed unchanged. Timings do not measure physical click-to-present latency or fleeting paint events.

Use a scene copy in Manual mode with a completed preview. For a separate visual A/B test, keep panel width fixed. With Cyrus selected, run:

```maxscript
global CyrusUITestUI = $.baseObject.mainUI
global CyrusUITestTimer = CyrusUITestUI.widthTimer.active
CyrusUITestUI.widthTimer.active = false
```

Open/close the same warmed section, then restore immediately:

```maxscript
CyrusUITestUI.widthTimer.active = CyrusUITestTimer
```

This temporarily disables only the host UI's width/statistics timer. Do not resize the panel during the comparison. If flashing disappears, isolate width reconstruction and statistics separately next. If it remains, focus on expansion/layout and native repaint. At this rollback checkpoint, a reusable selected-layer editor was proposed as a simpler experiment than another deferred-loading layer. Its subsequent private timing and binding tests are in the follow-up linked above; production integration and artist workflow review remain pending.

## Verification at the rollback checkpoint

Passed: repeat generation produces identical bytes; the handwritten product change is exactly four substituted lines against revision 2; native files and renderer script tail match 0.64. Max 2027.1 batch exited successfully after loading the script, checking the UI tag, creating one layer and all ten unmounted layer factories, checking unchanged cache data, and compiling the diagnostic with its empty-selection guard. See [qualification receipt](UI_Layer_Evidence_2026-10-02/r4/QUALIFICATION.json) and [batch result](UI_Layer_Evidence_2026-10-02/r4/batch-result.txt).

The candidate installer is `dist/ui-layer-0.64-r4/CyrusScatter-0.64-Max2027.mzp`. Save work, run it through Scripting > Run Script, restart Max, and verify `$.baseObject.uiVersion()` reports `2026-10-02.4` with Cyrus selected. The normal profile was not changed automatically; its installed script was observed as revision 2 during this turn.

Interactive flicker, scrolling, resize, DPI, controller switching and the diagnostic's complete mounted-UI path remain untested for revision 4. Computer Use was not used. Revision 2 interactive results are historical, not revision 4 qualification. The artist scene was not opened; its saved SHA-256 remains unchanged.

## Official references

- [Autodesk SubRollout](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-CDE5B06D-4BB4-4DEA-96C1-6BAB98709F09.html): automatic inner scrolling is the default; a changed subrollout height does not move sibling controls below it.
- [Autodesk rollout properties and events](https://help.autodesk.com/cloudhelp/2025/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html): expansion events and geometry properties. `updateRolloutLayout` documents dialogs/floaters; do not assume it fixes command-panel nesting.

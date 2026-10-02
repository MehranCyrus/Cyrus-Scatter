# Main rollout width and repaint correction

2026-10-02. Product 0.64, UI **2026-10-02.5**, Max 2027.1. This follows the user's screenshots of the main Cyrus header reopening at half width and becoming full width on hover.

**Later finding:** the [2026-10-03 layer/settings trace](LAYER_RESIZE_TRACE_2026-10-03.md) confirms that revision 5 still permits a transient 240 → 162 → 240 width reset when the main rollout height changes. This report's stale-paint fix does not establish that those expansion flashes are resolved.

## Verified cause

The private Max lab reproduced the same appearance. The main rollout's native window was 272 pixels wide inside a 280-pixel parent. Collapsing and reopening it reset the child to 162 pixels, centered 59 pixels into the parent. The existing `fitWidth()` restored 272 pixels and the 4-pixel inset, but its `windows.setWindowPos` call passed `false` for repaint. The on-screen contents remained narrow even though the recorded window geometry was correct.

Repeating the same correction with repaint `true` displayed the full-width controls without hovering over them. This isolates an actual stale-paint defect. It does not establish the sole cause or duration of every earlier flash.

[Autodesk documents the final Boolean as the repaint argument](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/Interaction-With-The-Operating/GUID-282F32AC-5A80-4FDB-B8C0-275D2CC15845.html). The host reset and visible difference were measured locally, rather than inferred from that documentation.

| Step | Native width | Observed appearance |
|---|---:|---|
| Before main collapse | 272 | Full width |
| Main reopened, diagnostic width timer stopped | 162 | Narrow and centered |
| Existing correction, repaint false | 272 | Still narrow on screen |
| Same correction, repaint true | 272 | Full width without hover |

Receipts: [baseline](evidence/main-reopen/main-reopen-baseline.json), [false](evidence/main-reopen/main-reopen-repair-false.json), [true](evidence/main-reopen/main-reopen-repair-true.json). Screens were inspected through Computer Use; these JSON files record geometry, not screenshots or frame timings.

## Small implementation

The [complete delta from revision 4](evidence/main-reopen/source-delta.patch) changes three executable UI behavior lines, the version tag and three comment lines:

1. Repaint when the existing width repair actually changes the window.
2. On main-rollout expansion, request an early tick from the existing width timer; collapsing restores its 300 ms interval.
3. At that early tick, restore the normal 300 ms interval and use the existing repair path.

No new timer, widget framework or control-recreation path was added. Source ownership remains `AminScatter/tools/ui/templates/host.ms`; regenerate with `node tools/ui/generate.cjs` from `AminScatter`.

Calling `fitWidth()` directly inside `rolledUp` was tested and rejected: all 20 immediate reopen samples still ended at 162 pixels. Max performed its own width reset after that callback. Deferring through the existing timer allows Max to finish the operation first. A requested 1 ms interval is scheduling intent, not a promised 1 ms repair or paint latency. [Autodesk's expansion-event contract](https://help.autodesk.com/cloudhelp/2025/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html) describes the event; the observed ordering comes from the local test.

## Validation and limits

- All **76 existing UI assertions passed** on a fresh default synthetic controller: [receipt](evidence/main-reopen/ui-regression.json).
- **30 asynchronous main-collapse/reopen cycles passed**, including an expanded nested Collision section. Width returned to 272 pixels, timer returned to 300 ms, control handles and nested open states remained the same, and layer values/build counters/dirty state were unchanged: [receipt](evidence/main-reopen/main-rollout-reopen.json).
- Real mouse collapse/reopen of the final revision displayed full-width controls without hovering over child controls. Still screenshots do not prove zero transient flicker.
- Generation was reproducible. The installer contains exactly the tested source; native binaries and renderer tail match retained-Mesh 0.64: [qualification](evidence/main-reopen/QUALIFICATION.json).
- The artist's saved `SaveSelect 2.max` hash remains unchanged. Max 2026, other DPI scales and broad scroll/resize behavior were not qualified by this fix.

Two harness issues were corrected without changing product behavior: the first general-regression attempt reused layers with deliberately altered diversity/collision settings from the previous experiment, violating its expected unfiltered-count fixture; the rerun used a fresh controller. The first new reopen test compared MAXScript arrays by identity, then was corrected to compare individual values. Both failed receipts are retained alongside the successful results.

The separate first-visit layer construction cost remains. The reusable-editor/Qt investigation addresses that cost; this narrow repaint fix does not demonstrate that a full UI rewrite is necessary.

## Local delivery and reproduction

The installed Max 2027 script was updated **on disk** to `2026-10-02.5`, with the previous revision-2 file backed up. The running artist session was not reloaded or restarted. [Staging receipt and backup location](evidence/main-reopen/local-staging.json).

Save work and restart Max, select Cyrus Scatter, then run `$.baseObject.uiVersion()` in the Listener. Expect `2026-10-02.5`. Collapse the main Cyrus header, reopen it and keep the mouse away from nested headers. The narrow contents should no longer remain until hover. Separately compare a previously unopened layer with a warm reopened layer; their construction costs are unchanged.

The reusable Max 2027 installer is `dist/ui-layer-0.64-r5/CyrusScatter-0.64-Max2027.mzp`. Another machine can install it through Scripting > Run Script, then restart Max.

Private test session: `build/mesh-integration-2026-10-02/ui-layer-status-layout-lab2`, PID 32592 during this run. In a fresh equivalent default fixture, run `tools/ui-tests/setup.ms`, `regression.ms`, then `main-rollout-reopen.ms` through the existing private transport. The last recipe completes asynchronously; inspect its `main-rollout-reopen.json` for `passed: true` and 30 samples rather than treating transport submission success as test completion. Its 50 ms observer measures settled geometry, not physical paint latency. Local A/B preparation scripts remain under `_local/maintenance/ui-layout-lab-2026-10-02/`; package/staging scripts and original backups are under `_local/maintenance/ui-main-reopen-2026-10-02/`.

# 0.7.1 implementation and qualification

<!-- CURRENT_SYSTEM_2026-10-05 -->

Later evidence boundary: the [current findings](../Current_System_2026-10-05/CURRENT_STATE.md) include a real-scene IR restart loop. The successful UI stages below do not certify that renderer workflow. Original receipts and results remain unchanged.

5 October 2026. **Final frozen candidate `final01`: PASS.** All 19 Max 2027 runtime stages passed, alongside 13 native test groups for each SDK and 66 offline MCP tests. This report separates generated-source checks, native tests, Max event fixtures and actual pointer inspection. See [summary](evidence/summary.json), [stage results](evidence/stages.json), [source fingerprint manifest](evidence/source.json) and [receipt index](evidence/receipt-index.json).

The generated script SHA-256 is `07d0bca2efe330b8b632c1a483cea23c65629b0f7ef5c0cbecd2c6984f1f9924`. The [qualification result](evidence/result.json) records all four matching Max 2027 module hashes. The preview launcher checks those identities and the actual loaded module paths before loading the script.

The [ordinary preview launch](evidence/preview-result.json) also passed, with the development transport disabled. Real input reopened its editor through the visible Layer Manager button. [Pointer observations](evidence/pointer-observations.json) distinguish final-source checks from earlier iteration checks. [Modify panel and demo screenshot](evidence/modify-and-demo.png) shows the new entry point.

## Change and preservation boundary

The Modify panel now has setup-wide controls and a compact ordered Layer Manager. One modeless editor contains six workflow topics and 16 reusable native sections. The first Assets visit creates three sections; other topics are built on first use. Changing layers rebinds visible controls, retaining the already-created windows. Ten duplicated layer-page stacks have been removed from the generated script.

The existing feature handlers remain the authority for settings, Undo, calculation and publication. The old feature-control inventory is compared by name and type, including the split Procedural sections. New ownership checks keep a source-node selection from retargeting the editor. Layer deletion, Scatter deletion, reset, file open and Undo/Redo have explicit lifecycle handling. Source rectangles stay under Assets; global rectangles stay with receiving-surface setup in Modify.

Product metadata is 0.7.1; serialization stays 53. Native class IDs, retained Mesh/Point Cloud implementations, procedural evaluator, source-container model, MCP schemas and licensing implementation are preserved. Native binaries were rebuilt with 0.7.1 metadata for Max 2026 and 2027; no product installation or packaging was performed.

## Test method and evidence

| Check | Coverage and evidence boundary |
| --- | --- |
| Generator/inventory | Deterministic generation, balanced MAXScript delimiters, version/class metadata, every old feature control preserved, one factory set, no obsolete layer pages. This alone is not compilation. |
| Native | 13 native test groups per SDK (2026 and 2027). Ordinary binaries; no development licensing authority. This is not Max 2026 runtime qualification. |
| MCP | 66 offline tests. Closed schemas and policy-3 boundary unchanged. |
| Max 2027 UI events | Actual script compilation and native controls; all topics, two roots, ten populations, explicit layer/set ownership, manual autosave, all four spacing selector modes, Undo/Redo, source rectangle creation, close/reopen/delete/load/reset, retained control handles. |
| Resize regression | Minimum 720 × 500, wide 1100 × 900, below-minimum request and restored default. Assert actual client size, footer, tabs, both column widths/positions/heights and unchanged generation keys/epochs. |
| Brush/Live | Brush start/dab/stop, saved stroke editing, tool cancellation when navigating, source fields, transform/reset, Area/exclude/falloff, Live spacing autosave and final cleanup. Brush dabs here are API fixtures, not a new curved-surface pointer campaign. |
| Preserved engine/output | Procedural acceptance, Edit bindings, disabled-radius/persistence regression, source containers, group/geometry events, stable parking/re-entry, preview/exact output/export regression. |
| Retained preview | 100,000 candidates, navigation in four display modes, plus repeated UI topic browsing. Compare publication/generation/build counters and native retained upload/revision counters; retain failure checks. Redraw timing is not presented FPS. |
| Pointer inspection | Private demo: all six topics, explicit layer switching, scene source selection, real spacing text entry/Enter, scope/peer selection, advanced Brush/Area expansion, independent wheel scrolling, horizontal/vertical resizing, tooltip display and screenshot inspection. |

## Defects found during this loop

- First-open right columns could appear blank after child-height changes when created under a hidden parent. Topics now show their parent before constructing native children.
- Resizing could restore old cleanup-field Y positions. Those positions now use the same policy-dependent expressions as binding.
- The validity check was behind the input-held gate, allowing deletion to retain a stale editor. Validity runs first and a `nodePreDelete` callback closes the bound editor immediately.
- Real border dragging exposed missing dialog reflow and a footer outside the shortened client area. The resize handler now uses the actual client size and explicitly updates the native layout; controls are not remounted. The regression checks actual positions and scroll viewports.
- The core fixture's UI-version assertion still expected 0.7.0; updated to 0.7.1. Early fixture syntax/handler-invocation mistakes were corrected and rerun; they are not product passes.

`candidate01` stopped on the old version assertion. `candidate02` found the deletion defect. `candidate03` passed its runtime stages but was deliberately superseded while pointer-driven resize fixes changed the working source; its final fingerprint check correctly rejected it. Only the final frozen candidate qualifies the delivered preview.

## Measured UI behavior

In the final isolated event fixture, first Assets construction took **2,047 ms**. Thirty warm owner switches measured **107 ms median**, **48–223 ms range**. These are synchronous UI construction/binding measurements in a small synthetic scene on this machine, with other Max processes running. Cold construction remains perceptible; this is not a universal responsiveness guarantee. The initial three sections become 16 after visiting all topics; repeated navigation, resize and owner changes retain their native control handles.

The [100k navigation receipt](evidence/layer-editor-071-100k-navigation.json) and [UI browsing receipt](evidence/retained-ui-071.json) passed unchanged generation/publication and retained upload checks. Native Mesh/Point Cloud source was unchanged. Neither these tests nor synchronous redraw timings establish presented FPS, high-count Proxy performance or absence of every possible memory leak.

## SDK contracts

Autodesk documents dialog resize events and the separate dialog/rollout auto-layout options in [CreateDialog](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Dialogs/GUID-816D257C-CD2D-4753-A792-6E7AEFAFA6A7.html). The explicit layout call and intrinsic rollout dimensions are covered by [rollout properties and methods](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html); nested scroll behavior uses [SubRollout](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-CDE5B06D-4BB4-4DEA-96C1-6BAB98709F09.html). The [node event contract](https://help.autodesk.com/cloudhelp/2023/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/General-Event-Callback-Mechanism/GUID-F0CD0BD9-FC77-4881-8021-102B5837F7B2.html) supports the deletion guard. File-open/reset remain separate callbacks.

## Limits and next artist loop

This is a development UI increment. Max 2026 runtime, multiple monitor/DPI combinations, prolonged artist sessions, third-party renderer integration and very long custom names are not newly qualified here. The existing ten-population capacity, static-surface Brush scope, Manual/Live behavior, policy-specific gates and default-off licensing remain. This work does not remove those limits.

The next artist loop should use the isolated demo first, then a disposable copy of a representative scene: add and reorder layers, paint two sets, park/re-enter a model, adjust a selected layer pair and switch between Manual and Live. Acceptance: the intended owner is always clear, no settings disappear on selection/Undo, all controls remain reachable at the preferred size, and routine browsing does not calculate or upload again. A normal-profile release should follow matching package and host qualification, rather than loading this script into an older running DLL set.

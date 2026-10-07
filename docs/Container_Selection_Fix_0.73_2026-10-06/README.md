# Container selection correction — Cyrus Scatter 0.73

6 October 2026. This is a corrective development build of **0.73 / 0.73.0**, serialization **54**, model **`CyrusUnified1`**. It supersedes the first delivered `unified-0.73-final-20261006` package. Current 0.73 scenes keep their settings; this correction adds no scene migration or licensing change.

## Confirmed failure

Selecting a source container opened multiple error dialogs: `Unknown property: "mainUI" in undefined`, followed by Max's nested-dialog limit. The installed script's disk hash matched the delivered package, `ee0061a365bc818eb162e0f6d0953decb57aea3d4a5879a7ee728f9148a5d550`. A stale script on disk was not the explanation. The loaded modules in the artist session were not inspected or changed.

In a disposable Max 2027 process, the original router recorded **21 instances of that exact exception**, including one explicit cold-handler probe. Ordinary selection mounted through the host message loop without manually invoking the mount timer. [Diagnostic reproduction](evidence/reproduction.json), [identity/protection receipt](evidence/reproduction-qualification.json).

Max opens the container's child rollouts before the one-shot owner-binding timer has finished. Those rollouts intentionally start with `root=undefined`. Their expansion handlers nevertheless called `CyrusContainerPanel root`; the router fell through to `root.mainUI` at the old script's line 7881. Several rollouts did this, producing the dialog cascade. This is a UI lifecycle defect in our delivered code, independent of the licensing system.

The earlier [UI qualification](evidence/previous-ui-qualification.json) and [UI assertions](evidence/previous-ui-acceptance.json) exercised explicit timer mounting and subsequent binding. They did not independently witness asynchronous expansion failures during natural selection. Their passing assertions did not qualify this startup sequence. The previous claim of safe container selection was too broad.

## Small correction

- In [container-system.cjs](../../AminScatter/tools/ui/container-system.cjs), each cloned child rollout captures its own `mainUI` panel on open. Expansion no longer resolves an undefined model through the router.
- Selected-layer expansion binds only when the panel is ready and neither panel nor layer binding is already running. General rollups use the panel's layout function, which needs no model.
- In [unified-core.ms](../../AminScatter/tools/ui/templates/unified-core.ms), the shared mount handler returns immediately if its rollout has already closed, before touching discarded controls. The setup enable handler requires a ready, defined owner.

This follows Max's documented rollout lifecycle: rollout locals and controls have display lifetimes, and open/close/expansion are separate events. [Autodesk rollout-local contract](https://help.autodesk.com/cloudhelp/2021/ENU/3DSMax-MAXScript/files/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.htm), [rollout properties and expansion events](https://help.autodesk.com/cloudhelp/2021/ENU/3DSMax-MAXScript/files/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.htm).

No production catch-all suppresses the exception. The private regression's interception records failures and makes any nonzero router-error count fail acceptance. Calculation, Brush, collision, retained display and native group movement implementations are unchanged by this correction. No additional polling timer or background evaluation was introduced.

[Text-scope audit](evidence/script-change-scope.json) proves the evaluator prefix before the first setup rollout is byte-equivalent after excluding the generated identity line. This is change-scope evidence, not a substitute for behavior tests.

## Validation contract

[Max_Unified_073_Selection.ms](../../tools/procedural_lab/Max_Unified_073_Selection.ms) creates its own scenes and tests natural mounting, repeated selection, three shared consumers across two setups, correct paint-set fields, all 16 selected-layer rollups, four general rollups, cold expansion, a deliberately late closed-panel timer, a global container with no layers, an unlinked helper and save/reopen. Positive mounting never manually ticks the timer. Property changes and expansion event invocations are scripted; this is not pointer/DPI acceptance.

The corrected regression **passes 12 checks with zero router errors across 178 calls**, including reopen. Its [overall receipt](evidence/corrected-qualification.json), [acceptance](evidence/corrected-container-selection073.json), [cold warmup](evidence/corrected-selection-reopen-warmup.json) and [settled counters](evidence/corrected-selection-counter-comparison.json) all use script SHA-256 `003b717f070bf07d6f7cae031afd4fb7b14f4d550549e5d16492ff73e8716162`, payload `1df871f7859c89f39d8b7aa65c28f4df0ad28c022f3659cfdfec82415ca87451`. The broader matching reruns and package identities are reported separately in the current results.

Selection and browsing must leave publication/candidate-build, membership and retained-buffer preparation/upload counters unchanged. The checks distinguish redraw calls from buffer uploads. The negative closed-timer invocation is separately declared; it must do no work. Acceptance and the matching broader campaigns are recorded in [current results](../Unified_System_0.73_2026-10-06/RESULTS.md) and [evidence index](../Unified_System_0.73_2026-10-06/evidence/INDEX.md).

A separate [reopen diagnostic](evidence/reopen-diagnostic-qualification.json) identified expected cold preview creation: [before/first draw](evidence/cold-reopen-counters.txt) had no preview owners before rendering, then initial uploads; [subsequent selection](evidence/settled-reopen-counters.txt) reused the same data. Epoch, candidate-build and membership counters stayed identical. The passive UI baseline therefore follows explicit cold-scene warm redraws with nothing selected. These raw diagnostic counter files retain MAXScript handle suffixes and are text evidence; the final fixture converts handles to integers for valid JSON.

Earlier receipts and package identities are preserved under this folder's `evidence/`. The diagnostic execution pass proves reproduction, not product acceptance. Failed fixture attempts remain classified in the current attempt audit rather than being discarded.

## Delivery and limits

Use the [corrected package instructions](../Unified_System_0.73_2026-10-06/PACKAGE.md). Save work, run the new Max-year MZP, then close and restart Max. Current serialization-54/0.73 scenes do not need to be recreated because of this fix. Older unpublished scenes/plans remain unsupported as before.

No computer-use tools, normal-profile installation, artist-scene edits, licensing changes, commit or push were performed. Only explicitly launched private Max processes were stopped. Real mouse/DPI/scrolling, actual Corona IR and Max 2026 runtime remain separate qualification gates; this correction does not claim to resolve the outstanding algorithm/performance findings in the [roadmap](../Unified_System_0.73_2026-10-06/ROADMAP.md).

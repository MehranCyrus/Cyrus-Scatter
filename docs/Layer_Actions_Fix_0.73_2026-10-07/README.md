# Cyrus Scatter 0.73 — Add layer callback correction

7 October 2026. The artist reported `Unknown property: "invalidateGroups" in undefined` at generated script line 7813. The installed script matched the previous compact-UI package (`53bf85f9…`). The layer remained after dismissing the error because creation completed before the failing UI follow-up.

## Cause and correction

The Add handler read its rollout's mutable `root` reference after refreshing the command panel. If Max closed that rollout during the refresh, its close handler correctly cleared the reference; the still-running button handler then tried to call `invalidateGroups` through `undefined`.

Ordinary isolated scripted Add passed in Manual and Live modes. A controlled selection change during binding reproduced the **same exception**, with one layer created and both UI owner references cleared. This establishes the vulnerable callback lifetime; it does not establish the exact native event sequence in the artist's original click.

The [authoritative Add/Copy handlers](../../AminScatter/tools/ui/templates/unified-core.ms) retain the controller for the duration of the operation and only select the new layer in a panel that remains bound to that controller. Paint-set Add/Remove/order handlers use the refresh already performed by their model operations. The [composer](../../AminScatter/tools/ui/approved-layout.cjs) rechecks the rollout lifetime before the post-event layout. The interruption test caught that second issue: after fixing the owner reference, an unconditional layout still accessed controls on the closed page.

The compact ordering, spacing, scene format, class IDs and version **0.73.0** remain. Source outside the 33 rollout bodies is byte-identical to the previous package after excluding the generated payload fingerprint. Native inputs and binaries are verified unchanged. This correction does not alter calculation, Brush, cache, MCP or licensing code.

## Verification

[The new runtime fixture](../../tools/procedural_lab/Max_Layer_Actions_073.ms) invokes the actual button handlers in disposable Max 2027 sessions. This closes the earlier test gap: calling the model's `newLayer()` method alone did not exercise the failing button continuation.

All following checks passed on the final Max 2027 script (`9614f6b7d95c0e7c97f9bbe7fa2cb5a770f7a3eca813f7a9f55ea68463d114bf`; loaded payload `562300e09f3be559388b05899823d5455e6e7562ce571ae5633a1d093cfc74c7`):

- Native Add from an empty controller, repeated Add, Undo/Redo, Copy and Remove, in both Manual and Live modes.
- Add/Copy/Remove through a naturally mounted source-container view; paint-set Add/order/Remove in both native and popup views. Existing layer values and identities are checked.
- A panel close during Add: exactly one layer commits, no exception occurs, the closed panel stays closed, and a stale button callback cannot add another layer.
- Approved workflow ownership/lifecycle and ordered procedural/Brush regressions; eight idle/change/failure/diagnostic cases on the final script.
- Generator/control inventory and package/source/native identity checks.

The [evidence index](evidence/index.json) records final results and source identities, including the original failure witness. Full private profiles/logs stay in the ignored workspace. This round uses scripted runtime tests; it does not claim a new pointer-driven reproduction of the artist's original click or new FPS/Corona measurements. The [previous compact-layout qualification](../Compact_UI_0.73_2026-10-07/README.md) and [broader outstanding findings](../Full_Qualification_0.73_2026-10-07/ROADMAP.md) retain their original scope.

## Corrected delivery

[Max 2027 installer](../../dist/Layer_Actions_Fix_0.73_2026-10-07/Max2027/CyrusScatter-0.73.0-Max2027.mzp) · [package identities](../../dist/Layer_Actions_Fix_0.73_2026-10-07/BUILD.json)

Run the MZP through **Scripting > Run Script**, then **restart Max**. The version caption stays 0.73; use this dated folder to distinguish the correction. Analyzer and MCP need no update for this fix. Artist scenes and normal installed product files were not modified by the tests. No commit or push was performed.

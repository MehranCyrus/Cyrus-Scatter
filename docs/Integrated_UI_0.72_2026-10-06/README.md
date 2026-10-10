# Cyrus Scatter 0.72 — selected-layer UI and runtime qualification

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

**Superseded source:** [0.73 unified system](../Unified_System_0.73_2026-10-06/README.md) is the current development model. This 0.72 folder retains its exact original implementation, packages and actual renderer evidence.

**Subsequent independent review:** [0.72 / tyFlow R&D](../TyFlow_CyrusScatter_RnD_2026-10-06/README.md) audits this campaign's source/receipt identities, runs new offline experiments and adds bounded projection/radius/Brush/reporting findings. It changes documentation only. This folder's implementation/package identities and original host results remain frozen.

6 October 2026. Implementation campaign; development version **0.72**, package/native metadata **0.72.0**, scene serialization **53**. Publication readiness remains 1.0.

**Completed within the no-computer-use scope.** Read [results and limits](RESULTS.md), [artist workflow](WORKFLOW.md), [matching packages](PACKAGE.md) and [next acceptance gates](NEXT_WORK.md). The final pair passes 140 Python tests, both SDK/native builds, 1,312 playback assertions, private Max 2027 UI/core/container fixtures, 100k retained browsing, eight settled idle cases and actual floating-Corona lifecycle checks. Pointer/DPI, presented FPS, successful docked IR and Max 2026 runtime remain separate gates.

The initial backup is commit `75564c4`, pushed to `codex/floating-layer-editor-0.7.1`. Implementation is on `codex/integrated-ui-0.72`. No artist-profile installation or artist-scene opening/editing was performed. Tests use fresh ignored workspaces and explicitly launched private Max processes. Computer-use is excluded.

## Completed work / bounded acceptance

1. Fix the confirmed warm-topic popup retarget defect. Test real population, asset and spacing events after switching layers and Scatter roots; only the bound owner may change.
2. Show one selected layer in native Modify rollouts, with setup controls separate and the popup optional. Reuse every existing feature body; no per-layer UI copies, extra evaluation model, width polling or remount on dropdown browsing. Verify ownership, collapsed-section binding, creation/removal, Undo, persistence and lifecycle.
3. Expose Start / Stop / Save / Read status diagnostics in Scatter. Reuse the existing bounded native recorder; no MCP requirement, uploads, training permission or background disk writes. Test cancellation, multi-page export, replacement and failed writes. Preserve recording health and script identity in the local artifact.
4. Verify static Live playback, Manual behavior, source/receiver animation, real queued scene changes, retained Mesh/Point publication and idle timer settlement. Counters establish avoided CPU/upload work; they are not presented FPS or a GUI-latency benchmark.
5. Investigate the Corona stop callback exception against the primary API and an isolated host. Make only evidence-supported changes. Do not treat unknown return codes as success or delete bridge geometry while a renderer still owns it.
6. Regenerate source/help; build and run native tests with Max 2026 and 2027 SDKs; run Python/offline guards and private Max 2027 control/runtime fixtures. Freeze matching script/native identities before qualification and packaging.
7. Record final results, remaining qualification gates and exact package identities here, then back up the completed changes to Git. Never label unavailable GUI, renderer or host tests as passes.

See the independent [assessment](../TyFlow_CyrusScatter_Assessment_2026-10-06/README.md) and [tyFlow research](../TyFlow_Architecture_Research_2026-10-06/README.md) for the rationale. They are evidence baselines, not certificates for this subsequent implementation.

## API references consulted

- [Autodesk rollout category mechanism](https://help.autodesk.com/cloudhelp/2019/ENU/3DSMax-MAXScript/files/GUID-2C5F5486-A171-43C1-9304-8A3D016BB0BD.htm): declare categories at creation so native page order is explicit.
- [Autodesk rollout lifecycle and properties](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html): native open/close/roll-up events and resize behavior.
- [Chaos Corona MAXScript](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124394405/MAXScript), read through its [primary page API](https://docs-chaos.atlassian.net/wiki/api/v2/pages/124394405?body-format=storage): `getRenderType` distinguishes inactive/production/docked/floating. The API does not document a specific meaning for Stop status 2; the actual inactive fixture supplies that bounded observation.

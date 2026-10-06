# Live runtime, diagnostics and MCP qualification

6 October 2026. The final frozen `final03` candidate passed this runtime campaign in an isolated Max 2027 profile. The fixes, reproduced failures, measurements and remaining limits are in [results](RESULTS.md); the scheduling rules are in [the runtime contract](SCHEDULING.md). This is a development qualification, not publication readiness.

**Subsequent requested delivery:** matching [Max 2027 MZPs](PACKAGE.md) now package this exact runtime pair. Actual MZP installation, automatic startup and courtyard/editor reopening were verified in a separate private profile. This follow-up did not update the artist installation; the original runtime receipts below remain unchanged.

**Later UI/debugging discussion:** the user now prefers an integrated selected-layer interface and recorder controls directly in Scatter. A new installed-script `Corona IR stop failed: 2` callback is reported and unresolved. The [next UI/performance loop](../UI_Performance_2026-10-06/README.md) records source facts and pending measurements; these earlier runtime receipts do not qualify that reported failure as fixed.

The target is no repeated scatter preparation, solving, source-pool reconciliation or retained-buffer upload during unchanged idle operation. Live mode must still respond to relevant parameter, source, receiver, Brush, Edit, container, time and Undo changes. Host UI and renderer activity are measured separately; zero process CPU is not a meaningful plugin guarantee.

## Ordered work and acceptance

- [x] Inventory tracked/untracked work and preserve source and artist-scene fingerprints in `build/live-runtime-20261006/before.json`.
- [x] Freeze a matching current script/native pair; run generator, Python and native baselines.
- [x] Qualify the existing offline diagnostics/publication fixtures inside isolated Max 2027. Fix integration failures before extending behavior.
- [x] Reproduce Live idle, false Pending and Corona IR refresh. Separate timer overhead, key construction, preparation, solving, publication and buffer uploads. The historical 485-restart session remains a separate evidence boundary; it was not reproduced by the starting candidate.
- [x] Remove demonstrated unnecessary work with the smallest dependency/lifecycle correction. Keep Manual semantics and relevant Live updates.
- [x] Test editor open/closed, browsing, navigation, container enrollment/parking, source/receiver changes, Brush/Edit, Undo/Redo, persistence and failure recovery.
- [x] Validate bounded recording, consent/revocation, passive MCP publication pages, identity, budget/error behavior and lifecycle cleanup. Preserve the closed plan 1/2 and read-only policy-3 boundary until a separately qualified write adapter exists.
- [x] Exercise exact output and Corona production/floating IR on the copied courtyard. One real edit settles after one publication and one explicit IR restart. Failed docked startup stops and removes its temporary bridge.
- [x] Repeat affected cases from a fresh host/final frozen build, compare diagnostics off/on overhead and retained Mesh/Point counters, and record limits honestly.
- [x] Reconcile current documentation, control coverage, findings, evidence and next priorities; leave a concrete handoff.

The final checks include 123 Python tests, 14 native suites per SDK configuration, the complete listed Max 2027 regression campaign, actual MCP panel/stdio calls, eight idle windows, 100,000-instance retained navigation, decoded renders and a pointer-driven resize/scroll check. A separate 12-second observation with the private test transport stopped also kept all measured Cyrus counters unchanged. These checks do not exhaust every value combination of the 241 inventoried controls.

Follow [next work and acceptance gates](NEXT_WORK.md) for Brush BR-01, other host/renderer configurations, complete diagnostic reporting and expanded automation. The [evidence index](evidence/index.json) identifies retained receipts and images; [scope and source fingerprints](evidence/scope-and-identities.json) distinguish this campaign from changes already present at its start.

The private Max host was stopped after verification. All 153 protected original files in the starting inventory, including artist scenes and licensing files, remain byte-identical. Current source and the frozen private build contain these fixes; existing installed packages have not been replaced.

## Scope and evidence rules

The starting checkout already contains substantial uncommitted UI, diagnostics and MCP work. It must be preserved. Authoritative MAXScript changes belong in the generator/templates and must regenerate reproducibly. Private outputs stay under the ignored `build/live-runtime-20261006/` workspace. Artist scenes, normal profiles and unrelated licensing are preserved. This campaign does not install, publish or commit a release.

Every runtime receipt must identify its script payload, native modules, host, profile, scene and test conditions. Previous SDK builds and mock tests do not establish runtime correctness. Failed attempts remain evidence. Callback timing, CPU time, synchronous redraw timing and presented FPS are different measurements.

The initial campaign covers the runtime foundations needed for reliable tools and later AI work. Renderer orchestration, artistic learning and broad policy-3 authoring remain downstream work; a passed engineering suite is not proof of artistic quality or all renderer/host combinations.

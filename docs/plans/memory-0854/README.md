# Count-change memory correction — 0.85.4

Authorized 17 October 2026: fix large Count edits while preserving Undo, test in Max 2027 and compile an installer without artist installation. This is a patch after 0.85.3. Phase 6 remains paused; slope/altitude settings and algorithms are out of scope. Scene schema 58, row version 2, saved recipe/numeric/library formats and independent product versions are unchanged.

## Cause and correction

Relevant contracts: F02 stable placement, F04 Manual/Live, F05 atomic publication, F06 bounded work, F07 host ownership, F08 passive reuse, F11 Undo/persistence. The [read-only investigation](../../../build/memory-investigation-20261017-01/README.md) reproduced Live 5k→50k rejection: 140 MiB required free in a 100 MiB heap, despite a successful separate no-history calculation.

- Immutable native candidate schedules replace per-candidate Integer64 script arrays, including grid schedules. Planning no longer hydrates that placement-sized script transport before memory admission.
- Immutable native collision-radius buffers retain the previous Float32 rounding and ordered `(XY,3D)` values. Bounded script indexing materializes only the requested pair; native spacing and preview comparisons consume the buffers directly.
- Zero face-offset receiver transport validates and reuses immutable rows. No-modifier Edit normalization changes identity representation while sharing the already-rounded matrix/anchor values. Active Edit behavior remains separate and unchanged.
- Actual successor Updates attempt Undo-preserving light collection, then reserve the documented session MAXScript workspace if needed. Native budget arithmetic checks overflow and available system commit with a host reserve before changing `heapSize`. Saved initial heap preferences are never written. No full GC, delayed flush or Undo clearing is requested. The reservation and pending versus retained Count are visible in diagnostics.
- Existing candidate/work caps and complete-result rollback remain. Native procedural publication capability advances to 3 for transient schedule/radius types; script memory capability is 1. These are internal calculation interfaces, not saved-data layout changes.

This is not an entirely native placement pipeline. Candidate and prepared placement rows still use script arrays. The conservative preparation allowance is deliberately retained while the measured redundant transport is reduced and sufficient workspace is reserved safely.

The old check compared the complete successor allowance against current free heap. An ordinary Count edit opens an Undo hold, so even the first UI edit could fail this admission check. This was an Update memory issue, not a preset import problem or a hard 50,000 limit.

Reservation uses checked arithmetic, adds 16 MiB margin, rounds to 64 MiB steps and retains 256 MiB Windows commit headroom. Session heap cannot shrink until Max exits. Actual memory/commit exhaustion can still reject an Update while retaining the previous complete result. Autodesk documents [session heap growth](https://help.autodesk.com/cloudhelp/2022/ENU/MAXScript-Help/files/MAXScript-Language-Reference/Variables-Assignment-and-Scope/GUID-DF09BF99-2106-408D-9965-60436B853D76.html) and [Undo-preserving light collection](https://help.autodesk.com/cloudhelp/2022/ENU/MAXScript-Help/files/MAXScript-Language-Reference/Variables-Assignment-and-Scope/Memory-Allocation-and-Garbage/GUID-CA7ABB4B-6CB6-47B7-903D-84D2F45D993D.html). These references support the mechanism; Max 2027 receipts establish the tested behavior.

## Qualification gates

- [x] Generated UI/controller and 296 controls; final 167 Python tests (11.77 s).
- [x] Final native-02 Max 2027 build: 40 suites (10.41 s), including workspace reuse/commit/overflow tests.
- [x] Max startup and native-value property/index behavior.
- [x] Actual UI 5k→50k, full rows equal frozen 0.85.3, no prior history and active Undo.
- [x] Count growth/shrink, Undo/Redo, Manual pending and explicit Update, cold copy 60k→90k.
- [x] Radius values/display, spacing, protected Edit, grids, Paint and complete presets.
- [x] Preflight and after-preparation failures retain previous full output/history.
- [x] Repeated counts, native-buffer owner release, unchanged passive/idle counters and measured UI handler times.
- [x] Exact final source/native identities and MZP payload verification; no artist installation. Final preservation and delivered paths are recorded in the structured receipts below.

## Current receipts

Final build: `build/memory-fix-0854-20261017-01/native-02/receipt.json`.
Generated checks: `build/memory-fix-0854-20261017-01/generated-final/`.
Final owned profiles: `build/mcp-qualification/foundation-memory0854-final-20261017-01` and `foundation-memory0854-coldcopy-20261017-01`. Max reports 2027.1 / 29.1.0.11426. Initial native-01/source hosts are iteration evidence, not replacements for final qualification.
Tests: `tools/memory_0854/`; all generated scenes/profiles are owned disposable artifacts under ignored build paths. Historical 0.85.3 receipts and existing unrelated changes are preserved.

See [structured qualification](QUALIFICATION.json) and [package manifest/hashes](PACKAGE.json).

## Max 2027 results

| Check | Result and limits |
| --- | --- |
| Fresh default 100 MiB heap; Live 5k→50k | Pass, 735 ms. Full eight-field group fingerprint equals 0.85.3: `35c2706213cb957417417b6f1338fd0c9d3b02011ccfbff33b8bb630855c9c89`; 37,985 first-layer / 38,722 total accepted |
| Count Undo/Redo | Exact preceding 5k and successor 50k settings/publications restore; Redo available |
| Repeated counts | 30k, 90k, 200k, 5k, 50k, 90k, 200k, 5k pass; repeated counts reproduce full hashes and retain preceding Undo. 50k 735–938 ms; 90k 1,427–1,555 ms; 200k 2,966–5,228 ms. Times include test hash/log overhead; not physical spinner latency or FPS |
| Manual | Pending 5k→50k retains the 5k output without calculation; actual Update publishes exact 50k result |
| Failure retention | Owned injected reservation exception retains full output/epoch/history. Invalid radius metadata fails after the changed population prepares; old publication and Undo survive. Undo recovers both. These are not OS allocator/device-loss injections |
| Cold copy boundary | Fresh 100 MiB session, two 30k layers, then copy to 90k: 1,263 ms. Undo restores ownership; Manual Update restores exact 60k rows. Redo plus Manual Update restores exact 90k. Manual keeps explicit Update semantics |
| Radius/Edit/persistence | Count/index/comparison, independent nonzero-radius distance oracle, feedback, fresh qualified Box Auto bounds, two protected transforms and radius overrides pass; save/reopen restores exact rows |
| Owner release | Owned scene/history reset plus light collection releases all native schedule/radius counts and bytes. No full GC/history flush during Count/copy acceptance |
| Grid | Full lattice, independent area/UV masks, stable IDs, dormant/restored Edit, invalid-frame retention, Point/Empty, normal alignment, projection and spacing pass |
| Eight ready presets | Actual progress-driven Load, full output, Undo, Redo, save/reopen, Paint bytes and required channel checks pass on final pair |
| Passive UI / idle | Three main-slot opening/closing rounds cause no receiver/preparation/preview builds or workspace growth. Idle 73.958 s causes no placement/publication/preparation/receiver/preview builds; retained prepare/upload counters unchanged. Cold controls still cost time (one 698 ms open/close); this is not a new panel-speed claim |

## Installer and user checks

- [Max 2027 MZP](../../../dist/CyrusScatter-0.85.4-20261017/CyrusScatter-0.85.4-Max2027.mzp)
- [Unsigned Windows EXE](../../../dist/CyrusScatter-0.85.4-20261017/CyrusScatter-0.85.4-Max2027-Setup.exe)

Use **Scripting > Run Script** to run the MZP, then restart Max 2027. Both formats contain the same payload. Archive CRC, complete member/payload hashes, version and 2027 guards are verified. The unchanged installer core is reused with its independent build receipt. Neither installer was run in the artist profile; fresh-recipient installer execution remains user acceptance.

1. Open a copy of your scene; change Live Count 5k→50k→90k and down. Verify complete planting without the former free-heap rejection.
2. Undo/Redo several Count edits and confirm an earlier unrelated Undo entry survives.
3. Check Manual pending Count and explicit Update. Copy a layer, Update, then Undo/Redo and Update as appropriate.
4. Repeat with the Valley preset. Leave the plugin idle and open panels; confirm no repeated calculation or application of pending Manual changes.

## Preservation and limits

Branch `codex/workflow-0.75`, HEAD `5aee4ef2242307b92e16c96e0106ee095d6a4215`. Pre-existing 0.85.3 dirty changes and unrelated Physics/landscape/marketing files are preserved. No Git commit/push or deployment was performed. Normal Max.ini bytes remain unchanged; owned hosts are individually closed and the artist process is preserved. Filter implementations and the authoritative slope/altitude block match the pre-task snapshot; runtime filter payloads remain unchanged.

B26 is partially addressed by the reproduced Count and cold-copy passes. Arbitrary low-commit/allocator failure, enormous Edit histories, prolonged artist workloads, continuous physical dragging, production renderers and GPU/device-loss remain unqualified. The conservative allowance is not measured exact peak accounting. No unlimited-memory or general speedup percentage is claimed. Phase 6 remains paused. Website sources/import checks are updated locally; nothing is deployed.

Failed iterations remain in raw receipts: first source startup had invalid catch-expression syntax, fixed before final build; fixture local scope, reference-array comparison and premature idle checks were corrected. A read-only native primitive could not be rebound, and an invalid preview mode did not trigger the assumed failure; neither counts as a retention pass. The successful after-preparation test uses invalid radius metadata. Initial Pyramid Auto/converted-source inspection attempts were rejected by existing source qualification/cache behavior; fresh Box Auto and manual Pyramid pass. This task does not change source-family qualification or converted-source same-frame cache behavior. Packaging first referenced a payload-only installer core without its build receipt; the successful package uses verified staging core/receipt. Failed artifacts are not delivered.

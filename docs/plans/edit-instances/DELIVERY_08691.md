# Cyrus Scatter 0.86.9.1 — density UI, columns and Edit movement

**Acceptance withdrawn, 23 October 2026:** a fatal Modify-panel lifecycle crash
was reproduced after delivery. The artist and owned test dumps agree on the Qt
layout failure. Do not distribute this EXE as the corrected build. The
[0.86.9.2 repair](IMPLEMENTATION_08692.md) restores previous column ownership and
adds independent queued-event/owner-switch acceptance. The original results and
package identities below remain historical evidence, not crash-free acceptance.

Delivered for user testing on 23 October 2026. This patch fixes procedural map
thumbnails, empty texture-map drag targets, centered/narrow content in widened
Modify columns and delayed Edit gizmo feedback. It preserves source-aware edits,
Undo, supported saved scenes, original Paint and placement calculation contracts.

**One EXE contains distinct Max 2024, 2026 and 2027 builds, including independently
versioned Surface Analyzer 0.14.2. Only Max 2027 was tested for this patch. Max 2024
and 2026 were built without running native tests or launching those hosts.**
Do not treat the earlier 0.86.9 three-host evidence as qualification of these bytes.

## Files and installation

- [Combined Windows EXE](../../../dist/CyrusScatter-0.86.9.1-20261023/CyrusScatter-0.86.9.1-Setup.exe),
  6,443,008 bytes (6.14 MiB).
- [Exact Max 2027 Scatter MZP](../../../dist/CyrusScatter-0.86.9.1-20261023/CyrusScatter-0.86.9.1-Max2027.mzp)
  and [Analyzer MZP](../../../dist/CyrusScatter-0.86.9.1-20261023/CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp).
- [Package folder and instructions](../../../dist/CyrusScatter-0.86.9.1-20261023/README.md)
  also contains the built, untested older-host MZPs and build/hash sidecars.
- [Qualification manifest](QUALIFICATION_08691.json) owns the exact producer,
  loaded-payload, package and request/result identities.

Save and close the Max versions being updated, run the EXE, choose **Install /
Update**, then reopen Max. The EXE installs both products; separate MZPs are
unnecessary on that route. Alternatively run the matching Scatter and Analyzer
MZPs through **Scripting > Run Script**, then restart Max. Keep scripts and native
modules together. No installation into or restart of the artist's Max was performed.

The EXE SHA-256 is
`670e2fb4f0f275a8f951bb55b9c27f349de6c3b6cc0073d4c3224deb535a9010`.
Content remains revision 0.86.7 and is distributed separately. Existing content
is reused; no second library copy was created. The website was not built or published.

## What was wrong and what changed

| Problem | Cause and correction | Preservation boundary |
| --- | --- | --- |
| Procedural Map displayed only its name | Amount only borrowed Bitmap images. It now owns a single 72×72 procedural preview per mounted page, keyed by graph identity, dependency revision and validity interval. Unchanged binds reuse it; replacement/close releases owned images. | Preview failure clears presentation, retaining the assigned graph, Manual settings and current placements. A generic tile is separate from the receiver-aware Show mask field. |
| An empty Map target could not receive a dragged map | The visible browse control was an ordinary button. Both map targets now use Max's native TextureMap button, which is available when empty; Max may caption it None. | Existing assignment, Clear and Undo paths remain. A complete material is not a density map; drag its texture map. No arbitrary material-channel extraction is added. |
| First-column contents became narrow and centered after widening | Measured native body width was 201 units while its embedded dialog remained 162 units and centered. The existing owned rollout subclass fits root dialogs/slots to the actual parent width, while lazy layouts cap visible controls to their clipping slot. Main controls use their actual available width. | Native rollout order, categories, lazy mounting and existing lifetime cleanup remain. Reflow/reselection does not calculate placements or consume pending Manual edits. Max still packs whole rollouts. |
| Edit Move handle/gizmo lagged until release | Feedback and selected-center queries used the committed final view; Move locked the axis tripods, and Max could retain an old center after the final renderer commit. Live matrices now derive from the current authored block and proven local input/downstream transform, selected queries avoid copying the whole visible vector, and Move axes follow the current center. A coalesced, modifier-identified selection-only UI message refreshes Max's cached axes after commit/rollback. | Full placement/display publication remains on release. The message runs outside the renderer callback, creates no Undo item or authored revision and is discarded with its owned panel. Rotate/Scale retain their original gesture pivot. |

Transient feedback captures the local authored revision, so presenting an older
retained bundle cannot clear a newer gesture. Display, hit testing, bounds and
gizmo centers use the same live handle matrix. CPU rollback, Cancel and normal
history transitions clear preview state. The read-only native
`cyrusEditHandleMatrix` query exposes live feedback for verification;
`cyrusEditInspect` retains its committed-renderer matrix meaning.

The [implementation record](IMPLEMENTATION_08691.md) declares ownership,
invalidation, resource lifetime, Undo and failure behavior. Authoritative UI
templates/generators and their generated script were updated together. No
placement-sized storage or computation was moved into MAXScript.

## Exact evidence

Source baseline: `codex/workflow-0.75` at
`dde07870d4c005cb27987c4c46f7f9065cb1e891`, plus scoped uncommitted patch changes.
Unrelated Arrange, Physics Lab, library plans and private assets were preserved.
This turn did not commit or push. Local ignored artifacts are not a Git backup.

| Check | Final result and scope |
| --- | --- |
| Generated UI | 333 controls and 32 delimiter fixtures passed in `build/ui-edit-08691-20261023/generated03/`. |
| Focused Python | 35 passed: build inputs, explicit build-only receipt admission, installer adapter and feature catalog. |
| Max 2027 SDK native | Scatter 56/56; Analyzer 1/1. Final producers are `scatter-2027-07` and `analyzer-2027-02`. |
| Max 2024/2026 SDK | Distinct matched native/managed payloads compiled; receipts explicitly say `tests_run: false`. No native test executables or older hosts were run. Final Scatter producers end in `-04`; Analyzer producers in `-02`. |
| Focused Max 2027 product checks | 50 assertions across 13 selected scenarios in owned `host05`: map preview/cache/invalidation/Clear/Undo, actual map drop, single/multiple-column geometry and remount, actual held/released Move feedback, Manual preservation, 100/10,000/30,000 placement feedback probes, Undo/Redo/Cancel/new save/reopen, previous 0.86.9 edits/radii, Analyzer, stacked transforms and guarded failure/rollback/retry. Preparation and repeated witnesses are excluded from the count. |
| Package identity | All six MZPs passed CRC, duplicate-entry, member hash, version and host-guard checks. Both 2027 archives match the loaded test payload. EXE and sidecars match the final `packages03/recipe-receipt.json`; 10,677 recorded producer input files still matched at final verification. |
| Installer scope | Current source/build/contained-package verification using the existing unchanged transaction engine. No new interactive installer campaign, installed-profile restart test or older-host runtime acceptance was run for this patch. |

The final Max 2027 test payload includes:

| File | SHA-256 |
| --- | --- |
| `CyrusScatter.ms` | `096f956e7d96c58fd4f3a20d3e2cfb3663ea71002342d567aa5a553134fca53d` |
| `AminScatter.dlx` | `51c1419fcdf9c4529fe27d7eedf8261306e9217e7e48b99362bf4dd7a0d4a7de` |
| `CyrusScatterEdit.dlm` | `ebd875ff9d8f86cb35db83dab18883c9399a457589eb1f294e55ebafd5a6734d` |
| `CyrusSurfaceAnalyzer.dlx` | `d179cf3cb7f023c6592e971e8491378cd147d97bab415cfa014445031b4d1897` |
| `CyrusSurfaceAnalyzer.ms` | `256ec6a25176417d2d45ec7f7ef1262ca3ffec1332f57965c77df7883a56ae69` |

Actual Computer Use dragged the Move gizmo and a Checker map from the Material
Editor onto the empty target, choosing Instance. The Move trace records the same
stable ID, authored delta, handle matrix, Max `getTransformAxis`, epoch and build
counter. Handle and gizmo moved while held without publication; release produced
one complete successor and both ended at its final position. One observed held
sample changed in 15 ms; this is a sample interval, not measured FPS or a latency
guarantee. A brief retained preceding frame during final staging is preserved by
the atomic display policy.

Request, result, wrapper and loaded-file evidence lives under
`build/ui-edit-08691-20261023/host05/`; the manifest selects accepted requests and
their hashes. Final source fixture snapshots are under `frozen-fixtures/`.
Intermediate candidates remain recorded and excluded: early checks exposed an
attempt to write creation-only checkbox widths, a mistaken validity-array length
and stale cached axes after commit. The final candidate passed their corrected
witnesses. Two test-only failures on the final payload are retained: an overly
strict nested-HWND width assumption, and a diagnostic referencing a missing test
symbol. The corrected column test checks the actual native body/root slot and
visible list insets, including after teardown/reselection; it does not require
invisible oversized child windows to match their clipping slot.

The owned host was closed after testing. The artist's running session, profile
and original scene were untouched.

## Limits

- Max 2024/2026 are built and untested. Artist acceptance of those payloads remains
  separate; this delivery does not claim they behave identically to Max 2027.
- Whole materials have no single density channel. Use a supported texture map.
  Receiver/camera/renderer-dependent output cannot be inferred from a generic
  thumbnail; Show mask is the surface-aware inspection route.
- Full mesh/point presentation still completes after release. This patch does
  not make heavy geometry realization asynchronous or guarantee production FPS.
- [B37](../../BACKLOG.md#edit-instance-findings--0869) remains open for whole-object
  Copy of clone-dependent Edit stacks/radius history. Generation/receiver binding
  guards remain enforced; incompatible edits are not silently rebound or reset.
- Saved schema 59, recipe 8, native Edit storage/capability 2, original Paint and
  content 0.86.7 are unchanged. Preserve original files when upgrading from
  plugins older than 0.86.9.
- Broad renderer/device-loss, high-DPI, large production-scene and long-soak
  qualification was not added. Earlier reports retain their original scope.
- Maintained knowledge guidance is updated; the selected retrieval index remains
  stale. No index activation, website publication, artist installation or Git
  push is part of this patch.

# Current state and evidence boundaries

**Superseding runtime slice, 6 October:** [results](../Live_Runtime_2026-10-06/RESULTS.md) and [source/receipt identities](../Live_Runtime_2026-10-06/evidence/scope-and-identities.json) record idle/Manual/IR fixes, diagnostics and actual MCP qualification. Current MCP source has twelve tools/seven resources and passive actual-publication pages. The older unresolved/status table below is the 5 October baseline; BR-01, material/host qualification, policy-3 writes and licensing remain open in the [updated queue](../Live_Runtime_2026-10-06/NEXT_WORK.md).

As of 5 October 2026. Source facts were checked in the local worktree; runtime results below are prior receipts, not new runtime tests in this documentation pass.

**Later research boundary:** the [Houdini/Autodesk follow-up](VENDOR_RECHECK.md) strengthens acceptance contracts without qualifying a new build. Diagnostics build/generator edits appeared independently in the shared checkout during that pass. The [follow-up receipt](evidence/vendor-recheck-validation.json) records observed source drift. The delivery/test claims below remain tied to their recorded snapshots; new diagnostics source is not automatically a delivered or tested recorder.

## Identity and delivery

| Item | State |
| --- | --- |
| Workspace | `F:\Cursor\_Cyrus_Apps\CyrusScatter` |
| Branch | `codex/floating-layer-editor-0.7.1` |
| HEAD | `addccb492a88292529594de81c287cc26e5ffe98` |
| Earlier review baseline | `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac` |
| Current Scatter source | 0.7.1 development; tracked and untracked UI, fixture and document work remains outside HEAD |
| MAXScript serialization | 53; internal class IDs and compatibility names remain unchanged |
| MCP package | Recorded baseline 1.1.0; concurrently edited source identifies 1.2.0 with diagnostic-event reading, unqualified in this pass. Plan versions 1.0/2.0 are separate |
| Analyzer | 0.14 in the documented source line; its SDK/host identity still belongs in each run |
| Existing installers | Earlier snapshots, including 0.7.0; not the current script/native pair |
| Publication | 1.0 is reserved for publication readiness; historical 1.x labels do not prove it |

[Source inventory](evidence/source-snapshot.json) records hashes and initial Git scope. An inventory proves identity, not correctness. The Git checkpoint does not include later uncommitted work or ignored artist assets, DLLs, SDKs and private logs. Do not infer backup completeness from HEAD alone.

The UI qualification pinned `build/ui-071/final01`; the real scene uses that script/native line plus the recorded Analyzer dependency. The delivered private-session script hash was `07d0bca2efe330b8b632c1a483cea23c65629b0f7ef5c0cbecd2c6984f1f9924`. Each future run must verify loaded modules and script provenance again; an on-disk file or version caption alone does not prove what Max loaded.

## What was delivered

| Area | Current implementation | Evidence and limits |
| --- | --- | --- |
| 0.7.1 UI | Compact Modify panel; one reusable resizable Layer Editor with Assets, Population, Paint, Transform, Spacing and Statistics | [UI results](../UI_0.7.1_2026-10-05/RESULTS.md): 19 recorded Max 2027 stages, event/lifecycle and pointer checks. No claim for all DPI/monitor arrangements or Max 2026 runtime |
| Procedural calculation | Ordered layers/sets; stable identities; three collision scopes; per-source/instance radii; bounded replacement; layer cleanup; staged publication | [Implementation](../Procedural_Implementation_0.7_2026-10-04/IMPLEMENTATION.md), [later fixes](../Independent_Review_0.7_2026-10-05/IMPLEMENTATION_RESULTS.md); no unlimited fill or general dependency graph |
| Source containers | Ordinary rectangles classify registered source pivots in local XY; global/layer/set pool selection; parking/reentry preserves settings | [Container contract](../Independent_Review_0.7_2026-10-05/SOURCE_CONTAINERS.md), real-scene parking/restore assertions; these rectangles do not define receiving terrain |
| Brush/Edit | Saved paint/erase histories on static flat/curved meshes; supported Edit reservations and radius bindings; Undo and persistence | [Real-scene results](../Real_Scene_0.7.1_2026-10-05/RESULTS.md); topology/system-unit changes and very small coordinate roundtrips have limits |
| Display | Retained Mesh and Point Cloud; separate display budgets; other preview modes preserved | Historical [Mesh](../Retained_Mesh_Preview_2026-10-02/RESULTS.md) and [Point Cloud](../Retained_Point_Preview_2026-10-02/README.md), later unchanged-generation/upload checks. Synchronous redraw is not presented FPS |
| Exact/render output | Published transforms, automatic PFlow bridge and Bake/CS Edit paths | Real scene: 10,724 exact instances, 19 source groups, five layers/eight populations, two completed Corona production previews. IR is a separate unresolved failure |
| MCP | Recorded baseline: nine tools/four resources, typed validation, local approval, owned mutation, cached inspection and legacy export. Concurrent source adds `scatter_read_diagnostic_events` as tool ten | [Recorded baseline receipt](../UI_0.7.1_2026-10-05/evidence/mcp-tests.log): 66 passed; earlier [Max campaign](../Procedural_Implementation_0.7_2026-10-04/RUNTIME_REPORT.md). Neither qualifies the new diagnostic tool. Policy 3 remains read-only |
| Licensing | Default-off native/local experimental foundation, scoped recipe/Edit/Brush ownership and signed authority tests | [Native foundation](../licensing/NATIVE_FOUNDATION_2026-10-05.md). Not whole-product enforcement, deployable issuer/customer service, or third-party renderer qualification |
| AI/ML | Operational record types and detailed research/roadmaps | [Style guide](../Artist_Style_ML_2026-10-04/README.md), [new research](../AI_Design_Learning_Research_2026-10-05/README.md). No learning software or trained model implemented |

The real-scene variants exercise incompatible options separately. Passing those examples does not mean every option can be enabled together or every renderer/asset combination is supported.

## Unresolved findings that change the next loop

| ID | Status and evidence | Impact / next evidence |
| --- | --- | --- |
| IR-01 | **Observed, cause unisolated.** Existing Corona log has 485 render-start markers from 12:03:04 to 12:06:23, repeatedly returning to the first pass. [Observation](evidence/ir-restart-summary.json) | IR cannot refine normally. Correlate node notifications, bridge phases/build counts, publication epochs and retained updates in a disposable scene. Production success does not close this issue |
| UI-01 | **Reproduced.** Redraw returns all eight populations to Pending while input/publication equality and epoch remain unchanged | [Pending receipt](../Real_Scene_0.7.1_2026-10-05/evidence/pending-status.json). Distinguish true unpublished changes from display/event dirty hints. Do not assert this causes IR-01 without a trace |
| BR-01 | **Observed boundary.** Extremely small generated terrain coordinates triggered Brush fingerprint rejection after reopen | [Finding](../Real_Scene_0.7.1_2026-10-05/FINDINGS.md). Test canonical-equivalent coordinates and genuine topology changes; the scene-only normalization is not a production fix |
| PERF-01 | **Unresolved measurement.** Cache reuse coexists with slow synchronous redraw/message processing in some real-scene samples | Profile clean-host traversal, key construction, container reconciliation, Brush and UI work; preserve no-regeneration/no-unchanged-upload invariants |
| ASSET-01 | **Existing-log warnings.** The user's later IR session reported missing texture-map plugins and external asset paths | Audit the exact copied scene/profile and asset resolution before using rendered images as appearance ground truth. These warnings do not establish the IR restart cause; do not silently equate the earlier relink report with this session |
| MCP-01 | **Intentional gap.** Current policy-3 inspection has no matching write or complete actual-layout export contract | Version the new contract; prove all exported values refer to one publication and cannot overwrite artist-owned state |
| LIC-01 | **Release gate.** Whole-product ownership and saved-state continuity are incomplete | Follow B07/B08 and the operation-family policy in [licensing roadmap](../licensing/ROADMAP.md); do not enable enforcement as an incidental MCP change |

The ordinary loaded test build excludes the licensing experiment. The IR observations are not evidence of a license denial. No definitive callback-level root cause has been reproduced during this documentation pass.

## Remaining product limits

Policy 3 supports Random/Clusters assignment, with legacy line/Analyzer assignment left on older policies. Outside-painted-coverage composition currently references earlier sibling sets on a shared domain. Brush receivers are static; painting is not a geodesic brush. System-unit migration of combined Brush/Edit/radius state is not automatic. Point and Empty source semantics differ, and Empty is incompatible with accepted-target replacement. Protected edits can legitimately exceed a quota or conflict with each other.

The native limits include ten stored populations, bounded attempts/rounds and neighbor-work caps. These are not a universal memory or wall-time guarantee. Old and staged new output can coexist during publication. Measure the expensive source/renderer cases before enlarging limits.

## Work intentionally not performed here

No new host reproduction, product test campaign, code fix, render, model training, package, installation, Git commit or push. Fresh work consists of source/document inspection, primary-reference checks, documentation edits and document consistency checks. See [validation](EVIDENCE.md) for the exact distinction.

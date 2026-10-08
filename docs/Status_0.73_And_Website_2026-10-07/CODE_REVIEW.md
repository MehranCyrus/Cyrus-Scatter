# Current compact 0.73 code review

Reviewed 7 October 2026 against the requested baseline `d55dfa88cbeda7af366e4510ac3119a749368958`. **Verdict: development baseline supported; publication readiness remains gated.** Confidence is high in the cited source paths and evidence distinctions, medium in the source-derived Manual/Undo behavior, and low in attribution of the historical cold Undo history loss.

This is a bounded static audit, not an exhaustive correctness certificate. It covers the native/MAXScript procedural model, selected Brush/Edit/container identity and restore paths, Live invalidation, retained Point Cloud/Mesh versus Proxy, and compact native/popup composition including the latest Layer Actions correction. It does not audit every control handler, renderer bridge, MCP/licensing boundary, or every native geometry algorithm. No Max was launched; no runtime, build, package, installation, or Git operation was performed by this reviewer. Offline reruns by the coordinating task must be reported separately. The only file written by this reviewer is this report.

The code-review skill was used as a checklist. The requested whole-baseline scope includes pre-existing findings, rather than limiting the review to the last patch.

## Identity and evidence boundaries

Direct read-only SHA-256 checks during this audit matched the latest Layer Actions evidence index:

| Current file | SHA-256 |
| --- | --- |
| `AminScatter/scripts/AminScatterObject.ms` | `9614f6b7d95c0e7c97f9bbe7fa2cb5a770f7a3eca813f7a9f55ea68463d114bf` |
| `AminScatter/tools/ui/templates/unified-core.ms` | `e718cb1de707e0af7464313c591a86bbf35fd66b16e16ff73f3100174416e799` |
| `AminScatter/tools/ui/approved-layout.cjs` | `f2e40ee64783d98db009040f52180b5b7b84527fbffecf115ebb9bd10a4a4405` |

The generator's authoritative route is explicit in `AminScatter/tools/ui/generate.cjs:5`: read `templates/unified-core.ms`, run inventory and approved-layout composition, then container composition, fingerprint the payload, and compare/write the generated script (`:8`–`:17`). Editing only the generated script would be incomplete.

Three 0.73 script identities must remain separate:

| Stage | Historical evidence it supports | Boundary |
| --- | --- | --- |
| Full qualification, script `15390e73…` | Earlier core/persistence/movement, actual garden/pointer use, retained display, 100k navigation/playback and actual Corona measurements | Frozen earlier script/native pair; not a fresh run against current script |
| Compact UI, script `53bf85f9…` | Compact control bounds, native/popup sizing, pointer browsing, idle/cache checks | Earlier compact script; not the latest handler correction |
| Layer Actions, current script `9614f6b7…`, payload `562300e0…` | Actual button-handler invocation in scripted Max 2027, interruption/lifetime regression, approved-layout/procedural and eight idle cases | `computer_use:false`; does not reproduce the artist's exact pointer sequence or rerun FPS/Corona |

Sources: [full results](../Full_Qualification_0.73_2026-10-07/RESULTS.md), [compact qualification](../Compact_UI_0.73_2026-10-07/README.md), [latest correction](../Layer_Actions_Fix_0.73_2026-10-07/README.md), and [latest evidence index](../Layer_Actions_Fix_0.73_2026-10-07/evidence/index.json). The current README's distinctions are substantially accurate. Its engineering-contract language must not become a claim of universal, freshly rerun acceptance.

The coordinating task separately reports fresh successful checks: 141 Python MCP/tools tests, 14 Scatter plus one Analyzer native core tests, and generator checks covering 240 controls and 22 fixtures. It verified eight pinned source identities, 33 evidence entries and the MZP hash. These are new offline checks, not new Max runtime qualification. See [baseline identity](evidence/baseline-identity.json) and the coordinator's verification records.

**Delivery mismatch:** the coordinator's read-only disk inspection found the normal Max 2027 profile's `C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/scripts/CyrusScatter/CyrusScatter.ms` still has the earlier compact hash `53bf85f9…`, while source/latest package has `9614f6b7…`. That establishes an on-disk mismatch, not what a currently running Max process has loaded. No installation was performed. Before attributing a fresh artist report to the corrected baseline, verify the loaded fingerprint in an authorized host using the exact latest package.

## Implemented contracts and limits

| Area | Source support in current baseline | Evidence status / limit |
| --- | --- | --- |
| Ordered populations and independent scopes | `AminScatter/src/procedural.cpp:23` validates limits and identities; `:48` validates pair scopes/endpoints; `:67` evaluates layers and sets in order; `:86`–`:105` builds layer/sibling blockers and resolves self rules. Earlier accepted ordinary instances win; protected edits in later populations can already block/conflict. | Latest historical procedural receipt lists sibling ordering, all three spacing scopes, accepted target/underfill and protected Edit cases. Not every possible recipe combination tested. |
| Bounded accepted-target work | `procedural.cpp:24`–`:45` caps layers, total populations, candidates, attempts and repair rounds; `:128`–`:143` extends a bounded prefix and reports shortfall/round exhaustion. `group_spacing.cpp:106` enforces neighbor visits. `unified-core.ms:3884`–`:3893` admits the complete pool before Edit mutation. | These limits do not bound every preparation allocation or total elapsed time. Underfill is supported output. Weighted Empty assets are explicitly rejected for accepted target (`unified-core.ms:3813`–`:3815`). |
| Publication and error retention | `unified-core.ms:3897` starts an Edit transaction; `:3917`–`:3921` stages displays/metadata before publication; `:3923`–`:3938` publishes one epoch. `:3942`–`:3947` rolls back an active Edit transaction and clears prepared keys on failure. `:3859`–`:3863` retains preceding viewport cache on successor failure. | Latest historical procedural and idle fixtures cover failure/recovery. This supports the tested transactional path, not an assertion that arbitrary host callbacks, device failures, or allocation failures at every commit instruction were fault-injected. |
| Brush and Edit correspondence | `unified-core.ms:3344`–`:3372` preserves source/receiver correspondence histories with explicit caps; `:3491`–`:3503` computes a base binding. `placement_identity.inc:8` transports candidate key and anchor. `cyrus_edit_stack.inc:6`–`:25` maps rows by stable identity; signature changes require reset. `brush.cpp:171` rejects changed surface fingerprints; `brush_host.cpp:254`–`:265`, `:310`–`:312` implement stroke hold/restore. | Latest historical receipt includes erase/Undo/Redo, curved Brush and persistence, clones/zero quota/selected radii. Stable identity is scoped to valid base correspondence; it is not arbitrary topology/seed/source replacement migration. Wide-history memory remains open below. |
| Container membership and following | `unified-core.ms:3572`–`:3629` keeps persistent source rows and filters active membership without compacting them. `source_container.cpp:93`–`:128` freezes eligible static hierarchies, checks ownership and caps 1024 nodes. `:146`–`:179` carries translation, rejects independent changes, and rolls back failures. `:192`–`:248` records whole-node movement in the original hold with weak references and restore guards. | Static, unlocked PRS translation is the supported following slice. Rotation/scale changes the boundary only (`:151`–`:152`). Historical direct and pointer movement evidence exists, but cold first pointer Undo history remains unresolved. |
| Relevant Live scheduling | `input_validity.cpp:15`–`:40` only recognizes specific stock constant controllers; `:45`–`:66` intersects other controller validity; `:126` onward intersects settings, nodes, ancestors and maps. `unified-core.ms:1784`–`:1829` stores validity and only responds to expired Live intervals. `:3631`–`:3694` classifies changed dependencies; `:5941` batches node events. | Source and historical eight-case receipts support reuse in measured idle/navigation scenarios. Deletions deliberately invalidate broadly (`:3691`); global Undo/Redo is broader still. No claim of zero host notifications or zero Max CPU is justified. |
| Retained Point Cloud and Mesh | `point_display.cpp:110`–`:114` compares immutable snapshot identity; `:129`–`:148` realizes point buffers once; `:150`–`:170` draws them without scene evaluation. `mesh_display.inc:74`–`:89` uploads shared triangles and instance matrices; `:107` issues instanced drawing. `point_display.cpp:261`–`:269` reuses equal generations. | Existing implementation, historically measured reuse. Retained GPU resource failures and device lifecycle are a separate gate; these paths are not a new engine or fresh performance result from this audit. |
| Proxy | `geometry_preview.inc:42`–`:46` creates retained snapshots only for Mesh mode 4; Proxy modes store cached geometry/batches. `preview.cpp:161`–`:179` still submits triangles on each redraw. | Cached preparation does not imply retained Proxy drawing or low cost at 100k. Existing performance limitation remains. |
| Compact native/popup ownership | `approved-main-ui.ms:16` binds the same root/owner records; `:23`–`:41` retargets and binds existing editors; `:62`–`:97` handles one-shot mount and close cleanup. `approved-layout.cjs:208` generates bind/close lifecycle and `:228`–`:241` adds width-change reflow and guarded event continuations. | The historical 240-control mapping and real-bounds tests support coverage/layout at tested scale, not pointer qualification of every control or every DPI. |
| Latest Add/Copy correction | `unified-core.ms:4306`–`:4319` caches the controller across refresh and selects through a still-bound panel. `approved-layout.cjs:232`–`:241` rechecks readiness/root before post-event layout. Set handlers `unified-core.ms:4373`–`:4380` rely on model refreshes. | `Max_Layer_Actions_073.ms:16`–`:38` injects a close during actual Add continuation and checks stale callback rejection; `:39` onward exercises native/container/popup actions. Current historical result has seven passing action groups. No newly observed recurrence or new defect found in this corrected Add/Copy path. |

The latest [procedural receipt](../Layer_Actions_Fix_0.73_2026-10-07/evidence/layer-actions073-regression02/procedural-acceptance.json) and [button receipt](../Layer_Actions_Fix_0.73_2026-10-07/evidence/layer-actions073-fixed03/layer-actions073.json) were read, not rerun. Native test source inspection included named cases in `AminScatter/tests/procedural_tests.cpp:15`–`:173` (stable sampler/pattern/Relax, distances, refill, target/order, scale bounds, cleanup limit, falloff, threading/density and exhaustive comparison), and selected Brush tests. Their presence is coverage intent, not a new passing result.

## Findings

| Priority | Finding | Classification |
| --- | --- | --- |
| P1 release gate | First cold pointer container Undo restored positions but erased prior Undo/Redo history; subsequent Redo failed | Historical runtime failure, current cause unisolated; not newly reproduced |
| P2 | Unrelated scene Undo/Redo can admit a pending Manual recipe through the initial-preview condition | Current source-derived behavior; focused Max reproduction outstanding |
| P2 | Brush authored limits do not bound aggregate derived dabs, patch membership, and reverse face links | Current source-confirmed existing resource gap; no OOM induced |
| P2 performance limitation | Proxy redraw repeats triangle submission even when placement and batch identities are stable | Current source-confirmed existing limitation; older measurements remain historical |

### P1 — Cold container Undo history remains a release gate

The retained [pointer receipt](../Full_Qualification_0.73_2026-10-07/evidence/real-assets/pointer-container-first-redo-failed.json) reports an actual pointer move, all three sources followed, position Undo succeeded, `undo_after_undo:[]`, `redo_after_undo:[]`, and `redo_passed:false`. Its top-level `passed:true` describes the move check and must not be interpreted as a full Undo/Redo pass. A subsequent direct cold-load test and controlled repeated gestures passed; neither resolves the first pointer failure.

Relevant current paths are `AminScatter/src/source_container.cpp:192`–`:248` (restore and node-change hold), `AminScatter/tools/ui/templates/unified-core.ms:5948`–`:5957` (global script Undo refresh), and the container/UI rebind callbacks. This audit does **not** identify any of them as the flushing caller.

Smallest next step: instrument the first gesture's native hold/flush reason, script callback sequence and heap state in an owned fresh-load host, retaining prior Undo history. Fix the proven caller only. Acceptance must preserve the preceding history plus repeated Redo after the first actual pointer/keyboard gesture; increasing the heap or clearing the buffer during setup would invalidate that gate.

### P2 — Manual pending work can calculate after unrelated Undo

Concrete source chain:

1. `unified-core.ms:5956`–`:5957` invokes `AminScatterLayerUndo` on every scene Undo/Redo.
2. `:5949`–`:5950` walks every Scatter and calls `forcePreviewUpdate` on all layer entries, with no dependency relevance or update-mode check.
3. `:3024` sets `dirty=true` and `previewBuildCount=0`.
4. `:2994` allows `refreshPreview()` when dirty and **either** Live **or** `previewBuildCount==0`.
5. `:3855` evaluates the recipe unless the separate temporary `groupDisplayOnly` flag is active; the global Undo callback does not set that flag.

A setup with a completed publication and a pending Manual edit therefore has a path to publish that edit on the redraw after an unrelated box Move Undo. This contradicts an unqualified “Manual waits for Update” statement (`templates/approved-main-ui.ms:4`, `:47`). This is a static control-flow finding, not a demonstrated host reproduction, and it does not explain the cold history loss.

Smallest fix direction: distinguish “no completed cache exists” from “restore invalidated input.” Do not reset the bootstrap count for unaffected owners; preserve the completed Manual publication and mark it pending. For relevant Scatter Undo, explicitly define whether restoring authored state should also restore/rebuild its publication. Verify both semantics before changing the global callback.

Acceptance: complete Update, change a Manual recipe without Update, perform and Undo/Redo an unrelated node move, then verify unchanged publication epoch/rows/prepared count until Update. Separately verify Undo/Redo of actual Scatter layer, Brush, Edit and container changes remains correct.

### P2 — Brush aggregate derived-memory admission is still missing

`brush.cpp:154` caps derived samples per stroke; `:255` and `:263` cap one million authored samples per document. But `:175` resamples every stroke, then `:176` builds a patch per enabled derived sample and adds reverse links for every touched face. No checked aggregate derived-sample/link/byte budget exists there. Wide strokes across dense surfaces can multiply work and memory far beyond the saved sample count; disabled histories also resample before the enabled check.

This confirms existing F3 in [the prior R&D findings](../TyFlow_CyrusScatter_RnD_2026-10-06/FINDINGS_AND_ROADMAP.md), rather than a newly observed crash. Smallest fix: account for total derived dabs, patch links and bytes before committing each expansion; fail with an actionable limit while retaining authored history and the previous complete field/publication. Require a bounded-memory stress case, exact ordinary replay equality and save/reopen equivalence. Do not claim the procedural neighbor budget solves this allocation path.

### P2 — Proxy remains a redraw bottleneck

`preview.cpp:170` submits every cached batch triangle, and `:174`–`:179` supplies the fallback transformed loop. This explains why unchanged placement counters can coexist with expensive navigation. Smallest improvement experiment: a retained Proxy display path preserving the exact box/sphere/pyramid geometry, budgets, shading and shown subset. Gate it on draw-only measurements and stable placement/upload identities; do not change sampling to manufacture a speedup. No new Proxy fix is claimed here.

## Prioritized acceptance and safe product wording

1. Verify the exact corrected loaded script/native pair first, given the normal-profile disk mismatch. Resolve the first cold pointer Undo history gate on that pair. Keep the historical failing receipt intact.
2. Reproduce and decide the Manual/unrelated-Undo behavior above; exercise failure recovery without losing the previous publication or Edit state.
3. Recheck actual pointer Add/Copy/Remove, interruption and container reselection on the corrected script in the artist workflow. Scripted handler success is strong regression evidence but not the original gesture reproduction.
4. Bound Brush derived memory; retain deterministic replay, stable IDs and ordinary persisted behavior. Keep projection/extreme-radius R&D separately scoped rather than presenting overall performance as solved.
5. Qualify Max 2026 runtime, DPI/font/docking variants, long sessions and additional renderer interactions. Any new FPS/Corona claim needs its own current identity, scene, settings and measurement.

Supported website wording: “Cyrus Scatter 0.73 is a development build with a compact layer workflow, independent paint sets, ordered spacing, editable Brush history, linked source containers, and retained Point Cloud/Mesh previews.” Explain that Manual has the above restore-path acceptance gap if making a detailed scheduling claim. “Scripted Max 2027 regression checks passed for the latest Add/Copy callback correction” is evidence-backed historical wording.

Unsupported wording: universally production-ready, every control fully tested, guaranteed zero idle CPU, retained/cheap Proxy at any population, unlimited Brush or instances, arbitrary topology-preserving edits, complete Max 2026 runtime certification, or current-script Corona/FPS gains inferred from the layout change. The current baseline has useful implementation and finite evidence; these remaining gates should stay visible in the handoff.

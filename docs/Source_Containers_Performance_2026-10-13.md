# Source rectangle creation and selection investigation

Historical 0.81.3 investigation. The [0.81.5 successor report](plans/terrace-0815/REPORT.md)
records the authorized compact-editor correction, matched-host tests and real-scene work.
The no-change statements below describe this original investigation only.

13 October 2026. Investigation of layer and global source rectangles in current
Scatter 0.81.3 / schema 58. No product code, version, package or installation was
changed. The artist scene was not opened or modified.

Selection latency was reproduced in an isolated Max 2027 process with ordinary,
matched modules. The strongest finding is expensive Modify editor construction
on rectangle selection. Creation has a separate problem: repeated global
container reconciliation, broad invalidation and rebinding. Both layer and global
rectangles use these same paths.

## Measured behavior

Synchronous wall-clock measurements in one hidden, disposable Max 2027 host.
These are diagnostic timings, not physical pointer latency or presented FPS.
The initial scene has one layer, one simple receiving plane, one box source and
100 published plants. Rectangles start with collection off. Selection runs have
nine rectangles; the later opened-button and scaling runs grow to thirteen.

| Action | Median | Samples |
| --- | ---: | ---: |
| First Scatter Modify mount | 4,931 ms | 1 |
| First layer rectangle Modify mount | 5,503 ms | 1 |
| First global rectangle Modify mount | 5,267 ms | 1 |
| Alternating selection between layer/global rectangles, including complete Modify remount | 5,908 ms | 6 |
| Warm main editor bind, without remount | 95 ms | 7 |
| Layer Create button, opened and bound page | 353 ms | 2 |
| Global Create button, opened and bound page | 410 ms | 2 |
| All-off full reconciliation, five rectangles | 8.2 ms | 7 |
| Warm opened Source containers page bind | 11.1 ms | 7 |
| Warm opened Surfaces/global containers page bind | 39.9 ms | 7 |

A separate selection phase took 3,587 ms in `select` itself, 185 ms in the scripted
mount timer and 258 ms draining posted messages. This is a separate sample, not
a decomposition of the earlier 5,908 ms median. Reapplying unchanged native page
visibility/layout took 0.02 ms median warm. The evidence therefore points first
to host control construction/remount, rather than warm list binding or one warm
`UpdateLayout` call. Cold layout and individual control costs are not yet isolated.

With thirteen rectangles, one enabled global rectangle and increasing numbers of
simple box sources, the following unchanged refresh costs were measured. There
is also one original parked registered source row.

| Active synthetic source boxes | Full reconciliation, median of 5 | Labels/configure only, median of 5 | Unchanged leaf membership, median of 5 |
| ---: | ---: | ---: | ---: |
| 20 | 16.7 ms | 4.6 ms | 0.40 ms |
| 100 | 37.0 ms | 5.4 ms | 0.57 ms |
| 250 | 134.6 ms | 8.6 ms | 1.00 ms |

The opened layer Create handler caused four full refreshes per click; the global
handler caused three. Off creation/selection recorded zero scene membership
scans. Publication epoch, preparation and preview-build counters stayed unchanged
during the checked Manual creation/selection sequence.

A final pair of complete rectangle remounts took 4,296 and 5,601 ms with the
250-box pool pending. Placement fingerprint, publication epoch, membership scans,
native preparation and upload counters were unchanged. Native uploads stayed at
2 / 128,000 bytes; draw calls increased from 153 to 161. The delay therefore
persisted while the published buffers were reused.

## Current-source causes

1. **The rectangle carries the full Scatter editor.**
   [container-system.cjs](../AminScatter/tools/ui/container-system.cjs) copies the
   shared main panel and all twelve generated settings pages into the helper.
   The generated helper contains fourteen rollouts and 486 control/timer
   declarations, including labels and WinForms controls. This is a declaration
   count, not a count of native child windows. Closing a section limits binding
   through `bindSection`; it does not remove its rollout/control declarations.
   [approved-main-ui.ms](../AminScatter/tools/ui/templates/approved-main-ui.ms)
   mounts this editor each time the helper enters Modify. Source inspection and
   the slow `select` call with fast warm binds support this as the primary
   selection bottleneck. Per-control construction attribution remains open.

2. **Creation repeats global work.**
   `containerCreate` calls `containerAdd`, which invalidates every layer, redraws,
   calls `CyrusContainerRefreshAll` and binds the current editor. Creation then
   calls `CyrusContainerRefreshAll` again. A changed membership/configuration can
   call it again during redraw reconciliation. The actual handlers subsequently
   bind their component page too. See
   [unified-core.ms](../AminScatter/tools/ui/templates/unified-core.ms),
   `invalidateGroups`, `containerRefresh`, `containerAdd` and `containerCreate`.
   Three/four full passes were counted in the running opened-button probes.

3. **A full refresh revisits all registered controllers and rectangles.**
   [container-node.ms](../AminScatter/tools/ui/templates/container-node.ms),
   `CyrusContainerRefreshAll`, gathers linked containers and sources across
   `CyrusTimeOwners`, recomputes consumers/links, assigns movement ownership,
   checks overlaps and walks source hierarchies. It repeatedly copies
   `movementSources` arrays and performs linear membership searches inside
   model/container loops. Thus adding an inactive rectangle can revisit existing
   active pools. The measured 20/100/250-box ladder demonstrates growing cost
   even with simple geometry; it is not a heavy-mesh benchmark.

4. **Label refresh also prepares movement state.**
   `refreshTitles` calls `CyrusContainerRefreshLabels`, which calls `view.configure`
   for each matching rectangle. In
   [source_container.cpp](../AminScatter/src/source_container.cpp), the unchanged
   `cyrusContainerConfigure` path still calls `cache`, then `capture`: it validates
   hierarchy/controllers/transforms and creates transient weak observers.
   A changed label also recreates movement-unit/member observers. This adds
   movement preparation to browsing and label work. It measured much less than
   a full refresh in this fixture, so it is a secondary target here.

5. **Collection off already skips geometry enumeration.**
   `containerRefresh` uses an empty candidate list when there are no enabled
   frames. The helper's native drawing/hit test uses a four-corner outline and
   cached label. The checked all-off delay does not require loading source
   meshes or recalculating placements. When collection is enabled and the frame
   configuration changes, the current code can enumerate `geometry` per
   consuming leaf. That separate heavy-scene cost remains unmeasured.

Creation also requests the first receiver's world bounding box to position the
rectangle. Its cost on complex receiving stacks has not been isolated; it is
not established as the main cause by this investigation.

## Recommended correction order and acceptance

1. Reduce complete editor/control construction on rectangle reselection, while
   preserving the shared owner model and access to the same controls. Compare
   cold mount, complete reselection, opened-section bind and context switching
   separately. Do not treat warm bind improvements as fixing the seconds-long
   remount.
2. Coalesce creation/linking into one necessary reconciliation and one final UI
   update; invalidate only affected consumers. A new unused global rectangle
   should not require all-layer placement invalidation.
3. Separate cached label/presentation updates from movement ownership/hierarchy
   preparation. Reuse movement preparation until relevant membership, transform,
   hierarchy or controller state changes; retain the move-start safety checks.
4. Reconcile affected pools with less repeated array copying and consumer lookup.
   Measure multi-layer shared/global pools and grouped real plant sources before
   choosing a broader cache or scene-index design.

Relevant contracts are F01/F03 ownership/dependencies, F04 Manual/Live, F07 host
thread/lifetime and F08 shared UI/buffer reuse. Any future correction must preserve
source identities/settings, parking, global sharing, overlapping movement
ownership, Undo/Redo, collection-off behavior and the previous published Manual
result. Recheck zero solve/preparation/upload deltas during unchanged selection.
Neither implementation nor a version bump is part of this report.

## Identities, reproduction and limits

- Branch `codex/workflow-0.75`, HEAD
  `2b9ad12b24f9d91241db4567037f64db71fe9726`, with 25 pre-existing tracked
  modifications plus unrelated untracked design/research/knowledge drafts.
  Investigation fixtures and exact inspected-source hashes are in
  [source-inventory.json](../build/agent-review/source-containers-20261013-01/source-inventory.json).
- Generated script SHA256
  `803df45bb17ec88e9d15fcf42b130d5e5b55df93c1f7621131cfb2497f604d32`.
  Compiled-source and binary hashes were checked against the ordinary 0.81.3
  Max 2027 build receipt before private launch. Actual loaded module paths are
  in [loaded.tsv](../build/mcp-qualification/foundation-container-investigation-20261013-01/loaded.tsv);
  [launch.json](../build/mcp-qualification/foundation-container-investigation-20261013-01/launch.json)
  records the isolated profile and binary identities.
- The private probes used wrappers around existing global refresh/label functions
  to count calls and time their original bodies. Product files were not patched.
  [First probe](../build/agent-review/source-containers-20261013-01/probe_host.py),
  [corrected follow-up](../build/agent-review/source-containers-20261013-01/followup_host.py)
  and [native reuse check](../build/agent-review/source-containers-20261013-01/reuse_host.py)
  are preserved with their raw receipts in the private profile directory.
- The first probe stopped at an incorrect fixture rectangle index in its scaling
  phase. Its two closed-button calls and two closed-page binds were guarded
  no-ops, excluded from the findings. The follow-up opened/bound both pages,
  asserted real node additions and enabled the global rectangle; all nine
  follow-up checks and both native reuse checks passed. Failed/intermediate
  evidence is retained, not relabeled as a successful complete run.
- The stock foundation launcher rejected this build receipt's filename-only
  binary keys before starting a host. The owned local launcher preserved the
  same source/binary checks and used the receipt's actual native directory.
- Knowledge status and search returned `stale_evidence` for the selected v7
  generation; findings use directly inspected current source. No index refresh
  or enrollment was performed. Public Max inspection was unavailable; all
  executed measurements used the owned private process.
- No artist asset timing, physical pointer gesture, Max 2026 run, Live timing,
  renderer test, sustained-session test or GPU/presentation benchmark was run.
  These bounded measurements do not qualify the separate 0.81.3 performance
  corrections or close the historical cold Move/Undo gate B05.

To reproduce, use a fresh owned profile, the preserved matched native build and
the local launcher/fixtures. Invoke the probes through
`tools/foundation_validation/run.py` in sequence. Normal profiles and source
identities are rechecked in the local closure receipt. Local `build/` receipts
are ignored by Git; the report is the tracked summary.

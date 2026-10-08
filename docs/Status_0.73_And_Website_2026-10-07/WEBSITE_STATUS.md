# Cyrus Scatter 0.73 — website status copy

This copy is reconciled against the implementation and recorded evidence on 7 October 2026. It is suitable for the project status website; it does not announce a public release. Engineering evidence and source locations are in `DOCS_RECONCILIATION.md`.

## Where we are

Cyrus Scatter is a working development tool for building layered planting in 3ds Max. Version 0.73 brings the everyday workflow into ten compact sections, with less-used options under Advanced. The latest correction fixes a layer-button error that could occur when Max refreshed or closed its controls during the action.

The next priority is confidence in everyday artist work: reliable Undo, complete interaction checks, faithful materials and measured performance. Release readiness is still ahead.

Verify the dated build before testing. Several development packages share the 0.73 version label, and an installed copy may predate the latest correction.

## What works today

- Build planting with ordered layers and paint sets, choose source models, and control amounts, transforms, boundaries and spacing.
- Paint and erase coverage, use source containers to organize models, and refine supported individual instances.
- Work in Manual or Live mode and inspect the last completed result separately from settings waiting for an update.
- Use Point Cloud and Mesh previews that reuse unchanged data. Display budgets help keep large scenes manageable.
- Record a short local troubleshooting report directly in Scatter. Sharing with an assistant is a separate choice.
- Let an assistant inspect an allowed scene scope and propose a small planting setup for local approval. Current proposals are limited to three supported models, three layers and 2,000 requested candidates.

Recorded Max 2027 tests cover selected workflows, a real planting scene, large-scene preview behavior and Corona rendering. Each result belongs to its tested version. The latest compact interface and layer-button correction have their own narrower checks.

## What remains unfinished

- A first container-move Undo sometimes lost its history in the recorded artist test. Its cause is still unresolved.
- Source review also identified a possible interaction between pending Manual edits and Undo of an unrelated scene action. It needs a focused Max test; it is separate from the recorded container-history failure.
- Very large Proxy previews are expensive to draw. Large radii, projection and broad painted areas still need stronger performance limits.
- Seven material-map placeholders were already missing in the original scene's private test copy. That limits conclusions about visual fidelity.
- Every control, display scale, long working session and renderer combination has not been qualified. Max 2026 runtime remains unqualified.
- Assistant control covers a limited planting workflow. It cannot yet author the full local Brush, source-container, instance-editing or rendering workflow.
- A small offline preference experiment exists. There is no established product that learns an artist's style from reference images and finishes scenes automatically.
- The licensing foundation exists, but customer activation, complete enforcement, seats and recovery are not ready for commercial release.

## The next four stages

### 1. Make everyday artist work dependable

Finish the practical control walkthrough and isolate the first container Undo problem. Check source movement, parking and return, save/reopen, empty setups, different panel widths and display scales, and long rendering sessions. Resolve the missing-material questions in an appropriate test setup.

**Complete when:** tested gestures preserve the intended changes and Undo history; controls keep the correct layer and set selected; saved scenes reopen correctly; material limitations are resolved or clearly documented; and the supported Max/renderer combinations have named passing checks.

### 2. Improve the measured performance limits

Target costly Proxy drawing, projection, exceptional spacing radii and large Brush histories. Keep the existing Point Cloud and Mesh improvements intact.

**Complete when:** comparisons show a useful improvement on the same scenes, planting remains equivalent, memory and work stay within defined limits, and a failed update preserves the last complete result and painting history.

### 3. Broaden assistant help and troubleshooting

Add assistant actions in small groups based on real artist needs. Build a useful, user-controlled history of troubleshooting reports so a problem can be connected to the scene, settings and completed result that produced it.

**Complete when:** each new action has a clear scope, preview and approval, predictable Undo and recovery, and tests in Max; reports are bounded and searchable; and sharing remains an explicit choice. A list of controls alone does not count as assistant support.

### 4. Prove learning value and complete release readiness

Collect artist-approved comparisons only with explicit consent. Connect each comparison to its scene, sources, camera and finished result, then test whether suggestions improve on straightforward planting recipes. Learning experiments and commercial licensing have independent acceptance gates: a promising experiment does not complete licensing, and finished licensing does not establish learning quality.

**Complete when:** learning shows useful results on independent projects and artist review, consent can be changed, the intended authoring and rendering behavior survives licensing expiry and renewal, and supported installations pass the release checklist. No date is promised for this stage.

## Suggested page links

- **Learn the controls** — current artist reference.
- **See the latest correction** — layer-action fix and its evidence.
- **Read the test limits** — the frozen qualification findings.
- **Continue development** — the fresh-conversation handoff in this status package.

Avoid a public download or purchase promise on this status page. The current packages are development test deliveries, and the local status page is not evidence of hosting or publication.

# What the Forest brush suggests for Cyrus

Captured Cyrus Brush source was inspected in `AminScatter/include/brush.h`, `AminScatter/src/brush.cpp`, `AminScatter/src/brush_host.cpp` and the unified UI template. The three native Brush files still match the starting commit; the UI template and generated script changed concurrently as the repository moved to `codex/ui-0.74`. This comparison is source-level and does not qualify that evolving UI; historical test receipts were not rerun and Forest has no measured performance advantage here.

| Responsibility | Forest area brush, observed in this pass | Current Cyrus source |
|---|---|---|
| Input | Max Painter callbacks and configured receiving nodes | Max Painter callbacks; checks the target and re-hits the exact mesh snapshot for persistent anchors |
| Authoring data | Current closed contour shape, with Undo/Redo contour snapshots | Ordered stroke records with stable IDs, radius, strength, softness, erase state and samples |
| Space | Projected integer polygon paths in a Forest frame | Mesh face/barycentric anchors, captured transforms/view rays and connected-face patches |
| Repeated painting | Polygon region editing | Within a stroke, maximum dab influence; across strokes, ordered soft-field application |
| Softness | Area-boundary density/scale falloff is documented separately | Continuous 0–1 brush field using strength and smooth falloff |
| Derived work | Clipping, simplification, contour rebuilding and downstream scatter update | Ray resampling, per-dab face patches/reverse links, field evaluation and bounded overlay tessellation |
| Geometric interchange | Native conversion to/from scene splines | Saved native brush document; no equivalent contour-to-spline brush conversion identified in this source pass |

## Useful lessons, without replacing our current model

**Keep painted coverage separate from plant placements.** Both systems follow that broad responsibility boundary. Density, model choice and transforms should remain editable without repainting a region or destroying stable edits.

**Planar contours are a plausible optimization for large terrain regions.** Their cost is tied to contour complexity rather than replaying every historical surface dab. That is a hypothesis, not a benchmark. Intricate erasure and many islands can grow polygon complexity, while full-shape rebuilds can still be expensive. A contour strategy would need limits on vertices, operations, temporary memory and latency.

**Our surface-aware data preserves different capabilities.** Cyrus stores face/barycentric anchors, connected patches and visibility information; its source has strength/softness and editable stroke settings. A projected contour alone cannot express that same contract without additional information. Curved/folded surfaces, stacked sheets and thin geometry are decisive comparison cases. Do not silently convert the existing document model to a projected mask.

**Brush feedback and scatter publication need explicit scheduling.** Forest's selected callback publishes shape changes and requests downstream updates while painting. We have not measured its solve frequency. For Cyrus, inspect input capture, brush overlay, field rebuild and placement publication separately; preserve Manual pending edits and atomic failed-successor behavior.

**The immediate Cyrus issue is aggregate derived-memory admission.** The current source still resamples strokes and builds affected-face/reverse-link data without one total derived-memory bound. Existing authored-sample caps do not bound these expansions. This was already identified in the [current code review](../../Status_0.73_And_Website_2026-10-07/CODE_REVIEW.md); this research reconfirmed the source, not an out-of-memory failure. Forest's contour approach offers a comparison point but does not fix that issue automatically.

If a later planar-contour experiment is justified, [the original author's Clipper2 project](https://github.com/AngusJohnson/Clipper2) supplies independently obtainable polygon operations. It is not the exact library version identified inside Forest; no library was installed or integrated during this pass.

## Next controlled acceptance loop

Use an owned disposable Max profile/scene with a hash-pinned Forest and Cyrus pair. Preserve the artist session. Start with:

1. A flat receiver: repeated paint, erase holes, overlapping dabs, undo/redo/cancel, model/density changes and save/reopen. Check whether mask changes remain independent of source placements.
2. Rotated/nonuniformly scaled owners and receivers: compare ring, actual painted footprint and resulting area. iToo's [paint-transform knowledge base](https://docs.itoosoft.com/kb/forest-pack/when-i-use-the-paint-tool-the-items-are-displaced-in-relation-to-the-brush-strokes-why) documents a displacement issue; it is a test case, not proof the current build reproduces it.
3. Curved receivers, disconnected or stacked sheets, and X/Y/Z projected masks: check surface membership and unintended projection overlap. Distinguish UV mask application from brush authoring.
4. Fast drags, tiny/variable pressure, Ctrl/Alt switching and Update-on-Mouse-Up: establish actual interpolation, gaps, pressure semantics and the private operation mapping.
5. Long strokes/many islands on dense surfaces: record input latency, brush geometry/field rebuild, scatter rebuild, redraw and memory separately. Require equal visible populations for comparison.
6. Owner/area changes, panel close, session end and undo afterward: verify hold ownership, session cleanup, identity and persistence.

A product change would need a separate scoped implementation request. This research adds documentation and neutral helpers only.

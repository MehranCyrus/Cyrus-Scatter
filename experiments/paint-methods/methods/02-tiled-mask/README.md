# B — Tiled Density Mask

**Hypothesis:** a sparse projected mask provides inexpensive local edits and soft density, with predictable costs controlled by resolution. **Status: initial 0.1.0 slice built and tested.** [Results and remaining gates](../../results/0.1.0-2026-10-10/README.md).

The implemented slice uses 32×32 float tiles, projected addressing, a maximum-influence gesture stencil and copy-on-write Undo snapshots. Hard/soft paint, erase, cancel and external save/load exist. The border is derived by the common complete mesh preview, not dirty-tile marching squares; tile-local retained display and resolution conversion remain absent. It rejects spheres/folds. The brief below is the design target, not a claim that every extension exists.

## Representation and workflow

Save a receiver-local projection frame, fixed physical pixel size, tile coordinates and current grayscale values. Start with 64 x 64 CPU tiles and float values for clarity; measure before changing storage precision or tile size. Allocate touched tiles, not one huge image for the entire receiver. This is a projected mask, not a volume and not a full-surface UV atlas.

Rasterize the swept footprint into affected tiles. Hard Paint writes covered values to one; hard Erase to zero. For soft gestures, hold pre-gesture values and a maximum influence stencil, then apply the common formula. Repeated mouse events at the same point must not increase opacity merely because the machine samples faster. Commit changed tiles together; retain changed-block Undo data.

Weight queries use an explicit sampling rule. The first hard track uses a documented cell reconstruction and measures its boundary error. The soft track can use bilinear sampling with neighbor-tile gutters. Derived outlines use marching squares with a specified ambiguity rule and consistent tile edges. Display updates dirty tiles/chunks only; a dense full-plane re-upload would obscure the method's actual benefit.

## First usable slice

- Same plane, hard Paint/Erase and candidate set as A.
- Fixed resolution, dirty tile count, allocated/undo bytes, outline and fill toggles.
- Painting across tile edges and negative coordinates; one-gesture Undo/Cancel.
- No automatic resolution changes during painting.

Next: soft density, terrain projection and resolution conversion as an explicit destructive-to-detail operation with Undo, never a silent optimization.

## Why this could win

Queries read current values instead of searching history. Small edits touch small regions. It naturally represents varied density within an area and separates authored coverage from display tessellation.

## Risks and limits to expose

Large radius at fine resolution touches many pixels even with sparse allocation. Tiled storage does not make dense coverage free. Borders approximate geometry, small islands can vanish, and differing resolutions can make a misleading speed comparison. Memory reports must include undo snapshots, active stencils, gutters and upload buffers.

Like A, a single projection cannot independently paint overlapping parts of a sphere/fold. Adding an artist UV requirement would introduce seams and a different workflow; that is not part of this initial method. D tests surface-bound storage separately.

## Decision gates

- Error remains inside the declared boundary band across tile seams.
- Repeated same-area gestures do not increase warm query cost with history.
- Very large brushes and widespread detailed paint remain bounded without silently lowering resolution.
- Soft stroke results are invariant to equivalent trace sampling rates.
- Publish speed versus accuracy/memory curves, not one favorable resolution.

Implementation: [mask.cpp](src/mask.cpp), [generated window](scripts/Launch.ms), shared [native tests](../../tests/core_tests.cpp) and [Max tests](../../tests/host_tests.ms). See the [common plan](../../docs/IMPLEMENTATION_PLAN.md) and [tests](../../docs/TEST_PLAN.md).

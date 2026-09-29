# 12 — Area, Line, Street, and Edge Feature Composition

This document records how later features compose rather than treating them as isolated UI additions.

## Area Include/Exclude

Closed spline Areas are converted to loops in world XY. Includes form allowed unions; excludes subtract. Density-preserving mode can thin without refilling.

## Line Pattern / Analyzer strokes

The stroke system stores path references, widths, side/kind, assignment mode, source/color selections and per-stroke scale ranges.

Analyzer channels map to Border, Centerline, Points, Street Side and later Edge Border.

## Consecutive strokes

Rows have cumulative start/width behavior. Source assignment is performed on existing placements; surviving positions are not regenerated merely because a stroke source assignment changes.

## Boundary facing

Border/Street/Edge placements can orient a configured source forward axis outward. Corner radius/blend uses neighboring edge directions; hole loops face into holes.

## Edge Border

Edge Border is special because its base population comes from boundary spacing rather than ordinary scatter Count. Later stages add:
- inward local offset;
- along/across deterministic jitter;
- protected corner samples;
- per-row local XYZ rotation;
- blend radius.

Local offset is deliberately final translation after filtering/orientation, so it can move final instances beyond the original surface.

## Boundary falloff

Analyzer boundary can delete, scale and density-thin points. Per-Area falloff extends this to selected Area splines and stores graph/config data per Area row.

## Curve graph

The graph UI uses Max CurveControl and stores exact editable graph data; calculation samples the curve densely (repository guide says 257 samples).

## Analyzer Area

Independent mask using Analyzer centerline strips and/or point-radius disks in world XY. It filters generated positions and does not refill.

## Street layout

Street Side:
- trim start/end on connected open chains;
- straight/round ends remain separate behavior.

Centerline:
- world-XY offset relative to nearest Street Side segment;
- shared by Analyze Data and Surface Analyzer Area within a layer.

## Ordering matters

Current high-level order is base generation → Analyzer Area/falloff → source transforms → cross-layer overlap/final cleanup → orientation/local Edge offset → CS Edit.

Feature changes should preserve this order unless a deliberate visual compatibility break is accepted.

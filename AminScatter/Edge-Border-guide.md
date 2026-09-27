# Edge Border — 0.45

Choose Analyze Surface > Analyzer data > Edge Border. Add Edge Row generates one ordered row per boundary loop; Spacing controls the base population independently of Count / per-square-meter settings.

Offset inward is now a final local translation. Positive moves backward along the source's chosen Forward axis; negative moves forward. It does not resample, delete, rotate or change the scale of placements, even when the translated result extends beyond the surface. At Face outward corners, the existing blended/bisector orientation determines the translation direction. With Face outward disabled, the actual instance orientation determines it. Distance is in scene units and is not multiplied by source scale.

Each row has its own offset. Collision, area and surface filtering run on the base placements before this translation; changing Offset alone does not rerun those filters on the translated positions. CS Edit runs afterward.

Jitter along varies positions along the original boundary (capped below half a step). Jitter across adds inward variation before the final offset. Both are deterministic and independent of Offset. Zero jitter keeps the exact ordered base row. Boundary masks and a 500,000-point generation guard remain in effect.

This changes the meaning of existing nonzero Edge Border offsets: scenes retain the numeric setting but use local translation instead of resampling an inset contour. Save a separate scene copy if preserving the previous appearance is necessary.

## Keep corner points (0.46)

Enable **Keep corner points** in Edge Border. **Min turn** is the direction change in degrees: straight = 0, a right-angle turn = 90. Vertices meeting or exceeding the threshold are protected from normal spacing and jitter; both convex and concave corners qualify. Smooth, finely segmented curves are excluded by a larger threshold.

**Points/corner** defaults to 1 (maximum 64). One sample is exactly on the vertex. Additional samples alternate along its adjacent enabled edges, with distance limited by spacing and edge length. Nearby regular samples are suppressed to avoid duplicates. Street/boundary masks still apply. These controls are independent for each scatter layer, and affect its Edge Border rows only. The option defaults off for compatibility.

Corner placement is guaranteed in base row generation, before local Offset and CS Edit. Surface/area/density/collision filters still apply; the option does not override exclusions or reinsert deliberately deleted instances. Offset moves these samples along their final local forward axis and preserves their count. At the exact vertex, Face outward uses the bisector of neighboring edge directions.

## Local rotation (0.47)

Each Edge Row has independent **Local X/Y/Z (deg)** values. These rotate every instance in its own frame after Face outward/corner blending; they are not rotations about world axes. Zero preserves the original boundary-facing orientation. Nonuniform scale is retained and rotation alone does not move or resample points. Local Offset runs after local rotation, so a nonzero offset follows the adjusted local forward direction. Controls save with the row and stay aligned after removing a different row.

The reported left-edge reversal was not reproduced in the available saved Surface_analayzer_2.max: its source forward axis is +X, left-edge instance X bases point toward -X, and both MAXScript and native point-cloud transformations map a local +X test sample toward -X. No unverified orientation reversal patch is included in this release; the exact failing scene state is needed to diagnose it.

## Blend Radius (0.48)

In Edge Border, **Blend radius** replaces the previous **Corner radius** caption and retains its saved value. With Face outward enabled, points near either endpoint blend smoothly toward the neighboring-edge bisector. Both endpoint influences are considered when radii overlap. At the exact corner the bisector is retained; outside the radius the straight-edge direction is retained. Zero disables blending around vertices. Border and Street Side retain their existing Corner radius behavior.

This changes only orientation, not base placement positions or count. Local XYZ rotation is applied afterward. Nonzero local Offset then follows the final local direction, so its translated positions can change when Blend radius changes. This preserves the established local-offset behavior.

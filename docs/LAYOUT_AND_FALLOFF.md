# Layout, Analyzer and falloff details

Companion to the [current artist guide](ARTIST_GUIDE.md). These settings belong to the layer unless stated otherwise. This replaces scattered version-specific feature notes; dated test receipts remain in [history](HISTORY.md).

## Assignment and guides

**Planting positions** is separate from model assignment. Surface random uses Count/Density. Rectangular, Staggered and Hexagonal grids use physical spacing, a fixed world XY origin/heading and stable jitter, projecting to the highest surface hit. Masks and collision rules thin this lattice; disabled Count/Density/refill settings do not affect it. Hexagonal calculates row pitch from its nearest-neighbor spacing. Grids keep the source choices and Band curves below; Analyzer Single/EdgeRow cannot replace their positions. See [the grid workflow and limits](plans/improvement-program/I06_0850.md).

Random mix chooses among weighted models. Clusters choose assignment groups across space; grouping colors and viewport identification colors are separate. Spline Bands use closed Paths in world XY, explicit source/group choices and per-Band scale multipliers. Consecutive ranges use first-match ownership; Independent ranges combine eligible density contributions. A selected Paint Area does not supply a different model collection.

Spline bands accept model-free Point placeholders through **Models / Points** or **Assignment groups**. Use Models & Points > Add Point, name the row and choose it directly for each band. **Plant centres** displays one point per accepted placement; Points have no final mesh output until replaced with models. Saved row identities retain explicit choices through replacement, removal of another row, layer copy and save/reopen. See the [0.79.1 runtime checks](Point_Workflow_0.79.1_2026-10-11/README.md).

**Band Width is a world-space distance from the Path**, not its node scale, corner radius or diameter. Scaling a rectangle changes its outline but leaves a 200 mm Band 200 mm wide. Nonuniform scale and rotation transform the outline before distance is measured. Rounded corners use distance to the original border segments. Sharp corners use miter-limited prepared offsets, with explicit precision/work admission. Consecutive widths accumulate separately on each Path and side: two 200 mm Inside Bands occupy 0–200 and 200–400 mm strips, subject to earlier matches and masks. Empty/unassigned intervals still reserve their full width.

Independent ranges expose each Band's Start/End. Its contribution is strength multiplied by the sampled density curve, provided its sources have positive total weight. Sum eligible contributions, cap occupancy at one, then select an owner proportional to contribution and a source using its weights. Independent ranges and nontrivial density require Candidate budget. Accepted target cannot refill density rejections. A deliberately assigned Empty source participates in its source lottery and can still leave a gap; an unassigned Band contributes zero.

Density curve X is normalized progress from Start to End; Y is 0–100%. The shared evaluator consumes the saved sampled trace, including when checking allowed automatic movement. Movement validates the destination and existing intermediate checks; it does not promise continuous no-gap-crossing. Protected manual edits keep their explicit exception. The [design contract](plans/spline-bands/DESIGN.md) states the numerical tolerances and distinctions.

The Band graph opens with the full density range visible, even for a constant
curve. Opening and closing an unchanged graph preserves its recipe. A drag applies
on release; Manual placements remain from the last Update.

Preview Falloff shows the selected contribution or explicitly selected Combined density. Blue samples denote zero, red denotes one; unsampled surface is distinct from zero. Show Boundaries adds white clipped contours. Both describe the Band stage before other masks/spacing/cleanup, and sample/face counts disclose approximate coverage. In Manual, **Pending field; plants from last Update** separates current feedback from frozen accepted plants/radii. Selected Band identity is shared by the Scatter and source-container Modify views; display controls do not enter placement generation keys.

Surface Analyzer assignment consumes cached boundary, street-side, centre-line or point data from a separate Analyzer. It does not analyze a sphere as a planar mesh. Ordinary scattering on curved receivers is separate. Terrain Paint uses receiver-local XY; the surface-attached Paint path supports eligible manifold curved receivers. Neither turns the planar Analyzer into a general curved-surface analyzer. Selecting or updating an Analyzer is explicit. Assignment, Analyzer Area masks and boundary falloff have separate Analyzer references. A new Scatter calculation rejects out-of-date linked analysis and retains the previous complete result; Analyze first, then Update scatter in Manual mode. Unchanged cached reads continue to use the prior publication. Older saved guides need one explicit Analyze with the matching updated script.


### Band scale profiles

In **Layout**, find **Scale** directly below the density curve. Min/Max remains the random Band size range.
**Scale profile** selects **Off**, **Follow Density** or **Custom**; Custom enables
**Edit scale curve**. X runs across the Band from Start to End, not along the Path.
Y is a size percentage: 100% is unchanged, 50% halves size and 200% doubles it.
The profile multiplies the existing random Band size, source scale and layer
transforms once. Density and scale retain separate saved curves and Bezier handles.

Follow Density uses the effective density curve shape, excluding the Density %
strength. Disabling the density curve makes this scale mode flat 100%. Switching
modes preserves the stored Custom graph. Zero scale collapses the instance without
removing its candidate; use density to remove placements. Scale traces are bounded
to 2–257 samples, at most 64 authored graph points and 0–10000% size.

Scale-only changes retain base candidates and source/owner random channels.
Size-dependent spacing, protected edits and cleanup can change accepted output.
Auto Radius follows the final instance basis; Manual radius follows size only when
Follow Scale is enabled. A drawn radius does not enable its spacing rule.
Manual retains published plants and radii until Update scatter; Live schedules
relevant changes. Opening an unchanged graph does not alter the recipe.

Rounded Bands use the existing distance coordinate. Sharp Bands reuse density's
prepared coordinate, so scale edits cannot perturb its density lottery. Away from
reported boundary uncertainty, scale-profile error is bounded to 0.005 multiplier
before the other scale factors. A curve too steep for that coordinate fails with a
specific error and retains the previous complete result; simplify the curve or use
Rounded corners. No unbounded geometry refinement is triggered by size editing.

## Boundary and street controls

Border/Street Side Face outward uses the model's Forward axis (+Y, −Y, +X or −X). Corner blending changes orientation near adjacent edges. Hole boundaries face into the hole. These controls do not imply that all candidate positions survive later masks or collisions.

Edge Border generates ordered boundary rows using row spacing. Jitter along/across changes candidate placement. Keep corner points protects qualifying corners during base row generation, not from every subsequent exclusion. Min turn is the change in direction; straight is zero. Points/corner adds a bounded set of corner samples.

Edge-row Local XYZ rotation changes the local orientation. Its final local offset follows the chosen forward direction; positive inward goes backward along that axis. It does not mean resampling an inset contour or guaranteeing that translated geometry stays within the receiver. Blend radius changes facing; nonzero local offsets can therefore move the final position when facing changes. Keep on surface and other eligibility settings have their own pipeline roles.

Street Trim start/end shorten connected street chains; traversal direction comes from the Analyzer boundary, not screen left/right. Closed loops have no endpoints to trim. Centre-line Street offset is a world-XY shift relative to the nearest street segment: positive away, negative toward. A nonzero value requires street data. It does not modify the Analyzer publication; assignment and Area share the layer's saved centre-line offset.

The 0.86.8.3 Max 2027 delivery admits dense Band Paths through bounded native
clipping and queries. Its ceiling is 8,192 total sampled vertices across unique
Paths; several Bands sharing a Path do not duplicate that input count.
Construction, queries and outlines retain separate limits. A rejected successor
retains the previous complete result. Painting > Export spline can optimize an
independent planar boundary within a world-unit tolerance while preserving the
original Paint. See the [delivery and limits](plans/refinement-program/DELIVERY_08683.md).

## Masks and falloff

Include/Exclude splines use world XY. Include domains union; Exclude takes precedence. This tests placement support/pivots, not trimmed plant geometry. Analyzer Area can combine centre-line bands and point-radius discs as a union. Full width describes the complete band width; flat/round ends control its caps. Point radius here is independent of model collision radius.

New Area links default to Include and select their new row automatically. **Selected area mode** follows the highlighted rows; mixed selections show neither mode selected and label the mixed state. No selection disables the mode control. Boundary falloff target, width and separate Scale/Density graph buttons are visible without Advanced. Disabled effects disable their width/graph controls. The [25 point-only inspection examples](Container_and_Radius_0.78.3_2026-10-10/AREA_EXAMPLES.md) exercise these distances, masks, falloffs and Analyzer combinations in Max 2026.

Choose Analyzer Boundary or exactly one Area spline as a falloff target. Each line retains its own settings. Delete width removes an edge strip. Scale and density ramps start after that strip when deletion is enabled; width and graph shape are separate controls. Density thins rather than promising a full count; accepted-target retries are a separate bounded setting.

The native curve editor stores the editable control points/tangents and derives sampled calculation curves. Graph changes commit immediately; Close is not Cancel. X is normalized ramp distance, Y is percentage. Density is clamped to its allowed range; scale can exceed 100%. Beyond the ramp width the endpoint value applies. Multiple enabled falloffs can accumulate deletion and multiply scale.

Area-line falloff follows its inside/outside world-XY domain. Analyzer falloff uses its full published boundary, including holes; a Street Side selection is not a replacement boundary. Manual Analyzer must be analyzed explicitly, and Manual Scatter still requires its own Update.

## Edit and preview distinctions

CS Edit targets stable candidate/source identities. Missing source histories remain
inactive and are not silently remapped by row index or source name. In 0.86.9,
removing a source preserves compatible surviving edits and recoverable inactive
history; incompatible generation or receiver changes remain guarded. Handle
colours follow Model/Layer/Bands, and drawing, picking and gizmos use the final
displayed placement. Current schema 59 supports an explicit Undoable upgrade from
58; earlier development-scene formats remain retired. Native Edit storage 2 has
its own supported legacy reader and downgrade guard, so preserve originals and
save upgraded copies. Whole-object Copy of clone-dependent Edit stacks or
clone-targeted radius overrides remains limited by [B37](BACKLOG.md#edit-instance-findings--0869).
See the [current delivery](plans/edit-instances/DELIVERY_0869.md) for exact tests
and the asset-pivot finding; the tree was not automatically recentered.

Point Cloud, Proxy and Mesh change preview representation and budgets, not the accepted output population. Mesh uses evaluated viewport geometry and preview coloring; it is not a guarantee of final renderer material/texture fidelity. Color by Bands follows accepted owner IDs. Auto Radius bounds supported geometry around the pivot using each final instance basis, without translation or a second scale application. Published XY/3D radii are selected per spacing rule; the radius display selector is independent. Points, Empty and unqualified source types remain Manual. Radius overlays are simplified collision bounds, not exact mesh collisions. A Point placeholder and an Empty choice have different placement/output semantics.

Current implementation anchors: [controller and adapters](../AminScatter/tools/ui/templates/unified-core.ms), [native sampling/orientation](../AminScatter/src/scatter.cpp), [host bridge](../AminScatter/src/max_bridge.cpp), [ordered acceptance](../AminScatter/src/procedural.cpp). Use [the backlog](BACKLOG.md) for combinations still awaiting artist or stress qualification.

Current distances use typed world-unit storage. Current-schema load/merge/rescale evidence and limitations are in [implementation progress](plans/spline-bands/PROGRESS.md). Native Paint/Edit geometry bindings still require the saved units when conversion changes the bound receiver geometry; preserve original scenes. The historical serialized-distance failure predates the typed repair and is not the current field representation.

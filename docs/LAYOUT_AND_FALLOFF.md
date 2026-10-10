# Layout, Analyzer and falloff details

Companion to the [current artist guide](ARTIST_GUIDE.md). These settings belong to the layer unless stated otherwise. This replaces scattered version-specific feature notes; dated test receipts remain in [history](HISTORY.md).

## Assignment and guides

Random mix chooses among weighted models. Clusters choose assignment groups across space; grouping colors and viewport identification colors are separate. Spline bands use closed guides in world XY, ordered inside/outside bands, explicit source/group choices and per-band scale ranges. First matching band wins. A selected Paint Area does not supply a different model collection.

Surface Analyzer assignment consumes cached boundary, street-side, centre-line or point data from a separate Analyzer. It does not analyze a sphere as a planar mesh; curved Brush painting is a different operation. Selecting or updating an Analyzer is explicit. Assignment, Analyzer Area masks and boundary falloff have separate Analyzer references. A new Scatter calculation rejects out-of-date linked analysis and retains the previous complete result; Analyze first, then Update scatter in Manual mode. Unchanged cached reads continue to use the prior publication. Older saved guides need one explicit Analyze with the matching updated script.

## Boundary and street controls

Border/Street Side Face outward uses the model's Forward axis (+Y, −Y, +X or −X). Corner blending changes orientation near adjacent edges. Hole boundaries face into the hole. These controls do not imply that all candidate positions survive later masks or collisions.

Edge Border generates ordered boundary rows using row spacing. Jitter along/across changes candidate placement. Keep corner points protects qualifying corners during base row generation, not from every subsequent exclusion. Min turn is the change in direction; straight is zero. Points/corner adds a bounded set of corner samples.

Edge-row Local XYZ rotation changes the local orientation. Its final local offset follows the chosen forward direction; positive inward goes backward along that axis. It does not mean resampling an inset contour or guaranteeing that translated geometry stays within the receiver. Blend radius changes facing; nonzero local offsets can therefore move the final position when facing changes. Keep on surface and other eligibility settings have their own pipeline roles.

Street Trim start/end shorten connected street chains; traversal direction comes from the Analyzer boundary, not screen left/right. Closed loops have no endpoints to trim. Centre-line Street offset is a world-XY shift relative to the nearest street segment: positive away, negative toward. A nonzero value requires street data. It does not modify the Analyzer publication; assignment and Area share the layer's saved centre-line offset.

## Masks and falloff

Include/Exclude splines use world XY. Include domains union; Exclude takes precedence. This tests placement support/pivots, not trimmed plant geometry. Analyzer Area can combine centre-line bands and point-radius discs as a union. Full width describes the complete band width; flat/round ends control its caps. Point radius here is independent of model collision radius.

Choose Analyzer Boundary or exactly one Area spline as a falloff target. Each line retains its own settings. Delete width removes an edge strip. Scale and density ramps start after that strip when deletion is enabled; width and graph shape are separate controls. Density thins rather than promising a full count; accepted-target retries are a separate bounded setting.

The native curve editor stores the editable control points/tangents and derives sampled calculation curves. Graph changes commit immediately; Close is not Cancel. X is normalized ramp distance, Y is percentage. Density is clamped to its allowed range; scale can exceed 100%. Beyond the ramp width the endpoint value applies. Multiple enabled falloffs can accumulate deletion and multiply scale.

Area-line falloff follows its inside/outside world-XY domain. Analyzer falloff uses its full published boundary, including holes; a Street Side selection is not a replacement boundary. Manual Analyzer must be analyzed explicitly, and Manual Scatter still requires its own Update.

## Edit and preview distinctions

CS Edit targets stable instance identities. Suspended/missing identities are not silently remapped by row index. Generation changes can invalidate a binding; preserve the scene before clearing edits. Old 0.39/0.40 migration instructions do not apply to the current stable-only storage.

Point Cloud, Proxy and Mesh change preview representation and budgets, not the accepted output population. Mesh uses evaluated viewport geometry and preview coloring; it is not a guarantee of final renderer material/texture fidelity. Radius overlays are simplified collision footprints. A Point placeholder and an Empty choice have different placement/output semantics.

Current implementation anchors: [controller and adapters](../AminScatter/tools/ui/templates/unified-core.ms), [native sampling/orientation](../AminScatter/src/scatter.cpp), [host bridge](../AminScatter/src/max_bridge.cpp), [ordered acceptance](../AminScatter/src/procedural.cpp). Use [the backlog](BACKLOG.md) for combinations still awaiting artist or stress qualification.

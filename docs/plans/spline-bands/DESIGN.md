# Proposed behavior and implementation contracts

Status: recommended design, not implemented. Decisions below consolidate the user requirements and independent Astra audits. Numerical admission values are proposed starting limits that must pass the validation gates; they are not measured capabilities.

## 1. Ownership and scope

| Owner | Saved authoring data | Derived/display data |
|---|---|---|
| Layer | Existing amount, seed, receivers, sources, spacing; one Spline Band arrangement mode | Candidate schedule, prepared fields, complete publication |
| Path | Stable local ID, node reference, Rounded/Sharp setting | Sampled world-XY geometry, topology, offset/index caches |
| Band | Stable local ID, path ID, side, width or independent start/end, source-selection mode and selections, density strength, curve enable/data, scale min/max, identification color | Resolved interval, active/empty status, source membership, field contribution |
| Source row | Existing stable ID, weight, base scale, Z Offset, group membership; Manual/Auto radius mode and Manual settings | Validated geometry bounds, effective XY/3D radii |
| Editor/display | Selected identities, Color by choice, Preview Falloff and Show Boundaries, radius display metric | Cached labels, palette, overlay snapshots; no placement ownership |

Use the existing layer records and parameter registration. Do not introduce new scene nodes per Band, an independent population per Band, a general graph engine, GPU placement computation, or a new collision framework. Surface Analyzer remains an independently versioned product; shared UI and transport changes require its regressions, not adoption of these spline features by default.

Band/path IDs are immutable within a layer namespace. Deleting or reordering rows changes labels, not surviving IDs. A copied layer has a distinct address namespace but copies its internal IDs and random recipe, so its initial pre-spacing distribution remains identical. Specifically, preserve the existing copied `randomSeed`/`procSamplingSalt`, receiver keys and local Band/source IDs; the new layer namespace is not an RNG input. Spacing between the original and copied layers may then change their accepted outputs. Duplicating a Band in the same layer allocates a new ID. Never use names, list positions, scene handles alone, or offset-contour indices as durable identities.

## 2. Ranges and empty intervals

**Consecutive** is the existing default. Resolve widths in authored order, independently for each path and side, before resolving sources. Widths 100/250/1000 produce 0–100, 100–350, 350–1350. An unassigned or all-zero-weight middle Band leaves 100–350 empty. Deleting that Band explicitly removes its width and shifts successors; merely unassigning models does not.

Consecutive classification retains the existing global authored-band precedence where different paths intersect. A matching empty Band reserves its interval and produces nothing; it does not fall through to a later row/path. At a shared distance boundary the nearer, earlier interval wins, matching the existing inclusive-end priority. A point exactly on the original spline follows the existing Inside boundary convention; Outside excludes that boundary.

**Independent** allows each Band to store `0 <= Start < End`; all eligible Bands across the layer's Paths may contribute. Explicit endpoints participate according to the common geometric tolerance and side predicate. At a shared independent endpoint both contributions are eligible. Every candidate is emitted at most once. Row reordering is presentation-only in this mode; selection uses canonical stable-ID order.

Switching Consecutive to Independent copies the current resolved intervals. Switching back is lossless only for ordered, contiguous intervals. Otherwise show the proposed consecutive intervals before an explicit conversion action, with one Undo operation; never silently discard offsets/overlap during a radio change.

New Bands use direct Models/Points with an explicit empty selection and a visible “Choose models” state. Changing assignment mode is not model selection. Preserve the user's stored direct and group selections when switching modes. Explicit source membership must distinguish empty from legacy group fallback. Missing sources and zero-weight selections have zero contribution. An intentional Empty/gap source with positive weight remains a lottery outcome that removes the chosen placement without redistributing its probability.

Missing Path nodes retain their authored records and display “Missing / inactive”; no same-name auto-rebinding. Explicit Update removes their contribution. In Manual mode, the last published plants remain until Update. Invalid geometry in a still-active Path is a preparation failure, not permission to publish an unrelated or partially valid result.

## 3. Density and source mixture

For Independent mode, for candidate position `p` and Band `i`:

```text
a_i(p) = support_i(p) * strength_i * curve_i(t_i(p))
         when its source lottery has positive total weight; otherwise 0
S(p)   = sum(a_i(p))
P(p)   = min(1, S(p))
```

Strength is 0–100%; the evaluated density curve is bounded to 0–1. Disabled curve means constant 1. Source weights determine the conditional choice within the selected Band; their total magnitude does not secretly multiply Band strength.

Curve X is `t = clamp((q - Start) / (End - Start), 0, 1)`: zero at the nearer range boundary and one at the farther boundary, increasing outward for Outside and inward for Inside. Reuse `fallCurve`'s uniformly sampled piecewise-linear representation. Admit 2–257 finite samples in [0,1]; the graph adapter writes 257 samples and preserves bounded editor handles separately. Reject invalid native payloads; UI evaluation constrains density to [0,1] and shows the applied sampled trace so Bezier overshoot or sub-sample detail is not misrepresented as solver behavior. Bound saved editor control points to 64, validate finite handle data, and retain endpoints at X=0/1. For n samples the slope bound is `L = (n-1) * max(abs(adjacent sample differences))`. Solver and field preview consume these samples, not separate Bezier implementations.

1. Compare one stable occupancy variate to `P`. Zero rejects, one passes.
2. If accepted, choose one owner Band with probability `a_i/S`, traversing canonical stable IDs.
3. Choose one source using the positive weights in that Band; retain intentional Empty outcomes.
4. Apply that owner's scale range using an independent stable variate.

Below saturation each Band contributes its specified probability. Above saturation they share the fixed candidate capacity proportionally. For example, Sphere 100% plus Box 25% gives 80% Sphere / 20% Box in the overlap, while Box alone remains 25% occupancy outside it. This meets the requested mixed, sparse continuation; it is not a guarantee of two independent absolute populations or exact per-Band counts.

Consecutive mode first resolves its single geometric owner, including empty intervals, then applies that owner's density. It does not fall through after density rejection.

Random channels for occupancy, owner, source, and scale are independent and use the existing effective seed (including population sampling salt), receiver salt and canonical candidate key. Address namespaces are not random recipe keys. Source sampling order uses stable source IDs for the new independent path. Preserve the existing flat Consecutive decisions where required by the baseline oracle; document intentional changes separately. Increasing the candidate budget must retain common candidates' positions/transforms and keyed decisions before shared spacing effects. A change in a competing Band's contribution may legitimately change the selected source while leaving position and candidate identity stable.

**Population rule for this delivery:** Candidate budget supports both Count and plants/m². Existing masks, density maps, Paint Areas, and Area falloff remain separate gates and apply once at their documented pipeline stages. New Band density is an additional deterministic thinning factor. No refill may compensate for it.

The advanced **Accepted target** policy is rejected for Independent mode or any active Band with nontrivial strength/density curve. Validate before candidate preparation/publication, explain “Band density requires Candidate budget,” and retain the previous result. Do not silently switch the user's policy. Existing flat Consecutive Accepted-target behavior remains available. Preserving an exact total while redistributing a varying density field would be a separate sampling feature; a global target reduced by average density does not solve its spatial bias.

## 4. Geometry and Sharp progress

Widths are world distances in the existing top-down XY projection. Transform the sampled path into world space before distance/offset calculations. Receiving-surface Z determines placement height, not Band distance. Several receivers at the same XY may independently receive instances; no new terrain-only receiver restriction is introduced.

Bands classify placement centers/pivots. A large model may extend across a Band boundary; Auto Radius controls spacing between instances and does not inset or clip the Band to contain the entire model. Whole-model boundary containment is outside this workstream.

Prepare one sampled path per relevant geometry/transform/time revision, shared by its Bands. Preserve linear knot corners. Bound curve tessellation error and count, preserve the baseline Rounded sampler until an intentionally tested sampling change is adopted, and never resample the same source spline once per Band. Reject degenerate projected paths and non-finite coordinates.

**Rounded:** retain Euclidean closest-segment distance with the existing side containment. Resolved Start/End makes the interval explicit. Build/reuse a segment index when justified by the measured path sizes; a rectangle does not need a large spatial structure.

**Sharp:** reuse vendored Clipper2 with Miter joins and limit 2; acute tips use the library's Square truncation. Normalize the sampled filled region using **EvenOdd**, preserving the existing spline fill interpretation, then orient outer loops/holes consistently for offsets. Do not reuse Brush's NonZero normalization blindly. Resolve intersections through this explicit fill rule, discard genuinely zero-area components with a visible status, and fail if normalization cannot produce valid bounded geometry. Disconnected components, holes, splitting, and inward collapse are ordinary geometric outcomes. Never use output path order as identity.

Prepared start/end offset regions define support relative to the sampled polygon and declared numerical tolerance. Outside support is the outer expanded region minus the inner expanded region; Inside support is the less-eroded region minus the more-eroded region, with the boundary tie policy above. Derive broad-phase bounds from prepared contours: simple `original bounds + width` is insufficient for arbitrary miter extension.

For Sharp curve progress, use the **offset level at which membership changes**, not Euclidean distance and not `distance-to-start / sum-of-boundary-distances`. Those alternatives can clip miter corners or become undefined after inward collapse.

Cache nested intermediate offset regions per unique path/side/join and offset. Every authored endpoint must be a level. Binary-search containment to bracket offset coordinate `q`; use a bounded approximation within that bracket. Successful empty inward levels are valid sentinels. Check Clipper's error status separately: empty output after a failure is not successful collapse. A collapsed start interval can have no support; a collapsed end still allows valid partial progress before collapse.

Accuracy is a release gate:

- Declare world-space polygon/tessellation/quantization tolerance in system-unit-aware terms. Translate to a local XY origin before integer scaling to avoid unnecessary large-coordinate loss.
- Bound and report the numerical uncertainty zone, including intermediate contours. It must remain small relative to admitted Band widths; reject a width/precision combination whose uncertainty would make the accuracy criterion vacuous. P0 records this maximum ratio with the physical tolerance and aggregate budgets.
- Bound `q` error by the bracket width. For band width `w` and sampled-curve slope bound `L`, contribution error is bounded by `strength * L * error(q) / w`, plus declared geometric tolerance near boundaries.
- Initial targets away from the boundary tolerance zone: normalized progress error at most 1/256, and aggregate absolute contribution error `E = sum(abs(a_i - approximate_a_i)) <= 0.005` over potentially eligible Bands at a query. Use a conservative allocation such as `0.005 / K` for K potentially eligible Bands, or a demonstrably tighter shared-field bound. This implies occupancy error at most 0.005 and each Band's unconditional emitted probability error at most 0.01 (bounded by its own contribution error plus E), including crossing the saturation threshold. Conditional mixture `a_i/S` is ill-conditioned near zero and is not promised the same error. Adapt levels for narrow intervals/steep curve segments; merely choosing 64 levels or allowing .01 error independently in every overlapping Band is insufficient.
- Validate nesting within tolerance, curve extrema, and topology transitions. Containment near an intermediate contour must widen/refine the certified q bracket or fail admission; a wrong binary-search branch cannot be hidden by checking only the start/end outlines. The aggregate error allocation covers every potentially contributing Band and assumes the exact validated source weights. Reuse identical levels. No Clipper operation is allowed per candidate or per viewport draw.
- Cap input/output vertices, aggregate levels, indices, query visits, and memory including staging. If quality does not fit, fail with an actionable complexity message; do not silently round corners or lower precision.

The exact admitted level/vertex budgets must be recorded after the Phase 0 prototype. This is a measured engineering gate, not permission to introduce an unbounded cache or a straight-skeleton subsystem.

## 5. One evaluator and provenance through the pipeline

Create one small prepared spline evaluator returning support, normalized progress, contribution, and stable owner-selection inputs. Generation, automatic movement validation, and the field overlay use it. Do not implement separate UI and native interpretations of the same curve.

Each generated placement retains its selected Band key separately from its candidate key. A publication owns an immutable mapping from compact native keys to stable Band/Path/source identities and display metadata. No dense candidates-by-bands table is required; stream local contributions and cache the path coordinate only where its reuse is measurable.

Before choosing the transport representation, inventory all strict row readers. Raw rows currently use 2/5 fields; post-Edit rows use a different convention, and protection is sometimes detected by exactly four fields. The implementation milestone must choose and document **one versioned internal row contract**, with named parsing/copy helpers and explicit owner/protection fields for each stage. Extend every affected producer and consumer in the same milestone; do not append one field and rely on `count >= n`. Preserve renderer-facing transform/source output at its existing external boundary. A keyed immutable sidecar is acceptable only if the inventory demonstrates a smaller complete implementation, including clone IDs and atomic publication; it is not a second concurrent source of truth.

Audit generation, receiver concatenation/offsets, transforms, Whole Scale, Brush, Area falloff, Analyzer orientation transport, Edit stacks/clones, radius resolution, spacing, cleanup, publication, point samples, Mesh/Proxy fallback, exact output/export and save/reopen. Numeric native workers consume copied data only.

Automatic Relax/final movement retains the selected owner. At the proposed destination, reevaluate **both** the original occupancy and owner variates and reject a move that fails occupancy or chooses another owner. Do not reroll, silently exchange models, or rely on `a_owner > 0`. This delivery promises destination validity, not continuous no-gap-crossing along the displacement; retain existing additional checks, but eight samples are not a proof for arbitrarily thin gaps. A stronger guarantee needs a separately qualified bounded segment-crossing check. Protected manual Edit overrides retain their explicit existing exceptions and original provenance; clones inherit provenance with a new output identity.

## 6. UI and graph lifecycle

- Paths becomes a compact scrolling list. Show name, Band count and inactive/missing state; restore selection by ID. Place Add closed line and Remove adjacent, with icon, tooltip, keyboard name and enabled state.
- Keep the Band list. Each row shows its swatch, side/index, resolved range and empty/inactive status. Add Outside, Add Inside and Remove share one row. The selected Band exposes its range/width, density and model selection clearly.
- Models/Points remains the main source-editing location. Extend the existing owner-drawn swatch list to `Name | Weight | Out 1`. Use compact multiple-membership text and a tooltip with Path, full range and direct/group origin. Do not add RGB/color names. Clicking a membership navigates to its Path/Band without changing assignment; ambiguous multiple memberships get a chooser.
- Label assignment as “Models used by this Band.” Direct Models/Points is the default for new Bands; Groups remains available for reusable source sets. Group edits update every dependent Band. Group-key colors remain distinct from identification colors.
- Band scale min/max remains an additional per-placement multiplier. Put it in an Advanced disclosure with an explanation; do not add a new per-source scale-range feature in this workstream. Source base Scale and Weight remain where they are.
- The existing curve editor is reused with an explicit Band target adapter. Capture controller/layer/path/band IDs when opening; resolve that target on every write. Deletion, Undo, scene reset/open, or owner changes must not redirect edits to the currently selected row. Define Apply/Done/Close and coalesce a drag into one understandable Undo transaction; closing a stale editor performs no write.
- Existing setups keep their assignment selections. Source/Path replacement never matches solely by displayed name. List membership reflects authored assignment, not whichever models happen to survive spacing.

## 7. Viewport, field preview, and Manual state

`Color by Bands` colors each accepted placement using retained provenance. Geometry and materials used for rendering are unaffected. Source geometry stays shared; do not create a copy for every Band×Source pair. Point samples inherit their placement's owner. Split immutable geometry, transforms/point positions, owner streams and palette/style resources only as needed for this path. Palette edits replace color/style resources without mutating a material still used by an older drawing generation.

Placements from another layout with no Band owner use a neutral, labeled “Unbanded” color when this controller-wide display mode is selected. Do not infer a nearest Band or treat a missing required owner key as this legitimate no-owner sentinel.

Add `Preview Falloff` and `Show Boundaries` as separate display toggles. Default field view is the selected Band's contribution; an explicit combined view shows `P(p)`. Use bounded colored samples on actual receiver surfaces plus admitted boundary lines and a 0–100% legend. This is the **Band density stage, before spacing/cleanup and other independent masks**, not a count of final plants. Zero contribution must be visually distinguishable from an unsampled region. Selected and combined modes must be labeled.

Sampling is a visualization approximation. Use the same scalar evaluator as generation, clip samples to receivers, preserve narrow Band outlines even when filled samples are sparse, and disclose when a display budget limits coverage. Do not project only to the highest receiver or borrow Brush's terrain-admission restrictions. Z-fighting offsets are display-only and do not change candidate positions. Preview samples never inflate placement/shown counts.

The current retained interface permits 20 cache entries for ten populations × preview/radius and 1,024 nonempty groups. Integrate overlays into a bounded per-population display bundle, or deliberately revise that interface and accounting together. Do not append arbitrary per-Band caches or multiply render groups by Band count. Account for owner/palette/overlay bytes, all layers, staged generations, and fallback resources against the existing point and Mesh reservation limits.

Manual has separate authored and published epochs:

- Plants, accepted owners, radii and published field metadata remain from the completed epoch until Update.
- Color edits for existing IDs may recolor published owners. Deleting an authored Band does not erase its published metadata before Update.
- A field preview of edited settings is labeled **Pending field; plants from last Update**. Toggling its visibility does not publish those settings.
- Source geometry/bounds must have an explicit revision. Prefer an already cached representation from the published revision. If a requested uncached display mode would require reading changed live source geometry, keep the current complete preview and show that Update is needed; do not silently combine new geometry with old Auto radii. Unchanged sources may prepare an additional display representation after revision verification without solving placements. Do not retain an unbounded full mesh solely for hypothetical mode switches.
- Live coalesces relevant curve/geometry changes and publishes only complete successors; unrelated selection, time changes outside validity, orbiting, or window movement do not solve placements.

CPU stage retention and GPU failure are distinct. Validate complete fallback drawing and owner/palette epoch agreement after new allocation/upload failures. If current native publication cannot safely support the new resources, fix that specific lifetime/commit defect before shipping the mode. Do not claim general device-loss certification from a successful CPU stage test.

## 8. Auto Radius

Manual retains existing radius, Follow Scale and stable instance override semantics. Auto is explicit per source and always follows final instance dimensions; disable the Manual Follow Scale control with “Auto follows instance size.” Preserve the saved Manual settings for switching back.

For supported mesh-convertible sources, extract **face-referenced geometry** once per relevant geometry revision in the same pivot-local convention used for scatter geometry. Unused/orphan vertices do not enlarge the planting bound. Cache its finite AABB and eight corners. Evaluate on the host thread; pure corner arithmetic can consume copied data.

After source scale, layer/band/falloff scale, normal alignment, rotations and Edit transforms, transform the eight corners by the final placement's linear basis, excluding translation:

```text
rXY = max(hypot(corner.x, corner.y))
r3D = max(length(corner))
```

This conservatively encloses the transformed AABB around the instance pivot, including off-center pivots, tilt and shear. Do not center the bound on the box midpoint and do not apply `transformScaleBound` again. Manual produces its existing effective scalar in both slots. Absolute instance overrides set both slots; multiplier overrides scale both.

Extend the procedural Sample/publication radius data to this pair. Choose the metric separately for self-spacing and **each** external rule's own/blocker arrays using its XY/3D setting. The existing group-spacing algorithm remains. Show Radius uses the published pair with a display-only XY/3D selector; 3D uses a sphere representation, such as three orthogonal rings.

Point and Empty rows have no geometry-derived radius: Auto is unavailable and Manual settings are preserved. Empty sources remain gap tokens. Missing geometry, no referenced vertices, a singular source-node transform needed for extraction, non-finite data or failed evaluation produces an unresolved source state and retains the previous completed result if that source is required; never silently substitute zero radius. Finite planar/linear/degenerate bounds remain valid: a genuinely collapsed bound at the pivot, or a finite final placement basis collapsing it there, produces an explicit zero radius. This is distinct from failed extraction.

A source is required when it has positive weight in an active source lottery capable of emitting placements, before random sampling. Band layouts additionally require a potentially nonzero Band contribution; other layouts use their existing active source-selection rules. A lucky seed producing no instances does not qualify invalid bounds. Unassigned, zero-weight or explicitly inactive source records may remain dormant without blocking an unrelated solve.

Renderer proxies need a declared capability. For a proxy whose evaluated viewport mesh is not the full scatter geometry, Auto remains unavailable until a bounded, non-mutating full-geometry/bounds route is qualified for that proxy type. Corona's current render-copy workaround is evidence of this mismatch, not automatic qualification. Manual radius remains usable. Initial supported-source tests must explicitly include or exclude each proxy type.

Auto is a conservative bound, not mesh-to-mesh collision. An asymmetric source or off-center pivot may leave extra space. Source bounds invalidate on relevant modifiers/animation/object offset changes; Manual defers acceptance changes until Update and Live follows the existing relevant-dependency path. Navigation never evaluates source meshes.

## 9. Persistence, units, and failure semantics

Include saved fields in parameter/tab registries, copy/removal functions, Undo, scene serialization, dirty signatures, diagnostics and publication metadata. Cache-only contours, indices and derived bounds are reconstructed from versioned inputs, not treated as authored data. Display colors/selections are excluded from placement keys; assignment-group changes remain solver dependencies.

The current schema is 55. Select the next unused schema/payload versions when implementation begins and update generated scripts/native bridge as one matched package. Provide a narrow, validated initialization from current schema 55: preserve existing source/group selections, widths, ordering, scales, seeds and Manual radii; assign stable Path/Band IDs once; default to Consecutive, Rounded, density 100% with the curve disabled, Manual radius and hidden overlays. Preserve node/row identities and do not overwrite the original scene. Empty-interval correction is an explicit behavior fix, not a promise of identical buggy output. Conversion must pass the units, copy and reopen oracles before it is enabled. Malformed 55 records fail without guessed assignments. Earlier retired development formats remain rejected and require their matching old build; no general compatibility layer is introduced.

Resolve the existing B14 units issue for all touched distances: widths/start/end, Auto bounds, Manual radii, world radius overrides and Z offset. A world-unit spinner over a serialized float does not establish unit safety. Curve X is dimensionless normalized progress. Saved physical distances must survive supported load/merge/rescale paths with explicit conversion exactly once.

Validation or bounded-work failure leaves the last complete calculation/publication intact and provides a cause tied to the affected Path/Band/source. Missing optional inactive records are not malformed active geometry. No partial layer result, silent precision downgrade, automatic reset, or hidden setting substitution is acceptable.

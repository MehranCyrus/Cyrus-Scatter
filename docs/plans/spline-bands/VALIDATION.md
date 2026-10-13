# Validation and performance gates

These are required future checks, not claims of tests already run. Research validation is recorded in [RESEARCH.md](RESEARCH.md) and [baseline.json](baseline.json). Implementation must attach actual receipts and exceptions to this matrix. A passed common evaluator test proves consistency; analytic or independent oracles establish correctness.

## R — Ranges, assignments and empty intervals

| Case | Required result |
|---|---|
| R1: Outside widths 100/250/1000 | Exactly 0–100, 100–350, 350–1350, independent of assigned source count; repeat Inside and interleaved sides/Paths |
| R2: Unassign middle Band; delete only its selected source | Middle interval remains empty; same-side successor does not expand into it. Test first/last/all empty as well |
| R3: Empty group, all-zero weights, removed group member | Zero contribution; no implicit fallback to all models. Reassigning restores the original interval |
| R4: Positive-weight intentional Empty source | Its selection removes a placement without redistributing its share; contrast with no assignment |
| R5: Two intersecting Paths | Consecutive preserves global authored precedence, including an empty winner; Independent combines eligible contributions across Paths |
| R6: Independent 0–10 cm and 0–40 cm | Both owners possible in 0–10; only the longer Band after 10; no accepted center beyond 40 apart from explicit protected Edit exceptions |
| R7: Conversion, order, exact endpoints | Consecutive→Independent preserves resolved intervals; noncontiguous reverse conversion is explicit/Undoable. Independent reorder preserves keyed decisions; consecutive reorder changes order intentionally |
| R8: Invalid/missing inputs | Missing Paths remain visible/inactive with records retained; NaN, negative or zero-width active ranges fail validation with previous result intact |

At distance ties test a scale-aware neighborhood on both sides, the exact spline edge, inside/outside boundary policy and thin Bands. Assert positions, source IDs and owner IDs. A row-count-only test cannot detect interval collapse. Changing Band 2 must not change Band 1 support, but shared spacing may change its accepted count; test support separately with spacing disabled.

## D — Density, deterministic sampling and movement

- D1: For a fixed candidate set with spacing/masks off, validate strength 0 and 1 exactly. Flat 0.25 must thin the original candidates; Accepted target must be rejected for this configuration before publication.
- D2: Use independent probability calculations. For `aSphere=1, aBox=.25`, overlap probabilities are .8/.2 and occupancy 1; Box-only occupancy is .25. For .4/.1, occupancy is .5 with owner .8/.2 conditional on acceptance. All-zero contributions produce none. Add a 50% Empty outcome and verify the lost mass is not reassigned.
- D3: Use fixed, predeclared seeds and enough candidates per spatial bin. For nondegenerate expected probability `p`, require deviation within a conservative `5*sqrt(N*p*(1-p)) + 1` count allowance, with multiple comparisons/seeds declared before running. Also exercise exact deterministic variates at interval thresholds; a statistical pass alone can hide selection-order defects.
- D4: Curves: constant, linear rise/fall, plateau, narrow peak, nonmonotonic multi-peak, sharp slope and disabled curve. Native payload requires 2–257 finite values in [0,1] with linear interpolation; the editor writes 257 samples with at most 64 stored control points. Compare its applied trace to solver samples, including Bezier overshoot/sub-sample detail. Reject malformed native data. Evaluate endpoint/tiny-band/collapse cases and direction for Inside/Outside. Never refill rejected density with later candidate ordinals.
- D5: Stable keys: repeated solve, larger candidate budget, source reorder with stable IDs, Independent Band reorder, multiple receiver IDs with overlapping local ordinals, duplicate names and layer copying. Common pre-spacing candidates retain decisions under budget growth; collision changes are analyzed separately. Distinguish address identity from distribution seed identity in layer copies.
- D6: Compose with other existing masks, Brush, Area density/scale and cleanup once. An all-one Band field is an identity operation for the baseline mode. Count and plants/m² select candidate budgets as before; a UI label must not imply a guaranteed accepted population.
- D7: Automatic movement: keep original occupancy/owner variates, reject destination if either decision changes. Include a saturated destination where owner contribution stays positive but its relative share shrinks. Verify source, Band scale and candidate identity stay attached. No rerolls or position-based recoloring.
- D8: Test thin gaps and source transitions along a movement segment. This delivery promises destination validation, not continuous no-gap-crossing; tests and documentation must state that limitation. Protected manual edits/clones follow their explicit exception and retain provenance.

## G — Geometry and field accuracy

| Geometry | Independent check |
|---|---|
| Axis-aligned rectangle | Rounded nearest-edge distance analytically; Sharp external rectangle bounds and miter-corner progress analytically; flat and ramped curves |
| Rotated rectangle, reversed knots, mirrored/nonuniform node transform | Same world-space support under the corresponding transform, physical distances unchanged; no winding-based inversion |
| Acute convex corner | Miter up to limit, Square truncation after limit; broad-phase includes admitted contour extents |
| Concave L/U shape, narrow neck | Correct topology, no bridging across excluded regions except intended offset topology changes |
| Donut, nested loops, disconnected components | EvenOdd filled region, hole erosion/expansion and stable semantic ownership regardless of output contour order |
| Crossing/touching closed contours | Explicit EvenOdd normalization or bounded validation failure, never accidental NonZero reinterpretation |
| Inward collapse and split | Successful empty contours distinguished from Clipper error; empty start vs empty end treated correctly; partial progress remains finite |
| Linear knots and curved Bezier segments | Sharp linear corners retained; documented tessellation accuracy and work bound; Rounded baseline change must be explicit |
| Tiny/huge units, far-from-origin geometry | Local coordinate conditioning, overflow admission and physically equivalent widths; no hidden epsilon derived only from display units |

G1: Include every start/end in cached levels. Compare computed offset coordinate against independent high-resolution offset queries at chosen distances, plus analytic cases, not the same cached bracketing algorithm. Away from the declared boundary tolerance zone, bound normalized progress error to 1/256 and aggregate absolute contribution error to .005 per query. Verify occupancy error <=.005 and per-Band unconditional emitted probability error <=.01, including 32 overlapping contributions and cases straddling saturation. Test near-zero sums separately: conditional mixture ratios have no fixed .01 promise. Record worst cases and error quantiles, not only a screenshot.

G2: Validate nested offset families within tolerance, level sharing, curve slope/error amplification and adaptive refinement. Include an interval smaller than a coarse level step and points within tolerance of intermediate contours. Uncertain containment widens/refines a certified q bracket; it never silently chooses a binary-search branch. If accuracy cannot fit declared aggregate limits, preparation fails atomically with a useful message.

G3: Exercise invalid, open, duplicate-point, zero-length, all-collinear, vertical/projected-degenerate and nonfinite paths; define which normalization removes harmless duplicates and which inputs fail. Inside/Outside refer to the filled projected region. A valid multi-loop shape must not be confused with an invalid single contour.

G4: Two receivers at different Z but the same XY get the same Band field and their own surface placements. Include slopes, object transforms and relevant spline animation. Host extraction occurs once per relevant Path revision, not once per Band.

G5: A model wider than its Band can extend beyond it while its center is correctly classified. Auto Radius affects inter-instance spacing, not whole-model boundary containment. Include this distinction in artist documentation and screenshot interpretation.

## T — Metadata through every stage

Maintain a checklist from the P0 inventory, not a guessed list of parsers. Exercise raw generation → receiver offsets/concatenation → source transforms → Whole Scale → Brush/Area falloff → applicable orientation → Edit/move/clone/protection → spacing/cleanup → publication → Point/Mesh samples → renderer/export. Test each stage alone and a combined fixture.

- T1: Two Bands sharing one source retain distinct owners. One Band with several sources retains one owner regardless of selected source. Band or source reorder never substitutes array indices for identity.
- T2: Protection survives every new row version, including consumers currently recognizing exactly four post-Edit fields. Clone has new output identity and inherited owner/protection according to existing semantics.
- T3: Native/script payload version mismatch fails before partial publication. Malformed owner key or missing palette entry cannot silently display another Band's color.
- T4: Source deletion/replacement, Point→model replacement, layer copy, Path removal/Undo and scene reopening preserve intended references. Repeated names are insufficient to rebind.
- T5: Analyzer and Brush shared bridges retain their current behavior. Ordinary spline work does not accidentally enable Analyzer orientation. Renderer-facing transform/source shape remains supported at its boundary.

## U — UI and authoring lifecycle

Use physical Max interaction in every supported rollout/editor container, not only scripted control setters. Cover supported narrow panels and at least 100%, 150% and 200% Windows display scaling where available.

- U1: Paths list, three-row initial height, scrollbar, adjacent path icons and one-row Band icons fit and remain usable. Tooltips, keyboard focus/activation, accessible names and disabled states are meaningful.
- U2: Models and Band lists show swatches without RGB text. `Point | 1.00 | Out 1` is readable; duplicate `Out 1` across Paths has a qualified tooltip. Multiple memberships show a count/chooser. Navigation never changes assignment.
- U3: New Band visibly requires model selection. Toggling direct/groups preserves separate selections; Ctrl/Shift selection edits the intended Band only. Group edits update all dependent memberships. Base Source Scale and Band Scale range have distinct explanations.
- U4: Open graph on Band A, select Band B/layer/controller, then drag/apply/close. Writes remain addressed to A or safely invalidate. Delete A, Undo/Redo, reset/open scene, remove Path, close dialog via window controls; no stale callback writes into B.
- U5: One drag produces the declared Undo transaction, coalesced Live updates and correct Manual pending status. Repeated opening does not leak dialogs, callbacks or owner subscriptions.
- U6: Radius/Auto/Follow Scale and world-Z tooltip match actual behavior. Unsupported Auto source state is explicit; changing back restores Manual settings.

## V — Viewport truth and rendering boundaries

- V1: Compare accepted data with displayed Point, Point Cloud and Mesh owner colors; same source in multiple Bands must differ correctly. Stable display subsampling preserves source/owner pairs. Switching Color by does not change transforms, counts or materials.
- V1b: Mixed layouts under one controller show legitimate no-owner placements as labeled Unbanded. A corrupt/missing required owner key fails validation instead of using that neutral fallback.
- V2: Field samples agree with evaluator values at recorded receiver positions. Selected view shows `a_i`, combined view shows `P`; legend and stage label are present. Zero differs from unsampled coverage. Samples and outlines respect Rounded/Sharp support, narrow Bands, holes and multiple receiver elevations.
- V3: Preview Falloff and Show Boundaries are independent toggles. Display budgets visibly report approximation/coverage; preview samples never count as plants and never render/export.
- V4: Band palette edits update only palette/style resources. Measure geometry, transform, owner and palette upload bytes separately; unchanged geometry and sibling streams stay unchanged. Older drawing generations do not observe mutated shared materials.
- V5: Mesh, native fallback and exact output use matching placement/source identities. Compare render material assignments to the pre-feature fixture, not just viewport colors. Device loss remains unqualified until a specific recovery witness passes.

## M — Manual/Live and publication epochs

M1: Publish, switch to Manual, edit width/curve/assignment/Auto/source modifier, then navigate, orbit, change color, toggle falloff/radius and switch Point/Mesh. Plants/radii/owner provenance remain published until Update. Pending field is clearly labeled. A mode requiring uncached changed source geometry keeps the previous complete preview and states Update is needed.

M2: After deleting an authored Band, its old published plants retain valid old metadata until Update. Existing-ID color edits may recolor published owners. Undo/Redo and reopening do not redirect graph ownership or erase valid publication unexpectedly.

M3: Explicit Update produces one coherent successor. Live responds to relevant source/path/receiver/transform animation, coalesces edits, and cancels/supersedes stale work safely. Unrelated animation, selection and UI movement perform no placement solve or source extraction. Workers use copied data; publication and SDK access stay on the host thread.

## A — Auto Radius oracle and spacing

Use independent transformed mesh vertices as an enclosure oracle, with analytic boxes to verify the expected eight-corner formula. The conservative bound may exceed the mesh's tight radius; that is not itself an error.

- A1: Symmetric box, tall narrow source, off-center pivot, asymmetric mesh, object offset, orphan vertices, normal alignment, yaw/pitch, nonuniform scale, reflection and shear. Radius excludes translation; every referenced transformed vertex is enclosed. Assert finite nonnegative values and `r3D >= rXY` within tolerance.
- A2: Combine source, Band, layer and falloff scales and Edit transforms. Auto applies final scale once. Manual with Follow Scale on/off matches its baseline. Absolute override sets both metrics; multiplier scales both. Stable overrides survive source/row reordering as intended.
- A3: Self XY plus external 3D, self 3D plus external XY, several external rules with different settings and owners. Both own and blocker arrays use that rule's metric. Assert exact pair decisions around sum-of-radii + gap thresholds.
- A4: Bounds evaluate once per relevant geometry revision, not per instance or orbit. Animate a relevant modifier/object offset; Manual retains published radii, Live updates them. Unsupported/failed/over-budget geometry does not silently become radius zero.
- A4b: Invalid positively weighted source in a potentially nonzero active Band fails preparation even when a particular seed would emit none. Repeat in a non-Band layout with an active source lottery. Dormant unassigned/zero-weight sources do not block unrelated active output.
- A5: Point, Empty, missing object, empty mesh, singular source transform and unsupported renderer proxy. Manual remains available. No referenced vertices or failed extraction is unresolved; a valid finite degenerate bound is accepted and can genuinely produce zero radius. Test a finite collapsed final placement basis separately from singular source extraction. Test each explicitly supported proxy against the geometry actually rendered, including viewport simplification.
- A6: Published Show Radius XY rings and 3D spheres match the chosen metric pair. Metric selection is display-only. Model pivots at different Z reveal the expected difference between planar and spatial scopes.

## S — Saved state, units and identities

Save/reopen disposable scenes containing mixed Paths, modes, assignments, curves, colors, radii and instance overrides. Exercise copy/remove/Undo/Redo and the supported scene merge/rescale paths. Test physical equivalence in millimetres, centimetres and metres; changing display units alone must not change geometry. Include nonzero Z Offset and explicit world-radius overrides, since float storage behind a world-unit spinner is insufficient evidence.

Verify schema/native payload agreement and new-default behavior. Current-schema-57 save/reopen, merge, copy and Undo must preserve selections, order, IDs, scales, seeds, typed Manual radii, physical distances and animation controllers. New Bands default to direct-empty. Earlier development scenes are unsupported under the user's current-only requirement: test actionable rejection and preserve their original bytes. No migration handlers or older row formats remain in the product. Capture actual parameter values and identities, not only UI captions.

## F — Failure, cancellation and retention

Inject failures at path extraction/normalization, Sharp level budget, source bounds, row conversion, owner/palette lookup, later-layer preparation, CPU snapshot allocation, native successor allocation, GPU realization/upload and display fallback construction. Distinguish successful inward collapse from failure.

Require: prior complete publication remains available or a verified complete fallback draws it; no old transforms with new owners/palette/radii; no mixed layers from failed successor; useful owner-specific status; resources released; subsequent valid Update recovers. Test cancellation/supersession and repeated failure/recovery cycles. Save/reopen after a failed successor must follow the declared published-state policy.

Current CPU-stage retention does not establish GPU atomicity. New allocation failure witnesses are mandatory, including a failing later group after earlier groups allocated. Any current native defect exposed by these required features is a prerequisite repair, not grounds to lower the acceptance contract.

## P — Performance and bounded work

Freeze baseline and candidate builds with matching scenes/settings and source hashes. Record machine, Max version, GPU/driver, resolution, display scaling, camera, shown subset and native fallback status. Predeclare repetition counts and thresholds before comparing runs. Report cold and warm median/p95; measure actual presented frames separately from script redraw time.

Representative workload ladder:

| Workload | Sweep |
|---|---|
| Candidate field | 1k / 10k / 100k candidates; 1 / 8 / 32 Bands; Rounded/Sharp; flat/steep curves |
| Geometry complexity | Rectangle, curved path, concave/hole case, high-vertex normalized case and the admitted-limit boundary |
| Shared sources | 1 / 20 supported sources reused across Bands; small/heavy mesh and Point Cloud sampling |
| Layer/receiver pressure | 1 / 10 active layers, several receivers including stacked XY; self and mixed external spacing |
| Display edits | Color, selection, curve drag, width, source modifier, Point/Mesh switch, radius metric, overlay toggle |
| Lifetime | Repeated mode switches, updates, cancellation and failures; retained old/staged generations near admission limits |

The 100k candidate point reflects the current receiver planning limit, not a newly promised universal scene maximum. Record per-receiver and aggregate work separately. Do not benchmark all Cartesian combinations blindly; cover each risk plus realistic artist fixtures.

Strict invariants:

1. Zero placement solves for navigation, palette changes and display-only toggles. Zero unchanged sibling geometry uploads; palette-only changes upload zero geometric/transform streams.
2. Zero host mesh extraction from viewport draw; one bounds extraction per relevant source revision; one Path extraction per relevant revision shared across its Bands. Auto corner work is bounded by eight corners per placement for both metrics together.
3. No per-candidate Clipper operation, no persistent candidates×Bands matrix, and no geometry duplication proportional to source×Band memberships.
4. New owner/palette/overlay/fallback/staging bytes fit declared reservations. Current native constraints are 20 cache entries, 1,024 nonempty groups, point/radius 64 MiB per owner / 128 MiB process and Mesh 512 MiB per owner / 1 GiB process. Any deliberate revision must be measured and reviewed with aggregate accounting, not a magic larger constant.
5. Input vertices, generated vertices, offset levels, query visits and preview samples all have finite per-operation and aggregate admission. Cancellation and failure do not leak reservations.

Proposed timing gate: unchanged Rounded/flat/no-overlay workloads should show no repeatable regression greater than 10% in warm median or p95 above the measured timer/noise floor. P0 must record the absolute noise floor and interactive update budget for the target machine before using this criterion. New Sharp/field work must fit that declared budget at the agreed artist workload; correctness/quality must not be traded away silently to pass timing. No FPS claim can be made from an unpresented redraw measurement.

Instrument extraction, field preparation, candidate evaluation, density rejection, spacing, radius calculation, CPU snapshot creation, native allocation/upload and presentation separately. Record attempted/rejected/accepted/shown counts, upload bytes by resource, peak reserved/live memory and cache hit/miss reasons. Historical 0.79.5 measurements are context, not this feature's baseline receipt.

## Acceptance record

For each milestone record code/script/native identities, dirty baseline, test commands, fixture creation, settings, expected oracle, actual data, failures and exclusions. Run the integrated host matrix on the currently supported Max versions (2026 and 2027 in the inspected workflow) using owned disposable profiles/scenes. Preserve `Test Scene/` and artist files.

Implementation acceptance requires all applicable families above, generated-source consistency and exact loaded identity. Plan review alone cannot certify host interaction, rendering, GPU failure recovery or performance. Missing empirical gates are blockers to claiming the corresponding feature complete.

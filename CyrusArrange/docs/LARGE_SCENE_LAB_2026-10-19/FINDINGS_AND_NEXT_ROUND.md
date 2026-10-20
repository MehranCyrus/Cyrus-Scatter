# Large scene findings and next round

This is an experiment with the unchanged 0.3.2 development pair. It is not a list of implemented fixes, a production certification, or a substitute for the remaining release gates. The tested layout is a furnished showroom with an adjacent curved road, using 590 generated placements across 15 arrangements.

## What worked in the accepted main run

The geometry-first workflow handled books, complete grouped plants, decor, repeated compound groups, arbitrary stair clutter, oversized cabinet devices and complete cars without furniture categories. All final scene requests were filled, including 100 books in each of four libraries, two uniformly fitted appliances and six cars in each direction. The original-size cabinet deliberately rejected two devices when no permitted space remained; enabling a 60% fit minimum produced a feasible result.

Bulk intake, fixed-seed repeat, fresh variations, protected placements, Undo/Redo, invalid-draft rejection and save/reopen worked in this integrated scene. The independent geometry review confirmed all 590 actual meshes retain the source shape and permitted scale and have supported bases. Four coarse collision candidates were resolved by examining the actual closed parts of the grouped decor, preserving the original conservative report.

Observed Generate calls took 41–409 ms in the main run. These are individual handler timings, not controlled performance benchmarks or viewport FPS. There is no evidence from this scene that warrants a performance rewrite before the remaining isolated measurements.

## Improvements worth considering

These are workflow observations or proposals, not confirmed placement bugs. They should remain optional artist controls and must not bring back restrictions based on furniture or prop categories. The fit-advice case below was reproduced during the follow-up editing pass; its final run identity and acceptance are recorded in the technical results.

| Priority | Observation in this scene | Proposed improvement | Acceptance example |
| --- | --- | --- | --- |
| High | The occupied cabinet with a 100% minimum generated 0/2 and reported “No smaller fit was verified.” Its blocked-space highlight worked, but no checked-size suggestion was available. Restoring the 60% minimum generated 2/2. | Improve the coverage and explanation of fit advice. Consider additional candidate positions/regions within a measured work budget; clearly describe an unsuccessful diagnostic as a bounded search. Do not offer an unverified shrink percentage. | Reopen `Arrange_Cabinet_Devices`, retain its seed and obstacle, enable fit with minimum 100%, Generate, then compare the checked advice with a Generate at 60%. A proposed suggestion must physically fit when applied. |
| High | A whole library is valid receiving geometry, including its outside top. Books therefore occupy both internal shelves and the cabinet top. | Simple optional surface/face selection or exclusion with a visible preview. Preserve automatic use of valid geometry as the default. | Select only three internal shelves; all requested placements remain on those selected surfaces after regenerate and reopen. |
| High | Nearby furniture and independent tray/TV objects need an explicit collision binding. Their presence in the scene alone does not make them obstacles. | Make the currently included obstacles and excluded surroundings clearer in Modify, with a simple action to add selected obstacles. | A user can see whether the reserved tray is included and add/remove it without accidentally changing another arrangement. |
| Medium | Fifteen arrangements are individually editable through their icons. Coordinated edits require visiting each owner. | Optional multi-arrangement selection and Generate, with individual success/underfill summaries. | Regenerate four selected libraries; preserve the other eleven owners and every protected object. Report which library could not fill. |
| Medium | The 400-book exercise intentionally repeats one prepared upright book model. Correct placement alone does not produce varied cover designs or a curated display. | Better source-variant previews and optional orientation controls. Bulk addition already supplies multiple models; make that route easy to discover. | Add several books at once and preview their contact orientation before generating; avoid a forced book-specific category. |
| Medium | The upright book source was prepared explicitly before intake. A user's flat or oddly oriented import may need preparation. | Preview the contact base and forward/up orientation during intake. Keep source models unchanged. | A flat imported book can be used flat or upright by an explicit artist choice, with correct support and repeatable transforms. |
| Release blocker | The artist profile still points to installed 0.3.1; the editable experiment uses 0.3.2. | Finish the existing 0.3.2 package/install acceptance before treating the editable scene as an installed-product example. Supply a plain-mesh viewing copy meanwhile. | A freshly installed qualified package opens the editable example with its icon, Modify controls, references and generated results intact. |

## Checks that still need separate evidence

- Independently check surface edge margins; the main mesh review checks support and relevant collision clearance, not every boundary inset.
- Compare effective material/UV bindings from compound source children to generated output faces. Raw face material IDs may legitimately change when compounds are flattened. The literal differences in the export are not proof of a visual defect.
- Exercise real interactive navigation and artist use. This experiment mounts native Modify views and invokes actual handlers, but it does not measure mouse workflow, viewport responsiveness or discoverability.
- Complete the existing exact-pair release, isolated performance, installer, private installation and example relocation gates. This scene is supplemental evidence.
- Treat nonplanar paths, gravity, cloth settling and physical stability as outside this experiment. The stairs contain rigid props; this is geometric placement, not dynamics.

## Specific follow-up observations

`Show fit space` displayed the cabinet's current failure boxes and toggled them off without changing selection, scene nodes or accepted placements. `Use checked size` could not be exercised because this case supplied no suggestion. That is recorded as unavailable, not a successful feature check. Local `src/fit_feedback.cpp` shows that advice evaluates a bounded set of recorded failure seeds and probes smaller sizes at those candidates; it is not an exhaustive search over every possible empty location. The failed advice followed by a successful 60% Generate establishes a coverage limitation, but does not by itself identify the best algorithmic fix.

With the TV console's original seed, disabling Clear approach retained all 24 placements and the same layout. Undo restored the complete original state. This verifies the control/transaction path; this particular layout did not demonstrate a geometric benefit from the option. A deliberately obstructed approach case remains the right way to evaluate that behavior.

Per-prop minimum counts were checked by actual asset ID, not source-selection array order. The stairs contained 20 copies of the book against a minimum of 12 and 23 fruit objects against a minimum of 6. The second stair minimum was fruit, not the bin. Coffee 1 contained two books against a minimum of two and two plants against a minimum of one.

## Reporting discipline

No confirmed placement defect was found in the accepted main scene. That statement is limited to the recorded geometry, explicit collision scope, final settings and 590 outputs. It does not establish that arbitrary scenes are issue-free. Original failed harness attempts and coarse review reports remain preserved, and follow-up findings belong in the technical record with their exact run identity.

See [technical results](TECHNICAL_RESULTS.md) for counts, timings, evidence paths, numerical tolerances and exclusions.

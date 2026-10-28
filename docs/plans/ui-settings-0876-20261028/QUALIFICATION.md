# 0.87.6 qualification

Result: **scoped pass**. [Machine-readable receipt](QUALIFICATION.json) binds the
observed host results, native suites, source preservation and package identities.

## Exact payload and environment

The private Max 2027 host loaded the extracted final MZP payload; loaded native
module paths/hashes are recorded in [loaded identity](evidence/loaded-identity.json).
The original Max 2027 MZP was copied byte-for-byte into the final combined delivery.
Max 2024 and 2026 were separately SDK-compiled and package checked, without launching
those hosts or running their native tests. Installer resource inspection did not
execute its entry point or install into an artist profile.

- Max 2027 MZP SHA-256: `0dd193dc54accf658fad54ce339a1e00a7b401e2621f4f3c51c602bac2547a89`.
- Combined EXE SHA-256: `6c05af719cf70e7bbd519418fd10c89c8c346eb489fc57981cbbc7fa3d90bdd4`.
- [All package, native and embedded-resource hashes](evidence/installer-receipt.json).

## Observed checks

| Check | Evidence / result |
|---|---|
| Point sources | [7 checks](evidence/points.json): Add Point button, authored scale/Z, all-Point publication, replacement identity, removal/shared lists and save/reopen. |
| Point Undo/Redo | Separate native MAXScript action, observation, Undo and Redo events; [Undo](evidence/point-undo-check.json) restores one source, [Redo](evidence/point-redo-check.json) restores two with the same identities; 40 placements retained. |
| Painting | [10 checks](evidence/paint_edges.json). One circular stroke: 112 placements; inward fade: 65; outward fade: 187. Clear: 0; Fill: 956; density zero: 0. Scale endpoint 0.25 persisted. Manual edits retained the completed result and displayed the Update reminder. |
| Paint curves and preview | [10 checks](evidence/paint_tools.json): both curve buttons open/close without changing samples; programmed endpoint edits publish 0.25 through the curve queue/Apply handler; all three Paint preview modes bind to the current Paint Area. This does not qualify physical graph dragging. |
| Panel workflows | [31 checks](evidence/panels.json): layers, receivers, source rectangle, grids, Clusters, Bands, Areas, scale reset, density preview, five display representations, cached stats and browsing. |
| Scalar setting handlers | [Default groups](evidence/settings.json): 46 checks executed, 151 inactive entries skipped. [Expanded groups](evidence/settings_expanded.json): 77 executed, 120 inactive. These runs overlap; totals are not unique controls. |
| Error recovery | [2 checks](evidence/negative.json): missing Analyzer input retains the completed result; duplicate source replacement is rejected without changing identities. |
| Interactions UI | [13 checks](evidence/interactions.json): small ribbon preparation, common strength/trunk/fixed-base/fade controls, 100% preview, Bend/Trim choices, guides and scene-collider pick/remove. No drag-performance claim. |
| Layout | [1,167 repeated visible-control samples](evidence/layout.json), no reported horizontal bound violations at the observed 154-pixel logical width. Command-panel shells clamped the requested test widths; this is not a three-width/DPI qualification. Spinner anchors and controls without a width property were skipped. |
| Color swatches | Separate [native bounds checks](evidence/swatches.json): both source/layer swatches x=126, width=22 within width=154. |
| Library startup | [4 checks](evidence/library.json): matching assembly 0.87.6.0, actual Recipes button opens the Library, no error banner, owned window closes. The disposable profile has no artist library configured; import/export transactions retain their earlier qualification. |
| Native calculations | [23/23 suites](evidence/native-tests.log): Point/source measurement, radius/clearance, Paint/conversion/feedback, masks, surface filters, grids, Bands/overlays, presets, receivers, procedural/group spacing, preview policies, orientation, edges and falloff. |
| Generated/package checks | [Generation check](evidence/generated-check.json), approved-layout assertions and 15 focused feature-catalog/package-version/library-host tests passed. The generation check binds the final script hash and normalized .NET guards. |

Tests use MAXScript/SDK queries and native control notifications in disposable
profiles. No Computer Use or physical input timing is claimed. Button callbacks,
dropdown notifications and numeric assertions establish different scopes; the
[control ledger](CONTROL_LEDGER.md) labels inactive and unexercised controls.

## Preserved performance foundation

[67 interaction/preparation/display source files](evidence/protected-sources.json)
match their pre-task hashes. No new interaction solver, GPU path, bulk calculation
or buffer-upload mechanism was introduced. Repeated panel binding preserved both
the publication epoch and prepared-build counter at 19 in the small panel fixture.
The original [0.87.5.6 performance evidence](../drag-response-08756-20261028/DELIVERY_08756.md)
remains the performance reference; this UI pass does not rerun or extend it.

The native producer receipts say build-only because tests were run afterward in
the completed Max 2027 build. Their original receipts remain immutable; the test
log above is the separate evidence of those 23 executions.

Before committing, the Git index was checked against the delivered script and all
67 protected source hashes. Scoped Git attributes preserve those source and dated
evidence bytes instead of normalizing their line endings. The maintained guides
and this audit also passed 811 local-link checks with no missing targets.

## Limits and development corrections

An inventory is not proof of every option combination. External Analyzer outputs,
renderer-specific results, remote Library transactions, physical curve dragging,
all source assets, mouse feel, DPI/theme combinations and older-host runtime are
not exhaustively qualified here. Library and native Scene presets retain their
previous independent scope.

Development probes exposed harness mistakes: creating the wrong fixture class,
reading controller receivers instead of layer receivers, calling a dropdown's
string property as an event, and attempting Copy while fixture construction still
owned a Max hold. A later curve probe also tried to call a native-only control
event; the final curve check explicitly calls its queue method and does not claim
physical input coverage. The final harness uses the correct owners, committed native
dropdown notifications and separate Undo callbacks. Earlier development reports
are not promoted to final acceptance. The first 0.87.6 test package is superseded
by the exact package identified above.

The website was not rebuilt, and no knowledge generation was refreshed or activated.
Maintained sources and delivered facts changed, so indexed freshness requires a
separate refresh before the previous 32/32 or 64/64 claims can be reused.

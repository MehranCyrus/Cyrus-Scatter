# Cyrus Scatter 0.75 — Layout and transform UI refinement

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

9 October 2026. This UI delivery follows [the Layout investigation](../Arrangement_Research_0.75_2026-10-09/README.md) and supersedes the first 0.75 installer for these controls. Product version stays 0.75.0, UI 0.75, schema 54. Native Scatter and Analyzer binaries are unchanged.

## Completed changes

- [x] Layout is its own main rollout directly after Models, in both Scatter and source-container views. The floating editor includes Layout on its Models topic.
- [x] Random mix, Clusters, Spline bands and Surface Analyzer are available without opening Advanced. Relevant controls and next-action help follow the selected mode. Noise, corner handling and other secondary controls remain under Advanced.
- [x] Rename pattern strokes to bands; preserve freehand Painting as a separate workflow. Band model choices display Scatter labels rather than renaming scene nodes.
- [x] Show the linked Analyzer name, receiver and ready/dirty/missing/disabled state. Select opens its scene selection; Update Analyzer performs analysis explicitly. Unsupported input errors appear in the status. In Manual mode, Update scatter still publishes pending placements separately.
- [x] Layers shows Enabled, Visible, layer actions and existing management/statistics controls directly. Properties is removed; Advanced is hidden and occupies no row.
- [x] Rotation, XYZ scale and movement each use paired X Min / X Max, Y Min / Y Max and Z Min / Z Max rows. Uniform scale also has a paired Min/Max row. All transform fields and reset buttons are directly visible.

## Implementation

Changes are in the authoritative layout rows/generator, main UI template and source-assignment component; the generated script, control inventory, tooltips and feature catalog are regenerated together. There are now 11 main sections and 234 cataloged controls (two new Analyzer action buttons; help/status labels are not catalog actions).

The former fallback layout emitted axis labels and numeric fields as separate rows. Explicit pair metadata now groups them and adds readable captions. MAXScript SpinnerControl exposes neither writable width nor fieldWidth at runtime. The layout positions each spinner and sizes its native CustEdit field via the same host window API already used for other native controls. Tests measure actual label/edit/arrow rectangles. They do not substitute for physical DPI/font acceptance.

Mode changes preserve existing generation, band priority, color-group semantics and Analyzer ownership. Named model groups, band previews, multi-Analyzer ownership and surface-following bands are not implemented in this UI pass.

## Validation and delivery

See [EVIDENCE.json](EVIDENCE.json) and the receipts alongside it for final checks and exact identities. The focused [Max fixture](../../tools/procedural_lab/Max_Layout_075.ms) covers Layout ownership and modes; layer disclosures; Min/Max native bounds in main, popup and container views; popup resizing; model aliases; Analyzer update/failure/select callbacks; Manual publication; layer switching; and transform reset callbacks.

Existing list-grip, shared-view and Manual/painting regressions are run on the final private script/native pair. Python and generator checks cover catalog consistency and generated sources. No native rebuild is needed: compiled native inputs remain identical to the verified 0.75 build.

Final result: **94 Layout assertions, 22 consolidation assertions, 45 layer/painting assertions, 23 list grips, shared-view/lifecycle and older-scene regressions passed; 141 Python tests passed.** Generator checks account for all 234 cataloged controls across 11 sections. The legacy-scene fixture initially ran before its LRAssert helper was loaded; recompiling it after loading that dependency passed. Intermediate spinner API and generated-newline errors were corrected before the final fresh-host qualification.

The installer is [CyrusScatter-0.75.0-Max2027.mzp](../../dist/UI_Layout_0.75_2026-10-09/Max2027/CyrusScatter-0.75.0-Max2027.mzp). It is a separate local artifact, not an overwrite of the earlier 0.75 package. It has not been installed into the artist profile.

No computer-use tools or artist scenes were used. Owned private hosts are closed after qualification. Physical interaction, high DPI/tablet, Max 2026 runtime, renderer output and heavy-model viewport performance remain outside this pass.

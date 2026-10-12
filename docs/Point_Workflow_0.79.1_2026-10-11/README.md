# Point workflow and falloff refinement — 0.79.1

Current follow-up: [0.79.2](../Layer_Navigation_0.79.2_2026-10-11/README.md) fixes the confirmed Manual cache/radius issues and navigation overhead. This report preserves the preceding build's evidence; the physical Live/picker report remains open.

Follow-up: the [layer and Point investigation](LAYER_INVESTIGATION.md) confirms a Manual display-cache ownership defect in this build. The reported Live/picker disappearance remains open; the original qualification below does not certify those interactions.

The [point-scene navigation study](NAVIGATION_PERFORMANCE.md) separates unchanged-cache reuse from expensive radius drawing and repeated layer checks. It also confirms that the radius display controls apply pending Manual placement edits through a full Update. These findings describe 0.79.1 and are addressed by the follow-up above.

11 October 2026. This is a focused development qualification, not a claim that every control, renderer or scene is release-ready. The existing 0.79 licensing/source checkpoint was committed and pushed first as `1f62f82` on `codex/workflow-0.75`. The refinement retains schema 55, the current team licensing authority and unchanged native calculation/display code. Analyzer remains 0.14; MCP remains 0.73.0.

## What changed

- **Models & Points** starts with Add Point and Add Model. Names, identification color, weight, scale, radius, offset, Follow Scale, radius display and forward axis are visible. Replace Point is enabled for one highlighted Point. Assignment groups have their own disclosure.
- **Source containers** is a separate collapsible section with Manual models, Shared containers and Layer containers. Rectangles collect scene models by their pivots. Point/Empty rows stay active without needing a scene pivot. Collection and layout assignment groups remain separate concepts.
- **Direct Point assignment** now works in Spline bands / Models / Points choices. Saved row identities support Point/Empty metadata and direct band choices. Replacement preserves the row; removing an earlier row cannot redirect another choice. An explicitly removed source leaves its band unassigned.
- **Layer copy** now copies the explicit band arrays, selected sources, paths and Analyzer link that the previous copy omitted.
- **Area selection** selects a newly added Include row, follows actual selected modes, shows an explicit mixed state, and disables mode editing when no area is selected.
- **Boundary falloff** target, widths and separate density/scale graph buttons are visible without Advanced. Disabled effects disable their dependent controls; an absent Analyzer cannot masquerade as a valid falloff target.
- **Add Point Undo** includes both row creation and its Point type. Add Empty explicitly creates the Empty type. Placeholder identification metadata grows node-reference tabs safely instead of appending an invalid undefined node.

These changes do not reseed existing receiver streams. Names remain local Scatter labels; scene node names are not changed. Saved source row identity is separate from native candidate and output identities.

## Qualification checklist

- [x] Copied the supplied `Include_Exclude_Point_Examples.max`; original file hash preserved.
- [x] All 25 examples retain their exact saved fingerprints, including positions and source slots, in both Max 2026 and Max 2027 when loaded using the file's system units.
- [x] Save/reopen of all 25 examples preserves those results.
- [x] Add/name/color three Points; assign them directly to three spline bands.
- [x] Copy a layer with its guides/choices; copied output matches exactly.
- [x] Replace a Point with a model without changing placements or its label/identity.
- [x] Container membership supports the mixed Point/model setup.
- [x] Remove an earlier Point; remaining identity/name survive and the removed direct band is empty.
- [x] Point/model choices, labels and row IDs survive save/reopen.
- [x] Add Point button, one Undo and Redo tested in separate pure MAXScript requests.
- [x] Weighted Empty produces gaps; Accepted target rejects weighted Empty while retaining the previous complete result; zero-weight Empty permits the target.
- [x] Inward and outward scale falloff compared with independent world-distance interpolation.
- [x] Radius Follow Scale on/off and the 80 mm radius + 20 mm gap example checked numerically.
- [x] Density curve zero/full endpoints, custom density graph midpoint and independent scale graph midpoint checked; editing one curve leaves the other unchanged.
- [x] Manual width edits wait; explicit Update applies them; Live publishes relevant width edits.
- [x] New/single/multiple/mixed/empty Area selection checked through actual generated handlers.
- [x] Native control bounds checked for overlaps in Models & Points, Source containers, Include/exclude and Layout at the test profile's width/DPI.
- [x] Five unchanged evaluation/display passes retain publication epochs, receiver-cache builds and point-buffer upload counters for every example.
- [ ] Cross-system-unit conversion: confirmed failure, described below.
- [ ] Physical graph dragging, pickers, tablet/mouse gestures, other DPI/docking configurations, sustained heavy assets and renderer certification.

Tests call generated handlers and MAXScript/pymxs in owned hidden Max processes. No computer-use input or artist-session mutation was used. Native rectangle measurements establish layout bounds, not visual font or physical interaction quality.

## Remaining unit-conversion defect

Loading the original file in its saved inches preserves case 16's **696 placements** and approximately **400 mm** fade width. Converting that same file to centimeters changes the serialized per-area fade to approximately **157.48 mm** and produces **918 placements**. `areaFallConfigs` currently stores distance values inside strings, so those values do not participate in host world-distance conversion.

Use **the file's system units** for these examples. This is an outstanding defect, not a passed unit-conversion test. Backlog B14 calls for an explicit distance storage/conversion contract and an audit of source radius/offset arrays and mixed world-radius/multiplier overrides, followed by load, merge, Rescale World Units and save/reopen witnesses. A blanket multiplier on all numeric fields would also change dimensionless settings, so it is not a safe correction.

## Evidence and performance

| Check | Max 2026 | Max 2027 |
| --- | --- | --- |
| Focused feature assertions | 176 passed | 176 passed |
| Add Point Undo/Redo | Both phases passed | Both phases passed |
| Exact original examples and save/reopen | 25/25 | 25/25 |
| Licensed native suites | 24/24 | 24/24 |
| Analyzer core suite | 1/1 | 1/1 |
| Unchanged 25-case evaluation/sync/redraw median | 483.43 ms | 334.62 ms |
| Extra receiver builds / point uploads during unchanged passes | 0 / 0 | 0 / 0 |

All 158 Python tests and generated/layout checks passed. Final generated script SHA-256: `ff2bee7e0baa1399d94c0d74b9dc8cad0335e45ef311e982e97225256344de08`. Original scene SHA-256: `b7e561c15e942843a1ebd694691fc36a18f9e79c385c31d140b1366cf633fc0b`.

See [evidence.json](evidence.json) for exact loaded identities, per-check results, native control bounds, timings, archive verification and original-scene hashes. Native test totals and scripted metrics are summarized there. Unchanged cache reuse does not imply zero drawing cost. The five-pass timing includes evaluation, point synchronization and synchronous redraw across all 25 cases; it is **not presented FPS**, an isolated GPU measurement or a controlled speedup against 0.79. Other Max/build processes were active during parts of the run.

The original example campaign supplies the geometric reference. This refinement additionally checks analytical scale/radius/curve witnesses; it does not rerun every historical feature campaign or certify all options from the source inventory.

## Delivery

- [Scatter 0.79.1 — Max 2026](../../dist/refinement-0.79.1/CyrusScatter-0.79.1-Max2026.mzp)
- [Scatter 0.79.1 — Max 2027](../../dist/refinement-0.79.1/CyrusScatter-0.79.1-Max2027.mzp)
- [Unchanged Analyzer 0.14 packages](../Container_and_Radius_0.78.3_2026-10-10/README.md)
- [Tested examples saved in Max 2026 format](../../Test%20Scene/0.79.1-Point-Refinement/Include_Exclude_Point_Examples_0.79.1.max)
- [Named Point/model band example](../../Test%20Scene/0.79.1-Point-Refinement/Point_Workflow_0.79.1.max)

Archives retain the owner's team trust and require activation. New source and loaded module hashes are verified; installer execution and the complete activation/expiry adversarial campaign were not repeated. No normal Max profile was upgraded. The previous [0.79 licensing report](../licensing/TEAM_PILOT_0.79_2026-10-11.md) remains the evidence for those unchanged boundaries. Local scenes, binaries and installers are ignored by Git; source, guides, reproducible checks and this evidence are committed.

## Reproduce

Use fresh output/profile names. `tools/licensing/build_candidate.py` freezes source, compiles the matching SDK binaries and runs native tests. `tools/refine0791/launch.py` checks compiled source identity, builds the unchanged Analyzer, copies the scene and launches an owned profile. `tools/refine0791/run_all.py <profile>` serializes the phases; `run_phase.py` can rerun a phase after its prerequisites. The unit phase records a failing observation separately from the passing feature assertions. Valid local team activation is required for owner-trusted builds.

The fixture requires the supplied artist scene and its original reference receipts at `build/vector-brush-078/include-exclude-visible2026-01/`; those local inputs are not supplied by Git. Do not run reset/load fixtures inside the artist's session. Generated checks and Python/native suites follow [the agent workflow](../AGENT_WORKFLOW.md).

## Development failures retained

Earlier private attempts exposed an initialization-order error in the new row-ID field and invalid placeholder node-tab appends; both were corrected before final qualification. A curve assertion compared wrapper strings instead of numeric values, and a dropdown fixture invoked its text property as a method; those fixture errors were corrected. The first Python Undo probe ran inside an outer test transaction, including a plain-box witness; pure MAXScript requests verify the actual button transaction independently. A corrected Max 2027 launch with the final build passed after one preceding process exited before readiness/loaded-module verification. That unexplained startup exit remains a deployment qualification observation, not proof of a plugin regression or a clean lifecycle campaign.

Historical receipts remain in the owned build directories. Failed runs are not counted as passing acceptance.

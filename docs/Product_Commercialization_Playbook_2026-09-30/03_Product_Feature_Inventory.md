# Stage 03 — Product feature inventory

## Goal

Maintain one practical inventory of existing features, their evidence, risks and presentation potential. Use it to choose what to validate and lead with.

## Why this matters

A feature can exist in code while being difficult to discover, untested in Max, or unsuitable for a release claim. This table keeps those distinctions visible.

## What we currently know

**VERIFIED IN SOURCE:** existing rows below were traced through current APIs, generated UI or native/script implementation. Source anchors S1–S12 are listed in [the repository review](98_Repository_Review_and_Deliverables.md). “Auto” describes dated evidence, not a certification of the entire feature.

Native test shorthand: **Core** = scatter_tests; **Space** = spacing_tests; **Weight** = weight_tests; **Orient** = orientation_tests; **Edge** = edge_border_tests; **Fall** = boundary_falloff_tests; **Analyze** = analyzer_tests. Seven existing executables passed on 2026-09-29; matching hashes checked again here. **Smoke** = limited Max 2027.1 batch on 2026-09-28. [Raw native results](../Product_Strategy_2026-09-29/evidence/native_test_rerun.json). Empty-stack smoke does not cover edit mutations.

**Readiness:** “Present; unqualified” is source presence awaiting manual qualification; “Partial” records a known access/support gap; “Planned” is PROPOSED. All public claims still pass through [the claims matrix](Landing_Page_Claims_Matrix.md).

## My tasks

- [ ] Map your MT results to the rows below.
- [ ] Replace general notes with exact build/configuration/evidence.
- [ ] Select your five most useful features and the three most confusing.
- [ ] Mark what you personally demonstrated versus what remains engineering-only.
- [ ] Update readiness after fixes and retesting; preserve old result dates.

## Engineering / Codex tasks

- [ ] Confirm ambiguous UI/code coverage and add needed integration fixtures.
- [ ] Supply diagnostics for features whose actual counts/state cannot be observed reliably.
- [ ] Correct confirmed defects under a scoped implementation task; update source and build evidence.

## Boss / Product-owner decisions

Decide the first offered workflow scope after the inventory and Stage 05 exercise. Approving a feature for a demo does not approve broad support or commercial terms.

## Step-by-step procedure

1. Read the Existing features table by workflow, using Stage 02 rather than reading all C++.
2. Add an evidence link/date to each row you exercised.
3. Keep “not tested” visible where the test did not happen.
4. Choose lead features only when their full create/edit/save/render chain is supported by evidence.
5. Review Planned capabilities separately and keep them out of present-tense public copy.

## Existing features

| ID / Feature | Module / anchor | Code | UI | Auto evidence | Manual test | Current readiness | Known risk | Marketing potential | Notes |
|---|---|---|---|---|---|---|---|---|---|
| F01 Surface mesh input | Bridge S2 | Yes | Surface Scatter | Core math; Smoke one plane | MT03 | Present; unqualified | Evaluated topology/transforms | Basic placement | Multiple surfaces need host fixture |
| F02 Count + Seed | Scatter S1/S4 | Yes | Point Generation | Core + Smoke | MT05 | Present; unqualified | Source/rule changes affect layout | Repeatable procedural setup | Reproducibility scoped to exact build/environment |
| F03 Plants per m2 | Controller S4 | Yes | Point Generation | Core thinning semantics | MT06 | Present; unqualified | Units and 100k requested cap | Physical density control | Filtering can reduce output |
| F04 Texture Density/invert | Bridge/controller S2/S4 | Yes | Map controls | Core numeric mask | MT07 | Present; unqualified | UV1/128² raster; legacy branch risk | Art-directed density | No arbitrary shader/OCIO guarantee |
| F05 Multiple weighted sources | Scatter S1 | Yes | Source Object | Weight | MT04/15 | Present; unqualified | Row/source changes and zero weights | Mix assets | Weight is 0–1 input |
| F06 Source color groups | Controller/Scatter S1/S3 | Yes | Source groups/colors | Weight/Core | MT15/29 | Present; unqualified | Preview color differs from render material | Group-based assignment | Not automatic material color variation |
| F07 Cluster assignment | Scatter S1 | Yes | Diversity / Colors | Core/Weight | MT15 | Present; unqualified | Confused with placement clustering | Natural source variation | Diversity changes assignment, not base positions |
| F08 Per-source scale/Z offset | Controller S3/S5 | Yes | Source Object | Core transform-related tests; full host gap | MT08/10 | Present; unqualified | Post-filter moves and pivots | Precise asset adjustment | Final transform needs render test |
| F09 Source Forward axis | Orientation S3 | Yes | Source Object | Orient | MT29 | Present; unqualified | +X/+Y asset conventions | Consistent roadside facing | Renderer transform parity pending |
| F10 Independent rotation XYZ | Scatter S1 | Yes | Randomize XYZ | Core | MT09 | Present; unqualified | Coordinate/pivot expectation | Controlled variation | Record actual ranges |
| F11 Independent scale XYZ | Scatter S1 | Yes | Randomize XYZ | Core | MT08 | Present; unqualified | Nonuniform scale/material/normals | Controlled variation | Source transforms compound |
| F12 Whole scale range | Controller/native | Yes | Randomize XYZ | No retained full host proof | MT08 | Present; unqualified | RNG/identity preservation on change | Convenient overall variation | Verify separately from axis scale |
| F13 Movement/projection/normal | Scatter/bridge S1/S2 | Yes | Keep on surface / Align to normal | Core | MT10 | Present; unqualified | Fast path and expensive projection | Surface-aware placement | Not deforming-surface attachment |
| F14 Include/exclude closed lines | Scatter S1 | Yes | Area | Core | MT11 | Present; unqualified | World-XY mask semantics | Protected planting zones | Pivot masking is not mesh trimming |
| F15 Line Pattern strokes | Scatter/controller S1/S3 | Yes | Diversity / Colors | Core/Weight | MT29 + closed-line fixture | Present; unqualified | Needs strokes/source assignment | Boundary-directed groups | Not generic open-spline scatter support |
| F16 Analyzer Border/Centerline assignment | Controller/native | Yes | Analyze Surface | Core | MT28/29 | Present; unqualified | Planarity/width and branch selection | Layout from site geometry | Pilot workflow candidate |
| F17 Analyzer Points/Single anchors | Controller/native | Yes | Analyzer data: Points | Core | MT28/29 | Present; unqualified | Membership/count semantics | Targeted point layout | Single mode independent of ordinary count |
| F18 Analyzer area filtering | Bridge/controller | Yes | Area > Surface Analyzer Area | Core portions; full host gap | MT12/28 | Present; unqualified | Width/radius thins results | Procedural permitted areas | No automatic refill |
| F19 Boundary falloff | Native/controller | Yes | Area | Fall | MT12 | Present; unqualified | Later moves override boundary clearance | Softer landscape transitions | Delete/scale/density are distinct |
| F20 Per-Area falloff graphs | Controller/native | Yes | Area / graph editor | Fall sampled curves | MT12 + per-line fixture | Present; unqualified | UI graph/runtime/units | Art-directed edges | Curve UI needs visual test |
| F21 Ordered Edge Border rows | Edge S1/S3 | Yes | Edge Border / Add Edge Row | Edge/Core | MT29 | Present; unqualified | Spacing determines count | Precise borders/site furniture | No universal boundary recovery guarantee |
| F22 Edge offset/jitter | Edge/orientation | Yes | Offset inward / Jitter | Edge/Orient | MT29 | Present; unqualified | Final offset can leave surface/mask | Controlled rows | Explain local-direction semantics |
| F23 Corner retention/blending/rotation | Edge/orientation | Yes | Keep corner points / local XYZ | Edge/Orient | MT29 | Present; unqualified | Filtering may remove corner candidates | Intentional corner layout | No unconditional corner-count promise |
| F24 Street Side/trim/offset | Analyzer/controller | Yes | Street Side / Analyze Surface | Core parts; script host gap | MT29 | Present; unqualified | Partial Analyzer publication risk | Road-adjacent workflow | Planar strips, not general civil solver |
| F25 Within-layer collision | Native | Yes | Collision / Relax | Space | MT13 | Present; unqualified | Configured radii, underfill | Clearance rules | Not polygon collision |
| F26 Within-layer relax | Native | Yes | Collision / Relax | Space | MT14 | Present; unqualified | Cost/crossover and constraints | Distribution adjustment | Measured benefit pending |
| F27 Ten-layer manager | Controller S3 | Yes | Layer Manager | Smoke one layer | MT15 | Present; unqualified | Slot identity/limit | Composed landscapes | Reordering/expanded ceiling unqualified |
| F28 Cross-layer Remove Overlaps | Bridge/controller S5 | Yes | Layer Manager | Native logic tests indirectly; no retained full host pass | MT16 | Present; unqualified | Directional blocker dependencies | Multi-layer clearance | Record before/after counts |
| F29 Final Cleanup / Boundary Relax | Controller/native S5 | Yes | Layer Manager | Core | MT14/16 + final fixture | Present; unqualified | Later edits and neighbor settings | Refine final layout | Explicit count/movement behavior |
| F30 Point/Empty placeholders | Controller | Yes | Add Point / Add Empty | Weight portions | MT04 + placeholder fixture | Present; unqualified | Render exclusion/replacement semantics | Plan before choosing assets | Test replacement/edit continuity |
| F31 Point Cloud display | Preview | Yes | Viewport and Render | Smoke live cache; Core helper separate | MT17 | Present; unqualified | Shown points differ from instances | Efficient visual feedback | No FPS claim |
| F32 Proxy Box/Sphere/Pyramid | Preview | Yes | Viewport and Render | Smoke box only | MT17 | Present; unqualified | Per-layer instance/face limits | Fast display choices | “Proxy” display is not renderer proxy support |
| F33 Mesh display | Preview | Yes | Viewport and Render | No retained image/UI pass | MT17 | Present; unqualified | Simplified shading/per-face draw cost | Inspect asset silhouettes | Not final materials |
| F34 Manual/Real-time updates | Controller | Yes | Update | Limited smoke; no interactive test | MT18 | Present; unqualified | Timers/coalescing/stale state | Responsive revision workflow | Synchronous computation |
| F35 CS Edit selection/transforms | Edit S7 | Yes | Instances / standard tools | Empty stack only | MT19–22 | Present; unqualified | Identity depends on base generation | Precise art direction | No arbitrary remapping claim |
| F36 CS Edit clone/delete/undo | Edit S7 | Yes | Standard host actions | Historical guide only | MT23–25 | Present; unqualified | Gesture discovery / copied IDs | Keep local intent | Obtain current mutation evidence |
| F37 CS Edit save/legacy/suspension | Edit S7/S8 | Yes | Status / Reset Edits | Empty modifier persistence; broader guide unverified | MT26/27 | Present; unqualified | Base/slot changes; corrupt load | Recoverable editing | Actual old scene required |
| F38 Analyzer path modes | Analyzer S9 | Yes | Auto/Straight/Ring/Branched | Analyze | MT28 | Present; unqualified | Raster approximation / planar limits | Extract useful layout guides | Not CAD/engineering accuracy claim |
| F39 Analyzer Fit/Point/Min/Relax controls | Analyzer | Yes | Surface Analysis | Analyze | MT28 | Present; unqualified | Min points can relax separation; fits still constrain | Controlled sampling | Record element status/asterisk |
| F40 Analyzer spline/helper exports | Analyzer S9 | Yes | Create Boundary/Path/Point/Street outputs | No retained current UI export pass | MT30 | Present; unqualified | Snapshot ownership/undo | Reusable scene guides | Not live round trip |
| F41 Automatic final render/PFlow | Render S10 | Yes | Automatic final render | No retained actual render proof | MT32 | Present; unqualified | Ownership/material/lifecycle | Production delivery after qualification | Scene safety gate |
| F42 Corona IR/proxy handling | Render S10 | Yes | Host renderer actions | No retained current renderer proof | MT33 | Present; unqualified | Renderer APIs/proxy display mesh | Later verified renderer integration | No blanket proxy/farm claim |
| F43 Scatter bake + cleanup | Controller S6 | Yes | Cleanup only; Bake creation absent | No retained current bake proof | MT31 | Partial | Discoverability/duplicate output | Evaluated output if qualified | Engineering-assisted fixture required |
| F44 2027 MZP installation | Packaging S11 | Yes | Installer dialogs / Create category | Fresh integrity + previous isolated load | MT01/02/36 | Partial | Clean-user installation/removal pending | Test-build availability | Analyzer uninstaller absent |
| F45 Performance counters/caches | Controller/native | Yes | Some status/counters; not full report | Generator/core evidence only | MT18/34 | Partial | Incomplete full-operation measurement | Internal diagnostics | No comparative speedup established |

## Planned capabilities

| Feature | Exists in product code / UI | Current evidence | What to do with it |
|---|---|---|---|
| Licensing authority, provider, commercial activation/trial | No implemented system found | PROPOSED | Stages 09–11; no licensed/trial-ready claim |
| CPU executor / OpenCL acceleration | No backend found in current product paths | PROPOSED | Follow measured performance roadmap |
| Max 2024/2025 ports | Not in current host target choices | PROPOSED / required target | Stage 07 qualification work |
| Max 2027.2 Points/Point Instance adapter | No Cyrus adapter | PROPOSED | Optional bounded experiment |
| Field Helper input | No established Cyrus implementation | PROPOSED | Later sampling/API feasibility |
| Slope/altitude constraints, richer brush/presets | No full advertised workflow established here | PROPOSED | Validate demand; do not borrow competitor claims |
| USD instance export / procedural round trip | No exporter found | PROPOSED | Stage 08/engineering studio demand |
| Qualified farm and 32 GB envelope | Missing qualification evidence | UNKNOWN | Specific tests, not inferred from development workstation |

## Evidence to collect

Feature result supplement:

| Feature ID | Build/date | Your MT result | Screenshot/scene/log | Confirmed limitation | Lead with it? |
|---|---|---|---|---|---|
| — | — | NOT TESTED | — | — | Pending |

Copy this row for each feature tested. Keep issue IDs from Stage 04 beside the feature.

## Status table

| Item | Status | Notes |
|---|---|---|
| Current source inventory prepared | WORKS | Review output; not a feature runtime result |
| My manual results mapped | NOT TESTED | — |
| Top useful/confusing features chosen | NOT TESTED | — |
| Marketing candidates have evidence | NOT TESTED | — |

## Completion criteria

You can point to existing versus planned features, your selected MT results are linked, and unqualified capabilities are visible. The table supports choosing a focused scope rather than assuming every present feature is launch-ready.

## Do not do yet

Do not turn source presence or old guide text into production readiness. Do not increase layer limits, rename saved identifiers, or add licensing as inventory cleanup.

## Optional / later

Expand feature rows after a verified new implementation. Advanced libraries and animation need their own support/asset contracts.

## Next stage

[Stage 04 — Problems and missing pieces](04_Problems_and_Missing_Pieces.md).


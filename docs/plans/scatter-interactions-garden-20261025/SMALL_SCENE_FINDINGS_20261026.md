# Small tree/grass interaction investigation — 26 October 2026

The user supplied `Test Scene/Small Test Interaction.max` and three classes of
Interactions failures while making the Trees layer a collider and preparing nearby
grass/flowers. This is an investigation of the exact **0.87.1 Max 2027** package,
not a new plugin delivery. Tests use an owned copy and isolated profiles. The
original scene, artist profile and installed plugin are preserved.

## Reproduced findings

| Trigger | Observed result | Meaning |
| --- | --- | --- |
| Analyze with the saved layer settings | `Analysis settings outside supported range.` | Every saved layer has minimum stem **0.5 mm**, below the native **1 mm** minimum. Foliage is a valid 5%. |
| Capture Maple as a full collider | `Interaction source admission: 1M vertices / 2M triangles` | The maple has **1,109,209 vertices / 1,640,630 triangles**. It exceeds the vertex cap. |
| Capture Maple in bounding-box proxy mode | Same admission failure | Current capture converts/admits the original mesh before constructing its box. The proxy mode does not bypass the source cap. |
| Capture Orange Tree as a full collider | `Mesh collider is open/nonmanifold after seam welding; choose an explicit proxy` | The orange tree is within the size cap but fails the solid-volume requirement. |
| Capture Orange Tree in bounding-box mode | Passes native collider admission | A closed box is admitted, but a whole-canopy box is too broad to represent a trunk accurately. |
| Analyze Small Clump grass at 5 mm / 5% | Passes; **467 folded-blade guides**, zero unresolved guides | The grass has a supported profile once its invalid saved minimum is corrected. |
| Analyze Arthropodium at 1, 2, 5 and 10 mm / 5% | Unresolved roots or branch connections | Correcting the settings exposes a separate preparation limitation. This flower cannot be claimed supported by the current inference profile. |

Tree colliders do **not** need plant stem analysis. Analysis is for sources that
will bend. Trying to analyze the orange tree after correcting the settings also
hits a 2,048-rooted-group blade limit; that is not a reason to rig it as a collider.

The raw snapshots have 484,766 open edges on Maple and 341,460 on Orange. These are
pre-weld mesh measurements; only Orange reached and failed the native welded-solid
check. Open foliage cards are normal visual geometry and are unsuitable for the
current whole-object solid classifier. Raising a polygon cap alone is insufficient.

The submitted saved scene has Interactions roles off and no accepted definitions.
The screenshot actions were reproduced separately in the owned copy; this is not
evidence that the artist failed to set them in the live, unsaved session.

## Units and actual scale

System units are **1 world unit = 1 mm**, and display units are millimetres.
Millimetres are supported as a unit choice. The saved **0.5 mm** minimum is ten
times smaller than the intended 5 mm default and is invalid for native analysis.
A freshly created controller in this test has 5 mm both before and after loading
the file. The origin of the saved 0.5 value is not established; a unit/default
initialization or earlier authored change must not be asserted without a witness.

The UI also admits values outside the native contract: the world-unit minimum
spinner uses raw `0.001..10000` limits, and foliage uses `0.1..100%` while native
analysis accepts **1..100 mm** and **1..25%**. Validation and messages need to agree
in physical units.

Published source transforms confirm a physically miniature layout:

| Item | Physical dimensions in the supplied scene |
| --- | --- |
| Main planting plane | Approximately **160.6 × 128.2 mm** |
| Outer plane | Approximately **720.0 × 574.6 mm** |
| Maple instance | Approximately **99.7 mm high**, source scale 1% |
| Orange instance | Approximately **68.6 mm high**, source scale 1% |
| Arthropodium instance | Approximately **11.1 mm high**, source scale 1% |
| Small grass clump | Approximately **2.50 mm high**, source scale 5% |

These are physical scene sizes, not viewport magnification. Choose intended garden
dimensions before preparation. Changing display labels alone cannot resize the
scene. Existing Paint/Edit bindings have guarded unit/rescale boundaries; preserve
the original and rebuild/reprepare supported data in a deliberately corrected copy.
Do not silently rescale the original or relax native safety limits.

## Lightweight collider feasibility test

In a private copy only, the two tree source meshes were replaced with explicitly
authored closed cylinders: **34 vertices / 64 triangles per source**, radius
0.15 m and height 2 m in source-local coordinates. Their existing 1% instance
scale makes 1.5 mm-radius, 20 mm-high diagnostic trunk volumes. These dimensions
are a coarse authored proof, not automatic trunk extraction or accurate tree fit.

With the grass corrected to 5 mm/5% and diagnostically accepted, the existing
native system admits **3,579 grass clumps and two colliders**. Initial contact
affects 182 clumps, poses **76**, and suppresses 3,394 covered rooted groups.
Initial fit is approximately **92–95 ms** in the first two runs. These are CPU
solver samples, not presented FPS or an equal-geometry performance comparison.

This demonstrates static contact using small closed colliders. It does not deliver
independent visual/collision geometry in the plugin: the test replaced geometry
inside a disposable scene. Production support must keep the full visible trees
and bind their separate collider definitions to the same placement transforms.

The first cold movement harness and the first message-pumped retry observed a
placement rebuild and reset contact generation. Their failed assertions remain in
the evidence. A subsequent probe allows actual timer settling and records every
move. Its six movement assertions pass; its first report parser then incorrectly
treats the native three-element validation return as a JSON string. That diagnostic
parser was corrected in a separate final run; no product repair was made. The
passing final result is recorded below.
No cause or production repair is inferred from the earlier harness failures.

## Recommended implementation work

1. **Validate preparation settings in physical units.** Align UI/native limits,
   show actual offending values and source/layer names, and provide an explicit
   repair of invalid saved settings without rescaling geometry. Preserve existing
   valid prepared definitions; changed preparation requires review again.
2. **Separate collider preparation from plant preparation.** Collider layers need
   a clear shape workflow; Analyze/accept stems belongs to reacting plants.
3. **Add a separate collider definition per source.** Start with an artist-picked
   closed trunk/root proxy or compound shapes. Reuse it for every tree placement
   with the same rotation/uniform scale/position and Cyrus Edit identity. Keep the
   high-quality visual tree instanced. Whole-canopy boxes are explicit coarse
   alternatives, not natural trunk defaults. Proxy admission should not need a
   full expensive render-mesh copy first.
4. **Support the chosen flower's preparation deliberately.** Inspect its inferred
   roots/branch attachments and add a qualified model profile or authored-guide
   route. Grass success does not establish Arthropodium support, and general
   visual remeshing does not supply a correct rooted guide structure.
5. **Qualify source, lifecycle and performance cases separately.** Test this exact
   scene and a copy at intended real-world sizes, independent source transforms,
   dragging, Undo/Redo, departing-plant restoration, Manual pending preservation,
   saved-state reload and full output. Count placement rebuilds, local contact work,
   preview preparation, redraw and memory separately. Keep previous complete
   contact results if a successor fails.

Reducing visual trees to 40–50% geometry is a separate viewport-LOD feature. For
this contact problem a closed trunk proxy can be orders of magnitude smaller and
avoid foliage topology entirely. Both representations must retain explicit
ownership, source identity, cache invalidation and lifetime/resource admission.

## Evidence and implementation anchors

Local owned evidence: `build/small-interaction-20261026-01/`. `inputs.json` binds
the original/copy and exact three-host delivery's Max 2027 MZP; each host run has
loaded native paths/hashes, script fingerprint and artist-INI preservation checks.
`inspect-host/scene-inspection.json`, `queries-host/query-report.json` and
`source-identity-check.json` preserve counts, settings, units and source matching.
`proxy-host`, `proxy-warm-host` and `proxy-settled-host` retain separate attempts.
Ignored scenes, native payloads and local diagnostic output are not Git artifacts.

- [Native source admission and collider capture](../../../AminScatter/src/interactions_host.cpp)
- [Closed/welded collider validation](../../../AminScatter/src/interactions_geometry.cpp)
- [Rooted source preparation and rejection](../../../AminScatter/src/interactions_source.cpp)
- [Analysis thresholds and root inference](../../../CyrusVegetationLab/experiments/stem-live/analysis.cpp)
- [Authoritative UI limits](../../../AminScatter/tools/ui/templates/interactions-ui.ms)
- [Authoritative preparation settings/persistence](../../../AminScatter/tools/ui/templates/interactions-authoring.ms)
- [Original Interactions acceptance limits](DELIVERY_0870.md)
- [Current 0.87.1 delivery](../preset-gallery-improvements/DELIVERY_0871.md)

No product code, installer, original scene or artist profile was changed by this
investigation. The proposed implementation remains separate from the diagnostics.

## Final owned Max 2027 result

The corrected `proxy-final-host` run passes and exits normally. Six individual
Cyrus Edit commands each move the selected proxy tree by 1 mm, advance contact
generation and retain the same placement epoch/build count. Between 78 and 83
clumps remain posed during the measured moves. Timings include command plus
synchronous redraw, with no claim about presented FPS or physical held dragging:

- Command/redraw median **237.90 ms**, worst **255.45 ms**.
- Contact-fit median **92.27 ms**, worst **107.04 ms**.
- Independent double-precision mesh audit: **755,260 triangles in 180 nearby plants**,
  zero penetrating vertex/obstacle pairs, zero touching/crossing triangle pairs,
  root drift **0 m**, maximum stem-edge change **2.92%**, rigid-part edge change 0.
  Native audit passes its provisional 25% strain gate. This does not qualify
  renderer-float output, natural bending or every source.

The native command path works with these coarse trunks and supported grass.
Earlier cold/insufficiently settled rebuilds remain failed harness evidence;
actual event-loop/timer settling eliminates that observation in the final run.
This is not an independently proven cause or repair of a product defect.

All six owned hosts exit with code 0 and retain their own semantic results: two
inspection/query passes, two failed early movement assertions, one movement-pass
run with a diagnostic parser failure, and the final complete pass. Each verifies
its exact loaded modules/script and an unchanged artist INI. Only owned private
hosts were started/closed. The original scene SHA-256 remains
`fd56a2468d1e54f1219e974e7238f35c34b21e111efe874ce73082e931747075`.

The exact Max 2027 MZP SHA-256 is `c1a2272f2ec0cfb2afa8608336fd1fcb90a3f2e5938f3f80ee567c94e7b76352`.
Seven relevant implementation/template files match the frozen 0.87.1 producer.
`SUMMARY.json` in the local evidence folder provides the machine-readable outcome
and paths. The report's eight local source/report links resolve. No installer,
product-code change, Git push or knowledge-index switch is part of this task.

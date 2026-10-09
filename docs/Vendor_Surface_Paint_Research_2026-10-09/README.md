# Receiving surfaces and painted regions: Forest and Chaos

9 October 2026. Research only; no Cyrus implementation, plugin installation, licensing change or vendor-code reuse.

**The strongest design recommendation is to preserve surviving placements through stable receiver identities, and make painted coverage a separate owner from a population's models.** Chaos's tested random distribution changes most existing placements when a receiver is added, even in Density mode. Forest's tested flat, projected paint areas preserve their existing sampling and can overlap additively, including duplicate instances. Neither result establishes which calculations were skipped.

This builds on the [receiving-surface investigation](../Receiving_Surface_Research_2026-10-08/README.md), [Forest brush reconstruction](../ForestPack_Research_2026-10-08/brush/NATIVE_FINDINGS.md) and [model/painting discussion](../Product_Discussion_2026-10-08/MODELS_AND_PAINTING.md). [EVIDENCE.json](EVIDENCE.json) preserves identities and measured summaries; [reproduction instructions](reproduce/README.md) explain successful fixtures and excluded diagnostics.

## Evidence boundaries and identities

**Observed** means inspected in the owned Max host or compared from exported placements. **Documented** describes the vendor's intended workflow. **Binary evidence** describes selected instructions/types in hash-pinned installed modules. **Inference/recommendation** is our architectural interpretation. **Unanswered** is a qualification gap, not a vendor defect.

The starting branch was `codex/ui-0.74`, HEAD `65cf22e9f4ae38f0e20a8e30dff3189d796b3c3a`. Two pre-existing native source edits, earlier research, documentation changes and the landing-page directory were preserved. Cyrus comparisons below refer to the earlier frozen 0.74 host campaign and inspected source; the existing region-coverage prototype is not runtime-qualified here.

| Installed component | Identity | SHA-256 |
|---|---|---|
| Forest Pack Lite, Max 2027 | Package 9.4.3; PE 9,4,3,766; API 900 | `23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d` |
| Chaos Max adapter | Package 9.0.671707; PE 15.0.671707 | `f7fdd25428e8374174501e6bb4ebd3b83e21c5ba2c33fcdc94280c022695b887` |
| Chaos scatter core | PE 15.0.671707; API 9, build May 25 2026 | `069ababd0dbc09218928f24d5bdc860509b237f34af703581e3fd78ed5d3cf86` |

Forest's module is under `C:\ProgramData\Autodesk\ApplicationPlugins\ForestPackLite2027\Contents\plugins\2027\ForestPackLite.dlo`; Chaos's adapter/core are under `C:\ProgramData\Autodesk\ApplicationPlugins\ChaosScatter3dsMax2027`. Manifest and PE numbering are distinct; neither is silently substituted for the other. Max was 2027.1, build 29.1.0.11426. The private profile used matching extracted Cyrus 0.74 binaries but did not load Cyrus orchestration. Only disposable nodes/scenes were edited.

## Ownership: models, receivers, populations and paint

**Documented — Forest.** The Geometry list supplies models. Areas restrict or add coverage and can select a subset of those models. Paint is one area type; it requires XY surface mode. Includes are additive; exclusion order matters. Areas are processed bottom to top. This differs from assigning a separate density/population owner to every brush document. [Forest Areas reference](https://docs.itoosoft.com/forestpack/forest-plugin/areas).

**Observed — Forest Lite.** One object held one model list, a shared receiver list and two independently identified paint records. One paint record accepted strokes on receiver one and receiver two. The area's controls did not provide an independently selected receiver; the shared Surfaces list supplied input nodes. That demonstrates multi-node authoring for this projected workflow, not a private node binding inside every paint record.

**Binary evidence — Forest, retained from the prior brush pass.** The area dialog owns Max Painter callbacks; session setup gathers receiving nodes and evaluated ObjectStates. Painting performs planar integer-contour union/subtraction, simplification and publication into a referenced LinearShape. The `arpaintlist` table stores shape-bearing area records. The selected bodies do not establish a per-region receiver UUID, geodesic metric or persistence of individual dab history.

**Documented — Chaos.** The object separates target objects/factors from model objects/frequencies. Fixed Count shares a total; Density uses target factors as multipliers. Its clustering painter assigns model lists to ordered layers; upper painted layers cover lower layers and erasing reveals them. The base layer covers the surface. Its separate Edit Instances brush adds/edits individual instances. Those two painters must not be treated as the same representation. [Chaos Max reference](https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter).

**Observed — Chaos fixture initialization.** Setting only `modelNodes` and `modelFrequencies` produced no working models in the interface and zero placements. The supported `FpInterface.addModelNode` method populated group records (`modelClusterGroupIds` became `#(1,1)`); subsequent valid fixtures generated both boxes and spheres. A cached `getModelCount()` read before evaluation still returned zero. Configuration references or a successful API return alone therefore do not qualify a fixture.

**New binary evidence — Chaos.** The exported `ILayerData::create` at core RVA `0x331e0` accepts collections typed as model/opaque handles, StrokeRecords and MeshPoints, validates record counts/indices, and moves the three collections into a 56-byte owner. The Max adapter at RVA `0x86a00` converts parameter tables and node references into these collections and calls that factory. The RTTI-supported stroke rearrangement path at RVA `0x97ce0` remaps and compacts records/associated points. These are concrete layer/stroke data paths, extending the earlier string-only ownership evidence. The adapter copies 12-byte point records; **the name MeshPoint does not prove face/barycentric anchoring or receiver identity**. Those field semantics remain unresolved. Private pseudocode is not original source and was not copied into Cyrus.

## Multiple surfaces: measured placement stability

**Observed — valid Chaos three-surface campaign.** Three flat receivers measured 1, 2 and 3 m², separated along X. Two models had equal frequencies; seed 42; collisions disabled. Fixed Total requested 600. Density requested 100/m², also yielding 600. Receiver four was a distant 1 m² plane. Comparison uses model/class/full-transform multisets at MAXScript's text precision, not native candidate IDs.

| Operation | Fixed Total: count / retained old transforms | Density: count / retained old transforms |
|---|---|---|
| Unchanged repeat | 600 / 600 of 600 | 600 / 600 of 600 |
| Append distant receiver | 600 / 13 of 600 | 700 / 13 of 600 |
| Remove appended receiver, restore recipe | 600 / all 600 restored | 600 / all 600 restored |
| Reverse receiver order by clearing/rebuilding list | 600 / 0 of 600 | 600 / 0 of 600 |
| Restore original order | 600 / all 600 restored | 600 / all 600 restored |
| Remove middle receiver | 600 / 21 of 397 originally on surviving receivers | 400 / 11 of 397 originally on surviving receivers |

Moving receiver one up 100 cm in Density mode retained **all 483 transforms on receivers two and three**. Returning it restored all 600. Selection/redraw followed by explicit capture also retained all 600. These are output-stability findings. Reordering was a scripted list reconstruction; UI drag-reorder and persistent native IDs were not measured.

**Observed — larger Chaos campaign.** Twenty 1 m² planes, 10,000 Fixed Total or 500/m² Density, plus a distant receiver 21:

| Mode | Before / after count | After on original 20 | On receiver 21 | Original full model/transforms retained |
|---|---:|---:|---:|---:|
| Fixed Total | 10,000 / 10,000 | 9,541 | 459 | 163 of 10,000 (1.63%) |
| Density | 10,000 / 10,500 | 10,018 | 482 | 163 of 10,000 (1.63%) |

These are validated split-callback exports; the earlier single-callback exports are excluded. Configuration and export must be separate requests so Max can process pending changes. The analyzer rejects wrong counts, points outside the fixture and an added receiver receiving no placements. This qualifies one random recipe, not every distribution mode.

**Prior observed Cyrus baseline.** In the frozen 20-to-21 campaign, both modes retained only 2,534 of the original 10,000 positions; Fixed Count stayed at 10,000, Density rose to 10,500. Candidate IDs, basis and model assignment survived while positions changed. Reversing receiver order moved every position; restoring the original list restored the result. Moving one plane preserved placements on other planes. This is comparable in purpose to the Chaos tests, but Cyrus's full-precision native-ID comparisons and vendor text-multiset comparisons are different methods.

**Binary/source interpretation.** Cyrus's inspected `scatter.cpp` builds an area CDF over the concatenated ordered triangle array supplied by `max_bridge.cpp::surfaceMeshes`. Changing the domain changes the mapping from random samples to positions. Earlier selected Chaos core bodies also show aggregate receiver preparation, requested quantity versus measure, and ID generation involving configuration/target data. This is consistent with the runtime reshuffle; it does not identify one universally identical algorithm or prove all receivers' preparation is repeated.

## Painting: flat receivers, overlap and missing targets

**Observed — corrected Forest Lite campaign.** White Gradient distribution removed the initial bitmap-dependent zero-output fixture. One box model, 50 × 50 pixels per 100 × 100 cm, transforms disabled, Surface Area off. Two initial brush footprints produced 38 instances. Forest's normal conversion exposed two closed spline contours, 17 knots each; converting back retained the painted workflow. The automation drag produced two footprints, not a smooth continuous stroke, so this does not benchmark brush smoothness.

| Operation | Count | Original 38 full transforms retained | Extra duplicate transforms |
|---|---:|---:|---:|
| First painted region | 38 | 38 | 0 |
| Add distant, unpainted flat receiver | 38 | 38 | 0 |
| Remove that receiver | 38 | 38 | 0 |
| Remove every receiver | 38 | 38 | 0 |
| Restore receiver one | 38 | 38 | 0 |
| Second region painted on receiver two | 59 | 38 | 0 |
| Remove receiver two while receiver one remains | 38 | 38 | 0 |
| Restore receiver two | 59 | 38 | 0 |
| First region also painted over region two's footprint | 80 | 38 | 21 |
| Upper region changed to Exclude | 38 | 38 | 0 |
| Restore Include | 80 | 38 | 21 |

Both paint records remained in the area tables when receiver two was removed; its 21 placements disappeared and returned after restoration. Removing **all** receivers allowed the first region's 38 placements to remain in the Forest object's XY plane. Thus missing-target behavior depends on whether other receivers remain; it is not a proven per-region orphan binding policy. The two overlapped Include records generated duplicate model/transforms in this regular sampling fixture. A single region's contour union and separate regions' additive population behavior are different operations.

**Edition/geometric limit.** The one-receiver setter initially waited on a Forest information dialog: “Forest Lite is limited to use flat surfaces.” Dismissing the information message let the script return. Surface Mode/UV and whole Surface Area activation were disabled in this Lite fixture; they were not forced through scripting. Curved receiver painting and general whole-surface multiple-terrain behavior are therefore **unqualified**. The official reference describes XY projection along the Forest object's Z and UV distribution for suitable mapped 3D surfaces; UV distribution does not itself establish UV brush authoring. [Forest Surfaces reference](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces), [edition comparison](https://docs.itoosoft.com/forestpack/lite-and-pro).

**Observed — Chaos artist-authored layers on a flat plane and curved sphere.** A separate 400-instance fixture used a 100 × 100 cm plane and a radius-50 cm, 24-segment sphere, seed 42 and collisions off. The base layer contained only the box; Layer 1 contained only the sphere model. The normal painter authored a footprint on the plane and a short stroke on the receiver sphere, using a 20 cm radius. The first click-only attempt on the curved mesh did not author a stroke; the subsequent short drag did. No private paint tables were fabricated.

| Operation | Total | Sphere models on flat / curved receivers | Unique positions |
|---|---:|---:|---:|
| Unpainted base | 400 | 0 / 0 | 400 |
| Layer 1 flat footprint | 400 | 13 / 0 | 400 |
| Layer 1 also painted on curved sphere | 400 | 13 / 20 | 400 |
| Remove curved receiver | 400 | 53 / 0 | 400 |
| Restore curved receiver | 400 | 13 / 0 | 400 |
| Layer 2 box footprint over the flat footprint | 400 | 0 / 0 | 400 |
| Erase that upper footprint | 400 | 13 / 0 | 400 |

Painting changed model assignment while retaining all 400 positions at export precision. The 20 sphere-model placements on the curved receiver had Z positions 42.8402–48.721 cm, confirming coverage on its curved upper surface. Upper-layer painting replaced all 13 lower-layer sphere models; erasing restored the entire previous 400 model/transforms. This contrasts with Forest's additive duplicate behavior.

Removing the curved receiver compacted `layerData` from three points to the one flat point, and `layerRecords` from two records to one. Restoring the receiver kept only that flat stroke; the curved paint did not return. Chaos displayed a warning that a topological change of the total distribution mesh had deleted associated custom properties, including painted layer strokes. The surviving flat footprint remained, while Fixed Total redistributed 400 candidates onto the remaining plane (53 became sphere models). After restoring both receivers, all 400 transforms matched the earlier flat-only capture. The warning was acknowledged in the disposable scene.

**Unanswered — paint identity and geometry.** The Chaos test demonstrates strokes on multiple target nodes and upper/lower layers, but not an explicit receiver selector owned by each layer or persistent receiver UUIDs. Folded/stacked meshes, topology edits without receiver removal, target reordering with paint, and separate layers painted exclusively on different receivers remain unqualified. Public point/record values and selected binary bodies do not establish their complete anchoring semantics.

## Updates and costs: what is actually established

**Documented — Forest.** Terrain preparation has a table shared between Forest objects, a manual refresh and optional Auto. That sharing concerns receiver preparation; it does not establish shared population results. Its placement seed is normally derived from XY position, which supports a stable projected-field interpretation for the tested flat regions. [Surfaces reference](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).

**Documented — Chaos.** Automatic Updates controls reactions to source/target changes; Scatter parameter changes and Update Now have their own recomputation behavior. Temporal Consistency concerns animated rest-pose attachment, not adding receivers. The current online reference was updated August 2026, after this installed core's May build, so untested details are intended behavior rather than certification of these bytes. [Chaos Max reference](https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter).

**Observed harness limitation.** Some single-callback Chaos experiments changed properties but exported the previous cached domain/count. Hidden/unselected fixtures and even in-callback redraw did not provide trustworthy before/after measurements. A separately returned configuration request followed by capture validated the large fixture. This does not diagnose a vendor cache defect, prove a UI-only operation rebuilt placements, or qualify Manual/Live scheduling. The exploratory manual-update files are excluded.

**Observed timing.** Corrected Forest `trees.update()` calls were 3–6 ms for 38–80 placements. The small valid Chaos surface captures timed explicit update calls at 4–9 ms and geometry conversion at about 0.75–0.97 s; its 400-instance paint captures measured 4–6 ms and 0.789–1.051 s respectively. Parameter setters may have already performed or scheduled work before those timers. Large fixture conversion measured 17.750–21.239 s, while the subsequent explicit update call measured 0–1 ms. These are coarse single-run host-call observations, not scatter-solve benchmarks. Geometry preparation, candidate generation, filtering, collision work, GPU upload and drawing were not independently timed. There is no vendor FPS or cache-hit measurement.

Forest exposes distinct `trees.update()` and `trees.update_ui()` methods. The latter plus selection/redraw followed by an explicit capture left output unchanged. That establishes stable output after the operation sequence, not that no solve happened. The prior Forest binary work separates placement/collision/sample-cache and display paths; it does not recover a complete dependency-invalidation graph.

| Operation | What the campaign establishes | What it does not establish |
|---|---|---|
| Chaos receiver add/remove/order | Updated placement positions/counts change; restoring recipe restores output | Whether every receiver mesh was prepared again |
| Chaos receiver translation | Moved receiver changes; other receivers' 483 transforms survive | Cache reuse on those unchanged receivers |
| Chaos layer paint/erase | Model assignments change; all 400 positions survive | Candidate solve, filter or upload work skipped |
| Forest painted-region membership/receiver changes | Counts and overlap change; original 38 transforms survive | Complete dirty-stage graph or per-stage reuse |
| Forest `update_ui`, selection/redraw | Subsequent explicitly updated export is unchanged | A passive interface-only refresh or zero solves |
| Chaos selection/redraw | Subsequent explicitly updated export is unchanged | Passive observation, buffer reuse or unchanged upload counts |
| Automatic/manual and source-model edits | Official update contract; exploratory deferred reads were unsuitable | Qualified scheduling or timing in this installed build |

## Recommended Cyrus contract

These are design choices for our own implementation, not recovered vendor requirements.

| Responsibility | Forest evidence | Chaos evidence | Frozen Cyrus / existing prototype | Recommended Cyrus |
|---|---|---|---|---|
| Receivers | Shared object list; XY projection | Shared target list and factors | Shared setup list; aggregate ordered binding | Stable receiver records; list order is presentation |
| Models | Geometry list; area subsets | Object models; layer memberships | Paint sets own models and can work unpainted | Name the model/count owner Population; regions supply optional coverage |
| Density stability | Flat paint test preserves 38 | Adding receiver reshuffles most points | Global CDF reshuffles positions | Independent deterministic sampling on unchanged receivers |
| Fixed Total | Image density is not an equivalent exact-total mode | Exact total across receivers | One total across surfaces | Reallocate quotas; preserve surviving points on each receiver |
| Region overlap | Includes can create duplicates | Painted upper layer replaced 13 model assignments; erase restored them | Existing native region prototype uses maximum coverage per receiver | Union coverage within a population; explicit relationships between populations |
| Missing target | Flat fallback observed when none remain | Removed sphere stroke was discarded; restoration did not recover it | Frozen binding safely rejects; native prototype skips removed targets | Retain authored region, mark missing/inactive, never silently retarget |
| UI/display | Separate public refresh methods | Preview controls; lazy export pitfalls | Retained buffers; unchanged publication checks | Separate dirty stages and observable reuse counters |

**Adding receiver 21 in Density mode should usually preserve existing placements.** Key candidate identity/random channels by stable population and receiver identity plus local sample identity, not receiver-list index or global candidate ordinal alone. Cache copied receiver geometry/preparation by its own revision. Generate/filter the new receiver and rebuild only dependent collision neighborhoods or other genuinely shared stages. Distant additions without shared collision effects should leave the previous receivers unchanged. Near additions can legitimately change cross-receiver collision acceptance; the collision scope and priority must stay explicit.

**Fixed Total cannot retain every old instance and populate the new receiver while keeping the same total.** Allocate quotas deterministically by weights/area, then keep a stable prefix/subset of each receiver's candidate stream when its quota shrinks or grows. For 10,000 across 20 equal receivers, adding the 21st implies about 476 instances on the newcomer and corresponding reductions elsewhere. Surviving instances should keep positions, model choice and transforms. Expose global redistribution as a deliberate action if desired; keep-existing placement with population growth is a different policy from Fixed Total.

**A border plus an optional fade curve is a sound terrain workflow, but a universal projected vector brush is insufficient for arbitrary meshes.** Start with hard coverage and fading disabled. Offer inward/outward/both distances in world units and a density curve evaluated from signed boundary distance. Outward fading must expand the eligible sampling domain as well as the weight; otherwise there are no candidates outside the border to fade. Scale falloff is a separate artistic effect. Use a stable random threshold per candidate so adjusting density/fade changes membership without gratuitous movement.

Keep planar/projected contour authoring distinct from surface-bound authoring. A curved hill that is a height field can use XY projection; a folded mesh, wall, sphere or stacked sheet cannot generally share that projection without ambiguity. Preserve receiver identity and mesh anchors for surface-bound regions, with explicit topology-change handling. Contours can be canonical for a terrain mode while distance tiles/fields are derived caches; an all-mesh rewrite is not justified by the current smoothness evidence.

Within one population, combine overlapping region coverage as a union/maximum and sample each candidate once. Across populations, expose layering/replacement/addition as deliberate controls. Do not copy Forest's duplicate-producing Include behavior by accident. The pre-existing `cyrusApplyRegionCoverageKeyed` source already uses receiver-scoped maximum weights and retains documents whose targets are absent; that is relevant prototype work, not a feature qualified by this report. The frozen UI still requires one shared receiver for painting.

Separate receiver preparation, candidate generation, coverage/filtering, collisions, model geometry, instance transforms and viewport presentation revisions. Source meshes should be retained when only placement transforms change. Selection, panel refresh and unchanged redraw must not dirty placements. Manual should retain pending edits until Update; failed work must keep the last complete publication. Add counters for cache hits/misses, solves and actual buffer uploads before making incremental-processing claims.

## Remaining acceptance tests

The unresolved high-value tests are Forest Pro curved/stacked receivers and whole-surface sampling; Chaos folded/stacked painting, receiver reordering with paint and explicit per-layer targeting; a split-callback Manual/Live campaign with a known passive observation API; stable native identities through save/reopen; nearby additions with collisions; and stage-level solve/upload/draw instrumentation. Forest has no directly qualified Fixed Total counterpart in this Image/paint campaign. No licensing-restricted feature was enabled to fill those gaps. The final owned scene was saved locally; reopening it was not tested.

The practical conclusion is to improve **ownership and placement identity first**. A contour-based terrain tool can then be tested as one authoring mode. Its speed advantage over Cyrus's surface-aware brush still needs equal-population measurements of input, coverage rebuilding, scatter publication and drawing.

## Delivery and preservation

The seven inspected installed inputs and eight inspected Cyrus source/generated files matched their starting SHA-256 hashes at delivery. The private scene was saved as `build/vendor-surface-paint-20261009-01/host/vendor-fixture.max`. The copied Ghidra adapter project was saved and closed; both owned processes were stopped after PID, executable and private-argument checks. The immediate process-exit check raced shutdown; a separate follow-up confirmed both exited. No artist session, installed plugin or product source was changed. Raw copied binaries, pseudocode, scenes and placement exports stay in the ignored run; the report, evidence summaries and reproduction scripts are the reviewable deliverables.

# Large scene experiment — 19 October 2026

Supplemental experiment on the unchanged Cyrus Arrange 0.3.2 development pair in owned normal 3ds Max 2027 sessions. Main experiment03 and follow-up experiment05 are terminal passes with all identity/preservation guards true. Both editable and ordinary-mesh scene deliveries saved and reopened successfully. This is not installer/release qualification.

## Observed integrated scene

590 generated placements; 15 independent editable arrangements; 714 scene nodes after reopen. Full-size real prepared books, plant/decor groups and tables are mixed with newly modeled cabinets, stairs, candles, fruit/bin placeholders, appliance and sedan/road geometry. One arrangement owns one receiving set; a nearby unrelated object is not implicitly a collider.

| Arrangement | Requested | Placed |
| --- | ---: | ---: |
| `Arrange_Library_1` | 100 | 100 |
| `Arrange_Library_2` | 100 | 100 |
| `Arrange_Library_3` | 100 | 100 |
| `Arrange_Library_4` | 100 | 100 |
| `Arrange_Coffee_1` | 12 | 12 |
| `Arrange_Coffee_2` | 12 | 12 |
| `Arrange_Coffee_3` | 12 | 12 |
| `Arrange_Coffee_4` | 7 | 7 |
| `Arrange_Side_Table` | 6 | 6 |
| `Arrange_Decor_Groups` | 16 | 16 |
| `Arrange_TV_Console` | 24 | 24 |
| `Arrange_Stairs` | 72 | 72 |
| `Arrange_Cabinet_Devices` | 2 | 2 |
| `Arrange_Two_Way_Road` | 12 | 12 |
| `Arrange_Path_Plants` | 15 | 15 |

Fill and path-spacing requests are the computed targets returned by Generate, not the dormant Copies spinner. All final targets filled; the separately recorded forbidden-shrink cabinet deliberately produced 0 of 2.

## Actual host actions

- Mounted the real native Modify views and used their handlers for bulk intake, Generate, quantities, Fill, random scale, fit, gaps, minimum copies, obstacles, optional approach, path controls and protection.
- Generated 400 upright detailed books across four divided libraries; 72 mixed stair props; 16 compound decor groups; 12 cars (six per lane); 15 plants from center spacing.
- The occupied cabinet rejected two full-size devices, then accepted two uniformly fitted devices when a 60% minimum was permitted.
- Same-seed repeats, automatic fresh seed, protected-book preservation, Undo/Redo and invalid scale draft rejection passed.
- Saved/reopened all 15 owners with exact poses/settings/minimums/path fields/obstacle names/approach; one reopened 100-book arrangement regenerated identically.
- Original source geometry/transform checks and all 131 copied map byte checks passed. This does not independently establish every output UV or shader binding.
- The complete host run reported 288 checks with zero failures. Many checks concern dependencies, so this count is not 288 distinct plugin features.

## Timing scope

Measured synchronous actual Generate handler calls in this one populated scene:

| Operation | Milliseconds | Placed |
| --- | ---: | ---: |
| `Library_1_100_books` | 139 | 100 |
| `Library_2_100_books` | 133 | 100 |
| `Library_3_100_books` | 108 | 100 |
| `Library_4_100_books` | 114 | 100 |
| `Coffee_1` | 223 | 12 |
| `Coffee_2` | 162 | 12 |
| `Coffee_3` | 65 | 12 |
| `Coffee_4` | 41 | 7 |
| `Small_side_table_capacity` | 48 | 6 |
| `Reusable_groups_16` | 409 | 16 |
| `TV_console_arbitrary_props` | 129 | 24 |
| `TV_console_clear_approach` | 114 | 24 |
| `Stairs_72_mixed_props` | 95 | 72 |
| `Cabinet_original_size_first` | 46 | 1 |
| `Cabinet_forbidden_shrink` | 51 | 0 |
| `Cabinet_fit_60_percent` | 94 | 2 |
| `Two_way_12_cars_random_spread` | 70 | 12 |
| `Straight_path_center_spacing_reverse` | 165 | 15 |
| `Dense_scene_repeat_seed` | 162 | 100 |
| `Dense_scene_new_variation` | 135 | 100 |

Reopened library Generate measured 230 ms (retained in result.txt; the metrics table was exported before reopen). These timings exclude model intake, application startup, scene load/save, independent exports, rendering and UI gesture latency. They are observational, not controlled benchmark or viewport FPS results.

## Independent geometry evidence

Every one of the 590 outputs passed actual world-source affine/topology, final scale and receiver-triangle-union base support checks. Worst observed world vertex deviation: approximately 0.00739123 mm against a 0.05 mm tolerance. Contact uses referenced triangles in the scaled 0.5 mm bottom band; full-body overhang alone is not a support failure.

216,235 exported relevant geometry pairs were examined, including cross-arrangement output pairs and deduplicated receiver/explicit obstacle nodes. Initial pass: 216,217 AABB separation certificates, 14 actual-mesh projection certificates, four unresolved compound-model candidates. The original report remains `review_required`. A separate actual closed-component refinement certified those four, preserving the original result.

| Candidate | Requested gap | Certified minimum component gap |
| --- | ---: | ---: |
| Coffee 2, outputs 5 / 10 | 15 mm | 18.30249 mm |
| Decor groups, outputs 2 / 9 | 35 mm | 49.98584 mm |
| Decor groups, outputs 7 / 16 | 35 mm | 38.29150 mm |
| Decor groups, outputs 8 / 11 | 35 mm | 37.61792 mm |

Certificates prove separation within the stated geometry/tolerance scope; their distances are conservative bounds, not exact closest-point distances. The exported pair set excludes unbound architecture and hidden source palettes. Surface edge margins, full effective shader/UV/normal preservation and physical stability/gravity are not independently proved by this export. Literal material-ID differences on flattened compounds are not evidence of lost materials; effective per-face bindings would need a separate comparison. The follow-up road proof below independently covers the actual car lane domains and headings.

## Independent integrated-road proof

The actual reopened/repeated experiment05 road export passed a separate frozen wrapper around the unchanged maintained road verifier. It verified twelve complete 4520 × 1900 × 1500 mm sedans, six per direction, exact final scale 1.0, actual source/output topology and transforms, opposite headings, arc/offset/spread bounds, complete-body containment inside independently evaluated curved lanes, and tyre support on the five real receiving road bands.

Native lane IDs are 7 and 8; output indexes 1–6 and 7–12 bind to those separate lanes. Maximum vertex deviation was approximately 0.00590008 mm. Support coverage was approximately 1.0. The conservative complete-box separation lower bound was 174.32030 mm against a requested 100 mm gap. All five counterfactual controls were rejected for the intended reason: lifted wheels, wrong lane, changed scale, reversed direction and overlap.

The proof checked the exact terminal host, twelve identity/preservation guards, the 189-input map and unchanged native/verifier cohort. It did not repeat the whole-scene geometry audit or promote the run to release qualification. Report: `build/large-scene-lab-20261019-review01/integrated-road-review01.json`, SHA256 `2de55ae0b4ab6c45be02f42c2f5141ee46531ba5baeced7ca4da3311ffdc29d6`.

## Follow-up editing observations

The follow-up uses a copied experiment03 scene and owned map copies. No original scene, product code or artist installation is edited. Experiment05 completed with **1,911 passed assertions and zero failures**, seven real Generate calls and all twelve host guards true. The large assertion count includes per-map and per-object copying/readback checks; it is not a count of distinct features. Its evidence remains separate from experiment03.

- Coffee 3: duplicate bulk intake preserved assets/settings/output; Remove obstacle removed only the tray binding; stale index/revision mutation rejected; adding the tray back and generating with the original seed restored the full original state. Binding changes did not publish new output before Generate.
- Cabinet: permitting fit but keeping its minimum at 100% reproduced 0/2. Actual native feedback was `Last Generate: 0 placed. The tested space is occupied. No smaller fit was verified.` The highlight showed current failure boxes and toggled off without changing nodes, selection or accepted state. No checked-size suggestion was returned, so **Use checked size was unavailable and is not a passed exercise**. Restoring the 60% minimum generated both devices and the original state. This is a reproducible fit-advice coverage limitation; no incorrect placement is inferred.
- TV: disabling Clear approach with the same seed retained 24 placements and the identical layout. One Undo restored settings/approach/poses. This fixture verifies the transaction but does not isolate an access-volume rejection.
- The actual minimum ledger contains Coffee 1 book asset 2: minimum 2, actual 2; plant asset 4: minimum 1, actual 2; stairs book asset 9: minimum 12, actual 20; fruit asset 11: minimum 6, actual 23. Bulk source ordering must not be used to name a minimum. There was no bin minimum in this scene.

Follow-up handler timings: coffee obstacle removed 124 ms, restored 83 ms; forbidden cabinet 100 ms, restored fit 73 ms; TV approach off 137 ms; reopened curved-road repeat 63 ms; reopened straight-plant repeat 178 ms. These have the same observational timing exclusions as the main run.

## Separate ordinary-mesh delivery

After saving and reopening the editable scene and repeating both paths, the test created 590 fresh core mesh nodes from actual generated world geometry. Every copy passed world vertex comparison within 0.03 mm, exact triangle indices/material IDs/smoothing/map arrays and an identical material-root reference before any original owner/output was deleted. After conversion the scene contained no Arrange owners, native Arrange classes or output ownership tags. All 590 descriptors matched again after reopening the new viewing scene. The editable file and original experiment03 file remained byte-identical through this bake.

The bake checks **generated output to ordinary mesh**, not every original compound child to generated output material/UV binding. Specified corner normals and all renderer-specific material properties are outside its independent comparison. No artist 0.3.1 runtime was launched. The viewing file is a practical ordinary-mesh delivery, not an installed compatibility or relocation qualification. Both final scenes point to the verified 131 maps adjacent to experiment05; twelve material-graph filename entries resolved to those owned copies.

## Identity and preservation

- Native build: `build/native-032-release10/receipt.json`, passed 21 native suites; unchanged 189-input map.
- DLX SHA256: `0ef8ef44e0361f6622bb86507546ae86ad25b7e12e2b5bd7079c2f52cf9af2ff`.
- Storage DLH SHA256: `c5edb8732c607295c3cc1a17752a25508c7b254486da2929e1478026c79d6a7b`.
- experiment03 receipt SHA256: `aeb91f2166ad486a379eb81d6ca77f94c424c9bf1d76c8094b148bdfd2f94ec2`.
- Produced editable scene SHA256: `7489119f3d746a1a2d3edf5b27bb3f074aeeb6c4a65fedc327b3ff5979dc2608`.
- experiment05 receipt SHA256: `76e3b28302273b7caef9053ffd5e546ed98d9550ef3e933f9722282d5d6bcdae`.
- Final editable scene SHA256: `684bb9d6601e388bbcfae16d356c7aaeacb42623ee57d67d19fb914444a06fbd`.
- Final view-only scene SHA256: `68d2c3fcbadb7f49baae2ae8db0435c4ed09dc85660b9decf607a14ef5a459fa`.
- Every loaded/native/source/private-script/profile guard passed; terminal Max exit 0. No computer use, artist-session control or artist installation.
- experiment01 and experiment02 remain failed test-harness attempts (reserved parameter and missing forward globals), before scene creation. They do not establish plugin defects. A build-only launcher correction accepts Max's normal encoding/trailing-slash rewrite of plugins.ini while requiring its exact directory semantics; executable input bytes remain strict.
- experiment04 remains rejected: a reserved `off` identifier stopped MAXScript parsing before scene work. The parent then corrected the lab script before the host finished shutting down, so its `lab_ms_inputs_unchanged` guard correctly failed. Other terminal identity/profile guards passed. This run provides no accepted scenario evidence. Both its original private input and the guard failure are retained; the correction was frozen before fresh experiment05.

## Evidence locations

- Scene, 131 maps, four actual Corona renders, result/metrics/settings/metadata and 15 mesh exports: `build/large-scene-lab-20261019-01/runs/experiment03/`.
- Final editable/view-only scenes, their owned 131 maps, follow-up report/minimum ledger and actual road export: `build/large-scene-lab-20261019-01/runs/experiment05/`.
- Frozen independent reviewer, arithmetic and negative synthetic controls, actual review and four-component refinement: `build/large-scene-lab-20261019-review01/`.
- Test-only launcher/scenario code: `build/large-scene-lab-20261019-01/`.
- No product C++, MAXScript, installer or maintained test code changed for this experiment.

# Imported furniture and accessories

## Scope and current status

This bounded real-model trial uses **Cyrus Arrange 0.1.3 native46** in Max 2027.1. The build passes twelve CTest executables / 117 cases. Its portable import probe08 passes **432/0**, including all five original models and exact restoration of seventeen importer settings. The original-model workflow and four-render trial passes **612/0** against the same native pair: physical and appearance-data checks, reroll/lock/selective regeneration, Preview/Commit, save/reopen and portable texture relocation. It publishes three full-size cabinet props and twelve shelf props from thirteen requested. Both processes match the exact loaded modules/private INI and preserve artist-profile hashes. Root and an independent reviewer inspected the four actual Scanline images. See the [usable examples](IMPORTED_EXAMPLES.md) and [release ledger](RELEASE_VALIDATION_0.1.3.md) for exact artifacts and delivery status.

Earlier workflow01/02 stopped on test-script parser errors. Native44/workflow03 then reached real setup analysis and exposed two independent issues: a strict test Float/Double mismatch, and rejection of sub-micron height variation on the broad shelf boards. The test type repair preserves all numeric values and assertions. The promoted [numerical support correction](NUMERICAL_SUPPORT.md) preserves original geometry and applies the existing contact tolerance. It has fresh native/golden/fault-injection, complete original-model workflow and reviewed render evidence. The chronology below preserves earlier stage-specific failures and pending statements; it does not override the current summary.

The intended visual scope is **Imported Poly Haven geometry — Standard diffuse adapter / Default Scanline**. Original Physical Material/PBR, third-party renderers, glass accuracy and arbitrary proxy objects are outside this trial. Original geometry, material IDs and UVs must remain available for comparison; no model resizing or topology repair is used to make the tests pass.

## Sources and licenses

The five assets are distributed under [Poly Haven's CC0 policy](https://polyhaven.com/license), with explicit CC0 links on their individual pages. The [CC0 deed](https://creativecommons.org/publicdomain/zero/1.0/) permits reuse. Credits below are retained voluntarily; no endorsement is implied. The provider's asset-info API has no license field, so license evidence comes from the pages and policy, not an invented metadata tag.

| Model | Author | Approximate catalogue dimensions, XYZ mm |
| --- | --- | --- |
| [Modern Wooden Cabinet](https://polyhaven.com/a/modern_wooden_cabinet) | Patrik Pangerl | 2440 × 520 × 680.14 |
| [Wooden Bookshelf Worn](https://polyhaven.com/a/wooden_bookshelf_worn) | Ulan Cabanilla | 1373.95 × 581.30 × 2063.44 |
| [Standing Picture Frame 02](https://polyhaven.com/a/standing_picture_frame_02) | James Ray Cock | 216.89 × 102.29 × 266.39 |
| [Ceramic Vase 02](https://polyhaven.com/a/ceramic_vase_02) | James Ray Cock | 219.84 × 221.45 × 309.29 |
| [Wooden Bowl 02](https://polyhaven.com/a/wooden_bowl_02) | Kuutti Siitonen | 130.71 × 124.54 × 73.10 |

Five FBX files and six diffuse/artwork maps total 5,235,387 bytes. The source manifest records every URL, byte count, provider MD5 and independently computed SHA256. Its SHA256 is `c222487d78c3ffea0a8dabb15652a0005b83959d6b778981b5273cb652283d5e`. Catalogue dimensions are an approximate external check, not a replacement for measured Max geometry.

## Reproducible import boundary

The current fixture root is `CA_TEST_ROOT + "tests/data/imported-model-assets/"`. All eleven original CC0 files, the source manifest, credits and license provenance are covered by the normal source/hash inventory and copied into the owned runner's private bundle. The probe verifies source and private-copy SHA256/size before and after import, and imports only its private copies. There is no absolute external asset-root or download fallback.

Historical probe01–03 used external research files under `build/`; separate before/after binding receipts supplemented their normal runner receipts because those files were outside the source inventory. Those original bindings and failed runs remain preserved. Portable probe04 through probe07 use the source-covered tree instead.

The actual importer is `FBXIMP`, class ID `(13766307, 0)`, in `fbxmax.dlu`, installed with Max 2027.1 build 29.1.0.11426. Its SHA256 is `df58af7e6abb23214be9f463a9ce78f3911d853a2d1e79b96ed2eab685c21431`. The probe declares a millimetre scene and verifies importer settings by readback. It requests geometry without animation, cameras, lights, skin or point caches. It preserves smoothing groups and requests axis/unit conversion to Z-up millimetres. It records the importer's actual scale factor instead of imposing a second scale correction.

Independent geometry inventory uses raw world-space `snapshotAsMesh` vertices, without multiplying by another node transform. It records original node/object transforms, vertex/triangle counts, bounds, map channels, smoothing groups, face material IDs, material leaves and texture slots. Normal samples from this probe are render-corner samples; they do not claim to expose original `MeshNormalSpec` identities. The separate native45/workflow04 passes source/output appearance-data parity for its fixed Standard adapter. Actual rendered appearance remains a separate pending check.

## First actual probe: diagnostic evidence

`build/host-import-probe-01` on native40 completed **377 passes / 3 failures**, with correct loaded native/storage modules, private profile and unchanged artist profiles. It is a failed diagnostic run, not import qualification. External before/after binding confirms all eleven source files remained unchanged and private copies matched their hashes.

- The bookshelf has one geometry node and 10,106 triangles. Its measured XYZ dimensions agree with the catalogue.
- The frame has one geometry node and 2,986 triangles. Its dimensions agree. Its actual material IDs are 1 artwork, 2 wood and 3 glass. The downloaded maps cover artwork and wood. The later workflow uses an explicitly simplified Standard transparent cover; this first probe did not qualify that adapter.
- The vase evaluates to 11,128 triangles, while catalogue metadata lists 2,756. Its measured dimensions are approximately 218.38 × 218.38 × 309.19 mm and pass the declared `max(5 mm, 2%)` dimensional tolerance. A passive read of the hash-pinned FBX subsequently found 5,566 control points and 5,564 quad polygons, yielding exactly 11,128 triangles. The difference is in the downloaded source topology versus catalogue metadata; no import-subdivision, decimation or rescaling claim is needed.
- The bowl has 4,666 triangles and dimensions agreeing with the catalogue.
- The cabinet's body and two doors total 24,976 triangles, matching the catalogue. The next imported path object has 144 vertices and zero faces. The probe incorrectly treated any empty triangle surface as a failed mesh, stopping the cabinet inventory before its second path. A successor must inventory these vertex-only objects explicitly and retain them in the scene. They contribute no triangle support surface.
- All seventeen queried importer settings are supported. After `PopSettings`, only `ConvertUnit` differs: the original snapshot was taken in the initial centimetre scene, while restoration was checked in the millimetre scene. The first proposed correction established the same host unit context before both snapshots and retained the full comparison. That hypothesis was subsequently disproved by probe03 below. The failures are preserved; the setting is not omitted.

The current plugin deliberately rejects an explicitly bound empty mesh. The representative cabinet arrangement will author its furniture selection from the three actual mesh surfaces and leave the original path nodes present but unbound. That selection requirement must be visible in the example instructions; this trial does not establish automatic cleanup of arbitrary imported hierarchies.

## Native41 diagnostic: corrected inventory and failed cleanup

Native41 passes all eleven CTest targets / 110 cases. `host-import-probe-02` did not reach the script: Max crashed during startup with an access violation at address zero. Its owned worker dump and process identity are preserved; artist sessions/profiles were unchanged. There is no confirmed caller or root cause, and this attempt provides no import qualification.

The identical fresh native41 retry, `host-import-probe-03`, completes **428 passes / 2 failures**. All five models now have complete saved original scenes and passing dimensional inventories. The cabinet has three triangle surfaces and two retained vertex-only meshes; its triangle-surface bounds are approximately 2440 × 520 × 680.142 mm. All eleven original files and private copies again pass external hash binding. Both actual loaded modules/private profile match, with unchanged artist profiles.

At that stage only importer cleanup failed: `ConvertUnit` read `cm` before Push and `mm` after Pop, even when both observations used a millimetre scene. The host-unit-context explanation was therefore insufficient. The successor explicitly logged Pop's observed state, restored the saved `ConvertUnit` through the documented setter, and required all seventeen settings to match exactly. That is **PopSettings plus explicit saved-unit restoration**, not a claim that Pop alone restores the observed setting. It changes no imported model and does not hide or discard either failed probe. The actual portable successor results follow.

## Portable import acceptance

`build/host-import-probe-04` passes **432 / 0** against native42, which passes eleven CTest targets / 110 cases. Both loaded module paths/hashes, the private profile and artist-profile preservation checks pass. The source map now includes all eleven original CC0 files, the manifest, credits, license provenance and a portable sidecar under `tests/data/imported-model-assets/`. The runner copies that tree into its private bundle; no absolute external asset root is needed. Source and private-copy SHA256/size checks remain active before/after import.

The run logs the post-Pop state, explicitly restores the saved original ConvertUnit through the documented setter, and confirms all seventeen settings exactly. All five original-size geometry inventories, saved original scenes and dimensional checks pass. The import receipt is bound as an execution dependency before the same-candidate imported artist workflow starts; it does not pre-qualify that workflow or its eventual renders.

`build/host-import-probe-05` repeats **432/0** against native43, again passing both actual loaded-module paths/hashes, the private profile and artist-profile preservation checks. Native43 also passes eleven CTest targets / 110 cases. The original eleven portable source files remain unchanged. These two probes establish their recorded import/inventory scope on their respective exact pairs, without qualifying a later source map.

## Preserved imported workflow parser failures

| Attempt | Actual result |
| --- | --- |
| `build/host-import-workflow-01`, native42 | Stops before execution at an inline numeric `case` clause in the test script. Compact `5:2` text is parsed as a time literal instead of the intended category/value clause. The successor spaces the unchanged Frame/Vase/Bowl cap values in multiline clauses. |
| `build/host-import-workflow-02`, native43 | Stops before execution with `Syntax error: at else, expected <factor>`. The new test script uses `if … do … else`; the proposed minimal correction uses `if … then … else`. |

Both are **test-script parser failures**, not observed native placement or appearance failures. Neither reaches a workflow assertion or emits the loaded-module/private-profile confirmation marker; unchanged binary and artist-profile checks alone do not establish those missing runtime gates. Both failed receipts remain preserved. Later actual parser checks and native45/workflow04 provide their own success receipts; they do not turn these failed attempts into passes. Static lexical checks alone did not establish parser acceptance.

## Final native46 acceptance

1. **Probe08 passes 432/0:** portable import inventory, exact composite settings restoration and original-source preservation on the final native pair.
2. **Workflow/render trial passes 612/0:** actual artist controls on both furniture models, including analyze, categories, accessory registration, generate, repeat/reroll, lock, Preview/Commit and save/reopen.
3. The same rendered trial checks evaluated source/output world geometry, UV/material associations, sampled support contact, full envelopes and deterministic records. Requested/accepted/underfilled counts remain explicit.
4. Four actual Default Scanline images of the fixed seeds and named adapter were inspected by root and an independent reviewer. That review complements numerical checks; hidden contacts and general aesthetic quality remain separate limits.
5. Matching scenes, original inputs, six maps, relocation helper, credits and hash-bound evidence are in `examples/imported-0.1.3`. [The example guide](IMPORTED_EXAMPLES.md) explains relocation and [the release report](RELEASE_VALIDATION_0.1.3.md) identifies the exact qualified MZP and source/examples delivery. Historical failures remain preserved.


## Native45 original-model workflow acceptance

The exact native45 pair passes portable probe07 **432/0**, followed serially by
`host-import-workflow-04` **595/0**. Both normal process exits match the actual
loaded main/storage modules, binary hashes and private profile, with unchanged
artist-profile hashes. The initial shelf target is13 and12 are accepted; the
reported underfill is1. The TV target is3 and all3 are accepted. No model is
resized to meet those targets.

The run verifies actual full-size source/output meshes and physical envelopes,
repeatable seeds, reroll, logical locking, selective shelf regeneration, Preview
retention and Commit, saved native bindings/rules, reopened Generate and explicit
portable six-map relocation. Original vertices, faces, material IDs, smoothing,
UVs, render-corner normals and effective adapted material leaves are compared.
These are bounded sampled-contact/axis-aligned-envelope and fixed-material
checks, not gravitational stability or arbitrary renderer qualification.

The three saved scenes and portable-example tree remain in that immutable run.
They are development evidence. A fresh native46 candidate changes only readable
UI count formatting and its test expectation; matching final examples, renders,
functional/performance tests and installer still require their own receipts.

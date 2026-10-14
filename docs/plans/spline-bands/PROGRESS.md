# Spline bands implementation evidence

Implementation authorized 12 October 2026. This work covers R01â€“R12 and P0â€“P6 in the existing plan; an intermediate native pass does not complete the feature.

## Baseline

- Branch: `codex/workflow-0.75`; HEAD: `049654929407df11ef5cba0c964514d8de4ec5aa`.
- Scatter source 0.79.6/schema 56; last packaged delivery 0.79.5.
- Initial tracked tree was clean. Existing untracked design assets and knowledge-curation drafts are unrelated and preserved.
- The implementation baseline receipt is local: `build/spline-bands-20261012-01/baseline.json`. Preserve `baseline.json` beside this document as the original research receipt.
- The plan now preserves schema-56 typed units and the staged native/script publication correction. GPU realization remains a separate required witness.

## Acceptance tracking

| Milestone | State | Evidence required |
| --- | --- | --- |
| P0 transport, geometry, sampling, radius/units and costs | Implemented; bounded qualification passes | Current transport, analytic/independent geometry oracles, supported Auto classes, physical units, CPU cost gates and primitive host/resource measurements pass; heavy artist workloads remain |
| P1 interval correction and persistent provenance | Implemented; bounded qualification passes | Current exact transport, owner dictionaries, paired radii, copy/Undo and host round trips pass |
| P2 authoring UI | Partially qualified | Scripted authoring/persistence and native Undo pass in both hosts. Selected physical controls and density drag pass in Max 2026 at 96 DPI; the full container/keyboard/DPI matrix remains |
| P3 Independent fields and density | Implemented; bounded qualification passes | Prepared fields, independent G/D oracles, host decisions, movement, admission and integrated publication checks pass |
| P4 colors and field displays | Implemented; bounded qualification passes | Field/radius integration, Manual/Live/Undo, rollback and image checks pass in both hosts; private GPU failure/recovery passes in 2027. Primitive workload/cost gates pass; heavy artist and complete physical acceptance remain |
| P5 Auto Radius | Implemented; bounded qualification passes | Paired metrics, source families, cache, failed successors, native Undo, units/load/merge and Manual/Live checks pass in both fresh integrated hosts; representative performance/artist acceptance remains |
| P6 integrated qualification | Partially qualified | Both-host integration, actual Scanline comparison, targeted physical controls and measured costs pass as scoped below. Complete artist/DPI/renderer/device/long-session acceptance remains |

The overlap contract remains a shared candidate population: 100% Sphere plus 25% Box emits 80%/20% in the overlap before subsequent masks/spacing. Band competition can change selected models; it does not weaken F03 independence between layers without shared dependencies. Paint Area overlap retains its existing max-density policy.

## Native experiments

- Frozen original baseline: all 16 SDK-free suites passed, 4.73 s total; receipt `build/spline-bands-20261012-01/baseline/receipt.json`.
- Field probe 01: all 17 suites passed. Probe 02 failed compiling the new test due to an ambiguous `Path` name; its failed log is retained. Probe 03 qualifies the corrected source, with all 17 suites passing in 5.01 s.
- Probe 03 independently checks rectangle miter geometry, a finer-grid concave offset reference, inward collapse, holes/winding, translated geometry, occupancy/mixture/Empty outcomes, source/Band ordering, finite work rejection and transformed radius enclosure. Its numerical harness reports 132,308 assertions; that is not 132,308 distinct acceptance scenarios.
- Probe 03 worst normalized progress error: rectangle 0.000468351, concave reference 0.00048545, below 1/256. The reference invokes Clipper at independently chosen finer-grid offsets, not the prepared lookup levels. Neither case proves all topology/precision combinations.
- Original flat Rounded CPU scatter baseline: 100k candidates median 48.81/50.56/61.05 ms for 1/8/32 Bands; 20 warm runs, one cold run. Receipt `build/spline-bands-20261012-01/baseline-cost-02/receipt.json`. First harness launch failed to resolve `cl.exe`; explicit compiler resolution corrected it before successful measurement.
- Prototype field inspection at 100k candidates: eight Sharp Bands median 137.05 ms, p95 140.79 ms; 32 Sharp Bands median 285.35 ms, p95 291.59 ms. Preparation median 2.69/2.95 ms respectively. These test shared simple ramps and one rectangle, with strengths normalized to 1/Band count; saturated full-strength/steep/complex workloads remain to be measured. Receipt `build/spline-bands-20261012-01/field-cost-01/receipt.json` refers to probe 03, before later integration edits.
- Returned retained-array bytes exclude library construction scratch and do not establish aggregate old/staged memory admission. No Max, renderer, GPU or physical interaction result is implied.

All local run directories are ignored evidence, not source-only checkout dependencies. Final source must receive new matched builds and host tests after integration.

## P1 initial native and transport witnesses

- `native-intervals-01`: all 17 SDK-free suites passed. Explicit empty intervals reserve coverage; global empty winners do not fall through. Complete flat consecutive fixtures preserve positions, bases, scale, source and candidate identity. Native point-cloud and falloff paths retain Band owner IDs.
- `transport-max2026-01` and `transport-max2027-01`: matching SDK builds and 26 executable suites passed per year. These include 17 Scatter suites and nine existing licensing suites; no licensing behavior was changed.
- Owned hosts `foundation-spline-transport-2026-01` and `foundation-spline-transport-2027-01`: 17 actual transport assertions passed per host, including receiver face offsets, Whole Scale, world-Z source offset, falloff/orientation round trips, Edit clones/anchors/protection and malformed-version rejection. Current scenes still use the legacy transport until the new authored fields are wired; the test deliberately supplies v2 rows to every changed primitive.
- The existing publication fault/recovery and retained admission/reuse fixtures also passed in both owned hosts. Their JSON and command receipts are retained in each profile. Normal user profiles are hash-checked; only the verified owned processes are stopped.
- Disposable `schema56-scene.max` and `schema56-expected.json` witnesses were captured in both profiles before changing the saved schema. They record full matrices, identities, selections, widths, radii, offsets and seeds for the next migration check. Original scene files are never overwritten.

P1 remains incomplete until current-schema lifecycle checks, actual ordinary-Band payload generation, copy/removal/Undo and matched host round trips pass. P2â€“P6 remain pending.

## Current-only cleanup decision

The user explicitly removed backward-compatibility requirements during implementation. Schema 57 / source 0.80.0 is the only scene target; old scenes require recreation and remain untouched. Earlier schema-56 witnesses remain historical evidence and can test rejection, not migration. Historical successful receipts above do not qualify the subsequent cleanup.

Removed schema-55/56 migration methods, hidden untyped distance storage, duplicate node-based Band membership storage, group fallback for empty native Bands, unkeyed Edit/Whole Scale/falloff branches, variable generation signatures and older placement readers. The old direct generator/overlap primitives are removed from active native source; remaining callers and fixtures are being audited before cleanup acceptance. Current renderer inputs and supported Max SDK versions remain separate valid interfaces.

Generated consistency passes for the current source (241 existing controls; P2 UI additions are still pending). The earlier schema57-generated-01 check caught a stale caption in the approved UI template; the source template was corrected and current-only-generated-01 passes. The pre-cleanup authored-max2027-01 build passed all 26 suites. The subsequent current-only-max2027-01 build passes all 26 suites in 5.38 seconds; host checks are pending.

### Current-only Max 2027 checks

- Native receipt `current-only-max2027-01`: 26 executable suites pass (5.38 s).
- `foundation-spline-authored-2027-02/spline-authored-a604500ffe8f498e99bc97f878d74681.json`: 21 authored checks pass. Explicit empty memberships reserve intervals; assigning/unassigning the middle Band preserves every unaffected full transform and identity. Copied layers preserve pre-spacing rows. Current-schema save/reopen and missing-Path behavior pass.
- This host also passes 22 transport assertions, 42 publication fault/recovery assertions, 17 retained-display admission/reuse assertions and four retired-scene rejection checks. Older scene bytes are unchanged.
- `foundation-spline-undo-2027-01/band-undo-commands.json`: separate native prepare/delete/undo/redo events all pass. Earlier Python-driven Undo attempts left an outer hold and also prevented a plain Max Box from undoing; they do not qualify Band Undo. Their failed results remain in the owned profiles.
- The actual authored fixture found two product issues: no-modifier rows bypassed output identity conversion; missing Path entries reached the shape cache key. Both were fixed in the authoritative template, regenerated, and the authored checks reran successfully. A test-only call to nonexistent `generateInstances` was corrected to inspect actual `procPreparedRows` after evaluation.
- Repository pytest run: 157 pass, one failed on the old catalog-version literal. The version expectation was updated for 0.80.0 and that focused test passes. This is not yet the final repository run.

Full feature completion remains P0/P1/P2-P6 as tracked above. The native field prototype is not yet connected to authored Independent/density execution; the bridge explicitly rejects those settings instead of ignoring them. No new UI controls, Band palette, field overlays or Auto Radius are currently qualified.

- Current-only Max 2026 SDK build also passed all 26 suites (6.20 s). Owned host `foundation-spline-authored-2026-01` passed native Band delete/Undo/Redo, 22 authored checks, 22 transport checks, 42 publication checks, 17 retained-display checks and four retired-scene rejection checks. Its final script additionally removes implicit group fallback, so switching a new empty Band to Groups remains empty.
- Removed the retired standalone `AminScatter/scripts/AminScatter.ms` 0.2 prototype. Removed obsolete `patternGroups`/`patternRestGroup` parameters and their unused methods; Groups now uses explicit membership only. Analyzer new-row default assignment is written explicitly at creation. The native module remains matched to the earlier current-only source; script identities are recorded per host/probe.
- All owned 2027 and 2026 processes from this milestone were verified by exact private profile command line and stopped. Normal user INI hashes remain unchanged.

## Prepared field integration

- `field-integration-01` compiled but failed the new test: its expected scale omitted the default overall scale. The fixture now isolates Band scale with overall scale 1; the failed receipt remains.
- `prepared-field-max2027-01`: matched SDK build and all 26 executable suites pass (5.69 s). Field generation, receiver salt, candidate-prefix/full-transform stability, Independent reorder, constrained Relax/final movement and invalid source-table rejection are exercised.
- Ordinary Bands use a GC-owned immutable numeric field prepared once per authored/geometry revision and reused across receivers. Ordinary preparation has one 14-field record; Analyzer has one 12-field record. Retired reserved group slots and the mixed ordinary/Analyzer parser are removed. Native interface version 3 is required; placement rows remain version 2.
- Field sampling uses dedicated keyed channels 101/102/103/104 for occupancy/owner/source/Band scale. This deliberately changes source/scale draws from the pre-0.80 ordinary Band implementation; candidate positions, IDs and parent transform streams are preserved. This is the single current recipe, without an old-scene compatibility branch.
- `foundation-spline-field-2027-01`: ten actual field checks pass, including independently replayed decisions from packed IDs on two receivers, 80/20 overlap with 25% continuation, one preparation across receivers, reuse on budget change, final-movement identity handling, Accepted-target rejection, malformed-curve retention and recovery. The existing 22 authored, 22 transport and 42 publication checks also pass in that host.
- `prepared-field-generated-01` passes. The one owned host was closed after exact profile command-line and normal-profile hash verification.

These results qualify the current Rounded field path. Sharp complex geometry, curve tessellation/resource gates, P2/P4/P5 controls/display/radii and Max 2026 requalification remain outstanding. No production installation or knowledge activation occurred.

## Geometry, resource admission and P2 follow-up â€” 13 October

The paragraphs above retain earlier milestone status. The acceptance table and this follow-up supersede their pending statements.

- `geometry-gates-01`: 17 SDK-free suites pass (6.44 s). Independent progress error was .000468351 for the rectangle and .00048545 for the concave reference; the complex Sharp sweep's aggregate contribution error was .000608542. The adaptive cubic witness used 409 vertices and maximum chord error .000727355 against .001. Its 222,764 assertions are not distinct acceptance scenarios.
- Host extraction uses copied Bezier data, exact straight segments and bounded adaptive subdivision. The physical quantum is .0001 mm, converted to system units; the chord tolerance is the smaller of 100 quanta and the narrowest width/4096. This intentionally replaces the old fixed-step ordinary spline tessellation. Rounded still means Euclidean distance to the prepared segments, without a second compatibility recipe.
- Field construction admits at most 250 million work units and reserves a 256 MiB construction allowance, with a 512 MiB process reservation across fields. Retained arrays fit the 128 MiB per-field limit. These conservative reservations do not prove a hard cap on Clipper allocator overhead or the Max process heap. Failure releases its reservation and preserves the previous publication.
- `geometry-resource-max2027-01` and `authoring-max2026-01`: all 26 executable suites pass per SDK. Actual host geometry checks cover straight/curved extraction, Sharp behavior and failed successor retention; see their owned profile receipts.
- `field-generation-cost-01`: 100k flat Rounded candidates / 1, 8, 32 Bands measured warm medians 32.8325 / 33.9402 / 40.2724 ms, p95 34.2151 / 34.8606 / 40.6364 ms. All emitted 23,323 rows. The older baseline is contextual; this is not a matched noise-floor proof of a speedup.
- `field-cost-02` ran concurrently with Max startup. Normalized Sharp eight/32-Band query medians were 179.67 / 380.697 ms, p95 231.311 / 400.759 ms. Saturated eight/32-Band medians were 196.338 / 463.132 ms; the eight-Band steep concave case was 299.325 ms. These pass the declared CPU development budget under that measured condition, not host Update/FPS acceptance. Child-process peak working set 11,833,344 bytes excludes Max and GPU resources.
- The authoritative template was recovered after an interrupted encoding write. Exact recorded edits were replayed and an intermediate generator result matched its preserved SHA256 byte-for-byte. Evidence is in `template-recovery-01/RECOVERY.txt`; subsequent text edits encode UTF-8 before replacing their destination.
- P2 now provides three-row Paths navigation, stable-ID Band selection/reordering, explicit intervals and assignments, membership navigation, Band swatches and one captured-owner density graph. Generated inventory has 252 controls. Graph writes follow the captured Band after reorder and cannot redirect after another layer is selected.
- Native 13-event conversion/reorder/curve Undo/Redo checks pass in Max 2026/2027. Two failures exposed deferred CurveControl sampling and an extra close transaction caused by comparing rounded saved text with full-precision samples. The corrected adapter compares canonical serialized values and defers release sampling. Scripted events do not certify physical drag handling.
- Final expanded authoring fixtures pass **31 checks per host**: `foundation-spline-authoring-2026-01/spline-authoring-ui-8aab8d49b4804c49a04ce6fab591be7c.json` and `foundation-spline-authoring-2027-04/spline-authoring-ui-652b1a34c4254ac2a8045c7b74d69b13.json`, script SHA256 `11b18b04fc0839fe8b3573397dbede5ab412617eaf04d67825b4d00f790576c2`. Save/reopen preserves current records, identity-keyed source labels/colors, ranges, curves and corners. Graph startup resolves the saved node dependency before transient preview binding; a detached layer fails without leaving a partial dialog.
- Earlier persistence probes used undefined MAXScript `cyan` and two isolated Max 2027 runs crashed while assigning it to a Point3 parameter. Dumps and incomplete results are retained in profiles `2027-02`/`2027-03`. Correct explicit colors pass in both hosts, including graph-close then garbage collection. The setter now rejects invalid value types before parameter mutation and this negative case passes. A separate post-reopen graph ownership error was reproduced and fixed; no claim of a general Autodesk crash diagnosis is made.
- The actual owned-host 720-pixel screen capture shows the controls and one-row icon actions. PrintWindow images with blank Qt content were rejected as visual evidence. Physical pointer/keyboard, 150%/200% scaling and final retained display qualification remain open.

## Current sampler cleanup in progress

Removed the opt-in legacy sampler, mask refill loop, row-index falloff random stream, dormant cluster-distribution settings and generator-local collision implementation. Current candidate budgets and ordered procedural spacing are now the only production route. The generation bridge is an exact 29-field call with 11 options and four Relax controls. Current tests exercise bounded candidate prefixes and the actual ordered spacing evaluator.

- `current-sampler-max2027-01` and `current-sampler-max2026-01` each pass 26 suites; repository pytest passes 158 tests. The generated/layout checks pass with 252 controls. These receipts qualify the pre-palette native interface 4.
- `foundation-spline-cleanup-2027-01/qualification-db9eb128948542a8a7608e4e52647270.json` passes 13 native Undo events and 157 fixture assertions across fields, geometry, authored behavior, transport, authoring, publication, retained display and retired-scene rejection.
- Max 2026 passes those Undo events, the field fixture and the remaining non-geometry fixtures. Its geometry check exposed over-tessellation in the inches profile. Both owned cleanup hosts were closed after profile ownership verification.

## P4 palette and geometry follow-up in progress

- Host tessellation now caps chord error by the smaller of the narrowest Band width/4096 and each Bezier control-box extent/4096. The physical quantization remains .0001 mm. This supersedes the fixed .01 mm tessellation ceiling above, which made the physically larger inches fixture exceed the admitted Sharp construction scratch allowance.
- `palette-max2027-01` failed to compile an ambiguous Point4 constructor. The corrected `palette-max2027-02` passes all 26 suites (6.76 s). Native interface 5 introduces one strict five-field palette and retains exact version-2 placement rows; no old preview-row adapter is present.
- `foundation-spline-palette-2027-01` passes 19 palette checks: actual point/mesh shader realization; shared source geometry across Band owners; zero geometry/transform/owner uploads on recolor; preceding immutable palettes; strict dictionary rejection; Manual deletion retaining last published colors; Update replacing the dictionary; unchanged render material. SDK parameter payload counters are not measurements of physical VRAM traffic.
- The same host passes nine geometry checks and ten unit checks. The identical physical curved Sharp fixture emits 5,263 candidates in millimeters, centimeters, meters and inches with matching identity/source/Band and physical transforms within the declared tolerance. The field retains 68 input vertices; this is not a general host unit/load qualification.
- `palette-source-revision-2027-01` passes 26 suites. Its owned host passes ten source-revision checks, 19 palette checks and the expanded 42 publication checks. An uncached Mesh/Point Cloud switch cannot borrow changed source geometry in Manual mode; Centers use published positions. Exact restored geometry admits a new representation without solving. The signature includes face-referenced pivot-local coordinates; source material/color edits are excluded and orphan vertices do not enlarge bounds. Inspection is capped at 512 entries and two million faces per population. This is a bounded host content check, not render-proxy qualification.
- P4 reservations now account for CPU snapshots, palettes, staging, SDK system copies, GPU payloads and upload temporaries against the existing 64/128 MiB point and 512/1024 MiB Mesh owner/process limits. Full Max conversion, allocator and driver overhead still require measurement; counters describe reserved payloads rather than process or VRAM consumption.
- `palette-resource-fault-2027-01` failed on a new test include path. Corrected build `02` passes all 26 suites, including peak-coexistence reservation/release checks. Its normal private-host launch was correctly rejected by the development-binary guard before starting a process. Build `03` separates the packaging refusal from an explicit recorded owned-profile fault-test route; qualification is still pending. The fault code is compiled out of ordinary builds, and packaging rejects its primitive marker. Eight focused packaging tests pass.
- Full P4 resource/failure/overlay gates, P5 Auto Radius and integrated P6 remain outstanding.

### Resource and visible rendering qualification

`palette-resource-fault-2027-03` passes 26 suites. Its owned fault host exercises actual Point/Mesh shader and later-group upload failures, complete production CPU fallback, immutable preceding caches and same-input retry. Resource-release testing initially failed: detached scripted objects retained their CPU caches after scene reset. Explicit post-scene cleanup now releases transient display/field caches only when the preceding controller has no live dependent nodes. The corrected fault fixture also verifies a still-live controller survives an aborted transition; process point/mesh reservations return to zero after reset. Failed fixtures and reference/Undo probes are retained.

The ordinary `palette-qualified-max2027-01` and `palette-qualified-max2026-01` builds each pass 26 suites, but **their names do not certify visible rendering**. Actual viewport captures then exposed a retained Mesh defect: the red/green images were identical and showed distorted gray geometry, while GraphicsWindow fallback showed the intended three colored boxes. `verify_palette_images.py` independently rejects that captured output. Prior upload/readiness counters did not catch this.

The [Autodesk instance-stream contract](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/struct_max_s_d_k_1_1_graphics_1_1_material_required_stream_element.html) permits instance data only in the final vertex buffer. The new owner stream incorrectly used a second instance buffer. The correction interleaves transform rows and the owner slot in that single immutable buffer while continuing to count their logical payload bytes separately. No defective build was installed or packaged. The following witnesses supersede the earlier pending state.

### Corrected rendering and current-contract cleanup

- `palette-instance-layout-2027-01` passes 26 native suites. Its first owned host exited before readiness without an established cause; the fresh `foundation-spline-instance-layout-2027-02` host passes 32 GPU failure/recovery assertions. Point/Mesh reservations return to zero after scene teardown; preceding CPU snapshots and live-controller ownership survive the tested failure paths.
- The same host passes 16 independent image checks: seven Mesh checks and nine Point checks. Mesh retained/fallback color masks have 100% IoU in this fixture. Each of the three point groups has 441 detected points in both render paths; every centroid agrees within 0.708 pixels. Retained one-pixel rasterization differs from GraphicsWindow marker coverage, so the Point oracle compares positions against an actual empty background. Grid contamination made earlier oracle attempts fail; those receipts remain. This is a controlled viewport witness, not arbitrary GPU/device-loss certification.
- The first ordinary SDK host campaign reproduced a separate product defect in both years: an unpublished copied layer's empty cache borrowed changing authored Band metadata, and a later recolor failed dictionary validation. Empty unpublished layers now carry an empty publication dictionary until Update. The existing authoring test and a new palette regression pass with generated script `5a216486602818f5ab78b19bce0deb4dac646d213593e616cb62de07ba14b963`.
- `current-contract-cleanup-max2026-01` / `current-contract-cleanup-max2027-01` each pass 26 suites (8.43 / 6.80 seconds). Their owned `foundation-spline-contract-cleanup-2026-01` / `2027-01` hosts pass the expanded campaign: 13 native Undo events; field, geometry, authored, transport, authoring, palette, source-revision, physical-unit, publication, retained and old-scene rejection scenarios; and all 16 image checks per year. Exact receipts are `qualification-a46fdb918b624a53bd04adf65d4d80d7.json` / `qualification-a578f29a953c48ffb99eba06aa0229a5.json` in those profiles.
- Earlier image requests sent after the old-scene rejection scenario timed out without entering the image fixture. The cause of that private transport failure remains undiagnosed; it is not recorded as a passing test. Fresh campaigns run images before the rejection scenario, retaining the independent image assertions. Failed requests and prior results remain in `foundation-spline-palette-verified-2026-01` / `2027-01`.
- Removed the unused Edit migration-pending state and made the diagnostic fingerprint require current placement rows. Removed six obsolete batching/migration entry points from active tooling; byte-identical copies and hashes remain in [historical fixtures](retired-fixtures/README.md). Retained Brush/performance tools now produce current rows/palettes and call the current triangle interface. The private request client now requires exact request correspondence for errors as well as success.
- Generated consistency passes with 252 controls; the repository Python suite passes 161 tests in 11.98 seconds. A final reader audit then found permissive Analyzer Area, placement-copy and spacing-blocker inputs. These now use current stage validation. `current-row-readers-max2026-01` / `max2027-01` pass 26 native suites (7.83 / 7.54 seconds), and their fresh owned `foundation-spline-row-readers-2026-01` / `2027-01` hosts pass 43 focused transport assertions each. Positive checks cover owner preservation and independent copied transforms; negative checks cover all retired row widths at each changed boundary. `current-row-readers-checks-01/verification.json` verifies all compiled inputs/binaries still match and ordinary binaries omit the fault-test primitive. Branch/HEAD and empty staging are unchanged. The broader display campaign above predates only these stricter readers.

P4 field/boundary overlays, P5 Auto Radius, final performance/resource distributions, physical UI/DPI and renderer acceptance remain open. Nothing was installed, packaged, committed or activated in the knowledge base.

## Auto Radius and current paired spacing

The preceding paragraph records the pre-P5 milestone. Auto Radius is now implemented through the existing ordered spacing pipeline. Current native Band interface 6 and procedural publication 2 replace the scalar radius call with one five-argument source-specification contract and frozen `(XY, 3D)` pairs. Every self/sibling/cross-layer rule selects both sides' own metric independently. Manual settings survive mode changes; Auto applies the final basis once, excludes translation, and honors keyed absolute/multiplier overrides. The prototype corner calculation moved from the Band module into the procedural domain; no parallel collision algorithm or compatibility adapter was introduced.

Source inspection keeps only bounded metadata behind weak SDK references, invalidating synchronously on geometry/topology/transform changes and animation validity expiry. Active Auto source lotteries are validated before sampling, including almost-never-selected invalid sources. Zero-weight, unassigned and zero-contribution sources remain dormant. Required missing/empty/singular geometry fails the successor. Point/Empty and unqualified source types retain Manual. Preview preparation skips unused sources. Radius display uses published pairs, independently selects XY or three 3D rings, and checks the existing 10,000-ring limit before creating script point arrays.

- `auto-radius-max2027-01` and `auto-radius-max2026-01` pass all 26 executable suites (6.67 / 6.83 seconds). The 240 exhaustive spacing comparisons now use different XY/3D radii, supplemented by explicit mixed self/sibling/cross-layer metrics and collapsed-basis checks.
- Owned `foundation-spline-auto-radius-2027-04` and `foundation-spline-auto-radius-2026-01` each pass **30 Auto geometry/publication checks** and **19 lifecycle checks**. These include independent transformed-corner/interior oracles, Manual Follow Scale, stable overrides, source-scale application, bounds cache hits, off-center pivots, zero-weight/unassigned/zero-density handling, failure retention and current-schema save/reopen. Millimeters/centimeters/meters/inches agree physically. Load conversion, world rescale, merge and copied-owner settings pass. Bound controls restore Manual values; Point shows Manual-only. Relevant source animation updates in Live, remains pending in Manual, and unrelated animation neither solves nor extracts bounds.
- Seven separate native Auto mode Undo/Redo events pass in Max 2026, preserving Manual values and the published epoch. Max 2027 still needs these new native events in a fresh integrated campaign. The earlier native Band/curve events also pass in the current 2026 campaign.
- Fourteen additional source/admission checks pass in Max 2027: Box, Sphere, Cylinder, Plane, GeoSphere, Cone, Capsule, Editable Mesh and Editable Poly; valid collapsed referenced geometry; modifier invalidation; source-count admission; deleted required source retention; and 3D ring admission rollback. Renderer proxies and other unqualified classes remain explicitly Manual-only.
- Source-revision, current transport, palette, publication-failure and retained-display fixtures pass with the new interface. Max 2026 additionally passes the broader field/geometry/authored/authoring/unit campaign, old-scene rejection and all **16 independent captured-image checks**. A combined campaign stopped at a fixture-only `box` versus `box()` error; corrected lifecycle and the remaining fixtures passed separately. That failed combined receipt is preserved, not presented as a complete passing campaign.
- Generated consistency passes with **254 controls**, script SHA256 `8e89e22116eceea6a0a34bf8f75701675ada4c5e41cc65a4a48d66b8f34339e0`. Repository pytest passes **161 tests in 12.24 seconds**. `auto-radius-checks-01/verification.json` verifies compiled sources/binaries, ordinary fault-primitive absence, evidence hashes, both normal profile identities, unchanged branch/HEAD and empty staging. This is scoped verification, not whole-workspace certification.

Earlier startup attempts exposed a MAXScript parser failure in the compact nested radius-ring expression; the explicit loop form loads successfully. Other retained fixture failures covered MAXScript array identity comparisons, argument-message capitalization, a uniform-scale test that left advanced axis scaling enabled, and an attempt to call a dropdown's string-valued `selected` property as an event. The corrected UI check tests bound controls and setter behavior; it does not claim physical pointer acceptance. A first image-oracle invocation used a Python environment without Pillow; the existing workspace venv completed the same captured-image oracle without installing dependencies.

P4 field/boundary overlays, final cost/resource distributions, physical interaction/DPI, exact renderer qualification and final maintained artist docs remain open. No installation, package, commit, release or knowledge activation occurred.

## P4 numeric field display and native bridge

The field-display backend now samples actual receiver triangles using the same
`Field::inspect` probabilities as generation. It allocates at least one sample
per nonempty receiver, then distributes the remainder by 3D area. Combined and
selected contributions share sample anchors. Bounded triangle glyphs distinguish
zero density from unsampled space, while outline curtains intersect every
receiver elevation, including sloped and vertical faces. Sharp endpoints reuse
prepared contours; Rounded endpoints preserve distance to original segments,
including overlapping-loop interiors. Display offsets never change evaluated
anchors or placements. The [transport note](TRANSPORT.md#field-display-preparation-p4-integration-in-progress)
defines the new preparation and diagnostic contracts and their resource limits.

- `field-overlay-max2027-02` passes all **27 native suites in 6.77 seconds**.
  The new overlay executable passes **17,386 assertions**, covering density
  parity, zero samples, holes, overlapping loops, Sharp corners, distinct narrow
  endpoints, stacked/sloped/vertical/coplanar receivers, physical scaling,
  deterministic output and admission/failure boundaries.
- The first core attempt failed on exact floating-point equality in the vertical
  glyph oracle; the corrected geometric tolerance preserves its intended test.
  A receiver-coverage assertion also incorrectly required exactly one sample
  for the tiny receiver, although bounded apportionment can assign two. It now
  checks participation and its one-to-two quota. Those failed receipts remain.
- `field-overlay-max2027-01` compiled but failed the new physical-scaling test.
  Clipping at an exact corner produced roundoff-sized extra segments. The
  production correction discards only coordinate-relative double-roundoff
  slivers, with no fixed world-unit epsilon; the unchanged scaling/topology
  assertion then passes. Rounded construction admission was also refined to
  account for actual corner turns rather than charge every join a full circle.
- Owned `foundation-spline-field-overlay-2027-01` passes **23 native bridge
  checks**, recorded in `field-overlay-93936213ff384765a16bf4efa9fc5814.json`:
  selected/combined analytic parity, three receiver surfaces, independent
  toggles, frozen anchors under display offsets, eight input-rejection cases
  without reservation leaks or preceding-cache changes, retained line submission
  and unchanged-redraw upload reuse. The fixture's 24-face/1,000-sample first
  preparation took 1.83 ms; this single small measurement is not a performance
  gate or presented-FPS claim. Peak point reservation was 55,547,506 bytes
  against the unchanged 128 MiB process allowance, not measured physical RAM.
- All **seven native Auto Radius Undo/Redo phases** pass in this fresh Max 2027
  host before Python fixtures. The existing **10 field checks** and **42
  publication checks** also pass. The loaded generated script is unchanged at
  SHA256 `8e89e22116eceea6a0a34bf8f75701675ada4c5e41cc65a4a48d66b8f34339e0`.
  The owned host was closed after exact command-line verification; its normal
  Max profile remained unchanged.

This is a backend milestone. The artist toggles, selected/combined legend,
per-population radius/field bundle, Manual pending/publication metadata and
captured-image acceptance are **not integrated yet**. Max 2026 overlay-specific
qualification and final workload/resource distributions remain pending. Earlier
generation, palette and radius witnesses do not substitute for those gates.
Nothing was installed, packaged, committed or activated in the knowledge base.

## P4 integrated field UI, lifecycle and failure qualification

Native Band interface **7** integrates Preview Falloff, Show Boundaries, selected
Band/Combined density and a saved 1â€“20,000 sample allowance. Field and radius
lines share one inspection slot per population. Main geometry and field keys
are independent; the completed publication captures its field revision alongside
owners, sources and paired radii. Manual feedback explicitly labels pending
inputs and follows relevant receiver/Path changes and animation without solving
placements. Restoring valid display settings clears display errors without
discarding a failed generation's distinct error.

- `field-ui-max2027-01` passes **27 native suites in 6.75 s**;
  `field-ui-max2026-01` passes **27 in 7.53 s**. The private NEVER SHIP
  `field-gpu-fault-max2027-01` passes **27 in 7.48 s**. Script SHA256 is
  `353413115719c35db3d1ce217a3e9712031bfa63cdf1365bb75036b2d36dcf13`.
- Fresh owned `foundation-spline-field-integrated-2026-01` and `2027-01`
  each pass all **53 campaign steps**: 33 separate native Undo events,
  18 Python host fixtures and two independent image verifiers. Receipts are
  `qualification-e2c22e36cdfa42a382b699eb7e4923e0.json` and
  `qualification-e2348c7e19e04f43b1c95f67ec2c95ed.json`, respectively.
- Each host passes **36 field UI/lifecycle assertions**: shared view selection,
  separate toggles, combined density, unchanged main cache/placements/radii,
  Manual pending labels, failure retention/recovery, source-revision denial,
  current-schema save/reopen/copy, relevant Manual/Live animation and unrelated
  animation reuse. Thirteen native events exercise the actual field control
  handler's Undo/Redo. These are programmatic controls, not physical mouse/DPI
  acceptance.
- Each host passes **23 native overlay checks**, **18 independent field image
  checks**, the earlier **16 palette image checks**, and the expanded **49
  publication assertions**. New publication cases inject a failure after the
  second owner install, reject a later preparation, and fail a plant successor:
  prior field/radius/main caches, keys, labels, metadata and Edit state survive.
  Captured retained and production fallback images visibly contain zero/high
  density, clipped white outlines and published radius rings.
- `foundation-spline-field-gpu-fault-2027-01` passes **44 assertions** in
  `gpu-failure-3a44a33f25e745a0b73642d3eb17f6b4.json`. Shader/owner-buffer
  failures in a later field group produce a complete CPU fallback, preserve
  placement epochs, keep preceding caches immutable and recover on the same
  inputs. Releasing the scene returns point and Mesh reservations to zero;
  observed peak declared point payload is 55,783,390 bytes. This is not measured
  physical RAM/VRAM or arbitrary device-loss certification.
- Generated consistency passes with **258 controls** (`field-ui-generated-02`);
  repository pytest passes **161 tests in 13.63 s**. A preceding pytest run
  correctly flagged the obsolete 254-control assertion; the four new field
  controls are now counted. Later documentation/catalog checks have separate
  receipts. All four owned hosts used for this integration were closed only
  after exact private command-line verification; normal Max profiles match
  their launch fingerprints.

Early integration exposed a MAXScript forward-reference error: helpers preceded
the Band parameters they read. Parameters and helpers now have valid declaration
order. Timeline tests also found Manual feedback was not scheduled; the bounded
enabled-field path now requests display refresh without placement publication.
A small label-formatting attempt failed parsing and was replaced with the
existing count formatter. Test-only corrections set a nonzero radius before
expecting rings and explicitly reset the disposable Edit binding before changing
its generation recipe. Failed requests and diagnostic receipts remain in
`foundation-spline-field-ui-2027-01`; repeated early publication result summaries
used the fixture's fixed filename, so not every intermediate JSON survives.
The last failing Edit-binding summary was separately retained. Fresh final
campaigns do not overwrite those profiles.

Current navigation, artist/reference guides, architecture, foundation, version
policy and capability help now describe schema 57 without migration. Historical
receipts are unchanged. Final representative cost/resource distributions,
physical UI/DPI, exact renderer/material acceptance and remaining P6 reconciliation
are still open. No installation, package, commit or release occurred.

The knowledge adapter became available during this work. Full-parent status for
generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`
reports stale evidence (22/38 parents verified; changed guides/source and two
retired migration fixtures), with its refresh process stopped. This work uses
current originals and preserves the active registration/index; a separately
reviewed successor must update enrollment before this new behavior is retrieved
as current knowledge.

## Final output, performance and physical-control corrections

The final renderer fixture exposed a real current-format bug: exact output groups
post-Edit String-ID rows, but `cyrusFilterSourceRows` accepted only raw Integer64
identities. The native filter now validates either stage of the same eight-field
layout. No retired reader or script fallback was restored. Five new transport
assertions cover both stages, retained owner/protection/clone IDs, exclusions and
invalid old/empty identities.

`CyrusPointSync` now preflights dependencies and requests one controller refresh
before reading retained layer caches. Previously, every still-dirty Manual layer
could repeat the whole root validation. Auto Radius visibility is also removed
from the placement key; changing it in Live is a display-only operation.

- `final-output-max2026-01`, `final-output-max2027-01` and the private
  `final-output-gpu-fault-2027-01` each pass all **27 native suites** in
  **9.07 / 8.15 / 9.06 seconds**. The fault build is NEVER SHIP. Ordinary native
  source identities remain current after the later interpreted graph-only fix.
- `foundation-spline-final-output-2027-01` passes all **55 campaign steps**;
  receipt `qualification-3c49990745964b3d984f85df2ae03cfc.json`. The matched 2026
  campaign passes the preceding checks but stops at a fixture-only undefined
  `magenta` constant. Its corrected renderer and final old-scene rejection steps
  pass separately. The failed receipt is retained as failed; this is not described
  as an uninterrupted 55-step 2026 pass.
- Both hosts pass **38 field UI checks**, **49 publication checks**, current
  transport, Auto/source/units, retained-display and independent palette/field
  image checks. Actual process-loaded paths and hashes of all four native modules
  are recorded in each ordinary profile's `loaded-modules.json`.
- Actual 384Ã—384 Scanline PFlow images use Standard and Multi/Sub-Object source
  materials. Palette/field/radius edits change **zero rendered pixels**. Against
  independent explicit instances, each host has only **one pixel** differing by
  more than two channel levels, within the declared raster tolerance. Both
  five-check image verifiers pass. This does not qualify Corona, V-Ray, proxies,
  displacement, IR or motion blur.
- `foundation-spline-final-fault-2027-01/gpu-failure-1234648f7731470db3dc4472ee794b6d.json`
  passes **44 checks** with current native code: later-group shader/buffer failure,
  complete fallback, immutable prior generations, unchanged Manual publication,
  recovery without a placement solve and release to zero reservations.

### Measured costs and resources

`field-cost-03` records one cold and twenty warm CPU samples, including saturated,
steep and concave Sharp cases. At 100k candidates, normalized eight/32-Band Sharp
query medians are **134.564 / 299.370 ms**, p95 **153.570 / 406.401 ms**. The
saturated 32-Band and steep concave eight-Band medians are **364.714 / 290.981 ms**.
The recorded CPU development gates pass; these are not total Max times.

`final-cost-comparison-01/comparison.json` alternates preserved baseline/current
executables three times over nine equivalent flat Rounded workloads. All accepted
counts match and no repeatable median/p95 regression crosses the declared 10%
plus measured-noise criterion. The current query excludes preparation performed
outside its timer, whereas the old implementation prepares inline. The receipt
states that asymmetry; it is not a claim of an equivalent end-to-end speedup.

`foundation-spline-final-performance-2026-02/performance-617a21ed980c456790b0abfce6a2b6db.json`
passes **23 invariants** with one/ten layers, one/20 shared sources, two stacked
receivers and eight Bands per layer. Each workload has one cold and twenty warm
display measurements. Explicit unchanged Updates use five warm samples and cache
reuse; they must not be presented as forced regeneration.

| Layers / sources | Palette edit median | Pending width edit median | Root refresh calls per field edit |
| --- | --- | --- | --- |
| 1 / 1 | 38.57 ms | 63.14 ms | 2 |
| 1 / 20 | 114.19 ms | 193.50 ms | 2 |
| 10 / 20 | 692.15 ms | 855.31 ms | 2 |

The two calls are the fixture's explicit refresh and its ensuing sync, independent
of sibling count. Before coalescing, the ten-layer medians were 2,755.06 and
2,889.34 ms. These separate host runs establish a measured improvement, not a
general responsiveness promise. Color edits upload zero geometry, transforms or
owner streams; unchanged redraws solve/extract/upload zero. Ten-layer field first
display still takes about **1.86 s**, and heavy artist scenes remain unqualified.

Machine: Ryzen 5 5600X, RTX 3090, driver 32.0.16.1047. The final process working set
was **2,182,037,504 bytes**; WDDM dedicated/shared allocations were
**943,300,608 / 124,264,448 bytes**. These process counters include Max and its
driver allocations, not just Scatter, and do not prove physical GPU residency.
Declared payload counters and allocation budgets remain separate. No presented
FPS or isolated GPU timing was measured.

### Physical authoring and remaining acceptance

Owned Max 2026 at **96 DPI** passed physical Path selection, outside Band creation,
width spinner, falloff/boundary toggles and density endpoint drag. Seven readback
checks preserve other widths and Manual placements. The graph initially fitted a
constant curve too tightly around 100%; it now opens on the full 0â€“100% domain.
The corrected physical drag saved an approximately 39.3% endpoint, with four
readback checks preserving other Band curves and Manual publication. Screenshots
and `physical-ui-*` / `physical-graph-*` receipts are retained in that profile.

The fix uses documented [CurveControl zoom and scroll properties](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/Rollout-User-Interface-Controls-3/GUID-E7FE8222-FC65-4A7D-AB8B-787A676DB2FA.html).
Max defers its sampled lookup refresh; the initial control geometry is therefore
the unchanged-graph identity. Opening/closing without edits must not serialize a
new recipe or create an Undo step. Final focused authoring results are recorded
below; the renderer/performance campaigns predate only this graph correction.

The current feature has bounded engineering evidence, **not complete P6 or release
acceptance**. Remaining gates are the complete physical control/container/keyboard
matrix, 150%/200% DPI and tablet input, sustained heavy artist assets, intended
renderer/proxy coverage, true device-loss recovery and presented-frame measurement.
Current-only cleanup does not remove supported Max 2026/2027 SDK integration,
current scene persistence, required class IDs or independently versioned components.
Old scenes and historical evidence remain preserved; no migration path was added.

Graph milestone interpreted script SHA256:
`74c6f83c5fea03ee5213cc79bed8b5392e147d9de7ce083cfe57247076f2208c`.
Fresh `foundation-spline-final-graph-2026-01` and `2027-02` pass **15 native
authoring/Undo events and 31 authoring/persistence assertions each**, including
unchanged graph open/close, meaningful curve edits and Undo after graph closure.
Their 16-step focused receipts are
`qualification-7718b277d4c84a07923bd11003c2653b.json` and
`qualification-1c5d229e87d046afb5a073115a82624e.json`.
Initial regression attempts used invalid MAXScript expression indexing and an
unparenthesized/exact-float sample comparison; corrected fixture checks retain
their original purpose. Failed receipts remain in `final-graph-2027-01` / `02`.
The physical full-domain graph witness predates only the final unchanged-geometry
guard, which these focused host checks qualify. The final Analyzer cleanup below
subsequently changes both native and interpreted identities.

The graph milestone local command receipt and preservation scope are in
`build/spline-bands-20261012-01/final-checks-01/`. Source/binary checks explicitly
distinguish the separately interpreted final script from compiled native inputs.
No installation, package, commit, push or knowledge activation was performed.

## Final current-only cleanup and matched validation â€” 13 October

A final source audit found that Analyzer mode 0 still reached the retired
ordinary `LineBand` sampler. That executable compatibility path is now removed,
including its area-mask branch and orientation path. Ordinary Bands always use
the prepared field. Analyzer has a distinct `AnalyzerBand` type with modes 1â€“6;
its transport is exactly 11 fields, without the unused old `inside` slot.
Both generation and orientation reject mode 0 and the former 12-field record.
Supported Analyzer paths still generate placements and orient them in actual Max.

The current identities are source **0.80.0**, scene schema **57**, native Band
interface **8**, placement transport **2**, procedural publication **2**, and
generated-script SHA256
`d2bc70eec1099afc54a6dadeef16f77cb663dca8eea490dbf0fed74fccd474bb`.
Earlier receipts retain their original scope and identities.

| Final native build under `build/spline-bands-20261012-01/` | Executable suites | Time |
| --- | --- | --- |
| `final-analyzer-cleanup-max2026-01` | 27 passed | 6.95 s |
| `final-analyzer-cleanup-max2027-01` | 27 passed | 7.59 s |
| `final-analyzer-cleanup-fault2027-01` | 27 passed | 7.71 s |

The totals include the existing licensing suites, whose source remains unchanged.
The fault build is private and NEVER SHIP. All 102 recorded inputs, including
the interpreted script, must match these receipts during final verification.

The old duplicate-sampler parity test now uses independent candidate streams and
analytic rectangle support to compare complete transforms. Current tests exercise
Analyzer outer/inner modes and explicitly reject the retired mode. Historical
benchmark/migration fixtures remain byte-preserved under `retired-fixtures` and
are absent from active build/tool entry points. `measure_costs.py` compiles only
current field/generation benchmarks; comparisons use the frozen historical
executable without restoring its source into the product.

Both final ordinary hosts run `qualify_host.py --performance` from fresh owned
profiles, and each passes **58/58 campaign steps**:

- `foundation-spline-final-clean-2026-01/qualification-fd37e3432be9410a923665e296c8f786.json`
- `foundation-spline-final-clean-2027-01/qualification-67e59d768fee4cf19cafff4f65328ae3.json`

Each includes 35 native authoring/radius/field Undo events, 54 transport
assertions, field/geometry/source/units/lifecycle checks, publication and retained
display, actual rendering, workload checks and final retired-scene rejection.
The image verifiers pass 18 field, 16 palette and five Scanline comparison checks
per host. These totals describe different assertion/step levels and must not be
added together as independent test scenarios.

Each final host passes all 23 workload invariants. For ten layers and 20 shared
sources, warm median palette/pending-width edit times are **692.63 / 867.07 ms**
in Max 2026 and **596.83 / 748.00 ms** in Max 2027. First field display is
**2.15 / 1.56 seconds** respectively. The explicit refresh plus sync still makes
two controller refresh calls per field edit, independent of sibling count.
Palette-only geometry/transform/owner uploads and unchanged solves/extractions/
uploads remain zero. These primitive synchronous host fixtures do not qualify
heavy artist scenes, forced regeneration or presented FPS.

`foundation-spline-final-clean-fault-2027-01/gpu-failure-e6f4a01c2ca14154bb80d19be7ca37ef.json`
passes **44/44 private fault checks** on the final matched source. It exercises
later-group shader/buffer failure, complete fallback, immutable prior publication,
Manual retention, recovery without a placement solve and release to zero retained
reservations. This is injected realization failure, not a physical device-loss
witness. All three final owned hosts record the actual four loaded module paths
and hashes before guarded shutdown. The normal 2026/2027 profile hashes remain
unchanged and the artist session was not used.

Final CPU receipts are `final-clean-generation-cost-01`,
`final-clean-field-cost-01` and `final-clean-cost-comparison-01` under the work's
build directory. The comparison passes all nine workloads over three alternating
pairs with equal accepted counts and the predeclared noise-aware regression rule.
At 100k candidates, normalized eight/32-Band Sharp query medians are
**139.234 / 298.888 ms**, p95 **145.372 / 315.568 ms**. Preparation medians are
**2.947 / 2.922 ms**. Saturated 32-Band and steep concave eight-Band query medians
are **377.719 / 289.823 ms**, with preparation **111.884 / 99.924 ms**.
The declared simple CPU gates pass; the comparison still has the documented
current-preparation-outside-timer versus historical-inline asymmetry.

Final generated/repository/website command logs and exact source/binary/module
verification are in `build/spline-bands-20261012-01/final-checks-02/`.
Generated consistency passes for **258 controls** and the exact script above;
**161 repository tests pass in 12.27 seconds**.
`commands.json` retains arguments, working directories, exit codes, durations and
output hashes; `verification.json` records the listed preservation checks.
Earlier failed and interrupted attempts remain evidence, without being relabeled
as final passes. Branch, HEAD, staging and the inspected unrelated tracked scopes
are unchanged. There is no initial byte inventory for every untracked/ignored
file, so this is not a whole-workspace preservation certificate.

Implementation and bounded engineering qualification are ready for review.
P2/P6 remain partial: complete physical control/keyboard/container/DPI/tablet
coverage, heavy artist assets and long sessions, intended renderers/proxies,
physical device-loss recovery and presented-frame measurements are still open.
The physical 96-DPI witness predates this final Analyzer-only cleanup and keeps
its original identity. No installation, packaging, commit, push or knowledge
activation was performed. The previously recorded knowledge generation remains
stale for changed sources; read current files until a separately reviewed refresh.


## UI refresh correction — 13 October 2026

The user reported slow Layout switching and repeated refresh when moving across
Models & Points. This correction changes the authoritative generator/template
and regenerated MAXScript only; calculation, schema and native modules remain
unchanged at 0.80.0. The existing implementation and historical receipts above
remain intact.

Cause: the generic control-event wrapper treated the colored list's `MouseMove`
and `HandleDestroyed` as edit events. Every pointer movement invoked the edit
gate and full page layout, which invalidated the list and reset its tooltip row.
The destruction wrapper also prevented tooltip disposal after the owner closed.
Layout mode changes separately invoked a retired component layout path, reflowing
unrelated open pages before the composed page's own layout.

- Passive list events now retain their own lifetime guards without the edit/layout
  wrapper; pointer inspection is suppressed while the list is synchronizing.
  Destruction can dispose the tooltip even after the owner has closed.
- Removed the obsolete Layout component visibility/height pass. Mode changes use
  the composed page's conditional rows once. Reapplying row visibility, control
  widths and native radio positions skips unchanged values.
- The focused fixture `tools/spline_bands/ui_refresh_host.py` passed **51 assertions
  in each of Max 2026 and 2027**, in owned profiles
  `build/mcp-qualification/foundation-spline-ui-refresh-final-{year}-01`.
  It exercises actual .NET MouseMove and native radio callbacks, inline/popup
  selection and tooltips, all four mode visibility states, cleanup after owner
  closure and a pristine-script remount. A nonempty 2,000-placement Manual result
  keeps full transforms/identities, preparation and publication across navigation;
  hover does not change source/GPU counters. Counter instrumentation is confined
  to a hashed owned copy; the pristine generated script is restored afterwards.
- `build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q`:
  **161 passed in 13.74 s**. Generated consistency passed with 258 controls;
  receipt `build/ui-refresh-20261013-01/final-generated/generated-check.json`.
- Paired Max 2027 callback probe, same owned host/input and frozen original versus
  final generated script: 100 same-row moves **8,489.1 → 19.1 ms**, layouts
  **100 → 0**; 20 cross-row moves **1,979.8 → 15.0 ms**, layouts **20 → 0**.
  Eight mode switches had median **793.2 → 302.5 ms** and page layouts **4 → 1**
  per event. These are bounded scripted UI timings with headless display, not
  heavy-scene FPS or universal interaction latency. The nonempty retained-result
  fixture is separate and is not used to inflate this timing comparison.
- Paired receipts: `ui-probe-a7a0175f6a024525aae46f78633e5bd0.json` and
  `ui-probe-091c07e7fe92425c96b91d1204849f74.json` in the final Max 2027 profile.
  The original generated script is preserved in
  `build/ui-refresh-20261013-01/baseline.ms`. Initial probe syntax/interop failures
  and intermediate measurements remain in their original owned profiles.
- Physical inspection of the pristine fixed script confirmed model selection and
  its tooltip, all four Layout options in Max 2027, and Point selection/window
  resizing plus Clusters/Spline switching in Max 2026. These checks do not qualify
  every DPI, large source palette or artist scene.

Script SHA256 `7a92c0b109359657d65d35a2362ce81c7bc357a127cd608bd1df38607d7925c4`.
Both corrected packages were installed on disk with backups and independent hash
checks; see [installation identities and recovery](INSTALLATION.md). Restart
normal Max sessions to load the change. Artist sessions/scenes, licensing, Analyzer,
Git staging and the knowledge-base generation were not changed by this task.


## First-click and panel cleanup — 13 October 2026

The [focused review](UI_REVIEW_20261013.md) reproduces hidden native .NET list
hosts intercepting Clusters/Spline clicks, records the generator fix, and removes
permanent help paragraphs while preserving controls and actionable status.
Both Max years pass 55 new visibility/remount checks and the 51 hover/cache checks.
Actual fresh-header first clicks pass; 161 Python tests, generated/JS checks and
27 native suites pass. Matched 0.79.5/current scenes preserve warm navigation,
Manual/Live and save/reload invariants. Warm UI switching improved, but changed
calculations remain slower in the bounded comparison; this is not blanket
performance certification. Exact new packages are in [INSTALLATION](INSTALLATION.md).

## Modify-only workflow — 0.81.0, 13 October 2026

The user requested removal of the floating layer editor and source-to-Band
navigation, reversible model/Point editing, and a clearer Band layout. The
0.80.0 → 0.81.0 minor records this deliberate workflow change and new conversion
action. Schema 57, native interfaces, Analyzer and MCP versions are unchanged.
The existing 0.80.0 installation remains on disk; this task builds and tests
source but does not package, install, commit, publish or activate knowledge.

- Removed the window, generated control factories, entry buttons, Band chooser,
  navigation helper, lifecycle callbacks and cross-window binding. Current tests,
  semantic metadata and the website sidebar no longer depend on that window.
  The generated tooltip file is now `control-tooltips.json`.
- Models & Points shows adjacent **Pick object** / **Make point** controls;
  only the applicable action is enabled for one selected row. Conversion keeps
  the row identity, labels/colors, weight, transforms and Band assignments.
  A converted Point retains the registered model reference, preventing automatic
  containers from enrolling it again; it resolves to a Point token and does not
  render model geometry or delete the artist's scene object. Pick object can
  restore that model or choose another unused model. Undo restores source kind.
- Auto Radius was already implemented. Supported geometry offers Manual/Auto;
  Points and Empty rows have no bounds and use Manual. Conversion retains stored
  radius preferences; model Auto is inactive while the row is a Point. The Point
  dropdown tooltip explains the unavailable option without a help paragraph.
- Band assignments precede density, below width/range. Advanced has a conditional
  **Scale** heading and adjacent **Min**/**Max** fields. Membership labels and
  tooltips remain informational.

Final automated evidence (no computer-use tools or physical pointer acceptance):

| Check | Result |
| --- | --- |
| Generated consistency, balanced source and JS layout regressions | Pass; 247 semantic controls |
| `build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q` | 161 passed, 12.80 s |
| Fresh SDK builds / native suites, Max 2026 and 2027 | 27/27 passed per year |
| `source_conversion_undo.ms`, separate native events | Seven phases passed per year |
| `ui_simplification_host.py` | 24 checks passed per year: actual handlers, Manual retention, identity/settings, container deduplication, layout, save/reopen and independent copies |
| `auto_radius_host.py` / `authoring_ui_host.py` | 30 + 30 checks passed per year |
| `field_ui_host.py`, Max 2027 | 38 checks passed |
| Current fixture Python syntax / MAXScript delimiters | 38 files passed; this is not execution of every fixture |
| Website import/content checks and TypeScript/Vite production build | Passed locally; no live deployment |

Final generated script SHA256:
`650482e1e1c9d8f6113fc7384dd40608e38bf773ebfa773d83b43e26b517f859`.
The script shrank from **2,321,571 to 1,671,187 bytes (28.01%)**. This does not
measure runtime memory, startup speed or a new installer's compressed size.

Exact command receipts, pre-task fingerprints and source deltas are under
`build/ui-simplification-20261013-01/`. SDK receipts are in `native-2026` and
`native-2027`; final script/loaded identities and individual checks are in
`build/mcp-qualification/foundation-spline-ui-simplification-{2026,2027}-final-01/`.
The build receipts retain their earlier interpreted-script fingerprint; compiled
sources are unchanged and the final script is independently pinned by each host
launch. Owned test processes were closed; both normal Max profile hashes match
their launch baselines. The initial fixture's array-identity assertion failure
and failed/intermediate content checks are retained, not counted as final passes.

Physical artist interaction, narrow/DPI variations and renderer acceptance of
this source remain unqualified. The existing heavy-scene performance limitation
is unchanged. Historical qualification records remain evidence for their own
builds; they are not recertified by this cleanup.


## Authorized local delivery — 0.81.0, 13 October 2026

At the user's subsequent request, both [Max installers](INSTALLATION.md) were
created and installed from verified payloads. The compiled sources, native binary
hashes and final script match the preceding 0.81.0 qualification exactly; no
unnecessary native rebuild or repeated host campaign was performed. Fresh
generated consistency and eight package/version tests passed. Package help was
corrected to remove the retired editor instructions.

Each archive passed integrity/manifest verification, and every installed file was
rehash-verified. Prior files were backed up; old native directories, normal Max
settings and Analyzer files were preserved. Only the owned Scatter registration
value was replaced in each plugin INI. Open artist sessions remained running and
were not scripted or restarted. Save work and restart to load 0.81.0; fresh
normal-profile and artist acceptance remain pending. No commit or website
publication occurred.

Exact identities and recovery paths:
`build/scatter-0.81.0-delivery-20261013-01/installation.json`.


## Band scale profiles — 0.81.1 implementation, 13 October 2026

The user explicitly requested release 0.81.1, installation for both Max years,
documentation and a Git push. Off / Follow Density / Custom adds independent size
variation across each Band while preserving the existing keyed random size range.
Saved format is schema 58 and native Band transport is interface 9; prior scenes
remain paired with their original build. This follows the current-only policy.

Fresh native/core, generator, host, packaging and delivery evidence is collected
under `build/band-scale-0.81.1-20261013-01/`. Final scoped checks and delivery are recorded below; implementation alone is
not a passing host test.

### Final scale-profile evidence and delivery

| Check | Result |
| --- | --- |
| SDK-free core suites | 18/18 passed, 6.87 s |
| Fresh SDK builds and native suites | Max 2026: 27/27, 9.08 s; Max 2027: 27/27, 8.41 s |
| Repository Python tests | 161 passed, 15.99 s; final catalog/package subset: 7 passed |
| Generated consistency and JS layout checks | Pass, 249 semantic controls; final receipt `generated-final/generated-check.json` |
| Scale graph and integration fixture | 29 checks per Max year: analytic scale, unchanged candidates, radius propagation, Follow Density, Manual retention, Live refresh, unrelated-edit stability, failed-successor retention, captured ownership and schema-58 save/reopen |
| Native scale Undo/Redo | Ten separate events per year; closing after Undo cannot reapply a stale graph |
| Existing density authoring / Auto Radius | 30 + 30 checks per year |
| Existing field UI | 38 checks, Max 2027 |
| Prior schema-57 witness | Four checks per year: persistent rejection, actionable error, original bytes unchanged |
| MZP and installed payloads | Both years built from the tested pair and hash-verified; prior files backed up |

The effective size factor is the existing keyed random Band Min/Max multiplied
by its profile at normalized Band progress. Off is one; Follow Density links the
enabled curve shape, excluding Density %. Custom has independent saved samples
and handles. Zero collapses size without removing a candidate. Scale does not
change the density lottery, candidate positions, source selection or Band owner;
subsequent spacing can change acceptance when effective radii change. Manual
fixed radii remain fixed; Auto and Follow Scale radii receive size exactly once.

Sharp fields retain the same prepared coordinate subdivision when scale changes.
Outside boundary uncertainty the scale interpolation error is bounded to 0.005
in multiplier units. An excessively steep profile that cannot meet this bound
fails explicitly and retains the preceding complete publication. Native tests
cover this limit and invalid/nonfinite/oversized traces; this is not an arbitrary
curve precision or unlimited-resource guarantee.

Final generated script SHA256:
`88d573ae37d7f007718dcd928e95733bc91e60eaa3dca6992186a83d791e42e3`.
SDK receipts in `build/band-scale-0.81.1-20261013-01/native-{2026,2027}-01`
retain the earlier interpreted-script fingerprint. Compiled sources are unchanged;
final launch receipts independently pin the above script with the tested native
modules. Actual host records are in
`build/mcp-qualification/foundation-spline-scale-{2026,2027}-03/`.
The `scale_curve_host.py` fixture calls the shared profile-selection handler and
actual graph button/Apply handlers; it does not certify physical dropdown clicks.

Earlier attempts exposed a Python fixture top-level-local error and an invalid
computed MAXScript Undo label. The fixture wrapper and literal Undo label were
corrected before the final two-host runs. An initial stale control-count check
and intermediate website content checks also failed and were corrected. Earlier
receipts and tool outputs remain evidence of those attempts, not final passes.

[Both installers](INSTALLATION.md) are installed on disk with backups and verified
hashes. Normal artist hosts were not scripted or restarted. Restart is required;
normal-profile/physical acceptance remains pending. This user-selected 0.81.1
label does not imply schema-57 compatibility or release certification. No website
deployment or knowledge-index activation is part of this delivery.

Website import/content verification and TypeScript/Vite production build passed
locally for 0.81.1; no live deployment was performed. Both owned test hosts were
closed after checking their process command lines. Normal profile template hashes
still match their launch baselines. The bounded repository snapshot found 4,114
of 4,159 pre-existing files unchanged, 45 intended feature/generated/doc changes
and no missing files; it does not certify unobserved workspace contents. New
scale fixtures are separately included in the source delivery. Unrelated design
assets and knowledge-curation drafts remain outside the product commit.


## Band assignment and Scale layout correction — 0.81.2, 13 October 2026

Requested patch: Scale controls move below the density-curve row, with Min/Max
paired and the profile/editor visible without Advanced. Band source/group rows
use click-to-toggle selection; deselecting the last model, Point or group leaves
an empty Band. Widths, stable IDs and neighboring assignments remain intact.
Assignment writes share one captured-owner handler with an explicit Undo block.
Schema 58 and native Band interface 9 are unchanged; this adds no migration path.

The 0.81.1 baseline probe proved both direct empty writes and programmatic visible
list deselection already worked. The visible list used MultiExtended, which needs
modifier-key selection; the user-facing correction changes only the Band choice
list to MultiSimple. The main source list retains its Ctrl/Shift behavior.
[Microsoft's selection-mode contract](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.listbox.selectionmode?view=netframework-4.8.1)
specifies click/Space toggling in MultiSimple. Scripted checks exercise actual
SelectedIndexChanged write-back, not physical pointer input.

| Final check | Result |
| --- | --- |
| Fresh Max 2026 / 2027 SDK builds | 27/27 native suites per year, 9.13 / 7.11 s |
| Repository Python tests | 161 passed, 14.49 s; final catalog/package subset 7 passed |
| Generator and layout assertions | Passed, 249 controls; correct order/basic visibility and list modes in both generated views |
| Band selection/layout fixture | 19 checks per year: direct/group emptiness, main/container views, Manual retention, copy and save/reopen |
| Native assignment Undo/Redo | Five separate events per year, including refresh after Redo |
| Existing scale-curve integration | 29 checks per year, including relevant Live changes and unrelated-edit stability |
| Prior 0.81.1 schema-58 reopen | Passed both years under UI 0.81.2; old scene bytes unchanged |
| Packages and installed payloads | Both years match tested source/native identities and were rehashed |

Final script SHA256: `c4a60a37c09a4aff8daafb465a53c199ff5fb3bbdbb5abe020092b6f78f35c41`.
Build, baseline and delivery evidence:
`build/band-ui-0.81.2-20261013-01/`. Baseline reproduction:
`build/mcp-qualification/foundation-spline-band-clear-2027-baseline-01/`.
Final matched hosts: `build/mcp-qualification/foundation-spline-band-ui-{2026,2027}-01/`.
The knowledge status check reported stale generation `44bb5752…dfa0d3`; source
inspection and host evidence were used without changing knowledge registration.

[Installers and recovery](INSTALLATION.md) retain the earlier deliveries. Restart
normal Max to load the installed patch; physical artist/DPI/renderer acceptance
remains separate. No computer-use tools, artist-scene commands or website
publication were used.

Website import/content checks and the TypeScript/Vite production build pass locally
for 0.81.2. No live website deployment was performed.

## Bounded performance corrections — 0.81.3, 13 October 2026

Version decision before implementation: advance delivered 0.81.2 to requested
0.81.3 for three bounded corrections preserving placement behavior and saved
schema 58: unchanged-layer preview reuse across calculation publications,
constant-time evaluation of prepared density curves, and complete scale-profile
retained-memory accounting. Native Band interface 9 and independently versioned
Analyzer, licensing and MCP products stay unchanged. New preview-comparison
primitives require a matched script/native package.

Scope: F02/F03 preserve candidates and collision results; F04/F08 preserve Manual
state and unchanged buffers; F05 retains staging and atomic rollback; F06 accounts
for retained scale storage. User authorization includes build, package and local
installation for manual acceptance, but explicitly excludes test execution and
opening Max. No automated/runtime qualification is claimed for this patch.

Implementation:

- Preview reuse compares the new accepted rows with the committed owner's rows
  using bounded native exact comparisons of ordered transforms, source indices
  and Band owners. Source node/row correspondence, source-geometry signatures,
  Band dictionary and display settings must also match. Changed content still
  rebuilds normally. Candidate/protection metadata publishes even when its visual
  geometry is unchanged; no placement decisions or random channels change.
- Radius overlays additionally compare both radius values and their inspection
  settings/field key. Point Cloud sampling retains the published seed, including
  a display-mode switch with pending Manual recipe edits. All reuse decisions
  happen in staging; no mutation was added to the publication/rollback tail.
- Immutable fields use the same interpolation arithmetic after construction
  validation. The public checked density helper still rejects malformed inputs.
- Retained bytes now include scale-curve capacities and scale-slope storage.
  Near-limit fields can correctly fail admission earlier; the existing failure
  path retains the previous complete publication.

Manual acceptance should cover two independent layers (change only one), source
geometry and Band-owner changes, Mesh/Point Cloud/Proxy and radius displays,
pending Manual seed/recipe edits, Live updates, and failed successor recovery.
Compare buffers/preparation separately from unchanged placement identities.
These scenarios are not claimed as executed by this delivery.

Delivery evidence: `build/performance-0.81.3-20261013-01/`. The owned build helper
invoked CMake configure and only the four product-module targets for each SDK;
it did not invoke ctest or build/run test executables. Both Max 2026 and Max 2027
compilations succeeded. UI and catalog were regenerated; generated/native source
hashes were frozen across compilation and packaging. The normal test-running
build wrappers were not executed. Package payloads and installed files match
their manifests. [Installation details and recovery](INSTALLATION.md) record both
profiles and preserved previous files. No Max launch, restart, runtime test,
commit/push, knowledge-index refresh or website deployment occurred.

Source diff inspection covers staged reuse, unchanged rollback ownership,
changed geometry/source/Band/seed invalidation and radius-only changes. This is
reasoning from source, not executed regression evidence. Website reference data
is regenerated from the updated guide/changelog; the website is not built or
published by this delivery.

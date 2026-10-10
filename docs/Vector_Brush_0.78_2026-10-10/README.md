# Vector Brush 0.78 — integration work and qualification

**Superseded by [0.78.1](../Brush_Start_0.78.1_2026-10-10/README.md).** This original qualification missed the artist Start Brush button-to-timer path; a function-binding error stopped the session on its first tick. The receipts below remain the historical 0.78.0 results. Use the corrected package.

Status: integrated and packaged as a tested Max 2027 development candidate. This is bounded scripted qualification, not a release certificate or physical-input sign-off.

[Scatter 0.78 installer](../../dist/Vector_Brush_0.78_2026-10-10/Max2027/CyrusScatter-0.78.0-Max2027.mzp) · [paired Analyzer 0.14](../../dist/Vector_Brush_0.78_2026-10-10/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp) · [package identities](PACKAGE.json) · [test identity and measurements](EVIDENCE.json) · [reproduction](../../tools/vector_brush_078/README.md)

Work started from `880ea89b654a389191c02e7a373807044ec713f1` on `codex/workflow-0.75`. Pre-existing documentation changes, `experiments/`, landing-page work, licensing, artist assets and the running artist process were preserved. This delivery is local; no commit, push or normal-profile installation was performed.

## Product decision

Replace the stroke replay backend with canonical vector regions selected after the four isolated prototypes. Paint unions a swept circular footprint into the region; Erase subtracts it. Repeated gestures edit the same area. No saved stroke history, conversion path, legacy evaluation fallback or bitmap authority remains in the new brush.

The receiving layer owns models, counts and candidate identities. Named Paint Areas each bind one receiver and contribute coverage to that population. Overlap takes maximum effective density, admitting each candidate once; the strongest area's scale wins, with saved area order breaking ties. Explicit Include/Exclude rules still constrain the resulting population.

## Supported domain and saved format

- Version 0.78.0; scripted schema 55. Registration IDs remain unchanged.
- New vector payload only; old development brush data is explicitly rejected, not silently converted. Work in new scenes / copies.
- Local XY single-valued receivers: planes and terrain, including transformed receivers. Closed, vertical, folded or stacked projected faces are rejected before authoring.
- Brush and fade widths measure distance in the transformed projection plane. Terrain slope does not stretch the width into geodesic distance.
- Optional inward and outward feather widths; density and scale each have a separately editable curve. Scale multiplies the existing instance basis. Candidate positions and identities are retained.
- Precision: 0.0001 receiver-local units; circular footprint: 96 edges. Limits: 200,000 contour vertices, one million receiver faces, 128 areas per layer. Capacity failure preserves the previous complete result.
- Cached border drawing replaces the old adaptive triangle tint. Coverage samples remain an optional bounded diagnostic display. No viewport FPS claim until measured separately.

## Work list

- [x] Replace stroke core/storage with vector Boolean regions, distance index, curves and a new payload.
- [x] Correct Max Painter radius handoff.
- [x] Replace old brush history controls, import transition and direct legacy filter paths.
- [x] Add inward/outward feather, density/scale curve controls and vector border feedback.
- [x] Compile native Max 2027 modules and pass 15 native suites.
- [x] Qualify the generated script and main/floating UI bindings inside a disposable Max host.
- [x] Test additive monotonicity, local erasing, large brushes, holes, overlap, multiple receivers, outside fade and scale.
- [x] Test cancellation, Undo/Redo, layer copy, save/reopen, failed successors and target invalidation.
- [x] Verify Manual/Live, retained display and receiver candidate-cache reuse.
- [x] Record authoring, feedback and population-update timings separately.
- [x] Update current guides, help catalog and passive vector inspection; deliver matched installers.

## What was replaced

The production brush no longer stores or evaluates individual strokes, per-stroke strength/softness, face-to-dab histories, adaptive triangle tint, old brush payloads or a conversion/import path. Repeated drawing changes a canonical region. Swept circular footprints connect consecutive hits; missed hits break the connection. Regions are clipped to the receiver domain, so painting with a radius larger than the entire receiver still produces visible receiver-edge borders.

Removed model-owning paint-set authoring/background-composition branches and the duplicate discarded popup implementation. Current Paint Areas own coverage only; both UI views edit the same native document. Layer copy now preserves its receiver list and independently clones its Paint Areas. Historical reports and frozen laboratory fixtures remain explicitly historical, outside the product package.

`cyrus.configuration/2.0` passive inspection reports vector areas/revisions instead of stroke counts or set-allocation fields. Receiver lists and area revisions participate in inspection freshness. The bounded Plan 0.73 write API is unchanged.

## Final evidence

Final native build: `build/vector-brush-078/max-06`. Final private Max host: `build/vector-brush-078/host-08`. Loaded module paths were checked before loading the copied generated script. Its SHA-256 is `00250595089391d3966bdab78fdedd45df8cb348144544da44fc96441721c427`. Exact native/archive hashes are in [PACKAGE.json](PACKAGE.json); compiled source and vendor hashes are in [EVIDENCE.json](EVIDENCE.json).

| Check | Result and scope |
| --- | --- |
| Generated script/layout/catalog | Pass; 238 semantic controls; both main captions 0.78; current schema 55 |
| Python | 143 tests passed, including bounded passive vector inspection |
| Native Scatter | 15 suites passed; brush core alone exercised 9,054 assertions, including growing additive regions and oversized brushes |
| Max vector integration | 430 assertions passed across acceptance, extended and performance fixtures; many are per-candidate Exclude/position checks |
| Max passive inspection | 6 checks passed; area identities/revisions exported without additional paint field preparation or queries |
| Max playback/retained regression | 835 assertions passed: unrelated/relevant animation, Manual/Live, source geometry, parameters, density maps, retained Points/Proxy/Mesh publication and scene lifecycle |
| Analyzer | Unchanged 0.14 source; fresh Max 2027 SDK compilation and one native suite. Analyzer host/renderer qualification was not repeated |
| Packages | Archive contents/hashes verified; Scatter payload matches the final host exactly; Clipper2 license included |

The host checks include idempotent repeated paint, overlap without duplicate plants, separate receiver ownership, inactive/relinked receivers, deterministic density thinning, unchanged surviving positions, scale-only basis changes, explicit Exclude overriding outward feather, cancellation, Undo/Redo, actual curveControl and floating-editor bindings, native Painter radius, large-brush borders, topology-error retention/restoration, independent copies and save/reopen identity. Static timeline changes and repeated border refresh preserve relevant prepared caches.

## Measured performance

These are single-run scripted measurements on this workstation, not presented FPS or a hardware-independent promise. The host fixture uses two 200 × 200 receiver planes, one simple box source and 5,000 candidate rows. No heavy plant textures or production renderer were exercised here.

| Workload | Median | p95 | Maximum |
| --- | ---: | ---: | ---: |
| 400 successive region edits, including native commit/Undo capture and border preparation | 4.018 ms | 5.422 ms | 7.195 ms |
| Separate 40-edit feathered workload: author/commit | 0.418 ms | 0.883 ms | 0.916 ms |
| Same workload: border preparation | 1.997 ms | 3.067 ms | 3.103 ms |
| Same workload: explicit full scatter Update/publication | 54.873 ms | 63.452 ms | 65.785 ms |

In the 400-edit workload, the first 20 edits had a 0.649 ms median and the last 20 had a 4.873 ms median: increasing border complexity still costs work. The design removes history replay; it does not make complex contours free.

For the 40 explicit Updates, receiver-cache builds stayed at **8**, cache hits increased **92 → 172**, and the same **2** receiver entries remained cached. Combined row assembly increased **50 → 90** because this workload intentionally pressed the equivalent of Update each time. Cached receiver candidates were reused; complete population publication still costs considerably more than brush authoring. The native-only 400-edit plus 10,000-query microbenchmark took **67.945 ms**, with 986 final boundary vertices and 554,144 segment visits. This microbenchmark excludes Max and feedback and cannot be compared directly with the host row above.

## Failures found and resolved during integration

- Identical-target rebinds and conservative timeline invalidation discarded prepared paint caches. Revalidation now retains them when geometry and object transform are unchanged.
- Layer copy omitted receiver membership; copies now retain their own receiver lists and native region documents.
- Oversized footprints could put every border off the receiver. Canonical paint is now clipped to its receiver domain.
- A curve-point event could expose updated graph handles before Max updated sampled values. Apply/Close compare both handles and samples. Editable graph metadata and native curve samples share one Undo/Redo action; unchanged settings do not create another revision.
- Two test-fixture mistakes were corrected without hiding product results: an Undo comparison used integer versus float string formatting, and a cache assertion confused combined row assembly with receiver candidate generation. The final tests compare the actual native values and correct cache counters. The passive-inspection fixture also reacquires its node after save/reopen.

Earlier intermediate runs and errors remain under `build/vector-brush-078`; their receipts do not qualify the delivery. Final tests used matching final source/script/native identities. All owned private Max processes were closed after qualification. No computer use was used.

## Remaining acceptance

- [ ] Physical mouse/tablet input, cursor feel, continuous long gestures, DPI, actual graph-handle dragging and visible layout review.
- [ ] Sustained heavy plant/material scenes, total process/Undo peak memory, device recovery and presented frame-time distributions.
- [ ] Very small/large system-unit scenes, high-complexity receiver domains and contour-cap workloads inside Max.
- [ ] General curved-surface painting beyond single-valued local-XY terrain; this requires a separately validated method, not a silent fallback.
- [ ] Installer execution/restart/recovery, current renderer smoke qualification and Max 2026 application runtime.

For artist acceptance, create a new 0.78 scene, add a layer/receiver/models, add a Paint Area, then test a long stroke, repeated crossing strokes, a brush larger than the receiver, Erase holes, inside/outside widths, both curves, Undo/Redo and Manual versus Live. Do not open an older development setup expecting conversion.

## Dependencies and historical evidence

Uses the same pinned Clipper2 source qualified by isolated prototype A, now under `AminScatter/third_party/clipper2/` with its Boost license and provenance. Prototype and earlier release reports remain historical evidence; their old storage / API tests are not current vector qualification.

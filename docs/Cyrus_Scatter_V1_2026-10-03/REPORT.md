# Cyrus Scatter 1.0: implementation and qualification

3 October 2026. Starting source/docs checkpoint: `9aca3683f3ec62aaf2fff0e27a7b57301f51b95e`, pushed to main before implementation. The underlying starting performance engine was Scatter 0.64; the previous Brush was an isolated prototype. This round integrates the features into one scene-owned product and replaces the nested layer UI. It does **not** promise that unlimited full-detail geometry has no drawing cost.

## Result and architecture

The product now presents ordinary Max command-panel rollouts, one shared editor for the selected layer, useful cached statistics, separate viewport visibility, and a procedural Brush document owned by each painted layer. Public names/version are Cyrus Scatter 1.0.0, CyrusScatter.ms, CyrusScatter.mcr, CyrusScatterStartup.ms, CyrusBrush.dlx and CyrusBrushStorage.dlh. Both SDK-specific packages include the main native engine and CS Edit as well as the two Brush modules.

The controller remains the saved Geometry object; CS Edit remains a native modifier. Changing the controller into a new modifier class would require a separate scene migration. Native Modify-panel behavior was achieved without that migration. The original class ID, internal `AminScatterObject` name, native `AminScatter.dlx` filename and serialized parameter names remain intentionally compatible. The public `CyrusScatterObject` alias is used by new creation paths. Serialized script-class version is 49; user-facing product version is 1.0.0. Saved Brush payload version is 3, with version 2 accepted as an empty-base document.

This follows Autodesk's distinction between a script variable, its public name and permanent class identity. Native rollout state belongs to Max's command panel. [Autodesk scripted plug-ins](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-B0B9C1BF-168C-47D2-A4BE-12D93116FE79.html).

## UI replacement

The generated runtime no longer creates per-layer nested subrollouts, factory rollouts, responsive width polling or Win32 layout repairs. The old extraction templates remain in the generator as input for existing feature controls; they are not a second runtime UI. New native conversion and Brush stages generate the product script, with native category rollouts and direct selected-layer binding.

Opening/collapsing a standard header leaves the controls mounted. Thirty selection changes reuse the same distribution-editor HWND and bind the correct layer values. Unchanged rows are compared element by element before assigning the listbox items; the passive one-second status timer skips held input and reads cached scalars. No statistics callback asks for placements. The generated source is about 3,200 lines, compared with roughly 14,500 in the previous nested layout.

The real UI check opened/collapsed Layers, Brush and Update with single clicks, started Brush, painted a connected stroke, stopped with right-click and published through Update now. A native session exit initially left the label showing “active” because no field revision changed. The session timer now refreshes the status on exit as well. Native Integer64 suffixes are removed from public count labels.

Layers have persistent GUIDs, independent copied Brush documents and monotonically assigned Edit keys. Deleting another layer no longer changes a painted layer's Edit ownership key. Viewport visibility filters the drawing membership while retaining enabled layers for rendering and inter-layer blocking. The public final-enable checkbox controls the existing enabled membership. Visibility does not regenerate placements.

Final copy qualification caught a sampling defect: including the ownership GUID in mask acceptance changed plants along fractional-density or soft edges when Copy Layer assigned a new GUID. Sampling now depends on the base population and seeds; ownership remains a separate GUID/Edit key. The strengthened fixture compares all 1,943 copied placements, including transforms, sources and candidate IDs, at 57% density before modifying the copied document independently.

Treat layer identity as scoped to its owning controller. Copy Layer generates a new GUID; future automation should pair it with controller identity rather than assuming saved parameter values cannot be duplicated by a whole-controller clone. The qualified independent-copy operation here is Copy Layer.

## Brush and procedural identity

The Max Painter adapter is now the normal `brush_host.cpp` product module, with public `cyrusBrush*` APIs. The companion DLH registers the saved ReferenceTarget class before scenes load. The document contains ordered surface strokes and target references; the UI does not own the data. Plane and scaled curved targets use an indexed mesh snapshot and canonical BVH ray hits, repairing Painter's inconsistent face/barycentric reports against that same snapshot.

The existing field uses connected surface coverage, captured visibility and world-space metrics; it is not exact geodesic distance. Radius changes replay/resample the captured cursor path rather than drawing a straight 3D segment through a curved target. Paint increases a density field and Erase reduces it. A new document starts at zero; Fill/Empty set its base and reset history in one undoable operation. Histories and references survive saving/reopening. Restored histories can be edited before the first placement request, including when their receiving target is hidden.

The keyed path adds a candidate ordinal before acceptance/compaction, alongside face and barycentric metadata. It does not add random-number draws to the legacy generator. Legacy layers remain on their old two-field row path until Brush identity is enabled. Fill at full density matches that layer's legacy transforms in the acceptance fixture. Source weighting/policy, orientation, scale/falloff, collision, final cleanup, geometry/preview and Edit consumers preserve metadata.

Brush filtering occurs after scale/falloff and before source policy/transforms and inter-layer blockers. This order preserves surviving candidates' index-based scale randomization. The Edit population signature describes the full base rather than the filtered row list; absent edited candidates remain dormant. A changed seed/base population remains a real binding change and is not silently treated as the same candidate set.

For eligible painted non-texture, non-final-pass layers, the prepared base is reused across mask revisions. The key includes input/settings/time, relevant node transforms, Analyzer runs and existing invalidation revisions. Brush filtering returns copied matrices; source offsets/scales cannot mutate that retained base. Texture distribution is conservatively regenerated, and explicit Update invalidates the prepared base. Field spatial indices are retained by document revision, shared with the bounded density overlay. Idle navigation performs no picking, replay or mask evaluation.

Manual mode publishes plant changes on Update. The active Brush timer coalesces mask/history updates at 150 ms and acts only while a session is tracked. Its overlay defaults to 2,048 samples and is independent of the layer's actual generation candidates. It is neither a UV mask nor the final population. Surface shape/topology changes preserve the document and report an incompatible binding. Multi-target painting, animated/deforming targets and automatic remapping are not qualified.

An integration fixture also exposed an existing function-reference problem in recursive Final Cleanup after performance tracing wrapped `placements`: the wrapper's later declaration made the bare name an undefined implicit local. The recursive call is now explicitly `this.placements`; the actual final-output path passed afterward.

## Performance preserved and measured

Retained Nitrous Point Cloud and GPU-instanced Mesh display remain the existing 0.64 paths; Proxy retains its bounded batching. Native CPU generation still uses its bounded execution policy, including at most four participants for automatic clustered work. This release adds no CUDA/OpenCL computation and no new main-thread Max SDK access from worker threads.

A 20,000-instance Mesh fixture ran 45 camera/redraw steps. Placement publication/base-build counters, Brush build/query/application counters and retained publication/update/upload counters stayed unchanged. Hiding the layer also caused no placement rebuild. This proves avoidance of repeated work in that fixture; the recorded synchronous step times are **not presented FPS**, and the fixture's simple source is not an all-asset performance promise.

The original `Test Scene/SaveSelect 2.max` was opened in a separate process with its Analyzer dependency. Its six legacy layers survived and produced no reported preview-generation errors. No save to the original was issued. The preview count can be far below placement count because detailed source geometry reaches the existing face/instance budget:

| Layer | Placed | Preview instances in that check |
| --- | ---: | ---: |
| Grass | 44,958 | 42 |
| Leaves | 200 | 200 |
| clover | 3,529 | 72 |
| BushesCenter | 70 | 0 |
| Bourder | 3,342 | 11 |
| Street_Plant | 44 | 7 |

The new `Limited` state and placed/preview distinction explain this situation. This check verifies scene loading and the current legacy path; it is not a new before/after render-image or FPS comparison against 0.64. Existing retained-Mesh measurements remain in their dated report.

## Qualification

All Max processes for this campaign used private configuration/native/startup directories under ignored `build/`. The artist's original live process was not reset, installed into or saved. Completed private fixtures were closed after collecting their results. Exact package/source/native fingerprints and the selected results are in [the evidence manifest](evidence/MANIFEST.json).

| Gate | Evidence/result |
| --- | --- |
| Native core | All 11 suites passed with the Max 2026 and 2027 SDK builds; new tests cover Fill/Erase/base persistence, v2 compatibility and invalid bases |
| Python | 62 MCP/tool tests passed |
| Native editor | Same HWND across 30 layer switches; correct values, unique GUIDs, visibility/render membership and no placement rebuild |
| Procedural mask | 4,000 base candidates; 613 painted / 511 after Erase in the fixed fixture; full-base transform equality, stable IDs, Undo/Redo, history edits and Manual publication |
| Cache and copy | Six base-cache hits across mask edits; protected matrices, stable surviving scales, identical fractional-density copied placements, independent document/GUID/Edit key and invalidation on true generation changes |
| Curved geometry / Edit | Scaled sphere coverage, preserved history after invalid target changes, restored target, hidden evaluation, dormant Edit restoration, layer deletion and seed mismatch |
| Output combinations | Non-default texture dispatch without advanced axes, empty/point-only source policy, collision and Final Cleanup metadata; hidden-layer bake and production bridge match final placements; transient cleanup |
| Save/reopen | Fresh-process history/IDs/output match; history edits before generation and on hidden targets |
| Real interaction | Final installed script: native Start, a two-sample mouse stroke, right-click Stop, Manual cached plants, single-click native rollouts and Update now: 1,102 → 1,822 tree placements. The baseline is recorded before mouse input |
| Render | Real 128 × 128 Default Scanline render: 2,522 painted-demo placements including a hidden preview layer; transient cleanup. No new Corona/V-Ray/Arnold qualification |
| Installation | Actual Max MZP reader, installed-byte checks against its manifest, startup restart and four loaded native module paths/hashes |
| Uninstall | Owned startup/INI registrations removed; unrelated INI registration, scene controllers and the recoverable product folder preserved |
| Existing artist file | Original six-layer scene opened in a private Max process, legacy identities/path intact, original not saved |
| MCP regression | Nine generation/Undo/idempotency cycles, 11 failure/refinement/recovery scenarios, retained display/inspection, capture and stdio seven-tool acceptance |

MCP's schema, local approval model and bounded design scope remain unchanged. Brush is available to artists in the plugin, but is not a new MCP mutation tool. The MCP test host qualified the existing automation interface against v1's main/Edit engine; it did not exercise the Brush adapter. Custom ML, automatic plan/PDF interpretation and unrestricted scene composition remain future work.

Product, fractional-copy, mouse, render, installation and fresh-process reopen checks use the final generated script. Navigation, legacy-scene, MCP and uninstall records preceded the final UI/sampling cleanup: the native binaries and installer cleanup are identical, navigation used a fully filled mask, and legacy/MCP fixtures did not use Brush. The manifest records the source profile of each result and this qualification boundary.

## Packaging and compatibility limits

The package builder refuses to label current source as historical 0.64. Historical experiment packaging must use its frozen checkout. An MZP uses numeric `version 1.0`; the filename/public metadata/manifest carry 1.0.0. Max's package reader and clean startup were exercised instead of relying only on ZIP extraction. [Autodesk ZIP-script packages](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/File-Access/Zip-file-Packaging-and-Drag-And/GUID-A085EFDD-A397-41D6-9391-421344294422.html), [startup order](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Introduction/General-MAXScript-Topics/GUID-A04C0E75-F82A-41AC-92E8-D7CB1D797430.html).

Max 2026 is SDK/native-test coverage, not application-runtime coverage. Renderer proxies, arbitrary third-party plugins, animated targets and every legacy workflow have not been exhaustively qualified. Existing native Area/spline and Analyzer contracts remain; a comprehensive semantic zone manager is not newly implemented. Brush explicitly rejects intra-layer Relax/Final Relax and unprojected movement until their mask-constrained behavior is designed and tested. Broader performance claims require the heavy foliage fixtures and display-detail work in the next roadmap.

## Source map

| Area | Authoritative source |
| --- | --- |
| Native selected-layer UI | `AminScatter/tools/ui/native-v1.cjs`, `templates/native-layers.ms`, `templates/layer-status-helpers.ms` |
| Brush integration/scheduling | `procedural-brush.cjs`, `templates/brush-integration.ms`, `templates/brush-session.ms` |
| Generated product | `AminScatter/scripts/AminScatterObject.ms` (generate from the `AminScatter` working directory) |
| Candidates/metadata | `include/scatter.h`, `src/scatter.cpp`, `src/placement_identity.inc`, `src/max_bridge.cpp` and affected bridge consumers |
| Brush field/storage/host | `include/brush.h`, `src/brush.cpp`, `src/brush_host.cpp`, `src/brush_storage_plugin.cpp`, `tests/brush_tests.cpp` |
| Edit persistence | `src/cyrus_edit.cpp`, `src/cyrus_edit_stack.inc` and generated layer-key/signature helpers |
| Release | `AminScatter/installer/`, `tools/build_max.py`, `tools/v1/` |
| MCP regression setup | `tools/mcp/launch.py` defaults to the v1 engine; host/server authorization and tools are unchanged |

The useful engineering conclusion is separation of responsibilities: persisted procedural input, stable candidate ownership, cached placement, retained display and a passive native editor. The next changes should improve one measured boundary at a time instead of replacing the whole engine.

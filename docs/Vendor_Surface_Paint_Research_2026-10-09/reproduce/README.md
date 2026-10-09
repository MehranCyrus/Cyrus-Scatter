# Reproduce the focused vendor tests

Run from `F:\Cursor\_Cyrus_Apps\CyrusScatter`. These are disposable research fixtures, not product tests or installers. Use a new ignored run; never use an artist scene. The launcher reuses the pinned 0.74 package and private-profile template from the earlier research. It extracts matching native modules into the private profile but the vendor-only transport does **not** load Cyrus's orchestration script.

```powershell
python docs/Vendor_Surface_Paint_Research_2026-10-09/reproduce/lab.py capture --run build/vendor-research-NEW
python docs/Vendor_Surface_Paint_Research_2026-10-09/reproduce/lab.py launch --run build/vendor-research-NEW
```

Wait for `host/ready.txt`; verify `host/launch.json`, `max-version.txt` and `loaded.tsv`. Every request below uses:

```powershell
python docs/Vendor_Surface_Paint_Research_2026-10-09/reproduce/lab.py request --run build/vendor-research-NEW --script docs/Vendor_Surface_Paint_Research_2026-10-09/reproduce/SCRIPT.ms
```

Only one request may be outstanding. `PENDING` after 50 seconds does not cancel Max. Inspect the exact request in `response.txt` and its `stage.txt` before another mutation. Process cleanup requires matching the saved PID, executable and private profile arguments; never kill Max by name.

## Chaos: valid fixtures and deferred evaluation

1. Run `chaos_smoke.ms`, then `chaos_capture.ms` to define the exporter. Initial zero-instance files are diagnostics, not measurements.
2. Run `chaos_renderer.ms` to select the installed Corona renderer in this disposable scene. Run `chaos_models.ms`: its public `addModelNode` calls initialize the model group records omitted by the first property-only fixture. Require 600 exported nodes and both model types.
3. Run `chaos_select_refresh.ms` and `chaos_surface_cases.ms`. `analyze_chaos.py --run ...` compares the valid three-surface campaign. Adding/removing uses tab append/delete. Reordering clears/reconstructs the list and restores its original order; it is not a tested drag-reorder gesture. Restoring all original transforms is an important control.
4. Use `chaos_twenty.ms` once to create/reuse the 20 named planes and extra receiver. Its single-callback captures were **invalid in this pass**: parameter lists changed while exports remained stale. Do not use their results.
5. For the validated large campaign, send **separate requests** in this order, waiting for SUCCESS between each:

   - `twenty_configure_only.ms`
   - `twenty_capture_only.ms`
   - `twenty_add_only.ms`
   - `twenty_capture_fixed_add.ms`
   - `twenty_density_configure_only.ms`
   - `twenty_capture_density_baseline.ms`
   - `twenty_add_only.ms`
   - `twenty_capture_density_add.ms`

6. Run `analyze_twenty.py --run ...`. It requires 10,000/10,000 Fixed Total, 10,000/10,500 Density, positions within the fixture and placements on receiver 21. A matching count alone is insufficient to exclude stale output.

`chaos_update_cases.ms` is an exploratory **single-callback diagnostic**, not a qualified automatic/manual-update test. Several of its captures were stale. A proper future update campaign must split mutations and reads, use an observation method whose evaluation effects are known, and compare cached versus explicitly updated output.

The exporter requests an explicit update, creates scene geometry through the vendor API, records model/class/matrix, then deletes only newly exported nodes. Matrix text has MAXScript's default precision. Multiset comparison permits export-order changes and duplicates; it does not expose native IDs. The explicit update timer excludes preceding parameter setters, queued work, redraw, serialization and deletion. Geometry conversion has its own timer.

## Chaos: artist-authored flat and curved layers

Use the same initialized public exporter/model fixtures. All interaction is in the owned Max window; re-observe panel layout after each host request.

1. Run `chaos_paint_setup.ms`. It creates `VP_Flat` (100 × 100 cm) and `VP_Curved` (radius 50 cm, 24 segments), with 400 Fixed Total instances, seed 42 and collisions disabled. Earlier owned fixtures are hidden.
2. In Clusters select **Paint with instances**. Edit the automatically created Base layer: move `VS_Box` from Available models to Cluster composition and accept. New creates Layer 1; edit it to contain only `VS_Sphere`. Require the interface to show one model in each layer. Run `chaos_paint_capture.ms` to define the layer-state exporter and capture `paint_before_strokes.tsv`: 400 boxes, 111 on the plane and 289 on the sphere.
3. Select Layer 1 explicitly, enable Paint (20 cm radius), and click the plane center. At the recorded 1898 × 1032 window/Top zoom, this was `(200,538)`. Stop Paint. Run `paint_capture_two.ms`: 13 sphere models on the flat receiver. Despite this file's exploratory label, its first click on the curved mesh did **not** create a curved stroke, and it is treated as the flat-only control.
4. Select Layer 1, enable Paint, and drag on the curved receiver from `(728,529)` to `(747,547)`. Stop Paint. Run `paint_capture_curved.ms`: still 400 positions, with 13 flat and 20 curved sphere-model assignments. Public layer state contains three points/two stroke records. Coordinates depend on viewport zoom; use the receiver's visible upper surface if the layout differs.
5. Send separate requests: `paint_remove_curved.ms`, `paint_capture_curved_removed.ms`, `paint_restore_curved.ms`, `paint_capture_curved_restored.ms`. Re-observe the window and acknowledge any topology warning in the disposable scene. The curved stroke's points/record are removed, leaving the flat stroke; restoring the receiver does not recover curved paint. The earlier `paint_capture_removed.ms`/`paint_capture_restored.ms` controls preceded the successful curved stroke and do not qualify this deletion finding.
6. New creates Layer 2 above Layer 1. Edit its composition to contain only `VS_Box`. Select it, enable Paint, and drag over the flat footprint from `(200,538)` to `(202,540)`; stop Paint. Run `paint_capture_overlap.ms`: all 400 boxes, 400 unique positions, no duplicate placement. Select Layer 2, enable Erase, repeat the same short drag and stop Erase. Run `paint_capture_erased.ms`: the 13 original flat sphere models return, with all 400 previous full model/transforms restored.
7. Run `analyze_paint.py --run ...`. It validates counts, receiver domains, curved model assignment, deletion, replacement and restoration. `save_fixture.ms` saves `host/vendor-fixture.max` only. That save is not a save/reopen qualification.

The painter assigns model membership over an existing population in this recipe; it is not Chaos's separate Edit Instances brush. Layer-exclusive receiver picking, receiver reordering with paint, folded/stacked meshes and full point/record field semantics remain unqualified. No private paint arrays were authored to manufacture strokes.

## Forest Lite: controlled flat painting

Use the vendor's normal interface in the **owned** Max window. No Pro-only option is enabled programmatically.

1. Run `forest_smoke.ms`. Assigning the first receiver displayed a modal information message: “Forest Lite is limited to use flat surfaces.” Close that information window normally. The setter then returns. Run `forest_inspect.ms`.
2. In Geometry, press the green plus once. This creates a correctly initialized Custom Object entry. In Areas, press Add Paint once. It creates a referenced Linear Shape. The built-in Surface Area stays off; its On control is disabled in this Lite fixture.
3. Run `forest_paint_setup.ms`: it assigns the custom box, sets Top view and zooms receiver one. Its initial zero-instance result is excluded.
4. Start the area's Paint tool and make two 100 mm brush footprints on receiver one. In the recorded 1898 × 1032 window, the drag from `(310,500)` to `(530,500)` produced two isolated footprints. These are repeatable area samples, **not a continuous-stroke latency test**. End the tool through its toggle.
5. Convert the first Paint area to a spline using Forest's normal conversion and acknowledge the reversible conversion in the disposable scene. Run `forest_constant.ms`: white Gradient distribution, 50 × 50 pixels per 100 × 100 cm, one model with weight 100. This produced 38 placements. The converted scene spline had two closed contours, 17 knots each. Convert back through Forest's UI.
6. Run `forest_capture.ms` to define the **corrected zero-based** tree exporter. The earlier one-based files and `forest-results.json` are invalid for complete transform comparisons. Use only `valid_*.txt` and `forest-results-corrected.json`.
7. Run `forest_surface_cases.ms`: add a distant flat receiver, remove it, remove every receiver, restore the first receiver. The first paint area retains 38 transforms throughout.
8. Run `forest_second_receiver.ms`. Add a second Paint area in the UI, start Paint, click receiver two's center, then stop. In the recorded zoom this was `(470,538)`. Run `forest_two_regions.ms`. Require 59 placements with both receivers, 38 after receiver two is removed, 59 after restoration, while the 38 original transforms remain.
9. Select the first Paint area and paint the same footprint on receiver two. This demonstrates one area being authored on multiple input nodes and overlaps the second area's coverage. Run `forest_overlap.ms`: 80 placements, 59 unique model/transforms, 21 duplicates; upper Exclude gives 38; restoring Include gives 80.
10. Run `analyze_forest.py --run ...`. It rejects invalid model IDs and compares model/transform multisets. For repeating the corrected campaign after the overlap probe, first erase the receiver-two footprint from area one, keep area two's footprint, and run `forest_corrected_cases.ms`; then repaint the overlap and rerun `forest_overlap.ms`.

Re-observe the owned window before every UI action; coordinates depend on panel layout and zoom. A scene save under the owned `host/` directory preserves the final artist-authored contours. No tablet pressure, fast-drag smoothness, curved receiver, save/reopen or Forest Pro runtime claim follows from these tests.

## Targeted binary reproduction

Use the existing `docs/ForestPack_Research_2026-10-08/reproduce/backend.py` and `export_selected.py`. Start a fresh loopback backend and copy the prior `ReceivingSurfaceCore` and `ChaosOwnership` projects into its own `projects/` directory. Do not open or mutate the original tyFlow projects. Opening a project does not load a program: call `load_program_from_project` with the binary's project path before exporting.

Question-selected addresses for the hash-pinned inputs:

| Program | Label | VA |
|---|---|---|
| Chaos core | `ILayerData::create` | `0x1800331e0` |
| Max adapter | layer-data parameter adapter | `0x180086a00` |
| Max adapter | stroke rearrangement; RTTI-supported name | `0x180097ce0` |

Write the selection JSON into the ignored run and pass it to `export_selected.py`. Detailed disassembly/decompiler output stays ignored. Review references and assembly alongside pseudocode: register/sret reconstruction and indirect Max SDK calls can be mistyped. The three decoded bodies were 380, 2,533 and 3,216 bytes respectively, with complete instruction-byte coverage inside Ghidra's selected function bounds. That is not a completeness percentage for the plugins.

## Final evidence and preservation

After the four analyzers complete, save/close the copied Ghidra project, and close only the PID/executable/private-profile-matched owned Max and backend. Record cleanup in the run's `cleanup.json`. Run `finalize.py --run ...` to hash the measured local artifacts, compare the original installed files and inspected product sources with the initial capture, and regenerate the research `EVIDENCE.json`. It rejects changed product/vendor hashes. Ignored raw exports, copied binaries, projects and scenes remain local; tracked deliverables contain research summaries and harness source.

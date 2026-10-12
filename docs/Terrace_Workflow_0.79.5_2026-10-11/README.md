# Terraced garden workflow — 0.79.5

**Later correction:** use the [creation-icon fix and corrected installers](CREATION_FIX.md) for the latest 0.79.5 script. The original package hashes and test receipts below remain historical evidence for their exact build.

11 October 2026. This batch fixes two demonstrated sources of repeated display work, qualifies the matched script/native pair in Max 2026 and 2027, and creates an editable terraced garden using the preserved pavilion plant library. This is development qualification, not 1.0 certification.

The active baseline was the dirty 0.79.2 source/script plus matching native modules. Git HEAD `15957a66de0480679dea6c533c7c5d09d9598d54` predates that baseline. Existing 0.79.2 work, licensing, website edits and artist originals were preserved. All Max work used disposable profiles and scripted host calls; no computer use, normal-profile installation or Git push was performed.

## What was wrong and what changed

**B19 — one layer's color edit prepared every layer again.** In the eight-layer garden, changing one source identification color increased preview-build counters on all eight layers. Each preview now stores its own display key, including publication epoch, owner, identification colors and display settings. A display refresh enters the shared evaluator once and stages only changed layers. All successor snapshots stage before any are installed; pending Manual settings remain unpublished.

**B20 — unchanged layer buffers were uploaded again.** The first CPU-only fix correctly prepared one layer, but still uploaded 56 streams / 304,055,484 bytes. Native display items now share ready SDK buffer/material handles for exact unchanged snapshot/group/style matches. Each item belongs to the new generation; old generation pointers are not repurposed. Failed or unrealized resources are not reused. Existing resource limits remain conservative.

**Recovery correction during the loop.** An intentionally malformed second layer preserved the old complete display, but the first draft left an error on an unchanged sibling after recovery. Successful staging now clears that status on reused siblings. The witness also confirms that recovery does not apply a pending Manual amount edit.

Changes are in the authoritative `unified-core.ms` template, generated script, `point_display.cpp` and `mesh_display.inc`. Version metadata is 0.79.5; schema remains 55. Analyzer remains 0.14 and MCP package/plan remain 0.73.0/0.73. The feature catalog's old eleven-section description was corrected to twelve.

## Measured comparison

The same saved scene, seed, camera, display settings and 7,461 accepted placements were used before and after. Mesh's existing face budget displayed the same **1,592** instances; this is not full-population Mesh timing. Twelve distinct source identification-color edits were measured sequentially in each host. Passive JSON collection is outside the timed action/redraw interval.

| Measurement | 0.79.2 baseline | 0.79.5 | Interpretation |
| --- | ---: | ---: | --- |
| Layers prepared for one local color edit | 8 | 1 | Unchanged CPU previews retained |
| Native streams uploaded per edit | 56 | 8 | Unchanged sibling buffers retained |
| Bytes uploaded per edit | 304,055,484 | 150,727,104 | 50.4% less; changed lavender remains heavy |
| Median color-edit action | 1,008.5 ms | 696.5 ms | 30.9% lower in this witness |
| Median action plus synchronous redraw | 1,502.5 ms | 1,075.8 ms | 28.4% lower |
| Median unchanged display refresh plus redraw | 1,166.7 ms | 1,074.9 ms | Still nontrivial synchronous host/display overhead |
| Uploads for unchanged refresh | 0 | 0 | No invented improvement where reuse already worked |
| Point navigation median, 40 frames | 30.2 ms | 26.4 ms | Zero preparation/publication/upload changes in either run |

Synchronous elapsed time is not presented FPS or physical input latency. Hosts were measured sequentially, but OS background activity and thermal state were not controlled. The navigation difference alone is not assigned to the new fix. Separate 26-controller navigation witnesses preserve all **18,759 points and 5,546 circles**, including exact radius-line coordinates/colors.

The smaller three-layer witness passes in both Max years: a local Mesh edit uploads four streams instead of twelve; a Point edit uploads one instead of three. Forty-eight edit/copy/remove/visibility cycles per host preserve all original placements and epochs, introduce no native fallback/error, and survive save/reopen. Sampled native reservations stay at 3,801,600 bytes for point/radius and 368,640 bytes for mesh. These conservative reservations and whole-process memory samples are not VRAM measurements or a long-session leak proof.

The empty-scene workflow records 30 steps: controller, panel mount, layer, receiver, Point, model replacement, second layer/removal, Mesh/Centres, Include/Exclude, curves, Paint/Erase, browsing and save. The final Max 2026 run records roughly 117–167 ms for its small Update actions. Its 6.5-second initial panel mount and 63-second aggregate browsing step include repeated fixture reselection/remounting and overlapped the other host's render. They are observations requiring an isolated UI profile, not certified panel-expansion latency or an alleged UI speed improvement.

A follow-up after the render finished separated full Modify mounting from ordinary warm section binding: one full mount took 5.38 seconds; 15 warm section binds had an 84.95 ms median and preserved the publication. The first-mount cost is now B21 for causal profiling. This is not a physical click latency measurement. The final 1600×900, 15-pass Corona frame took 510.2 seconds; its extra canopy geometry and changed population make it incomparable to the earlier five-pass draft.

## Tests and coverage

- [x] Frozen source/build identities and loaded module paths/hashes checked for each host.
- [x] Generated-source check, namespace/layout checks and **24 native tests per SDK**.
- [x] **158 Python tests**; catalog-only check repeated after the section-count correction.
- [x] **260 reused host assertions per year**: display ownership, Manual/Live, relevant/unrelated animation, layer lifecycle, saved examples, Point/model/Empty, falloff/radius and selected UI bounds.
- [x] Four layer Undo/Redo phases and four radius Undo/Redo phases per year; Point/model snapshots retain no reported errors.
- [x] Nine partial-reuse/failure-recovery assertions and 98 endurance assertions per year.
- [x] 24 point/radius navigation assertions per year.
- [x] 11 new end-to-end workflow assertions on the final Max 2026 pair.
- [x] Twelve garden relationship assertions in Max 2027: receiver relink, feather/cache reuse, copy isolation, Manual/Live, exact save/reopen.
- [x] All **285 presentation controls** in twelve main sections bind in Max 2027; browsing preserves publication. [All 241 semantic controls are inventoried](CONTROL_REGISTER.md).
- [x] Actual Corona draft and final render checks, exact scene reopen and clean render-bridge state; delivery receipts contain their results.
- [ ] Physical all-control/picker/graph/tablet/DPI walkthrough, device loss and long sessions remain open.

[Feature coverage](COVERAGE.md) states the precise witness for every C01–C34 capability, including untested, retired and out-of-scope items. No checkbox means that every combination of that feature was tested. Native algorithm tests do not substitute for a fresh artist Edit/Relax/cleanup workflow.

An initial reused Undo fixture failed because its required Point/model setup had not run. The runner was corrected to include that precondition; this was a test-fixture correction, not a product fix. Intermediate CPU-only results and the recovery failure remain in the ignored test profiles. Original fixtures were adapted into those profiles, with original/adapter hashes recorded, rather than overwritten.

## Scene and delivery

The reference's useful design structure is three curved planting terraces, limestone walls, a stepped path, lavender ribbons, golden grasses, pale flowers, shrubs and canopy trees. The new scene has **eight Scatter layers**, **three receiving surfaces**, **twelve painted areas**, all four assignment layouts, path exclusions, spline edging, separate falloff curves and layer spacing. The final saved population is **6,632 plants**. Point/Empty replacement and destructive layer tests use separate disposable witnesses rather than placeholder plants in the finished garden.

The real plant library supplies twelve used pavilion models; a lightweight authored ornamental-grass source supplements it. Myrtle-derived trees and columnar shrubs approximate the unavailable mature olive/cypress assets. The result is an editable interpretation and test scene, not a photorealistic match or certified material reconstruction.

- [Editable garden — Max 2027](../../Test%20Scene/Terraced_Garden_0795/Terraced_Garden_0795.max)
- [Actual Corona render](../../Test%20Scene/Terraced_Garden_0795/Terraced_Garden_0795.png)
- [Scene notes](../../Test%20Scene/Terraced_Garden_0795/README.md)
- [Scatter 0.79.5 for Max 2027](../../dist/refinement-0.79.5/CyrusScatter-0.79.5-Max2027.mzp), [receipt](package-2027.json)
- [Scatter 0.79.5 for Max 2026](../../dist/refinement-0.79.5/CyrusScatter-0.79.5-Max2026.mzp), [receipt](package-2026.json)

Scenes, images and installers above are ignored local artifacts, not supplied by a source-only Git clone. Use the package matching your Max year and restart to load matching scripts/native modules. Installation itself was not rerun. The garden scene was saved in Max 2027; Max 2026 was qualified with its separate examples and workflow fixtures. Existing Analyzer 0.14 modules were reused after source/SDK identity checks, not rebuilt or fully requalified in this batch. Team licensing remains unchanged.

Source assets were loaded from `Test Scene/Reference_Garden_075/Source_Plants.max`; the original file was not saved over. Geometry was rescaled before assigning centimeter system units. Changing the unit label alone does not rescale geometry: [Autodesk Units documentation](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Units/GUID-DB50F450-C3D1-47A5-98A2-A34601710034.html). The cross-unit Scatter issue B14 is not fixed by this scene preparation.

## Reproduction and next acceptance

The [compact evidence](evidence.json) records script/native hashes, loaded paths, assertions, upload samples and raw receipt locations. Final profiles are `build/mcp-qualification/refine0795-final-2026-01` and `...2027-01`; baseline is `...baseline-2027-01`. SDK candidates are under `build/refine0795-20261011/max2026-02` and `max2027-02`. The exact final script SHA-256 is `47ed50ed18aab79da76f511cc74b95a81f1d518fa9fd02b2fa647ec5eba3a100`.

Use `tools/refine0795/launch.py` with a fresh owned profile and matching frozen candidate. Run `regressions.py`, `navigation.py`, and the scripts through `request.py`, one mutation at a time per host. Run `workflow.py`, `reuse_checks.py` and `endurance.py` only in disposable scenes; they reset the host. Build the reference scene with `garden.py`, compare the exact saved baseline using `load_garden.py`/`benchmark.py`, then use the art passes. `final_scene.py` deliberately refuses an existing delivery directory. `package.py` gates packaging on source/native/loaded identity and passing host receipts. `summarize.py` regenerates the compact evidence and control register.

Next priorities remain physical picker reproduction B16, the explicit units contract B14, isolated cold/UI preparation profiling and changed-layer geometry/color upload separation. Historical B01/B05 observations are not closed by successful retries. Detailed acceptance lives in the single maintained [backlog](../BACKLOG.md); this report does not authorize additional unrelated work.

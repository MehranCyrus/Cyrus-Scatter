# Cyrus Scatter 0.7.1 — Garden Pavilion

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

**6 October follow-up:** the [runtime campaign](../Live_Runtime_2026-10-06/RESULTS.md) uses a separate copy and a newer pinned source/native pair to test stable IR, a real edit, production output and failure cleanup. It preserves this editable master. The delivery and historical failure notes below remain tied to their original builds; no artist-profile upgrade is implied.

<!-- CURRENT_SYSTEM_2026-10-05 -->

After delivery, the user reproduced repeated Corona IR refreshes while production rendering worked. See [updated findings](FINDINGS.md) and the [current system roadmap](../Current_System_2026-10-05/ROADMAP.md). The production images below are not IR qualification.

5 October 2026. An editable landscape and real-asset qualification scene, made from a copy of `Test Scene/Main Scene with 3D Model.max`.

The demonstration has a limestone and cedar pavilion, glazed frontage, terrace, reflecting pool, two roads, pedestrian crossing, lavender ribbons, a curved berm, and a meadow. A **1.4 m curved gravel walk** crosses the western meadow, with two independently painted flower borders. This is a development demonstration, not a publication-readiness certificate.

Finished Corona previews: [overview](../../Test%20Scene/Cyrus_071_Courtyard/01_Garden_Pavilion_Hero.png) and [walking-path detail](../../Test%20Scene/Cyrus_071_Courtyard/02_Garden_Walk_Detail.png). Both are actual renders of the saved procedural scene.

## Open the matching build

Run [`Open_Garden_Pavilion.cmd`](../../tools/real_scene_071/Open_Garden_Pavilion.cmd). It opens a **new working copy** of the scene in a separate Max 2027 profile, using the qualified 0.7.1 script and pinned native modules. It does not install into the normal Max profile. Loading the file directly into an older running DLL/script pair is not the tested route.

**Launcher follow-up, 5 October:** the test copy is now named `PREVIEW_0_7_1__Cyrus_071_Garden_Pavilion.max`, and the launcher requests the floating editor automatically after checking the loaded UI version. This distinguishes it from the original scene in an older installed Max session. The new launcher behavior has [offline validation only](../UI_0.7.1_2026-10-05/evidence/launcher-followup-offline.json); it does not change the pinned plugin build or establish a new Max runtime pass.

The editable master is [`Cyrus_071_Garden_Pavilion.max`](../../Test%20Scene/Cyrus_071_Courtyard/Cyrus_071_Garden_Pavilion.max). Keep the existing `Test Scene/maps` directory: the demonstration references those local textures and Corona proxies. Max 2027 and the installed Corona renderer are required for the supplied materials and final rendering. Use **Save As** to keep your changes to the working copy.

## Explore the scene

Select **CYRUS 0.7.1 | Courtyard - Edit layer**, then open **Modify > Layer Manager > Edit layer…**. Double-clicking a layer also opens its floating editor. Global receiving-surface, update, display and render settings stay in the command panel. The layer editor has Assets, Population, Paint, Transform, Spacing and Statistics tabs.

The camera list contains:

| Camera | Purpose |
|---|---|
| 01 HERO | Pavilion, roads and overall planting |
| 02 WALK | Curved meadow trail and the flower borders |
| 03 PLAN | Layout, includes/excludes and planting distribution |
| 04 SOURCES | The eight source rectangles off-site |

The default is **Manual**. Change a setting, then press **Update setup** in the layer editor or **Update now** in the modifier. Choose **Live** for immediate procedural updates; denser scenes have a noticeable calculation cost. Point Cloud is the default display. Mesh display has separate budgets and may show fewer plants than the exact render output.

The supplied previews use 1,200 × 840 pixels and an eight-pass render limit. The saved scene is set to 1,400 × 980 with a 24-pass limit for a longer render when desired.

## Paint and reshape the curved trail

1. Open **04 | Painted meadow walk**, then the **Paint** tab. Select **Outer edge | Phlox and Viola** or **Inner edge | Lamium and Geranium** in the paint-set selector.
2. Each border has a continuous Paint stroke with 69 samples, followed by an 81-sample Erase stroke that keeps the curved walking corridor clear. Expand **Paint feedback and editable stroke history** to select a stroke and edit its radius, strength, softness or enabled state. Changing a saved stroke affects the existing border; the upper Brush controls apply to the **next** stroke.
3. Choose Paint or Erase, set the radius, and press **Start Brush**. Drag on the receiving landscape, then press **Stop**. In Manual mode, press **Update setup** to publish the change. Undo/Redo works with authored strokes.
4. For the opening through the grass, select **05 | Meadow tapestry > Grass between flowering plants**. Its saved 81-sample **erase** stroke clears the trail. Clover, flower drifts and the other layers have their own erase strokes so they also respect the walking route.

The gravel mesh and the Brush fields are separate editable scene objects. Editing a Brush radius changes planting coverage; it does not reshape the gravel mesh. If you reshape the walk geometry, repaint the corresponding coverage. The trail was authored through the native Brush stroke API, not by baking individual plants or substituting an Area exclusion for the curved erase.

**Fill and Empty reset stroke history.** Undo restores the previous field. To retain a stroke while temporarily hiding its effect, disable it in the saved history instead.

## Try model containers

Use camera **04 SOURCES** and open a layer's **Assets** tab. Eight labeled rectangles hold the source models. The two new flower borders have separate source nodes that instance the supplied plant geometry.

Move a source model's **pivot** outside its assigned rectangle, then Update in Manual mode. Its registered source row is parked; its weight, scale, radius and identity remain. Move it back and Update to reactivate it. This is different from **Remove rows**, which unregisters the model. Container membership uses the rectangle's local XY bounds; it is not an intersection test against the model's entire mesh.

## What is planted

The final main scene contains **10,724 exact instances**, using 15 distinct supplied plant assets across 19 source-node groups. Five logical layers evaluate in this order:

| Layer / paint set | Published instances | Purpose |
|---|---:|---|
| 01 Structural shrubs | 52 | Myrtle, rose and elder structure |
| 02 Flowering perennials | 46 | Painted Arthropodium drifts, including the curved berm |
| 03 Lavender ribbons | 53 | Three Corona proxy sources inside two Area ribbons |
| 04 Painted meadow walk — outer | 132 | Phlox and Viola along one side of the S-curve |
| 04 Painted meadow walk — inner | 229 | Lamium and Geranium along the other side |
| 05 Meadow tapestry — flower drifts | 200 | Four flower types in painted coverage |
| 05 Meadow tapestry — clover | 1,320 | Outside referenced flower coverage |
| 05 Meadow tapestry — grass | 8,692 | Between accepted flowering plants, with trail erased |

Target-count layers can underfill when eligibility, spacing, cleanup or bounded retries reject candidates. Candidate-budget layers also publish fewer instances than their requested budget. Neither number should be presented as a guaranteed accepted count.

## Other option examples

The following saved variants demonstrate combinations that do not all belong in the main landscape. They were made before the curved-walk addition. Open them with the same launcher, for example:

```powershell
python tools/real_scene_071/open_scene.py --scene Variant_Protected_Edits_Radii.max
```

| Variant | Demonstration |
|---|---|
| Variant_Clusters_Density_Transforms.max | Source-color clusters, density endpoints, plants/m², XYZ variation and projected movement |
| Variant_Protected_Edits_Radii.max | CS Edit moves/clones, protected instances and selected-instance radii |
| Variant_Global_Containers_and_Radii.max | Global/inherited source rectangles, source scale/radius behavior and Point/Empty cases |
| Variant_Analyzer_Boundary.max | Analyzer Area and boundary assignment on a flat receiver |
| Variant_Line_Pattern.max | Existing-policy Line Pattern assignment |

The last three select an **OPTION LAB** controller; the main landscape controller is disabled in those variants. Analyzer and Line assignment retain their supported policy. The Analyzer currently requires planar surfaces.

See [RESULTS.md](RESULTS.md) for test scope and [FINDINGS.md](FINDINGS.md) for follow-up issues. One UI issue remains in this build: a redraw can show **Pending** even when the published calculation is current. The geometric and persistence tests passed independently of that label. Compact receipts are under [evidence](evidence/). The original artist scene and normal profile were preserved.

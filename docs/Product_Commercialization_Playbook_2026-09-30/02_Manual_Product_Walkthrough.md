# Stage 02 — Manual product walkthrough

## Goal

Use Cyrus as a new artist and leave a reproducible record of what works, fails, or remains unclear. Split this into five short sessions. A complete record is the output; every feature does not have to pass yet.

## Why this matters

Your own observations reveal usability and integration problems that mathematical tests cannot establish. They also create the first honest presentation material.

## What we currently know

**VERIFIED IN SOURCE:** the captions below are taken from the generated Scatter script, Analyzer script, and native edit modifier. Dynamic Edge Border captions come from the UI update functions. **REQUIRES MANUAL 3DS MAX TEST:** the interactive result of every MT test below.

Reference: [installation guide](../Max_2027_Installation.md), [current scene/edit contracts](../Product_Strategy_2026-09-29/05_Architecture_and_Scene_Contracts.md), and [source anchors](98_Repository_Review_and_Deliverables.md).

## My tasks

- [ ] Record the environment from Stage 01.
- [ ] Use new scenes/copies with built-in primitives and your own simple materials.
- [ ] Complete Session A before advanced rules, editing or heavy tests.
- [ ] Change one feature at a time; preserve a working baseline scene.
- [ ] Record all selected tests in the result table.
- [ ] Capture the exact error/action when you cannot proceed.

## Engineering / Codex tasks

- [ ] Help reproduce BROKEN/PARTIAL/UNCLEAR cases using the exact scene/build.
- [ ] Supply disposable legacy, fault, edit-stack and bake fixtures where UI alone cannot exercise a risk.
- [ ] Confirm clone/selection and coordinate-system behavior in the host if a standard Max action is unavailable.
- [ ] Provide a tested Analyzer removal/rollback procedure before uninstall testing.

## Boss / Product-owner decisions

No pricing or license approval is needed for these internal tests. Record your renderer availability. The intended beta/release renderer scope is chosen later; absence of a renderer does not prove incompatibility.

## Step-by-step procedure

### Session A — Install, create, save and reopen

**MT01 — Scatter installation.** Save any active work. In Max 2027 run **Scripting > Run Script** → [CyrusScatter-0.59-Max2027.mzp](../../dist/CyrusScatter-0.59-Max2027.mzp). Restart Max. Expected: no startup/plugin error and **Create > Geometry > Cyrus > Cyrus Scatter** appears. If already installed, record “previously installed; clean install not retested,” and defer clean-profile qualification to Stage 07.

**MT02 — Analyzer installation.** Run [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../../dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp), restart, and check **Cyrus > Surface Analyzer**. If already installed, record that and leave clean-profile installation pending. Use the MZPs; loose source installers still target 2026.

**MT03 — Surface/controller.** Create a new scene. Record System Units; type physical unit suffixes in dimensions. Make a **Plane 10 m × 10 m** and a **Box 0.15 m × 0.15 m × 0.5 m**, with the box outside the plane. Create **Cyrus Scatter** by clicking/dragging, select it, open Modify, then **Surface Scatter > Add: pick surface** → plane. Expected: controller and surface reference exist.

**MT04 — First source/preview.** **Layer Manager > Add Layer**. In that layer's **Source Object > Add: pick in viewport** pick the box. **Point Generation > Method: Random; Population: Count; Count: 200; Seed: 42**. **Viewport and Render > Show preview; Display mode: Proxy; Proxy shape: Box**. Click **Update now** or **Refresh preview**. Expected: populated plane and usable status. Save as your MT04 baseline; screenshot the controller, source and visible result.

**MT05 — Count and repeatability.** Change Count to 500, refresh, then back to 200. Change Seed to 43, then back to 42. Expected: count responds and the unchanged-input Seed 42 arrangement returns. With no masks/collision, a requested 200 should produce 200; preview budgets can show fewer in other setups.

**MT27 — First save/reopen.** Save a separate MT27 file; close/reopen it in the same Max/build. Refresh if required by Manual mode. Expected: references/settings/result preserved. Repeat this test again after editing in Session C; an unedited pass does not prove edited persistence.

### Session B — Rules, variation and layers

Reset to the MT04 baseline between unrelated tests.

| Test | Exact action | Expected observation / important limit |
|---|---|---|
| MT06 — Density population | Point Generation → **Population: Plants per m2**, **Per m2: 2** on the 100 m² plane | About 200 requested before constraints; record requested/emitted values and actual scene area. Restore Count afterward |
| MT07 — Texture Density | **Method: Texture Density**, **Choose density map** → a black/white Checker map; refresh; toggle **Invert density** | Pattern follows UV channel 1; inversion changes permitted regions. Current sampling is 128×128; a blank map produces an actionable error. Record map/UV setup |
| MT08 — Random scale | **Randomize XYZ**, Scale X/Y/Z minimum 0.8, maximum 1.2. Restore axes to 1, then separately test **Whole Scale (uniform)** Min 0.8/Max 1.2. Finally select the source row and test **Source Object > Scale** at 0.5 | Axis, uniform and per-source controls give their intended distinct effects; compare base positions and restore defaults before editing |
| MT09 — Random rotation | Randomize XYZ, Rotation X/Y 0–0, Z 0–90 degrees | Upright boxes vary around Z; do not confuse local/source orientation with world rotation |
| MT10 — Movement/normal | Randomize XYZ, set small Move Z variation; compare **Keep on surface** on/off; use a copied tilted plane with **Align to normal**. Separately select the source row and test **Z Offset** at 0.1 m, then restore 0 | Projection/normal/source-offset choices give distinct transform results. Record transform/units and later offsets. Legacy/basic-axis branch needs an engineering fixture, not a hidden UI switch |
| MT11 — Include/exclude | Draw two closed Rectangles in the plane. **Area > Add: pick closed line**; set first **Selected area mode: Include**, inner rectangle **Exclude**; refresh | Generated pivots obey permitted world-XY regions. This does not trim every source mesh element |
| MT12 — Falloff | Analyze the plane via MT28. In Area choose **Edge falloff target: Analyzer Boundary**, **Pick Surface Analyzer**. Test **Delete edge band** at 0.5 m, then **Scale ramp** at 1 m, then **Density ramp** at 1 m, one at a time | Deletion/ramping affects the existing population. Use **Edit Scale Graph... / Edit Density Graph...** and record whether the editor works. Later edits/offsets can move results beyond earlier rules |
| MT13 — Collision | **Collision / Relax > Enable collision**, choose a modest radius such as 0.3 m | Reduced overlap under the configured center/radius rule; count can fall. Arbitrary mesh-to-mesh clearance is not promised |
| MT14 — Relax | Separately enable **Enable relax**, **Spacing: 0.4 m**, **Iterations: 5**, **Strength %: 50** | Placements respond while respecting exercised constraints; collect before/after. Do not assume perfect packing |
| MT15 — Multiple layers/source assignment | Add a second layer with a small Sphere source; rename through **Name:**; toggle each layer's list checkbox. Back in the first layer add the Sphere as a second source; select each source row to set distinct **Color:** and **Weight** values (Box 0.75, Sphere 0.25). Compare **Diversity / Colors > Source assignment: Random** with **Clusters**, **Size: 2 m**, **Roughness %: 20**; restore Random afterward | Two layers remain independent. Source weighting affects mixture, not an exact guaranteed ratio. Clusters changes source assignment without deliberately relocating base pivots; preview group color is not a renderer material. Current ceiling is ten |
| MT16 — Cross-layer clearance | In the second layer use **Layer Manager > Remove Overlaps > Enable**, select the first in **Blocking layers (Ctrl/Shift)**; test **Fixed Radius** and **Source Radius** separately | Second layer avoids configured blockers; record **Refresh counts** and Before/Removed/Left. Do not assume symmetric interaction |
| MT17 — Preview/budgets | Viewport and Render → **Point Cloud**, **Proxy** Box/Sphere/Pyramid, **Mesh**. Lower **Point limit**, **Instances/layer**, **Faces/layer** independently | Display responds; final requested population is separate. Mesh preview uses simplified shading, not a material preview promise |
| MT18 — Update modes | Update → **Viewport update: Manual**, change Count without refresh, then **Update now**. Repeat in **Real-time** | Manual changes become visible on refresh; Real-time updates after event coalescing. Record delay and errors |
| MT35 — Failure/recovery | Save a copy, remove the source or choose an invalid input; observe status; undo/replace and refresh | Failure is understandable and recovery restores the result. Current preview rebuild clears the old cache on error; last-valid retention is proposed |

### Session C — CS Edit and persistence

Use a clean, modest scatter with about 20 instances and fixed Seed/rules. Keep a saved original.

| Test | Action | Expected observation |
|---|---|---|
| MT19 — Add/select | On the scatter controller add **Cyrus Scatter Edit** from the Modifier List. Expand/select its **Instances** subobject level; select one displayed instance | Status identifies selection and the intended instance responds |
| MT20 — Move | Standard Max Move tool: move selected instance by a small, recorded distance | Other instances remain unchanged; manual motion can override prior placement rules |
| MT21 — Rotate | Standard Rotate tool: rotate selected instance 30 degrees | Selected instance rotates; no accidental controller/source transform |
| MT22 — Scale | Standard Scale tool: scale selected instance visibly | Selected instance changes; record uniform/nonuniform tool used |
| MT23 — Clone | Try Max's subobject clone action, commonly Shift+Move, on one selected instance | A copy with its own edit behavior appears. If this custom modifier does not expose that gesture in your host, record UNCLEAR and ask engineering to exercise its implemented clone callback; there is no documented custom Clone button |
| MT24 — Delete | Select an instance in Instances mode; press Delete | Selected instance disappears; controller/source remain |
| MT25 — Undo/redo | Undo and redo each move/rotate/scale/clone/delete action one at a time | Correct instance/count/state restored; record any selection difference separately |
| MT26 — Stack/invalidation | On a copy add a second edit modifier, edit a lower-created copy, toggle lower modifier, then restore. Separately change base Seed on a saved copy | Suspension/restoration is understandable. Seed/base-layout changes can require Reset Edits; edits are not guaranteed to remap through arbitrary generation changes |
| MT27 — Edited save/reopen | Save after nonempty edits; reopen with same build; compare count/positions/status and lower-modifier toggle | Edited state survives, including intended suspended records. Save pre-edit and edited versions |

Do not use **Reset Edits** to dismiss an unexplained status: it clears records. Current source retains legacy readers, but an old guide's validation prose is not a new 2027 migration test. Ask engineering for an actual historical scene before advertising legacy recovery.

### Session D — Analyzer, edges and export

**MT28 — Analyzer.** Create **Surface Analyzer**. **Surface Analysis > Pick Surface** → the simple plane. Set **Path method: Auto**, **Fit radius: 0.5 m**, **Point radius: 1 m**, **Min points: 0**, **Resolution: 128**, **Relax steps: 0**; click **Analyze / Update**. In **Viewport and Output** enable **Boundary**, **Center paths**, **Sample points**. Expected: nonempty meaningful boundary/path/point data when the region fits; status explains an empty result. Repeat on an open planar L-shaped or holed surface only after the simple case works. A closed Box is an invalid Analyzer surface.

**MT29 — Street/boundary rows.** Draw a line beside a copied planar strip. Analyzer **Street Side > Pick Street Line**, **Analyze / Update**, **Show Street Side**. In Scatter **Diversity / Colors > Source assignment: Analyze Surface**, **Pick Surface Analyzer**, then **Analyzer data: Edge Border** → **Add Edge Row**. Select the row, set **Assign by: Source objects**, select the intended source in its list, and set the dynamic **Spacing** control to 2 m. Test **Face outward**, source **Forward axis**, **Offset inward**, **Keep corner points**, and **Local X/Y/Z (deg)** independently. Expected: a coherent ordered boundary row. Change Analyzer data to **Street Side** on a separate copy and test **Add Stroke Inside**, **Straight ends (Street Side)** and **Trim start/end**. Record disabled controls or empty source choices. Offset follows final orientation and can move objects outside prior constraints.

**MT30 — Analyzer output.** On the Analyzer use **Create Boundary Spline**, **Create Path Spline**, **Create Point Helpers**, and, with valid Street Side data, **Create Street Side Spline**. Expected: ordinary scene objects at matching positions; undo removes only the created output. These are snapshots. Record count/names and save before/after.

**MT31 — Scatter bake/export.** Current source has a **bakeInstances** function, but the generated UI has no Bake creation button. Record that discoverability gap as UNCLEAR/PARTIAL. Have engineering perform a small, guided bake in a scene copy and verify count/transforms, undo, owner cleanup, and duplicate-render avoidance. **Remove old baked output** is a cleanup control, not the bake command. There is no implemented USD export established here.

### Session E — Render, scale and recovery

**MT32 — Final render.** Name your actual renderer/build; use a clean 200-box scene and a simple material/light/camera. Enable **Automatic final render**. Render, compare population/transforms/materials, cancel once, render again, save and reopen. Expected: correct result, restored flags and no persistent disposable PFlow nodes or duplicated population. Record image and log. A successful viewport is insufficient evidence.

**MT33 — Interactive render.** Start the renderer's normal interactive session. Change Count, source transform and one edit; stop/restart IR; save a copy. Expected: correct updates and clean restoration. Source has Corona-specific start/stop handling; V-Ray or other IR remains a separate test. If unavailable, use NOT TESTED with the missing renderer/build.

**MT34 — Heavy behavior.** Start with 1k, then 10k, then 100k requested simple instances in Point Cloud with fixed point budget. Record emitted/displayed counts, update wait, navigation usability and Max memory. Save before increases; stop at a recorded unacceptable freeze/resource level. Test heavier source geometry separately and modestly. These observations are usability evidence, not a comparative benchmark or a “millions” claim.

**MT36 — Uninstall/rollback.** After preserving scenes and completing other tests, arrange a disposable Max profile or engineering-assisted session. Use the installed Scatter **Uninstall.ms** with its restart procedure. Analyzer currently lacks a dedicated uninstaller; engineering must supply a reviewed/tested removal procedure. Verify package reinstall and saved-scene recovery. Do not improvise deletion of plugin directories or test removal in the middle of an active production job.

## Evidence to collect

For every selected test save the smallest scene, screenshot/video, error text and this card:

~~~text
Test ID / date / operator:
Max full version / renderer build / package identity:
Scene / units / seed / sources / requested-emitted-displayed counts:
Actions:
Expected:
Actual:
Result:
Screenshot / video / scene / log paths:
Issue / next action:
~~~

## Status table

Use WORKS / PARTIAL / BROKEN / NOT TESTED / NOT APPLICABLE / UNCLEAR. Fill Notes with a reason; put actual evidence paths in the last column.

| Test | Status | Notes / screenshot or evidence path |
|---|---|---|
| MT01 Scatter install | NOT TESTED | — |
| MT02 Analyzer install | NOT TESTED | — |
| MT03 Surface/controller | NOT TESTED | — |
| MT04 Source/first scatter | NOT TESTED | — |
| MT05 Count/seed | NOT TESTED | — |
| MT06 Density population | NOT TESTED | — |
| MT07 Texture Density | NOT TESTED | — |
| MT08 Random scale | NOT TESTED | — |
| MT09 Random rotation | NOT TESTED | — |
| MT10 Movement/normal | NOT TESTED | — |
| MT11 Include/exclude | NOT TESTED | — |
| MT12 Falloff/graphs | NOT TESTED | — |
| MT13 Collision | NOT TESTED | — |
| MT14 Relax | NOT TESTED | — |
| MT15 Layers | NOT TESTED | — |
| MT16 Cross-layer clearance | NOT TESTED | — |
| MT17 Preview/budgets | NOT TESTED | — |
| MT18 Update modes | NOT TESTED | — |
| MT19 Edit selection | NOT TESTED | — |
| MT20 Move | NOT TESTED | — |
| MT21 Rotate | NOT TESTED | — |
| MT22 Scale | NOT TESTED | — |
| MT23 Clone | NOT TESTED | — |
| MT24 Delete | NOT TESTED | — |
| MT25 Undo/redo | NOT TESTED | — |
| MT26 Stack/invalidation | NOT TESTED | — |
| MT27 Save/reopen: unedited and edited | NOT TESTED | — |
| MT28 Analyzer | NOT TESTED | — |
| MT29 Street/Edge Border | NOT TESTED | — |
| MT30 Analyzer exports | NOT TESTED | — |
| MT31 Bake/export | NOT TESTED | — |
| MT32 Final render/lifecycle | NOT TESTED | — |
| MT33 IR | NOT TESTED | — |
| MT34 Heavy behavior | NOT TESTED | — |
| MT35 Failure/recovery | NOT TESTED | — |
| MT36 Uninstall/rollback | NOT TESTED | — |

## Completion criteria

Session A has actual results and saved evidence. Every other selected test is recorded or explicitly deferred with an owner/reason. Transfer failures and unclear controls to Stage 04; no result silently becomes a compatibility claim.

## Do not do yet

Do not inject faults into a working Max session, reset unexplained saved edits, use copyrighted demo assets, or publish timing claims from these quick observations.

## Optional / later

Group/hierarchy, animated/deforming sources, proxies, motion blur, alternate hosts and farms receive scoped fixtures in Stage 07. They need not prevent an initial internal walkthrough.

## Next stage

[Stage 03 — Product feature inventory](03_Product_Feature_Inventory.md).


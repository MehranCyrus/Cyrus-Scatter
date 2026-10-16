# 0.85.1 artist testing checklist

Use either installer in the [0.85.1 handoff](DELIVERY_0851.md). Exact evidence and remaining acceptance limits are recorded there; failed predecessors remain in [PROGRESS_0851.md](PROGRESS_0851.md). Tests use Max 2027; physical input, actual monitor transitions and your production renderer need your own acceptance.

## Install and find the examples

Save your work. Run the complete Max 2027 `.mzp` through **Scripting > Run Script**, then restart Max 2027. Alternatively, use the companion Windows EXE with an initialized Max 2027 profile, then restart Max. Choose one installation route. Never load only the loose MAXScript over an older native module. The EXE is unsigned and uses Windows .NET Framework 4.8. Neither installer restarts Max.

Create/select a Cyrus Scatter controller and open **Layers > Recipes**. Select **Bundled examples**. Collection tiles should lead to eight recipes across the collections; **All recipes** shows them together. The installed `Library-0.85.1` sits inside the versioned release under your Max user scripts. Its inventory and README identify matching editable `.max` scenes. Open a copy of a matching scene to inspect the settings and model bindings.

## Browse and author

1. Resize the gallery, switch thumbnail/list view, change tile size and search. Open a collection and return to All recipes. Scattering should stay unchanged. Check labels, menus and scrolling at your actual Windows scale and on each monitor you use.
2. Open Load Review, then change the gallery selection. The open review must retain its original recipe and controller. Canceling review must leave the scene alone.
3. In the painted-border example, use Save Recipe to save all layers into My recipes. Include the named Paint Areas and inspect their holes and fading after loading into a new setup. Use the matching terrain; an unrelated mountain is not automatically compatible Paint.
4. Capture a preview explicitly. Make a pending Manual edit and try saving it with the earlier preview. The dialog must require a valid capture choice, rather than label old plants as the new result. Explicit Update-and-capture should update only when requested.
5. Update that saved recipe, then Save Copy. Update should preserve the recipe identity and advance its revision; the copy is a separate item. Edit details should change its collection/name/tags without changing the scene.
6. With Saved variation and matching bindings, load a New setup and compare it with the original. Undo/Redo should remove/restore the whole import. Add layers should retain the target controller's update/display settings.
7. Apply a style to one layer, choosing only Amount or Transforms. Confirm that its receiving surfaces, models and Paint remain. Apply the same effective values again: it should not create another change or calculate plants. Test Undo/Redo for a real change.

## Share content and check daily use

8. Export a portable package from permitted static meshes, supported Standard/Blinn materials and PNG maps. Read the review's external terrain/path roles. Open it from a copied folder in another test scene and bind those roles.
9. Test independent source import, then explicit reuse of existing scene models/materials. Undo/Redo should preserve existing scene assets and their other users. Imported texture files belong to the persistent imported-asset store, so keep that store with scenes that need them.
10. Save/reopen the resulting scene. Compare Paint, model/material/map relationships and placements. Test your intended renderer separately; the automated material/pixel witness covers Scanline/Standard only.
11. Switch among example scenes several times, then continue working. Closed/departed scenes should release their calculation caches. If an operation reports insufficient MAXScript working memory, preserve the scene and note the error and steps; the guard retains the previous complete result and Undo instead of forcing the operation.
12. Leave a settled setup in Live, then in Manual with a pending edit. Browsing or opening panels should not apply the pending edit. Test a real relevant parameter change, Undo/Redo and Update afterward.

## Supported boundaries

This version does not add XRefs, nested populations, material-variant browsing, arbitrary renderer proxy/shader import, general recipe blending or automatic Paint transfer to unrelated terrain. Complete recipes reject unsupported authored Edit/per-instance radius records and controllers instead of silently dropping them. PG10's Edit/effect adapters depend on separate I13/I14 work; expressions remain dependent on I18. No additional Phase 6 work is started by this library delivery.

The original six examples keep their source data. Four garden rooms adds three painted layers; Valley moss and rocky crests uses authored channel 2 data, density/scale/orientation and slope controls. Its stored field does not represent a new automatic curvature engine.

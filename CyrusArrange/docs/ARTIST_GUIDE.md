# Cyrus Arrange geometry inspector guide

For the 0.3.2 development placement workflow, use the [geometry guide](GEOMETRY_USER_WORKFLOW_0.3.2.md). This page documents the separate inspector and earlier arrangement links.

For accessory registration, bulk selection, reusable decor groups and saved arrangements, start with the [simple workflow](SIMPLE_WORKFLOW.md). The [Modify guide](MODIFY_PANEL.md) covers the 0.3.1 scene controls, and [current acceptance](REAL_WORLD_0.3.1.md) records their status. The [0.3.0 workflow decisions](WORKFLOW_IMPROVEMENTS_0.3.0.md) retain that prior release's scope and evidence.

This guide covers the separate **geometry inspector panel**, introduced in the historical 0.1.0 milestone and retained in the current plugin. It measures sampled horizontal support areas. The inspector panel does not select or place accessories; the arrangement panel provides that workflow. Existing Cyrus Scatter and Surface Analyzer tools are separate products. The preserved [0.1.0 qualification](QUALIFICATION.md) describes that original inspector-only delivery, not the scope of the current arrangement plugin.

## Inspect furniture

1. Load the matched Cyrus Arrange Max 2027 native plugin and run `scripts/CyrusArrange.ms`. The installer supplies both. `caShowUI()` opens the inspector again.
2. Select the furniture parts or their group, then press **Use current selection / group**. Only that assembly is analyzed; include relevant obstructions in the selection. Native code expands groups and excludes Arrange overlays.
3. Choose the **TV console** or **Open shelf** label. This is a session UI label for this inspector, not automatic recognition or saved category metadata.
4. Set **Sample spacing**, **Minimum free height** and **Maximum support slope**. Distances are millimetres regardless of display units. Smaller spacing captures smaller details and increases calculation work.
5. Press **Inspect geometry**. The summary displays the assembly's world X/Y/Z dimensions in millimetres. These axis-aligned extents differ from local furniture width/depth when it is rotated. The region list reports support height, sampled usable area and overhead clearance. Select a row for its summary. **Open above** means no overhead hit was found in the captured assembly.

Calculation is explicit. Selection, opening the panel and reading a region do not recalculate furniture. Reopening the panel reads the existing native snapshot and its capture settings; choose the source selection again before a new inspection. After editing source geometry, transforms, scene time or scene units, press Inspect again. A failed inspection keeps the last complete native snapshot and region list; read the retained error before relying on the displayed result.

## Overlay and export

**Create sampled-area overlay** adds a regular scene mesh showing usable sample cells. It changes no furniture. Creation and **Delete owned / selected Arrange overlays** support ordinary Undo and Redo. Deletion affects only nodes tagged `CyrusArrangeGenerated=true`; select a previously saved tagged overlay to delete it after reopening a scene. Up to 64 created overlay references are retained by the panel at once.

The overlay describes the last captured snapshot. It does not update automatically and may extend around a support boundary by the sampling cell approximation. It is not a certified collision or accessory fitting surface. Saved overlays remain ordinary scene meshes without the plugin.

**Export captured snapshot JSON** writes native summaries and sample data. Export uses the existing capture and does not inspect again. Exported coordinates and distances are millimetres. The inspector's captured snapshot is session-only; scene saving preserves furniture and overlays, not a procedural inspection controller. Saved arrangement setups use their separate native document. On reopen, choose the assembly and inspect again.

**Clear captured snapshot** releases the inspector snapshot. Existing scene overlays are separate and remain until deleted or undone. This action does not clear saved arrangement setups or their transient geometry/query cache.

## Practical limits

The inspector performs sampled geometry analysis. Reported area is not exact polygon area. Thin shelves, gaps, small holes, bevels and sloping geometry depend on the spacing and slope settings. An inspector support region is not proof that an accessory fits or stands stably. This panel does not infer enclosed cabinets, door and drawer access, materials, object categories or aesthetic arrangements. Unselected scene geometry does not block its result. The arrangement workflow separately validates accessory support and conservative collision bounds using its authored categories and explicit obstacle scope.

Native work has explicit triangle, sample, region and effort limits. If the settings or geometry exceed them, use a smaller assembly or larger spacing and inspect again. Source nodes are preserved on success and failure.

## Automated fixtures

The ready-to-open [demo scene](../examples/CyrusArrange-Inspector-Demo.max) contains a console, open shelf and native-generated sample overlays. Choose its **Arrange demo | overview** camera to see the [rendered view](images/inspector-demo.png). The mint cells show sampled support. Overlays are made renderable only in this illustrative scene; ordinary inspector output is non-renderable by default.

The private Max 2027 tests build original procedural furniture with millimetre dimensions. They must run only in the dedicated disposable host described by the runner. `tests/max/inspect_tests.ms` resets that private scene, invokes the same rollout methods as the buttons, writes `result.txt` and exports JSON plus a fixture `.max` file under its assigned output directory. It never resets the scene from an artist-facing UI action.

# Cyrus Arrange troubleshooting

For 0.3.2 development placement feedback, see [When copies remain unplaced](GEOMETRY_USER_WORKFLOW_0.3.2.md#when-copies-remain-unplaced). This page retains 0.1.3 troubleshooting and its earlier controls.

This guide describes **Cyrus Arrange 0.1.3 for Max 2027**. Use native modules and UI from one matched package. The [release report](RELEASE_VALIDATION_0.1.3.md) identifies the exact tested pair, practical examples and separate installer/startup evidence; a result for another package does not qualify the installed one. Historical 0.1.2 packages and receipts remain preserved.

Start with a working copy of the scene. Select the setup helper and press **Use selected setup**, then read the complete **Status** message. A failed generation retains the previous complete result. Opening a panel, **Refresh setup view**, or **Refresh cached list** reads saved information; it does not inspect furniture or generate a successor. The [quick start](ARRANGE_QUICKSTART.md) describes the normal workflow.

## Nothing appears, or fewer objects appear than requested

1. Confirm that this is the intended setup and that **Asset Library** contains accessories. An empty catalog cannot supply objects. Generated outputs are not valid accessory sources.
2. Check **Density** and **Empty space**. A low density, high empty-space target or restrictive rules can legitimately request few or no props. **Generate**, **Preview bounds** and **Commit preview** report readable **Accepted … of … requested**, **kept**, **underfilled**, and the first warning when present. Preview reports its pending solve while retaining the committed objects; Commit reports its current recomputation. The displayed counts omit the technical Integer64 `L` suffix. The matching workflow regression checks these actual controls, including a real underfilled result, retained nodes and full-size committed contact; see the [release evidence](RELEASE_VALIDATION_0.1.3.md).
3. In **Asset Library**, check the accessory's **Category**, **Allowed furniture**, **Min scale**, **Max scale** and **Yaw angles**. In **Allowed-category rules**, a maximum of zero disables that category. Asset eligibility, setup category rules and surface rules all apply together.
4. Open **Surface rules...**, press **Analyze furniture**, and select an intended surface. Check **Exclude this region**, allowed categories and **Density multiplier**. A zero multiplier suppresses new placement there. Clear **Region IDs** in the main panel when you intend to regenerate all surfaces; a populated field restricts the command to those IDs.
5. Compare the full physical accessory dimensions with the usable shelf depth, width and overhead clearance. **Spacing (mm)**, **Edge gap (mm)**, obstacles, protected objects and conservative accessory bounds can prevent otherwise plausible positions. Reduce spacing or edge gap only when the new spacing is actually acceptable to you. Keep real-size assets at scale1 when required.
6. In **Collision scope...**, review the actual obstacle rows and the surface's front direction. **Require a clear horizontal approach** can reject a shelf placement that lacks an insertion path. Change that setting only when horizontal access is not part of the intended requirement; disabling it does not disable ordinary collision checks. Press **Apply approach setting** after changing the checkbox.

An underfilled result can be valid: the bounded search does not promise that every requested prop fits or that every mathematically possible arrangement will be found. Increasing density does not create shelf depth or overhead space. If support detection misses a small feature, inspect it at a suitable **Sample grid (mm)**; finer grids increase work and can reach admission limits. Split large furniture into sensible setups or simplify a source copy when a command reports a geometry/work limit.

For missing book rows, verify the explicit **Upright book row profile...**, a compatible spine side/front/yaw, enough eligible individual books and enough population slots. Ordinary props may still appear when a complete row cannot fit. See [book rows](BOOK_ROWS.md).

## An object has the wrong physical size or faces the wrong way

1. Read its captured dimensions in **Asset Library** and compare them with a known real dimension. Controls use millimetres regardless of Max display units. The inspector reports world-axis bounds, so rotating furniture changes those extents without resizing the model.
2. Set **Min scale** and **Max scale** to **1** to preserve the captured size. **Scale variation** only varies uniform scale inside those limits; it does not create different source models or change height independently.
3. Prepare the source upright on its intended base before registration. Capture includes the evaluated source's world orientation, then places its base-bounds centre at the asset origin. Its captured axes are not necessarily the source pivot's local axes.
4. Set the intended **Yaw angles**. After deliberately changing source geometry or orientation, use **Refresh source assets**, recheck the captured dimensions/support metadata, and Generate. For a replacement source, use **Rebind to selected model** instead of adding an accidental second catalog entry.
5. For a Book row, recheck **Spine side in the captured asset frame** after source rotation. Refresh does not recognize the spine or automatically reinterpret its saved tag. Match the row profile and allowed yaws to **Front direction in world XY (deg)** in Surface rules; the panel's hint is **0 = +X, 90 = +Y**.

If the imported source itself is the wrong size or orientation, correct and verify that source in a working copy before refreshing/rebinding. Changing a display-unit label is not an asset-scale control. Upright placement does not simulate gravity, settle tilted objects or correct arbitrary imported orientation automatically. See [source frames and support metadata](ASSET_LIBRARY.md).

## An excluded area still has part of an accessory over it

**Exclude this region** blocks new placement anchors there. An accessory anchored on a permitted surface can extend onto a touching, coplanar excluded surface while remaining supported. Exclusion is not full-footprint clipping.

To keep a physical area clear:

1. Create a suitable blocker volume rising above the surface in your working scene.
2. Open **Collision scope...**, select the blocker and press **Add selected**.
3. Check the saved obstacle rows, then Preview or Generate. Obstacles block placement and never supply support.

An excluded label, a flat outline, or an unbound room object is not an equivalent blocker. Bind a TV or existing decor explicitly when it must block placement. Keep the selected furniture out of the obstacle list; the two source scopes must not overlap. If an obstacle reference is missing, restore it with Undo or use **Remove chosen rows** / **Replace with selected** to author the intended scope. **Refresh cached scope** only reads the current rows.

## A source is missing, or generated materials/maps are missing

The Asset Library distinguishes **live scene source**, **stored geometry**, and **MISSING scene source**.

- For **MISSING scene source**, Undo the source deletion, or select the intended catalog row, select the replacement scene model/group in the viewport, then press **Rebind to selected model**. Keep the catalog row active; **Use selected model / group** clears it to start a new registration. Rebinding keeps its asset identity and validates the replacement against its metadata.
- **Use stored geometry** explicitly removes the source requirement and keeps the embedded mesh. It does not restore source materials or UVs. Choose it only when geometry-only output is acceptable.
- A `.cyalib` library stores geometry and placement metadata, not materials, texture files, UV channels or modifier stacks. Preserve the source `.max` library. To recover its appearance, merge the required source models/materials/maps into the scene and rebind the corresponding entries.
- If a live source already has missing texture files or wrong material assignments, repair those paths/assignments on that source and verify its evaluated appearance before Generate. The plugin captures current source data; it does not download missing maps or reconstruct lost mapping.

Generated objects retain their published appearance in a saved scene, but manual mesh/material edits to generated objects are not persistent asset overrides. A later Generate can replace them. Make reusable changes to the source and regenerate. Source models can remain in an organized hidden layer; keep their bindings intact.

The supplied imported-model examples use a **Standard diffuse adapter / Default Scanline**, with an approximate transparent cover. This does not promise reproduction of the original Physical/PBR materials or another renderer. Follow the [imported example scene and map instructions](IMPORTED_EXAMPLES.md); [import qualification](IMPORTED_MODEL_QUALIFICATION.md) records the exact source and rendering scope.

## Preview is stale, disappeared, or refuses Commit

Preview boxes are temporary diagnostic bounds. They do not replace the committed scene objects. Changes to setup settings, relevant source geometry, scene time, units or ownership can invalidate them. Saving/loading, Undo/Redo and scene lifecycle changes can discard them.

1. Read the Preview reason in the main setup view, such as **A relevant scene dependency changed; Preview again.**
2. Resolve the source/settings change, then press **Preview bounds** again.
3. Review the new bounds and press **Commit preview**. Alternatively, use **Generate** to compute and publish directly from current inputs.

**Clear preview** removes only the temporary preview. It retains the published objects and does not re-arm Live. Inspector overlays are separate scene meshes; clearing an arrangement preview does not delete those overlays. The inspector's own captured snapshot also requires explicit reinspection after source changes; see the [inspector guide](ARTIST_GUIDE.md).

## Manual or Live does not update when expected

- In Manual mode, **Apply settings** saves the authored settings; press **Generate** to update placements. Passive refresh buttons do not generate.
- **Live after first Generate** is an authored preference, not proof that updates are currently armed. Enable it and complete an explicit successful Generate. Reopening a scene also requires a successful Generate before Live resumes.
- **Preview bounds** pauses Live so current objects remain available for review. **Commit preview** or **Generate** re-arms it when the Live preference is enabled. Clearing a preview alone does not.
- Live responds to relevant bound furniture, accessories and obstacles. An unrelated scene object is not a dependency merely because it is visible nearby; add it to Collision scope when needed.
- If managed output was edited, Live may retain it and report the supported actions: **Lock selected outputs** for valid pose edits, or **Generate** to regenerate explicitly. Use the lock workflow below, or Generate when replacing those edits is intended. The actual workflow regression verifies that Live preserves the edited pose and names these existing controls. Historical 0.1.2 used the older “lock/detach … Update explicitly” wording; it had no separate detach button.

For Manual mode, clear **Live after first Generate** and press **Apply settings**. Use it while revising several sources/rules or investigating a failure. A geometry-cache hit does not authorize stale placement, replace an explicit Manual command or resume Preview-paused Live. Clearing a cache is not a repair for an invalid source or rule.

## A locked result prevents generation, or a row is broken

1. Read the error and identify the conflicting object, surface, asset or rule. A lock preserves a valid pose; it does not waive support, clearance, collision or category requirements.
2. Restore the previous valid source/rule with Undo, adjust the conflicting authored rule, or select the affected output and press **Unlock selected outputs** before Generate.
3. To preserve a deliberate moved pose, keep the object upright with uniform positive scale and no shear, then use **Lock selected outputs**. Unsupported tilt, shear, negative or nonuniform scale is rejected.
4. A Book row locks/unlocks as a whole. Translate all its members together before locking. If a member was deleted or moved independently, Undo that change, or select a remaining member, unlock the row and Generate. Use **Select all members of this row** when the complete row still exists.
5. If a surface was removed, press **Analyze furniture** and review current IDs. A retired surface ID is not silently transferred to a different shelf. Unlock affected placements and use a current selective scope, or clear **Region IDs** for all unlocked surfaces.

Locks preserve logical placement records, not permanent Max node handles. Successful generation can replace even locked nodes. Refresh the output/row list before selecting again. Generated nodes are unsuitable as permanent rig/animation dependencies, and a lock does not preserve manual mesh/material overrides. Connected stacks and complete affected rows are protected together; see [book-row recovery](BOOK_ROWS.md).

## A translated clone fails on locked regions or old poses

Zero-offset setup/system clone ownership is qualified within its recorded scope. Automatic frame reconciliation for translated, rotated or scaled complete clones is not promised.

For a translated working copy, bind the copied setup with **Use selected setup**, unlock its copied placements, review the copied furniture/surface IDs, and Generate against that furniture. Preserve the original scene or Undo if the copy is not the one intended. A setup-only clone does not mean its inputs or published output nodes were duplicated; inspect the selected setup's bindings before editing shared sources. See [scene ownership](SCENE_OWNERSHIP.md) for the exact clone contract.

## The imported cabinet reports an empty mesh

The representative Poly Haven cabinet contains three triangle surfaces and two original vertex-only path objects. The current native source admission rejects explicitly bound empty triangle meshes; a helper-like name does not make the mesh a valid support surface.

For that specific supplied example, select **modern_wooden_cabinet_body**, **modern_wooden_cabinet_door_l** and **modern_wooden_cabinet_door_r** as the furniture assembly. Keep the two original **path_l/path_r** objects present but outside the bound furniture group. Selecting all original cabinet components still includes the zero-face meshes and fails. This is an explicit preparation rule for that inventoried asset, not an automatic cleanup policy for every imported model. The [imported example guide](IMPORTED_EXAMPLES.md) explains its saved setup and source selection; [import qualification](IMPORTED_MODEL_QUALIFICATION.md) records the evidence scope.

## The plugin will not open, or native/UI versions disagree

1. Use **3ds Max 2027** and the original matched MZP identified by the [0.1.3 release report](RELEASE_VALIDATION_0.1.3.md), which records its actual installer/startup status. Install through **Scripting → Run Script**, save your work and restart Max normally.
2. Use **Cyrus → Cyrus Arrange** for arrangement or **Cyrus → Arrange Inspector** for the diagnostic panel. Running an old loose `.ms` file can load UI for a different native version.
3. For **Restart Max 2027 after installing Cyrus Arrange**, complete the restart before retrying. Installing a new file does not replace an already loaded native DLL in the running process.
4. For **The loaded Cyrus Arrange version differs from this installed UI** or **A different native module is loaded**, check duplicate plugin paths and old loose native copies, then restart with the intended matched package. Both `CyrusArrange.dlx` and `CyrusArrangeStorage.dlh` must come from that same payload. The installed native path is its `bin/` directory; do not mix files from different version folders.
5. For **Installed payload hash mismatch**, retain the exact error and use the original unmodified package. Editing the startup loader or combining files does not establish a valid matched installation. The [qualification scope](QUALIFICATION_SCOPES.md) explains which exact archive is certified.

For a technical report, include the exact status/startup error, Max version, package version, operation, relevant source dimensions, seed, requested/accepted counts when available, and whether source/scene time/units changed. The MAXScript Listener commands `caVersion()` and `caModulePaths()` report the loaded Arrange version and both native paths when the native API is available. A matching version label alone is weaker evidence than matching the actual pair and payload.

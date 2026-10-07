# Cyrus selection issue — investigation and diagnostic selector

## Resolution confirmed by the artist — October 1, 2026

Disabling **Enable Filter for this Viewport** restored selection. The artist confirmed the result and supplied a screenshot with the SC controller selected and its transform gizmo visible. The viewport filter is the confirmed cause of the reported viewport-selection problem. The exact prior filter configuration was not captured; renderable-only filtering is consistent with the shared `renderable=false` setting and the isolated reproduction.

The production plugin code was not changed to restore selection. Keep the filter disabled in a viewport used to select these controllers, or configure its categories to include them. Close the icon-test panel to remove its temporary probes if it is still open. Do not make controllers renderable as a workaround.

Follow-up product improvement: make controller overlays respect the filter for the viewport being drawn, so excluded controllers do not leave misleading visible icons. Retain non-renderable controller behavior and verify multiple viewports with different filters. The degenerate icon meshes remain a separate robustness concern, not the demonstrated cause of this incident. The previously reported Scene Explorer/H failure was not separately retested in the final confirmation. The screenshot's FPS change is not a controlled performance measurement.

The chronological investigation below records the hypotheses and evidence available at each stage; the resolution above supersedes its earlier unconfirmed status.

## Current evidence

The artist reports that existing and newly created Scatter and Surface Analyzer objects cannot be reselected, including through Scene Explorer. Ordinary geometry is selectable. The supplied screenshot shows both Scatter controllers and both Analyzers in Scene Explorer, visible red viewport icons, a selected Box and a reported viewport rate of 4 FPS.

The cause in that scene is **not yet established**. Low FPS alone is not evidence of a selection lock, memory exhaustion, or a broken controller.

### Confirmed source concern: degenerate icon geometry

Both scripted objects construct their icon meshes using repeated triangle indices `[k+1,k+2,k+2]`. The actual visible lines are drawn separately in viewport redraw callbacks:

- [Scatter generator source](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/before.ms), `on buildMesh`; emitted in [AminScatterObject.ms](../AminScatter/scripts/AminScatterObject.ms).
- [Surface Analyzer script](../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms), `on buildMesh`.

A separate Max 2027.1 batch probe measured **161/161 zero-area Scatter faces** and **116/116 zero-area Analyzer faces**. This is a picking risk: the object mesh is what a SimpleObject supplies for Max's ordinary geometry/hit-testing infrastructure. The visible overlay is not proof of a robust selectable surface. Actual Nitrous mouse picking has not been reproduced by this batch probe, and this finding does not by itself explain a failure of Scene Explorer selection.

Both overlays explicitly draw red without checking the frozen state. Consequently, an icon's red appearance is not evidence that its node or layer is unfrozen.

### Selection behavior and remaining possibilities

- In the fresh batch scene, both classes can be selected, deselected and reselected twice using `select node`; the selected node is verified each time.
- The source search found no controller-freezing or automatic deselection code in the two production scripts. Their ordinary nodes are deliberately non-renderable Geometry objects.
- Frozen node/layer state, group membership, selection context, Explorer filtering and errors when opening the Modify panel still need inspection in the affected scene. The screenshot confirms that filtering is not omitting those four listed rows at that moment.
- The benchmark recorder does not issue selection, freeze/unfreeze, selection-lock or selection-filter mutations.

## Run the diagnostic selector in the affected scene

### Affected-scene evidence received October 1

The supplied report from `Test Scene/SaveSelect.max` and two screenshots confirm direct selection of the existing Scatter and Analyzer in the **Modify** panel, persisting after the timer check. All four controllers are visible, unfrozen at both node and layer levels, and outside groups. The standard selection filter is All and sub-object level is 0. These flags no longer explain this reported failure. Only the PhysX selection callback is listed; the callback listing is not a complete inventory of all native/UI selection mechanisms.

The first diagnostic did **not** read the global selection-set lock. The updated tool queries Autodesk's managed `IInterface.SelectionFrozen` property and displays ON/OFF, or explicitly unavailable if the API cannot be read. Scanning does not change the lock. A separately labelled **Turn off selection lock** button is enabled only when the read succeeds and the lock is ON; clicking it calls `ThawSelection`, without changing frozen nodes or layers. This is a remaining hypothesis, not a confirmed cause. If OFF and normal selection still fails, the viewport icon concern and Scene Explorer selection behavior still require separate investigation.

1. Choose **Scripting > Run Script** and run [CyrusSelectionDiagnostic.ms](../tools/CyrusSelectionDiagnostic.ms). No plugin reinstall is needed.
2. The tool lists Cyrus nodes directly, including hidden/frozen nodes. Scanning reads flags, layer ancestry, group information, selection context and relevant callbacks; it does not evaluate meshes or rebuild scatter/Analyzer output.
   Check **Selection lock**. If ON, click **Turn off selection lock** and test ordinary selection. If OFF, leave it unchanged.
3. Select a row and click **Select listed object**. Wait for the selection result to be recorded.
4. If that fails or raises an error, click **Select via Create panel**. This explicitly switches to the Create panel before selecting, to help distinguish a Modify-panel problem. It leaves the Create panel active.
5. Click **Save diagnostic report**, then **Open saved report folder**. Send the new text file or its path back for inspection.

Reports go to [build/selection-diagnostics](../build/selection-diagnostics). The tool records immediate selection success and whether selection persists after several UI timer ticks, with actual elapsed time. It preserves object/layer freeze and visibility flags. It does not unfreeze all layers, reset Max settings, replace plugins, save the scene or delete scene content. Only the explicit Unlock button changes the selection-set lock.

If the tool successfully selects a controller, it may also provide a temporary way to access the existing object while diagnosis continues. Success is not proof that viewport picking is repaired.

## Verification and next decision

### New lead after the icon comparison

The user reports that the temporary icons still cannot be selected. Their response does not separately enumerate red versus green or H results, so those outcomes must not be inferred individually. Valid probe geometry therefore has not demonstrated a selection fix.

All controllers and all probes have `renderable=false`. Autodesk's separate per-viewport filter can exclude non-renderable objects with **Show Renderable Only**, independently of the ordinary selection filter and node/layer hidden flags. The production overlay callbacks only check node hiding and do not consult `ViewportFilter.IsNodeShown`; the temporary probe overlay likewise does not consult it. This can leave drawn outlines visible while Max filters their underlying objects. An earlier screenshot also shows a colored viewport-filter funnel, a clue rather than a recorded filter value.

The diagnostic now reports `ViewportFilter.Enabled`, `ShowRenderable`, its target viewport versus the active viewport, and `IsNodeShown` per controller. It does not set `ViewportID` (setting that property changes its automatic tracking behavior) or alter filter settings. The next manual step is to open the active viewport's funnel/filter settings and turn OFF **Enable Filter for this Viewport**, then test clicking the icons. This is a targeted viewport setting change; do not make the controllers renderable to work around the filter. It remains to be confirmed in the affected session and does not yet explain the separately reported Scene Explorer/H behavior.

### Controlled viewport test

Run [CyrusIconPickingTest.ms](../tools/CyrusIconPickingTest.ms) in the affected scene, preferably after saving a working copy. Click **Create test icons**, then **Show test icons (Top view)**. Keep the panel open, click in the viewport, and press Q. Test clicking each of the four icons and selecting their `CYRUS_PICK_TEST_` names through H followed by Select/OK.

- Left/red: the existing zero-area triangle construction.
- Right/green: closed triangular tubes with nonzero-area faces.
- Top row: SC; bottom row: SA.

These are temporary Editable Mesh probes built from the existing controllers' icon paths, not replacements or copies of their scatter data. Both columns use the same object type and non-renderable setting, with line overlays. This isolates a geometry difference, but does not reproduce every aspect of scripted SimpleObject picking. The tool creates four nodes, changes selection and explicitly switches the active viewport to Top when asked to show them. Closing the panel deletes only its own probes and removes its redraw callback; it leaves the viewport in its test view and does not save the scene. Existing controllers, their parameters and the installed plugin scripts are unchanged. The scene may be marked modified because temporary nodes were added/removed.

Report viewport clicks for red/green, plus H/list selection for those probes and the original controllers. Green-only viewport success would support a geometry-related explanation; it would not by itself resolve the original Explorer/H report.

### Follow-up: selection lock excluded in the affected session

The supplied reports [05:07:19 UTC](../build/selection-diagnostics/selection-20261001-050719-6654.txt) and [05:07:37 UTC](../build/selection-diagnostics/selection-20261001-050737-1738.txt) both show `Selection lock: false` at initial scan and export. Direct selection persists for Scatter handle 828 and Analyzer handle 6972 in the Create panel. Both are visible, unfrozen, ungrouped, on unfrozen/unhidden Layer002, with selection filter All. These captures list two Cyrus nodes; the earlier capture listed four. The reports do not establish why the scene contents differ.

Together with the earlier successful Modify-panel selections, this excludes a persistent global selection lock and the reported node/layer flags as the explanation at capture time. It does not test actual mouse hit testing or Scene Explorer selection synchronization. The next useful experiment is a controlled comparison of the existing icon mesh against valid nondegenerate pick geometry, alongside separate verification of Explorer/Select From Scene selection. A viewport-only improvement must not be reported as resolving the list-selection failure. Scene weight has not been established as the cause.

[Test runner](../tools/test_selection_diagnostic.py) and [disposable fixture](../tools/tests/selection_diagnostic_smoke.ms) run in a separate Max process. The test verifies direct reselection, scans a frozen-layer Analyzer without changing freeze/selection state, measures icon face degeneracy, and creates/closes the diagnostic dialog. [Result](../build/selection-diagnostic-test/result.txt) and [fixture state report](../build/selection-diagnostic-test/scene-state.txt) retain the evidence.

Production plugin code has not been changed in this investigation. Use the affected-scene report to choose a targeted correction. A future icon fix should replace degenerate geometry or provide proper hit testing, preserve rendering exclusion and controller identity, and be checked with actual viewport clicks across view angles/display modes. Changes to Scatter must be made in its generator input as well as regenerated output.

The updated diagnostic passed another isolated Max 2027.1 batch test: selection-lock ON/OFF detection, preservation of the lock during reporting, explicit unlocking, inherited layer-freeze reporting, controller reselection, and dialog creation. The lock test selects its disposable Box first: Max did not activate the lock for an empty selection in the initial test. The affected-scene reports above subsequently confirmed that its selection lock was OFF.

## Autodesk references

- [Scripted SimpleObject plug-ins](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-C0BFFE27-BB59-4265-8F70-BFE8A636F7CB.html): mesh responsibilities and automatic object behavior.
- [Core selection interface](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_interface.html): `SelectionFrozen` and `ThawSelection`; the installed `Autodesk.Max.xml` documents the corresponding managed property/method.
- [Active Viewport: Filter](https://help.autodesk.com/cloudhelp/2026/ENU/3DSMax-Basics/files/GUID-032D8548-DCE7-48D7-9A42-9E827EF7149B.htm): viewport-local filtering, renderable-only mode and the filter toggle.
- [ViewportFilter scripting interface](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Interfaces/Core-Interfaces/Core-Interfaces-Documentation/U-V-W-X-Y-Z/GUID-49038961-58CA-41F3-8226-7BC8EDE8F94A.html): `Enabled`, `ShowRenderable`, `ViewportID` and `IsNodeShown`.
- [Select From Scene](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-Basics/files/selecting_objects/selection_commands/GUID-0E53BB0B-8F4A-4C32-8968-6D5226ECE8FF.html): list selection and hidden/frozen filtering.
- [Layer Explorer](https://help.autodesk.com/cloudhelp/2025/ENU/3DSMax-Manage-Scenes/files/GUID-8E194B5E-221E-4896-93F8-18072DC6EB82.htm): frozen layers prevent object selection.
- [Selection Filter](https://help.autodesk.com/cloudhelp/2019/ENU/3DSMax-MAXScript/files/GUID-6EF57030-B59F-4341-B6AA-BFB4269AE913.htm): viewport filter restrictions can be bypassed by Select By Name or script selection.

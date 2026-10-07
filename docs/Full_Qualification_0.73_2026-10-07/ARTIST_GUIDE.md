# Artist test workflow — 0.73

**This page preserves the full-qualification scene workflow and its original delivery.** The later [artist reference](../Artist_Reference_0.73_2026-10-07/README.md) explains all current controls; the [Add-layer correction](../Layer_Actions_Fix_0.73_2026-10-07/README.md) identifies the newer Scatter installer. Existing scene and renderer evidence below keeps its original scope.

Use the matching Max 2027 Scatter and Analyzer installers in `dist/Full_Qualification_0.73_2026-10-07/Max2027/`, save work and restart Max. A new script with an older loaded DLL is not a valid test. Installation is an artist action; this campaign only uses isolated profiles. This is a development test build: the first cold rectangle Undo lost its stack in one repeated scenario, despite passing controlled repeats. Test copies first; see [the finding and next acceptance loop](RESULTS.md).

The native workflow follows the approved prototype:

1. **Receiving surfaces:** pick the static ground meshes; global receiver defaults stay here.
2. **Layers & paint sets:** create and order layers top to bottom, then select the layer and paint set to edit. Each layer owns its recipe and population; sets divide that population and share declared defaults.
3. **Models & source containers:** choose models, weights, scale/lift and source radius. Create or pick source rectangles at global, layer or set scope. A pivot inside the rectangle's local XY footprint is active; height is ignored. Moving a source out parks it, preserving its ID and saved settings. Returning it activates the same record. The helper label shows the linked context and active/saved counts; selecting it opens that context in Modify.
4. **Population:** choose a candidate budget or a bounded accepted target. A requested count is not a promise that collisions, areas and Brush can fit that many plants. Advanced exposes retry bounds and density mapping.
5. **Coverage & painting:** Paint/Erase the selected set on its receiver. Stop Brush before changing context. History can be disabled, edited or deleted. One stroke is one Undo. Outside Coverage, Between Plants and rejected-candidate replacement are separate options.
6. **Include / exclude areas:** constrain the layer domain and falloff. Advanced contains Analyzer and detailed falloff bindings.
7. **Transforms:** choose scale, rotation, movement and surface-normal alignment. Advanced contains less frequent assignment/orientation controls.
8. **Spacing & cleanup:** configure within-set, between-set and between-layer rules independently. Selected-instance radius belongs to stable Edit identity. Advanced contains pairs, Relax and detailed cleanup/refill settings.
9. **Viewport & render:** use Point Cloud for large scene browsing. Proxy draws boxes; a very large box count can be expensive. Mesh is subject to triangle and memory budgets. Automatic final render publishes exact output for the renderer; viewport points are not render geometry.
10. **Statistics & diagnostics:** inspect accepted/rejected/protected counts, errors and cached publication. Advanced contains opt-in Start/Stop/Save recording and recorder health. The recorder is in Scatter and does not require MCP.

Common controls stay visible. Each section's **Advanced** disclosure opens its detailed controls. The optional layer window edits the same model; opening it does not create another calculation pipeline. Global Enable, Manual/Live and Update now remain at the top.

In **Manual**, edits wait for Update now and the last complete preview remains. In **Live**, relevant edits schedule an update after a short pause. Browsing or unrelated animation should reuse placements and buffers. Update now explicitly requests a rebuild; it is distinct from passive browsing.

## New scene files

- `Test Scene/Cyrus_073_Qualification/Cyrus_073_Heavy_Garden.max`: five layers, eight sets, all 15 unique supplied plants, curved flower Brush bands, include/exclude areas and independent spacing. Starts in Manual/Point Cloud for predictable opening.
- `Test Scene/Cyrus_073_Qualification/Cyrus_073_100k_Stress_Field.max`: a separate 100,000-plant field for controlled display tests. Exact render is disabled on the stress setup to avoid an accidental enormous render. Mesh shows a triangle-budgeted subset; Point Cloud uses 300,000 points.
- `Test Scene/Cyrus_073_Qualification/Cyrus_073_Plant_Library.max`: isolated supplied source assets/materials.

Use the named HERO, WALK, PLAN and SOURCES cameras. The original supplied scene is unchanged. Seven missing map placeholders were already captured in the original's private copy before the generated garden was loaded; they affect grass and lavender materials. The render evidence does not certify their original visual fidelity. Do not replace unknown maps based only on their names.

`Cyrus_073_Garden_Render.png` is the inspected four-pass production proof; `Cyrus_073_Garden_IR.png` is the inspected IR output. Both are saved beside the scenes. The final garden restores the original 1400 × 980/24-pass renderer settings; the fast four-pass fixture does not become the saved artist preset.

Commercial licensing enforcement and reference-image ML are separate unfinished product work. MCP has a closed, locally approved authoring subset; catalog help does not expose every native control as a remote write.

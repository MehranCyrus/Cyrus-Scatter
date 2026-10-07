# Using the unified system

**Historical 6 October workflow.** For current panel names, ordering and every control explanation, use the [7 October artist reference](../Artist_Reference_0.73_2026-10-07/README.md). The original instructions below retain their dated layout and delivery context; they are not the latest navigation or installation guide.

Use the [matching 0.73 package](PACKAGE.md), restart Max, and make a **fresh Scatter setup**. Older unpublished Scatter/CS Edit scenes and MCP plans are intentionally unsupported. Keep originals and use ordinary source models in a new scene; no old scene is silently converted.

If updating from the first 0.73 package to the [container-selection correction](../Container_Selection_Fix_0.73_2026-10-06/README.md), keep your current 0.73/serialization-54 scene. This corrective build does not require recreating it. Install its matching MZP and restart Max.

Max may open ordinary geometry from an older scene while reporting retired Scatter settings. That Scatter record remains blocked even if saved again under 0.73. Create a fresh setup rather than treating the version caption as proof of compatibility.

## Start and edit a layer

1. Create Cyrus Scatter, select receiving surfaces, and choose Manual or Live.
2. Add a layer in **Modify > Layer Manager**. Select its row to show its sixteen sections below. General receiver/update/display/render controls stay separate.
3. Choose source models, population/seed, coverage and transforms; configure spacing and cleanup as needed.
4. Add paint sets for different assets/coverage. Their shares divide the layer population. Set-specific assets/Brush history stay independent; layer recipe/defaults are shared.
5. Manual waits for **Update now**; Live responds after relevant edits settle. **Edit layer in window...** is optional and changes the view, not the calculation model.

Spacing fields save through their change handlers. Background composition keeps its explicit Apply action so mode and references commit together. Paint/Erase/Fill/Delete/Assign radius are intentional actions, not generic Apply requirements.

## Create and use source rectangles

1. Open the selected set's **Source containers — own / inherited** section and click **Create rectangle**. This creates a dedicated **Cyrus Source Container** and selects an own pool automatically; no procedural-enable/conversion click is needed.
2. Move your source models into it. A pivot inside the rectangle's local XY boundary activates that model; height is ignored. The rectangle is a model palette, not a surface on which scattered instances are placed.
3. Use **Pick rectangle** to link another Cyrus container. Picking a supported ordinary unmodified Rectangle copies its frame into a new Cyrus helper; the original spline remains intact. Non-rectangular/rounded/modified shapes are not silently accepted.
4. For sharing, choose **Layer containers** to inherit the layer pool, or **Global containers** and create/link the setup-wide pool from **Surface Scatter > Global source containers**. Several rectangles can contribute to one pool.

The viewport label shows the rectangle name, current setup/layer/set editing context, distinct physical active/saved palette counts, and shared-consumer count when applicable. These palette counts are separate from each set's registered source rows and instance population. Source weights/radius/scale/lift/forward/color settings belong to each consuming set, so sharing one scene model does not merge those settings.

Drag a source out to park it; its saved row and settings remain. Drag it back to reactivate the same registration. **Remove rows** deliberately removes the source record and has different meaning. Manual keeps its previous scattered publication until Update; Live reacts to the real membership change.

## Select the rectangle to edit Scatter

Selecting the helper exposes a **Source Container** section plus linked Scatter setup/layer controls in Modify. The rectangle stays selected so you can move or resize it. **Edit linked Scatter context** selects among consumers; this changes the editing context only. The optional **Edit layer...** popup uses that same layer/set.

Inactive pools stay linked for editing but carry no sources. A global rectangle created before any layer still exposes setup/Layer Manager controls. An unlinked helper reports that state; it does not guess another Scatter owner. Rename the helper/layer/set to update the cached label. **Show viewport label** controls presentation only.

## Move a palette together

Translate the rectangle to carry its eligible active static source models. The boundary moves during the gesture; models follow when the gesture commits. One Undo restores both rectangle and models. Moving palette models does not translate their already-scattered instances. Width/Length only resize membership; rotation/scale do not transform the models.

Sources keep their scene parenting. A wholly managed static group/hierarchy moves once as a unit. A partially managed group, unmanaged child, locked/animated/constrained controller or instanced helper is excluded/refused with status rather than moving unrelated artist objects. Use a unique helper copy when necessary. Native following admits at most 1,024 hierarchy nodes per gesture.

If rectangles overlap, a valid previous movement owner stays. For an unowned ambiguous source, select its row in **Active / parked source models** and click **Follow this container**. Usage can be shared, but a physical model has only one movement owner. Sources crossed by the moving boundary are not swept into an already-started gesture. Cancel/failure restores the frozen transforms.

Scripted tests cover these lifecycle paths. Actual pointer-driven SDK forwarding, combined selection during a mouse gesture, DPI and scroll feel still need artist verification; [results](RESULTS.md) separate this from the API tests.

## Paint, spacing and display

Choose the intended paint set before starting Brush. Area/density/Brush eligibility combine. **Outside Coverage** excludes earlier authored coverage; **Between Plants** depends on earlier accepted plants and selected spacing. Accepted target separately attempts bounded replacement; shortfall remains possible.

Use **Scoped spacing** to choose set self override, sibling defaults/pair, layer pair or layer within-set defaults. Factor/radii/gap and XY/3D are independent of mesh geometry scale. Point/boundary Relax is off by default and prepares ordinary candidates before final eligibility and protected Edit.

Viewport Point Cloud/Mesh/Proxy/centres budgets change presentation. Full accepted output may exceed the displayed sample. Retained buffers avoid re-upload of unchanged data but still have draw costs. Navigation/redraw timing is not a guaranteed FPS.

## Diagnose and test

**Modify > Diagnostics** starts/stops bounded local recording, reads status and saves reports without MCP. Recording is optional and off by default. Container actions emit summary causes; cached inspection does not recalculate.

Test a disposable copy first: create layers/sets; park/return a source with custom radius/scale; translate/resize; Undo/Redo; switch linked contexts; save/reopen; test Manual/Live and a real Brush change. Confirm no new placements while merely browsing or playing unrelated animation. Qualify Corona IR separately from production render and keep original artist files intact. Use [the roadmap](ROADMAP.md) for unresolved performance/renderer/platform tests.

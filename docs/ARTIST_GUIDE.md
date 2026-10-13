# Cyrus Scatter 0.81.2 — current source workflow

The [offline team license](licensing/TEAM_PILOT_0.79_2026-10-11.md) is independent of scene format. Open **License / activation** in Scatter Modify, save a request for Mehran, then import the returned license file. It expires 30 days after generation. Supported scenes remain loadable/renderable after expiry; creation/editing locks. See [activation and renewal instructions](../tools/licensing/README.md).

Updated 13 October 2026. Current source adds spline Band ranges, density, identification and field previews, plus Auto Radius. The [implementation record](plans/spline-bands/PROGRESS.md) distinguishes completed tests from remaining acceptance. Current local Max 2026/2027 packages and their exact identities are listed in the [installation guide](plans/spline-bands/INSTALLATION.md).

Panels show controls, counts and actionable status. Detailed explanations live in this guide, the website and control tooltips. For example, hover over Radius mode to see why Auto is unavailable for a selected source. Pending updates, Analyzer errors and brush status remain visible.

## Start with a layer

Create a Scatter object, add a layer, add its receiving surfaces, and add its models. Set Amount, then press **Update scatter** in Manual mode. Live mode responds to relevant changes. Select another layer to edit a different planting recipe.

In **Geometry > Cyrus > Cyrus Scatter**, click to place the controller, move to size its icon, then click to finish. Right-click to leave Create mode; another placement click starts another controller. The corrected 0.79.5 package draws the icon before any layer or plant cache exists; see the [creation fix](Terrace_Workflow_0.79.5_2026-10-11/CREATION_FIX.md).

Each layer owns its surfaces, models, amount, layout, transforms, area limits, and cleanup. The layer list controls evaluation order. Earlier layers normally occupy space first when between-layer spacing is enabled. Visibility hides viewport display; disabling a layer removes its calculation/output contribution. Names and identification colors do not change layer identity.

Use the compact Add, Copy, Remove, Up and Down actions. Copy includes surfaces and independent copies of Paint Areas. Removing a link or layer is different from deleting its scene geometry. Undo is part of the acceptance checklist.

## Surfaces, models and optional containers

The Surfaces list belongs to the selected layer. Use + to pick a receiver, the list action to choose by name, and remove to unlink selected receivers. A plane and sphere can belong to one layer. Another layer can have different receivers or reuse the same ones.

**Adding a receiver preserves the base placement on unchanged receivers.** In Density mode, below the population cap, the new surface gets its own candidates. In Fixed Total mode, the same total is shared across the surfaces: existing surfaces may lose plants, while surviving base candidates retain their positions, models, rotation and scale. Reordering or renaming a receiver does not reseed it. Unlinking and restoring the same node restores its stream; a replacement with the same name is a new receiver.

This does not freeze all accepted output. A cap can redistribute quotas; changed masks, spacing, cleanup or protected edits can affect acceptance. Relax can move plants when their own receiver's count or neighborhood changes. Editing the receiver's geometry/topology is outside the unchanged-surface guarantee.

**Create fresh schema-58 setups.** Earlier development formats are unsupported and are not migrated. Preserve original scene files. Current settings use unit-aware distances; use saved system units when Paint or CS Edit is bound to receiver geometry. Unsupported binding conversion is rejected rather than clearing authored edits.

Models are source scene objects. Their Scatter label can differ from the scene object name; clearing the label uses the scene name again. The color square is a viewport identification color. Assignment groups use separate colors in their own disclosure; changing identification color does not change grouping.

0.79.5 limits a local preview edit to the affected layers and reuses unchanged native display buffers. Changing one source identification color leaves other layers' prepared previews intact. It does not change plant positions or apply pending Manual population edits. Heavy changed layers and cold scene loading can still take time; see the [measured garden workflow](Terrace_Workflow_0.79.5_2026-10-11/README.md).

Visible Source settings expose weight, scale, radius mode, vertical offset, Follow Scale and radius display. Weight controls relative selection frequency. **Manual** uses your saved radius and optional Follow Scale. **Auto** bounds supported model geometry around its pivot after final instance scale and orientation, computing both XY and 3D radii. It can be conservative for tall, asymmetric or off-center geometry. Follow Scale is disabled in Auto because final scaling is already included; returning to Manual restores its settings. Points, Empty rows and unqualified source types expose Manual only. Neither mode is exact mesh collision or whole-model containment inside a Band. Forward axis controls orientation conventions.

**Models & Points** starts with Add Point and Add Model. Names, identification colors, weight, scale, collision radius, Follow Scale and orientation are visible in this section. **Pick object** is enabled for one selected Point; **Make point** is enabled for one selected model. Both keep the source row identity, labels, colors, weights, transforms and Band assignments. Make point retains the registered scene object reference to prevent automatic containers from registering a duplicate; the Point uses no model geometry, and the scene object is not deleted. Stored Auto settings are inactive for Points; Manual radius remains editable. Pick object can restore the same registered model or choose another unused model. Assignment groups has its own disclosure. Point and Empty rows are distinct placeholder source kinds. A Point row creates accepted placement markers without final rendered geometry; replacing it with a model turns that row into an ordinary model source. An Empty row is an intentional weighted gap in Candidate budget mode. Accepted target rejects positive-weight Empty rows rather than endlessly refilling gaps: use Candidate budget, Point placeholders, or zero/remove the Empty weight. Points are permitted in Accepted target, so accepted counts are not necessarily visible-model counts. These source rows are different from Analyzer sample points.

For point-only Spline bands, add and name Point rows in Models & Points, then select them under Layout > Spline bands > Assign by **Models / Points**. Assignment groups remain available for choosing several source types together. Use **Plant centres** display for one marker per accepted point. No model or Paint Area is required; a receiver and closed spline still define the placement domain. Point placeholders do not produce final rendered geometry. Point names, identification colors and explicit band choices use saved row identities. Replacing a Point preserves its row; removing another row cannot redirect the choice. Copying a layer includes its band settings and explicit choices.

**Source containers** is a separate collapsible section. Choose Manual models, Layer containers or Shared containers. Containers are optional palettes. Point and Empty rows stay active independently of rectangles; actual models are activated by their pivots. Collection is distinct from layout assignment groups. New rectangles start with **Enable collection** off: position and resize the rectangle first, then enable it in Source containers or in the rectangle’s Modify panel. Inactive rectangles do not scan the scene or carry models. Disabling collection parks existing source rows and preserves their settings; Manual waits for Update, while Live applies the change automatically. The switch is saved per rectangle and shared by its linked layers. Rectangles saved before this switch existed also open with collection off. Enabled rectangles collect eligible model pivots inside their footprint; they are not receiving surfaces. Parking a model outside a palette preserves its registered settings. Shared containers can serve multiple consumers with independent settings. The selected-container Modify view edits the same records as the Scatter Modify panel. The floating layer editor and source-to-Band navigation button have been removed. Band membership labels and tooltips remain informational.

In a Band, choose **Models used by this Band** directly below its width/range, before density and field settings. The **Scale** controls sit directly below the density curve, with **Min** and **Max** on one row. Click a selected model, Point or assignment group again to remove it from the Band. Clearing the last selection leaves an empty Band and preserves its interval.

## Layout and Amount

Layout is directly after Models. It assigns models to candidate positions:

| Mode | Use | Important limit |
| --- | --- | --- |
| Random mix | Weighted model choices | The seed and all placement constraints still apply. |
| Clusters | Patches of assignment groups | This changes model choice, not necessarily candidate positions. Group weight derives from member model weights. |
| Spline bands | Consecutive or independently overlapping inside/outside Bands along closed Paths | Uses world XY. Receivers supply placement elevation. Consecutive gives earlier matching Bands priority; Independent combines eligible contributions. |
| Surface Analyzer | Assign models to Analyzer border, path, point and edge channels | Consumes a separate Analyzer result. Select Analyzer and Update Analyzer are explicit actions. |

For Bands, add a closed Path, add an inside/outside Band, and explicitly choose its **Models / Points** or **Assignment groups**. New Bands start unassigned. The list and **Models used by this Band** show membership; a source can belong to several Bands. Per-Band scale range is an additional multiplier under Advanced. These Bands are separate from Brush strokes.

**Consecutive** accumulates widths separately on each Path and side. An unassigned or zero-weight Band still reserves its interval, leaving a gap; later Bands do not move inward to fill it. **Independent** exposes Start/End distances for each Band, allowing overlap. Switching to Independent initializes those ranges from the consecutive intervals; switching back requires a contiguous, representable proposal. Both conversions are undoable.

**Density** and the optional density curve control contribution within a Band. Curve X runs from its Start boundary to its End boundary, including inward for Inside Bands. Independent contributions add up to a maximum occupancy of 100%, then choose an owner proportionally. For example, 100% Sphere plus 25% Box yields approximately 80% Sphere and 20% Box in the overlap, before other masks/spacing. Where only the Box contributes, occupancy is 25%. Use **Candidate budget** for Independent ranges or nontrivial Band density; Accepted target is rejected because refill would erase the fade.

Distances remain world-space widths when the Path is scaled. **Rounded** uses distance to the original border segments. **Sharp** uses bounded miter offsets; acute corners have a miter limit, and overly narrow or complex requests may require simplification. The preview shows the admitted contours rather than promising unlimited corner precision.

Amount offers fixed Count or area Density. The seed makes a given recipe reproducible. Sampling can use a texture mask. Candidate budget makes a bounded candidate request; restrictions can leave fewer accepted plants. Accepted target makes additional bounded attempts. A shortfall can be correct when spacing, boundaries or masks leave insufficient room. Increasing retry work cannot make an impossible arrangement fit.

## Vector painting

Turn on **Use Paint Areas**, add a named area and choose one of this layer's surfaces. Use **Start Brush**, **Paint / Erase**, **Radius**, **Stop**, **Fill** and **Clear**. **Radius** is center to edge: 100 mm gives a 200 mm stroke diameter. The Painter cursor now uses that same radius. Area density, fade controls and Paint feedback are directly visible in Painting, with no Advanced disclosure. Repeated painting merges into the same area. Erasing cuts holes; overlapping areas admit each candidate only once. Undo/Redo restores a complete brush gesture.

Each area targets one receiver. Use separate areas for separate terrain surfaces while retaining the same layer models and population. Vector painting supports terrain and planes that are single-valued in receiver-local XY. Closed spheres, vertical faces, folds and stacked projected sheets are rejected. They remain usable as ordinary scatter receivers without vector painting.

**Inside fade** places the transition inside the border; **Outside fade** extends it beyond the border. Set both for a transition across the border. Zero for both gives a hard edge. Distances are in the transformed projection plane, not distance along a slope. A larger outward fade cannot place plants outside the receiver or inside an explicit Exclude area.

**Fade density** thins stable candidates using the **Density curve**. **Fade scale** multiplies each plant's existing random scale between **Edge scale** and **Inner scale**, shaped by the **Scale curve**. The graph's left end is the outer edge of the transition, and its right end is the fully interior end. Density and scale can be used independently. With both widths at zero there is no transition: interior plants use the curve's right-end scale. Where areas overlap, the strongest effective density determines scale; equal weights use area order.

**Vector borders** is the default feedback. **Coverage samples** provides a bounded diagnostic view of the field. Feedback updates while drawing; in Manual mode plants wait for **Update**. No individual stroke/history controls or strength accumulation remain.

0.78.3 improves feedback during fast continuous strokes and avoids repeatedly rearranging the painting panel. Existing 0.78 vector regions and curves retain the same format. See [drawing measurements and acceptance limits](Container_and_Radius_0.78.3_2026-10-10/README.md); very complex outlines and heavy viewport geometry still add work.

Removing a receiver link leaves its area inactive with its borders preserved. Relinking the same node restores eligibility. An area with paint cannot silently change target. Changes to target geometry/topology require restoring that geometry or creating a new area; the previous completed scatter remains available after a failed update. Use saved scene units on reopen.

The new engine bounds contour vertices and prepared feedback. A failed edit leaves the preceding region intact; feedback never silently publishes a truncated successor. See [limits and actual qualification](Vector_Brush_0.78_2026-10-10/README.md) before treating scripted results as physical-input certification.

## Area limits, transforms and spacing

Include/Exclude splines are layer-wide world-XY masks. Include shapes form the allowed domain; Exclude wins in overlaps. Unlinking a shape keeps the scene spline. These rules constrain vector painting as well as ordinary scattering. New Area links select their row and default to Include. Selected area mode follows the highlighted rows; mixed modes show neither option selected, and no selection disables the control.

Advanced Analyzer Area can use a center-line band and/or point-radius discs. Together they form a union. Its Analyzer reference is separate from Layout's Analyzer and from the falloff Analyzer. Width is the full line-band width; point radius is not model collision radius.

Edge falloff can target an Analyzer boundary or one selected area line. Each area line retains its own delete strip, density ramp and scale ramp. Ramps start after the delete strip. Graph edits save as they are edited; Close is not Cancel. Physical graph-handle interaction remains a separate artist test.

Transforms show X Min/Max, Y Min/Max and Z Min/Max side by side for rotation, scale and movement, plus uniform scale. Reset actions reset their respective controls. Align to normal and Keep on surface affect orientation/projection.

Fresh ordinary layers expose Within this layer and Between layers spacing. Clearance is **factor × (radius A + radius B) + gap**. XY ignores vertical distance; 3D includes it. Each relationship has its own settings. Per-instance radius overrides belong to stable instance identities; generator changes can require an explicit clear instead of silently rebinding edits.

Candidate Relax moves candidates within its bounded settings. Cleanup removes unprotected isolated plants or small islands using neighbor distance, minimum neighbors and minimum island size. Protected CS Edit placements can survive generation/cleanup and create reported conflicts. Retry cleanup gaps is a separate population-policy choice.

## Preview, updates, output and diagnostics

Point Cloud, Proxy and Mesh serve different preview costs. Layer/model/Band identification colors help identify planting in simplified previews. **Color by Bands** uses the accepted Band owner, including when one source belongs to several Bands. These identification colors do not replace source render materials. Display limits can show fewer instances or faces than the accepted population. A displayed count is not the full output count. Box, Sphere and Pyramid proxies use retained instanced geometry; CPU fallback remains available if retained drawing fails.

Within Spline Bands, **Preview Falloff** shows bounded density samples on the receiving surfaces; blue is 0% and red is 100%. **Show Boundaries** independently draws white contour lines. **Field view** selects the highlighted Band's contribution or **Combined density**. The label reports sample/face counts: this is approximate coverage, not a fully shaded receiver or the final plant count. It describes the Band stage before other masks, spacing and cleanup. These samples and lines never become render output.

In Manual mode, field feedback can follow edited or animated Paths/receivers while plants and collision radii stay at the last Update. The label then reads **Pending field; plants from last Update**. Toggling feedback or selecting another Band does not publish placements. An uncached Mesh/Point Cloud mode cannot consume changed source geometry alongside the old publication; it retains the previous display and requests Update.

Manual stores edits until an explicit calculation action. **Update scatter**, **Refresh preview** and **Refresh areas / preview** update the whole Scatter setup and can publish pending Manual edits. **Read cached statistics**, **Read recording status** and **Refresh fields** only read the existing state. Passive browsing, area/layer selection and unrelated animation must not publish pending placements. Live responds to relevant input changes. Display-only settings can refresh presentation without changing placement generation. A failed successor retains the previous complete result and exposes an error.

**Radii / layer**, **Show All Radii**, per-source **Show Radius** and the XY/3D display choice refresh only the preview. Their Undo/Redo leaves pending Manual population/radius edits unapplied. XY draws a circle; 3D draws three perpendicular circles using the published spatial radius. Radius and field lines share a bounded cached display bundle. The display metric does not change the independently chosen metric of a spacing rule.

Automatic final render uses the render bridge; exact output and baking use source mappings and placement transforms. A successful preview does not certify every renderer/material/export path. Remove baked output removes owned baked nodes, not original sources.

Statistics describe the last completed result, including accepted, shown, rejected, protected and shortfall information. Refreshing cached statistics is not proof that a pending recipe has been generated. Diagnostic recording is local, bounded and off by default. Start, Stop and Save report are separate from sending a report anywhere.

Surface Analyzer remains version 0.14 and has its own Manual/Real-time mode. It analyzes supported open planar mesh elements, produces boundaries/paths/points, and can export spline/helper snapshots. It does not support a closed sphere as an ordinary planar analysis input; general curved-surface scattering remains separate; the vector brush has the projection limits above. Updating a Manual Analyzer does not authorize a pending Manual Scatter publication.

If linked analysis is out of date, Scatter keeps its previous complete result and names the Analyzer that needs updating. Run **Update Analyzer / Analyze**, then **Update scatter** when Scatter is Manual. This applies to Layout, Analyzer Area and Analyzer falloff dependencies. Freshness is saved with the guides, so reopening does not make pending analysis current. Older Analyzer publications need one explicit Analyze with the matching updated Analyzer script; the new Scatter script must be distributed with that script.

## Final artist acceptance

Use the [current validation matrix](plans/spline-bands/VALIDATION.md) and [implementation evidence](plans/spline-bands/PROGRESS.md). Scripted host checks, captured images and native calculations are recorded separately from physical picking, brush gestures, curve handles, high DPI, docking, long sessions, heavy assets and final render inspection. This is a development build, not 1.0 certification.


### Band scale profiles

In **Layout**, find **Scale** directly below the density curve. Min/Max remains the random Band size range.
**Scale profile** selects **Off**, **Follow Density** or **Custom**; Custom enables
**Edit scale curve**. X runs across the Band from Start to End, not along the Path.
Y is a size percentage: 100% is unchanged, 50% halves size and 200% doubles it.
The profile multiplies the existing random Band size, source scale and layer
transforms once. Density and scale retain separate saved curves and Bezier handles.

Follow Density uses the effective density curve shape, excluding the Density %
strength. Disabling the density curve makes this scale mode flat 100%. Switching
modes preserves the stored Custom graph. Zero scale collapses the instance without
removing its candidate; use density to remove placements. Scale traces are bounded
to 2–257 samples, at most 64 authored graph points and 0–10000% size.

Scale-only changes retain base candidates and source/owner random channels.
Size-dependent spacing, protected edits and cleanup can change accepted output.
Auto Radius follows the final instance basis; Manual radius follows size only when
Follow Scale is enabled. A drawn radius does not enable its spacing rule.
Manual retains published plants and radii until Update scatter; Live schedules
relevant changes. Opening an unchanged graph does not alter the recipe.

Rounded Bands use the existing distance coordinate. Sharp Bands reuse density's
prepared coordinate, so scale edits cannot perturb its density lottery. Away from
reported boundary uncertainty, scale-profile error is bounded to 0.005 multiplier
before the other scale factors. A curve too steep for that coordinate fails with a
specific error and retains the previous complete result; simplify the curve or use
Rounded corners. No unbounded geometry refinement is triggered by size editing.

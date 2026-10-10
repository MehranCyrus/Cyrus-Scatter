# Cyrus Scatter 0.75 — current workflow

9 October 2026. Use this guide for the current UI and ownership model. Dated 0.73 guides describe the older layout. This guide explains behavior; the qualification checklist separately identifies what has been tested.

## Start with a layer

Create a Scatter object, add a layer, add its receiving surfaces, and add its models. Set Amount, then press **Update scatter** in Manual mode. Live mode responds to relevant changes. Select another layer to edit a different planting recipe.

Each layer owns its surfaces, models, amount, layout, transforms, area limits, and cleanup. The layer list controls evaluation order. Earlier layers normally occupy space first when between-layer spacing is enabled. Visibility hides viewport display; disabling a layer removes its calculation/output contribution. Names and identification colors do not change layer identity.

Use the compact Add, Copy, Remove, Up and Down actions. Copy includes surfaces and independent copies of Paint Areas. Removing a link or layer is different from deleting its scene geometry. Undo is part of the acceptance checklist.

## Surfaces, models and optional containers

The Surfaces list belongs to the selected layer. Use + to pick a receiver, the list action to choose by name, and remove to unlink selected receivers. A plane and sphere can belong to one layer. Another layer can have different receivers or reuse the same ones.

**Adding a receiver can still move existing generated placements.** The current sampler works across the combined receiving domain. Density is not yet a guarantee of stable placements on untouched surfaces. Keep this limitation in mind before changing receivers in a finished composition.

Models are source scene objects. Their Scatter label can differ from the scene object name; clearing the label uses the scene name again. The color square is a viewport identification color. Assignment groups use separate colors under Advanced; changing identification color does not change grouping.

Model Properties expose weight, scale, radius, vertical offset, Follow Scale and radius display. Weight controls relative selection frequency. Radius is a simplified collision footprint, not exact mesh collision. Follow Scale makes the footprint follow model scaling. Forward axis controls orientation conventions.

Advanced Point and Empty rows are placeholder source kinds. A Point row can be replaced with a model; an Empty row reserves a source choice without visible model geometry. They are different from Analyzer sample points. Verify Point/Empty behavior with the chosen population policy before relying on requested counts as visible-model counts.

Source containers are optional palettes. They collect eligible model pivots inside their footprint; they are not receiving surfaces. Parking a model outside a palette preserves its registered settings. Shared containers can serve multiple consumers with independent settings. The container editing view and optional layer window edit the same records as Modify.

## Layout and Amount

Layout is directly after Models. It assigns models to candidate positions:

| Mode | Use | Important limit |
| --- | --- | --- |
| Random mix | Weighted model choices | The seed and all placement constraints still apply. |
| Clusters | Patches of assignment groups | This changes model choice, not necessarily candidate positions. Group weight derives from member model weights. |
| Spline bands | Consecutive inside/outside bands along closed guides | Uses world XY. Raising a guide in Z does not make the bands follow a curved surface. Earlier matching bands have priority. |
| Surface Analyzer | Assign models to Analyzer border, path, point and edge channels | Consumes a separate Analyzer result. Select Analyzer and Update Analyzer are explicit actions. |

For bands, add a guide, add an inside/outside band, set its width, choose source objects or assignment groups, select choices, and set its scale range. An empty choice list can produce no placements. These bands are not Brush strokes.

Amount offers fixed Count or area Density. The seed makes a given recipe reproducible. Sampling can use a texture mask. Candidate budget makes a bounded candidate request; restrictions can leave fewer accepted plants. Accepted target makes additional bounded attempts. A shortfall can be correct when spacing, boundaries or masks leave insufficient room. Increasing retry work cannot make an impossible arrangement fit.

## Painting on multiple receivers

Turn on **Use Paint Areas** only when you want to restrict the layer to painted coverage. Add a named Paint Area and choose its Surface from that layer's receiver list. Start Brush and paint. Further strokes edit the selected area; they do not create new populations or new named areas automatically.

For a plane and sphere in one layer, create one area targeting the plane and another targeting the sphere. Selecting an area changes the brush target, while both areas use the layer's model collection. Overlapping areas combine coverage without duplicating the layer's plants. Paint/Erase, radius, strength and softness affect the selected area. Fill and Empty affect that area's coverage. Stop ends the active brush session.

Removing a receiver link leaves its area inactive and preserves its paint. Restoring that receiver can reactivate it. An area with existing paint cannot silently switch to a different target. Topology changes can invalidate saved anchors; the system reports this instead of applying strokes to unrelated faces. Reopen painted scenes using the saved scene units; automatic unit rescaling of Brush data is guarded, not supported.

Older files may retain model-owning sets. These are different from current Paint Areas. A supported single-set layer can adopt its existing paint. Multi-set conversion remains unfinished; do not treat an old set selector as a new area selector.

## Area limits, transforms and spacing

Include/Exclude splines are layer-wide world-XY masks. Include shapes form the allowed domain; Exclude wins in overlaps. Unlinking a shape keeps the scene spline. This is separate from painting directly on a curved receiver.

Advanced Analyzer Area can use a center-line band and/or point-radius discs. Together they form a union. Its Analyzer reference is separate from Layout's Analyzer and from the falloff Analyzer. Width is the full line-band width; point radius is not model collision radius.

Edge falloff can target an Analyzer boundary or one selected area line. Each area line retains its own delete strip, density ramp and scale ramp. Ramps start after the delete strip. Graph edits save as they are edited; Close is not Cancel. Physical graph-handle interaction remains a separate artist test.

Transforms show X Min/Max, Y Min/Max and Z Min/Max side by side for rotation, scale and movement, plus uniform scale. Reset actions reset their respective controls. Align to normal and Keep on surface affect orientation/projection.

Fresh ordinary layers expose Within this layer and Between layers spacing. Clearance is **factor × (radius A + radius B) + gap**. XY ignores vertical distance; 3D includes it. Each relationship has its own settings. Older model-owning sets retain additional scopes. Per-instance radius overrides belong to stable instance identities; generator changes can require an explicit clear instead of silently rebinding edits.

Candidate Relax moves candidates within its bounded settings. Cleanup removes unprotected isolated plants or small islands using neighbor distance, minimum neighbors and minimum island size. Protected CS Edit placements can survive generation/cleanup and create reported conflicts. Retry cleanup gaps is a separate population-policy choice.

## Preview, updates, output and diagnostics

Point Cloud, Proxy and Mesh serve different preview costs. Layer/model identification colors help identify planting in simplified previews. Display limits can show fewer instances or faces than the accepted population. A displayed count is not the full output count. Box, Sphere and Pyramid proxies now use the retained instanced geometry display path; CPU fallback remains available if retained drawing cannot be used. See the [courtyard fix measurements](Courtyard_Fixes_0.75_2026-10-10/README.md) for the tested workload and remaining limits.

Manual stores edits until explicit Update scatter. Passive browsing, area/layer selection and unrelated animation must not publish pending placements. Live responds to relevant input changes. Display-only changes can refresh presentation without changing placement generation. A failed successor retains the previous complete result and exposes an error.

Automatic final render uses the render bridge; exact output and baking use source mappings and placement transforms. A successful preview does not certify every renderer/material/export path. Remove baked output removes owned baked nodes, not original sources.

Statistics describe the last completed result, including accepted, shown, rejected, protected and shortfall information. Refreshing cached statistics is not proof that a pending recipe has been generated. Diagnostic recording is local, bounded and off by default. Start, Stop and Save report are separate from sending a report anywhere.

Surface Analyzer remains version 0.14 and has its own Manual/Real-time mode. It analyzes supported open planar mesh elements, produces boundaries/paths/points, and can export spline/helper snapshots. It does not support a closed sphere as an ordinary planar analysis input; curved Brush painting is a separate supported feature. Updating a Manual Analyzer does not authorize a pending Manual Scatter publication.

If linked analysis is out of date, Scatter keeps its previous complete result and names the Analyzer that needs updating. Run **Update Analyzer / Analyze**, then **Update scatter** when Scatter is Manual. This applies to Layout, Analyzer Area and Analyzer falloff dependencies. Freshness is saved with the guides, so reopening does not make pending analysis current. Older Analyzer publications need one explicit Analyze with the matching updated Analyzer script; the new Scatter script must be distributed with that script.

## Final artist acceptance

Use the [feature checklist](System_Qualification_0.75_2026-10-09/CHECKLIST.md) and [complete control register](System_Qualification_0.75_2026-10-09/CONTROL_REGISTER.md). Scripted host checks and native calculations are recorded separately from physical picking, brush gestures, curve handles, high DPI, docking, long sessions, heavy assets and final render inspection. This is a development build, not 1.0 certification.

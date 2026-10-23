# Cyrus Scatter 0.86.9.2 — artist workflow

The 0.86.9.2 EXE includes distinct **Max 2024, 2026 and 2027** builds and **Surface Analyzer 0.14.2**. **This patch was tested only in Max 2027; the 2024/2026 builds are untested.** The [delivery report](plans/edit-instances/DELIVERY_08692.md) records the density controls, native column lifecycle, live Edit movement and preservation checks. Existing supported edits are preserved; save upgraded scenes as new copies because plugins older than 0.86.9 cannot read source-aware Edit data.

For library models already added to a layer, highlight the row in **Models &
Points** and use **Select sources**. **Show sources** and **Hide sources** change
node visibility while preserving renderable flags; expand **Source access** to reach
these commands. Layer/group restrictions still
apply. **Edit material** opens one model's assigned scene material in Slate.
Shared materials change together, and catalog files remain unchanged.

The private **0.86.7 individual library** replaces the bundled example designs
with 96 individual assets covering all 104 original catalog cards. Open **Layers >
Recipes** or **Cyrus Library**; **Plant models > All models** opens by default.
Filter Trees, Shrubs, Flowers, Groundcover, Grasses, Leaves or Ground Details.
Each tile uses its original Corona render. **Merge model** places a visible model
in the scene. **Add to selected layer** adds that complete model as a hidden
source to the current Scatter layer, preserving its planting settings. Choose
receivers and distribution yourself, then **Update scatter** in Manual mode.
Corona is required for the supplied materials. Personal recipes remain separate.
Successful model additions now show a banner naming the model and destination
layer. Failed imports show an error banner and retain the previous scene.
The **0.86.9.2** installer updates Scatter and Surface Analyzer 0.14.2 for Max 2024, 2026 and 2027 and detects your existing library.
Save and close the target Max versions, then choose **Install / Update** for the versions you need and reopen them afterwards.
**Uninstall Scatter** removes Scatter registration while keeping the independent Analyzer, your library
and scenes. To install or update the library, put
**CyrusScatter-Content-0.86.7.zip** beside the EXE and check
**Install / update plant library**. Leave it unchecked for a plugin-only update.
The installer reports a missing ZIP before installation and extracts a valid
ZIP directly into shared storage. Existing compatible bytes are reused.
Standard profiles share one library; models do not need a new copy when the
plugin version changes. See the
[installation guide](Max_2027_Installation.md), then restart Max after installation.

Drag rollout headers to arrange the Modify panel. Cyrus leaves Max's saved rollout order intact when the controller is deselected and selected again.
The order is a Max user preference; open/closed and Advanced state retain their existing presentation behavior. Max packs whole rollouts into columns, so a tall open rollout can move to the next column when it does not fit.
0.86.9.2 restores Max-controlled column geometry after a crash in the 0.86.9.1 width adjustment. Switching Scatter objects in wide Modify panels is covered by focused Max 2027 checks. Small native insets can remain; padding removal is deferred.

Common parameter edits now refresh affected sections and reuse unchanged layout.
When many sections are saved open, later sections appear in queued batches.
Open/closed preferences are preserved. Hidden Advanced controls within a mounted
section are still created; large all-open panels can still take time.
The correction keeps Layers and Models lists visible during cached refreshes,
including adding layers, removing sources and returning to the controller.

Library thumbnails now load as you scroll. In **Viewport & render**, choose
**Textured mesh** in **Display mode** to preview supported source materials,
source UV channels and leaf cutout opacity. **Mesh** uses identification colors
while retaining supported opacity cutouts, so an opacity-card leaf keeps its
outline. Point Cloud and Proxy retain their lightweight representations.
**Color by** is available for nontextured modes; it changes marker/geometry
identification colors and does not offer textures for Point Cloud.
**Placement points** shows one marker per accepted placement. Material edits
update appearance without applying pending Manual placement changes.
Radius and spacing edits reuse unchanged source textures and geometry. Changes
to source materials, their maps or UVs refresh the affected appearance.

Select receiving surfaces in **Surfaces**, then use **Hide surface** or
**Show surface**. This hides their viewport drawing while keeping them available
for painting and rendering. The choice belongs to the scene node, so every
setup sharing that surface sees the same visibility. Undo and saved scenes retain
it. Ordinary Max Hide and Freeze still prevent painting.

Adding a layer inherits the selected layer's current receiving surfaces and
starts with its own source and mask settings. Removing a surface from the new
layer does not remove it from the original layer. A layer with no receiving
surface says **No surface** and explains where to add one.

The preview uses bounded 256-pixel material tiles and two-sided alpha cutouts;
it is not a Corona render. Standard and Corona Legacy/Physical base color and
opacity, Multi/Sub IDs, Bitmap, Checker and supported UV map chains are covered.
Forest Color uses a preview without per-instance Forest variation. World/vertex
dependent maps and unsupported shaders use a stated fallback. Missing source UV
channels retain the previous complete display until repaired. Source render
materials remain intact. The supplied library requires compatible Corona and,
where used, Forest map plug-ins in each Max version.

The retained 0.86.5 library/Amount baseline fixes library portability, map/channel switching, Clear, empty-source output and Library restoration. Complete presets transfer supported Paint/path layouts across units and local-XY footprints. Map coordinates evaluates supported procedural graphs on the receiving surface. Its [historical delivery report](plans/preset-gallery-improvements/DELIVERY_0870.md) retains the original 0.87.0 labels, tests and limits. The [current delivery](plans/source-clearance/DELIVERY_08682.md) records current packages and focused qualification. The [0.86.7.2 report](plans/preset-gallery-improvements/DELIVERY_08672.md) preserves its original package and host evidence; [0.86.7](plans/preset-gallery-improvements/DELIVERY_0867.md) retains the textured-preview delivery details.

Placement computation and storage remain native C++. The one-million controller work limit still applies, and failed updates retain the previous complete result and Undo. Existing grids, Bands, orientation, Paint and slope/altitude controls remain available. The [library workflow](plans/preset-gallery-improvements/ARTIST_WORKFLOW.md) explains selected-terrain loading and complete Save. Further roadmap work remains paused.

The [offline team license](licensing/TEAM_PILOT_0.79_2026-10-11.md) remains independent. Open **License / activation**, save a request and import the returned license. Existing scenes remain loadable/renderable after expiry; creation/editing locks. See [activation instructions](../tools/licensing/README.md).

Scroll over empty panel background with the wheel, or click-hold and drag that background vertically. Buttons, numeric controls and list resize grips keep their own actions. In the library, Max’s default UI scale is treated as normal size; the toolbar offers Small, Medium and Large tiles. Resize the library as needed. Configured 150% scaling is tested separately from physical 4K/mixed-monitor acceptance.

Panels show controls, counts and actionable status. Detailed explanations live in this guide, the website and control tooltips. For example, hover over Radius mode to see why Auto is unavailable for a selected source. Pending updates, Analyzer errors and brush status remain visible.

Layers and Models show **Name** and the identification color above a full-width name field. Long list names end in an ellipsis so layer counts/status and model weight/Band information remain visible. Selecting a row reveals its complete name in the edit field; hovering the row also shows the full name. This display shortening never changes the saved name.

## Start with a layer

Create a Scatter object, add a layer, add its receiving surfaces, and add its models. Set Amount, then press **Update scatter** in Manual mode. Live mode responds to relevant changes. Select another layer to edit a different planting recipe.

0.82.4 adds **Amount > Mesh channel density** and short hover help for Paint
controls. The [mesh mask handoff](plans/eleven-phase-roadmap/MESH_MASK_0824.md)
records that delivery's implementation/testing and installer identity.

In **Geometry > Cyrus > Cyrus Scatter**, click to place the controller, move to size its icon, then click to finish. Right-click to leave Create mode; another placement click starts another controller. The corrected 0.79.5 package draws the icon before any layer or plant cache exists; see the [creation fix](Terrace_Workflow_0.79.5_2026-10-11/CREATION_FIX.md).

Each layer owns its surfaces, models, amount, layout, transforms, area limits, and cleanup. The layer list controls evaluation order. Earlier layers normally occupy space first when between-layer spacing is enabled. Visibility hides viewport display; disabling a layer removes its calculation/output contribution. Names and identification colors do not change layer identity.

Use the compact Add, Copy, Remove, Up and Down actions. Copy includes surfaces and independent copies of Paint Areas. Removing a link or layer is different from deleting its scene geometry. Undo is part of the acceptance checklist.

## Surfaces, models and optional containers

The Surfaces list belongs to the selected layer. Use + to pick a receiver, the list action to choose by name, and remove to unlink selected receivers. A plane and sphere can belong to one layer. Another layer can have different receivers or reuse the same ones.

**Adding a receiver preserves the base placement on unchanged receivers.** In Density mode, below the population cap, the new surface gets its own candidates. In Fixed Total mode, the same total is shared across the surfaces: existing surfaces may lose plants, while surviving base candidates retain their positions, models, rotation and scale. Reordering or renaming a receiver does not reseed it. Unlinking and restoring the same node restores its stream; a replacement with the same name is a new receiver.

This does not freeze all accepted output. A cap can redistribute quotas; changed masks, spacing, cleanup or protected edits can affect acceptance. Relax can move plants when their own receiver's count or neighborhood changes. Editing the receiver's geometry/topology is outside the unchanged-surface guarantee.

**New setups use schema 59.** Schema-58 scenes have an explicit Undoable clearance upgrade; save an upgraded copy and preserve the original. Earlier development formats remain unsupported. Current settings use unit-aware distances; use saved system units when Paint or CS Edit is bound to receiver geometry. Unsupported binding conversion is rejected rather than clearing authored edits.

Removing the last model produces a valid empty layer after Update in Manual, or automatically in Live. Amount changes remain valid while empty, and adding a replacement resumes normal validation. A failed update retains the last complete result; intentionally empty output clears it.

Models are source scene objects. Their Scatter label can differ from the scene object name; clearing the label uses the scene name again. The color square is a viewport identification color. Assignment groups use separate colors in their own disclosure; changing identification color does not change grouping.

0.79.5 limits a local preview edit to the affected layers and reuses unchanged native display buffers. Changing one source identification color leaves other layers' prepared previews intact. It does not change plant positions or apply pending Manual population edits. Heavy changed layers and cold scene loading can still take time; see the [measured garden workflow](Terrace_Workflow_0.79.5_2026-10-11/README.md).

Visible Source settings expose weight, scale, radius mode, vertical offset, Follow Scale and radius display. Weight controls relative selection frequency. **Manual** uses your saved radius and optional Follow Scale. **Auto** bounds supported model geometry around its pivot after final instance scale and orientation, computing both XY and 3D radii. It can be conservative for tall, asymmetric or off-center geometry. Follow Scale is disabled in Auto because final scaling is already included; returning to Manual restores its settings. Points, Empty rows and unqualified source types expose Manual only. Neither mode is exact mesh collision or whole-model containment inside a Band. Forward axis controls orientation conventions.

**Models & Points** uses the **+** below the source list to add a model. **Add Point** sits beside **Make point**. The former Add currently selected scene objects action is removed. Names, identification colors, weight, scale, collision radius, Follow Scale and orientation are visible in this section. **Pick object** is enabled for one selected Point or model and replaces that row with the picked object; **Make point** is enabled for one selected model. Both keep the source row identity, labels, colors, weights, transforms and Band assignments. Make point retains the registered scene object reference to prevent automatic containers from registering a duplicate; the Point uses no model geometry, and the scene object is not deleted. Stored Auto settings are inactive for Points; Manual radius remains editable. Pick object can restore the same registered model or choose another unused model. Assignment groups has its own disclosure. Point and Empty rows are distinct placeholder source kinds. A Point row creates accepted placement markers without final rendered geometry; replacing it with a model turns that row into an ordinary model source. An Empty row is an intentional weighted gap in Candidate budget mode. Accepted target rejects positive-weight Empty rows rather than endlessly refilling gaps: use Candidate budget, Point placeholders, or zero/remove the Empty weight. Points are permitted in Accepted target, so accepted counts are not necessarily visible-model counts. These source rows are different from Analyzer sample points.

For point-only Spline bands, add and name Point rows in Models & Points, then select them under Layout > Spline bands > Assign by **Models / Points**. Assignment groups remain available for choosing several source types together. Use **Placement points** display for one marker per accepted point. No model or Paint Area is required; a receiver and closed spline still define the placement domain. Point placeholders do not produce final rendered geometry. Point names, identification colors and explicit band choices use saved row identities. Replacing a Point preserves its row; removing another row cannot redirect the choice. Copying a layer includes its band settings and explicit choices.

**Source containers** is a separate collapsible section. Choose Manual models, Layer containers or Shared containers. Containers are optional palettes. Point and Empty rows stay active independently of rectangles; actual models are activated by their pivots. Collection is distinct from layout assignment groups. New rectangles start with **Enable collection** off: position and resize the rectangle first, then enable it in Source containers or in the rectangle’s Modify panel. Inactive rectangles do not scan the scene or carry models. Disabling collection parks existing source rows and preserves their settings; Manual waits for Update, while Live applies the change automatically. The switch is saved per rectangle and shared by its linked layers. Rectangles saved before this switch existed also open with collection off. Enabled rectangles collect eligible model pivots inside their footprint; they are not receiving surfaces. Parking a model outside a palette preserves its registered settings. Shared containers can serve multiple consumers with independent settings. The selected-container Modify view edits collection properties; select the Scatter controller for full layer and planting settings. The floating layer editor and source-to-Band navigation button have been removed. Band membership labels and tooltips remain informational.

Selecting a source rectangle opens its compact collection, dimensions and ownership properties. Select the Scatter controller to edit the full planting settings. Moving an enabled rectangle carries its eligible owned models; resizing its boundary leaves model transforms unchanged. Label refresh reuses the existing movement setup.

In a Band, choose **Models used by this Band** directly below its width/range, before density and field settings. The **Scale** controls sit directly below the density curve, with **Min** and **Max** on one row. Click a selected model, Point or assignment group again to remove it from the Band. Clearing the last selection leaves an empty Band and preserves its interval.

## Model radius and clearance (0.86.8)

Select a model or Point under **Models & Points**. **Radius and clearance** keeps the footprint and the rules that use it together. Radius is measured around the instance pivot. Showing its circle does not turn clearance on.

| Control | Meaning |
| --- | --- |
| Own copies | Separation between instances of this model entry |
| Other models in this layer | Separation from the other model entries in the selected layer |
| Other layers | Inherit layer defaults, turn this request off, choose specific layers, or include all other layers in this setup |
| Conflict priority | Normal, or Prefer this model when an eligible placement conflicts with a normal model |
| Clearance distance | Expand to edit factor, extra gap and world XY/3D metric for this model's explicit requests |

Each scope inherits independently. Changing **Other models in this layer** leaves **Other layers** unchanged. **Use layer defaults** uses the relevant rule under **Spacing & cleanup**. **Off** removes this model's request in that scope; another model can still request clearance from it. Selecting particular other layers follows their identities through renaming. Deleted targets remain inactive until restored by Undo; a new layer with the same name is a different target.

The minimum distance is **factor × (radius A + radius B) + extra gap**. With radius 20 mm for A and 0 mm for B, factor 1 and gap 0, their pivots need 20 mm of clearance; two copies of A need 40 mm when Own copies is enabled. Both models can request a constraint. The stricter evaluated distance applies for each metric, and both XY and 3D constraints are checked if requested. Exact tangency is allowed. This is pivot-based clearance, not an exact leaf outline or surface-geodesic distance.

**Prefer this model** wins clearance conflicts after protected edits; ties use layer order and stable candidate order. It does not reserve extra Count slots ahead of distant models. Count admission occurs before preference, and bounded refill can replace rejected candidates. Coverage, masks and cleanup can still remove a preferred ordinary placement. Protecting a model does not force it through an ineligible surface or an impossible Count target.

Multi-select shows **Mixed** for differing dropdown values and blank differing numeric values. Editing one setting changes only that setting for the selected entries. **Pick object**, **Make point**, copy and recipe import preserve or remap the intended source identities. Manual retains the previous completed result until **Update scatter**; Live reacts to relevant edits.

**Spacing & cleanup > Edit default rule** edits independent Within this layer and Between layers defaults; switching this dropdown does not disable the other saved rule. Candidate Relax, accepted-placement cleanup and per-instance radius overrides keep their separate meanings.

In **0.86.8.2**, **Point Relax** and **Boundary Relax** appear directly under
**Spacing & cleanup > Relax - move candidates**, above Advanced. Enable either
option to reveal its settings. Both belong to the selected layer:

- **Point Relax** separates nearby candidate positions toward the Relax distance.
  Iterations and Strength control the amount of relaxation.
- **Boundary Relax** smooths candidate neighborhoods. Its Strength, Iterations
  and Max movement limit the adjustment while retaining receiver eligibility.
- **Relax distance** is shared: Point Relax uses it as the desired separation;
  Boundary Relax uses it as the neighbor search radius. It remains editable when
  only Boundary Relax is enabled.

Relax moves candidate positions; subsequent radius/clearance rules reject
conflicting placements. Relax alone does not guarantee that model geometry will
not overlap. Use each model's **Radius and clearance** scopes to reject pivot-distance
conflicts. Geometry can still overlap because those checks are not exact mesh
collision. **Advanced**
keeps selected-instance radius overrides and accepted-placement cleanup.

Scenes saved with schema 58 show **Upgrade scene** with the installed version before calculation. The upgrade is Undoable and preserves authored identities and settings. Save an upgraded copy; schema-58 runtimes reject the new schema. Scenes already upgraded to schema 59 in 0.86.8 need no additional upgrade. New complete recipes use format 8, with inherited policies added when supported earlier recipes are imported. The content library retains its own revision; it does not need rebuilding for this change.

## Layout and Amount

Layout is directly after Models. **Planting positions** chooses the generator; **Source assignment** below it chooses models independently.

| Planting positions | Controls and behavior |
| --- | --- |
| Surface random | Existing surface sampling with Count or area Density |
| Rectangular | Independent column and row spacing |
| Staggered | Row spacing plus alternate half-column offsets |
| Hexagonal | One nearest-neighbor distance; row pitch is calculated |

For grids, set **Origin X/Y**, **Heading** and optional **Jitter %**. The frame is world XY and projects down onto the highest hit of each receiver. It stays fixed when terrain bounds or masks change. Zero jitter keeps exact lattice positions. Completely vertical receivers have no usable projected surface.

Grid pitch determines population. Count/Density and target/refill controls are inactive; masks and collision rules remove cells without adding replacements. Paint, Bands and normal controls keep their existing roles. Analyzer Single/EdgeRow provides its own positions and cannot be combined with grids. Grid cells over holes still count toward the shared one-million work limit; excessive bounds retain the preceding result and request larger spacing or a smaller domain. Authored CS Edit/radius bindings still require explicit reset/restore when generation geometry changes.

Source assignment offers:

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

With Surface random, Amount offers fixed Count or area Density. The seed makes a given recipe reproducible. Sampling can use a texture mask. Candidate budget makes a bounded candidate request; restrictions can leave fewer accepted plants. Accepted target makes additional bounded attempts. A shortfall can be correct when spacing, boundaries or masks leave insufficient room. Increasing retry work cannot make an impossible arrangement fit.

Count accepts up to **1,000,000** per population. All populations on one controller share a **1,000,000-candidate work limit**, including retry and protected-edit requirements. Exceeding the shared limit reports an error and keeps the preceding complete result. This limit is separate from the viewport display budget.

**Image / pattern density** and **Surface density** are independent. White permits plants, black excludes them and gray thins them. Enabled masks multiply with Paint and terrain eligibility before spacing/collision limits.

**Choose pattern** opens the bundled starter masks: Uniform, Soft patches and Wide bands. **Image** and the native **Map** target share the next row and remain available when empty. Max may label an empty map target **None**. Click it to browse, or drag a **texture map** from the Material Editor onto it; choose Instance to keep the same editable map. Map enables **Use image** and selects **Map coordinates**, evaluating the graph on each receiving surface. Supported graphs include Vertex Color, Color Correction, Output, Checker, Bitmap, Mix, Noise, RGB Multiply and Gradient. A Vertex Color node can read its own data channel, and Checker can read its own UV channel; nested outputs retain that context. A complete material is not a scalar density map. Renderer/camera-dependent maps and unsupported classes report an error. The three masks are original mathematical images; the user's final artwork can extend this collection later.

A selected bitmap shows the complete tile. Procedural maps now show a small cached texture preview. Receiver-dependent graphs can look different on the actual surface: use **Show mask** to inspect the field Scatter evaluates. A failed thumbnail clears the preview without removing the assigned map. Opening or refreshing this thumbnail preserves pending Manual settings and the current scatter result.

**World XY** projects without receiver UVs. **Scatter local XY** follows the setup frame. Physical **Tile X/Y**, size lock, rotation and offsets control the pattern footprint; **Repeat** tiles it and **Clamp** extends border pixels. **Receiver UV** explicitly reads UV channel 1..99 and has U/V repeats and offsets. Projected World/Scatter-local images do not require UVs. Receiver UV needs the selected UV channel; Map coordinates needs each channel requested by its graph. Invert precedes the image density curve. Initial placement and Relax use the same native image sampler.

**More settings** expands one section below the button: image sampling and portable Bake, mask display detail/opacity/sample markers, and population retry settings. **Fewer settings** collapses that section. Hiding these controls preserves their settings. Map resolution 64/128/256/512 controls projected image detail independently of physical tile size. Map coordinates samples the graph directly at each candidate; it is not a raster bake. Image mapping controls appear when **Use image** is enabled. Surface field controls appear when **Use surface density** is enabled. **Clear** removes the assigned map and disables image density, while retaining the independent surface field. Disabling Use image alone keeps the map for later re-enabling. Choosing an Image or pattern restores World XY; choosing Map restores Map coordinates.

**Show mask** displays Image, Mesh or Combined density as a bounded surface overlay. It stays enabled during relevant edits, including Data Channel changes. **Hide mask** stops it. Buttons share a row when space permits; narrow panels stack controls to keep captions readable. Opacity and optional tiny/small/large markers affect visualization only. Combined is eligibility before spacing, collision and count limits. A failed same-layer refresh marks the retained mask stale; a failed owner switch never displays another layer's cached mask. Manual placements remain at their last Update.

Image masks run before authored Edit. Removing eligibility keeps an edit dormant; restoring eligibility restores it. Resolution changes alone preserve Edit bindings. Live procedural maps remain editable in the scene. Arbitrary procedural graphs are retained in Max scenes but are not serialized by the portable package adapter. Receiver-aware graphs cannot be baked into a context-free tile. For projected image workflows, portable Save accepts a supported static RGB/RGBA PNG or explicit **Bake portable snapshot**: a linear 16-bit density tile with time/resolution provenance. This snapshot preserves scalar density, not the editable procedural producer; Undo restores the live map. Other live image formats can also be explicitly baked for portable Save. External bitmap edits follow Max's reload/notification behavior; there is no idle directory polling.

**Surface density > Mesh channel** reads numeric values directly from each receiving
surface's evaluated modifier stack. It works with Random, Clusters, Spline Bands,
Analyzer layouts, texture density and Paint Areas. Enable **Use surface density** in Amount and choose **Mesh channel**. Choose **Channel 0** for vertex colors or **1..99** for
a numbered map channel, then the component **R/X**, **G/Y** or **B/Z**. These are
stored values; the separate Texture Density UV channel still selects texture
coordinates. Each assigned receiver must contain the selected channel.

**Relative elevation** is the other surface field. It measures evaluated receiver-local Z from 0 at the lowest referenced vertex to 1 at the highest; a flat receiver is 0. It creates no channel or modifier. Invert and the response curve control low/high planting. Node translation, rotation and scale preserve this local field. The revised Valley and Mountain presets use this mode, so they require neither a fabricated channel 2 nor the original scene altitude. Explicit artist-authored channels remain requirements.

For terrain curvature, put Data Channel above the terrain deformation. Add
Curvature, adjust its convex/flat/concave response and output through Vertex
Output to an unused Map Channel (for example 7) and component X. In Scatter,
select channel 7 and R/X. VertexPaint can author or adjust the same channel.
The rainbow Data Channel display is an optional visualization, not the planting
mask's color interpretation. Slope controls steepness; curvature measures local
bending, so they can be combined.

**Input min/max** remap the selected value to 0..1 and clamp values outside the
range. Min must be less than max. **Invert mesh mask** reverses that normalized
value before **Density curve** maps it to planting eligibility: 0 excludes,
1 permits, and intermediate values thin stable candidates. Values interpolate
between each triangle's map-face corners, preserving intentional channel seams.
Detail follows the mesh data rather than a bitmap resolution. The curve is saved
with this layer; copying a layer copies its independent mask settings and curve.

The mask runs after candidate movement/Relax and before CS Edit. Masked base
candidates keep their saved edits dormant and recover them when eligibility
returns. Nonzero random movement requires **Keep on surface** when this mask is
enabled. Existing protected Edit placement rules continue to apply after replay.
Channel-only changes retain geometry bindings. Manual mode retains plants until
**Update scatter**; Live responds to relevant channel/modifier changes and
animation. Missing/invalid channels retain the preceding complete result and
identify the receiver/channel in the error.

**Preview mask** explicitly reads the current inputs and displays at most 2,048
grayscale face-centre markers across this layer's surfaces. White permits plants;
black excludes them. It does not include the other Paint/texture/slope masks and
can differ from pending Manual plants. It is a sparse snapshot, so tiny details
can be missed. After a relevant edit, press Preview mask again; **Hide preview**
clears the cached display. Navigation and redraw consume cached markers without
channel reads. Direct channel sampling is limited to 2 million evaluated faces
per receiver; VData, selection and negative map channels are outside this version.

Projected image samples are reused while the map, its resolution and its evaluation interval
remain valid. Receiver/UV changes can reuse that bake. Receiver-aware maps re-evaluate relevant receiver/channel/graph changes; unrelated animation and idle do not sample or solve. Invert derives its own
bounded sample array. Editing or animating the map refreshes its samples when an
update is needed. Manual holds the preceding plants until Update scatter; invalid
mapping or a failed update keeps the previous complete result. Cache reuse does
not make a high-resolution map free, and coarse maps can miss narrow features.


## Slope and altitude filters

In **Include / exclude areas → Surface eligibility**, enable **Filter slope** or **Filter altitude** for the selected layer. These decide whether a candidate can grow there; **Align to normal** controls its orientation separately. Disabled filters leave the candidate result unchanged.

Slope uses the evaluated triangle's world-space geometric normal: **0° faces upward, 90° is vertical, 180° faces downward**. A 0–35° interval keeps relatively gentle upward terrain. Smoothing normals do not change the test. A mirrored transform uses the winding of the transformed surface, so check the intended side.

Altitude uses world Z at the final receiver anchor, in scene units, after movement and Relax. Source pivot offsets do not move this test. For example, Min height 10 m and Max height 30 m select that elevation band. With unprojected movement, the saved anchor is the projection on the owning triangle's plane; this does not make an off-surface point lie inside that triangle.

**Lower fade** rises smoothly inside the minimum; **Upper fade** falls smoothly inside the maximum. A 0–35° slope interval with a 10° upper fade stays full through 25°, then thins to zero at 35°. Zero fade includes the hard endpoint. A lower fade of 5 m in the 10–30 m altitude example rises from zero at 10 m to full density at 15 m. Fades must fit inside the interval without overlapping; crossed ranges and nonfinite values reject the update and retain the previous complete result. Equal Min/Max is valid only with zero fades.

Slope and altitude eligibility multiply with the existing Paint, Band and texture restrictions. Overlapping Paint Areas retain their existing max-union rule. Surviving candidates retain IDs, model choices and transforms. Explicitly moved or cloned CS Edit plants are protected and bypass these filters. Filtering precedes spacing and cleanup. **Accepted target** can refill from a bounded later candidate prefix and therefore increase local density; use **Candidate budget** when the fade itself should determine the population.

The filter status reports **prepared rows**, filtered rows and protected rows from the last complete Update. It is not the number of attempted or accepted plants. Manual retains that result until Update; Live follows relevant edits and receiver animation. Invalid updates retain both placements and their prior statistics. Copy, save/reopen and merge retain the filter settings; height fields participate in scene-unit conversion. Settings/curve presets remain their named categories; complete static planting recipes are available separately through Layers > Recipes.

## Complete planting recipes

Select one terrain mesh and open **Cyrus Library** (Customize > Cyrus category), or **Layers > Recipes...** from an existing setup. The browser captures that terrain. Changing selection afterward does not redirect the load. The tree separates My recipes, Bundled examples and Custom library; open a collection or All recipes. Search, thumbnail/list views and three tile sizes are available. Refresh explicitly rereads disk; passive browsing does not calculate plants.

Choose **Save Recipe**, select layers in evaluation order, and enter a name, collection, tags and description. It saves supported static settings, model/Point/Empty roles and weights, seeds, transforms, spacing relationships, masks, Paths/Bands, editable curves and all native Paint coverage, including disabled, empty and orphan areas, holes and fades. Pending Manual edits save without calculating plants. My recipes defaults to **Documents/CyrusScatter/Library**. New format-5 recipes reference immutable `recipe-data-*` payload directories; keep the manifest and its referenced files together. Earlier formats and optional presentation sidecars remain readable.

Optional PNGs are limited to 1024 pixels per axis and 2 MiB. Choose an existing image or explicitly capture the published viewport. Pending Manual changes require explicit Update-and-capture or saving without a current thumbnail; browsing never renders previews. **Update selected** creates a new revision, **Save Copy** creates another identity, and **Edit details** changes presentation without touching the scene. A changed file after review requires a fresh review. Bundled examples remain read-only; save a personal copy.

**Load onto surface**, double-click or Enter imports supported models/materials, creates a setup when needed and adds new layers to the captured terrain. Existing layers, order and Manual/Live mode remain intact. The explicit Update also applies pending setup edits. Multiple owners require opening Recipes from the intended setup. Explicit missing mesh-channel requirements are explained before adding anything; no saved terrain is substituted. Complete presets transfer Paint contours and path positions from the saved local-XY footprint into the destination footprint. Plant sizes, spacing, brush radius, falloff and path widths convert system units and retain physical dimensions. Terrain Paint presets transfer between single-valued local-XY footprints. Surface-attached Paint presets require matching mesh topology; arbitrary remeshing is not an automatic transfer. Original Paint is preserved. Settings-only exact Paint restoration still requires its compatible receiver.

One Undo removes the added preset and restores the preceding complete publication. Redo restores the same layers, sources, Paint and placement rows without needing the library files. A setup supports ten populations. The controller's shared viewport budget stays unchanged; its per-layer share adjusts as layers are added.

Save has **Include models, materials, terrain and paths** enabled by default. Supported standalone models use static mesh/Standard-Blinn/PNG adapters. Included terrain captures the evaluated geometry and mesh channels at Save time, including modifier output; it does not store an editable modifier stack. Static spline paths retain their knots, handles and transforms. Complete Paint stays included with its compatible receiver. Package creation runs once on Save, and its progress window reports completion. Unsupported dependencies leave a clearly reported settings recipe rather than claiming a complete ready preset.

A settings-only recipe must be saved again with its supported assets before direct loading. The old advanced binding dialog is retired from the normal browser. Paint still requires compatible evaluated geometry, frame and saved units; footprints are not automatically reprojected to arbitrary terrain. Field overlays remain off until explicitly enabled.

Complete save rejects authored Scatter Edit deltas, per-instance radius overrides and unsupported parameter controllers rather than omitting them. Stop the brush before saving/importing. The catalog indexes up to 10,000 recipes, with 128 tiles per page, two image jobs and a bounded image cache. Missing previews show placeholders. The [eight bundled examples](../AminScatter/library/README.md) include editable scenes and actual-result thumbnails: meadow, woodland, mountain, painted borders, orchard, hexagonal hillside, four garden rooms and valley moss/rocky crests. Use Load onto surface, or open a copy of the matching scene to inspect the original example.

**Apply Style** copies selected supported setting groups to the captured layer, keeping receivers, sources and Paint by default. It offers Keep/Saved/New variation and explicit map/target bindings. Identical effective settings create no extra Undo or calculation. **Export portable package** additionally collects supported static standalone meshes, Standard/Blinn materials and PNG maps. Terrain/paths and other external roles still need binding. Direct loading uses independent packaged assets. Typed scene-reuse adapters remain internal and retain their ownership restrictions. Imported bitmap files persist for saved scenes and Redo. XRefs, nested populations, renderer-specific proxies/shaders, material-variant browsing, arbitrary-terrain Paint transfer and general recipe blending remain unsupported. See the [package contract and limits](plans/preset-gallery-improvements/PACKAGE_CONTRACT.md).

## Named settings and curve presets

Use **Presets...** in Amount, Transforms, or Spacing & cleanup. Open an existing density/scale graph to find its **Presets...** button. Enter a name and choose **Save new**. Selecting a saved item only changes the list selection; **Apply** changes the captured target. **Rename** changes the library name, and **Delete** confirms removal of that library file. Changing the selected layer while the dialog stays open does not redirect Apply; the target caption identifies the original layer. Reopen the browser to target a different layer.

Population presets contain count/density, seed, candidate-budget/target settings and bounded retry settings. Transforms contain the layer's rotation, size, movement, normal-alignment, orientation mode/blend/direction and projection settings. Target references are preserved: a Look at target numeric preset requires a valid target on the destination layer before Apply. They preserve models, surfaces, source-row metadata, IDs, maps and layout. Distances are stored in metres and converted to the scene's system units; density remains plants per square metre. Animated or expression-controlled target parameters are rejected; static shared controllers are detached so another layer is not changed.

Spacing presets save the effective rule for the chosen Within this layer or Between layers scope. Apply creates an explicit override for those selected owners. The existing inheritance/default reset is separate. Presets do not store peer identities or include Relax/cleanup settings.

Curve presets preserve the selected curve's samples and editable handles without changing its enabled state, width or scale range. Density and Paint scale use values from zero to one; boundary and Band scale can use larger multipliers. An incompatible or inconsistent curve is rejected. A samples-only curve becomes an editable polyline. One Undo/Redo restores a complete Apply; closing a stale graph after Undo does not restore the undone preset. If a graph reports an external change, close and reopen it before editing again.

Manual mode retains the last complete plants until **Update scatter**. Live applies the completed settings through its normal update callbacks. Saving, browsing and renaming do not calculate plants. The user library is **CyrusScatter/Presets** inside Max's per-user PlugCFG directory; copy the `.cspreset.json` files to share these settings. The browser admits 512 files, 64 KiB per file and names up to 80 characters. Invalid files are skipped with a count; file errors are reported without replacing the previous valid file. For complete static multi-layer recipes and explicit asset substitution, use Layers > Recipes below.

## Vector painting

**Paint and splines:** select a Paint Area and stop the brush. **Export spline**
offers **Optimized** and **Exact snapshot**, creating an independent Editable
Spline with the area's contours and holes. Optimized reduces planar knots within
the world-unit maximum deviation and reports the result; its initial tolerance is
1 mm. Attached boundaries use Exact. Original Paint and completed placements stay
unchanged. A changed export context requires reopening the options.
Edit the spline with Max's tools, reselect the Scatter and Paint Area, then
choose **Replace** or **Add** and press **Pick spline...**. Replace sets that area's
coverage; Add unions the imported region with existing paint. Escape cancels the
pick. Each changed import and each export is one Undo. Manual waits for Update;
Live applies the changed coverage. Neither operation links Paint to the source
spline, so later spline edits require another import.

On terrain, export uses the receiver's local XY plane at local Z=0, including
its scene transform; import projects along receiver-local Z and clips to the
receiver. Curved surfaces export their 3D border. An unchanged exported snapshot
restores exact coverage, including holes and large regions. Edited closed curves
must lie on the surface within Curve tolerance and select the smaller enclosed
region on a closed component. A completely filled closed object has no border to export. Every contour must be
closed. Nested contours alternate filled regions and holes regardless of winding
or order; self-intersections use the same even-odd fill. Add does not erase paint.
Area density, fades, identity and model assignments are preserved.

**Curve tolerance** is a world-unit approximation distance, initially 1 mm.
Smaller values require more samples. One edited-curve import allows up to 8,192 input knots
and 8,192 sampled vertices; unchanged guarded surface snapshots use the native
contour budget. For edited curves, simplify the shape or increase tolerance when needed.
Paint's local coordinate precision also imposes a minimum tolerance. Very large
local coordinates can exceed Max spline precision and cause export rejection.
Invalid conversion retains the preceding area. See [Phase 5 evidence](plans/eleven-phase-roadmap/P05.md).

Turn on **Use Paint Areas**, add a named area and choose one of this layer's surfaces. Use **Start Brush**, **Paint / Erase**, **Radius**, **Stop**, **Fill** and **Clear**. **Radius** is center to edge: 100 mm gives a 200 mm stroke diameter. The Painter cursor now uses that same radius. Area density, fade controls and Paint feedback are directly visible in Painting, with no Advanced disclosure. Repeated painting merges into the same area. Erasing cuts holes; overlapping areas admit each candidate only once. Undo/Redo restores a complete brush gesture.

Each area targets one receiver. Use separate areas for separate surfaces while retaining the same layer models and population. Vector painting supports terrain, spheres, boxes, vertical sides and manifold curved meshes. Curved strokes follow the surface, cross connected edges and do not paint through to the opposite side or a disconnected sheet. Degenerate faces and nonmanifold connections require repair. Curved receivers admit up to 100,000 triangles and 200,000 vertices, with additional bounded stroke and contour work.

**Inside fade** places the transition inside the border; **Outside fade** extends it beyond the border. Set both for a transition across the border. Zero for both gives a hard edge. Terrain distances remain in the transformed projection plane. Curved-surface distances follow the mesh with the complete receiver transform, including nonuniform scale. A larger outward fade cannot place plants outside the receiver or inside an explicit Exclude area.

**Fade density** thins stable candidates using the **Density curve**. **Fade scale** multiplies each plant's existing random scale between **Edge scale** and **Inner scale**, shaped by the **Scale curve**. The graph's left end is the outer edge of the transition, and its right end is the fully interior end. Density and scale can be used independently. With both widths at zero there is no transition: interior plants use the curve's right-end scale. Where areas overlap, the strongest effective density determines scale; equal weights use area order.

**Vector borders** is the default feedback. **Coverage samples** provides a bounded diagnostic view of the field. Feedback updates while drawing; in Manual mode plants wait for **Update**. No individual stroke/history controls or strength accumulation remain.

0.78.3 improves feedback during fast continuous strokes and avoids repeatedly rearranging the painting panel. Existing 0.78 vector regions and curves retain the same format. See [drawing measurements and acceptance limits](Container_and_Radius_0.78.3_2026-10-10/README.md); very complex outlines and heavy viewport geometry still add work.

Removing a receiver link leaves its area inactive with its borders preserved. Relinking the same node restores eligibility. An area with paint cannot silently change target. Changes to target geometry/topology require restoring that geometry or creating a new area; the previous completed scatter remains available after a failed update. Use saved scene units on reopen.

The new engine bounds contour vertices and prepared feedback. A failed edit leaves the preceding region intact; feedback never silently publishes a truncated successor. See [current limits and actual qualification](plans/preset-gallery-improvements/DELIVERY_0866.md) before treating scripted results as physical-input certification.

## Area limits, transforms and spacing

Include/Exclude splines are layer-wide world-XY masks. Include shapes form the allowed domain; Exclude wins in overlaps. Unlinking a shape keeps the scene spline. These rules constrain vector painting as well as ordinary scattering. New Area links select their row and default to Include. Selected area mode follows the highlighted rows; mixed modes show neither option selected, and no selection disables the control.

Advanced Analyzer Area can use a center-line band and/or point-radius discs. Together they form a union. Its Analyzer reference is separate from Layout's Analyzer and from the falloff Analyzer. Width is the full line-band width; point radius is not model collision radius.

Edge falloff can target an Analyzer boundary or one selected area line. Each area line retains its own delete strip, density ramp and scale ramp. Ramps start after the delete strip. Graph edits save as they are edited; Close is not Cancel. Physical graph-handle interaction remains a separate artist test.

Transforms show X Min/Max, Y Min/Max and Z Min/Max side by side for rotation, scale and movement, plus uniform scale. Reset actions reset their respective controls. **Keep on surface** controls movement projection. **Orientation > Mode** offers Random, World direction and Look at target. World direction is a full 3D vector; its length is irrelevant and it must be nonzero. Look at target aims toward the picked object's world pivot. Models use local +Z up and their **Models & Points > Forward axis**. Local random rotations still apply; zero their ranges for an exact heading.

**Align to normal / Normal %** chooses preferred up: disabled or 0% uses world +Z, 100% uses the geometric face normal, and intermediate values blend angularly. In direction modes this controls roll while preserving the heading. Slope eligibility stays independent. Coincident targets and parallel heading/up have deterministic fallbacks. Missing targets/zero vectors report an error and keep the last complete plants. Manual waits for Update; Live follows relevant target/parent or orientation animation. Target geometry changes with an unchanged pivot do not recalculate scatter. See the [orientation guide and limits](plans/improvement-program/I04_0830.md).

New complete recipes use format 8; numeric settings presets remain format 3 and edit their existing layer-owned categories. Source clearance does not add a numeric-preset category. Earlier complete formats retain their versioned defaults: formats 1/2/3 receive Surface random, formats 1/2 retain their original receiver variation, and format 1 receives neutral orientation. Reading never rewrites files or Paint. Grid distances convert with scene units. Explicit target bindings still apply.

Fresh ordinary layers expose Within this layer and Between layers spacing. Clearance is **factor × (radius A + radius B) + gap**. XY ignores vertical distance; 3D includes it. Each relationship has its own settings. Per-instance radius overrides belong to stable instance identities; generator changes can require an explicit clear instead of silently rebinding edits.

Candidate Relax moves candidates within its bounded settings. Cleanup removes unprotected isolated plants or small islands using neighbor distance, minimum neighbors and minimum island size. Protected CS Edit placements can survive generation/cleanup and create reported conflicts. Retry cleanup gaps is a separate population-policy choice.

## Preview, updates, output and diagnostics

Point Cloud, Proxy and Mesh serve different preview costs. Layer/model/Band identification colors help identify planting in simplified previews. **Color by Bands** uses the accepted Band owner, including when one source belongs to several Bands. These identification colors do not replace source render materials. Display limits can show fewer instances or faces than the accepted population. A displayed count is not the full output count. Box, Sphere and Pyramid proxies use retained instanced geometry. In **Viewport & render**, **Navigating** applies while moving the view or holding an interaction; **Idle** returns after a short pause. Point Cloud and Centres limits count points, Proxy limits count instances, and Mesh limits count triangles across this controller's visible layers. Both fields accept **0 = unlimited**. These caps affect the preview only; Update and final render retain the full accepted population.

The cache prepares for both settings within its resource allowance, so navigation can be lower or higher than idle. An oversized Point Cloud request uses a bounded sample and reports the memory reduction; switching from Proxy or Mesh returns to points even with both point limits at zero. Current-publication representations are reused across mode changes. Mesh switches to cached boxes for sources that cannot fit their artist-selected triangle share. Zero does not disable memory/input safeguards. Cached geometry counts can exceed the drawn amount. Changing a display limit or moving the camera does not publish pending Manual edits.

**Viewport & render > Viewport memory…** selects **Automatic** or a **Custom** allowance in MiB. It is shared by Scatter objects in that Max installation and saved outside the scene. **Apply** changes future resource admission while retaining existing display resources and Undo history. **Refresh display** retries presentation using published placements; pending Manual edits remain pending. A rejected Mesh successor keeps the previous complete display when available and reports the failure. Lowering the allowance below current usage can prevent subsequent allocations until resources are released. The displayed usage is an estimate of owned CPU and graphics resources, not measured free VRAM. Native system-headroom and graphics safety limits still apply; this preference does not control placement calculation or Auto Radius. See the [current qualification and limits](plans/edit-instances/DELIVERY_0869.md) and [original memory evidence](plans/code-quality/DELIVERY_08687.md).

Within Spline Bands, **Preview Falloff** shows bounded density samples on the receiving surfaces; blue is 0% and red is 100%. **Show Boundaries** independently draws white contour lines. **Field view** selects the highlighted Band's contribution or **Combined density**. The label reports sample/face counts: this is approximate coverage, not a fully shaded receiver or the final plant count. It describes the Band stage before other masks, spacing and cleanup. These samples and lines never become render output.

In Manual mode, field feedback can follow edited or animated Paths/receivers while plants and collision radii stay at the last Update. The label then reads **Pending field; plants from last Update**. Toggling feedback or selecting another Band does not publish placements. An uncached Mesh/Point Cloud mode cannot consume changed source geometry alongside the old publication; it retains the previous display and requests Update.

Manual stores edits until an explicit calculation action. **Update scatter**, **Refresh preview** and **Refresh areas / preview** update the whole Scatter setup and can publish pending Manual edits. **Read cached statistics**, **Read recording status** and **Refresh fields** only read the existing state. Passive browsing, area/layer selection and unrelated animation must not publish pending placements. Live responds to relevant input changes. Display-only settings can refresh presentation without changing placement generation. A failed successor retains the previous complete result and exposes an error.

**Radii / layer**, **Show All Radii**, per-source **Show Radius** and the XY/3D display choice refresh only the preview. Their Undo/Redo leaves pending Manual population/radius edits unapplied. XY draws a circle; 3D draws three perpendicular circles using the published spatial radius. Radius and field lines share a bounded cached display bundle. The display metric does not change the independently chosen metric of a spacing rule.

Automatic final render uses the render bridge; exact output and baking use source mappings and placement transforms. A successful preview does not certify every renderer/material/export path. Remove baked output removes owned baked nodes, not original sources.

Statistics identifies the selected layer by its name and describes its last completed calculation: requested count, candidates considered for spacing, accepted placements, rejections, protected conflicts and target shortfall. Prepared cloud points, centres, proxy instances or mesh instances describe the cached representation. They are not current-frame draw counts; viewport limits can display less detail without changing the accepted planting.

**Marked for Update** means the layer has been invalidated; reading statistics does not compare or apply pending settings. In Manual, use **Update scatter** to apply them. A successful zero result is distinct from a layer with no completed calculation. A failed update reports whether a previous result is retained and shows the error. **Read cached statistics** reads these cached values without regenerating placements. Exact host evidence and pending physical acceptance are tracked in the phase records.

Diagnostic recording is local, bounded and off by default. Start, Stop and Save report are separate from sending a report anywhere.

Surface Analyzer is independently versioned at 0.14.1 and has its own Manual/Real-time mode. It analyzes supported open planar mesh elements, produces boundaries/paths/points, and can export spline/helper snapshots. It does not support a closed sphere as an ordinary planar analysis input; general curved-surface scattering remains separate; the surface brush is a separate system and supports the curved receivers described above. Updating a Manual Analyzer does not authorize a pending Manual Scatter publication.

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

## Diagnostic timings in 0.82.6

From 0.82.6, saved reports include call counts, total time, longest time and failed-stage counts for input extraction, candidates, masks, transforms/radii, spacing, preview preparation, uploads, publication and panel work. Times are inclusive: a parent can contain another measured stage, so do not add all totals together. Action IDs connect an edit to invalidation and its deferred publication; unrelated host activity can have no action ID. The selected-setup snapshot reads cached requested/accepted/prepared counts and pending flags without evaluating the scene. These timings do not measure presented viewport FPS.

## Edit instances in 0.86.9

**Cyrus Scatter Edit > Instances** uses **Viewport & render > Color by**:
Model, Layer or Bands. Selected handles keep a colour accent with contrasting
selection marks. A handle marks the source pivot at its final accepted position;
it does not mark the trunk or automatically recenter a model. The library Orange
Tree has geometry offset from its pivot, so its trunk can remain beside a correct
handle. Changing the source pivot intentionally changes placement semantics.

In **0.86.9.2**, the selected handle and Move gizmo follow your drag immediately.
The complete scatter display commits after release, so heavy geometry can still
take time to finish presenting. The previous complete display may remain briefly
while that work finishes. Undo, Redo and Cancel preserve their existing behavior;
you do not need to delete and recreate Edit to receive this feedback fix.

Remove sources through **Models & Points**. Edits belonging to the removed model
remain saved and inactive. Matching surviving instances keep their edits; a
replacement model cannot inherit them merely by taking the same list position.
Undo restores the original compatible setup. Re-adding the original scene node
can recover its history when the generation and source settings still match;
a different node with the same name is a different source. Point and gap entries
also retain identity when another row is removed.

In Manual mode, removal changes the authored list while the previous result
stays visible until **Update scatter**. In Live mode the normal update runs.
Per-instance radius values keep their own saved ownership, including inactive
values. Seed or receiver-geometry changes still require the matching setup;
the plugin will not guess where old edits belong. **Reset all edits** clears
the whole modifier and supports Undo. It is not required for ordinary removal.

If a viewport successor fails, the complete preceding display and its handles
stay together. Refresh the display or restore the matching setup before making
another instance transform or selected-radius change.

Existing supported scenes load without an automatic reset. Save a new upgraded
copy and keep the original: source-aware Edit data saved by 0.86.9 requires
0.86.9 or later. See the [current delivery evidence and limits](plans/edit-instances/DELIVERY_08692.md) and [original source-aware Edit qualification](plans/edit-instances/DELIVERY_0869.md).

## Copy and recipe variation (0.84.0)

In Layers, **Copy variation** selects **Same variation** (default) or **New variation** for the next Copy. Both create independent owners, source correspondence and Paint Areas. Same keeps the receiver random inputs; New chooses fresh inputs once. Changing this choice does not calculate anything. Named Copy rejects authored Scatter Edit or per-instance radius overrides until their transfer is supported; Max object Copy duplicates the complete setup instead.

Full-object Copy has a pre-existing limit when an upper Edit modifier modifies
clones made by a lower Edit modifier, or a radius override targets a cloned
instance. Those cross-reference IDs need additional remapping. Preserve the
original setup; do not use that copied-stack route to transfer those edits.
Ordinary editing, Undo and saving/reopening the original stack are separate.

For example, duplicate a tree in the first Edit modifier, then move that duplicate
in a second Edit modifier above it. Copying the whole Scatter object currently
gives the duplicate a new internal ID, while the second modifier remembers the
old one. The copied arrangement can lose that movement; a deleted duplicate can
reappear or a further copy can be missing. A custom radius on a cloned instance
can lose its connection even with only one Edit modifier. The tested ordinary
single-Edit Copy case does not establish support for these combinations. The
required coordinated Copy repair is tracked as [B37](BACKLOG.md#edit-instance-findings--0869).

In Recipes, **Saved variation** keeps the saved random inputs while remapping ownership. An identical result also requires matching evaluated terrain, receiver order/history, quotas, source order/weights, masks, Relax and collision context. Replacing models or terrain can change accepted placements. This is not a promise that source reordering or arbitrary terrain changes retain the arrangement. Paint still requires compatible geometry, frame and units.

Amount settings presets offer **Saved seed**, **Keep current seed**, or **New seed** on Apply. They are numeric presets, not a complete arrangement. Redo restores the selected seed/domain rather than rerolling it. Manual mode waits for Update; Live reacts through normal dependency handling.

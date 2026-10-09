# Cyrus Scatter

**Current development build: Cyrus Scatter 0.75.** See the [workflow consolidation report](../docs/Consolidation_0.75_2026-10-09/README.md) for changes, exact tests and remaining work, and the [repository guide](../README.md) for engine/MCP boundaries. Historical notes below describe their original versions.

**Historical engine baseline: 0.64.** The notes below describe earlier engine work and are not a complete inventory of today's features. Mesh shares source geometry and exact instance transforms with retained Nitrous GPU buffers. Point Cloud retention, bounded CPU computation, prepared proxy batches and deferred synchronization remain. The [0.64 candidate guide](../docs/Retained_Mesh_Preview_2026-10-02/README.md) records its installation, measurements and Max 2026/2027 qualification limits.

The [retained-point experiment](../docs/Heavy_Scene_Viewport_2026-10-02/RESULTS.md) preceded the current [production-code integration](../docs/Retained_Point_Preview_2026-10-02/RESULTS.md). Point Cloud / Proxy / Mesh remain the display modes; automatic camera-dependent detail is still future work.

## Historical changes: 0.59 and earlier

0.59: sub-object selection and Modify display changes no longer invalidate geometry. Analyzer output revisions are checked before overlap dependency propagation. See [Selection-0.59-fix.md](Selection-0.59-fix.md).

Performance update: lazy layer UI, release-time updates, shared blocker cache and coalesced IR rebuilds. See [Performance-0.58-guide.md](Performance-0.58-guide.md).

Adds Point Cloud / Proxy (Box, Sphere, Cone) / Mesh display modes; see [Viewport-display-guide.md](Viewport-display-guide.md). Also includes ordered **Edge Border** rows with spacing, inward offset, deterministic along/across jitter and independent facing controls. See [Edge-Border-guide.md](Edge-Border-guide.md). Includes 0.41 boundary facing and the 0.40 CS Edit stack fixes.

## Historical release notes: 0.20

Install CyrusScatter-0.20.mzp through Scripting > Run Script, then restart Max.
Create > Geometry > Cyrus > Cyrus Scatter. All controls remain inside Modify.

## New in 0.20: Inside / Outside and per-row layer checkboxes

Pick a closed path in Diversity / Colors > Line Pattern. Add Outside creates a
stroke outward from the path; Add Inside creates one inward. Both sides accumulate
width separately per path, even when inside and outside strokes are interleaved.
For example, Outside 50 cm, Inside 40 cm, Outside 80 cm, Inside 60 cm gives outward
bands 0–50 and 50–130 cm, and inward bands 0–40 and 40–100 cm. Each keeps its own
sources/color groups and scale range. Uncovered regions remain empty. Inside
widths stop naturally where there is no remaining interior area; distances remain
world XY and do not depend on clockwise/counterclockwise spline direction.

Layer Manager now has a checkbox on each layer row. Click the checkbox to enable
or disable that layer in viewport and render; click its name to select it for
rename/removal. Checkbox changes support undo/redo and are stored in the scene.
Existing strokes load as Outside so previously saved scenes keep their behavior.

## Changed in 0.19: stroke-only output

Line Pattern only emits placements inside its stroke bands. Outside the last
stroke, inside the closed path, or with no strokes, there is no scatter output.
The legacy Rest of surface control is removed and its saved value is ignored.
This applies to viewport and render output, including existing scenes.
Count/density still generates surface candidates; stroke filtering can reduce
the final number. Random and Cluster modes retain their previous behavior.

## New in 0.18: consecutive line strokes

The separate Line Pattern rollout is merged into Diversity / Colors. Random,
Clusters and Line Pattern are three source-assignment modes. Only the chosen
mode's controls are shown. Nested layer padding has been reduced and containers
are explicitly aligned.

Choose Line Pattern, pick a closed spline under Paths, and click Add Stroke.
Each stroke has an incremental width, multiple selectable Color groups or Source
objects (Ctrl/Shift), and independent Scale min/max multipliers. For example,
50 cm + 80 cm + 40 cm produces bands at 0–50, 50–130 and 130–170 cm outside the
closed line. Removing or resizing a stroke shifts the following band boundaries.
Outside all strokes is empty; no fallback source is scattered. Grouped objects retain their
source-group colors in point clouds.

Stroke widths and source assignments do not regenerate or move the placement
points that remain inside the strokes. Points outside the strokes are discarded without refilling. Scale multiplies the layer's XYZ scale; it uses its own deterministic
random stream. Overlapping paths follow stroke-list priority (first match wins).
Shapes must be closed and are measured in world XY, as in previous Line Pattern
versions. Existing single-band scenes migrate without changing their widths.

## Hierarchy

A new controller has no layers. Its four global categories are Update, Surface
Scatter, Viewport and Render, and Layer Manager. Add Layer creates an independent
expandable layer below Layer Manager; up to ten layers can coexist. Remove Layer
can remove the last layer, returning to the empty state. Select a row to rename,
enable/disable or remove that layer.

Each layer has its own Source Object, Point Generation, Area, Diversity / Colors,
Randomize XYZ panels (Line Pattern is inside Diversity). Several layers and their settings can stay
open simultaneously. Editing a layer addresses its stored object directly; there
is no shared active-layer editor or copying of parameters when selecting a row.
Existing layers retain their expanded/collapsed state when adding another layer.

The surface list, Manual/Real-time update mode, point-cloud display, points per
plant, solid/group colors and automatic render setting are shared. The viewport
point limit is divided between enabled layers to cap the aggregate point cloud.
Count, density, sources, color IDs, textures, area masks, line patterns, transforms
and seeds remain independent per layer. Update now refreshes all enabled layers.

Old saved scenes migrate their former active editor and inactive layers to the
new layer records. Existing ClassID, engine name, internal identifiers and install
paths are retained for compatibility. The user-facing name/category is Cyrus.
The 0.18 engine adds source subsets and scale multipliers to line strokes; cached point-cloud drawing is retained.

## Rendering and scope

Corona 14 was tested with two independent layers and with one disabled. The
viewport stays in Point Cloud mode. The automatic render callback creates temporary
render instances and removes them afterward; this is not a Corona-native instancer.
Corona 15 was not available for a production-render test. V-Ray is outside scope.
No UV Randomizer, painting or new proxy conversion feature was added here.

## Source maintenance

Edit tools/ui/templates and tools/ui/generate.cjs, then run
`node tools/ui/generate.cjs` from this source directory to regenerate
scripts/AminScatterObject.ms. There is a separate rollout declaration for each of
ten UI slots: MAXScript rollout declarations are singletons, so reusing one for
several visible layers would share controls. Runtime layer data is stored in
independent persistent Max objects, not scene nodes.

## New in 0.14: Line Pattern diversity

Choose Diversity > Line Pattern. In the separate Line pattern rollout, add a
Circle or closed spline with Select From Scene or viewport pick. Select a row,
set Width (enter `1m` for one meter), then choose Band group from existing Source
Object color IDs. Choose Rest of surface for all other placements. Width defaults
to one physical meter on adding a line, respecting the scene's system units.
Multiple selected rows share width/group edits; each row stores its own settings.

For a circle of radius 3m and width 1m, the outer ring from 3m to 4m gets Band
group. Inside the circle and beyond the ring get Rest group. Multiple source
objects sharing a chosen color are randomly selected within that group.
This assigns sources to existing points: positions, count, rotations and scales
are unchanged. Source Group Colors displays the assigned group in Point Cloud;
source materials still determine rendered appearance.

Lines must contain closed splines with a nonzero footprint in world XY. Distance
is measured in that Top projection after world transforms; height does not
matter. Curves are approximated with 64 samples per segment. Exact boundary
points belong to the closed interior and thus Rest; the outer width limit is
included. Nested contours use even-odd filling. This is an outside-only band,
not an open-path scatter or a 3D surface/geodesic distance tool. Classification
uses each placement pivot; source geometry can extend beyond band edges.

The first matching line in list order wins where bands overlap. Area Include /
Exclude still determines which placements exist before source assignment.
Deleted line references are ignored; no remaining bands means all use Rest.
Real-time tracks line transform and shape changes; Manual keeps the cached
preview until refreshed. Final rendering evaluates the current pattern.

Groups are stored as RGB IDs. If source colors change so a configured ID has no
source, reselect Band/Rest from available groups; Refresh source groups reloads
the dropdowns. Remove selected rows removes references, never the scene lines.

## New in 0.13: faster viewport point clouds

Preview transformation and point storage now run in C++. A transient, immutable
native cache holds positions grouped by source color. Redraw uses one native
call per scatter, sets render flags once and submits markers in groups, avoiding
per-point MAXScript calls, color conversions and nested script arrays. Existing
point budgets, sample positions, colors, Manual/Real-time and render behavior
are preserved. Changing Solid/Group color display does not rebuild placements.

This remains main-thread GraphicsWindow submission, not a new GPU-resident
Nitrous render-item implementation or a multithreaded scatter engine. There is
no automatic point reduction while navigating. The normal preview path no longer
exports per-point MAXScript values; previewPoints() remains a diagnostic export
and intentionally allocates those values only when explicitly called.

On this host in the 5,000-plant benchmark, 500,000 points in group-color mode
redrew in 10.05 ms versus 125.78 ms previously (20 full redraws, same scene).
Preview build time fell from 1,222.85 ms to 7.56 ms. These are timings for this
simple test scene, not an FPS guarantee for every scene or a Forest Pack comparison.

## New in 0.12: update modes, multiple surfaces and plants per square meter

Scatter surfaces is now a list with multi-selection, Add from scene, viewport pick
and Remove selected rows. Duplicate nodes are ignored. Removing a row does not
delete the scene object. Old single-surface scenes migrate to the list.
The combined evaluated world-space triangles are sampled by area; Count is a
total across all surfaces, not a separate count for each. Separate overlapping
surface nodes are counted separately; this is not a geometric union operation.

Update mode controls the viewport cache:
- Real-time (default): relevant surface/source/Area geometry, mapping and transform
  events invalidate the preview. Changes to parents and time are also tracked.
  A 150 ms quiet period batches edits; large previews are not guaranteed to update
  at interactive frame rates during continuous dragging. Unrelated nodes and
  an idle scene do not trigger geometry polling.
- Manual: keeps the last preview even after parameter or input edits. Use Update
  now or Refresh Point Cloud to rebuild. A new controller initializes once.
  Final rendering always evaluates current scene inputs, even in Manual mode.

Point generation Population:
- Count: a fixed total, with bounded refill inside permitted masks.
- Plants per m2: evaluated world area divided by actual system units per meter
  squared, multiplied by the entered density, rounded to the nearest integer.
  Node scale, geometry modifiers and surface-size edits affect physical area.
  For example 6 m2 + 2 m2 at 100/m2 produces 800 plants before masks.
  Area exclusions and texture density thin this candidate population without
  refilling rejected points, maintaining expected density on permitted regions.
  Small masked regions have statistical variation. The 100,000-plant ceiling
  remains; the status text marks density capping. Point limit only caps preview
  samples and does not change placement density.

## New in 0.11: higher limits and Area

Point limit: 500,000 (was 50,000); Points/plant: 10,000 (was 1,000).
Plant Count: 100,000 (was 10,000). Defaults remain conservative. These are ceilings,
not a performance guarantee; dense preview clouds and 100,000 temporary render
nodes cost additional processing and memory.

Area has a list with Select From Scene, pick closed shape, and Remove selected
rows. Select one or more rows and choose Include or Exclude. New entries default
to Include. Removal only removes the reference, not the line in the scene.
All splines in the shape must be closed. Circles, rectangles and closed Lines are
supported through evaluated ShapeObject geometry, including node transforms.

With no Include entries, the entire surface is eligible. Includes combine as a
union; Exclude overrides Include. Compound closed sub-splines within one shape
use even-odd filling (nested loops form holes). Boundaries count as inside, so
Exclude also removes boundary points. Deleted area nodes are ignored.

Masks use world XY projection (Top view); shape height does not matter. The final
placement pivot is tested after randomized movement. Plants can extend across a
boundary; this does not trim their geometry or test their full footprint. Curved
segments are approximated with 16 samples per segment. Shapes must have nonzero
XY footprint; use simple non-self-intersecting contours.

In Manual mode use Refresh areas / preview after editing lines. Render recomputes area
geometry automatically. Random and Texture Density both work with Area, and
Diversity remains independent. In Count mode, bounded rejection sampling tries up to 100 candidates
per requested plant; tiny or fully excluded areas may produce fewer or no plants.

## UI layout correction in 0.10

The actual native rollout content is 162 logical units wide, independently of
apparent unused space in the outer command panel. Wider controls were clipped.
All six rollouts now use explicit positions within that width, with side margins.
Rotation/scale/movement have Min and Max column headings, three axis rows and
fully visible spinner arrows. Source list, color swatch, dropdown, distribution,
diversity and preview controls use the same compact bounds.

Actual native rollout captures from 3ds Max were inspected at the host's display
scaling. This is a layout change only; placement and rendering code is unchanged.

## Other behavior

Source color selection now waits for the MultiListBox selectionEnd event.
The old selected event also fired for deselected rows, which could overwrite the
swatch with the previous source's color. Selecting rows never writes group colors.
Accepting the modal color picker saves once to the selected rows; Cancel makes no
change. Reuse a group applies to selected rows. Equal RGB colors form one group.

Rotation, Scale and Movement each display X/Y/Z rows with explicitly labelled
Min and Max fields. If Min rises above Max, Max follows; if Max falls below Min,
Min follows. Thus the interval stays valid and the scatter does not disappear.
Rotation changes orientation, not placement pivots. Rotation can swing an object
far from its pivot: prepare source pivots at their bases.

## Automatic final render

Automatic final render is enabled by default. Keep Point Cloud enabled and start
a normal production render. Pre-render creates geometry-sharing temporary Max
instances; post-render removes them and restores any old baked nodes' render flags.
Viewport redraw is suspended for that render session so temporary geometry does
not build a full viewport display. The point-cloud setting stays unchanged.

No Bake button is required for this workflow. Render-time instances still consume
memory for nodes, transforms and renderer data. This is a temporary-node bridge,
not a Corona-native procedural instancer or a zero-memory scatter implementation.
Normal successful render cleanup and repeated renders are tested; cancellation
cleanup is simulated separately and must not be confused with a manual VFB Stop
test. Reset/open also clean up transient state.

Existing manually baked instances in old scenes are not deleted automatically.
Use Remove old baked instances on their controller to remove its owned generated
nodes and return to automatic rendering with Point Cloud. Save any hand edits to
those baked nodes first. Automatic rendering suppresses their renderability for
the render session to avoid duplicates, then restores the previous flag.

Bake editable instances (optional) deliberately makes permanent scene instances
and disables Automatic final render for that controller. Use it only when you
want editable scene output. Removing an instance-list source does not delete it.

This release targets single-frame production renders. Corona 14 is tested on the
installed 14 Update 1 Hotfix 2 build. Corona 15, Interactive Rendering, animated
surfaces across a multi-frame session, motion blur and distributed rendering are
not validated. Temporary transforms are generated at pre-render time; this is
not a supported animated-surface solution. A renderer-specific integration is
needed for the full production feature set.

## Placement and preview

Point generation: Random (surface-area weighted) or Texture Density. Diversity:
Random, Clusters or Line Pattern. Cluster Size/Seed/Roughness/Blurry edge/Noise choose which
color group's member occupies an existing point; they do not change placements.
Group proportions are statistical, not exact quotas. Small surfaces with large
clusters may show one group. Group colors do not alter source materials.

Texture density uses a baked 128x128 image and surface UV channel 1 clamped to
0..1. Use a bitmap or 2D procedural map. Black rejects, white accepts. The target
count is filled using at most 100 candidates per plant; sparse masks may fall
short. Masks are evaluated before world-space movement. Arbitrary renderer-specific
3D shading contexts are not supported.

Scale multiplies object-space size. Source node transforms are replaced by the
scatter transforms; object offsets/materials are inherited. Movement uses world
XYZ, optionally projected to the surface. Controller position does not move scatter.
In Manual mode, refresh after editing source geometry. Refresh after changing a density map in either mode.

Point Cloud color: Solid Color or Source Group Colors. Display settings do not
change source group membership or rendering. Max preview points defaults to
20,000 (up to 500,000); Points/plant supports up to 10,000. Placement count limit is 100,000 per layer. Source proxy
conversion/support, and Paint remain unimplemented.

## Installation/build

0.15 reuses the 0.14 native engine in userScripts/AminScatter/bin14. Restart is
required for the updated scripted scene class and render callbacks. Uninstall.ms
removes startup, macro and plugin-path registration and render callbacks. Restart
before manually removing the plugin folder. Controller scenes need the plugin.

    cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -T "v143,version=14.38"
    cmake --build build --config Release
    ctest --test-dir build -C Release --output-on-failure

MAXSDK_ROOT overrides the SDK path. AMIN_BUILD_MAX=OFF builds core tests only.
Legacy AminScatter.ms is reference code and is not installed.

Selection event semantics:
https://help.autodesk.com/cloudhelp/2016/ENU/MAXScript-Help/files/GUID-DBFFD89F-A6DD-46DC-BE74-5B8CEEA5402C.htm
Render callback timing:
https://help.autodesk.com/cloudhelp/2021/ENU/3DSMax-MAXScript/files/GUID-E5BE0058-2216-4E0B-88AF-680CA58AAC73.htm









## 0.23 — native point spacing
Each layer has independent Collision / Relax controls. The C++ solver uses a spatial grid and triangle BVH; relaxation is bounded to 128 candidate neighbors per point per iteration, and collision thinning follows relaxation. This is currently a single-thread CPU solver. Radius is per placement, independent of source bounding boxes. Cross-layer collisions are not implemented.

Run `node tools/ui/generate.cjs` from this project directory to regenerate the UI, PFlow bridge and spacing bindings. The generator now includes `tools/ui/spacing.cjs` and `tools/ui/templates/pflow.ms`. Run both `scatter_core` and `scatter_spacing` CTest targets after native changes. The new host argument is optional, preserving the previous 17/18/24/26/27/28-argument APIs; 29 arguments include the six spacing controls.







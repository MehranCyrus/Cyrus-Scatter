"""Build the offline documentation model; never imports or runs the plugin.

Run from any directory. Refreshes docs/System_Map_2026-10-04/model.json and,
when present, only the system-data JSON block in mockups/system-map/index.html.
"""
from pathlib import Path
import ast
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "docs/System_Map_2026-10-04"
PAGE = ROOT / "mockups/system-map/index.html"
SCRIPT = "AminScatter/scripts/AminScatterObject.ms"
GUIDE = "docs/Classic_Layout_2026-10-04/ARTIST_GUIDE.md"
CAPS = "docs/Layers_First_2026-10-03/CAPABILITIES.md"
nodes, edges, lenses, stories = [], [], [], []


def ref(path, needle=None, label=None):
    lines = (ROOT / path).read_text(encoding="utf-8-sig").splitlines()
    matches = [i + 1 for i, s in enumerate(lines) if needle in s] if needle else [1]
    if not matches:
        raise ValueError(f"Missing evidence anchor: {path}: {needle}")
    return {"path": path, "line": matches[0], "label": label or Path(path).name}


def node(id, title, subtitle, category, owner, summary, effect, *, status="current", limits=(), refs=(), keywords=()):
    nodes.append(dict(id=id, title=title, subtitle=subtitle, category=category, owner=owner,
                      status=status, summary=summary, effect=effect, limits=list(limits),
                      controls=[], refs=list(refs) or [ref(GUIDE)], keywords=list(keywords)))


def edge(id, a, b, label, detail, type="affects"):
    edges.append(dict(id=id, **{"from": a, "to": b}, type=type, label=label, detail=detail))


node("controller", "Cyrus controller", "One procedural setup", "structure", "Scene",
     "The scene object owns receiving surfaces, logical layers, global update/display settings and cached results.",
     "Global settings reach the whole controller. Individual layer settings remain independent unless a spacing rule connects them.",
     refs=[ref(SCRIPT, "plugin simpleObject", "Controller class"), ref(GUIDE, "What belongs where")])
node("ui", "Native controls", "Authoring & ownership", "structure", "Modify panel",
     "The native Max panel flows from general controls and Layer Manager into each named layer's own feature sections.",
     "Controls write to an explicit controller, layer or selected set. Opening a section changes the interface, not the planting rules.",
     refs=[ref("AminScatter/tools/ui/layers-first.cjs"), ref("AminScatter/tools/ui/templates/layers-flow-helpers.ms")],
     keywords=["rollout", "dropdown", "layout", "generated", "MAXScript"])
node("receivers", "Receiving surfaces", "Where candidates live", "inputs", "Controller",
     "The shared receiving geometry supplies positions, normals and surface area for placement. Surface picking and the receiving-surfaces list live in General.",
     "Changing a receiver can change candidate positions, density counts, normals and Brush validity; dependent layers need an update.",
     limits=["Brush supports one static mesh receiver, including curved geometry. It is narrower in scope than ordinary receiver selection."],
     refs=[ref("AminScatter/tools/ui/templates/layers-flow-surface.ms"), ref(GUIDE, "static mesh")])
node("layers", "Logical layers", "Grass • Flowers • Trees", "structure", "Controller",
     "Each named layer owns a complete planting setup and one Base set. Additional paint sets are children of that layer.",
     "Copy duplicates the layer and its sets with new identities and independent paint histories. Removing a layer removes its children; Undo restores them.",
     limits=["Ten total population slots per controller. A Base set and every extra set each consume one slot."],
     refs=[ref("AminScatter/tools/ui/templates/logical-layers.ms"), ref("AminScatter/tools/ui/templates/layers-flow-manager.ms")])
node("sets", "Paint sets", "Independent assets & paint", "structure", "Logical layer",
     "Use Red, Blue and Yellow sets inside Flowers. Sets own their source lists and paint history, and share the parent's placement rules.",
     "Share weight divides the parent candidate budget before masking. Selecting a set switches Plant assets and Coverage / Brush only.",
     limits=["A set does not receive another full copy of the parent candidate budget.", "Base cannot be removed alone. Random and Clusters support multiple sets; Line Pattern and Analyzer assignment do not."],
     refs=[ref("AminScatter/tools/ui/templates/layers-first-sets.ms"), ref("AminScatter/tools/ui/templates/logical-layers.ms")])
node("sources", "Plant assets", "Models & weighted choices", "inputs", "Selected paint set",
     "The set references scene source objects. Relative weights control which eligible source is chosen; source colors also form cluster/assignment groups.",
     "Changing assets or weights changes source assignment and may affect display geometry, footprints and output. This is separate from the set's share weight.",
     refs=[ref(SCRIPT, 'rollout sourceUI_1 "Plant assets"')], keywords=["geometry", "trees", "models", "source weights"])
node("source-variation", "Source properties", "Scale, Z offset & radius", "inputs", "Source row in a paint set",
     "Each source has scale, Z offset, forward axis, collision radius, follows-scale and radius-display properties.",
     "These properties contribute to final instance transforms and, when selected, approximate footprint spacing. Show Radius changes the diagnostic overlay.",
     limits=["Footprint radii are approximations, not triangle-to-triangle collision tests."], refs=[ref(SCRIPT, "spinner sourceZSpin")])
node("placeholders", "Point / Empty assets", "Reserve a source choice", "inputs", "Source row in a paint set",
     "Point and Empty rows are explicit source types. A Point can later be replaced with an object; Empty represents a deliberate no-geometry choice.",
     "Point rows can participate in preview and spacing but are omitted from final output. Empty consumes a weighted source choice and is then removed, creating holes before spacing.",
     refs=[ref("AminScatter/tools/ui/point-source.cjs"), ref("AminScatter/tools/ui/empty.cjs")])
node("population", "Population & seed", "One shared candidate budget", "placement", "Logical layer",
     "Choose Count or plants per square metre. The seed controls repeatable candidate generation. Enabled set weights divide this budget.",
     "A higher budget offers more candidates; Area, painted density, spacing and cleanup can still reduce accepted plants. A count is not a guarantee of final occupancy.",
     limits=["Current UI caps Count at 100,000; density is also bounded per parent. Direct Edge Border generation has a separate 500,000-row guard, so this is not a universal final-output cap.", "Changing seed, count or set allocation can invalidate a CS Edit generation binding."],
     refs=[ref(SCRIPT, 'rollout distributionUI_1 "Population"'), ref(GUIDE, "candidate budget")])
node("density-map", "Texture density", "UV-based eligibility", "placement", "Logical layer",
     "Texture Density uses a map on UV channel 1. White favors density and black removes it; Invert swaps that interpretation.",
     "The map affects candidate eligibility before final spacing. It is distinct from a surface-attached Brush history.",
     limits=["The current map path samples the 0..1 UV domain. MCP cannot enroll or change density maps."],
     refs=[ref(SCRIPT, 'mapbutton densityButton'), ref(CAPS, "Population / parent")])
node("brush", "Coverage / Brush", "Paint a procedural mask", "placement", "Selected paint set",
     "Paint and Erase define where the selected set can accept candidates on its receiving surface. They do not place one plant per brush sample.",
     "Radius, strength, softness and Mask % change eligibility. Population still sets the absolute candidate budget; a small painted patch can yield few plants.",
     limits=["One static mesh receiver, flat or curved. Topology/target changes require checking or resetting the paint target.", "Point Relax is paused while an enabled set in the parent has an active Brush mask. Active Brush also requires projection for nonzero movement; free unprojected movement is rejected."],
     refs=[ref(SCRIPT, 'rollout brushUI_1'), ref("AminScatter/src/brush.cpp"), ref("AminScatter/tools/ui/templates/planting-brush.ms")])
node("brush-history", "Saved strokes", "Editable Paint / Erase history", "placement", "Selected paint set",
     "The set stores ordered strokes and their surface anchors. Selected strokes can be enabled, switched to Erase, resized, softened or deleted.",
     "Editing history reevaluates that mask, then the parent shared solve can affect sibling and neighboring layers. Fill and Empty set whole-mask coverage states.",
     limits=["This is procedural stroke storage, not a reusable bitmap-map export feature."],
     refs=[ref("AminScatter/src/brush_storage_plugin.cpp"), ref(SCRIPT, 'fn editStroke =')])
node("brush-feedback", "Brush feedback", "Tint or coverage samples", "viewport", "Selected paint set",
     "Coverage tint and coverage samples help you see the mask while painting. The overlay can be turned off or recolored.",
     "These samples show coverage, not final plants. Use Plant centres or placed statistics to inspect the accepted population.",
     refs=[ref(SCRIPT, 'dropdownlist overlayMode')])
node("areas", "Include / exclude", "Closed shapes in world XY", "placement", "Logical layer",
     "Closed area shapes restrict the parent and every child set. Includes define allowed regions; excludes remove regions, with exclusion winning in overlaps.",
     "Area eligibility constrains candidates before painted density and spacing. Closed-area generation may refill candidates inside the eligible region.",
     limits=["World XY projection is separate from Brush's surface-attached coverage. These are not arbitrary 3D volumes."],
     refs=[ref(SCRIPT, 'rollout areaUI_1'), ref(GUIDE, "Include/exclude")])
node("analyzer", "Surface Analyzer", "Paths, points & boundaries", "inputs", "Separate optional plugin",
     "Analyzer 0.14 derives boundaries, guide paths and sample points from planar mesh elements. Scatter consumes selected channels as Area masks or assignment guides.",
     "Fit radius is boundary clearance; Point radius is centre separation. Resolution and Relax steps affect the Analyzer calculation, not Scatter's Brush solver.",
     limits=["Analyzer can process separately oriented planar elements, but Scatter's Area adapter uses world XY.", "Analyzer assignment remains single-set only. Its native analysis is synchronous and single-threaded. A disabled active Analyzer input can suppress the layer result."],
     refs=[ref("CyrusSurfaceAnalyzer/README.md"), ref("AminScatter/src/analyzer_area_bridge.inc")],
     keywords=["fit radius", "point radius", "min points", "resolution", "ring factor", "min length", "method"])
node("falloff", "Edge falloff", "Delete, thin or scale edges", "placement", "Logical layer",
     "Use an Analyzer boundary or a selected Area line to define distance from an edge. Delete band, scale ramp and density ramp have separate widths.",
     "Delete/density can remove candidates; the scale graph changes surviving plant scale near boundaries, which can also affect scale-aware footprints.",
     refs=[ref(SCRIPT, 'dropdownlist fallTarget'), ref("AminScatter/src/boundary_falloff.inc")])
node("diversity", "Diversity / Colors", "Choose source patterns", "placement", "Logical layer",
     "Random assigns weighted sources. Clusters uses size, seed, roughness, blur and noise with source color groups to organize variations.",
     "Changes which source is assigned at a candidate and how source groups are distributed. The source chosen also supplies its transform and radius properties.",
     refs=[ref(SCRIPT, 'radiobuttons diversityRadio'), ref("AminScatter/src/cluster.inc")])
node("line-pattern", "Line & Analyzer patterns", "Bands, streets & borders", "placement", "Single-set logical layer",
     "Line Pattern and Analyze Surface assign sources along consecutive bands, paths or Analyzer channels. They include border jitter, corner and street controls.",
     "Band width, source/color-group choices, scale ranges, channel and local rotations change the guided source pattern.", status="limited",
     limits=["Only independent single-set layers support these modes; adding paint sets is rejected before mutation.", "Consecutive pattern strokes are separate from Brush Paint/Erase strokes."],
     refs=[ref(SCRIPT, 'dropdownlist analyzerChannel'), ref("AminScatter/tools/ui/templates/strokes.ms"), ref("AminScatter/src/edge_border.inc")])
node("randomize", "Randomize XYZ", "Rotation • scale • movement", "placement", "Logical layer",
     "Axis min/max ranges randomize rotation, XYZ scale and movement. Whole Scale adds uniform scaling; Keep on surface and Align to normal control surface handling.",
     "Changes final transforms and potentially footprint clearance. Reset Rotation, Scale, Whole Scale or Movement restores only that family with Undo.",
     refs=[ref(SCRIPT, 'rollout randomUI_1'), ref("AminScatter/tools/ui/random-reset.cjs")])
node("collision", "Within-layer collision", "Shared spacing across sets", "placement", "Logical layer",
     "Collision enforces 3D centre spacing over the accepted union of the parent's enabled sets. Minimum centre gap is twice the collision radius.",
     "Red and Blue flowers are checked together. Filtering and Edit-aware candidates precede the shared solve; rejected plants do not keep blocking other candidates.",
     limits=["This centre-radius test is not exact mesh collision. Protected manual edits survive; their conflicts are counted."], refs=[ref("AminScatter/src/group_spacing.cpp"), ref(GUIDE, "Within a layer")])
node("relax", "Point & Boundary Relax", "Conditional redistribution", "placement", "Logical layer",
     "Point Relax can improve spacing for supported unpainted generation. The controls set spacing, iterations and strength; Boundary Relax has its own movement limits.",
     "When supported, relaxation moves candidates before the relevant acceptance checks. A disabled compatibility path preserves values and reports why it is paused.", status="limited",
     limits=["Point Relax is paused for a parent with an active enabled Brush mask.", "Boundary Relax is paused under the shared-spacing policy. Neither is currently exposed for MCP mutation."],
     refs=[ref(SCRIPT, 'rollout spacingUI_1'), ref(GUIDE, "Point Relax")])
node("separation", "Between-layer spacing", "Pairs, priorities & footprints", "placement", "Pairs of logical layers",
     "Choose another layer, enable pair separation, then use centre distance or source footprints plus a gap. XY ignores height; 3D uses height too.",
     "Higher priority wins, with stable identity tie-breaking. The rule covers every set in both parents, so changing one parent can change the other.",
     limits=["Legacy blocker controls remain for older placement policy. Shared spacing is an explicit, undoable conversion for legacy scenes."],
     refs=[ref(SCRIPT, 'rollout separationUI_1'), ref("AminScatter/src/group_spacing.cpp")])
node("cleanup", "Final cleanup", "Neighbors & islands", "placement", "Logical layer",
     "Remove isolated plants using a neighbor radius, minimum neighbor count and minimum connected-island size.",
     "Cleanup evaluates the final accepted union of sibling sets: a Red plant and a Blue plant can count as neighbors. Protected manual edits survive. The cleaned union blocks later parents.",
     limits=["Cleanup uses persisted parent overlapPlanar. The shared pair's XY/3D checkbox edits a separate value; the current native shared-cleanup panel has no separate plane toggle."],
     refs=[ref("AminScatter/src/final.inc"), ref(GUIDE, "Cleanup uses"), ref("AminScatter/tools/ui/templates/logical-layers.ms", "fn cleanLogicalLayer")])
node("visibility", "Visibility vs enable", "Draw state vs participation", "structure", "Layer and paint set",
     "Visible/Show hides plants from the viewport. Enabled controls contribution to the procedural result.",
     "Hidden plants still take part in spacing and final output. Disabled plants contribute to neither; disabling a set redistributes its parent's shared budget.",
     refs=[ref(GUIDE, "Hidden layers"), ref("AminScatter/tools/ui/templates/logical-layers.ms")])
node("update", "Manual / real-time", "When work is calculated", "engine", "Controller",
     "Manual mode preserves a cached preview until Update now. Real-time responds to relevant changes; cached navigation remains separate from regeneration.",
     "An explicit update may rebuild other affected layers because shared spacing has cross-layer dependencies. Statistics identify pending/stale output.",
     limits=["Manual is not a zero-cost viewport mode: existing geometry still has to be drawn."],
     refs=[ref(SCRIPT, 'rollout updateUI'), ref("AminScatter/tools/ui/viewport-performance.cjs")])
node("placements", "Accepted placements", "IDs, sources & transforms", "engine", "Native engine + controller cache",
     "The solve publishes accepted rows with source identity and transforms after applicable masks, Edit state, spacing and cleanup.",
     "This shared placement result feeds preview and output. Requested candidates, eligible candidates, placed plants, shown instances and cloud samples are different counts.",
     refs=[ref("AminScatter/src/scatter.cpp"), ref("AminScatter/tools/ui/templates/planting-model.ms"), ref("AminScatter/src/group_spacing.cpp")])
node("edit", "CS Edit", "Instance-level adjustments", "engine", "Modifier / generation binding",
     "The Edit modifier keeps manual plant changes linked to generation identities. Shared spacing incorporates the effective edited candidate transforms and protection policy.",
     "Moved or deleted plants influence the effective result and blocking policy. Seed/count/set-allocation changes may conflict with the stored generation instead of silently deleting edits.",
     limits=["A manual override is not a procedural Brush stroke. MCP does not mutate Edit."],
     refs=[ref("AminScatter/src/cyrus_edit_stack.inc"), ref("AminScatter/src/cyrus_edit.cpp"), ref(GUIDE, "Manually edited")])
node("display", "Viewport mode", "How placements are drawn", "viewport", "Controller",
     "Select Point Cloud, Proxy, Mesh or Plant centres. These are representations of the cached placements with their own display limits.",
     "A display choice changes the visible representation. Lower displayed counts alone do not mean fewer final plants.",
     refs=[ref(SCRIPT, 'dropdownlist displayModeDrop'), ref("AminScatter/src/preview.cpp")])
node("points", "Point Cloud", "Many samples per plant", "viewport", "Controller display",
     "Samples describe source shape around each accepted placement. Points/plant and the shared point budget determine how much of the shape is visible.",
     "Increasing detail makes plants clearer but uses more point preparation, buffer memory and drawing work. Fixed budgets can undersample dense scenes.",
     limits=["No automatic camera-distance detail refinement is implemented."],
     refs=[ref("docs/Retained_Point_Preview_2026-10-02/README.md"), ref("AminScatter/src/point_display.cpp")])
node("proxy", "Proxy", "Box • sphere • pyramid", "viewport", "Controller display",
     "A lightweight primitive stands in for each shown plant. Cached world-space proxy batches reduce repeated submission work.",
     "Changing shape or limits changes preview cost and recognizability. This display mode is separate from renderer proxy asset files.",
     refs=[ref("AminScatter/src/preview_batches.inc"), ref("AminScatter/tools/ui/viewport-performance.cjs")])
node("mesh", "Mesh", "Retained instanced geometry", "viewport", "Controller display",
     "Draws evaluated viewport source geometry with shared source buffers and per-instance transforms through Nitrous.",
     "Source geometry is reused across instances in each group. Camera motion changes the view without rebuilding placement or uploading every source again.",
     limits=["Preview uses Cyrus solid/source colors and fixed face shading; it is not full renderer material/texture shading.", "No global source-buffer pool across controllers or per-plant spatial culling is implemented."],
     refs=[ref("AminScatter/src/mesh_display.inc"), ref("docs/Retained_Mesh_Preview_2026-10-02/README.md")])
node("centres", "Plant centres", "One marker per shown plant", "viewport", "Controller display",
     "Centre markers show plant placement rather than source-shape samples. They are useful when checking density and comparing placement with coverage feedback.",
     "This removes detailed shape drawing, subject to preview visibility and budgets. Brush overlay dots remain a separate kind of sample.",
     refs=[ref(SCRIPT, '"Plant centres"'), ref(GUIDE, "Plant centres")])
node("budgets", "Preview budgets", "Limit displayed work", "viewport", "Controller",
     "Point limit and Points/plant govern cloud detail. Instance/face limits bound Proxy and Mesh preview work. Limits are display controls, not new placement counts.",
     "Budget reductions can hide instances or shape samples while leaving final output unchanged. The point budget is shared across the controller's enabled populations. In Manual mode, mode/proxy/instance/face changes have a display-only refresh route; not every display-related control uses it.",
     refs=[ref(SCRIPT, "spinner instancesLimitSpin"), ref("docs/Retained_Point_Preview_2026-10-02/README.md", "budget still applies")])
node("radii", "Radius overlays", "Inspect spacing footprints", "viewport", "Source flags + controller limit",
     "Show Radius on a source exposes its spacing footprint. Radii/layer and Show All Radii control how many diagnostics are drawn.",
     "The overlay helps explain spacing. Setting a display cap to zero hides radii; it does not disable spacing calculations.",
     refs=[ref(SCRIPT, "spinner radiusLimitSpin"), ref(SCRIPT, "checkbox showRadiusCheck")])
node("retained", "Retained display cache", "Reuse buffers during navigation", "engine", "Transient native display owner",
     "Immutable Point Cloud snapshots and instanced Mesh buffers are published outside drawing. The viewport reuses them until relevant data changes.",
     "Navigation avoids repeating source extraction and buffer creation for an unchanged generation. Allocation/resource failures fall back to the existing drawing path.",
     limits=["Point payload caps: 64 MiB/generation, 128 MiB/process. Mesh payload caps: 512 MiB/generation, 1 GiB/process.", "Reservations are buffer-payload accounting, not measured total VRAM. Rendering many visible primitives still has a cost."],
     refs=[ref("AminScatter/src/point_display.cpp", "ownerByteLimit"), ref("AminScatter/tools/ui/retained-points.cjs")])
node("gpu", "GPU drawing", "Max Nitrous graphics", "engine", "Native viewport implementation",
     "Nitrous draws retained points and instanced meshes; an HLSL shader applies mesh instance transforms and the preview shading.",
     "This accelerates drawing after CPU-side preparation. It does not mean candidate generation, Brush or collision runs on CUDA/OpenCL.",
     refs=[ref("AminScatter/src/mesh_display.inc"), ref("AminScatter/src/point_display.cpp")])
node("workers", "CPU computation", "Bounded native workers", "engine", "Native algorithms",
     "Selected sufficiently large native workloads use synchronous bounded workers on owned geometry data. The calling thread also participates and joins the workers before returning; Max scene access stays on the host thread.",
     "Parallelism helps eligible calculation workloads, not every operation. Automatic thread participation is capped at four in the current executor.",
     limits=["It is not a fully asynchronous scene-evaluation engine. Analyzer remains synchronous and single-threaded."],
     refs=[ref("AminScatter/src/execution.cpp", "computeParticipants"), ref("AminScatter/include/execution.h", "No"), ref("AminScatter/src/scatter.cpp", "parallelThreshold"), ref("AminScatter/src/max_bridge.cpp", "native workers")])
node("output", "Final output / Bake", "Renderable scene transport", "output", "Controller / local Max actions",
     "Automatic final render uses the existing placement/output transport. Baked output is a separate generated scene artifact with its own cleanup action.",
     "Final output consumes enabled populations and their effective transforms; viewport sample/face limits are not the final geometry budget.",
     limits=["Renderer/Bake/Edit mutations are local actions; no MCP tool executes them. A layout map is not renderer qualification."],
     refs=[ref("AminScatter/tools/ui/templates/pflow.ms"), ref(SCRIPT, "autoRenderCheck")], keywords=["render", "bake", "Particle Flow", "PFlow"])
node("stats", "Statistics & state", "Requested ≠ placed ≠ shown", "output", "Cached controller/layer result",
     "Layer titles and detail controls report the last build: counts, build state, removed/shown data and errors where available.",
     "Use statistics to distinguish underfill from preview throttling. Pending Manual changes mean cached results may be stale; readout is not an FPS benchmark.",
     refs=[ref("AminScatter/tools/ui/templates/layers-first-details.ms"), ref("AminScatter/tools/ui/templates/layer-status-helpers.ms")])
node("persistence", "Scene persistence", "Parameters, strokes & edits", "engine", "MAX file / native storage",
     "Scene parameters, source links, Brush history and Edit data preserve procedural authoring. Disposable retained-display nodes and GPU resources are rebuilt.",
     "Save/open restores the editable setup, not serialized GPU pointers. MCP ownership/enrollment must be renewed after reopening a scene.",
     refs=[ref("AminScatter/src/brush_storage_plugin.cpp"), ref("AminScatter/src/cyrus_edit_storage.inc"), ref("AminScatter/tools/ui/retained-points.cjs")])
node("mcp", "MCP automation", "Nine typed tools", "automation", "Optional local package 1.1",
     "A separate Python MCP server lets an assistant inspect an enrolled scope and propose bounded changes through the Max host service.",
     "MCP calls existing Cyrus capabilities. It does not give the assistant arbitrary Max scripting or automatic scene-wide design knowledge.",
     limits=["Automation qualification is Max 2027.1; complex terrain, Brush-history mutation, Relax, Bake/Edit and ML are outside current scope."],
     refs=[ref("CyrusMCP/cyrus_mcp/server.py", "def make_server"), ref("CyrusMCP/README.md")])
node("enrollment", "Scene enrollment", "Artist selects allowed inputs", "automation", "Local automation panel",
     "The artist selects a site, source meshes and planting/protected regions, or grants read-only inspection of an existing Cyrus controller.",
     "The context exposes approved IDs, geometry summaries, units and revisions. Relevant external changes invalidate enrollment instead of silently expanding its scope.",
     limits=["Design scope: static horizontal convex site; up to 3 sources/layers and 2,000 aggregate candidates; other geometry/input budgets apply.", "Read-only inspection of existing layouts is broader than design enrollment and grants no mutation authority."],
     refs=[ref("CyrusMCP/README.md", "Supported boundary"), ref("CyrusMCP/cyrus_mcp/panel.py")])
node("plan", "Typed design plan", "Schema 2.0 + validation", "automation", "Assistant proposal / registry",
     "A validated plan selects enrolled sources and regions, counts/seeds, supported transforms, exclusions, pair rules, cleanup and display/update settings.",
     "Defaults normalize before the plan digest and local review. Conservative footprint masks can underfill; the plan chooses allow or reject explicitly.",
     limits=["No arbitrary properties, files or scripts. Brush sets/history, texture maps and advanced pattern settings are not mutation contracts."],
     refs=[ref("CyrusMCP/cyrus_mcp/settings.py", "LAYER_SETTINGS"), ref("CyrusMCP/cyrus_mcp/models.py"), ref("CyrusMCP/cyrus_mcp/contracts.py")])
node("approval", "Local approval", "Approve this exact proposal", "automation", "Artist in Max",
     "The artist reviews normalized settings in the automation panel and approves the exact validated proposal.",
     "Application requires that approval, matching scene revision and digest. A later refinement needs a new local approval.",
     refs=[ref("CyrusMCP/cyrus_mcp/service.py"), ref("CyrusMCP/README.md", "Approve displayed proposal")])
node("apply", "Apply & publish", "Owned result, bounded recovery", "automation", "Max host adapter",
     "An approved request creates or replaces only the automation-owned controller/layers/masks and publishes the effective final result.",
     "Operation IDs and idempotency handle uncertain retries; status must confirm completion. Local Undo/reject checks protect unrelated artist actions.",
     limits=["Two successful candidates per enrollment. A synchronous native solve is not interruptible mid-call."],
     refs=[ref("CyrusMCP/cyrus_mcp/max_host.py"), ref("CyrusMCP/cyrus_mcp/service.py"), ref("CyrusMCP/README.md", "Recovery and connection")])
node("configuration", "Configuration inspection", "What is actually configured", "automation", "Read-only MCP tool",
     "Reads effective parent/set membership, parameters, sources, pair rules and paint status for an enrolled or owned controller.",
     "Explains the current setup without regeneration. Seeing a native setting does not imply MCP can mutate it.",
     refs=[ref("CyrusMCP/cyrus_mcp/server.py", "def scatter_get_configuration")])
node("diagnostics", "Cached diagnostics", "Counts, errors & draw counters", "automation", "Read-only MCP tools",
     "Connection/status/diagnostic tools report host identity, scope, operations, cached build data and retained-display counters.",
     "This supports investigation without silently rebuilding the scene. Draw callbacks are not presented-frame FPS, and reserved bytes are not total VRAM.",
     refs=[ref("CyrusMCP/cyrus_mcp/server.py", "def scatter_get_diagnostics")])
node("capture", "Viewport capture", "Optional visual context", "automation", "Locally shared viewport",
     "An approved viewport image is paired with camera/revision/generation metadata so an assistant can inspect visible composition.",
     "Provides visual context alongside geometry summaries; it is not automatic semantic understanding of every building or object.",
     limits=["Opt-in sharing; two captures per enrollment, max 1,536-pixel long edge. It captures the viewport, not the desktop."],
     refs=[ref("CyrusMCP/cyrus_mcp/server.py", "def scene_capture_viewport")])
node("records", "Execution records", "Actual transforms + lineage", "automation", "Versioned export contract",
     "cyrus.execution/1.0 ties context and normalized plan to the receipt and actual published transforms/source identities. Correction records have explicit lineage rules.",
     "This is evidence for reproducibility and a future collector. Parameters alone are not treated as executed results or inferred artist labels.",
     limits=["Current session/generation exports, max 1.5 MiB. Training eligibility is false; there is no automatic collection or upload."],
     refs=[ref("CyrusMCP/cyrus_mcp/records.py"), ref(CAPS, "Future ML foundation")])
node("ml", "Learned design / ML", "Future research", "future", "Not implemented",
     "Reference-image learning, artistic composition models and training datasets are future capabilities. Current records supply only part of their provenance foundation.",
     "Would need consent, dataset design, explicit labels, evaluation and bounded integration before it could propose reliable greenery layouts.", status="planned",
     limits=["No trained model, inference, image-to-planting system or automatic CAD/PDF interpretation is implemented."],
     refs=[ref(CAPS, "Future ML foundation"), ref("CyrusMCP/cyrus_mcp/settings.py", "training_or_ml_inference")])
node("adaptive", "Adaptive point detail", "Future viewport work", "future", "Not implemented",
     "Camera-aware point detail, stable levels of detail and spatial culling are proposed ways to preserve distant coverage and close-up shape detail.",
     "Would select existing display data by projected size, with stability and bounded budgets; it should not regenerate scatter on camera motion.", status="planned",
     limits=["Current Point Cloud has fixed sampling/budgets. Retained drawing alone is not automatic LOD or unlimited FPS."],
     refs=[ref("docs/Retained_Point_Preview_2026-10-02/README.md", "Next loop")])
node("zones", "Semantic zones / map exchange", "Future integration", "future", "Not implemented as a unified system",
     "Artist-named grass/tree/shrub zones, reusable Brush-map exchange and richer CAD/PDF-driven design are planned integration work.",
     "Existing Area shapes, Brush histories and MCP regions are useful separate building blocks; they are not yet one semantic-zone contract.", status="planned",
     refs=[ref("docs/Artist_Zones_Integration_2026-10-03/README.md"), ref(CAPS, "Brush / set")])

# Causal connections. 'Owns' expresses parameter scope, not execution order.
edge("ui-controller", "ui", "controller", "authors", "Native controls bind to their explicit owning object.")
edge("controller-receivers", "controller", "receivers", "owns", "Receiving surfaces are shared controller inputs.", "owns")
edge("controller-layers", "controller", "layers", "owns", "A controller owns independent logical layers.", "owns")
edge("controller-update", "controller", "update", "owns", "Update mode is shared by the setup.", "owns")
edge("controller-display", "controller", "display", "owns", "Display mode and budgets are controller settings.", "owns")
edge("layers-sets", "layers", "sets", "contains", "A parent contains a Base set and optional extra paint sets.", "owns")
edge("layers-population", "layers", "population", "shared budget", "The layer owns one candidate budget for all enabled sets.", "owns")
for owned_id in ("areas", "diversity", "randomize", "collision", "separation", "cleanup", "relax", "visibility", "falloff", "density-map"):
    edge("layers-" + owned_id, "layers", owned_id, "parent rule", "The enclosing logical layer owns this setting for its sets. Pair rules connect logical parents; set visibility also has its own flag.", "owns")
edge("sets-sources", "sets", "sources", "owns assets", "Changing the selected set switches its source editor.", "owns")
edge("sets-brush", "sets", "brush", "owns mask", "Each set has independent paint/erase coverage.", "owns")
edge("sources-props", "sources", "source-variation", "per-source", "Source rows carry transforms, forward axes and radius metadata.", "owns")
edge("sources-placeholder", "sources", "placeholders", "source kinds", "Point and Empty are supported row types.", "owns")
edge("sources-diversity", "sources", "diversity", "weights / colors", "Source weights and color groups feed Random/Clusters assignment.", "feeds")
edge("receivers-population", "receivers", "population", "area / normals", "Receiver geometry determines sampling domain, surface normals and density area.", "feeds")
edge("receivers-placements", "receivers", "placements", "surface geometry", "Receiving meshes supply candidate positions and normals; population and eligibility rules determine the accepted result.", "feeds")
edge("receivers-brush", "receivers", "brush", "surface anchors", "Brush hits and saved samples bind to a receiving mesh.", "feeds")
edge("sets-population", "sets", "population", "share weights", "Enabled set weights divide the parent budget before masks.")
edge("population-placements", "population", "placements", "candidates", "Requested candidates enter generation; accepted counts may be lower.", "feeds")
edge("density-population", "density-map", "population", "UV density", "Texture density influences candidate acceptance in its supported path.")
edge("areas-placements", "areas", "placements", "allowed region", "Include/exclude eligibility limits candidates; exclude takes precedence.")
edge("analyzer-areas", "analyzer", "areas", "path / point masks", "Scatter Area consumes Analyzer line bands and point-radius masks in world XY.", "feeds")
edge("analyzer-pattern", "analyzer", "line-pattern", "guide channel", "Analyzer channels supply guided assignment for single-set layers.", "feeds")
edge("analyzer-falloff", "analyzer", "falloff", "boundary", "An Analyzer boundary can drive edge falloff.", "feeds")
edge("areas-falloff", "areas", "falloff", "selected edge", "A selected Area line can be the falloff target.", "feeds")
edge("falloff-placements", "falloff", "placements", "thin / scale", "Boundary delete/density/scale controls affect eligible rows and transforms.")
edge("brush-history", "brush-history", "brush", "replay strokes", "Enabled Paint/Erase strokes define the evaluated mask.", "feeds")
edge("brush-feedback", "brush", "brush-feedback", "show coverage", "Overlay data visualizes coverage rather than final placements.", "feeds")
edge("brush-placements", "brush", "placements", "mask candidates", "Painted eligibility filters candidates before shared spacing.")
edge("brush-relax", "brush", "relax", "pauses Point Relax", "An active mask in an enabled set pauses parent Point Relax.", "guards")
edge("sets-pattern", "sets", "line-pattern", "single-set guard", "Multi-set parents cannot use Line Pattern/Analyzer assignment.", "guards")
edge("diversity-placements", "diversity", "placements", "source IDs", "Assignment selects source identities and their properties.", "feeds")
edge("pattern-placements", "line-pattern", "placements", "guided sources", "Bands/channels affect source assignment and guided transforms.", "feeds")
edge("props-randomize", "source-variation", "randomize", "combined transforms", "Source properties contribute additional transformations; source scale and world-Z offset are applied after Brush and falloff.", "feeds")
edge("randomize-placements", "randomize", "placements", "transforms", "Random transform settings determine effective placement matrices.")
edge("props-separation", "source-variation", "separation", "footprint radii", "Footprints + gap uses source radius and scale-following policy.", "feeds")
edge("collision-placements", "collision", "placements", "within parent", "3D centre spacing rejects conflicts across the parent's accepted sets.")
edge("separation-placements", "separation", "placements", "between parents", "Pair distance and priority filter cross-layer conflicts.")
edge("separation-relax", "separation", "relax", "shared-policy guard", "Shared-spacing policy pauses Boundary Relax.", "guards")
edge("relax-placements", "relax", "placements", "when supported", "Supported unpainted relaxation modifies candidates before acceptance.")
edge("cleanup-placements", "cleanup", "placements", "final union", "Neighbor/island cleanup runs over each parent's accepted sibling-set union.")
edge("visibility-placements", "visibility", "placements", "enable affects solve", "Disabled populations do not contribute. Merely hidden populations remain participants.")
edge("visibility-display", "visibility", "display", "hide affects drawing", "Layer/set visibility filters viewport contribution without excluding final output.")
edge("update-placements", "update", "placements", "rebuild when due", "Manual waits for Update; live changes trigger the appropriate rebuild.")
edge("edit-placements", "edit", "placements", "effective edits", "Edited/deleted/protected candidate state participates in shared result construction.")
edge("population-edit", "population", "edit", "identity can change", "Changing count/seed/allocation can invalidate a generation binding.", "invalidates")
edge("workers-placements", "workers", "placements", "native execution", "Eligible owned-data workloads can run in bounded native parallel ranges.", "feeds")
edge("placements-display", "placements", "display", "cached result", "The viewport consumes completed placement/source snapshots.", "feeds")
edge("placements-output", "placements", "output", "enabled result", "Final output uses effective placements rather than the displayed sample count.", "feeds")
edge("placements-stats", "placements", "stats", "build results", "Completed builds update counts and state; statistics do not reconstruct geometry.", "feeds")
edge("display-points", "display", "points", "Point Cloud", "Select a source-shape point representation.", "affects")
edge("display-proxy", "display", "proxy", "Proxy", "Select a simplified primitive representation.", "affects")
edge("display-mesh", "display", "mesh", "Mesh", "Select evaluated viewport source geometry.", "affects")
edge("display-centres", "display", "centres", "centres", "Select centre markers rather than many samples per plant.", "affects")
edge("budgets-points", "budgets", "points", "sample limits", "Point limit and Points/plant bound cloud detail.")
edge("budgets-proxy", "budgets", "proxy", "instance limits", "Displayed instance/geometry limits bound proxy work.")
edge("budgets-mesh", "budgets", "mesh", "instance / face limits", "Mesh previews keep whole-instance geometry subject to the current budgets.")
edge("points-retained", "points", "retained", "point buffers", "Retained point snapshots avoid per-point resubmission from the old marker path.", "feeds")
edge("mesh-retained", "mesh", "retained", "instanced buffers", "Source geometry and instance matrices are retained in graphics buffers.", "feeds")
edge("retained-gpu", "retained", "gpu", "reuse each redraw", "Nitrous consumes retained data with the current view transform.", "feeds")
edge("props-radii", "source-variation", "radii", "show footprint", "Source radius and Show Radius feed the spacing overlay.", "feeds")
edge("radii-display", "radii", "display", "diagnostic overlay", "Overlay limits control diagnostic drawing only.")
edge("retained-stats", "retained", "stats", "upload / draw counters", "The display owner exposes bounded cache and draw diagnostics.", "feeds")
edge("controller-persistence", "controller", "persistence", "save authoring", "Parameters and references preserve the procedural setup.", "feeds")
edge("history-persistence", "brush-history", "persistence", "save strokes", "Brush storage persists ordered history and target identity.", "feeds")
edge("edit-persistence", "edit", "persistence", "save edits", "Edit storage preserves generation bindings and instance changes.", "feeds")
edge("persistence-retained", "persistence", "retained", "rebuild after open", "Transient display resources are rebuilt rather than serialized.")
edge("mcp-enrollment", "mcp", "enrollment", "explicit scope", "The artist decides which objects and operations are exposed.", "guards")
edge("enrollment-plan", "enrollment", "plan", "IDs / geometry", "Only enrolled references and supported typed fields are accepted.", "feeds")
edge("plan-approval", "plan", "approval", "normalized review", "The exact normalized proposal and digest are reviewed locally.", "feeds")
edge("approval-apply", "approval", "apply", "permits exact apply", "Approval plus fresh revisions gates one bounded mutation.", "guards")
edge("apply-controller", "apply", "controller", "owned setup", "The adapter creates or refines its owned procedural controller.")
edge("apply-placements", "apply", "placements", "solve / publish", "The same native placement system produces the applied result.", "feeds")
edge("controller-configuration", "controller", "configuration", "effective settings", "Read-only inspection reports parent/set settings without generation.", "feeds")
edge("stats-diagnostics", "stats", "diagnostics", "cached counts", "Diagnostic tools expose cached result state and errors.", "feeds")
edge("retained-diagnostics", "retained", "diagnostics", "cache counters", "Diagnostics can read retained-owner data without estimating FPS.", "feeds")
edge("display-capture", "display", "capture", "opt-in image", "A shared viewport image includes matching camera/generation metadata.", "feeds")
edge("enrollment-capture", "enrollment", "capture", "sharing permission", "Capture is admitted only when the local scope grants viewport sharing.", "guards")
edge("placements-records", "placements", "records", "actual transforms", "Export contains actual final rows, not an assumption from the requested plan.", "feeds")
edge("plan-records", "plan", "records", "plan provenance", "Normalized plan and context digests accompany the executed result.", "feeds")
edge("records-ml", "records", "ml", "possible foundation", "Future training needs separate consent, collection and evaluation; none runs now.", "future")
edge("adaptive-points", "adaptive", "points", "proposed LOD", "Future detail selection would improve wide/close quality within budgets.", "future")
edge("zones-areas", "zones", "areas", "future shared meaning", "A proposed zone contract could unify semantic area assignment.", "future")
edge("zones-mcp", "zones", "mcp", "future design input", "Rich zone/CAD/plan understanding is not part of current automation.", "future")


def lens(id, title, subtitle, description, rows, edge_ids):
    # 230 x 92 cards, four columns. Air between rows leaves label-routing room.
    positions = [{"id": n, "x": 30 + col * 270, "y": 42 + row * 166}
                 for row, group in enumerate(rows) for col, n in enumerate(group) if n]
    lenses.append(dict(id=id, title=title, subtitle=subtitle, description=description,
                       nodes=positions, edges=edge_ids.split(), width=1100,
                       height=max(360, len(rows)*166+50)))


lens("overview", "System overview", "From authoring to output",
     "Read left to right within each row. Lines show ownership or influence, not a strict execution schedule. Click any feature to inspect its incoming and outgoing connections.",
     [["controller", "layers", "sets", "brush"], ["receivers", "placements", "display", "output"]],
     "controller-receivers controller-layers layers-sets sets-brush receivers-placements brush-placements placements-display placements-output")
lens("layers", "Inside a layer", "Shared rules, independent paint",
     "A parent shares its Population, Area, transforms and spacing across its sets. Each set keeps separate assets and coverage. Select a rule to trace effects beyond this view.",
     [["layers", "sets", "sources", "source-variation"], ["population", "brush-history", "brush", "brush-feedback"],
      ["density-map", "areas", "falloff", "diversity"], ["visibility", "randomize", "collision", "separation"],
      ["cleanup", "relax", "line-pattern", "placeholders"]],
     "layers-sets layers-population layers-areas layers-diversity layers-randomize layers-collision layers-separation layers-cleanup layers-relax layers-visibility layers-falloff layers-density-map sets-sources sets-brush sets-population sources-props sources-placeholder sources-diversity brush-history brush-feedback density-population areas-falloff props-randomize props-separation brush-relax sets-pattern separation-relax")
lens("generation", "Placement logic", "What changes the result",
     "A dependency map, not one universal linear pipeline. In shared spacing, eligible candidates and effective edits feed collision/pair acceptance, then parent-union cleanup produces published placements. Conditional legacy paths differ.",
     [["receivers", "population", "areas", "density-map"], ["brush", "diversity", "falloff", "randomize"],
      ["edit", "collision", "separation", "cleanup"], ["update", "workers", "placements", "output"]],
     "receivers-population density-population population-placements areas-placements brush-placements diversity-placements falloff-placements randomize-placements edit-placements collision-placements separation-placements cleanup-placements population-edit update-placements workers-placements placements-output")
lens("viewport", "Viewport & performance", "Generate once; reuse while moving",
     "Display mode changes representation and budgets. Retained Point Cloud and Mesh reuse data during navigation. CPU generation, GPU drawing and final-render output are separate responsibilities.",
     [["placements", "display", "budgets", "visibility"], ["centres", "points", "mesh", "proxy"],
      ["radii", "retained", "gpu", "stats"], ["brush-feedback", "adaptive", "update", "output"]],
     "placements-display visibility-display display-centres display-points display-mesh display-proxy budgets-points budgets-mesh budgets-proxy points-retained mesh-retained retained-gpu retained-stats radii-display adaptive-points placements-output")
lens("automation", "Automation & future ML", "Observe → propose → approve → apply",
     "MCP 1.1 has nine tools and a bounded local scope. Inspection and actual-result exports exist today. Learned design, automatic CAD/PDF interpretation and Brush-history automation are not shipped.",
     [["mcp", "enrollment", "plan", "approval"], ["configuration", "diagnostics", "apply", "placements"],
      ["capture", "controller", "records", "ml"], ["zones", "stats", "retained", "display"]],
     "mcp-enrollment enrollment-plan plan-approval approval-apply apply-controller apply-placements controller-configuration stats-diagnostics retained-diagnostics enrollment-capture display-capture placements-records plan-records records-ml zones-mcp")
lens("code", "Code responsibilities", "Where the pieces are implemented",
     "Follow the implementation boundaries. Generated native controls bind authoring state; native algorithms produce placements; transient Nitrous owners draw them. Expand Evidence in the inspector for exact source anchors.",
     [["ui", "controller", "persistence", "mcp"], ["receivers", "workers", "edit", "analyzer"],
      ["update", "placements", "retained", "gpu"], ["brush-history", "output", "stats", "records"]],
     "ui-controller controller-receivers controller-update controller-persistence edit-persistence history-persistence persistence-retained update-placements workers-placements edit-placements placements-output placements-stats retained-gpu retained-stats placements-records")


def story(id, title, summary, lens_id, steps):
    stories.append(dict(id=id, title=title, summary=summary, lens=lens_id,
                        steps=[{"node": n, "text": t} for n, t in steps]))


story("paint-flowers", "Paint three flower colors", "Independent masks; shared planting rules.", "layers", [
    ("layers", "Create Flowers as one logical layer. Grass stays a separate layer."),
    ("sets", "Add Red, Blue and Yellow paint sets. Their weights share the Flowers budget."),
    ("sources", "Select each set and give it the matching source models."),
    ("brush", "Paint or erase each set's independent mask. A stroke defines coverage, not one plant per dot."),
    ("collision", "Flowers' collision rule checks all accepted flower sets together."),
    ("separation", "A Flowers–Grass pair rule manages separation between those parent layers.")])
story("underfill", "Why do I see fewer plants?", "Separate candidate loss from display limits.", "generation", [
    ("population", "Count is the candidate budget, split across enabled sets."),
    ("brush", "A small painted area accepts only candidates that survive its mask."),
    ("collision", "Within-layer spacing can reject close candidates."),
    ("cleanup", "Neighbor/island cleanup can remove accepted but isolated plants."),
    ("budgets", "Preview budgets can show fewer instances than the final placement result."),
    ("stats", "Compare requested, placed and shown. Point-cloud samples are not plant counts.")])
story("hide-disable", "Hide or disable a layer?", "One changes drawing; the other changes participation.", "layers", [
    ("visibility", "Uncheck Visible/Show to hide from the viewport. Leave Enabled on."),
    ("separation", "Hidden populations still participate in spacing and may block other plants."),
    ("output", "Hidden populations still contribute to final output."),
    ("visibility", "Disable instead to remove contribution to spacing and output."),
    ("population", "Disabling a set redistributes its parent's budget to the remaining enabled sets.")])
story("navigate", "What happens when I orbit?", "Drawing continues; placement should stay cached.", "viewport", [
    ("placements", "The generation has already supplied sources and transforms."),
    ("display", "The current display mode chooses how those plants are represented."),
    ("retained", "Unchanged Point Cloud/Mesh buffers are reused rather than rebuilt for every camera step."),
    ("gpu", "Nitrous draws them using the new view transform; visible geometry still costs work."),
    ("adaptive", "Automatic wide-to-close detail is future work, not what retained caching alone provides.")])
story("manual-edit", "Move a plant with CS Edit", "Manual changes keep identity and spacing semantics.", "generation", [
    ("edit", "CS Edit records instance changes against its generation binding."),
    ("placements", "Shared result construction uses effective edited positions and removal/protection state."),
    ("separation", "Edited candidates participate in the supported spacing/conflict policy."),
    ("population", "Changing seed, count or allocation can change identities."),
    ("edit", "The plugin reports a binding conflict instead of silently discarding edits; preserve/Undo or explicitly reset Edit.")])
story("ai", "Ask AI for a planting proposal", "Bounded automation, with an artist decision.", "automation", [
    ("enrollment", "In Max, enroll a supported site, source meshes and regions."),
    ("plan", "The assistant uses approved IDs to propose a typed plan and validates it."),
    ("approval", "You review and approve that exact normalized proposal in Max."),
    ("apply", "The host creates its owned procedural setup, solves and publishes actual rows."),
    ("records", "Export actual transforms with context/plan digests for reproducible evidence."),
    ("ml", "This does not train a model. Learned artistic design is a separate future system.")])
story("solve-order", "Follow the shared solve", "The actual order behind the dependency graph.", "generation", [
    ("population", "1. Split the parent count/density among enabled sets by share weight; derive effective seeds."),
    ("receivers", "2. Sample surface triangles and optional texture density, then apply movement/reprojection and XY include/exclude. Count may retry rejects; density follows a different sampling policy."),
    ("diversity", "3. Assign weighted/cluster/pattern sources and build the normal/rotation/scale basis. Supported unpainted Relax follows; native per-set collision is deferred under shared spacing."),
    ("falloff", "4. Apply Whole Scale, Analyzer Area and edge deletion/density/scale falloff."),
    ("brush", "5. Filter candidate anchors through the set's Brush mask. Painted rejection does not refill its candidate share."),
    ("source-variation", "6. Drop Empty-source rows, apply source scale and world-Z offset, then supported Analyzer outward orientation."),
    ("edit", "7. Apply the active CS Edit stack. Manual edited rows receive protected metadata."),
    ("separation", "8. Resolve shared collision and pair rules in priority/stable-identity order. Protected manual rows survive and conflicts are counted."),
    ("cleanup", "9. Clean the accepted sibling-set union after a parent finishes. The cleaned union blocks subsequent parents."),
    ("placements", "10. Publish the completed result only after all enabled groups succeed. Preview applies display limits; final output omits Point-only rows. Legacy policy has a different order.")])

# Main-panel inventory uses each feature definition once, not its ten generated copies.
native = json.loads((ROOT / "AminScatter/tools/ui/layers-control-inventory.json").read_text())
source_lines = (ROOT / SCRIPT).read_text(encoding="utf-8-sig").splitlines()
section_rollout = {"host": "mainUI", "surface": "surfaceUI", "manager": "layersUI"}
section_default = {"host": "controller", "updateUI": "update", "previewUI": "display",
                   "surface": "receivers", "manager": "layers", "sourceUI": "sources",
                   "distributionUI": "population", "brushUI": "brush", "areaUI": "areas",
                   "diversityUI": "diversity", "randomUI": "randomize", "spacingUI": "collision",
                   "separationUI": "separation", "setsUI": "sets", "detailsUI": "stats"}
by_id = {n["id"]: n for n in nodes}
overrides = {}


def controls(section, node_id, items):
    for key, explanation in items.items():
        overrides[(section, key)] = (node_id, explanation)


controls("host", "controller", {"enabledCheck": "Enable or disable the entire Cyrus setup."})
controls("updateUI", "update", {"updateRadio": "Choose cached Manual updates or real-time response to changes.", "updateNow": "Rebuild the current planting result, including affected dependencies."})
controls("surface", "receivers", {"sharedPick": "Pick the shared receiving mesh.", "surfacesButton": "Open the receiving-surfaces list for the setup."})
controls("surface", "separation", {"policyButton": "Show the active spacing policy or explicitly convert a legacy setup to shared spacing with Undo."})
controls("manager", "layers", {"layerList": "Select a layer; double-click to open its feature editor.", "addButton": "Create a named parent layer with a Base set if capacity permits.", "copyButton": "Copy the selected layer and all its sets with independent identities and histories.", "removeButton": "Remove the parent and its child sets with Undo.", "nameEdit": "Rename the selected logical layer."})
controls("manager", "visibility", {"visibleCheck": "Show or hide this parent in the viewport; hidden plants still participate and render.", "enabledCheck": "Enable/disable this parent's contribution to spacing and final output."})
controls("setsUI", "sets", {"setList": "Choose which child set is edited by Plant assets and Brush.", "addButton": "Add a paint set within the ten-total-population capacity and compatible assignment modes.", "removeButton": "Remove a non-Base paint set and its history with Undo.", "nameEdit": "Rename this paint set.", "weightSpin": "Change this set's relative share of the parent candidate budget."})
controls("setsUI", "visibility", {"enabledCheck": "Enable/disable the set's contribution; disabled sets relinquish their budget share.", "visibleCheck": "Hide/show this set in the viewport without removing it from spacing or final output."})
controls("sourceUI", "sources", {"plantList": "Select source rows; Ctrl/Shift selects multiple.", "selectFromScene": "Choose source objects using a scene-selection dialog.", "addPlant": "Pick a source model in the viewport.", "addSelected": "Add supported currently selected scene objects as sources.", "removePlant": "Remove selected source references from this set; this is not source-object deletion.", "selectPlant": "Select the referenced source objects in the Max scene.", "existingGroups": "Reuse an existing cluster color group for selected source rows.", "groupColor": "Choose a color group for selected sources.", "applyColor": "Apply the chosen group color to selected rows.", "weightSpin": "Set relative source-choice weight inside this set; zero excludes the source choice."})
controls("sourceUI", "placeholders", {"addPoint": "Add a point-placeholder source row.", "addEmpty": "Add an explicit Empty source choice.", "replacePoint": "Replace exactly one selected Point placeholder row with a picked source object."})
controls("sourceUI", "source-variation", {"sourceZSpin": "Offset the source along world Z after Brush masking; this can lift it off the receiver.", "sourceScaleSpin": "Multiply the accepted instance basis by this source scale after coverage/falloff; 1 adds no source multiplier.", "radiusSourceSpin": "Set the approximate source footprint radius used by footprint rules.", "followRadiusCheck": "Let effective footprint radius follow source/instance scale.", "showRadiusCheck": "Show this source's radius overlay, subject to global overlay limits.", "forwardAxis": "Choose +Y, -Y, +X or -X as the source forward direction."})
controls("distributionUI", "population", {"modeRadio": "Select Random or Texture Density generation.", "populationRadio": "Select fixed candidate Count or plants per square metre.", "countSpin": "Set candidate count before painted coverage and spacing.", "densitySpin": "Set density used to derive a bounded shared parent candidate count.", "seedSpin": "Change deterministic placement randomness and potentially Edit identities."})
controls("distributionUI", "density-map", {"densityButton": "Assign a density map sampled in the supported UV channel-1 path.", "invertCheck": "Invert density-map values so black/white swap density behavior."})
controls("distributionUI", "centres", {"showCenterCheck": "Legacy plant-centre preview control; hidden under shared spacing in favor of the global display choice."})
controls("brushUI", "brush", {"coverageMode": "Use the whole shared receiver or the saved painted mask; Whole surface retains strokes.", "modeRadio": "Choose Paint or Erase for the next stroke.", "radiusSpin": "Set the world-space radius for subsequent strokes.", "strengthSpin": "Set the strength for subsequent strokes.", "softSpin": "Set the edge softness for subsequent strokes.", "densitySpin": "Thin mask-eligible plants; this is not the absolute population budget.", "beginButton": "Start the viewport Brush session for the selected set, creating a mask when needed.", "stopButton": "Stop the active Brush session.", "fillButton": "Fill coverage across the supported paint target.", "emptyButton": "Empty coverage across the paint target.", "resetTarget": "Explicitly reset the stored coverage target; review the local dialog before accepting."})
controls("brushUI", "brush-feedback", {"overlayMode": "Show coverage tint, coverage samples or no feedback.", "overlayColor": "Change coverage feedback color; it does not choose a source model."})
controls("brushUI", "brush-history", {"strokeList": "Select a saved Paint/Erase stroke for editing.", "strokeEnabled": "Include/exclude the selected stroke when evaluating history.", "strokeErase": "Switch the selected saved stroke between Paint and Erase.", "strokeRadius": "Reevaluate the selected historical stroke with a new radius.", "strokeStrength": "Reevaluate the selected historical stroke with new strength.", "strokeSoft": "Reevaluate the selected historical stroke with new softness.", "deleteStroke": "Remove the selected stroke from this set's history."})
controls("areaUI", "areas", {"areaList": "Select closed Area shapes; each has an Include/Exclude role.", "addAreaScene": "Add closed Area shapes through scene selection.", "pickArea": "Pick a closed Area shape in the viewport.", "removeArea": "Remove selected Area references from this layer.", "areaMode": "Set the selected Area shapes to Include or Exclude; exclude wins in overlaps.", "refreshAreas": "Refresh Area geometry and affected preview data."})
controls("areaUI", "analyzer", {"aaPick": "Link a Surface Analyzer to this layer's Area mask.", "aaRemove": "Remove the Area Analyzer reference.", "aaLine": "Enable an Area band around Analyzer centre lines.", "aaWidth": "Set the full world-space width of the Analyzer line band.", "aaCaps": "Choose flat or round ends for line-band masks.", "aaStreetOffset": "Offset the supported Analyzer street/line mask.", "aaPoints": "Enable circular Area masks around Analyzer sample points.", "aaRadius": "Set the radius of Analyzer-point Area masks."})
controls("areaUI", "falloff", {"fallTarget": "Choose an Analyzer boundary or selected Area line as the falloff edge.", "fallPick": "Choose the Analyzer used for edge falloff.", "fallRemove": "Clear the falloff Analyzer reference.", "fallDeleteCheck": "Enable removal inside a boundary band.", "fallDeleteSpin": "Set the width of the deletion band.", "fallScaleCheck": "Enable scaling as a function of edge distance.", "fallScaleSpin": "Set the distance over which scale falloff is evaluated.", "fallScaleEdit": "Open the scale-versus-edge-distance curve editor.", "fallDensityCheck": "Enable density thinning as a function of edge distance.", "fallDensitySpin": "Set the distance over which density falloff is evaluated.", "fallDensityEdit": "Open the density-versus-edge-distance curve editor."})
controls("diversityUI", "diversity", {"diversityRadio": "Select Random, Clusters, Line Pattern or Analyze Surface assignment; multi-set guards apply.", "sizeSpin": "Change characteristic cluster size.", "divSeedSpin": "Change deterministic cluster/assignment randomness.", "roughSpin": "Adjust cluster boundary roughness.", "blurSpin": "Adjust mixing near cluster edges.", "noiseSpin": "Adjust assignment noise within the cluster pattern."})
controls("diversityUI", "line-pattern", {"pathsDrop": "Choose the path whose consecutive assignment bands are edited.", "analyzerChannel": "Choose Border, Centerline, Points, Street Side or Edge Border data.", "pickAnalyzer": "Link the Analyzer used for source-pattern assignment.", "pickPath": "Add a closed shape as an assignment path.", "removePath": "Remove the selected assignment path.", "strokesList": "Select a consecutive pattern band; these are not Brush strokes.", "addOutside": "Add the channel-specific outer operation: Outside band, Centerline Stroke or Points Radius. Hidden in Border/Street/Edge channels.", "addInside": "Add the channel-specific inner operation: Inside band, Points Single or Edge Row.", "removeStrokeButton": "Remove the selected pattern band.", "strokeWidth": "Set assignment band width; in Edge Border this means point spacing. Points/Single disables it.", "strokeMode": "Assign the band by color groups or individual source objects.", "strokeChoices": "Choose eligible color groups or source objects for the band.", "strokeScaleMin": "Set the minimum scale multiplier within the band.", "strokeScaleMax": "Set the maximum scale multiplier within the band.", "refreshGroups": "Refresh source/group choices for the pattern editor.", "edgeOffsetSpin": "Move Edge Border candidates inward from the boundary.", "edgeAlongSpin": "Add position jitter along the boundary.", "edgeAcrossSpin": "Add position jitter across the boundary.", "keepCornerCheck": "Preserve eligible corner candidates in Edge Border mode.", "cornerAngleSpin": "Set the turn threshold for corner detection.", "cornerCountSpin": "Set candidate count per eligible corner.", "edgeRotXSpin": "Add local X rotation in Edge Border placement.", "edgeRotYSpin": "Add local Y rotation in Edge Border placement.", "edgeRotZSpin": "Add local Z rotation in Edge Border placement.", "streetStartSpin": "Trim the start of the street guide.", "streetEndSpin": "Trim the end of the street guide.", "centerStreetSpin": "Offset the supported centre/street pattern.", "faceOutCheck": "Orient supported border/street placements outward.", "cornerRadiusSpin": "Set the radius used to smooth outward orientation around Border/Street/Edge corners.", "straightStreet": "Use straight Street Side ends instead of the alternative corner treatment."})
for family, text in (("rot", "rotation in degrees"), ("scl", "scale multiplier"), ("mov", "movement in world units")):
    for axis in "XYZ":
        for side in ("Min", "Max"):
            controls("randomUI", "randomize", {f"{family}{axis}{side}Spin": f"Set the {side.lower()}imum {axis}-axis {text} for this parent's instances."})
controls("randomUI", "randomize", {"wholeMinSpin": "Set the minimum uniform Whole Scale multiplier.", "wholeMaxSpin": "Set the maximum uniform Whole Scale multiplier.", "projectCheck": "Project supported movement back onto the receiving surface.", "alignCheck": "Align placement orientation to the receiving surface normal.", "resetRotation": "Reset X/Y/Z rotation ranges in one Undo action.", "resetScale": "Reset X/Y/Z scale ranges to 1 in one Undo action.", "resetWholeScale": "Reset uniform Whole Scale range to 1 in one Undo action.", "resetMovement": "Reset movement ranges to zero in one Undo action."})
controls("spacingUI", "collision", {"collisionCheck": "Enable shared within-parent 3D centre spacing.", "radiusSpin": "Set within-parent collision radius; minimum centre gap is twice this value."})
controls("spacingUI", "relax", {"relaxCheck": "Enable Point Relax where compatible; active Brush masks pause it.", "spacingSpin": "Set the target spacing used by Point Relax.", "iterationsSpin": "Set the bounded iteration count for Point Relax.", "strengthSpin": "Set the strength of Point Relax adjustments."})
controls("separationUI", "separation", {"prioritySpin": "Set the parent's priority for shared conflict resolution.", "peerList": "Select another logical parent to edit its pair rule.", "blockerList": "Legacy-only list of populations that block this layer.", "overlapCheck": "Enable separation for the selected pair.", "radiusMode": "Use centre distance or approximate source footprints plus a gap.", "gapSpin": "Set the pair's centre distance or additional footprint gap.", "radiusSpin": "Set the older legacy blocker radius; shared pair rules have their own controls.", "planarCheck": "Choose XY or 3D for the selected pair in shared spacing. This does not change the separate persisted cleanup plane setting.", "statsButton": "Update planting and refresh spacing statistics."})
controls("separationUI", "cleanup", {"cleanCheck": "Remove isolated plants from the accepted parent union.", "neighborSpin": "Set the distance for neighbor and island connectivity.", "minNeighborSpin": "Require at least this many neighbors.", "minIslandSpin": "Require a minimum connected-island population."})
controls("separationUI", "relax", {"boundaryRelaxCheck": "Legacy Boundary Relax switch; shared spacing currently pauses it.", "finalStrengthSpin": "Set stored Boundary Relax strength for compatible legacy paths.", "finalIterSpin": "Set stored Boundary Relax iterations for compatible legacy paths.", "finalMoveSpin": "Cap stored Boundary Relax displacement for compatible legacy paths."})
controls("detailsUI", "stats", {"refreshButton": "Refresh the visible cached statistics without changing placement settings.", "helpButton": "Open the layer's local explanation of ownership and count semantics."})
controls("previewUI", "display", {"previewCheck": "Show or hide the controller's preview drawing.", "displayModeDrop": "Switch Point Cloud, Proxy, Mesh or Plant centres.", "pointColorRadio": "Use one solid preview color or source group colors.", "solidColorPicker": "Choose the solid preview color.", "iconSpin": "Set the size of the controller icon.", "refreshButton": "Explicitly refresh preview/planting caches and status through refreshAll, as Update now does."})
controls("previewUI", "proxy", {"proxyShapeDrop": "Choose a box, sphere or pyramid representation."})
controls("previewUI", "budgets", {"instancesLimitSpin": "Limit displayed instances in the supported per-population preview path.", "faceLimitSpin": "Limit displayed preview faces; this is not a final-render geometry cap.", "budgetSpin": "Limit controller Point Cloud samples, shared across enabled populations.", "pointsSpin": "Set target shape samples per plant, still subject to the total point budget."})
controls("previewUI", "radii", {"radiusLimitSpin": "Cap displayed radius diagnostics; zero hides them.", "radiusAllCheck": "Ignore the radius-display cap and show all eligible radius overlays."})
controls("previewUI", "output", {"autoRenderCheck": "Enable the existing automatic final-render output path.", "clearBakedButton": "Remove old generated baked output through the controller's local cleanup action."})

inventory = []
for scope, sections in native.items():
    if not isinstance(sections, dict):
        continue
    for section, items in sections.items():
        if not items:
            continue
        rollout = section_rollout.get(section, section + ("_1" if scope == "layer" else ""))
        starts = [i for i, line in enumerate(source_lines) if re.search(r"\brollout\s+" + re.escape(rollout) + r"\s", line)]
        if not starts:
            raise ValueError(f"Missing rollout {rollout}")
        start = starts[0]
        end = next((i for i in range(start+1, len(source_lines)) if re.search(r"\brollout\s+\w+\s+\"", source_lines[i])), len(source_lines))
        for control in items:
            name = control["name"]
            found = [(i, line) for i, line in enumerate(source_lines[start:end], start)
                     if re.match(r"\s*\w+\s+" + re.escape(name) + r'\s+"', line)]
            if not found:
                raise ValueError(f"Missing control definition {section}.{name}")
            index, line = found[0]
            label = re.search(r'\s+"((?:[^"\\]|\\.)*)"', line).group(1).replace("\\n", " ").strip(" :")
            target, explanation = overrides[(section, name)]  # A missing effect is a build error.
            key = f"{section}.{name}"
            item = dict(scope=("Paint set" if section in ("sourceUI", "brushUI", "setsUI") else "General" if scope == "general" else "Layer"),
                        section=section, kind=control["kind"], name=name, label=label,
                        node=target, key=key, effect=explanation, path=SCRIPT, line=index+1)
            inventory.append(item)
            by_id[target]["controls"].append({"label": label, "effect": explanation, "key": key})

# Companion controls are represented separately; they are not part of the 194-count main-panel inventory.
by_id["analyzer"]["controls"].extend([
    {"label": name, "effect": detail, "key": "Analyzer / " + name} for name, detail in [
        ("Fit radius", "Require footprint clearance to exterior edges and holes; zero disables that clearance."),
        ("Point radius", "Control centre spacing independently of boundary clearance."),
        ("Min points", "Request a minimum per element; may reduce centre separation but cannot violate Fit radius."),
        ("Relax steps", "Smooth supported guide paths with a bounded iterative solver, then recheck clearance."),
        ("Ring factor", "Choose a preferred ring radius, still constrained by clearance."),
        ("Min length", "Filter short path/region features."),
        ("Resolution", "Trade raster analysis precision for calculation cost."),
        ("Method / Auto", "Choose an analysis method or use the geometric Auto heuristic."),
        ("Update / Analyze", "Use cached Manual results or real-time updates after relevant changes."),
        ("Boundary / path / point display", "Draw cached Analyzer results without reanalysis."),
        ("Spline / helper export", "Create independent snapshots, not live output links.")]])
for name, target in [("connection_get_status", "diagnostics"), ("scene_get_context", "enrollment"),
                     ("scatter_validate_plan", "plan"), ("scatter_apply_plan", "apply"),
                     ("scatter_get_status", "diagnostics"), ("scatter_get_diagnostics", "diagnostics"),
                     ("scatter_get_configuration", "configuration"), ("scatter_export_record", "records"),
                     ("scene_capture_viewport", "capture")]:
    by_id[target]["controls"].append({"label": name, "effect": by_id[target]["summary"], "key": "MCP tool / " + name})

# Parse the closed settings declarations as data; do not import or start the service.
registry_ast = ast.parse((ROOT / "CyrusMCP/cyrus_mcp/settings.py").read_text())
for statement in registry_ast.body:
    if isinstance(statement, ast.Assign) and isinstance(statement.targets[0], ast.Name):
        registry_name = statement.targets[0].id
        if registry_name not in ("LAYER_SETTINGS", "SOURCE_SETTINGS", "DISPLAY_SETTINGS"):
            continue
        for key, (kind, default, bounds, native_key) in ast.literal_eval(statement.value).items():
            units = "metres" if key.endswith("_m") else "degrees" if key.endswith("_degrees") else "unitless / enum"
            by_id["plan"]["controls"].append({"label": key, "key": "MCP " + registry_name + "." + key,
                "effect": f"Typed {kind}; default {default}; units: {units}. " +
                          (f"Bounds or choices: {bounds}. " if bounds else "") +
                          f"Applies through validated plan 2.0 {registry_name.lower().replace('_settings', '')} settings, after local approval."})

files = {r["path"] for n in nodes for r in n["refs"]} | {SCRIPT, "AminScatter/tools/ui/layers-control-inventory.json", "CyrusMCP/cyrus_mcp/settings.py"}
model = dict(meta=dict(title="Cyrus Scatter · System map", version="Scatter 1.2.2 · Analyzer 0.14 · MCP 1.1", date="2026-10-04",
                       description="Explore what each feature owns, changes and depends on.",
                       scopeNote="Read-only documentation of the local source snapshot. Not connected to 3ds Max. Planned items are labeled; a mapped control is not a claim of exhaustive runtime qualification."),
             nodes=nodes, edges=edges, lenses=lenses, stories=stories, inventory=inventory,
             coverage=dict(nativeControls=sum(len(cs) for scope in native.values() if isinstance(scope, dict) for cs in scope.values()),
                           mappedControls=len(inventory), note="194 unique controls from the generated main-panel inventory: 28 General and 166 feature-section definitions. Labels, repeated editor copies, secondary dialog internals and separate Analyzer/Edit panels are not included in this count. Companion features and nine MCP tools are mapped separately."),
             evidence=dict(method="Source inspection plus preserved qualification documentation; no new plugin performance or host test is claimed by this map.",
                           files=[{"path": p, "sha256": hashlib.sha256((ROOT/p).read_bytes()).hexdigest()} for p in sorted(files)]))

# Structural checks keep the graph honest when its content changes.
ids = [n["id"] for n in nodes]
assert len(ids) == len(set(ids))
assert len(inventory) == model["coverage"]["nativeControls"] == 194
assert len({i["key"] for i in inventory}) == len(inventory)
assert len({e["id"] for e in edges}) == len(edges)
edge_by_id = {e["id"]: e for e in edges}
for e in edges:
    assert e["from"] in by_id and e["to"] in by_id
covered = set()
for view in lenses:
    members = {x["id"] for x in view["nodes"]}
    covered |= members
    for eid in view["edges"]:
        e = edge_by_id[eid]
        assert e["from"] in members and e["to"] in members, (view["id"], eid)
assert covered == set(ids), set(ids) - covered
for tour in stories:
    assert tour["lens"] in {v["id"] for v in lenses}
    assert all(s["node"] in by_id for s in tour["steps"])
DEST.mkdir(parents=True, exist_ok=True)
payload = json.dumps(model, indent=2, ensure_ascii=False)
(DEST / "model.json").write_text(payload + "\n", encoding="utf-8")
if PAGE.exists():
    html = PAGE.read_text(encoding="utf-8")
    pattern = r'(<script\b[^>]*\bid=["\']system-data["\'][^>]*>)[\s\S]*?(</script>)'
    assert len(re.findall(pattern, html)) == 1, "Expected exactly one system-data script block"
    safe_payload = payload.replace("<", "\\u003c")
    html = re.sub(pattern, lambda m: m[1] + "\n" + safe_payload + "\n" + m[2], html)
    PAGE.write_text(html, encoding="utf-8")
print(f"Built {len(nodes)} features, {len(edges)} connections, {len(lenses)} views, {len(stories)} guides and {len(inventory)} mapped controls.")

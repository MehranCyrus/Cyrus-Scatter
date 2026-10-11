# Cyrus Scatter: product and AI direction

Maintained public-facing summary, reviewed 11 October 2026 against Scatter 0.78.3, Analyzer 0.14 and MCP package/plan 0.73.0/0.73. This is the source for the website's product status and roadmap. Update it alongside the [artist guide](ARTIST_GUIDE.md), [backlog](BACKLOG.md) and [MCP contract](../CyrusMCP/README.md). It does not replace engineering acceptance criteria or announce a release date.

## The product today

Cyrus Scatter is an artist-controlled scattering plugin for 3ds Max. Build a landscape from your own models, arrange planting in layers and refine it with ordinary controls. AI is optional; everyday use does not depend on an assistant, account connection or trained model.

The current development version is **0.79**, beginning offline team licensing work while preserving the 0.78.3 artist workflow and schema 55. Team activation is not yet implemented in ordinary builds. The latest matched Max 2026 and 2027 packages and bounded scripted host checks remain **0.78.3**. Physical input, high DPI, long sessions, heavy assets and the full renderer/material matrix still have acceptance work. Version 1.0 is reserved for publication readiness.

| Feature | What the artist can do | Boundary to explain |
| --- | --- | --- |
| Layers and receivers | Give each layer its own surfaces, models, amount and rules | A layer owns the planting recipe; Paint Areas share its models |
| Source models and containers | Use model weights, labels, identification colors and optional rectangular palettes | New containers start with collection disabled; arrange them before enabling collection |
| Amount and stable candidates | Choose Density or Fixed Total with receiver-local identities | Adding a receiver preserves unchanged base candidates; quotas and acceptance constraints can still change final output |
| Density and target controls | Modulate density with supported texture/UV maps; choose candidate budgets or bounded accepted targets | Targets can underfill when masks, spacing and bounded retries reject candidates; Point/Empty restrictions apply |
| Layout | Choose Random mix, Clusters, Spline bands or Surface Analyzer guides | Clusters assign source groups; they do not necessarily move the candidate positions |
| Vector painting | Paint and erase named receiver-bound areas; shape density and scale feathering with curves | Supports single-valued terrain in receiver-local XY; closed spheres, folds and vertical receivers are outside vector painting support |
| Include/Exclude and falloff | Combine closed masks, holes, delete strips, density ramps and scale ramps | Uses world XY; Includes union and Exclude wins |
| Variation and spacing | Adjust transforms, model radii, within-layer and between-layer clearance | Collision radii are simplified footprints, not exact mesh intersection |
| Relax and cleanup | Adjust candidate spacing near boundaries and remove isolated or crowded results | Relax changes candidate positions; finite work limits and cleanup can leave a shortfall |
| Individual refinement | Use supported CS Edit and stable instance-radius overrides | Generation changes can invalidate a binding; identity is not a row index |
| Viewport and updates | Choose Plant centres, Point Cloud, Proxy or Mesh; work in Manual or Live | Display budgets can show fewer plants than the accepted result; cached reads do not generate pending work |
| Analyzer | Use separate planar boundaries, paths and points | Analyzer 0.14 has its own update mode and freshness; analyze it before updating dependent Scatter results |
| Diagnostics and output | Inspect completed counts, record a bounded local trace, remove old owned baked output and use supported final-output paths | A preview or successful smoke render does not qualify every renderer/material combination |

Current behavior is documented in [the artist guide](ARTIST_GUIDE.md) and [Layout/Analyzer/falloff details](LAYOUT_AND_FALLOFF.md). [Qualification reports](README.md) record which combinations were actually tested. Concept artwork on the website illustrates intent; it is not evidence of plugin output or benchmark performance.

## Assistant access today

The separate **Cyrus MCP** foundation supports bounded inspection and an approved planting-plan workflow. An assistant can read an enrolled scope, propose supported settings, validate them, wait for exact local approval, apply the approved owned plan and inspect the completed publication.

The current public authoring contract is narrower than the interactive plugin: a supported static horizontal convex site, up to three mesh sources, three regions/layers and 2,000 aggregate requested candidates, with limited applications per enrollment. The authoring host workflow is documented for Max 2027; Scatter's separate Max 2026 support does not certify MCP authoring there.

Full vector painting, source-container authoring, Spline bands/Analyzer authoring, individual instance edits, renderer jobs and general scene scripting are not public MCP mutation features. Read-only configuration and feature help do not grant access to every control. Integration with particular assistant clients must be qualified separately; a subscription alone does not establish compatibility.

See [CyrusMCP/README.md](../CyrusMCP/README.md) and the maintained [capability matrix](Current_System_2026-10-05/CAPABILITY_MATRIX.md) for exact operations and limits.

## Learning foundations today

An **offline Design Lab experiment** contains study records, explicit comparison/consent handling and a small preference ranker. It does not connect to Max, render scenes, understand reference images or deliver a production personal style model. Its saved experimental models are not deployable.

Style profiles, reference-assisted design, a working artist review gallery and ML-driven recipe recommendations remain future product work. A useful recipe library and editable preferences can precede training. MCP carries supported proposals and scene operations; it is not itself the model that learns an artist's taste.

See the [offline Design Lab](Offline_Implementation_2026-10-05/DESIGN_LAB.md), [artist-style proposal](Artist_Style_ML_2026-10-04/README.md) and [design-learning research](AI_Design_Learning_Research_2026-10-05/README.md). These research documents retain their historical terminology and versions; their proposed features are not current promises.

## Roadmap

The order below follows dependencies. It is a direction for development, without committed dates. The interactive plugin remains useful independently of each later stage.

### 1. Qualify the everyday artist workflow

Finish physical control, brush, graph, Undo, DPI and long-session checks with representative plant assets. Improve measured bottlenecks and qualify the declared Max/renderer matrix. Resolve open observations in the existing backlog rather than inferring readiness from pass counts.

**Ready when:** artists can complete representative scenes, reopen them and recover from errors with the declared supported combinations. Evidence includes real interaction and material/output checks.

### 2. Broaden MCP through complete artist tasks

Expand supported procedural recipes and area/layout operations in bounded groups. Add useful explanations, exact publication records and predictable ownership, approval, Undo and recovery. Qualify any new host or assistant client rather than assuming compatibility.

**Ready when:** each advertised task produces the same supported settings and output as the native workflow, with clear limits and reproducible recovery. A catalog of controls alone does not meet this gate.

### 3. Build a recipe library and artist review companion

Let artists map plant roles to their own assets, save editable preferences, compare a small set of valid planting alternatives and revisit approved recipes. Keep selection, approval and application separate. Start with curated recipes and deterministic variations before requiring a trained model.

**Ready when:** artists can compare, choose and apply useful alternatives while retaining ordinary editable Cyrus layers and controls. Completed examples keep their scene, source and view provenance.

### 4. Prove personal learning and reference assistance

Use explicitly consented comparisons to evaluate retrieval and a small preference model against a strong manual-recipe baseline. Add image/reference interpretation only when it reduces correction time on independent projects. More complex models, LoRA or other training methods are conditional research choices.

**Ready when:** held-out artist studies show better useful suggestions or less time to an approved result. Recording, sharing and training permission remain separate choices; approving a scene never silently trains a model.

### 5. Qualify studio workflows and wider delivery

Add supported batch/renderer jobs, project libraries and studio deployment only after their resource, identity, recovery and consent contracts pass. Licensing and distribution remain separate release workstreams.

**Ready when:** the declared platform/client/renderer matrix, failure recovery, storage/resource limits and installation paths have reproducible evidence. No autonomous scene-to-final-render product or release date is promised here.

## Reading the status labels

**Current** describes implemented functionality within its documented limits. **Experimental** describes working research foundations that are not production artist tools. **Planned** describes product direction, without committed release dates. Concept artwork and teaching diagrams illustrate ideas; actual plugin captures have their own build and scene captions.

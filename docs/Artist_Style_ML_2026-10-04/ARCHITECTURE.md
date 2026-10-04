# Architecture and output contracts

**PROPOSED.** No component described as a design companion, style profile, collector or trainer is implemented by this documentation task. The existing integration boundary is recorded in [CODEBASE_AUDIT.md](CODEBASE_AUDIT.md).

## Process boundaries

Use one separate local companion initially. A small desktop/browser interface, a local metadata database and versioned files are sufficient for the pilot. Do not begin with a distributed training platform, a dedicated vector database or a public profile marketplace.

| Component | Responsibility | Does not own |
| --- | --- | --- |
| Profile library | References, approved recipes, pattern examples, role vocabulary and profile revisions | Live Max node identities or scene mutation |
| Design service | Retrieval, optional model inference, candidate recipe proposals and scoring | Max SDK calls or unrestricted scripting |
| Recipe compiler | Capability checks, unit conversion contracts, role binding and explicit unsupported-feature reports | Artist taste or inferred exceptions to constraints |
| Existing Cyrus MCP service | Fresh scene context, closed plans, approval, owned transactions, receipts and diagnostics | Model weights, a training job or unbounded search |
| Cyrus engine | Deterministic generation, Brush/area/spacing policy and actual transforms | Personal preference training |
| Preview renderer | Cached Point Cloud, Proxy, Mesh and centre display | Inference or layout redesign while navigating |
| Offline collector/trainer | Approved records, data preparation, evaluation and candidate model revisions | Automatic promotion into a live scene |

MCP is a host/client/server protocol for exposing context and tools. A model loader is a separate implementation concern. The companion could be used by the same AI client alongside Cyrus MCP, or expose its own small tool interface later. Existing Cyrus tools remain the sole approved scene-mutation path for the pilot. [MCP architecture](https://modelcontextprotocol.io/docs/2026-07-28/learn/architecture)

## Three data contracts, with different lifetimes

### 1. Artist Style Profile: portable intent

Proposed contents:

- Profile ID, revision, owner scope, display name and a short description of when to use it.
- Reference IDs and explicit annotations such as “like the spacing” or “ignore the lighting.”
- Semantic roles: canopy tree, accent tree, shrub, groundcover. Roles are artist-editable; node names alone are insufficient labels.
- Soft preferences for mixture, height variation, spatial organization, open space and view composition.
- Approved recipe and authored-patch references, including measurement domains and applicable site types.
- Optional fitted statistics, retrieval embeddings, preference-model revision or planner adapter. Every learned component can be absent.
- Provenance, usage permissions, compatibility metadata and evaluation status.

One artist may keep several profiles. A studio may publish a shared base profile while artists retain private preferences. A project may pin a particular revision. Do not merge everyone into one changing model or assume that all work by one artist expresses one style.

The profile stores plant **roles**, not transient `source_...` IDs from an old Max enrollment. An asset library may provide stable local asset records, but binding those records to nodes in the current scene is a separate step. Replacement assets require size/shape checks, not name matching alone.

See [artist-style-profile.json](examples/artist-style-profile.json). It contains no trained weights and no scene data.

### 2. Design request and recipe: site-specific proposals

The design request should include a versioned site snapshot, units, zones, protected areas, available asset cards, role mapping, hard constraints, optional camera observations, profile revision, explicit overrides and a candidate-generation budget.

Asset cards initially need confirmed role, dimensions, pivot/ground contact, footprint policy, source revision and representation type. Future semantic building context should include artist-confirmed facade/entrance/path regions, rather than requiring a model to guess all of this from a viewport image.

A recipe expresses intended organization: role allocation, count or density semantics, scale/rotation distributions, coverage, spatial pattern and pair relationships. Record the origin of each choice: artist override, retrieved recipe, fitted pattern or model suggestion. Avoid invented numerical “confidence” scores; expose missing evidence and measurable calibration separately.

The proposed [design-recipe.json](examples/design-recipe.json) deliberately uses **candidate counts** so it can be mapped to current plan 2.0. Future fields and pattern requirements need new recipe and compiler capabilities. A design recipe is not itself an executable MCP plan.

### 3. Executable plan and actual result: generation-specific evidence

The compiler binds roles to the current enrollment and emits only fields allowed by `DesignPlanV2`. It must produce a feature report: supported, approximated with explicit artist acceptance, or unsupported. An essential unsupported request prevents application. Do not silently turn rows, spatial clumps or painted coverage into uniform random scatter.

Existing source IDs, context IDs and generation IDs are not portable profile data. Current plans are capped at 32 KiB and 2,000 aggregate candidates. Existing source weights are relative shares, not a guarantee of exact final per-species counts.

After execution, use the **actual exported layout** for measurement. The record must connect profile revision, recipe, normalized plan, scene snapshot, generation receipt and actual transforms. Keep proposed counts, accepted placements, displayed instances and cloud sample counts separate.

The [compiled-plan-v2.json](examples/compiled-plan-v2.json) is a synthetic illustration checked against existing shape/settings validators. Its IDs are placeholders. It has not been validated against a live scene or applied in Max.

## Exact request lifecycle

1. The artist chooses a profile, site, planting zones, protected regions and asset-role bindings. The companion identifies missing input before proposing a layout.
2. Obtain current capabilities and a scene snapshot. Use the supported subset for the first pilot. Keep source dimensions and world units explicit.
3. Retrieve relevant examples and propose a bounded set of recipes. A manual recipe path is always available as the baseline and fallback.
4. Check expressibility, units, ranges, ownership, counts and constraints. Rank valid proposals using interpretable measurements or the optional learned ranker.
5. Present a concrete proposal with what will be created, the assumed style, expected underfill and any limitations. Current MCP permits two successful applications per enrollment, not an unlimited interactive optimization loop.
6. Before application, acquire fresh context. If the geometry, assets, constraints or relevant camera changed, invalidate the stale proposal and reconsider it. Do not merely substitute new IDs into a geometrically stale recipe.
7. Compile and validate the exact plan. Obtain the existing local approval and apply through its idempotent transaction path.
8. Read the receipt and actual layout, show results and leave normal Cyrus editing available. An optional second approved refinement stays within current scope budgets.
9. Offer explicit feedback capture. Save edits with their meaning; do not turn a completed job into an implicit training opt-in.

Current context/validation deadlines are five minutes. Long model or training jobs cannot hold a plan valid indefinitely. Training never occurs inside this lifecycle; a completed training job publishes a candidate profile revision for separate evaluation.

## Layers, paint sets and manual editing

A style profile belongs to the design workflow, not to a hidden extra scatter layer. The output must use the artist's layer organization and show what each setting controls.

For the current pilot, MCP creates its own independent layers. It cannot automate the artist's existing paint sets. A later contract must expose persistent parent/set identities and preserve the current rule that sets share parent population and spacing while owning their sources and Brush history.

For future learned coverage, propose a separate editable coverage contribution in the same procedural system. Do not turn model output into thousands of fake brush strokes. Keep original strokes and their identities; an artist must be able to disable the learned contribution, repaint locally and regenerate without losing manual changes.

Define precedence explicitly: protected regions and exclusions always constrain output; artist overrides constrain learned suggestions; the remaining coverage combines under a documented mode such as intersection or artist-selected replacement. Additive and multiplicative modes have different meanings and must not be silently interchanged. Pin edited instances only through a qualified Edit/candidate contract; current MCP cannot promise to preserve arbitrary post-generation CS Edit modifications during refinement.

## Density, fields and pattern semantics

Three quantities need distinct names and units:

| Quantity | Meaning |
| --- | --- |
| Coverage mask `m(x)` in [0,1] | Relative eligibility or thinning strength at a surface position |
| Target intensity `lambda(x)` in plants/m² | Desired expected local plant count before or after a specifically named stage |
| Canopy/visual coverage | Area occupied by projected plant shapes; depends on plant size, overlap and viewpoint |

A white mask does not guarantee a fully packed bed. It authorizes the configured population; spacing and other constraints can still reduce output. For a proposed intensity sampler, `integral(lambda(x) dA)` is an expected count before explicitly specified rejection stages, not a promise about the final result. Current MCP count is sampled over the receiver before masks, so simply multiplying a planting region's area by a target density does **not** reproduce current semantics.

For the first learned-field experiment, specify a flat world-XY domain: origin in metres, X/Y basis, extent, grid resolution, row order, interpolation, value range, outside behavior and content hash. Protected areas stay separate exact constraints. Serialize a bounded field resource with its own enrollment/validation rather than putting a large array into the existing plan. A proposed 256×256, four-channel float32 field is 1 MiB of raw values; this is an engineering example, not an existing supported budget.

The native density sampler currently uses UV data with rows from `v=1` to `v=0`. A world field therefore requires an explicit tested mapping. Curved surfaces introduce seams, overlapping UVs, disconnected components and surface distance; those must be addressed before claiming learned coverage works on arbitrary geometry. Existing curved Brush support does not solve this exchange contract automatically.

A useful procedural vocabulary should distinguish source mixing, point spacing, spatial clumps, edge rows, grids, clearings and camera-aware emphasis. Native boundary-row and density paths are reuse candidates. Current source-diversity clustering does not move points into clumps. Implement only the missing primitive demonstrated by the exemplar/recipe experiments, with deterministic seeds, bounded work and validation against actual output.

Pair relationships also need a declared meaning. Trunk clearance, crown overlap, spacing for shrubs under trees and clearance from a building are different constraints. A lush understory may intentionally sit beneath a canopy. A blanket rule that excludes every shrub from a tree's entire projected crown can destroy that design. Current MCP exposes radius-based pair rules and conservative protected-region footprints; any richer clearance policy must be specified and qualified before the planner uses it. Do not infer horticultural viability from an artistic reference.

## Personalized inference and training

The first personal model should score **whole valid alternatives**. Input features can include actual role proportions, spacing distributions, clustering descriptors, coverage, view occlusion measurements and reference similarity. Pairwise feedback asks which of two layouts better satisfies the same brief. Store ties and “neither,” not just wins.

Keep recipe scoring and actual-layout scoring separate. Before generation, a model can rank proposed settings using predicted features. It cannot claim to have measured the resulting placement. Scoring many actual alternatives requires stored executed examples or the separately qualified offline generator described in the roadmap. With today's live MCP, inspection of actual alternatives is limited to its two approved applications. Do not hide extra generations behind a ranking feature.

A structured-planner LoRA becomes useful only if we have context-to-recipe examples and a measured weakness that retrieval cannot solve. Its training target is a valid typed recipe, with a separate compiler and final validation. Even a perfectly well-formed JSON output may describe a bad design; structural validity is only one metric.

A model package must pin base/model revision, adapter task, weights checksum, tokenizer/processor, feature normalization, role vocabulary, input/output schema, compiler compatibility, runtime versions and evaluation report. A LoRA checkpoint alone is insufficient. [PEFT format](https://huggingface.co/docs/peft/en/developer_guides/checkpoint)

Begin with one active profile binding per inference request and serialized adapter switching. Store the binding in the request and result. A shared runtime must not let simultaneous artists accidentally use each other's adapter. Adapter swapping facilities exist, but have compatibility constraints; they do not remove the need for request isolation. [PEFT hotswap](https://huggingface.co/docs/peft/en/package_reference/hotswap)

## Runtime and performance contract

- Run inference/training in a separate process/environment. Max SDK and `pymxs` calls remain on the existing main-thread adapter path.
- Start recipe retrieval and a small statistical/ranking baseline on CPU. Use a GPU only for a selected model whose measured cost warrants it. Training a larger planner may need a separate machine or an explicitly selected remote job.
- Separate processes still share GPU memory and compute with Max and the renderer. Limit active jobs, support cancellation, release idle model memory and measure contention during navigation. Defer local training during interactive production work by default.
- Cache reference features by image/preprocessing/model revision; cache proposals by relevant site/asset/constraint/profile/compiler revisions and seed. An image crop or changed asset footprint is a real invalidation.
- Freeze the chosen layout. Orbiting or zooming should use Cyrus' retained preview; camera-aware redesign happens only on explicit request.
- Save the selected recipe and actual result. A pinned seed alone does not guarantee identical neural output across model/runtime/hardware changes; reopening a scene must not depend on asking the model to reproduce its earlier answer.
- On missing models, incompatible packages, cancellation or memory failure, keep the existing layout usable. Offer an approved recipe/manual path rather than partially applying an unfinished result.

ONNX Runtime supports execution providers, but conversion and operator coverage must be tested for the actual chosen model. Its Windows guidance currently points new Windows deployment toward Windows ML while DirectML is in sustained engineering. This does not require changing Cyrus' native renderer or committing the companion to a particular GPU API now. [Execution providers](https://onnxruntime.ai/docs/execution-providers/), [Windows deployment guidance](https://onnxruntime.ai/docs/get-started/with-windows.html)

## Minimal product experience

The companion should offer **References**, **Style**, **Scene setup**, **Drafts**, and **Feedback**. Keep model names and training options in an advanced learning panel. Show concrete controls such as open space, variation and planting organization, with units for spatial settings.

The first release can save profiles, recommend recipes and record choices. Later it can show “personal ranking available” or “adapted planner available” with evaluation evidence and rollback. Avoid an automatic “trained” badge merely because images were uploaded. Import/export should package data and compatible weights without executable scripts, absolute machine paths, API secrets or unapproved asset binaries.

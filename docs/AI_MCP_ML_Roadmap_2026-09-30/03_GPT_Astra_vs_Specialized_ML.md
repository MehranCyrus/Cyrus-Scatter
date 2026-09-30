# 03 — General multimodal models versus specialized ML

**Status: capability judgments are PROPOSED / RESEARCH HYPOTHESIS, not Cyrus model-test results.**

## What current primary sources establish

The official [GPT-6 Astra model page](https://developers.openai.com/api/docs/models/gpt-6-astra), retrieved 2026-09-30, documents image/text input, text output, function calling and structured outputs. That establishes a candidate interface, not successful Cyrus scene design. Account access, cost, latency and the exact snapshot available at prototype time remain to be checked. “Astra-class” is a capability description in this roadmap; it does not lock the product to that provider.

OpenAI's [vision guidance](https://developers.openai.com/api/docs/guides/images-vision) describes limitations in precise spatial localization, counting and image interpretation. Its [structured-output guidance](https://developers.openai.com/api/docs/guides/structured-outputs) provides schema-constrained generation, but application semantics still require validation. Refusal and incomplete responses also need handling.

A relevant [OpenAI spatial-layout example](https://developers.openai.com/cookbook/examples/multimodal/grounded_spatial_reasoning_layouts) combines a floor plan, asset catalogue and structured layout evaluation. It is useful precedent for an experiment. It is not evidence of Cyrus compatibility, outdoor planting quality or a transferable success rate.

## Capability classification

“Strong today” below means a reasonable general-model starting task under structured input, based on documented interfaces and the nature of the task. It is not a measured reliability guarantee for Cyrus.

| Capability | Classification | Why / necessary support |
| --- | --- | --- |
| Turn a clear instruction into named layer roles | Strong today with a general multimodal model | Finite vocabulary and examples make this a language/planning task |
| Explain a proposal and ask about ambiguity | Strong today with a general multimodal model | Explanation is useful; validate the underlying plan independently |
| Produce typed parameter proposals | Strong today with a general multimodal model | Schema helps shape; ranges, IDs and combinations still need local checks |
| Identify dominant tree/shrub/open-space hierarchy | Usable but approximate | Canopy overlap, visual scale and asset appearance create ambiguity |
| Estimate relative density | Usable but approximate | Visible coverage is not stem count or plants per square metre |
| Interpret formal versus naturalistic composition | Usable but approximate | Style is contextual and subjective; artist confirmation matters |
| Interpret source clustering | Usable but approximate | Must distinguish appearance grouping from positional clustering |
| Select assets from an approved catalogue | Usable but approximate | Requires dimensions, category, footprint and representative thumbnails |
| Infer exact species or invisible vegetation | Unreliable without additional structured information | Species and hidden objects may be unobservable |
| Recover exact distances/scale from one perspective image | Unreliable without additional structured information | Metric ambiguity persists even with plausible depth |
| Map “left” or “behind” to the current site | Unreliable without additional structured information | Need camera frame and explicit world-space regions |
| Evaluate broad screenshot composition | Usable but approximate | Consistent view/display mode and actual count data are necessary |
| Propose a small parameter revision | Usable but approximate | Compare a bounded change against a fixed seed and baseline |
| Enforce boundary clearance, spacing and locked zones | Better solved with classical geometry/algorithms | Deterministic numeric predicates, independent of aesthetic judgment |
| Count emitted instances and validate transforms | Better solved with classical geometry/algorithms | Read the generated state; do not count foliage pixels |
| Produce editable masks quickly | Potentially better with specialized ML | A segmentation model may reduce tracing work; test correction time |
| Predict repeated studio density/style preferences | Potentially better with specialized ML | Needs consistent labels and held-out projects |
| Create a full coherent landscape from a single image | Research required | Missing 3D information, asset mismatch and many valid design solutions |
| Reliably improve its own design over many iterations | Research required | Self-evaluation may reward its own mistakes or oscillate |

**UNKNOWN:** where GPT/Astra actually falls on the artist-time/quality frontier for this plugin. Run [E-03 through E-05](11_Evaluation_and_Benchmarks.md) before making stronger claims.

## What structured 3D context should provide

**PROPOSED:** local truth first: unit conversion, selected surface dimensions and area, approximate slope/normal summary, world-space bounds, approved source footprints and height, explicit polygons/paths, camera, ownership, layer settings and generated-count summaries. An optional coarse occupancy grid can answer “what is already here” without exporting the mesh.

A screenshot provides appearance and view composition. Analyzer outputs provide computed boundaries/paths on supported geometry. Neither replaces the actual scene's units, references or constraints. Raw triangle/point dumps are expensive, sensitive and usually less useful to a language model than these summaries.

For an arbitrary photograph, use style transfer at the design-intent level. A metric image-to-site mapping requires known correspondence and calibration; do not create fake coordinates from an uncalibrated view.

## Options A–E

**PROPOSED relative estimates.** Assumptions: existing Cyrus engine remains; one experienced Max developer plus part-time QA/product support; the safety API is not built yet; cloud access and reference rights are available where used. Scope and quality gates matter more than calendar predictions.

| Dimension | A: general model + MCP | B: A + retrieval/templates | C: B + segmentation/depth | D: B + point-placement model | E: custom ML-heavy design |
| --- | --- | --- | --- | --- | --- |
| Engineering effort | Medium–high; mostly API/undo/qualification | Medium incremental work | Medium–high incremental work | High; identity, candidates, labels, selection | Very high, open-ended research |
| Data requirement | 20–50 owned evaluation briefs | Curated accepted recipes and metadata | Domain evaluation masks/depth references | Diverse project-level paired layouts and candidate labels | Large, diverse structured training corpus |
| Operations | Companion process and model adapter | Add versioned local library/index | Add model/runtime and image pipeline | Add training/evaluation/model deployment | Several coupled pipelines |
| Inference cost | Metered calls or local reasoning costs | Retrieval can reduce calls; must measure | Extra compute plus reasoning | Ranking plus selection plus reasoning | Highest uncertainty |
| GPU requirement | No extra local ML GPU for cloud reasoning | CPU retrieval feasible for a small library | Checkpoint/resolution dependent | Small ranker may run on CPU | Likely substantial; unqualified |
| Maintenance | API/schema/model regression fixtures | Plus recipe/version drift | Plus checkpoint/runtime/licensing | Plus dataset/feature/model drift | Largest support surface |
| Privacy | Only approved inputs may leave workstation | Local library possible; retrieved content has permissions | Local preprocessing can help; masks still sensitive | Per-studio isolation needed | Largest dataset exposure |
| Likely value | Faster setup and explanation | Good next hypothesis for repeatable workflows | Useful if zoning is the bottleneck | Useful only if placement preference remains costly | Uncertain relative to complexity |
| Principal risk | Safe execution and artist correction cost | Wrong examples / stale parameter recipes | False masks/depth and integration cost | Selection bias and weak generalization | Research consumes product roadmap |

The ranges are categorical because the available evidence does not support reliable person-week or dollar estimates. Re-estimate after API failure-injection tests and the first paired artist campaign. **Recommended order: A, then B; C or D only to fix a measured failure. E is not an initial product plan.**

## Training approach comparison

| Approach | Appropriate use | Main limitation |
| --- | --- | --- |
| Rules/presets | Known spacing, units, boundaries and common layer recipes | Do not infer arbitrary visual intent |
| Metadata retrieval | Find a successful courtyard, meadow or roadside recipe | Coverage and asset/site compatibility |
| Frozen embeddings + nearest neighbors | Reference/style search without model training | Similar appearance need not mean compatible layout |
| Frozen encoder + small classifier/ranker | Narrow labels with project-level validation | Still needs representative labels |
| Small supervised parameter model | Predict bounded density/spacing settings from context | Target ambiguity and correlated parameters |
| Pretrained segmentation/depth | Specialized image measurements | Domain errors, scale ambiguity, runtime/license constraints |
| Fine-tuning / adapters | Repeated, evidenced domain failure in an available trainable model | Does not create missing information or labels |
| Training a large vision model from scratch | Separate research program with substantial data/resources | Inappropriate for roughly 1,000 images |
| Preference/ranking model | Choose among valid candidate layouts | Preferences must be explicit, scoped and contextual |

[LoRA](https://arxiv.org/abs/2106.09685) is a parameter-efficient adaptation technique; fewer trainable parameters do not imply fewer independent examples are always sufficient. Its suitability depends on the specific base model, supported training access and target task. Do not assume a hosted model exposes its weights or supports the desired fine-tuning route.

See [10](10_ML_Options_and_Experiments.md) for task-specific inputs, labels, metrics and readiness gates.


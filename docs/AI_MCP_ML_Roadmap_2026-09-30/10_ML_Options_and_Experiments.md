# 10 — Specialized ML options and readiness

**Status: FUTURE / OPTIONAL. Every suggested product benefit is a RESEARCH HYPOTHESIS.**

## Start with a measured failure

Choose one prediction target that rules, better context, a curated recipe or a general model fails to solve economically. A model family is a means to test that target. It is not a roadmap milestone by itself.

Primary-source candidates inspected on 2026-09-30:

- [SAM 3](https://github.com/facebookresearch/sam3) supports promptable concept segmentation. It is a candidate for editable masks, not proof of reliable vegetation taxonomy or image-to-world zoning. Its SAM license needs checkpoint-specific review.
- [Depth Anything 3](https://github.com/ByteDance-Seed/Depth-Anything-3) includes relative, metric and multiview variants. The repository lists different licenses by checkpoint, including noncommercial larger variants and Apache-licensed variants. Do not infer commercial permission from the repository's top-level code license.
- The [DINOv3 model card](https://github.com/facebookresearch/dinov3/blob/main/MODEL_CARD.md) describes frozen visual features for retrieval and simple downstream heads. Its [license](https://github.com/facebookresearch/dinov3/blob/main/LICENSE.md) is separate from older DINO-family assumptions.
- [ATISS](https://arxiv.org/abs/2110.03675) studies autoregressive indoor scene layouts. It motivates structured-layout research; indoor furniture results do not establish outdoor planting quality.

No checkpoint was downloaded, executed, selected or trained.

## Task inventory

“1k” below means approximately 1,000 **independent, rights-cleared task examples across diverse projects**, not 1,000 crops or point rows from one project. Label quality and project coverage can invalidate every optimistic interpretation in this table. Metrics are proposed; no scores were measured.

| Task | Exact input → output | Labels and candidate model/training | What 1k could support | Metric and product-value gate |
| --- | --- | --- | --- | --- |
| Vegetation/land-use segmentation | Reference pixels + class prompts → masks for tree canopy, shrubs, ground cover, lawn, paths, buildings, roads, water, beds and open space | Artist-reviewed masks, unknown/occluded labels; pretrained segmentation first; small adaptation only after domain errors | Narrow adaptation/evaluation if masks cover classes; no large model from scratch | Per-class IoU, boundary error and artist correction minutes; worthwhile only if faster than manual zoning |
| Canopy instance separation | Image + optional prompts → visible canopy instance masks | Instance annotations distinguishing overlap; pretrained instance model, later small head | Pilot in a bounded image domain | Instance precision/recall and tracing effort; cannot infer hidden stems |
| Depth / relative foreground | Reference image(s), optional calibration → relative depth/confidence or calibrated estimate | Paired measured/known geometry or validated relative-order labels; pretrained depth first | Domain evaluation or small adaptation; 1k ordinary images lack depth truth | Relative-order accuracy; metric error only with scale truth; useful only if it improves zoning |
| Perspective-aware density | Image, camera/site mapping and source size priors → world-area population range | Known counts/areas and visibility labels; classical projection + small regressor | Narrow calibrated domain, not arbitrary photographs | Count/density error and coverage error; avoid claims for uncalibrated/occluded views |
| Candidate desirability | Local site features, approved source, intent/reference features, feasible candidate and context → ranking score | Explicit preferred/rejected alternatives with context; small tree/linear ranker or frozen encoder + head | Plausible narrow experiment; group by project | NDCG/pair accuracy plus final-layout acceptance/time; scores alone do not guarantee useful layouts |
| Source choice | Candidate/region, source cards, brief and style features → probabilities over approved source IDs | Accepted source choices/swaps, availability and costs; retrieval then small classifier | Limited catalogue/roles if labels are consistent | Top-k choice and calibration where probabilistic; fewer artist swaps |
| Density and spacing | Site/zone area, footprint, brief and accepted recipe → bounded density/spacing settings | Approved parameter values plus outcome/constraint status; small regression or ordinal model | Plausible low-dimensional task | Error normalized by artist tolerance; accepted-layout time beats recipe default |
| Cluster behavior | Site/region and brief → source-assignment size or positional density-field parameters | Explicit distinction between grouping and clumps; accepted settings/maps | Limited style family with clear labels | Spatial statistics plus artist preference; no improvement from relabeling current diversity |
| Variation and scale | Asset dimensions, role, region and brief → uniform/per-axis range proposals | Accepted ranges, corrected units, reason codes; small regression | Plausible narrow palette | Range error and correction burden; avoid learning unit mistakes |
| Boundary behavior | Local edge/path geometry, footprint and intent → clearance/falloff/edge-spacing preference | Reviewed parameters/edits; rules first, small regressor later | Potentially enough for a narrow preference task | Hard clearance passes plus artist time; never learn to violate safety masks |
| Hero placement / open-space composition | Site zones, camera, existing layout and brief → ranked valid anchors or occupancy preference | Explicit anchors/protected regions and whole-layout ratings; heuristic/retrieval then ranker | Useful study if diverse labelled projects; sparse labels are a concern | Open-space violations, multi-view preference, correction time |
| Style classification/retrieval | Reference + tags/site type → multi-label style scores and recipe ranking | Reviewed formal/naturalistic, forest edge, meadow, courtyard, roadside, residential, campus and urban tags | Good retrieval/classification pilot; no universal taste model | Retrieval relevance and downstream acceptance; calibrated abstention for mixed styles |
| Artist/studio preference | Pre-edit context + valid candidate alternatives → preference/range | Explicit contextual pairs and studio-scoped accepted settings; saved profile/retrieval then ranker | Depends on independent pairs and studio coverage | Held-out project wins and reduced corrections; no cross-studio leakage |

For every row: a pretrained model may be enough; fine-tuning is optional until its error pattern and benefit are demonstrated. The product value test is downstream artist work saved, not a better academic metric in isolation.

## Candidate scoring: useful, but incomplete

A narrower “is this feasible candidate desirable?” task is much more credible than “design the whole landscape.” Start with deterministic candidate generation and hard constraints.

Proposed pipeline:

1. Generate candidate positions deterministically on eligible geometry.
2. Reject invalid site/mask/footprint/locked-region cases locally.
3. Compute features: edge/path distance, slope, region, footprint, view salience, local occupancy, source role and reference/style descriptor.
4. Rank feasible candidates for each allowed source or action.
5. Select a set under population, spacing, overlap, open-space and diversity constraints.
6. Generate transforms, then perform final hard checks after all offsets/edits.
7. Let the artist inspect the result.

A score of 0.94 is not automatically a 94% probability of artistic correctness. Calibrate only if a probability claim is actually needed and supported by held-out labels. An abstention may be more useful than false confidence.

Independent unary scores cannot encode all pairwise spacing and group composition. A greedy constrained selector is a sensible baseline; compare more complex set/graph approaches only when its failure is measured.

**VERIFIED IN CURRENT CODE:** the existing engine has density-grid/source-assignment inputs, but no stable public “accept these ranked arbitrary candidates” API. A learned ranking prototype therefore needs a separate candidate/selection integration contract. Do not route large placement changes through visible-row CS Edit calls.

## Alternative formulations

| Formulation | Cyrus fit and recommendation |
| --- | --- |
| Semantic masks | Strong candidate for assisted zoning after artist confirmation; image masks are not world regions |
| Heatmaps | Useful visual preference surface; requires coordinate mapping and scale |
| Density fields | Good procedural interface if units/integral/caps are explicit; evaluate classical painted fields first |
| Point classification | Simple feasible/source-category labels; hard geometry should remain deterministic |
| Point desirability/ranking | Promising narrow task; requires candidates, labels and constrained selection |
| Parameter regression | Often the cheapest learned task; begin after saved recipe baselines |
| Pairwise preference ranking | Useful for choosing valid proposals without defining one ideal layout |
| Point generation | Harder identity, constraint and variable-count problem; defer |
| Graph prediction | May encode grouping/paths, but requires costly relation labels; defer |
| Imitation of edits | Needs stable action/state identity and contextual reasons; future study |
| Reinforcement learning | Expensive reward/exploration problem; unsuitable for exploring in an artist's live scene |
| Diffusion/generative layouts | Research-heavy, difficult hard guarantees and data needs; not MVP |
| Full multimodal foundation training | Not justified by the known data or product evidence |

For image masks on a calibrated planar site, map through known camera/site correspondence and validate locally. For an arbitrary inspiration photograph, use its segmentation only to suggest semantic composition, not literal world-space coordinates.

## Retrieval before training

Start with versioned recipes for courtyard, forest edge, meadow, roadside, residential garden, campus, urban plaza, roof garden, formal and naturalistic planting. Each contains compatible site/asset roles, parameter ranges, constraints, sample views, acceptance notes and engine/capability requirements.

1. Rules and tags filter incompatible recipes.
2. Metadata similarity ranks remaining choices.
3. Optional frozen embeddings improve reference/style retrieval.
4. The reasoning model adapts a few compatible recipes to approved source IDs and actual dimensions.
5. The normal validator checks the resulting plan.

Never paste an old source ID, world coordinate or unsupported parameter blindly into a new project. A visually similar roof garden can have entirely different footprint limits or site constraints. Keep proprietary studio recipes isolated.

## Future ML readiness checklist

Do not start custom ML until these answers are written:

- [ ] Exact prediction task, inference inputs and output semantics.
- [ ] Strong rules/retrieval/general-model baseline and its measured failure.
- [ ] Rights-cleared data inventory, independent project count and diversity.
- [ ] Ground-truth definition, ambiguity policy and label agreement.
- [ ] Project/studio train/validation/test split with leakage checks.
- [ ] Success metric and minimum artist-value improvement.
- [ ] Evidence that more scene context or rules will not solve the failure.
- [ ] Evidence that a pretrained model is insufficient or uneconomic.
- [ ] Exact trainable model/checkpoint access and license review.
- [ ] Deployment/runtime/VRAM/privacy and maintenance budget.
- [ ] Versioned features, model rollback and reproducible evaluation.
- [ ] Expected benefit justifies the added product/support complexity.

The most plausible first custom experiment is a small parameter or preference ranker. Choose segmentation first instead if measured manual zoning time dominates. Keep [E-07 to E-10](11_Evaluation_and_Benchmarks.md) optional until their prerequisites exist.


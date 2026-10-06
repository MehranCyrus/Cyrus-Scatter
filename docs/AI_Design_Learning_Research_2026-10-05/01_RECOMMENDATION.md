# Recommendation and decisions

The [second-pass review](16_SECOND_PASS_REPORT.md) retains this recommendation and tightens its prerequisites: identity-survival tests, complete render-artifact verification, callback/worker-mode qualification and a versioned feature pipeline. Artist preference, technical outcome prediction and inverse recipe proposals are separate learning tasks; the latter two remain conditional additions.

## The product to build

Build a **Cyrus Design Lab** companion workflow: give it a site, enrolled plant assets, a brief and optional references; review a small set of different planting proposals; mark preferences or make corrections; save a chosen recipe and apply it to the intended scene. The name is a proposal, not an existing application.

The central learning target is: **which valid, editable planting composition does this artist or studio prefer for this brief and site?** It is not a universal beauty score. A dense meadow, a formal entrance and a restrained architectural courtyard need different answers. A composition can look attractive in one camera while obstructing a route or failing elsewhere.

The engine should continue deciding whether candidates are eligible, how final transforms affect radii, which collisions reject them, and whether a complete result can be published. The learning system proposes bounded parameters, asset roles, areas and relationships that the engine can actually execute. It reports uncertainty and unsupported requests.

## Decisions for the first implementation

| Decision | Reason | Evidence needed to revisit it |
| --- | --- | --- |
| Start with recipes, search and a review gallery | Useful before model training; exposes missing execution/data contracts | Artists cannot express worthwhile variation with the recipe vocabulary |
| Train a small preference ranker first | Directly uses A/B comparisons; can inspect feature contributions and uncertainty | Held-out evaluation shows a richer model gives material benefit |
| Keep inference and training outside Max | Avoid dependency conflicts and unpredictable work on the host thread | A measured deployment constraint justifies an embedded inference runtime |
| Keep scene writes typed and transactional | Existing ownership, revision, validation and publication contracts are valuable | No evidence currently supports an arbitrary-script escape hatch |
| Use a finite workflow with bounded refinement | Restart, cancellation and budgets are easier to test | The benchmark requires genuinely open-ended planning |
| Use simple metadata/recipe retrieval initially | Relevant artist examples can guide proposals without training | A controlled retrieval experiment shows graph or vector search improvement |
| Keep personal profiles separate from studio defaults | Disagreement may represent legitimate taste or role differences | Explicit studio policy defines an aggregation rule |
| Preserve rejected, tied and skipped comparisons | They provide different information; discarding them biases the record | Retention/consent policy requires removal, which must be recorded |
| Leave the rendering engine and retained previews intact | Their behaviour is already part of the product contract | A measured bottleneck and acceptance test justify a targeted change |

## Why this direction is supported

**GardenDesigner (CVPR 2026)** combines procedural generation, expert asset knowledge and spatial constraints for Jiangnan gardens. It is a strong reason to test artist-authored rules and a structured asset catalogue. Its garden style, implementation and study are narrower than our product; its reported generation speed is not a Cyrus estimate. [Paper](https://arxiv.org/abs/2604.01777), [project](https://monad-cube.github.io/GardenDesigner/).

**PreferThinker**, revised June 2026, studies inferring a preference profile and then assessing images. **XPASS-Vis**, June 2026, explicitly studies preference transfer across visual domains and still reports a substantial generalization gap. Together they motivate editable profiles and evaluation on new sites; they do not establish that photographic taste transfers reliably to procedural planting. [PreferThinker](https://arxiv.org/abs/2511.00609), [XPASS-Vis](https://arxiv.org/abs/2606.15629).

**CRED (ICRA 2026)** investigates generating informative preference queries. **NAOD**, a 30 September 2026 preprint, addresses biased model judges under active query selection. These suggest experiments in choosing useful comparisons and retaining trusted human anchors. Their robotics and language-model settings are different from Cyrus. [CRED](https://arxiv.org/abs/2603.08531), [NAOD](https://arxiv.org/abs/2609.38860).

The practical inference is to invest first in controllable generation, valid data and discriminating experiments. It is not to reproduce every agent architecture from these papers.

## Three levels of learned behaviour

1. **Selection:** retrieve examples and rank generated candidates. The artist still sees alternatives. This is the first ML milestone.
2. **Guided proposal:** predict useful ranges, source mixtures and spatial recipes, then search locally. The engine validates every proposal. This follows evidence that selection helps.
3. **Sequential editing:** choose a series of actions in response to feedback. Only attempt this if logged edit sequences show a task that one-shot search cannot solve efficiently. This is where contextual bandits or RL might become justified.

An improvement in a learned score is insufficient at every level. Promotion requires blinded artist evaluation, valid geometry, retained diversity and acceptable cost.

## What “professional composition” means operationally

Begin with a small agreed rubric: brief adherence, readable circulation, foreground/midground/background structure, focal hierarchy, planting rhythm, negative space, believable scale, plant-role compatibility and editability. Record which criteria an artist considered, but allow preference without forcing a reason.

Some requirements are hard constraints: an exclusion area, locked plant, maximum memory budget or approved asset set. Others are soft preferences: a loose flower drift, asymmetry, richer layering or a quieter palette. Do not let a high aesthetic score compensate for a violated hard constraint.

Horticultural suitability, accessibility and real construction compliance require additional domain data and review. An aesthetically convincing render alone does not establish them. The first product should be described as a composition assistant for visual scene design.

## First useful vertical slice

Use a disposable copy of a courtyard site with a fixed camera set and a curated asset palette. Allow a small recipe vocabulary: plant-role mixture, scale range, spacing, density/target, cluster/edge distribution and approved flower zones. Produce 12–24 distinct valid candidates, show consistent previews, collect A/B/tie/neither feedback, replay a chosen candidate and preserve its editable controls.

The initial number is a proposed usability batch, not a model-training requirement or current MCP allowance. Existing MCP only permits two successful applications per enrollment; a separately specified batch contract is required before this slice is automated at scale.

The next milestone is a baseline study: can retrieval plus a small ranker reduce time to an artist-approved result compared with curated recipes and unranked variation? If it cannot, diagnose representation, controls and labels before escalating model size.

## Explicit deferrals

Defer a custom foundation model, per-instance autoregressive placement, unrestricted recursive agents, a graph database, automatic cloud collection, online weight updates inside Max, and GPU scatter compute undertaken solely for the ML feature. Each adds cost without resolving today's missing policy-3 automation and evaluation contracts.

Also defer promises about how many comparisons guarantee quality. Sample needs depend on task diversity, reviewer consistency and what the model must generalize to. Learning curves and project-level holdouts decide readiness.

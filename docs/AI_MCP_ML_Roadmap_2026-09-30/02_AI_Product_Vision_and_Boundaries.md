# 02 — Product vision and boundaries

**Status: PROPOSED product direction; benefits are RESEARCH HYPOTHESES until measured.**

## The job to solve

An environment or visualization artist already has a site and licensed assets. They need a convincing, editable distribution that respects open space, circulation and composition. Cyrus can help translate a brief and reference into a first procedural layout, explain its choices, and let the artist finish.

The proposed feature succeeds when the artist reaches an acceptable layout with less total work. A visually impressive first image is insufficient if revisions are slow, constraints are violated or the artist has to rebuild it.

Initial audience: artists already comfortable checking a Cyrus result. Studio pipeline users are a later audience once ownership, offline operation, host qualification and diagnostics are proven.

## Division of responsibility

| Responsibility | Proposed authority |
| --- | --- |
| Interpret the brief, suggest layer roles and explain uncertainty | General multimodal model |
| Supply site scale, asset dimensions, IDs, masks and current state | Local scene adapter |
| Decide what may change and what may leave the machine | Artist and studio policy |
| Validate parameters, references, ownership, bounds and constraints | Cyrus automation API |
| Produce seeded transforms and procedural output | Existing engine through qualified adapters |
| Judge whether the result serves the project | Artist |
| Improve a narrowly measured failure later | Optional retrieval or specialized ML |

MCP transports defined operations. It is not itself the design planner, geometry solver, permission system or training pipeline.

## Supported starting brief

“Use this image as a composition reference. Keep the marked centre open, put taller trees in this confirmed belt, use these shrubs in this border, and use this low plant sparsely in the remaining marked region.”

This is a good experiment because the site coordinates and assets are known, the aesthetic request is bounded, and success can be compared with a manual preset.

A single image can suggest visual hierarchy, relative density, scale relationships, irregularity and foreground/background. It cannot reliably determine metric layout, hidden instances, exact plant species, ecological suitability or structural/circulation compliance.

## Translate visual language into explicit controls

| Artist phrase | Proposed interpretation | Required evidence or clarification |
| --- | --- | --- |
| “Dense tree belt” | Named region, tree sources, count/density and boundary clearance | Actual site area and asset footprint |
| “Shrub clusters” | Planting islands or a density field; possibly correlated source assignment inside them | Specify spatial clumps versus source grouping |
| “Natural” | A stated combination of irregular spacing, variation and composition | Show a preview; the word alone has no single parameter value |
| “Leave the middle open” | An explicit protected polygon | Artist confirms polygon; camera centre is not world-space centre |
| “Trees on the left” | Camera-relative suggestion linked to a confirmed world region | Fixed camera and region mapping |
| “Match this species” | Suggest an approved asset category | Artist identifies species/asset; no invented catalogue entry |
| “Hero tree here” | Explicit anchored placement with protected footprint | Later endpoint and stable edit identity; MVP can use a manually placed locked asset |
| “Keep what I edited” | Preserve manual/locked objects and affected generations | Ownership and revision tracking; no fuzzy promise |

**VERIFIED IN CURRENT CODE:** source diversity clustering does not generate positional plant clumps. Existing radius/area controls are not full 3D collision certification. These semantic distinctions must appear in both plans and the UX.

## MVP scope and exclusions

**PROPOSED:** new owned controller, one static horizontal planar site, three approved mesh assets and up to three simple convex regions/layers. Existing site, source geometry and authored regions are read-only. The API may create up to three owned inset mask shapes derived deterministically from those regions; the approval preview lists them. AI-drawn regions require an explicit later preview/confirmation workflow.

The artist may inspect all settings and continue using the ordinary plugin after accepting a proposal. Existing CS Edit changes are preserved by excluding edited controllers from initial AI mutation, not by pretending their identity problem is already solved.

**FUTURE / OPTIONAL:** sloped and complex multi-element sites, asset catalogues, Analyzer-guided streets, edge rows, falloff, scoped edits to existing layouts, reference segmentation, local models and studio preferences. Each needs a stated contract and tests.

The first prototype does not render, export files, download assets, create arbitrary helpers, run scripts, train models or make construction/ecological decisions. A manual preview render remains available through the artist's usual workflow.

## Differentiation to investigate

| Possible value | Engineering reality | Claim status |
| --- | --- | --- |
| Natural-language setup | Feasible once typed commands and context exist | REQUIRES EXPERIMENT: setup time and error rate |
| Reference-informed composition | Depends on asset/site matching and explicit regions | REQUIRES EXPERIMENT: blind artist preference |
| Editable, constrained results | Strong fit with procedural engine; needs ownership/undo work | PROPOSED implementation promise |
| Learned studio preference | Needs consent, repeated outcomes and studio isolation | FUTURE / OPTIONAL |
| Automatic self-improvement | No current dataset or learning pipeline | Unproven; do not advertise |
| Must-have for every artist | Depends on workflow, adoption and willingness to pay | Unsupported market claim |

No competitor absence or superiority is asserted here. The [commercialization positioning review](../Product_Commercialization_Playbook_2026-09-30/06_Competitor_and_Positioning_Review.md) remains the place to maintain sourced competitor evidence.

## Product stop rules

Stop or narrow the feature if:

- A saved preset reaches an acceptable result as quickly with less review effort.
- Artists repeatedly reject the interpretation or cannot predict what a command will change.
- Correcting asset mismatch dominates any setup savings.
- Privacy policy prevents the necessary inputs and the offline fallback is not useful.
- Model cost, waiting time or support effort exceeds the value of the task.
- Reliable scene editing cannot be demonstrated on the declared host matrix.

A failed reference experiment does not invalidate automation or curated presets. Preserve useful capabilities and remove the unsupported claim.

## Success definition

**PROPOSED:** a reversible proposal that respects every hard constraint and reduces paired, end-to-end time to an artist-accepted layout. Also measure correction workload, repeat use, uncertainty handling and failure recovery. The numeric decision rules live in [11](11_Evaluation_and_Benchmarks.md), not in marketing copy.


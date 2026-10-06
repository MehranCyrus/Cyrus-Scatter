# Artist workflow and preference collection

Everything in this document is proposed. The current plugin does not have this review gallery or learning service.

## A typical session

1. **Choose the working scope.** Select a disposable study scene or an explicitly owned setup. Enroll the site, exclusions, asset palette and cameras. Display units, missing assets, unsupported features and the current engine version.
2. **Describe the goal.** For example: “A restrained courtyard, clear entrance, loose grass masses, a winding flower ribbon and occasional taller accents.” Choose a personal or studio profile. References are optional and may contribute different aspects.
3. **Confirm a small design brief.** Show editable roles and constraints: keep paths clear, preserve the building, use these assets, lock these trees, prefer this height hierarchy. Separate required constraints from preferences.
4. **Choose a variation budget.** The local UI authorizes a defined disposable batch and shows its limits. Begin with a small batch. The system estimates work from measured pilot timings, not an assumed render speed.
5. **Browse alternatives.** Show a grid of consistent thumbnails grouped by visibly different composition. Select a card to inspect the same hero, top and side views, statistics, warnings and effective recipe.
6. **Compare useful pairs.** A/B, tie, neither acceptable, or skip. Add optional reason tags. An artist can favourite several directions without declaring one universal winner.
7. **Refine a direction.** Request “more like this,” adjust a range, paint a desired flower area, or lock a feature. Refinement branches from an immutable candidate; it does not overwrite its evidence.
8. **Choose a result.** Verify its full-detail output and apply it through a separate owned-scene transaction. Keep the recipe and ordinary Cyrus controls editable.
9. **Save feedback.** Record the explicit comparison and any separately approved learning eligibility. Model training is a visible later job; it does not happen on every click.

The most frequent actions should be Compare, Keep, More like this, Adjust, Pause and Apply chosen. Dataset administration, model details and diagnostic traces belong in secondary panels. Show concise explanations such as “Keep saves this candidate; it does not change your scene” and “Neither means both results miss this brief.”

## The meaning of each feedback action

| Action | Stored meaning | Must not imply |
| --- | --- | --- |
| A better than B | A conditional pairwise preference for this brief, view set and reviewer | A is acceptable or globally better |
| Tie | Reviewer sees no meaningful difference on the stated criterion | Two identical layouts or missing data |
| Neither acceptable | Both fail the brief; optionally record which is less bad separately | An ordinary tie between acceptable designs |
| Skip / cannot judge | No preference label; retain reason if given | Negative feedback |
| Favourite | Candidate worth keeping under the current brief | Every unseen candidate is worse |
| Approved for use | Explicit task-level acceptance with the reviewed generation | Training permission, commercial asset permission, or universal quality |
| Manual edit | A changed scene, recipe or instance with exact before/after lineage | Every changed value was disliked; routine asset repair is taste |
| Render failed | Execution/asset/renderer failure | Aesthetic rejection |
| Delete from gallery | Visibility/retention action with defined policy | Erasure from previously trained weights |

Keep rejected metadata and comparisons when consent permits. Large image/scene artifacts can have a retention policy; deleting the only rendered evidence should mark a record as unavailable for image training. Do not silently convert an absent artifact into a black-image negative.

## Personal, studio and project preferences

A reviewer is not a universal truth label. Store a pseudonymous reviewer ID, the profile being used, project/brief ID and timestamp. A boss selecting designs for a client may be judging budget and delivery constraints that another artist is not considering. Ask for the task context, not a personality inference.

Start with separate personal profiles and an explicit studio-default profile. For the latter, define whether a designated art director decides, reviewers vote, or a published rubric sets priorities. Preserve individual responses even when the studio chooses a different outcome. Use a shared model with conservative per-profile adjustment only after there is enough data; unseen users receive the documented default.

Support profile versioning and project overrides. “I prefer denser flowers for this job” should not immediately rewrite the artist's long-term profile. A reference board can temporarily condition a session without being added to training.

Research on heterogeneous preference learning and reward features supports treating user differences explicitly, but its experiments do not settle the correct studio governance rule. [Variational preference learning](https://proceedings.neurips.cc/paper_files/paper/2024/hash/5e1c255653eb98cef13f45b2d337c882-Abstract-Conference.html), [reward features](https://proceedings.neurips.cc/paper_files/paper/2025/hash/761bc7f095f927e5a5de31ed4154bb45-Abstract-Conference.html).

## Reduce review fatigue without manufacturing labels

Use a diverse overview first, then pairwise decisions. Do not ask artists to review all pairs from thousands of candidates. Show roughly comparable candidates when studying a subtle change, and intentionally different candidates when discovering a style direction. Randomize left/right placement and hide the generating model/score during benchmark judgments.

A proposed pilot session is 10–20 comparisons followed by a break, with a small number of repeated or reversed pairs. This is a starting usability test, not a scientifically established optimum. Measure completion time, skip rate, repeat agreement and fatigue. Repeats reveal uncertainty; they should not be used to punish a reviewer for subjective changes.

Offer optional reason tags: density, grouping, height, colour, path clarity, focal balance, scale, realism, brief mismatch, technical problem. Allow “another reason.” Require neither an essay nor a model-generated explanation. A model may suggest tags, but artist acceptance and model suggestion must be separate fields.

## Model containers in this workflow

A rectangle of source models is a visual palette. Moving an enrolled source out parks its participation while its source registration and settings remain. It does not create a new scatter receiver or a new aesthetic preference label.

For a batch, snapshot the active membership and each source's geometry/material version, scale, radius and forward axis. If a source moves, is deleted or changes geometry while work is running, pause dependent jobs or explicitly fork a new context. A silent palette change makes before/after comparisons invalid.

Use role tags alongside geometry: groundcover, flower accent, shrub mass, canopy, border, specimen. Tags should be artist-editable. The system can propose a role from an image, but cannot infer reliable plant identity or ecological requirements solely from a thumbnail.

## Artist corrections as richer data

Record the exact immutable before candidate and after candidate, what was explicitly changed, and whether the artist says the change improves the result. Moving a plant, changing a seed and replacing an entire layer are different operations.

Only link instances across generations when stable identity and compatible lineage establish correspondence. Spatially nearest plants are not necessarily the same plant. Without reliable matching, store a whole-layout or parameter correction. Preserve locks and protected conflicts in the after state; don't teach the model that every collision is freely removable.

## Required recovery behaviour

Closing the review panel must not discard a submitted comparison. A lost connection must not submit the same preference twice. Reopening a batch must show completed, failed, cancelled and unreviewed candidates accurately. A candidate card must never display an old image with a new recipe.

These behaviours are part of the first usable product, not later polish. The [data contracts](08_DATA_AND_EVALUATION.md) and [workflow state machine](07_ARCHITECTURE_AND_GRAPHS.md) define their implementation boundaries.

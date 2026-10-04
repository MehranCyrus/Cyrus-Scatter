# Data, learning and evaluation

**PROPOSED.** No dataset was collected and no model was trained for this report. Numerical pilot sizes or decision thresholds below are suggested experiment budgets, not proven minimum training requirements or achieved results.

## Four evidence collections

| Collection | What to store | Valid use | Invalid assumption |
| --- | --- | --- | --- |
| Reference board | Images, descriptions, artist annotations and permitted-use metadata | Intent extraction and retrieval | Every image contains recoverable plant coordinates or a density label |
| Approved recipe library | Brief, site type, roles, settings and actual accepted output | Reuse and supervised recipe examples | An accepted setting guarantees the same appearance with different assets |
| Authored planting patches | Positions, role/source dimensions, boundary, units and context | Statistical pattern extraction and exemplar transfer | Many points from one patch are many independent artistic examples |
| Preference/correction records | Comparable alternatives, choice/tie/neither, before/after and reason | Personal ranking and carefully qualified labels | Every deletion is a negative plant example, or every Undo means dislike |

Use explicit inclusion in a personal or studio learning library. Operational diagnostics are not automatically training data. The existing execution and correction contracts already default to ineligible; retain that behavior.

## Minimum useful record

For every supervised or preference example, link:

1. The brief, reference IDs, profile revision, project group and permitted uses.
2. The site snapshot, coordinate system, zones/protected areas, camera if relevant, asset-role bindings and source revisions.
3. The proposed recipe, compiled/normalized plan, generator version and seed.
4. The execution receipt and actual final transforms, layer/set membership, counts, exclusions and underfill.
5. The observed representation: centres, Proxy, Point Cloud, Mesh or a specifically configured render. Record preview budget and camera calibration when available.
6. The artist's outcome, optional reasons, correction lineage and elapsed effort including review, waiting and repairs.

Missing data stays null. A profile ID is not a consent record. Store only needed scene-derived data, with project/studio isolation and explicit export controls. Large local artifacts use hashes and bounded references; credentials and absolute asset paths do not belong in a training record.

The current MCP exporter covers part of steps 2–4 for its owned current generation. Arbitrary artist-scene collection, saved Brush/zone payloads, calibrated observations and a durable feedback library still need implementation.

## How to learn from a 3D patch

First ask the artist to identify the patch boundary, its plant roles and whether it represents an interior area, path edge, border, focal group or complete composition. Record the distinction so an interior jungle patch is not used blindly at a building entrance.

Extract a compact descriptor from actual output:

- Plant and role counts divided by the declared usable area.
- Source height and footprint distributions, both in metres and normalized relative to comparable assets.
- Nearest-neighbor distances within and between roles; report boundary treatment.
- Directional alignment, repeated spacing, cluster scale and empty-space distribution.
- Relationships to authored paths, borders, obstacles and cameras when those are known.

Begin with simple summaries and recipe fitting. Compare a fitted procedural result with example retrieval and, later, a direct exemplar synthesis method. Nearest-neighbor statistics alone do not uniquely identify a pattern; inspect directional and cross-role behavior and use artist evaluation. Do not infer biological causation from visual correlations.

When fitting, measure the final constrained output. If exclusions and collision delete much of the proposed population, matching pre-filter parameters teaches the wrong relationship. Keep the artist's hard spacing requirements and report incompatibility instead of quietly relaxing them to make a descriptor score better.

## Synthetic data factory

Cyrus can provide paired inputs and outputs by generating controlled fixtures with known settings. This is a future data tool, not permission to run thousands of production MCP applications. The current MCP has strict scope budgets; a batch runner needs its own isolated fixture policy and qualification.

Use the same production generation implementation or a qualified host harness. A separate approximate scatter simulator can create misleading training targets if its masks, spacing or random streams differ from Cyrus.

Vary independently: site shape/scale, protected regions, source sizes, role mixtures, spatial settings, population, camera and seed. Include failures and underfill as labelled outcomes. Also include changed source assets, so the model cannot solve “dense” by memorizing one mesh's footprint.

Capture actual transforms and settings as ground truth. Later, capture standardized top views, semantic role masks, depth and perspective views where a qualified exporter exists. Fix or vary lighting deliberately to separate layout preference from attractive illumination. Beauty renders can supplement evaluation; they should not be the only supervision.

Infinigen demonstrates a procedural-data workflow with generated scenes and ground-truth outputs. It is useful precedent, but adopting its entire stack is unnecessary for a Cyrus-native fixture generator. [Official repository](https://github.com/princeton-vl/infinigen), [ground-truth documentation](https://github.com/princeton-vl/infinigen/blob/main/docs/source/GroundTruthAnnotations.md)

Synthetic records teach the relationship between Cyrus controls and layouts. They do not, by themselves, teach what a particular artist prefers. Human choices and approved edits supply that signal. Avoid generating labels from the same rule used to score them and then reporting the result as independent aesthetic intelligence.

## Training stages

| Stage | Input → learned result | Training approach | Stop condition |
| --- | --- | --- | --- |
| No custom training | References/context → relevant approved recipes | Metadata filtering, retrieval, explicit preferences | A useful baseline is already sufficient |
| Statistical personalization | Approved 3D patches → parameter priors | Fit simple distributions/pattern descriptors | Transfer harms composition or cannot satisfy constraints |
| Personal ranking | Same-context alternatives → relative preference | Regularized linear pairwise baseline, then a small boosted ranker if warranted | No improvement on held-out projects or too little reliable feedback |
| Structured planner adaptation | Context/references → accepted typed recipes | Supervised adapter training against a selected compatible base | Retrieval/base model is equally good or better |
| Learned spatial fields | Registered context → approved role/intensity maps | Narrow field model with independent final validation | Data domain, visual quality or correction cost remains unreliable |

A first pairwise baseline can learn a score `s(features, profile)` with probability `sigmoid(s(A)-s(B))`. Group comparisons by the same site, brief, asset palette and intended view. A later boosted ranking model can use query groups; XGBoost documents that formulation. Never compare “artist A's jungle” directly against “artist B's courtyard” as if the labels reflected one objective. [XGBoost ranking guide](https://xgboost.readthedocs.io/en/stable/tutorials/learning_to_rank.html)

Personal models with little data should stay close to an explicit default or studio profile. Retain a “not enough evidence” state. More preferences may justify adaptation, but there is no defensible universal promise that ten, fifty or one hundred images produces a reliable layout model.

For LoRA, select the output task and base first, then freeze the data manifest, splits, code/configuration, adapter settings and evaluation protocol. Compare with that same base without adaptation. Record wall time, peak memory, failures and inference cost; do not borrow training-time estimates from an unrelated image-model tutorial. Release a new profile revision only after evaluation and artist confirmation. Keep the previous revision available.

## Split correctly

Group all revisions, camera views, seeds, crops and near-duplicates from the same underlying project/site family into one partition. A hundred screenshots of one scene must not appear across training and test splits. Group-aware splitting tools provide a mechanism, but choosing the right project groups remains our responsibility. [GroupKFold documentation](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.GroupKFold.html)

Evaluate several distinct questions:

- **Personal transfer:** known artist, new project geometry and asset palette.
- **New-artist cold start:** no personal training records; test defaults and reference retrieval.
- **Style separation:** the same artist's formal and lush profiles remain distinguishable.
- **Asset transfer:** equivalent plant roles with different dimensions/meshes.
- **Site/camera transfer:** wide view versus eye level; narrow beds versus broad sites.
- **Cross-studio generalization:** hold out a studio only if making a cross-studio product claim.

Keep the final test set out of prompt/example selection and tuning. Retrieval libraries used by an evaluation must not contain the held-out answer or a near-duplicate scene.

## Metrics that matter

The primary product outcome is **time to an artist-accepted layout**, including setup, model waiting, reviewing alternatives and correcting them. Record full distributions and failures, not just the best screenshot or fastest run.

| Dimension | Measure |
| --- | --- |
| Correctness | Valid schemas; enrolled IDs; final footprint/zone violations; stale-result rejection; Undo integrity |
| Expressibility | Unsupported intent detected; approximation disclosed; requested versus supported pattern |
| Artist value | Accepted without correction; correction time; blinded A/B preference; ties/neither; retained manual work |
| Spatial style | Role proportions, spacing/clustering/direction summaries, open space, boundary behavior and asset scale |
| Composition | Artist-rated facade visibility, focal balance and depth; calibrated view measures only when available |
| Reliability | Repeatability under pinned inputs, failure rate, cancellation/recovery and offline behavior |
| Resource use | Proposal latency, time in Max, peak RAM/VRAM, model load/unload and cold/warm runs |
| Viewport | Camera-step and presented-frame timing where available; p50/p95; cache rebuild counters and contention |

Image similarity is a secondary diagnostic. A layout can resemble a reference while blocking a doorway, using the wrong asset role or failing in another view. Evaluate geometry and artist judgment independently. Do not score learned style using only the same encoder used to retrieve its examples.

## Experiment sequence

All experiments below are pending. Start with a small coverage pilot, for example 12 distinct sites across formal/lush/mixed briefs, including several palettes and viewpoints. This tests the workflow and exposes failure classes; it is not enough by itself to claim general model quality. Expand based on uncertainty and learning curves, not a fixed marketing dataset count.

| ID | Question and comparison | Go / no-go evidence |
| --- | --- | --- |
| E01 | Can the desired style be expressed? Artist-made recipes versus current supported MCP controls | Identify exact missing controls before any model training |
| E02 | Does the profile workflow help? Manual presets versus profile/recipe retrieval | Less time to accepted result, with all limitations visible |
| E03 | Does a general planner add value beyond retrieval? Same examples and assets for both | Better accepted drafts, accounting for inference/review time |
| E04 | Do authored patches transfer? Fitted descriptors versus nearest recipe and manual settings | Artist preference on new sites; no new boundary/seam failures |
| E05 | Is whole-layout ranking useful? Linear baseline versus boosted ranker versus artist-selected preset | Held-out ranking gain and reduced corrections, with uncertainty reported |
| E06 | Do visual features help? Metadata-only versus one frozen encoder | Better retrieval/ranking without confusing lighting with planting structure |
| E07 | Is a planner LoRA justified? Same base+retrieval versus base+retrieval+adapter | Additional held-out artist value with acceptable cost and structural validity |
| E08 | Are learned fields necessary? Best recipe generator versus bounded field proposal | Better patterns that remain editable and satisfy constraints |
| E09 | Does local inference interfere with Max? Companion off/idle/loading/inferencing | No unwanted regeneration; quantified navigation/memory effect and workable scheduling |
| E10 | Can profiles be trusted operationally? Swap/import/cancel/stale-scene/failure fixtures | Correct profile binding, no partial application and successful fallback/rollback |

Proposed initial promotion rule: zero known contract/ownership violations in the release suite, and a material improvement in artist time or preference over the best simpler baseline. Before testing, agree the minimum worthwhile improvement with the artists; a possible planning target is 20% less median time, but it is **not an achieved result or a statistical sufficiency rule**. Report per-artist/project outcomes and uncertainty, and reject a release that improves the average by creating severe regressions for another style.

## Learning loop and maintenance

Collect explicitly → review provenance and labels → version dataset → train candidate → evaluate on held-out projects → artist review → publish profile revision → monitor opted-in outcomes → retain rollback.

Changing units, feature extraction, role definitions, source footprints, generator semantics or model preprocessing invalidates assumptions behind old models. Keep compatibility tests and re-evaluate affected profiles. Removing a sample from future datasets does not automatically remove its effect from existing trained weights; mark affected model versions and decide whether to retire or retrain them. Keep individual and studio learning scopes distinct.

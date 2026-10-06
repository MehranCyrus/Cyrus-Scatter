# Dataset, evaluation and model lifecycle

## Three data products

Keep **operational diagnostics**, **review records** and **training datasets** separate. Diagnostics explain execution. Review records preserve explicit artist decisions. A training dataset is a reviewed, versioned selection of eligible records with known provenance and splits. A log entry does not become training data simply because it was saved.

Current `cyrus.execution/1.0` records explicitly set `training_eligible=false`. Preserve that behaviour. A future dataset builder can establish eligibility through a separate provenance and consent decision; do not flip the flag in existing records merely because an artist clicked Keep.

## Required record families

| Record | Essential fields |
| --- | --- |
| Study/context | Stable study ID; project/site family; units/coordinate conventions; brief/profile version; source/receiver/exclusion references and hashes; rights/consent references |
| Candidate recipe | Candidate ID; parent candidate; recipe family/version; normalized effective settings; stable layer/set/source IDs; seed/salt; allowed-scope reference; recipe digest |
| Execution attempt | Attempt/operation IDs; engine/script/native hashes; SDK/Max version; base revision; timing; status; errors; work counters; publication ID and transform digest when successful |
| Layout artifact | Ordered actual transforms, source/instance IDs, effective radii, visibility/protection state, counts and reasons; schema/units; checksum |
| View artifact | Candidate/publication/digest; camera matrix/lens; renderer/version/profile; lighting/material/assets; dimensions; colour/tone settings; render seed/pass/time policy; completion status; checksum |
| Comparison | Ordered candidate/view-set IDs; displayed left/right; reviewer/profile/brief; A/B/tie/neither/skip; optional acceptance/reasons; selection policy; event ID; consent references |
| Correction | Immutable before/after; explicit changed properties; verified correspondence or whole-layout change; artist-stated intent and improvement when supplied |
| Dataset manifest | Included immutable records; exclusions/reasons; rights status; grouped split assignments; feature pipeline/version; dataset checksum |
| Model registry | Model/feature/schema versions; training dataset; parameters/code revision; evaluation report; intended domain; limitations; promotion/rollback state |

Store raw observations alongside normalized features. Record requested counts and actual accepted counts separately. Keep source materials/geometry identity sufficient to reproduce an appearance without copying licensed assets into a shareable dataset by default.

## Identity and coordinates

Use stable project/study/candidate IDs independent of file names. A Max node handle alone is not a portable cross-session asset identity. Use enrolled asset IDs plus content/version references. Stable source registrations and instance IDs have different lifetimes; preserve each explicitly.

Existing MCP execution IDs are generation-scoped. Do not infer that instance 42 in one generation matches instance 42 in another. Record verified lineage, or `null` for unknown correspondence. A transform digest can confirm one publication without establishing semantic correspondence to a later publication.

Specify metres, degrees, handedness, up axis, matrix convention and camera convention in the record schema. Convert at one boundary and test round trips. A scene unit change invalidates derived metric features. Do not reuse an old Brush binding or radius interpretation silently.

## Storage and durability

The [identity-survival matrix](14_HOUDINI_ENGINEERING_LESSONS.md#identity-must-survive-named-operations-not-every-possible-edit) adds named-operation obligations: rejection compaction, source parking/reentry, rename/delete/recreate, layer ordering, topology change, clone and save/reload. Stable IDs do not promise unchanged output after changed dependencies. P1 must distinguish verified correspondence from unknown lineage and preserve that distinction in correction examples.

For the first local product, use relational metadata with foreign keys and immutable event IDs. Store larger images/layout arrays in an artifact directory addressed by a checksum. A database transaction records an artifact only after its file is durably written and verified. A startup reconciliation finds incomplete attempts and orphaned files without pretending they are successful candidates.

Use unique constraints to prevent duplicate comparison submission. Save model scores as observations with model version, not as replacements for human labels. A retracted comparison stays traceable through a retraction event; dataset manifests exclude it on the next build.

Dataset snapshots are immutable. Deletion/retention operations invalidate affected future dataset builds and identify models trained on removed records. Do not promise retroactive removal from model weights without an explicit retraining/unlearning process. A local export must include a manifest and verify artifact integrity on import.

## Consent and rights as product fields

Track separately: permission to inspect a scene, to run a batch, to capture images, to send selected content to an external service, to retain review data and to use it for training. Scope can be private to an artist, a project or a studio. These choices need clear UI and defaults, not hidden inference from operational activity.

Record asset/reference provenance and restrictions. A model/checkpoint's code license and weight license may differ. Commercial plugin licensing, renderer licensing, training-data rights and cloud processing permission are separate concerns. This document defines engineering fields and gates, not legal conclusions about a particular asset contract.

Do not store license secrets, access tokens, personal filesystem paths or unrelated scene contents in training records. Use pseudonymous reviewer IDs and scoped artifact references. Record enough build identity to reproduce behaviour without exposing credentials.

## Splits that prevent easy leakage

Hold out entire project/site families. Near-duplicate renders, alternate cameras, seed variants and mutations from one recipe family must not straddle training and test by accident. Group by shared base scene, reference board, asset family and candidate lineage as appropriate to the question being tested.

Use separate evaluations for:

- Known artist on a new site with familiar assets.
- Known artist on unfamiliar assets or style.
- New artist with no labels, then a small explicitly collected adaptation set.
- Studio-default profile versus personal profile.
- Reference-conditioned design versus brief-only design.

The same model need not pass every scope initially. Publish the supported domain. A single successful courtyard is a demo, not evidence of cross-project learning.

## Metrics and gates

| Level | Metrics | Decision |
| --- | --- | --- |
| Execution correctness | Wrong-publication images, stale applies, duplicate writes, constraint violations, unknown outcomes | No known identity/ownership/constraint breach is acceptable in the qualification suite |
| Preference prediction | Pairwise accuracy/log loss, tie handling, calibration and per-profile performance | Must beat simple recipe/retrieval baselines on grouped holdouts |
| Practical quality | Blinded artist win/tie/loss, acceptance rate, time to usable design, correction effort | Primary evidence for product usefulness |
| Diversity | Distinct accepted families; geometry/image near-duplicate rate; coverage of artist-relevant descriptors | Prevent a high average score from hiding mode collapse |
| Robustness | New sites/assets, sparse/dense limits, missing references, different seeds and renderer profiles | Identify supported conditions and fallbacks |
| Cost | Generation/render/inference wall time, memory peak, storage per candidate, review minutes, external API cost | Compare methods under equal budgets |
| Agent behaviour | Correct capability choice, executable plan rate, unsupported claims, unnecessary calls, recovery success | Promote orchestration/model changes independently of visual ranker changes |

Pre-register the primary comparison, baseline and budget before running a study. Report confidence intervals with project/site clustering; thousands of same-scene seeds are not thousands of independent trials. An exact required sample count should follow a pilot variance/power assessment, not an invented universal ML minimum.

A suggested promotion rule is a held-out artist preference improvement whose confidence interval excludes no improvement, or a predeclared non-inferiority result with a meaningful reduction in artist time. Choose the practical margin with the studio before evaluation. Report failure cases and per-profile results even when aggregate metrics improve.

## Human and model judges

Use human comparisons as the acceptance signal. A model judge can help triage obvious mismatches or generate advisory critiques, but store its labels separately. Randomize candidate order and use some order-reversed checks. Maintain a human-labelled audit set not selected solely by the judge being evaluated.

General image reward models learn from particular datasets and tasks. Their scores are not a universal landscape-quality measure. Position, verbosity and other biases in language-model judging also motivate controlled evaluation of any visual judge. [ImageReward](https://proceedings.neurips.cc/paper_files/paper/2023/hash/33646ef0ed554145eab65f6250fab0c9-Abstract-Conference.html), [MT-Bench/Chatbot Arena judging](https://arxiv.org/abs/2306.05685).

Grade actual outcomes in the scene and artifact store. A model saying “the path is clear” is not the path-clearance test. Agent evaluation guidance similarly distinguishes the action trace from the environment's final state. [Agent evaluation guidance](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents).

## Feature and inference contract (second pass)

Each model bundle needs a versioned feature contract in addition to its weights and training manifest. Record feature names/order, units, coordinate space, missing-value masks, categorical vocabulary, tensor shape/dtype, axis order and any variable-length policy. Fit normalization on the training split only; persist the fitted parameters. An unknown category or missing required feature must trigger a declared fallback or an actionable failure, never accidental index reuse.

For image features, pin decode/resize/crop/alpha handling, channel order, colour/tone interpretation, camera/view ordering and feature-extractor revision. For geometric features, pin how radii, area, distances and empty/underfilled layouts are measured. A feature may describe actual placement geometry or source metadata; it must say which.

Keep fixed input/output fixtures that run through both training preprocessing and inference preprocessing. Test finite values, empty layouts, unusual units, missing assets and out-of-domain values. If exporting a model, compare its scores and ranking behaviour against the reference implementation with declared tolerances. Qualify CPU and optional GPU providers separately, including fallback and memory contention. [E18](11_EXPERIMENTS.md#e18--feature-and-inference-parity) defines the promotion gate.

This requirement applies equally to a linear model and a neural model. It prevents a deployment mismatch from being misdiagnosed as a taste-learning failure. It does not require ONNX, a GPU or a new model framework.

## Model promotion sequence

1. Freeze eligible dataset and grouped splits.
2. Train only in the companion environment with reproducible configuration.
3. Evaluate offline against retained baselines and the untouched holdout.
4. Run a small shadow study: scores are logged but do not determine what artists see.
5. Run a bounded blinded comparison after shadow checks pass.
6. Promote a pinned model version with an evaluation receipt and supported domain.
7. Monitor failure, drift and cost; retain a one-action rollback to the previous model or recipe-only mode.

Feedback accumulation does not automatically mean the latest model is better. Keep data collection continuous when explicitly enabled, but model training and promotion deliberate and observable.

# 08 — Data and training strategy

**Status: PROPOSED data design. No telemetry, dataset collection or training was added by this task.**

## A useful example is a project outcome

One reference image is weak evidence. A useful record links a brief, site context, approved assets, proposed plan, actual generated layout, artist changes and acceptance. Ten camera crops or a million points from one scene do not create ten or a million independent projects.

The immediate activity should be **manual, local recording of owned pilot fixtures and explicit artist outcomes**. Automatic event capture belongs to a later approved implementation. Do not quietly turn product usage or licensing diagnostics into training data.

## Record from the first pilot

| Stage | Useful local record | Why |
| --- | --- | --- |
| Input | Brief, owned/licensed reference, source rights, selected site, confirmed zones, units/camera, source cards and pre-existing settings | Reconstruct the actual problem |
| Proposal | Model/provider ID when used, prompt/template version, interpretation, assumptions, normalized plan, seed and validation findings | Explain what was proposed and why it may fail |
| Execution | Operation IDs, actual tool calls, errors/recovery, host/build manifests, timings and cost fields when measured | Distinguish model and execution failures |
| Generated state | Complete local transforms/source/layer IDs, configuration, masks, exclusions, edge/falloff/collision/relax, source-assignment settings and output digest | Measure actual output, not just intention |
| Observation | Explicit viewport/camera/time/display mode, screenshot freshness, approved render settings if later used | Make visual comparison meaningful |
| Correction | Before/after, change type, stable correspondence or mapping uncertainty, optional reason | Avoid treating every edit as a preference |
| Outcome | Accepted/rejected/deferred, time to acceptable layout, optional rating and notes, final state | Measure artist value |
| Governance | Consent purpose, project/studio boundary, retention, deletion state and permitted uses | Prevent accidental reuse or leakage |

Never fabricate missing timestamps, cost, GPU memory, ratings or acceptance. Unknown stays null.

## What should stay out by default

Do not export scene filenames, absolute asset/network paths, usernames, customer identifiers, raw mesh/texture data, licensed source files, environment variables, credentials, desktop screenshots or unrelated scene objects.

A salted/pseudonymous project ID helps linking; it does not anonymize recognizable building geometry or imagery. Bounds, coordinates, embeddings and masks can still reveal a project. Treat them as project content.

Upload permission is scoped by data category, purpose and destination. Local diagnostic storage, cloud reasoning, product research, per-studio training and global training require separate decisions. Permission to render a commercial asset does not necessarily grant permission to redistribute it or use it in training.

Raw geometry should remain local by default. Any later export needs a concrete benefit, rights review and explicit studio authorization. Scene-derived structured summaries use an allowlist and user preview, not a general scene serializer.

## Practical storage and lineage

Use six versioned record families from [06](06_Structured_Design_Plan_Schema.md). Large arrays/images remain content-addressed local artifacts; JSON records hold digests, roles, dimensions, rights and permitted use.

A dataset manifest identifies immutable record/artifact digests, label/feature versions, exclusions and split membership. A training run records that manifest, code/configuration identity, model/checkpoint/runtime version and evaluation report. Corrections create a new dataset version; never mutate the historical training snapshot silently.

Build linkage includes package manifest digest, native/script identities, Max full version, algorithm/capability versions and schema. Marketing version alone is insufficient while existing version strings differ.

~~~mermaid
flowchart LR
  P["Owned pilot project and brief"] --> L["Local versioned records"]
  A["Artist corrections and explicit acceptance"] --> L
  L --> C{"Purpose-specific consent and rights"}
  C -->|No| LOCAL["Local operational use only"]
  C -->|Yes| D["Curated dataset manifest"]
  D --> SPLIT["Project and studio group split"]
  SPLIT --> F["Frozen features or small model experiment"]
  F --> E["Held-out quality, safety, time and cost evaluation"]
  E -->|Pass| R["Versioned optional model release"]
  E -->|Fail| B["Keep rules or retrieval baseline"]
  R --> O["Opt-in local feedback and rollback"]
~~~

## Dataset sizes: what could be attempted

**RESEARCH HYPOTHESIS:** these are planning stages, not sample-size guarantees.

| Independent examples | Sensible attempt | Evidence needed before increasing complexity |
| --- | --- | --- |
| 20–50 | Curated fixtures, manual baselines, prompt/schema failures, rules and a small recipe library | Rights, repeatable context, consistent acceptance rubric |
| About 100 | Retrieval, coarse style labels, possibly a tiny frozen-feature probe | Held-out projects and label agreement; avoid tuning to the whole set |
| About 500 | Small parameter/ranking experiments; domain evaluation of pretrained masks | Coverage across site/asset/style, confidence intervals and leakage audit |
| About 1,000 | Narrow supervised heads, preference ranking, targeted adaptation if supported | Learning curve, enough independent projects, strong heuristic baseline |
| 5,000+ | Broader adaptation and task diversity if labels/rights justify it | Distribution coverage and meaningful gains; count alone is not readiness |

For 1,000 examples:

- **Large multimodal fine-tuning:** may permit a narrow experiment on an available trainable model; not enough evidence to promise robust scene reasoning or train a large model from scratch.
- **Segmentation:** 1,000 carefully annotated independent images can support a domain adaptation study; 1,000 unlabelled pictures do not provide the required masks/classes.
- **Parameter regression:** plausible for a small, constrained feature space with consistent accepted settings.
- **Candidate ranking:** needs many distinct projects and explicit labels; candidate rows from the same scene remain correlated.
- **Style classification:** plausible for a small agreed taxonomy; ambiguous styles need multi-label/uncertainty treatment.
- **Preference ranking:** useful only when pairs share the same brief/context and their preference is actually recorded.
- **Retrieval:** often the earliest useful application, with little or no training.

## Splits, leakage and representativeness

Group all versions, cameras, crops, masks, augmentations, candidate points and artist corrections from a project in one partition. Where studio generalization is claimed, hold out entire studios. Keep a final test set untouched during prompt, rule, retrieval-index, feature and model tuning.

Stratify reporting by site type, style, asset palette, density, terrain eligibility, region complexity and host/display conditions. Prevent the retrieval library from containing the held-out target or a near-duplicate. Report both project count and derived sample count.

Define ground truth as an artist-approved result under a recorded brief, not the only universally correct landscape. Use multiple raters on a subset and preserve disagreements.

## Collection quality before collection volume

The first 20–50 fixtures should include success, rejection, ambiguity, a protected open area, an unavailable asset, thin regions, sparse/dense briefs, camera mismatch and a user taking over. Capture manual time using the same acceptance rubric.

A short optional reason is more useful than assuming every untouched point is loved. “No final decision” remains censored/unknown. Accepted AI output is not automatically a training target; an artist may accept it only because of a deadline.

## Retention and deletion

**PROPOSED:** local operational history has a visible retention limit and deletion control. Dataset inclusion is opt-in and reviewable. Revocation removes future dataset use and retrieval entries; track derived embeddings, snapshots and checkpoints that used the record.

Do not promise instant removal of a person's contribution from already-trained model weights. A release/retraining/retirement procedure is needed if that guarantee becomes contractual. Studio copies, backups and audit requirements must be resolved explicitly.

See [12](12_Security_Privacy_and_Studio_Constraints.md) for processing boundaries and [13](13_Performance_and_Infrastructure.md) for future infrastructure.


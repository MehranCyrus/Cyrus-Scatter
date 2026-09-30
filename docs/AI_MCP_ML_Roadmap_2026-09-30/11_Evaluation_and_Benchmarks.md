# 11 — Evaluation, benchmarks and experiment briefs

**Status: PROPOSED protocols and decision thresholds. None of these AI/MCP experiments has been run.**

## Compare the whole artist task

Primary outcome: time from a prepared brief/site/assets to a layout the artist accepts, including interpretation, waiting, review, corrections and recovery. Compare the same brief with a manual Cyrus preset workflow. Randomize/counterbalance order; use matched but distinct cases to reduce memory effects.

Record project count separately from repeated runs. Use project-level paired analysis and uncertainty intervals; repeated seeds/cameras from one project do not establish generalization. Keep prompts, model versions, recipes, engine/build identities, hardware, host, input permissions and evaluation rubric fixed during a comparison.

Safety and geometric correctness are hard gates. A prettier screenshot does not compensate for broken ownership, lost edits or invalid geometry.

## Metric set

| Dimension | Proposed measurement | Important limit |
| --- | --- | --- |
| Hard validity | Approved references only; no forbidden mutations; finite transforms; supported surface; footprint/region/clearance checks after generation | Current radius/pivot tests are not full geometry collision certification |
| Scene integrity | Before/after owned/unowned state, undo/redo and save/reopen fixtures; recovery after injected failure | Hash selected semantic state, not noisy whole-file bytes alone |
| Open space | Forbidden-region footprint intersections and occupied area fraction in world coordinates | Canopy silhouette and pivot occupancy are different quantities |
| Density/count | Requested, emitted and displayed counts; stems/m² by region; view coverage separately | Never infer true population from screenshot pixels |
| Layout | Nearest-neighbor distances, gap distribution, pair correlation where useful, boundary distance/alignment | No universal “naturalness” scalar |
| Source variety | Observed role/source proportions relative to the brief | More diversity is not always better |
| Semantic composition | Role/region hierarchy and explicit brief constraints; blinded artist rubric | A model judge alone is not ground truth |
| Visual resemblance | Optional embedding/mask/depth descriptors with fixed camera/display mode | Lighting, materials, crop and camera can dominate |
| Artist workload | Minutes, parameter edits and weighted move/delete/clone/swap events by layer/region | Normalize; dense ground cover must not swamp hero-tree edits |
| Acceptance | Explicit accept/reject/defer; preference versus baseline and reason | Saving/closing is not acceptance |
| Resources | Wall/active time by stage; peak host/helper RAM/VRAM; bytes/tokens/cost when actually measured | Missing values remain null |
| Reliability | Valid plans, bounded completion, stale/error handling, cancellation outcome | Zero observed failures is not proof of zero future risk |

## Why pixel similarity is insufficient

Different cameras, assets, seasons, materials or valid layouts can produce different pixels. Conversely, a visually similar crop can hide off-camera violations. Use local geometry for hard constraints, source/count data for population, semantic composition for intent, and artist judgment for value.

Embedding similarity is a weak style/retrieval signal. Segmentation can measure projected coverage but confuses canopy overlap with actual stems. Depth-aware comparison is meaningful only when calibration and scale are known. Use at least a top view and the intended composition view in evaluation, even if the initial agent captures only one designated view.

Evaluation staff can capture the second assessment view outside the agent's operational capture budget. Keep those evaluation artifacts separate from what the agent actually observed.

## Proposed stage gates

- **G0 — automation integrity:** zero forbidden mutations, stale commits or failed recovery in the declared fixture/fault suite; every failure has a structured outcome. Any scene-corruption or protected-edit failure blocks progression.
- **G1 — basic agent:** at least 90% valid completed tasks across 20 distinct prepared briefs, all within two candidate applications; zero hard-safety failures. Record repairs/refusals, not just final successes.
- **G2 — reference value:** provisional target of at least 20% median paired reduction in total time to acceptance on 20 held-out briefs, with no quality regression and a project-level uncertainty interval reported. Do not launch on a tiny positive point estimate whose uncertainty includes no benefit.
- **G3 — specialized ML:** beat the strongest rules/retrieval baseline on held-out projects and reduce artist time/corrections enough to cover added latency and maintenance. Define the task-specific minimum before training.
- **G4 — beta:** satisfy host/privacy/recovery/support gates and confirm repeat use with target artists. A successful internal demo is insufficient.

These thresholds are deliberately proposed and revisable before a campaign. Do not tune them after seeing results to manufacture a pass.

## Ten experiment briefs

### E-01 — MCP basic scatter creation

- **Question:** can a typed client create a valid owned scatter reliably?
- **Hypothesis:** a high-level validated plan produces the same result as the corresponding manual/native settings.
- **Input:** three owned simple fixtures, approved sources, fixed seeds; repeated create/undo cycles and injected failures.
- **Output:** new controller, three layers where requested, canonical transforms and operation ledger.
- **Baseline:** equivalent direct/manual Cyrus configuration.
- **Success metric:** parity on the declared build/path; G0; 100 create/undo attempts across the fixtures without leftover owned nodes or changed sentinels.
- **Stop condition:** any forbidden mutation, unmatched undo, duplicate application or uncertain outcome replay.
- **Evidence:** input/build hashes, plans, operations, state comparisons, failure/recovery logs and host versions.

### E-02 — Scene-context inspection

- **Question:** can context be useful while genuinely read-only and bounded?
- **Hypothesis:** purpose-built snapshots avoid side effects from current convenience queries.
- **Input:** small/large scenes, duplicate names, deleted references, multiple owners, hidden objects and dirty previews.
- **Output:** bounded context with explicit eligibility/freshness and scoped IDs.
- **Baseline:** manual inspection and a direct fixture truth manifest.
- **Success metric:** exact units/IDs/approved sets; zero changes to parameters, selection, undo history, revisions or preview counters; context within declared limits.
- **Stop condition:** implicit refresh/mutation, leaked object/path data or silent truncation.
- **Evidence:** before/after state, payload sizes, timing traces, eligibility decisions and negative cases.

### E-03 — GPT-generated design plan

- **Question:** can the requested general model propose valid useful settings from structured context?
- **Hypothesis:** clear capabilities and examples yield bounded plans without custom ML.
- **Input:** 20 distinct owned text briefs, contexts and source cards; fixed prompt/model configuration.
- **Output:** typed plans, assumptions and validation findings.
- **Baseline:** hand-authored recipes and manual setup.
- **Success metric:** G1, number of repairs, invalid/unsupported references and total setup/review time.
- **Stop condition:** authority expansion, persistent invented IDs or no advantage over a preset after prompt/context repair.
- **Evidence:** permitted prompts/responses, model ID/settings, normalized plans, validator results and artist timing.

### E-04 — Reference image to three-layer layout

- **Question:** does a reference improve composition beyond text and a generic recipe?
- **Hypothesis:** confirmed regions plus reference intent produce useful trees/shrubs/low-vegetation relationships.
- **Input:** 20 held-out owned reference/site/asset briefs, known cameras and confirmed zones.
- **Output:** at most three layers and an artist-reviewed editable proposal.
- **Baseline:** manual preset plus the same reference; also text-only agent where affordable.
- **Success metric:** G2, blinded composition ratings, open-space validity and weighted correction burden.
- **Stop condition:** asset/camera mismatch dominates, metric placement is guessed, or review time removes the gain.
- **Evidence:** references/rights, context/plan, complete local state, comparable views and acceptance rubric.

### E-05 — Screenshot-feedback refinement

- **Question:** does one visual revision improve the initial candidate?
- **Hypothesis:** combining a matching screenshot with numeric diagnostics produces a useful bounded adjustment.
- **Input:** E-04-style initial candidates on held-out briefs, same seed/view, remaining budget.
- **Output:** initial and one refined candidate with a concrete change explanation.
- **Baseline:** initial candidate without feedback; optionally numeric-only feedback.
- **Success metric:** blinded preference for refinement above chance with uncertainty reported, total-time benefit and no hard-constraint regression.
- **Stop condition:** stale observations, oscillation, quality regression or extra waiting exceeding saved correction time.
- **Evidence:** both plans/states/views, revision metadata, change fields, artist preference/ties and timings.

### E-06 — Retrieval from accepted layouts

- **Question:** do curated examples improve plans enough to justify the library?
- **Hypothesis:** compatible recipes reduce bad settings and revisions.
- **Input:** about 30 owned accepted recipes plus 20 separate held-out project briefs; metadata and optional frozen embeddings.
- **Output:** ranked compatible recipes and adapted plans with provenance.
- **Baseline:** no retrieval and simple tag/rule lookup.
- **Success metric:** downstream acceptance/time plus retrieval relevance; no test-project or studio-permission leakage.
- **Stop condition:** nearest examples are incompatible, gains vanish versus tags, or maintaining the library costs more than it saves.
- **Evidence:** library/version, split manifest, retrieved IDs, adaptation changes and paired outcomes.

### E-07 — Segmentation-assisted zoning

- **Question:** does a pretrained segmentation model reduce region-authoring effort?
- **Hypothesis:** editable masks save tracing time for a restricted image domain.
- **Input:** 50 rights-cleared references with reviewed masks for the relevant classes; explicit camera/site mapping where used.
- **Output:** image masks and artist-confirmed world regions only when mapping is valid.
- **Baseline:** manual zoning and general-model suggestions.
- **Success metric:** per-class IoU/boundary error and lower total tracing/correction time; unchanged hard validity.
- **Stop condition:** occlusion/class confusion, uncalibrated metric mapping, license/runtime block or no time benefit.
- **Evidence:** checkpoint/license identity, inputs/labels/splits, masks, corrections, mapping assumptions and memory/latency.

### E-08 — Point desirability model

- **Question:** can a small ranker improve selection among feasible candidates?
- **Hypothesis:** explicit artist choices add information beyond distance/region heuristics.
- **Input:** rights-cleared paired choices across diverse projects, stable IDs, frozen candidate generator and feature version.
- **Output:** candidate ranks and a constrained selected layout.
- **Baseline:** seeded random plus hard constraints, hand-scored heuristics and nearest-recipe settings.
- **Success metric:** held-out ranking quality and G3 downstream artist benefit; zero hard-constraint regressions.
- **Stop condition:** candidate API/labels are unavailable, split leakage, no gain over heuristic or training improves rank metrics without artist value.
- **Evidence:** dataset/split manifest, label ambiguity, feature/candidate versions, checkpoints, learning curves and final layouts.

### E-09 — Artist-correction learning

- **Question:** are corrections useful beyond a saved preference profile?
- **Hypothesis:** explicit contextual reasons and preference pairs reduce repeated revisions.
- **Input:** consented before/after sessions with verified correspondence, optional reasons and accepted outcomes.
- **Output:** studio-scoped parameter or preference recommendations.
- **Baseline:** last-used settings, per-studio median and retrieval.
- **Success metric:** lower correction/time on held-out projects, preference accuracy including ties and no cross-studio leakage.
- **Stop condition:** edits mostly reflect changed briefs/bugs, insufficient independent projects or no gain over saved settings.
- **Evidence:** reason/ambiguity labels, lineage/splits, baseline comparisons, opt-in state and model/profile versions.

### E-10 — Offline/local inference feasibility

- **Question:** which useful features work with network access disabled on the intended hardware?
- **Hypothesis:** rules/retrieval work locally; selected small models may add value within a measured budget.
- **Input:** 32 GB host target, recorded CPU/GPU/VRAM, fixed scenes and explicitly licensed candidate runtimes/checkpoints.
- **Output:** offline recipe workflow and optional model results with resource traces.
- **Baseline:** manual/preset offline Cyrus; cloud prototype only as a separate quality/cost comparator.
- **Success metric:** no attempted egress, no harmful host/renderer contention, acceptable end-to-end artist time and reproducible installation/rollback.
- **Stop condition:** hidden downloads, unsupported runtime, memory pressure, excessive latency or no useful quality.
- **Evidence:** environment manifest, network-denial observations, peak memory/VRAM, timing, model/license digest and accepted/rejected results.

## Evidence bundle for every campaign

Preserve declared hypotheses/thresholds before running, rights and consent, fixture/build/model identity, raw per-project outcomes, failures, uncertainty analysis and the decision. Save concise model decisions, not hidden chain-of-thought. Do not select only attractive screenshots.

The JSON examples in this package are not campaign results. Existing native/Max tests support the engine baseline only; no AI pass is inferred from them.


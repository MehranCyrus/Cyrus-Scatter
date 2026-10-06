# Experiment register

All experiments below are **planned**, except the existing offline MCP suite rerun recorded in the evidence folder. No model benchmark or Max experiment in this register was executed during this research.

## Common campaign receipt

Record experiment ID, hypothesis, predeclared acceptance rule, source/script/DLL hashes, Max/renderer/model versions, hardware and memory, disposable scene hash, assets and rights, seeds, camera/render profiles, warm/cold state, raw counters, output digests, failures, and interpretation. Keep observed facts separate from the explanation of why they occurred.

Use paired or randomized trials where appropriate. Warmup, caching and candidate order can confound results. Compare methods under equal generation/render/review budgets. Keep enough raw evidence to challenge a conclusion.

## E01 — IR causality and stability

**Question:** which event initiates repeated Corona IR restarts?

**Method:** record idle, navigation and one relevant edit with correlated invalidation/publication/render events. Run narrowly controlled diagnostic variations on a private matching build. Preserve each variant's source identity.

**Measure:** render-start count, publication epochs/digests, geometry/display notifications, bridge builds, cache hits, upload counters and timestamps.

**Pass:** an identified causal path explains the reproduction; a later fix removes idle loops while preserving intentional updates and exact output. A timer correlation alone is not sufficient.

## E02 — Cache and host-thread preservation

**Question:** does new automation/diagnostics disturb retained display or evaluation?

**Method:** same disposable scenes with instrumentation/companion disconnected, idle, and actively reading cached diagnostics. Test Mesh and Point Cloud, relevant source edits, scrolling, layer-editor navigation and camera movement.

**Measure:** placement builds, prepared-cache hits, publication/upload counts, host callback timing, process memory, and separately measured presentation behaviour if available.

**Pass:** no unnecessary placement rebuild/upload from observation or browsing; measured overhead within a predeclared margin; no worker-thread host API calls. Preserve the original timing semantics.

## E03 — Deterministic recipe replay

**Question:** can one candidate be reconstructed and meaningfully compared later?

**Method:** evaluate, save, close/reload a disposable scene, resolve the same asset versions and replay. Include ordered layers/sets, Brush masks, containers, parked sources, radius overrides and protected edits.

**Measure:** normalized settings, IDs/lineage, accepted transforms/counts/reasons, publication digest and rendered view identity.

**Pass:** exact fields/digests agree where the same deterministic environment promises agreement. Floating-point/renderer tolerances are declared for other outputs; unexplained differences fail. A photograph need not be byte-identical across GPUs.

## E04 — Publication/artifact failure injection

**Question:** can a failure attach an image or record to the wrong layout?

**Method:** inject failure before evaluation, during staging, after host commit before response, during image write and before database commit. Simulate disk full and missing/corrupt artifact.

**Pass:** preceding valid scene state remains recoverable; no partial candidate is labelled complete; exact retries/reconciliation do not duplicate mutation; mismatched hashes block review eligibility.

## E05 — Procedural API parity and capability truth

**Question:** do UI, engine and API mean the same thing?

**Method:** create equivalent supported configurations through UI and typed plans. Test inherited defaults, layer/set order, all three collision scopes, source/instance radii, background modes, accepted-target shortfall, cleanup, Manual/Live and Undo. Include unsupported cases.

**Pass:** normalized effective settings and final publications agree; unsupported operations fail explicitly; old plan schemas remain unchanged. A capture-only test cannot satisfy this experiment.

## E06 — Batch admission and recovery

**Question:** can a batch exceed authority or costs after retries and crashes?

**Method:** use deliberately tiny limits. Test changed source membership, expired authorization, host busy, cancellation before/during work, disconnect after apply, restart, repeated failures and two clients targeting one host.

**Pass:** no unauthorized mutation, one mutating job per host, persistent attempted-work accounting, no silent replay after uncertain outcomes, and accurate cancel-requested/cancelled states.

## E07 — Recipe diversity and expressiveness

**Question:** do generated alternatives differ in ways artists value?

**Method:** compare seed-only variation, stratified parameter variation, local mutation and curated recipe families on multiple sites. Use only implemented controls. Ask artists to group distinct directions and identify missing controls.

**Measure:** valid-candidate fraction, recipe and visual duplicates, distinct useful groups, acceptance and generation cost.

**Pass:** useful diversity exceeds the seed-only baseline without excessive failures. Missing expressiveness becomes a focused procedural-feature proposal rather than a larger-model purchase.

## E08 — Review usability and labels

**Question:** can artists provide reliable feedback at reasonable effort?

**Method:** pilot grid then pairwise review with A/B/tie/neither/skip. Randomize sides, add a small repeated set, test closing/reopening the gallery and retraction.

**Measure:** seconds per comparison, skips, fatigue, repeated-pair agreement, use of neither, lost/duplicate records and qualitative feedback.

**Pass:** durable understandable feedback and acceptable artist effort. Agreement is reported per criterion/context, not used to erase legitimate stylistic differences.

## E09 — Ranking baseline and generalization

**Question:** do learned preferences improve new-project results?

**Method:** compare curated retrieval, linear pairwise model, small nonlinear model, and optionally frozen image features. Group all related scenes/seeds/views/lineage in one split. Evaluate known and new profiles separately.

**Measure:** pairwise loss/calibration, acceptance, blinded win/tie/loss, correction time, per-project confidence intervals and failure examples.

**Pass:** the predeclared practical benefit survives grouped holdout and blind artist review. A random image split or training-set gain is insufficient.

## E10 — Reward exploitation and drift

**Question:** does increasing search exploit the scorer?

**Method:** freeze ranker and increase candidate-search budget. Blind-review top candidates and randomly sampled controls. Test changed assets, renderer settings and new style briefs.

**Measure:** model score versus human preference, feasibility, diversity and calibration.

**Pass:** promotion only while human benefit remains. If score rises and human outcomes decline, cap search/retrain/revise features; retain the failure set for evaluation.

## E11 — Reference interpretation

**Question:** which vision components reduce artist effort?

**Method:** brief-only baseline versus model observations, editable segmentation and optional depth cues. Include ambiguous references and unavailable assets. Keep camera and planting task fixed.

**Measure:** role/region/relationship correctness, unsupported claims, correction time, executable-recipe rate and final blind preference.

**Pass:** better usable design outcomes under matched effort; uncertainty is exposed. Attractive masks or verbose explanations alone do not pass.

## E12 — Active selection, BO and quality diversity

**Question:** which search policy gives more improvement per artist minute/render?

**Method:** compare random comparisons, transparent uncertainty/diversity mixture, preference BO on a small continuous subspace, and a small diversity archive. Use identical initial data and budget; keep a random human audit stream.

**Measure:** learning curve, time to acceptable design, diversity, calibration, regret against reviewed alternatives where defined, and inference overhead.

**Pass:** consistent practical advantage on held-out sites. Do not claim unbiased off-policy estimates if selection probabilities/support are unavailable.

## E13 — Graph and orchestration ablations

**Question:** which graph structure actually helps?

**Method:** separately compare plain typed metadata versus scene relationships; simple retrieval versus GraphRAG; explicit state machine versus a framework for the same workflow. A GNN is a later model ablation with identical data and budget.

**Measure:** executable plans, spatial correctness, task completion, recovery, retrieved-evidence relevance, latency/cost and maintenance complexity.

**Pass:** each added abstraction improves its own task enough to justify cost. A framework demo or diagram is not an architecture benchmark.

## E14 — Cost and studio scale

**Question:** what batch size/concurrency is sustainable?

**Method:** ramp from small serial batches to realistic candidate counts; measure all phases and storage. Add a second isolated host only after the first is stable and its renderer/asset permissions are understood.

**Measure:** p50/p95 phase times, peak RSS/VRAM where measurable, disk growth, failed attempts, UI responsiveness, review minutes and recovery time.

**Pass:** stated quotas bound worst observed work and preserve artist responsiveness. Evidence establishes a supported operating envelope, not unlimited performance.

## E15 — Identity, transform and surface contracts

**Question:** exactly which identities and geometric meanings survive each supported edit?

**Method:** construct a small disposable fixture with two layers, multiple sets, two asset registrations, a container, a flat receiver and a curved static receiver. Exercise rename, rejection compaction, park/reenter, delete/recreate, order changes, clone/merge and save/reload. Independently test source pivots/parents, nonuniform or reflected scale, Edit overrides, units changes and receiver geometry/topology changes. Unsupported cases must fail explicitly. Retain input/output records, not only screenshots.

**Measure:** persistent IDs versus slots, verified candidate correspondence, effective transforms/radii, anchor validity, underfill/rejection reasons, publication changes and parked-setting persistence.

**Pass:** each operation matches its declared identity-survival contract; no correspondence comes from array position or reused names. Invalid bindings and transforms preserve the preceding valid state and give an actionable reason. A changed topology is never silently treated as an equivalent surface. These tests qualify the declared supported subset; they do not require adding deformation support.

## E16 — Artifact integrity and complete-view joins

**Question:** can a workflow report completion while presenting stale, missing or incorrect design evidence?

**Method:** use synthetic manifests first, then qualified host captures. Delete, replace and truncate a cached image; swap candidate IDs; deliver an old-attempt image late; omit one required camera; simulate process exit zero with no output; interrupt artifact/manifest writes and restart. Retry under the same persistent budget accounting. Include valid empty or underfilled layouts so they are not confused with missing output.

**Measure:** artifact decode/digest checks, candidate/publication/view joins, durable state transitions, admitted attempts, diagnosis and recovery work.

**Pass:** no incomplete or mismatched candidate becomes reviewable/training-eligible. A complete technical failure stays distinct from an artist rejection. Valid complete artifacts resume without needless rerendering, and failures do not reset quotas. A scheduler success flag or matching filename cannot bypass verification.

## E17 — Callback lifecycle and worker-mode qualification

**Question:** does each advertised host mode obey lifecycle and render-phase contracts without hidden timer assumptions?

**Method:** on an isolated matching Max build, trace production and IR, idle versus relevant edits, cancellation/error, Undo/Redo, save/open/reset and repeated script/editor reload. Count owned registrations/timers. Compare passive diagnostics off/on. Test a noninteractive worker separately, with explicit job evaluation and missing dependency/error cases; do not claim Batch support from the interactive result.

**Measure:** callback phase/order, initiating operation, scene mutation/publication identity, bridge lifetime, handler counts, pending work, process exit and semantic artifact outcome. Distinguish a stale registered function from the current function definition.

**Pass:** no rendered-mesh mutation in a prohibited phase, unexplained callback accumulation or observer-induced idle rebuild loop. Required edits still update; cancellation and reset leave a valid declared state. Capability output lists only qualified modes/versions/renderers. For 2026, diagnostic event names work without assuming the 2027-only accessor.

## E18 — Feature and inference parity

**Question:** do the same eligible records mean the same thing in training, inference and any exported model?

**Method:** freeze golden records with known units, transforms, missing masks, image orientation/colour, camera order, empty layouts and out-of-domain values. Compare training and inference preprocessing. If model export or CPU/GPU providers are used, compare outputs to the reference under declared numerical/ranking tolerances. Introduce vocabulary, schema and extractor-version mismatches deliberately.

**Measure:** feature arrays and digests, finite-value checks, prediction/ranking differences, fallback behaviour, latency and peak memory. Test at least one artist preference model; technical surrogates require their own target/error metrics if introduced.

**Pass:** supported paths preserve feature semantics and acceptable prediction/ranking parity; incompatible inputs are rejected or use a documented fallback. Failed deployment parity blocks promotion even if the offline model scored well. Passing this test proves interface consistency, not artistic quality.

## Interpreting the outcomes

A failed hypothesis is useful. It may show that better recipe controls or asset curation matter more than a new model, that human feedback is too noisy for the current rubric, or that full renders are too expensive for the chosen acquisition policy. Revise the roadmap from those observations; keep the benchmark fixed long enough to distinguish progress from changing the test.

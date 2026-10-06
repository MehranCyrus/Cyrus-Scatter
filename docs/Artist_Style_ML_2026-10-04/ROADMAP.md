# Roadmap and implementation checklist

<!-- CURRENT_SYSTEM_2026-10-05 -->

This specialist proposal is coordinated by the [current system roadmap](../Current_System_2026-10-05/ROADMAP.md). Diagnostics and qualified procedural MCP/publication contracts precede broad automated design studies. Its unchecked ML items remain unimplemented.

4 October 2026 · **Planning deliverable.** All implementation items below are pending. Completed work in this task is research, source inspection, contract examples and documentation verification. No ML feature has been built or qualified.

The roadmap is ordered by dependencies and evidence, not estimated calendar dates. Profile-based assistance can ship before personalized training; each later stage must earn its complexity through a measured result.

## Phase 0 — Fix the target and baseline

**Purpose:** distinguish a useful artist workflow from an impressive but uneditable generated image.

- [ ] Freeze the pilot contract: static horizontal site, current enrolled mesh sources, current MCP limits, owned layers and manual approval.
- [ ] Name the first product artifact Artist Style Profile; allow several profiles per artist and one pinned revision per project.
- [ ] Choose pilot briefs covering formal, lush and mixed planting; include obstacles, narrow regions, different source sizes and deliberate underfill.
- [ ] Record which requested patterns are expressible by current MCP; label formal row placement and learned fields unsupported until qualified.
- [ ] Record a manual-preset baseline, current engine/build identity, actual output and artist time.
- [ ] Define unit, population, collision-footprint and ownership terminology in the UI and records.

**Exit gate:** each desired result has a measurable acceptance description and an honest supported/unsupported classification. If a style cannot be represented procedurally, model training is not the next step for that style.

## Phase 1 — Style Profile and Recipe Pilot

**Purpose:** let an artist reuse their preferences and examples with current capabilities.

Proposed implementation home: a new `CyrusDesign/` companion package, separate from the Max runtime. This directory is a proposal, not created by this report. Reuse the existing MCP contracts through a small shared/integration boundary rather than maintaining copied versions of setting ranges.

| Order | Task | Completion evidence |
| --- | --- | --- |
| 1 | Versioned profile and recipe schemas; local library; immutable revisions | Invalid imports rejected; profile save/load/export round trip; no machine-specific paths |
| 2 | Reference annotations, asset-role mapping and explicit project overrides | Same profile can bind to different current assets without stale node IDs |
| 3 | Small curated recipe library and metadata retrieval | Relevant examples explain their applicability and required controls |
| 4 | Pure recipe-to-plan-2.0 compiler plus capability report | Valid supported plans; unavailable fields fail explicitly; deterministic binding/seed handling |
| 5 | Minimal companion UI for profile, scene setup and draft review | Artist can understand counts, assets, scope and changes before applying |
| 6 | Existing context/validate/approve/apply/status/export lifecycle | One successful owned draft and at most one approved refinement; fresh IDs; Undo and recovery |
| 7 | Opt-in outcome and same-context preference capture | Links actual result to profile/recipe and records accept/reject/tie/neither honestly |

Use a manual recipe first to verify the whole path. Then add a general-model proposer behind the same typed interface and compare it with retrieval. Neither step requires custom training or image generation.

**Exit gate:** an artist can save two styles, apply a supported draft, inspect actual counts and edit the ordinary Cyrus result. Closing the companion must leave that scene usable. Unsupported patterns, missing role assets and stale context are visible failures rather than silent substitutions.

## Phase 2 — Durable examples and a measured learning loop

**Purpose:** collect the data needed to choose a model intelligently.

- [ ] Build a versioned record store around `cyrus.execution/1.0`, with profile/recipe/observation links and explicit permitted-use metadata.
- [ ] Add correction reasons and comparison groups. Preserve generation lineage; do not infer per-instance identity across replacement layouts.
- [ ] Add explicit authored-patch capture for artist-owned layouts only after qualifying read scope, identities and units.
- [ ] Store source dimensions, semantic roles, patch boundaries and contextual relationships needed for transfer.
- [ ] Build descriptor extraction and a simple procedural-parameter fitting baseline.
- [ ] Implement project-group splits and immutable dataset manifests; exclude test examples from retrieval.
- [ ] Build an isolated batch fixture runner if needed. It must not evade the production MCP's enrollment/application limits.
- [ ] Compare retrieval, general planning and exemplar fitting with artist outcomes; archive failures as well as attractive results.

**Exit gate:** a dataset record can reproduce its measured layout, and an evaluator can run comparisons without hand-curating away failures. There is enough independent project diversity to test the intended claim. Dataset size is decided from coverage and learning curves, not from the number of screenshots.

## Phase 3 — Fill demonstrated procedural and context gaps

**Purpose:** give a planner the controls necessary to express the styles artists actually want.

This phase may begin after Phase 1 exposes a specific gap; complete only the needed slices.

| Slice | Engineering work | Required qualification |
| --- | --- | --- |
| Semantic context | Confirmed zone roles, protected features, asset cards and source revisions | Wrong/unknown roles, changed dimensions, missing assets and unit changes |
| Parent and paint-set authoring | Typed operations for existing logical ownership and shared placement policy | Independent Brush histories, shared counts/spacing, hide versus disable, Undo and reopen |
| Density-field exchange | Bounded enrolled field resources with coordinate/domain contract | Black/white/gradient cases, row orientation, boundaries, transforms, invalid values, size caps and stale fields |
| Pattern vocabulary | Reuse boundary-row/Analyzer/density paths; add missing spatial-clump or regular-pattern primitive only if required | Actual spatial statistics, deterministic seeds, protected boundaries, source footprints and large-count costs |
| Artist overrides | Qualified ownership of manually edited or painted contributions | No unwanted replacement of Brush history or pinned edits during regeneration |
| Broader sites/assets | Separate terrain/proxy/production-scene scope extension | Curves, seams, transforms, disconnected surfaces and actual supported proxy types |

Learned coverage must not be implemented by generating fake Brush histories or manipulating arbitrary Max properties. Use the same native placement rules and expose a deliberate versioned contract. Future camera-aware composition must declare camera inputs and regenerate only on explicit request.

**Exit gate:** the engine and MCP can express each newly promised pattern with no learned model involved. Then a model may choose its parameters. Keep the current narrow scope available while broader capabilities are qualified.

## Phase 4 — Personal preference model

**Purpose:** reduce the time artists spend selecting and correcting plausible results.

- [ ] Fit a regularized linear pairwise baseline from same-context choices.
- [ ] Evaluate cold start, new projects, replacement assets and separate profiles for one artist.
- [ ] Compare a small boosted ranker only if the linear baseline leaves a measurable gap.
- [ ] Test one frozen visual encoder only if geometric/metadata features miss reference intent.
- [ ] Separate constraints from scores: invalid candidates cannot win because they look attractive.
- [ ] Implement request-bound profile revisions, cancellation, local CPU fallback and idle memory release.
- [ ] Compare against the strongest untrained recipe/retrieval baseline with all artist time included.

**Exit gate:** held-out artist outcomes improve with acceptable resource use. If simple fitting/retrieval is sufficient, ship that and stop this branch of complexity.

## Phase 5 — Optional personal LoRA or learned field model

**Purpose:** solve a documented residual problem, such as repeated failure to translate personal references into correct procedural organization.

- [ ] State the exact input/output task and select a trainable, compatible base after a small inference experiment.
- [ ] Prepare context-to-recipe or registered-field supervision; do not treat image captions as 3D layout ground truth.
- [ ] Freeze base, tokenizer/processor, feature normalization, target schema, dataset and split identities.
- [ ] Compare the same base with and without adaptation, both with equal access to examples and constraints.
- [ ] Test compatibility, malformed output, missing roles, contradictory briefs, scarce data and unfamiliar sites.
- [ ] Record training/inference latency, memory and failure cost on actual target hardware.
- [ ] Publish a versioned model package with evaluation evidence and rollback; no automatic activation after training.
- [ ] Expose “adapt this profile” only when the dataset is suitable, and keep reference-only profiles usable.

**Exit gate:** the adapter or field model beats the best simpler approach on unseen projects and passes runtime/contract checks. If it does not, retain the simpler model and record the failed experiment. Full generative point-layout models remain a separate research track requiring candidate-exchange and editing semantics.

## Phase 6 — Product qualification and studio use

- [ ] Qualify supported Max versions individually. Current MCP runtime evidence is Max 2027; SDK builds alone do not qualify Max 2026 automation.
- [ ] Pin profile, recipe, compiler, model and generator versions in saved projects/records.
- [ ] Test offline operation, missing/corrupt model package, base mismatch, interrupted import, cancellation, out-of-memory and process restart.
- [ ] Test simultaneous artists/jobs for correct profile binding and data isolation; serialize model switching initially.
- [ ] Verify import/export without executable code, machine secrets or unapproved model/asset payloads.
- [ ] Test library backup, migration, record removal, dataset revision and affected-model retirement/retraining policy.
- [ ] Measure navigation with the companion off, idle and active; keep ordinary redraw free of model calls.
- [ ] Repeat representative Point Cloud/Proxy/Mesh lifecycle checks when integration changes could affect caches, and include generation/manual-edit/save/reopen behavior.
- [ ] Provide an artist guide, model/data limitations, support matrix and measured release report.

**Exit gate:** a reproducible supported workflow, useful measured artist outcomes, preserved manual editing and viewport behavior, and documented recovery. A successful demo or a valid JSON recipe is insufficient on its own.

## First coding loop: concrete scope

Build Phase 1's schemas/library/compiler before a model trainer. Use the [synthetic examples](examples/README.md) as design illustrations, then create executable schemas and real tests during implementation.

The first loop should produce:

1. A local profile with editable preferences and reference annotations.
2. An approved recipe reusable with a second asset palette.
3. A compiler that emits only current plan 2.0, with a visible capability/underfill report.
4. A complete owned-generation review/apply/export workflow in an isolated Max fixture.
5. A saved comparison record and an artist evaluation against manual presets.

Required tests cover real boundary risks: unsupported recipe features, expired context, wrong source binding, count/weight/unit errors, modified scene before apply, underfill, rejection/cancellation, actual-result digest, and Undo. Do not call this complete until the artist can use and understand it.

## Research-loop rule

For each experiment, write one question, baseline, change, fixture set and acceptance rule **before** running it. Preserve actual results and failure cases, then choose one of: keep, simplify, investigate or stop. Update this roadmap after measured evidence; do not append increasingly complex models merely because they are available.

The next implementation starts at Phase 0/1 with these concrete boundaries. Training, external data transfer and expanded scene automation are later work items with their own defined scope and qualification.

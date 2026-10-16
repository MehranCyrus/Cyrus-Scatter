# Eleven-phase Cyrus Scatter implementation roadmap

**Active execution update, 16 October 2026:** the [user's improvement goal](../improvement-program/OBJECTIVE.md)
resumes P06 and authorizes the remaining P06–P11 and I03–I18 work. Presets are
first, implemented and scoped-tested as [0.82.6.1](../improvement-program/I03_08261.md). Follow the [current execution ledger](../improvement-program/PROGRESS.md).
Older pause statements and provisional version assignments below describe prior
checkpoints; the active version-policy override governs new deliveries.

Created 14 October 2026. This is the execution plan requested in the Forest / Chaos
comparison conversation. It covers feature-table items **1 through 11**, treated
as eleven sequential deliveries. It replaces the tentative ordering in that
conversation; it does not replace the engineering foundation or current backlog.

**15 October planning supplement:** [Forest-informed improvements, easiest to hardest](FOREST_IMPROVEMENTS.md)
maps the recorded reverse-engineering findings to current Cyrus 0.82.5, with
performance gates, tests and dependencies for 18 proposed improvements. It does
not reorder this execution program or authorize later implementation. The subsequent user-authorized [I01/I02 delivery](../panel-performance-0826/PROGRESS.md) is 0.82.6. **Phase 6 remains
paused.** Additional effects, UV, asset and renderer work is identified separately
from the original eleven phases.

## Scope and authorization

The user authorized implementation, proportionate testing, documentation, version
selection, and a commit/push after each successfully validated phase. Continue to
the next phase after its predecessor meets its acceptance criteria and its push
is verified. Fix a failed required check before declaring that phase complete.
Do not substitute a passing test count for the artist behavior being tested.

Packaging, normal-profile installation, public release and website deployment are
separate delivery actions. Existing authorization does cover private, disposable
Max test hosts. Preserve original scenes, profiles, assets and unrelated work.
On 14 October the user clarified that agent-run Max/automated testing should
continue through all eleven phases; their own artist testing happens at the end.
Attempt Computer Use when available, but its infrastructure failure is not a
per-phase stop or request for user acceptance. Record unperformed physical/visual
checks for the final artist session. Actual product/runtime failures still require
fixes before a phase checkpoint. Do not invent a passing visual result.

## Enrollment baseline

- Source: **0.81.7**, schema **58**, calculation model **CyrusUnified1**.
- Branch at enrollment: `codex/workflow-0.75`.
- HEAD at enrollment: `2b9ad12b24f9d91241db4567037f64db71fe9726`.
- The working tree contains substantial pre-existing 0.81.3–0.81.7 changes,
  qualification tools/reports, research and unrelated website/knowledge work.
  A clean checkout of HEAD alone is not this baseline. Inspect and preserve the
  baseline diff before forming a reproducible phase commit.
- Documentation records **0.81.6 installed**, with 0.81.7 privately qualified.
  Recheck actual installed/loaded hashes before any host-specific claim.
- [Current viewport handoff](../terrace-0815/VIEWPORT_0817.md) records 28 native
  suites per Max year, 161 Python tests and 357 scoped host assertions. These are
  historical receipts for their exact input bytes, not passes for future edits.
- General curved-surface scattering exists; vector Paint Areas remain restricted
  to single-valued receiver-local XY terrain. Layers, clusters, Bands, independent
  density/scale curves, Point/Empty source roles, protected Edit, independent
  spacing scopes, retained display and PFlow output already exist.
- **Phase 11 is partially implemented already:** 0.81.6 adds navigating/idle
  budgets and Mesh fallback; 0.81.7 adds resource-bounded Point preparation and
  current-publication representation-cache reuse. Audit and extend this behavior.
- Knowledge generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`
  rejected current-source retrieval as stale on 14 October. Direct current-source
  inspection is authoritative for this plan; no index refresh was performed.

## Documents and status

- [0.82.6 panel performance and diagnostics](../panel-performance-0826/PROGRESS.md): I01/I02 implementation, scoped Max 2027 checks and installer. P06 remains paused; next provisional label 0.82.7.

- [0.82.5 complete static recipes](../recipes-0825/PROGRESS.md): current P10 core, including native Paint, roles, transactional import and bounded browsing. P06 remains paused; the later panel delivery moves its provisional label to 0.82.7. P10 search/thumbnails, asset packaging and future-layout fields remain separate work.
- [0.82.4 mesh channel density and Paint help](MESH_MASK_0824.md): preceding source, Max 2027 evidence and runnable installer.
- [0.82.3 performance correction](PERFORMANCE_0823.md): preceding idle, interaction
  and panel latency evidence, preserved with its original hashes.

- [0.82.2 Max 2027 installer and installation](INSTALLATION_0822.md) and
  [artist acceptance checklist](ARTIST_ACCEPTANCE_0822.md): the first five phases
  are delivered on disk; restart and user testing are pending. P06 stays paused.
- [P01 implementation and evidence](P01.md): **0.81.8** phase checkpoint;
  runtime checks pass. The user deferred their visual acceptance until the end
  of the program; P01 was pushed as `50ea0a6037ea641298e8d9007931ee3bec2a5ed9`.
- [Implementation specifications](IMPLEMENTATION.md): outcome, ownership, staged
  delivery, cache dependencies, edge cases and acceptance for each phase.
- [Validation and performance](VALIDATION.md): common checks, fixtures, metrics,
  evidence levels and phase completion requirements.
- [TODO and progress](TODO.md): the operational checklist, current action, results,
  version decisions and Git checkpoints. Update this after every meaningful step.
- [Current backlog](../../BACKLOG.md): existing defect/acceptance IDs remain the
  authority for those issues; this plan links them rather than closing them by
  implication.

| Phase | Version | Outcome | Effort | Entry dependencies | Current state |
| --- | --- | --- | --- | --- | --- |
| P01 | 0.81.8 | Clear workflow, ownership, cached/pending state and useful feedback | Small–medium | Freeze current baseline and inspect actual generated UI | Implemented, qualified and pushed |
| P02 | 0.81.9 | Named settings and curve presets | Medium | P01; typed settings capture/apply | Implemented, qualified and pushed under original label |
| P03 | 0.82.0 | Slope/altitude filters with soft transitions | Medium | P02; existing eligibility and units contracts | Implemented, qualified and pushed under original label |
| P04 | 0.82.1 | Selectable UV channel and density-map resolution | Medium | P03; map dependency/coordinate contract | Implemented, qualified and pushed under original label |
| P05 | 0.82.2 | Paint-to-spline export and spline-to-Paint import | Medium | P04; current vector regions and units | Implemented, qualified and pushed under original label; corrected 0.82.2 label compiled for Max 2027 |
| P06 | 0.85.0 (I06) | Rectangular, staggered and hexagonal placement | Medium | P05; stable layout identities | Scoped Max 2027 qualification and package passed; see I06 handoff |
| P07 | 0.83.0 | Target/direction orientation controls | Medium | Final-transform and radius contracts; active-goal sequencing | Delivered in I04; scoped qualification |
| P08 | 0.82.9 | True path spacing, sequences and reference placement | Medium–large | P07; shared candidate/transform services | Planned |
| P09 | 0.83.0 | Transform maps and color-based source assignment | Medium–large | P04, P07, P08 | Planned |
| P10 | 0.82.5 core; follow-up TBD | Complete planting recipes, substitution and browser | Medium–large | P02 plus settled P03–P09 authored settings | Static core delivered separately; later layouts/maps and browser follow-ups remain |
| P11 | 0.83.1 | Adaptive viewport completion and production performance | Medium–large | P01–P10; existing 0.81.6/0.81.7 viewport policy | Partial baseline; new acceptance pending |

Execution is sequential. Performance and correctness work are continuous inside
each phase. A necessary foundational fix can be a tracked subtask of the phase
that exposes it; do not silently reorder or broaden the eleven product outcomes.

## Per-phase delivery loop

1. Recheck current branch, HEAD, relevant dirty/untracked changes and latest
   handoff. Review existing evidence once, then read the relevant original source.
2. Freeze the phase's behavior and acceptance table. Resolve important semantics
   before coding; record design decisions and remaining uncertainty.
3. Implement in authoritative native/template/generator sources. Update generated
   outputs, inventory and closed catalog contracts together where affected.
4. Validate the intended action, important unaffected cases, failure retention,
   persistence and relevant performance. Iterate on actual failures.
5. Review the complete candidate diff and evidence. Update current artist docs,
   backlog and website source imports for proven artist-visible changes.
6. Select the version using the [version policy](../../Release_Versioning.md),
   freeze source identities, and run the necessary final checks for those bytes.
7. Commit the coherent phase plus its necessary reviewed prerequisites; exclude
   unrelated assets/work. Push to the existing intended branch without force and
   verify the remote commit. Record hashes and outstanding acceptance limits.
8. Mark the phase complete only if required acceptance and push verification are
   complete. Start the next phase using that checkpoint.

An earlier phase's runtime receipt is reusable only for unchanged relevant inputs
and dependencies. Changed shared pipeline code requires the corresponding prior
phase regressions. A source-only Git checkpoint must contain the tracked/untracked
source dependencies needed to regenerate and build; ignored SDKs/assets/binaries
need separately recorded local provenance.

## Version approach

The user confirmed the small-step sequence on 14 October 2026: Phase 1 starts at
**0.81.8**, Phase 5 is **0.82.2**, and the remaining planned labels appear above.
Advance PATCH through 9, then carry into MINOR. Feature phases use the same step.
The [canonical mapping](../../Release_Versioning.md#eleven-phase-numbering)
retains original qualification labels for P02–P05; historical hashes/receipts and
Git commits remain unchanged. These are planned source checkpoints, not claims
that future phases are complete. Schema and native capabilities remain separate.
Development/testing use Max 2027 only. Phase implementation remains paused.

## Research discipline

Use vendor documentation, SDK/API references, vendor-owned public repositories,
readable installed scripts and controlled behavior experiments when available.
Record product version, source URL/path, observation, inference and chosen Cyrus
behavior separately. Public APIs and visible behavior do not reveal all private
engine decisions. A generic GitHub search on 14 October returned third-party
installer/activation repositories, not verified engine source; none was adopted.
Do not treat a repository name as evidence of vendor provenance.

Existing research and the four AI plans under `docs/How_Forest_Works/` are design
inputs. Their stroke-authoritative painting proposals, old ownership models,
fixed-radius incremental assumptions and speculative renderer paths must be
reconciled with current source before use. Preserve current vector authority,
ordered acceptance and existing PFlow output.

Primary references to revisit for decision-critical details:

- [Forest library browser](https://docs.itoosoft.com/forestpack/forest-library/library-browser)
  and [library authoring](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library): P02/P10.
- [Forest surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces)
  and [image distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode): P03/P04/P09.
- [Forest areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas): P05.
- [Forest path mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode)
  and [reference mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode): P08.
- [Chaos advanced features](https://support.chaos.com/hc/en-us/articles/4953359913617-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Advanced-Features): P03/P06/P07/P09.
- [Chaos performance guidance](https://support.chaos.com/hc/en-us/articles/4953457092625-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Performance-and-Troubleshooting): P11.
- [Forest export/MAXScript tools](https://docs.itoosoft.com/forestpack/instantiating-and-exporting/forest-tools): documented interoperability and bounded observations.

Features 12–18 of the comparison remain outside this program: broader linked
planting, a new advanced Edit system, renderer/material expansion, edge trimming,
animation/geometry LOD, general curved-surface painting and an Effects framework.
Do not make them hidden prerequisites for finishing phases 1–11.

Current successor: [I06/P06 0.85.0 grids](../improvement-program/I06_0850.md), following [I05 variation](../improvement-program/I05_0840.md) and [I04/P07 direction](../improvement-program/I04_0830.md). Six examples are scoped-qualified. I07/P08 paths is next; B26 and the remaining program/EXE stay open. Historical version proposals do not select future delivery numbers.

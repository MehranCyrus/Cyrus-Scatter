# MCP library checkpoint — implementation paused

24 October 2026. Paused at the user's request at M03, before public preset application and complete recipe application. The full M00–M13 objective remains open.

## What this checkpoint means

**The current models, library entries and recipes are test content. They establish whether the integration works; they are not the final production library.** Their counts and successful test cases do not establish production content quality, completeness, suitability or licensing readiness. Final content selection and qualification need a separate decision from API implementation. No new production library is being created at this checkpoint.

There is a useful, tested MCP foundation: an external client has exercised scoped scene inspection, asset preparation and approved source import, bounded planting, limited refinement, actual-result inspection and recovery cases in owned Max 2027 scenes. This is substantially beyond a design document, but it is not a complete integration or a newly delivered installer.

The development source currently registers **23 tools and seven resources**. The roadmap has **14 milestones: seven in progress and seven planned; none fully closed against its complete acceptance criteria**. Tool count, test count and inventory size are different measures from roadmap completion. A percentage would imply more certainty than the evidence supports.

## What an AI can do now

| Area | Implemented, with scoped evidence | Practical limit |
| --- | --- | --- |
| Connection | Read enrollment, connection state, module identities and supported contract | Development source and the older configured integration are distinct; verify the actual loaded pair |
| Scene context | Read explicitly permitted objects, roles, units, revisions and supported geometry facts; request bounded measurements | No general automatic understanding of an arbitrary whole scene |
| Task setup | Use locally confirmed receiver/source/exclusion/context roles; extend supported scope through the local task workflow | Names and visual appearance are clues, not proof of role or permission |
| Model discovery | Search and inspect shared installed-model metadata, stable references and preparation readiness | Discoverable does not mean importable or suitable |
| Source use | Prepare selected vetted derivatives and propose hidden, non-rendering source copies for exact local approval; import with scoped Undo/rollback | Separate sharing, preparation and write authority; no arbitrary file access or artist-scene `.max` merge |
| Recipe discovery | Search and inspect frozen recipe metadata | Complete recipe instantiation through MCP is unfinished |
| Settings presets | Discover and inspect native population, transforms, spacing, density-curve and scale-curve presets | Public approved preset application is unfinished |
| Native settings | Read bounded current category settings, exact target IDs, stored curves and controller availability | Inspection does not authorize editing every returned property |
| Planting | Validate and apply a bounded typed plan using supported sources, ordered layers, regions/exclusions, weights and the supported transform/spacing subset | Restricted geometry and work budgets; not all native Scatter capabilities |
| Refinement | Patch supported owned count/seed settings, configure without calculating, or explicitly Update; preserve identities and untouched settings | Broader typed edits and adoption of arbitrary existing setups remain open |
| Feedback | Read operation status, diagnostics, current configuration, last complete publication and paged actual instance data | Authored settings, completed result and viewport display can differ, especially in Manual mode |
| Artifacts | Export the supported execution record and capture a locally shared viewport | Viewport capture is not a renderer job or a complete output/export bridge |
| Reliability | Exact proposal approval, freshness checks, queued host execution, idempotency, receipts and scoped fault/process-loss/Undo cases | Wider lifecycle, storage failures and returning-task restoration are not fully qualified |

The most useful demonstrated workflow is:

1. The artist shares a supported area and model catalog, and confirms relevant roles.
2. The AI reads geometry, scale and constraints and selects supported test assets.
3. Separate local permission allows preparation; an exact proposal then describes source-copy effects.
4. After approval, source copies are imported into the same task.
5. The AI proposes planting, obtains local approval and invokes the native calculation.
6. It reads actual results, reports shortfall or limitations, and can propose supported refinement.

One installed-content campaign produced **68 grass and 69 flower instances: 137 verified rows** across two layers. A separate real-source campaign refined flowers from 2 to 19 while preserving all 85 grass rows and both layer identities. These are engineering fixtures, not claims about ideal artistic density, exact coverage or final library content. See [installed-source evidence](M03_INSTALLED_SOURCES.md) and [source metadata/planting evidence](M03_SOURCE_METADATA.md).

## How scene understanding should work

The artist should provide the intended result and consequential constraints. The plugin should supply measurable facts, native state and verified outcomes. The AI should turn those into an understandable proposal.

Helpful names, layers and containers can reduce ambiguity, but artists should not have to reorganize a whole scene before using MCP. Start with selected objects and cheap scoped facts. Suggest roles, expose uncertainty and let the artist correct by picking or confirming. Ask only when an unresolved choice materially changes the result: for example, which surface is editable, whether an entrance must stay clear, or which available asset should be used.

Density and ratio need explicit meanings. Source weights describe relative source selection; they do not specify flower-patch coverage. Candidate count, emitted instances, ground coverage, displayed percentage and exact accepted targets are separate quantities. The current API must not promise an unimplemented interpretation merely because the artist uses a natural-language quantity.

The repeated workflow should be **inspect → clarify consequential ambiguity → propose visible defaults → validate → local approval → execute → inspect actual result → refine**. Confirmed choices should survive ordinary refinement; changed geometry or settings should invalidate only affected facts and approvals. Wider assistance and durable memory are remaining roadmap work, not guarantees of the current implementation. See [scene onboarding design](SCENE_ONBOARDING_WORKFLOW_20261023.md).

## Tool inventory

| Group | Current registered tools |
| --- | --- |
| Connection and context | `connection_get_status`, `scene_get_context`, `scene_measure_objects` |
| Model discovery and source preparation | `library_search`, `library_inspect_entry`, `assets_prepare_sources`, `assets_validate_use` |
| Recipe and preset discovery | `recipes_search`, `recipes_inspect_entry`, `presets_search`, `presets_inspect_entry` |
| Proposal and execution | `scatter_validate_plan`, `scatter_validate_change`, `scatter_apply_plan`, `scatter_get_status` |
| Settings and diagnostics | `scatter_get_settings`, `scatter_get_configuration`, `scatter_get_diagnostics`, `scatter_read_diagnostic_events` |
| Results and artifacts | `scatter_get_publication`, `scatter_read_publication_page`, `scatter_export_record`, `scene_capture_viewport` |

Resources: `cyrus://plan-schema`, `cyrus://plan-schema/0.73`, `cyrus://capabilities`, `cyrus://feature-catalog`, `cyrus://workflow`, `cyrus://agent-workflows`, `cyrus://error-guide`.

The generated inventory describes 36 feature families and 333 controls. It is help and coverage inventory, not proof of 333 remotely writable controls. The [75-operation baseline](OPERATION_COVERAGE.md) likewise records required operations and acceptance gates, not 75 completed capabilities.

## Current bounds and important gaps

- Read-only context is bounded to 32 selected objects; explicit measurement requests cover one to three objects.
- The creation slice supports static qualified geometry, horizontal convex receiving regions, up to three sources, up to three layers and an aggregate 2,000-candidate budget. More complex terrain and arbitrary existing setups are not qualified for this design slice.
- A scope allows two successful planting applications, eight supported configuration changes, 24 ordinary calls and two viewport captures, with documented exceptions for outcome/status/idempotent recovery. These are initial admission limits, not native engine capacity claims.
- Native high-detail source metadata avoids copying full meshes through the AI/Python context. Separate native source admission can handle more geometry than the receiver/fallback path, but that does not certify every material, proxy, controller or asset dependency.
- The test catalog has 96 discoverable entries; 13 prepared derivatives passed the recorded admission. The other entries have explicit rejection/deferred reasons. These are fixture readiness observations, not a finished library inventory.
- Direct `.max` model merge is excluded from artist-scene source use because the recorded B38 boundary can destroy previous Undo history. The supported test workflow uses prepared derivatives built in owned scenes.
- Passive reads must not solve placements, initialize default curves or upload unchanged buffers. Broader performance qualification remains open.
- Full typed preset/recipe application, comprehensive placement controls, Paint Areas/masks/Paths, persistent instance editing, general task restoration, assisted visual iteration and complete output bridges remain unfinished.
- Cold-reopen evidence exposed reconstructed-publication differences. Returning to a saved task cannot yet be advertised as preserving every previous Manual result exactly.
- The complete native task-panel workflow and the requested single-file interactive HTML simulation are not delivered. Existing partial local panel interactions are narrower evidence.

## Verification and its limits

The latest fully qualified **native prerequisite** uses producer `build/mcp-preset-transactions-20261024-02` and owned host `build/mcp-preset-application-20261024-11/host01`:

| Evidence | Result | What it establishes |
| --- | --- | --- |
| Python/tool checks | 567 passed | Recorded adapter/tool regression scope |
| Native suites | 58 passed | Recorded native test scope |
| Scripted Max 2027/SDK campaign | 16 cases passed | Five-category native application, readback, curve fidelity, composed transactions, no-op and rollback cases |
| Physical native curve editor | Drag, close, Undo, Redo and history release passed | Reproduced live-owner global-density editor path on the matched successor |
| Identity receipt | 33 frozen runtime files and five loaded native hashes match | Evidence belongs to the recorded executed pair |

The host artifact identity is `c2d0721ec5db1a5117bca6f896e770bf25797121efffcf1874bbd4b912122664`. Its generated script SHA-256 is `f49e11a3704f7267b71ccc3e9bff143f70450f57ae393d8bc990f7530f593df7`.

**Native preset application in this campaign used private probes. It is not proof that the public MCP preset proposal/approval/apply path exists.** Real external-client evidence for earlier public inspection/import/planting tools is recorded in the individual M01–M03 reports. Scripted local approval also does not substitute for complete artist interaction testing.

Earlier physical editor Undo crashes remain preserved in the evidence history. The repaired successor passes the reproduced path; other curve targets, invalidated owners and long-history resource behavior remain open. Full details and receipt locations are in [destination settings and native prerequisites](M03_DESTINATION_SETTINGS.md).

## Unfinished changes at the stop boundary

Before this pause, a small native admission prerequisite had been edited and its offline Max 2027 build launched:

- Split receiver allocation summaries from candidate-schedule materialization, so a rejected high-density proposal need not allocate a large schedule first. Files: `AminScatter/include/receiver_plan.h`, `AminScatter/src/receiver_plan.cpp`, `AminScatter/src/receiver_bridge.inc`, with focused native cases in `AminScatter/tests/receiver_tests.cpp`.
- Remove the invalidated-model permission guard from curve Undo lifetime retention in the maintained `unified-core.ms` template and regenerate `AminScatter/scripts/AminScatterObject.ms`. Lifetime retention must remain valid independently of permission to edit the former model owner.
- Record public preset integration decisions in `M03_DESTINATION_SETTINGS.md`. No public preset application implementation was added.

The build that was already running before the stop request finished during checkpoint preparation: `build/mcp-native-admission-20261024-01` compiled successfully and passed all **58 native suites in 25.94 seconds**. This is offline SDK/native-executable evidence only. No successor Max-host qualification or fresh full Python/tool run has occurred. The generated script is hashed by the producer, not compiled or exercised by Max; its bytes have changed from the qualified pair above. In particular, the newer curve-lifetime guard change still requires its own host evidence. No further implementation or test campaign was started after the stop request.

The shared worktree contains substantial MCP changes and unrelated work. Branch: `codex/workflow-0.75`; observed HEAD: `588abff0ce211d7dc63798b8c5310631895465c7`. No checkpoint commit, push, release, installer delivery, artist-profile installation or artist-session restart was performed. Owned test hosts were closed; the artist Max session was left untouched. Preserve all unrelated changes on resumption.

## Remaining phases

Statuses below describe implementation progress before the user-requested program pause. Each milestone retains its full acceptance criteria in the [master goal](IMPLEMENTATION_GOAL.md).

| Phase | Progress at pause | Remaining work |
| --- | --- | --- |
| M00 — Baseline and capability contract | In progress | Finish operation/combination coverage, reconcile source/package/loaded client identities and prove the intended delivered client contract |
| M01 — Reliable operations | In progress | Broaden failure, cancellation, storage, interaction and lifecycle acceptance; retain exact effects and duplicate-prevention guarantees |
| M02 — Scene context and roles | In progress | Broader supported scene readiness, clearer correction UX and retained intent without stale permissions or repeated questions |
| M03 — Assets, presets and recipes | In progress; stop boundary | Qualify the unfinished source; implement approved category application and complete recipe use, destination compatibility and broader asset/dependency/readiness cases. Decide final library content separately |
| M04 — Complete planting workflow and UI | In progress | Complete local task panel, coherent real artist workflow, explicit regional flower behavior and the single-file HTML simulation; qualify correction, stale review, failure and shortfall UX |
| M05 — Targeted edits and adoption | In progress | Broader identity-preserving patches, manual conflict resolution, layer/source lifecycle operations and deliberate adoption of supported existing setups |
| M06 — Core placement parity | Planned | Qualified density/target/refill semantics, source kinds/weights/replacement, grid/clustering, transforms/projection, radius/collision/Relax and eligibility controls |
| M07 — Areas, masks, Paths and Analyzer | Planned | Typed receiver-bound Paint Areas and coverage, qualified masks and mappings, Paths/Bands/curves and versioned Analyzer bindings |
| M08 — Persistent instance Edit | Planned | Stable generated-instance selection, move/clone/delete/protect/radius overrides and supported rebuild/save/Undo correspondence |
| M09 — Durable tasks and lifecycle | In progress | Reopen/reconnect and original-result policy, deletion/reset/clone/merge cases, changed assets, damaged records and safe restoration of pending/manual work |
| M10 — Assisted discovery and visual iteration | Planned | Measured role suggestions, bounded spatial reasoning, expressive refinements and reliable before/after/reference evidence |
| M11 — Output and optional rendering | Planned | Complete output provenance and supported native export/cleanup bridges; renderer jobs only where explicitly included and qualified |
| M12 — Performance and clients | Planned | End-to-end latency, round trips, payload/cache behavior, native solve/upload/draw costs, peak/history memory, responsiveness and intended-client compatibility |
| M13 — Final qualification and delivery | Planned | Close required coverage gates, artist workflows and failure cases; align documentation and identities; produce verified MCP delivery and matched runnable Max 2027 installer |

## Recommended restart decision

Review this checkpoint first. The next engineering step, if resumed, is to establish the exact status of the unfinished admission/lifetime edits, then finish the public preset path through the existing proposal/approval/apply/status pipeline. Preserve native settings as authoritative and recheck real workload, derived-mask effects and destination freshness. Follow with complete recipe use using test content.

Then complete the M04 artist workflow and UI before expanding across the remaining feature families. This gives a comprehensible vertical workflow to evaluate while M05–M12 broaden capability and reliability. Final content curation should not be confused with the integration gates, and an expanding content library should not be required to prove the control architecture.

Implementation is paused here. The remaining roadmap is retained, not canceled or declared complete.

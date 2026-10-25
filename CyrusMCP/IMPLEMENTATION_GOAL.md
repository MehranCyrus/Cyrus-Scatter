# Cyrus MCP implementation goal and milestone ledger

Prepared and activated: 24 October 2026. Status: **paused at the user's request at the M03 library checkpoint**. M00/M01/M02/M03/M04 have partial implementation, alongside M05/M09 foundations. The full M00–M13 objective remains open. See the [checkpoint report](CHECKPOINT_20261024.md) for current capabilities, test-content status, unfinished source changes and every remaining phase. Earlier active/next-step notes below are historical progress entries, not authorization to continue during this pause.

## Master objective

Build, qualify and package a complete Cyrus Scatter MCP integration for 3ds Max 2027. An external AI client must be able to understand an explicitly permitted scene scope, discover supported features and available assets, propose understandable changes, obtain the required local approval, create and refine native Scatter work, inspect actual results, and recover reliably from errors and interrupted connections. Extend this workflow through the supported native feature families using typed domain operations and the existing native engine.

The artist supplies intent and consequential choices. The plugin supplies measurements, native calculations and verified outcome evidence. Conversation, the native task panel and the viewport share the same task state. Existing native settings remain authoritative and manually editable.

Maximum capability means the greatest useful, tested coverage of the agreed native baseline plus the task context and feedback required for effective AI use. It does not mean unrestricted MAXScript execution, a tool per UI control, unlimited work, or a guarantee that arbitrary scene semantics can be inferred. Broad context should be progressively available inside explicit scope, without making whole-scene classification a prerequisite.

## Baseline and finite scope

- Repository: `F:/Cursor/_Cyrus_Apps/CyrusScatter`.
- Observed planning HEAD: `588abff0ce211d7dc63798b8c5310631895465c7`, branch `codex/workflow-0.75`. This is an observation, not a frozen qualification snapshot.
- README test delivery: Scatter 0.86.9.2 / schema 59 / CyrusUnified2, Analyzer 0.14.2. Historical multi-host packages do not extend this project's default Max 2027 qualification scope.
- Planning snapshot: MCP package 0.73.0 / authoring plan 0.73, twelve tools and seven resources. M01 typed changes add a thirteenth source tool; M02 explicit scene measurements add a fourteenth. M03 installed model metadata discovery adds two more, for sixteen development tools. Typed recipe discovery adds two more for eighteen tools, prepared-source validation a nineteenth, installed-source preparation a twentieth, and settings-preset search/inspection two more for twenty-two development tools. Passive destination settings add a twenty-third development tool; source discovery is distinct from the older installed client. The older configured integration remains distinct. Catalog help covers more than the write API. Installed, source and loaded identities must be checked afresh.
- The current catalog contains 36 feature-family rows and 333 control entries. These are inventory observations, not target tool counts or proof of automation support.
- M00 freezes a named native baseline and a coverage matrix. Include supported artist-facing authoring, inspection, library, presentation and output workflows. Inventory every family; classify individual operations rather than assuming a whole family has equal support.
- Retired behavior, licensing administration, experimental training/style learning, unrelated Arrange/Physics products, arbitrary host scripting, external asset purchasing and cloud services are outside this goal. A dedicated new project is required for those extensions.
- Supported native features added after the M00 baseline enter an explicit follow-up list. They do not silently move this goal's finish line. Amend the baseline deliberately when useful.
- Advanced features marked required cannot be declared complete merely by documenting them as unavailable. Resolve their prerequisites or obtain an explicit scope change. Unsupported requests must still produce an honest explanation and supported handoff.

This document is the proposed implementation scope. Activating the goal starts phased coding and testing. It does not itself install into an artist profile, restart an artist session, push changes, publish a release or deploy services.

## Product workflow

1. Select a supported receiving area or explicitly enroll a supported existing Scatter setup; describe the intended result.
2. Inspect cheap scoped facts first. Resolve sources, units, existing planting, editable owner and relevant constraints.
3. Show a compact, correctable role map. Keep semantic role, evidence, measurement validity and edit permission separate.
4. Resolve consequential ambiguity through picking or focused questions; propose visible defaults for aesthetic choices.
5. Validate a concrete proposal against current settings and dependencies. Show assets, zones, exclusions, intended changes, work budget and limitations.
6. Obtain the required local approval for those exact effects. Calculate through the existing native pipeline and verify the actual result.
7. Report authored settings, completed publication and display state separately. Refine the same task, preserving unrelated manual work.

Sources, valid scale, scope and hard constraints must be resolved before execution; they need not all become onboarding questions. Helpful scene names, containers and layers are optional accelerators. The assistant must not reorganize artist objects merely to interpret them.

## Milestones

All milestones begin as planned. Numbering describes implementation order, not product release versions. Earlier vertical slices should be delivered and tested before the entire roadmap is complete. Later discoveries may change the sequence if the revised dependencies and acceptance remain explicit.

### M00 — Establish a truthful baseline and capability contract

Deliver:

- Record matching native/script/adapter/client identities and supported protocol/schema versions; reproduce the present bounded workflow in an owned Max 2027 environment.
- Build the operation coverage matrix: native availability, current read/write API, supported combinations and limits, prerequisites, required/optional/excluded scope, tests and evidence.
- Align generated catalog, tool descriptions and capability responses with actual support. Keep native help distinct from callable mutations.
- Record current tests, known defects, performance baselines and concurrent changes; select independently versioned delivery labels under repository policy when needed.

Complete when an intended external client discovers the correct contract and one real current owned operation is verified against a recorded matched build. Offline tests alone are insufficient.

### M01 — Reliable operation outcomes, approval and recovery

Deliver:

- Typed request/result/error contracts and operation receipts distinguishing queued/running/terminal state from actual effects: none, committed, verified rollback or unknown.
- Correct post-generation fingerprint/export/journal failure handling. Preserve known committed identities even if later verification or bookkeeping fails.
- Exact proposal approval, stale-state rejection, serialized mutation, idempotency and reconciliation after timeout/disconnect/process loss.
- Explicit cancellation behavior for queued versus executing native work, plus verified scoped Undo/recovery. Do not promise mid-call interruption without native support.
- Separate configure-only and apply-and-calculate effects; define the settings, publication, helper/import and Undo boundaries.

Complete when failures before and after native publication, journal faults, stale admission, cancellation races and retries preserve artist work and cannot silently duplicate creation or falsely report success/no-change.

### M02 — Scoped scene context, roles and task memory

Deliver:

- Bounded inspection of selection, supported owners, relevant neighbors, units, hierarchy, object types, source readiness and current bindings, with revision/scope/omission metadata.
- Task-local receiver/source/exclusion/preserve/context roles; one object may have several roles. Provide native Pick/Highlight and correction without restarting the task.
- Distinct static feature knowledge, live scene state and operation evidence; retrieve additional details only when they affect a decision.
- Retain confirmed intent and role bindings while independently invalidating changed geometry, measurements, proposal approval and results.
- Handle mixed selections, ambiguous curves, stacked surfaces, existing planting, misleading names and unsupported geometry honestly.

Complete when organized and unorganized scenes can reach a correct reviewed proposal without mandatory renaming, unrelated mutation, arbitrary broad scanning or repeated questions about still-valid choices.

### M03 — Asset, preset and recipe discovery

Deliver:

- Bounded search/list/inspect for authorized installed library entries, presets, recipes and selected scene models, using stable references and existing content engines.
- Dimensions, source-unit meaning, category/thumbnail where available, dependency readiness, supported proxy/material types and physical scale validation.
- Explicit import/instantiation effects and destinations in the proposal; no arbitrary filesystem API.
- Asset-aware starting recipes and compatibility checks for geometry, receiver topology and units. Broaden current low-poly admission only with native metadata paths and measured resource limits.

Complete when the AI can select or reuse viable assets and instantiate a qualified recipe, while missing dependencies or incompatible transfers reject cleanly and preserve previous work.

### M04 — First complete planting workflow and native task panel

Deliver:

- One coherent selected-area grass-and-flower task using explicit sources or a vetted preset, two editable logical layers and simple picked exclusions.
- Real spatial flower zones through supported native area controls; source weights must not substitute for patches. A native authoring handoff is acceptable for the first slice, with typed area authoring completed in M07.
- A compact native panel for task scope, role correction, constraints, proposal diff, approval, actual state and recovery; retain access to normal Scatter controls.
- A working single-file offline HTML simulation with shared conversation/panel/scene state. Exercise correction, stale proposals, manual changes, shortfall, cancellation and missing-asset recovery; label all simulated data.
- Zone overlay first; optional regional trials only with an explicit effect/cleanup contract. Distinguish full solve with reduced display from reduced solve scope.

Complete when an artist can create, review and refine this task through the real external client and Max, and can understand what changed, what is pending and what the viewport represents. Prototype behavior is not host qualification.

### M05 — Targeted editing and controlled adoption of existing setups

Deliver:

- Identity-preserving typed field/layer/source patches; omitted fields remain unchanged and resets are explicit.
- Explicit editable enrollment for supported existing setups, faithful inspection and preservation of untouched/unknown settings.
- Conflict detection against intervening manual edits, with nonconflicting edits retained and overlapping changes shown for resolution.
- Supported create/copy/remove/reorder operations, clear ownership and explicit Manual/Live update behavior.

Complete when both assistant-created and deliberately adopted supported setups can be refined without reconstructing unrelated settings, stealing ownership or losing pending artist work. Unrepresentable setups remain inspectable with a precise native handoff.

### M06 — Core population, source and placement parity

Deliver qualified typed operations for:

- Candidate budget, density, accepted target, seed, bounded attempts/refill and explicit shortfall policy.
- Source weights and supported model/Point/Empty kinds, replacement and container membership, preserving source-row identity and saved settings.
- Grid/random and supported clustering controls; rotation, scale, movement, orientation and projection.
- Manual/Auto source radius where qualified; own-copy/same-layer/cross-layer clearance, priorities, cleanup and Relax.
- Slope/altitude eligibility and supported per-layer/source enable/display settings.

Complete when results match equivalent native authoring within declared numerical tolerances, units and deterministic scope. Report candidates, attempts where available, accepted, geometry-producing and displayed populations distinctly. Exact accepted targets and exact per-source quotas are separate capabilities.

### M07 — Coverage, masks, Paint Areas, Paths and Analyzer integration

Deliver qualified typed operations for:

- Layer receivers, include/exclude regions, receiver-bound Paint Areas, vector coverage and supported import/export, preserving terrain and curved-surface semantics.
- Image/procedural/surface-field masks, mappings, responses and supported asset graphs, with explicit dependencies and no invented renderer context.
- Paths/Bands, ranges, joins, assignment, density/scale curves, layout fields and supported falloff controls.
- Explicit supported bindings to independently versioned Surface Analyzer capabilities.
- Defined planting-zone coverage and clearance measurements, with method, denominator, coordinate convention and tolerance. Complex footprints require a qualified method that preserves holes and stacked-surface distinctions.

Complete when supported area composition and targeted regional refinement work through MCP with native-equivalent ownership, physical units, lifecycle behavior and truthful approximate/exact measurements. Canonical coverage authoring need not emulate mouse gestures.

### M08 — Persistent instance Edit and protected-placement workflows

Deliver:

- Bounded inspection/selection of generated items by qualified owner/publication/instance identity.
- Supported move, clone, delete, protect and radius-override commands with source-aware correspondence, history, Undo/Redo and failure retention.
- Clear distinction between protecting an ordinary scene object, retaining authored settings and retaining particular generated instances.

Complete when promised instance operations survive the supported rebuild/save/Undo lifecycle. Resolve or explicitly gate relevant native identity defects such as B37 before exposing affected operations. A matching random seed alone is not a retention guarantee.

### M09 — Durable sessions, document lifecycle and restoration

Deliver:

- Persistent task bindings, constraints, quantity interpretations and operation records alongside authoritative native state.
- Tested reopen/reconnect, owner deletion, scene reset, rename, duplicate IDs, cloning/merge/XRef cases within the declared supported scope.
- Missing/changed assets and geometry, schema/version mismatches, damaged records and unknown outcomes produce explicit recovery paths rather than guessed rebinding.
- Scoped restoration preserves the artist's earlier pending settings and later unrelated edits according to an explicit policy.

Complete when supported returning tasks resume with valid context, stale data is caught, original files remain preserved and no operation silently binds a same-named replacement. Any task-focused scene-save feature must declare its destination and overwrite effects separately.

### M10 — Bounded assisted discovery and visual design iteration

Deliver:

- Incremental role suggestions for tested scene families, scoped spatial queries and geometric measurements; artist corrections remain first-class task data.
- Expressive requests such as larger patches, less planting near an entrance, height transitions and source replacement become supported, inspectable native changes.
- Shared viewport/reference evidence carries camera, frame, display and publication provenance. Reference images express preferences, not geometric proof.
- Qualified before/after or variant comparisons with held conditions and explicit budgets. Camera-visible coverage optimization is a separately measured advanced capability, never inferred from source weights.

Complete when assistance reduces total preparation/review/correction effort on held-out artist tasks without increasing serious scope or preservation errors. General scene classification and perfect reference reconstruction are not prerequisites or promised outcomes.

### M11 — Publication, output and optional renderer jobs

Deliver:

- Complete cached manifests, bounded paging, layout/execution records and task-linked artifacts with source/settings/dependency provenance.
- Supported native output/export/cleanup bridges where included in the M00 matrix, preserving geometry, materials, UVs, identity and ownership within verified limits.
- If renderer execution is included, add bounded jobs for named supported renderers with exact scene/camera/output scope, artifact retrieval, cancellation/recovery and renderer-specific tests.

Complete when exported or rendered results are verified against the intended complete publication and no unrelated output is overwritten or removed. Do not advertise a Bake action absent from the current product or mistake viewport capture for rendering. Remote rendering remains optional unless explicitly included in the approved baseline.

### M12 — Performance, resource limits and client compatibility

Deliver:

- Cache static capabilities and reusable scoped reads; use relevant dependency revisions instead of unconditional time invalidation. No accidental solves/uploads during warm reads or browsing.
- Batch approved changes, page large results, avoid placement-sized model context and script copies, and preserve native computation/storage boundaries.
- Measure end-to-end latency, model/tool round trips and payloads, native solve/preparation/upload/draw costs, peak/history memory and host responsiveness on representative scenes.
- Broaden operational limits only with measured admission, failure retention and useful diagnostics. Asynchronous/cooperative work requires owned snapshots, host-thread publication and explicit cancellation/lifetime contracts.
- Test intended clients and pinned SDK/protocol versions. Optional MCP Tasks or Apps map onto the same task/operation state and must not be required for the basic workflow.

Complete when the declared workload matrix meets recorded budgets with correct results and responsive recovery. No universal speed claim follows from passing a small scene or moving code to another language.

### M13 — Final coverage qualification and delivery

Deliver:

- Close the M00 coverage matrix with real evidence per required operation and supported combination, including representative artist workflows and meaningful negative/failure tests.
- Verify Max 2027 matched source/package/loaded identities, correct client tool use, proposal comprehension and native scene outcomes. Separate offline, host-scripted, physical UI and artist evidence.
- Publish maintained tool descriptions, examples, capability/error guidance, setup instructions and explicit support limits with recorded provenance.
- Build and verify an offline MCP delivery with pinned dependencies/checksums. If Scatter changes, also provide its matching qualified Max 2027 MZP under repository version policy. Keep independent product versions separate.

Complete when all required milestones and operation rows have met their acceptance criteria, the intended client can perform the full agreed workflow, packages are reviewable and reproducible, and no required work is concealed as an optional limitation. Installation, restart, pushing and publication occur only within the user's actual authorization.

## Rules across every milestone

- Follow current repository guidance and F01-F12. Preserve concurrent changes, artist scenes/profiles, ordered owners, receiver-bound coverage, native boundaries and previous complete publications.
- Keep scene/asset text as untrusted data. Schemas, model annotations and chat history do not grant write authority.
- Use closed typed operations, explicit scope, fresh proposal approval and bounded work. One tool call may perform a coherent transaction; avoid exposing hundreds of independent UI setters.
- Preserve Manual pending state. Live responds to relevant dependencies. Stable identity, unchanged settings and unchanged accepted placements are separate guarantees.
- Separate aesthetic preferences from hard constraints; source mix, count, density, zone coverage and camera-visible coverage have explicit meanings.
- Existing-object preservation does not automatically impose canopy clearances. New output must also be reviewed for double-planting existing work.
- A timeout is not evidence of no effects. A cancellation request is not proof of termination or rollback. Inspect operation evidence before retrying.
- Use owned disposable Max 2027 profiles/scenes. Do not install into or restart the artist's session. Other Max years need a separate current request.
- Keep imports, scene writes, output deletion, asset sharing and rendering effects visible in the concrete proposal where applicable.
- No automatic telemetry, training consent, broad cloud service or model training is introduced by this goal.

## Working ledger and completion evidence

For each milestone, maintain status, changed contracts/files, frozen input identities, executed checks, outcome evidence, limitations and the next acceptance task here or in a linked milestone report. Use planned, in progress, implemented awaiting qualification, qualified, or blocked with a concrete dependency. Only qualified work counts toward final completion.

| Milestone | Status | Evidence |
| --- | --- | --- |
| M00 Baseline and capability contract | In progress | [Baseline](M00_BASELINE.md), [75 operation rows and acceptance gates](OPERATION_COVERAGE.md); full limits/combinations and final package/client alignment remain open |
| M01 Reliable operations | In progress | [Operations](M01_OPERATIONS.md), [typed changes](M01_CHANGES.md), [bounded recovery/UI](M01_RECOVERY_BOUNDS.md), [three actual process-loss/restart cases](M01_PROCESS_LOSS.md), [verified/uncertain local Undo](M01_UNDO.md); 369 offline tests and scoped SDK/native Undo cases pass; wider lifecycle/storage and interaction gates remain open |
| M02 Scoped context and roles | In progress | [Onboarding/roles/measurements](M02_SCENE_CONTEXT.md) and [scope extension/geometry readiness/explicit design handoff](M02_HANDOFF.md); 413 offline tests and scoped fourteen-tool Max/client workflows pass. Earlier Windows task input and reset/close witnesses remain scoped evidence. Broader discovery/readiness, artist UX and lifecycle gates remain open |
| M03 Assets and recipes | In progress | [Discovery](M03_LIBRARY_DISCOVERY.md), [recipe readers](M03_RECIPE_READER.md), [typed recipes](M03_RECIPES.md), [native source metadata](M03_SOURCE_METADATA.md), [approved prepared-source use](M03_ASSET_USE.md): 493 Python /58 native suites; nineteen-tool SDK imports actual grass/flowers with scoped rollback/Undo/Redo, Auto Key preservation, same-task planting, truthful committed-completion faults, lifecycle release and old-pair denial. `.max` merge stays excluded (B38). [Installed-source selection and retained snapshots](M03_INSTALLED_SOURCES.md) add twenty-tool SDK discovery, approved three-package import/rollback/Undo, native handle release and same-task two-layer planting (137 verified rows); 519 Python/tool tests and 58 native suites pass. [Settings preset discovery](M03_SETTINGS_PRESETS.md) adds all five native categories, actual frozen typed values, 512-entry paging, reader independence, reset/open/close and old-native denial; 546 Python/tool tests and 58 native suites pass. [Passive destination settings](M03_DESTINATION_SETTINGS.md) adds twenty-three-tool scoped readback, seven external-SDK/Max cases, 567 Python/tool tests and 58 native suites; it also fixes a measured native preset unit-roundtrip defect. Preset/full-recipe application, broader readiness and artist/workload/package acceptance remain open |
| M04 First complete task and UI | In progress | [Installed-content end-to-end successor](M03_INSTALLED_SOURCES.md) verifies discovery → preparation → approved import → same-task design and 68 grass / 69 flower rows. [Real planting slice](M03_SOURCE_METADATA.md): picked convex flower zone, two actual plant source meshes, 85 grass / 2 flowers initially, typed flower refinement to 19 with every grass row and both layer identities preserved. Scripted local approval only; complete panel/HTML/artist/returning-task and broader refinement gates remain open |
| M05 Targeted editing/adoption | In progress | [Owned count/seed and configure/Update foundation](M01_CHANGES.md); scoped Max/SDK cases pass with stable layers and untouched settings; broader typed patches, manual conflict handling and explicit adoption remain open |
| M06 Core placement parity | Planned | Not started |
| M07 Coverage/masks/Paths/Analyzer | Planned | Not started |
| M08 Persistent instance Edit | Planned | Not started |
| M09 Durable lifecycle/recovery | In progress | [Process-loss foundation and measured cold-reopen gap](M01_PROCESS_LOSS.md); task context/adoption, manual conflicts and reconstructed-publication handling remain open |
| M10 Assisted discovery/visual iteration | Planned | Not started |
| M11 Publication/output/render jobs | Planned | Not started |
| M12 Performance and clients | Planned | Not started |
| M13 Final qualification/package | Planned | Not started |

Qualification starts with each affected milestone, not after M12. Final qualification integrates the accumulated evidence. Do not mark the master goal complete merely because tools register, mock tests pass or an HTML demo looks convincing.

Current work has M00/M01/M02 with M05/M09 foundations. Three owned process-loss/restart boundaries preserve uncertainty/commit evidence and prevent replay/new-key writes until local review. Local Undo journals verified, unknown and committed-but-incomplete outcomes; scoped native creation/refinement/configure/Update and fault cases pass. M02 shares/extends selected context, retains task intent/roles through an explicit separate design grant, reports source-local geometry/qualified receiver facts, and supports a whole-surface region without a redundant input spline. SDK creation/refinement and brief-invalidation cases pass alongside earlier clean-scene/Windows/reset witnesses; the M02 suite had 413 passes. M03 adds local installed catalog sharing and two cached read tools; 432 tests and the scoped 96-entry SDK/native campaign pass, including refresh/revoke/missing-content and same-task handoff. Discovery never claims import readiness.

Typed recipe discovery now passes 458 Python tests and scoped eighteen-tool SDK/Max workflows, including complete 256-entry paging, refresh/revoke, reset/open/close and old-build capability denial. The confined-reader successor passes 57 native tests including long paths. This remains an internal matched prototype, not a replacement of the frozen packaged baseline. Next extend M03 through settings-preset discovery, native source dimensions/unit/dependency readiness and explicitly approved asset/recipe use, reusing installed engines. See the M03 report for import Undo/resource prerequisites; cached metadata alone grants no use authority. Keep remaining M01 lifecycle/storage/interaction gates in affected campaigns. Explicit local selection supplies added neighbors; general spatial discovery and broader receiver geometry remain open. Cold reopen reconstructed pending Manual results (135→168 and 127→164), so M09 returning-task/publication restoration remains unqualified. Successful Undo still clears transient task context; M04/M09 must address returning to the task. Full field/workload/combination/client/package and artist acceptance remain open; neither the matrix nor scoped fixtures complete the goal.

The [native source successor](M03_SOURCE_METADATA.md) passes 469 Python and 58
native tests, adds source API 1 with no Python mesh copies, and verifies actual
grass/flower source sizes plus regional SDK creation/refinement. Earlier discovery
test counts retain their original scope. Direct Max 2027 probes establish that
both the current header read and `.max` merge destroy earlier Undo history; they
are not exposed as safe MCP asset use. The next M03 acceptance task is a qualified
portable asset-use path through the existing native package/mesh/material engines,
with preserved prior history, failed-stage rollback and explicit dependency,
destination, approval and resource contracts. Complete presets/recipe application
and M04 interaction/HTML/artist gates remain open. Do not treat the 2→19 flower
result as exact regional target or density support.

The native portable-staging prerequisite now passes on the actual plant package:
prior history survives, import Undo removes only new nodes, Undo/Redo works with
the package unavailable and prepared handle released, and a post-staging failure
retains existing state. The typed public asset-use operation, dependency-denial,
full material/output and artist-approval acceptance remain open; this proof does
not itself enable MCP imports or close M03.

The [approved prepared-source successor](M03_ASSET_USE.md) now connects that engine
to a separate local grant, nineteenth typed tool, native proposal review and the
shared apply/status/idempotency/journal pipeline. Four real SDK/Max workflow
cases, four native lifecycle cases and the historical packaged-pair denial pass;
30 frozen runtime files and five loaded native hashes match. Actual planting
using the imported sources publishes 143 accepted rows from 160 candidates.
Earlier staging-only reports retain their narrower scope. Next connect vetted
prepared content to installed discovery and complete preset/recipe use; retain
remaining M01 fault, M03 material/dependency/workload and M04/M09 interaction,
HTML/returning-task gates. No release package or artist installation is implied.

The final post-commit successor repeats the normal workflow and adds a fifth
native fault case: source copies remain committed when completion fails,
selection verification remains unknown, retries preserve the original receipt
and new writes require local review. Local retirement preserves the copies and
committed history without replay. It passes 493 Python tests and publishes 139
matching rows from 160 candidates in its own fresh scene; the earlier 143-row
witness retains its original scope. Source-specific recovery/adoption, remaining
M03 discovery/application, M04 interaction/HTML and final delivery remain open.

## Supporting evidence

- [Current repository baseline](../README.md), [workflow](../docs/AGENT_WORKFLOW.md), [engineering foundation](../docs/ENGINEERING_FOUNDATION.md) and [version policy](../docs/Release_Versioning.md).
- [Capability matrix](../docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md) and [MCP source contract](README.md); inspect current source rather than inheriting old qualification labels.
- [MCP audit](AUDIT_20261023.md), [research](RESEARCH_20261023.md), [system design](SYSTEM_DESIGN_REVIEW_20261023.md) and [scene onboarding](SCENE_ONBOARDING_WORKFLOW_20261023.md).
- External interaction study reviewed in this chat: `C:/Users/Mehran/Downloads/Cyrus_Scatter_AI_Interaction_Research.html`. Its recommendations and static mockups are design evidence, not executed product capabilities.

The installed-content successor now completes a scoped twenty-tool SDK workflow
using the existing catalog, portable package engine and exact approval pipeline.
A real three-package test exposed the single replaceable native package snapshot;
bounded retained native leases correct that ownership defect. Five import/recovery
cases and the separate same-task discovery/import/planting/export chain pass on
the matched successor; 31 frozen runtime files and five loaded hashes match.
519 Python/tool tests and 58 native suites pass. All 96 catalog entries remain
discoverable; 13 derivatives pass the current preparation admission, with every
omission recorded. Complete preset/recipe use, wider asset/adapter/workload and
artist/lifecycle/package acceptance remain open. See
[M03 installed sources](M03_INSTALLED_SOURCES.md). The full M00–M13 objective
remains active; this is an internal tested increment, not a release or installation.

The native curve prerequisite in [destination settings](M03_DESTINATION_SETTINGS.md)
now passes thirteen actual Max/SDK cases on producer `mcp-preset-curves-20261024-07`
and owned host `mcp-preset-application-20261024-09`, with 33 frozen runtime files
and five loaded native hashes verified. It covers precise capture/reapply,
unchanged editor browsing and persistent model Undo/Redo after editor closure;
two earlier fatal scripted-controller Undo failures remain recorded. Physical
dragging and public approved application remain open. Caller-owned native
transaction composition is being implemented and needs its own successor
qualification before integrating preset application with the common MCP
proposal/apply/status pipeline. O67/O68 and the full goal remain required.

The composed-transaction successor now passes sixteen scoped Max/SDK cases on
producer `mcp-preset-transactions-20261024-01` and owned host
`mcp-preset-application-20261024-10`, including one-hold category/configuration
changes, shared-controller preservation and caller cancellation. Its separate
physical drag/close/Undo campaign reproduces a fatal native editor error;
that failure does not erase the narrower scripted evidence or qualify artist
interaction. A native history-owned controller reference is the current repair
hypothesis and is building as `mcp-preset-transactions-20261024-02`. It must pass
fresh scripted, physical and history-retirement checks. Public approved preset
application, full recipes and all remaining milestone gates stay open.

The controller-lifetime successor now passes sixteen scripted Max/SDK cases
plus the actual density-point mouse drag/close/Undo/Redo that failed on the
predecessor. On producer `mcp-preset-transactions-20261024-02` and owned host
`mcp-preset-application-20261024-11`, the live native history references change
1→3 for selection/drag, remain valid across exact Undo/Redo, then release to zero
on normal owned scene reset. Source/runtime/loaded identities match; 567
Python/tool tests and 58 native suites pass. The linked destination-settings
report retains earlier failures and remaining invalidated-owner/other-editor
lifecycle limits. Next integrate the qualified caller transaction into exact
approved public application, preserving authoritative native settings and real
workload admission; full recipes and M00–M13 stay required. No release, artist
installation, restart or package delivery is implied by this internal increment.

The [settings-preset reader successor](M03_SETTINGS_PRESETS.md) now exposes
twenty-two tools/seven resources, using the existing native typed preset parser
and bounded file worker with independent ownership. Five real SDK/native workflows,
three reset/open/close cases and the old packaged-native denial pass. The native
58-suite successor and 546 Python/tool tests pass; 32 frozen runtime files and five
loaded modules match. Native typed values, metre flags, original-file and normalized
v3 hashes are available without application authority. Next implement faithful
category/settings readback and exact approved preset application, then full recipe
use. Preserve untouched/manual/pending native state. O67/O68, remaining M03 gates
and the full M00–M13 objective remain open; no release or artist installation.

The [destination-settings successor](M03_DESTINATION_SETTINGS.md) verifies exact
scoped layer IDs, all five native category families, inherited/explicit spacing,
stored curves and unsupported/animated controller availability without geometry
fingerprinting, default initialization or scene/history/publication changes. A
real centimetre preset-roundtrip defect was fixed in the maintained native script
template and generated output; identical population/transform/spacing applies
now remain passive in the owned regression. Seven external-SDK/Max 2027 cases,
567 Python/tool tests and 58 native suites pass; 33 frozen runtime files and five
loaded hashes match. Earlier failed receipts remain preserved. Next implement
exact approved category application with faithful authoritative settings and
curve graph/sample validation, then complete recipe use. O67/O68, broader M03
and every remaining M00–M13 gate stay open; no release or artist installation.

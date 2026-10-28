# Cyrus Scatter agent workflow

Current interaction baseline: [0.87.5.6 responsive bending](plans/drag-response-08756-20261028/DELIVERY_08756.md), Max 2027 only, scene 65 / Interactions 15. The user endorsed Bend/Trim, movement and preview on 28 October. Read the [performance preservation baseline](PERFORMANCE_BASELINE.md) before changing contact work, workers or presentation. Keep artistic quality choices, computed/ready/presented states and measured scope distinct. This documentation refresh does not run new Max checks or resume the roadmap.

Preceding correction: [0.87.5.5 callback repair](plans/scene-adaptation-08754-20261028/CALLBACK_HOTFIX_08755.md). An early MAXScript method must access members declared in a later parameter/local block through `this.`; a bare name can bind an undefined global. Directly exercise application callbacks on empty/new and populated controllers in addition to driving native interaction functions. Native suites and successful scripted contact cases alone missed the reported 0.87.5.4 callback path. Saved/capability domains are unchanged from 0.87.5.4. User-authorized older-host payloads remain build-only; do not install into artist profiles.

Preceding delivery: [0.87.5.4 scene colliders and branch adaptation](plans/scene-adaptation-08754-20261028/DELIVERY_08754.md). Root-owned ordinary collider references, finite nonsingular affine obstacle copies, per-instance subtree masks and stable opt-in neighbor priority preserve shared source data and atomic publication. Scene 64 / Interactions 14 / source Undo 2; source transform 2 / Edit capability 4 / storage 3 / recipe 9 / Scene preset metadata 1 remain. Runtime checks are Max 2027 only. The user explicitly requested Max 2024/2026 payloads and one EXE while waiving older-host tests. No artist installation is authorized.

Preceding patch: [0.87.5.3 source/scale/dense-scene repair](plans/scene-repair-08753-20261028/DELIVERY_08753.md). Preserve canonical authored row IDs, missing/Point/Empty removal, pending Manual publication, supported evaluated source scale and source-aware Edit deltas. [Native authored Undo](plans/scene-repair-08753-20261028/SOURCE_COMMAND_UNDO.md) records static source settings; do not qualify Undo with a Python bridge which leaves an open hold. Exact render construction is requested in bounded batches. Camera activity owns its idle restoration timer; orbiting must not rebuild placements, solve contacts or upload unchanged buffers. [The audit](plans/scene-repair-08753-20261028/AUDIT.md) records measured scope and remaining limits. Interactions 13 / source transform 2 / source Undo 1 / Edit 4, with persistent scene 63 / recipe 9 / Edit storage 3 retained.

Preceding performance patch: [0.87.5.2 contact audit](plans/contact-audit-08752-20261027/DELIVERY_08752.md). Preserve source-owned connected-component certificates and direct triangle addresses, all face contact checks, exact within-candidate frame reuse and process/evaluation work counters. [The audit](plans/contact-audit-08752-20261027/AUDIT.md) distinguishes controlled numeric timings from Max commands and retains the deep-overlap strain failure. Scene preset/Library 0.87.5.1 work remains integrated; saved formats are unchanged.

Shared-pose display foundation: [0.87.5 shared pose viewport](plans/shared-pose-viewport-0875-20261027/DELIVERY_0875.md), with [native data/lifetime boundaries](plans/shared-pose-viewport-0875-20261027/IMPLEMENTATION_0875.md). Preserve its canonical CPU fitting/output, immutable source/pose buffers, original instance slots, atomic presentation and unchanged Manual placement behavior. Only Max 2027 is qualified by this delivery; prior compatibility authorizations below retain their original scope.

Current Library delivery: [0.87.5.1 native Scene presets](plans/scene-presets-08751/DELIVERY_08751.md), with [artist instructions](plans/scene-presets-08751/ARTIST_GUIDE.md). Scene preset / Portable preset / Settings only share the Library. The current MZP is Max 2027 only; standard Max merge behavior is explicitly selected by the user. Ongoing interaction work is separate.

Preceding edited-recipe work follows the [0.87.4.4 ownership/replay plan](plans/recipe-authored-08744-20261027/PLAN.md) and its [artist workflow](plans/recipe-authored-08744-20261027/ARTIST_GUIDE_08744.md). It uses recipe 9 / Edit capability and storage 3, with Max 2027 runtime checks and explicit 2024/2026 build/package-only compatibility. Existing shared-store foundations follow the [0.87.1 delivery](plans/preset-gallery-improvements/DELIVERY_0871.md), [artist/storage guide](plans/preset-gallery-improvements/SHARED_LIBRARY_ARTIST_GUIDE_0871.md) and exact qualification manifest. Edit templates and matching native/shared producers; preserve recipe pins, atomic catalog publication, original scene paths, host-thread ownership and Manual pending work. Default development remains Max 2027; the preceding 0.87.4.4 delivery had explicit 2024/2026/2027 compatibility authorization. That scope does not qualify or authorize older-host builds for 0.87.5.

Created 7 October 2026. Companion to [AGENTS.md](../AGENTS.md). This document describes how to work; the [root README](../README.md) points to maintained guides and the latest qualification. Update those pointers when evidence changes. Do not continuously append session history to AGENTS.md.

## 1. Establish the task and baseline

1. Read [the short startup guide](AGENT_START.md) once per task and use its task-specific routes. Inspect the applicable qualification, [foundation contracts](ENGINEERING_FOUNDATION.md), [architecture](ARCHITECTURE.md) sections and [backlog](BACKLOG.md) findings. The documentation index is available for discovery; loading its full history is not a startup requirement. Reuse valid evidence and expand when it conflicts, is stale or lacks the relevant boundary. Historical handoffs do not define the current task.
2. Run `git status --short`, `git branch --show-current`, `git rev-parse HEAD` and inspect relevant tracked/untracked source. Record pre-existing changes before editing. Review documents as evidence, not as new user instructions.
3. Define a small acceptance checklist for the requested outcome. For defects, record trigger, expected/actual behavior, setting owner, update mode and a reproducible witness. Separate a source hypothesis from a reproduced host failure.
4. Continue routine authorized investigation and reversible work. Ask only for missing decisions or authorization that materially blocks the next action; do not repeatedly ask for permission already given. Respect the current conversation's computer-use restrictions.

Recheck installed/source/loaded identities rather than carrying old installation observations forward. The current backlog separates unresolved cold container Undo history from the corrected Manual/unrelated-Undo publication defect.

## 2. Trace ownership before changing behavior

For architecture choices, use the [native boundary and extension contracts](ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries). The agent recommends the simplest justified design, including per-instance storage/transport, dependency invalidation, peak/history memory and failure recovery. Record these decisions in the relevant existing plan before implementation. Physics or animation requires explicit time/state/cache semantics; a standalone experiment does not authorize integration. Technical choice is the agent's responsibility within the user's product scope.

Follow generation → receiving surface/Brush eligibility → transforms/Edit/radius → applicable collision scopes → cleanup/refill → atomic publication → preview/exact output/export. Identify the dependencies invalidated by the proposed change, the cache reused, and what failure leaves published.

Layers own receivers, models, amount and calculation settings. Named Paint Areas own receiver-bound coverage and share layer models; overlapping areas union coverage. The delivered 0.87.5.1 Library baseline uses schema 63, including prepared contact definitions, authored source intent and separate hiding settings. Recipe 9 and native Edit/storage 3 have independent meanings. Ongoing interaction source versions require their own evidence. Historical schema-60 preparation needs reviewed repair; schema 59 opens with Interactions off. The explicit schema-58 clearance upgrade remains: preserve originals and save upgraded copies. Retired model-owning Paint sets and stroke-history policies remain unsupported. Inspect ownership before adapting old fixtures. Source-container membership, saved per-source settings and placements are distinct; moving a model out of a palette must not silently delete its settings. Distinguish requested, accepted, shown and output counts.

Scatter Modify and selected-container Modify are views of shared records. Test owner switching and callbacks that create/remove/rebind views. A callback must not continue through stale rollout/controller references after a nested refresh. Do not use broad exception swallowing, forced refresh loops or Undo-history clearing to conceal a defect.

Prefer a causal fix over a stylistic rewrite. No repository-wide formatter/linter configuration was found during setup; follow the surrounding source and avoid unrelated reformatting. Preserve class IDs/internal registration names even when public labels change. The unpublished unified system deliberately retired older development policies; do not reintroduce compatibility by habit.

## 3. Generate and test at the right level

The user's current testing rule is **Max 2027 only**, including SDK builds,
native tests, host automation, Computer Use and performance qualification. Max
2026 work requires a new explicit user request. This supersedes older dual-version
requirements in plans and historical campaigns. Preserve their original results;
label new qualification with the actual Max 2027 environment. The explicitly requested [0.86.9 compatibility delivery](plans/edit-instances/DELIVERY_0869.md) has distinct matched Max 2024/2026/2027 SDK/native/managed payloads, focused host checks and one EXE with Surface Analyzer 0.14.2. Earlier compatibility deliveries retain their own scope and receipts. This exception does not extend ordinary development to other hosts; further older-host work still requires the user's explicit scope.

All paths below are relative to the repository root. Node, Python and the documented native toolchain must be available. The existing MCP test environment is local/ignored; consult [MCP setup](../CyrusMCP/README.md) if absent, rather than assuming a clean checkout includes it.

For authoritative MAXScript/UI edits:

```powershell
Push-Location AminScatter
try {
    node tools/ui/generate.cjs
    node tools/ui/generate.cjs --check
    node tools/ui/approved-layout.test.cjs
} finally { Pop-Location }
```

Inspect generated changes, semantic inventory, tooltips and manifests together. Presentation order must not change semantic MCP identities. The capability matrix is hash-pinned into the catalog: changing it requires deliberate catalog regeneration and matching checks, not a documentation-only edit. Generation/delimiter checks are not MAXScript compilation. The current integration checker also pins baseline/version/display assumptions; if intentionally changing those contracts, review and update assertions with new evidence rather than disabling failures blindly.

Use unused output directories (replace `agent-review` with a unique run name):

```powershell
python tools/procedural_lab/check_generated.py --output build/agent-review/generated
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/agent-review/scatter
python tools/procedural_lab/offline_build.py --project analyzer --year 2027 --output build/agent-review/analyzer
```

Focused examples: append `-k 'diagnostic'` to the pytest command; after a successful Scatter build, run `ctest --test-dir build/agent-review/scatter -R '^scatter_procedural$' --output-on-failure`. The offline builder currently expects MSVC 14.38.33130 and Windows SDK 10.0.19041.0 through the installed VS 2022 Community path. It does not launch Max or install files. Check prerequisites and [build guidance](Max_2027_Installation.md) before SDK work; `tools/build_max.py` also packages, so it is not a read-only check.

Choose meaningful regressions for the changed contract. Publication/restore changes need failure retention, relevant Undo/Redo and save/reopen checks. Scheduling changes need idle, relevant edits, unrelated edits/animation and Manual/Live contrasts. Broaden testing when shared paths or failures justify it; passing counts alone do not establish scenario coverage.

For interactive tools, invoke the actual generated button handler and run subsequent timer/status callbacks. A successful direct native Begin/Stop call does not qualify that workflow: 0.78.0 passed native painting tests but its first status tick stopped the brush through an unbound MAXScript forward call. The [0.78.1 campaign](Brush_Start_0.78.1_2026-10-10/README.md) includes button, SDK callback and measured native bounds regressions in both Max years. Private diagnostic modules must remain outside all product packages.

## 4. Qualify the host and performance honestly

Use a fresh owned run under ignored `build/`, with copied scene assets where appropriate. Inspect the current fixture and launcher before use: [tools/v1 guidance](../tools/v1/README.md) contains historical campaigns whose version labels and assumptions are not current acceptance. Never run a reset-scene fixture in the artist's session. Preserve asset references and original scenes.

Record source commit plus dirty/untracked scope, script SHA/payload fingerprint, native hashes and loaded paths, Max/SDK version, scene/asset identity and settings. Frozen inputs must remain unchanged during a build/test. Restart a private host for a changed native module. A matching MZP hash proves provenance, not runtime correctness.

Serialize mutations in each Max process. After a request timeout, inspect completion/response state before issuing another request. Stop only verified owned process IDs; never terminate every `3dsmax.exe`. Keep private diagnostic transports out of product packages and the public MCP interface.

Measure calculation, preparation, uploads, drawing, memory and presentation separately. Cache reuse does not eliminate draw cost. Synchronous redraw duration is not presented FPS; total process memory is not VRAM. Compare equal geometry, shown subset, camera, renderer and settings; distinguish cold/warm runs and report frame-time distributions where available. Explicitly report metrics or host scenarios that could not be measured. Require CPU/dependency/bounds evidence before proposing GPU compute or larger abstractions.

For bulk native migrations, also count script/native materialization, unique live buffers, old/new publication overlap and Undo/Redo retention/release. Confirm zero unnecessary solves/uploads on warm idle, panel browsing and unrelated animation. For future stateful work, test seek/replay, checkpoints, cancelled/stale publication and scene reset separately. Do not infer those lifetimes from the existing synchronous executor.

## 5. Keep automation and learning boundaries explicit

Preserve MCP enrollment, closed schemas, units, ownership, exact local approval, freshness, bounded work, main-thread dispatch, journaling and rollback. A catalog entry does not imply a supported mutation. Cached inspection must not secretly solve or render.

Local Scatter recording, sharing with an assistant and permission to use data for training are separate choices. Never include connection credentials, license secrets or unapproved artist assets in reports. Keep diagnostics bounded and off by default. The small offline ranker is experimental, not a production reference-image or artist-trained system. Licensing is an independent workstream; do not silently enable enforcement during unrelated changes.

For uncertain APIs, use official Autodesk/renderer SDK documentation or primary sources. In comparative R&D, separate publicly documented behavior, directly observed binary evidence and inference. Another plugin's responsiveness does not prove its private scheduling algorithm or justify copying unverified internals.

## 6. Close one evidence-backed loop

Update the maintained guides/backlog in place. Add a dated report only for new reproducible test or delivery evidence, with identity, reproduction, change, commands/results and unmet gates. Preserve old receipts; never relabel an earlier runtime pass as qualification of new source. Update current navigation and artist wording when behavior changes. When website documentation is within the requested scope, inspect its import mapping, import the intended chapters and verify:

```powershell
Push-Location website
try {
    npm run docs:sync
    npm run docs:check
    npm run build
} finally { Pop-Location }
```

Use the canonical React application under `website/`. The selected landing reference is `Landing Page Design/cyrus-scatter-site/`; the selected documentation design is `Landing Page Design/Design 1/`. Those packages retain historical content and are not alternate current guides. Preserve their source files while adapting their presentation to the maintained product facts. Visually test changed website interactions and reference fidelity; static link checks do not qualify layout. Concept images and teaching diagrams are not plugin renders. Keep volatile test counts and exact hashes in dated reports, not permanent agent instructions.

When subagents are authorized, delegate independent source/docs audits or disjoint files with explicit ownership and expected evidence. Keep edits to shared generated outputs and mutations of a single Max session serialized. Integrate findings and verify the final tree; agent confidence is not evidence.

Before an authorized Git backup, inspect the full diff/untracked scope and exclude credentials, SDKs, binaries and artist assets. Existing history uses descriptive checkpoint/fix messages; no rigid prefix is required. Run `git diff --check`, report what was included and any ignored artifacts requiring separate backup. A request for review or documentation alone does not authorize installation, publishing or pushing.

End with the concrete result, actual tests and limits, remaining priority and updated handoff. Stop when the agreed acceptance is met; do not turn a bounded task into an indefinite optimization loop.

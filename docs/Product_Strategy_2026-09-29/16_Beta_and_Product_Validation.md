# 16 — Beta and product validation

## Prove value through completed work

The product question is whether an artist finishes a real task faster, keeps control during revisions, and trusts the handoff. A long feature list or an impressive developer demo does not answer that question.

Use a small controlled cohort before a public launch. Proposed starting mix: several freelancers and environment artists plus two studios with a technical contact. Recruitment, outreach and any messages require the owner's authorization; this review contacted nobody.

## Pilot sequence

### Session 1 — First use

Provide the installer, one-page guide and a simple owned-asset scene. Observe installation, first scatter, a density/count change, preview-mode switch and saved-scene reopen. Record where the tester hesitates, misinterprets a control or needs help.

Proposed threshold: at least four of five new testers complete a simple scatter in ten minutes without developer intervention. This is a usability gate for a small cohort, not a market statistic.

### Session 2 — Real revision

Run one flagship task from [03](03_Product_Positioning_and_Workflows.md): change a planter/road boundary, adjust a layer and preserve intentional edits. Ask the artist to use their normal workflow as a comparison if feasible. Match assets, final constraints and renderer.

Record total task time, manual corrective actions, failure/recovery time, quality concerns and the operation that felt slowest. Compare the full revision, not only the best kernel timing.

### Session 3 — Handoff

Give the scene to another artist or worker using the declared configuration. Check assets, build identity, edit state, image result, render preparation and rollback. A studio's technical contact should be able to diagnose a prepared missing-asset or wrong-version case from the report.

### Follow-up — Independent repeated use

Ask which workflow they used without help, what stopped them, and whether they would choose Cyrus on another paid task. Proposed continuation gate: at least three pilots independently reuse a flagship workflow and can identify a concrete benefit. Positive comments without repeated use are insufficient.

## Product scorecard

| Metric | Definition | Use |
|---|---|---|
| First-task completion | Completed target task / attempted task | Discoverability and onboarding |
| Revision time | Input request to correct accepted result | Core value proposition |
| Recovery time | Failure to restored usable state | Reliability/support burden |
| Correct handoff rate | Matching output on second environment / attempted handoffs | Studio readiness |
| Repeat use | Independent second task within agreed pilot window | Practical adoption signal |
| Support minutes | Hands-on support per tester/task | Sustainability and documentation gaps |
| Confirmed severe defects | Reproducible critical/high cases by workflow/build | Release gate |
| Performance satisfaction | Reported slow step tied to measured operation | Prioritization, not a substitute for timings |

Keep collection local or explicitly consented. Scene content, file names and asset paths are not routine telemetry. Use anonymous aggregate summaries when possible; separate bug-reproduction files from commercial analytics.

## Feedback triage

Classify each request: correctness, discoverability, missing workflow, scale limit, integration or preference. Ask for the task and desired result before designing the control. Several requests may have the same underlying cause, such as unclear count semantics or invalidation.

Prioritize severity × repeated impact × target-workflow relevance, then consider implementation/support cost. Avoid mathematical scoring that disguises uncertain inputs as precision. Preserve a small backlog of deferred ideas with reopening conditions.

## Commercial readiness

Before pricing, estimate direct support, renderer/host qualification, release maintenance and licensing operations. Use real pilot behavior to understand what customers value. Do not copy a competitor's price or infer willingness to pay from praise.

A limited paid release should clearly state qualified hosts/renderers, tested workload envelopes, activation/offline terms, maintenance entitlement, support response expectations and known limitations. Keep older eligible installers available and document rollback.

## Demo and learning plan

Produce three short demonstrations corresponding to W1–W3. Show a starting scene, visible settings, a revision, an explanation of constraints and a successful render/handoff. Use the same recipe in documentation and regression fixtures so examples stay reproducible.

Publish honest before/after timing only with matched workloads and named configurations. Explain the difference between display limits and final population. Give artists a fast path to a useful result and a deeper path to understand it.

## Expansion decision

Expand when repeated successful use and manageable support justify it. If artists struggle to finish the initial workflow, invest in errors, defaults, examples or reliability before adding a new backend. If the workflow is reliable but not valuable enough to adopt, refine positioning and task scope before increasing breadth.

# Stage 12 — Beta readiness

## Goal

Decide whether a narrowly scoped build is safe and useful enough for a controlled external test, then collect actionable feedback.

## Why this matters

A beta exposes installation, recovery and handoff problems that a developer's successful session may miss. It needs a working core task, clear limits and someone responsible when a tester gets stuck.

## What we currently know

- **VERIFIED BY TEST:** retained native tests and a narrow Max 2027.1 batch smoke are recorded in [the evidence ledger](../Product_Strategy_2026-09-29/02_Current_System_and_Evidence.md). This is not an external-beta qualification.
- **VERIFIED IN SOURCE:** Scatter uninstall exists; a dedicated Analyzer uninstaller is absent. Automatic render transport exists but its ownership/cleanup risk needs investigation.
- **REQUIRES MANUAL 3DS MAX TEST:** interactive installation, editing persistence, actual render/IR, rollback and realistic scenes.
- **PROPOSED:** use the [governing pilot sequence](../Product_Strategy_2026-09-29/16_Beta_and_Product_Validation.md), the Stage 07 matrix and a small cohort. No testers have been contacted in this task.

## My tasks

- [ ] Choose a beta type and exact scope with the owner.
- [ ] Assemble the test kit only from qualified builds/scenes.
- [ ] Perform a first-use rehearsal and recovery exercise.
- [ ] Confirm tester authorization, asset rights and feedback permissions.
- [ ] Observe, record and triage rather than defending confusing behavior.
- [ ] Summarize whether another beta round is justified.

## Engineering / Codex tasks

- Close severe issues affecting beta workflows; provide reproduction/fix evidence.
- Verify clean install, upgrade/removal and restore for both included products.
- Qualify core scatter, saved edits, render and advertised support rows.
- Provide build identity, known issues, redacted diagnostic instructions and recovery steps.
- For licensing beta: implement/test activation, deactivation, expiry, outage and recovery first.
- Keep rollback installers/scenes and investigate crash reports.

## Boss / Product-owner decisions

Approve beta type, distribution scope, participant terms, support owner, success criteria and invitations. A **feature beta without licensing** needs explicit permission and disclosure that licensing is absent. A **licensing beta** needs the implemented, tested entitlement and recovery path. This task authorizes neither outreach nor distribution.

## Step-by-step procedure

1. Select **feature beta** or **licensing beta**. Do not call a feature beta an activation/trial test.
2. Declare exact Max update, renderer build, OS, workflows, hardware envelope and known exclusions. Use [Stage 07](07_Product_Support_Matrix.md).
3. Complete the applicable readiness gates below.
4. Assemble installer/checksum, quick start, S01 plus one lead scene, support contact, known issues and recovery instructions.
5. Rehearse on a disposable user profile/machine; include save/reopen and a failed-input/recovery case.
6. After owner approval, recruit a small cohort and distribute the controlled build using agreed channels.
7. Observe first use, one real revision and one handoff. Use Stage 02 IDs where useful.
8. Collect independent repeat-use feedback over an agreed pilot window.
9. Triage, fix and retest concrete failures; publish a revised scope/build record before another round.

### Readiness gates

| Gate | Required proof | Feature beta | Licensing beta |
|---|---|---|---|
| Installer and build identity | Clean install on exact scope, dependencies, hashes and version shown clearly | Required | Required |
| Uninstall / rollback | Rehearsed restoration; include Analyzer removal if bundled | Required; absence of a dedicated Analyzer uninstaller needs a tested engineering procedure | Required |
| Basic scatter | New artist can complete S01 with correct count/source/surface behavior | Required | Required |
| Save/reopen and CS Edit | Correct persistence on applicable unedited/edited scenes; invalidation explained | Required for advertised editing | Required |
| Render / cleanup | Actual final job and cancellation; no unrelated-node deletion or restoration failure | Required if render is offered | Required |
| Activation and deactivation | Restart/capacity/transfer outcomes match policy | Explicitly NOT APPLICABLE when licensing absent | Required |
| Expiry, offline, outage and recovery | Tested approved outcomes, reachable recovery and support runbook | Explicitly NOT APPLICABLE when licensing absent | Required for promised policy |
| Crash / failure handling | Save-copy discipline, readable failure, logs and recovery; investigate severe reproducible crashes | Required | Required |
| Diagnostics | Version, host/renderer, operation, counts and reproduction recorded without keys or unnecessary scene data | Required; manual collection is acceptable initially | Required, including redacted licensing state |
| Known limitations | Visible support matrix and issue list match the distributed build | Required | Required |
| Contact and response ownership | A real monitored channel and named responder | Required | Required |
| Test scenes / rights | Owned or confirmed licensed assets, expected results, no broken dependencies | Required | Required |
| Feedback process | One issue template, severity/owner, review cadence and tester response | Required | Required |

Suspected scene-loss/unrelated-deletion risks in the offered workflow require investigation before external testing. An unresolved severe failure cannot be accepted merely because it has not happened on the developer's scene. Narrow scope only when the risky path can be demonstrably excluded.

### Proposed small cohort

Start with **five to seven individual testers**, including two freelancers/archviz artists, a landscape/environment user, a heavy-scene user and contacts at one or two studios. Roles may overlap. The owner confirms access, actual host/renderer coverage and consent; this is a recruitment plan.

### Proposed beta outcomes

- At least four of the first five new users complete S01 in ten minutes without developer intervention.
- Every offered core workflow has a recorded result on its declared scope.
- Saved-scene and render handoffs reproduce the intended result.
- No unresolved critical scene corruption, unrelated deletion or licensing-induced render break.
- At least three testers independently reuse a lead workflow in the agreed window and describe a concrete benefit.
- Support time and recovery burden are recorded and judged manageable by the owner.

These are small-cohort decision gates, not proof of a market-wide success rate. Pause distribution when a severe issue emerges; preserve the failing copy, notify through approved support channels and use the tested rollback plan.

### Feedback card

~~~text
Tester alias / consent scope:
Build hash, Max update, renderer build, OS:
Scene ID and asset-rights record:
Task / expected result:
Actual result: WORKS / PARTIAL / BROKEN / NOT TESTED / NOT APPLICABLE / UNCLEAR
Steps / minimum reproduction:
Screenshot/log/video/scene location:
Severity and affected users/workflows:
Time spent / support minutes / recovery:
Issue owner and next action:
Retest build and outcome:
~~~

## Evidence to collect

Signed-off scope, test-kit manifest, install/remove/restore results, crash/failure reproductions, redacted logs, session notes, task times, repeat-use reports and beta decision. Collect scenes only with permission; routine feedback should not include private asset paths or credentials.

## Status table

| Item | Status | Notes |
|---|---|---|
| Beta type/scope approved | NOT TESTED | Owner decision |
| Product/install/render gates | NOT TESTED | Runtime qualification required |
| Licensing gates | NOT TESTED | Feature beta may mark N/A with explicit reason |
| Test kit/contact/feedback ready | NOT TESTED | No external distribution yet |
| Pilot outcomes recorded | NOT TESTED | Proposed criteria only |

## Completion criteria

A written beta go/no-go identifies the exact build, scope, evidence, limitations, recovery/contact owner and beta type. After the pilot, record outcomes and a continue/fix/pause decision. Passing a feature beta does not complete licensing readiness.

## Do not do yet

Do not run an open public beta, invite testers without authorization, advertise unqualified hosts/renderers, sell early access or use private production scenes as uncontrolled test fixtures.

## Optional / later

Larger cohort, localization, automated telemetry with separate consent and additional renderer/host combinations.

## Next stage

[Stage 13 — Presentation asset production](13_Presentation_Asset_Production.md).


# Stage 10 — Licensing technical preparation

## Goal

Give engineering a reviewable implementation brief grounded in the existing operation boundaries. This stage prepares work; it does not implement licensing.

## Why this matters

A licensing check added at the wrong point could interrupt scene evaluation or rendering. Policy must protect new authoring while preserving the approved behavior of existing jobs.

## What we currently know

- **VERIFIED IN SOURCE:** host bridges, CS Edit mutations, generated controller, baking helper and PFlow render transport exist. No provider-neutral licensing authority is implemented.
- **PROPOSED:** the [governing licensing strategy](../Product_Strategy_2026-09-29/09_Licensing_and_Commercial_Strategy.md) requires faithful evaluation, operation-scoped decisions, a fake provider, and network work outside placement/viewport hot loops.
- **DOCUMENTED BUT NOT VERIFIED:** the [older native architecture](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/04_Native_Architecture_and_File_Layout.md), [API sketch](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/05_LicenseCore_API_and_Pseudocode.md) and [integration map](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/06_Exact_Code_Integration_Map.md) are design inputs, not current components.

## My tasks

- [ ] Supply the approved Stage 09 policy or identify unresolved rows.
- [ ] Explain each user-visible failure/recovery message in plain language.
- [ ] Review what stays possible when a trial, maintenance or connection expires.
- [ ] Ask engineering for milestone outputs and evidence, not just “licensing done.”
- [ ] Record what must wait for product qualification.

## Engineering / Codex tasks

- Reconcile the older integration map with the current source anchors below.
- Define release identity, operation intent and runtime context without changing scene/Class IDs.
- Prepare pure policy tests and a fake adapter before networking.
- Specify how both products and multiple Max sessions share/licence state intentionally.
- Define bounded refresh, signature verification, local-state handling, recovery and diagnostics.
- Validate existing-scene fidelity before and after future candidate enforcement.

## Boss / Product-owner decisions

Approve the capability table, render-worker rules, expiry/continuity behavior and scope of the licensing candidate. No provider selection or implementation approval is assumed here.

## Step-by-step procedure

### The implementation journey — proposed future work

| Step | Future engineering output | Your review action | Dependency/gate |
|---|---|---|---|
| 1. Finalize capability policy | One table for author/edit/analyze/bake/view/evaluate/render | Match it to Stage 09 decisions | Product scope and owner policy |
| 2. Finalize render/evaluation rules | Workstation/worker cases, saved-state fidelity, expiry boundary | Follow a saved-job example through each context | Manual renderer evidence and unresolved local-render decision |
| 3. Provider-neutral LicenseCore | Native capability authority using an immutable validated state | Confirm no provider SDK leaks into placement logic | Release identity, context and lifetime contract |
| 4. Fake provider | Deterministic activated/expired/offline/outage/revoked states | Review recovery messages in a standalone harness | No real accounts or secrets needed |
| 5. Policy tests | Decision tests and saved-scene behavior scenarios | Read PASS/FAIL by promised outcome | Must pass before native enforcement |
| 6. Native gates | Candidate build gates actual mutation boundaries | Repeat applicable Stage 02 tests with each entitlement state | Qualified core workflows; preserve evaluation |
| 7. Licensing UI | Activate/deactivate/status/recovery controls in generator inputs | Test discoverability, errors and accessible recovery | Native authority exists; UI is not authority |
| 8. Provider POC | Comparable adapters and observed contracts | Use Stage 11 experiments | Include offline/floating/worker feasibility before selection |
| 9. Provider selection | Evidence and current commercial terms | Owner approves selected scope and cost | Must-have experiments passed; no choice in this task |
| 10. Commerce integration | Authenticated provisioning, idempotency, reconciliation/recovery | Test payment-to-entitlement and refund examples | Approved offer and external arrangements |
| 11. Offline/floating validation | End-to-end product/deployment/recovery tests | Exercise disconnected machine and crashed-seat cases | Revalidate the selected adapter; do not defer feasibility until after purchase |
| 12. Signing/release | Signed artifacts, verified installer and rollback kit | Run Stage 16 checklist | Operational and product gates passed |

**Now:** finish policy drafts, source map, recovery examples and acceptance plans. **After product validation and a coding assignment:** build the harness and candidate integration. **Later:** vendor experiments, commerce and release operations. This documentation task creates none of those implementations.

### Current integration points — VERIFIED IN SOURCE; gates are PROPOSED

| Current file / operation | Role now | Future authorization preparation |
|---|---|---|
| [max_bridge.cpp](../../AminScatter/src/max_bridge.cpp): aminScatterAdvanced_cf, aminScatterTransforms_cf | Native placement entries consumed by the controller | Both paths must honor the same operation policy. Separate new authoring from faithful recomputation; do not blanket-deny every invocation |
| [AminScatterObject.ms](../../AminScatter/scripts/AminScatterObject.ms): generation around 11059–11148 | Converts population, rasterizes density, requests placement and applies rules/edits | Trace user changes versus load/render callbacks. Script checks help UX; exposed native entry points still need meaningful authority |
| [Analyzer bridge](../../CyrusSurfaceAnalyzer/src/bridge.cpp): cyrusAnalyzeSurface_cf | Native analysis entry used by runAnalysis | Distinguish new analysis authoring from saved-scene dependencies needed for approved evaluation/render |
| [cyrus_edit.cpp](../../AminScatter/src/cyrus_edit.cpp): CSEdit::Move/Rotate/Scale, CloneSelSubComponents, Notify/delete, reset | Native instance mutations and reset | Gate mutations coherently, including programmatic paths; keep saved edits and inspection evaluable |
| cyrus_edit.cpp: cyrusEditCommand_cf, cyrusEditTransform_cf | Script-facing commands, including mutation access | Test direct calls as well as UI gestures; selection/query operations should not accidentally acquire an authoring seat |
| [cyrus_edit_stack.inc](../../AminScatter/src/cyrus_edit_stack.inc), [storage](../../AminScatter/src/cyrus_edit_storage.inc) | Evaluates stored edits and restores saved state | Preserve historical state without authoring authorization; loader validation remains a separate correctness investigation |
| AminScatterObject.ms: bakeInstances | Creates geometry from evaluated transforms; no ordinary Bake creation control currently exposed | A separate script authorization check is bypassable. Decide a native operation contract before claiming an enforced bake permission |
| [pflow.ms](../../AminScatter/tools/ui/templates/pflow.ms): CyrusPFBuild, CyrusPFClear, CyrusPFTick | Render preparation, object cleanup/restoration and Corona timer behavior | Faithful render transport should not blindly acquire an authoring seat; prove cleanup and worker policy in actual jobs |
| [preview.cpp](../../AminScatter/src/preview.cpp), [geometry preview](../../AminScatter/src/geometry_preview.inc) | Cached viewport drawing | No network, provider SDK call or changing seat state in draw/face/point loops |
| [generator](../../AminScatter/tools/ui/generate.cjs) and stage/template inputs | Authoritative controller/UI generation | Future licensing UI changes belong in generator inputs; prove repeatability and package parity |
| [build_max.py](../../tools/build_max.py), both CMake files/installers | Versions, host builds, manifests and installation | Centralize immutable release identity; test one intended runtime identity with Scatter/Analyzer and duplicate installs |

The generation functions currently accept caller-supplied inputs. A new “evaluation” flag alone is not sufficient security. Engineering must define practical authority and fidelity guarantees, acknowledge that transforms/render geometry are locally accessible, and avoid promising an unbypassable boundary.

### Licensing brief you hand to engineering

~~~text
Approved policy decision IDs:
Qualified product build and host/renderer scope:
Capabilities by workstation / unlicensed workstation / worker:
Eligible-release identity and maintenance cutoff:
Faithful-evaluation contract and representative saved scenes:
Mutation boundaries and direct-call tests:
Operation lifetime / expiry / cancellation rule:
Local signed-state schema and recovery behavior:
Network timeout / refresh / user-notification behavior:
Device and floating state ownership across Max sessions:
Diagnostics fields and privacy exclusions:
Fake-provider states and acceptance tests:
Deferred provider/commerce/offline features:
Owner and engineering reviewers:
~~~

### Minimum policy scenarios

No license; valid trial; expired trial; eligible perpetual build with expired maintenance; ineligible new build; temporary outage; fully offline; all floating seats occupied; crash/restart; lost device; refresh during a transform; scene open/render on a clean worker; mixed Scatter/Analyzer installs; multiple Max processes; failed signature/oversized state; uninstall/reinstall.

Map each scenario to an approved outcome. Pass criteria must include scene output and recovery, not only an allow/deny result.

## Evidence to collect

Approved brief, native/source map, fake-state cases, immutable build identity proposal, recovery text and later test reports. Use [existing test strategy](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/23_Test_Strategy.md) for detailed design reference.

## Status table

| Item | Status | Notes |
|---|---|---|
| Source integration map | PARTIAL | Inspected source anchors supplied; candidate gates absent |
| Approved policy/render contract | NOT TESTED | Stage 09 decisions required |
| Implementation brief reviewed | NOT TESTED | Engineering and owner |
| Fake-provider/policy tests | NOT TESTED | Future implementation |
| Native/UI/provider/commerce work | NOT TESTED | Not performed in this task |

## Completion criteria

The preparation brief lists policy decisions, current operation boundaries, failure cases, test fixtures and delivery gates. Unresolved policy is identified explicitly. Completing this document stage does not mean LicenseCore or gates are built.

## Do not do yet

Do not add authorization calls, introduce a provider SDK, change saved-scene contracts, block loading/rendering, or connect payment provisioning.

## Optional / later

Stronger tamper resistance after concrete need, expanded portals and enterprise deployment automation.

## Next stage

[Stage 11 — Licensing provider evaluation](11_Licensing_Provider_Evaluation.md).


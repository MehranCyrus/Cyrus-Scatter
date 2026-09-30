# Stage 04 — Product problems and missing pieces

## Goal

Give engineering a short prioritized issue list with reproductions, and know what blocks beta or paid release.

## Why this matters

Potentially destructive behavior, confusing controls and missing proof require different actions. A source suspicion deserves a test; a marketing gap deserves evidence or narrower scope.

## What we currently know

Current source still matches the earlier strategy's reviewed product inputs. Its [C-01..C-10 findings](../Product_Strategy_2026-09-29/02_Current_System_and_Evidence.md) remain relevant. No newly reproduced user-scene failure is being claimed by this documentation task.

**Confirmed implementation gaps:** no commercial licensing system; no qualified customer demo kit; no dedicated Analyzer uninstaller in its MZP; baking code has no creation button in the generated UI; version metadata is fragmented. These are source/artifact observations, not invented crash reports.

## My tasks

- [ ] Copy BROKEN/PARTIAL/UNCLEAR MT results into issue cards.
- [ ] Reproduce each failure in the smallest scene you can.
- [ ] Preserve the last working scene and exact build identity.
- [ ] Explain the effect on your task, not only the control name.
- [ ] Agree one next engineering assignment and track its retest.

## Engineering / Codex tasks

- [ ] Reproduce source risks with disposable fixtures and fault injection where needed.
- [ ] Classify each as confirmed defect, intended limitation, or unresolved.
- [ ] Give confirmed fixes meaningful regression coverage and a dated candidate package.
- [ ] Qualify scene/render cleanup before changing algorithms or transport.
- [ ] Improve diagnostics and version identity through the governing Baseline and Trust milestone.

## Boss / Product-owner decisions

Approve first-beta scope and support commitments after qualification. Do not accept unresolved serious scene safety risk merely to fit a launch date. A feature can be deferred explicitly; its remaining absence must appear in support/claims.

## Step-by-step procedure

1. Classify the observation: confirmed bug, suspected bug, UX gap, missing evidence, unsupported workflow, or commercial gap.
2. Assign its effect and phase below. “Critical consequence” describes what could happen, not proof it happened.
3. For a suspected bug request a focused reproduction; preserve source semantics until the result is understood.
4. For a confirmed bug describe expected/actual behavior and affected builds.
5. For an unsupported workflow choose test access, explicit deferral, or a scope exclusion.
6. Retest the actual candidate; a code explanation alone does not close the issue.

## Critical before beta on the affected workflow

| ID | Type / evidence | Consequence / next action | Owner |
|---|---|---|---|
| P01 | Suspected scene-safety bug; PFlow computes ownership from all new scene nodes | Could include unrelated callback-created nodes in cleanup. Engineering sentinel + success/failure/abort tests; confirm explicit ownership | Engineering, you verify scene |
| P02 | Editing identity risk; base row IDs/signatures and layer slots observed | Wrong attachment or invalidation after base/layer changes. Test two edited layers, earlier-layer removal, copy/delete stacks, clone/merge and reopen | Engineering |
| P03 | Suspected density/projection bypass in basic/legacy state; predicate omission confirmed in source | Legacy fixture with zero map and projection disabled; advancedAxes defaults true so ordinary UI result is not presumed broken | Engineering |
| P04 | Failed preview clears previous cache; source confirmed | Lost useful display/error recovery. MT35 first; define freshness before proposing last-valid retention | You + engineering |
| P05 | Analyzer publication split across stages; source confirmed | Street Side failure can leave mixed generations. Inject failure in a disposable test process | Engineering |
| P06 | Edit Load has large per-field limits/incremental acceptance | Resource/corrupt-scene risk. Bounded aggregate, truncated/duplicate/nonfinite fixtures before release | Engineering |
| P07 | Current render/IR and edited save/reopen evidence incomplete | Wrong final image or scene lifecycle may go unnoticed. MT20–27/32–33 with exact renderer/build | You + engineering |

Beta completion requires each applicable serious risk to be reproduced/classified and resolved or the affected workflow explicitly excluded with a safe, usable scope. Do not label P01/P02 as confirmed scene loss without a reproducer.

## Important before paid launch

| ID | Gap | Required output |
|---|---|---|
| P08 | Max 2024/2025 ports, 2026 and renderer qualification | Exact matrix from Stage 07; advertised rows pass |
| P09 | Installer upgrade/removal/recovery incomplete | Clean-user install, tested Scatter/Analyzer removal, duplicate-registration check and rollback |
| P10 | Package/CMake/native/UI version labels differ | One release identity with loaded paths and schema versions separate |
| P11 | Licensing/evaluation/offline/perpetual rules unsettled | Stage 09 capability/continuity decisions and tested implementation |
| P12 | No comparative profile or real 32 GB envelope | Raw full-operation/memory data; limited workload claims |
| P13 | Bake command inaccessible in generated UI | Defined artist access or explicit supported-output scope, ownership/undo proof |
| P14 | Support/diagnostic export and commercial operations absent | Reproducible reports, recovery owner and tested delivery/payment procedures |

## Improvements and later work

| Improvement | Why / phase |
|---|---|
| Explain requested/emitted/displayed/render counts and underfill | Early UX; status from actual pipeline |
| Show dependencies, stale state and actionable source errors | Early UX and reliable diagnosis |
| Three useful recipes and one-page first scatter | Early beta adoption |
| Density map channel/resolution choices | Pilot-driven texture precision |
| Slope/altitude controls | Proposed workflow addition after legacy parity |
| Durable identity for reorder/brush/animation | Separate schema/migration milestone |
| CPU/threading/GPU/retained viewport/new transport | Choose from measured bottleneck and experiment gates |
| USD, large libraries, enterprise floating/on-premises | Later named customer need and support capacity |

A current source limit such as ten layers or planar Analyzer input is a limitation to describe. It becomes a bug only if the accepted product contract promises different behavior.

## Evidence to collect

~~~text
Issue ID / related feature and MT IDs:
Type: confirmed bug / suspected bug / UX gap / evidence gap / unsupported / commercial
Severity / required phase / affected declared scope:
Build + Max/renderer:
Smallest scene:
Steps:
Expected:
Actual:
Evidence paths:
Reproduces: always / intermittent / not yet
Engineering task / owner:
Retest result / date:
Decision: open / fixed and verified / intended limitation / deferred with scope / unresolved
~~~

## Status table

| Item | Status | Notes |
|---|---|---|
| MT failures converted to cards | NOT TESTED | — |
| P01–P07 applicable risks classified | NOT TESTED | — |
| Next scoped engineering assignment agreed | NOT TESTED | — |
| Retest evidence / deferred scope recorded | NOT TESTED | — |

## Completion criteria

Every important observation has a type, owner and next action; serious risks are not hidden by optimistic language. Stage 04's issue-list preparation may complete while fixes remain open. Stage 12 then evaluates whether the proposed beta scope is safe enough.

## Do not do yet

Do not silently fix unrelated production code, reset saved edits, overhaul UI, change Class IDs/schema, or optimize an unclassified correctness failure.

## Optional / later

Maintain a deferred list with reopening conditions. A generalized node editor, asset marketplace or AI feature does not address the current beta blockers.

## Next stage

[Stage 05 — Define the product](05_Define_the_Product.md).


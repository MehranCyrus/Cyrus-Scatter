# 07 — Agent execution and feedback loop

**Status: PROPOSED state machine and operating policy.**

## One complete prototype workflow

Artist: “Use this reference to create a natural tree/shrub layout on this surface using these source objects.”

Prerequisites: a qualified automation adapter, the five MCP tools, one enrolled static planar site, approved source cards and regions, a known camera, local approval/undo controls, resource budgets, structured diagnostics and a model adapter. No custom ML is required.

1. **Understand:** `scene.get_context` returns the selected site, dimensions, sources, protected areas and capabilities. The model reads the reference and brief.
2. **Resolve ambiguity:** if the planting regions, asset categories or image-to-site relation are unknown, explain them and request the minimum artist input. Do not invent a metric mapping.
3. **Plan:** propose a tree layer, shrub border and sparse low-vegetation layer using the permitted features.
4. **Validate:** `scatter.validate_plan` resolves IDs, units, limits and hard constraints, returning an exact change preview.
5. **Approve:** the local UI shows the affected regions, counts, sources, assumptions and allowed refinement range. The artist approves a specific plan/envelope.
6. **Create:** `scatter.apply_plan` submits one idempotent operation. `scatter.get_status` reports publication or failure.
7. **Observe:** `scene.capture_viewport` returns the explicit view at the expected generation/revision. Status supplies actual counts and warnings.
8. **Compare:** inspect geometry metrics first, then the reference's compositional intent. A screenshot is insufficient to prove hard validity.
9. **Adjust once:** if useful and within the approved envelope, produce a small complete replacement plan for the owned candidate, revalidate and apply. Keep the seed and unrelated settings fixed.
10. **Stop:** show the result and uncertainties. The artist accepts, rejects the refinement through the local host control, or continues manually.

~~~mermaid
flowchart TD
  U["Understand brief and bounded scene context"] --> A{"Ambiguous required facts?"}
  A -->|Yes| Q["Artist clarifies or confirms regions"]
  Q --> P["Create typed plan"]
  A -->|No| P
  P --> V["Local validation and change preview"]
  V -->|Invalid| R{"Repair fits remaining budget?"}
  R -->|Yes| P
  R -->|No| STOP["Stop with explanation"]
  V -->|Valid| H["Artist approval or existing bounded authority"]
  H --> X["Apply one owned candidate"]
  X --> S["Query terminal status"]
  S -->|Failure or conflict| STOP
  S -->|Published| O["Capture matching viewport and metrics"]
  O --> C["Compare hard validity and composition"]
  C --> D{"One useful permitted refinement remains?"}
  D -->|Yes| P
  D -->|No| STOP
  STOP --> F["Artist accepts, rejects or edits manually"]
~~~

## Budgets

**PROPOSED pilot limits:** 24 tool calls including polls; two applied candidates; three reasoning responses; two captures; four minutes total soft session deadline. The local UI can extend a budget deliberately; model text cannot extend it.

Limit polling to five status reads per candidate with backoff. Exhaustion yields a visible “still running/outcome pending” state, not a duplicate apply. Completion may later appear in the local UI. Before applying a second candidate, reserve capacity to query its outcome and capture it.

Host operations have a proposed 30-second soft deadline and bounded admission checks. Existing synchronous engine calls may not be interruptible midway; report `cancel_requested` while waiting for a safe boundary. Do not promise a hard interruption latency until cooperative cancellation is implemented and tested.

## Approval modes

**Assist — MVP default:** interpretation and plan are visible. Each mutation needs a matching artist approval, or an explicitly approved one-refinement envelope. Ordinary repeat reads within the selected scope do not ask again.

**Bounded automatic refinement — later:** an artist approves a region, allowed fields, maximum count/delta, cost and iteration limits in advance. Within that envelope the assistant can iterate; exceeding it stops for review.

**Autonomous — FUTURE / OPTIONAL:** only if all safety and value gates pass. It must still operate on explicitly authorized objects and budgets. No mode may override manual locks or studio export policy.

Approval for local edits and approval for cloud upload are different permissions.

## What not to guess

Ask for clarification when a missing fact changes authority or geometry: which site, scale ambiguity, asset identity, protected space, interpretation of “left,” whether an existing edit may change, or whether project images may be uploaded.

For soft choices, propose visible defaults: mild scale/yaw variation or a conservative count. State the assumption in the plan, allow the artist to change it, and validate its consequences. Do not interrupt for every minor parameter.

## Comparison and stopping

Stop when any of these applies:

- Artist accepts or takes over.
- Two candidate applications or the tool/time/cost budget is reached.
- Hard geometry checks fail and no supported repair remains.
- The scene changes externally or manual edits invalidate ownership/generation.
- Reference, source or camera information is insufficient.
- The proposed second candidate repeats a prior plan digest or reverses the same parameter without new evidence.
- The critique cannot name a concrete improvement and measurable affected goal.
- Cost rises without improvement against the best valid candidate.

Keep both plan/metric summaries for comparison. The first candidate's reversible state is retained locally under a bounded policy. If the second is aesthetically worse, the artist's Reject Refinement action restores the first only after checking for intervening edits. The first five model tools do not include a hidden rollback operation.

## Preserve artist work

MVP mutation targets a newly owned controller. Existing edited layouts, manual hero objects and locked regions are read-only. Any artist edit to the proposal pauses automatic refinement and invalidates the previous approval receipt.

A later partial-edit feature needs stable per-instance identity, a three-way comparison of baseline/AI/artist state, explicit conflict reporting and localized regeneration. It must preserve objects outside the approved zone even when source arrays or seeds change. This is not currently implemented.

## Failure behavior

| Failure | Required outcome |
| --- | --- |
| Model refusal, incomplete JSON or invalid plan | No mutation; explain and offer manual continuation |
| Provider timeout | Existing scene remains usable; no transaction held |
| Stale context | Re-read and revalidate; no blind replay |
| Host generation/preview error | Preserve last-valid published state or report recovery failure explicitly |
| Disconnect after apply | Query operation identity; if uncertain, reconcile rather than resend |
| Artist cancels during compute | Cancel at next supported safe boundary; show whether publication occurred |
| Rollback fails | Stop further mutations; preserve diagnostic evidence |
| Viewport capture is stale/unavailable | Do not critique it as the new layout |
| Budget exhausted | Stop; retain editable result and honest pending/failure status |

This workflow prioritizes a small, inspectable loop. “Repeat until good” is not a sufficient operating policy.


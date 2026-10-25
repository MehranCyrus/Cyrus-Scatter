# Task extension, geometry readiness and explicit design handoff

24 October 2026. M02 increment; the milestone and full M00–M13 goal remain open.
Builds on [selected-object onboarding](M02_SCENE_CONTEXT.md).

## Behavior

The artist can add selected context objects to the same read-only task, retaining
its opaque task/object IDs, brief and role bindings. New objects start unassigned.
The 32-reference cap includes missing slots, and extension does not reset the normal
read-call budget. No surrounding-scene scan or name-based rebinding occurs.

Explicit mesh measurements now distinguish:

- World-axis-aligned bounds of evaluated mesh vertices.
- Source-local bounds, local-Z extent and XY/XYZ radii from the pivot, removing the
  node transform while retaining object offsets. These match design enrollment's
  existing source geometry convention, rather than mistaking a prototype's scene
  position for its planting destination.
- Receiver eligibility under the existing static, upward, horizontal, convex,
  single-boundary/manifold contract. Area/polygon/elevation are returned only after
  that verification; an arbitrary world AABB is not called planting area.

Materials/textures, renderer/proxy dependencies and asset unit provenance remain
explicitly unchecked. This is geometry readiness, not M03 asset readiness. Bounded
copied input meshes remain temporary; measurements/geometry are not cached or sent
as arrays to the model. Native placement storage/evaluation is unchanged.

## Local authoring grant

**Enable design proposals…** shows concrete receiver/source/boundary/exclusion
references and policy, defaults to Cancel, and expires after five minutes. It is
local-only and absent from MCP dispatch. Role strings alone never grant authority.
Confirmation rechecks scope/epoch, task digest, metadata digest and a one-use review.
Cancellation, stale/expired reviews and unsupported inputs keep inspection intact.

The supported handoff requires one receiver, 1–3 static supported mesh prototypes,
and optional 0–3 boundaries/exclusions. These four execution roles require distinct
objects; preserve/context annotations can overlap. Missing bound inputs reject
until corrected. A role can be removed from a missing table reference without
silently binding a replacement.

If no boundary is assigned, the already-verified receiver polygon becomes a virtual
whole-surface region. Enrollment creates no spline or scene node. Exact approved
generation later creates the existing owned bounded masks. Explicit boundaries
and exclusions retain their qualified convex-spline admission and physical units.

Native enrollment and fingerprinting finish before publishing the new service
scope. Failure restores the host's earlier inspection registries. Successful
handoff retains the same task/refs/brief/roles, issues a new scene epoch/scope and
design input IDs, and maps those inputs to original task IDs. Viewport sharing stays
off. Every actual write still needs fresh validation and exact local approval.

Design-connected task bindings are locked; the brief remains editable. A brief edit
clears proposal/context approvals without changing native authored settings,
publication, native scene revision or the last own Undo witness. Static settings
are referenced through `cyrus://capabilities` in task design contexts rather than
duplicated alongside live task metadata. This is a payload choice, not a measured
end-to-end speed claim.

## Evidence

Run: `build/mcp-handoff-20261024-01`, owned Max **2027** PID **44816**, exact staged
Scatter **0.86.9.2** / Surface Analyzer **0.14.2** pair. The source SDK discovers
fourteen tools. No native payload or product version changes.

**413 offline tests pass in 37.77 s** (`offline.xml`). Sixteen new handoff cases
cover production coordinator authority, task/ref retention, stale/expired reviews,
one-use failure, missing-role correction, contradictory input roles, closed public
dispatch, preserved read budgets, input-registry restoration and source-local
geometry conventions. Earlier measurement tests also verify the new facts. Offline
stubs/extracted methods do not prove native behavior.

The real SDK/native campaign passes both whole-surface and explicit
boundary/exclusion workflows:
`host01/handoff-329aa21deef34cabbc9d3cdf86e70ec3.json`, artifact
`f97c66c8eb8d03ae1b39c9db8a0b73e06676ec22c684a0e5b97794d37cdcc12e`.

- Scope extension preserves original IDs/brief/roles without restoring the read
  budget. Native object state remains unchanged beyond the fixture's explicit
  preparation/selection. A Point helper assigned as a mesh source is rejected;
  correction and retry retain the task.
- Stale reviews reject and Cancel is the dialog default. Cancelling clears its
  review without enabling authoring. The tested grant uses actual native panel
  button/dialog methods with scripted local responses, not human consent.
- A rotated prototype with a 0.1-unit object offset reports local height **2 m** and
  XY pivot radius **0.4 m**. Its receiver verifies at **900 m²**. These are the
  declared node-local/world conventions, not botanical species measurements.
- Handoff itself preserves an initially clean native state: **9 nodes before and
  after**, same transforms, selection and Undo history, save-required false.
- The same task ID, brief, nonexclusive roles and references survive the new scope,
  creation, brief correction and refinement. New source/region IDs map to task
  objects; virtual whole-surface regions are explicitly marked. Binding controls
  are disabled in design stage, capture remains off, and a write without separate
  proposal approval is denied.
- Whole-surface creation/refinement publishes **149→188** accepted placements from
  candidate totals **160→200**. The explicit boundary/exclusion task publishes
  **116→152**. Native final-row verification runs through the existing evaluator;
  these counts are not exact-target/density or grass/flower asset qualification.
- Editing the brief preserves the earlier published-row digest and invalidates the
  previously approved proposal. A fresh context/approval then permits refinement.
- `brief-undo.json` separately verifies own Undo remains available after another
  brief edit and restores the exact earlier **116-row** publication, authored hash,
  generation/configuration and layer IDs. Successful Undo still revokes the scope
  and clears transient task memory under the existing M01 policy.

## Remaining acceptance

This is bounded synthetic API/SDK and scripted native-widget evidence. The earlier
M02 Windows test covers the task editor, not physical input/consent through this
new grant dialog. Broad artist workflows, relevant spatial discovery beyond local
selection, complex terrain/geometry, materials/library/proxy readiness, source
replacement, existing-setup adoption/manual conflicts and durable resume remain
open. Return-to-task behavior after Undo also needs M04/M09 work; the current clear
policy is not seamless task restoration. These partial witnesses do not close the
full operation matrix or M02/M03/M04/M05/M09/M12/M13 acceptance.

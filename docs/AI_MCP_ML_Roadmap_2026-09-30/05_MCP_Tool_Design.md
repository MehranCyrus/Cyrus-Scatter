# 05 — MCP tool design

**Status: PROPOSED contracts. These tool names are not installed commands.**

## First five tools

Prefer five bounded tools over a long chain of tiny mutation calls. A plan applies one coherent set of changes and gives validation/undo a clear boundary.

| Tool | Required inputs | Result and effects |
| --- | --- | --- |
| `scene.get_context` | Local `scope_id`; requested bounded detail profile | Context ID, epoch/revision, units, selected site, approved sources/zones, ownership, capabilities, current settings and freshness. Read-only; no implicit refresh |
| `scatter.validate_plan` | Context ID and complete typed plan | Validation ID, canonical plan digest, normalized plan, affected-object summary, hard/soft findings, estimated work, expiry. No scene mutation |
| `scatter.apply_plan` | Validation ID/digest, expected epoch/revision, idempotency key; locally supplied approval receipt | Operation ID and queued/running/terminal state; bounded mutation through the API |
| `scene.capture_viewport` | Context/scope, explicit viewport ID and required published revision/generation | Image artifact or permitted image payload, dimensions, camera, display mode, color settings and freshness. No render or arbitrary file export |
| `scatter.get_status` | Exactly one operation ID or owned controller ID, plus epoch | State, structured errors, requested/emitted/displayed counts, cap/stale flags, generation and bounded timing fields. Read-only |

The local scope is created when the artist selects/enrolls the surface, sources, regions and view. A model cannot enroll arbitrary scene objects by inventing IDs. Context can include the selected surface and source list, avoiding separate MVP tools for each read.

### Shared rules

- Version domain input/output contracts independently of MCP.
- Reject unknown fields and unsupported features; require finite bounded numbers and valid enum values.
- Return readable errors plus machine-readable codes, field paths and recovery actions.
- Separate transport errors, tool-domain errors and asynchronously failed operations.
- A tool annotation such as read-only is a hint for clients; enforce behavior inside the API.
- A model-visible plan is not an approval. The local client supplies the approval receipt after the artist reviews the plan/scope.
- Bound input bytes, collection counts, image sizes and output pages before allocation.
- Return resource IDs from an allowlisted local artifact store; do not accept model-controlled filesystem paths or URLs.
- `get_status` reports facts from the operation ledger/published state; it must not call the current side-effectful `allStatus`.
- Dry-run validation may evaluate approved geometry under a work budget, but must not modify parameters, selection, undo history, layout or preview state.

The official [MCP tool specification](https://modelcontextprotocol.io/specification/2026-07-28/server/tools) defines input/output schemas and structured results. The rules above are Cyrus-specific proposed safeguards.

## Validation receipt and approval

The normalized plan is canonicalized and hashed using a pinned algorithm. Validation binds:

`scope + context + scene epoch/revision + input fingerprints + capability version + plan digest + expiry`.

An approval receipt binds the same digest and permitted effects. It cannot be supplied or extended by the reasoning model. A bounded refinement envelope may allow one change to counts/scale/yaw on the new owned controller, within displayed limits. New assets, regions, exclusions, deletions, upload categories or larger budgets require renewed artist review.

Approval is checked again just before mutation. Do not trust validation performed against a stale context.

## Error taxonomy

| Code | Meaning | Allowed recovery |
| --- | --- | --- |
| `STALE_CONTEXT` | Relevant scene state changed | Refresh context and revalidate; no blind apply retry |
| `UNKNOWN_REFERENCE` | ID missing, expired or outside scope | Artist re-enrolls or model uses current approved IDs |
| `UNSUPPORTED_CAPABILITY` | Plan asks for an unqualified feature | Revise the plan; do not silently substitute |
| `INVALID_PLAN` | Invalid type/range/combination | Return precise field errors |
| `GEOMETRY_CONSTRAINT` | Final placement violates a hard rule | Reject candidate; revise within budget |
| `BUDGET_EXCEEDED` | Count, bytes, time admission or resource cap exceeded | Reduce scope/work |
| `HOST_BUSY` | Rendering, modal state, load/reset or another mutation | Bounded wait/retry only while context remains valid |
| `APPROVAL_REQUIRED` | Missing, expired or mismatched local authority | Artist review; model cannot approve itself |
| `IDEMPOTENCY_CONFLICT` | Same key, different request | New deliberate operation after reconciliation |
| `GENERATION_FAILED` | Engine/preview update did not publish a valid generation | Preserve last-valid state; report cause and recovery |
| `CANCELLED` | Work stopped before commit | Report no publication; retain recorded cleanup result |
| `OUTCOME_UNKNOWN` | Connection/process failure prevents certainty | Inspect operation/owned state; do not replay |
| `ROLLBACK_FAILED` | Recovery could not restore the expected state | Stop mutation; retain diagnostics and offer manual recovery |

A valid empty result is a success with zero emitted count and an explanation. A failed generation is not reported as a valid empty result.

## Later tool families and current entry points

These are candidate internal commands first. Expose only the subset whose tests and UX justify model access.

| Category | Candidate operations | Source basis / missing contract | Stage |
| --- | --- | --- | --- |
| Scene inspection | Selected surface, eligible geometry, units, bounds, Cyrus/Analyzer/layer inspection | Local allowlist; no full-scene asset dump | MVP subset, expanded later |
| Lifecycle | Create/remove scatter; add/remove/duplicate/rename/enable layer | `newLayer`/`removeLayer` and parameters; identity/ownership/undo needed | Create/configure MVP; destructive/duplicate later |
| Surface/source | Add/remove/replace, weights, scale, Z offset, forward axis | UI-local array maintenance must become domain logic | Approved simple sources MVP; lifecycle expansion later |
| Distribution | Count, density, seed, density texture, source assignment | `placements` and advanced bridge; UV/map and clump semantics | Count/seed/weights MVP; density/map later |
| Variation | Rotation, uniform/per-axis scale, movement, projection, normal alignment | Existing controller fields; unit/order tests | Uniform scale/yaw MVP; remainder later |
| Constraints | Include/exclude, collision, relax, edge rows, falloff, cross-layer overlap | Native algorithms and arrays; final postcondition tests | Simple existing regions MVP |
| Analyzer | Analyze; boundaries, paths, points and Street Side output | `runAnalysis`, generation coherence and eligibility | Read qualified cached metadata first; recompute later |
| CS Edit | Query/select/move/rotate/scale/clone/delete by stable ID | Internal IDs exist but visible-row script selection is unsafe | Deferred until ID/undo/save/reopen contract |
| Observation | Viewport, diagnostics, requested/emitted/displayed counts | New snapshot/status wrapper | MVP |
| Render preview | Start/abort named renderer preset, bounded output | PFlow lifecycle, proxy/material and renderer qualification | Deferred |
| Templates | Tree belt, shrub border, meadow, path planting, spatial clusters | Recipe compiled to the same plan schema | Retrieval phase |

Never expose `execute_maxscript`, unrestricted `set_property`, shell commands, arbitrary imports/downloads, raw PFlow script generation, native pointers, unbounded point dumps or model-selected save paths.

## High-level versus low-level design

A tree-belt recipe can compile into zones, sources, counts and constraints. Keep that compilation inspectable and versioned. Do not create dozens of opaque tools that hide different interpretations of “natural” or “dense.”

Low-level domain operations remain valuable inside the API for tests, presets and expert studio clients. For an AI client, a high-level validated plan reduces round trips, partial states and schema choice errors. It also makes the proposed changes reviewable before any scene mutation.

## Initial budgets

**PROPOSED experiment policy, not current enforcement:** 24 total tool calls including polls; at most two applied candidates; at most three reasoning responses; three layers/sources; 2,000 total requested instances; 32 KiB plan; 64 KiB context/status response; two viewport captures, each at most 1,536 pixels on its long side and 2 MiB encoded.

Context enrollment caps evaluated site geometry at 100,000 triangles and approved source geometry at 100,000 triangles each for the pilot. Reject or request an artist-provided simplified asset if exceeded; do not silently decimate the production object. Numbers must be adjusted from measured pilot costs.

The initial mutation may create one controller plus at most three derived footprint-safe mask shapes. The normalized change preview and ownership ledger must list all of them. Source objects, site geometry and artist-authored regions stay outside mutation scope; replacement of derived masks is bounded and undoable.

Cancel/Undo/Reject remain local controls and are outside the model's tool-call budget.


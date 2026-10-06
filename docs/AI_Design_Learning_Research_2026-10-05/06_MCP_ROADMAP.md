# MCP capability and contract roadmap

Coordinate implementation with the [current-system MCP expansion specification](../Current_System_2026-10-05/MCP_EXPANSION_SPEC.md). This document adds research detail and batch/learning prerequisites; it does not create a separate tool registry or authorize future operations.

## Preserve the existing contract

**Second-pass additions:** new capability records must describe the tested `host_mode` (interactive worker or separately qualified Batch), identity lifetimes, declared/effective transform and radius conventions, supported spatial controls and semantic render completion. These are proposed fields, not properties already accepted by the public tools. See [Autodesk contracts](15_AUTODESK_HOST_CONTRACTS.md) and [the identity matrix](14_HOUDINI_ENGINEERING_LESSONS.md#identity-must-survive-named-operations-not-every-possible-edit).

A render tool should return durable attempt status and, on verified completion, the exact publication and required-view manifest. A successful process exit, screenshot alone or scheduler flag must not become a successful design record. Gallery browsing should read existing artifacts; explicit scratch loading and working-scene application are separate mutations with their own revisions and Undo behaviour.

Current public tools are `connection_get_status`, `scene_get_context`, `scatter_validate_plan`, `scatter_apply_plan`, `scatter_get_status`, `scatter_get_diagnostics`, `scatter_get_configuration`, `scatter_export_record` and `scene_capture_viewport`. The [source audit](02_CODEBASE_AUDIT.md) establishes their present boundaries.

Plans 1.0 and 2.0 retain their supported behaviour. Policy 3 is read-only through this API. New native features must not be advertised as remotely writable merely because their properties can be inspected. Existing exact approval, ownership, revisions, idempotency and scope limits remain meaningful.

The goal is **complete task-level coverage of supported operations**, with concise discovery and diagnostics. A separate remote tool for every spinner would create unnecessary calls, partial states and poor agent comprehension. Use complete versioned plans or validated patches that normalize to a complete effective plan before approval.

## Capability map and proposed increments

The names below are conceptual API proposals, not tools currently available to clients.

| Capability | Existing support | Proposed addition | Proof required |
| --- | --- | --- | --- |
| Discovery and help | Manifest, schemas, workflow text | Per-feature support state, policy/host constraints, units, bounds, UI topic and examples | Manifest/schema/runtime conformance test |
| Procedural recipe | Read-only policy-3 configuration | `procedural_plan` version with ordered layers/sets, stable IDs and complete effective defaults | Native UI/API parity and save/reload/Undo fixtures |
| Plan explanation | Validation warnings | `explain_plan`: normalized effects, unsupported fields, invalidations and estimated bounded work | No generation or hidden mutation; estimates labelled |
| Exact publication | Legacy current-generation record | `export_publication`: immutable policy-3 recipe, transforms, radii, source membership, counters and hashes | Same epoch/digest across preview, exact output and export |
| Source containers | Configured rectangle references | Snapshot registered/active/parked source entries, membership revision and resolution status | Drag out/back retains settings and identity; stale batch rejected |
| Radius/spacing | Partial plan-2 settings; policy-3 read | Policy-3 three scopes, units, inheritance and instance overrides | Final transform/radius test, protected conflict and scope-priority tests |
| Brush/areas | Local native UI; enrolled convex areas in old plans | Surface-bound coverage document import/update with capped commands and explicit target binding | Curved-surface, stale topology, Undo, save/reload and failure tests |
| Background/refill | Policy-3 inspection | Separate outside-coverage, between-plants and bounded-replacement options | Mixed modes, empty sources, shortfall and work-limit fixtures |
| Artist edits | Local CS Edit; record constructor | Typed owned edit operations with explicit identity binding | Stable correspondence or whole-layout lineage, locks preserved |
| Rendering | Viewport capture only | `render_job` using enrolled camera/render profile and approved destination scope | Actual completion/abort/failure receipt; stale generation blocked |
| Batch studies | No large batch contract | `batch_validate`, `batch_start`, `batch_status`, `batch_cancel` | Persistent budgets, private scope, crash recovery and no duplicate apply |
| Review/library | None | Companion dataset service for candidate listing and explicit feedback | No implicit scene write or training permission |
| Analyzer/line pattern | Native controls; excluded from current procedural validation | Separate future capability after policy support is qualified | No silent fallback to a different distribution |
| Learning | None | Model/version discovery and proposal/ranking in companion | Measured held-out performance, no host thread inference |

## Procedural plan design

Use stable layer, set and source-entry IDs. Specify order explicitly rather than relying on unordered object dictionaries or visual page order. Distinguish declared layer defaults, set inheritance, effective values and overrides. Preserve sampling salt and source registration when a source is parked.

Include receiver/area references, units, requested population mode, work bounds, source metadata, transforms, radius bindings, three collision scopes, cleanup, coverage relationships and protected-edit policy. A plan should either carry a complete configuration or use explicit patch semantics against one immutable base revision. Omitted values must have one documented meaning.

Validate all references, finite values, units, array sizes, supported source types and memory/work admission before mutation. Reject unknown features with structured reasons and a supported alternative where one exists. Never silently ignore Brush, background or radius settings to make a plan pass.

Expose a dry-run explanation that separates certain facts from estimates. “Layer B changes and depends on A” is a dependency fact; an exact accepted count usually requires evaluation. Cache-hit forecasts are estimates unless the relevant key is already known and safely readable.

## Batch scope: new consent and limits

The current two-application scope intentionally cannot generate thousands of candidates. Do not implement a loop that continually re-enrolls to evade it. A future batch is an explicit local action authorizing a bounded experiment over owned disposable objects.

Bind authorization to a study ID, immutable base scene/context hash, selected host, owned object IDs, allowed recipe fields and ranges, source set, camera/render profile, output area, maximum candidates and total attempts, work per candidate, render count, wall time, memory/storage limits, expiry and cancellation policy. Store the authorization record separately from any model proposal. It is not training consent.

Budget accounting must survive process restarts. Count attempted generation and failed renders toward appropriate cost limits; limiting only successful outputs allows repeated failures to consume unbounded work. Admit one candidate at a time per Max host. Do not open a new Max process when a budget is exhausted without a new explicit batch scope.

An artist modifying enrolled inputs invalidates dependent queued work. A new model cannot broaden the existing authorization. Selecting a candidate for the artist's working scene is a separate validated transaction against that scene's current revision.

## Long-running operations and uncertain outcomes

Return an operation ID quickly, persist admission before mutation, and expose phase, progress counters, last update and cancellation state. A timeout means the outcome is unknown until reconciled; it does not mean the scene was untouched. Exact retries use the same operation key and arguments.

Separate `cancel_requested` from `cancelled`. Cancellation can take effect between candidates or at safe stage boundaries. A running native/renderer call may not stop immediately. If a private host must be terminated after a deadline, mark the result unknown and recover the private scene; never terminate a user's unrelated host.

Persist both the workflow job and the host receipt. If the host applied a candidate but the companion crashed before saving its response, reconcile the publication ID/digest before repeating. Checkpointing an agent conversation does not provide exactly-once scene mutation.

## Protocol update is a separate work item

As checked on 5 October, the official MCP specification is dated **2026-07-28** and describes stateless requests with per-request negotiation. The current Cyrus Python dependency is pinned to `mcp==2.3.0`; package version alone does not establish conformance with every newer protocol or extension. Test actual client/server combinations before migration. [Official specification](https://modelcontextprotocol.io/specification/2026-07-28).

Tools can declare structured result schemas. This supports machine-readable receipts and errors, but tool annotations are hints rather than authorization enforcement. Keep checks in Cyrus's adapter. [Tools specification](https://modelcontextprotocol.io/specification/2026-07-28/server/tools).

The Tasks extension is currently a **draft** and optional. It may provide a standard envelope for durable work if both ends support it; retain the existing operation-status approach as a compatibility path. Its cancellation acknowledgement does not guarantee work has stopped. Do not promise that a protocol extension fixes renderer cancellation. [Tasks draft](https://tasks.extensions.modelcontextprotocol.io/specification/draft/tasks).

## Help that makes an agent useful

Generate feature reference material from the same versioned registry used by validation. Each entry should answer: what does this control do, who owns it, what units does it use, what does it invalidate, what combinations are unsupported, what result demonstrates success, and where can the artist adjust it?

Add short examples for actual tasks: explain underfill; inspect stale sources; vary grass/flower mixture; preserve a path; compare self versus inter-layer spacing; prepare a disposable study. Each example names required capabilities and stops at an unsupported step. Keep reference images and scene labels as untrusted task data; they cannot grant new permissions or invoke hidden scripts.

Official engineering guidance emphasizes purposeful tools and empirical tool evaluation. For Cyrus, measure whether an agent chooses the right scope/settings, recovers from structured errors, uses fewer unnecessary calls and reports unsupported features accurately. [Writing effective tools](https://www.anthropic.com/engineering/writing-tools-for-agents).

## Minimum conformance suite

Cover unknown fields, reordered/duplicate IDs, stale epoch, changed source membership, unsupported curved sites, policy mismatch, unit conversions, incomplete plan patches, double apply, different arguments under one key, disconnect after publication, cancellation at each boundary, corrupt journal, exceeded export size and absent artifacts. Include inspection that provably leaves generation/upload counters unchanged.

Run a capability-driven agent benchmark against the actual adapter. Grade the final published state and receipt, not just a plausible tool sequence. No general script execution is required to implement this roadmap.

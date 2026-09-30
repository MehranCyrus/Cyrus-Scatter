# 04 — MCP and automation architecture

**Status: PROPOSED. None of the layers introduced here is implemented by this documentation task.**

## API first

Create a provider-neutral domain API before the MCP adapter. This centralizes semantics, tests, permissions and transactions for AI, presets and studio automation.

~~~mermaid
flowchart TD
  UI["Artist UI: scope, approval, cancel, undo"] --> O["Local orchestrator / MCP client"]
  O <-->|"Approved text, summaries and images"| M["Optional reasoning provider"]
  O --> T["MCP adapter: schemas and transport"]
  T --> API["Cyrus Automation API: policy, IDs, validation, operation ledger"]
  API --> Q["Bounded host command queue"]
  Q --> H["Max main-thread adapter"]
  H --> S["Existing controller and native bridges"]
  S --> N["Cyrus procedural engine and previews"]
  H --> SNAP["Immutable context/result snapshot"]
  SNAP --> API
  API --> UI
~~~

The companion process performs network/inference work and hosts the client/server components as appropriate. The Max process receives typed commands through authenticated local IPC. The model never receives an arbitrary execution channel.

## Responsibilities

| Component | Owns | Must not own |
| --- | --- | --- |
| Orchestrator | Brief, budgets, model calls, plan/refinement state | Direct scene mutation or approval of its own authority |
| MCP adapter | Tool discovery, input/output shapes, transport errors | Cyrus parameter semantics or bypasses around API policy |
| Automation API | Capabilities, identities, ownership, preflight, idempotency, operation states | Provider prompts or model-specific assumptions |
| Max adapter | Main-thread evaluation/mutation, references, undo, viewport capture | Network waits inside a host operation |
| Native engine | Validated plain-data computation and procedural output | Cloud credentials, model inference or arbitrary external data parsing |
| Existing MAXScript | Controller behavior and generated UI through qualified wrappers | Exposed `execute` strings, unrestricted property writes |
| Artist UI | Scope selection, review, approval, cancel/reject/undo | Hidden training consent or silent authority expansion |

## Host threading and dispatch

**Primary-source fact:** Autodesk's [2027 threading guidance](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Python/files/MAXDEV_Python_threading_html.html) does not support `pymxs` calls from workers. Scene operations and viewport work must be marshaled to the supported main-thread path.

**PROPOSED implementation spike:** compare a small C++ queue adapter with a supported host-managed script/Python dispatch route. Prove execution context, idle/modal behavior, scene-load/reset handling and shutdown on the target host. Choose the mechanism from installed SDK documentation and tests. Do not repurpose a render-only job API as a universal dispatcher, or assume a timer creates background-safe Max access.

Network work can run elsewhere. Native compute may later run on owned plain-data snapshots under the separate performance plan. No worker retains `INode`, `Value`, Max bitmap or live parameter-block pointers.

## Identity and revision contract

Use:

- `scene_epoch`: unpredictable session identity replaced on open/new/reset and reconnection when identity cannot be proven.
- `scene_revision`: adapter-owned monotonic counter for relevant mutations, including undo/redo and external changes.
- `context_id`: immutable bounded snapshot at a particular epoch/revision.
- Opaque object/source/zone IDs: local registry handles, never object names or exposed memory addresses.
- `generation_id`: a published layout generation, required for point/edit references.
- `operation_id` and `idempotency_key`: identify one attempted mutation and safe retries.

These are proposed automation contracts, not the current plugin's `dirty` flags or global PFlow counters. Watch relevant node/parameter changes; recheck selected inputs/fingerprints immediately before commit. A missed event must not silently authorize stale edits.

MVP IDs are session-scoped. A Max node handle can help local lookup but is insufficient across reset/reopen/reuse. Layer array positions and current CS Edit visible-row indices are never durable IDs. Reject unsupported instanced controllers and ambiguous ownership. Durable scene IDs are a separate future migration decision.

## Mutation transaction

1. Resolve only enrolled, approved references on the main thread.
2. Check epoch/revision, capabilities, plan digest, approval receipt and work limits.
3. Normalize units/enums, resolve parallel arrays and compute a concrete change summary.
4. Capture the affected parameters/references and owned-object set; retain last-valid output under a bounded memory policy.
5. Start one short host undo transaction; coalesce affected refresh work.
6. Apply only the new owned controller or its authorized candidate replacement.
7. Generate and perform final geometric checks; publish a complete result and diagnostics together.
8. On failure, restore/undo the affected state and report both the primary failure and recovery outcome.
9. Restore redraw, callbacks/update policy and temporary state in a guaranteed cleanup path.

Do not use `cacheSnapshot` as a persistent checkpoint. It contains live/cache values and does not cover the full scene. Do not assume `undo on` alone supplies crash recovery or reverses every third-party callback.

**REQUIRES EXPERIMENT:** nested undo, source/layer-array restoration, exception after each mutation step, Max reset/load, selection changes, artist edits, callback-created sentinel objects and helper disconnect.

## Persisting geometric constraints

**PROPOSED MVP construction:** accept simple convex horizontal planting polygons whose relationship to protected regions is unambiguous. Compute an inward offset by the maximum approved source footprint radius after allowed scale, plus clearance. Reject an empty inset or an unsupported overlap with exclusions. More general concave/hole/terrain offset operations require a separately qualified geometry implementation.

Create at most one derived closed mask shape per layer, owned by the operation/controller, and bind it through the existing include-area parameters. Record its source-region fingerprint, offset rule and geometry in the normalized plan/result. The artist's original region remains unchanged. This makes later preview/regeneration use the same eligible-centre region; filtering an exported transform list alone would not persist the constraint.

Validate the final actual footprint against original planting/protected regions after all enabled transforms. If a count cannot be achieved, report requested/emitted count and the explicit plan's underfill policy; never add hidden retries or silently relax constraints. MVP forbids movement and uses conservative circular footprints. Include derived shapes in object budgets, undo, cleanup, save/reopen and ownership tests.

## Idempotency and interrupted operations

Bind a request digest to its idempotency key, scope, epoch and operation ID. Identical retries return the recorded result/status; a changed payload with the same key is an error. Deduplication is bounded by the lifetime and retention of the operation ledger.

A transport timeout means “outcome unknown,” not “nothing happened.” Query status before retrying. If the helper restarts and cannot prove the outcome, stop and reconcile owned scene state; never replay a possibly committed mutation automatically.

Only one mutation per controlled scene is admitted. Queued commands expire against their original revision. Cancellation before commit aborts; cancellation after commit reports the committed result and offers local undo. A transport cancellation is not proof of scene rollback.

## Recovery, local controls and manual work

The artist can Cancel, Reject or Undo without model cooperation. The prototype's five tools do not include a generic rollback tool. The local host UI owns safe reversal and checks that newer manual edits are not overwritten. If an artist has changed the candidate, stop automatic refinement and offer explicit conflict resolution.

Never hold an undo transaction open while waiting for model output or a user. Never force-kill Max as an operation timeout strategy. A guarded local scene checkpoint can be added after save/callback behavior is qualified; autosaving proprietary scenes to a new location is not an implicit side effect.

## MCP transport and versioning

**Primary-source facts, retrieved 2026-09-30:** the official [transport specification](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports) documents stdio and Streamable HTTP. The current `latest` pages resolved to revision **2026-07-28**, which differs from older connection-handshake examples. [Tool schemas and structured results](https://modelcontextprotocol.io/specification/2026-07-28/server/tools) are protocol features, not application validation.

**PROPOSED:** prefer client-launched stdio for the local prototype. Keep the Max IPC channel separate, using OS user/process restrictions and a per-session pairing secret. Pin a protocol revision and tested client/SDK versions during MCP-01; verify actual consumer support rather than assuming every client implements the newest revision.

A local orchestrator can call an approved cloud model over outbound HTTPS and invoke local tools itself. Cloud reasoning therefore does not require publishing the Max adapter on the internet. If a future integration requires a remote MCP endpoint, its hosting/authentication and studio data policy need a separate decision.

For HTTP deployments, evaluate current [Streamable HTTP requirements](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http) and [MCP security guidance](https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/security_best_practices). Transport security and tool annotations never replace local scene authorization.


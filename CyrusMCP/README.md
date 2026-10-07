# Cyrus Automation and MCP 0.73

Separate local MCP server and queued Max host adapter for **Scatter 0.73 / `CyrusUnified1`**. Package is **0.73.0**, closed authoring plan **0.73**, with twelve tools/seven resources. Retired plans 1.0/2.0 fail explicitly; they are not mapped silently to new semantics. [Current capabilities](../docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md), [AI workflow](../docs/Current_System_2026-10-05/AGENT_WORKFLOW_GUIDE.md), [0.73 results](../docs/Unified_System_0.73_2026-10-06/RESULTS.md) and [packages](../docs/Unified_System_0.73_2026-10-06/PACKAGE.md) define the current evidence.

The owned-plan subset now uses the sole ordered evaluator: bounded count/seed, asset weights/metadata, supported transforms/self/pair/cleanup and presentation settings. Full recipe, Brush/set-history, container, CS Edit/radius mutation, complex terrain, map enrollment, renderer execution and ML remain outside the public contract. Catalog help for a local control does not grant remote invocation.

## Install a matching offline package

Use the separately generated MCP folder under `dist/`; source alone is not an offline installer. The package contains pinned wheels/checksums, source host and installer. External runtime is **64-bit CPython 3.11**, MCP Python SDK **2.3.0**; Max uses its bundled Python.

```powershell
.\Install_Cyrus_MCP.ps1 -PythonExe 'C:\path\to\python.exe' -RegisterCodex
```

Registration is optional. The installer creates an isolated environment/build, verifies payloads and refuses an existing build/connection overwrite. It prints the exact `host/Start_Cyrus_Automation.ms` path. It does not copy DLLs/scripts into Max's startup/profile or modify scenes. The matching Scatter plugin must already be installed and Max restarted. This implementation campaign creates packages, not an installation into the artist profile or Codex configuration.

## Enroll, review and apply

1. Run the printed host startup script through **Scripting > Run Script** in Max 2027.
2. Choose a static horizontal convex site, one to three allowed mesh assets and straight closed convex planting splines. Add excluded/protected regions as needed.
3. Enable viewport sharing only if images should be available to the client; it can include other visible objects. Connect the selected design scope.
4. Read context/capabilities/schema, propose Plan 0.73 and validate. Inspect the normalized settings/counts/assets in Max and **Approve displayed proposal** locally.
5. Apply that exact digest once; query the operation and actual result. One separately approved refinement may replace only its owned layers/masks.
6. Cancel queued work, Undo/reject the next own result, disconnect or take over manually. Save/reopen preserves the result but requires fresh enrollment.

Select an existing Cyrus controller and use **Inspect selected Cyrus scatter (read-only)** for bounded cached inspection. This grants no authority to edit it. Current recipe can be pending while publication describes the previous complete epoch. Refresh manually if desired and re-enroll; readers do not solve/reconcile to answer a question.

Example: “Read the connected scope. Propose two layers using its assets/regions, 600 aggregate candidates and deterministic seeds. Validate and show source radius, self gap and layer-pair gap in metres. Wait for local approval; apply once and report actual emitted count/shortfall and matching publication.”

## Tools and resources

| Tool | Role |
| --- | --- |
| `connection_get_status` | Host/enrollment and loaded module identities |
| `scene_get_context` | Enrolled geometry, opaque IDs, units, revisions and budgets |
| `scatter_validate_plan` | Closed Plan 0.73 validation, normalization and review without mutation |
| `scatter_apply_plan` | Queue exact locally approved owned-plan operation |
| `scatter_get_status` | Operation/result state; timeout is not success |
| `scatter_get_diagnostics` | Cached errors/counts/build/retained metrics, no solver/FPS estimate |
| `scatter_get_configuration` | Current parameters and cached unified recipe/helper presentation |
| `scatter_get_publication` | Last complete manifest and bounded stale-checked paging handle |
| `scatter_read_publication_page` | Actual cached transforms/radii/IDs/protection/output flags |
| `scatter_export_record` | Current owned normalized plan/receipt and actual rows, not training consent |
| `scatter_read_diagnostic_events` | Exact locally shared bounded trace/session/sequence/health |
| `scene_capture_viewport` | Expressly shared viewport with generation/camera metadata |

Resources: `cyrus://plan-schema`, `cyrus://plan-schema/0.73`, `cyrus://capabilities`, `cyrus://workflow`, `cyrus://feature-catalog`, `cyrus://agent-workflows`, `cyrus://error-guide`. The generated catalog covers 34 capability families/240 semantic controls and includes current source/inventory hashes. Ordinary help is not a scene-write API. Read-only full recipe inspection and narrower owned-plan mutation are distinct.

## Bounds and supported semantics

At most three mesh sources, three regions/layers, **2,000 aggregate requested candidates**, two successful applications and two captures per enrollment. Plans cap 32 KiB; context 64 KiB; images 1,536-pixel long edge/2 MiB base64. There are 24 ordinary calls with defined outcome/idempotent-retry recovery exceptions. Publication pages cap 500 rows; five-minute handles expire when replaced; 2,048 attempts per enrollment include failed/stale attempts.

Design geometry is baked Editable Mesh/Poly or supported primitives, without modifier stacks, keyed/constraint/procedural controllers or renderer proxies. Site/assets cap 10,000 evaluated triangles/12,000 vertices. Read-only inspection may report cached existing inputs outside this design admission, without certifying them for automated generation.

Lengths are metres, rotations degrees, multiplicative scales unitless. Plan 0.73 normalizes the supported uniform/XYZ scale, yaw/XY tilt/projected movement, source scale/lift/radius/follow-scale, self rule, layer pairs, cleanup, enable/visibility and display/update subset. Layer order is explicit; old priority/blocker fields do not exist. Count is a candidate budget; each layer chooses underfill `allow` or `reject`. Missing/unsupported fields are errors, not silent fallback.

Existing artist objects remain read-only. The adapter creates its own controller and bounded masks and may refine only those objects. Relevant external edits revoke freshness. It keeps local exact-digest approval, ownership, scene revisions, idempotency, queued main-thread dispatch, journal and verified rollback. Rendering, playback, modal state and an active Undo transaction block admission.

## Diagnostics and recovery

**Scatter > Modify > Diagnostics** records without MCP. Defaults are off; recording caps 4,096 events/4 MiB/ten minutes. Container movement/ownership adds action summaries. No telemetry/cloud endpoint or inferred training labels are introduced. Automation's independent sharing checkbox grants reading of that exact process trace, including other controllers' recorded events; revoke it or change scope/session to remove permission. Recording does not imply sharing.

An unknown apply outcome requires query/reconciliation of the existing key; do not assume nothing happened or generate a new retry key. Incomplete journal entries after process loss become `outcome_unknown`; corrupt journal/failed rollback blocks further work. Own Undo checks the exact next label/fingerprint and does not undo unrelated artist actions. Synchronous admitted generation is bounded but not cancellable mid-native-call; completed work must be undone.

Default connection directory is `%USERPROFILE%\.cyrus-scatter\automation`; installed isolated builds live under `%USERPROFILE%\.cyrus-scatter\mcp`. The Windows-user-restricted directory contains credentials and a bounded 128-record journal. Never share `connection.json`. Multiple Max sessions require distinct directories/client configurations. Client command is the installed environment's Python with `-m cyrus_mcp.server` and optional `--connection-dir`.

Current-generation execution export caps exactly **1,500,000 bytes**. Cached publication rows/opaque input signatures are not a complete portable recipe/source-assets package. Operational records have training eligibility false. The separate offline Design Lab remains experimental with no Max render/training endpoint or reference-image model.

Max 2026 runtime, wider renderer/pointer/platform coverage and commercial licensing remain separate gates. Earlier 0.72 real IR evidence is dated; the new campaign's mocked lifecycle checks do not certify current real IR. [Next acceptance loops](../docs/Unified_System_0.73_2026-10-06/ROADMAP.md) precede broader tools or artistic search.

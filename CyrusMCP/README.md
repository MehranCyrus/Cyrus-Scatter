# Cyrus Automation and MCP 1.2 — source candidate

Local automation with a separate MCP server for a stdio MCP client. **Current Scatter source is 0.7.1; current MCP source is 1.2.0 with twelve tools and seven resources.** The source adds passive policy-3 publication pages, explicitly shared diagnostic-event pages and feature/workflow help. The [6 October runtime campaign](../docs/Live_Runtime_2026-10-06/README.md) qualifies a frozen Max 2027 slice through the actual panel, authenticated IPC and stdio interface, including locally approved schema-1/2 writes and save/reopen. Its idle dispatcher is event-driven. This is still an unpackaged source candidate; Max 2026 runtime and complete product qualification remain open. Plans 1.0/2.0 retain their bounded policy-1/2 behavior. Policy 3 remains read-only through MCP; complete reconstructable recipe/asset export is still unavailable.

The [earlier capability map](../docs/Layers_First_2026-10-03/CAPABILITIES.md) and [qualification report](../docs/Layers_First_2026-10-03/REPORT.md) record the MCP 1.1 expansion against the then-labelled Scatter 1.2/Max 2027.1 snapshot. The Max component uses its bundled Python; the external server uses an isolated **64-bit Python 3.11** environment and the pinned MCP Python SDK 2.3.0. Current source, installed packages and in-memory Max modules must be identified separately.

## Install the built package

Use the generated package under `dist/`, which includes the pinned wheels and checksums. The source directory alone is not an offline installer. From PowerShell in the package folder:

```powershell
.\Install_Cyrus_MCP.ps1 -PythonExe 'C:\path\to\python.exe' -RegisterCodex
```

`-RegisterCodex` adds `cyrus-scatter` to your local Codex MCP configuration after installation checks pass. Omit it for another client. The installer prints the exact Python and Max startup-script paths, records them in `installed.json`, and refuses to overwrite an existing build or existing Codex connection. It changes no Max startup folders, DLLs, existing scenes or existing Python environments. Administrative access is unnecessary.

The wheel package is offline after download. Python 3.11 and the Cyrus plugin must already be installed. License notices supplied by the dependency authors remain inside their wheels and installed `dist-info` directories.

## Use it

1. In **Max 2027**, choose **Scripting → Run Script** and run the printed `host/Start_Cyrus_Automation.ms`. The normal Cyrus plugin must already be loaded.
2. Select your site, then click **Use selected site**. Assign one to three source meshes and one to three closed, straight, convex planting splines. Optional protected splines remain excluded. The first version supports static horizontal convex sites.
3. Enable viewport sharing only if you want images available to the assistant. A capture includes other visible objects in that viewport; the MCP client controls whether it forwards images to its model provider.
4. Click **Connect selected scope**. Reconnect the MCP client after a qualified package upgrade to discover that package's tools. Existing packages do not acquire the new source tools automatically.
5. Ask for a proposal. Review its assets, regions, counts and variation in the Max panel. Click **Approve displayed proposal**. The assistant can then apply that exact proposal once and inspect its result.
6. One additional candidate may replace the owned layers after a new local approval. **Undo last result / reject refinement** restores the previous result when it is still the next Max Undo operation. **Disconnect scope and continue manually** leaves the procedural layout editable in Cyrus.

To inspect an existing layout instead, select one Cyrus controller and click **Inspect selected Cyrus scatter (read-only)**. This supports up to 32 layers and grants no authority to change that controller. Context/status report cached requested, generated and displayed counts; diagnostics also report retained Point Cloud/Mesh counters when a retained owner exists. A Manual preview can be older than its source geometry, and the response identifies that limitation. Refresh it manually and reconnect if you need a new inspection snapshot. Changing scope selections revokes the previous enrollment; unchecking image sharing takes effect immediately.

Example request to an assistant:

> Use the connected Cyrus scope. Read its context and propose two layers using the enrolled assets and regions, with 600 total requested plants, deterministic seeds, uniform scale 0.8–1.2 and random yaw. Validate first and show the proposed changes. Wait for my approval in Max, apply once, then report actual counts and capture the approved viewport if sharing is enabled. Do not refine automatically.

MCP clients do not need another OpenAI API key for this connection. The client supplies the reasoning model; the MCP server makes no model API calls and does not automatically train or collect a dataset. The optional [offline Design Lab CLI](../docs/Offline_Implementation_2026-10-05/DESIGN_LAB.md) records explicitly supplied candidates and reviews, and can fit a small experimental preference model; it has no Max/renderer connection or MCP endpoint.

## Tools

| MCP tool | Purpose |
| --- | --- |
| `connection_get_status` | Connection, Max version, loaded module file hashes and enrolled scope ID |
| `scene_get_context` | Approved geometry summaries, opaque IDs, units, revision and budgets |
| `scatter_validate_plan` | Strict schema, references, conservative footprint masks and change review |
| `scatter_apply_plan` | Queue a locally approved proposal, with revision and duplicate-request checks |
| `scatter_get_status` | Recorded operation or last published controller state |
| `scatter_get_diagnostics` | Cached preview counters, retained owner statistics and shared process totals; no regeneration or FPS estimate |
| `scene_capture_viewport` | Approved viewport image and matching generation/camera metadata |
| `scatter_get_configuration` | Current effective parent/set parameters and assets, without rebuilding |
| `scatter_export_record` | Matching current generation's context, normalized plan, receipt and actual transforms; not training consent |
| `scatter_read_diagnostic_events` | New source: 1–500 cached events from an exact locally shared process-wide trace; no recording/sharing control |
| `scatter_get_publication` | New source: last complete policy-3 publication manifest and a five-minute paging handle; no solve/reconciliation |
| `scatter_read_publication_page` | New source: actual transforms, effective radii, set/instance/source IDs and protection/output flags for that exact publication |

Resources: `cyrus://plan-schema` (legacy **1.0**), `cyrus://plan-schema/2.0`, `cyrus://capabilities`, `cyrus://workflow`, `cyrus://feature-catalog`, `cyrus://agent-workflows` and `cyrus://error-guide`. The catalog accounts for 34 capability families and 241 UI controls; listing a native control does not authorize remote invocation. The older research 0.1 JSON examples and new offline `3.0-draft1` compiler are not executable MCP apply requests. Read capabilities before proposing settings; no arbitrary Max property names are accepted.

## Supported boundary

Up to three source meshes, three planting regions/layers, 2,000 aggregate requested instances, two successful candidate applications and two captures per enrollment. Plans are capped at 32 KiB; context at 64 KiB; viewport images at a 1,536-pixel long edge and 2 MiB of base64 image data. There are 24 ordinary tool calls per scope; outcome queries and exact idempotent retries remain available for recovery. New publication paging has a separate 2,048-attempt read budget, at most 500 rows per call, with failed/stale host attempts counted. This does not enlarge mutation or render authority.

Both schemas support source weights, seeded count, uniform scale, yaw and footprint clearance. Schema 1.0 preserves legacy policy and requires protected regions to be disjoint. Schema 2.0 supports overlapping protected/excluded holes, XYZ scale, XY tilt/projected movement, source metadata, collision, pair spacing/priority, cleanup, visibility/enable and display/update settings. The adapter derives conservative masks and validates the final attached population. Counts can underfill; each layer explicitly chooses `allow` or `reject`.

Design inputs use baked Editable Mesh/Poly objects or supported simple primitives, with no modifier stack. The site and sources together are limited to 10,000 evaluated triangles and 12,000 vertices. Keyed geometry, keyed parent transforms, procedural/constraint controllers and renderer proxies are rejected. These restrictions apply to design enrollment; read-only inspection can report cached statistics from existing Cyrus layouts with other inputs. It does not certify those assets for automated generation.

Existing artist objects are read-only. The API creates one controller and bounded derived include/exclude masks, then may replace only its own layers/masks. Any relevant external edit invalidates enrollment. Save/reopen preserves the ordinary procedural result but requires fresh enrollment; the assistant does not silently reclaim old objects. Default preview is proxy boxes; schema 2.0 also selects Point Cloud, Mesh or centres with explicit budgets.

Complex/sloped terrain automation, Brush-set/history mutation, density-map enrollment, Relax, CS Edit, renderer execution, arbitrary scripting/files/URLs and ML remain outside the MCP contract. Records do not imply training consent or automatic artist labels. Current-generation legacy exports are in-memory, bounded to **1,500,000 bytes** and invalidated by scope/generation changes. New policy-3 pages copy actual cached rows/radii and compact metadata; their opaque input signature is not a reconstructable recipe. An expired/replaced publication requires a new manifest. Max 2026 runtime support is not claimed.

The new local Engineering diagnostics controls explicitly start, stop and save a recorder (default 4,096 events, 4 MiB, ten minutes). Recording does not grant MCP sharing. The separate checkbox shares that exact process-wide trace, including events for other scatter controllers, and is revoked when the scope/session changes. Reports distinguish eviction, lock contention, failures and truncation. Callback receipt timestamps are not presented FPS. Host qualification and the IR reproduction remain pending.

## Recovery and connection

The default connection directory is `%USERPROFILE%\.cyrus-scatter\automation`; installed builds live under `%USERPROFILE%\.cyrus-scatter\mcp`. Using the user profile avoids Windows Store application redirection of LocalAppData, so native Max and Codex see the same files. The connection directory is restricted to the Windows user and contains a session secret and a bounded 128-record operation journal. Never share `connection.json`. The journal is operational history, including layer labels and results, not a training dataset. There is no telemetry or cloud endpoint in the host/server.

Only one Max panel can own a connection directory. Separate Max sessions need distinct directories and separate client configurations. The client command is the printed environment's Python with `-m cyrus_mcp.server`; optionally append `--connection-dir <private-directory>`.

If the scene changes, re-enroll and revalidate. If a request times out, query its operation or retry **the exact same key and arguments**; never generate a new key automatically. A queued operation can be cancelled locally. Synchronous native generation is short and bounded in this scope but is not interruptible mid-call; a completed operation must be undone. Rendering, animation playback, modal dialogs and an active Undo transaction block admission.

After an interrupted host process, incomplete journal entries become `outcome_unknown`; inspect the scene before another action. A corrupt journal blocks startup rather than pretending the previous operation never happened. Preserve it for diagnosis. A failed rollback blocks further work in that enrollment. Local Undo checks both relevant scene fingerprints and the exact top Undo label, so it does not blindly undo an unrelated artist action.

Closing the panel disconnects IPC. Reopen the startup script to reconnect. For a code upgrade, close Max before switching the host package, because embedded Python caches imported modules. To remove the Codex registration, use `codex mcp remove cyrus-scatter`; keeping the host panel closed leaves ordinary Cyrus use unaffected.

## Development and qualification

Scatter 0.7's policy 3 is currently **read-only through MCP**. Configuration includes the ordered procedural recipe and last published diagnostics under `cyrus.procedural-configuration/1.0`, with lengths in metres. Schemas 1/2 continue to select policies 1/2 and cannot overwrite a policy-3 controller. Brush/order/rule mutation and ML remain unavailable through MCP. See the [0.7 implementation report](../docs/Procedural_Implementation_0.7_2026-10-04/IMPLEMENTATION.md) and [validation record](../docs/Procedural_Implementation_0.7_2026-10-04/VALIDATION.md). At that earlier recorded baseline, all nine existing live-host campaign programs and the policy-3 inspection fixture passed in isolated Max 2027. Current MCP 1.2 has separate [offline evidence](../docs/Offline_Implementation_2026-10-05/README.md) and [6 October runtime evidence](../docs/Live_Runtime_2026-10-06/RESULTS.md), including actual panel/stdio reads, consent, bounded writes, idle scheduling and save/reopen. Max 2026 runtime is not qualified.

```powershell
python -m venv build/mcp-venv
build/mcp-venv/Scripts/python.exe -m pip install -e CyrusMCP pytest==8.4.2
build/mcp-venv/Scripts/python.exe -m pip install -e "CyrusMCP[design-lab]"
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests -q
python tools/mcp/launch.py --run my-test
build/mcp-venv/Scripts/python.exe tools/mcp/qualify.py build/mcp-qualification/my-test --cycles 100
build/mcp-venv/Scripts/python.exe tools/mcp/scenarios.py build/mcp-qualification/my-test
build/mcp-venv/Scripts/python.exe tools/mcp/stdio_acceptance.py build/mcp-qualification/my-test
```

The launcher creates a separate visible Max session and redirects its configuration, plugins and generated artifacts into `build/`. `tools/mcp` includes privileged **test-only** controls; they are excluded from the product package and are never exposed as MCP tools. Run host campaigns serially against one fixture. Add `layers_v2_acceptance.py`, `boundary_acceptance.py`, `retained_acceptance.py`, `inspection_acceptance.py` and `budget_acceptance.py` for current qualification. Results and limits are in `docs/Layers_First_2026-10-03/REPORT.md`; the earlier MCP report preserves the 1.0 baseline.

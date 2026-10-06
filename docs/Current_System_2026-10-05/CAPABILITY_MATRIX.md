# Native and MCP capability coverage

**6 October qualification:** MCP 1.2.0 now has twelve tools/seven resources, including separately shared diagnostic pages and cached policy-3 publication manifest/row pages. [Current runtime evidence](../Live_Runtime_2026-10-06/RESULTS.md) covers Max 2027 panel/IPC/stdio, reader passivity, schemas 1/2 and lifecycle. Policy-3 mutation and complete reconstructable recipe/asset export remain unavailable. Historical nine/ten-tool descriptions below identify earlier snapshots; the [current tool list](../../CyrusMCP/README.md#tools) is authoritative for discovery.

Source snapshots: 5 October 2026. **Native availability does not grant MCP write support.** The recorded baseline is MCP 1.1.0 with nine tools. During the [vendor recheck](VENDOR_RECHECK.md), independently edited 1.2.0 source registered `scatter_read_diagnostic_events` as tool ten in [server.py](../../CyrusMCP/cyrus_mcp/server.py). Its runtime behaviour is not qualified by this documentation pass. [settings.py](../../CyrusMCP/cyrus_mcp/settings.py) remains the closed settings registry; [procedural.py](../../CyrusMCP/cyrus_mcp/procedural.py) exposes policy-3 inspection and denies legacy-plan mutation of that policy.

`Read` below means an applicable enrolled scope can expose the stated fields, not unrestricted scene access. `Plan 1/2` means existing bounded automation with local approval and ownership checks. `Future` names a documentation proposal, not a callable tool. Rows are capability families; [CONTROL_INVENTORY.md](CONTROL_INVENTORY.md) accounts for all named controls in the current inventory, without pretending every button is remotely supported.

## Coverage by feature family

| ID | Feature / native owner | Current local implementation | Current public MCP | Required extension or qualification |
| --- | --- | --- | --- | --- |
| C01 | Setup enable / controller | Enable controls contribution; policy retained in scene | Read configuration; plans act on enrolled/owned setups only | Explicit policy-3 controller creation/conversion contract; conversion must respect Edit bindings |
| C02 | Receiver and units / controller | Static flat/curved supported meshes for scatter/Brush; shared receiver defaults | Design enrollment: horizontal convex static site, restricted mesh/primitives | Receiver capability card, topology/units fingerprint, bounded curved enrollment after host proof |
| C03 | Layer administration / controller | Create/copy/remove/name/enable/hide/order; ten total stored populations including sets | Existing plans create up to three owned independent layers; read ordered policy-3 owners | Typed create/copy/remove/reorder with identity remapping, ownership and one transaction |
| C04 | Paint-set ownership / logical layer | Weighted sets share layer population/defaults; independent sources and coverage | Read effective values/paint status and procedural order; no set creation | Explicit declared/inherited/effective values, stable set IDs and atomic parent/set plan |
| C05 | Source palette / set | Pick/remove/share models, groups, weights and metadata | Enroll up to three approved mesh assets; plan source weights/settings; read source configuration | Broader qualified asset enrollment and capability restrictions; no arbitrary scene node IDs |
| C06 | Point/Empty source types / set | Point slots and intentional Empty choices; target mode rejects Empty | Inspection handles non-mesh/missing entries; design plans require mesh sources | Typed source kinds and count semantics before remote creation |
| C07 | Model containers / global/layer/set | Rectangle-local XY pivot membership; global/inherited/own pools; parking preserves registration/settings | Read configured references and pool mode only; **does not rescan membership** | Cached active/parked/missing snapshot with membership revision; later scoped rectangle/pool authoring |
| C08 | Source transform/radius / set row | Source lift/scale/forward axis, radius and follow-scale; per-owner settings | Plan-2 typed source settings; policy-3 metadata inspection | Policy-3 recipe authoring and normalized effective radius explanation |
| C09 | Population and seed / layer | Count or density, stable seed, weighted quota allocation | Plans use bounded count/seed; current configuration exposes more than plans can author | Density/target semantics and total sample budget; no implicit quota per child |
| C10 | Candidate budget / accepted target / layer | Bounded attempt factor, rounds and cleanup-gap retries | Policy-3 recipe and last-published statistics read only | Typed target/work admission and underfill acceptance after actual evaluation |
| C11 | Density texture / layer | Texture/UV density and inversion; qualified native invalidation paths | No map enrollment/write contract | Bounded enrolled map references, revisions and supported evaluation; reject missing assets explicitly |
| C12 | Area include/exclude / layer | Supported scene splines/meshes; Area combines with Brush | Plan-2 enrolled convex include/exclude/protected regions and conservative masks | General domain adapters and surface-bound references; no inferred world mask from an image |
| C13 | Analyzer Area/falloff / layer | Existing supported Analyzer references, curves and distances | No mutation; current plan geometry remains narrow | Analysis capability/version, cached result status and separately qualified binding |
| C14 | Brush coverage / set | Static surface-bound Paint/Erase; radius, strength, softness, density; overlays | Read paint enabled/document/revision/count; no Brush authoring | Typed target-bound stroke/field operations, capped samples/history and one Undo gesture |
| C15 | Brush history/reset / set | Edit, enable, delete strokes; Fill/Empty reset histories; rebinding guard | No mutation or arbitrary document import | Explicit replace/append/reset semantics, stale topology denial, rollback and persistence tests |
| C16 | Background composition / set | Outside coverage, Between plants, both/off; earlier sibling references | Policy-3 recipe read only | Separate typed operations/fields; validate order/domain/spacing without silent fallback |
| C17 | Random/cluster assignment / layer | Policy 3 supports Random/Clusters and source grouping | Existing plan writes random weighted sources; no cluster authoring | Qualified typed cluster parameters; preserve deterministic identities |
| C18 | Line/Analyzer assignment / layer | Supported legacy policies; not policy-3 assignment | Unavailable for mutation | Preserve honest policy restriction; do not offer it in a procedural plan until implemented |
| C19 | Rotation/scale/movement / layer | XYZ/whole scale/rotation, normal alignment, projected movement and resets | Plan 1 basic scale/yaw; plan 2 XYZ scale, XY tilt/projected movement; not every native axis/mode | Policy-3 parity, effective units/ranges and protected-binding effects |
| C20 | Three collision scopes / set/layer/pair | Independent self, sibling and layer rules; XY/3D; radius factor/gap | Plan 2 older shared collision/pair settings; read policy-3 rules | Policy-3 schema with ordered owners, inherited self rule, explicit pair overrides and final-radius checks |
| C21 | Instance Edit/radius / output identity | Move/clone/delete protections and selected-instance world radius/multiplier | No mutation; read stored procedural radius overrides | Snapshot-bound typed edits; define cross-generation correspondence or reject stale identities |
| C22 | Cleanup / layer union | Final neighbor/island cleanup, protected reservations, bounded retry | Typed older-plan cleanup; procedural diagnostics read | Policy-3 parity and disjoint candidate/instance accounting |
| C23 | Relax / legacy layer | Supported older unpainted paths; incompatible Brush/shared/procedural paths paused | Unavailable | Qualify movement/eligibility semantics before enabling; no misleading replacement with another algorithm |
| C24 | Manual/Live and Update / setup | Manual keeps complete publication until Update; Live responds to relevant edits | Existing plan display update mode; read cached result; no general policy-3 Update tool | Distinguish authored commit, evaluate, pending recipe and published result explicitly |
| C25 | Preview / setup/layer | Retained Point Cloud/Mesh; Proxy/centres; display budgets, colours and radius helpers | Plan-2 display subset; cached diagnostic counters and bounded viewport capture | Read-only current diagnostics; later display-only write with zero resampling contract |
| C26 | UI navigation / editor | Six topics, binding, scrolling, resize and tooltips | No remote UI clicking API | Feature help should map to artist location; UI browsing must not become a calculation action |
| C27 | Statistics / set/controller | Cached accepted/rejected/attempt/shortfall/protected/error/epoch data | Diagnostics/configuration; process totals distinct from per-controller data | Reason codes, field freshness/availability and optional bounded conflict samples |
| C28 | Renderer / output | PFlow exact-output adapter; successful production examples; open IR restart issue | No render execution tool; capture is viewport only | Qualified camera/profile enrollment, render jobs and correlated completion/failure receipts |
| C29 | Bake/clear / owned output | Local Bake and clear-owned-output paths | No mutation | Destructive scope, renderer/source fidelity, size cap, undo and failure-before-cleanup checks |
| C30 | Save/load/Undo / scene | Authored state persists; caches reconstruct; binding/unit restrictions | Scoped local recovery, journal and own top-Undo checks; no arbitrary scene-save command | Explicit future snapshot/recovery operations; no remote overwrite of arbitrary files |
| C31 | Export / published generation | Exact local placements; native stable identity semantics | Existing owned policy-1/2 execution record with actual transforms; policy-3 configuration is **not complete layout export** | Immutable policy-3 publication export with recipe, sources, radii, epoch, digest and bounded paging/artifacts |
| C32 | Diagnostics recording / session | Recorded manual tools plus new recorder/local-export source under independent development | Baseline cached diagnostics/journal; 1.2.0 source adds shared trace reading, unqualified here; no remote recording control implied | Qualify the new bounded page and local-sharing boundary, then the full causal session/archive specification |
| C33 | Licensing / product | Default-off native/local lab foundation, incomplete commercial boundary | No licensing-administration authority or production enforcement implied | Apply operation policy consistently across UI/API once qualified; redact grants/keys from diagnostics |
| C34 | References/style/learning / companion | Research and record contracts only | No training/inference tools or automatic collection | Profile/recipe pilot, explicit comparisons, dataset eligibility and held-out evaluation |

## Current public surface

| Tool | Actual role | Main limitation |
| --- | --- | --- |
| `connection_get_status` | Host/enrollment status and identities | Connection does not grant global scene authority |
| `scene_get_context` | Enrolled geometry summaries, units, IDs, revision and budgets | Bounded scope/context lifetime |
| `scatter_validate_plan` | Validate/normalize plans 1/2 and prepare review | Not a policy-3 compiler or proof of final accepted count |
| `scatter_apply_plan` | Queue the exact locally approved plan | Own scope only; fresh revision, digest and idempotency required |
| `scatter_get_status` | Operation or owned controller result | Last publication; timeout is not success |
| `scatter_get_diagnostics` | Cached counts/errors/build/retained metrics | No solver invocation and no presented-FPS claim |
| `scatter_get_configuration` | Effective configuration and additional policy-3 recipe | Current recipe can differ from last-published result |
| `scatter_read_diagnostic_events` **(1.2.0 source candidate)** | Declares bounded cached reading of the exact locally shared trace, with session/sequence cursor and health | Newly registered during this pass; no runtime acceptance here. Does not authorize recording control, sharing, scene evaluation or arbitrary files |
| `scatter_export_record` | Actual current owned legacy generation, plan and receipt | Not arbitrary existing-layout export; training eligibility remains false |
| `scene_capture_viewport` | Explicitly shared active viewport, generation/camera metadata | Not desktop capture or render execution |

Resources are `cyrus://plan-schema`, `cyrus://plan-schema/2.0`, `cyrus://capabilities` and `cyrus://workflow`. The server has no registered per-feature help or agent-workflow prompt catalog yet.

## Current numerical boundaries

Design enrollment supports up to three mesh sources, three planting regions/layers, 2,000 aggregate requested candidates, two successful applications and two captures. There are 24 calls per scope, with outcome/retry exceptions for recovery. Inspection permits up to 32 layer entries; that transport guard does not enlarge the current native ten-population model.

Plan size is 32 KiB; request/context limits are bounded in the implementation. Viewport captures cap the long edge at 1,536 pixels and base64 output at 2 MiB. Execution export uses an exact **1,500,000-byte** limit in `service.py`, despite older text calling it 1.5 MiB. The persistent operation journal retains at most 128 records. Source/site design geometry has separate triangle/vertex limits and rejects modifier stacks, animation and renderer proxies in that enrollment path.

Do not carry these numbers into a new feature by assumption. Plans that request accepted targets require limits on attempts/rounds/neighbor work as well as output count. Large studies need a new bounded authorization and recovery contract; repeatedly re-enrolling is not a substitute.

## Evidence interpretation

The 66-test receipt covers the earlier nine-tool baseline: local contracts, models, transport, service behavior and mocked inspection; older isolated Max campaigns supply host evidence within their own snapshots. It does not test the new tenth tool. `test_procedural.py` explicitly forbids container reconciliation in the inspection test and denies legacy mutation of policy 3. No test count proves every capability row end-to-end. The [roadmap](ROADMAP.md) names missing host, failure and agent-behavior tests before each row can become remotely writable.

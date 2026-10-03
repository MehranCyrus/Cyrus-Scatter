# Cyrus Automation and MCP 1.0 — implementation and qualification

**3 October 2026.** The local MCP implementation is built for Cyrus Scatter 0.64 and Max 2027.1. It supports existing-layout inspection, validated procedural layout creation, one approved refinement, viewport images and local recovery. This is a bounded local release for artist testing; it is not a claim that the entire AI/ML roadmap or every Max/renderer combination is production-qualified.

Start with the [local trial guide](TRY_IT.md) or [installation and user guide](../../CyrusMCP/README.md). The [architecture](ARCHITECTURE.md) describes ownership, threading, geometry and recovery. [Roadmap status](ROADMAP_STATUS.md) separates this delivery from later reference interpretation, retrieval, learning and studio rollout.

## What was implemented

The new `CyrusMCP` package contains a provider-neutral service, strict plan schema, a Max main-thread adapter, a local artist review panel, an authenticated loopback bridge and a separate stdio MCP server using the official Python SDK. No native scatter algorithm, retained viewport implementation or existing scene schema was changed for MCP.

Seven tools are available: connection status, scoped context, validation, apply, operation/controller status, cached diagnostics and viewport capture. Results use structured MCP content and explicit errors; captures use actual MCP image blocks. Schema and workflow resources are also discoverable.

The artist chooses between two workflows:

- **Inspect an existing Cyrus controller:** read up to 32 layers, cached counts/builds/errors, retained Point Cloud/Mesh statistics and loaded binary file hashes. Inspection cannot modify that layout. Manual caches are explicitly identified as cached observations, not proof that source geometry was regenerated.
- **Create a bounded design:** enroll the site, source objects and planting/protected splines locally; review an exact proposal; approve it; generate one procedural controller; optionally approve one refinement. Cancel, Undo/reject and disconnect remain local controls.

The result remains an ordinary editable Cyrus scatter. Owned inset masks persist in the scene and save/reopen preserves seeded placements. A model is not involved in viewport navigation or ordinary rendering.

## Supported release boundary

| Area | Qualified implementation boundary |
| --- | --- |
| Host | Windows x64, 3ds Max 2027.1 build 11426, bundled Python/PySide6 |
| External MCP process | Python 3.11 x64, MCP SDK 2.3.0, pinned offline wheels |
| Existing-layout inspection | One locally selected Cyrus controller, at most 32 layers; cached observations |
| Automated design | One static horizontal convex site; 1–3 sources; 1–3 straight convex planting regions/layers |
| Geometry inspection | Site plus sources: at most 10,000 evaluated triangles and 12,000 vertices; baked meshes/simple supported primitives; no modifier stacks or keyed/procedural controllers |
| Publication | At most 2,000 aggregate requested plants, one initial result and one approved refinement |
| Constraints | Persistent convex inset masks and conservative final footprint containment; protected regions disjoint from authored planting regions |
| Images | Two captures per enrollment, at most 1536 pixels on the long edge and 2 MiB base64; explicit sharing control |
| Recovery | Exact retries, bounded durable operation history, queued cancellation, checked local Undo, unknown outcomes after interrupted execution |

There is no inter-plant packing guarantee. Complex/sloped terrain, renderer proxies in design enrollment, Brush automation, CS Edit automation, arbitrary scripting, remote hosting, custom ML and automatic dataset collection remain outside this version. Max 2026 runtime support has not been tested or advertised.

## Test evidence

The release evidence is retained under [evidence](evidence/summary.json). Tests use separately configured Max processes and synthetic assets created by the harness. The original artist scene and Brush demo were not reset, saved, installed into or used as mutation fixtures.

| Test | Evidence and meaning |
| --- | --- |
| Python contracts/service/IPC/MCP | 48 passing tests: malformed/bounded JSON, geometry/matrices, approvals, revisions, idempotency, cancellations, journal recovery/corruption, capture permissions, read-only scope, authentication/replay, main-thread dispatch and real stdio discovery/errors |
| Repeated Max generation | Final 100-cycle run: metre, centimetre and translated/rotated/object-offset fixtures; seeded hashes, exact retries, pure inspection, Undo node restoration and viewport redraw checks |
| Failure and persistence | Five injected creation failure stages, failed refinement preserving the prior result, successful refinement, stale edits, bounded capture and seeded save/reopen parity |
| Host/input boundaries | Modal and active-Undo admission; native animation Play/Stop; render callback flag; keyed geometry, slopes, non-convex/out-of-site/protected regions, oversized footprints/meshes, deleted inputs, immediate capture revocation and protection against undoing an unrelated artist edit |
| Real MCP workflow | Official SDK client discovers all seven tools and full plan schema; valid zero-count result; 1,800 mixed-source plants across three layers; exact retry; image content and diagnostics |
| Existing controller inspection | Three existing layers inspected without changing parameters, node count, selection, dirty flag, Undo history or preview counters; mutation attempt rejected |
| Retained display observations | Both retained Mesh and Point Cloud reached ready state with GPU uploads; diagnostics remained pure, with owner counters separated from process totals |
| Near-budget generation | 9,000-triangle source, 2,000 emitted instances, exact retry and successful Undo; publication timing about 2.6 seconds on this machine |
| Installed build and UI | Fresh Max process loads the installed startup script; official SDK stdio discovery through the default connection; before-approval denial, actual UI approval, 1,200 plants, exact retry and image; Escape removes the descriptor and destroys the dialog; startup script reopens without reclaiming scope |

The initial 100-cycle run preceded the redraw-leak fix. It established deterministic data behavior, but did not establish working display after injected failures. It is superseded by the final run with explicit redraw-state assertions. This distinction matters: valid counts alone were insufficient.

Performance timings are fixture-specific. `duration_ms` covers generation/publication and its final fingerprint after admission, excluding local approval, model latency, queueing and the earlier freshness check. Context wall time includes the client/dispatcher round trip. These are neither artist workflow times nor viewport FPS. No long-duration memory-leak claim is made.

## Problems discovered and corrected

1. **Max exception recovery could crash.** Letting an exception unwind pymxs Undo with partly configured detached layers crashed the isolated test process. The implementation now catches inside the context, finishes it normally, then performs a checked explicit Undo and verifies recovery.
2. **Exception unwinding could leave redraw disabled.** A minimal test confirmed that a normal `pymxs.redraw(False)` exit restored redraw, while an exception exit leaked a disable reference on this Max build. The catch now sits inside all Undo/redraw/animate contexts. Regression checks verify redraw and Auto Key restoration. Viewport captures were visually checked after the fix and show the actual instances.
3. **Snapshot coordinates were easy to double-transform.** `snapshotAsMesh` already returned world-space data. Source extraction now removes only node transform, retaining object offsets. Rotated and offset fixtures exercise this behavior.
4. **A node animation flag was insufficient.** A cone with two height keys still reported an unanimated node track. The design gate now traverses bounded geometry/transform sub-animations, checks parents and rejects unqualified procedural controllers.
5. **A permissive geometry budget was too slow.** The 100k-triangle source took 25.3 seconds to enroll and exceeded an IPC read timeout. It now fails the preflight budget in about 1 ms. The 9k-triangle source enrolled in about 2.4 seconds and read context in about 1.47 seconds. Larger inputs require faster extraction, not merely a longer timeout.
6. **Windows Store path redirection could split the connection.** Max and packaged Codex could see different LocalAppData locations. Shared installation/connection paths now use the user's `.cyrus-scatter` directory, with a private ACL for connection state.
7. **Transport and MCP details needed real tests.** Fixes cover Windows handle widths, correct structured output, exact encoded image-size limits, safe nonce replay handling, a single-owner connection lease and bounded request rejection behavior.
8. **Local controls needed immediate semantics.** Unchecking image sharing revokes it immediately, re-picking scope invalidates the prior enrollment, and scene labels are rendered as plain text. A real Escape test exposed Max consuming the dialog's key before `reject()` ran. Autodesk's `DisableMaxAcceleratorsOnFocus` guard fixes this; `reject()` closes the connection, and `WA_DeleteOnClose` releases the dialog and child timers instead of accumulating hidden panels.

Private harness problems were kept separate from product defects. Synchronous `playAnimation()` inside the harness's Python timer blocked that timer; animation UI testing uses the real playback control. Synthetic edits now use explicit Undo contexts. A purported concavity fixture was initially a valid triangle with a collinear knot and was corrected before claiming a concavity rejection result.

## Delivery and preservation

The release package is generated under `dist/Cyrus-MCP-1.0.0-Max2027-Release`. Build **1.0.0-d654c4a224df** includes the host scripts, server wheel, 29 pinned dependency wheels, a hash-checked offline lockfile, installer, guide and package manifest. The hash-checked offline installation, dependency verification and Codex registration completed on this machine. Installed files live under `%USERPROFILE%/.cyrus-scatter/mcp/1.0.0-d654c4a224df`. Earlier package candidates are retained under `_local/mcp-package-previews`, outside the source backup.

The final installed package was exercised in a fresh private Max process, not only by reloading development modules. The service and Max adapter match the final 100-cycle run; the later Qt focus/lifetime changes were validated in the installed workflow. See the [evidence index](evidence/README.md) for this provenance and reproduction commands.

The source and tests live under `CyrusMCP` and `tools/mcp`. Bulky Max fixtures, captures, crash diagnostics, virtual environments and build outputs stay under ignored local/build directories. Only compact, non-secret qualification evidence is copied into documentation. No session secret, connection descriptor or operational journal is included in the handoff evidence.

The pre-existing native Brush work and its documentation remain separate. This task did not replace the loaded native 0.64 binaries in the artist's Max session. No Git commit or push was made as part of this MCP implementation turn.

## What this does not prove

This delivery proves a working, bounded tool interface on the recorded host and machine. It does not establish that a model produces better planting designs than an artist, that all renderer/busy/shutdown combinations have been exhausted, or that no future improvements remain. Render admission was exercised through the registered callback's busy state; full renderer workflows and cancellation are a separate qualification track. Unexpected process interruption remains an explicit unknown-outcome recovery case.

The next evidence comes from the user's inspection/design trial, then a second workstation and representative artist briefs. Later ML work should follow the existing data/rights/evaluation gates, beginning with rules and reusable recipes. The MCP implementation neither collects training data nor spends a model API budget on its own.

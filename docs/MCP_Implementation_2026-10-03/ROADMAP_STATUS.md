# Roadmap reconciliation after MCP implementation

<!-- CURRENT_SYSTEM_2026-10-05 -->

Historical MCP implementation status. See [current tools and capabilities](../Current_System_2026-10-05/CAPABILITY_MATRIX.md) and [proposed expansion](../Current_System_2026-10-05/MCP_EXPANSION_SPEC.md). Proposed tools are not registered by these documents.

The initial local automation/MCP implementation is in [CyrusMCP](../../CyrusMCP/README.md). The [qualification report](REPORT.md) defines its supported boundary. This update advances the original [AI/MCP/ML roadmap](../AI_MCP_ML_Roadmap_2026-09-30/15_Phased_Implementation_Roadmap.md); it does not claim completion of the later AI product and ML phases.

| Roadmap area | Delivered | Remaining boundary |
| --- | --- | --- |
| M0 / API-01: observe | Local read-only enrollment, existing layer snapshots, cached diagnostics, retained owner/process counters, loaded binary file hashes, bounded viewport capture | Manual caches may be older than sources; counters are not FPS/VRAM measurements |
| API-02/03: identity and contracts | Epoch/revision IDs, local scope, strict schema 1.0, bounded geometry, unsupported-mode rejection | Inspection IDs describe a cached snapshot, not an exact certification of all source geometry |
| API-04/05: mutation and recovery | Owned creation/refinement, exact local approval, one Undo entry, operation journal, retry suppression, Cancel/Undo, injected failure recovery | Native generation is synchronous; process termination can leave an unknown outcome requiring inspection |
| API-06: geometry | Persistent inset masks, source offsets, unit/matrix conversion, final conservative footprint checks | Static convex horizontal sites; no holes, Boolean mask subtraction, slopes, brush masks or inter-plant packing |
| API-07: main-thread dispatch | Bounded authenticated IPC queue, Qt main-thread adapter, scene lifecycle and busy admission guards | Exact tested lifecycle cases are listed in the report; renderer integration is separate |
| MCP-01/02, UX-01 | Seven typed stdio tools, image blocks, schemas/resources, local review and recovery panel, offline pinned package and Codex registration | Max 2027 qualification only; no embedded chat/login or cloud-hosted Max bridge |
| M1: reproducible engineering tests | Three private scene builders, repeatability, recovery and real MCP runners under `tools/mcp` | Privileged test execution is intentionally absent from production MCP tools |
| General-model planning | Codex can discover the interface; workflow instructions and a user prompt are included | Model task quality and paired manual-versus-agent artist trials have not been measured |
| Reference-based design | Context, opaque asset IDs, dimensions, geometry constraints, initial candidate and one refinement, bounded image feedback | No automatic reference-to-world calibration, authored asset thumbnails/tags or proven composition quality |
| Correction data, retrieval and ML | Provider-neutral boundaries and explicit no-telemetry policy | No automatic correction collection, vector database, custom model, training or preference inference |

## Next loop after the artist test

The [artist-zone integration proposal](../Artist_Zones_Integration_2026-10-03/README.md) adds a concrete next product direction: named artist-drawn zones, procedural paint and explicit spacing rules shared by the manual workflow and future AI plans. Current MCP 1.0 already enrolls bounded planting splines; it does not implement that larger zone model. Add read-only persistent zone/mask/rule context first, then separately qualify typed edits with ownership and revision checks. Existing delivery claims and schema 1.0 above remain unchanged.

1. **Validate usefulness on real briefs.** Start with inspection of an existing scatter, then a simple planar design with low-poly/baked sources. Record the brief, review time, correction time, final acceptance and failures locally. Do not call a valid API response an artist-quality success.
2. **Measure larger-input demand.** The 100k-triangle Python snapshot experiment was too slow. If real briefs require dense sources, batch extraction/fingerprinting through a separately tested native API; keep the current conservative cap until new measurements justify increasing it. This work is independent of retained GPU viewport drawing.
3. **Improve asset descriptions from actual mistakes.** Add approved asset cards, silhouettes/tags and compatible recipes if names and dimensions are insufficient. Try explicit rules and saved recipes before embedding search or training.
4. **Expand one capability at a time.** Terrain, concave regions, multiple controllers, Brush and renderer tasks each need their own typed contracts, ownership rules, geometric tests and host qualification. They are not unlocked by exposing generic script execution.
5. **Qualify distribution on additional machines.** Test the installer and runtime on another Max 2027 installation before broad studio rollout. Max 2026 needs its own port/installation/runtime checks. A compiled core SDK build is not MCP runtime evidence.

## Later ML admission criteria

Use the existing [ML experiments](../AI_MCP_ML_Roadmap_2026-09-30/10_ML_Options_and_Experiments.md) and [data strategy](../AI_MCP_ML_Roadmap_2026-09-30/08_Data_and_Training_Strategy.md). Begin only after a specific repeated failure survives simpler fixes, accepted examples have clear rights/consent, stable identities can associate edits with the correct instances, and evaluation splits separate projects/studios. Compare any model against rules, presets and retrieval on artist correction time plus hard geometric validity. Keep training/telemetry outside scene files and native viewport callbacks.

The operational journal is recovery data and must not be silently repurposed as a training dataset. Existing Codex authentication also must not be copied into a later embedded assistant; commercial provider authentication and entitlement are separate decisions.

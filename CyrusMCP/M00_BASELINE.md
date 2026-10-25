# M00 baseline and feature-family coverage

Recorded 24 October 2026. Status: in progress; a matched Max 2027/source-client workflow has scoped evidence. Full operation coverage and final installed-client/package alignment remain open.

## Source and client evidence

- Planning HEAD: `588abff0ce211d7dc63798b8c5310631895465c7` before this uncommitted increment.
- Catalog SHA-256: `9dc285094c218103c6a4ae61668fe9e5b4cf268ec8834f2f0425f02971184e0a`.
- Catalog declares Scatter 0.86.9.2, CyrusUnified2, MCP 0.73.0. Closed authoring plan remains 0.73.
- Source currently registers thirteen development tools and seven resources; the added tool validates owned count/seed changes or explicit Update. The offline suite includes an actual stdio discovery/schema/error test against the source server and its SDK client; this is not installed-client/Max integration.
- The currently advertised Cyrus integration exposes seven tools: connection_get_status, scene_get_context, scatter_validate_plan, scatter_apply_plan, scatter_get_status, scatter_get_diagnostics, scene_capture_viewport.
- Fresh read-only connection_get_status returned OUTCOME_UNKNOWN (local connection interrupted). No apply was issued, and this status alone does not establish any new scene mutation.
- The initial seven-tool configured integration is distinct from the twelve-tool source SDK client tested below. No artist session or configured connection was altered or restarted.
- Initial source/test baseline: `build/mcp-foundation-20261024-01/`, 265 passed before the first increment. Latest offline suite: **349 passed in 37.70 s**, `build/mcp-process-loss-20261024-01/offline.xml`; these tests remain separate from native execution evidence.

## Matched owned-host/client witness

Profile `build/mcp-foundation-20261024-04/host01` loaded the staged exact 0.86.9.2 Max 2027 and Analyzer 0.14.2 package pair. Five loaded native module hashes match the staged payload; loaded paths and script identity are recorded. Its 22 frozen MCP runtime Python/JSON files match current runtime source. The owned PID was 55420 and was closed cleanly after the campaign.

A real external MCP SDK stdio client discovers twelve tools and creates a locally approved two-layer bounded task. The final witness reports 197 accepted placements from 240 candidates, with all exported transforms matching the actual cached publication page. Configuration, diagnostics and viewport PNG capture work; reading an unshared trace fails with the expected permission error. Native tests also cover static enrollment time freshness, a pre-publication construction rollback, known committed failure after generation and local retirement without changing the scene.

Receipt: `build/mcp-foundation-20261024-04/host01/foundation-results-450f87d2e9ef47c59876bd8f573455bd.json`, artifact ID `3f42516948e7c6df1230b3fc65c6d90f3fb98abff09edb8feca6fd9575fb46e5`. [M01](M01_OPERATIONS.md) explains native gaps found and corrected, page schema 2.0, scripted approval provenance and remaining acceptance. This does not qualify physical interaction, every tool permission branch, existing-owner refinement, production installation, all feature families or broad renderer/performance behavior.

Successor run `build/mcp-foundation-20261024-06/host01` qualifies the refinement correction with the same packaged native pair, all five native hashes matching and 22 frozen runtime files matching source. Its native fixture verifies complete previous-publication restoration on own Undo, Redo and three failed-refinement checkpoints. A separate SDK stdio campaign repeats creation/readback/capture/recovery. Receipts: `refinement-567e497b2f624b849a379036629a3d55.json` and `foundation-results-652d4a1d102340b18dd35bebc6114da8.json`, artifact ID `787d6fdb6d77133e8e78ed63c7d2f144a1fe640437ceefdee0d869b924b81ab4`. PID 52500 was closed cleanly. These are owned native API and SDK witnesses, not full external-model/physical-UI or all-family acceptance.

## Coverage inventory

The native/public-API statements below are copied from the current catalog, not newly executed qualification. Milestone assignments are the chosen plan. Required rows are pending until their operation-level cases and supported combinations are implemented and qualified. A native-only declaration does not grant MCP write authority.

Retired behavior and licensing administration/experimental learning remain excluded. C28 includes required output readiness; remote renderer jobs are optional. C26 means task UI and domain behavior, not arbitrary UI clicking. All rows need explicit supported/unsupported combinations rather than a single feature-family pass.

| Family | Feature | Catalog public MCP declaration | Planned milestone | Qualification |
| --- | --- | --- | --- | --- |
| C01 | Setup enable / controller | Read configuration; Plan 0.73 creates/refines only owned unified controllers | M05 | Pending operation cases and host evidence |
| C02 | Receiver and units / layer | Design enrollment remains a horizontal convex static site with restricted geometry | M02, M07 | Pending operation cases and host evidence |
| C03 | Layer administration / controller | Plan 0.73 creates up to three owned layers; read explicit order/IDs | M05 | Pending operation cases and host evidence |
| C04 | Paint Areas / layer | No public Paint Area or Brush authoring | M07 | Pending operation cases and host evidence |
| C05 | Source palette / layer | Enroll up to three mesh assets; plan weights and typed source settings | M03, M06 | Pending operation cases and host evidence |
| C06 | Point/Empty / source row | Read configuration; plans require mesh assets | M06 | Pending operation cases and host evidence |
| C07 | Source containers / global/layer | Read pool references, cached membership and helper label/identity/context/status; no reconciliation | M06 | Pending operation cases and host evidence |
| C08 | Source transforms/radii / model row | Plan 0.73 typed Manual source metadata; no new Auto-mode mutation | M06 | Pending operation cases and host evidence |
| C09 | Population/seed / layer | Plan 0.73 bounded count/seed | M06 | Pending operation cases and host evidence |
| C10 | Budget/target/refill / layer | Cached recipe/statistics; plan count is a candidate budget with explicit underfill policy | M06 | Pending operation cases and host evidence |
| C11 | Density masks / layer | No map/channel enrollment or write contract | M07 | Pending operation cases and host evidence |
| C12 | Include/exclude / layer | Plan 0.73 convex enrolled include/exclude/protected areas with conservative masks | M04, M07 | Pending operation cases and host evidence |
| C13 | Analyzer Area/falloff / layer | No Analyzer mutation/binding | M07 | Pending operation cases and host evidence |
| C14 | Vector Brush / Paint Area | No Brush authoring | M07 | Pending operation cases and host evidence |
| C15 | Vector persistence / Paint Area | No history import or mutation | M07, M09 | Pending operation cases and host evidence |
| C16 | Retired set background composition | No background authoring | Excluded: retired | Excluded per goal |
| C17 | Random/Clusters / layer | Plan 0.73 random weighted assignment | M06 | Pending operation cases and host evidence |
| C18 | Layout bands / layer | No Band/range/density/assignment mutation | M07 | Pending operation cases and host evidence |
| C19 | Rotation/scale/movement / layer | Plan 0.73 bounded uniform/XYZ scale, yaw, XY tilt/projected movement subset | M06 | Pending operation cases and host evidence |
| C20 | Clearance / source with layer defaults | Plan 0.73 retains its typed self/source radius/layer-pair subset; no new source-policy write API | M06 | Pending operation cases and host evidence |
| C21 | Edit/instance radius / stable identity | Read radius overrides; no Edit mutation | M08 | Pending operation cases and host evidence |
| C22 | Cleanup / accepted layer union | Plan 0.73 typed cleanup subset; cached statistics | M06 | Pending operation cases and host evidence |
| C23 | Relax / layer candidate preparation | No Relax mutation | M06 | Pending operation cases and host evidence |
| C24 | Manual/Live / controller | Plan 0.73 display/update subset; reads do not Update | M05 | Pending operation cases and host evidence |
| C25 | Preview / setup/layer | Existing typed display subset, cached metrics and viewport capture; new Band/field/memory controls remain local | M04, M12 | Pending operation cases and host evidence |
| C26 | UI / editor | Catalog/workflow help; no remote UI invocation | M04 | Pending operation cases and host evidence |
| C27 | Statistics / layer/controller | Cached diagnostics/configuration/publication | M01, M06 | Pending operation cases and host evidence |
| C28 | Renderer / output | No render execution tool; viewport capture only | M11: output readiness; render jobs optional | Pending operation cases and host evidence |
| C29 | Output cleanup / owned output | No mutation | M11 | Pending operation cases and host evidence |
| C30 | Save/load/Undo / scene | Scoped own-top-Undo/journal recovery; no arbitrary scene save | M09 | Pending operation cases and host evidence |
| C31 | Publication/export / generation | Cached stale-checked pages and current owned execution record for Plan 0.73 | M11 | Pending operation cases and host evidence |
| C32 | Diagnostics / session | Exact locally shared cached trace pages and operation journal; no remote recording/sharing control | M01, M12 | Pending operation cases and host evidence |
| C33 | Licensing / product | No licensing-administration authority | Excluded: licensing administration | Excluded per goal |
| C34 | Style/learning / companion | No inference/training/reference-image tools | Excluded: experimental learning | Excluded per goal |
| C35 | Settings presets and complete static recipes | Catalog help only; no preset/recipe filesystem or application tool | M03 | Pending operation cases and host evidence |
| C36 | Slope and altitude eligibility | No authoring write; documentation only | M06 | Pending operation cases and host evidence |

## Open M00 acceptance

- [x] Record native/script/package/loaded identities for an owned Max 2027 environment; scoped witness above.
- [x] Decompose all 33 required catalog families into [75 domain operation rows and common gates](OPERATION_COVERAGE.md); full per-field/workload/combination acceptance remains unfinished.
- [ ] Classify optional output/client extensions explicitly; retain the agreed required feature scope.
- [ ] Finish packaged/installed intended-client alignment; the source SDK stdio path passes while the original integration remains unchanged.
- [ ] Finish approved creation/refinement lifecycle coverage; creation/readback, fault retirement, owned replacement, publication Undo/Redo and three failed-successor checkpoints pass; configure-only/Update passes in the scoped run 07 matrix; wider lifecycle and physical panel cases remain open.
- [ ] Record matched-artifact hashes and the supported workload baseline.

The unavailable original configured host did not prevent isolated qualification. M00 remains in progress, rather than complete or blocked. Its operation matrix must also address remaining native/read-budget differences, including publication per-set metadata limits, before claiming maximum native inspection coverage.

## Run 07 source contract increment

[Configure/Update evidence](M01_CHANGES.md) qualifies a thirteenth source tool, `scatter_validate_change`, reusing existing local approval/apply/status. Count/seed patches preserve current owned layers and unmentioned fields; configuration and publication IDs are separate. Manual pending behavior passes in proxy, retained Mesh and Point Cloud, with unchanged warm build/upload counters. Explicit Update, Live combined changes, Undo/Redo and three failure checkpoints pass. The full creation/recovery and replacement campaigns remain passing. All 23 frozen runtime Python/JSON files match source; five loaded native hashes match the same 0.86.9.2/0.14.2 Max 2027 payload. The private driver was explicitly rebound for additional edge cases; preceding qualification manifests are archived. This adds scoped cases to C09/C24/C30 and M01/M05, not all-family acceptance. The original seven-tool configured integration and historical twelve-tool receipts remain distinct.

## Run 08 recovery and acceptance decomposition

[Recovery evidence](M01_RECOVERY_BOUNDS.md) adds pre-marshalling selected-metadata budgets, configuration-aware commit evidence, real Windows approval/No/retirement input and a configured post-commit/journal-reload witness. Final offline suite: **349 passed in 37.70 s**, `build/mcp-process-loss-20261024-01/offline.xml`; 24 frozen runtime files match current source and five native hashes match the same packaged pair. The thirteen-tool SDK/native campaign passes with 200 accepted rows from 240 candidates and matching actual export/pages. Native helper corrections were explicitly reloaded/rebound, with prior failed sources and manifests retained. The owned host was closed; the artist session and original configured integration remain unchanged.

[O01–O75](OPERATION_COVERAGE.md) cover all 33 required catalog families, the 333-control inventory's family mapping, cross-feature gates and explicit optional/excluded scope. This closes the initial decomposition, not the required fields, supported workloads/combinations or full qualification. Every required row remains pending full acceptance; final client/package alignment remains open.

## Process-loss increment

[Actual before/after-process evidence](M01_PROCESS_LOSS.md) adds three O61/O59 scenarios, known-versus-unknown commit evidence, approved-base target semantics and startup blocking. **349 tests passed in 37.70 s**, `build/mcp-process-loss-20261024-01/offline.xml`; all 24 frozen runtime files match current source, and each successful fresh host verifies the same exact five native module hashes. The isolated startup exit and rejected-before-admission fixture attempt remain excluded from passing evidence. Pending Manual populations changed across cold reopen in the measured cases; task/publication restoration and full operation acceptance remain open. No configured client/package or artist-profile change follows from these source tests.

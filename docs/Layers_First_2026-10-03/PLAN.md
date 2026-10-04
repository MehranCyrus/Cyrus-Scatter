# Layers-first implementation plan

2026-10-03 design contract, implemented and qualified in the 4 October pass. The original checklist below preserves the acceptance intent. The authoritative completed work, evidence and deferred boundaries are in [CHECKLIST.md](CHECKLIST.md), [REPORT.md](REPORT.md) and [CAPABILITIES.md](CAPABILITIES.md); an original requirement alone is not evidence of runtime qualification.

## Required outcome

Implement the accepted hierarchy in `mockups/layers-first/index.html` using ordinary native Max controls. General settings remain separate. Every expandable layer owns all of its settings; multiple layers can stay open. Red/blue/yellow brush sets live inside their parent layer. The HTML defines hierarchy and interactions, not a CSS skin or evidence of engine capabilities.

Preserve existing placement, Brush, Edit, retained Mesh/Point Cloud/Proxy, rendering and persistence behavior. Follow UI delivery with complete coverage of **qualified supported settings** through MCP and versioned future ML records. Unsupported settings must remain explicit capabilities/limitations rather than implied support.

## 1. Native host gate

- [ ] Inventory every existing control and action; map it to General, layer, or brush set. Include advanced source properties, surface, population, areas/exclusions/falloff, distribution/diversity, transforms/reset, spacing/cleanup, Brush, preview/status/update, and output/Bake. Preserve supported actions absent from the mockup.
- [ ] Prototype a fixed-height native Layers subrollout under the root. Each layer has an independent header and a bounded scrollable editor area. Internal expansion changes internal content, never the root rollout height. Choose usable bounds against narrow command panels; verify nested scrolling and focus before adopting this host.
- [ ] Generate uniquely named per-slot editor rollouts, construct lazily once, and retain them through ordinary collapse/expand. Bind each slot to a persistent layer ID plus object reference; row indices are presentation only. Recreate only after object deletion/lifetime change.
- [ ] Remove `selectedLayer()` and global editor references from per-layer event routing. Selection may control an explicitly active brush tool, but cannot redirect controls in another open layer. Guard programmatic binding to prevent spurious writes and undo entries.
- [ ] Do not revive width polling, Win32 width repair, or changes to root height on layer/section expansion. Measure actual clicks and window geometry; settled width alone is insufficient.
- [ ] Native experiment acceptance: two complete layer editors open concurrently; editing either affects its bound layer; repeated warmed expansion retains controls; no observed 240→162→240 width reset; scrolling, host resizing and close/reopen work. Record first-open and warmed timings, handle counts, and cache counters.

If native subrollout containment fails this gate, document the precise host limitation before choosing another host. A full Qt rewrite is not the default scope and is not automatically authorized by an inconclusive experiment.

Critical implementation files: `AminScatter/tools/ui/native-v1.cjs`, `AminScatter/tools/ui/planting-groups.cjs`, `AminScatter/tools/ui/templates/native-layers.ms`, `planting-manager.ms`, `planting-brush.ms`, `planting-separation.ms`, and the generated MAXScript. Replace the current final prohibition on all subrollouts with focused assertions against obsolete singleton routing and resize repair. Adjust stage boundaries deliberately: `planting-groups.cjs` currently replaces complete native rollouts after `native-v1.cjs`.

## 2. Layer and brush-set ownership

- [ ] Introduce explicit persisted logical-layer and brush-set IDs, with a parent link and ordered child membership. Retain existing evaluator population objects as leaf execution units; do not make UI grouping the only record of ownership.
- [ ] Parent owns common surface policy, population method/budget, areas, distribution, transforms, spacing and output policy. Each set owns its sources/weights and source metadata, independent paint document/history, name/color, stable ID, seed stream, and enable/visibility state. One implicit whole-surface set supports an ordinary unpainted layer.
- [ ] Use one authoritative parent configuration and an explicit effective-configuration adapter for each leaf. Avoid independently editable copies of shared settings. Include parent revision and child source/paint identity in cache keys. Apply changes atomically before evaluation; inspect/read/export returns effective settings and ownership.
- [ ] Define population meaning before wiring controls: a parent candidate budget is shared deterministically across enabled sets using explicit weights; expose requested/candidate/eligible/accepted counts per parent and set. Do not silently multiply the parent count by the number of sets. Preserve old independent populations as independent logical layers on migration unless an explicit conversion defines new shared-budget semantics.
- [ ] Stable candidate/Edit identity includes persistent set identity and local candidate identity. Adding/reordering another set cannot redirect existing edits. Budget changes may create dormant candidates; retain the current documented dormant-override policy.
- [ ] Resolve spacing over the final accepted union of sets. Parent-level pair rules expand deterministically to leaf relationships; allow set-specific rules only if represented explicitly in the contract/UI. Within-parent overlap uses stable declared priority/tie ordering. Rejected/erased/cleaned rows cannot block later rows; protected manual overrides retain conflict reporting.
- [ ] Copy creates new ownership IDs and independent paint history; delete/Undo restores membership and relationships; visibility changes viewport only, while disable removes contribution under existing evaluation semantics. Save/reopen preserves all identities, effective settings, histories and output fingerprints.
- [ ] Keep layer capacity and candidate/resource caps explicit. Existing ten-population limits cannot be advertised as ten parents times arbitrary children; declare and enforce the initial total leaf cap until storage/UI limits are qualified.

Critical files: `AminScatter/tools/ui/templates/planting-model.ms`, Brush integration/session templates and generator parameter declarations; `AminScatter/src/group_spacing.cpp`, `group_spacing_bridge.inc`, and `include/group_spacing.h` only where the existing resolver cannot express the specified ownership policy. Prefer adapting the existing deterministic resolver over introducing a second solver.

## 3. UI completion and regression boundaries

- [ ] General: shared surface/defaults, master enable, update policy, viewport representation/budget, overall diagnostics and setup actions. Each layer contains all layer-specific settings and its own statistics/update/actions; inherited settings identify the effective value and override policy.
- [ ] Brush: set picker/details are nested within the owning layer. Starting a new set's brush ends the previous session safely. Add/erase/clear, stroke undo/history, tint/samples/off, topology invalidation and Manual Update pending state remain explicit.
- [ ] Advanced controls retain availability rules. Brush Relax and shared Boundary Relax remain paused until independently implemented and qualified; saved values must not masquerade as active behavior.
- [ ] Update only affected UI bindings after edits; do not rebuild all controls, evaluate geometry from draw callbacks, or recalculate statistics through a new polling timer.

## 4. MCP correctness first, then capability coverage

- [ ] Fix `CyrusMCP/cyrus_mcp/max_host.py`: choose and assign evaluation/group policy explicitly; establish IDs, parent/set membership, enable/visibility and complete configuration before solving. Validate final published rows after attachment/shared resolution. Derive emitted counts, stable IDs, transform digest, underfill and footprint checks from that same committed population.
- [ ] Keep schema 1 behavior explicit and qualified. Add a separately versioned schema 2 with a strict capability map; unknown fields, unsupported combinations and unqualified engine paths fail validation.
- [ ] Build a control-to-contract table covering all qualified controls: sources and weights/metadata, supported population modes, seeds, surface/area include/exclude, supported distribution/falloff, transforms, spacing/pair policy, preview/update and owned output operations. Each entry identifies units, enum/range, defaults, ownership, cache effect and validation evidence.
- [ ] Brush automation initially references enrolled local paint documents/regions through opaque scoped IDs; no unrestricted filesystem paths, arbitrary script execution, or invented stroke/topology remapping. Advertise procedural stroke editing only after its own bounded contract and tests exist.
- [ ] Preserve bounded generation/refinement transactions, approved enrolled sources/targets, context freshness, expected generation, idempotency, Undo rollback and budget checks. Normalized effective settings and group policy participate in plan/input digests and receipts.
- [ ] Expose inspect/configuration/diagnostics and final-result export alongside mutations; report requested/emitted/displayed separately. MCP completeness means every qualified setting is either supported by a typed tool or explicitly listed as unavailable with a reason.

Critical files: `CyrusMCP/cyrus_mcp/plan.schema.json`, `contracts.py`, `models.py`, `service.py`, `max_host.py`, `server.py`; tests in `CyrusMCP/tests/test_mcp.py` and focused schema/adapter fixtures.

## 5. Future ML contracts only

- [ ] Implement versioned records for scene context, normalized plan, execution receipt, actual final layout and artist correction lineage. Use opaque parent/set/candidate IDs, units, seed/build/input digests, requested/actual settings, missing-value semantics and provenance.
- [ ] Record corrections only where stable mapping is known; parameter changes and whole-layout replacement must not pretend to be per-instance labels. Separate consent/retention/training eligibility from operational logging.
- [ ] Keep dataset/train/test provenance and model-neutral contracts compatible with `docs/AI_MCP_ML_Roadmap_2026-09-30`. No training, ranking model, GPU compute, background Max SDK calls or learned placement is part of this delivery.

## Acceptance matrix

| Area | Required evidence |
| --- | --- |
| Ownership/UI | Two or more open layers; source/transform/area/spacing edits stay with the clicked layer; all controls accounted for; native narrow-panel, DPI, scrolling and reopen observations |
| Lifetime/layout | Cold and warmed expansion; control identities retained; no root-height mutation during internal expansion; frame/geometry evidence for reported flash, not settled screenshots alone |
| Brush sets | Grass plus a Flowers parent containing red/blue/yellow; independent source/history; parent transform affects all sets; erase frees space; count budget does not multiply |
| Solve/Edit | Existing shared spacing oracles; mutual priority, cleanup, protected moved/hidden overrides, dormant edits, copy/delete/Undo and deterministic seed results |
| State | Independent logical-layer migration preserves existing scenes; new parent/set save/reopen preserves IDs, histories, settings and final fingerprints |
| Performance | Retained 20k navigation/redraw fixture keeps placement, Brush query and upload counters unchanged; compare first-open, warmed interaction and bounded dense resolution against baseline |
| Outputs | Point Cloud/Proxy/Mesh/centres distinguish shown versus placed; hidden versus disabled, Bake, renderer and pending Manual Update consume documented committed population |
| MCP | Schema rejection/units/caps; supported-setting round trips; UI-versus-MCP equivalent normalized input/output; post-attachment digest; stale/refinement/idempotency/rollback failures |
| Packaging | Regenerate from source templates, build existing native suites for supported SDKs, private-profile exact loaded identities, installer/startup and uninstall regressions |
| Claims | Actual runtime hosts/renderers named; Max 2026 build-only remains build-only; no unlimited performance, arbitrary renderer or ML readiness claims |

Execute existing fixtures in `tools/v1/` plus focused new fixtures for concurrent editor bindings and parent/set ownership. Reuse `planting_qualification.ms`, `planting_reopen_fixture.ms`, `planting_legacy_fixture.ms`, output/Edit/Brush/navigation/render checks and the Python MCP suite. Tests run in disposable hosts/profiles, preserving the artist's open scene. Record source/package/runtime identities with evidence.

## Delivery order and stop conditions

1. Native host experiment and control inventory.
2. Persisted ownership/effective-configuration adapter and stable identity semantics.
3. Complete native hierarchy and Brush-set workflow.
4. Existing engine/output/performance/persistence regression campaign.
5. MCP published-result correction, then typed supported-setting coverage.
6. ML records, package qualification, concise artist/developer documentation.

A failed host experiment blocks adopting that host; failed output parity blocks release; unsupported combinations block only the affected capability. Do not label partial UI wiring, synthetic mockup state, schema drafts, or build-only results as completed runtime functionality. Planning is an implementation step and does not require a new user confirmation to continue the authorized work.

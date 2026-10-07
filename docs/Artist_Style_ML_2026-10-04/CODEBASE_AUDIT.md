# Current source audit and integration gaps

Audited 4 October 2026 at commit `e3518f8f87f3144d531f20afbb6790ce243f2cfc`. Findings are source inspection, not new runtime qualification. This research task changes documentation only. Exact inspected-file hashes are in [source_snapshot.json](evidence/source_snapshot.json).

## Reusable foundations

| Source anchor | Verified behavior | Implication for the style system |
| --- | --- | --- |
| [server.py](../../CyrusMCP/cyrus_mcp/server.py), lines 36–94 | Nine tools plus workflow, schemas and capability resources | Read live capabilities; do not teach a model a permanently hardcoded UI inventory |
| [models.py](../../CyrusMCP/cyrus_mcp/models.py), lines 11, 20, 63, 77 | Closed plan schemas; typed layer/source/display fields and pair rules | Keep a separate profile/recipe contract; unsupported style keys cannot be appended to executable plans |
| [contracts.py](../../CyrusMCP/cyrus_mcp/contracts.py), lines 87–146 | Independent validation; 32 KiB plans; one to three layers; 2,000 total candidates; identity and pair-rule checks | Compiler output must pass both MCP-facing and host-side validation |
| [settings.py](../../CyrusMCP/cyrus_mcp/settings.py), lines 10–81 | Shared setting registry, normalization and capability manifest | Reuse units, ranges, defaults and unsupported-feature declarations |
| [service.py](../../CyrusMCP/cyrus_mcp/service.py), lines 147–218 | Scene context, revisions, five-minute deadlines, enrolled references, conservative masks and validation digest | Model output must be bound to a fresh scene; a long inference cannot retain authority indefinitely |
| [service.py](../../CyrusMCP/cyrus_mcp/service.py), lines 225–320 | Local approval, apply queue and controlled host execution | Preserve the current review/transaction boundary |
| [max_host.py](../../CyrusMCP/cyrus_mcp/max_host.py), lines 186–218 | Explicit enrollment and geometric asset/site summaries | Good geometric substrate, but not semantic understanding of a whole architectural scene |
| [max_host.py](../../CyrusMCP/cyrus_mcp/max_host.py), lines 262–297 | Effective layer/set configuration, allocations, source settings and Brush status | Inspection can explain existing ownership without granting mutation of those controls |
| [max_host.py](../../CyrusMCP/cyrus_mcp/max_host.py), lines 320–472 | Build owned layers, solve after graph attachment, validate final footprints, export actual matrices/counts | Train/evaluate against final results rather than assuming plan settings equal output |
| [records.py](../../CyrusMCP/cyrus_mcp/records.py), lines 6–35 | Execution and correction record contracts; training eligibility false | Reuse provenance and lineage; add an explicit collector and dataset review |
| [scatter.h](../../AminScatter/include/scatter.h), lines 27–68 | Seeded settings, density and area controls, candidate keys and surface anchors | Reuse procedural state and known geometry; do not replace the scatter core with an opaque model |
| [logical-layers.ms](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/logical-layers.ms) and [planting-groups.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/planting-groups.cjs) | Parent/set ownership and shared settings/placement policy | Future learned coverage and recipes must respect existing ownership semantics |

Use the current [capability guide](../Layers_First_2026-10-03/CAPABILITIES.md) and [MCP README](../../CyrusMCP/README.md) for the broader documented qualification boundary.

## Limits that directly affect this proposal

1. **Scene scope is explicit and small.** Design enrollment requires Max 2027, a static horizontal convex receiver, one to three simple/baked mesh assets and one to three convex planting regions, plus up to three protected regions. Inspected receiver/source geometry has an aggregate budget of 10,000 faces and 12,000 vertices. Arbitrary production proxies, sloped terrain, a whole building and all surrounding obstacles are not automatically understood.
2. **Application/search budgets are bounded.** At most two successful applications, two captures and 24 normal tool calls per enrollment. A proposal to test many layouts must use a future offline fixture runner or a separately approved design, not silently re-enroll to evade the current limits.
3. **MCP creates independent logical layers.** It can inspect parent/set state, but does not create paint sets or edit Brush histories. The user's preferred layer/set workflow needs a new typed mutation contract before ML can author it.
4. **Population semantics matter.** `service.py:217` warns that count is sampled over the site before masks; actual output can be lower. `max_host.py:440` checks underfill against the published result. A requested 500 cannot be advertised as exactly 500 plants inside a smaller painted zone.
5. **Footprint constraints are approximations with explicit meaning.** The adapter derives conservative circle/bounding-radius masks, accounting for scale, tilt and movement. This is not exact leaf-by-leaf mesh intersection or ecological suitability.
6. **Exports are operational and temporary.** Current-generation owned layouts are held in memory and record exports are bounded to 1.5 MiB. There is no persistent training library, automatic artist-scene collector or full renderer dataset exporter.
7. **Identity has a generation boundary.** Exported instance identities and transforms describe that published generation. A replacement generation does not prove one-to-one correspondence. `records.py:26` forbids per-instance IDs for whole-layout replacement/parameter-change labels.
8. **Capture is not a ground-truth rendering service.** Current viewport capture can trigger a redraw and requires local sharing. It does not supply calibrated depth, semantic masks or photorealistic render passes.

These are scope boundaries, not newly discovered defects. They are prerequisites for claiming a broader design system.

## Important pattern distinctions

`scatter.h:49` labels `clusterEnabled` as source diversity that does not change placement. `scatter.cpp:204` uses separate placement, transform and source random streams; the clustering path affects source/group choice. Turning this control on is not equivalent to creating high-density spatial plant clumps.

Native spatial capabilities should nevertheless be reused where applicable. `scatter.cpp:181` routes boundary rows through `prepareEdgeRows`; [edge_border.inc](../../AminScatter/src/edge_border.inc) computes those points. Analyzer/line controls have existing scope and shared-set restrictions. A claim that Cyrus has no row support at all would be incorrect; what is missing is a qualified general pattern contract in MCP.

`scatter.h:46–53` and `scatter.cpp:313` describe UV density and area filtering. Density storage runs from `v=1` to `v=0`, and `preserveDensity` names fixed-candidate thinning without refill. A future ML field cannot be bound safely by assuming an arbitrary PNG is already in the correct world/surface domain.

## Proposed engineering changes, in order

| Priority | Work | Existing boundary to reuse | Evidence required |
| --- | --- | --- | --- |
| P0 | Profile/recipe library and role binding | `models.py`, `settings.py`, context summaries | Valid supported plans, explicit rejection of unsupported requests |
| P0 | Provenance-linked collector for owned generations | `records.py`, `scatter_export_record` | Matching context/plan/layout digests, correct units and explicit labels |
| P0 | Recipe-to-current-plan compiler | Independent `validate_shape`, normalization and local approval | No secret defaults, stale IDs, invented settings or budget bypass |
| P1 | Compare exemplar/statistical fitting with recipe retrieval | Actual transforms, semantic roles, native seeded engine | Better accepted layouts on new sites, not just a matching training patch |
| P1 | Semantic zones/obstacles and broader asset cards | Enrollment and source footprint logic | Artist-confirmed roles, source revisions, boundary fixtures |
| P1 | Expose parent/set and field operations deliberately | Logical layers, Brush generator and typed registry | Undo/persistence, manual-edit preservation, scope/size validation |
| P2 | Preference ranking and optional frozen visual features | Collector and offline evaluator | Held-out improvement over simple baselines |
| P3 | Structured planner LoRA or learned fields | Versioned recipe/field contracts and dataset | Valid output plus better artist outcomes at measured resource cost |

Keep source/UI generator ownership intact. New interactive controls belong in authoritative `AminScatter/tools/ui/` sources; `AminScatter/scripts/AminScatterObject.ms` is generated. Do not inject ML calls into its viewport callbacks, native retained-display updates or ordinary placement loops.

## What was not verified in this task

No new Max session, UI interaction, installation, renderer run, performance comparison, model inference or training occurred. The repository's previous runtime evidence remains historical. The new checks validate documentation links, synthetic plan shape/settings and preservation of tracked non-documentation files. They do not qualify semantic interpretation, style transfer, learning quality or expanded MCP scope.

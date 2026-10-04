# Native controls, MCP coverage and future ML

4 October 2026. Product: Scatter 1.2.0; automation: MCP 1.1.0. Machine-readable native inventory: `AminScatter/tools/ui/layers-control-inventory.json`. Machine-readable automation registry: `CyrusMCP/cyrus_mcp/settings.py`; clients read `cyrus://capabilities`.

## Control-to-contract coverage

| Feature / ownership | Native implementation | MCP contract / boundary | Main evidence |
| --- | --- | --- | --- |
| Receiver / General | Existing shared surface picker/list | Locally enrolled horizontal convex site | Enrollment/boundary campaign |
| Layer add/copy/remove / parent | Native independent expandable editors, persistent ownership, Undo | Create/refine up to three owned independent layers; inspection reads parent/set membership | Ownership/copy/Undo/reopen; v2 acceptance |
| Paint sets / parent | Named weighted child populations; source/Brush state per set | Read effective configuration only; no creation/history mutation tool | Shared budget/erase and pure configuration checks |
| Sources / set | Weights, colors, scale, offset, forward axis, radius, point-only/empty policy | Enrolled source IDs and weights; typed source scale, Z offset in metres, radius, follows-scale/show flags, forward axis 1–4 | Native output and v2 four-mode campaign |
| Population / parent | Count, plants/m², texture density | Seeded count, up to 2,000 aggregate candidates; no density-map binding | Shared density cap, black/white map regression, Python schema tests |
| Area / parent | Include/exclude closed shapes, XY projection; Analyzer Area and falloff preserved | Enrolled convex include/exclude/protected regions; conservative source footprint masks | Native area fixture; protected-hole v2 assertions |
| Diversity / parent | Random, Clusters; Line Pattern/Analyzer single-set only | Random weighted sources only; other modes unavailable | Guard fixture; legacy native solver suites |
| Brush / set | Paint/erase/fill/empty, editable history, curved static receiver, Undo | Local UI only; no arbitrary document paths or script execution | Native Brush/group, curved and independent erase checks |
| Randomize XYZ / parent | Existing rotation, XYZ/whole scale, movement and Reset controls | Whole scale/Z yaw plus XYZ scale, XY tilt, projected XY movement; source Z offset. Free Z movement unavailable | Bound reset, actual published matrices/footprints |
| Collision / parent | Radius separation over accepted union of sets | Typed enabled/radius in metres | Pairwise native oracles and v2 publication |
| Relax / parent | Existing unpainted point Relax; incompatible paths visibly paused | Unavailable | Guard and historical Brush/Relax tests |
| Separation / parents | Priority, pair spacing, radius footprints, XY/3D | Explicit typed pair rules and priorities | Existing group oracles; v2 pair distance assertions |
| Cleanup / parent | Final accepted union, minimum neighbors/island | Typed enable/radius/count/planar settings | Cross-set neighbor fixture; registry validation |
| Visibility / parent and set | Hidden viewport only; disabled removes contribution | Per-layer visible/enabled | Native and MCP visibility/disable/Undo |
| Update / General | Manual pending state, explicit Update, real-time | `display.update_mode` | Native clicked spinner, Manual/live fixture |
| Display / General | Point Cloud, Proxy, Mesh, centres; existing retained implementation | Typed mode, shape and budgets | 20k navigation counters, v2 round trips |
| Output / renderer / Bake / Edit | Existing local actions and linkage preserved | No mutation tool | Exact Bake/stacked Edit and Scanline regression |
| Statistics | Cached requested/eligible/placed/removed/shown/errors | Diagnostics, configuration and actual publication receipt/export | Read-only snapshots before/after; matching digests |

Native controls not newly exercised end-to-end in this campaign include every individual Analyzer assignment, falloff graph and source editor dialog permutation. Their bodies are reused and bindings are captured per owner; this is preservation evidence, not a claim of exhaustive clicking. Arbitrary DPI, renderer and artist-scene combinations remain qualification work.

## Typed settings and operations

Plan schema **1.0** retains its previous legacy placement policy and protected-region restrictions. Schema **2.0** explicitly chooses shared placement policy, supports protected holes, normalizes every omitted setting before approval/digest, and rejects unknown fields or unsupported combinations. Bounds, units, enums and defaults come from one registry shared by Pydantic tool schemas, validators and the host adapter.

All layers/IDs/settings are attached before final solving. Underfill, counts, footprint checks and transform digest refer to the same final published rows. Requested candidates, placed plants, displayed instances and cloud samples remain separate quantities. A source tilted in X/Y uses a conservative 3D bounding radius; movement expands the allowed-mask margin. This can intentionally underfill; `allow` or `reject` is explicit.

Nine tools: connection status, scene context, validate plan, apply plan, operation/controller status, diagnostics, viewport capture, configuration and execution-record export. Resources: `cyrus://workflow`, `cyrus://plan-schema` (v1), `cyrus://plan-schema/2.0`, `cyrus://capabilities`.

The existing local approval, fresh-scene revisions, idempotency, Undo checks, scope ownership, cancellation and bounded capture remain. Limits: three sources/layers, 2,000 aggregate candidates, six exclusion references per layer, three pair rules, two successful candidates and two captures per enrollment. No remotely supplied code, filesystem paths, renderer actions or arbitrary Max properties.

## Future ML foundation

`cyrus.execution/1.0` contains a versioned context snapshot, context/normalized-plan digests, receipt, actual transforms/source identities, units, producer version and generation lineage. Export recomputes the layout digest and count; parameters alone are not treated as executed results. IDs belong to that published generation; no cross-generation correspondence is inferred.

`cyrus.correction/1.0` validates explicit correction lineage. Whole-layout replacement and parameter changes cannot invent per-instance labels. The contract is available to future collectors; artist corrections are not automatically recorded or uploaded.

Records explicitly set training eligibility false and consent to null unless a separate correction record references consent. This delivery has no model, inference, training, dataset splits, automatic scoring or image interpretation. Exports are operational evidence only, capped at 1.5 MiB and available for the current owned generation in the current host session.

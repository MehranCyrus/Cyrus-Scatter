# Recipe and settings format 2 — orientation

Scatter 0.83.0 extends the [format-1 recipe contract](../recipes-0825/FORMAT.md). The static-data ownership, complete-save rules, role binding, metre normalization, native Paint sidecars, security bounds and import transaction contract remain applicable.

New writes use `formatVersion: 2`, and native recipe/settings capabilities return 2. Recipe `evaluationContract` remains `CyrusUnified1`, `sceneSchema` remains 58 and `hostYear` remains 2027. The complete settings object now has **234 fields**. The six additions are:

| Field | Stored type / meaning |
| --- | --- |
| `orientationMode` | Integer 1 Random, 2 World direction, 3 Look at target |
| `orientationBlend` | Number 0–100; preferred-up angular blend |
| `orientationX`, `orientationY`, `orientationZ` | Dimensionless numeric world direction components |
| `orientationTarget` | External node role or null; required in active Look at target mode |

The existing `alignNormal` field remains independent. A zero vector is invalid in active World direction mode. Each layer/area/root settings object includes dormant fields too. Target binding is explicit; no transient node handle or evaluated target position is serialized as the target identity.

Numeric Transform presets append five numeric values (mode, blend and XYZ direction) to their existing 29-value layout. They do not replace destination target references. Applying mode 3 requires a valid existing destination target and rejects before mutation otherwise. Complete recipes carry that target role normally.

## Narrow format-1 read

The immediately preceding delivered format 1 remains readable through an explicit, strict conversion. Require its original complete field count and absence of new fields; add Random / 100% / +Y / null-target defaults, then validate the entire format-2 document. Numeric Transform presets similarly receive only these neutral numeric defaults. Unknown versions, extra fields and incomplete old records fail. Conversion does not overwrite files or change native Paint bytes, role records, owner IDs or file hashes used by thumbnail presentation metadata. Saving the converted document writes format 2.

This supports the recently delivered presets/examples. It does not revive retired scene schemas or old MCP plans. Scene schema 58 receives a separate appended orientation parameter block; existing parameter IDs are unchanged. Scene reopen, full authored recapture, new recipe import and numeric preset Undo/Redo are covered by the [I04 receipt](I04_0830.md).

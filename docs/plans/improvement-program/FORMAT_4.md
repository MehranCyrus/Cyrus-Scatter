# I06 persistence contract — formats 4 / 3

Scatter **0.85.0**, scoped-qualified in [the I06 handoff](I06_0850.md). Scene schema stays 58: a new parameter block is appended after the variation block, without renumbering preceding saved fields. Native grid capability is 1. The complete recipe and numeric settings formats change independently of the scene schema. See [the grid contract](I06_GRIDS.md) and [execution ledger](PROGRESS.md) for actual acceptance.

## Authored placement settings

| Field | Type / default | Meaning |
| --- | --- | --- |
| `placementMode` | Integer, 1 | 1 Surface random, 2 Rectangular, 3 Staggered, 4 Hexagonal |
| `gridColumnWU` | World distance, 100 scene units | Column pitch; nearest-neighbor pitch in Hexagonal |
| `gridRowWU` | World distance, 100 scene units | Rectangular/Staggered row pitch; inactive for Hexagonal |
| `gridOriginXWU` | World distance, 0 | World XY lattice origin X |
| `gridOriginYWU` | World distance, 0 | World XY lattice origin Y |
| `gridHeading` | Float degrees, 0 | Lattice heading around world Z |
| `gridJitter` | Float percent, 0 | 0–100: independent displacement up to half a pitch along each lattice axis |

The layer owns these fields. Paint Areas remain receiver-bound coverage on that layer. Count/Density and accepted-target/refill settings remain authored for a later switch back to Surface random; they do not determine a grid's population. Independent source assignment, source weights, transforms, Paint, masks, orientation, Edit and spacing keep their existing owners. The grid origin is explicit world space; importing to another scene does not automatically move it to the receiver's bounding box.

Complete recipe format/capability **4** has **242** captured settings. All seven fields are saved in every complete settings record. The four world-distance fields use the existing recipe unit conversion; heading and jitter do not scale. Existing supported Paint payloads and guarded unsupported-data behavior are unchanged. Candidate caches, copied terrain, projection acceleration data, native snapshot objects and viewport buffers never enter a recipe.

Strict reads of formats 1/2/3 add neutral Surface random and the default inactive grid values. Formats 1/2 also preserve I05's original receiver-domain conversion; format 1 receives I04's neutral orientation defaults. An earlier-version document containing later grid fields is rejected. No original manifest or Paint attachment is rewritten during a read.

Numeric settings format/capability **3** extends the Population category from 8 to 15 values. Distances use its existing **metres** representation, so earlier numeric presets receive neutral Surface random and inactive one-metre column/row pitches. Transforms, spacing and curve categories retain their existing fields. Saved/Current/New seed remains a separate apply operation. Closed field/type/range validation continues; new formats are not accepted by earlier installed binaries.

## Runtime identity and binding

Grid cell identities occupy a disjoint positive signed-64-bit family. They encode generator mode, persistent receiver slot and signed column/row coordinates; they are neither compacted output indices nor hashes. Generator-local keys remove the receiver slot while keeping the full cell coordinate identity. Random channels combine those keys with the separate saved receiver variation domain.

The shared receiver transport accepts either the original random ordinal family or the new cell family. Existing random IDs and default random binding text remain byte-compatible. Exact numeric grid settings enter generation and authored-override bindings only in grid mode. Switching generator or changing its authored geometry rules rejects stale bound overrides through the existing explicit reset/restore contract.

A complete grid has no random prefix to refill. Authored Edit requirement inspection accepts its cell identities without converting them into a million-limited ordinal. The procedural schedule carries every projected cell at full integer precision. Geometry/settings changes remain binding-guarded; mask removal does not move the lattice or silently reroll surviving cells.

## Required acceptance

Native tests cover strict earlier-format reads, unknown/future fields, numeric category round trips, distances and complete Paint-bearing grid write/read. Host acceptance must also establish Copy/import, units, save/reopen, Undo/Redo, Manual/Live, actual UI handlers, failure retention and old example parity. Native success alone does not establish those host behaviors.

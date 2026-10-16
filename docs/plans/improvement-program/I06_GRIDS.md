# I06 / P06 — regular planting layouts

Baseline: I05 0.84.0, `f2bc8dd6bc831a71cc46b19a6cb91611d431928d`, pushed and verified. The active goal resumes P06. Substantial delivery **0.85.0** adds authored grid generation and cell identity; see [the completed scoped handoff](I06_0850.md). Preserve the exact 0.84.0 package and receipts. F01–F07/F09–F11 apply. B26 heap-pressure Undo stays open in I10/I11.

## Artist contract

Add a placement generator independent of source assignment: Surface random (existing default), Rectangular, Staggered, Hexagonal. Keep Random mix/Clusters/Bands as source-assignment choices, so grids can still use Bands and existing masks. Analyzer anchor/edge-row modes need explicit exclusion from grid generation; do not silently mix two position generators.

Grids use an explicit **world XY origin and heading**, with world-unit spacing. Their origin never follows receiver/include bounding boxes. Project each cell vertically onto the highest world-Z hit of its own receiver. Shared-edge ties choose the lowest evaluated face index. Vertical faces with no XY footprint contribute no hit; an entirely vertical receiver reports an unsupported projection instead of silently returning random scatter. Separate overlapping receivers remain independent populations; spacing can remove duplicates across layers according to the existing rules. Folded/closed meshes may supply topmost grid hits, but this does not expand Paint's single-valued receiver-local XY contract.

Rectangular exposes column and row spacing. Staggered offsets odd rows by half a column, including negative row indices. Hexagonal uses one nearest-neighbor spacing, half-column offset and `sqrt(3)/2` row pitch; hide/disable independent row spacing in that mode. Jitter is cell-keyed and bounded within half a pitch on each axis. Zero jitter gives exact lattice positions. Source scale/rotation/choice use separate random channels, and changing masks does not reroll surviving unrelaxed cells.

Spacing determines the available population. Disable Count/Density and Accepted target/refill controls in grid mode, with an explanation. Masks and spacing thin the lattice; there is no extra random refill. Admit at most the existing one-million shared candidate budget. Exhaustion is a reported failed successor, not undocumented truncation. Enumerating a very large sparse bounding rectangle may exceed that budget; explain changing spacing/origin/domain rather than pretending the output is complete.

## Identity and integration

The existing receiver ordinal transport only supports ordinals below one million; a bounding-box-relative ordinal cannot identify a stable signed lattice cell. Introduce an explicit disjoint positive signed-64-bit cell identity, preserving all existing random IDs. Planned packing: marker bit 61; two mode bits 59–60; seven receiver-slot bits 52–58; biased signed 26-bit column/row coordinates in bits 26–51 and 0–25. Reject out-of-range coordinates before conversion. This encoding is injective over the admitted domain; never hash cells into an identity. Randomness still uses I05's separate receiver domain plus a receiver-independent local cell key.

Audit every identity consumer: generation/final movement in `max_bridge.cpp`, procedural schedule validation, orientation lookup, mesh/surface stochastic filters, `cyrusEditReceiverRequirements` and authored Edit/radius bindings. Preserve full 64-bit values; never convert a cell key into a million-limited ordinal or float. Grid settings enter generation/binding keys. Geometry/settings changes with authored overrides retain the existing explicit failure/reset behavior. Border masks may change eligibility but not origin or cell IDs.

Build a native numeric lattice/projector first, then connect its anchored candidates to the existing transforms, source assignment, masks, Paint, orientation, Edit, final radii and spacing pipeline. Avoid duplicating those stages. Use a bounded projected-triangle acceleration structure and count projection visits; reject excessive geometry/work atomically. Max evaluates/copies mesh data on its thread; numeric helpers own plain data only. Reuse receiver candidate caches for passive/UI and downstream-only changes.

Append saved settings without renumbering old parameters. Plan a complete-recipe successor with neutral Surface random defaults for recent formats; assess numeric preset fields separately. Copy/import must preserve grid settings and I05 policy. Record the final native capability/format/schema decision before host integration. No old receipt qualifies this new identity family.

## Acceptance and delivery

1. Independent analytic oracles: exact cell positions/counts, negative parity, hex nearest neighbors, rotated/translated origins, units, shared-edge ties, holes, stacked triangles, steep/vertical surfaces, finite bounds and identity injectivity.
2. Deterministic jitter and random-channel isolation; expanding a border/receiver footprint preserves common cell identities and unchanged unrelaxed rows when other inputs match. Separate receivers and copy/import retain their documented policies.
3. Native admission/work limits and failure retention; no partial result on over-limit or invalid parameters. Measure projection/preparation on a large tessellated mountain and sparse/stacked adversarial meshes.
4. Full Max 2027 matrix: Manual/Live, ordinary/animated relevant edits, UI choices and owner switching, Undo/Redo, save/reopen, Points/Empty, zero weights, Bands/curves, Paint, mesh/UV masks, slope/altitude, Relax, radii, independent collision scopes and authored overrides. Compare complete rows and work counters.
5. Actual controls at 100%/150%, heavy idle/panel measurements, failure recovery and retained-resource lifecycle. Keep B26 visible rather than counting a warmed heap as a fix.
6. Add actual-result orchard and staggered/hex examples with compatible scenes and thumbnails. Update artist/architecture/version/roadmap/catalog/website sources; verify the exact MZP, commit/push, then continue paths. EXE and the eight-example goal remain later acceptance.

Current status: **implemented, scoped Max 2027 qualification and MZP passed**. See [I06_0850.md](I06_0850.md), [qualification](QUALIFICATION_0850.json) and [package](PACKAGE_0850.json). The grid, copied-data snapshot, full identity transport, persistent formats and controls pass the documented final host matrix. Six procedural examples are available. Physical artist acceptance, B26 and the remaining goal remain open; Git checkpoint state is in [PROGRESS.md](PROGRESS.md).

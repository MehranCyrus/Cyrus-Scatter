# Cyrus Scatter 0.40 — persistent CS Edit identities

Save the scene and restart 3ds Max after installation. Native binaries now use `AminScatter/bin40`. The modifier's name and Class ID are unchanged.

## Fixed

CS Edit now associates edits with stable internal point identities rather than the list of enabled modifiers or the current row index. Turning a lower CS Edit off/on no longer invalidates the upper edits. Move/Rotate/Scale deltas continue to apply to the same incoming points.

Copies have persistent unique identities saved with the modifier. If a lower modifier that creates a copy is disabled, higher edits of that copy are suspended. Re-enabling its creator restores the copy and its edits. The same rule applies to points temporarily absent because of a lower Delete operation. New incoming identities pass through until edited; existing deleted records are not accidentally resurrected.

The status line reports suspended records. Selection, transforms, copy and Delete act on currently present points; absent records retain their edits. Copies of copies follow the same rules. Undo/Redo and saving while a creator modifier is disabled preserve identities.

Changing the base Seed or the base scatter placement/source layout still invalidates edits and requires Reset Edits. Reset is undoable, clears the chosen modifier's edits and discards its generated copies. Lower CS Edit copy/delete operations are no longer treated as changes to the base generation layout.

## Existing 0.39 files

The reader preserves old edits and converts them when their old input-index mapping can be established. A saved upper edit created with its lower edit disabled can be recovered automatically, including the old sticky invalid flag, when its recorded base layout matches. Matching old multi-modifier stacks with copies also migrate.

Ambiguous old mappings are retained without guessing. The status asks to restore the lower modifiers' previous states to recover. Changing those states retries migration. Do not press Reset merely to dismiss this message: Reset clears saved edits. Real base-layout changes are not automatically remapped.

Files saved by 0.40 use a new identity-storage chunk; keep the original file or a backup when testing. 0.39 cannot read the new edit records.

## Validation

- Reproduced the reported bug with 0.39 in a disposable scene and saved the invalid stack.
- All eight enable/disable combinations of three modifiers checked against expected transforms and counts.
- Lower copy/delete, upper edits, nested copies, suspension and reactivation verified.
- Save/reopen with lower creator disabled; copies and edits restored on enable.
- Seed invalidation retained; old invalid 0.39 edit recovered without Reset.
- Three-modifier regression: Undo/Redo, copy/delete, scale inheritance and save/reopen.

The existing editing UI and subobject mouse callbacks are unchanged. This is a stack identity fix, not a new interactive-render implementation. CS Edit remains intended for one Scatter controller per modifier; independently instanced CS Edit modifiers across different controllers are not supported.

Additional integration checks passed: existing scene layer counts 2688 / 3273 / 1436 unchanged before editing; Point replacement and PFlow received all 40 expected edited transforms; idle render signature stable; valid 0.39 three-modifier stack with copies migrated and toggled. Core C++ tests: 3/3 passed.

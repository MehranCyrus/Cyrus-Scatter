# 12 — Manual editing, persistent overrides, and CS Edit integration

**Status: proposed Cyrus behavior. Research basis: R0 §4.6. Official anchor: S09.**

## 1. Four distinct records

A generated candidate is not a manual object. An override modifies an identified candidate. A tombstone suppresses that candidate. A manual item exists independently of procedural enumeration. A pin is an explicit persistence/priority policy applied to a valid item.

ForestPack's documented Generate/Custom Edit workflow is a useful capability reference, but it does not establish the persistent-override model proposed here [S09]. Cyrus deliberately avoids requiring a destructive mode switch for ordinary refinement.

## 2. Override schema

```text
InstanceOverride
    target canonical candidate key
    override UUID / authoring revision
    enabled
    source override, optional
    transform override, optional
    transform mode: absolute-world / receiver-local / local-delta
    deletion state
    constraint policy: constrained / pinned
    random channel salts, optional
    orphan policy and last-known binding
```

A manual item has its own UUID and source/binding/transform fields but no required candidate target. A source replacement is not automatically a transform replacement.

## 3. Constrained override: the default

The candidate must exist in the generator domain and pass normal eligibility. The override changes selected properties before final projection, boundary, and collision tests. If new settings reject it, the override remains saved but inactive.

The inspector explains why: density, area, missing source, no surface hit, boundary, or collision. Restoring the old settings can reactivate the same edit because the target identity persists.

This policy is appropriate when the artist wants a procedural plant nudged while still respecting planting rules.

## 4. Pinned edit: deliberate artistic authority

Pinning materializes the edited item as an explicit obstacle independent of the current procedural density/coverage gate. It keeps the target key to suppress the procedural duplicate when that candidate also exists.

Pins bypass normal area/density eligibility but do not ignore missing assets, invalid transform values, or unresolved surface bindings. Their attachment policy determines whether they remain fixed in world space or follow a compatible receiver.

Pins enter the collision solver before ordinary candidates. Two conflicting pins remain present and produce a warning; one manual tree is not silently removed because another was pinned first.

A “Respect hard exclusions even when pinned” option is a separate stricter policy. Do not change the default implicitly when area order changes.

## 5. Tombstones

Deleting a generated item stores its canonical key in a sparse suppression set. It does not delete the source mesh or erase the surrounding paint. Changing preview density cannot restore it.

If a structural generator change creates a new identity epoch, the old tombstone becomes orphaned. Show a report; do not map it to the nearest unrelated new candidate automatically.

Deleting a manual item removes that independent record. Undo restores it with its UUID.

## 6. Transform spaces

**Absolute world:** remains where placed unless the artist explicitly rebinds it.

**Receiver-local:** follows the receiver's transform and compatible deformation through a saved binding/offset policy.

**Local delta:** composes against the generated transform; procedural movement still affects it.

The gizmo must display the selected mode. A user editing a tree in world space should not discover later that its adjustment was actually stored as a source-relative percentage.

## 7. Surface attachment

For attached movement, raycast onto the allowed receiver snapshot and save the resulting binding. A planar XY adjustment without reprojection is an explicit free-move mode. On topology changes, use the repair contract in chapter 05.

`Place on surface` is a command creating/repairing bindings. `Link to surface` is a persistent behavior. They are not synonyms.

A source pivot or Z-offset edit should not double-apply an already stored manual ground offset. Keep anchor binding and final source transform separate.

## 8. Selection and picking

Viewport draw indices map to canonical IDs in the currently displayed snapshot. A pick result carries that snapshot revision. If publication occurs during a drag, selection remains associated with canonical IDs, not new array positions.

Selection modes include visible preview items, all accepted instances, source/category selection, region selection, and manual/pinned items. A preview-hidden instance should not be uneditable merely because the display budget is low; an “all population” pick path can use a CPU spatial index.

Region selection has documented point-versus-bounds semantics. Selecting “inside” and selecting “touching” are different operations.

## 9. Gestures and Undo

A move/rotate/scale drag creates one authoring transaction. During the gesture, display temporary edits separately from committed state. Cancel restores before values. Commit writes sparse overrides and schedules constraint reevaluation.

The CS Edit adapter issues the same commands as the native UI and automation. It must not maintain an independent authoritative transform array disconnected from the core model.

Existing CS Edit data requires a migration adapter after its actual schema is inspected. The project context identifies the module, not a verified current data contract.

## 10. Reseeding selected properties

Store per-instance/channel salts for “randomize selected rotation,” “replace selected sources,” and similar commands. Changing a rotation salt does not affect tint or scale.

`Store transform` converts the currently resolved transform into an explicit chosen override mode. Warn that later procedural transform changes may no longer affect those stored components.

## 11. Attach and detach

Attaching layers or setups requires ID remapping where namespaces collide, source deduplication by explicit policy, and preservation of transforms across setup coordinate frames. Do not concatenate arrays and hope indices remain meaningful.

Detaching selected instances can create a new manual-only layer, a new procedural recipe with explicit subset filters, or standard Max instances. These are three different commands with different editability and memory consequences.

Baking to Max objects reports object count and asset/material dependencies before execution. Large conversions use cancellation and rollback, not a half-completed scene with an ambiguous success state.

## 12. Orphan recovery

An orphan manager lists edits whose candidates, sources, or bindings no longer exist. Available operations are keep inactive, restore compatible generator settings, explicitly rebind with a preview, convert to independent manual item using a saved valid transform, or delete.

Nearest-neighbor remapping is an optional assisted repair requiring a distance bound, receiver/category restrictions, and conflict resolution. It never runs silently on file load.

## 13. Cross-layer consequences

An edited tree's **final** footprint influences downstream grass. Constrained tree edits that become rejected do not export active occupancy. Pinned trees do. A temporary gizmo preview can show approximate downstream effects, but coherent final publication uses committed tree revisions.

## 14. Tests

Move one tree, change density, change source weights, reduce preview budget, move the receiver, change topology, replace the source, Undo/Redo, and save/reopen. Test both constrained and pinned policies. Verify that visible outcomes and stored override states match the documented contract, including inactive/orphaned edits.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S09]: https://docs.itoosoft.com/forestpack/forest-plugin/item-editor

# Recipe authored data — 0.87.4.4

User scope: save and restore Cyrus Edit and prepared interactions in Library recipes; Max 2027 host tests only; distinct SDK payloads for Max 2024/2026/2027 in one EXE. Do not install artist profiles. Preserve the 0.87.4.3 receipt and unrelated work.

## Ownership and wire contracts

Recipe format 9 adds a closed authored section. Existing v8 recipes convert to an empty section; prior supported conversions remain. Numeric settings remain independently versioned. Layer-owned interaction settings, accepted definitions and custom collider node roles are captured. Prepared definitions are stored once per identical source definition. New source/owner IDs are mapped on import. Referenced custom colliders travel through the existing static asset graph. Serialized definitions never contain deformed per-instance meshes.

Native Edit export serializes sparse authored overrides and nondefault ordering, with explicit source lineage, stable candidate identities, clone identities, deletion, physical units and transforms. Native import seeds new modifiers and consumes their data at first candidate binding, before downstream contact and atomic publication. Local-instance deltas adapt to the imported base transform; unmatched historical rows remain inactive with their source evidence. Clone IDs are fresh per import and shared across its modifier stack. Edited recipes use saved variation. No settings change or discarded edits merely to pass the old guard.

## Resources and failure

Keep the existing finite recipe/manifest and heap admissions; fail oversized/invalid payloads explicitly. Bulk Edit traversal and replay stay native; script handles bounded layers, source mappings and UI. Import joins the existing single Undo transaction, stages assets/owners/modifiers, and must calculate completely before success when authored Edit data is present. Failed capture leaves the scene unchanged. Failed import rolls back imported assets/authored state and retains previous complete publication. Browsing does not rebuild the scatter.

Scene parameter layout remains 63. Native Edit storage advances to 3 for unbound/local recipe records, retaining storage-2 and legacy readers. Recipe and Edit capability guards advance to 9 and 3 for the new transport. Independently versioned Analyzer/content remain separate. The user-selected patch version takes precedence over a larger feature label.

## Acceptance

Native closed-format validation, malformed/reference/budget cases and old v8 compatibility. Max 2027 exact-pair tests: capture does not mutate source; moved/rotated/scaled/copied/deleted instances survive fresh import; repeat imports have fresh ownership and clone IDs; custom collider and prepared grass definitions restore; contacts recalculate; same-scene and changed terrain/unit cases have explicit results; selected subset does not leak other layers; one Undo/Redo, save/reopen and failed import retention. Exercise the actual Library save/load workflow. Build and package distinct 2024/2026/2027 pairs, validate EXE/archive identities, and label older hosts as not runtime tested. Deliver runnable Max 2027 MZP as well as the requested EXE.

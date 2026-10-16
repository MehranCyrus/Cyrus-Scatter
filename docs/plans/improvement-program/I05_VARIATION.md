# I05 â€” explicit copy/import variation contract

Baseline: delivered 0.83.0, implementation `a814513b3cb1d99640fe5b5c9886dcfc95c73a77`, ledger checkpoint `b9cd29992cbfb698d54ecdb9f436e6dbb270e0a6`. The active goal authorizes I05. Substantial delivery **0.84.0** adds an artist-visible copy/import choice and a persisted random-domain field. This plan is preserved alongside [actual delivery evidence](I05_0840.md); B26 remains open. Contracts F01/F02/F04/F05/F09/F11 apply.

## Current source findings

`effectiveSeed` combines `randomSeed` and `procSamplingSalt`. Receiver-local sampling also hashes `procReceiverIDs[slot]`; that salt drives position, source, transform, density, diversity and Band channels. Mesh density and surface filters separately consume the same receiver identity. Candidate IDs encode saved receiver slot and ordinal; owner IDs and source correspondence are separate namespaces. Whole-scale/Paint/falloff stages also use candidate/seed inputs. Preserving only Seed is insufficient.

Layer copy currently retains correspondence IDs and seeds; recipe Add/New setup remaps source/receiver IDs, changing variation even when the authored seeds are saved. Import already creates fresh owners/Edit keys and remaps relationships. There is no existing replace-layer import, so a target-layer variation policy has no meaning for Add/New setup. Numeric Amount settings presets have a separate seed-only scope.

Audit layer copy, Paint Area copy, recipe Add/New setup, numeric settings presets, Max node Copy/Instance and scene reopen/merge. Do not silently change existing scenes' random sequence or introduce source-reordering guarantees. Native scene cloning needs an actual baseline witness before selecting a correction. Autodesk documents [`on clone original`](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.html) on the new scripted instance; this does not prove child-reference or Undo behavior in Max 2027.

Baseline witness: owned Max 2027 profile `foundation-roadmap-variation0840-baseline-20261016-01`, 0.83.0 pair, `clone-baseline-*.json`. Max Copy created distinct root/child objects, an empty transient publication, and independently rebuilt identical complete rows; Instance shared the root as intended. Copy retained owner-local ID strings and Edit keys in the new independent graph. Do not gratuitously remap those IDs in native Max Copy, because existing copied Edit data uses them. Named layer Copy has a fresh owner/Edit key, so it can safely remap correspondence while preserving separate random domains. No `on clone` change is justified by this baseline.

## Intended choices

- **Copy layer: Same variation** by default, or **New variation**. Same preserves seed inputs and saved receiver random domains; new creates new domains once during the transaction. Both create independent owned data, preserve complete Paint/settings and remap relationships. Redo restores the chosen domains, never rerolls them.
- **Recipe Add / New setup: New variation** by default, preserving the preceding import behavior; optional **Saved variation** preserves the recipe's domains. Existing destination layers stay untouched. No misleading Keep target choice is shown for newly created layers.
- **Numeric Amount presets:** distinguish applying the saved seed, keeping the current seed, or generating a new seed where meaningful. They do not contain a full cross-scene arrangement; do not label seed-only behavior as exact saved variation. Transform/curve/spacing presets do not need seed choices.
- **Max Copy versus Instance:** preserve Max's explicit ownership semantics. A real copy must not borrow publication or mutable authored data; an instance intentionally shares the same base object. Inspect baseline clone/merge behavior before altering it. Do not reseed during load, UI binding, redraw or Undo/Redo.
- **Unsupported authored edits:** named layer copy rejects authored Scatter Edit or selected-layer per-instance radius data before mutation until I13 provides transfer. Max object Copy remains the complete-setup duplication route. Do not silently omit these records while promising the same arrangement.

## Data and algorithm boundary

Add a bounded saved receiver random-domain string array, separate from correspondence IDs, in an appended parameter block. Existing schema-58 scenes with an empty new array resolve their effective domains from their saved receiver IDs, preserving current output. Fresh receiver enrollment adds one domain once. Validate alignment/count, 1â€“256 identifier characters (`Aâ€“Z`, `aâ€“z`, digits, `_`, `-`, `.`, `:`) and uniqueness; incomplete nonempty arrays fail rather than reroll.

Keep the sampler and its conditional stability contract unchanged. Feed effective random domains to sampling, mesh-mask and slope/altitude stochastic acceptance; include domains in relevant generation/binding keys. Allocation continues to use saved receiver slots/ownership correspondence. No new per-candidate string hashing, RNG initialization, or display work is required.

Complete recipes must preserve domains before correspondence remapping. Proposed recipe format/capability 3 extends format 2 by this field; strict reads of immediately supported formats 1/2 derive domains from their original receiver IDs before validation. Existing Paint bytes/role bindings remain unchanged. Numeric settings format can stay 2 if the seed policy is an operation option rather than saved preset data. Keep old receipts unchanged and document this narrow conversion rather than restoring retired scene schemas.

## Conditional matching and acceptance

Saved variation on identical evaluated terrain, receiver slots, sources/order/weights, masks, quantity/quotas, Relax and acceptance inputs must reproduce complete transforms, source choices and surviving candidate ordinals. Fresh ownership/correspondence IDs remain independent. With changed terrain or models, only saved random inputs are promised. Different topology, area quotas, source order/weights, masks, geometry-dependent Auto Radius or preceding collision layers may change the accepted result. Do not implement rendezvous source selection or claim reorder invariance.

Test copy, Add/New setup, distinct compatible receiver objects, incompatible Paint binding rejection, receiver insertion, Fixed Total versus uncapped Density, source insertion/removal/reorder/zero weights, Relax, individual random channel edits and thread-count reproducibility. Include copied Paint Area settings, Manual/Live, single Undo/Redo, save/reopen, failure rollback and fresh source/receiver/owner identities. Compare every matrix/choice plus calculation/preparation/upload counters. Measure passive choice/browsing work and a representative heavy copy/import setup. Check actual controls at 100%/150% Max UI scale and keep physical input/DPI limits explicit.

After applicable native/generated/Python and matched Max 2027 checks, update current docs/examples, build the exact MZP, commit/push and continue to I06 grids. No I05 completion or 0.84.0 qualification is claimed here.

## Discovered host memory boundary â€” unresolved

The owned 60,000-to-90,000-row stress case can lose its Undo record when Max grows the MAXScript heap under pressure. An A/B witness reproduces this in the frozen delivered 0.83.0 pair and the 0.84.0 candidate. Both retain Undo when enough heap space remains. This is not an unconditional heavy Undo pass. No product code clears the Undo stack, and no runtime or user-profile heap setting was changed by these tests.

Autodesk's [Max 2027 garbage-collection documentation](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Language-Reference/Variables-Assignment-and-Scope/Memory-Allocation-and-Garbage/GUID-CA7ABB4B-6CB6-47B7-903D-84D2F45D993D.html) explains that automatic collection may flush Undo if its initial collection cannot free sufficient memory. The observed heap growth plus cleared history is consistent with that mechanism; it is not a native GC trace. Track the outstanding allocation/memory work in I10/I11 and retain the failed receipts. Do not claim this boundary fixed merely because a warmed, larger heap later passes.

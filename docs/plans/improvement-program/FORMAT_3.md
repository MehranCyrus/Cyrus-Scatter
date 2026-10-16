# Recipe format 3 â€” receiver variation domains

**0.84.0 contract; scoped delivery evidence is in [the I05 handoff](I05_0840.md).** This extends [format 2](FORMAT_2.md), preserving its static authored-data, explicit role binding, metre normalization, Paint sidecars and transaction rules. It does not add asset bundling, animated-controller transfer, authored Edit transfer or per-instance-radius transfer.

Complete recipe writes use `formatVersion: 3`; the native recipe capability returns 3. The evaluation contract remains `CyrusUnified1`, scene schema remains 58, and host year remains 2027. Numeric settings presets retain format/capability 2. The scene adds a separate parameter block after the existing blocks; earlier parameter IDs are unchanged.

## Saved data

The complete settings object has **235 fields**. The new `procReceiverVariationIDs` string array is aligned with the saved `procReceiverNodes` / `procReceiverIDs` history, including inactive slots. It has at most 128 entries. Each domain contains 1â€“256 ASCII identifier characters (`Aâ€“Z`, `aâ€“z`, digits, `_`, `-`, `.`, `:`), and domains are unique within the owner. A complete format-3 recipe must have one domain for every saved receiver identity.

Receiver correspondence IDs identify scene bindings; variation domains salt the existing deterministic receiver-local random channels. They are different roles. Source rows, source correspondence, owner IDs, Edit keys, candidate ordinals and accepted output rows remain separate identities. `sourceRowIDs`, `procSourceIDs` and `procReceiverIDs` must each contain unique, nonempty strings bounded to 256 characters; source-slot references may repeat when their corresponding source is reused.

In a current-schema scene, an empty new array means use the existing receiver IDs as the effective domains. This preserves the preceding sampler inputs. A nonempty partial array fails instead of generating replacements. Adding a new receiver enrolls its domain once; browsing, reopen, redraw and Redo never reroll it. Save freezes any missing correspondence metadata for an actual placement layer without initializing unrelated root metadata or authored curves, evaluating geometry, or calculating scatter. The ordinary prepared-layer path still initializes its existing curve and correspondence data as before.

The candidate/mesh-mask/slope-altitude stages consume the effective domain. Receiver allocation continues to use saved slots and correspondence. Domain changes participate in the affected receiver's cache key and binding **value**; the receiver's binding key remains unchanged. A nondefault domain therefore invalidates stale authored candidate/radius bindings. Default domains preserve the preceding binding text. Treating a new domain as a new receiver key is incorrect and was rejected by a focused host witness during implementation.

## Copy and import operations

| Operation | Default | Alternative | Persistent result |
| --- | --- | --- | --- |
| Named layer Copy | Same variation | New variation | Fresh owner/Edit/correspondence IDs in both cases; retained domains for Same, fresh domains for New |
| Complete recipe Add layers | New variation | Saved variation | New layers with fresh ownership; existing destination layers remain intact |
| Complete recipe Create new setup | New variation | Saved variation | Independent root/layer/Area graph with explicit external bindings |
| Numeric Amount preset Apply | Saved seed | Keep current seed / New seed | Changes only its supported numeric settings; it does not contain or replace receiver domains |
| Native Max object Copy / Instance | Max semantics | â€” | Copy is an independent graph with retained owner-local IDs; Instance intentionally shares the graph |

The script operations use `variation:#same` / `variation:#new`; numeric Apply uses `seedPolicy:#saved`, `#current` or `#new`. Choices are transient UI operation options, not fields added to numeric preset files. New entropy is chosen once during the operation and retained by Undo/Redo. No meaningless Keep target variation option is offered for an import that creates entirely new layers.

Named layer copy preserves supported Paint Area settings and independent native Paint data. It rejects authored Scatter Edit and selected-layer radius overrides until I13 implements transfer. Complete recipe save retains its existing analogous guards. Max object Copy remains the complete-setup duplication route. Any failure after a copy/import transaction begins must restore the prior graph and publication.

Saved variation reproduces complete rows only when evaluated geometry, receiver slots, quantity/quotas, source order/weights, masks, Relax, source dimensions, acceptance and preceding collision context also match. Different models/terrain may produce different accepted output from the same random inputs. No source-reordering or arbitrary topology correspondence guarantee is added.

## Strict preceding-format reads

Formats 1 and 2 remain readable for the delivered examples and recent saved recipes. Require their exact preceding field sets, reject mixed/new fields and derive the new domains from their **original** saved receiver IDs. Format 1 also receives the neutral orientation defaults documented in format 2. Validate the entire converted document before applying it; incomplete or unknown versions fail.

Conversion does not rewrite original files, Paint payloads, thumbnails or manifest hashes. Saving a converted document writes format 3. This is not migration of retired scene schemas. A format-3 document containing distinct domains but duplicate correspondence IDs is invalid and cannot merge independent bindings through the remap table.

## Acceptance limits

Use the [execution ledger](PROGRESS.md) for exact pair identities and actual passes; this contract is not a release receipt. B26 remains open: host heap growth under pressure can flush Undo in both the preceding delivery and the candidate. Warmed-heap passes do not close that issue, and no artist heap preference was changed as a workaround. Physical DPI/input, other renderers and the remaining I05 matrix retain their explicit status in the ledger.

# Persistent support-region registry

`region_registry.h/.cpp` adds portable support identity and authored region metadata without changing `Region`, `Placement` or the arrangement API. The inspector's one-based IDs describe one snapshot. A registry maps those transient IDs to monotonic 32-bit document IDs before placement, selection or exclusion policy uses them.

The registry is an additional identity layer, not a cavity recognizer. `SupportRole`, `label` and `compartment_label` are authored semantic metadata. Computed `open_above` and minimum clearance retain the inspector's sampling meanings; they do not infer doors, accessibility, complete compartments, exact support polygons or physical fit.

## Ownership and atomic integration

`RegionRegistry` is immutable when published through `shared_ptr<const RegionRegistry>`. Each record shares immutable `RegionShape` data, so copying the registry to edit a label/policy does not copy potentially large cell arrays. Exact matches reuse their previous shape pointers. A changed shape is a new owned snapshot; retained Undo versions legitimately keep their previous shape buffers.

Host sequence:

1. Capture and inspect the complete furniture support scope, including excluded surfaces.
2. Supply every captured region and its persistent source-key scope to `plan_regions(previous, observations, settings)`.
3. Read `plan.required_new_ids()`. Admit 32-bit range and reserve exactly that many IDs from a host allocator whose high-water survives Undo and failed publication. Skip reservation and pass zero when no IDs are needed.
4. Call `finish_regions(std::move(plan), first_reserved_id)`. It returns a complete immutable registry, observation-to-stable bindings and retired IDs. Apply bindings to the captured `Region.id` values.
5. Keep all current regions, map semantic policy to `RegionPlacementRule` rows, and run placement with stable region IDs. Persist the successor registry, placement rows and real source/output references in the same atomic host publication/Undo transaction.

Failure at any stage leaves the previous registry and its shared shapes untouched. A reserved span is never returned to the allocator after failure. A plan is move-only and consumed by finalization, including a failed finalization; retry by planning again. Registry state by itself cannot prove that a host allocator survived Undo, so that allocator is an explicit integration precondition, separately tested with simulated Undo/failure.

Do not remove excluded observations before reconciliation: that would retire their IDs and discard policy. Once integrated, use `RegionRecord.semantics.excluded` as the authoritative exclusion or maintain an explicitly synchronized external view; do not leave two independent exclusion owners.

## Identity representation

A shape contains:

- The inferred uniform cell size in integer 0.001 mm units.
- Sorted, unique persistent source keys.
- Sorted, unique supported-cell centre XYZ coordinates in the same 0.001 mm units.
- Bounds derived from those centres and half the cell size in XY. These are sampled bounds, not exact mesh extent.

Only supported geometry contributes to identity. Cell usability, upward clearance, density, labels, exclusion and style policy do not. Adding an overhead obstacle can change usability/clearance while retaining the same underlying support ID.

The host must supply persistent document source keys, with real references as authority. Raw pointers, array order and current Max node handles are not registry identities. The initial host may use the sorted keys of all selected furniture roots for every observation. This is conservative whole-assembly source scoping: replacing or adding a root can rename every support. Per-surface ownership can improve locality later without claiming that this version derives it automatically.

Equivalent retriangulation and independent source/cell/observation order retain identity at the fixed quantization/resolution. Fingerprints accelerate lookup, but full canonical geometry/source equality confirms exact matches; fingerprint equality alone never authorizes identity reuse.

New IDs allocate in deterministic canonical source/geometry order, not observation-array order. Bindings return sorted by observation ID; active records serialize sorted by stable ID.

## Exact and conservative matching

Exact matching is the default. Geometry changes, grid-origin changes, resolution changes or source-scope changes that alter the canonical shape receive fresh IDs. Existing protected rows cannot silently follow an unrelated new support because its transient inspector index happens to match.

An explicit `allow_overlap_matching=true` enables an additional conservative pass. A pair must have identical nonempty source scopes and cell size, minimum/maximum support-height change at most the configured value (never above 0.01 mm), sampled bounds intersection-over-union at least the configured threshold (never below 98%), and canonical cell intersection-over-union at least that threshold. XY centres must still match exactly at 0.001 mm; Z matching permits the admitted small height tolerance.

A match is accepted only when it is the sole eligible candidate in both directions. Ambiguous candidates, splits, merges, larger edits, shifted sampling grids and insufficient overlap receive fresh IDs. There is no nearest-surface fallback. This pass preserves semantic identity for a narrow set of small edits; it does not reposition locked props or certify that they still fit. Exact placement validation and protected-anchor/region membership checks remain required.

## Retirement, Undo and allocation

Only active previous records can match. An absent support is retired; if equivalent geometry returns after a later update, it receives a new ID. The registry retains its highest allocated ID even when all records are retired. No ever-growing tombstone geometry list is needed.

Undo can restore the original registry and original support identity. The host allocator must remain above every ID already issued in the session/history. Creating a new support after Undo therefore cannot reuse an ID issued by the undone successor. `finish_regions` checks that its reserved first ID exceeds the prior registry high-water and that the complete span fits `uint32_t`; the host's non-Undo high-water is what additionally prevents reuse across restored older registries.

Root/document allocation and serialization must persist that allocator separately from ordinary Undo state. A shared 64-bit document allocator may be used, provided the 32-bit region span is admitted before reservation. Exhaustion is an explicit failure, never wraparound or ID hashing.

## Semantic fields

Each stable record retains authored label, compartment label, support role, allowed asset-category mask, density multiplier (0–4), stacking permission, exclusion and front direction. Empty labels are permitted; nonempty labels must be printable UTF-8 of at most 512 bytes each. A zero category mask means no allowed categories. The front vector must be finite, horizontal and nonzero.

The registry stores policy and does not run placement or change collision scope. The native arrangement engine accepts an explicit `RegionPlacementRule` span with the corresponding fields, and applies masks, density, stacking, exclusion and front direction during generation and protected-row validation. Host integration must map every applicable current record explicitly; omitted rules use neutral defaults. Keep excluded regions in the input: exclusion suppresses new candidates, drops regenerated unprotected props and rejects conflicting protected props without disguising the conflict as a missing support. Authored labels and support roles remain descriptive metadata, not inferred placement constraints. New records use neutral defaults; matched records retain policy while computed clearance/open-above measurements update from the current inspection. See `PLACEMENT.md` for exact policy/selective semantics and test coverage.

Policy ownership is currently sampled **anchor membership**. `RegionShape` contains cells and sampled bounds, not an exact support polygon or a physical keep-clear volume. The concrete fit query separately checks the complete contact footprint and requested edge clearance against all captured furniture support polygons at the same height, using its global support union and fixed quantization. It does not subtract excluded records or apply a category mask to that polygon union.

Where touching coplanar areas remain distinct records A and B, a footprint anchored in allowed A may extend onto excluded B while remaining fully supported and collision-free. For example, a 20 mm wide footprint centered at X=95 mm can span X=85..105 mm across their shared X=100 mm border. This does not permit a footprint to span a real unsupported gap or hole: the independent full-support query still rejects that geometry. It means exclusion controls anchor ownership, rather than certifying complete footprint confinement to the record's sampled area.

Use an explicit independent collision obstacle volume above the support plane when the artist needs a physical keep-clear zone. The region registry neither creates that obstacle nor changes the setup's collision scope; ordinary collision/contact-tolerance rules apply. A flat sheet coincident with the support plane is not a reserved volume. Exact per-region footprint masks and their own edge insets would be a separate future query/geometry feature if required; they are not implemented by current registry policy.

## Bounds, encoding and limitations

Hard ceilings are 4,096 active regions, 1,000,000 canonical cells, 32,768 total source-key references, 64 MiB registry admission/encoded bytes and 50,000,000 charged work units. Settings can lower these values. Counts and byte estimates are checked before observation/decoder array growth. Dense ambiguous overlap workloads stop at the work cap. Bounds cover cardinality and charged operations; they are not measured process-memory or UI-latency guarantees.

The portable `CAREG001` schema-1 format uses explicit little-endian integers, IEEE-754 double bits, lengths and Boolean bytes. It never dumps pointers or compiler struct layouts. Decode rejects truncation, trailing bytes, oversized counts, duplicate IDs/geometry, invalid source keys/cells/semantics, invalid versions and malformed measurements. Canonical bounds are reconstructed and validated. The format is not an authenticity or tamper-proof envelope.

At peak, old registry, canonical observation staging and a successor can coexist. Exact matching drops newly captured duplicate shape buffers and shares old ones. Encode/decode add an independent bounded byte buffer. Host document/Undo accounting must include retained changed shapes and encoding buffers.

No guarantee is made for exact identity under arbitrary topology, unit/frame changes or resolution changes. Conservative rejection and explicit rebinding are valid outcomes. The module does not repair imported geometry, infer per-source triangle ownership, recognize compartments or authorize a stale protected placement merely because an ID matched.

## Native verification

Eight suites cover actual plane retriangulation and reordered independent sources, canonical allocation order, shared shape reuse, semantic/exclusion persistence under changed clearance, retirement/reappearance, simulated Undo and burned failed reservations, exact-only default, opt-in unique overlap, excessive/ambiguous edits and splits, source replacement, uint32 exhaustion, deterministic byte round-trip, corruption/truncation/trailing data, invalid UTF-8/metadata and hard budgets. Tests derive known cell geometry and allocator histories independently.

The pinned MSVC `/W4 /permissive-` direct build passed all eight suites (`build/region-registry-agent-02`). Root CMake/SDK/document/host integration and exact frozen receipts remain separate acceptance gates. No Max launch or computer use was performed for these tests.

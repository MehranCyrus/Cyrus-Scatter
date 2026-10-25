# M03 — Installed model metadata discovery

24 October 2026. **Partial M03 implementation, scoped qualification only.**
O66/O70/O71 gain evidence; preset/recipe discovery, imports and complete operation
acceptance remain open. This is source MCP development, not a packaged release.

## Contract and ownership

The native scene-task dialog provides **Share / refresh installed plant catalog**
and **Revoke catalog sharing**. This separate local action shares names,
categories, stable catalog IDs, declared scene hashes/bytes and measured preview
hashes/bytes. It never shares personal recipes, content paths or preview pixels.
Catalog strings are untrusted data. No remote operation can enable sharing.

`MaxHost.installed_model_catalog()` reuses the shipped `CyrusGallery.dll`
`IndividualModelCatalog.Load` and `CyrusRecipeBundledDirectory` /
`LibraryLocation` resolution. The loaded assembly location/version must match the
loaded script package. No independent library directory scanner, importer, asset
store or arbitrary filesystem API is added. The separate shared-library SL01–SL09
planning document is not implemented by this increment.

The existing loader bounds the catalog to 2 MiB and 104 entries, rejects linked or
escaping content paths, checks scene existence and declared length (at most 2 GiB
each / 16 GiB total), and hashes existing bounded JPEG previews (33 bytes–2 MiB).
**It does not hash model scene contents or inspect materials/dependencies.**
Discovery neither opens those model scenes nor evaluates their geometry.

The host returns seven bounded scalar fields per entry. The Python service
validates a closed metadata contract, sorts by catalog ID, admits at most 256 KiB,
and holds a frozen in-memory grant. `snapshot_sha256` hashes canonical admitted
metadata, **not the original catalog file bytes**. Asset references are bound to
that snapshot and entry; catalog IDs remain visible for user explanation.
Local refresh always issues a new `library_id`, even for identical content.

`library_search(scope_id, library_id, query, category, offset, limit)` searches
only that grant: case-insensitive substring across ID/name/category, exact
category, offset 0–104, page size 1–12, response at most 32 KiB. It returns
`next_offset`, total matches and up to twelve category labels with an explicit
omission count. Names/categories can be found through paged entries when the
category list is truncated. Preserve query/category while paging.

`library_inspect_entry(scope_id, library_id, asset_ref)` explains the evidence:
dimensions and physical source units unmeasured; materials, renderer/proxy support
and external dependencies unchecked; `ready_for_import` and `use_supported`
false. The installed JSON also contains declared `dimensions_cm`, but the current
shipped managed entry API does not expose them. This increment does not turn
those declarations into measured geometry or verified scale.

Both tools consume the normal 24-call scope budget. They perform no filesystem
access, geometry fingerprint/evaluation, selection, solve or redraw. A catalog
snapshot remains historical metadata after content changes; it is not a live
readiness assertion or executable import token. Local re-share is required to
refresh it. A future approved import must independently revalidate exact model
bytes, dependencies, physical units, compatibility and effects.

## Invalidation, failure, Undo and resource behavior

- Sharing requires an idle connected scene task. It changes no task roles, scene
  revision, write approval, native object or Undo entry and does not reset reads.
- Refresh revokes the previous grant **before** loading. Validation failure leaves
  no old grant available for accidental reuse. Native exceptions are replaced
  with a generic catalog-repair message; local diagnostics may retain details.
- Revocation, disconnect, reset/open, unrelated enrollment and panel close clear
  the grant. The explicit same-task design handoff retains it while changing the
  scene scope; callers must use the new `scope_id`. Old grant IDs reject.
- Only metadata is retained; native model/scene objects and managed catalog
  objects are not kept as import authority. No Undo is needed because no scene
  mutation occurs. Existing Undo/publications remain authoritative.
- Local share currently invokes the existing synchronous managed loader on the
  host thread. Remote reads are cached. Bounded input sizes do not establish a
  measured peak-memory or long-session responsiveness result. Moving file-only
  loading to a worker is a possible M12 improvement if measurement justifies it;
  no host API may run on that worker.

## Exact evidence

Owned run: `build/mcp-library-20261024-01`, Max 2027 PID **14364**, closed through
the verified owned-process transport. The artist profile/session was untouched.

- **432 tests passed in 38.63 s**, `offline.xml`, including 19 new catalog cases
  and the real SDK discovery contract, now **16 development tools / 7 resources**.
  Tests cover local-only grants, frozen reads without geometry/file reload,
  paging/filtering, unknown refs, bounds, malformed metadata, refresh failure,
  reset/revocation and unchanged read budgets.
- `host01/library-f7f200417be5432da30139d332534941.json`: real SDK plus native task
  widgets, installed content 0.86.7 with **96 individual model entries / 8 pages**,
  inspect/filter, unknown reference, refresh/old-ID rejection, revoke/read denial,
  same-task design handoff/new scope, missing-content refresh/revocation, repaired
  owned binding and disconnect. Every recorded scene-state comparison preserves
  node count, selected handles, transforms, Undo names and save-required **false**.
- `increment-receipt.json`: all **26 frozen runtime Python/JSON files** match
  current runtime source; all **five loaded native hashes** match the exact
  Scatter 0.86.9.2 / Analyzer 0.14.2 Max 2027 payload. Final artifact:
  `49f11242050ddc866ccb7bddce1f1470cca2a6a47a789cfefc8faf63d40be563`.
- First observed local catalog load: **519.87 ms**. A later warm run's first load:
  **47.33 ms**. These are two observations in one owned process, not a universal
  latency, disk-cold or peak-memory benchmark. Neither tool decodes previews.
- The earlier passing three-case receipt remains preserved. Its private driver
  bytes are archived under `driver-history/library_campaign-pass1.py`; the later
  driver adds missing-content qualification with an explicit suite rebind.

Local buttons and design grants in this campaign were scripted fixture actions,
not physical artist consent or a general usability study. Content registration
was written only inside the owned profile, pointing at existing read-only release
content. Source catalog hash is recorded; this is not a full content/package audit.
The configured artist MCP remains the older integration; no install, push, native
rebuild, product-version change or new package is claimed.

## Next acceptance

1. Extend authorized discovery to existing native preset/recipe engines, with
   worker/paging/cancellation semantics and stable data references. Personal or
   custom roots need explicit local grants, not unrestricted path parameters.
2. Expose and verify source scale, material/proxy/renderer dependency readiness
   and measured native metadata for real high-poly assets. Current 10k-triangle
   scene admission is not qualification of the full vegetation library.
3. Define approved import effects/destination, helper/source ownership, selection,
   memory and native merge Undo/failure behavior. The current `.max` import path
   must not be assumed to preserve arbitrary previous Undo history. Qualify exact
   missing dependency, changed bytes and rollback cases before enabling use.
4. Qualify selective style and complete recipe application using existing native
   engines, including units, Paint/paths, supported codecs and atomic preservation.
5. Feed viable assets into M04's actual grass-and-flower task and later intended
   installed-client/package tests. Catalog metadata is not a substitute for that
   workflow or full M03 acceptance.

Follow-up: [independent native recipe readers](M03_RECIPE_READER.md) now provide a tested prerequisite without borrowing the gallery singleton. Typed recipe MCP discovery and approved use remain open. The installed-model evidence above retains its original packaged/native identities.

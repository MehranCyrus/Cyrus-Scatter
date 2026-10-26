# Panel responsiveness and shared content — implementation plan

**26 October successor:** independent installed-content work below retains its original evidence. The personal model/recipe store is implemented separately in [0.87.1](DELIVERY_0871.md), following the [shared-library plan](SHARED_LIBRARY_IMPLEMENTATION_PLAN.md). Its exact static scope and remaining acceptance are recorded in that delivery.

## Shared personal library extension — planned, 23 October 2026

The user requested a full plan and explicitly deferred coding. The
[shared library implementation plan](SHARED_LIBRARY_IMPLEMENTATION_PLAN.md)
extends this document's existing byte-store/installer foundation to personal
models, shared textures, immutable recipe references, collections, portable
export/import and explicit migration. It includes the ten-look acceptance case
and retains old scene-path protections. SL01–SL09 are pending; this planning work
does not alter the delivered scope or qualification recorded below. Status stays
in the [execution ledger](../improvement-program/PROGRESS.md).

## Authorized 0.86.7.2 follow-up — 20 October 2026

The user authorizes an explicit optional content ZIP beside the EXE, concise
success feedback with failure details, a Textured mesh display choice, conditional
color controls, Placement points naming, and viewport-only receiver hiding.
Use F04–F08 and F11. Keep schema 58 and independent content revision 0.86.7.

Installer owns a bounded ZIP read (trusted packaged manifest, at most 4097 files,
16 GiB expanded, 2 GiB per file), streams verified entries into the existing
shared content store, and atomically registers only a complete pack. No temporary
full-library extraction. Peak additional disk is missing unique content plus the
existing working allowance; hard links reuse compatible same-volume installed
bytes. Checked content requires the matching adjacent ZIP; unchecked keeps current
content and never scans/expands ZIPs. Cancellation retains completed verified blobs
for retry and the prior active registration. Success hides logs; failure exposes them.

Textured mesh maps to existing native Mesh plus material appearance; no new saved
display enum or placement solve. Other modes expose relevant identification colors.
Receiver hiding is node-owned, persisted as a namespaced native app-data bit, shared
across controllers referencing that node, and undoable. A native display filter
reads it without altering ordinary Hide, render flags or receiver geometry.
Register it at system startup, after viewport initialization; DLX uses LibInit.
Suspend the filter before rendering and restore it afterwards because Max's
generic hidden-node query also includes display filters. Brush ignores only this
filter while preserving normal Hide/Freeze/layer and other-filter exclusions.
Rays continue against the bound snapshot. Test filter renderer behavior, Undo/Redo,
save/reopen, painting on plane/box/sphere, Manual pending edits, and retained counts.
No shader performance improvement is claimed solely from the menu change.

Qualify affected workflows and exact payloads in owned Max 2024/2026/2027 profiles;
real Corona leaf testing remains Max 2027 unless older renderer dependencies exist.
The EXE, three MZPs and one unchanged-content ZIP belong in the new delivery folder.
Original content paths remain available for saved scenes; no asset regeneration.

The newly reported Add Layer failure is in receiver ownership: obsolete
controller slots do not follow edits to layer-owned surfaces. New layers inherit
the selected logical layer's current receiver references in an independent array.
Sources, masks and Paint Areas stay at new-layer defaults. Empty receiver sets
receive an explicit No surface diagnosis. Test two real imported leaves, then
Add Layer, Add Point and Pick object replacement, including 20,000 placements.

The installer UX described below is the original broader roadmap, superseded
for this delivery by the explicit checkbox and automatic EXE flow above. Manual
path selectors, Analyze/Apply and equivalent content controls in the hosted MZP
are not part of the current UI; the MZP updates the plugin and retains content.
See [0.86.7.2 evidence](DELIVERY_08672.md) for completed acceptance and limitations.

20 October 2026. **Implemented as 0.86.7.1 within the delivery report's scope.**
The [implementation and evidence report](DELIVERY_08671.md) records current work.
The preceding shipped baseline is **0.86.7**. This document retains the full
roadmap; individual later steps are not automatically completed by this patch.
This plan answers the user's two requests: a faster Modify panel and one reusable
library with independent plugin/content updates for Max 2024, 2026 and 2027.

Read the [source and competitor research](SHARED_CONTENT_RESEARCH_20261020.md)
and [panel investigation](../panel-performance-0826/PANEL_THREADING_20261020.md)
for evidence and limitations. The [execution ledger](../improvement-program/PROGRESS.md)
owns status; B21 covers panel latency and B35 covers content/update storage.
Implementation, packaging, artist installation and deletion are separate from
this documentation request.

## Product decisions

1. **One managed library location per user, shared by all three Max versions.**
   The library location has no Max-year or plugin-version suffix. Different SDK
   binaries and managed helpers remain in their matched host runtimes.
2. **Updating the plugin does not automatically update the library.**
   Existing compatible content remains selected unless the user requests otherwise.
3. **Content has an independent pack ID and revision.**
   A plugin version bump cannot rewrite model files, previews or content manifests
   simply to keep version labels equal.
4. **Reuse verified bytes and preserve existing scenes.**
   One shared root may retain genuinely different revisions needed for compatibility
   or saved scene dependencies. It must not create three copies of the same assets.
5. **Reduce UI work before introducing asynchronous preparation.**
   Keep the current layout, controls and saved disclosure preferences. Do not
   promise a speedup until the exact implementation is measured.
6. Start with local NTFS content on a selectable drive. Shared network write
   coordination, online downloads, a content service and an asset marketplace
   are outside this first delivery. Choosing a shared folder on this computer
   does not require any of them.

## Installer experience

The EXE offers compatible installed hosts as checkboxes: Max 2024, 2026 and 2027.
Show each host's current/target plugin version and profile. Reuse the same content
selection for all selected hosts; do not silently target unselected profiles.

| Choice | Expected behavior |
| --- | --- |
| **Update plugin only** | Default for an existing installation. Update selected matched runtimes and preserve the compatible library binding. No content package required and no asset copying |
| **Update plugin and library** | Install the runtime and the explicitly selected content revision; show changed/new assets and extra disk use |
| **Manage library only** | Use an existing library, install/update a pack, or repair missing files without replacing plugin binaries |
| **Use existing library folder** | Verify and register a complete supported library where it already resides; no mandatory second copy |

On a fresh installation, allow the plugin without bundled assets: scene models,
points and personal recipes still work. The library shows a clear “Choose or
install a library” state. An incompatible library never triggers a silent upgrade.
For example, retained 0.86.6.2 Max-2027-only models can serve a compatible 2027
runtime; they must not be advertised as usable in Max 2024/2026.

Show the shared library path and a **Change location** action. Show separate
figures for existing/reused assets, new bytes, temporary peak space, retained
older files and potentially reclaimable bytes, with per-drive free space.
Explain the reason when content changes, such as a Max file-format conversion.
“Repair” is distinct from “Upgrade”: repair restores a selected revision.

The MZP must expose equivalent content choices through the same engine for its
single matched host. Its plugin-only route must not prompt for an external
Content folder. Normal plugin update must work offline without that folder.

## Content architecture and contracts

### Identity and location

Keep a small per-user library registration outside the runtime, for example
`%LOCALAPPDATA%/CyrusScatter/library-state.json`. Record canonical location,
pack ID, independent revision, manifest digest and owned host/profile bindings.
Explicit disposable-profile overrides must avoid artist/global registration.

A proposed managed layout is:

```text
<chosen library root>/
  objects/                 verified file data, keyed by full hash
  packs/<pack-id>/<revision>/
    catalog and logical model paths
  receipts/                ownership and transaction records
  staging/                 bounded, resumable install work
```

Keep existing hard-link reuse within this library volume. Logical pack views
can link to shared objects on that same volume; plugin runtimes only resolve
the library path and must not require cross-volume hard links. This removes
the current restriction that library and plugin runtime share C:.

Adoption must also accept the existing complete `Content/Library` layout by
a verified descriptor. It must not reorganize gigabytes just to conform to
the new directory layout. A later explicit migration can consolidate it.
The artist must understand that an adopted folder becomes the library's
permanent location and cannot be deleted as disposable installer media.

Define content compatibility by catalog schema/capabilities, MAX saved format,
explicit qualified host set and required renderer/map dependencies. Do not use
equality with the plugin version as a compatibility test. Keep full file hashes
and bounded path/count/size validation. Include stable asset IDs and revision
identities; retain numeric bounds without hard-coding “exactly 104 cards” as
the identity of every future library.

Support only the delivered legacy layouts needed for migration, with pinned
provenance. Read a legacy catalog through a bounded adapter; do not edit its
version field or resave its model files to manufacture compatibility.

### Discovery, planning and publication

1. Discover the shared registration, selected Max profile receipts, known owned
   legacy roots and a user-chosen folder. Avoid whole-drive scans.
2. Read manifests and compute a read-only installation plan. Verify candidate
   reused files by hash before trusting them; detect modified/corrupt files
   explicitly. Use cancellation and bounded streaming.
3. Calculate **additional physical allocation** on each destination volume:
   new unique blobs, missing runtime files, metadata and extraction/staging
   overlap. Do not count every host's linked logical view as another library.
   Include temporary extraction on its actual volume, even when content is on F:.
4. Revalidate the plan under the shared store lock and a consistent lock order.
   Handle competing installers, disk use by other programs and source-file
   changes; a prior free-space check does not guarantee a later write succeeds.
5. Stage only missing or changed files. Verify, then publish the complete
   content revision and its manifest. Never modify a shared linked blob in place.
6. Commit each selected host's matching runtime/registration transaction.
   Record per-host completion. If a later host fails, retain earlier complete
   installations and the previous complete installation of the failed host;
   report partial success clearly and make retry idempotent.
7. Remove only owned temporary work. Cleanup of old installed content is a
   separate decision. Keep journal recovery and changed-file protection.

Plugin-only mode may validate a compatible catalog but must not hash/copy the
entire multi-gigabyte library on every routine update. A full integrity scan is
an explicit repair/adoption operation; individual model import retains its
existing on-demand verification.

Preserve memory bounds: stream large files, keep manifest/queue admission limits,
and bound verification parallelism. Reuse the existing managed transaction engine;
no resident service or parallel Max scene access is needed.

### Saved paths, migration and retirement

Current imports store absolute bitmap paths under `Library-<plugin version>`.
Closing Max does **not** prove an old library is unused by saved scenes.

For new imports, resolve maps to stable immutable asset locations independent
of plugin releases. A changed map gets a new identity/path; existing scenes
continue to use their original bytes. Record pack/revision provenance with
imported assets where appropriate. Keep user-edited scene materials independent.

For existing installations:

- Plugin-only update can retain a verified legacy root in place. Do not copy
  its assets just to migrate metadata.
- On the same NTFS volume, verified files can be adopted through links or an
  explicitly planned rename. Preserve old dependency paths.
- Across volumes, explicit migration requires verified copy-before-switch,
  enough space on the destination, and a recovery journal. A cross-volume
  “move” is not a zero-space operation.
- Support using the already-complete 0.86.7 library on F: directly after
  verification, instead of requiring another 4.48 GiB on C:.
- Offer a reviewable legacy cleanup report. Include installed host pins,
  active leases/locked files, modified files, known imported dependencies,
  rollback retention and actual reclaimable allocation.
- Unknown saved-scene references remain a retention reason. Explicit scene
  relinking can operate on user-selected scene copies and must be tested
  through save/reopen/render before retiring their old paths. Do not scan or
  rewrite arbitrary artist scenes automatically.

Routine plugin updates must add zero content bytes when content is unchanged.
Old models/maps that genuinely remain referenced are not described as wasted
space. A general proof that no offline scene references a path is unavailable;
the UI must not claim otherwise.

Content-only changes are installation transactions, not Max Undo operations.
Scene import/relink commands retain authored Undo and save semantics. Browser
sessions pin a complete catalog revision; an install must not replace the
catalog underneath an in-progress import. Old files survive until consumers
release them, with legacy processes handled conservatively.

## Panel architecture and contracts

Preserve F01 ownership, F04 Manual/Live behavior, F05 complete publication, F06
bounds, F07 thread/lifetime rules, F08 passive reuse and F11 persistence.
See the [foundation](../../ENGINEERING_FOUNDATION.md). This work does not change
placement order, candidate identities, randomness or scatter results.

### UI-0: Repeatable baseline on delivered 0.86.7

Reuse the existing diagnostic stages and selection procedure. Record exact
script/native/managed hashes, hardware/load conditions, DPI, open sections and
fixture identities. Separate initial selection, queued mount, control creation,
value binding, layout, list work, first paint and first accepted user input.
Inclusive stage totals must not be summed.

Measure cold/reselected controllers and warm layer changes. Use at least ten
repeats per defined timing case; report median and range, and collect a larger
sample if reporting tail percentiles. Do not treat automation transport or
observer scheduling as UI CPU time.

Fixtures: empty controller; actual A027 leaf with Color Correction/opacity;
multiple layers and controllers; large source lists; assigned Analyzer guide;
source containers; two sections and all twelve sections open; 100/150/200% DPI.
Run the main development comparison in Max 2027. At final compatibility stage,
exercise affected UI and installer behavior in owned 2024/2026/2027 hosts.

### UI-1: Coalesced, affected-page refresh

Classify a refresh as values, rows/selection, titles/status, disclosure or geometry
layout. Combine redundant requests within one event turn; preserve timely control
feedback and final user edits. A known numeric edit should visit only its owning
page and explicitly dependent statistics/availability fields.

Use controller/layer/source stable IDs plus presentation/input revisions.
`procEpoch` alone is insufficient: Manual pending values can change without a
new scatter result. Owner switches, Undo/Redo and reset invalidate the appropriate
view. During initial rollout, unknown dependencies take a safe full-refresh path
with diagnostics rather than silently leaving stale controls.

Create a dependency table from actual handlers, including source name/color,
membership, Band assignments, containers, Analyzer freshness and relevant
animation. Preserve existing cheap status-only updates. Keep guards active
while assigning values so control events cannot write into a different owner.

### UI-2: Independent value/list/layout updates

A value-only edit must not reposition unchanged controls. Layout keys include
usable width, DPI/font, disclosure and mode visibility, wrapped text, list heights
and any label content affecting geometry. Skip unchanged property assignments.

Retain prepared row labels/colors keyed by row identity and presentation revisions.
Move list synchronization out of unconditional geometry layout. Bound caches by
mounted owners/rows; release them on unmount/deletion and invalidate on relevant
changes. Never retain dead control handles across Max-owned destruction.

### UI-3: Deeper lazy construction

Prototype one costly page first, selected using the new baseline. Create expensive
Advanced/disclosure bodies only when opened; retain them while the owning panel
is mounted. Preserve authored settings and saved open/closed preferences.

An unopened optional body has no control bindings or UI handles. Its commands
must use the shared model rather than assume hidden controls already exist.
Test first-open interaction, switching owners before opening, collapse/reopen,
Undo, scroll routing, keyboard focus and DPI. Expand to other pages only after
the prototype proves a construction benefit without lifecycle regressions.

### UI-4: Conditional scheduling and worker work

Only if UI-1 through UI-3 leave long freezes, queue complete sections between
event-loop turns and prioritize visible usable sections. Show consistent
loading/disabled state; preserve ordering and final scroll position. This can
reduce the longest freeze without reducing total completion time.

Each callback captures a mount generation and owner IDs. Discard stale work on
selection, unmount, deletion, reset/load or relevant Undo. Bound the pending queue;
never synchronously wait on a worker whose completion requires the UI thread.

Workers may prepare copied plain data or perform measured independent file/image
work. Live Max objects, MAXScript values, scene reads and control/layout updates
stay on the host/owning UI thread. Background preparation is optional, gated by
measured benefit after copying/dispatch overhead; no framework rewrite is assumed.

## Source map

| Work | Authoritative files |
| --- | --- |
| Installer modes, discovery, shared storage, admission and recovery | `AminScatter/setup/InstallEngine.cs`, `Distribution.cs`, `Program.cs` |
| MZP parity and exact host packaging | `AminScatter/installer/install.ms`, `AminScatter/tools/build_installer.py`, relevant `tools/*/package.py` |
| Independent content descriptor/catalog | `tools/build_individual_content.py`, `AminScatter/ui/LibraryGallery.cs` |
| Shared root selection, catalog resolution, stable imported map paths | `AminScatter/tools/ui/templates/recipes.ms` and managed catalog/resolver |
| UI requests, owners and refresh paths | `AminScatter/tools/ui/templates/approved-main-ui.ms`, `unified-core.ms` |
| Layout, lazy controls and lists | `AminScatter/tools/ui/approved-layout.cjs`, `lazy-pages.cjs`, `colored-lists.cjs`, row definitions |
| Host layout/scroll behavior, only if measurements require changes | `AminScatter/src/rollout_flow.cpp`, `rollout_scroll.cpp` |

Regenerate `AminScatter/scripts/AminScatterObject.ms` from authoritative inputs.
Do not implement fixes only in the generated file. Do not change content files
while editing runtime versions.

## Execution order and review gates

| Stage | Deliverable | Gate |
| --- | --- | --- |
| 0 | Freeze current identities; read-only storage plan and UI baseline | Explain actual new bytes and reproduce panel cost without artist mutation |
| 1 | Independent content descriptor/resolver and legacy adoption | Current assets load with a different compatible plugin label; incompatible host stays blocked |
| 2 | Plugin-only EXE/MZP path | Updating with no Content folder and insufficient space for a full library succeeds when runtime space is sufficient |
| 3 | One configurable library root, multi-host selection, content install/repair and explicit migration | Three hosts share asset bytes; F: content works with C: runtimes; interruption preserves complete states |
| 4 | Retirement report and stable scene-path handling | No automatic deletion of referenced/unknown legacy dependencies; candidate cleanup has measured reclaimable bytes |
| 5 | UI-1 and UI-2 prototypes | Fewer binds/layouts and improved measured interaction with identical model state |
| 6 | UI-3 prototype, optional UI-4 | Faster first usable controls without broken disclosure/lifecycle behavior |
| 7 | Combined qualification and delivery | Exact new EXE and three matched MZPs; current docs and explicit remaining limitations |

Storage is first because it currently prevents the artist's upgrade. UI baseline
collection can precede implementation; it does not require installing into the
artist's profiles. A stage that fails its evidence gate is revised before expansion.

## Required acceptance

### Content and installation

| Scenario | Required evidence |
| --- | --- |
| Fresh plugin-only install, no asset media | Plugin works with scene sources; library has an informative empty state |
| Plugin-only upgrade from 0.86.6.2 and 0.86.7 | Compatible content hashes/file IDs unchanged; zero asset copies and no content-folder prompt |
| Install all three hosts in several orders | Same content root/asset identity; second and third hosts add runtime bytes only |
| Different current runtime versions | Compatibility evaluated per host; library update does not silently rebind incompatible older runtimes |
| Existing library on F:, runtime and temporary directory on C: | No cross-volume hard-link attempt; correct independent space estimates |
| Exact reinstall and repair | No-op adds no asset bytes; one missing file repairs only that identity; modified bytes preserved |
| One changed asset / catalog-only update | Only required changed bytes and metadata added; no resave of unchanged models |
| Low space before install and mid-write exhaustion | Explain required/available bytes; no partial publication or broken previous registration |
| Cancellation/crash at staging and publication | Journal recovery, retry reuse and consistent per-host results; no unbounded orphan accumulation |
| Two concurrent installers | Bounded lock wait/cancellation; one published content identity, no duplicate blob writes |
| Adopt/migrate old root | Hash-verified reuse, path-boundary checks, Unicode/long-path/ACL handling and preserved recovery |
| Old scene saved before migration; new scene after it | Maps and opacity resolve after save/reopen; geometry/material edits preserved; no missing render dependencies introduced |
| Unregister one host | Other hosts and shared assets remain usable |
| Invalid/missing catalog, pack or renderer dependency | Clear bounded failure; no phantom successful library or partially imported scene nodes |
| Clean recipient EXE and MZP in each supported host | Exact package/runtime hashes and host guards, both content choices, restart/load verification in owned profiles |

Do not fill the artist's real drive to reproduce disk-full conditions. Use owned
bounded fixtures/fault injection and record where a real filesystem boundary
was or was not exercised. Prove sharing with file IDs/allocation or verified
zero-copy paths; directory logical sizes alone do not prove it.

### UI and retained behavior

- Actual generated control handlers: Count, source add/remove/replace, Point/model
  conversion, name/color, maps/patterns/channels, display and layer changes.
- Manual pending values remain visible without calculation; Live updates only
  relevant dependencies. Passive selection/browsing produces zero added static
  solves, preview preparations or GPU uploads in warm fixtures.
- Rapid controller/layer switching during queued work, Undo/Redo, delete, reset,
  save/reopen and close during loading never apply data to a stale owner.
- All-open and two-open layouts, Advanced first-open, list resize, narrow panel,
  scrolling, keyboard focus and 100/150/200% DPI remain correct.
- Real A027 library leaf: nested Color Correction and opacity edits, replacement,
  scene save/reopen, thumbnail wheel loading and retained Materials/Textures Mesh.
- Repeated mount/unmount leaves bounded cache/control memory. Compare unchanged
  viewport geometry/output as well as counters, not screenshots alone.

Proposed performance goals, to be ratified against the controlled baseline:
at least 50% lower median warm full-bind time and 30% lower all-open
selection-to-ready time, without a material two-section or heavy-scene regression.
Mechanistic gates are mandatory even if timing is noisy: a value-only edit
causes no unchanged geometry layout, and unopened optional bodies are not created.
Report first usable time and total ready time separately. No such improvement
is claimed by this plan.

## Delivery and remaining decisions

Use Max 2027 for development; the user's named compatibility scope requires
final matched SDK/managed packages and affected installer/UI checks for
2024/2026/2027. Retain the current renderer limitation: actual Corona leaf
qualification requires those renderer/map plugins; Standard fixtures and
missing-dependency rollback do not prove Corona rendering in the older hosts.

Choose the next version using the [version policy](../../Release_Versioning.md#choosing-the-next-version)
when implementation scope is fixed. No scene-schema change is intended;
content registration/manifest schemas are separate. Preserve the current
0.86.7 receipts and independently versioned products.

Deliver one universal EXE and exact host MZPs, with optional content distributed
independently. Verify archive integrity, host guards, pair identities and
offline plugin-only use. Include measured UI results and a storage report.
The artist installs and restarts; tests use disposable profiles.

Before coding, settle the exact descriptor/schema and legacy scene-path
retention rules in Stage 0/1. Network libraries, automatic discovery of every
offline scene, general shader compatibility and a new UI framework remain
outside this plan. No plugin code, installer or library bytes were changed
while preparing it.

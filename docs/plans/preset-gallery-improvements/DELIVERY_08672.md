# 0.86.7.2 — content ZIP, viewport controls and new-layer receivers

20 October 2026. User-selected patch after the
[corrected 0.86.7.1 delivery](DELIVERY_08671_CORRECTION.md). Scene schema 58,
CyrusUnified1, placement/Brush POD identities and independent product versions
are unchanged. Native Brush and matched host packages were rebuilt for Max
2024, 2026 and 2027. Previous deliveries retain their original receipts.

## What changed

- The EXE offers **Install / update plant library**, unchecked by default.
  Put **CyrusScatter-Content-0.86.7.zip** beside it and check the option to
  install content. A checked option with no matching ZIP gives a clear error
  before installation. Unchecked updates the plugin and preserves content.
- Success shows **Installation completed. You can now open Max.** Technical
  details are hidden; an **Error details** link appears after failure.
  Host selection, Install/Update and Uninstall remain automatic.
- **Textured mesh** is directly in **Display mode**. **Placement points**
  replaces the Plant centres label and means one marker per placement.
  **Color by** offers identification colors in nontextured modes; texture
  appearance is no longer offered for Point Cloud or Proxy.
- **Surfaces > Hide surface / Show surface** controls selected receiver
  viewport drawing while keeping painting and rendering available.
  The node-owned preference is shared across setups using that node,
  saved with the scene and undoable.
- **Add Layer** inherits the selected logical layer's current receivers.
  Its receiver array is independent; sources, masks and Paint Areas start at
  new-layer defaults. Missing receivers report **No surface** with guidance.

## Causes and contracts

The new-layer path read obsolete controller-level surface slots. Current
assignment edits belong to layers, so a populated first layer could coexist
with empty controller slots. Changing a Point to a sphere could not repair
the missing receiver. `newLayer` now reads `logicalParent(previous).validSurfaces()`
before creating the new independent layer. The new status distinguishes missing
surfaces from a valid calculation that accepts no placements.

The display menu maps Textured mesh to the existing native Mesh mode plus
material appearance. No saved native display enum or placement algorithm changed.
Material/geometry draw budgets still apply. Instancing reuses source geometry;
texturing still has shading, texture-memory and drawing costs. This menu change
does not establish a new FPS or memory improvement.

Receiver visibility uses one namespaced native node app-data byte and a native
display filter. Normal Hide/render flags, transforms and geometry stay intact.
Brush continues using its bound geometry snapshot and ignores only this Cyrus
filter; ordinary Hide, Freeze, hidden layers and other active filters remain
exclusions. Undo stores the previous bit and a reference-managed node lifetime.

Max's generic hidden query includes display filters, including during rendering.
The filter is therefore suspended at PRE_RENDER and restored at POST_RENDER,
with nesting state and preserved enabled state. Registration is deferred to
SYSTEM_STARTUP after viewport initialization; MAXScript extensions enter through
LibInit. Native calls also ensure registration for a module loaded later.
All host/filter/publication access remains on the Max thread. This adds no
placement-sized script data or geometry snapshots beyond the existing Brush.

## Content and storage

Content remains revision **0.86.7**. The archive packages the existing models,
materials, maps and original previews without regenerating them:

- 96 prepared individual models, covering 104 catalog cards, in seven categories.
- 1,204 declared payload files plus the content manifest.
- **2,440,853,358 bytes** compressed; **5,851,411,791 bytes** declared payload.
- Manifest SHA-256:
  `010f43f09172c084ba15407227f9776e359b013e1f1a9583d31a2d4458e9a361`.

The package pins the expected manifest. ZIP admission rejects traversal,
duplicate/unlisted entries, special-file entries, inventory/size differences and
mismatched manifests. Bounds are 4,097 entries, 16 GiB expanded, 2 GiB per file
and a 1 MiB manifest. Streaming uses a 256 KiB buffer and verifies each file hash.
There is no temporary full-library extraction. The installer uses the existing
shared blob/pack store and atomically registers only a complete pack; cancellation
preserves the prior active registration and completed verified blobs for retry.

Standard profiles share `%LOCALAPPDATA%/CyrusScatter/Library` and one library
registration across the three hosts. Identical installed packs remain in place.
Same-volume verified files can be hard-linked; missing unique bytes are charged
to their destination drive. Old runtime/content paths are preserved for saved
scene references. A Max-2027-only retained library does not block a Max 2024
plugin-only installation; compatible supplied content requires the ZIP option.

The hosted MZP updates its matching plugin and retains content. Use the EXE for
the optional content ZIP. Content is not downloaded automatically. Uninstall
keeps shared content and other Max registrations.

## Executed evidence

Fixtures: `tools/final_08672/`, with retained regression fixtures under
`tools/update_08671/` and `tools/repair_08671/`.
The final receipt is `build/final-08672-20261020/final-receipt.json`.

- Generator/control integration passes with **321 controls**; **175 Python
  regressions** and **48 Max-2027 SDK/native tests** passed. These offline
  checks do not substitute for the host tests below.
- **66 installer transaction checks** cover ZIP admission, missing/damaged
  content, streamed verification, cancellation, publication failures, repair,
  idempotency, same-file reuse, three-host binding, modified-file preservation,
  contention, long paths and synthetic low-disk admission. The added compatibility
  case preserves a Max-2027-only library while installing the Max 2024 plugin.
- The actual EXE form ran in an owned process with a WinForms message loop and
  illegal cross-thread access checking. Missing checked ZIP, running-host
  rejection, install/update, zero-byte repeated update, three-host shared
  resolution, concise success and uninstall preservation passed.
- A preceding candidate streamed the actual 5.85 GB ZIP content into a fresh
  owned library. The final EXE, differing by the plugin-only host-compatibility
  correction, verified/reused that same library without a second large copy.
  Final-core streamed ZIP transactions were also rerun with inert fixtures.
  The final EXE SHA is pinned by `exe-ui-release/exe-sha256.txt`.
- Actual hosted Install buttons passed with the final installer DLL in Max
  **2024, 2026 and 2027**; their receipts record its loaded assembly hash.
- Fresh plugin hosts at configured **200% / 150% / 100%** respectively passed
  all twelve sections, scoped refresh, conditional layout, cached-list visibility,
  source replacement/Undo, gallery loading, library binding and textured preview.
  These are configured scale checks, not physical multi-monitor certification.
- Actual display-menu notifications passed all five modes and preserved pending
  Manual placements. Surface visibility buttons passed Undo/Redo, ordinary Hide
  restoration and retained placement counts.
- Hidden planes, spheres and boxes passed Paint/Erase and Max Painter screen
  hit tests in all three hosts. Actual Start/Stop Brush handlers and subsequent
  status ticks passed on a hidden sphere. Normal Hide and Freeze remained rejected.
- Actual Scanline renders before/after viewport hiding had equal pixel checksums
  in all three hosts. The filter was restored after render; scene save/reopen
  retained visibility. A separately launched Max 2027 process applied the saved
  preference before any visibility command and could paint that receiver.
- Max 2027: two real library leaves, then Add Layer, Add Point and Pick object
  replacement by a sphere produced **20,000 accepted placements**. Original
  leaf sources/receivers and both visible layer rows were retained. Generic
  new-layer Point/sphere and Live tests also passed in all three hosts.
- Max 2027 real A027 leaf tests passed Color Correction property edits, diffuse
  clearing, opacity off/on, Undo, animation and warm navigation while retaining
  pending Manual placements. Actual Live library feedback/list retention passed.
- A real leaf imported from the **EXE-installed ZIP library**, with its bitmap
  dependencies resolving inside that shared root, and produced textured scatter.
- Max 2024/2026 lack this workstation's Corona/Forest dependencies. Their supplied
  leaf imports correctly failed with visible feedback and rollback. Standard
  material/UV tests passed there; successful Corona leaf rendering is not claimed.

Initial failed candidates and probes are retained separately. They exposed filter
render inclusion and too-early DLX viewport initialization, both corrected before
the final native host campaign. A Max 2024 probe initially passed logical pixels
to Painter at 200% scale; physical-pixel projection corrected the fixture.
The real-leaf layer fixture initially invoked an unmounted Models control; the
final test opens/binds the page and verifies the button's owner before clicking.

## Delivery

Folder: `dist/CyrusScatter-0.86.7.2-20261020/`.

| Artifact | SHA-256 |
| --- | --- |
| CyrusScatter-0.86.7.2-Setup.exe | `31b2081339e9c11e5e81913f9008da970093fdb7f7cc082e5968b964245fcbdb` |
| CyrusScatter-0.86.7.2-Max2024.mzp | `ab630fc6a4e380408a042d93501196217512dccc8e70ee456a84e7e5db3dcd59` |
| CyrusScatter-0.86.7.2-Max2026.mzp | `0264e8bed270948f8a2f8bea3d0478b64277862b6bf0eee364f05fe8f6ea301e` |
| CyrusScatter-0.86.7.2-Max2027.mzp | `dd546f1263c494f81670a9836230dba05097e3eefc0f7615eaecb141421c26ac` |
| CyrusScatter-Content-0.86.7.zip | `db5a63e87f81abd78563ec80039fed066a6cb73f585779749ed23faf548f2c58` |

Generated script SHA-256:
`b7a53162f376bcd7abbffcc38309e28b7c08749623dae1a951e5fafd01d41dd8`.
The receipt pins loaded fingerprints, native/gallery identities, final core,
EXE resources, source/build metadata and acceptance-file hashes.

Close the selected Max versions, run the EXE, select their cards and choose
whether to install the adjacent content ZIP. Alternatively use **Scripting >
Run Script** with the MZP matching the running Max year, then restart Max.
The EXE is unsigned. Nothing was installed into artist profiles, no artist Max
session was restarted, and source models/previous delivery folders were preserved.
No Git commit/push or website publication was performed.

B21 cold construction/fully lazy Advanced controls, automatic old-path retirement,
physical mouse/tablet testing, renderer-specific interactive-render lifecycles and
sustained production-scene acceptance remain separate. These scoped passes are not
a claim of perfection for every scene, third-party shader or device.

Automatic approval review rejected recursive removal of the disposable
`build/final-08672-20261020/exe-ui-final/2027/cs/Library` test library with only
“blocked by policy.” Its approximately 5.85 GB of verified data was retained and
reused for final testing; no second unpacked test library was created. It is
separate from the artist's library and the clean delivery folder.

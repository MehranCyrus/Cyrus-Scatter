# Shared personal library — Scatter 0.87.1

26 October 2026. **Delivered for artist testing** with separate matched Max 2024, 2026 and 2027 payloads. [Exact qualification manifest](QUALIFICATION_0871.json).

## Install

Use the [three-host EXE](../../../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Setup.exe),
or the matching [Max 2024](../../../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Max2024.mzp),
[Max 2026](../../../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Max2026.mzp)
or [Max 2027 MZP](../../../dist/CyrusScatter-0.87.1-20261026/CyrusScatter-0.87.1-Max2027.mzp).
Run an MZP with **Scripting > Run Script**, then restart that host. For the EXE,
save work and close the selected Max versions before installing, then reopen.
The exact [SHA-256 list](../../../dist/CyrusScatter-0.87.1-20261026/SHA256SUMS.txt)
and package inventory bind this delivery. Analyzer and installed plant content are
independent; plugin-only installation retains them. Installer transaction tests
use the exact EXE's embedded mapping and owned profiles; archive/host-guard checks
do not claim a physical click-through test of every MZP dialog.

## Result and ownership

Complete static planting recipes own their supported models, materials, textures,
terrain/path context and authored settings. The personal library keeps exact
mesh/image bytes once in a configurable local NTFS store. Recipes pin immutable
asset revisions; collections and model cards share those stored objects. A new
scene loads the assets automatically without revisiting the original import folder.
Use the [artist guide](SHARED_LIBRARY_ARTIST_GUIDE_0871.md) for the visible commands.

The store separates raw bytes, mesh/material/map definitions, normalized standalone
model packages, full recipe packages, collection membership and catalog history.
Model-only export follows only that model's dependencies. Ten looks remain ten
recipes, each with its own Count/seed/layer order and exact source revisions.
Changing material values or gamma reuses geometry and raw image bytes. A changed
image or mesh adds its changed object. Imported scene materials remain editable
without modifying the immutable library.

Every object is verified by SHA-256 and size. Package/resolved filenames are NTFS
hard links to the object allocation; no duplicate-copy fallback hides a failed link.
Gamma/colour interpretations have distinct filenames over the same encoded image,
avoiding Max's filename-based bitmap cache mixing their annotations. Model graphs
preserve whether equal shader objects were distinct or instanced.

Mesh import uses SDK floats in the destination scene's units. On re-save, a prior
mesh hint can recover the original encoded object only after native verification
of its hash and an exact comparison with the current SDK representation: vertices,
topology, mapping, normals and attributes. Merely stamping provenance never proves
equality. An actual edit creates a new object. This avoids duplicate geometry from
unit-conversion rounding during an unchanged import/re-save.

`SharedLibrary.cs`, its Management/Models partials and `ContentObjects.cs` own file
transactions, manifests, locks, catalogs and archive transport. `LibraryJson.cs`
is the bounded canonical document parser. Native `asset_package.cpp` owns typed
package validation/preparation; `asset_mesh_host.inc` owns SDK mesh conversion.
`recipes_bridge.cpp` exposes bounded data-only verification and independent
prepared-package leases. `recipe_library.cpp` reads the committed catalog directly.
The `shared-library.ms`, `assets.ms`, `recipes.ms` and `preset-loading.ms` templates
coordinate authored host commands. `LibraryGallery.cs` provides the same model
through My recipes/My models/collections and the storage menu.

## Publication, failure and resource behavior

A complete save captures to private marked staging, verifies and adopts the
dependency closure, and publishes one atomic catalog head. A failed successor
retains the previous complete entry. A settings-only save is deliberate and
separate. Cancellation/failure can leave verified reusable orphan objects, never
a falsely complete card. No background purge removes assets used by saved scenes.

One content lock coordinates writers, including the installer's shared byte-store
primitives. At most eight operations are pending and two file workers run; native
verification is serialized, cancellable, process-pinned and retired before native
shutdown. Workers consume copied data. SDK capture/creation/publication remains on
the Max thread. Imported personal models use one authored Undo transaction and
immediate created-node tracking. Captured owners are revalidated before apply.
Save/browsing does not consume pending Manual placement edits.

Catalogs admit at most 10,000 combined entries, 10,000 collections and 8 MiB per
snapshot, with 128-card pages. A bundle admits 100 recipe roots, 1,000 model
revisions, 4,096 objects and 16 GiB expanded bytes; individual objects/packages,
typed codecs and available host memory impose lower limits. Native M02 meshes
remain bounded to one million vertices/faces and 224 MiB encoded. Existing
resource admission retains the six-mesh-equivalent plan plus bitmap work and
physical/commit reserve. Large UI-independent capture/SDK creation is still
synchronous; this is not a claim of constant-time or unbounded import.

NTFS's 1,024-link limit applies per file, including immutable dependency views
and interpretation aliases. Reaching it fails safely; the 10,000-entry metadata
bound is not a guarantee that one image supports that many view aliases. Logical
object bytes, NTFS allocation, history, staging and retained external copies are
different storage categories.

## Sharing, migration and maintenance

`.cyruslib` export pins the selected catalog revision and writes the union of its
dependencies once. Import bounds and verifies every member, including already
present hashes, before merging the catalog. Repeated import adds no duplicate
cards or payloads. Same-recipe-ID/different-revision conflicts preserve the local
entry; explicit import-as-copy derives a repeatable copy identity. Current model
revision conflicts require explicit reconciliation or a separate library.

Migration validates supported flat recipe 1–8 libraries and their complete
`Presets/<digest>` packages. Originals remain. Present corruption is rejected;
missing packages remain explicitly settings-only. Optional same-volume
consolidation replaces only registered, verified migration dependency copies with
hard links at their existing filenames, using per-file recovery journals.

Relocation verifies the new store/history before redirecting future writers and
retains the old store for existing scenes. Explicit scene-copy relink verifies
known image hashes and interpretations, rechecks captured map owners and filenames,
records Undo/Redo and saves a new scene. Prior catalog restoration creates a new
history revision. Abandoned-stage recovery removes only marked dead-process work.
Backup repair replaces corrupted shared objects/views with verified archive bytes
and retains replaced bytes in quarantine. Ordinary import refuses corrupt reuse.

## Qualification and remaining limits

The [qualification manifest](QUALIFICATION_0871.json) binds 59 native tests per SDK, 244 managed transaction checks, 573 Python regressions, 58 exact-EXE installer checks, and the recorded actual-host workflows. Each host passes 126 ten-look and 67 personal-model checks; the separate native migration and Corona campaigns retain their own receipts.
Development/intermediate receipts remain under
`build/shared-library-0871-20261025/`; a passing earlier candidate does not qualify
the final package. Failures and test-driver corrections are retained.

The acceptance case uses three imported OBJ models, including a tree above
100,000 vertices, six PNG/JPEG images, a receiver and ten independently saved
looks. It checks physical file identities, exact Count settings/layer order,
transport to an empty recipient, repeat import, fresh scenes and reopening after
the original folder and archive become unavailable. Standard material comparison
uses a fixed 192×128 Scanline witness. The Corona check is a separate exact-profile
fixture, not general renderer certification.

The [plan](SHARED_LIBRARY_IMPLEMENTATION_PLAN.md) remains the original acceptance
design. This delivery covers static planting. Interactions roles and retained
reviewed preparation, arbitrary scene serialization, unsupported proxies/shaders,
animation and unsupported Edit/radius state remain explicitly rejected. The
existing installed Plant models `.max` merge/B38 Undo limitation is separate from
the new transactional personal-model route. Existing B37 copied Edit-stack lineage
remains open. This delivery does not close unrelated P/I/PG/N or Lab acceptance.

Portable bitmaps require Max's normal default OCIO mode and matching saved config,
rendering/data spaces. Max 2024's legacy Gamma mode is rejected deliberately;
tests select OCIO explicitly in their owned scenes. Renderer graph 3 retains its
exact Max 2027/Corona 15.0.671720 adapter requirement. Graph 4's Standard/M02 route
is independent of Corona. Cross-host sharing still requires compatible colour and
renderer profiles; no silent conversion changes the recipient's scene settings.

Managed transaction fault fixtures do not prove physical power-loss durability,
every filesystem/device failure, or long-soak behavior. Simulated 100/150/200%
gallery scale checks are not physical multi-monitor DPI certification. Broader
Paint/spline transfer, every variation and renderer combination, comprehensive
peak-memory measurements and the original plan's wider production matrix remain
separate acceptance. Native/unit passes are not presented FPS or artist approval.

Scene schema remains 60, recipe 8, numeric settings 3, native placement/Brush POD
2/2 and Edit storage 2. Library capability remains 4, portable package capability
3; shared-store capability is 1. New private schemas are store/catalog/bundle 1,
standalone model-package 1 and shared static graph 4. Analyzer 0.14.2 and installed
content 0.86.7 remain independent. The user selected **0.87.1**, overriding the
usual minor-step recommendation for a substantial feature. No artist installation,
session restart, Git commit/push or website publication is part of this delivery.

# Shared asset foundation: Forest Pack, Chaos Scatter and Cosmos

23 October 2026. Research and proposed architecture only. No plugin implementation, installation, Max launch, host test, asset relocation or vendor execution was performed. The only repository change in this investigation is this report. Existing working changes belong to other work.

The recommendation is **one configurable managed asset store, immutable asset revisions, lightweight recipes/collections, and a separate portable export/import format**. Vendor evidence supports separating asset delivery, catalogs, materials and scattering configuration. It does not establish that either vendor automatically deduplicates every independently authored preset by file content.

## Evidence and scope

- Fresh official-document research is linked below. Documentation of a workflow is not proof of a private storage algorithm.
- Current installed Forest catalogs and selected module identities were read directly. Selected existing Ghidra exports were reinspected; no new decompilation/backend run was performed.
- Ghidra 12.1.4 and the Ghidra MCP 6.0.0 JAR remain present at the locations in the [tool inventory](../../GitHub_Tools_Inventory_2026-10-15/README.md). Other GitHub tools are unnecessary for the questions resolved here.
- The existing knowledge search returned `stale_evidence`; conclusions use current files and original research artifacts. No index refresh was performed.
- Repository: `codex/workflow-0.75`, HEAD `7d5fd264f8c39e306389977d1eda7c4f358bd3c8`, with substantial pre-existing tracked/untracked changes. This is a source investigation, not qualification of a release.

## What Forest Pack establishes

Forest supports user library locations on local/network storage. Its documented authoring workflow can save selected objects, including Forest presets and sources, into a new `.max` file, optionally create material libraries, collect external assets and make thumbnails. Registering an existing asset is a separate reference-based workflow. Relative library paths simplify sharing. User library editing is Pro-only. [Official editing guide](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library).

The commercial-library specification explicitly separates catalog XML, model files, maps, material libraries and thumbnails. Entries can share maps/materials, and paths can use relative references or macros. Library vendors manage those files; registering their catalog does not itself copy the files. This supports reusable references, not a claim of automatic content deduplication. [Official library specification](https://docs.itoosoft.com/forestpack/forest-library/integrating-third-party-libraries).

Forest 9.4.1 added mesh objects to portable `.fp` files, alongside Forest settings, with browser support for those meshes. This establishes another payload format; it does not establish that all external textures or arbitrary dependencies are embedded. [17 June 2026 release notes](https://docs.itoosoft.com/changelog/2026/06/17/forestpack-9_4_1).

The 9.3.3 notes distinguish installed Assets location from Packages Cache, permit network asset locations, and document texture relinking to a library's maps directory. A shared download cache and shared installed assets are different storage policies. [27 November 2025 release notes](https://docs.itoosoft.com/changelog/2025/11/27/forestpack-9_3_3). The [Update Manager guide](https://docs.itoosoft.com/installation/update-manager) documents independent content delivery; its older network-installation wording should be read with that clarification.

### Fresh local catalog inspection

The scoped installed Lite root is `C:/Users/Mehran/AppData/Local/Itoo Software/Forest Pack Lite/lib`. Seventeen `index.xml` files were read. Twenty-three item entries contain explicit `maxfile` fields, grouped into 22 catalog/file pairs. Missing explicit fields have other catalog/UUID semantics; these counts do not enumerate all usable assets.

Two concrete entries in `Presets/Lawns/index.xml` are:

| Entry | Saved file | Object within file |
| --- | --- | --- |
| Common grass 01 (detail) | `objects/_fp_common_grass_01.max` | `_fp_common_grass_01` |
| Common grass 01 (large) | Same file | `_fp_common_grass_01_large` |

Both reference the same renderer-selected material-library expression. This demonstrates two catalog entries sharing a container file. It does **not** prove that the two Forest objects share all underlying model bytes, or that ten separate authoring saves eliminate duplicate meshes.

Catalog SHA-256: `7206f7b277f92fcc41b5110ba078a69197a201bc9a95b29c148634efd594ae5a`.

### Native analysis and its limits

The installed binaries still match the original library-analysis targets:

| Module | SHA-256 |
| --- | --- |
| ForestPackLite.dlo, file version `9,4,3,766` | `23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d` |
| ForestQtCatalog.dll | `eefef4a421bdb50320c951bf271a6b90d847bc09572337b816572f2ef9767e20` |

The selected core export for RVA `0x12e760` uses catalog/source identity and `ForestLibItem` to find managed scene templates. The cleanup export references `forest_templates` and the same property. This is scene-template management; it is not evidence of a global file-content store.

Original sources reinspected:

- [Acquisition export](<F:/Cursor/_Cyrus_Apps/Forest Reverse/build/library-20261015-08/batch1/library_merge_objects.c>), especially the lookup/property comparison around lines 298-328.
- [Cleanup export](<F:/Cursor/_Cyrus_Apps/Forest Reverse/build/library-20261015-08/batch4/cleanup_library_nodes.c>).
- [Qualified native reference/lifetime analysis](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/40_LIBRARY_REFERENCES_AND_LIFECYCLE.md>).
- [Corrected module/RVA evidence map](<F:/Cursor/_Cyrus_Apps/Forest Reverse/research/forest/41_LIBRARY_MAX_CODE_MAP.md>).

Earlier Max observations remain historical in [the runtime report](FOREST_RUNTIME_2026-10-16.md). They were not rerun. The local installation is Lite; there is no new Pro custom-library save/share result. Native acquisition/scene reuse must not be presented as proof of authoring-time disk deduplication.

## What Chaos Scatter and Cosmos establish

Chaos documents Scatter presets delivered through Cosmos and individual models that can be imported and scattered. Applying a Cosmos preset to a selected object can use that object as the receiver. [3ds Max integration guide](https://support.chaos.com/hc/en-us/articles/4953423307025-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Using-with-Other-Features).

Cosmos documents reusable downloaded packages across host platforms, asset updates, and distinct material/asset variants. Different material interpretations should therefore be modeled separately from reusable geometry. These descriptions do not reveal whether identical files across unrelated packages share physical storage. [Cosmos Browser](https://docs.chaos.com/display/COSMOS/Chaos%2BCosmos%2BBrowser).

Its asset download directory can be local or networked. Users sharing a network directory can see assets downloaded by another user. Changing that setting does not migrate existing downloads. [Directory configuration](https://docs.chaos.com/display/COSMOS/Configuring%2Bthe%2BAsset%2BDownload%2BDirectory). Chaos explicitly explains that retaining the old paths protects existing projects. [Relocation guidance](https://docs.chaos.com/display/COSMOS/Moving%2Bthe%2BAsset%2BDownload%2BDirectory).

The current official MAXScript reference exposes `saveConfiguration` and `loadConfiguration`; its example uses `.mbc` and calls the format unspecified. That is evidence of configuration persistence, not a demonstrated complete personal-model/material/texture archive or library authoring system. [MAXScript API](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124394405/MAXScript).

### Local inspection and remaining uncertainty

The current Chaos adapter/core hashes match the original ownership-analysis inputs:

| Module | SHA-256 |
| --- | --- |
| ScatterMax_Release-2027.dll | `f7fdd25428e8374174501e6bb4ebd3b83e21c5ba2c33fcdc94280c022695b887` |
| ScatterCore.ForScatter_Release.dll | `069ababd0dbc09218928f24d5bdc860509b237f34af703581e3fd78ed5d3cf86` |

Current PE file versions read `15.0.671707`; the older [ownership report](../../Product_Discussion_2026-10-08/CHAOS_OWNERSHIP_EVIDENCE.md) separately records its package-metadata caption. Those are different identity fields. That earlier analysis concerns scene-model/target ownership, not Cosmos storage.

Cosmos `cbservice.exe` is present, file version `2026.05.13-666839`. Its configured working directory is `C:/Users/Mehran/Documents/Chaos Cosmos`; both `Packages` and `UserPackages` were empty during inspection. No assets were downloaded to create evidence.

Only configuration key names and the relevant working-directory value were inspected. The package registry `cpkg.db` did not accept a read-only SQLite schema query (`file is not a database`); its header is not the SQLite signature. This establishes a failed format assumption, not encryption, corruption or any deduplication algorithm. No account records, authentication material or registry contents were extracted.

To establish Cosmos's physical deduplication, future targeted work needs actual downloaded packages and their manifests/file allocation identities. Decompiling Scatter's placement engine would not answer a question owned by the separate Cosmos package service. That uncertainty does not block designing Cyrus to meet its explicit storage requirements.

## Recommended Cyrus contract

### One store, multiple views

Use a selectable local root independent of plugin releases and Max-year runtime directories. Personal libraries are named manifests/collections referencing models and recipes in that store. The same item can belong to several collections without another payload copy. Installed read-only content can retain its existing adapter/layout during migration.

Identify exact captured bytes by full content hash and validate type/codec/version separately. Reuse geometry independently of material graphs and texture image bytes independently of their colour-space/UV/output settings. A changed material can reuse existing geometry/images. Similar-looking files, names, UUID tags or source paths are insufficient to establish identical content. Different representations may remain distinct even when visually similar.

A model has a stable catalog identity and immutable revisions; recipes pin specific revisions. A deliberate update can change selected recipes. Renaming, tagging, moving a collection or saving a new planting variation must not copy unchanged payloads. Do not mutate shared files when editing a scene material.

### Sharing

Export selected recipes or a collection by traversing the complete dependency graph and writing the union of required files once. Include models, material/map definitions, supported images, Paint, paths and compatibility/provenance metadata. The bundle uses relative/hash references, never the sender's drive letters. Import verifies complete dependencies, adds only missing verified objects, and publishes the collection after successful validation. Repeated import adds no duplicate payload bytes; equal names with different content remain distinct.

The portable archive is an intentional transport copy. Each recipient/machine or independently usable disconnected store needs its own files. Sharing storage does not automatically reduce per-scene SDK/Undo memory, or the geometry saved inside separate `.max` scenes.

Separate a reusable Scatter recipe from a complete scene snapshot. Cameras, lights, unsupported modifier producers, native proxy files and exact authored per-instance edits require explicitly supported payload adapters and acceptance. A storage refactor does not expand the current geometry/material export support.

### Ownership, failure, work and deletion

- Reuse the existing native capture/codecs and bounded file workers. Max API access stays on the host thread; workers own detached data. The UI owns bounded views and explicit commands.
- Put missing blobs first, verify them, then atomically publish the immutable recipe/asset revision and its visible collection reference. Incomplete saves retain the previous complete entry; recover orphan staging without treating it as a valid library item.
- Serialize conflicting store publication with cross-process locking/recovery. Stream hash/copy work, calculate new physical bytes and peak staging requirements, and retain separate finite limits for a multi-recipe bundle versus one recipe. Ten looks must not require hydrating ten complete scenes at once.
- Source fingerprints/provenance can help avoid unnecessary work only when current content is verified. Browsing and changing selection must not capture geometry, copy assets or calculate plants. Disk deduplication alone is not a measured save-speed improvement.
- Loading into a scene keeps the existing transaction, Manual/Live, complete-publication and Undo/Redo contracts. Library-only saves/imports are file transactions, separate from scene Undo.
- Resolve new texture bindings to stable immutable locations. Preserve old cache/library paths while saved scenes may refer to them. Relocation is an explicit verified migration plus supported relinking, not an automatic folder-setting change.
- Removing a collection or recipe removes a reference. No automatic global asset purge in the first delivery. Later cleanup must account for retained revisions, installed packs, active operations and known scene/project pins; unknown offline-scene dependencies are not proved absent by a library reference count.

## Implementation sequence and future acceptance

1. Specify asset/revision/recipe/collection manifests, a shared resolver, portable bundle format, atomic publication and scene retention. Choose formats deliberately; do not reactivate retired scene formats.
2. Extend shared storage to personal recipe saves and model assets. Metadata-only edits add metadata bytes only; unchanged geometry/images are reused across recipes and collections.
3. Add collection export/import over one dependency graph. Keep this usable offline without a resident cloud/content service.
4. Add explicit consolidation of supported existing packages. Reuse verified bytes, preserve originals and old texture bindings, and report migration peak space. Retirement is separate from adoption.
5. Qualify Max 2027 with exact script/native/managed pairs after implementation is authorized. Required cases include ten looks sharing one tree, material variants, same-name different data, repeat import, clean-recipient import, missing/corrupt assets, concurrent/interrupted saves, disk exhaustion, retained previous revisions, scene save/reopen and Undo/Redo without the source export bundle. None were executed in this research.

Start with local storage and portable sharing. Network multi-writer storage, a marketplace and cloud synchronization require separate operational/ownership contracts; the manifest/resolver boundaries should leave room for them without making them prerequisites.

## Current Cyrus source anchors

| Source | Relevant behavior | SHA-256 inspected |
| --- | --- | --- |
| [InstallEngine.cs](../../../AminScatter/setup/InstallEngine.cs) | Bundled object-store verification, missing-byte accounting and hard-link views | `01d4ab9eb9e4f55fc640f067c75b07beb5f5d8ce6a0496769677d00084a76588` |
| [asset_package.cpp](../../../AminScatter/src/asset_package.cpp) | Per-package content filenames/copy, graph verification, prepared texture cache | `abcc305539d1ef4fd5f2bf256241bdef217166e5b5264f18ba7b734744e1524f` |
| [recipe_store.cpp](../../../AminScatter/src/recipe_store.cpp) | Revision identity, content fingerprint, immutable payloads and atomic entry replacement | `5428e1308b72b52a290501a46209021c78dace1fc638d3330c82feaddbdc269d` |
| [preset-loading.ms](../../../AminScatter/tools/ui/templates/preset-loading.ms) | Recipe-hash package directories and asset recopy for revised metadata | `4c6e34817a3bef6399c506d3282e274a6b480e058824cc43d136a9cd1e9db1c8` |

The [existing shared-content plan](UI_AND_CONTENT_IMPLEMENTATION_PLAN.md) already separates software/content revisions and protects scene-dependent paths. This research extends the design discussion to personal assets, recipes, collections and portable sharing. It does not mark that extension implemented, resume unrelated roadmap phases, or change a release version.

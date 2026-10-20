# Shared content and installer research

20 October 2026. Read-only source, installed-file and official-document review.
No plugin implementation, installation, library relocation or cleanup was performed.
The proposed work is in the [combined implementation plan](UI_AND_CONTENT_IMPLEMENTATION_PLAN.md).

## Baseline and evidence limits

Current delivery: Scatter 0.86.7; artist receipt inspected: 0.86.6.2 / Max 2027.
Checkout: `codex/workflow-0.75`, HEAD
`3ec1cbc2b725912e39c2625ceecb648970054050`, with substantial existing tracked
and untracked changes. Source inspection includes those changes; HEAD alone
does not identify the delivered implementation.

The knowledge generation
`c14f3d16e81bcf39ebd488d53bcec1239b522a0de37dcc8a81738bffdcf9be3e`
reported stale parents during full verification earlier in this review.
An exact-path search successfully returned the unchanged installer contract,
whose applicability is the historical 0.86.2 delivery. It does not establish
0.86.7 behavior. The findings below use current originals and local receipts.
No knowledge index was refreshed.

## Observed disk-space failure

The artist's log is:
`C:/Users/Mehran/AppData/Local/CyrusScatter/2027/logs/install-20261020-101137-9beca60b.txt`.
It records the 0.86.7 MZP using the distribution's `Content` folder on F: and
rejecting installation with `Not enough free disk space for staged installation: C:\`.
This is the installer's admission check, not evidence that the failed attempt
copied another complete library.

The installed receipt is:
`C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/scripts/CyrusScatter/installed.txt`.
It points to 0.86.6.2 under
`C:/Users/Mehran/AppData/Local/CyrusScatter/2027/r/801cdef80783`.

Read-only comparison against the proposed 0.86.7 manifest, deduplicated by
SHA-256 and checking matching previous files by size and hash:

| Item | Result |
| --- | ---: |
| Available C: space at the observation | Approximately 2.98 GiB; volatile |
| Reusable unique existing files | 959 / 978,358,652 bytes / 0.911 GiB |
| New or changed MAX files | 96 / 4,808,463,828 bytes / 4.478 GiB |
| Other changed catalog file | 1 / 55,735 bytes |
| All content logical paths | 1,204 / 5,851,207,027 bytes |
| Unique content hashes in that manifest | 1,056 / 5,786,878,215 bytes |

The manifest itself, runtime files, extraction and filesystem overhead are
additional. The reusable figure counts unique bytes, so it differs from the
delivery's 1,107 image/preview paths and their logical size. Adding directory
sizes is not reliable physical accounting when hard links exist.

Manifest inspected:
`dist/CyrusScatter-0.86.7-20261020/Content/content-manifest.json`,
SHA-256 `010f43f09172c084ba15407227f9776e359b013e1f1a9583d31a2d4458e9a361`.
The [delivery report](DELIVERY_0867.md#content-reuse-and-storage) explains the
96 MAX save-backs to Max 2024 format. This changed file bytes even though the
geometry and previews were reused. The shared store had no asset blobs at the
time of inspection, only its zero-length lock file.

## Current implementation and gaps

| Source | Verified behavior | Implication |
| --- | --- | --- |
| `AminScatter/setup/InstallEngine.cs`, `InstallPaths.ForMax` | Standard profiles use one `%LOCALAPPDATA%/CyrusScatter/c` store; relocated profiles default to their own store | Cross-host sharing already exists for standard profiles, but is not one configurable user-facing library location |
| `MissingContentBytes`, `InstallFile` | Reuses verified store blobs or a matching path in the selected host's previous registered release; otherwise streams a new copy and links it | Does not blindly copy unchanged content; does not discover every older/other-host installation |
| `PreviousContent`, `Relative` | Previous receipt determines `Library-<version>`; each runtime gets a similarly named library tree | Runtime and content identity remain coupled |
| `CheckContentIdentity`, `LoadExternalContent` | Requires matching plugin version and the exact packaged manifest hash; missing external content rejects installation | Plugin-only update is not supported |
| `Install` | Requires content and runtime on the same NTFS volume; checks new unique content plus core payload and a 16 MiB reserve | Cannot simply select F: for content while leaving the runtime on C: |
| `Install`, repair branch | Admission includes the full core payload before checking whether the release already exists | A no-op repair estimate is conservative rather than an exact missing-file delta |
| `Program.cs`, `Distribution.cs`, `installer/install.ms` | EXE selects one Max host; EXE and MZP share the transaction engine and both require content | Both entry points need the new policy; an EXE-only checkbox would leave inconsistent behavior |
| `ui/LibraryGallery.cs`, `IndividualModelCatalog.Load` | Exact content/plugin version match; explicit host check; fixed 104-card assumptions | Compatibility needs an independent content contract; removing only the installer guard is insufficient |
| `tools/ui/templates/recipes.ms`, `CyrusRecipeBundledDirectory` | Bundled library is beside the loaded script and includes the plugin version | Browser needs a shared-library resolver |
| `CyrusModelMerge`, `MapPath` | Rewrites imported bitmap paths to absolute paths under that library | Removing or moving an old library can break saved scenes even after all Max processes exit |
| Installer recovery/unregister | Old releases and content remain; modified files are protected | Retention protects work but currently has no bounded retirement workflow |

Source references are repository-relative paths and symbol names, verified on
20 October; line numbers can change. Actual old-scene references were not
enumerated, and no blanket claim of safe deletion is made.

## Official product documentation reviewed

These are public workflow descriptions, not inspection of either vendor's private
installer, cache implementation, thread scheduling or deduplication algorithm.

| Product/source | Documented behavior | Relevant lesson for Cyrus |
| --- | --- | --- |
| [Chaos Scatter getting started](https://support.chaos.com/hc/en-us/articles/4953372632209-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Getting-Started) | Scatter can use individual Cosmos models or downloadable Scatter presets | Keep scatter behavior and asset delivery separate |
| [Cosmos installation and use](https://docs.chaos.com/display/COSMOS/Installing%20and%20Using%20Chaos%20Cosmos%20Browser) | Downloaded assets are reused across host platforms; browser and asset updates are exposed separately | Independent software/content revisions and explicit asset updates |
| [Cosmos download location](https://docs.chaos.com/display/COSMOS/Configuring%2Bthe%2BAsset%2BDownload%2BDirectory) | A configurable local/network asset directory; changing it does not transfer previous downloads | Show location separately from an explicit migration action |
| [Cosmos relocation](https://docs.chaos.com/display/COSMOS/Moving%2Bthe%2BAsset%2BDownload%2BDirectory) | Explains preserving existing project paths and reusing previously downloaded packages during relocation | Migration must preserve scene dependencies, not just browser visibility |
| [ITOOSOFT installer](https://docs.itoosoft.com/installation/installing-plugin) | Detects compatible Max versions and offers component selection; content is handled through Update Manager | One installer can select several hosts without treating each host as a new library |
| [ITOOSOFT Update Manager](https://docs.itoosoft.com/installation/update-manager) | Optional library packages can be installed and removed independently of software releases; a shared package cache can avoid repeated downloads | Separate core update, content selection, and cached installation packages |
| [ForestPack library locations](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library) | Configurable library roots, including network paths; built-in libraries and editable user libraries are distinct | Preserve artist libraries and make managed content discoverable |
| [ForestPack 9.3.3 changes](https://docs.itoosoft.com/changelog/2025/11/27/forestpack-9_3_3) | Assets-folder selection, including network locations; distinguishes Packages Cache from asset storage; optional texture relinking; fixes unrelated-layer rebuilds | Distinguish installed content from download cache; dependency-scoped UI/scene work |

The general ITOOSOFT Update Manager guide uses older “Local Network Installation”
terminology. The dated 9.3.3 release note clarifies the distinction between the
Assets location and Packages Cache. A shared download cache alone is not proof
that installed assets occupy one copy. The installation-files reference also
contains historical paths/renderer examples; do not copy those defaults as a
current Cyrus design.

Neither vendor documentation establishes that a checkbox can safely replace
changed assets in place, that old scenes never need retained files, or that
Modify-panel widgets are built on worker threads. Cyrus's design and tests
must establish its own guarantees.

## Recommendation

Use one user-selected content root across Max 2024/2026/2027, separate matched
host runtimes, independent content revisions and a plugin-only default for
upgrades. Reuse the existing streamed verification and hard-link machinery
within the content volume. Add adoption of an already-complete library so
existing bytes can be used directly. Make storage planning and legacy-path
retention visible before installation.

Develop panel performance from the
[existing measured investigation](../panel-performance-0826/PANEL_THREADING_20261020.md),
starting with affected-page binding, layout suppression and deeper lazy
construction. Public competitor documentation does not provide a substitute
for measuring those changes in Cyrus.

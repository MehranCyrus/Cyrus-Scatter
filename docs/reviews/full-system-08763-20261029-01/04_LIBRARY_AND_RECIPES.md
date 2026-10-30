# Library, recipes and storage

## Actual boundaries

The managed shared Library owns bounded file transactions and content-addressed storage. The gallery owns UI and bounded thumbnail tasks; it does not run Max scenes while browsing. Native validators check supported portable graphs and Scene envelopes. MAXScript owns explicit host serialization, graph collection, binding and merge. Workers receive file descriptors/bytes, not live Max objects.

These are different products within the workflow:

| Kind | Stored meaning | Important limit |
|---|---|---|
| Settings-only recipe | Authored settings and roles requiring binding | Not a self-contained model/material scene |
| Portable recipe/model package | Supported numeric geometry/material/bitmap graph and immutable dependencies | Supported adapters and graph fidelity matter; arbitrary renderer plugins are not made portable |
| Native Scene preset | Bounded Max graph closure plus declared files | Max 2027, matching system units and required plugins; standard merge clears Undo |

Content objects are hash-addressed and shared through verified hardlinks. Recipe/model revisions pin immutable dependencies. Removing a card is not permission to delete assets referenced by another saved recipe/scene. Catalog publication uses complete immutable snapshots and an atomic head; post-commit cleanup must not convert an already committed success into a partial failure.

## Fresh executed checks

**244 managed assertions** cover deduplication across ten recipes, model-only transport, shared images/meshes, concurrent conflicting saves, revision CAS, corrupt imports, explicit repair of damaged/missing hardlink views, rename/revision behavior, collection membership, relocation, migration, repeated import, previous-catalog restoration and interrupted transaction publication. Interruption tests kill only owned child processes before and after catalog commit. Native package validation is injected in these standalone tests; no artist store is used.

Additional tests reject ZIP traversal, absolute paths, duplicate members, symlink entries and excessive member counts, with the catalog head unchanged. A supported Unicode root works; an overlong root is rejected. These tests supplement source inspection of `Child`, archive inventory/digest/expanded-size checks and reparse-point rejection. They do not cover every filesystem ACL or adversarial concurrently modified path.

The actual Max 2027 host test saved a five-node Scene preset, prepared it through the real native validator, rejected mismatched units without changing the scene, merged a new independent setup with fresh layer identities, preserved placement counts `[1,500]`, and saved/reopened the result. This test collected **zero external assets**; it cannot certify texture/plugin portability. It reproduced the stale writer version in FS-02.

FS-01 separately reproduces abandoned Scene-load copies surviving recovery. The published recipe remains usable; explicit `DiscardSceneLoad` cleans the copy. See [findings](01_FINDINGS.md) for the minimal fix and live-owner control test.

## Source and failure review

- `SharedLibrary.cs`: local NTFS root bounded to 80 characters; paths bounded and rooted; per-file and total expanded sizes checked; immutable dependency verification precedes catalog visibility. Lock contention and asynchronous cancellation are bounded. Concurrent conflicting revisions fail instead of silently replacing a reviewed revision.
- `SharedLibrary.Management.cs`: relocation keeps earlier saved-scene paths available and redirects later writers; restoration republishes a complete prior catalog as a new revision. Recovery conservatively keeps unowned/live staging. That conservative rule is correct; FS-01 is a missing ownership marker in the producer.
- `SharedLibrary.Scenes.cs`: each scene is copied before Max rewrites its asset metadata, avoiding mutation of hardlinked published `.max` data. Completed cancellation discards the private copy. File-only envelope verification does not parse or sandbox arbitrary Max scene content.
- `scene-presets.ms`: bounded graph closure includes dependencies/parents, rejects unrelated Scatter setups in the closure, checks host/units/plugins, and cleans only newly merged nodes on failure. Identity remapping separates the imported owner/source/clone namespace. Scene merge's Undo-clear notice is intentional, not a newly found regression.
- `LibraryGallery.cs`: page size 128, image input limit 2 MiB, two decode jobs, 64 MiB bitmap cache, generation checks and disposal prevent stale image results from being adopted by a different page. Layout/search/thumbnail operations are distinct from authoring. Physical controls, scaling and rapid cancellation were not retested through Computer Use.

## Portability/security matrix

| Scenario | Status |
|---|---|
| Missing/corrupt declared content | Native/managed tests and conservative validation; failed head remains intact |
| Original transport archive removed | Managed recipient remains usable |
| Rename/delete a shared card | Managed pinned-dependency checks pass |
| Concurrent save/CAS conflict | Managed tests pass |
| Cancel/interrupt storage transaction | Managed transaction tests pass; Scene-load ownership gap remains |
| Scene unit mismatch | Fresh Max rejection preserves original scene |
| Scene save/merge/reopen | Fresh Max pass for small fixture; no external textures |
| Unicode / root-length policy | Supplemental managed pass/rejection as documented |
| UNC/network/non-NTFS/reparse roots | Explicit policy inspected; no network share test |
| Read-only root / permission changes mid-copy | Source/error path inspected; not an exhaustive fresh ACL campaign |
| Missing renderer/material plugins | Explicit native Scene restriction; not a fresh cross-machine plugin test |
| Portable UV/material adapter fidelity | Native package/mesh/shader tests; full artistic rendering comparison remains separate |
| Arbitrary metadata executing code | Data-only parsers/strict paths inspected; no generic eval path found in reviewed catalog handling |
| Loading an arbitrary `.max` | Uses Max's host loader and security environment; not a sandbox supplied by Library |

The existing MZP was read as an archive: CRC, complete member inventory, manifest hashes, all seven qualified payload hashes, version and Max 2027 guard passed. It was neither repackaged nor installed. See [package evidence](evidence/package-check.json).

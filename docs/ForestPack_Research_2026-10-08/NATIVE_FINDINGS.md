# Native findings and their limits

Addresses below are **RVAs** in the pinned `ForestPackLite.dlo` from [the identity receipt](EVIDENCE.json). Preferred image base is `0x180000000`. Names such as `collision_filter` are research labels, not recovered original source names. Raw listings and per-batch ledgers are retained privately under the recorded build run.

## Native modules and boundaries

The main 3,357,768-byte module is a native PE32+ x64 image with no CLR directory. Imports include Max core, parameter blocks, MAXScript integration, GraphicsDriver/GraphicsUtility, Qt6 and the OpenMP runtime. Auxiliary `ForestQt.dll` and `ForestQtCatalog.dll` import branded Qt5 libraries; `ForestVRay70.dll` imports V-Ray and contains renderer-related type names. These are dependency observations, not proof of every library's responsibilities.

The UI architecture is mixed. Native Max parameter-map callbacks exist in the core, alongside Qt dependencies and auxiliary Qt windows. Calling the entire product a Qt5 UI would be inaccurate.

RTTI candidates include `TForest`, distinct rollout dialog procedures, mesh/sample/proxy/node-property caches, `TCloud`, `TMeshCloud`, `TCloudItem`, `TForestGPUMarkerRenderer`, worker/thread types, `CollisionGrid`, `BSP::RTree<PolySeg*>` and an expression VM namespace. Strings/type names are navigation anchors. They do not establish execution order, field semantics, class totals or the completeness of a system.

## Retained viewport marker drawing — strong native evidence

RTTI identifies the primary marker-renderer vtable at RVA `0x220030`; its secondary interface table is at `0x220008`, with a 24-byte subobject offset. Independent MSVC/Max 2027 SDK probes identify primary slots 6 and 7 as `ICustomRenderItem::Realize` and `Display`.

| Path | RVA | Observed behavior |
|---|---|---|
| Preparation | `0x19f6b0` | A ready byte at object offset `0x31` gates preparation. The path initializes and locks a buffer with 16-byte records, fills data, unlocks/attaches it and marks readiness. |
| Parallel buffer filling | `0x1edbf0`, `0x1edce0` | OpenMP loop helpers write records. This proves CPU parallel fill, not GPU placement calculation. |
| Draw | `0x19f910` | Binds format/streams/index data, activates material passes, draws and restores state. |
| Device method | indirect offset `0x110` | The SDK witness identifies slot 34 as `IVirtualDevice::DrawInstanced`; the observed primitive is triangle-list, two primitives per marker, instance count from the prepared count. |
| Display-update dispatch | `0x415a0` | Compares two object fields before work and stores the current value afterward; an explicit force path bypasses the comparison. Revision semantics are inferred; fields are not named. |

This establishes a retained preparation/draw boundary for the marker path. It does not show every mesh renderer, all point-cloud record semantics, every event that clears readiness or the entire placement invalidation policy. SDK-imported reference-count thunks were identified as imports; apparent recursive decompiler output is not an algorithm.

## Collision system — concrete algorithm evidence

The distribution dispatch at `0x3afe0` contains separate XY and UV profiling anchors; both invoke `0x91890` when collision filtering is enabled and there are multiple items.

The filter sorts records, initializes a `CollisionGrid` using twice a selected record's radius, tests candidates and marks failed items before compacting the result. Its constructor at `0x90930` calculates grid dimensions from XY bounds and cell size, allocates cell heads and entry storage. The test/insert path at `0x90c60`:

1. Converts item XY position to clamped cell coordinates.
2. Checks linked entries in the current cell and relevant adjacent cells, including corner cases.
3. Uses the sum of each pair's radii and a Z-offset-adjusted position in a squared-distance sphere test.
4. Returns rejection on overlap; otherwise inserts the accepted item and references into neighboring cells it crosses.

Grid lookup is planar; the overlap test includes Z. The strict comparison is distance-squared **less than** combined-radius-squared. Input validation, floating-point tolerances, sort priority and behavior with extreme variable radii have not been qualified. The 3,049-byte test/insert body was completely decoded within Ghidra's discovered bounds, but some decompiled floating-point argument types are unresolved; assembly was used to check the structure of the path. We have not reconstructed a general-purpose replacement implementation.

The official [image-distribution documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode) describes collision removal after generation and sphere radius/height controls. Native findings corroborate that family of behavior; they do not prove collision behavior in every distribution mode or renderer.

## Sample cache and configuration — evidence with an open policy

Configuration reader `0x6b610` uses `GetPrivateProfileIntW`; writer `0x6ca50` writes the corresponding keys. Reader fallback values include:

| Key | Installed reader fallback | Interpretation boundary |
|---|---:|---|
| `cloudPointsByObject` | 250,000 | Consistent with the documented per-object point cap. Full sampling policy not traced. |
| `cloudHitTestMaxPoints` | 10,000 | Public documentation says 1,000. Record the version difference; neither is a measurement of the user's active setting. |
| `samplesCacheLimit` | 10,485,760 | In the documentation's KiB units, 10 GiB. Reader fallback, not a captured runtime allocation. |

The render-frame notification path at `0x1c850` calls cache cleanup with the configured limit and logs purged samples/cached size. Eviction at `0x7a670` checks the current cost against the limit, locks the cache, collects and sorts sample entries, and removes entries while enforcing its bound. Cost aggregation at `0x7aed0` sums stored sample costs across cached owners. The comparator at `0x7a650` was not a discovered function in this pass; **LRU, priority meaning, sample units and exact ownership/refcount policy remain unproved**.

The public [animation documentation](https://docs.itoosoft.com/forestpack/forest-plugin/animation) distinguishes source following from discrete random/map samples and describes sample caching. Runtime sample reuse and memory behavior still need controlled scene tests.

## UI ownership and dependency model

Display dialog procedure `0x55a20` handles initialization, commands and destruction. It retrieves `IParamMap2::GetParamBlock` and then `IParamBlock2::GetOwner`, initializes Max spinner/slider and proxy controls, and releases control interfaces during destruction. Transform procedure `0x54d30` follows the same owner-retrieval pattern. SDK compile witnesses verify the indirect method slots. This provides a concrete example of binding controls to the underlying scene object.

The readable startup script exposes source, receiver, path, reference, Particle Flow, paint, look-at and light dependencies through separate lists/properties. It is useful API evidence, not the native engine's implementation. `forest_utils.ms` is comments; encoded `optmat.mse` was preserved and not decoded.

## Corrections that prevent misleading conclusions

- `ForestAutoupdateThread` is a **software update checker**: the selected thread function sleeps, then invokes version/update-window logic containing vendor update URLs. It is not evidence of a placement scheduler.
- Selected distribution-worker virtual slots were deleting destructors; a later area-worker label named `area_worker_compute` turned out to be setup. Neither proves copied-data worker computation or host-thread safety.
- Abstract `TCloudItem` pure-virtual slots do not prove Lite features were stripped.
- An R-tree type name does not prove that all receiver projection uses that index.
- Complete decompilation of a discovered function does not recover original source, author names, types, semantics or original function boundaries.

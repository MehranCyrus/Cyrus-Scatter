# Native geometry reuse — 0.1.3 runtime

This describes the implemented 0.1.3 native46 runtime. [The qualification ledger](RELEASE_VALIDATION_0.1.3.md) identifies the exact tested build and package, and [performance measurements](PERFORMANCE.md) separate geometry preparation from complete command time. A cache hit is a validated reuse decision, not a timing claim. Historical 0.1.2 archives remain immutable.

## What is retained

Each admitted setup retains an immutable raw furniture inspection and a furniture/obstacle placement query. These contain copied numerical data. They contain no Max mesh, material, node pointer, authored document, placement result or region registry. A command borrows a strong lease; clearing the service does not destroy data still borrowed by that command.

On Generate, Preview and Commit, raw observations are reconciled against the current region registry. Bound scene assets are recaptured, current category/region/composition/lock settings are solved, and Generate/Commit capture current appearance and create their outputs. A hit skips furniture capture/inspection and obstacle capture/query construction. It does not skip placement validation, bound asset capture, solving or publication. Analyze remains a cold, furniture-only inspection: it reconciles the registry without using or filling this cache, refreshing assets or constructing the full fit query.

The initial implementation only reuses data at the same scene time. Its exact key includes the unique document instance, non-restored scene and geometry epochs, time, system-unit conversion, frame origin, every inspection/query setting, ordered furniture/obstacle roots, furniture source keys, expanded geometry identities and roles, evaluated object classes/validity, and exact final-pipeline object transforms/transform validity. Current source uses explicit `GetObjTMAfterWSM` consistently with evaluated numeric and visual capture; native36's WSM host failure motivated this correction. Native39's complete boundary suite verifies real furniture/obstacle WSM parameters and axes against independent world meshes; native41's separate appearance suite additionally verifies its bounded WSM accessory fixture. These historical receipts qualify their named pairs and fixture scopes. Identity is a valid final transform when world-space deformation has already transformed the mesh; mandatory dependency observation still covers upstream changes. No padded-structure hash substitutes for equality.

The retained query includes each support height bin's true minimum/maximum Z and owned polygon paths. Every probe admits a bin only if both extrema differ from the candidate support height by no more than its contact tolerance, whose shared default is **0.002 mm**. Eligible bins are united before edge inset; the height index alone does not establish contact. This prevents a numerical bin seam from blocking a continuous imported board without admitting a ramp through chained tolerances. The single-bin path preserves its existing work accounting. Cold and reused commands call the same immutable query; this changes no public result shape or scene/library schema. See [numerical support](NUMERICAL_SUPPORT.md) for the zero-degree inspector rule, conservative whole-bin rejection and tested limits.

## Observation and publication

Mandatory dependency observation operates even when optional reuse is disabled. A command stages a complete watcher for current furniture, accessory and obstacle roots and their group descendants. The Document owns that watcher as transient host state so Preview-only discoveries remain observed after the command returns. A command ticket itself is valid only inside its command scope. Relevant changes invalidate the ticket even while owned output publication suppresses ordinary output notifications. Reentrant commands for the same setup are rejected.

Native32's command-local watcher lost newly discovered descendants after a Preview-only command. Its actual regression changes a shelf child's support top from 820 to 880 mm after Preview returns and demonstrates a falsely valid Preview/Commit. Native34's persistent watcher passes this regression in both reuse modes, plus independent accessory/obstacle descendant and removed-member cases, in the 685-assertion general host suite. Its strengthened 233-assertion publication-callback suite also passes. Native39 later passes the complete boundary/lifetime suite. The [qualification ledger](RELEASE_VALIDATION_0.1.3.md) preserves the failures and exact successor receipts, including the matching native46 functional campaign and separate package evidence.

Generate validates current state, owner, dependencies, units, time and geometry key after preparation, after visual capture, before committing, and before accepting its Undo transaction. A failed successor cancels its transaction while the updating guard and dependency observer are still active. Deferred genuine input dirty state is drained after cancellation, so restoring old authored state cannot silently erase the observed change.

The input container is filled under a silent lifetime reference before its observer subscribes. Max emits change notifications for container insertion itself; subscribing earlier falsely invalidated unchanged input in native29/30. State/dependency checks bracket attachment and the bounded ordered reference set is checked afterwards. A complete successor replaces the previous watcher only after staging succeeds; the predecessor remains active during staging. No invalidation flag or epoch is reset to hide real changes.

The observer has at most 8,192 unique input nodes per document. Replacement can temporarily hold both old and new sets. This host-reference storage is separate from the numeric cache's byte accounting and is not serialized, cloned or restored through Undo. Binding publication refreshes the durable derived references. Scene, ownership, history or hierarchy changes mark the transient observer for retirement; active command publication/cancellation finishes before an ordinary boundary releases it. An authoritative current set may ignore a known detached descendant still present in the older durable derived container; unknown notification payloads and explicit root roles remain conservative.

The setup and its ancestors cannot become observed input dependencies, preventing a hidden ownership cycle through the C++ observer. Live servicing checks the actual ownership attribute rather than relying only on a non-null owner monitor, because Undo or Preview can retain a document after attribute removal. Safe servicing uses a bounded registry snapshot and pins documents while releasing SDK references. Native39's boundary receipt covers actual attribute removal, retained Undo lifetime, rejected detached Live servicing and restoration; those results do not replace checks on a later final pair.

Preview passes its original immutable state and command ticket into the preview service. The service validates them before staging and again after reference registration/allocation, immediately before swapping the entry. It never labels old diagnostic boxes with a newer state merely because a callback changed inputs during staging. Changes triggered after the swap invalidate the retained stamp normally.

Viewport redraw happens after transaction acceptance. A redraw exception records a refresh error while retaining the successfully published result; it cannot truthfully report that publication was rolled back. MAXScript response-array allocation still occurs after native publication/staging, so generic host out-of-memory response delivery is not an atomic rollback guarantee. This is distinct from tested capture/query/solve/publication failure retention.

Document geometry epochs and scene generations are not serialized or restored by Undo. Time/units/history/open/new/reset/merge and owner lifecycle events invalidate reuse. Source plugins must emit valid Max notifications and evaluated validity. An arbitrary third-party object that silently changes geometry is outside this contract; explicit cache clearing provides a forced-cold recovery path.

## Ownership and retained limits

The service admits at most four entries, 256 MiB of accounted retained entry allocations, one million triangles and one million raw inspection cells globally. Resident entries and retired entries with outstanding strong leases remain charged until final release. Replacement admission cannot conceal the memory of the predecessor.

Accounting includes the query wrapper/implementation, vector capacities, nested support paths, actual rebound map allocation requests (including support-bin extrema), raw results/key buffers and allocated entry metadata. Fixed service/control object sizes are reported separately. These numbers exclude allocator-private overhead, capture/build scratch, per-probe union/inset scratch, Max objects, output meshes, Preview, region registries and Undo history. Multi-bin support admits input polygon work before union and checks resulting complexity afterwards; this is not a strict preallocation scratch-byte cap. They are not process RAM or peak process-memory measurements.

A cold command remains usable when an optional entry is too large, its accounting is unavailable, outstanding leases prevent admission or optional metadata allocation fails. Ordinary geometry/query/solver failures still fail the command. Callbacks only flag invalidation; ordinary command/service boundaries release retained payloads.

## Native diagnostic API

All calls require Max's main thread. Existing public result rows retain their shapes. The new getters return last-known diagnostics and do not capture geometry, solve, drain events or establish current freshness.

| Call | Result or effect |
| --- | --- |
| `caGeometryCacheEnabled()` | Current process toggle; working default is true after the initial correctness gates. |
| `caSetGeometryCacheEnabled value` | Returns the prior toggle; disabling clears existing resident entries. |
| `caClearGeometryCache setup` | Clears optional retained data for this document instance. |
| `caClearAllGeometryCaches()` | Clears optional retained data globally. |
| `caGeometryDependencyInfo setup` | `#(1, instance, sceneEpoch, geometryEpoch, reusable)`; exact native integers. |
| `caGeometryCacheInfo setup` | `#(1, serviceEnabled, lastOrUndefined, totals, phases)`. |

`serviceEnabled` requires both the process reuse toggle and an existing enabled numeric service. It can be false before the first reusable command even when `caGeometryCacheEnabled()` is true. Totals describe the global service; `last` describes this document's last recorded command. Neither proves that a current entry exists for this setup. Clear calls return true and retain last-command diagnostics; they do not run another command or rewrite that historical disposition.

Clearing geometry reuse does not change authored revision, generated nodes, Preview validity, scene time or Live arming. It does not manufacture a valid dependency ticket. A later Generate or Preview rebuilds the cold data normally.

The twelve `last` fields are operation, disposition, reason, completed, published, lookupValidated, inspectionOriginalWork, inspectionExecutedWork, queryOriginalWork, queryExecutedWork, solverWork and commandSequence. Original construction work is retained provenance; executed construction work is zero on a hit. Preview can complete without publishing scene outputs. Analyze records `cold`/`disabled` because it deliberately bypasses reuse even when the process toggle is true; its measured registry update does not set the arrangement-output `published` flag. Failed commands replace the last-command diagnostics without replacing the previous complete scene result.

Operations are `generate`, `preview`, `commitPreview`, `analyze`. Dispositions are `cold`, `hit`, `coldNotRetained`. Reasons distinguish empty/key/dependency/time/units/scene/owner changes, explicit clear, disabled reuse, invalid keys, unavailable accounting, oversized entries, pinned budgets and optional metadata allocation failure.

The eight totals fields are resident entry count, retired borrowed entry count, live footprint, peak footprint, live entry-metadata bytes, peak entry-metadata bytes, fixed service inline bytes and fixed control-object bytes. Each footprint is `#(entries, bytes, triangles, cells)`.

The twelve phase rows are `#(name, nanoseconds)` in this order: `lookupStamp`, `furnitureCapture`, `inspect`, `registryBind`, `obstacleCapture`, `queryBuild`, `assetRefresh`, `solve`, `visualCapture`, `publish`, `finalValidate`, `total`. Timing uses native monotonic elapsed time. The total includes uninstrumented command overhead and should not be inferred by adding phase rows. No timer value alone proves a cache hit or a correct arrangement.

## Qualification boundaries

Native accounting/ownership tests establish bounded numerical lifetime behavior. Real Max tests must independently establish notification coverage, exact cold/hit placements, full mesh bounds, Preview/Commit, history, hierarchy, transforms, animation, save/load/merge/clone and callback-time edits. Phase timings must accompany successful correctness checks and matching script/native identities. Render/artist usability qualification and installer startup remain separate gates.

The default changed to enabled only after complete general and callback gates on native37 and boundary/lifetime gates on native39, whose C++/UI source maps match. `host-cache-boundaries-07` passes 1182 checks including actual native attribute deletion, retained Undo lifetime, no detached Live publication, same-instance restoration, native cycle rejection and recovery. Native41 separately verifies the enabled default and its bounded planar-Displace accessory appearance fixture. Native45's imported workflow exercises the numerical support correction on the selected original models. These historical receipts remain separate from native46's matching final functional campaign, which repeats the cache, callback and boundary scopes. The [release report](RELEASE_VALIDATION_0.1.3.md) is authoritative for that exact collection, opposite-order measurements and separate installer/startup evidence. Arbitrary imported models, deformers and renderers remain outside those fixture claims.

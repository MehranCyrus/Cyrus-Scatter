# Proposed recipe schema and import contract

**Subsequent implementation:** the user later authorized 0.82.5. The [current implementation and qualification](../plans/recipes-0825/PROGRESS.md) deliver the supported static core, including native Paint, while Phase 6 remains paused. This document retains the earlier design baseline and broader follow-ups; its original receipts are historical. The illustrative example remains non-loadable. Actual wire data uses the explicitly allowlisted typed controller settings and native Paint sidecars, documented in the handoff.

Revised 15 October 2026 following the user's decision: **Save Everything includes Paint.** This is a design contract, not implemented behavior. Phase 6 remains paused. No product/scene version changes accompany this document.

Read with the [report](README.md), [field map](FIELD_MAP.md), [declaration inventory](PARAMETER_INVENTORY.csv), [implementation plan](IMPLEMENTATION_PLAN.md) and [validation matrix](VALIDATION.md). The [three-layer example](example-recipe.json) is illustrative JSON; it marks itself non-loadable and does not enumerate every field or contain a real native Paint export.

## Formats, scope and completeness

Keep `cyrus.settings-preset` version 1 and its typed categories unchanged. Use a separate `cyrus.planting-recipe` discriminator, format version 1 and `.csrecipe.json` manifest. Product version, recipe format version, native attachment version and evaluation contract are distinct.

Vendor evidence informs the scope: [Chaos documents configuration save/load via MAXScript](https://forums.chaos.com/t/request-scatter-library-similar-to-forestpacks-library-browser/155909); [iToo's 2 July 2025 reply describes a multi-Forest library limitation](https://forum.itoosoft.com/forest-pro-%28%2A%29/can-you-add-a-few-forest-packs-as-a-single-preset-in-the-library/). Neither establishes a current, asset-complete multi-owner contract. Cyrus's rules below are independently specified, with full evidence limits in [SOURCES.md](SOURCES.md).

| Save choice | Required content | Meaning of success |
| --- | --- | --- |
| **Save Everything — default** | All authored state of the selected layers, including disabled/dormant values, ordered Paint documents, groups, Paths/Bands, masks, spacing, applicable Edit/radius records, presentation preferences and dependency roles | Every owned authored field is accounted for. Paint is never an optional unchecked box in this mode. Unsupported data prevents a successful complete export. |
| **Portable planting rules — explicit alternative** | Selected reusable settings and roles; the user chooses any omitted receiver-specific Paint/Edit content | A visible omission manifest accompanies the copy. This is a partial recipe and cannot claim full fidelity. |
| **Collect referenced assets — independent option** | External `.max`/proxy/material/texture assets and supported host-native dependencies, with a manifest | Package completeness is checked separately from authored Scatter completeness. A complete setup with external roles is not a self-contained scene. |

“Everything” is scoped to the chosen Scatter setup/layers and their declared dependencies; it does not mean the entire Max scene, application preferences, Undo history, installed plugins or licensing state. Save all layers selects the full ordered set. References to unselected collision partners remain external layer requirements, with a shortcut to include those layers; never drop them silently.

The first delivery supports typed static parameter controllers. Animated, wired or third-party controllers that cannot be preserved identify their owner/property and block **Save Everything**. A separately named **Snapshot at time** is an explicit lossy mode, available only after its own implementation and validation. Optional host asset packaging can later preserve supported native controller graphs. JSON is not a generic serializer for arbitrary Max objects.

Save captures authored pending settings, including edits waiting in Manual mode; it does not force Update or substitute the last published recipe. Report “pending changes saved” when applicable. A live Paint gesture must finish or cancel before capture; do not silently commit a half gesture. Deleted receivers can leave valid orphan Paint documents, which are still saved with unresolved binding context. Invalid/unknown data remains untouched in the source scene and produces an explicit save error.

## Required records and invariants

| Record | Required interpretation |
| --- | --- |
| `format`, `formatVersion` | Exact supported discriminator/version; no executable fallback. |
| `metadata` | Stable library recipe ID, bounded label/description/tags and optional thumbnail. Names are not identity. Production import rejects `architectureExampleOnly`. |
| `units` | Metres, instances/m², degrees and dimensionless multipliers at the typed boundary. Native Paint retains its saved unit scale separately. |
| `compatibility` | Host year, evaluation contract, required capabilities and attachment codecs. Scene schema 58 is context, not proof an importer exists. |
| `exportScope` | `complete-setup` or `portable-rules`; selected owners, controller policy, asset policy and omissions. Complete mode has no omitted owned authored fields. |
| `setupPreferences` | Captured controller enable/update/presentation/output preferences. Application differs between Add and Import setup. |
| `bindings` | Receiver/source/map/field/path/area/Analyzer/container/external-layer role IDs and requirements. No temporary handles. Names/paths are hints only. |
| `curves` | Unique curve IDs, domain, actual samples and lossless editable graph data where present. Disabled curves remain saved. |
| `layers` | Array order is evaluation order. File-local IDs, authored settings, source rows, memberships, Paths/Bands, areas, Paint, filters and spacing. |
| `paintDocuments` / attachments | Lossless native vector payloads plus version, byte size, hash, saved units, receiver frame/binding signature and owner role. Never a preview raster. |
| `authoredEdits` | Binding-aware per-instance changes and radius overrides. Authored locators differ from cached output arrays. Unsupported preservation blocks complete export. |
| `spacingRelationships` | Scope, two owner role IDs, enabled flag, multiplier, gap and XY/3D metric, including disabled rules. Preserve layer priority and protected-Edit semantics. |
| `dependencies` | Required/optional external resources and shared-reference relationships. Preserve multiple intentional rows and shared maps. |
| `importPolicy` | Action, binding decisions, identity/remapping and failure policy; not permission for scripts or downloads. |

Every reference resolves in its namespace. Source row IDs differ from model roles; two rows can reference one model with different settings. Convert aligned-array indices into explicit ID edges. Missing references remain unresolved until bound; a same-name object is not identity.

Preserve seeds and dormant settings. New owners, rows, Paths/Bands and areas receive fresh scene IDs. Receiver sampling identities and Edit locators require one consistent remap; do not transplant foreign scene identities or promise identical plants after cross-scene import. Same-scene `.max` reopen is a separate identity-preserving operation.

## Field completeness and defaults

The [field map](FIELD_MAP.md) is the capture/apply checklist. [PARAMETER_INVENTORY.csv](PARAMETER_INVENTORY.csv) records every current controller parameter declaration, default expression and policy category. Identity, preference, derived output and unsupported fields have explicit dispositions. Native Paint, Edit and container state are separately mapped because controller declarations alone are insufficient.

Production complete exports write every supported authored field, including disabled masks, inactive source rows, unused basic/advanced transforms, dormant manual radii and custom curves. Do not infer missing content from future plugin defaults. Missing required fields, unknown enum values, conflicting duplicate representations or unrecognized authored blocks are errors. A neutral default is allowed only where the frozen format explicitly defines it. The compact example omits default fields for readability and is not a production complete-export fixture.

Translate enums explicitly: mesh components UI 1/2/3 become X/Y/Z and native 0/1/2; Band sides and Scale Off/Follow Density/Custom remain distinct; density percent is not scale; assignment-group colors are not identification colors. Retain Consecutive widths and dormant Independent ranges, and vice versa.

All numeric values must be finite and within engine bounds. Reject unsupported combinations, including Accepted target with Independent Bands or nonneutral Band density. Never clamp or switch modes just to load a file. Resource admission includes destination owners, retries and protected edits.

## Paint is required authored content

Current `cyrus::brush::Document` contains a surface fingerprint, canonical local-XY contours and `Falloff`; `encode`/`decode` preserve that payload. The Max Paint object also owns a target reference and saved radius/erase option. Editable graph handles and area density/name/order live outside the payload. Save Everything accounts for all of them. [Native types](../../AminScatter/include/brush.h), [codec](../../AminScatter/src/brush.cpp), [host storage](../../AminScatter/src/brush_host.cpp), [owner model](../../AminScatter/tools/ui/templates/unified-core.ms).

Required capture:

- Area ID, name, enabled state, parent and saved order; include disabled, empty and orphan documents. A cleared empty document differs from missing data.
- Receiver role and original binding signature; evaluated local geometry/topology identity, saved system-unit scale and object frame/metric context. A rename alone does not invalidate compatible geometry.
- Canonical contour payload with islands and Erase holes. Preserve precision, contour order/winding and format version; do not reconstruct from feedback or a spline approximation.
- Layer `paintEnabled`/`paintDensity` and per-area `paintSetEnabled`/`paintDensity`. Disabled Paint, empty Paint and absent Paint remain distinct.
- Inside/outside fades, independent density/scale flags, edge/inner scales, curve samples and editable graph handles, including inactive settings.
- Display/color preferences and saved brush radius/mode. Active gesture/pointer, preview buffers and active host tool are excluded. Import does not start a brush or automatically enable an expensive overlay.

The native payload is authoritative for contours and native falloff. Typed manifest summaries are derived and must agree; graph handles supplement it. Compatible no-conversion save/load preserves payload bytes and verifies their hash. Hash equality is not receiver compatibility. Store a bounded binary sidecar with relative path/hash/size; small inline base64 can use the same codec and limits. Never embed SDK pointers or foreign node handles.

No complete portable recipe adapter currently exists for this object. Implement a bounded host-thread capture/staging bridge around the native codec; a MAXScript float conversion may lose precision. Stage a new document before assigning its validated target. Do not mutate the source or bypass author/projection checks.

### Restore and transfer decisions

| Situation | Required action |
| --- | --- |
| Compatible evaluated local geometry, frame and saved units | Explicit role binding, native validation, then new owned document. Preserve bytes/holes and equivalent coverage in qualified fixtures. |
| Same name but different geometry, topology or frame | Unresolved. Name, bounding box or face count is insufficient. |
| Different scene units / requested physical transform | Preserve original payload. Until a tested conversion adapter exists, block activation or import inactive; scaling manifest values alone is insufficient. |
| Different terrain | Qualified explicit transfer with bounded preview/loss summary, or original document retained inactive. Arbitrary remesh/geodesic transfer is outside the first delivery. |
| Missing target, disabled area or empty coverage | Preserve the record and binding context. Never fall back to whole-surface scattering. |
| Unsupported projection, malformed payload or capacity failure | Reject activation/transaction; preserve prior publication and source file. Never simplify, truncate or erase automatically. |

**Import inactive for later binding** is an explicit whole-affected-layer option. Retain requested enabled state separately from unresolved activation status and preserve original data through scene save/reopen. Resolve required bindings before activation. The importer must implement/test this state or block commit; dropping `paintDocument` is not an acceptable approximation.

Optional later transfer creates a new document with a declared source-to-target mapping. Reclip/revalidate only under that operation, report lost area/holes, retain the original and support Undo. Browsing/binding never rewrites the original export.

## Other dependencies and authored Edit

Source rows preserve model/Point/Empty kind, role, weight, scale/lift, forward axis, dormant Manual radius, Auto, Follow Scale, groups and identification. Auto failure does not silently select Manual. Container membership/collection remains explicit; a one-time scan is not an equivalent policy.

Paths, Include/Exclude splines, Texmaps, Analyzers and models remain host dependencies. Bind existing objects, reference library assets or collect an optional host package. Preserve shared references. A Data Channel producer hint does not authorize rebuilding modifiers: bind/validate actual numeric output. Analyzer freshness follows its own contract; browsing cannot run Analyze.

Per-instance Edit/radius changes are authored work. Current layer-copy helpers clear some instance-radius state and cannot act as a complete serializer. A full adapter retains stack order, enabled state, deltas/deletions/copies and binding context, and translates authored locators through a qualified remap. Cached Edit inputs, selections and publication IDs are excluded. Incompatible candidate correspondence retains data inactive or blocks activation. Until a safe adapter exists, block Save Everything for affected setups; a partial export requires an explicit different mode.

Optional asset packages enumerate dependencies, hashes, plugin/material requirements and bounds. Integrity does not prove compatible pivot or renderer behavior. Do not merge assets to display a thumbnail. Keep bulky assets outside the installer.

## Import transaction and application modes

Default **Add layers** appends in saved order without modifying existing owners or global Manual/Live/display preferences. **Import setup** creates a new controller and applies captured preferences only after authored commit. **Replace setup** is a separate reviewed transaction with Undo. Category Apply retains P02 behavior. Source merge, interpolation and density blending are separate later commands.

1. Parse bounded manifest/attachments; validate versions, hashes, fields, graphs and capabilities without scene mutation. Browse metadata lazily without host evaluation or solving.
2. Capture destination identity/revision. Build a proposal listing missing/incompatible receivers, models, channels, paths, maps, Paint/Edit bindings and external spacing partners. Selection/names suggest candidates only.
3. During explicit preparation, read only data needed for compatibility/admission on the host thread. Check units, bounds, projection, Analyzer freshness, field completeness and combined demand. This is separate from passive browsing.
4. Allocate fresh identities and one remap for owners, rows, Paths/Bands, areas, groups, relationships and supported authored locators. Preserve values/seeds and existing sampling semantics. Revalidate destination and roles before commit.
5. Stage assets, records, native documents and references with scheduling suspended. Commit one Undo or roll back all newly owned objects/references and changed destination preferences. Do not delete pre-existing same-name objects during rollback.
6. Mark actual dependencies once. Manual waits for Update; Live coalesces one successor. A later solve/preparation/upload failure retains the previous complete publication while authored settings and an actionable error remain pending. Import failure instead rolls back authored state.
7. Undo/Redo restores the graph and unresolved documents under Manual/Live rules. Redraw cannot consume pending work. Repeated imports cannot share mutable Paint accidentally.

Cancel before commit leaves no scene mutation. Asset cleanup is owned/journaled; after commit use Undo. An asynchronous worker framework is unnecessary for the first importer. If later numeric work becomes asynchronous, workers consume copied data, discard stale results and keep host APIs/publication on the host thread.

## Bounds, storage and failures

Proposed first-version admission: manifest 8 MiB/depth 32; ten total populations including destination; 257 samples/graph points per curve; 200,000 vertices per Paint document; one million aggregate imported contour vertices; 8 MiB decoded bytes per Paint attachment; 64 MiB total authored attachments; 256 Paint records. Aggregate limits are design choices to qualify, not current product limits or guaranteed memory use. Reject with owner/count details; never truncate. Existing category limits remain 64 KiB/depth eight/512 browser entries.

Root candidate admission includes existing owners, retries/protected records; the example's 430,000 caps alone do not establish admission. Account for decoded attachments, old/new documents, Undo copies and staged publications together. Heavy asset collection has a separate explicit byte/file budget.

Extend current storage/codec concepts; no separate executable. Keep the category directory. Recipes use a configurable Documents known-folder library root; indexes/thumbnails are disposable/lazy. Reject escaping paths, duplicate keys, nonfinite values, malformed UTF-8 and unsupported versions. No automatic downloads or executable recipe data.

Write temporary files on the destination volume, read back/verify, then publish the manifest last. Use immutable versioned attachment folders so readers see one complete generation. Failed saves preserve the prior recipe. Detect overwrite conflicts. Rename does not prove power-loss/network durability. Opening a file never upgrades it in place.

## Units and acceptance

With `u` scene units per metre, typed distances become `distanceMetres * u`; scene area becomes m² by dividing by `u²`. Dimensionless values remain unchanged. Native Paint/Edit bytes retain their own saved-unit context and separate conversion guards. Altitude uses its declared world datum.

Required comparisons:

- Category capture/apply/capture: precisely its supported fields.
- Complete capture/import/capture: all authored fields, dormant values, roles, order, curves, Paint bytes/holes and relationships, modulo declared identity remapping/bindings.
- Same-scene `.max` reopen: saved identities/output under the qualified engine/input pair.
- Different-terrain import: preserved design and original Paint with honest compatibility status, not guaranteed identical plants.
- Cache reuse: unchanged output and unchanged relevant evaluation/generation/preparation/upload counters.

[Validation fixtures](VALIDATION.md) are pending. Documentation checks do not establish a working importer, runtime qualification or artist acceptance.

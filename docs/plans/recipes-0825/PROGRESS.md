# 0.82.5 complete static authored recipes

15 October 2026. The user authorized a Git backup, implementation of the reviewed recipe plan, and Scatter **0.82.5**. **Phase 6 remains paused.** This is a separate delivery of the current P10 core. Analyzer 0.14 and MCP package/plan 0.73.0/0.73 stay independently versioned.

## Baseline and version decision

The pre-implementation source/test/documentation checkpoint was committed and pushed to `origin/codex/workflow-0.75`: `6658ff609d8e195609e58633b680c797e0cb56d7`. Remote HEAD was verified after push. It includes 260 files and the preceding 0.82.3/0.82.4 code and reviewed research. Artist scenes, installers, artwork, design-reference folders and unrelated presentation/website experiments stay local. Five existing whitespace findings in imported historical AI plans were preserved verbatim.

The delivered predecessor is 0.82.4. The user selected the next small step for static multi-layer recipes, including Paint, explicit dependency binding and transactional import. Scene schema **58**, calculation model **CyrusUnified1**, native class IDs and the existing planting pipeline remain unchanged. Recipe format and native recipe capability are independently **1**. Brush scene persistence gains an additive last-known receiver-frame chunk `0x7303`; the canonical Paint coverage codec is unchanged. Older orphan documents with unknown frames remain unknown.

## Delivered behavior

- **Layers > Recipes... > Save Everything** captures selected layers in evaluation order. It includes all supported authored settings, dormant/disabled values, source roles/weights/scales/radii/lifts, seeds, Paths/Bands, curve samples and editable handles, include/exclude and Analyzer dependencies, mesh/slope/altitude settings, internal/external spacing relationships and presentation preferences. Manual pending values save without Update.
- Paint is included by default: active, disabled, empty and orphan documents, exact native coverage bytes, multiple islands, holes, density, fades, scale curves, brush options and receiver frame. Paint export performs no target polling, field preparation or brush commit. Active gestures block save.
- Models, receivers, Paths, texture maps, Analyzers, source containers and unselected spacing partners remain **external scene roles**. Review bindings before import; unique-name matching is an explicit suggestion. Duplicate or missing names do not bind automatically. Compatible container settings and ordered saved membership are checked without editing that container.
- **Add layers** preserves destination controller preferences and Manual/Live mode. **Import as a new setup** restores saved controller preferences. Fresh scene owner/source identities are created, relationships and Band membership remap, and the complete authored import commits as one Undo. Redo restores the same imported identity. Field overlays are explicitly off on imported layers.
- Bound Paint requires compatible evaluated geometry, receiver frame and saved system units. Incompatible Paint rejects the entire import and preserves the existing graph/publication. Already orphaned Paint stays unbound with its original bytes and known frame, including after scene reopen. There is no arbitrary-terrain projection or full-surface fallback.
- Paint-free typed distances convert through metres into destination system units. Density remains plants per square metre. Imports obey the ten-layer capacity and existing aggregate calculation admission.
- Manual import leaves the complete previous planting until explicit Update. Live Add publishes one complete successor; relevant edits follow existing dependency scheduling. Unrelated scene edits, selection and time do not rebuild static recipes. A later failed calculation retains the prior complete publication and recovers after correction.
- The local library defaults to **Documents/CyrusScatter/Library**, with a custom-folder picker. It admits 128 manifests per page and caches at most 512 path/size/mtime metadata records. Bad entries are isolated. Refresh is explicit; no directory polling or thumbnail solve occurs on idle. Unchanged list rows are retained.

## Completeness and deliberate limits

The explicit allowlist captures **228 typed settings**. Other current declarations have explicit topology, identity, Paint, relationship, unsupported-data or derived/output handling. Two Python checks compare the allowlist with current declarations and typed-distance definitions. This is a static authored recipe, not a generic Max object serializer.

**Save Everything refuses unsupported authored data rather than silently omitting it:** actual Scatter Edit transforms/deletions/copies, per-instance radius overrides (including Paint Area records), nested Paint ownership, animated/wired/expression or unknown parameter controllers, invalid ownership and root-owned unsupported Paint/radius data. Selection alone in an otherwise unchanged Edit modifier is not authored placement data. The scene remains intact when save is blocked.

The current core does not implement asset collection, packaged proxies/materials/bitmaps, automatic terrain rebinding, lossy Portable rules/Snapshot-at-time export, blending, Replace/merge policies, a unified category/recipe dialog, search, tags, thumbnails, bundled demo assets, shared receiver-cache redesign, a field graph or P06-P09 features. Their reviewed follow-ups remain in the [broader plan](../../Scatter_Data_Recipes_Research_2026-10-15/IMPLEMENTATION_PLAN.md). Phase 10 is not marked wholly finished, and Phase 6 is not resumed.

## Format and bounds

See [the implemented wire format](FORMAT.md), the [earlier design contract](../../Scatter_Data_Recipes_Research_2026-10-15/PRESET_CONTRACT.md), and `AminScatter/src/recipe_fields.inc`. The earlier semantic three-layer example remains illustrative and cannot be loaded.

The production manifest is `.csrecipe.json` with discriminator `cyrus.planting-recipe`, `formatVersion: 1`, engine, scene schema and host identity, saved unit context, typed root settings, role table, ordered layers/Paint Areas and spacing relationships. Paint bytes live in immutable `paint-<recipe-id>.payload` sidecars with byte count and SHA-256. Keep manifest and companion folder together. Files contain data, never executable MAXScript or transient host handles.

Capture checks the aggregate Paint document/byte budget as it proceeds, before appending an oversized document. Limits include 8 MiB manifest, depth 32, ten layers, 128 Paint Areas per layer, 256 native Paint documents, 8 MiB per Paint payload/64 MiB total, one million aggregate contour vertices, 4,096 external roles and 256 spacing relationships. The native Paint codec retains its own vertex limits. Unknown/duplicate fields, wrong types, nonfinite values, invalid enums, broken relationships and unsupported versions reject. Attachment reads are constrained to the package directory. Metadata browsing parses a manifest but does not read Paint sidecars; full Review/import verifies them.

New-file saves use owned temporary files/folders, read back their data, publish attachments before renaming the manifest, and clean their own staging after failure. Existing recipes are not overwritten. Filesystem and path failures are reported. This is not a power-loss/disk-durability certification or a concurrent writer protocol.

## Source and qualification

The final native candidate is `build/recipes-0825-20261015-01/native-06`. The final script-only stage is `build/recipes-0825-20261015-01/script-11`, verified against every unchanged native input and native binary. The generated script SHA-256 is `c049c2d332033c7afca9a51f190ff0afa9dd9956bd07c1e5ca61442862416ffb`. Detailed frozen inputs and loaded/payload identities are in [the receipt](QUALIFICATION.json) and [package receipt](PACKAGE.json).

Required contracts: F01/F03 ownership/dependencies, F02 stable identity/randomness, F04/F08 scheduling/reuse, F05-F07 bounds/publication/host threading, F09-F11 geometry/units/persistence. Workers/calculation services were not redesigned. Knowledge generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3` was stale (16/38 verified); F11 retrieval rejected changed evidence. Current source was inspected directly; no index refresh was performed.

| Evidence | Result and practical limit |
| --- | --- |
| Max 2027 SDK build/native tests | Native-06 configure/build pass; **33 suites pass**, including recipe, Paint, masks, filters, placement, spacing, publication and independent licensing tests. |
| Generated integration | **281 controls / 36 capability families**, current script, inventories and catalog agree. This does not certify physical UI input. |
| Python tests | **163 pass** on the final run; log `build/recipes-0825-20261015-01/python-final.log`. |
| Complete recipe fixture | Three static layers with model weights, mesh mask, slope, Paint islands/hole plus disabled/empty areas, Band density/custom scale and spacing. Exact native Paint/file round trips, pending Manual capture, fresh identities, six-layer Add, new setup, missing/incompatible binding rollback pass. |
| Full publication comparison | Final Python witnesses hash all eight row fields: all twelve matrix values, source, candidate/output ID, face, barycentric anchor, Band owner, protection and row version. Native Undo/Live tests compare each field explicitly. The older `cyrusEditFingerprint` checks only position/source and is not used to claim full row equality. |
| Native lifecycle/guards | One Undo/Redo, late graph validation rollback, allocator/relationships/publication preservation, units, radius overrides, actual Edit delta and controller rejection pass. Orphan Paint bytes/frame survive import, scene reopen and re-save. Explicit model/dormant-map substitution, container membership rejection and duplicate names pass. |
| Actual UI handlers | Recipes button, Save Everything, Review, explicit name suggestions, Import Add and Close pass. Thirty refreshes preserve calculation/preparation/mask/upload counters. This is scripted UI-handler evidence, not pointer/DPI/tablet testing. |
| Scene reopen | Exact Paint payloads, accepted counts and full eight-field SHA-256 witnesses match the saved setup. Manual mode remains saved. |
| Live | Exactly one complete Add successor; independent pre-existing full rows unchanged; unrelated edits/selection/time cause no rebuild; one relevant imported parameter edit produces one successor. |
| Calculation failure/recovery | A missing mesh channel after a valid import retains all eight fields of the previous publication; correction publishes the whole imported graph. |
| Library performance | 2,002 local manifests, including two damaged entries; 128 per page and 512 cached records. Final warm page median/p95 was about 10/14 ms, with a 452 ms cold page. Earlier qualified warm p95 was about 16 ms. A later storage-churn campaign measured 119 ms and failed the proposed 100 ms target; the existing-library rerun measured about 98 ms p95. Cold page reads varied from about 0.8 to 4.5 seconds. No placement/preparation/mask/upload work was caused by browsing. These are observed local timings, not universal latency guarantees. |
| Idle | A 60-second event-loop observation on 200,000 requested candidates checks publication/build/preparation/receiver/mask and native upload counters. The corrected observer passed at 61.0013 seconds with all sampled counters unchanged; the qualification receipt pins the witness. |

Final exact-pair host evidence is under `build/mcp-qualification/foundation-roadmap-recipes0825-20261015-05`; preceding development campaigns under suffixes `-01` through `-04` retain their own inputs/results. The final campaign passes **93 scoped host assertions**, including a real 256/257-document boundary and an exhausted byte-budget guard. Source, package and loaded identities are checked separately; version captions are insufficient. Only Max 2027 was launched/tested. Installer execution, normal-profile artist acceptance, physical input, long sessions, renderer/material qualification and presented FPS remain separate. No artist Max process was installed into or restarted.

## Iterations and evidence limits

Development builds exposed C++20 JSON/path conversion and MAXScript macro collisions, corrected before native-04/05/06 passed. Cold MXS capture exposed late-bound globals, corrected with explicit declarations. Native MXS exceptions use `throw()`; relationship staging avoids MAXScript `copy` returning `OK` for its prior expression. Array equality is checked per element for container membership and publication witnesses.

The first library implementation reset identical rows and used linear metadata lookup; p95 reached 128 ms. Bounded lookup and unchanged list-row reuse reduced that work. A long temporary Paint-directory name failed in the deep fixture path; sidecar names now use one short recipe ID. Orphan frames initially lacked scene persistence; the additive chunk and cloned/imported frame retention resolve that case. All exact Paint bytes remain unchanged.

Python's enclosing execution hold is unsuitable for qualifying native import Undo. Functional fixtures use `pymxs.undo(False)`; owned-scene recovery explicitly clears their disposable nested holds between campaigns. Undo/Redo is tested in separate native MAXScript events. These recovery commands must never be applied to an artist scene.

One final Python transport run hit Windows socket abort 10053 in an unchanged rejection test (162 pass/one failure); the full subsequent run passes all 163. A Live setup request exceeded its 120-second request wait, then completed successfully; the timeout was not cancelled and no competing Max request was submitted. Cold/setup latency remains a separate limitation. The first idle observer had a logging precedence error after recording identical before/after counters; its corrected successor is the delivered witness. Earlier failed/partial iterations do not establish acceptance.

## Delivery and artist checks

The [Max 2027 installer](../../../dist/CyrusScatter-0.82.5-20261015/CyrusScatter-0.82.5-Max2027.mzp) contains the exact qualified script/native pair. Archive integrity, member hashes, version and Max 2027 guards are verified in [PACKAGE.json](PACKAGE.json). The archive is **980,862 bytes**, SHA-256 `eee6a4252da036e01766f65b13df7256500d37c720ab18bcb04bd4345ebc831e`. The final cold-start campaign also passed complete capture/import and scene reopen; the reopen request took about 3.6 seconds in that fresh host. The task does not execute the installer. Save your scene, run **Scripting > Run Script**, choose that MZP and **restart Max 2027** before testing.

1. On a copy, create two or three layers with different models/weights, Paint islands and an Erase hole; include a disabled Paint Area and a Band with density/scale curves.
2. In Manual mode, make a pending Amount edit. Open Layers > Recipes, select those layers and Save Everything. Plants should stay unchanged while saving/browsing.
3. Review the saved recipe. Bind all receiver/model/map/path roles explicitly, or request unique-name suggestions and inspect them. Add it to the existing setup; confirm the saved layer order, curves, holes and source assignments.
4. Confirm the destination stays Manual and the old planting remains until Update. Update and inspect both old and imported layers. One Undo removes the import; Redo restores it.
5. Import as a new setup, then save/reopen the scene. Confirm exact Paint borders and density/scale behavior. Copy the manifest and its companion Paint folder together when sharing.
6. Try an incompatible Paint receiver or missing role: import should fail clearly without adding partial layers or changing existing output. Different system units with native Paint must also reject; a Paint-free recipe converts its typed settings.
7. Change an imported setting in Live mode, then leave the scene idle and browse the library. Only relevant edits should calculate. Compare physical panel responsiveness, heavy assets and your intended renderer separately.
8. Test actual authored Edit/radius or animated settings: Save Everything should refuse the unsupported data and preserve the scene. Do not interpret the failure as a partial successful save.

## Completion checklist

- [x] Bounded separate recipe codec and explicit current-field accounting.
- [x] Lossless Paint payload capture/staging, orphan context and compatible restore.
- [x] Complete supported static capture and dependency roles; unsupported data blocks save.
- [x] Binding proposal and transactional multi-layer Add/new setup.
- [x] Local Save/Load browser with passive browsing and bounded metadata.
- [x] Native/generated/Python checks and scoped Max lifecycle/failure/Live evidence.
- [x] Final idle receipt and exact-pair Max 2027 package verification. Scoped commit/push identities are reported with delivery; installers/scenes remain ignored.

The wider recipe roadmap and artist/production acceptance remain open.

The website source import, static verification (281 controls/36 families) and local production build pass. Its existing 0.78.3 concept-gallery edition is preserved. No website upload package or deployment was produced.

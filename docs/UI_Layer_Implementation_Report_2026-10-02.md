# Cyrus Scatter Layer UI Implementation Report

Date: 2026-10-02\
Prepared for: Mehran and Cyrus Scatter development\
Product release: **0.64**\
Native library description: **0.25 — retained instanced mesh preview**\
UI revision: **2026-10-02.2**\
Test host: **3ds Max 2027.1**

**Follow-up correction:** this is the historical UI revision 2 report. The
[follow-up investigation](UI_Layer_Responsiveness_2026-10-02.md) found that the
final revision 2 script still contained the Collision control hide/show handler:
`spacing.cjs` generated it again. Therefore the removal claims and prototype
layout traces below do not establish its removal from the packaged revision 2
script. Revision 3 was withdrawn; revision 4 keeps the small generator correction
without its deferred section-loading system. Product 0.64, native-library 0.25 and UI revision numbers
identify three different components; they are not competing product versions.

This report covers the layer expansion repair, synchronized layer selection, new cached layer statistics, the follow-up repaint changes, and correction of the test session that loaded the wrong native engine. It explains what changed, why it changed, what the tests establish, and which checks remain open before wider use.

The result is a separate UI candidate using the exact native engine from the existing 0.64 release. It passed 76 UI regression assertions, seven retained-Mesh integration assertions, and a subsequent interactive resize check. Browsing the tested layer controls did not regenerate placements or upload Mesh buffers again. No additional viewport FPS improvement was measured in this UI round.

## Findings and delivered behavior

| Reported problem | Finding | Delivered behavior |
| --- | --- | --- |
| A layer arrow changes but the contents do not appear on the first click | The lazy-loading handler interpreted the expansion event backwards and built the controls when closing the layer | The first expansion creates its six child sections; reopening reuses them |
| The layer being inspected and the manager selection can disagree | Header expansion and manager selection were separate interaction paths | Opening a header selects its layer; clicking a manager row or pressing Enter opens the corresponding layer |
| Layer Manager gives little information about each layer | Cached generation metadata existed but was not presented beside the names | Count and State columns, exact selected-layer details, tooltips and a total for enabled layers |
| Opening sections looks like the plugin refreshes | Parent layout could run twice; a workaround hid and showed every control in an open Collision / Relax section | One final parent layout on expansion; the blanket hide/show cycle is removed; unchanged control properties are left alone |
| The new UI demo did not show the latest Mesh performance | The earlier private UI session loaded 0.63 native files | A replacement private session and package use native files identical to 0.64 |
| Resizing can lose nested expansion state or cause extra reconstruction | Width bookkeeping used a transient host window size; collapsed layers had no mounted children from which to restore state | Separate remembered content width, deferred width reconstruction, and pending section states for collapsed layers |

## Why the earlier Mesh comparison was invalid

Cyrus Scatter combines a MAXScript interface with compiled native plugins. An updated script on disk does not replace a native DLL already loaded into a running Max process. Both parts must be identified when qualifying a build.

The earlier UI fixture used the older 0.63 native binaries while the local script/source already contained the newer Mesh integration. That was my test setup mistake. It was not valid evidence that your 0.64 optimization had been lost or that the new statistics made Mesh slow. The native engine in that session did not include the retained-Mesh capability under evaluation.

I corrected this by starting a separate Max 2027.1 test session with the actual 0.64 binaries, checking their loaded paths, and comparing their bytes with the existing `dist/retained-mesh-0.64/CyrusScatter-0.64-Max2027.mzp` package. The replacement package contains those same native bytes. The generated script from `AminScatterObjectDraw` through the end of the file also matches the original 0.64 package.

The previous private fixture was saved before it was closed. The corrected fixture was saved as `Cyrus_UI_064_R2.max`. The artist's open `SaveSelect 2.max` session was preserved, and the original scene file's SHA-256 matched the recorded value after testing.

This round did not change C++ renderer code, distribution algorithms, source geometry, final-render transport, or the existing Mesh preview limits. Other native and research changes already present in the workspace belong to earlier or concurrent work; the full dirty Git diff must not be attributed to this UI task.

## How the interface is constructed

The runtime interface uses native MAXScript rollouts and nested subrollouts in the Modify panel. Layer Manager contains a .NET Windows Forms ListView. JavaScript runs during development to generate the MAXScript; it is not executing inside the viewport as a browser UI.

The generator reads templates and applies feature stages, then writes `AminScatter/scripts/AminScatterObject.ms`. The repairs were made in those templates and stages so regeneration preserves them. A final regeneration produced the same script hash as the tested copy.

There are ten layer slots. Each can contain Source Object, Point Generation, Collision / Relax, Area, Diversity / Colors and Randomize XYZ. Creating every nested control immediately would add work when selecting a controller. The revised implementation therefore retains lazy creation: a layer constructs its children on the first expansion and keeps them while it remains mounted.

## First expansion and lifecycle repair

The event argument and the creation option named `rolledUp` have opposite meanings in the relevant APIs. For the event, `true` means expanded. For the `addSubRollout` creation option, `rolledUp:true` means create it collapsed. The old handler used the latter interpretation for the former.

The original condition was effectively:

```maxscript
if not state and not parentView.building do ensureContents()
```

It therefore ran when the layer closed. The visible sequence was an open arrow with empty contents, then a close that constructed the controls, then a successful reopen.

The generated handlers now use an explicitly named `expanded` argument:

```maxscript
if expanded and not parentView.building do (
    ensureContents()
    parentView.selectLayerView obj
)
parentView.layoutPanels()
```

The generator verifies that all ten lazy layer handlers are patched. `ensureContents()` checks whether children already exist, suppresses intermediate parent layouts while mounting them, restores any pending child expansion flags, and fits the content once. Its error path removes displayed partial children, resets the child list and restores the previous building guard before reporting the failure.

`CyrusMount` also restores the previous factory context after mounting, including when mounting throws. This prevents a nested construction from leaving the global factory target pointing to the wrong layer. These are code-level safeguards; deliberate failure injection across every control factory was not part of the recorded runtime suite.

## Layer selection and manager interaction

The host now has one `selectLayerView` path used by layer navigation. It resolves the owning layer object to its current index, updates the controller's active layer when needed, updates header labels, and synchronizes the manager.

The resulting interactions are:

- Opening a layer header makes that layer active and adds `[active]` to its header.
- Selecting a manager row updates the active layer. Clicking the row body also expands it; Enter provides the explicit keyboard expansion action.
- Clicking the enable checkbox changes the owning layer's enabled state. The row is mapped back to the layer object instead of trusting an index retained from an earlier list structure.
- Selecting an already active layer reuses its controls.
- The layer name and overlap settings correspond to the active owner.

A `selecting` guard prevents recursive selection events from starting another navigation/layout sequence. Existing row selections, name text and enabled properties are assigned only when they differ. The overlap controls refresh when the selected owner changes or the manager is explicitly opened, rather than being reset on every unchanged selection synchronization.

Add and Remove share one row, leaving room for the status summary. The button previously labelled `Refresh counts` is now `Update scatter + counts`, because that action explicitly calls the scatter rebuild. Passive statistics refresh is a separate operation.

## What the new statistics mean

The main Count column shows **placements from the last preview build**. A placement is an item in the scatter's generated placement result. It is useful for comparing how much each layer contributes, but it is not a RAM reading, VRAM reading, occupied surface area or guaranteed final-render object count.

The selected-layer details and tooltips show the exact placement count, completed preview mode/count and last build duration. For example, 1,000 tree placements can produce many more point-cloud dots. The number of dots and number of tree placements answer different questions.

| Displayed value | Meaning |
| --- | --- |
| Count | Cached placement count, abbreviated in the row when useful |
| Exact placement count | Full count with separators in the detail/tooltip |
| Preview dots | Cached Point Cloud sample count |
| Proxy shown | Cached instance count prepared for Proxy preview |
| Mesh shown | Cached instance count prepared for Mesh preview |
| Last build | Duration of the completed preview build, in milliseconds |
| Last attempt | Attempt duration when preview creation failed |
| Enabled total | Sum of available cached placement counts for enabled layers; stale or incomplete data is labelled |

The preview counts describe prepared cache contents. They are not measurements of how many instances are visible in the current camera. Build duration describes generation/preparation, not viewport frame time or the layer's share of FPS cost.

| State | Meaning |
| --- | --- |
| OK / Cached | A valid cached result exists and no known pending invalidation is reported |
| Stale / Needs update | A cached result exists, but an edit requires an update |
| `--` / Not built | No valid completed result is available |
| Empty | A successful result contains zero placements |
| Error | The preview attempt failed; the UI does not present an intermediate count as a valid result |
| Off | The controller, layer or relevant Analyzer input is disabled |
| Hidden | Preview display is disabled while valid cached statistics can still exist |

An available cached count can remain visible for an Off layer, but that layer contributes zero to the enabled total. Stale values remain visible in Manual mode until an explicit update occurs. Error state is checked independently from the `dirty` flag, because the existing engine can clear that flag after a failed attempt.

The cache also records which display mode produced the result. If a user changes the mode in Manual mode, the old count keeps its old mode label until rebuilding. A restored older cache without this metadata is labelled with an unknown mode rather than being given the current setting's possibly incorrect meaning.

## Keeping statistics inexpensive

The new `uiLayerStats()` accessor returns scalar metadata: result availability, placement count, preview count, completed mode, build time, pending-update state, error text, density-cap state and disabled-input state. It does not retrieve the placement array or iterate through preview points. The existing nine-element `cacheSnapshot()` interface was preserved.

During a passive refresh, the manager checks its row owners, reads this small record for each layer, and updates only rows whose display signature changed. Ordinary refresh keeps the existing ListView items. A changed layer structure is handled by the structural refresh path.

Background polling uses the existing 300 ms UI timer with a 500 ms minimum interval check. Under regular scheduling that is typically about 600 ms between background checks, rather than a precise 500 ms cadence. Opening the manager, changing selection and other explicit UI events can refresh immediately. The polling path is gated by the host and manager being open and by the construction guard; closing the host deactivates its timer.

This path does not call placement generation, `refreshAll()`, point-cache extraction or a viewport redraw. It avoids calling the layer enumeration helpers that synchronize scatter parameters. The measured 100 repeated refreshes left every layer's preview build count unchanged.

## Repaint and layout changes

The flashing complaint revealed unnecessary UI work even after first expansion had been repaired. The host layout code contained a workaround that made every control in an open Collision / Relax section invisible and then visible again. A section with nine controls would undergo that whole visibility cycle on unrelated layout requests as well.

I removed that cycle and inspected the Collision controls in Max after the change. They remained visible during the tested open/close interactions. Heights, positions and titles now change only when the computed values differ. Header expansion and manager navigation share a guarded path that performs one final parent layout instead of two.

| Traced action | Earlier UI layouts | Revised UI layouts | Earlier hide/show cycles | Revised hide/show cycles |
| --- | ---: | ---: | ---: | ---: |
| First layer expansion | 2 | 1 | 0 | 0 |
| Reopen an existing layer | 2 | 1 | 0 | 0 |
| Open Collision / Relax | 1 | 1 | 1 | 0 |
| Open another layer with Collision visible | 2 | 1 | 2 | 0 |
| Five requests with unchanged layout | 5 | 5 | 5 | 0 |

These are counts of executed layout work. Mounting children can emit additional event requests that the building guard suppresses. First expansion still mounts six child sections; subsequent expansion does not mount them again. Keeping lazy creation means first expansion can still take longer than a warm reopen.

The traces identify redundant work; their timestamps are not a controlled click-latency benchmark. They were collected before the final content-width bookkeeping change. The final ordinary script, without probe instrumentation, passed the later regression, Mesh and resize checks.

## Width handling and preserved state

During the investigation, changing a rollout height could cause Max to report the host window at its old 162-pixel width, even though the allocated panel width was 240. Using that temporary width as the indicator for a real command-panel resize could produce unnecessary work.

The host now remembers `contentWidth`, the width used when constructing its children. `fitWidth()` repairs temporary window geometry while separately reporting whether the desired content width actually changed. Its native window call no longer requests an immediate forced repaint. The responsive size helper uses the allocated subrollout width during construction, avoiding a stale host width before Max finishes opening the panel.

An actual width change can still reconstruct the UI. The timer defers that reconstruction until held mouse input ends. This implementation therefore reduces reconstruction and preserves state; it does not claim to resize every control in place.

Expansion state is stored by layer ownership. If a collapsed parent has no children mounted yet, its remembered child state remains in `pendingSections` until the next expansion. Width reconstruction also preserves the host scroll position. General source/stroke list selection, keyboard focus and every other editor state have not been comprehensively preserved or qualified.

## Test environment and results

Testing used a private Max 2027.1 process with private startup/plugin paths. The native module paths and identity checks are saved in the evidence directory. The UI fixture contains ten layers with 100, 200, through 1,000 placements, totaling 5,500, using a simple source mesh. This keeps the test repeatable; it is not a heavy production foliage benchmark.

The final packaged script was tested without the temporary trace instrumentation. Background autosave in the private fixture was disabled after an AutoBackup interrupted a manual interaction. No precise click latency or FPS result is derived from that interrupted interaction.

### UI regression

The recorded regression contains **76 passed assertions**, including:

- Initial width and all ten first expansions, active ownership and warm reuse.
- Manager navigation, selection synchronization and repeated active-row navigation.
- Pending section-state restoration for expanded and collapsed parents after width reconstruction.
- Guard state returning to idle after the exercised operations.
- Per-layer dirty/build counters remaining unchanged during browsing and width reconstruction.
- One hundred passive statistics reads preserving selection and build counts.
- Compact/exact number formatting and labels for Point Cloud, Proxy and Mesh results.
- Manual stale values, explicit updates, hidden preview, successful empty output, error results, disabled layers/controllers and unbuilt results.
- The unchanged nine-field cache snapshot contract.

These scripted operations exercise the live Max UI handlers. Separate mouse checks confirmed a first click on an untouched layer and nested Collision open/close behavior; there is no claim that all 76 assertions were repeated manually with mouse input.

### Statistics refresh timing

For 100 synchronous refresh calls over ten cached layer rows:

| Metric | Measured time |
| --- | ---: |
| Median refresh | 1.6789 ms |
| p95 refresh | 1.9916 ms |

This measures the manager refresh function in that fixture. It is not a frame budget measurement, and it does not demonstrate a new FPS gain. It establishes a small measured cost for the new feature under the tested conditions while preserving the no-generation requirement.

### Retained Mesh integration

Seven assertions passed with **5,500 instances representing 352,000 triangles**. The test opened/closed layer and Collision controls, then performed 30 scripted camera redraws. It recorded these counters:

| Counter | Before | After | Interpretation |
| --- | ---: | ---: | --- |
| Native generation | 7 | 7 | The retained content generation remained the same |
| Explicit upload count | 512 | 512 | No additional counted uploads occurred |
| Native draw counter | 24,619 | 24,919 | The renderer continued drawing the retained content |
| Native failure counter | 0 | 0 | No new counted native failures |
| Native ready flag | 1 | 1 | The retained display remained ready |

The upload and draw counters are process-wide instrumentation; the private process reduces unrelated activity. Draw calls are not frames. The draw increase of 300 must not be interpreted as an FPS measurement or as 300 independent camera frames.

The ten preview build counters stayed exactly `[15, 15, 6, 15, 15, 15, 15, 15, 15, 15]`. Their nonzero starting values reflect earlier fixture operations. The relevant result is their zero change during this test. Root rollout handles also stayed the same during ordinary layer navigation, showing that it did not remount those controls.

### Interactive resize

The command-panel boundary was dragged wider and back. The manager retained the selected layer, cached counts and normal width on return. The final content width was 240 logical pixels and the manager list width was 202. Preview build counts, native generation and explicit uploads remained unchanged.

Max's multi-column command panel can make individual columns narrow even when the overall panel is wide. Long layer names may still be abbreviated in that layout. Full names remain available in the selected-layer detail/name field and tooltips; narrow-width usability remains an area for further checking.

## Implementation files

Paths in this table are relative to `AminScatter/` unless stated otherwise. The listed roles describe the UI changes, not every historical change in these files.

| File | Work performed |
| --- | --- |
| `tools/ui/templates/host.ms` | Centralized layer navigation, guarded layout, conditional property writes, width bookkeeping, deferred resize reconstruction and status polling |
| `tools/ui/templates/containers.ms` | Safe factory context restoration and conditional layer section geometry updates |
| `tools/ui/performance.cjs` | Correct event polarity for all ten slots, lazy creation guards, cleanup and pending expansion restoration |
| `tools/ui/responsive.cjs` | Derive control sizes from the fitted subrollout width during initial construction |
| `tools/ui/overlaps.cjs` | Correct manager expansion refresh event |
| `tools/ui/activation.cjs` | Preserve the enable-control offset when applying the revised conditional layout logic |
| `tools/ui/generate.cjs` | Integrate the layer-status feature stage in generated output |
| `tools/ui/layer-status.cjs` | New UI revision/accessor, completed-mode metadata, manager columns and interaction handlers |
| `tools/ui/templates/layer-status-helpers.ms` | New scalar status record, number formatting and state interpretation |
| `tools/ui/templates/layer-status-manager.ms` | New cached row refresh, details, total, column sizing and selection synchronization |
| `scripts/AminScatterObject.ms` | Regenerated runtime script containing the changes above |
| Repository `tools/ui-tests/setup.ms` | Configure ten layers and known settings in the private fixture |
| Repository `tools/ui-tests/regression.ms` | Runtime regression and passive-statistics timing |
| Repository `tools/ui-tests/mesh-064.ms` | Retained Mesh integration and no-rebuild/no-upload checks |

Generator regeneration was checked for identical output, selected generator files passed `node --check`, and the scoped tracked diff passed `git diff --check`. These checks support the runtime evidence but do not replace it.

## Deliverables and evidence

| Deliverable | Location |
| --- | --- |
| Max 2027 installer | [CyrusScatter-0.64-Max2027.mzp](../dist/ui-layer-0.64-r2/CyrusScatter-0.64-Max2027.mzp) |
| User instructions | [READ-ME-FIRST.txt](../dist/ui-layer-0.64-r2/READ-ME-FIRST.txt) |
| Package and script identity | [qualification.json](UI_Layer_Evidence_2026-10-02/qualification.json) |
| Loaded native module paths | [ready.json](UI_Layer_Evidence_2026-10-02/ready.json) |
| Full UI assertion list | [ui-regression.json](UI_Layer_Evidence_2026-10-02/ui-regression.json) |
| Mesh counts and before/after counters | [ui-mesh-064.json](UI_Layer_Evidence_2026-10-02/ui-mesh-064.json) |
| Post-resize receipt | [ui-resize-064.json](UI_Layer_Evidence_2026-10-02/ui-resize-064.json) |
| Earlier layout trace | [ui-layout-baseline.json](UI_Layer_Evidence_2026-10-02/ui-layout-baseline.json) |
| Revised layout trace | [ui-layout-candidate.json](UI_Layer_Evidence_2026-10-02/ui-layout-candidate.json) |
| Original diagnosis and proposed scope | [UI_Layer_Expansion_2026-10-02.md](UI_Layer_Expansion_2026-10-02.md) |

The retained layout traces normalize MAXScript integer64 values by removing their `L` suffixes so the files are valid JSON. Their original hashes and the normalization description are preserved in `qualification.json`. The startup `ready.json` contains initial fixture statistics; the later Mesh receipt describes the actual 5,500-instance Mesh check.

The tested native and script identities are:

| File | SHA-256 |
| --- | --- |
| `AminScatter.dlx` | `a3760a31a4f49488423ee8673e261d5ee4c4a70cfb65a16158fc156575b0e3df` |
| `CyrusScatterEdit.dlm` | `4456c96fd04f6eaecdea01efa2fc72b5c48dab8e9372854b9c95b2739aac513b` |
| `AminScatterObject.ms` | `f4321c8de0d15372672fa3cff8475cb9f5a5fa600ebf9448d0b2df45a2021b0d` |
| UI revision 2 MZP | `f3387556244aa9b1d23ee0f07bf59bdf4a5e8152f02b8bdd1b6d148bf1e7f89d` |

The generated native identifier is `390d3798f210`. ZIP integrity and every manifest payload hash were checked. The package script equals the tested script, and both native files equal those in the original 0.64 package.

Raw scripts, logs, temporary instrumentation and the corrected demo scene remain under `build/mesh-integration-2026-10-02/ui-layer-status-064-01/`. The prior private scene is retained under `build/retained-integration-2026-10-02/ui-layer-status-01/`. Source snapshots are under `_local/maintenance/ui-layer-status-2026-10-02/before/` and `round2-before/`. The report/evidence files provide the useful review record without copying test binaries and scene data into the docs directory.

## Installation and repository status

The normal Max profile was not installed or hot-reloaded by this work. The artist session remained open. The corrected private fixture demonstrated the combined engine and UI separately.

To try the package in a normal Max 2027 session, save work, run its MZP through Scripting > Run Script, and restart Max. With a scatter controller selected, `$.uiVersion()` should return `2026-10-02.2`. Engine version 0.64 and UI revision 2 describe different parts of the same candidate.

The original 0.64 installer remains in `dist/retained-mesh-0.64`. The UI candidate is deliberately stored in a different directory. No normal-profile installer smoke test or rollback exercise was performed in this round. No Git commit or push was made for this UI correction or report; the workspace also contains unrelated ongoing changes that require separate staging if a backup commit is requested.

## Remaining checks and recommended order

| Next check | Why it is still needed |
| --- | --- |
| Review normal use of the candidate in Max 2027 | Confirm the first-click behavior and repaint improvements with the user's real editing pattern |
| Test normal-profile installation and restart | Package byte verification does not prove an existing user profile has no conflicting startup/plugin paths |
| Test Max 2026 | The boss uses 2026; this UI candidate was tested in 2027.1, and the supplied installer is for 2027 |
| Test 150% and 200% DPI and narrow/multi-column panels | Native rollout geometry and control clipping can differ by scaling and layout |
| Broaden add/remove/Undo and object-switch coverage | The focused suite does not exhaust every structural edit or UI lifecycle transition |
| Check source/stroke selection and keyboard focus during reconstruction | Expansion/host scroll preservation is implemented; general editor-state preservation is incomplete |
| Inspect any remaining transient flashing | Removing the confirmed visibility cycle does not rule out every host repaint transition |
| Resume Brush work after UI acceptance | Brush should use the stabilized layer ownership and UI lifecycle |

The measured conclusion is that the candidate repairs the layer interaction defects, adds truthful cached statistics, reduces redundant repaint work, and preserves the tested 0.64 Mesh buffer reuse. Heavy-scene FPS targets, CUDA/OpenCL computation, new LOD methods and procedural Brush implementation remain separate engineering work.

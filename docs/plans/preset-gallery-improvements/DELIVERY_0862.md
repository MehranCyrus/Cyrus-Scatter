# Scatter 0.86.2 — density fields, portable recipes and panel follow-up

## Current multi-host installer — 19 October 2026

**Share the universal EXE below for team testing. Version remains 0.86.2.** This extends the exact UI follow-up to matching Max 2024 and 2026 builds. The Max 2027 MZP is byte-for-byte unchanged. [Exact qualification](QUALIFICATION_0862_COMPATIBILITY.json) records payloads, tests and limits; no plugin implementation was changed for compatibility.

| Installer | Bytes | SHA-256 |
| --- | ---: | --- |
| [Universal EXE](../../../dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Setup.exe) | 31,379,968 | `32702524d7c43fe3b18df73f9ce554d1b0ed7edbe440dc8ca76acef270b1c612` |
| [Max 2024 preview MZP](../../../dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Max2024.mzp) | 10,279,028 | `e54711b8081f45233ebf372e16a5fa22d9b6a953f8264cf900c6d4e599df1cbb` |
| [Max 2026 MZP](../../../dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Max2026.mzp) | 10,373,938 | `d477ed6fc3fbfab4ddbdb83b7b1939be9bd055d2fe13f32da0bcabbe0df60a89` |
| [Max 2027 MZP](../../../dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Max2027.mzp) | 10,688,793 | `5c8900f5a8f1341f15b125abdadee3801a07c233165655b18380268c3236f125` |

| Host | Qualification |
| --- | --- |
| Max 2027 | Exact unchanged UI follow-up pair and MZP; its scoped runtime and 100/150% UI evidence remain applicable. |
| Max 2026 | Matching SDK/.NET 8 pair; fresh owned-host density, channel, library, complete image/Paint Save, Undo/Redo, late-failure recovery, panel, dropdown and idle checks. |
| Max 2024 | **Preview only.** Matching SDK/.NET Framework 4.8 pair, native and managed tests, exact installer checks. No runnable local Max 2024 is installed; scene, notification, viewport and render behavior remain unqualified. |

Both older SDK builds pass **45 native tests**. Their actual managed assemblies each pass **41 checks**, including patterns and layouts at default/100/150/200% scripted scales. The universal EXE passes **68 distribution checks**: three host descriptors, 2024 preview label, exact payloads, recipient-profile paths including Unicode, bundled examples and starter masks, repair, 0.86.1 upgrades, interrupted-upgrade rollback, cancellation and preserved personal-content sentinels. Tests use disposable local paths; they are not tests on another physical Windows machine.

Max 2026 verifies all eight examples on matching-format scene copies, additive layers, stable pre-import publication, exact Undo/Redo, complete image/Paint custom Save and reload, procedural Noise baking, missing dependencies and late-failure retention. Count changes through 250,000 preserve Undo and reuse sampled images; warm idle and gallery browsing do not solve/upload. Empty/image/procedural thumbnails, More settings, full-width names and the actual Modify controls pass. The packaged MZP wrapper also executes successfully inside the redirected Max 2026 profile. Physical interaction scope is recorded in the receipt.

**Test correction:** the first painted-example Undo assertion captured its baseline inside the cold scene-load call stack. A no-import reproduction showed deferred restoration of the saved native publication changing that snapshot before Load. The corrected fixture returns through host callbacks, explicitly updates and verifies a stable baseline before import. All eight repeat witnesses pass; the first failure and diagnostic evidence are retained. This is a fixture correction, not a plugin-code fix.

The EXE contains eight ready examples, matching-format scene copies and **Uniform, Soft patches and Wide bands**. It installs for the Windows user running it using their initialized Max profile. Open the intended Max once, save/close it, select its year in the EXE and Install / Repair, then start/restart Max. For custom Max installation paths use **Scripting > Run Script** with the matching MZP, then restart. The EXE is unsigned and requires Windows .NET Framework 4.8. No Max 2025 or earlier-than-2024 payload is included.

Team licensing remains enabled: recipients need their own valid generated activation key. The installer carries only the public verification authority. Personal recipes remain in that user's Documents/CyrusScatter/Library; installation preserves personal content and activation. No artist installation/restart, Git push, knowledge activation or further roadmap work was performed. A teammate must validate Max 2024 before treating it as runtime supported.

## Qualified UI follow-up — 19 October 2026

**Retained Max 2027 qualification; the universal distribution above is current. Version remains 0.86.2.** [Exact qualification](QUALIFICATION_0862_UI.json) supersedes the earlier installer pair; earlier receipts and artifacts remain historical evidence.

| Current installer | Bytes | SHA-256 |
| --- | ---: | --- |
| [Max 2027 MZP](../../../dist/CyrusScatter-0.86.2-20261019-ui02/CyrusScatter-0.86.2-Max2027.mzp) | 10,688,793 | `5c8900f5a8f1341f15b125abdadee3801a07c233165655b18380268c3236f125` |
| [Unsigned Max 2027 EXE](../../../dist/CyrusScatter-0.86.2-20261019-ui02/CyrusScatter-0.86.2-Setup.exe) | 10,725,888 | `17767804a1d86625f13726cf8b3d02d47b125d73e91c9580cc789d80ebc15d95` |

Save your scene, run the EXE **or Scripting > Run Script** with the MZP, then restart Max 2027. The version caption is unchanged. No artist installation/restart or Git push was performed. Further roadmap work and knowledge activation remain paused.

### What changed

- Fixed first-click dropdown dismissal. Native message tracing reproduced a focus transfer from the combo to its outer Qt host. The owned input hook now establishes that host focus before the original combo handler runs. Selection, keyboard, dismissal and wheel behavior remain native. No timer, placement evaluation or buffer upload is added.
- Amount now says **Use image**, with **Choose pattern** above paired **Image / Map** buttons. Map opens Max's browser directly with no image prerequisite; choosing a map enables the input. Cancel preserves it. The selected-map field appears only when assigned and retains native drag/drop. Empty thumbnails reserve no blank row.
- Bundled **Uniform, Soft patches and Wide bands** as three original starter masks. This supersedes the earlier empty-product-catalog decision at the user's request. Final artwork can still replace/extend them later.
- Disabled image/channel controls collapse. Explanatory paragraphs move to tooltips. **More settings / Fewer settings** groups image sampling/portability, mask display and population/retries directly beneath its button.
- Models now match Layers: Name label and color, then a full-width name edit. Both list views ellipsize only the name and reserve space for metadata. Full authored names, including separator characters and non-ASCII text, remain unchanged and are available in the edit/tooltip.
- Grayscale thumbnail black is opaque instead of being the default transparency key. The existing bounded native stretch display is retained. Pure magenta in a custom color thumbnail remains a presentation limitation; Show mask and density sampling are unaffected.

### Evidence and artist checks

Native **45/45**, Python **175**, managed gallery **42** and installer distribution **35** checks passed. Generated/catalog consistency accounts for 320 controls. Exact source, package and loaded native/script identities are recorded. Native tests ran on native01; pair03 reused its verified binaries for the final UI script and received fresh host tests.

Owned Max 2027 tests at **100% and 150% UI scale** cover empty/image/procedural/missing-map panels, Map/Clear, Undo/Redo, panel and scene reopening, long names, More settings and horizontal layout bounds. Physical first-click dropdown tests survive idle/status refresh; wheel and background drag work. A packaged meadow loaded through the visible library onto a selected plain terrain. All eight examples pass compatible-terrain Add/Undo/Redo. Saved image/Paint/model recipes, missing dependencies and late-failure rollback pass in the final 100% campaign. These scales do not establish physical mixed-monitor or 4K-display qualification.

The final campaign also checks density/mesh/combined fields, Data Channel edits, persistent mask refresh, Manual retention, relevant Live updates, unrelated animation and heavy idle reuse. Candidate count changes through 250,000 retain exact Undo and reuse the sampled image. Fifty passive binds do not calculate, prepare or rebake.

**Pending is expected in Manual after edits.** It means the previous result is retained until Update; it does not mean background calculation. Explicit Update cleared every pending layer in the three-layer fixture; passive binding/idle then kept the same clean publication. In Live, persistent Pending after a relevant edit requires checking diagnostics.

Artist checks: reopen Amount with no map; choose each starter pattern; choose a Max map directly; reopen dropdowns after clicking elsewhere; use More settings, scroll and drag; rename Layers/Models with long labels; confirm metadata remains visible; press Update and check Pending becomes OK. Existing recipe/channel/Paint compatibility rules still apply.

## Earlier same-version correction — 19 October 2026

**Historical correction installers, superseded by the UI follow-up above. Version remained 0.86.2 at the user's request.** The [correction receipt](QUALIFICATION_0862_CORRECTION.json) supersedes the original installer pair below; the original receipt and artifacts are preserved as historical evidence. The original demo ZIP remains compatible and was requalified against the corrected pair.

| Current installer | Bytes | SHA-256 |
| --- | ---: | --- |
| [Max 2027 MZP](../../../dist/CyrusScatter-0.86.2-20261019-correction01/CyrusScatter-0.86.2-Max2027.mzp) | 10,634,526 | `045a2dc9c0f9779a408e7c1d26a55961f8bbbcba69e8822608d1b3f082b09124` |
| [Unsigned Max 2027 EXE](../../../dist/CyrusScatter-0.86.2-20261019-correction01/CyrusScatter-0.86.2-Setup.exe) | 10,671,616 | `462d12b6f1ba710cdaaf48743e57734ec39d549fa429d324fe2e65b807ea879f` |

Save your scene, run the EXE **or Scripting > Run Script** with this MZP, then restart Max 2027. The visible version caption is unchanged; use these artifact paths and hashes to distinguish the correction. A same-version upgrade/repair was tested in disposable paths. No artist installation or restart was performed.

### Reproduced cause and correction

The installed script matched the original delivery. Its generated line 10552 assigned `undefined` to a MAXScript BitmapControl when Amount bound a layer without a map, a procedural Noise map, or an empty Bitmaptexture. All three reproduced the reported exception in an owned Max 2027 host. Earlier tests had mounted Amount only after assigning bitmap images, so they missed this normal artist workflow.

Physical checking also revealed that BitmapControl cropped the image instead of showing the whole tile. Amount now uses native **ImgTag with `#bmp_stretch`**, which supports clearing an empty image and displays the full tile. The generator, semantic inventory and help catalog recognize this control. Browsing does not render a procedural map, create resized image copies, close map-owned bitmaps or change authored density settings. Autodesk's [ImgTag API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/Rollout-User-Interface-Controls-3/GUID-0A492074-4A5B-4D18-B65A-E859FC8E2454.html) documents the control; actual Max probes and the full generated rollout tests establish this correction's behavior.

### Correction qualification

- Fresh empty setup, no map, bitmap, Noise, empty/missing bitmap, Clear, actual picker callbacks, basic/Advanced, Undo/Redo, panel reopening and scene reopening pass in Max 2027 at 100% and 150% UI scales. Every loaded recipe layer's Amount page is checked, including layers with no image.
- All eight bundled examples pass compatible-terrain Add/Undo/Redo. Library new-setup and additive workflows, saved image/Paint/model recipes, transformed mapping frames, saved-scene reopening, missing dependency preflight and post-staging failure rollback pass.
- Existing density/preview tests pass: projection/UV/channel components, image/mesh/combined numeric fields, explicit procedural Bake, persistent Invert/Undo, real Data Channel Curvature edits, stale-field handling, Manual retention, relevant Live updates, unrelated animation and idle reuse. Count changes through 250,000 preserve exact Undo and reuse the image tile. These fixtures are not an all-scene performance guarantee.
- Fifty passive Amount binds leave calculation, preparation and density counters unchanged. The generated layout audit checks visible control HWNDs at both tested scales. Native tests: 45/45; Python: 175; managed gallery: 41; same-version installer distribution: 35. Source/generated/catalog consistency passes. A generator regression test now covers comment punctuation, property names, literals and named arguments.

The generator also incorrectly treated a period at the end of a comment as a property-access operator. It now ignores comments when qualifying control identifiers, preventing an unqualified thumbnail reference. Native tests ran on `native02`; final `pair03` reused those exact native binaries after verifying unchanged native sources, then received fresh host tests with the corrected generated script. The native tests were not reported as rerun for the script-only pairing.

Final script SHA-256: `b7a9cec8a66db340e86d4c1bc141f5e7048a812aab06e6c644cf2286f6debf71`. Final exact-pair host receipts use `density0862-s` and `density0862-t`, plus a cold start in `density0862-u`. Mouse-driven packaged-library loading, pattern selection, Show/Invert/Hide and wheel/drag navigation were checked in that cold-start host. The initial reproduction uses `density0862-p`; earlier correction candidates in `q/r` remain distinct evidence, including the visual finding that prompted whole-image scaling. No new pattern art, C++ placement behavior, slope/altitude changes, roadmap resumption, index activation or Git push is included.

**Artist regression:** open an empty setup's Amount panel; load a library example and switch through every layer; select and clear an image; choose Noise; reopen Amount; use Show mask/Invert/Hide; save and reload a supported image/Paint recipe; Undo/Redo. The final product pattern collection still awaits the user's artwork; only the existing three QA images were used for testing.

## Original delivery evidence — retained

The installers in the following historical table are superseded by the correction above. Their hashes and original test scope remain unchanged.

19 October 2026. **Scoped-qualified for Max 2027 and ready for artist testing.** This delivery completes D01–D11 within the scope below. The user's final artwork will arrive later: exactly three independently generated QA masks were used, two accompany the demo, and no pattern PNG enters the installer. Further roadmap work and knowledge-index activation remain paused. P06/P07 were already implemented; this delivery does not resume their remaining roadmap acceptance.

The [qualification receipt](QUALIFICATION_0862.json) pins the source, exact native/script/gallery pair, evidence and artifact hashes. This is a **local working-tree delivery**, not a new Git commit or push. The starting HEAD remains `56b6e09db2b7e53f30fd60b6e4f51ea19296075f`; pre-existing 0.86.1, Physics/Arrange and other changes were preserved. No artist profile was installed or restarted.

## Original installers and demonstration (superseded installer pair)

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| [Max 2027 MZP](../../../dist/CyrusScatter-0.86.2-20261019/CyrusScatter-0.86.2-Max2027.mzp) | 10,634,363 | `f8be2bbde8e70f35d679e546f941f7760572bd2190c0017101800a605fd28e5f` |
| [Unsigned Max 2027 EXE](../../../dist/CyrusScatter-0.86.2-20261019/CyrusScatter-0.86.2-Setup.exe) | 10,671,616 | `0c9807b6efeb8c6db3044a78f6651e7d10536320bba91399f8df715282f850ff` |
| [Editable feature demo ZIP](../../../dist/CyrusScatter-0.86.2-20261019/CyrusScatter-0.86.2-Feature-Demo.zip) | 698,232 | `d18656d87a10f08606d4c048a434dbe4905c659b696fec56b32f832c10b22dca` |

Save your scene. Use the EXE **or Scripting > Run Script** with the MZP, then **restart Max** so the matched script/native pair loads together. Do not load loose new scripts over older modules. Team offline licensing remains enabled; license issuance and activation are independently versioned. These installers contain the new **Max 2027** pair only. Earlier [0.86.1 host packages and receipts](DELIVERY_0861.md) keep their original labels and qualification.

Extract the whole demo ZIP and run **Demo/OPEN DEMO.ms** after installation/restart. Its relative opener rebinds the two included QA maps when the folder moves. The six editable layers demonstrate flat-plane channel density, Paint density/scale fading, Band density/scale curves, image-only physical mapping, mountain Curvature, normals on/off and the existing slope/altitude/include/exclude controls. Its README gives a layer-by-layer walkthrough. The demo was saved/reopened and relocated with exact full publication comparisons. `dist/` is ignored by Git; a source clone does not include these artifacts.

## Implemented scope

| Task | Delivered behavior |
| --- | --- |
| D01 | Show mask retains visibility through relevant edits, Invert and Undo/Redo. Hide stops it. Refreshes coalesce; no idle timer loop. Buttons share a row where space allows and stack in narrow panels. |
| D02 | Independently enabled Image / pattern density and Mesh-channel density. Either works alone; enabled fields multiply with existing Paint and terrain eligibility. |
| D03 | Native World XY, Scatter local XY or explicit receiver UV mapping; physical X/Y sizes, lock, rotation, offsets, Repeat/Clamp, UV repeats and independent resolution. Placement and Relax share the bilinear scalar sampler. |
| D04 | Three QA fixtures: uniform, soft-patches and wide-bands. Empty product catalog is supported and excludes QA artwork. User supplies final pattern collection later. |
| D05 | Compact thumbnail/picker, custom image loading and compatible Max texture maps. Bitmap and Noise were exercised. Explicit Bake portable snapshot writes linear 16-bit PNG with time/resolution provenance; one Undo restores the live map. |
| D06 | Continuous bounded Image, Mesh and Combined surface fields, opacity/detail and optional tiny/small/large markers. Receiver material/channels remain unchanged. Same-owner failure marks the previous field stale; a failed owner switch cannot display another layer's cache. |
| D07 | Format-6 recipes retain image bytes, mapping, saved local frame, curves and provenance alongside supported assets, paths, relationships and complete receiver-bound Paint. Different-root Load rebases the saved local frame without moving existing destination layers. |
| D08 | Required numeric channels, UVs, assets, paths and Paint compatibility are checked before staging. First Ready calculation/display preparation participates in the import transaction. Late failure rolls back staged content and retains preceding output/history. Successful Add remains one Undo/Redo without source package files. |
| D09 | All eight existing examples load/Undo/Redo on compatible terrain. Their unchanged authored designs and actual-result thumbnails are retained. Browser details derive channel/Paint requirements and distinguish settings-only, incomplete and packaged entries; full integrity is checked on Load. |
| D10 | Owned Max 2027 correctness, lifecycle, heavy Count, idle, Save/Load/reopen, demo, layout and distribution checks; exact matching MZP/EXE. |
| D11 | Name/color row followed by full-row editable layer name. Physical long-name input, Enter and Undo/Redo preserve identity and do not solve or republish placements. |

Image projection needs no receiver UVs unless **Receiver UV** is explicitly selected. A numeric channel is data stored on the evaluated mesh; it is not a material-library slot. Selecting channel 2 does not create Curvature or VertexPaint. Specialized recipes keep these requirements visible and validate them, rather than silently discarding a rule or substituting terrain.

Portable support remains the declared static mesh/Standard/PNG adapter. A compatible procedural map can remain live in the scene, but portable Save requires an explicit scalar snapshot, not a claim that its editable graph is saved. Arbitrary producer reconstruction, Paint reprojection, renderer/proxy/material graph adapters and authored Edit/effect codecs remain separate work.

## Foundation, caching and failure behavior

The layer owns authored map/response/mapping settings. Max evaluates the receiver and texture on its host thread; C++ owns copied immutable scalar pixels, sampling, placement-sized computation and overlay triangles. World/local physical coordinates are distinct from explicit UV coordinates. Inversion precedes the response curve. Repeat samples across texel centres, including negative coordinates; Clamp retains its explicit border behavior.

Relevant map/settings/time validity changes prepare a bounded sampled tile once; Count-only changes reuse it. Placement and preview share this sample. Redraw consumes cached field vertices and does not evaluate maps/meshes or rebuild placements. The overlay currently submits cached triangles through Max's immediate graphics API; it is **not** a retained GPU overlay. Unchanged Scatter instance buffers remain retained. Overlay detail is bounded at 4,096 / 32,768 / 131,072 triangles, with additional receiver, Paint, payload and query admission. High-face-count fields may refuse within these limits rather than allocate without a bound.

Manual mode separates current field visualization from the last published plants. Visible fields follow relevant edits; plant calculation waits for Update. Live mode responds to relevant dependencies. Passive browsing, unrelated animation and settled idle do not solve/rebake/reupload in the tested fixtures. No directory polling was added. External bitmap changes follow Max's Reload and notifications. Paint preview still exports a bounded serialized document into the native field; this delivery does not claim that all authored serialization is native.

Recipe format is **6**, the typed registry has **261 fields**, library capability is **4**, density-image capability is **2**, asset-package capability remains **2**, and saved scene schema remains **58**. Explicit earlier-recipe conversion retains its declared old UV/clamp defaults. Internal product identities and independent Analyzer/MCP/licensing versions remain unchanged.

## Executed evidence

| Check | Result and practical limit |
| --- | --- |
| SDK/native | Final Max 2027 SDK Release build: **45/45 tests**, including image mapping/filtering, recipe fields and shared area predicates. Final native receipt at `D:/CyrusScatterBuilds/density-recipes-0862-20261018-01/native04/receipt.json`. |
| Generated/Python | Exact generated script/layout: **319 semantic controls**; **174 MCP/tools Python tests**. Final saved outputs under `build/density-recipes-0862-20261018-01/delivery-checks/`. |
| Managed gallery | **41 checks** against the exact .NET 10 gallery, including bounded PNG decoding, dark states, scale normalization and empty/populated pattern catalogs. |
| Final host campaign | Fresh `density0862-m`, exact final pair: image/mesh/combined oracles, Manual/Live, relevant map changes, idle/unrelated animation, stale-owner isolation, large Count, selected terrain, all eight examples, complete Save/Load/Paint, package-unavailable Undo/Redo and demo reopen. Loaded module paths/hashes are retained. |
| Numeric field | Independent periodic texel-centre image oracle maximum error **0.0000012666**; numeric channels **0/2/7** and XYZ components; valid/missing UV7 positive/negative controls. A plain integer identifies missing channels. |
| Procedural snapshot | Noise scalar snapshot maximum error **0.0000152588** after linear 16-bit PNG encoding. Earlier ordinary bitmap-save encoding lost **0.146294** scalar value; that candidate is excluded. |
| Failure transaction | Actual native grid admission failure after imported asset/layer staging cancels the successor. Previous full publication and preceding Undo/Redo survive. Missing-channel, stale owner and ambiguous owner checks are separately exercised. This is not arbitrary allocator/third-party failure qualification. |
| Heavy Count | On this machine, white-mask **200,000 candidates: 446 ms; 250,000: 571 ms**. Count edits reuse sampled pixels, Undo restores exact preceding output, and settled idle counters remain unchanged. These timings are not an all-scene responsiveness or presented-FPS claim. |
| Redraw reuse | Owned `density0862-j`: **30 complete redraw requests in 245 ms**, field build/vertex counters unchanged, no Scatter republish/reupload. This physical/retained-counter witness preceded only the final thumbnail-row presentation change; its exact earlier script identity is recorded separately. |
| Real modifier | Final `density0862-m`: Data Channel Curvature edit changes numeric data at the same frame, refreshes the still-visible field, retains Manual plants, and Undo restores exact channel values. |
| Demo portability | Final six-layer scene reopens with exact full placement records and validated normal directions; moved-folder opener reproduces output and rebinds byte-identical maps. All three diagnostic marker sizes redraw without resampling or changing plants. |
| Modify layout | Final source at **100/150/200%**: 529 mounted visible HWNDs fit their page's actual outer usable width, full-width name passes. Final 150% owned-window wheel and left-hold drag work. Earlier physical long-name/Undo counters use `density0862-j`; no placement work. Physical 4K/mixed-monitor hardware transitions remain unqualified. |
| Distribution | **35 checks** on the exact EXE: extraction/hash/host guards, staging, readable controls, repair, 0.86.1 upgrade, interrupted upgrade recovery, cancel and unregister. Personal recipe/activation sentinels survive. All destinations were disposable. |

Authoritative helpers are under `tools/density_0862/`. Full host evidence is under ignored `build/mcp-qualification/density0862-{m,n,o}/`, with final 200% UI staging in `density0862-k`. Earlier failed candidates, original receipts and same-pair focused witnesses are retained, not relabeled as current tests. A standalone UI harness initially omitted its demo owner; it now binds the current demo explicitly before auditing. The final campaign's earlier layout phase is not used as the final 100/150% receipt.

Final script SHA-256: `d18694039c99e2ab61cd557ea38ad5ca4a10f54f85b5cf866bbf751dbe23c82a`. The receipt carries all native/gallery hashes, package manifest and evidence hashes. The default UI pattern catalog remains empty deliberately. Continuous field work, map baking, native publication and heavy operations are bounded and synchronous; a C++ boundary alone is not a performance promise.

## Artist test sequence

1. Install one route, restart Max 2027, extract the demo and run its opener. Inspect all six layers and their editable sources/guides.
2. In the image-only layer, change Tile X/Y, lock, rotation and Repeat/Clamp. Use Show mask, change Invert and curve, then Hide. Manual plants must wait for Update.
3. Inspect the plane's Channel 2/X ramp and mountain's Data Channel Channel 3/X. Change Curvature scale, inspect the still-visible field and Undo. Compare Image, Mesh and Combined views.
4. Change Paint inside fade/edge scale and Band density/scale curves; Update. Compare mountain normals on/off and the excluded clearing. Existing slope/altitude behavior was not modified.
5. Save a complete supported recipe with images/Paint/assets. Select compatible terrain and Load: layers should add without replacing prior planting. Test one Undo/Redo and save/reopen. A terrain lacking a required channel should reject before adding content and explain that requirement.
6. Try your real heavy scenes and preferred monitor/panel layout. Report the specific operation, Manual/Live state, display mode and Stats counters when something feels slow. Real assets, long histories, renderer combinations and physical monitor transitions remain broader artist acceptance.

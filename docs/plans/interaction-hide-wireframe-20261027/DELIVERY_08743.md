# Cyrus Scatter 0.87.4.3 — independent hiding and retained Wireframe

**Status: scoped Max 2027 patch ready for artist testing.** Use the **r3** package below. Native Interactions is **11**, scene schema **63**, authored intent **1**, and prepared-definition envelope **2**. Other products retain their independent versions. This patch version follows the user's requested 0.87.4.3 scope: two related interaction/display corrections rather than a new roadmap delivery.

## Installation and behavior

[CyrusScatter-0.87.4.3-Max2027.mzp](../../../dist/CyrusScatter-0.87.4.3-20261027-r3/CyrusScatter-0.87.4.3-Max2027.mzp) — **Scripting > Run Script**, follow the installer result, then restart Max. Script and native modules must be installed together. Artist profiles were not installed or restarted during qualification.

The reacting layer now has independent **Hide margin** and **Contact gap**. **Hide covered roots > Hide area** offers Inside solid and Under collider. Under collider explicitly clears the actual downward collider footprint; Hide margin widens it. Contact gap affects bending clearance only. Hiding removes rooted guide groups and their attachments, preserves scatter placement identities, and restores geometry when the collider moves away. Settings update contact automatically without re-preparing the source or consuming pending Manual placement edits. Earlier scenes migrate to Inside solid and copy their old gap into Hide margin to retain their previous exclusion.

Mesh and Textured mesh now honor the current viewport's Wireframe mode. The original draw path forced solid fill. A first prototype used only Nitrous's stored visual style; the Max test showed that legacy F3 could leave that style shaded. The final implementation also reads the drawing viewport's `ViewExp::IsWire()`. Wireframe uses existing untextured streams/material, avoiding texture opacity clipping. Shaded return restores the normal material path. No placement rebuild or geometry upload is required by a Wireframe toggle. Appended mesh telemetry distinguishes actual wire and solid draw calls while preserving existing counter indices.

[Artist guide](ARTIST_GUIDE_08743.md) · [ownership, migration, resources and acceptance](IMPLEMENTATION_08743.md).

## Executed evidence

Final producer: `build/interactions08743-20261027-01/native-03`; exact MZP installer profile: `installer-03`; final host: `host-03`, owned Max 2027 PID 4608. Loaded module paths, hashes and generated-script fingerprint passed startup preflight. Source/package receipts identify this exact pairing; captions alone were not used.

| Check | Observed result |
|---|---|
| Max 2027 SDK build and native suite | **61/61 pass**, including independent hide distance, footprint direction, rotated transforms, margin boundaries and old/new moved-collider index restoration; final native CTest 32.65 s |
| Generation and semantic catalog | **364 controls**; generated source/layout check passes; focused catalog test **1/1 passes** |
| Existing grass preparation | Real `Outdoor_Plants_01_Grass_Wild_QMH_001`, **451 guides**, 100% preview, **27,501 source triangles** |
| Raised sphere: Inside solid vs Under collider | **0 vs 81** hidden rooted groups; changing Hide margin to 9.050844 cm hid **451** with Contact gap still **0** |
| Source reuse and placement ownership | Guide definition unchanged; hiding did not advance placement epoch/build count; Manual requested count **201** remained published count **200** |
| Hide margin Undo/Redo | Separate Max commands restored margin **0** / **9.050844 cm**, and coverage **81** / **451** |
| Actual bending plus hiding | **6 fitted guides**, **62 hidden groups**, one posed plant; independent **23,497 visible-triangle** audit passed with zero penetrating vertex pairs, zero touching triangle pairs, zero root anchor error and maximum checked stem edge change **9.145%** |
| 200-plant fixture | **200 plants + 1 collider**, **3 nearby candidates**, 6 fitted guides and 62 hidden groups; observed native contact evaluation **4.0455 ms** for this update |
| Moving collider with 200 plants | Covered groups **437 → 0 → 437** on move away/back, with the same restored coverage |
| Mesh and Textured mesh Wireframe | Both pass automatic mode-specific checks: actual wire draw counters increase; placement epoch/build, retained revision/preparation and upload counters remain unchanged |
| F3 and visual inspection | Scattered low-poly sphere visibly switches between open triangle edges and solid faces; close grass view shows individual triangle edges, including the Textured mesh configuration |
| Mixed viewport styles | Four-view layout with one Wireframe and three shaded views: wire draws **316 → 464**, solid draws **2846 → 3258**; no geometry upload increase |
| Save/reload and previous schema | Final host opens the saved schema-62 Neottopteris fixture with schema-63 migration; the 200-plant saved copy reloads Hide margin **4.525422 cm**, Under collider and Contact gap **0**, retaining **437** hidden groups |
| Installer integrity | Actual MZP installer engine succeeded in a disposable profile; ZIP CRC, all manifest payload hashes, version and Max 2027 guards verified |

The first host preserves development failures rather than presenting them as passes. The initial wire implementation was superseded. Early Undo probes inside Python/MAXScript transaction wrappers could not prove Undo; final separate `max undo` / `max redo` events and subsequent read-only assertions pass. The fixture source-command attempt under an outer Undo-off wrapper was also rejected correctly; the final harness uses normal source command holds. Controlled opaque material/default OCIO were used for the isolated material return-path check; original asset texture portability is not certified by it.

The final plant-index review also found that an artificial upward footprint extent could dominate BVH splitting. The final r3 producer splits those reacting bounds horizontally; a native 5,000-plant test retains exactly one affected neighborhood. All final host assertions were repeated on r3.

## Exact identities

| Artifact | SHA-256 |
|---|---|
| Final r3 MZP, 2,564,935 bytes | `f8a9c526d03367cb53908dc096bbaf9e8c994989670c003b2e5e45d644563f85` |
| Final `AminScatter.dlx` | `324856664ed583ff9c6eb8b5798d09cf1071e7084c3c7ef965ce575d5997f1d8` |
| Packaged generated `CyrusScatter.ms` | `b99b50bd27b210842eaf0a5a0cad8264ff7c4e4dec74a933313b7b416389eeb8` |

Machine-readable final qualification is in `build/interactions08743-20261027-01/qualification-final.json`. Native build/test receipts, package identities, installer receipts, loaded identities, individual host assertions and the original preliminary diagnostics remain under that owned run. The preliminary archive is quarantined under that run and is not the artist delivery.

## Scope and remaining acceptance

The millisecond figure is native contact evaluation for one recorded update, not end-to-end drag latency, presented FPS, renderer throughput or a general performance guarantee. Worker/internal payload charges are not process/GPU peak measurements. The visible-mesh audit above is the existing independent double-precision check; renderer float delivery and broader render qualification remain separate.

Under collider deliberately hides below floating objects too. Use Inside solid for overhead canopies/bridges, or a trunk/custom collider for trees. Fixed roots that intersect bending clearance outside the chosen hidden area still reject the successor and retain the previous complete result; this patch does not detach roots or silently enlarge hiding. Root hiding remains per rooted guide group, not a mesh Boolean/remesher. Existing bounded geometry, query, guide and collider admissions remain. No new solver limits were silently removed.

Edged Faces overlays, other Max hosts, arbitrary welded plants, negative/nonuniform instance scaling, renderer qualification and another 20-model performance campaign are not claimed by this patch. Current artist navigation and capability/catalog documentation are updated. Website publication, knowledge-index refresh and Git commit/push were not part of this request; the previously stale knowledge generation was not used as current evidence.

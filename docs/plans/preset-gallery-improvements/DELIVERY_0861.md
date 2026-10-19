# Scatter 0.86.1 â€” selected-terrain library and host compatibility

18 October 2026. Scoped delivery ready for user testing. The user selected **0.86.1** and limited implementation to workflow, UI and compatibility. The requested pre-change code/docs backup was pushed as `56b6e09db2b7e53f30fd60b6e4f51ea19296075f` before implementation. The new release implementation is in the local working tree; that pre-change checkpoint is not a commit of 0.86.1. Further roadmap work remains paused. The deferred knowledge-index activation was not resumed.

## Artist workflow

1. Select one terrain mesh. Run **Cyrus Library** from the **Cyrus** action category (assign it through Customize), or open **Layers > Recipes** from an existing setup.
2. Choose a collection/preset and **Load onto surface**, double-click or press Enter. Browsing creates no scene objects. The browser retains the captured terrain if selection changes later.
3. Loading imports the supported models/materials and adds new layers. It creates a setup when the terrain has none. An existing unambiguous setup retains its layers, identities, order and Manual/Live mode. If several setups use the terrain, open Recipes from the intended setup.
4. Load explicitly updates once, including pending Manual changes. One Undo removes the added preset and restores the preceding publication; Redo restores exact owners/assets/results without the package files.
5. To save your own planting, use **Save Recipe** on a valid setup, select layers and keep **Include models, materials, terrain and paths** enabled. Complete Paint and optional captured PNG thumbnails remain included. A settings-only recipe must be saved with its assets before direct loading.

The selected terrain is authoritative. Missing numeric channels or incompatible Paint are explained **before mutation**; the loader does not substitute its saved terrain or disable planting rules. Paint still requires compatible evaluated geometry, frame and saved units. Static spline paths transfer through the saved terrain frame, retaining authored dimensions rather than stretching to the new mesh. Direct loading admits one saved terrain per recipe; broader terrain mappings/reprojection remain separate work. Grids retain explicit world-space origins.

The normal browser's binding-heavy load/review route is retired. Typed internal binding/reuse contracts remain for qualified engineering workflows. Existing static mesh, Standard/Blinn and supported PNG adapters remain the boundary; renderer shaders/proxies, animation and authored Edit/radius adapters were not added.

## What changed

- Rootless library entry, captured-surface ownership and a per-open browser session token; completing an older load cannot rebind a reopened browser. Scene creation occurs in the existing authored import transaction, after package/channel/Paint checks. New-setup rollback and preceding publication/history are preserved.
- Explicit dark toolbar/menu hover, pressed, popup, arrow and disabled text states, with system high-contrast colors. Save/Style/export depend on a valid setup; file browsing/details do not.
- Matching gallery builds for Max 2024 (.NET Framework 4.8), Max 2026 (.NET 8) and Max 2027 (.NET 10). Bounded image decoding, worker/cache ownership and page limits are retained. Framework-specific API replacements preserve hash/size/PNG checks.
- Matching SDK native builds and host-specific registration/guards. The universal unsigned net48 EXE embeds three exact MZPs and selects one host/profile per installation. Example scene copies are saved to the matching older format; original source scene bytes are preserved.
- Recipes/package manifests retain actual authoring-host provenance instead of always writing 2027. Format 5 and scene schema 58 remain. Readers admit supported data documents from 2024, 2026 and 2027; this does not make newer `.max` scenes readable by older Max.
- Standard material validation now compares aliases against the material the closed adapter restores. Runtime inspection found Max 2026 exposing `Diffuse_Color` and `Specular_Level` alongside canonical values. Canonical colors/specular settings now save correctly; unsupported shaders still reject.

Placement algorithms, synchronous calculation boundaries, candidate/capacity admission and existing native ownership contracts remain as documented in the [0.86.0 foundation](../native-placement/DELIVERY_0860.md). The Modify scrolling/flow source hashes match the pre-change baseline. This is not a repeat of the full historical heavy-count/render/one-hour soak campaign.

## Qualification

[Machine-readable identities and scope](QUALIFICATION_0861.json) pin script/native/gallery/package hashes, final owned profiles, counters and campaign durations. Exact final source script SHA-256: `8ea60d06a06dd93c82a2abd8561dd3c48740094e1c7266dee0779e936c9fca42`.

| Check | Result and limit |
| --- | --- |
| SDK/native | Matching 2024/2026/2027 SDK builds; 44 native tests pass in each. MSVC 14.38.33130, Windows SDK 10.0.19041.0; C++20 core. SDK compilation is not host acceptance. |
| Max 2027 | Fresh `library-surface0861-max2027-05`; all four final campaigns pass with verified loaded native paths, script fingerprint and gallery path/version. |
| Max 2026 | Fresh `library-surface0861-max2026-05`; same final campaigns pass, including saved 2026 scene copies and custom Save. This delivery has explicit user authorization overriding the default 2027-only test rule. |
| Max 2024 | **Preview only.** SDK/native tests and actual CLR/net48 gallery checks pass. The local 2024 folder has no runnable `3dsmax.exe`; no Max 2024 scene, Painter, notification or render qualification is claimed. The installer labels it preview. |
| Workflow/history | New setup, captured-selection change, repeated additive load, prior layer order/identity, preserved Manual mode, new-setup Undo/Redo, exact publication restore and save/reopen. |
| Eight examples | All eight ready presets load onto compatible selected terrain in both hosts. Complete Paint and existing layers survive Undo. Redo restores exact publication with the package directory temporarily unavailable. |
| Custom preset | Actual Capture viewport and Save button callbacks, async package completion, captured PNG, actual authoring host, exact digest linkage, reload to selected terrain and complete Paint bytes pass in both hosts. |
| Failure/ownership | Missing channel rejected before mutation; ambiguous destinations require explicit owner; cancellation/deleted target create no setup/assets. Injected late authored failure after setup/first-layer creation rolls back nodes, retains prior publication and leaves no stranded Undo hold. Unsupported shader rejection remains. |
| Passive work | Actual Library macro passes. Settled open-library observations show zero group solves/epochs, receiver/preparation/preview rebuilds, retained prepares/node updates/uploads/bytes, and bulk script materialization changes in both final hosts. These are scoped counters, not a presented-FPS or all-scene guarantee. |
| Gallery/UI | Interactive owned Max 2026 hover and open-menu inspection; [30 actual net48 control/layout/PNG-worker checks](MANAGED_0861.txt), including default scale 0, 100% and scripted 150%. Physical 4K mixed-monitor transitions remain separate acceptance. |
| Installer | [56 exact-EXE checks](DISTRIBUTION_0861.txt): three resources, preview label/host selection, scripted 100/150% bounds, extraction/inventory identity, native/library staging, host registration, repair, wrong profile/hash rejection, cancellation rollback, unregister and personal-content sentinels. Transactions ran only in disposable paths; no artist installation. |
| Offline | Generated source/layout checks and 171 MCP/tools Python tests pass. Product code remains outside the public MCP write surface. |

Reproduction helpers are in `tools/library_0861/`. Final native receipts, framework references, fixture logs and CLI-rendered bounds images are under ignored `build/library-surface-0861-20261018-01/`; final host evidence is under `build/mcp-qualification/library-surface0861-max{2026,2027}-05/`. Pass-line totals are recorded as such, not unique assertions.

Earlier candidates are excluded: one 2027 startup exited before readiness; 2026 compilation exposed the unsupported argumented rethrow syntax, corrected before final runs; a missing forward declaration and material aliases were corrected. A source-folder-only reload lacked its adjacent gallery DLL and failed the macro test; the final clean-start paired profiles pass. Browser reopening exposed reused MAXScript rollout identity; the per-open token correction passes both captured-terrain operations in each final host. Earlier fixture failures (shader enum, recipe-count assumption and identity-script syntax) remain in ignored logs. Their failures are not counted as passes.

## Installers and artist acceptance

The [distribution folder](../../../dist/CyrusScatter-0.86.1-20261018) contains:

| Artifact | SHA-256 |
| --- | --- |
| [Universal EXE](../../../dist/CyrusScatter-0.86.1-20261018/CyrusScatter-0.86.1-Setup.exe) | `21db3fd49a89105dfccb3ce0c86cf3f2086c3b0e472a6c215351dae113207cf0` |
| [Max 2027 MZP](../../../dist/CyrusScatter-0.86.1-20261018/CyrusScatter-0.86.1-Max2027.mzp) | `8182ac67179cc1fd82d8d4ca3fe09e71f9108e1c33e9b8bad07a4d2ab495a56a` |
| [Max 2026 MZP](../../../dist/CyrusScatter-0.86.1-20261018/CyrusScatter-0.86.1-Max2026.mzp) | `d6810e4c891d5d6e4db5063274660669da0e5bc08b3ee7ba07bb1592c6e892d8` |
| [Max 2024 preview MZP](../../../dist/CyrusScatter-0.86.1-20261018/CyrusScatter-0.86.1-Max2024.mzp) | `41a8fb1ef4251bbc8c1b99962c7e9a81e87ee6a7c48626ad61bbe692c38c9e5e` |

Use **Scripting > Run Script** with the MZP matching the host, then restart that Max version. Alternatively use the universal EXE's host selector. Team licensing remains enabled with the existing generated activation-key workflow; the executable does not grant authoring access. No private issuer key is packaged. Installation and restart remain the user's actions.

Artist checks: select a new plane/terrain and load meadow; load another preset and confirm preceding layers remain; Undo/Redo; save your own supported setup with Paint/thumbnail and reload; try a channel-driven preset on terrain carrying the required channel; inspect hover/menu text and Modify navigation at your actual monitor scaling. A teammate must qualify the preview in a real Max 2024 installation before treating that host as runtime supported. No Max 2025 or earlier-than-2024 support is implied.

## Primary references

Local source and runtime receipts establish Cyrus behavior. Autodesk documents [Standard material shader enums and aliases](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Material-MAXWrapper/Material-Types/GUID-57F5EBBA-5F54-4CD4-8993-0B07A3571293.html), [saved-file version selection](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/File-Access/3ds-Max-Scene-Files-Access/GUID-624D3D05-B15D-4A97-9F15-DA35CDB0DDD2.html), and [Max 2024 SDK requirements](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/what_s_new/whats_new_3dsmax_2024_sdk.html). The older SDK's recommended compiler/runtime requirements and the local MSVC toolchain do not replace the missing 2024 host qualification.

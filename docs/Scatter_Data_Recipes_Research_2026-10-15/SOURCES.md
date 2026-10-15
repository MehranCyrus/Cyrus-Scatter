# Source register and evidence limits

Accessed **15 October 2026**. Links below are primary Autodesk, iToo, Chaos and Microsoft sources. Dates in this table are page-stated dates or the documentation edition, not crawler dates. The report cites supporting pages beside competitor claims.

## Official iToo sources

| Source | Version/date | Supports |
| --- | --- | --- |
| [Forest 9.4.3 release](https://docs.itoosoft.com/changelog/2026/09/08/forestpack-9_4_3) | 8 Sep 2026 | Release identity; does not qualify our local installation. |
| [Forest 9.4.0 release](https://docs.itoosoft.com/changelog/2026/04/01/forestpack-9_4_0) | 1 Apr 2026 | Added Max 2027 / Arnold 7.5 support. |
| [Lite and Pro](https://docs.itoosoft.com/forestpack/lite-and-pro) | Current reference; no visible revision date | Editions differ. Table icons were not fully represented by text extraction; avoid inferring every edition cell from empty columns. |
| [Requirements](https://docs.itoosoft.com/forestpack/requirements) | Current reference; no visible revision date | Renderer/feature and library compatibility must be checked per use. |
| [Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces) | Current reference; no visible revision date | XY/UV modes, normal/slope/altitude controls and shared terrain preparation with Auto/refresh. |
| [Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) | Current reference; no visible revision date | Paint requires XY; spline conversion, order, falloff, material IDs and model selection. |
| [General](https://docs.itoosoft.com/forestpack/forest-plugin/general) | Current reference; no visible revision date | Numeric presets, external references preserved, `.fpe` and INI workflow. |
| [Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry) | Current reference; no visible revision date | Scene model picker and material ownership. |
| [Library Browser](https://docs.itoosoft.com/forestpack/forest-library/library-browser) | Current reference; no visible revision date | Asset-bearing presets, Merge/XRef, navigation, thumbnails/search and read-only system libraries. |
| [Editing a library](https://docs.itoosoft.com/forestpack/forest-library/editing-a-library) | Current reference; no visible revision date | Pro-only user editing, paths, collection and nested-object limitations. |
| [Animation](https://docs.itoosoft.com/forestpack/forest-plugin/animation) | Current reference; no visible revision date | Source animation sampling controls. |
| [Effects attributes](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes) | Current reference; no visible revision date | Exposed surface/PFlow attributes; not a complete SDK or internal data model. |
| [Multiple Forest objects in one library preset](https://forum.itoosoft.com/forest-pro-%28%2A%29/can-you-add-a-few-forest-packs-as-a-single-preset-in-the-library/) | Vendor reply, Michal Karmazín, **2 Jul 2025**; user follow-up 12 Dec 2025 | Vendor stated Library Manager required separate Forest objects/presets, including Layered Lawns. Dated limitation, not proof that every subsequent release is unchanged. Reopened during this review revision. |

## Official Chaos sources

| Source | Page-stated update date | Supports |
| --- | --- | --- |
| [Scatter overview, Max](https://support.chaos.com/hc/en-us/articles/4953289514513-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max) | 14 Nov 2025 | Feature overview and Corona 12 brush milestone. |
| [Getting started, Max](https://support.chaos.com/hc/en-us/articles/4953372632209-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Getting-Started) | 27 May 2026 | Target/model workflow, replacement and Cosmos preset import. |
| [Advanced features, Max](https://support.chaos.com/hc/en-us/articles/4953359913617-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Advanced-Features) | 31 Dec 2025 | Surface modes, paint-layer assignments, source animation controls. |
| [Using with other features, Max](https://support.chaos.com/hc/en-us/articles/4953423307025-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Using-with-Other-Features) | 14 Nov 2025 | Density texture/Distance Map integration. |
| [Cosmos assets, Corona Max](https://support.chaos.com/hc/en-us/articles/4953819541265-How-to-Use-Chaos-Cosmos-Assets-in-Corona-for-3ds-Max) | 14 Nov 2025 | Asset library, preset discovery and shared download paths. |
| [FAQ, Max](https://support.chaos.com/hc/en-us/articles/4953317171985-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-FAQ) | 14 Nov 2025 | Corona bundling/licensing context. |
| [Main technical reference](https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter) | Earlier research recorded Aug 2026; not reverified here | Current web extraction returned zero lines; direct fetch returned HTTP 403. Its automatic-update/temporal-consistency statements are retained only as historical evidence from the prior report. |
| [Configuration save/load vendor reply](https://forums.chaos.com/t/request-scatter-library-similar-to-forestpacks-library-browser/155909) | Chaos representative maru, **15 May 2023** | Confirms configuration save/load via MAXScript separately from Cosmos preset import. Does not establish exact serialization contents, asset completeness or a multi-Scatter recipe graph. Reopened during this revision. |
| [Official MAXScript reference](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124394405/MAXScript) | Current official reference; no page revision inferred | Chaos Scatter API section exposes `update` and a `saveConfiguration` entry. The extracted table ends at that entry; exact configuration signatures/content were not verified from this extraction. Vendor reply supports the general save/load claim. |

Cinema 4D and Envision pages appeared during discovery but are not used to establish 3ds Max behavior. **Correction from the review revision:** Chaos configuration save/load is documented. What remains unverified here is an arbitrary multi-Scatter, asset-complete recipe exporter and its Paint/dependency semantics. Do not conflate configuration I/O, Cosmos downloads, a library browser and a multi-owner package.

## Official Autodesk and Microsoft sources

| Source | Edition/date | Supports |
| --- | --- | --- |
| [INode](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_node.html) | Max 2027 C++ | Evaluated pipeline, object transforms, validity context. |
| [Interface](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_interface.html) | Max 2027 C++ | Save Selected and Merge host operations. |
| [Mesh](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_mesh.html) | Max 2027 C++ | Geometry and mapping data interfaces. |
| [MeshNormalSpec](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_mesh_normal_spec.html) | Max 2027 C++ | Corner/explicit normals and inverse-transpose transform. |
| [Object](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_object.html) | Max 2027 C++ | Channel validity and procedural-object aggregate validity caveat. |
| [ChannelData](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_channel_data.html) | Max 2027 C++ | Data Channel engines and data semantics. |
| [Data Channel operators](https://help.autodesk.com/cloudhelp/2025/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Modifier-MAXWrapper-and/Modifier-and-SpacewarpModifier/Modifiers/Parametric-Modifiers/Data_Channel-Modifier/GUID-F55E55FE-A78F-431D-9B47-2670DAABEAB6.html) | Max 2025 MAXScript | Curvature, Velocity and typed output controls. No claim that its prose specifies the internal estimator or velocity units. |
| [Data Channel Interface](https://help.autodesk.com/cloudhelp/2025/ENU/3DSMax-Modifiers/files/GUID-C8A1211F-8C4B-4D91-B8E5-73A9AAAC8C44.htm) | Max 2025 user help | Numeric data versus visual display colors/normalization. |
| [Render-session threading](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/rendering/new_rendering_api/render_session.html) | Max 2026 developer guide | General SDK thread-safety warning. Reading this reference is not Max 2026 development/testing. |
| [Windows known folders](https://learn.microsoft.com/en-us/windows/win32/shell/knownfolderid) | Microsoft current reference | Documents, LocalAppData, RoamingAppData and redirected-path handling. |

Equivalent attempted 2027 Data Channel user/MAXScript help URLs were unavailable through the research tool. The 2027 C++ documentation was accessible. Local 0.82.4 host evidence independently covers the named 2027 Curvature/Vertex Output cases, not every older help-page feature.

## Repository evidence and applicability

| Evidence | Status / use |
| --- | --- |
| [Engineering foundation](../ENGINEERING_FOUNDATION.md) | F01–F11 contracts read with limits. These prescribe behavior; they are not blanket acceptance. |
| [Current mesh-mask handoff](../plans/eleven-phase-roadmap/MESH_MASK_0824.md) | Exact source/package/host identities, selected channel behavior, timings and open gates. Historical test execution, reread now. |
| [P02 handoff](../plans/eleven-phase-roadmap/P02.md) | Category preset format, transaction/storage and scoped 2027 measurements. Original build labels preserved. |
| [Architecture](../ARCHITECTURE.md) | Existing owners, caches and binding limits. Header predates 0.82.4; current source/handoff inspected for newer behavior. |
| [Backlog](../BACKLOG.md) | Physical/long-session/extreme geometry and UI acceptance remain separate. |
| [P10 plan](../plans/eleven-phase-roadmap/IMPLEMENTATION.md#p10--planting-recipes-and-browser-0829) | Proposed multi-layer recipe work, not an implemented capability or resumed phase. |
| [Vendor surface/paint](../Vendor_Surface_Paint_Research_2026-10-09/README.md) | Owned 9 Oct Max 2027 experiments, exact counts and excluded stale captures. Old Cyrus 0.74 comparisons are not current behavior. |
| [Vendor native inspection](../Vendor_Native_Deep_Research_2026-10-09/README.md) | Selected assembly/decompilation witnesses; no recovered vendor project. |
| [Earlier rebuild blueprint](../How_Forest_Works/Cyrus_Scatter_Rebuild_Blueprint%20GPT%206/00_READ_ME_FIRST.md) | Inspected as a proposal, not proof of existing source or permission for a wholesale rewrite. |
| [Knowledge status](KNOWLEDGE_STATUS.json), [failed F02 retrieval](KNOWLEDGE_SEARCH.json) | Stale generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`; 16/38 parents verified. No refresh. Direct source inspection used. |
| [Source evidence](SOURCE_EVIDENCE.json) | Current inspected file hashes and initial dirty scope. Later verification records whether those files changed during this study. |
| [Revised contract](PRESET_CONTRACT.md), [field map](FIELD_MAP.md), [parameter inventory](PARAMETER_INVENTORY.csv), [implementation plan](IMPLEMENTATION_PLAN.md) | User-selected Save Everything/Paint requirement and proposed implementation. Source declaration accounting is not runtime acceptance. |
| [Revision checks](REVISION_CHECKS.json) | Documentation-only revision checks and source-preservation evidence. The original `DOCUMENT_CHECKS.json` and source/knowledge receipts remain historical records of the initial study. |

No new host behavior, competitor timing, cache hit, license entitlement, original proprietary algorithm or production recipe importer is claimed by this report. Historical binary offsets/raw decompilation remain in their separate research artifacts; the proposed schema and architecture are independently authored.

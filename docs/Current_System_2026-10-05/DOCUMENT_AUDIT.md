# Document authority and maintenance

5 October 2026. The repository contains many dated design, implementation and test packages. They are useful evidence, but several use “current” for different snapshots. This pass reconciles navigation and present claims; it does not rewrite past measurements or claim every line in every archived report was freshly reverified.

## Authority by question

| Question | Authority | How older material is used |
| --- | --- | --- |
| What is the current local product and what is next? | [This package](README.md), [current state](CURRENT_STATE.md), [roadmap](ROADMAP.md) | Dated reports supply evidence for their exact build |
| What should a control calculate? | [Option contracts](../Procedural_Evaluation_2026-10-04/11_OPTION_CONTRACTS.md), current source, later reproduced corrections | Historical 1.x guides explain preserved legacy policies; not automatic policy-3 support |
| Where are controls in 0.7.1? | [UI workflow](../UI_0.7.1_2026-10-05/WORKFLOW.md), current generator/inventory | Native-column/classic screenshots are historical layouts |
| What can an MCP client actually call? | Current `server.py`, validators, settings registry, host guards, and [coverage matrix](CAPABILITY_MATRIX.md) | MCP roadmap names are proposals; a Markdown tool list is not registration |
| How should logging be built? | [Diagnostics specification](DIAGNOSTICS_SPEC.md) | Existing performance/trace guides describe reusable tools and their limits |
| Which vendor contracts change the next implementation gates? | [Vendor recheck](VENDOR_RECHECK.md), reflected in [roadmap](ROADMAP.md) | Specialist Houdini/Autodesk supplements provide deeper context; vendor availability is not Cyrus support |
| How should policy-3 MCP expand? | [Expansion contract](MCP_EXPANSION_SPEC.md), gated by [roadmap](ROADMAP.md) | AI research provides deeper design alternatives and experiments |
| What is implemented in ML? | Current source and [current state](CURRENT_STATE.md) | All style/learning packages remain research/proposals; examples are synthetic |
| What governs licensing? | [Licensing index](../licensing/README.md), operation contract, decisions and recorded foundation tests | September/provider proposals and lab examples do not enable ordinary enforcement |
| Which build was tested? | Exact source/native identity plus the original run receipt | Version strings, plans and screenshots alone are insufficient |

If a requirement and implementation differ, record a gap; do not silently weaken the requirement or describe the proposal as completed. The user's current instructions take precedence over roadmap assumptions. Historical reports retain their authorship/date/provenance.

## Corrections made in this pass

- Update root/current navigation from the 0.7.0 checkpoint to local 0.7.1, retaining source/package/serialization distinctions.
- Connect the real-scene success evidence to the later IR failure and asset warnings; do not present production-render success as IR validation.
- Mark old “current,” “start here,” UI-layout and Brush-integration statements as historical at their entry points.
- Preserve native versus MCP capability distinctions and specify that policy-3 configuration export is not complete published-layout export.
- Identify performance logs, the 128-operation MCP journal, reproduction artifacts and future artist datasets as separate records.
- Link the new AI-design research as specialist proposal material; coordinate its phases through this roadmap without asserting that its models/tools exist.
- Retain licensing source/policies and test evidence unchanged; expose their dependencies in the cross-cutting roadmap.
- Correct the MCP export-size prose to the implemented 1,500,000-byte limit.

## Inventory and coverage method

The source snapshot records tracked and non-ignored untracked files, initial Git status, source hashes and documentation package counts. The generated control inventory accounts for every control entry in `layers-control-inventory.json`; it is a coverage checklist, not proof every event permutation was tested.

The package register below classifies documentation families. Current-path documents and relevant source/receipts were read for this task. Archived families were inventoried and routed to their newer authority rather than being described as individually requalified. Licensing and unrelated artist data were preserved.

| Documentation family | Markdown files at starting snapshot | Classification | Current routing |
| --- | ---: | --- | --- |
| [(top-level)](../README.md) | 21 | Navigation, versioning and manual diagnostics guides; selected current links updated | [Guide](CURRENT_STATE.md) |
| [AI_Design_Learning_Research_2026-10-05](../AI_Design_Learning_Research_2026-10-05/README.md) | 14 | Research and proposed AI/ML work; no implemented learning | [Guide](MCP_EXPANSION_SPEC.md) |
| [AI_MCP_ML_Roadmap_2026-09-30](../AI_MCP_ML_Roadmap_2026-09-30/README.md) | 19 | Research and proposed AI/ML work; no implemented learning | [Guide](MCP_EXPANSION_SPEC.md) |
| [Artist_Style_ML_2026-10-04](../Artist_Style_ML_2026-10-04/README.md) | 7 | Research and proposed AI/ML work; no implemented learning | [Guide](MCP_EXPANSION_SPEC.md) |
| [Artist_Zones_Integration_2026-10-03](../Artist_Zones_Integration_2026-10-03/README.md) | 4 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Brush_Relax_Reset_2026-10-03](../Brush_Relax_Reset_2026-10-03/REPORT.md) | 1 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Brush_Tool_2026-10-02](../Brush_Tool_2026-10-02/README.md) | 6 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Classic_Layout_2026-10-04](../Classic_Layout_2026-10-04/README.md) | 4 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Codebase_Research_2026-10-01](../Codebase_Research_2026-10-01/REPORT.md) | 2 | Historical/source or supplied research; preserve provenance | [Guide](EVIDENCE.md) |
| [CyrusScatter_Complete_Codebase_Documentation_2026-09-27](../CyrusScatter_Complete_Codebase_Documentation_2026-09-27/README.md) | 28 | Historical source reference; not current complete coverage | [Guide](SYSTEM_GUIDE.md) |
| [CyrusScatter_Licensing_Implementation_Package_2026-09-27](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md) | 35 | Historical licensing research; active authority is docs/licensing | [Guide](ROADMAP.md) |
| [Cyrus_Scatter_V1_2026-10-03](../Cyrus_Scatter_V1_2026-10-03/README.md) | 5 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Heavy_Scene_Viewport_2026-10-02](../Heavy_Scene_Viewport_2026-10-02/README.md) | 7 | Historical measurements and proposed performance work | [Guide](DIAGNOSTICS_SPEC.md) |
| [Independent_Review_0.7_2026-10-05](../Independent_Review_0.7_2026-10-05/README.md) | 7 | Earlier same-day checkpoint/source-container/licensing evidence | [Guide](CURRENT_STATE.md) |
| [Layer_Width_2026-10-04](../Layer_Width_2026-10-04/README.md) | 1 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Layers_First_2026-10-03](../Layers_First_2026-10-03/REPORT.md) | 5 | Historical native/shared-policy and bounded MCP qualification | [Guide](CAPABILITY_MATRIX.md) |
| [Licensing_Architecture_2026-10-02](../Licensing_Architecture_2026-10-02/SOURCES.md) | 1 | Historical licensing research; active authority is docs/licensing | [Guide](ROADMAP.md) |
| [MCP_Implementation_2026-10-03](../MCP_Implementation_2026-10-03/REPORT.md) | 5 | Historical native/shared-policy and bounded MCP qualification | [Guide](CAPABILITY_MATRIX.md) |
| [Performance_Roadmap_2026-09-28](../Performance_Roadmap_2026-09-28/README.md) | 14 | Historical measurements and proposed performance work | [Guide](DIAGNOSTICS_SPEC.md) |
| [Planting_Groups_2026-10-03](../Planting_Groups_2026-10-03/REPORT.md) | 2 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Procedural_Evaluation_2026-10-04](../Procedural_Evaluation_2026-10-04/README.md) | 13 | Detailed requirements; check implementation subset and later corrections | [Guide](SYSTEM_GUIDE.md) |
| [Procedural_Implementation_0.7_2026-10-04](../Procedural_Implementation_0.7_2026-10-04/README.md) | 6 | Earlier procedural implementation and frozen runtime/package evidence | [Guide](CURRENT_STATE.md) |
| [Product_Commercialization_Playbook_2026-09-30](../Product_Commercialization_Playbook_2026-09-30/README.md) | 21 | Historical strategy; current sequencing consolidated | [Guide](ROADMAP.md) |
| [Product_Strategy_2026-09-29](../Product_Strategy_2026-09-29/README.md) | 19 | Historical strategy; current sequencing consolidated | [Guide](ROADMAP.md) |
| [Real_Scene_0.7.1_2026-10-05](../Real_Scene_0.7.1_2026-10-05/README.md) | 4 | Current real-asset evidence and later IR finding | [Guide](CURRENT_STATE.md) |
| [Research_Briefs_2026-10-01](../Research_Briefs_2026-10-01/README.md) | 1 | Historical/source or supplied research; preserve provenance | [Guide](EVIDENCE.md) |
| [Research_Inputs_2026-10-01](../Research_Inputs_2026-10-01/README.md) | 7 | Historical/source or supplied research; preserve provenance | [Guide](EVIDENCE.md) |
| [Retained_Mesh_Preview_2026-10-02](../Retained_Mesh_Preview_2026-10-02/README.md) | 4 | Measured display preservation baseline | [Guide](CURRENT_STATE.md) |
| [Retained_Point_Preview_2026-10-02](../Retained_Point_Preview_2026-10-02/README.md) | 3 | Measured display preservation baseline | [Guide](CURRENT_STATE.md) |
| [Review_Handoff_2026-10-05](../Review_Handoff_2026-10-05/README.md) | 5 | Historical unfinished-UI/pre-review snapshot | [Guide](CURRENT_STATE.md) |
| [System_Map_2026-10-04](../System_Map_2026-10-04/README.md) | 2 | Historical interactive map; data/UI not changed in this documentation task | [Guide](SYSTEM_GUIDE.md) |
| [UI_0.7.1_2026-10-05](../UI_0.7.1_2026-10-05/README.md) | 3 | Current floating-editor workflow and frozen UI qualification | [Guide](SYSTEM_GUIDE.md) |
| [UI_Architecture_Investigation_2026-10-02](../UI_Architecture_Investigation_2026-10-02/README.md) | 4 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Viewport_Performance_2026-10-01](../Viewport_Performance_2026-10-01) | 1 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Viewport_Performance_Implementation_2026-10-01](../Viewport_Performance_Implementation_2026-10-01) | 1 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [Viewport_Performance_Round2_2026-10-01](../Viewport_Performance_Round2_2026-10-01) | 1 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [handoffs](../handoffs) | 1 | Historical implementation/investigation/evidence; retain dated scope | [Guide](CURRENT_STATE.md) |
| [licensing](../licensing/README.md) | 13 | Active specialist licensing policy and default-off foundation; preserved | [Guide](ROADMAP.md) |

Starting inventory: **297 Markdown files across 38 document families** (including top-level guides). New reconciliation files are additional. Counts include archived evidence/recipe Markdown; they are not counts of freshly audited reports.

## Keep this consistent after each implementation loop

1. Update the current-state row and finding status; say which exact test moved it from proposed/unverified to supported.
2. Update feature metadata, native/MCP coverage and UI help together. Regenerate the control inventory when controls change.
3. Record source/native/host/renderer identities, input fixtures, failed and passing receipts, and measurement scope.
4. Update the owning roadmap item and affected entry points. Never change an old failure receipt to a pass or replace the source snapshot of a historical report.
5. Check local links, explicit fragment anchors, tables, example syntax and references. Verify docs-only tasks did not alter production files.
6. Label proposals and synthetic examples visibly; runtime schemas/resources become authoritative only when implemented and qualified.

No new documentation should become a competing “master” roadmap. Extend the current authority or explicitly record that a newer dated package supersedes it. The interactive system map is a historical visualization until its data/UI are updated in a separate authorized code task.

## Same-day vendor follow-up

The original inventory above remains a dated count. The specialist AI research subsequently added engineering supplements and experiments; the [follow-up](VENDOR_RECHECK.md) independently rechecked selected primary contracts and integrated its requirements here. Keep research phases P0–P7 mapped to product tasks D01–A03 rather than copying either queue into another master plan. This pass also records simultaneous implementation changes separately, so a documentation-only result cannot claim the whole shared checkout was frozen.

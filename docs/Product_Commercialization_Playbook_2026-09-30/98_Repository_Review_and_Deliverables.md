# Repository review, provenance and exact deliverables

**Reviewed 2026-09-30.** The attached 885-line task was read before work. Source/artifact review preceded writing this package. No Git or subagents were used.

## What was inspected

| Area | Inspected inputs | Finding and evidence label |
|---|---|---|
| Structure | Filesystem inventory of product, tools, CMake, docs and local artifacts | Two product projects, generator, shared build tools; VERIFIED IN SOURCE |
| Scatter core | [API](../../AminScatter/include/scatter.h), [engine](../../AminScatter/src/scatter.cpp), spacing/final/edge/orientation/falloff includes | Seeded placement, weights, masks, spacing and ordered rules; VERIFIED IN SOURCE |
| Host bridge | [max_bridge.cpp](../../AminScatter/src/max_bridge.cpp), bridge includes | Mesh evaluation, world transforms and MAXScript marshaling; VERIFIED IN SOURCE |
| UI/controller | [generated script](../../AminScatter/scripts/AminScatterObject.ms), [generator](../../AminScatter/tools/ui/generate.cjs), stage/template inputs | Ten layer factories, actual UI captions and generation path; VERIFIED IN SOURCE |
| CS Edit | [native modifier](../../AminScatter/src/cyrus_edit.cpp), [stack](../../AminScatter/src/cyrus_edit_stack.inc), [storage](../../AminScatter/src/cyrus_edit_storage.inc) | Saved identities/deltas and mutation callbacks; arbitrary base changes are not durable attachments |
| Analyzer | [engine](../../CyrusSurfaceAnalyzer/src/analyzer.cpp), [elements](../../CyrusSurfaceAnalyzer/src/elements.cpp), [bridge](../../CyrusSurfaceAnalyzer/src/bridge.cpp), [script](../../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms) | Open planar connected elements, paths/points/Street Side; source support does not prove all real input behavior |
| Preview | [preview.cpp](../../AminScatter/src/preview.cpp), [geometry preview](../../AminScatter/src/geometry_preview.inc) | Bounded cached point/geometry data drawn through GraphicsWindow |
| Rendering | [PFlow template](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/pflow.ms) | Transient render transport and Corona-specific handling; manual renderer qualification missing |
| Packaging | [builder](../../tools/build_max.py), [shared SDK configuration](../../cmake/CyrusMaxSDK.cmake), both CMake files/installers and actual MZPs | 2026/2027 configuration; delivered 2027 package hashes verified |
| Tests | Six Scatter test sources, Analyzer tests, [Max smoke script](../../tools/tests/max2027_smoke.ms), [batch runner](../../tools/test_max2027.py), retained JSON/log evidence | Native tests use active check/throw assertions; old smoke is narrow |
| Licensing | Feature activation stage, mutation/evaluation primitives and existing licensing specifications | No implemented licensing authority/provider found in the inspected product paths |
| Demos | Product/tools/dist scene search plus top-level build scenes | Only build/max2027-smoke.max found in these locations; no qualified customer demo kit |
| Documentation | Current strategy, install guide and relevant historical architecture/performance/licensing references | Strategy governs; historical validation claims need evidence reconciliation |

This was a subsystem review with targeted source tracing and filename/content searches. It was not a line-by-line certification of every generated factory or a formal security audit. No Max UI, actual render or new native build/test run was performed for this playbook.

## Retained and freshly checked evidence

- The 100 product files present in the earlier strategy inventory still match their raw hashes.
- The new initial [input snapshot](evidence/input_snapshot.json) covers 101 product/root inputs and 124 existing docs-folder files, including an additional ZIP archive.
- Both delivered MZPs passed fresh ZIP/payload-manifest checks, and their packaged scripts match current source.
- All seven retained native test executables match the 2026-09-29 evidence hashes. Earlier PASS results remain dated 2026-09-29, not new test results.
- Generator repeatability remains [the 2026-09-29 observed result](../Product_Strategy_2026-09-29/evidence/generator_check.json), with matching production source.
- Prior Max smoke results are preserved in [the strategy archive](../Product_Strategy_2026-09-29/evidence/prior_runtime_evidence.json).
- The extra **docs/Cyrus Scatter Documents.zip** has 123 file entries and passes ZIP integrity. It is an archive, not a newer governing decision. It was preserved.
- [Review observations](evidence/repository_checks.json) and [final validation](evidence/final_validation.json) record provenance and checks.

## Concrete source anchors

Line numbers describe the inspected snapshot; filenames/functions remain the preferred references after changes.

| Anchor | Source location | What it supports |
|---|---|---|
| S1 | scatter.cpp: Random/Sampler/scatter; include/scatter.h | Seeded sampling, UV masks, weighted sources, placement/rule interfaces |
| S2 | max_bridge.cpp:73–94, 107 onward, 275–307 | World/local mesh capture, UV channel 1, two placement entries, source sampling |
| S3 | AminScatterObject.ms:118–1040, 9488 onward | Actual captions, display budgets, source choices, layer manager, spacing |
| S4 | AminScatterObject.ms:11059–11169 | Count/density conversion, 128×128 map raster, branch risk and preview clearing |
| S5 | AminScatterObject.ms:11110–11148 | Overlap/final/orientation/edit ordering and render exclusion of point placeholders |
| S6 | AminScatterObject.ms:11321–11349; generate.cjs previewUI transformation | Baking code remains, while the generated creation button is removed |
| S7 | cyrus_edit.cpp:38–60, 85–113; cyrus_edit_stack.inc:7 onward | Modifier name/Instances mode, mutations, status, conditional identity |
| S8 | cyrus_edit_storage.inc:15 onward | Current/legacy chunks, per-field limits and incremental publication |
| S9 | CyrusSurfaceAnalyzer.ms:201–220, 262–321 | Partial analysis publication, exact controls and export commands |
| S10 | templates/pflow.ms: CyrusPFBuild/CyrusPFClear/CyrusPFTick | Render object ownership, restoration, Corona timer/IR behavior |
| S11 | build_max.py: package/main; cmake/CyrusMaxSDK.cmake | Host targets, staged versions, integrity manifests and compiler setup |
| S12 | tools/tests/max2027_smoke.ms | Exactly what earlier host smoke asserts |

## Conflicts and practical corrections

| Statement encountered | Current treatment |
|---|---|
| Analyzer README says no Scatter integration | Current layer controller consumes Analyzer data; integration exists in source |
| Source installers require 2026 | Delivered MZPs contain builder-staged 2027 substitutions; use MZPs |
| Analyzer native description says 0.5 / UI note says v0.4 | Package says 0.14; version metadata needs consolidation before commercial release |
| CS Edit guide reports broad past integration passes | DOCUMENTED BUT NOT VERIFIED for this exact 2027 package; retained smoke only covers empty-stack evaluation/persistence |
| Baking is available in earlier UI descriptions | Code exists; a Bake creation control is absent from the current generated preview rollout |
| General uninstall implied | Scatter has an installed Uninstall.ms; no dedicated Analyzer uninstaller exists in its current MZP |
| Older provider rankings/terms imply a choice | No vendor or terms are approved by this playbook |
| Older performance checklist says build prerequisites absent | Later delivered build and retained evidence supersede that environment description |

The previous strategy's C-01..C-10 findings remain source-backed observations/hypotheses; Stage 04 translates them into action. Serious risks were documented without product fixes.

## External research used in this playbook

Checked 2026-09-30:

- [Chaos Scatter advanced Max/Corona guidance](https://support.chaos.com/hc/en-us/articles/4953359913617-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Advanced-Features): vendor documents constraints, instance editing, brush/cluster workflows and edge trimming.
- [ForestPack official page](https://www.itoosoft.com/forestpack): vendor presents scattering, library/preset, display and scene-management workflows. Performance/market leadership wording is marketing, not independent proof.
- [tyFlow official documentation](https://docs.tyflow.com/): operator-based workflows include placement and instance-related entries; task parity with Cyrus was not tested.

These are competitor facts, not Cyrus compatibility evidence or purchasing recommendations. Prices and license terms were not used as current guarantees. Autodesk/Chaos host/renderer context remains the dated [strategy source register](../Product_Strategy_2026-09-29/15_Research_Sources.md); refresh required facts before any release claim. Provider/payment/legal facts need later dedicated verification.

## Exact files created

The package contains **21 Markdown files and three JSON evidence records**:

1. README.md
2. 00_Master_Checklist.md
3. 01_Understand_the_Current_Product.md
4. 02_Manual_Product_Walkthrough.md
5. 03_Product_Feature_Inventory.md
6. 04_Problems_and_Missing_Pieces.md
7. 05_Define_the_Product.md
8. 06_Competitor_and_Positioning_Review.md
9. 07_Product_Support_Matrix.md
10. 08_Demo_and_Benchmark_Scenes.md
11. 09_Commercial_and_Licensing_Decisions.md
12. 10_Licensing_Technical_Preparation.md
13. 11_Licensing_Provider_Evaluation.md
14. 12_Beta_Readiness.md
15. 13_Presentation_Asset_Production.md
16. 14_Landing_Page_Content_Plan.md
17. 15_Pricing_and_Offer_Preparation.md
18. 16_Commercial_Launch_Readiness.md
19. Landing_Page_Claims_Matrix.md
20. 98_Repository_Review_and_Deliverables.md
21. 99_Progress_Log.md
22. evidence/input_snapshot.json
23. evidence/repository_checks.json
24. evidence/final_validation.json

**Existing file updated:** docs/README.md adds navigation to the operational playbook. Historical packages, their manifests, the ZIP archive and all snapshotted product/root inputs were preserved. Final validation checks local links/anchors, sequential stages, required stage sections and file integrity; external source retrieval status is recorded above.


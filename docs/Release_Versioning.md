# Cyrus Scatter release versioning

**6 October current development label: 0.73, explicitly requested by the user.** Native/package metadata is **0.73.0**, MAXScript serialization **54**, calculation model **`CyrusUnified1`**, and MCP package/closed plan **0.73.0 / 0.73**. The [unified campaign](Unified_System_0.73_2026-10-06/README.md) retires unpublished old policies/scene formats/schemas, ports useful features and adds source-container nodes. Internal names/class IDs remain registration identities, not old-scene compatibility promises. Stable-only Edit storage uses a new chunk and rejects old development storage. Analyzer stays **0.14**; 1.0 remains reserved for publication readiness.

**Previous 0.72 checkpoint:** package metadata 0.72.0 and serialization 53 belong to the [integrated selected-layer campaign](Integrated_UI_0.72_2026-10-06/README.md). Use that pair's receipts for its actual renderer/UI evidence, not the version caption alone.

**Historical 5 October source/package distinction:** Development source was **0.7.1**, introducing the compact Modify panel and [floating Layer Editor](UI_0.7.1_2026-10-05/WORKFLOW.md). Installers at that checkpoint remained 0.7.0. The subsequent 6 October runtime campaign packaged its separately qualified 0.7.1 pair. The preceding sidebar/source-container checkpoint is preserved at `addccb4`; its evidence remains in the [independent review results](Independent_Review_0.7_2026-10-05/IMPLEMENTATION_RESULTS.md).

**Historical decision recorded: 4 October 2026.** The development label was reset to **0.7** (`0.7.0` for that candidate). Reserve **1.0.0** for publication readiness; see the [current system and roadmap](Current_System_2026-10-05/README.md).

## Current checkpoint and historical labels

The development history progressed from the retained-Mesh **0.64** baseline through builds labeled **1.0.x**, **1.1.x** and **1.2.x**. Those labels identify existing development artifacts and evidence; they do not establish that a production 1.0 release was approved.

The procedural candidate packages report **0.7.0**, applied in the [procedural coding phase](Procedural_Implementation_0.7_2026-10-04/README.md). No candidate was installed during that phase. The later floating-editor development source advances to **0.7.1** while retaining those features and performance paths.

Historical commit messages, report titles, filenames, package checksums and captured screenshots retain their original labels so evidence remains traceable. Current planning should describe **Cyrus Scatter 0.73 development** and distinguish it from the installed build and from the procedural policy's historical 0.7 label.

## Historical 0.7.0 implementation checklist

- [x] Apply final UI version 0.7.0 in [procedural-policy.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/procedural-policy.cjs), after the retained layout stages, and regenerate [AminScatterObject.ms](../AminScatter/scripts/AminScatterObject.ms).
- [x] Align current product captions and candidate documentation to 0.7.
- [x] Build packages using [build_max.py](../tools/build_max.py), which checks the generated script's version; verify installer names/manifests agree.
- [x] Align [AminScatter/CMakeLists.txt](../AminScatter/CMakeLists.txt) product version to `0.7.0`. Keep product, serialized scene and MCP versions distinct.
- [ ] Test installation/update behavior from existing 0.64 and 1.x development packages. Any version comparator must handle this intentional labeling transition; a larger-looking historic label is not the authority for the selected product roadmap.
- [x] Preserve plugin/class IDs; advance MAXScript serialization to 52 for additional procedural parameters. Old policy values remain unchanged until explicit conversion.
- [x] Preserve independent MCP protocol/plan/package versions and Analyzer versions.
- [x] Record the checkpoint, working-tree source hashes, SDK builds, package hashes and runtime limitations in [0.7 evidence](Procedural_Implementation_0.7_2026-10-04/evidence.json). The [Max 2027 campaign](Procedural_Implementation_0.7_2026-10-04/RUNTIME_REPORT.md) is complete within its stated scope. Max 2026 host and installer-transition qualification remain required before cross-version distribution.

Patch builds can use `0.7.1`, `0.7.2`, and so on. Later pre-release milestones can use `0.8.x` or `0.9.x` when appropriate. Do not infer publication readiness from completing an individual feature or checkpoint; move to 1.0 only when release readiness is confirmed.

Current next work is coordinated by the [0.73 acceptance gates](Unified_System_0.73_2026-10-06/ROADMAP.md), with the broader [system roadmap](Current_System_2026-10-05/ROADMAP.md) covering MCP, reporting, ML and release tracks. The [procedural guide](Procedural_Evaluation_2026-10-04/README.md) remains the detailed calculation requirements reference. The [documentation index](README.md) links current capabilities and historical qualification records.

# Cyrus Scatter release versioning

**5 October source/package distinction:** Both current source and earlier installers report 0.7.0, but their contents differ. The sidebar corrections and opt-in source containers now have isolated Max 2027 evidence in the [independent review and implementation results](Independent_Review_0.7_2026-10-05/IMPLEMENTATION_RESULTS.md). They remain unpackaged. Current serialization is **53**; the earlier procedural candidate was 52. Identify builds by verified source/native hashes, not the version label alone.

**Decision recorded: 4 October 2026.** Cyrus Scatter is still in pre-release development. The next product version is **0.7** (`0.7.0` in build/package metadata). Reserve **1.0.0** for the version ready for public publication.

## Current checkpoint and historical labels

The development history progressed from the retained-Mesh **0.64** baseline through builds labeled **1.0.x**, **1.1.x** and **1.2.x**. Those labels identify existing development artifacts and evidence; they do not establish that a production 1.0 release was approved.

The generated script and current candidate packages now report **0.7.0**, applied in the [procedural coding phase](Procedural_Implementation_0.7_2026-10-04/README.md). No candidate was installed during that phase. This keeps the latest features and performance paths; the label change is not a rollback to old 0.64 source.

Historical commit messages, report titles, filenames, package checksums and captured screenshots retain their original labels so evidence remains traceable. New planning should describe the product as **Cyrus Scatter 0.7 pre-release** and distinguish that intended version from the currently installed build label.

## Next implementation checklist

- [x] Apply final UI version 0.7.0 in [procedural-policy.cjs](../AminScatter/tools/ui/procedural-policy.cjs), after the retained layout stages, and regenerate [AminScatterObject.ms](../AminScatter/scripts/AminScatterObject.ms).
- [x] Align current product captions and candidate documentation to 0.7.
- [x] Build packages using [build_max.py](../tools/build_max.py), which checks the generated script's version; verify installer names/manifests agree.
- [x] Align [AminScatter/CMakeLists.txt](../AminScatter/CMakeLists.txt) product version to `0.7.0`. Keep product, serialized scene and MCP versions distinct.
- [ ] Test installation/update behavior from existing 0.64 and 1.x development packages. Any version comparator must handle this intentional labeling transition; a larger-looking historic label is not the authority for the selected product roadmap.
- [x] Preserve plugin/class IDs; advance MAXScript serialization to 52 for additional procedural parameters. Old policy values remain unchanged until explicit conversion.
- [x] Preserve independent MCP protocol/plan/package versions and Analyzer versions.
- [x] Record the checkpoint, working-tree source hashes, SDK builds, package hashes and runtime limitations in [0.7 evidence](Procedural_Implementation_0.7_2026-10-04/evidence.json). The [Max 2027 campaign](Procedural_Implementation_0.7_2026-10-04/RUNTIME_REPORT.md) is complete within its stated scope. Max 2026 host and installer-transition qualification remain required before cross-version distribution.

Patch builds can use `0.7.1`, `0.7.2`, and so on. Later pre-release milestones can use `0.8.x` or `0.9.x` when appropriate. Do not infer publication readiness from completing an individual feature or checkpoint; move to 1.0 only when release readiness is confirmed.

Current next-engine work is defined in the [procedural implementation guide](Procedural_Evaluation_2026-10-04/README.md). The [documentation index](README.md) links the current capabilities and historical qualification records.

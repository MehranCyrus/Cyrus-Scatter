# Cyrus Scatter release versioning

**Decision recorded: 4 October 2026.** Cyrus Scatter is still in pre-release development. The next product version is **0.7** (`0.7.0` in build/package metadata). Reserve **1.0.0** for the version ready for public publication.

## Current checkpoint and historical labels

The development history progressed from the retained-Mesh **0.64** baseline through builds labeled **1.0.x**, **1.1.x** and **1.2.x**. Those labels identify existing development artifacts and evidence; they do not establish that a production 1.0 release was approved.

The generated script currently reports **1.2.3**. This checkpoint records the user's versioning decision without rebuilding or reinstalling the plugin. Align the active product label to **0.7.0** in the next implementation/build. Keep the latest features and performance improvements; this numbering decision is not a rollback to the old 0.64 source.

Historical commit messages, report titles, filenames, package checksums and captured screenshots retain their original labels so evidence remains traceable. New planning should describe the product as **Cyrus Scatter 0.7 pre-release** and distinguish that intended version from the currently installed build label.

## Next implementation checklist

- [ ] Update the authoritative UI version in [layers-first.cjs](../AminScatter/tools/ui/layers-first.cjs), then regenerate [AminScatterObject.ms](../AminScatter/scripts/AminScatterObject.ms).
- [ ] Verify product captions and current artist/developer entry points consistently explain the 0.7 version.
- [ ] Build packages with [build_max.py](../tools/build_max.py), which reads and checks the generated script's three-part version. Verify installer names, manifests and displayed labels agree.
- [ ] Test installation/update behavior from existing 0.64 and 1.x development packages. Any version comparator must handle this intentional labeling transition; a larger-looking historic label is not the authority for the selected product roadmap.
- [ ] Keep serialized plugin/class identities and scene/schema versions intact unless a separate data migration requires a change.
- [ ] Preserve independent MCP protocol/plan versions, MCP package versions and Analyzer versions. They are not automatically renumbered with the Scatter product label.
- [ ] Record the tested source commit, binary hashes, supported host versions and remaining limitations before distributing the next build.

Patch builds can use `0.7.1`, `0.7.2`, and so on. Later pre-release milestones can use `0.8.x` or `0.9.x` when appropriate. Do not infer publication readiness from completing an individual feature or checkpoint; move to 1.0 only when release readiness is confirmed.

Current next-engine work is defined in the [procedural implementation guide](Procedural_Evaluation_2026-10-04/README.md). The [documentation index](README.md) links the current capabilities and historical qualification records.

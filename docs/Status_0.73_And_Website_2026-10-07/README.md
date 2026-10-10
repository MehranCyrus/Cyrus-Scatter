# Cyrus Scatter 0.73 — verified starting point

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

7 October 2026. **The compact 0.73 implementation is a useful development baseline for the next phase. It is not a publication-readiness certificate.** This round reconciles source and documentation, reruns offline checks, and develops the combined local website. It makes no production plugin, scene, installer or licensing changes.

## Start here

- [Current visual website](../../website/index.html): product introduction, artist guide, interactive explanations and development status.
- [Final website verification](../../website/verification/COMBINED_BROWSER_REVIEW.md): independent design PASS, browser observations and desktop/mobile screenshots.
- [Fresh-conversation handoff](https://github.com/MehranCyrus/Cyrus-Scatter/blob/f5bc9737378d097cd469d20b32d5576cf10dab01/docs/Status_0.73_And_Website_2026-10-07/HANDOFF.md): exact baseline, delivery mismatch, protected files and the recommended next task.
- [Prioritized roadmap](ROADMAP.md): the next engineering loops and their acceptance criteria.
- [Code review](CODE_REVIEW.md) and [documentation reconciliation](DOCS_RECONCILIATION.md): source locations, findings and evidence boundaries.
- [Artist-facing status copy](WEBSITE_STATUS.md): the website's factual starting point.
- [Fresh checks and identities](evidence/offline-results.json): new offline results, with [source/package identity](evidence/baseline-identity.json).

## What has been achieved

The product now has one unified procedural model, explicit ordered layers/paint sets, independent spacing scopes, editable Brush coverage, stable source/Edit identities within their documented correspondence, source-container organization, and atomic publication of accepted results. The compact workflow places everyday controls in ten main sections and less-used fields in Advanced. The latest source corrects the Add/Copy callback lifetime problem.

Retained Point Cloud and Mesh previews reuse unchanged data. Manual/Live scheduling, local diagnostics and cached statistics are implemented. Recorded Max 2027 tests include a real garden, large-scene preview work and Corona rendering on their exact historical builds. Those measurements are not fresh results for every later script.

MCP has twelve tools, seven resources and a limited, locally approved Plan 0.73 authoring workflow. Its catalog can explain more controls than it can change. A small offline preference ranker exists, but there is no established artist-trained/reference-image production system. Licensing remains an independent, default-off foundation with commercial work unfinished.

The artist reference contains 16 documents and 240 contextual inventory entries. This means documented coverage, not 240 separately qualified buttons or every possible interaction.

## Exact baseline and installed-copy warning

| Item | Verified value |
| --- | --- |
| Branch / committed source | `codex/unified-0.73` / `d55dfa88cbeda7af366e4510ac3119a749368958` |
| Product / serialization / model | `0.73.0` / `54` / `CyrusUnified1` |
| Current source script | SHA-256 `9614f6b7d95c0e7c97f9bbe7fa2cb5a770f7a3eca813f7a9f55ea68463d114bf` |
| Latest corrected delivery | `dist/Layer_Actions_Fix_0.73_2026-10-07/Max2027/CyrusScatter-0.73.0-Max2027.mzp` |
| Corrected MZP | SHA-256 `92d1f93600c89e02133d90a9a4f6072db1daae2f0e7a0c110aa60f3de28ba9a7` |
| Inspected normal-profile script on disk | SHA-256 `53bf85f9a2cfe1034468919c408d4c73ca6e865f7e1b9c816cc7375fe12f10fa` — earlier compact build |

The installed script on disk therefore lacks the later layer-action correction even though both show 0.73. This is a read-only file observation, not proof of what an already-running Max process has loaded. Verify the dated package, installed bytes and loaded script/native pair before the next host test. No normal-profile installation occurred here.

All eight pinned sources and 33 retained evidence entries in the latest correction's index matched their recorded hashes. The corrected package and its bundled script also matched. Native payload hashes are preserved in the identity receipt.

## Fresh checks in this round

| Check | Observed result | Boundary |
| --- | --- | --- |
| Python MCP/tools tests | 141 passed | Offline service/schema/report/package behavior, not Max end-to-end |
| Fresh Scatter core build and CTest | 14 suites passed | Current C++ core source; no SDK plugin or host UI qualification |
| Fresh Analyzer core build and CTest | 1 suite passed | Current geometry core; no host interaction qualification |
| Generator/source integration | 240 controls, 22 fixture delimiter checks passed | MAXScript was not compiled in Max |
| Approved-layout assertions | Passed | Structural namespace, mapping and lifetime checks |
| Package/evidence identities | Matched as described above | File provenance, not a runtime pass |

Commands and full results are in [the evidence folder](evidence/). The native build receipts identify their source inputs and explicitly record no host launch or installation. Website browser verification is separate under `website/verification/` and must identify the final combined revision rather than silently reuse the earlier guide's result.

## What remains open

1. **Recorded release gate:** the first cold pointer-driven container Undo restored positions but lost the preceding Undo/Redo history. Its cause remains unisolated; passing later scripted/repeated cases does not resolve it.
2. **New source-level qualification target:** the global Undo refresh can admit pending Manual edits after an unrelated scene Undo. This has a concrete source path but was not reproduced in Max in this round. It is separate from the history-loss finding.
3. **Known resource limits:** large Proxy drawing repeats triangle submission; Brush derived dabs/patch links lack an aggregate memory-admission budget. Projection and exceptional radii retain their R&D gates.
4. **Qualification breadth:** all controls and combinations, DPI/font/docking variants, long sessions, Max 2026 runtime and additional renderers remain open. Seven material maps were missing in the earlier private scene copy.
5. **Future product scope:** broader MCP authoring, a useful causal debug archive, consented artist-learning experiments and commercial licensing each require their own acceptance loop.

## Documentation changes and preserved evidence

Current navigation is corrected in the root README, docs index, Current System README/guide and MCP README. It now points to the compact artist guide and latest callback fix, uses the current section names, and separates the historical 0.7.1/0.72 material. The source review and roadmap identify the small offline ranker accurately.

Original artist-reference Markdown and historical receipts remain unchanged. The capability matrix's stale navigation is documented rather than edited because its hash is pinned in the production MCP catalog; updating that catalog belongs in a separately verified source change. No old FPS or renderer measurements were rewritten as new results.

The website and review are local work. No commit, push, package, installation or public deployment is included. The existing reference designs and original artist scene remain preserved. Git backup does not include ignored scenes, binaries and installers; retain those separately if making a full-machine backup.

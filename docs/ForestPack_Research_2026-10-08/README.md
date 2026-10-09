# Forest Pack research — 8 October 2026

We can learn substantial architecture and several concrete algorithms from the installed Forest Pack Lite. The existing Ghidra tools are working; another installation was unnecessary. This investigation establishes useful parts of the native display, collision, parameter ownership and sample-cache systems. It does **not** recover the complete scatter engine or establish feature parity with Forest Pro.

Research stays in the CyrusScatter repository. No production plugin implementation, installed vendor file, artist profile or scene was changed. This is a research receipt, not release or performance qualification.

## Read the results

- [Focused Forest brush investigation: contour editing, Max Painter, Undo and Cyrus comparison](brush/README.md)

- [How the native system works, with evidence addresses](NATIVE_FINDINGS.md)
- [What the screenshot's controls imply about the model](CONTROL_MODEL.md)
- [What Cyrus already has and what would be useful to investigate next](CYRUS_LESSONS.md)
- [Tool choices, reproduction and continuation](HANDOFF.md)
- [Machine-readable identity, preservation and verification receipt](EVIDENCE.json)

## Strongest findings

| Question | What this investigation establishes |
|---|---|
| Is it a large MAXScript? | The principal engine is native x64 C++. Readable startup MAXScript mostly provides macros, helpers and dependency selection. It does not contain the distribution engine. |
| How does its viewport avoid repeating work? | A marker render item prepares buffers behind a ready flag, then draws through a separate instancing path. SDK compile probes independently identify `Realize`, `Display` and `DrawInstanced`. |
| How are collisions accelerated? | XY and UV placement paths call a common collision filter. A two-dimensional spatial grid narrows candidates; the narrow test compares squared three-dimensional distance with squared combined sphere radii. Rejected records are marked and removed. |
| How are animation samples managed? | Native sample-cache classes, a configured memory limit and a render-frame cleanup path are present. Eviction priority remains unresolved. |
| How are many settings organized? | Sources, receivers, masks, distribution inputs, transforms, camera, animation and display are separate domains. A native rollout callback retrieves its parameter block and owning Forest object before handling controls. |
| Is every grey control a Lite limitation? | No. The screenshot selects Particle Flow, which disables incompatible area controls. Lite restrictions and current-mode restrictions need separate interpretation. |

The public documentation independently describes a point-cloud budget and update behavior, but those descriptions do not substitute for a host measurement or proof of every invalidation path. See [iToo's Display documentation](https://docs.itoosoft.com/forestpack/forest-plugin/display).

## Exact scope and identity

Target: **Forest Pack Lite 9.4.3**, native file version **9,4,3,766**, Max **2027** package at `C:\ProgramData\Autodesk\ApplicationPlugins\ForestPackLite2027`. Main module SHA-256:

```text
23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d
```

Four installed native modules were inventoried; only the core `.dlo` underwent this Ghidra analysis. The screenshot supplied by the user is visual evidence; it contains expanded controls, collapsed sections and empty lists, and does not enumerate every Forest feature.

Ghidra discovered **8,664 analysis-defined functions**. We selected **33 records** for bounded inspection: **32 decompiled successfully**, with decoded byte coverage matching their analysis-defined bodies; **one cache comparator address had no discovered function**. Some inspected records were destructors, setup functions or import thunks. These counts are neither 32 recovered algorithms nor a percentage of the product understood. Four independent Max SDK class-layout probes compiled successfully; they were not linked or executed. An initial missing-header compile attempt is retained in the private run alongside the corrected pass.

Cyrus source baseline: branch `codex/unified-0.73`, HEAD `d55dfa88cbeda7af366e4510ac3119a749368958`. Eight inspected source files and eight captured installed inputs/copies retained their original hashes. Existing unrelated workspace changes were preserved. All vendor binary copies, pseudocode, assembly and full documentation snapshots remain in ignored `build/forestpack-research-20261008-01/`; this report contains findings and metadata.

The research database was saved, its project closed and only the verified research backend stopped. No Max scene execution, renderer test, FPS comparison or Pro-specific native investigation was performed. Chaos Scatter was previously located but is not a target of this Forest pass.

# Second-pass review: Houdini and Autodesk

**5 October 2026. Documentation and planning update; no production implementation.**

The original recommendation remains appropriate: preserve Cyrus's procedural engine, qualify reproducible execution, expose its actual capabilities through MCP, collect artist comparisons, and evaluate a small preference model before more elaborate learning. The vendor documentation strengthens that direction and reveals several contracts that the first roadmap did not specify tightly enough.

## What was checked

- Recompared the original 488 source/tool fingerprints with the current checkout; inspected the scatter record, Brush binding, procedural model, retained point publication and generated PFlow callback paths.
- Revisited the current research plans, evidence boundaries and the separately added current-system/diagnostics documents.
- Searched and read selected official SideFX procedural, TOP/PDG and ML documentation, and Autodesk Max callback, notification, validity, threading, rendering, Undo and Batch documentation.
- Cross-checked relevant notification contracts with the local Max 2027 SDK headers located through the existing CMake cache. Recorded header/configuration hashes, without redistributing SDK text.
- Extended the documentation consistency check and reran it after these changes. Its exact counts and source-preservation result are in [package_validation.json](evidence/package_validation.json).

This is a targeted second pass over the AI/MCP plan and its host prerequisites. It is not exhaustive certification of every Cyrus feature, all Autodesk/Houdini documentation or all past test reports. No Max or Houdini session was launched, no artist scene was used, and no trained model was evaluated. The **66-test MCP result belongs to the earlier pass**; unchanged production sources did not justify calling it a new host/runtime result.

## Findings and plan changes

| Priority | Finding | Evidence and implication | Smallest plan change |
| --- | --- | --- | --- |
| High | Render-phase and notification rules need explicit qualification | Autodesk distinguishes pre-render setup from frame callbacks that cannot modify rendered geometry. Current Cyrus uses the former. The IR cause is still unproven. | P0 trace phase, initiating operation, publication and bridge mutations; preserve correct notifications; add E17 lifecycle tests |
| High | Identity claims need operation-specific limits | Current code has candidate/source/anchor foundations. Point order, persistent asset identity, candidate keys and published instances have different lifetimes. | P1 identity-survival matrix plus E15; no correspondence inferred from compacted indices or reused names |
| High | Scheduler completion and cached files do not prove a valid candidate | PDG documents explicit limitations/options around dirty files, failure handling and partitioning. Those are useful counterexamples to trusting workflow status. | P1/P2 semantic completion predicate, required-view join and E16 corrupt/stale artifact tests |
| High | UI-driven and noninteractive workers cannot share an untested capability claim | Autodesk documents the Node Event System's Windows-message-loop dependency. | P2 explicit host mode; qualify Batch separately from an isolated interactive worker; test explicit evaluation without timers |
| Medium | “ML” combines three different objectives | Taste labels, measured technical outcomes and inverse recipe proposals have different supervision and success criteria. | Keep artist ranker first; collect technical metrics alongside execution; make surrogate/inverse models conditional experiments |
| Medium | Model file/version alone is insufficient for replay | Feature units/order, image preparation and tensor/provider behaviour can change a score while the model bytes remain unchanged. | P4/P5 versioned feature contract and E18 parity/unsupported-input checks |
| Medium | Source diversity is not positional composition | `clusterEnabled` is explicitly diversity-only in the current header. | Capability docs must distinguish source assignment from actual spatial clumps/ribbons; recipe compiler rejects unsupported controls |
| Medium | Diagnostic lifecycle can invalidate a seemingly clean comparison | Callback function registration can retain an older function instance; observer work can add events. | P0 ownership, teardown/reload checks, observer overhead measurement and tested 2026/2027 diagnostic paths |

These are strengthened requirements and evidence gaps. They are not eight newly reproduced runtime bugs. The first two engineering supplements identify source facts separately from SDK facts and proposed behaviour.

## What remains sound

Stable procedural records, explicit layer order, independent spacing scopes, bounded replacement, exact publication identity and retained display are valuable foundations. A companion process remains the right initial home for datasets, review, inference and training. A small typed state machine is enough for the first generation/review loop; neither a Houdini runtime, graph database, general node editor nor RL training is justified by this research alone.

Artist A/B comparisons remain useful, provided ties, neither, skips, rejection reasons, personal/studio context and explicit acceptance remain distinct. Technical render failures must be excluded from aesthetic labels. The grouped holdout, human audit stream and comparison against recipe/retrieval baselines remain necessary.

## Updated implementation order

1. **P0 — Host stability:** matching loaded script/DLL identities, causal IR diagnostics, callback/lifecycle evidence and retained-display regression checks. Correct the demonstrated cause in a separate coding loop.
2. **P1 — Reproducible evidence:** exact policy-3 publications, identity-survival and transform fixtures, immutable artifact receipts and complete required-view sets.
3. **P2 — Supported automation:** procedural MCP parity, explicit bounded batch scope, supported host mode, failure recovery and cancellation. No unqualified timer-dependent Batch support.
4. **P3/P4 — Useful artist workflow:** meaningful recipe variation, passive gallery browsing, explicit scratch/application actions, structured review and grouped benchmark.
5. **P5/P6 — Measured learning:** small preference ranker, versioned feature preparation, then reference-guided search. Add technical surrogates or inverse initializers only against measured baselines.

The [roadmap](10_ROADMAP.md) now incorporates these gates directly. The [experiment register](11_EXPERIMENTS.md) contains **18 planned experiments**, including four additions for identity/transforms, artifact integrity, host lifecycle/mode and feature/inference parity. None of those additions was executed as a runtime test in this pass.

## New and amended documentation

| Document | Role |
| --- | --- |
| [Houdini engineering lessons](14_HOUDINI_ENGINEERING_LESSONS.md) | Stage contracts, identity matrix, surface/transform semantics, PDG lessons and three learning objectives |
| [Autodesk host contracts](15_AUTODESK_HOST_CONTRACTS.md) | Callback phase, validity, notification, ownership, threading, Undo and worker-mode obligations |
| [Vendor source ledger](17_VENDOR_SOURCE_LEDGER.md) | 25 selected official documentation entries with version, reading depth and limitations; one revisits an original source |
| [Updated roadmap](10_ROADMAP.md) and [experiments](11_EXPERIMENTS.md) | Integrated tasks and acceptance criteria |
| [Learning](05_SEARCH_AND_LEARNING.md), [MCP](06_MCP_ROADMAP.md), [architecture](07_ARCHITECTURE_AND_GRAPHS.md), [data](08_DATA_AND_EVALUATION.md), [diagnostics](09_DIAGNOSTICS_AND_PERFORMANCE.md) | Corresponding contract refinements |

The original 40-entry paper/engineering ledger is retained. The vendor ledger is an additional, separately identified reading list rather than a claim of 25 new ML papers. All research is bounded by **5 October 2026**; later-2026 developments have not been invented or assumed.

## Evidence and unresolved work

The [second-pass starting snapshot](evidence/second_pass_before.json) preserves the prior document hashes and Git scope. [The first-pass validation receipt](evidence/package_validation_first_pass.json) remains available alongside the refreshed receipt. The [SDK receipt](evidence/vendor_sdk_crosscheck.json) identifies the local files inspected; no DLL build or loaded-process identity is inferred from it.

The shared docs index also acquired current-system navigation and historical-status corrections outside this research pass. They were preserved. A [separate index baseline](evidence/docs_index_second_pass_before.json) checks our one-paragraph amendment without reverting those updates. The research roadmap now includes an explicit crosswalk to the current product work queue.

Runtime work remains open: the IR restart cause, the full renderer/host matrix, the new batch contract, publication/export completeness, preference collection and ML evaluation. The revised plan makes these obligations more precise; it does not mark them finished. No production source, installer, normal Max profile, scene, licensing implementation, commit or push was changed by this pass. The separate `Current_System_2026-10-05` folder was preserved.

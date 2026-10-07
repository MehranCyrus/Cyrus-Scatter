# Stage 10 — Licensing technical preparation

**Updated 2026-10-02.** Follow the current [architecture](../licensing/ARCHITECTURE.md) and [L0/L1 roadmap](../licensing/ROADMAP.md). The former vendor-adapter sequence and generated-script line numbers are superseded.

## Goal

Prepare and then test a native authorization boundary that preserves agreed scene behavior. The current host bridges, CS Edit mutations, Analyzer entry and script bake helper exist; a production licensing authority has not been demonstrated.

## Source anchors for the first experiment

| Source | What to trace |
| --- | --- |
| [max_bridge.cpp](../../AminScatter/src/max_bridge.cpp): `aminScatterAdvanced_cf`, `aminScatterTransforms_cf`, related exposed helpers | New input, direct calls and saved-state computation |
| [cyrus_edit.cpp](../../AminScatter/src/cyrus_edit.cpp): native mutations and script primitives | Move/rotate/scale/clone/delete/reset, Undo/Redo and restore |
| [Analyzer bridge](../../CyrusSurfaceAnalyzer/src/bridge.cpp): `cyrusAnalyzeSurface_cf` | New analysis versus evaluation dependencies |
| [Controller template](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/before.ms): `bakeInstances` and parameter handlers | Authoring, bake/export and scene-owned state; a separate script check is insufficient authority |
| [UI generator](../../AminScatter/tools/ui/generate.cjs) and its inputs | Generated licensing/recovery UI; avoid hand-editing generated output |
| [Preview](../../AminScatter/src/preview.cpp) and display paths | Preserve prepared-data drawing; no license I/O, verification or checkout in callbacks |

The follow-up [codebase integration audit](../licensing/CODEBASE_AUDIT.md) expands these starting points into ten findings with file fingerprints and a native declaration inventory. It identifies separate enable/authorization state, admission before preview/PFlow cleanup, shared CS Edit mutation paths, evaluation bookkeeping, and runtime/package preparation. Reconcile it against the coding snapshot, including concurrent feature changes; it is not a complete call graph or runtime proof. Do not build around old generated line numbers.

## Immediate work

1. Convert the static map into the L0 caller/operation contract and changed-parameter versus saved-evaluation reproduction; exercise denial before cache/scene mutation and preserve existing output and edits.
2. Record worker/bake limitations and any required policy or native-state change.
3. Define independent facts, immutable snapshot, release identity, structured authorization decisions and bounded operation lifetime.
4. Build L1 with fake backend/clock fixtures and a maintained verifier; keep test trust out of production.
5. Prove same-product feature extension without changing service or signed schema.
6. Continue to the owned service and isolated Max candidate only when the relevant exit gates pass.

Use [decisions](../licensing/DECISIONS.md) for policy rather than duplicating its worksheet. Fake test policies can explore unresolved choices; customer enforcement needs the applicable decisions fixed.

## Evidence and completion

Record exact source/build, host/renderer, policy configuration, expected/actual outcomes, raw evidence and limitations. SDK compilation or unrelated performance tests cannot be marked as licensing tests.

Preparation is complete when L0 has a credible contract and L1 has a concrete implementation packet. Runtime qualification remains NOT TESTED until the experiments run. No service, native gate, purchase or rollout was implemented by the documentation cleanup.

Next: [Stage 11 — Owned licensing service validation](11_Licensing_Provider_Evaluation.md).

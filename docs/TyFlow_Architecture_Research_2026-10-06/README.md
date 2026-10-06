# tyFlow architecture research and Cyrus Scatter comparison

6 October 2026. Completed bounded static investigation of the installed tyFlow 2027 binary, its existing Ghidra working copy, official vendor/Autodesk/Qt documentation, and the current tracked/untracked Cyrus Scatter source. Research and documentation only; no production implementation or runtime speed qualification.

## What we learned

tyFlow's selected native paths confirm several concrete mechanisms: Qt parameter widgets and Max parameter maps, lazy popup construction, guarded signal updates, selective rollout reuse and explicit ordering, validity checks before heavier evaluation, deferred invalidation, and Nitrous custom render items with instanced mesh data. This is substantially more evidence than recognizing Qt imports or reading public feature lists.

The binary also challenges the idea that its UI does everything once. The examined filterable combo retains its popup but rebuilds the displayed item model on opening. Selection can reuse some rollouts and destroy others. What matters for Scatter is which work belongs to UI binding, evaluation, display preparation and actual drawing.

Cyrus already has native C++ calculation, bounded work, stable identities, staged publication, and retained Mesh/Point Cloud display. Its `.ms` entry point and `.dlx` engine do not by themselves demonstrate a faulty foundation. There is a real P1 popup binding regression: switching owner on an already built topic can leave controls attached to the preceding layer. The current playback corrections have preserved headless regression evidence, but their presented FPS, interactive UI and Corona IR behavior remain unqualified in the artist session.

## Read in this order

1. [Method, identities and evidence limits](METHOD_AND_EVIDENCE.md): tools, fingerprints, ABI witnesses, selected regions and corrections to tempting conclusions.
2. [UI construction, binding and layout](UI_AND_BINDING.md): verified paths, their meaning, and the proposed selected-layer Modify view.
3. [Evaluation, calculations and viewport submission](EVALUATION_AND_DISPLAY.md): separate validity gates, CPU/GPU boundaries and remaining unknowns.
4. [Current Cyrus comparison and findings](CYRUS_COMPARISON.md): exact local references, what to preserve and severity-ranked gaps.
5. [Prioritized implementation loops and experiments](ROADMAP_AND_EXPERIMENTS.md): smallest next changes, measurements and acceptance criteria.
6. [Continuation guide](CONTINUATION.md): reproduce this investigation and pursue specific unanswered questions without restarting from scratch.

Machine-readable receipts are under [evidence/](evidence/research-receipt.json); neutral research scripts are under `reproduce/`. Detailed vendor pseudocode, assembly, the Ghidra database, compiler outputs and the binary stay in the private analysis workspace:

`C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis\research-20261006`

## Relationship to existing reports

The [independent source/public-interface assessment](../TyFlow_CyrusScatter_Assessment_2026-10-06/README.md) remains useful and is preserved. This new investigation independently confirms its popup binding finding and adds bounded evidence about previously unknown private UI and display paths. It does not recover the complete tyFlow scheduler, collision structures, original C++, or all GPU upload behavior.

The [current playback results](../Playback_Performance_2026-10-06/RESULTS.md) and [0.64 retained Mesh](../Retained_Mesh_Preview_2026-10-02/README.md)/[0.63 retained Point Cloud](../Retained_Point_Preview_2026-10-02/README.md) reports retain their dated qualification boundaries. No previous assertion count is presented as a new benchmark here.

## Work list

- [x] Verify target/tools and preserve the existing analysis project before annotations.
- [x] Map selected imports, RTTI, inheritance and host vtables using the local Max 2027 SDK.
- [x] Trace selected UI creation, binding, signals, rollout ownership and ordering paths.
- [x] Trace evaluation validity, invalidation and Nitrous preparation/submission paths.
- [x] Compare current source and inspect preserved test evidence.
- [x] Record findings, evidence limits, priorities and repeatable experiments.
- [x] Validate documents, source identities and research artifacts; save/close the project and stop the owned analysis server. See [verification receipt](evidence/verification.json).

Version remains 0.7.1. No packages, artist scenes/profiles, licensing implementation, commits or pushes were changed. No computer-use or interactive Max tests were performed.

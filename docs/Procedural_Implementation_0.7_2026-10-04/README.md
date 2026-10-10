# Cyrus Scatter 0.7 — procedural implementation

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

> **5 October follow-up:** This package describes the previously tested procedural snapshot. The working tree now includes unfinished native-column and automatic-spacing UI changes. Read the [current handoff](../Review_Handoff_2026-10-05/README.md) before loading current source or interpreting the readiness statement below. Existing installers still contain the earlier snapshot.

4 October 2026. Implementation and isolated Max 2027 validation of the [reviewed design](../Procedural_Evaluation_2026-10-04/README.md), based on checkpoint `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`.

**This development candidate is ready for artist testing in Max 2027 within documented limits.** After the offline coding phase, the user authorized computer access. Clean Max loading, procedural/Brush/Edit/UI fixtures, live MCP and 20k/100k navigation checks now pass. Max 2026 has SDK/native-test evidence only. Automatic scene-unit rescaling and high-count Proxy drawing remain limitations; see the runtime report.

- [Implementation report](IMPLEMENTATION.md): architecture, behavior, changes and deliberate limits.
- [Max runtime report](RUNTIME_REPORT.md): integration fixes, executed scenarios, 0.64 comparison and remaining release gates.
- [Validation and reproduction](VALIDATION.md): executed checks and remaining release gates.
- [Artist testing guide](MAX_TESTING.md): how to assess the candidate safely on project copies.
- [Delivery checklist](STATUS.md): current implementation and validation status.

Product metadata is **0.7.0**. Policy 3 is explicitly enabled with **Surface Scatter → Enable Procedural 0.7**. Policies 1 and 2 retain their generation semantics. The first conversion changes the sampler deliberately; it is not an invisible upgrade of a saved layout. Existing CS Edit stacks block conversion, preserving their records.

Candidate packages are staged in `dist/procedural-0.7-candidate/`. They are not installed and are not a publishable 1.0 release. Earlier 0.64/1.x packages and dated benchmark reports remain intact.

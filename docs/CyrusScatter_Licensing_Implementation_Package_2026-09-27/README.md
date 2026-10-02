# Cyrus Scatter — historical licensing package

**Superseded for implementation on 2026-10-02.** Use the [current licensing home](../licensing/README.md), [roadmap](../licensing/ROADMAP.md) and [decisions](../licensing/DECISIONS.md). The selected direction is our own service. Provider recommendations, example commercial terms, worker-detection assumptions and estimates below are historical proposals.

The [document audit](../licensing/DOCUMENT_AUDIT.md) maps all 33 chapters and nine diagrams to their current treatment. Those files remain byte-for-byte preserved; this entry page and its manifest record the routing update.

## Original September 27 entry


**Date:** 2026-09-27  
**Codebase baseline:** `b9a9e909b469456a6193337363b7c50b2397e549`  
**Parent documentation:** `CyrusScatter_Complete_Codebase_Documentation_2026-09-27`

This package is the implementation plan for commercial licensing Cyrus Scatter without rewriting its existing scatter/analyzer engines. It is based on the completed codebase documentation and the audited repository, with current provider/Autodesk facts refreshed from official sources.

## Recommendation in one sentence

Build a small native licensing authority first, with a fake provider and capability tests; enforce authoring/edit/analyzer/export at native boundaries; preserve saved-scene/render evaluation; then run Cryptlex and Keygen POCs behind the same provider interface before committing to a vendor.

## Recommended commercial shape

- **Solo:** perpetual, node-locked, one authoring machine by default, 12 months of updates.
- **Studio:** perpetual or annual commercial contract, concurrent/floating authoring seats.
- **Trial:** 30-day full-feature node-locked evaluation.
- **Offline:** signed offline activation workflow; on-prem floating for air-gapped studios when commercially justified.
- **Render nodes:** free/restricted `RenderExistingScene`; no authoring, CS Edit mutation, Analyzer authoring/export or bake.
- **Updates:** maintenance entitlement controls new releases; an owned eligible build continues to run.
- **Security:** native checks + signed state + provider activation limits + code signing + protected release CI. No claim of being uncrackable.

## Recommended first vendor POC

Start with **Cryptlex**, because its current product maps directly to Cyrus Scatter's node-locked, offline, hosted floating, on-prem floating and maintenance requirements. Run **Keygen** second because it offers a strong cryptographic/offline API model and greater architectural flexibility. Keep `ILicenseProvider` so either can be replaced.

This is a recommendation, not a lock-in decision. The provider decision is gated by the POC acceptance matrix in this package.

## Important implementation rule

Do not add provider SDK calls to `scatter.cpp`, `spacing.inc`, `orientation.inc`, `final.inc`, or the Analyzer mathematical core. Licensing belongs at host-facing boundaries and in a shared native licensing component.

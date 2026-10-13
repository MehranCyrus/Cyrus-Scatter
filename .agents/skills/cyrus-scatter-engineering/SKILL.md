---
name: cyrus-scatter-engineering
description: "Design, implement or audit CyrusScatter behavior using explicit contracts and scoped evidence. Use for ownership, randomness, dependencies, publication, persistence, geometry, performance and release version selection; skip trivial wording and knowledge-pipeline-only work."
---

# Cyrus Scatter engineering

Follow repository startup instructions once per task; reuse the established baseline
and relevant evidence. Keep new work in English. This skill adds behavioral reasoning,
not another startup reading list or authorization to expand the task.

Select affected sections in the [foundation](../../../docs/ENGINEERING_FOUNDATION.md):

| Question | Contract IDs |
| --- | --- |
| Owners, independent layer edits, coverage, collision priority | F01, F03 |
| Stable candidates, randomness, quotas, Relax | F02; F03 for acceptance |
| Manual/Live, animation, browsing, buffer reuse | F04, F08; F12 for Analyzer |
| Failure, publication, resource admission, workers | F05–F07 |
| Geometry, units, save/merge/Undo, missing dependencies | F09–F11 |

Read each selected contract's applicability, rationale, evidence and falsifier. Read its
linked source/test and the relevant [architecture](../../../docs/ARCHITECTURE.md)
section only as needed. Decision status and verification are independent. Check the
relevant [backlog](../../../docs/BACKLOG.md) before claiming a known failure is fixed.
Audit receipts may be local/ignored; missing receipts leave their execution claims
unverified in another checkout.

Describe the artist action, expected change and unaffected result. Trace the owner,
persistent identity, dependencies, stage and publication boundary. Keep candidate IDs
separate from accepted/shown/output rows, UI source-row IDs separate from native
correspondence, and pending recipes separate from published state.

Use advertised knowledge tools for relevant evidence under repository instructions;
inspect current originals before consequential edits. For retrieval mechanics or
typed errors, consult the [knowledge skill](../cyrus-scatter-knowledge/SKILL.md) only
if not already applied. Do not recursively load both skills or their linked libraries.

Choose a proportionate design inside the existing pipeline. For an unresolved product
tradeoff, prepare a concrete recommendation and continue unaffected work. Research
only decision-critical uncertainties, reusing applicable project studies first;
uncertain vendor/API facts need primary sources with version/scope. Separate vendor
documentation, observation, inference and the design chosen for Cyrus.

Validate the intended change, an important unaffected case and relevant failure or
lifecycle boundary. Compare stable identities and full transforms for stability;
compare solve/preparation/upload counters separately for reuse. Account for quotas,
Relax, acceptance and topology. Test failures on both sides of publication;
pre-commit rejection alone does not prove atomicity.

Use the [workflow](../../../docs/AGENT_WORKFLOW.md) for test levels and host isolation.
Before choosing a delivery version, apply the [version policy](../../../docs/Release_Versioning.md#choosing-the-next-version).
Assess the full change since the last delivery, record the proposed version and its
impact-based reason, and keep version labels separate from qualification claims.
Offline passes do not qualify Max callbacks, physical interaction, renderers or loaded
builds. Record actual results and open acceptance in the existing maintained location;
preserve historical receipts. No activation, installation, compatibility framework
or new subsystem is implied by this skill.

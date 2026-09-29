# 14 — Documentation governance and reconciliation

## One authority for each question

| Question | Governing document |
|---|---|
| What should we build next, and why? | [Master roadmap](11_Master_Roadmap_and_Backlog.md) |
| What actually exists and has been verified? | [Current evidence](02_Current_System_and_Evidence.md), source and referenced artifacts |
| How should a performance experiment preserve behavior? | [Performance compatibility contract](../Performance_Roadmap_2026-09-28/03_Compatibility_and_Regression.md) |
| How do we measure and compare it? | [Benchmark design](../Performance_Roadmap_2026-09-28/02_Baseline_and_Benchmarks.md) |
| How might licensing be implemented? | Existing [licensing package](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md), corrected by [current policy decisions](09_Licensing_and_Commercial_Strategy.md) |
| How was the original system organized? | Dated [codebase reference](../CyrusScatter_Complete_Codebase_Documentation_2026-09-27/README.md) |
| How do I install today's test package? | [Max 2027 installation guide](../Max_2027_Installation.md) |
| Is a vendor feature available, and what does that prove? | [Research source register](15_Research_Sources.md), followed by local integration tests |

Current source/test evidence outranks descriptive prose. A newer proposal does not override a scene contract merely by being newer; intentional changes need an explicit decision and regression evidence.

## Stale-claim map

| Historical statement | Current correction | Treatment |
|---|---|---|
| Project is Max 2026-only | Shared 2026/2027 configuration; 2027.1 compatibility build exists | Preserve old audit; use current evidence for status |
| No compiler/SDK or successful native tests | Provisioned in compatibility task; existing tests pass | Do not repeat setup unless prerequisites actually change |
| Analyzer has no core-only option | Option now exists | Record standalone build validation separately |
| All performance backlog tasks not started | Foundation tasks partly progressed; optimization remains pending | Master backlog supplies current mapping |
| Generator not executed | Two isolated byte-identical runs now observed | Continuous automated check still needed |
| Analyzer has no Scatter integration | Current generated controller consumes its data | Analyzer standalone README is historical on this point |
| Test packages use stale MZP metadata | Staging build generates corrected package version/host values | Source metadata still needs consolidation |
| A license provider is the clear first choice | Previous recommendation has no fresh contract-test result here | Retain as historical shortlist; no selection implied |
| Perpetual offline semantics settled | Renewal/continuity conflict remains | Resolve before enforcement/sale |
| Repository visibility/public exposure is known today | Only an old audit reports it | No Git/remote inspection in this review; current status unknown |
| Report speedups and week estimates are actionable forecasts | No representative comparative campaign exists | Treat as hypotheses; estimate after spikes/baseline |
| “Max 2027” is one uniform capability level | Newer update features need explicit version gates | Separate 2027.1 tested baseline from 2027.2 experiments |

## Preserve useful references without multiplying plans

The earlier codebase/licensing manifests describe dated packages. Do not casually edit every historical file and invalidate those manifests. The main docs index routes readers to this reconciliation and the current master plan. If an active specification must change, add a dated change record and update the appropriate manifest deliberately.

The original research report remains background material. Its inaccessible exported citation tokens/ZIP references do not establish local artifacts or current evidence. It is not the coding authority where the performance audit corrects its assumptions.

## Documentation required with a code change

Each meaningful change records:

1. Task ID and reason.
2. Actual source/template changes and any schema effects.
3. Expected user-visible behavior and limits.
4. Exact tested configurations and evidence paths.
5. Performance/memory result when that was the purpose.
6. Recovery/rollback instructions and unresolved risks.

Update the status ledger in the same work cycle. A passing local test is recorded as that test, not upgraded into a generic “fully tested” claim. Retain a known-issues section for each release.

## Artifact preservation

Archive immutable copies of raw samples, fixtures, build identity, package hashes and test outputs outside temporary build logs. This package captures the earlier smoke/CTest material in [prior runtime evidence](evidence/prior_runtime_evidence.json). The newer [native rerun](evidence/native_test_rerun.json), [generator check](evidence/generator_check.json) and [package check](evidence/package_check.json) have their own dates and limits.

Use filesystem snapshots/checksums in the current workflow. Old documents that mention Git are historical design instructions; they do not authorize using Git against the user's explicit constraint.

## Future customer documentation

Create short user-facing pages for install/upgrade, first scatter, each flagship workflow, constraints/units, manual edits, renderer support, assets/farms, licensing recovery and diagnostics. Include screenshots only from verified UI builds. Keep internal experiments and implementation details out of ordinary artist instructions.

The current strategy package is an engineering/product guide. It should help us produce a simpler user experience rather than becoming required reading for an artist.

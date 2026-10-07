# R&D review tasks — Cyrus Scatter 0.72 and tyFlow

6 October 2026. Review and documentation only. No product changes, packaging, installation, artist-scene edits, commit or push. No computer-use.

- [x] Freeze clean source, commit, binary and tool identities; audit earlier receipts independently.
- [x] Reconcile the earlier 0.7.1 assessments with the completed 0.72 changes.
- [x] Follow selected tyFlow render-item, invalidation, scheduling and calculation anchors with bounded static analysis.
- [x] Check uncertain contracts against official Autodesk, Qt and tyFlow sources.
- [x] Trace the current Cyrus generation, eligibility, transforms, identities, collision scopes, cleanup/refill, publication and output pipeline.
- [x] Review the 0.72 diff separately from pre-existing architectural concerns.
- [x] Run useful offline correctness/performance experiments in ignored workspaces; record limitations and failures.
- [x] Map every capability family, maturity evidence, missing scenarios and sensible extensions.
- [x] Write severity findings, small next steps, measurement protocols and acceptance criteria.
- [x] Reconcile active documentation entry points without rewriting historical evidence.
- [x] Close only owned analysis processes; verify unchanged production files and vendor binary, and validate documentation links and receipts.

Completed within the review scope. [Results](README.md), [severity/next coding loops](FINDINGS_AND_ROADMAP.md), [evidence index](evidence/index.json) and [validation](evidence/validation.json).

Execution: 14 native suites, 140 Python tests, 503 independent collision cases and 300 Brush-reference queries pass. E1's intentional work-limit failure and the initial fixture's incorrect keyed-row assumption are retained. Static analysis covers 26 selected regions with explicit partial/decompiler limits.

Final preservation: HEAD and both vendor binary hashes match; 559/560 inventoried entries and 584/585 protected tracked entries match. The sole intended exception is CyrusMCP/README.md, a documentation update. No production implementation, scene/profile edit, package/install or Git mutation was performed.

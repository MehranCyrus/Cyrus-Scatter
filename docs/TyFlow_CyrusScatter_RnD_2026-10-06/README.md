# Cyrus Scatter 0.72 and tyFlow â€” comparative R&D review

**Subsequent implementation and measurements:** [approved UI, real scenes, exact evidence and remaining limits](../Full_Qualification_0.73_2026-10-07/README.md). The latest report supersedes older UI/runtime qualification claims; dated implementation and R&D evidence below remains historical. No artist installation or Git operations are part of this campaign.

**Implementation follow-up:** [0.73 unified system](../Unified_System_0.73_2026-10-06/README.md) ports/removes old paths, adds container nodes and reconciles the current catalog. This independent 0.72 review remains its frozen evidence; remaining findings are tracked in the [0.73 roadmap](../Unified_System_0.73_2026-10-06/ROADMAP.md).

6 October 2026. **Completed research, source review, bounded private static analysis, offline experiments and documentation reconciliation.** Production fixes, packaging, installation, artist-scene/profile edits, computer-use, commit and push are outside this task. Version remains 0.72.

Cyrus has the right foundations to preserve: native numeric calculation, ordered ownership and stable identities, bounded collision/refill, staged CPU publication, safe copied-data workers and retained Mesh/Point display. The user's slowdown observations warrant phase measurements; they do not establish that MAXScript or the original foundation is inherently wrong.

Selected tyFlow evidence now connects retained render-item construction/destruction, preparation-time buffer filling and instanced draw, plus selected thread-pool/main-thread guards. It does **not** recover the whole private engine or prove an overall speed ranking. Object reuse and unchanged data reuse are different claims.

Three existing CPU/resource costs were reproduced independently: exhaustive projection, radius-outlier grid collapse and wide Brush-field preparation. A small new diagnostic-export cleanup weakness was source-reviewed. Earlier popup-owner binding is fixed by 0.72; artist UI, presented FPS, successful docked IR, Max 2026 runtime and Brush BR-01 remain qualification gates.

## Read in this order

1. [Findings and prioritized loops](FINDINGS_AND_ROADMAP.md): severity, exact source locations, evidence, smallest fixes and acceptance criteria.
2. [Maturity and limits](MATURITY.md): what is solid, partial, experimental and unqualified, without an invented completion percentage.
3. [Current Cyrus pipeline/cache map](CYRUS_PIPELINE.md): generation through eligibility/Edit/radius/collision/cleanup/publication/output, ownership and failure boundaries.
4. [Every capability family](CAPABILITY_MAP.md): all C01â€“C34, current native/MCP boundaries and useful tyFlow comparisons.
5. [What the tyFlow analysis establishes](TYFLOW_INTERNALS.md): connected UI/validity/display/jobs, corrected provisional labels and unresolved private internals.
6. [Executed experiments and fair comparison protocol](EXPERIMENTS.md): correctness oracle, CPU scaling, memory lower bounds and missing runtime scenarios.
7. [Focused 0.72 diff review](CODE_REVIEW.md): one nonblocking P2, no newly verified P0/P1; separate from older architectural findings.
8. [Method and evidence](METHOD_AND_EVIDENCE.md), [document audit](DOCUMENT_AUDIT.md) and [completed task list](TASKS.md).

## Results that can be reproduced

| Work | Result / practical meaning |
| --- | --- |
| Identity audit | All 560 earlier 0.72 inventory entries matched initially; 585 tracked non-doc-directory files separately frozen. Only documented Markdown edits are allowed in the final comparison. |
| Historical evidence | All 52 indexed receipt hashes and four native SDK source/binary inventories match. This audits integrity; it does not rerun Max campaigns. |
| Fresh pure-core tests | 14/14 native suites pass; no Max plugin/package build. |
| Fresh Python contracts | 140 pass, zero failures/errors/skips. |
| Independent collision check | 503 exhaustive-pair oracle cases pass accepted indices, protection/conflicts and rejection scopes. |
| Brush replay check | 300 queries across twelve fixtures agree with the reference; this is partial flat-field evidence. |
| Radius stress | One far radius outlier causes 49,985,001 visits at 10,000 points and explicit bounded failure at 12,000. Correctness and broad-phase efficiency are separate. |
| Projection stress | 1,000 candidates / 20,000 triangles: median 146.985 ms projected versus 1.028 ms unprojected. CPU preparation, not FPS. |
| Brush stress | 8,192 faces / 256 wide dabs: 265.964 ms field build and at least 24 MiB patch/link payload. Lower bound, not process memory. |
| Private binary work | 26 selected regions inspected with bounded exports, RTTI and fresh SDK ABI witnesses. Some paths have explicit decode/decompiler limitations. Owned headless backend saved/closed/stopped. |

Neutral reproduce helpers are under [reproduce/](reproduce/run_core_probe.py); curated factual receipts are indexed in [evidence/index.json](evidence/index.json). Detailed vendor listings, copied Ghidra project and full logs remain private; no vendor pseudocode/binary is added to Git.

## Current delivery and extension boundaries

The [0.72 implementation campaign](../Integrated_UI_0.72_2026-10-06/README.md) remains implementation/package authority. This R&D folder adds independent review and future acceptance work, not a new install.

MCP 1.2 has twelve tools/seven resources. Policy 3 is read-only; schemas 1/2 keep their supported locally approved writes. Publication pages contain actual cached rows, not a complete portable recipe/assets package. The local recorder needs no MCP. The offline Design Lab has a small experimental ranker; there is no trained artist/reference model or automated creative learning system. Commercial licensing remains a separate incomplete default-off track.

Active docs are reconciled here; the existing product feature-catalog JSON is intentionally unchanged. Its renderer/learning help and source hash must be regenerated and qualified in a future coding loop. [Exact document changes and deferred artifact](DOCUMENT_AUDIT.md).

The immediate implementation recommendation is bounded Brush persistence/resource/reporting closure, then the specific projection acceleration. Preserve the measured retained display paths and use the controlled host protocol before a blanket UI/engine rewrite, persistent worker framework or GPU placement project.

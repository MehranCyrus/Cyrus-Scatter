# GPU interaction research comparison

Reviewed 27 October 2026. Scope: compare the supplied research and verify decision-critical claims; no plugin implementation or release qualification.

**Report C is the best primary implementation guide for CyrusScatter. A is a close second and the strongest detailed reference. B is particularly valuable for solver alternatives and reproducible validation. D reaches a sensible broad recommendation but needs more correction before it guides engineering.** This is a judgment about these reports, not an AI model benchmark.

| Report folder | Best use | Main qualification |
|---|---|---|
| [C](../CyrusScatter_GPU_Interaction_Research_2026-10-27_C/00_README.md) | Main implementation outline and Max API proof | Most actionable host integration, compiler clarification, publication and numerical contracts; no executed GPU fitter or Max bridge |
| [A](../CyrusScatter_GPU_Interaction_Research_2026-10-27_A/00_README.md) | Detailed solver/reference companion | Strongest depth and explicit drag-liveness gates; correct its inference about the Max compiler toolset |
| [B](../CyrusScatter_GPU_Interaction_Research_2026-10-27_B/00_README.md) | Alternative algorithms, feasible controls and matched benchmarks | Strong analytic checks; overlooks a documented shader buffer binding method |
| [D](../CyrusScatter_GPU_Interaction_Research_2026-10-27_D/00_README.md) | Shorter architectural cross-check | Device API coverage, five weighted totals and pose-storage assumptions need correction |
| [LocalCodex](../CyrusScatter_GPU_Interaction_Research_2026-10-27_LocalCodex/reports/local-codex/00_README.md) | Actual source, hardware and component-probe evidence | Only package with executed CUDA/OpenCL deformation and owned D3D11 sharing; neither probe is an in-Max fitter test |

The recommended combined approach is **C's plan + A's solver and liveness detail + B's positive controls + LocalCodex's measured evidence**. First profile the current CPU path and prove shared-source shader deformation in Max 2027. A full CUDA fitter is a later, conditional experiment. None of the reports establishes a CUDA performance win for the real Cyrus fitter.

## Review documents

- [Comparison, ranking and corrections](COMPARISON_AND_RANKING.md)
- [Consolidated lessons and next experiment gates](CONSOLIDATED_FINDINGS.md)
- [Claim-by-claim comparison](CLAIM_MATRIX.csv)
- [Primary-source and local-source checks](SOURCE_CHECKS.md)
- [Original inventory and manifest checks](INTAKE.json)
- [Reproduced analytic checks and corrected D arithmetic](ANALYTIC_VERIFICATION.json)
- [Final review validation](REVIEW_VALIDATION.json)

The original five packages are preserved. All four external packages internally call themselves researcher A; this review uses their containing folders **A/B/C/D** to avoid misattribution. Researcher/model metadata is self-reported. Existing LocalCodex measurements were inspected, not rerun for this comparison. Analytic checks from A/B/C were rerun in an owned build directory.

The engineering context is the supplied 0.87.4.3 interaction baseline, native capability 11 / scene schema 63. Concurrent repository work is separate; neither the reports nor this comparison certify it. The knowledge corpus was stale, so consequential checks used original source and installed SDK headers.

# Vegetation core handback reviews

Local review evidence for the [external C++ prototype handoff](../vegetation-core-handoff/README.md). These receipts do not change Scatter's release qualification or the research validation matrix. Supplied source packages and external execution records remain intact under their original intake folders.

| Owner | Local review | Result and scope |
| --- | --- | --- |
| A — collision | [24 October review](A-REVIEW-20261024.md), [identity/results JSON](A-REVIEW-20261024.json) | Unchanged source built with MSVC; 15/15 Windows headless tests passed. Approved for bounded primitive prototype integration; remaining contract/host gates retained. |
| B — static fitter | [24 October review](B-REVIEW-20261024.md), [identity/results JSON](B-REVIEW-20261024.json) | Unchanged source passed 19/19 standalone MSVC tests. Combined A+B passed 47/47: 15 A, 19 B and 13 coordinator integration cases. Guide acceptance only; C/host/resource gates remain. |
| C — mesh and independent validation | [24 October review](C-REVIEW-20261024.md), [identity/results JSON](C-REVIEW-20261024.json), [local correction](fixes/C-20261024/README.md) | Original source passed 4 groups / 23 individual Windows tests; four additional defects reproduced and corrected in an isolated variant. Final A+B+C passed 52/52 groups, including four regression cases and a conservative-box rejection control. Visible catalog ribbon passes; Max/resource/profile limits remain. |

The [research library](../vegetation-interaction/README.md) remains the synthesis and evidence register. Its 68 validation cases and eight decision experiments remain Pending until their actual requirements are executed and reviewed. Module test counts alone do not qualify those cases.

The reviewed code also feeds the independent [Cyrus Vegetation Lab 0.1.0](../../../CyrusVegetationLab/README.md), a bounded Max 2027 artist test with prepared ribbons and one spherical collider. Its [host qualification](../../../CyrusVegetationLab/docs/QUALIFICATION.md) is scoped separately from these original reviews and the full research matrix.

The subsequent [dense lavender / moving-sphere experiment](../../../CyrusVegetationLab/experiments/dense-live/REPORT.md) tests a real 577,792-vertex / 832,240-triangle library asset. It records a quadratic admission stall, a separate optimized variant, full-resolution timing/contact checks and physical pointer findings. Its coarse whole-clump binding is not natural vegetation preparation, and held-drag continuity remains unqualified; neither this experiment nor its private variant changes the original A/B/C acceptance or Scatter support.

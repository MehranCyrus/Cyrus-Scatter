# Executed checks — Researcher A

**Research date:** 27 October 2026. **Execution scope:** Python standard-library analysis and package verification only.

## Environment actually observed

Linux x86_64 (`Linux-6.18.55-x86_64-with-glibc2.39`), Python 3.12.14. The available C++ compiler identifies as `g++ (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0`; no C++ build was executed for this study. `nvcc`, `nvidia-smi`, `clinfo`, `cmake`, `clang++`, PowerShell and .NET were not found in the observed command path. No `/dev/nvidia*` device was exposed. This is an availability observation, not proof about the machine's undisclosed physical hardware.

No installed Max, Max SDK, Windows compiler/runtime, qualified GPU, production repository or intended production renderer was supplied or used. Full details and input digests are in [environment_and_inputs.json](environment_and_inputs.json).

## Executed commands and observed outcomes

Run from the extracted document directory:

```sh
python3 analysis/calculate_budgets.py
python3 analysis/check_adversarial_geometry.py
python3 analysis/check_decision_scores.py
```

All three commands exited **0**, emitted parseable JSON and had empty stderr. Their captured stdout is included unchanged as `calculated_budgets.json`, `analytic_counterexamples.json` and `decision_scores.json`.

- Byte/field arithmetic, representative binary32 spacing and hypothetical transfer division completed. Populations, node counts, layouts and bandwidth choices remain explicit assumptions.
- All six analytic counterexample assertions passed. These demonstrate geometric hazards; they do not exercise a fitter, mesh-query library, shader, GPU or Max.
- Decimal weighted-score arithmetic matched both decision tables and the declared portability/interop sensitivities. Scores are proposed judgments, not measured performance.
- The four supplied source-document hashes matched their supplied manifest. Input copies are byte-identical, including original line endings.

## Package verification

The verifier is [verify_package.py](verify_package.py). The following command exited **0** with status **Passed** against the assembled directory and real ZIP:

```sh
python3 analysis/verify_package.py . --zip ../CyrusScatter_GPU_Interaction_Research_2026-10-27_A.zip
```

| Check | Observed result |
|---|---:|
| Required core files present | 21: nineteen requested Markdown chapters, metadata and manifest |
| Complete file inventory | 37 files; metadata, directory and ZIP inventories agree |
| Actual SHA-256 verified | 36 included files; the outer manifest excludes itself |
| Supplied input-document hashes | 4 of 4 match the unchanged supplied input manifest |
| Markdown files checked | 24, including analysis notes and supplied inputs |
| Relative links / anchors | 386 checked; no missing target or anchor |
| Source records | 143 unique IDs with matching ledger anchors |
| External links recorded | 141; not an automated network recheck of all sources |
| ZIP member safety and parity | 37 members; no duplicate/absolute/traversal/symlink paths; every member matches the directory bytes |
| ZIP integrity | CRC/integrity check passed |

These counts describe package integrity, not GPU or host correctness. The same verifier is rerun after final metadata/manifest regeneration. The archive's own SHA-256 is reported with the delivered file rather than embedded inside itself. Hash verification is not a cryptographic signature or a guarantee that live external documentation will remain unchanged.

## Not executed

No CPU/GPU fitter comparison, CUDA/OpenCL/D3D compilation, shader execution, Windows presentation trace, Max host test, renderer/Bake/export test, installer test, hardware benchmark, device-loss test or production-code modification was performed. P0–P5, G0–G6, the benchmark cases and their proposed tolerances/budgets are specifications awaiting local implementation and measurement.

No elapsed-time benchmark, speedup ratio, fit convergence rate or working in-Max interop claim is inferred from these scripts. The supplied approximately 4.05 ms contact-evaluation observation remains a provided project fact with its original narrow scope.

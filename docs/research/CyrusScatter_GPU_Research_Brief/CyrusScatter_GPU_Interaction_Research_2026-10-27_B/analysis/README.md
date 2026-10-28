# Reproducible analysis and execution scope

These small Python 3 standard-library programs were executed for this research. They are arithmetic, analytic counterexample oracles and package checks. They are **not** a GPU backend, guide fitter, Max plugin or performance harness. The implementation prototypes in chapter 14 remain **Not executed**.

Run from the extracted package directory:

```sh
python3 analysis/calculate_budgets.py
python3 analysis/check_adversarial_geometry.py
python3 analysis/check_decision_scores.py
python3 analysis/verify_package.py .
```

To verify an unchanged archive as well as its extracted directory:

```sh
python3 analysis/verify_package.py . --zip ../CyrusScatter_GPU_Interaction_Research_2026-10-27_A.zip
```

| Program / record | Actual scope |
|---|---|
| [calculate_budgets.py](calculate_budgets.py) → [calculated_budgets.json](calculated_budgets.json) | Byte arithmetic under explicit hypothetical layouts/populations; binary32 spacing and local rebasing; hypothetical bandwidth division; no modeled allocation or transfer is executed |
| [check_adversarial_geometry.py](check_adversarial_geometry.py) → [analytic_counterexamples.json](analytic_counterexamples.json) | Six analytic assertions: whole-span crossing, width envelope, fixed root/zero gradient, contained span, narrow gap, quaternion antipodes; no search or production collision implementation is tested |
| [check_decision_scores.py](check_decision_scores.py) → [decision_scores.json](decision_scores.json) | Decimal arithmetic for declared judgment scores and sensitivity weights; no benchmark-derived scoring |
| [verify_package.py](verify_package.py) | Actual SHA-256, inventory, required files, relative Markdown links/anchors, input manifest, stable source IDs, optional ZIP paths/CRC/content parity; does not establish the truth of a cited page |
| [environment_and_inputs.json](environment_and_inputs.json) | Observed tool availability and exact input hashes; supplied source paths are not evidence of private repository access |
| [source_ledger.json](source_ledger.json) | Machine-readable records underlying [the source ledger](../17_SOURCE_LEDGER.md) |
| [EXECUTED_CHECKS.md](EXECUTED_CHECKS.md) | Commands, observed outcomes and limitations of this research's execution |

The JSON outputs are actual stdout captured from the three analysis scripts. Re-running those scripts writes only stdout unless the caller redirects it. Package verification intentionally fails after editing a file without updating the manifest. The manifest excludes only itself; the separately supplied input manifest is included and hashed.

No GPU timings, benchmark traces, generated plant fixtures, renderer images, compiled vendor samples or application binaries are included. Future benchmark generators must produce their own exact array fingerprints; this package does not invent hashes for uncreated assets.

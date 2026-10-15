# Executable reference examples

These examples support the **Cyrus Scatter Rebuild Blueprint**, especially identity, sampling, painting arithmetic, and collision correctness. They are not a production plugin or a substitute for the host/renderer fixtures in chapter 20.

## Files

| File | Purpose |
|---|---|
| `reference_oracle.py` | Self-contained standard-library Python algorithms and checks |
| `reference_validation.json` | Actual captured execution report from this delivery |
| `control_catalog.json` | Machine-readable copy of all 301 proposed controls/commands |
| `source_registry.json` | Primary-source URLs, evidence status, and original-source digest |

## Run

Use Python 3.10 or later. No third-party packages are needed. From this directory:

```bash
python reference_oracle.py --report reference_validation.json
```

A failed assertion exits with an error rather than producing a false success. A successful run prints a summary and writes the JSON report. The reported elapsed times are not performance targets.

## Actual delivered results

| Group | Check | Result |
|---|---|---|
| 1 | `keyed_randomness_and_partition_invariance` | PASS |
| 2 | `stable_density_thinning_before_collisions` | PASS |
| 3 | `source_weights_empty_and_list_order` | PASS |
| 4 | `ordered_areas_and_independent_contributions` | PASS |
| 5 | `canonical_paint_composition_and_exact_snapshot_undo` | PASS |
| 6 | `piecewise_linear_pdf_inverse_cdf` | PASS |
| 7 | `nonlocal_collision_chain_counterexample` | PASS |
| 8 | `accelerated_grid_matches_naive_full` | PASS |
| 9 | `exact_union_closure_matches_full_after_edits` | PASS |
| 10 | `pin_precedence_tangency_and_zero_radius` | PASS |
| 11 | `density_monotonicity_does_not_extend_through_collisions` | PASS |
| 12 | `invalid_input_guards` | PASS |

The grid comparison uses 60 generated fixtures at four grid sizes: **240 comparisons**. The exact incremental comparison uses 100 edit sequences of six edits: **600 comparisons**. The chain example contains 40 candidates and demonstrates that removing one candidate can alter acceptance across the entire chain.

The deterministic survival fixture evaluated 10,000 candidates: 2,494 survived a 0.25 threshold and 5,005 a 0.50 threshold. The latter set contains the former **before collision filtering**. These are observed output counts for this reference seed, not ForestPack measurements.

The weighted selection fixture evaluated 10,000 choices: A=4,978; B=2,972; Empty=2,050. These are illustrative sample outcomes, not exact quotas. List-order invariance is checked independently.

## What the code intentionally simplifies

Sphere conflicts and the old/new graph closure are brute-force reference computations except for the separately compared spatial-grid implementation. They favor clarity over production throughput. They do not represent receiver meshes, BVHs, actual projected brush kernels, host events, renderer prototypes, or GPU upload.

The paint test evaluates integer sample composition and exact before/after array restoration. It does not execute 3ds Max Undo. The area test demonstrates ordered contribution semantics on a tiny domain, not a production polygon engine.

The probability sampler supports piecewise-linear probability-density curves. A production curve editor must compile its chosen curve type into a validated representation or implement a correspondingly accurate integrator.

## How to port responsibly

Keep this oracle independent from the optimized C++ path. Add canonical input/output fixtures before changing algorithms. Compare IDs, selected sources, accepted sets, and relevant numerical values with declared tolerances. Test negative/invalid data and resource limits as carefully as ordinary scenes.

Do not include mutable execution order, cache tile IDs, host handles, or process-specific hashes in persistent randomness. Do not make the optimized test call the same implementation as the reference and then report that agreement as independent validation.

## Catalog schema

Each control row contains `id`, `label`, `type_range`, `default`, `impact_test`, `meaning`, `owner`, `chapter`, and `evidence`. The catalog does not generate Max parameter blocks by itself. Its textual domains first need a typed schema and explicit migration binding in the actual plugin.

All rows describe proposed build targets. Some depend on adapter capability gates; their presence is not a claim of shipping support.

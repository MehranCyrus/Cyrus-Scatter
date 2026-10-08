# Focused Chaos Scatter ownership inspection

8 October 2026. This answers the model/painting naming question, not the separate cache/performance research proposal.

Installed package metadata reports **9.0.671707, Max 2027**. Copies were made under ignored `build/chaos-ownership-20261008-01/`, with matching original/copy SHA-256:

| File | SHA-256 |
| --- | --- |
| ScatterMax_Release-2027.dll | `f7fdd25428e8374174501e6bb4ebd3b83e21c5ba2c33fcdc94280c022695b887` |
| ScatterCore.ForScatter_Release.dll | `069ababd0dbc09218928f24d5bdc860509b237f34af703581e3fd78ed5d3cf86` |
| PackageContents.xml | `b6ef25f1507552311f3523edc7c5b4edea1d6c3a48f41a063e1ec823c8cb7da1` |

The existing Ghidra 12.1.4 / ghidra-mcp 6.0.0 / Java 21 installation operated through an isolated localhost server, fresh user home and `ChaosOwnership` project. The tyFlow and Forest projects were preserved. This pass analyzed the Max adapter; the copied core library was not decompiled.

## Evidence and interpretation

- Defined strings include separate `modelNodes`, `modelFrequencies`, `targetNodes` and `targetFactors` fields. Model-node references at `18000f368` / `18000f3a0` and target-node references at `18000f472` / `18000f4aa` enter the same parameter-registration function, `180007050`.
- Separate painter fields include brush radius/rate, filterable instances and instance-override points, IDs and transforms. The override-points string has references at `1800099d5` / `180009a18` in that registration function.
- Decompilation identifies registration of a `ChaosScatterPb` parameter block. Its reconstructed varargs call does not expose the entire registration argument list, so it is not a recovered data-structure definition.
- These findings support distinct model, target and painted-instance responsibilities. They do **not** prove that every painter uses direct placement, that Chaos has no region/layer mechanism, or that its internals match Cyrus's sets. The image also contains a layer-painter radius field and a message referring to painted layer strokes.

[Official Chaos documentation](https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter) supplies the artist-facing target/model distinction. [The recommendation](MODELS_AND_PAINTING.md) combines this with Forest's documented area workflow and inspected region-shape implementation. No vendor implementation was copied into Cyrus.

## Reproduction and limitations

The [neutral Forest backend helper](../ForestPack_Research_2026-10-08/reproduce/backend.py) was reused with the new run directory. The live schema is `/mcp/schema`. Relevant endpoints were create/open project, load program, run analysis, analysis status, list strings, references, decompile, save, export and close.

The first import preceded project creation after a schema-output encoding error. Its save consequently failed. Raw results preserve that failure. Reopening the isolated project and importing again produced a successful completed analysis (7,089 discovered functions), successful project save and an 11,876,369-byte GZF export. Analysis requests exceeded the client timeout; status was inspected before further mutations. The project was closed and backend PID 33128 stopped after matching executable, argument file and listener ownership.

Saved analysis and raw strings/listings remain ignored locally. Original vendor files, normal Max profile and artist scenes were not modified. There was no Chaos host painting test, performance measurement or cache-invalidation qualification. Counts of discovered functions are not analysis-completeness percentages.

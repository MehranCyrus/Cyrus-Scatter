# Delivery checklist and next gates

4 October 2026. This is the working implementation tracker; the broader original contract is [PLAN.md](PLAN.md).

| Step | Purpose and implementation | State / evidence |
| --- | --- | --- |
| 1. Audit native host limits | Use documented Max subrollouts and retained per-slot controls; avoid another custom visual framework | Implemented; native probe and actual single-click inspection |
| 2. Account for controls | Preserve existing feature bodies; move general settings outside each layer and bind local editors by owner | Generated JSON inventory plus capability table; advanced dialog permutations remain broader QA |
| 3. Persist parent/set ownership | Keep ten native population slots, explicit parent IDs, independent sources/history and deterministic budget allocation | Ownership/copy/remove/Undo, shared count/density and save/reopen fixtures |
| 4. Resolve the final union | Inter-set collision, parent-wide cleanup, pair rules expanded across children; retain protected Edit semantics | Pairwise distance, cleanup-neighbor and existing shared-spacing/Edit oracles |
| 5. Complete native interaction | Single-click expansion, concurrent editors, reset routing, areas, erase, visible/enable and Manual/live | `layers-first-acceptance`, `layers-native-clicks`, `layers-features` evidence |
| 6. Preserve output and navigation | Existing retained implementation and native engine unchanged; verify work counters in all four representations | 20k navigation, source/Bake/Edit and Scanline checks; no presented-FPS claim |
| 7. Fix MCP publication | Attach final policy/configuration before solving; inspect/checksum the actual final rows | Legacy transactions plus v2 matrix/footprint/digest campaign |
| 8. Expose qualified MCP settings | Closed shared registry, schema v2, exclusions, spacing, display, effective config; explicit unsupported capability entries | Python suite, nine-tool stdio and live v2 campaign |
| 9. Prepare ML records | Context/plan/receipt/layout/correction schemas, explicit units/provenance, no inferred labels or consent | Contract and export digest checks; no ML implementation claimed |
| 10. Package and document | Two version-specific MZPs, synthetic demo, offline MCP package, private installation and loaded-identity checks | See REPORT/evidence for exact completed runs and file identities |

## Deliberate limits, not silently implemented features

- Brush-constrained point Relax and shared Boundary Relax remain paused. A future implementation needs surface-constrained motion, mask/edge tests and stable Edit semantics before the guard can be removed.
- Multiple paint sets support Random/Clusters. Line Pattern/Analyzer assignment uses an independent layer until per-set source assignment has a qualified contract.
- MCP does not yet mutate paint sets/history, bind maps, run Relax, Bake, render or CS Edit, or accept arbitrary sloped/curved design sites. The local native tools remain available. Each extension needs scoped references, validation, rollback, parity and a truthful capability entry.
- Actual Max 2026 host operation, additional renderers, DPI settings and long artist sessions are release qualification gates. SDK/native tests and synthetic Max 2027 fixtures do not replace them.
- Adaptive point detail and extremely large scene guarantees remain the separate measured viewport roadmap. This change preserves existing retained paths; it does not introduce GPU computation or promise unlimited FPS.
- ML data collection, explicit correction capture/consent, train/test provenance and model quality evaluation are future work. Operational exports are not a training dataset.

## Reproduction order

Generate from `AminScatter/tools/ui/generate.cjs`; run native builds/tests with `tools/v1/build.py` for each SDK. Run Python tests in `build/mcp-venv`. Use `tools/v1/launch.py` and `request.py` only in private profiles. `layers_release_fixture.ms` covers existing group/output regressions, the new feature checks, navigation, ownership, demo and render. Reopen `layers-qualified.max` in a fresh profile with its `layers-reopen-expected.ms` and run `layers_reopen_fixture.ms`.

For MCP, build/install the offline package into a private build directory. Launch `tools/mcp/launch.py --host-package <installed-host>` for a private connection. Run each campaign serially: `qualify.py`, `layers_v2_acceptance.py`, `scenarios.py`, `stdio_acceptance.py`, `boundary_acceptance.py`, `retained_acceptance.py`, `inspection_acceptance.py`, `budget_acceptance.py`. Test-only controls are excluded from the shipped package. Keep loaded file hashes with results.

Failed experiments must remain identifiable as failed; rerun only after a relevant fix. Do not convert synchronous redraw time into an FPS claim. Do not publish a production-ready claim from the absence of errors in this bounded matrix.

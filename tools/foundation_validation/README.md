# Owned foundation validation

These scripts exercise current production publication and retained display in disposable Max hosts. Current Scatter 0.80.0 accepts scene schema 57 only. They never authorize an artist installation or release certification.

Build the native project using the documented SDK/toolchain, then launch an isolated matched host from the repository root:

```powershell
py -3.11 -B tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/foundation-native-unique
py -3.11 -B tools/foundation_validation/launch.py --native-build build/foundation-native-unique --name foundation-unique
py -3.11 -B tools/foundation_validation/run.py build/mcp-qualification/foundation-unique tools/foundation_validation/publication.py --timeout 120
py -3.11 -B tools/foundation_validation/run.py build/mcp-qualification/foundation-unique tools/foundation_validation/retained.py --timeout 90
```

Choose a fresh output/profile name. `launch.py` checks non-script compiled inputs and loaded module hashes. MAXScript is interpreted separately; its selected source hash is recorded. Native binaries from an older source are rejected. Only the returned owned process may be stopped afterward.

The schema-55/56 migration fixtures are [historical evidence](../../docs/plans/spline-bands/retired-fixtures/README.md). They are no longer active tests. Use `tools/spline_bands/geometry_units_host.py` for current physical-unit geometry checks and `authored_host.py` / `authoring_ui_host.py` for current-schema persistence; see the spline plan's validation matrix for remaining acceptance.

Run one request at a time per host. JSON result files record assertions and errors; transport request/response files record the actual invocation. Preserve a failed result before another run. `publication.py` loads a fault-instrumented copy only inside its owned profile; load current production source before an unrelated scenario. `retained.py` records any inherited redraw lock and repairs it only before its scenario, not during assertions. Neither constitutes physical mouse/tablet or renderer acceptance.

The [0.79.6 handoff](../../docs/Foundation_0.79.6_2026-10-12/README.md) remains historical evidence. [Spline progress](../../docs/plans/spline-bands/PROGRESS.md) records current scope and limitations.

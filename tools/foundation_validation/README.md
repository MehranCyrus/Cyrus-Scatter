# Owned foundation validation

These scripts exercise current production publication methods and schema-55/56 persistence in disposable Max hosts. They never authorize an artist installation or release certification.

Build the native project using the documented SDK/toolchain, then launch an isolated matched host from the repository root:

```powershell
py -3.11 -B tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/foundation-native-unique
py -3.11 -B tools/foundation_validation/launch.py --native-build build/foundation-native-unique --name foundation-unique
py -3.11 -B tools/foundation_validation/run.py build/mcp-qualification/foundation-unique tools/foundation_validation/publication.py --timeout 120
py -3.11 -B tools/foundation_validation/run.py build/mcp-qualification/foundation-unique tools/foundation_validation/retained.py --timeout 90
```

Choose a fresh output/profile name. `launch.py` checks non-script compiled inputs and loaded module hashes. MAXScript is interpreted separately; its selected source hash is recorded. Native binaries from an older source are rejected. Only the returned owned process may be stopped afterward.

For `units.py` and `units_guards.py`, copy an explicitly verified immediately preceding schema-55 generated script to the owned profile's `scripts/schema55.ms` and the current generated source to `scripts/schema56.ms`. The original 0.79.5 witness has SHA256 `cacf3e6b1af8796d96bca7ed2698cfb762d3baff7f90bc35a507b100ee0af4b4`. Do not download or substitute an arbitrary older build. Native schema compatibility still has to match the witness.

Run one request at a time per host. JSON result files record assertions and errors; transport request/response files record the actual invocation. Preserve a failed result before another run. `publication.py` loads a fault-instrumented copy only inside its owned profile; load current production source before an unrelated scenario. `retained.py` records any inherited redraw lock and repairs it only before its scenario, not during assertions. Neither constitutes physical mouse/tablet or renderer acceptance.

See the [portable handoff](../../docs/Foundation_0.79.6_2026-10-12/README.md) for exact tested scope and the retained units guard.

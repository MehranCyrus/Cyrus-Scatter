# Current spline Band validation

`source_conversion_undo.ms` runs native Undo/Redo phases for Make point/Pick object.
`ui_simplification_host.py` checks the corresponding handlers, Manual publication,
source registration, Band identity, Auto applicability, save/reopen and compact
Modify controls without pointer automation. Use a fresh owned
`foundation-spline-ui-simplification-*` host.

`ui_first_click_host.py` checks managed and native list/grip visibility on cold
Random mounts, mode transitions and remounts in both Scatter and source-container Modify views.
Physical first-click acceptance must additionally open the Layout header and
click Clusters/Spline bands in a fresh scene, before choosing Analyzer.
`compare_0795_host.py` creates equivalent fresh three-layer scenes in separately
matched historical/current hosts; it checks navigation, Manual/Live behavior and
same-version save/reload. Run comparison hosts serially. Its synchronous timings
are diagnostic measurements, not presented FPS or a release performance claim.

These tools last qualified source 0.81.2 / schema 58. They have not been run for
the 0.81.3 performance corrections, as requested by the user. The current implementation,
exact receipts and open acceptance gates are in
[PROGRESS](../../docs/plans/spline-bands/PROGRESS.md). Historical benchmark and
scene-migration sources are archived under `docs/plans/spline-bands/retired-fixtures`;
they are not current executables or compatibility support.

Use fresh owned output/profile directories. Build matching native modules with
`tools/procedural_lab/offline_build.py`, then launch through
`tools/foundation_validation/launch.py`. Its source and binary checks must pass.
Never run scene-reset fixtures in an artist session.

From the repository root, against an already ready, owned host:

```powershell
build/mcp-venv/Scripts/python.exe tools/spline_bands/qualify_host.py build/mcp-qualification/foundation-spline-YOUR-RUN
```

The full campaign runs native Undo events before Python fixtures, then field,
geometry, ownership, transport, UI, units, Auto Radius, retained display,
publication, captured-image and actual Scanline comparisons. Old-scene rejection
is last. `--scope authoring` runs the focused graph/ownership campaign and records
that narrower scope. Add `--performance` to the full campaign to include the
bounded host workload ladder before the last rejection fixture. Pillow is
required by the independent image verifiers.

`gpu_failure_host.py` requires the explicitly enabled private fault build, which
must never be packaged. `performance_host.py` measures primitive host workloads
and retained-resource invariants; synchronous redraw times are not presented FPS.

CPU cost measurements use only current field/generation interfaces:

```powershell
python tools/spline_bands/measure_costs.py --native-build build/YOUR-NATIVE-BUILD --kind generation --output build/YOUR-FRESH-COST-RUN
python tools/spline_bands/measure_costs.py --native-build build/YOUR-NATIVE-BUILD --kind field --output build/YOUR-FRESH-FIELD-RUN
```

`compare_costs.py` compares two preserved benchmark executables without compiling
or restoring old code. Read its recorded preparation/timing asymmetry before
interpreting speed differences. Do not relabel historical receipts after a tool
rename or source change.

`physical_ui_prepare.ms` creates disposable controls for pointer acceptance.
The two `physical_*_capture.py` files only read back the specific physical actions
described in their source; they do not automate those actions or establish a full
UI/DPI matrix. Preserve failed/interrupted receipts and inspect a timed-out host
before sending another request. Close only the verified owned process and check
the normal-profile hash.

`scale_curve_host.py` checks independent Band scale/Follow Density, actual graph buttons, Manual retention, relevant Live updates, unrelated-edit stability, analytic size and radii, invalid-successor retention and saved/captured ownership. `scale_curve_undo.ms` must run each phase in a separate native event outside pymxs holds. Use fresh `foundation-spline-scale-*` profiles.

`retired_scale_scene_host.py` reads the preserved schema-57 source-conversion witness, verifies persistent rejection under schema 58 and rechecks the original bytes. It never saves that witness.

`band_selection_host.py` verifies click-to-toggle control policy, empty model/Point/group assignments, both Modify views, basic scale layout, Manual retention, copy and save/reopen. `band_selection_undo.ms` runs prepare/clear/undo/redo/refresh as separate native events in a disposable host.

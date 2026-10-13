# Historical fixtures only

These files were removed from active tooling during the current-only 0.80.0 cleanup. They are byte-preserved evidence, not current executable tests or compatibility support. `identities.json` records each original path and SHA256. Their original root calculations, build paths and API assumptions deliberately remain unchanged; do not run them from this archive.

- `CompareViewport.ms`, `test_viewport_performance.py` and `viewport_performance_smoke.ms` targeted the removed expanded-triangle batching implementation.
- `units.py` and `units_guards.py` qualified the retired schema-55 to schema-56 migration. The current product accepts only schema 57.
- `capture_schema56.py` produced the old-scene witness before the user removed migration requirements. That original scene is now used only to verify rejection without altering its bytes.
- `baseline_benchmark.cpp` measured the removed inline `LineBand` sampler before implementation. Comparisons run its preserved executable; current cost tooling never compiles that retired recipe.

Current checks use `tools/spline_bands/qualify_host.py`, `palette_host.py`, `palette_capture_host.py`, `verify_palette_images.py`, `source_revision_host.py`, `geometry_units_host.py`, and the production publication/retained fixtures in `tools/foundation_validation`. Run them only in a matched, explicitly owned host as described in that directory's README. Current geometry-unit checks do not replace full save/merge/rescale acceptance.

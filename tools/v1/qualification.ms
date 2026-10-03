-- Serial campaign against one disposable host with frozen product files.
for fixture in #("native_panel_fixture.ms","brush_fixture.ms","cache_and_copy_fixture.ms","curved_and_edit_fixture.ms","output_and_restore_fixture.ms") do fileIn (BLRoot+"tools/v1/"+fixture)

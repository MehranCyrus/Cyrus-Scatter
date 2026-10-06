(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/common.ms"
 RSReload()
 local baseline=RSRows(),h=(cyrusBrushHistory RSFlowers.paintDocument)[1]
 cyrusBrushStroke RSFlowers.paintDocument 1 false h[4] h[3] h[5] h[2]
 RSRoot.refreshAll();local disabled=RSRows()
 RSAssert (disabled[4].count<baseline[4].count) "Disabling a saved stroke did not change flowers"
 cyrusBrushStroke RSFlowers.paintDocument 1 true .6 180 .15 false
 RSRoot.refreshAll();local resized=RSRows()
 RSAssert (not(RSEqual baseline resized)) "Editing saved stroke size/strength/softness had no effect"
 cyrusBrushStroke RSFlowers.paintDocument 1 h[1] h[4] h[3] h[5] h[2]
 cyrusBrushFill RSFlowers.paintDocument 1.0;RSRoot.refreshAll();local filled=RSRows()
 RSAssert (filled[4].count>baseline[4].count and filled[5].count==0) "Full foreground coverage did not exclude the referenced background"
 RSAssert ((cyrusBrushHistory RSFlowers.paintDocument).count==0) "Fill did not reset stroke history"
 max undo;RSRoot.refreshAll()
 RSAssert (RSEqual baseline (RSRows())) "Undo Fill did not restore saved strokes and output"
 cyrusBrushFill RSFlowers.paintDocument 0.0;RSRoot.refreshAll()
 RSAssert ((RSRows())[4].count==0) "Empty did not clear painted coverage"
 max undo;RSRoot.refreshAll()
 RSAssert (RSEqual baseline (RSRows())) "Restoring Brush base/history changed seeded rows"
 local meshes=for n in RSOwners[3].sources collect #(n.name,(snapshotAsMesh n).numfaces)
 for row in meshes do RSAssert (row[2]>100) "Proxy source did not expose detailed geometry"
 CSPWriteText (MCPFixtureDir+"brush-history.json") (CSPObject #(#("passed",true),#("original_disabled_edited_filled_flower_counts",#(baseline[4].count,disabled[4].count,resized[4].count,filled[4].count)),#("full_coverage_background_count",filled[5].count),#("proxy_mesh_faces",meshes)))
)

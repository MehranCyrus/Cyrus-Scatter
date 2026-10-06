(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/common.ms"
 RSReload();local before=RSRows(),flower=RSRoot.layerObjects[7],history=cyrusBrushHistory flower.paintDocument
 RSAssert (history.count==1 and history[1][6]>50) "Flower border is not a continuous saved stroke"
 local h=history[1]
 cyrusBrushStroke flower.paintDocument 1 false h[4] h[3] h[5] h[2]
 RSRoot.refreshAll();RSAssert ((RSRows())[7].count==0) "Disabling the border did not remove its flowers"
 max undo;RSRoot.refreshAll();RSAssert (RSEqual before (RSRows())) "Undo did not restore the flower border"
 cyrusBrushStroke flower.paintDocument 1 true h[4] 52 h[5] h[2]
 RSRoot.refreshAll();local resized=(RSRows())[7].count
 RSAssert (not(RSEqual before (RSRows()))) "Changing the border width had no effect"
 max undo;RSRoot.refreshAll();RSAssert (RSEqual before (RSRows())) "Undo border width did not restore publication"
 history=cyrusBrushHistory RSGrass.paintDocument;h=history[history.count]
 cyrusBrushStroke RSGrass.paintDocument history.count false h[4] h[3] h[5] h[2]
 RSRoot.refreshAll();local grassRestored=(RSRows())[6].count
 RSAssert (grassRestored>before[6].count) "Disabling the trail erase did not restore grass"
 max undo;RSRoot.refreshAll();RSAssert (RSEqual before (RSRows())) "Undo trail erase did not restore publication"
 local curb=for n in objects where matchPattern n.name pattern:"Garden end curb*" and abs(n.pos.y+1067)<1 collect n
 RSAssert (curb.count==1) "Expected the original south garden curb"
 local base=curb[1]
 for segment in #(#(-1507,-1130),#(-970,-163),#(163,1507)) do (
  local n=copy base;n.name="South curb | opening at walking routes";n.width=segment[2]-segment[1];n.pos.x=(segment[1]+segment[2])/2
 )
 -- Retain the generated original as a hidden, non-rendering design reference.
 base.renderable=false;base.isHidden=true;base.name="Design reference | original south curb"
 viewport.setCamera (getNodeByName "01 HERO | garden pavilion");RSRoot.setGroupDisplay 1
 RSRoot.refreshAll();RSAssert (RSEqual before (RSRows())) "Curb edits altered Scatter output"
 renderWidth=1400;renderHeight=980;renderers.current.progressive_passLimit=24;renderers.current.progressive_timeLimit=0
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 RSReload();RSAssert (RSEqual before (RSRows())) "Final painted trail did not roundtrip"
 CSPWriteText (MCPFixtureDir+"path-acceptance.json") (CSPObject #(#("passed",true),#("flower_count_before_wider",#(before[7].count,resized)),#("grass_count_before_erase_disabled",#(before[6].count,grassRestored)),#("undo_restored_exact",true),#("save_reopen_exact",true),#("counts",for r in before collect r.count)))
)

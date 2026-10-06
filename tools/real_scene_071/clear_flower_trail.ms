-- Offset border strokes may approach another segment of a tight S-bend.
-- A final centerline erase explicitly reserves the entire walking corridor.
(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/common.ms"
 RSReload()
 local file=openFile (MCPFixtureDir+"curved-path.csv"),samples=#()
 readLine file
 while not eof file do (
  local line=filterString (readLine file) ","
  if line.count==2 do append samples [line[1] as float,line[2] as float,700]
 )
 close file
 for index in #(7,8) do (
  local leaf=RSRoot.layerObjects[index]
  RSAssert ((cyrusBrushHistory leaf.paintDocument).count==1) "Apply corridor erase once to the original flower stroke"
  cyrusBrushSettings leaf.paintDocument 104 1 0 true 1;cyrusBrushBind leaf.paintDocument
  for i=1 to samples.count do RSAssert (cyrusBrushDab leaf.paintDocument samples[i] [0,0,-1] (i==samples.count)) "Corridor erase missed"
 )
 RSRoot.refreshAll();RSRoot.evaluateGroups();local before=RSRows()
 for leaf in RSRoot.layerObjects do RSAssert ((leaf.cacheSnapshot())[4]=="") (leaf.cacheSnapshot())[4]
 viewport.setCamera (getNodeByName "01 HERO | garden pavilion");RSRoot.setGroupDisplay 1
 renderWidth=1400;renderHeight=980;renderers.current.progressive_passLimit=24;renderers.current.progressive_timeLimit=0
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 RSReload();RSAssert (RSEqual before (RSRows())) "Border erase did not roundtrip"
 CSPWriteText (MCPFixtureDir+"flower-corridor.json") (CSPObject #(#("passed",true),#("counts",for rows in before collect rows.count),#("histories",for index in #(7,8) collect cyrusBrushHistory RSRoot.layerObjects[index].paintDocument),#("save_reopen_exact",true)))
)

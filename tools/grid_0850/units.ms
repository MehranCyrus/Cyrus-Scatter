(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-grid0850-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"units-"+(timeStamp() as string)+".txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  if theHold.Holding() do theHold.Cancel()
  if CyrusRecipeBrowser!=undefined do CyrusRecipeBrowser.closeButton.pressed()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  units.SystemType=#meters;units.SystemScale=1
  local terrain=plane width:20 length:20 widthsegs:4 lengthsegs:4,root=(AminScatterObject name:"Grid units").baseObject
  root.updateMode=1;root.autoRender=false;root.newLayer();local leaf=root.selectedLayer()
  root.setLayerSurfaces leaf #(terrain);leaf.addPointSource();leaf.placementMode=2
  leaf.gridColumnWU=3;leaf.gridRowWU=4;leaf.gridOriginXWU=1;leaf.gridOriginYWU=2;leaf.gridHeading=12;leaf.gridJitter=20
  leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false;root.refreshAll()
  local before=deepCopy root.groupSnapshotRows[1],doc=CyrusRecipeCapture root #(leaf) "Grid units",bindings=CyrusRecipeSuggestBindings root doc
  local preset=#("population","Grid numeric units",CyrusPresetCapture (CyrusPresetMakeBinding root leaf "population"))
  units.SystemType=#centimeters;units.SystemScale=1
  local replacement=plane width:2000 length:2000 widthsegs:4 lengthsegs:4
  for pair in bindings where pair[2]==terrain do pair[2]=replacement
  local imported=CyrusRecipeImport root doc bindings newSetup:true variation:#same,other=imported[2][1]
  check (abs(other.gridColumnWU-300)<0.001 and abs(other.gridRowWU-400)<0.001 and abs(other.gridOriginXWU-100)<0.001 and abs(other.gridOriginYWU-200)<0.001) "Recipe converts all four grid distances from metres to centimetres" log
  imported[1].refreshAll();local after=imported[1].groupSnapshotRows[1]
  check (before.count==after.count and before.count>0) "Unit-equivalent terrain retains projected grid population" log
  for i=1 to before.count do (
   check (before[i][3]==after[i][3] and before[i][2]==after[i][2] and distance (before[i][1].row4*100) after[i][1].row4<0.01) "Unit conversion preserves stable cells and scales world positions exactly within float tolerance" log
  )
  other.gridColumnWU=50;other.gridRowWU=60;other.gridOriginXWU=10;other.gridOriginYWU=20
  CyrusPresetApply (CyrusPresetMakeBinding imported[1] other "population") preset
  check (abs(other.gridColumnWU-300)<0.001 and abs(other.gridRowWU-400)<0.001 and abs(other.gridOriginXWU-100)<0.001 and abs(other.gridOriginYWU-200)<0.001) "Numeric Population preset uses metre-based grid distances" log
  format "PASS: complete\n" to:log;close log;CyrusPerfHeadless=false
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;flush log;close log;throw())
)

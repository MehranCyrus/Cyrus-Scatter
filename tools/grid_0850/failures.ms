(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-grid0850-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"failures-"+(timeStamp() as string)+".txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  local terrain,root,a,b
  undo off (
   units.SystemType=#meters;units.SystemScale=1
   terrain=plane width:20 length:20 widthsegs:1 lengthsegs:1
   root=(AminScatterObject name:"Grid failure retention").baseObject;root.updateMode=1;root.autoRender=false
   root.newLayer();a=root.selectedLayer();root.setLayerSurfaces a #(terrain);a.addPointSource()
   a.placementMode=2;a.gridColumnWU=5;a.gridRowWU=5;a.procSelfOverride=true;a.procSelfEnabled=false;a.procLayerSelfEnabled=false
   b=root.copyLogicalLayer a variation:#same;root.refreshAll()
  )
  local before=for rows in root.groupSnapshotRows collect deepCopy rows,epoch=root.procEpoch
  a.gridColumnWU=0.026;a.gridRowWU=0.026;b.gridColumnWU=0.026;b.gridRowWU=0.026
  root.refreshAll()
  check (root.procEpoch==epoch and (a.previewError!="" or b.previewError!="") and equalRows before[1] root.groupSnapshotRows[1] and equalRows before[2] root.groupSnapshotRows[2]) "Two individually bounded grids cannot exceed the shared million-cell admission; all previous layers retained" log
  a.gridColumnWU=5;a.gridRowWU=5;b.gridColumnWU=5;b.gridRowWU=5;root.refreshAll()
  check (equalRows before[1] root.groupSnapshotRows[1] and equalRows before[2] root.groupSnapshotRows[2]) "Recovery after shared grid admission failure is exact" log
  epoch=root.procEpoch;a.distributionMode=3;a.densityMap=checker color1:white color2:white;a.densityUVChannel=99;root.refreshAll()
  check (root.procEpoch==epoch and a.previewError!="" and equalRows before[1] root.groupSnapshotRows[1] and equalRows before[2] root.groupSnapshotRows[2]) "Missing UV mapping on grid receiver fails before replacing any publication" log
  a.distributionMode=1;a.densityUVChannel=1;root.refreshAll()
  convertToMesh terrain
  local savedVerts=for i=1 to terrain.numverts collect getVert terrain i
  for i=1 to terrain.numverts do (local p=getVert terrain i;setVert terrain i [p.x,0,p.y]);update terrain
  epoch=root.procEpoch;root.refreshAll()
  check (root.procEpoch==epoch and a.previewError!="" and equalRows before[1] root.groupSnapshotRows[1]) "A wholly vertical receiver reports unsupported projection and retains the previous result" log
  for i=1 to terrain.numverts do setVert terrain i savedVerts[i];update terrain;root.refreshAll()
  check (equalRows before[1] root.groupSnapshotRows[1] and equalRows before[2] root.groupSnapshotRows[2]) "Recovering valid terrain restores exact rows" log
  format "PASS: complete\n" to:log;close log;CyrusPerfHeadless=false
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;flush log;close log;throw())
)

-- Serialized native events qualify Live import and subsequent dependency updates.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
 global RecipeLiveStage,RecipeLiveRoot,RecipeLiveNode,RecipeLiveEpoch,RecipeLiveRows,RecipeLiveTimer,RecipeLiveTick,RecipeLiveSeen,RecipeLiveStable,RecipeLiveArm
 if RecipeLiveStage==undefined or RecipeLiveStage>=5 do RecipeLiveStage=0
 fn RecipeLiveTick sender args = (
  local epoch=RecipeLiveRoot.procEpoch
  if epoch==RecipeLiveSeen and not CyrusPointPending and not CyrusPointBusy then RecipeLiveStable+=1 else RecipeLiveStable=0
  RecipeLiveSeen=epoch
  if RecipeLiveStable>=10 do (RecipeLiveTimer.Stop();(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-live-ready.txt") (epoch as string))
 )
 fn RecipeLiveArm = (
  try(RecipeLiveTimer.Stop();RecipeLiveTimer.Dispose())catch()
  deleteFile (MCPFixtureDir+"recipe-live-ready.txt");RecipeLiveStable=0;RecipeLiveSeen=RecipeLiveRoot.procEpoch
  RecipeLiveTimer=dotNetObject "System.Windows.Forms.Timer";RecipeLiveTimer.Interval=100
  dotNet.addEventHandler RecipeLiveTimer "Tick" RecipeLiveTick;RecipeLiveTimer.Start()
 )
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn rows root = (deepCopy root.groupSnapshotRows)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do (if a[i].count!=b[i].count do return false;for j=1 to a[i].count do (if a[i][j].count!=b[i][j].count do return false;for k=1 to a[i][j].count where a[i][j][k]!=b[i][j][k] do return false));true)
 local stage=RecipeLiveStage+1,log=if stage==1 then createFile (MCPFixtureDir+"recipe-live.txt") else openFile (MCPFixtureDir+"recipe-live.txt") mode:"a"
 try (
  case stage of (
   1:(
    if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
    loadMaxFile (MCPFixtureDir+"recipe-qualified.max") quiet:true useFileUnits:true
    RecipeLiveNode=getNodeByName "Recipe 0.82.5 source";RecipeLiveRoot=RecipeLiveNode.baseObject
    CyrusPerfHeadless=false;select RecipeLiveNode;max modify mode;modPanel.setCurrentObject RecipeLiveRoot
    RecipeLiveRoot.updateMode=2;CyrusViewportRedraw();RecipeLiveArm()
   )
   2:(
    RecipeLiveEpoch=RecipeLiveRoot.procEpoch;RecipeLiveRows=rows RecipeLiveRoot
    local document=CyrusRecipeCapture RecipeLiveRoot (for i=1 to 3 collect RecipeLiveRoot.layerObjects[i]) "Live recipe"
    local bindings=CyrusRecipeSuggestBindings RecipeLiveRoot document
    verify (RecipeLiveRoot.procEpoch==RecipeLiveEpoch) "Live capture does not solve" log
    CyrusRecipeImport RecipeLiveRoot document bindings;RecipeLiveArm()
   )
   3:(
    verify (RecipeLiveRoot.layerObjects.count==9 and RecipeLiveRoot.procEpoch==RecipeLiveEpoch+1) "Live Add publishes exactly one complete successor" log
    local current=rows RecipeLiveRoot
    verify (equalRows (for i=1 to 6 collect current[i]) RecipeLiveRows) "Live Add preserves independent existing full placements" log
    verify (RecipeLiveRoot.groupSnapshotRows[7].count>0 and RecipeLiveRoot.groupSnapshotRows[8].count>0 and RecipeLiveRoot.groupSnapshotRows[9].count>0) "All imported Live layers publish" log
    RecipeLiveEpoch=RecipeLiveRoot.procEpoch;RecipeLiveRows=rows RecipeLiveRoot
    local unrelated=box name:"Unrelated recipe probe";unrelated.pos=[100,100,100];sliderTime=17f;select unrelated
    RecipeLiveArm()
   )
   4:(
    verify (RecipeLiveRoot.procEpoch==RecipeLiveEpoch and equalRows (rows RecipeLiveRoot) RecipeLiveRows) "Unrelated scene edits, selection and time do not rebuild static recipes" log
    RecipeLiveRoot.layerObjects[7].amount+=100;RecipeLiveRoot.layerObjects[7].markInputDirty();CyrusViewportRedraw();RecipeLiveArm()
   )
   5:(
    verify (RecipeLiveRoot.procEpoch==RecipeLiveEpoch+1) "Relevant imported parameter edit publishes one Live successor" log
    verify (not (equalRows #((rows RecipeLiveRoot)[7]) #(RecipeLiveRows[7]))) "Relevant edit changes imported placements" log
    verify (not theHold.Holding()) "Native Live commands leave no stranded hold" log
    format "PASSED\n" to:log
   )
  )
  RecipeLiveStage=stage;close log
 )catch(format "FAILED: %\n" (getCurrentException()) to:log;close log;throw())
)

-- Actual asset scene checks. Every case records its evidence; failure is not a pass.
(
 global RSChecks=#(),RSBaseRows
 fn RSAssert condition description = (if not condition do throw description;true)
 fn RSRecord label evidence = (
  append RSChecks #(label,evidence)
  CSPWriteText (MCPFixtureDir+"campaign.json") (CSPObject #(#("checks",RSChecks),#("complete",false)))
 )
 fn RSRows = (for leaf in RSRoot.layerObjects collect (leaf.placements (leaf.outputSources())))
 fn RSEqual aa bb tolerance:0.0001 = (
  if aa.count!=bb.count do return false
  for i=1 to aa.count do (
   if aa[i].count!=bb[i].count do return false
   for j=1 to aa[i].count do (
    if aa[i][j][2]!=bb[i][j][2] or aa[i][j][3]!=bb[i][j][3] do return false
    for k=1 to 4 where distance aa[i][j][1][k] bb[i][j][1][k]>tolerance do return false
   )
  );true
 )
 fn RSExport filename = (
  local f=createFile filename
  format "set,owner,instance,source,x,y,z,radius,sx,sy,sz\n" to:f
  for i=1 to RSRoot.layerObjects.count do (
   local leaf=RSRoot.layerObjects[i],sources=leaf.outputSources(),rows=leaf.placements sources,radii=leaf.procRadii rows sources
   local owner=findItem RSOwners (RSRoot.logicalParent leaf)
   for j=1 to rows.count do (
    local r=rows[j],p=r[1].row4
    format "%,%,%,%,%,%,%,%,%,%,%\n" i owner r[3] sources[r[2]].name p.x p.y p.z radii[j] (length r[1].row1) (length r[1].row2) (length r[1].row3) to:f
   )
  );close f
 )
 RSRoot.updateMode=1;RSRoot.refreshAll();RSBaseRows=RSRows()
 local epoch=RSRoot.procEpoch,prepared=for leaf in RSRoot.layerObjects collect leaf.procPreparedBuilds
 for repeat=1 to 3 do (RSRoot.evaluateGroups();for leaf in RSRoot.layerObjects do leaf.cacheSnapshot())
 RSAssert (RSRoot.procEpoch==epoch and (for leaf in RSRoot.layerObjects collect leaf.procPreparedBuilds) as string==prepared as string) "Warm consumers recalculated placements"
 RSRecord "Exact output, statistics and warm cache" #(for rows in RSBaseRows collect rows.count)
 RSExport (MCPFixtureDir+"published-placements.csv")
 -- Real-model parking preserves settings, IDs and the previous Manual publication.
 local grassSource=RSGrass.sources[1],oldPos=grassSource.pos,settings=#(RSGrass.sourceWeights as array,RSGrass.sourceScales as array,RSGrass.sourceRadii as array,RSGrass.procSourceIDs as array)
 grassSource.pos+= [2000,0,0];RSGrass.containerScan=true;RSGrass.containerRefresh()
 RSAssert (RSEqual RSBaseRows (RSRows())) "Manual parking changed the exact published result"
 RSRoot.refreshAll();local parked=RSRows()
 RSAssert (parked[6].count<RSBaseRows[6].count and parked[6].count>0) "Parking did not suppress one real grass source"
 RSAssert (settings as string==#(RSGrass.sourceWeights as array,RSGrass.sourceScales as array,RSGrass.sourceRadii as array,RSGrass.procSourceIDs as array) as string) "Parking damaged per-model settings"
 grassSource.pos=oldPos;RSGrass.containerScan=true;RSRoot.refreshAll()
 RSAssert (RSEqual RSBaseRows (RSRows())) "Re-entering did not restore original placements/identities"
 RSRecord "Source container parking and re-entry" #(RSBaseRows[6].count,parked[6].count,(RSRows())[6].count,"Manual held exact output; model settings and IDs preserved")
 -- Undo/Redo of authored Brush coverage on the actual curved receiver.
 local leaf=RSOwners[2],before=RSRows()
 undo "Real-scene Brush erase" on (
  cyrusBrushSettings leaf.paintDocument 190 1 0 true 1
  RSAssert (cyrusBrushDab leaf.paintDocument [1090,410,700] [0,0,-1] true) "Curved Brush ray missed"
 )
 RSRoot.refreshAll();local erased=RSRows()
 RSAssert (not(RSEqual before erased)) "Erase had no effect on actual curved planting"
 max undo;RSRoot.refreshAll();RSAssert (RSEqual before (RSRows())) "Brush Undo did not restore exact rows"
 max redo;RSRoot.refreshAll();RSAssert (RSEqual erased (RSRows())) "Brush Redo differs"
 max undo;RSRoot.refreshAll()
 RSRecord "Curved Brush, erase, Undo and Redo" #(before[2].count,erased[2].count,"exact identities and transforms restored")
 -- Manual commits and Live evaluation use the same rule fields.
 local oldGap=RSOwners[1].procSelfGap
 RSOwners[1].procSelfGap=5000
 RSAssert (RSEqual RSBaseRows (RSRows())) "Manual spacing escaped the pending state"
 RSRoot.updateMode=2
 local live=RSRows()
 RSAssert (live[1].count<=1) "Live spacing did not evaluate committed fields"
 RSOwners[1].procSelfGap=oldGap;RSRoot.refreshAll()
 RSAssert (RSEqual RSBaseRows (RSRows())) "Restoring spacing changed seeded results"
 RSRoot.updateMode=1
 RSRecord "Manual and Live spacing" #(live[1].count,"no Apply spacing step; restored seeded output")
 -- Invalid successor must not replace the last completed publication.
 local validRadii=RSOwners[1].sourceRadii as array,oldEpoch=RSRoot.procEpoch
 RSOwners[1].sourceRadii=#(-1.0);RSRoot.updateMode=2
 local rejected=false;try(RSRoot.evaluateGroups())catch(rejected=true)
 RSAssert (rejected and RSRoot.procEpoch==oldEpoch) "Invalid radius published a successor"
 RSOwners[1].sourceRadii=validRadii;RSRoot.updateMode=1;RSRoot.refreshAll()
 RSAssert (RSEqual RSBaseRows (RSRows())) "Failed update corrupted completed rows"
 RSRecord "Atomic failure preservation" "Invalid radius rejected; epoch and seeded publication preserved"
 -- Display adapters and real UI navigation may refresh display, never placement.
 local nav=#(),cam=getNodeByName "01 HERO | garden pavilion",oldEye=cam.pos
 for mode in #(1,2,3,4) do (
  RSRoot.setGroupDisplay mode
  for warm=1 to 3 do (completeRedraw();windows.processPostedMessages())
  local view=CyrusPointOwner RSNode,stats=cyrusRetainedStats view,epoch=RSRoot.procEpoch
  local prepared=for l in RSRoot.layerObjects collect l.procPreparedBuilds,times=#()
  for step=1 to 12 do (
   local begin=timeStamp();cam.pos=oldEye+[30*sin(step*30),0,0];completeRedraw();windows.processPostedMessages();append times (timeStamp()-begin)
  )
  local now=cyrusRetainedStats view
  for k in #(3,4,5,6,7,9) do RSAssert (stats[k]==now[k]) "Navigation re-uploaded unchanged retained buffers"
  RSAssert (epoch==RSRoot.procEpoch and prepared as string==(for l in RSRoot.layerObjects collect l.procPreparedBuilds) as string) "Navigation recalculated placements"
  append nav #(mode,times,stats,now,cyrusRetainedMeshStats view)
 )
 cam.pos=oldEye;RSRoot.setGroupDisplay 1
 CSPWriteText (MCPFixtureDir+"navigation.json") (CSPObject #(#("trials",nav),#("metric","synchronous camera/redraw/message processing in milliseconds; not presented FPS")))
 local key=RSRoot.procInputKey(),epoch=RSRoot.procEpoch
 for owner in RSOwners do (
  CyrusOpenLayerEditor RSRoot owner
  for topic=1 to 6 do CyrusLayerEditor.showTopic topic
 )
 RSAssert (RSRoot.procInputKey()==key and RSRoot.procEpoch==epoch) "Editor browsing changed generation"
 CyrusCloseLayerEditor()
 RSRecord "Four preview modes, camera motion and six editor tabs" "No placement rebuild or unchanged retained-buffer upload during navigation; no placement invalidation during editor browsing"
 -- Native render adapter must preserve the exact population and transforms.
 CyrusPFTimer.Stop()
 try (
  RSAssert (CyrusPFBuild()) CyrusPFLastError
  local count=0;for rows in CyrusPFData do count+=rows.count
  local expected=0;for rows in RSBaseRows do expected+=rows.count
  RSAssert (count==expected) "PFlow population differs from exact output"
  RSRecord "Automatic render adapter with Corona proxies" #(count,CyrusPFData.count,"all source groups evaluated by PFlow")
  CyrusPFClear()
 )catch(CyrusPFTimer.Start();throw())
 CyrusPFTimer.Start()
 -- Native instance Bake checks material/source linkage and every matrix row.
 leaf=RSOwners[2]
 local sources=leaf.outputSources(),exact=leaf.placements sources
 leaf.bakeInstances RSNode
 RSAssert (leaf.bakedNodes.count==exact.count) "Bake count differs"
 local worst=0.0
 for i=1 to exact.count do (
  RSAssert (leaf.bakedNodes[i].baseObject==sources[exact[i][2]].baseObject) "Baked wrong source"
  for k=1 to 4 do worst=amax worst (distance leaf.bakedNodes[i].transform[k] exact[i][1][k])
 )
 RSAssert (worst<0.0001) "Bake transform error exceeds tolerance"
 leaf.clearBaked RSNode;leaf.showPoints=true;leaf.autoRender=true
 RSRecord "Bake and owned clear" #(exact.count,worst)
 RSRoot.refreshAll();RSAssert (RSEqual RSBaseRows (RSRows())) "Campaign changed main planting"
 RSExport (MCPFixtureDir+"published-placements-after.csv")
 CSPWriteText (MCPFixtureDir+"campaign.json") (CSPObject #(#("checks",RSChecks),#("complete",true)))
)

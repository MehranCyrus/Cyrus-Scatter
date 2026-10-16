(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"masks-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 fn setMaskChannel node = (
  convertToMesh node
  meshop.setNumMaps node 3 keep:true;meshop.setMapSupport node 2 true
  meshop.setNumMapVerts node 2 node.numverts;meshop.setNumMapFaces node 2 node.numfaces
  for i=1 to node.numverts do (local p=in coordsys local (getVert node i);meshop.setMapVert node 2 i [(p.x+50)/100.0,0,0])
  for i=1 to node.numfaces do meshop.setMapFace node 2 i (getFace node i)
  update node
 )
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  local root,leaf,a,b,model1,model2
  undo off (
   units.SystemType=#meters;units.SystemScale=1
   a=plane name:"Mask receiver A" width:100 length:100 widthsegs:10 lengthsegs:10;setMaskChannel a;rotate a (eulerAngles 10 0 0)
   b=plane name:"Mask receiver B" width:100 length:100 widthsegs:10 lengthsegs:10 pos:[130,0,10];setMaskChannel b;rotate b (eulerAngles 25 0 0)
   model1=pyramid name:"Mask pyramid" width:1 depth:2 height:5 pos:[-200,0,0]
   model2=box name:"Mask box" width:2 length:3 height:1 pos:[-200,10,0]
   root=(AminScatterObject name:"Variation masks").baseObject;root.updateMode=1;root.autoRender=false;root.newLayer();leaf=root.selectedLayer()
   root.setLayerSurfaces leaf #(a,b);leaf.sources=#(model1,model2);leaf.ensureSourceRows();leaf.sourceWeights=#(0.35,0.65)
   leaf.amount=4000;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
   leaf.slopeEnabled=true;leaf.slopeMinimum=0;leaf.slopeMaximum=35;leaf.slopeUpperFade=20
   leaf.altitudeEnabled=true;leaf.altitudeMinimum=-20;leaf.altitudeMaximum=40;leaf.altitudeUpperFade=30
   leaf.meshMaskEnabled=true;leaf.meshMaskChannel=2;leaf.meshMaskComponent=1
   root.refreshAll()
  )
  local baseline=deepCopy root.groupSnapshotRows[1]
  check (baseline.count>0 and baseline.count<2000) "Mesh, slope and altitude masks produce a nonempty filtered population" log
  check ((for row in baseline where row[1].row4.x<60 collect row).count>0 and (for row in baseline where row[1].row4.x>60 collect row).count>0) "Both stochastic receiver filters contribute surviving rows" log
  local copied=root.copyLogicalLayer leaf variation:#same;root.refreshAll()
  check (equalRows baseline root.groupSnapshotRows[2]) "Same variation preserves complete mesh/slope/altitude acceptance" log
  local document=CyrusRecipeCapture root #(leaf) "Masks",bindings=CyrusRecipeSuggestBindings root document
  local imported=CyrusRecipeImport root document bindings newSetup:true variation:#same
  imported[1].refreshAll();check (equalRows baseline imported[1].groupSnapshotRows[1]) "Saved import preserves complete masked placement rows" log
  -- Exercise different explicit bindings with identical evaluated geometry.
  local receiverCopies=#(copy a,copy b)
  for pair in bindings do (if pair[2]==a do pair[2]=receiverCopies[1];if pair[2]==b do pair[2]=receiverCopies[2])
  local rebound=CyrusRecipeImport root document bindings newSetup:true variation:#same
  rebound[1].refreshAll();check (equalRows baseline rebound[1].groupSnapshotRows[1]) "Saved variation reproduces on distinct compatible receiver objects" log
  -- A single domain edit is local to that receiver's candidate cache.
  local oldBuilds=(leaf.receiverCacheStats())[1],oldA=for row in baseline where row[1].row4.x<60 collect row,oldB=for row in baseline where row[1].row4.x>60 collect row
  local savedDomains=leaf.procReceiverVariationIDs as array
  leaf.procReceiverVariationIDs[2]=CyrusNewLayerID();root.refreshAll()
  local now=root.groupSnapshotRows[1],newA=for row in now where row[1].row4.x<60 collect row,newB=for row in now where row[1].row4.x>60 collect row
  check ((leaf.receiverCacheStats())[1]==oldBuilds+1 and equalRows oldA newA and not equalRows oldB newB) "Changing one domain rebuilds only its receiver and preserves all other rows" log
  leaf.procReceiverVariationIDs=savedDomains;root.refreshAll();check (equalRows baseline root.groupSnapshotRows[1]) "Restoring domains recovers the exact masked arrangement" log
  -- Variations promise identical inputs, not source-reordering invariance.
  leaf.meshMaskEnabled=false;leaf.slopeEnabled=false;leaf.altitudeEnabled=false;leaf.sourceWeights=#(1.0,0.0)
  root.refreshAll();check ((for row in root.groupSnapshotRows[1] where row[2]!=1 collect row).count==0) "Zero weight source is never selected" log
  local zeroCopy=root.copyLogicalLayer leaf variation:#same;root.refreshAll()
  check (equalRows root.groupSnapshotRows[1] root.groupSnapshotRows[3]) "Same copy preserves zero-weight source choices" log
  leaf.relaxEnabled=true;leaf.relaxSpacing=2;leaf.relaxIterations=2;leaf.relaxStrength=0.5
  local relaxed=root.copyLogicalLayer leaf variation:#same;root.refreshAll()
  check (equalRows root.groupSnapshotRows[1] root.groupSnapshotRows[4]) "Same variation retains deterministic Relax result for identical inputs" log
  check (not theHold.Holding()) "No stranded mask transaction" log
  CyrusPerfHeadless=false;CyrusPointSync();format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)

-- Library geometry plus Points, multiple receiver types and target lifecycle.
(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-*-2027/" do throw "Owned clearance host required"
 local log=createFile (MCPFixtureDir+"real-models.txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn fingerprint root = cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("real-models") #()
 try (
  resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
  units.SystemType=#centimeters;units.SystemScale=1
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  catalog.Load @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library" "0.86.7" 2027
  local entry=catalog.MatchingAt "A027" "" 0
  local node=AminScatterObject name:"Leaf clearance showcase",root=node.baseObject
  root.updateMode=1;root.autoRender=false;root.newLayer()
  local leaf=root.selectedLayer(),source=CyrusModelMerge catalog entry owner:leaf
  check (isValidNode source and source.material!=undefined and source.numfaces>0) "Real A027 leaf imports with geometry and material" log
  local surface=plane name:"Leaf plane" width:70 length:70 widthsegs:3 lengthsegs:3
  local curved=sphere name:"Curved receiver" radius:20 pos:[90,0,0]
  local boxSurface=box name:"Box receiver" width:35 length:35 height:30 pos:[-90,0,0]
  root.setLayerSurfaces leaf #(surface,curved,boxSurface)
  leaf.amount=120;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
  leaf.setSourceRadius #{1} 5
  leaf.setSourceClearance #{1} #clearanceOthers 2
  leaf.setSourceClearance #{1} #clearanceExternal 3
  leaf.setSourceClearance #{1} #clearancePreferred true
  root.newLayer();local filler=root.selectedLayer()
  check ((filler.validSurfaces()).count==3) "New layer inherits all selected-layer receivers" log
  filler.amount=160;filler.addPointSource();filler.setSourceRadius #{1} 0
  root.evaluateProcedural()
  check (root.groupSnapshotRows[2].count>0) "New layer Points calculate on inherited receivers" log
  local model=sphere name:"Filler model" radius:1 pos:[500,0,0]
  check (filler.replacePointSource 1 model) "Pick object replaces Point with sphere" log
  root.evaluateProcedural()
  check (root.groupSnapshotRows[2].count>0 and filler.previewError=="") "Replacement sphere retains working population" log
  local a=root.groupSnapshotRows[1],b=root.groupSnapshotRows[2]
  local ar=cyrusPlacementPage a (cyrusPlacementToken a) 0 a.count,br=cyrusPlacementPage b (cyrusPlacementToken b) 0 b.count,conflicts=0
  for x in ar do for y in br do if distance x[1].row4 y[1].row4<4.999 do conflicts+=1
  check (ar.count>0 and br.count>0 and conflicts==0) "Leaf clearance excludes fillers on plane, sphere and box" log
  leaf.setSourceClearance #{1} #clearanceExternal 2
  leaf.setSourceClearance #{1} #clearanceTargets (filler.layerID+"|")
  root.evaluateProcedural();local before=fingerprint root,id=filler.layerID
  root.removeLogicalLayer filler
  check (leaf.clearanceTargets[1]==id+"|") "Deleting a target preserves its unresolved identity" log
  root.evaluateProcedural()
  max undo;root.evaluateProcedural()
  check (root.layerObjects[2].layerID==id and fingerprint root==before) "Undo target deletion restores exact relationship and output" log
  local oldDiffuse=source.material.texmapDiffuse,cc=ColorCorrection()
  cc.map=oldDiffuse;cc.saturation=-50
  root.identificationMode=4;root.setGroupDisplay 3
  -- Establish the first retained display after target Undo before measuring a
  -- material-only edit. Cold publication/display recovery is a separate phase.
  CyrusPointSuspended=false
  root.evaluateProcedural()
  for pass=1 to 4 do (windows.processPostedMessages();redrawViews())
  root.evaluateProcedural();before=fingerprint root;local epoch=root.procEpoch
  source.material.texmapDiffuse=cc
  for pass=1 to 4 do (windows.processPostedMessages();redrawViews())
  root.evaluateProcedural()
  format "Material before/after: epoch %/%, placements equal %\n" epoch root.procEpoch (fingerprint root==before) to:log
  check (root.procEpoch==epoch and fingerprint root==before) "Leaf Color Correction changes material without changing clearance placement" log
  source.material.texmapDiffuse=oldDiffuse
  root.selectLayer 1;select node;max modify mode
  if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
  for slot in root.mainUI.slots do slot.open=true
  root.mainUI.bindEditors()
  local deadline=timeStamp()+30000
  while root.mainUI.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();root.mainUI.pageTimer.tick())
  root.bindNativeUI()
  check (root.managerUI.flow_layersUI_layerList_colored.Items.Count==2) "Both layer rows remain visible after target Undo" log
  leaf.setSourceClearance #{1} #clearancePlanar true
  root.evaluateProcedural();leaf.setSourceClearance #{1} #clearancePlanar false;root.evaluateProcedural()
  check (fingerprint root==before) "XY to 3D return restores exact 3D placement result" log
  local published=root.groupSnapshotRows[1],rows=cyrusPlacementPage published (cyrusPlacementToken published) 0 published.count
  check (leaf.bakeInstances node==rows.count) "Bake exports the accepted leaf count" log
  local matched=true,maxBasisError=0.,maxPositionError=0.
  for i=1 to rows.count do (
   local baked=leaf.bakedNodes[i]
   if baked.material!=source.material do matched=false
   -- Max decomposes assigned matrices into its transform controller. An isolated
   -- Point assignment reproduced a 5.89099e-5 basis error near a half turn, with
   -- no plugin involved (bake-diagnostic.txt). Bound that single-precision error.
   for axis=1 to 3 do maxBasisError=amax maxBasisError (distance baked.transform[axis] rows[i][1][axis])
   maxPositionError=amax maxPositionError (distance baked.transform.row4 rows[i][1].row4)
  )
  format "Bake maximum basis error %, position error % cm\n" maxBasisError maxPositionError to:log
  matched=matched and maxBasisError<=0.0001 and maxPositionError<=0.00001
  check matched "Baked models preserve accepted transforms and material correspondence" log
  max undo;root.evaluateProcedural()
  check (leaf.bakedNodes.count==0 and fingerprint root==before) "Undo Bake restores procedural output" log
  saveMaxFile (MCPFixtureDir+"real-leaf-clearance.max") quiet:true
  viewport.setLayout #layout_1;viewport.setType #view_top
  select #(surface,curved,boxSurface);max zoomext sel all;select node;redrawViews()
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)

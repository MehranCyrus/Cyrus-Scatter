(
 local year=(maxVersion())[1]/1000+1998
 if findItem #(2024,2026) year==0 or not matchPattern MCPFixtureDir pattern:("*/update08671-test-clearance-compat-"+year as string+"/") do throw "Owned compatibility profile required"
 local log=createFile (MCPFixtureDir+"compatibility-viewport.txt")
 fn verify value label log=(format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn key root=cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("compat") #()
 fn draw root=(root.refreshDisplay();for pass=1 to 3 do(windows.processPostedMessages();redrawViews());completeRedraw())
 try(
  resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
  units.SystemType=#centimeters;units.SystemScale=1
  local maps=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library/Maps/"
  verify (doesFileExist (maps+"3D4DL.COM_leaf2_opac.jpg") and doesFileExist (maps+"3D4DL.COM_leaf2_diff.jpg")) "Existing leaf image maps available" log
  global PFNode=AminScatterObject name:"200-leaf performance",PFRoot=PFNode.baseObject,PFLeaf,PFModels=#(),PFThird
  PFRoot.updateMode=1;PFRoot.autoRender=false;PFRoot.newLayer();PFLeaf=PFRoot.selectedLayer()
  local surface=plane name:"Plane001" width:160 length:160 widthsegs:2 lengthsegs:2
  PFRoot.setLayerSurfaces PFLeaf #(surface);PFLeaf.amount=200
  PFLeaf.procSelfOverride=true;PFLeaf.procSelfEnabled=true;PFLeaf.procSelfMultiplier=1;PFLeaf.procSelfGap=0
  for index=1 to 3 do(
   local model=plane name:("Compatibility opacity leaf "+index as string) width:20 length:17 widthsegs:1 lengthsegs:1 pos:[200+index*30,0,0]
   local mat=standardMaterial name:("Standard leaf "+index as string)
   mat.diffuseMap=BitmapTexture filename:(maps+"3D4DL.COM_leaf2_diff.jpg")
   mat.opacityMap=BitmapTexture filename:(maps+"3D4DL.COM_leaf2_opac.jpg")
   mat.diffuseMapEnable=true;mat.opacityMapEnable=true;mat.twoSided=true
   model.material=mat;PFLeaf.addModelSource model;append PFModels model
   if index==2 do(
    PFRoot.evaluateProcedural();PFRoot.identificationMode=4;PFRoot.setGroupDisplay 3;draw PFRoot
   )
  )
  PFThird=PFModels[3];PFLeaf.setSourceRadius #{1,2,3} 3
  PFRoot.evaluateProcedural();PFRoot.setGroupDisplay 3;PFRoot.identificationMode=4;draw PFRoot
  verify (PFRoot.uiVersion()=="0.86.8.1" and PFLeaf.previewError=="" and PFRoot.groupSnapshotRows[1].count>0) "Matched compatibility payload adds a third opacity-card model" log
  local before=key PFRoot,stats=cyrusMaterialPreviewStats(),epoch=PFRoot.procEpoch
  PFRoot.identificationMode=1;draw PFRoot;PFRoot.identificationMode=4;draw PFRoot
  verify (key PFRoot==before and PFRoot.procEpoch==epoch and (cyrusMaterialPreviewStats())[2]==stats[2]) "Colored/Textured switching retains appearance and placements" log
  local original=PFModels[1].material.diffuseMap,correction=ColorCorrection()
  correction.map=original;correction.saturation=-90;PFModels[1].material.diffuseMap=correction;draw PFRoot
  verify ((cyrusMaterialPreviewStats())[2]>stats[2] and key PFRoot==before) "Standard material Color Correction refreshes appearance only" log
  stats=cyrusMaterialPreviewStats();correction.saturation=30;draw PFRoot
  verify ((cyrusMaterialPreviewStats())[2]>stats[2]) "Nested correction change refreshes the material" log
  PFModels[1].material.diffuseMap=original;draw PFRoot
  PFLeaf.sourceWeights[3]=0;PFRoot.evaluateProcedural();before=key PFRoot
  PFLeaf.setSourceClearance #{3} #clearancePreferred true;PFRoot.evaluateProcedural()
  verify (key PFRoot==before) "Unused model preference preserves accepted placements" log
  PFLeaf.setSourceClearance #{3} #clearancePreferred false;PFLeaf.sourceWeights[3]=1;PFRoot.evaluateProcedural();before=key PFRoot
  saveMaxFile (MCPFixtureDir+"compatibility-three-leaves.max") quiet:true
  loadMaxFile (MCPFixtureDir+"compatibility-three-leaves.max") quiet:true
  PFNode=getNodeByName "200-leaf performance";PFRoot=PFNode.baseObject;PFLeaf=PFRoot.selectedLayer();PFModels=PFLeaf.validSources();PFThird=PFModels[3]
  PFRoot.updateMode=1;PFRoot.evaluateProcedural();draw PFRoot
  verify (PFModels.count==3 and key PFRoot==before) "Three-model saved scene reopens with identical placements" log
  surface=getNodeByName "Plane001";viewport.setLayout #layout_1;viewport.setType #view_top
  select surface;max zoomext sel all;hide surface;select PFNode;max modify mode
  if not PFRoot.mainUI.controlsReady do PFRoot.mainUI.mountTimer.tick()
  PFRoot.bindNativeUI();draw PFRoot
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)

(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-perf-*-2027/" do throw "Owned performance host required"
 local log=createFile (MCPFixtureDir+"viewport-checks.txt")
 fn verify value label log=(format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn drawNow root=(root.refreshDisplay();for k=1 to 3 do (windows.processPostedMessages();redrawViews());completeRedraw())
 fn placementKey root=cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("viewport") #()
 try(
  verify (PFRoot.uiVersion()=="0.86.8.1" and cyrusMaterialPreviewStats!=undefined) "Matching corrective script/native features loaded" log
  PFRoot.identificationMode=4;PFRoot.setGroupDisplay 3;drawNow PFRoot
  local stats=cyrusMaterialPreviewStats(),key=placementKey PFRoot
  PFLeaf.setSourceRadius #{1} 5
  PFRoot.evaluateProcedural();drawNow PFRoot
  local after=cyrusMaterialPreviewStats()
  format "Radius: before %, after %, streams %\n" stats after (cyrusRetainedStreamStats()) to:log
  verify (after[2]==stats[2] and after[3]>=stats[3]+2) "Radius edit reuses both leaf materials without baking maps" log
  stats=after;key=placementKey PFRoot;local epoch=PFRoot.procEpoch,builds=PFLeaf.procPreparedBuilds
  PFRoot.identificationMode=1;drawNow PFRoot
  PFRoot.identificationMode=4;drawNow PFRoot
  verify ((cyrusMaterialPreviewStats())[2]==stats[2]) "Colored/Textured Mesh switching reuses prepared material data" log
  verify (placementKey PFRoot==key and PFRoot.procEpoch==epoch and PFLeaf.procPreparedBuilds==builds) "Appearance switching preserves placements and preparation" log
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  catalog.Load @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library" "0.86.7" 2027
  global PFThird
  if not isValidNode PFThird do PFThird=CyrusModelMerge catalog (catalog.MatchingAt "A014" "" 0) owner:PFLeaf
  PFRoot.evaluateProcedural();drawNow PFRoot
  local meshCopy=snapshotAsMesh PFThird
  format "Third leaf: %, faces=%, vertices=%, material=%\n" PFThird.name meshCopy.numfaces meshCopy.numverts (classof PFThird.material) to:log
  verify (meshCopy.numfaces==2) "Third Sycamore source is a two-triangle opacity card" log
  meshCopy=undefined
  verify (PFLeaf.previewError=="" and PFRoot.groupSnapshotRows[1].count>0) "Third model adds successfully to existing layer" log
  PFRoot.identificationMode=1;drawNow PFRoot
  key=placementKey PFRoot;epoch=PFRoot.procEpoch;stats=cyrusMaterialPreviewStats()
  PFRoot.identificationMode=4;drawNow PFRoot
  verify (placementKey PFRoot==key and PFRoot.procEpoch==epoch) "Third-model Mesh/Textured switching preserves placement" log
  -- Select a supported legacy material from a real source, preserving originals.
  local source=PFModels[1],material=source.material
  format "First source material: %\n" (classof material) to:log
  local mapProperty=if isProperty material #baseTexmap then #baseTexmap else #texmapDiffuse
  verify (isProperty material mapProperty) "Real leaf exposes a supported Corona color map" log
  local original=getProperty material mapProperty,correction=ColorCorrection()
  correction.map=original;correction.saturation=-80
  setProperty material mapProperty correction;drawNow PFRoot
  verify ((cyrusMaterialPreviewStats())[2]>stats[2]) "Adding Color Correction refreshes the material" log
  verify (placementKey PFRoot==key and PFRoot.procEpoch==epoch) "Color Correction preserves placement publication" log
  stats=cyrusMaterialPreviewStats();correction.saturation=40;drawNow PFRoot
  verify ((cyrusMaterialPreviewStats())[2]>stats[2]) "Nested Color Correction changes invalidate the material" log
  setProperty material mapProperty original;drawNow PFRoot
  stats=cyrusMaterialPreviewStats()
  PFLeaf.setSourceRadius #{1} 6;PFRoot.evaluateProcedural();drawNow PFRoot
  verify ((cyrusMaterialPreviewStats())[2]==stats[2]) "Radius edit after material replacement still reuses textures" log
  PFRoot.identificationMode=1;drawNow PFRoot
  viewport.setLayout #layout_1;viewport.setType #view_top
  local surface=getNodeByName "Plane001"
  select surface;max zoomext sel all;hide surface;select PFNode;max modify mode
  saveMaxFile (MCPFixtureDir+"three-leaves-cutout.max") quiet:true
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)

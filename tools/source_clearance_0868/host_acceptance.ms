-- Development integration checks, only in a matching disposable Max 2027 host.
(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-*-2027/" do throw "Owned clearance host required"
 global CLRNode,CLRRoot,CLRA,CLRB,CLRSurface,CLRModels,CLRExpected
 local log=createFile (MCPFixtureDir+"clearance-acceptance.txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn page rows = (if rows.count>500 do throw "Bounded test readback exceeded";cyrusPlacementPage rows (cyrusPlacementToken rows) 0 rows.count)
 fn fingerprint root = cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("clearance") #()
 fn calculate root = (root.evaluateProcedural();for leaf in root.layerObjects do if leaf.previewError!="" do throw leaf.previewError)
 fn combo control index = (
  control.selection=index
  local handle=control.hwnd[1],identifier=windows.getWindowLong handle #id
  -- Max commits dropdown selection on CBN_SELENDOK, not CBN_SELCHANGE.
  windows.sendMessage (windows.getParentHWND handle) 0x0111 (identifier+9*65536) handle
  for pass=1 to 5 do (windows.processPostedMessages();sleep 0.02)
 )
 try (
  resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
  units.SystemType=#centimeters;units.SystemScale=1
  CLRSurface=plane name:"Clearance test surface" width:300 length:300 widthsegs:3 lengthsegs:3
  CLRModels=#(box name:"Model A" width:10 length:10 height:20 pos:[500,0,0],sphere name:"Model B" radius:4 pos:[550,0,0])
  CLRNode=AminScatterObject name:"Clearance acceptance";CLRRoot=CLRNode.baseObject;CLRRoot.updateMode=1;CLRRoot.autoRender=false
  CLRRoot.newLayer();CLRA=CLRRoot.selectedLayer();CLRRoot.setLayerSurfaces CLRA #(CLRSurface)
  for model in CLRModels do CLRA.addModelSource model
  CLRA.amount=200;CLRA.viewportMode=1;CLRA.procSelfOverride=true;CLRA.procSelfEnabled=false;CLRA.procLayerSelfEnabled=false
  CLRA.setSourceRadius #{1} 25;CLRA.setSourceRadius #{2} 0
  calculate CLRRoot
  check (CLRRoot.groupSnapshotRows[1].count==200) "Default rules preserve 200 eligible candidates" log
  local before=fingerprint CLRRoot,builds=CLRA.procPreparedBuilds,epoch=CLRRoot.procEpoch
  CLRA.setSourceClearance #{1} #clearanceOthers 2
  check (CLRRoot.procEpoch==epoch and fingerprint CLRRoot==before) "Manual edit retains the complete old publication" log
  calculate CLRRoot
  check (CLRA.procPreparedBuilds==builds) "Clearance edit reuses prepared candidate geometry" log
  local rows=page CLRRoot.groupSnapshotRows[1],checked=0,badPairs=0
  for i=1 to rows.count do for j=i+1 to rows.count do if rows[i][2]!=rows[j][2] do (
   if (distance rows[i][1].row4 rows[j][1].row4)<24.999 do badPairs+=1
   checked+=1
  )
  check (checked>0 and rows.count<200 and badPairs==0) "All different-model pairs meet requested radius" log
  local identity=CLRA.sourceRowIDs[1],policy=CLRA.clearanceRow 1
  check (CLRA.makePointSource 1) "Model converts to Point" log
  check (CLRA.sourceRowIDs[1]==identity and (CLRA.clearanceRow 1) as string==policy as string) "Point conversion preserves source clearance identity" log
  check (CLRA.replacePointSource 1 CLRModels[1]) "Pick object replaces Point" log
  local replacement=cylinder name:"Replacement model" radius:5 height:15 pos:[600,0,0]
  check (CLRA.replacePointSource 1 replacement and CLRA.sourceRowIDs[1]==identity and (CLRA.clearanceRow 1) as string==policy as string) "Pick object replaces a model without losing clearance" log
  CLRA.setSourceClearance #{1} #clearanceOthers 0;CLRA.procSelfEnabled=true;CLRA.procSelfMultiplier=1;CLRA.procSelfGap=0;CLRA.procSelfPlanar=false
  calculate CLRRoot;before=fingerprint CLRRoot
  CLRA.setSourceClearance #{1} #clearanceCopies 2;CLRA.setSourceClearance #{1} #clearanceOthers 2
  calculate CLRRoot
  check (fingerprint CLRRoot==before) "Equivalent inherited and explicit rules retain complete output" log
  CLRRoot.newLayer();CLRB=CLRRoot.selectedLayer();CLRRoot.setLayerSurfaces CLRB #(CLRSurface)
  CLRB.addPointSource();CLRB.amount=160;CLRB.procSelfOverride=true;CLRB.procSelfEnabled=false;CLRB.procLayerSelfEnabled=false
  CLRB.setSourceRadius #{1} 10
  CLRB.setSourceClearance #{1} #clearanceExternal 2
  CLRB.setSourceClearance #{1} #clearanceTargets (CLRA.layerID+"|")
  CLRB.setSourceClearance #{1} #clearancePreferred true
  calculate CLRRoot
  local a=page CLRRoot.groupSnapshotRows[1],b=page CLRRoot.groupSnapshotRows[2],conflicts=0
  for x in a do for y in b do if distance x[1].row4 y[1].row4 < (if x[2]==1 then 34.999 else 9.999) do conflicts+=1
  check (conflicts==0 and b.count>0) "Later preferred layer clears matching earlier-layer models" log
  local copyLayer=CLRRoot.copyLogicalLayer CLRB variation:#same
  check (copyLayer.sourceRowIDs[1]!=CLRB.sourceRowIDs[1] and copyLayer.clearanceSourceIDs[1]==copyLayer.sourceRowIDs[1]) "Layer copy remaps clearance source identity" log
  check (copyLayer.clearanceTargets[1]==CLRB.clearanceTargets[1]) "Layer copy preserves external target identity" log
  CLRRoot.removeLogicalLayer copyLayer
  local bindings=#(),document=CyrusRecipeCapture CLRRoot #(CLRA,CLRB) "Clearance round trip" bindingResult:bindings
  check (CyrusRecipeGet document "formatVersion"==8) "New recipes use contract 8" log
  local imported=CyrusRecipeImport undefined document bindings newSetup:true variation:#same calculate:true
  check (imported[2][2].clearanceTargets[1]==imported[2][1].layerID+"|") "Recipe import remaps explicit layer targets" log
  check (imported[2][2].clearanceSourceIDs[1]==imported[2][2].sourceRowIDs[1]) "Recipe import remaps source clearance identities" log
  delete imported[3]
  select CLRNode;max modify mode
  if not CLRRoot.mainUI.controlsReady do CLRRoot.mainUI.mountTimer.tick()
  for slot in CLRRoot.mainUI.slots do slot.open=true
  CLRRoot.mainUI.bindEditors()
  local deadline=timeStamp()+30000
  while CLRRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();CLRRoot.mainUI.pageTimer.tick())
  local mainBounds=windows.getWindowPos CLRRoot.mainUI.hwnd,licenseBounds=windows.getWindowPos CLRRoot.mainUI.licenseButton.hwnd[1]
  check (licenseBounds.y+licenseBounds.h<=mainBounds.y+mainBounds.h) "Main panel contains its bottom button at the current UI scale" log
  CLRRoot.selectLayer 1;CLRRoot.bindNativeUI()
  local ui=CLRRoot.modelsUI,spacing=CLRRoot.spacingUI
  check (ui.sourceUI_clearanceExternalList.selection==1) "Model external scope displays inherited state" log
  for index in #(1,2,1,2) do combo spacing.proceduralUI_scopeList index
  check (spacing.proceduralUI_peerList.items.count==1) "Actual spacing dropdown notification binds other layer" log
  epoch=CLRRoot.procEpoch;builds=CLRA.procPreparedBuilds
  for i=1 to 5 do CLRRoot.bindNativeUI()
  check (CLRRoot.procEpoch==epoch and CLRA.procPreparedBuilds==builds) "Browsing and repeated binding do no calculation" log
  ui.sourceUI_plantList.selection=#{1,2};ui.sourceUI_showSelectedColor()
  check (ui.sourceUI_clearanceCopiesList.selected=="Mixed") "Multi-selection explicitly labels mixed scope values" log
  combo ui.sourceUI_clearanceOthersList 2
  check ((CLRA.clearanceRow 1)[2]==1 and (CLRA.clearanceRow 2)[2]==1 and (CLRA.clearanceRow 1)[3]==0) "Multi-selection changes only requested scope" log
  max undo;CLRRoot.bindNativeUI()
  check ((CLRA.clearanceRow 1)[2]==2 and (CLRA.clearanceRow 2)[2]==0) "Undo restores independent model settings" log
  max redo;CLRRoot.bindNativeUI()
  check ((CLRA.clearanceRow 1)[2]==1 and (CLRA.clearanceRow 2)[2]==1) "Redo restores the same edit" log
  calculate CLRRoot;CLRExpected=fingerprint CLRRoot
  saveMaxFile (MCPFixtureDir+"clearance59.max") quiet:true
  local f=createFile (MCPFixtureDir+"saved-fingerprint.txt");format "%" CLRExpected to:f;close f
  CyrusPointSuspended=false;redrawViews()
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)

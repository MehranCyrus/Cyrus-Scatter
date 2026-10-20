-- Only execute in the task-owned profile; never in an artist session.
(
 if not matchPattern MCPFixtureDir pattern:"*/clearance-relax-08682-*/" do throw "Owned Relax fixture required"
 global RXNode,RXRoot,RXA,RXB,RXSurface,RXModels
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"generation-command.txt")
 local log=createFile (MCPFixtureDir+phase+".txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn calculate = (RXRoot.evaluateProcedural();for leaf in RXRoot.layerObjects do if leaf.previewError!="" do throw leaf.previewError)
 fn rows index = (local data=RXRoot.groupSnapshotRows[index];if data.count>500 do throw "Bounded fixture required";cyrusPlacementPage data (cyrusPlacementToken data) 0 data.count)
 fn fingerprint = cyrusPlacementPublicationFingerprint RXRoot.groupSnapshotRows RXRoot.procPublishedRadii #("relax") #()
 fn energy values spacing = (
  local total=0.0
  for i=1 to values.count do for j=i+1 to values.count do (local d=distance values[i][1].row4 values[j][1].row4;if d<spacing do total+=(spacing-d)^2)
  total
 )
 fn toggle control = (windows.sendMessage control.hwnd[1] 0x00F5 0 0;windows.processPostedMessages())
 try (
  case phase of (
   "setup": (
    resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
    units.SystemType=#centimeters;units.SystemScale=1
    RXSurface=plane name:"Relax receiver" width:300 length:300 widthsegs:5 lengthsegs:5
    RXModels=#(box name:"Clearance model A" width:10 length:10 height:10 pos:[500,0,0],sphere name:"Clearance model B" radius:4 pos:[550,0,0])
    RXNode=AminScatterObject name:"Clearance and Relax QA";RXRoot=RXNode.baseObject;RXRoot.updateMode=1;RXRoot.autoRender=false
    RXRoot.newLayer();RXA=RXRoot.selectedLayer();RXRoot.setLayerSurfaces RXA #(RXSurface)
    for model in RXModels do RXA.addModelSource model
    RXA.amount=200;RXA.procSelfOverride=true;RXA.procSelfEnabled=false;RXA.procLayerSelfEnabled=false
    calculate()
    select RXNode;max modify mode
    if not RXRoot.mainUI.controlsReady do RXRoot.mainUI.mountTimer.tick()
    for slot in RXRoot.mainUI.slots do slot.open=(findItem #("managerUISlot","modelsUISlot","spacingUISlot") slot.name)>0
    RXRoot.mainUI.bindEditors()
    local deadline=timeStamp()+30000
    while RXRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();RXRoot.mainUI.pageTimer.tick())
    RXRoot.bindNativeUI()
    format "VERSION=% ROOT=%\n" (RXRoot.uiVersion()) RXRoot to:log
   )
   "bounds": (
    local ui=RXRoot.modelsUI,spacing=RXRoot.spacingUI
    ui.clearanceToggle.checked=true;ui.layout()
    format "MODEL width=% height=%\n" ui.width ui.height to:log
    for control in #(ui.sourceUI_clearanceFactorSpin,ui.sourceUI_clearanceFactorSpin_caption,ui.sourceUI_clearanceGapSpin,ui.sourceUI_clearanceGapSpin_caption) do (
     format "% visible=% position=%\n" control.name control.visible control.pos to:log
     for h in control.hwnd do format "  % %\n" (windows.getHWNDData h) (windows.getWindowPos h) to:log
    )
    for pair in #(#(ui.sourceUI_clearanceFactorSpin,ui.sourceUI_clearanceFactorSpin_caption),#(ui.sourceUI_clearanceGapSpin,ui.sourceUI_clearanceGapSpin_caption)) do (
     local labelRect=windows.getWindowPos pair[2].hwnd[1]
     for h in pair[1].hwnd do (
      local r=windows.getWindowPos h
      check (r.x>=labelRect.x+labelRect.w or r.y>=labelRect.y+labelRect.h or r.y+r.h<=labelRect.y) (pair[1].name+" does not overlap its caption") log
     )
    )
    format "RELAX advanced=% pointVisible=% boundaryVisible=%\n" spacing.advancedToggle.checked spacing.spacingUI_relaxCheck.visible spacing.spacingUI_boundaryRelaxCheck.visible to:log
    spacing.advancedToggle.checked=true;spacing.layout()
    format "RELAX expanded pointVisible=% boundaryVisible=% pos=%\n" spacing.spacingUI_relaxCheck.visible spacing.spacingUI_boundaryRelaxCheck.visible spacing.spacingUI_relaxCheck.pos to:log
   )
   "calculations": (
    local ui=RXRoot.spacingUI
    ui.advancedToggle.checked=false;ui.layout()
    check (ui.spacingUI_relaxCheck.visible and ui.spacingUI_boundaryRelaxCheck.visible) "Both Relax controls are visible without Advanced" log
    RXA.relaxEnabled=false;RXA.finalRelax=false;RXA.relaxSpacing=25;RXA.relaxIterations=20;RXA.relaxStrength=0.7
    RXRoot.bindNativeUI();calculate()
    local before=rows 1,original=fingerprint(),epoch=RXRoot.procEpoch
    toggle ui.spacingUI_relaxCheck
    check RXA.relaxEnabled "Actual Point Relax checkbox edits the selected layer" log
    check (fingerprint()==original and RXRoot.procEpoch==epoch) "Manual Relax edit retains the previous publication" log
    calculate()
    local relaxed=rows 1
    check (relaxed.count==before.count) "Point Relax preserves unfiltered candidate count" log
    check ((energy relaxed 25)<(energy before 25)*0.8) "Point Relax reduces close-pair overlap energy" log
    local maxZ=0.0
    for row in relaxed do maxZ=amax maxZ (abs row[1].row4.z)
    check (maxZ<0.001) "Relaxed points remain on the receiver" log
    local repeat=fingerprint();calculate()
    check (fingerprint()==repeat) "Repeated Relax calculation is deterministic" log
    toggle ui.spacingUI_relaxCheck;calculate()
    check (fingerprint()==original) "Disabling Relax restores the original deterministic placements" log
    RXA.relaxSpacing=50;RXA.finalStrength=0.5;RXA.finalIterations=5;RXA.finalMaxMove=2;RXRoot.bindNativeUI()
    before=rows 1;original=fingerprint()
    toggle ui.spacingUI_boundaryRelaxCheck
    check (RXA.finalRelax and not RXA.relaxEnabled) "Boundary Relax runs independently of Point Relax" log
    check (ui.spacingUI_spacingSpin.visible and ui.spacingUI_spacingSpin.enabled) "Boundary-only neighborhood distance is visible and editable" log
    calculate();relaxed=rows 1
    local moved=0,maxMove=0.0
    for i=1 to before.count do (local d=distance before[i][1].row4 relaxed[i][1].row4;if d>0.001 do moved+=1;maxMove=amax maxMove d)
    format "Boundary moved=% maxMove=%\n" moved maxMove to:log
    check (moved>0 and maxMove<=2.001 and relaxed.count==before.count) "Boundary Relax moves candidates within the total movement cap" log
    toggle ui.spacingUI_boundaryRelaxCheck;calculate()
    check (fingerprint()==original) "Disabling Boundary Relax restores original placements" log
    RXA.relaxSpacing=25;RXRoot.bindNativeUI();toggle ui.spacingUI_relaxCheck;toggle ui.spacingUI_boundaryRelaxCheck
    RXA.setSourceRadius #{1,2} 12;RXA.setSourceClearance #{1,2} #clearanceCopies 2;RXA.setSourceClearance #{1,2} #clearanceOthers 2
    calculate();relaxed=rows 1
    local bad=0
    for i=1 to relaxed.count do for j=i+1 to relaxed.count do if distance relaxed[i][1].row4 relaxed[j][1].row4<23.999 do bad+=1
    format "Combined accepted=% badPairs=%\n" relaxed.count bad to:log
    check (bad==0 and relaxed.count>0 and relaxed.count<200) "Collision filtering follows both Relax passes and enforces summed radii" log
    RXRoot.newLayer();RXB=RXRoot.selectedLayer();RXRoot.setLayerSurfaces RXB #(RXSurface);RXB.addPointSource();RXB.amount=80
    RXB.setSourceRadius #{1} 12;RXB.setSourceClearance #{1} #clearanceExternal 3
    RXRoot.bindNativeUI();calculate()
    local a=rows 1,b=rows 2;bad=0
    for x in a do for y in b do if distance x[1].row4 y[1].row4<23.999 do bad+=1
    check (bad==0 and b.count>0) "Cross-layer collision respects the relaxed first layer" log
    check (not RXB.relaxEnabled and not RXB.finalRelax and RXA.relaxEnabled and RXA.finalRelax) "Switching layers preserves independent Relax settings" log
    RXRoot.selectLayer 1;RXRoot.bindNativeUI()
    check (ui.spacingUI_relaxCheck.checked and ui.spacingUI_boundaryRelaxCheck.checked) "Returning to the first layer restores both checkbox states" log
    saveMaxFile (MCPFixtureDir+"relax-clearance.max") quiet:true
   )
   "lifecycle": (
    local expected=fingerprint()
    loadMaxFile (MCPFixtureDir+"relax-clearance.max") quiet:true
    RXNode=getNodeByName "Clearance and Relax QA";RXRoot=RXNode.baseObject;RXA=RXRoot.layerObjects[1];RXB=RXRoot.layerObjects[2]
    calculate()
    check (fingerprint()==expected and RXA.relaxEnabled and RXA.finalRelax and not RXB.relaxEnabled) "Save/reopen preserves layer Relax settings and placement fingerprint" log
    select RXNode;max modify mode
    if not RXRoot.mainUI.controlsReady do RXRoot.mainUI.mountTimer.tick()
    for slot in RXRoot.mainUI.slots do slot.open=(findItem #("managerUISlot","modelsUISlot","spacingUISlot") slot.name)>0
    RXRoot.mainUI.bindEditors()
    local deadline=timeStamp()+30000
    while RXRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();RXRoot.mainUI.pageTimer.tick())
    RXRoot.selectLayer 1;RXRoot.bindNativeUI()
    local ui=RXRoot.spacingUI,epoch=RXRoot.procEpoch,builds=RXA.procPreparedBuilds
    toggle ui.spacingUI_relaxCheck
    check (not RXA.relaxEnabled and RXA.finalRelax) "Point checkbox changes only its own Relax setting" log
    max undo;RXRoot.bindNativeUI()
    check (RXA.relaxEnabled and ui.spacingUI_relaxCheck.checked) "Undo restores both model and checkbox" log
    max redo;RXRoot.bindNativeUI()
    check (not RXA.relaxEnabled and not ui.spacingUI_relaxCheck.checked) "Redo restores both model and checkbox" log
    calculate()
    RXRoot.updateMode=2;CyrusPointSuspended=false;RXRoot.bindNativeUI()
    for i=1 to 5 do (windows.processPostedMessages();redrawViews();sleep 0.05)
    epoch=RXRoot.procEpoch
    toggle ui.spacingUI_relaxCheck
    deadline=timeStamp()+15000
    while RXRoot.procEpoch==epoch and timeStamp()<deadline do (windows.processPostedMessages();redrawViews();sleep 0.05)
    check (RXA.relaxEnabled and RXRoot.procEpoch>epoch and fingerprint()==expected) "Live checkbox rebuilds relevant candidates and publishes the deterministic result" log
    epoch=RXRoot.procEpoch;builds=RXA.procPreparedBuilds
    for i=1 to 5 do (RXRoot.bindNativeUI();ui.advancedToggle.checked=not ui.advancedToggle.checked;ui.layout();windows.processPostedMessages())
    check (RXRoot.procEpoch==epoch and RXA.procPreparedBuilds==builds) "Binding and expanding Advanced do not calculate placements" log
    RXRoot.updateMode=1;RXRoot.bindNativeUI();ui.advancedToggle.checked=false;ui.layout()
    RXRoot.modelsUI.clearanceToggle.checked=true;RXRoot.modelsUI.layout()
   )
   "numeric": (
    local value=RXA.clearanceRow 1
    format "factor=% gap=% planar=% relaxDistance=%\n" value[6] value[7] value[8] RXA.relaxSpacing to:log
    check (abs(value[6]-1.5)<0.001 and abs(value[7]-3)<0.001 and value[8] and abs(RXA.relaxSpacing-30)<0.001) "Physical numeric edits and metric selection reached the selected source/layer" log
    calculate()
    local data=rows 1,bad=0
    for i=1 to data.count do for j=i+1 to data.count where data[i][2]==1 or data[j][2]==1 do (
     local p=data[i][1].row4,q=data[j][1].row4
     if distance [p.x,p.y,0] [q.x,q.y,0]<38.999 do bad+=1
    )
    check (bad==0 and data.count>0) "Edited source factor/gap/XY metric enforce 1.5 times summed radii plus 3" log
   )
   "ui-state": (
    select RXNode;max modify mode
    local deadline=timeStamp()+30000
    if not RXRoot.mainUI.controlsReady do RXRoot.mainUI.mountTimer.tick()
    for slot in RXRoot.mainUI.slots do slot.open=(findItem #("managerUISlot","modelsUISlot","spacingUISlot") slot.name)>0
    RXRoot.mainUI.bindEditors()
    while RXRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do (windows.processPostedMessages();RXRoot.mainUI.pageTimer.tick())
    RXRoot.bindNativeUI()
    local ui=RXRoot.modelsUI
    format "selected=% owner=% ready=% binding=%\n" ui.sourceUI_plantList.selection ui.owner ui.controlsReady ui.binding to:log
    for c in #(ui.sourceUI_clearanceFactorSpin,ui.sourceUI_clearanceGapSpin,ui.sourceUI_clearanceMetricList,RXRoot.spacingUI.spacingUI_spacingSpin) do format "% enabled=% value=%\n" c.name c.enabled (try(c.value)catch(undefined)) to:log
    ui.clearanceToggle.checked=true;ui.layout()
    for h in ui.sourceUI_clearanceFactorSpin.hwnd do format "% %\n" (windows.getHWNDData h) (windows.getWindowPos h) to:log
   )
   "wide": (
    -- Reuse the actual generated page in an owned, wider subrollout host.
    global RXWideHost,RXWidePage
    try(destroyDialog RXWideHost)catch()
    rollout RXWideHost "Cyrus layout verification" width:340 height:920 (
     local headerInset=0
     subRollout body "" pos:[0,0] width:340 height:920
    )
    local epoch=RXRoot.procEpoch,expected=fingerprint()
    createDialog RXWideHost width:340 height:920
    RXWidePage=RXRoot.createmodelsUI();RXWidePage.hostPage=RXWideHost
    addSubRollout RXWideHost.body RXWidePage rolledUp:false
    local pageRect=windows.getWindowPos RXWidePage.hwnd,pageData=windows.getHWNDData RXWidePage.hwnd
    local origin=windows.screenToClient pageData[2] pageRect.x pageRect.y
    windows.setWindowPos RXWidePage.hwnd origin.x origin.y 320 900 true
    RXWidePage.root=RXRoot;RXWidePage.owner=RXA;RXWidePage.bind RXA
    RXWidePage.clearanceToggle.checked=true;RXWidePage.layout()
    format "Measured wide page=%\n" RXWidePage.lastLayoutWidth to:log
    check (RXWidePage.lastLayoutWidth>300) "Generated page binds a wider host" log
    for pair in #(#(RXWidePage.sourceUI_clearanceFactorSpin,RXWidePage.sourceUI_clearanceFactorSpin_caption),#(RXWidePage.sourceUI_clearanceGapSpin,RXWidePage.sourceUI_clearanceGapSpin_caption)) do (
     local labelRect=windows.getWindowPos pair[2].hwnd[1],pageRect=windows.getWindowPos RXWidePage.hwnd
     for h in pair[1].hwnd do (
      local r=windows.getWindowPos h
      check (r.x>=labelRect.x+labelRect.w or r.y>=labelRect.y+labelRect.h or r.y+r.h<=labelRect.y) (pair[1].name+" wide field does not overlap its caption") log
      check (r.x>=pageRect.x and r.x+r.w<=pageRect.x+pageRect.w) (pair[1].name+" wide field stays inside its page") log
     )
    )
    destroyDialog RXWideHost
    check (RXRoot.procEpoch==epoch and fingerprint()==expected) "Opening a second width does not calculate or alter placements" log
   )
   "close": (
    global RXCloseTimer=dotNetObject "System.Windows.Forms.Timer"
    RXCloseTimer.Interval=800
    fn RXCloseTick sender args=(sender.Stop();quitMAX #noPrompt)
    dotNet.addEventHandler RXCloseTimer "Tick" RXCloseTick
    RXCloseTimer.Start()
   )
  )
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)

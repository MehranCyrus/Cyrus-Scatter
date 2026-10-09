-- Owned disposable host only. Load Max_Layer_Regions_074.ms first.
global C75Checks=#(),C75Assert,C75Manual,C75Workflow,C75Spacing
fn C75Assert condition message = (
    if not condition do throw ("0.75: "+message)
    append C75Checks message
    local log=createFile (MCPFixtureDir+"consolidation075-checks.txt")
    for item in C75Checks do format "%\n" item to:log
    close log;true
)
fn C75Manual = (
    LRSetup()
    local r=LRRoot,a=LRLayer,before=cyrusEditFingerprint LRRoot.groupSnapshotRows[1] "manual",epoch=LRRoot.procEpoch,builds=LRLayer.previewBuildCount
    a.amount=1234
    undo "Unrelated box" on (box name:"C75_Unrelated")
    max undo;windows.processPostedMessages()
    C75Assert (r.procEpoch==epoch and (cyrusEditFingerprint r.groupSnapshotRows[1] "manual")==before) "Unrelated Undo preserves Manual publication and epoch"
    C75Assert (a.previewBuildCount==builds) "Manual Undo does not rearm cold preview preparation"
    max redo;windows.processPostedMessages()
    C75Assert (r.procEpoch==epoch and r.groupSnapshotRows[1].count==1000) "Unrelated Redo does not publish pending count"
    a.refreshPreview()
    C75Assert (r.groupSnapshotRows[1].count==1000) "Passive preview refresh preserves Manual result"
    r.refreshAll()
    C75Assert (r.groupSnapshotRows[1].count==1234 and r.procEpoch>epoch) "Explicit Update publishes pending count"
    C75Assert (not r.procExplicitUpdate) "Update releases its explicit-publication scope"
    local completed=cyrusEditFingerprint r.groupSnapshotRows[1] "failure"
    a.advancedAxes=false;a.scaleMinimum=5;a.scaleMaximum=1;r.refreshAll()
    C75Assert (a.previewError!="" and (cyrusEditFingerprint r.groupSnapshotRows[1] "failure")==completed and not r.procExplicitUpdate) "Failed Update retains complete output and releases publication scope"
    a.scaleMinimum=1;a.scaleMaximum=1;a.advancedAxes=true;r.refreshAll()
    local oldSources=a.sources as array
    a.sources=#();r.refreshAll()
    C75Assert (not r.procExplicitUpdate) "Update failure/empty input does not leak publication permission"
    a.sources=oldSources;r.refreshAll()
    r.updateMode=2;a.amount=321;a.refreshPreview()
    C75Assert (r.groupSnapshotRows[1].count==321) "Live refresh still publishes relevant edits"
    r.updateMode=1
    true
)
fn C75Spacing = (
    LRSetup()
    local r=LRRoot,a=LRLayer
    r.newLayer();local second=r.selectedLayer();r.selectLayer 1
    select LRNode;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    r.spacingUI.open=true;r.mainUI.bindSection r.spacingUI
    local p=r.spacingUI
    C75Assert (p.proceduralUI_scopeList.items.count==2) "Ordinary layers expose only within-layer and between-layer spacing"
    p.proceduralUI_scopeList.selection=2;p.proceduralUI_bindRule resetPeer:true
    p.proceduralUI_enabledCheck.checked=true;p.proceduralUI_gapSpin.value=7;p.proceduralUI_saveRule()
    local pair=r.procPair 2 a second
    C75Assert (pair>0 and r.procRuleEnabled[pair] and r.procRuleGap[pair]==7) "Between layers saves the layer-pair rule"
    p.proceduralUI_scopeList.selection=1;p.proceduralUI_bindRule resetPeer:true
    p.proceduralUI_enabledCheck.checked=true;p.proceduralUI_gapSpin.value=2;p.proceduralUI_saveRule()
    C75Assert (a.procSelfOverride and a.procSelfEnabled and a.procSelfGap==2 and r.procRuleGap[pair]==7) "Within-layer changes preserve the independent layer-pair rule"
    r.addPaintSet a label:"Older group"
    r.mainUI.bindSection r.spacingUI
    C75Assert (r.spacingUI.proceduralUI_scopeList.items.count==5 and r.procRuleGap[pair]==7) "Older model groups retain every spacing scope"
    true
)
fn C75Workflow = (
    LRSetup()
    local r=LRRoot,a=LRLayer
    select LRNode;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    C75Assert (r.uiVersion()=="0.75") "Current source reports 0.75"
    C75Assert (a.paintAreas.count==0 and r.groupSnapshotRows[1].count==1000) "Basic scatter requires no Paint Area"
    r.modelsUI.open=true;r.modelsUI.advancedToggle.checked=false;r.mainUI.bindSection r.modelsUI
    -- WinForms Visible includes hidden host-window visibility. Assert retained
    -- rows and native disclosure state without claiming a visual screen test.
    C75Assert (r.modelsUI.sourceUI_plantList.items.count==1 and not r.modelsUI.sourceContainersUI_modeList.visible) "Model row retained; optional containers are under Advanced"
    r.modelsUI.advancedToggle.checked=true;r.modelsUI.layout()
    C75Assert (r.modelsUI.sourceContainersUI_modeList.visible) "Advanced still exposes source containers"
    r.coverageUI.open=true;r.mainUI.bindSection r.coverageUI
    C75Assert (r.coverageUI.setsUI_paintedCheck.visible and not r.coverageUI.setsUI_setList.visible and not r.coverageUI.brushUI_beginButton.visible) "Painting off hides area and brush controls"
    r.coverageUI.setsUI_paintedCheck.changed true
    C75Assert (r.coverageUI.setsUI_setList.visible and r.coverageUI.setsUI_addButton.visible) "Painting on exposes area creation"
    local area=r.addPaintArea a target:LRPlane
    cyrusBrushFill area.paintDocument 1.0;r.refreshAll()
    local doc=area.paintDocument,sources=a.sources as array
    r.coverageUI.setsUI_paintedCheck.changed false
    C75Assert (a.paintAreas.count==1 and area.paintDocument==doc and a.sources as string==sources as string) "Turning painting off preserves paint and model ownership"
    C75Assert (not r.coverageUI.brushUI_beginButton.visible) "Turning painting off hides brush again"
    r.refreshAll();C75Assert (r.groupSnapshotRows[1].count==1000) "Painting off returns to whole surfaces"
    true
)

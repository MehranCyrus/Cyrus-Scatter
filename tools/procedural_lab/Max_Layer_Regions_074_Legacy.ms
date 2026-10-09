-- Run Create in a private host with the frozen, pre-area 0.74 script/native pair.
-- Run Check in a separate private host with the current pair.
global LRLegacyCreate,LRLegacyCheck
fn LRLegacyCreate = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Owned host required"
    resetMaxFile #noPrompt;viewport.setType #view_top
    local p=plane width:200 length:200,model=box width:1 length:1 height:3 pos:[500,0,0]
    local node=AminScatterObject name:"Older074",r=node.baseObject
    r.setLayerTransfer true;r.updateMode=1;r.autoRender=false;r.surfaceNodes=#(p);r.newLayer()
    local a=r.selectedLayer();a.amount=1000;a.sources=#(model);a.sourceWeights=#(1.0)
    r.setLayerTransfer false;r.setGroupCoverage a true
    cyrusBrushSettings a.paintDocument 55 0.6 0.4 false 1
    cyrusBrushDab a.paintDocument [0,0,200] [0,0,-1] true
    cyrusBrushSettings a.paintDocument 20 0.5 0 true 1
    cyrusBrushDab a.paintDocument [0,0,200] [0,0,-1] true
    r.refreshAll()
    local log=createFile (MCPFixtureDir+"single-fingerprint.txt")
    format "%" (cyrusEditFingerprint r.groupSnapshotRows[1] "old074") to:log;close log
    saveMaxFile (MCPFixtureDir+"older-single.max") quiet:true
    local b=r.addPaintSet a label:"Other models";b.sources=#(model);b.paintEnabled=false;b.paintSetWeight=2.0
    r.refreshAll()
    log=createFile (MCPFixtureDir+"multi-fingerprint.txt")
    for rows in r.groupSnapshotRows do format "%\n" (cyrusEditFingerprint rows "old074") to:log
    close log;saveMaxFile (MCPFixtureDir+"older-multi.max") quiet:true
    true
)
fn LRLegacyCheck folder = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Owned host required"
    loadMaxFile (folder+"older-single.max") quiet:true
    local r=(getNodeByName "Older074").baseObject,a=r.layerObjects[1]
    r.refreshAll()
    local expected=(dotNetClass "System.IO.File").ReadAllText (folder+"single-fingerprint.txt")
    LRAssert ((cyrusEditFingerprint r.groupSnapshotRows[1] "old074")==expected) "Old single-set scene preserves soft paint and erase"
    select (getNodeByName "Older074");max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    r.coverageUI.open=true;r.mainUI.bindSection r.coverageUI
    LRAssert r.coverageUI.setsUI_importButton.enabled "Older paint has an explicit import action"
    r.coverageUI.setsUI_importButton.pressed()
    a.markInputDirty();r.refreshAll()
    LRAssert (a.paintAreas.count==1 and (cyrusEditFingerprint r.groupSnapshotRows[1] "old074")==expected) "Existing paint adopts into area without changing output"
    max undo;r.refreshAll()
    LRAssert (a.paintAreas.count==0 and (cyrusEditFingerprint r.groupSnapshotRows[1] "old074")==expected) "Area adoption Undo preserves older document"
    loadMaxFile (folder+"older-multi.max") quiet:true
    r=(getNodeByName "Older074").baseObject;r.refreshAll()
    local log=openFile (folder+"multi-fingerprint.txt")
    for rows in r.groupSnapshotRows do LRAssert ((cyrusEditFingerprint rows "old074")==(readLine log)) "Old multi-set population result remains intact"
    close log
    LRAssert (r.layerObjects.count==2 and r.layerObjects[2].logicalParentID==r.layerObjects[1].layerID) "Old model-owning sets remain distinct"
    true
)

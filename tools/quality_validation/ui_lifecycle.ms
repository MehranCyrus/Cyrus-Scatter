fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
(
QSetup();QMount()
local before=QFingerprint(),epoch=QRoot.procEpoch
case QScenarioID of (
 "R4-M01": (
    QRequire QRoot.mainUI.controlsReady "Main view unavailable"
    QRequire (QRoot.modelsUI.sourceUI_plantList.items.count==1) "Source view did not bind"
    clearSelection();QSettle 100;select QNode;max modify mode;QSettle 500
    QRequire QRoot.mainUI.controlsReady "Reopened view did not bind"
 )
 "R4-M02": (
    local first=QLayer;QRoot.newLayer();local second=QRoot.selectedLayer();QRoot.setLayerSurfaces second #(QSurface);second.addModelSource QModel
    for i=1 to 20 do (QRoot.selectLayer 1;QRoot.selectLayer 2;QRoot.selectLayer 1;QSettle 40)
    QRequire (QRoot.selectedLayer()==first) "Queued selection switched owner"
    QRoot.bindNativeUI();QRequire (QRoot.modelsUI.sourceUI_obj==first) "Source editor bound stale owner"
 )
 "R4-M03": (
    QRoot.modelsUI.sourceUI_plantList.selection=#{1}
    for i=1 to 10 do (QRoot.mainUI.bindEditors();QSettle 30)
    QRequire (QRoot.modelsUI.sourceUI_obj==QLayer and QRoot.mainUI.controlsReady) "Nested rebind left stale page"
 )
 "R4-M04": (
    local old=QNode;QRoot.mainUI.bindEditors();resetMaxFile #noPrompt;QSettle 700
    QRequire (not isValidNode old and not CyrusAnalyzerTimer.Enabled) "Reset retained owner work"
    QSetup();QMount();QRequire QRoot.mainUI.controlsReady "New scene did not mount after reset"
    before=QFingerprint();epoch=QRoot.procEpoch
 )
 "R4-M05": (
    local name=QNode.name;undo "Q delete controller" on delete QNode;QSettle 200;max undo;QSettle 500
    QNode=getNodeByName name;QRequire (isValidNode QNode) "Delete Undo lost controller"
    QRoot=QNode.baseObject;QLayer=QRoot.selectedLayer();QMount()
    QRequire (QRoot.modelsUI.sourceUI_obj==QLayer) "Restored controller bound wrong owner"
 )
 "R4-M06": (
    QRoot.modelsUI.sourceUI_plantList.selection=#{1};QLayer.setSourceRadius #{1} 4
    local identity=QLayer.sourceRowIDs[1];QLayer.makePointSource 1;QLayer.replacePointSource 1 QModel
    QRequire (QLayer.sourceRowIDs[1]==identity and QLayer.sourceRadiiWU[1]==4) "Point replacement lost source identity/policy"
 )
 "R4-M07": (
    QRoot.spacingUI.advancedToggle.checked=false;QRoot.spacingUI.layout()
    QRequire (QRoot.spacingUI.spacingUI_relaxCheck.visible and QRoot.spacingUI.spacingUI_boundaryRelaxCheck.visible) "Relax controls hidden"
    QClick QRoot.spacingUI.spacingUI_boundaryRelaxCheck
    QRequire (QLayer.finalRelax and QRoot.spacingUI.spacingUI_spacingSpin.enabled) "Boundary-only distance disabled"
    QLayer.setSourceClearance #{1} #clearanceCopies 2;QLayer.setSourceClearance #{1} #clearanceOthers 0
    QRequire ((QLayer.clearanceRow 1)[1]==2 and (QLayer.clearanceRow 1)[2]==0) "Clearance scopes coupled"
 )
 "R4-M08": (
    local count=objects.count;QClick QRoot.surfacesUI.flow_surfaceUI_surfaceVisibility
    QRequire (objects.count==count and cyrusSurfaceHidden QSurface) "Hide surface cloned or failed"
    max undo;QRequire (not cyrusSurfaceHidden QSurface) "Hide surface Undo failed"
 )
 "R4-M09": (
    for i=1 to 10 do (QRoot.mainUI.bindEditors();clearSelection();QSettle 30;select QNode;max modify mode;QSettle 50)
    QRequire (QRoot.mainUI.controlsReady and QRoot.selectedLayer()==QLayer) "Repeated views lost owner"
 )
 "R4-M10": (
    QArea=QRoot.addPaintArea QLayer target:QSurface;cyrusBrushFill QArea.paintDocument 1.0
    CyrusOpenPaintExport QRoot QArea;QSettle 100;resetMaxFile #noPrompt;QSettle 500
    QRequire (CyrusPaintExportDialog==undefined) "Scene reset retained export dialog"
    QSetup();before=QFingerprint();epoch=QRoot.procEpoch
 )
 "R4-M11": (
    QLayer.amount=500;local node=box name:"Q unrelated Undo sentinel"
    undo "Q unrelated transform" on node.pos.x=1200
    max undo;QSettle 500
    QRequire (QLayer.amount==500 and QFingerprint()==before and QRoot.procEpoch==epoch) "Unrelated Undo published Manual settings"
 )
 "R4-M12": (
    local scene=MCPFixtureDir+"schema59.max",identity=QLayer.layerID
    saveMaxFile scene quiet:true;resetMaxFile #noPrompt;units.SystemType=#centimeters;loadMaxFile scene quiet:true
    QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.selectedLayer();QCalculate()
    QRequire (QLayer.layerID==identity and QFingerprint()==before) "Schema59 identity/publication round trip failed"
    epoch=QRoot.procEpoch
 )
 "R4-M13": (
    local error="",path=splineShape name:"Q invalid open Band";addNewSpline path
    addKnot path 1 #corner #line [0,0,0];addKnot path 1 #corner #line [100,0,0];updateShape path
    QLayer.diversityMode=3;local band=QLayer.addStroke path side:2
    QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1]);try(QCalculate())catch(error=getCurrentException())
    QRequire (error!="" and QFingerprint()==before and QRoot.procEpoch==epoch) "Invalid successor lost publication"
    QLayer.diversityMode=1;QCalculate();QRequire (QFingerprint()==before) "Valid retry did not recover"
 )
 "R4-M14": (
    local stats=QLayer.procStatistics(),builds=stats[3]
    QLayer.amount=500
    -- The dedicated repeated-view scenario owns the ten-cycle stress test.
    for i=1 to 3 do (clearSelection();select QNode;QSettle 50)
    local unrelated=box();with animate on (at time 0 unrelated.pos=[2000,0,0];at time 10 unrelated.pos=[2500,0,0])
    for frame in #(0,5,10,0) do (sliderTime=frame;QSettle 100)
    QRequire ((QLayer.procStatistics())[3]==builds and QFingerprint()==before and QRoot.procEpoch==epoch) "Passive actions rebuilt Manual placements"
 )
 "R4-M15": (
    QLayer.bakeInstances QNode
    QRequire (QLayer.bakedNodes.count==400) "Bake did not preserve full output count"
    max undo;QRequire (QLayer.bakedNodes.count==0 or (for n in QLayer.bakedNodes where isValidNode n collect n).count==0) "Bake Undo retained output nodes"
 )
 default: throw ("Unknown UI/lifecycle scenario: "+QScenarioID)
)
QRequire (QFingerprint()==before) "UI lifecycle changed a retained publication"
QAssert true (QScenarioID+"-01") "Current generated UI/lifecycle checks completed"
)

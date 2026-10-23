fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
(
QSetup();hide QModel;QModel.renderable=false;QMount pages:#("modelsUISlot","managerUISlot");QRoot.modelsUI.sourceUI_plantList.selection=#{1}
QRoot.modelsUI.sourceUI_showSelectedColor();QRoot.modelsUI.accessToggle.checked=true;QRoot.modelsUI.layout()
local context=CyrusCaptureSourceAccess QRoot QLayer #{1},before=QFingerprint(),epoch=QRoot.procEpoch
case QScenarioID of (
 "R6-M01": (
    dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
    local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
    catalog.Load @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library" "0.86.8.3" 2027
    local entry=catalog.MatchingAt "A027" "" 0,imported=CyrusModelMerge catalog entry owner:QLayer
    QRequire (isValidNode imported and imported.material!=undefined) "Real library Add did not import its assigned material"
    local hidden=imported.isHidden,renderable=imported.renderable
    QMount pages:#("modelsUISlot","managerUISlot");QRoot.modelsUI.sourceUI_plantList.selection=#{2};QRoot.modelsUI.sourceUI_showSelectedColor()
    QClick QRoot.modelsUI.sourceUI_selectPlant
    QRequire (selection.count==1 and selection[1]==imported and imported.isHidden==hidden and imported.renderable==renderable) "Select sources changed visibility or selected wrong library node"
 )
 "R6-M02": (
    for flag in #(false,true) do (
        QModel.renderable=flag;CyrusShowSourceAccess context true;QRequire (not QModel.isHidden and QModel.renderable==flag) "Show changed renderable flag"
        CyrusShowSourceAccess context false;QRequire (QModel.isHidden and QModel.renderable==flag) "Hide changed renderable flag"
    )
 )
 "R6-M03": (
    QLayer.addPointSource();QRoot.bindNativeUI();QRoot.modelsUI.sourceUI_plantList.selection=#{1,2};QRoot.modelsUI.sourceUI_showSelectedColor()
    QRequire (not QRoot.modelsUI.sourceUI_editMaterial.enabled) "Mixed selection enabled material edit"
    local pointContext=CyrusCaptureSourceAccess QRoot QLayer #{2},error="";try(CyrusEditSourceMaterial pointContext)catch(error=getCurrentException())
    QRequire (error!="") "Point material edit was accepted"
 )
 "R6-M04": (
    local material=QModel.material,nodes=objects.count
    QClick QRoot.modelsUI.sourceUI_editMaterial
    QRequire (sme.GetMtlInParamEditor()==material and QModel.material==material and QModel.isHidden and objects.count==nodes) "Material editor changed source or opened a copy"
    local multi=multiMaterial numsubs:2;QModel.material=multi;CyrusEditSourceMaterial context
    QRequire (sme.GetMtlInParamEditor()==multi) "Multi/Sub root was not opened"
 )
 "R6-M05": (
    local shared=QModel.material,other=box material:shared pos:[2000,0,0]
    shared.diffuse=color 210 30 70;QSettle 500
    QRequire (other.material==shared and QModel.material==shared and other.material.diffuse==shared.diffuse) "Material instancing was broken"
 )
 "R6-M06": (
    QRoot.identificationMode=4;QRoot.setGroupDisplay 3;QRoot.refreshDisplay();QSettle 200
    local key=cyrusMaterialPreviewKey #(QModel),geometry=QLayer.procGeometryRevision
    QLayer.amount=500;QModel.material.diffuse=color 20 80 200;QRoot.refreshDisplay();QSettle 700
    QRequire (cyrusMaterialPreviewKey #(QModel)!=key and QLayer.procGeometryRevision==geometry) "Consumed appearance did not invalidate independently"
    QRequire (QRoot.procEpoch==epoch and QFingerprint()==before and QLayer.amount==500) "Material edit applied pending Manual population"
    key=cyrusMaterialPreviewKey #(QModel);QModel.material.opacity=65;QRoot.refreshDisplay();QSettle 200
    QRequire (cyrusMaterialPreviewKey #(QModel)!=key and QLayer.procGeometryRevision==geometry) "Consumed opacity did not invalidate only appearance"
    key=cyrusMaterialPreviewKey #(QModel);QModel.material.glossiness=.7;QRoot.refreshDisplay();QSettle 200
    QRequire (cyrusMaterialPreviewKey #(QModel)==key) "Unconsumed material input changed the appearance key"
 )
 "R6-M07": (
    local material=QModel.material
    with animate on (at time 0 material.diffuse=color 20 80 20;at time 10 material.diffuse=color 200 10 10)
    local frameKeys=#()
    for frame in #(0,5,10,0) do (sliderTime=frame;QSettle 200;append frameKeys (cyrusMaterialPreviewKey #(QModel)))
    QRequire (frameKeys[1]!=frameKeys[2] and frameKeys[1]==frameKeys[4]) "Scalar appearance animation/rewind key is incorrect"
    QRequire (QRoot.procEpoch==epoch and QFingerprint()==before) "Appearance animation rebuilt static Manual placements"
    sliderTime=0
    local sharedMap=noise size:25
    material.diffuseMap=sharedMap;material.diffuseMapEnable=true
    QLayer.densityMap=sharedMap;QLayer.distributionMode=3;QLayer.densityResolution=64
    QCalculate();local densityBefore=QFingerprint(),densityEpoch=QRoot.procEpoch
    sharedMap.size=80;QSettle 500
    QRequire (QFingerprint()==densityBefore and QRoot.procEpoch==densityEpoch) "Dual-role map edit implicitly applied Manual density"
    QCalculate();QRequire (QFingerprint()!=densityBefore and QRoot.procEpoch>densityEpoch) "Explicit Update ignored the same map's density role"
    before=QFingerprint();epoch=QRoot.procEpoch
 )
 "R6-M08": (
    QLayer.makePointSource 1;local error="";try(CyrusShowSourceAccess context true)catch(error=getCurrentException())
    QRequire (error!="" and QModel.isHidden) "Stale source identity was accepted"
 )
 "R6-M09": (
    CyrusShowSourceAccess context true;max undo;QRequire QModel.isHidden "Visibility Undo failed"
    max redo;QRequire (not QModel.isHidden and not QModel.renderable) "Visibility Redo changed source flags"
    local scene=MCPFixtureDir+"source-access.max",materialName=QModel.material.name
    saveMaxFile scene quiet:true;resetMaxFile #noPrompt;units.SystemType=#centimeters;loadMaxFile scene quiet:true
    QModel=getNodeByName "Q source";QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject
    QRequire (QModel.material.name==materialName and not QModel.isHidden and not QModel.renderable) "Source flags/material lost on reopen"
    QLayer=QRoot.selectedLayer();QCalculate();epoch=QRoot.procEpoch
 )
 "R6-M10": (
    QModel.material=undefined;local error="";try(CyrusEditSourceMaterial context)catch(error=getCurrentException())
    QRequire (error!="" and QModel.material==undefined) "Missing material created a replacement"
    QModel.material=standardMaterial();CyrusEditSourceMaterial context;QRequire (sme.GetMtlInParamEditor()==QModel.material) "Material access did not recover"
 )
 "R6-M11": (
    local material=QModel.material
    for i=1 to 30 do (CyrusEditSourceMaterial context;QRequire (sme.GetMtlInParamEditor()==material) "Repeated editor invocation changed instance")
 )
 default: throw ("Unknown source-access scenario: "+QScenarioID)
)
QRequire (QFingerprint()==before and QRoot.procEpoch==epoch) "Source access changed placement publication"
QAssert true (QScenarioID+"-01") "Source scene material and visibility ownership checks completed"
)

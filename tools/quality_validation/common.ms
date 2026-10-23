global QNode,QRoot,QLayer,QSurface,QModel,QGuide,QAnalyzer,QArea,QRequire,QSetup,QCalculate,QFingerprint,QRows,QMount,QClick,QSettle
fn QRequire value detail = (if not value do throw detail;true)
fn QSettle milliseconds = (
    local deadline=timeStamp()+milliseconds
    while timeStamp()<deadline do (windows.processPostedMessages();(dotNetClass "System.Windows.Forms.Application").DoEvents())
)
fn QCalculate = (QRoot.evaluateProcedural();for leaf in QRoot.layerObjects do QRequire (leaf.previewError=="") leaf.previewError)
fn QFingerprint = cyrusPlacementPublicationFingerprint QRoot.groupSnapshotRows QRoot.procPublishedRadii #("refinement") #()
fn QRows = (
    local data=QRoot.groupSnapshotRows[1],rows=#(),token=cyrusPlacementToken QRoot.groupSnapshotRows[1]
    QRequire (data.count<=2000) "Bounded fixture exceeded"
    if data.count>0 do for first=0 to (data.count-1) by 500 do
        join rows (cyrusPlacementPage data token first (if data.count-first>500 then 500 else data.count-first))
    rows
)
fn QSetup analyzer:false paint:false = (
    if not matchPattern MCPFixtureDir pattern:"*/build/*" do throw "Owned test profile required"
    resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1
    CyrusPerfHeadless=true;CyrusPointSuspended=true
    QSurface=plane name:"Q receiver" width:600 length:1000 widthsegs:4 lengthsegs:4
    QModel=box name:"Q source" width:3 length:3 height:5 pos:[1000,0,0]
    QModel.material=standardMaterial name:"Q material" diffuse:(color 30 130 50)
    QNode=AminScatterObject name:"Q Scatter";QRoot=QNode.baseObject;QRoot.updateMode=1;QRoot.autoRender=false
    QRoot.newLayer();QLayer=QRoot.selectedLayer();QRoot.setLayerSurfaces QLayer #(QSurface);QLayer.addModelSource QModel
    QLayer.amount=400;QLayer.procSelfOverride=true;QLayer.procSelfEnabled=false;QLayer.procLayerSelfEnabled=false
    if analyzer do (
        QGuide=CyrusSurfaceAnalyzer name:"Q Analyzer";QAnalyzer=QGuide.baseObject;QAnalyzer.surface=QSurface
        QAnalyzer.pointRadius=70;QAnalyzer.fitRadius=20;QAnalyzer.resolution=64;QAnalyzer.relaxIterations=0;QAnalyzer.updateMode=1;QAnalyzer.runAnalysis()
    )
    if paint do (QArea=QRoot.addPaintArea QLayer target:QSurface;QLayer.paintEnabled=true;cyrusBrushFill QArea.paintDocument 1.0)
    QCalculate();true
)
fn QMount pages:#("modelsUISlot","surfacesUISlot","layoutUISlot","spacingUISlot","coverageUISlot","managerUISlot") = (
    CyrusPerfHeadless=false;select QNode;max modify mode
    local deadline=timeStamp()+20000
    while not QRoot.mainUI.controlsReady and timeStamp()<deadline do QSettle 50
    QRequire QRoot.mainUI.controlsReady "Main UI did not mount"
    for slot in QRoot.mainUI.slots do slot.open=(findItem pages slot.name)>0
    QRoot.mainUI.bindEditors()
    deadline=timeStamp()+20000
    while QRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do QSettle 50
    QRequire (QRoot.mainUI.mountQueue.count==0) "Lazy pages did not settle"
    QRoot.bindNativeUI();QSettle 200
)
-- Max CustButton does not implement BM_CLICK. Exercise its actual native
-- mouse-message handler; this remains scripted notification, not physical input.
fn QClick control = (
    QRequire (control.hwnd.count>0 and control.enabled and control.visible) "Control is not mounted/enabled/visible"
    local handle=control.hwnd[1]
    windows.sendMessage handle 0x0201 1 0x000A000A
    windows.sendMessage handle 0x0202 0 0x000A000A
    QSettle 200
)

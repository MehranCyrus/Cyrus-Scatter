-- Disposable Max only. Loaded by run_host_tests.py through the owned transport.
global LTChecks=#(),LTAssert,LTRoot,LTLayer,LTArea,LTNode,LTExpected,LTPaintExpected
fn LTAssert condition label = (
    if not condition do throw ("Licensing 0.79: "+label)
    append LTChecks label
    local file=createFile (MCPFixtureDir+"licensing-checks.txt")
    for item in LTChecks do format "%\n" item to:file
    close file;true
)
fn LTRead path = trimRight (trimLeft ((dotNetClass "System.IO.File").ReadAllText path))
fn LTFingerprint = (cyrusEditFingerprint LTRoot.groupSnapshotRows[1] "licensing079")
fn LTBind = (
    LTNode=getNodeByName "LT_Controller";LTRoot=LTNode.baseObject;LTLayer=LTRoot.layerObjects[1];LTArea=LTLayer.paintAreas[1]
)
fn LTRender path = (
    renderers.current=Default_Scanline_Renderer()
    local result=render camera:(getNodeByName "LT_Camera") outputwidth:128 outputheight:128 vfb:false
    result.filename=path;save result;close result
)
fn LTCreate = (
    resetMaxFile #noPrompt
    viewport.setLayout #layout_1;viewport.setType #view_top
    local surfaceNode=plane name:"LT_Surface" width:200 length:200 widthsegs:2 lengthsegs:2
    surfaceNode.material=standardMaterial diffuse:(color 95 95 95)
    local model=box name:"LT_Model" width:4 length:4 height:15 pos:[1000,0,0]
    model.material=standardMaterial diffuse:(color 30 160 70)
    LTNode=AminScatterObject name:"LT_Controller";LTRoot=LTNode.baseObject
    LTRoot.setLayerTransfer true;LTRoot.updateMode=1;LTRoot.newLayer()
    LTLayer=LTRoot.selectedLayer();LTLayer.sources=#(model);LTLayer.sourceWeights=#(1.0);LTLayer.amount=100
    LTRoot.setLayerTransfer false;LTRoot.setLayerSurfaces LTLayer #(surfaceNode);LTRoot.refreshAll()
    LTAssert (LTRoot.groupSnapshotRows[1].count==100) "Licensed creation and procedural update"
    LTArea=LTRoot.addPaintArea LTLayer target:surfaceNode
    cyrusBrushFill LTArea.paintDocument 1;LTRoot.refreshAll()
    LTAssert (LTRoot.groupSnapshotRows[1].count==100) "Licensed vector Brush Fill"
    targetCamera name:"LT_Camera" pos:[260,-320,300] target:(targetObject name:"LT_Target" pos:[0,0,0])
    select LTNode;max modify mode;modPanel.setCurrentObject LTRoot
    if not LTRoot.mainUI.controlsReady do LTRoot.mainUI.mountTimer.tick()
    LTRoot.mainUI.licenseButton.pressed()
    LTAssert (CyrusLicenseDialog!=undefined) "Generated activation button opens panel"
    destroyDialog CyrusLicenseDialog
    LTExpected=LTFingerprint();LTPaintExpected=(cyrusBrushStats LTArea.paintDocument)[3]
    LTRender (MCPFixtureDir+"active.png")
    saveMaxFile (MCPFixtureDir+"licensed.max") quiet:true
    local file=createFile (MCPFixtureDir+"fingerprint.txt");format "%" LTExpected to:file;close file
)
fn LTLocked = (
    LTAssert (not cyrusLicenseAllows()) "Authority expires while Max remains open"
    local amount=LTLayer.amount,denied=false
    try(cyrusBrushDab LTArea.paintDocument [2,0,100] [0,0,-1] true)catch(denied=true)
    LTAssert (denied and (cyrusBrushStats LTArea.paintDocument)[6]==0 and (cyrusBrushStats LTArea.paintDocument)[3]==LTPaintExpected) "Expiry cancels staged stroke without changing completed contours"
    denied=false
    try(LTLayer.amount=999)catch(denied=true)
    LTAssert (LTLayer.amount==amount) "Direct scalar assignment denied before mutation"
    denied=false;try(LTRoot.newLayer())catch(denied=true)
    LTAssert (denied and LTRoot.layerObjects.count==1) "New layer denied before mutation"
    denied=false;try(LTRoot.refreshAll())catch(denied=true)
    LTAssert denied "Explicit authoring Update denied"
    denied=false;try(cyrusBrushFill LTArea.paintDocument 0)catch(denied=true)
    LTAssert (denied and (cyrusBrushStats LTArea.paintDocument)[3]==LTPaintExpected) "Native vector Fill denied and contours retained"
    denied=false;try(cyrusBrushDab LTArea.paintDocument [0,0,100] [0,0,-1] true)catch(denied=true)
    LTAssert denied "Native painting denied"
    LTLayer.refreshPreview()
    LTAssert (LTFingerprint()==LTExpected) "Expired viewport evaluation preserves exact publication"
    LTRender (MCPFixtureDir+"expired.png")
    saveMaxFile (MCPFixtureDir+"expired.max") quiet:true
    loadMaxFile (MCPFixtureDir+"expired.max") quiet:true;LTBind()
    LTRoot.refreshDisplay()
    LTAssert (LTFingerprint()==LTExpected) "Expired save and cold cache reopen preserves exact publication"
    LTRender (MCPFixtureDir+"reopened.png")
)

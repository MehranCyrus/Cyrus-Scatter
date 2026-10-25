(
    fn require ok message = (if not ok do throw message)
    fn write name value = ((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+name) value)
    fn analyzeWait doc id =
    (
        cvpAnalyze doc id .005 .05
        local count=0
        while cvpPoll doc do (windows.processPostedMessages();sleep .01;count+=1;if count>3000 do throw "Analysis timeout.")
    )
    cvlStage "source load"
    loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/Shrubs/A084 - Lavender - 05/model.max" quiet:true useFileUnits:true
    local source=getNodeByName "CyrusModel_A084",meter=units.decodeValue "1m"
    global CVPTestDoc=CVPDocument create:true
    local id=cvpAdd CVPTestDoc source
    cvlStage "native analysis"
    local sw=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
    analyzeWait CVPTestDoc id;sw.Stop()
    write "analysis.json" (cvpInfo CVPTestDoc id)
    write "analysis-wall-ms.txt" (sw.Elapsed.TotalMilliseconds as string)
    require (findString (cvpInfo CVPTestDoc id) "Needs review"!=undefined) "Analysis bypassed review."
    cvpAccept CVPTestDoc id
    require (findString (cvpInfo CVPTestDoc id) "Ready to prepare"!=undefined) "Review acceptance failed."
    cvlStage "acceptance Undo Redo"
    max undo
    require (findString (cvpInfo CVPTestDoc id) "Needs review"!=undefined) "Acceptance Undo failed."
    max redo
    require (findString (cvpInfo CVPTestDoc id) "Ready to prepare"!=undefined) "Acceptance Redo failed."
    cvlStage "prepare and automatic collider sweep"
    global CVPSphere=sphere name:"CVP_Test_Sphere" radius:(.167*meter) segments:48 pos:[.7*meter,.096*meter,.78*meter]
    CVPSphere.material=standardMaterial name:"Stone collider" diffuse:(color 148 144 136)
    local material=multiMaterial numsubs:4 name:"Botanical test materials"
    material[1]=standardMaterial name:"Woody stems" diffuse:(color 112 83 56)
    material[2]=standardMaterial name:"Green stems" diffuse:(color 91 123 63)
    material[3]=standardMaterial name:"Leaves" diffuse:(color 82 131 65) twoSided:true
    material[4]=standardMaterial name:"Flowers" diffuse:(color 146 104 179) twoSided:true
    source.material=material
    global CVPOutput
    undo "Prepare vegetation test" on (CVPOutput=cvpPrepare CVPTestDoc id CVPSphere)
    max undo
    require (not isValidNode (cvpNode CVPTestDoc id true)) "Prepare Undo left an output."
    max redo
    CVPOutput=cvpNode CVPTestDoc id true
    require (isValidNode CVPOutput) "Prepare Redo lost catalog output reference."
    setTransformLockFlags CVPOutput #{1..9}
    hide source;source.renderable=false
    viewport.setLayout #layout_1;viewport.setType #view_front;viewport.setRenderLevel #smoothhighlights
    select #(CVPOutput,CVPSphere);max zoomext sel all
    redrawViews()
    require ((getPolygonCount CVPOutput)[1]==69736) "Native preview topology mismatch."
    for x in #(.6,.55,.5,.47,.44,.42,.40,.38,.5,.7) do (CVPSphere.pos=[x*meter,.096*meter,.78*meter];redrawViews();getPolygonCount CVPOutput)
    write "sweep.json" (cvsStats CVPOutput)
    cvlStage "idle reuse"
    local before=cvsStats CVPOutput
    for i=1 to 20 do (redrawViews();getPolygonCount CVPOutput;cvpPoll CVPTestDoc;cvpInfo CVPTestDoc id)
    require (before==cvsStats CVPOutput) "Idle work counters changed."
    cvlStage "cancel retains prepared model"
    cvpAnalyze CVPTestDoc id .005 .05;cvpCancel CVPTestDoc
    while cvpPoll CVPTestDoc do (windows.processPostedMessages();sleep .01)
    require ((getPolygonCount CVPOutput)[1]==69736) "Cancelled analysis lost prepared result."
    write "cancel.json" (cvpInfo CVPTestDoc id)
    cvlStage "source change rejects in flight candidate"
    cvpAnalyze CVPTestDoc id .005 .05
    local rest=source.pos;source.pos=rest+[meter*.01,0,0]
    while cvpPoll CVPTestDoc do (windows.processPostedMessages();sleep .01)
    write "stale.json" (cvpInfo CVPTestDoc id)
    require (findString (cvpInfo CVPTestDoc id) "Stale"!=undefined) "Stale source was accepted."
    source.pos=rest
    analyzeWait CVPTestDoc id;cvpAccept CVPTestDoc id
    cvlStage "unsupported source"
    local unsupported=box name:"CVP_Unsupported_Box" length:meter width:meter height:meter
    local badid=cvpAdd CVPTestDoc unsupported
    analyzeWait CVPTestDoc badid
    require (findString (cvpInfo CVPTestDoc badid) "No supported"!=undefined) "Unsupported box silently rigged."
    delete unsupported
    cvpRemove CVPTestDoc badid
    require (cvpLabel CVPTestDoc badid=="") "Removed catalog row still visible."
    max undo
    require (cvpLabel CVPTestDoc badid!="") "Remove catalog row Undo failed."
    max redo
    cvlStage "full delivered mesh audit"
    CVPSphere.pos=[.42*meter,.096*meter,.78*meter];redrawViews();getPolygonCount CVPOutput
    write "audit.json" (cvsAudit CVPOutput)
    cvsMode CVPOutput 1;redrawViews();require ((getPolygonCount CVPOutput)[1]==832240) "Full viewport mismatch."
    cvsMode CVPOutput 0;redrawViews()
    cvlStage "save reopen catalog and poses"
    select CVPSphere;max move
    saveMaxFile (CVLTestDir+"Vegetation_Preparation_Max2027.max") quiet:true
    loadMaxFile (CVLTestDir+"Vegetation_Preparation_Max2027.max") quiet:true useFileUnits:true
    CVPTestDoc=CVPDocument();require (CVPTestDoc!=undefined) "Persistent catalog missing."
    CVPOutput=cvpNode CVPTestDoc id true;CVPSphere=getNodeByName "CVP_Test_Sphere"
    require (isValidNode CVPOutput) "Catalog output reference missing."
    require ((getPolygonCount CVPOutput)[1]==69736) "Reopened native preview missing."
    write "reopened.json" (cvpInfo CVPTestDoc id)
    CVPSphere.pos=[.47*meter,.096*meter,.78*meter];redrawViews();getPolygonCount CVPOutput
    write "reopened-moved.json" (cvsStats CVPOutput)
    cvlStage "review UI overlay"
    CVPOpen();CVPDialog.pickCollider.object=CVPSphere
    CVPDialog.showGuides.checked=true;CVPOverlayCallback();redrawViews()
    write "ui-open.txt" "true"
    CVPDialog.showGuides.checked=false
    cvlStage "render full geometry"
    local cam=targetCamera name:"CVP_TestCamera" pos:[-1.8*meter,-2.3*meter,1.45*meter] target:(targetObject pos:[.12*meter,0,.5*meter]) fov:42
    renderers.current=Default_Scanline_Renderer();ambientLight=color 45 45 45
    omniLight name:"CVP_Key" pos:[-2*meter,-2*meter,3*meter] multiplier:.8
    omniLight name:"CVP_Fill" pos:[2*meter,-meter,meter] multiplier:.5
    render camera:cam outputfile:(CVLTestDir+"Prepared_Lavender.png") vfb:false outputwidth:1100 outputheight:850
    write "rendered.json" (cvsStats CVPOutput)
    select CVPSphere;max move
    saveMaxFile (CVLTestDir+"Vegetation_Preparation_Max2027.max") quiet:true
    cvlStage "done"
)

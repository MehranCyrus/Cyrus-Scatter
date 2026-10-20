/* Owned normal Max2027. Full newly modeled sedan, actual Modify handlers,
   world-mm mesh exports, unit conversion and native Scanline renders. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global CyrusArrange,caModifierUI,caModifierViewOwner,caRCControls
global caRCMakeCar,caRCMakeRoad,caRCMakeCurve
global caRCLog=#(),caRCPasses=0,caRCFailures=0,caRCFinished=false,caRCUnit=1.0
fn caRCWrite=(local f=createFile(CA_TEST_OUTPUT+"result.txt");format "% passes=% failures=%\n"(if caRCFinished then(if caRCFailures==0 then "SUCCESS" else "ERROR")else "RUNNING")caRCPasses caRCFailures to:f;for line in caRCLog do format "%\n"line to:f;close f)
fn caRCCheck label value=(if value then caRCPasses+=1 else caRCFailures+=1;append caRCLog((if value then "PASS " else "FAIL ")+label);caRCWrite();if not value do throw("Road scene: "+label);value)
fn caRCMeasure label start=(append caRCLog("MEASURE "+label+"="+((timeStamp()-start)as string));caRCWrite())
fn caRCPose owner=for r in(caOutputRows owner)collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
fn caRCEqual a b=deepEqual a b strictCompare:true
fn caRCMesh node=(local m=undefined;in coordsys world(m=snapshotAsMesh node renderMesh:false);if m==undefined or m.numverts>20000 or m.numfaces>40000 do throw "Road mesh admission";m)
fn caRCBounds m=(local low=[1e30,1e30,1e30],high=[-1e30,-1e30,-1e30];for i=1 to m.numverts do(local p=(getVert m i)*caRCUnit;for k=1 to 3 do(low[k]=amin low[k]p[k];high[k]=amax high[k]p[k]));#(low,high))
fn caRCSignature node=
(
    local m=caRCMesh node,result=#(node.transform as string,node.material,for i=1 to m.numverts collect(getVert m i),for i=1 to m.numfaces collect #((getFace m i),(getFaceMatID m i),(getFaceSmoothGroup m i)))
    delete m;result
)
fn caRCOpen node=
(
    max modify mode;modPanel.setPinStack false;select node
    local modifier=undefined;for m in node.modifiers where classOf m==CyrusArrange do modifier=m
    if modifier==undefined do throw "Missing Cyrus Arrange modifier."
    modPanel.setCurrentObject modifier node:node ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caModifierUI!=undefined and caModifierUI.currentSetup()==node and caModifierUI.hwnd!=0
)
fn caRCVisual source owner=
(
    local original=caRCMesh source,valid=true,uvCorners=0
    for row in(caOutputRows owner)do
    (
        local m=caRCMesh row[9]
        if m.numverts!=original.numverts or m.numfaces!=original.numfaces or row[9].material!=source.material do valid=false
        for i=1 to original.numfaces do
        (
            if(getFace original i)!=(getFace m i)or(getFaceMatID original i)!=(getFaceMatID m i)or(getFaceSmoothGroup original i)!=(getFaceSmoothGroup m i)do valid=false
            if not(meshop.getMapSupport m 1)then valid=false
            else(local a=meshop.getMapFace original 1 i,b=meshop.getMapFace m 1 i;for k=1 to 3 do(if(meshop.getMapVert original 1 a[k])!=(meshop.getMapVert m 1 b[k])do valid=false;uvCorners+=1))
        )
        delete m
    )
    delete original;valid and uvCorners>0
)
fn caRCExport label receivers source owner=
(
    local f=createFile(CA_TEST_OUTPUT+label+"-meshes.txt"),rows=caOutputRows owner,assets=caAssetRows owner
    for kind in #("receiver","source","output")do
    (
        local nodes=case kind of("receiver":receivers;"source":#(source);"output":for r in rows collect r[9])
        for i=1 to nodes.count do
        (
            local m=caRCMesh nodes[i]
            format "mesh % % % %\n"kind i m.numverts m.numfaces to:f
            for j=1 to m.numverts do(local p=(getVert m j)*caRCUnit;format "v % % %\n"(formattedPrint(p.x as double)format:".17g")(formattedPrint(p.y as double)format:".17g")(formattedPrint(p.z as double)format:".17g")to:f)
            for j=1 to m.numfaces do(local t=getFace m j;format "f % % % % %\n"(t.x as integer)(t.y as integer)(t.z as integer)(getFaceMatID m j)(getFaceSmoothGroup m j)to:f)
            if kind=="source"do(local b=caRCBounds m,a=(caAssetSupport owner assets[1][1])[1]+[(b[1].x+b[2].x)*.5,(b[1].y+b[2].y)*.5,b[1].z];format "anchor % % %\n"(formattedPrint(a.x as double)format:".17g")(formattedPrint(a.y as double)format:".17g")(formattedPrint(a.z as double)format:".17g")to:f)
            if kind=="output"do(local r=rows[i];format "pose 1 % % % % % % %\n"r[1](formattedPrint(r[4].x as double)format:".17g")(formattedPrint(r[4].y as double)format:".17g")(formattedPrint(r[4].z as double)format:".17g")(formattedPrint r[5]format:".17g")(formattedPrint r[6]format:".17g")r[8]to:f)
            format "end\n"to:f;delete m
        )
    );close f
    f=createFile(CA_TEST_OUTPUT+label+"-settings.txt")
    local a=caPlacementSettings owner,p=(caPathSettings owner)[2]
    format "seed %\namount %\ncounts % %\noffsets % %\nwidths % %\nspacing % %\njitter % %\nscale % %\nedge %\ngap %\nunit %\ninsets % %\n"a[1]a[2]a[3]p[10]p[6]p[11]p[7]p[12]p[8]p[13]p[18]p[19]a[9]a[10]a[6]a[5]caRCUnit p[16]p[17] to:f
    local pathNode=(caPathSettings owner)[1],controls=undefined
    in coordsys world(controls=#((getKnotPoint pathNode 1 1),(getOutVec pathNode 1 1),(getInVec pathNode 1 2),(getKnotPoint pathNode 1 2)))
    for c in controls do(local q=c*caRCUnit;format "control % % %\n"(formattedPrint(q.x as double)format:".17g")(formattedPrint(q.y as double)format:".17g")(formattedPrint(q.z as double)format:".17g")to:f)
    for i=1 to rows.count do format "region % %\n"i rows[i][3] to:f
    close f;true
)
fn caRCConfigure owner=
(
    local view=caModifierViewOwner,p=caModifierViewOwner.pathControls
    caModifierUI.amountMode.selection=1;view.amountChanged 1;caModifierUI.quantity.value=3;caModifierUI.spacing.value=100
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true;caModifierUI.seedText.text="7712032"
    view.protectionControls.edgeGap.value=10;view.protectionControls.edgeGap.changed 10
    p.align.checked=true;p.align.changed true;p.frontAxis.selection=1;p.reverse.checked=false
    p.twoWay.checked=true;p.twoWay.changed true;p.offset.value=1750;p.laneWidth.value=3200;p.limitWidth.checked=true
    p.rightCopies.value=3;p.rightOffset.value=-1750;p.rightWidth.value=3200;p.opposite.checked=true
    p.sideways.value=0;p.along.value=0
    view.scaleControls.randomScale.checked=false;view.scaleControls.randomScale.changed false;view.scaleControls.fitScale.checked=false;view.scaleControls.fitScale.changed false
    true
)
fn caRCCamera name position target=
(
    local aim=targetObject name:(name+"_Target")pos:target
    targetCamera name:name pos:position target:aim fov:50
)
fn caRCRender owner=
(
    max create mode
    local ground=box name:"ROAD_Background_Ground"width:80000 length:60000 height:20 pos:[15000,10000,-220]
    ground.material=standardMaterial name:"ROAD_Ground_Material"diffuse:(color 95 115 86)
    local key=omniLight name:"ROAD_Key"pos:[15000,-10000,25000]multiplier:1.1;key.baseObject.castShadows=true;key.shadowGenerator=raytraceShadow()
    omniLight name:"ROAD_Fill"pos:[5000,30000,20000]multiplier:.45
    ambientLight=color 25 25 25;backgroundColor=color 165 185 200
    local overview=caRCCamera "ROAD_Overview" [30000,-25000,35000] [15000,10000,0]
    local target=(caOutputRows owner)[2][4]+[0,0,600],detail=caRCCamera "ROAD_Car_Detail"(target+[-6500,-8500,4500])target
    renderers.current=Default_Scanline_Renderer();renderWidth=1600;renderHeight=1100
    local started=timeStamp(),b=render camera:overview outputFile:(CA_TEST_OUTPUT+"CyrusArrange-Road-Overview.png")vfb:false
    caRCCheck "Actual Scanline overview renders at the declared dimensions"(b.width==1600 and b.height==1100);close b;caRCMeasure "overview_render_ms"started
    renderWidth=1400;renderHeight=1000;started=timeStamp();b=render camera:detail outputFile:(CA_TEST_OUTPUT+"CyrusArrange-Car-Detail.png")vfb:false
    caRCCheck "Actual complete-car detail render succeeds"(b.width==1400 and b.height==1000);close b;caRCMeasure "detail_render_ms"started
    true
)
fn caRCRun=
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;caRCUnit=1;CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms")do fileIn(CA_TEST_ROOT+"scripts/"+script)
    fileIn(CA_TEST_ROOT+"tests/max/road_car_fixture.ms")
    caRCCheck "Exact native in owned normal Max2027"(caVersion()=="0.3.2"and(maxVersion())[1]==29000 and not maxOps.isInNonInteractiveMode())
    local source=caRCMakeCar(),road=caRCMakeRoad(),curve=caRCMakeCurve(),owner=caCreateArrangement();owner.name="ROAD_Cyrus_Arrange"
    local original=caRCSignature source,m=caRCMesh source,b=caRCBounds m
    caRCCheck "Complete source has literal sedan dimensions and detailed body wheels rims and cabin"(m.numverts>1000 and m.numfaces>2000 and distance(b[2]-b[1]) [4520,1900,1500]<.03 and source.material.numsubs==6);delete m
    caBindReceivers owner road
    caRCCheck "Actual native modifier mounts on the road arrangement"(caRCOpen owner)
    local view=caModifierViewOwner,started=timeStamp()
    caRCCheck "Inline commands bind the curve and complete car source without generating"(view.dispatch #bindPath data:curve and view.dispatch #addProps data:#(source)and(caOutputRows owner).count==0 and(caGeometryCacheInfo owner)[3]==undefined)
    caRCMeasure "source_capture_ms"started;caRCConfigure owner
    local support=caAssetSupport owner(caAssetRows owner)[1][1]
    caRCCheck "Native contact anchor follows axle center instead of body center"(abs(support[1].x-100)<.02 and abs(support[1].y)<.02 and support[2].count>=4)
    started=timeStamp();caRCCheck "Actual Generate places three complete original-size cars in each direction"(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==6 and(caPathSettings owner)[3][1]==3 and(caPathSettings owner)[3][2]==3);caRCMeasure "cold_generate_ms"started
    caRCCheck "All six full meshes preserve exact source topology materials smoothing and UV corners"(caRCVisual source owner)
    caRCExport "original"road source owner
    local pose=caRCPose owner,settings=caPlacementSettings owner,pathSettings=(caPathSettings owner)[2]
    started=timeStamp();caRCCheck "Repeat seed reproduces every complete car pose and scale"(caModifierUI.generateButton.pressed()and caRCEqual pose(caRCPose owner));caRCMeasure "warm_generate_ms"started
    local metrics=(caGeometryCacheInfo owner)[3],commands=(caGeometryCacheInfo owner)[3][12]
    append caRCLog("CACHE warm="+(metrics as string));caRCWrite()
    caModifierUI.onRefresh preserveDrafts:true
    caRCCheck "Passive Modify refresh performs no generation"((caGeometryCacheInfo owner)[3][12]==commands)
    view.scaleControls.randomScale.checked=true;view.scaleControls.randomScale.changed true;view.scaleControls.minimumScale.value=80;view.scaleControls.maximumScale.value=110
    view.pathControls.sideways.value=300;view.pathControls.along.value=2000
    caRCCheck "Inline random scale and local path spread generate six validated cars"(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==6)
    caRCCheck "The real random-sized cars preserve all authored appearance data"(caRCVisual source owner)
    caRCExport "variation"road source owner
    local variation=caRCPose owner,variationSettings=caPlacementSettings owner,variationPath=(caPathSettings owner)[2]
    caModifierUI.keepSeed.checked=false;caModifierUI.keepSeed.changed false
    caRCCheck "Generate selects a fresh saved seed for the same complete-car setup"(caModifierUI.generateButton.pressed()and(caPlacementSettings owner)[1]!=variationSettings[1])
    max undo
    caRCCheck "One Undo restores all variation fields seed and complete mesh poses"(caRCEqual variation(caRCPose owner)and caRCEqual variationSettings(caPlacementSettings owner)and caRCEqual variationPath((caPathSettings owner)[2]))
    max redo
    caRCCheck "Redo restores six complete cars and the new saved variation"((caOutputRows owner).count==6 and(caPlacementSettings owner)[1]!=variationSettings[1])
    caRCCheck "Generating variations preserves the complete original source"(caRCEqual original(caRCSignature source))
    caRCRender owner
    local scene=CA_TEST_OUTPUT+"CyrusArrange-TwoWay-Cars-032.max",saved=caPlacementSettings owner,savedPath=(caPathSettings owner)[2],savedPose=caRCPose owner
    caRCCheck "Complete inspectable six-car curved-road scene saves"(saveMaxFile scene quiet:true)
    loadMaxFile scene quiet:true useFileUnits:true;owner=getNodeByName "ROAD_Cyrus_Arrange";source=getNodeByName "ROAD_Original_Sedan"
    road=for name in #("ROAD_Right_Shoulder","ROAD_Right_Lane","ROAD_Median","ROAD_Left_Lane","ROAD_Left_Shoulder")collect(getNodeByName name)
    caRCCheck "Reopen retains actual centerline fields seed and all six complete cars"(caRCEqual saved(caPlacementSettings owner)and caRCEqual savedPath((caPathSettings owner)[2])and caRCEqual savedPose(caRCPose owner)and caRCOpen owner)
    view=caModifierViewOwner;caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caRCCheck "Reopened Generate repeats the accepted six-car result"(caModifierUI.generateButton.pressed()and caRCEqual savedPose(caRCPose owner))
    local protectedID=(caOutputRows owner)[1][1],protectedPose=(caRCPose owner)[1]
    modPanel.setPinStack true;select((caOutputRows owner)[1][9])
    caRCCheck "Inline Protect selected captures an actual complete car"(view.protectionControls.lockSelected.pressed()and(caOutputRows owner)[1][7])
    local captured=(caRCPose owner)[1]
    caRCCheck "Protection captures the real Max transform within its float precision"(captured[1]==protectedPose[1] and captured[2]==protectedPose[2] and captured[3]==protectedPose[3] and distance captured[4] protectedPose[4]<.01 and abs(captured[5]-protectedPose[5])<.0001 and abs(captured[6]-protectedPose[6])<.000001 and captured[7] and captured[8]==protectedPose[8])
    protectedPose=captured;caRCOpen owner;view=caModifierViewOwner
    local beforeProtected=caRCPose owner,beforeProtectedSeed=(caPlacementSettings owner)[1]
    caModifierUI.keepSeed.checked=false;caModifierUI.keepSeed.changed false
    caRCCheck "Fresh Generate retains six complete cars and changes the saved seed"(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==6 and(caPlacementSettings owner)[1]!=beforeProtectedSeed)
    local found=false;for row in(caRCPose owner)where row[1]==protectedID do found=caRCEqual row protectedPose
    caRCCheck "Protected stable identity pose scale and lane remain exact"found
    caRCCheck "Fresh variation actually changes unlocked cars and preserves complete source appearance"(not(caRCEqual beforeProtected(caRCPose owner))and caRCVisual source owner)
    caSetLocked owner #(protectedID)false;caModifierUI.onRefresh()
    view=caModifierViewOwner;view.scaleControls.randomScale.checked=false;view.scaleControls.randomScale.changed false;view.scaleControls.fitScale.checked=true;view.scaleControls.fitScale.changed true;view.scaleControls.minimumScale.value=60
    view.pathControls.sideways.value=0;view.pathControls.along.value=0;view.pathControls.laneWidth.value=1600;view.pathControls.rightWidth.value=1600
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caRCCheck "Narrow lanes accept six uniformly fitted complete cars"(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==6)
    local fits=true;for row in(caOutputRows owner)do if row[6]<.6 or row[6]>.85 do fits=false
    caRCCheck "Every fitted size respects the permitted range and complete source appearance"(fits and caRCVisual source owner)
    caRCExport "fit"road source owner
    view.scaleControls.minimumScale.value=100;view.pathControls.laneWidth.value=1200;view.pathControls.rightWidth.value=1200
    caRCCheck "An impossible minimum reports six unfilled instead of forcing cars across lane edges"(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==0 and findString caModifierUI.statusText.text "6 unfilled"!=undefined)
    local report=caFitFeedback owner(caAssetRows owner)[1][1]
    caRCCheck "Actual path fit feedback explains the lane limitation"(report[1]and report[3]==10)
    caRCOpen owner;view=caModifierViewOwner;view.scaleControls.fitScale.checked=false;view.scaleControls.fitScale.changed false;view.pathControls.laneWidth.value=3200;view.pathControls.rightWidth.value=3200
    caModifierUI.amountMode.selection=2;view.amountChanged 2;view.pathControls.centerSpacing.value=6000;view.pathControls.rightSpacing.value=6500
    caRCCheck "Actual amount dropdown enables spacing for both directions"(not caModifierUI.quantity.enabled and view.pathControls.centerSpacing.visible and view.pathControls.rightSpacing.visible)
    caRCCheck "Center-spacing mode places complete cars in both lanes"(caModifierUI.generateButton.pressed()and(caOutputRows owner).count>=10 and(caPathSettings owner)[3][1]>0 and(caPathSettings owner)[3][2]>0)
    caRCExport "spacing"road source owner
    for unitCase in #(#centimeters,#inches)do
    (
        max create mode;units.SystemType=unitCase;units.SystemScale=1
        loadMaxFile scene quiet:true useFileUnits:false
        caRCUnit=if unitCase==#centimeters then 10.0 else 25.4
        owner=getNodeByName "ROAD_Cyrus_Arrange";source=getNodeByName "ROAD_Original_Sedan"
        road=for name in #("ROAD_Right_Shoulder","ROAD_Right_Lane","ROAD_Median","ROAD_Left_Lane","ROAD_Left_Shoulder")collect(getNodeByName name)
        local label=if unitCase==#centimeters then "centimetres" else "inches",before=caRCSignature source
        caRCCheck(label+" load keeps current system units and unchanged physical native settings")(units.SystemType==unitCase and caRCEqual saved(caPlacementSettings owner)and caRCEqual savedPath((caPathSettings owner)[2])and caRCOpen owner)
        view=caModifierViewOwner;caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
        caRCCheck(label+" actual Generate places six full cars at valid saved scales")(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==6 and caRCVisual source owner)
        caRCCheck(label+" conversion preserves source transform geometry and materials during generation")(caRCEqual before(caRCSignature source))
        caRCExport label road source owner
    )
    append caRCLog "LIMIT: newly modeled sedan and static flat-Z curved road; independent triangle/lane proof required. Scanline images do not qualify other renderers, dynamics or mouse gestures."
    true
)
try(caRCRun())catch(caRCFailures+=1;append caRCLog("EXCEPTION "+(getCurrentException()as string));append caRCLog("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caRCLog("STACK "+(getCurrentExceptionStackTrace()as string)))
caRCFinished=true;caRCWrite()

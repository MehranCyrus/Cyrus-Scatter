/* Owned normal Max2027: current command errors must not become authored Undo
   state. Actual mounted Modify controls; no computer use or artist session. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global CyrusArrange,caModifierUI,caModifierViewOwner
global caSULog=#(),caSUPasses=0,caSUFailures=0,caSUFinished=false
fn caSUWrite=(local f=createFile(CA_TEST_OUTPUT+"result.txt");format "% passes=% failures=%\n"(if caSUFinished then(if caSUFailures==0 then "SUCCESS" else "ERROR")else "RUNNING")caSUPasses caSUFailures to:f;for line in caSULog do format "%\n"line to:f;close f)
fn caSUCheck label value=(if value then caSUPasses+=1 else caSUFailures+=1;append caSULog((if value then "PASS " else "FAIL ")+label);caSUWrite();if not value do throw("Modify status: "+label);value)
fn caSUPose owner=for r in(caOutputRows owner)collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
fn caSURecovered owner rejected=
(
    local s=caSetupSummary owner,currentNotice=s[6]!=0 and findItem #("Scene inputs changed. Generate to refresh placements.","Scene loaded. Generate to refresh placement checks.")s[8]>0
    (s[8]==""or currentNotice)and findString s[8]rejected==undefined
)
fn caSUOpen node=
(
    max modify mode;modPanel.setPinStack false;select node
    local modifier=undefined
    for m in node.modifiers where classOf m==CyrusArrange do modifier=m
    if modifier==undefined do throw "Missing native modifier."
    modPanel.setCurrentObject modifier node:node ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caModifierUI!=undefined and caModifierUI.hwnd!=0 and caModifierUI.currentSetup()==node
)
fn caSUScenario pathMode=
(
    local label=if pathMode then "Path" else "Surface"
    local source=box name:("SU_"+label+"_Source")width:30 length:50 height:80 pos:[10000,5000,0]
    local sourceTM=source.transform as string,owner=caCreateArrangement();owner.name="SU_"+label+"_Arrangement"
    if pathMode then
    (
        local curve=splineShape name:"SU_Path";addNewSpline curve;addKnot curve 1 #corner #line [0,5000,0];addKnot curve 1 #corner #line [6000,5000,0];updateShape curve
        caBindPath owner curve 1
    )
    else(local receiver=box name:"SU_Surface"width:1000 length:1000 height:20 pos:[0,0,0];caBindReceivers owner #(receiver))
    caRegisterAssets owner #(source) 7
    caSUCheck(label+" actually mounts native Modify controls")(caSUOpen owner)
    local attribute=caModifierViewOwner
    caModifierUI.quantity.value=3;caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    attribute.scaleControls.randomScale.checked=true;attribute.scaleControls.randomScale.changed true
    attribute.scaleControls.minimumScale.value=80;attribute.scaleControls.maximumScale.value=110
    caSUCheck(label+" first actual Generate creates a valid complete result")(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==3 and(caSetupSummary owner)[8]=="")
    local accepted=caPlacementSettings owner,pose=caSUPose owner,revision=(caSetupSummary owner)[3]
    attribute.scaleControls.minimumScale.value=120;attribute.scaleControls.maximumScale.value=80
    caSUCheck(label+" invalid draft fails and exposes its current native/view error")(not caModifierUI.generateButton.pressed()and(caSetupSummary owner)[8]!=""and caModifierUI.errorMessage()!="")
    local oldError=(caSetupSummary owner)[8]
    caSUCheck(label+" failed command retains all accepted values poses seed and revision")(deepEqual accepted(caPlacementSettings owner)and deepEqual pose(caSUPose owner)and(caSetupSummary owner)[3]==revision)
    attribute.scaleControls.minimumScale.value=90;attribute.scaleControls.maximumScale.value=100;caModifierUI.quantity.value=4
    caSUCheck(label+" corrected draft succeeds and clears the current error")(caModifierUI.generateButton.pressed()and(caOutputRows owner).count==4 and(caSetupSummary owner)[8]==""and caModifierUI.errorMessage()=="")
    local nextSettings=caPlacementSettings owner,nextPose=caSUPose owner,commands=(caGeometryCacheInfo owner)[3][12]
    max undo
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caSUCheck(label+" Undo restores complete accepted values poses and seed")(deepEqual accepted(caPlacementSettings owner)and deepEqual pose(caSUPose owner))
    append caSULog("OBSERVED "+label+" previous_error="+oldError+" native_after_undo="+((caSetupSummary owner)[8])+" visible_after_undo="+caModifierUI.statusText.text);caSUWrite()
    caSUCheck(label+" Undo never revives the obsolete rejected-draft error")(caSURecovered owner oldError and findString caModifierUI.statusText.text oldError==undefined and caModifierUI.errorMessage()=="")
    caSUCheck(label+" Undo refreshes accepted scale/copies without solving")(caModifierUI.quantity.value==3 and attribute.scaleControls.minimumScale.value==80 and attribute.scaleControls.maximumScale.value==110 and(caGeometryCacheInfo owner)[3][12]==commands)
    max redo
    local redoSettings=caPlacementSettings owner,redoPose=caSUPose owner,redoError=(caSetupSummary owner)[8]
    append caSULog("OBSERVED "+label+" redo_native_settings="+((deepEqual nextSettings redoSettings)as string)+" redo_native_poses="+((deepEqual nextPose redoPose)as string)+" redo_native_error="+redoError+" redo_copies_before_UI_queue="+(caModifierUI.quantity.value as string));caSUWrite()
    caSUCheck(label+" Redo immediately restores complete native settings seed and poses")(deepEqual nextSettings redoSettings and deepEqual nextPose redoPose)
    -- Like Undo and initial mounting, observe controls after posted Qt work.
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    append caSULog("OBSERVED "+label+" redo_copies_after_UI_queue="+(caModifierUI.quantity.value as string)+" redo_error_after_UI_queue="+((caSetupSummary owner)[8]));caSUWrite()
    caSUCheck(label+" Redo preserves current pending notices but never the rejected-draft error")(caSURecovered owner oldError and findString caModifierUI.statusText.text oldError==undefined and caModifierUI.quantity.value==4 and(caGeometryCacheInfo owner)[3][12]==commands)
    caModifierUI.quantity.value=5
    caModifierUI.onRefresh preserveDrafts:true
    caSUCheck(label+" passive refresh retains genuine drafts without reviving history or solving")(caModifierUI.quantity.value==5 and(caPlacementSettings owner)[3]==4 and caSURecovered owner oldError and(caGeometryCacheInfo owner)[3][12]==commands)
    caSUCheck(label+" source transform remains unchanged")((source.transform as string)==sourceTM)
    owner
)
fn caSURun=
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms")do fileIn(CA_TEST_ROOT+"scripts/"+script)
    caSUCheck "Exact 0.3.2 native in an owned normal Max2027 host"((maxVersion())[1]==29000 and caVersion()=="0.3.2"and not maxOps.isInNonInteractiveMode())
    caSUScenario false
    local owner=caSUScenario true,name=owner.name,saved=caPlacementSettings owner,poses=caSUPose owner
    max create mode
    caSUCheck "Save accepted path state while the uncommitted Copies draft is discarded"(saveMaxFile(CA_TEST_OUTPUT+"status-undo.max")quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"status-undo.max")quiet:true useFileUnits:true;owner=getNodeByName name
    caSUCheck "Reopen preserves accepted settings seed and poses with its current validation notice"(deepEqual saved(caPlacementSettings owner)and deepEqual poses(caSUPose owner)and(caSetupSummary owner)[6]!=0 and caSURecovered owner "Invalid saved quantity or uniform scale range.")
    caSUCheck "Reopened actual Modify shows accepted Copies and scale with no old draft error"(caSUOpen owner and caModifierUI.quantity.value==4 and caModifierViewOwner.scaleControls.minimumScale.value==90 and caModifierViewOwner.scaleControls.maximumScale.value==100 and caModifierUI.errorMessage()=="")
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caSUCheck "Explicit validation Generate clears the load notice and repeats the accepted native result"(caModifierUI.generateButton.pressed()and(caSetupSummary owner)[8]==""and deepEqual saved(caPlacementSettings owner)and deepEqual poses(caSUPose owner))
    local source=getNodeByName "SU_Path_Source",commands=(caGeometryCacheInfo owner)[3][12]
    source.pos+=[1,0,0];caModifierUI.onRefresh preserveDrafts:true
    caSUCheck "A real Manual source edit shows the current Generate action without solving"((caSetupSummary owner)[6]!=0 and(caSetupSummary owner)[8]=="Scene inputs changed. Generate to refresh placements."and findString caModifierUI.statusText.text "Generate"!=undefined and(caGeometryCacheInfo owner)[3][12]==commands)
    caSUCheck "Generate after that real edit clears its fresh notice and retains accepted settings and poses"(caModifierUI.generateButton.pressed()and(caSetupSummary owner)[8]==""and deepEqual saved(caPlacementSettings owner)and deepEqual poses(caSUPose owner))
    append caSULog "LIMIT: actual handlers/state/status are checked; mouse gesture, rendered pixels and final installer remain separate."
    true
)
try(caSURun())catch(caSUFailures+=1;append caSULog("EXCEPTION "+(getCurrentException()as string));append caSULog("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caSULog("STACK "+(getCurrentExceptionStackTrace()as string)))
caSUFinished=true;caSUWrite()

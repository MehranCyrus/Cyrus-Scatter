/* Owned normal Max2027: actual Modify controls, native feedback and native
   display callback. No computer use, artist session or renderer claim. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global CyrusArrange, caModifierUI, caModifierViewOwner
global caCreateArrangement, caBindReceivers, caRegisterAssets, caAddObstacles
global caFitFeedback, caFitHighlightInfo, caShowFitFeedback, caHideFitFeedback
global caPlacementSettings, caOutputRows, caAssetRows, caSetupSummary, caGeometryCacheInfo
global caPreview, caPreviewInfo, caSceneSetups
global caFFLog=#(),caFFPasses=0,caFFFailures=0,caFFFinished=false
fn caFFWrite=(local f=createFile(CA_TEST_OUTPUT+"result.txt");format "% passes=% failures=%\n"(if caFFFinished then(if caFFFailures==0 then "SUCCESS" else "ERROR")else "RUNNING")caFFPasses caFFFailures to:f;for line in caFFLog do format "%\n"line to:f;close f)
fn caFFCheck label value=(if value then caFFPasses+=1 else caFFFailures+=1;append caFFLog((if value then "PASS " else "FAIL ")+label);caFFWrite();if not value do throw("Fit feedback: "+label);value)
fn caFFOpen node=
(
    max modify mode;modPanel.setPinStack false;select node
    local modifier=undefined
    for m in node.modifiers where classOf m==CyrusArrange do modifier=m
    if modifier==undefined do throw "Missing native modifier."
    modPanel.setCurrentObject modifier node:node ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caModifierUI!=undefined and caModifierUI.hwnd!=0 and caModifierUI.currentSetup()==node
)
fn caFFNoPopups=
(
    for name in #(#caHomeUI,#caHomePropsUI,#caArrangeUI,#caAssetUI,#caUI,#caRegionUI,#caCollisionUI,#caCompositionUI,#caRulesUI)do
    (local view=globalVars.get name;if view!=undefined do if view.isDisplayed do return false)
    true
)
fn caFFFits view=
(
    local page=windows.getWindowPos view.hwnd removeUIScaling:false, origin=windows.clientToScreen view.hwnd 0 0 applyUIScaling:false
    for control in view.controls where control.visible do for handle in control.hwnd do
    (local r=windows.getWindowPos handle removeUIScaling:false;if r.x<origin.x or r.x+r.w>page.x+page.w do(append caFFLog("LAYOUT "+(control as string)+" rect="+(r as string)+" origin="+(origin as string)+" page="+(page as string));caFFWrite();return false))
    true
)
fn caFFRun=
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms")do fileIn(CA_TEST_ROOT+"scripts/"+script)
    caFFCheck "Exact 0.3.2 native in an owned normal Max2027 host" ((maxVersion())[1]==29000 and not maxOps.isInNonInteractiveMode())
    local origin=[50000,32000,7000]
    local floor=box name:"FF_Cabinet_Base" width:600 length:400 height:20 pos:origin
    local roof=box name:"FF_Cabinet_Roof" width:600 length:400 height:20 pos:(origin+[0,0,300])
    local source=box name:"FF_Coffee_Device" width:100 length:100 height:450 pos:(origin+[3000,0,0])
    source.material=standardMaterial name:"FF_Device_Material" diffuse:(color 30 90 160)
    local sourceTM=source.transform as string,sourceBounds=nodeGetBoundingBox source(matrix3 1)
    local owner=caCreateArrangement();owner.name="FF_Arrangement";caBindReceivers owner #(floor);caRegisterAssets owner #(source) 7;caAddObstacles owner #(roof)
    caFFCheck "Original device mounts with no feedback calculation before Generate" (caFFOpen owner and not(caFitFeedback owner(caAssetRows owner)[1][1])[1] and(caGeometryCacheInfo owner)[3]==undefined)
    local attribute=caModifierViewOwner,id=(caAssetRows owner)[1][1]
    caModifierUI.quantity.value=1;caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caFFCheck "Actual Generate reports the original-size cabinet failure" (caModifierUI.generateButton.pressed() and(caOutputRows owner).count==0)
    local report=caFitFeedback owner id,accepted=caPlacementSettings owner,revision=(caSetupSummary owner)[3]
    caFFCheck "Native report identifies actual overhead clearance and checked reduction" (report[1] and report[3]==4 and report[4]>.62 and report[4]<.623 and report[5] and report[13]>62 and report[13]<62.3)
    caFFCheck "Single selected prop automatically shows useful fit feedback inside Props" (attribute.propControls.propList.selection==1 and attribute.propControls.fitText.visible and findString attribute.propControls.fitText.text "height"!=undefined and attribute.propControls.showFit.enabled and attribute.propControls.useFit.enabled)
    caFFCheck "Contextual controls fit the actual command panel without another window" (caFFFits attribute.propControls and caFFNoPopups())
    local cached=(caGeometryCacheInfo owner)[3]
    attribute.dispatch #minimumSelection;caModifierUI.onRefresh preserveDrafts:true
    caFFCheck "Reading selected-prop feedback performs no solve or state commit" (deepEqual cached(caGeometryCacheInfo owner)[3] and(caSetupSummary owner)[3]==revision)
    caPreview owner #()
    caFFCheck "A staged Preview coexists with accepted fit feedback" ((caPreviewInfo owner)[1] and(caPreviewInfo owner)[2] and(caFitFeedback owner id)[1])
    local beforeNodes=objects.count,beforeSelection=selection as array
    caFFCheck "Actual Show fit handler displays native copied bounds" (attribute.propControls.showFit.pressed())
    completeRedraw();windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    local highlight=caFitHighlightInfo owner
    caFFCheck "Native viewport callback draws the current two-box highlight" (highlight[1] and highlight[2] and highlight[3]==id and highlight[4]==2 and highlight[5] and highlight[6]>0)
    local roofBox=highlight[7][1],fitBox=highlight[7][2]
    caFFCheck "Highlighted roof and checked prop use correct WORLD millimetres at a far frame origin" (distance roofBox[1](origin+[0,0,310])<.02 and distance roofBox[2] [300,200,10]<.02 and abs(fitBox[1].z-fitBox[2].z-(origin.z+20))<.02 and fitBox[1].z+fitBox[2].z<=origin.z+300.02)
    caFFCheck "Highlight preserves scene nodes, selection, published state and separate Preview" (objects.count==beforeNodes and deepEqual beforeSelection(selection as array) and(caSetupSummary owner)[3]==revision and(caPreviewInfo owner)[1] and(caPreviewInfo owner)[2] and(caOutputRows owner).count==0)
    caFFCheck "Same button hides only fit highlighting" (attribute.propControls.showFit.pressed() and not(caFitHighlightInfo owner)[1] and(caPreviewInfo owner)[1])
    caFFCheck "Actual Use checked size sets visible fit drafts" (attribute.propControls.useFit.pressed() and attribute.scaleControls.fitScale.checked and abs(attribute.scaleControls.minimumScale.value-report[13])<.00001)
    caFFCheck "Suggested setting does not mutate accepted settings seed source or output" (deepEqual accepted(caPlacementSettings owner) and(caSetupSummary owner)[3]==revision and(source.transform as string)==sourceTM and(caOutputRows owner).count==0)
    attribute.scaleControls.minimumScale.value=120;attribute.scaleControls.maximumScale.value=80
    caFFCheck "Invalid fit draft retains complete accepted report and native state" (not caModifierUI.generateButton.pressed() and deepEqual accepted(caPlacementSettings owner) and(caFitFeedback owner id)[1] and(caOutputRows owner).count==0)
    attribute.propControls.useFit.pressed()
    caFFCheck "Generate applies the checked float-spinner minimum through normal physical validation" (caModifierUI.generateButton.pressed() and(caOutputRows owner).count==1)
    local placed=(caOutputRows owner)[1],bounds=nodeGetBoundingBox placed[9](matrix3 1)
    caFFCheck "Actual generated device has full support and clears the 280mm roof" (abs(bounds[1].z-(origin.z+20))<.02 and bounds[2].z<=origin.z+300.02 and bounds[1].x>=origin.x-295.02 and bounds[2].x<=origin.x+295.02 and bounds[1].y>=origin.y-195.02 and bounds[2].y<=origin.y+195.02 and placed[6]>=report[13]/100-.000001)
    caFFCheck "Successful fit collapses irrelevant feedback controls and preserves original source/material" (not attribute.propControls.fitText.visible and attribute.propControls.height==400 and not(caFitFeedback owner id)[1] and not(caFitHighlightInfo owner)[1] and(source.transform as string)==sourceTM and deepEqual sourceBounds(nodeGetBoundingBox source(matrix3 1)) and placed[9].material.name=="FF_Device_Material")
    max undo
    caFFCheck "Undo restores original failed arrangement without reviving a stale diagnostic snapshot" (deepEqual accepted(caPlacementSettings owner) and(caOutputRows owner).count==0 and not(caFitFeedback owner id)[1])
    max redo
    caFFCheck "Redo restores the physically valid output" ((caOutputRows owner).count==1)
    max undo
    caModifierUI.onRefresh();caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caModifierUI.generateButton.pressed();attribute=caModifierViewOwner;attribute.propControls.showFit.pressed()
    move source [10,0,0]
    caFFCheck "Relevant source edits invalidate report and drawn bounds without publishing" (not(caFitFeedback owner id)[1] and not(caFitHighlightInfo owner)[2] and(caOutputRows owner).count==0)
    local rejected=false;try(caShowFitFeedback owner id)catch(rejected=true)
    caFFCheck "Stale highlight request is rejected safely" (rejected and(caOutputRows owner).count==0)
    move source [-10,0,0];caModifierUI.onRefresh();caModifierUI.keepSeed.checked=true;caModifierUI.generateButton.pressed();attribute=caModifierViewOwner
    attribute.propControls.showFit.pressed();sliderTime=1;sliderTime=0
    caFFCheck "Time roundtrip cannot resurrect a stale fit report" (not(caFitFeedback owner id)[1] and not(caFitHighlightInfo owner)[2])
    caModifierUI.onRefresh();caModifierUI.keepSeed.checked=true;caModifierUI.generateButton.pressed();attribute=caModifierViewOwner;attribute.propControls.showFit.pressed()
    units.SystemScale=2
    caFFCheck "System-unit changes invalidate world-space report and highlight" (not(caFitFeedback owner id)[1] and not(caFitHighlightInfo owner)[2])
    units.SystemScale=1;caModifierUI.onRefresh();caModifierUI.keepSeed.checked=true;caModifierUI.generateButton.pressed();attribute=caModifierViewOwner;attribute.propControls.showFit.pressed()
    local retired=attribute,other=caCreateArrangement();caBindReceivers other #(floor)
    caFFCheck "Switching owners clears the previous view's highlight" (caFFOpen other and not(caFitHighlightInfo owner)[1])
    caFFCheck "Retired fit action cannot alter another owner" (not retired.dispatch #useFit and not(caPlacementSettings other)[8])
    caFFOpen owner;attribute=caModifierViewOwner
    caFFCheck "Returning to the owner displays its still-current numeric report without solving" (attribute.propControls.fitText.visible and caFFNoPopups())
    local savedName=owner.name,savedSource=source.name,saved=caPlacementSettings owner
    max create mode;caFFCheck "Feedback scene saves without serializing transient advice" (saveMaxFile(CA_TEST_OUTPUT+"CyrusArrange-Fit-Feedback-032.max")quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"CyrusArrange-Fit-Feedback-032.max")quiet:true useFileUnits:true
    owner=getNodeByName savedName;source=getNodeByName savedSource;id=(caAssetRows owner)[1][1]
    caFFCheck "Reopen preserves accepted settings and source while requiring fresh feedback" (deepEqual saved(caPlacementSettings owner) and(source.transform as string)==sourceTM and not(caFitFeedback owner id)[1] and not(caFitHighlightInfo owner)[1])
    caFFOpen owner;caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caFFCheck "Fresh generation after reopen restores useful checked advice" (caModifierUI.generateButton.pressed() and(caFitFeedback owner id)[1] and caModifierViewOwner.propControls.fitText.visible and caFFNoPopups())
    append caFFLog "LIMIT: native callback invocation and world-mm bounds are checked; pixels, mouse picker gesture, renderer and final installer remain separate."
    true
)
try(caFFRun())catch(caFFFailures+=1;append caFFLog("EXCEPTION "+(getCurrentException()as string));append caFFLog("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caFFLog("STACK "+(getCurrentExceptionStackTrace()as string)))
caFFFinished=true;caFFWrite()

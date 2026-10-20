/* Owned normal Max2027 host: actual mounted CA controls and real handlers.
   No computer use, synthetic mounting, artist profile or render-quality claim. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI, CA_STARTUP_OK
global CyrusArrange, CyrusArrangeIcon, caModifierUI, caModifierViewOwner, caCreateModifyView, caModifyViewDefinition
global caFocusArrange, caShowAdvancedArrangeUI, caShowHomePropsUI, caShowCollisionUI

global caUMLog=#(), caUMPasses=0, caUMFailures=0, caUMFinished=false
fn caUMWrite =
(
    local stream=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caUMFinished then (if caUMFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caUMPasses caUMFailures to:stream
    for line in caUMLog do format "%\n" line to:stream
    close stream
)
fn caUMCheck label value =
(
    if value then caUMPasses+=1 else caUMFailures+=1
    append caUMLog ((if value then "PASS " else "FAIL ")+label); caUMWrite()
    if not value do throw ("Unified Modify: "+label)
    value
)
fn caUMEqual a b = deepEqual a b strictCompare:true
fn caUMPose owner = for r in (caOutputRows owner) collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
fn caUMOpen node =
(
    max modify mode; modPanel.setPinStack false; select node
    local modifier=undefined
    for item in node.modifiers where classOf item==CyrusArrange do modifier=item
    if modifier==undefined do throw "Missing native modifier."
    modPanel.setCurrentObject modifier node:node ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    append caUMLog ("MOUNT object="+((modPanel.getCurrentObject())as string)+" view="+(caModifierUI as string)+" attribute="+(caModifierViewOwner as string)+" context="+((if caModifierUI==undefined then undefined else caModifierUI.currentContext())as string)+" window="+((if caModifierUI==undefined then 0 else caModifierUI.hwnd)as string)); caUMWrite()
    caModifierUI!=undefined and caModifierUI.isDisplayed and caModifierUI.hwnd!=0 and caModifierUI.currentContext()==node and modPanel.getCurrentObject()==modifier
)
fn caUMNoPopups =
(
    for name in #(#caHomeUI,#caHomePropsUI,#caArrangeUI,#caAssetUI,#caUI,#caRegionUI,#caCollisionUI,#caCompositionUI,#caRulesUI) do
    (
        local view=globalVars.get name
        if view!=undefined do if view.isDisplayed do return false
    )
    true
)
fn caUMFits view =
(
    local page=windows.getWindowPos view.hwnd removeUIScaling:false
    local origin=windows.clientToScreen view.hwnd 0 0 applyUIScaling:false
    local valid=origin.x==page.x
    if not valid do(append caUMLog("LAYOUT origin/page "+(view as string)+" "+(origin as string)+" "+(page as string));caUMWrite())
    for control in view.controls do
    (
        local handles=control.hwnd
        if handles.count==0 do(valid=false;append caUMLog("LAYOUT no handle "+(control as string));caUMWrite())
        for handle in handles do
        (
            local rect=windows.getWindowPos handle removeUIScaling:false
            if rect.x<origin.x or rect.x+rect.w>page.x+page.w do(valid=false;append caUMLog("LAYOUT "+(control as string)+" rect="+(rect as string)+" origin="+(origin as string)+" page="+(page as string));caUMWrite())
        )
    )
    valid
)
global caUMCreationSource,caUMCreationReplacement,caUMCreationPassed,caUMCreationMode=#delete,caUMCreationArmed=false,caUMCreationFired=false
global caUMCreationOwner,caUMCreationTransformHandler,caUMCreationAuthorArmed=false,caUMCreationAuthorFired=false,caUMCreationAuthorError="",caUMCreationAuthorRecord
fn caUMCreationTransform =
(
    if caUMCreationAuthorArmed and isValidNode caUMCreationOwner do
    (
        try
        (
            local bound=caReceiverNodes caUMCreationOwner
            if bound.count==1 and distance caUMCreationOwner.pos bound[1].pos<0.002 and length caUMCreationOwner.pos>100 do
            (
                caUMCreationAuthorArmed=false
                local before=caSetupSummary caUMCreationOwner,settings=before[9]
                settings[1]=981723L;settings[3]=37
                caSetArrangeSettings caUMCreationOwner settings
                local after=caSetupSummary caUMCreationOwner
                caUMCreationAuthorRecord=#(before[3],after[3],after[9][1],after[9][3])
                caUMCreationAuthorFired=after[3]>before[3] and after[9][1]==981723L and after[9][3]==37
            )
        )catch(caUMCreationAuthorError=getCurrentException() as string)
    )
)
fn caUMCreationCallback =
(
    if caUMCreationArmed do
    (
        caUMCreationArmed=false;caUMCreationFired=true
        case caUMCreationMode of
        (
            #replace: (caUMCreationPassed[1]=caUMCreationReplacement)
            #author:
            (
                caUMCreationOwner=callbacks.notificationParam()
                caUMCreationTransformHandler=when transform caUMCreationOwner changes id:#CA_UM_CreationTransform do caUMCreationTransform()
            )
            default: (if isValidNode caUMCreationSource do delete caUMCreationSource)
        )
    )
)
fn caUMCreation =
(
    max create mode;resetMaxFile #noPrompt
    local board=box name:"UM_Create_Receiver" width:400 length:300 height:20 pos:[1200,-300,700]
    local helper=point name:"UM_Create_InvalidHelper" pos:[0,-2000,0]
    local initialHandles=for node in objects collect getHandleByAnim node
    local sourceTM=copy board.transform,sourceMesh=snapshotAsMesh board
    local rejected=false
    try(caCreateArrangement #(helper))catch(rejected=true)
    caUMCheck "Invalid helper creation leaves no icon, document or new scene node" (rejected and(caSceneSetups #()).count==0 and caUMEqual initialHandles(for node in objects collect getHandleByAnim node))
    rejected=false;try(caCreateArrangement #())catch(rejected=true)
    caUMCheck "Empty receiving selection fails before creating a document" (rejected and(caSceneSetups #()).count==0 and objects.count==initialHandles.count)
    rejected=false;try(caCreateArrangement #(board,helper))catch(rejected=true)
    caUMCheck "Mixed mesh/helper selection is rejected completely" (rejected and(caSceneSetups #()).count==0 and caUMEqual initialHandles(for node in objects collect getHandleByAnim node))
    local owner=caCreateArrangement #(board)
    caUMCheck "Native bound creation positions one Quantity icon at the receiver pivot" (isValidNode owner and(caSceneSetups #()).count==1 and(caReceiverNodes owner)[1]==board and distance owner.pos board.pos<0.002 and(caPlacementSettings owner)[2]==2)
    caUMCheck "Bound creation neither analyzes nor solves nor captures geometry cache" ((caOutputRows owner).count==0 and(caRegionRows owner).count==0 and(caGeometryCacheInfo owner)[3]==undefined)
    local ownerHandle=getHandleByAnim owner,ownerGUID=(caSetupSummary owner)[1]
    max undo
    caUMCheck "One Undo removes the complete bound creation" ((caSceneSetups #()).count==0 and objects.count==initialHandles.count)
    max redo
    local matches=caSceneSetups #()
    owner=if matches.count==1 then matches[1][1] else undefined
    caUMCheck "One Redo restores the same native icon, document and receiver binding" (isValidNode owner and getHandleByAnim owner==ownerHandle and(caSetupSummary owner)[1]==ownerGUID and(caReceiverNodes owner)[1]==board)
    local afterMesh=snapshotAsMesh board,sourceSame=sourceMesh.numverts==afterMesh.numverts and sourceMesh.numfaces==afterMesh.numfaces
    for i=1 to sourceMesh.numverts while sourceSame do if (getVert sourceMesh i)!=(getVert afterMesh i) do sourceSame=false
    for i=1 to sourceMesh.numfaces while sourceSame do if (getFace sourceMesh i)!=(getFace afterMesh i) do sourceSame=false
    caUMCheck "Native creation and its Undo/Redo preserve every receiver vertex, face and transform" (sourceSame and caUMEqual #(sourceTM) #(board.transform))
    local raw=caCreateSetup #(board)1,empty=caCreateArrangement()
    caUMCheck "Explicit raw density creation retains Fill while current empty creation retains Quantity" ((caPlacementSettings raw)[2]==1 and(caPlacementSettings empty)[2]==2)
    local before=(caSceneSetups #()).count,handles=for node in objects collect getHandleByAnim node
    rejected=false;try(caBindReceivers owner #(helper))catch(rejected=true)
    caUMCheck "Existing owner rejects a helper without replacing its receiver or creating nodes" (rejected and(caSceneSetups #()).count==before and(caReceiverNodes owner)[1]==board and caUMEqual handles(for node in objects collect getHandleByAnim node))
    local emptyPath=splineShape name:"UM_Create_EmptySpline"
    local helperPosition=copy helper.pos
    undo "UM creation failure history sentinel" on(helper.pos+=[1,0,0])
    before=(caSceneSetups #()).count;handles=for node in objects collect getHandleByAnim node
    rejected=false;try(caCreateArrangement #(emptyPath))catch(rejected=true)
    caUMCheck "Invalid empty spline cancels the new icon through the native outer hold" (rejected and(caSceneSetups #()).count==before and caUMEqual handles(for node in objects collect getHandleByAnim node))
    max undo
    caUMCheck "Failed creation adds no Undo item ahead of an existing authored edit" (distance helper.pos helperPosition<0.0001)
    local path=splineShape name:"UM_Create_ValidSpline" pos:[2400,500,30]
    addNewSpline path;addKnot path 1 #corner #line [0,0,0];addKnot path 1 #corner #line [1000,0,0];updateShape path
    local pathOwner=caCreateArrangement #(path)
    caUMCheck "Bound spline creation uses the same native command without analyzing or solving" ((caPathSettings pathOwner)[1]==path and(caOutputRows pathOwner).count==0 and(caGeometryCacheInfo pathOwner)[3]==undefined and distance pathOwner.pos path.pos<0.002)
    -- Real scene callback deletes an input while CreateObjectNode is active.
    -- The source watch must reject before dereferencing stale input pointers.
    caUMCreationSource=box name:"UM_Create_CallbackSource" width:100 length:100 height:10 pos:[5000,0,0]
    before=(caSceneSetups #()).count
    caUMCreationMode=#delete;caUMCreationFired=false;caUMCreationArmed=true
    callbacks.removeScripts #nodeCreated id:#CA_UM_AtomicCreation
    callbacks.addScript #nodeCreated "caUMCreationCallback()" id:#CA_UM_AtomicCreation persistent:false
    rejected=false
    try(caCreateArrangement #(caUMCreationSource))catch(rejected=true)
    caUMCreationArmed=false;callbacks.removeScripts #nodeCreated id:#CA_UM_AtomicCreation
    caUMCheck "Input deletion during native creation rejects safely without a new owner" (caUMCreationFired and rejected and(caSceneSetups #()).count==before)
    caUMCheck "Owned creation callback is removed completely" ((callbacks.show #nodeCreated id:#CA_UM_AtomicCreation asArray:true).count==0)
    caUMCreationSource=box name:"UM_Create_SnapshotSource" width:100 length:100 height:10 pos:[6000,0,0]
    caUMCreationReplacement=box name:"UM_Create_ReplacedArrayEntry" width:300 length:200 height:40 pos:[8000,0,0]
    caUMCreationPassed=#(caUMCreationSource)
    caUMCreationMode=#replace;caUMCreationFired=false;caUMCreationArmed=true
    callbacks.addScript #nodeCreated "caUMCreationCallback()" id:#CA_UM_AtomicCreation persistent:false
    local snapshotOwner=undefined,creationError=undefined
    try(snapshotOwner=caCreateArrangement caUMCreationPassed)catch(creationError=getCurrentException())
    caUMCreationArmed=false;callbacks.removeScripts #nodeCreated id:#CA_UM_AtomicCreation
    caUMCheck "Real callback changes the caller array without redirecting the normalized native command" (creationError==undefined and caUMCreationFired and caUMCreationPassed[1]==caUMCreationReplacement and isValidNode snapshotOwner and(caReceiverNodes snapshotOwner)[1]==caUMCreationSource and distance snapshotOwner.pos caUMCreationSource.pos<0.002)
    caUMCreationSource=box name:"UM_Create_ImmediateTransformSource" width:100 length:100 height:10 pos:[9000,700,300]
    before=(caSceneSetups #()).count
    helperPosition=copy helper.pos
    undo "UM immediate-transform failure history sentinel" on(helper.pos+=[2,0,0])
    caUMCreationAuthorArmed=true;caUMCreationAuthorFired=false;caUMCreationAuthorError="";caUMCreationAuthorRecord=undefined
    caUMCreationMode=#author;caUMCreationFired=false;caUMCreationArmed=true
    callbacks.addScript #nodeCreated "caUMCreationCallback()" id:#CA_UM_AtomicCreation persistent:false
    rejected=false;creationError=undefined
    try(caCreateArrangement #(caUMCreationSource))catch(rejected=true;creationError=getCurrentException() as string)
    caUMCreationArmed=false;caUMCreationAuthorArmed=false
    callbacks.removeScripts #nodeCreated id:#CA_UM_AtomicCreation
    if caUMCreationTransformHandler!=undefined do
    (
        caUMCreationTransformHandler.enabled=false
        deleteChangeHandler caUMCreationTransformHandler
        caUMCreationTransformHandler=undefined
    )
    deleteAllChangeHandlers id:#CA_UM_CreationTransform
    append caUMLog("CREATION_TRANSFORM_WITNESS record="+(caUMCreationAuthorRecord as string)+" handlerError="+caUMCreationAuthorError+" creationError="+(creationError as string));caUMWrite()
    caUMCheck "Immediate marker transform callback really authors the same bound Document" (caUMCreationFired and caUMCreationAuthorFired and caUMCreationAuthorError=="")
    caUMCheck "Changed Document rejects the complete creation instead of publishing a stale settings copy" (rejected and(findString creationError "arrangement changed")!=undefined and(caSceneSetups #()).count==before)
    max undo
    caUMCheck "Rejected immediate-transform successor adds no Undo item ahead of the authored sentinel" (distance helper.pos helperPosition<0.0001)
    -- sweep:true deliberately includes retired objects still retained by
    -- callback/history Values. The contract is no registered executable handler.
    caUMCheck "Owned immediate transform handler is unregistered and no callback remains" ((getAllChangeHandlers id:#CA_UM_CreationTransform).count==0 and(callbacks.show #nodeCreated id:#CA_UM_AtomicCreation asArray:true).count==0)
    resetMaxFile #noPrompt
    true
)
fn caUMRun =
(
    resetMaxFile #noPrompt; units.SystemType=#millimeters; units.SystemScale=1; CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms") do fileIn(CA_TEST_ROOT+"scripts/"+script)
    caUMCheck "Exact 0.3.2 native in a normal owned Max2027 host" ((maxVersion())[1]==29000 and caVersion()=="0.3.2" and not maxOps.isInNonInteractiveMode())
    caUMCreation()
    local board=box name:"UM_Receiver" width:1800 length:500 height:20 pos:[0,0,300]
    local source=box name:"UM_Book" width:30 length:100 height:200 pos:[3000,0,0]
    source.material=standardMaterial name:"UM_Material" diffuse:(color 70 120 180)
    local second=box name:"UM_Decor" width:40 length:30 height:80 pos:[3050,0,0]
    local blocker=box name:"UM_KeepClear_Blocker" width:700 length:500 height:250 pos:[-450,0,320]
    local remote=box name:"UM_KeepClear_Remote" width:100 length:100 height:50 pos:[3000,1000,0]
    local obstacleGroup=group #(blocker,remote) name:"UM_KeepClear_Group"
    local originalSource=source.transform as string, originalSecond=second.transform as string
    local modifier=CyrusArrange(); addModifier board modifier
    caUMCheck "Stateless native modifier mounts on actual receiving geometry" (caUMOpen board)
    caUMCheck "Opening the unbound view creates no arrangement or output" (caModifierUI.currentSetup()==undefined and(caSceneSetups #()).count==0)
    caUMCheck "Main UI has no furniture dropdown, Apply or Advanced/Props popup buttons" (not isProperty caModifierUI #furnitureType and not isProperty caModifierUI #advancedButton and not isProperty caModifierUI #propsButton)
    caUMCheck "Actual Use geometry handler creates the native document" (caModifierUI.useReceiverButton.pressed())
    local owner=caModifierUI.currentSetup()
    caUMCheck "New owner has one native icon/one modifier and receiving references" (isValidNode owner and classOf owner.baseObject==CyrusArrangeIcon and owner.modifiers.count==1 and(caReceiverNodes owner).count==1 and(caReceiverNodes owner)[1]==board)
    caUMCheck "Binding geometry performs no solve" ((caOutputRows owner).count==0 and(caGeometryCacheInfo owner)[3]==undefined)
    caUMCheck "Default is explicit 100 copies and no scaling" ((caPlacementSettings owner)[2]==2 and(caPlacementSettings owner)[3]==100 and not(caPlacementSettings owner)[7] and not(caPlacementSettings owner)[8])
    caUMCheck "Icon selection mounts same native document" (caUMOpen owner and caModifierUI.currentSetup()==owner)
    local attribute=caModifierViewOwner
    caUMCheck "New geometry arrangement uses all support without a hidden edge margin" ((caPlacementSettings owner)[6]==0 and attribute.protectionControls.edgeGap.value==0)
    caUMCheck "All inline rollouts mount through the real CA" (attribute.propControls.hwnd!=0 and attribute.scaleControls.hwnd!=0 and attribute.protectionControls.hwnd!=0)
    caUMCheck "Every control fits actual command-panel width" (caUMFits caModifierUI and caUMFits attribute.propControls and caUMFits attribute.scaleControls and caUMFits attribute.protectionControls)
    modPanel.setPinStack true; select source
    caUMCheck "Actual Add selected props handler uses pinned arrangement" (attribute.propControls.addSelection.pressed())
    caUMCheck "Props are listed inline and source registered once" ((caAssetRows owner).count==1 and attribute.propControls.propList.items.count==1 and caModifierUI.currentSetup()==owner)
    attribute.propControls.propList.selection=1;attribute.dispatch #minimumSelection
    local minimumAsset=(caAssetRows owner)[1][1],expectedMinimums=#(#(minimumAsset,5))
    attribute.propControls.minimumCopies.value=5;attribute.propControls.minimumCopies.changed 5
    caUMCheck "Selected prop minimum is an inline draft without native mutation" ((caPropMinimums owner).count==0 and(caModifierUI.readMinimumDraft())[1][2]==5)
    -- Autodesk documents that .selected hides the dropdown event function.
    -- Exercise its real control plus the same shared handler used by that event.
    caModifierUI.amountMode.selection=2; attribute.amountChanged 2
    caUMCheck "Amount dropdown shared handler enables Fill and disables Quantity" (caModifierUI.fillAmount.enabled and not caModifierUI.quantity.enabled)
    caModifierUI.amountMode.selection=1; attribute.amountChanged 1
    caUMCheck "Amount dropdown shared handler enables Quantity and disables Fill" (caModifierUI.quantity.enabled and not caModifierUI.fillAmount.enabled)
    caModifierUI.quantity.value=12; caModifierUI.spacing.value=3
    attribute.protectionControls.edgeGap.value=15;attribute.protectionControls.edgeGap.changed 15
    caUMCheck "Optional edge gap is a visible draft inside Keep clear" ((caPlacementSettings owner)[6]==0 and(caModifierUI.readDraft())[6]==15 and caUMNoPopups())
    attribute.scaleControls.randomScale.checked=true; attribute.scaleControls.randomScale.changed true
    attribute.scaleControls.minimumScale.value=80; attribute.scaleControls.maximumScale.value=110
    caUMCheck "Scale toggles enable inline range without applying" (attribute.scaleControls.minimumScale.enabled and attribute.scaleControls.maximumScale.enabled and(caPlacementSettings owner)[3]==100 and not(caPlacementSettings owner)[7])
    caUMCheck "Actual Generate button commits quantity, gap and random scale in one command" (caModifierUI.generateButton.pressed())
    caUMCheck "Generate commits source minimums with the same output transaction" (caUMEqual expectedMinimums(caPropMinimums owner))
    local accepted=caPlacementSettings owner, pose=caUMPose owner
    caUMCheck "Generated result uses drafts without Apply" (accepted[2]==2 and accepted[3]==12 and accepted[5]==3 and accepted[6]==15 and accepted[7] and accepted[9]==0.8 and accepted[10]==1.1 and pose.count==12)
    local physical=true, varied=false
    local rows=caOutputRows owner
    for i=1 to rows.count do
    (
        local bounds=nodeGetBoundingBox rows[i][9](matrix3 1)
        if abs(bounds[1].z-320)>0.03 or bounds[1].x < -885.03 or bounds[2].x>885.03 or bounds[1].y < -235.03 or bounds[2].y>235.03 or rows[i][6]<0.8 or rows[i][6]>1.1 do physical=false
        if rows[i][9].material.name!="UM_Material" do physical=false
        if abs(rows[i][6]-rows[1][6])>0.001 do varied=true
        for j=1 to i-1 do
        (
            local other=nodeGetBoundingBox rows[j][9](matrix3 1)
            if bounds[1].x<other[2].x-0.03 and bounds[2].x>other[1].x+0.03 and bounds[1].y<other[2].y-0.03 and bounds[2].y>other[1].y+0.03 do physical=false
        )
    )
    caUMCheck "Actual output meshes satisfy scale, support, bounds, material and nonoverlap" (physical and varied)
    caUMCheck "Automatic sampling succeeds without editing a grid field" ((caSetupSummary owner)[9][10]>0 and not isProperty caModifierUI #cellMM)
    caUMCheck "Next Generate succeeds" (caModifierUI.generateButton.pressed())
    local nextSettings=caPlacementSettings owner
    caUMCheck "Default Generate actually changes saved seed" ((caPlacementSettings owner)[1]!=accepted[1])
    max undo
    caUMCheck "One Undo restores complete previous settings and placements" (caUMEqual accepted(caPlacementSettings owner) and caUMEqual pose(caUMPose owner))
    caUMCheck "Undo automatically refreshes accepted Modify values" (caModifierUI.quantity.value==accepted[3] and caModifierUI.seedText.text==trimRight(accepted[1]as string)"Ll")
    max redo
    caUMCheck "Redo automatically refreshes accepted Modify seed" (caUMEqual nextSettings(caPlacementSettings owner) and caModifierUI.seedText.text==trimRight(nextSettings[1]as string)"Ll")
    max undo
    caModifierUI.keepSeed.checked=true; caModifierUI.keepSeed.changed true
    caUMCheck "Repeat seed exposes exact editable seed inline" (caModifierUI.seedText.visible and caModifierUI.seedText.enabled)
    caUMCheck "Repeat Generate handler succeeds" (caModifierUI.generateButton.pressed())
    caUMCheck "Repeat preserves exact seed and poses" (caUMEqual accepted(caPlacementSettings owner) and caUMEqual pose(caUMPose owner))
    attribute.propControls.minimumCopies.value=20;attribute.propControls.minimumCopies.changed 20
    caUMCheck "An excessive minimum draft fails without altering accepted source requirements or output" (not caModifierUI.generateButton.pressed() and caUMEqual expectedMinimums(caPropMinimums owner) and caUMEqual pose(caUMPose owner))
    caModifierUI.onRefresh()
    caModifierUI.quantity.value=20
    attribute.scaleControls.minimumScale.value=120; attribute.scaleControls.maximumScale.value=80
    caUMCheck "Invalid visible range fails Generate" (not caModifierUI.generateButton.pressed())
    caUMCheck "Failed draft keeps all authored state and outputs" (caUMEqual accepted(caPlacementSettings owner) and caUMEqual pose(caUMPose owner) and caModifierUI.errorMessage()!="")
    caModifierUI.onRefresh(); attribute.scaleControls.fitScale.checked=true; attribute.scaleControls.fitScale.changed true
    caUMCheck "Fit scaling toggle is inline and leaves saved state until Generate" (attribute.scaleControls.minimumScale.enabled and not(caPlacementSettings owner)[8])
    attribute.scaleControls.fitScale.checked=false; attribute.scaleControls.fitScale.changed false
    caModifierUI.quantity.value=14; caModifierUI.spacing.value=7
    caUMCheck "Bulk source command accepts duplicates atomically" (attribute.dispatch #addProps data:#(source,second,second))
    caUMCheck "Source refresh preserves pending placement drafts" ((caAssetRows owner).count==2 and caModifierUI.quantity.value==14 and caModifierUI.spacing.value==7 and(caPlacementSettings owner)[3]==12)
    attribute.propControls.propList.selection=1;attribute.dispatch #minimumSelection
    attribute.propControls.minimumCopies.value=6;attribute.propControls.minimumCopies.changed 6
    attribute.propControls.groupName.text="UM_Reusable_Decor"
    attribute.protectionControls.clearApproach.checked=true;attribute.protectionControls.clearApproach.changed true
    attribute.protectionControls.edgeGap.value=6;attribute.protectionControls.edgeGap.changed 6
    caUMCheck "Optional approach is an inline draft with no accepted-state change" (not(caCollisionScope owner)[1] and caUMNoPopups())
    caUMCheck "Reusable group uses the same inline command and real native copy transaction" (attribute.dispatch #groupProps data:#(source,second))
    caUMCheck "Group is one registered reusable source and originals unchanged" ((caAssetRows owner).count==3 and(source.transform as string)==originalSource and(second.transform as string)==originalSecond)
    local beforeGroupView=attribute
    attribute=caModifierViewOwner
    caUMCheck "Group creation resumes same Modify document and pending drafts after Max closes its context" (attribute!=undefined and caModifierUI.currentSetup()==owner and attribute.propControls.propList.items.count==3 and caModifierUI.quantity.value==14 and caModifierUI.spacing.value==7)
    caUMCheck "Reusable grouping restores pending per-source minimums without applying them" ((caModifierUI.readMinimumDraft())[1][2]==6 and caUMEqual expectedMinimums(caPropMinimums owner))
    caUMCheck "Reusable grouping restores the same pending approach draft" (attribute.protectionControls.clearApproach.checked and not(caCollisionScope owner)[1])
    caUMCheck "Reusable grouping restores the pending edge gap without applying it" (attribute.protectionControls.edgeGap.value==6 and(caPlacementSettings owner)[6]==15)
    if beforeGroupView!=attribute do caUMCheck "Retired pre-group view cannot generate into resumed view" (not beforeGroupView.dispatch #generate)
    append caUMLog("GROUP_UI current="+(caModifierViewOwner as string)+" capturedActive="+((attribute.isActiveView())as string)+" list="+(attribute.propControls.propList.items as string)+" error="+((if caModifierUI==undefined then "no active view" else caModifierUI.errorMessage())as string)); caUMWrite()
    attribute.propControls.propList.selection=3
    local removed=attribute.propControls.removeProp.pressed()
    append caUMLog("REMOVE_UI returned="+(removed as string)+" count="+((caAssetRows owner).count as string)+" selected="+(attribute.propControls.propList.selection as string)+" error="+((if caModifierUI==undefined then "no active view" else caModifierUI.errorMessage())as string)); caUMWrite()
    caUMCheck "Actual Remove prop button removes selected library entry" (removed and(caAssetRows owner).count==2)
    local beforeObstaclePose=caUMPose owner, beforeObstacleSettings=caPlacementSettings owner, beforeObstacleCache=(caGeometryCacheInfo owner)[3]
    local beforeObstacleHandles=for row in(caOutputRows owner)collect(getHandleByAnim row[9])
    caUMCheck "Keep clear accepts a complete group and duplicate/child picks through its shared completion command" (attribute.dispatch #addObstacles data:#(obstacleGroup,blocker,obstacleGroup))
    caUMCheck "Obstacle picking retains output handles and performs no solve" (caUMEqual beforeObstaclePose(caUMPose owner) and caUMEqual beforeObstacleHandles(for row in(caOutputRows owner)collect(getHandleByAnim row[9])) and caUMEqual beforeObstacleCache(caGeometryCacheInfo owner)[3])
    caUMCheck "Keep clear hydrates one native root while retaining all placement and approach drafts" ((caCollisionScope owner)[2].count==1 and(caCollisionScope owner)[2][1][1]==obstacleGroup and attribute.protectionControls.obstacleList.items.count==1 and attribute.protectionControls.clearApproach.checked and not(caCollisionScope owner)[1] and caModifierUI.quantity.value==14 and caModifierUI.spacing.value==7 and(caModifierUI.readMinimumDraft())[1][2]==6)
    max undo
    caUMCheck "One Undo removes the obstacle reference without changing output or approach draft" ((caCollisionScope owner)[2].count==0 and attribute.protectionControls.obstacleList.items.count==0 and attribute.protectionControls.clearApproach.checked and caUMEqual beforeObstaclePose(caUMPose owner))
    max redo
    caUMCheck "Redo restores the same obstacle group in Modify" ((caCollisionScope owner)[2].count==1 and attribute.protectionControls.obstacleList.items.count==1 and caUMNoPopups())
    local scopeRevision=(caSetupSummary owner)[3]
    for row in #(#(board,"Receiver"),#(source,"Registered source"),#(owner,"Arrangement icon"),#((caOutputRows owner)[1][9],"Managed output")) do
        caUMCheck (row[2]+" cannot become an independent obstacle") (not(attribute.dispatch #addObstacles data:#(row[1])) and(caSetupSummary owner)[3]==scopeRevision and(caCollisionScope owner)[2].count==1 and caUMEqual beforeObstaclePose(caUMPose owner))
    caUMCheck "Obstacle and placement drafts commit through the actual Generate handler" (caModifierUI.generateButton.pressed())
    local obstaclePoses=caUMPose owner, obstacleSettings=caPlacementSettings owner, physicalObstacle=true, obstacleBounds=nodeGetBoundingBox blocker(matrix3 1)
    for row in(caOutputRows owner)do
    (
        local bounds=nodeGetBoundingBox row[9](matrix3 1)
        if bounds[1].x<obstacleBounds[2].x-0.03 and bounds[2].x>obstacleBounds[1].x+0.03 and bounds[1].y<obstacleBounds[2].y-0.03 and bounds[2].y>obstacleBounds[1].y+0.03 and bounds[1].z<obstacleBounds[2].z-0.03 and bounds[2].z>obstacleBounds[1].z+0.03 do physicalObstacle=false
    )
    caUMCheck "Actual generated meshes avoid the grouped on-surface blocker" (obstaclePoses.count==14 and physicalObstacle and(caCollisionScope owner)[1] and obstacleSettings[5]==7)
    caUMCheck "Generate commits edge gap with the same placement transaction" (obstacleSettings[6]==6)
    attribute.protectionControls.clearApproach.checked=false;attribute.protectionControls.clearApproach.changed false
    attribute.scaleControls.minimumScale.value=120;attribute.scaleControls.maximumScale.value=80
    caUMCheck "Failed Generate retains accepted approach, settings and complete obstacle-checked output" (not caModifierUI.generateButton.pressed() and(caCollisionScope owner)[1] and caUMEqual obstacleSettings(caPlacementSettings owner) and caUMEqual obstaclePoses(caUMPose owner))
    caModifierUI.onRefresh()
    max undo
    caUMCheck "One Generate Undo restores prior approach, settings, minimums and output while keeping obstacle bindings" (not(caCollisionScope owner)[1] and not attribute.protectionControls.clearApproach.checked and(caCollisionScope owner)[2].count==1 and caUMEqual beforeObstacleSettings(caPlacementSettings owner) and caUMEqual beforeObstaclePose(caUMPose owner) and caUMEqual expectedMinimums(caPropMinimums owner))
    max redo
    caUMCheck "Generate Redo restores the accepted approach and placements together" ((caCollisionScope owner)[1] and attribute.protectionControls.clearApproach.checked and caUMEqual obstaclePoses(caUMPose owner))
    max undo
    local absentA=box name:"UM_Missing_Obstacle_A" width:20 length:20 height:20 pos:[5000,0,0]
    local absentB=box name:"UM_Missing_Obstacle_B" width:20 length:20 height:20 pos:[5100,0,0]
    local liveExtra=box name:"UM_Extra_Obstacle" width:20 length:20 height:20 pos:[5200,0,0]
    local oldRevision=(caSetupSummary owner)[3]
    attribute.dispatch #addObstacles data:#(absentA,absentB)
    local staleRejected=false
    try(caRemoveObstacle owner 1 oldRevision)catch(staleRejected=true)
    caUMCheck "Native row removal rejects a stale list revision without changing current roots" (staleRejected and(caCollisionScope owner)[2].count==3)
    delete #(absentA,absentB);caModifierUI.onRefresh preserveDrafts:true
    caUMCheck "Missing obstacle references remain visible inline" ((for row in(caCollisionScope owner)[2]where not isValidNode row[1]collect row).count==2 and attribute.protectionControls.obstacleList.items.count==3)
    caUMCheck "Adding a live obstacle preserves both missing reference slots" (attribute.dispatch #addObstacles data:#(liveExtra) and(caCollisionScope owner)[2].count==4 and(for row in(caCollisionScope owner)[2]where not isValidNode row[1]collect row).count==2)
    for remaining=1 to 0 by -1 do
    (
        local scope=(caCollisionScope owner)[2], missingIndex=0
        for i=1 to scope.count where not isValidNode scope[i][1]do missingIndex=i
        attribute.protectionControls.obstacleList.selection=missingIndex;attribute.dispatch #obstacleSelection
        caUMCheck ("Actual Remove obstacle repairs one missing slot; remaining="+(remaining as string)) (attribute.protectionControls.removeObstacle.enabled and attribute.protectionControls.removeObstacle.pressed() and(for row in(caCollisionScope owner)[2]where not isValidNode row[1]collect row).count==remaining)
    )
    local liveIndex=0, liveScope=(caCollisionScope owner)[2]
    for i=1 to liveScope.count where liveScope[i][1]==liveExtra do liveIndex=i
    attribute.protectionControls.obstacleList.selection=liveIndex;attribute.dispatch #obstacleSelection
    caUMCheck "Remove obstacle retains the scene model and original group reference" (attribute.protectionControls.removeObstacle.pressed() and isValidNode liveExtra and(caCollisionScope owner)[2].count==1 and(caCollisionScope owner)[2][1][1]==obstacleGroup)
    local passiveCache=(caGeometryCacheInfo owner)[3], passiveRevision=(caSetupSummary owner)[3]
    attribute.dispatch #hydrateCollision;caModifierUI.onRefresh preserveDrafts:true
    caUMCheck "Browsing Keep clear does not solve or mutate native state" (caUMEqual passiveCache(caGeometryCacheInfo owner)[3] and(caSetupSummary owner)[3]==passiveRevision and caUMNoPopups())
    local retired=attribute, countBefore=(caSceneSetups #()).count
    local other=caCreateArrangement(); caBindReceivers other #(board)
    caUMCheck "Other arrangement mounts independently" (caUMOpen other and caModifierUI.currentSetup()==other)
    caUMCheck "Ambiguous receiving modifier mounts without choosing an owner" (caUMOpen board and caModifierUI.currentSetup()==undefined)
    local ambiguousCount=(caSceneSetups #()).count
    caUMCheck "Ambiguous Use geometry rejects instead of silently making a third arrangement" (not caModifierUI.useReceiverButton.pressed() and (caSceneSetups #()).count==ambiguousCount)
    caUMCheck "Explicit other icon resolves the ambiguity" (caUMOpen other and caModifierUI.currentSetup()==other)
    local otherBefore=caPlacementSettings other, active=caModifierViewOwner
    caUMCheck "Retired CA rejects commands against the new owner" (not retired.dispatch #generate and caUMEqual otherBefore(caPlacementSettings other))
    caUMCheck "Retired Keep clear cannot add obstacles to the next owner" (not(retired.dispatch #addObstacles data:#(liveExtra)) and(caCollisionScope other)[2].count==0)
    retired.releaseView()
    caUMCheck "Late old-view cleanup retains new active view" (caModifierViewOwner==active and caModifierUI.currentSetup()==other)
    local helper=CyrusArrangeIcon name:"UM_Public_Icon"
    addModifier helper (CyrusArrange())
    caBindReceivers helper #(board)
    caUMCheck "Public helper initialization is idempotent with manually added modifier" (helper.modifiers.count==1 and(caReceiverNodes helper)[1]==board)
    CA_STARTUP_OK=true; fileIn(CA_TEST_ROOT+"installer/CyrusArrange.mcr")
    select board; modPanel.setPinStack false; max create mode
    local beforeMacro=(caSceneSetups #()).count
    macros.run "Cyrus" "CreateCyrusArrange"
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caUMCheck "Create toolbar macro creates and selects one arrangement in Modify" ((caSceneSetups #()).count==beforeMacro+1 and caModifierUI!=undefined and caModifierUI.currentSetup()==selection[1] and getCommandPanelTaskMode()==#modify)
    modPanel.setPinStack true
    caUMCheck "Legacy Advanced entry focuses intended Modify owner through a pinned stack without popup" (isValidNode(caShowAdvancedArrangeUI setup:owner) and caModifierUI.currentSetup()==owner and caUMNoPopups())
    caUMCheck "Legacy Props entry focuses same arrangement without popup" (isValidNode(caShowHomePropsUI owner) and caModifierUI.currentSetup()==owner and caUMNoPopups())
    caUMCheck "Legacy collision entry focuses Modify without another window" (isValidNode(caShowCollisionUI owner) and caModifierUI.currentSetup()==owner and caUMNoPopups())
    local saved=caPlacementSettings owner, savedPoses=caUMPose owner, savedName=owner.name, savedApproach=(caCollisionScope owner)[1], savedObstacleName=obstacleGroup.name
    max create mode; modPanel.setPinStack false
    caUMCheck "Save native setup with redesigned UI" (saveMaxFile(CA_TEST_OUTPUT+"unified-modify.max") quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"unified-modify.max") quiet:true useFileUnits:true
    local reopened=getNodeByName savedName
    caUMCheck "Saved scene restores settings and poses" (isValidNode reopened and caUMEqual saved(caPlacementSettings reopened) and caUMEqual savedPoses(caUMPose reopened))
    caUMCheck "Reopened scene mounts exact native Document" (caUMOpen reopened and caModifierUI.currentSetup()==reopened and caUMNoPopups())
    caUMCheck "Reopened inline Scale reflects the saved random range" (caModifierViewOwner.scaleControls.randomScale.checked==saved[7] and abs(caModifierViewOwner.scaleControls.minimumScale.value-saved[9]*100.0)<0.001 and abs(caModifierViewOwner.scaleControls.maximumScale.value-saved[10]*100.0)<0.001)
    caModifierViewOwner.propControls.propList.selection=1;caModifierViewOwner.dispatch #minimumSelection
    caUMCheck "Reopened minimum copies hydrate the selected source in Modify" (caModifierViewOwner.propControls.minimumCopies.value==5 and caUMEqual expectedMinimums(caPropMinimums reopened))
    caUMCheck "Reopened Keep clear hydrates its actual group reference and approach flag" ((caCollisionScope reopened)[2].count==1 and(caCollisionScope reopened)[2][1][1].name==savedObstacleName and caModifierViewOwner.protectionControls.obstacleList.items.count==1 and caModifierViewOwner.protectionControls.clearApproach.checked==savedApproach)
    caUMCheck "Reopened edge gap hydrates from the saved native setting" (caModifierViewOwner.protectionControls.edgeGap.value==saved[6])
    -- Actual inline Path controls, using the same mounted native Document.
    local pathOwner=caCreateArrangement();pathOwner.name="UM_Path_Arrangement"
    local path=splineShape name:"UM_Path";addNewSpline path;addKnot path 1 #corner #line [0,0,0];addKnot path 1 #corner #line [15000,0,0];updateShape path
    local car=box name:"UM_Path_Car" width:4000 length:1800 height:1500 pos:[30000,0,0]
    caUMCheck "New path arrangement really mounts in Modify" (caUMOpen pathOwner)
    caUMCheck "One optional Path section contains lane and variation controls" (caModifierViewOwner.pathControls.hwnd!=0 and caModifierViewOwner.pathControls.twoWay!=undefined and caModifierViewOwner.pathControls.sideways!=undefined)
    caUMCheck "New path controls fit the measured command-panel width" (caUMFits caModifierViewOwner.pathControls)
    local pathView=caModifierViewOwner
    local pathBound=pathView.dispatch #bindPath data:path
    append caUMLog("PATH_BIND returned="+(pathBound as string)+" error="+caModifierUI.errorMessage()+" state="+((caPathSettings pathOwner)as string));caUMWrite()
    caUMCheck "Inline path binding command attaches one actual spline without solving" (pathBound and(caPathSettings pathOwner)[1]==path and(caOutputRows pathOwner).count==0 and(caGeometryCacheInfo pathOwner)[3]==undefined)
    caUMCheck "Single-path mode hides second lane inputs and unused center spacing" (not pathView.pathControls.rightCopies.visible and not pathView.pathControls.centerSpacing.visible and pathView.pathControls.sideways.visible)
    caUMCheck "Main amount dropdown changes context to quantity or center spacing" (caModifierUI.currentPathMode() and caModifierUI.amountMode.items[2]=="Center spacing" and not caModifierUI.fillAmount.visible)
    caUMCheck "Inline Props command registers the actual car" (pathView.dispatch #addProps data:#(car))
    local pathRevision=(caSetupSummary pathOwner)[3]
    caUMCheck "Selected spline cannot also become an independent obstacle" (not(pathView.dispatch #addObstacles data:#(path)) and(caSetupSummary pathOwner)[3]==pathRevision and(caCollisionScope pathOwner)[2].count==0)
    pathView.protectionControls.clearApproach.checked=true;pathView.protectionControls.clearApproach.changed true
    pathView.protectionControls.edgeGap.value=9;pathView.protectionControls.edgeGap.changed 9
    caModifierUI.quantity.value=3;caModifierUI.spacing.value=20
    pathView.pathControls.twoWay.checked=true;pathView.pathControls.twoWay.changed true
    caUMCheck "Two-way control supplies opposite lanes and enables their meaningful inputs" (pathView.pathControls.limitWidth.checked and not pathView.pathControls.limitWidth.enabled and pathView.pathControls.rightCopies.enabled and pathView.pathControls.offset.value==1750)
    caUMCheck "Enabling two-way placement reveals its fields inside Path" (pathView.pathControls.rightCopies.visible and pathView.pathControls.rightOffset.visible and pathView.pathControls.opposite.visible)
    pathView.pathControls.rightCopies.value=3
    pathView.propControls.propList.selection=1;pathView.dispatch #minimumSelection
    local pathMinimumID=(caAssetRows pathOwner)[1][1]
    pathView.propControls.minimumCopies.value=4;pathView.propControls.minimumCopies.changed 4
    caUMCheck "Path minimum copies stays an inline draft across both lane totals" ((caPropMinimums pathOwner).count==0 and(caModifierUI.readMinimumDraft())[1][2]==4)
    caUMCheck "Actual Generate button commits main and inline path drafts together" (caModifierUI.generateButton.pressed())
    caUMCheck "Path Generate accepts a minimum larger than either individual lane count" ((caPropMinimums pathOwner)[1][1]==pathMinimumID and(caPropMinimums pathOwner)[1][2]==4)
    caUMCheck "Actual UI publishes three complete cars each way" ((caOutputRows pathOwner).count==6 and(caPathSettings pathOwner)[3][1]==3 and(caPathSettings pathOwner)[3][2]==3)
    caModifierUI.amountMode.selection=2;pathView.amountChanged 2
    caUMCheck "Path spacing mode uses path center controls instead of density" (not caModifierUI.quantity.enabled and pathView.pathControls.centerSpacing.enabled and pathView.pathControls.rightSpacing.enabled and not caModifierUI.fillAmount.visible)
    pathView.pathControls.centerSpacing.value=5000;pathView.pathControls.rightSpacing.value=5000
    caUMCheck "Spacing Generate uses the same inline transaction" (caModifierUI.generateButton.pressed() and(caOutputRows pathOwner).count==6 and(caPlacementSettings pathOwner)[2]==1)
    caUMCheck "Path Generate accepts the staged approach flag without inventing a support requirement" ((caCollisionScope pathOwner)[1] and pathView.protectionControls.clearApproach.checked)
    local pathSaved=(caPathSettings pathOwner)[2],pathPoses=caUMPose pathOwner
    pathView.pathControls.sideways.value=100;pathView.pathControls.along.value=250
    caUMCheck "Path variation stays a draft until Generate" ((caPathSettings pathOwner)[2][18]==0 and(caPathSettings pathOwner)[2][19]==0)
    caUMCheck "Generate publishes actual path variation" (caModifierUI.generateButton.pressed() and(caPathSettings pathOwner)[2][18]==100 and(caPathSettings pathOwner)[2][19]==250)
    max undo
    caUMCheck "Undo restores path fields and output without an Apply step" (caUMEqual pathSaved((caPathSettings pathOwner)[2]) and caUMEqual pathPoses(caUMPose pathOwner) and pathView.pathControls.sideways.value==0 and pathView.pathControls.along.value==0)
    max redo
    caUMCheck "Redo refreshes visible path spread" (pathView.pathControls.sideways.value==100 and pathView.pathControls.along.value==250)
    pathView.pathControls.frontAxis.selection=2;pathView.dispatch #scale
    caUMCheck "Model-front dropdown maps to a native angle draft" ((caModifierUI.readPathDraft())[4]==90 and(caPathSettings pathOwner)[2][4]==0)
    pathView.pathControls.frontAxis.selection=1
    local cacheBefore=(caGeometryCacheInfo pathOwner)[3][12]
    pathView.pathControls.open=true
    caUMCheck "Opening optional path sections performs no solve" ((caGeometryCacheInfo pathOwner)[3][12]==cacheBefore)
    local pathSavedName=pathOwner.name,pathAccepted=(caPathSettings pathOwner)[2],pathAcceptedPose=caUMPose pathOwner
    max create mode
    caUMCheck "Save scene containing real inline path arrangement" (saveMaxFile(CA_TEST_OUTPUT+"path-modify.max") quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"path-modify.max") quiet:true useFileUnits:true
    pathOwner=getNodeByName pathSavedName
    caUMCheck "Reopened path scene retains settings/reference and poses" (caUMEqual pathAccepted((caPathSettings pathOwner)[2]) and isValidNode ((caPathSettings pathOwner)[1]) and caUMEqual pathAcceptedPose(caUMPose pathOwner))
    caUMCheck "Reopened path really mounts correct document and inline values" (caUMOpen pathOwner and caModifierUI.currentPathMode() and caModifierViewOwner.pathControls.twoWay.checked and caModifierViewOwner.pathControls.sideways.value==100 and caModifierViewOwner.pathControls.along.value==250)
    caUMCheck "Reopened optional section preserves a saved true approach and authored edge gap" ((caCollisionScope pathOwner)[1] and caModifierViewOwner.protectionControls.clearApproach.checked and caModifierViewOwner.protectionControls.edgeGap.value==9 and(caPlacementSettings pathOwner)[6]==9)
    caModifierViewOwner.propControls.propList.selection=1;caModifierViewOwner.dispatch #minimumSelection
    caUMCheck "Reopened path source minimum hydrates inline from the native policy" (caModifierViewOwner.propControls.minimumCopies.value==4 and(caPropMinimums pathOwner)[1][2]==4)
    local pathCount=(caSceneSetups #()).count
    caModifierUI.spacing.value=33
    caModifierViewOwner.protectionControls.clearApproach.checked=false;caModifierViewOwner.protectionControls.clearApproach.changed false
    caModifierViewOwner.propControls.minimumCopies.value=5;caModifierViewOwner.propControls.minimumCopies.changed 5
    caUMCheck "Clear path is an inline explicit command" (caModifierViewOwner.pathControls.clearPath.pressed() and caPathSettings pathOwner==undefined and caModifierUI.amountMode.items[2]=="Fill available space" and(caSceneSetups #()).count==pathCount)
    caUMCheck "Inline switch to surfaces retains total copies and required source count" ((caPlacementSettings pathOwner)[3]==6 and caModifierUI.quantity.value==6 and(caPropMinimums pathOwner)[1][2]==4)
    caUMCheck "Switching modes preserves unrelated gap and source minimum drafts without applying" (caModifierUI.spacing.value==33 and(caPlacementSettings pathOwner)[5]==20 and(caModifierUI.readMinimumDraft())[1][2]==5 and(caPropMinimums pathOwner)[1][2]==4)
    caUMCheck "Switching modes preserves an uncommitted approach draft" (not caModifierViewOwner.protectionControls.clearApproach.checked and(caCollisionScope pathOwner)[1])
    max undo
    caUMCheck "Undo Clear path restores the same real path binding and mode" (caPathSettings pathOwner!=undefined and caModifierUI.currentPathMode())
    select(getNodeByName "UM_Path");max create mode;macros.run "Cyrus" "CreateCyrusArrange"
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caUMCheck "Create macro recognizes an evaluated spline selection automatically" (caModifierUI!=undefined and caPathSettings(caModifierUI.currentSetup())!=undefined and(caPathSettings(caModifierUI.currentSetup()))[1]==getNodeByName "UM_Path")
    caUMCheck "Path editing never opens another settings dialog" (caUMNoPopups())
    append caUMLog "LIMIT: viewport pickObject interaction, public mouse-create gesture and visual quality are not qualified by this fixture."

    true
)
try (caUMRun()) catch (caUMFailures+=1; append caUMLog("EXCEPTION "+(getCurrentException()as string)); append caUMLog("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string)); append caUMLog("STACK "+(getCurrentExceptionStackTrace()as string)))
caUMFinished=true; caUMWrite()

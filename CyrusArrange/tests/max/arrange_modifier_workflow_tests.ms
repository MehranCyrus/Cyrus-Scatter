/* Actual private Max 2027 Modify-panel interaction. No CUA or render claim. */
-- Primary host API: https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Command-Panels/GUID-BAC3CC23-9D1D-44CE-B4AF-C0CEBDD7099E.html
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global CyrusArrange, CyrusArrangeIcon, caModifierUI, caModifierViewOwner, caCreateModifyView, caModifyViewDefinition
global caHomeUI, caHomePropsUI, caArrangeUI, caAssetUI, caUI
global caShowArrangeUI, caSceneSetups, caCreateSetup, caSetupSummary, caCreateArrangement, caBindReceivers, caPlacementSettings, caVersion
global caAssetRows, caOutputRows, caSetArrangeSettings, caGeometryCacheInfo, caGeometryDependencyInfo
global caMWLog=#(), caMWPasses=0, caMWFailures=0, caMWFinished=false
global caMWWrite, caMWNote, caMWCheck, caMWRequire, caMWEqual, caMWClose, caMWModifier, caMWOpen
global caMWMesh, caMWSource, caMWRecords, caMWHandles, caMWState, caMWPhysical, caMWOwnerAttribute, caMWRun
global caMWCurrentSetup, caMWCurrentContext, caMWSceneHandles, caMWNoSceneViewAttributes, caMWControlsFit
-- Numeric-only observation of the real provider handoff. No returned objects retained.
global caMWOriginalProvider=undefined, caMWProviderLedger=#(), caMWProviderSequence=0L
global caMWAnimHandle, caMWNumericClassID, caMWTrackedProvider, caMWInstallProvider, caMWRestoreProvider, caMWProviderIdentity

fn caMWWrite =
(
    local output=createFile (CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caMWFinished then (if caMWFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caMWPasses caMWFailures to:output
    for line in caMWLog do format "%\n" line to:output
    close output
)
fn caMWNote message=(append caMWLog message;caMWWrite())
fn caMWCheck message value=(if value then(caMWPasses+=1;caMWNote("PASS "+message))else(caMWFailures+=1;caMWNote("FAIL "+message));value)
fn caMWRequire message value=(caMWCheck message value;if not value do throw("Required Modify workflow prerequisite: "+message);value)
fn caMWEqual a b=deepEqual a b strictCompare:true
fn caMWCurrentSetup=(if caModifierUI==undefined then undefined else caModifierUI.currentSetup())
fn caMWCurrentContext=(if caModifierUI==undefined then undefined else caModifierUI.currentContext())
fn caMWSceneHandles=sort(for node in objects collect(getHandleByAnim node))
fn caMWNoSceneViewAttributes =
(
    for node in objects do
    (
        local sceneValues=#(node,node.baseObject)
        for modifier in node.modifiers do append sceneValues modifier
        for value in sceneValues do for index=1 to value.custAttributes.count do
        (
            local id=value.custAttributes[index].classID
            if id.count==2 and(id[1]as Integer64)==0x6a4387d5 and(id[2]as Integer64)==0x4fa90372 do return false
        )
    )
    true
)
fn caMWControlsFit view =
(
    -- Autodesk Windows Structure APIs return consistent raw physical coordinates
    -- when both scaling flags are false. Read only the owned mounted page.
    local page=windows.getWindowPos view.hwnd removeUIScaling:false
    local origin=windows.clientToScreen view.hwnd 0 0 applyUIScaling:false
    local style=windows.getWindowLong view.hwnd #style
    -- No horizontal nonclient border and no right-hand vertical scrollbar:
    -- the measured page-window left/right are the horizontal client bounds.
    local plainClient=origin.x==page.x and(bit.and style 0x00200000)==0
    local good=plainClient,handleCount=0
    caMWNote("MODIFY_LAYOUT page="+(page as string)+" clientOrigin="+(origin as string)+" style="+(style as string)+" horizontalClientKnown="+(plainClient as string))
    for control in view.controls do
    (
        local handles=control.hwnd
        if handles.count==0 do good=false
        local left=undefined,right=undefined
        for handle in handles do
        (
            if not(windows.isWindow handle) then good=false
            else
            (
                local rect=windows.getWindowPos handle removeUIScaling:false
                handleCount+=1
                left=if left==undefined then rect.x else amin left rect.x
                right=if right==undefined then rect.x+rect.w else amax right(rect.x+rect.w)
            )
        )
        caMWNote("MODIFY_CONTROL type="+((classOf control)as string)+" handles="+(handles.count as string)+" physicalLeft="+(left as string)+" physicalRight="+(right as string))
        if left==undefined or right==undefined or left<origin.x or right>page.x+page.w do good=false
    )
    caMWNote("MODIFY_LAYOUT totalControlHWNDs="+(handleCount as string)+" controls="+(view.controls.count as string))
    good and handleCount>=view.controls.count
)
fn caMWAnimHandle value=(if value==undefined then 0L else (getHandleByAnim value)as Integer64)
fn caMWNumericClassID value =
(
    if value==undefined then #(0L,0L)
    else
    (
        local id=value.classID
        #((id[1]as Integer64),(id[2]as Integer64))
    )
)
fn caMWTrackedProvider owner contextNode =
(
    local result=caMWOriginalProvider owner contextNode
    caMWProviderSequence+=1L
    -- sequence, holder, CA, argument-owner, argument-context, four numeric classIDs.
    local record=#(caMWProviderSequence,caMWAnimHandle result[1],caMWAnimHandle result[2],caMWAnimHandle owner,caMWAnimHandle contextNode,caMWNumericClassID result[1],caMWNumericClassID result[2],caMWNumericClassID owner,caMWNumericClassID contextNode)
    if caMWProviderLedger.count>=256 do deleteItem caMWProviderLedger 1
    append caMWProviderLedger record
    result -- The exact real provider tuple, unchanged; native code performs mounting.
)
fn caMWInstallProvider =
(
    if caMWOriginalProvider!=undefined do throw "Owned provider observer is already installed."
    caMWOriginalProvider=caCreateModifyView
    caCreateModifyView=caMWTrackedProvider
    true
)
fn caMWRestoreProvider =
(
    if caMWOriginalProvider!=undefined do
    (
        local original=caMWOriginalProvider
        caCreateModifyView=original
        caMWOriginalProvider=undefined
        caMWCheck "Finally cleanup restores the exact original real provider function" (caCreateModifyView==original)
    )
    true
)
fn caMWProviderIdentity view node =
(
    if view==undefined or caModifierViewOwner==undefined or caMWProviderLedger.count==0 then false
    else
    (
        local record=caMWProviderLedger[caMWProviderLedger.count]
        local active=caModifierViewOwner,activeHandle=caMWAnimHandle caModifierViewOwner
        local id=caMWNumericClassID active,resolvedWindow=active.modifyControls.hwnd
        caMWNote("MODIFY_PROVIDER_IDENTITY lastNumericRecord="+(record as string)+" activeHandle="+(activeHandle as string)+" activeClassID="+(id as string)+" resolvedHWND="+(resolvedWindow as string)+" mountedHWND="+(view.hwnd as string)+" expectedContextHandle="+((caMWAnimHandle node)as string)+" externalRolloutOwner="+((view.owner)as string))
        activeHandle>0 and activeHandle==record[3] and record[2]>0 and record[5]==caMWAnimHandle node and id[1]==0x6a4387d5 and id[2]==0x4fa90372 and caMWEqual id record[7] and resolvedWindow!=0 and resolvedWindow==view.hwnd and windows.isWindow resolvedWindow
    )
)
fn caMWClose =
(
    callbacks.removeScripts id:#CA_ModifierPropsClose
    max create mode
    try(destroyDialog caHomePropsUI)catch()
    try(destroyDialog caHomeUI)catch()
    try(destroyDialog caArrangeUI)catch()
    try(destroyDialog caAssetUI)catch()
    try(destroyDialog caUI)catch()
)
fn caMWModifier node =
(
    local result=undefined
    for modifier in node.modifiers where classOf modifier==CyrusArrange do result=modifier
    result
)
fn caMWOpen node modifier =
(
    max modify mode
    modPanel.setPinStack false
    select node
    modPanel.setCurrentObject modifier node:node ui:true
    local immediateWindow=if caModifierUI==undefined then 0 else caModifierUI.hwnd
    -- Autodesk 2027 Windows Structure, GUID-282F32AC-5A80-4FDB-B8C0-275D2CC15845:
    -- one message pump dispatches queued native/Qt layout events; no retry or manual page creation.
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    local actualObject=modPanel.getCurrentObject(),actualContext=caMWCurrentContext()
    local actualWindow=if caModifierUI==undefined then 0 else caModifierUI.hwnd
    local displayed=caModifierUI!=undefined and caModifierUI.isDisplayed
    caMWNote("MODIFY_MOUNT expectedNode="+(node as string)+" currentObject="+(actualObject as string)+" currentClass="+((classOf actualObject)as string)+" context="+(actualContext as string)+" owner="+((caMWCurrentSetup())as string)+" preHWND="+(immediateWindow as string)+" postHWND="+(actualWindow as string)+" displayed="+(displayed as string))
    local providerIdentity=caModifierUI!=undefined and caMWProviderIdentity caModifierUI node
    caMWCheck "Actual mounted CA matches the real native provider's numeric identity and context" providerIdentity
    actualObject==modifier and actualContext==node and actualWindow!=undefined and actualWindow!=0 and displayed and providerIdentity
)
fn caMWMesh node =
(
    -- snapshotAsMesh already stores world vertices, including WSM. No second TM.
    local value=snapshotAsMesh node renderMesh:false
    local vertices=for i=1 to value.numVerts collect(meshop.getVert value i)
    local faces=for i=1 to value.numFaces collect(getFace value i)
    delete value
    #(vertices,faces)
)
fn caMWSource node =
(
    -- Matrix3 rows are indexed 1..4; there is no MAXScript getRow function.
    local transformValue=node.transform
    local rows=for i=1 to 4 collect transformValue[i]
    local material=node.material
    #(rows,caMWMesh node,material.name,#(material.diffuse.r,material.diffuse.g,material.diffuse.b),material.opacity)
)
fn caMWRecords setup=for row in(caOutputRows setup)collect #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
fn caMWHandles setup=for row in(caOutputRows setup)collect(getHandleByAnim row[9])
fn caMWState setup =
(
    local summary=caSetupSummary setup
    #(summary[1],summary[3],summary[4],summary[5],summary[9],caMWRecords setup,caMWHandles setup,caPlacementSettings setup,caPropMinimums setup)
)
fn caMWOwnerAttribute setup =
(
    local result=undefined
    for i=1 to setup.custAttributes.count do
    (
        local value=setup.custAttributes[i],id=value.classID
        if id.count==2 and(id[1]as Integer64)==0x6a4387d2 and(id[2]as Integer64)==0x4fa90372 do
        (
            if result!=undefined do throw "Duplicate native owner attributes in owned fixture."
            result=#(i,value)
        )
    )
    if result==undefined do throw "Actual native owner attribute not found."
    result
)
fn caMWPhysical setup =
(
    local rows=caOutputRows setup, good=rows.count>0, boxes=#()
    for row in rows do
    (
        local bounds=nodeGetBoundingBox row[9](matrix3 1)
        local size=bounds[2]-bounds[1]
        local small=abs(size.x-40)<0.02 and abs(size.y-40)<0.02 and abs(size.z-40)<0.02
        local broad=((abs(size.x-80)<0.02 and abs(size.y-60)<0.02)or(abs(size.x-60)<0.02 and abs(size.y-80)<0.02))and abs(size.z-20)<0.02
        if not(small or broad)or abs(bounds[1].z-320)>0.02 or row[6]!=1 do good=false
        if bounds[1].x < -300.02 or bounds[2].x > 300.02 or bounds[1].y < -150.02 or bounds[2].y > 150.02 do good=false
        append boxes bounds
    )
    -- Cardinal yaw means these independently measured boxes are exact prop boxes.
    for a=1 to boxes.count do for b=a+1 to boxes.count do
    (
        local first=boxes[a],second=boxes[b]
        local separated=first[2].x<=second[1].x+0.002 or second[2].x<=first[1].x+0.002 or first[2].y<=second[1].y+0.002 or second[2].y<=first[1].y+0.002
        if not separated do good=false
    )
    good
)

fn caMWRun =
(
    caMWClose()
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1
    CA_AUTO_SHOW_UI=false
    fileIn(CA_TEST_ROOT+"scripts/CyrusArrange.ms")
    fileIn(CA_TEST_ROOT+"scripts/ArrangeAssets.ms")
    fileIn(CA_TEST_ROOT+"scripts/ArrangeWorkflow.ms")
    fileIn(CA_TEST_ROOT+"scripts/ArrangeModifier.ms")
    caMWRequire "Dedicated exact 0.3.2 Max 2027 host" ((maxVersion())[1]==29000 and caVersion()=="0.3.2")
    caMWRequire "Actual command panel requires the private interactive Max host" (not maxOps.isInNonInteractiveMode())
    caMWRequire "Matching transient Modify provider is loaded" (caCreateModifyView!=undefined and caModifyViewDefinition!=undefined)
    caMWInstallProvider()
    caMWNote "STAGE actual native modifier on unbound furniture"
    local top=box name:"MW_Furniture" width:600 length:300 height:20 pos:[0,0,300]
    local topBefore=caMWMesh top
    local first=box name:"MW_Original_Broad" width:80 length:60 height:20 pos:[2500,0,0]
    first.material=standardMaterial name:"MW_Terracotta" diffuse:(color 160 64 35)
    local second=box name:"MW_Original_Small" width:40 length:40 height:40 pos:[2700,0,0]
    second.material=standardMaterial name:"MW_Green" diffuse:(color 35 120 70)
    local firstBefore=caMWSource first,secondBefore=caMWSource second
    local arrangeModifier=CyrusArrange()
    local nativeKind=isKindOf arrangeModifier Modifier,nativeScripted=isMSPlugin arrangeModifier
    caMWNote("MODIFIER_CLASS class="+((classOf arrangeModifier)as string)+" superclass="+((superClassOf arrangeModifier)as string)+" classID="+(arrangeModifier.classID as string)+" kindOfModifier="+(nativeKind as string)+" isMSPlugin="+(nativeScripted as string))
    caMWCheck "Cyrus Arrange constructor returns an actual native modifier" (nativeKind and not nativeScripted)
    addModifier top arrangeModifier
    caMWCheck "Adding stateless modifier preserves actual furniture vertices and faces" (caMWEqual topBefore(caMWMesh top))
    caMWCheck "Adding modifier does not create a document or outputs" ((caSceneSetups #()).count==0)
    caMWNote "STAGE off-scene real CA provider contract before native mounting"
    local providerNodes=caMWSceneHandles()
    local firstView=caCreateModifyView undefined top,secondView=caCreateModifyView undefined first
    caMWRequire "Provider returns an off-scene modifier, its actual CA and its own rollout" (firstView.count==3 and classOf firstView[1]==EmptyModifier and firstView[1].custAttributes.count==1 and firstView[1].custAttributes[1]==firstView[2] and firstView[2].modifyControls==firstView[3])
    local viewID=firstView[2].classID
    caMWCheck "UI-only CA has the exact presentation class identity and zero parameter blocks" ((viewID[1]as Integer64)==0x6a4387d5 and(viewID[2]as Integer64)==0x4fa90372 and(custAttributes.getPBlockDefs caModifyViewDefinition).count==0)
    caMWCheck "Separate provider calls own distinct holders and actual CA instances" (firstView[1]!=secondView[1] and firstView[2]!=secondView[2])
    caMWNote("PROVIDER_LAYOUT sharedRollout="+((firstView[3]==secondView[3])as string)+" firstBinding="+((firstView[2].bindingSnapshot())as string)+" secondBinding="+((secondView[2].bindingSnapshot())as string))
    caMWCheck "CA-instance pending bindings remain independent before the class rollout opens" ((firstView[2].bindingSnapshot())[2]==top and(secondView[2].bindingSnapshot())[2]==first)
    firstView[2].releaseView()
    caMWCheck "Releasing one off-scene CA retains another CA's independent pending binding" ((firstView[2].bindingSnapshot())[2]==undefined and(secondView[2].bindingSnapshot())[2]==first)
    caMWCheck "Creating provider values neither mounts controls nor adds scene nodes or a document" (firstView[3].hwnd==0 and secondView[3].hwnd==0 and caModifierUI==undefined and caModifierViewOwner==undefined and caMWEqual providerNodes(caMWSceneHandles()) and(caSceneSetups #()).count==0)
    secondView[2].releaseView()
    firstView=undefined;secondView=undefined
    local beforeNativeProvider=caMWProviderSequence
    caMWRequire "Actual modPanel context mounts the native-hosted rollout" (caMWOpen top arrangeModifier)
    caMWCheck "Actual native panel mounting invoked the unchanged real provider" (caMWProviderSequence>beforeNativeProvider)
    caMWNote "CONTEXT_LIMIT external rollout.owner was undefined outside events in preserved dev10; identity is proved by the actual native provider handoff and active CA's native handle, classID and displayed HWND."
    caMWCheck "Native mounted CA retains and hydrates its captured furniture context" ((caModifierViewOwner.bindingSnapshot())[2]==top and(caModifierViewOwner.bindingSnapshot())[4] and caModifierUI.currentContext()==top)
    caMWCheck "Real CA mounting remains in the actual Modify task mode" ((getCommandPanelTaskMode())==#modify)
    caMWNote("MODIFY_LAYOUT logicalPageWidth="+(caModifierUI.width as string)+" compactAuthoredRight=152")
    caMWCheck "Every actual Modify control HWND union fits horizontally inside the page client" (caMWControlsFit caModifierUI)
    caMWCheck "Modifier applies to the selected furniture in the actual Modify panel" (modPanel.validModifier CyrusArrange)
    caMWCheck "Unbound rollout offers explicit creation without hidden setup creation" (caModifierUI.currentSetup()==undefined and caModifierUI.useReceiverButton.enabled and(caSceneSetups #()).count==0)
    caMWRequire "Actual Modify Create button creates one furniture arrangement" (caModifierUI.useReceiverButton.pressed())
    local setup=caModifierUI.currentSetup()
    caMWRequire "Created setup is a real icon owner with exactly one actual native modifier" (isValidNode setup and classOf setup.baseObject==CyrusArrangeIcon and setup.modifiers.count==1 and classOf setup.modifiers[1]==CyrusArrange)
    setup.name="MW_Setup_A"
    local iconBounds=nodeGetBoundingBox setup(matrix3 1),iconSize=iconBounds[2]-iconBounds[1]
    caMWNote("ICON_BOUNDS min="+(iconBounds[1]as string)+" max="+(iconBounds[2]as string)+" size="+(iconSize as string))
    caMWCheck "Icon owner is nonrenderable with a nonzero 120 by 120 by 48 mm glyph extent" (not setup.renderable and abs(iconSize.x-120)<0.02 and abs(iconSize.y-120)<0.02 and abs(iconSize.z-48)<0.02)
    caMWCheck "New icon is positioned at the actual first furniture pivot" (distance setup.pos top.pos<0.002)
    caMWCheck "Create binds receiving references without analyzing geometry" ((caReceiverNodes setup).count==1 and(caReceiverNodes setup)[1]==top and(caSetupSummary setup)[5]==0 and(caGeometryCacheInfo setup)[3]==undefined)
    caMWCheck "Original furniture modifier resolves the same sole native document" ((caSceneSetups #(top))[1][1]==setup and(caSceneSetups #()).count==1)

    caMWNote "STAGE passive icon selection, panel lifecycle and inline prop selection"
    local state=caMWState setup,ticket=caGeometryDependencyInfo setup,cacheLast=(caGeometryCacheInfo setup)[3],countBefore=objects.count,handlesBeforeViews=caMWSceneHandles()
    local priorAttribute=undefined
    for i=1 to 3 do
    (
        caMWRequire "Icon modifier really mounts" (caMWOpen setup setup.modifiers[1])
        caMWCheck "Mounted icon binds the existing document" (caModifierUI.currentSetup()==setup)
        local activeAttribute=caModifierViewOwner
        if priorAttribute!=undefined do
        (
            caMWCheck "Reopening binds a distinct actual CA while the old CA remains released" (activeAttribute!=priorAttribute and not(priorAttribute.bindingSnapshot())[4] and(priorAttribute.bindingSnapshot())[1]==undefined)
            priorAttribute.releaseView()
            caMWCheck "Late old-CA cleanup cannot clear the new CA's shared active rollout" (caModifierViewOwner==activeAttribute and caModifierUI==activeAttribute.modifyControls and caModifierUI.currentSetup()==setup)
            caMWCheck "Retired actual CA commands reject instead of targeting the new CA's controls" (not(priorAttribute.dispatch #refresh) and not(priorAttribute.dispatch #addProps data:#(first)) and not(priorAttribute.dispatch #generate) and caMWEqual state(caMWState setup))
        )
        priorAttribute=activeAttribute
        caMWRequire "Saved settings refresh is passive" (caModifierViewOwner.dispatch #refresh)
        max create mode
        caMWCheck "Native EndEdit closes and releases its exact CA binding" (caModifierUI==undefined and caModifierViewOwner==undefined and not(priorAttribute.bindingSnapshot())[4] and(priorAttribute.bindingSnapshot())[1]==undefined and(priorAttribute.bindingSnapshot())[2]==undefined)
        if i==1 do caMWCheck "Closed actual CA command path rejects without native mutation" (not(priorAttribute.dispatch #generate) and not(priorAttribute.dispatch #refresh) and not(priorAttribute.dispatch #addProps data:#(first)) and caMWEqual state(caMWState setup))
    )
    caMWCheck "Selection and panel open-close keep full document, epochs and native work unchanged" (caMWEqual state(caMWState setup) and caMWEqual ticket(caGeometryDependencyInfo setup) and caMWEqual cacheLast(caGeometryCacheInfo setup)[3] and objects.count==countBefore and caMWEqual handlesBeforeViews(caMWSceneHandles()) and caMWNoSceneViewAttributes())
    caMWRequire "Original geometry modifier reopens to its arrangement" (caMWOpen top arrangeModifier)
    modPanel.setPinStack true
    select #(first,second)
    caMWRequire "Pinned inline Add selected props registers both originals" (caModifierViewOwner.propControls.addSelection.pressed())
    caMWCheck "Bulk intake registers both original props in the same document" ((caAssetRows setup).count==2 and(caSceneSetups #()).count==1)
    caMWCheck "Inline prop intake preserves physical meshes transforms and materials" (caMWEqual firstBefore(caMWSource first) and caMWEqual secondBefore(caMWSource second))
    local catalogBeforeClose=caAssetRows setup, groupAttribute=caModifierViewOwner
    callbacks.addScript #selectionSetChanged "max create mode" id:#CA_ModifierPropsClose persistent:false
    groupAttribute.propControls.groupName.text="MW_Callback_Closed_Group"
    local groupAccepted=groupAttribute.dispatch #groupProps data:#(first,second)
    callbacks.removeScripts id:#CA_ModifierPropsClose
    caMWCheck "Selection callback closing Modify after group publication retains accepted success" (groupAccepted and(caAssetRows setup).count==3)
    local closedState=caMWState setup
    if groupAttribute.isActiveView() do max create mode
    caMWCheck "Retired inline Add rejects without catalog or placement mutation" (not(groupAttribute.dispatch #addProps data:#(first)) and caMWEqual closedState(caMWState setup))
    caMWCheck "Retired inline group rejects without mutation" (not(groupAttribute.dispatch #groupProps data:#(first,second)) and caMWEqual closedState(caMWState setup))
    max undo
    caMWCheck "One group Undo restores prior catalog after callback closed its view" (caMWEqual catalogBeforeClose(caAssetRows setup))

    caMWNote "STAGE actual Modify Generate fresh and exact-repeat seed"
    caMWRequire "Populated arrangement icon mounts" (caMWOpen setup setup.modifiers[1])
    caMWCheck "Fresh variation default hides and disables seed entry" (not caModifierUI.keepSeed.checked and not caModifierUI.seedText.visible and not caModifierUI.seedText.enabled)
    caModifierUI.quantity.value=6;caModifierUI.spacing.value=12
    caModifierUI.seedText.text="ignored hidden draft"
    local oldSeed=(caSetupSummary setup)[9][1]
    caMWRequire "Actual Modify Generate accepts hidden invalid seed in fresh mode" (caModifierUI.generateButton.pressed())
    caMWCheck "Successful Generate stages a different nonnegative native seed" ((caSetupSummary setup)[9][1]!=oldSeed and(caSetupSummary setup)[9][1]>=0)
    caMWCheck "Copies and gap commit through Generate" ((caPlacementSettings setup)[2]==2 and(caPlacementSettings setup)[3]==6 and(caPlacementSettings setup)[5]==12)
    caMWCheck "Generated full-size actual boxes fit independently measured furniture bounds" (caMWPhysical setup)
    caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale
    caMWCheck "Repeat seed exposes exact seed entry" (caModifierUI.seedText.visible and caModifierUI.seedText.enabled)
    caModifierUI.seedText.text="9223372036854775000"
    caMWRequire "Modify Repeat supports exact large Integer64 input" (caModifierUI.generateButton.pressed())
    caMWCheck "Shared exact parser and native state preserve all seed digits" ((caSetupSummary setup)[9][1]==9223372036854775000L and caModifierUI.seedText.text=="9223372036854775000")
    local poses=caMWRecords setup
    caMWRequire "Actual Modify Repeat generates again" (caModifierUI.generateButton.pressed())
    caMWCheck "Repeated modifier generation retains exact ordered native poses" (caMWEqual poses(caMWRecords setup))
    local movedState=caMWState setup,geometryEpoch=(caGeometryDependencyInfo setup)[4]
    undo "MW move viewport icon" on(setup.pos += [400,-250,80])
    caMWCheck "Moving only the icon preserves saved native state and actual outputs" (caMWEqual movedState(caMWState setup))
    caMWCheck "Moving only the icon preserves furniture dependency geometry epoch" ((caGeometryDependencyInfo setup)[4]==geometryEpoch)
    caMWRequire "Repeat Generate after icon-only movement succeeds" (caModifierUI.generateButton.pressed())
    caMWCheck "Moving icon cannot translate generated furniture props" (caMWEqual poses(caMWRecords setup) and caMWPhysical setup)
    state=caMWState setup
    caModifierUI.seedText.text="9223372036854775808"
    caMWCheck "Overflow seed rejects through actual Modify handler" (not caModifierUI.generateButton.pressed())
    caMWCheck "Rejected seed retains full accepted settings records and real node handles" (caMWEqual state(caMWState setup))
    caModifierUI.seedText.text="9223372036854775000"

    caMWNote "STAGE one-Undo native generation and owner switching"
    state=caMWState setup
    caModifierUI.keepSeed.checked=false;caModifierViewOwner.dispatch #scale
    caMWRequire "Second fresh Modify Generate succeeds" (caModifierUI.generateButton.pressed())
    local after=caMWState setup
    caMWCheck "Second fresh variation changes seed" (after[5][1]!=state[5][1])
    max create mode
    max undo
    caMWCheck "One Undo restores the complete prior native result and real output identities" (caMWEqual state(caMWState setup))
    max redo
    caMWCheck "One Redo restores complete accepted modifier generation" (caMWEqual after(caMWState setup))
    local otherTop=box name:"MW_Other_Furniture" width:700 length:350 height:30 pos:[0,1800,400]
    local other=caCreateArrangement();caBindReceivers other #(otherTop)
    other.name="MW_Setup_B"
    local otherSettings=(caSetupSummary other)[9];otherSettings[3]=31
    caSetArrangeSettings other otherSettings
    caMWRequire "Other icon mounts without floating main window" (caMWOpen other other.modifiers[1])
    caMWCheck "Switching owners reads only the other native settings" (caModifierUI.currentSetup()==other and caModifierUI.quantity.value==100 and caModifierUI.spacing.value==31)
    state=caMWState setup
    caMWCheck "Other owner Generate with no props reports bounded failure" (not caModifierUI.generateButton.pressed())
    caMWCheck "Wrong owner action leaves first accepted document and output nodes unchanged" (caMWEqual state(caMWState setup))
    caMWRequire "Return to first icon mounts first document" (caMWOpen setup setup.modifiers[1])
    caMWCheck "Returning owner hydrates its saved settings rather than other drafts" (caModifierUI.currentSetup()==setup and caModifierUI.spacing.value==12 and caModifierUI.quantity.value==6)
    local beforeAlias=caMWState setup
    caShowArrangeUI setup:setup
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caMWCheck "Public entry focuses the same document in Modify without publication" (caMWCurrentSetup()==setup and caMWEqual beforeAlias(caMWState setup))

    caMWNote "STAGE actual same-node native Document replacement and captured-identity guards"
    -- Prepare the independent valid source before mounting the view under test.
    local fresh=box name:"MW_Identity_Valid_Original" width:25 length:25 height:25 pos:[3000,0,0]
    fresh.material=standardMaterial name:"MW_Identity_Material" diffuse:(color 100 90 80)
    caMWRequire "First icon mounts before document-replacement fixture" (caMWOpen setup setup.modifiers[1])
    modPanel.setPinStack true
    local originalGuid=(caSetupSummary setup)[1],originalState=caMWState setup,ownerHandle=getHandleByAnim setup
    local capturedViewAttribute=caModifierViewOwner,capturedViewToken=caModifierUI.captureBinding()
    local originalAttribute=caMWOwnerAttribute setup
    caMWRequire "Real native owner attribute has its one Document reference" ((refs.getNumRefs originalAttribute[2])==1)
    local originalDocument=refs.getReference originalAttribute[2] 1
    local replacement=(copy originalAttribute[2])
    caMWRequire "Native attribute copy supplies a distinct cloned Document reference" ((refs.getNumRefs replacement)==1 and(refs.getReference replacement 1)!=originalDocument)
    -- No intervening object construction or selection between this gate and replacement.
    caMWRequire "Actual replacement begins with the exact captured CA token and original GUID mounted" (caModifierUI!=undefined and caModifierViewOwner==capturedViewAttribute and capturedViewAttribute.isActiveView() and caMWEqual capturedViewToken(caModifierUI.captureBinding()) and caModifierUI.currentSetup()==setup and caModifierUI.currentDocumentID()==originalGuid)
    undo "MW replace native document on the same icon" on(setup.custAttributes[originalAttribute[1]]=replacement)
    local replacementSummary=caSetupSummary setup
    caMWRequire "Real indexed native CA replacement changes Document GUID on the same live owner" (getHandleByAnim setup==ownerHandle and replacementSummary[1]!=originalGuid and setup.custAttributes.count==1)
    local replacementState=caMWState setup
    local retained=caModifierUI!=undefined and caModifierViewOwner==capturedViewAttribute
    caMWNote("DOCUMENT_REPLACEMENT retainedCapturedView="+(retained as string)+" currentCA="+(caModifierViewOwner as string)+" retiredBinding="+((capturedViewAttribute.bindingSnapshot())as string)+" oldGUID="+originalGuid+" newGUID="+replacementSummary[1])
    if retained then
    (
        caMWRequire "A retained Modify view keeps its captured old GUID rather than silently rebinding" (caModifierUI.currentSetup()==setup and caModifierUI.currentDocumentID()==originalGuid and caMWEqual capturedViewToken(caModifierUI.captureBinding()))
    )
    else
    (
        caMWCheck "A closed or rebuilt Modify panel retires the exact previously active CA" (not capturedViewAttribute.isActiveView())
    )
    local rejectedCommands=#(not(capturedViewAttribute.dispatch #generate),not(capturedViewAttribute.dispatch #addProps data:#(fresh)),not(capturedViewAttribute.dispatch #groupProps data:#(first,fresh)),not(capturedViewAttribute.dispatch #selectIcon),not(capturedViewAttribute.dispatch #useReceiver))
    caMWNote("DOCUMENT_REPLACEMENT rejectedCapturedCommands="+(rejectedCommands as string))
    caMWCheck "Every captured Modify command rejects the replacement or its retired view" ((findItem rejectedCommands false)==0)
    caMWCheck "Rejected captured-view commands retain the full replacement document and real output bindings" (caMWEqual replacementState(caMWState setup))
    select fresh
    caMWRequire "GUID rejection uses an actual valid independent original selection" (selection.count==1 and selection[1]==fresh and(classOf fresh)==Box and(caMWMesh fresh)[2].count==12)
    caMWCheck "Captured inline Add rejects a different GUID despite a valid original selection" (not(capturedViewAttribute.dispatch #addProps data:#(fresh)) and caMWEqual replacementState(caMWState setup))
    max undo
    caMWCheck "One Undo restores the original exact native Document and accepted output bindings" (caMWEqual originalState(caMWState setup))
    modPanel.setPinStack false
    caMWRequire "Reselecting restored icon intentionally binds its current native Document" (caMWOpen setup setup.modifiers[1])

    caMWNote "STAGE helper guard, saved icon lifecycle and setup-only clone"
    local emptyHelper=point name:"MW_Unbound_Helper" pos:[0,-1800,0]
    local helperModifier=CyrusArrange();addModifier emptyHelper helperModifier
    caMWRequire "Actual modifier on an unbound helper mounts" (caMWOpen emptyHelper helperModifier)
    local setupCount=(caSceneSetups #()).count
    caMWCheck "Unbound helper cannot be used as receiving geometry" (not(caModifierUI.useReceiverButton.pressed()))
    caMWCheck "Helper is never silently registered as furniture or replaced by another icon" ((caSceneSetups #()).count==setupCount and caMWCurrentSetup()==undefined)
    max create mode
    local originals,copies
    caMWRequire "Real setup-only native icon clone succeeds" (maxOps.cloneNodes #(setup) cloneType:#copy expandHierarchy:false actualNodeList:&originals newNodes:&copies)
    local clone=copies[findItem originals setup]
    clone.name="MW_Setup_Clone"
    caMWRequire "Cloned icon retains one real modifier and a distinct document" (clone.modifiers.count==1 and classOf clone.modifiers[1]==CyrusArrange and(caSetupSummary clone)[1]!=(caSetupSummary setup)[1])
    caMWCheck "Setup-only clone does not claim original generated nodes" ((caOutputRows clone).count==0)
    caMWRequire "Cloned icon mounts its own native document" (caMWOpen clone clone.modifiers[1])
    caMWCheck "Cloned Modify controls do not retain original owner" (caModifierUI.currentSetup()==clone)
    local originalState=caMWState setup
    caMWRequire "Clone Modify Generate publishes independently" (caModifierUI.generateButton.pressed())
    caMWCheck "Clone generation retains original accepted state and identities" (caMWEqual originalState(caMWState setup))
    local cloneAttribute=caModifierViewOwner
    local cloneGuid=(caSetupSummary clone)[1]
    max create mode
    undo "MW delete owner" on(delete clone)
    select first
    caMWCheck "Retired inline Add rejects a deleted real owner" (not(cloneAttribute.dispatch #addProps data:#(first)))
    max undo
    clone=getNodeByName "MW_Setup_Clone" exact:true
    caMWRequire "Owner deletion Undo restores real icon document and modifier" (isValidNode clone and(caSetupSummary clone)[1]==cloneGuid and clone.modifiers.count==1)
    caMWRequire "Restored icon really mounts again" (caMWOpen clone clone.modifiers[1])
    caMWCheck "Restored panel binds the Undo-restored document" (caModifierUI.currentSetup()==clone)
    max create mode
    local expectedSettings=(caSetupSummary setup)[9], expectedRecords=caMWRecords setup, guid=(caSetupSummary setup)[1]
    local scene=CA_TEST_OUTPUT+"CyrusArrange-Modifier-Workflow.max"
    caMWCheck "Transient presentation CAs are absent from every scene node base object and modifier" (caMWNoSceneViewAttributes())
    caMWRequire "Actual native modifier scene saves" (saveMaxFile scene quiet:true)
    caMWRequire "Actual native modifier scene reopens" (loadMaxFile scene useFileUnits:true quiet:true)
    setup=getNodeByName "MW_Setup_A" exact:true
    top=getNodeByName "MW_Furniture" exact:true
    first=getNodeByName "MW_Original_Broad" exact:true
    second=getNodeByName "MW_Original_Small" exact:true
    caMWRequire "Saved icon and original furniture retain native modifiers" (isValidNode setup and classOf setup.baseObject==CyrusArrangeIcon and setup.modifiers.count==1 and caMWModifier top!=undefined)
    caMWCheck "Save reopen preserves native GUID settings and complete ordered output records" ((caSetupSummary setup)[1]==guid and caMWEqual expectedSettings(caSetupSummary setup)[9] and caMWEqual expectedRecords(caMWRecords setup))
    caMWCheck "Reloaded scene contains no UI-only holder CA on scene objects" (caMWNoSceneViewAttributes())
    caMWRequire "Reloaded icon mounts native Modify controls" (caMWOpen setup setup.modifiers[1])
    caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale
    caMWRequire "Reloaded Repeat seed actual Modify action succeeds" (caModifierUI.generateButton.pressed())
    caMWCheck "Reloaded modifier repeats exact saved physical poses" (caMWEqual expectedRecords(caMWRecords setup))
    caMWCheck "Reloaded full-size actual output remains physically supported" (caMWPhysical setup)
    caMWCheck "Original physical prop meshes and materials survive all interactions and save-load" (caMWEqual firstBefore(caMWSource first) and caMWEqual secondBefore(caMWSource second))
    caMWNote "SCOPE actual native modifier class, mounted Modify rollout, captured document actions, original procedural boxes, Undo/Redo, clone and save/load. No CUA, pixel/DPI or renderer claim."
    caMWClose()
    true
)
try(caMWRun())catch
(
    caMWFailures+=1
    caMWNote("EXCEPTION "+(getCurrentException()as string))
    caMWNote("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string))
    caMWNote("STACK "+(getCurrentExceptionStackTrace()as string))
    try(caMWClose())catch
    (
        caMWFailures+=1
        caMWNote("CLEANUP_EXCEPTION "+(getCurrentException()as string))
    )
)
-- MAXScript has no finally clause: this unconditional cleanup follows both paths.
caMWRestoreProvider()
caMWFinished=true;caMWWrite()

/* Cyrus Arrange 0.3.2: one transient CA view in the native Modify panel.
   Numeric work, persistence and atomic publication belong to the C++ Document. */
global caModifierUI, caModifierViewOwner, caCreateModifyView, caModifyViewDefinition
global caCreateArrangement, caBindReceivers, caReceiverNodes, caSceneSetups, caSetupSummary
global caPlacementSettings, caGeneratePlacement, caReadExactSeed, caAssetRows, caOutputRows
global caRegisterAssets, caCreatePropGroup, caRemoveAssets, caSetLocked
global caPropMinimums, caGeneratePlacementMinimums, caGeneratePathMinimums
global caBindPath, caClearPath, caPathSettings, caGenerateAlongPath, caIsSplinePath, caInputKind
global caCollisionScope, caAddObstacles, caRemoveObstacle
global caFitFeedback, caShowFitFeedback, caHideFitFeedback, caFitHighlightInfo

global caFocusArrange, caShowArrangeUI, caShowAdvancedArrangeUI, caShowHomePropsUI
global caShowAssetUI, caShowRegionUI, caShowCollisionUI, caShowCompositionUI, caShowRulesUI, caShowUI

caModifyViewDefinition = attributes CyrusArrangeModifyView version:9 attribID:#(0x6a4387d5,0x4fa90372) initialRollupState:0x1c
(
    local modifyControls, propControls, scaleControls, protectionControls, pathControls
    local pendingOwner = undefined, pendingContext = undefined, pendingSerial = 0, viewMounted = false
    fn bindView owner node = (pendingSerial += 1; pendingOwner = owner; pendingContext = node; true)
    fn bindingSnapshot = #(pendingOwner,pendingContext,pendingSerial,viewMounted)
    fn beginView = (viewMounted = true; true)
    fn isActiveView = viewMounted and caModifierViewOwner == this and caModifierUI == modifyControls
    fn dispatch action data:undefined = (if isActiveView() then modifyControls.command action data:data else false)
    fn amountChanged value = dispatch #scale
    fn releaseView =
    (
        local oldOwner=pendingOwner
        pendingSerial += 1; pendingOwner = undefined; pendingContext = undefined; viewMounted = false
        if caModifierViewOwner == this do (if isValidNode oldOwner do caHideFitFeedback oldOwner;caModifierUI = undefined; caModifierViewOwner = undefined)
        true
    )
    rollout modifyControls "Cyrus Arrange" width:#cmdPanel height:546
    (
        local boundAttribute = undefined, setupNode = undefined, contextNode = undefined
        local mounted = false, bindingSerial = 0, ownerGuid = undefined, loadedSettings = #(), loadedPath = #(), pathActive = false, propRows = #(), loadedMinimums = #(), minimumDrafts = #(), hydratingMinimum = false, lastError = ""
        local obstacleRows = #(), obstacleRevision = 0, loadedApproach = false, scopeLoaded = false, collisionViewHydrated = false
        local refreshFitFeedback
        label intro "Choose geometry, add props, Generate." pos:[10,8] width:142 height:30
        label receiverInfo "No receiving geometry." pos:[10,42] width:142 height:38
        button useReceiverButton "Use this geometry" pos:[10,84] width:142 height:27
        button pickReceiverButton "Pick receiving objects" pos:[10,117] width:142 height:27 tooltip:"Pick one or more objects or groups. Right-click to finish. Replaces this arrangement's receiving geometry."
        dropdownList amountMode "Placement amount:" items:#("Quantity","Fill available space") selection:1 pos:[10,153] width:142
        spinner quantity "Copies:" range:[0,2000,100] type:#integer pos:[10,210] width:142 fieldWidth:52
        spinner fillAmount "Fill (%):" range:[0,100,10] type:#float pos:[10,240] width:142 fieldWidth:52
        spinner spacing "Gap (mm):" range:[0,1000000,20] type:#float pos:[10,270] width:142 fieldWidth:52
        button generateButton "Generate" pos:[10,304] width:142 height:36 tooltip:"Applies the visible placement and scale settings. Creates a new variation unless Repeat seed is checked."
        checkbox keepSeed "Repeat seed" checked:false pos:[10,348] width:142
        editText seedText "Seed:" text:"1" pos:[10,375] width:142 visible:false enabled:false
        editText statusText "" text:"Choose receiving geometry, then add original props below." readOnly:true pos:[10,410] width:142 height:125

        fn captureBinding = #(boundAttribute,bindingSerial)
        fn isCurrentView ticket = mounted and ticket.count == 2 and ticket[1] != undefined and ticket[1] == boundAttribute and ticket[2] == bindingSerial and caModifierViewOwner == boundAttribute
        fn sameBinding node ticket = isCurrentView ticket and setupNode == node and isValidNode node
        fn currentSetup = (if isCurrentView (captureBinding()) and isValidNode setupNode then setupNode else undefined)
        fn currentContext = (if isCurrentView (captureBinding()) and isValidNode contextNode then contextNode else undefined)
        fn currentDocumentID = (if isCurrentView (captureBinding()) then ownerGuid else undefined)
        fn errorMessage = lastError
        fn decimal value = trimRight (value as string) "Ll"
        fn fail message = (lastError = message as string; if mounted do statusText.text = lastError; false)
        fn ownerSummary node ticket =
        (
            if not (sameBinding node ticket) do throw "Select this arrangement's modifier first."
            local summary = caSetupSummary node
            if ownerGuid == undefined or summary[1] != ownerGuid do throw "The arrangement changed. Select its icon again."
            summary
        )
        fn hydrateBinding attribute =
        (
            local binding = attribute.bindingSnapshot()
            boundAttribute = attribute; bindingSerial = binding[3]; setupNode = binding[1]; contextNode = binding[2]
            ownerGuid = undefined; loadedSettings = #(); loadedPath = #(); pathActive = false; propRows = #(); loadedMinimums = #(); minimumDrafts = #(); lastError = ""
            obstacleRows = #(); obstacleRevision = 0; loadedApproach = false; scopeLoaded = false; collisionViewHydrated = false; true
        )
        fn setBinding owner node = (boundAttribute.bindView owner node; hydrateBinding boundAttribute)
        fn minimumValue values id = (local value=0; for row in values where row[1]==id do value=row[2]; value)
        fn updateMinimumLabels selected:undefined =
        (
            local list=boundAttribute.propControls.propList,index=if selected==undefined then boundAttribute.propControls.propList.selection else selected
            list.items=for row in propRows collect(row[2]+(if minimumValue minimumDrafts row[1]>0 then " [min "+((minimumValue minimumDrafts row[1])as string)+"]" else "")+(if row[10] then "" else " [source missing]"))
            if index>=0 and index<=propRows.count do list.selection=index
            true
        )
        fn syncMinimumControl =
        (
            local view=boundAttribute.propControls,index=view.propList.selection
            hydratingMinimum=true
            view.minimumCopies.enabled=isValidNode setupNode and index>0 and index<=propRows.count
            view.minimumCopies.value=if index>0 and index<=propRows.count then minimumValue minimumDrafts propRows[index][1] else 0
            hydratingMinimum=false;refreshFitFeedback();true
        )
        fn refreshFitFeedback =
        (
            local view=boundAttribute.propControls, index=boundAttribute.propControls.propList.selection, data=undefined, info=undefined
            if isValidNode setupNode do
            (
                info=caFitHighlightInfo setupNode
                if index>0 and index<=propRows.count do data=caFitFeedback setupNode propRows[index][1]
                if info[1] and(index<1 or index>propRows.count or info[3]!=propRows[index][1])do(caHideFitFeedback setupNode;info=undefined)
            )
            local shown=data!=undefined and data[1]
            if not shown and info!=undefined and info[1]do(caHideFitFeedback setupNode;info=undefined)
            view.fitText.visible=shown;view.showFit.visible=shown;view.useFit.visible=shown
            view.fitText.text=if shown then data[2] else ""
            view.showFit.enabled=shown and data[6];view.useFit.enabled=shown and data[13]>0
            view.showFit.text=if shown and info!=undefined and info[2] then "Hide fit space" else "Show fit space"
            local extra=if shown then 180 else 0
            for row in #(#(view.pickProps,200),#(view.addSelection,232),#(view.removeProp,264),#(view.groupName,300),#(view.groupProps,336),#(view.selectIcon,368))do row[1].pos=[10,row[2]+extra]
            view.height=400+extra;true
        )
        fn readMinimumDraft = (for row in minimumDrafts where row[2]>0 collect #(row[1],row[2]))
        fn showMinimumDraft values = (minimumDrafts=for row in propRows collect #(row[1],minimumValue values row[1]);updateMinimumLabels();syncMinimumControl())
        fn syncObstacleControls =
        (
            local view=boundAttribute.protectionControls, ready=isValidNode setupNode, index=boundAttribute.protectionControls.obstacleList.selection
            view.pickObstacles.enabled=ready;view.clearApproach.enabled=ready;view.edgeGap.enabled=ready
            view.removeObstacle.enabled=ready and index>0 and index<=obstacleRows.count
            true
        )
        fn refreshCollision preserveDrafts:false =
        (
            local view=boundAttribute.protectionControls, draft=undefined
            if preserveDrafts and collisionViewHydrated and scopeLoaded and view.clearApproach.checked!=loadedApproach do draft=view.clearApproach.checked
            local selected=if view.obstacleList.selection>0 and view.obstacleList.selection<=obstacleRows.count then obstacleRows[view.obstacleList.selection][1] else undefined
            if isValidNode setupNode then
            (
                local data=caCollisionScope setupNode
                obstacleRows=data[2];obstacleRevision=(caSetupSummary setupNode)[3];loadedApproach=data[1];scopeLoaded=true
            )
            else (obstacleRows=#();obstacleRevision=0;loadedApproach=false;scopeLoaded=false)
            view.clearApproach.checked=if draft==undefined then loadedApproach else draft
            view.obstacleList.items=for row in obstacleRows collect((if isValidNode row[1] then "" else "Missing: ")+(row[2] as string))
            local index=0
            if isValidNode selected do for i=1 to obstacleRows.count where obstacleRows[i][1]==selected do index=i
            view.obstacleList.selection=index
            view.obstacleInfo.text=if obstacleRows.count==0 then "Receiver collisions are automatic. Add other scene objects to avoid." else (obstacleRows.count as string)+" external obstacle(s)."
            syncObstacleControls();true
        )
        fn syncControls =
        (
            local ready = isValidNode setupNode
            quantity.enabled = ready and amountMode.selection == 1
            fillAmount.enabled = ready and not pathActive and amountMode.selection == 2
            fillAmount.visible = not pathActive
            amountMode.enabled = ready; spacing.enabled = ready; generateButton.enabled = ready; keepSeed.enabled = ready
            seedText.visible = keepSeed.checked; seedText.enabled = ready and keepSeed.checked
            local scaleView = boundAttribute.scaleControls
            scaleView.minimumScale.enabled = ready and (scaleView.randomScale.checked or scaleView.fitScale.checked)
            scaleView.maximumScale.enabled = ready and scaleView.randomScale.checked
            local p=boundAttribute.pathControls, l=boundAttribute.pathControls, v=boundAttribute.pathControls
            p.curveIndex.enabled=ready and pathActive; p.align.enabled=ready and pathActive; p.frontAxis.enabled=ready and pathActive and p.align.checked
            p.reverse.enabled=ready and pathActive; p.centerSpacing.enabled=ready and pathActive and amountMode.selection==2
            p.offset.enabled=ready and pathActive; p.limitWidth.enabled=ready and pathActive and not l.twoWay.checked
            p.laneWidth.enabled=ready and pathActive and (p.limitWidth.checked or l.twoWay.checked)
            l.twoWay.enabled=ready and pathActive
            l.rightCopies.enabled=ready and pathActive and l.twoWay.checked and amountMode.selection==1
            l.rightOffset.enabled=ready and pathActive and l.twoWay.checked; l.rightWidth.enabled=ready and pathActive and l.twoWay.checked
            l.rightSpacing.enabled=ready and pathActive and l.twoWay.checked and amountMode.selection==2; l.opposite.enabled=ready and pathActive and l.twoWay.checked
            v.sideways.enabled=ready and pathActive; v.along.enabled=ready and pathActive
            p.clearPath.enabled=ready and pathActive
            quantity.text=if pathActive and l.twoWay.checked then "First copies:" else "Copies:"
            -- Compact the optional path view; hidden fields never leave blank rows.
            -- This is presentation only. Native generation validates every draft.
            local y=116, bySpacing=amountMode.selection==2, paired=l.twoWay.checked
            for row in #(
                #(p.curveIndex,30,true),#(p.align,29,true),#(p.frontAxis,57,true),#(p.reverse,32,true),
                #(p.centerSpacing,32,bySpacing),#(p.offset,32,true),#(p.limitWidth,32,not paired),
                #(p.laneWidth,32,p.limitWidth.checked or paired),#(p.twoWay,32,true),#(p.laneInfo,42,paired),
                #(p.rightCopies,32,paired and not bySpacing),#(p.rightOffset,32,paired),#(p.rightWidth,32,paired),
                #(p.rightSpacing,32,paired and bySpacing),#(p.opposite,32,paired),
                #(p.sideways,32,true),#(p.along,32,true),#(p.help,38,true)) do
            (
                row[1].visible=pathActive and row[3]
                if row[1].visible do (row[1].pos=[10,y]; y+=row[2])
            )
            p.height=if pathActive then y+6 else 110
            syncMinimumControl()
            syncObstacleControls()
            true
        )
        fn readDraft =
        (
            local scaleView = boundAttribute.scaleControls
            #((if keepSeed.checked then caReadExactSeed seedText.text else loadedSettings[1]), (if amountMode.selection == 1 then 2 else 1), quantity.value, fillAmount.value/100.0, spacing.value, (if collisionViewHydrated then boundAttribute.protectionControls.edgeGap.value else loadedSettings[6]), scaleView.randomScale.checked, scaleView.fitScale.checked, scaleView.minimumScale.value/100.0, scaleView.maximumScale.value/100.0)
        )
        fn showSettings values =
        (
            amountMode.selection = if values[2] == 2 then 1 else 2
            quantity.value = values[3]; fillAmount.value = values[4]*100.0; spacing.value = values[5]; seedText.text = decimal values[1]
            local scaleView = boundAttribute.scaleControls
            scaleView.randomScale.checked = values[7]; scaleView.fitScale.checked = values[8]
            scaleView.minimumScale.value = values[9]*100.0; scaleView.maximumScale.value = values[10]*100.0
            boundAttribute.protectionControls.edgeGap.value = values[6]
            syncControls()
        )
        fn currentPathMode = pathActive
        fn readPathDraft =
        (
            local p=boundAttribute.pathControls, l=boundAttribute.pathControls, v=boundAttribute.pathControls
            local angles=#(0.0,90.0,180.0,-90.0)
            local front=if p.frontAxis.selection>=1 and p.frontAxis.selection<=4 then angles[p.frontAxis.selection] else loadedPath[4]
            #(p.curveIndex.value,(if l.twoWay.checked then 2 else 1),p.align.checked,front,p.reverse.checked,p.offset.value,p.laneWidth.value,p.centerSpacing.value,(p.limitWidth.checked or l.twoWay.checked),l.rightCopies.value,l.rightOffset.value,l.rightWidth.value,l.rightSpacing.value,(if l.opposite.checked then not p.reverse.checked else p.reverse.checked),true,loadedPath[16],loadedPath[17],v.sideways.value,v.along.value)
        )
        fn showPathSettings values =
        (
            if values.count!=19 then false
            else
            (
                local p=boundAttribute.pathControls, l=boundAttribute.pathControls, v=boundAttribute.pathControls
                p.curveIndex.value=values[1]; l.twoWay.checked=values[2]==2; p.align.checked=values[3]
                local angles=#(0.0,90.0,180.0,-90.0), index=findItem angles values[4]
                p.frontAxis.items=if index==0 then #("+X","+Y","-X","-Y","Custom saved angle") else #("+X","+Y","-X","-Y")
                p.frontAxis.selection=if index==0 then 5 else index
                p.reverse.checked=values[5]; p.offset.value=values[6]; p.laneWidth.value=values[7]; p.centerSpacing.value=values[8]; p.limitWidth.checked=values[9]
                l.rightCopies.value=values[10]; l.rightOffset.value=values[11]; l.rightWidth.value=values[12]; l.rightSpacing.value=values[13]; l.opposite.checked=values[14]!=values[5]
                v.sideways.value=values[18]; v.along.value=values[19]
                syncControls()
            )
        )
        fn refreshPath preserveDrafts:false =
        (
            local draft=if preserveDrafts and loadedPath.count==19 then readPathDraft() else undefined
            local saved=if isValidNode setupNode then caPathSettings setupNode else undefined
            pathActive=saved!=undefined
            amountMode.items=if pathActive then #("Quantity","Center spacing") else #("Quantity","Fill available space")
            if pathActive then
            (
                local shown=for value in saved[2] collect value
                if draft!=undefined do for i=1 to 19 where draft[i]!=loadedPath[i] do shown[i]=draft[i]
                loadedPath=for value in saved[2] collect value
                showPathSettings shown
                boundAttribute.pathControls.pathName.text=if isValidNode saved[1] then saved[1].name else "Missing path - pick again."
                boundAttribute.pathControls.laneInfo.text=(saved[3][1]as string)+" first / "+(saved[3][2]as string)+" second placed"
            )
            else
            (
                loadedPath=#(); boundAttribute.pathControls.pathName.text="Optional: use a spline path."
                boundAttribute.pathControls.laneInfo.text="Enable for two directions."
            )
            true
        )
        fn refreshProps preserveDrafts:false =
        (
            local oldRows=propRows,oldSelection=boundAttribute.propControls.propList.selection
            local selectedID=if oldSelection>0 and oldSelection<=oldRows.count then oldRows[oldSelection][1] else undefined
            propRows = if isValidNode setupNode then caAssetRows setupNode else #()
            local saved=if isValidNode setupNode then caPropMinimums setupNode else #(),draft=#()
            for row in propRows do
            (
                local value=minimumValue saved row[1]
                if preserveDrafts and (minimumValue minimumDrafts row[1])!=(minimumValue loadedMinimums row[1]) do value=minimumValue minimumDrafts row[1]
                append draft #(row[1],value)
            )
            minimumDrafts=draft;loadedMinimums=saved
            local index=0
            if selectedID!=undefined do for i=1 to propRows.count where propRows[i][1]==selectedID do index=i
            if index==0 and propRows.count==1 do index=1
            updateMinimumLabels selected:index
            boundAttribute.propControls.propInfo.text = (propRows.count as string) + " prop model(s). Originals stay unchanged."
            syncMinimumControl();true
        )
        fn onRefresh preserveDrafts:false =
        (
            if not (isCurrentView (captureBinding())) then false
            else try
            (
                local draft = if preserveDrafts and loadedSettings.count == 10 then readDraft() else undefined
                useReceiverButton.enabled = isValidNode contextNode and not (isKindOf contextNode.baseObject Helper)
                if not isValidNode setupNode then
                (
                    receiverInfo.text = "Choose the objects that will receive props."
                    loadedSettings = #(); keepSeed.checked = false; refreshPath(); refreshCollision(); syncControls(); refreshProps()
                    statusText.text = "Use this geometry, or pick receiving objects. Nothing is analyzed until Generate."
                    true
                )
                else
                (
                    local summary = caSetupSummary setupNode
                    if ownerGuid == undefined then ownerGuid = summary[1]
                    else if ownerGuid != summary[1] do throw "The arrangement changed. Select its icon again."
                    local settings = caPlacementSettings setupNode
                    local shown = for value in settings collect value
                    if draft != undefined do for i = 1 to 10 where draft[i] != loadedSettings[i] do shown[i] = draft[i]
                    loadedSettings = for value in settings collect value
                    refreshPath preserveDrafts:preserveDrafts
                    showSettings shown
                    local receivers = caReceiverNodes setupNode
                    receiverInfo.text = if receivers.count == 1 and isValidNode receivers[1] then receivers[1].name else ((receivers.count as string) + " receiving objects / groups")
                    if pathActive do receiverInfo.text="Path: "+boundAttribute.pathControls.pathName.text+"\n"+(receivers.count as string)+" support object(s)"
                    intro.text=if pathActive then "Props follow the spline. Generate." else "Choose geometry, add props, Generate."
                    refreshProps preserveDrafts:preserveDrafts
                    refreshCollision preserveDrafts:preserveDrafts
                    statusText.text = (summary[5] as string) + " placed.\n" + (if propRows.count == 0 then "Add props below, then Generate." else "Generate makes a new variation.")
                    if summary[6] != 0 do statusText.text += "\nChanges pending Generate."
                    if summary[8] != "" do statusText.text = summary[8]
                    lastError = ""; true
                )
            ) catch (fail (getCurrentException()))
        )
        fn pickedNodes prompt =
        (
            local chosen = pickObject message:prompt count:#multiple select:false forceListenerFocus:false
            if classOf chosen != Array then #() else chosen
        )
        fn bindPathNode chosen ticket =
        (
            if not isCurrentView ticket do throw "Arrangement selection changed while picking."
            if not isValidNode chosen then false
            else
            (
                local owner=setupNode, context=contextNode
                if isValidNode owner do ownerSummary owner ticket
                boundAttribute.pathControls.curveIndex.value=1
                undo "Cyrus Arrange: choose path" on
                (
                    if not isValidNode owner then owner=caCreateArrangement #(chosen)
                    else caBindPath owner chosen 1
                )
                if isCurrentView ticket do (if setupNode!=owner do setBinding owner context; onRefresh preserveDrafts:true)
                true
            )
        )
        fn bindReceivers chosen ticket =
        (
            if not (isCurrentView ticket) do throw "Arrangement selection changed while picking."
            if chosen.count == 0 then false
            else
            (
                local owner = setupNode, context = contextNode
                if isValidNode owner do ownerSummary owner ticket
                if not isValidNode owner and isValidNode context do
                (
                    local matches=for row in (caSceneSetups #(context)) where row[2] collect row[1]
                    if matches.count > 1 do throw "Several arrangements use this geometry. Select the arrangement icon you want to edit."
                    if matches.count == 1 do owner=matches[1]
                )
                undo "Cyrus Arrange: receiving geometry" on
                (
                    if not isValidNode owner then owner = caCreateArrangement chosen
                    else caBindReceivers owner chosen
                )
                if isCurrentView ticket do (if setupNode != owner do setBinding owner context; onRefresh preserveDrafts:true)
                true
            )
        )
        fn onGenerate =
        (
            local owner = setupNode, ticket = captureBinding()
            try
            (
                local summary = ownerSummary owner ticket
                if summary[4] == 0 do throw "Add original prop models below first."
                local settings = readDraft()
                local approach=boundAttribute.protectionControls.clearApproach.checked
                local result = if pathActive then caGeneratePathMinimums owner settings (readPathDraft()) (readMinimumDraft()) (not keepSeed.checked) approach else caGeneratePlacementMinimums owner settings (readMinimumDraft()) (not keepSeed.checked) approach
                if sameBinding owner ticket do
                (
                    onRefresh()
                    statusText.text = (decimal result[2]) + " placed / " + (decimal result[1]) + " requested\n" + (decimal result[5]) + " unfilled\nSeed " + seedText.text
                    if result[6].count > 0 do statusText.text += "\n" + (result[6][1] as string)
                )
                true
            ) catch (if sameBinding owner ticket then fail (getCurrentException()) else false)
        )
        fn command action data:undefined =
        (
            local owner = setupNode, ticket = captureBinding()
            if not (isCurrentView ticket) then false
            else try
            (
                case action of
                (
                    #refresh: (onRefresh preserveDrafts:true)
                    #scale: (syncControls())
                    #hydrateProps: (refreshProps preserveDrafts:true)
                    #hydrateCollision:
                    (
                        if not collisionViewHydrated and loadedSettings.count==10 do boundAttribute.protectionControls.edgeGap.value=loadedSettings[6]
                        refreshCollision preserveDrafts:true;collisionViewHydrated=true;true
                    )
                    #obstacleSelection: (syncObstacleControls())
                    #approach: (statusText.text="Clear approach is pending Generate.";true)
                    #edgeGap: (statusText.text="Edge gap is pending Generate.";true)
                    #pickObstacles:
                    (
                        local chosen=pickedNodes "Pick scene objects to avoid; right-click finishes"
                        if chosen.count>0 and sameBinding owner ticket do (ownerSummary owner ticket;caAddObstacles owner chosen;onRefresh preserveDrafts:true)
                        true
                    )
                    #addObstacles: (ownerSummary owner ticket;caAddObstacles owner (if data==undefined then (selection as array) else data);onRefresh preserveDrafts:true)
                    #removeObstacle:
                    (
                        ownerSummary owner ticket
                        caRemoveObstacle owner boundAttribute.protectionControls.obstacleList.selection obstacleRevision
                        onRefresh preserveDrafts:true
                    )
                    #minimumSelection: (syncMinimumControl())
                    #showFit:
                    (
                        ownerSummary owner ticket
                        local index=boundAttribute.propControls.propList.selection
                        if index<1 or index>propRows.count do throw "Select an unfilled prop first."
                        local info=caFitHighlightInfo owner
                        if info[1] and info[2] and info[3]==propRows[index][1] then caHideFitFeedback owner else caShowFitFeedback owner propRows[index][1]
                        refreshFitFeedback();true
                    )
                    #useFit:
                    (
                        ownerSummary owner ticket
                        local index=boundAttribute.propControls.propList.selection
                        if index<1 or index>propRows.count do throw "Select an unfilled prop first."
                        local data=caFitFeedback owner propRows[index][1]
                        if not data[1] or data[13]<=0 do throw "No checked size is available. Generate again to refresh fit feedback."
                        local scaleView=boundAttribute.scaleControls
                        scaleView.fitScale.checked=true;scaleView.minimumScale.value=data[13]
                        if scaleView.maximumScale.value<data[13] do scaleView.maximumScale.value=data[13]
                        syncControls();statusText.text="Checked fit minimum is a draft for this arrangement. Press Generate to apply.";true
                    )
                    #minimum:
                    (
                        if not hydratingMinimum do
                        (
                            ownerSummary owner ticket
                            local index=boundAttribute.propControls.propList.selection
                            if index<1 or index>propRows.count do throw "Select a prop in the list first."
                            local id=propRows[index][1]
                            for row in minimumDrafts where row[1]==id do row[2]=data
                            updateMinimumLabels();syncMinimumControl()
                            statusText.text="Minimum copies are pending Generate."
                        )
                        true
                    )
                    #hydratePath: (if loadedPath.count==19 then showPathSettings loadedPath else syncControls())
                    #bindPath: (bindPathNode data ticket)
                    #pickPath: (local chosen=pickObject message:"Pick one spline path" count:1 select:false forceListenerFocus:false; if isValidNode chosen do bindPathNode chosen ticket; true)
                    #clearPath:
                    (
                        ownerSummary owner ticket
                        local beforeDraft=readDraft(), beforeSaved=for value in loadedSettings collect value, pendingMinimums=readMinimumDraft(), pendingApproach=boundAttribute.protectionControls.clearApproach.checked
                        caClearPath owner; ownerSummary owner ticket; loadedPath=#()
                        if onRefresh() do
                        (
                            local shown=for value in loadedSettings collect value
                            -- Mode and Copies are rebased natively. Preserve only
                            -- actual unrelated edits, not an inactive path count.
                            for i=1 to 10 where i!=2 and i!=3 and beforeDraft[i]!=beforeSaved[i] do shown[i]=beforeDraft[i]
                            showSettings shown;showMinimumDraft pendingMinimums
                            boundAttribute.protectionControls.clearApproach.checked=pendingApproach
                        )
                        true
                    )
                    #twoWay: (if pathActive and boundAttribute.pathControls.twoWay.checked do (local p=boundAttribute.pathControls; p.limitWidth.checked=true; if p.offset.value==0 do p.offset.value=1750); syncControls())
                    #hydrateScale: (if loadedSettings.count == 10 do (local view=boundAttribute.scaleControls; view.randomScale.checked=loadedSettings[7]; view.fitScale.checked=loadedSettings[8]; view.minimumScale.value=loadedSettings[9]*100.0; view.maximumScale.value=loadedSettings[10]*100.0); syncControls())
                    #generate: (onGenerate())
                    #useReceiver: (if isValidNode contextNode and caIsSplinePath contextNode then bindPathNode contextNode ticket else bindReceivers #(contextNode) ticket)
                    #pickReceiver: (local chosen = pickedNodes "Pick receiving geometry; right-click finishes"; bindReceivers chosen ticket)
                    #bindReceivers: (bindReceivers data ticket)
                    #pickProps: (local chosen = pickedNodes "Pick original prop models; right-click finishes"; if sameBinding owner ticket and chosen.count > 0 do (ownerSummary owner ticket; caRegisterAssets owner chosen 7; onRefresh preserveDrafts:true); true)
                    #addProps: (ownerSummary owner ticket; local chosen = if data == undefined then (selection as array) else data; caRegisterAssets owner chosen 7; onRefresh preserveDrafts:true)
                    #groupProps:
                    (
                        ownerSummary owner ticket
                        local chosen=if data==undefined then pickedNodes "Pick components of one decor group; right-click finishes" else data
                        if chosen.count > 0 and sameBinding owner ticket do
                        (
                            ownerSummary owner ticket
                            local drafts=readDraft(), pathDrafts=(if pathActive then readPathDraft() else undefined), retainSeed=keepSeed.checked, minimumValues=readMinimumDraft(), approachDraft=boundAttribute.protectionControls.clearApproach.checked, documentID=ownerGuid
                            caCreatePropGroup owner chosen boundAttribute.propControls.groupName.text 7
                            if sameBinding owner ticket then onRefresh preserveDrafts:true
                            else if caModifierUI==undefined and isValidNode owner and (caSetupSummary owner)[1]==documentID do
                            (
                                -- Max can close the native edit context while grouping.
                                -- Resume only this completed command's unchanged Document,
                                -- and only when another view has not taken over.
                                caFocusArrange setup:owner
                                local resumed=caModifierUI
                                if resumed!=undefined and resumed.currentSetup()==owner and resumed.currentDocumentID()==documentID do
                                (
                                    resumed.keepSeed.checked=retainSeed
                                    resumed.showSettings drafts
                                    resumed.showMinimumDraft minimumValues
                                    caModifierViewOwner.protectionControls.clearApproach.checked=approachDraft
                                    if pathDrafts!=undefined do resumed.showPathSettings pathDrafts
                                )
                            )
                        )
                        true
                    )
                    #removeProp: (ownerSummary owner ticket; local index = boundAttribute.propControls.propList.selection; if index < 1 or index > propRows.count do throw "Choose a prop in the list first."; caRemoveAssets owner #(propRows[index][1]) true; onRefresh preserveDrafts:true)
                    #selectIcon: (ownerSummary owner ticket; select owner; true)
                    #lock: (ownerSummary owner ticket; local chosen = if data == undefined then (selection as array) else data; local ids = for row in (caOutputRows owner) where findItem chosen row[9] > 0 collect row[1]; if ids.count == 0 do throw "Pin the stack, then select generated objects to protect."; caSetLocked owner ids true; onRefresh preserveDrafts:true)
                    #unlock: (ownerSummary owner ticket; local chosen = if data == undefined then (selection as array) else data; local ids = for row in (caOutputRows owner) where findItem chosen row[9] > 0 collect row[1]; if ids.count == 0 do throw "Pin the stack, then select generated objects to unprotect."; caSetLocked owner ids false; onRefresh preserveDrafts:true)
                    default: false
                )
            ) catch (if isCurrentView ticket then fail (getCurrentException()) else false)
        )
        on useReceiverButton pressed do modifyControls.owner.dispatch #useReceiver
        on pickReceiverButton pressed do modifyControls.owner.dispatch #pickReceiver
        on generateButton pressed do modifyControls.owner.dispatch #generate
        on amountMode selected value do modifyControls.owner.amountChanged value
        on keepSeed changed value do modifyControls.owner.dispatch #scale
        on seedText entered value do (keepSeed.checked = true; modifyControls.owner.dispatch #scale)
        on modifyControls open do
        (
            local attribute = modifyControls.owner
            attribute.beginView(); hydrateBinding attribute; mounted = true
            caModifierViewOwner = attribute; caModifierUI = modifyControls; keepSeed.checked = false
            onRefresh()
        )
        on modifyControls close do
        (
            local attribute = modifyControls.owner
            if boundAttribute == attribute do (mounted = false; boundAttribute = undefined; setupNode = undefined; contextNode = undefined; ownerGuid = undefined; loadedSettings = #())
            attribute.releaseView()
        )
    )
    rollout propControls "Props" width:#cmdPanel height:400
    (
        label propInfo "Add original models or complete groups." pos:[10,8] width:142 height:34
        listBox propList "" items:#() pos:[10,45] width:142 height:5
        spinner minimumCopies "Min copies:" range:[0,2000,0] type:#integer pos:[10,142] width:142 fieldWidth:48 tooltip:"0 lets Arrange choose. Required copies reserve space before optional props. Applies with Generate."
        label minimumHelp "For the selected prop. 0 = no minimum." pos:[10,171] width:142 height:27
        editText fitText "" text:"" readOnly:true pos:[10,201] width:142 height:110 visible:false
        button showFit "Show fit space" pos:[10,317] width:142 height:26 visible:false
        button useFit "Use checked size" pos:[10,349] width:142 height:26 visible:false tooltip:"Sets the arrangement's Shrink to fit minimum to a physically checked value. Applies only with Generate. Source models stay unchanged."
        button pickProps "Pick props" pos:[10,200] width:142 height:26 tooltip:"Pick multiple original models or groups; right-click finishes."
        button addSelection "Add selected props" pos:[10,232] width:142 height:26 tooltip:"Pin the Modify stack before selecting other scene objects."
        button removeProp "Remove prop + copies" pos:[10,264] width:142 height:26 tooltip:"Removes the listed prop and its generated copies from this arrangement. Undo is available."
        editText groupName "" text:"Decor group" pos:[10,300] width:142 tooltip:"Name for the reusable prop group."
        button groupProps "Pick reusable group" pos:[10,336] width:142 height:26 tooltip:"Pick two or more original props. Arrange copies them into a reusable source group; originals stay unchanged."
        button selectIcon "Select arrangement icon" pos:[10,368] width:142 height:26
        on propList selected index do propControls.owner.dispatch #minimumSelection
        on showFit pressed do propControls.owner.dispatch #showFit
        on useFit pressed do propControls.owner.dispatch #useFit
        on minimumCopies changed value do propControls.owner.dispatch #minimum data:value
        on pickProps pressed do propControls.owner.dispatch #pickProps
        on addSelection pressed do propControls.owner.dispatch #addProps
        on removeProp pressed do propControls.owner.dispatch #removeProp
        on groupProps pressed do propControls.owner.dispatch #groupProps
        on selectIcon pressed do propControls.owner.dispatch #selectIcon
        on propControls open do propControls.owner.dispatch #hydrateProps
    )
    rollout scaleControls "Scale" width:#cmdPanel height:194
    (
        checkbox randomScale "Random scale" checked:false pos:[10,9] width:142
        checkbox fitScale "Shrink to fit" checked:false pos:[10,36] width:142 tooltip:"Try preferred size across all spaces first, then shrink uniformly within the minimum."
        spinner minimumScale "Minimum (%):" range:[1,10000,80] type:#float pos:[10,71] width:142 fieldWidth:48
        spinner maximumScale "Maximum (%):" range:[1,10000,110] type:#float pos:[10,102] width:142 fieldWidth:48
        label help "100% preserves original size. Fit keeps proportions and never changes the source." pos:[10,138] width:142 height:48
        on randomScale changed value do scaleControls.owner.dispatch #scale
        on fitScale changed value do scaleControls.owner.dispatch #scale
        on scaleControls open do scaleControls.owner.dispatch #hydrateScale
    )
    rollout protectionControls "Keep clear" width:#cmdPanel height:448
    (
        label obstacleInfo "Receiver collisions are automatic. Add other scene objects to avoid." pos:[10,8] width:142 height:48
        listBox obstacleList "" items:#() pos:[10,59] width:142 height:4
        button pickObstacles "Pick obstacles" pos:[10,139] width:142 height:26 tooltip:"Add external scene objects or complete groups to avoid. They will not become receiving surfaces. Right-click finishes."
        button removeObstacle "Remove obstacle" pos:[10,171] width:142 height:26 tooltip:"Removes the listed reference from this arrangement. Leaves the scene object unchanged."
        spinner edgeGap "Edge gap (mm):" range:[0,1000000,0] type:#float pos:[10,207] width:142 fieldWidth:48 tooltip:"Optional distance between the prop's base and the support edge. Zero uses all available support. Applies with Generate."
        checkbox clearApproach "Clear approach" checked:false pos:[10,247] width:142 tooltip:"Optional: also require a clear horizontal approach from the support region's front direction. Applies with Generate."
        label approachHelp "Optional extra access check. Collisions are always checked." pos:[10,277] width:142 height:43
        label help "Pin the stack and select generated objects to keep their placement." pos:[10,328] width:142 height:45
        button lockSelected "Protect selected" pos:[10,380] width:142 height:26
        button unlockSelected "Unprotect selected" pos:[10,414] width:142 height:26
        on obstacleList selected index do protectionControls.owner.dispatch #obstacleSelection
        on pickObstacles pressed do protectionControls.owner.dispatch #pickObstacles
        on removeObstacle pressed do protectionControls.owner.dispatch #removeObstacle
        on clearApproach changed value do protectionControls.owner.dispatch #approach
        on edgeGap changed value do protectionControls.owner.dispatch #edgeGap
        on lockSelected pressed do protectionControls.owner.dispatch #lock
        on unlockSelected pressed do protectionControls.owner.dispatch #unlock
        on protectionControls open do protectionControls.owner.dispatch #hydrateCollision
    )
    rollout pathControls "Path" width:#cmdPanel height:110
    (
        label pathName "Optional: use a spline path." pos:[10,8] width:142 height:33
        button pickPath "Pick spline path" pos:[10,45] width:142 height:26
        button clearPath "Use surfaces instead" pos:[10,77] width:142 height:26
        spinner curveIndex "Curve:" range:[1,256,1] type:#integer pos:[10,116] width:142 fieldWidth:48
        checkbox align "Align to path" checked:true pos:[10,145] width:142
        dropdownList frontAxis "Model front:" items:#("+X","+Y","-X","-Y") selection:1 pos:[10,174] width:142
        checkbox reverse "Reverse direction" checked:false pos:[10,231] width:142
        spinner centerSpacing "Centers (mm):" range:[0.001,1000000,5000] type:#float pos:[10,264] width:142 fieldWidth:48
        spinner offset "Offset (mm):" range:[-1000000,1000000,0] type:#float pos:[10,296] width:142 fieldWidth:48
        checkbox limitWidth "Keep inside width" checked:false pos:[10,328] width:142
        spinner laneWidth "Width (mm):" range:[0.001,1000000,3000] type:#float pos:[10,360] width:142 fieldWidth:48
        checkbox twoWay "Two-way placement" checked:false pos:[10,392] width:142
        label laneInfo "Enable for two directions." pos:[10,424] width:142 height:30
        spinner rightCopies "Other copies:" range:[0,2000,3] type:#integer pos:[10,466] width:142 fieldWidth:48
        spinner rightOffset "Offset (mm):" range:[-1000000,1000000,-1750] type:#float pos:[10,498] width:142 fieldWidth:48
        spinner rightWidth "Width (mm):" range:[0.001,1000000,3000] type:#float pos:[10,530] width:142 fieldWidth:48
        spinner rightSpacing "Centers (mm):" range:[0.001,1000000,5000] type:#float pos:[10,562] width:142 fieldWidth:48
        checkbox opposite "Opposite direction" checked:true pos:[10,594] width:142
        spinner sideways "Sideways (mm):" range:[0,1000000,0] type:#float pos:[10,626] width:142 fieldWidth:48
        spinner along "Along (mm):" range:[0,1000000,0] type:#float pos:[10,658] width:142 fieldWidth:48
        label help "Positive offset is left of the path. Spread is random in both directions." pos:[10,690] width:142 height:32
        on pickPath pressed do pathControls.owner.dispatch #pickPath
        on clearPath pressed do pathControls.owner.dispatch #clearPath
        on align changed value do pathControls.owner.dispatch #scale
        on frontAxis selected value do pathControls.owner.dispatch #scale
        on limitWidth changed value do pathControls.owner.dispatch #scale
        on twoWay changed value do pathControls.owner.dispatch #twoWay
        on pathControls open do pathControls.owner.dispatch #hydratePath
    )

)

fn caCreateModifyView owner contextNode =
(
    local holder = EmptyModifier()
    custAttributes.add holder caModifyViewDefinition
    if holder.custAttributes.count != 1 do throw "Cannot create the Cyrus Arrange parameter view."
    local attribute = holder.custAttributes[1]
    attribute.bindView owner contextNode
    #(holder,attribute,attribute.modifyControls)
)

fn caFocusArrange setup:undefined createNew:false =
(
    local chosen = selection as array, owner = setup
    if not createNew and not isValidNode owner do
    (
        if caModifierUI != undefined do owner = caModifierUI.currentSetup()
        if not isValidNode owner do
        (
            local matches = for row in (caSceneSetups chosen) where row[2] collect row[1]
            if matches.count == 1 do owner = matches[1]
            if matches.count > 1 do throw "Select the Cyrus Arrange icon you want to edit."
        )
    )
    if createNew or not isValidNode owner do
    (
        undo "Create Cyrus Arrange" on
        (
            local receivers = for node in chosen where isValidNode node and (caInputKind node == 1) collect node
            owner = if chosen.count==1 and caIsSplinePath chosen[1] then caCreateArrangement chosen else if receivers.count > 0 then caCreateArrangement receivers else caCreateArrangement()
        )
    )
    max modify mode
    modPanel.setPinStack false
    select owner
    for modifier in owner.modifiers where classOf modifier == CyrusArrange do modPanel.setCurrentObject modifier node:owner ui:true
    owner
)
-- Old entry actions now focus the same native Modify view, never another dialog.
fn caShowArrangeUI setup:undefined = caFocusArrange setup:setup
fn caShowAdvancedArrangeUI setup:undefined = caFocusArrange setup:setup
fn caShowHomePropsUI setup independentOwner:false = caFocusArrange setup:setup
fn caShowAssetUI setup = caFocusArrange setup:setup
fn caShowRegionUI setup = caFocusArrange setup:setup
fn caShowCollisionUI setup = caFocusArrange setup:setup
fn caShowCompositionUI setup = caFocusArrange setup:setup
fn caShowRulesUI setup category = caFocusArrange setup:setup
fn caShowUI = caFocusArrange()

-- Read only after native Undo/Redo completes. Uncommitted drafts survive while
-- restored accepted values follow the native Document. No capture or solve.
callbacks.removeScripts id:#CyrusArrangeModifyRestore
callbacks.addScript #sceneUndo "if caModifierUI != undefined do caModifierUI.onRefresh preserveDrafts:true" id:#CyrusArrangeModifyRestore persistent:false
callbacks.addScript #sceneRedo "if caModifierUI != undefined do caModifierUI.onRefresh preserveDrafts:true" id:#CyrusArrangeModifyRestore persistent:false

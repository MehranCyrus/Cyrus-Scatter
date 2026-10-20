/* Isolated Max2027 only: native variation/discovery and actual simple artist handlers. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caModifierUI,caModifierViewOwner,CyrusArrange,caCreateArrangement,caBindReceivers,caPlacementSettings,caReadExactSeed
global caSceneSetups, caGenerateVariation, caCreateSetup, caSetupSummary, caSetArrangeSettings
global caRegisterAsset, caAssetRows, caAssetDetail, caRemoveAssets, caOutputRows, caGenerate, caSetLocked
global caSetCollisionScope, caRegionRows, caGeometryCacheInfo, caGeometryDependencyInfo
global caPreview, caPreviewInfo, caCommitPreview, caClearPreview, caTick, caVersion
global caSWLog=#(), caSWPasses=0, caSWFailures=0, caSWFinished=false
global caSWWrite, caSWNote, caSWCheck, caSWRequire, caSWClose, caSWBox
global caSWRecords, caSWHandles, caSWState, caSWEqual, caSWMatches, caSWPhysical, caSWDifferences, caSWRun

fn caSWWrite =
(
    local f=createFile (CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caSWFinished then (if caSWFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caSWPasses caSWFailures to:f
    for line in caSWLog do format "%\n" line to:f
    close f
)
fn caSWNote message=(append caSWLog message;caSWWrite())
fn caSWCheck message value=(if value then(caSWPasses+=1;caSWNote("PASS "+message))else(caSWFailures+=1;caSWNote("FAIL "+message));value)
fn caSWRequire message value=(caSWCheck message value;if not value do throw("Required simple-workflow prerequisite: "+message);value)
fn caSWEqual a b=(deepEqual a b strictCompare:true)
fn caSWClose =
(
    modPanel.setPinStack false;max create mode
)
fn caSWBox label size base = box name:label width:size.x length:size.y height:size.z pos:base
fn caSWRecords setup=(for row in (caOutputRows setup) collect #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8]))
fn caSWHandles setup=(for row in (caOutputRows setup) collect (if isValidNode row[9] then getHandleByAnim row[9] else undefined))
fn caSWTransforms setup=
(
    local values=#()
    for row in(caOutputRows setup)do
    (
        local tm=row[9].objectTransform
        append values #(row[1],(for axis=1 to 4 collect tm[axis]))
    )
    values
)
fn caSWState setup =
(
    local s=caSetupSummary setup
    -- Error/dirty diagnostics may legitimately change after an input failure.
    #(s[1],s[3],s[4],s[5],s[9],caSWRecords setup,caSWHandles setup,caPlacementSettings setup,caPropMinimums setup)
)
fn caSWMatches nodes=(for row in (caSceneSetups nodes) where row[2] collect row[1])
fn caSWPhysical setup =
(
    local good=true
    for row in (caOutputRows setup) while good do
    (
        if not isValidNode row[9] then good=false
        else
        (
            local bounds=nodeGetBoundingBox row[9] (matrix3 1)
            local size=bounds[2]-bounds[1]
            local horizontal=(abs(size.x-80)<0.02 and abs(size.y-60)<0.02) or (abs(size.x-60)<0.02 and abs(size.y-80)<0.02)
            if not horizontal or abs(size.z-20)>0.02 or abs(bounds[1].z-320)>0.02 do good=false
            if bounds[1].x < -300.02 or bounds[2].x > 300.02 or bounds[1].y < -150.02 or bounds[2].y > 150.02 do good=false
            if abs(row[6]-1.0)>0.00001 do good=false
        )
    )
    good
)
fn caSWDifferences label before after =
(
    caSWNote ("POSE_DIAGNOSTIC "+label+" beforeCount="+(before.count as string)+" afterCount="+(after.count as string))
    local shown=0
    local comparableCount=if before.count<after.count then before.count else after.count
    for i=1 to comparableCount while shown<8 do
    (
        if not(caSWEqual before[i] after[i]) do
        (
            shown+=1
            caSWNote ("POSE_BEFORE "+label+" row="+(i as string)+" "+(before[i] as string))
            caSWNote ("POSE_AFTER "+label+" row="+(i as string)+" "+(after[i] as string))
            caSWNote ("POSE_DELTA "+label+" row="+(i as string)+" positionMM="+((distance before[i][4] after[i][4]) as string)+" yawDegrees="+((after[i][5]-before[i][5]) as string)+" scale="+((after[i][6]-before[i][6]) as string))
            local yawDelta=after[i][5]-before[i][5]
            while yawDelta>180 do yawDelta-=360
            while yawDelta< -180 do yawDelta+=360
            caSWNote("POSE_ID_ANGLE "+label+" beforeID="+(before[i][1]as string)+" afterID="+(after[i][1]as string)+" modulo360Delta="+(yawDelta as string))
        )
    )
    shown
)

fn caSWOpen node =
(
    max modify mode;modPanel.setPinStack false;select node
    local modifier=undefined
    for item in node.modifiers where classOf item==CyrusArrange do modifier=item
    if modifier==undefined do throw "Simple fixture missing native modifier."
    modPanel.setCurrentObject modifier node:node ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caSWRequire "Real Modify view mounts expected context" (caModifierUI!=undefined and caModifierUI.hwnd!=0 and caModifierUI.currentContext()==node)
    true
)
fn caSWRun =
(
    caSWClose();resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms") do fileIn(CA_TEST_ROOT+"scripts/"+script)
    caSWRequire "Exact 0.3.2 in owned normal Max2027 host" ((maxVersion())[1]==29000 and caVersion()=="0.3.2" and not maxOps.isInNonInteractiveMode())
    local top=caSWBox "SW_Top" [600,300,20] [0,0,300]
    local source=caSWBox "SW_Source" [80,60,20] [2500,0,0]
    source.material=standardMaterial name:"SW_Material" diffuse:(color 70 130 190)
    local sourceTM=source.transform as string,sourceMaterial=source.material
    addModifier top(CyrusArrange())
    caSWOpen top
    caSWCheck "Opening unbound geometry is passive" (caModifierUI.currentSetup()==undefined and(caSceneSetups #()).count==0)
    caSWRequire "Use this geometry creates one native arrangement" (caModifierUI.useReceiverButton.pressed())
    local setup=caModifierUI.currentSetup();setup.name="SW_Arrangement"
    caSWCheck "New default is Quantity100 original-size draft without analysis" (caModifierUI.quantity.value==100 and(caPlacementSettings setup)[2]==2 and not(caPlacementSettings setup)[7] and not(caPlacementSettings setup)[8] and(caRegionRows setup).count==0)
    caSWOpen setup
    caModifierUI.quantity.value=6;caModifierUI.spacing.value=11
    caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale;caModifierUI.seedText.text="4321"
    local nativeBefore=(caPlacementSettings setup),revision=(caSetupSummary setup)[3]
    modPanel.setPinStack true;select source
    caSWRequire "Inline Add selected props registers an original" (caModifierViewOwner.propControls.addSelection.pressed())
    local asset=(caAssetRows setup)[1]
    caSWCheck "Source uses original size and descriptive tag" (asset[3]==7 and (distance asset[4] [80,60,20])<0.001 and asset[7]==1 and asset[8]==1)
    caSWCheck "Inline Add retains Copies gap and exact seed drafts" (caModifierUI.quantity.value==6 and caModifierUI.spacing.value==11 and caModifierUI.seedText.text=="4321")
    caSWCheck "Prop registration does not apply pending Generate settings" (caSWEqual nativeBefore(caPlacementSettings setup))
    local beforeDuplicate=caSWState setup
    caSWCheck "All-existing inline Add is an exact catalog/revision no-op" (caModifierViewOwner.propControls.addSelection.pressed() and caSWEqual beforeDuplicate(caSWState setup))
    select top
    caSWCheck "Receiving geometry cannot register as a prop" (not(caModifierViewOwner.propControls.addSelection.pressed()) and caSWEqual beforeDuplicate(caSWState setup))
    caModifierUI.keepSeed.checked=false;caModifierViewOwner.dispatch #scale;caModifierUI.seedText.text="ignored hidden draft"
    local seedBefore=(caPlacementSettings setup)[1]
    caSWRequire "Fresh Generate accepts hidden malformed seed" (caModifierUI.generateButton.pressed())
    local firstSeed=(caPlacementSettings setup)[1],firstRecords=caSWRecords setup
    caSWCheck "Fresh Generate commits six full-size supported copies and new seed" (firstSeed>=0 and firstSeed!=seedBefore and firstRecords.count==6 and caSWPhysical setup)
    caSWRequire "Second fresh Generate succeeds" (caModifierUI.generateButton.pressed())
    local secondSeed=(caPlacementSettings setup)[1]
    caSWCheck "New variation changes used seed and free poses" (secondSeed!=firstSeed and not(caSWEqual firstRecords(caSWRecords setup)) and caSWPhysical setup)
    caSWCheck "Status reports human counts and exact used seed" ((filterString caModifierUI.statusText.text "\n")[1]=="6 placed / 6 requested" and(findString caModifierUI.statusText.text("Seed "+trimRight(secondSeed as string)"Ll"))!=undefined)
    caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale
    local repeatRecords=caSWRecords setup
    caSWRequire "Repeat Generate succeeds" (caModifierUI.generateButton.pressed())
    caSWCheck "Repeat seed repeats complete logical poses" ((caPlacementSettings setup)[1]==secondSeed and caSWEqual repeatRecords(caSWRecords setup))
    caModifierUI.seedText.text="9223372036854775807"
    caSWRequire "Exact maximum Integer64 seed succeeds" (caModifierUI.generateButton.pressed())
    local highRecords=caSWRecords setup
    caSWCheck "Maximum seed displays all nineteen digits" (caModifierUI.seedText.text=="9223372036854775807" and (caReadExactSeed caModifierUI.seedText.text)==9223372036854775807L)
    caSWRequire "Maximum seed repeats" (caModifierUI.generateButton.pressed())
    caSWCheck "Maximum seed keeps exact records" (caSWEqual highRecords(caSWRecords setup))
    local stable=caSWState setup
    caModifierUI.seedText.text="9223372036854775808"
    caSWCheck "Overflow through Generate retains full state and handles" (not(caModifierUI.generateButton.pressed()) and caSWEqual stable(caSWState setup))
    caModifierUI.seedText.text="9223372036854775807"
    caModifierViewOwner.scaleControls.randomScale.checked=true;caModifierViewOwner.dispatch #scale
    caModifierViewOwner.scaleControls.minimumScale.value=110;caModifierViewOwner.scaleControls.maximumScale.value=80
    caSWCheck "Invalid scale draft through Generate retains complete accepted state" (not(caModifierUI.generateButton.pressed()) and caSWEqual stable(caSWState setup))
    caModifierViewOwner.scaleControls.randomScale.checked=false;caModifierViewOwner.dispatch #scale
    undo "SW delete source" on(delete source)
    local missingState=caSWState setup,oldNodes=caSWHandles setup
    caSWCheck "Missing source Generate keeps saved seed settings revision and output identities" (not(caModifierUI.generateButton.pressed()) and caSWEqual missingState(caSWState setup) and caSWEqual oldNodes(caSWHandles setup))
    max undo
    source=getNodeByName "SW_Source" exact:true
    caSWOpen setup
    local beforeVariation=caSWState setup
    caSWRequire "Fresh Generate before one-Undo test succeeds" (caModifierUI.generateButton.pressed())
    local afterVariation=caSWState setup
    caSWCheck "Fresh transaction changed saved seed" (beforeVariation[5][1]!=afterVariation[5][1])
    max undo
    caSWCheck "One Undo restores seed settings records and real handles" (caSWEqual beforeVariation(caSWState setup))
    max redo
    caSWCheck "Redo restores accepted variation without reroll" (caSWEqual afterVariation(caSWState setup))

    caSWNote "STAGE passive native discovery, ambiguity and retired inline owner"
    caSWCheck "Receiver resolves by authoritative ownership" (caSWEqual(caSWMatches #(top))#(setup))
    local output=(caOutputRows setup)[1][9]
    caSWCheck "Output resolves by native binding" (caSWEqual(caSWMatches #(output))#(setup))
    caSWCheck "Original prop does not resolve as receiving/output owner" ((caSWMatches #(source)).count==0)
    local forged=point name:setup.name
    setUserProp forged "CyrusArrangeSetupGuid" (caSetupSummary setup)[1]
    setUserProp forged "CyrusArrangeGenerated" true
    caSWCheck "Name and copied user props cannot forge ownership" ((caSWMatches #(forged)).count==0)
    local unsettledState=caSWState setup,unsettledMetrics=caGeometryCacheInfo setup,unsettledTicket=caGeometryDependencyInfo setup
    local settledUpdates=caTick()
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    local passive=caSWState setup,metrics=caGeometryCacheInfo setup,ticket=caGeometryDependencyInfo setup
    caSWNote("SETTLE updates="+(settledUpdates as string)+" authoredEqual="+((caSWEqual unsettledState passive)as string)+" lastCommandEqual="+((caSWEqual unsettledMetrics[3]metrics[3])as string)+" phaseEqual="+((caSWEqual unsettledMetrics[5]metrics[5])as string)+" ticketBefore="+(unsettledTicket as string)+" ticketAfter="+(ticket as string))
    for i=1 to metrics[4].count do caSWNote("SETTLE_CACHE field="+(i as string)+" before="+(unsettledMetrics[4][i]as string)+" after="+(metrics[4][i]as string))
    caSWCheck "Draining prior Undo notifications performs no Live solve or authored change" (settledUpdates==0 and caSWEqual unsettledState passive and caSWEqual unsettledMetrics[3]metrics[3]and caSWEqual unsettledMetrics[5]metrics[5])
    caSWOpen setup;caModifierViewOwner.dispatch #refresh
    local passiveAfter=caSWState setup,metricsAfter=caGeometryCacheInfo setup,ticketAfter=caGeometryDependencyInfo setup
    caSWNote("PASSIVE authoredEqual="+((caSWEqual passive passiveAfter)as string)+" cacheEqual="+((caSWEqual metrics metricsAfter)as string)+" lastCommandEqual="+((caSWEqual metrics[3]metricsAfter[3])as string)+" phaseEqual="+((caSWEqual metrics[5]metricsAfter[5])as string)+" ticketBefore="+(ticket as string)+" ticketAfter="+(ticketAfter as string))
    for i=1 to metrics[4].count do caSWNote("PASSIVE_CACHE field="+(i as string)+" before="+(metrics[4][i]as string)+" after="+(metricsAfter[4][i]as string))
    caSWCheck "Lookup and mounted refresh are passive for state and native geometry work" (caSWEqual passive passiveAfter and caSWEqual metrics metricsAfter and caSWEqual ticket ticketAfter)
    local oldAttribute=caModifierViewOwner
    local secondSetup=caCreateArrangement();caBindReceivers secondSetup #(top);secondSetup.name="SW_Second_Arrangement"
    caSWOpen secondSetup
    local stateA=caSWState setup,stateB=caSWState secondSetup
    caSWCheck "Retired inline Add/group/Generate cannot mutate either owner" (not(oldAttribute.dispatch #addProps data:#(source)) and not(oldAttribute.dispatch #groupProps data:#(source,top)) and not(oldAttribute.dispatch #generate) and caSWEqual stateA(caSWState setup) and caSWEqual stateB(caSWState secondSetup))
    local matches=caSWMatches #(top)
    caSWCheck "Shared geometry returns both owners without guessing" (matches.count==2 and findItem matches setup>0 and findItem matches secondSetup>0)
    caSWOpen top
    caSWCheck "Ambiguous geometry has no implicit arrangement" (caModifierUI.currentSetup()==undefined)
    caSWCheck "Ambiguous Use geometry cannot create a third owner" (not(caModifierUI.useReceiverButton.pressed()) and(caSceneSetups #()).count==2)
    caSWCheck "Ambiguous Generate changes neither owner" (not(caModifierUI.generateButton.pressed()) and caSWEqual stateA(caSWState setup) and caSWEqual stateB(caSWState secondSetup))
    caSWOpen setup;modPanel.setPinStack true
    select (caOutputRows setup)[1][9]
    local beforeProtection=caSWRecords setup,beforeProtectionTransforms=caSWTransforms setup,beforeProtectionSettings=caPlacementSettings setup
    caSWRequire "Actual Protect selected handler captures an output" (caModifierViewOwner.protectionControls.lockSelected.pressed())
    caSWCheck "Selected output is natively protected" ((caOutputRows setup)[1][7])
    caSWDifferences "protect-capture" beforeProtection(caSWRecords setup)
    caSWRequire "Actual Unprotect selected handler releases it" (caModifierViewOwner.protectionControls.unlockSelected.pressed())
    caSWCheck "Selected output lock is released" (not(caOutputRows setup)[1][7])
    caSWDifferences "after-unprotect-versus-recipe" beforeProtection(caSWRecords setup)
    caSWCheck "Protect and Unprotect retain every exact output transform and seeded setting" (caSWEqual beforeProtectionTransforms(caSWTransforms setup) and caSWEqual beforeProtectionSettings(caPlacementSettings setup))
    local savedRecords=caSWRecords setup,savedSettings=caPlacementSettings setup,savedGUID=(caSetupSummary setup)[1]
    caSWClose()
    local scene=CA_TEST_OUTPUT+"CyrusArrange-Simple-Workflow.max"
    caSWRequire "Accepted scene saves" (saveMaxFile scene quiet:true)
    caSWRequire "Accepted scene reopens" (loadMaxFile scene quiet:true useFileUnits:true)
    setup=getNodeByName "SW_Arrangement" exact:true
    local reopened=caSWState setup
    caSWCheck "Reopen retains GUID current settings and complete logical placements" ((caSetupSummary setup)[1]==savedGUID and caSWEqual savedSettings(caPlacementSettings setup) and caSWEqual savedRecords(caSWRecords setup))
    caSWCheck "Passive reopen leaves Live unarmed" (caTick()==0 and caSWEqual reopened(caSWState setup))
    caSWOpen setup
    caSWCheck "Reopened owner mounts with fresh variation default" (caModifierUI.currentSetup()==setup and not caModifierUI.keepSeed.checked)
    caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale
    caSWNote("REOPEN_SAVED_SETTINGS "+(savedSettings as string)+" native="+((caPlacementSettings setup)as string)+" draft="+(caModifierUI.readDraft()as string)+" seedText="+caModifierUI.seedText.text)
    caSWRequire "Reopened Repeat Generate succeeds" (caModifierUI.generateButton.pressed())
    caSWNote("REOPEN_REPEAT_SETTINGS "+((caPlacementSettings setup)as string)+" savedCount="+(savedRecords.count as string)+" actualCount="+((caSWRecords setup).count as string)+" exactRecords="+((caSWEqual savedRecords(caSWRecords setup))as string)+" physical="+((caSWPhysical setup)as string))
    caSWDifferences "reopened-repeat" savedRecords(caSWRecords setup)
    -- Protect captured the host's actual PRS encoding (270 can become -90).
    -- Save/reopen above retains that exact authored capture. Once unprotected,
    -- Repeat must reproduce the ORIGINAL seeded recipe, including its raw yaw.
    caSWCheck "Reopened repeat exactly restores original seeded recipe settings size and contact" (caSWEqual beforeProtection(caSWRecords setup) and caSWEqual savedSettings(caPlacementSettings setup) and caSWPhysical setup)
    local low=caSWRecords setup,seed=(caPlacementSettings setup)[1]
    caGenerate setup #()
    caSWCheck "Raw existing Generate remains deterministic after accepted geometry settings" ((caPlacementSettings setup)[1]==seed and caSWEqual low(caSWRecords setup))
    source=getNodeByName "SW_Source" exact:true
    caSWCheck "Original source transform dimensions and material survive workflow" ((source.transform as string)==sourceTM and source.width==80 and source.length==60 and source.height==20 and source.material.name=="SW_Material")
    caSWNote "LIMIT current Quantity/Fill controls replace old Home/Advanced dirty-field merge. No mouse picking or renderer assertion."
    caSWClose();true
)
try(caSWRun())catch
(
    caSWFailures+=1
    caSWNote("EXCEPTION "+(getCurrentException() as string))
    caSWNote("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
    caSWNote("STACK "+(getCurrentExceptionStackTrace() as string))
    caSWClose()
)
caSWFinished=true
caSWWrite()

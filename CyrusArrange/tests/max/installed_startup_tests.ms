/* A second private normal Max process discovers the actual installed native
   pair, startup and macros. Product commands use only that installed code. */
global CA_TEST_OUTPUT,CA_INSTALL_QA_ROOT,CA_INSTALL_EXPECTED_DIR
global CA_STARTUP_OK,CA_STARTUP_ERROR,CA_ARRANGE_SCRIPT_DIR
global caVersion,caModulePaths,caDiagnostics,caShowUI,caShowAssetUI,caShowArrangeUI,caShowRegionUI,caShowCollisionUI,caFocusArrange
global caSetupSummary,caOutputRows,caSceneSetups,caGenerateVariation,caCreateArrangement,caCreateModifyView
global caReceiverNodes,caAssetRows,caPlacementSettings,caPropMinimums,caCompositionRows,caGeometryCacheInfo,caReadExactSeed
global caModifierUI,caModifierViewOwner,CyrusArrange,CyrusArrangeIcon
global caSLog,caSPasses,caSFailures,caSFinished,caSWrite,caSNote,caSCheck,caSRequire,caSSamePath,caSInside
global caSEqual,caSProcess,caSBound,caSNoPopups,caSPose,caSNodes,caSState,caSMesh,caSSignature,caSLive
global caSVisual,caSPhysical,caSMinima,caSMinimumCount,caSRun
caSLog=#();caSPasses=0;caSFailures=0;caSFinished=false

fn caSWrite=
(
    local report=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n"(if caSFinished then(if caSFailures==0 then "SUCCESS" else "ERROR")else "RUNNING")caSPasses caSFailures to:report
    for line in caSLog do format "%\n"line to:report
    close report
)
fn caSNote line=(append caSLog line;caSWrite();true)
fn caSCheck label value=(if value then caSPasses+=1 else caSFailures+=1;caSNote((if value then "PASS " else "FAIL ")+label);value)
fn caSRequire label value=(caSCheck label value;if not value do throw("Required startup prerequisite: "+label);true)
fn caSEqual a b=deepEqual a b strictCompare:true
fn caSSamePath a b=
(
    local paths=dotNetClass "System.IO.Path"
    (toLower((paths.GetFullPath a)as string))==(toLower((paths.GetFullPath b)as string))
)
fn caSInside path root=
(
    local paths=dotNetClass "System.IO.Path",absoluteRoot=(paths.GetFullPath root)as string
    while absoluteRoot.count>0 and(absoluteRoot[absoluteRoot.count]=="\\"or absoluteRoot[absoluteRoot.count]=="/")do absoluteRoot=substring absoluteRoot 1(absoluteRoot.count-1)
    (findString(toLower((paths.GetFullPath path)as string))(toLower(absoluteRoot+"\\")))==1
)
fn caSProcess=windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
fn caSBound setup=
(
    caModifierUI!=undefined and caModifierViewOwner!=undefined and caModifierUI.currentSetup()==setup and caModifierUI.currentContext()==setup and caModifierUI.isDisplayed and caModifierUI.hwnd!=undefined and caModifierUI.hwnd!=0 and windows.isWindow caModifierUI.hwnd and(getCommandPanelTaskMode())==#modify and(modPanel.getCurrentObject())==setup.modifiers[1]
)
fn caSNoPopups=
(
    for name in #(#caHomeUI,#caHomePropsUI,#caArrangeUI,#caAssetUI,#caUI,#caRegionUI,#caCollisionUI,#caCompositionUI,#caRulesUI)do
    (
        local view=globalVars.get name
        if view!=undefined do if view.isDisplayed do return false
    )
    true
)
fn caSPose setup=for row in(caOutputRows setup)collect #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
fn caSNodes setup=for row in(caOutputRows setup)collect #(row[1],getHandleByAnim row[9])
fn caSState setup=
(
    local summary=caSetupSummary setup
    #(summary[1],summary[3],caPlacementSettings setup,caPropMinimums setup,caSPose setup,caCompositionRows setup,caAssetRows setup)
)
fn caSMesh node=
(
    local value=undefined
    in coordsys world(value=snapshotAsMesh node renderMesh:false)
    if value==undefined do throw "Installed fixture has no evaluated mesh."
    if value.numverts>10000 or value.numfaces>20000 do(delete value;throw "Installed fixture exceeds test snapshot admission.")
    value
)
fn caSSignature node=
(
    local mesh=caSMesh node
    local material=if node.material==undefined then #()else #(classOf node.material as string,node.material.name)
    local result=#(node.name,(for axis=1 to 4 collect node.transform[axis]),material,(for i=1 to mesh.numverts collect getVert mesh i),(for i=1 to mesh.numfaces collect #(getFace mesh i,getFaceMatID mesh i,getFaceSmoothGroup mesh i)))
    if meshop.getMapSupport mesh 1 do append result #((for i=1 to meshop.getNumMapVerts mesh 1 collect meshop.getMapVert mesh 1 i),(for i=1 to meshop.getNumMapFaces mesh 1 collect meshop.getMapFace mesh 1 i))
    delete mesh
    result
)
fn caSLive nodes=for node in nodes collect #(getHandleByAnim node,(if node.material==undefined then 0 else getHandleByAnim node.material))
fn caSVisual setup sourcePairs=
(
    local valid=true,corners=0
    for row in(caOutputRows setup)do
    (
        local source=undefined
        for pair in sourcePairs where pair[1]==row[2]do source=pair[2]
        if not isValidNode source or not isValidNode row[9]then valid=false
        else
        (
            local original=caSMesh source,actual=caSMesh row[9]
            local matching=original.numverts==actual.numverts and original.numfaces==actual.numfaces and row[9].material==source.material
            if matching do for i=1 to original.numfaces do
            (
                if(getFace original i)!=(getFace actual i)or(getFaceMatID original i)!=(getFaceMatID actual i)or(getFaceSmoothGroup original i)!=(getFaceSmoothGroup actual i)do matching=false
            )
            if meshop.getMapSupport original 1 then
            (
                if not(meshop.getMapSupport actual 1)then matching=false
                else if original.numfaces==actual.numfaces do for i=1 to original.numfaces do
                (
                    local a=meshop.getMapFace original 1 i,b=meshop.getMapFace actual 1 i
                    for k=1 to 3 do(if(meshop.getMapVert original 1 a[k])!=(meshop.getMapVert actual 1 b[k])do matching=false;corners+=1)
                )
            )
            else matching=false -- Owned box fixtures deliberately carry mapping.
            if not matching do valid=false
            delete original;delete actual
        )
    )
    valid and corners>0
)
fn caSPhysical setup lowScale highScale=
(
    local rows=caOutputRows setup,valid=true
    for i=1 to rows.count do
    (
        local row=rows[i],bounds=nodeGetBoundingBox row[9](matrix3 1),tm=row[9].transform
        if row[6]<lowScale or row[6]>highScale or abs(bounds[1].z-730)>0.03 do valid=false
        for axis=1 to 3 do if abs((length tm[axis])-row[6])>0.0001 do valid=false
        if bounds[1].x < -588.03 or bounds[2].x > 588.03 or bounds[1].y < -288.03 or bounds[2].y > 288.03 do valid=false
        for j=1 to i-1 do
        (
            local other=nodeGetBoundingBox rows[j][9](matrix3 1)
            local dx=amax #(0.0,bounds[1].x-other[2].x,other[1].x-bounds[2].x),dy=amax #(0.0,bounds[1].y-other[2].y,other[1].y-bounds[2].y)
            if sqrt(dx*dx+dy*dy)<14.97 do valid=false
        )
    )
    valid
)
fn caSMinimumCount setup assetID=(local count=0;for row in(caOutputRows setup)where row[2]==assetID do count+=1;count)
fn caSMinima setup minimums=
(
    local valid=caSEqual minimums(caPropMinimums setup)
    for policy in minimums do if(caSMinimumCount setup policy[1])<policy[2]do valid=false
    valid
)
fn caSRun=
(
    if CA_TEST_OUTPUT==undefined or CA_INSTALL_EXPECTED_DIR==undefined or CA_INSTALL_QA_ROOT==undefined do throw "Installed-startup runner paths are required."
    caSNote "STAGE actual automatically discovered installed startup and native identity"
    caSRequire "Installed startup completed before this test entry"(CA_STARTUP_OK==true and CA_STARTUP_ERROR=="")
    caSRequire "Installed native is exact 0.3.2 in a normal Max2027 process"(caVersion()=="0.3.2"and(maxVersion())[1]==29000 and not maxOps.isInNonInteractiveMode())
    caSRequire "Installed destination and actual INI remain within the private profile"(caSInside CA_INSTALL_EXPECTED_DIR CA_INSTALL_QA_ROOT and caSInside(getMAXIniFile())CA_INSTALL_QA_ROOT)
    local modules=caModulePaths()
    caSRequire "Both loaded module paths are the installed native bin paths"(caSSamePath modules[1](CA_INSTALL_EXPECTED_DIR+"bin/CyrusArrange.dlx")and caSSamePath modules[2](CA_INSTALL_EXPECTED_DIR+"bin/CyrusArrangeStorage.dlh"))
    caSRequire "All six UI entry definitions and current native workflow commands are installed"(caShowUI!=undefined and caShowAssetUI!=undefined and caShowArrangeUI!=undefined and caShowRegionUI!=undefined and caShowCollisionUI!=undefined and caCreateModifyView!=undefined and caFocusArrange!=undefined and caCreateArrangement!=undefined and caSceneSetups!=undefined and caGenerateVariation!=undefined and caPropMinimums!=undefined)
    caSRequire "Lazy UI directory belongs to this installed payload"(caSSamePath CA_ARRANGE_SCRIPT_DIR CA_INSTALL_EXPECTED_DIR)
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1
    local furniture=box name:"CAA_Installed_Table"width:1200 length:600 height:30 pos:[0,0,700]mapcoords:true
    local accessory=box name:"CAA_Installed_FlatBook"width:80 length:60 height:20 pos:[0,2000,0]mapcoords:true
    local decor=box name:"CAA_Installed_Decor"width:45 length:45 height:65 pos:[300,2000,0]mapcoords:true
    furniture.material=standardMaterial name:"CAA_Installed_TableMaterial"diffuse:(color 140 100 60)
    accessory.material=standardMaterial name:"CAA_Installed_BookMaterial"diffuse:(color 50 110 170)
    decor.material=standardMaterial name:"CAA_Installed_DecorMaterial"diffuse:(color 170 85 65)
    local originals=#(furniture,accessory,decor),sourceSignature=for node in originals collect caSSignature node,sourceLive=caSLive originals
    local initialSetups=(caSceneSetups #()).count
    select furniture
    macros.run "Cyrus" "CreateCyrusArrange"
    caSProcess()
    local setup=if selection.count==1 then selection[1]else undefined
    caSRequire "Installed Create action creates one selectable native icon and modifier"(isValidNode setup and classOf setup.baseObject==CyrusArrangeIcon and setup.modifiers.count==1 and classOf setup.modifiers[1]==CyrusArrange and not setup.renderable and(caSceneSetups #()).count==initialSetups+1)
    setup.name="CAA_Installed_Arrangement"
    caSRequire "Create action mounts the actual native-hosted Modify page for its owner"(caSBound setup)
    caSRequire "Create binds selected receiving geometry without analyzing or generating"(caSEqual #(furniture)(caReceiverNodes setup)and(caOutputRows setup).count==0 and(caAssetRows setup).count==0 and(caGeometryCacheInfo setup)[3]==undefined and not(caDiagnostics())[3])
    local passiveState=caSState setup
    for action in #("CyrusArrangeStyling","CyrusArrangeInspector")do
    (
        macros.run "Cyrus" action
        caSProcess()
        caSRequire("Installed "+action+" focuses the same native document in Modify")(caSBound setup and caSEqual passiveState(caSState setup)and(caSceneSetups #()).count==initialSetups+1 and(caGeometryCacheInfo setup)[3]==undefined and caSNoPopups())
    )
    local installedView=caModifierUI,installedAttribute=caModifierViewOwner
    local installedAnim=getHandleByAnim installedAttribute,installedID=installedAttribute.classID,installedBinding=installedAttribute.bindingSnapshot(),resolvedWindow=installedAttribute.modifyControls.hwnd
    caSNote("INSTALLED_MODIFY_CA nativeAnim="+(installedAnim as string)+" classID="+(installedID as string)+" resolvedHWND="+(resolvedWindow as string)+" mountedHWND="+(installedView.hwnd as string)+" binding="+(installedBinding as string))
    caSRequire "Installed controls bind the exact native presentation CA and live page"(installedAnim>0 and installedID.count==2 and(installedID[1]as Integer64)==0x6a4387d5 and(installedID[2]as Integer64)==0x4fa90372 and resolvedWindow==installedView.hwnd and windows.isWindow resolvedWindow and installedBinding.count==4 and installedBinding[1]==setup and installedBinding[2]==setup and installedBinding[4])
    caSRequire "Current inline Props Scale Keep clear and Path pages are present"(installedAttribute.propControls.hwnd!=0 and installedAttribute.scaleControls.hwnd!=0 and installedAttribute.protectionControls.hwnd!=0 and installedAttribute.pathControls.hwnd!=0)

    caSNote "STAGE installed pinned bulk selection and inline authored drafts"
    modPanel.setPinStack true
    select #(accessory,decor)
    caSRequire "Actual installed Add selected props button registers both originals on the pinned arrangement"(installedAttribute.propControls.addSelection.pressed()and(caAssetRows setup).count==2 and installedAttribute.propControls.propList.items.count==2 and caSBound setup)
    local catalog=caAssetRows setup,sourcePairs=#(),minimums=#()
    for index=1 to catalog.count do
    (
        local source=getNodeByName catalog[index][2]exact:true
        caSRequire("Registered original prop is bound: "+catalog[index][2])(isValidNode source and catalog[index][10])
        append sourcePairs #(catalog[index][1],source)
        append minimums #(catalog[index][1],2)
        installedAttribute.propControls.propList.selection=index
        installedAttribute.dispatch #minimumSelection
        installedAttribute.propControls.minimumCopies.value=2
        installedAttribute.propControls.minimumCopies.changed 2
    )
    caModifierUI.amountMode.selection=1;installedAttribute.amountChanged 1
    caModifierUI.quantity.value=4;caModifierUI.spacing.value=15
    installedAttribute.protectionControls.edgeGap.value=12;installedAttribute.protectionControls.edgeGap.changed 12
    installedAttribute.scaleControls.randomScale.checked=true;installedAttribute.scaleControls.randomScale.changed true
    installedAttribute.scaleControls.minimumScale.value=80;installedAttribute.scaleControls.maximumScale.value=110
    caModifierUI.keepSeed.checked=false;caModifierUI.keepSeed.changed false
    local draftState=caSState setup,previousSeed=(caPlacementSettings setup)[1]
    caSRequire "Inline quantity minimums and scale remain unapplied until Generate"((caPropMinimums setup).count==0 and caSEqual minimums(caModifierUI.readMinimumDraft())and(caOutputRows setup).count==0 and(caGeometryCacheInfo setup)[3]==undefined and not(caPlacementSettings setup)[7]and caSNoPopups())
    caSRequire "Actual installed Generate applies drafts and creates four complete copies"(caModifierUI.generateButton.pressed()and(caOutputRows setup).count==4)
    local first=caSState setup,settings=caPlacementSettings setup
    caSRequire "Installed Generate commits exact authored policy in one revision"(first[2]==draftState[2]+1 and settings[2]==2 and settings[3]==4 and settings[5]==15 and settings[6]==12 and settings[7]and settings[9]==0.8 and settings[10]==1.1 and caSMinima setup minimums)
    caSRequire "Fresh Generate saves a new nonnegative seed and exact UI seed text"(settings[1]>=0 and settings[1]!=previousSeed and(caReadExactSeed caModifierUI.seedText.text)==settings[1])
    caSRequire "Installed copies satisfy actual support edges separation and uniform scale"(caSPhysical setup 0.8 1.1)
    caSRequire "Installed output keeps complete source topology UV corners smoothing and material references"(caSVisual setup sourcePairs)

    caSNote "STAGE new variation failure retention and single Generate Undo/Redo"
    caModifierUI.quantity.value=6
    installedAttribute.scaleControls.minimumScale.value=90;installedAttribute.scaleControls.maximumScale.value=100
    caSRequire "Another actual Generate commits edited copies and scale with a fresh variation"(caModifierUI.generateButton.pressed()and(caOutputRows setup).count==6 and(caPlacementSettings setup)[1]!=first[3][1])
    local second=caSState setup,acceptedNodes=caSNodes setup
    caSRequire "Second installed result honors both required source counts and narrower random scale"(second[3][3]==6 and second[3][9]==0.9 and second[3][10]==1.0 and caSMinima setup minimums and caSPhysical setup 0.9 1.0)
    installedAttribute.scaleControls.minimumScale.value=120;installedAttribute.scaleControls.maximumScale.value=80
    caSRequire "Invalid installed scale draft fails visibly without replacing accepted state or nodes"(not caModifierUI.generateButton.pressed()and caModifierUI.errorMessage()!=""and caSEqual second(caSState setup)and caSEqual acceptedNodes(caSNodes setup))
    -- Discard only this test's invalid visible draft, without a native command.
    installedAttribute.scaleControls.minimumScale.value=90;installedAttribute.scaleControls.maximumScale.value=100
    local commands=(caGeometryCacheInfo setup)[3][12]
    max undo
    caSProcess()
    caSRequire "One Undo restores all first accepted settings minimums seed groups and output"(caSEqual first(caSState setup))
    caSRequire "Installed Undo refreshes the live page without solving or reviving the rejected error"(caSBound setup and caModifierUI.quantity.value==4 and installedAttribute.scaleControls.minimumScale.value==80 and installedAttribute.scaleControls.maximumScale.value==110 and caModifierUI.errorMessage()==""and(caGeometryCacheInfo setup)[3][12]==commands)
    max redo
    caSProcess()
    caSRequire "One Redo restores the full second result and inline scale without solving"(caSEqual second(caSState setup)and caSBound setup and caModifierUI.quantity.value==6 and installedAttribute.scaleControls.minimumScale.value==90 and installedAttribute.scaleControls.maximumScale.value==100 and(caGeometryCacheInfo setup)[3][12]==commands)
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caSRequire "Installed Repeat seed reproduces exact settings policy and ordered poses"(caModifierUI.generateButton.pressed()and caSEqual second[3](caPlacementSettings setup)and caSEqual second[4](caPropMinimums setup)and caSEqual second[5](caSPose setup))
    caSRequire "All original table and source geometry UVs transforms and material references remain unchanged"(caSEqual sourceSignature(for node in originals collect caSSignature node)and caSEqual sourceLive(caSLive originals)and caSVisual setup sourcePairs)

    caSNote "STAGE installed binding lifetime and saved native document"
    installedAttribute=caModifierViewOwner
    max create mode
    caSRequire "Closing installed Modify releases the exact former owner context and mounted flag"(caModifierUI==undefined and caModifierViewOwner==undefined and(installedAttribute.bindingSnapshot())[1]==undefined and(installedAttribute.bindingSnapshot())[2]==undefined and not(installedAttribute.bindingSnapshot())[4])
    local setupName=setup.name,before=caSState setup,scene=CA_TEST_OUTPUT+"installed-startup.max"
    caSRequire "Installed persistent setup saves"(saveMaxFile scene quiet:true)
    caSRequire "Installed persistent setup reopens"(loadMaxFile scene quiet:true useFileUnits:true)
    setup=getNodeByName setupName exact:true
    caSRequire "Installed GUID assets settings minimums seed and placements survive save-load"(isValidNode setup and caSEqual before(caSState setup))
    originals=#(getNodeByName "CAA_Installed_Table"exact:true,getNodeByName "CAA_Installed_FlatBook"exact:true,getNodeByName "CAA_Installed_Decor"exact:true)
    caSRequire "Reopened original source snapshots and material labels retain their exact data"(caSEqual sourceSignature(for node in originals collect caSSignature node))
    local cached=(caGeometryCacheInfo setup)[3]
    select setup
    macros.run "Cyrus" "CyrusArrangeInspector"
    caSProcess()
    caSRequire "Installed Parameters reopens the saved native page passively with accepted values"(caSBound setup and caSEqual before(caSState setup)and caSEqual cached(caGeometryCacheInfo setup)[3]and caModifierUI.quantity.value==6 and caModifierViewOwner.scaleControls.minimumScale.value==90 and caModifierViewOwner.scaleControls.maximumScale.value==100 and caSNoPopups())
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caSRequire "Explicit installed Generate after reopen repeats saved seed policy and output"(caModifierUI.generateButton.pressed()and caSEqual before[3](caPlacementSettings setup)and caSEqual before[4](caPropMinimums setup)and caSEqual before[5](caSPose setup))
    caSRequire "Final installed workflow still uses one native arrangement and no popup"((caSceneSetups #()).count==initialSetups+1 and caSNoPopups())
    local identity=createFile(CA_TEST_OUTPUT+"loaded-native.txt")
    for modulePath in(caModulePaths())do format "%\n"modulePath to:identity
    format "%\n"(getMAXIniFile())to:identity
    close identity
    caSNote "LIMIT: actual installed startup/macros/handlers/state and simple mapped mesh preservation are checked; mouse gestures, rendered pixels, general packing performance and independent full-mesh cases remain separate."
    caSNote "INSTALLED_STARTUP_PRIVATE_PROFILE"
    true
)
try(caSRun())catch
(
    caSFailures+=1
    caSNote("EXCEPTION "+(getCurrentException()as string))
    caSNote("STARTUP_ERROR "+(CA_STARTUP_ERROR as string))
    caSNote("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string))
    caSNote("STACK "+(getCurrentExceptionStackTrace()as string))
)
caSFinished=true
caSWrite()

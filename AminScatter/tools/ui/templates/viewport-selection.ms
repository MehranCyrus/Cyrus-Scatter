-- Shared controls bind existing Scatter controllers. No second recipe model.
global CyrusSelectionUI,CyrusSelectionRefresh,CyrusSelectionChanged,CyrusSelectionBusy=false,CyrusSelectionClosedKey="",CyrusSelectionTimer
global CyrusOpenSelectionControls,CyrusSelectionApply,CyrusSelectionTargets
global CyrusSelectionPending=undefined
fn CyrusSelectionEnterInstance request = (
    local node=request[1]
    if not isValidNode node or selection.count!=1 or selection[1]!=node do return false
    if not (cyrusViewportSelectionValid node request[4]) do return false
    local root=node.baseObject,edit=undefined
    for m in node.modifiers where edit==undefined and classof m==CyrusScatterEdit and m.enabled do edit=m
    if edit==undefined do (
        if not CyrusLicenseCanEdit() do return false
        -- Capture only the complete retained result. No source mesh query,
        -- placement solve, contact fit or preview publication on selection.
        local retained=for i=1 to root.procPublishedOwners.count collect (
            local leaf=root.procPublishedOwners[i]
            #(leaf.editLayerKey,root.groupSnapshotRows[i],leaf.procBindingKey,(leaf.procPreviewPalette root.procPublishedMetadata[i]),(root.visibleLayer (findItem root.layerObjects leaf)))
        )
        edit=CyrusScatterEdit()
        cyrusEditAttachDisplayed edit node retained
        undo "Enable Cyrus instance editing" on addModifier node edit
    )
    local key=cyrusEditSelectViewport edit node request[2] request[3]
    if key==undefined do return false
    for leaf in root.layerObjects where leaf.editLayerKey==key do (
        local parent=root.logicalParent leaf
        undo off root.selectLayer (findItem root.layerObjects parent)
    )
    max modify mode
    modPanel.setCurrentObject edit
    subObjectLevel=1
    redrawViews();true
)
fn CyrusSelectionTargets all:false = (
    local nodes=if all then CyrusTimeOwners else (selection as array)
    for n in nodes where isValidNode n and classof n.baseObject==AminScatterObject collect n
)
fn CyrusSelectionApply nodes property value = (
    if not CyrusLicenseCanEdit() do return false
    -- Capture owners before callbacks can alter the Modify panel or selection.
    local owners=for n in nodes where isValidNode n and classof n.baseObject==AminScatterObject collect n.baseObject
    undo "Cyrus shared viewport" on (
        for owner in owners do (
            case property of (
                #display: (
                    if value==5 then owner.identificationMode=4 else if owner.identificationMode==4 do owner.identificationMode=1
                    owner.setGroupDisplay (if value==5 then 3 else value)
                )
                #enabled: (owner.cyrusEnabled=value;owner.invalidateGroups())
                #update: owner.refreshAll()
                default: (
                    if findItem #(#viewportNavigationFaces,#viewportFaces,#showPoints) property==0 do throw "Unsupported shared viewport setting."
                    setProperty owner property value
                    if property!=#showPoints do owner.refreshDisplay()
                )
            )
        )
    )
    CyrusViewportRedraw();true
)
rollout CyrusSelectionUI "Cyrus Scatter - selected setups" width:290 height:360 (
    local binding=false,nodes=#()
    dropdownlist scope "Apply to" items:#("Selected Scatters","All Scatters") selection:1 pos:[12,8] width:266
    label summary "" pos:[12,58] width:266 height:34
    button updateButton "Update Scatters" pos:[12,96] width:266
    button enableButton "Enable" pos:[12,124] width:130
    button disableButton "Disable" pos:[148,124] width:130
    dropdownlist display "Viewport display" items:#("Mixed / choose...","Point Cloud","Proxy","Mesh","Centers","Textured mesh") pos:[12,155] width:266
    spinner navigation "Moving triangles:" type:#integer range:[0,2147483647,500000] pos:[12,210] width:266 fieldWidth:110
    spinner idle "Idle triangles:" type:#integer range:[0,2147483647,2000000] pos:[12,238] width:266 fieldWidth:110
    button showButton "Show previews" pos:[12,268] width:130
    button hideButton "Hide previews" pos:[148,268] width:130
    label hint "Only the control you change is applied. Mixed budgets are marked below; 0 = unlimited." pos:[12,300] width:266 height:36
    label mixed "" pos:[12,338] width:266 height:18
    fn bind = (
        binding=true
        nodes=CyrusSelectionTargets all:(scope.selection==2)
        summary.text=(nodes.count as string)+" Scatter setup(s). Update also applies pending Manual edits."
        local usable=nodes.count>0
        for control in #(updateButton,enableButton,disableButton,display,navigation,idle,showButton,hideButton) do control.enabled=usable
        mixed.text=""
        if usable do (
            local first=nodes[1].baseObject,modes=#(),nav=#(),rest=#()
            for node in nodes do (
                local owner=node.baseObject
                appendIfUnique modes (if owner.groupCenters then 4 else if owner.viewportMode==3 and owner.identificationMode==4 then 5 else owner.viewportMode)
                appendIfUnique nav owner.viewportNavigationFaces;appendIfUnique rest owner.viewportFaces
            )
            display.selection=if modes.count==1 then modes[1]+1 else 1
            navigation.value=first.viewportNavigationFaces;idle.value=first.viewportFaces
            mixed.text=(if nav.count>1 then "Moving: mixed. " else "")+(if rest.count>1 then "Idle: mixed." else "")
        )
        binding=false
    )
    fn apply property value = (if not binding do (local captured=for n in nodes collect n;CyrusSelectionApply captured property value;bind()))
    on scope selected value do bind()
    on updateButton pressed do apply #update true
    on enableButton pressed do apply #enabled true
    on disableButton pressed do apply #enabled false
    on display selected value do if value>1 do apply #display (value-1)
    on navigation changed value do apply #viewportNavigationFaces value
    on idle changed value do apply #viewportFaces value
    on showButton pressed do apply #showPoints true
    on hideButton pressed do apply #showPoints false
    on CyrusSelectionUI open do bind()
    on CyrusSelectionUI close do CyrusSelectionClosedKey=(for n in (CyrusSelectionTargets()) collect getHandleByAnim n) as string
)
fn CyrusOpenSelectionControls = (
    if not CyrusSelectionUI.open do createDialog CyrusSelectionUI style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    CyrusSelectionUI.bind()
)
fn CyrusSelectionRefresh = (
    local targets=CyrusSelectionTargets(),key=(for n in (CyrusSelectionTargets()) collect getHandleByAnim n) as string
    if CyrusSelectionUI.open then CyrusSelectionUI.bind()
    else if targets.count>1 and key!=CyrusSelectionClosedKey do CyrusOpenSelectionControls()
)
fn CyrusSelectionChanged = (
    if CyrusSelectionBusy do return false
    CyrusSelectionBusy=true
    try (
        local nodes=selection as array,redirected=#(),changed=false
        CyrusSelectionPending=undefined
        if nodes.count==1 and cyrusViewportSelectionHit!=undefined do CyrusSelectionPending=cyrusViewportSelectionHit nodes[1]
        for n in nodes where isValidNode n do (
            local owner=if cyrusViewportSelectionOwner!=undefined then cyrusViewportSelectionOwner n else undefined
            if isValidNode owner then (appendIfUnique redirected owner;changed=true) else appendIfUnique redirected n
        )
        if changed do select redirected
        CyrusSelectionRefresh()
    )catch(format "Cyrus selection: %\n" (getCurrentException()))
    CyrusSelectionBusy=false
)
callbacks.removeScripts id:#CyrusViewportSelection
callbacks.addScript #selectionSetChanged "CyrusSelectionChanged()" id:#CyrusViewportSelection
try(CyrusSelectionTimer.Stop();dotNet.removeAllEventHandlers CyrusSelectionTimer)catch()
fn CyrusSelectionHoverTick sender event = (
    if CyrusSelectionPending!=undefined and not CyrusSelectionBusy and not CyrusPointBusy and cyrusViewportPointerIdle() do (
        local request=CyrusSelectionPending;CyrusSelectionPending=undefined;CyrusSelectionBusy=true
        try(CyrusSelectionEnterInstance request)catch(format "Cyrus instance selection: %\n" (getCurrentException()))
        CyrusSelectionBusy=false
    )
    if cyrusViewportHoverTick!=undefined and not CyrusPointBusy and AminScatterRenderRedrawHeld!=true do
        try(if cyrusViewportHoverTick() do redrawViews())catch()
)
CyrusSelectionTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusSelectionTimer.Interval=80
dotNet.addEventHandler CyrusSelectionTimer "Tick" CyrusSelectionHoverTick
CyrusSelectionTimer.Start()

-- Natural Modify selection regression. All scenes/processes are disposable.
-- The router interception is a private failure witness, never product code.
global U73SelectionOriginalPanel,U73SelectionErrors=#(),U73SelectionCalls=0,U73SelectionColdPanel
global U73SelectionNodes=#(),U73SelectionHelpers=#(),U73SelectionExpectedRoot,U73SelectionExpectedSet
global U73SelectionBefore,U73SelectionChecks=#(),U73SelectionStage="",U73SelectionSaved,U73SelectionReopened=false,U73SelectionClosedPanel
struct U73SelectionColdPanelType (
    controlsReady=false,editors=#(),binding=false,
    fn layoutPanels = true,
    fn bindSection section = false
)
global U73SelectionSetup,U73SelectionChoose,U73SelectionCheck,U73SelectionBrowse
global U73SelectionSwitch,U73SelectionAway,U73SelectionClosedCheck,U73SelectionSave,U73SelectionReload
global U73SelectionFinish,U73SelectionSnapshot,U73SelectionAssert
fn U73SelectionAssert value message = (
    if not value do throw ("[natural container selection: "+U73SelectionStage+"] "+message)
    true
)
fn U73SelectionSnapshot = (
    for node in U73SelectionNodes where isValidNode node collect (
        local root=node.baseObject,owner=CyrusPointOwner node
        local retained=if isValidNode owner then cyrusRetainedStats owner else undefined
        #((getHandleByAnim node) as integer64,root.procEpoch,(root.groupCounters())[1],
          (for leaf in root.layerObjects collect #(leaf.procPreparedBuilds,leaf.containerScans,leaf.containerTests,leaf.containerMembershipBuilds,(leaf.cacheSnapshot())[6])),
          (if retained!=undefined then (for k in #(3,4,5,6,7,9) collect retained[k]) else undefined),
          (if isValidNode owner then cyrusRetainedMeshStats owner else undefined))
    )
)
fn U73SelectionSetup = (
    if findString MCPFixtureDir "/build/mcp-qualification/"==undefined do throw "Private fixture required"
    P07Case="natural container selection";P07New count:200
    local root=P07Root,leaf=P07Layer,source=P07Source,c=leaf.containerCreate()
    c.name="U73_SharedContainer";c.pos=source.pos
    local flowers=root.addPaintSet leaf label:"Flowers"
    flowers.sources=#(source);flowers.containerMode=2;flowers.paintEnabled=false;flowers.sourceRadii=#(7.0)
    local second=AminScatterObject name:"U73_SecondSetup",other=second.baseObject
    other.autoRender=false;other.updateMode=1;other.surfaceNodes=#(P07Surface);other.newLayer()
    local secondSet=other.selectedLayer()
    secondSet.sources=#(source);secondSet.sourceWeights=#(1.0);secondSet.amount=80;secondSet.paintEnabled=false
    secondSet.containerAdd c;secondSet.containerMode=4;secondSet.sourceRadii=#(13.0)
    local empty=AminScatterObject name:"U73_GlobalSetup",globalContainer=empty.baseObject.containerCreate globalPool:true
    globalContainer.name="U73_GlobalContainer"
    local unlinked=CyrusSourceContainer name:"U73_UnlinkedContainer"
    U73SelectionNodes=#(P07Node,second,empty)
    U73SelectionHelpers=#(c,globalContainer,unlinked)
    root.refreshAll();other.refreshAll();empty.baseObject.refreshAll();CyrusContainerRefreshAll()
    clearSelection();max modify mode
    U73SelectionBefore=U73SelectionSnapshot()
    U73SelectionErrors=#();U73SelectionCalls=0;U73SelectionChecks=#();U73SelectionReopened=false
    U73SelectionOriginalPanel=CyrusContainerPanel;U73SelectionColdPanel=U73SelectionColdPanelType()
    fn CyrusContainerPanel root = (
        U73SelectionCalls+=1
        try(U73SelectionOriginalPanel root)catch(
            append U73SelectionErrors #(#("error",getCurrentException()),#("root_undefined",root==undefined),#("stage",U73SelectionStage))
            CSPWriteText (MCPFixtureDir+"container-selection-errors.json") (CSPJson U73SelectionErrors)
            U73SelectionColdPanel
        )
    )
    U73SelectionChoose 1
    true
)
fn U73SelectionChoose index = (
    U73SelectionStage="select helper "+index as string
    local node=U73SelectionHelpers[index],context=CyrusContainerResolve node.baseObject
    U73SelectionExpectedRoot=if context==undefined then undefined else context[1]
    U73SelectionExpectedSet=if context==undefined then undefined else context[2]
    select node
    -- No tick(), setCurrentObject(), bind() or processPostedMessages() here.
    -- The launcher returns to Max's normal message loop before checking.
    true
)
fn U73SelectionCheck = (
    U73SelectionAssert (U73SelectionErrors.count==0) "A rollout called the original router without a valid owner"
    local node=selection[1],view=node.baseObject,panel=view.mainUI
    CSPWriteText (MCPFixtureDir+"selection-mount.json") (CSPObject #(#("stage",U73SelectionStage),#("reopened",U73SelectionReopened),#("task",getCommandPanelTaskMode() as string),#("displayed",panel.isDisplayed),#("ready",panel.controlsReady),#("expected",if U73SelectionExpectedRoot==undefined then "undefined" else U73SelectionExpectedRoot.layerID),#("actual",if panel.root==undefined then "undefined" else panel.root.layerID)))
    U73SelectionAssert (classof view==CyrusSourceContainer) "Selection was replaced by a Scatter controller"
    if U73SelectionExpectedRoot==undefined then (
        U73SelectionAssert (not panel.controlsReady and panel.root==undefined) "Unlinked helper guessed a controller"
        panel.enabledCheck.changed false
    ) else (
        U73SelectionAssert (panel.controlsReady and panel.root==U73SelectionExpectedRoot) "Natural mount did not bind the expected controller"
        U73SelectionAssert (not panel.mountTimer.active) "Mount timer remains active after settling"
        local expectedParent=if U73SelectionExpectedSet==undefined then undefined else U73SelectionExpectedRoot.logicalParent U73SelectionExpectedSet
        U73SelectionAssert (panel.owner==expectedParent) "Natural mount selected the wrong layer"
        for section in panel.roots do U73SelectionAssert (section.root==U73SelectionExpectedRoot and (not section.open or section.controlsReady)) "General controls retained an undefined or previous root"
        if expectedParent!=undefined do (
            view.modelsUI.open=true
            view.modelsUI.rolledUp true
            CSPWriteText (MCPFixtureDir+"selection-binding.json") (CSPObject #(#("stage",U73SelectionStage),#("expected",U73SelectionExpectedSet.layerID),#("selected",(panel.root.selectedPaintSet panel.owner).layerID),#("bound",if view.modelsUI.sourceUI_obj==undefined then "undefined" else view.modelsUI.sourceUI_obj.layerID)))
            U73SelectionAssert (view.modelsUI.sourceUI_obj==U73SelectionExpectedSet) "Source fields target a different paint set"
        )
    )
    local after=U73SelectionSnapshot()
    CSPWriteText (MCPFixtureDir+"selection-counter-comparison.json") (CSPObject #(#("stage",U73SelectionStage),#("reopened",U73SelectionReopened),#("before",U73SelectionBefore),#("after",after)))
    U73SelectionAssert (after as string==U73SelectionBefore as string) "Selection changed calculation, membership or retained buffers"
    append U73SelectionChecks #(U73SelectionStage,true)
    true
)
fn U73SelectionBrowse = (
    U73SelectionStage="expand and cold rollup handlers"
    local view=U73SelectionHelpers[1].baseObject,panel=view.mainUI
    for cycle=1 to 3 do (
        for section in panel.editors do (section.open=true;section.rolledUp true;section.open=false;section.rolledUp false)
        for section in panel.roots do (section.open=true;section.rolledUp true;section.open=false;section.rolledUp false)
    )
    -- Simulate a rollup notification while mount owns initialization. It must
    -- not guess a root or bind controls during that incomplete transition.
    local sections=panel.editors+panel.roots,oldRoots=for section in sections collect section.root
    panel.controlsReady=false
    for section in panel.editors do (section.root=undefined;section.rolledUp true)
    for section in panel.roots do (section.root=undefined;section.rolledUp true)
    panel.enabledCheck.changed false
    for i=1 to sections.count do sections[i].root=oldRoots[i]
    panel.controlsReady=true
    panel.bind()
    U73SelectionAssert (U73SelectionErrors.count==0) "Initial/cold rollup handler still dereferences undefined"
    U73SelectionCheck()
    true
)
fn U73SelectionSwitch index = (
    U73SelectionStage="shared consumer "+index as string
    local view=U73SelectionHelpers[1].baseObject,row=view.consumerRows[index]
    U73SelectionExpectedRoot=(getAnimByHandle row[1]).baseObject
    U73SelectionExpectedSet=for leaf in U73SelectionExpectedRoot.layerObjects where leaf.layerID==row[3] collect leaf
    U73SelectionExpectedSet=U73SelectionExpectedSet[1]
    -- Dropdown.selected is the selected item text, not a callable handler.
    -- Invoke the same function dispatched by its native selection event.
    view.containerUI.consumerList.selection=index;view.containerUI.selectConsumer index
    true
)
fn U73SelectionAway = (
    U73SelectionStage="deselect and late timer"
    U73SelectionClosedPanel=selection[1].baseObject.mainUI
    select P07Source
    true
)
fn U73SelectionClosedCheck = (
    U73SelectionAssert (not U73SelectionClosedPanel.isDisplayed) "Helper panel remains displayed after selection leaves"
    -- This negative probe deliberately invokes a queued handler after close.
    -- Positive mounts always use the normal host message loop.
    U73SelectionClosedPanel.mountTimer.tick()
    U73SelectionAssert (U73SelectionErrors.count==0) "A closed panel dereferenced its discarded rollout locals"
    U73SelectionAssert ((U73SelectionSnapshot()) as string==U73SelectionBefore as string) "Late timer changed calculation or buffers"
    append U73SelectionChecks #(U73SelectionStage,true)
    true
)
fn U73SelectionSave = (
    U73SelectionStage="save and close scene"
    U73SelectionSaved=MCPFixtureDir+"Natural-Container-Selection.max"
    U73SelectionAssert (saveMaxFile U73SelectionSaved quiet:true) "Save failed"
    resetMaxFile #noPrompt
    true
)
fn U73SelectionReload = (
    U73SelectionStage="reopen container scene"
    U73SelectionAssert (loadMaxFile U73SelectionSaved quiet:true) "Reopen failed"
    U73SelectionNodes=for name in #("P07_Controller","U73_SecondSetup","U73_GlobalSetup") collect (getNodeByName name)
    U73SelectionHelpers=for name in #("U73_SharedContainer","U73_GlobalContainer","U73_UnlinkedContainer") collect (getNodeByName name)
    for node in U73SelectionHelpers do U73SelectionAssert (isValidNode node) "Reopened helper name differs"
    for node in U73SelectionNodes do node.baseObject.procReadSnapshot()
    clearSelection();max modify mode
    -- Exact-output restore does not create viewport preview owners. Warm the
    -- cold scene with nothing selected before measuring passive UI actions.
    local cold=U73SelectionSnapshot()
    for warm=1 to 3 do (completeRedraw();windows.processPostedMessages())
    U73SelectionBefore=U73SelectionSnapshot()
    CSPWriteText (MCPFixtureDir+"selection-reopen-warmup.json") (CSPObject #(#("no_selection",selection.count==0),#("cold",cold),#("warm",U73SelectionBefore)))
    U73SelectionReopened=true
    U73SelectionChoose 1
    true
)
fn U73SelectionFinish = (
    U73SelectionStage="final"
    U73SelectionAssert (U73SelectionErrors.count==0) "Unhandled router failures were recorded"
    U73SelectionAssert U73SelectionReopened "Scene reopen was not tested"
    CSPWriteText (MCPFixtureDir+"container-selection073.json") (CSPObject #(
        #("passed",true),#("router_errors",U73SelectionErrors.count),#("router_calls",U73SelectionCalls),
        #("checks",U73SelectionChecks),#("natural_mount",true),#("explicit_positive_mount_calls",0),#("closed_timer_negative_probe",true),
        #("unchanged_calculation_and_buffers",true),#("reopen",true),#("pointer_test",false)))
    CyrusContainerPanel=U73SelectionOriginalPanel
    true
)

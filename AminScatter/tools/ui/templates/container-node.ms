-- Scene helper and cached presentation. Controller -> container is the only
-- persistent controller link; reverse editing contexts use durable IDs.
global CyrusSourceContainer,CyrusContainerConsumers,CyrusContainerLinks,CyrusContainerResolve,CyrusContainerPanel,CyrusContainerRefreshAll,CyrusContainerRefreshPresentation,CyrusContainerInside,CyrusContainerRefreshLabels,CyrusContainerNodes=#()
plugin helper CyrusSourceContainer
name:"Cyrus Source Container" category:"Cyrus" classID:#(0x51732c41,0x42cf0973) extends:CyrusSourceFrame version:1
(
    parameters containerSettings (
        width type:#worldUnits default:500
        length type:#worldUnits default:300
        showLabel type:#boolean default:true
        containerID type:#string default:""
        contextRootID type:#string default:""
        contextSetID type:#string default:""
        savedSources type:#nodeTab tabSize:0 tabSizeVariable:true
        movementSources type:#nodeTab tabSize:0 tabSizeVariable:true
        on width set value do CyrusContainerRefreshPresentation this
        on length set value do CyrusContainerRefreshPresentation this
        on showLabel set value do CyrusContainerRefreshPresentation this
    )
    local consumerRows=#(),consumerLabels=#(),cachedLabel="Unlinked source container",cachedActiveCount=0,cachedSavedCount=0,cachedConsumerCount=0,movementUnits=#(),movementStatus="Ready"
    local updateUI,surfaceUI,previewUI,layersUI,uiRootState=#()
    fn configure node = (
        if (refs.dependentNodes this).count!=1 do (
            movementStatus="Instanced containers cannot carry sources. Make a unique copy."
            cyrusContainerDisable delegate;return false
        )
        cyrusContainerConfigure delegate node movementUnits width length cachedLabel showLabel (for source in movementSources where isValidNode source collect source)
    )
    fn movePalette delta = (
        if (refs.dependentNodes this).count!=1 do throw "Make this container unique before moving its sources."
        cyrusContainerTranslate delegate delta
    )
    fn movementStats = (cyrusContainerMoveStats delegate)
    fn nativeEditors = (for r in #(updateUI,surfaceUI,previewUI,layersUI) where r!=undefined collect r)
    -- __CONTAINER_PANEL__
    on attachedToNode node do (
        node.renderable=false;node.wirecolor=color 80 180 240
        local duplicate=false
        for handle in CyrusContainerNodes do (local prior=getAnimByHandle handle;if isValidNode prior and prior!=node and prior.baseObject!=this and prior.containerID==containerID do duplicate=true)
        if duplicate do (containerID="";contextRootID="";contextSetID="";savedSources=#();movementSources=#())
        if containerID=="" do containerID=CyrusNewLayerID()
        appendIfUnique CyrusContainerNodes (getHandleByAnim node)
        configure node
    )
    tool create (
        on mousePoint click do (if click==1 do nodeTM.translation=gridPoint;if click==2 do #stop)
        on mouseMove click do (if click==2 do (width=amax .01 (2*abs gridDist.x);length=amax .01 (2*abs gridDist.y)))
    )
)
fn CyrusContainerResolve view = (
    for row in view.consumerRows do (
        local node=getAnimByHandle row[1]
        if isValidNode node and classof node.baseObject==AminScatterObject and node.baseObject.layerID==view.contextRootID do (
            local root=node.baseObject
            if view.contextSetID=="" and root.layerObjects.count==0 do return #(root,undefined)
            for leaf in root.layerObjects where leaf.layerID==view.contextSetID do return #(root,leaf)
        )
    )
    undefined
)
fn CyrusContainerConsumers node = (
    local rows=#()
    for controller in CyrusTimeOwners where isValidNode controller do (
        local root=controller.baseObject
        for leaf in root.layerObjects where findItem (leaf.effectiveContainers()) node>0 do append rows #(controller,root,leaf)
    )
    rows
)
fn CyrusContainerLinks node = (
    local rows=CyrusContainerConsumers node
    for controller in CyrusTimeOwners where isValidNode controller do (
        local root=controller.baseObject
        for leaf in root.layerObjects where findItem leaf.containerNodes node>0 do (
            if (for row in rows where row[1]==controller and row[3]==leaf collect row).count==0 do append rows #(controller,root,leaf)
        )
        if findItem root.containerGlobalNodes node>0 and (for row in rows where row[1]==controller collect row).count==0 do (
            local leaf=root.selectedLayer()
            if leaf!=undefined do leaf=root.selectedPaintSet (root.logicalParent leaf)
            append rows #(controller,root,leaf)
        )
    )
    rows
)
fn CyrusContainerInside model node = (
    local p=model.transform.row4*(inverse node.objectTransform),epsilon=amax 1e-4 ((amax node.width node.length)*.5e-6)
    abs p.x<=node.width/2+epsilon and abs p.y<=node.length/2+epsilon
)
fn CyrusContainerRefreshLabels root = (
    for handle in CyrusContainerNodes do (
        local node=getAnimByHandle handle
        if isValidNode node do (
            local view=node.baseObject,context=CyrusContainerResolve view
            if root==undefined or (context!=undefined and context[1]==root) do (
                local caption=if context==undefined then (if view.consumerRows.count==0 then "Unlinked" else "Choose context") else if context[2]==undefined then "Global sources" else context[1].setCaption context[2]
                view.cachedLabel=node.name+" | "+caption+" | "+(view.cachedActiveCount as string)+" active / "+(view.cachedSavedCount as string)+" saved"+(if view.cachedConsumerCount>1 then " | "+(view.cachedConsumerCount as string)+" consumers" else "")
                view.configure node
            )
        )
    )
    true
)
fn CyrusContainerRefreshPresentation view = (
    for node in refs.dependentNodes view where isValidNode node and node.baseObject==view do view.configure node
    CyrusViewportRedraw();true
)
fn CyrusContainerPanel root = (
    local active=try(modPanel.getCurrentObject())catch(undefined)
    if active!=undefined and classof active==CyrusSourceContainer then (
        local context=CyrusContainerResolve active
        if context!=undefined and context[1]==root and active.mainUI.controlsReady do return active.mainUI
    )
    root.mainUI
)
fn CyrusContainerRefreshAll = (
    CyrusContainerNodes=for handle in CyrusContainerNodes where isValidNode (getAnimByHandle handle) collect handle
    local containers=for handle in CyrusContainerNodes collect (getAnimByHandle handle),models=#()
    for controller in CyrusTimeOwners where isValidNode controller do (
        local root=controller.baseObject
        if root.layerID=="" do undo off root.layerID=CyrusNewLayerID()
        for node in root.containerGlobalNodes where isValidNode node do appendIfUnique containers node
        for leaf in root.layerObjects do (
            for node in leaf.containerNodes where isValidNode node do appendIfUnique containers node
            if leaf.containerProvider()!=undefined do for node in leaf.sources where isValidNode node do appendIfUnique models node
        )
    )
    -- Movement ownership is independent of usage. Keep a valid prior owner;
    -- unique admission assigns ownership, overlaps remain explicitly unresolved.
    local usedContainers=for node in containers where (CyrusContainerConsumers node).count>0 collect node
    for model in models do (
        local prior=#(),inside=#()
        for node in usedContainers do (
            local view=node.baseObject
            if findItem view.movementSources model>0 do append prior node
            if CyrusContainerInside model node do append inside node
        )
        local valid=for node in prior where findItem inside node>0 collect node
        local chosen=if valid.count==1 then valid[1] else if valid.count==0 and inside.count==1 then inside[1] else undefined
        for node in containers do (
            local values=node.baseObject.movementSources as array,index=findItem values model
            if node==chosen then (
                if index==0 do undo off append node.baseObject.movementSources model
            ) else if chosen!=undefined and index>0 do undo off deleteItem node.baseObject.movementSources index
        )
    )
    for node in containers do (
        local view=node.baseObject,consumers=CyrusContainerConsumers node,links=CyrusContainerLinks node,labels=#(),rows=#(),saved=#(),active=#(),conflicts=#()
        for row in links do (
            append rows #((getHandleByAnim row[1]),row[2].layerID,if row[3]==undefined then "" else row[3].layerID)
            append labels (row[1].name+" | "+(if row[3]==undefined then "Global pool" else row[2].setCaption row[3]))
        )
        for row in consumers do (
            for model in row[3].sources where isValidNode model do (
                local inside=CyrusContainerInside model node
                if inside do (appendIfUnique active model;appendIfUnique saved model)
                if findItem view.savedSources model>0 do appendIfUnique saved model
                if inside and (for other in containers where findItem other.baseObject.movementSources model>0 collect other).count==0 do appendIfUnique conflicts model
            )
        )
        view.consumerRows=rows;view.consumerLabels=labels
        if (CyrusContainerResolve view)==undefined and rows.count>0 do undo off (view.contextRootID=rows[1][2];view.contextSetID=rows[1][3])
        local same=saved.count==view.savedSources.count
        if same do for i=1 to saved.count where saved[i]!=view.savedSources[i] do same=false
        if not same do undo off view.savedSources=saved
        local units=#(),failure=""
        for model in view.movementSources where isValidNode model do (
            if CyrusContainerInside model node do (
            local unit=model,parent=model.parent
            if isGroupMember model do while isValidNode parent and isGroupHead parent do (unit=parent;parent=parent.parent)
            if not isGroupMember model do (
                local ancestor=model.parent
                while isValidNode ancestor and findItem view.movementSources ancestor>0 do (unit=ancestor;ancestor=ancestor.parent)
            )
            local tree=#(unit),index=1,complete=true
            while index<=tree.count and tree.count<=1024 do (
                local member=tree[index];index+=1
                if not cyrusContainerMovable member do complete=false
                if not isGroupHead member and findItem view.movementSources member==0 do complete=false
                if superclassof member==GeometryClass and not isGroupHead member do (
                    if not CyrusContainerInside member node do complete=false
                )
                if classof member.baseObject==CyrusSourceContainer or classof member.baseObject==AminScatterObject do complete=false
                for child in member.children do appendIfUnique tree child
            )
            if tree.count>1024 do complete=false
            local ancestor=unit.parent,depth=0
            while isValidNode ancestor and depth<64 do (if not cyrusContainerMovable ancestor do complete=false;ancestor=ancestor.parent;depth+=1)
            if depth>=64 do complete=false
            if complete then appendIfUnique units unit else failure="Some sources cannot follow: partial hierarchy, locked or animated/constrained transform."
            )
        )
        view.movementUnits=if consumers.count==0 then #() else units
        local previous=view.movementStatus
        view.movementStatus=if conflicts.count>0 then (conflicts.count as string)+" overlapping sources need an owner." else if failure!="" then failure else "Translation follows active static models. Resize changes membership."
        if previous!=view.movementStatus do CyrusDiagnosticEmit "container.ownership" "source_container" view.containerID 0 view.movementStatus
        view.cachedActiveCount=active.count;view.cachedSavedCount=saved.count;view.cachedConsumerCount=consumers.count
    )
    CyrusContainerRefreshLabels undefined
    true
)
fn CyrusContainerSceneOpened = (
    CyrusContainerNodes=for node in helpers where classof node.baseObject==CyrusSourceContainer collect (getHandleByAnim node)
    CyrusContainerRefreshAll()
)
callbacks.removeScripts id:#CyrusSourceContainers
callbacks.addScript #filePostOpen "CyrusContainerSceneOpened()" id:#CyrusSourceContainers persistent:false

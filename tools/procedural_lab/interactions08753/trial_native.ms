-- Final trial persistence outside the Python bridge. Only this run's new copies.
global TNJSON,TNObject,TNSnapshot,WFOwner,WFRoot,WFGrass,WFCollider,WFEdit
fn TNObject pairs = #(#trialObject,pairs)
fn TNJSON value = (
    if classof value==Array then (
        if value.count==2 and value[1]==#trialObject then (
            local text="{",first=true
            for pair in value[2] do (if not first do text+=",";first=false;text+=(TNJSON pair[1])+":"+(TNJSON pair[2]))
            text+"}"
        ) else (
            local text="[",first=true
            for item in value do (if not first do text+=",";first=false;text+=TNJSON item)
            text+"]"
        )
    ) else if value==undefined then "null"
    else if classof value==String then (
        local text=substituteString value "\\" "\\\\"
        text=substituteString text "\"" "\\\"";text=substituteString text "\r" "\\r";text=substituteString text "\n" "\\n"
        "\""+text+"\""
    ) else if classof value==BooleanClass then (if value then "true" else "false")
    else value as string
)
fn TNSnapshot = (
    local groups=cyrusPlacementTransformGroups (cyrusInteractionRows WFRoot.interactionState 2),tm=groups[1][1]
    local sourceScale=(WFCollider.validSources())[1].scale,position=tm.row4
    TNObject #(
        #("amounts",for leaf in WFRoot.layerObjects collect leaf.amount),
        #("source_ids",for leaf in WFRoot.layerObjects collect (for id in leaf.sourceRowIDs collect id)),
        #("node_scale",#(sourceScale.x,sourceScale.y,sourceScale.z)),
        #("model_scale",WFCollider.sourceScale 1),#("axis",length tm.row1),
        #("position",#(position.x,position.y,position.z)),#("navigation",WFRoot.viewportNavigationFaces),
        #("idle",WFRoot.viewportFaces),#("hide_area",WFGrass.interactionHideArea),
        #("error",WFRoot.interactionError),#("layer_errors",for leaf in WFRoot.layerObjects collect leaf.previewError)
    )
)
(
    if not matchPattern GardenRun pattern:"*/build/interactions08753-20261028-01/host-*/" do throw "Owned trial host required."
    if theHold.Holding() or theHold.IsSuspended() do throw "Native trial fixture found an unexpected authored hold."
    local broad=matchPattern CVProfileCase pattern:"*-broad"
    local folder=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Interaction 0.87.5.3\"
    local file=folder+(if broad then "Broad_Stone_Stress_0.87.5.3.max" else "New_Plants_22_0.87.5.3.max")
    local previousBusy=CyrusPointBusy,previousSuspended=CyrusPointSuspended,failure=""
    local result=#(#("phase",CVProfileCase),#("holding_before",theHold.Holding()),#("scene",file))
    try (
        if matchPattern CVProfileCase pattern:"trial-native-load-*" then (
            CyrusPointBusy=true;CyrusPointSuspended=true
            if not loadMaxFile file quiet:true useFileUnits:true missingDLLsAction:#logmsg do throw "Cannot load this run's trial copy."
            ColorPipelineMgr.Mode=#OCIO_Default
            WFOwner=undefined
            for node in objects where classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined do WFOwner=node
            if not isValidNode WFOwner do throw "No root in owned trial."
            WFRoot=WFOwner.baseObject;WFGrass=WFRoot.layerObjects[1];WFCollider=WFRoot.layerObjects[2]
            WFEdit=undefined
            for modifier in WFOwner.modifiers where classof modifier==CyrusScatterEdit do WFEdit=modifier
            CyrusPointBusy=previousBusy;CyrusPointSuspended=previousSuspended
            WFRoot.interactionsEnsure();CyrusPointSync()
        ) else if matchPattern CVProfileCase pattern:"trial-native-save-*" then (
            if not doesFileExist file do throw "Only an existing run-owned trial may be refreshed."
            if not saveMaxFile file quiet:true do throw "Cannot save owned trial."
        ) else throw "Unknown trial phase."
        if WFRoot.interactionError!="" do throw WFRoot.interactionError
        for leaf in WFRoot.layerObjects where leaf.previewError!="" do throw leaf.previewError
        if WFGrass.amount!=1000 or WFCollider.amount!=1 or WFRoot.viewportNavigationFaces!=500000 or WFRoot.viewportFaces!=0 or WFGrass.interactionHideArea!=2 do throw "Trial configuration differs."
        if theHold.Holding() or theHold.IsSuspended() do throw "A native trial operation leaked an authored hold."
        append result #("snapshot",TNSnapshot());append result #("status","pass")
    )catch(failure=getCurrentException();append result #("status","failed");append result #("error",failure);append result #("stack",getCurrentExceptionStackTrace()))
    CyrusPointBusy=previousBusy;CyrusPointSuspended=previousSuspended
    append result #("holding_after",theHold.Holding());append result #("suspended_after",theHold.IsSuspended())
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+CVProfileCase+".json") (TNJSON (TNObject result))
    if failure!="" do throw failure
)

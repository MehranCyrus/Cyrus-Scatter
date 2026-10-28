-- Owned Max 2027 installed-catalog regression. No artist-profile install,
-- material changes, scene reset/save, history clearing or unexpected hold repair.
-- Dispatch library-native-add, let the callback/timers return, then dispatch
-- library-native-observe. Both phases are pure MAXScript.
global LNBefore,LNAfter,LNModel,LNCatalog,LNEntry,LNMissing,LNOutcome,LNMergeError,LNOwner,LNRoot,LNVerified
global LNPath,LNGuard,LNObject,LNJSON,LNWrite,LNSnapshot,LNGet,LNViews,LNHash

fn LNPath value = (toLower (substituteString ((dotNetClass "System.IO.Path").GetFullPath value) "\\" "/"))
fn LNGuard = (
    local path=trimRight (LNPath GardenRun) "/",fixture=trimRight (LNPath MCPFixtureDir) "/"
    if path!=fixture or not matchPattern (path+"/") pattern:"f:/cursor/_cyrus_apps/cyrusscatter/build/interactions08753-20261028-01/host-*/" do throw "An owned scene-repair fixture host is required."
    if not doesFileExist (pathConfig.appendPath path "launch.json") or not doesFileExist (pathConfig.appendPath path "ready.json") do throw "The owned fixture launch/ready receipts are missing."
    if ((maxVersion())[1]/1000+1998)!=2027 do throw "This regression is scoped to Max 2027."
    if not isValidNode WFOwner or WFOwner.baseObject!=WFRoot or findItem (WFRoot.layerObjects as array) WFCollider==0 do throw "The small fixture's controller/layer identity differs."
    if WFCollider.interactionCollider or WFCollider.interactionReact or WFCollider.containerProvider()!=undefined do throw "Use the existing role-Off layer with explicit source rows."
    if WFRoot.layerObjects.count>8 or WFCollider.sources.count>16 or WFCollider.amount>16 do throw "Use the bounded small source fixture."
    if theHold.Holding() or theHold.IsSuspended() do throw "The test found an active/suspended hold and did not accept, cancel or resume it."
    path
)
fn LNObject pairs = #(#libraryNativeObject,pairs)
fn LNJSON value = (
    if classof value==Array then (
        if value.count==2 and classof value[1]==Name and value[1]==#libraryNativeObject then (
            local text="{",first=true
            for pair in value[2] do (if not first do text+=",";first=false;text+=(LNJSON (pair[1] as string))+":"+(LNJSON pair[2]))
            text+"}"
        ) else (
            local text="[",first=true
            for item in value do (if not first do text+=",";first=false;text+=LNJSON item)
            text+"]"
        )
    ) else if value==undefined then "null"
    else if classof value==String then (
        local text=substituteString value "\\" "\\\\"
        text=substituteString text "\"" "\\\"";text=substituteString text "\r" "\\r";text=substituteString text "\n" "\\n";text=substituteString text "\t" "\\t"
        "\""+text+"\""
    ) else if classof value==BooleanClass then (if value then "true" else "false")
    else value as string
)
fn LNWrite pairs directory = (
    local folder=pathConfig.appendPath directory "library-native-history"
    makeDir folder
    local document=LNJSON (LNObject pairs),identity=((dotNetClass "System.Guid").NewGuid()).ToString "N"
    (dotNetClass "System.IO.File").WriteAllText (pathConfig.appendPath folder (CVProfileCase+"-"+identity+".json")) document
    (dotNetClass "System.IO.File").WriteAllText (pathConfig.appendPath directory (CVProfileCase+".json")) document
)
fn LNHash text = (
    local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create(),result=""
    try (
        local bytes=(dotNetClass "System.Text.Encoding").UTF8.GetBytes text
        result=toLower (substituteString ((dotNetClass "System.BitConverter").ToString (sha.ComputeHash bytes)) "-" "")
        sha.Dispose()
    )catch(sha.Dispose();throw())
    result
)
fn LNSnapshot = (
    if WFCollider.interactionDefinitions.count>16 or WFCollider.interactionProxyNodes.count>16 do throw "The Library regression's retained source bindings exceed the small fixture."
    #(
        #("ids",for value in WFCollider.sourceRowIDs collect value),
        #("nodes",for node in WFCollider.sources collect (if isValidNode node then node.handle else 0)),
        #("names",for node in WFCollider.sources collect (if isValidNode node then node.name else "<missing>")),
        #("point",for value in WFCollider.sourcePoint collect value),#("empty",for value in WFCollider.sourceEmpty collect value),
        #("roles",#(WFCollider.interactionCollider,WFCollider.interactionReact)),
        #("definition_ids",for value in WFCollider.interactionSourceIDs collect value),
        #("definition_sha256",for value in WFCollider.interactionDefinitions collect LNHash value),
        #("proxy_ids",for value in WFCollider.interactionProxySourceIDs collect value),
        #("proxy_nodes",for node in WFCollider.interactionProxyNodes collect (if isValidNode node then node.handle else 0)),
        #("collider_mode",WFCollider.interactionColliderMode),#("definition_revision",WFCollider.interactionDefinitionRevision)
    )
)
fn LNGet pairs key = (
    for pair in pairs where pair[1]==key do return pair[2]
    throw "The Library regression snapshot is incomplete."
)
fn LNViews enforce:false = (
    local models=WFRoot.modelsUI,interactions=WFRoot.interactionsUI,ids=for value in WFCollider.sourceRowIDs collect value
    local interactionIDs=for value in interactions.interactionsUI_modelIDs collect value
    local modelItems=for value in models.sourceUI_plantList.items collect value,interactionItems=for value in interactions.interactionsUI_modelList.items collect value
    if enforce do (
        if not models.controlsReady or not interactions.controlsReady do throw "The bound source views are not ready after the deferred Library callback."
        if not CyrusPresetSameValues ids interactionIDs or modelItems.count!=ids.count or interactionItems.count!=ids.count do throw "The Library add did not automatically synchronize both authored source views."
    )
    LNObject #(#("ids",ids),#("interaction_ids",interactionIDs),#("models",modelItems),#("interactions",interactionItems))
)

(
    local directory=LNGuard(),failure="",status="running",beforeObjects=objects.count
    local report=#(#("phase",CVProfileCase),#("host",2027),#("version",WFRoot.uiVersion()),#("holding_before",theHold.Holding()),#("suspended_before",theHold.IsSuspended()))
    try (
        if cyrusSourceCommandUndoVersion()!=1 do throw "Use the matched installed source Undo module."
        if CVProfileCase=="library-native-add" then (
            LNOwner=WFCollider;LNRoot=WFRoot;LNBefore=LNSnapshot();LNAfter=undefined;LNModel=undefined;LNOutcome="running";LNMergeError="";LNMissing=#();LNVerified=false
            append report #("before",LNObject LNBefore)
            local galleryPath=pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll"
            local runRoot=LNPath ((dotNetClass "System.IO.Path").GetDirectoryName directory)
            if not matchPattern (LNPath galleryPath) pattern:(runRoot+"/installer-*/runtime/r/*/cyrusgallery.dll") do throw "Load the managed Gallery from this owned profile's matched installed payload."
            local assembly=dotNet.loadAssembly galleryPath
            if assembly==undefined or (assembly.GetName()).Version.ToString()!=WFRoot.uiVersion() or LNPath assembly.Location!=LNPath galleryPath do throw "The installed managed Gallery identity differs from the current Scatter pair."
            LNCatalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
            LNCatalog.Load @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library" "0.86.7" 2027
            LNEntry=LNCatalog.MatchingAt "A027" "" 0
            if LNEntry.Id!="A027" do throw "The catalog returned a different source entry."
            local names=getMAXFileObjectNames LNEntry.Scene quiet:true missingDLLsAction:#logmsg missingDLLsList:&LNMissing
            if LNMissing==undefined do LNMissing=#()
            append report #("catalog",LNObject #(#("id",LNEntry.Id),#("name",LNEntry.Name),#("source_revision","0.86.7"),#("scene",LNEntry.Scene),#("scene_sha256",LNEntry.SceneHash),#("entry_count",LNCatalog.Count),#("header_objects",names)))
            append report #("managed",LNObject #(#("path",assembly.Location),#("version",(assembly.GetName()).Version.ToString())))
            try(LNModel=CyrusModelMerge LNCatalog LNEntry owner:WFCollider;LNOutcome="merged")
            catch(LNMergeError=getCurrentException();LNOutcome=if matchPattern LNMergeError pattern:"*unavailable material*plug-ins*" or matchPattern LNMergeError pattern:"*Missing_*" then "blocked_dependency" else "failed")
            LNAfter=LNSnapshot()
            append report #("after",LNObject LNAfter)
            append report #("missing_header_dependencies",for value in LNMissing collect (value as string))
            append report #("views_immediate",LNViews());append report #("outcome",LNOutcome)
            if LNOutcome!="merged" then (
                local retained=CyrusPresetSameValues LNBefore LNAfter and objects.count==beforeObjects
                append report #("rollback_preserved_sources_and_scene_count",retained);append report #("merge_error",LNMergeError)
                if not retained do throw "The rejected Library model did not restore source rows or scene-node count."
                status=LNOutcome;throw LNMergeError
            ) else (
                local oldIDs=LNGet LNBefore "ids",newIDs=LNGet LNAfter "ids",oldNodes=LNGet LNBefore "nodes",newNodes=LNGet LNAfter "nodes"
                if not isValidNode LNModel or newIDs.count!=oldIDs.count+1 or newNodes[newNodes.count]!=LNModel.handle or findItem oldIDs newIDs[newIDs.count]>0 do throw "The installed model was not enrolled exactly once with a fresh source-row identity."
                for row=1 to oldIDs.count where oldIDs[row]!=newIDs[row] or oldNodes[row]!=newNodes[row] do throw "The Library add changed an existing source row."
                for key in #("roles","definition_ids","definition_sha256","proxy_ids","proxy_nodes","collider_mode","definition_revision") do if not CyrusPresetSameValues (LNGet LNBefore key) (LNGet LNAfter key) do throw ("The Library add changed unrelated source interaction data: "+key)
                if not LNModel.isHidden or LNModel.renderable do throw "A source added from the Library must remain hidden and non-renderable as a source object."
                append report #("model",LNObject #(#("handle",LNModel.handle),#("name",LNModel.name),#("material_class",if LNModel.material==undefined then "undefined" else ((classof LNModel.material) as string)),#("hidden",LNModel.isHidden),#("renderable",LNModel.renderable)))
                LNVerified=true;status="pass"
            )
        ) else if CVProfileCase=="library-native-observe" then (
            if LNOwner!=WFCollider or LNRoot!=WFRoot or LNBefore==undefined or LNAfter==undefined do throw "Run library-native-add in this same owned controller first."
            append report #("outcome",LNOutcome);append report #("missing_header_dependencies",for value in LNMissing collect (value as string))
            local current=LNSnapshot()
            append report #("before",LNObject LNBefore);append report #("current",LNObject current)
            if not CyrusPresetSameValues current LNAfter do throw "The source membership changed between Library add and deferred observation."
            append report #("views",LNViews enforce:true)
            if LNOutcome!="merged" do (status=LNOutcome;throw LNMergeError)
            if not LNVerified do throw "The immediate Library add assertions did not pass. Preserve that failed receipt."
            if not isValidNode LNModel or WFCollider.sources[WFCollider.sources.count]!=LNModel do throw "The deferred source view lost the newly merged model."
            status="pass"
        ) else throw "Unknown Library native regression phase."
    )catch(failure=getCurrentException();if status=="running" do status="failed";append report #("error",failure);append report #("stack",getCurrentExceptionStackTrace()))
    append report #("status",status);append report #("objects_before",beforeObjects);append report #("objects_after",objects.count)
    append report #("holding_after",theHold.Holding());append report #("suspended_after",theHold.IsSuspended())
    append report #("undo",for value in (theHold.getUndoNames()) collect (value as string));append report #("redo",for value in (theHold.getRedoNames()) collect (value as string))
    LNWrite report directory
    if failure!="" do throw failure
)

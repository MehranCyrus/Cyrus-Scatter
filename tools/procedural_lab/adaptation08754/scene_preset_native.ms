-- Test-only standard Scene preset round trip in a disposable Max 2027 host.
-- Four phases: save; poll publication/start PrepareScene; ready; merge.
-- Workers are polled by separate host events. No Python, hold acceptance,
-- material replacement, scene reset or artist-file save occurs here.
global SPNRoot,SPNOriginal,SPNJob,SPNStore,SPNEntry,SPNExpected,SPNLoad,SPNImported,SPNActive
global SPNOldOverride,SPNOldStore,SPNRootCount,SPNMetadata
global SPNPath,SPNGuard,SPNObject,SPNJSON,SPNWrite,SPNHash,SPNMatrix,SPNVector,SPNOwners,SPNSnapshot,SPNGet,SPNRestoreStore,SPNDisjoint

fn SPNPath value = (toLower (substituteString ((dotNetClass "System.IO.Path").GetFullPath value) "\\" "/"))
fn SPNGuard = (
    local path=trimRight (SPNPath GardenRun) "/",fixture=trimRight (SPNPath MCPFixtureDir) "/"
    if path!=fixture or not matchPattern (path+"/") pattern:"f:/cursor/_cyrus_apps/cyrusscatter/build/adaptation08754-20261028-01/host-*/" do throw "An owned scene-repair fixture host is required."
    if not doesFileExist (pathConfig.appendPath path "launch.json") or not doesFileExist (pathConfig.appendPath path "ready.json") do throw "Owned host receipts are missing."
    if ((maxVersion())[1]/1000+1998)!=2027 or WFRoot.uiVersion()!="0.87.5.4" do throw "Use the matched 0.87.5.4 Max 2027 fixture."
    if not isValidNode WFOwner or WFOwner.baseObject!=WFRoot do throw "The original fixture owner changed."
    if theHold.Holding() or theHold.IsSuspended() do throw "Finish the current hold first. This harness does not accept, cancel or resume unrelated holds."
    path
)
fn SPNObject pairs = #(#sceneNativeObject,pairs)
fn SPNJSON value = (
    if classof value==Array then (
        if value.count==2 and classof value[1]==Name and value[1]==#sceneNativeObject then (
            local text="{",first=true
            for pair in value[2] do (if not first do text+=",";first=false;text+=(SPNJSON (pair[1] as string))+":"+(SPNJSON pair[2]))
            text+"}"
        ) else (
            local text="[",first=true
            for item in value do (if not first do text+=",";first=false;text+=SPNJSON item)
            text+"]"
        )
    ) else if value==undefined then "null"
    else if classof value==String then (
        local text=substituteString value "\\" "\\\\"
        text=substituteString text "\"" "\\\"";text=substituteString text "\r" "\\r";text=substituteString text "\n" "\\n";text=substituteString text "\t" "\\t"
        "\""+text+"\""
    ) else if classof value==BooleanClass then (if value then "true" else "false")
    else if classof value==Integer64 then trimRight (value as string) "L"
    else value as string
)
fn SPNWrite pairs directory = (
    local folder=pathConfig.appendPath directory "scene-native-history"
    makeDir folder
    local document=SPNJSON (SPNObject pairs),identity=((dotNetClass "System.Guid").NewGuid()).ToString "N"
    (dotNetClass "System.IO.File").WriteAllText (pathConfig.appendPath folder (CVProfileCase+"-"+identity+".json")) document
    (dotNetClass "System.IO.File").WriteAllText (pathConfig.appendPath directory (CVProfileCase+".json")) document
)
fn SPNHash text = (
    local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create(),result=""
    try(result=toLower (substituteString ((dotNetClass "System.BitConverter").ToString (sha.ComputeHash ((dotNetClass "System.Text.Encoding").UTF8.GetBytes text))) "-" "");sha.Dispose())catch(sha.Dispose();throw())
    result
)
fn SPNVector point = #(point.x,point.y,point.z)
fn SPNMatrix transform = (for row=1 to 4 collect SPNVector transform[row])
fn SPNOwners root = (
    if root.layerObjects.count>8 do throw "Use the small Scene preset fixture (at most eight published layers)."
    local owners=#(root)
    for owner in root.layerObjects do appendIfUnique owners owner
    for owner in (owners as array) do for area in owner.paintAreas do appendIfUnique owners area
    if owners.count>24 do throw "The Scene preset fixture exceeds 24 authored owners."
    owners
)
fn SPNGet pairs key = (
    for pair in pairs where pair[1]==key do return pair[2]
    throw "The Scene preset snapshot is incomplete."
)
fn SPNSnapshot root = (
    local ownerNode=CyrusRecipeOwnerNode root,owners=SPNOwners root,total=0
    for rows in root.groupSnapshotRows do total+=rows.count
    if total>256 do throw "Use the small prepared fixture: this regression snapshots at most 256 published placements."
    local comparable=#(),identities=#(),handles=#()
    for owner in owners do (
        if owner.sources.count>16 or owner.interactionDefinitions.count>16 or owner.interactionProxyNodes.count>16 do throw "The Scene preset fixture exceeds 16 sources/definitions/proxies per owner."
        local inputs=for node in owner.sources collect (if isValidNode node then node else 0)
        local geometry=cyrusSourceGeometryInfo inputs
        local proxyInputs=for node in owner.interactionProxyNodes collect (if isValidNode node then node else 0),proxyGeometry=cyrusSourceGeometryInfo proxyInputs
        local shape=for value in geometry collect #(value[1],value[3],SPNVector value[4],SPNVector value[5])
        local proxyShape=for value in proxyGeometry collect #(value[1],value[3],SPNVector value[4],SPNVector value[5])
        local transforms=for node in owner.sources collect (if isValidNode node then SPNMatrix node.transform else undefined)
        local proxyTransforms=for node in owner.interactionProxyNodes collect (if isValidNode node then SPNMatrix node.transform else undefined)
        append comparable #(
            #("geometry",shape),#("source_transforms",transforms),#("proxy_geometry",proxyShape),#("proxy_transforms",proxyTransforms),
            #("preparation_sha256",for value in owner.interactionDefinitions collect SPNHash value),
            #("preparation_rows",for id in owner.interactionSourceIDs collect (findItem (owner.sourceRowIDs as array) id)),
            #("proxy_rows",for id in owner.interactionProxySourceIDs collect (findItem (owner.sourceRowIDs as array) id)),
            #("points",for value in owner.sourcePoint collect value),#("empty",for value in owner.sourceEmpty collect value),
            #("scales",for value in owner.sourceScales collect value),#("offsets",for value in owner.sourceZOffsetsWU collect value),
            #("weights",for value in owner.sourceWeights collect value),#("roles",#(owner.interactionCollider,owner.interactionReact)),
            #("scene_collider_transforms",for collider in owner.interactionSceneColliders where isValidNode collider collect SPNMatrix collider.transform),#("response",#(owner.interactionResponse,owner.interactionBendStrength,owner.interactionPruneAmount,owner.interactionPruneThresholdWU,owner.interactionNeighbors)),#("collider_mode",owner.interactionColliderMode),#("amount",owner.amount),#("seed",owner.randomSeed)
        )
        append identities #(#("owner",owner.layerID),#("source_rows",for value in owner.sourceRowIDs collect value),#("registered_sources",for value in owner.procSourceIDs collect value),#("prepared_sources",for value in owner.interactionSourceIDs collect value),#("proxy_sources",for value in owner.interactionProxySourceIDs collect value))
        append handles #(#("sources",for node in owner.sources collect (if isValidNode node then node.handle else 0)),#("proxies",for node in owner.interactionProxyNodes collect (if isValidNode node then node.handle else 0)))
    )
    -- CyrusPlacementTransforms deliberately exposes only count and indexed
    -- reads; it is not a MAXScript-mappable collection. Detach only this small
    -- fixture's already admitted matrices, never map the opaque native view.
    local rows=#(),detached=0
    for layer=1 to root.groupSnapshotRows.count do (
        local groups=cyrusPlacementTransformGroups root.groupSnapshotRows[layer],layerRows=#()
        if groups.count>32 do throw "The small Scene preset fixture exceeds 32 source transform groups."
        for source=1 to groups.count do (
            local group=groups[source],matrices=#()
            if detached+group.count>256 do throw "The Scene preset matrix readback exceeds its 256-placement bound."
            for row=1 to group.count do append matrices (SPNMatrix group[row])
            detached+=group.count;append layerRows matrices
        )
        append rows layerRows
    )
    if detached!=total do throw "The native transform groups differ from their published placement counts."
    #(#("root_handle",ownerNode.handle),#("identities",identities),#("handles",handles),#("comparable",comparable),#("placements",rows),#("placement_count",total))
)
fn SPNRestoreStore = (
    if SPNActive==true do (CyrusSharedLibraryRootOverride=SPNOldOverride;CyrusSharedLibraryInstance=SPNOldStore;SPNActive=false)
)
fn SPNDisjoint original imported = (
    local oldOwners=#(),newOwners=#(),oldSources=#(),newSources=#()
    for owner in (SPNGet original "identities") do (
        append oldOwners (SPNGet owner "owner")
        for key in #("source_rows","registered_sources") do for id in (SPNGet owner key) do appendIfUnique oldSources id
    )
    for owner in (SPNGet imported "identities") do (
        append newOwners (SPNGet owner "owner")
        for key in #("source_rows","registered_sources") do for id in (SPNGet owner key) do appendIfUnique newSources id
    )
    -- A fresh controller's unused legacy layer ID is empty, not an identity.
    for id in newOwners where id!="" and findItem oldOwners id>0 do throw "The imported Scene preset reused an original owner identity."
    for id in newSources where findItem oldSources id>0 do throw "The imported Scene preset reused an original authored or registered source identity."
    true
)

(
    local directory=SPNGuard(),failure="",status="running",state="",report=#(#("phase",CVProfileCase),#("version","0.87.5.4"),#("host",2027),#("holding_before",theHold.Holding()))
    try (
        if CVProfileCase=="scene-native-save" then (
            if SPNActive==true do throw "This harness already owns an unfinished Scene preset operation. Poll it or cancel that owned job first."
            if CyrusSharedSaveJobs.count>0 do throw "Wait for existing Library save operations; this smoke does not cancel them."
            SPNRoot=WFRoot
            if SPNRoot.groupSnapshotKey=="" do throw "Publish the small prepared setup before this test; the harness does not change its settings."
            local nodes=CyrusScenePresetNodes SPNRoot
            if nodes.count>128 do throw "Use the bounded small fixture: at most 128 nodes in its Scene preset dependency closure."
            SPNOriginal=SPNSnapshot SPNRoot
            SPNOldOverride=CyrusSharedLibraryRootOverride;SPNOldStore=CyrusSharedLibraryInstance
            local storeRoot=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\ad8754lib"
            if storeRoot.count>80 do throw "The owned test library path exceeds the supported short-root bound."
            CyrusSharedLibraryRootOverride=storeRoot;CyrusSharedLibraryInstance=undefined;SPNActive=true
            SPNEntry="";SPNExpected="";SPNLoad=undefined;SPNImported=undefined;SPNJob=undefined;SPNStore=CyrusSharedStore()
            local title="Source repair 0.87.5.4 "+(((dotNetClass "System.Guid").NewGuid()).ToString "N")
            SPNJob=CyrusScenePresetSave SPNRoot title (CyrusRecipeObject #(#("category","Owned regression"),#("tags",#("0.87.5.4","native scene preset")),#("description","Unmodified materials; small prepared source round trip"))) ""
            state="saving";status="pass"
            append report #("store",SPNStore.Root);append report #("dependency_nodes",nodes.count);append report #("original",SPNObject SPNOriginal)
            local prepared=0,proxies=0,points=0,empty=0
            for owner in (SPNOwners SPNRoot) do (
                prepared+=owner.interactionDefinitions.count;proxies+=owner.interactionProxyNodes.count
                for row=1 to owner.sources.count do (if owner.isPointSource row then points+=1 else if owner.isEmptySource row do empty+=1)
            )
            append report #("fixture_coverage",SPNObject #(#("prepared_sources",prepared),#("proxy_bindings",proxies),#("point_rows",points),#("empty_rows",empty)))
            append report #("scene_filename",maxFilePath+maxFileName)
        ) else if CVProfileCase=="scene-native-poll" then (
            if SPNActive!=true or SPNJob==undefined do throw "Start this owned Scene preset save first."
            local saved=CyrusSharedPollSave SPNJob
            append report #("save_state",saved)
            if saved=="working" then state="saving"
            else (
                if saved!="complete" do throw SPNJob.error
                if not CyrusPresetSameValues (SPNSnapshot SPNRoot) SPNOriginal do throw "Saving a Scene preset changed the original authored/prepared/published setup."
                SPNEntry=SPNJob.result;SPNExpected=(cyrusRecipeInfo SPNEntry)[11];SPNMetadata=cyrusRecipeReadMetadata SPNEntry
                if (CyrusRecipeGet SPNMetadata "format")!="cyrus.scene-preset" or (CyrusRecipeGet SPNMetadata "scatterVersion")!="0.87.5.4" or (CyrusRecipeGet SPNMetadata "maxYear")!=2027 do throw "The saved Scene preset metadata has the wrong format/version/host."
                if SPNLoad==undefined do SPNLoad=SPNStore.PrepareScene SPNEntry SPNExpected
                state="preparing";append report #("entry",SPNEntry);append report #("expected_sha256",SPNExpected)
                append report #("metadata",SPNObject #(#("format",CyrusRecipeGet SPNMetadata "format"),#("scatter_version",CyrusRecipeGet SPNMetadata "scatterVersion"),#("max_year",CyrusRecipeGet SPNMetadata "maxYear"),#("nodes",CyrusRecipeGet SPNMetadata "nodeCount")))
                append report #("original_retained",true)
            )
            status="pass"
        ) else if CVProfileCase=="scene-native-ready" then (
            if SPNActive!=true or SPNLoad==undefined do throw "Poll the successful save and begin PrepareScene first."
            if not SPNLoad.Terminal then state="preparing"
            else (
                if SPNLoad.State!="complete" do throw SPNLoad.Error
                local missing=#(),names=getMAXFileObjectNames SPNLoad.Result quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
                if missing==undefined do missing=#()
                append report #("staged",SPNLoad.Result);append report #("staged_node_count",names.count);append report #("header_dependencies",for value in missing collect (value as string))
                if names.count!=(CyrusRecipeGet SPNMetadata "nodeCount") do throw "The prepared Scene preset has a different node count."
                state="ready"
            )
            status="pass"
        ) else if CVProfileCase=="scene-native-merge" then (
            if SPNActive!=true or SPNLoad==undefined or not SPNLoad.Terminal or SPNLoad.State!="complete" do throw "PrepareScene must finish before the merge event."
            if not CyrusPresetSameValues (SPNSnapshot SPNRoot) SPNOriginal do throw "The original setup changed while the preset was being prepared."
            local roots=for node in objects where isValidNode node and classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined collect node
            SPNRootCount=roots.count
            append report #("standard_merge_clears_undo_history",true)
            SPNImported=CyrusScenePresetMerge SPNEntry SPNExpected SPNLoad.Result
            local imported=SPNSnapshot SPNImported.baseObject,current=SPNSnapshot SPNRoot
            if (for node in objects where isValidNode node and classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined collect node).count!=SPNRootCount+1 do throw "Standard merge did not add exactly one independent Scatter root."
            if findItem roots SPNImported>0 or not CyrusPresetSameValues current SPNOriginal do throw "The standard merge changed the original setup."
            if not CyrusPresetSameValues (SPNGet imported "placements") (SPNGet SPNOriginal "placements") do throw "The imported setup's published instance transforms differ."
            if not CyrusPresetSameValues (SPNGet imported "comparable") (SPNGet SPNOriginal "comparable") do throw "The imported geometry, source/proxy transforms, flags or preparation hashes differ."
            SPNDisjoint SPNOriginal imported
            for collider in SPNImported.baseObject.interactionSceneColliders where findItem (SPNRoot.interactionSceneColliders as array) collider>0 do throw "The imported setup reused an original scene collider node."
            if SPNImported.baseObject.interactionError!="" do throw SPNImported.baseObject.interactionError
            for leaf in SPNImported.baseObject.layerObjects where leaf.previewError!="" do throw leaf.previewError
            SPNStore.DiscardSceneLoad SPNLoad.Result
            append report #("original",SPNObject current);append report #("imported",SPNObject imported)
            append report #("independent_import",true);append report #("independent_scene_colliders",true);append report #("placements_preserved",true);append report #("geometry_and_preparation_preserved",true);append report #("original_retained",true)
            append report #("geometry_scope","Native face-referenced position/topology fingerprint and pivot-local bounds; no rendered-material/UV/normal qualification.")
            state="complete";status="pass";SPNRestoreStore()
        ) else if CVProfileCase=="scene-native-cancel" then (
            if SPNActive==true do (
                if SPNJob!=undefined and SPNJob.state=="working" do CyrusSharedCancelSave SPNJob
                if SPNLoad!=undefined do SPNStore.CancelSceneLoad SPNLoad
                SPNRestoreStore()
            )
            state="cancelled";status="pass"
        ) else throw "Unknown native Scene preset phase."
    )catch(
        failure=getCurrentException();status=if matchPattern failure pattern:"*plug-in*unavailable*" or matchPattern failure pattern:"*Missing asset:*" or matchPattern failure pattern:"*unavailable material*" then "blocked_dependency" else "failed"
        append report #("error",failure);append report #("stack",getCurrentExceptionStackTrace())
        if SPNActive==true do (
            if SPNJob!=undefined and SPNJob.state=="working" do try(CyrusSharedCancelSave SPNJob)catch()
            if SPNLoad!=undefined do try(SPNStore.CancelSceneLoad SPNLoad)catch()
            try(append report #("original_retained",CyrusPresetSameValues (SPNSnapshot SPNRoot) SPNOriginal))catch()
            SPNRestoreStore()
        )
    )
    append report #("status",status);append report #("state",state);append report #("holding_after",theHold.Holding());append report #("suspended_after",theHold.IsSuspended())
    append report #("scope","Owned Max 2027 standard Scene preset save/prepare/merge only; unmodified materials; no artist-file overwrite or hold repair.")
    SPNWrite report directory
    if failure!="" do throw failure
)

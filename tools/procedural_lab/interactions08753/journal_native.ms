-- Owned Max 2027 fixture only. No Python entry point, no history clearing, and
-- no acceptance of a hold owned by a product command or another callback.
-- Actions, deferred observation, Undo and Redo each occupy separate host events.
global CJNativeKind,CJNativeBefore,CJNativeAfter,CJNativeUndoBefore
global CJNativeModel,CJNativeAction,CJNativeReport
global CJNativeJSON,CJNativeObject,CJNativeWrite,CJNativeSnapshot,CJNativeViews,CJNativeGate,CJNativeRow,CJNativeNames

fn CJNativeObject pairs = #(#journalNativeObject,pairs)
fn CJNativeJSON value = (
    if classof value==Array then (
        if value.count==2 and classof value[1]==Name and value[1]==#journalNativeObject then (
            local text="{",first=true
            for pair in value[2] do (if not first do text+=",";first=false;text+=(CJNativeJSON (pair[1] as string))+":"+(CJNativeJSON pair[2]))
            text+"}"
        ) else (
            local text="[",first=true
            for item in value do (if not first do text+=",";first=false;text+=CJNativeJSON item)
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
fn CJNativeNames names = (for item in names collect (item as string))
fn CJNativeWrite pairs = (
    local directory=pathConfig.appendPath GardenRun "journal-native-history"
    makeDir directory
    local document=CJNativeJSON (CJNativeObject pairs),identity=((dotNetClass "System.Guid").NewGuid()).ToString "N"
    local path=pathConfig.appendPath directory (CVProfileCase+"-"+identity+".json")
    (dotNetClass "System.IO.File").WriteAllText path document
    (dotNetClass "System.IO.File").WriteAllText (pathConfig.appendPath GardenRun (CVProfileCase+".json")) document
)
fn CJNativeGate whereText = (
    if theHold.Holding() do throw ("Unexpected active hold at "+whereText+". The test did not accept or cancel it.")
    if theHold.IsSuspended() do throw ("Unexpected suspended hold at "+whereText+". The test did not resume it.")
    true
)
fn CJNativeSnapshot = (
    local leaf=WFCollider
    if leaf.sources.count>16 or leaf.interactionDefinitions.count>16 or leaf.interactionProxyNodes.count>16 do throw "Journal fixture exceeds 16 source rows/definitions/proxies. Recreate the small owned fixture."
    if leaf.interactionSourceIDs.count!=leaf.interactionDefinitions.count or leaf.interactionProxySourceIDs.count!=leaf.interactionProxyNodes.count do throw "Journal fixture source bindings are incomplete."
    local hashes=#(),sha=(dotNetClass "System.Security.Cryptography.SHA256").Create()
    try (
        for text in leaf.interactionDefinitions do (
            local bytes=(dotNetClass "System.Text.Encoding").UTF8.GetBytes text
            local digest=sha.ComputeHash bytes
            append hashes (toLower (substituteString ((dotNetClass "System.BitConverter").ToString digest) "-" ""))
        )
        sha.Dispose()
    )catch(sha.Dispose();throw())
    #(
        #("ids",for value in leaf.sourceRowIDs collect value),
        #("nodes",for node in leaf.sources collect (if isValidNode node then node.handle else 0)),
        #("points",for value in leaf.sourcePoint collect value),#("empty",for value in leaf.sourceEmpty collect value),
        #("scales",for value in leaf.sourceScales collect value),#("offsets",for value in leaf.sourceZOffsetsWU collect value),
        #("weights",for value in leaf.sourceWeights collect value),#("forward",for value in leaf.sourceForwardAxes collect value),
        #("colors",for value in leaf.sourceColors collect #(value.r,value.g,value.b)),
        #("radii",for value in leaf.sourceRadiiWU collect value),#("auto_radius",for value in leaf.sourceAutoRadius collect value),
        #("follow_scale",for value in leaf.sourceFollowScale collect value),#("show_radius",for value in leaf.sourceShowRadius collect value),
        #("definition_ids",for value in leaf.interactionSourceIDs collect value),#("definition_sha256",hashes),
        #("proxy_ids",for value in leaf.interactionProxySourceIDs collect value),
        #("proxy_nodes",for node in leaf.interactionProxyNodes collect (if isValidNode node then node.handle else 0)),
        #("definition_revision",leaf.interactionDefinitionRevision),#("collider_mode",leaf.interactionColliderMode),
        #("collider",leaf.interactionCollider),#("react",leaf.interactionReact),#("navigation",WFRoot.viewportNavigationFaces)
    )
)
fn CJNativeViews = (
    local models=WFRoot.modelsUI,interactions=WFRoot.interactionsUI,ids=for value in WFCollider.sourceRowIDs collect value
    if not models.controlsReady or not interactions.controlsReady do throw "Source views are not ready. Complete journal-native-prepare and let its callback return."
    local interactionIDs=for value in interactions.interactionsUI_modelIDs collect value
    if not CyrusPresetSameValues ids interactionIDs do throw "The Interactions source view differs from authored row identities."
    if models.sourceUI_plantList.items.count!=ids.count or interactions.interactionsUI_modelList.items.count!=ids.count do throw "The two source views have different row counts."
    CJNativeObject #(#("ids",ids),#("interaction_ids",interactionIDs),#("models",CJNativeNames models.sourceUI_plantList.items),#("interactions",CJNativeNames interactions.interactionsUI_modelList.items))
)
fn CJNativeRow prepared:false = (
    for row=1 to WFCollider.sources.count do (
        local node=WFCollider.sources[row]
        if not WFCollider.isPointSource row and not WFCollider.isEmptySource row and WFCollider.usableSource node do (
            local id=WFCollider.sourceRowIDs[row]
            if not prepared or (findItem (WFCollider.interactionSourceIDs as array) id>0 and findItem (WFCollider.interactionProxySourceIDs as array) id>0) do return row
        )
    )
    throw (if prepared then "The small fixture needs one prepared source with an assigned proxy for removal Undo." else "The small fixture needs a usable mesh source row.")
)

(
    local failure="",holdingBefore=theHold.Holding(),suspendedBefore=theHold.IsSuspended()
    CJNativeReport=#(#("phase",CVProfileCase),#("action",if CJNativeAction==undefined then 0 else CJNativeAction),#("holding_before",holdingBefore),#("suspended_before",suspendedBefore))
    try (
        if cyrusSourceCommandUndoVersion()==1 then () else throw "This fixture needs the matched source Undo module."
        if CVProfileCase=="journal-native-picker-ready" then (
            CJNativeGate "native picker fixture entry"
            if not WFRoot.mainUI.controlsReady do throw "Let the owned fixture's command-panel mount callback return first."
            undo off (
                WFRoot.mainUI.selectLayerView WFCollider
                WFRoot.modelsUISlot.open=true;WFRoot.interactionsUISlot.open=true
                WFRoot.mainUI.bindSection WFRoot.modelsUI;WFRoot.mainUI.bindSection WFRoot.interactionsUI
                WFRoot.modelsUI.sourceUI_plantList.selection=#{1}
                WFRoot.modelsUI.sourceUI_showSelectedColor()
            )
        ) else if CVProfileCase=="journal-native-picker-baseline" then (
            CJNativeGate "native picker baseline"
            CJNativeBefore=CJNativeSnapshot();CJNativeAfter=undefined;CJNativeKind="replace"
            CJNativeUndoBefore=CJNativeNames (theHold.getUndoNames());CJNativeAction=1
            append CJNativeReport #("before",CJNativeObject CJNativeBefore)
        ) else if CVProfileCase=="journal-native-prepare" then (
            CJNativeGate "prepare entry"
            if not isValidNode AuditStone or WFCollider.interactionCollider or WFCollider.interactionReact do throw "Use the small role-Off replacement fixture with a valid AuditStone."
            if WFCollider.sources.count<2 or WFCollider.sources.count>8 do throw "Use the small two-source replacement fixture."
            CJNativeModel=instance AuditStone;CJNativeModel.name=uniqueName "Owned_native_journal_model_"
            WFRoot.viewportNavigationFaces=0
            WFRoot.modelsUISlot.open=true;WFRoot.interactionsUISlot.open=true;WFRoot.displayUISlot.open=true
            WFRoot.mainUI.selectLayerView WFCollider
            WFRoot.mainUI.bindSection WFRoot.modelsUI;WFRoot.mainUI.bindSection WFRoot.interactionsUI;WFRoot.mainUI.bindSection WFRoot.displayUI
            CJNativeBefore=undefined;CJNativeAfter=undefined;CJNativeKind="";CJNativeAction=0
            append CJNativeReport #("candidate_handle",CJNativeModel.handle)
            append CJNativeReport #("authored",CJNativeObject (CJNativeSnapshot()))
        ) else if CVProfileCase=="journal-native-observe" then (
            CJNativeGate "read-only observe"
            append CJNativeReport #("authored",CJNativeObject (CJNativeSnapshot()))
            append CJNativeReport #("views",CJNativeViews())
        ) else if matchPattern CVProfileCase pattern:"journal-native-action-*" then (
            CJNativeGate "action entry"
            CJNativeKind=substring CVProfileCase 23 (CVProfileCase.count-22)
            CJNativeBefore=CJNativeSnapshot();CJNativeAfter=undefined;CJNativeUndoBefore=CJNativeNames (theHold.getUndoNames());CJNativeAction+=1
            local models=WFRoot.modelsUI,row=0,chosen=0.0
            case CJNativeKind of (
                "model": (
                    if not isValidNode CJNativeModel or findItem (WFCollider.sources as array) CJNativeModel>0 do throw "Re-run journal-native-prepare to create one unused owned candidate."
                    models.sourceUI_addPlant.picked CJNativeModel
                )
                "empty": models.sourceUI_addEmpty.pressed()
                "point": models.sourceUI_addPoint.pressed()
                "remove": (row=CJNativeRow prepared:true;models.sourceUI_plantList.selection=#{row};models.sourceUI_removePlant.pressed())
                "scale": (row=CJNativeRow();chosen=if WFCollider.sourceScale row==0.731 then 0.673 else 0.731;models.sourceUI_plantList.selection=#{row};models.sourceUI_sourceScaleSpin.changed chosen)
                "offset": (row=CJNativeRow();chosen=if WFCollider.sourceZOffset row==1.2345 then 2.3456 else 1.2345;models.sourceUI_plantList.selection=#{row};models.sourceUI_sourceZSpin.changed chosen)
                "fast": WFRoot.displayUI.flow_previewUI_fastNavigationButton.pressed()
                default: throw "Unknown native journal action."
            )
            append CJNativeReport #("kind",CJNativeKind);append CJNativeReport #("before",CJNativeObject CJNativeBefore)
            append CJNativeReport #("undo_before",CJNativeUndoBefore)
            append CJNativeReport #("row",row);append CJNativeReport #("chosen",chosen)
            -- Observe this callback's exit state, but qualify closure only in
            -- the following independent record event after natural UI return.
        ) else if CVProfileCase=="journal-native-record" then (
            CJNativeGate "record after action callback"
            if CJNativeBefore==undefined or CJNativeKind=="" do throw "Run one native journal action before recording it."
            CJNativeAfter=CJNativeSnapshot()
            if CyrusPresetSameValues CJNativeBefore CJNativeAfter do throw "The source action made no authored change."
            local undoNames=CJNativeNames (theHold.getUndoNames()),maximum=theHold.getMaxUndoLevels()
            if undoNames.count!=(amin maximum (CJNativeUndoBefore.count+1)) do throw "The action did not create exactly one natural Undo unit. No hold was auto-accepted."
            append CJNativeReport #("kind",CJNativeKind);append CJNativeReport #("before",CJNativeObject CJNativeBefore);append CJNativeReport #("after",CJNativeObject CJNativeAfter)
            append CJNativeReport #("views",CJNativeViews());append CJNativeReport #("undo_before",CJNativeUndoBefore)
        ) else if CVProfileCase=="journal-native-undo-check" or CVProfileCase=="journal-native-redo-check" then (
            CJNativeGate "read-only Undo/Redo check"
            if CJNativeAfter==undefined do throw "Record the completed action before Undo/Redo."
            local current=CJNativeSnapshot(),expected=if CVProfileCase=="journal-native-undo-check" then CJNativeBefore else CJNativeAfter
            if not CyrusPresetSameValues current expected do throw "The authored source snapshot differs after the standalone Undo/Redo event."
            append CJNativeReport #("kind",CJNativeKind);append CJNativeReport #("authored",CJNativeObject current);append CJNativeReport #("views",CJNativeViews())
        ) else if CVProfileCase=="journal-native-cancel" then (
            CJNativeGate "owned cancellation entry"
            local before=CJNativeSnapshot(),suspended=CyrusPointSuspended,command=WFCollider.sourceCommandBegin "Owned cancelled source" 2,seen=false
            try(WFCollider.sourceScales[1]=0.123;cyrusSourceCommandSeal undefined)
            catch(seen=true;WFCollider.sourceCommandCancel command)
            if not seen or not CyrusPresetSameValues before (CJNativeSnapshot()) or CyrusPointSuspended!=suspended do throw "The failed owned command did not restore its authored state and suspension flag."
            CJNativeGate "owned cancellation exit";append CJNativeReport #("restored",CJNativeObject before)
        ) else if CVProfileCase=="journal-native-nested-cancel" then (
            CJNativeGate "caller-owned cancellation entry"
            local before=CJNativeSnapshot(),suspended=CyrusPointSuspended
            theHold.Begin()
            try(WFCollider.addEmptySource();theHold.Cancel())catch(theHold.Cancel();throw())
            if not CyrusPresetSameValues before (CJNativeSnapshot()) or CyrusPointSuspended!=suspended do throw "Caller cancellation did not restore the source command and suspension flag."
            CJNativeGate "caller-owned cancellation exit";append CJNativeReport #("restored",CJNativeObject before)
        ) else throw "Unknown native journal phase."
        append CJNativeReport #("status","pass")
    )catch(failure=getCurrentException();append CJNativeReport #("status","failed");append CJNativeReport #("error",failure);append CJNativeReport #("stack",getCurrentExceptionStackTrace()))
    append CJNativeReport #("holding_after",theHold.Holding());append CJNativeReport #("suspended_after",theHold.IsSuspended())
    append CJNativeReport #("super_level",theHold.SuperLevel());append CJNativeReport #("undo",CJNativeNames (theHold.getUndoNames()));append CJNativeReport #("redo",CJNativeNames (theHold.getRedoNames()))
    CJNativeWrite CJNativeReport
    if failure!="" do throw failure
)

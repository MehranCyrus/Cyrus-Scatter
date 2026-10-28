-- Commands and Undo/Redo occupy separate native Max events. Never clear history
-- or accept/cancel a hold owned by any other operation.
global ADBeforeRefs,ADBeforeMode,ADExpectedRefs,ADExpectedMode,ADJournalAction,ADRefsEqual
fn ADRefsEqual expected = (
    local actual=WFRoot.interactionSceneColliders as array
    if actual.count!=expected.count do return false
    for i=1 to actual.count where actual[i]!=expected[i] do return false
    true
)
(
    if not matchPattern GardenRun pattern:"*/build/adaptation08754-20261028-01/host-*/" do throw "Owned adaptation host required."
    if theHold.Holding() or theHold.IsSuspended() do throw "Unexpected authored hold. Test did not repair it."
    local phase=CVProfileCase,result="",failure=""
    try (
        case phase of (
            "ui-bind":(
                WFRoot.mainUI.selectLayerView WFGrass
                WFRoot.interactionsUISlot.open=true;WFRoot.collidersUISlot.open=true
                WFRoot.mainUI.bindSection WFRoot.interactionsUI;WFRoot.mainUI.bindSection WFRoot.collidersUI
                local section=WFRoot.collidersUI
                if section.collidersUI_colliderList.items.count!=WFRoot.interactionSceneColliders.count do throw "Scene list does not bind root references."
                result="PASS same model views, response controls and root scene list"
            )
            "add-scene":(
                ADBeforeRefs=WFRoot.interactionSceneColliders as array
                ADBox=box name:"AD_Second_Ordinary_Box" width:20 length:20 height:20 pos:[0,0,500]
                WFRoot.interactionsSceneCommand #(ADBox)
                ADExpectedRefs=WFRoot.interactionSceneColliders as array
                if ADExpectedRefs.count!=ADBeforeRefs.count+1 do throw "Scene collider add failed."
                result="PASS scene collider authoring"
            )
            "verify-add-undo":(
                if not ADRefsEqual ADBeforeRefs do throw ("Undo did not restore scene references. Count="+(WFRoot.interactionSceneColliders.count as string))
                result="PASS scene collider Undo"
            )
            "verify-add-redo":(
                if not ADRefsEqual ADExpectedRefs do throw "Redo did not restore scene references."
                result="PASS scene collider Redo"
            )
            "response-setting":(
                ADBeforeMode=WFGrass.interactionResponse
                WFGrass.interactionsResponseSetting #interactionResponse 2
                ADExpectedMode=2
                if WFGrass.interactionResponse!=2 do throw "Response did not change."
                result="PASS response setting authoring"
            )
            "verify-response-undo":(
                if WFGrass.interactionResponse!=ADBeforeMode do throw "Response Undo failed."
                result="PASS response Undo"
            )
            "verify-response-redo":(
                if WFGrass.interactionResponse!=ADExpectedMode do throw "Response Redo failed."
                result="PASS response Redo"
            )
            "remove-scene":(
                ADBeforeRefs=WFRoot.interactionSceneColliders as array
                WFRoot.interactionsSceneCommand #() removeIndex:WFRoot.interactionSceneColliders.count
                ADExpectedRefs=WFRoot.interactionSceneColliders as array
                if ADExpectedRefs.count!=ADBeforeRefs.count-1 do throw "Scene collider remove failed."
                result="PASS scene collider removal"
            )
            "refresh":(WFRoot.interactionsEnsure();CyrusPointSync();result="PASS retained refresh")
            "save-trial":(
                local folder=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Interaction 0.87.5.4\"
                makeDir folder
                if not saveMaxFile (folder+"Scene_Collider_Grass_0.87.5.4.max") quiet:true do throw "Could not save trial copy."
                result="PASS saved owned trial"
            )
            default:throw ("Unknown journal phase "+phase)
        )
        if theHold.Holding() or theHold.IsSuspended() do throw "Authored hold leaked by test operation."
    )catch(failure=getCurrentException();result="FAILED "+failure+"\n"+getCurrentExceptionStackTrace())
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+phase+".txt") result
    if failure!="" do throw failure
)

(
global IOwner,IRoot,IGrass,IRocks,IEdit,IAssert,IWrite,ISettle
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/interactions087/smoke.py"
if not doesFileExist (GardenRun+"setup-complete.json") do throw "Smoke setup failed. See error.txt."
fn IAssert value message = (if not value do throw message;true)
fn IWrite name content = ((dotNetClass "System.IO.File").WriteAllText (GardenRun+name) content)
fn ISettle ms = (
    local end=timeStamp()+ms
    while timeStamp()<end do (windows.processPostedMessages();(dotNetClass "System.Windows.Forms.Application").DoEvents();redrawViews())
)
select IOwner;max modify mode;modPanel.setCurrentObject IEdit;completeRedraw();ISettle 1500
cyrusEditActiveLayers IEdit #(IGrass.editLayerKey,IRocks.editLayerKey)
local rows=(cyrusEditInspect IEdit 0 200)[4],visible=for row in rows where row[7] collect row
local index=0
for i=1 to visible.count where visible[i][1]==IRocks.editLayerKey do index=i
IAssert (index>0) "The stone Edit handle must be in the actually displayed population."
cyrusEditSelect IEdit #(index)
clearUndoBuffer()
local before=(cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation
IRocks.interactionCollider=false;IRoot.interactionsEnsure();CyrusPointSync();ISettle 150
undo "Move before enabling Collider" on cyrusEditTransform IEdit 0 [3,0,0] (matrix3 1) false
ISettle 150
IRocks.interactionCollider=true;IRoot.interactionsEnsure();CyrusPointSync();ISettle 150
IAssert (distance (before+[3,0,0]) (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.001) "Enabling Collider must read an Edit made while its role was off."
max undo;ISettle 150
IAssert (distance before (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.001) "Undo after role activation restores the same stone."
clearUndoBuffer()
IWrite "before-edit.json" (IRoot.interactionsStatistics())
local restores=(cyrusEditMemoryStats IEdit)[8],epoch=IRoot.procEpoch
undo "Interaction stone move" on cyrusEditTransform IEdit 0 [20,0,0] (matrix3 1) false
ISettle 200
local moved=(cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation
IAssert (distance before moved>19.99) "The individual stone and displayed handle must move together."
IWrite "after-edit.json" (IRoot.interactionsStatistics())
max undo
ISettle 200
IAssert (isValidNode IOwner and IGrass.interactionReact and IRocks.interactionCollider) "Undo must preserve the scene and its authored interaction roles."
IAssert ((cyrusEditMemoryStats IEdit)[8]>restores) "The move must have a real native Edit restore record."
local restored=(cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation
IAssert (distance restored before<0.001) "Undo must restore the individual stone to its prior transform."
IWrite "after-undo.json" (IRoot.interactionsStatistics())
IGrass.amount=5000;IGrass.randomSeed=931
undo "Manual contact move" on cyrusEditTransform IEdit 0 [10,0,0] (matrix3 1) false
ISettle 200
IAssert (IRoot.procEpoch==epoch and IGrass.generatedCount==80) "Moving a collider must not consume pending Manual amount or seed edits."
IGrass.amount=80;IGrass.randomSeed=42
local effective=(cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation
IGrass.interactionGapWU=0.2
IRoot.interactionsEnsure();CyrusPointSync();ISettle 150
IAssert (distance effective (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.001) "Changing contact gap must retain the moved stone."
IAssert (IRoot.procEpoch==epoch) "Contact settings must retain the frozen placement epoch."
IRocks.interactionCollider=false
IRoot.interactionsEnsure();CyrusPointSync();ISettle 150
IAssert (distance effective (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.001) "Turning Collider off must preserve its authored Edit transform."
IGrass.interactionReact=false
IRoot.interactionsEnsure();CyrusPointSync();ISettle 150
IAssert (IRoot.interactionState!=undefined) "An overlay with existing instance edits must survive turning all contact roles off."
IAssert (distance effective (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.001) "Disabling all roles must retain the moved stone."
IGrass.interactionReact=true;IRocks.interactionCollider=true;IGrass.interactionGapWU=0
IRoot.interactionsEnsure();CyrusPointSync();ISettle 150
IAssert (distance effective (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.001) "Re-enabling contact roles must preserve the stone."
IWrite "after-settings.json" (IRoot.interactionsStatistics())
local active=(cyrusEditInspect IEdit 0 200)[4],currentVisible=for row in active where row[7] collect row
for i=1 to currentVisible.count where currentVisible[i][1]==IRocks.editLayerKey do index=i
cyrusEditSelect IEdit #(index);clearUndoBuffer()
undo "Delete contact stone" on cyrusEditCommand IEdit 2 (matrix3 1)
ISettle 150
IAssert ((cyrusInteractionRows IRoot.interactionState 2).count==0) "Deleting an individual collider must remove it from the contact output."
max undo;ISettle 150
IAssert ((cyrusInteractionRows IRoot.interactionState 2).count==1) "Undo must restore a deleted collider to the contact output."
IAssert (distance effective (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.001) "Delete Undo must restore the moved stone's position."
local audit=cyrusInteractionValidate IRoot.interactionState 2000000
IWrite "full-mesh.json" audit[3]
IAssert audit[1] "Independent complete visible grass mesh audit must pass."
saveMaxFile (GardenRun+"Interaction_Smoke_087.max") quiet:true
loadMaxFile (GardenRun+"Interaction_Smoke_087.max") quiet:true
IOwner=getNodeByName "INTERACTION_Scatter_087";IRoot=IOwner.baseObject;IGrass=IRoot.layerObjects[1];IRocks=IRoot.layerObjects[2];IEdit=IOwner.modifiers[1]
IRoot.refreshAll();CyrusPointSync();select IOwner;modPanel.setCurrentObject IEdit;ISettle 500
IAssert (distance effective (cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation<0.01) "Save/reopen must reconstruct contact poses and authored stone edits."
IWrite "reopened.json" (IRoot.interactionsStatistics())
IWrite "completed.json" "{\"status\":\"pass\",\"host\":2027,\"scope\":\"Source review, retained Mesh, individual Edit and Undo, Manual pending isolation, contact-settings and role changes, delete/Undo, full grass mesh audit, save/reopen; no FPS/render qualification\"}"
)

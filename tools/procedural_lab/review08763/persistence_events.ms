-- Separate host events keep setup/inspection out of the authored Undo command.
global RPETimer,RPEStep=0,RPEFile,RPEBefore,RPEAfter,RPEIdentity
loadMaxFile (GardenRun+"Review_08763.max") quiet:true useFileUnits:true
RKOwner=getNodeByName "Review fixture" exact:true;RKRoot=RKOwner.baseObject
RKA=RKRoot.layerObjects[1];RKB=RKRoot.layerObjects[2]
for m in RKOwner.modifiers where classof m==CyrusScatterEdit do RKEdit=m
undo off (RKRoot.interactionsEnsure();CyrusPointSync();completeRedraw())
clearUndoBuffer()
RPEFile=createFile (GardenRun+"persistence-events.txt")
fn RPERow = (
    for row in (cyrusEditInspect RKEdit 0 500)[4] where row[1]==RKB.editLayerKey and (RPEIdentity==undefined or row[5]==RPEIdentity) do return row
    throw "Fixture reactor row unavailable"
)
fn RPETick sender args = (
    RPETimer.Stop()
    try (
        RPEStep+=1
        case RPEStep of (
            1: (
                undo off (CyrusPointSync();cyrusEditActiveLayers RKEdit #(RKB.editLayerKey);cyrusEditSelect RKEdit #(1))
                local row=RPERow();RPEIdentity=row[5];RPEBefore=row[13].row4
                if RKB.generatedCount!=500 do throw "Saved placement count differs"
                undo "Review sparse Edit" on (cyrusEditCommand RKEdit 4 (transMatrix [.01,0,0]))
            )
            2: (
                undo off (CyrusPointSync();redrawViews())
                RPEAfter=(RPERow())[13].row4
                if distance RPEAfter (RPEBefore+[.01,0,0])>1e-6 do throw "Move differs"
                format "MOVE % % identity:%\nUNDO_NAMES %\n" RPEBefore RPEAfter RPEIdentity (theHold.getUndoNames()) to:RPEFile
                max undo
            )
            3: (
                undo off (CyrusPointSync();redrawViews())
                local position=(RPERow())[13].row4
                format "UNDO %\nREDO_NAMES %\n" position (theHold.getRedoNames()) to:RPEFile
                if distance position RPEBefore>1e-6 do throw "Undo differs"
                max redo
            )
            4: (
                undo off (CyrusPointSync();redrawViews())
                local position=(RPERow())[13].row4
                format "REDO %\n" position to:RPEFile
                if distance position RPEAfter>1e-6 do throw "Redo differs"
                if RKRoot.interactionError!="" do throw RKRoot.interactionError
                format "COMPLETE\n" to:RPEFile;close RPEFile
            )
        )
        if RPEStep<4 do (flush RPEFile;RPETimer.Start())
    )catch(format "ERROR %\n" (getCurrentException()) to:RPEFile;close RPEFile)
)
RPETimer=dotNetObject "System.Windows.Forms.Timer";RPETimer.Interval=250
dotNet.addEventHandler RPETimer "Tick" RPETick
RPETimer.Start()

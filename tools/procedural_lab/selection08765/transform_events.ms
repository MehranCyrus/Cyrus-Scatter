-- Separate event boundaries exercise the real authoring / Undo path.
global VETimer,VEStep=0,VEFile,VEEdit=VPNode.modifiers[1],VEId,VEInitial,VEMoved,VERotated,VEScaled
CyrusSelectionTimer.Stop()
undo off (VPA.amount=10;VPRoot.updateMode=2;VPRoot.refreshAll();CyrusPointSync();redrawViews())
clearUndoBuffer()
VEFile=createFile (GardenRun+"transform-events.txt")
fn VERow = (
    for row in (cyrusEditInspect VEEdit 0 500)[4] where row[8] do return row
    throw "Expected one selected instance"
)
fn VEMatrixEqual a b = (
    for i=1 to 4 where distance a[i] b[i]>0.001 do return false
    true
)
fn VETick sender args = (
    VETimer.Stop()
    try (
        VEStep+=1
        undo off (CyrusPointSync();redrawViews())
        case VEStep of (
            1: (
                local row=VERow();VEId=row[5];VEInitial=row[13]
                undo "Viewport selected Move" on cyrusEditTransform VEEdit 0 [20,0,0] (matrix3 1) false
            )
            2: (
                VEMoved=(VERow())[13]
                if distance VEMoved.row4 (VEInitial.row4+[20,0,0])>0.001 do throw "Move differs"
                format "MOVE PASS %\n" VEId to:VEFile
                undo "Viewport selected Rotate" on cyrusEditTransform VEEdit 1 (quat 30 [0,0,1]) (matrix3 1) true
            )
            3: (
                VERotated=(VERow())[13]
                if VEMatrixEqual VERotated VEMoved do throw "Rotation did not change"
                if distance VERotated.row4 VEMoved.row4>0.001 do throw "Rotation changed pivot"
                format "ROTATE PASS\n" to:VEFile
                undo "Viewport selected Scale" on cyrusEditTransform VEEdit 2 [1.5,1.5,1.5] (matrix3 1) true
            )
            4: (
                VEScaled=(VERow())[13]
                if abs ((length VEScaled.row1)/(length VERotated.row1)-1.5)>0.001 do throw "Scale differs"
                format "SCALE PASS\n" to:VEFile
                max undo
            )
            5: (
                if not VEMatrixEqual (VERow())[13] VERotated do throw "Undo differs"
                format "UNDO PASS\n" to:VEFile;max redo
            )
            6: (
                if not VEMatrixEqual (VERow())[13] VEScaled do throw "Redo differs"
                if (VERow())[5]!=VEId do throw "Stable identity changed"
                if VPRoot.interactionError!="" do throw VPRoot.interactionError
                format "REDO PASS\nCOMPLETE\n" to:VEFile;close VEFile
            )
        )
        if VEStep<6 do (flush VEFile;VETimer.Start())
    )catch(format "ERROR %\n" (getCurrentException()) to:VEFile;close VEFile)
)
VETimer=dotNetObject "System.Windows.Forms.Timer";VETimer.Interval=350
dotNet.addEventHandler VETimer "Tick" VETick
VETimer.Start()

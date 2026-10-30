-- Separate UI events, so each command ends its real Undo hold before the next.
global PKBatchTimer,PKBatchStep=0,PKBatchBefore,PKBatchFile
PKBatchBefore=#(PKRoot.viewportNavigationFaces,PKOther.viewportNavigationFaces)
PKBatchFile=createFile (GardenRun+"batch-events.txt")
select #(PKOne,PKTwo)
fn PKBatchTick sender args = (
    PKBatchTimer.Stop()
    try (
        PKBatchStep+=1
        case PKBatchStep of (
            1: (CyrusSelectionUI.navigation.changed 771234)
            2: (
                format "UNDO_NAMES %\n" (theHold.getUndoNames()) to:PKBatchFile
                if PKRoot.viewportNavigationFaces!=771234 or PKOther.viewportNavigationFaces!=771234 do throw "Batch setting failed"
                max undo
                format "UNDO_VALUES % % expected %\n" PKRoot.viewportNavigationFaces PKOther.viewportNavigationFaces PKBatchBefore to:PKBatchFile
                if PKRoot.viewportNavigationFaces!=PKBatchBefore[1] or PKOther.viewportNavigationFaces!=PKBatchBefore[2] do throw "Batch Undo failed"
                format "UNDO_PASS\n" to:PKBatchFile
            )
            3: (CyrusSelectionUI.disableButton.pressed())
            4: (
                if PKRoot.cyrusEnabled or PKOther.cyrusEnabled do throw "Disable failed"
                CyrusPointSync()
                format "DISABLE_PASS\n" to:PKBatchFile
                CyrusSelectionUI.enableButton.pressed()
            )
            5: (
                if not PKRoot.cyrusEnabled or not PKOther.cyrusEnabled do throw "Enable failed"
                format "ENABLE_PASS\n" to:PKBatchFile
                CyrusSelectionUI.apply #display 5
            )
            6: (
                if PKRoot.identificationMode!=4 or PKOther.identificationMode!=4 do throw "Textured mode failed"
                format "TEXTURED_PASS\n" to:PKBatchFile
                CyrusSelectionUI.apply #display 3
            )
            7: (
                if PKRoot.viewportMode!=3 or PKOther.viewportMode!=3 or PKRoot.identificationMode==4 do throw "Mesh mode failed"
                format "MESH_PASS\nCOMPLETE\n" to:PKBatchFile
                close PKBatchFile
            )
        )
        if PKBatchStep<7 do (flush PKBatchFile;PKBatchTimer.Start())
    )catch(format "ERROR %\n" (getCurrentException()) to:PKBatchFile;close PKBatchFile)
)
PKBatchTimer=dotNetObject "System.Windows.Forms.Timer"
PKBatchTimer.Interval=200
dotNet.addEventHandler PKBatchTimer "Tick" PKBatchTick
PKBatchTimer.Start()

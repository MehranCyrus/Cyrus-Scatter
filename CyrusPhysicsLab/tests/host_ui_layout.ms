setSilentMode true
setQuietMode true
resetMaxFile #noPrompt
setSilentMode false
setQuietMode false
global CPLUILab
(
 local node=CyrusPhysicsLab name:"PhysicsLab_Layout"
 cplStage "layout node created"
 CPLUILab=node.baseObject
 select node;max modify mode;modPanel.setCurrentObject CPLUILab
 cplStage "layout selected"
 windows.processPostedMessages()
 cplStage "layout messages processed"
 CPLUILab.syncUI()
 if CPLUILab.brushHeader.startButton.enabled do throw "Start must remain disabled without bindings."
 CPLUILab.showError "A longer diagnostic must remain readable. The pending physics result is preserved. Resume the session, undo a stroke, freeze the preview, or cancel before changing the source geometry. This checks wrapping and rollout height without a screenshot."
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 cplStage "layout Python completed"
 local report=createFile (CPLTestDir+"assertions.txt")
 format "PASS native rollout bounds and caption metrics; no screen pixels or OS input\n" to:report
 close report
)

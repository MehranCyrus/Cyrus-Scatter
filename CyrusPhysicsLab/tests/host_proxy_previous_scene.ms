cplResetScene()
loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-011-final-05/PhysicsLab_Leaves_Max2027.max" quiet:true
(
 local lab=getNodeByName "Standalone_Physics_Leaves"
 local saved=cplExport lab.physicsDocument
 if findString saved "cpl-leaf-2"==undefined do throw "Historical profile 2 changed on open."
 if (cplUIState lab.physicsDocument)[5]!=60 do throw "Historical profile 2 cached result was lost."
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.refreshBindings();windows.processPostedMessages()
 if cplExport lab.physicsDocument!=saved do throw "Opening the new proxy controls changed cached state."
 local report=createFile (CPLTestDir+"assertions.txt")
 format "PASS preserved 0.1.1 scene: profile 2 and 60 cached leaves unchanged; no replay/resave\n" to:report
 close report
)

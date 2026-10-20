-- Read a preserved 0.1.0 test scene; never resave or replay it.
cplResetScene()
loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-host-20261016-25/PhysicsLab_Leaves_Max2027.max" quiet:true
(
 local lab=getNodeByName "Standalone_Physics_Leaves"
 if lab==undefined do throw "Historical lab scene did not open."
 local cached=cplExport lab.physicsDocument
 if findString cached "cpl-leaf-1"==undefined do throw "Old solver profile was lost."
 if findString (cplStats lab.physicsDocument) "\"rows\":60"==undefined do throw "Cached bodies were lost."
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 windows.processPostedMessages()
 lab.refreshBindings()
 if cplExport lab.physicsDocument!=cached do throw "Panel opening replayed or changed the cached result."
 if not lab.brushHeader.startButton.enabled do throw "Reopened input bindings did not enable the brush."
 local report=createFile (CPLTestDir+"assertions.txt")
 format "PASS preserved 0.1.0 scene opens with 60 cached bodies, original solver profile and current UI; no replay/resave\n" to:report
 close report
)

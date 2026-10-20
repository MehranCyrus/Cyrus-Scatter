cplResetScene()
(
 local path=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-014-fatal-02/"
 if not loadMaxFile (path+"bindings.max") quiet:true do throw "Old bindings did not load"
 local lab=getNodeByName "Continuous_crash_recovery"
 local dirs=getDirectories (path+"diagnostics/*")
 cplRecoverFile lab.physicsDocument (dirs[1]+"live-recovery-0.json")
 local rejected=false
 try(lab.startBrush())catch(rejected=true)
 if not rejected do throw "Old solver accepted Resume"
 if (cplUIState lab.physicsDocument)[6]!=3 do throw "Old cached preview lost"
 cplFreeze lab.physicsDocument
 if (cplUIState lab.physicsDocument)[5]!=3 do throw "Old cached Freeze failed"
 if lab.stickiness!=0 do throw "Old editable setting not zero"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS old 0.1.4 bindings and recovery default to zero grip; different solver rejects Resume and preserves cached Freeze"
)

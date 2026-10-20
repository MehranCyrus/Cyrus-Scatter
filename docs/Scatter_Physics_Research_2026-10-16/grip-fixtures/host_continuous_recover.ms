cplResetScene()
fn recoverRequire value message = if not value do throw message
(
 local root=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/",combined=""
 for run in #("physics-lab-015-fatal-01","physics-lab-015-hardkill-01") do
 (
  cplResetScene()
  local path=root+run+"/",dirs=getDirectories (path+"diagnostics/*")
  recoverRequire (dirs.count==1) "Crash diagnostic directory missing or ambiguous"
  local recovery=dirs[1]+"live-recovery-0.json"
  recoverRequire (doesFileExist recovery) "Durable recovery missing"
  recoverRequire (loadMaxFile (path+"bindings.max") quiet:true) "Crash base scene could not load"
  local lab=getNodeByName "Continuous_crash_recovery"
  cplRecoverFile lab.physicsDocument recovery
  recoverRequire ((cplUIState lab.physicsDocument)[6]==3 and (cplUIState lab.physicsDocument)[8]) "Crash preview missing or not paused"
  recoverRequire (lab.stickiness==80) "Crash scene lost grip"
  lab.startBrush();cplPause lab.physicsDocument
  recoverRequire ((cplUIState lab.physicsDocument)[9]==3) "Crash stroke history missing"
  cplUndoStroke lab.physicsDocument
  recoverRequire ((cplUIState lab.physicsDocument)[6]==2) "Crash history Undo failed"
  cplRedoStroke lab.physicsDocument
  cplFreeze lab.physicsDocument
  for i=1 to 100 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01)
  recoverRequire ((cplUIState lab.physicsDocument)[5]==3) "Recovered Freeze failed"
  cplClear lab.physicsDocument
  local content=(dotNetClass "System.IO.File").ReadAllText recovery
  local bad=(dotNetClass "System.Text.RegularExpressions.Regex").Replace content "\"solver\":\"[^\"]+\"" "\"solver\":\"wrong-build\""
  local mismatch=CPLTestDir+run+"-wrong-solver.json"
  (dotNetClass "System.IO.File").WriteAllText mismatch bad
  cplRecoverFile lab.physicsDocument mismatch
  local rejected=false
  try(lab.startBrush())catch(rejected=true)
  recoverRequire rejected "Wrong solver build replay was accepted"
  recoverRequire ((cplUIState lab.physicsDocument)[6]==3) "Rejected replay discarded cached preview"
  cplFreeze lab.physicsDocument
  recoverRequire ((cplUIState lab.physicsDocument)[5]==3 and not (cplUIState lab.physicsDocument)[2]) "Cross-build cached Freeze failed"
  combined+="PASS "+run+": cached preview, matching replay, Undo/Redo, Freeze, mismatched replay rejection and cached Freeze\n"
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") combined
)

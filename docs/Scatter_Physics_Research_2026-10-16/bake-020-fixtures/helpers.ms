loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global BChecks=0,CPLUILab
fn bNeed value message=(BChecks+=1;if not value do throw message)
fn bPump ms=(local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn bShow lab=(select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;lab.brushHeader.open=true;lab.objectsUI.open=true;lab.collisionUI.open=true;bPump 100;lab.refreshBindings())
fn bWait lab=(local until=timeStamp()+40000;while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 4;bPump 10);bNeed (not (cplUIState lab.physicsDocument)[2]) ("Finish/bake failed: "+cplStats lab.physicsDocument+lab.uiError))
fn bPath lab points=(bNeed (cplPrivatePaintPath lab.physicsDocument points false==points.count) "Painter SDK hit mismatch";cplSynchronize lab.physicsDocument)
fn bWrite name value=((dotNetClass "System.IO.File").WriteAllText (CPLTestDir+name) value)

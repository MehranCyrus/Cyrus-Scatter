from pathlib import Path
from pymxs import runtime as r
import json,time,traceback,hashlib
ROOT=Path(__file__).resolve().parents[4];OUT=Path(str(r.GardenRun));report={}
def wait(op):
 end=time.monotonic()+50
 while not op.Terminal and time.monotonic()<end:r.windows.processPostedMessages();time.sleep(.02)
 assert op.Terminal and str(op.State)=='complete',str(op.Error)
 return str(op.Result)
try:
 assert r.cyrusLicenseAllows(),'Only the isolated test authority may authorize this host'
 fixture=ROOT/'build/full-system-review-08763-20261029-01/host/Review_08763.max'
 assert r.loadMaxFile(str(fixture),quiet=True,useFileUnits=True)
 r.execute('global LBOwner=getNodeByName "Review fixture" exact:true;global LBRoot=LBOwner.baseObject;global LBJob;CyrusSelectionTimer.Stop();for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned review frame"')
 r.execute('LBJob=CyrusScenePresetSave LBRoot "Review native scene" (CyrusRecipeObject #(#("category","Review"),#("tags",#("fixture")),#("description","Private review"))) ""')
 end=time.monotonic()+60
 while time.monotonic()<end:
  state=str(r.CyrusSharedPollSave(r.LBJob))
  if state in ('complete','failed','cancelled'):break
  r.windows.processPostedMessages();time.sleep(.02)
 assert state=='complete',str(r.LBJob.error)
 entry=str(r.LBJob.result);d=json.loads(Path(entry).read_text(encoding='utf-8-sig'));digest=hashlib.sha256(Path(entry).read_bytes()).hexdigest()
 report['save']={'format':d['format'],'writer_version':d['scatterVersion'],'nodes':d['nodeCount'],'assets':len(d['assets'])}
 store=r.CyrusSharedStore();copy=wait(store.PrepareScene(entry,digest));old=float(r.units.SystemScale);before=len(list(r.objects))
 try:
  r.units.SystemScale=old*2
  r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned unit guard frame"')
  rejected=False
  try:r.CyrusScenePresetMerge(entry,digest,copy)
  except Exception as e:rejected='system units' in str(e)
  assert rejected and len(list(r.objects))==before
  report['units_mismatch_retains_scene']=True
 finally:r.units.SystemScale=old
 r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned merge frame"')
 imported=r.CyrusScenePresetMerge(entry,digest,copy);store.DiscardSceneLoad(copy)
 assert imported!=r.undefined
 def rows(root):return [int(x.generatedCount) for x in root.layerObjects]
 assert rows(imported.baseObject)==rows(r.LBRoot)
 assert not set(str(x.layerID) for x in imported.baseObject.layerObjects).intersection(str(x.layerID) for x in r.LBRoot.layerObjects)
 report['merge']={'original_rows':rows(r.LBRoot),'imported_rows':rows(imported.baseObject),'fresh_layer_identities':True,'old_scene_retained':r.isValidNode(r.LBOwner)}
 r.saveMaxFile(str(OUT/'library-roundtrip.max'),quiet=True)
 assert r.loadMaxFile(str(OUT/'library-roundtrip.max'),quiet=True,useFileUnits=True)
 report['save_reload']=True
 report['status']='complete';(OUT/'completed.json').write_text(json.dumps(report,indent=2))
except Exception:
 report.update(status='failed',error=traceback.format_exc());(OUT/'error.txt').write_text(report['error'])
finally:(OUT/'library-host.json').write_text(json.dumps(report,indent=2))

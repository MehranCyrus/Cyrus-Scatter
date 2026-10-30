from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
run=Path(__file__).resolve().parent;out=Path(str(r.GardenRun));report={}
def pump():
 for _ in range(14):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.03)
def mat(m):return [[float(m[i][j]) for j in range(3)] for i in range(4)]
def selected():return next(x for x in r.cyrusEditInspect(r.EREdit,0,500)[3] if x[7])
try:
 assert r.cyrusLicenseAllows()
 assert r.loadMaxFile(str(run/'baseline-events/edited-08765.max'),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
 r.execute('global ERNode=getNodeByName "Owned pinned Edit",ERRoot=ERNode.baseObject,ERLayer=ERRoot.layerObjects[1],EREdit=ERNode.modifiers[1];ERRoot.refreshAll()');pump()
 original=mat(selected()[12]);report['from_08765']=original
 assert not str(r.ERLayer.previewError)
 r.ERLayer.randomSeed=int(r.ERLayer.randomSeed)+1;r.ERLayer.markInputDirty();r.ERRoot.refreshAll();pump()
 report['reseed']=mat(selected()[12]);assert report['reseed']==original and not str(r.ERLayer.previewError)
 path=out/'migrated-0877.max';assert r.saveMaxFile(str(path),quiet=True);assert r.loadMaxFile(str(path),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
 r.execute('ERNode=getNodeByName "Owned pinned Edit";ERRoot=ERNode.baseObject;ERLayer=ERRoot.layerObjects[1];EREdit=ERNode.modifiers[1];ERRoot.refreshAll()');pump()
 report['reopened']=mat(selected()[12]);assert report['reopened']==original and not str(r.ERLayer.previewError)
 report['status']='complete';(out/'completed.json').write_text(json.dumps(report,indent=2))
except Exception:
 report['error']=traceback.format_exc();(out/'error.txt').write_text(report['error'])
(out/'migration.json').write_text(json.dumps(report,indent=2))

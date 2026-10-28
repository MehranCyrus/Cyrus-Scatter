from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));phase=str(r.CVProfileCase);out={'phase':phase}
def roots():return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined]
def rows(mod):
 def matrix(m):return None if m==r.undefined else [[float(m[i][j]) for j in range(3)] for i in range(4)]
 return [{'key':int(x[0]),'input':str(x[3]),'output':str(x[4]),'deleted':bool(x[8]),'order':int(x[9]),'base':matrix(x[11]),'final':matrix(x[12])} for x in r.cyrusEditInspect(mod,0,500)[3]]
try:
 if phase=='before-undo':
  assert len(roots())==1
  data=rows(roots()[0].baseObject.procModifiers()[0]);(O/'lifecycle-before.json').write_text(json.dumps(data,indent=2));out['nodes']=len(list(r.objects));out['rows']=len(data)
 elif phase=='check-undo':
  out['remaining_nodes']=[str(n.name) for n in r.objects];assert len(roots())==0,out
 elif phase in ('check-redo','reopen'):
  if phase=='reopen':
   assert r.loadMaxFile(str(O/'Ready_Roundtrip_08744.max'),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
  assert len(roots())==1
  r.WFOwner=roots()[0];r.WFRoot=roots()[0].baseObject;r.WFEdit=r.WFRoot.procModifiers()[0]
  r.WFRoot.refreshAll();r.CyrusPointSync();assert not str(r.WFRoot.interactionError)
  data=rows(r.WFEdit);expected=json.loads((O/'lifecycle-before.json').read_text());assert len(data)==len(expected)
  error=0
  for a,b in zip(expected,data):
   for key in ['key','input','output','deleted','order']:assert a[key]==b[key],(key,a,b)
   for field in ['base','final']:
    assert (a[field] is None)==(b[field] is None)
    if a[field] is not None:error=max(error,max(abs(a[field][i][j]-b[field][i][j]) for i in range(4) for j in range(3)))
  assert error<.002,error
  out.update(rows=len(data),max_matrix_error_WU=error,contact=json.loads(str(r.WFRoot.interactionsStatistics())))
 elif phase=='prepare-failure':
  r.execute('global CVBadBindings=#(),CVBadDoc;CVBadDoc=CyrusRecipeCapture WFRoot (WFRoot.logicalLayers()) "Failure fixture" bindingResult:CVBadBindings;cyrusRecipeEntryWrite (GardenRun+"failure-base.csrecipe.json") CVBadDoc (CyrusRecipeObject #(#("category","Test"),#("tags",#()),#("description",""))) "" undefined "" false')
  doc=json.loads((O/'failure-base.csrecipe.json').read_text(encoding='utf-8-sig'));definition=json.loads(doc['authored']['definitions'][0]);definition['source']['fingerprint']='0'*64;doc['authored']['definitions'][0]=json.dumps(definition,separators=(',',':'))
  (O/'failure-invalid.csrecipe.json').write_text(json.dumps(doc,separators=(',',':')),encoding='utf-8')
  (O/'failure-before.json').write_text(json.dumps({'layers':len(r.WFRoot.layerObjects),'nodes':len(list(r.objects)),'rows':rows(r.WFEdit),'epoch':int(r.WFRoot.procEpoch)},indent=2))
 elif phase=='validate-failure':
  before=json.loads((O/'failure-before.json').read_text());out['error']=(O/'failure-result.txt').read_text();assert 'Prepared source changed' in out['error'] or 'Prepared source or settings changed' in out['error'],out
  assert len(r.WFRoot.layerObjects)==before['layers'] and len(list(r.objects))==before['nodes']
  assert rows(r.WFEdit)==before['rows'],'Failed import changed the previous Edit/publication'
  out['retained_layers']=len(r.WFRoot.layerObjects);out['retained_rows']=len(before['rows'])
 out['status']='passed'
except Exception:out.update(status='failed',error=traceback.format_exc());raise
finally:(O/(phase+'.json')).write_text(json.dumps(out,indent=2))

from pathlib import Path
import json,math,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));phase=str(r.CVProfileCase);report={'phase':phase}
def matrix(m):return [[float(m[i][j]) for j in range(3)] for i in range(4)]
def snapshot(mod):
 return [{'key':int(x[0]),'input':str(x[3]),'output':str(x[4]),'deleted':bool(x[8]),'order':int(x[9]),'delta':matrix(x[10]),'base':None if x[11]==r.undefined else matrix(x[11]),'final':None if x[12]==r.undefined else matrix(x[12])} for x in r.cyrusEditInspect(mod,0,500)[3]]
def compare(expected,got):
 a=[x for x in expected if x['base'] is not None and not x['deleted']];b=[x for x in got if x['base'] is not None and not x['deleted']]
 a.sort(key=lambda x:(x['key'],x['order']));b.sort(key=lambda x:(x['key'],x['order']))
 assert len(a)==len(b),(len(a),len(b));error=0
 for x,y in zip(a,b):
  assert x['order']==y['order'] and x['input']==y['input'],(x,y)
  for field in ['base','final']:
   assert x[field] is not None and y[field] is not None,(field,x,y)
   error=max(error,max(abs(x[field][i][j]-y[field][i][j]) for i in range(4) for j in range(3)))
 assert error<.002,error
 assert sum(x['deleted'] for x in expected)==sum(x['deleted'] for x in got)
 old={x['output'] for x in expected if x['input']!=x['output']};new={x['output'] for x in got if x['input']!=x['output']};assert len(new)==len(old) and not old.intersection(new)
 return {'active_rows':len(a),'max_matrix_error_WU':error,'deleted':sum(x['deleted'] for x in got),'fresh_clones':len(new)}
try:
 if phase in ('import-settings','validate-settings'):
  (O/'expected-rows.json').write_text(json.dumps(snapshot(r.WFEdit),indent=2))
  if phase=='import-settings':r.execute('CVImported=CyrusRecipeImport undefined CVDocument CVBindings newSetup:true calculate:true variation:#new')
  imported=r.CVImported[0];mod=imported.procModifiers()[0]
  report.update(compare(json.loads((O/'expected-rows.json').read_text()),snapshot(mod)))
  assert str(imported.interactionError)==''
  assert len(imported.layerObjects[0].interactionDefinitions)==1
  assert len(imported.layerObjects[1].interactionProxyNodes)==1
  report['contact']=json.loads(str(imported.interactionsStatistics()))
  report['fresh_owners']=all(str(a.layerID)!=str(b.layerID) for a,b in zip(r.WFRoot.layerObjects,imported.layerObjects));assert report['fresh_owners']
  assert all(str(a.procSourceIDs[0])!=str(b.procSourceIDs[0]) for a,b in zip(r.WFRoot.layerObjects,imported.layerObjects))
  r.execute('select CVImported[3];modPanel.setCurrentObject CVImported[1];CyrusPointSync();completeRedraw()')
 elif phase=='poll-save':
  job=r.CyrusSharedProgressData;state=str(r.CyrusSharedPollSave(job));report.update(state=state,error=str(job.error),path=str(job.store.RecipePaths()[0]))
  assert state=='complete',report
  (O/'saved-entry.json').write_text(json.dumps(report,indent=2))
 elif phase=='import-ready':
  entry=json.loads((O/'saved-entry.json').read_text());path=entry['path'];digest=str(r.cyrusRecipeInfo(path)[10]);package_dir=str(r.CyrusPresetPackageDirectory(path,digest))
  report['directory']=package_dir
  r.execute('if CyrusRecipeSaveEditor!=undefined do destroyDialog CyrusRecipeSaveEditor;if CyrusSharedProgressEditor!=undefined do destroyDialog CyrusSharedProgressEditor')
  r.resetMaxFile(r.Name('noPrompt'));r.ColorPipelineMgr.Mode=r.Name('OCIO_Default')
  # Same receiving plane, detached from the original scene, proves asset restoration.
  terrain=r.Plane(length=400,width=400,lengthsegs=4,widthsegs=4,pos=r.Point3(787.712,-1073.92,0),name='Recipe08744_NewTerrain')
  r.CVTerrain=terrain
  r.CyrusOpenReadyPreset(r.undefined,package_dir,surface=terrain)
 elif phase=='poll-ready':
  status=str(r.CyrusReadyPresetEditor.status.text);report['status_text']=status;assert 'new layers added' in status,status
  owners=[n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined];assert len(owners)==1
  r.WFOwner=owners[0];r.WFRoot=owners[0].baseObject;r.WFEdit=r.WFRoot.procModifiers()[0]
  assert not str(r.WFRoot.interactionError),str(r.WFRoot.interactionError)
  report['edit_rows']=snapshot(r.WFEdit)
  assert sum(x['deleted'] for x in report['edit_rows'])==1
  assert sum(x['input']!=x['output'] for x in report['edit_rows'])==1
  assert len(r.WFRoot.layerObjects[0].interactionDefinitions)==1
  assert len(r.WFRoot.layerObjects[1].interactionProxyNodes)==1
  report['contact']=json.loads(str(r.WFRoot.interactionsStatistics()))
  r.execute('destroyDialog CyrusReadyPresetEditor;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot;CyrusPointSync();completeRedraw()')
  r.saveMaxFile(str(O/'Ready_Roundtrip_08744.max'),quiet=True)
 report['status']='passed'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(O/(phase+'.json')).write_text(json.dumps(report,indent=2))

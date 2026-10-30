from pathlib import Path
from pymxs import runtime as r
import builtins,json,traceback,time
RUN=Path('F:/Cursor/_Cyrus_Apps/CyrusScatter/build/edit-size-review-20261029-01');OUT=Path(str(r.GardenRun));report={'status':'running','passed':[]}
def write():(OUT/'violet-qualification.json').write_text(json.dumps(report,indent=2))
def info():return json.loads(str(r.cyrusPreparationEditorInfo()))
def definition():return json.loads(str(r.cyrusPreparationEditorDefinition()))
def command(op,**values):r.cyrusPreparationEditorCommand(json.dumps(dict(op=op,**values)))
def check(value,name):
 if not value:raise AssertionError(name)
 report['passed'].append(name);write()
def ready():
 end=time.monotonic()+45
 while info().get('busy'):
  if time.monotonic()>end:raise TimeoutError(info())
  yield
 check(info()['ready'],'latest preparation is ready')
def guide(data,part):
 m=data['source']['metadata'];return m['guides'][m['parts'][part]['guide']]
def campaign():
 try:
  yield from ready();base=definition();report['baseline']=info();check(int(r.cyrusInteractionVersion())==17,'matched native interaction capability 17')
  check(base['source']['metadata']['triangles']==17110 and len(base['source']['metadata']['parts'])==197 and len(base['source']['metadata']['guides'])==12,'exact artist Violet baseline: 197 pieces / 17110 faces / 12 guides')
  before=info();command('select',parts=[1]);yield;after=info();check(after['analyses']==before['analyses'] and after['geometry_uploads']==before['geometry_uploads'],'selection alone does not prepare or upload geometry')
  command('detail',points=16);yield from ready();detail=definition();check(len(guide(detail,1)['nodes'])==16,'selected flower stem has 16 guide points')
  for p in [2,3,4,6,7,8,9,11,12,13,14]:check(guide(detail,p)['nodes']==guide(base,p)['nodes'],f'untouched stem {p} retains its exact guide')
  check(len(detail['source']['metadata']['guides'])==12,'stem detail does not convert leaves or petals into guides')
  command('undo');yield from ready();check(len(guide(definition(),1)['nodes'])==3,'draft Undo restores automatic stem detail')
  command('redo');yield from ready();check(len(guide(definition(),1)['nodes'])==16,'draft Redo restores 16-point stem')
  old=definition()
  try:command('detail',points=17)
  except Exception:pass
  else:raise AssertionError('Invalid detail admitted')
  check(definition()==old,'out-of-range detail retains the complete draft')
  command('select',parts=list(range(15,77)));command('profile',profile=2);yield from ready();command('detail',points=9);yield from ready();leaves=definition()
  check(len(leaves['source']['metadata']['guides'])==74,'all 62 selected leaves have independent guides')
  check(all(len(guide(leaves,p)['nodes'])==9 and leaves['source']['metadata']['parts'][p]['stem'] for p in range(15,77)),'selected leaf detail is independent of stem detail')
  check(len(guide(leaves,1)['nodes'])==16 and len(guide(leaves,2)['nodes'])==3,'leaf detail leaves both edited and automatic stem settings intact')
  command('select',parts=list(range(77,197)));command('profile',profile=3);yield from ready();flowers=definition()
  check(all(not flowers['source']['metadata']['parts'][p]['stem'] and flowers['source']['metadata']['parts'][p]['profile']==3 for p in range(77,197)),'all selected flower heads follow stems as rigid pieces')
  check(flowers['format']==3 and flowers['source']['format']==3 and flowers['source']['authoring']['version']==2,'saved profile/detail envelope and intent guards agree')
  command('select',parts=[0]);command('profile',profile=1)
  while info().get('busy'):yield
  check(not info()['ready'],'unsupported tiny piece blocks accepting an incomplete successor')
  command('undo');yield from ready();check(definition()['source']['authoring']==flowers['source']['authoring'],'Undo after failed analysis restores the complete intended preparation')
  command('select',parts=list(range(15,77)));command('isolate');command('frame');yield
  report['prepared']=info();(OUT/'prepared-definition.json').write_text(json.dumps(definition(),indent=2))
  epoch=int(r.VRoot.procEpoch);r.VLayer.amount=5;r.VLayer.markInputDirty();check(r.CyrusPreparationEditorCommit(),'Use preparation commits the staged source')
  yield;check(not info()['open'] and int(r.VRoot.procEpoch)==epoch and int(r.VLayer.generatedCount)==3,'accepting preparation leaves Manual amount changes pending')
  stored=str(r.VLayer.interactionDefinitions[-1]);r.CyrusOpenPreparationEditor(r.VLayer,r.VSource);yield from ready();check(definition()['source']['authoring']==flowers['source']['authoring'],'reopening editor restores profiles, point counts and parents');r.cyrusPreparationEditorClose()
  path=OUT/'Violet-08767-authored.max';check(r.saveMaxFile(str(path),quiet=True),'save authored preparation scene');yield
  check(r.loadMaxFile(str(path),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg')),'reopen authored preparation scene');yield
  r.execute('VNode=getNodeByName "Owned Violet preparation 08767";VRoot=VNode.baseObject;VLayer=VRoot.layerObjects[1];VSource=getNodeByName "SOURCE | A062 | Common Blue Violet - 04"')
  check(str(r.VLayer.interactionDefinitions[-1])==stored,'scene roundtrip retains exact serialized preparation')
  r.CyrusOpenPreparationEditor(r.VLayer,r.VSource);yield from ready();check(len(definition()['source']['metadata']['guides'])==74,'reopened scene reconstructs all 74 guides')
  command('select',parts=list(range(15,77)));command('isolate');command('frame');report['status']='complete';write()
 except Exception:report.update(status='failed',error=traceback.format_exc());write()
_campaign=campaign()
def tick():
 r.VCampaignTimer.Stop()
 try:next(_campaign);r.VCampaignTimer.Start()
 except StopIteration:pass
builtins._cyrus_violet_campaign_tick=tick
r.execute('''global VCampaignTimer=dotNetObject "System.Windows.Forms.Timer"
VCampaignTimer.Interval=250
fn VCampaignTick sender args = (python.Execute "import builtins; builtins._cyrus_violet_campaign_tick()")
dotNet.addEventHandler VCampaignTimer "Tick" VCampaignTick
VCampaignTimer.Start()''')

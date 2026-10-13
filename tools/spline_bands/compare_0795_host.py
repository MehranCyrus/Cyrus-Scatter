"""Equivalent fresh scenes in matched 0.79.5 and current owned Max hosts.

No cross-version scene loading. Synchronous timings, not presented FPS.
"""
from pathlib import Path
import hashlib,json,statistics,time,traceback,uuid
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-spline-')
report={'checks':[],'samples':{},'launch':json.loads((OUT/'launch.json').read_text()),'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
receipt=OUT/('compare-0795-'+uuid.uuid4().hex+'.json')
def save():receipt.write_text(json.dumps(report,indent=2)+'\n')
def check(ok,label):
 report['checks'].append({'passed':bool(ok),'label':label});save()
 if not ok:raise AssertionError(label)
def ms(code):return r.execute('('+code+')')
def timed(label,call,count=7):
 samples=[]
 for i in range(count):
  start=time.perf_counter();call(i);samples.append((time.perf_counter()-start)*1000)
 report['samples'][label]={'samples_ms':samples,'median_ms':statistics.median(samples),'max_ms':max(samples)};save()
def state():
 root=r.CompareRoot
 return {'epoch':int(root.procEpoch),'prepared':[int(l.procPreparedBuilds) for l in root.layerObjects],
 'preview':[int(l.previewBuildCount) for l in root.layerObjects],
 'fingerprints':[str(r.cyrusEditFingerprint(rows,'compare0795')) for rows in root.groupSnapshotRows],
 'retained':list(map(int,list(r.cyrusRetainedStats(r.CyrusPointOwner(r.CompareNode)))[:12]))}
def same(a,b):return all(a[k]==b[k] for k in ['epoch','prepared','preview','fingerprints']) and a['retained'][:7]==b['retained'][:7]
try:
 r.resetMaxFile(r.Name('noPrompt'))
 start=time.perf_counter()
 ms('''global CompareNode=AminScatterObject name:"Equivalent 0795 comparison"
 global CompareRoot=CompareNode.baseObject
 CompareRoot.updateMode=1;CompareRoot.autoRender=false
 global CompareSurface=plane width:500 length:500 widthsegs:8 lengthsegs:8
 global CompareSources=#(box width:3 length:3 height:8 pos:[600,0,0],sphere radius:3 segments:16 pos:[620,0,0])
 for n=1 to 3 do (CompareRoot.newLayer();local leaf=CompareRoot.selectedLayer()
 CompareRoot.setLayerSurfaces leaf #(CompareSurface);leaf.sources=CompareSources
 leaf.amount=10000;leaf.randomSeed=n*137;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false)
 CompareRoot.setGroupDisplay 4
 hide (CompareSources+#(CompareSurface));clearSelection()
 viewport.setType #view_top;viewport.setGridVisibility #all false
 viewport.ZoomToBounds false [-260,-260,-10] [260,260,40]''')
 report['scene_setup_ms']=(time.perf_counter()-start)*1000
 report['version']=str(r.CompareRoot.uiVersion())
 timed('cold_calculation',lambda _:r.CompareRoot.evaluateProcedural(),1)
 timed('warm_explicit_update',lambda _:r.CompareRoot.evaluateProcedural())
 check(all(len(rows)==10000 for rows in r.CompareRoot.groupSnapshotRows),'Three layers each retain 10,000 placements')
 r.CyrusPerfHeadless=False;ms('CyrusPointSync();completeRedraw();windows.processPostedMessages();completeRedraw()')
 for mode in [4,3]:
  r.CompareRoot.setGroupDisplay(mode);ms('CyrusPointSync();completeRedraw();completeRedraw()')
  before=state();view=r.viewport.getTM()
  timed('point_navigation' if mode==4 else 'mesh_navigation',lambda i:(r.viewport.setTM(r.rotateZMatrix(.1*(i+1))*view),r.completeRedraw()),20)
  after=state();report['samples']['point_navigation' if mode==4 else 'mesh_navigation'].update(before=before,after=after)
  check(same(before,after),f'Display {mode}: navigation has zero solves, preparations, preview rebuilds or uploads')
  r.viewport.setTM(view)
 before=state()
 timed('cold_modify_mount',lambda _:ms('select CompareNode;max modify mode;if not CompareRoot.mainUI.controlsReady do CompareRoot.mainUI.mountTimer.tick()'),1)
 def bind(_):
  ms('CompareRoot.modelsUI.open=true;CompareRoot.mainUI.bindSection CompareRoot.modelsUI;CompareRoot.layoutUI.open=true;CompareRoot.mainUI.bindSection CompareRoot.layoutUI')
 timed('first_models_layout_bind',bind,1);timed('warm_models_layout_bind',bind,10)
 check(same(before,state()),'Mount and panel binding preserve caches and placements')
 timed('warm_layout_mode_switch',lambda i:ms(f'CompareRoot.layoutUI.diversityUI_diversityRadio.state={1+i%2};CompareRoot.layoutUI.diversityUI_diversityRadio.changed {1+i%2}'),10)
 check(int(r.CompareRoot.procEpoch)==before['epoch'],'Manual mode switches preserve generation')
 ms('CompareRoot.layoutUI.diversityUI_diversityRadio.state=1;CompareRoot.layoutUI.diversityUI_diversityRadio.changed 1;CompareRoot.evaluateProcedural()')
 before=state();ms('CompareRoot.layerObjects[1].amount=10001;CompareRoot.refreshDisplay();completeRedraw()')
 check(before['fingerprints']==state()['fingerprints'] and before['epoch']==state()['epoch'],'Manual amount edit retains last publication')
 r.CompareRoot.evaluateProcedural()
 check(len(r.CompareRoot.groupSnapshotRows[0])==10001,'Explicit Update applies pending amount')
 ms('CompareRoot.updateMode=2;global CompareUnrelated=box pos:[1000,1000,1000];completeRedraw()')
 before=state()
 timed('live_unrelated_edit',lambda i:ms(f'CompareUnrelated.pos.x={1001+i};completeRedraw();windows.processPostedMessages()'),10)
 check(same(before,state()),'Live unrelated edits preserve placements and retained buffers')
 scene=OUT/'Equivalent-comparison.max'
 before=state()
 timed('save_scene',lambda _:r.saveMaxFile(str(scene),quiet=True),1)
 timed('load_scene',lambda _:r.loadMaxFile(str(scene),quiet=True),1)
 ms('global CompareNode=getNodeByName "Equivalent 0795 comparison";global CompareRoot=CompareNode.baseObject;CompareRoot.refreshAll();CyrusPointSync();completeRedraw()')
 check(before['fingerprints']==state()['fingerprints'],'Same-version save/reload reconstructs identical placements')
 report['passed']=True
except Exception:report['passed']=False;report['error']=traceback.format_exc()
finally:save()
if not report['passed']:raise RuntimeError(report['error'])

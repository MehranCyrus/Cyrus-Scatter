"""Cold Layout host visibility regression; physical radio acceptance is separate."""
from pathlib import Path
import hashlib,json,time,traceback,uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-spline-ui-refresh-firstclick-')
started=time.perf_counter()
report={'checks':[],'launch':json.loads((OUT/'launch.json').read_text())}
receipt=OUT/('first-click-'+uuid.uuid4().hex+'.json')
def save():receipt.write_text(json.dumps(report,indent=2)+'\n')
def check(value,label):
 report['checks'].append({'passed':bool(value),'label':label,'elapsed_ms':(time.perf_counter()-started)*1000});save()
 if not value:raise AssertionError(label)
def ms(code):return r.execute('('+code+')')
def visible(control):return any(r.windows.isWindowVisible(h) for h in control.hwnd)
try:
 check(hashlib.sha256((ROOT/'AminScatter/scripts/AminScatterObject.ms').read_bytes()).hexdigest()==report['launch']['script_sha256'],'Current generated source matches owned startup')
 r.resetMaxFile(r.Name('noPrompt'))
 ms('''global ColdNode=AminScatterObject name:"Cold Layout regression"
 global ColdRoot=ColdNode.baseObject;ColdRoot.updateMode=1;ColdRoot.autoRender=false;ColdRoot.newLayer()
 global ColdLeaf=ColdRoot.selectedLayer()
 ColdRoot.setLayerSurfaces ColdLeaf #(plane width:500 length:500)
 ColdLeaf.addPointSource();ColdLeaf.amount=2000;ColdRoot.evaluateProcedural()
 select ColdNode;max modify mode
 if not ColdRoot.mainUI.controlsReady do ColdRoot.mainUI.mountTimer.tick()
 ColdRoot.layoutUI.open=true;ColdRoot.mainUI.bindSection ColdRoot.layoutUI
 completeRedraw();windows.processPostedMessages()''')
 epoch=int(r.ColdRoot.procEpoch)
 for view in ['inline','container']:
  if view=='inline':p=r.ColdRoot.layoutUI
  else:
   ms('global ColdContainer=ColdLeaf.containerCreate();ColdLeaf.containerMode=1;select ColdContainer;max modify mode;if not ColdContainer.mainUI.controlsReady do ColdContainer.mainUI.mountTimer.tick();ColdContainer.layoutUI.open=true;ColdContainer.mainUI.bindSection ColdContainer.layoutUI')
   p=r.ColdContainer.layoutUI
  r.ColdPage=p
  for mode in [1,2,3,4,1]:
   p.diversityUI_diversityRadio.state=mode
   ms(f'ColdPage.diversityUI_diversityRadio.changed {mode}')
   for name in ['strokesList','strokeChoices']:
    control=getattr(p,'diversityUI_'+name+'_colored')
    check(bool(control.visible)==(mode>=3) and visible(control)==(mode>=3),f'{view} mode {mode}: {name} child and native host visibility agree')
    check(visible(getattr(p,'diversityUI_'+name+'_grip'))==(mode>=3),f'{view} mode {mode}: {name} resize host visibility agrees')
   check(not p.diversityUI_fieldLegend.visible and not p.diversityUI_strokeHelp.visible,f'{view} mode {mode}: help paragraphs remain removed')
  check(int(r.ColdRoot.procEpoch)==epoch,f'{view}: pending Manual choices retain generation')
 # Remount a fresh Random view, with no preceding Analyzer or Spline selection.
 r.clearSelection();r.select(r.ColdNode);ms('max modify mode')
 if not r.ColdRoot.mainUI.controlsReady:r.ColdRoot.mainUI.mountTimer.tick()
 r.ColdRoot.layoutUI.open=True;r.ColdRoot.mainUI.bindSection(r.ColdRoot.layoutUI)
 for name in ['strokesList','strokeChoices']:
  check(not visible(getattr(r.ColdRoot.layoutUI,'diversityUI_'+name+'_colored')),'Fresh Random mount hides native '+name+' host')
 r.saveMaxFile(str(OUT/('Cold-first-click-Max'+str(report['launch']['max_year'])+'.max')),quiet=True)
 report['passed']=True
except Exception:report['passed']=False;report['error']=traceback.format_exc()
finally:save()
if not report['passed']:raise RuntimeError(report['error'])

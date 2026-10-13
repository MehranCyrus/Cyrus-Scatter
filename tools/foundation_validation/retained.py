"""Actual Nitrous admission/reuse checks in a disposable matched Max host."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-'):
    raise RuntimeError('Owned foundation host required')
report={'assertions':[],'errors':[]}
def write(): (OUT/'retained-results.json').write_text(json.dumps(report,indent=2)+'\n')
def check(ok,label):
    report['assertions'].append({'passed':bool(ok),'label':label});write()
    if not ok:raise AssertionError(label)
def arr(values):return r.Array(*values)
def stats(owner):return list(r.cyrusRetainedStats(owner))
def redraw():
    r.execute('for i=1 to 3 do (completeRedraw();windows.processPostedMessages();sleep .05)')
try:
    r.CyrusStopBrush();r.resetMaxFile(r.Name('noPrompt'))
    r.fileIn(str(ROOT/'AminScatter/scripts/AminScatterObject.ms'))
    report['initial_redraw_disabled']=bool(r.isSceneRedrawDisabled())
    # Earlier failed load probes may leave Max's outer load redraw lock held.
    # Repair only this disposable host's pre-test state, never mid-scenario.
    for _ in range(16):
        if not r.isSceneRedrawDisabled():break
        r.enableSceneRedraw()
    check(not r.isSceneRedrawDisabled(),'Owned host redraw enabled before the scenario')
    r.execute('''fn FoundationPointCache groups = (
      local data=for i=1 to groups collect #((transMatrix [(mod i 20)*2.,(floor (i/20.))*2.,0]),i,(i as integer64),1,[1,0,0],0,false,2)
      aminScatterBuildPreview data (for i=1 to groups collect #([0,0,0])) #(1,1,(for i=1 to groups collect white),#(),false) 500000
    )''')
    controller=r.box(name='Native publication controller',width=100.,length=100.,height=1.)
    owner=r.cyrusRetainedCreate();check(owner is not None,'Retained API available')
    r.hideByCategory.helpers=False
    r.viewport.setType(r.Name('view_top'))
    r.viewport.ZoomToBounds(False,r.Point3(-100.,-100.,-10.),r.Point3(100.,100.,10.));redraw()
    first=r.FoundationPointCache(3);styles=arr([arr([False,r.color(255,255,255)])])
    check(r.cyrusRetainedPublish(owner,controller,arr([first]),styles),'Initial generation publishes')
    redraw()
    before=stats(owner);report['before']=list(map(str,before))
    check(r.cyrusRetainedMatches(owner,arr([first]),styles),'Initial native generation is submitted and enabled')
    excessive=r.FoundationPointCache(1025)
    check(not r.cyrusRetainedPublish(owner,controller,arr([excessive]),styles),'Native group admission rejects 1025 groups')
    after=stats(owner);report['after_rejection']=list(map(str,after))
    check(all(before[i]==after[i] for i in [0,1,2,9,10,11,12]),'Rejected successor retains counts, revision, items, reservation, readiness and content')
    check(int(after[8])==int(before[8])+1,'Admission failure is observable')
    check(r.cyrusRetainedMatches(owner,arr([first]),styles),'Rejected successor keeps preceding generation enabled')
    redraw()
    check(stats(owner)[5]==before[5],'Retained old generation does not upload again after rejection')
    replacement=r.FoundationPointCache(4)
    check(r.cyrusRetainedPublish(owner,controller,arr([replacement]),styles),'Valid successor recovers after rejection')
    redraw()
    check(int(stats(owner)[0])==4 and int(stats(owner)[2])==int(before[2])+1,'Recovery commits exactly one successor')
    # Two shared snapshots, then only one changes: unchanged item buffers reuse.
    sibling=r.FoundationPointCache(1);both=arr([replacement,sibling]);two_styles=arr([styles[0],styles[0]])
    check(r.cyrusRetainedPublish(owner,controller,both,two_styles),'Two-layer native publication')
    redraw();before=stats(owner)
    changed=r.FoundationPointCache(2)
    check(r.cyrusRetainedPublish(owner,controller,arr([changed,sibling]),two_styles),'One changed native layer publishes')
    redraw();after=stats(owner)
    report['partial_uploads']=int(after[5])-int(before[5])
    check(report['partial_uploads']==4,'Only positions/owners for the two changed point groups upload; sibling buffers reuse')
    check(r.cyrusRetainedPublish(owner,controller,arr([changed,sibling]),two_styles),'Unchanged generation reuse succeeds')
    r.completeRedraw();check(stats(owner)[2]==after[2] and stats(owner)[5]==after[5],'Unchanged inputs add no publication or upload')
    check(not r.isSceneRedrawDisabled(),'Scenario leaves redraw enabled')
    report['passed']=True
except Exception:
    report['passed']=False;report['errors'].append(traceback.format_exc())
finally:write()
if not report.get('passed'):raise RuntimeError(report['errors'][-1])

"""Verify and save the real nine-layer garden in the final matched 2027 host."""
from pathlib import Path
import json,time,statistics,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve();SCENES=ROOT/'Test Scene/Terraces_0815'
assert OUT.name=='foundation-terrace0815-candidate2027-04'
REPORT=OUT/'garden-final-acceptance.json';data={'status':'started','checks':[],'timings':{}}
def save():REPORT.write_text(json.dumps(data,indent=2)+'\n')
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def fp(root):return [str(r.cyrusEditFingerprint(rows,'garden-final815')) for rows in root.groupSnapshotRows]
def state(root):return {'epoch':int(root.procEpoch),'fingerprints':fp(root),'prepared':[int(l.procPreparedBuilds) for l in root.layerObjects],'counts':[int(l.generatedCount) for l in root.layerObjects]}
def timed(name,fn,n=1):
    values=[]
    for i in range(n):
        start=time.perf_counter();fn(i);values.append((time.perf_counter()-start)*1000)
    data['timings'][name]={'ms':values,'median_ms':statistics.median(values)};save()
def redraw():r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages()
try:
    r.CyrusPerfHeadless=True;r.clearSelection()
    timed('load_planting05',lambda i:r.loadMaxFile(str(SCENES/'Terraces_0815_Planting_05.max'),quiet=True,useFileUnits=True))
    node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject;root.autoRender=False
    check(str(root.uiVersion())=='0.81.5' and int(r.cyrusSplineBandVersion())==10,'Final script/native interface matched')
    timed('explicit_first_update',lambda i:root.refreshAll())
    before=state(root);data['baseline']=before
    check(before['counts']==[220000,3590,5730,15342,725,22,5,163,87],'All nine planting populations reconstruct at saved counts')
    check(all(not str(l.previewError) for l in root.layerObjects),'All nine populations have no publication error')
    r.CyrusPerfHeadless=False;r.viewport.setCamera(r.getNodeByName('PhysCamera002'));r.execute('max modify mode');redraw()
    owner=r.CyrusPointOwner(node);native=list(r.cyrusRetainedStats(owner));data['retained_before']=[str(v) for v in native]
    rectangles=list(root.containerGlobalNodes)
    for l in root.layerObjects:rectangles+=list(l.containerNodes)
    rectangles=[n for n in rectangles if r.isValidNode(n)]
    check(len(rectangles)>=7,'Layer and global palettes remain available')
    def select(i):
        n=rectangles[i%len(rectangles)];r.select(n);redraw()
        check(bool(n.baseObject.containerUI.controlsReady),'Compact rectangle editor opens '+str(i))
    timed('real_scene_rectangle_selection',select,8)
    after=list(r.cyrusRetainedStats(owner));data['retained_after']=[str(v) for v in after]
    check(state(root)==before,'Rectangle selection preserves all placements, epochs and preparation counts')
    check(all(native[i]==after[i] for i in [3,5,6]),'Rectangle selection reuses native preparation and uploaded buffers')
    # evaluateGroups is an explicit solver entry point; ordinary render/display
    # readers use procReadSnapshot so Manual pending work stays unpublished.
    timed('warm_snapshot_reads',lambda i:root.procReadSnapshot(),5)
    check(state(root)==before,'Warm evaluation preserves publication and prepared data')
    timed('layer_selection',lambda i:root.selectLayer(i+1),len(root.layerObjects))
    check(state(root)==before,'Browsing every layer does not recalculate placements')
    # A real Manual pending edit must not be implicitly published by browsing.
    grass=root.layerObjects[0];old=int(grass.amount);grass.amount=old+1;grass.markInputDirty()
    root.procReadSnapshot();redraw()
    check(state(root)==before,'Manual Amount edit waits for explicit Update')
    timed('update_one_changed_layer',lambda i:root.refreshAll())
    changed=state(root)
    check(changed['counts'][0]==220001 and changed['fingerprints'][1:]==before['fingerprints'][1:],'Explicit Update changes grass and preserves all eight sibling placements')
    grass.amount=old;grass.markInputDirty();root.refreshAll()
    check(fp(root)==before['fingerprints'],'Restoring Amount reproduces all original IDs and transforms')
    root.selectLayer(1);r.clearSelection();r.CyrusPerfHeadless=False
    # Parked source models are accessible in the viewport; never render as originals.
    used=[]
    for l in root.layerObjects:
        for n in l.validSources():
            if not any(n==x for x in used):used.append(n)
    for n in used:n.renderable=False;r.unhide(n)
    root.autoRender=True;r.renderWidth=1920;r.renderHeight=1080;r.renderers.current.progressive_passLimit=8
    r.viewport.setCamera(r.getNodeByName('PhysCamera002'));redraw()
    data['layers']=[{'name':str(root.layerNames[i]),'requested':int(l.amount),'accepted':int(l.generatedCount),'sources':[str(n.name) for n in l.validSources()],'error':str(l.previewError)} for i,l in enumerate(root.layerObjects)]
    data['total_accepted']=sum(int(l.generatedCount) for l in root.layerObjects)
    expected=fp(root);target=SCENES/'Terraces_0815_Final.max'
    timed('save_final',lambda i:r.saveMaxFile(str(target),quiet=True))
    r.CyrusPerfHeadless=True;timed('reopen_final',lambda i:r.loadMaxFile(str(target),quiet=True,useFileUnits=True))
    node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject;root.autoRender=False
    timed('reopened_explicit_update',lambda i:root.refreshAll())
    check(fp(root)==expected,'Final save/reopen preserves every placement identity and transform')
    check(all(not str(l.previewError) for l in root.layerObjects),'Reopened final scene has no Scatter errors')
    missing=[]
    for m in r.getClassInstances(r.Bitmaptexture):
        path=str(m.filename)
        if path and not r.doesFileExist(path):missing.append(path)
    data['missing_bitmap_paths']=missing;check(not missing,'All bitmap file references resolve after reopen')
    root.autoRender=True;r.CyrusPerfHeadless=False;r.viewport.setCamera(r.getNodeByName('PhysCamera002'));redraw()
    data['render_properties']=[str(p) for p in r.getPropNames(r.renderers.current) if 'denois' in str(p).lower()]
    data['status']='complete';data['scene']=str(target)
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

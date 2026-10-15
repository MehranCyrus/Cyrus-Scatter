"""Measure real compact rectangle selection/creation and test palette movement."""
from pathlib import Path
import json,time,statistics,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-candidate')
data={'checks':[],'timings':{},'status':'started'}
def write():(OUT/'containers-host.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label});write()
    if not ok:raise AssertionError(label)
def timed(label,fn,n=5):
    values=[]
    for i in range(n):
        start=time.perf_counter();fn(i);values.append((time.perf_counter()-start)*1000)
    data['timings'][label]={'ms':values,'median_ms':statistics.median(values)};write()
def fingerprint(root):return [str(r.cyrusEditFingerprint(rows,'container0815')) for rows in root.groupSnapshotRows]
try:
    node=r.getNodeByName('Capacity 0.81.5');root=node.baseObject;leaf=root.layerObjects[0]
    before={'epoch':int(root.procEpoch),'fingerprints':fingerprint(root),'prepared':int(leaf.procPreparedBuilds)}
    r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    root.containersUI.open=True;root.mainUI.bindSection(root.containersUI)
    root.surfacesUI.open=True;root.mainUI.bindSection(root.surfacesUI)
    check(root.containersUI.sourceContainersUI_controlsReady and root.surfacesUI.flow_surfaceUI_controlsReady,'Opened bound creation controls')
    timed('create_layer_button',lambda i:root.containersUI.sourceContainersUI_createContainer.pressed(),2)
    timed('create_global_button',lambda i:root.surfacesUI.flow_surfaceUI_createContainer.pressed(),2)
    check(len(leaf.containerNodes)==2 and len(root.containerGlobalNodes)==2,'Both buttons created the requested rectangles')
    rectangles=list(leaf.containerNodes)+list(root.containerGlobalNodes)
    r.clearSelection();r.windows.processPostedMessages()
    def select(i):
        n=rectangles[i%len(rectangles)];r.select(n);r.windows.processPostedMessages()
        check(bool(n.baseObject.containerUI.controlsReady),'Compact properties open on selection '+str(i))
    timed('rectangle_selection_and_posted_messages',select,8)
    check(int(root.procEpoch)==before['epoch'] and fingerprint(root)==before['fingerprints'] and int(leaf.procPreparedBuilds)==before['prepared'],'Create and selection retain Manual results')
    r.clearSelection();r.execute('max create mode');r.CyrusPerfHeadless=True
    active=rectangles[2];active.pos=r.Point3(-1000,0,0);active.width=1000;active.length=1000
    leaf.containerSetMode(3);active.collectEnabled=True
    models=[]
    for i in range(250):models.append(r.box(name='Palette test '+str(i),length=1,width=1,height=1,pos=r.Point3(-1000+(i%20)*2,(i//20)*2,0)))
    leaf.containerScan=True;leaf.containerRefresh();r.CyrusContainerRefreshAll()
    check(all(any(x==n for x in leaf.sources) for n in models),'Global collection registers 250 source pivots')
    timed('active_250_full_refresh',lambda i:r.CyrusContainerRefreshAll())
    timed('active_250_labels_only',lambda i:r.CyrusContainerRefreshLabels(root))
    timed('active_250_unchanged_membership',lambda i:leaf.containerRefresh())
    positions=[r.copy(n.pos) for n in models];original=r.copy(active.pos)
    r.execute('global TerraceMovingRectangle');r.TerraceMovingRectangle=active
    r.execute('(undo "Terrace container translation" on TerraceMovingRectangle.pos += [75,0,0])')
    check(all(float(r.distance(n.pos,p+r.Point3(75,0,0)))<.01 for n,p in zip(models,positions)),'Whole-node translation carries all owned models')
    r.execute('max undo')
    check(float(r.distance(active.pos,original))<.01 and all(float(r.distance(n.pos,p))<.01 for n,p in zip(models,positions)),'Undo restores rectangle and source transforms')
    r.execute('max redo')
    check(all(float(r.distance(n.pos,p+r.Point3(75,0,0)))<.01 for n,p in zip(models,positions)),'Redo restores the complete translated palette')
    previous=[r.copy(n.pos) for n in models];active.width=1200;r.CyrusContainerRefreshAll()
    check(all(float(r.distance(n.pos,p))<.01 for n,p in zip(models,previous)),'Resizing changes the boundary without moving sources')
    r.CyrusPerfHeadless=False;r.CyrusPointSync();r.completeRedraw()
    helper=r.CyrusPointOwner(node);native=list(r.cyrusRetainedStats(helper));epoch=int(root.procEpoch)
    for i in range(8):r.select(rectangles[i%4]);r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages()
    after=list(r.cyrusRetainedStats(helper))
    data['retained_before']=[str(v) for v in native];data['retained_after']=[str(v) for v in after]
    check(int(root.procEpoch)==epoch and native[3]==after[3] and native[5]==after[5] and native[6]==after[6],'Repeated rectangle selection reuses native preparation and uploads')
    check(fingerprint(root)==before['fingerprints'],'Pending collection and movement edits retain the last Manual publication')
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:write()
if data['status']!='complete':raise RuntimeError(data['error'])

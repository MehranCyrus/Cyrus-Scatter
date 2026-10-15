"""Memory fallback, recovery, real controls and save/reopen on the terrace copy."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-viewport0816-')
data={'status':'started','checks':[],'states':{}}
node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject
def save():(OUT/'terrace-extra.json').write_text(json.dumps(data,indent=2)+'\n')
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def state():return {'policy':[int(x) for x in r.cyrusRetainedViewportStats(r.CyrusPointOwner(node))],'retained':[str(x) for x in r.cyrusRetainedStats(r.CyrusPointOwner(node))],'mesh':[int(x) for x in r.cyrusRetainedMeshStats(r.CyrusPointOwner(node))],'epoch':int(root.procEpoch),'fp':[str(r.cyrusEditFingerprint(rows,'garden-final815')) for rows in root.groupSnapshotRows],'errors':[str(l.previewError) for l in root.layerObjects],'error':str(r.CyrusPointLastError),'detail':str(r.CyrusPointDetailStatus),'fallback':[int(x) for x in r.cyrusPreviewFallbackStats()]}
try:
    baseline=state();root.viewportFaces=0;root.viewportNavigationFaces=0
    t=time.perf_counter();root.refreshDisplay();r.CyrusPointSync();r.completeRedraw();data['unlimited_switch_seconds']=time.perf_counter()-t
    unlimited=state();data['states']['unlimited']=unlimited
    check(unlimited['policy'][9]==1 and unlimited['policy'][7]==245664,'Memory admission reduces unlimited Mesh to cached boxes for every placement')
    check(unlimited['policy'][5]==245664*12 and unlimited['policy'][6]==245664*12,'Zero keeps all available boxes in both phases')
    check(unlimited['retained'][11]=='1' and not unlimited['error'] and not any(unlimited['errors']),'Reduced representation reaches ready GPU state')
    check(unlimited['fallback'][3]==baseline['fallback'][3],'Unlimited memory reduction adds zero CPU source triangles')
    check(unlimited['fp']==baseline['fp'] and unlimited['epoch']==baseline['epoch'],'Resource reduction preserves publication')
    root.viewportFaces=2000000;root.viewportNavigationFaces=500000;root.refreshDisplay();r.CyrusPointSync();r.completeRedraw()
    recovery=state();data['states']['recovery']=recovery
    check(recovery['retained'][11]=='1' and recovery['policy'][9]==0 and 0<recovery['policy'][5]<=2000000,'Finite Mesh recovers full geometry where it fits')
    # Exercise generated controls through the real rollout binding in both modes.
    r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    panel=root.displayUI;panel.open=True;root.mainUI.bindSection(panel)
    check(bool(panel.controlsReady),'Viewport rollout binds to the Scatter controller')
    panel.flow_previewUI_navigationFacesSpin.value=360000;panel.flow_previewUI_navigationFacesSpin.changed(360000)
    check(int(root.viewportNavigationFaces)==360000,'Navigating triangles control writes the controller setting')
    panel.flow_previewUI_faceLimitSpin.value=0;panel.flow_previewUI_faceLimitSpin.changed(0)
    check(int(root.viewportFaces)==0,'Idle triangles control accepts zero')
    root.viewportFaces=2000000;root.viewportNavigationFaces=500000;root.refreshDisplay();r.CyrusPointSync()
    r.clearSelection();r.execute('max create mode');r.CyrusPerfHeadless=True
    expected=state()['fp'];saved=OUT/'Terrace_0816_verified.max';r.saveMaxFile(str(saved),quiet=True)
    r.disableSceneRedraw();r.loadMaxFile(str(saved),quiet=True,useFileUnits=True)
    node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject;root.autoRender=False;r.CyrusPFTimer.Stop()
    root.refreshAll();r.CyrusPointSync();r.enableSceneRedraw();r.completeRedraw()
    reopened=state();data['states']['reopened']=reopened
    check(reopened['fp']==expected and int(root.viewportNavigationFaces)==500000 and int(root.viewportFaces)==2000000,'Terrace save/reopen preserves limits and exact placement identities/transforms')
    data['status']='complete'
except Exception:
    data['status']='failed';data['error']=traceback.format_exc()
    try:r.enableSceneRedraw()
    except:pass
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

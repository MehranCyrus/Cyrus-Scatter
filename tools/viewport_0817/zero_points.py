"""Large zero-limit point preparation and mode reuse, independent of terrace assets."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-viewport0817-')
data={'checks':[],'status':'started'}
def save():(OUT/'zero-points.json').write_text(json.dumps(data,indent=2)+'\n')
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def redraw():
    r.CyrusPointSync()
    for _ in range(3):r.completeRedraw();r.windows.processPostedMessages()
try:
    r.resetMaxFile(r.Name('noPrompt'));r.CyrusPerfHeadless=True
    node=r.AminScatterObject(name='Zero point capacity');root=node.baseObject;root.updateMode=1;root.autoRender=False
    receiver=r.plane(length=1000,width=1000,lengthsegs=1,widthsegs=1)
    source=r.box(length=2,width=2,height=5,pos=r.Point3(-2000,-2000,0))
    root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(receiver));leaf.sources=r.Array(source);leaf.containerMode=1
    leaf.amount=1000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False
    root.pointsPerPlant=10000;root.previewBudget=0;root.viewportNavigationPoints=0
    root.viewportInstances=0;root.viewportNavigationInstances=0;root.refreshAll();redraw()
    baseline=str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'zero-points'));epoch=int(root.procEpoch)
    values=[int(x) for x in r.cyrusRetainedViewportStats(r.CyrusPointOwner(node))];data['policy']=values
    check(int(leaf.generatedCount)==1000 and not str(leaf.previewError),'Ten million requested point samples retain all 1000 placements')
    check(values[1]==values[2]==int(r.cyrusViewportPointCapacity()),'Both zero phases draw the admitted point capacity')
    check('memory allowance' in str(r.CyrusPointDetailStatus),'Point resource reduction is visible')
    for proxy in [1,2,3]:
        root.proxyShape=proxy;root.setGroupDisplay(2);redraw();root.setGroupDisplay(1);redraw()
        check(int(leaf.uiPreviewMode)==1 and not str(leaf.previewError),'Return to Points from proxy '+str(proxy))
    check(int(root.procEpoch)==epoch and str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'zero-points'))==baseline,'Mode changes preserve publication')
    root.setGroupDisplay(4);redraw();values=[int(x) for x in r.cyrusRetainedViewportStats(r.CyrusPointOwner(node))]
    check(values[1]==values[2]==1000 and int(leaf.uiPreviewMode)==4,'Centres retain one point per placement')
    root.setGroupDisplay(1);redraw();check(int(leaf.uiPreviewMode)==1 and not str(leaf.previewError),'Cloud returns after Centres')
    check(len(leaf.procPreviewModes)==5,'Each point/proxy representation occupies one cache slot')
    data['resources']=[int(x) for x in r.cyrusPreviewResourceStats()];data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

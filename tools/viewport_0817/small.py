"""Exercise policy semantics, Manual ownership and persistence in an owned host."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-viewport0817-')
data={'status':'started','checks':[],'cases':[]}
def save():(OUT/'small.json').write_text(json.dumps(data,indent=2)+'\n')
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def arr(xs):return r.Array(*xs)
def pt(x,y,z=0):return r.Point3(float(x),float(y),float(z))
def fp():return [str(r.cyrusEditFingerprint(rows,'viewport0817')) for rows in root.groupSnapshotRows]
def policy():return [int(x) for x in r.cyrusRetainedViewportStats(r.CyrusPointOwner(node))]
def apply(mode):
    root.setGroupDisplay(mode);root.refreshDisplay();r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages()
try:
    r.resetMaxFile(r.Name('noPrompt'));r.CyrusPerfHeadless=True
    node=r.AminScatterObject(name='Viewport 0.81.7');root=node.baseObject;root.updateMode=1;root.autoRender=False
    check(str(root.uiVersion())=='0.81.7' and int(r.cyrusViewportPolicyVersion())==2,'Matched UI and viewport native capability')
    receiver=r.plane(length=1000,width=1000,lengthsegs=1,widthsegs=1)
    source=r.box(length=2,width=2,height=6,pos=pt(-2000,-2000))
    for count in [400,600]:
        root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,arr([receiver]));leaf.sources=arr([source]);leaf.containerMode=1
        leaf.amount=count;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.distributionMode=1
    root.pointsPerPlant=1;root.refreshAll();baseline=fp();epoch=int(root.procEpoch)
    check(sum(int(l.generatedCount) for l in root.layerObjects)==1000,'Two layers publish 1000 placements')
    for mode in [1,2,3]:
        # Deliberately make navigation larger than idle: preparation must serve both.
        root.previewBudget=100;root.viewportNavigationPoints=300
        root.viewportInstances=100;root.viewportNavigationInstances=300
        root.viewportFaces=1200;root.viewportNavigationFaces=3600
        apply(mode);stats=policy();data['cases'].append({'mode':mode,'limits':'finite','stats':stats});save()
        offset={1:1,2:3,3:5}[mode];unit=12 if mode==3 else 1
        check(stats[offset]==100*unit and stats[offset+1]==300*unit,'Independent idle/navigation controller totals, mode '+str(mode))
        root.previewBudget=0;root.viewportNavigationPoints=0;root.viewportInstances=0;root.viewportNavigationInstances=0;root.viewportFaces=0;root.viewportNavigationFaces=0
        apply(mode);stats=policy();data['cases'].append({'mode':mode,'limits':'unlimited','stats':stats});save()
        check(stats[offset]==1000*unit and stats[offset+1]==1000*unit,'Zero removes both display caps, mode '+str(mode))
        check(fp()==baseline and int(root.procEpoch)==epoch,'Display policy preserves complete placements, mode '+str(mode))
    # Face budget below one source: source must degrade to a box rather than disappear.
    dense=r.sphere(radius=10,segs=64,pos=pt(-2000,0));leaf=root.layerObjects[0];leaf.sources=arr([dense]);root.refreshAll()
    check(all(int(l.procPreviewModesEpoch)==int(root.procEpoch) and len(l.procPreviewModes)==1 for l in root.layerObjects),'New publication retires every previous-epoch representation cache')
    root.viewportFaces=120;root.viewportNavigationFaces=60;apply(3)
    stats=policy();check(0<stats[5]<=120 and 0<stats[6]<=60,'Oversized source remains represented within triangle caps')
    baseline=fp();epoch=int(root.procEpoch);leaf.amount=401
    root.viewportNavigationFaces=24;apply(3)
    check(fp()==baseline and int(root.procEpoch)==epoch and int(leaf.generatedCount)==400,'Manual pending recipe remains unpublished during display policy edits')
    # Bound emergency CPU markers, with no CPU triangle submission.
    before=[int(x) for x in r.cyrusPreviewFallbackStats()]
    r.CyrusMeshEnabled=False;r.CyrusViewportRedraw();r.completeRedraw()
    after=[int(x) for x in r.cyrusPreviewFallbackStats()]
    data['fallback_before']=before;data['fallback_after']=after
    check(after[3]==before[3] and after[1]>before[1],'Emergency fallback submits zero source triangles')
    r.CyrusMeshEnabled=True;r.CyrusViewportRedraw();r.completeRedraw()
    scene=OUT/'Policy_settings.max';r.saveMaxFile(str(scene),quiet=True)
    r.loadMaxFile(str(scene),quiet=True,useFileUnits=True);node=r.getNodeByName('Viewport 0.81.7');root=node.baseObject
    check(int(root.viewportFaces)==120 and int(root.viewportNavigationFaces)==24 and int(root.previewBudget)==0,'Limits including zero persist through save/reopen')
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

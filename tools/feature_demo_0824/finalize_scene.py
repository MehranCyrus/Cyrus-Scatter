"""Freeze presentation, capture via Max APIs, and recheck the delivered scene."""
from pathlib import Path
import hashlib,json,math
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-feature-demo0824-')
original=json.loads((OUT/'demo-verification.json').read_text());assert original['status']=='passed'
NODE='CYRUS 0.82.4 | SELECT ME - five feature layers'
def vector(v):return tuple(float(v[k]) for k in range(3))
def signature(root):
    all_rows=[]
    for group in root.groupSnapshotRows:
        all_rows.append({str(row[2]):(tuple(vector(getattr(row[0],'row'+str(i))) for i in range(1,5)),
            int(row[1]),str(row[2]),int(row[3]),vector(row[4]),int(row[5]),bool(row[6]),int(row[7])) for row in group})
    return hashlib.sha256(json.dumps(all_rows,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def unit(v):
    length=math.sqrt(sum(x*x for x in v));return tuple(x/length for x in v)
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def camera(name,eye,target,fov):
    look=unit(tuple(target[i]-eye[i] for i in range(3)))
    up_hint=(0,1,0) if abs(look[2])>.99 else (0,0,1)
    right=unit(cross(look,up_hint));up=cross(right,look)
    node=r.getNodeByName(name);node.transform=r.matrix3(r.Point3(*right),r.Point3(*up),r.Point3(*(-x for x in look)),r.Point3(*eye));node.fov=fov
    return node

# Keep the inspectable current state before reloading the exact original demo.
r.saveMaxFile(str(OUT/'Before final presentation.max'),quiet=True)
r.CyrusPerfHeadless=True;r.loadMaxFile(str(OUT/'Feature Demo 0.82.4 - working.max'),quiet=True,useFileUnits=True)
root=r.getNodeByName(NODE).baseObject;root.updateMode=1;root.refreshAll()
assert signature(root)==original['final_publication_sha256'],'The combined feature setup changed'
anchors={'TITLE':-33,'Plane heading':-33,'Mountain heading':3,'Density heading':-31,'Paint heading':-31,
    'Bands heading':-31,'On heading':3.5,'Off heading':18,'Clearing heading':8,'Sources heading':-31,'Usage':-33}
for name,x in anchors.items():
    node=r.getNodeByName(name);bounds=r.nodeGetBoundingBox(node,r.matrix3(1));p=node.pos
    node.pos=r.Point3(float(p.x)+x-float(bounds[0].x),float(p.y),float(p.z))
views=[('CAM 01 | Overview',(-8,-65,85),(-1,-1,1),48,'Preview - Overview.png'),
    ('CAM 02 | Plane - density Paint Bands',(-19,-27,38),(-19,0,0),52,'Preview - Plane.png'),
    ('CAM 03 | Mountain - normals and filters',(39,-30,28),(17,0,2),53,'Preview - Mountain.png'),
    ('CAM 04 | Top plan',(-1,0,105),(-1,0,0),44,'Preview - Top.png')]
for name,eye,target,fov,_ in views:camera(name,eye,target,fov)
r.LayerManager.getLayerFromName('DEMO | Cameras').isHidden=True
r.CyrusPerfHeadless=False;r.select(r.getNodeByName(NODE));r.execute('max modify mode');r.modPanel.setCurrentObject(root)
if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
root.selectLayer(1);root.populationUI.open=True;root.mainUI.bindSection(root.populationUI)
r.viewport.setLayout(r.Name('layout_1'));r.viewport.setRenderLevel(r.Name('smoothhighlights'))
r.viewport.setGridVisibility(r.viewport.activeViewport,False);r.CyrusClearMeshMaskPreview(r.undefined)
for name,_,_,_,filename in views:
    r.viewport.setCamera(r.getNodeByName(name));r.CyrusPointSync();r.completeRedraw()
    image=r.gw.getViewportDib();image.filename=str(OUT/filename);r.save(image);r.close(image)
r.viewport.setCamera(r.getNodeByName(views[0][0]));r.completeRedraw()
final=OUT/'CyrusScatter 0.82.4 Feature Demo.max';r.saveMaxFile(str(final),quiet=True)
sha=hashlib.sha256(final.read_bytes()).hexdigest()
# Cold rebuild after the presentation save. Do not overwrite the frozen scene.
r.loadMaxFile(str(final),quiet=True,useFileUnits=True);root=r.getNodeByName(NODE).baseObject;root.refreshAll();r.CyrusPointSync()
assert signature(root)==original['final_publication_sha256']
assert all(not bool(leaf.dirty) and not str(leaf.previewError) for leaf in root.layerObjects)
assert hashlib.sha256(final.read_bytes()).hexdigest()==sha
receipt={'status':'passed','scene':str(final),'scene_sha256':sha,'bytes':final.stat().st_size,
    'version':'0.82.4','max_year':2027,'qualification_receipt_sha256':hashlib.sha256((OUT/'demo-verification.json').read_bytes()).hexdigest(),
    'assertions':len(original['checks']),'counts':original['counts'],'total_accepted':original['total_accepted'],
    'final_publication_sha256':original['final_publication_sha256'],'cold_reopen_all_rows_equal':True,
    'cameras_reset_to_authored_views':True,'text_bounds_aligned':True,
    'capture_method':'MAXScript/pymxs viewport and GraphicsWindow APIs; no Computer Use',
    'previews':{filename:hashlib.sha256((OUT/filename).read_bytes()).hexdigest() for *_,filename in views}}
(OUT/'demo-final.json').write_text(json.dumps(receipt,indent=2)+'\n')

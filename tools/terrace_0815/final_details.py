"""Correct asset orientation and place the saved stepping stones in world coordinates."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve();SCENES=ROOT/'Test Scene/Terraces_0815'
assert OUT.name.startswith('foundation-terrace0815-candidate2027-')
data={'status':'started'};report=OUT/'final-details-05.json'
def save():report.write_text(json.dumps(data,indent=2)+'\n')
try:
    root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject;root.autoRender=False;r.CyrusPerfHeadless=True
    r.execute('fn TerracePlaceStone node p angle=(local tm=(eulerAngles 0 0 angle) as matrix3;tm.row4=p;node.transform=tm)')
    layout=json.loads((OUT/'planting-zones.json').read_text())
    for i,(x,y,z,a) in enumerate(layout['steps']):
        n=r.getNodeByName('PATH | stepping stone %02d'%i)
        r.TerracePlaceStone(n,r.Point3(x,y,z),a);n.material.baseColor=r.color(104+(i%5)*7,97+(i%5)*7,78+(i%5)*6)
    original=r.getNodeByName('palm tree');palm=r.snapshot(original);palm.parent=None
    r.resetXForm(palm);r.collapseStack(palm);palm.transform=r.matrix3(1)
    palm.name='SOURCE | upright palm';palm.pos=r.Point3(37500,24000,0);palm.renderable=False;r.hide(palm)
    r.LayerManager.getLayerFromName('08 Cyrus source palettes').addNode(palm)
    info=r.cyrusSourceGeometryInfo(r.Array(palm))[0];data['palm_bounds_before_pivot']=str(info)
    # Put the basal point on the receiving surface, keeping the baked upright mesh.
    base=float(info[3].z);palm.objectOffsetPos+=r.Point3(0,0,-base)
    l=root.layerObjects[5];l.containerMode=1;l.sources=r.Array(palm);l.sourceScales=r.Array(1.);l.sourceRadiiWU=r.Array(160.);l.sourceWeights=r.Array(1.);l.markInputDirty()
    data['palm_bounds']=str(r.cyrusSourceGeometryInfo(r.Array(palm)))
    root.refreshAll();data['counts']=[int(l.generatedCount) for l in root.layerObjects];data['errors']=[str(l.previewError) for l in root.layerObjects]
    if any(data['errors']):raise RuntimeError(str(data['errors']))
    root.autoRender=True;r.CyrusPerfHeadless=False;r.CyrusPointSync();r.clearSelection();r.completeRedraw()
    r.renderWidth=1280;r.renderHeight=720;r.renderers.current.progressive_passLimit=6
    data['status']='saving';save();r.saveMaxFile(str(SCENES/'Terraces_0815_Planting_05.max'),quiet=True)
    data['status']='rendering';save();start=time.perf_counter()
    image=r.render(camera=r.getNodeByName('PhysCamera002'),vfb=False,outputfile=str(SCENES/'Terraces_0815_Planting_05.png'));r.close(image)
    data['render_seconds']=time.perf_counter()-start;data['render_error']=str(r.CyrusPFLastError);data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

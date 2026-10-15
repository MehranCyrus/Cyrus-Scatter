"""Real Data Channel Curvature and VertexPaint inputs, without renderer baking."""
from pathlib import Path
import json,math,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-meshmask-')
data={'status':'started','checks':[]}
def save(): (OUT/'mesh-mask-producers.json').write_text(json.dumps(data,indent=2)+'\n')
def check(value,label):
    data['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def solve():root.procManualRevision+=1;root.evaluateProcedural()
try:
    r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
    terrain=r.Plane(name='Curvature terrain',length=40,width=40,lengthsegs=35,widthsegs=35)
    r.convertToMesh(terrain)
    for i in range(1,int(terrain.numverts)+1):
        p=r.getVert(terrain,i);p.z=3*math.sin(float(p.x)/4)*math.cos(float(p.y)/6);r.setVert(terrain,i,p)
    r.update(terrain)
    dc=r.DataChannelModifier();dc.AddOperator(0x0e12bb44,0,0);dc.AddOperator(0xabcdaa33,0,1)
    curvature=dc.operators[0];output=dc.operators[1]
    curvature.convex=0;curvature.flat=.5;curvature.concave=1;curvature.scale=3;curvature.hardEdgesOnly=False
    output.output=2;output.channelNum=7;output.xyz=0;output.replace=0
    r.addModifier(terrain,dc)
    node=r.AminScatterObject(name='Curvature mask workflow');root=node.baseObject;root.updateMode=1;root.autoRender=False
    root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.addPointSource()
    leaf.amount=12000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False
    solve();full=int(leaf.generatedCount)
    leaf.meshMaskEnabled=True;leaf.meshMaskChannel=7;solve()
    first=int(leaf.generatedCount);firstKey=str(r.cyrusMeshDensityKey(terrain,leaf.meshMaskPayload()))
    mesh=r.snapshotAsMesh(terrain)
    values=[float(r.meshop.getMapVert(mesh,7,i).x) for i in range(1,int(r.meshop.getNumMapVerts(mesh,7))+1)]
    data['curvature_values']={'minimum':min(values),'maximum':max(values),'samples':len(values),'accepted':first,'full':full}
    check(min(values)<max(values) and 0<first<full,'Actual Curvature -> Vertex Output channel 7 drives terrain planting')
    curvature.concave=0;curvature.flat=0;curvature.convex=0;solve()
    check(int(leaf.generatedCount)==0 and str(r.cyrusMeshDensityKey(terrain,leaf.meshMaskPayload()))!=firstKey,'Data Channel operator edit changes stored values and excludes plants')
    curvature.concave=1;curvature.flat=.5;curvature.convex=0;solve();check(int(leaf.generatedCount)==first,'Restoring Curvature settings restores the stable count')
    dc.display=True;dc.normalizeDisplay=True
    dc.minColor=r.color(255,0,255);dc.midColor=r.color(0,255,0);dc.maxColor=r.color(0,0,0)
    check(str(r.cyrusMeshDensityKey(terrain,leaf.meshMaskPayload()))==firstKey,'Rainbow display colors and display normalization do not alter sampled channel values')
    dc.display=False
    output.output=1;output.xyz=0;leaf.meshMaskChannel=0;solve()
    check(0<int(leaf.generatedCount)<full,'Curvature Vertex Color output is read through channel 0')
    output.output=2;output.channelNum=7;leaf.meshMaskChannel=7
    paint=r.VertexPaint();paint.mapChannel=7;r.addModifier(terrain,paint);solve()
    check(int(leaf.generatedCount)==first,'A VertexPaint layer preserves and composes with the channel produced below it')
    # Actual SDK-exposed VertexPaint UI interface is inspected for a fill action;
    # artist-input qualification is recorded separately from this stack check.
    data['vertexpaint_interfaces']=str(r.showInterfaces(paint))
    r.CurvatureNode=node;r.CurvatureRoot=root;r.CurvatureLeaf=leaf;r.CurvatureTerrain=terrain;r.CurvatureDC=dc
    data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise

"""Close actual terrain gaps and develop the foreground tree composition."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve();SCENES=ROOT/'Test Scene/Terraces_0815'
assert OUT.name.startswith('foundation-terrace0815-candidate2027-')
data={'status':'started'};report=OUT/'refine-structure-03.json'
def save():report.write_text(json.dumps(data,indent=2)+'\n')
def arr(v):return r.Array(*v)
def pt(p):return r.Point3(*map(float,p))
def group(n,name):
    layer=r.LayerManager.getLayerFromName(name)
    if layer is None:layer=r.LayerManager.newLayerFromName(name)
    layer.addNode(n);return n
try:
    r.CyrusPerfHeadless=True;root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject;root.autoRender=False
    stone=r.getNodeByName('spl_terrace_1').material
    for wall in json.loads((OUT/'retaining-walls.json').read_text()):
        n=r.mesh(name=wall['name'],vertices=arr([pt(p) for p in wall['vertices']]),faces=arr([pt(p) for p in wall['faces']]),material=stone)
        group(n,'02 Repaired retaining walls');r.addModifier(n,r.UVWMap(maptype=4,width=100,length=100,height=100))
    data['wall_count']=10
    tree=r.getNodeByName('CGt_02_Acer platanoides-3');leaf=r.getSubMtl(tree.material,2)
    leaf.colorDiffuse=r.color(48,75,15);leaf.texmapOnDiffuse=False;leaf.colorTranslucency=r.color(104,131,35);leaf.texmapOnTranslucency=False
    # Preserve the original two-part tree; create one atomic Scatter model from copies.
    trunk=r.snapshot(r.getNodeByName('trees 01 trunk'));leaves=r.snapshot(r.getNodeByName('trees01 leaves'))
    trunk.parent=None;leaves.parent=None;trunk.transform=r.matrix3(1);leaves.transform=r.matrix3(1)
    r.meshop.attach(trunk,leaves);trunk.name='SOURCE | complete branching tree';trunk.pos=r.Point3(41300,24000,0);trunk.renderable=False;r.hide(trunk);group(trunk,'08 Cyrus source palettes')
    frame=root.layerObjects[6];frame.containerMode=1;frame.sources=arr([trunk]);frame.sourceScales=arr([.95]);frame.sourceWeights=arr([1.]);frame.sourceRadiiWU=arr([500.]);frame.markInputDirty()
    # The paired tree supplies the broad open canopy the reference needs.
    root.layerObjects[7].sourceWeights=arr([.45,.55]);root.layerObjects[7].sourceScales=arr([4.5,1.4]);root.layerObjects[7].amount=1800
    root.layerObjects[5].sourceScales=arr([3.6]);root.layerObjects[5].sourceRadiiWU=arr([160.])
    # Distinct yellow petals must override both surface and backlit petal color.
    for name in ['SOURCE | golden woodland flowers','SOURCE | pale gold flower carpet']:
        n=r.getNodeByName(name)
        for j in range(1,int(r.getNumSubMtls(n.material))+1):
            m=r.getSubMtl(n.material,j)
            if m is not None and ('petals' in str(m.name).lower()):
                m.colorDiffuse=r.color(218,162,35);m.texmapOnDiffuse=False;m.colorTranslucency=r.color(239,196,75);m.texmapOnTranslucency=False
    root.refreshAll();data['layers']=[{'name':str(root.layerNames[i]),'count':int(l.generatedCount),'error':str(l.previewError)} for i,l in enumerate(root.layerObjects)]
    if any(l['error'] for l in data['layers']):raise RuntimeError(str(data['layers']))
    # Inventory supported atmosphere controls before choosing a physical haze.
    volume=r.CoronaVolumeMtl();data['volume_properties']=[str(p) for p in r.getPropNames(volume)]
    data['tone_operators']=[];op=r.renderers.current.colorMap_pipeline
    while op is not None:
        data['tone_operators'].append({'class':str(r.classOf(op)),'props':[str(p) for p in r.getPropNames(op)]});op=op.colorMappingOperator_nextOperator
    root.autoRender=True;r.CyrusPerfHeadless=False;r.CyrusPointSync();r.clearSelection();r.completeRedraw()
    r.renderWidth=1100;r.renderHeight=619;r.renderers.current.progressive_passLimit=5
    data['status']='saving';save();r.saveMaxFile(str(SCENES/'Terraces_0815_Planting_03.max'),quiet=True)
    data['status']='rendering';save();start=time.perf_counter()
    frame=r.render(camera=r.getNodeByName('PhysCamera002'),vfb=False,outputfile=str(SCENES/'Terraces_0815_Planting_03.png'));r.close(frame)
    data['render_seconds']=time.perf_counter()-start;data['render_error']=str(r.CyrusPFLastError);data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

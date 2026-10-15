"""Refine planting materials and render through the corrected source frame."""
from pathlib import Path
import json,time,traceback,hashlib
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve();SCENES=ROOT/'Test Scene/Terraces_0815'
assert OUT.name.startswith('foundation-terrace0815-candidate2027-')
data={'status':'started'};report=OUT/'refine-scene-02.json'
def save():report.write_text(json.dumps(data,indent=2)+'\n')
try:
    r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms';r.fileIn(str(script));data['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest()
    r.loadMaxFile(str(SCENES/'Terraces_0815_Planting_01.max'),quiet=True,useFileUnits=True)
    root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject;root.autoRender=False;root.updateMode=1
    tree=r.getNodeByName('CGt_02_Acer platanoides-3');tree.material=r.copy(tree.material);data['leaf_materials']=[]
    for j in range(1,int(r.getNumSubMtls(tree.material))+1):
        sub=r.getSubMtl(tree.material,j)
        if sub is None:continue
        data['leaf_materials'].append(str(sub))
        if any(s in str(sub.name).lower() for s in ['leaf','leaves','foliage']):
            sub=r.copy(sub);r.setSubMtl(tree.material,j,sub)
            if r.isProperty(sub,r.Name('baseColor')):sub.baseColor=r.color(52,79,21);sub.baseTexmapOn=False
            elif r.isProperty(sub,r.Name('colorDiffuse')):sub.colorDiffuse=r.color(52,79,21);sub.texmapOnDiffuse=False
    stone=r.getNodeByName('spl_terrace_1').material
    stone.displacementTexmap=r.Noise(size=35,levels=4,noiseType=1,color1=r.color(0,0,0),color2=r.color(255,255,255));stone.displacementTexmapOn=True;stone.displacementMinimum=-4;stone.displacementMaximum=9
    sun=r.getNodeByName('Terraces | warm afternoon sun');sun.pos=r.Point3(-1000,4000,6500);sun.target.pos=r.Point3(-5500,-1800,-700);sun.sizeMultiplier=4
    r.execute('(local op=renderers.current.colorMap_pipeline;while op!=undefined do (if isProperty op #colorMappingOperator_simpleExposure do op.colorMappingOperator_simpleExposure=-2.7;op=op.colorMappingOperator_nextOperator))')
    start=time.perf_counter();root.refreshAll();data['update_seconds']=time.perf_counter()-start
    data['layers']=[{'name':str(root.layerNames[i]),'count':int(l.generatedCount),'error':str(l.previewError)} for i,l in enumerate(root.layerObjects)]
    if any(l['error'] for l in data['layers']):raise RuntimeError(str(data['layers']))
    root.autoRender=True;r.CyrusPerfHeadless=False;r.CyrusPointSync();r.clearSelection();r.completeRedraw()
    r.renderWidth=1100;r.renderHeight=619;r.renderers.current.progressive_passLimit=5
    data['status']='saving';save();r.saveMaxFile(str(SCENES/'Terraces_0815_Planting_02.max'),quiet=True)
    data['status']='rendering';save();start=time.perf_counter()
    frame=r.render(camera=r.getNodeByName('PhysCamera002'),vfb=False,outputfile=str(SCENES/'Terraces_0815_Planting_02.png'));r.close(frame)
    data['render_seconds']=time.perf_counter()-start;data['render_error']=str(r.CyrusPFLastError);data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

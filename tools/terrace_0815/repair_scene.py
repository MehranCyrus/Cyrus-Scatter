"""Repair actual scene dependencies and establish a camera lighting draft."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-')
SCENES=ROOT/'Test Scene/Terraces_0815'
data={'maps':[], 'uv_receivers':[], 'removed_missing_plugins':[], 'status':'started'}
def save(): (OUT/'scene-repair.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def pt(x,y,z):return r.Point3(float(x),float(y),float(z))
def mat(name,color,rough=.8):return r.CoronaPhysicalMtl(name=name,baseColor=r.color(*color),baseRoughness=rough)
save()
try:
    root=r.getNodeByName('Cyrus Scatter001').baseObject
    r.CyrusPerfHeadless=True;root.updateMode=1;root.autoRender=False;root.cyrusEnabled=False
    files={}
    for p in (ROOT/'Test Scene').rglob('*'):
        if p.is_file() and p.suffix.lower() in ('.jpg','.png','.jpeg','.tif','.tiff','.exr','.hdr','.bmp'):
            files.setdefault(p.name.lower(),[]).append(p)
    for kind,field in [('Bitmaptexture','filename'),('CoronaBitmap','filename')]:
        for item in r.getClassInstances(getattr(r,kind)):
            filename=str(getattr(item,field));resolved=str(r.mapPaths.getFullFilePath(filename))
            if Path(resolved).is_file():continue
            choices=files.get(Path(filename).name.lower(),[])
            if len(choices)!=1:raise RuntimeError('Texture needs unambiguous local path: '+filename)
            setattr(item,field,str(choices[0]));data['maps'].append({'old':filename,'new':str(choices[0])})
    soil=mat('Terraces | dark planted soil',(49,43,29))
    soil.baseTexmap=r.Noise(size=22.,color1=r.color(26,29,15),color2=r.color(78,65,43));soil.baseTexmapOn=True
    stone=mat('Terraces | weathered stone',(90,86,66))
    stone.baseTexmap=r.Noise(size=45.,color1=r.color(44,48,33),color2=r.color(125,117,89));stone.baseTexmapOn=True
    stone.baseBumpTexmap=r.Noise(size=9.,color1=r.color(0,0,0),color2=r.color(255,255,255));stone.baseBumpTexmapOn=True;stone.baseBumpAmount=1.3
    for node in root.layerObjects[0].validSurfaces():
        uv=r.UVWMap();uv.name='Terrace density and material UV';uv.maptype=0;uv.width=1000.;uv.length=1000.;uv.mapChannel=1
        r.addModifier(node,uv);node.material=soil;data['uv_receivers'].append(str(node.name))
    for node in list(r.objects):
        if str(r.classOf(node.baseObject))=='Missing_Light':
            data['removed_missing_plugins'].append({'node':str(node.name),'class':'Missing_Light'});r.delete(node);continue
        for modifier in list(node.modifiers):
            if str(r.classOf(modifier))=='Missing_OSM':
                data['removed_missing_plugins'].append({'node':str(node.name),'class':'Missing_OSM'});r.deleteModifier(node,modifier)
        if str(node.name).startswith(('spl_terrace_','coastal_cliff','rock-')):node.material=stone
    for node in r.geometry:
        if str(node.name).startswith(('grass','leaf','clover','crp_','MT_PM_','tree','trees','palm','CGt_','GrowFX','stone01','soil')):
            node.renderable=False
    path=r.getNodeByName('spl-path');path.material=mat('Path | warm stone gravel',(130,123,103));path.renderable=False
    r.renderers.current=r.Corona();renderer=r.renderers.current
    renderer.system_numThreads=12;renderer.progressive_passLimit=3;renderer.denoise_filterType=2;renderer.renderstamp_use=False
    sun=r.CoronaSun(name='Terraces | warm afternoon sun');sun.targeted=True
    sun.target.pos=pt(-2500,0,0);sun.pos=pt(-2000,8000,13000);sun.sizeMultiplier=3.;sun.intensity=.8
    sky=r.CoronaSky();sky.selectedSun=sun;sky.sunSelectionMode=1
    r.environmentMap=sky;r.useEnvironmentMap=True
    r.execute('(local op=renderers.current.colorMap_pipeline;while op!=undefined do (if classof op==AcesOtOperatorPlugin do op.colorMappingOperator_enabled=true;if isProperty op #colorMappingOperator_simpleExposure do op.colorMappingOperator_simpleExposure=-3.0;op=op.colorMappingOperator_nextOperator))')
    camera=r.getNodeByName('PhysCamera002');camera.use_dof=False
    r.renderWidth=960;r.renderHeight=540
    root.refreshAll();r.CyrusPerfHeadless=False;r.CyrusPointSync();r.completeRedraw()
    data['status']='saving';save()
    r.saveMaxFile(str(SCENES/'Terraces_0815_Prepared.max'),quiet=True)
    data['status']='rendering';save();start=time.perf_counter()
    bitmap=r.render(camera=camera,vfb=False,outputfile=str(SCENES/'Terraces_0815_Prepared.png'));r.close(bitmap)
    data['render_seconds']=time.perf_counter()-start;data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

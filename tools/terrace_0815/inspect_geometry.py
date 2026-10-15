"""Read geometry, UV and asset evidence from the owned, already loaded copy."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-')
data={'receivers':[], 'sources':[], 'maps':[], 'camera':{}, 'renderer':{}, 'errors':[]}
def save(): (OUT/'geometry-assets.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def xyz(p):return [float(p.x),float(p.y),float(p.z)]
def properties(obj):
    result={}
    for prop in r.getPropNames(obj):
        try:result[str(prop)]=str(r.getProperty(obj,prop))
        except Exception:pass
    return result
try:
    root=r.getNodeByName('Cyrus Scatter001').baseObject
    for node in root.layerObjects[0].validSurfaces():
        mesh=r.snapshotAsMesh(node)
        data['receivers'].append({'name':str(node.name),'faces':int(mesh.numfaces),'vertices':int(mesh.numverts),
            'uv1':bool(r.meshop.getMapSupport(mesh,1)), 'mods':[str(r.classOf(m)) for m in node.modifiers],
            'bounds':[xyz(p) for p in r.nodeGetBoundingBox(node,r.matrix3(1))]})
        r.delete(mesh)
        save()
    for node in r.geometry:
        if str(node.name).startswith(('grass','leaf','clover','crp_','MT_PM_','tree','trees','palm','CGt_','GrowFX')):
            mesh=r.snapshotAsMesh(node)
            data['sources'].append({'name':str(node.name),'faces':int(mesh.numfaces),
                'scale':xyz(node.scale),'pos':xyz(node.pos),
                'local_bounds':[xyz(p) for p in r.nodeGetBoundingBox(node,node.transform)],
                'materials':properties(node.material) if node.material else {}})
            r.delete(mesh)
            save()
    files={}
    for path in (ROOT/'Test Scene').rglob('*'):
        if path.is_file() and path.suffix.lower() in ('.jpg','.png','.jpeg','.tif','.tiff','.exr','.hdr','.bmp'):
            files.setdefault(path.name.lower(),[]).append(str(path))
    for kind,field in [('Bitmaptexture','filename'),('CoronaBitmap','filename')]:
        for item in r.getClassInstances(getattr(r,kind)):
            filename=str(getattr(item,field));resolved=str(r.mapPaths.getFullFilePath(filename))
            data['maps'].append({'name':str(item.name),'class':kind,'filename':filename,'resolved':resolved,
                'resolved_exists':Path(resolved).is_file(),'local_matches':files.get(Path(filename).name.lower(),[])})
    data['camera']=properties(r.getNodeByName('PhysCamera002'))
    data['renderer']=properties(r.renderers.current)
    data['environment']={'map':str(r.environmentMap),'enabled':bool(r.useEnvironmentMap), 'background':str(r.backgroundColor),
        'exposure_control':str(r.SceneExposureControl.exposureControl)}
except Exception:data['errors'].append(traceback.format_exc())
save()
if data['errors']:raise RuntimeError(data['errors'][-1])

"""Merge the missing real flower assets into the owned terrace copy."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-candidate')
data={'status':'started','sources':[]};report=OUT/'flower-assets.json'
def save():report.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
try:
    names=['crp_Lavander_01','crp_Lavander_05','crp_MT_PM_V33_Glossy_abelia_01_006','MT_PM_V41_Geranium_robertianum_01_04','MT_PM_V41_Lamium_maculatum_01_04','MT_PM_V41_Phlox_stolonifera_01_01','MT_PM_V41_Viola_sororia_01_05']
    missing=[name for name in names if r.getNodeByName(name) is None]
    r.execute('global TerraceMergeNames');r.TerraceMergeNames=r.Array(*missing)
    if missing:
        ok=r.execute('mergeMAXFile @"'+(ROOT/'Test Scene/Reference_Garden_075/Source_Plants.max').as_posix()+'" TerraceMergeNames #noRedraw #autoRenameDups #renameMtlDups quiet:true')
        if not ok:raise RuntimeError('Selective asset merge failed')
    files={}
    for p in (ROOT/'Test Scene').rglob('*'):
        if p.is_file() and p.suffix.lower() in ('.jpg','.png','.jpeg','.tif','.tiff','.exr','.hdr','.bmp'):files.setdefault(p.name.lower(),[]).append(p)
    data['asset_repairs']=[]
    for kind in ['Bitmaptexture','CoronaBitmap']:
        for item in r.getClassInstances(getattr(r,kind)):
            filename=str(item.filename);resolved=str(r.mapPaths.getFullFilePath(filename))
            if Path(resolved).is_file():continue
            choices=files.get(Path(filename).name.lower(),[])
            if len(choices)!=1:raise RuntimeError('Unresolved local texture: '+filename)
            item.filename=str(choices[0]);data['asset_repairs'].append([filename,str(choices[0])])
    for i,name in enumerate(names):
        n=r.getNodeByName(name)
        if n is None:raise RuntimeError('Missing merged asset: '+name)
        box=r.nodeGetBoundingBox(n,n.transform);size=box[1]-box[0]
        n.pos=r.Point3(24000+i*450,18000,0);n.renderable=False;r.hide(n)
        mats=[]
        if n.material is not None:
            for j in range(1,int(r.getNumSubMtls(n.material))+1):mats.append(str(r.getSubMtl(n.material,j)))
        data['sources'].append({'name':name,'size':[float(size.x),float(size.y),float(size.z)],'scale':str(n.scale),'material':str(n.material),'submaterials':mats})
    r.saveMaxFile(str(ROOT/'Test Scene/Terraces_0815/Terraces_0815_Assets.max'),quiet=True)
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])

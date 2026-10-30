from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun))
lib=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library'
data={'resolved':0,'missing':[]}
try:
    for node in r.GardenSources:
        for cls in ['Bitmaptexture','CoronaBitmap']:
            for texture in r.getClassInstances(r.execute(cls),target=node.material):
                old=str(texture.filename)
                if not old:continue
                if Path(old).is_file():continue
                candidate=lib/old.replace('\\','/')
                if not candidate.is_file():candidate=lib/'Maps'/Path(old.replace('\\','/')).name
                if candidate.is_file():texture.filename=str(candidate);data['resolved']+=1
                else:data['missing'].append(dict(source=str(node.name),path=old))
    assert not data['missing'],data['missing'][:5]
    r.execute('for n in GardenNodes do n.baseObject.refreshAll();CyrusPointSync();completeRedraw()')
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Resolved.max'),quiet=True)
    dib=r.gw.getViewportDib();dib.filename=str(out/'garden-textures-resolved.png');r.save(dib);r.close(dib)
    (out/'render-stage.txt').write_text('rendering resolved textures, four passes')
    r.renderers.current.progressive_passLimit=4
    start=time.perf_counter()
    b=r.render(camera=r.TCBoulderCamera,outputwidth=960,outputheight=600,vfb=False,outputfile=str(out/'garden-resolved-render.png'))
    r.close(b);data['render_seconds']=time.perf_counter()-start
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Resolved.max'),quiet=True)
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-resolve-textures.json').write_text(json.dumps(data,indent=2),encoding='utf-8')

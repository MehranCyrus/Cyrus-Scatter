"""Save existing prepared meshes in Max 2024 format; no asset construction."""
from pathlib import Path
import gc,hashlib,json,os,time,traceback
from pymxs import runtime as rt
from PySide6.QtCore import QTimer

ROOT=Path('F:/Cursor/_Cyrus_Apps/CyrusScatter')
WORK=ROOT/'build/viewport-0867-20261020'
LIB=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library'
assert Path(str(rt.MCPFixtureDir)).resolve()==ROOT/'build/mcp-qualification/viewport0867-content-2027'
CAT=json.loads((WORK/'model-catalog-before.json').read_text())
REPORT=WORK/'content-saveback.json'
state={'status':'running','pid':os.getpid(),'version':'0.86.7','saved_format':2024,
       'originals_modified':False,'previews_regenerated':False,'complete':[],'failures':[]}
if REPORT.exists():
    previous=json.loads(REPORT.read_text())
    assert previous['status']!='running','Observe the current pass; never duplicate an active conversion'
    state['previous_failures']=previous['failures']
    state['complete']=previous['complete']
completed_ids={row['id'] for row in state['complete']}
pending=[entry for entry in CAT['entries'] if entry['id'] not in completed_ids]
obsolete={'mental ray: material custom attribute':'mrmaterialattribs.gup',
          'mental ray: Displacement Custom Attributes':'mrmaterialattribs.gup',
          'VRayShadow':'vrender2018.dlr'}
# These are retained studio render elements/post controls, not model shaders.
# The scene is required to contain exactly its one declared prepared mesh.
obsolete.update({name:'vrender2018.dlr' for name in (
    'VRayDenoiser','VRayRawLighting','VRayReflection','VRayReflectionFilter',
    'VRayRefraction','VRaySpecular','VRayZDepth','VRayRenderID')})
obsolete.update({name:'redshift4max.dlr' for name in (
    'RS Color Management Params','RS LUT Params','RS Color Control Params',
    'RS Physical Camera Params','RS Bloom Params','RS Flare Params','RS Streak Params','RS Post Effects')})
index=0
def sha(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
def save():
    temp=REPORT.with_suffix('.tmp');temp.write_text(json.dumps(state,indent=2));os.replace(temp,REPORT)
def next_entry():
    global index
    timer.stop()
    if index==len(pending):
        state['status']='passed' if not state['failures'] else 'failed'
        if state['status']=='passed':
            CAT.update(version='0.86.7',max_year=2024)
            by_id={row['id']:row for row in state['complete']}
            for entry in CAT['entries']:
                row=by_id[entry['id']];entry.update(scene_sha256=row['after_sha256'],scene_bytes=row['after_bytes'])
            (LIB/'model-catalog.json').write_text(json.dumps(CAT,indent=2)+'\n',encoding='utf-8')
        state.pop('current',None);save();return
    entry=pending[index];index+=1;state['current']=entry['id'];save()
    started=time.time();path=LIB/entry['scene'];temp=path.with_name('model-0867-staging.max')
    try:
        before=sha(path);assert before==entry['scene_sha256'],'Source model identity changed'
        assert rt.loadMaxFile(str(path),quiet=True,useFileUnits=True)
        nodes=list(rt.objects)
        assert len(nodes)==1 and str(nodes[0].name)==entry['node_name']
        n=nodes[0];faces=int(n.numfaces);vertices=int(n.numverts)
        rt.execute('global VSaveNode,VSaveLegacy,VSaveTarget,VSaveMissing')
        rt.VSaveNode=n
        missing=[]
        for i in range(1,int(rt.SceneMissingPlugIns.GetMissingPlugInCount())+1):
            missing.append((str(rt.SceneMissingPlugIns.GetMissingPlugInClassName(i)),str(rt.SceneMissingPlugIns.GetMissingPlugInFileName(i))))
        assert all(obsolete.get(name)==dll.lower() for name,dll in missing),missing
        legacy=list(rt.SceneConverter.GetMissingLegacyAssetsName())
        assert all(str(name) in obsolete for name in legacy),legacy
        if legacy:
            rt.execute('VSaveLegacy=SceneConverter.GetMissingLegacyAssetsName(); SceneConverter.RemoveMissingLegacyAssetsFromScene &VSaveLegacy')
        # Preserve maps and their portable filenames. No new image is written.
        maps=[]
        for cls in (rt.Bitmaptexture,rt.CoronaBitmap):
            maps.extend(rt.getClassInstances(cls,target=n.material))
        for image in maps:
            filename=str(image.filename).replace('\\','/')
            candidate=LIB/'Maps'/filename.rsplit('/',1)[-1]
            assert candidate.is_file(),filename
            image.filename='Maps/'+candidate.name
        assert int(n.numfaces)==faces and int(n.numverts)==vertices
        rt.VSaveTarget=str(temp)
        assert rt.execute('saveNodes #(VSaveNode) VSaveTarget quiet:true saveAsVersion:2024')
        assert list(rt.getMAXFileVersionData(str(temp)))[0]==26000
        rt.execute('VSaveMissing=#(); getMAXFileObjectNames VSaveTarget quiet:true missingDLLsAction:#logmsg missingDLLsList:&VSaveMissing')
        assert not list(rt.VSaveMissing),list(rt.VSaveMissing)
        assert list(map(str,rt.getMAXFileObjectNames(str(temp),quiet=True)))==[entry['node_name']]
        after=sha(temp);size=temp.stat().st_size
        os.replace(temp,path)
        state['complete'].append(dict(id=entry['id'],before_sha256=before,after_sha256=after,after_bytes=size,
                                      faces=faces,vertices=vertices,maps=len(maps),removed_legacy=list(map(str,legacy)),seconds=round(time.time()-started,2)))
    except Exception:
        state['failures'].append(dict(id=entry['id'],error=traceback.format_exc()))
        # A failed successor never replaces the prepared model.
        if temp.is_file():temp.unlink()
    finally:
        rt.resetMaxFile(rt.Name('noPrompt'));rt.gc(light=True);gc.collect();save()
    timer.start(100)
timer=QTimer();timer.timeout.connect(next_entry);timer.start(100);save()

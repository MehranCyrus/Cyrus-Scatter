"""Real orbit telemetry. QTimer reads counters without forcing a draw or solve."""
from pathlib import Path
import builtins,json,os,time,traceback
from pymxs import runtime as r
from PySide6.QtCore import QTimer

out=Path(str(r.GardenRun));phase=str(r.CVProfileCase);ROOT=Path(__file__).resolve().parents[3]

def snap():
    owner=r.CyrusPointOwner(r.WFOwner)
    return {'time':time.perf_counter(),'viewport':list(r.cyrusRetainedViewportStats(owner)),
            'view_matrix':[[float(v) for v in row] for row in r.viewport.getTM()],
            'streams':list(r.cyrusRetainedStreamStats()),'epoch':int(r.WFRoot.procEpoch),
            'idle_timer':bool(r.CyrusPreviewIdleTimer.Enabled),'held':bool(r.CyrusInteractionHeld()),
            'script_records':len(r.CyrusViewportRecords),
            'group':list(r.WFRoot.groupCounters()),'work':json.loads(str(r.WFRoot.interactionsStatistics()))['process_work']}

if phase=='nav-close':
    rows=r.cyrusPlacementTransformGroups(r.WFRoot.groupSnapshotRows[0])[0]
    collider=r.cyrusPlacementTransformGroups(r.WFRoot.groupSnapshotRows[1])[0][0].row4
    sample=max(rows,key=lambda tm:float(r.distance(tm.row4,collider)))
    centre=sample.row4+r.Point3(0,0,15);eye=centre+r.Point3(60,-80,45)
    back=r.normalize(eye-centre);right=r.normalize(r.cross(r.Point3(0,0,1),back));up=r.cross(back,right)
    r.viewport.setType(r.Name('view_persp_user'));r.viewport.setFOV(45);r.viewport.setTM(r.inverse(r.matrix3(right,up,back,eye)))
    r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap(),'sample_position':[float(v) for v in sample.row4]},indent=2),encoding='utf-8')
elif phase in ('nav-setup','nav-frame'):
    root=r.WFRoot
    if phase=='nav-setup':root.viewportFaces=0;root.viewportNavigationFaces=0
    root.setGroupDisplay(3);root.identificationMode=4;r.CyrusPointSync()
    preview=r.CyrusPointOwner(r.WFOwner);r.unhide(preview)
    for n in r.objects:
        if n!=r.WFOwner and n!=preview:r.hide(n)
    rows=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0]
    xs=[float(m.row4.x) for m in rows];ys=[float(m.row4.y) for m in rows];zs=[float(m.row4.z) for m in rows]
    bounds=r.nodeGetBoundingBox(preview,r.matrix3(1))
    size=max(float(bounds[1][i]-bounds[0][i]) for i in range(3))
    size=max(size,100.)
    centre=(bounds[0]+bounds[1])*.5
    eye=centre+r.Point3(size*.7,-size*.9,size*.7);back=r.normalize(eye-centre)
    right=r.normalize(r.cross(r.Point3(0,0,1),back));up=r.cross(back,right)
    r.viewport.setType(r.Name('view_persp_user'));r.viewport.setFOV(45);r.viewport.setTM(r.inverse(r.matrix3(right,up,back,eye)))
    r.viewport.SetRenderLevel(r.Name('smoothhighlights'))
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    for _ in range(30):r.windows.processPostedMessages();time.sleep(.02)
    root.displayUISlot.open=True;root.mainUI.bindSection(root.displayUI)
    r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap(),'navigation':int(root.viewportNavigationFaces),'idle':int(root.viewportFaces)},indent=2),encoding='utf-8')
elif phase=='nav-gpu-reload':
    os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None)
    scene=out/'Resolved-texture-control.max';assert r.saveMaxFile(str(scene),quiet=True)
    r.CyrusPointSuspended=True
    try:assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    finally:r.CyrusPointSuspended=False
    r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1]
    r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','scene':str(scene),'snapshot':snap()},indent=2),encoding='utf-8')
elif phase=='nav-resolve-materials':
    source=r.WFGrass.validSources()[0]
    if r.AuditGrassMaterial!=r.undefined:source.material=r.AuditGrassMaterial
    base=ROOT/'Test Scene/Organized Models/Plants/Outdoor/Outdoor_Plants_01';resolved=[];missing=[]
    for bitmap in r.getClassInstances(r.Bitmaptexture,target=source.material):
        raw=str(bitmap.filename);path=Path(raw)
        candidate=path if path.is_absolute() else base/path
        if candidate.is_file():
            bitmap.filename=str(candidate);resolved.append(str(candidate))
        else:missing.append(raw)
    r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.viewport.SetRenderLevel(r.Name('smoothhighlights'));r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','resolved':resolved,'missing':missing,'snapshot':snap()},indent=2),encoding='utf-8')
elif phase=='nav-flat-material':
    r.execute('global AuditGrassMaterial');r.AuditGrassMaterial=r.WFGrass.validSources()[0].material
    material=r.StandardMaterial(name='Owned opaque material control');material.diffuse=r.Color(80,150,60);material.twoSided=True
    r.WFGrass.validSources()[0].material=material;r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.viewport.SetRenderLevel(r.Name('smoothhighlights'));r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap()},indent=2),encoding='utf-8')
elif phase=='nav-wireframe':
    r.viewport.SetRenderLevel(r.Name('wireframe'));r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap()},indent=2),encoding='utf-8')
elif phase=='nav-cpu-preview':
    os.environ['CYRUS_INTERACTION_CPU_PREVIEW']='1'
    r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap()},indent=2),encoding='utf-8')
elif phase=='nav-hide-stone':
    r.WFRoot.layerVisible[1]=False;r.WFRoot.refreshDisplay();r.CyrusPointSync();r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap()},indent=2),encoding='utf-8')
elif phase=='nav-mesh':
    r.WFRoot.identificationMode=2;r.WFRoot.refreshIdentification();r.CyrusPointSync();r.completeRedraw()
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap()},indent=2),encoding='utf-8')
elif phase.startswith('nav-arm-'):
    label=phase.removeprefix('nav-arm-');data={'status':'recording','label':label,'samples':[],'navigation':int(r.WFRoot.viewportNavigationFaces),'idle':int(r.WFRoot.viewportFaces)}
    timer=QTimer();timer.setInterval(100);start=time.perf_counter();data['start']=start
    # Keep a strong lifetime independently from ExecuteFile's local namespace.
    if hasattr(builtins,'cyrus_nav08753'):builtins.cyrus_nav08753['timer'].stop()
    builtins.cyrus_nav08753={'timer':timer,'data':data}
    def tick(data=data,timer=timer,start=start,output=out/(phase+'.json'),snapshot=snap):
        try:
            data['samples'].append(snapshot())
            if time.perf_counter()-start<18:return
            timer.stop();first,last=data['samples'][0],data['samples'][-1]
            data['draw_delta']=[last['viewport'][i]-first['viewport'][i] for i in (10,11)]
            data['upload_delta']={str(i):last['streams'][i]-first['streams'][i] for i in (1,2,3,6,7)}
            assert first['epoch']==last['epoch'] and first['group']==last['group'] and first['work']==last['work']
            assert not any(data['upload_delta'].values()),data['upload_delta']
            assert first['view_matrix']!=last['view_matrix'],'No actual viewport movement recorded'
            assert data['draw_delta'][1]>0,'No moving-view draw callback recorded'
            assert data['draw_delta'][0]>0,'No restored idle draw callback recorded'
            assert not last['idle_timer'] and not last['held'],'Navigation did not return to full idle detail'
            data['status']='pass'
        except Exception:
            timer.stop();data.update(status='failed',error=traceback.format_exc())
        if not timer.isActive():output.write_text(json.dumps(data,indent=2),encoding='utf-8')
    timer.timeout.connect(tick);timer.start()
elif phase=='nav-snapshot':
    (out/(phase+'.json')).write_text(json.dumps({'status':'pass','snapshot':snap()},indent=2),encoding='utf-8')
else:raise ValueError(phase)

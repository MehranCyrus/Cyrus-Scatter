"""Actual mountain, rollout handlers and Painter SDK; no physical input or pixels."""
from pathlib import Path
from pymxs import runtime as r
import json,time,hashlib,struct
out=Path(str(r.CPLTestDir));report={'checks':0,'cases':[],'pass':False}
def need(value,message):
 report['checks']+=1
 if not value:raise AssertionError(message)
def stats(lab):return json.loads(str(r.cplStats(lab.physicsDocument)))
def overlay(lab):return json.loads(str(r.cplCollisionDisplayInfo(lab.physicsDocument)))
def pump(seconds):
 until=time.monotonic()+seconds
 while time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
def press(button):r.execute('CPLMountainLab.brushHeader.'+button+'.pressed()')
def show(lab):
 r.CPLMountainLab=lab
 r.execute('select CPLMountainLab;max modify mode;modPanel.setCurrentObject CPLMountainLab.baseObject;CPLMountainLab.brushHeader.open=true;CPLMountainLab.objectsUI.open=true;CPLMountainLab.collisionUI.open=true;CPLMountainLab.refreshBindings()')
 pump(.12)
def toggle(value):r.execute('CPLMountainLab.collisionUI.showCollisionCheck.changed '+('true' if value else 'false'))
def hit(ground,x,y):
 ray=r.intersectRay(ground,r.ray(r.Point3(x,y,100000),r.Point3(0,0,-1)))
 need(ray is not None,'Fixture point missed actual mountain')
 return ray.pos
def path(lab,ground,points,finish=True):
 values=r.Array(*(hit(ground,x,y) for x,y in points))
 n=r.cplPrivatePaintPath(lab.physicsDocument,values,False) if finish else r.cplPrivatePaintContinue(lab.physicsDocument,values)
 need(int(n)==len(points),'Actual mountain Painter SDK path missed')
 r.cplSynchronize(lab.physicsDocument)
def mesh_hash(lab):
 m=r.snapshotAsMesh(lab);h=hashlib.sha256();h.update(struct.pack('<II',int(m.numverts),int(m.numfaces)))
 for i in range(1,int(m.numverts)+1):h.update(struct.pack('<fff',*list(r.getVert(m,i))))
 for i in range(1,int(m.numfaces)+1):h.update(struct.pack('<III',*(int(x) for x in r.getFace(m,i))))
 return {'sha256':h.hexdigest(),'vertices':int(m.numverts),'faces':int(m.numfaces)}
try:
 ground=r.getNodeByName('Plane001');original=r.getNodeByName('Pyramid001');old=r.getNodeByName('Cyrus Physics Lab001')
 need(ground is not None and original is not None and old is not None,'Actual scene objects missing')
 origin=old.pos
 r.hide(old);r.hide(original)
 r.execute('viewport.setLayout #layout_1;viewport.setType #view_top')
 r.select(ground);r.execute('max zoomext sel all')
 sources=[('original_pyramid',original,.001,.08),('pyramid_original_radius',original,5.,.08),
          ('teapot',r.Teapot(name='Mountain_Test_Teapot',radius=120,segments=8,pos=r.Point3(16000,0,0)),2.,.8),
          ('torus',r.Torus(name='Mountain_Test_Torus',radius1=120,radius2=35,segments=32,sides=16,pos=r.Point3(17000,0,0)),2.,.8),
          ('tall_box',r.Box(name='Mountain_Test_Box',width=120,length=80,height=450,pos=r.Point3(18000,0,0)),2.,.8)]
 for index,(kind,source,radius,spacing) in enumerate(sources):
  r.cplStage(kind);r.hide(source)
  lab=r.CyrusPhysicsLab(name='Mountain_017_'+kind);lab.pos=origin
  lab.setReceiver(ground);lab.addSource(source)
  lab.brushRadius=radius;lab.birthSpacing=spacing;lab.emissionHeight=.4;lab.bodyLimit=1000
  show(lab);toggle(True)
  need(bool(lab.showCollisionShapes),'Collision checkbox did not own saved flag')
  press('startButton');need(stats(lab)['painting'],'Start handler did not start the actual mountain brush')
  need(bool(lab.collisionUI.showCollisionCheck.enabled),'Collision toggle is locked while brushing')
  y=4000-index*2000
  # The first two cases retain 8 cm spacing; the tall-source burst must no longer pause.
  distance=50 if spacing<.1 else 500
  path(lab,ground,[(-5000,y),(-5000+distance,y)],finish=False)
  first=stats(lab);poses=str(r.cplPendingRows(lab.physicsDocument));pump(.35);r.cplSynchronize(lab.physicsDocument)
  moving=stats(lab)
  need(moving['preview']>1,'Only one object was emitted')
  need(not moving['live']['paused'] and moving['error']=='','Crowding paused the worker: '+moving['error'])
  need(moving['live']['step']>first['live']['step'],'Simulation clock needs Finish to advance')
  need(str(r.cplPendingRows(lab.physicsDocument))!=poses,'Poses do not animate before Finish')
  r.cplRelease(lab.physicsDocument);r.cplSynchronize(lab.physicsDocument)
  count=stats(lab)['preview'];path(lab,ground,[(-1500,y),(-1500+distance,y)])
  need(stats(lab)['preview']>count,'Could not draw another stroke while bodies move')
  count=stats(lab)['preview'];outside=r.Array(r.Point3(50000,50000,0),r.Point3(51000,50000,0))
  need(int(r.cplPrivatePaintPath(lab.physicsDocument,outside,False))==0,'Outside path hit mountain')
  r.cplSynchronize(lab.physicsDocument);need(stats(lab)['preview']==count,'Outside brush emitted')
  path(lab,ground,[(2000,y),(2000+distance,y)])
  need(stats(lab)['preview']>count,'Valid re-entry did not emit')
  press('stopButton');paused=stats(lab);before=str(r.cplPendingRows(lab.physicsDocument));mesh_before=mesh_hash(lab)
  r.redrawViews();shown=overlay(lab)
  need(shown['prepared'] and shown['draws']>0 and shown['model_lines']>0 and shown['surface_lines']>0,'Cooked collision wires were not issued by redraw callback')
  need(shown['model_lines']+shown['surface_lines']<=shown['line_limit'],'Draw line budget exceeded')
  builds=shown['builds'];toggle(False);r.redrawViews();off=overlay(lab)
  need(not off['enabled'] and off['model_lines']==0,'Display did not turn off')
  toggle(True);r.redrawViews();on=overlay(lab)
  need(on['builds']==builds,'Visibility toggle recooked geometry')
  need(str(r.cplPendingRows(lab.physicsDocument))==before and stats(lab)['live']['step']==paused['live']['step'],'Display toggle changed solver state/time')
  mesh_after=mesh_hash(lab);need(mesh_after==mesh_before,'Collision wires changed rendered geometry')
  press('undoButton');need(stats(lab)['preview']<paused['preview'],'Live Undo did not remove last stroke')
  press('redoButton');need(str(r.cplPendingRows(lab.physicsDocument))==before,'Live Redo changed poses/velocities/sleep')
  scene=out/(kind+'-pending.max');need(r.saveMaxFile(str(scene),quiet=True),'Pending save failed')
  need(r.loadMaxFile(str(scene),quiet=True),'Pending reopen failed')
  lab=r.getNodeByName('Mountain_017_'+kind);ground=r.getNodeByName('Plane001');show(lab)
  need(bool(lab.showCollisionShapes),'Scene lost collision-display setting')
  need(stats(lab)['preview']==paused['preview'],'Scene lost pending bodies')
  need(mesh_hash(lab)==mesh_before,'Scene changed cached preview geometry')
  press('startButton');pump(.1);r.cplSynchronize(lab.physicsDocument)
  need(stats(lab)['painting'] and not stats(lab)['live']['paused'],'Saved session failed to Resume')
  # Finish is tested after independent live motion and more than one stroke.
  press('finishButton');until=time.monotonic()+33
  while stats(lab)['active'] and not stats(lab)['timedOut'] and time.monotonic()<until:r.cplTick(lab.physicsDocument,1);pump(.02)
  end=stats(lab);settled=not end['active']
  if not settled:
   need(end['timedOut'],'Finish did not settle or reach its explicit bound')
   press('keepButton');until=time.monotonic()+5
   while stats(lab)['active'] and time.monotonic()<until:r.cplTick(lab.physicsDocument,1);pump(.02)
  need(not stats(lab)['active'] and stats(lab)['rows']>1,'Finish/Freeze failed to preserve the composition')
  saved_rows=str(r.cplRows(lab.physicsDocument));r.execute('max undo');r.execute('max redo')
  need(str(r.cplRows(lab.physicsDocument))==saved_rows,'Completed result Undo/Redo changed poses')
  r.cplExportFile(lab.physicsDocument,str(out/(kind+'-result.json')))
  report['cases'].append({'kind':kind,'source':str(source.name) if r.isValidNode(source) else kind,'initial':first,'live':moving,'overlay':shown,'mesh':mesh_before,'final':stats(lab),'finish_settled':settled})
  (out/'mountain-results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
  # Show/hide and owner deletion must remove the non-owning draw registration.
  r.CPLMountainLab=lab;r.execute('delete CPLMountainLab');r.redrawViews()
  need(not r.isValidNode(lab),'Owner deletion failed')
  # Reloading invalidates old Python node wrappers; reacquire actual source nodes.
  for j in range(index+1,len(sources)):
   k,s,ra,sp=sources[j];name={'original_pyramid':'Pyramid001','pyramid_original_radius':'Pyramid001','teapot':'Mountain_Test_Teapot','torus':'Mountain_Test_Torus','tall_box':'Mountain_Test_Box'}[k]
   sources[j]=(k,r.getNodeByName(name),ra,sp)
  original=r.getNodeByName('Pyramid001')
 need(any(c['live']['live']['blocked']>0 for c in report['cases']),'Host matrix did not exercise blocked births')
 info=str(r.cplDiagnosticInfo());need('"recording":true' in info and '"watcher_alive":true' in info,'Crash recorder/watcher unavailable')
 report['diagnostic_status']=json.loads(info);report['pass']=True
 (out/'assertions.txt').write_text('PASS '+str(report['checks'])+' actual-mountain/shape/continuous/overlay/Undo/recovery checks\n',encoding='utf-8')
except Exception as e:
 report['error']=str(e);raise
finally:(out/'mountain-results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

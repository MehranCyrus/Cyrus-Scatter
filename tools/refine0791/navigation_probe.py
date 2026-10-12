"""Measure cached navigation and diagnostic redraw variants in a private Max host."""
from pathlib import Path
import hashlib,json,statistics,time,traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('refine0791-navigation'):
    raise RuntimeError('Owned navigation host required')
phase=str(r.N79Phase)
report=dict(phase=phase,errors=[],measurements=[])
def write():
    (OUT/('navigation-'+phase+'.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def nodes():return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject']
def state():
    results=[]
    for node in nodes():
        root=node.baseObject;owner=r.CyrusPointOwner(node)
        results.append(dict(name=str(node.name),epoch=int(root.procEpoch),groups=list(map(int,root.groupCounters())),
            retained=None if owner is None else list(map(str,r.cyrusRetainedStats(owner))),
            layers=[dict(id=str(leaf.layerID),builds=int(leaf.previewBuildCount),prepared=int(leaf.procPreparedBuilds),
                         receivers=list(map(str,leaf.receiverCacheStats())),shown=int(leaf.cachedPointCount),
                         dirty=bool(leaf.dirty),error=str(leaf.previewError)) for leaf in root.layerObjects]))
    return results
def pump(ms):r.execute(f'(local finish=timeStamp()+{ms};while timeStamp()<finish do (windows.processPostedMessages();sleep .01))')
def background_state():
    return dict(analyzers={str(n.name):int(n.baseObject.getAnalysisRuns()) for n in r.objects if str(r.classOf(n.baseObject))=='CyrusSurfaceAnalyzer'},
                pf_builds=int(r.CyrusPFBuilds),live_events=int(r.CyrusLiveChangeCalls),
                input_validity={str(n.name):[list(map(str,n.baseObject.inputTimeStats()))]+[list(map(str,l.inputTimeStats())) for l in n.baseObject.layerObjects] for n in nodes()})
def measure(mode,motion,label,held=0,count=12):
    before=state();background_before=background_state()
    result=r.N79Measure(mode,motion,count,held=held)
    samples=list(map(float,result[0]))
    report['measurements'].append(dict(label=label,mode=mode,motion=motion,held=held,samples_ms=samples,
        median_ms=statistics.median(samples),callbacks=int(result[1]),
        breakdown_total_ms=dict(zip(('icons','entries','preview','radii','retained_match','fallback','callback'),map(float,result[2]))),
        before=before,after=state(),background_before=background_before,background_after=background_state()))
    write()
try:
    if phase=='load':
        path=OUT/'input-examples.max'
        report['input_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
        started=time.perf_counter();r.loadMaxFile(str(path),quiet=True,useFileUnits=True)
        report['load_ms']=(time.perf_counter()-started)*1000
        pump(1000)
        report['before_first_update']=state()
        started=time.perf_counter()
        for node in nodes():node.baseObject.refreshAll()
        r.CyrusPointSync();r.completeRedraw();pump(1000)
        report['first_update_all_ms']=(time.perf_counter()-started)*1000
        report['inventory']=[dict(name=str(n.name),mode=int(n.baseObject.updateMode),layers=[dict(
            name=str(n.baseObject.layerNames[i]),count=int(leaf.generatedCount),shown=int(leaf.cachedPointCount),
            radii=int(leaf.radiusDisplayCount()),radius_limit=int(leaf.radiusDisplayLimit),radius_all=bool(leaf.radiusDisplayAll),
            show_radius=list(map(bool,leaf.sourceShowRadius)),viewport_mode=int(leaf.viewportMode),
            points_per_plant=int(leaf.pointsPerPlant),show_centers=bool(leaf.showCenters),
            fingerprint=str(r.cyrusEditFingerprint(n.baseObject.groupSnapshotRows[i],'areas')))
            for i,leaf in enumerate(n.baseObject.layerObjects)]) for n in nodes()]
        report['before_idle']=state();pump(2500);report['after_idle']=state()
        r.fileIn(str(Path(__file__).with_suffix('.ms')))
        report['view_tm']=str(r.viewport.getTM());report['view_type']=str(r.viewport.getType())
        bitmap=r.gw.getViewportDib();bitmap.filename=str(OUT/'navigation-scene.png');r.save(bitmap);r.close(bitmap)
        report['realized']=state()
    elif phase in ('ab','perspective'):
        if phase=='perspective':
            receivers=[]
            for n in nodes():
                for leaf in n.baseObject.layerObjects:
                    for surface in leaf.surfaceNodes:
                        if surface not in receivers:receivers.append(surface)
            bounds=[r.nodeGetBoundingBox(n,r.matrix3(1)) for n in receivers]
            lo=r.Point3(*[min(float(b[0][i]) for b in bounds) for i in range(3)])
            hi=r.Point3(*[max(float(b[1][i]) for b in bounds) for i in range(3)])
            center=(lo+hi)*0.5;span=float(r.length(hi-lo))
            eye=center+r.Point3(0,-span*.65,span*1.1)
            normal=r.normalize(eye-center);right=r.normalize(r.cross(r.Point3(0,0,1),normal));up=r.cross(normal,right)
            r.viewport.setType(r.Name('view_persp_user'))
            r.viewport.setTM(r.inverse(r.matrix3(right,up,normal,eye)))
        r.fileIn(str(Path(__file__).with_suffix('.ms')))
        report['view_type']=str(r.viewport.getType());report['view_tm']=str(r.viewport.getTM())
        if phase=='perspective':
            r.completeRedraw()
            bitmap=r.gw.getViewportDib();bitmap.filename=str(OUT/'navigation-perspective.png');r.save(bitmap);r.close(bitmap)
        # Warm alternating order, same scene/view/point buffers. No product file changes.
        for mode,label in [(-1,'original'),(0,'instrumented-full'),(1,'without-radius-overlay'),
                           (2,'cached-access-with-radii'),(3,'cached-access-no-radii'),(4,'no-scatter-script-overlay'),
                           (1,'without-radius-repeat'),(0,'instrumented-full-repeat'),(-1,'original-repeat')]:
            measure(mode,1,label)
        measure(0,1,'held-input-full',held=1)
        measure(1,1,'held-input-without-radii',held=1)
        for motion,label in [(0,'static'),(2,'pan'),(3,'zoom')]:
            measure(-1,motion,'original-'+label)
        report['after_idle_before']=state();pump(1000);report['after_idle_after']=state()
    elif phase=='controls':
        targets=[n for n in nodes() if any(int(l.radiusDisplayCount()) for l in n.baseObject.layerObjects)]
        saved=[(n,int(n.baseObject.radiusDisplayLimit),bool(n.baseObject.radiusDisplayAll)) for n in targets]
        def panel(node):
            r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(node.baseObject)
            root=node.baseObject
            if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
            result=root.previewUI;result.open=True;result.bind(None)
            if not result.controlsReady or not result.flow_previewUI_controlsReady:raise RuntimeError('Viewport panel not bound')
            return result
        report['control_edits']=[]
        try:
            r.clearSelection();measure(-1,1,'original-before-controls')
            for cap in (250,0):
                for node in targets:
                    ui=panel(node);root=node.baseObject;before=state();started=time.perf_counter()
                    ui.flow_previewUI_radiusLimitSpin.changed(cap)
                    report['control_edits'].append(dict(name=str(node.name),cap=cap,
                        handler_ms=(time.perf_counter()-started)*1000,before=before,after=state()))
                    write()
                r.clearSelection();pump(400)
                report['control_edits'].append(dict(cap=cap,total_rings=sum(int(l.radiusDisplayCount()) for n in nodes() for l in n.baseObject.layerObjects)))
                measure(-1,1,'original-radius-cap-'+str(cap))
            # A display-only change should not publish pending Manual placement edits.
            node=targets[0];root=node.baseObject;leaf=root.layerObjects[0];ui=panel(node)
            amount=int(leaf.amount);before_epoch=int(root.procEpoch)
            before_fp=str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'areas'))
            try:
                leaf.amount=amount+137
                pending_epoch=int(root.procEpoch)
                ui.flow_previewUI_radiusLimitSpin.changed(1)
                report['manual_pending_radius_change']=dict(name=str(node.name),mode=int(root.updateMode),
                    amount_before=amount,amount_pending=int(leaf.amount),epoch_before=before_epoch,
                    epoch_while_pending=pending_epoch,epoch_after_radius=int(root.procEpoch),
                    fingerprint_before=before_fp,fingerprint_after=str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'areas')))
            finally:
                leaf.amount=amount;root.refreshAll()
        finally:
            for node,limit,all_radii in saved:
                ui=panel(node);ui.flow_previewUI_radiusLimitSpin.changed(limit)
                if bool(node.baseObject.radiusDisplayAll)!=all_radii:ui.flow_previewUI_radiusAllCheck.changed(all_radii)
            r.clearSelection();pump(400)
            measure(-1,1,'original-controls-restored')
        report['restored_fingerprints']={str(n.name):[str(r.cyrusEditFingerprint(rows,'areas')) for rows in n.baseObject.groupSnapshotRows] for n in nodes()}
    else:raise ValueError(phase)
except Exception:
    report['errors'].append(traceback.format_exc())
finally:
    if phase!='load':
        try:r.N79Restore()
        except Exception:report['errors'].append('Restore failed: '+traceback.format_exc())
    write()

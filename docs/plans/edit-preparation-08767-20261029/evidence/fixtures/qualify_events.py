"""Owned Max 2027 edit pin and presented held-gesture regression."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback,statistics
RUN=Path(__file__).resolve().parent;OUT=Path(str(r.GardenRun));report={}
def save(): (OUT/'edit-qualification.json').write_text(json.dumps(report,indent=2))
def pump(n=12):
    if "terraces" in OUT.name:n=min(n,3)
    for _ in range(n):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.03)
def matrix(m):return [[float(m[i][j]) for j in range(3)] for i in range(4)]
def rows():return list(r.cyrusEditInspect(r.EREdit,0,500)[3])
def picked():return next(x for x in rows() if str(x[4])==report['selected_id'])
def state():
    row=picked()
    return dict(epoch=int(r.ERRoot.procEpoch),source=str(row[2]),delta=matrix(row[10]),base=matrix(row[11]),shown=matrix(row[12]),error=str(r.ERLayer.previewError),group=list(r.ERRoot.groupCounters()),streams=list(r.cyrusRetainedStreamStats()),presentation=list(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.ERNode))) if r.CyrusPointOwner(r.ERNode) else [],display_error=str(r.CyrusPointLastError))
def capture(name):
    b=r.gw.getViewportDib();b.filename=str(OUT/name);r.save(b);r.close(b)
def check(value,message):
    if not value:raise AssertionError(message)
    report.setdefault('passed',[]).append(message);save()
def campaign():
    try:
        version=str(r.CyrusLibraryVersion());report['version']=version;baseline=version=='0.87.6.5'
        if not r.cyrusLicenseAllows():
            if not str(r.cyrusLicenseStatus()[4]).startswith("review-"):raise RuntimeError("Production test requires an existing valid license")
            req=RUN/('authority/request-'+OUT.name+'.json');req.write_text(str(r.cyrusLicenseRequest()));license=req.with_suffix('.test-license');until=time.monotonic()+45
            while not license.exists() and time.monotonic()<until:time.sleep(.1)
            r.cyrusLicenseImport(license.read_text());assert r.cyrusLicenseAllows()
        r.CyrusSelectionTimer.Stop()
        real='terraces' in OUT.name
        if real:
            assert r.loadMaxFile(str(RUN/'Terraces-owned.max'),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
            r.execute('global ERNode=getNodeByName "GARDEN | Woodland framing",ERRoot=ERNode.baseObject,ERLayer=ERRoot.layerObjects[3],EREdit=CyrusScatterEdit();addModifier ERNode EREdit;ERRoot.selectLayer 3;ERRoot.updateMode=2;ERRoot.refreshAll();select ERNode;max modify mode;modPanel.setCurrentObject EREdit;subObjectLevel=1;cyrusEditActiveLayers EREdit #(ERLayer.editLayerKey)')
        else:
            r.execute('''resetMaxFile #noPrompt
            global ERPlane=plane length:1000 width:1000 lengthsegs:1 widthsegs:1
            global ERSource=box length:12 width:12 height:40 pos:[2000,0,0]
            global ERNode=AminScatterObject name:"Owned pinned Edit",ERRoot=ERNode.baseObject,ERLayer,EREdit
            ERRoot.surfaceNodes=#(ERPlane);ERRoot.newLayer();ERLayer=ERRoot.selectedLayer();ERLayer.addModelSource ERSource
            ERLayer.amount=400;ERLayer.randomSeed=76102;ERRoot.updateMode=2;ERRoot.autoRender=false;ERRoot.setGroupDisplay 3;ERRoot.refreshAll()
            EREdit=CyrusScatterEdit();addModifier ERNode EREdit;ERRoot.refreshAll()
            hide ERSource;viewport.setType #view_top;select ERPlane;max zoomext sel
            select ERNode;max modify mode;modPanel.setCurrentObject EREdit;subObjectLevel=1
            ''')
        pump(30);report['setup_ready']=True;save();yield
        r.cyrusEditSelect(r.EREdit,r.Array(1));pump(15)
        report['selected_id']=str(next(x for x in rows() if x[7])[4]);report['initial']=state();save();capture('before-drag.png')
        r.loadDllsFromDir(str(RUN/'probe')+'/', 'SelectionProbeV2.dlx')
        # The actual SDK gesture is sampled while the ordinary script held gate is true.
        r.execute('global ERHeldOriginal=CyrusInteractionHeld;fn CyrusInteractionHeld = true')
        r.selectionProbeGesture(0);report['held']=[];yield
        for i in range(3):
            start=time.perf_counter();r.selectionProbeGesture(1);callback=(time.perf_counter()-start)*1000
            pump(12);report['held'].append(dict(callback_ms=callback,state=state()));save();yield
        capture('held-drag.png')
        for i,sample in enumerate(report['held']):
            check(sample['state']['epoch']==report['initial']['epoch'],'held step '+str(i)+' does not regenerate')
            check(sample['state']['group'][0]==report['initial']['group'][0] and sample['state']['group'][2]==report['initial']['group'][2],'held step '+str(i)+' reuses placement and source preparation')
            check(sample['state']['streams'][1]==report['initial']['streams'][1],'held step '+str(i)+' reuses geometry uploads')
            if not baseline:check(abs(sample['state']['shown'][3][0]-report['initial']['shown'][3][0]-20*(i+1))<.02,'held step '+str(i)+' presents its moved mesh')
        r.execute('CyrusInteractionHeld=ERHeldOriginal');r.selectionProbeGesture(2);yield
        r.ERRoot.refreshAll();pump(25);report['released']=state();save();yield
        check(abs(report['released']['shown'][3][0]-report['initial']['shown'][3][0]-60)<.02,'release preserves the authored movement')
        if baseline and not real:
            assert r.saveMaxFile(str(OUT/'edited-08765.max'),quiet=True);yield
            r.ERRoot.refreshAll();pump(25)
        before=report['released']['shown'];source=report['released']['source'];untouched={str(x[4]):matrix(x[12]) for x in rows() if x[6] and str(x[4])!=report['selected_id']}
        r.ERLayer.randomSeed=int(r.ERLayer.randomSeed)+1;r.ERLayer.markInputDirty();r.ERRoot.refreshAll();pump(20);report['reseed']=state();save();yield
        if baseline:
            check('Generation settings changed' in report['reseed']['error'],'baseline reproduces Seed compatibility error')
        else:
            check(not report['reseed']['error'],'Seed changes without an error')
            check(report['reseed']['shown']==before and report['reseed']['source']==source,'reseed preserves edited full transform and source')
            check(any(str(x[4]) in untouched and matrix(x[12])!=untouched[str(x[4])] for x in rows() if x[6]),'unedited instances follow the changed Seed')
            # Cancel across a real native hold, then qualify the completed result.
            r.execute('fn CyrusInteractionHeld = true');r.selectionProbeGesture(0);yield
            r.selectionProbeGesture(1);pump(15);yield
            report['before_cancel']=state();r.selectionProbeGesture(3);r.execute('CyrusInteractionHeld=ERHeldOriginal');yield
            r.ERRoot.refreshAll();pump(25)
            report['cancelled']=state();save();check(state()['shown']==before and bool(state()['presentation']),'cancel restores the complete pinned transform');yield
            r.execute('clearUndoBuffer();cyrusEditResetSelected EREdit');yield
            r.ERRoot.refreshAll();pump(25);report['reset']=state();save()
            check(report['reset']['shown']!=before,'Reset selected returns the instance to the current procedural result')
            r.execute('max undo');yield
            r.ERRoot.refreshAll();pump(25);check(state()['shown']==before,'Undo restores the selected pin')
            r.execute('max redo');yield
            r.ERRoot.refreshAll();pump(25);check(state()['shown']==report['reset']['shown'],'Redo restores selected reset')
            r.execute('max undo');yield
            r.ERRoot.refreshAll();pump(25)
            if not real:
                path=OUT/'pin-roundtrip.max';assert r.saveMaxFile(str(path),quiet=True);yield
                assert r.loadMaxFile(str(path),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'));yield
                r.execute('ERNode=getNodeByName "Owned pinned Edit";ERRoot=ERNode.baseObject;ERLayer=ERRoot.layerObjects[1];EREdit=ERNode.modifiers[1];ERRoot.refreshAll()');pump(25)
                check(state()['shown']==before,'save/reopen retains the pinned transform')
                r.ERLayer.randomSeed=int(r.ERLayer.randomSeed)+1;r.ERLayer.markInputDirty();r.ERRoot.refreshAll();pump(25)
                check(not state()['error'] and state()['shown']==before,'another Seed after reopen preserves the pin')
                yield
                r.ERLayer.scaleMinimum=2.0;r.ERLayer.scaleMaximum=2.0;r.ERLayer.markInputDirty();r.ERRoot.refreshAll();pump(20)
                check(not state()['error'] and state()['shown']==before,'global size variation changes preserve the edited transform')
                # Export/replay the actual native portable payload after multiple reseeds.
                r.ERExport=r.execute('cyrusEditRecipeExport EREdit #(#(ERLayer.editLayerKey,ERLayer.layerID,(ERLayer.procSourceEditBinding (ERLayer.validSources()) ERLayer.procPreparedRows)))')
                report['portable_payload']=json.loads(str(r.ERExport));save()
                r.execute('global ERSources=for id in ERLayer.procSourceIDs collect #(id,id);deleteModifier ERNode EREdit;EREdit=CyrusScatterEdit();undo "Owned portable replay" on (addModifier ERNode EREdit;cyrusEditRecipeImport EREdit ERExport #(#(ERLayer.layerID,ERLayer.editLayerKey,ERSources)) "{}")')
                yield
                r.ERRoot.refreshAll();pump(25)
                check(not state()['error'] and max(abs(state()['shown'][i][j]-before[i][j]) for i in range(4) for j in range(3))<.001,'portable replay retains the reseeded pin')
                # Pending Manual parameters must remain pending during native movement.
                r.execute('select ERNode;max modify mode;modPanel.setCurrentObject EREdit;subObjectLevel=1;cyrusEditSelect EREdit #(1)')
                pump(15);r.ERRoot.updateMode=1;r.ERLayer.amount=int(r.ERLayer.amount)+17;r.ERLayer.randomSeed=int(r.ERLayer.randomSeed)+1;r.ERLayer.markInputDirty();pump(15)
                pending_count=int(r.ERLayer.generatedCount);pending_epoch=int(r.ERRoot.procEpoch)
                r.execute('fn CyrusInteractionHeld = true');r.selectionProbeGesture(0);yield
                r.selectionProbeGesture(1);pump(15)
                check(int(r.ERLayer.generatedCount)==pending_count and int(r.ERRoot.procEpoch)==pending_epoch,'held Edit leaves pending Manual amount and Seed unapplied')
                r.selectionProbeGesture(2);r.execute('CyrusInteractionHeld=ERHeldOriginal');yield
                pump(20);check(int(r.ERLayer.generatedCount)==pending_count,'release does not consume pending Manual population')
                r.ERRoot.refreshAll();pump(20);check(int(r.ERLayer.generatedCount)==417,'explicit Update applies pending population')

        report['callback_median_ms']=statistics.median(x['callback_ms'] for x in report['held']);report['status']='complete';(OUT/'completed.json').write_text(json.dumps(report,indent=2))
    except Exception:
        report.update(status='failed',error=traceback.format_exc()); (OUT/'error.txt').write_text(report['error'])
    finally:
        try:r.execute('if ERHeldOriginal!=undefined do CyrusInteractionHeld=ERHeldOriginal')
        except Exception:pass
        save()

import builtins
_generator=campaign()
def tick():
    r.ERTestTimer.Stop()
    try:
        next(_generator)
        r.ERTestTimer.Start()
    except StopIteration:
        r.execute('resetMaxFile #noPrompt;gc light:true;quitMax #noPrompt quiet:true exitCode:0')
    except Exception:
        (OUT/'error.txt').write_text(traceback.format_exc());r.execute('quitMax #noPrompt quiet:true exitCode:1')
builtins._cyrus_edit_tick=tick
r.execute('''global ERTestTimer=dotNetObject "System.Windows.Forms.Timer"
ERTestTimer.Interval=350
fn ERTestTick sender args = (python.Execute "import builtins; builtins._cyrus_edit_tick()")
dotNet.addEventHandler ERTestTimer "Tick" ERTestTick
ERTestTimer.Start()
''')

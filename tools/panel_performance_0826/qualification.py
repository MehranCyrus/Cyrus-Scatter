"""I01/I02 host qualification. Executes only in a recorded private Max 2027 host."""
from pathlib import Path
import hashlib
import json
import math
import shutil
import statistics
import sys
import time
import traceback
import pymxs
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification'
assert OUT.name.startswith('foundation-roadmap-panel0826-')
assert json.loads((OUT/'launch.json').read_text())['max_year'] == 2027
sys.path.insert(0, str(ROOT/'tools/recipes_0825'))
from recipe_rows import fingerprint
req = json.loads((OUT/'panel-command.json').read_text())
op = req['operation']
result = {'operation': op, 'checks': [], 'status': 'running'}
target = OUT/('qualification-'+req.get('label', op)+'.json')

def save():
    target.write_text(json.dumps(result, indent=2))

def check(value, label):
    result['checks'].append({'passed': bool(value), 'assertion': label})
    save()
    assert value, label

def root():
    return r.PanelRoot

def hashes():
    return [fingerprint(rows) for rows in root().groupSnapshotRows]

def counters():
    owner = r.CyrusPointOwner(r.PanelNode)
    native = list(r.cyrusRetainedStats(owner))
    return {'epoch': int(root().procEpoch), 'solves': int(root().groupBuilds),
            'prepared': [int(x.procPreparedBuilds) for x in root().layerObjects],
            'previews': [int(x.previewBuildCount) for x in root().layerObjects],
            'map_bakes': [int(x.procDensityBakes) for x in root().layerObjects],
            'mesh_density': [int(x) for x in r.cyrusMeshDensityStats()],
            'source_geometry': [int(x) for x in r.cyrusSourceGeometryStats()],
            'retained_prepare': int(native[3]), 'uploads': int(native[5]), 'upload_bytes': int(native[6])}

def timed(fn, count):
    values = []
    for i in range(count):
        start=time.perf_counter();fn(i);values.append((time.perf_counter()-start)*1000)
    return {'samples_ms': values, 'median_ms': statistics.median(values),
            'p95_ms': sorted(values)[math.ceil(.95*len(values))-1]}

def mount():
    r.CyrusPerfHeadless=False
    r.select(r.PanelNode)
    r.execute('max modify mode')
    if r.modPanel.getCurrentObject()!=root():r.modPanel.setCurrentObject(root())
    if not root().mainUI.controlsReady:root().mainUI.mountTimer.tick()

def page(index, opened=True):
    slot=root().mainUI.slots[index]
    slot.open=opened
    slot.rolledUp(not opened)
    return root().mainUI.editors[index]

def recording(label):
    r.cyrusDiagnosticStop()
    r.cyrusDiagnosticStart(label,4096,4194304,600000)

def stages():
    return {x['stage']:x for x in json.loads(str(r.cyrusDiagnosticSnapshot(0,0)))['measurements']['stages']}

def events():
    rows=[];cursor=0
    for _ in range(40):
        value=json.loads(str(r.cyrusDiagnosticSnapshot(cursor,500)));rows.extend(value['events'])
        if not value['has_more']:return rows
        cursor=value['next_sequence']
    raise AssertionError('Unbounded diagnostic paging')

def unchanged_work(before, after):
    # Cache hit counters can change during explicit inspection; extraction misses
    # and generated work cannot. Counter 1 is metadata reads, counter 2 cache hits.
    keys=['epoch','solves','prepared','previews','map_bakes','mesh_density','retained_prepare','uploads','upload_bytes']
    return all(before[k]==after[k] for k in keys) and before['source_geometry'][1]==after['source_geometry'][1]

try:
    with pymxs.undo(False):
        save()
        if op=='inspect':
            result['state']={k:str(getattr(r,k)) for k in ['CyrusPointSuspended','CyrusPointBusy','CyrusPointLastError','CyrusTimeOwners','CyrusPointOwners','PanelNode','PanelRoot']}
            result['hold']=bool(r.theHold.Holding())
            result['count']=len(root().layerObjects)
            result['rows']=hashes()
        elif op=='presentation_scene':
            r.execute('global PanelRoot,PanelNode,PanelReceiver,PanelOther')
            previous=ROOT/'build/mcp-qualification/foundation-roadmap-panel0826-final100-20261015-01'
            copied=OUT/'presentation-input.max';shutil.copy2(previous/'panel-current.max',copied)
            r.CyrusPerfHeadless=True
            check(r.loadMaxFile(str(copied),quiet=True,useFileUnits=True),'Load owned populated Paint/Band fixture for final captions')
            r.PanelNode=r.getNodeByName('Panel performance owned fixture');r.PanelRoot=r.PanelNode.baseObject
            r.PanelReceiver=root().layerObjects[0].validSurfaces()[0];r.PanelOther=r.getNodeByName('Box001')
            root().refreshAll();r.CyrusPointSync();mount()
            check(hashes()==json.loads((previous/'qualification-paint-bands.json').read_text())['saved_rows'],'Presentation-only corrections preserve complete rows')
            root().mainUI.selectLayerView(root().layerObjects[1]);p=page(4)
            check(str(p.diversityUI_removePath.text)=='\u00d7' and str(p.diversityUI_addOutside.text)=='\u2197' and str(p.diversityUI_addInside.text)=='\u2199','Band button glyphs render from correct Unicode text')
            result['input_sha256']=hashlib.sha256(copied.read_bytes()).hexdigest()
            result['loaded_payload_fingerprint']=str(r.CyrusLoadedScriptFingerprint)
            r.cyrusDiagnosticStop()
        elif op=='load':
            r.execute('global PanelRoot,PanelNode,PanelReceiver,PanelOther')
            baseline=ROOT/'build/mcp-qualification/foundation-roadmap-panel0826-baseline-20261015-01'
            original=baseline/'panel-baseline.max';copied=OUT/'baseline-input.max'
            shutil.copy2(original,copied)
            result['input_sha256']=hashlib.sha256(copied.read_bytes()).hexdigest()
            r.CyrusPerfHeadless=True
            check(r.loadMaxFile(str(copied),quiet=True,useFileUnits=True),'Load copied 0.82.5 fixture')
            r.PanelNode=r.getNodeByName('Panel performance owned fixture');r.PanelRoot=r.PanelNode.baseObject
            r.PanelReceiver=root().layerObjects[0].validSurfaces()[0]
            r.PanelOther=r.getNodeByName('Box001')
            check(str(root().uiVersion())=='0.82.6','Loaded script version 0.82.6')
            recording('candidate_load')
            root().refreshAll();r.CyrusPointSync();r.completeRedraw()
            result['rows']=hashes()
            baseline_rows=json.loads((baseline/'panel-save_fixture.json').read_text())['rows']
            check(result['rows']==baseline_rows,'Exact ordered eight-field publication equals 0.82.5')
            result['stages']=stages()
            check(result['stages']['candidates']['calls']>0 and result['stages']['geometry_extract']['calls']>0,'Counters observe actual input/candidate work')
            r.cyrusDiagnosticStop()
            result['mount']=timed(lambda i:mount(),1)
            check(sum(bool(p.isDisplayed) for p in root().mainUI.editors)<12,'Closed page controls are not constructed on selection')
            result['before']=counters() if r.CyrusPointOwner(r.PanelNode) is not None else {'pending_host_display':True}
        elif op=='panels':
            mount();before=counters();before_hash=hashes();recording('panel_cycles')
            result['before']=before
            handles={}
            for i in range(12):
                p=page(i)
                check(bool(p.controlsReady) and p.root==root(),'Page '+str(p.name)+' binds current setup')
                handles[i]=str(p.hwnd)
                page(i,False)
            page(0)
            result['first_open_stages']=stages()
            creations=result['first_open_stages']['ui_create']['calls']
            def cycle(i):
                p=page(1+i%11)
                check(str(p.hwnd)==handles[1+i%11],'Cycle '+str(i)+' retains controls')
                # Invoke the generated native list selection handler, including its
                # captured owner and rebind behavior, rather than only setting a field.
                r.execute('PanelRoot.managerUI.flow_layersUI_layerList_colored.SetSelected '+str(i%len(root().layerObjects))+' true')
                check(p.owner==root().logicalParent(root().selectedLayer()),'Cycle '+str(i)+' binds selected layer')
                page(1+i%11,False)
            result['cycles']=timed(cycle,req.get('count',100))
            result['after']=counters();result['stages']=stages()
            check(result['stages']['ui_create']['calls']==creations,'Warm panel cycles create no replacement controls')
            check(unchanged_work(before,result['after']),'Browsing changes no solve, extraction, preparation or upload counters')
            check(all(result['stages'][key]['calls']==0 for key in ['geometry_extract','mesh_channel_extract','candidates','mask_filter','surface_filter','attributes_radii','spacing','preview_prepare','buffer_upload','publication','map_bake']),'Recorded panel work is UI-only')
            check(hashes()==before_hash,'Panel cycles preserve full publication rows')
            r.cyrusDiagnosticStop()
        elif op=='manual':
            mount();root().mainUI.updateRadio.changed(1)
            p=page(5);leaf=root().selectedLayer();before=counters();rows=hashes()
            new_amount=int(leaf.amount)+7
            p.distributionUI_countSpin.value=new_amount;p.distributionUI_countSpin.changed(new_amount)
            check(int(leaf.amount)==new_amount,'Actual Amount handler edits its captured layer')
            for i in range(12):page(i);page(i,False)
            page(0)
            check(hashes()==rows and counters()['epoch']==before['epoch'],'Manual pending survives panel browsing without publication')
            result['pending']=json.loads(str(r.CyrusDiagnosticState(root())))
            root().mainUI.updateNow.pressed()
            check(counters()['epoch']>before['epoch'] and hashes()!=rows,'Explicit Update publishes pending amount')
            check(not any(str(x.previewError) for x in root().layerObjects),'Update leaves no layer errors')
            root().mainUI.updateRadio.changed(2)
        elif op=='live':
            mount();page(5);root().mainUI.updateRadio.changed(2);root().refreshAll();r.CyrusPointSync()
            result['before']=counters();result['rows']=hashes()
            recording('relevant_ui_edit')
            p=root().populationUI;value=int(root().selectedLayer().amount)+3
            p.distributionUI_countSpin.value=value;p.distributionUI_countSpin.changed(value)
            result['expected_amount']=value
        elif op=='live_observe':
            before=json.loads((OUT/'qualification-live.json').read_text())
            check(counters()['epoch']>before['before']['epoch'],'Live event loop publishes the relevant edit')
            check(hashes()!=before['rows'],'Live changed full rows')
            check(not any(str(x.previewError) for x in root().layerObjects),'Live publication succeeds')
            result['after']=counters()
            result['events']=events();result['stages']=stages()
            actions={e['action_id'] for e in result['events'] if e['name']=='ui.action' and e['action_id']>0}
            check(bool(actions),'UI action receives a nonzero correlation ID')
            check(any(e['name']=='input.invalidated' and e['action_id'] in actions for e in result['events']),'Invalidation carries the originating action ID')
            check(any(e['name']=='publication.committed' and e['action_id'] in actions for e in result['events']),'Deferred publication carries the originating action ID')
            check(int(r.CyrusActiveActionID)==0,'UI handler releases action scope before returning to the host loop')
            r.cyrusDiagnosticStop()
        elif op=='unrelated':
            before=counters();rows=hashes();recording('unrelated_animation')
            r.execute('with animate on (at time 0 PanelOther.pos=[9000,0,0];at time 10 PanelOther.pos=[9010,0,0])')
            for i in range(20):
                r.sliderTime=i;r.windows.processPostedMessages();r.completeRedraw()
            result['before']=before;result['after']=counters();result['stages']=stages()
            check(unchanged_work(before,result['after']) and hashes()==rows,'Unrelated animated object and timeline do not rebuild static scattering')
            r.cyrusDiagnosticStop()
        elif op=='undo_observe':
            baseline=ROOT/'build/mcp-qualification/foundation-roadmap-panel0826-baseline-20261015-01/panel-save_fixture.json'
            check(hashes()==json.loads(baseline.read_text())['rows'],'Native Undo restores exact complete eight-field rows')
            mount();page(0);page(5)
            check(root().populationUI.owner==root().selectedLayer(),'Restored panel binds restored owner')
        elif op=='failure':
            mount();root().mainUI.updateRadio.changed(1);root().refreshAll()
            before=hashes();epoch=int(root().procEpoch);leaf=root().selectedLayer()
            old=int(leaf.meshMaskChannel);leaf.meshMaskChannel=98;leaf.meshMaskEnabled=True
            recording('failed_successor')
            root().refreshAll()
            check(int(root().procEpoch)==epoch and hashes()==before,'Invalid channel successor retains complete prior publication')
            check(any(str(x.previewError) for x in root().layerObjects),'Failure is visible in layer status')
            leaf.meshMaskEnabled=False;leaf.meshMaskChannel=old;root().refreshAll()
            check(hashes()==before and not any(str(x.previewError) for x in root().layerObjects),'Corrected recipe recovers exact complete rows')
            r.cyrusDiagnosticStop()
        elif op=='failure_undo':
            count=len(root().layerObjects);before=hashes();page(0);r.clearUndoBuffer()
            result['before_remove']={'count':count,'rows':before,'ids':[str(x.layerID) for x in root().layerObjects]}
            root().managerUI.flow_layersUI_removeButton.pressed()
            check(len(root().layerObjects)==count-1,'Actual Remove handler completes after rebuilding controls')
            r.execute('max undo')
            result['after_undo']={'count':len(root().layerObjects),'rows':hashes(),'ids':[str(x.layerID) for x in root().layerObjects]}
            mount();root().refreshAll()
            result['after_undo_refresh']={'count':len(root().layerObjects),'rows':hashes(),'ids':[str(x.layerID) for x in root().layerObjects], 'errors':[str(x.previewError) for x in root().layerObjects]}
            check(len(root().layerObjects)==count and hashes()==before,'Undo restores layer owners and exact rows')
            check(root().mainUI.controlsReady,'Panel remains usable after Undo')
        elif op=='passive':
            mount();page(11);recording('passive_inspection');before=counters();rows=hashes()
            result['reads']=timed(lambda i:(r.CyrusDiagnosticState(root()),r.cyrusDiagnosticSnapshot(0,0),root().statisticsUI.diagnosticsUI_refresh()),100)
            after=counters();result['stages']=stages()
            check(unchanged_work(before,after) and rows==hashes(),'Passive status reads preserve work and full rows')
            check(all(x['calls']==0 for x in result['stages'].values()),'Passive diagnostics do not invoke measured stages')
            report=OUT/'diagnostic-export.json'
            root().statisticsUI.diagnosticsUI_saveReport(str(report))
            data=json.loads(report.read_text())
            check(data['selected_setup']['epoch']==int(root().procEpoch),'Export includes passive published setup snapshot')
            check(data['pages'][0]['measurements']['inclusive'],'Export identifies inclusive timing scope')
        elif op=='selection':
            mount()
            for i in range(12):page(i,False)
            page(0);root().mainUI.rememberViews()
            before=counters();rows=hashes()
            if req.get('record'):recording('selection_on')
            else:r.cyrusDiagnosticStop()
            def select(i):
                r.select(r.PanelOther);mount()
            result['timing']=timed(select,req.get('count',30))
            result['before']=before;result['after']=counters()
            check(unchanged_work(before,result['after']) and hashes()==rows,'Selection preserves publication and buffer work')
            if req.get('record'):result['stages']=stages()
            r.cyrusDiagnosticStop()
        elif op=='heavy':
            mount();root().mainUI.updateRadio.changed(1)
            r.PanelReceiver.widthsegs=300;r.PanelReceiver.lengthsegs=300
            root().viewportMode=3
            for leaf in root().layerObjects:leaf.amount=25000
            leaf=root().layerObjects[0]
            leaf.meshMaskChannel=1;leaf.meshMaskMinimum=-1.;leaf.meshMaskMaximum=0.;leaf.meshMaskEnabled=True
            root().refreshAll();root().updateMode=2;r.CyrusPointSync();r.completeRedraw()
            result['accepted']=[int(x.generatedCount) for x in root().layerObjects]
            check(sum(result['accepted'])==200000,'Heavy fixture contains 200,000 accepted placements')
            result['receiver_faces']=int(r.getNumFaces(r.snapshotAsMesh(r.PanelReceiver)))
            result['viewport_mode']=int(root().viewportMode)
        elif op=='paint_bands':
            mount();root().mainUI.updateRadio.changed(1)
            paint_owner,bands=list(root().layerObjects)[:2]
            paint=root().addPaintArea(paint_owner,target=r.PanelReceiver)
            border=r.Rectangle(name='Owned panel Paint border',width=800.,length=800.)
            root().importPaintSpline(paint,border,tolerance=.1)
            r.cyrusBrushSetFalloff(paint.paintDocument,r.Array(40.,10.,True,True,.3,1.2,r.Array(0.,.4,1.),r.Array(0.,.6,1.)))
            paint.publishPaint()
            path=r.Rectangle(name='Owned panel Band path',width=400.,length=400.)
            bands.diversityMode=3;bands.addStroke(path,side=2)
            bands.patternWidths[0]=100.;bands.strokeStarts[0]=0.;bands.strokeEnds[0]=100.
            bands.setStrokeSelection(1,2,r.Array(str(bands.sourceRowIDs[0])))
            bands.strokeCurveEnabled[0]=True;bands.strokeCurveSamples[0]='1,0.8,0.4,0.1'
            bands.strokeScaleModes[0]=3;bands.strokeScaleSamples[0]='0.3,0.7,1.2'
            root().refreshAll();r.CyrusPointSync();r.completeRedraw()
            check(all(int(x.generatedCount)>0 for x in [paint_owner,bands]),'Active Paint and Bands publish nonempty planting')
            before=counters();rows=hashes();recording('paint_bands_browsing')
            for i in range(20):
                root().mainUI.selectLayerView(paint_owner);p=page(6)
                check(p.brushUI_obj==paint,'Paint controls bind receiver-bound area after owner switch')
                root().mainUI.selectLayerView(bands);p=page(4)
                check(p.diversityUI_obj==bands,'Band controls bind the chosen layer after owner switch')
            check(unchanged_work(before,counters()) and hashes()==rows,'Active Paint/Band browsing does no calculation or upload')
            root().mainUI.selectLayerView(paint_owner);p=page(6)
            p.brushUI_densitySpin.value=60.;p.brushUI_densitySpin.changed(60.)
            check(abs(float(paint.paintDensity)-.6)<.0001,'Actual Paint density handler updates captured area')
            root().mainUI.selectLayerView(bands);p=page(4)
            p.diversityUI_strokeWidth.value=125.;p.diversityUI_strokeWidth.changed(125.)
            check(abs(float(bands.patternWidths[0])-125.)<.0001,'Actual Band width handler updates captured layer')
            check(hashes()==rows and counters()['epoch']==before['epoch'],'Manual Paint and Band changes retain published rows')
            root().managerUI.flow_layersUI_recipesButton.pressed()
            browser=r.CyrusRecipeBrowser;check(browser is not None,'Actual Recipes button opens from lazy manager')
            library=OUT/'panel-library';library.mkdir(exist_ok=True)
            browser.directory=str(library);browser.recipeName.text='Panel owners and Paint';browser.saveRecipe.pressed()
            files=list(library.glob('*.csrecipe.json'))
            check(len(files)==1 and 'Saved all' in str(browser.status.text),'Recipe Save Everything succeeds from current panel')
            document=r.cyrusRecipeRead(str(files[0]));layers=r.CyrusRecipeGet(document,'layers')
            check(str(r.CyrusRecipeGet(r.CyrusRecipeGet(r.CyrusRecipeGet(layers[0],'areas')[0],'paint'),'payload'))==str(r.cyrusBrushRecipeExport(paint.paintDocument)[0]),'Recipe includes exact authored Paint bytes')
            r.destroyDialog(browser)
            check(hashes()==rows and counters()['epoch']==before['epoch'],'Recipe browser preserves Manual pending publication')
            root().mainUI.updateNow.pressed();r.CyrusPointSync()
            check(not any(str(x.previewError) for x in root().layerObjects),'Paint/Band edits publish successfully on Update')
            result['saved_rows']=hashes()
            check(r.saveMaxFile(str(OUT/'panel-current.max'),quiet=True),'Save owned current scene with Paint and Bands')
            r.cyrusDiagnosticStop()
        elif op=='reopen':
            previous=json.loads((OUT/'qualification-paint-bands.json').read_text())
            r.CyrusPerfHeadless=True;r.loadMaxFile(str(OUT/'panel-current.max'),quiet=True,useFileUnits=True)
            r.PanelNode=r.getNodeByName('Panel performance owned fixture');r.PanelRoot=r.PanelNode.baseObject
            r.PanelReceiver=root().layerObjects[0].validSurfaces()[0];r.PanelOther=r.getNodeByName('Box001')
            root().refreshAll()
            check(hashes()==previous['saved_rows'],'Saved Paint/Band scene reopens with exact complete rows')
            mount()
            for i in range(12):
                p=page(i);check(p.controlsReady and p.root==root(),'Reopened '+str(p.name)+' binds current setup')
        elif op=='idle_arm':
            mount()
            if req.get('record'):recording('idle_on')
            else:r.cyrusDiagnosticStop()
            result['rows']=hashes();result['before']=counters()
            r.fileIn(str(ROOT/'tools/panel_performance_0826/idle.ms'))
        elif op=='idle_observe':
            text=(OUT/'panel-idle.txt').read_text()
            result['witness']=text;result['after']=counters()
            check('unchanged=true' in text,'60-second event-loop interval performs no extra published work')
            before=json.loads((OUT/('qualification-'+req['arm_label']+'.json')).read_text())
            check(hashes()==before['rows'],'Heavy idle preserves exact full publication')
            if req.get('record'):
                result['stages']=stages()
                check(all(x['calls']==0 for x in result['stages'].values()),'Enabled recorder observes zero measured idle stages')
            r.cyrusDiagnosticStop()
        elif op=='presentation':
            mount()
            for i in range(12):page(i,False)
            for i in [0,2,5,6]:page(i)
            result['bodies']={str(p.name):{'width':float(p.width),'height':float(p.height),'ready':bool(p.controlsReady)} for p in root().mainUI.editors if p.isDisplayed}
            check(all(v['width']>=140 and v['height']>0 for v in result['bodies'].values()),'Displayed bodies have valid dimensions')
        else:
            raise ValueError(op)
        result['status']='passed'
except Exception:
    result['status']='failed';result['error']=traceback.format_exc()
    raise
finally:
    save()

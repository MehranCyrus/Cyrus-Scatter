"""Run one phase on the Max thread, only in a private refinement profile.

The original 25-case artist file is never saved or modified. Numerical checks
use world distances and saved fingerprints, not just absence of exceptions.
"""
from pathlib import Path
import json,math,statistics,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('refine0791-'):
    raise RuntimeError('Owned refinement profile required')
phase=str(r.R791Phase)
path=OUT/(phase+'-results.json');checks=[];metrics={}
def write():path.write_text(json.dumps(dict(phase=phase,checks=checks,metrics=metrics),indent=2))
def check(ok,label,**details):
    checks.append(dict(passed=bool(ok),label=label,host_holding=bool(r.theHold.Holding()),**details));write()
    if not ok:raise AssertionError(label)
def mx(code):return r.execute('('+code+')')
def arr(values):return r.Array(*values)
def bits(*values):return r.execute('#{'+','.join(map(str,values))+'}')
def pump(ms=300):mx(f'local finish=timeStamp()+{ms};while timeStamp()<finish do (windows.processPostedMessages();sleep .01)')
def activate(node,page):
    r.select(node);mx('max modify mode');r.modPanel.setCurrentObject(node.baseObject)
    # Allow Max to create rollout HWNDs before invoking a timer manually.
    pump(200)
    root=node.baseObject
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    panel=getattr(root,page);panel.open=True;root.mainUI.bindSection(panel);panel.layout()
    return panel
def fp(root):return str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'areas'))
def update(root):
    root.refreshAll()
    for leaf in root.layerObjects:
        if str(leaf.previewError):raise RuntimeError(str(leaf.previewError))
def case(n):
    item=cases[n-1];node=r.getNodeByName(item['node_name'])
    return node,node.baseObject,node.baseObject.layerObjects[0]
def scales(root):return [float(r.length(row[0].row1)) for row in root.groupSnapshotRows[0]]
def positions(root):return [(str(row[2]),tuple(float(v) for v in row[0].row4)) for row in root.groupSnapshotRows[0]]
def clone_cfg(leaf,node):
    cfg=leaf.getFallConfig(node)
    return arr([arr(list(v)) if i in (4,7) else v for i,v in enumerate(cfg)])
cases=json.loads((ROOT/'build/vector-brush-078/include-exclude-visible2026-01/area-examples-results.json').read_text())['cases']
mx('global R791ExpectedVersion,R791PreviousHeld=CyrusInteractionHeld;fn CyrusInteractionHeld = false')
expected_version=str(r.R791ExpectedVersion) if r.R791ExpectedVersion is not None else '0.79.1'
try:
    check(bool(r.cyrusLicenseAllows()),'Active test authority authorizes normal editing')
    if phase=='scene':
        r.loadMaxFile(str(OUT/'input-examples.max'),quiet=True,useFileUnits=True);pump(750)
        saved=json.loads((ROOT/'build/vector-brush-078/include-exclude-visible2026-01/final-before-save.json').read_text())
        measured={};baseline={}
        for item in cases:
            node,root,leaf=case(item['number']);started=time.perf_counter();update(root)
            measured[item['number']]=round((time.perf_counter()-started)*1000,2)
            check(str(root.uiVersion())==expected_version,'Case %02d loads %s'%(item['number'],expected_version))
            check(fp(root)==saved[item['node_name']]['fingerprint'],'Case %02d preserves the saved placements'%item['number'],count=len(root.groupSnapshotRows[0]))
            baseline[item['node_name']]=fp(root)
        r.CyrusPointSync();r.redrawViews();pump(500)
        cold={}
        for item in cases:
            node,root,leaf=case(item['number']);owner=r.CyrusPointOwner(node)
            stats=r.cyrusRetainedStats(owner)
            cold[item['number']]=(int(root.procEpoch),int(leaf.receiverCacheStats()[0]),int(stats[2]),int(stats[5]))
        times=[]
        for _ in range(5):
            started=time.perf_counter()
            for item in cases:case(item['number'])[1].evaluateGroups()
            r.CyrusPointSync();r.redrawViews();times.append((time.perf_counter()-started)*1000)
        for item in cases:
            node,root,leaf=case(item['number']);stats=r.cyrusRetainedStats(r.CyrusPointOwner(node))
            now=(int(root.procEpoch),int(leaf.receiverCacheStats()[0]),int(stats[2]),int(stats[5]))
            check(now==cold[item['number']],'Case %02d unchanged reads reuse publication, receiver cache and point uploads'%item['number'])
        metrics.update(first_update_ms=measured,warm_all_cases_ms=times,warm_median_ms=statistics.median(times))
        (OUT/'baseline.json').write_text(json.dumps(baseline,indent=2))
        r.saveMaxFile(str(OUT/'Examples_0.79.1.max'),quiet=True);write()
    elif phase=='falloff':
        r.loadMaxFile(str(OUT/'Examples_0.79.1.max'),quiet=True,useFileUnits=True);pump(500)
        # Independent linear interpolation against planar world-space boundaries.
        metre=float(r.units.decodeValue('1m'))
        for number,base,amplitude,width,inset,outward in [(15,.2,.8,.3,.1,False),(25,.2,.8,.3,.1,True)]:
            node,root,leaf=case(number);guide=leaf.areaNodes[0];old=clone_cfg(leaf,guide)
            cfg=clone_cfg(leaf,guide);cfg[4]=arr([base,base+amplitude]);leaf.setFallConfig(guide,cfg);update(root)
            # Rectangular Area may be scaled; derive its world bounds directly.
            bb=r.nodeGetBoundingBox(guide,r.matrix3(1));lo,hi=bb[0],bb[1]
            errors=[]
            for row in root.groupSnapshotRows[0]:
                p=row[0].row4
                if outward:distance=math.hypot(max(float(lo.x-p.x),0,float(p.x-hi.x)),max(float(lo.y-p.y),0,float(p.y-hi.y)))/metre
                else:distance=min(float(p.x-lo.x),float(hi.x-p.x),float(p.y-lo.y),float(hi.y-p.y))/metre
                expected=base+amplitude*max(0,min(1,(distance-inset)/width))
                errors.append(abs(float(r.length(row[0].row1))-expected))
            check(bool(errors) and max(errors)<3e-4,f'Case {number}: scale falloff matches world distance',max_error=max(errors,default=0))
            leaf.setFallConfig(guide,old);update(root)
        node,root,leaf=case(17);panel=activate(node,'modelsUI');panel.sourceUI_plantList.selection=bits(1);panel.sourceUI_plantList.selectionEnd()
        before=positions(root);radius=float(leaf.sourceRadius(1))
        panel.sourceUI_followRadiusCheck.changed(False);update(root)
        check(all(abs(float(v)-radius)<1e-4 for v in root.procPublishedRadii[0]),'Follow Scale off keeps source radius constant')
        panel.sourceUI_followRadiusCheck.changed(True);update(root)
        check(all(abs(float(v)-radius*s)<1e-4 for v,s in zip(root.procPublishedRadii[0],scales(root))),'Follow Scale on includes band scaling')
        check(positions(root)==before,'Radius edits preserve positions when spacing is disabled')
        node,root,leaf=case(18);pts=[row[0].row4 for row in root.groupSnapshotRows[0]]
        minimum=min(float(r.distance(a,b)) for i,a in enumerate(pts) for b in pts[i+1:])
        check(minimum>=.18*metre-.001,'Two 80 mm radii plus 20 mm gap enforce 180 mm separation',minimum_mm=minimum/metre*1000)
        node,root,leaf=case(16);guide=leaf.areaNodes[0];old=clone_cfg(leaf,guide)
        for value in (0,1):
            cfg=clone_cfg(leaf,guide);cfg[7]=arr([value,value]);leaf.setFallConfig(guide,cfg);update(root)
            if value==0:check(len(root.groupSnapshotRows[0])==0,'Flat zero density curve removes all eligible candidates')
            else:check(len(root.groupSnapshotRows[0])>0,'Flat full density curve restores eligible candidates')
        leaf.setFallConfig(guide,old);update(root)
        panel=activate(node,'areasUI');panel.areaUI_areaList.selection=bits(1);panel.areaUI_areaList.selectionEnd()
        check(panel.areaUI_fallTargetName.visible and panel.areaUI_fallDensityEdit.visible,'Falloff target and curve controls are outside Advanced')
        epoch=int(root.procEpoch);panel.areaUI_fallDensitySpin.changed(.2*metre);pump()
        check(int(root.procEpoch)==epoch,'Manual curve-width editing waits for Update')
        update(root);check(int(root.procEpoch)>epoch,'Explicit Update applies pending width')
        root.updateMode=2;root.markInputDirty();pump(450);epoch=int(root.procEpoch)
        panel.areaUI_fallDensitySpin.changed(.35*metre);pump(2200)
        check(int(root.procEpoch)>epoch and not str(leaf.previewError),'Live width editing automatically publishes')
        root.updateMode=1;leaf.setFallConfig(guide,old);update(root)
        # Actual graph widget methods, preserving its independent scale samples.
        r.R791Leaf=leaf;r.R791Guide=guide
        mx('global R791Graph;R791Graph=CyrusOpenFalloffGraph R791Leaf R791Guide true;local c=R791Graph.graph.curves[1];c.numPoints=3;for i=1 to 3 do (local p=c.points[i];p.value=[(i-1)*.5,(if i==1 then 0 else if i==2 then 25 else 100)];p.bezier=false;p.corner=true;c.points[i]=p);R791Graph.storeCurve();destroyDialog R791Graph')
        cfg=leaf.getFallConfig(guide)
        check(len(cfg[7])==257 and abs(float(cfg[7][128])-.25)<.002,'Density graph stores the edited custom midpoint')
        check(list(map(float,cfg[4]))==list(map(float,old[4])),'Density graph leaves scale curve unchanged')
        density=list(map(float,cfg[7]))
        mx('R791Graph=CyrusOpenFalloffGraph R791Leaf R791Guide false;local c=R791Graph.graph.curves[1];c.numPoints=3;for i=1 to 3 do (local p=c.points[i];p.value=[(i-1)*.5,(if i==1 then 20 else if i==2 then 60 else 100)];p.bezier=false;p.corner=true;c.points[i]=p);R791Graph.storeCurve();destroyDialog R791Graph')
        cfg=leaf.getFallConfig(guide)
        check(len(cfg[4])==257 and abs(float(cfg[4][128])-.6)<.002,'Scale graph stores its independent custom midpoint')
        check(list(map(float,cfg[7]))==density,'Scale graph leaves density curve unchanged')
        leaf.setFallConfig(guide,old);update(root)
        # Every original example remains intact after these edits are restored.
        baseline=json.loads((OUT/'baseline.json').read_text())
        for item in cases:
            _,root,_=case(item['number']);update(root)
            check(fp(root)==baseline[item['node_name']],f"Case {item['number']:02d} restored exactly after falloff/radius checks")
        r.saveMaxFile(str(OUT/'Examples_0.79.1.max'),quiet=True)
    elif phase=='points':
        r.resetMaxFile(r.Name('noPrompt'))
        ground=r.plane(width=300,length=300);model=r.box(width=2,length=2,height=5,pos=r.Point3(500,0,0))
        node=r.AminScatterObject(name='Refine_Point_Workflow');root=node.baseObject;root.updateMode=1;root.autoRender=False;root.newLayer()
        leaf=root.selectedLayer();leaf.amount=6000;root.setLayerSurfaces(leaf,arr([ground]));root.setGroupDisplay(4)
        panel=activate(node,'modelsUI')
        check(panel.sourceUI_addPoint.visible and panel.sourceUI_radiusSourceSpin.visible,'Add Point, scale and radius are directly visible')
        for i in range(1,4):
            panel.sourceUI_addPoint.pressed();panel.sourceUI_sourceName.entered(f'Point {i}')
            panel.sourceUI_idColor.changed(r.color(40*i,210,60))
        ids=list(leaf.sourceRowIDs)
        check([str(leaf.sourceLabel(i)) for i in range(1,4)]==['Point 1','Point 2','Point 3'],'Three Point rows keep distinct editable names')
        check(int(leaf.sourceIDColor(2).r)==80,'Point identification color is independently editable')
        guide=r.rectangle(width=180,length=180)
        layout=activate(node,'layoutUI');layout.diversityUI_diversityRadio.changed(3);layout.diversityUI_pickPath.picked(guide)
        for i in range(1,4):
            if i<3:layout.diversityUI_addInside.pressed()
            else:layout.diversityUI_addOutside.pressed()
            layout.diversityUI_strokeWidth.changed(20.0);layout.diversityUI_strokeMode.changed(2)
            check(len(layout.diversityUI_strokeChoices.items)==3,f'Band {i} exposes all Points as direct choices')
            layout.diversityUI_strokeChoices.selection=bits(i);layout.diversityUI_strokeChoices.selectionEnd()
        pump(500);update(root);original=fp(root)
        check(all(any(int(row[1])==i for row in root.groupSnapshotRows[0]) for i in range(1,4)),'All three direct Point bands generate placements')
        copied=root.copyLogicalLayer(leaf);update(root)
        check(str(copied.strokeSourceIDs)==str(leaf.strokeSourceIDs) and len(copied.patternPaths)==1,'Layer copy retains direct band identities and guides')
        check(str(r.cyrusEditFingerprint(root.groupSnapshotRows[1],'areas'))==original,'Copied layer has exactly the same point layout')
        root.removeLogicalLayer(copied);root.selectLayer(1);update(root)
        panel=activate(node,'modelsUI');panel.sourceUI_plantList.selection=bits(1);panel.sourceUI_plantList.selectionEnd()
        panel.sourceUI_replacePoint.picked(model);update(root)
        check(fp(root)==original and str(leaf.sourceRowIDs[0])==str(ids[0]),'Replace Point preserves exact placements and assignment identity')
        check(str(leaf.sourceLabel(1))=='Point 1','Replace Point preserves its label')
        containers=activate(node,'containersUI');containers.sourceContainersUI_createContainer.pressed()
        container=leaf.containerNodes[0];container.pos=r.Point3(500,0,0);container.collectEnabled=True;update(root)
        check(fp(root)==original and all(leaf.containerActive),'Container mode keeps model and Point bands active')
        panel=activate(node,'modelsUI');panel.sourceUI_plantList.selection=bits(2);panel.sourceUI_removePlant.pressed();update(root)
        check(str(leaf.sourceRowIDs[1])==str(ids[2]) and str(leaf.sourceLabel(2))=='Point 3','Removing an earlier row preserves the surviving Point identity and name')
        line=leaf.lineInputs(leaf.validSources())
        check(len(line[2])==2,'Removed direct source leaves its band empty without assigning another Point')
        area=r.rectangle(width=240,length=240)
        areas=activate(node,'areasUI');areas.areaUI_pickArea.picked(area)
        check(areas.areaUI_areaList.selection==bits(1) and int(areas.areaUI_areaMode.state)==1,'New Include area is selected with its actual mode')
        areas.areaUI_areaMode.changed(2)
        check(int(leaf.areaModes[0])==2 and int(areas.areaUI_areaMode.state)==2,'Area mode edits the highlighted shape')
        other=r.rectangle(width=40,length=40);areas.areaUI_pickArea.picked(other);areas.areaUI_areaList.selection=bits(1,2);areas.areaUI_areaList.selectionEnd()
        check(int(areas.areaUI_areaMode.state)==0 and areas.areaUI_areaMode.enabled,'Mixed area selection has an explicit mixed state')
        areas.areaUI_areaList.selection=bits();areas.areaUI_areaList.selectionEnd()
        check(not areas.areaUI_areaMode.enabled,'No area selection disables mode editing')
        leaf.areaNodes=arr([]);leaf.areaModes=arr([]);update(root)
        r.saveMaxFile(str(OUT/'Point_Workflow_0.79.1.max'),quiet=True)
        (OUT/'points-before.json').write_text(json.dumps(dict(fingerprint=fp(root),ids=list(map(str,leaf.sourceRowIDs)),names=[str(leaf.sourceLabel(i)) for i in (1,2)])))
    elif phase=='reopen':
        r.loadMaxFile(str(OUT/'Point_Workflow_0.79.1.max'),quiet=True,useFileUnits=True);pump(600)
        node=r.getNodeByName('Refine_Point_Workflow');root=node.baseObject;leaf=root.layerObjects[0];update(root)
        saved=json.loads((OUT/'points-before.json').read_text())
        check(fp(root)==saved['fingerprint'],'Point/model bands preserve exact placements after reopening')
        check(list(map(str,leaf.sourceRowIDs))==saved['ids'] and [str(leaf.sourceLabel(i)) for i in (1,2)]==saved['names'],'Point identities and names survive reopening')
        layout=activate(node,'layoutUI')
        layout.diversityUI_pathsDrop.selection=1;layout.diversityUI_showPath()
        check(len(layout.diversityUI_strokesList.items)==3,'Saved guide and all three bands are accessible')
        r.loadMaxFile(str(OUT/'Examples_0.79.1.max'),quiet=True,useFileUnits=True);pump(600)
        saved=json.loads((OUT/'baseline.json').read_text())
        for item in cases:
            _,root,_=case(item['number']);update(root)
            check(fp(root)==saved[item['node_name']],f"Case {item['number']:02d} retains its complete result after 0.79.1 save/reopen")
    elif phase=='units':
        # Record the outstanding cross-unit limitation separately from passing
        # same-unit acceptance. Never save either variant over the input.
        witness={}
        for preserve in (True,False):
            if not preserve:r.units.SystemType=r.Name('centimeters');r.units.SystemScale=1.0
            r.loadMaxFile(str(OUT/'input-examples.max'),quiet=True,useFileUnits=preserve);pump(500)
            node,root,leaf=case(16);update(root)
            cfg=leaf.getFallConfig(leaf.areaNodes[0]);mm=float(r.units.decodeValue('1mm'))
            witness['file_units' if preserve else 'converted_cm']=dict(system_type=str(r.units.SystemType),count=len(root.groupSnapshotRows[0]),density_width_mm=float(cfg[6])/mm,scale_width_mm=float(cfg[3])/mm)
        (OUT/'unit-conversion-observation.json').write_text(json.dumps(witness,indent=2))
        metrics['unit_conversion_qualified']=False
        metrics['observation']=witness
    elif phase=='empty':
        r.resetMaxFile(r.Name('noPrompt'))
        node=r.AminScatterObject(name='Gap_Policy');root=node.baseObject;root.updateMode=1;root.autoRender=False;root.newLayer()
        leaf=root.selectedLayer();ground=r.plane(width=200,length=200);root.setLayerSurfaces(leaf,arr([ground]));leaf.amount=1000
        panel=activate(node,'modelsUI');panel.sourceUI_addPoint.pressed();panel.sourceUI_addEmpty.pressed();update(root)
        count=len(root.groupSnapshotRows[0]);before=fp(root)
        check(0<count<1000 and all(int(row[1])==1 for row in root.groupSnapshotRows[0]),'Empty contributes intentional gaps, distinct from Point markers',accepted=count)
        check(not leaf.isPointSource(2),'Add Empty keeps its own source type')
        leaf.procPopulation=2;root.refreshAll()
        check('Empty' in str(leaf.previewError) and fp(root)==before,'Accepted target rejects weighted Empty and preserves the complete prior result')
        leaf.sourceWeights[1]=0.0;update(root)
        check(len(root.groupSnapshotRows[0])==1000,'Zero-weight Empty allows Accepted target to generate 1000 Points')
    elif phase=='layout':
        r.loadMaxFile(str(OUT/'Point_Workflow_0.79.1.max'),quiet=True,useFileUnits=True);pump()
        node=r.getNodeByName('Refine_Point_Workflow');root=node.baseObject
        measures=[]
        for name in ['modelsUI','containersUI','areasUI','layoutUI']:
            panel=activate(node,name)
            if name=='modelsUI':panel.groupsToggle.checked=True;panel.layout()
            bounds=[]
            for control in panel.controls:
                try:
                    if not control.visible:continue
                    for hwnd in list(control.hwnd):
                        data=r.windows.getHWNDData(hwnd);rect=r.windows.getWindowPos(hwnd)
                        bounds.append(dict(name=str(control.name),type=str(data[3]),text=str(data[4]),x=int(rect.x),y=int(rect.y),w=int(rect.w),h=int(rect.h)))
                except Exception:continue
            # Independent visible controls cannot overlap. Max's spinner arrows
            # and edit fields are subcontrols of one logical spinner.
            collisions=[]
            for i,a in enumerate(bounds):
                for b in bounds[i+1:]:
                    if a['name']==b['name']:continue
                    if min(a['x']+a['w'],b['x']+b['w'])-max(a['x'],b['x'])>2 and min(a['y']+a['h'],b['y']+b['h'])-max(a['y'],b['y'])>2:
                        collisions.append([a['name'],b['name']])
            measures.append(dict(page=name,width=int(panel.width),height=int(panel.height),bounds=bounds,collisions=collisions))
            check(not collisions,name+': visible native control rectangles do not overlap',collisions=collisions)
        (OUT/'native-layout.json').write_text(json.dumps(measures,indent=2))
    else:raise ValueError(phase)
    write()
except Exception:
    (OUT/(phase+'-error.txt')).write_text(traceback.format_exc());raise
finally:mx('CyrusInteractionHeld=R791PreviousHeld')

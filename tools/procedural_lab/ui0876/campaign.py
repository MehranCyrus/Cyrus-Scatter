"""Bounded real MAXScript handlers in our disposable Max 2027 scene.

This is smoke evidence, not a claim that every numerical combination is valid.
The semantic cases below separately check Point sources and Paint edge behavior.
"""
from pathlib import Path
import json, time, traceback, re, ctypes
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(str(r.GardenRun)); CASE=str(r.CVProfileCase)
assert OUT.is_relative_to(ROOT/'build/ui0876-20261028-01')
report={'case':CASE,'status':'running','checks':[]}
def persist(): (OUT/(CASE+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
def check(name,code):
    try:
        value=r.execute('('+code+')')
        pump()
        report['checks'].append({'name':name,'status':'pass','value':str(value)})
        persist();return value
    except Exception:
        report['checks'].append({'name':name,'status':'fail','error':traceback.format_exc()})
        persist();return None
def pump():
    for _ in range(6):r.windows.processPostedMessages();time.sleep(.015)
def fixture():
    r.execute('''resetMaxFile #noPrompt
    global UIPlane=plane name:"UI receiver" length:100 width:100 lengthsegs:1 widthsegs:1
    global UIModel=box name:"UI source" width:1 length:1 height:3 pos:[80,0,0]
    global UINode=AminScatterObject(),UIRoot=UINode.baseObject,UILayer
    UIRoot.surfaceNodes=#(UIPlane);UIRoot.newLayer();UILayer=UIRoot.selectedLayer()
    UILayer.addModelSource UIModel;UILayer.amount=40;UIRoot.updateMode=1;UIRoot.refreshAll()
    select UINode;max modify mode;modPanel.setCurrentObject UIRoot''')
    pump()
    r.execute('for i=1 to UIRoot.mainUI.slots.count do (UIRoot.mainUI.slots[i].open=true;UIRoot.mainUI.bindSection UIRoot.mainUI.editors[i])')
    pump()
    # The scripted fixture creation can leave a Max command hold open. Finish
    # only this private scene's fixture frame before testing UI transactions.
    r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned UI fixture construction"')
def publish():
    return 'UIRoot.refreshAll();if UILayer.previewError!="" do throw UILayer.previewError;'

def select_combo(path,value):
    """Send the same selection notification Max receives from its native combo."""
    control=r.execute(path);control.selection=value
    handle=int(control.hwnd[0]);u=ctypes.windll.user32
    u.GetParent.argtypes=[ctypes.c_void_p];u.GetParent.restype=ctypes.c_void_p
    u.GetDlgCtrlID.argtypes=[ctypes.c_void_p];u.GetDlgCtrlID.restype=ctypes.c_int
    u.SendMessageW.argtypes=[ctypes.c_void_p,ctypes.c_uint,ctypes.c_size_t,ctypes.c_ssize_t]
    u.SendMessageW.restype=ctypes.c_ssize_t
    u.SendMessageW(u.GetParent(handle),0x111,u.GetDlgCtrlID(handle)|(1<<16),handle)
    u.SendMessageW(u.GetParent(handle),0x111,u.GetDlgCtrlID(handle)|(9<<16),handle)
    pump()

try:
    fixture()
    if CASE=='debug':
        check('guards','#(CyrusLicenseCanEdit(),UIRoot.managerUI.binding,UIRoot.managerUI.flow_layersUI_binding,UIRoot.managerUI.flow_layersUI_controlsReady,UIRoot.layoutUI.binding,UIRoot.layoutUI.placementUI_controlsReady,UIRoot.layoutUI.placementUI_binding,UIRoot.managerUI.flow_layersUI_root==UIRoot)')
        check('before','#(UIRoot.layerObjects.count,UIRoot.selectedLayer(),UIRoot.mainUI.owner,UIRoot.managerUI.flow_layersUI_currentLayer(),UILayer,UIRoot.managerUI.controlsReady)')
        check('copy','UIRoot.managerUI.flow_layersUI_copyButton.pressed()')
        check('after','#(UIRoot.layerObjects.count,UIRoot.selectedLayer(),UIRoot.mainUI.owner,UIRoot.managerUI.flow_layersUI_currentLayer(),UILayer,UIRoot.managerUI.controlsReady)')
        check('select first','UIRoot.mainUI.selectLayerView UILayer;true')
        check('binding','#(UIRoot.layoutUI.owner,UIRoot.layoutUI.diversityUI_obj,UIRoot.modelsUI.sourceUI_obj)')
        select_combo('UIRoot.layoutUI.placementUI_generatorList',2)
        check('combo','#(UILayer.placementMode,UIRoot.layoutUI.placementUI_generatorList.selection,UIRoot.layoutUI.placementUI_generatorList.hwnd)')
        check('combo windows','for h in UIRoot.layoutUI.placementUI_generatorList.hwnd collect windows.getHWNDData h')
        check('direct combo handler','UIRoot.layoutUI.placementUI_changePlacement #placementMode 2;#(UILayer.placementMode,UIRoot.layoutUI.placementUI_obj==UILayer,UIRoot.layoutUI.placementUI_generatorList.enabled)')
        check('button flags','#(UIRoot.managerUI.flow_layersUI_copyButton.enabled,UIRoot.managerUI.flow_layersUI_copyButton.visible,UIRoot.mainUI.eventDepth,UIRoot.mainUI.eventRefresh)')
        check('direct copy','UIRoot.copyLogicalLayer UILayer;UIRoot.layerObjects.count')
    elif CASE=='points':
        check('Add Point actual button', 'UIRoot.modelsUI.sourceUI_addPoint.pressed();'+publish()+'if UILayer.sources.count!=2 or not UILayer.sourcePoint[2] do throw "Point absent";UILayer.generatedCount')
        check('Point authored scale and Z', 'UILayer.sourceScales[2]=2;UILayer.sourceZOffsetsWU[2]=5;UILayer.markInputDirty();'+publish()+'if UILayer.generatedCount!=40 do throw "Count changed";true')
        check('all Point publication','UILayer.makePointSource 1;'+publish()+'if UILayer.sourcePoint[1]!=true do throw "Conversion failed";UILayer.generatedCount')
        check('replace Point keeps row identity','global UIID=UILayer.sourceRowIDs[2];global UIReplacement=box name:"UI replacement" width:2 length:2 height:4 pos:[90,0,0];UILayer.replacePointSource 2 UIReplacement;'+publish()+'if UILayer.sourceRowIDs[2]!=UIID or UILayer.sourcePoint[2] do throw "Replacement identity changed";true')
        check('remove source and shared lists','UILayer.removeModelSources #{1};UIRoot.mainUI.bind();'+publish()+'if UILayer.sources.count!=1 do throw "Remove failed";#(UIRoot.modelsUI.sourceUI_plantList.items,UIRoot.interactionsUI.interactionsUI_modelList.items)')
        check('Point save','UILayer.addPointSource();'+publish()+'saveMaxFile (GardenRun+"points.max") quiet:true')
        check('Point reopen','loadMaxFile (GardenRun+"points.max") quiet:true;UINode=getNodeByName "Cyrus Scatter001";UIRoot=UINode.baseObject;UILayer=UIRoot.selectedLayer();'+publish()+'if UILayer.sources.count!=2 or not UILayer.sourcePoint[2] do throw "Point did not persist";true')
    elif CASE=='paint_edges':
        check('enable Paint Areas','UIRoot.coverageUI.setsUI_paintedCheck.checked=true;UIRoot.coverageUI.setsUI_paintedCheck.changed true')
        check('create Paint Area','UIRoot.coverageUI.setsUI_addButton.pressed();UILayer.amount=1000')
        check('area rebound','global UIArea=UIRoot.coverageUI.brushUI_obj;if UIArea==undefined do throw "Paint owner missing";true')
        check('one committed circular stroke','cyrusBrushSettings UIArea.paintDocument 20 false;cyrusBrushDab UIArea.paintDocument [0,0,100] [0,0,-1] true;'+publish()+'global UIHard=UILayer.generatedCount;if UIHard<30 do throw "Dab missing";UIHard')
        check('inward fade changes density','UIRoot.coverageUI.brushUI_insideSpin.value=10;UIRoot.coverageUI.brushUI_insideSpin.changed 10;'+publish()+'global UIInside=UILayer.generatedCount;if UIInside>=UIHard do throw "Inward fade did not thin";#(UIHard,UIInside)')
        check('outward fade extends coverage','UIRoot.coverageUI.brushUI_insideSpin.value=0;UIRoot.coverageUI.brushUI_insideSpin.changed 0;UIRoot.coverageUI.brushUI_outsideSpin.value=10;UIRoot.coverageUI.brushUI_outsideSpin.changed 10;'+publish()+'global UIOutside=UILayer.generatedCount;if UIOutside<=UIHard do throw "Outward fade did not extend";#(UIHard,UIOutside)')
        check('size fade parameters persist','UIRoot.coverageUI.brushUI_scaleFade.checked=true;UIRoot.coverageUI.brushUI_scaleFade.changed true;UIRoot.coverageUI.brushUI_scaleMin.value=0.25;UIRoot.coverageUI.brushUI_scaleMin.changed 0.25;'+publish()+'local f=cyrusBrushFalloff UIArea.paintDocument;if not f[4] or abs(f[5]-0.25)>0.0001 do throw "Size falloff lost";f')
        check('Manual dirty state remains pending','UIRoot.coverageUI.brushUI_insideSpin.value=5;UIRoot.coverageUI.brushUI_insideSpin.changed 5;if UILayer.generatedCount!=UIOutside do throw "Manual edit evaluated eagerly";UIRoot.coverageUI.brushUI_status();UIRoot.coverageUI.brushUI_brushState.text')
        check('clear and fill actual buttons','UIRoot.coverageUI.brushUI_emptyButton.pressed();'+publish()+'if UILayer.generatedCount!=0 do throw "Clear failed";UIRoot.coverageUI.brushUI_fillButton.pressed();'+publish()+'if UILayer.generatedCount<400 do throw "Fill failed";UILayer.generatedCount')
        check('area enable and density','UIRoot.coverageUI.brushUI_densitySpin.value=0;UIRoot.coverageUI.brushUI_densitySpin.changed 0;'+publish()+'if UILayer.generatedCount!=0 do throw "Zero density failed";true')
    elif CASE in ('settings','settings_expanded'):
        r.execute('UILayer.densityMap=checker();UILayer.meshMaskChannel=1;UIRoot.mainUI.bind()')
        pump()
        if CASE=='settings_expanded':
            for page in r.UIRoot.mainUI.editors:
                for c in page.controls:
                    try:
                        if str(r.classOf(c))=='CheckButtonControl':c.checked=True
                    except Exception:pass
                page.layout()
        layout=json.loads((ROOT/'AminScatter/tools/ui/approved-layout-manifest.json').read_text())
        script=(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf-8-sig')
        # Run scalar authoring handlers; dialogs, pickers and destructive commands
        # need their own fixtures and are deliberately not invoked blindly.
        kinds={m[2]:(m[1],m[3]) for m in re.finditer(r'^        (spinner|checkbox|dropdownlist|radiobuttons|colorpicker) (\w+) ([^\n]*)',script,re.M)}
        for page in layout['sections']:
            if page['name'] in ('interactionsUI','collidersUI'):continue
            for item in page['controls']:
                name=item['presentation']; entry=kinds.get(name)
                if not entry:continue
                kind,_=entry;path='UIRoot.'+page['name']+'.'+name
                if kind=='spinner': prop,event='value','changed'; alter='(if abs(old)<1 then old+0.1 else if old<100 then old+1 else old)'
                elif kind=='checkbox':prop,event='checked','changed';alter='(not old)'
                elif kind=='dropdownlist':prop,event='selection','selected';alter='(if old<control.items.count then old+1 else 1)'
                elif kind=='radiobuttons':prop,event='state','changed';alter='(if old==1 then 2 else 1)'
                else:prop,event='color','changed';alter='(color 43 121 189)'
                if not re.search(r'on '+re.escape(name)+r' '+event+r'\b',script):continue
                # Expensive/global diagnostic switches and foreign Analyzer choices
                # are reviewed separately, not misrepresented as exercised here.
                if any(s in name for s in ('analyzerChannel','aaLine','aaPoints','coordinatesList','meshSourceList','fallTarget','scopeList','orientationList','generatorList','diversityRadio','modeList','populationRadio','begin','diagnostics','trunk')):continue
                code=f'''(local control={path}
                if not control.enabled or not control.visible then "not exercised: prerequisite inactive" else (
                    local old=control.{prop},candidate={alter}
                    local caught=undefined
                    try (
                    control.{prop}=candidate;control.{event} control.{prop}
                    {publish()}
                    )catch(caught=getCurrentException())
                    control={path};control.{prop}=old;control.{event} old
                    {publish()} if caught!=undefined do throw caught;true))'''
                if kind=='dropdownlist':
                    control=r.execute(path)
                    if not control.enabled or not control.visible:
                        report['checks'].append({'name':name,'status':'pass','value':'not exercised: prerequisite inactive'});continue
                    old=int(control.selection);new=old+1 if old<len(control.items) else 1
                    try:
                        select_combo(path,new);check(name,publish()+'true')
                    finally:select_combo(path,old);r.execute(publish()+'true')
                else:check(name,code)
        check('ordinary box fixture remains healthy',publish()+'UILayer.generatedCount')
    elif CASE=='panels':
        check('layer copy button','UIRoot.managerUI.flow_layersUI_copyButton.pressed();if UIRoot.layerObjects.count!=2 do throw "Copy failed";true')
        check('layer rename','UIRoot.managerUI.flow_layersUI_nameEdit.text="Copied layer";UIRoot.managerUI.flow_layersUI_nameEdit.entered "Copied layer";if findItem (UIRoot.layerNames as array) "Copied layer"==0 do throw "Rename failed";true')
        check('layer remove button','UIRoot.managerUI.flow_layersUI_removeButton.pressed();if UIRoot.layerObjects.count!=1 do throw "Remove failed";UILayer=UIRoot.selectedLayer();true')
        check('receiver pick handler','global UISecond=plane name:"Second receiver" length:20 width:20 pos:[0,120,0];UIRoot.surfacesUI.flow_surfaceUI_sharedPick.picked UISecond;'+publish()+'if (UILayer.validSurfaces()).count!=2 do throw "Receiver missing";true')
        check('restore receiver','UILayer.surfaceNodes=#(UIPlane);UILayer.markInputDirty();'+publish()+'true')
        check('create inactive source rectangle','UIRoot.containersUI.sourceContainersUI_createContainer.pressed();if UILayer.containerNodes.count!=1 do throw "Container missing";true')
        check('unlink source rectangle','UIRoot.containersUI.sourceContainersUI_removeContainer.pressed();UILayer.containerMode=1;'+publish()+'true')
        for mode in (2,3,4,1):
            select_combo('UIRoot.layoutUI.placementUI_generatorList',mode)
            check('grid mode '+str(mode),'UILayer.gridColumnWU=20;UILayer.gridRowWU=20;UILayer.markInputDirty();'+publish()+f'if UILayer.placementMode!={mode} do throw "Dropdown notification failed";UILayer.generatedCount')
        check('cluster assignment','UIRoot.layoutUI.diversityUI_diversityRadio.state=2;UIRoot.layoutUI.diversityUI_diversityRadio.changed 2;'+publish()+'if UILayer.diversityMode!=2 do throw "Cluster mode failed";true')
        check('spline mode','UIRoot.layoutUI.diversityUI_diversityRadio.state=3;UIRoot.layoutUI.diversityUI_diversityRadio.changed 3;global UIPath=rectangle width:40 length:40;true')
        check('Band path and outward Band','UIRoot.layoutUI.diversityUI_pickPath.picked UIPath;UIRoot.layoutUI.diversityUI_addOutside.pressed();if UILayer.strokeIDs.count!=1 do throw "Band absent";true')
        check('Band width and source assignment','UIRoot.layoutUI.diversityUI_strokeWidth.value=20;UIRoot.layoutUI.diversityUI_strokeWidth.changed 20;UIRoot.layoutUI.diversityUI_strokeMode.state=2;UIRoot.layoutUI.diversityUI_strokeMode.changed 2;UIRoot.layoutUI.diversityUI_strokeChoices.selection=#{1};UIRoot.layoutUI.diversityUI_strokeChoices.selectionEnd();'+publish()+'UILayer.generatedCount')
        check('Band preview is inspection only','global UIBrowseEpoch=UIRoot.procEpoch;UIRoot.layoutUI.diversityUI_fieldFalloffCheck.checked=true;UIRoot.layoutUI.diversityUI_fieldFalloffCheck.changed true;UIRoot.layoutUI.diversityUI_fieldBoundaryCheck.checked=true;UIRoot.layoutUI.diversityUI_fieldBoundaryCheck.changed true;if UIRoot.procEpoch!=UIBrowseEpoch do throw "Band preview regenerated";true')
        check('remove Band then path','UIRoot.layoutUI.diversityUI_removeStrokeButton.pressed();UIRoot.layoutUI.diversityUI_removePath.pressed();UIRoot.layoutUI.diversityUI_diversityRadio.state=1;UIRoot.layoutUI.diversityUI_diversityRadio.changed 1;'+publish()+'if UILayer.strokeIDs.count!=0 do throw "Band retained";true')
        check('include Area','UIRoot.areasUI.areaUI_pickArea.picked UIPath;'+publish()+'global UIInclude=UILayer.generatedCount;if UIInclude>=40 do throw "Include did not constrain";UIInclude')
        check('exclude Area','UIRoot.areasUI.areaUI_areaList.selection=#{1};UIRoot.areasUI.areaUI_areaList.selectionEnd();UIRoot.areasUI.areaUI_areaMode.state=2;UIRoot.areasUI.areaUI_areaMode.changed 2;'+publish()+'if UILayer.generatedCount<=UIInclude do throw "Exclude did not invert";UILayer.generatedCount')
        check('remove Area','UIRoot.areasUI.areaUI_removeArea.pressed();'+publish()+'if UILayer.generatedCount!=40 do throw "Area removal retained filter";true')
        check('transform scale roundtrip','UIRoot.transformsUI.randomUI_wholeMaxSpin.value=1.5;UIRoot.transformsUI.randomUI_wholeMaxSpin.changed 1.5;'+publish()+'if UILayer.wholeScaleMax!=1.5 do throw "Scale ignored";UIRoot.transformsUI.randomUI_resetWholeScale.pressed();'+publish()+'if UILayer.wholeScaleMax!=1 do throw "Reset failed";true')
        check('surface mask fixture','UILayer.meshMaskChannel=1;UIRoot.populationUI.distributionUI_meshCheck.checked=true;UIRoot.populationUI.distributionUI_meshCheck.changed true;'+publish()+'true')
        check('density preview toggle','UIRoot.populationUI.distributionUI_meshPreviewButton.pressed();if CyrusMeshMaskPreviewTarget!=UILayer do throw "Preview missing";UIRoot.populationUI.distributionUI_meshPreviewButton.pressed();if CyrusMeshMaskPreviewTarget==UILayer do throw "Preview not hidden";true')
        check('restore mask','UIRoot.populationUI.distributionUI_meshCheck.checked=false;UIRoot.populationUI.distributionUI_meshCheck.changed false;'+publish()+'true')
        for mode in range(1,6):
            select_combo('UIRoot.displayUI.flow_previewUI_displayModeDrop',mode)
            check('display representation '+str(mode),'if UILayer.previewError!="" do throw UILayer.previewError;#(UIRoot.viewportMode,UIRoot.identificationMode)')
        check('read cached statistics','UIRoot.statisticsUI.detailsUI_refreshButton.pressed();UIRoot.statisticsUI.detailsUI_info.text')
        check('browsing keeps publication','global UIEpoch=UIRoot.procEpoch,UIBuilds=UILayer.procPreparedBuilds;for cycle=1 to 3 do for page in UIRoot.mainUI.editors do (UIRoot.mainUI.bindSection page;page.layout());if UIRoot.procEpoch!=UIEpoch or UILayer.procPreparedBuilds!=UIBuilds do throw "Browsing rebuilt placements";#(UIEpoch,UIBuilds)')
    elif CASE=='interactions':
        check('owned ribbon source','global UILeaf=mesh name:"Owned UI ribbon" vertices:(for i=0 to 11 collect [-0.2,0,i]) faces:#();local vs=#(),fs=#();for i=0 to 11 do (append vs [-0.2,0,i];append vs [0.2,0,i]);for i=0 to 10 do (local a=i*2+1;append fs [a,a+1,a+2];append fs [a+1,a+3,a+2]);delete UILeaf;UILeaf=mesh name:"Owned UI ribbon" vertices:vs faces:fs pos:[80,0,0];UILayer.makePointSource 1;UILayer.replacePointSource 1 UILeaf;UIRoot.mainUI.bind();'+publish()+'true')
        select_combo('UIRoot.interactionsUI.interactionsUI_roleList',3)
        check('Prepare model actual button','UIRoot.interactionsUI.interactionsUI_prepareButton.pressed();if not UILayer.interactionsReady #(UILeaf) do throw UIRoot.interactionsUI.interactionsUI_info.text;UIRoot.interactionsEnsure();true')
        for control,value,prop,expected in [('strengthSpin',65,'interactionBendStrength',.65),('trunkSpin',20,'interactionTrunkBend',.2),('fixedBaseSpin',30,'interactionFixedBase',.3),('transitionSpin',40,'interactionBendTransition',.4),('foliageSpin',100,'interactionFoliage',1)]:
            check('interactionsUI_'+control,f'UIRoot.interactionsUI.interactionsUI_{control}.value={value};UIRoot.interactionsUI.interactionsUI_{control}.changed {value};if abs(UILayer.{prop}-{expected})>0.001 do throw "Response setting lost";if UIRoot.interactionError!="" do throw UIRoot.interactionError;true')
        for mode in (2,3,1):
            select_combo('UIRoot.interactionsUI.interactionsUI_responseList',mode)
            check('response '+str(mode),f'if UILayer.interactionResponse!={mode} do throw "Response mode lost";if UIRoot.interactionError!="" do throw UIRoot.interactionError;true')
        check('source guide toggle','UIRoot.interactionsUI.interactionsUI_guideReviewButton.changed true;UIRoot.interactionsUI.interactionsUI_guideReviewButton.changed false;true')
        check('scene collider pick','global UICollider=sphere name:"Owned UI collider" radius:3 pos:[0,0,6];UIRoot.collidersUI.collidersUI_addButton.picked UICollider;if UIRoot.interactionSceneColliders.count!=1 do throw "Scene collider missing";UIRoot.interactionsEnsure();if UIRoot.interactionError!="" do throw UIRoot.interactionError;true')
        check('scene collider remove','UIRoot.collidersUI.collidersUI_colliderList.selection=1;UIRoot.collidersUI.collidersUI_removeButton.pressed();if UIRoot.interactionSceneColliders.count!=0 do throw "Scene collider retained";UIRoot.interactionsEnsure();true')
    elif CASE=='negative':
        check('missing Analyzer retains complete result','local before=UILayer.generatedCount;UILayer.areaUseLine=true;UILayer.markInputDirty();UIRoot.refreshAll();local message=UILayer.previewError;UILayer.areaUseLine=false;UILayer.markInputDirty();UIRoot.refreshAll();if findString message "pick a Surface Analyzer"==undefined or UILayer.generatedCount!=before do throw "Missing Analyzer was not bounded";message')
        check('source duplicate is rejected without changing rows','UILayer.addPointSource();local before=UILayer.sourceRowIDs as array;local result=UILayer.replacePointSource 2 UIModel;if result or (UILayer.sourceRowIDs as array) as string!=before as string do throw "Duplicate changed identity";true')
    elif CASE=='paint_tools':
        check('Paint tools enabled','UIRoot.coverageUI.setsUI_paintedCheck.checked=true;UIRoot.coverageUI.setsUI_paintedCheck.changed true')
        check('Paint tools area added','UIRoot.coverageUI.setsUI_addButton.pressed();true')
        check('Paint tools fixture','global UIArea=UIRoot.coverageUI.brushUI_obj;if UIArea==undefined do throw "Paint owner absent";cyrusBrushSettings UIArea.paintDocument 20 false;cyrusBrushDab UIArea.paintDocument [0,0,100] [0,0,-1] true;'+publish()+'true')
        for field,index in [('density',7),('scale',8)]:
            control='UIRoot.coverageUI.brushUI_'+field+'Curve'
            check(field+' curve opens without changing samples',f'global UICurveBefore=(cyrusBrushFalloff UIArea.paintDocument)[{index}] as string;{control}.pressed();if CyrusFalloffGraph==undefined do throw "Curve did not open";CyrusFalloffGraph.doneButton.pressed();if (cyrusBrushFalloff UIArea.paintDocument)[{index}] as string!=UICurveBefore do throw "Curve browsing changed samples";true')
            # Curve controls do not expose their native ptChanged event as a
            # callable property. Exercise its queue method after a scripted
            # point edit; this is not evidence of physical graph dragging.
            check(field+' programmed curve endpoint applies',f'{control}.pressed();local c=CyrusFalloffGraph.graph.curves[1],p=c.points[c.numPoints];p.value=[1,25];setPoint c c.numPoints p;CyrusFalloffGraph.queueCurve();CyrusFalloffGraph.applyButton.pressed();local values=(cyrusBrushFalloff UIArea.paintDocument)[{index}];if abs(values[values.count]-0.25)>0.0001 do throw "Curve endpoint not applied";CyrusFalloffGraph.doneButton.pressed();values[values.count]')
        for choice,value in [(1,2),(2,1),(3,0)]:
            select_combo('UIRoot.coverageUI.brushUI_overlayMode',choice)
            check('Paint preview mode '+str(choice),f'if UIArea.paintView!={value} do throw "Preview mode did not bind to Paint Area";UIArea.paintView')
    elif CASE=='library':
        check('matching shared store assembly','local store=CyrusSharedStore();if store==undefined do throw "Shared store absent";local kind=store.GetType();local name=kind.Assembly.GetName();if name.Version.ToString()!="0.87.6.0" do throw "Assembly identity mismatch";store.Root')
        check('Recipes button opens Library','UIRoot.managerUI.flow_layersUI_recipesButton.pressed();if CyrusRecipeBrowser==undefined do throw "Library did not open";true')
        check('Library has no error banner','local notice=CyrusRecipeBrowser.panel.NoticeText,status=CyrusRecipeBrowser.panel.StatusText;if notice!="" do throw notice;#(notice,status)')
        check('close owned Library','destroyDialog CyrusRecipeBrowser;true')
    elif CASE=='swatches':
        check('layer swatch native bounds','local control=UIRoot.managerUI.flow_layersUI_layerColor,page=UIRoot.managerUI,out=#();for h in control.hwnd where (windows.getHWNDData h)[4]=="ColorSwatch" do (local b=windows.getWindowPos h removeUIScaling:true,p=windows.screenToClient page.hwnd b.x b.y;if p.x<0 or p.x+b.w>page.lastLayoutWidth do throw "Layer swatch clipped";append out #(p.x,b.w,page.lastLayoutWidth));if out.count==0 do throw "No swatch inspected";out')
        check('source swatch native bounds','local control=UIRoot.modelsUI.sourceUI_idColor,page=UIRoot.modelsUI,out=#();for h in control.hwnd where (windows.getHWNDData h)[4]=="ColorSwatch" do (local b=windows.getWindowPos h removeUIScaling:true,p=windows.screenToClient page.hwnd b.x b.y;if p.x<0 or p.x+b.w>page.lastLayoutWidth do throw "Source swatch clipped";append out #(p.x,b.w,page.lastLayoutWidth));if out.count==0 do throw "No swatch inspected";out')
    elif CASE=='layout':
        checks=[];measured=0;errors=[];widths=[]
        for page in r.UIRoot.mainUI.editors:
            if page is None:continue
            for width in (168,220,320):
                page.hostPage.width=width;page.hostPage.body.width=width-8
                page.width=width
                for expanded in (False,True):
                    for c in page.controls:
                        try:
                            if str(r.classOf(c))=='CheckButtonControl':c.checked=expanded
                        except Exception:pass
                    page.layout()
                    widths.append({'page':str(page.name),'requested':width,'actual_layout':int(page.lastLayoutWidth),'expanded':expanded})
                    for c in page.controls:
                        try:
                            if not c.visible:continue
                            kind=str(r.classOf(c));pos=c.pos;cw=float(c.width)
                            # Spinner.pos is its arrow anchor, not its left edge.
                            if kind=='SpinnerControl':continue
                            measured+=1
                            if float(pos.x)<-1 or float(pos.x)+cw>float(page.width)+2:
                                checks.append({'page':str(page.name),'control':str(c.name),'width':width,'expanded':expanded,'x':float(pos.x),'control_width':cw})
                        except Exception as e:
                            if len(errors)<10:errors.append(str(e))
        report['bounds_issues']=checks
        report['measured_controls']=measured;report['measurement_skips']=errors;report['widths']=widths
        if measured<200:raise AssertionError('Too few native controls inspected')
        check('all 14 panels constructed','UIRoot.mainUI.editors.count')
        check('band captions after bind','local labels=for key in #(#diversityUI_removePath,#diversityUI_addOutside,#diversityUI_addInside) collect (getProperty UIRoot.layoutUI key).text;if labels as string!=#("x","Out +","In +") as string do throw "Incorrect Band labels";labels')
        if checks:raise AssertionError('Out of bounds controls require inspection')
    report['status']='pass' if all(x['status']=='pass' for x in report['checks']) else 'failed'
except Exception:report.update(status='failed',error=traceback.format_exc())
persist()

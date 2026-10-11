"""Continue the append-only area examples; requires area_examples.py to finish."""
from pathlib import Path
import json, traceback
HERE=Path(__file__).resolve().parent
exec((HERE/'area_examples.py').read_text().split("rt.execute('global QA_PreviousHeld")[0],globals())
previous=json.loads((OUT/'area-examples-results.json').read_text())
checks=previous['checks'];cases=previous['cases']
rt.execute('global QA_PreviousHeld=CyrusInteractionHeld\nfn CyrusInteractionHeld = false')
def mx(s): return rt.execute('('+s+')')
def get_case(n):
    c=cases[n-1];node=rt.getNodeByName(c['node_name']);r=node.baseObject
    return dict(c,node=node,root=r,leaf=r.layerObjects[0],obj=arr([node,r.layerObjects[0]]))
def probe_rows(c): return rows(c)
def segment_distance(p,a,b,caps=2,first=True,last=True):
    dx,dy=b[0]-a[0],b[1]-a[1];den=dx*dx+dy*dy
    if den==0:return float('inf')
    t=((p[0]-a[0])*dx+(p[1]-a[1])*dy)/den
    if caps==1 and ((first and t<0) or (last and t>1)):return float('inf')
    t=max(0,min(1,t));return math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy)
try:
    c=get_case(17);before=rows(c)
    c['leaf'].setSourceRadius(rt.execute('#{1}'),False,kind=2);update(c)
    check(all(abs(float(v)/M-.04)<1e-5 for v in c['root'].procPublishedRadii[0]),'Follow Scale off keeps a fixed 40 mm radius despite band scaling')
    check({r['id'] for r in rows(c)}=={r['id'] for r in before},'Radius display changes preserve accepted point identities without spacing')
    c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=2);update(c)
    # Main area list controls, preserving the final Include-only example.
    c=get_case(7);r=c['root'];leaf=c['leaf'];guide=leaf.areaNodes[0];before=rows(c)
    rt.QA_UI=c['obj'];rt.QA_AreaGuide=guide
    mx('global QA_AP;local r=QA_Activate QA_UI;QA_AP=r.areasUI;QA_AP.open=true;r.mainUI.bindSection QA_AP;QA_AP.areaUI_areaList.selection=#{1};QA_AP.areaUI_areaList.selectionEnd()')
    check(int(rt.QA_AP.areaUI_areaMode.state)==1,'Area selection synchronizes Include radio')
    rt.QA_AP.areaUI_pickArea.picked(guide)
    check(len(leaf.areaNodes)==1,'Adding the same Area twice does not duplicate its row')
    rt.QA_AP.areaUI_areaMode.state=2;rt.QA_AP.areaUI_areaMode.changed(2);excluded=update(c)
    check(len(before)+len(excluded)==2400 and not ({x['id'] for x in before}&{x['id'] for x in excluded}),'Include to Exclude is the exact complementary candidate set')
    # Undo is tested across separate transport turns: pymxs runs inside a Max
    # hold, so inline max undo/redo cannot qualify a completed UI gesture.
    rt.QA_AddArea(c['obj'],guide,1);update(c)
    check({x['id'] for x in rows(c)}=={x['id'] for x in before},'Restoring Include returns the exact original points')
    mx('local r=QA_Activate QA_UI;r.mainUI.mountTimer.tick();QA_AP=r.areasUI;r.mainUI.bindSection QA_AP;QA_AP.areaUI_areaList.selection=#{1};QA_AP.areaUI_areaList.selectionEnd();QA_AP.areaUI_removeArea.pressed()')
    update(c);check(rt.isValidNode(guide) and len(leaf.areaNodes)==0 and c['count']==2400,'Remove Area unlinks it and keeps the scene spline')
    rt.QA_AddArea(c['obj'],guide,1);update(c)
    check(len(leaf.areaNodes)==1 and c['count']==len(before),'Relinking the retained Area restores mask and count')
    # The density graph stores the sampled shape; restore the demonstrated curve.
    c=get_case(16);leaf=c['leaf'];guide=leaf.areaNodes[0];cfg=leaf.getFallConfig(guide)
    rt.QA_FallLeaf=leaf;rt.QA_FallGuide=guide
    mx('global QA_Graph;QA_Graph=CyrusOpenFalloffGraph QA_FallLeaf QA_FallGuide true;local curve=QA_Graph.graph.curves[1];curve.numPoints=3;for i=1 to 3 do (local p=curve.points[i];p.value=[(i-1)*.5,(if i==1 then 0 else if i==2 then 25 else 100)];p.bezier=false;p.corner=true;p.lock_x=(i==1 or i==3);curve.points[i]=p);QA_Graph.storeCurve();destroyDialog QA_Graph')
    after=leaf.getFallConfig(guide)
    check(len(after[7])==257 and abs(float(after[7][128])-.25)<.001,'Area density graph commits sampled custom curve')
    check(str(after[4])==str(cfg[4]),'Density graph leaves independent scale curve intact')
    leaf.setFallConfig(guide,cfg);update(c)
    # Scale graph on the scaled-radius case, also restored after numeric verification.
    c=get_case(15);leaf=c['leaf'];guide=leaf.areaNodes[0];cfg=leaf.getFallConfig(guide)
    rt.QA_FallLeaf=leaf;rt.QA_FallGuide=guide
    mx('QA_Graph=CyrusOpenFalloffGraph QA_FallLeaf QA_FallGuide false;local curve=QA_Graph.graph.curves[1];local p=curve.points[1];p.value=[0,40];curve.points[1]=p;QA_Graph.storeCurve();destroyDialog QA_Graph')
    after=leaf.getFallConfig(guide);check(abs(float(after[4][0])-.4)<.001,'Area scale graph commits its endpoint')
    leaf.setFallConfig(guide,cfg);update(c)
    # Manual/Live on the actual Area width controls, then restore the final case.
    rt.QA_UI=c['obj'];rt.QA_AreaGuide=guide
    mx('local r=QA_Activate QA_UI;QA_AP=r.areasUI;QA_AP.open=true;r.mainUI.bindSection QA_AP;QA_AP.advancedToggle.checked=true;QA_AP.layout();QA_AP.areaUI_areaList.selection=#{1};QA_AP.areaUI_areaList.selectionEnd()')
    check(bool(rt.QA_AP.areaUI_fallDeleteCheck.checked) and abs(float(rt.QA_AP.areaUI_fallDeleteSpin.value)/M-.1)<1e-5,'Area falloff panel binds the selected line settings')
    before=rows(c);epoch=int(c['root'].procEpoch)
    rt.QA_AP.areaUI_fallDeleteSpin.changed(.2*M);rt.QA_Pump(350)
    check(int(c['root'].procEpoch)==epoch and len(rows(c))==len(before),'Manual falloff control waits for Update')
    rt.QA_AP.areaUI_refreshAreas.pressed()
    check(len(rows(c))<len(before),'Refresh areas / preview button applies a wider delete band')
    c['root'].updateMode=2;rt.QA_AP.areaUI_fallDeleteSpin.changed(.1*M);rt.QA_Pump(1800)
    check({x['id'] for x in rows(c)}=={x['id'] for x in before},'Live falloff change restores original accepted points')
    c['root'].updateMode=1;leaf.setFallConfig(guide,cfg);update(c)
    # Real Surface Analyzer objects and published centreline/point masks.
    for title,mode in [('Analyzer line - flat ends','flat'),('Analyzer line - round ends','round'),('Analyzer points - radius 250 mm','points'),('Analyzer union plus street offset','union')]:
        c=new(title);center=c['center'];a_surface=rt.plane(name=f"CSQA_{c['number']}_AnalyzerInput",width=2*M,length=.6*M,widthsegs=1,lengthsegs=1,pos=p3(*center))
        a=rt.CyrusSurfaceAnalyzer(name=f"CSQA_{c['number']}_Analyzer");a.surface=a_surface;a.analysisMode=2;a.pointRadius=.25*M;a.pointCount=5;a.resolution=128;a.fitRadius=0
        if mode=='union':
            street=rt.splineShape(name='CSQA_Street_Guide');rt.addNewSpline(street)
            # Street must lie outside the receiver boundary, not coincide with it.
            for x in (-1,1):rt.addKnot(street,1,rt.Name('corner'),rt.Name('line'),p3(center[0]+x,center[1]-.33))
            rt.updateShape(street);a.streetLine=street;a.streetDistance=.05*M;c['bucket'].addNode(street)
        a.runAnalysis();a_surface.isHidden=True;a.pos=p3(center[0]-1.3,center[1]-1.3)
        c['bucket'].addNode(a_surface);c['bucket'].addNode(a)
        rt.QA_UI=c['obj'];rt.QA_Analyzer=a
        mx('local r=QA_Activate QA_UI;QA_AP=r.areasUI;QA_AP.open=true;r.mainUI.bindSection QA_AP;QA_AP.advancedToggle.checked=true;QA_AP.layout();QA_AP.areaUI_aaPick.picked QA_Analyzer')
        rt.QA_AP.areaUI_aaLine.changed(mode!='points');rt.QA_AP.areaUI_aaWidth.changed(.6*M)
        caps=1 if mode=='flat' else 2
        # Dropdown .selected is its item text; use the backing property for caps.
        c['leaf'].areaLineCaps=caps
        rt.QA_AP.areaUI_aaPoints.changed(mode in ('points','union'));rt.QA_AP.areaUI_aaRadius.changed(.25*M)
        if mode=='union':rt.QA_AP.areaUI_aaStreetOffset.changed(.2*M)
        actual=update(c);paths=[[point(v) for v in path] for path in c['leaf'].centerStreetPaths(a)]
        anchors=[point(v) for v in a.samplePoints]
        check(bool(paths) and bool(anchors),title+': Analyzer published paths and points',paths=len(paths),points=len(anchors))
        want=set()
        for row in c['base']:
            p=row['xy'];ok=False
            if mode!='points':
                for path in paths:
                    for j,(x,y) in enumerate(zip(path,path[1:])):
                        if segment_distance(p,x,y,caps,j==0,j==len(path)-2)<=.3+1e-6:ok=True
            if mode in ('points','union') and any(math.dist(p,q)<=.25+1e-6 for q in anchors):ok=True
            if ok:want.add(row['id'])
        check({r['id'] for r in actual}==want,title+': exact line width, caps and disc-union membership',accepted=len(actual),expected=len(want))
        if mode=='union':
            original=[[point(v) for v in path] for path in a.packedLines(a.pathVertices,a.pathCounts)]
            check(any(math.dist(p,q)>.19 for x,y in zip(paths,original) for p,q in zip(x,y)),'Street offset moves the Area centreline by the configured amount')
        for k,p in enumerate(anchors):
            circle=rt.circle(name=f"CSQA_{c['number']}_Radius250_{k}",radius=.25*M,pos=p3(*p));circle.renderable=False;circle.wirecolor=rt.color(120,155,210);c['bucket'].addNode(circle)
        # Exercise unlink and restore on this last Analyzer, keeping its nodes.
        if mode=='union':
            rt.QA_AP.areaUI_aaRemove.pressed();update(c)
            check(c['count']==2400 and rt.isValidNode(a) and not c['leaf'].areaUseLine and not c['leaf'].areaUsePoints,'Remove Area Analyzer disables masks without deleting its node')
            rt.QA_AP.areaUI_aaPick.picked(a);rt.QA_AP.areaUI_aaLine.changed(True);rt.QA_AP.areaUI_aaPoints.changed(True);update(c)
    # Curved closed Area: quantify approximation against the exact circle.
    c=new('Curved Include - radius 800 mm');g=rt.circle(name='CSQA_Circle_Include',radius=.8*M,pos=p3(*c['center']));g.renderable=False;c['bucket'].addNode(g)
    rt.QA_AddArea(c['obj'],g,1);actual=update(c);ids={r['id'] for r in actual}
    false_outer=[r for r in actual if math.dist(r['xy'],c['center'])>.801]
    missed_deep=[r for r in c['base'] if math.dist(r['xy'],c['center'])<.798 and r['id'] not in ids]
    check(not false_outer and not missed_deep,'Curved Include matches analytic circle outside 2 mm tessellation tolerance',outer_errors=len(false_outer),deep_missing=len(missed_deep))
    c=new('Analyzer boundary - delete and scale')
    a=rt.CyrusSurfaceAnalyzer(name='CSQA_Boundary_Analyzer');a.surface=c['receiver'];a.analysisMode=2;a.pointRadius=.25*M;a.resolution=128;a.runAnalysis();c['bucket'].addNode(a)
    a.pos=p3(c['center'][0]-1.3,c['center'][1]-1.3)
    rt.QA_UI=c['obj'];rt.QA_Analyzer=a
    mx('local r=QA_Activate QA_UI;QA_AP=r.areasUI;QA_AP.open=true;r.mainUI.bindSection QA_AP;QA_AP.advancedToggle.checked=true;QA_AP.layout();QA_AP.areaUI_fallTarget.selection=1;QA_AP.areaUI_syncFalloff();QA_AP.areaUI_fallPick.picked QA_Analyzer')
    rt.QA_AP.areaUI_fallDeleteCheck.changed(True);rt.QA_AP.areaUI_fallDeleteSpin.changed(.15*M)
    rt.QA_AP.areaUI_fallScaleCheck.changed(True);rt.QA_AP.areaUI_fallScaleSpin.changed(.3*M)
    c['leaf'].fallScaleCurve=arr([.25,.4375,.625,.8125,1]);c['leaf'].setSourceRadius(rt.execute('#{1}'),.035*M);c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=2);c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=3)
    actual=update(c)
    def edge_distance(row):return 1.5-max(abs(row['xy'][0]-c['center'][0]),abs(row['xy'][1]-c['center'][1]))
    check({r['id'] for r in actual}=={r['id'] for r in c['base'] if edge_distance(r)>=.15},'Analyzer Boundary delete width matches receiver edge distance')
    check(all(abs(r['scale']-(.25+.75*min(1,max(0,(edge_distance(r)-.15)/.3))))<2e-4 for r in actual),'Analyzer Boundary scale width and curve match expected distances')
    rt.QA_AP.areaUI_fallRemove.pressed();update(c)
    check(c['count']==2400 and rt.isValidNode(a) and not c['leaf'].fallDelete and not c['leaf'].fallScale,'Remove falloff Analyzer clears effects and keeps its node')
    rt.QA_AP.areaUI_fallPick.picked(a);rt.QA_AP.areaUI_fallDeleteCheck.changed(True);rt.QA_AP.areaUI_fallScaleCheck.changed(True);update(c)
    # Give the artist both an overview and an immediately editable masked case.
    all_nodes=[rt.getNodeByName(c['node_name']) for c in cases]
    rt.viewport.setType(rt.Name('view_top'))
    rt.select(arr(all_nodes));mx('max zoomext sel all')
    rt.CyrusPointSync();rt.redrawViews()
    bmp=rt.gw.getViewportDib();bmp.filename=str(OUT/'Area_Examples_Overview.png');rt.save(bmp);rt.close(bmp)
    focus=rt.getNodeByName(cases[13]['node_name'])
    guides=[n for n in rt.shapes if str(n.name).startswith('CSQA_14_')]
    rt.select(arr(guides));mx('max zoomext sel all')
    rt.QA_Activate(arr([focus,focus.baseObject.layerObjects[0]]))
    focus.baseObject.areasUI.open=True;focus.baseObject.layoutUI.open=True
    rt.CyrusPointSync();rt.redrawViews()
    bmp=rt.gw.getViewportDib();bmp.filename=str(OUT/'Area_Example_14_Closeup.png');rt.save(bmp);rt.close(bmp)
    scene_path=str(OUT/'Include_Exclude_Point_Examples.max')
    fingerprints={c['node_name']:str(rt.cyrusEditFingerprint(rt.getNodeByName(c['node_name']).baseObject.groupSnapshotRows[0],'areas')) for c in cases}
    rt.saveMaxFile(scene_path,quiet=True)
    rt.loadMaxFile(scene_path,quiet=True)
    rt.QA_Pump(700)
    for c in cases:
        node=rt.getNodeByName(c['node_name']);r=node.baseObject;r.refreshAll()
        check(str(r.layerObjects[0].previewError)=='' and str(rt.cyrusEditFingerprint(r.groupSnapshotRows[0],'areas'))==fingerprints[c['node_name']],c['title']+': exact saved-scene round trip')
    roots=[rt.getNodeByName(c['node_name']).baseObject for c in cases]
    rt.CyrusPointSync();rt.redrawViews();rt.QA_Pump(500)
    before=[(int(r.procEpoch),int(r.layerObjects[0].receiverCacheStats()[0])) for r in roots]
    for _ in range(5):
        for r in roots:r.layerObjects[0].previewCache(interactionHeld=False)
        rt.CyrusPointSync();rt.redrawViews()
    after=[(int(r.procEpoch),int(r.layerObjects[0].receiverCacheStats()[0])) for r in roots]
    check(before==after,'All saved comparison cases reuse placement and receiver caches during five unchanged redraws')
    focus=rt.getNodeByName(cases[13]['node_name']);rt.QA_Activate(arr([focus,focus.baseObject.layerObjects[0]]))
    write_results()
except Exception:
    (OUT/'area-examples-extra-error.txt').write_text(traceback.format_exc());raise
finally:rt.execute('CyrusInteractionHeld=QA_PreviousHeld')

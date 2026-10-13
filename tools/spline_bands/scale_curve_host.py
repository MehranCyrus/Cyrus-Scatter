"""Band scale profiles through actual generated controls in an owned Max host."""
from pathlib import Path
import hashlib,json,math,traceback,uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
receipt=OUT/('scale-curve-'+uuid.uuid4().hex+'.json')
report={'checks':[],'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text(encoding='utf-8'))}
def save():receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(value,label):
    report['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def ms(code):return r.execute('(\n'+code+'\n)')
def update():
    r.ScaleRoot.procManualRevision+=1
    return r.ScaleRoot.evaluateProcedural()
def rows():
    return [[str(v[2]),int(v[1]),int(v[5]),*[list(map(float,p)) for p in (v[0].row1,v[0].row2,v[0].row3,v[0].row4)]]
            for v in r.ScaleRoot.groupSnapshotRows[0]]
def radii():return [list(map(float,p)) for p in r.ScaleRoot.procPublishedRadii[0]]
def length(v):return math.sqrt(sum(x*x for x in v))
def close(a,b):return math.isclose(a,b,rel_tol=2e-5,abs_tol=2e-5)
def same_positions(a,b):return len(a)==len(b) and all(x[:3]==y[:3] and x[6]==y[6] for x,y in zip(a,b))

try:
    r.resetMaxFile(r.Name('noPrompt'))
    check(int(r.cyrusSplineBandVersion())==9,'Matched native Band record version 9')
    check(hashlib.sha256((ROOT/'AminScatter/scripts/AminScatterObject.ms').read_bytes()).hexdigest()==report['launch']['script_sha256'],'Matched startup script')
    ms('''
global ScaleNode=AminScatterObject name:"Band scale qualification"
global ScaleRoot=ScaleNode.baseObject
ScaleRoot.updateMode=1;ScaleRoot.autoRender=false;ScaleRoot.newLayer()
global ScaleLeaf=ScaleRoot.selectedLayer()
global ScaleModel=box width:6 length:8 height:12 pos:[700,0,0]
global ScaleReceiver=plane width:400 length:400 widthsegs:1 lengthsegs:1
global ScalePath=rectangle width:100 length:100
ScaleRoot.setLayerSurfaces ScaleLeaf #(ScaleReceiver)
ScaleLeaf.sources=#(ScaleModel);ScaleLeaf.amount=2000;ScaleLeaf.diversityMode=3
ScaleLeaf.scaleMinimum=1.;ScaleLeaf.scaleMaximum=1.;ScaleLeaf.tiltDegrees=0.
ScaleLeaf.sourceScales=#(1.);ScaleLeaf.sourceRadiiWU=#(10.);ScaleLeaf.sourceFollowScale=#(true)
ScaleLeaf.procSelfOverride=true;ScaleLeaf.procSelfEnabled=false
ScaleLeaf.addStroke ScalePath;ScaleLeaf.patternWidths[1]=50.
ScaleLeaf.setStrokeSelection 1 2 #(ScaleModel)
ScaleLeaf.setSourceRadius #{1} true kind:4
ScaleRoot.evaluateProcedural()
global ScaleBandID=ScaleLeaf.strokeIDs[1]
select ScaleNode;max modify mode
if not ScaleRoot.mainUI.controlsReady do ScaleRoot.mainUI.mountTimer.tick()
ScaleRoot.layoutUI.open=true;ScaleRoot.mainUI.bindSection ScaleRoot.layoutUI
global ScalePage=ScaleRoot.layoutUI
''')
    before=rows();before_radii=radii();epoch=int(r.ScaleRoot.procEpoch)
    check(len(before)>100,'Nonempty Band baseline')
    check(ms('ScaleLeaf.strokeScaleModes[1]==1 and ScaleLeaf.strokeScaleSamples[1]=="1,1" and not ScalePage.diversityUI_bandScaleEdit.enabled'),'Off is neutral and disables the scale editor')
    ms('ScalePage.diversityUI_setBandScaleProfile 3')
    check(ms('ScaleLeaf.strokeScaleModes[1]==3 and ScalePage.diversityUI_bandScaleEdit.enabled'),'Shared profile selection handler selects Custom')
    ms('ScalePage.diversityUI_bandScaleEdit.pressed()')
    check(ms('not CyrusFalloffGraph.isDensity and CyrusFalloffGraph.ownerBandID==ScaleBandID and (findString CyrusFalloffGraph.title "Band Scale")!=undefined'),'Scale button opens the captured scale channel')
    key=str(r.ScaleRoot.procInputKey())
    ms('destroyDialog CyrusFalloffGraph')
    check(str(r.ScaleRoot.procInputKey())==key and ms('ScaleLeaf.strokeScaleSamples[1]=="1,1"'),'Opening and closing an unchanged scale graph writes nothing')
    ms('''ScalePage.diversityUI_bandScaleEdit.pressed()
local c=CyrusFalloffGraph.graph.curves[1],a=c.points[1],b=c.points[2]
a.value=[0,25];b.value=[1,200];a.bezier=false;b.bezier=false;c.points[1]=a;c.points[2]=b
CyrusFalloffGraph.applyButton.pressed()
destroyDialog CyrusFalloffGraph''')
    check(ms('(CyrusFallUnpack ScaleLeaf.strokeScaleSamples[1]).count==257 and ScaleLeaf.strokeScaleGraphs[1]!="" and ScaleLeaf.strokeCurveSamples[1]=="1,1"'),'Actual scale graph saves its trace and handles without writing density')
    check(rows()==before and radii()==before_radii and int(r.ScaleRoot.procEpoch)==epoch,'Manual graph edits preserve published transforms and radii')
    update();sized=rows();sized_radii=radii()
    check(same_positions(before,sized),'Custom scale preserves candidate identities, positions, sources and Band ownership')
    factors=[];scale_matches=True
    for a,b in zip(before,sized):
        x,y,_=b[6];distance=math.hypot(max(abs(x)-50,0),max(abs(y)-50,0))
        expected=.25+1.75*distance/50;factors.append(expected)
        scale_matches &= all(close(length(b[j]),length(a[j])*expected) for j in (3,4,5))
    check(scale_matches,'Final scale matches analytic distance across the rectangle Band')
    check(all(close(b[j],a[j]*f) for a,b,f in zip(before_radii,sized_radii,factors) for j in (0,1)),'Published Auto XY/3D radii include the scale profile exactly once')
    # Follow Density uses effective shape, not the strength percentage.
    custom=str(r.ScaleLeaf.strokeScaleSamples[0])
    ms('ScaleLeaf.strokeCurveEnabled[1]=true;ScaleLeaf.strokeCurveSamples[1]=".5,1";ScaleLeaf.strokeStrengths[1]=.4;ScalePage.diversityUI_setBandScaleProfile 2')
    check(ms('not ScalePage.diversityUI_bandScaleEdit.enabled and (ScaleLeaf.bandScaleCurve 1)[1]==.5 and (ScaleLeaf.bandScaleCurve 1)[2]==1.'),'Follow Density links shape, excluding Density % strength')
    update();linked=rows()
    base_by_id={v[0]:v for v in before}
    check(bool(linked) and len(linked)<len(before),'Density still independently thins candidates')
    check(all(close(length(v[3]),length(base_by_id[v[0]][3])*(.5+.5*math.hypot(max(abs(v[6][0])-50,0),max(abs(v[6][1])-50,0))/50)) for v in linked),'Follow Density applies the same position-dependent shape to scale')
    ms('ScaleLeaf.strokeCurveEnabled[1]=false;ScaleLeaf.strokeStrengths[1]=1.')
    check(ms('(ScaleLeaf.bandScaleCurve 1)[1]==1. and (ScaleLeaf.bandScaleCurve 1)[2]==1.'),'Disabled density curve makes Follow Density neutral')
    update();check(rows()==before,'Neutral Follow Density restores exact baseline transforms')
    ms('ScalePage.diversityUI_setBandScaleProfile 3')
    check(str(r.ScaleLeaf.strokeScaleSamples[0])==custom,'Switching profile preserves the independent Custom curve')
    update();check(rows()==sized,'Returning to Custom restores its exact result')
    # Actual native radius modes after the new profile, separate from display.
    ms('ScaleLeaf.setSourceRadius #{1} false kind:4;ScaleLeaf.sourceFollowScale[1]=true')
    update();check(all(close(p[0],10*length(v[3])) and close(p[1],10*length(v[3])) for p,v in zip(radii(),rows())),'Manual Follow Scale radii follow the new profile')
    ms('ScaleLeaf.sourceFollowScale[1]=false');update()
    check(all(close(p[0],10) and close(p[1],10) for p in radii()),'Manual fixed radius stays fixed under scale changes')
    saved=rows();saved_radii=radii();epoch=int(r.ScaleRoot.procEpoch)
    ms('ScaleLeaf.strokeScaleSamples[1]="1,101"')
    failed=False
    try:update()
    except Exception:failed=True
    check(failed and rows()==saved and radii()==saved_radii and int(r.ScaleRoot.procEpoch)==epoch,'Invalid scale trace retains the previous complete publication')
    r.ScaleLeaf.strokeScaleSamples[0]=custom;update()
    ms('ScaleLeaf.strokeScaleSamples[1]="0,0"');update()
    check(same_positions(saved,rows()) and all(length(v[3])==0 for v in rows()),'Zero scale collapses size without deleting candidates')
    # The production redraw path applies relevant Live edits without a manual revision.
    r.ScaleLeaf.strokeScaleSamples[0]=custom;update()
    manual_revision=int(r.ScaleRoot.procManualRevision)
    ms('ScaleRoot.updateMode=2;ScaleLeaf.strokeScaleSamples[1]=".75,.75";ScaleRoot.refreshDisplay();completeRedraw();windows.processPostedMessages()')
    live=rows();live_epoch=int(r.ScaleRoot.procEpoch)
    check(same_positions(before,live) and all(close(length(b[3]),length(a[3])*.75) for a,b in zip(before,live)) and int(r.ScaleRoot.procManualRevision)==manual_revision,'Live redraw applies scale edits without explicit Update')
    ms('global ScaleUnrelated=box pos:[1500,1500,1500];completeRedraw();windows.processPostedMessages();ScaleUnrelated.pos.x+=1;completeRedraw();windows.processPostedMessages()')
    check(rows()==live and int(r.ScaleRoot.procEpoch)==live_epoch,'Unrelated Live scene edits do not republish scale results')
    ms('ScaleRoot.updateMode=1')
    # Keep graph writes bound to captured identity across reorder and selection.
    r.ScaleLeaf.strokeScaleSamples[0]=custom
    ms('''ScaleLeaf.addStroke ScalePath;ScaleLeaf.patternWidths[2]=20.
ScaleLeaf.setStrokeSelection 2 2 #(ScaleModel)
CyrusOpenFalloffGraph ScaleLeaf undefined false bandID:ScaleBandID
ScaleLeaf.moveBand ScaleBandID 2
global ScaleCopy=ScaleRoot.copyLogicalLayer ScaleLeaf
ScaleRoot.mainUI.selectLayerView ScaleCopy
local c=CyrusFalloffGraph.graph.curves[1],p=c.points[2]
p.value.y=125.;c.points[2]=p;CyrusFalloffGraph.storeCurve()''')
    check(ms('CyrusFalloffGraph.bandTargetRow()==2 and ScaleLeaf.strokeScaleSamples[2]!=ScaleCopy.strokeScaleSamples[2]'),'Reorder/copy/view switching cannot redirect captured scale graph writes')
    ms('ScaleLeaf.removeStroke 2')
    check(ms('CyrusFalloffGraph.bandTargetRow()==0 and not CyrusFalloffGraph.applyButton.enabled'),'Deleting the captured Band invalidates its scale editor')
    ms('destroyDialog CyrusFalloffGraph')
    # Save both curve channels and current-only schema, then exercise reopened ownership.
    ms('ScaleCopy.strokeCurveEnabled[2]=true;ScaleCopy.strokeCurveSamples[2]=".5,1";ScaleCopy.strokeCurveGraphs[2]=""')
    state=ms('with printAllElements on #(ScaleCopy.strokeIDs as array,ScaleCopy.strokeScaleModes as array,ScaleCopy.strokeScaleSamples as array,ScaleCopy.strokeScaleGraphs as array,ScaleCopy.strokeCurveSamples as array) as string')
    scene=receipt.with_suffix('.max');r.saveMaxFile(str(scene),quiet=True);r.loadMaxFile(str(scene),quiet=True)
    ms('ScaleRoot=(getNodeByName "Band scale qualification").baseObject;ScaleCopy=ScaleRoot.layerObjects[2]')
    check(ms('with printAllElements on #(ScaleCopy.strokeIDs as array,ScaleCopy.strokeScaleModes as array,ScaleCopy.strokeScaleSamples as array,ScaleCopy.strokeScaleGraphs as array,ScaleCopy.strokeCurveSamples as array) as string')==state,'Save/reopen preserves both curves, modes, handles and stable Band identities')
    ms('CyrusOpenFalloffGraph ScaleCopy undefined false bandID:ScaleCopy.strokeIDs[2]')
    check(ms('CyrusFalloffGraph.ownerRoot==ScaleRoot and CyrusFalloffGraph.bandTargetRow()==2 and not CyrusFalloffGraph.isDensity'),'Reopened scale editor resolves its saved owner')
    ms('destroyDialog CyrusFalloffGraph')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:save()
if not report['passed']:raise RuntimeError(report['error'])

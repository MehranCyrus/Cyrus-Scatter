"""Owned Max regression: immediately preceding schema, units and persistence."""
from pathlib import Path
import hashlib
import json
import math
import traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-'):
    raise RuntimeError('Owned foundation host required')
old_script=OUT/'scripts/schema55.ms'
new_script=OUT/'scripts/schema56.ms'
report={'assertions':[], 'errors':[], 'scripts':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (old_script,new_script)}}
def write(): (OUT/'units-results.json').write_text(json.dumps(report,indent=2)+'\n')
def check(ok,label):
    report['assertions'].append({'passed':bool(ok),'label':label});write()
    if not ok: raise AssertionError(label)
def arr(x): return r.Array(*x)
def unit(name): r.units.SystemType=r.Name(name);r.units.SystemScale=1
def controllers(): return r.getNodeByName('Foundation units').baseObject,r.getNodeByName('Unit fields').baseObject
def physical_rows(root):
    mm=float(r.units.decodeValue('1mm'))
    return [(str(row[2]),int(row[1]),tuple(float(x)/mm for x in row[0].row4),tuple(float(x) for a in (row[0].row1,row[0].row2,row[0].row3) for x in a)) for row in root.groupSnapshotRows[0]]
def same_rows(a,b,factor=1.):
    return len(a)==len(b) and all(x[:2]==y[:2] and all(math.isclose(u*factor,v,rel_tol=2e-5,abs_tol=.02) for u,v in zip(x[2],y[2])) and all(math.isclose(u,v,rel_tol=2e-5,abs_tol=2e-5) for u,v in zip(x[3],y[3])) for x,y in zip(a,b))
def fields(probe,factor):
    expected={'sourceRadiiWU':[2.], 'sourceZOffsetsWU':[1.25], 'edgeOffsetsWU':[3.], 'edgeAlongWU':[4.], 'edgeAcrossWU':[5.], 'procRuleGapWU':[2.25], 'procRadiusDistances':[6.,0.]}
    for name,values in expected.items():
        check(all(math.isclose(float(a),b*factor,rel_tol=1e-6) for a,b in zip(getattr(probe,name),values)) and len(getattr(probe,name))==len(values),'Typed distances: '+name+' factor '+str(factor))
    check(list(map(float,probe.procRadiusValues))==[6.,1.75], 'Radius multipliers remain dimensionless; legacy absolute slot is inert')
    check(list(map(float,probe.sourceScales))==[1.5] and list(map(float,probe.sourceWeights))==[.75], 'Source scale and weight unchanged')
    for time,value in [(0,1.),(10,2.)]:
        r.sliderTime=time
        check(math.isclose(float(probe.movXMinWU),value*factor,rel_tol=1e-6),'Animated movement key '+str(time)+' retains units')
        check(math.isclose(float(probe.sourceRadiiWU[0]),value*2.*factor,rel_tol=1e-6),'Animated per-source radius key '+str(time)+' retains units')
    r.sliderTime=0

try:
    check(not r.isSceneRedrawDisabled(),'Owned host begins with redraw enabled')
    r.CyrusStopBrush();r.resetMaxFile(r.Name('noPrompt'));r.fileIn(str(old_script));unit('Inches')
    surface=r.plane(name='Unit receiver',width=200.,length=200.,widthsegs=8,lengthsegs=8)
    surface.scale=r.Point3(1.5,.8,1.)
    model=r.box(name='Unit source',width=1.,length=1.,height=2.,pos=r.Point3(600.,0.,0.));r.hide(model)
    border=r.rectangle(name='Unit boundary',width=150.,length=130.)
    node=r.AminScatterObject(name='Foundation units');root=node.baseObject;root.updateMode=1;root.autoRender=False
    root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,arr([surface]));leaf.sources=arr([model]);leaf.amount=1000
    leaf.areaNodes=arr([border]);leaf.areaModes=arr([1])
    width=float(r.units.decodeValue('400mm'))
    leaf.setFallConfig(border,arr([False,0.,True,width,arr([.5,1.]),True,width,arr([0.,1.])]))
    root.evaluateProcedural();baseline=physical_rows(root);report['baseline_count']=len(baseline)
    probe=r.AminScatterObject(name='Unit fields').baseObject;probe.updateMode=1;probe.autoRender=False
    for name,values in {'sourceRadii':[2.], 'sourceZOffsets':[1.25], 'edgeOffsets':[3.], 'edgeAlong':[4.], 'edgeAcross':[5.], 'procRuleGap':[2.25], 'sourceScales':[1.5], 'sourceWeights':[.75]}.items():setattr(probe,name,arr(values))
    probe.procRadiusIDs=arr(['absolute','multiplier']);probe.procRadiusModes=arr([1,2]);probe.procRadiusValues=arr([6.,1.75])
    r.execute('global foundationUnitProbe=(getNodeByName "Unit fields").baseObject;with animate on (at time 0 (foundationUnitProbe.movXMin=1.;foundationUnitProbe.sourceRadii[1]=2.);at time 10 (foundationUnitProbe.movXMin=2.;foundationUnitProbe.sourceRadii[1]=4.))')
    path=OUT/'schema55-inches.max';r.saveMaxFile(str(path),quiet=True)
    r.resetMaxFile(r.Name('noPrompt'));r.fileIn(str(new_script));unit('Inches')
    r.loadMaxFile(str(path),quiet=True,useFileUnits=True)
    root,probe=controllers();check(root.procSchemaValid and probe.procSchemaValid,'Schema 55 migrates without denial')
    fields(probe,1.);root.evaluateProcedural();check(same_rows(baseline,physical_rows(root)),'Same-unit migration preserves complete accepted placement values')
    r.resetMaxFile(r.Name('noPrompt'));unit('Centimeters');r.loadMaxFile(str(path),quiet=True,useFileUnits=False)
    root,probe=controllers();fields(probe,2.54)
    leaf=root.layerObjects[0];cfg=leaf.getFallConfig(leaf.areaNodes[0]);mm=float(r.units.decodeValue('1mm'))
    report['converted_falloff_mm']=[float(cfg[3])/mm,float(cfg[6])/mm]
    # Schema 55 already rounded its distance strings to six significant digits.
    check(all(math.isclose(value,400.,abs_tol=.002) for value in report['converted_falloff_mm']),'400 mm falloffs survive load within the original string precision')
    root.evaluateProcedural();check(same_rows(baseline,physical_rows(root)),'Unit-only load conversion preserves accepted IDs and physical transforms')
    converted=OUT/'schema56-centimeters.max';r.saveMaxFile(str(converted),quiet=True)
    r.resetMaxFile(r.Name('noPrompt'));unit('Inches');r.loadMaxFile(str(converted),quiet=True,useFileUnits=False)
    root,probe=controllers();fields(probe,1.);root.evaluateProcedural()
    check(same_rows(baseline,physical_rows(root)),'Save in centimeters and reopen in inches retains physical publication')
    r.rescaleWorldUnits(2.);fields(probe,2.);root.evaluateProcedural()
    check(same_rows(baseline,physical_rows(root),2.),'Explicit world rescale doubles distances and positions without scaling dimensionless transforms')
    r.resetMaxFile(r.Name('noPrompt'));unit('Centimeters')
    sentinel=r.box(name='Merge sentinel',width=7.,length=9.,height=11.)
    check(r.mergeMAXFile(str(path),r.Name('autoRenameDups'),r.Name('renameMtlDups'),quiet=True),'Schema-55 merge returns success')
    root,probe=controllers();fields(probe,2.54);root.evaluateProcedural()
    check(same_rows(baseline,physical_rows(root)),'Merge into centimeters preserves physical accepted publication')
    check(float(sentinel.width)==7. and float(sentinel.length)==9.,'Merge leaves pre-existing scene dimensions unchanged')
    # New-schema writes never serialize distance values through the old string.
    leaf=root.layerObjects[0];border=leaf.areaNodes[0]
    cfg=leaf.getFallConfig(border);cfg[3]=r.units.decodeValue('400mm');cfg[6]=r.units.decodeValue('400mm')
    leaf.setFallConfig(border,cfg)
    copied=root.copyLogicalLayer(leaf)
    cfg=copied.getFallConfig(copied.areaNodes[0]);mm=float(r.units.decodeValue('1mm'))
    check(all(math.isclose(float(cfg[i])/mm,400.,rel_tol=1e-6) for i in (3,6)),'New-schema layer copy retains all typed falloff distances')
    leaf.populationMode=2; leaf.plantsPerM2=40.; root.evaluateProcedural()
    density_rows=physical_rows(root)
    check(len(density_rows)>0,'Density conversion witness is nonempty')
    density_scene=OUT/'schema56-density-centimeters.max'; r.saveMaxFile(str(density_scene),quiet=True)
    r.resetMaxFile(r.Name('noPrompt')); unit('Inches'); r.loadMaxFile(str(density_scene),quiet=True,useFileUnits=False)
    root,probe=controllers(); root.evaluateProcedural()
    check(same_rows(density_rows,physical_rows(root)),'Density count, IDs and physical transforms survive centimeter-to-inch conversion')
    check(not r.isSceneRedrawDisabled(),'Load, merge, save and migration leave redraw enabled')
    report['passed']=True
except Exception:
    report['passed']=False;report['errors'].append(traceback.format_exc())
finally: write()
if not report.get('passed'):raise RuntimeError(report['errors'][-1])

"""Qualify actual Curvature outputs and existing source assets in the owned mountain copy."""
from pathlib import Path
import json,math,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-meshmask-')
assert Path(str(r.maxFilePath)).resolve()==ROOT/'build/mesh-mask-0824-20261015-01/mountain'
data={'status':'started','checks':[],'timings_ms':{},'observations':{}}
def save(): (OUT/'mesh-mask-mountain.json').write_text(json.dumps(data,indent=2)+'\n')
def check(value,label):
    data['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def rows():
    return {str(row[2]):{'matrix':tuple(float(getattr(row[0],'row'+str(i))[k]) for i in range(1,5) for k in range(3)),
        'source':int(row[1]),'face':int(row[3]),'bary':tuple(float(row[4][k]) for k in range(3))}
        for row in root.groupSnapshotRows[0]}
def solve(label):
    root.procManualRevision+=1;t=time.perf_counter();root.evaluateProcedural();data['timings_ms'][label]=(time.perf_counter()-t)*1000;save()
def reference(channel,minimum=0,maximum=1,invert=False):
    mesh=r.snapshotAsMesh(terrain)
    values=[float(r.meshop.getMapVert(mesh,channel,i).x) for i in range(1,int(r.meshop.getNumMapVerts(mesh,channel))+1)]
    faces=[tuple(int(r.meshop.getMapFace(mesh,channel,i)[k])-1 for k in range(3)) for i in range(1,int(mesh.numfaces)+1)]
    weights={}
    for identity,row in baseline.items():
        indices=faces[row['face']-1];b=row['bary'];corners=[values[k] for k in indices]
        value=corners[0]+(corners[1]-corners[0])*b[1]+(corners[2]-corners[0])*b[2]
        weight=max(0,min(1,(value-minimum)/(maximum-minimum)))
        weights[identity]=1-weight if invert else weight
    return weights
def match_reference(channel,label,minimum=0,maximum=1,invert=False):
    accepted=rows();weights=reference(channel,minimum,maximum,invert)
    expected=sum(weights.values());sigma=math.sqrt(sum(w*(1-w) for w in weights.values()))
    low=[key for key,w in weights.items() if w==0];high=[key for key,w in weights.items() if w==1]
    data['observations'][label]={'accepted':len(accepted),'expected':expected,'sigma':sigma,
        'zero_weight_candidates':len(low),'one_weight_candidates':len(high)};save()
    check(abs(len(accepted)-expected)<max(15,6*sigma),label+' count agrees with independently interpolated channel probability')
    check(all(key not in accepted for key in low) and all(key in accepted for key in high),label+' exactly excludes zero weight and retains one weight candidates')
    check(all(row==baseline[key] for key,row in accepted.items()),label+' preserves full source transforms, anchors and identities')
    return accepted
try:
    r.CyrusPerfHeadless=True
    # Forest comparison objects are hidden only in this disposable copy, so the viewport
    # witness measures the existing Cyrus source assets without another scatter's drawing.
    forests=[n for n in r.objects if str(r.classOf(n.baseObject))=='Forest_Lite']
    data['hidden_comparison_objects']=[str(n.name) for n in forests]
    for node in forests:r.hide(node)
    node=r.getNodeByName('Cyrus Scatter001');terrain=r.getNodeByName('Plane001')
    root=node.baseObject;root.updateMode=1;root.autoRender=False;leaf=root.layerObjects[0]
    check(int(leaf.amount)==20000 and len(leaf.sources)==1 and str(leaf.sources[0].name)=='Pyramid001','Uses the original mountain setup, 20000 population and Pyramid001 source')
    leaf.meshMaskEnabled=False;solve('existing_unmasked_20000');baseline=rows()
    check(len(baseline)==20000,'Owned artist scene retains its full preceding unmasked population')
    leaf.meshMaskChannel=2;leaf.meshMaskComponent=1;leaf.meshMaskMinimum=0;leaf.meshMaskMaximum=1
    leaf.meshMaskSamples=r.Array(0.,1.);leaf.meshMaskInvert=False;leaf.meshMaskEnabled=True
    check(rows()==baseline,'Manual mask enable preserves the artist scene until Update')
    solve('channel_2_20000');channel2=match_reference(2,'channel_2')
    leaf.meshMaskChannel=3;solve('channel_3_20000');channel3=match_reference(3,'channel_3')
    check(set(channel2)!=set(channel3),'The two actual Curvature outputs produce different spatial planting subsets')
    leaf.meshMaskInvert=True;solve('channel_3_inverted');match_reference(3,'channel_3_inverted',invert=True)
    leaf.meshMaskInvert=False;leaf.meshMaskMinimum=-1.6216679811477661;leaf.meshMaskMaximum=1.7171599864959717
    solve('channel_3_full_range');match_reference(3,'channel_3_full_range',leaf.meshMaskMinimum,leaf.meshMaskMaximum)
    leaf.meshMaskMinimum=0;leaf.meshMaskMaximum=1;leaf.meshMaskChannel=2;solve('channel_2_restore')
    check(rows()==channel2,'Restoring the first channel restores exactly the same planting subset')
    binding=str(leaf.procBindingKey)
    dc=terrain.modifiers[0];curvature=dc.operators[0]
    saved=(float(curvature.convex),float(curvature.flat),float(curvature.concave))
    curvature.convex=0;curvature.flat=0;curvature.concave=0;leaf.meshMaskChannel=3;solve('actual_curvature_operator_zero')
    check(len(rows())==0 and str(leaf.procBindingKey)==binding,'Actual mountain Curvature operator edit changes density without invalidating Edit geometry binding')
    curvature.convex,curvature.flat,curvature.concave=saved;solve('actual_curvature_operator_restore')
    check(rows()==channel3,'Restoring the mountain modifier restores exact placements')
    area=root.addPaintArea(leaf,target=terrain);r.cyrusBrushFill(area.paintDocument,1.);area.paintDensity=.5;leaf.paintEnabled=True
    solve('curvature_and_paint');paint=rows()
    check(0<len(paint)<len(channel3) and set(paint).issubset(channel3),'Receiver-bound Paint density composes with the mountain Curvature channel')
    leaf.paintEnabled=False;solve('paint_disabled_restore')
    check(rows()==channel3,'Disabling Paint restores exact Curvature eligibility')
    target=ROOT/'build/mesh-mask-0824-20261015-01/mountain/Mountain Scene Test - qualified 0824.max'
    r.saveMaxFile(str(target),quiet=True);r.loadMaxFile(str(target),quiet=True,useFileUnits=True)
    node=r.getNodeByName('Cyrus Scatter001');root=node.baseObject;leaf=root.layerObjects[0];terrain=r.getNodeByName('Plane001')
    solve('mountain_reopen');check(rows()==channel3,'Owned mountain save/reopen preserves mask settings, modifiers and exact source transforms')
    data['saved_scene']=str(target);data['status']='passed';save()
    # Reuse the same bounded idle observer, with this real model/terrain scene.
    r.MeshHeavyNode=node;r.MeshHeavyRoot=root;r.MeshHeavyLeaf=leaf;r.MeshHeavyReceiver=terrain
    root.updateMode=2;root.refreshAll();r.CyrusPointSync();r.MeshHeavyCount=leaf.generatedCount;r.MeshQuietStage=0
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise

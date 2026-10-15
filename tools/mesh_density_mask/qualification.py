"""Owned Max 2027 channel, Paint composition, lifecycle and cache witnesses."""
from pathlib import Path
import json, math, time, traceback
import pymxs
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-meshmask-')
assert json.loads((OUT/'launch.json').read_text())['max_year']==2027
data={'status':'started','checks':[],'timings_ms':{},'script':str(r.CyrusLoadedScriptFingerprint)}
def save(): (OUT/'mesh-mask.json').write_text(json.dumps(data,indent=2)+'\n')
def check(value,label):
    data['checks'].append({'passed':bool(value),'label':label});save()
    if not value: raise AssertionError(label)
def rows(index=0):
    return {str(row[2]):([tuple(float(getattr(row[0],'row'+str(i))[k]) for k in range(3)) for i in range(1,5)],
        int(row[1]),int(row[3]),tuple(float(row[4][k]) for k in range(3)),int(row[5]),bool(row[6]),int(row[7]))
        for row in root.groupSnapshotRows[index]}
def solve():
    root.procManualRevision+=1
    started=time.perf_counter();root.evaluateProcedural()
    return (time.perf_counter()-started)*1000
def channel(node,number,fn):
    r.meshop.setNumMaps(node,max(number+1,int(r.meshop.getNumMaps(node))),keep=True)
    r.meshop.setMapSupport(node,number,True)
    r.meshop.setNumMapVerts(node,number,node.numverts)
    r.meshop.setNumMapFaces(node,number,node.numfaces)
    for i in range(1,int(node.numverts)+1):
        p=r.getVert(node,i);r.meshop.setMapVert(node,number,i,r.Point3(*fn(p)))
    for i in range(1,int(node.numfaces)+1):r.meshop.setMapFace(node,number,i,r.getFace(node,i))
    r.update(node)
def fail(label,text):
    before=rows();epoch=int(root.procEpoch);message=''
    try: solve()
    except Exception as e: message=str(e)
    data.setdefault('expected_errors',[]).append({'label':label,'message':message})
    check(text in message,label+' reports actionable failure')
    check(rows()==before and int(root.procEpoch)==epoch,label+' retains complete publication and epoch')
try:
    with pymxs.undo(False):
        r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
        r.units.SystemType=r.Name('meters');r.units.SystemScale=1
        node=r.AminScatterObject(name='Mesh mask 0.82.4 qualification')
        root=node.baseObject;root.updateMode=1;root.autoRender=False
        receiver=r.Plane(name='Mesh mask terrain',length=40,width=40,lengthsegs=12,widthsegs=12)
        r.convertToMesh(receiver)
        channel(receiver,0,lambda p:(1,0,.5));channel(receiver,2,lambda p:((float(p.x)+20)/40,0,1))
        channel(receiver,99,lambda p:(1,1,1))
        root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(receiver));leaf.addPointSource()
        leaf.amount=10000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False
        check(str(root.uiVersion())=='0.82.4' and int(r.cyrusMeshDensityVersion())==1,'Matched 0.82.4 script and mesh density capability')
        check(not leaf.meshMaskEnabled and leaf.meshMaskChannel==0 and leaf.meshMaskComponent==1,'New mask defaults are disabled channel 0 R/X')
        data['timings_ms']['disabled_10000']=solve();unmasked=rows()
        check(len(unmasked)==10000,'Disabled mask preserves complete candidate budget')
        leaf.meshMaskEnabled=True;before=rows()
        check(before==unmasked,'Manual mask setting waits for explicit Update')
        data['timings_ms']['white_10000']=solve();check(rows()==unmasked,'Constant white preserves full matrices, anchors, sources and identities')
        leaf.meshMaskComponent=2;solve();check(len(rows())==0,'Component G/Y reads the stored zero channel')
        leaf.meshMaskComponent=3;solve();half=rows()
        check(4700<len(half)<5300,'Half-valued channel gives approximately half eligibility')
        check(all(v==unmasked[k] for k,v in half.items()),'Mask thinning preserves surviving full transforms and identities')
        leaf.meshMaskInvert=True;solve();check(rows()==half,'Inverting constant one-half preserves the exact stable subset')
        leaf.meshMaskInvert=False;leaf.meshMaskComponent=1;leaf.meshMaskChannel=2;solve();ramp=rows()
        check(4500<len(ramp)<5500,'Triangle interpolation integrates the analytic linear ramp')
        left=sum(v[0][3][0]<-10 for v in ramp.values());right=sum(v[0][3][0]>10 for v in ramp.values())
        check(right>left*4,'Increasing channel ramp spatially favors high-value terrain')
        check(all(v==unmasked[k] for k,v in ramp.items()),'Channel switch retains surviving base transforms')
        binding=str(leaf.procBindingKey)
        channel(receiver,2,lambda p:(0,0,1));solve();check(len(rows())==0,'Channel-only receiver edit updates eligibility')
        check(str(leaf.procBindingKey)==binding,'Channel-only changes preserve Edit geometry binding')
        channel(receiver,2,lambda p:((float(p.x)+20)/40,0,1));solve();check(rows()==ramp,'Restoring channel values restores exact subset')
        leaf.meshMaskInvert=True;solve();inverse=rows()
        check(4500<len(inverse)<5500 and sum(v[0][3][0]<-10 for v in inverse.values())>sum(v[0][3][0]>10 for v in inverse.values())*4,'Invert reverses the analytic spatial gradient')
        leaf.meshMaskInvert=False;leaf.meshMaskMinimum=-1;leaf.meshMaskMaximum=1;solve()
        check(7000<len(rows())<8000,'Explicit input range remaps values before eligibility')
        leaf.meshMaskMinimum=0;leaf.meshMaskMaximum=1;leaf.meshMaskSamples=r.Array(1.,1.);solve();check(rows()==unmasked,'Constant-one response curve permits the full population')
        leaf.meshMaskSamples=r.Array(0.,0.);solve();check(len(rows())==0,'Constant-zero response curve excludes all candidates')
        leaf.meshMaskSamples=r.Array(0.,1.);solve();check(rows()==ramp,'Returning to linear response restores exact candidate subset')
        preview=r.cyrusMeshDensityPreview(receiver,leaf.meshMaskPayload(),128)
        check(0<len(preview)<=128 and all(0<=float(x[1])<=1 for x in preview),'Native mask preview returns bounded normalized markers')
        channel(receiver,2,lambda p:(1,0,0));solve()
        leaf.meshMaskChannel=99;solve();check(rows()==unmasked,'Highest supported map channel reads stored values')
        r.meshop.setMapSupport(receiver,98,False);r.update(receiver)
        leaf.meshMaskChannel=98;fail('Missing channel','channel 98')
        leaf.meshMaskChannel=2;solve();leaf.meshMaskMinimum=leaf.meshMaskMaximum;fail('Equal input bounds','minimum')
        leaf.meshMaskMinimum=0;leaf.meshMaskComponent=4;fail('Invalid component','component')
        leaf.meshMaskComponent=1;leaf.meshMaskSamples=r.Array(0.,1.1);fail('Out-of-range curve','0..1')
        leaf.meshMaskSamples=r.Array(0.,1.);solve()
        rejected=False
        try: r.meshop.setMapFace(receiver,2,1,r.Point3(999999,1,2))
        except Exception: rejected=True
        check(rejected,'Max rejects malformed map-face indices before they enter the plugin')
        channel(receiver,2,lambda p:(1,0,0));solve()
        area=root.addPaintArea(leaf,target=receiver);r.cyrusBrushFill(area.paintDocument,1.);area.paintDensity=.5;leaf.paintEnabled=True
        solve();paint=rows();check(4500<len(paint)<5500,'Paint density composes with white mesh mask')
        channel(receiver,2,lambda p:(.5,0,0));solve()
        check(2100<len(rows())<2900 and set(rows()).issubset(paint),'Independent Paint and mesh mask combine at approximately quarter density')
        leaf.distributionMode=3;leaf.densityMap=r.Checker(color1=r.color(128,128,128),color2=r.color(128,128,128));solve()
        check(900<len(rows())<1600,'Texture density, Paint and mesh mask compose together')
        leaf.distributionMode=1;leaf.paintEnabled=False;channel(receiver,2,lambda p:(1,0,0))
        leaf.slopeEnabled=True;leaf.slopeMaximum=10;leaf.altitudeEnabled=True;leaf.altitudeMinimum=-1;leaf.altitudeMaximum=1;solve()
        check(rows()==unmasked,'Slope and altitude filters compose with direct mesh density')
        leaf.slopeEnabled=False;leaf.altitudeEnabled=False;leaf.relaxEnabled=True;leaf.relaxIterations=1;solve()
        check(len(rows())>0,'Candidate Relax composes with mesh mask')
        leaf.relaxEnabled=False;leaf.finalRelax=True;leaf.finalIterations=1;solve();check(len(rows())>0,'Final boundary Relax applies mask after movement and reprojection')
        leaf.finalRelax=False;leaf.projectMove=False;leaf.movXMaxWU=.1;fail('Unprojected movement','Keep on surface')
        leaf.projectMove=True;leaf.movXMaxWU=0;solve()
        saved=OUT/'mesh-mask-saved.max';expected=rows();r.saveMaxFile(str(saved),quiet=True)
        r.loadMaxFile(str(saved),quiet=True);node=next(n for n in r.objects if str(n.name)=='Mesh mask 0.82.4 qualification')
        root=node.baseObject;leaf=root.layerObjects[0];receiver=leaf.procReceiverNodes[0]
        solve();check(rows()==expected,'Save/reopen retains mask settings, curve and exact full result')
        root.copyLogicalLayer(leaf);copy=root.selectedLayer()
        check(copy.meshMaskEnabled and copy.meshMaskChannel==2 and list(copy.meshMaskSamples)==[0,1],'Layer copy owns independent saved mesh density settings')
        copy.meshMaskSamples=r.Array(1.,0.);check(list(leaf.meshMaskSamples)==[0,1],'Copied response samples do not alias their source')
        root.removeLogicalLayer(copy);root.selectLayer(1)
        solve();r.MeshMaskNode=node;r.MeshMaskRoot=root;r.MeshMaskLeaf=leaf;r.MeshMaskReceiver=receiver
        r.MeshMaskExpectedCount=len(rows())
        data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise

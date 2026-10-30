"""Small prepared-blade fixture: posed/trimmed hover and retained selection."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));data={};baked=[]

def pump(n=8):
    for _ in range(n):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.03)
def capture(name):
    b=r.gw.getViewportDib();b.filename=str(out/name);r.save(b);r.close(b)

try:
    r.CyrusSelectionTimer.Stop()
    r.execute('resetMaxFile #noPrompt;units.SystemType=#Centimeters;units.SystemScale=1;global OSource,OOwner,ORoot,OLeaf,OStone')
    vertices=[];faces=[]
    for x in (-.03,.03):
        start=len(vertices)
        for ring in range(3):
            z=ring*.03
            vertices.extend((r.Point3(x,0,z),r.Point3(x-.001,.0002,z),r.Point3(x+.001,.0002,z)))
        vertices.append(r.Point3(x+.005,0,.075))
        for ring in range(2):
            a=start+3*ring;b=a+3
            faces.extend((r.Point3(a+1,a+2,b+1),r.Point3(a+2,b+2,b+1),r.Point3(a+3,a+1,b+1),r.Point3(a+3,b+1,b+3)))
        faces.extend((r.Point3(start+7,start+8,start+10),r.Point3(start+9,start+7,start+10)))
    r.OSource=r.mesh(vertices=r.Array(*[v*100 for v in vertices]),faces=r.Array(*faces),name='Owned prepared blades',pos=r.Point3(100,0,0))
    r.execute('''(local receiver=plane length:.1 width:.1 lengthsegs:1 widthsegs:1
    OStone=box name:"Owned blade contact" width:8 length:8 height:1 pos:[0,0,4]
    OOwner=AminScatterObject name:"Owned posed outline";ORoot=OOwner.baseObject;ORoot.surfaceNodes=#(receiver)
    ORoot.newLayer();OLeaf=ORoot.selectedLayer();OLeaf.addModelSource OSource;OLeaf.amount=1
    OLeaf.interactionFoliage=1.;OLeaf.interactionsPrepare (OLeaf.validSources());OLeaf.interactionResponse=1
    OLeaf.interactionCoverRoots=false;OLeaf.interactionBendStrength=1.;ORoot.interactionSceneColliders=#(OStone)
    ORoot.updateMode=2;ORoot.autoRender=false;ORoot.viewportFaces=0;ORoot.viewportNavigationFaces=0;ORoot.setGroupDisplay 3
    ORoot.refreshAll();ORoot.interactionsChanged();ORoot.interactionsEnsure();hide OSource;hide receiver)''')
    pump(20)
    data['contact']=json.loads(str(r.ORoot.interactionsStatistics()))
    assert data['contact']['posed']>0,data['contact']
    baked=list(r.cyrusInteractionBake(r.ORoot.interactionState,1));assert baked
    for n in baked:n.isHidden=False
    r.select(r.Array(*baked));r.viewport.setType(r.Name('view_front'));pump();r.execute('max zoomext sel');pump();r.clearSelection()
    mesh=r.snapshotAsMesh(baked[0]);data['faces']=int(r.getNumFaces(mesh))
    for n in baked:n.isHidden=True
    pump(8)
    samples=[]
    for face in range(1,data['faces']+1):
        f=r.getFace(mesh,face);p=(r.getVert(mesh,int(f.x))+r.getVert(mesh,int(f.y))+r.getVert(mesh,int(f.z)))/3
        r.gw.setTransform(r.Matrix3(1));pixel=r.gw.wTransPoint(p)
        if not (0<=pixel.x<r.gw.getWinSizeX() and 0<=pixel.y<r.gw.getWinSizeY()):continue
        hit=r.cyrusViewportPickAt(r.OOwner,int(pixel.x),int(pixel.y))
        if hit!=r.undefined:samples.append(dict(x=int(pixel.x),y=int(pixel.y),layer=int(hit[0]),id=str(hit[1])))
    assert samples,'Expected a visible posed surface hit'
    sample=samples[0];hit=r.cyrusViewportPickAt(r.OOwner,sample['x'],sample['y'])
    r.redrawViews();capture('posed-hover.png')
    data['hover']=list(r.cyrusViewportOutlineStats());assert data['hover'][2]==data['faces']
    r.select(r.OOwner)
    ticket=int(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.OOwner))[2])
    assert r.CyrusSelectionEnterInstance(r.Array(r.OOwner,sample['layer'],sample['id'],ticket))
    pump();data['selected']=list(r.cyrusViewportOutlineStats());capture('posed-selected.png')
    assert data['selected'][3]==data['faces'] and data['selected'][4]==1
    before=(int(r.ORoot.procEpoch),list(r.cyrusRetainedStreamStats()),list(r.cyrusViewportOutlineStats()))
    for _ in range(12):r.redrawViews();r.windows.processPostedMessages()
    assert before==(int(r.ORoot.procEpoch),list(r.cyrusRetainedStreamStats()),list(r.cyrusViewportOutlineStats()))
    data['warm_reused']=True
    # Clear selection through the actual Edit command; the cue must retire.
    r.cyrusEditSelect(r.OOwner.modifiers[0],r.Array());pump();data['cleared']=list(r.cyrusViewportOutlineStats());assert data['cleared'][3]==0
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
finally:
    for n in baked:
        if r.isValidNode(n):r.delete(n)
    (out/'posed.json').write_text(json.dumps(data,indent=2))
    r.execute('global MCPFixtureDir=GardenRun,MCPFixtureTimer')
    r.fileIn(str(ROOT/'tools/mcp/development_transport.ms'))
    r.MCPFixtureLast=(out/'dev-request.txt').read_text()

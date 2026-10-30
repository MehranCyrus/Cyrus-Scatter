from pathlib import Path
import json,time,traceback,math
from pymxs import runtime as r
out=Path(str(r.GardenRun));cases=[]
try:
    r.execute('''(cyrusEditActiveLayers WFEdit #();WFRoot.layerEnabled[2]=false;WFCollider.interactionCollider=false
    DGStone.isHidden=false;WFRoot.interactionSceneColliders=#(DGStone);WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
    global TCProxyBox
    local b=nodeGetBoundingBox DGStone (matrix3 1),d=b[2]-b[1]
    TCProxyBox=box name:"BENCH | twelve-face box proxy" width:d.x length:d.y height:d.z pos:[(b[1].x+b[2].x)/2,(b[1].y+b[2].y)/2,b[1].z]
    TCProxyBox.renderable=false;TCProxyBox.isHidden=true)''')
    stone=r.DGStone;proxy=r.TCProxyBox;stoneOrigin=r.copy(stone.pos);proxyOrigin=r.copy(proxy.pos)
    for name,collider in [('original-stone',stone),('box-proxy',proxy)]:
        r.WFRoot.interactionSceneColliders=r.Array(collider);r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
        samples=[]
        for i in range(16):
            shift=r.Point3(35*math.sin(i*math.pi/7),0,0);stone.pos=stoneOrigin+shift;proxy.pos=proxyOrigin+shift
            r.CyrusSceneColliderWatch();r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.redrawViews()
            for _ in range(2):r.windows.processPostedMessages();time.sleep(.01)
            samples.append(json.loads(str(r.WFRoot.interactionsStatistics())))
        b=r.gw.getViewportDib();b.filename=str(out/(name+'.png'));r.save(b);r.close(b)
        cases.append(dict(case=name,faces=int(r.getPolygonCount(collider)[0]),samples=samples))
        stone.pos=stoneOrigin;proxy.pos=proxyOrigin
    r.WFRoot.interactionSceneColliders=r.Array(stone);r.delete(proxy);r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
    result=dict(status='complete',cases=cases,scope='User-supplied custom proxy experiment; box does not preserve concavities and is not an automatic replacement policy.')
except Exception:result=dict(status='failed',error=traceback.format_exc(),cases=cases)
(out/'proxy-sweep.json').write_text(json.dumps(result,indent=2),encoding='utf-8')

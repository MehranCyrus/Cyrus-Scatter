"""Real-asset palette and cameras on the owned Terraces scene."""
from pathlib import Path
import json,time,traceback,ctypes
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));run=out.parent
lib=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library'
ids=['A056','A072','A078','A098','A103','A075','A049','A083','A086','A081','A085',
     'A062','A064','A066','A067','A068','A069','A070','A088','A090']
def xyz(p):return [float(p.x),float(p.y),float(p.z)]
def write(name,data):(out/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
try:
    assert r.loadMaxFile(str(run/'inputs/Terraces_Final.max'),quiet=True,useFileUnits=True)
    r.execute('global GardenSources=#(); global GardenRoot,GardenNode; CyrusStopBrush()')
    # Existing authored setup is kept in the copy for reference.
    for node in list(r.objects):
        if str(r.classOf(node.baseObject))=='AminScatterObject':
            node.baseObject.cyrusEnabled=False;r.hide(node)
    catalog={e['id']:e for e in json.loads((lib/'model-catalog.json').read_text())['entries']}
    palette=[]
    for index,id in enumerate(ids):
        e=catalog[id];(out/'stage.txt').write_text('merge '+id+' '+e['name'])
        start=time.perf_counter()
        assert r.mergeMaxFile(str(lib/e['scene']),r.Name('select'),quiet=True)
        nodes=[n for n in r.selection if r.superClassOf(n)==r.GeometryClass]
        assert len(nodes)==1,(id,len(nodes))
        n=nodes[0];n.name='SOURCE | '+id+' | '+e['name']
        n.pos=r.Point3(22000+index*400,22000,0);r.hide(n);n.renderable=False
        r.append(r.GardenSources,n)
        mesh=r.snapshotAsMesh(n);counts=[int(mesh.numverts),int(mesh.numfaces)];r.free(mesh)
        b=r.nodeGetBoundingBox(n,r.Matrix3(1))
        palette.append(dict(id=id,name=e['name'],node=n.name,path=str(lib/e['scene']),
            vertices=counts[0],triangles=counts[1],dimensions=[float(b[1][k]-b[0][k]) for k in range(3)],
            merge_seconds=time.perf_counter()-start))
        write('palette.json',palette)
    # Cameras share the actual landform and house; no generated concept replaces geometry.
    r.execute('''global TCOverview,TCLake,TCHouse
      TCOverview=targetCamera name:"GARDEN | 01 Terraced estate" pos:[-15000,-23000,15000] target:(targetObject pos:[1800,2200,600]) fov:48
      TCLake=targetCamera name:"GARDEN | 02 Lake promenade" pos:[-10600,-7800,-450] target:(targetObject pos:[-1500,-1700,50]) fov:58
      TCHouse=targetCamera name:"GARDEN | 03 Meadow and house" pos:[-5500,-6500,450] target:(targetObject pos:[800,500,500]) fov:50
      hide (for n in shapes where superclassof n==shape collect n)
      hide (for n in cameras collect n);hide (for n in lights collect n)
      clearSelection();viewport.setLayout #layout_1;viewport.setCamera TCOverview
      renderWidth=1600;renderHeight=1000''')
    hwnd=int(r.windows.getMAXHWND());ctypes.windll.user32.SetWindowPos(ctypes.c_void_p(hwnd),0,30,30,1700,1050,0x0014)
    r.completeRedraw();r.windows.processPostedMessages()
    dib=r.gw.getViewportDib();dib.filename=str(out/'overview-palette.png');r.save(dib);r.close(dib)
    (out/'stage.txt').write_text('palette ready')
    write('palette-ready.json',dict(status='ready',sources=len(palette)))
except Exception:
    write('palette-ready.json',dict(status='failed',error=traceback.format_exc()))

"""Owned Max 2027 landscape campaign. Original input is never saved over."""
from pathlib import Path
import json, time, traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(str(r.GardenRun))
RUN = OUT.parent

def write(name, value):
    (OUT/name).write_text(json.dumps(value, indent=2), encoding='utf-8')

def xyz(v):
    return [float(v.x), float(v.y), float(v.z)]

try:
    assert int(r.maxVersion()[0]) == 29000
    r.execute('global MCPFixtureDir=GardenRun')
    r.execute('fileIn @"' + (ROOT/'tools/mcp/development_transport.ms').as_posix() + '"')
    started = time.perf_counter()
    (OUT/'stage.txt').write_text('loading owned scene')
    assert r.loadMaxFile(str(RUN/'inputs/Terraces_Final.max'), quiet=True,
                         useFileUnits=True, missingDLLsAction=r.Name('logmsg'))
    loaded = time.perf_counter() - started
    metre = float(r.units.decodeValue('1m'))
    nodes = []
    for i, node in enumerate(list(r.objects)):
        if i % 30 == 0:
            (OUT/'stage.txt').write_text('inventory ' + str(i))
        item = dict(name=str(node.name), handle=int(r.getHandleByAnim(node)),
                    classname=str(r.classOf(node.baseObject)), superclass=str(r.superClassOf(node)),
                    hidden=bool(node.isHidden), position=xyz(node.pos))
        try:
            bounds = r.nodeGetBoundingBox(node, r.Matrix3(1))
            item['bounds'] = [xyz(v) for v in bounds]
            if r.superClassOf(node) == r.GeometryClass:
                counts = r.getPolygonCount(node)
                item.update(triangles=int(counts[0]), vertices=int(counts[1]))
            if node.material:
                item.update(material=str(node.material.name), material_class=str(r.classOf(node.material)))
        except Exception as e:
            item['inspection_error'] = str(e)
        nodes.append(item)
    write('nodes.json', nodes)
    write('inventory.json', dict(status='ready', load_seconds=loaded, units_per_metre=metre,
          node_count=len(nodes), triangles=sum(n.get('triangles', 0) for n in nodes),
          renderer=str(r.classOf(r.renderers.current)), version=str(r.CyrusLibraryVersion())))
    r.execute('max tool maximize')
    r.completeRedraw()
    dib = r.gw.getViewportDib()
    dib.filename = str(OUT/'initial-view.png')
    r.save(dib)
    r.close(dib)
    write('ready.json', {'status':'ready'})
except Exception:
    write('ready.json', {'status':'failed','error':traceback.format_exc()})

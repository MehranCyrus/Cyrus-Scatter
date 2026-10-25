"""Read-only production-scene inventory in an isolated Max 2027 process."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as rt
ROOT=Path(r'F:/Cursor/_Cyrus_Apps/CyrusScatter')
OUT=Path(str(rt.GardenRun))
SCENE=ROOT/'build/interactions087-inputs-20261025-01/Terraces_Final.max'
def write(name,data): (OUT/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
def xyz(p): return [float(p.x),float(p.y),float(p.z)]
def prop(obj,name,default=None):
    try:
        value=getattr(obj,name)
        if isinstance(value,(str,int,float,bool)): return value
        return str(value) if value is not None else default
    except Exception: return default
def main():
    (OUT/'stage.txt').write_text('load owned scene copy')
    rt.execute('CyrusPerfHeadless=true')
    start=time.perf_counter()
    assert rt.loadMaxFile(str(SCENE),quiet=True,useFileUnits=True,missingDLLsAction=rt.Name('logmsg'))
    load_seconds=time.perf_counter()-start
    metres=float(rt.units.decodeValue('1m')); nodes=[]; scatter=[]
    for i,node in enumerate(list(rt.objects)):
        if i%50==0: (OUT/'stage.txt').write_text('inventory node '+str(i))
        base=node.baseObject
        item={'name':str(node.name),'handle':int(rt.getHandleByAnim(node)),'class':str(rt.classOf(base)),
              'superclass':str(rt.superClassOf(node)),'base_handle':int(rt.getHandleByAnim(base)),
              'hidden':bool(node.isHidden),'renderable':bool(node.renderable),
              'pos_m':[x/metres for x in xyz(node.pos)]}
        try:
            if str(rt.superClassOf(node))=='GeometryClass':
                counts=rt.getPolygonCount(node); item.update(triangles=int(counts[0]),vertices=int(counts[1]))
                b=rt.nodeGetBoundingBox(node,rt.Matrix3(1)); item['bounds_m']=[[v/metres for v in xyz(p)] for p in b]
        except Exception as e: item['geometry_error']=str(e)[:500]
        if node.material: item['material']=str(rt.classOf(node.material))
        if item['class']=='AminScatterObject':
            r=base; layers=[]
            for j,leaf in enumerate(r.layerObjects):
                sources=[{'name':str(n.name),'class':str(rt.classOf(n.baseObject))} for n in leaf.sources if rt.isValidNode(n)]
                layers.append({'index':j,'name':str(r.layerNames[j]),'id':str(leaf.layerID),'amount':int(leaf.amount),
                    'generated':int(leaf.generatedCount),'shown':int(leaf.cachedPointCount),'sources':sources,
                    'receivers':[str(n.name) for n in leaf.surfaceNodes if rt.isValidNode(n)],'error':str(leaf.previewError)})
            scatter.append({'node':item['name'],'schema':int(r.version),'mode':int(r.updateMode),'epoch':int(r.procEpoch),
                'viewport_mode':int(r.viewportMode),'viewport_instances':int(r.viewportInstances),'viewport_faces':int(r.viewportFaces),'layers':layers})
        nodes.append(item)
    materials=[{'class':str(rt.classOf(m)),'name':str(m.name)} for m in rt.sceneMaterials]
    process=rt.execute('(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()')
    report={'status':'inspected','host':2027,'scene':str(SCENE),'load_seconds':load_seconds,'metres_per_world_unit':1/metres,
        'node_count':len(nodes),'geometry_nodes':sum('triangles' in n for n in nodes),
        'triangle_sum_including_instances':sum(n.get('triangles',0) for n in nodes),
        'unique_geometry_objects':len({n['base_handle'] for n in nodes if 'triangles' in n}),
        'renderer':str(rt.classOf(rt.renderers.current)),'materials':materials,'scatter':scatter,
        'private_bytes':int(process.PrivateMemorySize64),'working_set_bytes':int(process.WorkingSet64),'peak_working_set_bytes':int(process.PeakWorkingSet64),
        'scope':'Read-only inventory; no Update, solve, save, render or original-scene mutation.'}
    write('nodes.json',nodes); write('scene-inventory.json',report)
    write('completed.json',{'status':'complete'})
try: main()
except Exception: (OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
# The runner closes Max from MAXScript after Python returns. Closing from an
# active embedded Python call can leave renderer/plugin teardown with exit -1.

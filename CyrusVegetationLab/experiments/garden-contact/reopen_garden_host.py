"""Cold scene reload and warm read-only reuse in an owned Max 2027 profile."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as rt
ROOT=Path(r'F:/Cursor/_Cyrus_Apps/CyrusScatter')
OUT=Path(str(rt.GardenRun))
BASE=ROOT/'build/garden-baseline-host-20261025-03'
def write(name,value): (OUT/name).write_text(json.dumps(value,indent=2),encoding='utf-8')
def rows(root):
    result=[]
    for view in root.groupSnapshotRows:
        token=rt.cyrusPlacementToken(view); layer=[]
        for offset in range(0,int(view.count),500):
            for row in rt.cyrusPlacementPage(view,token,offset,min(500,int(view.count)-offset)):
                tm=row[0]
                layer.append({'source':int(row[1]),'id':str(row[2]),'tm':[[float(p.x),float(p.y),float(p.z)] for p in [tm.row1,tm.row2,tm.row3,tm.row4]]})
        result.append(layer)
    return result
def main():
    rt.execute('CyrusPerfHeadless=true')
    assert rt.loadMaxFile(str(BASE/'Cyrus_Garden_Baseline_Max2027.max'),quiet=True,useFileUnits=True)
    node=rt.getNodeByName('CYRUS | Garden interaction investigation',exact=True); root=node.baseObject
    start=time.perf_counter(); root.procEnsureDisplay(); rt.completeRedraw(); cold=time.perf_counter()-start
    actual=rows(root); expected=[x['rows'] for x in json.loads((BASE/'placements.json').read_text())]
    assert actual==expected,'Cold reconstruction changed source bindings, IDs or transforms'
    before={'epoch':int(root.procEpoch),'preparation_builds':[int(x.procPreparedBuilds) for x in root.layerObjects],
            'preview_builds':[int(x.previewBuildCount) for x in root.layerObjects]}
    times=[]
    for repeat in range(5):
        start=time.perf_counter(); root.procEnsureDisplay(); rt.completeRedraw(); times.append((time.perf_counter()-start)*1000)
    after={'epoch':int(root.procEpoch),'preparation_builds':[int(x.procPreparedBuilds) for x in root.layerObjects],
           'preview_builds':[int(x.previewBuildCount) for x in root.layerObjects]}
    assert before==after,'Warm reuse rebuilt placement/preparation/preview state'
    assert rows(root)==actual,'Warm cached read changed placements'
    write('reopen-report.json',{'status':'pass','cold_source_correspondence_ids_transforms_equal':True,'before':before,'after':after,
          'cold_display_seconds':cold,'warm_ensure_and_redraw_ms':times,'scope':'Cold reopen and five warm cached ensure/redraw calls. Not physical held drag or presented FPS.'})
    write('completed.json',{'status':'complete'})
try: main()
except Exception: (OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
rt.quitMax(rt.Name('noPrompt'))

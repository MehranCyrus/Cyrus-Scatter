"""Read-only asset intake inside an owned Max 2027 process. Originals never saved."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as rt

ROOT=Path(r'F:/Cursor/_Cyrus_Apps/CyrusScatter')
HERE=ROOT/'CyrusVegetationLab/experiments/garden-contact'
OUT=Path(str(rt.GardenRun))
def write(name,value): (OUT/name).write_text(json.dumps(value,indent=2),encoding='utf-8')
def vec(p):return [float(p.x),float(p.y),float(p.z)]
def main():
    result=[]
    for asset in json.loads((HERE/'asset-inputs.json').read_text()):
        (OUT/'stage.txt').write_text(asset['id']);started=time.perf_counter();entry=dict(asset)
        try:
            rt.resetMaxFile(rt.Name('noPrompt'))
            if Path(asset['path']).suffix.lower()=='.max':rt.loadMaxFile(asset['path'],quiet=True,useFileUnits=True)
            else:
                rt.units.SystemType=rt.Name('centimeters');rt.units.SystemScale=1
                rt.importFile(asset['path'],rt.Name('noPrompt'))
            metre=float(rt.units.decodeValue('1m'));nodes=[]
            for i,node in enumerate(list(rt.geometry)):
                bounds=rt.nodeGetBoundingBox(node,rt.Matrix3(1));counts=rt.getPolygonCount(node)
                item={'name':str(node.name),'class':str(rt.classOf(node.baseObject)),
                      'vertices':int(counts[1]),'triangles':int(counts[0]),
                      'min_m':[x/metre for x in vec(bounds[0])],'max_m':[x/metre for x in vec(bounds[1])],
                      'pivot_m':[x/metre for x in vec(node.pos)],'material':str(rt.classOf(node.material)) if node.material else None}
                if counts[0]>0:
                    base=OUT/f"{asset['id']}-{i}"
                    try:rt.cvsInspect(node,str(base));item['snapshot']=str(base.with_suffix('.bin'))
                    except Exception as e:item['snapshot_error']=str(e)
                nodes.append(item)
            entry.update(status='inspected',nodes=nodes,bitmaps=[{'file':str(b.filename),'exists':Path(str(b.filename)).exists()} for b in list(rt.getClassInstances(rt.Bitmaptexture))],seconds=time.perf_counter()-started)
        except Exception:entry.update(status='failed',error=traceback.format_exc())
        result.append(entry);write('assets.json',result)
    write('license.json',{'editing_allowed':bool(rt.cyrusLicenseAllows()),'host':2027})
    write('completed.json',{'status':'complete','assets':len(result)})
try:main()
except Exception:(OUT/'error.txt').write_text(traceback.format_exc())
rt.quitMax(rt.Name('noPrompt'))

"""Read actual HWND bounds in the isolated Max process; no UI automation."""
import json
from pathlib import Path
from pymxs import runtime as rt

folder=Path(str(rt.MCPFixtureDir)).resolve()
root=Path(__file__).resolve().parents[2]
assert folder.parent==root/'build/vector-brush-078'
pages=list(rt.BLayoutPages)
result=[]
for page in pages:
    row={'page':str(page.title),'width':int(page.width),'height':int(page.height),'controls':[]}
    for c in page.controls:
        try:
            if not c.visible:continue
            handles=list(c.hwnd)
        except Exception:continue
        name=str(c.name);rects=[]
        for h in handles:
            try:
                data=rt.windows.getHWNDData(h);r=rt.windows.getWindowPos(h)
                rects.append({'class':str(data[3]),'text':str(data[4]),'x':int(r.x),'y':int(r.y),'w':int(r.w),'h':int(r.h)})
            except Exception:continue
        row['controls'].append({'name':name,'type':str(rt.classOf(c)),'pos':[c.pos.x,c.pos.y],'rects':rects})
    result.append(row)
path=folder/'layout-measurements.json'
data=json.loads(path.read_text()) if path.exists() else []
data.append({'context':str(rt.BLayoutContext),'pages':result})
path.write_text(json.dumps(data,indent=2))

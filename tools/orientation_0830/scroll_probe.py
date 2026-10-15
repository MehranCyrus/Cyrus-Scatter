from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.MCPFixtureDir));assert out.name.startswith('foundation-roadmap-orientation0830-')
page=r.OrientationRoot.mainUI.editors[8];records=[];handle=int(page.hwnd)
for _ in range(10):
 if not handle:break
 data=r.windows.getHWNDData(handle);records.append([str(x) for x in data]);handle=int(data[1])
(out/'scroll-hierarchy.json').write_text(json.dumps(records,indent=2),encoding='utf-8')

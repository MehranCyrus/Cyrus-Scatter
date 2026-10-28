"""Read the owned host's main-window identity; never inject UI input."""
from pathlib import Path
import json
from pymxs import runtime as r
(Path(str(r.GardenRun))/'window-identity.json').write_text(json.dumps({
    'hwnd':int(r.windows.getMAXHWND()),'version':str(r.AminScatterObject().uiVersion())}),encoding='utf-8')

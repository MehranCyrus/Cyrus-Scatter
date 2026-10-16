from pathlib import Path
import json
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
browser=r.CyrusRecipeBrowser
(OUT/'status.json').write_text(json.dumps({'library_loading':browser is not None and (browser.scanTimer.active or browser.panel.Gallery.IsLoading)}))

from pathlib import Path
import json
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
folder=OUT/'gallery-examples'/json.loads((OUT/'command.json').read_text(encoding='utf-8'))['folder']
data=json.loads((folder/'preview-receipt.json').read_text(encoding='utf-8'));original=json.loads((folder/'receipt.json').read_text(encoding='utf-8'))
assert data['status']=='passed'
r.execute('global ExampleRecipe,ExampleScene,ExampleTitle,ExampleEvidence')
r.ExampleRecipe=data['recipe'];r.ExampleScene=data['scene'];r.ExampleTitle=original['title'];r.ExampleEvidence=str(folder)

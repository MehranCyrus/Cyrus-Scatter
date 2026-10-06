from pathlib import Path
import sys,json,shutil,hashlib
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import digest
source=ROOT/'build/real-scene-071/source'
source.mkdir(exist_ok=True)
analyzer=source/'CyrusSurfaceAnalyzer.ms'
shutil.copy2(ROOT/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms',analyzer)
launch=json.loads((ROOT/'build/mcp-qualification/procedural07-real-scene-071-full/launch.json').read_text())
result={'scatter_script_sha256':launch['script_sha256'],'modules':launch['binaries'],'analyzer_script_sha256':digest(analyzer)}
(ROOT/'build/real-scene-071/identity.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))

from pathlib import Path
import sys,shutil,json
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch,digest
from preview import SCRIPT_HASH,MODULES,CANDIDATE
native=ROOT/'build/real-scene-071/native-full'
native.mkdir(exist_ok=True)
for name,sha in MODULES.items():
 src=CANDIDATE/'max2027'/name
 assert digest(src)==sha
 shutil.copy2(src,native/name)
shutil.copy2(ROOT/'build/real-scene-071/analyzer-max2027/CyrusSurfaceAnalyzer.dlx',native/'CyrusSurfaceAnalyzer.dlx')
script=CANDIDATE/'source/AminScatter/scripts/AminScatterObject.ms'
assert digest(script)==SCRIPT_HASH
extra='fileIn @"'+(ROOT/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\n'
extra+='fileIn @"'+(ROOT/'tools/real_scene_071/prepare_assets.ms').as_posix()+'"'
process,metadata=launch(ROOT/'build/mcp-qualification/procedural07-real-scene-071-full',script,native,extra=extra,transport=True,visible=False,extra_modules=('CyrusSurfaceAnalyzer.dlx',))
print(json.dumps(metadata,indent=2),flush=True)

"""Inspect a copy of the supplied artist scene using the qualified 0.7.1 pair."""
from pathlib import Path
import hashlib,json,shutil,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch,digest
from preview import SCRIPT_HASH,MODULES,CANDIDATE

source=ROOT/'Test Scene/Main Scene with 3D Model.max'
workspace=ROOT/'build/real-scene-071'
workspace.mkdir(exist_ok=True)
copied=workspace/'Original_Artist_Scene_Copy.max'
if copied.exists():
    if digest(copied)!=digest(source):raise RuntimeError('Original changed; use a new inspection workspace.')
else:shutil.copy2(source,copied)
script=CANDIDATE/'source/AminScatter/scripts/AminScatterObject.ms'
assert digest(script)==SCRIPT_HASH
for name,sha in MODULES.items():assert digest(CANDIDATE/'max2027'/name)==sha
(workspace/'input-identity.json').write_text(json.dumps({'input':str(source),'sha256':digest(source),'bytes':source.stat().st_size,'copy':str(copied)},indent=2)+'\n')
extra='fileIn @"'+(ROOT/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\n'
extra+='if not (loadMaxFile @"'+copied.as_posix()+'" quiet:true useFileUnits:true) do throw "Could not load the scene copy"\n'
extra+='fileIn @"'+(ROOT/'tools/real_scene_071/inspect.ms').as_posix()+'"'
process,metadata=launch(ROOT/'build/mcp-qualification/procedural07-real-scene-071',script,CANDIDATE/'max2027',extra=extra,transport=True,visible=False)
print(json.dumps(metadata,indent=2),flush=True)

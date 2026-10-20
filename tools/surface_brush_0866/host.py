"""Launch/send only to this campaign's recorded disposable Max 2027 profile."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
sys.path.insert(0,str(ROOT/'tools'))
import build_max
BASE=ROOT/'build/surface-brush-0866-20261019'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
p=argparse.ArgumentParser();p.add_argument('operation',choices=['launch','send']);p.add_argument('--name',required=True);p.add_argument('--native',type=Path);p.add_argument('--script',type=Path);a=p.parse_args()
assert a.name.startswith('density0862-reliability-surface0866-')
host=ROOT/'build/mcp-qualification'/a.name
if a.operation=='send':
 ready(host);assert json.loads((host/'launch.json').read_text())['max_year']==2027
 send(host,a.script.resolve(),a.script.stem);sys.exit(0)
native=a.native.resolve();receipt=json.loads((native/'receipt.json').read_text());assert receipt['max_year']==2027 and all(x['exit_code']==0 for x in receipt['stages'])
for name,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==digest,name
probe=BASE/('probe-'+a.name);probe.mkdir(parents=True)
source=probe/'source';source.mkdir();original=ROOT/'tools/vector_brush_078/callback_probe/probe.cpp'
(source/'probe.cpp').write_text(original.read_text().replace('/build/vector-brush-078/','/build/mcp-qualification/density0862-reliability-surface0866-'),encoding='utf-8')
(source/'CMakeLists.txt').write_text('''cmake_minimum_required(VERSION 3.24)
project(CyrusPrivatePaintProbe LANGUAGES CXX)
include("'''+(ROOT/'cmake/CyrusMaxSDK.cmake').as_posix()+'''")
add_library(CyrusPrivatePaintProbe MODULE probe.cpp)
cyrus_max_target(CyrusPrivatePaintProbe)
target_link_libraries(CyrusPrivatePaintProbe PRIVATE core geom mesh gfx maxutil Maxscrpt paramblk2)
set_target_properties(CyrusPrivatePaintProbe PROPERTIES SUFFIX ".dlx")
''',encoding='utf-8')
env=build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
for label,command in [('configure',['cmake','-S',str(source),'-B',str(probe/'build'),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release','-DCYRUS_MAX_YEAR=2027','-DMAXSDK_ROOT='+str(sdk)]),('build',['cmake','--build',str(probe/'build')])]:
 r=subprocess.run(command,env=env,capture_output=True,text=True);(probe/(label+'.log')).write_text(r.stdout+r.stderr,encoding='utf-8');assert r.returncode==0,(r.stdout+r.stderr)[-6000:]
stage=probe/'pair';stage.mkdir()
for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusGallery.dll'):shutil.copy2(native/name,stage/name)
shutil.copy2(probe/'build/CyrusPrivatePaintProbe.dlx',stage/'CyrusPrivatePaintProbe.dlx')
process,metadata=launch(host,ROOT/'AminScatter/scripts/AminScatterObject.ms',stage,transport=True,max_year=2027,silent_startup=True,script_assets=('CyrusGallery.dll',),extra_modules=('CyrusPrivatePaintProbe.dlx',))
shutil.copytree(ROOT/'AminScatter/patterns',host/'scripts/Patterns')
(host/'source-pair.json').write_text(json.dumps({'native':str(native),'receipt_sha256':sha(native/'receipt.json'),'probe_sha256':sha(stage/'CyrusPrivatePaintProbe.dlx'),'original_probe_source':str(original),'adapted_probe_sha256':sha(source/'probe.cpp')},indent=2)+'\n')
print(json.dumps({'pid':process.pid,'profile':str(host)}),flush=True)
end=time.monotonic()+180
while time.monotonic()<end:
 if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text(encoding='utf-8-sig'))
 if (host/'ready.json').exists():print('Owned Max 2027 host ready',flush=True);break
 if process.poll() is not None:raise RuntimeError('Owned Max exited: '+str(process.returncode))
 time.sleep(.3)
else:raise TimeoutError('Inspect the recorded process; do not relaunch automatically')

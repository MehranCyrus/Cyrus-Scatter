"""Build the unchanged Analyzer and launch a matched, private 0.79.1 host."""
from pathlib import Path
import argparse,json,shutil,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_max import compiler_environment
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--name',required=True)
a=p.parse_args();candidate=a.candidate.resolve();year=json.loads((candidate/'build.json').read_text())['year']
if Path(a.name).name!=a.name:raise ValueError('Private profile name required')
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
source=candidate/'source'
if not (source/'CyrusSurfaceAnalyzer').exists():
    shutil.copytree(ROOT/'CyrusSurfaceAnalyzer',source/'CyrusSurfaceAnalyzer',ignore=shutil.ignore_patterns('build','__pycache__'))
sdk=ROOT/f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk'
analyzer=candidate/'analyzer'
with (candidate/'analyzer-build.log').open('w') as log:
    for cmd in [['cmake','-S',source/'CyrusSurfaceAnalyzer','-B',analyzer,'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',f'-DCYRUS_MAX_YEAR={year}',f'-DMAXSDK_ROOT={sdk}'],['cmake','--build',analyzer],['ctest','--test-dir',analyzer,'--output-on-failure']]:
        subprocess.run(list(map(str,cmd)),env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
shutil.copy2(analyzer/'CyrusSurfaceAnalyzer.dlx',candidate/'native/CyrusSurfaceAnalyzer.dlx')
folder=ROOT/'build/mcp-qualification'/a.name
extra='fileIn @"'+(source/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix()+'"'
import hashlib
for rel,digest in json.loads((candidate/'source.json').read_text()).items():
    if rel!='team_public_key.h' and (rel.endswith(('.cpp','.h','.inc')) or rel.endswith('CMakeLists.txt')):
        if hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()!=digest:raise RuntimeError('Compiled source changed: '+rel)
process,metadata=launch(folder,ROOT/'AminScatter/scripts/AminScatterObject.ms',candidate/'native',extra=extra,transport=True,max_year=year,silent_startup=True,extra_modules=('CyrusSurfaceAnalyzer.dlx',))
original=ROOT/'build/vector-brush-078/include-exclude-visible2026-01/Include_Exclude_Point_Examples.max'
shutil.copy2(original,folder/'input-examples.max')
print(json.dumps(metadata),flush=True)
deadline=time.monotonic()+240
while time.monotonic()<deadline:
    if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (folder/'ready.json').exists():print('Private 0.79.1 host ready');break
    if process.poll() is not None:raise RuntimeError('Host exited')
    time.sleep(.5)
else:raise TimeoutError('Inspect owned host before sending more work')

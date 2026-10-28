"""Replay owned Max 2027 numeric fixtures and read back production HLSL math."""
from argparse import ArgumentParser
from pathlib import Path
import hashlib,importlib.util,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[3]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
parser=ArgumentParser();parser.add_argument('--producer',type=Path,required=True);parser.add_argument('--fixture',type=Path,action='append',required=True);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
producer=args.producer.resolve();output=args.output.resolve();fixtures=[p.resolve() for p in args.fixture]
assert all(p.is_relative_to(ROOT/'build') for p in [producer,output,*fixtures])
receipt=json.loads((producer/'receipt.json').read_text());assert receipt['status']=='complete' and receipt['max_year']==2027 and receipt['tests_run']
sys.path.insert(0,str(ROOT/'tools'));import build_inputs
build_inputs.verify_frozen(receipt['input_manifest'],ROOT)
output.mkdir(parents=True,exist_ok=False)
spec=importlib.util.spec_from_file_location('build_max',ROOT/'tools/build_max.py');builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
env=builder.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
def run(label,command):
    result=subprocess.run([str(v) for v in command],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (output/(label+'.log')).write_text(result.stdout,encoding='utf-8')
    if result.returncode:raise RuntimeError(label+' failed: '+result.stdout[-2000:])
    return result.stdout
exe=output/'gpu_probe.exe';source=ROOT/'tools/procedural_lab/interactions0875/gpu_probe.cpp'
run('build',['C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe','/nologo','/EHsc','/std:c++20','/O2',source,'/Fo'+str(output/'gpu_probe.obj'),'/Fe'+str(exe),'d3d11.lib','d3dcompiler.lib'])
results=[]
for index,fixture in enumerate(fixtures):
    data=json.loads(fixture.read_text());assert data['compact_audit']
    for layer in data['layers']:
        for entry in layer['sources']:
            mesh=Path(entry['mesh']).resolve();assert mesh.is_relative_to(ROOT/'build') and sha(mesh)==entry['sha256']
    packet=Path(data['compact_export']).resolve();assert packet.is_relative_to(ROOT/'build')
    cpu=json.loads(run(f'cpu-{index}',[producer/'interactions_tests.exe','--fixture',fixture,'0']))
    assert cpu['compact_audit']['corners']>0 and cpu['compact_audit']['exported']
    gpu=json.loads(run(f'gpu-{index}',[exe,packet]));assert gpu['status']=='pass' and gpu['corners']==cpu['compact_audit']['corners']
    results.append({'fixture':str(fixture),'fixture_sha256':sha(fixture),'packet_sha256':sha(packet),'cpu':cpu['compact_audit'],'gpu':gpu})
report={'status':'pass','scope':'Copied numeric model data and production HLSL deformation math on an independent hardware D3D11 device; Max presentation and FPS are separate checks','native_source_receipt':str(producer/'receipt.json'),'source_files_verified':len(receipt['sources']),'shader_sha256':sha(ROOT/'AminScatter/src/deformation_shader.inc'),'probe_source_sha256':sha(source),'probe_executable_sha256':sha(exe),'results':results}
(output/'gpu-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))

"""Compile/run isolated research probes with installed tools, without changing Max or installing dependencies."""
from pathlib import Path
import datetime,hashlib,importlib.util,json,os,subprocess,sys
HERE=Path(__file__).resolve().parent
# parents: prototype/local-codex/reports/gpu-brief/research/docs/repository
ROOT=HERE.parents[5]
OUT=ROOT/'build/gpu-interaction-research-20261027-01';OUT.mkdir(parents=True,exist_ok=True)
spec=importlib.util.spec_from_file_location('research_build_tools',ROOT/'tools/build_max.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
env=m.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
cuda=Path('C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.1')
env['PATH']=str(cuda/'bin')+os.pathsep+env['PATH']
probe=sys.argv[1] if len(sys.argv)>1 else 'deformation'
assert probe in ('deformation','interop')
source=HERE/(probe+'_probe.cpp');exe=OUT/(probe+'_probe.exe')
command=['C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe','/nologo','/std:c++17','/O2','/fp:precise','/MD','/EHsc','/I'+str(cuda/'include'),str(source),'/Fe:'+str(exe),'/Fo:'+str(OUT/(probe+'_probe.obj')),'/link','/LIBPATH:'+str(cuda/'lib/x64'),'OpenCL.lib','cuda.lib','cudart.lib','nvrtc.lib','d3d11.lib','dxgi.lib']
build=subprocess.run(command,env=env,cwd=OUT,capture_output=True,text=True,timeout=180)
(OUT/(probe+'-build.log')).write_text(build.stdout+'\n'+build.stderr,encoding='utf-8')
record={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':command,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'compiler_exit_code':build.returncode,'production_files_changed':False}
if build.returncode:
 (OUT/(probe+'-execution.json')).write_text(json.dumps(record,indent=2));print(build.stdout+build.stderr);sys.exit(build.returncode)
run=subprocess.run([str(exe)],env=env,cwd=OUT,capture_output=True,text=True,timeout=120)
(OUT/(probe+'-stdout.json')).write_text(run.stdout,encoding='utf-8');(OUT/(probe+'-stderr.log')).write_text(run.stderr,encoding='utf-8');record['execution_exit_code']=run.returncode
if not run.returncode:
 data=json.loads(run.stdout);record['validated_cases']=len(data['results']) if 'results' in data else sum(bool(data.get(api,{}).get('passed')) for api in ('cuda','opencl'));(HERE/(probe+'_results.json')).write_text(json.dumps(data,indent=2),encoding='utf-8');print(json.dumps({'gpu':data.get('gpu',data.get('device')),'validated_cases':record['validated_cases'],'scope':data['scope']},indent=2))
else:print(run.stderr)
(HERE/(probe+'_execution.json')).write_text(json.dumps(record,indent=2),encoding='utf-8');sys.exit(run.returncode)

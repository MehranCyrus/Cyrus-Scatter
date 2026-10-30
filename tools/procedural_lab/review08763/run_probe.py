from pathlib import Path
import ctypes, importlib.util, json, subprocess, sys
root=Path(__file__).resolve().parents[3]
out=root/'build/interaction-review-08763-20261029-01/probes';out.mkdir(exist_ok=True)
spec=importlib.util.spec_from_file_location('build_max',root/'tools/build_max.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
vs=Path('C:/Program Files/Microsoft Visual Studio/2022/Community')
env=module.compiler_environment(vs,'14.38.33130','10.0.19041.0')
cl=vs/'VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe'
includes=['AminScatter/include','CyrusVegetationLab/experiments/stem-live','CyrusVegetationLab/core/include','CyrusVegetationLab/core/fitter/private','CyrusVegetationLab/core/delivery/src','CyrusLicensing/third_party']
command=[str(cl),'/nologo','/std:c++20','/EHsc','/O2','/MD','/DNOMINMAX','/DCYRUS_STEM_PREPARATION_ONLY']+['/I'+str(root/p) for p in includes]+[str(Path(__file__).with_name('probe.cpp')),'/Fe:'+str(out/'probe.exe'),'/Fo:'+str(out/'probe.obj'),str(out.parent/'native-2027/amin_scatter.lib'),str(out.parent/'native-2027/cyrus_interaction_rig.lib'),'bcrypt.lib']
p=subprocess.run(command,cwd=out,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(out/'probe-compile.log').write_text(p.stdout,encoding='utf-8');print('Compile',p.returncode);print(p.stdout[-4000:])
if p.returncode:sys.exit(p.returncode)
results={}
old=ctypes.windll.kernel32.SetErrorMode(1|2|0x8000)
try:
 for name,args in [('probe',[]),('collider-only-probe',['--collider-only'])]:
  p=subprocess.run([str(out/'probe.exe')]+args,cwd=out,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
  (out/(name+'.log')).write_text(p.stdout+'\nEXIT '+str(p.returncode)+' HEX '+hex(p.returncode&0xffffffff),encoding='utf-8')
  results[name]={'exit_code':p.returncode,'hex':hex(p.returncode&0xffffffff),'output':p.stdout};print(name,p.returncode);print(p.stdout)
finally:ctypes.windll.kernel32.SetErrorMode(old)
(out/'probe-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')

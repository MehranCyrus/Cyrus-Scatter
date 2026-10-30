"""Reproducible review driver. Product sources remain unchanged."""
from pathlib import Path
import ctypes,importlib.util,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
OUT=ROOT/'build/full-system-review-08763-20261029-01/probes';OUT.mkdir(exist_ok=True)
baseline=(ROOT/'tools/procedural_lab/review08763/probe.cpp').read_text().replace('int main(int argc,char**)', 'int repairProbeMain(int argc,char**)').replace('F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/tests/interactions_tests.cpp','../../../../AminScatter/tests/interactions_tests.cpp')
(HERE/'repair_probe.cpp').write_text(baseline)
spec=importlib.util.spec_from_file_location('build_max',ROOT/'tools/build_max.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
vs=Path('C:/Program Files/Microsoft Visual Studio/2022/Community');env=mod.compiler_environment(vs,'14.38.33130','10.0.19041.0')
cl=vs/'VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe'
inc=['AminScatter/include','CyrusVegetationLab/experiments/stem-live','CyrusVegetationLab/core/include','CyrusVegetationLab/core/fitter/private','CyrusVegetationLab/core/delivery/src','CyrusLicensing/third_party']
native=OUT.parent/'native'
cmd=[str(cl),'/nologo','/std:c++20','/EHsc','/O2','/MD','/DNOMINMAX','/DCYRUS_STEM_PREPARATION_ONLY']+['/I'+str(ROOT/p) for p in inc]+[str(HERE/'extra_probe.cpp'),'/Fe:'+str(OUT/'probe.exe'),'/Fo:'+str(OUT/'probe.obj'),str(native/'amin_scatter.lib'),str(native/'cyrus_interaction_rig.lib'),'bcrypt.lib']
proc=subprocess.run(cmd,cwd=OUT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(OUT/'compile.log').write_text(proc.stdout);print(proc.stdout)
if proc.returncode:sys.exit(proc.returncode)
old=ctypes.windll.kernel32.SetErrorMode(1|2|0x8000)
try:
    args=['--benchmark'] if '--benchmark' in sys.argv else []
    proc=subprocess.run([str(OUT/'probe.exe')]+args,cwd=OUT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
    name='benchmark' if args else 'regression';(OUT/(name+'.json')).write_text(json.dumps({'exit':proc.returncode,'command':[str(OUT/'probe.exe')]+args,'output':proc.stdout},indent=2));print(proc.stdout);sys.exit(proc.returncode)
finally:ctypes.windll.kernel32.SetErrorMode(old)

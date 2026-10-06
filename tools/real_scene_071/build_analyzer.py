from pathlib import Path
import sys,json,subprocess
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_max import compiler_environment
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
out=ROOT/'build/real-scene-071/analyzer-max2027'
out.mkdir(parents=True,exist_ok=True)
commands=[['cmake','-S',str(ROOT/'CyrusSurfaceAnalyzer'),'-B',str(out),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release','-DCYRUS_MAX_YEAR=2027','-DMAXSDK_ROOT='+str(ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk')],['cmake','--build',str(out)],['ctest','--test-dir',str(out),'--output-on-failure']]
for i,cmd in enumerate(commands):
 with (out/f'stage-{i}.log').open('w') as log:r=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT)
 print(i,r.returncode,flush=True)
 if r.returncode:raise SystemExit(r.returncode)

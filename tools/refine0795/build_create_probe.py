from pathlib import Path
import argparse,sys,subprocess
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
from build_max import compiler_environment
p=argparse.ArgumentParser();p.add_argument('--year',type=int,choices=(2026,2027),required=True);a=p.parse_args()
out=ROOT/f'build/refine0795-create-20261011/probe{a.year}-nmake';out.mkdir(exist_ok=False,parents=True)
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
sdk=ROOT/f'build/tooling/max{a.year}-sdk/Program Files/Autodesk/3ds Max {a.year} SDK/maxsdk'
for label,command in [('configure',['cmake','-S',str(ROOT/'tools/refine0795/create_callback_probe'),'-B',str(out),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',f'-DCYRUS_MAX_YEAR={a.year}',f'-DMAXSDK_ROOT={sdk}']),('build',['cmake','--build',str(out)])]:
    r=subprocess.run(command,env=env,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (out/(label+'.log')).write_text(r.stdout);print(r.stdout[-5000:],flush=True)
    if r.returncode:raise SystemExit(r.returncode)

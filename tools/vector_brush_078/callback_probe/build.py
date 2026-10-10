"""Compile private diagnostic only; does not modify product or install it."""
from pathlib import Path
import argparse,json,subprocess,sys
root=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'tools'))
from build_max import compiler_environment
p=argparse.ArgumentParser();p.add_argument('--year',type=int,choices=(2026,2027),required=True);a=p.parse_args()
out=root/f'build/vector-brush-078/callback-probe-{a.year}';out.mkdir(exist_ok=True)
sdk=root/f'build/tooling/max{a.year}-sdk/Program Files/Autodesk/3ds Max {a.year} SDK/maxsdk'
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
for cmd in ([ 'cmake','-S',str(Path(__file__).parent),'-B',str(out),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',f'-DCYRUS_MAX_YEAR={a.year}',f'-DMAXSDK_ROOT={sdk}'],['cmake','--build',str(out)]):
 subprocess.run(cmd,env=env,check=True)

"""Incremental native development checks; not a release qualification receipt."""
from pathlib import Path
import os,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import build_max
env=build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
out=ROOT/'build/source-clearance-0868-20261020/core'
out.mkdir(parents=True,exist_ok=True)
commands=[
 ['cmake','-S',str(ROOT/'AminScatter'),'-B',str(out),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release','-DAMIN_BUILD_MAX=OFF'],
 ['cmake','--build',str(out),'--target','procedural_tests','source_clearance_tests'],
 ['ctest','--test-dir',str(out),'-R','^scatter_(procedural|source_clearance)$','--output-on-failure'],
]
for index,cmd in enumerate(commands):
 result=subprocess.run(cmd,env=env,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 (out/f'development-{index}.log').write_text(result.stdout,encoding='utf-8')
 print(result.stdout[-6000:],flush=True)
 if result.returncode:raise SystemExit(result.returncode)

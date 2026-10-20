"""Incremental native development checks; never a final qualification receipt."""
from pathlib import Path
import argparse,subprocess,sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
import build_max
p=argparse.ArgumentParser();p.add_argument('build',type=Path);p.add_argument('--targets',nargs='+',default=['brush_atlas_tests']);a=p.parse_args()
env=build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
r=subprocess.run(['cmake','--build',str(a.build),'--target',*a.targets],env=env,capture_output=True,text=True)
(a.build/'development-build.log').write_text(r.stdout+r.stderr,encoding='utf-8');print((r.stdout+r.stderr)[-8000:]);sys.exit(r.returncode)

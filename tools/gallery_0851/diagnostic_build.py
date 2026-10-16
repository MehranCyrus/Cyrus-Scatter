"""Incremental compile diagnostics only; never changes the frozen build receipt."""
from pathlib import Path
import argparse, importlib.util, subprocess, uuid
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('directory',type=Path);a=p.parse_args()
folder=a.directory.resolve();assert folder.parent==ROOT/'build/gallery-0851-20261016-01'
spec=importlib.util.spec_from_file_location('build_max',ROOT/'tools/build_max.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
env=module.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
result=subprocess.run(['cmake','--build',str(folder)],cwd=ROOT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
log=folder/('diagnostic-'+uuid.uuid4().hex+'.log');log.write_text(result.stdout,encoding='utf-8')
print(log,flush=True)
if result.returncode:
 print('\n'.join(line for line in result.stdout.splitlines() if 'error ' in line or 'fatal error' in line),flush=True)
else:print('Diagnostic compilation passed; this is not a frozen build receipt.',flush=True)
raise SystemExit(result.returncode)

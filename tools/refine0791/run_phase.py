"""Serialize one regression phase through the owned Max transport."""
from pathlib import Path
import argparse,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('phase',choices=['scene','falloff','points','reopen','undo_prepare','undo_check','empty','layout','units']);a=p.parse_args()
entry='fileIn' if a.phase.startswith('undo_') else 'python.ExecuteFile'
name='undo_checks.ms' if a.phase.startswith('undo_') else 'host_checks.py'
invocation=f'{entry} @"{(Path(__file__).with_name(name)).as_posix()}"'
# Python fixture setup is not an artist transaction. Product handlers still
# open their own undo scopes; the dedicated undo probe stays pure MAXScript.
if not a.phase.startswith('undo_'):invocation='undo off ('+invocation+')'
script=f'global R791Phase="{a.phase}"\n{invocation}'
result=run_script(a.profile,script,timeout=180)
print(result);raise SystemExit(0 if result.startswith('SUCCESS ') else 1)

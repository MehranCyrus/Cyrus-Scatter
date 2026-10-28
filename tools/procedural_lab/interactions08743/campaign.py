"""Run the scoped checks serially in a previously launched owned Max 2027 host."""
from argparse import ArgumentParser
from pathlib import Path
import json,subprocess,sys
ROOT=Path(__file__).resolve().parents[3];here=Path(__file__).resolve().parent
p=ArgumentParser();p.add_argument('--host',type=Path,required=True);args=p.parse_args();host=args.host.resolve()
assert host.is_relative_to(ROOT/'build') and json.loads((host/'ready.json').read_text())['status']=='ready'
phases=['reset','setup','under-auto','margin','undo-native','undo-read','redo-native','redo-read','bend','view-deformed','scale200','pending','save','reload','restore','view-setup','view-grass','view-mesh-wire','view-texture','view-material','view-texture-wire','view-split','view-shade','migration','reload']
for phase in phases:
    script='reset_fixture_host.py' if phase=='reset' else 'undo_host.ms' if phase in ('undo-native','redo-native') else 'check_host.py'
    result=subprocess.run([sys.executable,str(here/'dispatch_job.py'),'--host',str(host),'--script',str(here/script),'--case',phase,'--timeout','180'],cwd=ROOT,capture_output=True,text=True,timeout=200)
    if result.returncode:raise RuntimeError(phase+'\n'+result.stdout+result.stderr)
    if phase not in ('reset','undo-native','redo-native'):assert json.loads((host/('check-'+phase+'.json')).read_text())['status']=='pass',phase
    print('PASS '+phase,flush=True)

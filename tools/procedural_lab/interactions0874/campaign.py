"""Serialize commands to an owned profile; never target an artist Max session."""
from pathlib import Path
from argparse import ArgumentParser
import json,time
p=ArgumentParser();p.add_argument('--host',required=True,type=Path);p.add_argument('--phase',required=True);p.add_argument('--suffix',required=True);a=p.parse_args()
ROOT=Path(__file__).resolve().parents[3];host=a.host.resolve();assert host.is_relative_to(ROOT/'build') and (host/'launch.json').exists()
assert json.loads((host/'ready.json').read_text())['status']=='ready'
script=Path(__file__).parent/'checks.py';path=host/(a.suffix+'.ms');assert not path.exists()
path.write_text('global PEPhase="'+a.phase+'";python.ExecuteFile @"'+script.as_posix()+'"',encoding='utf-8')
(host/'dev-request.txt').write_text(path.as_posix(),encoding='utf-8')
until=time.monotonic()+180
while True:
    result=(host/'dev-result.txt').read_text() if (host/'dev-result.txt').exists() else ''
    if path.as_posix() in result:
        assert result.startswith('SUCCESS'),result;break
    assert time.monotonic()<until,'Owned command timed out';time.sleep(.2)
data=json.loads((host/(a.phase+'.json')).read_text());summary={k:v for k,v in data.items() if k in ('status','error','trial','authored_survives_prepare','cancel_preserves_definition','selected_part')};summary['stages']={k:{n:v.get(n) for n in ('ready','preparation_ms','source_triangles','parts')}|{'guides':v.get('report',{}).get('guides')} for k,v in data.items() if k in ('initial','fixed','manual')};print(json.dumps(summary,indent=2));assert 'error' not in data,summary

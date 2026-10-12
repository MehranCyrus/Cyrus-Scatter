"""Audit both CLI interpreters before their first detector/repository import."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


BOOTSTRAP = '''import atexit,json,os,sys
from pathlib import Path
directory=Path(os.environ['CYRUS_TEST_RUNTIME'])
names=set(json.loads(os.environ['CYRUS_TEST_RUNTIME_NAMES']))
denied=os.environ.get('CYRUS_TEST_ACCESS_DENIED','')
events=[]
def audit(event,args):
    value=args[0] if event=='open' else getattr(args[0],'co_filename',None) if event=='exec' else None
    if not isinstance(value,(str,bytes)):return
    path=Path(os.fsdecode(value))
    # Include bytecode cache attempts as well as source reads/execution.
    name=path.name if path.suffix!='.pyc' else path.name.split('.')[0]+'.py'
    if name in names and (path.parent==directory or path.parent==directory/'__pycache__'):
        events.append({'event':event,'path':str(path),'pid':os.getpid()})
        if event=='open' and name==denied:raise PermissionError('Owned fresh-process access denial')
sys.addaudithook(audit)
def save():
    Path(os.environ['CYRUS_TEST_AUDIT'],str(os.getpid())+'.json').write_text(json.dumps(events),encoding='utf-8')
atexit.register(save)
'''


def run(script, root, index, runtime_names, access_denied='', human=False):
    # The instrumentation is outside protected fixture inputs; the CLI writes
    # neither the audit nor any artifact. sitecustomize covers parent AND worker.
    with tempfile.TemporaryDirectory(prefix='cyrus-refresh-audit-') as directory:
        directory=Path(directory)
        (directory/'sitecustomize.py').write_text(BOOTSTRAP,encoding='utf-8',newline='\n')
        environment=dict(os.environ,PYTHONPATH=str(directory),PYTHONDONTWRITEBYTECODE='1',
                         CYRUS_TEST_RUNTIME=str(script.parent),CYRUS_TEST_RUNTIME_NAMES=json.dumps(list(runtime_names)),
                         CYRUS_TEST_AUDIT=str(directory),CYRUS_TEST_ACCESS_DENIED=access_denied)
        command=[sys.executable,'-B',str(script),'--root',str(root),'--index',str(index)]
        if not human:command.append('--json')
        result=subprocess.run(command,capture_output=True,env=environment,timeout=35)
        receipts=sorted(directory.glob('*.json'))
        events=[event for path in receipts for event in json.loads(path.read_bytes())]
        return result,events,len(receipts)
